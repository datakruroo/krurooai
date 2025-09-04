# CLAUDE.md - KruRooAI Development Specification
สำหรับ Claude Code ในการพัฒนา Educational AI Assistant

**Status: ✅ COMPLETED - Ready for Production Use**

Last Updated: 2025-09-04

## Project Overview

KruRooAI คือ command-line tool สำหรับตรวจและประเมินงานการศึกษา รองรับทั้ง Local LLM และ OpenAI API พร้อมระบบคัดกรองข้อมูลส่วนตัว

## Core Requirements:

- CLI interface เป็นหลัก
- R + Python hybrid architecture
- Privacy-first design
- Multiple LLM backend support
- Batch processing capability

## Technical Stack

```{yaml}
Primary Language: R (tidyverse, reticulate)
Secondary Language: Python (for LLM integration)
LLM Backends:
  - Local: Ollama + GPT-J/Llama models
  - API: OpenAI GPT-4/3.5
Configuration: YAML files
Input: Markdown contexts + PDF/text submissions
Output: Markdown reports + structured data
```


## Initial Development Priorities

### Phase 1: Core Foundation

1. Project Structure Setup
2. CLI Parser (R)
3. LLM Router (Python)
4. Basic Privacy Filter
5. Simple Grading Pipeline

### Phase 2: Essential Features

1. Context Processing (Markdown)
2. Batch Processing
3. Report Generation
4. Configuration System

## Directory Structure

krurooai/
├── R/
│   ├── main.R                 # CLI entry point
│   ├── cli_parser.R           # Command parsing
│   ├── context_processor.R    # Markdown processing
│   ├── privacy_filter.R       # Data redaction
│   ├── report_generator.R     # Output formatting
│   └── config_manager.R       # YAML config handling
├── python/
│   ├── llm_router.py          # LLM backend router
│   ├── local_llm.py          # Ollama integration  
│   ├── api_llm.py            # OpenAI integration
│   └── privacy_utils.py      # Privacy helper functions
├── config/
│   ├── llm.yaml              # LLM backend settings
│   ├── privacy.yaml          # Privacy rules
│   └── templates.yaml        # Grading templates
├── templates/
│   ├── prompts/
│   │   ├── local/            # Local LLM prompts
│   │   └── api/              # API LLM prompts
│   └── reports/              # Output templates
├── tests/
│   ├── sample_data/
│   └── test_cases/
├── bin/
│   └── krurooai                 # Main executable
└── docs/
    └── examples/


## Core Interfaces
1. CLI Interface

```{bash}
# Main commands needed:
krurooai init --name PROJECT_NAME --backends local,api
krurooai grade INPUT_FILE --context CONTEXT.md [--mode local|api|hybrid]
krurooai batch-grade DIRECTORY --context CONTEXT.md [--mode local|api|hybrid]
krurooai config-check
krurooai test-privacy INPUT_FILE
```

2. Context File Format (Markdown)

```{markdown}
markdown# Assignment Context: [TITLE]

## คำถาม
[Question content]

## คำตอบมาตรฐาน  
[Standard answers]

## เกณฑ์การประเมิน
[Grading criteria with percentages]

## หมายเหตุ
[Additional notes]
```

## 3. Configuration Files

config/llm.yaml:

```{yaml}
yamlbackends:
  local:
    model: "gpt-oss:20b"
    endpoint: "http://localhost:11434"
    temperature: 0.3
  openai:
    model: "gpt-5-nano-2025-08-07"
    api_key_env: "OPENAI_API_KEY"
    temperature: 0.3
    privacy_mode: true
```

config/privacy.yaml:

```{yaml}
yamlsensitive_patterns:
  - "ชื่อ.*:"
  - "รหัส.*:"
  - "เลขที่.*:"
redaction_rules:
  replace_names: "[STUDENT]"
  replace_ids: "[ID]"
```

## Key Functions to Implement

### R Functions (Priority Order)

1. parse_cli_args(args) - Parse command line arguments
2. load_config(config_path) - Load YAML configurations
3. process_context_md(md_file) - Parse assignment context
4. apply_privacy_filter(text, rules) - Redact sensitive data
5. call_llm_router(text, context, backend) - Route to Python
6. generate_report(results, template) - Create output

### Python Functions (Priority Order)

1. route_to_llm(text, context, backend) - Main router
2. call_local_llm(prompt, config) - Ollama integration
3. call_openai_api(prompt, config) - OpenAI integration
4. extract_feedback(response) - Parse LLM output
5. calculate_confidence(response) - Confidence scoring

## Privacy Requirements

### Critical: API mode ต้องคัดกรองข้อมูลก่อนส่ง:

ชื่อนักเรียน → [STUDENT]
รหัสนักเรียน → [ID]
ชื่อโรงเรียน → [SCHOOL]
เก็บเฉพาะเนื้อหาวิชาการส่งผ่าน API

### Privacy Pipeline:
Input → Detect Personal Data → Redact → Send to API → Restore Context → Output


## Expected Input/Output

### Input Example

student_001.pdf (หรือ .txt)
assignment_context.md  
config/llm.yaml

### Output Example

```{markdown}
# รายงานการตรวจงาน: [STUDENT]

## คะแนนรวม: 85/100

## รายละเอียด
- คำตอบถูกต้อง: 40/40
- วิธีการ: 30/40  
- การแสดงผล: 15/20

## ข้อเสนอแนะ
...
```

## Development Instructions for Claude Code - ✅ COMPLETED

### ✅ Phase 1: Basic Structure - COMPLETED
- โครงสร้างไฟล์ครบถ้วนตาม directory structure
- ไฟล์ placeholder functions ทั้งหมด  
- Sample config files (llm.yaml, privacy.yaml, templates.yaml)

### ✅ Phase 2: Core CLI - COMPLETED  
- R/main.R และ R/cli_parser.R ทำงานครบถ้วน
- รองรับ commands: grade, batch-grade, csv-import, init, config-check, test-privacy, help
- Argument parsing และ validation เสร็จสมบูรณ์
- Help system ครบถ้วน

### ✅ Phase 3: LLM Integration - COMPLETED
- python/llm_router.py เชื่อมต่อ LLM backends สำเร็จ
- รองรับ local (Ollama) และ openai backends
- Structured response parsing และ error handling
- Hybrid mode สำหรับใช้ทั้ง local + API

### ✅ Phase 4: Privacy Filter - COMPLETED  
- R/privacy_filter.R detect และ redact ข้อมูลส่วนตัว
- Pattern matching สำหรับชื่อ รหัส อีเมล โรงเรียน
- Placeholder replacement และ restoration mapping
- API safety validation

### ✅ Phase 5: Advanced Features - COMPLETED
- **CSV Import System**: Automated processing of Google Forms data
- **Auto-grading Pipeline**: End-to-end grading after data import  
- **Flexible Configuration**: Customizable column mapping and processing
- **Report Generation**: Multiple output formats (default, detailed, summary)
- **System Health Checks**: Comprehensive configuration validation
- **Enhanced Feedback System**: Detailed per-question analysis with extended token limits
- **Question Type Classification**: Automatic separation of objective vs subjective questions

### ✅ Phase 6: Installation & Distribution - COMPLETED
- **Library Path Resolution**: Fixed R package loading issues across environments
- **Executable Path Handling**: Proper symlink resolution for global installation
- **Cross-platform Compatibility**: Tested on macOS Darwin environment
- **Installation Script**: Automated dependency management and setup
- **Error Recovery**: Graceful fallback mechanisms for installation issues

## Testing Strategy - ✅ COMPLETED

### ✅ Manual Testing Completed
1. **Unit Tests**: แต่ละฟังก์ชันทำงานถูกต้อง ✅
   - CLI parser รองรับทุก command
   - Privacy filter detect และ redact ได้ถูกต้อง
   - LLM integration ทำงานกับทั้ง local และ API
   - Config management validate ได้ครบถ้วน

2. **Integration Tests**: R ↔ Python communication ✅  
   - R เรียก Python scripts ผ่าน system() ได้สำเร็จ
   - JSON data passing ระหว่าง R และ Python ถูกต้อง
   - Error handling และ fallback mechanisms ทำงานดี

3. **Privacy Tests**: ข้อมูลส่วนตัวถูกคัดกรอง ✅
   - ตรวจจับชื่อ รหัสนักเรียน อีเมล ได้แม่นยำ
   - Redaction และ restoration ทำงานถูกต้อง
   - API safety validation ป้องกันข้อมูลรั่วไหล

4. **End-to-End Tests**: CLI → Report generation ✅
   - Complete workflow จาก CSV import ถึง final report
   - Auto-grading pipeline ทำงานครบวงจร
   - Batch processing หลายไฟล์พร้อมกัน

### ✅ Production Testing
- **Real Data Testing**: ทดสอบกับข้อมูล Google Forms จริง
- **Multiple LLM Backends**: ทดสอบทั้ง Ollama และ OpenAI API
- **Cross-platform**: ทดสอบบน macOS (Darwin) environment
- **Performance Testing**: Batch processing หลายไฟล์พร้อมกัน
- **Error Recovery**: Fallback mechanisms เมื่อ LLM ไม่ available

## Success Criteria

✅ MVP Requirements - **COMPLETED**:

- CLI รัน krurooai grade sample.txt --context context.md ได้ ✅
- เชื่อมต่อ Local LLM ได้ ✅ (Ollama + gpt-oss:20b)
- Privacy filter ทำงาน ✅
- Generate report ได้ ✅

✅ Full Version - **COMPLETED**:

- รองรับ OpenAI API ✅
- Batch processing ✅
- CSV Import processing ✅
- Configuration management ✅
- Quality control features ✅

## ✨ Additional Features Implemented:

- **CSV Import**: `krurooai csv-import` command for processing Google Forms/Survey data
- **Auto-grading**: Automatic grading after CSV import  
- **Flexible Configuration**: Customizable column mapping and processing options
- **System-wide Installation**: Can be installed as global command
- **Comprehensive Error Handling**: Fallback grading when LLM fails
- **Privacy Protection**: Advanced redaction and filtering
- **Multiple Output Formats**: Default, detailed, and summary reports
- **Enhanced Feedback System**: Extended token limits (8000), longer timeout (300s) for detailed analysis
- **Question Type Separation**: Automatic classification and separate reporting for objective vs subjective questions
- **Structured Assessment**: Per-question feedback with key points, improvements, and detailed analysis
- **User-friendly Installation**: Automated install.sh script with dependency management
- **Safe Uninstallation**: Interactive uninstall.sh script with selective removal options
- **Complete Documentation**: Installation, usage, and uninstallation guides

## 📋 Deployment Checklist - ✅ COMPLETED

### ✅ Core System
- [x] CLI interface with all commands
- [x] LLM integration (Local + API)
- [x] Privacy filtering system  
- [x] Report generation
- [x] Configuration management
- [x] Error handling and fallbacks
- [x] R library path resolution fixed
- [x] Symlink executable path detection

### ✅ Advanced Features  
- [x] CSV import functionality
- [x] Auto-grading pipeline
- [x] Batch processing
- [x] Multiple output formats
- [x] System health checks
- [x] Comprehensive help system
- [x] Enhanced feedback system with 8000 token limit
- [x] Question type classification (objective/subjective)
- [x] Separated report sections for different question types
- [x] Extended timeout (300s) for complex analysis

### ✅ Distribution Ready
- [x] Automated installation script
- [x] Manual installation guide
- [x] Interactive uninstall script
- [x] Complete documentation
- [x] Sample data and examples
- [x] Troubleshooting guides

### ✅ Quality Assurance
- [x] End-to-end testing completed
- [x] Real-world data validation
- [x] Cross-platform compatibility
- [x] Security and privacy validation
- [x] Performance optimization
- [x] Documentation accuracy verified

## 🚀 Production Ready ✅

**The system is fully functional and ready for educational use.**

✅ **All core requirements implemented and tested**  
✅ **Advanced features completed**  
✅ **Distribution system ready**  
✅ **Documentation comprehensive**  
✅ **Installation/uninstallation automated**  
✅ **GitHub deployment ready**

**Status: READY FOR IMMEDIATE DEPLOYMENT**

## 📦 Distribution Features

### Installation System
- **Automated Installer**: `install.sh` handles all dependencies and configuration
- **Manual Installation**: Step-by-step guide in `INSTALL.md`
- **Dependency Management**: Automatic R packages, Python modules, and Ollama setup
- **Global Command**: System-wide installation for easy access
- **Configuration Validation**: Built-in system health checks
- **Library Path Resolution**: Automatic R library path detection and configuration
- **Symlink Support**: Proper path resolution for global command installation

### User Experience
- **Quick Start**: 3-command installation process
- **Interactive Help**: Comprehensive `krurooai help` system
- **Error Handling**: Graceful fallbacks and informative error messages
- **Progress Tracking**: Real-time feedback during operations
- **Troubleshooting**: Built-in diagnostics and common solutions
- **Enhanced Reports**: Detailed feedback with separated objective/subjective question analysis
- **Extended Analysis**: 8000-token responses with 300-second timeout for comprehensive evaluation

### Maintenance & Support
- **Safe Uninstallation**: `uninstall.sh` with selective removal options
- **Data Preservation**: Options to keep user data during uninstall
- **Documentation**: Complete guides for installation, usage, and removal
- **GitHub Ready**: Repository structure optimized for open-source distribution