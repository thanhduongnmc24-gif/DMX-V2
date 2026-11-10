import UIKit

// MARK: - Bảng Màu Sáng Tươi Chuẩn ĐMX & BaoCaoThiDua (Không dùng màu xanh đen tối)

enum BangMauBCTD {
    // Màu chủ đạo sáng tươi: Xanh Dương ĐMX (#2563EB / #0284C7) + Vàng Tươi (#FACC15) + Cam Nâu (#AD4F0A)
    static let nenMenuToi = UIColor(red: 0.14, green: 0.39, blue: 0.92, alpha: 1.0)       // #2563EB Bright Royal Blue
    static let nenDongChonMenu = UIColor(red: 0.11, green: 0.31, blue: 0.85, alpha: 1.0)  // #1D4ED8 Deep Sky Blue
    static let nenMenuCon = UIColor(red: 0.93, green: 0.96, blue: 1.00, alpha: 1.0)       // #EFF6FF Light Sky
    static let nenHeaderBang = UIColor(red: 0.15, green: 0.42, blue: 0.92, alpha: 1.0)    // #266BE9 Bright Blue Header

    // Màu Sidebar sáng thanh lịch
    static let nenSidebarSang = UIColor.white
    static let nenSidebarChon = UIColor(red: 0.92, green: 0.96, blue: 1.00, alpha: 1.0)   // #EBF4FF
    static let nenSidebarCon = UIColor(red: 0.96, green: 0.98, blue: 1.00, alpha: 1.0)    // #F5F9FF

    // Màu nhấn thương hiệu: Vàng Tươi (như nút "Bình thường" trên ảnh mẫu) + Cam Phân Tích + Indigo/Sky
    static let vangChuDao = UIColor(red: 1.00, green: 0.84, blue: 0.10, alpha: 1.0)       // #FFD61A Bright Gold
    static let vangSang = UIColor(red: 0.99, green: 0.82, blue: 0.15, alpha: 1.0)         // #FACC15 Bright Yellow Pill
    static let vangNhatNen = UIColor(red: 1.00, green: 0.96, blue: 0.80, alpha: 1.0)      // #FEF3C7
    static let camPhanTich = UIColor(red: 0.68, green: 0.31, blue: 0.04, alpha: 1.0)      // #AD4F0A ("PHÂN TÍCH (viết sẵn — sửa được)")
    static let mauChuTieuDePhanTich = UIColor(red: 0.68, green: 0.31, blue: 0.04, alpha: 1.0) // #AD4F0A
    static let xanhChuDao = UIColor(red: 0.14, green: 0.39, blue: 0.92, alpha: 1.0)       // #2563EB
    static let xanhChuDaoDam = UIColor(red: 0.11, green: 0.31, blue: 0.85, alpha: 1.0)    // #1D4ED8
    static let vienXanhNhat = UIColor(red: 0.75, green: 0.85, blue: 0.99, alpha: 1.0)     // #BFDBFE
    static let xanhLaDam = UIColor(red: 0.07, green: 0.49, blue: 0.23, alpha: 1.0)        // #127D3B
    static let indigoChuDao = UIColor(red: 0.15, green: 0.40, blue: 0.92, alpha: 1.0)     // #2667EB Bright Blue
    static let indigoDam = UIColor(red: 0.11, green: 0.32, blue: 0.82, alpha: 1.0)        // #1D52D1
    static let indigoNhatNen = UIColor(red: 0.92, green: 0.96, blue: 1.00, alpha: 1.0)    // #EBF5FF
    static let indigoVien = UIColor(red: 0.75, green: 0.85, blue: 0.99, alpha: 1.0)       // #BFDBFE
    static let xanhBienChuDao = UIColor(red: 0.01, green: 0.52, blue: 0.78, alpha: 1.0)   // #0284C7 Sky 600

    // Nền trang & thẻ sáng sạch (#F4F7FB / #FFFFFF / #E2E8F0)
    static let nenTrang = UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0)         // #F5F8FC Bright Light Surface
    static let nenThe = UIColor.white                                                     // #FFFFFF
    static let nenThePhu = UIColor(red: 0.97, green: 0.98, blue: 1.00, alpha: 1.0)        // #F8FAFC
    static let nenHeaderPhu = UIColor(red: 0.93, green: 0.96, blue: 1.00, alpha: 1.0)     // #EFF6FF
    static let vienThe = UIColor(red: 0.86, green: 0.90, blue: 0.95, alpha: 1.0)          // #DCE5F2
    static let vienDam = UIColor(red: 0.78, green: 0.83, blue: 0.90, alpha: 1.0)          // #C7D4E6

    // Chữ phân cấp độ tương phản cao
    static let chuChinh = UIColor(red: 0.10, green: 0.15, blue: 0.24, alpha: 1.0)         // #1A263D
    static let chuPhu = UIColor(red: 0.27, green: 0.34, blue: 0.45, alpha: 1.0)           // #455773
    static let chuMo = UIColor(red: 0.42, green: 0.48, blue: 0.58, alpha: 1.0)            // #6B7B94
    static let chuTrenNenToi = UIColor(red: 0.93, green: 0.96, blue: 1.00, alpha: 1.0)    // #EFF6FF

    // 3 mức trạng thái nghiệp vụ: >=100% Xanh (ok) · 80-99% Vàng (mid/near) · <80% Đỏ (no/di)
    static let xanhDatChu = UIColor(red: 0.07, green: 0.49, blue: 0.23, alpha: 1.0)       // #127D3B
    static let xanhDatPill = UIColor(red: 0.86, green: 0.98, blue: 0.90, alpha: 1.0)      // #DCFCE7
    static let xanhDatNenDong = UIColor(red: 0.94, green: 0.99, blue: 0.96, alpha: 1.0)   // #F0FDF4
    static let xanhDatVach = UIColor(red: 0.09, green: 0.64, blue: 0.29, alpha: 1.0)      // #16A34A

    static let vangKhaChu = UIColor(red: 0.63, green: 0.36, blue: 0.03, alpha: 1.0)       // #A15C07
    static let vangKhaPill = UIColor(red: 1.00, green: 0.95, blue: 0.76, alpha: 1.0)      // #FEF3C2
    static let vangKhaNenDong = UIColor(red: 1.00, green: 0.98, blue: 0.92, alpha: 1.0)   // #FFFBEB
    static let vangKhaVach = UIColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1.0)      // #F59E0B

    static let doYeuChu = UIColor(red: 0.73, green: 0.11, blue: 0.11, alpha: 1.0)         // #B91C1C
    static let doYeuPill = UIColor(red: 1.00, green: 0.89, blue: 0.89, alpha: 1.0)        // #FEE2E2
    static let doYeuNenDong = UIColor(red: 1.00, green: 0.95, blue: 0.95, alpha: 1.0)     // #FEF2F2
    static let doYeuVach = UIColor(red: 0.86, green: 0.15, blue: 0.15, alpha: 1.0)        // #DC2626

    static func mauTrangThai(phanTram pt: Double) -> (chu: UIColor, pill: UIColor, nenDong: UIColor, vach: UIColor) {
        if pt >= 99.995 {
            return (xanhDatChu, xanhDatPill, xanhDatNenDong, xanhDatVach)
        } else if pt >= 80.0 {
            return (vangKhaChu, vangKhaPill, vangKhaNenDong, vangKhaVach)
        } else {
            return (doYeuChu, doYeuPill, doYeuNenDong, doYeuVach)
        }
    }

    static func taoHeaderBannerBaoCao(
        rong: CGFloat,
        kicker: String,
        tieuDe: String,
        thongKePhu: String? = nil
    ) -> (view: UIView, chieuCao: CGFloat) {
        let le: CGFloat = 18
        let rongChu = max(120, rong - le * 2)
        let pLeft = NSMutableParagraphStyle()
        pLeft.alignment = .left
        pLeft.lineBreakMode = .byWordWrapping

        let fontKicker = UIFont.systemFont(ofSize: 12.0, weight: .bold)
        let fontTieuDe = UIFont.systemFont(ofSize: 19.0, weight: .heavy)
        let fontPhu = UIFont.systemFont(ofSize: 12.5, weight: .semibold)

        let caoKicker = max(18, ceil((kicker.uppercased() as NSString).boundingRect(
            with: CGSize(width: rongChu, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontKicker, .paragraphStyle: pLeft],
            context: nil
        ).height))

        let caoTieuDe = max(26, ceil((tieuDe as NSString).boundingRect(
            with: CGSize(width: rongChu, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontTieuDe, .paragraphStyle: pLeft],
            context: nil
        ).height))

        var caoPhu: CGFloat = 0
        if let s = thongKePhu, !s.isEmpty {
            caoPhu = max(18, ceil((s as NSString).boundingRect(
                with: CGSize(width: rongChu, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: fontPhu, .paragraphStyle: pLeft],
                context: nil
            ).height))
        }

        let tongCao = 14 + caoKicker + 4 + caoTieuDe + (caoPhu > 0 ? 4 + caoPhu : 0) + 14 + 5
        let header = UIView(frame: CGRect(x: 0, y: 0, width: rong, height: tongCao))
        header.backgroundColor = nenHeaderBang
        let gradient = CAGradientLayer()
        gradient.frame = header.bounds
        gradient.colors = [
            UIColor(red: 0.12, green: 0.35, blue: 0.94, alpha: 1).cgColor,
            UIColor(red: 0.02, green: 0.62, blue: 0.88, alpha: 1).cgColor,
            UIColor(red: 0.02, green: 0.70, blue: 0.55, alpha: 1).cgColor
        ]
        gradient.locations = [0, 0.62, 1]
        gradient.startPoint = CGPoint(x: 0, y: 0.15)
        gradient.endPoint = CGPoint(x: 1, y: 0.85)
        header.layer.insertSublayer(gradient, at: 0)

        // Họa tiết ánh sáng nhẹ giúp ảnh xuất nổi bật nhưng vẫn giữ chữ dễ đọc.
        for (x, y, d, alpha) in [
            (rong * 0.78, -tongCao * 0.55, tongCao * 1.25, 0.10),
            (rong * 0.91, tongCao * 0.34, tongCao * 0.72, 0.08)
        ] {
            let vong = CAShapeLayer()
            vong.path = UIBezierPath(ovalIn: CGRect(x: x, y: y, width: d, height: d)).cgPath
            vong.fillColor = UIColor.white.withAlphaComponent(alpha).cgColor
            header.layer.insertSublayer(vong, above: gradient)
        }

        let lbKicker = UILabel(frame: CGRect(x: le, y: 14, width: rongChu, height: caoKicker))
        lbKicker.text = kicker.uppercased()
        lbKicker.font = fontKicker
        lbKicker.textColor = vangChuDao
        lbKicker.numberOfLines = 0
        lbKicker.lineBreakMode = .byWordWrapping
        lbKicker.adjustsFontSizeToFitWidth = false
        header.addSubview(lbKicker)

        var y = 14 + caoKicker + 4
        let lbTieuDe = UILabel(frame: CGRect(x: le, y: y, width: rongChu, height: caoTieuDe))
        lbTieuDe.text = tieuDe
        lbTieuDe.font = fontTieuDe
        lbTieuDe.textColor = .white
        lbTieuDe.numberOfLines = 0
        lbTieuDe.lineBreakMode = .byWordWrapping
        lbTieuDe.adjustsFontSizeToFitWidth = false
        header.addSubview(lbTieuDe)
        y += caoTieuDe

        if let s = thongKePhu, !s.isEmpty, caoPhu > 0 {
            y += 4
            let lbPhu = UILabel(frame: CGRect(x: le, y: y, width: rongChu, height: caoPhu))
            lbPhu.text = s
            lbPhu.font = fontPhu
            lbPhu.textColor = UIColor(red: 0.90, green: 0.95, blue: 1.00, alpha: 1.0)
            lbPhu.numberOfLines = 0
            lbPhu.lineBreakMode = .byWordWrapping
            lbPhu.adjustsFontSizeToFitWidth = false
            header.addSubview(lbPhu)
        }

        let vachVang = UIView(frame: CGRect(x: 0, y: tongCao - 5, width: rong, height: 5))
        vachVang.backgroundColor = vangChuDao
        header.addSubview(vachVang)

        return (header, tongCao)
    }
}

enum LoaiCheDoDoanhThu: Int, CaseIterable {
    case luyKe = 0
    case realtime = 1

    var tieuDe: String {
        switch self {
        case .luyKe: return "Lũy kế"
        case .realtime: return "Realtime"
        }
    }
}

enum LoaiTabMuc: Int, CaseIterable {
    case thiDua = 0
    case nhanVien = 1
    case duPhong2 = 2

    static let cacTabCumDuoi: [LoaiTabMuc] = [.thiDua, .nhanVien]

    var tieuDe: String {
        switch self {
        case .thiDua: return "Thi đua"
        case .nhanVien: return "Nhân viên"
        case .duPhong2: return "Biểu đồ"
        }
    }
}

/// 4 tab con bên trong mục "1. Xem số" (Lũy kế | Realtime | Biểu đồ | Nhân viên)
enum TabXemSo: Int, CaseIterable {
    case luyKe = 0
    case realtime = 1
    case bieuDo = 2
    case nhanVien = 3
    case tonKho = 4

    static var allCases: [TabXemSo] { [.luyKe, .realtime, .bieuDo, .tonKho] }

    var tieuDe: String {
        switch self {
        case .luyKe: return "Lũy kế"
        case .realtime: return "Realtime"
        case .bieuDo: return "Biểu đồ"
        case .nhanVien: return "Nhân viên"
        case .tonKho: return "Tồn kho"
        }
    }

    var bieuTuong: String {
        switch self {
        case .luyKe: return "📊"
        case .realtime: return "⚡"
        case .bieuDo: return "📈"
        case .nhanVien: return "👥"
        case .tonKho: return "📦"
        }
    }
}

/// 3 mục con bên trong phần "Đổ số - Xem số" trên Menu điều hướng:
/// 1. Xem số  |  2. Nhập số  |  3. Xuất ảnh
enum MucConDoSo: Int, CaseIterable {
    case xemSo = 0
    case nhapSo = 1
    case xuatAnh = 2

    var tieuDe: String {
        switch self {
        case .xemSo: return "1. Xem số"
        case .nhapSo: return "2. Nhập số"
        case .xuatAnh: return "3. Xuất ảnh"
        }
    }

    var tieuDeNgan: String {
        switch self {
        case .xemSo: return "Xem số"
        case .nhapSo: return "Nhập số"
        case .xuatAnh: return "Xuất ảnh"
        }
    }

    var bieuTuongSF: String {
        switch self {
        case .xemSo: return "tablecells.fill"
        case .nhapSo: return "camera.viewfinder"
        case .xuatAnh: return "photo.on.rectangle.angled"
        }
    }
}

/// Danh sách mục chính trên Menu trượt (Sidebar Drawer):
/// Dưới "Tổng quan" có ngay nút "Báo cáo", tiếp theo là "Đổ số - Xem số" (3 mục con) và "Cài đặt".
enum MucMenuChinh: Int, CaseIterable {
    case tongQuan = 0
    case baoCao = 1
    case doSoXemSo = 2
    case caiDat = 3
    case lichDoSo = 4
    case xuatFileBaoCao = 5
    case lenhTroLy = 6
    case taiKhoanHopThu = 7
    case ketNoi = 8
    case nhiemVu = 9
    case capNhat = 10
    case hoTro = 11
    case lienHeVip = 12
    case quanTri = 13
    case trinhDuyet = 14
    case nhanVien = 15
    case guiBaoCao = 16
    case tonKho = 17

    static var allCases: [MucMenuChinh] {
        [.tongQuan, .doSoXemSo, .nhanVien, .tonKho, .guiBaoCao, .xuatFileBaoCao, .caiDat, .quanTri]
    }

    var tieuDe: String {
        switch self {
        case .tongQuan: return "Tổng quan"
        case .baoCao: return "Báo cáo"
        case .doSoXemSo: return "Đổ số - Xem số"
        case .caiDat: return "Cài đặt"
        case .lichDoSo: return "Lịch đổ số"
        case .xuatFileBaoCao: return "Xuất file báo cáo"
        case .lenhTroLy: return "Lệnh trợ lý"
        case .taiKhoanHopThu: return "Tài khoản & Hộp thư"
        case .ketNoi: return "Kết nối"
        case .nhiemVu: return "Nhiệm vụ"
        case .capNhat: return "Cập nhật"
        case .hoTro: return "Hỗ trợ"
        case .lienHeVip: return "Liên hệ & gói VIP"
        case .quanTri: return "Quản trị"
        case .trinhDuyet: return "Trình duyệt Copilot"
        case .nhanVien: return "Nhân viên"
        case .guiBaoCao: return "Gởi báo cáo"
        case .tonKho: return "Lọc dữ liệu tồn kho"
        }
    }

    var bieuTuongSF: String {
        switch self {
        case .tongQuan: return "house.fill"
        case .baoCao: return "doc.text.magnifyingglass"
        case .doSoXemSo: return "tablecells.fill"
        case .caiDat: return "gearshape.fill"
        case .lichDoSo: return "calendar.badge.clock"
        case .xuatFileBaoCao: return "doc.on.clipboard.fill"
        case .lenhTroLy: return "terminal.fill"
        case .taiKhoanHopThu: return "person.crop.circle"
        case .ketNoi: return "icloud.and.arrow.up"
        case .nhiemVu: return "checklist"
        case .capNhat: return "arrow.up.square"
        case .hoTro: return "questionmark.circle"
        case .lienHeVip: return "phone.fill"
        case .quanTri: return "crown.fill"
        case .trinhDuyet: return "globe"
        case .nhanVien: return "person.3.fill"
        case .guiBaoCao: return "paperplane.fill"
        case .tonKho: return "shippingbox.fill"
        }
    }

    var nhanDoPhai: String? {
        nil
    }

    var coMenuCon: Bool {
        false
    }
}

enum KieuSapXepNhanVien: Int, CaseIterable {
    case tenAZ = 0
    case soMonHoanThanh = 1
    case doanhThuQD = 2
    case phanTramTB = 3

    var nhan: String {
        switch self {
        case .tenAZ: return "🔤 Tên nhân viên (A → Z)"
        case .soMonHoanThanh: return "🏆 Số môn hoàn thành (Cao → Thấp)"
        case .doanhThuQD: return "🎯 Doanh thu QĐ (Cao → Thấp)"
        case .phanTramTB: return "📈 % HT thi đua TB (Cao → Thấp)"
        }
    }

    var nhanNgan: String {
        switch self {
        case .tenAZ: return "Tên A-Z"
        case .soMonHoanThanh: return "Số môn HT"
        case .doanhThuQD: return "DT QĐ"
        case .phanTramTB: return "% HT TB"
        }
    }
}

struct NhanVienQuanLy: Codable, Hashable, Identifiable {
    private static let localeVN = Locale(identifier: "vi_VN")

    var maNV: String
    var hoTen: String
    var id: String { maNV }

    static func soSanhAZ(_ a: NhanVienQuanLy, _ b: NhanVienQuanLy) -> Bool {
        let tenA = a.hoTen.trimmingCharacters(in: .whitespacesAndNewlines)
        let tenB = b.hoTen.trimmingCharacters(in: .whitespacesAndNewlines)
        let kq = tenA.compare(tenB, options: [.caseInsensitive], range: nil, locale: localeVN)
        if kq != .orderedSame {
            return kq == .orderedAscending
        }
        return a.maNV.compare(b.maNV, options: [.numeric]) == .orderedAscending
    }

    static func sapXepAZ(_ danhSach: [NhanVienQuanLy]) -> [NhanVienQuanLy] {
        danhSach.sorted(by: soSanhAZ)
    }
}

struct DoanhThuNhanVienItem: Codable, Hashable {
    var maNV: String
    var hoTen: String
    var soLuong: Double = 0
    var doanhThuThuc: Double = 0
    var doanhThuQD: Double = 0
    var target: Double = 0
    var dtQDKhoanVay: Double = 0
    var dtTraThangQD: Double = 0
    var dtTraGop: Double = 0
    var phanTramHT: Double = 0
    var phanTramQuyDoi: Double = 0
    var phanTramTraGop: Double = 0
    var gioCong: Double = 0
    var soNgayNghi: Double = 0
    var nangSuat: Double = 0

    init(
        maNV: String,
        hoTen: String,
        soLuong: Double = 0,
        doanhThuThuc: Double = 0,
        doanhThuQD: Double = 0,
        target: Double = 0,
        dtQDKhoanVay: Double = 0,
        dtTraThangQD: Double = 0,
        dtTraGop: Double = 0,
        phanTramHT: Double = 0,
        phanTramQuyDoi: Double = 0,
        phanTramTraGop: Double = 0,
        gioCong: Double = 0,
        soNgayNghi: Double = 0,
        nangSuat: Double = 0
    ) {
        self.maNV = maNV
        self.hoTen = hoTen
        self.soLuong = soLuong
        self.doanhThuThuc = doanhThuThuc
        self.doanhThuQD = doanhThuQD
        self.target = target
        self.dtQDKhoanVay = dtQDKhoanVay
        self.dtTraThangQD = dtTraThangQD
        self.dtTraGop = dtTraGop
        self.phanTramHT = phanTramHT
        self.phanTramQuyDoi = phanTramQuyDoi
        self.phanTramTraGop = phanTramTraGop
        self.gioCong = gioCong
        self.soNgayNghi = soNgayNghi
        self.nangSuat = nangSuat
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        maNV = (try? c.decode(String.self, forKey: .maNV)) ?? ""
        hoTen = (try? c.decode(String.self, forKey: .hoTen)) ?? ""
        soLuong = (try? c.decode(Double.self, forKey: .soLuong)) ?? 0
        doanhThuThuc = (try? c.decode(Double.self, forKey: .doanhThuThuc)) ?? 0
        doanhThuQD = (try? c.decode(Double.self, forKey: .doanhThuQD)) ?? 0
        target = (try? c.decode(Double.self, forKey: .target)) ?? 0
        dtQDKhoanVay = (try? c.decode(Double.self, forKey: .dtQDKhoanVay)) ?? 0
        dtTraThangQD = (try? c.decode(Double.self, forKey: .dtTraThangQD)) ?? 0
        dtTraGop = (try? c.decode(Double.self, forKey: .dtTraGop)) ?? 0
        phanTramHT = (try? c.decode(Double.self, forKey: .phanTramHT)) ?? 0
        phanTramQuyDoi = (try? c.decode(Double.self, forKey: .phanTramQuyDoi)) ?? 0
        phanTramTraGop = (try? c.decode(Double.self, forKey: .phanTramTraGop)) ?? 0
        gioCong = (try? c.decode(Double.self, forKey: .gioCong)) ?? 0
        soNgayNghi = (try? c.decode(Double.self, forKey: .soNgayNghi)) ?? 0
        nangSuat = (try? c.decode(Double.self, forKey: .nangSuat)) ?? 0
    }
}

struct DongXepHangNhanVienNganh: Hashable {
    var maNV: String
    var hoTen: String
    var thucHien: Double
    var targetCaNhan: Double
    var phanTramHT: Double
    var chenhLech: Double { thucHien - targetCaNhan }
    var daDat: Bool { phanTramHT >= 99.995 }
}

struct MonThiDuaNhanVien: Hashable {
    var khoaNganh: String
    var tenNganhHang: String
    var loaiChiTieu: LoaiChiTieuThiDua
    var thucHien: Double
    var targetCaNhan: Double
    var phanTramHT: Double
    var phanTramSieuThi: Double
    var conLai: Double { targetCaNhan - thucHien }
    var daDat: Bool { phanTramHT >= 99.995 }
}

struct TongHopNhanVien: Hashable {
    var nhanVien: NhanVienQuanLy
    var soMonDat: Int
    var tongMonGiao: Int
    var phanTramHTTB: Double
    var doanhThuQD: Double
    var soLuongDon: Double
    var dtQDKhoanVay: Double
    var dtTraThangQD: Double
    var phanTramTiTrong: Double = 0
    var cacMonGiao: [MonThiDuaNhanVien]
    var doanhThuCaNhan: DoanhThuNhanVienItem?
}

/// Khung dữ liệu thông số Sức khỏe cá nhân Nhân viên (mẫu 27 điểm: Doanh thu 6, Năng suất 3, Hiệu quả khai thác 9, Đơn giá 8, Thi đua 1).
/// Các trường Optional cho phép hiển thị khung chờ bổ sung khi chưa có số liệu, và tự động hiển thị ngay khi được cập nhật/bổ sung.
struct DuLieuSucKhoeBoSungNV: Codable, Hashable {
    // 0. Thông tin chung trên phiếu sức khỏe 27 điểm
    var diemDat27: Int?
    var tongDiem27: Int?
    var phanTramHoanThanhChung: Double?
    var soNgayDaQuaThang: Int?
    var tongSoNgayThang: Int?

    // 1. Khối Doanh thu bổ sung (Đủ 6 mục: Doanh thu QĐ, % Target, Số lượt bill bán hàng, % Quy đổi, % Trả chậm, % Bán kèm)
    var doanhThuQDSucKhoe: Double?
    var tbDoanhThuQDSieuThi: Double?
    var mucTieuTargetQD: Double?
    var phanTramTarget: Double?
    var tbPhanTramTarget: Double?
    var soLuotBillBanHang: Double?
    var tbSoLuotBillBanHang: Double?
    var phanTramQuyDoi: Double?
    var tbPhanTramQuyDoi: Double?
    var phanTramTraCham: Double?
    var tbPhanTramTraCham: Double?
    var phanTramBanKem: Double?
    var tbPhanTramBanKem: Double?

    // 2. Khối Năng suất (3/3: Điểm thưởng ERP, Điểm thưởng / Giờ công, DTQĐ / Giờ công)
    var diemThuongERP: Double?
    var tbDiemThuongERP: Double?
    var diemThuongTrenGioCong: Double?
    var tbDiemThuongTrenGioCong: Double?
    var dtqdTrenGioCong: Double?
    var tbDtqdTrenGioCong: Double?

    // 2b. Khối Thi đua cá nhân (% hoàn thành từng môn từ phiếu sức khỏe NV)
    var phanTramThiDuaCaNhan: [String: Double]?

    // 3. Khối Hiệu quả khai thác (0/9) - Lưu theo khóa danh mục chuẩn
    var hieuQuaKhaiThac: [String: Double] = [:]

    // 4. Khối Đơn giá (4/8) - Lưu giá trị cá nhân và TB siêu thị (đơn vị: triệu đồng)
    var donGiaCaNhan: [String: Double] = [:]
    var donGiaTrungBinhST: [String: Double] = [:]

    // 5. Tỷ trọng ngành hàng (%)
    var tyTrongNganhHang: [String: Double] = [:]

    // 6. Doanh thu QĐ từng tháng ("MM/yyyy": triệu đồng)
    var doanhThuQDTungThang: [String: Double] = [:]

    static let danhSachMucHieuQuaTrai: [(khoa: String, nhan: String)] = [
        ("phu_kien", "% Phụ kiện"),
        ("may_loc_nuoc", "% Máy lọc nước"),
        ("sim", "% Sim"),
        ("vas", "% VAS"),
        ("bao_hiem_dmx", "% Bảo hiểm ĐMX")
    ]

    static let danhSachMucHieuQuaPhai: [(khoa: String, nhan: String)] = [
        ("camera", "% Camera"),
        ("bao_hiem_tong", "% Bảo hiểm tổng"),
        ("sac_du_phong", "% Sạc dự phòng"),
        ("gia_dung", "% Gia dụng")
    ]

    static var tatCaMucHieuQua: [(khoa: String, nhan: String)] {
        danhSachMucHieuQuaTrai + danhSachMucHieuQuaPhai
    }

    static let danhSachMucDonGia: [(khoa: String, nhan: String)] = [
        ("tb_spc", "TB SẢN PHẨM CHÍNH"),
        ("tivi", "TIVI"),
        ("tu_lanh", "TỦ LẠNH"),
        ("may_giat", "MÁY GIẶT"),
        ("may_lanh", "MÁY LẠNH"),
        ("mln", "MLN"),
        ("dien_thoai", "ĐIỆN THOẠI"),
        ("laptop", "LAPTOP")
    ]

    static let danhSachNhomTyTrongNganhHang: [(khoa: String, nhan: String)] = [
        ("apple", "Apple"),
        ("tu_lanh_dong_mat", "Tủ lạnh, đông, mát"),
        ("dien_tu", "Điện tử"),
        ("gia_dung", "Gia dụng"),
        ("vien_thong_di_dong", "Viễn thông di động"),
        ("laptop", "Laptop"),
        ("may_lanh_nuoc_nong", "Máy lạnh & Máy nước nóng"),
        ("khac", "Khác")
    ]

    var coDuLieu: Bool {
        doanhThuQDSucKhoe != nil ||
        tbDoanhThuQDSieuThi != nil ||
        mucTieuTargetQD != nil ||
        phanTramTarget != nil ||
        soLuotBillBanHang != nil ||
        phanTramQuyDoi != nil ||
        phanTramTraCham != nil ||
        phanTramBanKem != nil ||
        diemThuongERP != nil ||
        diemThuongTrenGioCong != nil ||
        dtqdTrenGioCong != nil ||
        !(phanTramThiDuaCaNhan ?? [:]).isEmpty ||
        !hieuQuaKhaiThac.isEmpty ||
        !donGiaCaNhan.isEmpty
    }

    func gop(voi moi: DuLieuSucKhoeBoSungNV) -> DuLieuSucKhoeBoSungNV {
        var kq = self
        if let v = moi.diemDat27 { kq.diemDat27 = v }
        if let v = moi.tongDiem27 { kq.tongDiem27 = v }
        if let v = moi.phanTramHoanThanhChung { kq.phanTramHoanThanhChung = v }
        if let v = moi.soNgayDaQuaThang { kq.soNgayDaQuaThang = v }
        if let v = moi.tongSoNgayThang { kq.tongSoNgayThang = v }
        if let v = moi.doanhThuQDSucKhoe { kq.doanhThuQDSucKhoe = v }
        if let v = moi.tbDoanhThuQDSieuThi { kq.tbDoanhThuQDSieuThi = v }
        if let v = moi.mucTieuTargetQD { kq.mucTieuTargetQD = v }
        if let v = moi.phanTramTarget { kq.phanTramTarget = v }
        if let v = moi.tbPhanTramTarget { kq.tbPhanTramTarget = v }
        if let v = moi.soLuotBillBanHang { kq.soLuotBillBanHang = v }
        if let v = moi.tbSoLuotBillBanHang { kq.tbSoLuotBillBanHang = v }
        if let v = moi.phanTramQuyDoi { kq.phanTramQuyDoi = v }
        if let v = moi.tbPhanTramQuyDoi { kq.tbPhanTramQuyDoi = v }
        if let v = moi.phanTramTraCham { kq.phanTramTraCham = v }
        if let v = moi.tbPhanTramTraCham { kq.tbPhanTramTraCham = v }
        if let v = moi.phanTramBanKem { kq.phanTramBanKem = v }
        if let v = moi.tbPhanTramBanKem { kq.tbPhanTramBanKem = v }
        if let v = moi.diemThuongERP { kq.diemThuongERP = v }
        if let v = moi.tbDiemThuongERP { kq.tbDiemThuongERP = v }
        if let v = moi.diemThuongTrenGioCong { kq.diemThuongTrenGioCong = v }
        if let v = moi.tbDiemThuongTrenGioCong { kq.tbDiemThuongTrenGioCong = v }
        if let v = moi.dtqdTrenGioCong { kq.dtqdTrenGioCong = v }
        if let v = moi.tbDtqdTrenGioCong { kq.tbDtqdTrenGioCong = v }
        if let ptMoi = moi.phanTramThiDuaCaNhan, !ptMoi.isEmpty {
            var gopPT = kq.phanTramThiDuaCaNhan ?? [:]
            for (k, v) in ptMoi { gopPT[k] = v }
            kq.phanTramThiDuaCaNhan = gopPT
        }
        for (k, v) in moi.hieuQuaKhaiThac { kq.hieuQuaKhaiThac[k] = v }
        for (k, v) in moi.donGiaCaNhan { kq.donGiaCaNhan[k] = v }
        for (k, v) in moi.donGiaTrungBinhST { kq.donGiaTrungBinhST[k] = v }
        for (k, v) in moi.tyTrongNganhHang { kq.tyTrongNganhHang[k] = v }
        for (k, v) in moi.doanhThuQDTungThang { kq.doanhThuQDTungThang[k] = v }
        return kq
    }
}

enum LoaiBieuDoThang: Int, CaseIterable {
    case realtime = 0
    case sucKhoeNhanVien = 1

    var tieuDe: String {
        switch self {
        case .realtime: return "📊 Biểu đồ Realtime"
        case .sucKhoeNhanVien: return "❤️‍🩹 Biểu đồ sức khỏe NV"
        }
    }
}

enum MucDoSucKhoeNV: Int, Codable, Hashable {
    case khoe = 0
    case trungBinh = 1
    case yeu = 2
    case chuaCoSo = 3

    var nhan: String {
        switch self {
        case .khoe: return "Khỏe mạnh"
        case .trungBinh: return "Trung bình"
        case .yeu: return "Yếu"
        case .chuaCoSo: return "Chưa có số"
        }
    }

    var kyHieu: String {
        switch self {
        case .khoe: return "🟢"
        case .trungBinh: return "🟡"
        case .yeu: return "🔴"
        case .chuaCoSo: return "⚪"
        }
    }
}

struct DiemSucKhoeNgayNV: Hashable {
    var khoaNgay: String
    var ngayTrongThang: Int
    var nhanNgay: String
    var diemSucKhoe: Double
    var mucDo: MucDoSucKhoeNV
    var soMonDat: Int
    var tongMonGiao: Int
    var phanTramHTTB: Double
    var doanhThuQD: Double
}

struct HoSoSucKhoeNhanVien: Hashable {
    var nhanVien: NhanVienQuanLy
    var tongHopHienTai: TongHopNhanVien
    var diemSucKhoe: Double
    var mucDo: MucDoSucKhoeNV
    var soNgayYeuLienTuc: Int
    var chuoiYeuDaiNhat: Int
    var tongSoNgayYeu: Int
    var tongSoNgayCoSo: Int
    var lichSuNgay: [DiemSucKhoeNgayNV]
    var cacMonYeuNhat: [String]
    var xuHuongDiem: Double
    var laCanhBaoTop5: Bool
    var hangCanhBao: Int?

    var nhanXuHuong: String {
        if xuHuongDiem >= 3.0 { return "📈 Tăng" }
        if xuHuongDiem <= -3.0 { return "📉 Giảm" }
        return "➖ Đi ngang"
    }

    var chuoiCanhBaoYeu: String {
        if soNgayYeuLienTuc >= 2 {
            return "🔥 Yếu \(soNgayYeuLienTuc) ngày liên tục"
        } else if soNgayYeuLienTuc == 1 {
            return "⚠️ Yếu \(tongSoNgayYeu > 1 ? "\(tongSoNgayYeu) ngày (đang yếu)" : "1 ngày gần nhất")"
        } else if tongSoNgayYeu > 0 {
            return "⚠️ Đã yếu \(tongSoNgayYeu)/\(max(1, tongSoNgayCoSo)) ngày"
        } else {
            return "⚠️ Điểm SK thấp (\(Int(round(diemSucKhoe)))%)"
        }
    }
}

struct BaoCaoSucKhoeDoiNgu: Hashable {
    var ngayBaoCao: Date
    var cheDo: LoaiCheDoDoanhThu
    var soNgayDaTheoDoi: Int
    var cacNhanNgayTheoDoi: [String]
    var soNVKhoe: Int
    var soNVTrungBinh: Int
    var soNVYeu: Int
    var diemTrungBinhDoiNgu: Double
    var top5CanhBaoYeu: [HoSoSucKhoeNhanVien]
    var danhSachTatCa: [HoSoSucKhoeNhanVien]
}

enum KieuHienThiBaoCao: Int, Codable, CaseIterable {
    case bangChiTiet = 0
    case theGon = 1

    var tieuDe: String {
        switch self {
        case .bangChiTiet: return "Bảng 8 cột"
        case .theGon: return "Thẻ tiến độ"
        }
    }

    var maWeb: String {
        switch self {
        case .bangChiTiet: return "bangChiTiet"
        case .theGon: return "theGon"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let rawInt = try? container.decode(Int.self), let val = KieuHienThiBaoCao(rawValue: rawInt) {
            self = val
        } else if let rawStr = try? container.decode(String.self) {
            self = (rawStr == "theGon") ? .theGon : .bangChiTiet
        } else {
            self = .bangChiTiet
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(maWeb)
    }
}

enum LoaiChiTieuThiDua: String, Codable, CaseIterable {
    case soLuong = "SL"
    case doanhThu = "DT"

    var maBang: String {
        switch self {
        case .soLuong: return "SL"
        case .doanhThu: return "DT"
        }
    }

    var maThe: String {
        switch self {
        case .soLuong: return "SLLK"
        case .doanhThu: return "DTLK"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self))?.uppercased() ?? "DT"
        if raw.contains("SL") {
            self = .soLuong
        } else {
            self = .doanhThu
        }
    }
}

struct ThongTinDoanhThu: Codable, Hashable {
    var doanhThuThuc: Double = 0
    var targetThuc: Double = 0
    var duKienThuc: Double = 0
    var phanTramHTThuc: Double = 0

    var doanhThuQuyDoi: Double = 0
    var targetQuyDoi: Double = 0
    var duKienQuyDoi: Double = 0
    var phanTramHTQuyDoi: Double = 0

    var phanTramTraGop: Double = 0
    var doanhThuTraGop: Double = 0

    var luotKhach: Double = 0
    var soBill: Double = 0
    var phanTramPVTC: Double = 0

    var tangGiamCungKy: Double = 0
    var coTangGiam: Bool = false
    var tb3Thang: Double = 0

    var soNgayDaQua: Int = 0
    var tongSoNgay: Int = 0
    var phanTramTienDoThang: Double = 0

    init(
        doanhThuThuc: Double = 0,
        targetThuc: Double = 0,
        duKienThuc: Double = 0,
        phanTramHTThuc: Double = 0,
        doanhThuQuyDoi: Double = 0,
        targetQuyDoi: Double = 0,
        duKienQuyDoi: Double = 0,
        phanTramHTQuyDoi: Double = 0,
        phanTramTraGop: Double = 0,
        doanhThuTraGop: Double = 0,
        luotKhach: Double = 0,
        soBill: Double = 0,
        phanTramPVTC: Double = 0,
        tangGiamCungKy: Double = 0,
        coTangGiam: Bool = false,
        tb3Thang: Double = 0,
        soNgayDaQua: Int = 0,
        tongSoNgay: Int = 0,
        phanTramTienDoThang: Double = 0
    ) {
        self.doanhThuThuc = doanhThuThuc
        self.targetThuc = targetThuc
        self.duKienThuc = duKienThuc
        self.phanTramHTThuc = phanTramHTThuc
        self.doanhThuQuyDoi = doanhThuQuyDoi
        self.targetQuyDoi = targetQuyDoi
        self.duKienQuyDoi = duKienQuyDoi
        self.phanTramHTQuyDoi = phanTramHTQuyDoi
        self.phanTramTraGop = phanTramTraGop
        self.doanhThuTraGop = doanhThuTraGop
        self.luotKhach = luotKhach
        self.soBill = soBill
        self.phanTramPVTC = phanTramPVTC
        self.tangGiamCungKy = tangGiamCungKy
        self.coTangGiam = coTangGiam
        self.tb3Thang = tb3Thang
        self.soNgayDaQua = soNgayDaQua
        self.tongSoNgay = tongSoNgay
        self.phanTramTienDoThang = phanTramTienDoThang
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        doanhThuThuc = (try? c.decode(Double.self, forKey: .doanhThuThuc)) ?? 0
        targetThuc = (try? c.decode(Double.self, forKey: .targetThuc)) ?? 0
        duKienThuc = (try? c.decode(Double.self, forKey: .duKienThuc)) ?? 0
        phanTramHTThuc = (try? c.decode(Double.self, forKey: .phanTramHTThuc)) ?? 0
        doanhThuQuyDoi = (try? c.decode(Double.self, forKey: .doanhThuQuyDoi)) ?? 0
        targetQuyDoi = (try? c.decode(Double.self, forKey: .targetQuyDoi)) ?? 0
        duKienQuyDoi = (try? c.decode(Double.self, forKey: .duKienQuyDoi)) ?? 0
        phanTramHTQuyDoi = (try? c.decode(Double.self, forKey: .phanTramHTQuyDoi)) ?? 0
        phanTramTraGop = (try? c.decode(Double.self, forKey: .phanTramTraGop)) ?? 0
        doanhThuTraGop = (try? c.decode(Double.self, forKey: .doanhThuTraGop)) ?? 0
        luotKhach = (try? c.decode(Double.self, forKey: .luotKhach)) ?? 0
        soBill = (try? c.decode(Double.self, forKey: .soBill)) ?? 0
        phanTramPVTC = (try? c.decode(Double.self, forKey: .phanTramPVTC)) ?? 0
        tangGiamCungKy = (try? c.decode(Double.self, forKey: .tangGiamCungKy)) ?? 0
        coTangGiam = (try? c.decode(Bool.self, forKey: .coTangGiam)) ?? (tangGiamCungKy != 0)
        tb3Thang = (try? c.decode(Double.self, forKey: .tb3Thang)) ?? 0
        soNgayDaQua = (try? c.decode(Int.self, forKey: .soNgayDaQua)) ?? 0
        tongSoNgay = (try? c.decode(Int.self, forKey: .tongSoNgay)) ?? 0
        phanTramTienDoThang = (try? c.decode(Double.self, forKey: .phanTramTienDoThang)) ?? 0
    }

    var coDuLieu: Bool {
        doanhThuThuc > 0 || targetThuc > 0 || doanhThuQuyDoi > 0 || targetQuyDoi > 0 || luotKhach > 0 || phanTramTraGop > 0
    }

    /// Chỉ điều chỉnh target để hiển thị/báo cáo. Target quét gốc trong dữ liệu ngày không bị thay đổi.
    func apDungPhanTramTarget(_ phanTram: Double, cheDo: LoaiCheDoDoanhThu) -> ThongTinDoanhThu {
        let tyLe = min(2.0, max(0.5, phanTram / 100.0))
        guard abs(tyLe - 1.0) > 0.0001 else { return self }
        var kq = self
        if kq.targetThuc > 0 { kq.targetThuc *= tyLe }
        if kq.targetQuyDoi > 0 { kq.targetQuyDoi *= tyLe }
        kq.phanTramHTThuc = kq.targetThuc > 0 ? (kq.doanhThuThuc / kq.targetThuc) * 100.0 : 0
        // Realtime hiển thị "% HT target ngày", vì vậy phải lấy doanh thu hiện tại
        // chia target ngày. Chỉ lũy kế mới dùng doanh thu dự kiến cuối tháng.
        let coSoQD = cheDo == .realtime
            ? kq.doanhThuQuyDoi
            : (kq.duKienQuyDoi > 0 ? kq.duKienQuyDoi : kq.doanhThuQuyDoi)
        kq.phanTramHTQuyDoi = kq.targetQuyDoi > 0 ? (coSoQD / kq.targetQuyDoi) * 100.0 : 0
        return kq
    }

    /// % Quy đổi = (DT Quy đổi - DT Thực) / DT Thực * 100
    var phanTramQuyDoi: Double {
        guard doanhThuThuc > 0, doanhThuQuyDoi > 0 else { return 0 }
        return ((doanhThuQuyDoi - doanhThuThuc) / doanhThuThuc) * 100.0
    }

    /// % Hoàn thành Doanh thu thực
    var phanTramHTThucHienThi: Double {
        if phanTramHTThuc > 0 { return phanTramHTThuc }
        if targetThuc > 0, doanhThuThuc > 0 {
            return (doanhThuThuc / targetThuc) * 100.0
        }
        return 0
    }

    /// % Hoàn thành QĐ dự kiến (hiển thị trực tiếp con số quét được từ ảnh)
    var phanTramHTQDDuKienHienThi: Double {
        if phanTramHTQuyDoi > 0 { return phanTramHTQuyDoi }
        if duKienQuyDoi > 0, targetQuyDoi > 0 {
            return (duKienQuyDoi / targetQuyDoi) * 100.0
        }
        if targetQuyDoi > 0, doanhThuQuyDoi > 0 {
            return (doanhThuQuyDoi / targetQuyDoi) * 100.0
        }
        if phanTramHTThuc > 0 { return phanTramHTThuc }
        if targetThuc > 0, doanhThuThuc > 0 {
            return (doanhThuThuc / targetThuc) * 100.0
        }
        return 0
    }

    /// Realtime luôn là doanh thu hiện tại / target ngày. Không được lấy dự kiến
    /// cuối tháng vì có thể làm tỷ lệ nhảy lên hàng nghìn phần trăm.
    func phanTramHTQuyDoiHienThi(cheDo: LoaiCheDoDoanhThu) -> Double {
        if cheDo == .realtime {
            guard targetQuyDoi > 0 else { return 0 }
            return (doanhThuQuyDoi / targetQuyDoi) * 100.0
        }
        return phanTramHTQDDuKienHienThi
    }

    /// Gộp dữ liệu từ ảnh mới quét (ví dụ quét ảnh DT thực rồi quét tiếp ảnh DT quy đổi)
    func gop(voi moi: ThongTinDoanhThu, laRealtime: Bool = false) -> ThongTinDoanhThu {
        var kq = self
        if moi.doanhThuThuc > 0 { kq.doanhThuThuc = moi.doanhThuThuc }
        if moi.targetThuc > 0 { kq.targetThuc = moi.targetThuc }
        if moi.duKienThuc > 0 { kq.duKienThuc = moi.duKienThuc }
        if moi.phanTramHTThuc > 0 { kq.phanTramHTThuc = moi.phanTramHTThuc }

        if moi.doanhThuQuyDoi > 0 { kq.doanhThuQuyDoi = moi.doanhThuQuyDoi }
        if moi.targetQuyDoi > 0 { kq.targetQuyDoi = moi.targetQuyDoi }
        if moi.duKienQuyDoi > 0 { kq.duKienQuyDoi = moi.duKienQuyDoi }
        if moi.phanTramHTQuyDoi > 0 { kq.phanTramHTQuyDoi = moi.phanTramHTQuyDoi }

        if moi.phanTramTraGop > 0 { kq.phanTramTraGop = moi.phanTramTraGop }
        if moi.doanhThuTraGop > 0 { kq.doanhThuTraGop = moi.doanhThuTraGop }

        if moi.luotKhach > 0 { kq.luotKhach = moi.luotKhach }
        if moi.soBill > 0 { kq.soBill = moi.soBill }
        if moi.phanTramPVTC > 0 { kq.phanTramPVTC = moi.phanTramPVTC }

        if moi.coTangGiam || moi.tangGiamCungKy != 0 {
            kq.tangGiamCungKy = moi.tangGiamCungKy
            kq.coTangGiam = true
        }
        if moi.tb3Thang > 0 { kq.tb3Thang = moi.tb3Thang }

        if moi.soNgayDaQua > 0 { kq.soNgayDaQua = moi.soNgayDaQua }
        if moi.tongSoNgay > 0 { kq.tongSoNgay = moi.tongSoNgay }
        if moi.phanTramTienDoThang > 0 { kq.phanTramTienDoThang = moi.phanTramTienDoThang }
        return kq
    }
}

struct DongThiDua: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var tenNganhHangGoc: String
    var tenNganhHang: String
    var loaiChiTieu: LoaiChiTieuThiDua
    var thucHien: Double
    var target: Double
    var phanTramHTGoc: Double?
    var phanTramDuBaoGoc: Double?
    var duKienGoc: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case tenNganhHangGoc
        case tenNganhHang
        case loaiChiTieu
        case thucHien
        case target
        case phanTramHTGoc
        case phanTramDuBaoGoc
        case duKienGoc
    }

    init(
        id: UUID = UUID(),
        tenNganhHangGoc: String? = nil,
        tenNganhHang: String,
        loaiChiTieu: LoaiChiTieuThiDua,
        thucHien: Double,
        target: Double,
        phanTramHTGoc: Double? = nil,
        phanTramDuBaoGoc: Double? = nil,
        duKienGoc: Double? = nil
    ) {
        self.id = id
        let goc = KhoDuLieu.chuanHoaTenMonThiDuaChuan(tenNganhHangGoc ?? tenNganhHang)
        self.tenNganhHangGoc = goc
        self.tenNganhHang = KhoDuLieu.apDungLocTuCaiDat(goc)
        self.loaiChiTieu = loaiChiTieu
        self.thucHien = thucHien
        self.target = target
        self.phanTramHTGoc = phanTramHTGoc
        self.phanTramDuBaoGoc = phanTramDuBaoGoc
        self.duKienGoc = duKienGoc
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let uuid = try? c.decode(UUID.self, forKey: .id) {
            id = uuid
        } else if let str = try? c.decode(String.self, forKey: .id), let uuid = UUID(uuidString: str) {
            id = uuid
        } else {
            id = UUID()
        }
        let ten = (try? c.decode(String.self, forKey: .tenNganhHang)) ?? ""
        let gocThuc = (try? c.decode(String.self, forKey: .tenNganhHangGoc)) ?? ten
        let gocSach = KhoDuLieu.chuanHoaTenMonThiDuaChuan(gocThuc.isEmpty ? ten : gocThuc)
        tenNganhHangGoc = gocSach.isEmpty ? gocThuc : gocSach
        let tenSach = KhoDuLieu.chuanHoaTenMonThiDuaChuan(ten.isEmpty ? tenNganhHangGoc : ten)
        tenNganhHang = tenSach.isEmpty ? tenNganhHangGoc : tenSach
        loaiChiTieu = (try? c.decode(LoaiChiTieuThiDua.self, forKey: .loaiChiTieu)) ?? .doanhThu
        thucHien = (try? c.decode(Double.self, forKey: .thucHien)) ?? 0
        target = (try? c.decode(Double.self, forKey: .target)) ?? 0
        phanTramHTGoc = try? c.decode(Double.self, forKey: .phanTramHTGoc)
        phanTramDuBaoGoc = try? c.decode(Double.self, forKey: .phanTramDuBaoGoc)
        duKienGoc = try? c.decode(Double.self, forKey: .duKienGoc)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id.uuidString.lowercased(), forKey: .id)
        try c.encode(tenNganhHangGoc, forKey: .tenNganhHangGoc)
        try c.encode(tenNganhHang, forKey: .tenNganhHang)
        try c.encode(loaiChiTieu, forKey: .loaiChiTieu)
        try c.encode(thucHien, forKey: .thucHien)
        try c.encode(target, forKey: .target)
        try c.encodeIfPresent(phanTramHTGoc, forKey: .phanTramHTGoc)
        try c.encodeIfPresent(phanTramDuBaoGoc, forKey: .phanTramDuBaoGoc)
        try c.encodeIfPresent(duKienGoc, forKey: .duKienGoc)
    }

    var chenhLech: Double {
        thucHien - target
    }

    var conThieu: Double {
        max(0, target - thucHien)
    }

    var vuotMuc: Double {
        max(0, thucHien - target)
    }

    var phanTramHT: Double {
        if target > 0.0001 {
            let htTinh = (thucHien / target) * 100.0
            let nguong: Double = (loaiChiTieu == .soLuong && target <= 25) ? 3.5 : 1.2
            if let goc = phanTramHTGoc, abs(goc) > 0.0001, abs(htTinh - goc) <= nguong {
                return goc
            }
            return htTinh
        }
        return phanTramHTGoc ?? 0
    }

    /// Doanh thu / Số lượng dự kiến cuối tháng (ưu tiên con số quét trực tiếp từ ô DT DỰ KIẾN / SL DỰ KIẾN trên ảnh Lũy kế)
    var duKien: Double {
        if let dk = duKienGoc, dk > 0 {
            if let htGoc = phanTramHTGoc, htGoc > 0.1, target > 0.0001 {
                let htMoi = (thucHien / target) * 100.0
                if abs(htMoi - htGoc) > 1.5 {
                    let uoc = (target * phanTramDuBao) / 100.0
                    return loaiChiTieu == .soLuong ? uoc.rounded() : ((uoc * 100).rounded() / 100)
                }
            }
            return dk
        }
        if target > 0.0001, phanTramDuBao > 0 {
            let uoc = (target * phanTramDuBao) / 100.0
            return loaiChiTieu == .soLuong ? uoc.rounded() : ((uoc * 100).rounded() / 100)
        }
        let uoc = thucHien * TienIchNgay.heSoDuBaoThang()
        return loaiChiTieu == .soLuong ? uoc.rounded() : ((uoc * 100).rounded() / 100)
    }

    var chenhLechDuKien: Double {
        duKien - target
    }

    var conThieuDuKien: Double {
        max(0, target - duKien)
    }

    var vuotMucDuKien: Double {
        max(0, duKien - target)
    }

    var phanTramDuBao: Double {
        if let goc = phanTramDuBaoGoc, abs(goc) > 0.0001 {
            if let htGoc = phanTramHTGoc, abs(htGoc) > 0.1, target > 0.0001 {
                let htMoi = (thucHien / target) * 100.0
                if abs(htMoi - htGoc) > 1.5 {
                    let tyLe = goc / htGoc
                    return htMoi * tyLe
                }
            }
            return goc
        }
        if let goc = phanTramDuBaoGoc, abs(goc) <= 0.0001, abs(thucHien) <= 0.0001 {
            return 0
        }
        if let dk = duKienGoc, dk > 0, target > 0.0001 {
            return (dk / target) * 100.0
        }
        return phanTramHT * TienIchNgay.heSoDuBaoThang()
    }

    var daDat: Bool {
        phanTramHT >= 99.995
    }

    var daHoanThanhDuBao: Bool {
        phanTramDuBao >= 99.995
    }
}

enum PhuongPhapQuetThiDua: Int, Codable, CaseIterable {
    case phuongPhap1 = 0 // Phương pháp 1 (Mặc định: Thẻ tiến độ / Bảng 4 cột T11)
    case phuongPhap2 = 1 // Phương pháp 2 (Lũy kế: Bảng 6 cột | Realtime theo ngày: Bảng 5 cột)
    case phuongPhap3 = 2 // Phương pháp 3 (Quét ảnh với Gemini Flash AI)

    var tieuDe: String {
        switch self {
        case .phuongPhap1:
            return "Phương pháp 1 (Thẻ / Bảng T11)"
        case .phuongPhap2:
            return "Phương pháp 2 (Bảng 5-6 cột)"
        case .phuongPhap3:
            return "Phương pháp 3 (Gemini Flash)"
        }
    }
}

struct CaiDatDMX: Codable {
    static let khoaKhongChonMonThiDua = "__KHONG_CHON_MON_NAO__"
    static let geminiKeyMacDinh = "AIzaSyBLV7N_qUxSuiJ3B3FETmj2Ta67CKeVKWo"
    static let geminiModelMacDinh = "gemini-2.5-flash"

    var kieuHienThi: KieuHienThiBaoCao = .bangChiTiet
    var phuongPhapQuetThiDua: PhuongPhapQuetThiDua = .phuongPhap1
    var danhSachCumTuLocBo: [String] = []
    var soCotXuatAnh: Int = 3
    var danhSachNhanVien: [NhanVienQuanLy] = CaiDatDMX.nhanVienMau
    var chiaTargetNganhHang: [String: [String]] = [:]
    var mucTieuDoanhThuQDThang: [String: Double] = [:]
    var phanTramTargetLuyKe: Double = 100
    var phanTramTargetRealtime: Double = 100
    /// Rỗng nghĩa là theo dõi tất cả. Giá trị được lưu bằng khóa tên chuẩn, không làm mất dữ liệu quét gốc.
    var monThiDuaTheoDoiLuyKe: [String] = []
    var monThiDuaTheoDoiRealtime: [String] = []
    var geminiApiKey: String = CaiDatDMX.geminiKeyMacDinh
    var geminiModel: String = CaiDatDMX.geminiModelMacDinh
    var dungGeminiQuetAnh: Bool = false
    var hienThiNangSuatNhanVien: Bool = true

    enum CodingKeys: String, CodingKey {
        case kieuHienThi
        case phuongPhapQuetThiDua
        case danhSachCumTuLocBo
        case soCotXuatAnh
        case danhSachNhanVien
        case chiaTargetNganhHang
        case mucTieuDoanhThuQDThang
        case phanTramTargetLuyKe
        case phanTramTargetRealtime
        case monThiDuaTheoDoiLuyKe
        case monThiDuaTheoDoiRealtime
        case geminiApiKey
        case geminiModel
        case dungGeminiQuetAnh
        case hienThiNangSuatNhanVien
    }

    static let nhanVienMau: [NhanVienQuanLy] = [
        .init(maNV: "116719", hoTen: "Đinh Thị Quỳnh Nga"),
        .init(maNV: "34922", hoTen: "Đỗ Thị Chanh"),
        .init(maNV: "186532", hoTen: "Đỗ Thị Mỹ Linh"),
        .init(maNV: "285681", hoTen: "Hồ Ngọc Châu Ánh"),
        .init(maNV: "207241", hoTen: "Huỳnh Tấn Thành"),
        .init(maNV: "280417", hoTen: "Huỳnh Thành Đạt"),
        .init(maNV: "23997", hoTen: "Lê Thị Kim Phượng"),
        .init(maNV: "285688", hoTen: "Lê Tuấn"),
        .init(maNV: "194649", hoTen: "Nguyễn Hoàn Điện"),
        .init(maNV: "39665", hoTen: "Nguyễn Hữu Kha"),
        .init(maNV: "23986", hoTen: "Nguyễn Ngọc Đẩu"),
        .init(maNV: "201962", hoTen: "Nguyễn Thị Kim Loan"),
        .init(maNV: "65255", hoTen: "Nguyễn Thị Thu Thảo"),
        .init(maNV: "24939", hoTen: "Phan Hoàng Sơn"),
        .init(maNV: "65257", hoTen: "Phan Thương Vĩnh"),
        .init(maNV: "261423", hoTen: "Trần Nam Tùng"),
        .init(maNV: "293044", hoTen: "Võ Ngọc Vĩ")
    ]

    init(
        kieuHienThi: KieuHienThiBaoCao = .bangChiTiet,
        phuongPhapQuetThiDua: PhuongPhapQuetThiDua = .phuongPhap1,
        danhSachCumTuLocBo: [String] = [],
        soCotXuatAnh: Int = 3,
        danhSachNhanVien: [NhanVienQuanLy] = CaiDatDMX.nhanVienMau,
        chiaTargetNganhHang: [String: [String]] = [:],
        mucTieuDoanhThuQDThang: [String: Double] = [:],
        phanTramTargetLuyKe: Double = 100,
        phanTramTargetRealtime: Double = 100,
        monThiDuaTheoDoiLuyKe: [String] = [],
        monThiDuaTheoDoiRealtime: [String] = [],
        geminiApiKey: String = CaiDatDMX.geminiKeyMacDinh,
        geminiModel: String = CaiDatDMX.geminiModelMacDinh,
        dungGeminiQuetAnh: Bool = false,
        hienThiNangSuatNhanVien: Bool = true
    ) {
        self.kieuHienThi = kieuHienThi
        self.phuongPhapQuetThiDua = phuongPhapQuetThiDua
        self.danhSachCumTuLocBo = danhSachCumTuLocBo
        self.soCotXuatAnh = soCotXuatAnh
        var dsNV = danhSachNhanVien.isEmpty ? Self.nhanVienMau : danhSachNhanVien
        for i in dsNV.indices {
            if dsNV[i].maNV == "65257" && dsNV[i].hoTen.count < 14 {
                dsNV[i].hoTen = "Phan Thương Vĩnh"
            }
        }
        if !dsNV.contains(where: { $0.maNV == "65257" }) {
            dsNV.append(.init(maNV: "65257", hoTen: "Phan Thương Vĩnh"))
        }
        self.danhSachNhanVien = NhanVienQuanLy.sapXepAZ(dsNV)
        self.chiaTargetNganhHang = chiaTargetNganhHang
        self.mucTieuDoanhThuQDThang = mucTieuDoanhThuQDThang
        self.phanTramTargetLuyKe = min(200, max(50, phanTramTargetLuyKe))
        self.phanTramTargetRealtime = min(200, max(50, phanTramTargetRealtime))
        self.monThiDuaTheoDoiLuyKe = monThiDuaTheoDoiLuyKe
        self.monThiDuaTheoDoiRealtime = monThiDuaTheoDoiRealtime
        self.geminiApiKey = geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Self.geminiKeyMacDinh : geminiApiKey
        self.geminiModel = geminiModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Self.geminiModelMacDinh : geminiModel
        self.dungGeminiQuetAnh = dungGeminiQuetAnh
        self.hienThiNangSuatNhanVien = hienThiNangSuatNhanVien
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kieuHienThi = (try? c.decode(KieuHienThiBaoCao.self, forKey: .kieuHienThi)) ?? .bangChiTiet
        if let pp = try? c.decode(PhuongPhapQuetThiDua.self, forKey: .phuongPhapQuetThiDua) {
            phuongPhapQuetThiDua = pp
        } else if UserDefaults.standard.object(forKey: "dmx.caiDat.phuongPhapQuetThiDua") != nil,
                  let luuPP = PhuongPhapQuetThiDua(rawValue: UserDefaults.standard.integer(forKey: "dmx.caiDat.phuongPhapQuetThiDua")) {
            phuongPhapQuetThiDua = luuPP
        } else {
            phuongPhapQuetThiDua = .phuongPhap1
        }
        danhSachCumTuLocBo = (try? c.decode([String].self, forKey: .danhSachCumTuLocBo)) ?? []
        let cot = (try? c.decode(Int.self, forKey: .soCotXuatAnh)) ?? 3
        soCotXuatAnh = (cot >= 1 && cot <= 4) ? cot : 3
        let dsNV = (try? c.decode([NhanVienQuanLy].self, forKey: .danhSachNhanVien)) ?? []
        danhSachNhanVien = NhanVienQuanLy.sapXepAZ(dsNV.isEmpty ? Self.nhanVienMau : dsNV)
        chiaTargetNganhHang = (try? c.decode([String: [String]].self, forKey: .chiaTargetNganhHang)) ?? [:]
        mucTieuDoanhThuQDThang = (try? c.decode([String: Double].self, forKey: .mucTieuDoanhThuQDThang)) ?? [:]
        phanTramTargetLuyKe = min(200, max(50, (try? c.decode(Double.self, forKey: .phanTramTargetLuyKe)) ?? 100))
        phanTramTargetRealtime = min(200, max(50, (try? c.decode(Double.self, forKey: .phanTramTargetRealtime)) ?? 100))
        monThiDuaTheoDoiLuyKe = (try? c.decode([String].self, forKey: .monThiDuaTheoDoiLuyKe)) ?? []
        monThiDuaTheoDoiRealtime = (try? c.decode([String].self, forKey: .monThiDuaTheoDoiRealtime)) ?? []
        let rawKey = (try? c.decode(String.self, forKey: .geminiApiKey))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let luuKeyUD = UserDefaults.standard.string(forKey: "dmx.caiDat.geminiApiKey")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !luuKeyUD.isEmpty && luuKeyUD != Self.geminiKeyMacDinh {
            geminiApiKey = luuKeyUD
        } else if !rawKey.isEmpty && rawKey != Self.geminiKeyMacDinh {
            geminiApiKey = rawKey
        } else if !luuKeyUD.isEmpty {
            geminiApiKey = luuKeyUD
        } else {
            geminiApiKey = Self.geminiKeyMacDinh
        }
        let rawModel = (try? c.decode(String.self, forKey: .geminiModel))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        geminiModel = rawModel.isEmpty ? Self.geminiModelMacDinh : rawModel
        dungGeminiQuetAnh = (try? c.decode(Bool.self, forKey: .dungGeminiQuetAnh)) ?? (phuongPhapQuetThiDua == .phuongPhap3)
        if let hienNS = try? c.decode(Bool.self, forKey: .hienThiNangSuatNhanVien) {
            hienThiNangSuatNhanVien = hienNS
        } else if UserDefaults.standard.object(forKey: "dmx.caiDat.hienThiNangSuatNhanVien") != nil {
            hienThiNangSuatNhanVien = UserDefaults.standard.bool(forKey: "dmx.caiDat.hienThiNangSuatNhanVien")
        } else {
            hienThiNangSuatNhanVien = true
        }
    }

    var geminiApiKeyHieuLuc: String {
        let k = geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return k.isEmpty ? Self.geminiKeyMacDinh : k
    }

    func phanTramTarget(cho cheDo: LoaiCheDoDoanhThu) -> Double {
        cheDo == .luyKe ? phanTramTargetLuyKe : phanTramTargetRealtime
    }

    func khoaMonTheoDoi(cho cheDo: LoaiCheDoDoanhThu) -> [String] {
        cheDo == .luyKe ? monThiDuaTheoDoiLuyKe : monThiDuaTheoDoiRealtime
    }

    mutating func ganKhoaMonTheoDoi(_ danhSach: [String], cho cheDo: LoaiCheDoDoanhThu) {
        if cheDo == .luyKe { monThiDuaTheoDoiLuyKe = danhSach }
        else { monThiDuaTheoDoiRealtime = danhSach }
    }
}

struct DuBaoQuyDoiThang: Hashable {
    var mucTieuThang: Double
    var soNgayTrongThang: Int
    var mucTieuMoiNgay: Double
    var soNgayCoRealtime: Int
    var tongDTThucRealtime: Double
    var tongDTQDRealtime: Double
    var trungBinhThucMoiNgay: Double
    var trungBinhQDMoiNgay: Double
    var duKienThucCuoiThang: Double
    var duKienQDCuoiThang: Double
    var phanTramHTQDDuKien: Double
    var phanTramQuyDoiDuKien: Double
    var chenhLechDuKienCuoiThang: Double { duKienQDCuoiThang - mucTieuThang }
    var daHoanThanhDuKien: Bool { phanTramHTQDDuKien >= 99.995 }
}

struct DuLieuRealtimeNgayTrongThang: Hashable {
    var ngay: Date
    var khoaNgay: String
    var ngayTrongThang: Int
    var doanhThu: ThongTinDoanhThu

    var doanhThuThuc: Double { doanhThu.doanhThuThuc }
    var targetThuc: Double { doanhThu.targetThuc }
    var doanhThuQuyDoi: Double { doanhThu.doanhThuQuyDoi }
    var targetQuyDoi: Double { doanhThu.targetQuyDoi }
    var phanTramQuyDoi: Double { doanhThu.phanTramQuyDoi }
    var phanTramTraGop: Double { doanhThu.phanTramTraGop }
    var luotKhach: Double { doanhThu.luotKhach }
    var soBill: Double { doanhThu.soBill }
    var coDuLieu: Bool {
        doanhThu.doanhThuThuc > 0 || doanhThu.doanhThuQuyDoi > 0 || doanhThu.luotKhach > 0 || doanhThu.soBill > 0
    }
}

struct DuLieuNgayDMX: Codable {
    var khoaNgay: String
    var capNhatLuc: String
    var thongTinDonVi: String
    var doanhThu: ThongTinDoanhThu
    var doanhThuRealtime: ThongTinDoanhThu = ThongTinDoanhThu()
    var danhSachThiDua: [DongThiDua]
    var danhSachThiDuaRealtime: [DongThiDua] = []
    var thiDuaNhanVien: [String: [String: Double]] = [:]
    var thiDuaNhanVienRealtime: [String: [String: Double]] = [:]
    var doanhThuNhanVien: [DoanhThuNhanVienItem] = []
    var doanhThuNhanVienRealtime: [DoanhThuNhanVienItem] = []
    var sucKhoeBoSungNhanVien: [String: DuLieuSucKhoeBoSungNV] = [:]

    init(
        khoaNgay: String,
        capNhatLuc: String,
        thongTinDonVi: String,
        doanhThu: ThongTinDoanhThu,
        doanhThuRealtime: ThongTinDoanhThu = ThongTinDoanhThu(),
        danhSachThiDua: [DongThiDua],
        danhSachThiDuaRealtime: [DongThiDua] = [],
        thiDuaNhanVien: [String: [String: Double]] = [:],
        thiDuaNhanVienRealtime: [String: [String: Double]] = [:],
        doanhThuNhanVien: [DoanhThuNhanVienItem] = [],
        doanhThuNhanVienRealtime: [DoanhThuNhanVienItem] = [],
        sucKhoeBoSungNhanVien: [String: DuLieuSucKhoeBoSungNV] = [:]
    ) {
        self.khoaNgay = khoaNgay
        self.capNhatLuc = capNhatLuc
        self.thongTinDonVi = thongTinDonVi
        self.doanhThu = doanhThu
        self.doanhThuRealtime = doanhThuRealtime
        self.danhSachThiDua = danhSachThiDua
        self.danhSachThiDuaRealtime = danhSachThiDuaRealtime
        self.thiDuaNhanVien = thiDuaNhanVien
        self.thiDuaNhanVienRealtime = thiDuaNhanVienRealtime
        self.doanhThuNhanVien = doanhThuNhanVien
        self.doanhThuNhanVienRealtime = doanhThuNhanVienRealtime
        self.sucKhoeBoSungNhanVien = sucKhoeBoSungNhanVien
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        khoaNgay = (try? c.decode(String.self, forKey: .khoaNgay)) ?? ""
        capNhatLuc = (try? c.decode(String.self, forKey: .capNhatLuc)) ?? ""
        thongTinDonVi = (try? c.decode(String.self, forKey: .thongTinDonVi)) ?? ""
        doanhThu = (try? c.decode(ThongTinDoanhThu.self, forKey: .doanhThu)) ?? ThongTinDoanhThu()
        doanhThuRealtime = (try? c.decode(ThongTinDoanhThu.self, forKey: .doanhThuRealtime)) ?? ThongTinDoanhThu()
        danhSachThiDua = (try? c.decode([DongThiDua].self, forKey: .danhSachThiDua)) ?? []
        danhSachThiDuaRealtime = (try? c.decode([DongThiDua].self, forKey: .danhSachThiDuaRealtime)) ?? []
        thiDuaNhanVien = (try? c.decode([String: [String: Double]].self, forKey: .thiDuaNhanVien)) ?? [:]
        thiDuaNhanVienRealtime = (try? c.decode([String: [String: Double]].self, forKey: .thiDuaNhanVienRealtime)) ?? [:]
        doanhThuNhanVien = (try? c.decode([DoanhThuNhanVienItem].self, forKey: .doanhThuNhanVien)) ?? []
        doanhThuNhanVienRealtime = (try? c.decode([DoanhThuNhanVienItem].self, forKey: .doanhThuNhanVienRealtime)) ?? []
        sucKhoeBoSungNhanVien = (try? c.decode([String: DuLieuSucKhoeBoSungNV].self, forKey: .sucKhoeBoSungNhanVien)) ?? [:]
    }

    func danhSachThiDua(theo cheDo: LoaiCheDoDoanhThu) -> [DongThiDua] {
        switch cheDo {
        case .luyKe: return danhSachThiDua
        case .realtime: return danhSachThiDuaRealtime
        }
    }

    mutating func ganDanhSachThiDua(_ ds: [DongThiDua], theo cheDo: LoaiCheDoDoanhThu) {
        switch cheDo {
        case .luyKe: danhSachThiDua = ds
        case .realtime: danhSachThiDuaRealtime = ds
        }
    }

    func thiDuaNhanVien(theo cheDo: LoaiCheDoDoanhThu) -> [String: [String: Double]] {
        switch cheDo {
        case .luyKe: return thiDuaNhanVien
        case .realtime: return thiDuaNhanVienRealtime
        }
    }

    mutating func ganThiDuaNhanVien(_ bang: [String: [String: Double]], theo cheDo: LoaiCheDoDoanhThu) {
        switch cheDo {
        case .luyKe: thiDuaNhanVien = bang
        case .realtime: thiDuaNhanVienRealtime = bang
        }
    }

    func doanhThuNhanVien(theo cheDo: LoaiCheDoDoanhThu) -> [DoanhThuNhanVienItem] {
        switch cheDo {
        case .luyKe: return doanhThuNhanVien
        case .realtime: return doanhThuNhanVienRealtime
        }
    }

    mutating func ganDoanhThuNhanVien(_ ds: [DoanhThuNhanVienItem], theo cheDo: LoaiCheDoDoanhThu) {
        switch cheDo {
        case .luyKe: doanhThuNhanVien = ds
        case .realtime: doanhThuNhanVienRealtime = ds
        }
    }
}

final class ThuMucDuLieu {
    static let dungChung = ThuMucDuLieu()

    let thuMuc: URL
    func tepNgay(choSieuThi id: String) -> URL {
        guard !id.isEmpty else { return thuMuc.appendingPathComponent("du-lieu-dmx-v3.json") }
        return thuMuc.appendingPathComponent("du-lieu-dmx-\(BoNhoSieuThiDMX.tenTepAnToan(id))-v4.json")
    }
    func tepCaiDat(choSieuThi id: String) -> URL {
        guard !id.isEmpty else { return thuMuc.appendingPathComponent("cai-dat-dmx-v3.json") }
        return thuMuc.appendingPathComponent("cai-dat-dmx-\(BoNhoSieuThiDMX.tenTepAnToan(id))-v4.json")
    }
    var tepNgay: URL {
        tepNgay(choSieuThi: BoNhoSieuThiDMX.idDangChon)
    }
    var tepCaiDat: URL {
        tepCaiDat(choSieuThi: BoNhoSieuThiDMX.idDangChon)
    }

    /// Không dùng prettyPrinted / sortedKeys để mã hoá JSON nhanh gấp 4 lần, không gây nghẽn CPU
    private let maHoa = JSONEncoder()
    private let giaiMa = JSONDecoder()
    private let hangDoiGhiFile = DispatchQueue(label: "com.thanhduong.tonghopdmx.ghifile", qos: .utility)
    private var congViecGhiNgay: DispatchWorkItem?
    private var congViecGhiCaiDat: DispatchWorkItem?

    private init() {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!

        thuMuc = documents.appendingPathComponent("DuLieuDMX", isDirectory: true)
        try? FileManager.default.createDirectory(at: thuMuc, withIntermediateDirectories: true)
    }

    /// Bản trước lưu chung ở file v3. Khi nâng cấp, sao chép (không di chuyển/xóa)
    /// sang siêu thị mặc định để dữ liệu lịch sử luôn có đường lui cứu hộ.
    @discardableResult
    func khoiPhucDuLieuCuNeuCan(choSieuThi id: String, laMacDinh: Bool) -> Bool {
        guard laMacDinh, !id.isEmpty else { return false }
        let tepNgayCu = thuMuc.appendingPathComponent("du-lieu-dmx-v3.json")
        let tepCaiDatCu = thuMuc.appendingPathComponent("cai-dat-dmx-v3.json")
        let tepNgayMoi = tepNgay(choSieuThi: id)
        let tepCaiDatMoi = tepCaiDat(choSieuThi: id)
        guard let ngayCu = doc([String: DuLieuNgayDMX].self, tu: tepNgayCu), !ngayCu.isEmpty else { return false }

        let ngayMoi = doc([String: DuLieuNgayDMX].self, tu: tepNgayMoi)
        guard ngayMoi == nil || ngayMoi?.isEmpty == true else { return false }
        let daGhiNgay = ghi(ngayCu, vao: tepNgayMoi)
        if let caiDatCu = doc(CaiDatDMX.self, tu: tepCaiDatCu) {
            _ = ghi(caiDatCu, vao: tepCaiDatMoi)
        }
        return daGhiNgay
    }

    func doc<T: Decodable>(_ loai: T.Type, tu tep: URL) -> T? {
        guard let duLieu = try? Data(contentsOf: tep) else { return nil }
        return try? giaiMa.decode(loai, from: duLieu)
    }

    @discardableResult
    func ghi<T: Encodable>(_ giaTri: T, vao tep: URL) -> Bool {
        do {
            let duLieu = try maHoa.encode(giaTri)
            try duLieu.write(to: tep, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    /// Ghi dữ liệu các ngày xuống đĩa trên luồng nền (debounce 0.35s) để tuyệt đối không làm đơ giao diện chính
    func ghiNgayBatDongBo(_ cacNgay: [String: DuLieuNgayDMX]) {
        let banSao = cacNgay
        let tep = tepNgay
        hangDoiGhiFile.async { [weak self] in
            guard let self else { return }
            self.congViecGhiNgay?.cancel()
            let cv = DispatchWorkItem { [weak self] in
                guard let self else { return }
                _ = self.ghi(banSao, vao: tep)
            }
            self.congViecGhiNgay = cv
            self.hangDoiGhiFile.asyncAfter(deadline: .now() + 0.35, execute: cv)
        }
    }

    /// Ghi dữ liệu cài đặt xuống đĩa trên luồng nền (debounce 0.25s)
    func ghiCaiDatBatDongBo(_ caiDat: CaiDatDMX) {
        let banSao = caiDat
        let tep = tepCaiDat
        hangDoiGhiFile.async { [weak self] in
            guard let self else { return }
            self.congViecGhiCaiDat?.cancel()
            let cv = DispatchWorkItem { [weak self] in
                guard let self else { return }
                _ = self.ghi(banSao, vao: tep)
            }
            self.congViecGhiCaiDat = cv
            self.hangDoiGhiFile.asyncAfter(deadline: .now() + 0.25, execute: cv)
        }
    }
}

final class KhoDuLieu {
    static let dungChung = KhoDuLieu()

    private let khoaTruyCap = NSRecursiveLock()
    private(set) var cacNgay: [String: DuLieuNgayDMX] = [:]
    var caiDat = CaiDatDMX()

    /// Bộ nhớ đệm trong RAM giúp chuyển đổi qua lại giữa các tab tức thì (0ms), không phải chạy lại Regex hay vòng lặp tổng hợp nhiều ngày
    private(set) var phienBanDuLieu: Int = 1
    private var boNhoDemDuLieuNgay: [String: DuLieuNgayDMX] = [:]
    private var boNhoDemMatHangThang: [String: [DongThiDua]] = [:]
    private var boNhoDemThucHienNVThang: [String: [String: [String: Double]]] = [:]
    private var boNhoDemTongHopNV: [String: [TongHopNhanVien]] = [:]
    private var boNhoDemBaoCaoSucKhoe: [String: BaoCaoSucKhoeDoiNgu] = [:]
    private var boNhoDemRealtimeThang: [String: [DuLieuRealtimeNgayTrongThang]] = [:]
    private var boNhoDemDuBaoThang: [String: DuBaoQuyDoiThang] = [:]
    private var boNhoDemDTLuyKeThang: [String: ThongTinDoanhThu] = [:]
    private var boNhoDemDTNVLuyKeThang: [String: [DoanhThuNhanVienItem]] = [:]
    private var boNhoSieuThi: [String: (caiDat: CaiDatDMX, cacNgay: [String: DuLieuNgayDMX])] = [:]

    private static let khoaBoNhoDemTinh = NSLock()
    private static var danhSachCumTuLocBoTinh: [String] = []
    private static var boNhoDemKhoaSoSanh: [String: String] = [:]
    private static var boNhoDemLocTen: [String: String] = [:]
    private static var boNhoDemTenChuan: [String: String] = [:]
    private static var boNhoDemKhoaCoBan: [String: String] = [:]
    private static var boNhoDemKhoaLienMach: [String: String] = [:]
    private static var boNhoDemKhoaLMKhongThang: [String: String] = [:]

    private static let khoaLuuMucDaXoa = "dmx.cacKhoaMucDaXoa.v1"
    private var cacKhoaMucDaXoa: Set<String> = {
        let mang = UserDefaults.standard.stringArray(forKey: "dmx.cacKhoaMucDaXoa.v1") ?? []
        return Set(mang)
    }()

    private func luuTapKhoaMucDaXoa() {
        UserDefaults.standard.set(Array(cacKhoaMucDaXoa), forKey: Self.khoaLuuMucDaXoa)
    }

    private func apDungCoXoa(vao dl: inout DuLieuNgayDMX) {
        guard !cacKhoaMucDaXoa.isEmpty else { return }
        let khoa = dl.khoaNgay
        let tienTo = String(khoa.prefix(7))
        if cacKhoaMucDaXoa.contains("dt_lk|\(tienTo)") {
            dl.doanhThu = ThongTinDoanhThu()
        }
        if cacKhoaMucDaXoa.contains("dt_rt|\(khoa)") {
            dl.doanhThuRealtime = ThongTinDoanhThu()
        }
        if cacKhoaMucDaXoa.contains("td_0|\(tienTo)") {
            dl.danhSachThiDua = []
        }
        if cacKhoaMucDaXoa.contains("td_1|\(khoa)") {
            dl.danhSachThiDuaRealtime = []
        }
        if cacKhoaMucDaXoa.contains("nv_dt|\(tienTo)") {
            dl.doanhThuNhanVien = []
            dl.doanhThuNhanVienRealtime = []
            dl.sucKhoeBoSungNhanVien = [:]
        }
        if cacKhoaMucDaXoa.contains("nv_td|\(tienTo)") {
            dl.thiDuaNhanVien = [:]
            dl.thiDuaNhanVienRealtime = [:]
        }
        let tienToNVOne = "nv_one|\(tienTo)|"
        let maNVDaXoa = cacKhoaMucDaXoa.compactMap { item -> String? in
            guard item.hasPrefix(tienToNVOne) else { return nil }
            return String(item.dropFirst(tienToNVOne.count))
        }
        if !maNVDaXoa.isEmpty {
            let tapMaXoa = Set(maNVDaXoa)
            dl.doanhThuNhanVien.removeAll { tapMaXoa.contains(Self.chuanHoaMaNV($0.maNV)) }
            dl.doanhThuNhanVienRealtime.removeAll { tapMaXoa.contains(Self.chuanHoaMaNV($0.maNV)) }
            for ma in tapMaXoa {
                dl.sucKhoeBoSungNhanVien.removeValue(forKey: ma)
                for kMon in Array(dl.thiDuaNhanVien.keys) {
                    dl.thiDuaNhanVien[kMon]?.removeValue(forKey: ma)
                }
                for kMon in Array(dl.thiDuaNhanVienRealtime.keys) {
                    dl.thiDuaNhanVienRealtime[kMon]?.removeValue(forKey: ma)
                }
            }
        }
    }

    private init() {
        doc()
    }

    /// Lấy bản sao an toàn của toàn bộ dữ liệu để đồng bộ nền mà không tranh chấp bộ nhớ với luồng chính
    func layBanSaoAnToan() -> (caiDat: CaiDatDMX, cacNgay: [String: DuLieuNgayDMX]) {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        return (caiDat, cacNgay)
    }

    /// Lấy bản sao cài đặt an toàn cho các luồng quét ảnh OCR nền
    func layCaiDatAnToan() -> CaiDatDMX {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        return caiDat
    }

    private func xoaBoNhoDem(xoaonLocTen: Bool = false) {
        khoaTruyCap.lock()
        phienBanDuLieu &+= 1
        let cumTuHienTai = caiDat.danhSachCumTuLocBo
        boNhoDemDuLieuNgay.removeAll(keepingCapacity: true)
        boNhoDemMatHangThang.removeAll(keepingCapacity: true)
        boNhoDemThucHienNVThang.removeAll(keepingCapacity: true)
        boNhoDemTongHopNV.removeAll(keepingCapacity: true)
        boNhoDemBaoCaoSucKhoe.removeAll(keepingCapacity: true)
        boNhoDemRealtimeThang.removeAll(keepingCapacity: true)
        boNhoDemDuBaoThang.removeAll(keepingCapacity: true)
        boNhoDemDTLuyKeThang.removeAll(keepingCapacity: true)
        boNhoDemDTNVLuyKeThang.removeAll(keepingCapacity: true)
        khoaTruyCap.unlock()
        Self.khoaBoNhoDemTinh.lock()
        Self.danhSachCumTuLocBoTinh = cumTuHienTai
        if xoaonLocTen {
            Self.boNhoDemLocTen.removeAll(keepingCapacity: true)
        }
        Self.khoaBoNhoDemTinh.unlock()
    }

    func doc() {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let thuMuc = ThuMucDuLieu.dungChung
        if let cd = thuMuc.doc(CaiDatDMX.self, tu: thuMuc.tepCaiDat) {
            caiDat = cd
        } else {
            caiDat = CaiDatDMX()
        }
        Self.khoaBoNhoDemTinh.lock()
        Self.danhSachCumTuLocBoTinh = caiDat.danhSachCumTuLocBo
        Self.boNhoDemLocTen.removeAll(keepingCapacity: true)
        Self.khoaBoNhoDemTinh.unlock()

        if var giaTri = thuMuc.doc([String: DuLieuNgayDMX].self, tu: thuMuc.tepNgay) {
            for (khoa, var dl) in giaTri {
                if !dl.danhSachThiDua.isEmpty {
                    dl.danhSachThiDua = Self.gopDanhSachThiDua(cu: [], moi: dl.danhSachThiDua)
                }
                if !dl.danhSachThiDuaRealtime.isEmpty {
                    dl.danhSachThiDuaRealtime = Self.gopDanhSachThiDua(cu: [], moi: dl.danhSachThiDuaRealtime)
                }
                dl.khoaNgay = khoa
                apDungCoXoa(vao: &dl)
                giaTri[khoa] = dl
            }
            cacNgay = giaTri
        } else {
            cacNgay = [:]
        }
        xoaBoNhoDem(xoaonLocTen: true)
    }

    /// Chuyển dữ liệu bằng RAM/ổ máy trước, không chờ mạng. Mỗi lần rời một siêu thị
    /// đều cập nhật snapshot mới nhất nên quay lại gần như tức thời.
    func chuyenSieuThiNhanh(tu idCu: String, sang idMoi: String, laMacDinh: Bool) {
        let thuMuc = ThuMucDuLieu.dungChung
        let daKhoiPhuc = thuMuc.khoiPhucDuLieuCuNeuCan(choSieuThi: idMoi, laMacDinh: laMacDinh)

        khoaTruyCap.lock()
        if !idCu.isEmpty && idCu != idMoi {
            boNhoSieuThi[idCu] = (caiDat, cacNgay)
        }
        if !daKhoiPhuc, let daCo = boNhoSieuThi[idMoi] {
            caiDat = daCo.caiDat
            cacNgay = daCo.cacNgay
            xoaBoNhoDem(xoaonLocTen: true)
            khoaTruyCap.unlock()
            return
        }
        khoaTruyCap.unlock()

        let cd = thuMuc.doc(CaiDatDMX.self, tu: thuMuc.tepCaiDat(choSieuThi: idMoi)) ?? CaiDatDMX()
        let ngay = thuMuc.doc([String: DuLieuNgayDMX].self, tu: thuMuc.tepNgay(choSieuThi: idMoi)) ?? [:]
        khoaTruyCap.lock()
        caiDat = cd
        cacNgay = ngay
        boNhoSieuThi[idMoi] = (cd, ngay)
        xoaBoNhoDem(xoaonLocTen: true)
        khoaTruyCap.unlock()
    }

    /// Đọc trước các siêu thị chưa mở trên luồng nền để lần chọn đầu tiên cũng nhanh.
    func napTruocSieuThi(id: String, laMacDinh: Bool) {
        guard !id.isEmpty else { return }
        khoaTruyCap.lock()
        let daCo = boNhoSieuThi[id] != nil
        khoaTruyCap.unlock()
        guard !daCo else { return }
        let thuMuc = ThuMucDuLieu.dungChung
        _ = thuMuc.khoiPhucDuLieuCuNeuCan(choSieuThi: id, laMacDinh: laMacDinh)
        let cd = thuMuc.doc(CaiDatDMX.self, tu: thuMuc.tepCaiDat(choSieuThi: id)) ?? CaiDatDMX()
        let ngay = thuMuc.doc([String: DuLieuNgayDMX].self, tu: thuMuc.tepNgay(choSieuThi: id)) ?? [:]
        khoaTruyCap.lock()
        if boNhoSieuThi[id] == nil { boNhoSieuThi[id] = (cd, ngay) }
        khoaTruyCap.unlock()
    }

    /// Lấy Doanh thu Lũy kế cố định của tháng (mỗi lần nhập ở ngày mới sẽ thay thế cho ngày hôm trước)
    func doanhThuLuyKeThang(cho ngay: Date) -> ThongTinDoanhThu {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let khoa = TienIchNgay.khoa.string(from: ngay)
        if let daDem = boNhoDemDTLuyKeThang[khoa] {
            return daDem
        }
        let tienTo = String(khoa.prefix(7))
        if let hienTai = cacNgay[khoa]?.doanhThu, hienTai.coDuLieu {
            boNhoDemDTLuyKeThang[khoa] = hienTai
            return hienTai
        }
        for k in cacNgay.keys.filter({ $0.hasPrefix(tienTo) }).sorted(by: >) {
            if let dt = cacNgay[k]?.doanhThu, dt.coDuLieu {
                boNhoDemDTLuyKeThang[khoa] = dt
                return dt
            }
        }
        let trong = ThongTinDoanhThu()
        boNhoDemDTLuyKeThang[khoa] = trong
        return trong
    }

    /// Lấy thông số Sức khỏe bổ sung của nhân viên trong tháng
    func sucKhoeBoSungNhanVienThang(cho ngay: Date) -> [String: DuLieuSucKhoeBoSungNV] {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let khoa = TienIchNgay.khoa.string(from: ngay)
        let tienTo = String(khoa.prefix(7))
        var ketQua: [String: DuLieuSucKhoeBoSungNV] = [:]
        for k in cacNgay.keys.filter({ $0.hasPrefix(tienTo) && $0 <= khoa }).sorted() {
            guard let bang = cacNgay[k]?.sucKhoeBoSungNhanVien, !bang.isEmpty else { continue }
            for (ma, info) in bang {
                if let cu = ketQua[ma] {
                    ketQua[ma] = cu.gop(voi: info)
                } else {
                    ketQua[ma] = info
                }
            }
        }
        return ketQua
    }

    /// Lấy Doanh thu QĐ từng tháng trong 6 tháng gần nhất (kết thúc tại tháng của `ngay`) cho 1 nhân viên
    func layDoanhThuQDTheo6ThangGanNhat(
        maNV: String,
        den ngay: Date,
        doanhThuThangHienTai: Double,
        boSung: DuLieuSucKhoeBoSungNV? = nil
    ) -> [(nhanThang: String, giaTri: Double?)] {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let lich = TienIchNgay.lich
        let maChuan = Self.chuanHoaMaNV(maNV)
        var ketQua: [(nhanThang: String, giaTri: Double?)] = []

        for offset in stride(from: -5, through: 0, by: 1) {
            guard let ngayThang = lich.date(byAdding: .month, value: offset, to: ngay) else { continue }
            let nam = lich.component(.year, from: ngayThang)
            let thang = lich.component(.month, from: ngayThang)
            let tienTo = String(format: "%04d-%02d", nam, thang)
            let nhan = String(format: "%02d/%04d", thang, nam)

            if let valBoSung = boSung?.doanhThuQDTungThang[nhan], valBoSung > 0 {
                ketQua.append((nhan, valBoSung))
                continue
            }
            if offset == 0 && doanhThuThangHienTai > 0 {
                ketQua.append((nhan, doanhThuThangHienTai))
                continue
            }

            var giaTriTimThay: Double?
            for k in cacNgay.keys.filter({ $0.hasPrefix(tienTo) }).sorted(by: >) {
                if let ds = cacNgay[k]?.doanhThuNhanVien,
                   let item = ds.first(where: { Self.chuanHoaMaNV($0.maNV) == maChuan }),
                   item.doanhThuQD > 0 {
                    giaTriTimThay = item.doanhThuQD
                    break
                }
            }
            ketQua.append((nhan, giaTriTimThay))
        }
        return ketQua
    }

    /// Lấy Doanh thu Lũy kế Nhân viên của tháng (khi nhập mới sẽ thay thế dữ liệu cũ)
    func doanhThuNhanVienLuyKeThang(cho ngay: Date) -> [DoanhThuNhanVienItem] {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let khoa = TienIchNgay.khoa.string(from: ngay)
        if let daDem = boNhoDemDTNVLuyKeThang[khoa] {
            return daDem
        }
        let tienTo = String(khoa.prefix(7))
        if let hienTai = cacNgay[khoa]?.doanhThuNhanVien, !hienTai.isEmpty {
            boNhoDemDTNVLuyKeThang[khoa] = hienTai
            return hienTai
        }
        for k in cacNgay.keys.filter({ $0.hasPrefix(tienTo) }).sorted(by: >) {
            if let ds = cacNgay[k]?.doanhThuNhanVien, !ds.isEmpty {
                boNhoDemDTNVLuyKeThang[khoa] = ds
                return ds
            }
        }
        boNhoDemDTNVLuyKeThang[khoa] = []
        return []
    }

    /// Xoá toàn bộ dữ liệu Nhân viên (Sức khỏe 27 điểm, Doanh thu NV & Thi đua NV) của tháng để dữ liệu cũ không còn tồn đọng
    func xoaDoanhThuNhanVienLuyKeThang(cho ngay: Date, xoaCaThiDuaNV: Bool = true) {
        khoaTruyCap.lock()
        let khoa = TienIchNgay.khoa.string(from: ngay)
        let tienTo = String(khoa.prefix(7))
        cacKhoaMucDaXoa.insert("nv_dt|\(tienTo)")
        if xoaCaThiDuaNV {
            cacKhoaMucDaXoa.insert("nv_td|\(tienTo)")
        }
        luuTapKhoaMucDaXoa()
        var khoaCanDongBo = Set(cacNgay.keys.filter { $0.hasPrefix(tienTo) })
        khoaCanDongBo.insert(khoa)
        for k in khoaCanDongBo {
            if cacNgay[k] == nil {
                cacNgay[k] = DuLieuNgayDMX(
                    khoaNgay: k,
                    capNhatLuc: "",
                    thongTinDonVi: "",
                    doanhThu: ThongTinDoanhThu(),
                    danhSachThiDua: []
                )
            }
            cacNgay[k]?.doanhThuNhanVien = []
            cacNgay[k]?.doanhThuNhanVienRealtime = []
            cacNgay[k]?.sucKhoeBoSungNhanVien = [:]
            if xoaCaThiDuaNV {
                cacNgay[k]?.thiDuaNhanVien = [:]
                cacNgay[k]?.thiDuaNhanVienRealtime = [:]
            }
        }
        xoaBoNhoDem()
        let banSaoNgay = cacNgay
        khoaTruyCap.unlock()

        ThuMucDuLieu.dungChung.ghiNgayBatDongBo(banSaoNgay)
        for k in khoaCanDongBo {
            if let dlDaXoa = banSaoNgay[k] {
                DichVuDongBo.dungChung.dayDuLieuNgay(dlDaXoa)
            }
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .duLieuDMXDaThayDoiTaiMay, object: khoa)
        }
    }

    /// Xoá dữ liệu đã quét của riêng 1 nhân viên cụ thể trong toàn bộ tháng
    func xoaDuLieuMotNhanVien(maNV: String, cho ngay: Date) {
        let maChuan = Self.chuanHoaMaNV(maNV)
        guard !maChuan.isEmpty else { return }
        khoaTruyCap.lock()
        let khoa = TienIchNgay.khoa.string(from: ngay)
        let tienTo = String(khoa.prefix(7))
        cacKhoaMucDaXoa.insert("nv_one|\(tienTo)|\(maChuan)")
        luuTapKhoaMucDaXoa()
        var khoaCanDongBo = Set(cacNgay.keys.filter { $0.hasPrefix(tienTo) })
        khoaCanDongBo.insert(khoa)

        for k in khoaCanDongBo {
            guard var dl = cacNgay[k] else { continue }
            dl.doanhThuNhanVien.removeAll { Self.chuanHoaMaNV($0.maNV) == maChuan }
            dl.doanhThuNhanVienRealtime.removeAll { Self.chuanHoaMaNV($0.maNV) == maChuan }
            dl.sucKhoeBoSungNhanVien.removeValue(forKey: maChuan)
            dl.sucKhoeBoSungNhanVien.removeValue(forKey: maNV)
            for kMon in Array(dl.thiDuaNhanVien.keys) {
                dl.thiDuaNhanVien[kMon]?.removeValue(forKey: maChuan)
                dl.thiDuaNhanVien[kMon]?.removeValue(forKey: maNV)
            }
            for kMon in Array(dl.thiDuaNhanVienRealtime.keys) {
                dl.thiDuaNhanVienRealtime[kMon]?.removeValue(forKey: maChuan)
                dl.thiDuaNhanVienRealtime[kMon]?.removeValue(forKey: maNV)
            }
            cacNgay[k] = dl
        }
        xoaBoNhoDem()
        let banSaoNgay = cacNgay
        khoaTruyCap.unlock()

        ThuMucDuLieu.dungChung.ghiNgayBatDongBo(banSaoNgay)
        for k in khoaCanDongBo {
            if let dlDaXoa = banSaoNgay[k] {
                DichVuDongBo.dungChung.dayDuLieuNgay(dlDaXoa)
            }
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .duLieuDMXDaThayDoiTaiMay, object: khoa)
        }
    }

    /// Xoá danh sách Thi đua ngành hàng theo chế độ (Lũy kế xoá toàn tháng, Realtime xoá ngày đang chọn)
    func xoaThiDuaTheoCheDo(cho ngay: Date, cheDo: LoaiCheDoDoanhThu) {
        khoaTruyCap.lock()
        let khoa = TienIchNgay.khoa.string(from: ngay)
        let tienTo = String(khoa.prefix(7))
        cacKhoaMucDaXoa.insert("td_\(cheDo.rawValue)|\(cheDo == .luyKe ? tienTo : khoa)")
        luuTapKhoaMucDaXoa()
        var khoaCanDongBo = Set<String>([khoa])
        if cheDo == .luyKe {
            for k in cacNgay.keys where k.hasPrefix(tienTo) {
                khoaCanDongBo.insert(k)
            }
        }
        for k in khoaCanDongBo {
            if cacNgay[k] == nil {
                cacNgay[k] = DuLieuNgayDMX(
                    khoaNgay: k,
                    capNhatLuc: "",
                    thongTinDonVi: "",
                    doanhThu: ThongTinDoanhThu(),
                    danhSachThiDua: []
                )
            }
            if cheDo == .luyKe {
                cacNgay[k]?.danhSachThiDua = []
            } else {
                cacNgay[k]?.danhSachThiDuaRealtime = []
            }
        }
        xoaBoNhoDem()
        let banSaoNgay = cacNgay
        khoaTruyCap.unlock()

        ThuMucDuLieu.dungChung.ghiNgayBatDongBo(banSaoNgay)
        for k in khoaCanDongBo {
            if let dlDaXoa = banSaoNgay[k] {
                DichVuDongBo.dungChung.dayDuLieuNgay(dlDaXoa)
            }
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .duLieuDMXDaThayDoiTaiMay, object: khoa)
        }
    }

    /// Xoá Doanh thu Lũy kế cố định của tháng
    func xoaDoanhThuLuyKeThang(cho ngay: Date) {
        khoaTruyCap.lock()
        let khoa = TienIchNgay.khoa.string(from: ngay)
        let tienTo = String(khoa.prefix(7))
        cacKhoaMucDaXoa.insert("dt_lk|\(tienTo)")
        luuTapKhoaMucDaXoa()
        let doanhThuTrong = ThongTinDoanhThu()
        var khoaCanDongBo = Set(cacNgay.keys.filter { k in
            k.hasPrefix(tienTo) && cacNgay[k]?.doanhThu != doanhThuTrong
        })
        khoaCanDongBo.insert(khoa)
        for k in khoaCanDongBo {
            cacNgay[k]?.doanhThu = ThongTinDoanhThu()
        }
        xoaBoNhoDem()
        var dl = duLieu(cho: ngay)
        dl.doanhThu = ThongTinDoanhThu()
        cacNgay[khoa] = dl
        xoaBoNhoDem()
        let banSaoNgay = cacNgay
        khoaTruyCap.unlock()

        ThuMucDuLieu.dungChung.ghiNgayBatDongBo(banSaoNgay)
        for k in khoaCanDongBo {
            if let ngayDaXoa = banSaoNgay[k] {
                DichVuDongBo.dungChung.dayDuLieuNgay(ngayDaXoa)
            }
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .duLieuDMXDaThayDoiTaiMay, object: khoa)
        }
    }

    /// Xoá Doanh thu Realtime của ngày đang chọn
    func xoaDoanhThuRealtime(cho ngay: Date) {
        khoaTruyCap.lock()
        let khoa = TienIchNgay.khoa.string(from: ngay)
        cacKhoaMucDaXoa.insert("dt_rt|\(khoa)")
        luuTapKhoaMucDaXoa()
        var dl = duLieu(cho: ngay)
        dl.doanhThuRealtime = ThongTinDoanhThu()
        cacNgay[khoa] = dl
        xoaBoNhoDem()
        let banSaoNgay = cacNgay
        khoaTruyCap.unlock()

        ThuMucDuLieu.dungChung.ghiNgayBatDongBo(banSaoNgay)
        if let ngayDaXoa = banSaoNgay[khoa] {
            DichVuDongBo.dungChung.dayDuLieuNgay(ngayDaXoa)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .duLieuDMXDaThayDoiTaiMay, object: khoa)
        }
    }

    /// Khóa tháng dạng "yyyy-MM"
    func khoaThang(cho ngay: Date) -> String {
        let k = TienIchNgay.khoa.string(from: ngay)
        return String(k.prefix(7))
    }

    /// Số ngày thực tế của tháng (28, 29, 30 hoặc 31)
    func soNgayTrongThang(cho ngay: Date) -> Int {
        TienIchNgay.lich.range(of: .day, in: .month, for: ngay)?.count ?? 30
    }

    /// Lấy Mục tiêu Doanh thu Quy đổi tháng từ Target QĐ Lũy kế đã quét
    func mucTieuDoanhThuQDThang(cho ngay: Date) -> Double {
        let lk = doanhThuLuyKeThang(cho: ngay)
        if lk.targetQuyDoi > 0 {
            return lk.targetQuyDoi
        }
        return 0
    }

    /// Tính toán Dự báo Doanh thu QĐ cuối tháng, % HT QĐ dự kiến & % Quy đổi dự kiến cho bảng Biểu đồ tháng.
    func tinhDuBaoQuyDoiTuRealtime(cho ngay: Date, cheDoDangXem: LoaiCheDoDoanhThu = .realtime) -> DuBaoQuyDoiThang {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let khoaDem = "\(TienIchNgay.khoa.string(from: ngay))|\(cheDoDangXem.rawValue)"
        if let daDem = boNhoDemDuBaoThang[khoaDem] {
            return daDem
        }
        let soNgay = max(1, soNgayTrongThang(cho: ngay))
        let lk = doanhThuLuyKeThang(cho: ngay)
        let mucTieuThang = lk.targetQuyDoi
        let mucTieuNgay = mucTieuThang > 0 ? (mucTieuThang / Double(soNgay)) : 0

        let khoaDen = TienIchNgay.khoa.string(from: ngay)
        let tatCaNgay = danhSachRealtimeTheoNgayTrongThang(cho: ngay)
        let cacNgayCoRTDenNgay = tatCaNgay.filter { $0.khoaNgay <= khoaDen && ($0.doanhThuQuyDoi > 0 || $0.doanhThuThuc > 0) }
        let cacNgayCoRTTrongThang = tatCaNgay.filter { $0.doanhThuQuyDoi > 0 || $0.doanhThuThuc > 0 }
        let cacNgayCoRT = !cacNgayCoRTDenNgay.isEmpty ? cacNgayCoRTDenNgay : cacNgayCoRTTrongThang

        let dlNgayChon = duLieu(cho: ngay)

        var soNgayTinh = cacNgayCoRT.count
        var tongQD = cacNgayCoRT.reduce(0.0) { $0 + $1.doanhThuQuyDoi }
        var tongThuc = cacNgayCoRT.reduce(0.0) { $0 + $1.doanhThuThuc }

        let tbQDMoiNgay: Double
        let tbThucMoiNgay: Double

        if soNgayTinh > 0 {
            tbQDMoiNgay = tongQD / Double(soNgayTinh)
            tbThucMoiNgay = tongThuc / Double(soNgayTinh)
        } else if lk.coDuLieu {
            let ngayDaQua = lk.soNgayDaQua > 0 ? lk.soNgayDaQua : max(1, TienIchNgay.lich.component(.day, from: ngay))
            soNgayTinh = ngayDaQua
            tongQD = lk.doanhThuQuyDoi
            tongThuc = lk.doanhThuThuc
            tbQDMoiNgay = ngayDaQua > 0 ? (lk.doanhThuQuyDoi / Double(ngayDaQua)) : 0
            tbThucMoiNgay = ngayDaQua > 0 ? (lk.doanhThuThuc / Double(ngayDaQua)) : 0
        } else {
            tbQDMoiNgay = 0
            tbThucMoiNgay = 0
        }

        let duKienQDCuoiThang = lk.duKienQuyDoi > 0 ? lk.duKienQuyDoi : (tbQDMoiNgay * Double(soNgay))
        let duKienThucCuoiThang = lk.duKienThuc > 0 ? lk.duKienThuc : (tbThucMoiNgay * Double(soNgay))

        let phanTramHTQDDuKien: Double
        if lk.phanTramHTQuyDoi > 0 {
            phanTramHTQDDuKien = lk.phanTramHTQuyDoi
        } else if dlNgayChon.doanhThuRealtime.phanTramHTQuyDoi > 0 {
            phanTramHTQDDuKien = dlNgayChon.doanhThuRealtime.phanTramHTQuyDoi
        } else if mucTieuThang > 0, duKienQDCuoiThang > 0 {
            phanTramHTQDDuKien = (duKienQDCuoiThang / mucTieuThang) * 100.0
        } else if dlNgayChon.doanhThuRealtime.targetQuyDoi > 0, tbQDMoiNgay > 0 {
            phanTramHTQDDuKien = (tbQDMoiNgay / dlNgayChon.doanhThuRealtime.targetQuyDoi) * 100.0
        } else {
            phanTramHTQDDuKien = 0
        }

        let phanTramQDDuKien: Double
        if duKienThucCuoiThang > 0, duKienQDCuoiThang > 0 {
            phanTramQDDuKien = ((duKienQDCuoiThang - duKienThucCuoiThang) / duKienThucCuoiThang) * 100.0
        } else {
            let dt = (cheDoDangXem == .luyKe) ? dlNgayChon.doanhThu : dlNgayChon.doanhThuRealtime
            phanTramQDDuKien = dt.phanTramQuyDoi
        }

        let ketQua = DuBaoQuyDoiThang(
            mucTieuThang: mucTieuThang,
            soNgayTrongThang: soNgay,
            mucTieuMoiNgay: mucTieuNgay,
            soNgayCoRealtime: soNgayTinh,
            tongDTThucRealtime: tongThuc,
            tongDTQDRealtime: tongQD,
            trungBinhThucMoiNgay: tbThucMoiNgay,
            trungBinhQDMoiNgay: tbQDMoiNgay,
            duKienThucCuoiThang: duKienThucCuoiThang,
            duKienQDCuoiThang: duKienQDCuoiThang,
            phanTramHTQDDuKien: phanTramHTQDDuKien,
            phanTramQuyDoiDuKien: phanTramQDDuKien
        )
        boNhoDemDuBaoThang[khoaDem] = ketQua
        return ketQua
    }

    /// Danh sách Doanh thu Realtime (Thực & Quy đổi) theo từng ngày trong tháng để vẽ đồ thị cột và bảng tổng hợp
    func danhSachRealtimeTheoNgayTrongThang(cho ngay: Date) -> [DuLieuRealtimeNgayTrongThang] {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let lich = TienIchNgay.lich
        let nam = lich.component(.year, from: ngay)
        let thang = lich.component(.month, from: ngay)
        let khoaThangDem = String(format: "%04d-%02d", nam, thang)
        if let daDem = boNhoDemRealtimeThang[khoaThangDem] {
            return daDem
        }
        let soNgay = lich.range(of: .day, in: .month, for: ngay)?.count ?? 30

        var ketQua: [DuLieuRealtimeNgayTrongThang] = []
        ketQua.reserveCapacity(soNgay)
        for d in 1...soNgay {
            var comp = DateComponents()
            comp.year = nam
            comp.month = thang
            comp.day = d
            let ngayD = lich.date(from: comp) ?? ngay
            let khoa = String(format: "%04d-%02d-%02d", nam, thang, d)
            let rt = cacNgay[khoa]?.doanhThuRealtime ?? ThongTinDoanhThu()
            ketQua.append(
                DuLieuRealtimeNgayTrongThang(
                    ngay: ngayD,
                    khoaNgay: khoa,
                    ngayTrongThang: d,
                    doanhThu: rt
                )
            )
        }
        boNhoDemRealtimeThang[khoaThangDem] = ketQua
        return ketQua
    }

    func duLieu(cho ngay: Date) -> DuLieuNgayDMX {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let khoa = TienIchNgay.khoa.string(from: ngay)
        if let daDem = boNhoDemDuLieuNgay[khoa] {
            return daDem
        }

        let tienTo = String(khoa.prefix(7))
        let luyKeThang = doanhThuLuyKeThang(cho: ngay)
        let dtNVLuyKeThang = doanhThuNhanVienLuyKeThang(cho: ngay)
        let skBoSungThang = sucKhoeBoSungNhanVienThang(cho: ngay)

        // Tìm target Lũy kế & Realtime gần nhất trong tháng (tách biệt hoàn toàn giữa Lũy kế và Realtime)
        var targetTheoKhoaTrongThang: [String: Double] = [:]
        var targetRealtimeTheoKhoaTrongThang: [String: Double] = [:]
        for kNgay in cacNgay.keys.filter({ $0.hasPrefix(tienTo) && $0 <= khoa }).sorted() {
            guard let dlNgay = cacNgay[kNgay] else { continue }
            for d in dlNgay.danhSachThiDua where d.target > 0 {
                let k1 = Self.chuanHoaKhoaSoSanh(Self.apDungLocTuCaiDat(d.tenNganhHangGoc))
                let k2 = Self.chuanHoaKhoaSoSanh(d.tenNganhHangGoc)
                if !k1.isEmpty { targetTheoKhoaTrongThang[k1] = d.target }
                if !k2.isEmpty { targetTheoKhoaTrongThang[k2] = d.target }
            }
            for d in dlNgay.danhSachThiDuaRealtime where d.target > 0 {
                let k1 = Self.chuanHoaKhoaSoSanh(Self.apDungLocTuCaiDat(d.tenNganhHangGoc))
                let k2 = Self.chuanHoaKhoaSoSanh(d.tenNganhHangGoc)
                if !k1.isEmpty { targetRealtimeTheoKhoaTrongThang[k1] = d.target }
                if !k2.isEmpty { targetRealtimeTheoKhoaTrongThang[k2] = d.target }
            }
        }

        if var coSan = cacNgay[khoa] {
            if !coSan.doanhThu.coDuLieu && luyKeThang.coDuLieu {
                coSan.doanhThu = luyKeThang
            }
            if coSan.doanhThuNhanVien.isEmpty && !dtNVLuyKeThang.isEmpty {
                coSan.doanhThuNhanVien = dtNVLuyKeThang
            }
            if !skBoSungThang.isEmpty {
                var gopSK = skBoSungThang
                for (ma, skNgay) in coSan.sucKhoeBoSungNhanVien {
                    if let cu = gopSK[ma] {
                        gopSK[ma] = cu.gop(voi: skNgay)
                    } else {
                        gopSK[ma] = skNgay
                    }
                }
                coSan.sucKhoeBoSungNhanVien = gopSK
            }
            for i in coSan.danhSachThiDua.indices {
                let goc = coSan.danhSachThiDua[i].tenNganhHangGoc
                coSan.danhSachThiDua[i].tenNganhHang = KhoDuLieu.apDungLocTuCaiDat(goc)
                if coSan.danhSachThiDua[i].target <= 0 {
                    let k1 = Self.chuanHoaKhoaSoSanh(coSan.danhSachThiDua[i].tenNganhHang)
                    let k2 = Self.chuanHoaKhoaSoSanh(goc)
                    if let t = targetTheoKhoaTrongThang[k1] ?? targetTheoKhoaTrongThang[k2], t > 0 {
                        coSan.danhSachThiDua[i].target = t
                    }
                }
            }
            coSan.danhSachThiDua = Self.gopDanhSachThiDua(cu: [], moi: coSan.danhSachThiDua)

            for i in coSan.danhSachThiDuaRealtime.indices {
                let goc = coSan.danhSachThiDuaRealtime[i].tenNganhHangGoc
                coSan.danhSachThiDuaRealtime[i].tenNganhHang = KhoDuLieu.apDungLocTuCaiDat(goc)
                if coSan.danhSachThiDuaRealtime[i].target <= 0 {
                    let k1 = Self.chuanHoaKhoaSoSanh(coSan.danhSachThiDuaRealtime[i].tenNganhHang)
                    let k2 = Self.chuanHoaKhoaSoSanh(goc)
                    if let t = targetRealtimeTheoKhoaTrongThang[k1] ?? targetRealtimeTheoKhoaTrongThang[k2], t > 0 {
                        coSan.danhSachThiDuaRealtime[i].target = t
                    }
                }
            }
            coSan.danhSachThiDuaRealtime = Self.gopDanhSachThiDua(cu: [], moi: coSan.danhSachThiDuaRealtime)
            boNhoDemDuLieuNgay[khoa] = coSan
            return coSan
        }

        let moi = DuLieuNgayDMX(
            khoaNgay: khoa,
            capNhatLuc: "",
            thongTinDonVi: "",
            doanhThu: luyKeThang,
            doanhThuRealtime: ThongTinDoanhThu(),
            danhSachThiDua: [],
            danhSachThiDuaRealtime: [],
            doanhThuNhanVien: dtNVLuyKeThang,
            sucKhoeBoSungNhanVien: skBoSungThang
        )
        boNhoDemDuLieuNgay[khoa] = moi
        return moi
    }

    func luu(_ duLieu: DuLieuNgayDMX) {
        khoaTruyCap.lock()
        var banLuu = duLieu
        let tienTo = String(banLuu.khoaNgay.prefix(7))
        var coThayDoiCoXoa = false
        if banLuu.doanhThu.coDuLieu && cacKhoaMucDaXoa.remove("dt_lk|\(tienTo)") != nil { coThayDoiCoXoa = true }
        if banLuu.doanhThuRealtime.coDuLieu && cacKhoaMucDaXoa.remove("dt_rt|\(banLuu.khoaNgay)") != nil { coThayDoiCoXoa = true }
        if !banLuu.danhSachThiDua.isEmpty && cacKhoaMucDaXoa.remove("td_0|\(tienTo)") != nil { coThayDoiCoXoa = true }
        if !banLuu.danhSachThiDuaRealtime.isEmpty && cacKhoaMucDaXoa.remove("td_1|\(banLuu.khoaNgay)") != nil { coThayDoiCoXoa = true }
        if !banLuu.doanhThuNhanVien.isEmpty || !banLuu.doanhThuNhanVienRealtime.isEmpty || !banLuu.sucKhoeBoSungNhanVien.isEmpty {
            if cacKhoaMucDaXoa.remove("nv_dt|\(tienTo)") != nil { coThayDoiCoXoa = true }
            for item in banLuu.doanhThuNhanVien + banLuu.doanhThuNhanVienRealtime {
                let ma = Self.chuanHoaMaNV(item.maNV)
                if !ma.isEmpty && cacKhoaMucDaXoa.remove("nv_one|\(tienTo)|\(ma)") != nil { coThayDoiCoXoa = true }
            }
            for ma in banLuu.sucKhoeBoSungNhanVien.keys {
                let maChuan = Self.chuanHoaMaNV(ma)
                if !maChuan.isEmpty && cacKhoaMucDaXoa.remove("nv_one|\(tienTo)|\(maChuan)") != nil { coThayDoiCoXoa = true }
            }
        }
        if !banLuu.thiDuaNhanVien.isEmpty || !banLuu.thiDuaNhanVienRealtime.isEmpty {
            if cacKhoaMucDaXoa.remove("nv_td|\(tienTo)") != nil { coThayDoiCoXoa = true }
        }
        if coThayDoiCoXoa { luuTapKhoaMucDaXoa() }

        for i in banLuu.danhSachThiDua.indices {
            let goc = banLuu.danhSachThiDua[i].tenNganhHangGoc
            banLuu.danhSachThiDua[i].tenNganhHang = Self.apDungLocTuCaiDat(goc)
        }
        banLuu.danhSachThiDua = Self.gopDanhSachThiDua(cu: [], moi: banLuu.danhSachThiDua)

        for i in banLuu.danhSachThiDuaRealtime.indices {
            let goc = banLuu.danhSachThiDuaRealtime[i].tenNganhHangGoc
            banLuu.danhSachThiDuaRealtime[i].tenNganhHang = Self.apDungLocTuCaiDat(goc)
        }
        banLuu.danhSachThiDuaRealtime = Self.gopDanhSachThiDua(cu: [], moi: banLuu.danhSachThiDuaRealtime)

        // Doanh thu Lũy kế là cố định của tháng: khi người dùng nhập vào mỗi ngày sẽ thay thế cho ngày hôm trước trong cùng tháng
        if banLuu.doanhThu.coDuLieu {
            for k in cacNgay.keys where k.hasPrefix(tienTo) {
                cacNgay[k]?.doanhThu = banLuu.doanhThu
            }
        } else if !cacKhoaMucDaXoa.contains("dt_lk|\(tienTo)") {
            for k in cacNgay.keys.filter({ $0.hasPrefix(tienTo) && $0 != banLuu.khoaNgay }).sorted(by: >) {
                if let dtCu = cacNgay[k]?.doanhThu, dtCu.coDuLieu {
                    banLuu.doanhThu = dtCu
                    break
                }
            }
        }

        // Doanh thu Lũy kế nhân viên: mỗi khi nhập mới sẽ thay thế hoàn toàn dữ liệu cũ của tháng
        if !banLuu.doanhThuNhanVien.isEmpty {
            for k in cacNgay.keys where k.hasPrefix(tienTo) {
                cacNgay[k]?.doanhThuNhanVien = banLuu.doanhThuNhanVien
            }
        } else if !cacKhoaMucDaXoa.contains("nv_dt|\(tienTo)") {
            for k in cacNgay.keys.filter({ $0.hasPrefix(tienTo) && $0 != banLuu.khoaNgay }).sorted(by: >) {
                if let dsCu = cacNgay[k]?.doanhThuNhanVien, !dsCu.isEmpty {
                    banLuu.doanhThuNhanVien = dsCu
                    break
                }
            }
        }

        if !banLuu.sucKhoeBoSungNhanVien.isEmpty {
            for k in cacNgay.keys where k.hasPrefix(tienTo) && k != banLuu.khoaNgay {
                var skCu = cacNgay[k]?.sucKhoeBoSungNhanVien ?? [:]
                for (ma, skMoi) in banLuu.sucKhoeBoSungNhanVien {
                    if let cu = skCu[ma] {
                        skCu[ma] = cu.gop(voi: skMoi)
                    } else {
                        skCu[ma] = skMoi
                    }
                }
                cacNgay[k]?.sucKhoeBoSungNhanVien = skCu
            }
        }

        cacNgay[banLuu.khoaNgay] = banLuu
        xoaBoNhoDem()
        let banSaoNgay = cacNgay
        khoaTruyCap.unlock()

        ThuMucDuLieu.dungChung.ghiNgayBatDongBo(banSaoNgay)
        DichVuDongBo.dungChung.dayDuLieuNgay(banLuu)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .duLieuDMXDaThayDoiTaiMay, object: banLuu.khoaNgay)
        }
    }

    func luuCaiDat(_ moi: CaiDatDMX) {
        khoaTruyCap.lock()
        var moi = moi
        moi.danhSachNhanVien = NhanVienQuanLy.sapXepAZ(moi.danhSachNhanVien)
        let doiCumTu = (caiDat.danhSachCumTuLocBo != moi.danhSachCumTuLocBo)
        UserDefaults.standard.set(moi.phuongPhapQuetThiDua.rawValue, forKey: "dmx.caiDat.phuongPhapQuetThiDua")
        UserDefaults.standard.set(moi.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "dmx.caiDat.geminiApiKey")
        UserDefaults.standard.set(moi.hienThiNangSuatNhanVien, forKey: "dmx.caiDat.hienThiNangSuatNhanVien")
        caiDat = moi
        xoaBoNhoDem(xoaonLocTen: doiCumTu)
        let banSaoCaiDat = moi
        var banSaoNgayCanLuu: [String: DuLieuNgayDMX]?
        if doiCumTu {
            for (khoa, var dl) in cacNgay {
                for i in dl.danhSachThiDua.indices {
                    let goc = dl.danhSachThiDua[i].tenNganhHangGoc
                    dl.danhSachThiDua[i].tenNganhHang = KhoDuLieu.apDungLocTuCaiDat(goc)
                }
                dl.danhSachThiDua = Self.gopDanhSachThiDua(cu: [], moi: dl.danhSachThiDua)

                for i in dl.danhSachThiDuaRealtime.indices {
                    let goc = dl.danhSachThiDuaRealtime[i].tenNganhHangGoc
                    dl.danhSachThiDuaRealtime[i].tenNganhHang = KhoDuLieu.apDungLocTuCaiDat(goc)
                }
                dl.danhSachThiDuaRealtime = Self.gopDanhSachThiDua(cu: [], moi: dl.danhSachThiDuaRealtime)
                cacNgay[khoa] = dl
            }
            xoaBoNhoDem()
            banSaoNgayCanLuu = cacNgay
        }
        khoaTruyCap.unlock()

        ThuMucDuLieu.dungChung.ghiCaiDatBatDongBo(banSaoCaiDat)
        if let banSaoNgayCanLuu {
            ThuMucDuLieu.dungChung.ghiNgayBatDongBo(banSaoNgayCanLuu)
        }
        DichVuDongBo.dungChung.dayCaiDat(moi)
    }

    /// Chuẩn hoá dữ liệu tải về từ đám mây trên luồng nền rồi gán nhanh vào bộ nhớ để tránh làm khựng giao diện người dùng
    func nhapDuLieuDamMay(caiDat moi: CaiDatDMX?, cacNgay ngayMoi: [String: DuLieuNgayDMX]) {
        khoaTruyCap.lock()
        if var moi {
            moi.danhSachNhanVien = NhanVienQuanLy.sapXepAZ(moi.danhSachNhanVien)
            if UserDefaults.standard.object(forKey: "dmx.caiDat.phuongPhapQuetThiDua") != nil,
               let luuPP = PhuongPhapQuetThiDua(rawValue: UserDefaults.standard.integer(forKey: "dmx.caiDat.phuongPhapQuetThiDua")) {
                moi.phuongPhapQuetThiDua = luuPP
            }
            if let luuKey = UserDefaults.standard.string(forKey: "dmx.caiDat.geminiApiKey")?.trimmingCharacters(in: .whitespacesAndNewlines),
               !luuKey.isEmpty {
                if luuKey != CaiDatDMX.geminiKeyMacDinh || moi.geminiApiKey.isEmpty {
                    moi.geminiApiKey = luuKey
                }
            }
            caiDat = moi
        }
        xoaBoNhoDem(xoaonLocTen: true)
        for (khoa, var duLieu) in ngayMoi {
            duLieu.khoaNgay = khoa
            for i in duLieu.danhSachThiDua.indices {
                let goc = duLieu.danhSachThiDua[i].tenNganhHangGoc
                duLieu.danhSachThiDua[i].tenNganhHang = KhoDuLieu.apDungLocTuCaiDat(goc)
            }
            duLieu.danhSachThiDua = Self.gopDanhSachThiDua(cu: [], moi: duLieu.danhSachThiDua)

            for i in duLieu.danhSachThiDuaRealtime.indices {
                let goc = duLieu.danhSachThiDuaRealtime[i].tenNganhHangGoc
                duLieu.danhSachThiDuaRealtime[i].tenNganhHang = KhoDuLieu.apDungLocTuCaiDat(goc)
            }
            duLieu.danhSachThiDuaRealtime = Self.gopDanhSachThiDua(cu: [], moi: duLieu.danhSachThiDuaRealtime)
            apDungCoXoa(vao: &duLieu)
            cacNgay[khoa] = duLieu
        }
        xoaBoNhoDem()
        let banSaoCaiDat = caiDat
        let banSaoNgay = cacNgay
        khoaTruyCap.unlock()

        ThuMucDuLieu.dungChung.ghiCaiDatBatDongBo(banSaoCaiDat)
        ThuMucDuLieu.dungChung.ghiNgayBatDongBo(banSaoNgay)
    }

    func datLaiSauDangXuat() {
        khoaTruyCap.lock()
        caiDat = CaiDatDMX()
        cacNgay = [:]
        boNhoSieuThi.removeAll()
        xoaBoNhoDem(xoaonLocTen: true)
        khoaTruyCap.unlock()
        // Chỉ xóa RAM. Không ghi file rỗng đè lên dữ liệu của tài khoản vừa đăng xuất;
        // khi đăng nhập lại app có thể mở ngay cache cũ rồi mới đồng bộ phần mới nhất.
    }

    /// Danh sách mặt hàng đồng bộ theo chế độ đang xem (Lũy kế hoặc Realtime)
    func danhSachMatHangThang(den ngay: Date, cheDo: LoaiCheDoDoanhThu = .luyKe) -> [DongThiDua] {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let khoaDen = TienIchNgay.khoa.string(from: ngay)
        let khoaDem = "\(khoaDen)|\(cheDo.rawValue)"
        if let daDem = boNhoDemMatHangThang[khoaDem] {
            return daDem
        }
        let dlNgay = duLieu(cho: ngay)
        if cheDo == .realtime {
            if !dlNgay.danhSachThiDuaRealtime.isEmpty {
                boNhoDemMatHangThang[khoaDem] = dlNgay.danhSachThiDuaRealtime
                return dlNgay.danhSachThiDuaRealtime
            }
            let tienTo = String(khoaDen.prefix(7))
            let cacKhoa = cacNgay.keys.filter { $0.hasPrefix(tienTo) && $0 <= khoaDen }.sorted(by: >)
            for khoa in cacKhoa {
                if let dl = cacNgay[khoa], !dl.danhSachThiDuaRealtime.isEmpty {
                    var ds = dl.danhSachThiDuaRealtime
                    for i in ds.indices {
                        ds[i].tenNganhHang = Self.apDungLocTuCaiDat(ds[i].tenNganhHangGoc)
                    }
                    let kq = Self.gopDanhSachThiDua(cu: [], moi: ds)
                    boNhoDemMatHangThang[khoaDem] = kq
                    return kq
                }
            }
            if !dlNgay.danhSachThiDua.isEmpty {
                boNhoDemMatHangThang[khoaDem] = dlNgay.danhSachThiDua
                return dlNgay.danhSachThiDua
            }
        } else {
            if !dlNgay.danhSachThiDua.isEmpty {
                boNhoDemMatHangThang[khoaDem] = dlNgay.danhSachThiDua
                return dlNgay.danhSachThiDua
            }
            let tienTo = String(khoaDen.prefix(7))
            let cacKhoa = cacNgay.keys.filter { $0.hasPrefix(tienTo) && $0 <= khoaDen }.sorted(by: >)
            for khoa in cacKhoa {
                if let dl = cacNgay[khoa], !dl.danhSachThiDua.isEmpty {
                    var ds = dl.danhSachThiDua
                    for i in ds.indices {
                        ds[i].tenNganhHang = Self.apDungLocTuCaiDat(ds[i].tenNganhHangGoc)
                    }
                    let kq = Self.gopDanhSachThiDua(cu: [], moi: ds)
                    boNhoDemMatHangThang[khoaDem] = kq
                    return kq
                }
            }
            if !dlNgay.danhSachThiDuaRealtime.isEmpty {
                boNhoDemMatHangThang[khoaDem] = dlNgay.danhSachThiDuaRealtime
                return dlNgay.danhSachThiDuaRealtime
            }
        }
        boNhoDemMatHangThang[khoaDem] = []
        return []
    }

    /// Lấy danh sách mã NV được chia Target cho 1 ngành hàng (đồng bộ cả khóa tên đã lọc và khóa tên gốc)
    func danhSachMaNVChiaTarget(cho dong: DongThiDua, trong tapCaiDat: CaiDatDMX? = nil) -> [String] {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let cd = tapCaiDat ?? caiDat
        let tatCaMa = cd.danhSachNhanVien.map(\.maNV)
        let k1 = Self.chuanHoaKhoaSoSanh(dong.tenNganhHang)
        let k2 = Self.chuanHoaKhoaSoSanh(dong.tenNganhHangGoc)
        if let ds = cd.chiaTargetNganhHang[k1] ?? cd.chiaTargetNganhHang[k2] {
            return ds.filter { tatCaMa.contains($0) }
        }
        return tatCaMa
    }

    /// Đồng bộ cập nhật Target & ĐVT (DT/SL) của 1 ngành hàng từ màn hình Chia Target (Cài đặt) sang Bảng Thi Đua
    func capNhatTargetNganhHang(dongGoc: DongThiDua, targetMoi: Double, loaiChiTieuMoi: LoaiChiTieuThiDua? = nil, cho ngay: Date, cheDo: LoaiCheDoDoanhThu = .luyKe) {
        khoaTruyCap.lock()
        let k1 = Self.chuanHoaKhoaSoSanh(dongGoc.tenNganhHang)
        let k2 = Self.chuanHoaKhoaSoSanh(dongGoc.tenNganhHangGoc)
        var dl = duLieu(cho: ngay)
        var ds = dl.danhSachThiDua(theo: cheDo)
        var daCapNhat = false
        for i in ds.indices {
            let dk1 = Self.chuanHoaKhoaSoSanh(ds[i].tenNganhHang)
            let dk2 = Self.chuanHoaKhoaSoSanh(ds[i].tenNganhHangGoc)
            if ds[i].id == dongGoc.id || dk1 == k1 || dk2 == k2 {
                ds[i].target = targetMoi
                if let loai = loaiChiTieuMoi {
                    ds[i].loaiChiTieu = loai
                }
                daCapNhat = true
            }
        }
        if daCapNhat {
            dl.ganDanhSachThiDua(ds, theo: cheDo)
            khoaTruyCap.unlock()
            luu(dl)
        } else {
            let khoaDen = TienIchNgay.khoa.string(from: ngay)
            let tienTo = String(khoaDen.prefix(7))
            let cacKhoa = cacNgay.keys.filter { $0.hasPrefix(tienTo) && $0 <= khoaDen }.sorted(by: >)
            var dlCanLuu: DuLieuNgayDMX?
            for khoa in cacKhoa {
                guard var dlCu = cacNgay[khoa] else { continue }
                var dsCu = dlCu.danhSachThiDua(theo: cheDo)
                guard !dsCu.isEmpty else { continue }
                for i in dsCu.indices {
                    let dk1 = Self.chuanHoaKhoaSoSanh(Self.apDungLocTuCaiDat(dsCu[i].tenNganhHangGoc))
                    let dk2 = Self.chuanHoaKhoaSoSanh(dsCu[i].tenNganhHangGoc)
                    if dk1 == k1 || dk2 == k2 {
                        dsCu[i].target = targetMoi
                        if let loai = loaiChiTieuMoi {
                            dsCu[i].loaiChiTieu = loai
                        }
                    }
                }
                dlCu.ganDanhSachThiDua(dsCu, theo: cheDo)
                dlCanLuu = dlCu
                break
            }
            khoaTruyCap.unlock()
            if let dlCanLuu {
                luu(dlCanLuu)
            }
        }
    }

    /// Tổng hợp số thực hiện của từng nhân viên theo từng mặt hàng theo chế độ Lũy kế hoặc Realtime
    func thucHienNhanVienTheoMatHangThang(den ngay: Date, cheDo: LoaiCheDoDoanhThu = .luyKe) -> [String: [String: Double]] {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let khoaDen = TienIchNgay.khoa.string(from: ngay)
        let khoaDem = "\(khoaDen)|\(cheDo.rawValue)"
        if let daDem = boNhoDemThucHienNVThang[khoaDem] {
            return daDem
        }
        if cheDo == .realtime {
            let kq = duLieu(cho: ngay).thiDuaNhanVienRealtime
            boNhoDemThucHienNVThang[khoaDem] = kq
            return kq
        }

        let tienTo = String(khoaDen.prefix(7))
        var cacKhoa = cacNgay.keys.filter { $0.hasPrefix(tienTo) && $0 <= khoaDen }.sorted()
        if !cacKhoa.contains(khoaDen) {
            cacKhoa.append(khoaDen)
        }

        var ketQua: [String: [String: Double]] = [:]
        for khoa in cacKhoa {
            let dl = (khoa == khoaDen) ? duLieu(cho: ngay) : cacNgay[khoa]
            guard let bangNganh = dl?.thiDuaNhanVien else { continue }
            for (khoaNganh, bangNV) in bangNganh {
                ketQua[khoaNganh, default: [:]].merge(bangNV) { _, moi in moi }
            }
        }
        boNhoDemThucHienNVThang[khoaDem] = ketQua
        return ketQua
    }

    /// Danh sách xếp hạng nhân viên cho 1 ngành hàng cụ thể (chia theo Lũy kế hoặc Realtime)
    func danhSachXepHangNhanVien(cho dong: DongThiDua, den ngay: Date, cheDo: LoaiCheDoDoanhThu = .luyKe) -> [DongXepHangNhanVienNganh] {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let khoaNganh = Self.chuanHoaKhoaSoSanh(dong.tenNganhHang)
        let dsMaDuocChon = danhSachMaNVChiaTarget(cho: dong)
        let soNV = dsMaDuocChon.count
        guard soNV > 0 else { return [] }

        let targetCaNhan = dong.target / Double(soNV)
        let bangTH = thucHienNhanVienTheoMatHangThang(den: ngay, cheDo: cheDo)[khoaNganh] ?? [:]
        let bangSK = sucKhoeBoSungNhanVienThang(cho: ngay)
        let khoaLM = Self.chuanHoaKhoaLienMachThiDua(dong.tenNganhHangGoc)

        return dsMaDuocChon.map { maNV in
            let nv = caiDat.danhSachNhanVien.first(where: { $0.maNV == maNV }) ?? NhanVienQuanLy(maNV: maNV, hoTen: "NV \(maNV)")
            let thTuBang = bangTH[maNV]
            let ptTuSK = bangSK[maNV]?.phanTramThiDuaCaNhan?[khoaLM] ?? bangSK[maNV]?.phanTramThiDuaCaNhan?[khoaNganh]
            let thucHien: Double
            let phanTramHT: Double
            if let ptSK = ptTuSK {
                if targetCaNhan > 0.0001 {
                    if let th = thTuBang, th > 0 {
                        thucHien = th
                        let htTinh = (th / targetCaNhan) * 100.0
                        phanTramHT = abs(htTinh - ptSK) <= 2.5 ? ptSK : htTinh
                    } else if ptSK > 0 {
                        thucHien = ((targetCaNhan * ptSK / 100.0) * 100.0).rounded() / 100.0
                        phanTramHT = ptSK
                    } else {
                        thucHien = 0
                        phanTramHT = 0
                    }
                } else {
                    thucHien = thTuBang ?? 0
                    phanTramHT = max(0, ptSK)
                }
            } else {
                thucHien = thTuBang ?? 0
                phanTramHT = targetCaNhan > 0.0001 ? (thucHien / targetCaNhan) * 100.0 : 0
            }
            return DongXepHangNhanVienNganh(
                maNV: maNV,
                hoTen: nv.hoTen,
                thucHien: thucHien,
                targetCaNhan: targetCaNhan,
                phanTramHT: phanTramHT
            )
        }.sorted {
            if abs($0.phanTramHT - $1.phanTramHT) > 0.001 {
                return $0.phanTramHT > $1.phanTramHT
            }
            if abs($0.thucHien - $1.thucHien) > 0.001 {
                return $0.thucHien > $1.thucHien
            }
            return NhanVienQuanLy.soSanhAZ(
                NhanVienQuanLy(maNV: $0.maNV, hoTen: $0.hoTen),
                NhanVienQuanLy(maNV: $1.maNV, hoTen: $1.hoTen)
            )
        }
    }

    /// Bảng tổng hợp nhân viên (chia theo Lũy kế hoặc Realtime).
    func tongHopNhanVien(
        den ngay: Date,
        sapXep: KieuSapXepNhanVien = .tenAZ,
        cheDo: LoaiCheDoDoanhThu = .luyKe
    ) -> [TongHopNhanVien] {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let khoaNgay = TienIchNgay.khoa.string(from: ngay)
        let khoaDem = "\(khoaNgay)|\(cheDo.rawValue)|\(sapXep.rawValue)"
        if let daDem = boNhoDemTongHopNV[khoaDem] {
            return daDem
        }

        let dsNV = NhanVienQuanLy.sapXepAZ(caiDat.danhSachNhanVien)
        guard !dsNV.isEmpty else {
            boNhoDemTongHopNV[khoaDem] = []
            return []
        }

        // Nếu đã tính cho cùng ngày + chế độ ở kiểu sắp xếp khác thì chỉ cần sắp xếp lại mảng 16 NV (0ms)
        let tienToNgayCheDo = "\(khoaNgay)|\(cheDo.rawValue)|"
        if let daCoCungCheDo = boNhoDemTongHopNV.first(where: { $0.key.hasPrefix(tienToNgayCheDo) })?.value {
            let sapXepLai = Self.sapXepDanhSachTongHopNV(daCoCungCheDo, theo: sapXep)
            boNhoDemTongHopNV[khoaDem] = sapXepLai
            return sapXepLai
        }

        var matHang = danhSachMatHangThang(den: ngay, cheDo: cheDo)
        let thucHienTheoNganh = thucHienNhanVienTheoMatHangThang(den: ngay, cheDo: cheDo)
        let dlHienTai = duLieu(cho: ngay)
        let bangSucKhoeThang = dlHienTai.sucKhoeBoSungNhanVien.isEmpty
            ? sucKhoeBoSungNhanVienThang(cho: ngay)
            : dlHienTai.sucKhoeBoSungNhanVien

        // Bổ sung đầy đủ các môn thi đua chuẩn ĐMX vào bảng chi tiết nhân viên (môn nào chưa có mặc định để 0)
        var tapKhoaDaCo = Set(matHang.map { Self.chuanHoaKhoaLienMachThiDua($0.tenNganhHangGoc) })
        let danhSachKhoaTheoDoi = Set(caiDat.khoaMonTheoDoi(cho: cheDo))
        let khongChonMonNao = danhSachKhoaTheoDoi.contains(CaiDatDMX.khoaKhongChonMonThiDua)
        if !khongChonMonNao {
            for tenChuan in Self.danhSachTenMonThiDuaChuanDMX {
                let kLM = Self.chuanHoaKhoaLienMachThiDua(tenChuan)
                guard !kLM.isEmpty, !tapKhoaDaCo.contains(kLM) else { continue }
                let kSoSanh = Self.chuanHoaKhoaSoSanh(tenChuan)
                if !danhSachKhoaTheoDoi.isEmpty && !danhSachKhoaTheoDoi.contains(kSoSanh) && !danhSachKhoaTheoDoi.contains(kLM) {
                    continue
                }
                tapKhoaDaCo.insert(kLM)
                matHang.append(DongThiDua(
                    tenNganhHangGoc: tenChuan,
                    tenNganhHang: Self.apDungLocTuCaiDat(tenChuan),
                    loaiChiTieu: Self.loaiChiTieuMacDinhChoMon(tenChuan),
                    thucHien: 0,
                    target: 0
                ))
            }
        }

        let dtNVList: [DoanhThuNhanVienItem]
        if cheDo == .luyKe {
            dtNVList = !dlHienTai.doanhThuNhanVien.isEmpty
                ? dlHienTai.doanhThuNhanVien
                : doanhThuNhanVienLuyKeThang(cho: ngay)
        } else {
            dtNVList = dlHienTai.doanhThuNhanVienRealtime
        }

        // Tiền tính toán thông tin mặt hàng và chia Target 1 lần duy nhất thay vì lặp lại 16 x 35 lần
        let tatCaMaSet = Set(dsNV.map(\.maNV))
        let bangChiaTarget = caiDat.chiaTargetNganhHang
        struct ThongTinMatHangTienXuLy {
            let mh: DongThiDua
            let khoa: String
            let khoaLM: String
            let tapMaDuocGiao: Set<String>
            let targetCaNhan: Double
            let phanTramSieuThi: Double
            let bangTHNganh: [String: Double]
        }
        let danhSachMHTienXuLy: [ThongTinMatHangTienXuLy] = matHang.map { mh in
            let k1 = Self.chuanHoaKhoaSoSanh(mh.tenNganhHang)
            let k2 = Self.chuanHoaKhoaSoSanh(mh.tenNganhHangGoc)
            let kLM = Self.chuanHoaKhoaLienMachThiDua(mh.tenNganhHangGoc)
            let tapMa: Set<String>
            if let dsChon = bangChiaTarget[k1] ?? bangChiaTarget[k2] {
                tapMa = Set(dsChon).intersection(tatCaMaSet)
            } else {
                tapMa = tatCaMaSet
            }
            let soNguoi = max(1, tapMa.count)
            return ThongTinMatHangTienXuLy(
                mh: mh,
                khoa: k1,
                khoaLM: kLM,
                tapMaDuocGiao: tapMa,
                targetCaNhan: mh.target / Double(soNguoi),
                phanTramSieuThi: mh.target > 0.0001 ? (mh.thucHien / mh.target) * 100.0 : mh.phanTramHT,
                bangTHNganh: thucHienTheoNganh[k1] ?? thucHienTheoNganh[k2] ?? [:]
            )
        }

        // Tiền ánh xạ doanh thu cá nhân theo mã NV 1 lần duy nhất
        var mapDTCaNhan: [String: DoanhThuNhanVienItem] = [:]
        for item in dtNVList {
            let maChuan = Self.chuanHoaMaNV(item.maNV)
            if tatCaMaSet.contains(maChuan) {
                if mapDTCaNhan[maChuan] == nil {
                    mapDTCaNhan[maChuan] = item
                }
            } else if let khop = Self.khopNhanVienQuetVoiQuanLy(maQuet: item.maNV, tenQuet: item.hoTen, dsQuanLy: dsNV) {
                if mapDTCaNhan[khop.maNV] == nil {
                    mapDTCaNhan[khop.maNV] = item
                }
            }
        }

        let ketQuaChuaXep: [TongHopNhanVien] = dsNV.map { nv in
            let boSungNV = bangSucKhoeThang[nv.maNV]
            let mapPTThiDuaSK = boSungNV?.phanTramThiDuaCaNhan
            var cacMonGiao: [MonThiDuaNhanVien] = []
            cacMonGiao.reserveCapacity(danhSachMHTienXuLy.count)
            for info in danhSachMHTienXuLy {
                guard info.tapMaDuocGiao.contains(nv.maNV) else { continue }
                let thTuBang = info.bangTHNganh[nv.maNV]
                let ptTuSK = mapPTThiDuaSK?[info.khoaLM] ?? mapPTThiDuaSK?[info.khoa]

                let thucHien: Double
                let phanTramHT: Double
                if let ptSK = ptTuSK {
                    if info.targetCaNhan > 0.0001 {
                        if let th = thTuBang, th > 0 {
                            thucHien = th
                            let htTinh = (th / info.targetCaNhan) * 100.0
                            phanTramHT = abs(htTinh - ptSK) <= 2.5 ? ptSK : htTinh
                        } else if ptSK > 0 {
                            let uocTH = (info.targetCaNhan * ptSK) / 100.0
                            thucHien = (uocTH * 100.0).rounded() / 100.0
                            phanTramHT = ptSK
                        } else {
                            thucHien = 0
                            phanTramHT = 0
                        }
                    } else {
                        thucHien = thTuBang ?? 0
                        phanTramHT = max(0, ptSK)
                    }
                } else {
                    thucHien = thTuBang ?? 0
                    phanTramHT = info.targetCaNhan > 0.0001 ? (thucHien / info.targetCaNhan) * 100.0 : 0
                }

                cacMonGiao.append(MonThiDuaNhanVien(
                    khoaNganh: info.khoa,
                    tenNganhHang: info.mh.tenNganhHang,
                    loaiChiTieu: info.mh.loaiChiTieu,
                    thucHien: thucHien,
                    targetCaNhan: info.targetCaNhan,
                    phanTramHT: phanTramHT,
                    phanTramSieuThi: info.phanTramSieuThi
                ))
            }

            cacMonGiao.sort {
                if abs($0.phanTramHT - $1.phanTramHT) > 0.01 { return $0.phanTramHT > $1.phanTramHT }
                if abs($0.thucHien - $1.thucHien) > 0.01 { return $0.thucHien > $1.thucHien }
                return $0.tenNganhHang < $1.tenNganhHang
            }
            let soMonDat = cacMonGiao.filter(\.daDat).count
            let tongMonGiao = cacMonGiao.count
            let phanTramHTTB = tongMonGiao > 0 ? cacMonGiao.map(\.phanTramHT).reduce(0, +) / Double(tongMonGiao) : 0
            let dtCaNhan = mapDTCaNhan[nv.maNV]

            let dtQDCuoi = (boSungNV?.doanhThuQDSucKhoe ?? 0) > 0 ? (boSungNV?.doanhThuQDSucKhoe ?? 0) : (dtCaNhan?.doanhThuQD ?? 0)
            let soDonCuoi = (boSungNV?.soLuotBillBanHang ?? 0) > 0 ? (boSungNV?.soLuotBillBanHang ?? 0) : (dtCaNhan?.soLuong ?? 0)
            let tiTrongCuoi: Double
            if let skQD = boSungNV?.phanTramQuyDoi, skQD != 0 {
                tiTrongCuoi = skQD
            } else if let dtCaNhan, dtCaNhan.phanTramQuyDoi != 0 {
                tiTrongCuoi = dtCaNhan.phanTramQuyDoi
            } else if let dtCaNhan, dtCaNhan.dtTraThangQD != 0 {
                tiTrongCuoi = dtCaNhan.dtTraThangQD
            } else {
                tiTrongCuoi = 0
            }

            return TongHopNhanVien(
                nhanVien: nv,
                soMonDat: soMonDat,
                tongMonGiao: tongMonGiao,
                phanTramHTTB: phanTramHTTB,
                doanhThuQD: dtQDCuoi,
                soLuongDon: soDonCuoi,
                dtQDKhoanVay: dtCaNhan?.dtQDKhoanVay ?? 0,
                dtTraThangQD: (dtCaNhan?.dtTraThangQD ?? 0) > 0 ? (dtCaNhan?.dtTraThangQD ?? 0) : (dtCaNhan?.doanhThuThuc ?? 0),
                phanTramTiTrong: tiTrongCuoi,
                cacMonGiao: cacMonGiao,
                doanhThuCaNhan: dtCaNhan
            )
        }

        let ketQua = Self.sapXepDanhSachTongHopNV(ketQuaChuaXep, theo: sapXep)
        boNhoDemTongHopNV[khoaDem] = ketQua
        return ketQua
    }

    private static func sapXepDanhSachTongHopNV(_ ds: [TongHopNhanVien], theo sapXep: KieuSapXepNhanVien) -> [TongHopNhanVien] {
        var ketQua = ds
        switch sapXep {
        case .tenAZ:
            ketQua.sort { NhanVienQuanLy.soSanhAZ($0.nhanVien, $1.nhanVien) }
        case .soMonHoanThanh:
            ketQua.sort {
                if $0.soMonDat != $1.soMonDat { return $0.soMonDat > $1.soMonDat }
                if abs($0.phanTramHTTB - $1.phanTramHTTB) > 0.001 { return $0.phanTramHTTB > $1.phanTramHTTB }
                if abs($0.doanhThuQD - $1.doanhThuQD) > 0.001 { return $0.doanhThuQD > $1.doanhThuQD }
                return NhanVienQuanLy.soSanhAZ($0.nhanVien, $1.nhanVien)
            }
        case .doanhThuQD:
            ketQua.sort {
                if abs($0.doanhThuQD - $1.doanhThuQD) > 0.001 { return $0.doanhThuQD > $1.doanhThuQD }
                if $0.soMonDat != $1.soMonDat { return $0.soMonDat > $1.soMonDat }
                return NhanVienQuanLy.soSanhAZ($0.nhanVien, $1.nhanVien)
            }
        case .phanTramTB:
            ketQua.sort {
                if abs($0.phanTramHTTB - $1.phanTramHTTB) > 0.001 { return $0.phanTramHTTB > $1.phanTramHTTB }
                if $0.soMonDat != $1.soMonDat { return $0.soMonDat > $1.soMonDat }
                return NhanVienQuanLy.soSanhAZ($0.nhanVien, $1.nhanVien)
            }
        }
        return ketQua
    }

    /// Gộp kết quả quét thực hiện nhân viên theo ngành hàng vào dữ liệu ngày (theo chế độ Lũy kế hoặc Realtime).
    /// Nếu ảnh quét theo mẫu chỉ có % nhân viên đạt được (`item.laPhanTram == true`), tự động quy đổi từ % và Target cá nhân được chia (`targetCaNhan = targetMon / soNVChia`) ra số lượng/doanh thu thực hiện.
    func gopKetQuaThiDuaNhanVien(
        hienTai: [String: [String: Double]],
        mangKhoiNV: [KetQuaThiDuaNhanVienKhoi],
        ngay: Date,
        cheDo: LoaiCheDoDoanhThu = .luyKe,
        khoaNganhMacDinh: String? = nil
    ) -> [String: [String: Double]] {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        var ketQua = hienTai
        var matHangThang = danhSachMatHangThang(den: ngay, cheDo: cheDo)
        if matHangThang.isEmpty {
            matHangThang = danhSachMatHangThang(den: ngay, cheDo: .luyKe)
        }
        let dlNgay = duLieu(cho: ngay)
        let dsThiDuaNgay = dlNgay.danhSachThiDua(theo: cheDo)

        for khoi in mangKhoiNV {
            let tenLoc = Self.apDungLocTuCaiDat(khoi.tenNganhHang)
            var khoaNganh = Self.chuanHoaKhoaSoSanh(tenLoc)

            if let macDinh = khoaNganhMacDinh, !macDinh.isEmpty {
                // Khi người dùng bấm trực tiếp vào 1 môn thi đua để nhập ảnh cho môn đó, ưu tiên gắn đúng vào môn đang mở
                khoaNganh = macDinh
            } else if !khoaNganh.isEmpty {
                if let khop = matHangThang.first(where: {
                    let k = Self.chuanHoaKhoaSoSanh($0.tenNganhHang)
                    return k == khoaNganh || k.contains(khoaNganh) || khoaNganh.contains(k)
                }) {
                    khoaNganh = Self.chuanHoaKhoaSoSanh(khop.tenNganhHang)
                }
            }
            guard !khoaNganh.isEmpty else { continue }

            // Tìm thông tin môn thi đua để lấy Số đã thực hiện của môn đó (thucHienMon)
            let dongMon = dsThiDuaNgay.first(where: {
                Self.chuanHoaKhoaSoSanh($0.tenNganhHang) == khoaNganh ||
                Self.chuanHoaKhoaSoSanh($0.tenNganhHangGoc) == khoaNganh
            }) ?? matHangThang.first(where: {
                Self.chuanHoaKhoaSoSanh($0.tenNganhHang) == khoaNganh ||
                Self.chuanHoaKhoaSoSanh($0.tenNganhHangGoc) == khoaNganh
            })

            let thucHienMon: Double
            if let dongMon, dongMon.thucHien > 0 {
                thucHienMon = dongMon.thucHien
            } else if khoi.thucHienNganhGoiY > 0 {
                thucHienMon = khoi.thucHienNganhGoiY
            } else {
                thucHienMon = dongMon?.thucHien ?? 0
            }

            var bangCu = ketQua[khoaNganh] ?? [:]
            for item in khoi.danhSach {
                let maLuu: String
                if !caiDat.danhSachNhanVien.isEmpty {
                    guard let nvKhop = Self.khopNhanVienQuetVoiQuanLy(
                        maQuet: item.maNV,
                        tenQuet: item.hoTen,
                        dsQuanLy: caiDat.danhSachNhanVien
                    ) else { continue }
                    maLuu = nvKhop.maNV
                } else {
                    maLuu = Self.chuanHoaMaNV(item.maNV)
                }
                guard !maLuu.isEmpty else { continue }
                if item.thucHien >= 0 {
                    if item.laPhanTramTargetCaNhan {
                        let soNVChia = max(1, dongMon.map { danhSachMaNVChiaTarget(cho: $0).count } ?? max(1, caiDat.danhSachNhanVien.count))
                        let targetMon = (dongMon?.target ?? 0) > 0 ? (dongMon?.target ?? 0) : khoi.targetNganhGoiY
                        let targetCaNhan = targetMon / Double(soNVChia)
                        if targetCaNhan > 0 && item.thucHien > 0 {
                            let soLuongNV = (targetCaNhan * item.thucHien) / 100.0
                            bangCu[maLuu] = ((soLuongNV * 100.0).rounded()) / 100.0
                        } else {
                            bangCu[maLuu] = 0
                        }
                    } else if item.laPhanTram {
                        // Lấy số đã thực hiện của môn đó chia 100 rồi nhân với số phần trăm của nhân viên thì được số lượng (doanh thu) thực hiện của nhân viên;
                        // sau đó bảng xếp hạng sẽ lấy số lượng này so sánh với Target được chia để tính Còn/Vượt và % HT.
                        if thucHienMon > 0 {
                            let soLuongNV = (thucHienMon / 100.0) * item.thucHien
                            let lamTron = ((soLuongNV * 10000.0).rounded()) / 10000.0
                            bangCu[maLuu] = lamTron
                        } else {
                            bangCu[maLuu] = 0
                        }
                    } else {
                        bangCu[maLuu] = item.thucHien
                    }
                }
            }
            ketQua[khoaNganh] = bangCu
        }
        return ketQua
    }

    /// Lưu kết quả quét ảnh Phiếu Sức Khỏe & Thi Đua Cá Nhân 27 điểm của nhân viên vào dữ liệu ngày (cập nhật cả Sức khỏe 6 mục Doanh thu + 3 mục Năng suất, Doanh thu NV và Thi đua NV)
    func apDungSucKhoeNhanVienQuetDuoc(
        _ dsSucKhoe: [String: DuLieuSucKhoeBoSungNV],
        vao dl: inout DuLieuNgayDMX,
        ngay: Date,
        cheDo: LoaiCheDoDoanhThu = .luyKe
    ) {
        guard !dsSucKhoe.isEmpty else { return }
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }

        let dsQuanLy = caiDat.danhSachNhanVien
        var matHang = danhSachMatHangThang(den: ngay, cheDo: cheDo)
        if matHang.isEmpty {
            matHang = danhSachMatHangThang(den: ngay, cheDo: .luyKe)
        }

        var mapDTNV: [String: DoanhThuNhanVienItem] = [:]
        for item in dl.doanhThuNhanVien(theo: cheDo) {
            let m = Self.chuanHoaMaNV(item.maNV)
            if !m.isEmpty { mapDTNV[m] = item }
        }
        var bangTDNV = dl.thiDuaNhanVien(theo: cheDo)

        for (maQuet, skMoi) in dsSucKhoe {
            let maChuan = Self.chuanHoaMaNV(maQuet)
            guard !maChuan.isEmpty else { continue }
            let nvKhop = dsQuanLy.first(where: { Self.chuanHoaMaNV($0.maNV) == maChuan })
            let maNV = nvKhop?.maNV ?? maChuan
            let hoTen = nvKhop?.hoTen ?? "NV \(maNV)"

            dl.sucKhoeBoSungNhanVien[maNV] = skMoi
            let tienToThang = String(dl.khoaNgay.prefix(7))
            for kNgay in cacNgay.keys where kNgay.hasPrefix(tienToThang) {
                cacNgay[kNgay]?.sucKhoeBoSungNhanVien[maNV] = skMoi
            }
            let skGop = skMoi

            // Cập nhật DoanhThuNhanVienItem nếu có số liệu Doanh thu QĐ / Số lượt bill / % Quy đổi
            if (skGop.doanhThuQDSucKhoe ?? 0) > 0 || (skGop.soLuotBillBanHang ?? 0) > 0 || (skGop.phanTramQuyDoi ?? 0) > 0 {
                var itemDT = mapDTNV[maNV] ?? DoanhThuNhanVienItem(maNV: maNV, hoTen: hoTen)
                itemDT.maNV = maNV
                itemDT.hoTen = hoTen
                if let dtQD = skGop.doanhThuQDSucKhoe, dtQD > 0 {
                    itemDT.doanhThuQD = dtQD
                }
                if let bill = skGop.soLuotBillBanHang, bill > 0 {
                    itemDT.soLuong = bill
                }
                if let ptQD = skGop.phanTramQuyDoi, ptQD > 0 {
                    itemDT.phanTramQuyDoi = ptQD
                    if itemDT.dtTraThangQD <= 0 { itemDT.dtTraThangQD = ptQD }
                }
                if let mt = skGop.mucTieuTargetQD, mt > 0 {
                    itemDT.target = mt
                }
                if let ptTG = skGop.phanTramTarget, ptTG > 0 {
                    itemDT.phanTramHT = ptTG
                }
                if let ptTC = skGop.phanTramTraCham, ptTC > 0 {
                    itemDT.phanTramTraGop = ptTC
                }
                mapDTNV[maNV] = itemDT
            }

            // Cập nhật bảng thi đua nhân viên cho tất cả các môn (môn nào chưa có mặc định để 0)
            if let bangPT = skGop.phanTramThiDuaCaNhan {
                for mh in matHang {
                    let k1 = Self.chuanHoaKhoaSoSanh(mh.tenNganhHang)
                    let kLM = Self.chuanHoaKhoaLienMachThiDua(mh.tenNganhHangGoc)
                    let pt = bangPT[kLM] ?? bangPT[k1] ?? 0
                    let soNVChia = max(1, danhSachMaNVChiaTarget(cho: mh).count)
                    let targetCaNhan = mh.target / Double(soNVChia)
                    if targetCaNhan > 0 && pt > 0 {
                        let uocTH = (targetCaNhan * pt) / 100.0
                        bangTDNV[k1, default: [:]][maNV] = (uocTH * 100.0).rounded() / 100.0
                    } else if pt <= 0 {
                        bangTDNV[k1, default: [:]][maNV] = 0
                    }
                }
            }
        }

        if !mapDTNV.isEmpty {
            dl.ganDoanhThuNhanVien(Array(mapDTNV.values), theo: cheDo)
        }
        dl.ganThiDuaNhanVien(bangTDNV, theo: cheDo)
    }

    /// Xóa dữ liệu thi đua nhân viên của riêng 1 môn (ngành hàng) cụ thể theo chế độ Lũy kế hoặc Realtime
    func xoaThiDuaNhanVienTheoMon(dong: DongThiDua, ngay: Date, cheDo: LoaiCheDoDoanhThu) {
        khoaTruyCap.lock()
        let k1 = Self.chuanHoaKhoaSoSanh(dong.tenNganhHang)
        let k2 = Self.chuanHoaKhoaSoSanh(dong.tenNganhHangGoc)
        let cacKhoaMon = Set([k1, k2].filter { !$0.isEmpty })
        var dl = duLieu(cho: ngay)

        if cheDo == .realtime {
            for k in cacKhoaMon {
                dl.thiDuaNhanVienRealtime.removeValue(forKey: k)
            }
            khoaTruyCap.unlock()
            luu(dl)
            return
        }

        for k in cacKhoaMon {
            dl.thiDuaNhanVien.removeValue(forKey: k)
        }
        let tienTo = String(dl.khoaNgay.prefix(7))
        var cacNgayCanDay: [DuLieuNgayDMX] = []
        for kNgay in cacNgay.keys where kNgay.hasPrefix(tienTo) && kNgay != dl.khoaNgay {
            guard var dlCu = cacNgay[kNgay] else { continue }
            var coXoa = false
            for k in cacKhoaMon {
                if dlCu.thiDuaNhanVien.removeValue(forKey: k) != nil {
                    coXoa = true
                }
            }
            if coXoa {
                cacNgay[kNgay] = dlCu
                cacNgayCanDay.append(dlCu)
            }
        }
        khoaTruyCap.unlock()
        luu(dl)
        for dlCu in cacNgayCanDay {
            DichVuDongBo.dungChung.dayDuLieuNgay(dlCu)
        }
    }

    /// Danh mục tên môn thi đua chuẩn ĐMX để khôi phục dấu tiếng Việt và khoảng cách chuẩn xác 100% khi OCR bị dính chữ
    static let danhSachTenMonThiDuaChuanDMX: [String] = [
        "Máy Lạnh",
        "Đồng hồ & Smartwatch",
        "Cáp sạc",
        "Đèn năng lượng mặt trời",
        "Điện thoại Realme",
        "Laptop",
        "Loa Phụ Kiện",
        "Máy lọc KK - Hút bụi - Hút ẩm",
        "Máy lọc nước",
        "Máy sấy / Máy rửa chén",
        "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBAK EVO",
        "Phụ kiện công nghệ",
        "Phụ kiện khác IT & Nhóm khác",
        "Tivi TCL",
        "Trả chậm FECREDIT, SAMSUNG F+, SHINHAN, MCREDIT",
        "Trả chậm Homecredit",
        "Vay tiền mặt",
        "Ví trả sau",
        "Bảo hiểm Thợ ICT",
        "Bảo hiểm Thợ ĐMX",
        "Trả Chậm Điện máy & Gia dụng",
        "Bảo hiểm Tổng",
        "Nạp rút",
        "Điện tử",
        "Máy giặt",
        "Camera",
        "Máy nước nóng",
        "ĐIỆN THOẠI & TABLET ANDROID",
        "Tai nghe",
        "Quạt gió",
        "CE LG",
        "Nồi cơm & Nồi chiên",
        "Điện tử Samsung",
        "Sim ĐMX",
        "Sim",
        "Điện thoại Vivo",
        "Sạc dự phòng",
        "VAS",
        "Tủ Lạnh / Đông / Mát"
    ]

    private static let bangAnhXaKhoaLienMachChuanDMX: [String: String] = {
        var map: [String: String] = [:]
        for ten in danhSachTenMonThiDuaChuanDMX {
            let k = taoKhoaLienMachKhongThang(ten)
            if !k.isEmpty {
                map[k] = ten
            }
        }
        // Ánh xạ tương thích cả bản rút gọn không có MCREDIT sang cùng 1 tên chuẩn
        map["TRACHAMFECREDITSAMSUNGFSHINHAN"] = "Trả chậm FECREDIT, SAMSUNG F+, SHINHAN, MCREDIT"
        map["TRACHAMFECREDITSAMSUNGFSHINHANMCREDIT"] = "Trả chậm FECREDIT, SAMSUNG F+, SHINHAN, MCREDIT"
        map["MOTHETINDUNGVPBANKMWGVATPBAKEVO"] = "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBAK EVO"
        map["MOTHETINDUNGVPBANKMWGVATPBANKEVO"] = "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBAK EVO"
        map["MOTHETINDUNGVPBANKMWG"] = "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBAK EVO"
        map["MOTHETINDUNGVPBANK"] = "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBAK EVO"
        map["MWGVATPBAKEVO"] = "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBAK EVO"
        map["MWGVATPBANKEVO"] = "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBAK EVO"
        map["BAOHIEMTHOICT"] = "Bảo hiểm Thợ ICT"
        map["BAOHIEMTHODMX"] = "Bảo hiểm Thợ ĐMX"
        map["VITRASAU"] = "Ví trả sau"
        map["PHUKIENKHACITNHOMKHAC"] = "Phụ kiện khác IT & Nhóm khác"
        map["PHUKIENKHACIT"] = "Phụ kiện khác IT & Nhóm khác"
        map["TRACHAMDIENMAYGIADUNG"] = "Trả Chậm Điện máy & Gia dụng"
        map["TRACHAMDIENMAY"] = "Trả Chậm Điện máy & Gia dụng"
        map["DIENTHOAITABLETANDROID"] = "ĐIỆN THOẠI & TABLET ANDROID"
        map["DIENTHOAITABLET"] = "ĐIỆN THOẠI & TABLET ANDROID"
        map["SIM"] = "Sim"
        return map
    }()

    static func loaiChiTieuMacDinhChoMon(_ ten: String) -> LoaiChiTieuThiDua {
        let k = taoKhoaLienMachKhongThang(ten)
        switch k {
        case "MAYLANH", "MAYNUOCNONG", "DENNANGLUONGMATTROI", "MOTHETINDUNGVPBANKMWGVATPBAKEVO", "SIM", "SIMDMX", "VITRASAU", "NAPRUT":
            return .soLuong
        default:
            return .doanhThu
        }
    }

    static func laTenMonThiDuaChuanDMX(_ ten: String) -> Bool {
        let k = taoKhoaLienMachKhongThang(ten)
        return bangAnhXaKhoaLienMachChuanDMX[k] != nil
    }

    private static func khoangCachLevenshtein(_ a: String, _ b: String) -> Int {
        let s1 = Array(a.utf8)
        let s2 = Array(b.utf8)
        let m = s1.count
        let n = s2.count
        if m == 0 { return n }
        if n == 0 { return m }
        if abs(m - n) > 3 { return abs(m - n) }
        var prev = Array(0...n)
        var curr = Array(repeating: 0, count: n + 1)
        for i in 1...m {
            curr[0] = i
            for j in 1...n {
                let cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1
                curr[j] = min(min(curr[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost)
            }
            swap(&prev, &curr)
        }
        return prev[n]
    }

    static func taoKhoaLienMachKhongThang(_ ten: String) -> String {
        khoaBoNhoDemTinh.lock()
        if let daDem = boNhoDemKhoaLMKhongThang[ten] {
            khoaBoNhoDemTinh.unlock()
            return daDem
        }
        khoaBoNhoDemTinh.unlock()

        var khongDau = ten
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "D")
            .uppercased()
            .replacingOccurrences(of: "^[^A-Z0-9]+", with: "", options: .regularExpression)

        // Cắt an toàn tối đa 4 lần các cụm tiền tố tháng ở đầu mà không dùng regex lồng nhau (tránh tràn stack trên luồng nền 512KB)
        for _ in 0..<4 {
            guard let rGach = khongDau.range(of: "^[^\\-–—−]{1,12}[-–—−]+\\s*", options: .regularExpression) else {
                break
            }
            let truoc = String(khongDau[rGach])
                .replacingOccurrences(of: "[-–—−\\s]+$", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if truoc.range(of: "^(?:[A-Z]{1,2}\\s+)?[T71IL0-9\\s]{1,8}$", options: .regularExpression) != nil {
                khongDau = String(khongDau[rGach.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                break
            }
        }
        khongDau = khongDau.replacingOccurrences(of: "^(?:T\\d{1,2}|711|111|I11|1I1|11)\\s+", with: "", options: .regularExpression)

        var boHauTo = khongDau
            .replacingOccurrences(of: "\\s*(?:\\(\\s*#?\\d+\\s*\\)|#\\d+)\\s*$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "(?:\\s+|\\s*[\\|¦_]\\s*)\\b(DT|SL|5L|0T|OT|SI|ST|PR|PRT|PT|OR|OX|SE|RI|BT|07|D7|DI|DL|SV|S1|51)\\b\\s*$", with: "", options: .regularExpression)
        let laBaoHiem = boHauTo.contains("BAO HIEM") || boHauTo.contains("BAOHIEM")
        if laBaoHiem {
            if boHauTo.contains("ICT") || boHauTo.contains("1CT") || boHauTo.contains("LCT") || boHauTo.contains("IC7") {
                boHauTo = "BAO HIEM THO ICT"
            } else if boHauTo.contains("DMX") || boHauTo.contains("OMX") || boHauTo.contains("BMX") || boHauTo.contains("0MX") {
                boHauTo = "BAO HIEM THO DMX"
            } else if boHauTo.contains("TONG") || boHauTo.contains("T0NG") {
                boHauTo = "BAO HIEM TONG"
            }
        } else if !boHauTo.contains("THO ICT") && !boHauTo.contains("THO 1CT") && !boHauTo.contains("THO LCT") {
            boHauTo = boHauTo.replacingOccurrences(of: "\\s+\\b(CE|ICT|1CT|LCT|LER|DV|BV|OV|0V|MDA|SDA|GD)\\b\\s*$", with: "", options: .regularExpression)
        } else {
            boHauTo = boHauTo
                .replacingOccurrences(of: "THO 1CT", with: "THO ICT")
                .replacingOccurrences(of: "THO LCT", with: "THO ICT")
        }
        boHauTo = boHauTo.replacingOccurrences(of: "\\s+\\b(?:11|I1|1I|T11)\\b\\s*$", with: "", options: .regularExpression)
        var ketQua = boHauTo.replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
        if (ketQua.contains("MOTHETINDUNG") || ketQua.contains("THETINDUNG") || ketQua.contains("MOTHE")) &&
           (ketQua.contains("VPBANK") || ketQua.contains("VP8ANK") || ketQua.contains("TPBAK") || ketQua.contains("TPBANK") || ketQua.contains("MWG") || ketQua.contains("EVO") || ketQua.contains("EV0")) {
            ketQua = "MOTHETINDUNGVPBANKMWGVATPBAKEVO"
        } else if (ketQua.contains("VPBANK") || ketQua.contains("VP8ANK")) &&
                  (ketQua.contains("MWG") || ketQua.contains("TPBAK") || ketQua.contains("TPBANK") || ketQua.contains("EVO") || ketQua.contains("EV0") || ketQua.contains("TINDUNG")) {
            ketQua = "MOTHETINDUNGVPBANKMWGVATPBAKEVO"
        } else if (ketQua.contains("TPBAK") || ketQua.contains("TPBANK")) &&
                  (ketQua.contains("MWG") || ketQua.contains("EVO") || ketQua.contains("EV0") || ketQua.contains("TINDUNG") || ketQua.contains("MOTHE")) {
            ketQua = "MOTHETINDUNGVPBANKMWGVATPBAKEVO"
        } else if ketQua == "MOTHETINDUNGVPBANKMWGVATPBANKEVO" {
            ketQua = "MOTHETINDUNGVPBANKMWGVATPBAKEVO"
        } else if ketQua == "TRACHAMFECREDITSAMSUNGFSHINHAN" {
            ketQua = "TRACHAMFECREDITSAMSUNGFSHINHANMCREDIT"
        } else if ketQua == "DIENTUY" || ketQua == "DIENTU0T" || ketQua == "DIENTUOT" {
            ketQua = "DIENTU"
        } else if ketQua == "SIMOMX" || ketQua == "SIMBMX" || ketQua == "SIM0MX" {
            ketQua = "SIMDMX"
        } else if ketQua == "5IM" || ketQua == "S1M" {
            ketQua = "SIM"
        }

        khoaBoNhoDemTinh.lock()
        boNhoDemKhoaLMKhongThang[ten] = ketQua
        khoaBoNhoDemTinh.unlock()
        return ketQua
    }

    /// Làm sạch và chuẩn hoá tên môn thi đua (loại bỏ nhãn CE/ICT/DV, DT/SL, ký hiệu sao, hậu tố #2, tiền tố T11 lặp và khôi phục tên chuẩn ĐMX)
    static func chuanHoaTenMonThiDuaChuan(_ tenGoc: String, tienToThangMacDinh: String? = nil) -> String {
        let khoaDem = tienToThangMacDinh == nil ? tenGoc : "\(tenGoc)|\(tienToThangMacDinh!)"
        khoaBoNhoDemTinh.lock()
        if let daDem = boNhoDemTenChuan[khoaDem] {
            khoaBoNhoDemTinh.unlock()
            return daDem
        }
        khoaBoNhoDemTinh.unlock()

        var s = tenGoc
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "^[^A-Za-zÀ-ỹĐđ0-9]+", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !s.isEmpty else { return "" }

        // Vòng lặp giới hạn 4 bước cắt sạch mọi tiền tố tháng lặp ("T11 - 11 T11 -", "11 T11 -", "711 -", "gy T1-") mà không dùng regex lồng nhau
        var tienToThang = ""
        for _ in 0..<4 {
            guard let rGach = s.range(of: "^[^\\-–—−]{1,12}[-–—−]+\\s*", options: .regularExpression) else {
                break
            }
            let truoc = String(s[rGach])
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
                .uppercased()
                .replacingOccurrences(of: "[-–—−\\s]+$", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if truoc.range(of: "^(?:[A-Z]{1,2}\\s+)?[T71IL0-9\\s]{1,8}$", options: .regularExpression) != nil {
                if truoc.contains("11") || truoc.contains("I1") || truoc.contains("1I") {
                    tienToThang = "T11"
                } else if tienToThang.isEmpty {
                    if let rSo = truoc.range(of: "1[0-2]|[1-9]", options: .regularExpression) {
                        tienToThang = tienToThangMacDinh ?? "T\(truoc[rSo])"
                    } else {
                        tienToThang = tienToThangMacDinh ?? "T11"
                    }
                }
                s = String(s[rGach.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                break
            }
        }
        if tienToThang.isEmpty, let macDinh = tienToThangMacDinh, !macDinh.isEmpty {
            tienToThang = macDinh
        }

        // Nếu đầu chuỗi vẫn còn sót "11 " hoặc "T11 " rời thì cắt bỏ
        for _ in 0..<3 {
            if let rDu = s.range(of: "^(?:T\\d{1,2}|711|111|I11|1I1|11|[-–—−]+)\\s+", options: [.regularExpression, .caseInsensitive]) {
                s = String(s[rDu.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                break
            }
        }

        // Bỏ hậu tố đánh số (#2), đơn vị (DT/SL), nhãn phân nhóm (CE/ICT/DV) và số 11 thừa bị dính ở cuối (giữ nguyên ICT cho "Bảo hiểm Thợ ICT")
        s = s
            .replacingOccurrences(of: "\\s*(?:\\(\\s*#?\\d+\\s*\\)|#\\d+)\\s*$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "(?:\\s+|\\s*[\\|¦_]\\s*)\\b(DT|SL|5L|0T|OT|SI|ST|PR|PRT|PT|OR|OX|SE|RI|BT|07|D7|DI|DL|SV|S1|51)\\b\\s*$", with: "", options: [.regularExpression, .caseInsensitive])
        let sCheckKhongDau = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN")).uppercased()
        let laBaoHiemCheck = sCheckKhongDau.contains("BAO HIEM") || sCheckKhongDau.contains("BAOHIEM")
        if !laBaoHiemCheck && !sCheckKhongDau.contains("THO ICT") && !sCheckKhongDau.contains("THO 1CT") && !sCheckKhongDau.contains("THO LCT") {
            s = s.replacingOccurrences(of: "\\s+\\b(CE|ICT|1CT|LCT|LER|DV|BV|OV|0V|MDA|SDA|GD)\\b\\s*$", with: "", options: [.regularExpression, .caseInsensitive])
        }
        s = s
            .replacingOccurrences(of: "\\s+\\b(?:11|T11)\\b\\s*$", with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "\\bCELG\\b", with: "CE LG", options: .regularExpression)
            .replacingOccurrences(of: "\\bBMX\\b", with: "ĐMX", options: .regularExpression)
            .replacingOccurrences(of: "\\s*/\\s*", with: " / ", options: .regularExpression)
            .replacingOccurrences(of: "\\s*,\\s*", with: ", ", options: .regularExpression)
            .replacingOccurrences(of: "\\.{2,}|…", with: "", options: .regularExpression)
            .replacingOccurrences(of: "^[\\s\\|¦\\-–—−•◦○●⊕⊖/\\\\.:;,…]+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "[\\s\\|¦\\-–—−•◦○●⊕⊖/\\\\.:;,…]+$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let klm = taoKhoaLienMachKhongThang(s)
        var tenChuan = s
        if let khopChinhXac = bangAnhXaKhoaLienMachChuanDMX[klm] {
            tenChuan = khopChinhXac
        } else if klm == "DIENTHOAITABLET" || klm == "DIENTHOAITABLETANDROID" {
            tenChuan = "ĐIỆN THOẠI & TABLET ANDROID"
        } else if klm == "SAMSUNG" || (klm.hasSuffix("SAMSUNG") && klm.count <= 14 && !klm.contains("FECREDIT")) {
            tenChuan = "Điện tử Samsung"
        } else if klm.count >= 6 {
            let nguong = (klm.count >= 8) ? 2 : 1
            var totNhat: (ten: String, kc: Int)?
            for (kMau, tenMau) in bangAnhXaKhoaLienMachChuanDMX {
                guard abs(klm.count - kMau.count) <= nguong else { continue }
                let kc = khoangCachLevenshtein(klm, kMau)
                if kc <= nguong {
                    if totNhat == nil || kc < totNhat!.kc {
                        totNhat = (tenMau, kc)
                    }
                }
            }
            if let totNhat {
                tenChuan = totNhat.ten
            }
        }

        let ketQuaCuoi = !tienToThang.isEmpty ? "\(tienToThang) - \(tenChuan)" : tenChuan
        khoaBoNhoDemTinh.lock()
        boNhoDemTenChuan[khoaDem] = ketQuaCuoi
        if tienToThangMacDinh == nil {
            boNhoDemTenChuan[ketQuaCuoi] = ketQuaCuoi
        }
        khoaBoNhoDemTinh.unlock()
        return ketQuaCuoi
    }

    static func apDungLocTuCaiDat(_ tenGoc: String) -> String {
        khoaBoNhoDemTinh.lock()
        if let daDem = boNhoDemLocTen[tenGoc] {
            khoaBoNhoDemTinh.unlock()
            return daDem
        }
        let danhSachLoc = danhSachCumTuLocBoTinh
        khoaBoNhoDemTinh.unlock()

        var s = chuanHoaTenMonThiDuaChuan(tenGoc)

        for cumTu in danhSachLoc {
            let sach = cumTu.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sach.isEmpty else { continue }
            s = s.replacingOccurrences(of: sach, with: "", options: .caseInsensitive)
        }

        s = s
            .replacingOccurrences(of: "^[\\s\\|¦\\-–—−•◦○●⊕⊖/\\\\.:;,…]+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "[\\s\\|¦\\-–—−•◦○●⊕⊖/\\\\.:;,…]+$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\|\\s*\\|+", with: "|", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let ketQua = s.isEmpty ? tenGoc.trimmingCharacters(in: .whitespacesAndNewlines) : s

        khoaBoNhoDemTinh.lock()
        boNhoDemLocTen[tenGoc] = ketQua
        khoaBoNhoDemTinh.unlock()
        return ketQua
    }

    /// Chuẩn hoá khóa tên ngành hàng cơ bản (bỏ hậu tố đánh số trùng như "(#2)", "#2", nhãn CE/ICT/DV, DT/SL) để so sánh và lọc trùng 100%
    static func chuanHoaKhoaCoBanThiDua(_ ten: String) -> String {
        khoaBoNhoDemTinh.lock()
        if let daDem = boNhoDemKhoaCoBan[ten] {
            khoaBoNhoDemTinh.unlock()
            return daDem
        }
        khoaBoNhoDemTinh.unlock()

        let sach = chuanHoaTenMonThiDuaChuan(ten)
        let ketQua = chuanHoaKhoaSoSanh(sach)
            .replacingOccurrences(of: "\\s*\\(?#?\\d+\\)?$", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        khoaBoNhoDemTinh.lock()
        boNhoDemKhoaCoBan[ten] = ketQua
        khoaBoNhoDemTinh.unlock()
        return ketQua
    }

    /// Khóa tên môn thi đua không tính tiền tố tháng (ví dụ "T11 - Máy Lạnh" và "Máy Lạnh" đều có khóa "MAYLANH")
    static func chuanHoaKhoaLienMachThiDua(_ ten: String) -> String {
        khoaBoNhoDemTinh.lock()
        if let daDem = boNhoDemKhoaLienMach[ten] {
            khoaBoNhoDemTinh.unlock()
            return daDem
        }
        khoaBoNhoDemTinh.unlock()

        let sach = chuanHoaTenMonThiDuaChuan(ten)
        let k = taoKhoaLienMachKhongThang(sach)
        let ketQua = !k.isEmpty ? k : chuanHoaKhoaCoBanThiDua(sach).replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)

        khoaBoNhoDemTinh.lock()
        boNhoDemKhoaLienMach[ten] = ketQua
        khoaBoNhoDemTinh.unlock()
        return ketQua
    }

    /// Gộp và lọc trùng danh sách môn thi đua với độ phức tạp O(N) qua bảng băm:
    /// So sánh giữa các môn mới quét được với nhau và so sánh với các môn có sẵn; nếu tên môn giống nhau 100% thì chỉ giữ lại 1 môn duy nhất.
    /// Kiểm tra xem một chuỗi tên có phải là dòng nhân viên (có mã NV 5-7 số, tiền tố id:, hoặc trùng tên nhân viên) bị quét nhầm vào bảng Thi đua hay không
    static func laTenDongNhanVienBiQuetNham(_ ten: String) -> Bool {
        let s = ten.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return true }
        if laTenMonThiDuaChuanDMX(s) {
            return false
        }
        let u = chuanHoaKhoaSoSanh(s)
        if u.contains("MO THE") || u.contains("TIN DUNG") || u.contains("VPBANK") || u.contains("TPBAK") || u.contains("TPBANK") {
            return false
        }
        if u.range(of: "\\b(?:ID|LD|1D)\\b", options: .regularExpression) != nil {
            return true
        }
        if s.range(of: "(?i)\\b(?:id|ld|1d)\\s*[:.;\\-]?\\s*\\d{3,7}", options: .regularExpression) != nil {
            return true
        }
        if s.range(of: "\\b\\d{5,7}\\b", options: .regularExpression) != nil {
            return true
        }
        if u == "NHAN VIEN" || u.contains("NGANH HANG BI") || u.contains("NHOM HANG BI") || u.contains("DT QD KHOAN VAY") || u.contains("TI TRONG") {
            return true
        }
        let tenKhongId = u
            .replacingOccurrences(of: "\\b(?:ID|LD|1D)\\b", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\d+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        for nv in CaiDatDMX.nhanVienMau {
            let tenNV = chuanHoaKhoaSoSanh(nv.hoTen)
            if tenKhongId == tenNV || u.contains(tenNV) {
                return true
            }
        }
        if tenKhongId == "PHAN THUONG VINH" || tenKhongId == "VINH" {
            return true
        }
        return false
    }

    static func gopDanhSachThiDua(cu: [DongThiDua], moi: [DongThiDua]) -> [DongThiDua] {
        let tatCa = cu.isEmpty ? moi : (cu + moi)
        guard !tatCa.isEmpty else { return [] }

        var ketQua: [DongThiDua] = []
        ketQua.reserveCapacity(tatCa.count)

        for var dongMoi in tatCa {
            let tenKiemTra = dongMoi.tenNganhHangGoc.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !tenKiemTra.isEmpty, !laTenDongNhanVienBiQuetNham(tenKiemTra), !laTenDongNhanVienBiQuetNham(dongMoi.tenNganhHang) else { continue }

            let gocSach = chuanHoaTenMonThiDuaChuan(dongMoi.tenNganhHangGoc)
            dongMoi.tenNganhHangGoc = gocSach.isEmpty ? dongMoi.tenNganhHangGoc : gocSach
            dongMoi.tenNganhHang = apDungLocTuCaiDat(dongMoi.tenNganhHangGoc)

            let khoaCoBanMoi = chuanHoaKhoaCoBanThiDua(dongMoi.tenNganhHangGoc)
            let khoaLienMachGocMoi = chuanHoaKhoaLienMachThiDua(dongMoi.tenNganhHangGoc)
            guard !khoaCoBanMoi.isEmpty || !khoaLienMachGocMoi.isEmpty else { continue }

            // Chỉ gộp thành 1 môn khi TRÙNG 100% VỀ TÊN và TRÙNG VỀ TARGET & THỰC HIỆN (hoặc 1 bên đang trống target/thực hiện = 0 khi ghép cặp ảnh 2 cột)
            var viTriTrung: Int? = nil
            for (idxCu, dongCu) in ketQua.enumerated() {
                let khoaCoBanCu = chuanHoaKhoaCoBanThiDua(dongCu.tenNganhHangGoc)
                let khoaLienMachCu = chuanHoaKhoaLienMachThiDua(dongCu.tenNganhHangGoc)
                let trungTen100 = (!khoaCoBanMoi.isEmpty && khoaCoBanMoi == khoaCoBanCu) ||
                                  (!khoaLienMachGocMoi.isEmpty && khoaLienMachGocMoi == khoaLienMachCu)
                guard trungTen100 else { continue }

                let cuChuaCoSo = (abs(dongCu.thucHien) < 0.0001 && abs(dongCu.target) < 0.0001) ||
                                 (abs(dongCu.target) < 0.0001 && abs(dongMoi.thucHien) < 0.0001) ||
                                 (abs(dongCu.thucHien) < 0.0001 && abs(dongMoi.target) < 0.0001)
                let moiChuaCoSo = (abs(dongMoi.thucHien) < 0.0001 && abs(dongMoi.target) < 0.0001)
                let trungTargetVaDoanhThu = abs(dongCu.target - dongMoi.target) < 0.05 &&
                                            abs(dongCu.thucHien - dongMoi.thucHien) < 0.05

                if trungTargetVaDoanhThu || cuChuaCoSo || moiChuaCoSo {
                    viTriTrung = idxCu
                    break
                }
            }

            if let viTri = viTriTrung {
                var dongCu = ketQua[viTri]
                let moiLaChuan = laTenMonThiDuaChuanDMX(dongMoi.tenNganhHangGoc)
                let cuLaChuan = laTenMonThiDuaChuanDMX(dongCu.tenNganhHangGoc)
                if (moiLaChuan && !cuLaChuan) || (moiLaChuan == cuLaChuan && dongMoi.tenNganhHangGoc.count >= dongCu.tenNganhHangGoc.count) {
                    dongCu.tenNganhHangGoc = dongMoi.tenNganhHangGoc
                    dongCu.tenNganhHang = dongMoi.tenNganhHang
                }
                dongCu.loaiChiTieu = dongMoi.loaiChiTieu
                if abs(dongMoi.thucHien) > 0.0001 || (dongMoi.target > 0 && dongMoi.phanTramHTGoc != nil) {
                    dongCu.thucHien = dongMoi.thucHien
                }
                if dongMoi.target > 0 {
                    dongCu.target = dongMoi.target
                }
                if let htGoc = dongMoi.phanTramHTGoc {
                    dongCu.phanTramHTGoc = htGoc
                }
                if let dbGoc = dongMoi.phanTramDuBaoGoc {
                    dongCu.phanTramDuBaoGoc = dbGoc
                }
                if let dkGoc = dongMoi.duKienGoc, dkGoc > 0 {
                    dongCu.duKienGoc = dkGoc
                }
                ketQua[viTri] = dongCu
            } else {
                ketQua.append(dongMoi)
            }
        }
        return ketQua
    }

    static func chuanHoaKhoaSoSanh(_ ten: String) -> String {
        khoaBoNhoDemTinh.lock()
        if let daDem = boNhoDemKhoaSoSanh[ten] {
            khoaBoNhoDemTinh.unlock()
            return daDem
        }
        khoaBoNhoDemTinh.unlock()

        let ketQua = ten.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "D")
            .replacingOccurrences(of: "[\\|¦\\-–—−•◦○●⊕⊖/\\\\.:;,…]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        khoaBoNhoDemTinh.lock()
        boNhoDemKhoaSoSanh[ten] = ketQua
        khoaBoNhoDemTinh.unlock()
        return ketQua
    }

    static func chuanHoaMaNV(_ raw: String) -> String {
        if let range = raw.range(of: "\\b\\d{3,10}\\b", options: .regularExpression) {
            return String(raw[range])
        }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func khopNhanVienQuetVoiQuanLy(
        maQuet: String,
        tenQuet: String,
        dsQuanLy: [NhanVienQuanLy]
    ) -> NhanVienQuanLy? {
        let maSach = chuanHoaMaNV(maQuet.isEmpty ? tenQuet : maQuet)
        if !maSach.isEmpty {
            if let theoMa = dsQuanLy.first(where: { $0.maNV == maSach }) {
                return theoMa
            }
            if maSach.count >= 6 {
                let boDauKyTu = String(maSach.dropFirst())
                if let theoMaBoDau = dsQuanLy.first(where: { $0.maNV == boDauKyTu }) {
                    return theoMaBoDau
                }
            }
        }

        let tenKhongSo = tenQuet
            .replacingOccurrences(of: "(?i)\\b(?:id|ld|1d|ia|iđ|ma|mã)\\b\\s*[:.;\\-]?", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\d+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "[-–—+]", with: " ", options: .regularExpression)
        let tenChuan = chuanHoaKhoaSoSanh(tenKhongSo)

        // Nếu có mã NV quét được bị lệch tối đa 1 chữ số và phần tên khớp đầu tên nhân viên trong danh sách
        if maSach.count >= 4 {
            let ungVienGanMa = dsQuanLy.filter { nv in
                guard abs(nv.maNV.count - maSach.count) <= 1 else { return false }
                let a = Array(nv.maNV)
                let b = Array(maSach)
                if a.count == b.count {
                    return zip(a, b).filter { $0 != $1 }.count <= 1
                } else {
                    return nv.maNV.contains(maSach) || maSach.contains(nv.maNV)
                }
            }
            if ungVienGanMa.count == 1, !tenChuan.isEmpty {
                let nv = ungVienGanMa[0]
                let nvChuan = chuanHoaKhoaSoSanh(nv.hoTen)
                if nvChuan.hasPrefix(tenChuan) || nvChuan.contains(tenChuan) {
                    return nv
                }
            } else if ungVienGanMa.count > 1, !tenChuan.isEmpty {
                if let khop = ungVienGanMa.first(where: { chuanHoaKhoaSoSanh($0.hoTen).hasPrefix(tenChuan) }) {
                    return khop
                }
            }
            // Nếu đã có mã NV 4-7 chữ số rõ ràng nhưng hoàn toàn khác mã với mọi NV trong danh sách (ví dụ NV mới 65257),
            // tuyệt đối không ghép bừa theo họ phổ biến (như "Nguyễn", "Huỳnh", "Đỗ Thị", "Phan") để tránh ghi đè nhầm NV khác
            if !tenChuan.isEmpty {
                if let khopHoTenDayDu = dsQuanLy.first(where: { chuanHoaKhoaSoSanh($0.hoTen) == tenChuan }) {
                    return khopHoTenDayDu
                }
            }
            return nil
        }

        guard !tenChuan.isEmpty else { return nil }
        for nv in dsQuanLy {
            let nvChuan = chuanHoaKhoaSoSanh(nv.hoTen)
            if nvChuan == tenChuan || nvChuan.hasSuffix(tenChuan) || tenChuan.hasSuffix(nvChuan) || nvChuan.contains(tenChuan) {
                return nv
            }
        }
        return nil
    }

    static func huyChuongHang(_ hang: Int) -> String {
        switch hang {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(hang)"
        }
    }

    /// Phân tích Sức khỏe Nhân viên toàn đội (~16 NV) và phát hiện Top 5 nhân viên yếu nhiều ngày liên tục
    func tinhBaoCaoSucKhoeNhanVien(
        den ngay: Date,
        cheDo: LoaiCheDoDoanhThu = .luyKe
    ) -> BaoCaoSucKhoeDoiNgu {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }

        let khoaDen = TienIchNgay.khoa.string(from: ngay)
        let khoaDem = "\(khoaDen)|\(cheDo.rawValue)"
        if let daDem = boNhoDemBaoCaoSucKhoe[khoaDem] {
            return daDem
        }

        let dsNV = NhanVienQuanLy.sapXepAZ(caiDat.danhSachNhanVien)
        guard !dsNV.isEmpty else {
            return BaoCaoSucKhoeDoiNgu(
                ngayBaoCao: ngay,
                cheDo: cheDo,
                soNgayDaTheoDoi: 0,
                cacNhanNgayTheoDoi: [],
                soNVKhoe: 0,
                soNVTrungBinh: 0,
                soNVYeu: 0,
                diemTrungBinhDoiNgu: 0,
                top5CanhBaoYeu: [],
                danhSachTatCa: []
            )
        }

        let tienToThang = String(khoaDen.prefix(7))

        // Lấy các ngày trong tháng hiện tại (và tối đa 10 ngày cuối tháng trước nếu đầu tháng) có dữ liệu nhân viên
        var cacKhoaUngVien = cacNgay.keys.filter { $0 <= khoaDen && $0.hasPrefix(tienToThang) }.sorted()
        if cacKhoaUngVien.count < 7 {
            let cacKhoaTruoc = cacNgay.keys.filter { $0 < khoaDen && !$0.hasPrefix(tienToThang) }.sorted().suffix(10)
            cacKhoaUngVien = Array(cacKhoaTruoc) + cacKhoaUngVien
        }
        if !cacKhoaUngVien.contains(khoaDen) {
            cacKhoaUngVien.append(khoaDen)
        }

        struct BanGhiNgay {
            let khoaNgay: String
            let ngayTrongThang: Int
            let nhanNgay: String
            let bangDiem: [String: DiemSucKhoeNgayNV]
        }

        var cacBanGhiNgay: [BanGhiNgay] = []

        for khoa in cacKhoaUngVien {
            guard let ngayD = TienIchNgay.khoa.date(from: khoa) else { continue }
            let dlRaw = cacNgay[khoa]
            let coDuLieuRiengNgay: Bool
            if let dlRaw {
                coDuLieuRiengNgay = !dlRaw.thiDuaNhanVien.isEmpty
                    || !dlRaw.thiDuaNhanVienRealtime.isEmpty
                    || !dlRaw.doanhThuNhanVienRealtime.isEmpty
                    || !dlRaw.danhSachThiDua.isEmpty
                    || !dlRaw.danhSachThiDuaRealtime.isEmpty
                    || (khoa == khoaDen && !dlRaw.doanhThuNhanVien.isEmpty)
            } else {
                coDuLieuRiengNgay = (khoa == khoaDen)
            }
            guard coDuLieuRiengNgay else { continue }

            // Chọn chế độ có dữ liệu thực tế cho ngày đó (ưu tiên cheDo đang chọn, nếu trống thì lấy chế độ còn lại)
            var dsTH = tongHopNhanVien(den: ngayD, sapXep: .soMonHoanThanh, cheDo: cheDo)
            let coSoChinh = dsTH.contains { $0.tongMonGiao > 0 || $0.doanhThuQD > 0 || $0.soMonDat > 0 }
            if !coSoChinh {
                let cheDoPhu: LoaiCheDoDoanhThu = (cheDo == .luyKe) ? .realtime : .luyKe
                let dsPhu = tongHopNhanVien(den: ngayD, sapXep: .soMonHoanThanh, cheDo: cheDoPhu)
                if dsPhu.contains(where: { $0.tongMonGiao > 0 || $0.doanhThuQD > 0 || $0.soMonDat > 0 }) {
                    dsTH = dsPhu
                } else if khoa != khoaDen {
                    continue
                }
            }

            let coThiDua = dsTH.contains { $0.tongMonGiao > 0 }
            let dsCoDT = dsTH.filter { $0.doanhThuQD > 0 }
            let coDoanhThu = !dsCoDT.isEmpty
            let tbHTTB = dsTH.map(\.phanTramHTTB).reduce(0.0, +) / Double(max(1, dsTH.count))
            let tbDTQD = coDoanhThu ? (dsCoDT.map(\.doanhThuQD).reduce(0.0, +) / Double(dsCoDT.count)) : 0

            var diemTamTheoMa: [String: (diem: Double, th: TongHopNhanVien)] = [:]
            for th in dsTH {
                let tyLeMon = th.tongMonGiao > 0 ? (Double(th.soMonDat) / Double(th.tongMonGiao)) * 100.0 : 0
                let diemHTTuyetDoi = min(100.0, th.phanTramHTTB)
                let diemHTTuongDoi = tbHTTB > 0.01 ? min(100.0, (th.phanTramHTTB / tbHTTB) * 72.0) : diemHTTuyetDoi
                let diemThiDua = 0.35 * tyLeMon + 0.30 * diemHTTuyetDoi + 0.35 * diemHTTuongDoi

                let diemDT: Double
                if coDoanhThu && tbDTQD > 0 {
                    let diemSoVoiTB = min(100.0, (th.doanhThuQD / tbDTQD) * 74.0)
                    if let ptCN = th.doanhThuCaNhan?.phanTramHT, ptCN > 0 {
                        diemDT = 0.45 * min(100.0, ptCN) + 0.55 * diemSoVoiTB
                    } else {
                        diemDT = diemSoVoiTB
                    }
                } else {
                    diemDT = 0
                }

                let diemTong: Double
                if coThiDua && coDoanhThu {
                    diemTong = 0.65 * diemThiDua + 0.35 * diemDT
                } else if coThiDua {
                    diemTong = diemThiDua
                } else if coDoanhThu {
                    diemTong = diemDT
                } else {
                    diemTong = 0
                }

                let diemChuan = min(100.0, max(0.0, diemTong))
                diemTamTheoMa[th.nhanVien.maNV] = (diemChuan, th)
            }

            let cacDiemSapXep = diemTamTheoMa.values.map(\.diem).sorted()
            let chiSoTop5Yeu = min(4, max(0, cacDiemSapXep.count - 1))
            let nguongTop5Yeu = cacDiemSapXep.isEmpty ? 55.0 : cacDiemSapXep[chiSoTop5Yeu]
            let coDuLieuThucTe = coThiDua || coDoanhThu

            let dNgay = TienIchNgay.lich.component(.day, from: ngayD)
            let mThang = TienIchNgay.lich.component(.month, from: ngayD)
            let nhanNgay = String(format: "%02d/%02d", dNgay, mThang)

            var bangDiemNgay: [String: DiemSucKhoeNgayNV] = [:]
            for nv in dsNV {
                guard let info = diemTamTheoMa[nv.maNV] else { continue }
                let mucDo: MucDoSucKhoeNV
                if !coDuLieuThucTe {
                    mucDo = .chuaCoSo
                } else if info.diem < 55.0 || (info.diem <= nguongTop5Yeu + 0.001 && info.diem < 74.0 && !(info.th.tongMonGiao > 0 && info.th.soMonDat == info.th.tongMonGiao)) {
                    mucDo = .yeu
                } else if info.diem >= 75.0 || (info.th.tongMonGiao > 0 && info.th.soMonDat == info.th.tongMonGiao) {
                    mucDo = .khoe
                } else {
                    mucDo = .trungBinh
                }

                bangDiemNgay[nv.maNV] = DiemSucKhoeNgayNV(
                    khoaNgay: khoa,
                    ngayTrongThang: dNgay,
                    nhanNgay: nhanNgay,
                    diemSucKhoe: info.diem,
                    mucDo: mucDo,
                    soMonDat: info.th.soMonDat,
                    tongMonGiao: info.th.tongMonGiao,
                    phanTramHTTB: info.th.phanTramHTTB,
                    doanhThuQD: info.th.doanhThuQD
                )
            }
            if coDuLieuThucTe || cacBanGhiNgay.isEmpty {
                cacBanGhiNgay.append(BanGhiNgay(
                    khoaNgay: khoa,
                    ngayTrongThang: dNgay,
                    nhanNgay: nhanNgay,
                    bangDiem: bangDiemNgay
                ))
            }
        }

        var dsTongHopHienTai = tongHopNhanVien(den: ngay, sapXep: .soMonHoanThanh, cheDo: cheDo)
        if !dsTongHopHienTai.contains(where: { $0.tongMonGiao > 0 || $0.doanhThuQD > 0 }) {
            let cheDoPhu: LoaiCheDoDoanhThu = (cheDo == .luyKe) ? .realtime : .luyKe
            let dsPhu = tongHopNhanVien(den: ngay, sapXep: .soMonHoanThanh, cheDo: cheDoPhu)
            if dsPhu.contains(where: { $0.tongMonGiao > 0 || $0.doanhThuQD > 0 }) {
                dsTongHopHienTai = dsPhu
            }
        }
        let mapTHHienTai = Dictionary(uniqueKeysWithValues: dsTongHopHienTai.map { ($0.nhanVien.maNV, $0) })

        var hoSoTam: [HoSoSucKhoeNhanVien] = []
        hoSoTam.reserveCapacity(dsNV.count)

        for nv in dsNV {
            let thHienTai = mapTHHienTai[nv.maNV] ?? TongHopNhanVien(
                nhanVien: nv,
                soMonDat: 0,
                tongMonGiao: 0,
                phanTramHTTB: 0,
                doanhThuQD: 0,
                soLuongDon: 0,
                dtQDKhoanVay: 0,
                dtTraThangQD: 0,
                cacMonGiao: [],
                doanhThuCaNhan: nil
            )

            let lichSuDayDu: [DiemSucKhoeNgayNV] = cacBanGhiNgay.compactMap { $0.bangDiem[nv.maNV] }
            let lichSuCoSo = lichSuDayDu.filter { $0.mucDo != .chuaCoSo }

            var soNgayYeuLienTuc = 0
            for item in lichSuCoSo.reversed() {
                if item.mucDo == .yeu {
                    soNgayYeuLienTuc += 1
                } else {
                    break
                }
            }

            var chuoiYeuDaiNhat = 0
            var demTam = 0
            var tongSoNgayYeu = 0
            for item in lichSuCoSo {
                if item.mucDo == .yeu {
                    demTam += 1
                    tongSoNgayYeu += 1
                    chuoiYeuDaiNhat = max(chuoiYeuDaiNhat, demTam)
                } else {
                    demTam = 0
                }
            }

            let diemHienTai = lichSuDayDu.last?.diemSucKhoe ?? 0
            let mucDoHienTai = lichSuDayDu.last?.mucDo ?? .chuaCoSo

            let xuHuong: Double
            if lichSuCoSo.count >= 2 {
                let diemCuoi = lichSuCoSo.last!.diemSucKhoe
                let cacTruoc = lichSuCoSo.dropLast().suffix(3)
                let tbTruoc = cacTruoc.map(\.diemSucKhoe).reduce(0.0, +) / Double(max(1, cacTruoc.count))
                xuHuong = diemCuoi - tbTruoc
            } else {
                xuHuong = 0
            }

            let cacMonChuaDat = thHienTai.cacMonGiao
                .filter { !$0.daDat }
                .sorted { $0.phanTramHT < $1.phanTramHT }
                .prefix(2)
                .map { "\($0.tenNganhHang) (\(Int(round($0.phanTramHT)))%)" }

            hoSoTam.append(HoSoSucKhoeNhanVien(
                nhanVien: nv,
                tongHopHienTai: thHienTai,
                diemSucKhoe: diemHienTai,
                mucDo: mucDoHienTai,
                soNgayYeuLienTuc: soNgayYeuLienTuc,
                chuoiYeuDaiNhat: max(chuoiYeuDaiNhat, soNgayYeuLienTuc),
                tongSoNgayYeu: tongSoNgayYeu,
                tongSoNgayCoSo: lichSuCoSo.count,
                lichSuNgay: Array(lichSuDayDu.suffix(8)),
                cacMonYeuNhat: Array(cacMonChuaDat),
                xuHuongDiem: xuHuong,
                laCanhBaoTop5: false,
                hangCanhBao: nil
            ))
        }

        // Xác định 5 nhân viên yếu nhiều ngày liên tục nhất (ưu tiên số ngày yếu liên tục giảm dần -> tổng ngày yếu -> điểm sức khỏe thấp nhất)
        let sapXepCanhBao = hoSoTam.sorted { a, b in
            let aCoYeu = (a.soNgayYeuLienTuc > 0 || a.mucDo == .yeu) ? 1 : 0
            let bCoYeu = (b.soNgayYeuLienTuc > 0 || b.mucDo == .yeu) ? 1 : 0
            if aCoYeu != bCoYeu { return aCoYeu > bCoYeu }
            if a.soNgayYeuLienTuc != b.soNgayYeuLienTuc { return a.soNgayYeuLienTuc > b.soNgayYeuLienTuc }
            if a.tongSoNgayYeu != b.tongSoNgayYeu { return a.tongSoNgayYeu > b.tongSoNgayYeu }
            if abs(a.diemSucKhoe - b.diemSucKhoe) > 0.05 { return a.diemSucKhoe < b.diemSucKhoe }
            if abs(a.tongHopHienTai.phanTramHTTB - b.tongHopHienTai.phanTramHTTB) > 0.05 {
                return a.tongHopHienTai.phanTramHTTB < b.tongHopHienTai.phanTramHTTB
            }
            return a.tongHopHienTai.doanhThuQD < b.tongHopHienTai.doanhThuQD
        }

        let soLuongCanhBao = min(5, sapXepCanhBao.count)
        let maTop5 = Array(sapXepCanhBao.prefix(soLuongCanhBao).map(\.nhanVien.maNV))

        for i in hoSoTam.indices {
            if let viTri = maTop5.firstIndex(of: hoSoTam[i].nhanVien.maNV) {
                hoSoTam[i].laCanhBaoTop5 = true
                hoSoTam[i].hangCanhBao = viTri + 1
            }
        }

        let top5 = maTop5.compactMap { ma in hoSoTam.first(where: { $0.nhanVien.maNV == ma }) }
        let soKhoe = hoSoTam.filter { $0.mucDo == .khoe }.count
        let soTB = hoSoTam.filter { $0.mucDo == .trungBinh }.count
        let soYeu = hoSoTam.filter { $0.mucDo == .yeu }.count
        let diemTBDoi = hoSoTam.isEmpty ? 0 : (hoSoTam.map(\.diemSucKhoe).reduce(0.0, +) / Double(hoSoTam.count))
        let cacNhanNgay = cacBanGhiNgay.suffix(8).map(\.nhanNgay)
        let soNgayCoSo = cacBanGhiNgay.filter { bg in bg.bangDiem.values.contains(where: { $0.mucDo != .chuaCoSo }) }.count

        let baoCao = BaoCaoSucKhoeDoiNgu(
            ngayBaoCao: ngay,
            cheDo: cheDo,
            soNgayDaTheoDoi: max(soNgayCoSo, cacBanGhiNgay.isEmpty ? 0 : 1),
            cacNhanNgayTheoDoi: Array(cacNhanNgay),
            soNVKhoe: soKhoe,
            soNVTrungBinh: soTB,
            soNVYeu: soYeu,
            diemTrungBinhDoiNgu: diemTBDoi,
            top5CanhBaoYeu: top5,
            danhSachTatCa: hoSoTam
        )
        boNhoDemBaoCaoSucKhoe[khoaDem] = baoCao
        return baoCao
    }
}

// MARK: - Hộp Chọn Hành Động Tùy Chỉnh (Đảm bảo mọi dòng chữ có CÙNG CỠ CHỮ, tự động xuống dòng khi dài, tuyệt đối không bao giờ hiện dấu "...")

struct MucChonDMX {
    enum KieuMuc {
        case macDinh
        case nguyHiem
        case huy
    }

    let tieuDe: String
    let kieu: KieuMuc
    let dangChon: Bool
    let xuLy: (() -> Void)?

    init(tieuDe: String, kieu: KieuMuc = .macDinh, dangChon: Bool = false, xuLy: (() -> Void)? = nil) {
        self.tieuDe = tieuDe
        self.kieu = kieu
        self.dangChon = dangChon
        self.xuLy = xuLy
    }
}

private final class NutHangMenuDMX: UIControl {
    private let nhan = UILabel()
    private let vachChonTrai = UIView()
    private let nenMacDinh: UIColor
    private var xuLyBam: (() -> Void)?

    init(muc: MucChonDMX, coChu: UIFont, canGiua: Bool, khiBam: @escaping () -> Void) {
        self.xuLyBam = khiBam
        self.nenMacDinh = muc.dangChon ? BangMauBCTD.vangNhatNen.withAlphaComponent(0.45) : .clear
        super.init(frame: .zero)
        backgroundColor = nenMacDinh

        vachChonTrai.backgroundColor = BangMauBCTD.vangChuDao
        vachChonTrai.isHidden = !muc.dangChon
        vachChonTrai.isUserInteractionEnabled = false
        vachChonTrai.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vachChonTrai)

        let chuHienThi = muc.dangChon ? "✓  \(muc.tieuDe)" : muc.tieuDe
        nhan.text = chuHienThi
        nhan.font = muc.dangChon ? .systemFont(ofSize: coChu.pointSize, weight: .bold) : coChu
        nhan.numberOfLines = 0
        nhan.lineBreakMode = .byWordWrapping
        nhan.adjustsFontSizeToFitWidth = false
        nhan.textAlignment = canGiua ? .center : .left
        nhan.isUserInteractionEnabled = false

        switch muc.kieu {
        case .nguyHiem:
            nhan.textColor = BangMauBCTD.doYeuChu
        case .huy:
            nhan.textColor = BangMauBCTD.chuChinh
        case .macDinh:
            nhan.textColor = muc.dangChon ? BangMauBCTD.chuChinh : BangMauBCTD.indigoDam
        }

        nhan.translatesAutoresizingMaskIntoConstraints = false
        nhan.setContentCompressionResistancePriority(.required, for: .vertical)
        addSubview(nhan)

        NSLayoutConstraint.activate([
            vachChonTrai.topAnchor.constraint(equalTo: topAnchor),
            vachChonTrai.bottomAnchor.constraint(equalTo: bottomAnchor),
            vachChonTrai.leadingAnchor.constraint(equalTo: leadingAnchor),
            vachChonTrai.widthAnchor.constraint(equalToConstant: 4),

            nhan.topAnchor.constraint(equalTo: topAnchor, constant: 13),
            nhan.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -13),
            nhan.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            nhan.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        ])

        addTarget(self, action: #selector(bamChon), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("Khong ho tro coder")
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? BangMauBCTD.indigoNhatNen : nenMacDinh
        }
    }

    @objc private func bamChon() {
        xuLyBam?()
    }
}

final class HopChonDMXController: UIViewController {
    private let tieuDeMenu: String?
    private let thongDiepMenu: String?
    private let cacMuc: [MucChonDMX]
    private let canGiuaText: Bool

    private let nenMo = UIControl()
    private let khungChinh = UIView()
    private let khungDanhSach = UIView()
    private let khungNutHuy = UIView()

    init(tieuDe: String?, thongDiep: String? = nil, cacMuc: [MucChonDMX], canGiuaText: Bool = false) {
        self.tieuDeMenu = tieuDe
        self.thongDiepMenu = thongDiep
        self.cacMuc = cacMuc
        self.canGiuaText = canGiuaText
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("Khong ho tro coder")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        taoGiaoDien()
    }

    private func taoGiaoDien() {
        view.backgroundColor = .clear

        nenMo.backgroundColor = UIColor.black.withAlphaComponent(0.42)
        nenMo.addTarget(self, action: #selector(bamDong), for: .touchUpInside)
        nenMo.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nenMo)

        khungChinh.backgroundColor = .clear
        khungChinh.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(khungChinh)

        khungDanhSach.backgroundColor = .secondarySystemGroupedBackground
        khungDanhSach.layer.cornerRadius = 16
        khungDanhSach.clipsToBounds = true
        khungDanhSach.translatesAutoresizingMaskIntoConstraints = false

        let cuon = UIScrollView()
        cuon.showsVerticalScrollIndicator = true
        cuon.alwaysBounceVertical = false
        cuon.translatesAutoresizingMaskIntoConstraints = false
        khungDanhSach.addSubview(cuon)

        let ngan = UIStackView()
        ngan.axis = .vertical
        ngan.spacing = 0
        ngan.translatesAutoresizingMaskIntoConstraints = false
        cuon.addSubview(ngan)

        let coTieuDe = !(tieuDeMenu ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let coThongDiep = !(thongDiepMenu ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if coTieuDe || coThongDiep {
            let khungHeader = UIView()
            khungHeader.backgroundColor = BangMauBCTD.nenMenuToi
            let vachVang = UIView()
            vachVang.backgroundColor = BangMauBCTD.vangChuDao
            vachVang.translatesAutoresizingMaskIntoConstraints = false
            khungHeader.addSubview(vachVang)

            let nganHeader = UIStackView()
            nganHeader.axis = .vertical
            nganHeader.spacing = 4
            nganHeader.translatesAutoresizingMaskIntoConstraints = false
            khungHeader.addSubview(nganHeader)

            if coTieuDe, let td = tieuDeMenu {
                let lbTieuDe = UILabel()
                lbTieuDe.text = td.uppercased()
                lbTieuDe.font = .systemFont(ofSize: 14.5, weight: .heavy)
                lbTieuDe.textColor = BangMauBCTD.vangChuDao
                lbTieuDe.textAlignment = .center
                lbTieuDe.numberOfLines = 0
                lbTieuDe.lineBreakMode = .byWordWrapping
                lbTieuDe.adjustsFontSizeToFitWidth = false
                nganHeader.addArrangedSubview(lbTieuDe)
            }

            if coThongDiep, let msg = thongDiepMenu {
                let lbMsg = UILabel()
                lbMsg.text = msg
                lbMsg.font = .systemFont(ofSize: 13, weight: .medium)
                lbMsg.textColor = BangMauBCTD.chuTrenNenToi
                lbMsg.textAlignment = .center
                lbMsg.numberOfLines = 0
                lbMsg.lineBreakMode = .byWordWrapping
                lbMsg.adjustsFontSizeToFitWidth = false
                nganHeader.addArrangedSubview(lbMsg)
            }

            NSLayoutConstraint.activate([
                nganHeader.topAnchor.constraint(equalTo: khungHeader.topAnchor, constant: 14),
                nganHeader.bottomAnchor.constraint(equalTo: khungHeader.bottomAnchor, constant: -14),
                nganHeader.leadingAnchor.constraint(equalTo: khungHeader.leadingAnchor, constant: 16),
                nganHeader.trailingAnchor.constraint(equalTo: khungHeader.trailingAnchor, constant: -16),

                vachVang.leadingAnchor.constraint(equalTo: khungHeader.leadingAnchor),
                vachVang.trailingAnchor.constraint(equalTo: khungHeader.trailingAnchor),
                vachVang.bottomAnchor.constraint(equalTo: khungHeader.bottomAnchor),
                vachVang.heightAnchor.constraint(equalToConstant: 2.5)
            ])
            ngan.addArrangedSubview(khungHeader)
        }

        // Tất cả các dòng lựa chọn đều dùng chung 1 cỡ chữ 15pt đồng nhất, tự xuống dòng khi dài
        let coChuDongNhat = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let cacMucChinh = cacMuc.filter { $0.kieu != .huy }
        let mucHuy = cacMuc.first(where: { $0.kieu == .huy }) ?? MucChonDMX(tieuDe: "Đóng", kieu: .huy)

        for (idx, muc) in cacMucChinh.enumerated() {
            if idx > 0 || coTieuDe || coThongDiep {
                let vach = UIView()
                vach.backgroundColor = .separator
                vach.translatesAutoresizingMaskIntoConstraints = false
                vach.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                ngan.addArrangedSubview(vach)
            }

            let nut = NutHangMenuDMX(muc: muc, coChu: coChuDongNhat, canGiua: canGiuaText) { [weak self] in
                guard let self else { return }
                self.dismiss(animated: true) {
                    muc.xuLy?()
                }
            }
            ngan.addArrangedSubview(nut)
        }

        khungNutHuy.backgroundColor = .secondarySystemGroupedBackground
        khungNutHuy.layer.cornerRadius = 16
        khungNutHuy.clipsToBounds = true
        khungNutHuy.translatesAutoresizingMaskIntoConstraints = false

        let nutHuy = NutHangMenuDMX(
            muc: mucHuy,
            coChu: .systemFont(ofSize: 16, weight: .bold),
            canGiua: true
        ) { [weak self] in
            guard let self else { return }
            self.dismiss(animated: true) {
                mucHuy.xuLy?()
            }
        }
        nutHuy.translatesAutoresizingMaskIntoConstraints = false
        khungNutHuy.addSubview(nutHuy)

        khungChinh.addSubview(khungDanhSach)
        khungChinh.addSubview(khungNutHuy)

        let chieuCaoCuon = cuon.heightAnchor.constraint(equalTo: ngan.heightAnchor)
        chieuCaoCuon.priority = .defaultHigh

        NSLayoutConstraint.activate([
            nenMo.topAnchor.constraint(equalTo: view.topAnchor),
            nenMo.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            nenMo.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nenMo.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            khungChinh.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            khungChinh.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            khungChinh.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            khungChinh.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),

            khungDanhSach.topAnchor.constraint(equalTo: khungChinh.topAnchor),
            khungDanhSach.leadingAnchor.constraint(equalTo: khungChinh.leadingAnchor),
            khungDanhSach.trailingAnchor.constraint(equalTo: khungChinh.trailingAnchor),

            cuon.topAnchor.constraint(equalTo: khungDanhSach.topAnchor),
            cuon.leadingAnchor.constraint(equalTo: khungDanhSach.leadingAnchor),
            cuon.trailingAnchor.constraint(equalTo: khungDanhSach.trailingAnchor),
            cuon.bottomAnchor.constraint(equalTo: khungDanhSach.bottomAnchor),
            chieuCaoCuon,

            ngan.topAnchor.constraint(equalTo: cuon.contentLayoutGuide.topAnchor),
            ngan.leadingAnchor.constraint(equalTo: cuon.contentLayoutGuide.leadingAnchor),
            ngan.trailingAnchor.constraint(equalTo: cuon.contentLayoutGuide.trailingAnchor),
            ngan.bottomAnchor.constraint(equalTo: cuon.contentLayoutGuide.bottomAnchor),
            ngan.widthAnchor.constraint(equalTo: cuon.frameLayoutGuide.widthAnchor),

            khungNutHuy.topAnchor.constraint(equalTo: khungDanhSach.bottomAnchor, constant: 8),
            khungNutHuy.leadingAnchor.constraint(equalTo: khungChinh.leadingAnchor),
            khungNutHuy.trailingAnchor.constraint(equalTo: khungChinh.trailingAnchor),
            khungNutHuy.bottomAnchor.constraint(equalTo: khungChinh.bottomAnchor),

            nutHuy.topAnchor.constraint(equalTo: khungNutHuy.topAnchor),
            nutHuy.leadingAnchor.constraint(equalTo: khungNutHuy.leadingAnchor),
            nutHuy.trailingAnchor.constraint(equalTo: khungNutHuy.trailingAnchor),
            nutHuy.bottomAnchor.constraint(equalTo: khungNutHuy.bottomAnchor)
        ])
    }

    @objc private func bamDong() {
        let mucHuy = cacMuc.first(where: { $0.kieu == .huy })
        dismiss(animated: true) {
            mucHuy?.xuLy?()
        }
    }
}

extension UIViewController {
    func hienMenuChon(
        tieuDe: String? = nil,
        thongDiep: String? = nil,
        cacMuc: [MucChonDMX],
        canGiuaText: Bool = false
    ) {
        let hop = HopChonDMXController(
            tieuDe: tieuDe,
            thongDiep: thongDiep,
            cacMuc: cacMuc,
            canGiuaText: canGiuaText
        )
        present(hop, animated: true)
    }
}

extension UIView {
    /// Đảm bảo mọi UILabel và UIButton bên trong view luôn hiển thị trọn vẹn văn bản, tự xuống dòng, không bao giờ hiện dấu "..."
    func damBaoHienThiDayDuText() {
        if let lb = self as? UILabel {
            lb.numberOfLines = 0
            lb.lineBreakMode = .byWordWrapping
            lb.adjustsFontSizeToFitWidth = false
        } else if let bt = self as? UIButton {
            bt.titleLabel?.numberOfLines = 0
            bt.titleLabel?.lineBreakMode = .byWordWrapping
            bt.titleLabel?.adjustsFontSizeToFitWidth = false
        }
        for sub in subviews {
            sub.damBaoHienThiDayDuText()
        }
    }
}

extension UIAlertController {
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        view.damBaoHienThiDayDuText()
    }
}

enum TienIchNgay {
    static let lich: Calendar = {
        var lich = Calendar(identifier: .gregorian)
        lich.locale = Locale(identifier: "vi_VN")
        lich.timeZone = .current
        return lich
    }()

    static let khoa: DateFormatter = {
        let dinhDang = DateFormatter()
        dinhDang.calendar = lich
        dinhDang.locale = Locale(identifier: "vi_VN")
        dinhDang.dateFormat = "yyyy-MM-dd"
        return dinhDang
    }()

    static let hienThiNgay: DateFormatter = {
        let dinhDang = DateFormatter()
        dinhDang.calendar = lich
        dinhDang.locale = Locale(identifier: "vi_VN")
        dinhDang.dateFormat = "dd/MM/yyyy"
        return dinhDang
    }()

    static let hienThiGioPhut: DateFormatter = {
        let dinhDang = DateFormatter()
        dinhDang.calendar = lich
        dinhDang.locale = Locale(identifier: "vi_VN")
        dinhDang.dateFormat = "HH:mm dd/MM/yyyy"
        return dinhDang
    }()

    static func heSoDuBaoThang(cho ngay: Date = Date()) -> Double {
        let soNgayTrongThang = Double(lich.range(of: .day, in: .month, for: ngay)?.count ?? 30)
        let ngayHienTai = Double(max(1, lich.component(.day, from: ngay)))
        return max(1.0, soNgayTrongThang / ngayHienTai)
    }
}

extension Double {
    private static let boDinhDangVN: NumberFormatter = {
        let df = NumberFormatter()
        df.locale = Locale(identifier: "vi_VN")
        df.numberStyle = .decimal
        df.minimumFractionDigits = 2
        df.maximumFractionDigits = 2
        return df
    }()

    private static let boDinhDangNguyenVN: NumberFormatter = {
        let df = NumberFormatter()
        df.locale = Locale(identifier: "vi_VN")
        df.numberStyle = .decimal
        df.minimumFractionDigits = 0
        df.maximumFractionDigits = 0
        return df
    }()

    private static let boDinhDangSoLieuNguyenUS: NumberFormatter = {
        let df = NumberFormatter()
        df.locale = Locale(identifier: "en_US")
        df.numberStyle = .decimal
        df.minimumFractionDigits = 0
        df.maximumFractionDigits = 0
        return df
    }()

    private static let boDinhDangSoLieuThapPhanUS: NumberFormatter = {
        let df = NumberFormatter()
        df.locale = Locale(identifier: "en_US")
        df.numberStyle = .decimal
        df.minimumFractionDigits = 2
        df.maximumFractionDigits = 2
        return df
    }()

    var chuoiSoVN: String {
        Double.boDinhDangVN.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self)
    }

    var chuoiSoNguyenVN: String {
        Double.boDinhDangNguyenVN.string(from: NSNumber(value: self.rounded())) ?? String(format: "%.0f", self)
    }

    var chuoiSoMotLeVN: String {
        if abs(self) < 0.005 { return "0" }
        return String(format: "%.1f", self).replacingOccurrences(of: ".", with: ",")
    }

    var chuoiSoGonVN: String {
        if abs(self.rounded() - self) < 0.005 {
            return chuoiSoNguyenVN
        }
        return chuoiSoVN
    }

    var chuoiPhanTramVN: String {
        "\(self.chuoiSoVN)%"
    }

    var chuoiSoLieu: String {
        if abs(self.rounded() - self) < 0.005 {
            return Double.boDinhDangSoLieuNguyenUS.string(from: NSNumber(value: self.rounded())) ?? String(format: "%.0f", self)
        }
        return Double.boDinhDangSoLieuThapPhanUS.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self)
    }

    var chuoiChenhLech: String {
        if abs(self) < 0.005 { return "0" }
        let dau = self > 0 ? "+" : ""
        return "\(dau)\(self.chuoiSoLieu)"
    }

    var chuoiPhanTram: String {
        if abs(self.rounded() - self) < 0.05 {
            return String(format: "%.0f%%", self)
        }
        return String(format: "%.1f%%", self)
    }
}
