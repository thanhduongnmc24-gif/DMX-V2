import UIKit
import MapKit
import CoreLocation

// MARK: - 1. Kho Lưu Bền Vững Kết Quả Quét Khu Vực (Giữ Nguyên Thông Số Cho Đến Khi Quét Lại)

struct KetQuaTuyenLuu: Codable, Equatable {
    let cacDiemDung: [DiaDiemQuet]
    let toaDoDuongDi: [[Double]]
    let tongQuangDuongMet: Double
    let thoiGianPhut: Int
    let laDuongThucTe: Bool
    let khoangCachTungChangMet: [Double]
    let chiDanTungBuoc: [BuocChiDanTuyen]
    let thoiGianXeMayPhut: Int
    let thoiGianDiBoPhut: Int

    init(
        cacDiemDung: [DiaDiemQuet],
        toaDoDuongDi: [[Double]],
        tongQuangDuongMet: Double,
        thoiGianPhut: Int,
        laDuongThucTe: Bool,
        khoangCachTungChangMet: [Double],
        chiDanTungBuoc: [BuocChiDanTuyen] = [],
        thoiGianXeMayPhut: Int = 0,
        thoiGianDiBoPhut: Int = 0
    ) {
        self.cacDiemDung = cacDiemDung
        self.toaDoDuongDi = toaDoDuongDi
        self.tongQuangDuongMet = tongQuangDuongMet
        self.thoiGianPhut = thoiGianPhut
        self.laDuongThucTe = laDuongThucTe
        self.khoangCachTungChangMet = khoangCachTungChangMet
        self.chiDanTungBuoc = chiDanTungBuoc
        self.thoiGianXeMayPhut = thoiGianXeMayPhut
        self.thoiGianDiBoPhut = thoiGianDiBoPhut
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        cacDiemDung = (try? c.decode([DiaDiemQuet].self, forKey: .cacDiemDung)) ?? []
        toaDoDuongDi = (try? c.decode([[Double]].self, forKey: .toaDoDuongDi)) ?? []
        tongQuangDuongMet = (try? c.decode(Double.self, forKey: .tongQuangDuongMet)) ?? 0
        thoiGianPhut = (try? c.decode(Int.self, forKey: .thoiGianPhut)) ?? 0
        laDuongThucTe = (try? c.decode(Bool.self, forKey: .laDuongThucTe)) ?? false
        khoangCachTungChangMet = (try? c.decode([Double].self, forKey: .khoangCachTungChangMet)) ?? []
        chiDanTungBuoc = (try? c.decode([BuocChiDanTuyen].self, forKey: .chiDanTungBuoc)) ?? []
        thoiGianXeMayPhut = (try? c.decode(Int.self, forKey: .thoiGianXeMayPhut)) ?? max(1, thoiGianPhut)
        thoiGianDiBoPhut = (try? c.decode(Int.self, forKey: .thoiGianDiBoPhut)) ?? max(3, Int(ceil(tongQuangDuongMet / 75.0)))
    }
}

struct KetQuaQuetKhuVucLuu: Codable, Equatable {
    let tatCaDiaDiem: [DiaDiemQuet]
    let banKinhQuetMet: Double
    let tenTamQuet: String
    let tamLat: Double
    let tamLon: Double
    let nguonQuet: [String]
    let thoiGianQuet: String
    let thongBaoTrangThai: String
    let ketQuaTuyen: KetQuaTuyenLuu?
}

final class KhoKetQuaQuetKhuVuc {
    static let dungChung = KhoKetQuaQuetKhuVuc()
    private init() {}

    private let hangDoi = DispatchQueue(label: "com.thanhduong.v2dmx.quetkhuvuc.luu", qos: .utility)

    private var tepLuu: URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("DMX_KetQuaQuetKhuVuc", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("ket_qua_quet_v1.json")
    }

    func taiKetQuaDaLuu() -> KetQuaQuetKhuVucLuu? {
        guard let data = try? Data(contentsOf: tepLuu) else { return nil }
        return try? JSONDecoder().decode(KetQuaQuetKhuVucLuu.self, from: data)
    }

    func luuKetQua(_ banLuu: KetQuaQuetKhuVucLuu) {
        hangDoi.async {
            if let data = try? JSONEncoder().encode(banLuu) {
                try? data.write(to: self.tepLuu, options: .atomic)
            }
        }
    }
}

// MARK: - 2. Bộ Dẫn Đường Bám Sát Đường Thực Tế & Chỉ Dẫn Rẽ Trái / Rẽ Phải Cho Từng Tuyến

final class BoDanDuongTuyenThucTe {
    static let dungChung = BoDanDuongTuyenThucTe()
    private init() {}

    private let phienMang: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 14
        cfg.timeoutIntervalForResource = 22
        return URLSession(configuration: cfg)
    }()

    static func dinhDangKhoangCach(_ met: Double) -> String {
        if met >= 1000.0 {
            return String(format: "%.2f km", met / 1000.0)
        }
        return "\(max(1, Int(met.rounded())))m"
    }

    static func dinhDangPhut(_ phut: Int) -> String {
        let p = max(1, phut)
        if p >= 60 {
            let gio = p / 60
            let du = p % 60
            return du == 0 ? "\(gio) giờ" : "\(gio) giờ \(du) phút"
        }
        return "\(p) phút"
    }

    static func tinhThoiGianXeMayPhut(quangDuongMet: Double, durationOSRMGiay: Double? = nil) -> Int {
        // Xe máy đô thị Việt Nam trung bình ~24 km/h (400 m/phút)
        let theoQuangDuong = ceil(quangDuongMet / 400.0)
        if let sec = durationOSRMGiay, sec > 0 {
            let theoOSRM = ceil((sec / 60.0) * 1.15)
            return max(2, Int(max(theoQuangDuong * 0.85, theoOSRM)))
        }
        return max(2, Int(theoQuangDuong))
    }

    static func tinhThoiGianDiBoPhut(quangDuongMet: Double) -> Int {
        // Đi bộ kết hợp quan sát khu vực ~4.5 km/h (75 m/phút)
        return max(3, Int(ceil(quangDuongMet / 75.0)))
    }

    /// Cập nhật đường bám sát thực tế (OSRM steps=true, dự phòng Apple MKDirections) cho tất cả các tuyến phát tờ rơi
    func capNhatDuongThucTeChoTatCaTuyen(
        cacTuyen: [TuyenPhatToRoiMaTran],
        tenDiemXuatPhat: String,
        capNhatTungTuyen: @escaping (TuyenPhatToRoiMaTran) -> Void,
        hoanTatTatCa: @escaping () -> Void
    ) {
        let hopLe = cacTuyen.filter { $0.cacToaDo.count >= 2 }
        guard !hopLe.isEmpty else {
            DispatchQueue.main.async { hoanTatTatCa() }
            return
        }

        func chayTuyen(chiSo: Int) {
            guard chiSo < hopLe.count else {
                DispatchQueue.main.async { hoanTatTatCa() }
                return
            }
            let tuyen = hopLe[chiSo]
            self.tinhDuongThucTeChoMotTuyen(tuyen: tuyen, tenDiemXuatPhat: tenDiemXuatPhat) { daCapNhat in
                DispatchQueue.main.async {
                    capNhatTungTuyen(daCapNhat)
                }
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.18) {
                    chayTuyen(chiSo: chiSo + 1)
                }
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            chayTuyen(chiSo: 0)
        }
    }

    func tinhDuongThucTeChoMotTuyen(
        tuyen: TuyenPhatToRoiMaTran,
        tenDiemXuatPhat: String,
        hoanTat: @escaping (TuyenPhatToRoiMaTran) -> Void
    ) {
        guard tuyen.cacToaDo.count >= 2 else {
            hoanTat(tuyen)
            return
        }

        let tenXuatPhat = tenDiemXuatPhat.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (tuyen.tenDiemXuatPhat.isEmpty ? "Siêu thị (Tâm quét)" : tuyen.tenDiemXuatPhat)
            : tenDiemXuatPhat

        let chuoiLonLat = tuyen.cacToaDo.compactMap { p -> String? in
            guard p.count >= 2 else { return nil }
            return String(format: "%.6f,%.6f", p[1], p[0])
        }.joined(separator: ";")

        guard !chuoiLonLat.isEmpty,
              let url = URL(string: "https://router.project-osrm.org/route/v1/driving/\(chuoiLonLat)?overview=full&geometries=geojson&steps=true") else {
            tinhDuongDuPhongAppleDirections(tuyen: tuyen, tenDiemXuatPhat: tenXuatPhat, hoanTat: hoanTat)
            return
        }

        var req = URLRequest(url: url)
        req.setValue("DMX-V2-iOS/1.0", forHTTPHeaderField: "User-Agent")

        phienMang.dataTask(with: req) { [weak self] data, resp, err in
            guard let self else { return }
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            if err == nil, code == 200, let data,
               let kq = self.phanTichOSRM(data: data, tuyenGoc: tuyen, tenDiemXuatPhat: tenXuatPhat) {
                hoanTat(kq)
            } else {
                // Dự phòng bám đường thật bằng Apple MapKit MKDirections nếu OSRM bận / timeout
                self.tinhDuongDuPhongAppleDirections(tuyen: tuyen, tenDiemXuatPhat: tenXuatPhat, hoanTat: hoanTat)
            }
        }.resume()
    }

    private func phanTichOSRM(
        data: Data,
        tuyenGoc: TuyenPhatToRoiMaTran,
        tenDiemXuatPhat: String
    ) -> TuyenPhatToRoiMaTran? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let routes = json["routes"] as? [[String: Any]],
              let route = routes.first,
              let geom = route["geometry"] as? [String: Any],
              let coordsRaw = geom["coordinates"] as? [[Double]],
              coordsRaw.count >= 2 else {
            return nil
        }

        let toaDoDuong: [[Double]] = coordsRaw.compactMap { pair in
            guard pair.count >= 2 else { return nil }
            return [pair[1], pair[0]]
        }
        guard toaDoDuong.count >= 2 else { return nil }

        let dist = (route["distance"] as? Double) ?? tuyenGoc.tongQuangDuongMet
        let durSec = route["duration"] as? Double
        let legs = (route["legs"] as? [[String: Any]]) ?? []

        let buocChiDan = Self.xayDungChiDanTuOSRM(
            legs: legs,
            tenDiemXuatPhat: tenDiemXuatPhat,
            cacDiemDung: tuyenGoc.cacDiemMucTieu
        )

        var moi = tuyenGoc
        moi.tenDiemXuatPhat = tenDiemXuatPhat
        moi.toaDoDuongThucTe = toaDoDuong
        moi.laDuongThucTe = true
        moi.tongQuangDuongMet = dist
        moi.thoiGianXeMayPhut = Self.tinhThoiGianXeMayPhut(quangDuongMet: dist, durationOSRMGiay: durSec)
        moi.thoiGianDiBoPhut = Self.tinhThoiGianDiBoPhut(quangDuongMet: dist)
        if !buocChiDan.isEmpty {
            moi.chiDanTungBuoc = buocChiDan
        }
        return moi
    }

    static func xayDungChiDanTuOSRM(
        legs: [[String: Any]],
        tenDiemXuatPhat: String,
        cacDiemDung: [DiemMucTieuTuyen]
    ) -> [BuocChiDanTuyen] {
        var ketQua: [BuocChiDanTuyen] = [
            BuocChiDanTuyen(
                stt: 1,
                hanhDong: "🚩 Xuất phát",
                noiDung: "Bắt đầu từ \(tenDiemXuatPhat)",
                khoangCachMet: 0,
                laDiemDung: false
            )
        ]

        for (legIdx, leg) in legs.enumerated() {
            let steps = (leg["steps"] as? [[String: Any]]) ?? []
            for step in steps {
                let maneuver = (step["maneuver"] as? [String: Any]) ?? [:]
                let type = (maneuver["type"] as? String ?? "").lowercased()
                let modifier = (maneuver["modifier"] as? String ?? "").lowercased()
                let exitNum = maneuver["exit"] as? Int
                let dist = (step["distance"] as? Double) ?? 0
                let tenDuongRaw = (step["name"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let tenDuong = tenDuongRaw.isEmpty ? "" : " vào \(tenDuongRaw)"
                let theoDuong = tenDuongRaw.isEmpty ? "" : " theo \(tenDuongRaw)"

                if type == "arrive" {
                    continue
                }
                if dist < 12 && (type == "new name" || type == "continue" || type == "notification") {
                    continue
                }

                let (icon, moTa): (String, String)
                switch type {
                case "depart":
                    icon = "⬆️ Đi thẳng"
                    let huongText = dichHuongModifier(modifier)
                    if !tenDuongRaw.isEmpty {
                        moTa = "Đi\(huongText) theo \(tenDuongRaw) (\(dinhDangKhoangCach(dist)))"
                    } else {
                        moTa = "Đi\(huongText) thẳng (\(dinhDangKhoangCach(dist)))"
                    }
                case "turn", "end of road", "off ramp", "on ramp":
                    let (ic, chu) = dichRe(modifier: modifier)
                    icon = ic
                    moTa = "\(chu)\(tenDuong) — đi \(dinhDangKhoangCach(dist))"
                case "fork":
                    let (ic, chu) = dichRe(modifier: modifier, macDinh: "Giữ làn")
                    icon = ic
                    moTa = "Tại ngã ba, \(chu.lowercased())\(tenDuong) — đi \(dinhDangKhoangCach(dist))"
                case "roundabout", "rotary", "roundabout turn":
                    if dist < 20 { continue }
                    icon = "⭕ Vòng xuyến"
                    let loiRa = exitNum.map { " ra lối thứ \($0)" } ?? ""
                    moTa = "Vào vòng xuyến,\(loiRa)\(tenDuong) — đi \(dinhDangKhoangCach(dist))"
                case "exit roundabout", "exit rotary":
                    icon = "⭕ Ra vòng xuyến"
                    moTa = "Ra khỏi vòng xuyến\(tenDuong) — đi \(dinhDangKhoangCach(dist))"
                case "merge":
                    icon = "🔀 Nhập làn"
                    moTa = "Nhập làn\(tenDuong) — đi \(dinhDangKhoangCach(dist))"
                case "continue", "new name":
                    icon = "⬆️ Đi thẳng"
                    moTa = "Tiếp tục đi thẳng\(theoDuong) (\(dinhDangKhoangCach(dist)))"
                default:
                    if !modifier.isEmpty {
                        let (ic, chu) = dichRe(modifier: modifier)
                        icon = ic
                        moTa = "\(chu)\(tenDuong) — đi \(dinhDangKhoangCach(dist))"
                    } else {
                        icon = "⬆️ Đi thẳng"
                        moTa = "Đi tiếp\(theoDuong) (\(dinhDangKhoangCach(dist)))"
                    }
                }

                ketQua.append(BuocChiDanTuyen(
                    stt: ketQua.count + 1,
                    hanhDong: icon,
                    noiDung: moTa,
                    khoangCachMet: dist,
                    laDiemDung: false
                ))
            }

            // Chèn mốc địa điểm dừng phát tờ rơi sau mỗi chặng
            let legDist = (leg["distance"] as? Double) ?? 0
            if legIdx < cacDiemDung.count {
                let d = cacDiemDung[legIdx]
                let dc = d.diaChi.isEmpty ? "" : "\n   ↳ Địa chỉ: \(d.diaChi)"
                ketQua.append(BuocChiDanTuyen(
                    stt: ketQua.count + 1,
                    hanhDong: "📍 Điểm #\(legIdx + 1)",
                    noiDung: "Đến \(d.ten) (\(d.loaiRaw)) • chặng \(dinhDangKhoangCach(legDist))\(dc)",
                    khoangCachMet: legDist,
                    laDiemDung: true
                ))
            }
        }

        return ketQua
    }

    private static func dichHuongModifier(_ modifier: String) -> String {
        switch modifier {
        case "left": return " hướng trái"
        case "right": return " hướng phải"
        case "slight left": return " chếch trái"
        case "slight right": return " chếch phải"
        default: return ""
        }
    }

    private static func dichRe(modifier: String, macDinh: String = "Đi thẳng") -> (String, String) {
        switch modifier {
        case "right": return ("➡️ Rẽ phải", "Rẽ phải")
        case "slight right": return ("↗️ Chếch phải", "Đi chếch sang phải")
        case "sharp right": return ("↪️ Ngoặt phải", "Rẽ ngoặt sang phải")
        case "left": return ("⬅️ Rẽ trái", "Rẽ trái")
        case "slight left": return ("↖️ Chếch trái", "Đi chếch sang trái")
        case "sharp left": return ("↩️ Ngoặt trái", "Rẽ ngoặt sang trái")
        case "uturn": return ("🔄 Quay đầu", "Quay đầu lại")
        case "straight": return ("⬆️ Đi thẳng", "Đi thẳng")
        default: return ("⬆️ \(macDinh)", macDinh)
        }
    }

    private func tinhDuongDuPhongAppleDirections(
        tuyen: TuyenPhatToRoiMaTran,
        tenDiemXuatPhat: String,
        hoanTat: @escaping (TuyenPhatToRoiMaTran) -> Void
    ) {
        let waypoints: [CLLocationCoordinate2D] = tuyen.cacToaDo.compactMap { p in
            guard p.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: p[0], longitude: p[1])
        }
        guard waypoints.count >= 2 else {
            hoanTat(tuyen)
            return
        }

        var tatCaToaDo: [[Double]] = []
        var tongMet: Double = 0
        var tongGiay: Double = 0
        var coItNhatMotChangThucTe = false
        var buocChiDan: [BuocChiDanTuyen] = [
            BuocChiDanTuyen(stt: 1, hanhDong: "🚩 Xuất phát", noiDung: "Bắt đầu từ \(tenDiemXuatPhat)", khoangCachMet: 0, laDiemDung: false)
        ]

        func chayChang(idx: Int) {
            guard idx < waypoints.count - 1 else {
                var moi = tuyen
                moi.tenDiemXuatPhat = tenDiemXuatPhat
                if coItNhatMotChangThucTe && tatCaToaDo.count >= 2 {
                    moi.toaDoDuongThucTe = tatCaToaDo
                    moi.laDuongThucTe = true
                    moi.tongQuangDuongMet = tongMet
                    moi.thoiGianXeMayPhut = Self.tinhThoiGianXeMayPhut(quangDuongMet: tongMet, durationOSRMGiay: tongGiay > 0 ? tongGiay : nil)
                    moi.thoiGianDiBoPhut = Self.tinhThoiGianDiBoPhut(quangDuongMet: tongMet)
                    moi.chiDanTungBuoc = buocChiDan
                }
                hoanTat(moi)
                return
            }

            let req = MKDirections.Request()
            req.source = MKMapItem(placemark: MKPlacemark(coordinate: waypoints[idx]))
            req.destination = MKMapItem(placemark: MKPlacemark(coordinate: waypoints[idx + 1]))
            req.transportType = .automobile

            MKDirections(request: req).calculate { resp, _ in
                if let route = resp?.routes.first {
                    coItNhatMotChangThucTe = true
                    tongMet += route.distance
                    tongGiay += route.expectedTravelTime
                    let pts = route.polyline.points()
                    for k in 0..<route.polyline.pointCount {
                        let coord = pts[k].coordinate
                        tatCaToaDo.append([coord.latitude, coord.longitude])
                    }
                    for step in route.steps {
                        let instr = step.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !instr.isEmpty else { continue }
                        let low = instr.lowercased()
                        let ic: String
                        if low.contains("phải") || low.contains("right") { ic = "➡️ Rẽ phải" }
                        else if low.contains("trái") || low.contains("left") { ic = "⬅️ Rẽ trái" }
                        else if low.contains("quay") || low.contains("u-turn") { ic = "🔄 Quay đầu" }
                        else if low.contains("vòng xuyến") || low.contains("roundabout") { ic = "⭕ Vòng xuyến" }
                        else { ic = "⬆️ Đi tiếp" }
                        buocChiDan.append(BuocChiDanTuyen(
                            stt: buocChiDan.count + 1,
                            hanhDong: ic,
                            noiDung: "\(instr) (\(Self.dinhDangKhoangCach(step.distance)))",
                            khoangCachMet: step.distance,
                            laDiemDung: false
                        ))
                    }
                    if idx < tuyen.cacDiemMucTieu.count {
                        let d = tuyen.cacDiemMucTieu[idx]
                        let dc = d.diaChi.isEmpty ? "" : "\n   ↳ Địa chỉ: \(d.diaChi)"
                        buocChiDan.append(BuocChiDanTuyen(
                            stt: buocChiDan.count + 1,
                            hanhDong: "📍 Điểm #\(idx + 1)",
                            noiDung: "Đến \(d.ten) (\(d.loaiRaw)) • chặng \(Self.dinhDangKhoangCach(route.distance))\(dc)",
                            khoangCachMet: route.distance,
                            laDiemDung: true
                        ))
                    }
                } else {
                    let a = waypoints[idx], b = waypoints[idx + 1]
                    tatCaToaDo.append([a.latitude, a.longitude])
                    tatCaToaDo.append([b.latitude, b.longitude])
                    let seg = CLLocation(latitude: a.latitude, longitude: a.longitude)
                        .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude)) * 1.32
                    tongMet += seg
                    if idx < tuyen.cacDiemMucTieu.count {
                        let d = tuyen.cacDiemMucTieu[idx]
                        buocChiDan.append(BuocChiDanTuyen(
                            stt: buocChiDan.count + 1,
                            hanhDong: "📍 Điểm #\(idx + 1)",
                            noiDung: "Đến \(d.ten) (\(d.loaiRaw)) • ước lượng \(Self.dinhDangKhoangCach(seg))",
                            khoangCachMet: seg,
                            laDiemDung: true
                        ))
                    }
                }
                chayChang(idx: idx + 1)
            }
        }

        chayChang(idx: 0)
    }
}

// MARK: - 3. Bộ Xuất Ảnh Bảng Chi Tiết Khu Vực & Lộ Trình Tuyến (Nét, Chuẩn Sáng, Không Cắt Chữ)

private final class BoXuatAnhBanDo {
    static func taoAnhBangDiaDiem(
        tieuDeNhom: String,
        tenTamQuet: String,
        banKinhMet: Double,
        thoiGianQuet: String,
        danhSach: [DiaDiemQuet],
        mauNhan: UIColor
    ) -> [UIImage] {
        // Chia trang tối đa 38 địa điểm/ảnh để ảnh luôn sắc nét, đọc rõ khi gửi Zalo/LINE
        let kichThuocTrang = 38
        let tongTrang = max(1, Int(ceil(Double(danhSach.count) / Double(kichThuocTrang))))
        var cacAnh: [UIImage] = []

        for trang in 0..<tongTrang {
            let start = trang * kichThuocTrang
            let end = min(danhSach.count, start + kichThuocTrang)
            let latCat = start < end ? Array(danhSach[start..<end]) : []
            if let img = veMotTrangBangDiaDiem(
                tieuDeNhom: tieuDeNhom,
                tenTamQuet: tenTamQuet,
                banKinhMet: banKinhMet,
                thoiGianQuet: thoiGianQuet,
                danhSachTrang: latCat,
                sttBatDau: start + 1,
                tongTatCa: danhSach.count,
                soTrang: trang + 1,
                tongTrang: tongTrang,
                mauNhan: mauNhan
            ) {
                cacAnh.append(img)
            }
        }
        return cacAnh
    }

    private static func veMotTrangBangDiaDiem(
        tieuDeNhom: String,
        tenTamQuet: String,
        banKinhMet: Double,
        thoiGianQuet: String,
        danhSachTrang: [DiaDiemQuet],
        sttBatDau: Int,
        tongTatCa: Int,
        soTrang: Int,
        tongTrang: Int,
        mauNhan: UIColor
    ) -> UIImage? {
        let chieuRong: CGFloat = 860
        let khung = UIView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: chieuRong, height: CGFloat(100)))
        khung.backgroundColor = .white
        khung.overrideUserInterfaceStyle = .light

        let ngan = UIStackView()
        ngan.axis = .vertical
        ngan.spacing = 10
        ngan.translatesAutoresizingMaskIntoConstraints = false
        khung.addSubview(ngan)

        // Banner tiêu đề
        let header = UIView()
        header.backgroundColor = mauNhan
        header.layer.cornerRadius = 14

        let lbTitle = taoLabel(
            text: "📍 DANH SÁCH \(tieuDeNhom.uppercased()) (\(tongTatCa) ĐỊA ĐIỂM)",
            font: .systemFont(ofSize: 22, weight: .heavy),
            color: .white
        )
        let phuTrang = tongTrang > 1 ? " • Trang \(soTrang)/\(tongTrang)" : ""
        let lbSub = taoLabel(
            text: "Tâm quét: \(tenTamQuet) • Bán kính: \(BoDanDuongTuyenThucTe.dinhDangKhoangCach(banKinhMet)) • Cập nhật: \(thoiGianQuet)\(phuTrang)",
            font: .systemFont(ofSize: 14, weight: .semibold),
            color: UIColor.white.withAlphaComponent(0.94)
        )
        let stackHeader = UIStackView(arrangedSubviews: [lbTitle, lbSub])
        stackHeader.axis = .vertical
        stackHeader.spacing = 5
        stackHeader.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(stackHeader)
        NSLayoutConstraint.activate([
            stackHeader.topAnchor.constraint(equalTo: header.topAnchor, constant: 16),
            stackHeader.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 18),
            stackHeader.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -18),
            stackHeader.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -16)
        ])
        ngan.addArrangedSubview(header)

        // Hàng thống kê nhanh
        let soDT = danhSachTrang.filter { $0.loai == .doiThu }.count
        let soMWG = danhSachTrang.filter { $0.loai == .heThongMWG }.count
        let soTH = danhSachTrang.filter { $0.loai == .truongHoc }.count
        let soCho = danhSachTrang.filter { $0.loai == .cho }.count
        let soKhac = danhSachTrang.filter { $0.loai == .khac }.count
        let lbTomTat = taoLabel(
            text: "Trong bảng này: Đối thủ \(soDT) • ĐMX/TGDĐ \(soMWG) • Trường \(soTH) • Chợ \(soCho) • Khác \(soKhac)",
            font: .systemFont(ofSize: 13.5, weight: .bold),
            color: UIColor(red: 0.12, green: 0.24, blue: 0.45, alpha: 1.0)
        )
        let khungTomTat = bocNen(view: lbTomTat, nen: UIColor(red: 0.94, green: 0.97, blue: 1.0, alpha: 1.0), vien: mauNhan.withAlphaComponent(0.3))
        ngan.addArrangedSubview(khungTomTat)

        if danhSachTrang.isEmpty {
            ngan.addArrangedSubview(taoLabel(text: "Không có địa điểm nào trong mục này.", font: .systemFont(ofSize: 15, weight: .medium), color: .darkGray))
        } else {
            for (idx, item) in danhSachTrang.enumerated() {
                let stt = sttBatDau + idx
                let dong = UIView()
                dong.backgroundColor = (idx % 2 == 0) ? UIColor(red: 0.98, green: 0.99, blue: 1.0, alpha: 1.0) : .white
                dong.layer.cornerRadius = 10
                dong.layer.borderWidth = 1
                dong.layer.borderColor = UIColor(white: 0.88, alpha: 1.0).cgColor

                let vach = UIView()
                vach.backgroundColor = item.loai.mauChuDao
                vach.layer.cornerRadius = 2.5
                vach.translatesAutoresizingMaskIntoConstraints = false
                vach.widthAnchor.constraint(equalToConstant: 5).isActive = true

                let lbSTT = taoLabel(text: "#\(stt)", font: .systemFont(ofSize: 14, weight: .heavy), color: item.loai.mauChuDao)
                lbSTT.setContentHuggingPriority(.required, for: .horizontal)
                lbSTT.setContentCompressionResistancePriority(.required, for: .horizontal)
                lbSTT.widthAnchor.constraint(greaterThanOrEqualToConstant: 42).isActive = true

                let lbTen = taoLabel(text: item.ten, font: .systemFont(ofSize: 15.5, weight: .bold), color: UIColor(white: 0.1, alpha: 1.0))
                let kcStr = BoDanDuongTuyenThucTe.dinhDangKhoangCach(item.khoangCachMet)
                let dcStr = item.diaChi.isEmpty ? "" : " • \(item.diaChi)"
                let lbChiTiet = taoLabel(
                    text: "[\(item.loai.tieuDe)] Cách \(kcStr)\(dcStr)",
                    font: .systemFont(ofSize: 13, weight: .medium),
                    color: UIColor(white: 0.35, alpha: 1.0)
                )

                let cot = UIStackView(arrangedSubviews: [lbTen, lbChiTiet])
                cot.axis = .vertical
                cot.spacing = 3

                let hang = UIStackView(arrangedSubviews: [vach, lbSTT, cot])
                hang.axis = .horizontal
                hang.spacing = 10
                hang.alignment = .center
                hang.translatesAutoresizingMaskIntoConstraints = false
                dong.addSubview(hang)

                NSLayoutConstraint.activate([
                    vach.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),
                    hang.topAnchor.constraint(equalTo: dong.topAnchor, constant: 9),
                    hang.leadingAnchor.constraint(equalTo: dong.leadingAnchor, constant: 10),
                    hang.trailingAnchor.constraint(equalTo: dong.trailingAnchor, constant: -12),
                    hang.bottomAnchor.constraint(equalTo: dong.bottomAnchor, constant: -9)
                ])
                ngan.addArrangedSubview(dong)
            }
        }

        NSLayoutConstraint.activate([
            ngan.topAnchor.constraint(equalTo: khung.topAnchor, constant: 18),
            ngan.leadingAnchor.constraint(equalTo: khung.leadingAnchor, constant: 18),
            ngan.trailingAnchor.constraint(equalTo: khung.trailingAnchor, constant: -18),
            ngan.bottomAnchor.constraint(equalTo: khung.bottomAnchor, constant: -18),
            ngan.widthAnchor.constraint(equalToConstant: chieuRong - 36)
        ])

        return renderViewThanhAnh(khung, chieuRong: chieuRong)
    }

    static func taoAnhLoTrinhTuyen(tuyen: TuyenPhatToRoiMaTran) -> UIImage? {
        let chieuRong: CGFloat = 860
        let khung = UIView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: chieuRong, height: CGFloat(100)))
        khung.backgroundColor = .white
        khung.overrideUserInterfaceStyle = .light

        let ngan = UIStackView()
        ngan.axis = .vertical
        ngan.spacing = 10
        ngan.translatesAutoresizingMaskIntoConstraints = false
        khung.addSubview(ngan)

        let header = UIView()
        header.backgroundColor = tuyen.mauTuyen
        header.layer.cornerRadius = 14

        let lbT = taoLabel(text: "🧭 LỘ TRÌNH PHÁT TỜ RƠI — \(tuyen.ten.uppercased())", font: .systemFont(ofSize: 21, weight: .heavy), color: .white)
        let xuatPhat = tuyen.tenDiemXuatPhat.isEmpty ? "Siêu thị (Tâm quét)" : tuyen.tenDiemXuatPhat
        let kmText = BoDanDuongTuyenThucTe.dinhDangKhoangCach(tuyen.tongQuangDuongMet)
        let xmText = BoDanDuongTuyenThucTe.dinhDangPhut(tuyen.thoiGianXeMayPhut)
        let dbText = BoDanDuongTuyenThucTe.dinhDangPhut(tuyen.thoiGianDiBoPhut)
        let lbS = taoLabel(
            text: "🚩 Xuất phát: \(xuatPhat)\n📏 Tổng quãng đường: \(kmText) (\(tuyen.laDuongThucTe ? "bám đường thực tế" : "ước lượng")) • 🛵 Xe máy: ~\(xmText) • 🚶 Đi bộ: ~\(dbText)",
            font: .systemFont(ofSize: 14, weight: .semibold),
            color: UIColor.white.withAlphaComponent(0.95)
        )
        let stH = UIStackView(arrangedSubviews: [lbT, lbS])
        stH.axis = .vertical
        stH.spacing = 6
        stH.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(stH)
        NSLayoutConstraint.activate([
            stH.topAnchor.constraint(equalTo: header.topAnchor, constant: 16),
            stH.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 18),
            stH.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -18),
            stH.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -16)
        ])
        ngan.addArrangedSubview(header)

        if !tuyen.cacDiemMucTieu.isEmpty {
            let tenDiem = tuyen.cacDiemMucTieu.enumerated().map { "\($0.offset + 1). \($0.element.ten) (\($0.element.loaiRaw))" }.joined(separator: "\n")
            let lbDiem = taoLabel(text: "📍 CÁC ĐỊA ĐIỂM ĐI QUA:\n\(tenDiem)", font: .systemFont(ofSize: 14, weight: .semibold), color: UIColor(white: 0.12, alpha: 1.0))
            ngan.addArrangedSubview(bocNen(view: lbDiem, nen: UIColor(red: 0.94, green: 0.98, blue: 0.95, alpha: 1.0), vien: tuyen.mauTuyen.withAlphaComponent(0.35)))
        }

        let lbMucCD = taoLabel(text: "🧭 CHỈ DẪN TỪNG NGÃ RẼ (RẼ TRÁI / RẼ PHẢI):", font: .systemFont(ofSize: 15, weight: .heavy), color: tuyen.mauTuyen)
        ngan.addArrangedSubview(lbMucCD)

        for buoc in tuyen.chiDanTungBuoc {
            let lb = taoLabel(
                text: "\(buoc.stt). \(buoc.hanhDong): \(buoc.noiDung)",
                font: .systemFont(ofSize: buoc.laDiemDung ? 14.5 : 13.5, weight: buoc.laDiemDung ? .bold : .medium),
                color: buoc.laDiemDung ? tuyen.mauTuyen : UIColor(white: 0.15, alpha: 1.0)
            )
            let bg = buoc.laDiemDung ? tuyen.mauTuyen.withAlphaComponent(0.10) : UIColor(white: 0.97, alpha: 1.0)
            ngan.addArrangedSubview(bocNen(view: lb, nen: bg, vien: UIColor(white: 0.88, alpha: 1.0)))
        }

        NSLayoutConstraint.activate([
            ngan.topAnchor.constraint(equalTo: khung.topAnchor, constant: 18),
            ngan.leadingAnchor.constraint(equalTo: khung.leadingAnchor, constant: 18),
            ngan.trailingAnchor.constraint(equalTo: khung.trailingAnchor, constant: -18),
            ngan.bottomAnchor.constraint(equalTo: khung.bottomAnchor, constant: -18),
            ngan.widthAnchor.constraint(equalToConstant: chieuRong - 36)
        ])

        return renderViewThanhAnh(khung, chieuRong: chieuRong)
    }

    private static func taoLabel(text: String, font: UIFont, color: UIColor) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = font
        l.textColor = color
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.adjustsFontSizeToFitWidth = false
        return l
    }

    private static func bocNen(view: UIView, nen: UIColor, vien: UIColor) -> UIView {
        let v = UIView()
        v.backgroundColor = nen
        v.layer.cornerRadius = 10
        v.layer.borderWidth = 1
        v.layer.borderColor = vien.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: v.topAnchor, constant: 10),
            view.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 12),
            view.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -12),
            view.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -10)
        ])
        return v
    }

    private static func renderViewThanhAnh(_ view: UIView, chieuRong: CGFloat) -> UIImage? {
        let targetSize = CGSize(width: chieuRong, height: UIView.layoutFittingCompressedSize.height)
        let size = view.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        let cao = max(CGFloat(120), ceil(size.height))
        view.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: chieuRong, height: cao)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        return view.ketXuatAnhChuanSang(scale: 2.0)
    }
}

// MARK: - 4. Popup Bảng Chi Tiết Khu Vực Đã Quét (Tất cả / Đối thủ / ĐMX / Trường / Chợ / Khác + Xuất Ảnh)

enum BoLocPopupKhuVuc: Int, CaseIterable {
    case tatCa = 0
    case doiThu = 1
    case heThongMWG = 2
    case truongHoc = 3
    case cho = 4
    case khac = 5

    var tieuDe: String {
        switch self {
        case .tatCa: return "Tất cả"
        case .doiThu: return "Đối thủ"
        case .heThongMWG: return "ĐMX/TGDĐ"
        case .truongHoc: return "Trường"
        case .cho: return "Chợ"
        case .khac: return "Khác"
        }
    }

    var tieuDeDayDu: String {
        switch self {
        case .tatCa: return "Tất cả địa điểm khu vực"
        case .doiThu: return "Đối thủ (Điện máy / Gia dụng)"
        case .heThongMWG: return "Cửa hàng ĐMX / TGDĐ"
        case .truongHoc: return "Trường học"
        case .cho: return "Chợ"
        case .khac: return "Khác (Ăn uống, Thời trang, Thú cưng, Tiện ích)"
        }
    }

    var mau: UIColor {
        switch self {
        case .tatCa: return BangMauBCTD.xanhChuDao
        case .doiThu: return LoaiDiaDiemQuet.doiThu.mauChuDao
        case .heThongMWG: return LoaiDiaDiemQuet.heThongMWG.mauChuDao
        case .truongHoc: return LoaiDiaDiemQuet.truongHoc.mauChuDao
        case .cho: return LoaiDiaDiemQuet.cho.mauChuDao
        case .khac: return LoaiDiaDiemQuet.khac.mauChuDao
        }
    }
}

final class HopChiTietKhuVucQuetViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    private let tatCaDiaDiem: [DiaDiemQuet]
    private let tenTamQuet: String
    private let banKinhMet: Double
    private let thoiGianQuet: String
    private var boLocHienTai: BoLocPopupKhuVuc
    private let khiChonDiaDiem: (DiaDiemQuet) -> Void
    private let khiMoGoogleMaps: (DiaDiemQuet) -> Void

    private let cuonTab = UIScrollView()
    private let nganTab = UIStackView()
    private let oTimKiem = UITextField()
    private let nutXuatAnh = UIButton(type: .system)
    private let nhanTomTat = UILabel()
    private let bang = UITableView(frame: .zero, style: .insetGrouped)

    private var dsHienThi: [DiaDiemQuet] = []

    init(
        tatCaDiaDiem: [DiaDiemQuet],
        tenTamQuet: String,
        banKinhMet: Double,
        thoiGianQuet: String,
        boLocMacDinh: BoLocPopupKhuVuc,
        khiChonDiaDiem: @escaping (DiaDiemQuet) -> Void,
        khiMoGoogleMaps: @escaping (DiaDiemQuet) -> Void
    ) {
        self.tatCaDiaDiem = tatCaDiaDiem
        self.tenTamQuet = tenTamQuet
        self.banKinhMet = banKinhMet
        self.thoiGianQuet = thoiGianQuet
        self.boLocHienTai = boLocMacDinh
        self.khiChonDiaDiem = khiChonDiaDiem
        self.khiMoGoogleMaps = khiMoGoogleMaps
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Khong ho tro coder") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "📍 Chi tiết khu vực (\(tatCaDiaDiem.count))"
        view.backgroundColor = BangMauBCTD.nenTrang
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Đóng", style: .done, target: self, action: #selector(bamDong))
        dungGiaoDien()
        capNhatDanhSachLoc()
    }

    @objc private func bamDong() { dismiss(animated: true) }

    private func dungGiaoDien() {
        let khungTren = UIView()
        khungTren.backgroundColor = BangMauBCTD.nenThe
        khungTren.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(khungTren)

        cuonTab.showsHorizontalScrollIndicator = false
        cuonTab.translatesAutoresizingMaskIntoConstraints = false
        cuonTab.heightAnchor.constraint(equalToConstant: 36).isActive = true

        nganTab.axis = .horizontal
        nganTab.spacing = 6
        nganTab.alignment = .center
        nganTab.translatesAutoresizingMaskIntoConstraints = false
        cuonTab.addSubview(nganTab)
        NSLayoutConstraint.activate([
            nganTab.topAnchor.constraint(equalTo: cuonTab.contentLayoutGuide.topAnchor),
            nganTab.bottomAnchor.constraint(equalTo: cuonTab.contentLayoutGuide.bottomAnchor),
            nganTab.leadingAnchor.constraint(equalTo: cuonTab.contentLayoutGuide.leadingAnchor),
            nganTab.trailingAnchor.constraint(equalTo: cuonTab.contentLayoutGuide.trailingAnchor),
            nganTab.heightAnchor.constraint(equalTo: cuonTab.frameLayoutGuide.heightAnchor)
        ])

        oTimKiem.placeholder = "Tìm tên địa điểm, quán ăn, shop, trường, chợ..."
        oTimKiem.font = .systemFont(ofSize: 13.5)
        oTimKiem.textColor = BangMauBCTD.chuChinh
        oTimKiem.backgroundColor = BangMauBCTD.nenThePhu
        oTimKiem.layer.cornerRadius = 9
        oTimKiem.layer.borderWidth = 1
        oTimKiem.layer.borderColor = BangMauBCTD.vienDam.cgColor
        oTimKiem.clearButtonMode = .whileEditing
        oTimKiem.returnKeyType = .done
        oTimKiem.delegate = self
        oTimKiem.leftView = UIView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(10), height: CGFloat(10)))
        oTimKiem.leftViewMode = .always
        oTimKiem.heightAnchor.constraint(equalToConstant: 38).isActive = true
        oTimKiem.addTarget(self, action: #selector(khiSuaTimKiem), for: .editingChanged)

        nutXuatAnh.titleLabel?.font = .systemFont(ofSize: 13, weight: .heavy)
        nutXuatAnh.titleLabel?.numberOfLines = 0
        nutXuatAnh.titleLabel?.lineBreakMode = .byWordWrapping
        nutXuatAnh.titleLabel?.adjustsFontSizeToFitWidth = false
        nutXuatAnh.setTitleColor(.white, for: .normal)
        nutXuatAnh.layer.cornerRadius = 9
        nutXuatAnh.contentEdgeInsets = UIEdgeInsets(top: 9, left: 12, bottom: 9, right: 12)
        nutXuatAnh.addTarget(self, action: #selector(bamXuatAnhNhomHienTai), for: .touchUpInside)

        nhanTomTat.font = .systemFont(ofSize: 12, weight: .semibold)
        nhanTomTat.textColor = BangMauBCTD.chuPhu
        nhanTomTat.numberOfLines = 0
        nhanTomTat.lineBreakMode = .byWordWrapping
        nhanTomTat.adjustsFontSizeToFitWidth = false

        let stackTren = UIStackView(arrangedSubviews: [cuonTab, oTimKiem, nutXuatAnh, nhanTomTat])
        stackTren.axis = .vertical
        stackTren.spacing = 8
        stackTren.translatesAutoresizingMaskIntoConstraints = false
        khungTren.addSubview(stackTren)

        bang.dataSource = self
        bang.delegate = self
        bang.keyboardDismissMode = .onDrag
        bang.rowHeight = UITableView.automaticDimension
        bang.estimatedRowHeight = 76
        bang.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bang)

        NSLayoutConstraint.activate([
            khungTren.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            khungTren.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            khungTren.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            stackTren.topAnchor.constraint(equalTo: khungTren.topAnchor, constant: 10),
            stackTren.leadingAnchor.constraint(equalTo: khungTren.leadingAnchor, constant: 12),
            stackTren.trailingAnchor.constraint(equalTo: khungTren.trailingAnchor, constant: -12),
            stackTren.bottomAnchor.constraint(equalTo: khungTren.bottomAnchor, constant: -10),

            bang.topAnchor.constraint(equalTo: khungTren.bottomAnchor),
            bang.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bang.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bang.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func demSoLuong(_ loc: BoLocPopupKhuVuc) -> Int {
        switch loc {
        case .tatCa: return tatCaDiaDiem.count
        case .doiThu: return tatCaDiaDiem.filter { $0.loai == .doiThu }.count
        case .heThongMWG: return tatCaDiaDiem.filter { $0.loai == .heThongMWG }.count
        case .truongHoc: return tatCaDiaDiem.filter { $0.loai == .truongHoc }.count
        case .cho: return tatCaDiaDiem.filter { $0.loai == .cho }.count
        case .khac: return tatCaDiaDiem.filter { $0.loai == .khac }.count
        }
    }

    private func veLaiThanhTab() {
        nganTab.arrangedSubviews.forEach { nganTab.removeArrangedSubview($0); $0.removeFromSuperview() }
        for loc in BoLocPopupKhuVuc.allCases {
            let dangChon = (loc == boLocHienTai)
            let btn = UIButton(type: .system)
            btn.tag = loc.rawValue
            btn.setTitle("\(loc.tieuDe) (\(demSoLuong(loc)))", for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 12.5, weight: dangChon ? .heavy : .semibold)
            btn.setTitleColor(dangChon ? .white : loc.mau, for: .normal)
            btn.backgroundColor = dangChon ? loc.mau : BangMauBCTD.nenThePhu
            btn.layer.cornerRadius = 9
            btn.layer.borderWidth = 1.2
            btn.layer.borderColor = loc.mau.withAlphaComponent(dangChon ? 1.0 : 0.4).cgColor
            btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 11, bottom: 6, right: 11)
            btn.addTarget(self, action: #selector(bamChonTab(_:)), for: .touchUpInside)
            nganTab.addArrangedSubview(btn)
        }
    }

    @objc private func bamChonTab(_ sender: UIButton) {
        boLocHienTai = BoLocPopupKhuVuc(rawValue: sender.tag) ?? .tatCa
        capNhatDanhSachLoc()
    }

    @objc private func khiSuaTimKiem() {
        capNhatDanhSachLoc()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private func capNhatDanhSachLoc() {
        veLaiThanhTab()

        let theoNhom: [DiaDiemQuet]
        switch boLocHienTai {
        case .tatCa: theoNhom = tatCaDiaDiem
        case .doiThu: theoNhom = tatCaDiaDiem.filter { $0.loai == .doiThu }
        case .heThongMWG: theoNhom = tatCaDiaDiem.filter { $0.loai == .heThongMWG }
        case .truongHoc: theoNhom = tatCaDiaDiem.filter { $0.loai == .truongHoc }
        case .cho: theoNhom = tatCaDiaDiem.filter { $0.loai == .cho }
        case .khac: theoNhom = tatCaDiaDiem.filter { $0.loai == .khac }
        }

        let tuKhoa = BoPhanTichLichCaExcel.chuanHoa(oTimKiem.text ?? "")
        if tuKhoa.isEmpty {
            dsHienThi = theoNhom
        } else {
            dsHienThi = theoNhom.filter {
                BoPhanTichLichCaExcel.chuanHoa($0.ten).contains(tuKhoa)
                || BoPhanTichLichCaExcel.chuanHoa($0.diaChi).contains(tuKhoa)
                || BoPhanTichLichCaExcel.chuanHoa($0.loai.tieuDe).contains(tuKhoa)
            }
        }

        nutXuatAnh.backgroundColor = boLocHienTai.mau
        nutXuatAnh.setTitle("📸 Xuất ảnh: \(boLocHienTai.tieuDe) (\(dsHienThi.count) địa điểm)", for: .normal)
        nhanTomTat.text = "• \(boLocHienTai.tieuDeDayDu) • Bán kính quét \(BoDanDuongTuyenThucTe.dinhDangKhoangCach(banKinhMet)) • Cập nhật: \(thoiGianQuet)"
        bang.reloadData()
    }

    @objc private func bamXuatAnhNhomHienTai() {
        view.endEditing(true)
        guard !dsHienThi.isEmpty else {
            let ac = UIAlertController(title: "Chưa có địa điểm", message: "Không có địa điểm nào trong mục \"\(boLocHienTai.tieuDe)\" để xuất ảnh.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Đóng", style: .default))
            present(ac, animated: true)
            return
        }

        let cacAnh = BoXuatAnhBanDo.taoAnhBangDiaDiem(
            tieuDeNhom: boLocHienTai.tieuDe,
            tenTamQuet: tenTamQuet,
            banKinhMet: banKinhMet,
            thoiGianQuet: thoiGianQuet,
            danhSach: dsHienThi,
            mauNhan: boLocHienTai.mau
        )
        guard !cacAnh.isEmpty else { return }
        let hd = UIActivityViewController(activityItems: cacAnh, applicationActivities: nil)
        if let pop = hd.popoverPresentationController {
            pop.sourceView = nutXuatAnh
            pop.sourceRect = nutXuatAnh.bounds
        }
        present(hd, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, dsHienThi.count)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "CellChiTietKhuVuc"
        let cell = tableView.dequeueReusableCell(withIdentifier: id)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: id)

        if dsHienThi.isEmpty {
            cell.textLabel?.text = "Không có địa điểm nào trong mục này."
            cell.textLabel?.font = .systemFont(ofSize: 13.5, weight: .medium)
            cell.textLabel?.textColor = BangMauBCTD.chuMo
            cell.textLabel?.numberOfLines = 0
            cell.detailTextLabel?.text = nil
            cell.accessoryView = nil
            cell.selectionStyle = .none
            return cell
        }

        let item = dsHienThi[indexPath.row]
        let kcStr = BoDanDuongTuyenThucTe.dinhDangKhoangCach(item.khoangCachMet)
        cell.textLabel?.text = "#\(indexPath.row + 1)  \(item.ten)"
        cell.textLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        cell.textLabel?.textColor = BangMauBCTD.chuChinh
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.adjustsFontSizeToFitWidth = false

        let dc = item.diaChi.isEmpty ? "" : " • \(item.diaChi)"
        cell.detailTextLabel?.text = "\(item.loai.tieuDe) • Cách \(kcStr)\(dc)"
        cell.detailTextLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        cell.detailTextLabel?.textColor = item.loai.mauChuDao
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.lineBreakMode = .byWordWrapping
        cell.detailTextLabel?.adjustsFontSizeToFitWidth = false

        let nutGG = UIButton(type: .system)
        nutGG.setTitle("GG Map", for: .normal)
        nutGG.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutGG.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
        nutGG.backgroundColor = BangMauBCTD.nenHeaderPhu
        nutGG.layer.cornerRadius = 7
        nutGG.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        nutGG.sizeToFit()
        nutGG.addAction(UIAction { [weak self] _ in
            self?.khiMoGoogleMaps(item)
        }, for: .touchUpInside)
        cell.accessoryView = nutGG
        cell.selectionStyle = .default
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < dsHienThi.count else { return }
        let chon = dsHienThi[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.khiChonDiaDiem(chon)
        }
    }
}

// MARK: - 5. Popup Chi Tiết Lộ Trình Tuyến (Xuất Phát, Đi Qua, Rẽ Trái/Phải, Xe Máy / Đi Bộ, Xuất Ảnh)

final class HopChiTietTuyenDuongViewController: UIViewController {
    private var tuyen: TuyenPhatToRoiMaTran
    private let khiMoGoogleMaps: (TuyenPhatToRoiMaTran) -> Void
    private let khiCapNhatTuyen: (TuyenPhatToRoiMaTran) -> Void

    private let cuon = UIScrollView()
    private let ngan = UIStackView()
    private let chonPhuongTien = UISegmentedControl(items: ["🛵 Xe máy", "🚶 Đi bộ"])
    private let nhanThoiGianChiTiet = UILabel()
    private let vongQuayDuong = UIActivityIndicatorView(style: .medium)
    private let nganBuocChiDan = UIStackView()

    init(
        tuyen: TuyenPhatToRoiMaTran,
        khiMoGoogleMaps: @escaping (TuyenPhatToRoiMaTran) -> Void,
        khiCapNhatTuyen: @escaping (TuyenPhatToRoiMaTran) -> Void
    ) {
        self.tuyen = tuyen
        self.khiMoGoogleMaps = khiMoGoogleMaps
        self.khiCapNhatTuyen = khiCapNhatTuyen
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Khong ho tro coder") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "🧭 \(tuyen.ten)"
        view.backgroundColor = BangMauBCTD.nenTrang
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Đóng", style: .done, target: self, action: #selector(bamDong))
        dungGiaoDien()
        capNhatNoiDung()

        // Nếu tuyến chưa kịp bám đường thực tế, tự động gọi bám đường ngay khi mở popup
        if !tuyen.laDuongThucTe && tuyen.cacToaDo.count >= 2 {
            vongQuayDuong.startAnimating()
            BoDanDuongTuyenThucTe.dungChung.tinhDuongThucTeChoMotTuyen(
                tuyen: tuyen,
                tenDiemXuatPhat: tuyen.tenDiemXuatPhat
            ) { [weak self] moi in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.vongQuayDuong.stopAnimating()
                    self.tuyen = moi
                    self.capNhatNoiDung()
                    self.khiCapNhatTuyen(moi)
                }
            }
        }
    }

    @objc private func bamDong() { dismiss(animated: true) }

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

        // 1. Thẻ tổng quan lộ trình + chọn Xe máy / Đi bộ
        let (theTongQuan, stackTQ) = taoThe(tieuDe: "🛣️ TỔNG QUAN LỘ TRÌNH")
        chonPhuongTien.selectedSegmentIndex = 0
        chonPhuongTien.addTarget(self, action: #selector(doiPhuongTien), for: .valueChanged)
        stackTQ.addArrangedSubview(chonPhuongTien)

        vongQuayDuong.hidesWhenStopped = true
        nhanThoiGianChiTiet.font = .systemFont(ofSize: 13, weight: .semibold)
        nhanThoiGianChiTiet.textColor = BangMauBCTD.chuChinh
        nhanThoiGianChiTiet.numberOfLines = 0
        nhanThoiGianChiTiet.lineBreakMode = .byWordWrapping
        nhanThoiGianChiTiet.adjustsFontSizeToFitWidth = false

        let hangTrangThai = UIStackView(arrangedSubviews: [vongQuayDuong, nhanThoiGianChiTiet])
        hangTrangThai.axis = .horizontal
        hangTrangThai.spacing = 8
        hangTrangThai.alignment = .top
        stackTQ.addArrangedSubview(hangTrangThai)

        let nutGG = taoNut(tieuDe: "🗺️ Dẫn đường GG Maps", mauNen: tuyen.mauTuyen, mauChu: .white)
        nutGG.addTarget(self, action: #selector(bamMoGoogleMaps), for: .touchUpInside)

        let nutCopy = taoNut(tieuDe: "📋 Copy lộ trình", mauNen: BangMauBCTD.nenHeaderPhu, mauChu: BangMauBCTD.xanhChuDaoDam, coVien: true)
        nutCopy.addTarget(self, action: #selector(bamCopyLoTrinh), for: .touchUpInside)

        let nutAnh = taoNut(tieuDe: "📸 Xuất ảnh lộ trình", mauNen: BangMauBCTD.xanhLaDam, mauChu: .white)
        nutAnh.addTarget(self, action: #selector(bamXuatAnhLoTrinh), for: .touchUpInside)

        let hangNut1 = UIStackView(arrangedSubviews: [nutGG, nutCopy])
        hangNut1.axis = .horizontal
        hangNut1.spacing = 8
        hangNut1.distribution = .fillEqually
        stackTQ.addArrangedSubview(hangNut1)
        stackTQ.addArrangedSubview(nutAnh)
        ngan.addArrangedSubview(theTongQuan)

        // 2. Thẻ danh sách địa điểm đi qua
        if !tuyen.cacDiemMucTieu.isEmpty {
            let (theDiem, stackDiem) = taoThe(tieuDe: "📍 ĐI QUA \(tuyen.cacDiemMucTieu.count) ĐỊA ĐIỂM (THEO THỨ TỰ)")
            for (idx, d) in tuyen.cacDiemMucTieu.enumerated() {
                let dc = d.diaChi.isEmpty ? "" : "\n   \(d.diaChi)"
                let lb = taoNhan("\(idx + 1). \(d.ten) [\(d.loaiRaw)]\(dc)", dam: false)
                stackDiem.addArrangedSubview(lb)
            }
            ngan.addArrangedSubview(theDiem)
        }

        // 3. Thẻ chỉ dẫn chi tiết từng bước rẽ trái / rẽ phải
        let (theBuoc, stackBuoc) = taoThe(tieuDe: "🧭 CHỈ DẪN CHI TIẾT (RẼ TRÁI / RẼ PHẢI / ĐI THẲNG)")
        nganBuocChiDan.axis = .vertical
        nganBuocChiDan.spacing = 7
        stackBuoc.addArrangedSubview(nganBuocChiDan)
        ngan.addArrangedSubview(theBuoc)
    }

    @objc private func doiPhuongTien() {
        capNhatNhanThoiGian()
    }

    private func capNhatNoiDung() {
        capNhatNhanThoiGian()
        nganBuocChiDan.arrangedSubviews.forEach { nganBuocChiDan.removeArrangedSubview($0); $0.removeFromSuperview() }

        if tuyen.chiDanTungBuoc.isEmpty {
            nganBuocChiDan.addArrangedSubview(taoNhan("Chưa có dữ liệu chỉ dẫn chi tiết cho tuyến này.", dam: false))
            return
        }

        for buoc in tuyen.chiDanTungBuoc {
            let the = UIView()
            the.backgroundColor = buoc.laDiemDung ? tuyen.mauTuyen.withAlphaComponent(0.11) : BangMauBCTD.nenThePhu
            the.layer.cornerRadius = 9
            the.layer.borderWidth = 1
            the.layer.borderColor = (buoc.laDiemDung ? tuyen.mauTuyen.withAlphaComponent(0.45) : BangMauBCTD.vienThe).cgColor

            let lb = taoNhan("\(buoc.stt). \(buoc.hanhDong): \(buoc.noiDung)", dam: buoc.laDiemDung)
            if buoc.laDiemDung { lb.textColor = tuyen.mauTuyen }
            lb.translatesAutoresizingMaskIntoConstraints = false
            the.addSubview(lb)
            NSLayoutConstraint.activate([
                lb.topAnchor.constraint(equalTo: the.topAnchor, constant: 8),
                lb.leadingAnchor.constraint(equalTo: the.leadingAnchor, constant: 10),
                lb.trailingAnchor.constraint(equalTo: the.trailingAnchor, constant: -10),
                lb.bottomAnchor.constraint(equalTo: the.bottomAnchor, constant: -8)
            ])
            nganBuocChiDan.addArrangedSubview(the)
        }
    }

    private func capNhatNhanThoiGian() {
        let xuatPhat = tuyen.tenDiemXuatPhat.isEmpty ? "Siêu thị (Tâm quét)" : tuyen.tenDiemXuatPhat
        let km = BoDanDuongTuyenThucTe.dinhDangKhoangCach(tuyen.tongQuangDuongMet)
        let xm = BoDanDuongTuyenThucTe.dinhDangPhut(tuyen.thoiGianXeMayPhut)
        let db = BoDanDuongTuyenThucTe.dinhDangPhut(tuyen.thoiGianDiBoPhut)
        let phutDungPhat = max(5, tuyen.cacDiemMucTieu.count * 5)
        let dangXeMay = (chonPhuongTien.selectedSegmentIndex == 0)
        let tongDuKien = BoDanDuongTuyenThucTe.dinhDangPhut((dangXeMay ? tuyen.thoiGianXeMayPhut : tuyen.thoiGianDiBoPhut) + phutDungPhat)
        let cheDo = tuyen.laDuongThucTe ? "✅ Bám sát đường thực tế trên bản đồ" : "⏳ Đang đồng bộ đường thực tế..."

        nhanThoiGianChiTiet.text = """
        🚩 Xuất phát từ: \(xuatPhat)
        📏 Quãng đường: \(km) (\(cheDo))
        🛵 Di chuyển xe máy: ~\(xm)  |  🚶 Đi bộ: ~\(db)
        ⏱️ Dự kiến cả đi & dừng phát (\(tuyen.cacDiemMucTieu.count) điểm, ~5p/điểm): ~\(tongDuKien) (\(dangXeMay ? "bằng Xe máy" : "Đi bộ"))
        """
    }

    @objc private func bamMoGoogleMaps() {
        khiMoGoogleMaps(tuyen)
    }

    @objc private func bamCopyLoTrinh() {
        let xuatPhat = tuyen.tenDiemXuatPhat.isEmpty ? "Siêu thị" : tuyen.tenDiemXuatPhat
        var lines: [String] = [
            "🧭 LỘ TRÌNH PHÁT TỜ RƠI — \(tuyen.ten)",
            "• Xuất phát: \(xuatPhat)",
            "• Tổng quãng đường: \(BoDanDuongTuyenThucTe.dinhDangKhoangCach(tuyen.tongQuangDuongMet))",
            "• Thời gian di chuyển: 🛵 Xe máy ~\(BoDanDuongTuyenThucTe.dinhDangPhut(tuyen.thoiGianXeMayPhut)) | 🚶 Đi bộ ~\(BoDanDuongTuyenThucTe.dinhDangPhut(tuyen.thoiGianDiBoPhut))",
            ""
        ]
        if !tuyen.cacDiemMucTieu.isEmpty {
            lines.append("📍 CÁC ĐỊA ĐIỂM ĐI QUA:")
            for (i, d) in tuyen.cacDiemMucTieu.enumerated() {
                lines.append("\(i + 1). \(d.ten) (\(d.loaiRaw))")
            }
            lines.append("")
        }
        lines.append("🧭 CHỈ DẪN TỪNG BƯỚC:")
        for b in tuyen.chiDanTungBuoc {
            lines.append("\(b.stt). \(b.hanhDong): \(b.noiDung)")
        }
        UIPasteboard.general.string = lines.joined(separator: "\n")
        let ac = UIAlertController(title: "Đã sao chép", message: "Đã sao chép chi tiết lộ trình rẽ trái/rẽ phải & thời gian xe máy/đi bộ.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Đóng", style: .default))
        present(ac, animated: true)
    }

    @objc private func bamXuatAnhLoTrinh() {
        guard let anh = BoXuatAnhBanDo.taoAnhLoTrinhTuyen(tuyen: tuyen) else { return }
        let hd = UIActivityViewController(activityItems: [anh], applicationActivities: nil)
        if let pop = hd.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: CGFloat(1), height: CGFloat(1))
        }
        present(hd, animated: true)
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

    private func taoNhan(_ text: String, dam: Bool) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: dam ? 13.5 : 12.5, weight: dam ? .bold : .regular)
        l.textColor = BangMauBCTD.chuChinh
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.adjustsFontSizeToFitWidth = false
        return l
    }

    private func taoNut(tieuDe: String, mauNen: UIColor, mauChu: UIColor, coVien: Bool = false) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(tieuDe, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        b.titleLabel?.numberOfLines = 0
        b.titleLabel?.lineBreakMode = .byWordWrapping
        b.titleLabel?.adjustsFontSizeToFitWidth = false
        b.backgroundColor = mauNen
        b.setTitleColor(mauChu, for: .normal)
        b.layer.cornerRadius = 9
        if coVien {
            b.layer.borderWidth = 1
            b.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
        }
        b.contentEdgeInsets = UIEdgeInsets(top: 9, left: 10, bottom: 9, right: 10)
        return b
    }
}
