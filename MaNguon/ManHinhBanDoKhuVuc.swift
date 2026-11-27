import UIKit
import MapKit
import CoreLocation

// MARK: - Mô Hình Dữ Liệu Quét Khu Vực, Siêu Thị Đã Lưu & Tuyến Phát Tờ Rơi

enum LoaiDiaDiemQuet: String, CaseIterable, Codable {
    case doiThu = "doi_thu"
    case heThongMWG = "he_thong_mwg"
    case truongHoc = "truong_hoc"
    case cho = "cho"
    case khac = "khac"

    var tieuDe: String {
        switch self {
        case .doiThu: return "Đối thủ"
        case .heThongMWG: return "ĐMX/TGDĐ"
        case .truongHoc: return "Trường học"
        case .cho: return "Chợ"
        case .khac: return "Khác"
        }
    }

    var tieuDeNgan: String {
        switch self {
        case .doiThu: return "Đối thủ"
        case .heThongMWG: return "ĐMX/TGDĐ"
        case .truongHoc: return "Trường"
        case .cho: return "Chợ"
        case .khac: return "Khác"
        }
    }

    var tieuDeDayDu: String {
        switch self {
        case .doiThu: return "Đối thủ (Điện máy / Gia dụng)"
        case .heThongMWG: return "Cửa hàng ĐMX / TGDĐ"
        case .truongHoc: return "Trường học"
        case .cho: return "Chợ"
        case .khac: return "Khác (Ăn uống, Thời trang, Thú cưng, Tiện ích)"
        }
    }

    var bieuTuongSF: String {
        switch self {
        case .doiThu: return "storefront.fill"
        case .heThongMWG: return "bolt.fill"
        case .truongHoc: return "graduationcap.fill"
        case .cho: return "basket.fill"
        case .khac: return "bag.fill"
        }
    }

    var mauChuDao: UIColor {
        switch self {
        case .doiThu: return UIColor(red: 0.86, green: 0.15, blue: 0.15, alpha: 1.0)      // Đỏ #DC2626
        case .heThongMWG: return UIColor(red: 0.05, green: 0.58, blue: 0.53, alpha: 1.0)  // Xanh ngọc #0D9488
        case .truongHoc: return UIColor(red: 0.14, green: 0.39, blue: 0.92, alpha: 1.0)   // Xanh dương #2563EB
        case .cho: return UIColor(red: 0.85, green: 0.47, blue: 0.02, alpha: 1.0)         // Cam vàng #D97706
        case .khac: return UIColor(red: 0.49, green: 0.23, blue: 0.93, alpha: 1.0)        // Tím #7C3AED
        }
    }

    var mauNenNhat: UIColor {
        switch self {
        case .doiThu: return UIColor(red: 1.00, green: 0.95, blue: 0.95, alpha: 1.0)
        case .heThongMWG: return UIColor(red: 0.91, green: 0.99, blue: 0.97, alpha: 1.0)
        case .truongHoc: return UIColor(red: 0.93, green: 0.96, blue: 1.00, alpha: 1.0)
        case .cho: return UIColor(red: 1.00, green: 0.97, blue: 0.88, alpha: 1.0)
        case .khac: return UIColor(red: 0.96, green: 0.94, blue: 1.00, alpha: 1.0)
        }
    }

    /// Trọng số hiệu quả phát tờ rơi (Chợ & Trường học ưu tiên cao nhất, tiếp đến vùng Đối thủ)
    var diemUuTienToRoi: Double {
        switch self {
        case .cho: return 10.0
        case .truongHoc: return 9.0
        case .doiThu: return 7.0
        case .khac: return 3.5
        case .heThongMWG: return 0.0
        }
    }
}

struct DiaDiemSieuThiLuu: Codable, Equatable {
    let id: String
    var ten: String
    var viDo: Double
    var kinhDo: Double
    var dangChon: Bool

    var toaDo: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: viDo, longitude: kinhDo)
    }
}

private final class KhoDiaDiemSieuThi {
    static let dungChung = KhoDiaDiemSieuThi()
    private init() {}

    private let khoaLuu = "dmx_bando_ds_sieu_thi_luu_v1"

    func taiDanhSach() -> [DiaDiemSieuThiLuu] {
        guard let data = UserDefaults.standard.data(forKey: khoaLuu),
              let ds = try? JSONDecoder().decode([DiaDiemSieuThiLuu].self, from: data) else {
            return []
        }
        return ds
    }

    func luuDanhSach(_ ds: [DiaDiemSieuThiLuu]) {
        if let data = try? JSONEncoder().encode(ds) {
            UserDefaults.standard.set(data, forKey: khoaLuu)
        }
    }
}

struct DiaDiemQuet: Codable, Equatable {
    let id: String
    let ten: String
    let diaChi: String
    let loai: LoaiDiaDiemQuet
    let viDo: Double
    let kinhDo: Double
    let khoangCachMet: Double
    let nguon: String
    var soThuTuTuyen: Int? = nil

    var toaDo: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: viDo, longitude: kinhDo)
    }
}

struct KetQuaTuyenPhatToRoi {
    let cacDiemDung: [DiaDiemQuet]
    let toaDoDuongDi: [CLLocationCoordinate2D]
    let tongQuangDuongMet: Double
    let thoiGianPhut: Int
    let laDuongThucTe: Bool
    let khoangCachTungChangMet: [Double]
    let chiDanTungBuoc: [BuocChiDanTuyen]
    let thoiGianXeMayPhut: Int
    let thoiGianDiBoPhut: Int

    init(
        cacDiemDung: [DiaDiemQuet],
        toaDoDuongDi: [CLLocationCoordinate2D],
        tongQuangDuongMet: Double,
        thoiGianPhut: Int,
        laDuongThucTe: Bool,
        khoangCachTungChangMet: [Double],
        chiDanTungBuoc: [BuocChiDanTuyen] = [],
        thoiGianXeMayPhut: Int? = nil,
        thoiGianDiBoPhut: Int? = nil
    ) {
        self.cacDiemDung = cacDiemDung
        self.toaDoDuongDi = toaDoDuongDi
        self.tongQuangDuongMet = tongQuangDuongMet
        self.thoiGianPhut = thoiGianPhut
        self.laDuongThucTe = laDuongThucTe
        self.khoangCachTungChangMet = khoangCachTungChangMet
        self.chiDanTungBuoc = chiDanTungBuoc
        self.thoiGianXeMayPhut = thoiGianXeMayPhut ?? BoDanDuongTuyenThucTe.tinhThoiGianXeMayPhut(quangDuongMet: tongQuangDuongMet)
        self.thoiGianDiBoPhut = thoiGianDiBoPhut ?? BoDanDuongTuyenThucTe.tinhThoiGianDiBoPhut(quangDuongMet: tongQuangDuongMet)
    }

    func sangBanLuu() -> KetQuaTuyenLuu {
        return KetQuaTuyenLuu(
            cacDiemDung: cacDiemDung,
            toaDoDuongDi: toaDoDuongDi.map { [$0.latitude, $0.longitude] },
            tongQuangDuongMet: tongQuangDuongMet,
            thoiGianPhut: thoiGianPhut,
            laDuongThucTe: laDuongThucTe,
            khoangCachTungChangMet: khoangCachTungChangMet,
            chiDanTungBuoc: chiDanTungBuoc,
            thoiGianXeMayPhut: thoiGianXeMayPhut,
            thoiGianDiBoPhut: thoiGianDiBoPhut
        )
    }

    static func tuBanLuu(_ luu: KetQuaTuyenLuu) -> KetQuaTuyenPhatToRoi {
        let coords = luu.toaDoDuongDi.compactMap { p -> CLLocationCoordinate2D? in
            guard p.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: p[0], longitude: p[1])
        }
        return KetQuaTuyenPhatToRoi(
            cacDiemDung: luu.cacDiemDung,
            toaDoDuongDi: coords,
            tongQuangDuongMet: luu.tongQuangDuongMet,
            thoiGianPhut: luu.thoiGianPhut,
            laDuongThucTe: luu.laDuongThucTe,
            khoangCachTungChangMet: luu.khoangCachTungChangMet,
            chiDanTungBuoc: luu.chiDanTungBuoc,
            thoiGianXeMayPhut: luu.thoiGianXeMayPhut,
            thoiGianDiBoPhut: luu.thoiGianDiBoPhut
        )
    }
}

// MARK: - Annotation & Overlay Tùy Biến Cho Bản Đồ

private final class GhimTamQuetAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var laSieuThiDaLuu: Bool = false

    init(
        coordinate: CLLocationCoordinate2D,
        title: String = "Tâm quét (Siêu thị)",
        subtitle: String? = "Chạm giữ bản đồ để di chuyển",
        laSieuThiDaLuu: Bool = false
    ) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.laSieuThiDaLuu = laSieuThiDaLuu
    }
}

private final class GhimDiaDiemAnnotation: NSObject, MKAnnotation {
    let diaDiem: DiaDiemQuet
    var coordinate: CLLocationCoordinate2D { diaDiem.toaDo }
    var title: String? {
        if let stt = diaDiem.soThuTuTuyen {
            return "#\(stt) \(diaDiem.ten)"
        }
        return diaDiem.ten
    }
    var subtitle: String? {
        let kc = Int(round(diaDiem.khoangCachMet))
        if diaDiem.diaChi.isEmpty {
            return "\(diaDiem.loai.tieuDe) • \(kc) m"
        }
        return "\(diaDiem.loai.tieuDe) • \(kc) m • \(diaDiem.diaChi)"
    }

    init(diaDiem: DiaDiemQuet) {
        self.diaDiem = diaDiem
    }
}

private final class TuyenPhatToRoiPolyline: MKPolyline {
    var laVienNen: Bool = false
    var mauTuyen: UIColor = BangMauBCTD.xanhDatVach
}

private final class VongBanKinhToRoiCircle: MKCircle {}

private final class GhimNhanTuyenAnnotation: NSObject, MKAnnotation {
    let soThuTu: Int
    let tenTuyen: String
    let moTa: String
    let mauTuyen: UIColor
    let coordinate: CLLocationCoordinate2D

    var title: String? { tenTuyen }
    var subtitle: String? { moTa }

    init(soThuTu: Int, tenTuyen: String, moTa: String, mauTuyen: UIColor, coordinate: CLLocationCoordinate2D) {
        self.soThuTu = soThuTu
        self.tenTuyen = tenTuyen
        self.moTa = moTa
        self.mauTuyen = mauTuyen
        self.coordinate = coordinate
    }
}

private final class GhimBangChungAnnotation: NSObject, MKAnnotation {
    let bangChung: BangChungPhatToRoi
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: bangChung.viDoCheckIn, longitude: bangChung.kinhDoCheckIn)
    }
    var title: String? { "✅ \(bangChung.tenDiaDiem) (\(bangChung.tenNhanSu))" }
    var subtitle: String? { "\(bangChung.trangThaiViTri.nhan) • \(bangChung.thoiGianHienThi)" }

    init(bangChung: BangChungPhatToRoi) {
        self.bangChung = bangChung
    }
}

// MARK: - Dịch Vụ Quét Đa Nguồn (Overpass OSM + Apple MKLocalSearch + Google Places Tùy Chọn)

private final class DichVuQuetKhuVuc {
    static let dungChung = DichVuQuetKhuVuc()
    private init() {}

    static let khoaGoogleApiKey = "dmx_google_maps_api_key_v1"

    var googleApiKey: String {
        get { (UserDefaults.standard.string(forKey: Self.khoaGoogleApiKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }
        set { UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Self.khoaGoogleApiKey) }
    }

    private let phienMang: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 14
        cfg.timeoutIntervalForResource = 22
        return URLSession(configuration: cfg)
    }()

    /// Quét đồng thời nhiều tâm (1 hoặc nhiều siêu thị/địa điểm) rồi hợp nhất, loại trùng
    func quetNhieuTam(
        cacTam: [CLLocationCoordinate2D],
        banKinhMet: Double,
        capNhatTrangThai: @escaping (String) -> Void,
        hoanThanh: @escaping ([DiaDiemQuet], [String]) -> Void
    ) {
        guard !cacTam.isEmpty else {
            DispatchQueue.main.async { hoanThanh([], []) }
            return
        }

        let nhomTong = DispatchGroup()
        let khoa = NSLock()
        var tatCaGop: [DiaDiemQuet] = []
        var nguonSet: Set<String> = []

        DispatchQueue.main.async {
            if cacTam.count > 1 {
                capNhatTrangThai("Đang quét đồng thời \(cacTam.count) vị trí đã chọn...")
            } else {
                capNhatTrangThai("Đang quét đối thủ, ĐMX/TGDĐ, trường học & chợ...")
            }
        }

        for tam in cacTam {
            nhomTong.enter()
            quetMotTam(tam: tam, banKinhMet: banKinhMet) { ds, dsNguon in
                khoa.lock()
                tatCaGop.append(contentsOf: ds)
                for n in dsNguon { nguonSet.insert(n) }
                khoa.unlock()
                nhomTong.leave()
            }
        }

        nhomTong.notify(queue: .global(qos: .userInitiated)) {
            let daLoc = self.hopNhatVaLoaiTrungNhieuTam(tatCaGop, cacTam: cacTam, banKinhMet: banKinhMet)
            DispatchQueue.main.async {
                hoanThanh(daLoc, Array(nguonSet).sorted())
            }
        }
    }

    private func quetMotTam(
        tam: CLLocationCoordinate2D,
        banKinhMet: Double,
        hoanThanh: @escaping ([DiaDiemQuet], [String]) -> Void
    ) {
        let nhom = DispatchGroup()
        let khoa = NSLock()
        var tatCa: [DiaDiemQuet] = []
        var ghiChuNguon: [String] = []

        func themKetQua(_ ds: [DiaDiemQuet], tenNguon: String) {
            khoa.lock()
            tatCa.append(contentsOf: ds)
            if !ds.isEmpty { ghiChuNguon.append(tenNguon) }
            khoa.unlock()
        }

        // 1. Nguồn Apple MapKit LocalSearch
        nhom.enter()
        quetBangAppleLocalSearch(tam: tam, banKinhMet: banKinhMet) { ds in
            themKetQua(ds, tenNguon: "Apple Map")
            nhom.leave()
        }

        // 2. Nguồn OpenStreetMap Overpass API
        nhom.enter()
        quetBangOverpassOSM(tam: tam, banKinhMet: banKinhMet) { ds in
            themKetQua(ds, tenNguon: "OpenStreetMap")
            nhom.leave()
        }

        // 3. Nguồn Google Places API (nếu người dùng đã nhập API Key)
        let keyGG = googleApiKey
        if !keyGG.isEmpty {
            nhom.enter()
            quetBangGooglePlaces(tam: tam, banKinhMet: banKinhMet, apiKey: keyGG) { ds in
                themKetQua(ds, tenNguon: "Google Places")
                nhom.leave()
            }
        }

        nhom.notify(queue: .global(qos: .userInitiated)) {
            hoanThanh(tatCa, ghiChuNguon)
        }
    }

    // MARK: 1. Apple MKLocalSearch

    private func quetBangAppleLocalSearch(
        tam: CLLocationCoordinate2D,
        banKinhMet: Double,
        hoanThanh: @escaping ([DiaDiemQuet]) -> Void
    ) {
        let vung = MKCoordinateRegion(
            center: tam,
            latitudinalMeters: banKinhMet * 2.15,
            longitudinalMeters: banKinhMet * 2.15
        )
        let truyVan: [(String, LoaiDiaDiemQuet)] = [
            ("Điện Máy Xanh", .heThongMWG),
            ("Thế Giới Di Động", .heThongMWG),
            ("điện máy", .doiThu),
            ("gia dụng", .doiThu),
            ("điện lạnh", .doiThu),
            ("máy lạnh", .doiThu),
            ("điện cơ", .doiThu),
            ("điện thoại", .doiThu),
            ("cửa hàng điện tử", .doiThu),
            ("trường học", .truongHoc),
            ("trường tiểu học", .truongHoc),
            ("trường THCS", .truongHoc),
            ("trường THPT", .truongHoc),
            ("trường mầm non", .truongHoc),
            ("chợ", .cho),
            ("nhà hàng quán ăn", .khac),
            ("cà phê trà sữa", .khac),
            ("shop quần áo thời trang", .khac),
            ("thú cưng pet shop", .khac),
            ("siêu thị mini nhà thuốc", .khac)
        ]

        let nhom = DispatchGroup()
        let khoa = NSLock()
        var ketQua: [DiaDiemQuet] = []
        let viTriTam = CLLocation(latitude: tam.latitude, longitude: tam.longitude)

        for (tuKhoa, loaiGoiY) in truyVan {
            nhom.enter()
            let req = MKLocalSearch.Request()
            req.naturalLanguageQuery = tuKhoa
            req.region = vung
            req.resultTypes = .pointOfInterest

            let search = MKLocalSearch(request: req)
            search.start { resp, _ in
                defer { nhom.leave() }
                guard let items = resp?.mapItems else { return }
                var danhSachTam: [DiaDiemQuet] = []
                for item in items {
                    let ten = (item.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !ten.isEmpty else { continue }
                    let toaDo = item.placemark.coordinate
                    let kc = viTriTam.distance(from: CLLocation(latitude: toaDo.latitude, longitude: toaDo.longitude))
                    guard kc <= banKinhMet else { continue }

                    if let cat = item.pointOfInterestCategory, self.laDanhMucAppleBiLoai(cat) {
                        continue
                    }
                    let diaChi = self.dinhDangDiaChi(item.placemark)
                    guard let loaiChuan = self.phanLoaiChinhXac(ten: ten, diaChi: diaChi, goiY: loaiGoiY, tagOSMChacChan: false) else {
                        continue
                    }

                    let id = "apple_\(loaiChuan.rawValue)_\(Int(toaDo.latitude * 100000))_\(Int(toaDo.longitude * 100000))"
                    danhSachTam.append(DiaDiemQuet(
                        id: id,
                        ten: ten,
                        diaChi: diaChi,
                        loai: loaiChuan,
                        viDo: toaDo.latitude,
                        kinhDo: toaDo.longitude,
                        khoangCachMet: kc,
                        nguon: "Apple"
                    ))
                }
                khoa.lock()
                ketQua.append(contentsOf: danhSachTam)
                khoa.unlock()
            }
        }

        nhom.notify(queue: .global(qos: .userInitiated)) {
            hoanThanh(ketQua)
        }
    }

    private func dinhDangDiaChi(_ pm: MKPlacemark) -> String {
        let phan = [pm.subThoroughfare, pm.thoroughfare, pm.subLocality, pm.locality]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return phan.joined(separator: ", ")
    }

    // MARK: 2. OpenStreetMap Overpass API

    private func quetBangOverpassOSM(
        tam: CLLocationCoordinate2D,
        banKinhMet: Double,
        hoanThanh: @escaping ([DiaDiemQuet]) -> Void
    ) {
        let r = Int(max(100, min(20000, banKinhMet)))
        let lat = String(format: "%.6f", tam.latitude)
        let lon = String(format: "%.6f", tam.longitude)

        let query = """
        [out:json][timeout:16];
        (
          nwr(around:\(r),\(lat),\(lon))["amenity"~"^(school|kindergarten|college|university|marketplace|restaurant|cafe|fast_food|pharmacy|veterinary)$"];
          nwr(around:\(r),\(lat),\(lon))["shop"~"^(electronics|appliance|electrical|houseware|hifi|computer|mobile_phone|marketplace|clothes|fashion|pet|convenience|supermarket|bakery|beauty|hairdresser|shoes|cosmetics)$"];
          nwr(around:\(r),\(lat),\(lon))["name"~"^(Chợ|Trường|Điện [Mm]áy|Điện [Ll]ạnh|Điện [Cc]ơ|Điện [Tt]hoại|Máy [Ll]ạnh|Thế [Gg]iới [Dd]i [Đđ]ộng|TopZone|Gia [Dd]ụng|Siêu [Tt]hị Điện)",i];
        );
        out center tags 420;
        """

        let cacMayChu = [
            "https://overpass-api.de/api/interpreter",
            "https://overpass.kumi.systems/api/interpreter"
        ]

        goiOverpass(danhSachURL: cacMayChu, chiSo: 0, query: query, tam: tam, banKinhMet: banKinhMet, hoanThanh: hoanThanh)
    }

    private func goiOverpass(
        danhSachURL: [String],
        chiSo: Int,
        query: String,
        tam: CLLocationCoordinate2D,
        banKinhMet: Double,
        hoanThanh: @escaping ([DiaDiemQuet]) -> Void
    ) {
        guard chiSo < danhSachURL.count, let url = URL(string: danhSachURL[chiSo]) else {
            hoanThanh([])
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        req.setValue("DMX-V2-iOS/1.0", forHTTPHeaderField: "User-Agent")
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let body = "data=" + (query.addingPercentEncoding(withAllowedCharacters: allowed) ?? query)
        req.httpBody = body.data(using: .utf8)

        phienMang.dataTask(with: req) { [weak self] data, resp, err in
            guard let self = self else { hoanThanh([]); return }
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            if err != nil || code != 200 || data == nil {
                self.goiOverpass(danhSachURL: danhSachURL, chiSo: chiSo + 1, query: query, tam: tam, banKinhMet: banKinhMet, hoanThanh: hoanThanh)
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let elements = json["elements"] as? [[String: Any]] else {
                hoanThanh([])
                return
            }

            let viTriTam = CLLocation(latitude: tam.latitude, longitude: tam.longitude)
            var ketQua: [DiaDiemQuet] = []

            for el in elements {
                let tags = el["tags"] as? [String: Any] ?? [:]
                let ten = ((tags["name"] as? String) ?? (tags["brand"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !ten.isEmpty else { continue }

                var latVal: Double?
                var lonVal: Double?
                if let la = el["lat"] as? Double, let lo = el["lon"] as? Double {
                    latVal = la; lonVal = lo
                } else if let center = el["center"] as? [String: Any],
                          let la = center["lat"] as? Double, let lo = center["lon"] as? Double {
                    latVal = la; lonVal = lo
                }
                guard let la = latVal, let lo = lonVal else { continue }

                let kc = viTriTam.distance(from: CLLocation(latitude: la, longitude: lo))
                guard kc <= banKinhMet else { continue }

                let amenity = (tags["amenity"] as? String ?? "").lowercased()
                let shop = (tags["shop"] as? String ?? "").lowercased()

                let goiY: LoaiDiaDiemQuet?
                let tagChacChan: Bool
                if ["school", "kindergarten", "college", "university"].contains(amenity) {
                    goiY = .truongHoc
                    tagChacChan = true
                } else if amenity == "marketplace" || shop == "marketplace" {
                    goiY = .cho
                    tagChacChan = true
                } else if ["electronics", "appliance", "electrical", "houseware", "hifi", "computer", "mobile_phone"].contains(shop) {
                    goiY = .doiThu
                    tagChacChan = true
                } else if ["restaurant", "cafe", "fast_food", "pharmacy", "veterinary"].contains(amenity)
                            || ["clothes", "fashion", "pet", "convenience", "supermarket", "bakery", "beauty", "hairdresser", "shoes", "cosmetics"].contains(shop) {
                    goiY = .khac
                    tagChacChan = true
                } else {
                    goiY = nil
                    tagChacChan = false
                }

                let duong = (tags["addr:street"] as? String) ?? ""
                let soNha = (tags["addr:housenumber"] as? String) ?? ""
                let phuong = (tags["addr:suburb"] as? String) ?? (tags["addr:district"] as? String) ?? ""
                let diaChi = [soNha, duong, phuong].filter { !$0.isEmpty }.joined(separator: ", ")

                guard let loaiChuan = self.phanLoaiChinhXac(ten: ten, diaChi: diaChi, goiY: goiY, tagOSMChacChan: tagChacChan) else {
                    continue
                }

                let idNum = el["id"] as? Int64 ?? Int64(la * 100000)
                ketQua.append(DiaDiemQuet(
                    id: "osm_\(idNum)",
                    ten: ten,
                    diaChi: diaChi,
                    loai: loaiChuan,
                    viDo: la,
                    kinhDo: lo,
                    khoangCachMet: kc,
                    nguon: "OSM"
                ))
            }

            hoanThanh(ketQua)
        }.resume()
    }

    // MARK: 3. Google Places API (Tùy chọn khi người dùng nhập Key)

    private func quetBangGooglePlaces(
        tam: CLLocationCoordinate2D,
        banKinhMet: Double,
        apiKey: String,
        hoanThanh: @escaping ([DiaDiemQuet]) -> Void
    ) {
        let r = Int(max(100, min(50000, banKinhMet)))
        let loc = "\(tam.latitude),\(tam.longitude)"
        let dsTruyVan: [(String, LoaiDiaDiemQuet)] = [
            ("keyword=Điện+Máy+Xanh+Thế+Giới+Di+Động", .heThongMWG),
            ("type=electronics_store&keyword=điện+máy+gia+dụng", .doiThu),
            ("type=home_goods_store&keyword=gia+dụng", .doiThu),
            ("type=school", .truongHoc),
            ("keyword=chợ", .cho),
            ("type=restaurant", .khac),
            ("type=clothing_store", .khac),
            ("type=pet_store", .khac)
        ]

        let nhom = DispatchGroup()
        let khoa = NSLock()
        var ketQua: [DiaDiemQuet] = []
        let viTriTam = CLLocation(latitude: tam.latitude, longitude: tam.longitude)

        for (thamSo, loaiGoiY) in dsTruyVan {
            let raw = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(loc)&radius=\(r)&\(thamSo)&language=vi&key=\(apiKey)"
            guard let encoded = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: encoded) else { continue }
            nhom.enter()
            phienMang.dataTask(with: url) { [weak self] data, _, _ in
                defer { nhom.leave() }
                guard let self = self, let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let results = json["results"] as? [[String: Any]] else { return }

                var tamDS: [DiaDiemQuet] = []
                for item in results {
                    let ten = (item["name"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !ten.isEmpty,
                          let geo = item["geometry"] as? [String: Any],
                          let l = geo["location"] as? [String: Any],
                          let la = l["lat"] as? Double,
                          let lo = l["lng"] as? Double else { continue }

                    let kc = viTriTam.distance(from: CLLocation(latitude: la, longitude: lo))
                    guard kc <= banKinhMet else { continue }
                    let diaChi = (item["vicinity"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

                    guard let loaiChuan = self.phanLoaiChinhXac(ten: ten, diaChi: diaChi, goiY: loaiGoiY, tagOSMChacChan: false) else {
                        continue
                    }

                    let pid = (item["place_id"] as? String) ?? "gg_\(Int(la * 100000))_\(Int(lo * 100000))"
                    tamDS.append(DiaDiemQuet(
                        id: pid,
                        ten: ten,
                        diaChi: diaChi,
                        loai: loaiChuan,
                        viDo: la,
                        kinhDo: lo,
                        khoangCachMet: kc,
                        nguon: "Google"
                    ))
                }
                khoa.lock()
                ketQua.append(contentsOf: tamDS)
                khoa.unlock()
            }.resume()
        }

        nhom.notify(queue: .global(qos: .userInitiated)) {
            hoanThanh(ketQua)
        }
    }

    // MARK: Phân Loại & Loại Trùng Thông Minh Cho Thị Trường Việt Nam

    private func chuanHoaChuoi(_ s: String) -> String {
        return s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "d")
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func laDanhMucAppleBiLoai(_ cat: MKPointOfInterestCategory) -> Bool {
        let danhMucLoai: Set<MKPointOfInterestCategory> = [
            .parking, .evCharger, .atm, .postOffice, .police, .fireStation,
            .beach, .campground, .marina, .publicTransport, .airport
        ]
        return danhMucLoai.contains(cat)
    }

    private func coTuNguyen(_ chuoi: String, tu: String) -> Bool {
        let pattern = "(^|[^\\p{L}\\p{N}])" + NSRegularExpression.escapedPattern(for: tu) + "($|[^\\p{L}\\p{N}])"
        return chuoi.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    private func phanLoaiChinhXac(
        ten: String,
        diaChi: String,
        goiY: LoaiDiaDiemQuet?,
        tagOSMChacChan: Bool
    ) -> LoaiDiaDiemQuet? {
        let tenGoc = ten.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let t = chuanHoaChuoi(ten)
        guard !t.isEmpty else { return nil }

        // 1. Nhận diện hệ thống Điện Máy Xanh / Thế Giới Di Động / TopZone
        let laHeThongMWG = t.contains("dien may xanh")
            || t.contains("the gioi di dong")
            || t.contains("topzone")
            || coTuNguyen(t, tu: "dmx")
            || coTuNguyen(t, tu: "tgdd")
        if laHeThongMWG {
            return .heThongMWG
        }

        // 2. Loại trừ các cơ quan hành chính / trạm ATM / bãi giữ xe không phải điểm kinh doanh
        let loaiTruPhiThuongMai = [
            "cong an", "uy ban", "ubnd", "buu dien", "bai giu xe", "chua ", "nha tho", "ben xe"
        ]
        if loaiTruPhiThuongMai.contains(where: { t.contains($0) }) || coTuNguyen(t, tu: "atm") {
            return nil
        }

        // 3. Nhóm KHÁC (Nhà hàng, quán ăn, cafe, trà sữa, shop quần áo, thời trang, thú cưng, pet shop, siêu thị mini, spa, nhà thuốc...)
        // Đặt trước Chợ & Đối thủ để KHÔNG BAO GIỜ nhầm "Thịt Chó" thành "Chợ" hay quán ăn/showroom thành "Đối thủ"
        let nhomAnUong = [
            "nha hang", "quan an", "quan nhau", "quan com", "com tam", "com ga", "com binh dan",
            "bun bo", "bun cha", "bun rieu", "bun dau", "bun thit", "pho bo", "pho ga", "mi quang",
            "hu tieu", "banh mi", "banh xeo", "banh canh", "banh cuon", "banh beo", "banh trang",
            "lau ", "nuong ", "hai san", "thit cho", "thit de", "thit trau", "vit quay", "ga ran",
            "dac san", "am thuc", "buffet", "tra sua", "ca phe", "cafe", "coffee", "bia hoi",
            "quan bia", "karaoke", "bakery", "tiem banh", "an vat", "be thui", "chao long",
            "chao vit", "chao ech", "quan oc", "oc ", "bo ne", "bo kho", "pizza", "burger",
            "kfc", "lotteria", "jollibee", "highlands", "phuc long", "trung nguyen", "quán "
        ]
        let nhomShopThoiTrangThuCung = [
            "quan ao", "thoi trang", "fashion", "boutique", "giay dep", "tui xach", "my pham",
            "cosmetic", "thu cung", "pet shop", "petshop", "pet ", "thu y", "grooming",
            "shop ", "cua hang thoi trang", "ao dai", "me va be", "do choi tre em", "nha sach",
            "hoa tuoi", "tiem vang", "salon", "cat toc", "tham my", "spa ", "massage", "nail",
            "nha thuoc", "pharmacy", "long chau", "an khang", "pharmacity", "phong kham", "nha khoa",
            "tap hoa", "bach hoa xanh", "winmart", "vinmart", "circle k", "gs25", "7-eleven",
            "coopfood", "satrafoods", "familymart", "ministop", "sieu thi mini",
            "khach san", "nha nghi", "homestay", "hotel", "motel", "resort", "bida", "billiards"
        ]
        let nhomXeCo = [
            "o to", "oto", "garage", "gara", "rua xe", "sua xe", "xe may", "xe dap",
            "phu tung", "lop xe", "vo xe", "cham soc xe", "cay xang", "tram xang",
            "petrolimex", "pvoil", "showroom", "dai ly xe", "hyundai", "toyota", "honda",
            "mazda", "vinfast", "mitsubishi", "suzuki", "yamaha", "ford ", "chevrolet",
            "mercedes", "bmw ", "kia ", "isuzu", "thaco", "mua ban xe", "noi that xe"
        ]

        let laNhomAnUong = nhomAnUong.contains(where: { t.contains($0) || tenGoc.contains($0) })
            || coTuNguyen(t, tu: "quan")
            || coTuNguyen(t, tu: "pho")
            || coTuNguyen(t, tu: "bun")
            || coTuNguyen(t, tu: "com")
            || coTuNguyen(t, tu: "bar")
            || coTuNguyen(t, tu: "pub")
        let laNhomThuongMaiKhac = nhomShopThoiTrangThuCung.contains(where: { t.contains($0) })
            || nhomXeCo.contains(where: { t.contains($0) })

        // Kiểm tra ngoại lệ: nếu rõ ràng là đối thủ điện máy/điện thoại (VD: FPT Shop, CellphoneS, Điện Máy Chợ Lớn) thì không đẩy sang Khác
        let tuKhoaDoiThuChuan = [
            "dien may", "sieu thi dien may", "nguyen kim", "mediamart", "pico", "dien may cho lon",
            "fpt shop", "cellphones", "viettel store", "hoang ha mobile", "di dong viet",
            "bach long", "phong vu", "gearvn", "hacom", "minh tuan mobile", "24hstore", "hc center",
            "dien lanh", "may lanh", "dieu hoa", "tu lanh", "may giat", "tu dong", "may nuoc nong",
            "dien co", "co dien", "may bom", "may khoan", "may han", "dung cu dien", "mo to dien",
            "dien thoai", "di dong", "smartphone", "iphone", "mobile", "laptop", "may tinh",
            "vi tinh", "tin hoc", "phu kien dien thoai", "sua chua dien thoai", "ep kinh",
            "gia dung", "do gia dung", "dien gia dung", "dien tu", "thiet bi dien", "do dien",
            "may loc nuoc", "bep tu", "bep dien", "quat dien", "noi com", "tivi", "am thanh",
            "lock&lock", "elmich", "sunhouse", "kangaroo", "karofi", "daikin", "panasonic",
            "samsung", "toshiba", "sharp", "aqua", "casper", "nagakawa", "midea", "electrolux",
            "sony", "lg electronics", "bosch"
        ]
        if tuKhoaDoiThuChuan.contains(where: { t.contains($0) }) {
            return .doiThu
        }

        if laNhomAnUong || laNhomThuongMaiKhac {
            return .khac
        }

        // 4. Nhận diện CHỢ (giữ dấu tiếng Việt "chợ" hoặc tag marketplace OSM)
        let laDienMayChoLon = t.contains("dien may cho lon") || t.contains("sieu thi dien may")
        if !laDienMayChoLon {
            let laChoCoDau = coTuNguyen(tenGoc, tu: "chợ")
            let laMarketOSM = (tagOSMChacChan && goiY == .cho)
            if laChoCoDau || laMarketOSM {
                if !t.contains("dien may") && !t.contains("sieu thi") && !t.contains("mini") {
                    return .cho
                }
            }
        }

        // 5. Nhận diện TRƯỜNG HỌC
        let tuKhoaTruong = [
            "truong ", "tieu hoc", "thcs", "thpt", "mam non", "mau giao", "nha tre",
            "dai hoc", "cao dang", "trung cap", "hoc vien", "school", "kindergarten",
            "university", "college", "academy", "anh ngu", "ngoai ngu"
        ]
        if tuKhoaTruong.contains(where: { t.contains($0) }) || (tagOSMChacChan && goiY == .truongHoc) {
            return .truongHoc
        }

        // 6. Fallback chuẩn theo tag OSM hoặc truy vấn nhóm Khác
        if tagOSMChacChan && goiY == .doiThu {
            return .doiThu
        }
        if goiY == .khac {
            return .khac
        }

        return nil
    }

    private func hopNhatVaLoaiTrungNhieuTam(
        _ danhSach: [DiaDiemQuet],
        cacTam: [CLLocationCoordinate2D],
        banKinhMet: Double
    ) -> [DiaDiemQuet] {
        let dsLocTam = cacTam.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }

        func khoangCachNhoNhatDenCacTam(_ item: DiaDiemQuet) -> Double {
            let loc = CLLocation(latitude: item.viDo, longitude: item.kinhDo)
            return dsLocTam.map { $0.distance(from: loc) }.min() ?? item.khoangCachMet
        }

        func uuTienNguon(_ n: String) -> Int {
            switch n {
            case "Google": return 3
            case "Apple": return 2
            default: return 1
            }
        }

        let chuanHoaKC: [DiaDiemQuet] = danhSach.compactMap { item in
            let kcMin = khoangCachNhoNhatDenCacTam(item)
            guard kcMin <= banKinhMet else { return nil }
            return DiaDiemQuet(
                id: item.id,
                ten: item.ten,
                diaChi: item.diaChi,
                loai: item.loai,
                viDo: item.viDo,
                kinhDo: item.kinhDo,
                khoangCachMet: kcMin,
                nguon: item.nguon
            )
        }

        let sapXep = chuanHoaKC.sorted { a, b in
            if uuTienNguon(a.nguon) != uuTienNguon(b.nguon) {
                return uuTienNguon(a.nguon) > uuTienNguon(b.nguon)
            }
            return a.khoangCachMet < b.khoangCachMet
        }

        var ketQua: [DiaDiemQuet] = []
        for item in sapXep {
            let tenChuan = chuanHoaChuoi(item.ten)
            let locItem = CLLocation(latitude: item.viDo, longitude: item.kinhDo)

            let biTrung = ketQua.contains { daCo in
                guard daCo.loai == item.loai else { return false }
                let kc = locItem.distance(from: CLLocation(latitude: daCo.viDo, longitude: daCo.kinhDo))
                if kc < 55 { return true }
                let tenDaCo = chuanHoaChuoi(daCo.ten)
                if kc < 180 && (tenChuan == tenDaCo || tenChuan.contains(tenDaCo) || tenDaCo.contains(tenChuan)) {
                    return true
                }
                return false
            }

            if !biTrung {
                ketQua.append(item)
            }
        }

        return ketQua.sorted { $0.khoangCachMet < $1.khoangCachMet }
    }
}

// MARK: - Bộ Tối Ưu Tuyến Đường Phát Tờ Rơi Hiệu Quả Nhất (TSP + 2-opt + OSRM Road Routing)

private final class BoToiUuTuyenPhatToRoi {
    static let dungChung = BoToiUuTuyenPhatToRoi()
    private init() {}

    private let phienMang: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 10
        cfg.timeoutIntervalForResource = 15
        return URLSession(configuration: cfg)
    }()

    func tinhTuyenHieuQuaNhat(
        tam: CLLocationCoordinate2D,
        tenDiemXuatPhat: String = "Siêu thị (Tâm quét)",
        danhSach: [DiaDiemQuet],
        banKinhMet: Double = 2000,
        hoanThanh: @escaping (KetQuaTuyenPhatToRoi?) -> Void
    ) {
        // Ưu tiên Chợ, Trường học và Đối thủ trong đúng bán kính phát tờ rơi (nếu trống mới mở rộng sang điểm Khác)
        let trongBanKinh = danhSach.filter { $0.khoangCachMet <= banKinhMet + 25.0 }
        let dsUuTien = trongBanKinh.filter { $0.loai == .cho || $0.loai == .truongHoc || $0.loai == .doiThu }
        let dsPhatToRoi = !dsUuTien.isEmpty ? dsUuTien : trongBanKinh.filter { $0.loai != .heThongMWG }
        guard !dsPhatToRoi.isEmpty else {
            DispatchQueue.main.async { hoanThanh(nil) }
            return
        }

        let viTriAll = dsPhatToRoi.map { CLLocation(latitude: $0.viDo, longitude: $0.kinhDo) }
        var diemSo: [(DiaDiemQuet, Double)] = []
        for (i, item) in dsPhatToRoi.enumerated() {
            var score = item.loai.diemUuTienToRoi
            var lanCan = 0
            for (j, otherLoc) in viTriAll.enumerated() where i != j {
                if viTriAll[i].distance(from: otherLoc) <= 300 {
                    lanCan += 1
                }
            }
            score += Double(min(lanCan, 6)) * 1.4
            score += max(0, 2.0 - item.khoangCachMet / 1500.0)
            diemSo.append((item, score))
        }

        // Trải đều điểm dừng khắp cả 4 hướng & vươn rộng ra toàn bộ bán kính quét (không bị bó hẹp quanh tâm!)
        let kcToiThieu = max(180.0, banKinhMet * 0.14)
        let sapXepDiem = diemSo.sorted { $0.1 > $1.1 }

        // Chia 4 góc phần tư so với tâm và chọn cân bằng từng hướng (mỗi hướng tối đa 3 điểm: cả vòng trong & vòng ngoài)
        var nhomGoc: [[DiaDiemQuet]] = [[], [], [], []]
        for (uv, _) in sapXepDiem {
            let dLat = uv.viDo - tam.latitude
            let dLon = uv.kinhDo - tam.longitude
            let g: Int
            if dLat >= 0 && dLon >= 0 { g = 0 }
            else if dLat < 0 && dLon >= 0 { g = 1 }
            else if dLat < 0 && dLon < 0 { g = 2 }
            else { g = 3 }
            nhomGoc[g].append(uv)
        }

        var daChon: [DiaDiemQuet] = []
        func thuThemDiem(_ uv: DiaDiemQuet, minDist: Double) -> Bool {
            let locUV = CLLocation(latitude: uv.viDo, longitude: uv.kinhDo)
            let quaGan = daChon.contains {
                locUV.distance(from: CLLocation(latitude: $0.viDo, longitude: $0.kinhDo)) < minDist
            }
            if !quaGan {
                daChon.append(uv)
                return true
            }
            return false
        }

        // Vòng 1: Lấy 1 điểm xa/vòng ngoài (>= 45% bán kính) ở mỗi hướng để mở rộng phạm vi phủ đều toàn vòng tròn
        for g in 0..<4 {
            if let xa = nhomGoc[g].first(where: { $0.khoangCachMet >= banKinhMet * 0.45 }) {
                _ = thuThemDiem(xa, minDist: kcToiThieu)
            }
        }
        // Vòng 2: Bổ sung đều từng hướng cho đủ tối đa 11 điểm nóng
        var vong = 0
        while daChon.count < 11 && vong < 8 {
            var coThem = false
            for g in 0..<4 {
                if daChon.count >= 11 { break }
                for uv in nhomGoc[g] {
                    if daChon.contains(where: { $0.id == uv.id }) { continue }
                    if thuThemDiem(uv, minDist: kcToiThieu) {
                        coThem = true
                        break
                    }
                }
            }
            if !coThem { break }
            vong += 1
        }
        // Nếu vẫn ít hơn 6 điểm do mật độ thưa, nới khoảng cách tối thiểu xuống 120m
        if daChon.count < 6 {
            for (uv, _) in sapXepDiem where !daChon.contains(where: { $0.id == uv.id }) {
                if daChon.count >= 11 { break }
                _ = thuThemDiem(uv, minDist: 120)
            }
        }
        if daChon.isEmpty, let dau = dsPhatToRoi.first {
            daChon = [dau]
        }

        let thuTuToiUu = toiUuThuTuTSP(xuatPhat: tam, cacDiem: daChon)
        var diemCoSoThuTu: [DiaDiemQuet] = []
        for (idx, var d) in thuTuToiUu.enumerated() {
            d.soThuTuTuyen = idx + 1
            diemCoSoThuTu.append(d)
        }

        var kcTungChang: [Double] = []
        var diemTruoc = CLLocation(latitude: tam.latitude, longitude: tam.longitude)
        var tongThang: Double = 0
        for d in diemCoSoThuTu {
            let loc = CLLocation(latitude: d.viDo, longitude: d.kinhDo)
            let seg = diemTruoc.distance(from: loc)
            kcTungChang.append(seg)
            tongThang += seg
            diemTruoc = loc
        }

        var chuoiToaDo: [String] = [String(format: "%.6f,%.6f", tam.longitude, tam.latitude)]
        for d in diemCoSoThuTu {
            chuoiToaDo.append(String(format: "%.6f,%.6f", d.kinhDo, d.viDo))
        }
        let urlStr = "https://router.project-osrm.org/route/v1/driving/\(chuoiToaDo.joined(separator: ";"))?overview=full&geometries=geojson&steps=true"

        guard let url = URL(string: urlStr) else {
            let duPhong = taoKetQuaDuPhong(tam: tam, tenDiemXuatPhat: tenDiemXuatPhat, diem: diemCoSoThuTu, kcChang: kcTungChang, tongThang: tongThang)
            DispatchQueue.main.async { hoanThanh(duPhong) }
            return
        }

        var req = URLRequest(url: url)
        req.setValue("DMX-V2-iOS/1.0", forHTTPHeaderField: "User-Agent")

        phienMang.dataTask(with: req) { [weak self] data, resp, err in
            guard let self = self else { return }
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            if err == nil, code == 200, let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let routes = json["routes"] as? [[String: Any]],
               let firstRoute = routes.first,
               let geom = firstRoute["geometry"] as? [String: Any],
               let coords = geom["coordinates"] as? [[Double]],
               coords.count >= 2 {

                let polyCoords = coords.compactMap { pair -> CLLocationCoordinate2D? in
                    guard pair.count >= 2 else { return nil }
                    return CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0])
                }
                let dist = (firstRoute["distance"] as? Double) ?? (tongThang * 1.3)
                let durSec = firstRoute["duration"] as? Double
                var legDists = kcTungChang
                let legs = (firstRoute["legs"] as? [[String: Any]]) ?? []
                if legs.count == diemCoSoThuTu.count {
                    legDists = legs.map { ($0["distance"] as? Double) ?? 0 }
                }

                let dsDiemMucTieu = diemCoSoThuTu.map {
                    DiemMucTieuTuyen(id: $0.id, ten: $0.ten, diaChi: $0.diaChi, loaiRaw: $0.loai.tieuDe, viDo: $0.viDo, kinhDo: $0.kinhDo)
                }
                let chiDan = BoDanDuongTuyenThucTe.xayDungChiDanTuOSRM(
                    legs: legs,
                    tenDiemXuatPhat: tenDiemXuatPhat,
                    cacDiemDung: dsDiemMucTieu
                )
                let phutXeMay = BoDanDuongTuyenThucTe.tinhThoiGianXeMayPhut(quangDuongMet: dist, durationOSRMGiay: durSec)
                let phutDiBo = BoDanDuongTuyenThucTe.tinhThoiGianDiBoPhut(quangDuongMet: dist)
                let ketQua = KetQuaTuyenPhatToRoi(
                    cacDiemDung: diemCoSoThuTu,
                    toaDoDuongDi: polyCoords,
                    tongQuangDuongMet: dist,
                    thoiGianPhut: phutXeMay,
                    laDuongThucTe: true,
                    khoangCachTungChangMet: legDists,
                    chiDanTungBuoc: chiDan,
                    thoiGianXeMayPhut: phutXeMay,
                    thoiGianDiBoPhut: phutDiBo
                )
                DispatchQueue.main.async { hoanThanh(ketQua) }
            } else {
                let duPhong = self.taoKetQuaDuPhong(tam: tam, tenDiemXuatPhat: tenDiemXuatPhat, diem: diemCoSoThuTu, kcChang: kcTungChang, tongThang: tongThang)
                DispatchQueue.main.async { hoanThanh(duPhong) }
            }
        }.resume()
    }

    private func taoKetQuaDuPhong(
        tam: CLLocationCoordinate2D,
        tenDiemXuatPhat: String,
        diem: [DiaDiemQuet],
        kcChang: [Double],
        tongThang: Double
    ) -> KetQuaTuyenPhatToRoi {
        var coords = [tam]
        coords.append(contentsOf: diem.map { $0.toaDo })
        let uocLuongMet = tongThang * 1.32
        let phutXM = BoDanDuongTuyenThucTe.tinhThoiGianXeMayPhut(quangDuongMet: uocLuongMet)
        let phutDB = BoDanDuongTuyenThucTe.tinhThoiGianDiBoPhut(quangDuongMet: uocLuongMet)
        var buoc: [BuocChiDanTuyen] = [
            BuocChiDanTuyen(stt: 1, hanhDong: "🚩 Xuất phát", noiDung: "Bắt đầu từ \(tenDiemXuatPhat)", khoangCachMet: 0, laDiemDung: false)
        ]
        for (i, d) in diem.enumerated() {
            let seg = i < kcChang.count ? kcChang[i] * 1.32 : d.khoangCachMet
            buoc.append(BuocChiDanTuyen(
                stt: buoc.count + 1,
                hanhDong: "📍 Điểm #\(i + 1)",
                noiDung: "Đến \(d.ten) (\(d.loai.tieuDe)) • ước lượng \(BoDanDuongTuyenThucTe.dinhDangKhoangCach(seg))",
                khoangCachMet: seg,
                laDiemDung: true
            ))
        }
        return KetQuaTuyenPhatToRoi(
            cacDiemDung: diem,
            toaDoDuongDi: coords,
            tongQuangDuongMet: uocLuongMet,
            thoiGianPhut: phutXM,
            laDuongThucTe: false,
            khoangCachTungChangMet: kcChang.map { $0 * 1.32 },
            chiDanTungBuoc: buoc,
            thoiGianXeMayPhut: phutXM,
            thoiGianDiBoPhut: phutDB
        )
    }

    private func khoangCach(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }

    private func toiUuThuTuTSP(xuatPhat: CLLocationCoordinate2D, cacDiem: [DiaDiemQuet]) -> [DiaDiemQuet] {
        guard cacDiem.count > 1 else { return cacDiem }
        var conLai = cacDiem
        var loTrinh: [DiaDiemQuet] = []
        var hienTai = xuatPhat

        while !conLai.isEmpty {
            var chiSoTotNhat = 0
            var kcNhoNhat = Double.greatestFiniteMagnitude
            for (idx, d) in conLai.enumerated() {
                let kc = khoangCach(hienTai, d.toaDo)
                if kc < kcNhoNhat {
                    kcNhoNhat = kc
                    chiSoTotNhat = idx
                }
            }
            let chon = conLai.remove(at: chiSoTotNhat)
            loTrinh.append(chon)
            hienTai = chon.toaDo
        }

        func tongChieuDai(_ arr: [DiaDiemQuet]) -> Double {
            guard !arr.isEmpty else { return 0 }
            var sum = khoangCach(xuatPhat, arr[0].toaDo)
            for i in 0..<(arr.count - 1) {
                sum += khoangCach(arr[i].toaDo, arr[i + 1].toaDo)
            }
            return sum
        }

        var caiThien = true
        var vong = 0
        while caiThien && vong < 30 {
            caiThien = false
            vong += 1
            let n = loTrinh.count
            guard n >= 3 else { break }
            var bestLen = tongChieuDai(loTrinh)
            for i in 0..<(n - 1) {
                for j in (i + 1)..<n {
                    var thu = loTrinh
                    thu[i...j].reverse()
                    let len = tongChieuDai(thu)
                    if len + 1.0 < bestLen {
                        loTrinh = thu
                        bestLen = len
                        caiThien = true
                    }
                }
            }
        }

        return loTrinh
    }
}

// MARK: - Màn Hình Chính Tích Hợp Google Maps & Quét Bán Kính

final class ManHinhBanDoKhuVuc: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate {

    private enum KieuNenBanDo: Int {
        case googleDuongPho = 0
        case googleVeTinh = 1
        case appleMap = 2
    }

    private static let khoaViDoLuu = "dmx_bando_tam_lat_v1"
    private static let khoaKinhDoLuu = "dmx_bando_tam_lon_v1"
    private static let khoaBanKinhLuu = "dmx_bando_bankinh_v1"

    // Trạng thái dữ liệu
    private let quanLyViTri = CLLocationManager()
    private var tamQuet: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 16.0544, longitude: 108.2022)
    private var tenTamQuet: String = "Tâm quét (Siêu thị)"
    private var banKinhMet: Double = 2000
    private var kieuNenBanDo: KieuNenBanDo = .googleDuongPho
    private var hienTuyenToRoi: Bool = true
    private var dangPhongToBanDo: Bool = false
    private var dangQuet: Bool = false

    private var dsSieuThiDaLuu: [DiaDiemSieuThiLuu] = []
    private var tatCaDiaDiem: [DiaDiemQuet] = []
    private var ketQuaTuyen: KetQuaTuyenPhatToRoi? = nil
    private var thoiGianQuetGanNhat: String = ""
    private var nguonQuetGanNhat: [String] = []
    private var thongBaoQuetLuu: String = ""
    private var phienDanDuongID: Int = 0
    private var lopTileGoogle: MKTileOverlay?

    // Giao diện chính
    private let cuonChinh = UIScrollView()
    private let nganChinh = UIStackView()

    // Khối điều khiển tìm kiếm, siêu thị đã lưu & bán kính
    private let oTimDiaChi = UITextField()
    private let nutTimDiaChi = UIButton(type: .system)
    private let nutViTriToi = UIButton(type: .system)
    private let nutLuuSieuThi = UIButton(type: .system)
    private let cuonSieuThiDaLuu = UIScrollView()
    private let nganSieuThiDaLuu = UIStackView()
    private let nhanGoiYSieuThi = UILabel()
    private let oNhapBanKinh = UITextField()
    private let nutQuetKhuVuc = UIButton(type: .system)
    private let vongQuayQuet = UIActivityIndicatorView(style: .medium)
    private let nhanTrangThaiQuet = UILabel()
    private let nutCauHinhGoogleKey = UIButton(type: .system)
    private var cacNutBanKinhNhanh: [UIButton] = []

    // Khối Bản đồ
    private let khungBanDo = UIView()
    private var rangBuocChieuCaoBanDo: NSLayoutConstraint?
    private let banDo = MKMapView()
    private let chonKieuBanDo = UISegmentedControl(items: ["GG Bản đồ", "GG Vệ tinh", "Apple"])
    private let nutCheDoTrangThaiPhat = UIButton(type: .system)
    private let nutBatTatTuyen = UIButton(type: .system)
    private let nutPhongToBanDo = UIButton(type: .system)
    private let nhanGoiYBanDo = UILabel()
    private var cheDoTrangThaiPhat: Bool = false

    // Dữ liệu check-in đồng bộ từ PWA (Google Sheet BC-Phát tờ rơi)
    private var dsCheckInPWA: [BanGhiCheckInPWA] = KhoCheckInPWADongBo.dungChung.taiDanhSachLuu()
    private var dangDongBoPWA: Bool = false

    // Khối xem nhanh lộ trình tuyến đang chọn (ẩn khi đã gộp gọn vào khung tuyến chính)
    private let khungChiTietTuyenChon = UIView()
    private let nhanTieuDeTuyenChon = UILabel()
    private let nhanNoiDungTuyenChon = UILabel()
    private let nutXemChiTietLoTrinh = UIButton(type: .system)
    private let nutMoGGMapsTuyenChon = UIButton(type: .system)

    // 6 thẻ thống kê KPI 1 dòng duy nhất dưới bản đồ (bấm vào ô bất kỳ mở popup bảng chi tiết + xuất ảnh)
    private let nhanSoTatCa = UILabel()
    private let nhanSoDoiThu = UILabel()
    private let nhanSoMWG = UILabel()
    private let nhanSoTruongHoc = UILabel()
    private let nhanSoCho = UILabel()
    private let nhanSoKhac = UILabel()

    // Thẻ Chọn tuyến & Xem chỉ dẫn rẽ trái/phải (đã bỏ danh sách 1, 2, 3, 4...)
    private let khungTuyenToRoi = UIView()
    private let nhanTieuDeKhungTuyen = UILabel()
    private let cuonChonTuyenChiDan = UIScrollView()
    private let nganChonTuyenChiDan = UIStackView()
    private let nhanTomTatTuyen = UILabel()
    private let nhanKhungGioVang = UILabel()
    private let nutChiDanTuyenToiUu = UIButton(type: .system)
    private let nutMoGoogleMapsTuyen = UIButton(type: .system)
    private let nutCopyKeHoach = UIButton(type: .system)

    // Trạng thái & giao diện Ma trận phát tờ rơi xoay vòng + 1 Link Google Trang tính (PG & NV) + Kiểm soát PWA
    private var danhSachKhoiPG: [KhoiLichTuanExcel] = []
    private var khoiLichPG: KhoiLichTuanExcel? = nil
    private var khoiLichNV: KhoiLichTuanExcel? = nil
    private var keHoachMaTran: KeHoachMaTranTuan? = nil
    private var cauHinhPhanTuyen: CauHinhPhanTuyenToRoi = KhoMaTranPhatToRoi.dungChung.taiCauHinhPhanTuyen()

    private let khungMaTranToRoi = UIView()
    private let nutNhacChuNhat = UIButton(type: .system)
    private let nhanNhacTuyenChuaPhat = UILabel()
    private let oLinkTrangTinh = UITextField()
    private let nutDanLinkTrangTinh = UIButton(type: .system)
    private let nutTaiTrangTinh = UIButton(type: .system)
    private let vongQuayTrangTinh = UIActivityIndicatorView(style: .medium)
    private let nutChonTuanPG = UIButton(type: .system)
    private let nutChonSoPG = UIButton(type: .system)
    private let nutChonSoNV = UIButton(type: .system)
    private let nutChonSoTuyen = UIButton(type: .system)
    private let nutChonBanKinhToRoi = UIButton(type: .system)
    private let nhanTomTatChiaTuyen = UILabel()
    private let nhanTrangThaiExcel = UILabel()
    private let nutTaoMaTran = UIButton(type: .system)
    private let nutCopyMaTran = UIButton(type: .system)
    private let nutXemLichCa = UIButton(type: .system)
    private let nutSoXoayTuaThang = UIButton(type: .system)
    private let nutKiemSoatTuan = UIButton(type: .system)
    private let nutPWACheckIn = UIButton(type: .system)
    private let nutDongBoPWA = UIButton(type: .system)
    private let nutLocNhanSuMaTran = UIButton(type: .system)
    private let khungLichNhanSuChon = UIView()
    private let nganLichNhanSuChon = UIStackView()
    private var tenNhanSuDangLoc: String? = nil
    private var tuyenDangLocTrenBanDo: String? = nil
    private let cuonChuThichTuyen = UIScrollView()
    private let nganChuThichTuyen = UIStackView()
    private let chonLocMaTran = UISegmentedControl(items: ["Tất cả", "Chưa phát", "Đã phát"])
    private let nganDanhSachMaTran = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BangMauBCTD.nenTrang
        khoiPhucTrangThaiDaLuu()
        cauHinhViTri()
        taoGiaoDien()
        apDungLopNenBanDo()
        dungLaiThanhSieuThiDaLuu()
        capNhatThongKeKPI()
        if !thongBaoQuetLuu.isEmpty {
            nhanTrangThaiQuet.text = thongBaoQuetLuu
        }
        capNhatNutCheDoTrangThaiPhat()
        capNhatTamVaVongTronTrenBanDo(diChuyenCamera: true)
        capNhatKhungTuyenPhatToRoi()
        capNhatGiaoDienMaTran()
        // Nếu các tuyến đã lưu chưa bám đường thực tế, tự động đồng bộ nền
        if let kh = keHoachMaTran, kh.cacTuyen.contains(where: { !$0.laDuongThucTe && $0.cacToaDo.count >= 2 }) {
            dongBoDuongThucTeChoCacTuyen()
        }
        dongBoCheckInTuPWA(imLang: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dongBoCheckInTuPWA(imLang: true)
    }

    private func khoiPhucTrangThaiDaLuu() {
        let ud = UserDefaults.standard
        if ud.object(forKey: Self.khoaViDoLuu) != nil, ud.object(forKey: Self.khoaKinhDoLuu) != nil {
            let lat = ud.double(forKey: Self.khoaViDoLuu)
            let lon = ud.double(forKey: Self.khoaKinhDoLuu)
            if abs(lat) > 0.01 && abs(lon) > 0.01 {
                tamQuet = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
        }
        let bk = ud.double(forKey: Self.khoaBanKinhLuu)
        if bk >= 100 && bk <= 20000 {
            banKinhMet = bk
        }
        dsSieuThiDaLuu = KhoDiaDiemSieuThi.dungChung.taiDanhSach()
        danhSachKhoiPG = KhoMaTranPhatToRoi.dungChung.taiDanhSachKhoiPG()
        khoiLichPG = KhoMaTranPhatToRoi.dungChung.taiKhoiPG()
        khoiLichNV = KhoMaTranPhatToRoi.dungChung.taiKhoiNV()
        keHoachMaTran = KhoMaTranPhatToRoi.dungChung.taiKeHoach()
        cauHinhPhanTuyen = KhoMaTranPhatToRoi.dungChung.taiCauHinhPhanTuyen()

        // Khôi phục toàn bộ kết quả quét khu vực lần trước (giữ nguyên cho đến khi quét lại!)
        if let banLuu = KhoKetQuaQuetKhuVuc.dungChung.taiKetQuaDaLuu() {
            tatCaDiaDiem = banLuu.tatCaDiaDiem
            if banLuu.banKinhQuetMet >= 100 && banLuu.banKinhQuetMet <= 20000 {
                banKinhMet = banLuu.banKinhQuetMet
            }
            if !banLuu.tenTamQuet.isEmpty {
                tenTamQuet = banLuu.tenTamQuet
            }
            if abs(banLuu.tamLat) > 0.01 && abs(banLuu.tamLon) > 0.01 {
                tamQuet = CLLocationCoordinate2D(latitude: banLuu.tamLat, longitude: banLuu.tamLon)
            }
            nguonQuetGanNhat = banLuu.nguonQuet
            thoiGianQuetGanNhat = banLuu.thoiGianQuet
            thongBaoQuetLuu = banLuu.thongBaoTrangThai
            if let tuyenLuu = banLuu.ketQuaTuyen {
                ketQuaTuyen = KetQuaTuyenPhatToRoi.tuBanLuu(tuyenLuu)
            }
        }
    }

    private func luuTrangThaiTamVaBanKinh() {
        let ud = UserDefaults.standard
        ud.set(tamQuet.latitude, forKey: Self.khoaViDoLuu)
        ud.set(tamQuet.longitude, forKey: Self.khoaKinhDoLuu)
        ud.set(banKinhMet, forKey: Self.khoaBanKinhLuu)
    }

    private func tenXuatPhatHienTai() -> String {
        let chon = danhSachTamDangChonDeQuet()
        if let dau = chon.first, !dau.ten.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return dau.ten
        }
        return tenTamQuet.isEmpty ? "Siêu thị (Tâm quét)" : tenTamQuet
    }

    private func cauHinhViTri() {
        quanLyViTri.delegate = self
        quanLyViTri.desiredAccuracy = kCLLocationAccuracyBest
        // Chỉ tự lấy GPS lúc mở lần đầu khi chưa có dữ liệu quét hay tâm đã lưu (không ghi đè khu vực đã quét)
        let daCoTamHoacDuLieu = !tatCaDiaDiem.isEmpty || UserDefaults.standard.object(forKey: Self.khoaViDoLuu) != nil
        if !daCoTamHoacDuLieu && (quanLyViTri.authorizationStatus == .authorizedWhenInUse || quanLyViTri.authorizationStatus == .authorizedAlways) {
            quanLyViTri.requestLocation()
        }
    }

    private func danhSachTamDangChonDeQuet() -> [(ten: String, toaDo: CLLocationCoordinate2D, laSieuThiLuu: Bool)] {
        let daChon = dsSieuThiDaLuu.filter { $0.dangChon }
        if !daChon.isEmpty {
            return daChon.map { ($0.ten, $0.toaDo, true) }
        }
        return [(tenTamQuet, tamQuet, false)]
    }

    // MARK: - Dựng Giao Diện

    private func taoGiaoDien() {
        cuonChinh.alwaysBounceVertical = true
        cuonChinh.keyboardDismissMode = .onDrag
        cuonChinh.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cuonChinh)

        nganChinh.axis = .vertical
        nganChinh.spacing = 12
        nganChinh.translatesAutoresizingMaskIntoConstraints = false
        cuonChinh.addSubview(nganChinh)

        NSLayoutConstraint.activate([
            cuonChinh.topAnchor.constraint(equalTo: view.topAnchor),
            cuonChinh.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cuonChinh.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cuonChinh.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            nganChinh.topAnchor.constraint(equalTo: cuonChinh.contentLayoutGuide.topAnchor, constant: 10),
            nganChinh.leadingAnchor.constraint(equalTo: cuonChinh.contentLayoutGuide.leadingAnchor, constant: 10),
            nganChinh.trailingAnchor.constraint(equalTo: cuonChinh.contentLayoutGuide.trailingAnchor, constant: -10),
            nganChinh.bottomAnchor.constraint(equalTo: cuonChinh.contentLayoutGuide.bottomAnchor, constant: -24),
            nganChinh.widthAnchor.constraint(equalTo: cuonChinh.frameLayoutGuide.widthAnchor, constant: -20)
        ])

        nganChinh.addArrangedSubview(taoTheDieuKhienQuet())
        nganChinh.addArrangedSubview(taoTheBanDo())
        nganChinh.addArrangedSubview(taoThanhChuThichTuyenBanDo())
        nganChinh.addArrangedSubview(taoKhungChiTietTuyenDangChon())
        nganChinh.addArrangedSubview(taoKhungThongKeKPI())
        nganChinh.addArrangedSubview(taoTheTuyenPhatToRoi())
        nganChinh.addArrangedSubview(taoTheMaTranPhatToRoi())

        let tapAnBanPhim = UITapGestureRecognizer(target: self, action: #selector(anBanPhim))
        tapAnBanPhim.cancelsTouchesInView = false
        view.addGestureRecognizer(tapAnBanPhim)
    }

    private func taoKhungThe() -> UIView {
        let v = UIView()
        v.backgroundColor = BangMauBCTD.nenThe
        v.layer.cornerRadius = 14
        v.layer.borderWidth = 1
        v.layer.borderColor = BangMauBCTD.vienThe.cgColor
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.04
        v.layer.shadowRadius = 6
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private func taoTheDieuKhienQuet() -> UIView {
        let the = taoKhungThe()

        let tieuDe = UILabel()
        tieuDe.text = "QUÉT KHU VỰC & PHÁT TỜ RƠI (GOOGLE MAPS)"
        tieuDe.font = .systemFont(ofSize: 12.5, weight: .heavy)
        tieuDe.textColor = BangMauBCTD.xanhChuDaoDam

        nutCauHinhGoogleKey.setTitle("🔑 Key GG", for: .normal)
        nutCauHinhGoogleKey.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutCauHinhGoogleKey.setTitleColor(BangMauBCTD.chuPhu, for: .normal)
        nutCauHinhGoogleKey.backgroundColor = BangMauBCTD.nenHeaderPhu
        nutCauHinhGoogleKey.layer.cornerRadius = 7
        nutCauHinhGoogleKey.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        nutCauHinhGoogleKey.setContentHuggingPriority(.required, for: .horizontal)
        nutCauHinhGoogleKey.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutCauHinhGoogleKey.addTarget(self, action: #selector(bamCaiDatGoogleKey), for: .touchUpInside)

        let hangTieuDe = UIStackView(arrangedSubviews: [tieuDe, UIView(), nutCauHinhGoogleKey])
        hangTieuDe.axis = .horizontal
        hangTieuDe.alignment = .center

        // Hàng 1: Tìm địa chỉ / Siêu thị + Nút Tìm (cố định chiều rộng không bị bóp) + GPS
        oTimDiaChi.placeholder = "Tìm siêu thị ĐMX hoặc nhập địa chỉ..."
        oTimDiaChi.font = .systemFont(ofSize: 13.5, weight: .medium)
        oTimDiaChi.textColor = BangMauBCTD.chuChinh
        oTimDiaChi.backgroundColor = BangMauBCTD.nenThePhu
        oTimDiaChi.layer.cornerRadius = 9
        oTimDiaChi.layer.borderWidth = 1
        oTimDiaChi.layer.borderColor = BangMauBCTD.vienDam.cgColor
        oTimDiaChi.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        oTimDiaChi.leftViewMode = .always
        oTimDiaChi.clearButtonMode = .whileEditing
        oTimDiaChi.returnKeyType = .search
        oTimDiaChi.delegate = self
        oTimDiaChi.setContentHuggingPriority(.defaultLow, for: .horizontal)
        oTimDiaChi.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        oTimDiaChi.heightAnchor.constraint(equalToConstant: 38).isActive = true

        nutTimDiaChi.setTitle("Tìm", for: .normal)
        nutTimDiaChi.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        nutTimDiaChi.setTitleColor(.white, for: .normal)
        nutTimDiaChi.backgroundColor = BangMauBCTD.xanhBienChuDao
        nutTimDiaChi.layer.cornerRadius = 9
        nutTimDiaChi.widthAnchor.constraint(equalToConstant: 56).isActive = true
        nutTimDiaChi.heightAnchor.constraint(equalToConstant: 38).isActive = true
        nutTimDiaChi.setContentHuggingPriority(.required, for: .horizontal)
        nutTimDiaChi.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutTimDiaChi.addTarget(self, action: #selector(bamTimDiaChi), for: .touchUpInside)

        let cfgGPS = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        nutViTriToi.setImage(UIImage(systemName: "location.fill", withConfiguration: cfgGPS), for: .normal)
        nutViTriToi.tintColor = BangMauBCTD.xanhChuDao
        nutViTriToi.backgroundColor = BangMauBCTD.nenHeaderPhu
        nutViTriToi.layer.cornerRadius = 9
        nutViTriToi.layer.borderWidth = 1
        nutViTriToi.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
        nutViTriToi.widthAnchor.constraint(equalToConstant: 38).isActive = true
        nutViTriToi.heightAnchor.constraint(equalToConstant: 38).isActive = true
        nutViTriToi.setContentHuggingPriority(.required, for: .horizontal)
        nutViTriToi.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutViTriToi.addTarget(self, action: #selector(bamLayViTriHienTai), for: .touchUpInside)

        let hangTim = UIStackView(arrangedSubviews: [oTimDiaChi, nutTimDiaChi, nutViTriToi])
        hangTim.axis = .horizontal
        hangTim.spacing = 6
        hangTim.alignment = .center

        // Hàng 2: Chọn & lưu nhiều vị trí siêu thị của mình
        nutLuuSieuThi.setTitle("＋ Lưu siêu thị", for: .normal)
        nutLuuSieuThi.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        nutLuuSieuThi.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
        nutLuuSieuThi.backgroundColor = BangMauBCTD.vangSang
        nutLuuSieuThi.layer.cornerRadius = 8
        nutLuuSieuThi.layer.borderWidth = 1
        nutLuuSieuThi.layer.borderColor = BangMauBCTD.vangChuDao.cgColor
        nutLuuSieuThi.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        nutLuuSieuThi.heightAnchor.constraint(equalToConstant: 32).isActive = true
        nutLuuSieuThi.setContentHuggingPriority(.required, for: .horizontal)
        nutLuuSieuThi.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutLuuSieuThi.addTarget(self, action: #selector(bamLuuViTriSieuThi), for: .touchUpInside)

        cuonSieuThiDaLuu.showsHorizontalScrollIndicator = false
        cuonSieuThiDaLuu.translatesAutoresizingMaskIntoConstraints = false
        cuonSieuThiDaLuu.heightAnchor.constraint(equalToConstant: 32).isActive = true

        nganSieuThiDaLuu.axis = .horizontal
        nganSieuThiDaLuu.spacing = 6
        nganSieuThiDaLuu.alignment = .center
        nganSieuThiDaLuu.translatesAutoresizingMaskIntoConstraints = false
        cuonSieuThiDaLuu.addSubview(nganSieuThiDaLuu)

        NSLayoutConstraint.activate([
            nganSieuThiDaLuu.topAnchor.constraint(equalTo: cuonSieuThiDaLuu.contentLayoutGuide.topAnchor),
            nganSieuThiDaLuu.bottomAnchor.constraint(equalTo: cuonSieuThiDaLuu.contentLayoutGuide.bottomAnchor),
            nganSieuThiDaLuu.leadingAnchor.constraint(equalTo: cuonSieuThiDaLuu.contentLayoutGuide.leadingAnchor),
            nganSieuThiDaLuu.trailingAnchor.constraint(equalTo: cuonSieuThiDaLuu.contentLayoutGuide.trailingAnchor),
            nganSieuThiDaLuu.heightAnchor.constraint(equalTo: cuonSieuThiDaLuu.frameLayoutGuide.heightAnchor)
        ])

        let hangSieuThi = UIStackView(arrangedSubviews: [nutLuuSieuThi, cuonSieuThiDaLuu])
        hangSieuThi.axis = .horizontal
        hangSieuThi.spacing = 6
        hangSieuThi.alignment = .center

        nhanGoiYSieuThi.text = "Mẹo: Tìm địa chỉ hoặc chạm giữ bản đồ để chọn siêu thị → bấm \"＋ Lưu siêu thị\" (chọn được nhiều điểm để quét cùng lúc, chạm giữ thẻ để xóa)."
        nhanGoiYSieuThi.font = .systemFont(ofSize: 11, weight: .medium)
        nhanGoiYSieuThi.textColor = BangMauBCTD.chuMo
        nhanGoiYSieuThi.numberOfLines = 0

        // Hàng 3: Nhập bán kính (mét) + Nút Quét khu vực
        let nhanBK = UILabel()
        nhanBK.text = "Bán kính:"
        nhanBK.font = .systemFont(ofSize: 13, weight: .bold)
        nhanBK.textColor = BangMauBCTD.chuChinh
        nhanBK.setContentHuggingPriority(.required, for: .horizontal)
        nhanBK.setContentCompressionResistancePriority(.required, for: .horizontal)

        oNhapBanKinh.text = "\(Int(banKinhMet))"
        oNhapBanKinh.placeholder = "VD: 2000"
        oNhapBanKinh.keyboardType = .numberPad
        oNhapBanKinh.textAlignment = .center
        oNhapBanKinh.font = .systemFont(ofSize: 15, weight: .heavy)
        oNhapBanKinh.textColor = BangMauBCTD.xanhChuDaoDam
        oNhapBanKinh.backgroundColor = BangMauBCTD.vangNhatNen.withAlphaComponent(0.55)
        oNhapBanKinh.layer.cornerRadius = 9
        oNhapBanKinh.layer.borderWidth = 1.2
        oNhapBanKinh.layer.borderColor = BangMauBCTD.vangChuDao.cgColor
        oNhapBanKinh.widthAnchor.constraint(equalToConstant: 82).isActive = true
        oNhapBanKinh.heightAnchor.constraint(equalToConstant: 40).isActive = true
        let thanhXong = UIToolbar()
        thanhXong.sizeToFit()
        thanhXong.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Xong", style: .done, target: self, action: #selector(anBanPhim))
        ]
        oNhapBanKinh.inputAccessoryView = thanhXong
        oNhapBanKinh.addTarget(self, action: #selector(banKinhThayDoi), for: .editingChanged)

        let nhanMet = UILabel()
        nhanMet.text = "m"
        nhanMet.font = .systemFont(ofSize: 13, weight: .semibold)
        nhanMet.textColor = BangMauBCTD.chuPhu
        nhanMet.setContentHuggingPriority(.required, for: .horizontal)
        nhanMet.setContentCompressionResistancePriority(.required, for: .horizontal)

        nutQuetKhuVuc.setTitle("🔍 Quét khu vực", for: .normal)
        nutQuetKhuVuc.titleLabel?.font = .systemFont(ofSize: 14, weight: .heavy)
        nutQuetKhuVuc.setTitleColor(.white, for: .normal)
        nutQuetKhuVuc.backgroundColor = BangMauBCTD.xanhChuDao
        nutQuetKhuVuc.layer.cornerRadius = 10
        nutQuetKhuVuc.heightAnchor.constraint(equalToConstant: 40).isActive = true
        nutQuetKhuVuc.addTarget(self, action: #selector(bamQuetKhuVuc), for: .touchUpInside)

        vongQuayQuet.color = BangMauBCTD.xanhChuDao
        vongQuayQuet.hidesWhenStopped = true

        let hangBanKinh = UIStackView(arrangedSubviews: [nhanBK, oNhapBanKinh, nhanMet, nutQuetKhuVuc, vongQuayQuet])
        hangBanKinh.axis = .horizontal
        hangBanKinh.spacing = 6
        hangBanKinh.alignment = .center

        // Hàng 4: Chọn nhanh bán kính
        let mucNhanh = [500, 1000, 2000, 3000, 5000]
        let hangChonNhanh = UIStackView()
        hangChonNhanh.axis = .horizontal
        hangChonNhanh.spacing = 6
        hangChonNhanh.distribution = .fillEqually
        cacNutBanKinhNhanh = []

        for m in mucNhanh {
            let btn = UIButton(type: .system)
            btn.tag = m
            let nhan = m >= 1000 ? "\(m / 1000)km" : "\(m)m"
            btn.setTitle(nhan, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
            btn.layer.cornerRadius = 8
            btn.layer.borderWidth = 1
            btn.heightAnchor.constraint(equalToConstant: 28).isActive = true
            btn.addTarget(self, action: #selector(bamChonBanKinhNhanh(_:)), for: .touchUpInside)
            cacNutBanKinhNhanh.append(btn)
            hangChonNhanh.addArrangedSubview(btn)
        }
        capNhatNutBanKinhNhanh()

        nhanTrangThaiQuet.text = "Chọn siêu thị hoặc chạm giữ bản đồ để đặt tâm, nhập bán kính rồi bấm Quét khu vực."
        nhanTrangThaiQuet.font = .systemFont(ofSize: 12, weight: .medium)
        nhanTrangThaiQuet.textColor = BangMauBCTD.chuPhu
        nhanTrangThaiQuet.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [hangTieuDe, hangTim, hangSieuThi, nhanGoiYSieuThi, hangBanKinh, hangChonNhanh, nhanTrangThaiQuet])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        the.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: the.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: the.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: the.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: the.bottomAnchor, constant: -12)
        ])

        return the
    }

    private func dungLaiThanhSieuThiDaLuu() {
        nganSieuThiDaLuu.arrangedSubviews.forEach {
            nganSieuThiDaLuu.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        if dsSieuThiDaLuu.isEmpty {
            let nhan = UILabel()
            nhan.text = "Chưa lưu siêu thị nào"
            nhan.font = .systemFont(ofSize: 11.5, weight: .medium)
            nhan.textColor = BangMauBCTD.chuMo
            nganSieuThiDaLuu.addArrangedSubview(nhan)
            return
        }

        for (idx, st) in dsSieuThiDaLuu.enumerated() {
            let nut = UIButton(type: .system)
            nut.tag = idx
            let dau = st.dangChon ? "✓ " : ""
            nut.setTitle("\(dau)\(st.ten)", for: .normal)
            nut.titleLabel?.font = .systemFont(ofSize: 12, weight: st.dangChon ? .bold : .semibold)
            nut.setTitleColor(st.dangChon ? .white : BangMauBCTD.chuChinh, for: .normal)
            nut.backgroundColor = st.dangChon ? BangMauBCTD.xanhChuDao : BangMauBCTD.nenThePhu
            nut.layer.cornerRadius = 8
            nut.layer.borderWidth = 1
            nut.layer.borderColor = (st.dangChon ? BangMauBCTD.xanhChuDaoDam : BangMauBCTD.vienDam).cgColor
            nut.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
            nut.heightAnchor.constraint(equalToConstant: 30).isActive = true
            nut.addTarget(self, action: #selector(bamChonSieuThiDaLuu(_:)), for: .touchUpInside)

            let giu = UILongPressGestureRecognizer(target: self, action: #selector(giuXoaSieuThiDaLuu(_:)))
            giu.minimumPressDuration = 0.5
            nut.addGestureRecognizer(giu)

            nganSieuThiDaLuu.addArrangedSubview(nut)
        }
    }

    private func taoTheBanDo() -> UIView {
        khungBanDo.backgroundColor = BangMauBCTD.nenThe
        khungBanDo.layer.cornerRadius = 14
        khungBanDo.layer.borderWidth = 1
        khungBanDo.layer.borderColor = BangMauBCTD.vienThe.cgColor
        khungBanDo.clipsToBounds = true
        khungBanDo.translatesAutoresizingMaskIntoConstraints = false

        banDo.delegate = self
        banDo.showsUserLocation = true
        banDo.showsCompass = true
        banDo.showsScale = true
        banDo.translatesAutoresizingMaskIntoConstraints = false
        khungBanDo.addSubview(banDo)

        let nhanGiu = UILongPressGestureRecognizer(target: self, action: #selector(xuLyChamGiuBanDo(_:)))
        nhanGiu.minimumPressDuration = 0.45
        banDo.addGestureRecognizer(nhanGiu)

        chonKieuBanDo.selectedSegmentIndex = 0
        chonKieuBanDo.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        chonKieuBanDo.selectedSegmentTintColor = BangMauBCTD.xanhChuDao
        chonKieuBanDo.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 11.5, weight: .bold)], for: .selected)
        chonKieuBanDo.setTitleTextAttributes([.foregroundColor: BangMauBCTD.chuChinh, .font: UIFont.systemFont(ofSize: 11.5, weight: .semibold)], for: .normal)
        chonKieuBanDo.translatesAutoresizingMaskIntoConstraints = false
        chonKieuBanDo.addTarget(self, action: #selector(doiKieuBanDo), for: .valueChanged)
        khungBanDo.addSubview(chonKieuBanDo)

        nutBatTatTuyen.setTitle("🛣️ Tuyến: Bật", for: .normal)
        nutBatTatTuyen.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutBatTatTuyen.setTitleColor(.white, for: .normal)
        nutBatTatTuyen.backgroundColor = BangMauBCTD.xanhDatVach.withAlphaComponent(0.94)
        nutBatTatTuyen.layer.cornerRadius = 8
        nutBatTatTuyen.contentEdgeInsets = UIEdgeInsets(top: 5, left: 9, bottom: 5, right: 9)
        nutBatTatTuyen.translatesAutoresizingMaskIntoConstraints = false
        nutBatTatTuyen.addTarget(self, action: #selector(bamBatTatTuyen), for: .touchUpInside)
        khungBanDo.addSubview(nutBatTatTuyen)

        nutCheDoTrangThaiPhat.setTitle("📍 Trạng thái phát", for: .normal)
        nutCheDoTrangThaiPhat.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .heavy)
        nutCheDoTrangThaiPhat.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
        nutCheDoTrangThaiPhat.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        nutCheDoTrangThaiPhat.layer.cornerRadius = 8
        nutCheDoTrangThaiPhat.layer.borderWidth = 1.3
        nutCheDoTrangThaiPhat.layer.borderColor = BangMauBCTD.xanhChuDao.cgColor
        nutCheDoTrangThaiPhat.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        nutCheDoTrangThaiPhat.translatesAutoresizingMaskIntoConstraints = false
        nutCheDoTrangThaiPhat.addTarget(self, action: #selector(bamCheDoTrangThaiPhat), for: .touchUpInside)
        khungBanDo.addSubview(nutCheDoTrangThaiPhat)

        nutPhongToBanDo.setTitle("⤢ Rộng", for: .normal)
        nutPhongToBanDo.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutPhongToBanDo.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
        nutPhongToBanDo.backgroundColor = UIColor.white.withAlphaComponent(0.94)
        nutPhongToBanDo.layer.cornerRadius = 8
        nutPhongToBanDo.layer.borderWidth = 1
        nutPhongToBanDo.layer.borderColor = BangMauBCTD.vienDam.cgColor
        nutPhongToBanDo.contentEdgeInsets = UIEdgeInsets(top: 5, left: 9, bottom: 5, right: 9)
        nutPhongToBanDo.translatesAutoresizingMaskIntoConstraints = false
        nutPhongToBanDo.addTarget(self, action: #selector(bamPhongToBanDo), for: .touchUpInside)
        khungBanDo.addSubview(nutPhongToBanDo)

        nhanGoiYBanDo.isHidden = true
        nhanGoiYBanDo.translatesAutoresizingMaskIntoConstraints = false
        khungBanDo.addSubview(nhanGoiYBanDo)

        let caoBD = khungBanDo.heightAnchor.constraint(equalToConstant: 360)
        rangBuocChieuCaoBanDo = caoBD

        NSLayoutConstraint.activate([
            caoBD,
            banDo.topAnchor.constraint(equalTo: khungBanDo.topAnchor),
            banDo.leadingAnchor.constraint(equalTo: khungBanDo.leadingAnchor),
            banDo.trailingAnchor.constraint(equalTo: khungBanDo.trailingAnchor),
            banDo.bottomAnchor.constraint(equalTo: khungBanDo.bottomAnchor),

            chonKieuBanDo.topAnchor.constraint(equalTo: khungBanDo.topAnchor, constant: 8),
            chonKieuBanDo.leadingAnchor.constraint(equalTo: khungBanDo.leadingAnchor, constant: 8),
            chonKieuBanDo.heightAnchor.constraint(equalToConstant: 29),

            nutPhongToBanDo.topAnchor.constraint(equalTo: khungBanDo.topAnchor, constant: 8),
            nutPhongToBanDo.trailingAnchor.constraint(equalTo: khungBanDo.trailingAnchor, constant: -8),

            nutCheDoTrangThaiPhat.bottomAnchor.constraint(equalTo: khungBanDo.bottomAnchor, constant: -10),
            nutCheDoTrangThaiPhat.leadingAnchor.constraint(equalTo: khungBanDo.leadingAnchor, constant: 8),

            nutBatTatTuyen.bottomAnchor.constraint(equalTo: khungBanDo.bottomAnchor, constant: -10),
            nutBatTatTuyen.trailingAnchor.constraint(equalTo: khungBanDo.trailingAnchor, constant: -8)
        ])

        return khungBanDo
    }

    private func taoKhungChiTietTuyenDangChon() -> UIView {
        khungChiTietTuyenChon.backgroundColor = BangMauBCTD.nenThe
        khungChiTietTuyenChon.layer.cornerRadius = 12
        khungChiTietTuyenChon.layer.borderWidth = 1.4
        khungChiTietTuyenChon.layer.borderColor = BangMauBCTD.xanhChuDao.withAlphaComponent(0.45).cgColor
        khungChiTietTuyenChon.isHidden = true

        nhanTieuDeTuyenChon.font = .systemFont(ofSize: 13.5, weight: .heavy)
        nhanTieuDeTuyenChon.textColor = BangMauBCTD.xanhChuDaoDam
        nhanTieuDeTuyenChon.numberOfLines = 0
        nhanTieuDeTuyenChon.lineBreakMode = .byWordWrapping
        nhanTieuDeTuyenChon.adjustsFontSizeToFitWidth = false

        nhanNoiDungTuyenChon.font = .systemFont(ofSize: 12, weight: .medium)
        nhanNoiDungTuyenChon.textColor = BangMauBCTD.chuChinh
        nhanNoiDungTuyenChon.numberOfLines = 0
        nhanNoiDungTuyenChon.lineBreakMode = .byWordWrapping
        nhanNoiDungTuyenChon.adjustsFontSizeToFitWidth = false

        nutXemChiTietLoTrinh.setTitle("🧭 Xem rẽ trái/phải & Xuất ảnh", for: .normal)
        nutXemChiTietLoTrinh.titleLabel?.font = .systemFont(ofSize: 12, weight: .heavy)
        nutXemChiTietLoTrinh.titleLabel?.numberOfLines = 0
        nutXemChiTietLoTrinh.titleLabel?.lineBreakMode = .byWordWrapping
        nutXemChiTietLoTrinh.titleLabel?.adjustsFontSizeToFitWidth = false
        nutXemChiTietLoTrinh.setTitleColor(.white, for: .normal)
        nutXemChiTietLoTrinh.backgroundColor = BangMauBCTD.xanhChuDao
        nutXemChiTietLoTrinh.layer.cornerRadius = 9
        nutXemChiTietLoTrinh.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        nutXemChiTietLoTrinh.addTarget(self, action: #selector(bamMoChiTietTuyenDangChon), for: .touchUpInside)

        nutMoGGMapsTuyenChon.setTitle("🗺️ GG Maps", for: .normal)
        nutMoGGMapsTuyenChon.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        nutMoGGMapsTuyenChon.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
        nutMoGGMapsTuyenChon.backgroundColor = BangMauBCTD.nenHeaderPhu
        nutMoGGMapsTuyenChon.layer.cornerRadius = 9
        nutMoGGMapsTuyenChon.layer.borderWidth = 1
        nutMoGGMapsTuyenChon.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
        nutMoGGMapsTuyenChon.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        nutMoGGMapsTuyenChon.setContentHuggingPriority(.required, for: .horizontal)
        nutMoGGMapsTuyenChon.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutMoGGMapsTuyenChon.addTarget(self, action: #selector(bamMoGGMapsTuyenDangChon), for: .touchUpInside)

        let hangNut = UIStackView(arrangedSubviews: [nutXemChiTietLoTrinh, nutMoGGMapsTuyenChon])
        hangNut.axis = .horizontal
        hangNut.spacing = 8
        hangNut.alignment = .fill

        let stack = UIStackView(arrangedSubviews: [nhanTieuDeTuyenChon, nhanNoiDungTuyenChon, hangNut])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        khungChiTietTuyenChon.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: khungChiTietTuyenChon.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: khungChiTietTuyenChon.leadingAnchor, constant: 11),
            stack.trailingAnchor.constraint(equalTo: khungChiTietTuyenChon.trailingAnchor, constant: -11),
            stack.bottomAnchor.constraint(equalTo: khungChiTietTuyenChon.bottomAnchor, constant: -10)
        ])
        return khungChiTietTuyenChon
    }

    private func taoKhungThongKeKPI() -> UIView {
        let theTatCa = taoMotTheKPITuyBien(
            tieuDe: "Tất cả",
            bieuTuongSF: "square.grid.2x2.fill",
            mauChuDao: BangMauBCTD.xanhChuDao,
            mauNen: BangMauBCTD.nenHeaderPhu,
            nhanSo: nhanSoTatCa,
            tagLoc: BoLocPopupKhuVuc.tatCa.rawValue
        )
        let theDoiThu = taoMotTheKPI(loai: .doiThu, nhanSo: nhanSoDoiThu, tagLoc: BoLocPopupKhuVuc.doiThu.rawValue)
        let theMWG = taoMotTheKPITuyBien(
            tieuDe: "ĐMX",
            bieuTuongSF: LoaiDiaDiemQuet.heThongMWG.bieuTuongSF,
            mauChuDao: LoaiDiaDiemQuet.heThongMWG.mauChuDao,
            mauNen: LoaiDiaDiemQuet.heThongMWG.mauNenNhat,
            nhanSo: nhanSoMWG,
            tagLoc: BoLocPopupKhuVuc.heThongMWG.rawValue
        )
        let theTruong = taoMotTheKPI(loai: .truongHoc, nhanSo: nhanSoTruongHoc, tagLoc: BoLocPopupKhuVuc.truongHoc.rawValue)
        let theCho = taoMotTheKPI(loai: .cho, nhanSo: nhanSoCho, tagLoc: BoLocPopupKhuVuc.cho.rawValue)
        let theKhac = taoMotTheKPI(loai: .khac, nhanSo: nhanSoKhac, tagLoc: BoLocPopupKhuVuc.khac.rawValue)

        // Gọn chỉ còn 1 dòng duy nhất cho cả 6 chỉ số (chạm ô bất kỳ để mở popup chi tiết & xuất ảnh)
        let hangDuyNhat = UIStackView(arrangedSubviews: [theTatCa, theDoiThu, theMWG, theTruong, theCho, theKhac])
        hangDuyNhat.axis = .horizontal
        hangDuyNhat.spacing = 4
        hangDuyNhat.distribution = .fillEqually

        let goiY = UILabel()
        goiY.text = "👆 Chạm ô số lượng bất kỳ để mở bảng chi tiết & xuất ảnh"
        goiY.font = .systemFont(ofSize: 10.5, weight: .semibold)
        goiY.textColor = BangMauBCTD.chuPhu
        goiY.textAlignment = .center
        goiY.numberOfLines = 0
        goiY.lineBreakMode = .byWordWrapping
        goiY.adjustsFontSizeToFitWidth = false

        let cot = UIStackView(arrangedSubviews: [hangDuyNhat, goiY])
        cot.axis = .vertical
        cot.spacing = 4
        return cot
    }

    private func taoMotTheKPI(loai: LoaiDiaDiemQuet, nhanSo: UILabel, tagLoc: Int) -> UIControl {
        return taoMotTheKPITuyBien(
            tieuDe: loai.tieuDeNgan,
            bieuTuongSF: loai.bieuTuongSF,
            mauChuDao: loai.mauChuDao,
            mauNen: loai.mauNenNhat,
            nhanSo: nhanSo,
            tagLoc: tagLoc
        )
    }

    private func taoMotTheKPITuyBien(
        tieuDe: String,
        bieuTuongSF: String,
        mauChuDao: UIColor,
        mauNen: UIColor,
        nhanSo: UILabel,
        tagLoc: Int
    ) -> UIControl {
        let the = UIControl()
        the.tag = tagLoc
        the.backgroundColor = mauNen
        the.layer.cornerRadius = 9
        the.layer.borderWidth = 1.1
        the.layer.borderColor = mauChuDao.withAlphaComponent(0.35).cgColor
        the.addTarget(self, action: #selector(bamTheKPI(_:)), for: .touchUpInside)

        let cfg = UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
        let icon = UIImageView(image: UIImage(systemName: bieuTuongSF, withConfiguration: cfg))
        icon.tintColor = mauChuDao
        icon.contentMode = .scaleAspectFit

        let lbTieuDe = UILabel()
        lbTieuDe.text = tieuDe
        lbTieuDe.font = .systemFont(ofSize: 9.5, weight: .bold)
        lbTieuDe.textColor = BangMauBCTD.chuChinh
        lbTieuDe.textAlignment = .center
        lbTieuDe.numberOfLines = 0
        lbTieuDe.lineBreakMode = .byWordWrapping
        lbTieuDe.adjustsFontSizeToFitWidth = false

        nhanSo.text = "0"
        nhanSo.font = .systemFont(ofSize: 15, weight: .heavy)
        nhanSo.textColor = mauChuDao
        nhanSo.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [icon, nhanSo, lbTieuDe])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 1
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        the.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: the.topAnchor, constant: 5),
            stack.leadingAnchor.constraint(equalTo: the.leadingAnchor, constant: 2),
            stack.trailingAnchor.constraint(equalTo: the.trailingAnchor, constant: -2),
            stack.bottomAnchor.constraint(equalTo: the.bottomAnchor, constant: -5)
        ])

        return the
    }

    private func taoTheTuyenPhatToRoi() -> UIView {
        khungTuyenToRoi.backgroundColor = BangMauBCTD.nenThe
        khungTuyenToRoi.layer.cornerRadius = 14
        khungTuyenToRoi.layer.borderWidth = 1.2
        khungTuyenToRoi.layer.borderColor = BangMauBCTD.xanhDatVach.withAlphaComponent(0.45).cgColor
        khungTuyenToRoi.isHidden = true

        nhanTieuDeKhungTuyen.text = "🛣️ CHỌN TUYẾN & CHỈ DẪN ĐƯỜNG ĐI PHÁT TỜ RƠI"
        nhanTieuDeKhungTuyen.font = .systemFont(ofSize: 12.5, weight: .heavy)
        nhanTieuDeKhungTuyen.textColor = BangMauBCTD.xanhDatChu
        nhanTieuDeKhungTuyen.numberOfLines = 0
        nhanTieuDeKhungTuyen.lineBreakMode = .byWordWrapping
        nhanTieuDeKhungTuyen.adjustsFontSizeToFitWidth = false

        cuonChonTuyenChiDan.showsHorizontalScrollIndicator = false
        cuonChonTuyenChiDan.translatesAutoresizingMaskIntoConstraints = false
        cuonChonTuyenChiDan.heightAnchor.constraint(equalToConstant: 34).isActive = true

        nganChonTuyenChiDan.axis = .horizontal
        nganChonTuyenChiDan.spacing = 6
        nganChonTuyenChiDan.alignment = .center
        nganChonTuyenChiDan.translatesAutoresizingMaskIntoConstraints = false
        cuonChonTuyenChiDan.addSubview(nganChonTuyenChiDan)
        NSLayoutConstraint.activate([
            nganChonTuyenChiDan.topAnchor.constraint(equalTo: cuonChonTuyenChiDan.contentLayoutGuide.topAnchor),
            nganChonTuyenChiDan.bottomAnchor.constraint(equalTo: cuonChonTuyenChiDan.contentLayoutGuide.bottomAnchor),
            nganChonTuyenChiDan.leadingAnchor.constraint(equalTo: cuonChonTuyenChiDan.contentLayoutGuide.leadingAnchor),
            nganChonTuyenChiDan.trailingAnchor.constraint(equalTo: cuonChonTuyenChiDan.contentLayoutGuide.trailingAnchor),
            nganChonTuyenChiDan.heightAnchor.constraint(equalTo: cuonChonTuyenChiDan.frameLayoutGuide.heightAnchor)
        ])

        nhanTomTatTuyen.font = .systemFont(ofSize: 12, weight: .semibold)
        nhanTomTatTuyen.textColor = BangMauBCTD.chuChinh
        nhanTomTatTuyen.numberOfLines = 0
        nhanTomTatTuyen.lineBreakMode = .byWordWrapping
        nhanTomTatTuyen.adjustsFontSizeToFitWidth = false

        nhanKhungGioVang.font = .systemFont(ofSize: 11.5, weight: .medium)
        nhanKhungGioVang.textColor = BangMauBCTD.camPhanTich
        nhanKhungGioVang.backgroundColor = BangMauBCTD.vangNhatNen.withAlphaComponent(0.75)
        nhanKhungGioVang.layer.cornerRadius = 8
        nhanKhungGioVang.clipsToBounds = true
        nhanKhungGioVang.numberOfLines = 0
        nhanKhungGioVang.lineBreakMode = .byWordWrapping
        nhanKhungGioVang.adjustsFontSizeToFitWidth = false

        nutChiDanTuyenToiUu.setTitle("🧭 Chọn tuyến ở trên để xem chỉ dẫn rẽ trái/phải", for: .normal)
        nutChiDanTuyenToiUu.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .heavy)
        nutChiDanTuyenToiUu.titleLabel?.numberOfLines = 0
        nutChiDanTuyenToiUu.titleLabel?.lineBreakMode = .byWordWrapping
        nutChiDanTuyenToiUu.titleLabel?.adjustsFontSizeToFitWidth = false
        nutChiDanTuyenToiUu.setTitleColor(.white, for: .normal)
        nutChiDanTuyenToiUu.backgroundColor = BangMauBCTD.xanhChuDao
        nutChiDanTuyenToiUu.layer.cornerRadius = 10
        nutChiDanTuyenToiUu.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        nutChiDanTuyenToiUu.addTarget(self, action: #selector(bamXemChiDanTuyenToiUu), for: .touchUpInside)

        nutMoGoogleMapsTuyen.setTitle("🗺️ Dẫn đường GG Maps", for: .normal)
        nutMoGoogleMapsTuyen.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .heavy)
        nutMoGoogleMapsTuyen.titleLabel?.numberOfLines = 0
        nutMoGoogleMapsTuyen.titleLabel?.lineBreakMode = .byWordWrapping
        nutMoGoogleMapsTuyen.titleLabel?.adjustsFontSizeToFitWidth = false
        nutMoGoogleMapsTuyen.setTitleColor(.white, for: .normal)
        nutMoGoogleMapsTuyen.backgroundColor = BangMauBCTD.xanhDatVach
        nutMoGoogleMapsTuyen.layer.cornerRadius = 10
        nutMoGoogleMapsTuyen.contentEdgeInsets = UIEdgeInsets(top: 9, left: 8, bottom: 9, right: 8)
        nutMoGoogleMapsTuyen.addTarget(self, action: #selector(bamMoGoogleMapsTuyen), for: .touchUpInside)

        nutCopyKeHoach.setTitle("📋 Sao chép kế hoạch", for: .normal)
        nutCopyKeHoach.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        nutCopyKeHoach.titleLabel?.numberOfLines = 0
        nutCopyKeHoach.titleLabel?.lineBreakMode = .byWordWrapping
        nutCopyKeHoach.titleLabel?.adjustsFontSizeToFitWidth = false
        nutCopyKeHoach.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
        nutCopyKeHoach.backgroundColor = BangMauBCTD.nenHeaderPhu
        nutCopyKeHoach.layer.cornerRadius = 10
        nutCopyKeHoach.layer.borderWidth = 1
        nutCopyKeHoach.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
        nutCopyKeHoach.contentEdgeInsets = UIEdgeInsets(top: 9, left: 8, bottom: 9, right: 8)
        nutCopyKeHoach.addTarget(self, action: #selector(bamCopyKeHoach), for: .touchUpInside)

        let hangNut = UIStackView(arrangedSubviews: [nutMoGoogleMapsTuyen, nutCopyKeHoach])
        hangNut.axis = .horizontal
        hangNut.spacing = 8
        hangNut.distribution = .fillEqually

        // Đã bỏ danh sách bảng 1, 2, 3, 4... bên dưới cho giao diện gọn sạch
        let stack = UIStackView(arrangedSubviews: [nhanTieuDeKhungTuyen, cuonChonTuyenChiDan, nhanTomTatTuyen, nhanKhungGioVang, nutChiDanTuyenToiUu, hangNut])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        khungTuyenToRoi.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: khungTuyenToRoi.topAnchor, constant: 11),
            stack.leadingAnchor.constraint(equalTo: khungTuyenToRoi.leadingAnchor, constant: 11),
            stack.trailingAnchor.constraint(equalTo: khungTuyenToRoi.trailingAnchor, constant: -11),
            stack.bottomAnchor.constraint(equalTo: khungTuyenToRoi.bottomAnchor, constant: -11)
        ])

        return khungTuyenToRoi
    }

    // MARK: - Xử Lý Bản Đồ & Google Maps Tile Layer

    private func apDungLopNenBanDo() {
        if let cu = lopTileGoogle {
            banDo.removeOverlay(cu)
            lopTileGoogle = nil
        }

        switch kieuNenBanDo {
        case .googleDuongPho:
            let tile = MKTileOverlay(urlTemplate: "https://mt1.google.com/vt/lyrs=m&hl=vi&x={x}&y={y}&z={z}")
            tile.canReplaceMapContent = true
            tile.maximumZ = 20
            lopTileGoogle = tile
            banDo.insertOverlay(tile, at: 0, level: .aboveLabels)
        case .googleVeTinh:
            let tile = MKTileOverlay(urlTemplate: "https://mt1.google.com/vt/lyrs=y&hl=vi&x={x}&y={y}&z={z}")
            tile.canReplaceMapContent = true
            tile.maximumZ = 20
            lopTileGoogle = tile
            banDo.insertOverlay(tile, at: 0, level: .aboveLabels)
        case .appleMap:
            banDo.mapType = .standard
        }
    }

    private func capNhatTamVaVongTronTrenBanDo(diChuyenCamera: Bool) {
        let vongCu = banDo.overlays.filter { $0 is MKCircle }
        banDo.removeOverlays(vongCu)

        let ghimTamCu = banDo.annotations.filter { $0 is GhimTamQuetAnnotation }
        banDo.removeAnnotations(ghimTamCu)

        // Khi bật chế độ "Trạng thái phát tờ rơi", ẩn toàn bộ vòng tròn & ghim tâm quét để bản đồ CHỈ hiện Tuyến + Check-in!
        if cheDoTrangThaiPhat {
            return
        }

        let bkPhat = cauHinhPhanTuyen.banKinhPhatHieuLuc(banKinhQuetMet: banKinhMet)
        let hienVongPhatRieng = (cauHinhPhanTuyen.banKinhPhatToRoiMet >= 200 && abs(bkPhat - banKinhMet) >= 10)

        let cacTam = danhSachTamDangChonDeQuet()
        for t in cacTam {
            let moTaVong = hienVongPhatRieng
                ? "Quét: \(Int(banKinhMet))m • Phát tờ rơi: \(Int(bkPhat))m"
                : "Bán kính quét & phát: \(Int(banKinhMet))m"
            let ghim = GhimTamQuetAnnotation(
                coordinate: t.toaDo,
                title: t.ten,
                subtitle: moTaVong,
                laSieuThiDaLuu: t.laSieuThiLuu
            )
            banDo.addAnnotation(ghim)

            let vongQuet = MKCircle(center: t.toaDo, radius: banKinhMet)
            banDo.addOverlay(vongQuet, level: .aboveLabels)

            if hienVongPhatRieng {
                let vongPhat = VongBanKinhToRoiCircle(center: t.toaDo, radius: bkPhat)
                banDo.addOverlay(vongPhat, level: .aboveLabels)
            }
        }

        if diChuyenCamera {
            let bkHien = max(banKinhMet, bkPhat)
            if cacTam.count == 1, let dau = cacTam.first {
                let spanMet = max(600, bkHien * 2.55)
                let region = MKCoordinateRegion(center: dau.toaDo, latitudinalMeters: spanMet, longitudinalMeters: spanMet)
                banDo.setRegion(region, animated: true)
            } else if cacTam.count > 1 {
                var minLat = Double.greatestFiniteMagnitude
                var maxLat = -Double.greatestFiniteMagnitude
                var minLon = Double.greatestFiniteMagnitude
                var maxLon = -Double.greatestFiniteMagnitude
                for t in cacTam {
                    minLat = min(minLat, t.toaDo.latitude)
                    maxLat = max(maxLat, t.toaDo.latitude)
                    minLon = min(minLon, t.toaDo.longitude)
                    maxLon = max(maxLon, t.toaDo.longitude)
                }
                let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2.0, longitude: (minLon + maxLon) / 2.0)
                let latDelta = max((maxLat - minLat) * 1.45, (bkHien * 2.6) / 111000.0)
                let lonDelta = max((maxLon - minLon) * 1.45, (bkHien * 2.6) / 111000.0)
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
                banDo.setRegion(region, animated: true)
            }
        }
    }

    private func danhSachTuyenIdCuaNhanSuDangLoc() -> Set<String>? {
        guard let tenLoc = tenNhanSuDangLoc, !tenLoc.isEmpty, let kh = keHoachMaTran else { return nil }
        let key = KhoCheckInPWADongBo.tenChuanHoaKhongCa(tenLoc)
        var ids = Set<String>()
        for o in kh.cacO {
            let ds = (o.danhSachPG + o.danhSachNV).map { KhoCheckInPWADongBo.tenChuanHoaKhongCa($0) }
            if ds.contains(where: { $0 == key || $0.contains(key) || key.contains($0) }) {
                ids.insert(o.tuyenId)
            }
        }
        return ids.isEmpty ? nil : ids
    }

    private func veLaiGhimVaTuyenTrenBanDo() {
        let ghimCu = banDo.annotations.filter { $0 is GhimDiaDiemAnnotation }
        banDo.removeAnnotations(ghimCu)

        let duongCu = banDo.overlays.filter { $0 is MKPolyline }
        banDo.removeOverlays(duongCu)

        let nhanTuyenCu = banDo.annotations.filter { $0 is GhimNhanTuyenAnnotation }
        banDo.removeAnnotations(nhanTuyenCu)

        let ghimBangChungCu = banDo.annotations.filter { $0 is GhimBangChungAnnotation }
        banDo.removeAnnotations(ghimBangChungCu)

        let ghimPWACu = banDo.annotations.filter { $0 is GhimCheckInPWAAnnotation }
        banDo.removeAnnotations(ghimPWACu)

        let tapTuyenNhanSu = danhSachTuyenIdCuaNhanSuDangLoc()

        // Ở chế độ thường: hiển thị các ghim POI quét được (Đối thủ, ĐMX, Trường, Chợ, Khác).
        // Ở chế độ "Trạng thái phát tờ rơi": ẨN SẠCH các ghim POI, CHỈ hiện Tuyến đường + Vị trí + Tên nhân viên/PG đã check-in!
        if !cheDoTrangThaiPhat {
            var banDoSTT: [String: Int] = [:]
            if hienTuyenToRoi {
                if let locID = tuyenDangLocTrenBanDo,
                   let tuyenChon = keHoachMaTran?.cacTuyen.first(where: { $0.id == locID }) {
                    for (i, d) in tuyenChon.cacDiemMucTieu.enumerated() {
                        banDoSTT[d.id] = i + 1
                    }
                } else if let tuyen = ketQuaTuyen {
                    for d in tuyen.cacDiemDung {
                        if let stt = d.soThuTuTuyen {
                            banDoSTT[d.id] = stt
                        }
                    }
                }
            }

            let dsGhim: [GhimDiaDiemAnnotation] = tatCaDiaDiem.map { item in
                var banSao = item
                banSao.soThuTuTuyen = banDoSTT[item.id]
                return GhimDiaDiemAnnotation(diaDiem: banSao)
            }
            banDo.addAnnotations(dsGhim)
        }

        if hienTuyenToRoi || cheDoTrangThaiPhat {
            // Vẽ từng tuyến bằng đường thực tế bám sát bản đồ (toaDoVeBanDo) với màu riêng & nhãn T1/T2...
            let cacTuyenCoToaDo = (keHoachMaTran?.cacTuyen ?? []).filter { $0.toaDoVeBanDo.count >= 2 }
            if !cacTuyenCoToaDo.isEmpty {
                for tuyen in cacTuyenCoToaDo {
                    if let locID = tuyenDangLocTrenBanDo, locID != tuyen.id { continue }
                    if tuyenDangLocTrenBanDo == nil, let tapNS = tapTuyenNhanSu, !tapNS.contains(tuyen.id) { continue }
                    let coords = tuyen.toaDoVeBanDo.compactMap { pair -> CLLocationCoordinate2D? in
                        guard pair.count >= 2 else { return nil }
                        return CLLocationCoordinate2D(latitude: pair[0], longitude: pair[1])
                    }
                    guard coords.count >= 2 else { continue }
                    let vien = TuyenPhatToRoiPolyline(coordinates: coords, count: coords.count)
                    vien.laVienNen = true
                    vien.mauTuyen = tuyen.mauTuyen
                    let loi = TuyenPhatToRoiPolyline(coordinates: coords, count: coords.count)
                    loi.laVienNen = false
                    loi.mauTuyen = tuyen.mauTuyen
                    banDo.addOverlay(vien, level: .aboveLabels)
                    banDo.addOverlay(loi, level: .aboveLabels)

                    // Đặt nhãn T1 / T2 / T3 / T4 ở điểm giữa tuyến bám đường thực tế
                    let midIdx = max(1, coords.count / 2)
                    let kmStr = BoDanDuongTuyenThucTe.dinhDangKhoangCach(tuyen.tongQuangDuongMet)
                    let xmStr = BoDanDuongTuyenThucTe.dinhDangPhut(tuyen.thoiGianXeMayPhut)
                    let dbStr = BoDanDuongTuyenThucTe.dinhDangPhut(tuyen.thoiGianDiBoPhut)
                    let nhanAnn = GhimNhanTuyenAnnotation(
                        soThuTu: tuyen.soThuTu,
                        tenTuyen: tuyen.ten,
                        moTa: "\(kmStr) • 🛵 \(xmStr) • 🚶 \(dbStr)",
                        mauTuyen: tuyen.mauTuyen,
                        coordinate: coords[midIdx]
                    )
                    banDo.addAnnotation(nhanAnn)
                }
            } else if let tuyen = ketQuaTuyen, tuyen.toaDoDuongDi.count >= 2 {
                let vien = TuyenPhatToRoiPolyline(coordinates: tuyen.toaDoDuongDi, count: tuyen.toaDoDuongDi.count)
                vien.laVienNen = true
                let loi = TuyenPhatToRoiPolyline(coordinates: tuyen.toaDoDuongDi, count: tuyen.toaDoDuongDi.count)
                loi.laVienNen = false
                banDo.addOverlay(vien, level: .aboveLabels)
                banDo.addOverlay(loi, level: .aboveLabels)
            }
        }

        // Hiển thị các ghim nhân viên/PG đã check-in từ PWA (luôn kèm thẻ tên trực tiếp trên bản đồ!)
        let sttTuyenLoc: Int? = {
            if let locID = tuyenDangLocTrenBanDo {
                return keHoachMaTran?.cacTuyen.first(where: { $0.id == locID })?.soThuTu
            }
            return nil
        }()
        let tenNSLocKey = tenNhanSuDangLoc.map { KhoCheckInPWADongBo.tenChuanHoaKhongCa($0) }
        let dsPWALoc = dsCheckInPWA.filter { bc in
            if let tenKey = tenNSLocKey, !tenKey.isEmpty {
                let k = bc.tenChuanHoa
                if !(k == tenKey || k.contains(tenKey) || tenKey.contains(k)) { return false }
            }
            if let stt = sttTuyenLoc, let bcStt = bc.soThuTuTuyen, bcStt != stt {
                return false
            }
            return true
        }
        let ghimPWA = dsPWALoc.compactMap { GhimCheckInPWAAnnotation(banGhi: $0) }
        if !ghimPWA.isEmpty {
            banDo.addAnnotations(ghimPWA)
        }

        // Hiển thị thêm các ghim bằng chứng nội bộ (nếu có)
        if let kh = keHoachMaTran {
            let idsO = Set(kh.cacO.map { $0.id })
            let dsBC = KhoBangChungPhatToRoi.dungChung.layTatCa().filter { bc in
                guard idsO.contains(bc.oMaTranId) else { return false }
                if let locID = tuyenDangLocTrenBanDo, locID != bc.tuyenId { return false }
                return true
            }
            if !dsBC.isEmpty {
                banDo.addAnnotations(dsBC.map { GhimBangChungAnnotation(bangChung: $0) })
            }
        }
    }

    // MARK: - Hành Động Người Dùng (Lưu / Chọn Nhiều Siêu Thị & Quét)

    @objc private func anBanPhim() {
        view.endEditing(true)
    }

    @objc private func bamLuuViTriSieuThi() {
        view.endEditing(true)
        let goiYTen: String
        let tuTim = (oTimDiaChi.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !tuTim.isEmpty {
            goiYTen = tuTim
        } else if !tenTamQuet.isEmpty && !tenTamQuet.hasPrefix("Tâm quét") {
            goiYTen = tenTamQuet
        } else {
            goiYTen = "Siêu thị ĐMX #\(dsSieuThiDaLuu.count + 1)"
        }

        let ac = UIAlertController(
            title: "Lưu vị trí siêu thị / điểm quét",
            message: "Đặt tên cho vị trí đang ghim trên bản đồ (bạn có thể lưu và chọn nhiều điểm để quét cùng lúc).",
            preferredStyle: .alert
        )
        ac.addTextField { tf in
            tf.placeholder = "VD: ĐMX 275 Quang Trung"
            tf.text = goiYTen
            tf.clearButtonMode = .whileEditing
        }
        ac.addAction(UIAlertAction(title: "Lưu & Chọn", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let ten = (ac.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let tenChuan = ten.isEmpty ? goiYTen : ten
            let moi = DiaDiemSieuThiLuu(
                id: UUID().uuidString,
                ten: tenChuan,
                viDo: self.tamQuet.latitude,
                kinhDo: self.tamQuet.longitude,
                dangChon: true
            )
            self.dsSieuThiDaLuu.append(moi)
            KhoDiaDiemSieuThi.dungChung.luuDanhSach(self.dsSieuThiDaLuu)
            self.dungLaiThanhSieuThiDaLuu()
            self.capNhatTamVaVongTronTrenBanDo(diChuyenCamera: true)
            let soChon = self.dsSieuThiDaLuu.filter { $0.dangChon }.count
            self.nhanTrangThaiQuet.text = "Đã lưu \"\(tenChuan)\". Đang chọn \(soChon) vị trí siêu thị để quét."
        })
        ac.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        present(ac, animated: true)
    }

    @objc private func bamChonSieuThiDaLuu(_ sender: UIButton) {
        let idx = sender.tag
        guard idx >= 0 && idx < dsSieuThiDaLuu.count else { return }
        dsSieuThiDaLuu[idx].dangChon.toggle()
        if dsSieuThiDaLuu[idx].dangChon {
            tamQuet = dsSieuThiDaLuu[idx].toaDo
            tenTamQuet = dsSieuThiDaLuu[idx].ten
        }
        KhoDiaDiemSieuThi.dungChung.luuDanhSach(dsSieuThiDaLuu)
        dungLaiThanhSieuThiDaLuu()
        capNhatTamVaVongTronTrenBanDo(diChuyenCamera: true)

        let soChon = dsSieuThiDaLuu.filter { $0.dangChon }.count
        if soChon > 0 {
            nhanTrangThaiQuet.text = "Đang chọn \(soChon) vị trí siêu thị. Bấm \"Quét khu vực\" để quét tất cả vùng đã chọn."
        } else {
            nhanTrangThaiQuet.text = "Đã bỏ chọn siêu thị đã lưu — sẽ quét quanh ghim hiện tại trên bản đồ."
        }
    }

    @objc private func giuXoaSieuThiDaLuu(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let btn = gesture.view as? UIButton else { return }
        let idx = btn.tag
        guard idx >= 0 && idx < dsSieuThiDaLuu.count else { return }
        let item = dsSieuThiDaLuu[idx]

        let ac = UIAlertController(title: item.ten, message: "Bạn muốn xóa vị trí đã lưu này?", preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Xóa vị trí này", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.dsSieuThiDaLuu.remove(at: idx)
            KhoDiaDiemSieuThi.dungChung.luuDanhSach(self.dsSieuThiDaLuu)
            self.dungLaiThanhSieuThiDaLuu()
            self.capNhatTamVaVongTronTrenBanDo(diChuyenCamera: true)
        })
        ac.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        if let pop = ac.popoverPresentationController {
            pop.sourceView = btn
            pop.sourceRect = btn.bounds
        }
        present(ac, animated: true)
    }

    @objc private func banKinhThayDoi() {
        let so = Double((oNhapBanKinh.text ?? "").filter { $0.isNumber }) ?? 0
        if so >= 100 && so <= 20000 {
            banKinhMet = so
            capNhatNutBanKinhNhanh()
            capNhatMenuCauHinhPhanTuyen()
            capNhatTamVaVongTronTrenBanDo(diChuyenCamera: false)
        }
    }

    @objc private func bamChonBanKinhNhanh(_ sender: UIButton) {
        view.endEditing(true)
        banKinhMet = Double(sender.tag)
        oNhapBanKinh.text = "\(sender.tag)"
        capNhatNutBanKinhNhanh()
        luuTrangThaiTamVaBanKinh()
        capNhatMenuCauHinhPhanTuyen()
        capNhatTamVaVongTronTrenBanDo(diChuyenCamera: true)
    }

    private func capNhatNutBanKinhNhanh() {
        for btn in cacNutBanKinhNhanh {
            let dangChon = (Double(btn.tag) == banKinhMet)
            btn.backgroundColor = dangChon ? BangMauBCTD.vangSang : BangMauBCTD.nenThePhu
            btn.setTitleColor(dangChon ? BangMauBCTD.chuChinh : BangMauBCTD.chuPhu, for: .normal)
            btn.layer.borderColor = (dangChon ? BangMauBCTD.vangChuDao : BangMauBCTD.vienThe).cgColor
        }
    }

    @objc private func doiKieuBanDo() {
        kieuNenBanDo = KieuNenBanDo(rawValue: chonKieuBanDo.selectedSegmentIndex) ?? .googleDuongPho
        apDungLopNenBanDo()
        capNhatTamVaVongTronTrenBanDo(diChuyenCamera: false)
        veLaiGhimVaTuyenTrenBanDo()
    }

    @objc private func bamBatTatTuyen() {
        hienTuyenToRoi.toggle()
        nutBatTatTuyen.setTitle(hienTuyenToRoi ? "🛣️ Tuyến: Bật" : "🛣️ Tuyến: Ẩn", for: .normal)
        nutBatTatTuyen.backgroundColor = (hienTuyenToRoi ? BangMauBCTD.xanhDatVach : BangMauBCTD.chuMo).withAlphaComponent(0.94)
        veLaiGhimVaTuyenTrenBanDo()
    }

    @objc private func bamCheDoTrangThaiPhat() {
        cheDoTrangThaiPhat.toggle()
        if cheDoTrangThaiPhat {
            hienTuyenToRoi = true
            nutBatTatTuyen.setTitle("🛣️ Tuyến: Bật", for: .normal)
            nutBatTatTuyen.backgroundColor = BangMauBCTD.xanhDatVach.withAlphaComponent(0.94)
        }
        capNhatNutCheDoTrangThaiPhat()
        capNhatTamVaVongTronTrenBanDo(diChuyenCamera: false)
        veLaiGhimVaTuyenTrenBanDo()
        if cheDoTrangThaiPhat {
            dongBoCheckInTuPWA(imLang: true)
            zoomToanCanhTrangThaiPhat()
        }
    }

    private func capNhatNutCheDoTrangThaiPhat() {
        let soCheckIn = dsCheckInPWA.count
        if cheDoTrangThaiPhat {
            nutCheDoTrangThaiPhat.setTitle("✅ Đang xem Check-in (\(soCheckIn)) • Tắt", for: .normal)
            nutCheDoTrangThaiPhat.setTitleColor(.white, for: .normal)
            nutCheDoTrangThaiPhat.backgroundColor = BangMauBCTD.xanhLaDam.withAlphaComponent(0.96)
            nutCheDoTrangThaiPhat.layer.borderColor = UIColor.white.cgColor
        } else {
            let nhanSo = soCheckIn > 0 ? " (\(soCheckIn))" : ""
            nutCheDoTrangThaiPhat.setTitle("📍 Trạng thái phát\(nhanSo)", for: .normal)
            nutCheDoTrangThaiPhat.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
            nutCheDoTrangThaiPhat.backgroundColor = UIColor.white.withAlphaComponent(0.96)
            nutCheDoTrangThaiPhat.layer.borderColor = BangMauBCTD.xanhChuDao.cgColor
        }
    }

    private func zoomToanCanhTrangThaiPhat() {
        var tatCaToaDo: [CLLocationCoordinate2D] = []
        for bc in dsCheckInPWA {
            if let c = bc.toaDoHopLe { tatCaToaDo.append(c) }
        }
        for tuyen in (keHoachMaTran?.cacTuyen ?? []) {
            if let locID = tuyenDangLocTrenBanDo, locID != tuyen.id { continue }
            for p in tuyen.toaDoVeBanDo where p.count >= 2 {
                tatCaToaDo.append(CLLocationCoordinate2D(latitude: p[0], longitude: p[1]))
            }
        }
        guard tatCaToaDo.count >= 2 else {
            if let mot = tatCaToaDo.first {
                banDo.setRegion(MKCoordinateRegion(center: mot, latitudinalMeters: 900, longitudinalMeters: 900), animated: true)
            }
            return
        }
        var minLat = Double.greatestFiniteMagnitude
        var maxLat = -Double.greatestFiniteMagnitude
        var minLon = Double.greatestFiniteMagnitude
        var maxLon = -Double.greatestFiniteMagnitude
        for c in tatCaToaDo {
            minLat = min(minLat, c.latitude); maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2.0, longitude: (minLon + maxLon) / 2.0)
        let span = MKCoordinateSpan(latitudeDelta: max((maxLat - minLat) * 1.45, 0.008), longitudeDelta: max((maxLon - minLon) * 1.45, 0.008))
        banDo.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
    }

    private func zoomDenGhimCheckInPWA(_ bc: BanGhiCheckInPWA) {
        cheDoTrangThaiPhat = true
        hienTuyenToRoi = true
        capNhatNutCheDoTrangThaiPhat()
        capNhatTamVaVongTronTrenBanDo(diChuyenCamera: false)
        veLaiGhimVaTuyenTrenBanDo()
        if let c = bc.toaDoHopLe {
            banDo.setRegion(MKCoordinateRegion(center: c, latitudinalMeters: 650, longitudinalMeters: 650), animated: true)
        }
        cuonChinh.setContentOffset(CGPoint(x: CGFloat(0), y: max(CGFloat(0), khungBanDo.frame.minY - CGFloat(8))), animated: true)
    }

    private func dongBoCheckInTuPWA(imLang: Bool) {
        guard !dangDongBoPWA else { return }
        dangDongBoPWA = true
        if !imLang {
            nutDongBoPWA.isEnabled = false
            nutDongBoPWA.setTitle("⏳ Đang đồng bộ...", for: .normal)
        }
        BoDongBoCheckInPWA.dungChung.taiDanhSachCheckIn { [weak self] res in
            guard let self else { return }
            self.dangDongBoPWA = false
            self.nutDongBoPWA.isEnabled = true
            self.nutDongBoPWA.setTitle("🔄 Đồng bộ PWA", for: .normal)
            switch res {
            case .success(let ds):
                self.dsCheckInPWA = ds
                // Tự động đánh dấu hoàn thành những buổi đã có nhân viên/PG check-in trên PWA
                if var kh = self.keHoachMaTran {
                    var coDoi = false
                    for i in 0..<kh.cacO.count {
                        if !kh.cacO[i].daPhat {
                            let khop = KhoCheckInPWADongBo.locCheckIn(choO: kh.cacO[i], cacTuyen: kh.cacTuyen, trong: ds)
                            if !khop.isEmpty {
                                kh.cacO[i].daPhat = true
                                coDoi = true
                            }
                        }
                    }
                    if coDoi {
                        self.keHoachMaTran = kh
                        KhoMaTranPhatToRoi.dungChung.luuKeHoach(kh)
                    }
                }
                self.capNhatNutCheDoTrangThaiPhat()
                self.capNhatGiaoDienMaTran()
                if !imLang {
                    self.hienThongBao(
                        tieuDe: "✅ Đã đồng bộ Check-in PWA",
                        noiDung: "Đã tải \(ds.count) lượt check-in & ảnh từ tab BC-Phát tờ rơi. Bấm “📍 Trạng thái phát” trên bản đồ hoặc “🛡️ Kiểm soát phát” để xem chi tiết."
                    )
                }
            case .failure(let loi):
                if !imLang {
                    self.hienThongBao(tieuDe: "Chưa đồng bộ được PWA", noiDung: loi.localizedDescription)
                }
            }
        }
    }

    private func dongBoLichLenPWANen(hienKetQua: Bool = false) {
        guard let kh = keHoachMaTran, !kh.cacTuyen.isEmpty else { return }
        let dau = danhSachTamDangChonDeQuet().first?.toaDo ?? tamQuet
        BoDongBoCheckInPWA.dungChung.dongBoLichPhanTuyenLenSheet(keHoach: kh, tamToaDo: dau) { [weak self] res in
            guard hienKetQua, let self else { return }
            switch res {
            case .success(let msg):
                self.hienThongBao(tieuDe: "☁️ Đã đẩy lịch & tuyến lên PWA", noiDung: msg + "\n\nNhân viên/PG mở PWA chọn tên mình sẽ thấy ngay tuyến đường & lịch phát tờ rơi riêng.")
            case .failure(let loi):
                self.hienThongBao(tieuDe: "Chưa đẩy được lịch lên PWA", noiDung: loi.localizedDescription)
            }
        }
    }

    @objc private func bamPhongToBanDo() {
        dangPhongToBanDo.toggle()
        rangBuocChieuCaoBanDo?.constant = dangPhongToBanDo ? 560 : 360
        nutPhongToBanDo.setTitle(dangPhongToBanDo ? "⤡ Thu gọn" : "⤢ Rộng", for: .normal)
        UIView.animate(withDuration: 0.22) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func xuLyChamGiuBanDo(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let diem = gesture.location(in: banDo)
        let toaDo = banDo.convert(diem, toCoordinateFrom: banDo)
        tamQuet = toaDo
        tenTamQuet = String(format: "Điểm chọn (%.4f, %.4f)", toaDo.latitude, toaDo.longitude)
        luuTrangThaiTamVaBanKinh()

        // Nếu đang có danh sách siêu thị đã lưu, hỏi nhanh có muốn thêm thẳng điểm vừa chạm vào danh sách hay chỉ dời ghim
        if dsSieuThiDaLuu.contains(where: { $0.dangChon }) {
            let ac = UIAlertController(
                title: "Đã chọn vị trí trên bản đồ",
                message: "Bạn muốn thêm vị trí này vào danh sách siêu thị đang quét hay chỉ đặt làm 1 tâm duy nhất?",
                preferredStyle: .actionSheet
            )
            ac.addAction(UIAlertAction(title: "＋ Thêm vào danh sách siêu thị", style: .default) { [weak self] _ in
                self?.bamLuuViTriSieuThi()
            })
            ac.addAction(UIAlertAction(title: "Chỉ quét 1 tâm tại điểm này", style: .default) { [weak self] _ in
                guard let self = self else { return }
                for i in 0..<self.dsSieuThiDaLuu.count { self.dsSieuThiDaLuu[i].dangChon = false }
                KhoDiaDiemSieuThi.dungChung.luuDanhSach(self.dsSieuThiDaLuu)
                self.dungLaiThanhSieuThiDaLuu()
                self.capNhatTamVaVongTronTrenBanDo(diChuyenCamera: false)
                self.nhanTrangThaiQuet.text = "Đã dời tâm quét tới vị trí mới. Bấm \"Quét khu vực\" để quét."
            })
            ac.addAction(UIAlertAction(title: "Hủy", style: .cancel))
            if let pop = ac.popoverPresentationController {
                pop.sourceView = banDo
                pop.sourceRect = CGRect(origin: diem, size: CGSize(width: 2, height: 2))
            }
            present(ac, animated: true)
        } else {
            capNhatTamVaVongTronTrenBanDo(diChuyenCamera: false)
            nhanTrangThaiQuet.text = "Đã đặt ghim tại vị trí mới. Bấm \"＋ Lưu siêu thị\" để lưu hoặc bấm \"Quét khu vực\"."
        }
    }

    @objc private func bamLayViTriHienTai() {
        view.endEditing(true)
        let status = quanLyViTri.authorizationStatus
        switch status {
        case .notDetermined:
            quanLyViTri.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            nhanTrangThaiQuet.text = "Đang lấy vị trí GPS hiện tại..."
            quanLyViTri.requestLocation()
        case .denied, .restricted:
            hienThongBao(
                tieuDe: "Chưa bật quyền Vị trí",
                noiDung: "Vui lòng vào Cài đặt iPhone > V2 ĐMX > Vị trí để cho phép định vị GPS, hoặc nhập địa chỉ / chạm giữ trực tiếp trên bản đồ."
            )
        @unknown default:
            break
        }
    }

    @objc private func bamTimDiaChi() {
        view.endEditing(true)
        let tuKhoa = (oTimDiaChi.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tuKhoa.isEmpty else { return }

        nhanTrangThaiQuet.text = "Đang tìm vị trí \"\(tuKhoa)\"..."
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = tuKhoa
        req.region = banDo.region
        MKLocalSearch(request: req).start { [weak self] resp, err in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let item = resp?.mapItems.first {
                    self.tamQuet = item.placemark.coordinate
                    self.tenTamQuet = item.name ?? tuKhoa
                    self.luuTrangThaiTamVaBanKinh()
                    // Zoom tới điểm vừa tìm và hiển thị ghim để người dùng bấm Lưu hoặc Quét
                    let spanMet = max(600, self.banKinhMet * 2.55)
                    self.banDo.setRegion(MKCoordinateRegion(center: self.tamQuet, latitudinalMeters: spanMet, longitudinalMeters: spanMet), animated: true)
                    self.capNhatTamVaVongTronTrenBanDo(diChuyenCamera: false)
                    self.nhanTrangThaiQuet.text = "Đã tìm thấy: \(self.tenTamQuet). Bấm \"＋ Lưu siêu thị\" để thêm hoặc bấm \"Quét khu vực\"."
                } else {
                    self.nhanTrangThaiQuet.text = "Không tìm thấy \"\(tuKhoa)\". Thử nhập tên đường kèm quận/tỉnh rõ hơn (\(err?.localizedDescription ?? "không có kết quả"))."
                }
            }
        }
    }

    @objc private func bamQuetKhuVuc() {
        view.endEditing(true)
        guard !dangQuet else { return }

        let soNhap = Double((oNhapBanKinh.text ?? "").filter { $0.isNumber }) ?? banKinhMet
        guard soNhap >= 100 && soNhap <= 20000 else {
            hienThongBao(tieuDe: "Bán kính chưa hợp lệ", noiDung: "Vui lòng nhập bán kính từ 100 mét đến 20.000 mét (20 km).")
            return
        }

        banKinhMet = soNhap
        oNhapBanKinh.text = "\(Int(banKinhMet))"
        capNhatNutBanKinhNhanh()
        luuTrangThaiTamVaBanKinh()
        capNhatTamVaVongTronTrenBanDo(diChuyenCamera: true)

        let cacTamInfo = danhSachTamDangChonDeQuet()
        let cacTamToaDo = cacTamInfo.map { $0.toaDo }
        let diemXuatPhat = cacTamToaDo.first ?? tamQuet

        dangQuet = true
        nutQuetKhuVuc.isEnabled = false
        nutQuetKhuVuc.alpha = 0.65
        vongQuayQuet.startAnimating()
        nhanTrangThaiQuet.text = "Đang quét đối thủ, ĐMX/TGDĐ, trường học, chợ & điểm khác trong bán kính \(Int(banKinhMet)) m..."

        DichVuQuetKhuVuc.dungChung.quetNhieuTam(
            cacTam: cacTamToaDo,
            banKinhMet: banKinhMet,
            capNhatTrangThai: { [weak self] msg in
                self?.nhanTrangThaiQuet.text = msg
            },
            hoanThanh: { [weak self] dsKetQua, nguon in
                guard let self = self else { return }
                self.tatCaDiaDiem = dsKetQua
                self.nguonQuetGanNhat = nguon
                let df = DateFormatter()
                df.locale = Locale(identifier: "vi_VN")
                df.dateFormat = "HH:mm dd/MM/yyyy"
                self.thoiGianQuetGanNhat = df.string(from: Date())
                self.capNhatThongKeKPI()

                if dsKetQua.isEmpty {
                    self.ketQuaTuyen = nil
                    self.ketThucQuet(thongBao: "Không tìm thấy địa điểm nào trong bán kính \(Int(self.banKinhMet)) m. Thử tăng bán kính lên nhé!")
                    return
                }

                let bkPhat = self.cauHinhPhanTuyen.banKinhPhatHieuLuc(banKinhQuetMet: self.banKinhMet)
                let tenXuatPhat = self.tenXuatPhatHienTai()
                self.nhanTrangThaiQuet.text = "Đã tìm thấy \(dsKetQua.count) địa điểm. Đang tính tuyến đường bám sát bản đồ (bán kính phát \(Int(bkPhat))m)..."
                BoToiUuTuyenPhatToRoi.dungChung.tinhTuyenHieuQuaNhat(
                    tam: diemXuatPhat,
                    tenDiemXuatPhat: tenXuatPhat,
                    danhSach: dsKetQua,
                    banKinhMet: bkPhat
                ) { [weak self] tuyen in
                    guard let self = self else { return }
                    self.ketQuaTuyen = tuyen
                    let soDT = dsKetQua.filter { $0.loai == .doiThu }.count
                    let soMWG = dsKetQua.filter { $0.loai == .heThongMWG }.count
                    let soTH = dsKetQua.filter { $0.loai == .truongHoc }.count
                    let soCho = dsKetQua.filter { $0.loai == .cho }.count
                    let soKhac = dsKetQua.filter { $0.loai == .khac }.count
                    let chuoiNguon = nguon.isEmpty ? "" : " • Nguồn: \(nguon.joined(separator: ", "))"
                    let nhanTam = cacTamInfo.count > 1 ? "\(cacTamInfo.count) điểm, bán kính \(Int(self.banKinhMet))m" : "bán kính \(Int(self.banKinhMet))m"
                    self.ketThucQuet(
                        thongBao: "Hoàn tất lúc \(self.thoiGianQuetGanNhat) (\(nhanTam)): \(soDT) đối thủ, \(soMWG) ĐMX/TGDĐ, \(soTH) trường, \(soCho) chợ, \(soKhac) khác\(chuoiNguon)."
                    )
                }
            }
        )
    }

    private func luuKetQuaQuetVaoBoNho(thongBao: String) {
        let dau = danhSachTamDangChonDeQuet().first?.toaDo ?? tamQuet
        let banLuu = KetQuaQuetKhuVucLuu(
            tatCaDiaDiem: tatCaDiaDiem,
            banKinhQuetMet: banKinhMet,
            tenTamQuet: tenXuatPhatHienTai(),
            tamLat: dau.latitude,
            tamLon: dau.longitude,
            nguonQuet: nguonQuetGanNhat,
            thoiGianQuet: thoiGianQuetGanNhat,
            thongBaoTrangThai: thongBao,
            ketQuaTuyen: ketQuaTuyen?.sangBanLuu()
        )
        thongBaoQuetLuu = thongBao
        KhoKetQuaQuetKhuVuc.dungChung.luuKetQua(banLuu)
    }

    private func ketThucQuet(thongBao: String) {
        dangQuet = false
        nutQuetKhuVuc.isEnabled = true
        nutQuetKhuVuc.alpha = 1.0
        vongQuayQuet.stopAnimating()
        nhanTrangThaiQuet.text = thongBao
        luuKetQuaQuetVaoBoNho(thongBao: thongBao)
        veLaiGhimVaTuyenTrenBanDo()
        capNhatKhungTuyenPhatToRoi()
        if !tatCaDiaDiem.isEmpty {
            bamTaoMaTranXoayVong()
        }
    }

    private func capNhatThongKeKPI() {
        let soDT = tatCaDiaDiem.filter { $0.loai == .doiThu }.count
        let soMWG = tatCaDiaDiem.filter { $0.loai == .heThongMWG }.count
        let soTH = tatCaDiaDiem.filter { $0.loai == .truongHoc }.count
        let soCho = tatCaDiaDiem.filter { $0.loai == .cho }.count
        let soKhac = tatCaDiaDiem.filter { $0.loai == .khac }.count

        nhanSoTatCa.text = "\(tatCaDiaDiem.count)"
        nhanSoDoiThu.text = "\(soDT)"
        nhanSoMWG.text = "\(soMWG)"
        nhanSoTruongHoc.text = "\(soTH)"
        nhanSoCho.text = "\(soCho)"
        nhanSoKhac.text = "\(soKhac)"
    }

    private func capNhatKhungTuyenPhatToRoi() {
        nganChonTuyenChiDan.arrangedSubviews.forEach {
            nganChonTuyenChiDan.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let cacTuyen = (keHoachMaTran?.cacTuyen ?? []).filter { $0.cacToaDo.count >= 2 }
        let coTuyenDon = (ketQuaTuyen != nil && !(ketQuaTuyen?.cacDiemDung.isEmpty ?? true))

        guard !cacTuyen.isEmpty || coTuyenDon else {
            khungTuyenToRoi.isHidden = true
            return
        }

        khungTuyenToRoi.isHidden = false
        let bkPhat = cauHinhPhanTuyen.banKinhPhatHieuLuc(banKinhQuetMet: banKinhMet)
        nhanKhungGioVang.text = "  ⏰ Khung giờ vàng: Sáng 06:30–09:00 (Chợ + Trường) • Chiều 16:00–18:00 (Tan trường + Chợ chiều + Đối thủ)"

        if !cacTuyen.isEmpty {
            cuonChonTuyenChiDan.isHidden = false
            for t in cacTuyen {
                let dangChon = (tuyenDangLocTrenBanDo == t.id)
                let nut = UIButton(type: .system)
                nut.setTitle(dangChon ? "✓ \(t.ten)" : "● \(t.ten)", for: .normal)
                nut.titleLabel?.font = .systemFont(ofSize: 12, weight: .heavy)
                nut.setTitleColor(dangChon ? .white : t.mauTuyen, for: .normal)
                nut.backgroundColor = dangChon ? t.mauTuyen : BangMauBCTD.nenThePhu
                nut.layer.cornerRadius = 9
                nut.layer.borderWidth = 1.4
                nut.layer.borderColor = t.mauTuyen.cgColor
                nut.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
                nut.accessibilityIdentifier = t.id
                nut.addTarget(self, action: #selector(bamChonTuyenTrongKhungChiDan(_:)), for: .touchUpInside)
                nganChonTuyenChiDan.addArrangedSubview(nut)
            }

            if let locID = tuyenDangLocTrenBanDo,
               let tuyenChon = cacTuyen.first(where: { $0.id == locID }) {
                let xuatPhat = tuyenChon.tenDiemXuatPhat.isEmpty ? tenXuatPhatHienTai() : tuyenChon.tenDiemXuatPhat
                let km = BoDanDuongTuyenThucTe.dinhDangKhoangCach(tuyenChon.tongQuangDuongMet)
                let xm = BoDanDuongTuyenThucTe.dinhDangPhut(tuyenChon.thoiGianXeMayPhut)
                let db = BoDanDuongTuyenThucTe.dinhDangPhut(tuyenChon.thoiGianDiBoPhut)
                let trangThai = tuyenChon.laDuongThucTe ? "bám sát đường thực tế" : "đang bám đường thực tế..."
                let dsQua = tuyenChon.cacDiemMucTieu.isEmpty
                    ? tuyenChon.moTaDiemNong
                    : tuyenChon.cacDiemMucTieu.prefix(5).map { $0.ten }.joined(separator: " → ") + (tuyenChon.cacDiemMucTieu.count > 5 ? " (+\(tuyenChon.cacDiemMucTieu.count - 5))" : "")

                nhanTieuDeKhungTuyen.text = "🛣️ \(tuyenChon.ten.uppercased()) ĐANG CHỌN"
                nhanTieuDeKhungTuyen.textColor = tuyenChon.mauTuyen
                khungTuyenToRoi.layer.borderColor = tuyenChon.mauTuyen.withAlphaComponent(0.7).cgColor
                nhanTomTatTuyen.text = """
                🚩 Xuất phát: \(xuatPhat) • Bán kính phát: \(BoDanDuongTuyenThucTe.dinhDangKhoangCach(bkPhat))
                📏 Quãng đường: \(km) (\(trangThai))
                🛵 Xe máy: ~\(xm)  |  🚶 Đi bộ: ~\(db)
                📍 Đi qua (\(tuyenChon.cacDiemMucTieu.count) điểm): \(dsQua)
                """
                nutChiDanTuyenToiUu.setTitle("🧭 Xem chỉ dẫn rẽ trái/phải — \(tuyenChon.ten)", for: .normal)
                nutChiDanTuyenToiUu.backgroundColor = tuyenChon.mauTuyen
                nutMoGoogleMapsTuyen.setTitle("🗺️ GG Maps (\(tuyenChon.ten))", for: .normal)
            } else {
                nhanTieuDeKhungTuyen.text = "🛣️ CHỌN TUYẾN & XEM CHỈ DẪN PHÁT TỜ RƠI"
                nhanTieuDeKhungTuyen.textColor = BangMauBCTD.xanhDatChu
                khungTuyenToRoi.layer.borderColor = BangMauBCTD.xanhDatVach.withAlphaComponent(0.45).cgColor
                nhanTomTatTuyen.text = """
                🚩 Xuất phát: \(tenXuatPhatHienTai()) • Bán kính phát: \(BoDanDuongTuyenThucTe.dinhDangKhoangCach(bkPhat))
                👆 Hãy chạm chọn 1 tuyến ở hàng trên (\(cacTuyen.map { $0.ten }.joined(separator: ", "))) rồi bấm “Xem chỉ dẫn rẽ trái/phải” để dẫn đường chi tiết theo đúng tuyến đó.
                """
                nutChiDanTuyenToiUu.setTitle("🧭 Chọn tuyến ở trên để xem chỉ dẫn rẽ trái/phải", for: .normal)
                nutChiDanTuyenToiUu.backgroundColor = BangMauBCTD.xanhChuDao.withAlphaComponent(0.75)
                nutMoGoogleMapsTuyen.setTitle("🗺️ Dẫn đường GG Maps", for: .normal)
            }
        } else if let tuyen = ketQuaTuyen {
            cuonChonTuyenChiDan.isHidden = true
            let km = BoDanDuongTuyenThucTe.dinhDangKhoangCach(tuyen.tongQuangDuongMet)
            let xm = BoDanDuongTuyenThucTe.dinhDangPhut(tuyen.thoiGianXeMayPhut)
            let db = BoDanDuongTuyenThucTe.dinhDangPhut(tuyen.thoiGianDiBoPhut)
            let cheDoDuong = tuyen.laDuongThucTe ? "bám sát đường thực tế" : "ước lượng"
            nhanTieuDeKhungTuyen.text = "🛣️ TUYẾN ĐƯỜNG PHÁT TỜ RƠI HIỆU QUẢ NHẤT"
            nhanTieuDeKhungTuyen.textColor = BangMauBCTD.xanhDatChu
            nhanTomTatTuyen.text = """
            🚩 Xuất phát: \(tenXuatPhatHienTai()) • Bán kính phát: \(BoDanDuongTuyenThucTe.dinhDangKhoangCach(bkPhat))
            📏 Quãng đường: \(km) (\(cheDoDuong))
            🛵 Xe máy: ~\(xm)  |  🚶 Đi bộ: ~\(db)
            📍 Đi qua \(tuyen.cacDiemDung.count) điểm nóng
            """
            nutChiDanTuyenToiUu.setTitle("🧭 Xem chỉ dẫn rẽ trái/phải & Xuất ảnh", for: .normal)
            nutChiDanTuyenToiUu.backgroundColor = BangMauBCTD.xanhChuDao
            nutMoGoogleMapsTuyen.setTitle("🗺️ Dẫn đường GG Maps", for: .normal)
        }
    }

    @objc private func bamChonTuyenTrongKhungChiDan(_ sender: UIButton) {
        guard let id = sender.accessibilityIdentifier else { return }
        tuyenDangLocTrenBanDo = (tuyenDangLocTrenBanDo == id) ? nil : id
        hienTuyenToRoi = true
        nutBatTatTuyen.setTitle("🛣️ Tuyến: Bật", for: .normal)
        nutBatTatTuyen.backgroundColor = BangMauBCTD.xanhDatVach.withAlphaComponent(0.94)
        dungLaiThanhChuThichTuyen()
        capNhatKhungChiTietTuyenDangChon()
        capNhatKhungTuyenPhatToRoi()
        veLaiGhimVaTuyenTrenBanDo()
        if let loc = tuyenDangLocTrenBanDo {
            zoomVaoTuyen(id: loc)
        }
    }

    @objc private func bamTheKPI(_ sender: UIControl) {
        let loc = BoLocPopupKhuVuc(rawValue: sender.tag) ?? .tatCa
        moPopupChiTietKhuVuc(boLocMacDinh: loc)
    }

    private func moPopupChiTietKhuVuc(boLocMacDinh: BoLocPopupKhuVuc) {
        guard !tatCaDiaDiem.isEmpty else {
            hienThongBao(
                tieuDe: "Chưa có dữ liệu quét khu vực",
                noiDung: "Hãy nhập bán kính rồi bấm “🔍 Quét khu vực”. Dữ liệu sau khi quét sẽ được lưu giữ cố định cho những lần mở app tiếp theo."
            )
            return
        }
        let tg = thoiGianQuetGanNhat.isEmpty ? "Mới nhất" : thoiGianQuetGanNhat
        let vc = HopChiTietKhuVucQuetViewController(
            tatCaDiaDiem: tatCaDiaDiem,
            tenTamQuet: tenXuatPhatHienTai(),
            banKinhMet: banKinhMet,
            thoiGianQuet: tg,
            boLocMacDinh: boLocMacDinh,
            khiChonDiaDiem: { [weak self] diem in
                self?.focusDiaDiemTrenBanDo(diem)
            },
            khiMoGoogleMaps: { [weak self] diem in
                self?.moGoogleMapsDanDuong(den: diem.toaDo)
            }
        )
        let nav = UINavigationController(rootViewController: vc)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    private func focusDiaDiemTrenBanDo(_ diem: DiaDiemQuet) {
        let region = MKCoordinateRegion(center: diem.toaDo, latitudinalMeters: 650, longitudinalMeters: 650)
        banDo.setRegion(region, animated: true)

        if let ann = banDo.annotations.compactMap({ $0 as? GhimDiaDiemAnnotation }).first(where: { $0.diaDiem.id == diem.id }) {
            banDo.selectAnnotation(ann, animated: true)
        }
        cuonChinh.setContentOffset(CGPoint(x: 0, y: max(0, khungBanDo.frame.minY - 8)), animated: true)
    }

    @objc private func bamChonDongDiaDiem(_ sender: UIControl) {
        guard let id = sender.accessibilityIdentifier,
              let diem = tatCaDiaDiem.first(where: { $0.id == id }) else { return }
        focusDiaDiemTrenBanDo(diem)
    }

    private func moGoogleMapsDanDuong(den: CLLocationCoordinate2D) {
        let dau = danhSachTamDangChonDeQuet().first?.toaDo ?? tamQuet
        let origin = "\(dau.latitude),\(dau.longitude)"
        let dest = "\(den.latitude),\(den.longitude)"
        let webStr = "https://www.google.com/maps/dir/?api=1&origin=\(origin)&destination=\(dest)&travelmode=driving"
        if let url = URL(string: webStr) {
            UIApplication.shared.open(url)
        }
    }

    private func moGoogleMapsChoTuyen(_ tuyen: TuyenPhatToRoiMaTran) {
        guard !tuyen.cacDiemMucTieu.isEmpty else { return }
        let dau = danhSachTamDangChonDeQuet().first?.toaDo ?? tamQuet
        let origin = "\(dau.latitude),\(dau.longitude)"
        let ds = tuyen.cacDiemMucTieu
        guard let diemCuoi = ds.last else { return }
        let dest = "\(diemCuoi.viDo),\(diemCuoi.kinhDo)"
        let trungGian = Array(ds.dropLast().prefix(9))
        var urlStr = "https://www.google.com/maps/dir/?api=1&origin=\(origin)&destination=\(dest)&travelmode=driving"
        if !trungGian.isEmpty {
            let wp = trungGian.map { "\($0.viDo),\($0.kinhDo)" }.joined(separator: "|")
            if let encodedWP = wp.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                urlStr += "&waypoints=\(encodedWP)"
            }
        }
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url)
        }
    }

    @objc private func bamXemChiDanTuyenToiUu() {
        let cacTuyen = (keHoachMaTran?.cacTuyen ?? []).filter { $0.cacToaDo.count >= 2 }
        if !cacTuyen.isEmpty {
            // Bắt buộc chỉ dẫn theo đúng tuyến đang chọn; nếu chưa chọn tuyến thì mở menu chọn tuyến ngay!
            if let locID = tuyenDangLocTrenBanDo,
               let tuyenChon = cacTuyen.first(where: { $0.id == locID }) {
                moPopupChiTietTuyen(tuyenChon)
                return
            }
            let ac = UIAlertController(
                title: "Chọn tuyến xem chỉ dẫn rẽ trái/phải",
                message: "Hãy chọn 1 tuyến phát tờ rơi bên dưới để xem lộ trình chi tiết (xuất phát, rẽ trái/rẽ phải, xe máy/đi bộ).",
                preferredStyle: .actionSheet
            )
            for t in cacTuyen {
                let km = BoDanDuongTuyenThucTe.dinhDangKhoangCach(t.tongQuangDuongMet)
                ac.addAction(UIAlertAction(title: "🛣️ \(t.ten) (\(km) • \(t.cacDiemMucTieu.count) điểm)", style: .default) { [weak self] _ in
                    guard let self else { return }
                    self.tuyenDangLocTrenBanDo = t.id
                    self.dungLaiThanhChuThichTuyen()
                    self.capNhatKhungTuyenPhatToRoi()
                    self.veLaiGhimVaTuyenTrenBanDo()
                    self.zoomVaoTuyen(id: t.id)
                    self.moPopupChiTietTuyen(t)
                })
            }
            ac.addAction(UIAlertAction(title: "Đóng", style: .cancel))
            if let pop = ac.popoverPresentationController {
                pop.sourceView = nutChiDanTuyenToiUu
                pop.sourceRect = nutChiDanTuyenToiUu.bounds
            }
            present(ac, animated: true)
            return
        }

        guard let kq = ketQuaTuyen, !kq.cacDiemDung.isEmpty else { return }
        let dau = danhSachTamDangChonDeQuet().first?.toaDo ?? tamQuet
        let dsDiem = kq.cacDiemDung.map {
            DiemMucTieuTuyen(id: $0.id, ten: $0.ten, diaChi: $0.diaChi, loaiRaw: $0.loai.tieuDe, viDo: $0.viDo, kinhDo: $0.kinhDo)
        }
        var waypoints: [[Double]] = [[dau.latitude, dau.longitude]]
        waypoints.append(contentsOf: dsDiem.map { [$0.viDo, $0.kinhDo] })
        let tuyenAo = TuyenPhatToRoiMaTran(
            id: "tuyen_toi_uu",
            soThuTu: 1,
            ten: "Tuyến hiệu quả nhất",
            moTaDiemNong: "\(dsDiem.count) điểm nóng tối ưu",
            soDiemNong: dsDiem.count,
            cacToaDo: waypoints,
            cacDiemMucTieu: dsDiem,
            tenDiemXuatPhat: tenXuatPhatHienTai(),
            toaDoDuongThucTe: kq.toaDoDuongDi.map { [$0.latitude, $0.longitude] },
            laDuongThucTe: kq.laDuongThucTe,
            tongQuangDuongMet: kq.tongQuangDuongMet,
            thoiGianXeMayPhut: kq.thoiGianXeMayPhut,
            thoiGianDiBoPhut: kq.thoiGianDiBoPhut,
            chiDanTungBuoc: kq.chiDanTungBuoc
        )
        moPopupChiTietTuyen(tuyenAo)
    }

    @objc private func bamMoGoogleMapsTuyen() {
        if let locID = tuyenDangLocTrenBanDo,
           let tuyenChon = keHoachMaTran?.cacTuyen.first(where: { $0.id == locID }) {
            moGoogleMapsChoTuyen(tuyenChon)
            return
        }
        guard let tuyen = ketQuaTuyen, !tuyen.cacDiemDung.isEmpty else { return }
        let dau = danhSachTamDangChonDeQuet().first?.toaDo ?? tamQuet
        let origin = "\(dau.latitude),\(dau.longitude)"
        let ds = tuyen.cacDiemDung
        guard let diemCuoi = ds.last else { return }
        let dest = "\(diemCuoi.viDo),\(diemCuoi.kinhDo)"

        let trungGian = Array(ds.dropLast().prefix(9))
        var urlStr = "https://www.google.com/maps/dir/?api=1&origin=\(origin)&destination=\(dest)&travelmode=driving"
        if !trungGian.isEmpty {
            let wp = trungGian.map { "\($0.viDo),\($0.kinhDo)" }.joined(separator: "|")
            if let encodedWP = wp.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                urlStr += "&waypoints=\(encodedWP)"
            }
        }
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url)
        }
    }

    @objc private func bamCopyKeHoach() {
        let soDT = tatCaDiaDiem.filter { $0.loai == .doiThu }.count
        let soMWG = tatCaDiaDiem.filter { $0.loai == .heThongMWG }.count
        let soTH = tatCaDiaDiem.filter { $0.loai == .truongHoc }.count
        let soCho = tatCaDiaDiem.filter { $0.loai == .cho }.count
        let soKhac = tatCaDiaDiem.filter { $0.loai == .khac }.count
        let dsTenTam = danhSachTamDangChonDeQuet().map { $0.ten }.joined(separator: ", ")
        let bkPhat = cauHinhPhanTuyen.banKinhPhatHieuLuc(banKinhQuetMet: banKinhMet)

        var dong: [String] = [
            "📍 BÁO CÁO QUÉT KHU VỰC & TUYẾN PHÁT TỜ RƠI",
            "• Tâm quét: \(dsTenTam)",
            "• Bán kính quét: \(Int(banKinhMet)) m • Bán kính phát tờ rơi: \(Int(bkPhat)) m",
            "• Đối thủ điện máy/gia dụng: \(soDT)",
            "• Cửa hàng ĐMX / TGDĐ: \(soMWG)",
            "• Trường học: \(soTH)",
            "• Chợ: \(soCho)",
            "• Khác (ăn uống, shop, thú cưng...): \(soKhac)"
        ]

        if let tuyen = ketQuaTuyen, !tuyen.cacDiemDung.isEmpty {
            dong.append("")
            dong.append("🛣️ TUYẾN PHÁT TỜ RƠI HIỆU QUẢ NHẤT (\(BoDanDuongTuyenThucTe.dinhDangKhoangCach(tuyen.tongQuangDuongMet)) • 🛵 Xe máy ~\(BoDanDuongTuyenThucTe.dinhDangPhut(tuyen.thoiGianXeMayPhut)) • 🚶 Đi bộ ~\(BoDanDuongTuyenThucTe.dinhDangPhut(tuyen.thoiGianDiBoPhut))):")
            for (idx, d) in tuyen.cacDiemDung.enumerated() {
                let kc = Int(round(d.khoangCachMet))
                dong.append("\(idx + 1). [\(d.loai.tieuDe)] \(d.ten) (cách tâm \(kc)m)")
            }
            dong.append("⏰ Khung giờ vàng: Sáng 06:30–09:00 (Chợ + Trường) | Chiều 16:00–18:00 (Tan trường + Chợ chiều + Khu đối thủ)")
        }

        UIPasteboard.general.string = dong.joined(separator: "\n")
        hienThongBao(tieuDe: "Đã sao chép", noiDung: "Đã sao chép báo cáo quét khu vực và tuyến phát tờ rơi để dán vào nhóm LINE/Zalo.")
    }

    @objc private func bamCaiDatGoogleKey() {
        let alert = UIAlertController(
            title: "Google Places API Key (Tùy chọn)",
            message: "Ứng dụng đã tự động quét miễn phí qua Bản đồ địa điểm & OpenStreetMap. Nếu bạn có Google Maps Places API Key, nhập vào đây để tăng thêm độ phủ dữ liệu từ Google.",
            preferredStyle: .alert
        )
        alert.addTextField { tf in
            tf.placeholder = "AIzaSy..."
            tf.text = DichVuQuetKhuVuc.dungChung.googleApiKey
            tf.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: "Lưu", style: .default) { _ in
            let key = alert.textFields?.first?.text ?? ""
            DichVuQuetKhuVuc.dungChung.googleApiKey = key
        })
        alert.addAction(UIAlertAction(title: "Xóa Key", style: .destructive) { _ in
            DichVuQuetKhuVuc.dungChung.googleApiKey = ""
        })
        alert.addAction(UIAlertAction(title: "Đóng", style: .cancel))
        present(alert, animated: true)
    }

    private func hienThongBao(tieuDe: String, noiDung: String) {
        let ac = UIAlertController(title: tieuDe, message: noiDung, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === oTimDiaChi {
            bamTimDiaChi()
            return true
        }
        if textField === oLinkTrangTinh {
            bamTaiTrangTinh()
            return true
        }
        textField.resignFirstResponder()
        return true
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        tamQuet = loc.coordinate
        tenTamQuet = "Vị trí hiện tại của bạn"
        luuTrangThaiTamVaBanKinh()
        capNhatTamVaVongTronTrenBanDo(diChuyenCamera: true)
        nhanTrangThaiQuet.text = "Đã định vị GPS thành công. Bấm \"＋ Lưu siêu thị\" hoặc \"Quét khu vực\"."
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        nhanTrangThaiQuet.text = "Không lấy được GPS lúc này (\(error.localizedDescription)). Bạn có thể tìm địa chỉ hoặc chạm giữ bản đồ."
    }

    // MARK: - MKMapViewDelegate

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let tile = overlay as? MKTileOverlay {
            return MKTileOverlayRenderer(tileOverlay: tile)
        }
        if let circle = overlay as? VongBanKinhToRoiCircle {
            let r = MKCircleRenderer(circle: circle)
            r.fillColor = BangMauBCTD.xanhDatVach.withAlphaComponent(0.08)
            r.strokeColor = BangMauBCTD.xanhDatVach.withAlphaComponent(0.95)
            r.lineWidth = 2.6
            r.lineDashPattern = [8, 5]
            return r
        }
        if let circle = overlay as? MKCircle {
            let r = MKCircleRenderer(circle: circle)
            r.fillColor = BangMauBCTD.xanhChuDao.withAlphaComponent(0.11)
            r.strokeColor = BangMauBCTD.xanhChuDao.withAlphaComponent(0.85)
            r.lineWidth = 2.2
            r.lineDashPattern = [6, 4]
            return r
        }
        if let poly = overlay as? TuyenPhatToRoiPolyline {
            let r = MKPolylineRenderer(polyline: poly)
            if poly.laVienNen {
                r.strokeColor = UIColor.white.withAlphaComponent(0.95)
                r.lineWidth = 7.5
            } else {
                r.strokeColor = poly.mauTuyen
                r.lineWidth = 4.6
            }
            r.lineJoin = .round
            r.lineCap = .round
            return r
        }
        if let poly = overlay as? MKPolyline {
            let r = MKPolylineRenderer(polyline: poly)
            r.strokeColor = BangMauBCTD.xanhDatVach
            r.lineWidth = 4.2
            return r
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }

        if let pwaAnn = annotation as? GhimCheckInPWAAnnotation {
            let id = KhungGhimCheckInPWAView.maTaiSuDung
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? KhungGhimCheckInPWAView)
                ?? KhungGhimCheckInPWAView(annotation: pwaAnn, reuseIdentifier: id)
            view.annotation = pwaAnn
            let mauTuyen: UIColor? = {
                if let stt = pwaAnn.banGhi.soThuTuTuyen {
                    return keHoachMaTran?.cacTuyen.first(where: { $0.soThuTu == stt })?.mauTuyen
                }
                return nil
            }()
            view.capNhat(voi: pwaAnn, mauTuyen: mauTuyen)
            return view
        }

        if let bcAnn = annotation as? GhimBangChungAnnotation {
            let id = "GhimBangChungToRoi"
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView)
                ?? MKMarkerAnnotationView(annotation: bcAnn, reuseIdentifier: id)
            view.annotation = bcAnn
            let hopLe = bcAnn.bangChung.trangThaiViTri.hopLe
            view.markerTintColor = hopLe ? BangMauBCTD.xanhLaDam : .systemRed
            view.glyphTintColor = .white
            view.glyphText = nil
            view.glyphImage = UIImage(systemName: hopLe ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
            view.displayPriority = .required
            view.canShowCallout = true
            return view
        }

        if let nhanTuyen = annotation as? GhimNhanTuyenAnnotation {
            let id = "GhimNhanTuyen"
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView)
                ?? MKMarkerAnnotationView(annotation: nhanTuyen, reuseIdentifier: id)
            view.annotation = nhanTuyen
            view.markerTintColor = nhanTuyen.mauTuyen
            view.glyphTintColor = .white
            view.glyphText = "T\(nhanTuyen.soThuTu)"
            view.glyphImage = nil
            view.displayPriority = .required
            view.canShowCallout = true
            return view
        }

        if let tamAnn = annotation as? GhimTamQuetAnnotation {
            let id = "GhimTamQuet"
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView)
                ?? MKMarkerAnnotationView(annotation: tamAnn, reuseIdentifier: id)
            view.annotation = tamAnn
            view.markerTintColor = BangMauBCTD.vangChuDao
            view.glyphTintColor = BangMauBCTD.xanhChuDaoDam
            view.glyphImage = UIImage(systemName: tamAnn.laSieuThiDaLuu ? "building.2.fill" : "star.fill")
            view.displayPriority = .required
            view.canShowCallout = true
            return view
        }

        if let ddAnn = annotation as? GhimDiaDiemAnnotation {
            let id = "GhimDiaDiem"
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView)
                ?? MKMarkerAnnotationView(annotation: ddAnn, reuseIdentifier: id)
            view.annotation = ddAnn
            view.markerTintColor = ddAnn.diaDiem.loai.mauChuDao
            view.glyphTintColor = .white
            if let stt = ddAnn.diaDiem.soThuTuTuyen {
                view.glyphText = "\(stt)"
                view.glyphImage = nil
                view.displayPriority = .required
            } else {
                view.glyphText = nil
                view.glyphImage = UIImage(systemName: ddAnn.diaDiem.loai.bieuTuongSF)
                view.displayPriority = .defaultHigh
            }
            view.canShowCallout = true

            let nutChiDuong = UIButton(type: .detailDisclosure)
            nutChiDuong.setImage(UIImage(systemName: "arrow.triangle.turn.up.right.diamond.fill"), for: .normal)
            nutChiDuong.tintColor = BangMauBCTD.xanhChuDao
            view.rightCalloutAccessoryView = nutChiDuong
            return view
        }

        return nil
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let ddAnn = view.annotation as? GhimDiaDiemAnnotation {
            moGoogleMapsDanDuong(den: ddAnn.diaDiem.toaDo)
        }
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let pwaAnn = view.annotation as? GhimCheckInPWAAnnotation {
            mapView.deselectAnnotation(pwaAnn, animated: false)
            moChiTietCheckInPWA(pwaAnn.banGhi)
        }
    }

    private func moChiTietCheckInPWA(_ bc: BanGhiCheckInPWA) {
        let vc = HopChiTietCheckInPWAViewController(banGhi: bc) { [weak self] bg in
            self?.zoomDenGhimCheckInPWA(bg)
        }
        let nav = UINavigationController(rootViewController: vc)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    // MARK: - Thẻ Ma Trận Phát Tờ Rơi Xoay Vòng & Đồng Bộ Google Trang Tính (1 Link Chung PG + NV)

    private func taoTheMaTranPhatToRoi() -> UIView {
        khungMaTranToRoi.backgroundColor = BangMauBCTD.nenThe
        khungMaTranToRoi.layer.cornerRadius = 14
        khungMaTranToRoi.layer.borderWidth = 1.2
        khungMaTranToRoi.layer.borderColor = BangMauBCTD.xanhChuDao.withAlphaComponent(0.4).cgColor

        let tieuDe = UILabel()
        tieuDe.text = "📅 MA TRẬN PHÁT TỜ RƠI XOAY VÒNG"
        tieuDe.font = .systemFont(ofSize: 13, weight: .heavy)
        tieuDe.textColor = BangMauBCTD.xanhChuDaoDam
        tieuDe.numberOfLines = 0
        tieuDe.lineBreakMode = .byWordWrapping
        tieuDe.adjustsFontSizeToFitWidth = false

        nutNhacChuNhat.titleLabel?.font = .systemFont(ofSize: 11, weight: .bold)
        nutNhacChuNhat.layer.cornerRadius = 8
        nutNhacChuNhat.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        nutNhacChuNhat.setContentHuggingPriority(.required, for: .horizontal)
        nutNhacChuNhat.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutNhacChuNhat.addTarget(self, action: #selector(bamBatTatNhacChuNhat), for: .touchUpInside)

        let hangDau = UIStackView(arrangedSubviews: [tieuDe, UIView(), nutNhacChuNhat])
        hangDau.axis = .horizontal
        hangDau.alignment = .center
        hangDau.spacing = 6

        nhanNhacTuyenChuaPhat.font = .systemFont(ofSize: 12, weight: .bold)
        nhanNhacTuyenChuaPhat.numberOfLines = 0
        nhanNhacTuyenChuaPhat.lineBreakMode = .byWordWrapping
        nhanNhacTuyenChuaPhat.adjustsFontSizeToFitWidth = false
        nhanNhacTuyenChuaPhat.layer.cornerRadius = 9
        nhanNhacTuyenChuaPhat.clipsToBounds = true

        // 1 ô duy nhất nhập link Google Trang tính (tự đọc đồng thời cả tab Lịch PG & tab TEAM NV.)
        let khungLinkTrangTinh = UIView()
        khungLinkTrangTinh.backgroundColor = BangMauBCTD.nenHeaderPhu
        khungLinkTrangTinh.layer.cornerRadius = 11
        khungLinkTrangTinh.layer.borderWidth = 1
        khungLinkTrangTinh.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor

        let nhanTieuDeLink = UILabel()
        nhanTieuDeLink.text = "📗 Link Google Trang tính lịch làm việc (PG & Nhân viên)"
        nhanTieuDeLink.font = .systemFont(ofSize: 12, weight: .bold)
        nhanTieuDeLink.textColor = BangMauBCTD.xanhChuDaoDam
        nhanTieuDeLink.numberOfLines = 0
        nhanTieuDeLink.lineBreakMode = .byWordWrapping
        nhanTieuDeLink.adjustsFontSizeToFitWidth = false

        oLinkTrangTinh.placeholder = "Dán link Google Trang tính (tab PG & NV)..."
        oLinkTrangTinh.text = KhoMaTranPhatToRoi.dungChung.layLinkTrangTinhChung()
        oLinkTrangTinh.font = .systemFont(ofSize: 13, weight: .medium)
        oLinkTrangTinh.textColor = BangMauBCTD.chuChinh
        oLinkTrangTinh.backgroundColor = BangMauBCTD.nenThe
        oLinkTrangTinh.layer.cornerRadius = 9
        oLinkTrangTinh.layer.borderWidth = 1
        oLinkTrangTinh.layer.borderColor = BangMauBCTD.vienDam.cgColor
        oLinkTrangTinh.keyboardType = .URL
        oLinkTrangTinh.autocapitalizationType = .none
        oLinkTrangTinh.autocorrectionType = .no
        oLinkTrangTinh.clearButtonMode = .whileEditing
        oLinkTrangTinh.returnKeyType = .go
        oLinkTrangTinh.delegate = self
        oLinkTrangTinh.leftView = UIView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(10), height: CGFloat(10)))
        oLinkTrangTinh.leftViewMode = .always
        oLinkTrangTinh.heightAnchor.constraint(equalToConstant: 40).isActive = true

        nutDanLinkTrangTinh.setTitle("📋 Dán & Tải", for: .normal)
        nutDanLinkTrangTinh.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        nutDanLinkTrangTinh.titleLabel?.numberOfLines = 0
        nutDanLinkTrangTinh.titleLabel?.lineBreakMode = .byWordWrapping
        nutDanLinkTrangTinh.titleLabel?.adjustsFontSizeToFitWidth = false
        nutDanLinkTrangTinh.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
        nutDanLinkTrangTinh.backgroundColor = BangMauBCTD.nenThe
        nutDanLinkTrangTinh.layer.cornerRadius = 9
        nutDanLinkTrangTinh.layer.borderWidth = 1
        nutDanLinkTrangTinh.layer.borderColor = BangMauBCTD.vienDam.cgColor
        nutDanLinkTrangTinh.contentEdgeInsets = UIEdgeInsets(top: 9, left: 10, bottom: 9, right: 10)
        nutDanLinkTrangTinh.setContentHuggingPriority(.required, for: .horizontal)
        nutDanLinkTrangTinh.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutDanLinkTrangTinh.addTarget(self, action: #selector(bamDanVaTaiTrangTinh), for: .touchUpInside)

        nutTaiTrangTinh.setTitle("🔄 Tải lịch PG & NV", for: .normal)
        nutTaiTrangTinh.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .heavy)
        nutTaiTrangTinh.titleLabel?.numberOfLines = 0
        nutTaiTrangTinh.titleLabel?.lineBreakMode = .byWordWrapping
        nutTaiTrangTinh.titleLabel?.adjustsFontSizeToFitWidth = false
        nutTaiTrangTinh.setTitleColor(.white, for: .normal)
        nutTaiTrangTinh.backgroundColor = BangMauBCTD.xanhDatVach
        nutTaiTrangTinh.layer.cornerRadius = 9
        nutTaiTrangTinh.contentEdgeInsets = UIEdgeInsets(top: 9, left: 10, bottom: 9, right: 10)
        nutTaiTrangTinh.addTarget(self, action: #selector(bamTaiTrangTinh), for: .touchUpInside)

        vongQuayTrangTinh.color = BangMauBCTD.xanhChuDao
        vongQuayTrangTinh.hidesWhenStopped = true

        let hangNutTrangTinh = UIStackView(arrangedSubviews: [nutDanLinkTrangTinh, nutTaiTrangTinh, vongQuayTrangTinh])
        hangNutTrangTinh.axis = .horizontal
        hangNutTrangTinh.spacing = 8
        hangNutTrangTinh.alignment = .center

        nutChonTuanPG.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        nutChonTuanPG.titleLabel?.numberOfLines = 0
        nutChonTuanPG.titleLabel?.lineBreakMode = .byWordWrapping
        nutChonTuanPG.titleLabel?.adjustsFontSizeToFitWidth = false
        nutChonTuanPG.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
        nutChonTuanPG.backgroundColor = BangMauBCTD.nenThe
        nutChonTuanPG.layer.cornerRadius = 8
        nutChonTuanPG.layer.borderWidth = 1
        nutChonTuanPG.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
        nutChonTuanPG.contentHorizontalAlignment = .left
        nutChonTuanPG.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        nutChonTuanPG.showsMenuAsPrimaryAction = true
        nutChonTuanPG.isHidden = true

        let stackLinkSheet = UIStackView(arrangedSubviews: [nhanTieuDeLink, oLinkTrangTinh, hangNutTrangTinh, nutChonTuanPG])
        stackLinkSheet.axis = .vertical
        stackLinkSheet.spacing = 7
        stackLinkSheet.translatesAutoresizingMaskIntoConstraints = false
        khungLinkTrangTinh.addSubview(stackLinkSheet)
        NSLayoutConstraint.activate([
            stackLinkSheet.topAnchor.constraint(equalTo: khungLinkTrangTinh.topAnchor, constant: 10),
            stackLinkSheet.leadingAnchor.constraint(equalTo: khungLinkTrangTinh.leadingAnchor, constant: 10),
            stackLinkSheet.trailingAnchor.constraint(equalTo: khungLinkTrangTinh.trailingAnchor, constant: -10),
            stackLinkSheet.bottomAnchor.constraint(equalTo: khungLinkTrangTinh.bottomAnchor, constant: -10)
        ])

        // Khung chỉnh số nhân sự phát theo tuyến & bán kính phát tờ rơi -> app tự chia tuyến tương ứng
        let khungCauHinhTuyen = UIView()
        khungCauHinhTuyen.backgroundColor = BangMauBCTD.nenThePhu
        khungCauHinhTuyen.layer.cornerRadius = 10
        khungCauHinhTuyen.layer.borderWidth = 1
        khungCauHinhTuyen.layer.borderColor = BangMauBCTD.vienThe.cgColor

        for nut in [nutChonSoPG, nutChonSoNV, nutChonSoTuyen, nutChonBanKinhToRoi] {
            nut.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
            nut.titleLabel?.numberOfLines = 0
            nut.titleLabel?.lineBreakMode = .byWordWrapping
            nut.titleLabel?.adjustsFontSizeToFitWidth = false
            nut.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
            nut.backgroundColor = BangMauBCTD.nenThe
            nut.layer.cornerRadius = 8
            nut.layer.borderWidth = 1
            nut.layer.borderColor = BangMauBCTD.vienDam.cgColor
            nut.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            nut.showsMenuAsPrimaryAction = true
        }
        nutChonBanKinhToRoi.setTitleColor(BangMauBCTD.xanhDatChu, for: .normal)
        nutChonBanKinhToRoi.layer.borderColor = BangMauBCTD.xanhDatVach.withAlphaComponent(0.55).cgColor

        let hangChonNhanSuTuyen = UIStackView(arrangedSubviews: [nutChonSoPG, nutChonSoNV])
        hangChonNhanSuTuyen.axis = .horizontal
        hangChonNhanSuTuyen.spacing = 8
        hangChonNhanSuTuyen.distribution = .fillEqually

        nhanTomTatChiaTuyen.font = .systemFont(ofSize: 11.5, weight: .semibold)
        nhanTomTatChiaTuyen.textColor = BangMauBCTD.xanhChuDaoDam
        nhanTomTatChiaTuyen.numberOfLines = 0
        nhanTomTatChiaTuyen.lineBreakMode = .byWordWrapping
        nhanTomTatChiaTuyen.adjustsFontSizeToFitWidth = false

        let stackCauHinhTuyen = UIStackView(arrangedSubviews: [hangChonNhanSuTuyen, nutChonSoTuyen, nutChonBanKinhToRoi, nhanTomTatChiaTuyen])
        stackCauHinhTuyen.axis = .vertical
        stackCauHinhTuyen.spacing = 6
        stackCauHinhTuyen.translatesAutoresizingMaskIntoConstraints = false
        khungCauHinhTuyen.addSubview(stackCauHinhTuyen)
        NSLayoutConstraint.activate([
            stackCauHinhTuyen.topAnchor.constraint(equalTo: khungCauHinhTuyen.topAnchor, constant: 9),
            stackCauHinhTuyen.leadingAnchor.constraint(equalTo: khungCauHinhTuyen.leadingAnchor, constant: 9),
            stackCauHinhTuyen.trailingAnchor.constraint(equalTo: khungCauHinhTuyen.trailingAnchor, constant: -9),
            stackCauHinhTuyen.bottomAnchor.constraint(equalTo: khungCauHinhTuyen.bottomAnchor, constant: -9)
        ])

        nhanTrangThaiExcel.font = .systemFont(ofSize: 11.5, weight: .medium)
        nhanTrangThaiExcel.textColor = BangMauBCTD.chuPhu
        nhanTrangThaiExcel.numberOfLines = 0
        nhanTrangThaiExcel.lineBreakMode = .byWordWrapping
        nhanTrangThaiExcel.adjustsFontSizeToFitWidth = false

        nutTaoMaTran.setTitle("⚡ Phân lịch xoay vòng", for: .normal)
        nutTaoMaTran.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .heavy)
        nutTaoMaTran.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
        nutTaoMaTran.backgroundColor = BangMauBCTD.vangSang
        nutTaoMaTran.layer.cornerRadius = 9
        nutTaoMaTran.layer.borderWidth = 1
        nutTaoMaTran.layer.borderColor = BangMauBCTD.vangChuDao.cgColor
        nutTaoMaTran.heightAnchor.constraint(equalToConstant: 38).isActive = true
        nutTaoMaTran.addTarget(self, action: #selector(bamTaoMaTranXoayVong), for: .touchUpInside)

        nutCopyMaTran.setTitle("📋 Copy ma trận tuần", for: .normal)
        nutCopyMaTran.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        nutCopyMaTran.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
        nutCopyMaTran.backgroundColor = BangMauBCTD.nenHeaderPhu
        nutCopyMaTran.layer.cornerRadius = 9
        nutCopyMaTran.layer.borderWidth = 1
        nutCopyMaTran.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
        nutCopyMaTran.heightAnchor.constraint(equalToConstant: 38).isActive = true
        nutCopyMaTran.addTarget(self, action: #selector(bamCopyMaTranTuan), for: .touchUpInside)

        nutXemLichCa.setTitle("👀 Xem lịch ca", for: .normal)
        nutXemLichCa.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        nutXemLichCa.titleLabel?.numberOfLines = 0
        nutXemLichCa.titleLabel?.lineBreakMode = .byWordWrapping
        nutXemLichCa.titleLabel?.adjustsFontSizeToFitWidth = false
        nutXemLichCa.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
        nutXemLichCa.backgroundColor = BangMauBCTD.nenThePhu
        nutXemLichCa.layer.cornerRadius = 9
        nutXemLichCa.layer.borderWidth = 1
        nutXemLichCa.layer.borderColor = BangMauBCTD.vienDam.cgColor
        nutXemLichCa.contentEdgeInsets = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        nutXemLichCa.addTarget(self, action: #selector(bamXemLichCaDaQuet), for: .touchUpInside)

        let hangHanhDong = UIStackView(arrangedSubviews: [nutTaoMaTran, nutCopyMaTran])
        hangHanhDong.axis = .horizontal
        hangHanhDong.spacing = 8
        hangHanhDong.distribution = .fillEqually

        chonLocMaTran.selectedSegmentIndex = 0
        chonLocMaTran.addTarget(self, action: #selector(doiBoLocMaTran), for: .valueChanged)

        nganDanhSachMaTran.axis = .vertical
        nganDanhSachMaTran.spacing = 7

        nutSoXoayTuaThang.setTitle("📊 Xoay tua tháng", for: .normal)
        nutSoXoayTuaThang.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        nutSoXoayTuaThang.titleLabel?.numberOfLines = 0
        nutSoXoayTuaThang.titleLabel?.lineBreakMode = .byWordWrapping
        nutSoXoayTuaThang.titleLabel?.adjustsFontSizeToFitWidth = false
        nutSoXoayTuaThang.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
        nutSoXoayTuaThang.backgroundColor = BangMauBCTD.nenHeaderPhu
        nutSoXoayTuaThang.layer.cornerRadius = 9
        nutSoXoayTuaThang.layer.borderWidth = 1
        nutSoXoayTuaThang.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
        nutSoXoayTuaThang.contentEdgeInsets = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        nutSoXoayTuaThang.addTarget(self, action: #selector(bamXemSoXoayTuaThang), for: .touchUpInside)

        nutKiemSoatTuan.setTitle("🛡️ Kiểm soát phát", for: .normal)
        nutKiemSoatTuan.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        nutKiemSoatTuan.titleLabel?.numberOfLines = 0
        nutKiemSoatTuan.titleLabel?.lineBreakMode = .byWordWrapping
        nutKiemSoatTuan.titleLabel?.adjustsFontSizeToFitWidth = false
        nutKiemSoatTuan.setTitleColor(.white, for: .normal)
        nutKiemSoatTuan.backgroundColor = BangMauBCTD.xanhLaDam
        nutKiemSoatTuan.layer.cornerRadius = 9
        nutKiemSoatTuan.contentEdgeInsets = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        nutKiemSoatTuan.addTarget(self, action: #selector(bamXemKiemSoatTuan), for: .touchUpInside)

        let hangKiemTra = UIStackView(arrangedSubviews: [nutXemLichCa, nutSoXoayTuaThang, nutKiemSoatTuan])
        hangKiemTra.axis = .horizontal
        hangKiemTra.spacing = 6
        hangKiemTra.distribution = .fillEqually

        nutPWACheckIn.setTitle("📲 Link PWA / Sheet", for: .normal)
        nutPWACheckIn.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        nutPWACheckIn.titleLabel?.numberOfLines = 0
        nutPWACheckIn.titleLabel?.lineBreakMode = .byWordWrapping
        nutPWACheckIn.titleLabel?.adjustsFontSizeToFitWidth = false
        nutPWACheckIn.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
        nutPWACheckIn.backgroundColor = BangMauBCTD.nenHeaderPhu
        nutPWACheckIn.layer.cornerRadius = 9
        nutPWACheckIn.layer.borderWidth = 1
        nutPWACheckIn.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
        nutPWACheckIn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        nutPWACheckIn.addTarget(self, action: #selector(bamMenuPWACheckIn), for: .touchUpInside)

        nutDongBoPWA.setTitle("🔄 Đồng bộ PWA", for: .normal)
        nutDongBoPWA.titleLabel?.font = .systemFont(ofSize: 12, weight: .heavy)
        nutDongBoPWA.titleLabel?.numberOfLines = 0
        nutDongBoPWA.titleLabel?.lineBreakMode = .byWordWrapping
        nutDongBoPWA.titleLabel?.adjustsFontSizeToFitWidth = false
        nutDongBoPWA.setTitleColor(.white, for: .normal)
        nutDongBoPWA.backgroundColor = BangMauBCTD.xanhChuDao
        nutDongBoPWA.layer.cornerRadius = 9
        nutDongBoPWA.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        nutDongBoPWA.addTarget(self, action: #selector(bamDongBoPWAThuCong), for: .touchUpInside)

        let hangPWA = UIStackView(arrangedSubviews: [nutPWACheckIn, nutDongBoPWA])
        hangPWA.axis = .horizontal
        hangPWA.spacing = 8
        hangPWA.distribution = .fillEqually

        // Chọn PG / Nhân viên để xem riêng tuyến đường & lịch phát tờ rơi của người đó
        nutLocNhanSuMaTran.setTitle("👤 Chọn PG / NV xem tuyến & lịch phát ▾", for: .normal)
        nutLocNhanSuMaTran.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .heavy)
        nutLocNhanSuMaTran.titleLabel?.numberOfLines = 0
        nutLocNhanSuMaTran.titleLabel?.lineBreakMode = .byWordWrapping
        nutLocNhanSuMaTran.titleLabel?.adjustsFontSizeToFitWidth = false
        nutLocNhanSuMaTran.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
        nutLocNhanSuMaTran.backgroundColor = BangMauBCTD.vangNhatNen.withAlphaComponent(0.65)
        nutLocNhanSuMaTran.layer.cornerRadius = 9
        nutLocNhanSuMaTran.layer.borderWidth = 1.2
        nutLocNhanSuMaTran.layer.borderColor = BangMauBCTD.vangChuDao.cgColor
        nutLocNhanSuMaTran.contentHorizontalAlignment = .left
        nutLocNhanSuMaTran.contentEdgeInsets = UIEdgeInsets(top: 9, left: 10, bottom: 9, right: 10)
        nutLocNhanSuMaTran.showsMenuAsPrimaryAction = true

        khungLichNhanSuChon.backgroundColor = BangMauBCTD.nenHeaderPhu
        khungLichNhanSuChon.layer.cornerRadius = 11
        khungLichNhanSuChon.layer.borderWidth = 1.3
        khungLichNhanSuChon.layer.borderColor = BangMauBCTD.xanhChuDao.withAlphaComponent(0.55).cgColor
        khungLichNhanSuChon.isHidden = true

        nganLichNhanSuChon.axis = .vertical
        nganLichNhanSuChon.spacing = 6
        nganLichNhanSuChon.translatesAutoresizingMaskIntoConstraints = false
        khungLichNhanSuChon.addSubview(nganLichNhanSuChon)
        NSLayoutConstraint.activate([
            nganLichNhanSuChon.topAnchor.constraint(equalTo: khungLichNhanSuChon.topAnchor, constant: 10),
            nganLichNhanSuChon.leadingAnchor.constraint(equalTo: khungLichNhanSuChon.leadingAnchor, constant: 10),
            nganLichNhanSuChon.trailingAnchor.constraint(equalTo: khungLichNhanSuChon.trailingAnchor, constant: -10),
            nganLichNhanSuChon.bottomAnchor.constraint(equalTo: khungLichNhanSuChon.bottomAnchor, constant: -10)
        ])

        let stack = UIStackView(arrangedSubviews: [
            hangDau, nhanNhacTuyenChuaPhat, khungLinkTrangTinh, khungCauHinhTuyen, nhanTrangThaiExcel, hangHanhDong, hangKiemTra, hangPWA, nutLocNhanSuMaTran, khungLichNhanSuChon, chonLocMaTran, nganDanhSachMaTran
        ])
        stack.axis = .vertical
        stack.spacing = 9
        stack.translatesAutoresizingMaskIntoConstraints = false
        khungMaTranToRoi.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: khungMaTranToRoi.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: khungMaTranToRoi.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: khungMaTranToRoi.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: khungMaTranToRoi.bottomAnchor, constant: -12)
        ])

        return khungMaTranToRoi
    }

    @objc private func bamBatTatNhacChuNhat() {
        let batMoi = !KhoMaTranPhatToRoi.dungChung.dangBatNhacChuNhat
        KhoMaTranPhatToRoi.dungChung.capNhatNhacChuNhatHangTuan(bat: batMoi) { [weak self] _, msg in
            self?.capNhatNutNhacChuNhat()
            self?.hienThongBao(tieuDe: "Nhắc lịch Chủ nhật hằng tuần", noiDung: msg)
        }
    }

    private func capNhatNutNhacChuNhat() {
        let dangBat = KhoMaTranPhatToRoi.dungChung.dangBatNhacChuNhat
        nutNhacChuNhat.setTitle(dangBat ? "🔔 Nhắc CN: Bật" : "🔕 Nhắc CN 18h", for: .normal)
        nutNhacChuNhat.backgroundColor = dangBat ? BangMauBCTD.xanhDatPill : BangMauBCTD.nenHeaderPhu
        nutNhacChuNhat.setTitleColor(dangBat ? BangMauBCTD.xanhDatChu : BangMauBCTD.chuPhu, for: .normal)
    }

    @objc private func bamDanVaTaiTrangTinh() {
        view.endEditing(true)
        guard let clip = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty else {
            hienThongBao(tieuDe: "Bộ nhớ tạm trống", noiDung: "Hãy sao chép link Google Trang tính trước rồi bấm “📋 Dán & Tải”.")
            return
        }
        oLinkTrangTinh.text = clip
        thucThiTaiTrangTinhChung(link: clip)
    }

    @objc private func bamTaiTrangTinh() {
        view.endEditing(true)
        let link = (oLinkTrangTinh.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        thucThiTaiTrangTinhChung(link: link)
    }

    @objc private func bamMenuPWACheckIn() {
        let pwaLink = KhoMaTranPhatToRoi.linkPWACheckInMacDinh
        let bcLink = KhoMaTranPhatToRoi.linkSheetBaoCaoCheckIn
        let sheet = UIAlertController(
            title: "📲 App PWA Check-in Phát Tờ Rơi",
            message: "Gửi link PWA cho nhân viên/PG check-in GPS + chụp ảnh gửi trực tiếp về tab BC-Phát tờ rơi.",
            preferredStyle: .actionSheet
        )
        sheet.addAction(UIAlertAction(title: "📋 Copy link PWA gửi cho nhân viên", style: .default) { [weak self] _ in
            UIPasteboard.general.string = pwaLink
            self?.hienThongBao(
                tieuDe: "✅ Đã sao chép link PWA",
                noiDung: "\(pwaLink)\n\nDán gửi vào nhóm Zalo/Line siêu thị. Nhân viên bấm mở là check-in GPS & chụp ảnh được ngay, không cần cài app từ Store."
            )
        })
        sheet.addAction(UIAlertAction(title: "☁️ Đẩy lịch & tuyến lên PWA (để PG/NV chọn tên xem lịch)", style: .default) { [weak self] _ in
            guard let self else { return }
            if self.keHoachMaTran == nil {
                self.hienThongBao(tieuDe: "Chưa có ma trận tuần", noiDung: "Hãy bấm “⚡ Phân lịch xoay vòng” trước rồi đồng bộ lên PWA.")
            } else {
                self.dongBoLichLenPWANen(hienKetQua: true)
            }
        })
        sheet.addAction(UIAlertAction(title: "🌐 Mở PWA Check-in trên Safari", style: .default) { _ in
            if let url = URL(string: pwaLink) {
                UIApplication.shared.open(url)
            }
        })
        sheet.addAction(UIAlertAction(title: "📗 Mở Google Sheet (Tab BC-Phát tờ rơi)", style: .default) { _ in
            if let url = URL(string: bcLink) {
                UIApplication.shared.open(url)
            }
        })
        sheet.addAction(UIAlertAction(title: "Đóng", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = nutPWACheckIn
            pop.sourceRect = nutPWACheckIn.bounds
        }
        present(sheet, animated: true)
    }

    @objc private func bamDongBoPWAThuCong() {
        dongBoCheckInTuPWA(imLang: false)
        dongBoLichLenPWANen(hienKetQua: false)
    }

    private func thucThiTaiTrangTinhChung(link: String) {
        let linkSach = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !linkSach.isEmpty else {
            hienThongBao(
                tieuDe: "Chưa nhập link Trang tính",
                noiDung: "Hãy dán link Google Trang tính chứa lịch PG và TEAM NV. vào ô phía trên rồi bấm “🔄 Tải lịch PG & NV”."
            )
            return
        }

        KhoMaTranPhatToRoi.dungChung.luuLinkTrangTinhChung(linkSach)
        nhanTrangThaiExcel.text = "⏳ Đang tải lịch PG & Nhân viên từ Google Trang tính…"
        nutDanLinkTrangTinh.isEnabled = false
        nutTaiTrangTinh.isEnabled = false
        vongQuayTrangTinh.startAnimating()

        BoTaiTrangTinhGoogleSheets.dungChung.taiToanBoLichTuGoogleSheets(link: linkSach) { [weak self] ketQua in
            guard let self else { return }
            self.nutDanLinkTrangTinh.isEnabled = true
            self.nutTaiTrangTinh.isEnabled = true
            self.vongQuayTrangTinh.stopAnimating()

            switch ketQua {
            case .success(let res):
                let kq = res.ketQua
                if !kq.dsKhoiPG.isEmpty {
                    self.danhSachKhoiPG = kq.dsKhoiPG
                    KhoMaTranPhatToRoi.dungChung.luuDanhSachKhoiPG(kq.dsKhoiPG)
                    if let pg = kq.khoiPGMacDinh {
                        self.khoiLichPG = pg
                        KhoMaTranPhatToRoi.dungChung.luuKhoiPG(pg)
                    }
                }
                if let nv = kq.khoiNVMacDinh {
                    self.khoiLichNV = nv
                    KhoMaTranPhatToRoi.dungChung.luuKhoiNV(nv)
                }

                self.bamTaoMaTranXoayVong()

                var dongTomTat: [String] = []
                if let pg = kq.khoiPGMacDinh {
                    let themTuan = kq.dsKhoiPG.count > 1 ? " (có \(kq.dsKhoiPG.count) tuần — bấm Đổi tuần PG nếu cần)" : ""
                    dongTomTat.append("• PG: \(pg.tenTuan) — \(pg.danhSachNguoi.count) người\(themTuan)")
                } else {
                    dongTomTat.append("• PG: Không thấy tab lịch PG đang hiển thị")
                }
                if let nv = kq.khoiNVMacDinh {
                    dongTomTat.append("• Nhân viên (\(nv.tenSheet)): \(nv.tenTuan) — \(nv.danhSachNguoi.count) người")
                } else {
                    dongTomTat.append("• Nhân viên: Không thấy tab TEAM NV. đang hiển thị")
                }
                self.hienThongBao(
                    tieuDe: "✅ Đã đồng bộ Google Trang tính",
                    noiDung: dongTomTat.joined(separator: "\n") + "\n\nApp đã tự động khớp tuần và chia tuyến theo cấu hình nhân sự."
                )

            case .failure(let loi):
                self.capNhatGiaoDienMaTran()
                self.hienThongBao(tieuDe: "Chưa tải được Google Trang tính", noiDung: loi.localizedDescription)
            }
        }
    }

    private func capNhatMenuChonTuanPG() {
        if !danhSachKhoiPG.isEmpty {
            nutChonTuanPG.isHidden = false
            let dangChon = khoiLichPG?.tenTuan ?? danhSachKhoiPG.first?.tenTuan ?? "Chọn tuần"
            let slChon = khoiLichPG?.danhSachNguoi.count ?? 0
            nutChonTuanPG.setTitle("📅 Tuần PG: \(dangChon) (\(slChon) PG) ▾", for: .normal)
            nutChonTuanPG.menu = UIMenu(title: "Chọn tuần lịch PG (Tuần hiện tại / Tuần tiếp theo)", children: danhSachKhoiPG.map { khoi in
                let isSelected = (khoi.id == khoiLichPG?.id)
                let moTaSL = khoi.danhSachNguoi.isEmpty ? "Chưa nhập lịch trên Sheet" : "\(khoi.danhSachNguoi.count) PG"
                let title = "\(khoi.tenTuan) — \(moTaSL)"
                return UIAction(title: title, state: isSelected ? .on : .off) { [weak self] _ in
                    guard let self else { return }
                    self.khoiLichPG = khoi
                    KhoMaTranPhatToRoi.dungChung.luuKhoiPG(khoi)
                    if khoi.danhSachNguoi.isEmpty {
                        self.capNhatGiaoDienMaTran()
                        self.hienThongBao(
                            tieuDe: "Tuần này chưa có lịch trên Sheet",
                            noiDung: "\(khoi.tenTuan) hiện chưa được nhập lịch trên tab PG của Google Trang tính.\n\nHãy chuyển sang tuần đó trên Google Trang tính để nhập lịch, sau đó bấm “🔄 Tải lịch PG & NV”."
                        )
                    } else {
                        self.bamTaoMaTranXoayVong()
                    }
                }
            })
        } else {
            nutChonTuanPG.isHidden = true
        }
    }

    private func capNhatMenuCauHinhPhanTuyen() {
        capNhatMenuChonTuanPG()

        nutChonSoPG.setTitle("👩‍💼 PG/tuyến: \(cauHinhPhanTuyen.soPGMoiTuyen) ▾", for: .normal)
        nutChonSoPG.menu = UIMenu(title: "Số PG phát trên mỗi tuyến", children: (0...5).map { so in
            UIAction(title: so == 0 ? "0 PG (không gán PG)" : "\(so) PG / tuyến", state: (so == cauHinhPhanTuyen.soPGMoiTuyen) ? .on : .off) { [weak self] _ in
                guard let self else { return }
                self.cauHinhPhanTuyen.soPGMoiTuyen = so
                KhoMaTranPhatToRoi.dungChung.luuCauHinhPhanTuyen(self.cauHinhPhanTuyen)
                self.bamTaoMaTranXoayVong()
            }
        })

        nutChonSoNV.setTitle("🧑‍🔧 NV/tuyến: \(cauHinhPhanTuyen.soNVMoiTuyen) ▾", for: .normal)
        nutChonSoNV.menu = UIMenu(title: "Số NV siêu thị phát trên mỗi tuyến", children: (0...5).map { so in
            UIAction(title: so == 0 ? "0 NV (không gán NV)" : "\(so) NV / tuyến", state: (so == cauHinhPhanTuyen.soNVMoiTuyen) ? .on : .off) { [weak self] _ in
                guard let self else { return }
                self.cauHinhPhanTuyen.soNVMoiTuyen = so
                KhoMaTranPhatToRoi.dungChung.luuCauHinhPhanTuyen(self.cauHinhPhanTuyen)
                self.bamTaoMaTranXoayVong()
            }
        })

        let tieuDeTuyen = cauHinhPhanTuyen.soTuyenMongMuon == 0
            ? "Tự động chia tuyến"
            : "Chia cố định \(cauHinhPhanTuyen.soTuyenMongMuon) tuyến"
        nutChonSoTuyen.setTitle("🛣️ Số tuyến: \(tieuDeTuyen) ▾", for: .normal)
        let cacMucTuyen = [0, 2, 3, 4, 5, 6, 8]
        nutChonSoTuyen.menu = UIMenu(title: "Chế độ chia tuyến phát tờ rơi", children: cacMucTuyen.map { st in
            let title = st == 0 ? "Tự động theo số nhân sự/tuyến" : "Chia \(st) tuyến quanh siêu thị"
            return UIAction(title: title, state: (st == cauHinhPhanTuyen.soTuyenMongMuon) ? .on : .off) { [weak self] _ in
                guard let self else { return }
                self.cauHinhPhanTuyen.soTuyenMongMuon = st
                KhoMaTranPhatToRoi.dungChung.luuCauHinhPhanTuyen(self.cauHinhPhanTuyen)
                self.bamTaoMaTranXoayVong()
            }
        })

        let bkPhatHieuLuc = cauHinhPhanTuyen.banKinhPhatHieuLuc(banKinhQuetMet: banKinhMet)
        let nhanBanKinhPhat: String
        if cauHinhPhanTuyen.banKinhPhatToRoiMet <= 0 {
            nhanBanKinhPhat = "Theo bán kính quét (\(BoDanDuongTuyenThucTe.dinhDangKhoangCach(banKinhMet)))"
        } else {
            nhanBanKinhPhat = BoDanDuongTuyenThucTe.dinhDangKhoangCach(cauHinhPhanTuyen.banKinhPhatToRoiMet)
        }
        nutChonBanKinhToRoi.setTitle("🎯 Bán kính phát tờ rơi: \(nhanBanKinhPhat) ▾", for: .normal)
        let cacMucBanKinh: [(Double, String)] = [
            (0, "Theo bán kính quét (\(BoDanDuongTuyenThucTe.dinhDangKhoangCach(banKinhMet)))"),
            (500, "500 m (quanh sát siêu thị)"),
            (1000, "1 km"),
            (1500, "1.5 km"),
            (2000, "2 km"),
            (3000, "3 km"),
            (5000, "5 km")
        ]
        var actionBanKinh: [UIAction] = cacMucBanKinh.map { (giaTri, tieuDe) in
            let dangChon = (giaTri == 0 && cauHinhPhanTuyen.banKinhPhatToRoiMet <= 0)
                || (giaTri > 0 && abs(cauHinhPhanTuyen.banKinhPhatToRoiMet - giaTri) < 1)
            return UIAction(title: tieuDe, state: dangChon ? .on : .off) { [weak self] _ in
                self?.apDungBanKinhPhatToRoi(giaTri)
            }
        }
        actionBanKinh.append(UIAction(title: "✏️ Nhập bán kính phát tùy chỉnh (mét)...") { [weak self] _ in
            self?.moHopNhapBanKinhPhatTuyChinh()
        })
        nutChonBanKinhToRoi.menu = UIMenu(title: "Chọn bán kính phát tờ rơi", children: actionBanKinh)

        let soDiemNong = tatCaDiaDiem.filter { $0.loai != .heThongMWG && $0.khoangCachMet <= bkPhatHieuLuc + 25.0 }.count
        let soTuyenDuKien = BoLapMaTranToRoiXoayVong.tinhSoTuyenTuDong(
            khoiPG: khoiLichPG,
            khoiNV: khoiLichNV,
            cauHinh: cauHinhPhanTuyen,
            soDiemNong: soDiemNong
        )
        let tongNS = (khoiLichPG?.danhSachNguoi.count ?? 0) + (khoiLichNV?.danhSachNguoi.count ?? 0)
        nhanTomTatChiaTuyen.text = "⚙️ Định mức: \(cauHinhPhanTuyen.soPGMoiTuyen) PG + \(cauHinhPhanTuyen.soNVMoiTuyen) NV (\(cauHinhPhanTuyen.tongNhanSuMoiTuyen) người/tuyến) • Bán kính phát: \(BoDanDuongTuyenThucTe.dinhDangKhoangCach(bkPhatHieuLuc)) → Chia \(soTuyenDuKien) tuyến\(tongNS > 0 ? " (từ \(tongNS) nhân sự có lịch)" : "")."
    }

    private func apDungBanKinhPhatToRoi(_ met: Double) {
        cauHinhPhanTuyen.banKinhPhatToRoiMet = (met <= 0) ? 0 : max(200, min(20000, met))
        KhoMaTranPhatToRoi.dungChung.luuCauHinhPhanTuyen(cauHinhPhanTuyen)
        capNhatTamVaVongTronTrenBanDo(diChuyenCamera: false)

        if !tatCaDiaDiem.isEmpty {
            let dau = danhSachTamDangChonDeQuet().first?.toaDo ?? tamQuet
            let bkPhat = cauHinhPhanTuyen.banKinhPhatHieuLuc(banKinhQuetMet: banKinhMet)
            BoToiUuTuyenPhatToRoi.dungChung.tinhTuyenHieuQuaNhat(
                tam: dau,
                tenDiemXuatPhat: tenXuatPhatHienTai(),
                danhSach: tatCaDiaDiem,
                banKinhMet: bkPhat
            ) { [weak self] tuyen in
                guard let self else { return }
                self.ketQuaTuyen = tuyen
                self.capNhatKhungTuyenPhatToRoi()
                self.luuKetQuaQuetVaoBoNho(thongBao: self.nhanTrangThaiQuet.text ?? self.thongBaoQuetLuu)
            }
        }
        bamTaoMaTranXoayVong()
    }

    private func moHopNhapBanKinhPhatTuyChinh() {
        let bkHien = cauHinhPhanTuyen.banKinhPhatHieuLuc(banKinhQuetMet: banKinhMet)
        let ac = UIAlertController(
            title: "Nhập bán kính phát tờ rơi (mét)",
            message: "Nhập phạm vi phát tờ rơi quanh siêu thị từ 200m đến 20.000m (có thể nhỏ hơn bán kính quét để gom tuyến tập trung hơn).",
            preferredStyle: .alert
        )
        ac.addTextField { tf in
            tf.placeholder = "VD: 1200"
            tf.text = "\(Int(bkHien))"
            tf.keyboardType = .numberPad
            tf.clearButtonMode = .whileEditing
        }
        ac.addAction(UIAlertAction(title: "Áp dụng", style: .default) { [weak self, weak ac] _ in
            let so = Double((ac?.textFields?.first?.text ?? "").filter { $0.isNumber }) ?? 0
            guard so >= 200 && so <= 20000 else {
                self?.hienThongBao(tieuDe: "Bán kính chưa hợp lệ", noiDung: "Vui lòng nhập bán kính phát tờ rơi từ 200m đến 20.000m.")
                return
            }
            self?.apDungBanKinhPhatToRoi(so)
        })
        ac.addAction(UIAlertAction(title: "Dùng theo bán kính quét", style: .default) { [weak self] _ in
            self?.apDungBanKinhPhatToRoi(0)
        })
        ac.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        present(ac, animated: true)
    }

    @objc private func bamTaoMaTranXoayVong() {
        let dau = danhSachTamDangChonDeQuet().first?.toaDo ?? tamQuet
        let tenXuatPhat = tenXuatPhatHienTai()
        let bkPhat = cauHinhPhanTuyen.banKinhPhatHieuLuc(banKinhQuetMet: banKinhMet)
        let soDiemNong = tatCaDiaDiem.filter { $0.loai != .heThongMWG && $0.khoangCachMet <= bkPhat + 25.0 }.count
        let soTuyenCanChia = BoLapMaTranToRoiXoayVong.tinhSoTuyenTuDong(
            khoiPG: khoiLichPG,
            khoiNV: khoiLichNV,
            cauHinh: cauHinhPhanTuyen,
            soDiemNong: soDiemNong
        )

        let cacTuyen: [TuyenPhatToRoiMaTran]
        if !tatCaDiaDiem.isEmpty {
            cacTuyen = BoLapMaTranToRoiXoayVong.taoCacTuyenTuKetQuaQuet(
                tamLat: dau.latitude,
                tamLon: dau.longitude,
                danhSach: tatCaDiaDiem,
                banKinhMet: bkPhat,
                soTuyenMongMuon: soTuyenCanChia,
                tenDiemXuatPhat: tenXuatPhat
            )
        } else if let cu = keHoachMaTran, !cu.cacTuyen.isEmpty, cu.cacTuyen.count == soTuyenCanChia {
            cacTuyen = cu.cacTuyen
        } else {
            cacTuyen = BoLapMaTranToRoiXoayVong.taoCacTuyenTuKetQuaQuet(
                tamLat: dau.latitude,
                tamLon: dau.longitude,
                danhSach: [],
                banKinhMet: bkPhat,
                soTuyenMongMuon: soTuyenCanChia,
                tenDiemXuatPhat: tenXuatPhat
            )
        }

        let kh = BoLapMaTranToRoiXoayVong.lapMaTranTuan(
            cacTuyen: cacTuyen,
            khoiPG: khoiLichPG,
            khoiNV: khoiLichNV,
            cauHinh: cauHinhPhanTuyen,
            giuTrangThaiCu: keHoachMaTran
        )
        keHoachMaTran = kh
        KhoMaTranPhatToRoi.dungChung.luuKeHoach(kh)
        capNhatTamVaVongTronTrenBanDo(diChuyenCamera: false)
        capNhatKhungTuyenPhatToRoi()
        capNhatGiaoDienMaTran()
        dongBoDuongThucTeChoCacTuyen()
        dongBoLichLenPWANen()
    }

    /// Tự động bám sát đường đi thực tế trên bản đồ + chỉ dẫn rẽ trái/phải + thời gian xe máy/đi bộ cho toàn bộ tuyến
    private func dongBoDuongThucTeChoCacTuyen() {
        guard let kh = keHoachMaTran else { return }
        let canCapNhat = kh.cacTuyen.filter { $0.cacToaDo.count >= 2 && !$0.laDuongThucTe }
        guard !canCapNhat.isEmpty else { return }

        phienDanDuongID += 1
        let phienHienTai = phienDanDuongID
        let tenXuatPhat = tenXuatPhatHienTai()

        BoDanDuongTuyenThucTe.dungChung.capNhatDuongThucTeChoTatCaTuyen(
            cacTuyen: canCapNhat,
            tenDiemXuatPhat: tenXuatPhat,
            capNhatTungTuyen: { [weak self] tuyenDaBamDuong in
                guard let self, self.phienDanDuongID == phienHienTai,
                      var khMoi = self.keHoachMaTran,
                      let idx = khMoi.cacTuyen.firstIndex(where: { $0.id == tuyenDaBamDuong.id }) else { return }
                khMoi.cacTuyen[idx] = tuyenDaBamDuong
                self.keHoachMaTran = khMoi
                KhoMaTranPhatToRoi.dungChung.luuKeHoach(khMoi)
                self.veLaiGhimVaTuyenTrenBanDo()
                self.capNhatKhungTuyenPhatToRoi()
            },
            hoanTatTatCa: { [weak self] in
                guard let self, self.phienDanDuongID == phienHienTai else { return }
                self.capNhatKhungTuyenPhatToRoi()
                self.capNhatGiaoDienMaTran()
                self.dongBoLichLenPWANen()
            }
        )
    }

    @objc private func doiBoLocMaTran() {
        capNhatGiaoDienMaTran()
    }

    @objc private func bamDanhDauDaPhat(_ sender: UIButton) {
        guard var kh = keHoachMaTran, let idO = sender.accessibilityIdentifier,
              let idx = kh.cacO.firstIndex(where: { $0.id == idO }) else { return }
        kh.cacO[idx].daPhat.toggle()
        keHoachMaTran = kh
        KhoMaTranPhatToRoi.dungChung.luuKeHoach(kh)
        capNhatGiaoDienMaTran()
    }

    private func capNhatGiaoDienMaTran() {
        capNhatNutNhacChuNhat()
        capNhatMenuCauHinhPhanTuyen()

        let pgInfo = khoiLichPG.map { "PG: \($0.tenTuan) (\($0.danhSachNguoi.count) người • \($0.tenSheet))" } ?? "PG: Chưa tải từ Google Trang tính"
        let nvInfo = khoiLichNV.map { "NV: \($0.tenTuan) (\($0.danhSachNguoi.count) người • \($0.tenSheet))" } ?? "NV: Chưa tải từ Google Trang tính"
        let laChuNhat = (Calendar(identifier: .gregorian).component(.weekday, from: Date()) == 1)
        let ghiChuCN = laChuNhat
            ? "📌 Hôm nay là Chủ nhật — bấm “🔄 Tải lịch PG & NV” để cập nhật tuần tiếp theo!"
            : "🗓️ 1 link Google Trang tính duy nhất tự động đọc cả lịch PG và tab TEAM NV. (Ca 1–Ca 6)."
        let bangThang = KhoSoXoayTuaThang.dungChung.layBangThang()
        let daPhatThang = bangThang.filter { !$0.cacTuanDaPhat.isEmpty }.count
        let chuaPhatThang = bangThang.filter { $0.cacTuanDaPhat.isEmpty }
        var thongKePhan = ""
        if let kh = keHoachMaTran, kh.tongPGCoLich > 0 {
            thongKePhan += "\n✅ Tuần này: đã phân \(kh.tongPGDaPhan)/\(kh.tongPGCoLich) PG đang làm việc (mỗi người tối đa 1 lần)."
        }
        if !bangThang.isEmpty {
            if chuaPhatThang.isEmpty {
                thongKePhan += "\n🏆 \(KhoSoXoayTuaThang.nhanThangHienTai()): Đã xoay tua đủ 100% (\(daPhatThang)/\(bangThang.count) người) — không bỏ sót ai!"
            } else {
                let dsChua = chuaPhatThang.prefix(5).map { $0.tenGoc }.joined(separator: ", ")
                let them = chuaPhatThang.count > 5 ? " (+\(chuaPhatThang.count - 5))" : ""
                thongKePhan += "\n📊 \(KhoSoXoayTuaThang.nhanThangHienTai()): \(daPhatThang)/\(bangThang.count) người đã phát • Còn \(chuaPhatThang.count) người 0 lượt (ưu tiên tuần tới): \(dsChua)\(them)"
            }
        }
        nhanTrangThaiExcel.text = "• \(pgInfo)\n• \(nvInfo)\(thongKePhan)\n\(ghiChuCN)"
        dungLaiThanhChuThichTuyen()
        capNhatKhungTuyenPhatToRoi()
        capNhatKhungChiTietTuyenDangChon()
        capNhatMenuVaKhungLocNhanSu()
        veLaiGhimVaTuyenTrenBanDo()

        nganDanhSachMaTran.arrangedSubviews.forEach {
            nganDanhSachMaTran.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        guard let kh = keHoachMaTran else {
            nhanNhacTuyenChuaPhat.text = "  💡 Dán link Google Trang tính PG & NV ở trên rồi bấm “🔄 Tải lịch PG & NV” để tự phân tuyến."
            nhanNhacTuyenChuaPhat.textColor = BangMauBCTD.xanhChuDaoDam
            nhanNhacTuyenChuaPhat.backgroundColor = BangMauBCTD.nenHeaderPhu
            return
        }

        // Tính các tuyến chưa phát (có tính cả các buổi đã nhận check-in từ PWA!)
        let oHoanThanh: (OMaTranPhatToRoi) -> Bool = { o in
            o.daPhat || !KhoCheckInPWADongBo.locCheckIn(choO: o, cacTuyen: kh.cacTuyen, trong: self.dsCheckInPWA).isEmpty
        }
        let tuyenDaPhatIDs = Set(kh.cacO.filter(oHoanThanh).map { $0.tuyenId })
        let tuyenChuaPhat = kh.cacTuyen.filter { !tuyenDaPhatIDs.contains($0.id) }
        let soBuoiChuaPhat = kh.cacO.filter { !oHoanThanh($0) }.count

        if tuyenChuaPhat.isEmpty {
            nhanNhacTuyenChuaPhat.text = "  ✅ Tuyệt vời! Tuần này (\(kh.nhanTuan)) đã phủ kín tất cả \(kh.cacTuyen.count) tuyến tờ rơi!"
            nhanNhacTuyenChuaPhat.textColor = BangMauBCTD.xanhDatChu
            nhanNhacTuyenChuaPhat.backgroundColor = BangMauBCTD.xanhDatPill
        } else {
            let tenChuaPhat = tuyenChuaPhat.map { $0.ten }.joined(separator: " • ")
            nhanNhacTuyenChuaPhat.text = "  ⚠️ Nhắc tuyến chưa phát (\(tuyenChuaPhat.count)/\(kh.cacTuyen.count) tuyến • \(soBuoiChuaPhat) buổi chưa xong):\n  \(tenChuaPhat)"
            nhanNhacTuyenChuaPhat.textColor = BangMauBCTD.doYeuChu
            nhanNhacTuyenChuaPhat.backgroundColor = BangMauBCTD.doYeuPill
        }

        var dsHien: [OMaTranPhatToRoi]
        switch chonLocMaTran.selectedSegmentIndex {
        case 1: dsHien = kh.cacO.filter { !oHoanThanh($0) }
        case 2: dsHien = kh.cacO.filter { oHoanThanh($0) }
        default: dsHien = kh.cacO
        }

        if let tenLoc = tenNhanSuDangLoc, !tenLoc.isEmpty {
            let key = KhoCheckInPWADongBo.tenChuanHoaKhongCa(tenLoc)
            dsHien = dsHien.filter { o in
                let all = (o.danhSachPG + o.danhSachNV).map { KhoCheckInPWADongBo.tenChuanHoaKhongCa($0) }
                return all.contains(where: { $0 == key || $0.contains(key) || key.contains($0) })
            }
        }

        if dsHien.isEmpty {
            let lb = UILabel()
            lb.text = tenNhanSuDangLoc != nil ? "Không có buổi nào của nhân sự này trong bộ lọc." : "Không có buổi nào thuộc bộ lọc này."
            lb.font = .systemFont(ofSize: 12, weight: .medium)
            lb.textColor = BangMauBCTD.chuMo
            lb.textAlignment = .center
            lb.numberOfLines = 0
            lb.lineBreakMode = .byWordWrapping
            lb.adjustsFontSizeToFitWidth = false
            nganDanhSachMaTran.addArrangedSubview(lb)
            return
        }

        for o in dsHien {
            nganDanhSachMaTran.addArrangedSubview(taoDongMaTran(o))
        }
    }

    private func capNhatMenuVaKhungLocNhanSu() {
        var dsTenPG: [String] = []
        var dsTenNV: [String] = []
        var daCo = Set<String>()

        func themTen(_ raw: String, laPG: Bool) {
            let sach = raw.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? raw
            let k = BoPhanTichLichCaExcel.chuanHoa(sach)
            guard !k.isEmpty, !daCo.contains(k) else { return }
            daCo.insert(k)
            if laPG { dsTenPG.append(sach) } else { dsTenNV.append(sach) }
        }

        if let kh = keHoachMaTran {
            for o in kh.cacO {
                for p in o.danhSachPG { themTen(p, laPG: true) }
                for n in o.danhSachNV { themTen(n, laPG: false) }
            }
        }
        for p in (khoiLichPG?.danhSachNguoi ?? []) { themTen(p.ten, laPG: true) }
        for n in (khoiLichNV?.danhSachNguoi ?? []) { themTen(n.ten, laPG: false) }

        var actions: [UIAction] = [
            UIAction(title: "👥 Tất cả PG & Nhân viên", state: (tenNhanSuDangLoc == nil) ? .on : .off) { [weak self] _ in
                self?.chonNhanSuXemLich(nil)
            }
        ]

        let kh = keHoachMaTran
        for ten in dsTenPG {
            let key = BoPhanTichLichCaExcel.chuanHoa(ten)
            let buoi = kh?.cacO.filter { o in o.danhSachPG.contains(where: { KhoCheckInPWADongBo.tenChuanHoaKhongCa($0) == key }) } ?? []
            let moTa = buoi.isEmpty ? "Chưa phân buổi" : buoi.map { $0.tenTuyen }.joined(separator: ", ")
            actions.append(UIAction(title: "👩‍💼 [PG] \(ten) — \(moTa)", state: (tenNhanSuDangLoc == ten) ? .on : .off) { [weak self] _ in
                self?.chonNhanSuXemLich(ten)
            })
        }
        for ten in dsTenNV {
            let key = BoPhanTichLichCaExcel.chuanHoa(ten)
            let buoi = kh?.cacO.filter { o in o.danhSachNV.contains(where: { KhoCheckInPWADongBo.tenChuanHoaKhongCa($0) == key }) } ?? []
            let moTa = buoi.isEmpty ? "Chưa phân buổi" : buoi.map { $0.tenTuyen }.joined(separator: ", ")
            actions.append(UIAction(title: "🧑‍🔧 [NV] \(ten) — \(moTa)", state: (tenNhanSuDangLoc == ten) ? .on : .off) { [weak self] _ in
                self?.chonNhanSuXemLich(ten)
            })
        }

        nutLocNhanSuMaTran.menu = UIMenu(title: "Chọn PG / Nhân viên xem tuyến & lịch phát", children: actions)
        if let ten = tenNhanSuDangLoc {
            nutLocNhanSuMaTran.setTitle("👤 Đang xem: \(ten) (Bấm đổi) ▾", for: .normal)
        } else {
            nutLocNhanSuMaTran.setTitle("👤 Chọn PG / NV xem tuyến & lịch phát (\(dsTenPG.count + dsTenNV.count) người) ▾", for: .normal)
        }

        // Dựng thẻ lịch & tuyến riêng cho nhân sự đang chọn
        nganLichNhanSuChon.arrangedSubviews.forEach {
            nganLichNhanSuChon.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        guard let tenChon = tenNhanSuDangLoc, !tenChon.isEmpty else {
            khungLichNhanSuChon.isHidden = true
            return
        }

        khungLichNhanSuChon.isHidden = false
        let key = KhoCheckInPWADongBo.tenChuanHoaKhongCa(tenChon)
        let cacBuoi = (kh?.cacO ?? []).filter { o in
            (o.danhSachPG + o.danhSachNV).contains { KhoCheckInPWADongBo.tenChuanHoaKhongCa($0) == key }
        }
        let dsCheckInNguoi = KhoCheckInPWADongBo.locCheckIn(choTenNguoi: tenChon, soThuTuTuyen: nil, trong: dsCheckInPWA)

        let lbHead = UILabel()
        lbHead.text = "👤 LỊCH & TUYẾN PHÁT TỜ RƠI CỦA \(tenChon.uppercased())"
        lbHead.font = .systemFont(ofSize: 12.5, weight: .heavy)
        lbHead.textColor = BangMauBCTD.xanhChuDaoDam
        lbHead.numberOfLines = 0
        lbHead.lineBreakMode = .byWordWrapping
        lbHead.adjustsFontSizeToFitWidth = false

        let nutBoLoc = UIButton(type: .system)
        nutBoLoc.setTitle("✖️ Bỏ lọc", for: .normal)
        nutBoLoc.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutBoLoc.setTitleColor(BangMauBCTD.doYeuChu, for: .normal)
        nutBoLoc.backgroundColor = BangMauBCTD.doYeuPill
        nutBoLoc.layer.cornerRadius = 7
        nutBoLoc.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        nutBoLoc.setContentHuggingPriority(.required, for: .horizontal)
        nutBoLoc.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutBoLoc.addAction(UIAction { [weak self] _ in
            self?.chonNhanSuXemLich(nil)
        }, for: .touchUpInside)

        let hangHead = UIStackView(arrangedSubviews: [lbHead, UIView(), nutBoLoc])
        hangHead.axis = .horizontal
        hangHead.alignment = .center
        hangHead.spacing = 6
        nganLichNhanSuChon.addArrangedSubview(hangHead)

        if cacBuoi.isEmpty {
            let lbTrong = UILabel()
            lbTrong.text = "Tuần này \(tenChon) chưa có buổi phân công trong ma trận (hiện đã check-in PWA: \(dsCheckInNguoi.count) lượt)."
            lbTrong.font = .systemFont(ofSize: 12, weight: .medium)
            lbTrong.textColor = BangMauBCTD.chuPhu
            lbTrong.numberOfLines = 0
            lbTrong.lineBreakMode = .byWordWrapping
            lbTrong.adjustsFontSizeToFitWidth = false
            nganLichNhanSuChon.addArrangedSubview(lbTrong)
        } else {
            for buoi in cacBuoi {
                let thu = (buoi.thuIndex >= 0 && buoi.thuIndex < BoPhanTichLichCaExcel.tenThu.count) ? BoPhanTichLichCaExcel.tenThu[buoi.thuIndex] : "Thứ"
                let khungGio = (buoi.buoi == "Sáng") ? "07:00–09:00" : "16:30–18:30"
                let tuyen = kh?.cacTuyen.first(where: { $0.id == buoi.tuyenId })
                let checkInsBuoi = KhoCheckInPWADongBo.locCheckIn(choTenNguoi: tenChon, soThuTuTuyen: tuyen?.soThuTu, trong: dsCheckInPWA)
                let daXong = buoi.daPhat || !checkInsBuoi.isEmpty
                let ttStr = checkInsBuoi.first.map { "✅ Đã check-in PWA lúc \($0.thoiGian)" } ?? (daXong ? "✅ Đã hoàn thành" : "⏳ Chưa hoàn thành")
                let kmStr = tuyen.map { " • \(BoDanDuongTuyenThucTe.dinhDangKhoangCach($0.tongQuangDuongMet)) • 🛵 ~\(BoDanDuongTuyenThucTe.dinhDangPhut($0.thoiGianXeMayPhut))" } ?? ""

                let theBuoi = UIView()
                theBuoi.backgroundColor = BangMauBCTD.nenThe
                theBuoi.layer.cornerRadius = 9
                theBuoi.layer.borderWidth = 1
                theBuoi.layer.borderColor = (daXong ? BangMauBCTD.xanhLaDam : BangMauBCTD.vienXanhNhat).withAlphaComponent(0.6).cgColor

                let lb = UILabel()
                lb.text = "🗓️ \(thu) • \(buoi.buoi) (\(khungGio))\n🛣️ \(buoi.tenTuyen)\(kmStr)\n📍 \(buoi.moTaTuyen)\n\(ttStr)"
                lb.font = .systemFont(ofSize: 12, weight: .semibold)
                lb.textColor = BangMauBCTD.chuChinh
                lb.numberOfLines = 0
                lb.lineBreakMode = .byWordWrapping
                lb.adjustsFontSizeToFitWidth = false

                let hangNut = UIStackView()
                hangNut.axis = .horizontal
                hangNut.spacing = 6
                hangNut.distribution = .fillEqually

                if let t = tuyen {
                    let nutChiDan = UIButton(type: .system)
                    nutChiDan.setTitle("🧭 Chỉ dẫn rẽ trái/phải", for: .normal)
                    nutChiDan.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
                    nutChiDan.setTitleColor(.white, for: .normal)
                    nutChiDan.backgroundColor = t.mauTuyen
                    nutChiDan.layer.cornerRadius = 8
                    nutChiDan.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
                    nutChiDan.addAction(UIAction { [weak self] _ in
                        self?.moPopupChiTietTuyen(t)
                    }, for: .touchUpInside)
                    hangNut.addArrangedSubview(nutChiDan)
                }

                if let bcDau = checkInsBuoi.first {
                    let nutAnh = UIButton(type: .system)
                    nutAnh.setTitle("🖼️ Xem ảnh & vị trí", for: .normal)
                    nutAnh.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
                    nutAnh.setTitleColor(.white, for: .normal)
                    nutAnh.backgroundColor = BangMauBCTD.xanhLaDam
                    nutAnh.layer.cornerRadius = 8
                    nutAnh.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
                    nutAnh.addAction(UIAction { [weak self] _ in
                        self?.moChiTietCheckInPWA(bcDau)
                    }, for: .touchUpInside)
                    hangNut.addArrangedSubview(nutAnh)
                } else {
                    let nutBanDo = UIButton(type: .system)
                    nutBanDo.setTitle("🗺️ Hiện trên bản đồ", for: .normal)
                    nutBanDo.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
                    nutBanDo.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
                    nutBanDo.backgroundColor = BangMauBCTD.nenHeaderPhu
                    nutBanDo.layer.cornerRadius = 8
                    nutBanDo.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
                    nutBanDo.addAction(UIAction { [weak self] _ in
                        guard let self else { return }
                        self.tuyenDangLocTrenBanDo = buoi.tuyenId
                        self.dungLaiThanhChuThichTuyen()
                        self.capNhatKhungTuyenPhatToRoi()
                        self.veLaiGhimVaTuyenTrenBanDo()
                        self.zoomVaoTuyen(id: buoi.tuyenId)
                        self.cuonChinh.setContentOffset(CGPoint(x: CGFloat(0), y: max(CGFloat(0), self.khungBanDo.frame.minY - CGFloat(8))), animated: true)
                    }, for: .touchUpInside)
                    hangNut.addArrangedSubview(nutBanDo)
                }

                let st = UIStackView(arrangedSubviews: [lb, hangNut])
                st.axis = .vertical
                st.spacing = 6
                st.translatesAutoresizingMaskIntoConstraints = false
                theBuoi.addSubview(st)
                NSLayoutConstraint.activate([
                    st.topAnchor.constraint(equalTo: theBuoi.topAnchor, constant: 8),
                    st.leadingAnchor.constraint(equalTo: theBuoi.leadingAnchor, constant: 9),
                    st.trailingAnchor.constraint(equalTo: theBuoi.trailingAnchor, constant: -9),
                    st.bottomAnchor.constraint(equalTo: theBuoi.bottomAnchor, constant: -8)
                ])
                nganLichNhanSuChon.addArrangedSubview(theBuoi)
            }
        }
    }

    private func chonNhanSuXemLich(_ ten: String?) {
        tenNhanSuDangLoc = ten
        if let ten, !ten.isEmpty, let kh = keHoachMaTran {
            let key = KhoCheckInPWADongBo.tenChuanHoaKhongCa(ten)
            if let buoiDau = kh.cacO.first(where: { o in
                (o.danhSachPG + o.danhSachNV).contains { KhoCheckInPWADongBo.tenChuanHoaKhongCa($0) == key }
            }) {
                tuyenDangLocTrenBanDo = buoiDau.tuyenId
                hienTuyenToRoi = true
                nutBatTatTuyen.setTitle("🛣️ Tuyến: Bật", for: .normal)
                nutBatTatTuyen.backgroundColor = BangMauBCTD.xanhDatVach.withAlphaComponent(0.94)
            }
        } else {
            tuyenDangLocTrenBanDo = nil
        }
        capNhatGiaoDienMaTran()
        if let loc = tuyenDangLocTrenBanDo {
            zoomVaoTuyen(id: loc)
        }
    }

    private func taoDongMaTran(_ o: OMaTranPhatToRoi) -> UIView {
        let the = UIControl()
        the.accessibilityIdentifier = o.tuyenId
        the.addTarget(self, action: #selector(bamXemTuyenTrenBanDoTuMaTran(_:)), for: .touchUpInside)
        the.backgroundColor = o.daPhat ? BangMauBCTD.xanhDatNenDong : BangMauBCTD.nenThePhu
        the.layer.cornerRadius = 10
        the.layer.borderWidth = 1
        the.layer.borderColor = (o.daPhat ? BangMauBCTD.xanhDatVach.withAlphaComponent(0.45) : BangMauBCTD.vienThe).cgColor

        let tenThu = (o.thuIndex >= 0 && o.thuIndex < BoPhanTichLichCaExcel.tenThu.count) ? BoPhanTichLichCaExcel.tenThu[o.thuIndex] : "Thứ"
        let khungGio = (o.buoi == "Sáng") ? "07:00–09:00" : "16:30–18:30"

        let lbThu = UILabel()
        lbThu.text = "\(tenThu) • \(o.buoi) (\(khungGio))"
        lbThu.font = .systemFont(ofSize: 12, weight: .heavy)
        lbThu.textColor = (o.buoi == "Sáng") ? BangMauBCTD.xanhChuDaoDam : BangMauBCTD.camPhanTich

        let nutCheck = UIButton(type: .system)
        nutCheck.setTitle(o.daPhat ? "✅ Đã phát" : "☐ Chưa phát", for: .normal)
        nutCheck.titleLabel?.font = .systemFont(ofSize: 11, weight: .bold)
        nutCheck.setTitleColor(o.daPhat ? BangMauBCTD.xanhDatChu : BangMauBCTD.doYeuChu, for: .normal)
        nutCheck.backgroundColor = o.daPhat ? BangMauBCTD.xanhDatPill : BangMauBCTD.doYeuPill
        nutCheck.layer.cornerRadius = 7
        nutCheck.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        nutCheck.accessibilityIdentifier = o.id
        nutCheck.setContentHuggingPriority(.required, for: .horizontal)
        nutCheck.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutCheck.addTarget(self, action: #selector(bamDanhDauDaPhat(_:)), for: .touchUpInside)

        let hangTren = UIStackView(arrangedSubviews: [lbThu, UIView(), nutCheck])
        hangTren.axis = .horizontal
        hangTren.alignment = .center

        let lbTuyen = UILabel()
        lbTuyen.text = "🛣️ \(o.tenTuyen)"
        lbTuyen.font = .systemFont(ofSize: 13, weight: .bold)
        lbTuyen.textColor = BangMauBCTD.chuChinh
        lbTuyen.numberOfLines = 0

        let lbMoTa = UILabel()
        let tuyenTuongUngDau = keHoachMaTran?.cacTuyen.first(where: { $0.id == o.tuyenId })
        if let t = tuyenTuongUngDau, t.tongQuangDuongMet > 0 {
            let km = BoDanDuongTuyenThucTe.dinhDangKhoangCach(t.tongQuangDuongMet)
            let xm = BoDanDuongTuyenThucTe.dinhDangPhut(t.thoiGianXeMayPhut)
            let db = BoDanDuongTuyenThucTe.dinhDangPhut(t.thoiGianDiBoPhut)
            lbMoTa.text = "\(o.moTaTuyen)\n📏 \(km) • 🛵 Xe máy ~\(xm) • 🚶 Đi bộ ~\(db)"
        } else {
            lbMoTa.text = o.moTaTuyen
        }
        lbMoTa.font = .systemFont(ofSize: 11.5, weight: .medium)
        lbMoTa.textColor = BangMauBCTD.chuPhu
        lbMoTa.numberOfLines = 0
        lbMoTa.lineBreakMode = .byWordWrapping
        lbMoTa.adjustsFontSizeToFitWidth = false

        var dongNhanSu: [String] = []
        if !o.danhSachPG.isEmpty {
            dongNhanSu.append("👩‍💼 PG (\(o.danhSachPG.count)): \(o.danhSachPG.joined(separator: ", "))")
        } else if khoiLichPG != nil && cauHinhPhanTuyen.soPGMoiTuyen > 0 {
            dongNhanSu.append("👩‍💼 PG: Đã hết PG chưa phát trong ca này (bấm Sửa nhân sự để gán thêm)")
        }
        if !o.danhSachNV.isEmpty {
            dongNhanSu.append("🧑‍🔧 NV (\(o.danhSachNV.count)): \(o.danhSachNV.joined(separator: ", "))")
        } else if khoiLichNV != nil && cauHinhPhanTuyen.soNVMoiTuyen > 0 {
            dongNhanSu.append("🧑‍🔧 NV: Đã hết NV chưa phát trong ca này (bấm Sửa nhân sự để gán thêm)")
        }
        if dongNhanSu.isEmpty {
            dongNhanSu.append("ℹ️ Tải Google Trang tính PG/NV hoặc bấm “👥 Sửa nhân sự” để thêm người vào tuyến.")
        }

        let lbNS = UILabel()
        lbNS.text = dongNhanSu.joined(separator: "\n")
        lbNS.font = .systemFont(ofSize: 11.5, weight: .semibold)
        lbNS.textColor = BangMauBCTD.xanhLaDam
        lbNS.numberOfLines = 0
        lbNS.lineBreakMode = .byWordWrapping
        lbNS.adjustsFontSizeToFitWidth = false

        // Trạng thái kiểm soát bằng chứng vị trí Google Maps + Ảnh minh chứng (gộp cả PWA đồng bộ & nội bộ)
        let dsBangChung = KhoBangChungPhatToRoi.dungChung.layBangChung(choOId: o.id)
        let dsPWA = KhoCheckInPWADongBo.locCheckIn(choO: o, cacTuyen: keHoachMaTran?.cacTuyen ?? [], trong: dsCheckInPWA)
        let tuyenTuongUng = keHoachMaTran?.cacTuyen.first(where: { $0.id == o.tuyenId })
        let tongDiem = tuyenTuongUng?.cacDiemMucTieu.count ?? 0
        let soDiemCheck = Set(dsBangChung.map { $0.diemId }).count
        let soHopLe = dsBangChung.filter { $0.trangThaiViTri.hopLe }.count
        let coLech = dsBangChung.contains(where: { !$0.trangThaiViTri.hopLe })
        let tongMinhChung = dsPWA.count + dsBangChung.count

        let lbKiemSoat = UILabel()
        lbKiemSoat.font = .systemFont(ofSize: 11.5, weight: .bold)
        lbKiemSoat.numberOfLines = 0
        lbKiemSoat.lineBreakMode = .byWordWrapping
        lbKiemSoat.adjustsFontSizeToFitWidth = false
        if !dsPWA.isEmpty {
            let tenNop = dsPWA.map { "\($0.tenSachKhongNgoac) (\($0.thoiGian))" }.prefix(2).joined(separator: ", ")
            lbKiemSoat.text = "✅ Hoàn thành (PWA): \(dsPWA.count) ảnh/GPS • \(tenNop)"
            lbKiemSoat.textColor = BangMauBCTD.xanhLaDam
        } else if dsBangChung.isEmpty {
            lbKiemSoat.text = "⏳ Chưa hoàn thành: Chưa có check-in & ảnh từ PWA"
            lbKiemSoat.textColor = BangMauBCTD.chuMo
        } else if coLech {
            let phanDiem = tongDiem > 0 ? " (\(soDiemCheck)/\(tongDiem) điểm)" : ""
            lbKiemSoat.text = "⚠️ Kiểm soát: \(dsBangChung.count) ảnh/GPS\(phanDiem) • \(soHopLe) đúng vị trí, có điểm lệch xa!"
            lbKiemSoat.textColor = .systemRed
        } else {
            let phanDiem = tongDiem > 0 ? " (\(soDiemCheck)/\(tongDiem) điểm)" : ""
            lbKiemSoat.text = "🛡️ Kiểm soát: Đã xác minh \(dsBangChung.count) ảnh/GPS\(phanDiem) • 🟢 Đúng vị trí"
            lbKiemSoat.textColor = BangMauBCTD.xanhLaDam
        }

        let nutLoTrinh = UIButton(type: .system)
        nutLoTrinh.setTitle("🧭 Lộ trình", for: .normal)
        nutLoTrinh.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutLoTrinh.titleLabel?.numberOfLines = 0
        nutLoTrinh.titleLabel?.lineBreakMode = .byWordWrapping
        nutLoTrinh.titleLabel?.adjustsFontSizeToFitWidth = false
        nutLoTrinh.setTitleColor(tuyenTuongUng?.mauTuyen ?? BangMauBCTD.xanhChuDaoDam, for: .normal)
        nutLoTrinh.backgroundColor = BangMauBCTD.nenThe
        nutLoTrinh.layer.cornerRadius = 8
        nutLoTrinh.layer.borderWidth = 1.2
        nutLoTrinh.layer.borderColor = (tuyenTuongUng?.mauTuyen ?? BangMauBCTD.xanhChuDao).withAlphaComponent(0.55).cgColor
        nutLoTrinh.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        nutLoTrinh.accessibilityIdentifier = o.tuyenId
        nutLoTrinh.addTarget(self, action: #selector(bamMoChiTietTuyenTuNut(_:)), for: .touchUpInside)

        let nutSuaNhanSu = UIButton(type: .system)
        nutSuaNhanSu.setTitle("👥 Nhân sự", for: .normal)
        nutSuaNhanSu.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutSuaNhanSu.titleLabel?.numberOfLines = 0
        nutSuaNhanSu.titleLabel?.lineBreakMode = .byWordWrapping
        nutSuaNhanSu.titleLabel?.adjustsFontSizeToFitWidth = false
        nutSuaNhanSu.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
        nutSuaNhanSu.backgroundColor = BangMauBCTD.nenHeaderPhu
        nutSuaNhanSu.layer.cornerRadius = 8
        nutSuaNhanSu.layer.borderWidth = 1
        nutSuaNhanSu.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
        nutSuaNhanSu.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        nutSuaNhanSu.accessibilityIdentifier = o.id
        nutSuaNhanSu.addTarget(self, action: #selector(bamSuaNhanSuTuyen(_:)), for: .touchUpInside)

        let nutKiemSoat = UIButton(type: .system)
        nutKiemSoat.setTitle(tongMinhChung == 0 ? "📍 Check-in" : "🖼️ Xem ảnh (\(tongMinhChung))", for: .normal)
        nutKiemSoat.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutKiemSoat.titleLabel?.numberOfLines = 0
        nutKiemSoat.titleLabel?.lineBreakMode = .byWordWrapping
        nutKiemSoat.titleLabel?.adjustsFontSizeToFitWidth = false
        nutKiemSoat.setTitleColor(.white, for: .normal)
        nutKiemSoat.backgroundColor = tongMinhChung == 0 ? BangMauBCTD.xanhChuDao : (coLech && dsPWA.isEmpty ? .systemRed : BangMauBCTD.xanhLaDam)
        nutKiemSoat.layer.cornerRadius = 8
        nutKiemSoat.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        if let pwaDau = dsPWA.first {
            nutKiemSoat.addAction(UIAction { [weak self] _ in
                self?.moChiTietCheckInPWA(pwaDau)
            }, for: .touchUpInside)
        } else {
            nutKiemSoat.accessibilityIdentifier = o.id
            nutKiemSoat.addTarget(self, action: #selector(bamMoKiemSoatPhat(_:)), for: .touchUpInside)
        }

        let hangThaoTacO = UIStackView(arrangedSubviews: [nutLoTrinh, nutSuaNhanSu, nutKiemSoat])
        hangThaoTacO.axis = .horizontal
        hangThaoTacO.spacing = 6
        hangThaoTacO.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [hangTren, lbTuyen, lbMoTa, lbNS, lbKiemSoat, hangThaoTacO])
        stack.axis = .vertical
        stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false
        the.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: the.topAnchor, constant: 9),
            stack.leadingAnchor.constraint(equalTo: the.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: the.trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: the.bottomAnchor, constant: -9)
        ])

        return the
    }

    @objc private func bamSuaNhanSuTuyen(_ sender: UIButton) {
        guard let kh = keHoachMaTran,
              let idO = sender.accessibilityIdentifier,
              let o = kh.cacO.first(where: { $0.id == idO }) else { return }

        let vc = HopChinhSuaNhanSuTuyenViewController(
            oMaTran: o,
            khoiPG: khoiLichPG,
            khoiNV: khoiLichNV,
            keHoachTuan: kh
        ) { [weak self] oMoi in
            guard let self, var khCapNhat = self.keHoachMaTran,
                  let idx = khCapNhat.cacO.firstIndex(where: { $0.id == oMoi.id }) else { return }
            khCapNhat.cacO[idx] = oMoi
            self.keHoachMaTran = khCapNhat
            KhoMaTranPhatToRoi.dungChung.luuKeHoach(khCapNhat)
            KhoSoXoayTuaThang.dungChung.capNhatTuKeHoachTuan(khCapNhat)
            self.capNhatGiaoDienMaTran()
            self.dongBoLichLenPWANen()
        }
        let nav = UINavigationController(rootViewController: vc)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    @objc private func bamMoKiemSoatPhat(_ sender: UIButton) {
        guard let kh = keHoachMaTran,
              let idO = sender.accessibilityIdentifier,
              let o = kh.cacO.first(where: { $0.id == idO }) else { return }
        moManHinhKiemSoat(cho: o)
    }

    private func moManHinhKiemSoat(cho o: OMaTranPhatToRoi) {
        let tuyen = keHoachMaTran?.cacTuyen.first(where: { $0.id == o.tuyenId })
        let vc = ManHinhKiemSoatPhatToRoiViewController(
            oMaTran: o,
            tuyen: tuyen,
            nguongMet: cauHinhPhanTuyen.nguongKiemSoatMet
        ) { [weak self] coBangChungMoi in
            guard let self else { return }
            if coBangChungMoi, var kh = self.keHoachMaTran,
               let idx = kh.cacO.firstIndex(where: { $0.id == o.id }) {
                kh.cacO[idx].daPhat = true
                self.keHoachMaTran = kh
                KhoMaTranPhatToRoi.dungChung.luuKeHoach(kh)
            }
            self.capNhatGiaoDienMaTran()
        }
        let nav = UINavigationController(rootViewController: vc)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    @objc private func bamXemKiemSoatTuan() {
        let vc = HopQuanLyCheckInPWAViewController(
            keHoach: keHoachMaTran,
            dsCheckIn: dsCheckInPWA,
            khiCapNhatCheckIn: { [weak self] dsMoi in
                guard let self else { return }
                self.dsCheckInPWA = dsMoi
                self.capNhatNutCheDoTrangThaiPhat()
                self.capNhatGiaoDienMaTran()
            },
            khiXemTrenBanDo: { [weak self] banGhi in
                self?.zoomDenGhimCheckInPWA(banGhi)
            }
        )
        let nav = UINavigationController(rootViewController: vc)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    @objc private func bamXemLichCaDaQuet() {
        let dsPG = khoiLichPG?.danhSachNguoi ?? []
        let dsNV = khoiLichNV?.danhSachNguoi ?? []
        guard !dsPG.isEmpty || !dsNV.isEmpty else {
            hienThongBao(tieuDe: "Chưa có dữ liệu lịch ca", noiDung: "Hãy dán link Google Trang tính ở ô phía trên rồi bấm “🔄 Tải lịch PG & NV”.")
            return
        }
        let tieuDePG = khoiLichPG.map { "👩‍💼 Lịch PG — \($0.tenTuan) (\($0.danhSachNguoi.count) người)" } ?? "👩‍💼 Lịch PG"
        let tieuDeNV = khoiLichNV.map { "🧑‍🔧 Lịch Nhân viên (\($0.tenSheet)) — \($0.tenTuan) (\($0.danhSachNguoi.count) người)" } ?? "🧑‍🔧 Lịch Nhân viên"
        let vc = HopXemLichCaDaQuetViewController(dsPG: dsPG, dsNV: dsNV, tieuDePG: tieuDePG, tieuDeNV: tieuDeNV)
        let nav = UINavigationController(rootViewController: vc)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    private func taoThanhChuThichTuyenBanDo() -> UIView {
        cuonChuThichTuyen.showsHorizontalScrollIndicator = false
        cuonChuThichTuyen.translatesAutoresizingMaskIntoConstraints = false
        cuonChuThichTuyen.heightAnchor.constraint(equalToConstant: 34).isActive = true

        nganChuThichTuyen.axis = .horizontal
        nganChuThichTuyen.spacing = 6
        nganChuThichTuyen.alignment = .center
        nganChuThichTuyen.translatesAutoresizingMaskIntoConstraints = false
        cuonChuThichTuyen.addSubview(nganChuThichTuyen)

        NSLayoutConstraint.activate([
            nganChuThichTuyen.topAnchor.constraint(equalTo: cuonChuThichTuyen.contentLayoutGuide.topAnchor),
            nganChuThichTuyen.bottomAnchor.constraint(equalTo: cuonChuThichTuyen.contentLayoutGuide.bottomAnchor),
            nganChuThichTuyen.leadingAnchor.constraint(equalTo: cuonChuThichTuyen.contentLayoutGuide.leadingAnchor),
            nganChuThichTuyen.trailingAnchor.constraint(equalTo: cuonChuThichTuyen.contentLayoutGuide.trailingAnchor),
            nganChuThichTuyen.heightAnchor.constraint(equalTo: cuonChuThichTuyen.frameLayoutGuide.heightAnchor)
        ])
        return cuonChuThichTuyen
    }

    private func dungLaiThanhChuThichTuyen() {
        nganChuThichTuyen.arrangedSubviews.forEach {
            nganChuThichTuyen.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let cacTuyen = (keHoachMaTran?.cacTuyen ?? []).filter { $0.cacToaDo.count >= 2 }
        cuonChuThichTuyen.isHidden = cacTuyen.isEmpty
        guard !cacTuyen.isEmpty else { return }

        let nutTatCa = UIButton(type: .system)
        let dangChonAll = (tuyenDangLocTrenBanDo == nil)
        nutTatCa.setTitle("Tất cả (\(cacTuyen.count) tuyến)", for: .normal)
        nutTatCa.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        nutTatCa.setTitleColor(dangChonAll ? .white : BangMauBCTD.chuChinh, for: .normal)
        nutTatCa.backgroundColor = dangChonAll ? BangMauBCTD.xanhChuDao : BangMauBCTD.nenThe
        nutTatCa.layer.cornerRadius = 9
        nutTatCa.layer.borderWidth = 1
        nutTatCa.layer.borderColor = (dangChonAll ? BangMauBCTD.xanhChuDaoDam : BangMauBCTD.vienDam).cgColor
        nutTatCa.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        nutTatCa.accessibilityIdentifier = "ALL"
        nutTatCa.addTarget(self, action: #selector(bamLocTuyenTrenBanDo(_:)), for: .touchUpInside)
        nganChuThichTuyen.addArrangedSubview(nutTatCa)

        for t in cacTuyen {
            let dangChon = (tuyenDangLocTrenBanDo == t.id)
            let nut = UIButton(type: .system)
            nut.setTitle("● Tuyến \(t.soThuTu)", for: .normal)
            nut.titleLabel?.font = .systemFont(ofSize: 12, weight: .heavy)
            nut.setTitleColor(dangChon ? .white : t.mauTuyen, for: .normal)
            nut.backgroundColor = dangChon ? t.mauTuyen : BangMauBCTD.nenThe
            nut.layer.cornerRadius = 9
            nut.layer.borderWidth = 1.4
            nut.layer.borderColor = t.mauTuyen.cgColor
            nut.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
            nut.accessibilityIdentifier = t.id
            nut.addTarget(self, action: #selector(bamLocTuyenTrenBanDo(_:)), for: .touchUpInside)
            nganChuThichTuyen.addArrangedSubview(nut)
        }
    }

    private func capNhatKhungChiTietTuyenDangChon() {
        // Đã gộp gọn chỉ dẫn tuyến đang chọn vào thẻ Chọn tuyến chính bên dưới 1 dòng KPI để tránh lặp thẻ
        khungChiTietTuyenChon.isHidden = true
    }

    @objc private func bamMoChiTietTuyenDangChon() {
        guard let locID = tuyenDangLocTrenBanDo,
              let tuyen = keHoachMaTran?.cacTuyen.first(where: { $0.id == locID }) else { return }
        moPopupChiTietTuyen(tuyen)
    }

    @objc private func bamMoGGMapsTuyenDangChon() {
        guard let locID = tuyenDangLocTrenBanDo,
              let tuyen = keHoachMaTran?.cacTuyen.first(where: { $0.id == locID }) else { return }
        moGoogleMapsChoTuyen(tuyen)
    }

    @objc private func bamMoChiTietTuyenTuNut(_ sender: UIButton) {
        guard let id = sender.accessibilityIdentifier,
              let tuyen = keHoachMaTran?.cacTuyen.first(where: { $0.id == id }) else { return }
        moPopupChiTietTuyen(tuyen)
    }

    private func moPopupChiTietTuyen(_ tuyen: TuyenPhatToRoiMaTran) {
        let vc = HopChiTietTuyenDuongViewController(
            tuyen: tuyen,
            khiMoGoogleMaps: { [weak self] t in
                self?.moGoogleMapsChoTuyen(t)
            },
            khiCapNhatTuyen: { [weak self] tMoi in
                guard let self, var kh = self.keHoachMaTran,
                      let idx = kh.cacTuyen.firstIndex(where: { $0.id == tMoi.id }) else { return }
                kh.cacTuyen[idx] = tMoi
                self.keHoachMaTran = kh
                KhoMaTranPhatToRoi.dungChung.luuKeHoach(kh)
                self.veLaiGhimVaTuyenTrenBanDo()
                self.capNhatKhungChiTietTuyenDangChon()
            }
        )
        let nav = UINavigationController(rootViewController: vc)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    @objc private func bamLocTuyenTrenBanDo(_ sender: UIButton) {
        let id = sender.accessibilityIdentifier ?? "ALL"
        if id == "ALL" {
            tuyenDangLocTrenBanDo = nil
        } else {
            tuyenDangLocTrenBanDo = (tuyenDangLocTrenBanDo == id) ? nil : id
        }
        dungLaiThanhChuThichTuyen()
        capNhatKhungTuyenPhatToRoi()
        capNhatKhungChiTietTuyenDangChon()
        veLaiGhimVaTuyenTrenBanDo()
        if let loc = tuyenDangLocTrenBanDo {
            zoomVaoTuyen(id: loc)
        }
    }

    @objc private func bamXemTuyenTrenBanDoTuMaTran(_ sender: UIControl) {
        guard let id = sender.accessibilityIdentifier else { return }
        tuyenDangLocTrenBanDo = id
        hienTuyenToRoi = true
        nutBatTatTuyen.setTitle("🛣️ Tuyến: Bật", for: .normal)
        nutBatTatTuyen.backgroundColor = BangMauBCTD.xanhDatVach.withAlphaComponent(0.94)
        dungLaiThanhChuThichTuyen()
        capNhatKhungTuyenPhatToRoi()
        capNhatKhungChiTietTuyenDangChon()
        veLaiGhimVaTuyenTrenBanDo()
        zoomVaoTuyen(id: id)
        cuonChinh.setContentOffset(CGPoint(x: 0, y: max(0, khungBanDo.frame.minY - 8)), animated: true)
    }

    private func zoomVaoTuyen(id: String) {
        guard let tuyen = keHoachMaTran?.cacTuyen.first(where: { $0.id == id }),
              tuyen.toaDoVeBanDo.count >= 2 else { return }
        var minLat = Double.greatestFiniteMagnitude
        var maxLat = -Double.greatestFiniteMagnitude
        var minLon = Double.greatestFiniteMagnitude
        var maxLon = -Double.greatestFiniteMagnitude
        for pair in tuyen.toaDoVeBanDo where pair.count >= 2 {
            minLat = min(minLat, pair[0]); maxLat = max(maxLat, pair[0])
            minLon = min(minLon, pair[1]); maxLon = max(maxLon, pair[1])
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2.0, longitude: (minLon + maxLon) / 2.0)
        let span = MKCoordinateSpan(latitudeDelta: max((maxLat - minLat) * 1.55, 0.007), longitudeDelta: max((maxLon - minLon) * 1.55, 0.007))
        banDo.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
    }

    @objc private func bamXemSoXoayTuaThang() {
        let bang = KhoSoXoayTuaThang.dungChung.layBangThang()
        guard !bang.isEmpty else {
            hienThongBao(tieuDe: "Chưa có sổ xoay tua tháng", noiDung: "Hãy tải dữ liệu từ link Google Trang tính PG & NV rồi bấm “⚡ Phân lịch xoay vòng” để theo dõi xoay tua tháng.")
            return
        }
        let vc = HopSoXoayTuaThangViewController(danhSach: bang) { [weak self] in
            self?.capNhatGiaoDienMaTran()
        }
        let nav = UINavigationController(rootViewController: vc)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    @objc private func bamCopyMaTranTuan() {
        guard let kh = keHoachMaTran else {
            hienThongBao(tieuDe: "Chưa có ma trận", noiDung: "Hãy bấm \"⚡ Phân lịch xoay vòng\" trước khi sao chép.")
            return
        }
        let tuyenDaPhatIDs = Set(kh.cacO.filter { $0.daPhat }.map { $0.tuyenId })
        let tuyenChuaPhat = kh.cacTuyen.filter { !tuyenDaPhatIDs.contains($0.id) }

        var dong: [String] = [
            "📅 MA TRẬN PHÁT TỜ RƠI XOAY VÒNG (\(kh.nhanTuan))",
            "• Nguồn PG: \(kh.tenNguonPG)",
            "• Nguồn NV: \(kh.tenNguonNV)"
        ]
        if !tuyenChuaPhat.isEmpty {
            dong.append("⚠️ Tuyến chưa phát: \(tuyenChuaPhat.map { $0.ten }.joined(separator: ", "))")
        } else {
            dong.append("✅ Đã phát đủ tất cả \(kh.cacTuyen.count) tuyến!")
        }
        dong.append("")

        for o in kh.cacO {
            let thu = (o.thuIndex >= 0 && o.thuIndex < BoPhanTichLichCaExcel.tenThu.count) ? BoPhanTichLichCaExcel.tenThu[o.thuIndex] : ""
            let tt = o.daPhat ? "[ĐÃ PHÁT]" : "[CHƯA PHÁT]"
            var ns: [String] = []
            if !o.danhSachPG.isEmpty { ns.append("PG: \(o.danhSachPG.joined(separator: ", "))") }
            if !o.danhSachNV.isEmpty { ns.append("NV: \(o.danhSachNV.joined(separator: ", "))") }
            let chuoiNS = ns.isEmpty ? "Chưa phân nhân sự" : ns.joined(separator: " | ")
            dong.append("• \(thu) (\(o.buoi)) \(tt): \(o.tenTuyen) → \(chuoiNS)")
        }

        UIPasteboard.general.string = dong.joined(separator: "\n")
        hienThongBao(tieuDe: "Đã sao chép", noiDung: "Đã sao chép toàn bộ Ma trận phát tờ rơi xoay vòng tuần này để gửi nhóm LINE/Zalo.")
    }

}


// MARK: - Màn Hình Đối Chiếu Tên & Thời Gian Làm Việc Đã Đọc Từ Google Trang Tính

private final class HopXemLichCaDaQuetViewController: UITableViewController {
    private let cacNhom: [(tieuDe: String, danhSach: [LichTuanMotNguoi])]

    init(dsPG: [LichTuanMotNguoi], dsNV: [LichTuanMotNguoi], tieuDePG: String, tieuDeNV: String) {
        var nhom: [(String, [LichTuanMotNguoi])] = []
        if !dsPG.isEmpty { nhom.append((tieuDePG, dsPG)) }
        if !dsNV.isEmpty { nhom.append((tieuDeNV, dsNV)) }
        self.cacNhom = nhom
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("Khong ho tro coder")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let tong = cacNhom.reduce(0) { $0 + $1.danhSach.count }
        title = "Lịch ca (\(tong) người)"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Đóng", style: .done, target: self, action: #selector(bamDong))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 104
    }

    @objc private func bamDong() {
        dismiss(animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return cacNhom.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return cacNhom[section].tieuDe
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cacNhom[section].danhSach.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "CellXemLichCa"
        let cell = tableView.dequeueReusableCell(withIdentifier: id)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: id)
        let nguoi = cacNhom[indexPath.section].danhSach[indexPath.row]
        let nganh = nguoi.nganhHang.isEmpty ? nguoi.nhom.rawValue : "\(nguoi.nhom.rawValue) • \(nguoi.nganhHang)"
        cell.textLabel?.text = "\(nguoi.ten) (\(nganh))"
        cell.textLabel?.font = .systemFont(ofSize: 13.5, weight: .bold)
        cell.textLabel?.textColor = BangMauBCTD.chuChinh
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.adjustsFontSizeToFitWidth = false

        let tenThuNgan = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
        var dongChiTiet: [String] = []
        for (i, ca) in nguoi.lich7Ngay.enumerated() where i < tenThuNgan.count {
            let caText = [ca.nhanCaGoc, ca.gioLamGoc].filter { !$0.isEmpty }.joined(separator: " ")
            let ranhTag: String
            if ca.dangLamSang && ca.dangLamChieu { ranhTag = "→ Sáng & Chiều" }
            else if ca.dangLamSang { ranhTag = "→ Sáng" }
            else if ca.dangLamChieu { ranhTag = "→ Chiều" }
            else { ranhTag = "(OFF)" }
            let noiDungCa = caText.isEmpty ? "Trống" : caText
            dongChiTiet.append("\(tenThuNgan[i]): \(noiDungCa) \(ranhTag)")
        }

        cell.detailTextLabel?.text = dongChiTiet.joined(separator: "\n")
        cell.detailTextLabel?.font = .systemFont(ofSize: 11.5, weight: .medium)
        cell.detailTextLabel?.textColor = BangMauBCTD.chuPhu
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.lineBreakMode = .byWordWrapping
        cell.detailTextLabel?.adjustsFontSizeToFitWidth = false
        cell.selectionStyle = .none
        return cell
    }
}


// MARK: - Sổ Theo Dõi Xoay Tua Theo Tháng (Đảm Bảo 100% PG/NV Đều Đi Phát, Không Bỏ Sót Ai)

private final class HopSoXoayTuaThangViewController: UITableViewController {
    private var danhSach: [BanGhiXoayTuaThang]
    private let khiCapNhat: () -> Void

    init(danhSach: [BanGhiXoayTuaThang], khiCapNhat: @escaping () -> Void) {
        self.danhSach = danhSach
        self.khiCapNhat = khiCapNhat
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("Khong ho tro coder")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Xoay tua \(KhoSoXoayTuaThang.nhanThangHienTai())"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Reset tháng", style: .plain, target: self, action: #selector(bamResetThang))
        navigationItem.leftBarButtonItem?.tintColor = BangMauBCTD.doYeuChu
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Đóng", style: .done, target: self, action: #selector(bamDong))
    }

    @objc private func bamDong() {
        dismiss(animated: true)
    }

    @objc private func bamResetThang() {
        let ac = UIAlertController(title: "Reset sổ xoay tua tháng?", message: "Xóa bộ đếm lượt phát của \(KhoSoXoayTuaThang.nhanThangHienTai()) để tính lại từ đầu.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Xóa & tính lại", style: .destructive) { [weak self] _ in
            KhoSoXoayTuaThang.dungChung.xoaSoThang()
            self?.danhSach = []
            self?.tableView.reloadData()
            self?.khiCapNhat()
        })
        ac.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        present(ac, animated: true)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let chua = danhSach.filter { $0.cacTuanDaPhat.isEmpty }.count
        return "Người 0 lượt xếp trên cùng & tự động được ưu tiên vào tuần tiếp theo (Chưa phát: \(chua)/\(danhSach.count))"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return danhSach.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "CellSoThang"
        let cell = tableView.dequeueReusableCell(withIdentifier: id)
            ?? UITableViewCell(style: .value1, reuseIdentifier: id)
        let rec = danhSach[indexPath.row]
        let soLan = rec.cacTuanDaPhat.count
        cell.textLabel?.text = "\(rec.tenGoc) (\(rec.nhom.rawValue))"
        cell.textLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        cell.textLabel?.textColor = BangMauBCTD.chuChinh

        if soLan == 0 {
            cell.detailTextLabel?.text = "⚠️ 0 lượt (ưu tiên)"
            cell.detailTextLabel?.textColor = BangMauBCTD.doYeuChu
        } else {
            cell.detailTextLabel?.text = "✅ \(soLan) lượt"
            cell.detailTextLabel?.textColor = BangMauBCTD.xanhDatChu
        }
        cell.detailTextLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        cell.selectionStyle = .none
        return cell
    }
}
