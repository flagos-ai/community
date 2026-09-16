import json
import hashlib
import os
import shutil
from pathlib import Path

import torch
from compressed_tensors.compressors.pack_quantized.helpers import pack_to_int32, unpack_from_int32
from safetensors import safe_open
from safetensors.torch import save_file

source = Path(os.environ["W4_SOURCE"])
packed_dir = Path(os.environ["W4_PACKED"])

def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(4 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()

if packed_dir.exists() and any(packed_dir.iterdir()):
    weight_file = packed_dir / "model.safetensors"
    config_file = packed_dir / "config.json"
    tokenizer_file = packed_dir / "tokenizer.json"
    if weight_file.exists() and config_file.exists() and tokenizer_file.exists():
        packed_config = json.loads(config_file.read_text())
        packed_quant = packed_config["quantization_config"]
        packed_group = next(iter(packed_quant["config_groups"].values()))
        if (sha256(weight_file) ==
                "0bc220b3da79f4af1b77dc9231bf7dec417d0a0a8e344e41da6f3f502b76ac7e"
                and sha256(tokenizer_file) ==
                "3e065a558a034185fe299917b398685c1facd0169a9eea1e629eb30c171fed81"
                and packed_quant["format"] == packed_group["format"] == "pack-quantized"):
            print("existing lossless W4A8 test copy already verified", packed_dir)
            raise SystemExit(0)
    raise RuntimeError(f"incomplete W4A8 test copy: {packed_dir}; use an empty output directory")
for file in source.iterdir():
    if file.is_file():
        with file.open("rb") as handle:
            assert not handle.read(64).startswith(
                b"version https://git-lfs.github.com/spec/v1"
            ), f"unresolved Git LFS pointer: {file}"

config = json.loads((source / "config.json").read_text())
quant = config["quantization_config"]
group = next(iter(quant["config_groups"].values()))
weights, activations = group["weights"], group["input_activations"]
assert quant["format"] == "int-quantized"
assert group.get("format", quant["format"]) == "int-quantized"
assert weights["num_bits"] == 4 and weights["group_size"] == 128
assert weights["strategy"] == "group" and weights["symmetric"]
assert activations["num_bits"] == 8 and activations["strategy"] == "token"
assert activations["dynamic"]

output = {}
count = 0
with safe_open(source / "model-00000-of-00001.safetensors", framework="pt", device="cpu") as f:
    keys = set(f.keys())
    for name in sorted(keys):
        tensor = f.get_tensor(name)
        if name.endswith(".weight") and tensor.dtype == torch.int8:
            assert tensor.ndim == 2 and tensor.shape[0] % 4 == 0
            assert tensor.shape[1] % 128 == 0 and name + "_scale" in keys
            assert -8 <= int(tensor.min()) and int(tensor.max()) <= 7
            packed = pack_to_int32(tensor, 4)
            assert torch.equal(unpack_from_int32(packed, 4, tensor.shape), tensor), name
            stem = name.removesuffix(".weight")
            output[stem + ".weight_packed"] = packed.contiguous()
            output[stem + ".weight_shape"] = torch.tensor(tensor.shape, dtype=torch.int64)
            count += 1
        else:
            output[name] = tensor.contiguous()
assert count == config["num_hidden_layers"] * 7 == 294, count

packed_dir.mkdir(parents=True, exist_ok=True)
save_file(output, packed_dir / "model.safetensors")
quant["format"] = group["format"] = "pack-quantized"
(packed_dir / "config.json").write_text(json.dumps(config, indent=2) + "\n")
for file in source.iterdir():
    if file.is_file() and file.name not in {
        "model-00000-of-00001.safetensors", "model.safetensors.index.json", "config.json"
    }:
        shutil.copy2(file, packed_dir / file.name)
print("lossless W4A8 packing PASS", count, packed_dir)
