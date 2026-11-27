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
  schedule: null,
  pgWeeks: [],
  pgRegWeekKind: 'current',
  pgRegDraft: ['', '', '', '', '', '', ''],
  teamPGWeekKind: 'current',
  teamDayFilter: 'all',
  teamSearchQuery: '',
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

function normVN(s) {
  return String(s || '')
    .split('(')[0]
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[đĐ]/g, 'd')
    .replace(/\s+/g, ' ')
    .toLowerCase()
    .trim();
}

function selectRouteByName(routeName) {
  if (!routeName) return;
  const chips = Array.from(document.querySelectorAll('#routeChips .chip'));
  let matched = chips.find((c) => normVN(c.dataset.route) === normVN(routeName));
  if (!matched) {
    const m = String(routeName).match(/tuy[eêế]n\s*(\d+)/i);
    if (m) matched = chips.find((c) => c.dataset.route === 'Tuyến ' + m[1]);
  }
  if (matched) {
    chips.forEach((c) => c.classList.remove('active'));
    matched.classList.add('active');
    state.selectedRoute = matched.dataset.route;
    localStorage.setItem('dmx_checkin_route', state.selectedRoute);
  }
}

function renderStaffSchedule(autoPickRoute = false) {
  const box = el('staffScheduleBox');
  if (!box) return;
  const info = getSelectedStaffInfo();
  const tenKey = normVN(info.hoTen);
  if (!tenKey) {
    box.classList.add('hidden');
    box.innerHTML = '';
    return;
  }

  box.classList.remove('hidden');
  const sched = state.schedule;
  if (!sched || !Array.isArray(sched.cacPhanCong) || !sched.cacPhanCong.length) {
    box.innerHTML =
      `<div class="schedule-head">📅 Lịch & Tuyến phát tờ rơi của ${escapeHtml(info.hoTen)}</div>` +
      `<div class="schedule-empty">ℹ️ Quản lý chưa đồng bộ lịch chia tuyến tuần này lên Sheet. Khi quản lý bấm <strong>“⚡ Phân lịch xoay vòng”</strong> hoặc <strong>“☁️ Đồng bộ lịch lên PWA”</strong> trong app ĐMX, tuyến đường &amp; lịch phát riêng của bạn sẽ tự hiển thị tại đây.</div>`;
    return;
  }

  const tuyenMap = {};
  for (const t of (sched.cacTuyen || [])) {
    tuyenMap[String(t.id || '')] = t;
  }

  const mySlots = sched.cacPhanCong.filter((o) => {
    const allNames = [...(o.danhSachPG || []), ...(o.danhSachNV || [])];
    return allNames.some((n) => {
      const k = normVN(n);
      return k && (k === tenKey || k.includes(tenKey) || tenKey.includes(k));
    });
  });

  if (!mySlots.length) {
    box.innerHTML =
      `<div class="schedule-head">📅 Lịch phát tờ rơi (${escapeHtml(sched.tuan || 'Tuần này')})</div>` +
      `<div class="schedule-empty">Tuần này <strong>${escapeHtml(info.hoTen)}</strong> chưa có buổi phân công trong ma trận. Nếu được điều động bổ sung, bạn vẫn có thể chọn tuyến bên dưới để check-in bình thường.</div>`;
    return;
  }

  let html = `<div class="schedule-head">📅 Tuyến &amp; Lịch phát tờ rơi của ${escapeHtml(info.hoTen)} (${mySlots.length} buổi${sched.tuan ? ' • ' + escapeHtml(sched.tuan) : ''})</div>`;
  let firstRouteToPick = '';

  for (const slot of mySlots) {
    const tuyenObj = tuyenMap[String(slot.tuyenId || '')] || {};
    const routeTitle = slot.tenTuyen || tuyenObj.ten || 'Tuyến phát tờ rơi';
    const soTuyenMatch = routeTitle.match(/tuy[eêế]n\s*(\d+)/i);
    const shortRoute = soTuyenMatch ? ('Tuyến ' + soTuyenMatch[1]) : routeTitle;
    if (!firstRouteToPick) firstRouteToPick = shortRoute;

    const myCheckIn = state.history.find((h) => {
      const hKey = normVN(h.hoTen);
      const nameOk = hKey && (hKey === tenKey || hKey.includes(tenKey) || tenKey.includes(hKey));
      if (!nameOk) return false;
      if (!soTuyenMatch) return true;
      const hRouteMatch = String(h.tuyen || '').match(/tuy[eêế]n\s*(\d+)/i);
      return !hRouteMatch || hRouteMatch[1] === soTuyenMatch[1];
    });

    const isDone = Boolean(myCheckIn || slot.daPhat);
    const badgeHtml = myCheckIn
      ? `<span class="schedule-badge done">✅ Đã check-in (${escapeHtml(myCheckIn.thoiGian || '')})</span>`
      : (slot.daPhat ? `<span class="schedule-badge done">✅ Đã hoàn thành</span>` : `<span class="schedule-badge pending">⏳ Chưa check-in</span>`);

    const khungGio = slot.buoi === 'Sáng' ? '07:00–09:00' : '16:30–18:30';
    const km = tuyenObj.tongQuangDuongMet ? (tuyenObj.tongQuangDuongMet >= 1000 ? (tuyenObj.tongQuangDuongMet / 1000).toFixed(2) + ' km' : Math.round(tuyenObj.tongQuangDuongMet) + ' m') : '';
    const timeMeta = [];
    if (km) timeMeta.push('📏 ' + km);
    if (tuyenObj.thoiGianXeMayPhut) timeMeta.push('🛵 ~' + tuyenObj.thoiGianXeMayPhut + ' phút');
    if (tuyenObj.thoiGianDiBoPhut) timeMeta.push('🚶 ~' + tuyenObj.thoiGianDiBoPhut + ' phút');

    const diemList = Array.isArray(tuyenObj.cacDiemMucTieu) && tuyenObj.cacDiemMucTieu.length
      ? tuyenObj.cacDiemMucTieu.map((d, idx) => `${idx + 1}. ${d.ten}`).join(' → ')
      : (slot.moTaTuyen || tuyenObj.moTaDiemNong || '');

    const dongHanh = [...(slot.danhSachPG || []), ...(slot.danhSachNV || [])]
      .filter((n) => normVN(n) !== tenKey)
      .map((n) => n.split('(')[0].trim());

    const stepsHtml = Array.isArray(tuyenObj.chiDanTomTat) && tuyenObj.chiDanTomTat.length
      ? `<div class="schedule-steps"><strong>🧭 Chỉ dẫn đường đi:</strong><br />${tuyenObj.chiDanTomTat.slice(0, 5).map((st) => '• ' + escapeHtml(st)).join('<br />')}</div>`
      : '';

    const firstStopName = (Array.isArray(tuyenObj.cacDiemMucTieu) && tuyenObj.cacDiemMucTieu[0]?.ten) || '';

    html +=
      `<div class="schedule-item">` +
        `<div class="schedule-top">` +
          `<span class="schedule-day">🗓️ ${escapeHtml(slot.thuTen || '')} • ${escapeHtml(slot.buoi || '')} (${khungGio})</span>` +
          badgeHtml +
        `</div>` +
        `<div class="schedule-route">🛣️ ${escapeHtml(routeTitle)}${timeMeta.length ? ' (' + timeMeta.join(' • ') + ')' : ''}</div>` +
        (diemList ? `<div class="schedule-detail">📍 Điểm phát: ${escapeHtml(diemList)}</div>` : '') +
        (dongHanh.length ? `<div class="schedule-detail">👥 Đi cùng: ${escapeHtml(dongHanh.join(', '))}</div>` : '') +
        stepsHtml +
        `<div class="schedule-actions">` +
          (tuyenObj.googleMapsUrl ? `<a class="schedule-btn-map" href="${escapeAttr(tuyenObj.googleMapsUrl)}" target="_blank" rel="noopener">🗺️ Dẫn đường GG Maps ↗</a>` : '') +
          `<button type="button" class="schedule-btn-pick" data-pick-route="${escapeAttr(shortRoute)}" data-pick-stop="${escapeAttr(firstStopName)}">📍 Chọn ${escapeHtml(shortRoute)} check-in</button>` +
        `</div>` +
      `</div>`;
  }

  box.innerHTML = html;
  box.querySelectorAll('.schedule-btn-pick').forEach((btn) => {
    btn.addEventListener('click', () => {
      const rName = btn.dataset.pickRoute;
      const stopName = btn.dataset.pickStop;
      selectRouteByName(rName);
      if (stopName && !el('locationName').value.trim()) {
        el('locationName').value = stopName;
      }
      el('locationName').scrollIntoView({ behavior: 'smooth', block: 'center' });
    });
  });

  if (autoPickRoute && firstRouteToPick) {
    selectRouteByName(firstRouteToPick);
  }
}

function updateStaffMeta() {
  const info = getSelectedStaffInfo();
  if (info.hoTen) {
    el('staffMeta').textContent = `Đang chọn: ${info.hoTen} • ${info.nhom}${info.boPhan ? ' (' + info.boPhan + ')' : ''}`;
  } else {
    el('staffMeta').textContent = '';
  }
  renderStaffSchedule(true);
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
    state.schedule = data.lichPhanCong || null;
    state.pgWeeks = Array.isArray(data.pgHaiTuan) ? data.pgHaiTuan : [];
    el('countPG').textContent = state.staff.pg.length;
    el('countNV').textContent = state.staff.nv.length;
    el('historyCount').textContent = state.history.length;
    el('headerSub').textContent = data.tuanHienTai
      ? `${data.tuanHienTai} • Đã đồng bộ`
      : `Đã kết nối Sheet (${state.staff.pg.length} PG, ${state.staff.nv.length} NV)`;

    applyGroupUI();
    renderHistory();
    renderPGRegSection();
    renderTeamSchedule();
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

// ============================================================================
// TAB 2: ĐĂNG KÝ CA LÀM VIỆC CHO PG (TUẦN HIỆN TẠI / TUẦN TIẾP THEO)
// ============================================================================

const PG_SHIFT_OPTIONS = [
  { val: 'SÁNG', label: 'SÁNG', gio: '8h-16h', cls: 'sh-sang' },
  { val: 'CHIỀU', label: 'CHIỀU', gio: '15h-20h', cls: 'sh-chieu' },
  { val: 'GÃY ( SÁNG VS CHIỀU)', label: 'GÃY', gio: '8h-20h', cls: 'sh-gay' },
  { val: 'OFF', label: 'OFF', gio: 'Nghỉ', cls: 'sh-off' },
  { val: 'ST #', label: 'ST #', gio: 'ST khác', cls: 'sh-st' }
];

function getPGWeekObj(kind) {
  return state.pgWeeks.find((w) => w.kind === kind) || state.pgWeeks[0] || null;
}

function showPGRegAlert(msg, type = 'ok') {
  const box = el('pgRegAlert');
  if (!box) return;
  box.className = 'alert-box ' + type;
  box.innerHTML = msg;
  box.classList.remove('hidden');
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function normalizePGShiftVal(raw) {
  const up = String(raw || '').trim().toUpperCase();
  if (!up) return '';
  if (up === 'SÁNG' || up === 'SANG') return 'SÁNG';
  if (up === 'CHIỀU' || up === 'CHIEU') return 'CHIỀU';
  if (up.indexOf('GÃY') !== -1 || up.indexOf('GAY') !== -1) return 'GÃY ( SÁNG VS CHIỀU)';
  if (up === 'OFF') return 'OFF';
  if (up.indexOf('ST') === 0) return 'ST #';
  return raw;
}

function renderPGRegSection() {
  const sel = el('pgRegSelect');
  if (!sel) return;

  // Cập nhật tên nút chọn 2 tuần
  const wCur = getPGWeekObj('current');
  const wNext = getPGWeekObj('next');
  document.querySelectorAll('#pgWeekSelector .seg-btn').forEach((btn) => {
    const k = btn.dataset.week;
    btn.classList.toggle('active', k === state.pgRegWeekKind);
    if (k === 'current' && wCur) btn.textContent = `📍 Tuần hiện tại (${wCur.khoangNgay})`;
    if (k === 'next' && wNext) btn.textContent = `⏭️ Tuần tiếp theo (${wNext.khoangNgay})`;
  });

  const activeWeek = getPGWeekObj(state.pgRegWeekKind);
  el('pgWeekInfo').textContent = activeWeek
    ? `Đang chọn: ${activeWeek.label}`
    : 'Chưa có dữ liệu 2 tuần PG từ Apps Script (bấm 🔄 đồng bộ lại).';

  // Đổ danh sách 21 PG
  const prevVal = sel.value || localStorage.getItem('dmx_pg_reg_name') || localStorage.getItem('dmx_checkin_name_PG') || '';
  const listPG = (activeWeek && activeWeek.rows && activeWeek.rows.length)
    ? activeWeek.rows.map((r) => ({ ten: r.ten, boPhan: r.nganh }))
    : state.staff.pg;

  sel.innerHTML = '';
  const opt0 = document.createElement('option');
  opt0.value = '';
  opt0.textContent = listPG.length ? `-- Chọn tên PG (${listPG.length} người) --` : '-- Đang tải danh sách PG... --';
  sel.appendChild(opt0);

  for (const p of listPG) {
    const opt = document.createElement('option');
    opt.value = p.ten;
    opt.textContent = p.boPhan ? `${p.ten} (${p.boPhan})` : p.ten;
    sel.appendChild(opt);
  }
  if (prevVal && listPG.some((x) => x.ten === prevVal)) {
    sel.value = prevVal;
  }

  loadPGDraftFromSheet();
}

function loadPGDraftFromSheet() {
  const ten = el('pgRegSelect')?.value || '';
  const weekObj = getPGWeekObj(state.pgRegWeekKind);
  if (!ten || !weekObj) {
    state.pgRegDraft = ['', '', '', '', '', '', ''];
    renderPGDaysList();
    return;
  }
  const row = (weekObj.rows || []).find((r) => normVN(r.ten) === normVN(ten));
  if (row && Array.isArray(row.days) && row.days.length === 7) {
    state.pgRegDraft = row.days.map((d) => normalizePGShiftVal(d.ca));
  } else {
    state.pgRegDraft = ['', '', '', '', '', '', ''];
  }
  renderPGDaysList();
}

function renderPGDaysList() {
  const container = el('pgDaysList');
  const summaryEl = el('pgRegSummary');
  if (!container || !summaryEl) return;

  const ten = el('pgRegSelect')?.value || '';
  const weekObj = getPGWeekObj(state.pgRegWeekKind);

  if (!weekObj) {
    container.innerHTML = '<div class="empty-state">Chưa đồng bộ được lịch tuần PG từ Google Sheet.</div>';
    return;
  }
  if (!ten) {
    summaryEl.className = 'status-pill neutral';
    summaryEl.textContent = '👆 Chọn tên PG ở Mục 2 để xem ca hiện có và đăng ký cho 7 ngày.';
    container.innerHTML = '';
    return;
  }

  // Thống kê nhanh 7 ngày đang chọn
  let cSang = 0, cChieu = 0, cGay = 0, cOff = 0, cSt = 0, cTrong = 0;
  for (const v of state.pgRegDraft) {
    if (v === 'SÁNG') cSang++;
    else if (v === 'CHIỀU') cChieu++;
    else if (v === 'GÃY ( SÁNG VS CHIỀU)') cGay++;
    else if (v === 'OFF') cOff++;
    else if (v === 'ST #') cSt++;
    else cTrong++;
  }
  const tongLam = cSang + cChieu + cGay;
  summaryEl.className = cTrong === 0 ? 'status-pill ok' : 'status-pill warn';
  summaryEl.textContent = `📊 ${ten}: ${tongLam} ngày làm (${cSang} Sáng, ${cChieu} Chiều, ${cGay} Gãy) • ${cOff} OFF${cSt ? ' • ' + cSt + ' ST #' : ''}${cTrong ? ' • Còn ' + cTrong + ' ngày chưa chọn' : ' • Đủ 7/7 ngày'}`;

  container.innerHTML = '';
  const headers = weekObj.ngayHeaders || [];
  for (let d = 0; d < 7; d++) {
    const h = headers[d] || { thuDai: 'Ngày ' + (d + 1), ngay: '' };
    const curVal = state.pgRegDraft[d] || '';
    const optObj = PG_SHIFT_OPTIONS.find((o) => o.val === curVal);

    const card = document.createElement('div');
    card.className = 'pg-day-card';
    card.innerHTML =
      `<div class="pg-day-head">` +
        `<span>${escapeHtml(h.thuDai)} (${escapeHtml(h.ngay)})</span>` +
        `<span class="pg-day-time">${optObj ? escapeHtml(optObj.label + ' • ' + optObj.gio) : 'Chưa chọn'}</span>` +
      `</div>` +
      `<div class="pg-shift-btns"></div>`;

    const btnWrap = card.querySelector('.pg-shift-btns');
    for (const opt of PG_SHIFT_OPTIONS) {
      const b = document.createElement('button');
      b.type = 'button';
      b.className = 'pg-shift-btn ' + opt.cls + (curVal === opt.val ? ' active' : '');
      b.textContent = opt.label;
      b.addEventListener('click', () => {
        state.pgRegDraft[d] = (state.pgRegDraft[d] === opt.val) ? '' : opt.val;
        renderPGDaysList();
      });
      btnWrap.appendChild(b);
    }
    container.appendChild(card);
  }
}

document.querySelectorAll('#pgWeekSelector .seg-btn').forEach((btn) => {
  btn.addEventListener('click', () => {
    state.pgRegWeekKind = btn.dataset.week;
    el('pgRegAlert')?.classList.add('hidden');
    renderPGRegSection();
  });
});

el('pgRegSelect')?.addEventListener('change', () => {
  const val = el('pgRegSelect').value;
  if (val) localStorage.setItem('dmx_pg_reg_name', val);
  el('pgRegAlert')?.classList.add('hidden');
  loadPGDraftFromSheet();
});

el('btnCopyPrevWeekPG')?.addEventListener('click', () => {
  const ten = el('pgRegSelect')?.value || '';
  if (!ten) {
    showPGRegAlert('⚠️ Vui lòng chọn tên PG trước khi sao chép.', 'err');
    return;
  }
  const otherKind = state.pgRegWeekKind === 'current' ? 'next' : 'current';
  const otherWeek = getPGWeekObj(otherKind);
  const row = otherWeek && (otherWeek.rows || []).find((r) => normVN(r.ten) === normVN(ten));
  if (!row || !row.days || !row.days.some((d) => d.ca)) {
    showPGRegAlert('⚠️ Tuần còn lại chưa có lịch của ' + escapeHtml(ten) + ' để sao chép.', 'err');
    return;
  }
  state.pgRegDraft = row.days.map((d) => normalizePGShiftVal(d.ca));
  renderPGDaysList();
  showPGRegAlert(`📋 Đã sao chép lịch 7 ngày của <strong>${escapeHtml(ten)}</strong> từ ${escapeHtml(otherWeek.badge)}. Bấm <strong>LƯU ĐĂNG KÝ CA</strong> để ghi lên Sheet!`, 'ok');
});

el('btnClearPGWeek')?.addEventListener('click', () => {
  state.pgRegDraft = ['', '', '', '', '', '', ''];
  renderPGDaysList();
});

el('btnSavePGShift')?.addEventListener('click', async () => {
  el('pgRegAlert')?.classList.add('hidden');
  const ten = el('pgRegSelect')?.value || '';
  const weekObj = getPGWeekObj(state.pgRegWeekKind);
  if (!ten) {
    showPGRegAlert('⚠️ Vui lòng chọn tên PG ở Mục 2 trước khi lưu.', 'err');
    return;
  }
  if (!weekObj) {
    showPGRegAlert('⚠️ Chưa tải được thông tin tuần từ Google Sheet. Bấm 🔄 ở góc trên phải để tải lại.', 'err');
    return;
  }

  const btn = el('btnSavePGShift');
  btn.disabled = true;
  btn.textContent = '⏳ Đang lưu lịch ca lên Google Sheet...';

  try {
    const res = await fetch(getScriptUrl(), {
      method: 'POST',
      headers: { 'Content-Type': 'text/plain;charset=utf-8' },
      redirect: 'follow',
      body: JSON.stringify({
        action: 'registerPGShift',
        weekKey: weekObj.weekKey,
        hoTen: ten,
        shifts: state.pgRegDraft
      })
    });
    const kq = await res.json();
    if (!kq || !kq.ok) {
      throw new Error((kq && kq.error) || 'Không lưu được lịch đăng ký.');
    }
    if (Array.isArray(kq.pgHaiTuan)) {
      state.pgWeeks = kq.pgHaiTuan;
    }
    renderPGRegSection();
    renderTeamSchedule();
    showPGRegAlert(
      `✅ <strong>Đã lưu lịch làm việc cho ${escapeHtml(ten)}!</strong><br />` +
      `Tuần ${escapeHtml(kq.tuan)} • ${escapeHtml(kq.thangNam)} (${escapeHtml(kq.khoangNgay)}) — cập nhật lúc ${escapeHtml(kq.capNhatLuc)}.`,
      'ok'
    );
  } catch (err) {
    showPGRegAlert('⚠️ Lưu thất bại: ' + escapeHtml(err.message), 'err');
  } finally {
    btn.disabled = false;
    btn.textContent = '✅ LƯU ĐĂNG KÝ CA LÊN GOOGLE SHEET';
  }
});

// ============================================================================
// TAB 3: XEM LỊCH LÀM VIỆC TỔNG 21 PG (CHỈ HIỂN THỊ PG, KHÔNG HIỂN THỊ LỊCH NV)
// ============================================================================

function pillInfoForPG(day) {
  const ca = normalizePGShiftVal(day && day.ca);
  if (!ca) return { text: '—', gio: '', cls: 'sp-off', sang: false, chieu: false, off: true };
  if (ca === 'SÁNG') return { text: 'SÁNG', gio: day.gio || '8h-16h', cls: 'sp-sang', sang: true, chieu: false, off: false };
  if (ca === 'CHIỀU') return { text: 'CHIỀU', gio: day.gio || '15h-20h', cls: 'sp-chieu', sang: false, chieu: true, off: false };
  if (ca === 'GÃY ( SÁNG VS CHIỀU)') return { text: 'GÃY', gio: day.gio || '8h-20h', cls: 'sp-full', sang: true, chieu: true, off: false };
  if (ca === 'OFF') return { text: 'OFF', gio: '', cls: 'sp-off', sang: false, chieu: false, off: true };
  if (ca === 'ST #') return { text: 'ST #', gio: day.gio || 'ST khác', cls: 'sp-st', sang: false, chieu: false, off: true };
  return { text: ca, gio: day.gio || '', cls: 'sp-sang', sang: false, chieu: false, off: false };
}

function renderTeamSchedule() {
  const box = el('teamScheduleContent');
  const labelEl = el('teamWeekLabel');
  const hcEl = el('teamHeadcount');
  if (!box || !labelEl || !hcEl) return;

  const wCur = getPGWeekObj('current');
  const wNext = getPGWeekObj('next');
  document.querySelectorAll('#teamPGWeekBar .seg-btn').forEach((b) => {
    const k = b.dataset.tweek;
    b.classList.toggle('active', k === state.teamPGWeekKind);
    if (k === 'current' && wCur) b.textContent = `📍 Tuần hiện tại (${wCur.khoangNgay})`;
    if (k === 'next' && wNext) b.textContent = `⏭️ Tuần tiếp theo (${wNext.khoangNgay})`;
  });

  const q = normVN(state.teamSearchQuery);
  const wk = getPGWeekObj(state.teamPGWeekKind);
  if (!wk || !Array.isArray(wk.rows) || !wk.rows.length) {
    labelEl.textContent = 'Chưa tải được lịch 21 PG.';
    hcEl.classList.add('hidden');
    box.innerHTML = '<div class="empty-state">Bấm nút 🔄 ở góc trên phải để đồng bộ lịch 21 PG.</div>';
    return;
  }

  const headers = (wk.ngayHeaders || []).map((h) => `${h.thu} (${h.ngay})`);
  updateTeamDayChipLabels(headers);
  labelEl.textContent = `📅 Lịch tổng ${wk.rows.length} PG • ${wk.label}`;

  // Thống kê quân số Sáng / Tối mỗi ngày (đối chiếu min 10 bạn mỗi sáng & tối trên sheet PG)
  hcEl.classList.remove('hidden');
  hcEl.innerHTML = (wk.ngayHeaders || []).map((h, dIdx) => {
    let s = 0, t = 0;
    for (const r of wk.rows) {
      const info = pillInfoForPG(r.days[dIdx]);
      if (info.sang) s++;
      if (info.chieu) t++;
    }
    const clsS = s >= 10 ? 'hc-ok' : 'hc-warn';
    const clsT = t >= 10 ? 'hc-ok' : 'hc-warn';
    return `<div class="hc-cell"><div class="hc-day">${escapeHtml(h.thu)}</div><div class="${clsS}">S:${s}</div><div class="${clsT}">T:${t}</div></div>`;
  }).join('');

  const filtered = wk.rows.filter((r) => !q || normVN(r.ten).includes(q) || normVN(r.nganh).includes(q));
  if (!filtered.length) {
    box.innerHTML = '<div class="empty-state">Không tìm thấy PG khớp từ khóa.</div>';
    return;
  }

  if (state.teamDayFilter === 'all') {
    let html = '<div class="matrix-wrap"><table class="matrix-table"><thead><tr><th class="sticky-col">PG (' + filtered.length + ')</th>';
    for (const h of headers) html += `<th>${escapeHtml(h)}</th>`;
    html += '</tr></thead><tbody>';
    for (let i = 0; i < filtered.length; i++) {
      const r = filtered[i];
      html += `<tr><td class="sticky-col"><div class="staff-cell-name">${i + 1}. ${escapeHtml(r.ten)}</div><div class="staff-cell-dept">${escapeHtml(r.nganh)}</div></td>`;
      for (let d = 0; d < 7; d++) {
        const info = pillInfoForPG(r.days[d]);
        html += `<td><span class="shift-pill ${info.cls}">${escapeHtml(info.text)}</span>${info.gio ? `<span class="shift-subtime">${escapeHtml(info.gio)}</span>` : ''}</td>`;
      }
      html += '</tr>';
    }
    html += '</tbody></table></div>';
    box.innerHTML = html;
  } else {
    const dIdx = parseInt(state.teamDayFilter, 10);
    const sorted = filtered.slice().sort((a, b) => Number(pillInfoForPG(a.days[dIdx]).off) - Number(pillInfoForPG(b.days[dIdx]).off));
    let html = '<div class="day-card-list">';
    for (let i = 0; i < sorted.length; i++) {
      const r = sorted[i];
      const info = pillInfoForPG(r.days[dIdx]);
      html +=
        `<div class="day-staff-row">` +
          `<div class="day-staff-left"><div class="staff-cell-name">${i + 1}. ${escapeHtml(r.ten)}</div><div class="staff-cell-dept">${escapeHtml(r.nganh)}</div></div>` +
          `<div class="day-staff-right"><span class="shift-pill ${info.cls}">${escapeHtml(info.text)}</span>${info.gio ? `<span class="shift-subtime">${escapeHtml(info.gio)}</span>` : ''}</div>` +
        `</div>`;
    }
    html += '</div>';
    box.innerHTML = html;
  }
}

function updateTeamDayChipLabels(headers) {
  document.querySelectorAll('#teamDayChips .chip').forEach((chip) => {
    const d = chip.dataset.day;
    if (d === 'all') return;
    const idx = parseInt(d, 10);
    if (headers[idx]) chip.textContent = headers[idx];
  });
}

document.querySelectorAll('#teamPGWeekBar .seg-btn').forEach((btn) => {
  btn.addEventListener('click', () => {
    state.teamPGWeekKind = btn.dataset.tweek;
    renderTeamSchedule();
  });
});

document.querySelectorAll('#teamDayChips .chip').forEach((chip) => {
  chip.addEventListener('click', () => {
    document.querySelectorAll('#teamDayChips .chip').forEach((c) => c.classList.remove('active'));
    chip.classList.add('active');
    state.teamDayFilter = chip.dataset.day;
    renderTeamSchedule();
  });
});

el('teamSearch')?.addEventListener('input', (e) => {
  state.teamSearchQuery = e.target.value || '';
  renderTeamSchedule();
});

// Khởi chạy
loadInitData();
