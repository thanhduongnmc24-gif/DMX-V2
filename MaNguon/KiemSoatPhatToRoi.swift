import UIKit
import CoreLocation
import PhotosUI

// MARK: - 1. Bộ Tải Dữ Liệu Từ Google Trang Tính (Google Sheets -> XLSX đa sheet + dự phòng CSV)

final class BoTaiTrangTinhGoogleSheets {
    static let dungChung = BoTaiTrangTinhGoogleSheets()
    private init() {}

    struct KetQuaTachLink {
        let spreadsheetId: String
        let gid: String?
        let linkCSVTrucTiep: URL?
    }

    static func tachThongTinLink(_ rawInput: String) -> KetQuaTachLink? {
        let text = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        // Link đã xuất bản trực tiếp dạng CSV (pub?output=csv)
        if text.lowercased().contains("output=csv") || text.lowercased().contains("format=csv"),
           let url = URL(string: text) {
            return KetQuaTachLink(spreadsheetId: "", gid: nil, linkCSVTrucTiep: url)
        }

        // Bắt Spreadsheet ID từ URL chuẩn Google Sheets
        let patternId = #"/spreadsheets/d/([a-zA-Z0-9_-]{12,})"#
        var sheetId = ""
        if let regex = try? NSRegularExpression(pattern: patternId),
           let m = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let r = Range(m.range(at: 1), in: text) {
            sheetId = String(text[r])
        } else if text.range(of: "^[a-zA-Z0-9_-]{20,80}$", options: .regularExpression) != nil {
            sheetId = text
        }

        guard !sheetId.isEmpty else { return nil }

        var gid: String? = nil
        if let rgGid = try? NSRegularExpression(pattern: #"[#&?]gid=([0-9]+)"#),
           let mGid = rgGid.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let rGid = Range(mGid.range(at: 1), in: text) {
            gid = String(text[rGid])
        }
        return KetQuaTachLink(spreadsheetId: sheetId, gid: gid, linkCSVTrucTiep: nil)
    }

    func taiLichTuGoogleSheets(
        link: String,
        nhom: NhomNhanSuLich,
        hoanTat: @escaping (Result<(dsKhoi: [KhoiLichTuanExcel], tenNguon: String), Error>) -> Void
    ) {
        guard let thongTin = Self.tachThongTinLink(link) else {
            DispatchQueue.main.async {
                hoanTat(.failure(NSError.dmx("Đường dẫn Google Trang tính không hợp lệ. Hãy dán link dạng https://docs.google.com/spreadsheets/d/...")))
            }
            return
        }

        if let csvURL = thongTin.linkCSVTrucTiep {
            taiCSV(url: csvURL, tenSheet: "Google Trang tính", nhom: nhom, hoanTat: hoanTat)
            return
        }

        // Ưu tiên 1: Xuất toàn bộ file Google Sheets dạng .xlsx để giữ đủ tất cả các tab tuần!
        guard let urlXlsx = URL(string: "https://docs.google.com/spreadsheets/d/\(thongTin.spreadsheetId)/export?format=xlsx") else {
            DispatchQueue.main.async { hoanTat(.failure(NSError.dmx("Không tạo được đường dẫn tải Trang tính."))) }
            return
        }

        var req = URLRequest(url: urlXlsx, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 35)
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            guard let self else { return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let finalURL = response?.url?.absoluteString.lowercased() ?? ""

            if let error {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError.dmx("Không tải được Google Trang tính: \(error.localizedDescription)")))
                }
                return
            }

            if status == 401 || status == 403 || finalURL.contains("accounts.google.com") {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError.dmx("Trang tính đang ở chế độ riêng tư. Hãy mở Google Trang tính → Chia sẻ → Quyền truy cập chung → chọn “Bất kỳ ai có đường liên kết (Người xem)” rồi thử lại.")))
                }
                return
            }

            if status == 200, let data, data.count > 22 {
                let bytes = [UInt8](data.prefix(4))
                let laZip = bytes.count >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B
                if laZip {
                    do {
                        let dsKhoi = try BoPhanTichLichCaExcel.phanTichWorkbook(tuData: data, nhom: nhom)
                        if !dsKhoi.isEmpty {
                            DispatchQueue.main.async {
                                hoanTat(.success((dsKhoi: dsKhoi, tenNguon: "Google Trang tính")))
                            }
                            return
                        }
                    } catch {
                        // Thử dự phòng CSV nếu bảng có cấu trúc khác
                    }
                } else if let textDau = String(data: data.prefix(512), encoding: .utf8)?.lowercased(),
                          textDau.contains("<html") || textDau.contains("<!doctype html") {
                    DispatchQueue.main.async {
                        hoanTat(.failure(NSError.dmx("Google Trang tính chưa bật chia sẻ công khai (Người xem). Hãy bật “Bất kỳ ai có đường liên kết → Người xem” rồi tải lại.")))
                    }
                    return
                }
            }

            // Dự phòng 2: Xuất tab CSV (ưu tiên đúng gid trong link nếu có)
            let gidQuery = thongTin.gid.map { "&gid=\($0)" } ?? ""
            guard let urlCsv = URL(string: "https://docs.google.com/spreadsheets/d/\(thongTin.spreadsheetId)/export?format=csv\(gidQuery)") else {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError.dmx("Không đọc được bảng lịch tuần hợp lệ trong Google Trang tính (HTTP \(status)).")))
                }
                return
            }
            self.taiCSV(url: urlCsv, tenSheet: "Trang tính", nhom: nhom, hoanTat: hoanTat)
        }.resume()
    }

    private func taiCSV(
        url: URL,
        tenSheet: String,
        nhom: NhomNhanSuLich,
        hoanTat: @escaping (Result<(dsKhoi: [KhoiLichTuanExcel], tenNguon: String), Error>) -> Void
    ) {
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: req) { data, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let finalURL = response?.url?.absoluteString.lowercased() ?? ""
            if let error {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError.dmx("Lỗi mạng khi tải Trang tính: \(error.localizedDescription)")))
                }
                return
            }
            if status == 401 || status == 403 || finalURL.contains("accounts.google.com") {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError.dmx("Trang tính chưa mở quyền xem công khai. Hãy bật “Bất kỳ ai có đường liên kết → Người xem”.")))
                }
                return
            }
            guard status == 200, let data, let csvText = String(data: data, encoding: .utf8), !csvText.isEmpty else {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError.dmx("Không tải được dữ liệu Trang tính (HTTP \(status)).")))
                }
                return
            }
            let dauLow = csvText.prefix(400).lowercased()
            if dauLow.contains("<html") || dauLow.contains("<!doctype html") {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError.dmx("Google Trang tính đang yêu cầu đăng nhập. Hãy chia sẻ công khai ở chế độ Người xem.")))
                }
                return
            }

            let cacDong = Self.phanTichCSV(csvText)
            let sheet = BangSheetExcel(tenSheet: tenSheet, cacDong: cacDong)
            let dsKhoi = BoPhanTichLichCaExcel.phanTichSheets([sheet], nhom: nhom)
            DispatchQueue.main.async {
                if dsKhoi.isEmpty {
                    hoanTat(.failure(NSError.dmx("Đã tải Trang tính nhưng không tìm thấy bảng lịch theo Thứ 2 – Chủ nhật hợp lệ.")))
                } else {
                    hoanTat(.success((dsKhoi: dsKhoi, tenNguon: "Google Trang tính")))
                }
            }
        }.resume()
    }

    static func phanTichCSV(_ text: String) -> [[String]] {
        let sach = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        var cacDong: [[String]] = []
        var dong: [String] = []
        var o = ""
        var trongNgoac = false
        let chars = Array(sach)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if trongNgoac {
                if c == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        o.append("\"")
                        i += 1
                    } else {
                        trongNgoac = false
                    }
                } else {
                    o.append(c)
                }
            } else {
                if c == "\"" {
                    trongNgoac = true
                } else if c == "," {
                    dong.append(o.trimmingCharacters(in: .whitespacesAndNewlines))
                    o = ""
                } else if c == "\n" {
                    dong.append(o.trimmingCharacters(in: .whitespacesAndNewlines))
                    o = ""
                    if dong.contains(where: { !$0.isEmpty }) {
                        cacDong.append(dong)
                    }
                    dong = []
                } else {
                    o.append(c)
                }
            }
            i += 1
        }
        dong.append(o.trimmingCharacters(in: .whitespacesAndNewlines))
        if dong.contains(where: { !$0.isEmpty }) {
            cacDong.append(dong)
        }
        return cacDong
    }
}

// MARK: - 2. Bộ Phân Tích Vị Trí Google Maps (Link rút gọn maps.app.goo.gl, Link đầy đủ, Tọa độ thô)

final class BoPhanTichLinkGoogleMaps {
    static let dungChung = BoPhanTichLinkGoogleMaps()
    private init() {}

    static func khoangCachMet(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let a = CLLocation(latitude: lat1, longitude: lon1)
        let b = CLLocation(latitude: lat2, longitude: lon2)
        return a.distance(from: b)
    }

    static func toaDoHopLe(lat: Double, lon: Double) -> Bool {
        return lat >= -90.0 && lat <= 90.0 && lon >= -180.0 && lon <= 180.0 && (abs(lat) > 0.001 || abs(lon) > 0.001)
    }

    static func trichToaDoTrucTiep(tu chuoi: String) -> CLLocationCoordinate2D? {
        let giaiMa = chuoi.removingPercentEncoding ?? chuoi
        let cacMau: [String] = [
            // 1. Tọa độ ghim chính xác nhất trong link Google Maps (!3d...!4d...)
            #"!3d(-?\d{1,2}\.\d{3,})!4d(-?\d{1,3}\.\d{3,})"#,
            // 2. Tham số q=, query=, ll=, center=, destination=, sll=
            #"[?&](?:q|query|ll|center|destination|sll)=(-?\d{1,2}\.\d{3,})[,\s+]+(-?\d{1,3}\.\d{3,})"#,
            // 3. Tọa độ ngay sau /place/ hoặc /search/
            #"/(?:place|search)/(-?\d{1,2}\.\d{3,})[,\s+]+(-?\d{1,3}\.\d{3,})"#,
            // 4. Tâm bản đồ /@lat,lon
            #"/@(-?\d{1,2}\.\d{3,}),(-?\d{1,3}\.\d{3,})"#,
            // 5. Tọa độ thô dán thẳng (VD: 16.05442, 108.20221)
            #"(?:^|[\s(])(-?\d{1,2}\.\d{4,})\s*[,;\s]\s*(-?\d{1,3}\.\d{4,})(?:$|[\s),])"#
        ]
        for pattern in cacMau {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let m = regex.firstMatch(in: giaiMa, range: NSRange(giaiMa.startIndex..., in: giaiMa)),
               let r1 = Range(m.range(at: 1), in: giaiMa),
               let r2 = Range(m.range(at: 2), in: giaiMa),
               let lat = Double(giaiMa[r1]),
               let lon = Double(giaiMa[r2]),
               toaDoHopLe(lat: lat, lon: lon) {
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
        }
        return nil
    }

    static func trichURLDauTien(trong text: String) -> URL? {
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let matches = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
            if let url = matches.first?.url {
                return url
            }
        }
        let sach = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return URL(string: sach)
    }

    func giaiMaViTri(
        tu input: String,
        hoanTat: @escaping (Result<(toaDo: CLLocationCoordinate2D, linkChuan: String), Error>) -> Void
    ) {
        let sach = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sach.isEmpty else {
            DispatchQueue.main.async {
                hoanTat(.failure(NSError.dmx("Hãy dán đường dẫn vị trí Google Maps hoặc tọa độ (vĩ độ, kinh độ).")))
            }
            return
        }

        if let toaDo = Self.trichToaDoTrucTiep(tu: sach) {
            DispatchQueue.main.async {
                hoanTat(.success((toaDo: toaDo, linkChuan: sach)))
            }
            return
        }

        guard let url = Self.trichURLDauTien(trong: sach),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            DispatchQueue.main.async {
                hoanTat(.failure(NSError.dmx("Không đọc được tọa độ từ nội dung vừa dán. Hãy bấm Chia sẻ vị trí trên Google Maps (link maps.app.goo.gl hoặc tọa độ 16.xxxx, 108.xxxx).")))
            }
            return
        }

        // Giải link rút gọn Google Maps (maps.app.goo.gl / goo.gl/maps)
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError.dmx("Không mở được link rút gọn Google Maps: \(error.localizedDescription)")))
                }
                return
            }
            if let finalUrlStr = response?.url?.absoluteString,
               let toaDo = Self.trichToaDoTrucTiep(tu: finalUrlStr) {
                DispatchQueue.main.async {
                    hoanTat(.success((toaDo: toaDo, linkChuan: finalUrlStr)))
                }
                return
            }
            if let data, let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) {
                if let toaDo = Self.trichToaDoTrucTiep(tu: html) {
                    DispatchQueue.main.async {
                        hoanTat(.success((toaDo: toaDo, linkChuan: response?.url?.absoluteString ?? url.absoluteString)))
                    }
                    return
                }
            }
            DispatchQueue.main.async {
                hoanTat(.failure(NSError.dmx("Link Google Maps không chứa tọa độ rõ ràng. Hãy thử ghim vị trí hiện tại trên Google Maps rồi bấm Chia sẻ lại.")))
            }
        }.resume()
    }
}

// MARK: - 3. Mô Hình & Kho Lưu Bằng Chứng Kiểm Soát Phát Tờ Rơi (Vị trí Google Maps + Ảnh Minh Chứng)

struct BangChungPhatToRoi: Codable, Equatable {
    let id: String
    let oMaTranId: String
    let tuyenId: String
    let tenTuyen: String
    let diemId: String
    let tenDiaDiem: String
    let tenNhanSu: String
    let linkGoogleMapsGoc: String
    let viDoCheckIn: Double
    let kinhDoCheckIn: Double
    /// -1 nếu tuyến chưa có tọa độ mục tiêu để so sánh
    let khoangCachDenDiemMet: Double
    let nguongHopLeMet: Double
    let tenTepAnh: String
    let thoiGianGhiNhan: String
    let ghiChu: String

    var trangThaiViTri: (hopLe: Bool, nhan: String, mau: UIColor) {
        if khoangCachDenDiemMet < 0 {
            return (true, "📍 Đã ghi nhận GPS", BangMauBCTD.xanhChuDaoDam)
        }
        let kcText = khoangCachDenDiemMet >= 1000
            ? String(format: "%.2f km", khoangCachDenDiemMet / 1000.0)
            : "\(Int(khoangCachDenDiemMet.rounded()))m"
        if khoangCachDenDiemMet <= nguongHopLeMet {
            return (true, "🟢 Đúng địa điểm (\(kcText))", BangMauBCTD.xanhLaDam)
        } else if khoangCachDenDiemMet <= nguongHopLeMet * 2.0 {
            return (false, "🟡 Gần khu vực (\(kcText))", BangMauBCTD.camPhanTich)
        } else {
            return (false, "🔴 Lệch xa địa điểm (\(kcText))", .systemRed)
        }
    }

    var thoiGianHienThi: String {
        let iso = ISO8601DateFormatter()
        guard let d = iso.date(from: thoiGianGhiNhan) else { return thoiGianGhiNhan }
        let df = DateFormatter()
        df.locale = Locale(identifier: "vi_VN")
        df.dateFormat = "HH:mm dd/MM/yyyy"
        return df.string(from: d)
    }
}

final class KhoBangChungPhatToRoi {
    static let dungChung = KhoBangChungPhatToRoi()
    private init() {}

    private let hangDoiGhi = DispatchQueue(label: "com.thanhduong.v2dmx.bangchung.toroi", qos: .utility)
    private let khoa = NSLock()
    private var boNhoDem: [BangChungPhatToRoi]? = nil

    private var thuMucLuu: URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("DMX_BangChungToRoi", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var tepDanhSach: URL {
        thuMucLuu.appendingPathComponent("danh_sach_bang_chung.json")
    }

    func layTatCa() -> [BangChungPhatToRoi] {
        khoa.lock()
        defer { khoa.unlock() }
        if let cache = boNhoDem { return cache }
        guard let data = try? Data(contentsOf: tepDanhSach),
              let ds = try? JSONDecoder().decode([BangChungPhatToRoi].self, from: data) else {
            boNhoDem = []
            return []
        }
        boNhoDem = ds
        return ds
    }

    func layBangChung(choOId oId: String) -> [BangChungPhatToRoi] {
        return layTatCa().filter { $0.oMaTranId == oId }
    }

    func layBangChung(choTuyenId tuyenId: String) -> [BangChungPhatToRoi] {
        return layTatCa().filter { $0.tuyenId == tuyenId }
    }

    func themBangChung(_ banGhi: BangChungPhatToRoi, anh: UIImage, hoanTat: @escaping (Result<BangChungPhatToRoi, Error>) -> Void) {
        hangDoiGhi.async {
            guard let duLieuAnh = self.nenAnhMinhChung(anh) else {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError.dmx("Không nén được ảnh minh chứng.")))
                }
                return
            }
            let duongDanAnh = self.thuMucLuu.appendingPathComponent(banGhi.tenTepAnh)
            do {
                try duLieuAnh.write(to: duongDanAnh, options: .atomic)
            } catch {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError.dmx("Không lưu được ảnh minh chứng: \(error.localizedDescription)")))
                }
                return
            }

            self.khoa.lock()
            var ds = self.boNhoDem ?? self.docKhongKhoa()
            ds.insert(banGhi, at: 0)
            self.boNhoDem = ds
            let jsonData = try? JSONEncoder().encode(ds)
            self.khoa.unlock()

            if let jsonData {
                try? jsonData.write(to: self.tepDanhSach, options: .atomic)
            }
            DispatchQueue.main.async {
                hoanTat(.success(banGhi))
            }
        }
    }

    func xoaBangChung(id: String) {
        khoa.lock()
        var ds = boNhoDem ?? docKhongKhoa()
        let biXoa = ds.first(where: { $0.id == id })
        ds.removeAll { $0.id == id }
        boNhoDem = ds
        let jsonData = try? JSONEncoder().encode(ds)
        khoa.unlock()

        hangDoiGhi.async {
            if let tenTep = biXoa?.tenTepAnh, !tenTep.isEmpty {
                try? FileManager.default.removeItem(at: self.thuMucLuu.appendingPathComponent(tenTep))
            }
            if let jsonData {
                try? jsonData.write(to: self.tepDanhSach, options: .atomic)
            }
        }
    }

    func taiAnh(tenTep: String) -> UIImage? {
        guard !tenTep.isEmpty else { return nil }
        let url = thuMucLuu.appendingPathComponent(tenTep)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func docKhongKhoa() -> [BangChungPhatToRoi] {
        guard let data = try? Data(contentsOf: tepDanhSach),
              let ds = try? JSONDecoder().decode([BangChungPhatToRoi].self, from: data) else {
            return []
        }
        return ds
    }

    private func nenAnhMinhChung(_ img: UIImage) -> Data? {
        return autoreleasepool {
            let maxSide: CGFloat = 1440
            let w = img.size.width * img.scale
            let h = img.size.height * img.scale
            guard w > 10, h > 10 else { return img.jpegData(compressionQuality: 0.78) }
            let canhLon = max(w, h)
            let tiLe = canhLon > maxSide ? (maxSide / canhLon) : CGFloat(1.0)
            let size = CGSize(width: max(1, (w * tiLe).rounded()), height: max(1, (h * tiLe).rounded()))
            let fmt = UIGraphicsImageRendererFormat()
            fmt.scale = 1.0
            fmt.opaque = true
            let anhChuan = UIGraphicsImageRenderer(size: size, format: fmt).image { _ in
                img.draw(in: CGRect(origin: .zero, size: size))
            }
            return anhChuan.jpegData(compressionQuality: 0.78)
        }
    }
}

// MARK: - 4. Màn Hình Thêm / Bớt Nhân Sự Cho Từng Tuyến / Buổi

final class HopChinhSuaNhanSuTuyenViewController: UIViewController {
    private var oMaTran: OMaTranPhatToRoi
    private let khoiPG: KhoiLichTuanExcel?
    private let khoiNV: KhoiLichTuanExcel?
    private let keHoachTuan: KeHoachMaTranTuan
    private let khiLuu: (OMaTranPhatToRoi) -> Void

    private let cuon = UIScrollView()
    private let ngan = UIStackView()
    private let nganDangPhan = UIStackView()
    private let nganGoiY = UIStackView()

    init(
        oMaTran: OMaTranPhatToRoi,
        khoiPG: KhoiLichTuanExcel?,
        khoiNV: KhoiLichTuanExcel?,
        keHoachTuan: KeHoachMaTranTuan,
        khiLuu: @escaping (OMaTranPhatToRoi) -> Void
    ) {
        self.oMaTran = oMaTran
        self.khoiPG = khoiPG
        self.khoiNV = khoiNV
        self.keHoachTuan = keHoachTuan
        self.khiLuu = khiLuu
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Khong ho tro coder") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "👥 Sửa nhân sự tuyến"
        view.backgroundColor = BangMauBCTD.nenTrang
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Huỷ", style: .plain, target: self, action: #selector(bamHuy))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Lưu", style: .done, target: self, action: #selector(bamLuu))
        dungGiaoDien()
        veLaiToanBo()
    }

    @objc private func bamHuy() { dismiss(animated: true) }

    @objc private func bamLuu() {
        khiLuu(oMaTran)
        dismiss(animated: true)
    }

    private func dungGiaoDien() {
        cuon.translatesAutoresizingMaskIntoConstraints = false
        cuon.alwaysBounceVertical = true
        view.addSubview(cuon)

        ngan.axis = .vertical
        ngan.spacing = 12
        ngan.translatesAutoresizingMaskIntoConstraints = false
        cuon.addSubview(ngan)

        NSLayoutConstraint.activate([
            cuon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cuon.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cuon.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cuon.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            ngan.topAnchor.constraint(equalTo: cuon.contentLayoutGuide.topAnchor, constant: 12),
            ngan.leadingAnchor.constraint(equalTo: cuon.frameLayoutGuide.leadingAnchor, constant: 14),
            ngan.trailingAnchor.constraint(equalTo: cuon.frameLayoutGuide.trailingAnchor, constant: -14),
            ngan.bottomAnchor.constraint(equalTo: cuon.contentLayoutGuide.bottomAnchor, constant: -24)
        ])

        let tenThu = (oMaTran.thuIndex >= 0 && oMaTran.thuIndex < BoPhanTichLichCaExcel.tenThu.count)
            ? BoPhanTichLichCaExcel.tenThu[oMaTran.thuIndex] : "Thứ"
        let (theTieuDe, stackTD) = taoThe(tieuDe: "🛣️ \(oMaTran.tenTuyen)")
        stackTD.addArrangedSubview(taoNhan("\(tenThu) • Buổi \(oMaTran.buoi)\n\(oMaTran.moTaTuyen)"))
        ngan.addArrangedSubview(theTieuDe)

        let (theDangPhan, stackDP) = taoThe(tieuDe: "✅ Nhân sự đang phân cho tuyến này (bấm Bớt để gỡ)")
        nganDangPhan.axis = .vertical
        nganDangPhan.spacing = 7
        stackDP.addArrangedSubview(nganDangPhan)

        let nutThemTay = UIButton(type: .system)
        nutThemTay.setTitle("＋ Thêm nhân sự nhập tay (ngoài danh sách)", for: .normal)
        cauHinhNut(nutThemTay, mauNen: BangMauBCTD.xanhChuDao, mauChu: .white)
        nutThemTay.addTarget(self, action: #selector(bamThemNhanSuNhapTay), for: .touchUpInside)
        stackDP.addArrangedSubview(nutThemTay)
        ngan.addArrangedSubview(theDangPhan)

        let (theGoiY, stackGY) = taoThe(tieuDe: "➕ Thêm nhanh từ lịch PG / NV tuần này")
        nganGoiY.axis = .vertical
        nganGoiY.spacing = 7
        stackGY.addArrangedSubview(nganGoiY)
        ngan.addArrangedSubview(theGoiY)
    }

    private func tenGoc(_ chuoi: String) -> String {
        return chuoi.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? chuoi
    }

    private func veLaiToanBo() {
        nganDangPhan.arrangedSubviews.forEach { nganDangPhan.removeArrangedSubview($0); $0.removeFromSuperview() }
        nganGoiY.arrangedSubviews.forEach { nganGoiY.removeArrangedSubview($0); $0.removeFromSuperview() }

        let tong = oMaTran.danhSachPG.count + oMaTran.danhSachNV.count
        if tong == 0 {
            nganDangPhan.addArrangedSubview(taoNhan("Chưa có nhân sự nào trong tuyến này. Hãy thêm bên dưới."))
        } else {
            for (idx, p) in oMaTran.danhSachPG.enumerated() {
                nganDangPhan.addArrangedSubview(taoDongDangPhan(nhom: .pg, index: idx, text: "👩‍💼 PG: \(p)"))
            }
            for (idx, n) in oMaTran.danhSachNV.enumerated() {
                nganDangPhan.addArrangedSubview(taoDongDangPhan(nhom: .nhanVien, index: idx, text: "🧑‍🔧 NV: \(n)"))
            }
        }

        // Xây dựng tập nhân sự đã gán ở buổi này và các buổi khác trong tuần
        let dangCoTrongO = Set((oMaTran.danhSachPG + oMaTran.danhSachNV).map { BoPhanTichLichCaExcel.chuanHoa(tenGoc($0)) })
        var daPhatTuanKhac: Set<String> = []
        for other in keHoachTuan.cacO where other.id != oMaTran.id {
            for s in (other.danhSachPG + other.danhSachNV) {
                daPhatTuanKhac.insert(BoPhanTichLichCaExcel.chuanHoa(tenGoc(s)))
            }
        }

        let tatCaNguoi: [LichTuanMotNguoi] = (khoiPG?.danhSachNguoi ?? []) + (khoiNV?.danhSachNguoi ?? [])
        if tatCaNguoi.isEmpty {
            nganGoiY.addArrangedSubview(taoNhan("Chưa tải Trang tính lịch PG / NV. Bạn vẫn có thể bấm “＋ Thêm nhân sự nhập tay” ở trên."))
            return
        }

        let laSang = (oMaTran.buoi == "Sáng")
        struct UngVien {
            let nguoi: LichTuanMotNguoi
            let dungCa: Bool
            let daPhatKhac: Bool
            let moTaCa: String
        }

        var dsUngVien: [UngVien] = []
        for nguoi in tatCaNguoi {
            let key = BoPhanTichLichCaExcel.chuanHoa(nguoi.ten)
            if dangCoTrongO.contains(key) { continue }
            let ca = (oMaTran.thuIndex >= 0 && oMaTran.thuIndex < nguoi.lich7Ngay.count) ? nguoi.lich7Ngay[oMaTran.thuIndex] : nil
            let dungCa = ca.map { laSang ? $0.dangLamSang : $0.dangLamChieu } ?? false
            let moTaCa: String
            if let ca, !ca.nhanCaGoc.isEmpty || !ca.gioLamGoc.isEmpty {
                moTaCa = ca.gioLamGoc.isEmpty ? ca.nhanCaGoc : "\(ca.nhanCaGoc) \(ca.gioLamGoc)"
            } else {
                moTaCa = "Không rõ ca"
            }
            dsUngVien.append(UngVien(nguoi: nguoi, dungCa: dungCa, daPhatKhac: daPhatTuanKhac.contains(key), moTaCa: moTaCa))
        }

        dsUngVien.sort { a, b in
            if a.dungCa != b.dungCa { return a.dungCa && !b.dungCa }
            if a.daPhatKhac != b.daPhatKhac { return !a.daPhatKhac && b.daPhatKhac }
            return a.nguoi.ten < b.nguoi.ten
        }

        if dsUngVien.isEmpty {
            nganGoiY.addArrangedSubview(taoNhan("Tất cả nhân sự trong bảng lịch đã nằm trong tuyến này."))
            return
        }

        for uv in dsUngVien {
            let icon = (uv.nguoi.nhom == .pg) ? "👩‍💼 PG" : "🧑‍🔧 NV"
            let trangThai: String
            let mauTrangThai: UIColor
            if uv.dungCa && !uv.daPhatKhac {
                trangThai = "🟢 Đúng ca (\(uv.moTaCa)) • Chưa phát tuần này"
                mauTrangThai = BangMauBCTD.xanhLaDam
            } else if uv.dungCa && uv.daPhatKhac {
                trangThai = "🟡 Đúng ca (\(uv.moTaCa)) • Đã có lịch buổi khác"
                mauTrangThai = BangMauBCTD.camPhanTich
            } else {
                trangThai = "⚪ Khác ca (\(uv.moTaCa))"
                mauTrangThai = BangMauBCTD.chuPhu
            }

            let dong = UIStackView()
            dong.axis = .horizontal
            dong.alignment = .center
            dong.spacing = 8
            dong.isLayoutMarginsRelativeArrangement = true
            dong.layoutMargins = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 8)
            dong.backgroundColor = BangMauBCTD.nenThePhu
            dong.layer.cornerRadius = 9
            dong.layer.borderWidth = 1
            dong.layer.borderColor = BangMauBCTD.vienThe.cgColor

            let cotChu = UIStackView()
            cotChu.axis = .vertical
            cotChu.spacing = 2
            cotChu.addArrangedSubview(taoNhan("\(icon): \(uv.nguoi.ten)", dam: true))
            let lbTT = taoNhan(trangThai)
            lbTT.textColor = mauTrangThai
            cotChu.addArrangedSubview(lbTT)

            let tenDayDu = "\(uv.nguoi.ten) (\(uv.moTaCa))"
            let nhom = uv.nguoi.nhom
            let nutThem = UIButton(type: .system)
            nutThem.setTitle("＋ Thêm", for: .normal)
            cauHinhNut(nutThem, mauNen: BangMauBCTD.xanhLaDam, mauChu: .white)
            nutThem.setContentHuggingPriority(.required, for: .horizontal)
            nutThem.setContentCompressionResistancePriority(.required, for: .horizontal)
            nutThem.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                if nhom == .pg {
                    self.oMaTran.danhSachPG.append(tenDayDu)
                } else {
                    self.oMaTran.danhSachNV.append(tenDayDu)
                }
                self.veLaiToanBo()
            }, for: .touchUpInside)

            dong.addArrangedSubview(cotChu)
            dong.addArrangedSubview(nutThem)
            nganGoiY.addArrangedSubview(dong)
        }
    }

    private func taoDongDangPhan(nhom: NhomNhanSuLich, index: Int, text: String) -> UIView {
        let dong = UIStackView()
        dong.axis = .horizontal
        dong.alignment = .center
        dong.spacing = 8
        dong.isLayoutMarginsRelativeArrangement = true
        dong.layoutMargins = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 8)
        dong.backgroundColor = BangMauBCTD.nenHeaderPhu
        dong.layer.cornerRadius = 9
        dong.layer.borderWidth = 1
        dong.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor

        let lb = taoNhan(text, dam: true)
        let nutBot = UIButton(type: .system)
        nutBot.setTitle("✕ Bớt", for: .normal)
        cauHinhNut(nutBot, mauNen: UIColor.systemRed.withAlphaComponent(0.12), mauChu: .systemRed)
        nutBot.setContentHuggingPriority(.required, for: .horizontal)
        nutBot.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutBot.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            if nhom == .pg, self.oMaTran.danhSachPG.indices.contains(index) {
                self.oMaTran.danhSachPG.remove(at: index)
            } else if nhom == .nhanVien, self.oMaTran.danhSachNV.indices.contains(index) {
                self.oMaTran.danhSachNV.remove(at: index)
            }
            self.veLaiToanBo()
        }, for: .touchUpInside)

        dong.addArrangedSubview(lb)
        dong.addArrangedSubview(nutBot)
        return dong
    }

    @objc private func bamThemNhanSuNhapTay() {
        let tb = UIAlertController(
            title: "Thêm nhân sự vào tuyến",
            message: "Nhập tên nhân sự (PG hoặc Nhân viên siêu thị):",
            preferredStyle: .alert
        )
        tb.addTextField { tf in
            tf.placeholder = "Ví dụ: Nguyễn Văn A (Sáng)"
        }
        tb.addAction(UIAlertAction(title: "Thêm làm PG", style: .default) { [weak self, weak tb] _ in
            let ten = (tb?.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !ten.isEmpty else { return }
            self?.oMaTran.danhSachPG.append(ten)
            self?.veLaiToanBo()
        })
        tb.addAction(UIAlertAction(title: "Thêm làm NV siêu thị", style: .default) { [weak self, weak tb] _ in
            let ten = (tb?.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !ten.isEmpty else { return }
            self?.oMaTran.danhSachNV.append(ten)
            self?.veLaiToanBo()
        })
        tb.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        present(tb, animated: true)
    }

    private func taoThe(tieuDe: String) -> (UIView, UIStackView) {
        let the = UIView()
        the.backgroundColor = BangMauBCTD.nenThe
        the.layer.cornerRadius = 12
        the.layer.borderWidth = 1
        the.layer.borderColor = BangMauBCTD.vienThe.cgColor

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        the.addSubview(stack)
        stack.addArrangedSubview(taoNhan(tieuDe, dam: true))

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: the.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: the.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: the.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: the.bottomAnchor, constant: -12)
        ])
        return (the, stack)
    }

    private func taoNhan(_ text: String, dam: Bool = false) -> UILabel {
        let l = UILabel()
        l.text = text
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.adjustsFontSizeToFitWidth = false
        l.textColor = BangMauBCTD.chuChinh
        l.font = .systemFont(ofSize: dam ? 13.5 : 12.5, weight: dam ? .bold : .regular)
        return l
    }

    private func cauHinhNut(_ b: UIButton, mauNen: UIColor, mauChu: UIColor) {
        b.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        b.titleLabel?.numberOfLines = 0
        b.titleLabel?.lineBreakMode = .byWordWrapping
        b.titleLabel?.adjustsFontSizeToFitWidth = false
        b.backgroundColor = mauNen
        b.setTitleColor(mauChu, for: .normal)
        b.layer.cornerRadius = 8
        b.contentEdgeInsets = UIEdgeInsets(top: 7, left: 10, bottom: 7, right: 10)
    }
}

// MARK: - 5. Màn Hình Kiểm Soát Nhân Sự Phát Tờ Rơi (Dán Vị Trí Google Maps + Úp 1 Ảnh Minh Chứng)

final class ManHinhKiemSoatPhatToRoiViewController: UIViewController, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {
    private let oMaTran: OMaTranPhatToRoi
    private let tuyen: TuyenPhatToRoiMaTran?
    private let nguongMet: Double
    private let khiCapNhat: (_ coBangChungMoi: Bool) -> Void

    private let cuon = UIScrollView()
    private let ngan = UIStackView()
    private let nganDiemMucTieu = UIStackView()
    private let nutChonNhanSu = UIButton(type: .system)
    private let oTenNhanSu = UITextField()
    private let oLinkGoogleMaps = UITextField()
    private let vongQuayViTri = UIActivityIndicatorView(style: .medium)
    private let nhanKetQuaViTri = UILabel()
    private let anhMinhChungView = UIImageView()
    private let nhanChuaCoAnh = UILabel()
    private let oGhiChu = UITextField()
    private let nutLuuBangChung = UIButton(type: .system)
    private let nganDanhSachBangChung = UIStackView()

    private let quanLyViTri = CLLocationManager()
    private var danhSachDiem: [DiemMucTieuTuyen] = []
    private var diemDangChonId: String = "chung"
    private var toaDoDaPhanTich: CLLocationCoordinate2D? = nil
    private var linkChuanDaPhanTich: String = ""
    private var khoangCachHienTaiMet: Double = -1
    private var anhDaChon: UIImage? = nil
    private var danhSachBangChung: [BangChungPhatToRoi] = []

    init(
        oMaTran: OMaTranPhatToRoi,
        tuyen: TuyenPhatToRoiMaTran?,
        nguongMet: Double,
        khiCapNhat: @escaping (_ coBangChungMoi: Bool) -> Void
    ) {
        self.oMaTran = oMaTran
        self.tuyen = tuyen
        self.nguongMet = nguongMet
        self.khiCapNhat = khiCapNhat
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Khong ho tro coder") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "📍 Kiểm soát phát tờ rơi"
        view.backgroundColor = BangMauBCTD.nenTrang
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Đóng", style: .done, target: self, action: #selector(bamDong))

        quanLyViTri.delegate = self
        quanLyViTri.desiredAccuracy = kCLLocationAccuracyBest

        danhSachDiem = tuyen?.cacDiemMucTieu ?? []
        if let dau = danhSachDiem.first {
            diemDangChonId = dau.id
        } else {
            diemDangChonId = "chung"
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(anBanPhim))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        dungGiaoDien()
        napDanhSachBangChung()
    }

    @objc private func bamDong() { dismiss(animated: true) }
    @objc private func anBanPhim() { view.endEditing(true) }

    private func dungGiaoDien() {
        cuon.translatesAutoresizingMaskIntoConstraints = false
        cuon.keyboardDismissMode = .interactive
        cuon.alwaysBounceVertical = true
        view.addSubview(cuon)

        ngan.axis = .vertical
        ngan.spacing = 12
        ngan.translatesAutoresizingMaskIntoConstraints = false
        cuon.addSubview(ngan)

        NSLayoutConstraint.activate([
            cuon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cuon.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cuon.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cuon.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            ngan.topAnchor.constraint(equalTo: cuon.contentLayoutGuide.topAnchor, constant: 12),
            ngan.leadingAnchor.constraint(equalTo: cuon.frameLayoutGuide.leadingAnchor, constant: 14),
            ngan.trailingAnchor.constraint(equalTo: cuon.frameLayoutGuide.trailingAnchor, constant: -14),
            ngan.bottomAnchor.constraint(equalTo: cuon.contentLayoutGuide.bottomAnchor, constant: -26)
        ])

        // 1. Thẻ thông tin tuyến & danh sách điểm cần kiểm soát
        let tenThu = (oMaTran.thuIndex >= 0 && oMaTran.thuIndex < BoPhanTichLichCaExcel.tenThu.count)
            ? BoPhanTichLichCaExcel.tenThu[oMaTran.thuIndex] : "Thứ"
        let (theDiem, stackDiem) = taoThe(tieuDe: "1. Chọn địa điểm cần kiểm soát (\(tenThu) • \(oMaTran.buoi))")
        stackDiem.addArrangedSubview(taoNhan("🛣️ \(oMaTran.tenTuyen)\n\(oMaTran.moTaTuyen)"))
        nganDiemMucTieu.axis = .vertical
        nganDiemMucTieu.spacing = 6
        stackDiem.addArrangedSubview(nganDiemMucTieu)
        ngan.addArrangedSubview(theDiem)

        // 2. Thẻ nộp bằng chứng (Vị trí Google Maps + 1 Ảnh minh chứng)
        let (theNop, stackNop) = taoThe(tieuDe: "2. Xác nhận đã phát (Vị trí Google Maps + 1 Ảnh)")

        // Nhân sự thực hiện
        let cacNhanSu = oMaTran.danhSachPG + oMaTran.danhSachNV
        if !cacNhanSu.isEmpty {
            let dsTen = cacNhanSu.map { $0.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? $0 }
            oTenNhanSu.text = dsTen.first
            nutChonNhanSu.contentHorizontalAlignment = .left
            cauHinhNut(nutChonNhanSu, mauNen: BangMauBCTD.nenThePhu, mauChu: BangMauBCTD.chuChinh, coVien: true)
            nutChonNhanSu.menu = UIMenu(title: "Chọn nhân sự trong tuyến", children: dsTen.map { ten in
                UIAction(title: ten) { [weak self] _ in
                    self?.oTenNhanSu.text = ten
                    self?.nutChonNhanSu.setTitle("👤 Nhân sự: \(ten) ▾", for: .normal)
                }
            })
            nutChonNhanSu.showsMenuAsPrimaryAction = true
            nutChonNhanSu.setTitle("👤 Nhân sự: \(dsTen.first ?? "") ▾", for: .normal)
            stackNop.addArrangedSubview(nutChonNhanSu)
        }
        cauHinhTextField(oTenNhanSu, goiY: "Tên nhân viên / PG đi phát")
        stackNop.addArrangedSubview(oTenNhanSu)

        // Ô dán link Google Maps
        stackNop.addArrangedSubview(taoNhan("Vị trí Google Maps nhân viên đang đi (bắt buộc):", dam: true))
        cauHinhTextField(oLinkGoogleMaps, goiY: "Dán link Google Maps (maps.app.goo.gl/...) hoặc tọa độ")
        oLinkGoogleMaps.addTarget(self, action: #selector(khiSuaLinkGoogleMaps), for: .editingDidEnd)
        stackNop.addArrangedSubview(oLinkGoogleMaps)

        let nutDanViTri = UIButton(type: .system)
        nutDanViTri.setTitle("📋 Dán link Google Maps", for: .normal)
        cauHinhNut(nutDanViTri, mauNen: BangMauBCTD.xanhChuDao, mauChu: .white)
        nutDanViTri.addTarget(self, action: #selector(bamDanLinkGoogleMaps), for: .touchUpInside)

        let nutLayGPS = UIButton(type: .system)
        nutLayGPS.setTitle("📍 Lấy GPS máy này", for: .normal)
        cauHinhNut(nutLayGPS, mauNen: BangMauBCTD.nenHeaderPhu, mauChu: BangMauBCTD.xanhChuDaoDam, coVien: true)
        nutLayGPS.addTarget(self, action: #selector(bamLayGPSMayNay), for: .touchUpInside)

        let hangNutViTri = UIStackView(arrangedSubviews: [nutDanViTri, nutLayGPS])
        hangNutViTri.axis = .horizontal
        hangNutViTri.spacing = 8
        hangNutViTri.distribution = .fillEqually
        stackNop.addArrangedSubview(hangNutViTri)

        vongQuayViTri.hidesWhenStopped = true
        nhanKetQuaViTri.font = .systemFont(ofSize: 12.5, weight: .semibold)
        nhanKetQuaViTri.textColor = BangMauBCTD.chuPhu
        nhanKetQuaViTri.numberOfLines = 0
        nhanKetQuaViTri.lineBreakMode = .byWordWrapping
        nhanKetQuaViTri.adjustsFontSizeToFitWidth = false
        nhanKetQuaViTri.text = "Chưa có tọa độ kiểm soát. Dán link Google Maps để app tự đo khoảng cách tới địa điểm."
        let hangKQViTri = UIStackView(arrangedSubviews: [vongQuayViTri, nhanKetQuaViTri])
        hangKQViTri.axis = .horizontal
        hangKQViTri.spacing = 8
        hangKQViTri.alignment = .center
        stackNop.addArrangedSubview(hangKQViTri)

        // Khung ảnh minh chứng (1 tấm)
        stackNop.addArrangedSubview(taoNhan("Ảnh minh chứng đã phát tại địa điểm (bắt buộc 1 tấm):", dam: true))
        let khungAnh = UIView()
        khungAnh.backgroundColor = BangMauBCTD.nenThePhu
        khungAnh.layer.cornerRadius = 10
        khungAnh.layer.borderWidth = 1
        khungAnh.layer.borderColor = BangMauBCTD.vienDam.cgColor
        khungAnh.clipsToBounds = true
        khungAnh.heightAnchor.constraint(equalToConstant: 190).isActive = true

        anhMinhChungView.contentMode = .scaleAspectFit
        anhMinhChungView.translatesAutoresizingMaskIntoConstraints = false
        khungAnh.addSubview(anhMinhChungView)

        nhanChuaCoAnh.text = "📷 Chưa tải ảnh minh chứng.\nChụp hoặc chọn 1 tấm ảnh đã phát tờ rơi tại địa điểm."
        nhanChuaCoAnh.font = .systemFont(ofSize: 12.5, weight: .medium)
        nhanChuaCoAnh.textColor = BangMauBCTD.chuPhu
        nhanChuaCoAnh.textAlignment = .center
        nhanChuaCoAnh.numberOfLines = 0
        nhanChuaCoAnh.lineBreakMode = .byWordWrapping
        nhanChuaCoAnh.adjustsFontSizeToFitWidth = false
        nhanChuaCoAnh.translatesAutoresizingMaskIntoConstraints = false
        khungAnh.addSubview(nhanChuaCoAnh)

        NSLayoutConstraint.activate([
            anhMinhChungView.topAnchor.constraint(equalTo: khungAnh.topAnchor),
            anhMinhChungView.leadingAnchor.constraint(equalTo: khungAnh.leadingAnchor),
            anhMinhChungView.trailingAnchor.constraint(equalTo: khungAnh.trailingAnchor),
            anhMinhChungView.bottomAnchor.constraint(equalTo: khungAnh.bottomAnchor),

            nhanChuaCoAnh.centerYAnchor.constraint(equalTo: khungAnh.centerYAnchor),
            nhanChuaCoAnh.leadingAnchor.constraint(equalTo: khungAnh.leadingAnchor, constant: 12),
            nhanChuaCoAnh.trailingAnchor.constraint(equalTo: khungAnh.trailingAnchor, constant: -12)
        ])
        stackNop.addArrangedSubview(khungAnh)

        let nutChupAnh = UIButton(type: .system)
        nutChupAnh.setTitle("📸 Chụp ảnh trực tiếp", for: .normal)
        cauHinhNut(nutChupAnh, mauNen: BangMauBCTD.xanhLaDam, mauChu: .white)
        nutChupAnh.addTarget(self, action: #selector(bamChupAnh), for: .touchUpInside)

        let nutChonAnh = UIButton(type: .system)
        nutChonAnh.setTitle("🖼️ Chọn 1 ảnh từ máy", for: .normal)
        cauHinhNut(nutChonAnh, mauNen: BangMauBCTD.xanhChuDao, mauChu: .white)
        nutChonAnh.addTarget(self, action: #selector(bamChonAnhThuVien), for: .touchUpInside)

        let hangNutAnh = UIStackView(arrangedSubviews: [nutChupAnh, nutChonAnh])
        hangNutAnh.axis = .horizontal
        hangNutAnh.spacing = 8
        hangNutAnh.distribution = .fillEqually
        stackNop.addArrangedSubview(hangNutAnh)

        cauHinhTextField(oGhiChu, goiY: "Ghi chú thêm (VD: Đã phát 150 tờ cổng chợ)")
        stackNop.addArrangedSubview(oGhiChu)

        nutLuuBangChung.setTitle("✅ Xác nhận & Lưu bằng chứng đã phát", for: .normal)
        cauHinhNut(nutLuuBangChung, mauNen: BangMauBCTD.xanhLaDam, mauChu: .white)
        nutLuuBangChung.titleLabel?.font = .systemFont(ofSize: 14.5, weight: .heavy)
        nutLuuBangChung.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        nutLuuBangChung.addTarget(self, action: #selector(bamLuuBangChung), for: .touchUpInside)
        stackNop.addArrangedSubview(nutLuuBangChung)
        ngan.addArrangedSubview(theNop)

        // 3. Thẻ danh sách bằng chứng đã lưu
        let (theLS, stackLS) = taoThe(tieuDe: "3. Bằng chứng đã nộp của buổi này")
        nganDanhSachBangChung.axis = .vertical
        nganDanhSachBangChung.spacing = 9
        stackLS.addArrangedSubview(nganDanhSachBangChung)
        ngan.addArrangedSubview(theLS)
    }

    private func napDanhSachBangChung() {
        danhSachBangChung = KhoBangChungPhatToRoi.dungChung.layBangChung(choOId: oMaTran.id)
        veDanhSachDiemMucTieu()
        veDanhSachBangChung()
    }

    private func veDanhSachDiemMucTieu() {
        nganDiemMucTieu.arrangedSubviews.forEach { nganDiemMucTieu.removeArrangedSubview($0); $0.removeFromSuperview() }
        let diemDaCo = Set(danhSachBangChung.map { $0.diemId })

        if danhSachDiem.isEmpty {
            let nut = taoNutChonDiem(
                id: "chung",
                tieuDe: "📍 Kiểm soát chung cho \(oMaTran.tenTuyen)",
                daCo: diemDaCo.contains("chung"),
                dangChon: diemDangChonId == "chung"
            )
            nganDiemMucTieu.addArrangedSubview(nut)
            return
        }

        for diem in danhSachDiem {
            let bangChungDiem = danhSachBangChung.first(where: { $0.diemId == diem.id })
            let hauTo = bangChungDiem.map { " — \($0.trangThaiViTri.nhan)" } ?? ""
            let tieuDe = "\(diem.ten) (\(diem.loaiRaw))\(hauTo)"
            let nut = taoNutChonDiem(
                id: diem.id,
                tieuDe: tieuDe,
                daCo: bangChungDiem != nil,
                dangChon: diemDangChonId == diem.id
            )
            nganDiemMucTieu.addArrangedSubview(nut)
        }

        let nutKhac = taoNutChonDiem(
            id: "chung",
            tieuDe: "📍 Điểm khác dọc theo \(oMaTran.tenTuyen)",
            daCo: diemDaCo.contains("chung"),
            dangChon: diemDangChonId == "chung"
        )
        nganDiemMucTieu.addArrangedSubview(nutKhac)
    }

    private func taoNutChonDiem(id: String, tieuDe: String, daCo: Bool, dangChon: Bool) -> UIButton {
        let b = UIButton(type: .system)
        let prefix = daCo ? "✅ " : (dangChon ? "👉 " : "☐ ")
        b.setTitle(prefix + tieuDe, for: .normal)
        b.contentHorizontalAlignment = .left
        b.titleLabel?.font = .systemFont(ofSize: 12.5, weight: dangChon ? .bold : .semibold)
        b.titleLabel?.numberOfLines = 0
        b.titleLabel?.lineBreakMode = .byWordWrapping
        b.titleLabel?.adjustsFontSizeToFitWidth = false
        b.setTitleColor(dangChon ? .white : (daCo ? BangMauBCTD.xanhLaDam : BangMauBCTD.chuChinh), for: .normal)
        b.backgroundColor = dangChon ? BangMauBCTD.xanhChuDao : (daCo ? BangMauBCTD.xanhDatNenDong : BangMauBCTD.nenThePhu)
        b.layer.cornerRadius = 9
        b.layer.borderWidth = 1
        b.layer.borderColor = (dangChon ? BangMauBCTD.xanhChuDaoDam : (daCo ? BangMauBCTD.xanhDatVach : BangMauBCTD.vienDam)).cgColor
        b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        b.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.diemDangChonId = id
            self.veDanhSachDiemMucTieu()
            if let coord = self.toaDoDaPhanTich {
                self.capNhatKhoangCachChoToaDo(coord)
            }
        }, for: .touchUpInside)
        return b
    }

    private func diemMucTieuHienTai() -> DiemMucTieuTuyen? {
        return danhSachDiem.first(where: { $0.id == diemDangChonId })
    }

    @objc private func bamDanLinkGoogleMaps() {
        guard let text = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            hienThongBao(tieuDe: "Bộ nhớ tạm trống", noiDung: "Hãy sao chép link chia sẻ vị trí từ Google Maps trước rồi bấm dán.")
            return
        }
        oLinkGoogleMaps.text = text
        phanTichLinkGoogleMaps(text)
    }

    @objc private func khiSuaLinkGoogleMaps() {
        let text = (oLinkGoogleMaps.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        phanTichLinkGoogleMaps(text)
    }

    private func phanTichLinkGoogleMaps(_ text: String) {
        vongQuayViTri.startAnimating()
        nhanKetQuaViTri.textColor = BangMauBCTD.xanhChuDao
        nhanKetQuaViTri.text = "⏳ Đang giải mã tọa độ từ vị trí Google Maps…"

        BoPhanTichLinkGoogleMaps.dungChung.giaiMaViTri(tu: text) { [weak self] kq in
            guard let self else { return }
            self.vongQuayViTri.stopAnimating()
            switch kq {
            case .success(let res):
                self.toaDoDaPhanTich = res.toaDo
                self.linkChuanDaPhanTich = res.linkChuan
                self.capNhatKhoangCachChoToaDo(res.toaDo)
            case .failure(let loi):
                self.toaDoDaPhanTich = nil
                self.khoangCachHienTaiMet = -1
                self.nhanKetQuaViTri.textColor = .systemRed
                self.nhanKetQuaViTri.text = "⚠️ \(loi.localizedDescription)"
            }
        }
    }

    private func capNhatKhoangCachChoToaDo(_ coord: CLLocationCoordinate2D) {
        var khoangCachMin: Double = -1
        if let diem = diemMucTieuHienTai() {
            khoangCachMin = BoPhanTichLinkGoogleMaps.khoangCachMet(lat1: coord.latitude, lon1: coord.longitude, lat2: diem.viDo, lon2: diem.kinhDo)
        } else if let t = tuyen {
            let cacDiemTuyen: [(Double, Double)] = !t.cacDiemMucTieu.isEmpty
                ? t.cacDiemMucTieu.map { ($0.viDo, $0.kinhDo) }
                : t.cacToaDo.dropFirst().compactMap { $0.count >= 2 ? ($0[0], $0[1]) : nil }
            for (lat, lon) in cacDiemTuyen {
                let d = BoPhanTichLinkGoogleMaps.khoangCachMet(lat1: coord.latitude, lon1: coord.longitude, lat2: lat, lon2: lon)
                if khoangCachMin < 0 || d < khoangCachMin {
                    khoangCachMin = d
                }
            }
        }
        khoangCachHienTaiMet = khoangCachMin
        let toaDoStr = String(format: "%.5f, %.5f", coord.latitude, coord.longitude)
        if khoangCachMin < 0 {
            nhanKetQuaViTri.textColor = BangMauBCTD.xanhChuDaoDam
            nhanKetQuaViTri.text = "📍 Đã nhận tọa độ: \(toaDoStr)"
        } else {
            let kcText = khoangCachMin >= 1000
                ? String(format: "%.2f km", khoangCachMin / 1000.0)
                : "\(Int(khoangCachMin.rounded()))m"
            let tenDiem = diemMucTieuHienTai()?.ten ?? oMaTran.tenTuyen
            if khoangCachMin <= nguongMet {
                nhanKetQuaViTri.textColor = BangMauBCTD.xanhLaDam
                nhanKetQuaViTri.text = "🟢 Đúng địa điểm! Cách \"\(tenDiem)\" \(kcText) (tọa độ: \(toaDoStr))"
            } else if khoangCachMin <= nguongMet * 2.0 {
                nhanKetQuaViTri.textColor = BangMauBCTD.camPhanTich
                nhanKetQuaViTri.text = "🟡 Hơi lệch vùng mục tiêu: cách \"\(tenDiem)\" \(kcText) (ngưỡng \(Int(nguongMet))m • \(toaDoStr))"
            } else {
                nhanKetQuaViTri.textColor = .systemRed
                nhanKetQuaViTri.text = "🔴 Lệch xa mục tiêu: cách \"\(tenDiem)\" \(kcText) (tọa độ: \(toaDoStr))"
            }
        }
    }

    @objc private func bamLayGPSMayNay() {
        let st = quanLyViTri.authorizationStatus
        if st == .notDetermined {
            quanLyViTri.requestWhenInUseAuthorization()
        } else if st == .denied || st == .restricted {
            hienThongBao(tieuDe: "Chưa cấp quyền vị trí", noiDung: "Vào Cài đặt iPhone → V2 ĐMX → Vị trí để bật định vị, hoặc dán link Google Maps trực tiếp.")
            return
        }
        vongQuayViTri.startAnimating()
        nhanKetQuaViTri.textColor = BangMauBCTD.xanhChuDao
        nhanKetQuaViTri.text = "⏳ Đang lấy tọa độ GPS hiện tại…"
        quanLyViTri.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        vongQuayViTri.stopAnimating()
        guard let loc = locations.last else { return }
        let coord = loc.coordinate
        let link = String(format: "https://www.google.com/maps?q=%.6f,%.6f", coord.latitude, coord.longitude)
        oLinkGoogleMaps.text = link
        toaDoDaPhanTich = coord
        linkChuanDaPhanTich = link
        capNhatKhoangCachChoToaDo(coord)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        vongQuayViTri.stopAnimating()
        nhanKetQuaViTri.textColor = .systemRed
        nhanKetQuaViTri.text = "⚠️ Không lấy được GPS: \(error.localizedDescription)"
    }

    @objc private func bamChupAnh() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            hienThongBao(tieuDe: "Không có Camera", noiDung: "Thiết bị này không hỗ trợ chụp trực tiếp. Hãy chọn ảnh từ thư viện.")
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func bamChonAnhThuVien() {
        var cfg = PHPickerConfiguration(photoLibrary: .shared())
        cfg.filter = .images
        cfg.selectionLimit = 1
        let picker = PHPickerViewController(configuration: cfg)
        picker.delegate = self
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let img = info[.originalImage] as? UIImage {
            datAnhMinhChung(img)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let first = results.first, first.itemProvider.canLoadObject(ofClass: UIImage.self) else { return }
        first.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
            if let img = obj as? UIImage {
                DispatchQueue.main.async { self?.datAnhMinhChung(img) }
            }
        }
    }

    private func datAnhMinhChung(_ img: UIImage) {
        anhDaChon = img
        anhMinhChungView.image = img
        nhanChuaCoAnh.isHidden = true
    }

    @objc private func bamLuuBangChung() {
        view.endEditing(true)
        let tenNS = (oTenNhanSu.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tenNS.isEmpty else {
            hienThongBao(tieuDe: "Thiếu tên nhân sự", noiDung: "Hãy chọn hoặc nhập tên nhân sự thực hiện phát tờ rơi.")
            return
        }
        guard let anh = anhDaChon else {
            hienThongBao(tieuDe: "Thiếu ảnh minh chứng", noiDung: "Hãy chụp hoặc chọn 1 tấm ảnh đã phát tờ rơi tại địa điểm.")
            return
        }

        let linkRaw = (oLinkGoogleMaps.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !linkRaw.isEmpty else {
            hienThongBao(tieuDe: "Thiếu vị trí Google Maps", noiDung: "Hãy dán link vị trí Google Maps nhân viên đang đi (hoặc bấm Lấy GPS máy này).")
            return
        }

        if let coord = toaDoDaPhanTich {
            thucThiLuuBangChung(tenNS: tenNS, anh: anh, coord: coord, link: linkChuanDaPhanTich.isEmpty ? linkRaw : linkChuanDaPhanTich)
        } else {
            nutLuuBangChung.isEnabled = false
            vongQuayViTri.startAnimating()
            BoPhanTichLinkGoogleMaps.dungChung.giaiMaViTri(tu: linkRaw) { [weak self] kq in
                guard let self else { return }
                self.nutLuuBangChung.isEnabled = true
                self.vongQuayViTri.stopAnimating()
                switch kq {
                case .success(let res):
                    self.toaDoDaPhanTich = res.toaDo
                    self.linkChuanDaPhanTich = res.linkChuan
                    self.capNhatKhoangCachChoToaDo(res.toaDo)
                    self.thucThiLuuBangChung(tenNS: tenNS, anh: anh, coord: res.toaDo, link: res.linkChuan)
                case .failure(let loi):
                    self.hienThongBao(tieuDe: "Vị trí Google Maps chưa hợp lệ", noiDung: loi.localizedDescription)
                }
            }
        }
    }

    private func thucThiLuuBangChung(tenNS: String, anh: UIImage, coord: CLLocationCoordinate2D, link: String) {
        nutLuuBangChung.isEnabled = false
        let id = UUID().uuidString
        let tenDiem = diemMucTieuHienTai()?.ten ?? "Điểm trên \(oMaTran.tenTuyen)"
        let ghiChu = (oGhiChu.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let banGhi = BangChungPhatToRoi(
            id: id,
            oMaTranId: oMaTran.id,
            tuyenId: oMaTran.tuyenId,
            tenTuyen: oMaTran.tenTuyen,
            diemId: diemDangChonId,
            tenDiaDiem: tenDiem,
            tenNhanSu: tenNS,
            linkGoogleMapsGoc: link,
            viDoCheckIn: coord.latitude,
            kinhDoCheckIn: coord.longitude,
            khoangCachDenDiemMet: khoangCachHienTaiMet,
            nguongHopLeMet: nguongMet,
            tenTepAnh: "\(id).jpg",
            thoiGianGhiNhan: ISO8601DateFormatter().string(from: Date()),
            ghiChu: ghiChu
        )

        KhoBangChungPhatToRoi.dungChung.themBangChung(banGhi, anh: anh) { [weak self] kq in
            guard let self else { return }
            self.nutLuuBangChung.isEnabled = true
            switch kq {
            case .success(let daLuu):
                self.oLinkGoogleMaps.text = ""
                self.oGhiChu.text = ""
                self.toaDoDaPhanTich = nil
                self.linkChuanDaPhanTich = ""
                self.khoangCachHienTaiMet = -1
                self.anhDaChon = nil
                self.anhMinhChungView.image = nil
                self.nhanChuaCoAnh.isHidden = false
                self.nhanKetQuaViTri.textColor = BangMauBCTD.xanhLaDam
                self.nhanKetQuaViTri.text = "✅ Đã lưu bằng chứng cho \"\(daLuu.tenDiaDiem)\" (\(daLuu.trangThaiViTri.nhan))."
                self.napDanhSachBangChung()
                self.khiCapNhat(true)
            case .failure(let loi):
                self.hienThongBao(tieuDe: "Không lưu được bằng chứng", noiDung: loi.localizedDescription)
            }
        }
    }

    private func veDanhSachBangChung() {
        nganDanhSachBangChung.arrangedSubviews.forEach { nganDanhSachBangChung.removeArrangedSubview($0); $0.removeFromSuperview() }
        if danhSachBangChung.isEmpty {
            nganDanhSachBangChung.addArrangedSubview(taoNhan("Chưa có nhân viên nào nộp bằng chứng phát tờ rơi cho buổi này."))
            return
        }

        for bc in danhSachBangChung {
            let khung = UIStackView()
            khung.axis = .vertical
            khung.spacing = 7
            khung.isLayoutMarginsRelativeArrangement = true
            khung.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            khung.backgroundColor = BangMauBCTD.nenThePhu
            khung.layer.cornerRadius = 10
            khung.layer.borderWidth = 1
            khung.layer.borderColor = bc.trangThaiViTri.mau.withAlphaComponent(0.45).cgColor

            let hangInfo = UIStackView()
            hangInfo.axis = .horizontal
            hangInfo.alignment = .top
            hangInfo.spacing = 10

            let thumb = UIImageView()
            thumb.contentMode = .scaleAspectFill
            thumb.clipsToBounds = true
            thumb.layer.cornerRadius = 8
            thumb.backgroundColor = BangMauBCTD.vienThe
            thumb.isUserInteractionEnabled = true
            thumb.widthAnchor.constraint(equalToConstant: 78).isActive = true
            thumb.heightAnchor.constraint(equalToConstant: 78).isActive = true
            let anh = KhoBangChungPhatToRoi.dungChung.taiAnh(tenTep: bc.tenTepAnh)
            thumb.image = anh

            let nutXemAnh = UIButton(type: .custom)
            nutXemAnh.translatesAutoresizingMaskIntoConstraints = false
            nutXemAnh.addAction(UIAction { [weak self] _ in
                guard let self, let anh else { return }
                self.moXemAnhToanManHinh(anh: anh, tieuDe: "\(bc.tenDiaDiem) • \(bc.tenNhanSu)")
            }, for: .touchUpInside)
            thumb.addSubview(nutXemAnh)
            NSLayoutConstraint.activate([
                nutXemAnh.topAnchor.constraint(equalTo: thumb.topAnchor),
                nutXemAnh.leadingAnchor.constraint(equalTo: thumb.leadingAnchor),
                nutXemAnh.trailingAnchor.constraint(equalTo: thumb.trailingAnchor),
                nutXemAnh.bottomAnchor.constraint(equalTo: thumb.bottomAnchor)
            ])

            let cotChu = UIStackView()
            cotChu.axis = .vertical
            cotChu.spacing = 3
            cotChu.addArrangedSubview(taoNhan("📍 \(bc.tenDiaDiem)", dam: true))
            cotChu.addArrangedSubview(taoNhan("👤 \(bc.tenNhanSu) • 🕒 \(bc.thoiGianHienThi)"))
            let lbTT = taoNhan(bc.trangThaiViTri.nhan, dam: true)
            lbTT.textColor = bc.trangThaiViTri.mau
            cotChu.addArrangedSubview(lbTT)
            if !bc.ghiChu.isEmpty {
                cotChu.addArrangedSubview(taoNhan("💬 \(bc.ghiChu)"))
            }

            hangInfo.addArrangedSubview(thumb)
            hangInfo.addArrangedSubview(cotChu)
            khung.addArrangedSubview(hangInfo)

            let nutMoMap = UIButton(type: .system)
            nutMoMap.setTitle("🗺️ Mở vị trí đã dán", for: .normal)
            cauHinhNut(nutMoMap, mauNen: BangMauBCTD.nenHeaderPhu, mauChu: BangMauBCTD.xanhChuDaoDam, coVien: true)
            nutMoMap.addAction(UIAction { _ in
                if let url = URL(string: "https://www.google.com/maps?q=\(bc.viDoCheckIn),\(bc.kinhDoCheckIn)") {
                    UIApplication.shared.open(url)
                }
            }, for: .touchUpInside)

            let nutXoa = UIButton(type: .system)
            nutXoa.setTitle("🗑 Xóa", for: .normal)
            cauHinhNut(nutXoa, mauNen: UIColor.systemRed.withAlphaComponent(0.10), mauChu: .systemRed)
            nutXoa.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                KhoBangChungPhatToRoi.dungChung.xoaBangChung(id: bc.id)
                self.napDanhSachBangChung()
                self.khiCapNhat(false)
            }, for: .touchUpInside)

            let hangNut = UIStackView(arrangedSubviews: [nutMoMap, nutXoa])
            hangNut.axis = .horizontal
            hangNut.spacing = 8
            hangNut.distribution = .fillEqually
            khung.addArrangedSubview(hangNut)

            nganDanhSachBangChung.addArrangedSubview(khung)
        }
    }

    private func moXemAnhToanManHinh(anh: UIImage, tieuDe: String) {
        let vc = UIViewController()
        vc.title = tieuDe
        vc.view.backgroundColor = .black
        let iv = UIImageView(image: anh)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(iv)
        NSLayoutConstraint.activate([
            iv.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor),
            iv.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            iv.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            iv.bottomAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.bottomAnchor)
        ])
        let actionDong = UIAction(title: "Đóng") { [weak vc] _ in
            vc?.dismiss(animated: true)
        }
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(primaryAction: actionDong)
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func taoThe(tieuDe: String) -> (UIView, UIStackView) {
        let the = UIView()
        the.backgroundColor = BangMauBCTD.nenThe
        the.layer.cornerRadius = 12
        the.layer.borderWidth = 1
        the.layer.borderColor = BangMauBCTD.vienThe.cgColor
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        the.addSubview(stack)
        stack.addArrangedSubview(taoNhan(tieuDe, dam: true))
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: the.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: the.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: the.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: the.bottomAnchor, constant: -12)
        ])
        return (the, stack)
    }

    private func taoNhan(_ text: String, dam: Bool = false) -> UILabel {
        let l = UILabel()
        l.text = text
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.adjustsFontSizeToFitWidth = false
        l.textColor = BangMauBCTD.chuChinh
        l.font = .systemFont(ofSize: dam ? 13.5 : 12.5, weight: dam ? .bold : .regular)
        return l
    }

    private func cauHinhTextField(_ tf: UITextField, goiY: String) {
        tf.placeholder = goiY
        tf.font = .systemFont(ofSize: 13.5)
        tf.textColor = BangMauBCTD.chuChinh
        tf.backgroundColor = BangMauBCTD.nenThePhu
        tf.layer.cornerRadius = 9
        tf.layer.borderWidth = 1
        tf.layer.borderColor = BangMauBCTD.vienDam.cgColor
        tf.clearButtonMode = .whileEditing
        tf.heightAnchor.constraint(equalToConstant: 40).isActive = true
        let dem = UIView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(10), height: CGFloat(1)))
        tf.leftView = dem
        tf.leftViewMode = .always
    }

    private func cauHinhNut(_ b: UIButton, mauNen: UIColor, mauChu: UIColor, coVien: Bool = false) {
        b.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        b.titleLabel?.numberOfLines = 0
        b.titleLabel?.lineBreakMode = .byWordWrapping
        b.titleLabel?.adjustsFontSizeToFitWidth = false
        b.backgroundColor = mauNen
        b.setTitleColor(mauChu, for: .normal)
        b.layer.cornerRadius = 9
        if coVien {
            b.layer.borderWidth = 1
            b.layer.borderColor = BangMauBCTD.vienDam.cgColor
        }
        b.contentEdgeInsets = UIEdgeInsets(top: 9, left: 10, bottom: 9, right: 10)
    }

    private func hienThongBao(tieuDe: String, noiDung: String) {
        let tb = UIAlertController(title: tieuDe, message: noiDung, preferredStyle: .alert)
        tb.addAction(UIAlertAction(title: "Đóng", style: .default))
        present(tb, animated: true)
    }
}

// MARK: - 6. Màn Hình Tổng Hợp Kiểm Soát Phát Tờ Rơi Cả Tuần

final class HopTongHopKiemSoatTuanViewController: UITableViewController {
    private let keHoach: KeHoachMaTranTuan
    private let khiChonO: (OMaTranPhatToRoi) -> Void
    private var dsBangChung: [BangChungPhatToRoi] = []

    init(keHoach: KeHoachMaTranTuan, khiChonO: @escaping (OMaTranPhatToRoi) -> Void) {
        self.keHoach = keHoach
        self.khiChonO = khiChonO
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError("Khong ho tro coder") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "🛡️ Kiểm soát phát tuần"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "📋 Copy", style: .plain, target: self, action: #selector(bamCopyBaoCao))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Đóng", style: .done, target: self, action: #selector(bamDong))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 74
        dsBangChung = KhoBangChungPhatToRoi.dungChung.layTatCa()
    }

    @objc private func bamDong() { dismiss(animated: true) }

    @objc private func bamCopyBaoCao() {
        var lines: [String] = ["🛡️ BÁO CÁO KIỂM SOÁT PHÁT TỜ RƠI (\(keHoach.nhanTuan))"]
        var daXacMinh = 0
        var coCanhBao = 0
        for o in keHoach.cacO {
            let thu = (o.thuIndex >= 0 && o.thuIndex < BoPhanTichLichCaExcel.tenThu.count) ? BoPhanTichLichCaExcel.tenThu[o.thuIndex] : ""
            let bcO = dsBangChung.filter { $0.oMaTranId == o.id }
            let hopLe = bcO.filter { $0.trangThaiViTri.hopLe }.count
            if !bcO.isEmpty { daXacMinh += 1 }
            if bcO.contains(where: { !$0.trangThaiViTri.hopLe }) { coCanhBao += 1 }
            let tt = bcO.isEmpty
                ? "❌ Chưa có ảnh + vị trí"
                : "✅ \(bcO.count) bằng chứng (\(hopLe) đúng vị trí)"
            lines.append("• \(thu) \(o.buoi) — \(o.tenTuyen): \(tt)")
            for bc in bcO {
                lines.append("   ↳ \(bc.tenDiaDiem) | \(bc.tenNhanSu) | \(bc.trangThaiViTri.nhan) | \(bc.thoiGianHienThi)")
            }
        }
        lines.insert("📊 Tổng kết: \(daXacMinh)/\(keHoach.cacO.count) buổi có bằng chứng • \(coCanhBao) buổi có cảnh báo lệch vị trí", at: 1)
        UIPasteboard.general.string = lines.joined(separator: "\n")
        let tb = UIAlertController(title: "Đã sao chép", message: "Đã sao chép báo cáo kiểm soát vị trí & ảnh phát tờ rơi cả tuần.", preferredStyle: .alert)
        tb.addAction(UIAlertAction(title: "Đóng", style: .default))
        present(tb, animated: true)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let buoiCoBC = keHoach.cacO.filter { o in dsBangChung.contains(where: { $0.oMaTranId == o.id }) }.count
        return "\(keHoach.nhanTuan) • \(buoiCoBC)/\(keHoach.cacO.count) buổi có bằng chứng (chạm để kiểm tra)"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return keHoach.cacO.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "CellKiemSoatTuan"
        let cell = tableView.dequeueReusableCell(withIdentifier: id)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: id)
        let o = keHoach.cacO[indexPath.row]
        let thu = (o.thuIndex >= 0 && o.thuIndex < BoPhanTichLichCaExcel.tenThu.count) ? BoPhanTichLichCaExcel.tenThu[o.thuIndex] : ""
        let bcO = dsBangChung.filter { $0.oMaTranId == o.id }
        let tuyen = keHoach.cacTuyen.first(where: { $0.id == o.tuyenId })
        let soDiemMucTieu = tuyen?.cacDiemMucTieu.count ?? 0
        let soDiemDaCheck = Set(bcO.map { $0.diemId }).count
        let soHopLe = bcO.filter { $0.trangThaiViTri.hopLe }.count
        let coLech = bcO.contains(where: { !$0.trangThaiViTri.hopLe })

        cell.textLabel?.text = "\(thu) • \(o.buoi) — \(o.tenTuyen)"
        cell.textLabel?.font = .systemFont(ofSize: 13.5, weight: .bold)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.adjustsFontSizeToFitWidth = false

        let ns = (o.danhSachPG + o.danhSachNV).joined(separator: ", ")
        let trangThai: String
        if bcO.isEmpty {
            trangThai = "⏳ Chưa nộp vị trí Google Maps & ảnh minh chứng"
            cell.detailTextLabel?.textColor = BangMauBCTD.chuPhu
        } else if coLech {
            trangThai = "⚠️ \(bcO.count) ảnh/GPS (\(soHopLe) đúng vị trí, có điểm lệch xa) • \(soDiemMucTieu > 0 ? "\(soDiemDaCheck)/\(soDiemMucTieu) điểm" : "")"
            cell.detailTextLabel?.textColor = .systemRed
        } else {
            trangThai = "✅ Đã xác minh \(bcO.count) bằng chứng (🟢 Đúng vị trí) • \(soDiemMucTieu > 0 ? "\(soDiemDaCheck)/\(soDiemMucTieu) điểm" : "")"
            cell.detailTextLabel?.textColor = BangMauBCTD.xanhLaDam
        }
        cell.detailTextLabel?.text = "\(trangThai)\(ns.isEmpty ? "" : "\n👥 \(ns)")"
        cell.detailTextLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.lineBreakMode = .byWordWrapping
        cell.detailTextLabel?.adjustsFontSizeToFitWidth = false
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let o = keHoach.cacO[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.khiChonO(o)
        }
    }
}
