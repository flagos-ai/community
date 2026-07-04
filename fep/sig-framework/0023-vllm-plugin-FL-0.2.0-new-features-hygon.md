# FEP: vllm-plugin-FL 0.2.0 New Features (Qwen3.6 Test Expansion, Hygon)

**Status:** `Implemented`

**Created:** 2026-05-27

**Owner:** @cyber-pioneer

**SIG:** sig-framework

**Target Version:** FlagOS 2.1

---

## Summary

This proposal adds end-to-end text and image test coverage for `Qwen3.6-35B-A3B` and `Qwen3.6-27B` in [flagos-ai/vllm-plugin-FL](https://github.com/flagos-ai/vllm-plugin-FL), with validated execution on the Hygon platform. The scope includes model test configs and Hygon platform test matrix updates that verify inference and serving behaviors.

## Motivation

Current test coverage in vllm-plugin-FL focuses on existing Qwen3/Qwen3.5 and selected multimodal models. For the 0.2.0 feature set, we need first-class validation for the two new Qwen3.6 model lines in both text and image scenarios on Hygon.

Without this expansion:

- New model support may regress silently on Hygon.
- Multimodal integration risk remains high because text-only tests cannot detect image pipeline issues.
- Release confidence for Hygon delivery is limited.

### Goals

- Add text inference/serving smoke tests for `Qwen3.6-35B-A3B` and `Qwen3.6-27B`.
- Add image inference/serving smoke tests for both model lines.
- Execute the same logical test matrix on Hygon.

## Proposal

From a user perspective, test execution remains unchanged: maintainers run the existing test entrypoint with platform and device flags, and obtain deterministic pass/fail signals for both model families and modalities.

## Design Details

This proposal implements Qwen3.6 validation by adding four new model cases (35B-A3B/27B, text/image) in the existing model-YAML driven workflow, extending the Hygon platform matrix to include inference and serving coverage for those cases, and running the same unified service-plus-request test flow so that multimodal behavior, endpoint compatibility, and pass/fail criteria remain consistent with the current vllm-plugin-FL smoke-test framework.

## Packaging

This feature relies on existing vllm-plugin-FL packaging and environment setup.
All commands in this section are intended to run inside the container started in the Test Plan.

### Container Setup

```bash
docker pull harbor.sourcefind.cn:5443/dcu/admin/base/custom:vllm0.20.0-ubuntu22.04-dtk26.04-py3.10-MiniCPM-V-4.6
docker run \
    --name perf \
    --network=host \
    --ipc=host \
    --device=/dev/kfd \
    --device=/dev/mkfd \
    --device=/dev/dri \
    -v /opt/hyhal:/opt/hyhal \
    -v /path/to/models:/models \
    --group-add video \
    --cap-add=SYS_PTRACE \
    --security-opt seccomp=unconfined \
    -itd harbor.sourcefind.cn:5443/dcu/admin/base/custom:vllm0.20.0-ubuntu22.04-dtk26.04-py3.10-MiniCPM-V-4.6 \
    /bin/bash
```

### Build and Package

1. Inside the container, install build dependencies:
```bash
pip install -U scikit-build-core==0.11 pybind11 ninja cmake
```


2. Install FlagGems:

```bash
git clone https://github.com/flagos-ai/FlagGems
cd FlagGems
git checkout 2718037d887cd6a3143474da0224648e40c5004f
pip install --no-build-isolation -e .
```

3. Clone and install vllm-plugin-FL:

```bash
git clone https://github.com/flagos-ai/vllm-plugin-FL
cd vllm-plugin-FL
git checkout 48af29e21491700a38020ab031af5d3b90e6795e
pip install --no-build-isolation -e .
```

4. Download models
```bash
modelscope download --model Qwen/Qwen3.6-27B --local_dir /models/Qwen3.6-27B
modelscope download --model Qwen/Qwen3.6-35B-A3B --local_dir /models/Qwen3.6-35B-A3B
```

## Test Plan

The test plan below is required for Hygon.

### Environment Matrix

- Platform: Hygon

### Image Acquisition

Record image source explicitly in test logs, including:

- image name/tag
- vllm-plugin-FL commit
- vLLM version


### Component Setup and Running (Unified Case)

Use one unified serving-and-request case for Hygon. Only the model path changes between `Qwen3.6-35B-A3B` and `Qwen3.6-27B`.

#### 1. Start vLLM service

```bash
export VLLM_PLUGINS=fl
vllm serve /models/Qwen3.6-35B-A3B \
        --served-model-name "qwen" \
        --host 0.0.0.0 \
        --port 8000 \
        --tensor-parallel-size 2 \
        --max-model-len 32768 \
        --trust-remote-code \
        --limit-mm-per-prompt '{"image": 1}'
```

For `Qwen3.6-27B`, run the same command and replace model path with `/models/Qwen3.6-27B`.

Expected result:

- Service starts successfully and listens on port `8000`.
- OpenAI-compatible endpoint `/v1/chat/completions` is reachable.

#### 2. Unified request cases

##### 2.1 Text test case (unified)

```python
from openai import OpenAI

client = OpenAI(
    api_key="EMPTY",
    base_url="http://localhost:8000/v1",
)

messages = [
    {"role": "user", "content": "Type \"Introduce LLM\" backwards"},
]

chat_response = client.chat.completions.create(
    model="qwen",
    messages=messages,
    max_tokens=8192,
    temperature=1.0,
    top_p=0.95,
    presence_penalty=1.5,
    extra_body={
        "top_k": 20,
    },
)
print("Chat response:", chat_response)
```

Expected result:

- Request returns HTTP 200.
- `chat_response.choices` is present and non-empty.
- Assistant response includes a valid backward form of `Introduce LLM`.

##### 2.2 Image test case (unified)

```python
from openai import OpenAI

client = OpenAI(
    api_key="EMPTY",
    base_url="http://localhost:8000/v1",
)

messages = [
    {
        "role": "user",
        "content": [
            {
                "type": "image_url",
                "image_url": {
                    "url": "https://qianwen-res.oss-accelerate.aliyuncs.com/Qwen3.5/demo/CI_Demo/mathv-1327.jpg"
                }
            },
            {
                "type": "text",
                "text": "The centres of the four illustrated circles are in the corners of the square. The two big circles touch each other and also the two little circles. With which factor do you have to multiply the radii of the little circles to obtain the radius of the big circles?\nChoices:\n(A) $\\frac{2}{9}$\n(B) $\\sqrt{5}$\n(C) $0.8 \\cdot \\pi$\n(D) 2.5\n(E) $1+\\sqrt{2}$"
            }
        ]
    }
]

chat_response = client.chat.completions.create(
    model="qwen",
    messages=messages,
    max_tokens=8120,
    temperature=1.0,
    top_p=0.95,
    presence_penalty=1.5,
    extra_body={
        "top_k": 20,
    },
)
print("Chat response:", chat_response)
```

Expected result:

- Request returns HTTP 200.
- `chat_response.choices` is present and non-empty.
- Assistant response content is non-empty (image + text jointly understood).

#### 3. Execution matrix

Run the same unified case in this matrix:

- Hygon + `Qwen3.6-35B-A3B`
- Hygon + `Qwen3.6-27B`

Pass criteria:

- Both combinations pass both the text test case and image test case.
- No model load failure, no multimodal parsing error, and no empty generation.
