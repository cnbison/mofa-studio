# MoFA Cast - Development Guide

> Building a chat-to-podcast transformation app

---

## Overview

**MoFA Cast** converts chat transcripts into podcast-ready audio with AI script refinement and multi-voice TTS.

### Key Challenges
1. Parsing diverse chat formats
2. Maintaining speaker identity
3. Batch processing (not real-time)
4. Audio synchronization

---

## Development Phases

### Phase 1: Transcript Parsing (Week 1)

**Goal**: Import and display chat transcripts

**Tasks**:
- [ ] Define `Transcript` and `Message` data structures
- [ ] Implement plain text parser (speaker: message format)
- [ ] Implement JSON parser (OpenAI format)
- [ ] Implement Markdown parser (GitHub format)
- [ ] Auto-detect format
- [ ] Display parsed transcript in UI

**Files**: `transcript_parser.rs` (~200 lines)

**Test Data**:
```
Alice: Hey, how are you?
Bob: I'm good! Working on a new project.
Alice: That sounds exciting! Tell me more.
```

---

### Phase 2: Script Editor UI (Week 2)

**Goal**: Build editable script view

**Tasks**:
- [ ] Create split-view layout (original | refined)
- [ ] Implement text editor widget
- [ ] Add speaker color coding
- [ ] Add line numbers
- [ ] Support Markdown preview

**Files**: `screen.rs` (~500 lines)

**Reference**: Use Makepad `TextInput` with `multiline: true`

---

### Phase 3: AI Refinement (Week 3)

**Goal**: Transform raw chat into polished script

**Tasks**:
- [ ] Integrate LLM API (OpenAI/Claude)
- [ ] Design refinement prompt
- [ ] Handle streaming responses
- [ ] Show progress indicator
- [ ] Allow manual editing after AI

**Files**: `script_refiner.rs` (~250 lines)

**Example Transformation**:
```
Before:
Alice: umm yeah so like i think we should maybe try that
Bob: lol ok

After:
[Host] Alice suggests an interesting approach.
[Alice] I think we should try that strategy.
[Host] Bob agrees enthusiastically.
[Bob] That sounds like a great idea!
```

---

### Phase 4: Batch TTS (Week 4-5)

**Goal**: Convert script to audio

**Tasks**:
- [ ] Split script by speaker
- [ ] Spawn Dora TTS nodes (one per speaker)
- [ ] Queue segments for parallel processing
- [ ] Monitor progress (X/N segments done)
- [ ] Save audio files
- [ ] Handle TTS errors gracefully

**Files**: `tts_batch.rs` (~300 lines)

**Pattern**:
```rust
pub struct TTSBatch {
    segments: Vec<Segment>,
    completed: Vec<PathBuf>,  // Audio files
    tx: Sender<TTSRequest>,
    rx: Receiver<TTSResult>,
}

impl TTSBatch {
    pub fn synthesize_all(&mut self) -> Result<()> {
        // Spawn workers
        for i in 0..2 {  // 2 speakers
            self.spawn_tts_worker(i);
        }

        // Queue segments
        for seg in &self.segments {
            self.tx.send(TTSRequest { text: seg.text.clone() });
        }

        // Collect results
        while self.completed.len() < self.segments.len() {
            if let Ok(result) = self.rx.recv() {
                self.completed.push(result.audio_path);
            }
        }
        Ok(())
    }
}
```

---

### Phase 5: Audio Mixing (Week 6)

**Goal**: Combine segments into final podcast

**Tasks**:
- [ ] Concatenate audio files
- [ ] Normalize volume
- [ ] Add fade in/out
- [ ] Add background music (optional)
- [ ] Export as MP3

**Files**: `audio_mixer.rs` (~200 lines)

**Dependencies**:
```toml
hound = "3.5"        # WAV I/O
symphonia = "0.5"    # Audio decoding
rubato = "0.14"      # Resampling
```

---

## Implementation Patterns

### 1. Format Detection

```rust
pub enum TranscriptFormat {
    PlainText,
    Json,
    Markdown,
}

impl TranscriptFormat {
    pub fn detect(content: &str) -> Self {
        if content.starts_with('{') || content.starts_with('[') {
            TranscriptFormat::Json
        } else if content.contains("```") || content.contains("##") {
            TranscriptFormat::Markdown
        } else {
            TranscriptFormat::PlainText
        }
    }
}
```

### 2. Speaker Identification

```rust
pub fn extract_speakers(messages: &[Message]) -> Vec<Speaker> {
    let mut speakers = HashSet::new();
    for msg in messages {
        speakers.insert(msg.speaker.clone());
    }

    speakers.into_iter()
        .enumerate()
        .map(|(i, name)| Speaker {
            name,
            voice_id: format!("voice_{}", i),
            color: SPEAKER_COLORS[i % SPEAKER_COLORS.len()],
        })
        .collect()
}
```

### 3. Progress Tracking

```rust
impl CastScreen {
    fn update_progress(&mut self, cx: &mut Cx) {
        let progress = self.tts_batch.completed.len() as f64
            / self.tts_batch.segments.len() as f64;

        self.view.label(ids!(progress_panel.status_text))
            .set_text(cx, &format!("Synthesizing: {}/{}",
                self.tts_batch.completed.len(),
                self.tts_batch.segments.len()));

        self.view.view(ids!(progress_panel.progress_bar))
            .apply_over(cx, live!{
                draw_bg: { progress: (progress) }
            });
    }
}
```

---

## Testing Strategy

### Unit Tests
- [ ] Parser correctness (each format)
- [ ] Speaker extraction accuracy
- [ ] Audio concatenation (no gaps/overlaps)

### Integration Tests
- [ ] End-to-end: text → audio file
- [ ] Large transcripts (1000+ messages)
- [ ] Edge cases (missing speaker, empty messages)

### Manual Tests
- [ ] Import real WhatsApp chat
- [ ] Edit refined script
- [ ] Export and listen to podcast

---

## Dependencies

```toml
[dependencies]
makepad-widgets.workspace = true
mofa-widgets = { path = "../../mofa-widgets" }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
chrono = "0.4"              # Timestamp parsing
regex = "1.10"              # Text parsing
tokio = { version = "1", features = ["full"] }
reqwest = { version = "0.11", features = ["json"] }  # LLM API
hound = "3.5"               # WAV I/O
symphonia = "0.5"           # Audio decoding
```

---

**Last Updated**: 2026-01-07
**Target Complexity**: Medium (batch processing, no real-time)
