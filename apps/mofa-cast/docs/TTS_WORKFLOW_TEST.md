# MoFA Cast TTS Workflow Testing Guide

**Version**: 0.2.0
**Last Updated**: 2026-01-09
**Purpose**: Test end-to-end TTS synthesis using Dora dataflow

---

## Prerequisites

1. **Dora installed and running**
   ```bash
   # Check if dora is available
   dora --version

   # Start dora daemon and coordinator
   dora up
   ```

2. **Kokoro TTS node available**
   ```bash
   # Check if dora-kokoro-tts is installed
   ls ../../node-hub/dora-kokoro-tts/

   # Should see:
   # - dora-kokoro-tts/
   # - pyproject.toml
   # - kokoro_tts.py
   ```

3. **Build mofa-cast**
   ```bash
   cd /Users/loubicheng/project/mofa-studio
   cargo build --release --package mofa-cast
   ```

---

## Test Workflow

### Step 1: Start mofa-studio-shell

```bash
./target/release/mofa-studio-shell
```

The UI should appear with MoFA Cast in the sidebar (cast icon 🎙️).

### Step 2: Import a Test Transcript

1. Click the **MoFA Cast** icon in the sidebar
2. In the "Import Section" dropdown, select **Plain Text**
3. Click **Import** button
4. Navigate to: `apps/mofa-cast/test_samples/sample_plain.txt`
5. Click **Open**

**Expected Result**:
- Left panel shows speaker statistics (e.g., "2 speakers")
- Left panel shows speaker list with colors
- Original text editor displays the imported transcript
- File info label shows message count

**Log Output**:
```
[INFO] Parsed transcript: 2 speakers, 6 messages
[INFO] Transcript loaded successfully
```

### Step 3: Refine Script (AI Enhancement)

1. Review the original script in the left editor
2. Click **Refine Script** button

**Expected Result**:
- Progress label shows: "🤖 Refining script with AI..."
- After a few seconds, refined script appears in the right editor
- Progress label shows: "✅ Script refined successfully!"
- Refine button is re-enabled

**Log Output**:
```
[INFO] Starting AI script refinement...
[INFO] Script refinement completed
```

**Note**: This uses `MockRefiner` by default (no API key needed). To use real AI, set `OPENAI_API_KEY` environment variable.

### Step 4: Synthesize Audio (Dora + Kokoro)

1. Review the refined script
2. Click **Synthesize Audio** button

**Expected Result**:

**Stage 1: Starting Dataflow**
- Progress label: "🎙️ Starting Dora dataflow..."
- Console logs:
  ```
  [INFO] Initializing Dora integration
  [INFO] Starting Dora dataflow: .../dataflow/batch-tts.yml
  [INFO] Expecting N audio segments from Dora dataflow
  [INFO] Started Dora TTS synthesis with N segments
  ```

**Stage 2: Processing Segments**
- Progress label: "🎙️ Synthesizing N segments via Dora..."
- Console logs:
  ```
  [INFO] Sending N text segments to TTS
  [INFO] [Dora] Sent N text segments to TTS
  ```

**Stage 3: Receiving Audio**
- Progress label updates: "🎙️ Received 1/N segments (X%) - SpeakerName"
- Console logs:
  ```
  [INFO] Received audio segment: XXXX samples, rate: 22050, channels: 1
  [INFO] Saved segment 1 of N: segment_000_speaker1.wav (X.XXs)
  ```

**Stage 4: Completion**
- Progress label: "✅ All N segments received! Ready to export."
- Export button becomes enabled
- Synthesize button becomes enabled
- Console logs:
  ```
  [INFO] All N segments received, enabling export
  ```

**Audio Files Created**:
```
output/mofa-cast/dora/
├── segment_000_Alice.wav
├── segment_001_Bob.wav
├── segment_002_Alice.wav
└── ...
```

### Step 5: Export Podcast (Mix Audio)

1. Click **Export Audio** button

**Expected Result**:
- Progress label: "📥 Mixing and exporting audio..."
- After processing: "✅ Exported! X.Xs audio • YKB"
- Export button is re-enabled

**Console Logs**:
```
[INFO] Exporting N audio segments
[INFO] Audio exported successfully: X.Xs, YKB
[INFO] Export file: ./output/mofa-cast/podcast.wav
```

**Output File Created**:
```
output/mofa-cast/podcast.wav  <- Final podcast audio
```

### Step 6: Verify Output

1. Open the exported audio file:
   ```bash
   open output/mofa-cast/podcast.wav
   # or
   ffplay output/mofa-cast/podcast.wav
   ```

**Expected Quality**:
- Sample rate: 22050 Hz (or 24000 Hz)
- Channels: Mono (1 channel)
- Format: 16-bit PCM WAV
- All segments concatenated with 0.5s silence between them
- Speaker voices: Alice (female), Bob (male)

---

## Troubleshooting

### Issue: "Dataflow configuration not found"

**Cause**: Dora dataflow YAML file not found

**Solution**:
```bash
# Check if batch-tts.yml exists
ls apps/mofa-cast/dataflow/batch-tts.yml

# If missing, create it from the template
# (Already created in P0.6)
```

### Issue: "Failed to start Dora dataflow"

**Possible Causes**:
1. Dora daemon not running
   ```bash
   dora up
   ```

2. dora-kokoro-tts node not available
   ```bash
   cd ../../node-hub/dora-kokoro-tts
   pip install -e .
   ```

3. Port conflicts (dora already running)
   ```bash
   dora list
   dora destroy <dataflow_id>
   ```

### Issue: "No audio segments received"

**Possible Causes**:
1. Kokoro TTS not installed
   ```bash
   # Check installation
   python -c "import kokoro; print(kokoro.__version__)"
   ```

2. Missing dynamic node bridge
   - Check mofa-dora-bridge is running
   - Check console for bridge connection logs

3. Script segmentation failed
   - Check if refined script has proper speaker labels
   - Format: `[SpeakerName] dialog text`

### Issue: "Export failed"

**Possible Causes**:
1. Audio files not created
   ```bash
   ls -la output/mofa-cast/dora/
   ```

2. Audio mixer error
   - Check file format (must be WAV)
   - Check sample rate consistency
   - Check console logs for mixer errors

---

## Performance Benchmarks

### Expected Processing Times

**Small Script** (6 messages, ~2 segments):
- Import: < 1 second
- Refine: 1-2 seconds (MockRefiner)
- Synthesize: 5-10 seconds (depends on Kokoro backend)
- Export: < 1 second
- **Total**: ~10-15 seconds

**Medium Script** (50 messages, ~20 segments):
- Import: < 1 second
- Refine: 2-3 seconds
- Synthesize: 30-60 seconds
- Export: 1-2 seconds
- **Total**: ~35-65 seconds

**Large Script** (200 messages, ~100 segments):
- Import: 1-2 seconds
- Refine: 5-10 seconds
- Synthesize: 3-5 minutes
- Export: 5-10 seconds
- **Total**: ~4-6 minutes

### Backend Performance

**Kokoro-82M on Apple Silicon (M1/M2/M3)**:
- MLX backend: 6.6x realtime (fastest)
  - 10 seconds audio → 1.5 seconds synthesis
- CPU backend: 4.1x realtime
  - 10 seconds audio → 2.4 seconds synthesis

**Comparison**:
- Real-time (1x): 10 seconds audio → 10 seconds synthesis
- OpenAI TTS (cloud): ~2-3x (but requires internet, costs money)
- MockTtsEngine: Instant (test tones only)

---

## Advanced Testing

### Test with Real AI

Set OpenAI API key:
```bash
export OPENAI_API_KEY="sk-..."
./target/release/mofa-studio-shell
```

The "Refine Script" will now use GPT-4 instead of MockRefiner.

### Test with Different TTS Voices

Edit `dataflow/batch-tts.yml`:
```yaml
kokoro-tts:
  env:
    VOICE: "bf_alice"  # Try: af_heart, bm_george, zf_xiaoyi
    LANGUAGE: "en"     # Try: zh, ja, ko
    SPEED: "1.2"       # Try: 0.8 (slow), 1.5 (fast)
```

### Test with Multi-language Scripts

Create a test script with mixed languages:
```
[SpeakerA] Hello, welcome to the podcast.
[SpeakerB] 你好，感谢收听。
[SpeakerA] こんにちは、ありがとうございます。
[SpeakerB] 안녕하세요, 감사합니다.
```

Set appropriate voices in dataflow config for each language.

---

## Success Criteria

✅ **All steps complete without errors**
✅ **Audio files created in `output/mofa-cast/dora/`**
✅ **Exported podcast file plays correctly**
✅ **Audio quality is clear and understandable**
✅ **Speaker voices are distinct**
✅ **No audio gaps or overlaps**
✅ **Silence between segments is natural (0.5s)**

---

## Next Steps After Testing

If all tests pass:

1. **Performance Optimization**
   - Adjust segment size for better balance
   - Optimize silence duration
   - Test with larger scripts

2. **Feature Enhancements**
   - Add TTS configuration UI (backend/voice/speed controls)
   - Implement real-time progress visualization
   - Add audio preview before export

3. **Documentation**
   - Update user guide with screenshots
   - Create video tutorial
   - Add troubleshooting FAQ

4. **Integration Testing**
   - Test with different transcript formats
   - Test with edge cases (very short/long scripts)
   - Test error recovery (cancel synthesis, restart)

---

## Notes

- **Development Status**: P0.6 Complete (Dora integration)
- **Local-First**: No cloud API required for TTS (Kokoro)
- **Privacy**: All processing happens on your machine
- **Free**: No costs for TTS synthesis

**For issues or questions**, check:
- `docs/ARCHITECTURE.md` - Technical details
- `docs/TTS_INTEGRATION.md` - TTS engine options
- `docs/KOKORO_TTS_GUIDE.md` - Kokoro TTS details
- `README.md` - Project overview
