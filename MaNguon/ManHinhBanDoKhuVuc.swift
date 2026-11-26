import UIKit
import MapKit
import CoreLocation
import UniformTypeIdentifiers

// MARK: - Mô Hình Dữ Liệu Quét Khu Vực, Siêu Thị Đã Lưu & Tuyến Phát Tờ Rơi

enum LoaiDiaDiemQuet: String, CaseIterable, Codable {
    case doiThu = "doi_thu"
    case heThongMWG = "he_thong_mwg"
    case truongHoc = "truong_hoc"
    case cho = "cho"

    var tieuDe: String {
        switch self {
        case .doiThu: return "Đối thủ"
        case .heThongMWG: return "ĐMX/TGDĐ"
        case .truongHoc: return "Trường học"
        case .cho: return "Chợ"
        }
    }

    var tieuDeNgan: String {
        switch self {
        case .doiThu: return "Đối thủ"
        case .heThongMWG: return "ĐMX/TGDĐ"
        case .truongHoc: return "Trường"
        case .cho: return "Chợ"
        }
    }

    var tieuDeDayDu: String {
        switch self {
        case .doiThu: return "Đối thủ (Điện máy / Gia dụng)"
        case .heThongMWG: return "Cửa hàng ĐMX / TGDĐ"
        case .truongHoc: return "Trường học"
        case .cho: return "Chợ"
        }
    }

    var bieuTuongSF: String {
        switch self {
        case .doiThu: return "storefront.fill"
        case .heThongMWG: return "bolt.fill"
        case .truongHoc: return "graduationcap.fill"
        case .cho: return "basket.fill"
        }
    }

    var mauChuDao: UIColor {
        switch self {
        case .doiThu: return UIColor(red: 0.86, green: 0.15, blue: 0.15, alpha: 1.0)      // Đỏ #DC2626
        case .heThongMWG: return UIColor(red: 0.05, green: 0.58, blue: 0.53, alpha: 1.0)  // Xanh ngọc #0D9488
        case .truongHoc: return UIColor(red: 0.14, green: 0.39, blue: 0.92, alpha: 1.0)   // Xanh dương #2563EB
        case .cho: return UIColor(red: 0.85, green: 0.47, blue: 0.02, alpha: 1.0)         // Cam vàng #D97706
        }
    }

    var mauNenNhat: UIColor {
        switch self {
        case .doiThu: return UIColor(red: 1.00, green: 0.95, blue: 0.95, alpha: 1.0)
        case .heThongMWG: return UIColor(red: 0.91, green: 0.99, blue: 0.97, alpha: 1.0)
        case .truongHoc: return UIColor(red: 0.93, green: 0.96, blue: 1.00, alpha: 1.0)
        case .cho: return UIColor(red: 1.00, green: 0.97, blue: 0.88, alpha: 1.0)
        }
    }

    /// Trọng số hiệu quả phát tờ rơi (Chợ & Trường học ưu tiên cao nhất, tiếp đến vùng Đối thủ)
    var diemUuTienToRoi: Double {
        switch self {
        case .cho: return 10.0
        case .truongHoc: return 9.0
        case .doiThu: return 7.0
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

struct DiaDiemQuet: Equatable {
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
            ("chợ", .cho)
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
        [out:json][timeout:14];
        (
          nwr(around:\(r),\(lat),\(lon))["amenity"~"^(school|kindergarten|college|university|marketplace)$"];
          nwr(around:\(r),\(lat),\(lon))["shop"~"^(electronics|appliance|electrical|houseware|hifi|computer|mobile_phone|marketplace)$"];
          nwr(around:\(r),\(lat),\(lon))["name"~"^(Chợ|Trường|Điện [Mm]áy|Điện [Ll]ạnh|Điện [Cc]ơ|Điện [Tt]hoại|Máy [Ll]ạnh|Thế [Gg]iới [Dd]i [Đđ]ộng|TopZone|Gia [Dd]ụng|Siêu [Tt]hị Điện)",i];
        );
        out center tags 280;
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
            ("keyword=chợ", .cho)
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
            .restaurant, .cafe, .bakery, .brewery, .winery, .nightlife,
            .hotel, .gasStation, .parking, .carRental, .evCharger,
            .hospital, .pharmacy, .bank, .atm, .postOffice, .police, .fireStation,
            .park, .beach, .campground, .marina, .museum, .theater, .movieTheater,
            .fitnessCenter, .stadium, .zoo, .amusementPark, .aquarium, .publicTransport, .airport
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

        // 2. Bộ lọc loại trừ TUYỆT ĐỐI: Ăn uống, Ô tô / Xe cộ, Khách sạn, Y tế, Ngân hàng, Tạp hóa...
        let loaiTruAnUong = [
            "nha hang", "quan an", "quan nhau", "quan com", "com tam", "com ga", "com binh dan",
            "bun bo", "bun cha", "bun rieu", "bun dau", "bun thit", "pho bo", "pho ga", "mi quang",
            "hu tieu", "banh mi", "banh xeo", "banh canh", "banh cuon", "banh beo", "banh trang",
            "lau ", "nuong ", "hai san", "thit cho", "thit de", "thit trau", "vit quay", "ga ran",
            "dac san", "am thuc", "buffet", "tra sua", "ca phe", "cafe", "coffee", "bia hoi",
            "quan bia", "karaoke", "bakery", "tiem banh", "an vat", "be thui", "chao long",
            "chao vit", "chao ech", "quan oc", "oc ", "bo ne", "bo kho", "pizza", "burger",
            "kfc", "lotteria", "jollibee", "highlands", "phuc long", "trung nguyen", "quán "
        ]
        let loaiTruXeCo = [
            "o to", "oto", "garage", "gara", "rua xe", "sua xe", "xe may", "xe dap",
            "phu tung", "lop xe", "vo xe", "cham soc xe", "bai giu xe", "cay xang",
            "tram xang", "petrolimex", "pvoil", "ben xe", "showroom", "dai ly xe",
            "hyundai", "toyota", "honda", "mazda", "vinfast", "mitsubishi", "suzuki",
            "yamaha", "ford ", "chevrolet", "mercedes", "bmw ", "kia ", "isuzu", "thaco",
            "mua ban xe", "do choi xe", "noi that xe", "dan phim cach nhiet"
        ]
        let loaiTruKhac = [
            "khach san", "nha nghi", "homestay", "hotel", "motel", "resort",
            "salon", "cat toc", "tham my", "nha thuoc", "phong kham", "benh vien", "nha khoa",
            "ngan hang", "buu dien", "cong an", "uy ban", "ubnd", "chua ", "nha tho",
            "tap hoa", "bach hoa xanh", "winmart", "vinmart", "circle k", "gs25", "7-eleven",
            "coopfood", "satrafoods", "familymart", "ministop", "spa ", "massage", "bida",
            "billiards", "tiem vang", "cam do", "xay dung", "vat lieu", "sat thep", "go noi that"
        ]

        let biLoaiAnUong = loaiTruAnUong.contains(where: { t.contains($0) || tenGoc.contains($0) })
            || coTuNguyen(t, tu: "quan")
            || coTuNguyen(t, tu: "pho")
            || coTuNguyen(t, tu: "bun")
            || coTuNguyen(t, tu: "com")
            || coTuNguyen(t, tu: "bar")
            || coTuNguyen(t, tu: "pub")
        let biLoaiXeCo = loaiTruXeCo.contains(where: { t.contains($0) })
        let biLoaiKhac = loaiTruKhac.contains(where: { t.contains($0) }) || coTuNguyen(t, tu: "atm")

        if biLoaiAnUong || biLoaiXeCo || biLoaiKhac {
            return nil
        }

        // 3. Nhận diện CHỢ (bắt buộc giữ dấu tiếng Việt "chợ" để KHÔNG BAO GIỜ nhầm "Thịt Chó" thành "Chợ"!)
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

        // 4. Nhận diện TRƯỜNG HỌC
        let tuKhoaTruong = [
            "truong ", "tieu hoc", "thcs", "thpt", "mam non", "mau giao", "nha tre",
            "dai hoc", "cao dang", "trung cap", "hoc vien", "school", "kindergarten",
            "university", "college", "academy", "anh ngu", "ngoai ngu"
        ]
        if tuKhoaTruong.contains(where: { t.contains($0) }) || (tagOSMChacChan && goiY == .truongHoc) {
            return .truongHoc
        }

        // 5. Nhận diện ĐỐI THỦ (CHỈ nhận đúng ngành: Điện máy, Điện cơ, Điện thoại, Máy lạnh, Điện lạnh, Gia dụng, Điện tử...)
        // Tuyệt đối KHÔNG fallback bừa bãi!
        let tuKhoaDoiThuChuan = [
            // Điện máy & chuỗi đối thủ
            "dien may", "sieu thi dien may", "nguyen kim", "mediamart", "pico", "dien may cho lon",
            "fpt shop", "cellphones", "viettel store", "hoang ha mobile", "di dong viet",
            "bach long", "phong vu", "gearvn", "hacom", "minh tuan mobile", "24hstore",
            "dien may xanh", "hc center",
            // Điện lạnh & Máy lạnh
            "dien lanh", "may lanh", "dieu hoa", "tu lanh", "may giat", "tu dong", "may nuoc nong",
            // Điện cơ & Cơ điện
            "dien co", "co dien", "may bom", "may khoan", "may han", "dung cu dien", "mo to dien",
            // Điện thoại & Công nghệ
            "dien thoai", "di dong", "smartphone", "iphone", "mobile", "laptop", "may tinh",
            "vi tinh", "tin hoc", "phu kien dien thoai", "sua chua dien thoai", "ep kinh",
            // Gia dụng & Điện tử
            "gia dung", "do gia dung", "dien gia dung", "dien tu", "thiet bi dien", "do dien",
            "may loc nuoc", "bep tu", "bep dien", "quat dien", "noi com", "tivi", "am thanh",
            "lock&lock", "elmich", "sunhouse", "kangaroo", "karofi", "daikin", "panasonic",
            "samsung", "toshiba", "sharp", "aqua", "casper", "nagakawa", "midea", "electrolux",
            "sony", "lg electronics", "bosch"
        ]

        if tuKhoaDoiThuChuan.contains(where: { t.contains($0) }) {
            return .doiThu
        }

        // Chỉ chấp nhận fallback khi đến từ tag OSM chuyên ngành điện máy/điện tử/điện thoại rõ ràng
        if tagOSMChacChan && goiY == .doiThu {
            return .doiThu
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
        danhSach: [DiaDiemQuet],
        hoanThanh: @escaping (KetQuaTuyenPhatToRoi?) -> Void
    ) {
        // Chỉ chọn điểm phát tờ rơi là Chợ, Trường học và Đối thủ (không đưa ĐMX/TGDĐ nhà mình vào điểm dừng phát tờ rơi)
        let dsPhatToRoi = danhSach.filter { $0.loai != .heThongMWG }
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

        let sapXepDiem = diemSo.sorted { $0.1 > $1.1 }
        var daChon: [DiaDiemQuet] = []
        for (ungVien, _) in sapXepDiem {
            if daChon.count >= 11 { break }
            let locUV = CLLocation(latitude: ungVien.viDo, longitude: ungVien.kinhDo)
            let quaGan = daChon.contains {
                locUV.distance(from: CLLocation(latitude: $0.viDo, longitude: $0.kinhDo)) < 90
            }
            if !quaGan {
                daChon.append(ungVien)
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
        let urlStr = "https://router.project-osrm.org/route/v1/driving/\(chuoiToaDo.joined(separator: ";"))?overview=full&geometries=geojson"

        guard let url = URL(string: urlStr) else {
            let duPhong = taoKetQuaDuPhong(tam: tam, diem: diemCoSoThuTu, kcChang: kcTungChang, tongThang: tongThang)
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
                let durSec = (firstRoute["duration"] as? Double) ?? (dist / 6.5)
                var legDists = kcTungChang
                if let legs = firstRoute["legs"] as? [[String: Any]], legs.count == diemCoSoThuTu.count {
                    legDists = legs.map { ($0["distance"] as? Double) ?? 0 }
                }

                let phutDiChuyen = max(1, Int(ceil(durSec / 60.0)))
                let ketQua = KetQuaTuyenPhatToRoi(
                    cacDiemDung: diemCoSoThuTu,
                    toaDoDuongDi: polyCoords,
                    tongQuangDuongMet: dist,
                    thoiGianPhut: phutDiChuyen,
                    laDuongThucTe: true,
                    khoangCachTungChangMet: legDists
                )
                DispatchQueue.main.async { hoanThanh(ketQua) }
            } else {
                let duPhong = self.taoKetQuaDuPhong(tam: tam, diem: diemCoSoThuTu, kcChang: kcTungChang, tongThang: tongThang)
                DispatchQueue.main.async { hoanThanh(duPhong) }
            }
        }.resume()
    }

    private func taoKetQuaDuPhong(
        tam: CLLocationCoordinate2D,
        diem: [DiaDiemQuet],
        kcChang: [Double],
        tongThang: Double
    ) -> KetQuaTuyenPhatToRoi {
        var coords = [tam]
        coords.append(contentsOf: diem.map { $0.toaDo })
        let uocLuongMet = tongThang * 1.32
        let phut = max(2, Int(ceil(uocLuongMet / 380.0)))
        return KetQuaTuyenPhatToRoi(
            cacDiemDung: diem,
            toaDoDuongDi: coords,
            tongQuangDuongMet: uocLuongMet,
            thoiGianPhut: phut,
            laDuongThucTe: false,
            khoangCachTungChangMet: kcChang.map { $0 * 1.32 }
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

final class ManHinhBanDoKhuVuc: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate, UIDocumentPickerDelegate {

    private enum KieuNenBanDo: Int {
        case googleDuongPho = 0
        case googleVeTinh = 1
        case appleMap = 2
    }

    private enum BoLocDanhSach: Int {
        case tatCa = 0
        case doiThu = 1
        case heThongMWG = 2
        case truongHoc = 3
        case cho = 4
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
    private var boLocHienTai: BoLocDanhSach = .tatCa

    private var dsSieuThiDaLuu: [DiaDiemSieuThiLuu] = []
    private var tatCaDiaDiem: [DiaDiemQuet] = []
    private var ketQuaTuyen: KetQuaTuyenPhatToRoi? = nil
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
    private let nutBatTatTuyen = UIButton(type: .system)
    private let nutPhongToBanDo = UIButton(type: .system)
    private let nhanGoiYBanDo = UILabel()

    // 4 thẻ thống kê KPI
    private let nhanSoDoiThu = UILabel()
    private let nhanSoMWG = UILabel()
    private let nhanSoTruongHoc = UILabel()
    private let nhanSoCho = UILabel()

    // Thẻ Tuyến phát tờ rơi hiệu quả nhất
    private let khungTuyenToRoi = UIView()
    private let nhanTomTatTuyen = UILabel()
    private let nhanKhungGioVang = UILabel()
    private let nganDanhSachDiemDung = UIStackView()
    private let nutMoGoogleMapsTuyen = UIButton(type: .system)
    private let nutCopyKeHoach = UIButton(type: .system)

    // Thẻ Danh sách chi tiết địa điểm
    private let khungDanhSach = UIView()
    private let chonBoLoc = UISegmentedControl(items: ["Tất cả", "Đối thủ", "ĐMX/TG", "Trường", "Chợ"])
    private let nganDanhSachDiaDiem = UIStackView()
    private let nhanTrongDanhSach = UILabel()

    // Trạng thái & giao diện Ma trận phát tờ rơi xoay vòng + Nhập Excel lịch PG / NV
    private var nhomDangChonExcel: NhomNhanSuLich = .pg
    private var khoiLichPG: KhoiLichTuanExcel? = nil
    private var khoiLichNV: KhoiLichTuanExcel? = nil
    private var keHoachMaTran: KeHoachMaTranTuan? = nil
    private var locMaTranChiChuaPhat: Bool = false

    private let khungMaTranToRoi = UIView()
    private let nutNhacChuNhat = UIButton(type: .system)
    private let nhanNhacTuyenChuaPhat = UILabel()
    private let nutNhapExcelPG = UIButton(type: .system)
    private let nutNhapExcelNV = UIButton(type: .system)
    private let nhanTrangThaiExcel = UILabel()
    private let nutTaoMaTran = UIButton(type: .system)
    private let nutCopyMaTran = UIButton(type: .system)
    private let nutXemLichCa = UIButton(type: .system)
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
        capNhatTamVaVongTronTrenBanDo(diChuyenCamera: true)
        capNhatGiaoDienMaTran()
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
        khoiLichPG = KhoMaTranPhatToRoi.dungChung.taiKhoiPG()
        khoiLichNV = KhoMaTranPhatToRoi.dungChung.taiKhoiNV()
        keHoachMaTran = KhoMaTranPhatToRoi.dungChung.taiKeHoach()
    }

    private func luuTrangThaiTamVaBanKinh() {
        let ud = UserDefaults.standard
        ud.set(tamQuet.latitude, forKey: Self.khoaViDoLuu)
        ud.set(tamQuet.longitude, forKey: Self.khoaKinhDoLuu)
        ud.set(banKinhMet, forKey: Self.khoaBanKinhLuu)
    }

    private func cauHinhViTri() {
        quanLyViTri.delegate = self
        quanLyViTri.desiredAccuracy = kCLLocationAccuracyBest
        if quanLyViTri.authorizationStatus == .authorizedWhenInUse || quanLyViTri.authorizationStatus == .authorizedAlways {
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
        nganChinh.addArrangedSubview(taoHang4TheKPI())
        nganChinh.addArrangedSubview(taoTheTuyenPhatToRoi())
        nganChinh.addArrangedSubview(taoTheMaTranPhatToRoi())
        nganChinh.addArrangedSubview(taoTheDanhSachChiTiet())

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

        nhanGoiYBanDo.text = "  📍 Chạm giữ bản đồ để chọn điểm / dời tâm  "
        nhanGoiYBanDo.font = .systemFont(ofSize: 11, weight: .semibold)
        nhanGoiYBanDo.textColor = .white
        nhanGoiYBanDo.backgroundColor = UIColor.black.withAlphaComponent(0.58)
        nhanGoiYBanDo.layer.cornerRadius = 10
        nhanGoiYBanDo.clipsToBounds = true
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

            nutBatTatTuyen.bottomAnchor.constraint(equalTo: khungBanDo.bottomAnchor, constant: -10),
            nutBatTatTuyen.trailingAnchor.constraint(equalTo: khungBanDo.trailingAnchor, constant: -8),

            nhanGoiYBanDo.bottomAnchor.constraint(equalTo: khungBanDo.bottomAnchor, constant: -10),
            nhanGoiYBanDo.leadingAnchor.constraint(equalTo: khungBanDo.leadingAnchor, constant: 8),
            nhanGoiYBanDo.heightAnchor.constraint(equalToConstant: 22)
        ])

        return khungBanDo
    }

    private func taoHang4TheKPI() -> UIView {
        let theDoiThu = taoMotTheKPI(loai: .doiThu, nhanSo: nhanSoDoiThu, tagLoc: BoLocDanhSach.doiThu.rawValue)
        let theMWG = taoMotTheKPI(loai: .heThongMWG, nhanSo: nhanSoMWG, tagLoc: BoLocDanhSach.heThongMWG.rawValue)
        let theTruong = taoMotTheKPI(loai: .truongHoc, nhanSo: nhanSoTruongHoc, tagLoc: BoLocDanhSach.truongHoc.rawValue)
        let theCho = taoMotTheKPI(loai: .cho, nhanSo: nhanSoCho, tagLoc: BoLocDanhSach.cho.rawValue)

        let hang = UIStackView(arrangedSubviews: [theDoiThu, theMWG, theTruong, theCho])
        hang.axis = .horizontal
        hang.spacing = 6
        hang.distribution = .fillEqually
        return hang
    }

    private func taoMotTheKPI(loai: LoaiDiaDiemQuet, nhanSo: UILabel, tagLoc: Int) -> UIControl {
        let the = UIControl()
        the.tag = tagLoc
        the.backgroundColor = loai.mauNenNhat
        the.layer.cornerRadius = 11
        the.layer.borderWidth = 1.2
        the.layer.borderColor = loai.mauChuDao.withAlphaComponent(0.35).cgColor
        the.addTarget(self, action: #selector(bamTheKPI(_:)), for: .touchUpInside)

        let cfg = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        let icon = UIImageView(image: UIImage(systemName: loai.bieuTuongSF, withConfiguration: cfg))
        icon.tintColor = loai.mauChuDao
        icon.contentMode = .scaleAspectFit

        let tieuDe = UILabel()
        tieuDe.text = loai.tieuDeNgan
        tieuDe.font = .systemFont(ofSize: 11, weight: .bold)
        tieuDe.textColor = BangMauBCTD.chuChinh
        tieuDe.textAlignment = .center
        tieuDe.adjustsFontSizeToFitWidth = true
        tieuDe.minimumScaleFactor = 0.8

        nhanSo.text = "0"
        nhanSo.font = .systemFont(ofSize: 21, weight: .heavy)
        nhanSo.textColor = loai.mauChuDao
        nhanSo.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [icon, nhanSo, tieuDe])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        the.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: the.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: the.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: the.trailingAnchor, constant: -4),
            stack.bottomAnchor.constraint(equalTo: the.bottomAnchor, constant: -8)
        ])

        return the
    }

    private func taoTheTuyenPhatToRoi() -> UIView {
        khungTuyenToRoi.backgroundColor = BangMauBCTD.nenThe
        khungTuyenToRoi.layer.cornerRadius = 14
        khungTuyenToRoi.layer.borderWidth = 1.2
        khungTuyenToRoi.layer.borderColor = BangMauBCTD.xanhDatVach.withAlphaComponent(0.45).cgColor
        khungTuyenToRoi.isHidden = true

        let tieuDe = UILabel()
        tieuDe.text = "🛣️ TUYẾN ĐƯỜNG PHÁT TỜ RƠI HIỆU QUẢ NHẤT"
        tieuDe.font = .systemFont(ofSize: 13, weight: .heavy)
        tieuDe.textColor = BangMauBCTD.xanhDatChu
        tieuDe.numberOfLines = 0

        nhanTomTatTuyen.font = .systemFont(ofSize: 13, weight: .semibold)
        nhanTomTatTuyen.textColor = BangMauBCTD.chuChinh
        nhanTomTatTuyen.numberOfLines = 0

        nhanKhungGioVang.font = .systemFont(ofSize: 12, weight: .medium)
        nhanKhungGioVang.textColor = BangMauBCTD.camPhanTich
        nhanKhungGioVang.backgroundColor = BangMauBCTD.vangNhatNen.withAlphaComponent(0.75)
        nhanKhungGioVang.layer.cornerRadius = 8
        nhanKhungGioVang.clipsToBounds = true
        nhanKhungGioVang.numberOfLines = 0

        nganDanhSachDiemDung.axis = .vertical
        nganDanhSachDiemDung.spacing = 6

        nutMoGoogleMapsTuyen.setTitle("🗺️ Dẫn đường Google Maps", for: .normal)
        nutMoGoogleMapsTuyen.titleLabel?.font = .systemFont(ofSize: 13, weight: .heavy)
        nutMoGoogleMapsTuyen.setTitleColor(.white, for: .normal)
        nutMoGoogleMapsTuyen.backgroundColor = BangMauBCTD.xanhDatVach
        nutMoGoogleMapsTuyen.layer.cornerRadius = 10
        nutMoGoogleMapsTuyen.heightAnchor.constraint(equalToConstant: 40).isActive = true
        nutMoGoogleMapsTuyen.addTarget(self, action: #selector(bamMoGoogleMapsTuyen), for: .touchUpInside)

        nutCopyKeHoach.setTitle("📋 Sao chép kế hoạch", for: .normal)
        nutCopyKeHoach.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        nutCopyKeHoach.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
        nutCopyKeHoach.backgroundColor = BangMauBCTD.nenHeaderPhu
        nutCopyKeHoach.layer.cornerRadius = 10
        nutCopyKeHoach.layer.borderWidth = 1
        nutCopyKeHoach.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
        nutCopyKeHoach.heightAnchor.constraint(equalToConstant: 40).isActive = true
        nutCopyKeHoach.addTarget(self, action: #selector(bamCopyKeHoach), for: .touchUpInside)

        let hangNut = UIStackView(arrangedSubviews: [nutMoGoogleMapsTuyen, nutCopyKeHoach])
        hangNut.axis = .horizontal
        hangNut.spacing = 8
        hangNut.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [tieuDe, nhanTomTatTuyen, nhanKhungGioVang, nganDanhSachDiemDung, hangNut])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        khungTuyenToRoi.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: khungTuyenToRoi.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: khungTuyenToRoi.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: khungTuyenToRoi.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: khungTuyenToRoi.bottomAnchor, constant: -12)
        ])

        return khungTuyenToRoi
    }

    private func taoTheDanhSachChiTiet() -> UIView {
        khungDanhSach.backgroundColor = BangMauBCTD.nenThe
        khungDanhSach.layer.cornerRadius = 14
        khungDanhSach.layer.borderWidth = 1
        khungDanhSach.layer.borderColor = BangMauBCTD.vienThe.cgColor

        let tieuDe = UILabel()
        tieuDe.text = "📍 DANH SÁCH ĐỊA ĐIỂM ĐÃ QUÉT"
        tieuDe.font = .systemFont(ofSize: 13, weight: .heavy)
        tieuDe.textColor = BangMauBCTD.xanhChuDaoDam

        chonBoLoc.selectedSegmentIndex = 0
        chonBoLoc.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 10.5, weight: .semibold)], for: .normal)
        chonBoLoc.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 10.5, weight: .bold)], for: .selected)
        chonBoLoc.addTarget(self, action: #selector(doiBoLocDanhSach), for: .valueChanged)

        nhanTrongDanhSach.text = "Chưa có dữ liệu quét. Hãy nhập bán kính và bấm \"Quét khu vực\"."
        nhanTrongDanhSach.font = .systemFont(ofSize: 12.5, weight: .medium)
        nhanTrongDanhSach.textColor = BangMauBCTD.chuMo
        nhanTrongDanhSach.textAlignment = .center
        nhanTrongDanhSach.numberOfLines = 0

        nganDanhSachDiaDiem.axis = .vertical
        nganDanhSachDiaDiem.spacing = 6

        let stack = UIStackView(arrangedSubviews: [tieuDe, chonBoLoc, nhanTrongDanhSach, nganDanhSachDiaDiem])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        khungDanhSach.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: khungDanhSach.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: khungDanhSach.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: khungDanhSach.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: khungDanhSach.bottomAnchor, constant: -12)
        ])

        return khungDanhSach
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

        let cacTam = danhSachTamDangChonDeQuet()
        for t in cacTam {
            let ghim = GhimTamQuetAnnotation(
                coordinate: t.toaDo,
                title: t.ten,
                subtitle: "Bán kính quét: \(Int(banKinhMet)) m",
                laSieuThiDaLuu: t.laSieuThiLuu
            )
            banDo.addAnnotation(ghim)

            let vong = MKCircle(center: t.toaDo, radius: banKinhMet)
            banDo.addOverlay(vong, level: .aboveLabels)
        }

        if diChuyenCamera {
            if cacTam.count == 1, let dau = cacTam.first {
                let spanMet = max(600, banKinhMet * 2.55)
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
                let latDelta = max((maxLat - minLat) * 1.45, (banKinhMet * 2.6) / 111000.0)
                let lonDelta = max((maxLon - minLon) * 1.45, (banKinhMet * 2.6) / 111000.0)
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
                banDo.setRegion(region, animated: true)
            }
        }
    }

    private func veLaiGhimVaTuyenTrenBanDo() {
        let ghimCu = banDo.annotations.filter { $0 is GhimDiaDiemAnnotation }
        banDo.removeAnnotations(ghimCu)

        let duongCu = banDo.overlays.filter { $0 is MKPolyline }
        banDo.removeOverlays(duongCu)

        var banDoSTT: [String: Int] = [:]
        if let tuyen = ketQuaTuyen {
            for d in tuyen.cacDiemDung {
                if let stt = d.soThuTuTuyen {
                    banDoSTT[d.id] = stt
                }
            }
        }

        let dsGhim: [GhimDiaDiemAnnotation] = tatCaDiaDiem.map { item in
            var banSao = item
            banSao.soThuTuTuyen = banDoSTT[item.id]
            return GhimDiaDiemAnnotation(diaDiem: banSao)
        }
        banDo.addAnnotations(dsGhim)

        if hienTuyenToRoi, let tuyen = ketQuaTuyen, tuyen.toaDoDuongDi.count >= 2 {
            let vien = TuyenPhatToRoiPolyline(coordinates: tuyen.toaDoDuongDi, count: tuyen.toaDoDuongDi.count)
            vien.laVienNen = true
            let loi = TuyenPhatToRoiPolyline(coordinates: tuyen.toaDoDuongDi, count: tuyen.toaDoDuongDi.count)
            loi.laVienNen = false
            banDo.addOverlay(vien, level: .aboveLabels)
            banDo.addOverlay(loi, level: .aboveLabels)
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
            capNhatTamVaVongTronTrenBanDo(diChuyenCamera: false)
        }
    }

    @objc private func bamChonBanKinhNhanh(_ sender: UIButton) {
        view.endEditing(true)
        banKinhMet = Double(sender.tag)
        oNhapBanKinh.text = "\(sender.tag)"
        capNhatNutBanKinhNhanh()
        luuTrangThaiTamVaBanKinh()
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
        nhanTrangThaiQuet.text = "Đang quét đối thủ, ĐMX/TGDĐ, trường học và chợ trong bán kính \(Int(banKinhMet)) m..."

        DichVuQuetKhuVuc.dungChung.quetNhieuTam(
            cacTam: cacTamToaDo,
            banKinhMet: banKinhMet,
            capNhatTrangThai: { [weak self] msg in
                self?.nhanTrangThaiQuet.text = msg
            },
            hoanThanh: { [weak self] dsKetQua, nguon in
                guard let self = self else { return }
                self.tatCaDiaDiem = dsKetQua
                self.capNhatThongKeKPI()

                if dsKetQua.isEmpty {
                    self.ketQuaTuyen = nil
                    self.ketThucQuet(thongBao: "Không tìm thấy địa điểm nào trong bán kính \(Int(self.banKinhMet)) m. Thử tăng bán kính lên nhé!")
                    return
                }

                self.nhanTrangThaiQuet.text = "Đã tìm thấy \(dsKetQua.count) địa điểm. Đang tối ưu tuyến phát tờ rơi hiệu quả nhất..."
                BoToiUuTuyenPhatToRoi.dungChung.tinhTuyenHieuQuaNhat(tam: diemXuatPhat, danhSach: dsKetQua) { [weak self] tuyen in
                    guard let self = self else { return }
                    self.ketQuaTuyen = tuyen
                    let soDT = dsKetQua.filter { $0.loai == .doiThu }.count
                    let soMWG = dsKetQua.filter { $0.loai == .heThongMWG }.count
                    let soTH = dsKetQua.filter { $0.loai == .truongHoc }.count
                    let soCho = dsKetQua.filter { $0.loai == .cho }.count
                    let chuoiNguon = nguon.isEmpty ? "" : " • Nguồn: \(nguon.joined(separator: ", "))"
                    let nhanTam = cacTamInfo.count > 1 ? "\(cacTamInfo.count) điểm, bán kính \(Int(self.banKinhMet))m" : "bán kính \(Int(self.banKinhMet))m"
                    self.ketThucQuet(
                        thongBao: "Hoàn tất (\(nhanTam)): \(soDT) đối thủ, \(soMWG) ĐMX/TGDĐ, \(soTH) trường, \(soCho) chợ\(chuoiNguon)."
                    )
                }
            }
        )
    }

    private func ketThucQuet(thongBao: String) {
        dangQuet = false
        nutQuetKhuVuc.isEnabled = true
        nutQuetKhuVuc.alpha = 1.0
        vongQuayQuet.stopAnimating()
        nhanTrangThaiQuet.text = thongBao
        veLaiGhimVaTuyenTrenBanDo()
        capNhatKhungTuyenPhatToRoi()
        capNhatDanhSachChiTiet()
        if !tatCaDiaDiem.isEmpty {
            let dau = danhSachTamDangChonDeQuet().first?.toaDo ?? tamQuet
            let cacTuyen = BoLapMaTranToRoiXoayVong.taoCacTuyenTuKetQuaQuet(tamLat: dau.latitude, tamLon: dau.longitude, danhSach: tatCaDiaDiem)
            let kh = BoLapMaTranToRoiXoayVong.lapMaTranTuan(cacTuyen: cacTuyen, khoiPG: khoiLichPG, khoiNV: khoiLichNV, giuTrangThaiCu: keHoachMaTran)
            keHoachMaTran = kh
            KhoMaTranPhatToRoi.dungChung.luuKeHoach(kh)
            capNhatGiaoDienMaTran()
        }
    }

    private func capNhatThongKeKPI() {
        let soDT = tatCaDiaDiem.filter { $0.loai == .doiThu }.count
        let soMWG = tatCaDiaDiem.filter { $0.loai == .heThongMWG }.count
        let soTH = tatCaDiaDiem.filter { $0.loai == .truongHoc }.count
        let soCho = tatCaDiaDiem.filter { $0.loai == .cho }.count

        nhanSoDoiThu.text = "\(soDT)"
        nhanSoMWG.text = "\(soMWG)"
        nhanSoTruongHoc.text = "\(soTH)"
        nhanSoCho.text = "\(soCho)"

        chonBoLoc.setTitle("Tất cả(\(tatCaDiaDiem.count))", forSegmentAt: 0)
        chonBoLoc.setTitle("Đ.Thủ(\(soDT))", forSegmentAt: 1)
        chonBoLoc.setTitle("ĐMX(\(soMWG))", forSegmentAt: 2)
        chonBoLoc.setTitle("Trường(\(soTH))", forSegmentAt: 3)
        chonBoLoc.setTitle("Chợ(\(soCho))", forSegmentAt: 4)
    }

    private func capNhatKhungTuyenPhatToRoi() {
        nganDanhSachDiemDung.arrangedSubviews.forEach {
            nganDanhSachDiemDung.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        guard let tuyen = ketQuaTuyen, !tuyen.cacDiemDung.isEmpty else {
            khungTuyenToRoi.isHidden = true
            return
        }

        khungTuyenToRoi.isHidden = false
        let km = tuyen.tongQuangDuongMet / 1000.0
        let soCho = tuyen.cacDiemDung.filter { $0.loai == .cho }.count
        let soTH = tuyen.cacDiemDung.filter { $0.loai == .truongHoc }.count
        let soDT = tuyen.cacDiemDung.filter { $0.loai == .doiThu }.count

        let cheDoDuong = tuyen.laDuongThucTe ? "theo đường thực tế" : "ước lượng đường đi"
        nhanTomTatTuyen.text = String(
            format: "• Tổng quãng đường: %.2f km (%@) • Di chuyển ~%d phút\n• Đi qua %d điểm nóng tối ưu: %d Chợ, %d Trường học, %d cụm Đối thủ",
            km, cheDoDuong, tuyen.thoiGianPhut, tuyen.cacDiemDung.count, soCho, soTH, soDT
        )

        nhanKhungGioVang.text = "  ⏰ Khung giờ vàng phát tờ rơi:\n  • Sáng (06:30 – 09:00): Tập trung Chợ sáng & giờ đưa đón Trường học.\n  • Chiều (16:00 – 18:00): Giờ tan trường, chợ chiều & đón đầu khu Đối thủ."

        for (idx, diem) in tuyen.cacDiemDung.enumerated() {
            let changMet = idx < tuyen.khoangCachTungChangMet.count ? Int(round(tuyen.khoangCachTungChangMet[idx])) : Int(round(diem.khoangCachMet))
            let dong = taoDongDiemDungTuyen(stt: idx + 1, diem: diem, changMet: changMet)
            nganDanhSachDiemDung.addArrangedSubview(dong)
        }
    }

    private func taoDongDiemDungTuyen(stt: Int, diem: DiaDiemQuet, changMet: Int) -> UIView {
        let nut = UIControl()
        nut.backgroundColor = diem.loai.mauNenNhat
        nut.layer.cornerRadius = 9
        nut.layer.borderWidth = 1
        nut.layer.borderColor = diem.loai.mauChuDao.withAlphaComponent(0.28).cgColor
        nut.accessibilityIdentifier = diem.id
        nut.addTarget(self, action: #selector(bamChonDongDiaDiem(_:)), for: .touchUpInside)

        let huyHieu = UILabel()
        huyHieu.text = "\(stt)"
        huyHieu.font = .systemFont(ofSize: 12, weight: .heavy)
        huyHieu.textColor = .white
        huyHieu.textAlignment = .center
        huyHieu.backgroundColor = diem.loai.mauChuDao
        huyHieu.layer.cornerRadius = 12
        huyHieu.clipsToBounds = true
        huyHieu.translatesAutoresizingMaskIntoConstraints = false
        huyHieu.widthAnchor.constraint(equalToConstant: 24).isActive = true
        huyHieu.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let nhanTen = UILabel()
        nhanTen.text = diem.ten
        nhanTen.font = .systemFont(ofSize: 13, weight: .bold)
        nhanTen.textColor = BangMauBCTD.chuChinh
        nhanTen.numberOfLines = 2

        let nhanPhu = UILabel()
        let ghiChuChang = stt == 1 ? "Cách tâm \(changMet)m" : "Chặng tiếp +\(changMet)m"
        nhanPhu.text = "\(diem.loai.tieuDe) • \(ghiChuChang)" + (diem.diaChi.isEmpty ? "" : " • \(diem.diaChi)")
        nhanPhu.font = .systemFont(ofSize: 11.5, weight: .medium)
        nhanPhu.textColor = BangMauBCTD.chuPhu
        nhanPhu.numberOfLines = 2

        let cotChu = UIStackView(arrangedSubviews: [nhanTen, nhanPhu])
        cotChu.axis = .vertical
        cotChu.spacing = 2
        cotChu.isUserInteractionEnabled = false

        let hang = UIStackView(arrangedSubviews: [huyHieu, cotChu])
        hang.axis = .horizontal
        hang.spacing = 9
        hang.alignment = .center
        hang.isUserInteractionEnabled = false
        hang.translatesAutoresizingMaskIntoConstraints = false
        nut.addSubview(hang)

        NSLayoutConstraint.activate([
            hang.topAnchor.constraint(equalTo: nut.topAnchor, constant: 8),
            hang.leadingAnchor.constraint(equalTo: nut.leadingAnchor, constant: 10),
            hang.trailingAnchor.constraint(equalTo: nut.trailingAnchor, constant: -10),
            hang.bottomAnchor.constraint(equalTo: nut.bottomAnchor, constant: -8)
        ])

        return nut
    }

    @objc private func bamTheKPI(_ sender: UIControl) {
        boLocHienTai = BoLocDanhSach(rawValue: sender.tag) ?? .tatCa
        chonBoLoc.selectedSegmentIndex = boLocHienTai.rawValue
        capNhatDanhSachChiTiet()
    }

    @objc private func doiBoLocDanhSach() {
        boLocHienTai = BoLocDanhSach(rawValue: chonBoLoc.selectedSegmentIndex) ?? .tatCa
        capNhatDanhSachChiTiet()
    }

    private func capNhatDanhSachChiTiet() {
        nganDanhSachDiaDiem.arrangedSubviews.forEach {
            nganDanhSachDiaDiem.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let dsLoc: [DiaDiemQuet]
        switch boLocHienTai {
        case .tatCa: dsLoc = tatCaDiaDiem
        case .doiThu: dsLoc = tatCaDiaDiem.filter { $0.loai == .doiThu }
        case .heThongMWG: dsLoc = tatCaDiaDiem.filter { $0.loai == .heThongMWG }
        case .truongHoc: dsLoc = tatCaDiaDiem.filter { $0.loai == .truongHoc }
        case .cho: dsLoc = tatCaDiaDiem.filter { $0.loai == .cho }
        }

        nhanTrongDanhSach.isHidden = !dsLoc.isEmpty
        if dsLoc.isEmpty && !tatCaDiaDiem.isEmpty {
            nhanTrongDanhSach.text = "Không có địa điểm nào thuộc mục đang lọc."
        }

        for diem in dsLoc.prefix(100) {
            nganDanhSachDiaDiem.addArrangedSubview(taoDongDanhSachDiaDiem(diem))
        }
    }

    private func taoDongDanhSachDiaDiem(_ diem: DiaDiemQuet) -> UIView {
        let the = UIControl()
        the.backgroundColor = BangMauBCTD.nenThePhu
        the.layer.cornerRadius = 10
        the.layer.borderWidth = 1
        the.layer.borderColor = BangMauBCTD.vienThe.cgColor
        the.accessibilityIdentifier = diem.id
        the.addTarget(self, action: #selector(bamChonDongDiaDiem(_:)), for: .touchUpInside)

        let vachMau = UIView()
        vachMau.backgroundColor = diem.loai.mauChuDao
        vachMau.layer.cornerRadius = 2
        vachMau.translatesAutoresizingMaskIntoConstraints = false
        vachMau.widthAnchor.constraint(equalToConstant: 4).isActive = true

        let nhanTen = UILabel()
        nhanTen.text = diem.ten
        nhanTen.font = .systemFont(ofSize: 13.5, weight: .bold)
        nhanTen.textColor = BangMauBCTD.chuChinh
        nhanTen.numberOfLines = 2

        let kc = Int(round(diem.khoangCachMet))
        let nhanPhu = UILabel()
        nhanPhu.text = "\(diem.loai.tieuDe) • Cách \(kc) m" + (diem.diaChi.isEmpty ? "" : " • \(diem.diaChi)")
        nhanPhu.font = .systemFont(ofSize: 11.5, weight: .medium)
        nhanPhu.textColor = BangMauBCTD.chuPhu
        nhanPhu.numberOfLines = 2

        let cotChu = UIStackView(arrangedSubviews: [nhanTen, nhanPhu])
        cotChu.axis = .vertical
        cotChu.spacing = 2
        cotChu.isUserInteractionEnabled = false

        let nutGG = UIButton(type: .system)
        nutGG.setTitle("GG Map", for: .normal)
        nutGG.titleLabel?.font = .systemFont(ofSize: 11, weight: .bold)
        nutGG.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
        nutGG.backgroundColor = BangMauBCTD.nenHeaderPhu
        nutGG.layer.cornerRadius = 7
        nutGG.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        nutGG.accessibilityIdentifier = diem.id
        nutGG.setContentHuggingPriority(.required, for: .horizontal)
        nutGG.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutGG.addTarget(self, action: #selector(bamMoMotDiemTrenGoogleMaps(_:)), for: .touchUpInside)

        let hang = UIStackView(arrangedSubviews: [vachMau, cotChu, nutGG])
        hang.axis = .horizontal
        hang.spacing = 8
        hang.alignment = .center
        hang.translatesAutoresizingMaskIntoConstraints = false
        the.addSubview(hang)

        NSLayoutConstraint.activate([
            vachMau.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),
            hang.topAnchor.constraint(equalTo: the.topAnchor, constant: 8),
            hang.leadingAnchor.constraint(equalTo: the.leadingAnchor, constant: 8),
            hang.trailingAnchor.constraint(equalTo: the.trailingAnchor, constant: -8),
            hang.bottomAnchor.constraint(equalTo: the.bottomAnchor, constant: -8)
        ])

        return the
    }

    @objc private func bamChonDongDiaDiem(_ sender: UIControl) {
        guard let id = sender.accessibilityIdentifier,
              let diem = tatCaDiaDiem.first(where: { $0.id == id }) else { return }

        let region = MKCoordinateRegion(center: diem.toaDo, latitudinalMeters: 650, longitudinalMeters: 650)
        banDo.setRegion(region, animated: true)

        if let ann = banDo.annotations.compactMap({ $0 as? GhimDiaDiemAnnotation }).first(where: { $0.diaDiem.id == id }) {
            banDo.selectAnnotation(ann, animated: true)
        }
        cuonChinh.setContentOffset(CGPoint(x: 0, y: max(0, khungBanDo.frame.minY - 8)), animated: true)
    }

    @objc private func bamMoMotDiemTrenGoogleMaps(_ sender: UIButton) {
        guard let id = sender.accessibilityIdentifier,
              let diem = tatCaDiaDiem.first(where: { $0.id == id }) else { return }
        moGoogleMapsDanDuong(den: diem.toaDo)
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

    @objc private func bamMoGoogleMapsTuyen() {
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
        let dsTenTam = danhSachTamDangChonDeQuet().map { $0.ten }.joined(separator: ", ")

        var dong: [String] = [
            "📍 BÁO CÁO QUÉT KHU VỰC & TUYẾN PHÁT TỜ RƠI",
            "• Tâm quét: \(dsTenTam)",
            "• Bán kính: \(Int(banKinhMet)) m",
            "• Đối thủ điện máy/gia dụng: \(soDT)",
            "• Cửa hàng ĐMX / TGDĐ: \(soMWG)",
            "• Trường học: \(soTH)",
            "• Chợ: \(soCho)"
        ]

        if let tuyen = ketQuaTuyen, !tuyen.cacDiemDung.isEmpty {
            dong.append("")
            dong.append(String(format: "🛣️ TUYẾN PHÁT TỜ RƠI HIỆU QUẢ NHẤT (%.2f km • ~%d phút di chuyển):", tuyen.tongQuangDuongMet / 1000.0, tuyen.thoiGianPhut))
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
                r.strokeColor = BangMauBCTD.xanhDatVach
                r.lineWidth = 4.4
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

    // MARK: - Thẻ Ma Trận Phát Tờ Rơi Xoay Vòng & Nhập Excel Lịch PG / NV Siêu Thị

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
        nhanNhacTuyenChuaPhat.layer.cornerRadius = 9
        nhanNhacTuyenChuaPhat.clipsToBounds = true

        // 2 nút nhập file Excel lịch PG và lịch Nhân viên siêu thị
        nutNhapExcelPG.setTitle("📊 Nhập Excel PG", for: .normal)
        nutNhapExcelPG.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        nutNhapExcelPG.setTitleColor(.white, for: .normal)
        nutNhapExcelPG.backgroundColor = BangMauBCTD.xanhDatVach
        nutNhapExcelPG.layer.cornerRadius = 9
        nutNhapExcelPG.heightAnchor.constraint(equalToConstant: 38).isActive = true
        nutNhapExcelPG.addTarget(self, action: #selector(bamNhapExcelPG), for: .touchUpInside)

        nutNhapExcelNV.setTitle("👥 Nhập Excel NV", for: .normal)
        nutNhapExcelNV.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        nutNhapExcelNV.setTitleColor(.white, for: .normal)
        nutNhapExcelNV.backgroundColor = BangMauBCTD.xanhBienChuDao
        nutNhapExcelNV.layer.cornerRadius = 9
        nutNhapExcelNV.heightAnchor.constraint(equalToConstant: 38).isActive = true
        nutNhapExcelNV.addTarget(self, action: #selector(bamNhapExcelNV), for: .touchUpInside)

        let hangExcel = UIStackView(arrangedSubviews: [nutNhapExcelPG, nutNhapExcelNV])
        hangExcel.axis = .horizontal
        hangExcel.spacing = 8
        hangExcel.distribution = .fillEqually

        nhanTrangThaiExcel.font = .systemFont(ofSize: 11.5, weight: .medium)
        nhanTrangThaiExcel.textColor = BangMauBCTD.chuPhu
        nhanTrangThaiExcel.numberOfLines = 0

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
        nutXemLichCa.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
        nutXemLichCa.backgroundColor = BangMauBCTD.nenThePhu
        nutXemLichCa.layer.cornerRadius = 9
        nutXemLichCa.layer.borderWidth = 1
        nutXemLichCa.layer.borderColor = BangMauBCTD.vienDam.cgColor
        nutXemLichCa.heightAnchor.constraint(equalToConstant: 36).isActive = true
        nutXemLichCa.addTarget(self, action: #selector(bamXemLichCaDaQuet), for: .touchUpInside)

        let hangHanhDong = UIStackView(arrangedSubviews: [nutTaoMaTran, nutCopyMaTran])
        hangHanhDong.axis = .horizontal
        hangHanhDong.spacing = 8
        hangHanhDong.distribution = .fillEqually

        chonLocMaTran.selectedSegmentIndex = 0
        chonLocMaTran.addTarget(self, action: #selector(doiBoLocMaTran), for: .valueChanged)

        nganDanhSachMaTran.axis = .vertical
        nganDanhSachMaTran.spacing = 7

        let stack = UIStackView(arrangedSubviews: [
            hangDau, nhanNhacTuyenChuaPhat, hangExcel, nhanTrangThaiExcel, hangHanhDong, nutXemLichCa, chonLocMaTran, nganDanhSachMaTran
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

    @objc private func bamNhapExcelPG() {
        nhomDangChonExcel = .pg
        moChonFileExcel()
    }

    @objc private func bamNhapExcelNV() {
        nhomDangChonExcel = .nhanVien
        moChonFileExcel()
    }

    private func moChonFileExcel() {
        var types: [UTType] = []
        if let xlsx = UTType(filenameExtension: "xlsx") {
            types.append(xlsx)
        }
        types.append(.spreadsheet)
        types.append(.data)
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let nhom = nhomDangChonExcel
        nhanTrangThaiExcel.text = "Đang đọc file Excel \(nhom.rawValue): \(url.lastPathComponent)..."

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let dsKhoi = try BoPhanTichLichCaExcel.phanTichWorkbook(tu: url, nhom: nhom)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    guard !dsKhoi.isEmpty else {
                        self.hienThongBao(
                            tieuDe: "Không tìm thấy bảng lịch ca",
                            noiDung: "File \"\(url.lastPathComponent)\" không có bảng lịch theo Thứ 2 – Chủ nhật hợp lệ."
                        )
                        self.capNhatGiaoDienMaTran()
                        return
                    }
                    if dsKhoi.count == 1, let duyNhat = dsKhoi.first {
                        self.apDungKhoiLichExcel(duyNhat)
                    } else {
                        self.hienChonTuanTrongExcel(dsKhoi: dsKhoi, tenFile: url.lastPathComponent)
                    }
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.hienThongBao(tieuDe: "Lỗi đọc file Excel", noiDung: error.localizedDescription)
                    self?.capNhatGiaoDienMaTran()
                }
            }
        }
    }

    private func hienChonTuanTrongExcel(dsKhoi: [KhoiLichTuanExcel], tenFile: String) {
        // Sắp xếp tuần có ngày mới nhất lên đầu tiên, sau đó giữ thứ tự ngược cho các tuần không có số ngày
        let sapXep = dsKhoi.enumerated().sorted { a, b in
            if a.element.ngaySerialSapXep != b.element.ngaySerialSapXep {
                return a.element.ngaySerialSapXep > b.element.ngaySerialSapXep
            }
            return a.offset > b.offset
        }.map { $0.element }

        let pickerVC = HopChonTuanExcelViewController(dsKhoi: sapXep, tenFile: tenFile) { [weak self] khoi in
            self?.apDungKhoiLichExcel(khoi)
        }
        let nav = UINavigationController(rootViewController: pickerVC)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    private func apDungKhoiLichExcel(_ khoi: KhoiLichTuanExcel) {
        if khoi.nhom == .pg {
            khoiLichPG = khoi
            KhoMaTranPhatToRoi.dungChung.luuKhoiPG(khoi)
        } else {
            khoiLichNV = khoi
            KhoMaTranPhatToRoi.dungChung.luuKhoiNV(khoi)
        }
        bamTaoMaTranXoayVong()
    }

    @objc private func bamTaoMaTranXoayVong() {
        let dau = danhSachTamDangChonDeQuet().first?.toaDo ?? tamQuet
        let cacTuyen: [TuyenPhatToRoiMaTran]
        if !tatCaDiaDiem.isEmpty {
            cacTuyen = BoLapMaTranToRoiXoayVong.taoCacTuyenTuKetQuaQuet(tamLat: dau.latitude, tamLon: dau.longitude, danhSach: tatCaDiaDiem)
        } else if let cu = keHoachMaTran, !cu.cacTuyen.isEmpty {
            cacTuyen = cu.cacTuyen
        } else {
            cacTuyen = BoLapMaTranToRoiXoayVong.taoCacTuyenTuKetQuaQuet(tamLat: dau.latitude, tamLon: dau.longitude, danhSach: [])
        }

        let kh = BoLapMaTranToRoiXoayVong.lapMaTranTuan(
            cacTuyen: cacTuyen,
            khoiPG: khoiLichPG,
            khoiNV: khoiLichNV,
            giuTrangThaiCu: keHoachMaTran
        )
        keHoachMaTran = kh
        KhoMaTranPhatToRoi.dungChung.luuKeHoach(kh)
        capNhatGiaoDienMaTran()
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

        let pgInfo = khoiLichPG.map { "PG: \($0.tenSheet) – \($0.tenTuan) (\($0.danhSachNguoi.count) người)" } ?? "PG: Chưa nhập file Excel"
        let nvInfo = khoiLichNV.map { "NV: \($0.tenSheet) – \($0.tenTuan) (\($0.danhSachNguoi.count) người)" } ?? "NV: Chưa nhập file Excel"
        let laChuNhat = (Calendar(identifier: .gregorian).component(.weekday, from: Date()) == 1)
        let ghiChuCN = laChuNhat
            ? "📌 Hôm nay là Chủ nhật — hãy nhập file Excel mới để đăng ký lịch tuần tiếp theo!"
            : "🗓️ Lịch cập nhật theo tuần (Chủ nhật hằng tuần nhập Excel cho tuần tới)."
        nhanTrangThaiExcel.text = "• \(pgInfo)\n• \(nvInfo)\n\(ghiChuCN)"

        nganDanhSachMaTran.arrangedSubviews.forEach {
            nganDanhSachMaTran.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        guard let kh = keHoachMaTran else {
            nhanNhacTuyenChuaPhat.text = "  💡 Quét khu vực trên bản đồ hoặc nhập file Excel PG/NV rồi bấm \"⚡ Phân lịch xoay vòng\"."
            nhanNhacTuyenChuaPhat.textColor = BangMauBCTD.xanhChuDaoDam
            nhanNhacTuyenChuaPhat.backgroundColor = BangMauBCTD.nenHeaderPhu
            return
        }

        // Tính các tuyến chưa phát trong tuần để hiện cảnh báo nhắc nhở
        let tuyenDaPhatIDs = Set(kh.cacO.filter { $0.daPhat }.map { $0.tuyenId })
        let tuyenChuaPhat = kh.cacTuyen.filter { !tuyenDaPhatIDs.contains($0.id) }
        let soBuoiChuaPhat = kh.cacO.filter { !$0.daPhat }.count

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

        let dsHien: [OMaTranPhatToRoi]
        switch chonLocMaTran.selectedSegmentIndex {
        case 1: dsHien = kh.cacO.filter { !$0.daPhat }
        case 2: dsHien = kh.cacO.filter { $0.daPhat }
        default: dsHien = kh.cacO
        }

        if dsHien.isEmpty {
            let lb = UILabel()
            lb.text = "Không có buổi nào thuộc bộ lọc này."
            lb.font = .systemFont(ofSize: 12, weight: .medium)
            lb.textColor = BangMauBCTD.chuMo
            lb.textAlignment = .center
            nganDanhSachMaTran.addArrangedSubview(lb)
            return
        }

        for o in dsHien {
            nganDanhSachMaTran.addArrangedSubview(taoDongMaTran(o))
        }
    }

    private func taoDongMaTran(_ o: OMaTranPhatToRoi) -> UIView {
        let the = UIView()
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
        lbMoTa.text = o.moTaTuyen
        lbMoTa.font = .systemFont(ofSize: 11.5, weight: .medium)
        lbMoTa.textColor = BangMauBCTD.chuPhu
        lbMoTa.numberOfLines = 2

        var dongNhanSu: [String] = []
        if !o.danhSachPG.isEmpty {
            dongNhanSu.append("👩‍💼 PG rảnh (ko trùng ca): \(o.danhSachPG.joined(separator: ", "))")
        } else if khoiLichPG != nil {
            dongNhanSu.append("👩‍💼 PG: Không có PG rảnh buổi này (đều đang trực ca/OFF)")
        }
        if !o.danhSachNV.isEmpty {
            dongNhanSu.append("🧑‍🔧 NV siêu thị rảnh: \(o.danhSachNV.joined(separator: ", "))")
        } else if khoiLichNV != nil {
            dongNhanSu.append("🧑‍🔧 NV: Không có NV rảnh buổi này")
        }
        if dongNhanSu.isEmpty {
            dongNhanSu.append("ℹ️ Nhập file Excel lịch PG / NV để tự động phân người không trùng ca.")
        }

        let lbNS = UILabel()
        lbNS.text = dongNhanSu.joined(separator: "\n")
        lbNS.font = .systemFont(ofSize: 11.5, weight: .semibold)
        lbNS.textColor = BangMauBCTD.xanhLaDam
        lbNS.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [hangTren, lbTuyen, lbMoTa, lbNS])
        stack.axis = .vertical
        stack.spacing = 4
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

    @objc private func bamXemLichCaDaQuet() {
        var dsHien: [LichTuanMotNguoi] = []
        if let pg = khoiLichPG { dsHien.append(contentsOf: pg.danhSachNguoi) }
        if let nv = khoiLichNV { dsHien.append(contentsOf: nv.danhSachNguoi) }
        guard !dsHien.isEmpty else {
            hienThongBao(tieuDe: "Chưa có dữ liệu lịch ca", noiDung: "Hãy bấm \"📊 Nhập Excel PG\" hoặc \"👥 Nhập Excel NV\" để tải lịch làm việc tuần trước.")
            return
        }
        let tieuDeTuan = khoiLichPG?.tenTuan ?? khoiLichNV?.tenTuan ?? "Tuần hiện tại"
        let vc = HopXemLichCaDaQuetViewController(danhSach: dsHien, tieuDeTuan: tieuDeTuan)
        let nav = UINavigationController(rootViewController: vc)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
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


// MARK: - Hộp Chọn Tuần Lịch Excel Dạng Danh Sách Cuộn Sạch Đẹp (Không Bị Đè Chữ)

private final class HopChonTuanExcelViewController: UITableViewController {
    private let dsKhoi: [KhoiLichTuanExcel]
    private let tenFile: String
    private let khiChon: (KhoiLichTuanExcel) -> Void

    init(dsKhoi: [KhoiLichTuanExcel], tenFile: String, khiChon: @escaping (KhoiLichTuanExcel) -> Void) {
        self.dsKhoi = dsKhoi
        self.tenFile = tenFile
        self.khiChon = khiChon
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("Khong ho tro coder")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chọn Tuần (\(dsKhoi.count) tuần)"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Đóng", style: .done, target: self, action: #selector(bamDong))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 58
    }

    @objc private func bamDong() {
        dismiss(animated: true)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Nguồn: \(tenFile) (mới nhất ở trên)"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dsKhoi.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "CellTuanExcel"
        let cell = tableView.dequeueReusableCell(withIdentifier: id)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: id)
        let khoi = dsKhoi[indexPath.row]
        cell.textLabel?.text = khoi.tenTuan
        cell.textLabel?.font = .systemFont(ofSize: 14.5, weight: .bold)
        cell.textLabel?.textColor = BangMauBCTD.chuChinh
        cell.textLabel?.numberOfLines = 1
        cell.textLabel?.lineBreakMode = .byTruncatingTail

        cell.detailTextLabel?.text = "Sheet: \(khoi.tenSheet) • \(khoi.danhSachNguoi.count) \(khoi.nhom.rawValue)"
        cell.detailTextLabel?.font = .systemFont(ofSize: 12.5, weight: .medium)
        cell.detailTextLabel?.textColor = BangMauBCTD.xanhChuDaoDam
        cell.detailTextLabel?.numberOfLines = 1
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let khoi = dsKhoi[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.khiChon(khoi)
        }
    }
}


// MARK: - Màn Hình Đối Chiếu Tên & Thời Gian Làm Việc Đã Quét Từ Excel

private final class HopXemLichCaDaQuetViewController: UITableViewController {
    private let danhSach: [LichTuanMotNguoi]
    private let tieuDeTuan: String

    init(danhSach: [LichTuanMotNguoi], tieuDeTuan: String) {
        self.danhSach = danhSach
        self.tieuDeTuan = tieuDeTuan
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("Khong ho tro coder")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Lịch ca (\(danhSach.count) người)"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Đóng", style: .done, target: self, action: #selector(bamDong))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 96
    }

    @objc private func bamDong() {
        dismiss(animated: true)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(tieuDeTuan) — Kiểm tra tên, ca & khung rảnh phát tờ rơi"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return danhSach.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "CellXemLichCa"
        let cell = tableView.dequeueReusableCell(withIdentifier: id)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: id)
        let nguoi = danhSach[indexPath.row]
        let nganh = nguoi.nganhHang.isEmpty ? nguoi.nhom.rawValue : "\(nguoi.nhom.rawValue) • \(nguoi.nganhHang)"
        cell.textLabel?.text = "\(nguoi.ten)  (\(nganh))"
        cell.textLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        cell.textLabel?.textColor = BangMauBCTD.chuChinh
        cell.textLabel?.numberOfLines = 1

        let tenThuNgan = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
        var dongChiTiet: [String] = []
        for (i, ca) in nguoi.lich7Ngay.enumerated() where i < tenThuNgan.count {
            let caText = [ca.nhanCaGoc, ca.gioLamGoc].filter { !$0.isEmpty }.joined(separator: " ")
            let ranhTag: String
            if ca.ranhSang { ranhTag = "→ Rảnh SÁNG" }
            else if ca.ranhChieu { ranhTag = "→ Rảnh CHIỀU" }
            else if ca.laNghiOff { ranhTag = "(Nghỉ/OFF)" }
            else { ranhTag = "(Bận ca)" }
            let noiDungCa = caText.isEmpty ? "Trống" : caText
            dongChiTiet.append("\(tenThuNgan[i]): \(noiDungCa) \(ranhTag)")
        }

        cell.detailTextLabel?.text = dongChiTiet.joined(separator: "\n")
        cell.detailTextLabel?.font = .systemFont(ofSize: 11.5, weight: .medium)
        cell.detailTextLabel?.textColor = BangMauBCTD.chuPhu
        cell.detailTextLabel?.numberOfLines = 0
        cell.selectionStyle = .none
        return cell
    }
}
