# TTS Integration Troubleshooting Guide

**Last Updated**: 2026-01-14
**Status**: Production-ready (all issues resolved)

This document records critical bugs encountered during TTS integration and their solutions.

---

## Bug #1: Only 2/10 Audio Segments Generated (Batch Sending)

**Date**: 2026-01-13
**Symptom**: Only 2 audio files generated (intro + outro), middle segments missing
**Affected**: Both Kokoro TTS and PrimeSpeech TTS
**Root Cause**: Batch sending overwhelmed TTS nodes

### Symptoms

```
[INFO] Sending segment 1/10: 95 chars
[INFO] Sending segment 2/10: 71 chars
...
[INFO] Sending segment 10/10: 46 chars  // All sent in 500ms
[INFO] Received audio segment: 128000 samples (segment 1)
[INFO] Received audio segment: 90880 samples (segment 2)
// Silence... only 2 segments processed
```

### Root Cause Analysis

**Send Rate vs Process Rate Mismatch**:
- Send rate: 1 segment / 50ms = **20 segments/second**
- Process rate: 1 segment / 2-4s = **0.25-0.5 segments/second**
- **40x mismatch** → Dora queue overflow

**What Happened**:
1. mofa-cast sends 10 segments in 500ms (batch mode)
2. Dora queue fills up (default: ~10-100 messages)
3. TTS processes first 2 segments (slow)
4. Queue overflows → remaining 8 segments dropped
5. TTS stops processing (thinks queue is empty)

### Solution

**Change**: `src/dora_integration.rs` - Sequential sending with handshake

**Before** (Batch - BROKEN):
```rust
for (idx, segment) in segments.into_iter().enumerate() {
    bridge.send("text", DoraData::Text(text))?;
    std::thread::sleep(50ms);  // Tiny delay
}
```

**After** (Sequential - WORKING):
```rust
// Send only FIRST segment
state.write().pending_segments = segments.clone();
bridge.send("text", DoraData::Text(segments[0].text))?;

// In poll_events loop:
if input_id == "segment_complete" {
    let idx = state.read().current_segment_index;
    if idx + 1 < state.read().pending_segments.len() {
        let next = &state.read().pending_segments[idx + 1];
        bridge.send("text", DoraData::Text(next.text))?;  // Send next
        state.write().current_segment_index = idx + 1;
    }
}
```

### Result

| Metric | Batch (Broken) | Sequential (Fixed) |
|--------|----------------|-------------------|
| Segments sent | 10 in 500ms | 10 over ~40s |
| Segments processed | 2/10 (20%) | 10/10 (100%) |
| Reliability | ❌ Unreliable | ✅ 100% reliable |

### Lessons Learned

1. **Batch processing ≠ Faster processing**
   - Sending fast doesn't mean processing fast
   - Queue overflow causes data loss
   - Backpressure is essential

2. **TTS nodes are pull-based, not push-based**
   - They process at their own pace (2-4s per segment)
   - Cannot be sped up by sending faster
   - Need flow control mechanism

3. **Real-time vs Batch patterns**
   - Real-time (mofa-fm): Natural flow control (one at a time)
   - Batch (mofa-cast): Must implement explicit flow control

4. **Testing approach**
   - Same symptom across different TTS engines → points to architecture
   - User observation was correct: "应该跟这两个节点无关"
   - Problem was in integration layer, not TTS nodes

---

## Bug #2: Only 1/10 Audio Segment Generated (Event Forwarding)

**Date**: 2026-01-14
**Symptom**: Only 1 audio file generated (sequential sending not working)
**Affected**: PrimeSpeech TTS (after sequential sending implemented)
**Root Cause**: Bridge didn't forward `segment_complete` event

### Symptoms

```
[INFO] Sending FIRST segment 1/10: 95 chars
[INFO] ✓ First segment sent, waiting for segment_complete
[INFO] Received audio segment: 214400 samples, 32000Hz
[INFO] ✅ Saved segment 1 of 10: segment_000_unknown.wav (6.70s)
[INFO] Segment complete signal received  // Logged in cast_controller
// Silence... no more segments sent
```

**Expected behavior**:
```
[INFO] 📢 Segment complete signal received  // Should appear but didn't
[INFO] 🚀 Sending NEXT segment 2/10
```

### Root Cause Analysis

**Missing Event Forwarding in Bridge**:

In `mofa-dora-bridge/src/widgets/cast_controller.rs:190-192`:
```rust
"segment_complete" => {
    info!("Segment complete signal received");
    // ❌ MISSING: No event sent to dora_integration.rs!
}
```

**Compare with `audio` handling (which works)**:
```rust
"audio" => {
    info!("Received audio input from dora");
    let _ = event_sender.send(BridgeEvent::DataReceived {  // ✅ Event sent!
        input_id: input_id.to_string(),
        data: DoraData::Audio(audio),
        metadata: event_meta,
    });
}
```

**Sequential Sending Flow**:
1. dora_integration sends segment 1
2. TTS processes and sends `segment_complete` to **cast_controller**
3. **cast_controller must forward event to dora_integration** ← STEP MISSING!
4. dora_integration receives event → sends segment 2
5. Repeat...

**Without step 3**: Loop never continues → only 1 segment

### Solution

**Change**: `mofa-dora-bridge/src/widgets/cast_controller.rs:190-197`

**Before** (BROKEN):
```rust
"segment_complete" => {
    info!("Segment complete signal received");
}
```

**After** (WORKING):
```rust
"segment_complete" => {
    info!("Segment complete signal received");
    // ✅ FIX: Forward event to trigger next segment
    let _ = event_sender.send(BridgeEvent::DataReceived {
        input_id: input_id.to_string(),
        data: DoraData::Empty,  // No data needed, just signal
        metadata: event_meta,
    });
}
```

### Result

**Before fix**:
```
[INFO] Sending FIRST segment 1/10: 95 chars
[INFO] Received audio segment: 214400 samples, 32000Hz
[INFO] ✅ Saved segment 1 of 10
// Stops here...
```

**After fix**:
```
[INFO] Sending FIRST segment 1/10: 95 chars
[INFO] Received audio segment: 214400 samples, 32000Hz
[INFO] 📢 Segment complete signal received  // Now appears!
[INFO] 🚀 Sending NEXT segment 2/10: 71 chars
[INFO] ✓ Segment 2/10 sent
[INFO] Received audio segment: 90880 samples, 32000Hz
[INFO] 📢 Segment complete signal received
[INFO] 🚀 Sending NEXT segment 3/10: 55 chars
...
[INFO] ✅ All 10 segments processed!
```

### Lessons Learned

1. **Check both sides of bridge communication**
   - ✅ UI → Bridge: Events sent correctly
   - ✅ Bridge → Dora: Data sent correctly
   - ❌ **Dora → Bridge → UI**: Event forwarding was broken!

2. **Bridge pattern common oversight**
   - Middle component must forward events in **both directions**
   - Easy to forget "return path" (Dora → Bridge → UI)
   - Always verify complete round-trip communication

3. **Debugging tip**
   - If sequential sending stops after first item:
     - Check if "trigger next" events are being sent
     - Verify bridge is forwarding events (not just consuming them)
     - Add logs on both sides of bridge

4. **Silent failures**
   - `segment_complete` was received (logged in cast_controller)
   - But event never sent to dora_integration
   - No error, just silent failure → hard to debug

---

## Summary of Fixes

### Files Modified

1. **`src/dora_integration.rs`** (~80 lines)
   - Added sequential sending logic
   - Added `pending_segments`, `current_segment_index`, `total_segments` to `DoraState`
   - Added `segment_complete` handler in `poll_events`

2. **`mofa-dora-bridge/src/widgets/cast_controller.rs`** (6 lines)
   - Added event forwarding for `segment_complete`
   - Uses `DoraData::Empty` as signal

3. **`dataflow/test-primespeech-simple.yml`** (new file)
   - Simplified dataflow (no text-segmenter)
   - Direct connection: mofa-cast-controller → primespeech-tts

### Architecture Changes

**Before** (Batch - 2/10 segments):
```
UI → [Send all 10 at once] → Bridge → Dora Queue (overflow) → TTS (processes 2) → Stop
```

**After** (Sequential - 10/10 segments):
```
UI → [Send segment 1] → Bridge → Dora → TTS (processes 1) → segment_complete
                                                                    ↓
UI ← [Trigger next] ← Bridge ← [Forward event] ← Dora ← segment_complete
```

### Test Results

**Date**: 2026-01-14
**Result**: ✅ All 10 segments generated successfully
**Status**: Production-ready

---

## Prevention Guidelines

### When Implementing Batch Processing

1. **Check processing time vs send rate**
   - Measure: How long does receiver process one item?
   - Calculate: Maximum sustainable send rate
   - Rule of thumb: Send rate < 0.5 × Process rate

2. **Implement backpressure**
   - Use queue size limits
   - Monitor queue depth
   - Implement flow control signals (ack, complete, etc.)

3. **Prefer sequential sending for slow nodes**
   - TTS: 2-4s per segment → use sequential
   - LLM: 1-10s per request → use sequential
   - Video encoding: variable → use sequential

### When Implementing Bridge Patterns

1. **Verify both directions**
   - Test: UI → Bridge → External System ✓
   - Test: External System → Bridge → UI ← Often forgotten!

2. **Event forwarding checklist**
   - [ ] Control events (start, stop, complete)
   - [ ] Data events (audio, text, binary)
   - [ ] Status events (progress, error, log)
   - [ ] All inputs mapped to outputs?

3. **Add logging on both sides**
   - Bridge receives event → log
   - Bridge forwards event → log
   - Compare logs to find missing events

### Debugging Tips

**Problem**: Only first segment generated
**Check**:
1. Is sequential sending implemented?
2. Are `segment_complete` signals being received? (check bridge logs)
3. Are `segment_complete` events being forwarded? (check UI logs)
4. Does UI have handler for `segment_complete` event?

**Problem**: Only 2/10 segments generated
**Check**:
1. Is batch sending overwhelming receiver?
2. What is send rate vs process rate?
3. Is Dora queue overflowing?
4. Try sequential sending

---

## References

- **TTS_INTEGRATION.md**: Full technical decision document
- **ARCHITECTURE.md**: System architecture and data flow
- **Code changes**: See git commits for detailed diffs
- **Test logs**: Check `target/release/mofa-studio` output for examples

---

**Document Status**: ✅ Complete (all critical bugs documented)
**Last Updated**: 2026-01-14
**Maintainer**: Claude Code (with user feedback)
