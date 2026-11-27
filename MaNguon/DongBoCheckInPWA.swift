import UIKit
import MapKit
import CoreLocation

// MARK: - 1. Mô Hình Bản Ghi Check-in Đồng Bộ Từ PWA / Google Sheet ("BC-Phát tờ rơi")

struct BanGhiCheckInPWA: Codable, Equatable {
    let stt: String
    let thoiGian: String
    let ngay: String
    let nhom: String
    let hoTen: String
    let boPhan: String
    let tuyen: String
    let diaDiem: String
    let toaDo: String
    let lat: Double?
    let lng: Double?
    let linkMaps: String
    let linkDrive: String
    let linkAnh: String
    let fileId: String
    let ghiChu: String

    var idDuyNhat: String {
        return "\(stt)_\(thoiGian)_\(hoTen)"
    }

    var tenSachKhongNgoac: String {
        return hoTen.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? hoTen
    }

    var tenChuanHoa: String {
        return BoPhanTichLichCaExcel.chuanHoa(tenSachKhongNgoac)
    }

    var soThuTuTuyen: Int? {
        let low = BoPhanTichLichCaExcel.chuanHoa(tuyen)
        guard let regex = try? NSRegularExpression(pattern: #"tuyen\s*(\d+)"#),
              let m = regex.firstMatch(in: low, range: NSRange(low.startIndex..., in: low)),
              let r = Range(m.range(at: 1), in: low) else { return nil }
        return Int(low[r])
    }

    var toaDoHopLe: CLLocationCoordinate2D? {
        if let la = lat, let lo = lng, BoPhanTichLinkGoogleMaps.toaDoHopLe(lat: la, lon: lo) {
            return CLLocationCoordinate2D(latitude: la, longitude: lo)
        }
        if let c = BoPhanTichLinkGoogleMaps.trichToaDoTrucTiep(tu: toaDo) {
            return c
        }
        if let c = BoPhanTichLinkGoogleMaps.trichToaDoTrucTiep(tu: linkMaps) {
            return c
        }
        return nil
    }

    var driveFileIdTrichXuat: String {
        if !fileId.isEmpty { return fileId }
        for src in [linkAnh, linkDrive] {
            if let rx1 = try? NSRegularExpression(pattern: #"/d/([a-zA-Z0-9_-]{15,})"#),
               let m = rx1.firstMatch(in: src, range: NSRange(src.startIndex..., in: src)),
               let r = Range(m.range(at: 1), in: src) {
                return String(src[r])
            }
            if let rx2 = try? NSRegularExpression(pattern: #"[?&]id=([a-zA-Z0-9_-]{15,})"#),
               let m = rx2.firstMatch(in: src, range: NSRange(src.startIndex..., in: src)),
               let r = Range(m.range(at: 1), in: src) {
                return String(src[r])
            }
        }
        return ""
    }

    var cacURLAnhDuPhong: [URL] {
        var urls: [URL] = []
        let fid = driveFileIdTrichXuat
        if !fid.isEmpty {
            if let u1 = URL(string: "https://drive.google.com/thumbnail?id=\(fid)&sz=w1000") { urls.append(u1) }
            if let u2 = URL(string: "https://lh3.googleusercontent.com/d/\(fid)=w1000") { urls.append(u2) }
            if let u3 = URL(string: "https://drive.google.com/uc?export=view&id=\(fid)") { urls.append(u3) }
        }
        if let uRaw = URL(string: linkAnh), !urls.contains(uRaw) {
            urls.append(uRaw)
        }
        return urls
    }

    init(
        stt: String,
        thoiGian: String,
        ngay: String,
        nhom: String,
        hoTen: String,
        boPhan: String,
        tuyen: String,
        diaDiem: String,
        toaDo: String,
        lat: Double?,
        lng: Double?,
        linkMaps: String,
        linkDrive: String,
        linkAnh: String,
        fileId: String,
        ghiChu: String
    ) {
        self.stt = stt
        self.thoiGian = thoiGian
        self.ngay = ngay
        self.nhom = nhom
        self.hoTen = hoTen
        self.boPhan = boPhan
        self.tuyen = tuyen
        self.diaDiem = diaDiem
        self.toaDo = toaDo
        self.lat = lat
        self.lng = lng
        self.linkMaps = linkMaps
        self.linkDrive = linkDrive
        self.linkAnh = linkAnh
        self.fileId = fileId
        self.ghiChu = ghiChu
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let s = try? c.decode(String.self, forKey: .stt) {
            stt = s
        } else if let n = try? c.decode(Int.self, forKey: .stt) {
            stt = "\(n)"
        } else {
            stt = ""
        }
        thoiGian = (try? c.decode(String.self, forKey: .thoiGian)) ?? ""
        ngay = (try? c.decode(String.self, forKey: .ngay)) ?? ""
        nhom = (try? c.decode(String.self, forKey: .nhom)) ?? ""
        hoTen = (try? c.decode(String.self, forKey: .hoTen)) ?? ""
        boPhan = (try? c.decode(String.self, forKey: .boPhan)) ?? ""
        tuyen = (try? c.decode(String.self, forKey: .tuyen)) ?? ""
        diaDiem = (try? c.decode(String.self, forKey: .diaDiem)) ?? ""
        toaDo = (try? c.decode(String.self, forKey: .toaDo)) ?? ""
        lat = try? c.decode(Double.self, forKey: .lat)
        lng = try? c.decode(Double.self, forKey: .lng)
        linkMaps = (try? c.decode(String.self, forKey: .linkMaps)) ?? ""
        linkDrive = (try? c.decode(String.self, forKey: .linkDrive)) ?? ""
        linkAnh = (try? c.decode(String.self, forKey: .linkAnh)) ?? ""
        fileId = (try? c.decode(String.self, forKey: .fileId)) ?? ""
        ghiChu = (try? c.decode(String.self, forKey: .ghiChu)) ?? ""
    }
}

// MARK: - 2. Kho Lưu Đệm & Dịch Vụ Đồng Bộ 2 Chiều DMX-V2 <-> Google Sheet PWA

final class KhoCheckInPWADongBo {
    static let dungChung = KhoCheckInPWADongBo()
    private init() {}

    private let khoaDanhSach = "dmx_checkin_pwa_dongbo_v1"
    private let khoaThoiGianCuoi = "dmx_checkin_pwa_thoigian_v1"

    func taiDanhSachLuu() -> [BanGhiCheckInPWA] {
        guard let data = UserDefaults.standard.data(forKey: khoaDanhSach),
              let ds = try? JSONDecoder().decode([BanGhiCheckInPWA].self, from: data) else {
            return []
        }
        return ds
    }

    func luuDanhSach(_ ds: [BanGhiCheckInPWA]) {
        if let data = try? JSONEncoder().encode(ds) {
            UserDefaults.standard.set(data, forKey: khoaDanhSach)
        }
        let df = DateFormatter()
        df.locale = Locale(identifier: "vi_VN")
        df.dateFormat = "HH:mm dd/MM"
        UserDefaults.standard.set(df.string(from: Date()), forKey: khoaThoiGianCuoi)
    }

    var lanDongBoCuoi: String {
        return UserDefaults.standard.string(forKey: khoaThoiGianCuoi) ?? ""
    }

    static func tenChuanHoaKhongCa(_ chuoiNguoi: String) -> String {
        let sach = chuoiNguoi.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? chuoiNguoi
        return BoPhanTichLichCaExcel.chuanHoa(sach)
    }

    /// Khớp các lượt check-in từ PWA cho 1 nhân sự cụ thể (và tùy chọn số thứ tự tuyến)
    static func locCheckIn(choTenNguoi ten: String, soThuTuTuyen: Int?, trong ds: [BanGhiCheckInPWA]) -> [BanGhiCheckInPWA] {
        let key = tenChuanHoaKhongCa(ten)
        guard !key.isEmpty else { return [] }
        let theoTen = ds.filter { bc in
            let k = bc.tenChuanHoa
            return !k.isEmpty && (k == key || k.contains(key) || key.contains(k))
        }
        guard let sttTuyen = soThuTuTuyen else { return theoTen }
        let khopTuyen = theoTen.filter { $0.soThuTuTuyen == sttTuyen || $0.soThuTuTuyen == nil }
        return khopTuyen.isEmpty ? theoTen : khopTuyen
    }

    /// Khớp các lượt check-in từ PWA cho 1 buổi trong Ma trận phát tờ rơi
    static func locCheckIn(choO o: OMaTranPhatToRoi, cacTuyen: [TuyenPhatToRoiMaTran], trong ds: [BanGhiCheckInPWA]) -> [BanGhiCheckInPWA] {
        let sttTuyen = cacTuyen.first(where: { $0.id == o.tuyenId })?.soThuTu
        let tatCaTen = (o.danhSachPG + o.danhSachNV).map { tenChuanHoaKhongCa($0) }.filter { !$0.isEmpty }
        guard !tatCaTen.isEmpty else {
            if let stt = sttTuyen {
                return ds.filter { $0.soThuTuTuyen == stt }
            }
            return []
        }
        return ds.filter { bc in
            let k = bc.tenChuanHoa
            guard !k.isEmpty else { return false }
            let tenKhop = tatCaTen.contains(where: { $0 == k || $0.contains(k) || k.contains($0) })
            if !tenKhop { return false }
            if let stt = sttTuyen, let bcStt = bc.soThuTuTuyen {
                return bcStt == stt
            }
            return true
        }
    }
}

final class BoDongBoCheckInPWA {
    static let dungChung = BoDongBoCheckInPWA()
    private init() {}

    static let urlWebAppMacDinh = "https://script.google.com/macros/s/AKfycbyIVu3UNuqG72zJvF0Pt8RaobieaWNnyXQCGifFXPK5c5A0kjzHB9OL49LKkAAzjG4J_w/exec"

    private let phienMang: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 30
        return URLSession(configuration: cfg)
    }()

    private struct PhanHoiDanhSachPWA: Decodable {
        let ok: Bool?
        let error: String?
        let lichSu: [BanGhiCheckInPWA]?
    }

    /// Tải toàn bộ lượt check-in nhân viên đã nộp từ PWA trên tab "BC-Phát tờ rơi"
    func taiDanhSachCheckIn(limit: Int = 200, hoanTat: @escaping (Result<[BanGhiCheckInPWA], Error>) -> Void) {
        let ts = Int(Date().timeIntervalSince1970)
        guard let url = URL(string: "\(Self.urlWebAppMacDinh)?action=list&limit=\(limit)&t=\(ts)") else {
            DispatchQueue.main.async { hoanTat(.failure(NSError.dmx("URL Apps Script không hợp lệ."))) }
            return
        }
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        req.setValue("DMX-V2-iOS/1.0", forHTTPHeaderField: "User-Agent")

        phienMang.dataTask(with: req) { data, resp, err in
            if let err {
                DispatchQueue.main.async { hoanTat(.failure(err)) }
                return
            }
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            guard code == 200, let data else {
                DispatchQueue.main.async { hoanTat(.failure(NSError.dmx("Không kết nối được Apps Script (HTTP \(code))."))) }
                return
            }
            do {
                let parsed = try JSONDecoder().decode(PhanHoiDanhSachPWA.self, from: data)
                if parsed.ok == false {
                    throw NSError.dmx(parsed.error ?? "Apps Script trả về lỗi.")
                }
                let ds = parsed.lichSu ?? []
                KhoCheckInPWADongBo.dungChung.luuDanhSach(ds)
                DispatchQueue.main.async { hoanTat(.success(ds)) }
            } catch {
                DispatchQueue.main.async { hoanTat(.failure(error)) }
            }
        }.resume()
    }

    /// Đẩy ma trận phân tuyến & lịch phát tờ rơi tuần hiện tại lên Google Sheet (tab LichPhatToRoi) để PWA hiện tuyến riêng cho từng PG/NV
    func dongBoLichPhanTuyenLenSheet(
        keHoach: KeHoachMaTranTuan,
        tamToaDo: CLLocationCoordinate2D,
        hoanTat: ((Result<String, Error>) -> Void)? = nil
    ) {
        guard let url = URL(string: Self.urlWebAppMacDinh) else {
            DispatchQueue.main.async { hoanTat?(.failure(NSError.dmx("URL Apps Script không hợp lệ."))) }
            return
        }

        let origin = "\(tamToaDo.latitude),\(tamToaDo.longitude)"
        let cacTuyenJSON: [[String: Any]] = keHoach.cacTuyen.map { t in
            var mapsUrl = ""
            if let cuoi = t.cacDiemMucTieu.last {
                let dest = "\(cuoi.viDo),\(cuoi.kinhDo)"
                let wp = Array(t.cacDiemMucTieu.dropLast().prefix(9)).map { "\($0.viDo),\($0.kinhDo)" }.joined(separator: "|")
                var u = "https://www.google.com/maps/dir/?api=1&origin=\(origin)&destination=\(dest)&travelmode=driving"
                if !wp.isEmpty, let enc = wp.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    u += "&waypoints=\(enc)"
                }
                mapsUrl = u
            }
            let diemArr: [[String: Any]] = t.cacDiemMucTieu.prefix(12).map { d in
                ["ten": d.ten, "loai": d.loaiRaw, "lat": d.viDo, "lng": d.kinhDo]
            }
            let stepsArr: [String] = t.chiDanTungBuoc.prefix(8).map { "\($0.hanhDong): \($0.noiDung)" }
            return [
                "id": t.id,
                "soThuTu": t.soThuTu,
                "ten": t.ten,
                "moTaDiemNong": t.moTaDiemNong,
                "tongQuangDuongMet": Int(round(t.tongQuangDuongMet)),
                "thoiGianXeMayPhut": t.thoiGianXeMayPhut,
                "thoiGianDiBoPhut": t.thoiGianDiBoPhut,
                "cacDiemMucTieu": diemArr,
                "chiDanTomTat": stepsArr,
                "googleMapsUrl": mapsUrl
            ]
        }

        let cacPhanCongJSON: [[String: Any]] = keHoach.cacO.map { o in
            let thuTen = (o.thuIndex >= 0 && o.thuIndex < BoPhanTichLichCaExcel.tenThu.count) ? BoPhanTichLichCaExcel.tenThu[o.thuIndex] : "Thứ"
            return [
                "id": o.id,
                "thuIndex": o.thuIndex,
                "thuTen": thuTen,
                "buoi": o.buoi,
                "tuyenId": o.tuyenId,
                "tenTuyen": o.tenTuyen,
                "moTaTuyen": o.moTaTuyen,
                "danhSachPG": o.danhSachPG,
                "danhSachNV": o.danhSachNV,
                "daPhat": o.daPhat
            ]
        }

        let payload: [String: Any] = [
            "action": "syncSchedule",
            "tuan": keHoach.nhanTuan,
            "cacTuyen": cacTuyenJSON,
            "cacPhanCong": cacPhanCongJSON
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else {
            DispatchQueue.main.async { hoanTat?(.failure(NSError.dmx("Không đóng gói được dữ liệu lịch phân tuyến."))) }
            return
        }

        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 25)
        req.httpMethod = "POST"
        req.setValue("text/plain;charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.httpBody = bodyData

        phienMang.dataTask(with: req) { data, resp, err in
            if let err {
                DispatchQueue.main.async { hoanTat?(.failure(err)) }
                return
            }
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            guard code == 200, let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  (json["ok"] as? Bool) == true else {
                DispatchQueue.main.async { hoanTat?(.failure(NSError.dmx("Chưa đồng bộ được lịch phân tuyến lên Google Sheet (HTTP \(code))."))) }
                return
            }
            let tg = (json["capNhatLuc"] as? String) ?? ""
            DispatchQueue.main.async {
                hoanTat?(.success("Đã đồng bộ \(keHoach.cacTuyen.count) tuyến & \(keHoach.cacO.count) buổi lên PWA (\(tg))."))
            }
        }.resume()
    }
}

// MARK: - 3. Bộ Tải Ảnh Minh Chứng Google Drive Có Cache Bộ Nhớ

final class BoTaiAnhCheckInPWA {
    static let dungChung = BoTaiAnhCheckInPWA()
    private init() {}

    private let cache = NSCache<NSString, UIImage>()

    func taiAnh(cho banGhi: BanGhiCheckInPWA, hoanTat: @escaping (UIImage?) -> Void) {
        let key = banGhi.idDuyNhat as NSString
        if let san = cache.object(forKey: key) {
            DispatchQueue.main.async { hoanTat(san) }
            return
        }
        let urls = banGhi.cacURLAnhDuPhong
        guard !urls.isEmpty else {
            DispatchQueue.main.async { hoanTat(nil) }
            return
        }
        thuTaiLanLuot(urls: urls, index: 0, cacheKey: key, hoanTat: hoanTat)
    }

    private func thuTaiLanLuot(urls: [URL], index: Int, cacheKey: NSString, hoanTat: @escaping (UIImage?) -> Void) {
        guard index < urls.count else {
            DispatchQueue.main.async { hoanTat(nil) }
            return
        }
        var req = URLRequest(url: urls[index], cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 18)
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            if let data, let img = UIImage(data: data) {
                self?.cache.setObject(img, forKey: cacheKey)
                DispatchQueue.main.async { hoanTat(img) }
                return
            }
            self?.thuTaiLanLuot(urls: urls, index: index + 1, cacheKey: cacheKey, hoanTat: hoanTat)
        }.resume()
    }
}

// MARK: - 4. Ghim Bản Đồ Hiển Thị Luôn Tên Nhân Viên / PG Đã Check-in

final class GhimCheckInPWAAnnotation: NSObject, MKAnnotation {
    let banGhi: BanGhiCheckInPWA
    let coordinate: CLLocationCoordinate2D

    var title: String? {
        return "✅ \(banGhi.tenSachKhongNgoac) (\(banGhi.nhom))"
    }

    var subtitle: String? {
        return "\(banGhi.tuyen) • \(banGhi.diaDiem) • \(banGhi.thoiGian)"
    }

    init?(banGhi: BanGhiCheckInPWA) {
        guard let c = banGhi.toaDoHopLe else { return nil }
        self.banGhi = banGhi
        self.coordinate = c
    }
}

final class KhungGhimCheckInPWAView: MKAnnotationView {
    static let maTaiSuDung = "KhungGhimCheckInPWAView"

    private let chamTron = UIView()
    private let bieuTuong = UIImageView()
    private let khungNhan = UIView()
    private let nhanTen = UILabel()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        thietLapGiaoDien()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        thietLapGiaoDien()
    }

    private func thietLapGiaoDien() {
        canShowCallout = false
        displayPriority = .required
        collisionMode = .none

        chamTron.backgroundColor = BangMauBCTD.xanhLaDam
        chamTron.layer.cornerRadius = 13
        chamTron.layer.borderWidth = 2.2
        chamTron.layer.borderColor = UIColor.white.cgColor
        chamTron.layer.shadowColor = UIColor.black.cgColor
        chamTron.layer.shadowOpacity = 0.28
        chamTron.layer.shadowRadius = 4
        chamTron.layer.shadowOffset = CGSize(width: CGFloat(0), height: CGFloat(2))
        addSubview(chamTron)

        let cfg = UIImage.SymbolConfiguration(pointSize: 12, weight: .heavy)
        bieuTuong.image = UIImage(systemName: "checkmark", withConfiguration: cfg)
        bieuTuong.tintColor = .white
        bieuTuong.contentMode = .scaleAspectFit
        chamTron.addSubview(bieuTuong)

        khungNhan.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        khungNhan.layer.cornerRadius = 9
        khungNhan.layer.borderWidth = 1.4
        khungNhan.layer.borderColor = BangMauBCTD.xanhLaDam.cgColor
        khungNhan.layer.shadowColor = UIColor.black.cgColor
        khungNhan.layer.shadowOpacity = 0.22
        khungNhan.layer.shadowRadius = 3
        khungNhan.layer.shadowOffset = CGSize(width: CGFloat(0), height: CGFloat(1.5))
        addSubview(khungNhan)

        nhanTen.font = .systemFont(ofSize: 11, weight: .heavy)
        nhanTen.textColor = BangMauBCTD.xanhDatChu
        nhanTen.textAlignment = .center
        nhanTen.numberOfLines = 1
        khungNhan.addSubview(nhanTen)
    }

    func capNhat(voi ann: GhimCheckInPWAAnnotation, mauTuyen: UIColor?) {
        let mau = mauTuyen ?? BangMauBCTD.xanhLaDam
        chamTron.backgroundColor = mau
        khungNhan.layer.borderColor = mau.cgColor
        nhanTen.textColor = BangMauBCTD.chuChinh

        let tuyenNgan = ann.banGhi.soThuTuTuyen.map { "T\($0)" } ?? ann.banGhi.nhom
        let tenNgan = ann.banGhi.tenSachKhongNgoac
        nhanTen.text = "✅ \(tenNgan) • \(tuyenNgan)"

        let sizeChu = (nhanTen.text ?? "").size(withAttributes: [.font: nhanTen.font as Any])
        let wNhan = min(CGFloat(210), max(CGFloat(72), ceil(sizeChu.width) + CGFloat(14)))
        let hNhan = CGFloat(22)
        let dCham = CGFloat(26)
        let tongW = max(wNhan, dCham)
        let tongH = hNhan + CGFloat(3) + dCham

        bounds = CGRect(x: CGFloat(0), y: CGFloat(0), width: tongW, height: tongH)
        centerOffset = CGPoint(x: CGFloat(0), y: -(tongH / CGFloat(2) - dCham / CGFloat(2)))

        khungNhan.frame = CGRect(x: (tongW - wNhan) / CGFloat(2), y: CGFloat(0), width: wNhan, height: hNhan)
        nhanTen.frame = khungNhan.bounds.insetBy(dx: CGFloat(5), dy: CGFloat(1))

        chamTron.frame = CGRect(x: (tongW - dCham) / CGFloat(2), y: hNhan + CGFloat(3), width: dCham, height: dCham)
        bieuTuong.frame = CGRect(x: CGFloat(5), y: CGFloat(5), width: dCham - CGFloat(10), height: dCham - CGFloat(10))
    }
}

// MARK: - 5. Popup Xem Ảnh & Vị Trí Chi Tiết Của 1 Lượt Check-in PWA

final class HopChiTietCheckInPWAViewController: UIViewController {
    private let banGhi: BanGhiCheckInPWA
    private let khiXemTrenBanDo: ((BanGhiCheckInPWA) -> Void)?

    private let anhView = UIImageView()
    private let vongQuay = UIActivityIndicatorView(style: .medium)
    private let nhanTrangThaiAnh = UILabel()

    init(banGhi: BanGhiCheckInPWA, khiXemTrenBanDo: ((BanGhiCheckInPWA) -> Void)? = nil) {
        self.banGhi = banGhi
        self.khiXemTrenBanDo = khiXemTrenBanDo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Khong ho tro coder")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BangMauBCTD.nenTrang
        title = "📸 Chi tiết Check-in"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Đóng", style: .done, target: self, action: #selector(bamDong))
        dungGiaoDien()
        taiAnhMinhChung()
    }

    private func dungGiaoDien() {
        let cuon = UIScrollView()
        cuon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cuon)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        cuon.addSubview(stack)

        NSLayoutConstraint.activate([
            cuon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cuon.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cuon.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cuon.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: cuon.contentLayoutGuide.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: cuon.contentLayoutGuide.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: cuon.contentLayoutGuide.trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: cuon.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: cuon.frameLayoutGuide.widthAnchor, constant: -28)
        ])

        // Khung ảnh minh chứng
        let khungAnh = UIView()
        khungAnh.backgroundColor = BangMauBCTD.nenThePhu
        khungAnh.layer.cornerRadius = 14
        khungAnh.layer.borderWidth = 1
        khungAnh.layer.borderColor = BangMauBCTD.vienThe.cgColor
        khungAnh.clipsToBounds = true
        khungAnh.heightAnchor.constraint(equalToConstant: 300).isActive = true

        anhView.contentMode = .scaleAspectFit
        anhView.backgroundColor = UIColor.black.withAlphaComponent(0.06)
        anhView.translatesAutoresizingMaskIntoConstraints = false
        khungAnh.addSubview(anhView)

        vongQuay.color = BangMauBCTD.xanhChuDao
        vongQuay.translatesAutoresizingMaskIntoConstraints = false
        khungAnh.addSubview(vongQuay)

        nhanTrangThaiAnh.text = "Đang tải ảnh minh chứng từ Google Drive..."
        nhanTrangThaiAnh.font = .systemFont(ofSize: 12, weight: .semibold)
        nhanTrangThaiAnh.textColor = BangMauBCTD.chuPhu
        nhanTrangThaiAnh.textAlignment = .center
        nhanTrangThaiAnh.numberOfLines = 0
        nhanTrangThaiAnh.lineBreakMode = .byWordWrapping
        nhanTrangThaiAnh.adjustsFontSizeToFitWidth = false
        nhanTrangThaiAnh.translatesAutoresizingMaskIntoConstraints = false
        khungAnh.addSubview(nhanTrangThaiAnh)

        NSLayoutConstraint.activate([
            anhView.topAnchor.constraint(equalTo: khungAnh.topAnchor),
            anhView.leadingAnchor.constraint(equalTo: khungAnh.leadingAnchor),
            anhView.trailingAnchor.constraint(equalTo: khungAnh.trailingAnchor),
            anhView.bottomAnchor.constraint(equalTo: khungAnh.bottomAnchor),

            vongQuay.centerXAnchor.constraint(equalTo: khungAnh.centerXAnchor),
            vongQuay.centerYAnchor.constraint(equalTo: khungAnh.centerYAnchor, constant: -14),

            nhanTrangThaiAnh.topAnchor.constraint(equalTo: vongQuay.bottomAnchor, constant: 8),
            nhanTrangThaiAnh.leadingAnchor.constraint(equalTo: khungAnh.leadingAnchor, constant: 16),
            nhanTrangThaiAnh.trailingAnchor.constraint(equalTo: khungAnh.trailingAnchor, constant: -16)
        ])
        stack.addArrangedSubview(khungAnh)

        // Thẻ thông tin nhân sự & vị trí
        let theInfo = UIView()
        theInfo.backgroundColor = BangMauBCTD.nenThe
        theInfo.layer.cornerRadius = 12
        theInfo.layer.borderWidth = 1
        theInfo.layer.borderColor = BangMauBCTD.vienThe.cgColor

        let lbTen = UILabel()
        lbTen.text = "✅ \(banGhi.hoTen) (\(banGhi.nhom)\(banGhi.boPhan.isEmpty ? "" : " • \(banGhi.boPhan)"))"
        lbTen.font = .systemFont(ofSize: 15, weight: .heavy)
        lbTen.textColor = BangMauBCTD.xanhChuDaoDam
        lbTen.numberOfLines = 0
        lbTen.lineBreakMode = .byWordWrapping
        lbTen.adjustsFontSizeToFitWidth = false

        var dong: [String] = [
            "🕒 Thời gian: \(banGhi.thoiGian)",
            "🛣️ Tuyến: \(banGhi.tuyen)",
            "📍 Địa điểm: \(banGhi.diaDiem)",
            "🛰️ Tọa độ GPS: \(banGhi.toaDo)"
        ]
        if !banGhi.ghiChu.isEmpty {
            dong.append("💬 Ghi chú: \(banGhi.ghiChu)")
        }
        let lbChiTiet = UILabel()
        lbChiTiet.text = dong.joined(separator: "\n")
        lbChiTiet.font = .systemFont(ofSize: 13, weight: .medium)
        lbChiTiet.textColor = BangMauBCTD.chuChinh
        lbChiTiet.numberOfLines = 0
        lbChiTiet.lineBreakMode = .byWordWrapping
        lbChiTiet.adjustsFontSizeToFitWidth = false

        let stInfo = UIStackView(arrangedSubviews: [lbTen, lbChiTiet])
        stInfo.axis = .vertical
        stInfo.spacing = 7
        stInfo.translatesAutoresizingMaskIntoConstraints = false
        theInfo.addSubview(stInfo)
        NSLayoutConstraint.activate([
            stInfo.topAnchor.constraint(equalTo: theInfo.topAnchor, constant: 12),
            stInfo.leadingAnchor.constraint(equalTo: theInfo.leadingAnchor, constant: 12),
            stInfo.trailingAnchor.constraint(equalTo: theInfo.trailingAnchor, constant: -12),
            stInfo.bottomAnchor.constraint(equalTo: theInfo.bottomAnchor, constant: -12)
        ])
        stack.addArrangedSubview(theInfo)

        // Các nút hành động
        if khiXemTrenBanDo != nil && banGhi.toaDoHopLe != nil {
            let nutBanDo = UIButton(type: .system)
            nutBanDo.setTitle("📍 Xem vị trí check-in trên bản đồ app", for: .normal)
            nutBanDo.titleLabel?.font = .systemFont(ofSize: 13.5, weight: .heavy)
            nutBanDo.setTitleColor(.white, for: .normal)
            nutBanDo.backgroundColor = BangMauBCTD.xanhLaDam
            nutBanDo.layer.cornerRadius = 11
            nutBanDo.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            nutBanDo.addTarget(self, action: #selector(bamXemTrenBanDo), for: .touchUpInside)
            stack.addArrangedSubview(nutBanDo)
        }

        let hangLink = UIStackView()
        hangLink.axis = .horizontal
        hangLink.spacing = 8
        hangLink.distribution = .fillEqually

        let nutMaps = UIButton(type: .system)
        nutMaps.setTitle("🗺️ Mở Google Maps", for: .normal)
        nutMaps.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        nutMaps.setTitleColor(.white, for: .normal)
        nutMaps.backgroundColor = BangMauBCTD.xanhChuDao
        nutMaps.layer.cornerRadius = 10
        nutMaps.contentEdgeInsets = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        nutMaps.addTarget(self, action: #selector(bamMoGoogleMaps), for: .touchUpInside)

        let nutDrive = UIButton(type: .system)
        nutDrive.setTitle("🖼️ Mở ảnh gốc Drive", for: .normal)
        nutDrive.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        nutDrive.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
        nutDrive.backgroundColor = BangMauBCTD.nenHeaderPhu
        nutDrive.layer.cornerRadius = 10
        nutDrive.layer.borderWidth = 1
        nutDrive.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
        nutDrive.contentEdgeInsets = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        nutDrive.addTarget(self, action: #selector(bamMoDrive), for: .touchUpInside)

        hangLink.addArrangedSubview(nutMaps)
        hangLink.addArrangedSubview(nutDrive)
        stack.addArrangedSubview(hangLink)
    }

    private func taiAnhMinhChung() {
        vongQuay.startAnimating()
        BoTaiAnhCheckInPWA.dungChung.taiAnh(cho: banGhi) { [weak self] img in
            guard let self else { return }
            self.vongQuay.stopAnimating()
            if let img {
                self.anhView.image = img
                self.nhanTrangThaiAnh.isHidden = true
            } else {
                self.nhanTrangThaiAnh.text = "Không tải trực tiếp được ảnh thu nhỏ. Hãy bấm “🖼️ Mở ảnh gốc Drive” bên dưới."
                self.nhanTrangThaiAnh.isHidden = false
            }
        }
    }

    @objc private func bamDong() {
        dismiss(animated: true)
    }

    @objc private func bamXemTrenBanDo() {
        let cb = khiXemTrenBanDo
        let bg = banGhi
        dismiss(animated: true) {
            cb?(bg)
        }
    }

    @objc private func bamMoGoogleMaps() {
        if let url = URL(string: banGhi.linkMaps), !banGhi.linkMaps.isEmpty {
            UIApplication.shared.open(url)
        } else if let c = banGhi.toaDoHopLe, let url = URL(string: "https://www.google.com/maps?q=\(c.latitude),\(c.longitude)") {
            UIApplication.shared.open(url)
        }
    }

    @objc private func bamMoDrive() {
        let str = !banGhi.linkDrive.isEmpty ? banGhi.linkDrive : banGhi.linkAnh
        if let url = URL(string: str) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - 6. Bảng Quản Lý Kiểm Soát Hoàn Thành / Chưa Hoàn Thành & Ảnh Check-in PWA

final class HopQuanLyCheckInPWAViewController: UIViewController {
    private var keHoach: KeHoachMaTranTuan?
    private var dsCheckIn: [BanGhiCheckInPWA]
    private let khiCapNhatCheckIn: ([BanGhiCheckInPWA]) -> Void
    private let khiXemTrenBanDo: (BanGhiCheckInPWA) -> Void

    private let nhanTomTat = UILabel()
    private let chonTab = UISegmentedControl(items: ["Tất cả", "✅ Hoàn thành", "⏳ Chưa xong", "📸 Ảnh PWA"])
    private let cuon = UIScrollView()
    private let ngan = UIStackView()
    private let vongQuay = UIActivityIndicatorView(style: .medium)

    init(
        keHoach: KeHoachMaTranTuan?,
        dsCheckIn: [BanGhiCheckInPWA],
        khiCapNhatCheckIn: @escaping ([BanGhiCheckInPWA]) -> Void,
        khiXemTrenBanDo: @escaping (BanGhiCheckInPWA) -> Void
    ) {
        self.keHoach = keHoach
        self.dsCheckIn = dsCheckIn
        self.khiCapNhatCheckIn = khiCapNhatCheckIn
        self.khiXemTrenBanDo = khiXemTrenBanDo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Khong ho tro coder")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BangMauBCTD.nenTrang
        title = "🛡️ Quản lý Check-in PWA"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "🔄 Đồng bộ", style: .plain, target: self, action: #selector(bamDongBo))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Đóng", style: .done, target: self, action: #selector(bamDong))
        dungGiaoDien()
        capNhatDanhSach()
        bamDongBo()
    }

    private func dungGiaoDien() {
        nhanTomTat.font = .systemFont(ofSize: 12.5, weight: .bold)
        nhanTomTat.textColor = BangMauBCTD.xanhChuDaoDam
        nhanTomTat.backgroundColor = BangMauBCTD.nenHeaderPhu
        nhanTomTat.layer.cornerRadius = 10
        nhanTomTat.clipsToBounds = true
        nhanTomTat.numberOfLines = 0
        nhanTomTat.lineBreakMode = .byWordWrapping
        nhanTomTat.adjustsFontSizeToFitWidth = false
        nhanTomTat.translatesAutoresizingMaskIntoConstraints = false

        let khungTomTat = UIView()
        khungTomTat.backgroundColor = BangMauBCTD.nenHeaderPhu
        khungTomTat.layer.cornerRadius = 10
        khungTomTat.layer.borderWidth = 1
        khungTomTat.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
        khungTomTat.translatesAutoresizingMaskIntoConstraints = false
        khungTomTat.addSubview(nhanTomTat)
        vongQuay.color = BangMauBCTD.xanhChuDao
        vongQuay.hidesWhenStopped = true
        vongQuay.translatesAutoresizingMaskIntoConstraints = false
        khungTomTat.addSubview(vongQuay)
        view.addSubview(khungTomTat)

        chonTab.selectedSegmentIndex = (keHoach == nil) ? 3 : 0
        chonTab.addTarget(self, action: #selector(doiTab), for: .valueChanged)
        chonTab.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chonTab)

        cuon.alwaysBounceVertical = true
        cuon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cuon)

        ngan.axis = .vertical
        ngan.spacing = 9
        ngan.translatesAutoresizingMaskIntoConstraints = false
        cuon.addSubview(ngan)

        NSLayoutConstraint.activate([
            khungTomTat.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            khungTomTat.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            khungTomTat.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            nhanTomTat.topAnchor.constraint(equalTo: khungTomTat.topAnchor, constant: 9),
            nhanTomTat.leadingAnchor.constraint(equalTo: khungTomTat.leadingAnchor, constant: 10),
            nhanTomTat.trailingAnchor.constraint(equalTo: vongQuay.leadingAnchor, constant: -6),
            nhanTomTat.bottomAnchor.constraint(equalTo: khungTomTat.bottomAnchor, constant: -9),

            vongQuay.centerYAnchor.constraint(equalTo: khungTomTat.centerYAnchor),
            vongQuay.trailingAnchor.constraint(equalTo: khungTomTat.trailingAnchor, constant: -10),

            chonTab.topAnchor.constraint(equalTo: khungTomTat.bottomAnchor, constant: 10),
            chonTab.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            chonTab.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            cuon.topAnchor.constraint(equalTo: chonTab.bottomAnchor, constant: 10),
            cuon.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cuon.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cuon.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            ngan.topAnchor.constraint(equalTo: cuon.contentLayoutGuide.topAnchor, constant: 2),
            ngan.leadingAnchor.constraint(equalTo: cuon.contentLayoutGuide.leadingAnchor, constant: 12),
            ngan.trailingAnchor.constraint(equalTo: cuon.contentLayoutGuide.trailingAnchor, constant: -12),
            ngan.bottomAnchor.constraint(equalTo: cuon.contentLayoutGuide.bottomAnchor, constant: -24),
            ngan.widthAnchor.constraint(equalTo: cuon.frameLayoutGuide.widthAnchor, constant: -24)
        ])
    }

    @objc private func bamDong() {
        dismiss(animated: true)
    }

    @objc private func doiTab() {
        capNhatDanhSach()
    }

    @objc private func bamDongBo() {
        vongQuay.startAnimating()
        BoDongBoCheckInPWA.dungChung.taiDanhSachCheckIn { [weak self] res in
            guard let self else { return }
            self.vongQuay.stopAnimating()
            switch res {
            case .success(let ds):
                self.dsCheckIn = ds
                self.khiCapNhatCheckIn(ds)
                self.capNhatDanhSach()
            case .failure(let loi):
                self.nhanTomTat.text = "⚠️ Lỗi đồng bộ từ Google Sheet: \(loi.localizedDescription)"
            }
        }
    }

    private func capNhatDanhSach() {
        ngan.arrangedSubviews.forEach {
            ngan.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let cacO = keHoach?.cacO ?? []
        let cacTuyen = keHoach?.cacTuyen ?? []
        let soHoanThanh = cacO.filter { o in
            o.daPhat || !KhoCheckInPWADongBo.locCheckIn(choO: o, cacTuyen: cacTuyen, trong: dsCheckIn).isEmpty
        }.count
        let soChua = max(0, cacO.count - soHoanThanh)
        let tgCuoi = KhoCheckInPWADongBo.dungChung.lanDongBoCuoi
        nhanTomTat.text = "✅ Hoàn thành: \(soHoanThanh)/\(cacO.count) buổi • ⏳ Chưa hoàn thành: \(soChua) buổi\n📸 Tổng ảnh Check-in đồng bộ từ PWA: \(dsCheckIn.count)\(tgCuoi.isEmpty ? "" : " (cập nhật \(tgCuoi))")"

        if chonTab.selectedSegmentIndex == 3 {
            if dsCheckIn.isEmpty {
                ngan.addArrangedSubview(taoNhanTrong("Chưa có lượt check-in nào từ PWA trên tab BC-Phát tờ rơi."))
                return
            }
            for bc in dsCheckIn {
                ngan.addArrangedSubview(taoTheCheckInPWA(bc))
            }
            return
        }

        if cacO.isEmpty {
            ngan.addArrangedSubview(taoNhanTrong("Chưa có Ma trận tuần. Bấm sang mục “📸 Ảnh PWA” để xem các ảnh nhân viên đã nộp."))
            return
        }

        var daThem = 0
        for o in cacO {
            let dsKhop = KhoCheckInPWADongBo.locCheckIn(choO: o, cacTuyen: cacTuyen, trong: dsCheckIn)
            let hoanThanh = o.daPhat || !dsKhop.isEmpty
            if chonTab.selectedSegmentIndex == 1 && !hoanThanh { continue }
            if chonTab.selectedSegmentIndex == 2 && hoanThanh { continue }
            daThem += 1
            ngan.addArrangedSubview(taoTheTrangThaiBuoi(o: o, checkIns: dsKhop, hoanThanh: hoanThanh))
        }

        if daThem == 0 {
            ngan.addArrangedSubview(taoNhanTrong("Không có buổi nào thuộc bộ lọc này."))
        }
    }

    private func taoNhanTrong(_ text: String) -> UILabel {
        let lb = UILabel()
        lb.text = text
        lb.font = .systemFont(ofSize: 13, weight: .medium)
        lb.textColor = BangMauBCTD.chuMo
        lb.textAlignment = .center
        lb.numberOfLines = 0
        lb.lineBreakMode = .byWordWrapping
        lb.adjustsFontSizeToFitWidth = false
        return lb
    }

    private func taoTheTrangThaiBuoi(o: OMaTranPhatToRoi, checkIns: [BanGhiCheckInPWA], hoanThanh: Bool) -> UIView {
        let the = UIView()
        the.backgroundColor = hoanThanh ? BangMauBCTD.xanhDatNenDong : BangMauBCTD.nenThe
        the.layer.cornerRadius = 11
        the.layer.borderWidth = 1.1
        the.layer.borderColor = (hoanThanh ? BangMauBCTD.xanhLaDam.withAlphaComponent(0.5) : BangMauBCTD.vienThe).cgColor

        let thu = (o.thuIndex >= 0 && o.thuIndex < BoPhanTichLichCaExcel.tenThu.count) ? BoPhanTichLichCaExcel.tenThu[o.thuIndex] : "Thứ"
        let lbTieuDe = UILabel()
        lbTieuDe.text = "\(hoanThanh ? "✅" : "⏳") \(thu) • \(o.buoi) — \(o.tenTuyen)"
        lbTieuDe.font = .systemFont(ofSize: 13, weight: .heavy)
        lbTieuDe.textColor = hoanThanh ? BangMauBCTD.xanhDatChu : BangMauBCTD.doYeuChu
        lbTieuDe.numberOfLines = 0
        lbTieuDe.lineBreakMode = .byWordWrapping
        lbTieuDe.adjustsFontSizeToFitWidth = false

        var nsList: [String] = []
        if !o.danhSachPG.isEmpty { nsList.append("PG: \(o.danhSachPG.joined(separator: ", "))") }
        if !o.danhSachNV.isEmpty { nsList.append("NV: \(o.danhSachNV.joined(separator: ", "))") }
        let lbNS = UILabel()
        lbNS.text = nsList.isEmpty ? "Chưa phân nhân sự" : nsList.joined(separator: "\n")
        lbNS.font = .systemFont(ofSize: 12, weight: .semibold)
        lbNS.textColor = BangMauBCTD.chuChinh
        lbNS.numberOfLines = 0
        lbNS.lineBreakMode = .byWordWrapping
        lbNS.adjustsFontSizeToFitWidth = false

        var views: [UIView] = [lbTieuDe, lbNS]
        if checkIns.isEmpty {
            let lbTT = UILabel()
            lbTT.text = hoanThanh ? "Đã đánh dấu hoàn thành thủ công (chưa có ảnh từ PWA)." : "Chưa có nhân viên/PG nào check-in trên PWA."
            lbTT.font = .systemFont(ofSize: 11.5, weight: .medium)
            lbTT.textColor = BangMauBCTD.chuPhu
            lbTT.numberOfLines = 0
            lbTT.lineBreakMode = .byWordWrapping
            lbTT.adjustsFontSizeToFitWidth = false
            views.append(lbTT)
        } else {
            for bc in checkIns {
                views.append(taoTheCheckInPWA(bc))
            }
        }

        let st = UIStackView(arrangedSubviews: views)
        st.axis = .vertical
        st.spacing = 6
        st.translatesAutoresizingMaskIntoConstraints = false
        the.addSubview(st)
        NSLayoutConstraint.activate([
            st.topAnchor.constraint(equalTo: the.topAnchor, constant: 10),
            st.leadingAnchor.constraint(equalTo: the.leadingAnchor, constant: 10),
            st.trailingAnchor.constraint(equalTo: the.trailingAnchor, constant: -10),
            st.bottomAnchor.constraint(equalTo: the.bottomAnchor, constant: -10)
        ])
        return the
    }

    private func taoTheCheckInPWA(_ bc: BanGhiCheckInPWA) -> UIView {
        let the = UIControl()
        the.backgroundColor = BangMauBCTD.nenThe
        the.layer.cornerRadius = 10
        the.layer.borderWidth = 1
        the.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor

        let thumb = UIImageView()
        thumb.backgroundColor = BangMauBCTD.nenThePhu
        thumb.contentMode = .scaleAspectFill
        thumb.clipsToBounds = true
        thumb.layer.cornerRadius = 8
        thumb.translatesAutoresizingMaskIntoConstraints = false
        thumb.widthAnchor.constraint(equalToConstant: 66).isActive = true
        thumb.heightAnchor.constraint(equalToConstant: 66).isActive = true
        BoTaiAnhCheckInPWA.dungChung.taiAnh(cho: bc) { img in
            thumb.image = img ?? UIImage(systemName: "photo")
        }

        let lbTen = UILabel()
        lbTen.text = "✅ \(bc.hoTen) (\(bc.nhom)) • \(bc.tuyen)"
        lbTen.font = .systemFont(ofSize: 12.5, weight: .heavy)
        lbTen.textColor = BangMauBCTD.xanhChuDaoDam
        lbTen.numberOfLines = 0
        lbTen.lineBreakMode = .byWordWrapping
        lbTen.adjustsFontSizeToFitWidth = false

        let lbChiTiet = UILabel()
        lbChiTiet.text = "🕒 \(bc.thoiGian)\n📍 \(bc.diaDiem)\(bc.ghiChu.isEmpty ? "" : "\n💬 \(bc.ghiChu)")"
        lbChiTiet.font = .systemFont(ofSize: 11.5, weight: .medium)
        lbChiTiet.textColor = BangMauBCTD.chuPhu
        lbChiTiet.numberOfLines = 0
        lbChiTiet.lineBreakMode = .byWordWrapping
        lbChiTiet.adjustsFontSizeToFitWidth = false

        let nutXemAnh = UIButton(type: .system)
        nutXemAnh.setTitle("🖼️ Xem ảnh & vị trí", for: .normal)
        nutXemAnh.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutXemAnh.setTitleColor(.white, for: .normal)
        nutXemAnh.backgroundColor = BangMauBCTD.xanhChuDao
        nutXemAnh.layer.cornerRadius = 7
        nutXemAnh.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        nutXemAnh.addAction(UIAction { [weak self] _ in
            self?.moChiTiet(bc)
        }, for: .touchUpInside)

        let nutBanDo = UIButton(type: .system)
        nutBanDo.setTitle("📍 Bản đồ", for: .normal)
        nutBanDo.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutBanDo.setTitleColor(BangMauBCTD.xanhDatChu, for: .normal)
        nutBanDo.backgroundColor = BangMauBCTD.xanhDatPill
        nutBanDo.layer.cornerRadius = 7
        nutBanDo.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        nutBanDo.isEnabled = (bc.toaDoHopLe != nil)
        nutBanDo.alpha = (bc.toaDoHopLe != nil) ? 1.0 : 0.45
        nutBanDo.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let cb = self.khiXemTrenBanDo
            self.dismiss(animated: true) { cb(bc) }
        }, for: .touchUpInside)

        let hangNut = UIStackView(arrangedSubviews: [nutXemAnh, nutBanDo])
        hangNut.axis = .horizontal
        hangNut.spacing = 6

        let cotChu = UIStackView(arrangedSubviews: [lbTen, lbChiTiet, hangNut])
        cotChu.axis = .vertical
        cotChu.spacing = 4

        let hang = UIStackView(arrangedSubviews: [thumb, cotChu])
        hang.axis = .horizontal
        hang.spacing = 9
        hang.alignment = .top
        hang.translatesAutoresizingMaskIntoConstraints = false
        the.addSubview(hang)

        NSLayoutConstraint.activate([
            hang.topAnchor.constraint(equalTo: the.topAnchor, constant: 8),
            hang.leadingAnchor.constraint(equalTo: the.leadingAnchor, constant: 8),
            hang.trailingAnchor.constraint(equalTo: the.trailingAnchor, constant: -8),
            hang.bottomAnchor.constraint(equalTo: the.bottomAnchor, constant: -8)
        ])

        the.addAction(UIAction { [weak self] _ in
            self?.moChiTiet(bc)
        }, for: .touchUpInside)

        return the
    }

    private func moChiTiet(_ bc: BanGhiCheckInPWA) {
        let vc = HopChiTietCheckInPWAViewController(banGhi: bc) { [weak self] bg in
            guard let self else { return }
            let cb = self.khiXemTrenBanDo
            self.dismiss(animated: true) { cb(bg) }
        }
        let nav = UINavigationController(rootViewController: vc)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }
}
