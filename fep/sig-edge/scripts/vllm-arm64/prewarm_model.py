import json
import os
import time
from pathlib import Path

kind = os.environ["MODEL_KIND"]
assert kind in {"w4", "w8"}, kind
cache = Path(os.environ["TRITON_CACHE_DIR"])
cache.mkdir(parents=True, exist_ok=True)

from vllm import LLM, SamplingParams

calls = {"pack": 0, "linear": 0}
if kind == "w4":
    import flag_gems.quantized_linear as flag_linear
    original_pack = flag_linear.pack_rhs_qsi4c128p
    original_linear = flag_linear.w4a8_g128_linear

    def audited_pack(*args, **kwargs):
        calls["pack"] += 1
        return original_pack(*args, **kwargs)

    def audited_linear(*args, **kwargs):
        calls["linear"] += 1
        return original_linear(*args, **kwargs)

    flag_linear.pack_rhs_qsi4c128p = audited_pack
    flag_linear.w4a8_g128_linear = audited_linear

started = time.perf_counter()
llm = LLM(model=os.environ["MODEL_DIR"], dtype="bfloat16", enforce_eager=True,
          max_model_len=int(os.environ["CONTEXT_LIMIT"]),
          max_num_batched_tokens=int(os.environ["CONTEXT_LIMIT"]), max_num_seqs=1)
loaded = time.perf_counter()
print("model initialized", round(loaded - started, 3), "seconds", flush=True)
if kind == "w4":
    assert calls["pack"] == 168, calls
for index in range(2):
    before = calls["linear"]
    request_start = time.perf_counter()
    output = llm.chat(
        messages=[{"role": "user", "content": "请只回答数字：1+1等于几？"}],
        sampling_params=SamplingParams(max_tokens=16, temperature=0),
        chat_template_kwargs={"enable_thinking": False},
    )[0]
    elapsed = time.perf_counter() - request_start
    answer = output.outputs[0].text.strip()
    assert answer == "2", answer
    if kind == "w4":
        assert calls["linear"] - before == 336, calls
    print(json.dumps({"model": kind, "request_index": index + 1, "answer": answer,
                      "model_init_s": round(loaded - started, 3),
                      "request_s": round(elapsed, 3), "pack_calls": calls["pack"],
                      "request_linear_calls": calls["linear"] - before,
                      "cache": str(cache)}), flush=True)
