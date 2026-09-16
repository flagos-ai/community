import hashlib
import json
import os
from pathlib import Path


def sha256(path):
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for chunk in iter(lambda: handle.read(4 * 1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


kind = os.environ['MODEL_KIND']
model = Path(os.environ['MODEL_DIR'])
config = json.loads((model / 'config.json').read_text())
quant = config['quantization_config']
group = next(iter(quant['config_groups'].values()))
weights, activations = group['weights'], group['input_activations']
assert config['architectures'] == ['LlamaForCausalLM']
assert config['num_hidden_layers'] == 42
assert weights['symmetric'] and not weights['dynamic']
assert activations['num_bits'] == 8 and activations['strategy'] == 'token'
assert activations['symmetric'] and activations['dynamic']
if kind == 'w4':
    assert quant['format'] == group['format'] == 'pack-quantized'
    assert weights['num_bits'] == 4 and weights['group_size'] == 128
    assert weights['strategy'] == 'group'
    filename, expected = 'model.safetensors', os.environ['PACKED_WEIGHT_SHA']
elif kind == 'w8':
    assert quant['format'] == 'int-quantized'
    assert weights['num_bits'] == 8 and weights['strategy'] == 'channel'
    filename, expected = 'model-00000-of-00001.safetensors', os.environ['W8_WEIGHT_SHA']
else:
    raise ValueError(kind)
assert sha256(model / filename) == expected, f'weight checksum mismatch: {model}'
assert sha256(model / 'tokenizer.json') == os.environ['TOKENIZER_SHA']
print('checkpoint PASS', kind, model, expected)
