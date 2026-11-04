import UIKit

// MARK: - Khung bản tin & giọng văn

/// 3 khung bản tin trong ngày: Đầu ca (tới 9h) · Hiện tại (9h–19h) · Kết ca (sau 19h)
enum KhungBanTin: Int, CaseIterable {
    case dauCa = 0
    case hienTai = 1
    case ketCa = 2

    var tieuDe: String {
        switch self {
        case .dauCa: return "☀️ Đầu ca"
        case .hienTai: return "⏱ Hiện tại"
        case .ketCa: return "🌙 Kết ca"
        }
    }

    var tenNgan: String {
        switch self {
        case .dauCa: return "ĐẦU CA"
        case .hienTai: return "HIỆN TẠI"
        case .ketCa: return "KẾT CA"
        }
    }

    /// Tự chọn khung theo giờ hiện tại: tới 9h = Đầu ca, 9h–19h = Hiện tại, sau 19h = Kết ca
    static func theoGio(_ luc: Date = Date()) -> KhungBanTin {
        let gio = TienIchNgay.lich.component(.hour, from: luc)
        if gio < 9 { return .dauCa }
        if gio < 19 { return .hienTai }
        return .ketCa
    }
}

enum GiongVanBanTin: Int, CaseIterable {
    case binhThuong = 0
    case cangThang = 1
    case thaoMai = 2

    var tieuDe: String {
        switch self {
        case .binhThuong: return "Bình thường"
        case .cangThang: return "Căng thẳng"
        case .thaoMai: return "Thảo mai"
        }
    }
}

// MARK: - Bộ số liệu dùng để viết bản tin

struct SoLieuBanTin {
    var ngay: Date
    var khung: KhungBanTin
    var tenDonVi: String
    var capNhatLuc: String
    var luyKe: ThongTinDoanhThu
    var dsLuyKe: [DongThiDua]
    var homNay: ThongTinDoanhThu
    var dsHomNay: [DongThiDua]
    var nhanVien: [TongHopNhanVien]
    var homNayNV: [DoanhThuNhanVienItem]
    /// true = số Lũy kế đầu ca hôm nay chưa có, đang tính tạm từ (Lũy kế hôm qua + Realtime kết ca hôm qua)
    var tamTinh: Bool
    var soNgayTrongThang: Int
    var ngayTrongThang: Int

    /// Số ngày còn lại để chạy tới cuối tháng (đầu ca / hiện tại: tính cả hôm nay; kết ca: không tính hôm nay)
    var soNgayConLai: Int {
        let con = (khung == .ketCa) ? (soNgayTrongThang - ngayTrongThang) : (soNgayTrongThang - ngayTrongThang + 1)
        return max(1, con)
    }

    var coSoLieuLuyKe: Bool {
        luyKe.coDuLieu || !dsLuyKe.isEmpty
    }

    var coSoLieuHomNay: Bool {
        homNay.coDuLieu || !dsHomNay.isEmpty
    }
}

extension KhoDuLieu {
    /// Gom số liệu cho bản tin. Đầu ca chưa có số hôm nay → tự dựng "Đầu ca tạm tính".
    func taoSoLieuBanTin(cho ngay: Date, khung: KhungBanTin) -> SoLieuBanTin {
        let lich = TienIchNgay.lich
        let dl = duLieu(cho: ngay)
        let soNgay = soNgayTrongThang(cho: ngay)
        let ngayTrongThang = lich.component(.day, from: ngay)

        var luyKe = dl.doanhThu
        var dsLuyKe = danhSachMatHangThang(den: ngay, cheDo: .luyKe)
        var tamTinh = false

        if khung == .dauCa, ngayTrongThang > 1, lich.isDateInToday(ngay) {
            let khoaHomNay = TienIchNgay.khoa.string(from: ngay)
            let homNay = cacNgay[khoaHomNay]
            let homNayDaCo = (homNay?.doanhThu.coDuLieu ?? false) || !(homNay?.danhSachThiDua.isEmpty ?? true)
            if !homNayDaCo, let homQua = lich.date(byAdding: .day, value: -1, to: ngay) {
                let khoaQua = TienIchNgay.khoa.string(from: homQua)
                if let q = cacNgay[khoaQua], q.doanhThu.coDuLieu, q.doanhThuRealtime.coDuLieu {
                    let daQua = Double(max(1, ngayTrongThang - 1))
                    let tong = Double(soNgay)

                    var lk = q.doanhThu
                    lk.doanhThuThuc += q.doanhThuRealtime.doanhThuThuc
                    lk.doanhThuQuyDoi += q.doanhThuRealtime.doanhThuQuyDoi
                    if lk.phanTramHTThuc > 0, lk.targetThuc > 0 {
                        lk.phanTramHTThuc = lk.doanhThuThuc / lk.targetThuc * 100.0
                    }
                    lk.duKienThuc = lk.doanhThuThuc / daQua * tong
                    lk.duKienQuyDoi = lk.doanhThuQuyDoi / daQua * tong
                    if lk.targetQuyDoi > 0 {
                        lk.phanTramHTQuyDoi = lk.duKienQuyDoi / lk.targetQuyDoi * 100.0
                    }
                    lk.soNgayDaQua = Int(daQua)
                    lk.tongSoNgay = soNgay
                    lk.phanTramTienDoThang = daQua / tong * 100.0

                    var dsTam: [DongThiDua] = []
                    for d in q.danhSachThiDua {
                        let khoa = KhoDuLieu.chuanHoaKhoaSoSanh(d.tenNganhHang)
                        var them: Double = 0
                        for r in q.danhSachThiDuaRealtime where KhoDuLieu.chuanHoaKhoaSoSanh(r.tenNganhHang) == khoa {
                            them = r.thucHien
                            break
                        }
                        let thucHien = d.thucHien + them
                        let duKien = thucHien / daQua * tong
                        let phanTramHT: Double? = d.target > 0 ? (thucHien / d.target * 100.0) : nil
                        let phanTramDuBao: Double? = d.target > 0 ? (duKien / d.target * 100.0) : nil
                        let dong = DongThiDua(
                            tenNganhHangGoc: d.tenNganhHangGoc,
                            tenNganhHang: d.tenNganhHang,
                            loaiChiTieu: d.loaiChiTieu,
                            thucHien: thucHien,
                            target: d.target,
                            phanTramHTGoc: phanTramHT,
                            phanTramDuBaoGoc: phanTramDuBao,
                            duKienGoc: duKien
                        )
                        dsTam.append(dong)
                    }
                    luyKe = lk
                    dsLuyKe = dsTam
                    tamTinh = true
                }
            }
        }

        return SoLieuBanTin(
            ngay: ngay,
            khung: khung,
            tenDonVi: dl.thongTinDonVi,
            capNhatLuc: dl.capNhatLuc,
            luyKe: luyKe,
            dsLuyKe: dsLuyKe,
            homNay: dl.doanhThuRealtime,
            dsHomNay: dl.danhSachThiDuaRealtime,
            nhanVien: tongHopNhanVien(den: ngay, sapXep: .soMonHoanThanh, cheDo: .luyKe),
            homNayNV: dl.doanhThuNhanVienRealtime,
            tamTinh: tamTinh,
            soNgayTrongThang: soNgay,
            ngayTrongThang: ngayTrongThang
        )
    }
}

// MARK: - Bộ sinh số ngẫu nhiên theo hạt giống (cùng số + cùng ngày → cùng bài, không đổi mỗi lần mở)

struct BoSinhNgauNhien: RandomNumberGenerator {
    private var trangThai: UInt64

    init(hatGiong: String) {
        var h: UInt64 = 1469598103934665603
        for byte in hatGiong.utf8 {
            h ^= UInt64(byte)
            h = h &* 1099511628211
        }
        trangThai = h
    }

    mutating func next() -> UInt64 {
        trangThai = trangThai &+ 0x9E3779B97F4A7C15
        var z = trangThai
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

// MARK: - Bộ viết bài Phân tích (mẫu câu theo số liệu, không dùng AI ngoài, chạy offline)

final class BoVietBanTin {
    private var rng: BoSinhNgauNhien
    private let s: SoLieuBanTin
    private let giong: GiongVanBanTin

    private struct LoiDan {
        var mo: String
        var viec: String
        var duoiTapTrung: String
        var ket: String
    }

    /// Việc cụ thể theo nhóm hàng: (từ khóa, việc làm)
    private static let bangViec: [([String], String)] = [
        (["sim"], "mời 100% khách mua máy lấy sim, để sẵn bộ sim + bảng giá gói cước ngay quầy thu ngân"),
        (["bao hiem"], "chào bảo hiểm cho mọi đơn máy từ 3 triệu, nói rõ quyền lợi rơi vỡ – vào nước trong 1 câu"),
        (["phu kien", "cap", "sac", "tai nghe", "op", "dan"], "giao máy là đưa combo phụ kiện ra bàn: ốp + dán + sạc, báo giá combo thay vì từng món"),
        (["tra cham", "tra gop", "vay", "the tin dung", "vi tra sau", "homecredit", "fecredit"], "khách chê giá hoặc phân vân thì mời ngay trả chậm 0%, tính sẵn số tiền mỗi tháng để khách dễ gật"),
        (["laptop", "tablet", "dong ho", "camera", "may doc sach"], "mời khách trải nghiệm máy trưng bày, demo tính năng chính trong 2 phút"),
        (["iphone"], "chủ động gợi ý đổi máy cũ lên iPhone, báo giá thu cũ ngay tại quầy"),
        (["vas", "nap", "rut", "tai khoan"], "mời khách nạp/rút tiền, mở tài khoản ngay lúc chờ thanh toán"),
        (["dien thoai"], "đón khách ở khu điện thoại, so sánh 2 mẫu cùng tầm giá để khách chốt nhanh")
    ]

    init(soLieu: SoLieuBanTin, giong: GiongVanBanTin, bienThe: Int = 0) {
        self.s = soLieu
        self.giong = giong
        let khoa = TienIchNgay.khoa.string(from: soLieu.ngay)
        self.rng = BoSinhNgauNhien(hatGiong: "\(khoa)|\(soLieu.khung.rawValue)|\(giong.rawValue)|\(soLieu.tenDonVi)|\(bienThe)")
    }

    func viet() -> String {
        switch s.khung {
        case .dauCa: return vietDauCa()
        case .hienTai: return vietHienTai()
        case .ketCa: return vietKetCa()
        }
    }

    // MARK: Tiện ích

    private func chon(_ cacMau: [String]) -> String {
        cacMau.randomElement(using: &rng) ?? ""
    }

    private func ten(_ hoTen: String) -> String {
        hoTen.split(separator: " ").last.map { String($0) } ?? hoTen
    }

    private func vietHoaDau(_ chu: String) -> String {
        guard let dau = chu.first else { return chu }
        return String(dau).uppercased() + chu.dropFirst()
    }

    private func khongDau(_ chu: String) -> String {
        KhoDuLieu.chuanHoaKhoaSoSanh(chu).lowercased()
    }

    private func hanhDong(cho nhom: String) -> String {
        let g = " " + khongDau(nhom) + " "
        for (cacKhoa, viec) in Self.bangViec {
            for khoa in cacKhoa {
                let trung = khoa.count <= 3 ? g.contains(" " + khoa + " ") : g.contains(khoa)
                if trung { return viec }
            }
        }
        return "đưa \(nhom) vào lời chào đầu tiên với mỗi khách, mục tiêu ít nhất 1 đơn trong ca"
    }

    private func loiDan() -> LoiDan {
        switch giong {
        case .cangThang:
            return LoiDan(
                mo: chon(["Anh chị em chú ý, nói ngắn gọn:", "Tình hình cần xử lý ngay, mọi người đọc kỹ:"]),
                viec: "✔ YÊU CẦU (làm ngay, cuối ca QL kiểm tra):",
                duoiTapTrung: " — chưa có số trước 15h thì báo lại QL lý do.",
                ket: chon(["Không có lý do cho việc để môn bằng 0. Cuối ca mình chốt số với từng người.",
                           "Hôm nay ai hụt target sẽ trao đổi riêng với QL. Làm ngay!"])
            )
        case .thaoMai:
            return LoiDan(
                mo: chon(["Cả nhà iu ơi, chị gửi chút tình hình nha ♥", "Mấy đứa ơi, mình cùng nhìn số một chút nhé ♥"]),
                viec: "✔ Mình cùng làm mấy việc nhỏ này nha:",
                duoiTapTrung: " — chị tin em làm được mà, cố lên nè ♥",
                ket: chon(["Thương cả nhà nhiều, mình cùng nhau làm thật đẹp nha ♥",
                           "Cả nhà giỏi lắm, chị luôn ở đây hỗ trợ mọi người ♥"])
            )
        case .binhThuong:
            return LoiDan(
                mo: chon(["Cả nhà cùng xem tình hình nhé:", "Gửi cả nhà tình hình số liệu:"]),
                viec: "✔ VIỆC CẦN LÀM:",
                duoiTapTrung: "",
                ket: chon(["Cùng nhau làm một ngày thật đẹp số nhé!", "Cố lên cả nhà, mình làm được!"])
            )
        }
    }

    private func dongCoTarget(_ ds: [DongThiDua]) -> [DongThiDua] {
        ds.filter { $0.target > 0.0001 }
    }

    private func tieuDeBai(_ ten: String) -> String {
        let ngay = TienIchNgay.hienThiNgay.string(from: s.ngay)
        let donVi = s.tenDonVi.isEmpty ? "" : " · \(s.tenDonVi)"
        return "\(ten)\(donVi) · \(ngay)"
    }

    private func dongLuuY() -> [String] {
        if s.tamTinh {
            return ["⏳ TẠM TÍNH (lũy kế hôm qua + kết ca tối qua) — gửi ảnh Đầu ca thật để thay bằng số thật.", ""]
        }
        return []
    }

    private func phanTramNgay(_ t: ThongTinDoanhThu) -> Double {
        if t.targetQuyDoi > 0, t.doanhThuQuyDoi > 0 { return t.doanhThuQuyDoi / t.targetQuyDoi * 100.0 }
        if t.targetThuc > 0, t.doanhThuThuc > 0 { return t.doanhThuThuc / t.targetThuc * 100.0 }
        if t.phanTramHTQuyDoi > 0 { return t.phanTramHTQuyDoi }
        return t.phanTramHTThuc
    }

    /// Đoạn "TẬP TRUNG": 3 nhân viên chậm nhất × 2 môn yếu nhất, có số cụ thể + việc cụ thể
    private func doanTapTrung(_ loi: LoiDan) -> [String] {
        let cacNV = s.nhanVien
            .filter { $0.tongMonGiao > 0 && $0.phanTramHTTB < 100 }
            .sorted { $0.phanTramHTTB < $1.phanTramHTTB }
            .prefix(3)
        var ketQua: [String] = []
        let conLai = Double(s.soNgayConLai)
        for nv in cacNV {
            let cacMon = nv.cacMonGiao
                .filter { $0.targetCaNhan > 0.0001 && $0.phanTramHT < 100 }
                .sorted { $0.phanTramHT < $1.phanTramHT }
                .prefix(2)
            for mon in cacMon {
                let thieu = max(0, mon.targetCaNhan - mon.thucHien)
                let moiNgay = thieu / conLai
                let dong1 = "• \(ten(nv.nhanVien.hoTen)) – \(mon.tenNganhHang): \(mon.thucHien.chuoiSoGonVN)/\(mon.targetCaNhan.chuoiSoGonVN) (\(mon.phanTramHT.chuoiPhanTram)). Còn thiếu \(thieu.chuoiSoGonVN), mỗi ngày cần ~\(moiNgay.chuoiSoGonVN)."
                let viec = vietHoaDau(hanhDong(cho: mon.tenNganhHang))
                ketQua.append(dong1)
                ketQua.append("   → \(viec)\(loi.duoiTapTrung)")
            }
        }
        return ketQua.isEmpty ? [] : ["", "◎ TẬP TRUNG:"] + ketQua
    }

    private func danhSachDanhDau(_ tieuDe: String, _ cacDong: [String]) -> [String] {
        cacDong.isEmpty ? [] : ["", tieuDe] + cacDong
    }

    // MARK: Đầu ca

    private func vietDauCa() -> String {
        guard s.coSoLieuLuyKe else {
            return "\(tieuDeBai("■ PHÂN TÍCH ĐẦU CA"))\n\nChưa có số Lũy kế. Vào \"Đổ số - Xem số → Lũy kế\" nhập ảnh Thi đua / Doanh thu rồi quay lại bản tin."
        }
        let loi = loiDan()
        let lk = s.luyKe
        let ds = dongCoTarget(s.dsLuyKe)
        let p = lk.phanTramHTQDDuKienHienThi
        let dat = ds.filter { $0.phanTramDuBao >= 99.995 }
        let yeu = ds.filter { $0.phanTramDuBao < 90 }.sorted { $0.phanTramDuBao < $1.phanTramDuBao }
        let gan = ds.filter { $0.phanTramDuBao >= 90 && $0.phanTramDuBao < 99.995 }.sorted { $0.phanTramDuBao > $1.phanTramDuBao }

        let dungQD = lk.targetQuyDoi > 0
        let dtHT = dungQD ? lk.doanhThuQuyDoi : lk.doanhThuThuc
        let mucTieu = dungQD ? lk.targetQuyDoi : lk.targetThuc
        let moiNgayCan = max(0, mucTieu - dtHT) / Double(s.soNgayConLai)
        let nhanLoai = dungQD ? "DT quy đổi" : "DT thực"

        var L: [String] = [tieuDeBai("■ PHÂN TÍCH ĐẦU CA"), ""]
        L += dongLuuY()
        L.append(loi.mo)

        if p >= 100 {
            L.append(chon(["Cả nhà ơi, lũy kế đến hôm qua mình đang đi tốt: dự kiến \(p.chuoiPhanTram) target doanh thu.",
                           "Tin vui đầu ngày: siêu thị đang dự kiến \(p.chuoiPhanTram) target, giữ nhịp này là về đích sớm."]))
        } else if p >= 90 {
            L.append(chon(["Lũy kế đến hôm qua mình dự kiến \(p.chuoiPhanTram) target — sát nút rồi, không được lơi tay.",
                           "Doanh thu dự kiến \(p.chuoiPhanTram), còn thiếu một chút nữa thôi, hôm nay phải bứt lên."]))
        } else {
            L.append(chon(["Nói thẳng: lũy kế dự kiến mới \(p.chuoiPhanTram) target, đang hụt khá nhiều.",
                           "Tình hình chưa ổn — dự kiến chỉ \(p.chuoiPhanTram) target, cả team cần tăng tốc ngay từ ca sáng."]))
        }
        L.append("• Lũy kế \(nhanLoai): \(dtHT.chuoiSoGonVN) / \(mucTieu.chuoiSoGonVN). Mỗi ngày còn lại cần ~\(moiNgayCan.chuoiSoGonVN) để chạm 100%.")
        if lk.coTangGiam {
            let dau = lk.tangGiamCungKy >= 0 ? "+" : ""
            L.append("• So cùng kỳ: \(dau)\(lk.tangGiamCungKy.chuoiPhanTram).")
        }
        L.append("• Thi đua: \(dat.count)/\(ds.count) môn đang về đích.")

        L += danhSachDanhDau("⚠ CẢNH BÁO — môn đang hụt nặng:", yeu.prefix(5).map { "  - \($0.tenNganhHang): \($0.phanTramDuBao.chuoiPhanTram)" })
        if !gan.isEmpty {
            let tieuDe = chon(["◎ Môn chỉ cần đẩy thêm chút là đạt:", "◎ Môn sát đích, làm ngay hôm nay:"])
            L += danhSachDanhDau(tieuDe, gan.prefix(4).map { "  - \($0.tenNganhHang): \($0.phanTramDuBao.chuoiPhanTram)" })
        }
        L += doanTapTrung(loi)

        var viec: [String] = []
        if let m = yeu.first {
            viec.append(chon(["Ưu tiên tư vấn kèm \(m.tenNganhHang) cho mọi khách mua máy.",
                              "Mỗi bạn chốt ít nhất 1 đơn \(m.tenNganhHang) trước 12h."]))
        }
        if yeu.count > 1 {
            viec.append("Ca chiều tập trung \(yeu[1].tenNganhHang) — quản lý kiểm tra lúc 15h.")
        }
        if let m = gan.first {
            viec.append("Chốt nốt \(m.tenNganhHang) trong hôm nay.")
        }
        viec.append(chon(["Chào khách trong 5 giây, không để khách đứng chờ.",
                          "Mời khách trải nghiệm máy trưng bày, tăng tỉ lệ chốt."]))
        L += ["", loi.viec]
        for (i, v) in viec.enumerated() { L.append("  \(i + 1). \(v)") }

        let nvYeu = s.nhanVien
            .filter { $0.tongMonGiao > 0 && $0.phanTramHTTB < 90 }
            .sorted { $0.phanTramHTTB < $1.phanTramHTTB }
            .prefix(2)
        if !nvYeu.isEmpty {
            L += ["", "➤ NHẮC NHỞ:"]
            for nv in nvYeu {
                let soKhong = nv.cacMonGiao.filter { $0.thucHien <= 0 }.count
                let t = ten(nv.nhanVien.hoTen)
                let pc = nv.phanTramHTTB.chuoiPhanTram
                L.append("  " + chon(["\(t) đang \(pc) target, còn \(soKhong) môn chưa có số — hôm nay cố lên em nhé.",
                                      "\(t): \(pc) target, \(soKhong) môn = 0. Cần thấy số trong ca hôm nay."]))
            }
        }
        if let tot = s.nhanVien.filter({ $0.tongMonGiao > 0 }).max(by: { ($0.soMonDat, $0.phanTramHTTB) < ($1.soMonDat, $1.phanTramHTTB) }), tot.soMonDat > 0 {
            let t = ten(tot.nhanVien.hoTen)
            L += ["", chon(["★ Khen \(t): \(tot.soMonDat)/\(tot.tongMonGiao) môn về đích — mọi người học hỏi nhé!",
                            "★ \(t) đang dẫn đầu với \(tot.soMonDat)/\(tot.tongMonGiao) môn đạt."])]
        }
        L += ["", loi.ket]
        return L.joined(separator: "\n")
    }

    // MARK: Hiện tại

    private func vietHienTai() -> String {
        guard s.coSoLieuHomNay || s.coSoLieuLuyKe else {
            return "\(tieuDeBai("⚡ BÁO CÁO HIỆN TẠI"))\n\nChưa có số. Vào \"Đổ số - Xem số → Realtime\" nhập ảnh rồi quay lại bản tin."
        }
        let loi = loiDan()
        let t = s.homNay
        var L: [String] = [tieuDeBai("⚡ BÁO CÁO HIỆN TẠI"), "", loi.mo]

        if s.coSoLieuHomNay {
            let p = phanTramNgay(t)
            let dungQD = t.targetQuyDoi > 0
            let dt = dungQD ? t.doanhThuQuyDoi : t.doanhThuThuc
            let tg = dungQD ? t.targetQuyDoi : t.targetThuc
            L.append("• Hôm nay đến giờ: \(dt.chuoiSoGonVN) / target ngày \(tg.chuoiSoGonVN) (\(p.chuoiPhanTram)).")
            if p >= 60 {
                L.append(chon(["Đang đi đúng nhịp, giữ vững nhé.", "Nhịp ổn, tiếp tục chốt đều tay."]))
            } else {
                L.append(chon(["Đang chậm so với nhịp ngày, cần tăng tốc ngay.", "Số trong ngày còn thấp, ca sau phải bù."]))
            }
        } else {
            L.append("• Chưa có số Realtime hôm nay — nhập ảnh Realtime để bản tin đầy đủ hơn.")
        }
        if s.coSoLieuLuyKe {
            L.append("• Lũy kế tháng: dự kiến \(s.luyKe.phanTramHTQDDuKienHienThi.chuoiPhanTram) target.")
        }

        let dsNgay = dongCoTarget(s.dsHomNay).sorted { $0.phanTramHT < $1.phanTramHT }
        let chuaCoSo = dsNgay.filter { $0.thucHien <= 0 }
        let chuaDu = dsNgay.filter { $0.thucHien > 0 && $0.phanTramHT < 100 }
        L += danhSachDanhDau("⚠ Môn hôm nay chưa có số:", chuaCoSo.prefix(6).map { "  - \($0.tenNganhHang)" })
        L += danhSachDanhDau("◎ Môn đang có số nhưng chưa đủ target ngày:", chuaDu.prefix(4).map { "  - \($0.tenNganhHang): \($0.phanTramHT.chuoiPhanTram)" })

        let nvNgay = s.homNayNV.sorted { $0.doanhThuQD > $1.doanhThuQD }.filter { $0.doanhThuQD > 0 }
        var bang: [String] = []
        for (i, nv) in nvNgay.enumerated() {
            bang.append("  \(i + 1). \(ten(nv.hoTen)): \(nv.doanhThuQD.chuoiSoGonVN)")
        }
        L += danhSachDanhDau("★ Bảng nhanh nhân viên hôm nay:", bang)
        L += doanTapTrung(loi)

        var viec: [String] = []
        if let m = chuaCoSo.first {
            viec.append("Ưu tiên \(m.tenNganhHang) ngay trong 1 giờ tới.")
        } else {
            viec.append("Giữ nhịp chốt đơn, không để khách chờ.")
        }
        if let m = chuaDu.first {
            viec.append("\(m.tenNganhHang): \(hanhDong(cho: m.tenNganhHang)).")
        }
        L += ["", loi.viec]
        for (i, v) in viec.enumerated() { L.append("  \(i + 1). \(v)") }
        L += ["", loi.ket]
        return L.joined(separator: "\n")
    }

    // MARK: Kết ca

    private func vietKetCa() -> String {
        guard s.coSoLieuHomNay else {
            return "\(tieuDeBai("☾ ĐÁNH GIÁ CUỐI NGÀY"))\n\nChưa có số trong ngày. Nhập ảnh Realtime (Doanh thu + Thi đua) rồi quay lại viết đánh giá."
        }
        let loi = loiDan()
        let t = s.homNay
        let p = phanTramNgay(t)
        let dungQD = t.targetQuyDoi > 0
        let dt = dungQD ? t.doanhThuQuyDoi : t.doanhThuThuc
        let tg = dungQD ? t.targetQuyDoi : t.targetThuc
        let nhanLoai = dungQD ? "DT quy đổi" : "DT thực"

        let ds = dongCoTarget(s.dsHomNay)
        let dat = ds.filter { $0.phanTramHT >= 99.995 }
        let truot = ds.filter { $0.phanTramHT < 99.995 }.sorted { $0.phanTramHT < $1.phanTramHT }

        var L: [String] = [tieuDeBai("☾ ĐÁNH GIÁ CUỐI NGÀY"), "", loi.mo]
        if p >= 100 {
            L.append(chon(["Hôm nay mình đạt \(p.chuoiPhanTram) target ngày — cảm ơn cả team đã chiến hết mình!",
                           "Ngày hôm nay về đích \(p.chuoiPhanTram) target. Làm tốt lắm mọi người!"]))
        } else if p >= 80 {
            L.append(chon(["Hôm nay đạt \(p.chuoiPhanTram) target ngày — gần tới nhưng vẫn chưa đủ.",
                           "Kết quả \(p.chuoiPhanTram) target ngày, hụt một chút. Ngày mai phải bù."]))
        } else {
            L.append(chon(["Hôm nay chỉ đạt \(p.chuoiPhanTram) target ngày, chưa đạt yêu cầu.",
                           "Kết quả ngày \(p.chuoiPhanTram) — thấp. Mình cần nhìn lại cách làm."]))
        }
        L.append("• \(nhanLoai) hôm nay: \(dt.chuoiSoGonVN) / target ngày \(tg.chuoiSoGonVN).")
        if !ds.isEmpty {
            L.append("• Thi đua hôm nay: \(dat.count)/\(ds.count) môn đạt target ngày.")
        }
        L += danhSachDanhDau("✖ Môn chưa đạt hôm nay:", truot.prefix(5).map { "  - \($0.tenNganhHang): \($0.phanTramHT.chuoiPhanTram)" })

        let nvCoSo = s.homNayNV.filter { $0.doanhThuQD > 0 }
        let tb = nvCoSo.isEmpty ? 0 : nvCoSo.map { $0.doanhThuQD }.reduce(0, +) / Double(nvCoSo.count)
        let nvYeu = nvCoSo.filter { $0.doanhThuQD < tb * 0.6 }.sorted { $0.doanhThuQD < $1.doanhThuQD }.prefix(2)
        L += danhSachDanhDau("➤ Nhân sự chưa làm tốt hôm nay:", nvYeu.map { "  - \(ten($0.hoTen)): \($0.doanhThuQD.chuoiSoGonVN) (trung bình team \(tb.chuoiSoGonVN))" })
        if let top = nvCoSo.max(by: { $0.doanhThuQD < $1.doanhThuQD }) {
            L += ["", "★ Ghi nhận \(ten(top.hoTen)) cao nhất hôm nay: \(top.doanhThuQD.chuoiSoGonVN)."]
        }

        var viec: [String] = []
        if let m = truot.first {
            viec.append("Ngày mai mở ca bằng \(m.tenNganhHang) — mỗi bạn có ít nhất 1 đơn.")
        }
        if !nvYeu.isEmpty {
            let danhSachTen = nvYeu.map { ten($0.hoTen) }.joined(separator: ", ")
            viec.append("\(danhSachTen): gặp quản lý đầu ca để cùng tìm cách tăng số.")
        }
        viec.append(chon(["Rà lại khách hẹn quay lại, gọi chăm sóc trước 10h.",
                          "Kiểm tra trưng bày, giá, quà tặng trước giờ mở cửa."]))
        L += ["", giong == .binhThuong ? "✔ YÊU CẦU HÀNH ĐỘNG:" : loi.viec]
        for (i, v) in viec.enumerated() { L.append("  \(i + 1). \(v)") }
        L += ["", "✍ CAM KẾT NGÀY MAI:",
              chon(["  Cả team cam kết đạt 100% target ngày và không để môn nào bằng 0.",
                    "  Cam kết bù phần hụt hôm nay, đạt tối thiểu 100% target ngày mai."])]
        L += ["", loi.ket]
        return L.joined(separator: "\n")
    }
}
