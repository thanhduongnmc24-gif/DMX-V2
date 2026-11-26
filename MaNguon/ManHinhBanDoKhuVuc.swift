import UIKit
import MapKit
import CoreLocation

// MARK: - Mô Hình Dữ Liệu Quét Khu Vực & Tuyến Phát Tờ Rơi

enum LoaiDiaDiemQuet: String, CaseIterable, Codable {
    case doiThu = "doi_thu"
    case truongHoc = "truong_hoc"
    case cho = "cho"

    var tieuDe: String {
        switch self {
        case .doiThu: return "Đối thủ"
        case .truongHoc: return "Trường học"
        case .cho: return "Chợ"
        }
    }

    var tieuDeDayDu: String {
        switch self {
        case .doiThu: return "Đối thủ (Điện máy / Gia dụng)"
        case .truongHoc: return "Trường học"
        case .cho: return "Chợ"
        }
    }

    var bieuTuongSF: String {
        switch self {
        case .doiThu: return "storefront.fill"
        case .truongHoc: return "graduationcap.fill"
        case .cho: return "basket.fill"
        }
    }

    var mauChuDao: UIColor {
        switch self {
        case .doiThu: return UIColor(red: 0.86, green: 0.15, blue: 0.15, alpha: 1.0)     // Đỏ #DC2626
        case .truongHoc: return UIColor(red: 0.14, green: 0.39, blue: 0.92, alpha: 1.0)  // Xanh dương #2563EB
        case .cho: return UIColor(red: 0.85, green: 0.47, blue: 0.02, alpha: 1.0)        // Cam vàng #D97706
        }
    }

    var mauNenNhat: UIColor {
        switch self {
        case .doiThu: return UIColor(red: 1.00, green: 0.95, blue: 0.95, alpha: 1.0)
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

    init(coordinate: CLLocationCoordinate2D, title: String = "Tâm quét (Siêu thị)", subtitle: String? = "Chạm giữ bản đồ để di chuyển") {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
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

    /// Quét đồng thời nhiều nguồn và gộp, loại trùng, lọc chính xác theo bán kính (mét)
    func quetKhuVuc(
        tam: CLLocationCoordinate2D,
        banKinhMet: Double,
        capNhatTrangThai: @escaping (String) -> Void,
        hoanThanh: @escaping ([DiaDiemQuet], [String]) -> Void
    ) {
        let nhom = DispatchGroup()
        let khoa = NSLock()
        var tatCa: [DiaDiemQuet] = []
        var ghiChuNguon: [String] = []

        func themKetQua(_ ds: [DiaDiemQuet], tenNguon: String) {
            khoa.lock()
            tatCa.append(contentsOf: ds)
            if !ds.isEmpty { ghiChuNguon.append("\(tenNguon) (\(ds.count))") }
            khoa.unlock()
        }

        // 1. Nguồn Apple MapKit LocalSearch (nhanh, dữ liệu Việt Nam rất phong phú, miễn phí)
        DispatchQueue.main.async { capNhatTrangThai("Đang quét đối thủ, trường học & chợ...") }
        nhom.enter()
        quetBangAppleLocalSearch(tam: tam, banKinhMet: banKinhMet) { ds in
            themKetQua(ds, tenNguon: "Bản đồ địa điểm")
            nhom.leave()
        }

        // 2. Nguồn OpenStreetMap Overpass API (truy vấn chính xác theo bán kính mét, miễn phí)
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
            let daLoc = self.hopNhatVaLoaiTrung(tatCa, tam: tam, banKinhMet: banKinhMet)
            DispatchQueue.main.async {
                hoanThanh(daLoc, ghiChuNguon)
            }
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
            ("điện máy", .doiThu),
            ("gia dụng", .doiThu),
            ("điện lạnh", .doiThu),
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

                    guard let loaiChuan = self.phanLoaiChinhXac(ten: ten, diaChi: self.dinhDangDiaChi(item.placemark), goiY: loaiGoiY) else {
                        continue
                    }

                    let diaChi = self.dinhDangDiaChi(item.placemark)
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
          nwr(around:\(r),\(lat),\(lon))["shop"~"^(electronics|appliance|electrical|houseware|hardware|department_store|hifi|computer|marketplace)$"];
          nwr(around:\(r),\(lat),\(lon))["name"~"^(Chợ|Trường|Điện [Mm]áy|Gia [Dd]ụng|Siêu [Tt]hị Điện)",i];
        );
        out center tags 250;
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
                if ["school", "kindergarten", "college", "university"].contains(amenity) {
                    goiY = .truongHoc
                } else if amenity == "marketplace" || shop == "marketplace" {
                    goiY = .cho
                } else if ["electronics", "appliance", "electrical", "houseware", "hardware", "department_store", "hifi", "computer"].contains(shop) {
                    goiY = .doiThu
                } else {
                    goiY = nil
                }

                let duong = (tags["addr:street"] as? String) ?? ""
                let soNha = (tags["addr:housenumber"] as? String) ?? ""
                let phuong = (tags["addr:suburb"] as? String) ?? (tags["addr:district"] as? String) ?? ""
                let diaChi = [soNha, duong, phuong].filter { !$0.isEmpty }.joined(separator: ", ")

                guard let loaiChuan = self.phanLoaiChinhXac(ten: ten, diaChi: diaChi, goiY: goiY) else {
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

                    guard let loaiChuan = self.phanLoaiChinhXac(ten: ten, diaChi: diaChi, goiY: loaiGoiY) else {
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

    private func phanLoaiChinhXac(ten: String, diaChi: String, goiY: LoaiDiaDiemQuet?) -> LoaiDiaDiemQuet? {
        let t = chuanHoaChuoi(ten)
        guard !t.isEmpty else { return nil }

        // 1. Loại trừ hệ thống nhà mình (Điện Máy Xanh / Thế Giới Di Động) khỏi danh sách đối thủ
        let laHeThongNhaMinh = t.contains("dien may xanh") || t.contains("the gioi di dong") || t.contains("topzone") || t == "dmx" || t.hasPrefix("dmx ")
        if laHeThongNhaMinh {
            return nil
        }

        // 2. Nhận diện Đối thủ điện máy / gia dụng trước (tránh nhầm "Điện Máy Chợ Lớn" thành Chợ!)
        let tuKhoaDoiThu = [
            "dien may", "gia dung", "dien lanh", "nguyen kim", "mediamart", "pico", "hc ",
            "sieu thi dien may", "dien may cho lon", "cho lon", "fpt shop", "cellphones",
            "viettel store", "hoang ha mobile", "lock&lock", "elmich", "sunhouse", "kangaroo",
            "karofi", "aqua", "panasonic", "samsung", "lg ", "toshiba", "sharp", "nagakawa",
            "do gia dung", "thiet bi dien", "dien tu", "noi that gia dung", "bep tu", "may lanh", "tu lanh"
        ]
        if tuKhoaDoiThu.contains(where: { t.contains($0) }) {
            // Tránh nhầm tên chợ thật là "Chợ Lớn" nếu không có chữ điện máy
            if t == "cho lon" || (t.hasPrefix("cho ") && !t.contains("dien may")) {
                return .cho
            }
            return .doiThu
        }

        // 3. Nhận diện Trường học
        let tuKhoaTruong = [
            "truong ", "tieu hoc", "thcs", "thpt", "mam non", "mau giao", "nha tre",
            "dai hoc", "cao dang", "trung cap", "hoc vien", "school", "kindergarten",
            "university", "college", "academy", "anh ngu", "ngoai ngu"
        ]
        if tuKhoaTruong.contains(where: { t.contains($0) }) {
            // Loại bỏ mấy quán ăn/tiệm photo gần trường kiểu "Cơm Trường Học", "Quán trà sữa ..."
            let loaiTru = ["quan ", "cafe", "ca phe", "tra sua", "com ", "pho ", "bun ", "nha tro", "khach san", "hotel", "pharmacy", "nha thuoc"]
            if loaiTru.contains(where: { t.hasPrefix($0) }) { return nil }
            return .truongHoc
        }

        // 4. Nhận diện Chợ
        let tuKhoaCho = ["cho ", "cho dem", "cho dau moi", "cho dan sinh", "market", "bazaar"]
        if t.hasPrefix("cho ") || t == "cho" || tuKhoaCho.contains(where: { t.contains($0) }) {
            let loaiTruCho = [
                "mini mart", "minimart", "winmart", "vinmart", "bach hoa xanh", "circle k",
                "gs25", "7-eleven", "sieu thi dien may", "dien may", "quan ", "com ", "pho ",
                "bun ", "banh mi", "cafe", "ca phe", "nha thuoc", "benh vien", "ngan hang", "atm"
            ]
            if loaiTruCho.contains(where: { t.contains($0) }) { return nil }
            return .cho
        }

        // 5. Nếu đến từ nguồn có tag rõ ràng (OSM / Google / Apple) thì giữ lại nếu không phải rác
        if let goiY = goiY {
            if goiY == .cho {
                // Với gợi ý "chợ", bắt buộc tên có chứa chữ chợ/market để tránh kết quả lạc đề
                if t.contains("cho") || t.contains("market") {
                    let loaiTru = ["bach hoa xanh", "winmart", "vinmart", "circle k", "quan ", "cafe", "ca phe", "nha thuoc", "ngan hang"]
                    if loaiTru.contains(where: { t.contains($0) }) { return nil }
                    return .cho
                }
                return nil
            }
            if goiY == .truongHoc {
                let loaiTru = ["quan ", "cafe", "ca phe", "tra sua", "nha thuoc", "atm", "ngan hang", "khach san"]
                if loaiTru.contains(where: { t.contains($0) }) { return nil }
                return .truongHoc
            }
            if goiY == .doiThu {
                let loaiTru = ["quan ", "cafe", "ca phe", "nha thuoc", "benh vien", "truong ", "chua ", "nha tho", "cong an", "uy ban", "ubnd", "ngan hang", "atm"]
                if loaiTru.contains(where: { t.contains($0) }) { return nil }
                return .doiThu
            }
        }

        return nil
    }

    private func hopNhatVaLoaiTrung(
        _ danhSach: [DiaDiemQuet],
        tam: CLLocationCoordinate2D,
        banKinhMet: Double
    ) -> [DiaDiemQuet] {
        // Ưu tiên nguồn: Google > Apple > OSM (vì tên & địa chỉ Google/Apple thường đầy đủ hơn)
        func uuTienNguon(_ n: String) -> Int {
            switch n {
            case "Google": return 3
            case "Apple": return 2
            default: return 1
            }
        }

        let sapXep = danhSach
            .filter { $0.khoangCachMet <= banKinhMet }
            .sorted { a, b in
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

    /// Chọn các điểm nóng hiệu quả nhất (Chợ + Trường học + Cụm đối thủ), sắp xếp lộ trình tối ưu (Nearest-Neighbor + 2-opt) và vẽ đường thực tế qua OSRM
    func tinhTuyenHieuQuaNhat(
        tam: CLLocationCoordinate2D,
        danhSach: [DiaDiemQuet],
        hoanThanh: @escaping (KetQuaTuyenPhatToRoi?) -> Void
    ) {
        guard !danhSach.isEmpty else {
            DispatchQueue.main.async { hoanThanh(nil) }
            return
        }

        // 1. Chấm điểm mật độ & giá trị phát tờ rơi cho từng điểm
        let viTriAll = danhSach.map { CLLocation(latitude: $0.viDo, longitude: $0.kinhDo) }
        var diemSo: [(DiaDiemQuet, Double)] = []
        for (i, item) in danhSach.enumerated() {
            var score = item.loai.diemUuTienToRoi
            // Thưởng điểm cụm mật độ: càng nhiều điểm nóng khác trong bán kính 300m càng đáng ghé phát tờ rơi
            var lanCan = 0
            for (j, otherLoc) in viTriAll.enumerated() where i != j {
                if viTriAll[i].distance(from: otherLoc) <= 300 {
                    lanCan += 1
                }
            }
            score += Double(min(lanCan, 6)) * 1.4
            // Ưu tiên nhẹ các điểm không quá sát rìa
            score += max(0, 2.0 - item.khoangCachMet / 1500.0)
            diemSo.append((item, score))
        }

        // 2. Gom cụm nhỏ (< 90m) để không dừng 2 lần quá sát nhau, chọn tối đa 11 điểm dừng chiến lược
        // (Vừa chuẩn hiệu quả thực tế vừa khớp giới hạn waypoint khi mở Google Maps dẫn đường)
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
        if daChon.isEmpty, let dau = danhSach.first {
            daChon = [dau]
        }

        // 3. Tối ưu thứ tự đi qua: Nearest Neighbor từ điểm xuất phát (Siêu thị) + cải thiện 2-opt
        let thuTuToiUu = toiUuThuTuTSP(xuatPhat: tam, cacDiem: daChon)
        var diemCoSoThuTu: [DiaDiemQuet] = []
        for (idx, var d) in thuTuToiUu.enumerated() {
            d.soThuTuTuyen = idx + 1
            diemCoSoThuTu.append(d)
        }

        // 4. Tính khoảng cách từng chặng thẳng làm dự phòng
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

        // 5. Gọi OSRM để bám theo đường giao thông thực tế
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

                // Cộng thêm ~3 phút dừng phát tờ rơi cho mỗi điểm nóng
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

        // Nearest Neighbor
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

        // 2-opt cải thiện đường đi mở (từ xuatPhat qua loTrinh[0...n-1])
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
            let bestInit = tongChieuDai(loTrinh)
            var bestLen = bestInit
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

    private enum BoLocDanhSach: Int {
        case tatCa = 0
        case doiThu = 1
        case truongHoc = 2
        case cho = 3
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

    private var tatCaDiaDiem: [DiaDiemQuet] = []
    private var ketQuaTuyen: KetQuaTuyenPhatToRoi? = nil
    private var lopTileGoogle: MKTileOverlay?

    // Giao diện chính
    private let cuonChinh = UIScrollView()
    private let nganChinh = UIStackView()

    // Khối điều khiển tìm kiếm & bán kính
    private let oTimDiaChi = UITextField()
    private let nutTimDiaChi = UIButton(type: .system)
    private let nutViTriToi = UIButton(type: .system)
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

    // 3 thẻ thống kê KPI
    private let nhanSoDoiThu = UILabel()
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
    private let chonBoLoc = UISegmentedControl(items: ["Tất cả", "Đối thủ", "Trường học", "Chợ"])
    private let nganDanhSachDiaDiem = UIStackView()
    private let nhanTrongDanhSach = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BangMauBCTD.nenTrang
        khoiPhucTrangThaiDaLuu()
        cauHinhViTri()
        taoGiaoDien()
        apDungLopNenBanDo()
        capNhatTamVaVongTronTrenBanDo(diChuyenCamera: true)
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
        nganChinh.addArrangedSubview(taoHang3TheKPI())
        nganChinh.addArrangedSubview(taoTheTuyenPhatToRoi())
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
        nutCauHinhGoogleKey.addTarget(self, action: #selector(bamCaiDatGoogleKey), for: .touchUpInside)

        let hangTieuDe = UIStackView(arrangedSubviews: [tieuDe, UIView(), nutCauHinhGoogleKey])
        hangTieuDe.axis = .horizontal
        hangTieuDe.alignment = .center

        // Hàng 1: Tìm địa chỉ / Siêu thị + GPS
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
        oTimDiaChi.heightAnchor.constraint(equalToConstant: 38).isActive = true

        nutTimDiaChi.setTitle("Tìm", for: .normal)
        nutTimDiaChi.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        nutTimDiaChi.setTitleColor(.white, for: .normal)
        nutTimDiaChi.backgroundColor = BangMauBCTD.xanhBienChuDao
        nutTimDiaChi.layer.cornerRadius = 9
        nutTimDiaChi.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        nutTimDiaChi.heightAnchor.constraint(equalToConstant: 38).isActive = true
        nutTimDiaChi.setContentHuggingPriority(.required, for: .horizontal)
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
        nutViTriToi.addTarget(self, action: #selector(bamLayViTriHienTai), for: .touchUpInside)

        let hangTim = UIStackView(arrangedSubviews: [oTimDiaChi, nutTimDiaChi, nutViTriToi])
        hangTim.axis = .horizontal
        hangTim.spacing = 6

        // Hàng 2: Nhập bán kính (mét) + Nút Quét khu vực
        let nhanBK = UILabel()
        nhanBK.text = "Bán kính:"
        nhanBK.font = .systemFont(ofSize: 13, weight: .bold)
        nhanBK.textColor = BangMauBCTD.chuChinh
        nhanBK.setContentHuggingPriority(.required, for: .horizontal)

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
        oNhapBanKinh.widthAnchor.constraint(equalToConstant: 88).isActive = true
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
        nhanMet.text = "mét"
        nhanMet.font = .systemFont(ofSize: 13, weight: .semibold)
        nhanMet.textColor = BangMauBCTD.chuPhu
        nhanMet.setContentHuggingPriority(.required, for: .horizontal)

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

        // Hàng 3: Chọn nhanh bán kính
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

        nhanTrangThaiQuet.text = "Nhập bán kính (mét) hoặc chạm giữ trên bản đồ để đặt tâm, rồi bấm Quét khu vực."
        nhanTrangThaiQuet.font = .systemFont(ofSize: 12, weight: .medium)
        nhanTrangThaiQuet.textColor = BangMauBCTD.chuPhu
        nhanTrangThaiQuet.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [hangTieuDe, hangTim, hangBanKinh, hangChonNhanh, nhanTrangThaiQuet])
        stack.axis = .vertical
        stack.spacing = 9
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

        // Thanh chuyển kiểu bản đồ (Google Maps Road / Satellite / Apple)
        chonKieuBanDo.selectedSegmentIndex = 0
        chonKieuBanDo.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        chonKieuBanDo.selectedSegmentTintColor = BangMauBCTD.xanhChuDao
        chonKieuBanDo.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 11.5, weight: .bold)], for: .selected)
        chonKieuBanDo.setTitleTextAttributes([.foregroundColor: BangMauBCTD.chuChinh, .font: UIFont.systemFont(ofSize: 11.5, weight: .semibold)], for: .normal)
        chonKieuBanDo.translatesAutoresizingMaskIntoConstraints = false
        chonKieuBanDo.addTarget(self, action: #selector(doiKieuBanDo), for: .valueChanged)
        khungBanDo.addSubview(chonKieuBanDo)

        // Nút bật/tắt tuyến tờ rơi
        nutBatTatTuyen.setTitle("🛣️ Tuyến: Bật", for: .normal)
        nutBatTatTuyen.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutBatTatTuyen.setTitleColor(.white, for: .normal)
        nutBatTatTuyen.backgroundColor = BangMauBCTD.xanhDatVach.withAlphaComponent(0.94)
        nutBatTatTuyen.layer.cornerRadius = 8
        nutBatTatTuyen.contentEdgeInsets = UIEdgeInsets(top: 5, left: 9, bottom: 5, right: 9)
        nutBatTatTuyen.translatesAutoresizingMaskIntoConstraints = false
        nutBatTatTuyen.addTarget(self, action: #selector(bamBatTatTuyen), for: .touchUpInside)
        khungBanDo.addSubview(nutBatTatTuyen)

        // Nút phóng to / thu nhỏ bản đồ
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

        nhanGoiYBanDo.text = "  📍 Chạm giữ bản đồ để dời tâm quét  "
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

    private func taoHang3TheKPI() -> UIView {
        let theDoiThu = taoMotTheKPI(loai: .doiThu, nhanSo: nhanSoDoiThu, tagLoc: BoLocDanhSach.doiThu.rawValue)
        let theTruong = taoMotTheKPI(loai: .truongHoc, nhanSo: nhanSoTruongHoc, tagLoc: BoLocDanhSach.truongHoc.rawValue)
        let theCho = taoMotTheKPI(loai: .cho, nhanSo: nhanSoCho, tagLoc: BoLocDanhSach.cho.rawValue)

        let hang = UIStackView(arrangedSubviews: [theDoiThu, theTruong, theCho])
        hang.axis = .horizontal
        hang.spacing = 8
        hang.distribution = .fillEqually
        return hang
    }

    private func taoMotTheKPI(loai: LoaiDiaDiemQuet, nhanSo: UILabel, tagLoc: Int) -> UIControl {
        let the = UIControl()
        the.tag = tagLoc
        the.backgroundColor = loai.mauNenNhat
        the.layer.cornerRadius = 12
        the.layer.borderWidth = 1.2
        the.layer.borderColor = loai.mauChuDao.withAlphaComponent(0.35).cgColor
        the.addTarget(self, action: #selector(bamTheKPI(_:)), for: .touchUpInside)

        let cfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        let icon = UIImageView(image: UIImage(systemName: loai.bieuTuongSF, withConfiguration: cfg))
        icon.tintColor = loai.mauChuDao
        icon.contentMode = .scaleAspectFit

        let tieuDe = UILabel()
        tieuDe.text = loai.tieuDe
        tieuDe.font = .systemFont(ofSize: 12, weight: .bold)
        tieuDe.textColor = BangMauBCTD.chuChinh
        tieuDe.textAlignment = .center

        nhanSo.text = "0"
        nhanSo.font = .systemFont(ofSize: 24, weight: .heavy)
        nhanSo.textColor = loai.mauChuDao
        nhanSo.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [icon, nhanSo, tieuDe])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 3
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        the.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: the.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: the.leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: the.trailingAnchor, constant: -6),
            stack.bottomAnchor.constraint(equalTo: the.bottomAnchor, constant: -10)
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
        // Xóa vòng tròn cũ và ghim tâm cũ
        let vongCu = banDo.overlays.filter { $0 is MKCircle }
        banDo.removeOverlays(vongCu)

        let ghimTamCu = banDo.annotations.filter { $0 is GhimTamQuetAnnotation }
        banDo.removeAnnotations(ghimTamCu)

        let ghimMoi = GhimTamQuetAnnotation(coordinate: tamQuet, title: tenTamQuet, subtitle: "Bán kính quét: \(Int(banKinhMet)) m")
        banDo.addAnnotation(ghimMoi)

        let vongMoi = MKCircle(center: tamQuet, radius: banKinhMet)
        banDo.addOverlay(vongMoi, level: .aboveLabels)

        if diChuyenCamera {
            let spanMet = max(600, banKinhMet * 2.55)
            let region = MKCoordinateRegion(center: tamQuet, latitudinalMeters: spanMet, longitudinalMeters: spanMet)
            banDo.setRegion(region, animated: true)
        }
    }

    private func veLaiGhimVaTuyenTrenBanDo() {
        // Xóa ghim địa điểm cũ & polyline cũ
        let ghimCu = banDo.annotations.filter { $0 is GhimDiaDiemAnnotation }
        banDo.removeAnnotations(ghimCu)

        let duongCu = banDo.overlays.filter { $0 is MKPolyline }
        banDo.removeOverlays(duongCu)

        // Gắn số thứ tự tuyến vào các địa điểm nếu có
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

    // MARK: - Hành Động Người Dùng

    @objc private func anBanPhim() {
        view.endEditing(true)
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
        tenTamQuet = String(format: "Tâm quét (%.4f, %.4f)", toaDo.latitude, toaDo.longitude)
        luuTrangThaiTamVaBanKinh()
        capNhatTamVaVongTronTrenBanDo(diChuyenCamera: false)
        nhanTrangThaiQuet.text = "Đã dời tâm quét tới vị trí mới. Bấm \"Quét khu vực\" để quét lại."
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
                    self.capNhatTamVaVongTronTrenBanDo(diChuyenCamera: true)
                    self.nhanTrangThaiQuet.text = "Đã chuyển tâm tới: \(self.tenTamQuet). Bấm \"Quét khu vực\" để bắt đầu."
                } else {
                    self.nhanTrangThaiQuet.text = "Không tìm thấy \"\(tuKhoa)\". Thử nhập tên đường, phường/quận rõ hơn (\(err?.localizedDescription ?? "không có kết quả"))."
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

        dangQuet = true
        nutQuetKhuVuc.isEnabled = false
        nutQuetKhuVuc.alpha = 0.65
        vongQuayQuet.startAnimating()
        nhanTrangThaiQuet.text = "Đang quét đối thủ, trường học và chợ trong bán kính \(Int(banKinhMet)) m..."

        DichVuQuetKhuVuc.dungChung.quetKhuVuc(
            tam: tamQuet,
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
                    self.ketThucQuet(thongBao: "Không tìm thấy đối thủ, trường học hoặc chợ nào trong bán kính \(Int(self.banKinhMet)) m. Thử tăng bán kính lên nhé!")
                    return
                }

                self.nhanTrangThaiQuet.text = "Đã tìm thấy \(dsKetQua.count) địa điểm. Đang tối ưu tuyến phát tờ rơi hiệu quả nhất..."
                BoToiUuTuyenPhatToRoi.dungChung.tinhTuyenHieuQuaNhat(tam: self.tamQuet, danhSach: dsKetQua) { [weak self] tuyen in
                    guard let self = self else { return }
                    self.ketQuaTuyen = tuyen
                    let soDT = dsKetQua.filter { $0.loai == .doiThu }.count
                    let soTH = dsKetQua.filter { $0.loai == .truongHoc }.count
                    let soCho = dsKetQua.filter { $0.loai == .cho }.count
                    let chuoiNguon = nguon.isEmpty ? "" : " • Nguồn: \(nguon.joined(separator: ", "))"
                    self.ketThucQuet(
                        thongBao: "Hoàn tất bán kính \(Int(self.banKinhMet))m: \(soDT) đối thủ, \(soTH) trường học, \(soCho) chợ\(chuoiNguon)."
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
    }

    private func capNhatThongKeKPI() {
        let soDT = tatCaDiaDiem.filter { $0.loai == .doiThu }.count
        let soTH = tatCaDiaDiem.filter { $0.loai == .truongHoc }.count
        let soCho = tatCaDiaDiem.filter { $0.loai == .cho }.count

        nhanSoDoiThu.text = "\(soDT)"
        nhanSoTruongHoc.text = "\(soTH)"
        nhanSoCho.text = "\(soCho)"

        chonBoLoc.setTitle("Tất cả (\(tatCaDiaDiem.count))", forSegmentAt: 0)
        chonBoLoc.setTitle("Đối thủ (\(soDT))", forSegmentAt: 1)
        chonBoLoc.setTitle("Trường (\(soTH))", forSegmentAt: 2)
        chonBoLoc.setTitle("Chợ (\(soCho))", forSegmentAt: 3)
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
        case .truongHoc: dsLoc = tatCaDiaDiem.filter { $0.loai == .truongHoc }
        case .cho: dsLoc = tatCaDiaDiem.filter { $0.loai == .cho }
        }

        nhanTrongDanhSach.isHidden = !dsLoc.isEmpty
        if dsLoc.isEmpty && !tatCaDiaDiem.isEmpty {
            nhanTrongDanhSach.text = "Không có địa điểm nào thuộc mục đang lọc."
        }

        for diem in dsLoc.prefix(80) {
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
        let origin = "\(tamQuet.latitude),\(tamQuet.longitude)"
        let dest = "\(den.latitude),\(den.longitude)"
        let webStr = "https://www.google.com/maps/dir/?api=1&origin=\(origin)&destination=\(dest)&travelmode=driving"
        if let url = URL(string: webStr) {
            UIApplication.shared.open(url)
        }
    }

    @objc private func bamMoGoogleMapsTuyen() {
        guard let tuyen = ketQuaTuyen, !tuyen.cacDiemDung.isEmpty else { return }
        let origin = "\(tamQuet.latitude),\(tamQuet.longitude)"
        let ds = tuyen.cacDiemDung
        guard let diemCuoi = ds.last else { return }
        let dest = "\(diemCuoi.viDo),\(diemCuoi.kinhDo)"

        // Google Maps URL hỗ trợ tối đa 9 waypoints trung gian
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
        let soTH = tatCaDiaDiem.filter { $0.loai == .truongHoc }.count
        let soCho = tatCaDiaDiem.filter { $0.loai == .cho }.count

        var dong: [String] = [
            "📍 BÁO CÁO QUÉT KHU VỰC & TUYẾN PHÁT TỜ RƠI",
            "• Tâm quét: \(tenTamQuet)",
            "• Bán kính: \(Int(banKinhMet)) m",
            "• Đối thủ điện máy/gia dụng: \(soDT)",
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
        nhanTrangThaiQuet.text = "Đã định vị GPS thành công. Nhập bán kính và bấm \"Quét khu vực\"."
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
            view.glyphImage = UIImage(systemName: "star.fill")
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
}
