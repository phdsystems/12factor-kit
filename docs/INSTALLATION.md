# Installation Guide

## Quick Start

### Clone and Run
```bash
git clone https://github.com/phdsystems/12-factor-reviewer.git
cd 12-factor-reviewer
./bin/12factor-assess /path/to/project
```

## Installation Methods

### Method 1: Local Installation

```bash
# Clone this repository
git clone https://github.com/phdsystems/12-factor-reviewer.git
cd 12-factor-reviewer

# Make the tool executable
chmod +x bin/12factor-assess

# Run directly
./bin/12factor-assess /path/to/project

# Or add to PATH (optional)
export PATH="$PATH:$(pwd)/bin"
12factor-assess /path/to/project
```

### Method 2: System-wide Installation

```bash
# Clone and install
git clone https://github.com/phdsystems/12-factor-reviewer.git
cd 12-factor-reviewer

# Install to /usr/local/bin
sudo ./install.sh

# Now use from anywhere
12factor-assess /path/to/project
```

### Method 3: Docker Installation

```bash
# Using pre-built image (when available)
docker pull phdsystems/12factor-reviewer
docker run -v $(pwd):/project phdsystems/12factor-reviewer

# Or build locally
git clone https://github.com/phdsystems/12-factor-reviewer.git
cd 12-factor-reviewer
docker build -t 12factor-reviewer .
docker run -v $(pwd):/project 12factor-reviewer
```

### Method 4: npm Installation (when published)

```bash
# Global installation
npm install -g 12factor-reviewer

# Run assessment
12factor-assess /path/to/project
```

## Verification

After installation, verify it works:

```bash
# Check version
12factor-assess --version

# Show help
12factor-assess --help

# Run on current directory
12factor-assess .
```

## Updating

### For Git installations
```bash
cd 12-factor-reviewer
git pull origin main
```

### For system-wide installations
```bash
cd 12-factor-reviewer
git pull origin main
sudo ./install.sh
```

### For Docker
```bash
docker pull phdsystems/12factor-reviewer
```

## Uninstallation

### Remove local installation
```bash
rm -rf 12-factor-reviewer
```

### Remove system-wide installation
```bash
sudo rm /usr/local/bin/12factor-assess
```

### Remove Docker image
```bash
docker rmi 12factor-reviewer
```

## Troubleshooting

### Permission Denied
```bash
chmod +x bin/12factor-assess
```

### Command Not Found
Add to PATH:
```bash
export PATH="$PATH:/path/to/12-factor-reviewer/bin"
```

### Docker Volume Issues
Use absolute paths:
```bash
docker run -v $(pwd):/project 12factor-reviewer
```