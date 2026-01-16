# MoFA Cast Known Issues

**Last Updated**: 2026-01-15
**Version**: 0.6.0

## Critical Issues

### Issue #1: TextInput Not Editable (BLOCKING)

**Status**: 🔴 OPEN - High Priority
**Severity**: Critical - Core functionality broken
**Affected Component**: `script_editor` TextInput in screen.rs
**Impact**: Users cannot edit imported scripts, breaking the core workflow

**Symptoms**:
- ❌ Clicking on TextInput doesn't show cursor
- ❌ Cannot type new text
- ❌ Cannot select text with mouse
- ❌ Cannot delete existing text
- ❌ No visual feedback when clicking

**Attempts to Fix**:
1. **Attempt 1** - Added custom `instance hover: 0.0` and `instance focus: 0.0`
   - Result: ❌ Made problem worse, interfered with TextInput's internal state
   - Code: Added custom instances + focus ring with `sdf.stroke()`

2. **Attempt 2** - Removed custom instances and simplified to match mofa-fm
   - Result: ❌ Still not editable
   - Code: Removed all custom instances, simplified draw_bg to basic configuration
   - Current state: Matches mofa-fm's working TextInput exactly

**Comparison with Working Example** (mofa-fm prompt_input):
```rust
// mofa-fm (WORKS ✅)
prompt_input = <TextInput> {
    width: Fill, height: Fit
    padding: {left: 12, right: 12, top: 10, bottom: 10}
    empty_text: "Enter prompt to send..."
    draw_bg: { ... }  // Only dark_mode instance
    draw_text: { ... }  // Only dark_mode instance
    draw_selection: { color: (INDIGO_200) }
}

// mofa-cast (NOT WORKING ❌)
script_editor = <TextInput> {
    width: Fill, height: Fill  // Different: Fill vs Fit
    text: "Click 'Import Script'..."  // Different: text vs empty_text
    padding: {left: 12, right: 12, top: 10, bottom: 10}
    draw_bg: { ... }  // Same: Only dark_mode instance
    draw_text: { ... }  // Same: Only dark_mode instance, plus word: Wrap
    draw_selection: { color: (INDIGO_200) }
}
```

**Key Differences**:
1. `height: Fill` vs `height: Fit` ⚠️
2. `text: "..."` vs `empty_text: "..."` ⚠️
3. `word: Wrap` in draw_text (mofa-fm doesn't have this)

**Potential Causes**:
1. **Layout issue**: `height: Fill` might prevent TextInput from calculating proper hit areas
2. **Container hierarchy**: script_editor is nested deeper (editor_container → script_panel → script_editor)
3. **Event propagation**: Parent containers might be capturing events before TextInput receives them
4. **Makepad version issue**: Different Makepad versions might have different behaviors
5. **Z-order/focus management**: Another widget might be stealing focus/events

**Next Investigation Steps**:
1. ✅ Check if mofa-fm TextInput is actually working (user reports ALL TextInputs broken)
2. Check container hierarchy and event handling
3. Try changing `height: Fill` → `height: Fit`
4. Try changing `text:` → `empty_text:`
5. Remove `word: Wrap` to match mofa-fm exactly
6. Check if there's a global event handler interfering
7. Look for any `set_enabled(false)` or disabled state
8. Check Makepad documentation for TextInput requirements

**Workarounds** (if fix is complex):
1. Use external editor (VS Code, TextEdit) for script editing
2. Add "Open in External Editor" button that opens script in default editor
3. Focus on TTS synthesis workflow, defer editing to v0.7.0

**References**:
- mofa-fm working example: `apps/mofa-fm/src/screen/mod.rs:603-628`
- mofa-cast broken example: `apps/mofa-cast/src/screen.rs:395-420`
- Known issue note: mofa-fm comment at line 1435: "TextInput apply_over causes errors"

---

## Medium Priority Issues

### Issue #2: Dark Mode Not Applied to TextInput

**Status**: 🟡 KNOWN LIMITATION
**Severity**: Medium - Visual only, doesn't affect functionality
**Affected Component**: `script_editor` dark_mode instance

**Description**:
TextInput apply_over causes "target class not found" errors (from mofa-fm code comment at line 1435).
Currently, we CANNOT use `apply_over` to update TextInput's dark_mode instance.

**Workaround**:
- TextInput uses its internal `dark_mode` instance (default 0.0 = light mode)
- In dark mode, background might not update correctly

**Potential Solutions**:
1. Find alternative method to update TextInput instance variables
2. Use different widget that supports dynamic theme switching
3. Accept light-mode-only TextInput for now

---

## Low Priority Issues

### Issue #3: Code Cleanup Required

**Status**: 🟢 PLANNED
**Severity**: Low - Aesthetics and maintainability
**Affected Component**: Various

**Description**:
- Unused field warnings (segmenter in tts_batch.rs:269)
- Naming convention warnings (normalize_dB in audio_mixer.rs:24)
- Total: 11 warnings in mofa-cast lib

**Action**: Run `cargo fix --lib -p mofa-cast` to apply 4 suggestions

---

## Resolved Issues

### Issue #4: Dual Editor UI Still Showing (RESOLVED ✅)

**Status**: ✅ FIXED in v0.6.0
**Fix**: Replaced dual editor UI with single script_editor using Python script

### Issue #5: Script Refiner References (RESOLVED ✅)

**Status**: ✅ FIXED in v0.6.0
**Fix**: Removed all script_refiner imports and state fields

---

## Issue Tracking Template

For new issues, use this template:

```markdown
### Issue #N: [Title]

**Status**: 🔴/🟡/🟢 OPEN/KNOWN/FIXED
**Severity**: Critical/Medium/Low
**Affected Component**: [Component name]
**Impact**: [Description of impact]

**Symptoms**:
- ❌ [Symptom 1]
- ❌ [Symptom 2]

**Attempts to Fix**:
1. **Attempt 1** - [Description]
   - Result: ✅/❌ [Outcome]
   - Code: [Code snippet or reference]

**Potential Causes**:
1. [Cause 1]
2. [Cause 2]

**Next Steps**:
1. [ ] [Step 1]
2. [ ] [Step 2]

**Workarounds**:
- [Workaround 1]
- [Workaround 2]
```
