
NOTE: same process in CUDA and METAX

1. prepare FlagScale
```bash
git clone https://github.com/flagos-ai/FlagScale.git
git checkout xxx
```

2. Prepare megatron-lm-fl
```bash
git clone https://github.com/flagos-ai/Megatron-LM-FL.git
git cehckout xxx
cd Megatron-LM
pip install . --no-build-isolation --root-user-action=ignore
```

3. Prepare transformerengine-fl 
```bash
git clone https://github.com/flagos-ai/TransformerEngine-FL.git
git checkout xxx
cd TransformerEngine-FL
git submodule update --init --recursive
MAX_JOBS=64 pip install -v . --no-build-isolation --root-user-action=ignore
# in metax env(image: harbor.baai.ac.cn/flagscale/megatron-lm-with-te:202603231839):
TE_FL_SKIP_CUDA=1 MAX_JOBS=64 pip install -v . --no-build-isolation --root-user-action=ignore
```

4. Prepare dataset/tokenizer/...
```bash
mkdir -p ./data && cd ./data
wget https://baai-flagscale.ks3-cn-beijing.ksyuncs.com/datasets/enron_emails_demo_text_document_qwen/enron_emails_demo_text_document_qwen.idx
wget https://baai-flagscale.ks3-cn-beijing.ksyuncs.com/datasets/enron_emails_demo_text_document_qwen/enron_emails_demo_text_document_qwen.bin
```

```bash
mkdir -p ./qwentokenizer && cd ./qwentokenizer
wget "https://baai-flagscale.ks3-cn-beijing.ksyuncs.com/tokenizers/qwentokenizer/tokenizer_config.json" -O tokenizer_config.json
wget "https://baai-flagscale.ks3-cn-beijing.ksyuncs.com/tokenizers/qwentokenizer/qwen.tiktoken" -O qwen.tiktoken
wget "https://baai-flagscale.ks3-cn-beijing.ksyuncs.com/tokenizers/qwentokenizer/qwen_generation_utils.py" -O qwen_generation_utils.py
wget "https://baai-flagscale.ks3-cn-beijing.ksyuncs.com/tokenizers/qwentokenizer/tokenization_qwen.py" -O tokenization_qwen.py
```

5. qwen3 test

```bash
cd FlagScale
python run.py \
    --config-path examples/qwen3/conf \
    --config-name train_te_fl.yaml \
    action=run \
    experiment.exp_dir=./ \
    experiment.runner.hostfile=null \
    '~experiment.runner.ssh_port' \
    'experiment.cmds.before_start="ulimit -n 1048576 && source /root/miniconda3/bin/activate base"' \
    'experiment.envs.CUDA_VISIBLE_DEVICES="4,5,6,7"' \
    train.system.tensor_model_parallel_size=4 \
    train.model.num_layers=4 \
    train.data.data_path=./data/enron_emails_demo_text_document_qwen \
    train.data.tokenizer.tokenizer_path=./qwentokenizer \
    train.model.te_fl_prefer=vendor \ **Optional: vendor/reference**
    train.model.distributed_backend=nccl \
    +train.model.attention_backend=flash \
    train.model.enable_flag_gems=False \
    '~train.model.te_fl_allow_vendors' \
    '~train.model.te_fl_deny_vendors' \
    '~train.model.te_fl_per_op' \
    '~train.model.flag_gems_log_path' \
    '~train.model.flag_gems_unused'
```

6. deepseek-v3 test

```bash
cd FlagScale
python run.py \
    --config-path examples/deepseek_v3/conf \
    --config-name train.yaml \
    action=run \
    experiment.exp_dir=./ \
    'experiment.cmds.before_start="ulimit -n 1048576 && source /root/miniconda3/bin/activate base"' \
    'experiment.envs.CUDA_VISIBLE_DEVICES="4,5,6,7"' \
    train.system.decoder_first_pipeline_num_layers=2 \
    train.system.expert_model_parallel_size=2 \
    train.model.num_layers=4 \
    'train.model.moe_layer_freq="[0]+[1]*3"' \
    train.data.data_path=./data/enron_emails_demo_text_document_qwen \
    train.data.tokenizer.tokenizer_path=./qwentokenizer \
    +train.model.enable_flag_gems=False \
    +train.model.attention_backend=unfused \
    +train.model.te_fl_prefer=vendor \ **Optional: vendor/reference**
    '+train.model.te_fl_per_op="te_general_grouped_gemm=vendor"'
```

7. NOTE:
- change conda env
- need 4 GPUs
- NOTE Optional in cmd
- log path: ./logs/host_0_localhost.output
