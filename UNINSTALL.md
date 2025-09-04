# KruRooAI Uninstall Guide

## 🗑️ วิธีลบ KruRooAI ออกจากเครื่อง

### ⚡ Quick Uninstall

```bash
# Run uninstall script
./uninstall.sh
```

### 🔧 Manual Uninstall

#### 1. ลบ Global Command
```bash
# ลบ symlink หรือ executable file
sudo rm -f /usr/local/bin/krurooai

# ตรวจสอบว่าลบแล้ว
which krurooai  # ควรไม่เจออะไร
```

#### 2. ลบโฟลเดอร์โปรเจกต์
```bash
# ย้ายไปที่โฟลเดอร์แม่ก่อน
cd ..

# ลบโฟลเดอร์ทั้งหมด
rm -rf krurooai-project
```

#### 3. ลบ Workspace (ถ้ามี)
```bash
# ลบ workspace ที่สร้างไว้
rm -rf ~/KruRooAI-Work

# หรือลบเฉพาะไฟล์ที่ไม่ต้องการ
rm -rf ~/KruRooAI-Work/submissions
rm -rf ~/KruRooAI-Work/reports
# เก็บไว้เฉพาะ data/ และ contexts/
```

#### 4. ลบ Ollama และ AI Models (ทางเลือก)
```bash
# ดู models ที่ติดตั้งไว้
ollama list

# ลบ specific model
ollama rm gpt-oss:20b
ollama rm llama2:7b

# ลบ Ollama ทั้งหมด (ถ้าไม่ใช้อื่น)
# macOS
brew uninstall ollama

# Linux
sudo systemctl stop ollama
sudo rm -rf /usr/local/bin/ollama
sudo rm -rf ~/.ollama
```

#### 5. ลบ Dependencies (ทางเลือก - ระวัง!)

⚠️ **คำเตือน:** อย่าลบ R หรือ Python ถ้ายังใช้โปรแกรมอื่น

```bash
# ลบ R packages เฉพาะที่ KruRooAI ใช้
R --slave -e "remove.packages(c('optparse', 'yaml', 'jsonlite'))"

# ลบ Python requests (ถ้าไม่มีโปรแกรมอื่นใช้)
pip3 uninstall requests
```

## 🔍 ตรวจสอบการลบ

### ตรวจสอบว่าลบหมดแล้ว
```bash
# ตรวจสอบ global command
which krurooai
# ผลลัพธ์: krurooai not found

# ตรวจสอบโฟลเดอร์
ls ~/krurooai-project
# ผลลัพธ์: No such file or directory

# ตรวจสอบ workspace
ls ~/KruRooAI-Work
# ผลลัพธ์: No such file or directory (ถ้าลบแล้ว)
```

### ตรวจสอบ processes ที่ยังทำงาน
```bash
# ตรวจสอบ Ollama
ps aux | grep ollama

# หยุด Ollama process (ถ้ายังทำงานอยู่)
killall ollama
```

## 🧹 Clean Uninstall Options

### ลบทุกอย่าง (Full Clean)
```bash
# ลบโปรเจกต์
sudo rm -f /usr/local/bin/krurooai
cd .. && rm -rf krurooai-project

# ลบ workspace
rm -rf ~/KruRooAI-Work

# ลบ Ollama และ models
ollama rm gpt-oss:20b
brew uninstall ollama  # macOS

# ลบ R packages
R --slave -e "remove.packages(c('optparse', 'yaml', 'jsonlite'))"
```

### ลบเฉพาะโปรแกรม (Keep Dependencies)
```bash
# เก็บ R, Python, Ollama ไว้ ลบแค่ KruRooAI
sudo rm -f /usr/local/bin/krurooai
cd .. && rm -rf krurooai-project

# เก็บ workspace data ไว้
mkdir ~/KruRooAI-Backup
mv ~/KruRooAI-Work/data ~/KruRooAI-Backup/
mv ~/KruRooAI-Work/contexts ~/KruRooAI-Backup/
rm -rf ~/KruRooAI-Work
```

## 🔄 การติดตั้งใหม่

หากต้องการติดตั้งใหม่ในอนาคต:

```bash
# Clone อีกครั้ง
git clone https://github.com/[your-username]/krurooai-project.git
cd krurooai-project
./install.sh
```

## ⚠️ สิ่งที่ควรระวัง

1. **อย่าลบ R หรือ Python** ถ้ายังมีโปรแกรมอื่นใช้
2. **เช็ค workspace** ก่อนลบ อาจมีไฟล์สำคัญ
3. **Backup ข้อมูล** contexts และ reports ที่สำคัญก่อน
4. **Ollama models** ใหญ่มาก ถ้าจะใช้ใหม่อย่าลบ

## 🆘 หากมีปัญหา

```bash
# หาไฟล์ที่เหลือ
find /usr/local/bin -name "*krurooai*"
find ~ -name "*krurooai*" -o -name "*KruRooAI*"

# ลบไฟล์ที่เหลือ
sudo rm -f /path/to/remaining/files
```