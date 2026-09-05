import os
import shutil
import time

TARGET_DIR = r"C:\en1gma-tech\resources"
TARGET_FILE = os.path.join(TARGET_DIR, "wlogo_125.png")

BACKUP_FILE_NAME = "wlogo_125.png"
REQUIRED_SIZE = 11514 
CHECK_INTERVAL = 1

def get_script_dir():
    return os.path.dirname(os.path.abspath(__file__))

def check_and_restore():
    source_backup = os.path.join(get_script_dir(), BACKUP_FILE_NAME)
    if not os.path.exists(source_backup):
        print(f"[-] Ошибка: Рядом со скриптом не найден эталонный файл: {BACKUP_FILE_NAME}")
        return

    try:
        if os.path.exists(TARGET_FILE):
            current_size = os.path.getsize(TARGET_FILE)
            if current_size == REQUIRED_SIZE:
                return
            
            print(f"[!] Размер изменился: {current_size} байт вместо {REQUIRED_SIZE}. Заменяю...")
        else:
            print("[!] Целевой файл отсутствует. Восстанавливаю...")
        if not os.path.exists(TARGET_DIR):
            os.makedirs(TARGET_DIR, exist_ok=True)
            print(f"[+] Создана отсутствующая папка: {TARGET_DIR}")
        shutil.copy2(source_backup, TARGET_FILE)
        print(f"[+] Файл успешно восстановлен: {TARGET_FILE}")
        
    except Exception as e:
        print(f"[-] Произошла ошибка при обработке: {e}")

if __name__ == "__main__":
    print(f"[*] Скрипт запущен. Наблюдаю за {TARGET_FILE}...")
    print(f"[*] Для остановки нажмите Ctrl+C")
    
    while True:
        check_and_restore()
        time.sleep(CHECK_INTERVAL)
