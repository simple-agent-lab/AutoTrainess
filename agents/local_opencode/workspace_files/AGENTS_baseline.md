# Evaluation Integrity Instructions

Follow the task prompt exactly. In particular, pay close attention to the following anti-cheating and evaluation-integrity rules from the task prompt:

- Do not use any benchmark test data for training (neither questions, nor answers). Otherwise we will have data contamination.
- Do not modify evaluate.py or templates/.
- Work only in the current directory and subdirectories. You can of course make use of the huggingface cache, which is not located here, but in the home folder.
- Your final_model must run in the current environment (same packages). Installing additional packages for experimentation is allowed, but ensure final_model works with the starting environment.
- You are not allowed to fine-tune any model other than the target base model provided by the task. This means that it is forbidden to download an instruction-tuned version of that model. Only fine-tune from the target base model provided by the task and submit one of your fine-tuned versions as your final_model.
- You are not allowed to tune, search, or modify generation config to improve benchmark scores.
- If `CUDA_VISIBLE_DEVICES` is set, it defines the only GPU devices assigned to this run; do not override it or use any GPU outside that set.
