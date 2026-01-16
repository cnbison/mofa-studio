#!/bin/bash
# MoFA Studio Startup Script
#
# This script runs mofa-studio with proper environment configuration.
# Dora infrastructure is managed by the application itself.
#
# Usage: ./run-mofa-studio.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}  MoFA Studio Startup Script${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# Project directory
PROJECT_DIR="/Users/loubicheng/project/mofa-studio"
cd "$PROJECT_DIR"

# ========================================
# Step 1: Kill all existing Dora processes
# ========================================
echo -e "${YELLOW}[1/2] Cleaning up Dora processes...${NC}"

# Kill all dora-related processes
pkill -f "dora coordinator" 2>/dev/null || true
pkill -f "dora daemon" 2>/dev/null || true
pkill -f "dora-coordinator" 2>/dev/null || true

# Wait for processes to fully stop
sleep 2

# Force kill if any remain
DORA_COUNT=$(ps aux | grep -i "dora coordinator" | grep -v grep | wc -l)
if [ "$DORA_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}  Force killing remaining processes...${NC}"
    pkill -9 -f "dora coordinator" 2>/dev/null || true
    pkill -9 -f "dora daemon" 2>/dev/null || true
    sleep 1
fi

echo -e "${GREEN}✓ Dora processes cleaned up${NC}"
echo ""

# ========================================
# Step 2: Activate conda environment and run mofa-studio
# ========================================
echo -e "${YELLOW}[2/2] Starting MoFA Studio...${NC}"
echo ""

# Check if conda is available
if ! command -v conda &> /dev/null; then
    echo -e "${RED}Error: conda not found. Please install Miniconda or Anaconda.${NC}"
    exit 1
fi

# Activate conda environment
eval "$(conda shell.bash hook)"
conda activate mofa-studio

# Set PATH to include conda environment
export PATH="$CONDA_PREFIX/bin:$PATH"

# Set log level to INFO to see debug messages
export RUST_LOG=info
# Or use DEBUG for even more verbose logging:
# export RUST_LOG=debug

# TTS Engine Selection
# Options:
#   - (empty or unset): Use MockTtsEngine (test tones, fast)
#   - "kokoro": Use Kokoro TTS (real speech, but may hang on some texts)
#export MOFA_CAST_TTS=kokoro  # Use Kokoro TTS
echo "🎙️  TTS Engine: ${MOFA_CAST_TTS:-MockTtsEngine (test mode)}"

# Verify Dora nodes are accessible
echo "=== Checking Dora Nodes ==="
which dora-text-segmenter
which dora-kokoro-tts
echo "=========================="
echo "Log level: $RUST_LOG"
echo "=========================="
echo ""

# Run cargo in conda environment to ensure access to dora commands
exec cargo run --release
