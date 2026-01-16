# Dora Dataflow Configuration for MoFA Cast

## Node Paths

**Important**: This dataflow configuration uses absolute paths for Dora nodes.

### Why Absolute Paths?

Dora daemon runs as a separate process and doesn't inherit environment variables from mofa-studio. Therefore, we use absolute paths to ensure nodes can be found.

### Current Configuration

```yaml
text-segmenter:
  path: /Users/loubicheng/miniconda3/envs/mofa-studio/bin/dora-text-segmenter

kokoro-tts:
  path: /Users/loubicheng/miniconda3/envs/mofa-studio/bin/dora-kokoro-tts
```

### For Different Users

If your conda environment is in a different location, update these paths:

1. Find your conda environment:
   ```bash
   which dora-kokoro-tts
   which dora-text-segmenter
   ```

2. Edit `batch-tts.yml` and update the `path` fields with your results.

### Alternative: System-Wide Symlinks

Instead of absolute paths, you can create symlinks in system paths:

```bash
# Create directory for user-local binaries
mkdir -p ~/.local/bin

# Create symlinks
ln -s ~/miniconda3/envs/mofa-studio/bin/dora-kokoro-tts ~/.local/bin/
ln -s ~/miniconda3/envs/mofa-studio/bin/dora-text-segmenter ~/.local/bin/

# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH="$HOME/.local/bin:$PATH"
```

Then update `batch-tts.yml` to use just node names:
```yaml
path: dora-kokoro-tts  # Will look in PATH
```

## Testing

After updating paths, test with:

```bash
cd /Users/loubicheng/project/mofa-studio
./run-mofa-studio.sh
```

Then try the "Synthesize Audio" button in MoFA Cast.
