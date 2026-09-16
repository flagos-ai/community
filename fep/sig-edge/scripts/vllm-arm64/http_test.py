import json
import os
import signal
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

action = sys.argv[1]
kind = os.environ['MODEL_KIND']
work = Path(os.environ['WORK_DIR'])
scripts = Path(__file__).resolve().parent
perf = action == 'bench'
port = int(os.environ.get('PORT', {'w4': '18043', 'w8': '18042'}[kind]))
name = f'minicpm5-{kind}a8' + ('-perf' if perf else '')
limit = 1024 if perf else int(os.environ['CONTEXT_LIMIT'])
wait_budget = int(os.environ.get('TEST_TIMEOUT_SECONDS', '1800'))
opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
base = f'http://127.0.0.1:{port}'
command = [
    'taskset', '-c', os.environ['A720_CORES'], str(work / '.venv/bin/vllm'),
    'serve', os.environ['MODEL_DIR'], '--host', '127.0.0.1', '--port', str(port),
    '--served-model-name', name, '--dtype', 'bfloat16', '--enforce-eager',
    '--max-model-len', str(limit), '--max-num-batched-tokens', str(limit),
    '--max-num-seqs', '1', '--generation-config', 'vllm',
    '--distributed-executor-backend', 'uni', '--disable-log-stats', '--language-model-only',
]
if perf:
    command.append('--no-enable-prefix-caching')
env = os.environ.copy()
env.pop('VLLM_ENABLE_V1_MULTIPROCESSING', None)


def get_json(path):
    with opener.open(base + path, timeout=5) as response:
        assert response.status == 200
        return json.load(response)


def smoke():
    assert any(item['id'] == name for item in get_json('/v1/models')['data'])
    for index in [1, 2]:
        payload = {'model': name, 'messages': [
            {'role': 'user', 'content': '请只回答数字：1+1等于几？'}],
            'chat_template_kwargs': {'enable_thinking': False},
            'max_tokens': 16, 'temperature': 0}
        request = urllib.request.Request(
            base + '/v1/chat/completions', data=json.dumps(payload).encode(),
            headers={'Content-Type': 'application/json'}, method='POST')
        started = time.perf_counter()
        with opener.open(request, timeout=wait_budget) as response:
            assert response.status == 200
            output = json.load(response)
        elapsed = time.perf_counter() - started
        assert output['choices'][0]['message']['content'].strip() == '2', output
        assert output['usage']['completion_tokens'] > 0, output
        (work / f'logs/{kind}-chat-{index}.json').write_text(json.dumps(output, indent=2))
        print('HTTP inference PASS', kind, index, round(elapsed, 3), 'seconds', output['usage'], flush=True)


if action == 'serve':
    try:
        sys.exit(subprocess.call(command, env=env))
    except KeyboardInterrupt:
        sys.exit(130)

# Fail if the port belongs to another service; never test or stop an unrelated server.
with socket.socket() as probe:
    probe.bind(('127.0.0.1', port))
log = work / f'logs/{action}-{kind}-server.log'
started = time.perf_counter()
with log.open('w') as output:
    process = subprocess.Popen(command, env=env, stdout=output, stderr=subprocess.STDOUT,
                               start_new_session=True)
    print('server starting', process.pid, 'log:', log, flush=True)
    try:
        deadline = time.monotonic() + wait_budget
        while True:
            if process.poll() is not None:
                raise RuntimeError(f'server exited {process.returncode}; inspect {log}')
            try:
                with opener.open(base + '/health', timeout=5) as response:
                    assert response.status == 200
                break
            except (OSError, urllib.error.URLError):
                if time.monotonic() >= deadline:
                    raise TimeoutError(f'server not ready; inspect {log}')
                time.sleep(2)
        print('server ready', round(time.perf_counter() - started, 3), 'seconds', flush=True)
        if perf:
            subprocess.run([sys.executable, str(scripts / 'perf_client.py'),
                            '--port', str(port), '--model', name,
                            '--output', str(work / f'logs/{kind}-perf.jsonl')], check=True)
        else:
            smoke()
        content = log.read_text()
        assert 'Platform plugin fl is activated' in content, log
        if kind == 'w8':
            assert 'Selected CPUInt8ScaledMMLinearKernel for CompressedTensorsW8A8Int8' in content, log
    finally:
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        try:
            process.wait(timeout=30)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
        print('test server stopped; caches retained', flush=True)
