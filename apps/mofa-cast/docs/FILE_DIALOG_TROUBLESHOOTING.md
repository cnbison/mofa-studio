# File Dialog Troubleshooting

## Issue: File Dialog Not Opening

If clicking the "Import" button doesn't open a file dialog, follow these steps:

### 1. Check Console Logs

Run mofa-studio-shell from terminal and look for logs:

```bash
./target/release/mofa-studio-shell
```

**Expected logs when clicking Import**:
```
[INFO] Opening file dialog...
[INFO] File selected: "/path/to/file.txt"
[INFO] File read successfully: XXX bytes
[INFO] Transcript parsed successfully: 2 speakers, 6 messages
```

**If you see only**:
```
[INFO] Opening file dialog...
```

Then the file dialog is not appearing. Continue to step 2.

### 2. Platform-Specific Issues

#### macOS (Most Common)

**Problem**: On macOS, file dialogs need to run on the main thread.

**Solution**: Make sure you're running from an applications bundle (not just the binary):

```bash
# Instead of:
./target/release/mofa-studio-shell

# Build the app bundle:
make mac-bundle

# Then run:
open target/release/bundle/osx/mofa-studio-shell.app
```

**Alternative**: Set the environment variable:

```bash
export RFD_DEBUG=1
./target/release/mofa-studio-shell
```

This will show debug information from rfd.

#### Linux

**Problem**: Missing dependencies for file dialog backend.

**Solution**: Install required packages:

```bash
# Ubuntu/Debian:
sudo apt-get install libgtk-3-dev

# Fedora:
sudo dnf install gtk3-devel

# Arch Linux:
sudo pacman -S gtk3
```

Then rebuild:

```bash
cargo clean
cargo build --release --package mofa-studio-shell
```

#### Windows

**Problem**: File dialog may open behind the main window.

**Solution**: Check your taskbar for the file dialog window, or press `Alt+Tab` to cycle through windows.

### 3. Alternative: Use Absolute Path

If the file dialog still doesn't work, you can manually edit the file path:

1. Open a test file from the terminal:
   ```bash
   cat apps/mofa-cast/test_samples/sample_plain.txt
   ```

2. Copy the content

3. Paste directly into the "Original Script" text editor

### 4. Test File Dialog Separately

Create a simple test to verify rfd works:

```rust
// test_file_dialog.rs
fn main() {
    let file = rfd::FileDialog::new()
        .add_filter("Text", &["txt"])
        .pick_file();

    match file {
        Some(path) => println!("Selected: {:?}", path),
        None => println!("Cancelled"),
    }
}
```

Run it:
```bash
cargo run --example test_file_dialog
```

If this doesn't open a dialog, the issue is with your rfd installation, not mofa-cast.

### 5. Check rfd Version

Verify you have the correct rfd version:

```bash
grep "rfd" apps/mofa-cast/Cargo.toml
```

Should show:
```toml
rfd = "0.14"
```

### 6. macOS Permissions

If you're on macOS and running from Xcode:

1. Go to **Project Settings** → **Signing & Capabilities**
2. Add **File Access** entitlement:
   - `com.apple.security.files.user-selected.read-write`

### 7. Fallback: Command Line Input

As a last resort, you can modify the code to accept file path from command line:

```rust
// In screen.rs, temporarily add:
fn handle_file_import(&mut self, cx: &mut Cx) {
    // For testing, use hardcoded path
    let test_path = std::path::PathBuf::from("apps/mofa-cast/test_samples/sample_plain.txt");

    // ... rest of the function
}
```

This bypasses the file dialog entirely.

## Common Error Messages

### "File dialog failed"

**Cause**: rfd cannot create native file dialog

**Solution**:
- Make sure you're on main thread
- Check platform-specific requirements above
- Try running with elevated permissions

### "Parse error"

**Cause**: File format not recognized

**Solution**:
- Check file is plain text, JSON, or Markdown
- Verify file encoding is UTF-8
- Try with sample files in `test_samples/`

### "Error reading file"

**Cause**: File permissions or file doesn't exist

**Solution**:
- Check file exists: `ls -la /path/to/file.txt`
- Check permissions: `chmod 644 /path/to/file.txt`
- Try copying file to a simpler location (like Desktop)

## Testing with Sample Files

If file dialog doesn't work, you can still test with built-in samples:

```bash
# List available test files
ls -la apps/mofa-cast/test_samples/

# You should see:
# sample_plain.txt
# sample_json.json
# sample_markdown.md
```

**To manually load a file**, modify `screen.rs` temporarily:

```rust
fn handle_file_import(&mut self, cx: &mut Cx) {
    // Temporary: Use hardcoded path for testing
    let test_path = std::path::PathBuf::from("apps/mofa-cast/test_samples/sample_plain.txt");

    // Copy the rest of the function from the match file_handle block...
}
```

## Report Issues

If none of these solutions work:

1. **Collect diagnostics**:
   ```bash
   RFD_DEBUG=1 ./target/release/mofa-studio-shell > debug.log 2>&1
   ```

2. **Check rfd issues**:
   https://github.com/PolyMeilex/rfd/issues

3. **Provide information**:
   - Platform (macOS/Linux/Windows)
   - mofa-studio version: `./target/release/mofa-studio-shell --version`
   - Rust version: `rustc --version`
   - Console output when clicking Import

## Known Issues

### macOS: Dialog opens behind window

**Workaround**: Press `Cmd+Tab` to find the dialog

### Linux: No native dialog on Wayland

**Workaround**: Switch to X11 or use file path input

### All platforms: Dialog opens on wrong monitor

**Workaround**: Move mofa-studio to primary monitor before clicking Import
