import argparse
import json
import statistics
import time
import urllib.request
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--port", type=int, required=True)
parser.add_argument("--model", required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()

opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
short_base = "请用中文详述在 ARM CPU 上运行量化语言模型的三个主要性能瓶颈，并逐项给出工程处理方法。"
context = "在 ARM CPU 上部署量化语言模型，需要评估加载时间、首 token 延迟、持续生成速度、内存占用和并发能力。"
long_base = context * 12 + "请根据上述背景综合说明如何评估一个量化模型服务的可用性。"
cases = [("short", short_base, 0), ("long", long_base, 0),
         ("short", short_base, 1), ("short", short_base, 2),
         ("short", short_base, 3), ("long", long_base, 1),
         ("long", long_base, 2)]
records = []
for kind, base, run in cases:
    prompt = f"样本编号 {kind}-{run}。" + base
    payload = {
        "model": args.model,
        "messages": [{"role": "user", "content": prompt}],
        "chat_template_kwargs": {"enable_thinking": False},
        "max_tokens": 64,
        "ignore_eos": True,
        "temperature": 0,
        "stream": True,
        "stream_options": {"include_usage": True},
    }
    request = urllib.request.Request(
        f"http://127.0.0.1:{args.port}/v1/chat/completions",
        data=json.dumps(payload, ensure_ascii=False).encode(),
        headers={"Content-Type": "application/json"}, method="POST",
    )
    started = time.perf_counter()
    first_content = last_content = usage = None
    chunks = 0
    with opener.open(request, timeout=1800) as response:
        assert response.status == 200, response.status
        for raw in response:
            line = raw.decode("utf-8").strip()
            if not line.startswith("data:"):
                continue
            data = line[5:].strip()
            if data == "[DONE]":
                break
            item = json.loads(data)
            if item.get("usage"):
                usage = item["usage"]
            for choice in item.get("choices", []):
                content = choice.get("delta", {}).get("content")
                if content:
                    now = time.perf_counter()
                    if first_content is None:
                        first_content = now
                    last_content = now
                    chunks += 1
    ended = time.perf_counter()
    assert usage is not None and usage["completion_tokens"] == 64, usage
    assert first_content is not None and last_content is not None
    assert chunks == 64, f"expected one content chunk per output token, got {chunks}"
    if run == 0:
        print("prewarm complete", kind, round(ended - started, 3), "seconds", flush=True)
        continue
    elapsed_decode = last_content - first_content
    record = {
        "model": args.model, "case": kind, "run": run,
        "prompt_tokens": usage["prompt_tokens"],
        "completion_tokens": usage["completion_tokens"],
        "ttft_s": round(first_content - started, 3),
        "total_s": round(ended - started, 3),
        "decode_tok_per_s": round(63 / elapsed_decode, 2)
        if elapsed_decode > 0 else None,
        "content_chunks": chunks,
    }
    records.append(record)
    print(json.dumps(record, ensure_ascii=False), flush=True)
args.output.write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in records) + "\n")
for kind in ("short", "long"):
    warm = [r for r in records if r["case"] == kind]
    print(kind, "warm median TTFT",
          round(statistics.median(r["ttft_s"] for r in warm), 3),
          "s, total", round(statistics.median(r["total_s"] for r in warm), 3),
          "s, decode",
          round(statistics.median(r["decode_tok_per_s"] for r in warm), 2),
          "tok/s", flush=True)
