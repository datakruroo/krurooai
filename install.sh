#!/bin/bash

# KruRooAI Installation Script
# Automatically installs all dependencies and sets up the system

set -e  # Exit on any error

echo "🚀 Installing KruRooAI - Educational AI Assistant"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_status "Checking prerequisites..."

# Check if R is installed
if ! command -v R &> /dev/null; then
    print_error "R is not installed. Please install R first:"
    print_error "  macOS: brew install r"
    print_error "  Ubuntu: sudo apt-get install r-base"
    exit 1
fi
print_success "R is installed"

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3 first"
    exit 1
fi
print_success "Python 3 is installed"

# Install R dependencies
print_status "Installing R packages..."
R --slave --no-restore --no-save -e "
packages <- c('optparse', 'yaml', 'jsonlite')
installed <- rownames(installed.packages())
to_install <- packages[!packages %in% installed]
if(length(to_install) > 0) {
  install.packages(to_install, repos='https://cran.r-project.org', quiet=TRUE)
  cat('Installed:', paste(to_install, collapse=', '), '\n')
} else {
  cat('All R packages already installed\n')
}
"
print_success "R packages installed"

# Install Python dependencies
print_status "Installing Python packages..."
if python3 -c "import requests" 2>/dev/null; then
    print_success "Python requests already installed"
else
    if pip3 install requests; then
        print_success "Python requests installed"
    else
        print_warning "Could not install requests via pip3, trying pip..."
        pip install requests || {
            print_error "Failed to install Python requests module"
            exit 1
        }
    fi
fi

# Install Ollama (optional)
print_status "Checking Ollama installation..."
if command -v ollama &> /dev/null; then
    print_success "Ollama already installed"
else
    print_warning "Ollama not found. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -fsSL https://ollama.ai/install.sh | sh
        print_success "Ollama installed"
    else
        print_warning "Please install Ollama manually from https://ollama.ai/download"
    fi
fi

# Download AI model
print_status "Checking AI model..."
if ollama list | grep -q "gpt-oss:20b"; then
    print_success "AI model already downloaded"
else
    print_status "Downloading AI model (this may take a while)..."
    if ollama pull gpt-oss:20b; then
        print_success "AI model downloaded"
    else
        print_warning "Failed to download gpt-oss:20b, trying smaller model..."
        if ollama pull llama2:7b; then
            print_success "Alternative model (llama2:7b) downloaded"
            # Update config to use the smaller model
            sed -i.bak 's/gpt-oss:20b/llama2:7b/g' config/llm.yaml
        else
            print_warning "Could not download AI model. You can install it later with: ollama pull gpt-oss:20b"
        fi
    fi
fi

# Make executable
print_status "Setting up executable permissions..."
chmod +x bin/krurooai
print_success "Permissions set"

# Install as global command
print_status "Installing as global command..."
if sudo -n true 2>/dev/null; then
    # User has sudo without password
    sudo ln -sf "$(pwd)/bin/krurooai" /usr/local/bin/krurooai
    print_success "Installed as global command 'krurooai'"
else
    # Ask for password
    echo "Administrator password needed to install global command..."
    if sudo ln -sf "$(pwd)/bin/krurooai" /usr/local/bin/krurooai; then
        print_success "Installed as global command 'krurooai'"
    else
        print_warning "Could not install globally. You can run: ./bin/krurooai"
    fi
fi

# Fix config files
print_status "Fixing configuration files..."
echo "" >> config/llm.yaml
echo "" >> config/privacy.yaml
print_success "Configuration files fixed"

# Test installation
print_status "Testing installation..."
echo ""
echo "🧪 Running system check..."
if krurooai config-check; then
    echo ""
    print_success "✅ Installation completed successfully!"
    echo ""
    echo "🎉 KruRooAI is ready to use!"
    echo ""
    echo "Quick start:"
    echo "  krurooai help                    # Show all commands"
    echo "  krurooai config-check            # Check system status" 
    echo "  krurooai test-privacy tests/sample_data/sample_submission.txt"
    echo ""
    echo "For full documentation, see README.md"
else
    print_warning "Installation completed but some checks failed"
    echo "Please run 'krurooai config-check' to see what needs fixing"
fi