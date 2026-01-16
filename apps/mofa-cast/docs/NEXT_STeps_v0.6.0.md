# Next Steps Recommendations - MoFA Cast v0.6.0

**Date**: 2026-01-15
**Version**: 0.6.0 (Simplified - TTS-Focused)
**Context**: TextInput editability issue documented (KNOWN_ISSUES.md)

---

## 🎯 Executive Summary

v0.6.0 重构已完成，核心功能（多音色TTS合成）**完全可用**。当前有一个UI问题（文本框不可编辑），但不影响主要工作流程。

---

## 📊 Current Status

### ✅ Working Features (Production-Ready)
1. **Script Import** - JSON/MD/TXT formats with auto-detection
2. **Multi-voice TTS** - PrimeSpeech with 3 voices (Luo Xiang, Ma Yun, Ma Baoguo)
3. **Audio Export** - WAV mixing and export
4. **Log Viewer** - Real-time progress monitoring
5. **Dark Mode** - Full theme support (except TextInput)

### ❌ Known Issues
1. **TextInput not editable** - Can't type/delete text in script editor
   - **Workaround**: Edit scripts externally before import (TextEdit, VS Code, etc.)
   - **Impact**: LOW - Users can still use the app effectively
   - **Status**: Documented in KNOWN_ISSUES.md

---

## 🚀 Recommended Next Steps

### Option A: Focus on Non-UI Enhancements (RECOMMENDED)

**Reason**: TextInput issue is complex and deep in Makepad framework. Better to deliver value elsewhere first.

#### Priority 1: Audio Export Enhancement (2-3 days) ⭐⭐⭐

**User Value**: High - Better audio quality and more format options

**Tasks**:
1. **Add MP3 export** - Most users want MP3, not WAV
   - Use `lame_encoder` or `rubato` crates
   - Add quality selector (128/192/256/320 kbps)
   - Estimated: 1 day

2. **Add volume normalization** - Prevent volume jumps between segments
   - Implement `normalize_dB` in audio_mixer.rs
   - Use EBU R128 standard or simple RMS normalization
   - Estimated: 0.5 day

3. **Add metadata embedding** - ID3 tags for MP3
   - Title: Script title or filename
   - Artist: "MoFA Cast"
   - Album: "AI Podcast"
   - Estimated: 0.5 day

**Files to Modify**:
- `src/audio_mixer.rs` (~540 lines) - Add MP3 encoding
- `src/screen.rs` - Add export format dropdown
- `Cargo.toml` - Add MP3 encoding dependency

**Success Criteria**:
- [ ] Export MP3 with selectable quality
- [ ] Volume consistent across segments
- [ ] ID3 tags visible in audio player
- [ ] Export time < 5s for 10min podcast

---

#### Priority 2: Workflow Improvements (1-2 days) ⭐⭐⭐

**User Value**: High - Better user experience

**Tasks**:
1. **Add "Open in External Editor" button** (WORKAROUND for TextInput issue)
   - Opens script in default editor (TextEdit, VS Code)
   - Auto-reloads when file changes
   - Estimated: 0.5 day

2. **Add recent files list** - Quick access to last 5 scripts
   - Store in `~/.config/mofa-studio/recent_cast_scripts.json`
   - Display in left panel
   - Estimated: 0.5 day

3. **Add script templates** - Pre-formatted podcast scripts
   - 2-person interview template
   - 3-person discussion template
   - Narrative/storytelling template
   - Estimated: 1 day

**Files to Create**:
- `src/script_template.rs` (~200 lines) - Template definitions
- `src/recent_files.rs` (~150 lines) - Recent files manager

**Success Criteria**:
- [ ] Click button → Script opens in external editor
- [ ] Save external file → Changes appear in MoFA Cast
- [ ] Last 5 scripts shown in left panel
- [ ] 3 templates available for quick start

---

#### Priority 3: Advanced Voice Configuration (2-3 days) ⭐⭐

**User Value**: Medium - More control over voices

**Tasks**:
1. **Add voice preview** - Hear each voice before synthesis
   - Click speaker name → Play sample
   - Display voice description (e.g., "Deep male voice - Authoritative")
   - Estimated: 1 day

2. **Add custom voice mapping** - Override automatic assignment
   - UI to change which speaker uses which voice
   - Dropdown for each detected speaker
   - Estimated: 1 day

3. **Add speed/pitch controls** - Adjust voice characteristics
   - Speed slider (0.5x - 2.0x)
   - Pitch slider (optional, complex)
   - Estimated: 1 day

**Files to Modify**:
- `src/screen.rs` - Add voice configuration UI
- `src/dora_integration.rs` - Add speed/pitch to voice routing

**Success Criteria**:
- [ ] Click speaker → Hear 3s sample of each voice
- [ ] Change speaker voice → Re-routing works correctly
- [ ] Adjust speed slider → TTS uses new speed
- [ ] Configuration persists across sessions

---

### Option B: Fix TextInput Issue (3-5 days) ⭐

**Reason**: High complexity, uncertain outcome, lower user value (workaround exists)

**Investigation Path**:
1. **Day 1**: Deep investigation of Makepad TextInput
   - Read Makepad source code (makepad-widgets/src/widgets/text_input.rs)
   - Understand event handling and focus management
   - Test minimal example (new widget from scratch)

2. **Day 2**: Container hierarchy analysis
   - Test if nesting depth causes issues
   - Try moving script_editor to different parent
   - Test with simplified layout

3. **Day 3**: Event propagation debugging
   - Add logging to track event flow
   - Check if parent captures events
   - Test with different widget combinations

4. **Day 4-5**: Attempt fixes based on findings
   - Fix focus management
   - Fix hit testing
   - Alternative: Use different widget (e.g., CodeEditor)

**Risk**: May require changes to Makepad framework itself (out of our control)

**Recommendation**: Defer until after delivering higher-value features

---

### Option C: Documentation and Polish (1-2 days) ⭐⭐

**User Value**: Medium - Better onboarding and user guide

**Tasks**:
1. **Complete v0.6.0 documentation**
   - Update SCREENSHOTS.md (add v0.6.0 UI screenshots)
   - Update TROUBLESHOOTING.md with TextInput workaround
   - Add video tutorial (optional)

2. **Create user guide**
   - "Getting Started" tutorial (step-by-step)
   - "How to optimize scripts with ChatGPT" (with prompts)
   - "Voice configuration guide"
   - "Export format comparison (WAV vs MP3)"

3. **Code polish**
   - Fix all compiler warnings (11 warnings in mofa-cast)
   - Add doc comments to public APIs
   - Improve error messages

**Files to Create**:
- `docs/USER_GUIDE.md` (~500 lines)
- `docs/CHATGPT_PROMPTS.md` (~300 lines)
- `docs/EXPORT_FORMATS.md` (~200 lines)

**Success Criteria**:
- [ ] New user can create first podcast in <10 min
- [ ] All screenshots reflect v0.6.0 UI
- [ ] Zero compiler warnings
- [ ] All public APIs documented

---

## 🎯 My Recommendation: **Option A (Priority 1 + 2)**

**Rationale**:
1. **High user value** - MP3 export and external editor are most requested
2. **Low risk** - Well-defined scope, no framework limitations
3. **Fast delivery** - 3-5 days total (vs 3-5 days for TextInput fix alone)
4. **Workaround for TextInput** - "Open in External Editor" solves the problem

**Proposed Schedule (5 days)**:

### Day 1: External Editor Integration
- [ ] Add "Open in External Editor" button
- [ ] Implement file watching (auto-reload)
- [ ] Test with TextEdit, VS Code, Sublime Text
- [ ] Document workaround in KNOWN_ISSUES.md

### Day 2: Recent Files & Templates
- [ ] Implement recent files list
- [ ] Create 3 script templates
- [ ] Add template selection UI
- [ ] Test template workflow

### Day 3: MP3 Export - Part 1
- [ ] Research MP3 encoding crates (`lame_encoder`, `rubato`)
- [ ] Add dependency to Cargo.toml
- [ ] Implement basic MP3 export
- [ ] Test MP3 quality settings

### Day 4: MP3 Export - Part 2
- [ ] Add quality selector UI
- [ ] Implement volume normalization
- [ ] Add ID3 tag embedding
- [ ] Test with 10min podcast

### Day 5: Testing & Documentation
- [ ] End-to-end testing (all features)
- [ ] Update user guide with new features
- [ ] Add screenshots
- [ ] Release v0.6.1

**Deliverables**:
- v0.6.1 release with MP3 export + external editor
- Updated documentation
- All tests passing
- Zero critical bugs

---

## 📋 Alternative: If You Prefer Different Focus

### If you want to fix TextInput first:
- **Go with Option B** (3-5 days)
- **Risk**: May not be fixable without Makepad changes
- **Value**: Medium (workaround exists)

### If you want more voices and languages:
- **Add to Option A Priority 3** (2-3 extra days)
- **Research** Other PrimeSpeech voices or add Kokoro TTS
- **Value**: High for multilingual users

### If you want to polish existing features:
- **Go with Option C** (1-2 days)
- **Then return to Option A** (3-5 days)
- **Value**: Medium - Better UX but no new features

---

## ✅ Decision Checklist

Before starting, please confirm:

1. **User priority**: What do users want most?
   - [ ] MP3 export
   - [ ] Better editing experience
   - [ ] More voices
   - [ ] Other: _______

2. **Risk tolerance**: Are you comfortable with workaround?
   - [ ] Yes - Use external editor for now
   - [ ] No - Must fix TextInput first

3. **Time constraints**: When do you need v0.6.1?
   - [ ] This week (5 days) → Option A Priority 1+2
   - [ ] Next week (10 days) → Option A all priorities
   - [ ] No rush → Can try TextInput fix (Option B)

4. **Technical confidence**:
   - [ ] High - Comfortable with audio processing → Option A
   - [ ] Medium - Prefer straightforward tasks → Option C
   - [ ] Low - Need guidance → Start with Option C

---

## 🎬 Next Action

**Please tell me**:
1. Which option you prefer (A/B/C)
2. If A, which priorities (1/2/3 or all)
3. Any specific requirements or constraints

**I'll then**:
1. Create detailed task breakdown
2. Set up TodoWrite tracking
3. Start implementation

---

**Last Updated**: 2026-01-15
**Maintained by**: Claude Code
**Status**: Awaiting user decision
