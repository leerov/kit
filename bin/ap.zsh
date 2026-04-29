#!/bin/bash
# lib/ap.zsh - AP (AI-friendly Patch) functions

export AP_HOME="/opt/goinfre/$(whoami)/ap"

# Function to ensure ap is installed
_ensure_ap() {
    if [[ ! -d "$AP_HOME" ]]; then
        echo "📦 AP not found at $AP_HOME, cloning..."
        git clone https://github.com/unxed/ap.git "$AP_HOME"
        if [[ $? -eq 0 ]]; then
            echo "✅ AP cloned successfully"
        else
            echo "❌ Failed to clone AP"
            return 1
        fi
    fi
    if [[ ! -f "$AP_HOME/implementation/ap.py" ]]; then
        echo "❌ Error: $AP_HOME/implementation/ap.py not found"
        return 1
    fi
    return 0
}

function fj() {
    _ensure_ap || return 1

    if [[ ! -f "$AP_HOME/ap.md" ]]; then
        echo "❌ Error: $AP_HOME/ap.md not found"
        return 1
    fi

    local tmpfile="/tmp/fj_combined.txt"

    cat > "$tmpfile" << 'EOF'
# INSTRUCTIONS FOR AI
#
# === PROJECT STRUCTURE ===
#
EOF

    tree >> "$tmpfile" 2>/dev/null

    cat >> "$tmpfile" << 'EOF'
#
# === END OF PROJECT STRUCTURE ===
#
# Now wait. Do nothing else.
# Do not explain anything.
# Do not add any comments or extra text.
# Just wait for my next message.
#
# Below is the ap format specification and the current code.
# After I tell you what to change, generate ONLY the ap patch file.
# Nothing else. Just the patch.
#
# write patch like a code block
# 
# ```ap
# 
# ```
#
# === AP FORMAT SPECIFICATION ===
#
EOF

    cat "$AP_HOME/ap.md" >> "$tmpfile"

    echo -e "\n\n=== CURRENT CODE (with line numbers) ===\n" >> "$tmpfile"
    sc --stdout >> "$tmpfile" 2>&1

    cat >> "$tmpfile" << 'EOF'

# === WAITING FOR TASK ===
#
# I have analyzed the project structure and code.
# I am ready to generate AP patches.
# Just tell me what to change.
#
# write patch like a code block
# 
# ```ap
# 
# ```
#
# === PROJECT STRUCTURE (again) ===
#
EOF

    tree >> "$tmpfile" 2>/dev/null

    echo -e "\n# === END ===" >> "$tmpfile"

    cat "$tmpfile" | pbcopy
    rm "$tmpfile"
    echo "✅ Copied to clipboard: tree + instructions + ap.md + sc output"
}

function jf() {
    _ensure_ap || return 1

    local tmpfile="/tmp/jf_patch_$(date +%s).ap"
    pbpaste > "$tmpfile"
    if [[ ! -s "$tmpfile" ]]; then
        echo "❌ Буфер обмена пуст. Скопируйте сначала ap-патч."
        rm -f "$tmpfile"
        return 1
    fi
    python3 "$AP_HOME/implementation/ap.py" "$tmpfile" "$@"
    rm -f ./afailed.ap 2>/dev/null
    rm "$tmpfile"
}

function fs() {
    _ensure_ap || return 1
    
    # Берем содержимое буфера обмена
    local clipboard_content=$(pbpaste)
    if [[ -z "$clipboard_content" ]]; then
        echo "❌ Clipboard is empty. Run 'fj' first to copy project structure."
        return 1
    fi
    
    # Извлекаем секцию с деревом
    local tree_section=$(echo "$clipboard_content" | sed -n '/=== PROJECT STRUCTURE ===/,/=== END OF PROJECT STRUCTURE ===/p' | sed '1d;$d')
    
    if [[ -z "$tree_section" ]]; then
        echo "❌ Could not find PROJECT STRUCTURE section in clipboard"
        return 1
    fi
    
    echo "📁 Creating filesystem from structure..."
    
    # Парсим дерево и создаем файлы/папки
    local tmp_script="/tmp/fs_parse_$$.py"
    
    cat > "$tmp_script" << 'PYTHON_SCRIPT'
import sys
import os
import re

def parse_and_create(tree_text, base_path):
    """Parse tree with └──, ├──, │ and create directories/files"""
    lines = tree_text.split('\n')
    
    # Убираем первую строку с "." если есть
    if lines and lines[0].strip() == '.':
        lines = lines[1:]
    
    # Стек для отслеживания текущего пути
    path_stack = []
    created_dirs = set()
    created_files = set()
    
    for line in lines:
        if not line.strip():
            continue
        
        # Определяем глубину вложенности по количеству символов │ и пробелов
        # Считаем количество "└──" и "├──" для определения уровня
        depth = 0
        # Считаем вертикальные черты и пробелы перед ними
        match = re.match(r'^(.*?)(?:├──|└──)', line)
        if match:
            prefix = match.group(1)
            # Каждый "│   " или "    " это уровень
            depth = prefix.count('│') + (prefix.count('    ') // 4)
        
        # Извлекаем имя элемента (после └── или ├──)
        name_match = re.search(r'(?:├──|└──)\s*(.+?)$', line)
        if not name_match:
            continue
        
        name = name_match.group(1).strip()
        
        # Убираем декоративные символы в начале имени
        name = re.sub(r'^[│├└─\s]+', '', name)
        
        if not name:
            continue
        
        # Корректируем стек до нужной глубины
        while len(path_stack) > depth:
            path_stack.pop()
        
        # Определяем полный путь
        if path_stack:
            full_path = os.path.join(base_path, *path_stack, name)
        else:
            full_path = os.path.join(base_path, name)
        
        # Определяем, это файл или папка?
        # Если есть расширение или это .gitkeep/.gitignore - скорее файл
        is_file = False
        if '.' in name and not name.endswith('/'):
            is_file = True
        elif name.startswith('.') and name not in ['.gitkeep', '.gitignore']:
            is_file = True
        elif name in ['app.py', 'requirements.txt', 'setup.sql']:
            is_file = True
        
        # Создаем
        if is_file:
            # Создаем родительскую папку
            parent = os.path.dirname(full_path)
            if parent and parent not in created_dirs:
                os.makedirs(parent, exist_ok=True)
                created_dirs.add(parent)
                print(f"  📁 Created directory: {os.path.relpath(parent, base_path)}")
            
            # Создаем пустой файл
            if not os.path.exists(full_path):
                with open(full_path, 'w') as f:
                    pass  # Пустой файл
                print(f"  📄 Created file: {os.path.relpath(full_path, base_path)}")
                created_files.add(full_path)
            else:
                print(f"  ⏭️  File already exists: {os.path.relpath(full_path, base_path)}")
        else:
            # Это папка
            if full_path not in created_dirs:
                os.makedirs(full_path, exist_ok=True)
                created_dirs.add(full_path)
                print(f"  📁 Created directory: {os.path.relpath(full_path, base_path)}")
        
        # Добавляем в стек для следующих уровней (только для папок)
        if not is_file and name != '.':
            path_stack.append(name)
    
    return created_dirs, created_files

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)
    
    tree_text = sys.argv[1]
    base_path = sys.argv[2] if len(sys.argv) > 2 else os.getcwd()
    
    try:
        dirs, files = parse_and_create(tree_text, base_path)
        print(f"\n✅ Created: {len(dirs)} directories, {len(files)} files")
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)
PYTHON_SCRIPT

    # Запускаем парсер
    python3 "$tmp_script" "$tree_section" "$PWD"
    local result=$?
    
    rm -f "$tmp_script"
    
    if [[ $result -eq 0 ]]; then
        echo ""
        echo "📊 Final structure:"
        tree -L 2 2>/dev/null || ls -la
        return 0
    else
        echo "❌ Failed to create structure"
        return 1
    fi
}