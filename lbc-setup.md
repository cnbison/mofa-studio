安装虚拟环境出现的一些错误：

Dora Nodes:
------------------------------
✗ dora-asr: Not installed - No module named 'dora_common'
✗ dora-primespeech: Not installed - No module named 'dora_common'
✗ dora-qwen3: Not installed - No module named 'dora_qwen3'
✓ dora-text-segmenter: Installed
✓ dora-speechmonitor: Installed

/Users/loubicheng/miniconda3/envs/mofa-studio/lib/python3.12/site-packages/webrtcvad.py:1: UserWarning: pkg_resources is deprecated as an API. See https://setuptools.pypa.io/en/latest/pkg_resources.html. The pkg_resources package is slated for removal as early as 2025-11-30. Refrain from using this package or pin to Setuptools<81.
  import pkg_resources

To activate the environment:
  conda activate mofa-studio

To test the installation:
  cd /Users/loubicheng/project/mofa-studio/models/setup-local-models
  python tests/run_all_tests.py

To run examples:
  cd /Users/loubicheng/project/mofa-studio/models/setup-local-models/../../examples/mac-aec-chat
  dora up
  dora start voice-chat-with-aec.yml

To test Kokoro TTS backends:
  cd /Users/loubicheng/project/mofa-studio/models/setup-local-models/kokoro-tts-validation
  ./run_all_tests.sh

Installing collected packages: numpy
  Attempting uninstall: numpy
    Found existing installation: numpy 1.26.4
    Uninstalling numpy-1.26.4:
      Successfully uninstalled numpy-1.26.4
ERROR: pip's dependency resolver does not currently take into account all the packages that are installed. This behaviour is the source of the following dependency conflicts.
opencv-python 4.12.0.88 requires numpy<2.3.0,>=2; python_version >= "3.9", but you have numpy 1.26.4 which is incompatible.
mlx-vlm 0.3.9 requires transformers>=4.57.0, but you have transformers 4.49.0 which is incompatible.
Successfully installed numpy-1.26.4
✓ NumPy compatibility fixed

  Attempting uninstall: transformers
    Found existing installation: transformers 4.57.3
    Uninstalling transformers-4.57.3:
      Successfully uninstalled transformers-4.57.3
ERROR: pip's dependency resolver does not currently take into account all the packages that are installed. This behaviour is the source of the following dependency conflicts.
mlx-vlm 0.3.9 requires transformers>=4.57.0, but you have transformers 4.49.0 which is incompatible.

