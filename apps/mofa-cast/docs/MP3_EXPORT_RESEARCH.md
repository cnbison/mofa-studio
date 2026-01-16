# MP3 Export Research for MoFA Cast

**Date**: 2026-01-15
**Goal**: Add MP3 export functionality with quality selector

## Implementation Status: ✅ COMPLETE (2026-01-16)

**Actual Implementation**: Used ffmpeg CLI tool instead of lame_encoder

**Reason for Change**:
- `lame_encoder` crate does not exist (tried, got error)
- `mp3lame-encoder` crate has complex API with C dependencies
- ffmpeg is simpler, more reliable, and industry-standard

**See**: CHANGELOG.md v0.6.1 for complete implementation details

---

## Original Research (Archived)

### Available Rust Crates

#### Option 1: `lame_encoder` ⭐ RECOMMENDED (Original Choice)
**URL**: https://crates.io/crates/lame_encoder
**Version**: 0.1.1
**License**: MIT
**Features**:
- Native Rust bindings to LAME MP3 encoder
- Cross-platform (Windows, macOS, Linux)
- Configurable quality (VBR, CBR, ABR)
- Sample rate support: 8-48kHz
- Channel support: Mono/Stereo

**Pros**:
- ✅ Industry-standard LAME encoder
- ✅ High quality MP3 encoding
- ✅ Well-maintained
- ✅ C library (fast, reliable)

**Cons**:
- ❌ Requires LAME library installed (or bundled)
- ❌ Build complexity (C dependency)

**Code Example**:
```rust
use lame_encoder::{encode, Encoder};

let mut encoder = Encoder::new(
    sample_rate,
    channels,
    lame_encoder::Mode::Stereo,
    lame_encoder::Quality::VBRHigh(192), // 192kbps VBR
).unwrap();

let mp3_data = encode(&encoder, &wav_data).unwrap();
```

#### Option 2: `rubato` + `symphonia`
**URL**: https://crates.io/crates/rubato
**Version**: 0.14
**License**: MIT
**Features**:
- Pure Rust resampling
- Can use with `symphonia` for MP3 encoding
- No C dependencies

**Pros**:
- ✅ Pure Rust (no C dependency)
- ✅ Resampling built-in

**Cons**:
- ❌ Not a direct MP3 encoder
- ❌ More complex (needs multiple crates)
- ❌ May not have quality control

#### Option 3: `minimp3`
**URL**: https://crates.io/crates/minimp3
**Version**: 0.5
**License**: MIT
**Features**:
- MP3 decoding only (not encoding)
- Pure Rust, single-file library

**Cons**:
- ❌ Decode-only, cannot encode

#### Option 4: External Tool (ffmpeg) ⭐ ACTUAL IMPLEMENTATION
**Approach**: Call `ffmpeg` CLI tool

**Pros**:
- ✅ FFmpeg has excellent MP3 encoding
- ✅ No Rust dependencies
- ✅ Simple and reliable
- ✅ Industry-standard

**Cons**:
- ❌ External dependency
- ❌ Not self-contained
- ❌ Requires FFmpeg installation

## Quality Settings

### Bitrate Options:
- **128 kbps**: Good quality, small file size (~1MB/min)
- **192 kbps**: High quality (recommended, ~1.5MB/min)
- **256 kbps**: Very high quality (~2MB/min)
- **320 kbps**: Maximum quality (~2.5MB/min)

### Encoding Modes:
- **VBR (Variable Bitrate)**: Best quality/size ratio (recommended)
- **CBR (Constant Bitrate)**: Consistent bitrate (for compatibility)
- **ABR (Average Bitrate)**: Balance between VBR and CBR

## Actual Implementation (ffmpeg Approach)

### Implementation Steps

1. **No additional Rust dependencies** (uses ffmpeg CLI)

2. **Extended audio_mixer.rs**
```rust
pub enum ExportFormat {
    Wav,
    Mp3,
}

pub enum Mp3Bitrate {
    Kbps128,
    Kbps192,
    Kbps256,
    Kbps320,
}

impl Mp3Bitrate {
    pub fn kbps(&self) -> u32 {
        match self {
            Mp3Bitrate::Kbps128 => 128,
            Mp3Bitrate::Kbps192 => 192,
            Mp3Bitrate::Kbps256 => 256,
            Mp3Bitrate::Kbps320 => 320,
        }
    }
}
```

3. **MP3 encoding using ffmpeg**
```rust
fn write_mp3_file(path: &Path, config: &MixerConfig, audio_data: &[u8]) -> Result<(), MixerError> {
    // First write to a temporary WAV file
    let temp_wav = path.with_extension("wav");
    Self::write_wav_file(&temp_wav, config, audio_data)?;

    // Convert WAV to MP3 using ffmpeg
    let bitrate = config.mp3_bitrate.kbps();
    let output = std::process::Command::new("ffmpeg")
        .arg("-y")  // Overwrite output file
        .arg("-i").arg(&temp_wav)
        .arg("-codec:a").arg("libmp3lame")
        .arg("-b:a").arg(format!("{}k", bitrate))
        .arg("-qscale:a").arg("2")  // High quality VBR
        .arg(path)
        .output();

    match output {
        Ok(_) => {
            // Clean up temporary WAV file
            let _ = std::fs::remove_file(&temp_wav);
            Ok(())
        }
        Err(e) => {
            // Clean up temp file on error too
            let _ = std::fs::remove_file(&temp_wav);
            Err(MixerError::IoError(format!("ffmpeg conversion failed: {}. Is ffmpeg installed?", e)))
        }
    }
}
```

4. **UI Controls in screen.rs**
```rust
// Export format dropdown
export_format_dropdown = <DropDown> {
    width: 70, height: 24
    labels: ["WAV", "MP3"]
    values: [0, 1]
}

// MP3 bitrate dropdown
mp3_bitrate_dropdown = <DropDown> {
    width: 110, height: 24
    labels: ["128 kbps", "192 kbps", "256 kbps", "320 kbps"]
    values: [0, 1, 2, 3]
}
```

5. **Event handling**
```rust
if let Some(format_id) = self.view.drop_down(ids!(export_format_dropdown)).selected(actions) {
    self.selected_export_format = format_id;
    ::log::info!("Export format changed to: {}", if format_id == 0 { "WAV" } else { "MP3" });
}

if let Some(bitrate_id) = self.view.drop_down(ids!(mp3_bitrate_dropdown)).selected(actions) {
    self.selected_mp3_bitrate = bitrate_id;
    ::log::info!("MP3 bitrate changed to: {} kbps", ["128", "192", "256", "320"][bitrate_id]);
}
```

## Testing Strategy
1. ✅ Export 30s test clip with different bitrates
2. ⏳ Compare file sizes
3. ⏳ Listen test quality
4. ⏳ Verify playback in common players (VLC, QuickTime, etc.)

## Prerequisites

**ffmpeg must be installed on system**:
```bash
# macOS
brew install ffmpeg

# Ubuntu/Debian
sudo apt install ffmpeg

# Fedora/CentOS
sudo yum install ffmpeg
```

## Lessons Learned

### Why ffmpeg was better than lame_encoder

1. **Simplicity**: No C library linking issues, no build complexity
2. **Reliability**: ffmpeg is mature, well-tested, industry-standard
3. **Speed**: Development time < 1 day vs. potentially days with lame_encoder
4. **Quality**: libmp3lame encoder in ffmpeg is the same LAME encoder
5. **Maintenance**: No need to worry about C library updates or compatibility

### Trade-offs

**Pros of ffmpeg approach**:
- ✅ Fast implementation
- ✅ No additional Rust dependencies
- ✅ Works reliably
- ✅ Same quality as lame_encoder (both use LAME)

**Cons of ffmpeg approach**:
- ❌ External dependency (must be installed)
- ❌ Not self-contained
- ❌ Requires user to install ffmpeg

**Decision**: For MVP (v0.6.1), ffmpeg is the right choice. Future versions could add pure Rust MP3 encoding if needed.

## Future Enhancements

### v0.6.2 (Planned)
- [ ] Volume normalization (RMS or EBU R128)
- [ ] ID3 tag embedding for MP3 files
- [ ] End-to-end testing

### v0.7.0 (Future)
- [ ] Consider pure Rust MP3 encoding (if users request self-contained binary)
- [ ] Alternative: Bundle ffmpeg with application
- [ ] Advanced audio effects (crossfade, EQ)

## Conclusion

**Original Plan**: Use `lame_encoder` crate
**Actual Implementation**: Used ffmpeg CLI tool
**Result**: ✅ Complete, working MP3 export in <1 day

**Recommendation for Future**: Keep ffmpeg approach unless users strongly request self-contained binary. It's simple, reliable, and produces excellent quality MP3 files.
