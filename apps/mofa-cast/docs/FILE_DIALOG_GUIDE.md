# File Dialog Test Guide

## Quick Test

After building mofa-cast:

```bash
./target/release/mofa-studio-shell
```

1. Click **MoFA Cast** icon (🎙️) in sidebar
2. Click **Import** button
3. **A file dialog should appear**

## What Should Happen

### macOS
- Native macOS file picker opens
- You can select `.txt`, `.json`, or `.md` files
- Dialog is styled like other macOS apps

### Linux
- GTK file chooser opens (if GTK3 installed)
- You can select files with proper filters

### Windows
- Windows File Explorer dialog opens
- Standard Windows file picker interface

## If Dialog Doesn't Open

### Check 1: Console Logs

Look for these logs when you click Import:
```
[INFO] Opening file dialog...
```

If you see this but no dialog appears, check [FILE_DIALOG_TROUBLESHOOTING.md](FILE_DIALOG_TROUBLESHOOTING.md)

### Check 2: Try Test Files

Navigate to `apps/mofa-cast/test_samples/` and try opening:
- `sample_plain.txt` - Simple text format
- `sample_json.json` - JSON format
- `sample_markdown.md` - Markdown format

### Check 3: Platform-Specific Notes

#### macOS Users

**Most reliable method**: Use the app bundle

```bash
# If you have make:
make mac-bundle
open target/release/bundle/osx/mofa-studio-shell.app
```

**From binary**: May have issues
```bash
./target/release/mofa-studio-shell
```

Dialog might open:
- On a different Space (Desktop)
- Behind other windows
- Minimized in Dock

**Try**: Press `Cmd+Tab` or check all desktop spaces.

#### Linux Users

Ensure GTK3 is installed:
```bash
# Ubuntu/Debian:
sudo apt-get install libgtk-3-dev

# Fedora:
sudo dnf install gtk3-devel
```

Rebuild:
```bash
cargo clean
cargo build --release --package mofa-studio-shell
```

#### Windows Users

Dialog should work out of the box. If not:
- Check taskbar for dialog window
- Press `Alt+Tab` to find it
- Run as Administrator if needed

## Workaround: Direct File Path

If file dialog doesn't work, you can temporarily modify the code to use a hardcoded path:

**Edit**: `apps/mofa-cast/src/screen.rs`

**Find** (around line 541):
```rust
fn handle_file_import(&mut self, cx: &mut Cx) {
```

**Replace with**:
```rust
fn handle_file_import(&mut self, cx: &mut Cx) {
    // Temporary: Use hardcoded path for testing
    let file_path = std::path::PathBuf::from("apps/mofa-cast/test_samples/sample_plain.txt");

    ::log::info!("Using hardcoded path: {:?}", file_path);

    // Read file content (same as before)
    match fs::read_to_string(&file_path) {
        Ok(content) => {
            // ... rest of the function (same as current code)
```

This bypasses the file dialog and loads the test file directly.

## After Fixing

Once file dialog works:

1. Import test file
2. Verify it appears in Original Script editor
3. Check speaker list appears on left
4. File info shows message count

**Expected output**:
```
sample_plain.txt
6 messages • 2 speakers
```

## Debug Mode

For detailed debugging:

```bash
# Enable rfd debug logging
RFD_DEBUG=1 ./target/release/mofa-studio-shell
```

This will show internal rfd operations.

## Report Issues

Include in your report:
- Platform (macOS/Linux/Windows + version)
- What you see in console when clicking Import
- Whether `RFD_DEBUG=1` shows any additional info
- Screenshot if possible

## Alternative Test: Manual File Loading

As a last resort, you can manually paste file content:

1. Open test file in text editor:
   ```bash
   cat apps/mofa-cast/test_samples/sample_plain.txt
   ```

2. Copy all content

3. Paste into "Original Script" text editor in mofa-studio

This bypasses file loading entirely but lets you test the rest of the pipeline.

## Next Steps After Import

Once file imports successfully:
1. Click **Refine Script** to generate podcast version
2. Click **Synthesize Audio** to create podcast with TTS
3. Click **Export Audio** to save final podcast file

See [TTS_WORKFLOW_TEST.md](TTS_WORKFLOW_TEST.md) for complete testing guide.
