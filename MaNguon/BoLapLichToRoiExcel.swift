import Foundation
import UIKit
import Compression
import UserNotifications

// MARK: - Bộ Đọc Dữ Liệu Google Trang Tính (.xlsx) Thuần Swift (ZIP Central Directory + DEFLATE + XMLParser)

struct BangSheetExcel {
    let tenSheet: String
    let cacDong: [[String]]
    let biAn: Bool

    init(tenSheet: String, cacDong: [[String]], biAn: Bool = false) {
        self.tenSheet = tenSheet
        self.cacDong = cacDong
        self.biAn = biAn
    }
}

final class BoDocExcelXLSX {
    enum LoiDocExcel: LocalizedError {
        case khongDocDuocFile
        case khongPhaiFileXLSX
        case khongCoSheetHopLe

        var errorDescription: String? {
            switch self {
            case .khongDocDuocFile: return "Không thể đọc dữ liệu từ Google Trang tính."
            case .khongPhaiFileXLSX: return "Dữ liệu tải về không đúng định dạng Google Trang tính (.xlsx)."
            case .khongCoSheetHopLe: return "Không tìm thấy bảng dữ liệu lịch làm việc hợp lệ trong Google Trang tính."
            }
        }
    }

    static func docTatCaSheet(tuData data: Data) throws -> [BangSheetExcel] {
        guard data.count > 22 else {
            throw LoiDocExcel.khongDocDuocFile
        }

        let mucZip = giaiNenMucZip(tu: data)
        guard !mucZip.isEmpty else {
            throw LoiDocExcel.khongPhaiFileXLSX
        }

        var chuoiDungChung: [String] = []
        if let ssData = mucZip["xl/sharedStrings.xml"] {
            chuoiDungChung = BoPhanTichSharedStrings().phanTich(data: ssData)
        }

        var danhSachSheet: [(ten: String, rId: String, biAn: Bool)] = []
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
                ketQua.append(BangSheetExcel(tenSheet: sheet.ten, cacDong: cacDong, biAn: sheet.biAn))
            }
        }

        if ketQua.isEmpty {
            throw LoiDocExcel.khongCoSheetHopLe
        }
        return ketQua
    }

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

// MARK: - XML Parsers

private final class BoPhanTichWorkbook: NSObject, XMLParserDelegate {
    private var ds: [(ten: String, rId: String, biAn: Bool)] = []

    func phanTich(data: Data) -> [(ten: String, rId: String, biAn: Bool)] {
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
            let state = (attributeDict["state"] ?? "").lowercased()
            let biAn = (state == "hidden" || state == "veryhidden")
            if !ten.isEmpty && !rId.isEmpty {
                ds.append((ten: ten, rId: rId, biAn: biAn))
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
            guard colO >= 0 && colO < 200 else { return }
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

// MARK: - Mô Hình Lịch Làm Việc PG & Nhân Viên Siêu Thị (Dùng Người ĐANG LÀM VIỆC Đi Phát Tờ Rơi)

enum NhomNhanSuLich: String, Codable {
    case pg = "PG"
    case nhanVien = "NV"
}

struct TrangThaiCaNgay: Codable, Equatable {
    /// 0 = Thứ 2 ... 6 = Chủ nhật
    let thuIndex: Int
    let nhanCaGoc: String
    let gioLamGoc: String
    /// Đang làm việc ca Sáng tại siêu thị -> có thể điều đi phát tờ rơi buổi Sáng
    let dangLamSang: Bool
    /// Đang làm việc ca Chiều tại siêu thị -> có thể điều đi phát tờ rơi buổi Chiều
    let dangLamChieu: Bool
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
    let ngaySerialSapXep: Int
}

struct KetQuaPhanTichTrangTinhTongHop {
    let dsKhoiPG: [KhoiLichTuanExcel]
    let dsKhoiNV: [KhoiLichTuanExcel]
    let khoiPGMacDinh: KhoiLichTuanExcel?
    let khoiNVMacDinh: KhoiLichTuanExcel?
}

// MARK: - Bộ Phân Tích Lịch Ca PG (CA/TIME) & TEAM NV (Ca 1..Ca 6) Từ 1 Google Trang Tính Duy Nhất

final class BoPhanTichLichCaExcel {
    static let tenThu = ["Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7", "Chủ nhật"]

    /// Phân tích toàn bộ Google Trang tính chứa CẢ tab Lịch PG và tab TEAM NV. (tự động bỏ qua các tab đã ẩn)
    static func phanTichWorkbookTongHop(tuData data: Data) throws -> KetQuaPhanTichTrangTinhTongHop {
        let sheets = try BoDocExcelXLSX.docTatCaSheet(tuData: data)
        return phanTichSheetsTongHop(sheets)
    }

    static func phanTichSheetsTongHop(_ sheets: [BangSheetExcel]) -> KetQuaPhanTichTrangTinhTongHop {
        let sheetHien = sheets.filter { !$0.biAn }
        let danhSachUuTien = sheetHien.isEmpty ? sheets : sheetHien

        var ketQua = docVaPhanLoaiSheets(danhSachUuTien, boQuaSheetPhu: true)
        if ketQua.dsKhoiPG.isEmpty && ketQua.dsKhoiNV.isEmpty && !sheetHien.isEmpty && sheetHien.count < sheets.count {
            ketQua = docVaPhanLoaiSheets(sheets, boQuaSheetPhu: true)
        }
        if ketQua.dsKhoiPG.isEmpty && ketQua.dsKhoiNV.isEmpty {
            ketQua = docVaPhanLoaiSheets(sheets, boQuaSheetPhu: false)
        }
        return ketQua
    }

    private static func docVaPhanLoaiSheets(_ sheets: [BangSheetExcel], boQuaSheetPhu: Bool) -> KetQuaPhanTichTrangTinhTongHop {
        var dsPG: [KhoiLichTuanExcel] = []
        var dsNV: [KhoiLichTuanExcel] = []

        for sheet in sheets {
            let tenLow = chuanHoa(sheet.tenSheet)
            if boQuaSheetPhu {
                if tenLow.contains("muc luc") || tenLow.contains("dung cua") || tenLow.contains("bao cao")
                    || tenLow == "ict" || tenLow.contains("truyen thong")
                    || tenLow.contains("phat to roi") || tenLow.hasPrefix("bc-") || tenLow.hasPrefix("bc ")
                    || tenLow.contains("check in") || tenLow.contains("checkin") {
                    continue
                }
            }

            if laBangCa1DenCa6(sheet) {
                let khoiNV = tachKhoiLichCa1DenCa6(trong: sheet, nhom: .nhanVien)
                dsNV.append(contentsOf: khoiNV)
                continue
            }

            let laSheetTenNV = (tenLow == "nv" || tenLow.contains("team nv") || tenLow.contains("nhan vien") || tenLow.contains("lich nv") || tenLow.contains("nv.") || tenLow.hasSuffix(" nv"))
                && !tenLow.contains("pg")
            if laSheetTenNV {
                let khoiNV = tachCacKhoiTuan(trong: sheet, nhom: .nhanVien)
                dsNV.append(contentsOf: khoiNV)
            } else {
                let khoiPG = tachCacKhoiTuan(trong: sheet, nhom: .pg)
                dsPG.append(contentsOf: khoiPG)
            }
        }

        // Sắp xếp danh sách tuần PG mới nhất lên trên để người dùng dễ đổi tuần
        let dsPGSapXep = dsPG.enumerated().sorted { a, b in
            if a.element.ngaySerialSapXep != b.element.ngaySerialSapXep {
                return a.element.ngaySerialSapXep > b.element.ngaySerialSapXep
            }
            return a.offset > b.offset
        }.map { $0.element }

        let dsNVSapXep = dsNV.enumerated().sorted { a, b in
            if a.element.ngaySerialSapXep != b.element.ngaySerialSapXep {
                return a.element.ngaySerialSapXep > b.element.ngaySerialSapXep
            }
            return a.offset > b.offset
        }.map { $0.element }

        let nvChon = dsNVSapXep.first
        let pgChon = chonKhoiPGPhuHopNhat(dsPG: dsPGSapXep, khoiNV: nvChon)
        return KetQuaPhanTichTrangTinhTongHop(
            dsKhoiPG: dsPGSapXep,
            dsKhoiNV: dsNVSapXep,
            khoiPGMacDinh: pgChon,
            khoiNVMacDinh: nvChon
        )
    }

    private static func chonKhoiPGPhuHopNhat(dsPG: [KhoiLichTuanExcel], khoiNV: KhoiLichTuanExcel?) -> KhoiLichTuanExcel? {
        guard !dsPG.isEmpty else { return nil }

        // 1. Khớp đúng khoảng ngày (dd/MM) với tab TEAM NV. (VD: TEAM NV. 23/11 – 29/11 -> tự chọn TUẦN 4 THÁNG 11 (23/11 – 29/11))
        if let nv = khoiNV {
            let ngayNV = trichTatCaNgayDDMM(trong: nv.tenTuan)
            if ngayNV.count >= 2 {
                let d1 = ngayNV.first!
                let d2 = ngayNV.last!
                if let khopDu = dsPG.first(where: { $0.tenTuan.contains(d1) && $0.tenTuan.contains(d2) }) {
                    return khopDu
                }
            }
            if let d1 = ngayNV.first {
                if let khopDau = dsPG.first(where: { $0.tenTuan.contains(d1) }) {
                    return khopDau
                }
            }
        }

        // 2. Ưu tiên tuần đầy đủ nhân sự (>= 5 người, tránh rơi vào TUẦN CUỐI chỉ có 1 ngày/ít lịch)
        let tuanDayDu = dsPG.filter { $0.danhSachNguoi.count >= 5 }
        let tapXet = tuanDayDu.isEmpty ? dsPG : tuanDayDu

        // 3. Nếu có ngày serial, ưu tiên tuần gần ngày hiện tại nhất (hoặc tuần mới nhất)
        let serialHomNay = tinhSerialExcel(tu: Date())
        if let dangDienRa = tapXet.first(where: { $0.ngaySerialSapXep >= serialHomNay && $0.ngaySerialSapXep <= serialHomNay + 6 }) {
            return dangDienRa
        }
        return tapXet.first
    }

    static func chuanHoa(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "d")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func gonKhoangTrang(_ s: String) -> String {
        s.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func nhanDienThuIndex(_ text: String) -> Int? {
        let t = chuanHoa(text)
        if t.contains("thu 2") || t == "t2" || t.hasPrefix("t2 ") || t.hasPrefix("t2(") { return 0 }
        if t.contains("thu 3") || t == "t3" || t.hasPrefix("t3 ") || t.hasPrefix("t3(") { return 1 }
        if t.contains("thu 4") || t == "t4" || t.hasPrefix("t4 ") || t.hasPrefix("t4(") { return 2 }
        if t.contains("thu 5") || t == "t5" || t.hasPrefix("t5 ") || t.hasPrefix("t5(") { return 3 }
        if t.contains("thu 6") || t == "t6" || t.hasPrefix("t6 ") || t.hasPrefix("t6(") { return 4 }
        if t.contains("thu 7") || t == "t7" || t.hasPrefix("t7 ") || t.hasPrefix("t7(") { return 5 }
        if t.contains("chu nhat") || t == "cn" || t.hasPrefix("cn ") || t.hasPrefix("cn(") { return 6 }
        return nil
    }

    private static func trichTatCaNgayDDMM(trong text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: #"\b(\d{1,2})/(\d{1,2})\b"#) else { return [] }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        var kq: [String] = []
        for m in matches {
            guard let r1 = Range(m.range(at: 1), in: text),
                  let r2 = Range(m.range(at: 2), in: text),
                  let d = Int(text[r1]), let mo = Int(text[r2]),
                  d >= 1 && d <= 31 && mo >= 1 && mo <= 12 else { continue }
            kq.append(String(format: "%02d/%02d", d, mo))
        }
        return kq
    }

    private static func tinhSerialExcel(tu date: Date) -> Int {
        var comp = DateComponents()
        comp.year = 1899; comp.month = 12; comp.day = 30
        let cal = Calendar(identifier: .gregorian)
        guard let goc = cal.date(from: comp) else { return 0 }
        return cal.dateComponents([.day], from: goc, to: date).day ?? 0
    }

    private static func tinhSerialTuDDMM(_ ddmm: String) -> Int {
        let parts = ddmm.split(separator: "/")
        guard parts.count == 2, let d = Int(parts[0]), let m = Int(parts[1]) else { return 0 }
        let cal = Calendar(identifier: .gregorian)
        let nam = cal.component(.year, from: Date())
        var comp = DateComponents()
        comp.year = nam; comp.month = m; comp.day = d
        guard let date = cal.date(from: comp) else { return m * 100 + d }
        return tinhSerialExcel(tu: date)
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

    // MARK: - Nhận Diện & Phân Tích Bảng TEAM NV. (Mỗi Ngày 6 Cột Ca 1..Ca 6)

    private static func trichSoCa(_ text: String) -> Int? {
        let t = chuanHoa(text)
        guard let regex = try? NSRegularExpression(pattern: #"\bca\s*([1-6])\b"#),
              let m = regex.firstMatch(in: t, range: NSRange(t.startIndex..., in: t)),
              let r = Range(m.range(at: 1), in: t),
              let so = Int(t[r]) else { return nil }
        return so
    }

    private static func laBangCa1DenCa6(_ sheet: BangSheetExcel) -> Bool {
        let rows = sheet.cacDong
        guard rows.count >= 3 else { return false }
        let maxScan = min(rows.count, 12)
        for r in 0..<maxScan {
            var mapThu: [Int: Int] = [:]
            for (c, v) in rows[r].enumerated() {
                if let thu = nhanDienThuIndex(v), mapThu[thu] == nil {
                    mapThu[thu] = c
                }
            }
            guard mapThu.count >= 4 else { continue }
            // Kiểm tra hàng tiếp theo hoặc chính hàng đó có nhiều cột "Ca 1".."Ca 6"
            let dongKiemTra = (r + 1 < rows.count) ? rows[r + 1] : rows[r]
            let soOCaSub = dongKiemTra.compactMap { trichSoCa($0) }.count
            let soOCaSame = rows[r].compactMap { trichSoCa($0) }.count
            if soOCaSub >= 6 || soOCaSame >= 6 {
                return true
            }
        }
        return false
    }

    private struct KhungGioMotCaNV {
        let caSo: Int
        let batDau: Double
        let ketThuc: Double
        let chuBatDau: String
        let chuKetThuc: String
    }

    private static func docBangKhungGioCaNV(trong rows: [[String]]) -> [Int: KhungGioMotCaNV] {
        var map: [Int: KhungGioMotCaNV] = [
            1: KhungGioMotCaNV(caSo: 1, batDau: 7.5, ketThuc: 9.0, chuBatDau: "7h30", chuKetThuc: "9h"),
            2: KhungGioMotCaNV(caSo: 2, batDau: 9.0, ketThuc: 12.0, chuBatDau: "9h", chuKetThuc: "12h"),
            3: KhungGioMotCaNV(caSo: 3, batDau: 12.0, ketThuc: 15.0, chuBatDau: "12h", chuKetThuc: "15h"),
            4: KhungGioMotCaNV(caSo: 4, batDau: 15.0, ketThuc: 18.0, chuBatDau: "15h", chuKetThuc: "18h"),
            5: KhungGioMotCaNV(caSo: 5, batDau: 18.0, ketThuc: 21.0, chuBatDau: "18h", chuKetThuc: "21h"),
            6: KhungGioMotCaNV(caSo: 6, batDau: 21.0, ketThuc: 21.5, chuBatDau: "21h", chuKetThuc: "21h30")
        ]

        // Đọc thêm chú thích "CA / Thời Gian" ở cuối sheet nếu siêu thị có thay đổi khung giờ ca
        for r in 0..<(rows.count - 1) {
            let firstCell = chuanHoa(rows[r].first ?? "")
            let nextFirst = chuanHoa(rows[r + 1].first ?? "")
            if firstCell == "ca" && nextFirst.contains("thoi gian") {
                let caRow = rows[r]
                let gioRow = rows[r + 1]
                for c in 1..<min(caRow.count, gioRow.count) {
                    guard let soD = Double(caRow[c].trimmingCharacters(in: .whitespacesAndNewlines)) else { continue }
                    let caSo = Int(soD.rounded())
                    guard caSo >= 1 && caSo <= 6 else { continue }
                    let gioText = gioRow[c].trimmingCharacters(in: .whitespacesAndNewlines)
                    let cacKhung = tachTatCaKhungGio(chuanHoa(gioText))
                    if let k = cacKhung.first {
                        let phan = gioText.components(separatedBy: CharacterSet(charactersIn: "-–"))
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        let sStr = phan.first ?? dinhDangGio(k.0)
                        let eStr = phan.count >= 2 ? phan[1] : dinhDangGio(k.1)
                        map[caSo] = KhungGioMotCaNV(caSo: caSo, batDau: k.0, ketThuc: k.1, chuBatDau: sStr, chuKetThuc: eStr)
                    }
                }
            }
        }
        return map
    }

    private static func dinhDangGio(_ h: Double) -> String {
        let gio = Int(h)
        let phut = Int(((h - Double(gio)) * 60.0).rounded())
        return phut == 0 ? "\(gio)h" : String(format: "%dh%02d", gio, phut)
    }

    private static func dinhDangChuoiCaVaGio(cacCa: [Int], bangGio: [Int: KhungGioMotCaNV]) -> (nhanCa: String, gioLam: String) {
        let sorted = Array(Set(cacCa)).sorted()
        guard !sorted.isEmpty else { return ("OFF", "") }

        // Gom các ca liền kề nhau: VD [1,2,3] -> "Ca 1-3", [1,2,4,5,6] -> "Ca 1-2, 4-6"
        var nhomLienKe: [(Int, Int)] = []
        var s = sorted[0]
        var e = sorted[0]
        for x in sorted.dropFirst() {
            if x == e + 1 {
                e = x
            } else {
                nhomLienKe.append((s, e))
                s = x; e = x
            }
        }
        nhomLienKe.append((s, e))

        let nhanCa = "Ca " + nhomLienKe.map { a, b in a == b ? "\(a)" : "\(a)-\(b)" }.joined(separator: ", ")
        let gioLam = nhomLienKe.compactMap { a, b -> String? in
            guard let gA = bangGio[a], let gB = bangGio[b] else { return nil }
            return "\(gA.chuBatDau)-\(gB.chuKetThuc)"
        }.joined(separator: ", ")
        return (nhanCa, gioLam)
    }

    private static func tachKhoiLichCa1DenCa6(trong sheet: BangSheetExcel, nhom: NhomNhanSuLich) -> [KhoiLichTuanExcel] {
        let rows = sheet.cacDong
        guard rows.count >= 3 else { return [] }

        var headerThuRow = -1
        var mapThu: [Int: Int] = [:]
        for r in 0..<min(rows.count, 12) {
            var tmp: [Int: Int] = [:]
            for (c, v) in rows[r].enumerated() {
                if let thu = nhanDienThuIndex(v), tmp[thu] == nil {
                    tmp[thu] = c
                }
            }
            if tmp.count >= 4 {
                headerThuRow = r
                mapThu = tmp
                break
            }
        }
        guard headerThuRow >= 0 else { return [] }

        let subRowIdx: Int
        let dataStartRow: Int
        if headerThuRow + 1 < rows.count && rows[headerThuRow + 1].compactMap({ trichSoCa($0) }).count >= 6 {
            subRowIdx = headerThuRow + 1
            dataStartRow = headerThuRow + 2
        } else {
            subRowIdx = headerThuRow
            dataStartRow = headerThuRow + 1
        }
        guard dataStartRow < rows.count else { return [] }

        let thuSapXep = mapThu.sorted { $0.value < $1.value }
        let cotThuDauTien = thuSapXep.first?.value ?? 4
        let buocCot = (thuSapXep.count >= 2) ? max(4, thuSapXep[1].value - thuSapXep[0].value) : 6

        let subRow = rows[subRowIdx]
        var colBoPhanFound: Int? = nil
        var colTenFound: Int? = nil
        for (c, v) in subRow.enumerated() where c < cotThuDauTien {
            let lv = chuanHoa(v)
            if colBoPhanFound == nil && (lv.contains("bo phan") || lv.contains("nganh") || lv.contains("nhom")) {
                colBoPhanFound = c
            } else if colTenFound == nil && (lv.contains("ho ten") || lv == "ten" || lv.contains("ten nv") || lv.contains("nhan vien")) {
                colTenFound = c
            }
        }
        let colBoPhan = colBoPhanFound ?? 0
        let colTen = colTenFound ?? min(2, max(0, cotThuDauTien - 1))

        // Ánh xạ cột (Ca 1..Ca 6) cho từng ngày Thứ 2..Chủ nhật
        var mapCotCaTheoThu: [Int: [(caSo: Int, col: Int)]] = [:]
        for (k, pair) in thuSapXep.enumerated() {
            let cStart = pair.value
            let cEnd = (k + 1 < thuSapXep.count) ? thuSapXep[k + 1].value : (cStart + buocCot)
            var dsCap: [(caSo: Int, col: Int)] = []
            for c in cStart..<cEnd {
                let caVal: Int? = (c < subRow.count) ? trichSoCa(subRow[c]) : nil
                let caSo = caVal ?? ((c - cStart) + 1)
                if caSo >= 1 && caSo <= 6 {
                    dsCap.append((caSo: caSo, col: c))
                }
            }
            mapCotCaTheoThu[pair.key] = dsCap
        }

        // Trích khoảng ngày từ dòng tiêu đề Thứ (VD: T2 (23/11) ... CN (29/11))
        var ngayDDMM: [String] = []
        for (_, c) in thuSapXep where c < rows[headerThuRow].count {
            let found = trichTatCaNgayDDMM(trong: rows[headerThuRow][c])
            ngayDDMM.append(contentsOf: found)
        }
        let tenTuan: String
        let serialSapXep: Int
        if let d1 = ngayDDMM.first, let d2 = ngayDDMM.last, d1 != d2 {
            tenTuan = "Tuần \(d1) – \(d2)"
            serialSapXep = tinhSerialTuDDMM(d2)
        } else if let d1 = ngayDDMM.first {
            tenTuan = "Tuần \(d1)"
            serialSapXep = tinhSerialTuDDMM(d1)
        } else {
            tenTuan = gonKhoangTrang(sheet.tenSheet)
            serialSapXep = tinhSerialExcel(tu: Date())
        }

        let bangGioCa = docBangKhungGioCaNV(trong: rows)
        var boPhanHienTai = ""
        var dsNguoi: [LichTuanMotNguoi] = []

        for r in dataStartRow..<rows.count {
            let row = rows[r]
            let oDau = chuanHoa(row.first ?? "")
            if oDau.hasPrefix("note") || oDau.contains("ghi chu") || oDau == "ca" || oDau.contains("thoi gian") {
                break
            }

            if colBoPhan < row.count {
                let bp = gonKhoangTrang(row[colBoPhan])
                let bpLow = chuanHoa(bp)
                if !bp.isEmpty && !bpLow.contains("bo phan") && !bpLow.hasPrefix("note") {
                    boPhanHienTai = bp
                }
            }

            guard colTen < row.count else { continue }
            let tenRaw = gonKhoangTrang(row[colTen])
            let tenLow = chuanHoa(tenRaw)
            if tenRaw.isEmpty || tenLow == "ho ten" || tenLow == "ten" || tenLow.contains("tong") || Double(tenRaw) != nil {
                continue
            }

            var lich7: [TrangThaiCaNgay] = []
            var coItNhatMotCa = false

            for thu in 0..<7 {
                guard let dsCot = mapCotCaTheoThu[thu], !dsCot.isEmpty else {
                    lich7.append(TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: "OFF", gioLamGoc: "", dangLamSang: false, dangLamChieu: false, laNghiOff: true))
                    continue
                }

                var cacCaLam: [Int] = []
                for (caSo, col) in dsCot where col < row.count {
                    let val = row[col].trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !val.isEmpty else { continue }
                    let valLow = chuanHoa(val)
                    if valLow == "0" || valLow == "0.0" || valLow == "-" || valLow.contains("off") || valLow.contains("nghi") || valLow.contains("phep") {
                        continue
                    }
                    // Mọi giá trị giờ làm dương (1.5 / 3.0 / 2.0 / 0.5 / hoặc serial 46143 do Sheets tự đổi 1/5) đều nghĩa là CÓ TRỰC ca này
                    cacCaLam.append(caSo)
                }

                if cacCaLam.isEmpty {
                    lich7.append(TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: "OFF", gioLamGoc: "", dangLamSang: false, dangLamChieu: false, laNghiOff: true))
                } else {
                    coItNhatMotCa = true
                    let (nhanCa, gioLam) = dinhDangChuoiCaVaGio(cacCa: cacCaLam, bangGio: bangGioCa)
                    // Buổi sáng (07:00-09:00): trực Ca 1 (7h30-9h) hoặc Ca 2 (9h-12h)
                    let lamSang = cacCaLam.contains { caSo in
                        guard let g = bangGioCa[caSo] else { return caSo == 1 || caSo == 2 }
                        return g.batDau < 12.0 && g.ketThuc > 7.5
                    }
                    // Buổi chiều (16:30-18:30): trực Ca 4 (15h-18h) hoặc Ca 5 (18h-21h)
                    let lamChieu = cacCaLam.contains { caSo in
                        guard let g = bangGioCa[caSo] else { return caSo == 4 || caSo == 5 }
                        return (g.batDau >= 14.5 && g.batDau < 21.0) || g.ketThuc >= 17.5
                    }
                    lich7.append(TrangThaiCaNgay(
                        thuIndex: thu,
                        nhanCaGoc: nhanCa,
                        gioLamGoc: gioLam,
                        dangLamSang: lamSang,
                        dangLamChieu: lamChieu,
                        laNghiOff: false
                    ))
                }
            }

            if coItNhatMotCa {
                dsNguoi.append(LichTuanMotNguoi(ten: tenRaw, nganhHang: boPhanHienTai, nhom: nhom, lich7Ngay: lich7))
            }
        }

        guard !dsNguoi.isEmpty else { return [] }
        let tenSheetSach = gonKhoangTrang(sheet.tenSheet)
        return [KhoiLichTuanExcel(
            id: "\(tenSheetSach)_ca16_\(nhom.rawValue)",
            tenSheet: tenSheetSach,
            tenTuan: tenTuan,
            nhom: nhom,
            danhSachNguoi: dsNguoi,
            ngaySerialSapXep: serialSapXep
        )]
    }

    // MARK: - Phân Tích Bảng Lịch PG Nhiều Tuần (CA / TIME)

    private static func tachCacKhoiTuan(trong sheet: BangSheetExcel, nhom: NhomNhanSuLich) -> [KhoiLichTuanExcel] {
        let rows = sheet.cacDong
        guard rows.count >= 4 else { return [] }

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
            let endRow = (bIdx + 1 < viTriHeaderThu.count) ? min(viTriHeaderThu[bIdx + 1].rowIdx - 1, startRow + 45) : min(rows.count - 1, startRow + 45)

            let thuSapXep = hdr.cotTheoThu.sorted { $0.value < $1.value }
            var vungCotTheoThu: [Int: Range<Int>] = [:]
            for (k, pair) in thuSapXep.enumerated() {
                let cStart = pair.value
                let cEnd = (k + 1 < thuSapXep.count) ? thuSapXep[k + 1].value : (cStart + 2)
                vungCotTheoThu[pair.key] = cStart..<max(cStart + 1, min(cEnd, cStart + 3))
            }

            let cotThuDauTien = thuSapXep.first?.value ?? 3
            var colTenFound: Int? = nil
            var colNganhFound: Int? = nil
            var dataStartRow = startRow + 1
            if startRow + 1 <= endRow {
                let sub = rows[startRow + 1]
                var laSubHeader = false
                for (c, v) in sub.enumerated() {
                    let lv = chuanHoa(v)
                    if c < cotThuDauTien {
                        if colTenFound == nil && (lv == "ten" || lv.contains("ho ten") || lv.contains("ten nv") || lv.contains("ten pg") || lv.contains("nhan vien")) {
                            colTenFound = c
                            laSubHeader = true
                        } else if colNganhFound == nil && (lv.contains("nganh") || lv.contains("bo phan") || lv.contains("nhom")) {
                            colNganhFound = c
                            laSubHeader = true
                        }
                    }
                    if lv == "ca" || lv == "buoi" || lv == "sang" || lv == "time" {
                        laSubHeader = true
                    }
                }
                if laSubHeader {
                    dataStartRow = startRow + 2
                } else {
                    for (c, v) in rows[startRow].enumerated() where c < cotThuDauTien {
                        let lv = chuanHoa(v)
                        if colTenFound == nil && (lv == "ten" || lv.contains("ho ten") || lv.contains("nhan vien")) {
                            colTenFound = c
                        }
                    }
                }
            }
            let colTen = colTenFound ?? max(0, cotThuDauTien - 1)
            let colNganh = colNganhFound ?? max(0, colTen - 1)

            var nhanTuan = "Tuần \(bIdx + 1)"
            var ngayDauCuoi: [String] = []
            var serialMax = 0
            for rCheck in max(0, startRow - 4)...startRow {
                let dongCheck = rows[rCheck]
                // Hỗ trợ bảng PG chuẩn có hàng trên ghi "Tuần | Tháng/Năm" và hàng kế tiếp ghi số tuần + MM/YYYY (VD: 5.0 | 11/2026)
                if rCheck + 1 < rows.count {
                    var cotTuan: Int? = nil
                    var cotThangNam: Int? = nil
                    for (cIdx, val) in dongCheck.enumerated() {
                        let lv = chuanHoa(gonKhoangTrang(val))
                        if lv == "tuan" { cotTuan = cIdx }
                        else if lv.contains("thang") && lv.contains("nam") { cotThangNam = cIdx }
                    }
                    if let cT = cotTuan {
                        let dongGiaTri = rows[rCheck + 1]
                        let rawTuan = (cT < dongGiaTri.count) ? gonKhoangTrang(dongGiaTri[cT]) : ""
                        let soTuanStr: String = {
                            if let d = Double(rawTuan), d >= 1 && d <= 6 {
                                return "\(Int(d.rounded()))"
                            }
                            return rawTuan
                        }()
                        let rawThang = (cotThangNam != nil && cotThangNam! < dongGiaTri.count)
                            ? gonKhoangTrang(dongGiaTri[cotThangNam!])
                            : ""
                        if !soTuanStr.isEmpty && !rawThang.isEmpty {
                            nhanTuan = "Tuần \(soTuanStr) • \(rawThang)"
                        } else if !soTuanStr.isEmpty {
                            nhanTuan = "Tuần \(soTuanStr)"
                        }
                    }
                }

                for v in dongCheck {
                    let sach = gonKhoangTrang(v)
                    let lv = chuanHoa(sach)
                    if lv.contains("tuan") && lv != "tuan" && !lv.contains("lich di ca") && sach.count <= 32 {
                        nhanTuan = sach
                    }
                    if let num = Double(sach), num > 40000 && num < 55000 {
                        serialMax = max(serialMax, Int(num))
                    }
                    if let ngayStr = doiSoSerialExcelSangNgay(sach) {
                        ngayDauCuoi.append(ngayStr)
                    } else if lv.contains("ngay") || sach.contains("/") {
                        let ddmmList = trichTatCaNgayDDMM(trong: sach)
                        for d in ddmmList {
                            ngayDauCuoi.append(d)
                            serialMax = max(serialMax, tinhSerialTuDDMM(d))
                        }
                    }
                }
            }
            if let d1 = ngayDauCuoi.first, let d2 = ngayDauCuoi.last, d1 != d2 {
                nhanTuan += " (\(d1) – \(d2))"
            } else if let d1 = ngayDauCuoi.first {
                nhanTuan += " (\(d1))"
            }

            var dsNguoi: [LichTuanMotNguoi] = []
            var nganhHienTai = ""
            var soCoDuLieu = 0

            guard dataStartRow <= endRow else { continue }
            for r in dataStartRow...endRow {
                let row = rows[r]
                // Dừng sớm nếu chạm vào tiêu đề của khối tuần tiếp theo
                let o0Low = chuanHoa(row.first ?? "")
                if o0Low.hasPrefix("tuan ") || o0Low == "tuan cuoi" {
                    break
                }
                if colNganh < row.count {
                    let ng = gonKhoangTrang(row[colNganh])
                    let ngLow = chuanHoa(ng)
                    if !ng.isEmpty && !ngLow.contains("lich di ca") && ngLow != "ngay" && !ngLow.contains("nganh hang") {
                        nganhHienTai = ng
                    }
                }
                guard colTen < row.count else { continue }
                let tenRaw = gonKhoangTrang(row[colTen])
                let tenLow = chuanHoa(tenRaw)
                if tenRaw.isEmpty || tenLow == "ten" || tenLow.contains("tong") || tenLow.contains("lich di ca") || tenLow.contains("nganh") {
                    continue
                }

                var lich7: [TrangThaiCaNgay] = []
                var nguoiCoLich = false

                for thu in 0..<7 {
                    guard let rangeCol = vungCotTheoThu[thu] else {
                        lich7.append(TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: "", gioLamGoc: "", dangLamSang: false, dangLamChieu: false, laNghiOff: true))
                        continue
                    }
                    var cacO: [String] = []
                    for c in rangeCol where c < row.count {
                        let s = gonKhoangTrang(row[c])
                        if !s.isEmpty { cacO.append(s) }
                    }
                    let trangThai = phanTichCaMotNgay(thu: thu, cacGiaTri: cacO)
                    if !trangThai.nhanCaGoc.isEmpty || !trangThai.gioLamGoc.isEmpty {
                        nguoiCoLich = true
                    }
                    lich7.append(trangThai)
                }

                if nguoiCoLich {
                    soCoDuLieu += 1
                    dsNguoi.append(LichTuanMotNguoi(ten: tenRaw, nganhHang: nganhHienTai, nhom: nhom, lich7Ngay: lich7))
                }
            }

            if !dsNguoi.isEmpty && soCoDuLieu >= 2 {
                let tenSheetSach = gonKhoangTrang(sheet.tenSheet)
                let idKhoi = "\(tenSheetSach)_\(bIdx)_\(nhom.rawValue)"
                ketQua.append(KhoiLichTuanExcel(
                    id: idKhoi,
                    tenSheet: tenSheetSach,
                    tenTuan: nhanTuan,
                    nhom: nhom,
                    danhSachNguoi: dsNguoi,
                    ngaySerialSapXep: serialMax
                ))
            }
        }

        return ketQua
    }

    /// Phân tích ca làm việc 1 ngày để xác định nhân sự ĐANG LÀM VIỆC buổi Sáng và/hoặc buổi Chiều tại siêu thị
    /// (Nguyên tắc: Chỉ điều động PG/NV ĐANG LÀM VIỆC trong buổi đó đi phát tờ rơi, KHÔNG điều người OFF/ST# hoặc không trực ca buổi đó!)
    static func phanTichCaMotNgay(thu: Int, cacGiaTri: [String]) -> TrangThaiCaNgay {
        guard !cacGiaTri.isEmpty else {
            return TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: "", gioLamGoc: "", dangLamSang: false, dangLamChieu: false, laNghiOff: true)
        }

        let nhanCa = cacGiaTri.first ?? ""
        let gioLam = cacGiaTri.count > 1 ? cacGiaTri.dropFirst().joined(separator: " ") : ""
        let gop = cacGiaTri.joined(separator: " ")
        let low = chuanHoa(gop)
        let lowCa = chuanHoa(nhanCa)
        let lowGio = chuanHoa(gioLam)

        // 1. Trường hợp đặc biệt trong bảng: "sáng/ off chiều" -> đang làm SÁNG, nghỉ chiều
        if lowGio.contains("sang") && lowGio.contains("off chieu") {
            return TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: "SÁNG", gioLamGoc: gioLam, dangLamSang: true, dangLamChieu: false, laNghiOff: false)
        }
        if lowGio.contains("chieu") && lowGio.contains("off sang") {
            return TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: "CHIỀU", gioLamGoc: gioLam, dangLamSang: false, dangLamChieu: true, laNghiOff: false)
        }

        // 2. Nghỉ OFF / Phép / Lễ / Đi siêu thị khác (ST #, NVL, 661, NĐC, CC, họp...) -> KHÔNG có mặt làm việc
        let laOff = lowCa.contains("off") || lowCa.contains("st #") || lowCa.contains("st#")
            || low.contains("phep") || low.contains("off le") || low.contains("off tuan")
            || low.contains("nvl") || low.contains("hop") || low.contains("team building")
            || low == "le" || low == "cc" || low == "ndc"
        if laOff {
            return TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: nhanCa, gioLamGoc: gioLam, dangLamSang: false, dangLamChieu: false, laNghiOff: true)
        }

        // 3. Kiểm tra trực tiếp các khung giờ làm việc thực tế (VD: 9h-16h, 14h-20h, 15-21h, 9g-21h, 15-20g, 8h-11h 15h-20h, 7h30-15h)
        let cacKhungLam = tachTatCaKhungGio(low)
        let laGay = lowCa.contains("gay") || (lowCa.contains("sang") && lowCa.contains("chieu"))

        if !cacKhungLam.isEmpty {
            // Đang làm buổi Sáng: có khung giờ giao với khoảng sáng [07:30 .. 12:00]
            let lamSang = cacKhungLam.contains { (s, e) in s < 12.0 && e > 8.0 }
            // Đang làm buổi Chiều: có khung giờ giao với khoảng chiều [14:00 .. 20:00]
            // Lưu ý: ca Sáng 8h-16h / 9h-16h30 / 8h-17h tan sớm -> chỉ tính buổi Sáng (trừ khi kéo dài >= 17h30 hoặc ghi CHIỀU/GÃY)
            let lamChieuTheoGio = cacKhungLam.contains { (s, e) in
                if s >= 12.5 { return true }
                if e >= 17.5 { return true }
                return false
            }
            let lamChieu = lamChieuTheoGio || laGay || lowCa.contains("chieu")
            return TrangThaiCaNgay(
                thuIndex: thu,
                nhanCaGoc: nhanCa,
                gioLamGoc: gioLam,
                dangLamSang: lamSang || laGay || lowCa.contains("sang"),
                dangLamChieu: lamChieu,
                laNghiOff: false
            )
        }

        // 4. Không có ô giờ TIME -> dựa theo chữ CA (SÁNG / CHIỀU / GÃY / HÀNH CHÍNH)
        if laGay || lowCa.contains("hanh chinh") || lowCa == "hc" || lowCa.contains("ca ngay") || lowCa.contains("full") {
            return TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: nhanCa, gioLamGoc: gioLam, dangLamSang: true, dangLamChieu: true, laNghiOff: false)
        }
        if lowCa.contains("sang") {
            return TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: nhanCa, gioLamGoc: gioLam, dangLamSang: true, dangLamChieu: false, laNghiOff: false)
        }
        if lowCa.contains("chieu") {
            return TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: nhanCa, gioLamGoc: gioLam, dangLamSang: false, dangLamChieu: true, laNghiOff: false)
        }

        return TrangThaiCaNgay(thuIndex: thu, nhanCaGoc: nhanCa, gioLamGoc: gioLam, dangLamSang: false, dangLamChieu: false, laNghiOff: true)
    }

    private static func tachTatCaKhungGio(_ text: String) -> [(Double, Double)] {
        // Hỗ trợ đủ định dạng thực tế: 9h-16h, 9g-21h, 15-20g, 15-20, 7h30-16h, 07:30-15h, 15-21:30, 8h-11h 15h-20h
        let pattern = #"(\d{1,2})(?:\s*[:hg]\s*(\d{1,2})?)?\s*[-–/]\s*(\d{1,4})(?:\s*[:hg]\s*(\d{1,2})?)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        var ketQua: [(Double, Double)] = []

        for match in matches {
            func layInt(_ idx: Int) -> Int? {
                let r = match.range(at: idx)
                guard r.location != NSNotFound, let sr = Range(r, in: text) else { return nil }
                return Int(text[sr])
            }
            guard let h1Raw = layInt(1), let h2Raw = layInt(3) else { continue }
            let m1 = layInt(2) ?? 0
            var h2 = h2Raw
            var m2 = layInt(4) ?? 0

            if h2Raw >= 100 && h2Raw <= 2359 && layInt(4) == nil {
                h2 = h2Raw / 100
                m2 = h2Raw % 100
            }
            guard h1Raw >= 1 && h1Raw <= 23 && h2 >= 6 && h2 <= 23 && m1 < 60 && m2 < 60 else { continue }
            let h1 = (h1Raw < 6 && h2 >= 18) ? (h1Raw + 12) : h1Raw
            let start = Double(h1) + Double(m1) / 60.0
            let end = Double(h2) + Double(m2) / 60.0
            if end > start {
                ketQua.append((start, end))
            }
        }
        return ketQua
    }
}

// MARK: - Bộ Lập Ma Trận Phát Tờ Rơi Xoay Vòng (ĐANG LÀM VIỆC & AI ĐÃ PHÁT KHÔNG PHÁT NỮA)

struct DiemMucTieuTuyen: Codable, Equatable {
    let id: String
    var ten: String
    var diaChi: String
    var loaiRaw: String
    var viDo: Double
    var kinhDo: Double
}

struct BuocChiDanTuyen: Codable, Equatable {
    let stt: Int
    let hanhDong: String
    let noiDung: String
    let khoangCachMet: Double
    let laDiemDung: Bool
}

struct CauHinhPhanTuyenToRoi: Codable, Equatable {
    /// Số PG phân cho mỗi tuyến/buổi (0..5)
    var soPGMoiTuyen: Int = 1
    /// Số NV siêu thị phân cho mỗi tuyến/buổi (0..5)
    var soNVMoiTuyen: Int = 1
    /// Số tuyến chia trên bản đồ: 0 = Tự động chia tuyến theo số nhân sự & số người/tuyến; 2...8 = cố định
    var soTuyenMongMuon: Int = 0
    /// Bán kính kiểm soát hợp lệ khi nhân viên dán vị trí Google Maps (mặc định 300m)
    var nguongKiemSoatMet: Double = 300.0
    /// Bán kính phát tờ rơi riêng (mét): 0 = dùng theo bán kính quét khu vực; >= 200 = giới hạn riêng cho tuyến phát tờ rơi
    var banKinhPhatToRoiMet: Double = 0

    var tongNhanSuMoiTuyen: Int {
        return max(1, soPGMoiTuyen + soNVMoiTuyen)
    }

    func banKinhPhatHieuLuc(banKinhQuetMet: Double) -> Double {
        if banKinhPhatToRoiMet >= 200 {
            return min(20000.0, banKinhPhatToRoiMet)
        }
        return max(200.0, banKinhQuetMet)
    }

    init(
        soPGMoiTuyen: Int = 1,
        soNVMoiTuyen: Int = 1,
        soTuyenMongMuon: Int = 0,
        nguongKiemSoatMet: Double = 300.0,
        banKinhPhatToRoiMet: Double = 0
    ) {
        self.soPGMoiTuyen = max(0, min(5, soPGMoiTuyen))
        self.soNVMoiTuyen = max(0, min(5, soNVMoiTuyen))
        self.soTuyenMongMuon = (soTuyenMongMuon == 0) ? 0 : max(2, min(8, soTuyenMongMuon))
        self.nguongKiemSoatMet = max(50, min(2000, nguongKiemSoatMet))
        self.banKinhPhatToRoiMet = (banKinhPhatToRoiMet <= 0) ? 0 : max(200, min(20000, banKinhPhatToRoiMet))
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        soPGMoiTuyen = max(0, min(5, (try? c.decode(Int.self, forKey: .soPGMoiTuyen)) ?? 1))
        soNVMoiTuyen = max(0, min(5, (try? c.decode(Int.self, forKey: .soNVMoiTuyen)) ?? 1))
        let st = (try? c.decode(Int.self, forKey: .soTuyenMongMuon)) ?? 0
        soTuyenMongMuon = (st == 0) ? 0 : max(2, min(8, st))
        nguongKiemSoatMet = max(50, min(2000, (try? c.decode(Double.self, forKey: .nguongKiemSoatMet)) ?? 300.0))
        let bk = (try? c.decode(Double.self, forKey: .banKinhPhatToRoiMet)) ?? 0
        banKinhPhatToRoiMet = (bk <= 0) ? 0 : max(200, min(20000, bk))
    }
}

struct TuyenPhatToRoiMaTran: Codable, Equatable {
    let id: String
    let soThuTu: Int
    var ten: String
    var moTaDiemNong: String
    var soDiemNong: Int
    /// Danh sách tọa độ điểm dừng [lat, lon] bắt đầu từ tâm siêu thị qua các điểm nóng của tuyến này
    var cacToaDo: [[Double]]
    /// Danh sách địa điểm mục tiêu chi tiết (tên + tọa độ) để nhân viên check-in kiểm soát phát tờ rơi
    var cacDiemMucTieu: [DiemMucTieuTuyen]
    /// Tên điểm xuất phát (siêu thị / tâm quét)
    var tenDiemXuatPhat: String
    /// Danh sách tọa độ bám sát đường đi thực tế trên bản đồ (từ OSRM / Apple MKDirections)
    var toaDoDuongThucTe: [[Double]]
    /// Đã bám đường thực tế trên map hay đang là ước lượng tạm thời
    var laDuongThucTe: Bool
    /// Tổng quãng đường (mét)
    var tongQuangDuongMet: Double
    /// Thời gian di chuyển ước tính bằng xe máy (phút)
    var thoiGianXeMayPhut: Int
    /// Thời gian di chuyển ước tính bằng đi bộ (phút)
    var thoiGianDiBoPhut: Int
    /// Chỉ dẫn chi tiết từng bước: xuất phát, đi thẳng, rẽ trái/rẽ phải, vòng xuyến, điểm dừng phát tờ rơi
    var chiDanTungBuoc: [BuocChiDanTuyen]

    var toaDoVeBanDo: [[Double]] {
        return toaDoDuongThucTe.count >= 2 ? toaDoDuongThucTe : cacToaDo
    }

    init(
        id: String,
        soThuTu: Int,
        ten: String,
        moTaDiemNong: String,
        soDiemNong: Int,
        cacToaDo: [[Double]],
        cacDiemMucTieu: [DiemMucTieuTuyen] = [],
        tenDiemXuatPhat: String = "",
        toaDoDuongThucTe: [[Double]] = [],
        laDuongThucTe: Bool = false,
        tongQuangDuongMet: Double = 0,
        thoiGianXeMayPhut: Int = 0,
        thoiGianDiBoPhut: Int = 0,
        chiDanTungBuoc: [BuocChiDanTuyen] = []
    ) {
        self.id = id
        self.soThuTu = soThuTu
        self.ten = ten
        self.moTaDiemNong = moTaDiemNong
        self.soDiemNong = soDiemNong
        self.cacToaDo = cacToaDo
        self.cacDiemMucTieu = cacDiemMucTieu
        self.tenDiemXuatPhat = tenDiemXuatPhat
        self.toaDoDuongThucTe = toaDoDuongThucTe
        self.laDuongThucTe = laDuongThucTe
        self.tongQuangDuongMet = tongQuangDuongMet
        self.thoiGianXeMayPhut = thoiGianXeMayPhut
        self.thoiGianDiBoPhut = thoiGianDiBoPhut
        self.chiDanTungBuoc = chiDanTungBuoc
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        soThuTu = try c.decode(Int.self, forKey: .soThuTu)
        ten = try c.decode(String.self, forKey: .ten)
        moTaDiemNong = try c.decode(String.self, forKey: .moTaDiemNong)
        soDiemNong = try c.decode(Int.self, forKey: .soDiemNong)
        cacToaDo = (try? c.decode([[Double]].self, forKey: .cacToaDo)) ?? []
        cacDiemMucTieu = (try? c.decode([DiemMucTieuTuyen].self, forKey: .cacDiemMucTieu)) ?? []
        tenDiemXuatPhat = (try? c.decode(String.self, forKey: .tenDiemXuatPhat)) ?? ""
        toaDoDuongThucTe = (try? c.decode([[Double]].self, forKey: .toaDoDuongThucTe)) ?? []
        laDuongThucTe = (try? c.decode(Bool.self, forKey: .laDuongThucTe)) ?? false
        tongQuangDuongMet = (try? c.decode(Double.self, forKey: .tongQuangDuongMet)) ?? 0
        thoiGianXeMayPhut = (try? c.decode(Int.self, forKey: .thoiGianXeMayPhut)) ?? 0
        thoiGianDiBoPhut = (try? c.decode(Int.self, forKey: .thoiGianDiBoPhut)) ?? 0
        chiDanTungBuoc = (try? c.decode([BuocChiDanTuyen].self, forKey: .chiDanTungBuoc)) ?? []
    }

    var mauTuyen: UIColor {
        let bangMau: [UIColor] = [
            UIColor(red: 0.09, green: 0.64, blue: 0.29, alpha: 1.0), // Tuyến 1: Xanh lá đậm
            UIColor(red: 0.14, green: 0.39, blue: 0.92, alpha: 1.0), // Tuyến 2: Xanh dương
            UIColor(red: 0.92, green: 0.35, blue: 0.05, alpha: 1.0), // Tuyến 3: Cam đậm
            UIColor(red: 0.58, green: 0.20, blue: 0.92, alpha: 1.0), // Tuyến 4: Tím nổi bật
            UIColor(red: 0.01, green: 0.56, blue: 0.64, alpha: 1.0), // Tuyến 5: Xanh ngọc đậm
            UIColor(red: 0.85, green: 0.15, blue: 0.45, alpha: 1.0), // Tuyến 6: Hồng đậm
            UIColor(red: 0.64, green: 0.44, blue: 0.04, alpha: 1.0), // Tuyến 7: Vàng nâu đậm
            UIColor(red: 0.28, green: 0.33, blue: 0.41, alpha: 1.0)  // Tuyến 8: Xám xanh đậm
        ]
        return bangMau[max(0, soThuTu - 1) % bangMau.count]
    }
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
    var danhSachPG: [String]
    var danhSachNV: [String]
    var daPhat: Bool
}

struct KeHoachMaTranTuan: Codable, Equatable {
    let khoaTuan: String
    let nhanTuan: String
    var cacTuyen: [TuyenPhatToRoiMaTran]
    var cacO: [OMaTranPhatToRoi]
    var tenNguonPG: String
    var tenNguonNV: String
    var tongPGDaPhan: Int
    var tongPGCoLich: Int
    var danhSachPGChuaDuocPhan: [String]
}

final class KhoMaTranPhatToRoi {
    static let dungChung = KhoMaTranPhatToRoi()
    private init() {}

    static let linkTrangTinhMacDinh = "https://docs.google.com/spreadsheets/d/1hHbwvf-xCq1zT_qCuasYGcCotnHKCM_s5fJgre3M1Qg/edit?gid=0#gid=0"
    static let linkSheetBaoCaoCheckIn = "https://docs.google.com/spreadsheets/d/1hHbwvf-xCq1zT_qCuasYGcCotnHKCM_s5fJgre3M1Qg/edit?gid=1263278153#gid=1263278153"
    static let linkPWACheckInMacDinh = "https://thanhduongnmc24-gif.github.io/DMX-V2/"

    private let khoaKeHoach = "dmx_matran_toroi_tuan_v2"
    private let khoaLichPG = "dmx_lich_pg_excel_v2"
    private let khoaDanhSachPG = "dmx_danhsach_lich_pg_sheet_v1"
    private let khoaLichNV = "dmx_lich_nv_excel_v2"
    private let khoaNhacChuNhat = "dmx_nhac_cn_dangky_lich_v1"
    private let khoaCauHinhPhanTuyen = "dmx_cauhinh_phantuyen_toroi_v1"
    private let khoaLinkSheetChung = "dmx_link_google_sheet_chung_v2"
    private let khoaLinkSheetPGCu = "dmx_link_google_sheet_pg_v1"
    private let khoaLinkSheetNVCu = "dmx_link_google_sheet_nv_v1"

    func taiCauHinhPhanTuyen() -> CauHinhPhanTuyenToRoi {
        guard let data = UserDefaults.standard.data(forKey: khoaCauHinhPhanTuyen),
              let cfg = try? JSONDecoder().decode(CauHinhPhanTuyenToRoi.self, from: data) else {
            return CauHinhPhanTuyenToRoi()
        }
        return cfg
    }

    func luuCauHinhPhanTuyen(_ cfg: CauHinhPhanTuyenToRoi) {
        if let data = try? JSONEncoder().encode(cfg) {
            UserDefaults.standard.set(data, forKey: khoaCauHinhPhanTuyen)
        }
    }

    func layLinkTrangTinhChung() -> String {
        if let chung = UserDefaults.standard.string(forKey: khoaLinkSheetChung), !chung.isEmpty {
            return chung
        }
        return Self.linkTrangTinhMacDinh
    }

    func luuLinkTrangTinhChung(_ link: String) {
        let sach = link.trimmingCharacters(in: .whitespacesAndNewlines)
        if sach.isEmpty {
            UserDefaults.standard.removeObject(forKey: khoaLinkSheetChung)
        } else {
            UserDefaults.standard.set(sach, forKey: khoaLinkSheetChung)
        }
    }

    func taiDanhSachKhoiPG() -> [KhoiLichTuanExcel] {
        guard let data = UserDefaults.standard.data(forKey: khoaDanhSachPG),
              let ds = try? JSONDecoder().decode([KhoiLichTuanExcel].self, from: data) else {
            return []
        }
        return ds
    }

    func luuDanhSachKhoiPG(_ ds: [KhoiLichTuanExcel]) {
        if ds.isEmpty {
            UserDefaults.standard.removeObject(forKey: khoaDanhSachPG)
        } else if let data = try? JSONEncoder().encode(ds) {
            UserDefaults.standard.set(data, forKey: khoaDanhSachPG)
        }
    }

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
            content.title = "📅 Nhắc đồng bộ lịch phát tờ rơi tuần tới"
            content.body = "Hôm nay là Chủ nhật! Hãy bấm tải lại Google Trang tính lịch PG & Nhân viên tuần tiếp theo để phân ma trận phát tờ rơi xoay vòng."
            content.sound = .default

            var dc = DateComponents()
            dc.weekday = 1
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

// MARK: - Sổ Xoay Tua Theo Tháng (Đảm Bảo 100% PG/NV Đều Đi Phát, Không Bỏ Sót Ai)

struct BanGhiXoayTuaThang: Codable, Equatable {
    var tenGoc: String
    var nhom: NhomNhanSuLich
    var cacTuanDaPhat: [String]
}

final class KhoSoXoayTuaThang {
    static let dungChung = KhoSoXoayTuaThang()
    private init() {}

    private let khoaLuu = "dmx_so_xoay_tua_thang_v1"

    static func khoaThangHienTai(ngay: Date = Date()) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM"
        return df.string(from: ngay)
    }

    static func nhanThangHienTai(ngay: Date = Date()) -> String {
        let df = DateFormatter()
        df.dateFormat = "MM/yyyy"
        return "Tháng \(df.string(from: ngay))"
    }

    private func taiTatCa() -> [String: [String: BanGhiXoayTuaThang]] {
        guard let data = UserDefaults.standard.data(forKey: khoaLuu),
              let dict = try? JSONDecoder().decode([String: [String: BanGhiXoayTuaThang]].self, from: data) else {
            return [:]
        }
        return dict
    }

    private func luuTatCa(_ dict: [String: [String: BanGhiXoayTuaThang]]) {
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: khoaLuu)
        }
    }

    func soLanTrongThang(ten: String, khoaThang: String = khoaThangHienTai()) -> Int {
        let key = BoPhanTichLichCaExcel.chuanHoa(ten)
        return taiTatCa()[khoaThang]?[key]?.cacTuanDaPhat.count ?? 0
    }

    func layBangThang(khoaThang: String = khoaThangHienTai()) -> [BanGhiXoayTuaThang] {
        let map = taiTatCa()[khoaThang] ?? [:]
        return map.values.sorted { a, b in
            if a.cacTuanDaPhat.count != b.cacTuanDaPhat.count {
                return a.cacTuanDaPhat.count < b.cacTuanDaPhat.count
            }
            return a.tenGoc < b.tenGoc
        }
    }

    /// Ghi nhận danh sách nhân sự đã được phân / đã phát trong tuần vào sổ tháng (tránh bỏ sót sang tuần tiếp theo)
    func capNhatTuKeHoachTuan(_ kh: KeHoachMaTranTuan, khoaThang: String = khoaThangHienTai()) {
        var all = taiTatCa()
        var thangMap = all[khoaThang] ?? [:]

        // Xóa dấu tuần này cũ trước khi ghi lại để đồng bộ chính xác khi sửa/tạo lại tuần này
        for (k, var rec) in thangMap {
            rec.cacTuanDaPhat.removeAll { $0 == kh.khoaTuan }
            thangMap[k] = rec
        }

        func ghiNhan(chuoiNguoi: String, nhom: NhomNhanSuLich) {
            // Tách tên gốc trước dấu "(" VD: "LỆ SH (SÁNG 9h-16h)" -> "LỆ SH"
            let tenSach = chuoiNguoi.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? chuoiNguoi
            guard !tenSach.isEmpty else { return }
            let key = BoPhanTichLichCaExcel.chuanHoa(tenSach)
            var rec = thangMap[key] ?? BanGhiXoayTuaThang(tenGoc: tenSach, nhom: nhom, cacTuanDaPhat: [])
            if !rec.cacTuanDaPhat.contains(kh.khoaTuan) {
                rec.cacTuanDaPhat.append(kh.khoaTuan)
            }
            thangMap[key] = rec
        }

        for o in kh.cacO {
            for p in o.danhSachPG { ghiNhan(chuoiNguoi: p, nhom: .pg) }
            for n in o.danhSachNV { ghiNhan(chuoiNguoi: n, nhom: .nhanVien) }
        }

        all[khoaThang] = thangMap
        luuTatCa(all)
    }

    /// Bổ sung cả những nhân sự có trong danh sách Excel tuần này (0 lần) để sổ tháng hiện đủ mọi người
    func damBaoDuNhanSu(danhSach: [LichTuanMotNguoi], khoaThang: String = khoaThangHienTai()) {
        var all = taiTatCa()
        var thangMap = all[khoaThang] ?? [:]
        for nguoi in danhSach {
            let key = BoPhanTichLichCaExcel.chuanHoa(nguoi.ten)
            if thangMap[key] == nil {
                thangMap[key] = BanGhiXoayTuaThang(tenGoc: nguoi.ten, nhom: nguoi.nhom, cacTuanDaPhat: [])
            }
        }
        all[khoaThang] = thangMap
        luuTatCa(all)
    }

    func xoaSoThang(khoaThang: String = khoaThangHienTai()) {
        var all = taiTatCa()
        all.removeValue(forKey: khoaThang)
        luuTatCa(all)
    }
}

final class BoLapMaTranToRoiXoayVong {
    static func tinhSoTuyenTuDong(
        khoiPG: KhoiLichTuanExcel?,
        khoiNV: KhoiLichTuanExcel?,
        cauHinh: CauHinhPhanTuyenToRoi,
        soDiemNong: Int
    ) -> Int {
        if cauHinh.soTuyenMongMuon >= 2 && cauHinh.soTuyenMongMuon <= 8 {
            return cauHinh.soTuyenMongMuon
        }
        let tongPG = khoiPG?.danhSachNguoi.count ?? 0
        let tongNV = khoiNV?.danhSachNguoi.count ?? 0
        let tongNS = tongPG + tongNV
        if tongNS > 0 {
            let soTuyenTheoPG = (cauHinh.soPGMoiTuyen > 0 && tongPG > 0)
                ? Int(ceil(Double(tongPG) / Double(cauHinh.soPGMoiTuyen)))
                : 0
            let soTuyenTheoNV = (cauHinh.soNVMoiTuyen > 0 && tongNV > 0)
                ? Int(ceil(Double(tongNV) / Double(cauHinh.soNVMoiTuyen)))
                : 0
            let soTuyenTong = Int(ceil(Double(tongNS) / Double(cauHinh.tongNhanSuMoiTuyen)))
            let uocLuong = max(soTuyenTong, max(soTuyenTheoPG, soTuyenTheoNV))
            let gioiHanTren = soDiemNong >= 2 ? min(8, soDiemNong) : 6
            return max(2, min(min(6, gioiHanTren), uocLuong))
        }
        if soDiemNong >= 2 {
            return min(4, soDiemNong)
        }
        return 4
    }

    private static func tenHuongTheoGoc(_ gocDo: Double) -> String {
        let g = (gocDo.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        switch g {
        case 337.5..<360, 0..<22.5: return "Bắc"
        case 22.5..<67.5: return "Đông Bắc"
        case 67.5..<112.5: return "Đông"
        case 112.5..<157.5: return "Đông Nam"
        case 157.5..<202.5: return "Nam"
        case 202.5..<247.5: return "Tây Nam"
        case 247.5..<292.5: return "Tây"
        default: return "Tây Bắc"
        }
    }

    static func taoCacTuyenTuKetQuaQuet(
        tamLat: Double,
        tamLon: Double,
        danhSach: [DiaDiemQuet],
        banKinhMet: Double = 2000,
        soTuyenMongMuon: Int = 4,
        tenDiemXuatPhat: String = "Siêu thị"
    ) -> [TuyenPhatToRoiMaTran] {
        let soTuyenMucTieu = max(1, min(8, soTuyenMongMuon))
        let trongBanKinh = danhSach.filter { $0.khoangCachMet <= banKinhMet + 25.0 }
        let diemNongUuTien = trongBanKinh.filter { $0.loai == .cho || $0.loai == .truongHoc || $0.loai == .doiThu }
        let diemNong = !diemNongUuTien.isEmpty ? diemNongUuTien : trongBanKinh.filter { $0.loai != .heThongMWG }
        guard !diemNong.isEmpty else {
            let tenMacDinh = ["Đông Bắc", "Đông Nam", "Tây Nam", "Tây Bắc", "Bắc", "Nam", "Đông", "Tây"]
            return (0..<soTuyenMucTieu).map { i in
                TuyenPhatToRoiMaTran(
                    id: "tuyen_\(i + 1)",
                    soThuTu: i + 1,
                    ten: "Tuyến \(i + 1) — Hướng \(tenMacDinh[i % tenMacDinh.count])",
                    moTaDiemNong: "Quét bản đồ hoặc mở rộng bán kính phát tờ rơi để vẽ tuyến thực tế",
                    soDiemNong: 0,
                    cacToaDo: [],
                    cacDiemMucTieu: [],
                    tenDiemXuatPhat: tenDiemXuatPhat
                )
            }
        }

        // Trải đều các điểm nóng từ gần tâm ra tới rìa bán kính quét (không bị dồn cục quanh siêu thị!)
        func taoChuoiToaDoVaDiemTuyen(tu ds: [DiaDiemQuet]) -> (toaDo: [[Double]], diem: [DiemMucTieuTuyen]) {
            let kcToiThieuMet = max(180.0, banKinhMet * 0.14)
            let sapXepUuTien = ds.sorted { a, b in
                if a.loai.diemUuTienToRoi != b.loai.diemUuTienToRoi {
                    return a.loai.diemUuTienToRoi > b.loai.diemUuTienToRoi
                }
                return a.khoangCachMet > b.khoangCachMet
            }
            var top: [DiaDiemQuet] = []
            for d in sapXepUuTien {
                if top.count >= 6 { break }
                let quaGan = top.contains {
                    hypot((d.viDo - $0.viDo) * 111000.0, (d.kinhDo - $0.kinhDo) * 105000.0) < kcToiThieuMet
                }
                if !quaGan { top.append(d) }
            }
            if top.count < 3 {
                for d in sapXepUuTien where !top.contains(where: { $0.id == d.id }) {
                    if top.count >= 5 { break }
                    top.append(d)
                }
            }

            var conLai = top
            var ketQuaToaDo: [[Double]] = [[tamLat, tamLon]]
            var ketQuaDiem: [DiemMucTieuTuyen] = []
            var curLat = tamLat
            var curLon = tamLon
            while !conLai.isEmpty {
                var bestIdx = 0
                var bestDist = Double.greatestFiniteMagnitude
                for (i, d) in conLai.enumerated() {
                    let dist = hypot(d.viDo - curLat, d.kinhDo - curLon)
                    if dist < bestDist {
                        bestDist = dist
                        bestIdx = i
                    }
                }
                let chon = conLai.remove(at: bestIdx)
                ketQuaToaDo.append([chon.viDo, chon.kinhDo])
                ketQuaDiem.append(DiemMucTieuTuyen(
                    id: chon.id,
                    ten: chon.ten,
                    diaChi: chon.diaChi,
                    loaiRaw: chon.loai.tieuDe,
                    viDo: chon.viDo,
                    kinhDo: chon.kinhDo
                ))
                curLat = chon.viDo
                curLon = chon.kinhDo
            }
            return (ketQuaToaDo, ketQuaDiem)
        }

        // Chia thành đúng `soTuyenMucTieu` cung quạt theo góc phương vị quanh siêu thị (nếu dữ liệu tập trung ít hướng, chia theo thứ tự góc đều nhau)
        let diemTheoGoc: [(diem: DiaDiemQuet, goc: Double)] = diemNong.map { d in
            let dLat = d.viDo - tamLat
            let dLon = d.kinhDo - tamLon
            let rad = atan2(dLon, dLat) // 0 = Bắc, 90 = Đông
            let deg = (rad * 180.0 / .pi + 360.0).truncatingRemainder(dividingBy: 360.0)
            return (d, deg)
        }.sorted { $0.goc < $1.goc }

        var nhomTuyen: [(tenHuong: String, ds: [DiaDiemQuet])] = []

        if soTuyenMucTieu == 4 {
            let ten4Huong = ["Đông Bắc", "Đông Nam", "Tây Nam", "Tây Bắc"]
            var nhom4: [[DiaDiemQuet]] = [[], [], [], []]
            for item in diemTheoGoc {
                let idx = min(3, max(0, Int(item.goc / 90.0)))
                nhom4[idx].append(item.diem)
            }
            for (i, ds) in nhom4.enumerated() where !ds.isEmpty {
                nhomTuyen.append((ten4Huong[i], ds))
            }
        } else {
            let soNhomThucTe = min(soTuyenMucTieu, diemTheoGoc.count)
            let buocGoc = 360.0 / Double(soNhomThucTe)
            var theoCung: [[DiaDiemQuet]] = Array(repeating: [], count: soNhomThucTe)
            for item in diemTheoGoc {
                let idx = min(soNhomThucTe - 1, max(0, Int(item.goc / buocGoc)))
                theoCung[idx].append(item.diem)
            }
            let soCungCoDiem = theoCung.filter { !$0.isEmpty }.count
            if soCungCoDiem >= max(2, soNhomThucTe - 1) {
                for (i, ds) in theoCung.enumerated() where !ds.isEmpty {
                    let gocGiua = (Double(i) + 0.5) * buocGoc
                    nhomTuyen.append((tenHuongTheoGoc(gocGiua), ds))
                }
            } else {
                // Nếu điểm nóng lệch về một phía bản đồ, chia đều số điểm theo góc tăng dần để vẫn đủ đúng số tuyến người dùng chọn
                var startIdx = 0
                for i in 0..<soNhomThucTe {
                    let conLaiDiem = diemTheoGoc.count - startIdx
                    let conLaiNhom = soNhomThucTe - i
                    let count = max(1, Int(ceil(Double(conLaiDiem) / Double(conLaiNhom))))
                    let endIdx = min(diemTheoGoc.count, startIdx + count)
                    guard startIdx < endIdx else { break }
                    let slice = diemTheoGoc[startIdx..<endIdx]
                    let gocTB = slice.reduce(0.0) { $0 + $1.goc } / Double(slice.count)
                    nhomTuyen.append((tenHuongTheoGoc(gocTB), slice.map { $0.diem }))
                    startIdx = endIdx
                }
            }
        }

        if nhomTuyen.count == 1 && soTuyenMucTieu >= 2 && diemNong.count >= 2 {
            let sorted = diemNong.sorted { $0.khoangCachMet < $1.khoangCachMet }
            let soNhom = min(soTuyenMucTieu, sorted.count)
            nhomTuyen = []
            var startIdx = 0
            for i in 0..<soNhom {
                let conLaiDiem = sorted.count - startIdx
                let conLaiNhom = soNhom - i
                let count = max(1, Int(ceil(Double(conLaiDiem) / Double(conLaiNhom))))
                let endIdx = min(sorted.count, startIdx + count)
                guard startIdx < endIdx else { break }
                let tenVanhDai = (i == 0) ? "Vành đai gần" : ((i == soNhom - 1) ? "Vành đai ngoài" : "Vành đai giữa \(i)")
                nhomTuyen.append((tenVanhDai, Array(sorted[startIdx..<endIdx])))
                startIdx = endIdx
            }
        }

        var ketQua: [TuyenPhatToRoiMaTran] = []
        for (idx, nhom) in nhomTuyen.enumerated() {
            let ds = nhom.ds
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
            let soKhac = ds.filter { $0.loai == .khac }.count
            var phanLoaiText = ["\(soCho) chợ", "\(soTH) trường", "\(soDT) đối thủ"]
            if soKhac > 0 { phanLoaiText.append("\(soKhac) điểm khác") }
            let chiTiet = "\(topTen) (\(phanLoaiText.joined(separator: ", ")))"
            let chuoi = taoChuoiToaDoVaDiemTuyen(tu: ds)

            // Ước lượng quãng đường & chỉ dẫn cơ sở trước khi bám đường thực tế OSRM/MKDirections
            var tongMetThang = 0.0
            var buocCoSo: [BuocChiDanTuyen] = [
                BuocChiDanTuyen(stt: 1, hanhDong: "🚩 Xuất phát", noiDung: "Xuất phát từ \(tenDiemXuatPhat)", khoangCachMet: 0, laDiemDung: false)
            ]
            for j in 1..<chuoi.toaDo.count {
                let p1 = chuoi.toaDo[j - 1]
                let p2 = chuoi.toaDo[j]
                let seg = hypot((p2[0] - p1[0]) * 111000.0, (p2[1] - p1[1]) * 105000.0) * 1.32
                tongMetThang += seg
                if j - 1 < chuoi.diem.count {
                    let d = chuoi.diem[j - 1]
                    let dc = d.diaChi.isEmpty ? "" : " • \(d.diaChi)"
                    buocCoSo.append(BuocChiDanTuyen(
                        stt: buocCoSo.count + 1,
                        hanhDong: "📍 Điểm #\(j)",
                        noiDung: "\(d.ten) (\(d.loaiRaw))\(dc)",
                        khoangCachMet: seg,
                        laDiemDung: true
                    ))
                }
            }
            let phutXeMay = max(2, Int(ceil(tongMetThang / 400.0)))
            let phutDiBo = max(3, Int(ceil(tongMetThang / 75.0)))

            ketQua.append(TuyenPhatToRoiMaTran(
                id: "tuyen_chia_\(idx + 1)",
                soThuTu: idx + 1,
                ten: "Tuyến \(idx + 1) — \(nhom.tenHuong)",
                moTaDiemNong: chiTiet,
                soDiemNong: ds.count,
                cacToaDo: chuoi.toaDo,
                cacDiemMucTieu: chuoi.diem,
                tenDiemXuatPhat: tenDiemXuatPhat,
                toaDoDuongThucTe: [],
                laDuongThucTe: false,
                tongQuangDuongMet: tongMetThang,
                thoiGianXeMayPhut: phutXeMay,
                thoiGianDiBoPhut: phutDiBo,
                chiDanTungBuoc: buocCoSo
            ))
        }

        return ketQua
    }

    /// Lập Ma trận xoay vòng Thứ 2 → Chủ nhật (Sáng & Chiều)
    /// NGUYÊN TẮC CỐT LÕI:
    /// 1. Chỉ sử dụng PG / NV ĐANG LÀM VIỆC trong đúng buổi đó (Sáng dùng người ca Sáng/Gãy, Chiều dùng người ca Chiều/Gãy).
    /// 2. PG / NV nào ĐÃ PHÁT rồi thì TUYỆT ĐỐI KHÔNG PHÁT NỮA trong tuần đó (mỗi người tối đa 1 lần/tuần).
    /// 3. Phân đúng số PG/tuyến và số NV/tuyến theo cấu hình người dùng chọn.
    static func lapMaTranTuan(
        cacTuyen: [TuyenPhatToRoiMaTran],
        khoiPG: KhoiLichTuanExcel?,
        khoiNV: KhoiLichTuanExcel?,
        cauHinh: CauHinhPhanTuyenToRoi = KhoMaTranPhatToRoi.dungChung.taiCauHinhPhanTuyen(),
        giuTrangThaiCu: KeHoachMaTranTuan? = nil
    ) -> KeHoachMaTranTuan {
        let tuyenHopLe = cacTuyen.isEmpty
            ? [TuyenPhatToRoiMaTran(id: "t1", soThuTu: 1, ten: "Tuyến 1", moTaDiemNong: "Chưa quét bản đồ", soDiemNong: 0, cacToaDo: [], cacDiemMucTieu: [])]
            : cacTuyen

        let (khoaTuan, nhanTuanMacDinh) = tinhKhoaVaNhanTuan()
        let nhanTuan: String
        if let p = khoiPG {
            nhanTuan = "\(p.tenTuan) • \(p.tenSheet)"
        } else if let nv = khoiNV {
            nhanTuan = "\(nv.tenTuan) • \(nv.tenSheet)"
        } else {
            nhanTuan = nhanTuanMacDinh
        }

        // Tập đánh dấu người ĐÃ PHÁT -> tuyệt đối không phân lại lần 2 trong tuần!
        var pgDaPhat: Set<String> = []
        var nvDaPhat: Set<String> = []

        var trangThaiCuMap: [String: Bool] = [:]
        if let cu = giuTrangThaiCu, cu.khoaTuan == khoaTuan {
            for o in cu.cacO { trangThaiCuMap[o.id] = o.daPhat }
        }

        let dsPGAll = khoiPG?.danhSachNguoi ?? []
        let dsNVAll = khoiNV?.danhSachNguoi ?? []

        func soBuoiLamConLai(_ nguoi: LichTuanMotNguoi, tuThu: Int) -> Int {
            var c = 0
            for t in tuThu..<min(7, nguoi.lich7Ngay.count) {
                if nguoi.lich7Ngay[t].dangLamSang { c += 1 }
                if nguoi.lich7Ngay[t].dangLamChieu { c += 1 }
            }
            return c
        }

        var cacO: [OMaTranPhatToRoi] = []
        var chiSoTuyen = 0

        for thu in 0..<7 {
            for buoi in ["Sáng", "Chiều"] {
                let laSang = (buoi == "Sáng")
                let tuyen = tuyenHopLe[chiSoTuyen % tuyenHopLe.count]
                chiSoTuyen += 1

                // 1. Chọn PG ĐANG LÀM VIỆC buổi này VÀ CHƯA PHÁT LẦN NÀO trong tuần theo đúng số PG/tuyến
                var pgChon: [String] = []
                if !dsPGAll.isEmpty && cauHinh.soPGMoiTuyen > 0 {
                    let ungVienPG = dsPGAll.filter { nguoi in
                        let key = BoPhanTichLichCaExcel.chuanHoa(nguoi.ten)
                        guard !pgDaPhat.contains(key), thu < nguoi.lich7Ngay.count else { return false }
                        let ca = nguoi.lich7Ngay[thu]
                        return laSang ? ca.dangLamSang : ca.dangLamChieu
                    }.sorted { a, b in
                        let lanThangA = KhoSoXoayTuaThang.dungChung.soLanTrongThang(ten: a.ten)
                        let lanThangB = KhoSoXoayTuaThang.dungChung.soLanTrongThang(ten: b.ten)
                        if lanThangA != lanThangB { return lanThangA < lanThangB }
                        return soBuoiLamConLai(a, tuThu: thu) < soBuoiLamConLai(b, tuThu: thu)
                    }

                    for p in ungVienPG.prefix(cauHinh.soPGMoiTuyen) {
                        let ca = p.lich7Ngay[thu]
                        let chuThich = ca.gioLamGoc.isEmpty ? ca.nhanCaGoc : "\(ca.nhanCaGoc) \(ca.gioLamGoc)"
                        pgChon.append("\(p.ten) (\(chuThich))")
                        pgDaPhat.insert(BoPhanTichLichCaExcel.chuanHoa(p.ten))
                    }
                }

                // 2. Chọn NV siêu thị ĐANG LÀM VIỆC buổi này VÀ CHƯA PHÁT LẦN NÀO trong tuần theo đúng số NV/tuyến
                var nvChon: [String] = []
                if !dsNVAll.isEmpty && cauHinh.soNVMoiTuyen > 0 {
                    let ungVienNV = dsNVAll.filter { nguoi in
                        let key = BoPhanTichLichCaExcel.chuanHoa(nguoi.ten)
                        guard !nvDaPhat.contains(key), thu < nguoi.lich7Ngay.count else { return false }
                        let ca = nguoi.lich7Ngay[thu]
                        return laSang ? ca.dangLamSang : ca.dangLamChieu
                    }.sorted { a, b in
                        let lanThangA = KhoSoXoayTuaThang.dungChung.soLanTrongThang(ten: a.ten)
                        let lanThangB = KhoSoXoayTuaThang.dungChung.soLanTrongThang(ten: b.ten)
                        if lanThangA != lanThangB { return lanThangA < lanThangB }
                        return soBuoiLamConLai(a, tuThu: thu) < soBuoiLamConLai(b, tuThu: thu)
                    }

                    for nv in ungVienNV.prefix(cauHinh.soNVMoiTuyen) {
                        let ca = nv.lich7Ngay[thu]
                        let chuThich = ca.gioLamGoc.isEmpty ? ca.nhanCaGoc : "\(ca.nhanCaGoc) \(ca.gioLamGoc)"
                        nvChon.append("\(nv.ten) (\(chuThich))")
                        nvDaPhat.insert(BoPhanTichLichCaExcel.chuanHoa(nv.ten))
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

        let dsPGChuaDuocPhan = dsPGAll
            .filter { !pgDaPhat.contains(BoPhanTichLichCaExcel.chuanHoa($0.ten)) }
            .map { $0.ten }

        let keHoachMoi = KeHoachMaTranTuan(
            khoaTuan: khoaTuan,
            nhanTuan: nhanTuan,
            cacTuyen: tuyenHopLe,
            cacO: cacO,
            tenNguonPG: khoiPG.map { "\($0.tenSheet) – \($0.tenTuan) (\($0.danhSachNguoi.count) PG)" } ?? "Chưa có dữ liệu PG từ Trang tính",
            tenNguonNV: khoiNV.map { "\($0.tenSheet) – \($0.tenTuan) (\($0.danhSachNguoi.count) NV)" } ?? "Chưa có dữ liệu NV từ Trang tính",
            tongPGDaPhan: pgDaPhat.count,
            tongPGCoLich: dsPGAll.count,
            danhSachPGChuaDuocPhan: dsPGChuaDuocPhan
        )
        KhoSoXoayTuaThang.dungChung.damBaoDuNhanSu(danhSach: dsPGAll + dsNVAll)
        KhoSoXoayTuaThang.dungChung.capNhatTuKeHoachTuan(keHoachMoi)
        return keHoachMoi
    }

    static func tinhKhoaVaNhanTuan(ngay: Date = Date()) -> (String, String) {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let weekday = cal.component(.weekday, from: ngay)
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
