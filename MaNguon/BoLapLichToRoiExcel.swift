import Foundation
import Compression
import UserNotifications

// MARK: - Bộ Đọc File Excel (.xlsx) Thuần Swift (ZIP Central Directory + DEFLATE + XMLParser)

struct BangSheetExcel {
    let tenSheet: String
    let cacDong: [[String]]
}

final class BoDocExcelXLSX {
    enum LoiDocExcel: LocalizedError {
        case khongDocDuocFile
        case khongPhaiFileXLSX
        case khongCoSheetHopLe

        var errorDescription: String? {
            switch self {
            case .khongDocDuocFile: return "Không thể đọc nội dung file Excel đã chọn."
            case .khongPhaiFileXLSX: return "File không đúng định dạng Excel (.xlsx). Vui lòng lưu dưới dạng .xlsx."
            case .khongCoSheetHopLe: return "Không tìm thấy bảng dữ liệu lịch làm việc hợp lệ trong file Excel."
            }
        }
    }

    static func docTatCaSheet(tu url: URL) throws -> [BangSheetExcel] {
        let daMoQuyen = url.startAccessingSecurityScopedResource()
        defer { if daMoQuyen { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url), data.count > 22 else {
            throw LoiDocExcel.khongDocDuocFile
        }

        let mucZip = giaiNenMucZip(tu: data)
        guard !mucZip.isEmpty else {
            throw LoiDocExcel.khongPhaiFileXLSX
        }

        // 1. Đọc sharedStrings.xml (nếu có)
        var chuoiDungChung: [String] = []
        if let ssData = mucZip["xl/sharedStrings.xml"] {
            chuoiDungChung = BoPhanTichSharedStrings().phanTich(data: ssData)
        }

        // 2. Đọc workbook.xml & workbook.xml.rels để lấy đúng tên sheet -> file xml
        var danhSachSheet: [(ten: String, rId: String)] = []
        if let wbData = mucZip["xl/workbook.xml"] {
            danhSachSheet = BoPhanTichWorkbook().phanTich(data: wbData)
        }

        var mapRel: [String: String] = [:]
        if let relData = mucZip["xl/_rels/workbook.xml.rels"] {
            mapRel = BoPhanTichRels().phanTich(data: relData)
        }

        var ketQua: [BangSheetExcel] = []
        for sheet in danhSachSheet {
            guard let target = mapRel[sheet.rId] else { continue }
            let duongDan: String
            if target.hasPrefix("/") {
                duongDan = String(target.dropFirst())
            } else if target.hasPrefix("xl/") {
                duongDan = target
            } else {
                duongDan = "xl/" + target
            }

            guard let sheetData = mucZip[duongDan] else { continue }
            let cacDong = BoPhanTichWorksheet(sharedStrings: chuoiDungChung).phanTich(data: sheetData)
            if !cacDong.isEmpty {
                ketQua.append(BangSheetExcel(tenSheet: sheet.ten, cacDong: cacDong))
            }
        }

        if ketQua.isEmpty {
            throw LoiDocExcel.khongCoSheetHopLe
        }
        return ketQua
    }

    // MARK: Giải nén ZIP qua Central Directory (hỗ trợ cả Data Descriptor & DEFLATE)

    private static func docUInt16LE(_ bytes: [UInt8], _ off: Int) -> Int {
        guard off + 1 < bytes.count else { return 0 }
        return Int(bytes[off]) | (Int(bytes[off + 1]) << 8)
    }

    private static func docUInt32LE(_ bytes: [UInt8], _ off: Int) -> Int {
        guard off + 3 < bytes.count else { return 0 }
        return Int(bytes[off])
            | (Int(bytes[off + 1]) << 8)
            | (Int(bytes[off + 2]) << 16)
            | (Int(bytes[off + 3]) << 24)
    }

    private static func giaiNenMucZip(tu data: Data) -> [String: Data] {
        let bytes = [UInt8](data)
        let n = bytes.count
        guard n >= 22 else { return [:] }

        // Tìm End of Central Directory (0x06054b50) từ cuối file
        let minPos = max(0, n - 65557)
        var eocdPos = -1
        var idx = n - 22
        while idx >= minPos {
            if bytes[idx] == 0x50 && bytes[idx + 1] == 0x4b && bytes[idx + 2] == 0x05 && bytes[idx + 3] == 0x06 {
                eocdPos = idx
                break
            }
            idx -= 1
        }
        guard eocdPos >= 0 else { return [:] }

        let totalEntries = docUInt16LE(bytes, eocdPos + 10)
        let cdOffset = docUInt32LE(bytes, eocdPos + 16)
        guard cdOffset >= 0 && cdOffset < n else { return [:] }

        var ketQua: [String: Data] = [:]
        var pos = cdOffset

        for _ in 0..<totalEntries {
            guard pos + 46 <= n,
                  bytes[pos] == 0x50 && bytes[pos + 1] == 0x4b && bytes[pos + 2] == 0x01 && bytes[pos + 3] == 0x02 else {
                break
            }
            let method = docUInt16LE(bytes, pos + 10)
            let compSize = docUInt32LE(bytes, pos + 20)
            let uncompSize = docUInt32LE(bytes, pos + 24)
            let nameLen = docUInt16LE(bytes, pos + 28)
            let extraLen = docUInt16LE(bytes, pos + 30)
            let commentLen = docUInt16LE(bytes, pos + 32)
            let localOffset = docUInt32LE(bytes, pos + 42)

            guard pos + 46 + nameLen <= n else { break }
            let tenFile = String(bytes: bytes[(pos + 46)..<(pos + 46 + nameLen)], encoding: .utf8) ?? ""
            pos += 46 + nameLen + extraLen + commentLen

            // Chỉ giải nén các file XML cần thiết để tiết kiệm RAM & siêu nhanh
            let canDoc = tenFile == "xl/workbook.xml"
                || tenFile == "xl/_rels/workbook.xml.rels"
                || tenFile == "xl/sharedStrings.xml"
                || (tenFile.hasPrefix("xl/worksheets/") && tenFile.hasSuffix(".xml"))
            guard canDoc else { continue }

            guard localOffset + 30 <= n,
                  bytes[localOffset] == 0x50 && bytes[localOffset + 1] == 0x4b && bytes[localOffset + 2] == 0x03 && bytes[localOffset + 3] == 0x04 else {
                continue
            }
            let localNameLen = docUInt16LE(bytes, localOffset + 26)
            let localExtraLen = docUInt16LE(bytes, localOffset + 28)
            let dataStart = localOffset + 30 + localNameLen + localExtraLen
            let dataEnd = dataStart + compSize
            guard dataStart >= 0 && dataEnd <= n && compSize >= 0 else { continue }

            if method == 0 {
                ketQua[tenFile] = Data(bytes[dataStart..<dataEnd])
            } else if method == 8 {
                let rawComp = Data(bytes[dataStart..<dataEnd])
                if let decompressed = giaiNenRawDeflate(rawComp, kichThuocDuKien: max(uncompSize, compSize * 4)) {
                    ketQua[tenFile] = decompressed
                }
            }
        }

        return ketQua
    }

    private static func giaiNenRawDeflate(_ compressed: Data, kichThuocDuKien: Int) -> Data? {
        guard !compressed.isEmpty else { return Data() }
        var dstCap = max(4096, kichThuocDuKien + 1024)
        for _ in 0..<4 {
            var dst = [UInt8](repeating: 0, count: dstCap)
            let decodedSize: Int = compressed.withUnsafeBytes { srcPtr in
                guard let base = srcPtr.bindMemory(to: UInt8.self).baseAddress else { return 0 }
                return compression_decode_buffer(&dst, dstCap, base, compressed.count, nil, COMPRESSION_ZLIB)
            }
            if decodedSize > 0 && decodedSize < dstCap {
                return Data(dst[0..<decodedSize])
            }
            dstCap *= 4
        }
        return nil
    }
}

// MARK: - XML Parsers cho Workbook, Rels, SharedStrings & Worksheet

private final class BoPhanTichWorkbook: NSObject, XMLParserDelegate {
    private var ds: [(String, String)] = []

    func phanTich(data: Data) -> [(String, String)] {
        ds = []
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return ds
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "sheet" || elementName.hasSuffix(":sheet") {
            let ten = attributeDict["name"] ?? ""
            let rId = attributeDict["r:id"] ?? attributeDict["id"] ?? ""
            if !ten.isEmpty && !rId.isEmpty {
                ds.append((ten, rId))
            }
        }
    }
}

private final class BoPhanTichRels: NSObject, XMLParserDelegate {
    private var map: [String: String] = [:]

    func phanTich(data: Data) -> [String: String] {
        map = [:]
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return map
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "Relationship" || elementName.hasSuffix(":Relationship") {
            if let id = attributeDict["Id"], let target = attributeDict["Target"] {
                map[id] = target
            }
        }
    }
}

private final class BoPhanTichSharedStrings: NSObject, XMLParserDelegate {
    private var ketQua: [String] = []
    private var dangTrongSI = false
    private var dangTrongT = false
    private var chuoiHienTai = ""

    func phanTich(data: Data) -> [String] {
        ketQua = []
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return ketQua
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "si" {
            dangTrongSI = true
            chuoiHienTai = ""
        } else if dangTrongSI && elementName == "t" {
            dangTrongT = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if dangTrongSI && dangTrongT {
            chuoiHienTai += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "t" {
            dangTrongT = false
        } else if elementName == "si" {
            ketQua.append(chuoiHienTai)
            dangTrongSI = false
        }
    }
}

private final class BoPhanTichWorksheet: NSObject, XMLParserDelegate {
    private let sharedStrings: [String]
    private var cacDong: [[String]] = []
    private var dongHienTai: [Int: String] = [:]
    private var maxColDong = -1

    private var kieuO = ""
    private var colO = -1
    private var dangTrongV = false
    private var dangTrongT = false
    private var giaTriO = ""

    init(sharedStrings: [String]) {
        self.sharedStrings = sharedStrings
    }

    func phanTich(data: Data) -> [[String]] {
        cacDong = []
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return cacDong
    }

    private func tachChiSoCot(tu ref: String) -> Int {
        var col = 0
        for ch in ref.uppercased().utf8 {
            if ch >= 65 && ch <= 90 {
                col = col * 26 + Int(ch - 64)
            } else {
                break
            }
        }
        return col - 1
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "row" {
            dongHienTai = [:]
            maxColDong = -1
        } else if elementName == "c" {
            kieuO = attributeDict["t"] ?? ""
            if let ref = attributeDict["r"] {
                colO = tachChiSoCot(tu: ref)
            } else {
                colO = maxColDong + 1
            }
            giaTriO = ""
        } else if elementName == "v" {
            dangTrongV = true
        } else if elementName == "t" {
            dangTrongT = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if dangTrongV || dangTrongT {
            giaTriO += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "v" {
            dangTrongV = false
        } else if elementName == "t" {
            dangTrongT = false
        } else if elementName == "c" {
            guard colO >= 0 && colO < 45 else { return }
            let text: String
            if kieuO == "s", let idx = Int(giaTriO.trimmingCharacters(in: .whitespacesAndNewlines)), idx >= 0 && idx < sharedStrings.count {
                text = sharedStrings[idx]
            } else {
                text = giaTriO
            }
            let sach = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !sach.isEmpty {
                dongHienTai[colO] = sach
                if colO > maxColDong { maxColDong = colO }
            }
        } else if elementName == "row" {
            if maxColDong >= 0 {
                var arr = Array(repeating: "", count: maxColDong + 1)
                for (c, v) in dongHienTai {
                    if c >= 0 && c < arr.count { arr[c] = v }
                }
                cacDong.append(arr)
            }
        }
    }
}

// MARK: - Mô Hình Lịch Làm Việc PG & Nhân Viên Siêu Thị (Cập Nhật Theo Tuần)

enum NhomNhanSuLich: String, Codable {
    case pg = "PG"
    case nhanVien = "NV"
}

struct TrangThaiCaNgay: Codable, Equatable {
    /// 0 = Thứ 2 ... 6 = Chủ nhật
    let thuIndex: Int
    let nhanCaGoc: String
    let gioLamGoc: String
    let ranhSang: Bool
    let ranhChieu: Bool
    let laNghiOff: Bool
}

struct LichTuanMotNguoi: Codable, Equatable {
    let ten: String
    let nganhHang: String
    let nhom: NhomNhanSuLich
    /// 7 ngày: 0 = Thứ 2 ... 6 = Chủ nhật
    let lich7Ngay: [TrangThaiCaNgay]
}

struct KhoiLichTuanExcel: Codable, Equatable {
    let id: String
    let tenSheet: String
    let tenTuan: String
    let nhom: NhomNhanSuLich
    let danhSachNguoi: [LichTuanMotNguoi]
}

// MARK: - Bộ Phân Tích File Excel Lịch Ca (Chuẩn PG 275 QUANG TRUNG.xlsx & File NV Siêu Thị)

final class BoPhanTichLichCaExcel {
    static let tenThu = ["Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7", "Chủ nhật"]

    static func phanTichWorkbook(tu url: URL, nhom: NhomNhanSuLich) throws -> [KhoiLichTuanExcel] {
        let sheets = try BoDocExcelXLSX.docTatCaSheet(tu: url)
        var tatCaKhoi: [KhoiLichTuanExcel] = []

        for sheet in sheets {
            let tenLow = chuanHoa(sheet.tenSheet)
            // Bỏ qua các sheet phụ không phải lịch đi ca (VD: Lịch đứng cửa, ICT CMR/SIM, Trang tính trống)
            if tenLow.contains("dung cua") || tenLow == "ict" || tenLow.contains("truyen thong") {
                continue
            }
            let khoiTrongSheet = tachCacKhoiTuan(trong: sheet, nhom: nhom)
            tatCaKhoi.append(contentsOf: khoiTrongSheet)
        }

        // Nếu không tìm thấy ở các sheet chính, thử quét lại toàn bộ sheet
        if tatCaKhoi.isEmpty {
            for sheet in sheets {
                tatCaKhoi.append(contentsOf: tachCacKhoiTuan(trong: sheet, nhom: nhom))
            }
        }

        return tatCaKhoi
    }

    private static func chuanHoa(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "d")
            .replacingOccurrences(of: "\n", with: " ")
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func nhanDienThuIndex(_ text: String) -> Int? {
        let t = chuanHoa(text)
        if t.contains("thu 2") || t == "t2" || t.hasPrefix("t2 ") { return 0 }
        if t.contains("thu 3") || t == "t3" || t.hasPrefix("t3 ") { return 1 }
        if t.contains("thu 4") || t == "t4" || t.hasPrefix("t4 ") { return 2 }
        if t.contains("thu 5") || t == "t5" || t.hasPrefix("t5 ") { return 3 }
        if t.contains("thu 6") || t == "t6" || t.hasPrefix("t6 ") { return 4 }
        if t.contains("thu 7") || t == "t7" || t.hasPrefix("t7 ") { return 5 }
        if t.contains("chu nhat") || t == "cn" || t.hasPrefix("cn ") { return 6 }
        return nil
    }

    private static func doiSoSerialExcelSangNgay(_ str: String) -> String? {
        guard let num = Double(str.trimmingCharacters(in: .whitespacesAndNewlines)), num > 40000 && num < 55000 else {
            return nil
        }
        var comp = DateComponents()
        comp.year = 1899; comp.month = 12; comp.day = 30
        let cal = Calendar(identifier: .gregorian)
        guard let goc = cal.date(from: comp),
              let d = cal.date(byAdding: .day, value: Int(num), to: goc) else { return nil }
        let df = DateFormatter()
        df.dateFormat = "dd/MM"
        return df.string(from: d)
    }

    private static func tachCacKhoiTuan(trong sheet: BangSheetExcel, nhom: NhomNhanSuLich) -> [KhoiLichTuanExcel] {
        let rows = sheet.cacDong
        guard rows.count >= 4 else { return [] }

        // Tìm tất cả các dòng tiêu đề có ít nhất 4 thứ trong tuần (Thứ 2 ... Thứ 7/CN)
        var viTriHeaderThu: [(rowIdx: Int, cotTheoThu: [Int: Int])] = []
        for (rIdx, row) in rows.enumerated() {
            var mapThu: [Int: Int] = [:]
            for (cIdx, val) in row.enumerated() {
                if let thu = nhanDienThuIndex(val), mapThu[thu] == nil {
                    mapThu[thu] = cIdx
                }
            }
            if mapThu.count >= 4 {
                viTriHeaderThu.append((rIdx, mapThu))
            }
        }

        var ketQua: [KhoiLichTuanExcel] = []

        for (bIdx, hdr) in viTriHeaderThu.enumerated() {
            let startRow = hdr.rowIdx
            let endRow = (bIdx + 1 < viTriHeaderThu.count) ? min(viTriHeaderThu[bIdx + 1].rowIdx - 1, startRow + 40) : min(rows.count - 1, startRow + 40)

            // Xác định vùng cột cho từng thứ (từ cột của Thứ đó đến trước cột của Thứ tiếp theo)
            let thuSapXep = hdr.cotTheoThu.sorted { $0.value < $1.value }
            var vungCotTheoThu: [Int: Range<Int>] = [:]
            for (k, pair) in thuSapXep.enumerated() {
                let cStart = pair.value
                let cEnd = (k + 1 < thuSapXep.count) ? thuSapXep[k + 1].value : (cStart + 2)
                vungCotTheoThu[pair.key] = cStart..<max(cStart + 1, min(cEnd, cStart + 4))
            }

            // Tìm dòng sub-header (TÊN, CA, TIME...) ngay dưới dòng Thứ 2..CN
            var colTen = 2
            var colNganh = 1
            var dataStartRow = startRow + 1
            if startRow + 1 <= endRow {
                let sub = rows[startRow + 1]
                var laSubHeader = false
                for (c, v) in sub.enumerated() {
                    let lv = chuanHoa(v)
                    if lv == "ten" || lv.contains("ho ten") || lv.contains("ten nv") || lv.contains("ten pg") || lv.contains("nhan vien") {
                        colTen = c
                        laSubHeader = true
                    } else if lv.contains("nganh") || lv.contains("bo phan") || lv.contains("nhom") {
                        colNganh = c
                        laSubHeader = true
                    } else if lv == "ca" || lv == "buoi" || lv == "sang" || lv == "time" {
                        laSubHeader = true
                    }
                }
                if laSubHeader {
                    dataStartRow = startRow + 2
                } else {
                    // Fallback nếu tên cột nằm cùng dòng với Thứ 2
                    for (c, v) in rows[startRow].enumerated() {
                        let lv = chuanHoa(v)
                        if lv == "ten" || lv.contains("ho ten") || lv.contains("nhan vien") {
                            colTen = c
                        }
                    }
                    if colTen >= (thuSapXep.first?.value ?? 2) {
                        colTen = max(0, (thuSapXep.first?.value ?? 2) - 1)
                    }
                }
            }

            // Tìm tên tuần (quét ngược lên 3 dòng trên header để tìm "TUẦN X" hoặc ngày dd/MM)
            var nhanTuan = "Tuần \(bIdx + 1)"
            var ngayDauCuoi: [String] = []
            for rCheck in max(0, startRow - 3)...startRow {
                for v in rows[rCheck] {
                    let lv = chuanHoa(v)
                    if lv.contains("tuan ") {
                        nhanTuan = v.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    if let ngayStr = doiSoSerialExcelSangNgay(v) {
                        ngayDauCuoi.append(ngayStr)
                    }
                }
            }
            if let d1 = ngayDauCuoi.first, let d2 = ngayDauCuoi.last, d1 != d2 {
                nhanTuan += " (\(d1)–\(d2))"
            }

            // Đọc danh sách nhân sự trong khối tuần này
            var dsNguoi: [LichTuanMotNguoi] = []
            var nganhHienTai = ""
            var soCoDuLieu = 0

            guard dataStartRow <= endRow else { continue }
            for r in dataStartRow...endRow {
                let row = rows[r]
                if colNganh < row.count {
                    let ng = row[colNganh].replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                    if !ng.isEmpty && !chuanHoa(ng).contains("lich di ca") && !chuanHoa(ng).contains("ngay") {
                        nganhHienTai = ng
                    }
                }
                guard colTen < row.count else { continue }
                let tenRaw = row[colTen].trimmingCharacters(in: .whitespacesAndNewlines)
                let tenLow = chuanHoa(tenRaw)
                if tenRaw.isEmpty || tenLow == "ten" || tenLow.contains("tong") || tenLow.contains("lich di ca") || tenLow.contains("nganh") {
                    continue
                }

                var lich7: [TrangThaiCaNgay] = []
                var nguoiCoLich = false

                for thu in 0..<7 {
                    guard let rangeCol = vungCotTheoThu[thu] else {
                        lich7.append(TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: "", gioLamGoc: "", ranhSang: false, ranhChieu: false, laNghiOff: true))
                        continue
                    }
                    var cacO: [String] = []
                    for c in rangeCol where c < row.count {
                        let s = row[c].trimmingCharacters(in: .whitespacesAndNewlines)
                        if !s.isEmpty { cacO.append(s) }
                    }
                    let trangThai = phanTichCaMotNgay(thu: thu, cacGiaTri: cacO)
                    if !trangThai.nhanCaGoc.isEmpty || !trangThai.gioLamGoc.isEmpty {
                        nguoiCoLich = true
                    }
                    lich7.append(trangThai)
                }

                if nguoiCoLich { soCoDuLieu += 1 }
                dsNguoi.append(LichTuanMotNguoi(ten: tenRaw, nganhHang: nganhHienTai, nhom: nhom, lich7Ngay: lich7))
            }

            if !dsNguoi.isEmpty && soCoDuLieu >= 2 {
                let idKhoi = "\(sheet.tenSheet)_\(bIdx)_\(nhom.rawValue)"
                ketQua.append(KhoiLichTuanExcel(
                    id: idKhoi,
                    tenSheet: sheet.tenSheet.trimmingCharacters(in: .whitespacesAndNewlines),
                    tenTuan: nhanTuan,
                    nhom: nhom,
                    danhSachNguoi: dsNguoi
                ))
            }
        }

        return ketQua
    }

    /// Phân tích ca làm việc 1 ngày để xác định chắc chắn buổi Rảnh Sáng / Rảnh Chiều (KHÔNG trùng ca!)
    private static func phanTichCaMotNgay(thu: Int, cacGiaTri: [String]) -> TrangThaiCaNgay {
        guard !cacGiaTri.isEmpty else {
            return TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: "", gioLamGoc: "", ranhSang: false, ranhChieu: false, laNghiOff: true)
        }

        let gop = cacGiaTri.joined(separator: " ")
        let low = chuanHoa(gop)
        let nhanCa = cacGiaTri.first ?? ""
        let gioLam = cacGiaTri.count > 1 ? cacGiaTri.dropFirst().joined(separator: " ") : ""

        // 1. Nghỉ OFF / Phép / Đi siêu thị khác (ST #, NVL, 661, NĐC, CC, họp...) -> không xếp phát tờ rơi
        let laOff = low.contains("off") || low.contains("phep") || low.contains("st #")
            || low.contains("st#") || low.contains("nvl") || low.contains("hop")
            || low.contains("team building") || low == "cc" || low == "ndc"
        if laOff {
            return TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: nhanCa, gioLamGoc: gioLam, ranhSang: false, ranhChieu: false, laNghiOff: true)
        }

        // 2. Ca gãy / Hành chính cả ngày / Làm cả Sáng & Chiều (VD: 8h-20h, 9h-20h, "GÃY (SÁNG VS CHIỀU)") -> bận cả ngày!
        let coSang = low.contains("sang")
        let coChieu = low.contains("chieu")
        let laGay = low.contains("gay") || (coSang && coChieu) || low.contains("ca ngay") || low.contains("full")
        if laGay {
            return TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: nhanCa, gioLamGoc: gioLam, ranhSang: false, ranhChieu: false, laNghiOff: false)
        }

        // 3. Phân tích khung giờ cụ thể nếu có (VD: 8h-16h, 9h-16h30, 14h-20h, 15-21h, 8h-20h)
        if let (gioBatDau, gioKetThuc) = tachKhungGio(low) {
            // Nếu làm kéo dài từ sáng tới tối (>= 18h mà bắt đầu <= 11h) -> bận cả ngày
            if gioBatDau <= 11.5 && gioKetThuc >= 18.0 {
                return TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: nhanCa, gioLamGoc: gioLam, ranhSang: false, ranhChieu: false, laNghiOff: false)
            }
            // Vào ca từ 12h trở đi (ca Chiều) -> RẢNH BUỔI SÁNG (06:30 - 09:30)
            if gioBatDau >= 12.0 {
                return TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: nhanCa, gioLamGoc: gioLam, ranhSang: true, ranhChieu: false, laNghiOff: false)
            }
            // Tan ca trước hoặc bằng 16h45 (ca Sáng) -> RẢNH BUỔI CHIỀU (16:45 - 18:30)
            if gioKetThuc <= 16.75 {
                return TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: nhanCa, gioLamGoc: gioLam, ranhSang: false, ranhChieu: true, laNghiOff: false)
            }
            // Trường hợp tan ca 17h -> vẫn bận chiều sớm
            return TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: nhanCa, gioLamGoc: gioLam, ranhSang: false, ranhChieu: false, laNghiOff: false)
        }

        // 4. Nếu không ghi giờ rõ, dựa theo chữ CA:
        if coChieu {
            // Làm ca Chiều tại siêu thị -> Rảnh Sáng để đi phát tờ rơi
            return TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: nhanCa, gioLamGoc: gioLam, ranhSang: true, ranhChieu: false, laNghiOff: false)
        }
        if coSang {
            // Làm ca Sáng tại siêu thị -> Rảnh Chiều sau ca để đi phát tờ rơi
            return TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: nhanCa, gioLamGoc: gioLam, ranhSang: false, ranhChieu: true, laNghiOff: false)
        }
        if low.contains("hanh chinh") || low == "hc" {
            // Hành chính thường 8h30-17h -> tránh trùng
            return TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: nhanCa, gioLamGoc: gioLam, ranhSang: false, ranhChieu: false, laNghiOff: false)
        }

        return TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: nhanCa, gioLamGoc: gioLam, ranhSang: false, ranhChieu: false, laNghiOff: false)
    }

    private static func tachKhungGio(_ text: String) -> (Double, Double)? {
        // Khớp các dạng: "9h-16h", "8h30-16h30", "15-21h", "14:00-20:00", "9g-16h30", "8h 16h"
        let pattern = #"(\d{1,2})(?:[:hg](\d{1,2}))?\s*[-–/]\s*(\d{1,2})(?:[:hg](\d{1,2}))?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }

        func layInt(_ idx: Int) -> Int? {
            let r = match.range(at: idx)
            guard r.location != NSNotFound, let sr = Range(r, in: text) else { return nil }
            return Int(text[sr])
        }

        guard let h1 = layInt(1), let h2 = layInt(3) else { return nil }
        let m1 = layInt(2) ?? 0
        let m2 = layInt(4) ?? 0
        guard h1 >= 5 && h1 <= 23 && h2 >= 6 && h2 <= 23 else { return nil }

        // Xử lý kiểu ghi "3h30-20h" (tức 15h30-20h)
        let h1Chuan = (h1 < 6 && h2 >= 18) ? (h1 + 12) : h1
        let start = Double(h1Chuan) + Double(m1) / 60.0
        let end = Double(h2) + Double(m2) / 60.0
        guard end > start else { return nil }
        return (start, end)
    }
}

// MARK: - Bộ Lập Ma Trận Phát Tờ Rơi Xoay Vòng & Nhắc Tuyến Chưa Phát

struct TuyenPhatToRoiMaTran: Codable, Equatable {
    let id: String
    var ten: String
    var moTaDiemNong: String
    var soDiemNong: Int
}

struct OMaTranPhatToRoi: Codable, Equatable {
    let id: String
    /// 0 = Thứ 2 ... 6 = Chủ nhật
    let thuIndex: Int
    /// "Sáng" hoặc "Chiều"
    let buoi: String
    let tuyenId: String
    let tenTuyen: String
    let moTaTuyen: String
    let danhSachPG: [String]
    let danhSachNV: [String]
    var daPhat: Bool
}

struct KeHoachMaTranTuan: Codable, Equatable {
    let khoaTuan: String
    let nhanTuan: String
    var cacTuyen: [TuyenPhatToRoiMaTran]
    var cacO: [OMaTranPhatToRoi]
    var tenNguonPG: String
    var tenNguonNV: String
}

final class KhoMaTranPhatToRoi {
    static let dungChung = KhoMaTranPhatToRoi()
    private init() {}

    private let khoaKeHoach = "dmx_matran_toroi_tuan_v1"
    private let khoaLichPG = "dmx_lich_pg_excel_v1"
    private let khoaLichNV = "dmx_lich_nv_excel_v1"
    private let khoaNhacChuNhat = "dmx_nhac_cn_dangky_lich_v1"

    func taiKeHoach() -> KeHoachMaTranTuan? {
        guard let data = UserDefaults.standard.data(forKey: khoaKeHoach) else { return nil }
        return try? JSONDecoder().decode(KeHoachMaTranTuan.self, from: data)
    }

    func luuKeHoach(_ kh: KeHoachMaTranTuan) {
        if let data = try? JSONEncoder().encode(kh) {
            UserDefaults.standard.set(data, forKey: khoaKeHoach)
        }
    }

    func taiKhoiPG() -> KhoiLichTuanExcel? {
        guard let data = UserDefaults.standard.data(forKey: khoaLichPG) else { return nil }
        return try? JSONDecoder().decode(KhoiLichTuanExcel.self, from: data)
    }

    func luuKhoiPG(_ khoi: KhoiLichTuanExcel?) {
        if let k = khoi, let data = try? JSONEncoder().encode(k) {
            UserDefaults.standard.set(data, forKey: khoaLichPG)
        } else {
            UserDefaults.standard.removeObject(forKey: khoaLichPG)
        }
    }

    func taiKhoiNV() -> KhoiLichTuanExcel? {
        guard let data = UserDefaults.standard.data(forKey: khoaLichNV) else { return nil }
        return try? JSONDecoder().decode(KhoiLichTuanExcel.self, from: data)
    }

    func luuKhoiNV(_ khoi: KhoiLichTuanExcel?) {
        if let k = khoi, let data = try? JSONEncoder().encode(k) {
            UserDefaults.standard.set(data, forKey: khoaLichNV)
        } else {
            UserDefaults.standard.removeObject(forKey: khoaLichNV)
        }
    }

    var dangBatNhacChuNhat: Bool {
        get { UserDefaults.standard.bool(forKey: khoaNhacChuNhat) }
        set { UserDefaults.standard.set(newValue, forKey: khoaNhacChuNhat) }
    }

    /// Bật / tắt thông báo định kỳ 18:00 Chủ nhật hằng tuần để đăng ký lịch tuần tiếp theo
    func capNhatNhacChuNhatHangTuan(bat: Bool, hoanThanh: @escaping (Bool, String) -> Void) {
        let center = UNUserNotificationCenter.current()
        let idTB = "dmx_nhac_dang_ky_lich_tuan_chu_nhat"
        if !bat {
            center.removePendingNotificationRequests(withIdentifiers: [idTB])
            dangBatNhacChuNhat = false
            DispatchQueue.main.async { hoanThanh(false, "Đã tắt nhắc lịch Chủ nhật hằng tuần.") }
            return
        }

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else {
                DispatchQueue.main.async {
                    hoanThanh(false, "Chưa có quyền Thông báo. Vui lòng bật trong Cài đặt iPhone > V2 ĐMX.")
                }
                return
            }
            let content = UNMutableNotificationContent()
            content.title = "📅 Nhắc đăng ký lịch phát tờ rơi tuần tới"
            content.body = "Hôm nay là Chủ nhật! Hãy nhập file Excel lịch ca PG & Nhân viên tuần tiếp theo để phân ma trận phát tờ rơi không trùng ca."
            content.sound = .default

            var dc = DateComponents()
            dc.weekday = 1 // Chủ nhật
            dc.hour = 18
            dc.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            let req = UNNotificationRequest(identifier: idTB, content: content, trigger: trigger)

            center.removePendingNotificationRequests(withIdentifiers: [idTB])
            center.add(req) { err in
                DispatchQueue.main.async {
                    if let err = err {
                        hoanThanh(false, "Không thể đặt nhắc lịch: \(err.localizedDescription)")
                    } else {
                        self.dangBatNhacChuNhat = true
                        hoanThanh(true, "Đã bật nhắc định kỳ 18:00 Chủ nhật hằng tuần để cập nhật lịch tuần tiếp theo.")
                    }
                }
            }
        }
    }
}

final class BoLapMaTranToRoiXoayVong {
    /// Tự động chia các địa điểm nóng đã quét (Chợ, Trường, Đối thủ) thành 4–6 tuyến theo hướng địa lý quanh siêu thị
    static func taoCacTuyenTuKetQuaQuet(
        tamLat: Double,
        tamLon: Double,
        danhSach: [DiaDiemQuet]
    ) -> [TuyenPhatToRoiMaTran] {
        let diemNong = danhSach.filter { $0.loai != .heThongMWG }
        guard !diemNong.isEmpty else {
            return [
                TuyenPhatToRoiMaTran(id: "tuyen_1", ten: "Tuyến 1 (Khu Đông - Chợ & Trường)", moTaDiemNong: "Quét bản đồ để tự động lấy điểm nóng", soDiemNong: 0),
                TuyenPhatToRoiMaTran(id: "tuyen_2", ten: "Tuyến 2 (Khu Tây - Khu dân cư)", moTaDiemNong: "Quét bản đồ để tự động lấy điểm nóng", soDiemNong: 0),
                TuyenPhatToRoiMaTran(id: "tuyen_3", ten: "Tuyến 3 (Khu Nam - Trục đối thủ)", moTaDiemNong: "Quét bản đồ để tự động lấy điểm nóng", soDiemNong: 0),
                TuyenPhatToRoiMaTran(id: "tuyen_4", ten: "Tuyến 4 (Khu Bắc - Trường học)", moTaDiemNong: "Quét bản đồ để tự động lấy điểm nóng", soDiemNong: 0)
            ]
        }

        // Gom thành 4 hướng (Đông Bắc, Đông Nam, Tây Nam, Tây Bắc) so với tâm siêu thị
        let tenHuong = ["Đông Bắc", "Đông Nam", "Tây Nam", "Tây Bắc"]
        var nhomHuong: [[DiaDiemQuet]] = [[], [], [], []]

        for d in diemNong {
            let dLat = d.viDo - tamLat
            let dLon = d.kinhDo - tamLon
            let idx: Int
            if dLat >= 0 && dLon >= 0 { idx = 0 }
            else if dLat < 0 && dLon >= 0 { idx = 1 }
            else if dLat < 0 && dLon < 0 { idx = 2 }
            else { idx = 3 }
            nhomHuong[idx].append(d)
        }

        var ketQua: [TuyenPhatToRoiMaTran] = []
        var stt = 1
        for (i, ds) in nhomHuong.enumerated() where !ds.isEmpty {
            let uuTien = ds.sorted { a, b in
                if a.loai.diemUuTienToRoi != b.loai.diemUuTienToRoi {
                    return a.loai.diemUuTienToRoi > b.loai.diemUuTienToRoi
                }
                return a.khoangCachMet < b.khoangCachMet
            }
            let topTen = uuTien.prefix(3).map { $0.ten }.joined(separator: ", ")
            let soCho = ds.filter { $0.loai == .cho }.count
            let soTH = ds.filter { $0.loai == .truongHoc }.count
            let soDT = ds.filter { $0.loai == .doiThu }.count
            let chiTiet = "\(topTen) (\(soCho) chợ, \(soTH) trường, \(soDT) đối thủ)"

            ketQua.append(TuyenPhatToRoiMaTran(
                id: "tuyen_huong_\(i)",
                ten: "Tuyến \(stt) — Hướng \(tenHuong[i])",
                moTaDiemNong: chiTiet,
                soDiemNong: ds.count
            ))
            stt += 1
        }

        // Nếu có ít hơn 2 hướng nhưng nhiều điểm, chia thêm theo khoảng cách Gần / Xa
        if ketQua.count == 1 && diemNong.count >= 4 {
            let sorted = diemNong.sorted { $0.khoangCachMet < $1.khoangCachMet }
            let mid = sorted.count / 2
            let gan = Array(sorted[0..<mid])
            let xa = Array(sorted[mid...])
            return [
                TuyenPhatToRoiMaTran(
                    id: "tuyen_gan",
                    ten: "Tuyến 1 — Vành đai gần siêu thị",
                    moTaDiemNong: gan.prefix(3).map { $0.ten }.joined(separator: ", "),
                    soDiemNong: gan.count
                ),
                TuyenPhatToRoiMaTran(
                    id: "tuyen_xa",
                    ten: "Tuyến 2 — Vành đai mở rộng",
                    moTaDiemNong: xa.prefix(3).map { $0.ten }.joined(separator: ", "),
                    soDiemNong: xa.count
                )
            ]
        }

        return ketQua
    }

    /// Lập Ma trận xoay vòng Thứ 2 → Chủ nhật (Sáng & Chiều) dựa trên lịch ca PG + NV để TUYỆT ĐỐI KHÔNG TRÙNG CA!
    static func lapMaTranTuan(
        cacTuyen: [TuyenPhatToRoiMaTran],
        khoiPG: KhoiLichTuanExcel?,
        khoiNV: KhoiLichTuanExcel?,
        giuTrangThaiCu: KeHoachMaTranTuan? = nil
    ) -> KeHoachMaTranTuan {
        let tuyenHopLe = cacTuyen.isEmpty
            ? [TuyenPhatToRoiMaTran(id: "t1", ten: "Tuyến 1", moTaDiemNong: "Chưa quét bản đồ", soDiemNong: 0)]
            : cacTuyen

        // Tính tuần sắp tới / tuần hiện tại (Chủ nhật đăng ký cho tuần tiếp theo!)
        let (khoaTuan, nhanTuanMacDinh) = tinhKhoaVaNhanTuan()
        let nhanTuan: String
        if let p = khoiPG {
            nhanTuan = "\(p.tenTuan) • \(p.tenSheet)"
        } else if let nv = khoiNV {
            nhanTuan = "\(nv.tenTuan) • \(nv.tenSheet)"
        } else {
            nhanTuan = nhanTuanMacDinh
        }

        // Bộ đếm số buổi đã phân để xoay vòng công bằng giữa tất cả PG và NV
        var demBuoiPG: [String: Int] = [:]
        var demBuoiNV: [String: Int] = [:]
        var trangThaiCuMap: [String: Bool] = [:]
        if let cu = giuTrangThaiCu, cu.khoaTuan == khoaTuan {
            for o in cu.cacO { trangThaiCuMap[o.id] = o.daPhat }
        }

        var cacO: [OMaTranPhatToRoi] = []
        var chiSoTuyen = 0

        for thu in 0..<7 {
            for buoi in ["Sáng", "Chiều"] {
                let laSang = (buoi == "Sáng")
                let tuyen = tuyenHopLe[chiSoTuyen % tuyenHopLe.count]
                chiSoTuyen += 1

                // Chọn tối đa 2 PG rảnh đúng buổi này (KHÔNG trùng ca làm việc!)
                var pgChon: [String] = []
                if let dsPG = khoiPG?.danhSachNguoi {
                    let ranh = dsPG.filter { nguoi in
                        guard thu < nguoi.lich7Ngay.count else { return false }
                        let ca = nguoi.lich7Ngay[thu]
                        return laSang ? ca.ranhSang : ca.ranhChieu
                    }.sorted { a, b in
                        (demBuoiPG[a.ten] ?? 0) < (demBuoiPG[b.ten] ?? 0)
                    }

                    for p in ranh.prefix(2) {
                        let ca = p.lich7Ngay[thu]
                        let chuThich = ca.gioLamGoc.isEmpty ? ca.nhanCaGoc : "\(ca.nhanCaGoc) \(ca.gioLamGoc)"
                        pgChon.append("\(p.ten) (ca \(chuThich))")
                        demBuoiPG[p.ten, default: 0] += 1
                    }
                }

                // Chọn tối đa 2 NV siêu thị rảnh đúng buổi này (KHÔNG trùng ca làm việc!)
                var nvChon: [String] = []
                if let dsNV = khoiNV?.danhSachNguoi {
                    let ranh = dsNV.filter { nguoi in
                        guard thu < nguoi.lich7Ngay.count else { return false }
                        let ca = nguoi.lich7Ngay[thu]
                        return laSang ? ca.ranhSang : ca.ranhChieu
                    }.sorted { a, b in
                        (demBuoiNV[a.ten] ?? 0) < (demBuoiNV[b.ten] ?? 0)
                    }

                    for nv in ranh.prefix(2) {
                        let ca = nv.lich7Ngay[thu]
                        let chuThich = ca.gioLamGoc.isEmpty ? ca.nhanCaGoc : "\(ca.nhanCaGoc) \(ca.gioLamGoc)"
                        nvChon.append("\(nv.ten) (ca \(chuThich))")
                        demBuoiNV[nv.ten, default: 0] += 1
                    }
                }

                let idO = "\(khoaTuan)_\(thu)_\(buoi)"
                cacO.append(OMaTranPhatToRoi(
                    id: idO,
                    thuIndex: thu,
                    buoi: buoi,
                    tuyenId: tuyen.id,
                    tenTuyen: tuyen.ten,
                    moTaTuyen: tuyen.moTaDiemNong,
                    danhSachPG: pgChon,
                    danhSachNV: nvChon,
                    daPhat: trangThaiCuMap[idO] ?? false
                ))
            }
        }

        return KeHoachMaTranTuan(
            khoaTuan: khoaTuan,
            nhanTuan: nhanTuan,
            cacTuyen: tuyenHopLe,
            cacO: cacO,
            tenNguonPG: khoiPG.map { "\($0.tenSheet) - \($0.tenTuan) (\($0.danhSachNguoi.count) PG)" } ?? "Chưa nhập file PG",
            tenNguonNV: khoiNV.map { "\($0.tenSheet) - \($0.tenTuan) (\($0.danhSachNguoi.count) NV)" } ?? "Chưa nhập file NV"
        )
    }

    static func tinhKhoaVaNhanTuan(ngay: Date = Date()) -> (String, String) {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Thứ 2 đầu tuần
        let weekday = cal.component(.weekday, from: ngay)
        // Nếu hôm nay là Chủ nhật (weekday == 1) -> mặc định lập cho tuần tiếp theo (bắt đầu Thứ 2 ngày mai)!
        let ngayThamChieu = (weekday == 1) ? (cal.date(byAdding: .day, value: 1, to: ngay) ?? ngay) : ngay
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: ngayThamChieu)
        let thu2 = cal.date(from: comps) ?? ngayThamChieu
        let cn = cal.date(byAdding: .day, value: 6, to: thu2) ?? thu2

        let df = DateFormatter()
        df.dateFormat = "dd/MM"
        let dfKey = DateFormatter()
        dfKey.dateFormat = "yyyy-'W'ww"
        let nhan = "Tuần \(df.string(from: thu2)) – \(df.string(from: cn))"
        return (dfKey.string(from: thu2), nhan)
    }
}
