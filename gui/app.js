function $(sel) { return document.querySelector(sel); }
function $all(sel) { return document.querySelectorAll(sel); }

let api;

(function initTitlebarIcon() {
  const img = document.getElementById('app-icon-img');
  const dot = document.getElementById('app-dot');
  if (img && img.getAttribute('src')) {
    img.classList.remove('hidden');
    if (dot) dot.style.display = 'none';
  }
})();

function hideLoadingScreen() {
  const ls = document.getElementById('loading-screen');
  if (!ls) return;
  ls.classList.add('hidden');
  setTimeout(() => ls.remove(), 300);
}

window.addEventListener('pywebviewready', async () => {
  api = window.pywebview.api;
  await Promise.all([loadBans(), loadProfiles()]);
  hideLoadingScreen();
});

const TAB_ORDER = ['bans', 'profiles'];
const TAB_SHIFT = 20;

function switchTab(targetName, btn) {
  const current = document.querySelector('.tab-content.active');
  const target = document.getElementById('tab-' + targetName);
  if (!target || target === current) return;

  $all('.tab-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');

  const curName = current ? current.id.replace('tab-', '') : null;
  const forward = TAB_ORDER.indexOf(targetName) > TAB_ORDER.indexOf(curName);

  // Новая вкладка появляется, влетая с нужной стороны
  target.style.transition = 'none';
  target.style.display = 'block';
  target.style.opacity = '0';
  target.style.transform = `translateX(${forward ? TAB_SHIFT : -TAB_SHIFT}px)`;
  void target.offsetWidth;

  target.style.transition = 'opacity .2s ease, transform .2s ease';
  requestAnimationFrame(() => {
    target.classList.add('active');
    target.style.opacity = '1';
    target.style.transform = 'translateX(0)';
  });
  
  if (current) {
    current.classList.remove('active');
    current.style.transition = 'opacity .18s ease, transform .18s ease';
    current.style.opacity = '0';
    current.style.transform = `translateX(${forward ? -TAB_SHIFT : TAB_SHIFT}px)`;
    setTimeout(() => {
      current.style.display = 'none';
      current.style.transition = '';
      current.style.transform = '';
      current.style.opacity = '';
    }, 190);
  }
}

$all('.tab-btn').forEach(btn => {
  btn.addEventListener('click', () => switchTab(btn.dataset.tab, btn));
});

(function initResize() {
  let dir = null, startX, startY, startW, startH;
  let queued = false, pendingW, pendingH;

  function apply() {
    if (!queued) {
      queued = true;
      requestAnimationFrame(() => {
        api.window_resize(pendingW, pendingH);
        queued = false;
      });
    }
  }

  $all('.resize-handle').forEach(h => {
    h.addEventListener('mousedown', e => {
      dir = h.dataset.dir;
      startX = e.screenX;
      startY = e.screenY;
      startW = window.innerWidth;
      startH = window.innerHeight;
      document.body.style.userSelect = 'none';
      e.preventDefault();
    });
  });

  window.addEventListener('mousemove', e => {
    if (!dir) return;
    let w = startW, h = startH;
    if (dir.includes('e')) w = Math.max(850, startW + (e.screenX - startX));
    if (dir.includes('s')) h = Math.max(600, startH + (e.screenY - startY));
    pendingW = Math.round(w);
    pendingH = Math.round(h);
    apply();
  });

  window.addEventListener('mouseup', () => {
    dir = null;
    document.body.style.userSelect = '';
  });
})();

$('#btn-win-min').addEventListener('click', () => api.window_minimize());
$('#btn-win-max').addEventListener('click', () => api.window_toggle_max());
$('#btn-win-close').addEventListener('click', () => api.window_close());

function fileIcon(name) {
  const ext = (name.split('.').pop() || '').toLowerCase();
  const video = ['mp4', 'mkv', 'avi', 'webm', 'mov'];
  const image = ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'];
  if (video.includes(ext)) return '🎬';
  if (image.includes(ext)) return '🖼️';
  return '📄';
}

function isImage(name) {
  const ext = (name.split('.').pop() || '').toLowerCase();
  return ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'].includes(ext);
}

async function openDocPreview(docPath, docName) {
  const body = $('#preview-body');
  body.innerHTML = '<div class="empty">Загрузка...</div>';
  $('#modal-preview').classList.remove('hidden');

  const res = await api.get_doc_preview(docPath);

  if (!res.ok) {
    body.innerHTML = `<div class="empty">Не удалось загрузить файл: ${escapeHtml(res.error || '')}</div>`;
    return;
  }
  if (res.kind === 'image') {
    body.innerHTML = `<img src="${res.data_uri}" alt="${escapeHtml(docName)}">`;
  } else if (res.kind === 'video') {
    body.innerHTML = `<video src="${res.data_uri}" controls autoplay></video>`;
  } else if (res.kind === 'video-too-large') {
    body.innerHTML = '<div class="empty">Видео слишком большое для предпросмотра.<br>Нажмите «Файл» в карточке, чтобы открыть его в плеере.</div>';
  } else {
    body.innerHTML = '<div class="empty">Предпросмотр недоступен для этого типа файла.</div>';
  }
}

$('#btn-close-preview').addEventListener('click', () => {
  $('#preview-body').innerHTML = '';
  $('#modal-preview').classList.add('hidden');
});

function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str ?? '';
  return div.innerHTML;
}

async function loadBans(query) {
  const list = query ? await api.search_bans(query) : await api.list_bans();
  const el = $('#bans-list');
  el.innerHTML = '';

  if (!list.length) {
    el.innerHTML = '<div class="empty">Ничего не найдено</div>';
    return;
  }

  list.forEach(b => {
    const card = document.createElement('div');
    card.className = 'card';
    const dateOnly = (b.timestamp || '').split('_')[0];
    const docRow = b.doc
      ? `<div class="doc-row" data-preview="${b.doc_path}" data-preview-name="${escapeHtml(b.doc)}" title="${escapeHtml(b.doc)} (клик — предпросмотр)">
           <span class="doc-icon">${fileIcon(b.doc)}</span>
           <span class="doc-name">${escapeHtml(b.doc)}</span>
         </div>`
      : `<div class="doc-row empty-doc">Без доказательств</div>`;

    card.innerHTML = `
      <div class="card-top">
        <div>
          <div class="field-label">Steam ID</div>
          <span class="mono steamid" title="${escapeHtml(b.steam64)}">${escapeHtml(b.steam64)}</span>
        </div>
        <div>
          <div class="field-label">Дата</div>
          <span class="date">${escapeHtml(dateOnly)}</span>
        </div>
      </div>
      <div class="field-label">Причина</div>
      <div class="reason" title="${escapeHtml(b.reason)}">${escapeHtml(b.reason)}</div>
      <div class="field-label">Доки</div>
      ${docRow}
      <div class="card-actions">
        ${b.doc_path ? `<button class="btn small" data-open="${b.doc_path}">Файл</button>` : ''}
        <button class="btn small" data-open="${b.path}">Папка</button>
        <button class="btn small danger" data-del="${b.path}">✕</button>
      </div>`;
    el.appendChild(card);

    if (b.doc && b.doc_path && isImage(b.doc)) {
      api.get_doc_preview(b.doc_path).then(res => {
        if (res.ok && res.kind === 'image') {
          const iconEl = card.querySelector('.doc-icon');
          if (iconEl) iconEl.outerHTML = `<img class="doc-thumb-icon" src="${res.data_uri}">`;
        }
      });
    }
  });

  el.querySelectorAll('[data-preview]').forEach(row =>
    row.addEventListener('click', () => openDocPreview(row.dataset.preview, row.dataset.previewName)));

  el.querySelectorAll('[data-open]').forEach(btn =>
    btn.addEventListener('click', () => api.open_folder(btn.dataset.open)));

  el.querySelectorAll('[data-del]').forEach(btn =>
    btn.addEventListener('click', async () => {
      if (confirm('Удалить эту запись бана?')) {
        await api.delete_ban(btn.dataset.del);
        loadBans($('#ban-search').value);
      }
    }));
}

$('#ban-search').addEventListener('input', e => loadBans(e.target.value));

$('#btn-add-ban').addEventListener('click', () => {
  $('#ban-steam64').value = '';
  $('#ban-reason').value = '';
  $('#ban-doc-path').value = '';
  $('#ban-error').textContent = '';
  $('#modal-ban').classList.remove('hidden');
});

$('#btn-cancel-ban').addEventListener('click', () => $('#modal-ban').classList.add('hidden'));

$('#btn-pick-doc').addEventListener('click', async () => {
  const path = await api.pick_file();
  if (path) $('#ban-doc-path').value = path;
});

$('#btn-save-ban').addEventListener('click', async () => {
  const steam64 = $('#ban-steam64').value.trim();
  const reason = $('#ban-reason').value.trim();
  const doc = $('#ban-doc-path').value.trim();

  const res = await api.add_ban(steam64, reason, doc);
  if (!res.ok) {
    $('#ban-error').textContent = res.error;
    return;
  }
  $('#modal-ban').classList.add('hidden');
  loadBans($('#ban-search').value);
});

let currentProfiles = [];
let currentNoteSteam = null;

async function loadProfiles(query) {
  let list = await api.list_profiles();
  currentProfiles = list;

  if (query) {
    const q = query.toLowerCase();
    list = list.filter(p => {
      const inTags = (p.tags || []).some(t => t.toLowerCase().includes(q));
      return p.steam64.includes(q) ||
        (p.nickname || '').toLowerCase().includes(q) ||
        (p.note || '').toLowerCase().includes(q) ||
        inTags;
    });
  }

  const el = $('#profiles-list');
  el.innerHTML = '';

  if (!list.length) {
    el.innerHTML = '<div class="empty">Профилей нет</div>';
    return;
  }

  list.forEach(p => {
    const oldNames = (p.old_names || []).filter(n => n && n !== p.nickname);
    const tags = p.tags || [];
    const card = document.createElement('div');
    card.className = 'profile-card';
    card.innerHTML = `
      <img class="avatar" src="${p.avatar || ''}" onerror="this.style.visibility='hidden'">
      <div class="profile-info">
        <div class="nickname">${escapeHtml(p.nickname || '—')}</div>
        <div class="mono small">${escapeHtml(p.steam64)}</div>
        <button class="btn small note-btn" data-note="${p.steam64}">📝 Заметка</button>
        ${p.note ? `<div class="note-preview" title="${escapeHtml(p.note)}">${escapeHtml(p.note)}</div>` : ''}
        ${oldNames.length ? `<div class="old-names">Прошлые ники: ${oldNames.map(escapeHtml).join(', ')}</div>` : ''}
        <div class="tags-row">
          ${tags.map(t => `<span class="tag-chip">${escapeHtml(t)} <span class="tag-remove" data-tag-remove="${escapeHtml(t)}" data-steam="${p.steam64}">×</span></span>`).join('')}
          <button class="tag-add-btn" data-tag-add="${p.steam64}">+ тег</button>
        </div>
        <div class="profile-actions">
          <button class="btn small" data-refresh="${p.steam64}">Обновить</button>
          <button class="btn small danger" data-delp="${p.steam64}">Удалить</button>
        </div>
      </div>`;
    el.appendChild(card);
  });

  el.querySelectorAll('[data-note]').forEach(btn =>
    btn.addEventListener('click', () => {
      currentNoteSteam = btn.dataset.note;
      const p = currentProfiles.find(x => x.steam64 === currentNoteSteam);
      $('#note-steamid').textContent = currentNoteSteam;
      $('#note-text').value = (p && p.note) || '';
      $('#modal-note').classList.remove('hidden');
    }));

  el.querySelectorAll('[data-tag-add]').forEach(btn =>
    btn.addEventListener('click', async () => {
      const steam64 = btn.dataset.tagAdd;
      const tag = prompt('Введите тег (например 4.1 или Читер):');
      if (!tag) return;
      await api.add_profile_tag(steam64, tag);
      loadProfiles($('#profile-search').value);
    }));

  el.querySelectorAll('[data-tag-remove]').forEach(btn =>
    btn.addEventListener('click', async () => {
      await api.remove_profile_tag(btn.dataset.steam, btn.dataset.tagRemove);
      loadProfiles($('#profile-search').value);
    }));

  el.querySelectorAll('[data-refresh]').forEach(btn =>
    btn.addEventListener('click', async () => {
      btn.textContent = '...';
      await api.refresh_profile(btn.dataset.refresh);
      loadProfiles($('#profile-search').value);
    }));

  el.querySelectorAll('[data-delp]').forEach(btn =>
    btn.addEventListener('click', async () => {
      if (confirm('Удалить этот профиль?')) {
        await api.delete_profile(btn.dataset.delp);
        loadProfiles($('#profile-search').value);
      }
    }));
}

$('#btn-cancel-note').addEventListener('click', () => $('#modal-note').classList.add('hidden'));

$('#btn-save-note').addEventListener('click', async () => {
  await api.set_profile_note(currentNoteSteam, $('#note-text').value);
  $('#modal-note').classList.add('hidden');
  loadProfiles($('#profile-search').value);
});

$('#profile-search').addEventListener('input', e => loadProfiles(e.target.value));

$('#btn-add-profile').addEventListener('click', () => {
  $('#profile-steam64').value = '';
  $('#profile-error').textContent = '';
  $('#modal-profile').classList.remove('hidden');
});

$('#btn-cancel-profile').addEventListener('click', () => $('#modal-profile').classList.add('hidden'));

$('#btn-save-profile').addEventListener('click', async () => {
  const steam64 = $('#profile-steam64').value.trim();
  const btn = $('#btn-save-profile');
  btn.textContent = 'Загрузка...';
  btn.disabled = true;

  const res = await api.add_profile(steam64);

  btn.textContent = 'Добавить';
  btn.disabled = false;

  if (!res.ok) {
    $('#profile-error').textContent = res.error;
    return;
  }
  $('#modal-profile').classList.add('hidden');
  loadProfiles();
});
