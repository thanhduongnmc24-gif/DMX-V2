// ============================================================================
// DMX-V2 — GOOGLE APPS SCRIPT TỔNG HỢP (V4):
// 1. Lưu & nạp dữ liệu RIÊNG BIỆT cho từng Tuần / Tháng trên sheet "PG"
//    qua kho ẩn "Data_PG" (chuyển tuần/tháng nào lưu & sửa đúng tuần đó!)
// 2. Tối ưu tốc độ chuyển Tuần / Tháng + Dropdown chọn nhanh trên A2 / B2
// 3. Auto-fill giờ làm việc khi sửa cột CA & tự lưu ngay vào kho tuần hiện tại
// 4. Web App API (doGet / doPost) cho PWA Check-in + Upload Ảnh & đồng bộ 2 chiều DMX-V2
// ============================================================================

const SHEET_PG = "PG";
const SHEET_NV = "NV";
const SHEET_CHECKIN = "BC-Phát tờ rơi";
const SHEET_LICH_PHAT = "LichPhatToRoi";
const SHEET_DATA_PG = "Data_PG";
const DRIVE_ROOT_FOLDER = "DMX_Anh_CheckIn_PhatToRoi";
const PROP_ACTIVE_PG_KEY = "dmx_pg_active_week_key_v1";

const PG_START_ROW = 7;
const PG_MIN_ROWS = 21;   // Tối thiểu dòng 7 -> 27
const PG_MAX_ROWS = 100;  // Hỗ trợ tự mở rộng tối đa 100 PG (dòng 7 -> 106)

function _chuanHoaTenPG(s) {
  return String(s || "").replace(/\s+/g, " ").trim().toLowerCase();
}

/** Tự động đếm số dòng nhân sự PG thực tế trên sheet PG (cập nhật động khi thêm/bớt PG!) */
function _laySoDongPG(sheetPG) {
  if (!sheetPG) return PG_MIN_ROWS;
  const maxScan = Math.min(Math.max(sheetPG.getLastRow(), PG_START_ROW + PG_MIN_ROWS - 1), PG_START_ROW + PG_MAX_ROWS - 1);
  const scanCount = Math.max(PG_MIN_ROWS, maxScan - PG_START_ROW + 1);
  const colB = sheetPG.getRange(PG_START_ROW, 2, scanCount, 1).getDisplayValues();
  let lastValidOffset = -1;
  for (let i = colB.length - 1; i >= 0; i--) {
    const val = String(colB[i][0] || "").trim();
    if (val && val.toLowerCase() !== "tên") {
      lastValidOffset = i;
      break;
    }
  }
  return Math.max(PG_MIN_ROWS, lastValidOffset + 1);
}

/** Ánh xạ dữ liệu tuần đã lưu trong Data_PG sang danh sách PG hiện tại theo TÊN (không bao giờ lệch dòng khi thêm/xóa/chèn PG!) */
function _anhXaLuoiTheoTenPG(savedGrid, nganhTenHienTai) {
  const numRows = nganhTenHienTai.length;
  const lichOut = [];
  const diemDanhOut = [];

  const mapTheoTen = {};
  if (savedGrid && Array.isArray(savedGrid.lich)) {
    const savedNames = Array.isArray(savedGrid.nganhTen) ? savedGrid.nganhTen : [];
    const savedDD = Array.isArray(savedGrid.diemDanh) ? savedGrid.diemDanh : [];
    for (let i = 0; i < savedGrid.lich.length; i++) {
      const k = (savedNames[i] && savedNames[i][1]) ? _chuanHoaTenPG(savedNames[i][1]) : "";
      if (k) {
        mapTheoTen[k] = {
          lich: savedGrid.lich[i],
          dd: savedDD[i] ? (savedDD[i][0] || "") : ""
        };
      }
    }
  }

  for (let r = 0; r < numRows; r++) {
    const tenKey = _chuanHoaTenPG(nganhTenHienTai[r][1]);
    let row14 = null;
    let ddVal = "";
    if (tenKey && mapTheoTen[tenKey] && Array.isArray(mapTheoTen[tenKey].lich) && mapTheoTen[tenKey].lich.length === 14) {
      row14 = mapTheoTen[tenKey].lich.slice();
      ddVal = mapTheoTen[tenKey].dd;
    } else if (!tenKey && savedGrid && Array.isArray(savedGrid.lich) && savedGrid.lich[r] && savedGrid.lich[r].length === 14 && (!savedGrid.nganhTen || !savedGrid.nganhTen[r] || !savedGrid.nganhTen[r][1])) {
      row14 = savedGrid.lich[r].slice();
    }
    lichOut.push(row14 || ["", "", "", "", "", "", "", "", "", "", "", "", "", ""]);
    diemDanhOut.push([ddVal]);
  }
  return { lich: lichOut, diemDanh: diemDanhOut };
}

const TIME_MAP = {
  "SÁNG": "8h-16h",
  "CHIỀU": "15h-20h",
  "GÃY ( SÁNG VS CHIỀU)": "8h-20h",
  "GÃY (SÁNG VS CHIỀU)": "8h-20h",
  "GÃY": "8h-20h"
};

// ============================================================================
// 0. TIỆN ÍCH TÍNH NGÀY THỨ 2 & KHÓA TUẦN (KHỚP 100% CÔNG THỨC HÀNG 4 SHEET PG)
// ============================================================================

function _laySheetPG(ssOpt) {
  const ss = ssOpt || SpreadsheetApp.getActiveSpreadsheet();
  const active = ss.getActiveSheet();
  if (active && active.getName() === SHEET_PG) return active;
  return ss.getSheetByName(SHEET_PG);
}

function _pad2(n) {
  return n < 10 ? "0" + n : "" + n;
}

function _formatISODate(d) {
  return d.getFullYear() + "-" + _pad2(d.getMonth() + 1) + "-" + _pad2(d.getDate());
}

function _formatDDMM(d) {
  return _pad2(d.getDate()) + "/" + _pad2(d.getMonth() + 1);
}

function _tinhNgayThu2(thangNamStr, tuanSo) {
  const parts = String(thangNamStr || "").trim().split("/");
  if (parts.length !== 2) return null;
  const month = parseInt(parts[0], 10);
  const year = parseInt(parts[1], 10);
  const week = parseInt(tuanSo, 10);
  if (isNaN(month) || isNaN(year) || isNaN(week) || month < 1 || month > 12 || week < 1 || week > 6) {
    return null;
  }
  const firstDay = new Date(year, month - 1, 1, 12, 0, 0);
  const dow = firstDay.getDay() === 0 ? 7 : firstDay.getDay(); // T2=1 .. CN=7
  return new Date(year, month - 1, 1 - dow + 1 + (week - 1) * 7, 12, 0, 0);
}

function _tinhKhoangNgayTuMonday(monday) {
  if (!monday) return "";
  const sunday = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + 6, 12, 0, 0);
  return _formatDDMM(monday) + " – " + _formatDDMM(sunday);
}

/**
 * Từ ngày Thứ 2 bất kỳ, tính chính xác (Tuần mấy, Tháng/Năm nào) khớp 100% công thức hàng 4 sheet PG:
 * - Chủ nhật của tuần thuộc tháng nào thì tuần đó thuộc tháng đó (mỗi tuần duy nhất 1 mã, không trùng lặp, không bỏ sót).
 * - Khi hết tuần cuối của tháng, cộng thêm 7 ngày sẽ tự động chuyển sang Tuần 1 của tháng tiếp theo!
 */
function _xacDinhTuanThangTuMonday(monday) {
  const sunday = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + 6, 12, 0, 0);
  const month = sunday.getMonth() + 1;
  const year = sunday.getFullYear();
  const thangNam = _pad2(month) + "/" + year;
  const w1Monday = _tinhNgayThu2(thangNam, 1);
  const diffDays = Math.round((monday.getTime() - w1Monday.getTime()) / 86400000);
  const tuan = Math.floor(diffDays / 7) + 1;
  return {
    tuan: tuan,
    month: month,
    year: year,
    thangNam: thangNam,
    monday: monday,
    weekKey: _formatISODate(monday),
    khoangNgay: _tinhKhoangNgayTuMonday(monday)
  };
}

/** Dựa vào ngày hiện tại (múi giờ Việt Nam) để xác định chính xác Thứ 2, Tuần mấy & Tháng/Năm hiện tại */
function _tinhThongTinTuanHomNay() {
  const tz = Session.getScriptTimeZone() || "Asia/Ho_Chi_Minh";
  const parts = Utilities.formatDate(new Date(), tz, "yyyy-MM-dd").split("-");
  const today = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10), 12, 0, 0);
  const dow = today.getDay() === 0 ? 7 : today.getDay(); // T2=1 .. CN=7
  const monday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - (dow - 1), 12, 0, 0);
  return _xacDinhTuanThangTuMonday(monday);
}

/** Đếm số tuần thực tế (4 hoặc 5 tuần) thuộc về một tháng/năm nhất định */
function _soTuanCuaThang(month, year) {
  const thangNam = _pad2(month) + "/" + year;
  let maxW = 4;
  for (let w = 4; w <= 5; w++) {
    const mon = _tinhNgayThu2(thangNam, w);
    if (!mon) break;
    const sun = new Date(mon.getFullYear(), mon.getMonth(), mon.getDate() + 6, 12, 0, 0);
    if (sun.getMonth() + 1 === month && sun.getFullYear() === year) {
      maxW = w;
    }
  }
  return maxW;
}

function _docThangNamVaTuan(sheetPG) {
  const vals = sheetPG.getRange("A2:B2").getValues()[0];
  const tuan = parseInt(vals[0], 10);
  const rawB2 = vals[1];
  let thangNam = "";
  if (rawB2 instanceof Date) {
    thangNam = Utilities.formatDate(rawB2, Session.getScriptTimeZone() || "Asia/Ho_Chi_Minh", "MM/yyyy");
  } else {
    thangNam = String(rawB2 || "").trim();
  }
  const monday = _tinhNgayThu2(thangNam, tuan);
  if (!monday) {
    return _tinhThongTinTuanHomNay();
  }
  const weekKey = _formatISODate(monday);
  const khoangNgay = _tinhKhoangNgayTuMonday(monday);
  return { tuan: isNaN(tuan) ? 1 : tuan, thangNam: thangNam, monday: monday, weekKey: weekKey, khoangNgay: khoangNgay };
}

function _damBaoSheetDataPG(ss) {
  let sh = ss.getSheetByName(SHEET_DATA_PG);
  if (!sh) {
    sh = ss.insertSheet(SHEET_DATA_PG);
  }
  const firstVal = String(sh.getRange(1, 1).getValue() || "").trim();
  if (!firstVal) {
    sh.getRange(1, 1, 1, 6).setValues([[
      "WeekKey", "KhoangNgay", "ThangNam", "Tuan", "CapNhatLuc", "GridJSON"
    ]]);
    sh.getRange(1, 1, 1, 6).setFontWeight("bold").setBackground("#1E3A8A").setFontColor("#FFFFFF");
    sh.setFrozenRows(1);
  }
  if (!sh.isSheetHidden()) {
    sh.hideSheet();
  }
  return sh;
}

function _coDuLieuTrongLuoi(lich21x14, diemDanh21x1) {
  for (let r = 0; r < lich21x14.length; r++) {
    for (let c = 0; c < lich21x14[r].length; c++) {
      if (String(lich21x14[r][c] || "").trim() !== "") return true;
    }
  }
  if (diemDanh21x1) {
    for (let r = 0; r < diemDanh21x1.length; r++) {
      if (String(diemDanh21x1[r][0] || "").trim() !== "") return true;
    }
  }
  return false;
}

function _luuTuanPGVaoKho(ss, sheetPG, metaOverride) {
  const meta = metaOverride || _docThangNamVaTuan(sheetPG);
  if (!meta.weekKey) return null;

  const shData = _damBaoSheetDataPG(ss);
  const numRows = _laySoDongPG(sheetPG);
  const gridAP = sheetPG.getRange(PG_START_ROW, 1, numRows, 16).getDisplayValues();
  const diemDanh = sheetPG.getRange(PG_START_ROW, 19, numRows, 1).getDisplayValues();

  const nganhTen = [];
  const lich = [];
  for (let r = 0; r < numRows; r++) {
    nganhTen.push([gridAP[r][0], gridAP[r][1]]);
    lich.push(gridAP[r].slice(2, 16));
  }

  const tz = Session.getScriptTimeZone() || "Asia/Ho_Chi_Minh";
  const capNhatLuc = Utilities.formatDate(new Date(), tz, "HH:mm dd/MM/yyyy");
  const jsonStr = JSON.stringify({
    nganhTen: nganhTen,
    lich: lich,
    diemDanh: diemDanh
  });

  const lastRow = shData.getLastRow();
  let foundRow = -1;
  if (lastRow >= 2) {
    const keys = shData.getRange(2, 1, lastRow - 1, 1).getValues();
    for (let i = 0; i < keys.length; i++) {
      if (String(keys[i][0] || "").trim() === meta.weekKey) {
        foundRow = i + 2;
        break;
      }
    }
  }

  const rowData = [[
    "'" + meta.weekKey,
    "'" + (meta.khoangNgay || ""),
    "'" + (meta.thangNam || ""),
    meta.tuan || "",
    "'" + capNhatLuc,
    jsonStr
  ]];

  if (foundRow >= 2) {
    shData.getRange(foundRow, 1, 1, 6).setValues(rowData);
  } else {
    shData.getRange(Math.max(2, lastRow + 1), 1, 1, 6).setValues(rowData);
  }

  return meta.weekKey;
}

function _timDuLieuTuanTrongKho(ss, weekKey) {
  if (!weekKey) return null;
  const shData = ss.getSheetByName(SHEET_DATA_PG);
  if (!shData) return null;
  const lastRow = shData.getLastRow();
  if (lastRow < 2) return null;

  const vals = shData.getRange(2, 1, lastRow - 1, 6).getValues();
  for (let i = 0; i < vals.length; i++) {
    if (String(vals[i][0] || "").trim() === weekKey) {
      const rawJson = String(vals[i][5] || "");
      if (!rawJson) return null;
      try {
        return {
          weekKey: weekKey,
          khoangNgay: String(vals[i][1] || ""),
          thangNam: String(vals[i][2] || ""),
          tuan: vals[i][3],
          capNhatLuc: String(vals[i][4] || ""),
          grid: JSON.parse(rawJson)
        };
      } catch (e) {
        return null;
      }
    }
  }
  return null;
}

function _napTuanPGTuKho(ss, sheetPG, weekKey) {
  const saved = _timDuLieuTuanTrongKho(ss, weekKey);
  const numRows = _laySoDongPG(sheetPG);
  const endRow = PG_START_ROW + numRows - 1;
  if (saved && saved.grid && Array.isArray(saved.grid.lich)) {
    const nganhTenHienTai = sheetPG.getRange(PG_START_ROW, 1, numRows, 2).getDisplayValues();
    const mapped = _anhXaLuoiTheoTenPG(saved.grid, nganhTenHienTai);
    sheetPG.getRange(PG_START_ROW, 3, numRows, 14).setValues(mapped.lich);
    sheetPG.getRange(PG_START_ROW, 19, numRows, 1).setValues(mapped.diemDanh);
  } else {
    // Tuần mới chưa từng nhập lịch -> xóa sạch lưới CA/TIME để nhập mới hoàn toàn riêng biệt!
    sheetPG.getRangeList(["C" + PG_START_ROW + ":P" + endRow, "S" + PG_START_ROW + ":S" + endRow]).clearContent();
  }
  PropertiesService.getDocumentProperties().setProperty(PROP_ACTIVE_PG_KEY, weekKey);
}

// ============================================================================
// 1. MENU TIỆN ÍCH & KHỞI TẠO NHANH (DROPDOWN + KHO TUẦN PG + HEADER CHECK-IN)
// ============================================================================

function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu("⚡ DMX Tiện ích")
    .addItem("📍 Về đúng Tuần hiện tại (theo ngày hôm nay)", "veTuanHienTai")
    .addItem("📋 Sao chép lịch tuần trước sang tuần đang mở", "saoChepTuanTruocSangTuanNay")
    .addItem("🚀 Khởi tạo kho tuần PG + Dropdown nhanh + Bảng Check-in", "khoiTaoNhanhBangTinh")
    .addItem("💾 Lưu thủ công tuần PG hiện tại vào kho", "luuTuanPGHienTai")
    .addItem("🗑️ Xóa lịch làm việc tuần đang mở (PG)", "xoaLichLamViec")
    .addToUi();
}

/** Nhảy thẳng về đúng Tuần & Tháng của ngày hiện tại (tự lưu tuần cũ trước khi chuyển) */
function veTuanHienTai() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = _laySheetPG(ss);
  if (!sheet) return;

  const curMeta = _docThangNamVaTuan(sheet);
  const todayInfo = _tinhThongTinTuanHomNay();

  if (curMeta.weekKey) {
    _luuTuanPGVaoKho(ss, sheet, curMeta);
  }
  sheet.getRange("A2:B2").setValues([[todayInfo.tuan, "'" + todayInfo.thangNam]]);
  CacheService.getDocumentCache().put("dmx_pg_b2", todayInfo.thangNam, 300);

  if (todayInfo.weekKey !== curMeta.weekKey) {
    _napTuanPGTuKho(ss, sheet, todayInfo.weekKey);
  } else {
    PropertiesService.getDocumentProperties().setProperty(PROP_ACTIVE_PG_KEY, todayInfo.weekKey);
  }
  return todayInfo;
}

function khoiTaoNhanhBangTinh() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();

  // 1. Gắn dropdown chọn nhanh trên PG!A2 (Tuần 1..5) và PG!B2 (Tháng/Năm)
  const sheetPG = ss.getSheetByName(SHEET_PG);
  if (sheetPG) {
    const ruleTuan = SpreadsheetApp.newDataValidation()
      .requireValueInList(["1", "2", "3", "4", "5"], true)
      .setAllowInvalid(true)
      .build();
    sheetPG.getRange("A2").setDataValidation(ruleTuan);

    const dsThang = [];
    const namHienTai = new Date().getFullYear();
    for (let y = namHienTai - 1; y <= namHienTai + 2; y++) {
      for (let m = 1; m <= 12; m++) {
        dsThang.push(_pad2(m) + "/" + y);
      }
    }
    const ruleThang = SpreadsheetApp.newDataValidation()
      .requireValueInList(dsThang, true)
      .setAllowInvalid(true)
      .build();
    sheetPG.getRange("B2").setNumberFormat("@").setDataValidation(ruleThang);

    // Chụp lưu tuần đang hiển thị vào Data_PG, đồng thời chuẩn hóa A2:B2 đúng theo ngày hiện tại nếu đang sai chuẩn
    const meta = _docThangNamVaTuan(sheetPG);
    if (meta.weekKey) {
      _luuTuanPGVaoKho(ss, sheetPG, meta);
      const chuan = _xacDinhTuanThangTuMonday(meta.monday);
      sheetPG.getRange("A2:B2").setValues([[chuan.tuan, "'" + chuan.thangNam]]);
      PropertiesService.getDocumentProperties().setProperty(PROP_ACTIVE_PG_KEY, chuan.weekKey);
    } else {
      veTuanHienTai();
    }
  }

  // 2. Đảm bảo sheet "BC-Phát tờ rơi" có đủ tiêu đề chuẩn đẹp
  _damBaoHeaderCheckIn(ss);
  return "OK";
}

function luuTuanPGHienTai() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheetPG = _laySheetPG(ss);
  if (!sheetPG) return;
  const meta = _docThangNamVaTuan(sheetPG);
  if (meta.weekKey) {
    _luuTuanPGVaoKho(ss, sheetPG, meta);
    PropertiesService.getDocumentProperties().setProperty(PROP_ACTIVE_PG_KEY, meta.weekKey);
  }
}

function saoChepTuanTruocSangTuanNay() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheetPG = _laySheetPG(ss);
  if (!sheetPG) return;
  const meta = _docThangNamVaTuan(sheetPG);
  if (!meta.monday) return;

  const prevMonday = new Date(meta.monday.getFullYear(), meta.monday.getMonth(), meta.monday.getDate() - 7, 12, 0, 0);
  const prevKey = _formatISODate(prevMonday);
  const saved = _timDuLieuTuanTrongKho(ss, prevKey);
  if (!saved || !saved.grid || !Array.isArray(saved.grid.lich)) {
    SpreadsheetApp.getUi().alert("Chưa có dữ liệu tuần trước (" + _tinhKhoangNgayTuMonday(prevMonday) + ") trong kho để sao chép.");
    return;
  }
  const numRows = _laySoDongPG(sheetPG);
  const nganhTenHienTai = sheetPG.getRange(PG_START_ROW, 1, numRows, 2).getDisplayValues();
  const mapped = _anhXaLuoiTheoTenPG(saved.grid, nganhTenHienTai);
  sheetPG.getRange(PG_START_ROW, 3, numRows, 14).setValues(mapped.lich);
  _luuTuanPGVaoKho(ss, sheetPG, meta);
  PropertiesService.getDocumentProperties().setProperty(PROP_ACTIVE_PG_KEY, meta.weekKey);
}

// ============================================================================
// 2. XÓA LỊCH & CHUYỂN THÁNG / TUẦN (TỰ LƯU TUẦN CŨ + TỰ NẠP TUẦN MỚI!)
// ============================================================================

function xoaLichLamViec() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = _laySheetPG(ss);
  if (!sheet) return;
  const endRow = PG_START_ROW + _laySoDongPG(sheet) - 1;
  sheet.getRangeList(["C" + PG_START_ROW + ":P" + endRow, "S" + PG_START_ROW + ":S" + endRow]).clearContent();
  const meta = _docThangNamVaTuan(sheet);
  if (meta.weekKey) {
    _luuTuanPGVaoKho(ss, sheet, meta);
    PropertiesService.getDocumentProperties().setProperty(PROP_ACTIVE_PG_KEY, meta.weekKey);
  }
}

function prevMonth() {
  changeMonth(-1);
}

function nextMonth() {
  changeMonth(1);
}

function changeMonth(delta) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = _laySheetPG(ss);
  if (!sheet) return;

  const curMeta = _docThangNamVaTuan(sheet);
  const parts = String(curMeta.thangNam || "").split("/");
  if (parts.length !== 2) return;

  let month = parseInt(parts[0], 10);
  let year = parseInt(parts[1], 10);
  if (isNaN(month) || isNaN(year)) return;

  // 1. Lưu tuần đang mở vào kho Data_PG trước khi chuyển tháng
  if (curMeta.weekKey) {
    _luuTuanPGVaoKho(ss, sheet, curMeta);
  }

  month += delta;
  if (month < 1) {
    month = 12;
    year -= 1;
  } else if (month > 12) {
    month = 1;
    year += 1;
  }

  const maxWeek = _soTuanCuaThang(month, year);
  const newWeek = Math.min(Math.max(curMeta.tuan, 1), maxWeek);
  const formatted = _pad2(month) + "/" + year;

  // 2. Cập nhật A2:B2 trong đúng 1 lần gọi setValues
  sheet.getRange("A2:B2").setValues([[newWeek, "'" + formatted]]);
  CacheService.getDocumentCache().put("dmx_pg_b2", formatted, 300);

  // 3. Nạp dữ liệu riêng của tuần/tháng mới từ kho Data_PG (trống nếu chưa nhập!)
  const newMonday = _tinhNgayThu2(formatted, newWeek);
  if (newMonday) {
    const newKey = _formatISODate(newMonday);
    if (newKey !== curMeta.weekKey) {
      _napTuanPGTuKho(ss, sheet, newKey);
    }
  }
}

function prevWeek() {
  changeWeek(-1);
}

function nextWeek() {
  changeWeek(1);
}

/**
 * Chuyển tuần tiến (+1) / lùi (-1) liên tục theo lịch thực tế:
 * - Bấm mũi tên tuần tới tuần cuối của tháng -> TỰ ĐỘNG nhảy sang Tháng sau & đặt về Tuần 1!
 * - Bấm mũi tên lùi từ Tuần 1 -> TỰ ĐỘNG lùi về Tháng trước & đặt đúng Tuần cuối (Tuần 4 hoặc 5)!
 * - Tự động lưu dữ liệu tuần cũ vào kho Data_PG và nạp dữ liệu riêng của tuần mới.
 */
function changeWeek(delta) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = _laySheetPG(ss);
  if (!sheet) return;

  const curMeta = _docThangNamVaTuan(sheet);
  const baseMonday = curMeta.monday || _tinhThongTinTuanHomNay().monday;

  // 1. Lưu tuần hiện tại vào kho Data_PG trước khi nhảy tuần/tháng
  if (curMeta.weekKey) {
    _luuTuanPGVaoKho(ss, sheet, curMeta);
  }

  // 2. Cộng/trừ đúng 7 ngày -> tự tính chính xác (Tuần mới, Tháng/Năm mới)
  const targetMonday = new Date(
    baseMonday.getFullYear(),
    baseMonday.getMonth(),
    baseMonday.getDate() + delta * 7,
    12, 0, 0
  );
  const nextInfo = _xacDinhTuanThangTuMonday(targetMonday);

  // 3. Ghi đồng thời cả ô Tuần (A2) và ô Tháng/Năm (B2) trong ĐÚNG 1 lần gọi API cho nhanh tối đa
  sheet.getRange("A2:B2").setValues([[nextInfo.tuan, "'" + nextInfo.thangNam]]);
  CacheService.getDocumentCache().put("dmx_pg_b2", nextInfo.thangNam, 300);

  // 4. Nạp dữ liệu riêng của tuần mới từ kho Data_PG (trống nếu chưa nhập!)
  if (nextInfo.weekKey !== curMeta.weekKey) {
    _napTuanPGTuKho(ss, sheet, nextInfo.weekKey);
  }
}

// ============================================================================
// 3. ONEDIT: ĐỔI TUẦN/THÁNG BẰNG DROPDOWN A2/B2 + TỰ ĐIỀN GIỜ + TỰ LƯU KHO TUẦN
// ============================================================================

function onEdit(e) {
  if (!e || !e.range) return;
  const range = e.range;
  const sheet = range.getSheet();
  if (sheet.getName() !== SHEET_PG) return;

  const startRow = range.getRow();
  const startCol = range.getColumn();
  const numRows = range.getNumRows();
  const numCols = range.getNumColumns();
  const endRow = startRow + numRows - 1;
  const endCol = startCol + numCols - 1;
  const ss = sheet.getParent();

  // Trường hợp A: Người dùng chọn trực tiếp Tuần (A2) hoặc Tháng/Năm (B2) bằng Dropdown hoặc gõ tay!
  if (startRow <= 2 && endRow >= 2 && startCol <= 2) {
    const props = PropertiesService.getDocumentProperties();
    const oldKey = props.getProperty(PROP_ACTIVE_PG_KEY) || "";
    const rawMeta = _docThangNamVaTuan(sheet);
    const newMeta = rawMeta.monday ? _xacDinhTuanThangTuMonday(rawMeta.monday) : _tinhThongTinTuanHomNay();
    // Nếu tuần vừa chọn vượt sang tháng kế tiếp (VD: chọn Tuần 5 của tháng chỉ có 4 tuần) -> tự chỉnh về đúng Tuần 1 tháng sau
    if (newMeta.tuan !== rawMeta.tuan || newMeta.thangNam !== rawMeta.thangNam) {
      sheet.getRange("A2:B2").setValues([[newMeta.tuan, "'" + newMeta.thangNam]]);
    }
    if (newMeta.weekKey && newMeta.weekKey !== oldKey) {
      // Lưu lưới hiện tại vào đúng khóa tuần cũ trước khi nạp dữ liệu tuần mới
      if (oldKey) {
        const oldParts = oldKey.split("-");
        const oldMonday = oldParts.length === 3 ? new Date(parseInt(oldParts[0], 10), parseInt(oldParts[1], 10) - 1, parseInt(oldParts[2], 10), 12, 0, 0) : null;
        _luuTuanPGVaoKho(ss, sheet, {
          weekKey: oldKey,
          khoangNgay: oldMonday ? _tinhKhoangNgayTuMonday(oldMonday) : "",
          thangNam: oldMonday ? (_pad2(oldMonday.getMonth() + 1) + "/" + oldMonday.getFullYear()) : "",
          tuan: ""
        });
      }
      _napTuanPGTuKho(ss, sheet, newMeta.weekKey);
    }
    return;
  }

  // Trường hợp B: Người dùng sửa ca/giờ (C7:P...) hoặc tên/ngành (A7:B...) hoặc điểm danh (S7:S...)
  const pgLastRow = PG_START_ROW + _laySoDongPG(sheet) - 1;
  if (endRow < PG_START_ROW || startRow > pgLastRow) return;

  // 1. Tự điền khung giờ ở cột TIME khi sửa cột CA (cột lẻ 3..15)
  if (endCol >= 3 && startCol <= 15) {
    if (numRows === 1 && numCols === 1) {
      if (startCol % 2 === 1) {
        const ca = e.value ? String(e.value).trim().toUpperCase() : "";
        range.offset(0, 1).setValue(TIME_MAP[ca] || "");
      }
    } else {
      const validStartRow = Math.max(startRow, PG_START_ROW);
      const validEndRow = Math.min(endRow, pgLastRow);
      const validNumRows = validEndRow - validStartRow + 1;
      const rowOffset = validStartRow - startRow;
      const values = range.getValues();

      for (let c = 0; c < numCols; c++) {
        const currentCol = startCol + c;
        if (currentCol >= 3 && currentCol <= 15 && currentCol % 2 === 1) {
          const timeColValues = [];
          for (let r = 0; r < validNumRows; r++) {
            const ca = String(values[rowOffset + r][c] || "").trim().toUpperCase();
            timeColValues.push([TIME_MAP[ca] || ""]);
          }
          sheet.getRange(validStartRow, currentCol + 1, validNumRows, 1).setValues(timeColValues);
        }
      }
    }
  }

  // 2. Tự động lưu ngay thay đổi vào kho Data_PG cho đúng tuần đang mở
  if ((endCol >= 1 && startCol <= 16) || (startCol <= 19 && endCol >= 19)) {
    const meta = _docThangNamVaTuan(sheet);
    if (meta.weekKey) {
      _luuTuanPGVaoKho(ss, sheet, meta);
      PropertiesService.getDocumentProperties().setProperty(PROP_ACTIVE_PG_KEY, meta.weekKey);
    }
  }
}

// ============================================================================
// 4. WEB APP API CHO PWA CHECK-IN, UPLOAD ẢNH & ĐỒNG BỘ 2 TUẦN PG VỚI APP DMX-V2
// ============================================================================

function _jsonOut(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

function _damBaoHeaderCheckIn(ss) {
  let sh = ss.getSheetByName(SHEET_CHECKIN);
  if (!sh) {
    sh = ss.insertSheet(SHEET_CHECKIN);
  }
  const firstVal = String(sh.getRange(1, 1).getValue() || "").trim();
  if (!firstVal) {
    const headers = [
      "STT",
      "Thời gian",
      "Ngày",
      "Nhóm",
      "Họ tên",
      "Bộ phận / Ngành",
      "Tuyến / Khu vực",
      "Địa điểm phát",
      "Tọa độ GPS",
      "Link Google Maps",
      "Link Ảnh Drive",
      "Xem nhanh ảnh",
      "Ghi chú"
    ];
    const headerRange = sh.getRange(1, 1, 1, headers.length);
    headerRange.setValues([headers]);
    headerRange
      .setFontWeight("bold")
      .setBackground("#0B4F9E")
      .setFontColor("#FFFFFF")
      .setHorizontalAlignment("center")
      .setVerticalAlignment("middle");
    sh.setFrozenRows(1);
    sh.setRowHeight(1, 34);
    const widths = [52, 145, 95, 65, 175, 165, 130, 190, 155, 120, 120, 150, 200];
    for (let i = 0; i < widths.length; i++) {
      sh.setColumnWidth(i + 1, widths[i]);
    }
  }
  return sh;
}

function _docDanhSachNhanSu(ss) {
  const dsPG = [];
  const dsNV = [];

  const shPG = ss.getSheetByName(SHEET_PG);
  if (shPG) {
    const numRowsPG = _laySoDongPG(shPG);
    const vals = shPG.getRange(PG_START_ROW, 1, numRowsPG, 2).getDisplayValues();
    let nganhHienTai = "";
    for (let i = 0; i < vals.length; i++) {
      const ng = String(vals[i][0] || "").replace(/\s+/g, " ").trim();
      const ten = String(vals[i][1] || "").replace(/\s+/g, " ").trim();
      if (ng && ng.toLowerCase().indexOf("ngành") === -1) nganhHienTai = ng;
      if (ten && ten.toLowerCase() !== "tên") {
        dsPG.push({ ten: ten, nhom: "PG", boPhan: nganhHienTai || "PG" });
      }
    }
  }

  const shNV = ss.getSheetByName(SHEET_NV);
  if (shNV) {
    const lastRow = Math.min(Math.max(shNV.getLastRow(), 23), 80);
    if (lastRow >= 3) {
      const vals = shNV.getRange(3, 1, lastRow - 2, 3).getValues();
      let bpHienTai = "";
      for (let i = 0; i < vals.length; i++) {
        const bp = String(vals[i][0] || "").replace(/\s+/g, " ").trim();
        const ten = String(vals[i][2] || "").replace(/\s+/g, " ").trim();
        const bpLow = bp.toLowerCase();
        if (bpLow.indexOf("note") === 0 || bpLow === "ca" || bpLow.indexOf("thời gian") === 0) break;
        if (bp && bpLow.indexOf("bộ phận") === -1) bpHienTai = bp;
        if (ten && ten.toLowerCase().indexOf("họ tên") === -1 && isNaN(Number(ten))) {
          dsNV.push({ ten: ten, nhom: "NV", boPhan: bpHienTai || "NV Siêu thị" });
        }
      }
    }
  }

  return { pg: dsPG, nv: dsNV };
}

function _trichToaDoTuChuoi(toaDoText, linkMaps) {
  const sources = [String(toaDoText || ""), String(linkMaps || "")];
  const patterns = [
    /(-?\d{1,2}\.\d{3,})\s*,\s*(-?\d{1,3}\.\d{3,})/,
    /!3d(-?\d{1,2}\.\d{3,})!4d(-?\d{1,3}\.\d{3,})/,
    /[?&](?:q|query|ll|center)=(-?\d{1,2}\.\d{3,})[,\s+]+(-?\d{1,3}\.\d{3,})/
  ];
  for (let s = 0; s < sources.length; s++) {
    const txt = sources[s];
    if (!txt) continue;
    for (let p = 0; p < patterns.length; p++) {
      const m = txt.match(patterns[p]);
      if (m) {
        const la = parseFloat(m[1]);
        const lo = parseFloat(m[2]);
        if (isFinite(la) && isFinite(lo) && la >= -90 && la <= 90 && lo >= -180 && lo <= 180 && (Math.abs(la) > 0.001 || Math.abs(lo) > 0.001)) {
          return { lat: la, lng: lo };
        }
      }
    }
  }
  return { lat: null, lng: null };
}

function _trichDriveFileId(url) {
  const s = String(url || "");
  const m1 = s.match(/\/d\/([a-zA-Z0-9_-]{15,})/);
  if (m1) return m1[1];
  const m2 = s.match(/[?&]id=([a-zA-Z0-9_-]{15,})/);
  if (m2) return m2[1];
  return "";
}

function _docCheckInGanNhat(ss, limit) {
  const sh = ss.getSheetByName(SHEET_CHECKIN);
  if (!sh) return [];
  const lastRow = sh.getLastRow();
  if (lastRow < 2) return [];

  const count = Math.min(limit || 100, lastRow - 1);
  const startRow = lastRow - count + 1;
  const vals = sh.getRange(startRow, 1, count, 13).getDisplayValues();
  const formulas = sh.getRange(startRow, 12, count, 1).getFormulas();
  const kq = [];

  for (let i = vals.length - 1; i >= 0; i--) {
    const r = vals[i];
    const f = String(formulas[i][0] || "");
    const imgMatch = f.match(/IMAGE\("([^"]+)"/i);
    const thumbUrl = imgMatch ? imgMatch[1] : "";
    const fileId = _trichDriveFileId(thumbUrl || r[10]);
    const imageUrlChuan = thumbUrl || (fileId ? ("https://drive.google.com/thumbnail?id=" + fileId + "&sz=w1000") : r[10]);
    const coords = _trichToaDoTuChuoi(r[8], r[9]);
    kq.push({
      stt: r[0],
      thoiGian: r[1],
      ngay: r[2],
      nhom: r[3],
      hoTen: r[4],
      boPhan: r[5],
      tuyen: r[6],
      diaDiem: r[7],
      toaDo: r[8],
      lat: coords.lat,
      lng: coords.lng,
      linkMaps: r[9],
      linkDrive: r[10],
      linkAnh: imageUrlChuan,
      fileId: fileId,
      ghiChu: r[12]
    });
  }
  return kq;
}

function _luuLichPhanCongPhatToRoi(ss, payload) {
  let sh = ss.getSheetByName(SHEET_LICH_PHAT);
  if (!sh) {
    sh = ss.insertSheet(SHEET_LICH_PHAT);
  }
  const tz = Session.getScriptTimeZone() || "Asia/Ho_Chi_Minh";
  const capNhatLuc = Utilities.formatDate(new Date(), tz, "HH:mm dd/MM/yyyy");
  const tuan = String(payload.tuan || "").trim();
  const cacTuyen = Array.isArray(payload.cacTuyen) ? payload.cacTuyen : [];
  const cacPhanCong = Array.isArray(payload.cacPhanCong) ? payload.cacPhanCong : [];

  sh.clearContents();
  const headers = [
    "Tuần",
    "Thứ",
    "Buổi",
    "Tuyến",
    "Điểm nóng / Quãng đường",
    "PG phân công",
    "NV phân công",
    "Trạng thái",
    "Link Google Maps",
    "Cập nhật lúc"
  ];
  const tuyenMap = {};
  for (let i = 0; i < cacTuyen.length; i++) {
    tuyenMap[String(cacTuyen[i].id || "")] = cacTuyen[i];
  }

  const rows = [headers];
  for (let i = 0; i < cacPhanCong.length; i++) {
    const o = cacPhanCong[i] || {};
    const t = tuyenMap[String(o.tuyenId || "")] || {};
    const pgStr = Array.isArray(o.danhSachPG) ? o.danhSachPG.join(", ") : "";
    const nvStr = Array.isArray(o.danhSachNV) ? o.danhSachNV.join(", ") : "";
    rows.push([
      tuan,
      String(o.thuTen || ""),
      String(o.buoi || ""),
      String(o.tenTuyen || ""),
      String(o.moTaTuyen || t.moTaDiemNong || ""),
      pgStr,
      nvStr,
      o.daPhat ? "Đã phát" : "Chưa phát",
      String(t.googleMapsUrl || ""),
      "'" + capNhatLuc
    ]);
  }

  sh.getRange(1, 1, rows.length, headers.length).setValues(rows);
  const hdrRange = sh.getRange(1, 1, 1, headers.length);
  hdrRange.setFontWeight("bold").setBackground("#0D9488").setFontColor("#FFFFFF").setHorizontalAlignment("center");
  sh.setFrozenRows(1);

  const pack = JSON.stringify({
    tuan: tuan,
    capNhatLuc: capNhatLuc,
    cacTuyen: cacTuyen,
    cacPhanCong: cacPhanCong
  });
  const chunkSize = 40000;
  const chunks = [];
  for (let pos = 0; pos < pack.length; pos += chunkSize) {
    chunks.push([pack.slice(pos, pos + chunkSize)]);
  }
  if (chunks.length > 0) {
    sh.getRange(1, 12, chunks.length, 1).setValues(chunks);
  }
  sh.getRange(1, 11).setValue(chunks.length);

  return {
    ok: true,
    action: "syncSchedule",
    tuan: tuan,
    soTuyen: cacTuyen.length,
    soBuoi: cacPhanCong.length,
    capNhatLuc: capNhatLuc
  };
}

function _docLichPhanCongPhatToRoi(ss) {
  const sh = ss.getSheetByName(SHEET_LICH_PHAT);
  if (!sh) return null;
  const numChunks = parseInt(sh.getRange(1, 11).getValue(), 10);
  if (!numChunks || numChunks < 1 || numChunks > 20) return null;
  const vals = sh.getRange(1, 12, numChunks, 1).getValues();
  let raw = "";
  for (let i = 0; i < vals.length; i++) {
    raw += String(vals[i][0] || "");
  }
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch (e) {
    return null;
  }
}

function _layThuMucAnh(thangNam) {
  const roots = DriveApp.getFoldersByName(DRIVE_ROOT_FOLDER);
  const rootFolder = roots.hasNext() ? roots.next() : DriveApp.createFolder(DRIVE_ROOT_FOLDER);
  const subs = rootFolder.getFoldersByName(thangNam);
  return subs.hasNext() ? subs.next() : rootFolder.createFolder(thangNam);
}

// ============================================================================
// 4B. API ĐĂNG KÝ CA LÀM VIỆC PG (TUẦN HIỆN TẠI + TUẦN TIẾP THEO) & LỊCH TỔNG 21 NV
// ============================================================================

const PG_VALID_SHIFTS = {
  "": "",
  "SÁNG": "SÁNG",
  "SANG": "SÁNG",
  "CHIỀU": "CHIỀU",
  "CHIEU": "CHIỀU",
  "GÃY": "GÃY ( SÁNG VS CHIỀU)",
  "GAY": "GÃY ( SÁNG VS CHIỀU)",
  "GÃY ( SÁNG VS CHIỀU)": "GÃY ( SÁNG VS CHIỀU)",
  "GÃY (SÁNG VS CHIỀU)": "GÃY ( SÁNG VS CHIỀU)",
  "OFF": "OFF",
  "ST #": "ST #",
  "ST#": "ST #"
};

function _taoNgayHeadersTuMonday(monday) {
  const thuNgan = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];
  const thuDai = ["Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7", "Chủ nhật"];
  const arr = [];
  for (let i = 0; i < 7; i++) {
    const d = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + i, 12, 0, 0);
    arr.push({
      index: i,
      thu: thuNgan[i],
      thuDai: thuDai[i],
      ngay: _formatDDMM(d),
      iso: _formatISODate(d)
    });
  }
  return arr;
}

function _docHaiTuanPGDayDu(ss) {
  const shPG = ss.getSheetByName(SHEET_PG);
  if (!shPG) return [];

  const numRows = _laySoDongPG(shPG);
  const gridAP = shPG.getRange(PG_START_ROW, 1, numRows, 16).getDisplayValues();
  const curMeta = _docThangNamVaTuan(shPG);

  // Đọc danh sách PG ĐỘNG theo thực tế hiện có trên sheet PG (thêm/bớt dòng tự cập nhật ngay!)
  const dsTen = [];
  const nganhTenHienTai = [];
  let nganhHienTai = "";
  for (let r = 0; r < numRows; r++) {
    const ng = String(gridAP[r][0] || "").replace(/\s+/g, " ").trim();
    const ten = String(gridAP[r][1] || "").replace(/\s+/g, " ").trim();
    if (ng && ng.toLowerCase().indexOf("ngành") === -1) nganhHienTai = ng;
    dsTen.push({ rowIndex: r, nganh: nganhHienTai || "PG", ten: ten });
    nganhTenHienTai.push([gridAP[r][0], gridAP[r][1]]);
  }

  // Đọc toàn bộ Data_PG 1 lần duy nhất
  const mapKho = {};
  const shData = ss.getSheetByName(SHEET_DATA_PG);
  if (shData && shData.getLastRow() >= 2) {
    const rowsData = shData.getRange(2, 1, shData.getLastRow() - 1, 6).getValues();
    for (let i = 0; i < rowsData.length; i++) {
      const wk = String(rowsData[i][0] || "").trim();
      const raw = String(rowsData[i][5] || "");
      if (wk && raw) {
        try {
          mapKho[wk] = JSON.parse(raw);
        } catch (e) {}
      }
    }
  }

  const t1 = _tinhThongTinTuanHomNay();
  const nextMonday = new Date(t1.monday.getFullYear(), t1.monday.getMonth(), t1.monday.getDate() + 7, 12, 0, 0);
  const t2 = _xacDinhTuanThangTuMonday(nextMonday);

  const ketQua = [];
  const targets = [
    { kind: "current", badge: "Tuần hiện tại", info: t1 },
    { kind: "next", badge: "Tuần tiếp theo", info: t2 }
  ];

  for (let k = 0; k < targets.length; k++) {
    const item = targets[k];
    const info = item.info;
    let lichMapped = null;

    // Nếu tab PG đang mở đúng tuần này -> lấy trực tiếp từ PG (mới nhất)
    if (curMeta.weekKey === info.weekKey) {
      lichMapped = [];
      for (let r = 0; r < numRows; r++) {
        lichMapped.push(gridAP[r].slice(2, 16));
      }
    } else if (mapKho[info.weekKey] && Array.isArray(mapKho[info.weekKey].lich)) {
      lichMapped = _anhXaLuoiTheoTenPG(mapKho[info.weekKey], nganhTenHienTai).lich;
    }

    const rows = [];
    for (let r = 0; r < numRows; r++) {
      const p = dsTen[r];
      if (!p.ten) continue;
      const lichRow = (lichMapped && lichMapped[r]) ? lichMapped[r] : [];
      const days = [];
      for (let d = 0; d < 7; d++) {
        const ca = String(lichRow[d * 2] || "").trim();
        const gio = String(lichRow[d * 2 + 1] || "").trim();
        days.push({ ca: ca, gio: gio });
      }
      rows.push({
        rowIndex: r,
        nganh: p.nganh,
        ten: p.ten,
        days: days
      });
    }

    ketQua.push({
      kind: item.kind,
      badge: item.badge,
      weekKey: info.weekKey,
      tuan: info.tuan,
      thangNam: info.thangNam,
      khoangNgay: info.khoangNgay,
      label: item.badge + " • Tuần " + info.tuan + "/" + info.month + " (" + info.khoangNgay + ")",
      ngayHeaders: _taoNgayHeadersTuMonday(info.monday),
      rows: rows
    });
  }

  return ketQua;
}

function _dangKyCaLamViecPG(ss, payload) {
  const shPG = ss.getSheetByName(SHEET_PG);
  if (!shPG) return { ok: false, error: "Không tìm thấy sheet PG." };

  const weekKey = String(payload.weekKey || "").trim();
  const hoTen = String(payload.hoTen || "").trim();
  const shifts = Array.isArray(payload.shifts) ? payload.shifts : [];
  const customTimes = Array.isArray(payload.customTimes) ? payload.customTimes : [];

  if (!hoTen) return { ok: false, error: "Vui lòng chọn tên PG trước khi đăng ký ca." };
  if (shifts.length !== 7) return { ok: false, error: "Dữ liệu đăng ký phải đủ 7 ngày (Thứ 2 – Chủ nhật)." };

  // Chỉ cho phép đăng ký cho Tuần hiện tại hoặc Tuần tiếp theo
  const t1 = _tinhThongTinTuanHomNay();
  const nextMonday = new Date(t1.monday.getFullYear(), t1.monday.getMonth(), t1.monday.getDate() + 7, 12, 0, 0);
  const t2 = _xacDinhTuanThangTuMonday(nextMonday);

  let targetMeta = null;
  if (weekKey === t1.weekKey) targetMeta = t1;
  else if (weekKey === t2.weekKey) targetMeta = t2;
  else return { ok: false, error: "Chỉ hỗ trợ đăng ký ca cho Tuần hiện tại (" + t1.khoangNgay + ") hoặc Tuần tiếp theo (" + t2.khoangNgay + ")." };

  // Đọc động danh sách PG hiện tại trên sheet PG (không giới hạn 21 người!)
  const numRows = _laySoDongPG(shPG);
  const nganhTenVals = shPG.getRange(PG_START_ROW, 1, numRows, 2).getDisplayValues();
  const tenKey = _chuanHoaTenPG(hoTen);
  let matchedIdx = -1;
  for (let r = 0; r < numRows; r++) {
    if (_chuanHoaTenPG(nganhTenVals[r][1]) === tenKey) {
      matchedIdx = r;
      break;
    }
  }
  if (matchedIdx < 0) {
    return { ok: false, error: "Không tìm thấy PG \"" + hoTen + "\" trong danh sách PG hiện tại trên sheet PG." };
  }

  // Chuẩn hóa 7 cặp [CA, TIME] khớp đúng DataValidation trên Google Sheet
  const row14 = [];
  for (let d = 0; d < 7; d++) {
    const rawCa = String(shifts[d] || "").trim().toUpperCase();
    const caChuan = (PG_VALID_SHIFTS[rawCa] !== undefined) ? PG_VALID_SHIFTS[rawCa] : String(shifts[d] || "").trim();
    const customGio = String(customTimes[d] || "").trim();
    const gioChuan = customGio || (TIME_MAP[caChuan.toUpperCase()] || "");
    row14.push(caChuan);
    row14.push(gioChuan);
  }

  const curMeta = _docThangNamVaTuan(shPG);
  const tz = Session.getScriptTimeZone() || "Asia/Ho_Chi_Minh";
  const capNhatLuc = Utilities.formatDate(new Date(), tz, "HH:mm dd/MM/yyyy");

  if (curMeta.weekKey === targetMeta.weekKey) {
    // Tuần đăng ký chính là tuần đang mở trên sheet PG -> ghi thẳng lên PG và đồng bộ vào Data_PG!
    shPG.getRange(PG_START_ROW + matchedIdx, 3, 1, 14).setValues([row14]);
    _luuTuanPGVaoKho(ss, shPG, curMeta);
  } else {
    // Tuần đăng ký là tuần khác (VD Tuần tiếp theo) -> ánh xạ theo TÊN vào kho Data_PG
    const shData = _damBaoSheetDataPG(ss);
    const saved = _timDuLieuTuanTrongKho(ss, targetMeta.weekKey);
    const mapped = _anhXaLuoiTheoTenPG(saved ? saved.grid : null, nganhTenVals);
    mapped.lich[matchedIdx] = row14;

    const jsonStr = JSON.stringify({
      nganhTen: nganhTenVals,
      lich: mapped.lich,
      diemDanh: mapped.diemDanh
    });

    const lastRow = shData.getLastRow();
    let foundRow = -1;
    if (lastRow >= 2) {
      const keys = shData.getRange(2, 1, lastRow - 1, 1).getValues();
      for (let i = 0; i < keys.length; i++) {
        if (String(keys[i][0] || "").trim() === targetMeta.weekKey) {
          foundRow = i + 2;
          break;
        }
      }
    }

    const rowData = [[
      "'" + targetMeta.weekKey,
      "'" + targetMeta.khoangNgay,
      "'" + targetMeta.thangNam,
      targetMeta.tuan,
      "'" + capNhatLuc,
      jsonStr
    ]];

    if (foundRow >= 2) {
      shData.getRange(foundRow, 1, 1, 6).setValues(rowData);
    } else {
      shData.getRange(Math.max(2, lastRow + 1), 1, 1, 6).setValues(rowData);
    }
  }

  return {
    ok: true,
    action: "registerPGShift",
    hoTen: hoTen,
    weekKey: targetMeta.weekKey,
    tuan: targetMeta.tuan,
    thangNam: targetMeta.thangNam,
    khoangNgay: targetMeta.khoangNgay,
    capNhatLuc: capNhatLuc,
    pgHaiTuan: _docHaiTuanPGDayDu(ss)
  };
}

function doGet(e) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const action = (e && e.parameter && e.parameter.action) ? String(e.parameter.action) : "init";
    const limitParam = (e && e.parameter && e.parameter.limit) ? parseInt(e.parameter.limit, 10) : 100;
    const limit = (isFinite(limitParam) && limitParam > 0 && limitParam <= 500) ? limitParam : 100;

    if (action === "ping") {
      return _jsonOut({ ok: true, time: new Date().toISOString(), sheetName: ss.getName() });
    }

    if (action === "list") {
      return _jsonOut({
        ok: true,
        lichSu: _docCheckInGanNhat(ss, limit),
        lichPhanCong: _docLichPhanCongPhatToRoi(ss)
      });
    }

    if (action === "schedules") {
      return _jsonOut({
        ok: true,
        pgHaiTuan: _docHaiTuanPGDayDu(ss)
      });
    }

    const nhanSu = _docDanhSachNhanSu(ss);
    const lichSu = _docCheckInGanNhat(ss, limit);
    const lichPhanCong = _docLichPhanCongPhatToRoi(ss);
    const pgHaiTuan = _docHaiTuanPGDayDu(ss);

    let tuanHienTai = "";
    const shPG = ss.getSheetByName(SHEET_PG);
    if (shPG) {
      const meta = _docThangNamVaTuan(shPG);
      tuanHienTai = ("Tuần " + meta.tuan + " • " + meta.thangNam + (meta.khoangNgay ? " (" + meta.khoangNgay + ")" : "")).trim();
    }

    return _jsonOut({
      ok: true,
      tenBangTinh: ss.getName(),
      tuanHienTai: tuanHienTai,
      nhanSu: nhanSu,
      lichSu: lichSu,
      lichPhanCong: lichPhanCong,
      pgHaiTuan: pgHaiTuan
    });
  } catch (err) {
    return _jsonOut({ ok: false, error: String(err && err.message ? err.message : err) });
  }
}

function doPost(e) {
  const lock = LockService.getScriptLock();
  try {
    if (!lock.tryLock(20000)) {
      return _jsonOut({ ok: false, error: "Hệ thống đang bận lưu dữ liệu khác, vui lòng bấm thử lại sau 2 giây." });
    }

    const rawBody = (e && e.postData && e.postData.contents) ? e.postData.contents : "";
    if (!rawBody) {
      return _jsonOut({ ok: false, error: "Không nhận được dữ liệu gửi lên." });
    }

    const data = JSON.parse(rawBody);
    const ss = SpreadsheetApp.getActiveSpreadsheet();

    // Nhánh 1: App DMX-V2 đồng bộ ma trận phân tuyến & lịch phát tờ rơi lên Sheet cho PWA đọc
    if (String(data.action || "") === "syncSchedule") {
      return _jsonOut(_luuLichPhanCongPhatToRoi(ss, data));
    }

    // Nhánh 2: PG đăng ký ca làm việc cho Tuần hiện tại hoặc Tuần tiếp theo từ PWA
    if (String(data.action || "") === "registerPGShift") {
      return _jsonOut(_dangKyCaLamViecPG(ss, data));
    }

    // Nhánh 2: Nhân viên / PG gửi check-in + ảnh minh chứng từ PWA
    const hoTen = String(data.hoTen || "").trim();
    const nhom = String(data.nhom || "PG").trim();
    const boPhan = String(data.boPhan || "").trim();
    const tuyen = String(data.tuyen || "").trim();
    const diaDiem = String(data.diaDiem || "").trim();
    const ghiChu = String(data.ghiChu || "").trim();
    const lat = Number(data.lat);
    const lng = Number(data.lng);
    const accuracy = Number(data.accuracy || 0);
    const linkMapsInput = String(data.googleMapsUrl || "").trim();
    const imageBase64 = String(data.imageBase64 || "").trim();

    if (!hoTen) {
      return _jsonOut({ ok: false, error: "Vui lòng chọn hoặc nhập họ tên nhân sự." });
    }
    if (!imageBase64) {
      return _jsonOut({ ok: false, error: "Vui lòng chụp hoặc chọn 1 tấm ảnh minh chứng đã phát tờ rơi." });
    }
    const coToaDo = isFinite(lat) && isFinite(lng) && (Math.abs(lat) > 0.001 || Math.abs(lng) > 0.001);
    if (!coToaDo && !linkMapsInput) {
      return _jsonOut({ ok: false, error: "Vui lòng bật GPS lấy vị trí hiện tại hoặc dán link Google Maps." });
    }

    const tz = Session.getScriptTimeZone() || "Asia/Ho_Chi_Minh";
    const now = new Date();
    const thoiGian = Utilities.formatDate(now, tz, "HH:mm dd/MM/yyyy");
    const ngay = Utilities.formatDate(now, tz, "dd/MM/yyyy");
    const thangNam = Utilities.formatDate(now, tz, "yyyy-MM");
    const stampFile = Utilities.formatDate(now, tz, "yyyyMMdd_HHmmss");

    // 1. Lưu ảnh vào Google Drive (DMX_Anh_CheckIn_PhatToRoi/YYYY-MM)
    const cleanB64 = imageBase64.replace(/^data:image\/[a-zA-Z0-9.+-]+;base64,/, "");
    const bytes = Utilities.base64Decode(cleanB64);
    const tenAnToan = hoTen.replace(/[^a-zA-Z0-9À-ỹ _-]/g, "").replace(/\s+/g, "_").slice(0, 32) || "NV";
    const fileName = stampFile + "_" + nhom + "_" + tenAnToan + ".jpg";
    const blob = Utilities.newBlob(bytes, "image/jpeg", fileName);

    const folder = _layThuMucAnh(thangNam);
    const file = folder.createFile(blob);
    file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);

    const fileId = file.getId();
    const driveViewUrl = "https://drive.google.com/file/d/" + fileId + "/view";
    const imageThumbUrl = "https://drive.google.com/thumbnail?id=" + fileId + "&sz=w1000";

    // 2. Ghi dòng mới vào tab "BC-Phát tờ rơi"
    const sh = _damBaoHeaderCheckIn(ss);
    const nextRow = Math.max(2, sh.getLastRow() + 1);
    const stt = nextRow - 1;

    const toaDoText = coToaDo
      ? (lat.toFixed(6) + ", " + lng.toFixed(6) + (accuracy > 0 ? " (±" + Math.round(accuracy) + "m)" : ""))
      : "Theo link Maps";
    const mapsUrl = coToaDo
      ? ("https://www.google.com/maps?q=" + lat.toFixed(6) + "," + lng.toFixed(6))
      : linkMapsInput;

    const rowValues = [[
      stt,
      "'" + thoiGian,
      "'" + ngay,
      nhom,
      hoTen,
      boPhan,
      tuyen || "Chưa chọn tuyến",
      diaDiem || "Tại vị trí GPS",
      "'" + toaDoText,
      mapsUrl,
      driveViewUrl,
      '=IMAGE("' + imageThumbUrl + '")',
      ghiChu
    ]];

    sh.getRange(nextRow, 1, 1, 13).setValues(rowValues);
    sh.getRange(nextRow, 1, 1, 13).setVerticalAlignment("middle").setWrap(true);
    sh.setRowHeight(nextRow, 96);

    return _jsonOut({
      ok: true,
      stt: stt,
      rowNumber: nextRow,
      thoiGian: thoiGian,
      ngay: ngay,
      lat: coToaDo ? lat : null,
      lng: coToaDo ? lng : null,
      toaDo: toaDoText,
      linkMaps: mapsUrl,
      linkDrive: driveViewUrl,
      linkAnh: imageThumbUrl,
      fileId: fileId
    });
  } catch (err) {
    return _jsonOut({ ok: false, error: "Lỗi lưu dữ liệu: " + String(err && err.message ? err.message : err) });
  } finally {
    lock.releaseLock();
  }
}
