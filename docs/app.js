// ============================================================================
// DMX CHECK-IN PHÁT TỜ RƠI — PWA CLIENT (Đồng bộ trực tiếp Google Sheet)
// ============================================================================

const DEFAULT_SCRIPT_URL = 'https://script.google.com/macros/s/AKfycbyIVu3UNuqG72zJvF0Pt8RaobieaWNnyXQCGifFXPK5c5A0kjzHB9OL49LKkAAzjG4J_w/exec';

function getScriptUrl() {
  const params = new URLSearchParams(window.location.search);
  const fromQuery = (params.get('api') || '').trim();
  if (fromQuery.startsWith('https://script.google.com/')) {
    localStorage.setItem('dmx_checkin_api_url', fromQuery);
    return fromQuery;
  }
  return localStorage.getItem('dmx_checkin_api_url') || DEFAULT_SCRIPT_URL;
}

const state = {
  group: localStorage.getItem('dmx_checkin_group') || 'PG',
  staff: { pg: [], nv: [] },
  history: [],
  historyFilter: 'all',
  selectedRoute: localStorage.getItem('dmx_checkin_route') || 'Tuyến 1',
  lat: null,
  lng: null,
  accuracy: 0,
  imageBase64: '',
  deferredPrompt: null
};

const el = (id) => document.getElementById(id);

// Đăng ký Service Worker cho PWA
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('./sw.js').catch(() => {});
  });
}

// Phát hiện chế độ PWA để hiện gợi ý cài lên màn hình chính
const isStandalone = window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone === true;
if (!isStandalone) {
  el('installBanner').classList.remove('hidden');
}

window.addEventListener('beforeinstallprompt', (e) => {
  e.preventDefault();
  state.deferredPrompt = e;
  el('btnInstall').textContent = 'Cài ngay';
  el('installBanner').classList.remove('hidden');
});

el('btnInstall').addEventListener('click', async () => {
  if (state.deferredPrompt) {
    state.deferredPrompt.prompt();
    await state.deferredPrompt.userChoice;
    state.deferredPrompt = null;
    el('installBanner').classList.add('hidden');
  } else {
    el('installModal').classList.remove('hidden');
  }
});

el('installCloseBtn').addEventListener('click', () => el('installModal').classList.add('hidden'));
el('installCloseBg').addEventListener('click', () => el('installModal').classList.add('hidden'));
el('modalCloseBtn').addEventListener('click', () => el('imgModal').classList.add('hidden'));
el('modalCloseBg').addEventListener('click', () => el('imgModal').classList.add('hidden'));

// Chuyển tab
document.querySelectorAll('.tab-btn').forEach((btn) => {
  btn.addEventListener('click', () => {
    const target = btn.dataset.tab;
    document.querySelectorAll('.tab-btn').forEach((b) => b.classList.toggle('active', b === btn));
    document.querySelectorAll('.tab-panel').forEach((p) => p.classList.toggle('active', p.id === 'tab-' + target));
  });
});

// Chuyển nhóm PG / NV
function applyGroupUI() {
  document.querySelectorAll('#groupSelector .seg-btn').forEach((b) => {
    b.classList.toggle('active', b.dataset.group === state.group);
  });
  renderStaffDropdown();
}

document.querySelectorAll('#groupSelector .seg-btn').forEach((btn) => {
  btn.addEventListener('click', () => {
    state.group = btn.dataset.group;
    localStorage.setItem('dmx_checkin_group', state.group);
    applyGroupUI();
  });
});

// Chọn tuyến nhanh
document.querySelectorAll('#routeChips .chip').forEach((chip) => {
  if (chip.dataset.route === state.selectedRoute) {
    document.querySelectorAll('#routeChips .chip').forEach((c) => c.classList.remove('active'));
    chip.classList.add('active');
  }
  chip.addEventListener('click', () => {
    document.querySelectorAll('#routeChips .chip').forEach((c) => c.classList.remove('active'));
    chip.classList.add('active');
    state.selectedRoute = chip.dataset.route;
    localStorage.setItem('dmx_checkin_route', state.selectedRoute);
  });
});

// Bộ lọc lịch sử
document.querySelectorAll('#historyFilter .seg-mini-btn').forEach((btn) => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('#historyFilter .seg-mini-btn').forEach((b) => b.classList.toggle('active', b === btn));
    state.historyFilter = btn.dataset.filter;
    renderHistory();
  });
});

function showAlert(msg, type = 'ok') {
  const box = el('alertBox');
  box.className = 'alert-box ' + type;
  box.innerHTML = msg;
  box.classList.remove('hidden');
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function hideAlert() {
  el('alertBox').classList.add('hidden');
}

function getSelectedStaffInfo() {
  const sel = el('staffSelect').value;
  if (sel === '__OTHER__') {
    const custom = el('staffCustom').value.trim();
    return { hoTen: custom, nhom: state.group, boPhan: state.group === 'PG' ? 'PG' : 'NV Siêu thị' };
  }
  const list = state.group === 'PG' ? state.staff.pg : state.staff.nv;
  const found = list.find((x) => x.ten === sel);
  return {
    hoTen: found ? found.ten : sel,
    nhom: state.group,
    boPhan: found ? found.boPhan : ''
  };
}

function renderStaffDropdown() {
  const select = el('staffSelect');
  const list = state.group === 'PG' ? state.staff.pg : state.staff.nv;
  const savedName = localStorage.getItem('dmx_checkin_name_' + state.group) || '';

  select.innerHTML = '';
  const opt0 = document.createElement('option');
  opt0.value = '';
  opt0.textContent = list.length ? `-- Chọn tên ${state.group} (${list.length} người) --` : '-- Nhập tên thủ công bên dưới --';
  select.appendChild(opt0);

  for (const person of list) {
    const opt = document.createElement('option');
    opt.value = person.ten;
    opt.textContent = person.boPhan ? `${person.ten} (${person.boPhan})` : person.ten;
    select.appendChild(opt);
  }

  const optOther = document.createElement('option');
  optOther.value = '__OTHER__';
  optOther.textContent = '✏️ Tên khác (tự nhập tay)...';
  select.appendChild(optOther);

  if (savedName && list.some((x) => x.ten === savedName)) {
    select.value = savedName;
    el('staffCustom').classList.add('hidden');
  } else if (list.length === 0) {
    select.value = '__OTHER__';
    el('staffCustom').classList.remove('hidden');
  } else {
    el('staffCustom').classList.add('hidden');
  }
  updateStaffMeta();
}

function updateStaffMeta() {
  const info = getSelectedStaffInfo();
  if (info.hoTen) {
    el('staffMeta').textContent = `Đang chọn: ${info.hoTen} • ${info.nhom}${info.boPhan ? ' (' + info.boPhan + ')' : ''}`;
  } else {
    el('staffMeta').textContent = '';
  }
}

el('staffSelect').addEventListener('change', () => {
  const val = el('staffSelect').value;
  if (val === '__OTHER__') {
    el('staffCustom').classList.remove('hidden');
    el('staffCustom').focus();
  } else {
    el('staffCustom').classList.add('hidden');
    if (val) localStorage.setItem('dmx_checkin_name_' + state.group, val);
  }
  updateStaffMeta();
  renderHistory();
});

el('staffCustom').addEventListener('input', updateStaffMeta);

// Tải danh sách nhân sự + lịch sử từ Google Sheet Web App
async function loadInitData() {
  el('headerSub').textContent = 'Đang đồng bộ danh sách PG/NV từ Google Sheet...';
  try {
    const res = await fetch(getScriptUrl() + '?action=init&t=' + Date.now(), {
      method: 'GET',
      redirect: 'follow'
    });
    const data = await res.json();
    if (!data || !data.ok) {
      throw new Error((data && data.error) || 'Không đọc được dữ liệu từ Google Sheet');
    }
    state.staff = data.nhanSu || { pg: [], nv: [] };
    state.history = data.lichSu || [];
    el('countPG').textContent = state.staff.pg.length;
    el('countNV').textContent = state.staff.nv.length;
    el('historyCount').textContent = state.history.length;
    el('headerSub').textContent = data.tuanHienTai
      ? `${data.tuanHienTai} • Đã đồng bộ`
      : `Đã kết nối Sheet (${state.staff.pg.length} PG, ${state.staff.nv.length} NV)`;

    applyGroupUI();
    renderHistory();
  } catch (err) {
    el('headerSub').textContent = '⚠️ Chưa kết nối được Apps Script';
    showAlert('⚠️ Không tải được danh sách từ Google Sheet: ' + err.message, 'err');
    renderStaffDropdown();
  }
}

el('btnReload').addEventListener('click', loadInitData);

// Trích xuất tọa độ từ link Google Maps dán tay
function parseCoordsFromText(raw) {
  const txt = decodeURIComponent(raw || '');
  const patterns = [
    /!3d(-?\d{1,2}\.\d{3,})!4d(-?\d{1,3}\.\d{3,})/,
    /[?&](?:q|query|ll|center|destination)=(-?\d{1,2}\.\d{3,})[,\s+]+(-?\d{1,3}\.\d{3,})/,
    /@(-?\d{1,2}\.\d{3,}),(-?\d{1,3}\.\d{3,})/,
    /(-?\d{1,2}\.\d{4,})\s*[,;\s]\s*(-?\d{1,3}\.\d{4,})/
  ];
  for (const re of patterns) {
    const m = txt.match(re);
    if (m) {
      const lat = parseFloat(m[1]);
      const lng = parseFloat(m[2]);
      if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) return { lat, lng };
    }
  }
  return null;
}

function updateGpsUI(lat, lng, acc, customLink) {
  state.lat = lat;
  state.lng = lng;
  state.accuracy = acc || 0;

  const statusEl = el('gpsStatus');
  const linkEl = el('gpsMapLink');
  if (lat !== null && lng !== null) {
    const accText = acc > 0 ? ` (sai số ±${Math.round(acc)}m)` : '';
    statusEl.className = 'status-pill ok mt-8';
    statusEl.textContent = `🟢 Đã lấy GPS: ${lat.toFixed(6)}, ${lng.toFixed(6)}${accText}`;
    const url = `https://www.google.com/maps?q=${lat.toFixed(6)},${lng.toFixed(6)}`;
    linkEl.href = url;
    linkEl.classList.remove('hidden');
  } else if (customLink) {
    statusEl.className = 'status-pill warn mt-8';
    statusEl.textContent = '📍 Đã nhận link Google Maps (sẽ lưu kèm link gốc lên Sheet).';
    linkEl.href = customLink;
    linkEl.classList.remove('hidden');
  }
}

el('btnGetGPS').addEventListener('click', () => {
  hideAlert();
  if (!navigator.geolocation) {
    el('gpsStatus').className = 'status-pill err mt-8';
    el('gpsStatus').textContent = '⚠️ Trình duyệt không hỗ trợ GPS. Hãy dán link vị trí từ Google Maps.';
    return;
  }
  const btn = el('btnGetGPS');
  btn.disabled = true;
  btn.textContent = '⏳ Đang định vị...';
  el('gpsStatus').className = 'status-pill neutral mt-8';
  el('gpsStatus').textContent = '⏳ Đang lấy tọa độ GPS chính xác từ thiết bị...';

  navigator.geolocation.getCurrentPosition(
    (pos) => {
      btn.disabled = false;
      btn.textContent = '📍 Lấy lại GPS';
      const { latitude, longitude, accuracy } = pos.coords;
      el('mapsInput').value = `https://www.google.com/maps?q=${latitude.toFixed(6)},${longitude.toFixed(6)}`;
      updateGpsUI(latitude, longitude, accuracy, '');
    },
    (err) => {
      btn.disabled = false;
      btn.textContent = '📍 Lấy vị trí GPS ngay';
      el('gpsStatus').className = 'status-pill err mt-8';
      el('gpsStatus').textContent =
        err.code === 1
          ? '⚠️ Bạn đã từ chối quyền Vị trí. Hãy bật Định vị cho Safari/Chrome trong Cài đặt hoặc dán link Google Maps.'
          : '⚠️ Chưa bắt được tín hiệu GPS (' + err.message + '). Hãy thử ra ngoài trời hoặc dán link Google Maps.';
    },
    { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 }
  );
});

el('btnPasteMaps').addEventListener('click', async () => {
  try {
    const clip = (await navigator.clipboard.readText()).trim();
    if (!clip) {
      showAlert('Bộ nhớ tạm đang trống. Hãy sao chép link chia sẻ từ Google Maps trước.', 'err');
      return;
    }
    el('mapsInput').value = clip;
    handleMapsInputChange();
  } catch {
    el('mapsInput').focus();
    showAlert('Hãy chạm giữ vào ô Link Google Maps bên dưới rồi bấm Dán.', 'err');
  }
});

function handleMapsInputChange() {
  const val = el('mapsInput').value.trim();
  if (!val) return;
  const parsed = parseCoordsFromText(val);
  if (parsed) {
    updateGpsUI(parsed.lat, parsed.lng, 0, val);
  } else if (val.startsWith('http://') || val.startsWith('https://')) {
    updateGpsUI(null, null, 0, val);
  }
}
el('mapsInput').addEventListener('change', handleMapsInputChange);
el('mapsInput').addEventListener('blur', handleMapsInputChange);

// Nén ảnh & tự đóng dấu Watermark (Họ tên + Thời gian + GPS) chống gian lận
function formatNowVN() {
  const d = new Date();
  const pad = (n) => (n < 10 ? '0' + n : '' + n);
  return `${pad(d.getHours())}:${pad(d.getMinutes())} ${pad(d.getDate())}/${pad(d.getMonth() + 1)}/${d.getFullYear()}`;
}

function processImageFile(file) {
  if (!file) return;
  el('photoMeta').textContent = '⏳ Đang nén ảnh & đóng dấu thời gian/GPS...';

  const reader = new FileReader();
  reader.onload = (ev) => {
    const img = new Image();
    img.onload = () => {
      const maxSide = 1280;
      let w = img.naturalWidth;
      let h = img.naturalHeight;
      if (Math.max(w, h) > maxSide) {
        const ratio = maxSide / Math.max(w, h);
        w = Math.round(w * ratio);
        h = Math.round(h * ratio);
      }
      const canvas = document.createElement('canvas');
      canvas.width = w;
      canvas.height = h;
      const ctx = canvas.getContext('2d');
      ctx.drawImage(img, 0, 0, w, h);

      // Đóng dấu watermark góc dưới
      const info = getSelectedStaffInfo();
      const line1 = `DMX CHECK-IN • ${info.hoTen || 'Nhân sự'} (${info.nhom}) • ${formatNowVN()}`;
      const gpsStr = state.lat !== null && state.lng !== null
        ? `GPS: ${state.lat.toFixed(6)}, ${state.lng.toFixed(6)} • ${state.selectedRoute}`
        : `${state.selectedRoute} • ${el('locationName').value.trim() || 'Minh chứng phát tờ rơi'}`;

      const fontSize = Math.max(18, Math.round(w * 0.025));
      const padX = Math.round(fontSize * 0.8);
      const barH = Math.round(fontSize * 3.1);
      ctx.fillStyle = 'rgba(7, 25, 56, 0.72)';
      ctx.fillRect(0, h - barH, w, barH);
      ctx.fillStyle = '#FFD400';
      ctx.font = `700 ${fontSize}px -apple-system, BlinkMacSystemFont, sans-serif`;
      ctx.fillText(line1, padX, h - barH + Math.round(fontSize * 1.25), w - padX * 2);
      ctx.fillStyle = '#FFFFFF';
      ctx.font = `600 ${Math.round(fontSize * 0.88)}px -apple-system, BlinkMacSystemFont, sans-serif`;
      ctx.fillText(gpsStr, padX, h - Math.round(fontSize * 0.55), w - padX * 2);

      const dataUrl = canvas.toDataURL('image/jpeg', 0.8);
      state.imageBase64 = dataUrl;

      el('photoPreview').src = dataUrl;
      el('photoPreview').classList.remove('hidden');
      el('photoPlaceholder').classList.add('hidden');
      const kb = Math.round((dataUrl.length * 3) / 4 / 1024);
      el('photoMeta').textContent = `✅ Ảnh sẵn sàng (${w}×${h}px • ~${kb} KB • đã đóng dấu thời gian & GPS)`;
    };
    img.src = ev.target.result;
  };
  reader.readAsDataURL(file);
}

el('cameraInput').addEventListener('change', (e) => processImageFile(e.target.files[0]));
el('galleryInput').addEventListener('change', (e) => processImageFile(e.target.files[0]));

// Gửi check-in lên Google Apps Script (text/plain để tránh CORS preflight!)
el('btnSubmit').addEventListener('click', async () => {
  hideAlert();
  const info = getSelectedStaffInfo();
  if (!info.hoTen) {
    showAlert('⚠️ Vui lòng chọn tên nhân sự ở Mục 1 trước khi gửi.', 'err');
    return;
  }
  const mapsUrl = el('mapsInput').value.trim();
  if (state.lat === null && !mapsUrl) {
    showAlert('⚠️ Vui lòng bấm “📍 Lấy vị trí GPS ngay” hoặc dán link Google Maps ở Mục 2.', 'err');
    return;
  }
  if (!state.imageBase64) {
    showAlert('⚠️ Vui lòng chụp hoặc chọn 1 tấm ảnh minh chứng ở Mục 4.', 'err');
    return;
  }

  const btn = el('btnSubmit');
  btn.disabled = true;
  btn.textContent = '⏳ Đang tải ảnh lên Drive & ghi Google Sheet...';

  try {
    const payload = {
      hoTen: info.hoTen,
      nhom: info.nhom,
      boPhan: info.boPhan,
      tuyen: state.selectedRoute,
      diaDiem: el('locationName').value.trim(),
      ghiChu: el('noteInput').value.trim(),
      lat: state.lat,
      lng: state.lng,
      accuracy: state.accuracy,
      googleMapsUrl: mapsUrl,
      imageBase64: state.imageBase64
    };

    const res = await fetch(getScriptUrl(), {
      method: 'POST',
      headers: { 'Content-Type': 'text/plain;charset=utf-8' },
      redirect: 'follow',
      body: JSON.stringify(payload)
    });
    const kq = await res.json();
    if (!kq || !kq.ok) {
      throw new Error((kq && kq.error) || 'Không nhận được xác nhận từ Google Sheet');
    }

    showAlert(
      `✅ <strong>Check-in thành công (#${kq.stt}) lúc ${kq.thoiGian}!</strong><br />` +
      `Đã lưu ảnh lên Google Drive và ghi dòng ${kq.rowNumber} trên tab <strong>BC-Phát tờ rơi</strong>.<br />` +
      `<a href="${kq.linkDrive}" target="_blank" rel="noopener">🖼️ Xem ảnh trên Drive ↗</a> &nbsp;|&nbsp; ` +
      `<a href="${kq.linkMaps}" target="_blank" rel="noopener">🗺️ Mở Google Maps ↗</a>`,
      'ok'
    );

    // Xóa ảnh & ghi chú để sẵn sàng check-in điểm tiếp theo (giữ lại tên nhân sự!)
    state.imageBase64 = '';
    el('photoPreview').src = '';
    el('photoPreview').classList.add('hidden');
    el('photoPlaceholder').classList.remove('hidden');
    el('photoMeta').textContent = '';
    el('locationName').value = '';
    el('noteInput').value = '';
    el('cameraInput').value = '';
    el('galleryInput').value = '';

    await loadInitData();
  } catch (err) {
    showAlert('⚠️ Gửi check-in thất bại: ' + err.message, 'err');
  } finally {
    btn.disabled = false;
    btn.textContent = '✅ GỬI CHECK-IN LÊN GOOGLE SHEET';
  }
});

// Hiển thị danh sách lịch sử check-in từ Google Sheet
function renderHistory() {
  const box = el('historyList');
  const myName = getSelectedStaffInfo().hoTen.toLowerCase();
  const list = state.historyFilter === 'mine' && myName
    ? state.history.filter((x) => (x.hoTen || '').toLowerCase() === myName)
    : state.history;

  if (!list.length) {
    box.innerHTML = '<div class="empty-state">Chưa có lượt check-in nào trong mục này.</div>';
    return;
  }

  box.innerHTML = '';
  for (const item of list) {
    const div = document.createElement('div');
    div.className = 'history-item';

    const img = document.createElement('img');
    img.className = 'history-thumb';
    img.src = item.linkAnh || './icon-192.png';
    img.alt = item.hoTen || 'Ảnh check-in';
    img.loading = 'lazy';
    img.addEventListener('click', () => {
      el('modalTitle').textContent = `${item.hoTen} • ${item.thoiGian}`;
      el('modalImg').src = item.linkAnh || '';
      el('modalDriveLink').href = item.linkDrive || '#';
      el('imgModal').classList.remove('hidden');
    });

    const body = document.createElement('div');
    body.className = 'history-body';
    body.innerHTML =
      `<div class="history-name">#${item.stt} ${escapeHtml(item.hoTen)} <span style="color:#0b4f9e">(${escapeHtml(item.nhom)})</span></div>` +
      `<div class="history-meta">🕒 ${escapeHtml(item.thoiGian)} • 🛣️ ${escapeHtml(item.tuyen)}</div>` +
      `<div>📍 ${escapeHtml(item.diaDiem || item.toaDo)}</div>` +
      (item.ghiChu ? `<div class="history-meta">💬 ${escapeHtml(item.ghiChu)}</div>` : '') +
      `<div class="history-links">` +
      (item.linkMaps ? `<a href="${escapeAttr(item.linkMaps)}" target="_blank" rel="noopener">🗺️ Google Maps ↗</a>` : '') +
      (item.linkDrive ? `<a href="${escapeAttr(item.linkDrive)}" target="_blank" rel="noopener">🖼️ Ảnh Drive ↗</a>` : '') +
      `</div>`;

    div.appendChild(img);
    div.appendChild(body);
    box.appendChild(div);
  }
}

function escapeHtml(s) {
  return String(s || '')
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

function escapeAttr(s) {
  return escapeHtml(s);
}

// Khởi chạy
loadInitData();
