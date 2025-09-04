# KruRooAI Installation Guide

## Prerequisites

- **macOS, Linux, or Windows WSL**
- **R** (≥ 4.0.0)
- **Python 3** (≥ 3.8)
- **Terminal/Command Line access**

## Quick Installation

### 1. Clone Repository
```bash
git clone https://github.com/[your-username]/krurooai-project.git
cd krurooai-project
```

### 2. Run Installation Script
```bash
# For macOS/Linux
chmod +x install.sh
./install.sh

# For manual installation, see below
```

### 3. Test Installation
```bash
krurooai config-check
krurooai help
```

## Manual Installation

### Step 1: Install R Dependencies
```bash
R -e "install.packages(c('optparse', 'yaml', 'jsonlite'), repos='https://cran.r-project.org')"
```

### Step 2: Install Python Dependencies  
```bash
pip3 install requests
# or
pip install requests
```

### Step 3: Install Ollama (Local LLM)
```bash
# macOS/Linux
curl -fsSL https://ollama.ai/install.sh | sh

# Windows - Download from https://ollama.ai/download
```

### Step 4: Download AI Model
```bash
ollama serve  # Run in background
ollama pull gpt-oss:20b
# or try smaller model: ollama pull llama2:7b
```

### Step 5: Install as Global Command
```bash
# Make executable
chmod +x bin/krurooai

# Create symlink (recommended)
sudo ln -sf $(pwd)/bin/krurooai /usr/local/bin/krurooai

# OR copy file
sudo cp bin/krurooai /usr/local/bin/krurooai
```

### Step 6: Fix Config Files
```bash
echo "" >> config/llm.yaml
echo "" >> config/privacy.yaml
```

## Verification

### Check Installation
```bash
krurooai config-check
```

Expected output should show ✅ for most items:
- ✅ LLM config is valid
- ✅ Privacy config is valid  
- ✅ R packages installed
- ✅ Python 3 available
- ✅ Ollama server running

### Test with Sample Data
```bash
krurooai test-privacy tests/sample_data/sample_submission.txt
krurooai grade tests/sample_data/sample_submission.txt --context tests/sample_data/sample_context.md
```

## Optional: OpenAI API Setup

If you want to use OpenAI instead of/alongside local LLM:

```bash
# Set your API key
export OPENAI_API_KEY="your-api-key-here"

# Test
krurooai grade tests/sample_data/sample_submission.txt \
  --context tests/sample_data/sample_context.md \
  --mode openai
```

## Troubleshooting

### Common Issues

**"Command not found: krurooai"**
```bash
# Check if symlink exists
ls -la /usr/local/bin/krurooai

# Recreate if needed
sudo ln -sf $(pwd)/bin/krurooai /usr/local/bin/krurooai
```

**"R package not found"**
```bash
# Install missing packages
R -e "install.packages('missing_package_name')"
```

**"Ollama not running"**
```bash
# Start Ollama server
ollama serve

# Check if model is downloaded
ollama list
```

**"Python module not found"**
```bash
# Install requests
pip3 install requests
# or try: python3 -m pip install requests
```

### Get Help

- Run `krurooai help` for command reference
- Check `README.md` for usage examples
- Report issues on GitHub

## Uninstall

```bash
# Remove global command
sudo rm /usr/local/bin/krurooai

# Remove repository
cd ..
rm -rf krurooai-project
```