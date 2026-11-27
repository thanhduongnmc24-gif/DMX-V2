// ============================================================================
// DMX-V2 — GOOGLE APPS SCRIPT TỔNG HỢP:
// 1. Tối ưu tốc độ chuyển Tuần / Tháng trên sheet "PG" + Dropdown chọn tức thì
// 2. Auto-fill giờ làm việc khi sửa cột CA (onEdit tối ưu)
// 3. Web App API (doGet / doPost) cho ứng dụng PWA Nhân viên Check-in + Upload Ảnh
//    -> Lưu ảnh vào Google Drive (DMX_Anh_CheckIn_PhatToRoi/YYYY-MM)
//    -> Ghi lịch sử + ảnh xem nhanh (=IMAGE) vào tab "BC-Phát tờ rơi"
// ============================================================================

const SHEET_PG = "PG";
const SHEET_NV = "NV";
const SHEET_CHECKIN = "BC-Phát tờ rơi";
const DRIVE_ROOT_FOLDER = "DMX_Anh_CheckIn_PhatToRoi";

const TIME_MAP = {
  "SÁNG": "8h-16h",
  "CHIỀU": "15h-20h",
  "GÃY ( SÁNG VS CHIỀU)": "8h-20h",
  "GÃY (SÁNG VS CHIỀU)": "8h-20h",
  "GÃY": "8h-20h"
};

// Cache nội bộ giảm gọi getActiveSpreadsheet() lặp lại trong cùng lần chạy
function _laySheetPG() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const active = ss.getActiveSheet();
  if (active && active.getName() === SHEET_PG) return active;
  return ss.getSheetByName(SHEET_PG);
}

// ============================================================================
// 1. MENU TIỆN ÍCH & KHỞI TẠO NHANH (DROPDOWN 0ms + HEADER BC-PHÁT TỜ RƠI)
// ============================================================================

function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu("⚡ DMX Tiện ích")
    .addItem("🚀 Tối ưu chọn Tuần/Tháng tức thì + Tạo bảng Check-in", "khoiTaoNhanhBangTinh")
    .addItem("🗑️ Xóa lịch làm việc tuần hiện tại (PG)", "xoaLichLamViec")
    .addToUi();
}

function khoiTaoNhanhBangTinh() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();

  // 1. Gắn dropdown chọn nhanh trực tiếp trên PG!A2 (Tuần 1..6) và PG!B2 (Tháng/Năm) -> đổi 0ms không cần chờ Script!
  const sheetPG = ss.getSheetByName(SHEET_PG);
  if (sheetPG) {
    const ruleTuan = SpreadsheetApp.newDataValidation()
      .requireValueInList(["1", "2", "3", "4", "5", "6"], true)
      .setAllowInvalid(true)
      .build();
    sheetPG.getRange("A2").setDataValidation(ruleTuan);

    const dsThang = [];
    const namHienTai = new Date().getFullYear();
    for (let y = namHienTai - 1; y <= namHienTai + 2; y++) {
      for (let m = 1; m <= 12; m++) {
        dsThang.push((m < 10 ? "0" + m : "" + m) + "/" + y);
      }
    }
    const ruleThang = SpreadsheetApp.newDataValidation()
      .requireValueInList(dsThang, true)
      .setAllowInvalid(true)
      .build();
    sheetPG.getRange("B2").setNumberFormat("@").setDataValidation(ruleThang);
  }

  // 2. Đảm bảo sheet "BC-Phát tờ rơi" có đủ tiêu đề chuẩn đẹp
  _damBaoHeaderCheckIn(ss);
  return "OK";
}

// ============================================================================
// 2. XÓA LỊCH & CHUYỂN THÁNG / TUẦN (TỐI ƯU TỐC ĐỘ GẤP 2-3 LẦN)
// ============================================================================

function xoaLichLamViec() {
  const sheet = _laySheetPG();
  if (!sheet) return;
  // Xóa hàng loạt 1 lần (dòng nhân viên 7 -> 27: cột CA/TIME C7:P27 và Điểm Danh S7:S27)
  sheet.getRangeList(["C7:P27", "S7:S27"]).clearContent();
}

function prevMonth() {
  changeMonth(-1);
}

function nextMonth() {
  changeMonth(1);
}

function changeMonth(delta) {
  const sheet = _laySheetPG();
  if (!sheet) return;

  const cell = sheet.getRange("B2");
  const cache = CacheService.getDocumentCache();
  const cacheKey = "dmx_pg_b2";

  // Đọc trực tiếp ô B2 (chỉ 1 lần đọc getValue thay vì getDisplayValue + setNumberFormat)
  const raw = cell.getValue();
  let rawStr = "";
  if (raw instanceof Date) {
    rawStr = Utilities.formatDate(raw, Session.getScriptTimeZone(), "MM/yyyy");
  } else {
    rawStr = String(raw || "").trim();
  }
  if (!rawStr) {
    rawStr = cache.get(cacheKey) || Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "MM/yyyy");
  }

  const parts = rawStr.split("/");
  if (parts.length !== 2) return;

  let month = parseInt(parts[0], 10);
  let year = parseInt(parts[1], 10);
  if (isNaN(month) || isNaN(year)) return;

  month += delta;
  if (month < 1) {
    month = 12;
    year -= 1;
  } else if (month > 12) {
    month = 1;
    year += 1;
  }

  const formatted = (month < 10 ? "0" + month : "" + month) + "/" + year;
  // Dùng dấu nháy đơn "'" ở đầu để ép lưu văn bản MM/yyyy trong ĐÚNG 1 lần gọi setValue (bỏ RPC setNumberFormat thừa)
  cell.setValue("'" + formatted);
  cache.put(cacheKey, formatted, 300);
}

function prevWeek() {
  changeWeek(-1);
}

function nextWeek() {
  changeWeek(1);
}

function changeWeek(delta) {
  const sheet = _laySheetPG();
  if (!sheet) return;

  const cell = sheet.getRange("A2");
  const cur = parseInt(cell.getValue(), 10);
  const oldWeek = isNaN(cur) ? 1 : cur;
  let newWeek = oldWeek + delta;
  if (newWeek < 1) newWeek = 1;
  if (newWeek > 6) newWeek = 6;

  // Thoát ngay không ghi thừa nếu đã ở biên Tuần 1 hoặc Tuần 6
  if (newWeek === oldWeek) return;
  cell.setValue(newWeek);
}

// ============================================================================
// 3. TỰ ĐIỀN KHUNG GIỜ KHI SỬA CỘT CA TRÊN SHEET "PG"
// ============================================================================

function onEdit(e) {
  if (!e || !e.range) return;
  const range = e.range;
  const startRow = range.getRow();
  const numRows = range.getNumRows();
  const endRow = startRow + numRows - 1;

  if (endRow < 7 || startRow > 27) return;

  const startCol = range.getColumn();
  const numCols = range.getNumColumns();
  const endCol = startCol + numCols - 1;

  if (endCol < 3 || startCol > 15) return;
  if (numCols === 1 && startCol % 2 === 0) return;

  const sheet = range.getSheet();
  if (sheet.getName() !== SHEET_PG) return;

  if (numRows === 1 && numCols === 1) {
    const ca = e.value ? String(e.value).trim().toUpperCase() : "";
    range.offset(0, 1).setValue(TIME_MAP[ca] || "");
    return;
  }

  const validStartRow = Math.max(startRow, 7);
  const validEndRow = Math.min(endRow, 27);
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

// ============================================================================
// 4. WEB APP API CHO PWA CHECK-IN & UPLOAD ẢNH PHÁT TỜ RƠI
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

  // Đọc PG từ sheet "PG" (A7:B40)
  const shPG = ss.getSheetByName(SHEET_PG);
  if (shPG) {
    const lastRow = Math.min(Math.max(shPG.getLastRow(), 27), 50);
    const vals = shPG.getRange(7, 1, lastRow - 6, 2).getValues();
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

  // Đọc NV từ sheet "NV" (A3:C60)
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

function _docCheckInGanNhat(ss, limit) {
  const sh = ss.getSheetByName(SHEET_CHECKIN);
  if (!sh) return [];
  const lastRow = sh.getLastRow();
  if (lastRow < 2) return [];

  const count = Math.min(limit || 40, lastRow - 1);
  const startRow = lastRow - count + 1;
  const vals = sh.getRange(startRow, 1, count, 13).getDisplayValues();
  const formulas = sh.getRange(startRow, 12, count, 1).getFormulas();
  const kq = [];

  for (let i = vals.length - 1; i >= 0; i--) {
    const r = vals[i];
    const f = String(formulas[i][0] || "");
    const imgMatch = f.match(/IMAGE\("([^"]+)"/i);
    const thumbUrl = imgMatch ? imgMatch[1] : "";
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
      linkMaps: r[9],
      linkDrive: r[10],
      linkAnh: thumbUrl || r[10],
      ghiChu: r[12]
    });
  }
  return kq;
}

function _layThuMucAnh(thangNam) {
  const roots = DriveApp.getFoldersByName(DRIVE_ROOT_FOLDER);
  const rootFolder = roots.hasNext() ? roots.next() : DriveApp.createFolder(DRIVE_ROOT_FOLDER);
  const subs = rootFolder.getFoldersByName(thangNam);
  return subs.hasNext() ? subs.next() : rootFolder.createFolder(thangNam);
}

function doGet(e) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const action = (e && e.parameter && e.parameter.action) ? String(e.parameter.action) : "init";

    if (action === "ping") {
      return _jsonOut({ ok: true, time: new Date().toISOString(), sheetName: ss.getName() });
    }

    const nhanSu = _docDanhSachNhanSu(ss);
    const lichSu = _docCheckInGanNhat(ss, 40);

    // Đọc thông tin tuần đang mở trên tab PG
    let tuanHienTai = "";
    const shPG = ss.getSheetByName(SHEET_PG);
    if (shPG) {
      const a2 = shPG.getRange("A2").getDisplayValue();
      const b2 = shPG.getRange("B2").getDisplayValue();
      const d1 = shPG.getRange("C4").getDisplayValue();
      const d2 = shPG.getRange("O4").getDisplayValue();
      tuanHienTai = ("Tuần " + a2 + " • " + b2 + (d1 && d2 ? " (" + d1 + " – " + d2 + ")" : "")).trim();
    }

    return _jsonOut({
      ok: true,
      tenBangTinh: ss.getName(),
      tuanHienTai: tuanHienTai,
      nhanSu: nhanSu,
      lichSu: lichSu
    });
  } catch (err) {
    return _jsonOut({ ok: false, error: String(err && err.message ? err.message : err) });
  }
}

function doPost(e) {
  const lock = LockService.getScriptLock();
  try {
    if (!lock.tryLock(20000)) {
      return _jsonOut({ ok: false, error: "Hệ thống đang bận lưu lượt check-in khác, vui lòng bấm Gửi lại sau 2 giây." });
    }

    const rawBody = (e && e.postData && e.postData.contents) ? e.postData.contents : "";
    if (!rawBody) {
      return _jsonOut({ ok: false, error: "Không nhận được dữ liệu check-in." });
    }

    const data = JSON.parse(rawBody);
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

    // 1. Lưu ảnh vào Google Drive (thư mục DMX_Anh_CheckIn_PhatToRoi/YYYY-MM)
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
    const ss = SpreadsheetApp.getActiveSpreadsheet();
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
      toaDo: toaDoText,
      linkMaps: mapsUrl,
      linkDrive: driveViewUrl,
      linkAnh: imageThumbUrl
    });
  } catch (err) {
    return _jsonOut({ ok: false, error: "Lỗi lưu check-in: " + String(err && err.message ? err.message : err) });
  } finally {
    lock.releaseLock();
  }
}
