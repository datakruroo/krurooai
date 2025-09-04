# KruRooAI - Educational AI Assistant

KruRooAI คือ command-line tool สำหรับตรวจและประเมินงานการศึกษา รองรับทั้ง Local LLM และ OpenAI API พร้อมระบบคัดกรองข้อมูลส่วนตัว

## ✨ คุณสมบัติหลัก

- 🤖 **Multi-LLM Support**: รองรับทั้ง Local LLM (Ollama) และ OpenAI API
- 🔒 **Privacy-First**: ระบบคัดกรองข้อมูลส่วนตัวอัตโนมัติ
- 📊 **Batch Processing**: ประมวลผลงานหลายไฟล์พร้อมกันแบบควบคุมคุณภาพ
- 📈 **CSV Import**: นำเข้าข้อมูลจาก Google Forms/Survey ได้โดยตรง
- 📝 **Enhanced Reports**: รายงานแยกประเภทข้อปรนัย/อัตนัย พร้อมวิเคราะห์เชิงลึก
- 🎯 **Question Classification**: แยกประเภทคำถามอัตโนมัติและให้ feedback ตรงจุด
- ⚙️ **Extended Analysis**: Token limit 8000 และ timeout 300 วินาที สำหรับการวิเคราะห์ละเอียด
- 🚀 **Auto-Grade**: ตรวจงานอัตโนมัติหลังจาก import ข้อมูล

## 🚀 การติดตั้ง

### ⚡ Quick Installation

```bash
# Clone repository
git clone https://github.com/[your-username]/krurooai-project.git
cd krurooai-project

# Run automatic installation
chmod +x install.sh
./install.sh

# Test installation  
krurooai config-check
```

### 📋 Manual Installation

#### ความต้องการระบบ
- **R** (≥ 4.0.0) 
- **Python** (≥ 3.8)
- **Ollama** (สำหรับ Local LLM)

#### ขั้นตอนติดตั้ง
```bash
# 1. Install R packages
R -e "install.packages(c('optparse', 'yaml', 'jsonlite'))"

# 2. Install Python packages
pip3 install requests

# 3. Install Ollama & AI model
curl -fsSL https://ollama.ai/install.sh | sh
ollama pull gpt-oss:20b

# 4. Install as global command
sudo ln -sf $(pwd)/bin/krurooai /usr/local/bin/krurooai

# 5. Fix config files
echo "" >> config/llm.yaml
echo "" >> config/privacy.yaml
```

**📖 สำหรับรายละเอียด:** ดู [INSTALL.md](INSTALL.md)

### การติดตั้ง Local LLM (ทางเลือก)

สำหรับใช้งาน Local LLM ผ่าน Ollama:

```bash
# ติดตั้ง Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# ดาวน์โหลดโมเดล
ollama pull gpt-oss:20b
# หรือ
ollama pull llama2:7b
```

## 📋 การใช้งาน

### คำสั่งพื้นฐาน

```bash
# ตรวจงานไฟล์เดี่ยว
./bin/krurooai grade student.txt --context assignment.md

# ตรวจงานแบบ batch (ควบคุมขนาด batch)
./bin/krurooai batch-grade submissions/ --context assignment.md --batch-size 3

# 🆕 นำเข้าข้อมูล CSV จาก Google Forms
./bin/krurooai csv-import responses.csv --output-dir submissions

# 🆕 นำเข้า CSV และตรวจงานอัตโนมัติ
./bin/krurooai csv-import quiz_data.csv --auto-grade --context assignment.md

# ตรวจสอบการตั้งค่าระบบ
./bin/krurooai config-check

# ทดสอบ privacy filter
./bin/krurooai test-privacy sample_data.txt

# ดูคำแนะนำการใช้งาน
./bin/krurooai help
```

### ⚙️ Batch Size Control

KruRooAI รองรับการควบคุมขนาด batch เพื่อคุณภาพการตรวจ:

```bash
# กำหนดขนาด batch (default: 5)
krurooai batch-grade submissions/ \
  --context context.md \
  --batch-size 3

# ระบบจะ:
# - แบ่งไฟล์เป็นกลุม ๆ ละ 3 ไฟล์  
# - หยุดรอ confirmation ระหว่างแต่ละ batch
# - ประมวลผลครบทุกไฟล์ตามลำดับ
# - สร้างรายงานสำหรับแต่ละไฟล์
```

**ประโยชน์ของการควบคุม Batch Size:**
- 🎯 **Quality Control**: ตรวจสอบคุณภาพระหว่างประมวลผล
- ⚡ **Performance**: ป้องกัน LLM overload  
- 🔧 **Flexibility**: ปรับแต่งตามทรัพยากรระบบ
- 📊 **Progress Tracking**: ติดตามความคืบหน้าชัดเจน
- ✅ **Complete Processing**: รับประกันประมวลผลครบทุกไฟล์

**การเลือกขนาด Batch Size:**
- `--batch-size 1`: ตรวจทีละไฟล์ (แม่นยำสูงสุด)
- `--batch-size 3-5`: เหมาะกับการตรวจงานทั่วไป (แนะนำ)
- `--batch-size 10+`: สำหรับงานจำนวนมาก (ต้องมี LLM เสถียร)

### 🎯 Quick Start - ใช้งานจริงในสถานการณ์

**Scenario 1: ตรวจข้อสอบจาก Google Forms**

```bash
# 1. Export ข้อมูลจาก Google Forms เป็น CSV
# 2. นำเข้าและตรวจงานอัตโนมัติ
./bin/krurooai csv-import quiz_responses.csv \
  --auto-grade --context quiz_context.md \
  --output-dir student_submissions

# ผลลัพธ์: ได้รายงานการตรวจงานทุกคนใน reports/
```

**Scenario 2: ตรวจงาน Assignment แบบไฟล์แยก**

```bash
# 1. จัดเก็บงานนักเรียนใน submissions/
# 2. สร้าง context file
# 3. ตรวจงานทั้งหมด (แบบมีควบคุมคุณภาพ)
./bin/krurooai batch-grade submissions/ \
  --context assignment_context.md \
  --output-dir reports/ \
  --batch-size 5
```

### 📈 CSV Import Features

**Basic Import:**
```bash
./bin/krurooai csv-import responses.csv
```

**Advanced Import with Custom Settings:**
```bash
./bin/krurooai csv-import survey.csv \
  --email-column "อีเมล" \
  --timestamp-column "เวลาส่ง" \
  --skip-columns "รหัสนักเรียน,ชื่อ-นามสกุล" \
  --prefix "student" \
  --output-dir submissions
```

### ตัวอย่างการใช้งาน

1. **เตรียม Context File** (`assignment.md`):

```markdown
# Assignment Context: การแก้สมการกำลังสอง

## คำถาม
จงแก้สมการ x² - 5x + 6 = 0 โดยใช้วิธีการแยกตัวประกอบ

## คำตอบมาตรฐาน  
x = 2 หรือ x = 3

## เกณฑ์การประเมิน
- ความถูกต้องของคำตอบ (40%)
- วิธีการและกระบวนการ (40%)
- การนำเสนอและความชัดเจน (20%)
```

2. **รันคำสั่งตรวจงาน**:

```bash
./bin/krurooai grade student_001.txt --context assignment.md --mode local
```

### ตัวอย่างการใช้งานกับไฟล์ CSV

**สำหรับข้อมูลจาก Google Forms หรือ Survey:**

1. **เตรียมไฟล์ CSV** (`quiz_responses.csv`):
```csv
Timestamp,Email Address,Score,ข้อใดอธิบายแนวคิด Data-Driven Classroom,ข้อใดสะท้อนแนวคิด Education 4.0,Analytics และ AI บทบาทอย่างไร
8/4/2025 23:25:41,student001@university.ac.th,0 / 1,การจัดการเรียนรู้โดยใช้ข้อมูลของผู้เรียน,การออกแบบการเรียนรู้ที่ส่งเสริมความคิดสร้างสรรค์,ช่วยครูวิเคราะห์พฤติกรรมและผลการเรียน
8/5/2025 0:52:12,student002@university.ac.th,0 / 1,การจัดการเรียนรู้โดยใช้ข้อมูลของผู้เรียน,การจัดหลักสูตรที่ช่วยให้ผู้เรียนสามารถจดจำข้อมูล,ช่วยครูวิเคราะห์พฤติกรรมและผลการเรียน
```

2. **แปลง CSV เป็น Individual Files:**
```bash
# สร้าง Python script สำหรับแปลงไฟล์
python3 -c "
import csv
import os

# อ่าน CSV
with open('quiz_responses.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    
    os.makedirs('submissions', exist_ok=True)
    
    for i, row in enumerate(reader, 1):
        # สร้างไฟล์แต่ละคน
        filename = f'submissions/student_{i:03d}.txt'
        
        with open(filename, 'w', encoding='utf-8') as out:
            out.write(f'Email: {row[\"Email Address\"]}\\n')
            out.write(f'Timestamp: {row[\"Timestamp\"]}\\n')
            out.write(f'คะแนนเดิม: {row[\"Score\"]}\\n\\n')
            
            # เขียนคำตอบของแต่ละข้อ
            for key, value in row.items():
                if key not in ['Timestamp', 'Email Address', 'Score']:
                    out.write(f'คำถาม: {key}\\n')
                    out.write(f'คำตอบ: {value}\\n\\n')
        
        print(f'Created {filename}')
"
```

3. **สร้าง Context File** (`context/quiz_context.md`):
```markdown
# Assignment Context: แบบประเมิน Data-Driven Classroom

## คำถาม
ข้อสอบเกี่ยวกับแนวคิด Data-Driven Classroom และ Education 4.0
- ข้อใดอธิบายแนวคิด "Data-Driven Classroom" ได้ถูกต้องที่สุด?
- ข้อใดสะท้อนแนวคิด Education 4.0?  
- Analytics และ AI มีบทบาทอย่างไรในห้องเรียนที่ขับเคลื่อนด้วยข้อมูล?

## คำตอบมาตรฐาน
1. การจัดการเรียนรู้โดยใช้ข้อมูลของผู้เรียนเพื่อปรับเปลี่ยนการสอนให้เหมาะกับแต่ละคนอย่างต่อเนื่อง ✓
2. การออกแบบการเรียนรู้ที่ส่งเสริมความคิดสร้างสรรค์ ความยืดหยุ่น และการเรียนรู้ตลอดชีวิต ✓
3. ช่วยครูวิเคราะห์พฤติกรรมและผลการเรียนของนักเรียน เพื่อให้ข้อมูลสำหรับปรับการสอน ✓

## เกณฑ์การประเมิน
- ความถูกต้องของคำตอบ (60%)
- ความเข้าใจแนวคิด (25%)
- การอธิบายและให้เหตุผล (15%)
```

4. **ตรวจงานทั้งหมดแบบ Batch:**
```bash
# ตรวจทั้งหมดพร้อมกัน (แบบควบคุมคุณภาพ)
./bin/krurooai batch-grade submissions/ \
  --context context/quiz_context.md \
  --output-dir reports/ \
  --mode local \
  --batch-size 3

# หรือตรวจทีละคน
./bin/krurooai grade submissions/student_001.txt \
  --context context/quiz_context.md \
  --output reports/student_001_report.md
```

5. **ผลลัพธ์ที่ได้:**
```
reports/
├── student_001_report.md
├── student_002_report.md  
├── student_003_report.md
└── batch_summary.md
```

**แต่ละรายงานจะมี:**
- **ผลการประเมิน: ข้อปรนัย** - แสดงเฉลย คำอธิบาย และผลลัพธ์
- **ผลการประเมิน: ข้ออัตนัย** - แสดงจุดสำคัญ การประเมิน และข้อเสนอแนะพัฒนา  
- **ข้อเสนอแนะภาพรวม** - วิเคราะห์ครบถ้วน 100-150 คำ
- **จุดเด่น** - รายละเอียด 50-80 คำ
- **ข้อเสนอแนะเพื่อพัฒนา** - แนวทางปรับปรุง 80-120 คำ
- **การวิเคราะห์เชิงลึก** - วิเคราะห์แนวคิดและการประยุกต์ใช้ 150-200 คำ

**สำหรับข้อสอบความเรียงยาว ๆ:**
```bash
# ใช้ detailed template
./bin/krurooai grade essay_response.txt \
  --context essay_context.md \
  --template detailed \
  --output detailed_report.md
```

## ⚙️ Configuration

### LLM Configuration (`config/llm.yaml`)

```yaml
backends:
  local:
    model: "gpt-oss:20b"
    endpoint: "http://localhost:11434"
    temperature: 0.3
    timeout: 300          # 5 minutes for detailed analysis
    max_tokens: 8000      # Extended for comprehensive feedback
  openai:
    model: "gpt-4o-mini"
    api_key_env: "OPENAI_API_KEY"
    temperature: 0.3
    privacy_mode: true

default_backend: "local"
```

### Privacy Configuration (`config/privacy.yaml`)

```yaml
sensitive_patterns:
  - "ชื่อ\\s*[:\\：]\\s*\\S+"
  - "รหัส\\s*[:\\：]\\s*\\d+"

redaction_rules:
  replace_names: "[STUDENT]"
  replace_ids: "[ID]"

api_safety:
  enabled: true
  privacy_threshold: 0.7
```

## 📁 โครงสร้างโปรเจกต์

```
krurooai/
├── R/                      # R source files
│   ├── main.R             # CLI entry point
│   ├── cli_parser.R       # Command parsing
│   ├── context_processor.R # Markdown processing
│   ├── privacy_filter.R   # Data redaction
│   ├── report_generator.R # Output formatting
│   └── config_manager.R   # YAML config handling
├── python/                # Python LLM integration
│   ├── llm_router.py      # LLM backend router
│   ├── local_llm.py       # Ollama integration  
│   ├── api_llm.py         # OpenAI integration
│   └── privacy_utils.py   # Privacy helper functions
├── config/                # Configuration files
│   ├── llm.yaml           # LLM backend settings
│   ├── privacy.yaml       # Privacy rules
│   └── templates.yaml     # Grading templates
├── templates/             # Prompt and report templates
├── tests/                 # Test files and sample data
├── bin/                   # Executables
└── docs/                  # Documentation
```

## 🔐 ความปลอดภัยและความเป็นส่วนตัว

KruRooAI ให้ความสำคัญกับการปกป้องข้อมูลส่วนตัว:

- **Auto-redaction**: คัดกรองชื่อ รหัสนักเรียน ข้อมูลส่วนตัวอัตโนมัติ
- **API Safety**: ตรวจสอบความปลอดภัยก่อนส่งข้อมูลไป API
- **Local Processing**: สนับสนุนการประมวลผลด้วย Local LLM
- **Configurable Privacy**: ปรับระดับการปกป้องข้อมูลได้

## 🧪 การทดสอบ

```bash
# ทดสอบ privacy filter
./bin/krurooai test-privacy tests/sample_data/sample_submission.txt

# ทดสอบการตรวจงาน
./bin/krurooai grade tests/sample_data/sample_submission.txt \
  --context tests/sample_data/sample_context.md \
  --mode local
```

## 🤝 การพัฒนา

### การตั้งค่า Development Environment

```bash
# Clone repository
git clone <repository-url>
cd krurooai

# ติดตั้ง dependencies
R -e "install.packages(c('optparse', 'yaml', 'reticulate', 'testthat'))"
pip3 install requests pytest

# รัน tests
Rscript -e "testthat::test_dir('tests/test_cases')"
python3 -m pytest tests/
```

### การเพิ่มฟีเจอร์ใหม่

1. แก้ไข R functions ใน `R/`
2. แก้ไข Python integrations ใน `python/`
3. อัปเดต configuration files ใน `config/`
4. เพิ่ม tests ใน `tests/`

## 📊 รูปแบบรายงานที่ได้รับการปรับปรุง

KruRooAI ได้รับการปรับปรุงให้สร้างรายงานที่แยกประเภทคำถามและให้ข้อมูลป้อนกลับแบบละเอียด:

### 🎯 การแยกประเภทคำถาม

**ข้อปรนัย (Objective Questions)**
```markdown
## ผลการประเมิน: ข้อปรนัย

### ข้อที่ 1
**คำตอบของนักเรียน:** การจัดการเรียนรู้โดยใช้ข้อมูล...
**คำตอบที่ถูกต้อง:** การจัดการเรียนรู้โดยใช้ข้อมูล...
**ผลลัพธ์:** 6/6 (✅ ถูกต้อง)
**คำอธิบาย:** คำตอบตรงกับคำตอบมาตรฐานอย่างครบถ้วน...
```

**ข้ออัตนัย (Subjective Questions)**
```markdown
## ผลการประเมิน: ข้ออัตนัย

### ข้อที่ 8
**คำตอบของนักเรียน:**
[คำตอบยาวของนักเรียน...]

**คะแนนที่ได้:** 20/100

**จุดสำคัญที่ควรมี:**
1) ความเข้าใจแนวคิด Data-Driven Classroom
2) การประยุกต์ใช้ในห้องเรียน
3) เหตุผลที่เพิ่มประสิทธิภาพการเรียนรู้

**การประเมิน:**
คำตอบมีความเข้าใจพื้นฐาน แต่ยังขาดความลึก...

**ข้อเสนอแนะเพื่อพัฒนา:**
1. เพิ่มความยาวให้ครบ 150 คำต่อส่วน
2. ใช้ตัวอย่างการใช้ข้อมูลจริง...
```

### 🔍 คุณสมบัติพิเศษ

- **Token Limit**: เพิ่มเป็น 8000 tokens สำหรับการวิเคราะห์ละเอียด
- **Timeout**: ขยายเป็น 300 วินาที สำหรับงานซับซ้อน
- **Structured Feedback**: แยกเฉลย การประเมิน และข้อเสนอแนะ
- **Question Type Detection**: ระบุประเภทคำถามอัตโนมัติ
- **Comprehensive Analysis**: วิเคราะห์เชิงลึก 150-200 คำ

## 📄 License

MIT License - ดู LICENSE file สำหรับรายละเอียด

## 🙋‍♂️ การสนับสนุน

สำหรับปัญหาการใช้งานหรือข้อเสนอแนะ:

- สร้าง Issue ใน GitHub repository
- ดู documentation ใน `docs/`
- ตรวจสอบ sample files ใน `tests/sample_data/`

## 📦 การติดตั้งแบบ System-wide (แนะนำ)

**สำหรับใช้งานง่าย ๆ จากที่ไหนก็ได้:**

```bash
# วิธีที่ 1: Symlink (แนะนำ)
sudo ln -sf /Users/choat/Documents/krurooai-project/bin/krurooai /usr/local/bin/krurooai

# วิธีที่ 2: Copy ไฟล์
sudo cp /Users/choat/Documents/krurooai-project/bin/krurooai /usr/local/bin/krurooai
sudo chmod +x /usr/local/bin/krurooai

# ทดสอบการติดตั้ง
cd ~/Desktop  # ไปที่ไหนก็ได้
krurooai help  # ใช้ได้จากทุกที่!
```

**หลังติดตั้งแล้ว สามารถใช้งานได้จากทุก directory:**

```bash
# สร้าง workspace แยก
mkdir ~/KruRooAI-Work
cd ~/KruRooAI-Work

# ใช้งานปกติ
krurooai csv-import ~/Downloads/quiz_responses.csv --auto-grade --context assignment.md
```

## 🎓 การใช้งานในสถานการณ์จริง

### สำหรับครูที่ใช้ Google Forms

1. **สร้างแบบฟอร์มใน Google Forms** 
2. **Export responses เป็น CSV**
3. **รันคำสั่งเดียว:**
   ```bash
   krurooai csv-import responses.csv --auto-grade --context assignment.md
   ```
4. **ได้รายงานการตรวจงานทุกคนทันที** 

### สำหรับครูที่รับงานเป็นไฟล์

1. **จัดเก็บงานนักเรียนใน folder**
2. **สร้างไฟล์ context.md**
3. **ตรวจงานแบบ batch (ควบคุมคุณภาพ):**
   ```bash
   krurooai batch-grade submissions/ --context context.md --batch-size 5
   ```
   - ระบบจะแบ่งไฟล์เป็นกลุม ๆ ละ 5 ไฟล์
   - หยุดรอ confirmation ระหว่างแต่ละ batch เพื่อตรวจสอบคุณภาพ
   - ประมวลผลครบทุกไฟล์ตามลำดับ

## 🔧 Troubleshooting

**หาก LLM ไม่ทำงาน:**
```bash
# ตรวจสอบสถานะระบบ
krurooai config-check

# เริ่ม Ollama server (หากใช้ local LLM)
ollama serve
```

**หากมี Warning เรื่อง config files:**
```bash
echo "" >> config/llm.yaml
echo "" >> config/privacy.yaml
```

**หาก CSV import ไม่ทำงาน:**
```bash
# ดูโครงสร้าง CSV ก่อน
python3 python/csv_processor.py your_file.csv --analyze
```

## 🚧 Future Roadmap

- [ ] Web interface for easier use
- [ ] Database integration for data persistence  
- [ ] Advanced analytics and reporting
- [ ] Multi-language support (English interface)
- [ ] Plugin system for custom grading criteria

---

## 🗑️ การถอนการติดตั้ง

หากต้องการลบ KruRooAI ออกจากเครื่อง:

```bash
# ใช้ uninstall script (แนะนำ)
./uninstall.sh

# หรือลบแบบ manual
sudo rm -f /usr/local/bin/krurooai
cd .. && rm -rf krurooai-project
rm -rf ~/KruRooAI-Work
```

**📖 สำหรับรายละเอียด:** ดู [UNINSTALL.md](UNINSTALL.md)

## 📞 Support & Documentation

- **Installation Guide**: [INSTALL.md](INSTALL.md)
- **Uninstall Guide**: [UNINSTALL.md](UNINSTALL.md)
- **GitHub Issues**: สำหรับ bug reports และ feature requests
- **Documentation**: ดูใน `docs/` folder สำหรับรายละเอียดเพิ่มเติม
- **Sample Files**: ดูตัวอย่างใน `tests/sample_data/`

*KruRooAI v1.0 - Educational AI Assistant for Thai Schools*  
*Ready for Production Use - September 2025*