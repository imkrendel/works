import os
import sys
import json
import shutil
import fnmatch
import base64
import mimetypes
import xml.etree.ElementTree as ET
from datetime import datetime

import requests
import webview

APPDATA = os.getenv('APPDATA') or os.path.expanduser('~/.xrmanager')
BASE_DIR = os.path.join(APPDATA, 'xRManager')
CONTENT_DIR = os.path.join(BASE_DIR, 'content')
PROFILES_DIR = os.path.join(BASE_DIR, 'profiles')

os.makedirs(CONTENT_DIR, exist_ok=True)
os.makedirs(PROFILES_DIR, exist_ok=True)

RU_MONTHS = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
]


def ru_date(dt: datetime) -> str:
    return f'{dt.day} {RU_MONTHS[dt.month - 1]} {dt.year}'


class Api:
    def pick_file(self):
        result = webview.windows[0].create_file_dialog(
            webview.OPEN_DIALOG,
            file_types=(
                'Медиафайлы (*.png;*.jpg;*.jpeg;*.gif;*.mp4;*.mkv;*.avi;*.webm;*.mov)',
                'Все файлы (*.*)',
            ),
        )
        if result:
            return result[0]
        return None

    def add_ban(self, steam64, reason, doc_path):
        steam64 = (steam64 or '').strip()
        reason = (reason or '').strip()

        if not steam64.isdigit():
            return {'ok': False, 'error': 'Steam64 должен содержать только цифры'}
        if not reason:
            return {'ok': False, 'error': 'Укажите причину / правило'}

        now = datetime.now()
        ts_folder = now.strftime('%d.%m.%Y_%H-%M-%S')
        entry_dir = os.path.join(CONTENT_DIR, steam64, ts_folder)
        os.makedirs(entry_dir, exist_ok=True)

        doc_name = ''
        if doc_path and os.path.isfile(doc_path):
            doc_name = os.path.basename(doc_path)
            try:
                shutil.copy2(doc_path, os.path.join(entry_dir, doc_name))
            except Exception:
                doc_name = ''

        date_human = f'{now.strftime("%d.%m.%Y")} ({ru_date(now)})'
        data_file = os.path.join(entry_dir, 'data.txt')
        with open(data_file, 'w', encoding='utf-8') as f:
            f.write(f'Steam64: {steam64}\n')
            f.write(f'Правило/Причина: {reason}\n')
            f.write(f'Дата: {date_human}\n')
            f.write(f'Доказательства: {doc_name}\n')

        return {'ok': True}

    def list_bans(self):
        bans = []
        if not os.path.isdir(CONTENT_DIR):
            return bans

        for steam64 in os.listdir(CONTENT_DIR):
            steam_path = os.path.join(CONTENT_DIR, steam64)
            if not os.path.isdir(steam_path):
                continue
            for ts in os.listdir(steam_path):
                entry_path = os.path.join(steam_path, ts)
                data_file = os.path.join(entry_path, 'data.txt')
                if not os.path.isfile(data_file):
                    continue

                reason, doc_name = '', ''
                with open(data_file, encoding='utf-8') as f:
                    for line in f:
                        if line.startswith('Правило/Причина:'):
                            reason = line.split(':', 1)[1].strip()
                        elif line.startswith('Доказательства:'):
                            doc_name = line.split(':', 1)[1].strip()

                bans.append({
                    'steam64': steam64,
                    'timestamp': ts,
                    'reason': reason,
                    'doc': doc_name,
                    'doc_path': os.path.join(entry_path, doc_name) if doc_name else '',
                    'path': entry_path,
                })

        bans.sort(key=lambda b: b['timestamp'], reverse=True)
        return bans

    def search_bans(self, query):
        query = (query or '').strip()
        all_bans = self.list_bans()
        if not query:
            return all_bans
        if query.isdigit():
            return [b for b in all_bans if query in b['steam64']]
        pattern = query.lower()
        if '*' not in pattern:
            pattern = f'*{pattern}*'
        return [b for b in all_bans if fnmatch.fnmatch(b['reason'].lower(), pattern)]

    def delete_ban(self, path):
        try:
            shutil.rmtree(path)
            return {'ok': True}
        except Exception as e:
            return {'ok': False, 'error': str(e)}

    def open_folder(self, path):
        try:
            os.startfile(path)
            return {'ok': True}
        except Exception as e:
            return {'ok': False, 'error': str(e)}

    IMAGE_EXT = {'.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'}
    VIDEO_EXT = {'.mp4', '.mkv', '.avi', '.webm', '.mov'}
    VIDEO_PREVIEW_LIMIT = 40 * 1024 * 1024

    def get_doc_preview(self, doc_path):
        if not doc_path or not os.path.isfile(doc_path):
            return {'ok': False, 'error': 'Файл не найден'}

        ext = os.path.splitext(doc_path)[1].lower()
        mime, _ = mimetypes.guess_type(doc_path)

        try:
            if ext in self.IMAGE_EXT:
                with open(doc_path, 'rb') as f:
                    b64 = base64.b64encode(f.read()).decode('ascii')
                return {'ok': True, 'kind': 'image',
                        'data_uri': f'data:{mime or "image/png"};base64,{b64}'}

            if ext in self.VIDEO_EXT:
                if os.path.getsize(doc_path) > self.VIDEO_PREVIEW_LIMIT:
                    return {'ok': True, 'kind': 'video-too-large'}
                with open(doc_path, 'rb') as f:
                    b64 = base64.b64encode(f.read()).decode('ascii')
                return {'ok': True, 'kind': 'video',
                        'data_uri': f'data:{mime or "video/mp4"};base64,{b64}'}
        except Exception as e:
            return {'ok': False, 'error': str(e)}

        return {'ok': True, 'kind': 'other'}

    def _profile_path(self, steam64):
        return os.path.join(PROFILES_DIR, steam64, 'profile.json')

    def _load_profile(self, steam64):
        p = self._profile_path(steam64)
        if not os.path.isfile(p):
            return None
        with open(p, encoding='utf-8') as f:
            return json.load(f)

    def _save_profile(self, profile):
        p = self._profile_path(profile['steam64'])
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, 'w', encoding='utf-8') as f:
            json.dump(profile, f, ensure_ascii=False, indent=2)

    def add_profile(self, steam64):
        steam64 = (steam64 or '').strip()
        if not steam64.isdigit():
            return {'ok': False, 'error': 'Steam64 должен содержать только цифры'}

        try:
            r = requests.get(
                f'https://steamcommunity.com/profiles/{steam64}?xml=1', timeout=10
            )
            r.encoding = 'utf-8'
            root = ET.fromstring(r.content)
            err = root.findtext('error')
            if err:
                return {'ok': False, 'error': f'Steam: {err}'}
            nickname = root.findtext('steamID') or ''
            avatar = root.findtext('avatarFull') or root.findtext('avatarIcon') or ''
        except Exception as e:
            return {'ok': False, 'error': f'Ошибка запроса профиля: {e}'}

        old_names = []
        try:
            r2 = requests.get(
                f'https://steamcommunity.com/profiles/{steam64}/ajaxaliases/',
                timeout=10,
                headers={'X-Requested-With': 'XMLHttpRequest'},
            )
            data = r2.json()
            old_names = [item.get('newname', '') for item in data if item.get('newname')]
        except Exception:
            old_names = []

        existing = self._load_profile(steam64) or {}
        profile = {
            'steam64': steam64,
            'nickname': nickname,
            'avatar': avatar,
            'old_names': old_names,
            'note': existing.get('note', ''),
            'tags': existing.get('tags', []),
            'updated': datetime.now().strftime('%d.%m.%Y %H:%M:%S'),
        }

        self._save_profile(profile)
        return {'ok': True, 'profile': profile}

    def refresh_profile(self, steam64):
        return self.add_profile(steam64)

    def list_profiles(self):
        profiles = []
        if not os.path.isdir(PROFILES_DIR):
            return profiles
        for steam64 in os.listdir(PROFILES_DIR):
            pf = os.path.join(PROFILES_DIR, steam64, 'profile.json')
            if os.path.isfile(pf):
                with open(pf, encoding='utf-8') as f:
                    profiles.append(json.load(f))
        return profiles

    def delete_profile(self, steam64):
        try:
            shutil.rmtree(os.path.join(PROFILES_DIR, steam64))
            return {'ok': True}
        except Exception as e:
            return {'ok': False, 'error': str(e)}

    def set_profile_note(self, steam64, note):
        profile = self._load_profile(steam64)
        if profile is None:
            return {'ok': False, 'error': 'Профиль не найден'}
        profile['note'] = (note or '').strip()
        self._save_profile(profile)
        return {'ok': True}

    def add_profile_tag(self, steam64, tag):
        tag = (tag or '').strip()
        if not tag:
            return {'ok': False, 'error': 'Пустой тег'}
        if not tag.startswith('#'):
            tag = '#' + tag

        profile = self._load_profile(steam64)
        if profile is None:
            return {'ok': False, 'error': 'Профиль не найден'}

        tags = profile.get('tags', [])
        if tag not in tags:
            tags.append(tag)
        profile['tags'] = tags
        self._save_profile(profile)
        return {'ok': True, 'tags': tags}

    def remove_profile_tag(self, steam64, tag):
        profile = self._load_profile(steam64)
        if profile is None:
            return {'ok': False, 'error': 'Профиль не найден'}
        profile['tags'] = [t for t in profile.get('tags', []) if t != tag]
        self._save_profile(profile)
        return {'ok': True, 'tags': profile['tags']}

    def window_minimize(self):
        webview.windows[0].minimize()
        return {'ok': True}

    def window_toggle_max(self):
        webview.windows[0].toggle_fullscreen()
        return {'ok': True}

    def window_close(self):
        webview.windows[0].destroy()
        return {'ok': True}

    def window_resize(self, width, height):
        try:
            webview.windows[0].resize(int(width), int(height))
            return {'ok': True}
        except Exception as e:
            return {'ok': False, 'error': str(e)}


SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))


def resource_path(*parts):
    base = getattr(sys, '_MEIPASS', SCRIPT_DIR)
    return os.path.join(base, *parts)


ICON_PATH = resource_path('assets', 'ico.ico')
LOADING_BG = '#2b2d33'


def get_icon_data_uri():
    if not os.path.isfile(ICON_PATH):
        return None
    try:
        with open(ICON_PATH, 'rb') as f:
            b64 = base64.b64encode(f.read()).decode('ascii')
        return f'data:image/x-icon;base64,{b64}'
    except Exception:
        return None


def set_windows_app_id():
    if os.name != 'nt':
        return
    try:
        import ctypes
        ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID('xRManager.DesktopApp')
    except Exception:
        pass


def _to_int_handle(h):
    if not h:
        return None
    try:
        return int(h)
    except Exception:
        pass
    for meth in ('ToInt64', 'ToInt32'):
        try:
            return int(getattr(h, meth)())
        except Exception:
            continue
    return None


def try_set_taskbar_icon(window):
    if os.name != 'nt' or not os.path.isfile(ICON_PATH):
        return
    try:
        import ctypes

        hwnd = None
        for attr in ('hwnd', '_hwnd'):
            hwnd = _to_int_handle(getattr(window, attr, None))
            if hwnd:
                break
        if not hwnd:
            native = getattr(window, 'native', None)
            if native is not None:
                hwnd = _to_int_handle(getattr(native, 'Handle', None))

        if not hwnd:
            gui = getattr(window, 'gui', None)
            hwnd = _to_int_handle(getattr(gui, 'hwnd', None) if gui else None)

        if not hwnd:
            try:
                from webview.platforms import edgechromium as _edge
                bv = _edge.BrowserView.instances.get(window.uid)
                if bv is not None:
                    hwnd = _to_int_handle(getattr(bv, 'Handle', None))
            except Exception:
                pass

        if not hwnd:
            return

        IMAGE_ICON = 1
        LR_LOADFROMFILE = 0x00000010
        WM_SETICON = 0x0080
        ICON_SMALL = 0
        ICON_BIG = 1

        h_icon = ctypes.windll.user32.LoadImageW(
            0, ICON_PATH, IMAGE_ICON, 0, 0, LR_LOADFROMFILE
        )
        if h_icon:
            ctypes.windll.user32.SendMessageW(hwnd, WM_SETICON, ICON_SMALL, h_icon)
            ctypes.windll.user32.SendMessageW(hwnd, WM_SETICON, ICON_BIG, h_icon)
    except Exception:
        pass


def load_gui_html():
    gui_dir = resource_path('gui')

    with open(os.path.join(gui_dir, 'index.html'), encoding='utf-8') as f:
        html = f.read()
    with open(os.path.join(gui_dir, 'style.css'), encoding='utf-8') as f:
        css = f.read()
    with open(os.path.join(gui_dir, 'app.js'), encoding='utf-8') as f:
        js = f.read()

    html = html.replace(
        '<link rel="stylesheet" href="style.css">',
        f'<style>\n{css}\n</style>',
    )
    html = html.replace(
        '<script src="app.js"></script>',
        f'<script>\n{js}\n</script>',
    )

    icon_uri = get_icon_data_uri() or ''
    html = html.replace('{{ICON_DATA_URI}}', icon_uri)

    return html


def _create_window(api):
    kwargs = dict(
        html=load_gui_html(), js_api=api,
        width=1050, height=720, min_size=(850, 600),
        frameless=True, easy_drag=False,
        resizable=True,
        hidden=True,
        background_color=LOADING_BG,
    )
    if os.path.isfile(ICON_PATH):
        kwargs['icon'] = ICON_PATH

    optional_keys = ('background_color', 'hidden', 'icon', 'resizable', 'easy_drag')
    while True:
        try:
            return webview.create_window('xRManager', **kwargs), kwargs
        except TypeError as e:
            msg = str(e)
            removed = False
            for key in optional_keys:
                if key in kwargs and key in msg:
                    kwargs.pop(key)
                    removed = True
                    break
            if not removed:
                raise


if __name__ == '__main__':
    set_windows_app_id()

    api = Api()
    window, used_kwargs = _create_window(api)

    def _reveal():
        try_set_taskbar_icon(window)
        try:
            window.show()
        except Exception:
            pass

    if used_kwargs.get('hidden'):
        try:
            window.events.loaded += _reveal
        except Exception:
            _reveal()
    else:
        _reveal()

    webview.start(debug=False)
