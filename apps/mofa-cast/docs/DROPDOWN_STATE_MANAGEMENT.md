# Makepad Dropdown State Management - Complete Guide

**Date**: 2026-01-15
**Version**: v1.0
**Component**: MoFA Cast (mofa-cast)
**Category**: Technical Solution / Pattern

---

## Table of Contents

1. [Problem Description](#problem-description)
2. [Root Cause Analysis](#root-cause-analysis)
3. [Solution Steps](#solution-steps)
4. [Complete Code Example](#complete-code-example)
5. [Best Practices](#best-practices)
6. [Common Pitfalls](#common-pitfalls)
7. [Debugging Checklist](#debugging-checklist)
8. [Related Patterns](#related-patterns)

---

## Problem Description

### Symptoms

1. **Dropdown selection seems to work but has no effect**
   - User selects an option from dropdown (e.g., "JSON" format)
   - Logs show correct value: `Format dropdown changed to: 2`
   - But when user clicks the action button, it always uses default value (0 = Auto Detect)

2. **Event handlers fire but state is not preserved**
   - `selected()` method returns correct value during event
   - But subsequent button click handler sees different value (always 0)

3. **UI changes position but event paths not updated**
   - After moving UI components to different panels
   - Dropdown buttons stop working entirely

### Example Scenario

```rust
// User selects "JSON" from format_dropdown
// Logs show: "Format dropdown changed to: 2"

// But when clicking Import button:
if self.selected_format_id == 0 {
    // Always executes this branch (Auto Detect)
    parser_factory.parse_auto(&content)
} else {
    // This branch never executes even though user selected "JSON"
    parser_factory.parse_with_format(&content, TranscriptFormat::Json)
}
```

---

## Root Cause Analysis

### Issue 1: Missing Field Initialization in live_design

**Problem**: Rust fields declared in struct but not initialized in `live_design!` block.

```rust
// ✅ Field declared in struct
pub struct CastScreen {
    #[rust]
    selected_format_id: usize,  // Default value is 0!
}

// ❌ But NOT initialized in live_design
pub CastScreen = {{CastScreen}} {
    // ... UI components ...
    // Missing: selected_format_id: 0
}
```

**Result**: Field remains at default value (0 for usize), even when dropdown events fire.

### Issue 2: Event Handler Path Mismatch

**Problem**: After moving UI components, event handler paths are not updated.

```rust
// Old structure (before layout change)
main_content.left_panel.templates_section.template_dropdown

// New structure (after moving templates_section)
main_content.right_panel.templates_section.template_dropdown

// ❌ Event handler still uses old path
self.view.drop_down(ids!(main_content.left_panel.templates_section.template_dropdown))
```

**Result**: Events never reach the handler because the component path is invalid.

### Issue 3: Understanding Makepad's Event Model

**Key Insight**: Makepad's `DropDown::selected()` method **only returns a value during the selection event**. You cannot query the dropdown later to get its current value.

```rust
// ❌ WRONG - This won't work
let format_id = self.view.drop_down(ids!(format_dropdown)).selected();
// selected() returns None outside of event context!

// ✅ CORRECT - Save the value immediately when event fires
if let Some(format_id) = self.view.drop_down(ids!(format_dropdown)).selected(actions) {
    self.selected_format_id = format_id;  // Save to field
}

// Later, use the saved value
if self.selected_format_id == 0 { ... }
```

---

## Solution Steps

### Step 1: Declare Rust Fields

Add fields to your widget struct to store dropdown selections:

```rust
#[derive(Live, LiveHook, Widget)]
pub struct CastScreen {
    #[deref]
    view: View,

    // ... other fields ...

    // Dropdown selection states (must be #[rust])
    #[rust]
    selected_format_id: usize,  // 0=Auto, 1=Plain Text, 2=JSON, 3=Markdown

    #[rust]
    selected_template_id: usize,  // 0=2-Person, 1=3-Person, 2=Narrative
}
```

**Best Practices**:
- Use descriptive names: `selected_<dropdown_name>_id`
- Document the mapping: `0=Auto, 1=Plain Text, ...`
- Group related dropdown fields together

### Step 2: Initialize Fields in live_design

**CRITICAL**: Initialize all `#[rust]` fields at the end of the `live_design!` block:

```rust
live_design! {
    pub CastScreen = {{CastScreen}} {
        // ... all UI components ...

        // Rust field initializations (must be at the END)
        selected_format_id: 0      // Default to Auto Detect
        selected_template_id: 0    // Default to first template
    }
}
```

**Common Mistake**: Forgetting to initialize fields in `live_design`. Rust will use default value (0 for usize), which may not match your dropdown's first option.

### Step 3: Handle Dropdown Events

Listen to dropdown change events and save the selection immediately:

```rust
fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
    // ... other event handling ...

    let actions = match event {
        Event::Actions(actions) => actions.as_slice(),
        _ => return,
    };

    // Format dropdown changed
    if let Some(format_id) = self.view.drop_down(
        ids!(main_content.left_panel.import_section.format_dropdown)
    ).selected(actions) {
        ::log::info!("Format dropdown changed to: {}", format_id);
        self.selected_format_id = format_id;  // ✅ Save immediately
    }

    // Template dropdown changed
    if let Some(template_id) = self.view.drop_down(
        ids!(main_content.right_panel.templates_section.template_dropdown)
    ).selected(actions) {
        ::log::info!("Template dropdown changed to: {}", template_id);
        self.selected_template_id = template_id;  // ✅ Save immediately
        // Optional: Auto-load template on selection
        self.load_template(cx, template_id);
    }
}
```

**Key Points**:
- Check component path carefully (left_panel vs right_panel)
- Save to field **immediately** when event fires
- Log the value for debugging
- Optional: Trigger action immediately (auto-load pattern)

### Step 4: Use Saved Values in Action Handlers

```rust
fn handle_file_import(&mut self, cx: &mut Cx) {
    // ... file dialog code ...

    // Use the saved format selection
    let parse_result = if self.selected_format_id == 0 {
        // Auto detect
        parser_factory.parse_auto(&content)
    } else {
        // Use specific format
        let format = match self.selected_format_id {
            1 => TranscriptFormat::PlainText,
            2 => TranscriptFormat::Json,
            3 => TranscriptFormat::Markdown,
            _ => TranscriptFormat::PlainText,
        };

        ::log::info!("Using format: {:?}", format);
        parser_factory.parse_with_format(&content, format)
    };

    // ... rest of handler ...
}
```

### Step 5: Update Event Paths After Layout Changes

When moving UI components, update ALL event handler paths:

```rust
// Before (templates_section in left_panel)
self.view.drop_down(ids!(main_content.left_panel.templates_section.template_dropdown))

// After (templates_section moved to right_panel)
self.view.drop_down(ids!(main_content.right_panel.templates_section.template_dropdown))
```

**Checklist**:
- [ ] dropdown `selected()` events
- [ ] button `clicked()` events
- [ ] label `set_text()` calls
- [ ] Any other widget references

---

## Complete Code Example

### File: `apps/mofa-cast/src/screen.rs`

```rust
// ============================================================================
// PART 1: Declare Rust Fields
// ============================================================================

#[derive(Live, LiveHook, Widget)]
pub struct CastScreen {
    #[deref]
    view: View,

    #[rust]
    transcript: Option<Transcript>,

    #[rust]
    script: Option<String>,

    // ⭐ Dropdown selection states
    #[rust]
    selected_format_id: usize,      // 0=Auto, 1=Plain Text, 2=JSON, 3=Markdown

    #[rust]
    selected_template_id: usize,    // 0=2-Person, 1=3-Person, 2=Narrative

    // ... other fields ...
}

// ============================================================================
// PART 2: Initialize Fields in live_design
// ============================================================================

live_design! {
    use link::theme::*;
    use link::shaders::*;
    use link::widgets::*;
    use mofa_widgets::theme::*;

    pub CastScreen = {{CastScreen}} {
        width: Fill, height: Fill
        flow: Down
        spacing: 12.0

        // ... ALL UI components ...

        main_content = <View> {
            flow: Right

            left_panel = <View> {
                flow: Down

                import_section = <RoundedView> {
                    flow: Down

                    // ⭐ Dropdown component
                    format_dropdown = <DropDown> {
                        width: Fill
                        labels: ["Auto Detect", "Plain Text", "JSON", "Markdown"]
                        values: [0, 1, 2, 3]
                        // ... styling ...
                    }

                    import_button = <Button> {
                        text: "Select File"
                        // ... styling ...
                    }
                }

                // ... other sections ...
            }

            right_panel = <View> {
                flow: Down

                templates_section = <RoundedView> {
                    flow: Down

                    // ⭐ Another dropdown component
                    template_dropdown = <DropDown> {
                        width: Fill
                        labels: ["2-Person Interview", "3-Person Discussion", "Narrative"]
                        values: [0, 1, 2]
                        // ... styling ...
                    }

                    use_template_button = <Button> {
                        text: "Use Template"
                        // ... styling ...
                    }
                }

                // ... other sections ...
            }
        }
    }

    // ⭐⭐⭐ CRITICAL: Initialize all #[rust] fields at the END
    selected_format_id: 0      // Default to Auto Detect
    selected_template_id: 0    // Default to first template
}

// ============================================================================
// PART 3: Handle Dropdown Events
// ============================================================================

impl Widget for CastScreen {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        // ... event handling setup ...

        let actions = match event {
            Event::Actions(actions) => actions.as_slice(),
            _ => return,
        };

        // ⭐ Format dropdown event handler
        if let Some(format_id) = self.view.drop_down(
            ids!(main_content.left_panel.import_section.format_dropdown)
        ).selected(actions) {
            ::log::info!("Format dropdown changed to: {}", format_id);
            self.selected_format_id = format_id;  // Save immediately
        }

        // ⭐ Import button click handler
        if self.view.button(ids!(main_content.left_panel.import_section.import_button))
            .clicked(actions)
        {
            self.handle_file_import(cx);  // Uses saved selected_format_id
        }

        // ⭐ Template dropdown event handler
        if let Some(template_id) = self.view.drop_down(
            ids!(main_content.right_panel.templates_section.template_dropdown)
        ).selected(actions) {
            ::log::info!("Template dropdown changed to: {}", template_id);
            self.selected_template_id = template_id;  // Save immediately
            self.load_template(cx, template_id);  // Auto-load
        }

        // ⭐ Use template button handler
        if self.view.button(ids!(main_content.right_panel.templates_section.use_template_button))
            .clicked(actions)
        {
            ::log::info!("Use Template button clicked, template ID: {}", self.selected_template_id);
            self.load_template(cx, self.selected_template_id);  // Use saved value
        }
    }
}

// ============================================================================
// PART 4: Use Saved Values
// ============================================================================

impl CastScreen {
    fn handle_file_import(&mut self, cx: &mut Cx) {
        // ... file dialog code ...

        let parser_factory = ParserFactory::new();

        // ⭐ Use saved format selection
        let parse_result = if self.selected_format_id == 0 {
            parser_factory.parse_auto(&content)
        } else {
            let format = match self.selected_format_id {
                1 => TranscriptFormat::PlainText,
                2 => TranscriptFormat::Json,
                3 => TranscriptFormat::Markdown,
                _ => TranscriptFormat::PlainText,
            };

            ::log::info!("Using format: {:?}", format);
            parser_factory.parse_with_format(&content, format)
        };

        // ... rest of handler ...
    }

    fn load_template(&mut self, cx: &mut Cx, template_id: usize) {
        let template_type = match template_id {
            0 => TemplateType::TwoPersonInterview,
            1 => TemplateType::ThreePersonDiscussion,
            2 => TemplateType::Narrative,
            _ => TemplateType::TwoPersonInterview,
        };

        let template = ScriptTemplate::new(template_type);

        // Load template into editor
        self.view.text_input(ids!(main_content.right_panel.editor_container.script_editor))
            .set_text(cx, &template.content);

        self.script = Some(template.content.clone());

        let msg = format!("✅ Loaded template: {}", template_type.display_name());
        self.add_log(cx, &msg);
    }
}
```

---

## Best Practices

### 1. Naming Conventions

```rust
// ✅ GOOD - Clear, descriptive names
selected_format_id: usize
selected_template_id: usize
selected_bitrate_option: usize

// ❌ BAD - Ambiguous names
format: usize
template: usize
choice: usize
```

### 2. Document Value Mappings

```rust
// ✅ GOOD - Inline documentation
#[rust]
selected_format_id: usize,  // 0=Auto, 1=Plain Text, 2=JSON, 3=Markdown

// Or in live_design
selected_format_id: 0  // 0=Auto Detect, 1=Plain Text, 2=JSON, 3=Markdown

// ❌ BAD - No documentation
#[rust]
format_id: usize
```

### 3. Use Enums for Type Safety

```rust
// ✅ BETTER - Use enum when possible
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum FormatType {
    AutoDetect,
    PlainText,
    Json,
    Markdown,
}

// Convert usize to enum
let format = match self.selected_format_id {
    0 => FormatType::AutoDetect,
    1 => FormatType::PlainText,
    2 => FormatType::Json,
    3 => FormatType::Markdown,
    _ => FormatType::AutoDetect,
};
```

### 4. Auto-Load Pattern

Consider triggering actions immediately on dropdown change for better UX:

```rust
// ✅ Auto-load template on selection
if let Some(template_id) = self.view.drop_down(...).selected(actions) {
    self.selected_template_id = template_id;
    self.load_template(cx, template_id);  // Immediate action
}

// vs

// ❌ Require separate button click
if let Some(template_id) = self.view.drop_down(...).selected(actions) {
    self.selected_template_id = template_id;
    // User must click "Use Template" button separately
}
```

### 5. Log Everything

```rust
// ✅ Good - Comprehensive logging
if let Some(format_id) = self.view.drop_down(...).selected(actions) {
    ::log::info!("Format dropdown changed: {} -> {}", self.selected_format_id, format_id);
    self.selected_format_id = format_id;
}

// ✅ Also log in action handlers
::log::info!("Using format: {:?}", format);
::log::debug!("selected_format_id = {}", self.selected_format_id);
```

---

## Common Pitfalls

### Pitfall 1: Forgetting Field Initialization

**Symptom**: Dropdown changes but actions always use default value.

**Fix**: Always initialize `#[rust]` fields in `live_design!`:

```rust
live_design! {
    pub MyScreen = {{MyScreen}} {
        // ... UI components ...

        // ⭐ MUST initialize at end
        selected_format_id: 0
    }
}
```

### Pitfall 2: Event Path Mismatch

**Symptom**: Dropdown/button clicks don't trigger any action.

**Fix**: Update event paths after layout changes:

```rust
// Before: main_content.left_panel.templates_section.template_dropdown
// After:  main_content.right_panel.templates_section.template_dropdown
```

**Debugging**:
```rust
// Add logging to verify path is correct
if let Some(val) = self.view.drop_down(ids!(...)).selected(actions) {
    ::log::info!("✅ Event fired! Value: {}", val);
} else {
    ::log::warn!("❌ Event not fired - check path!");
}
```

### Pitfall 3: Querying Dropdown Outside Event Context

**Symptom**: `selected()` returns `None` when called outside of `Event::Actions`.

**Wrong Approach**:
```rust
// ❌ This won't work
fn get_format(&self) -> FormatType {
    let format_id = self.view.drop_down(ids!(format_dropdown)).selected();
    // format_id is always None!
}
```

**Correct Approach**:
```rust
// ✅ Save during event, use later
if let Some(format_id) = self.view.drop_down(...).selected(actions) {
    self.selected_format_id = format_id;  // Save
}

fn get_format(&self) -> FormatType {
    // Use saved value
    match self.selected_format_id {
        0 => FormatType::AutoDetect,
        // ...
    }
}
```

### Pitfall 4: Not Using `#[rust]` Attribute

**Symptom**: Compilation error "field not found in struct".

**Fix**: Always use `#[rust]` for custom state fields:

```rust
// ✅ Correct
#[rust]
selected_format_id: usize,

// ❌ Wrong (Makepad won't recognize this field)
selected_format_id: usize,
```

### Pitfall 5: Wrong Order in live_design

**Symptom**: Fields don't initialize correctly.

**Fix**: Rust field initializations must be **at the very end** of `live_design!`:

```rust
live_design! {
    pub MyScreen = {{MyScreen}} {
        // All UI components first
        header = <View> { ... }
        content = <View> { ... }
        footer = <View> { ... }

        // ⭐ Then Rust fields at the END
        selected_format_id: 0
        selected_template_id: 0
    }
}
```

---

## Debugging Checklist

When dropdown state management isn't working, check these items:

### Step 1: Verify Field Declaration

- [ ] Field declared in struct with `#[rust]` attribute
- [ ] Field type matches dropdown values (usually `usize`)
- [ ] Field has descriptive name with clear documentation

### Step 2: Verify Initialization

- [ ] Field initialized in `live_design!` block
- [ ] Initialization is at the **end** of `live_design!`
- [ ] Initial value matches first dropdown option (usually 0)

### Step 3: Verify Event Handler Path

- [ ] Event handler uses correct component path
- [ ] Path matches current UI layout (left_panel vs right_panel)
- [ ] All event handlers updated after layout changes

### Step 4: Add Logging

```rust
// In dropdown event handler
::log::info!("Dropdown event fired! Value: {:?}", format_id);
::log::info!("Before: selected_format_id = {}", self.selected_format_id);
self.selected_format_id = format_id;
::log::info!("After: selected_format_id = {}", self.selected_format_id);

// In action handler
::log::info!("Action handler called! selected_format_id = {}", self.selected_format_id);
```

### Step 5: Test Flow

1. [ ] Select dropdown option → Check logs for "Dropdown event fired!"
2. [ ] Verify `selected_format_id` changed → Check logs for "After: selected_format_id = X"
3. [ ] Click action button → Check logs for "Action handler called!"
4. [ ] Verify correct branch executes → Check logs for "Using format: ..."

### Step 6: Check UI Component Path

```rust
// Temporary: Add logging to verify path
if let Some(format_id) = self.view.drop_down(ids!(...)).selected(actions) {
    ::log::info!("✅ Path is correct! Got: {}", format_id);
}

// If you don't see this log, path is wrong
::log::warn!("⚠️ If you see this, dropdown event didn't fire");
```

---

## Related Patterns

### Pattern 1: Toggle Button State

Similar pattern for toggle/checkbox buttons:

```rust
// Field
#[rust]
is_enabled: bool,

// Initialization in live_design
is_enabled: false

// Event handler
if self.view.button(ids!(toggle_button)).clicked(actions) {
    self.is_enabled = !self.is_enabled;  // Toggle
}

// Use saved value
if self.is_enabled {
    // Do something
}
```

### Pattern 2: Multi-Select State

For handling multiple selections:

```rust
// Field
#[rust]
selected_items: Vec<usize>,

// In live_design (if needed)
selected_items: Vec<usize>

// Event handler (multi-select dropdown)
if let Some(item_id) = self.view.drop_down(...).selected(actions) {
    if !self.selected_items.contains(&item_id) {
        self.selected_items.push(item_id);
    }
}

// Use saved values
for &item_id in &self.selected_items {
    // Process each selected item
}
```

### Pattern 3: Cascading Dropdowns

When one dropdown affects another:

```rust
// Fields
#[rust]
selected_category: usize,
#[rust]
selected_item: usize,

// Category dropdown handler
if let Some(category_id) = self.view.drop_down(ids!(category_dropdown)).selected(actions) {
    self.selected_category = category_id;
    self.update_item_dropdown_options(cx, category_id);  // Update second dropdown
    self.selected_item = 0;  // Reset item selection
}

// Item dropdown handler
if let Some(item_id) = self.view.drop_down(ids!(item_dropdown)).selected(actions) {
    self.selected_item = item_id;
}
```

---

## Quick Reference

### Dropdown State Management - One-Line Summary

> **Always save dropdown selection immediately to a `#[rust]` field during the event, initialize the field in `live_design!`, and use the saved value later.**

### Code Template

```rust
// 1. Declare field
#[rust]
selected_<dropdown>_id: usize,

// 2. Initialize in live_design
selected_<dropdown>_id: 0  // Default value

// 3. Handle event
if let Some(val) = self.view.drop_down(ids!(path.to.dropdown)).selected(actions) {
    self.selected_<dropdown>_id = val;  // Save immediately
}

// 4. Use saved value
match self.selected_<dropdown>_id {
    0 => { /* option 0 */ },
    1 => { /* option 1 */ },
    _ => { /* default */ },
}
```

---

## Conclusion

Makepad's dropdown state management requires understanding three key concepts:

1. **Field Declaration**: Use `#[rust]` attribute for custom state
2. **Field Initialization**: Initialize in `live_design!` block at the end
3. **Event Handling**: Save selection immediately during event, use saved value later

Following this pattern ensures dropdown selections persist and are correctly used in action handlers.

---

**Related Documents**:
- `UI_LAYOUT.md` - Complete UI layout structure
- `ARCHITECTURE.md` - Application architecture overview
- Makepad Documentation: https://github.com/makepad/makepad

**Last Updated**: 2026-01-15
**Maintained By**: Development Team
