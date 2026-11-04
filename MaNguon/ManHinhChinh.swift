import UIKit
import PhotosUI

// MARK: - Menu Điều Hướng Trượt Bên Trái (Giao diện Sáng Tươi Chuẩn ĐMX & BaoCaoThiDua)
// Dưới "Tổng quan" có nút "Báo cáo"; trong "Đổ số - Xem số" có 3 mục: 1. Xem số | 2. Nhập số | 3. Xuất ảnh; có nút "Cài đặt"

final class MenuDieuHuongBenTraiView: UIView {
    var khiChonMucChinh: ((MucMenuChinh) -> Void)?
    var khiChonMucConDoSo: ((MucConDoSo) -> Void)?
    var khiDongMenu: (() -> Void)?

    private let nhanTenTaiKhoan = UILabel()
    private let khungHuyHieu = UIView()
    private let nhanHuyHieu = UILabel()
    private let cuonMenu = UIScrollView()
    private let nganDanhSach = UIStackView()

    private var dangMoMenuConDoSo: Bool = true
    private var mucChinhDangChon: MucMenuChinh = .doSoXemSo
    private var mucConDangChon: MucConDoSo = .xemSo

    override init(frame: CGRect) {
        super.init(frame: frame)
        taoGiaoDien()
    }

    required init?(coder: NSCoder) {
        fatalError("Khong ho tro coder")
    }

    private func taoGiaoDien() {
        backgroundColor = BangMauBCTD.nenSidebarSang
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 16
        layer.shadowOffset = CGSize(width: 4, height: 0)

        let khungDau = UIView()
        khungDau.backgroundColor = BangMauBCTD.xanhChuDao
        khungDau.translatesAutoresizingMaskIntoConstraints = false
        addSubview(khungDau)

        nhanTenTaiKhoan.font = .systemFont(ofSize: 18, weight: .heavy)
        nhanTenTaiKhoan.textColor = .white
        nhanTenTaiKhoan.numberOfLines = 0
        nhanTenTaiKhoan.lineBreakMode = .byWordWrapping
        nhanTenTaiKhoan.adjustsFontSizeToFitWidth = false
        nhanTenTaiKhoan.translatesAutoresizingMaskIntoConstraints = false
        khungDau.addSubview(nhanTenTaiKhoan)

        khungHuyHieu.backgroundColor = BangMauBCTD.vangSang
        khungHuyHieu.layer.cornerRadius = 5
        khungHuyHieu.translatesAutoresizingMaskIntoConstraints = false
        khungDau.addSubview(khungHuyHieu)

        nhanHuyHieu.text = "👑 CAO CẤP"
        nhanHuyHieu.font = .systemFont(ofSize: 11.5, weight: .heavy)
        nhanHuyHieu.textColor = BangMauBCTD.chuChinh
        nhanHuyHieu.numberOfLines = 0
        nhanHuyHieu.lineBreakMode = .byWordWrapping
        nhanHuyHieu.adjustsFontSizeToFitWidth = false
        nhanHuyHieu.translatesAutoresizingMaskIntoConstraints = false
        khungHuyHieu.addSubview(nhanHuyHieu)

        let vachVangDau = UIView()
        vachVangDau.backgroundColor = BangMauBCTD.vangSang
        vachVangDau.translatesAutoresizingMaskIntoConstraints = false
        khungDau.addSubview(vachVangDau)

        cuonMenu.showsVerticalScrollIndicator = false
        cuonMenu.alwaysBounceVertical = true
        cuonMenu.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cuonMenu)

        nganDanhSach.axis = .vertical
        nganDanhSach.spacing = 2
        nganDanhSach.translatesAutoresizingMaskIntoConstraints = false
        cuonMenu.addSubview(nganDanhSach)

        NSLayoutConstraint.activate([
            khungDau.topAnchor.constraint(equalTo: topAnchor),
            khungDau.leadingAnchor.constraint(equalTo: leadingAnchor),
            khungDau.trailingAnchor.constraint(equalTo: trailingAnchor),

            nhanTenTaiKhoan.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12),
            nhanTenTaiKhoan.leadingAnchor.constraint(equalTo: khungDau.leadingAnchor, constant: 20),
            nhanTenTaiKhoan.trailingAnchor.constraint(equalTo: khungDau.trailingAnchor, constant: -16),

            khungHuyHieu.topAnchor.constraint(equalTo: nhanTenTaiKhoan.bottomAnchor, constant: 8),
            khungHuyHieu.leadingAnchor.constraint(equalTo: khungDau.leadingAnchor, constant: 20),
            khungHuyHieu.trailingAnchor.constraint(lessThanOrEqualTo: khungDau.trailingAnchor, constant: -16),
            khungHuyHieu.bottomAnchor.constraint(equalTo: khungDau.bottomAnchor, constant: -14),

            nhanHuyHieu.topAnchor.constraint(equalTo: khungHuyHieu.topAnchor, constant: 4),
            nhanHuyHieu.bottomAnchor.constraint(equalTo: khungHuyHieu.bottomAnchor, constant: -4),
            nhanHuyHieu.leadingAnchor.constraint(equalTo: khungHuyHieu.leadingAnchor, constant: 10),
            nhanHuyHieu.trailingAnchor.constraint(equalTo: khungHuyHieu.trailingAnchor, constant: -10),

            vachVangDau.leadingAnchor.constraint(equalTo: khungDau.leadingAnchor),
            vachVangDau.trailingAnchor.constraint(equalTo: khungDau.trailingAnchor),
            vachVangDau.bottomAnchor.constraint(equalTo: khungDau.bottomAnchor),
            vachVangDau.heightAnchor.constraint(equalToConstant: 4),

            cuonMenu.topAnchor.constraint(equalTo: khungDau.bottomAnchor, constant: 6),
            cuonMenu.leadingAnchor.constraint(equalTo: leadingAnchor),
            cuonMenu.trailingAnchor.constraint(equalTo: trailingAnchor),
            cuonMenu.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8),

            nganDanhSach.topAnchor.constraint(equalTo: cuonMenu.contentLayoutGuide.topAnchor),
            nganDanhSach.leadingAnchor.constraint(equalTo: cuonMenu.contentLayoutGuide.leadingAnchor),
            nganDanhSach.trailingAnchor.constraint(equalTo: cuonMenu.contentLayoutGuide.trailingAnchor),
            nganDanhSach.bottomAnchor.constraint(equalTo: cuonMenu.contentLayoutGuide.bottomAnchor, constant: -12),
            nganDanhSach.widthAnchor.constraint(equalTo: cuonMenu.frameLayoutGuide.widthAnchor)
        ])

        capNhatThongTinTaiKhoan()
        dungLaiDanhSachMenu()
    }

    func capNhatThongTinTaiKhoan() {
        let tenTK = DichVuDongBo.dungChung.tenDangNhap.trimmingCharacters(in: .whitespacesAndNewlines)
        if tenTK.isEmpty || tenTK.lowercased() == "duongnt" {
            nhanTenTaiKhoan.text = tenTK.isEmpty ? "VĂN ĐẠT" : tenTK.uppercased()
        } else {
            nhanTenTaiKhoan.text = tenTK.uppercased()
        }
        nhanHuyHieu.text = "👑 CAO CẤP"
    }

    func capNhatTrangThai(mucChinh: MucMenuChinh, mucCon: MucConDoSo) {
        self.mucChinhDangChon = mucChinh
        self.mucConDangChon = mucCon
        capNhatThongTinTaiKhoan()
        dungLaiDanhSachMenu()
    }

    private func dungLaiDanhSachMenu() {
        nganDanhSach.arrangedSubviews.forEach {
            nganDanhSach.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for muc in MucMenuChinh.allCases {
            let laMucDangChon = (muc == mucChinhDangChon)
            let dongChinh = taoDongMenuChinh(muc: muc, dangChon: laMucDangChon)
            nganDanhSach.addArrangedSubview(dongChinh)

            if muc == .doSoXemSo && dangMoMenuConDoSo {
                let khungMenuCon = UIStackView()
                khungMenuCon.axis = .vertical
                khungMenuCon.spacing = 4
                khungMenuCon.backgroundColor = BangMauBCTD.nenSidebarCon
                khungMenuCon.isLayoutMarginsRelativeArrangement = true
                khungMenuCon.layoutMargins = UIEdgeInsets(top: 4, left: 10, bottom: 6, right: 10)

                for mucCon in MucConDoSo.allCases {
                    let dangChonCon = (mucChinhDangChon == .doSoXemSo && mucConDangChon == mucCon)
                    let dongCon = taoDongMenuCon(mucCon: mucCon, dangChon: dangChonCon)
                    khungMenuCon.addArrangedSubview(dongCon)
                }
                nganDanhSach.addArrangedSubview(khungMenuCon)
            }
        }
    }

    private func taoDongMenuChinh(muc: MucMenuChinh, dangChon: Bool) -> UIView {
        let nut = UIControl()
        nut.tag = muc.rawValue
        nut.backgroundColor = dangChon ? BangMauBCTD.nenSidebarChon : .clear
        nut.translatesAutoresizingMaskIntoConstraints = false
        nut.addTarget(self, action: #selector(bamMucChinh(_:)), for: .touchUpInside)

        let vachTrai = UIView()
        vachTrai.backgroundColor = BangMauBCTD.xanhChuDao
        vachTrai.isHidden = !dangChon
        vachTrai.isUserInteractionEnabled = false
        vachTrai.translatesAutoresizingMaskIntoConstraints = false
        nut.addSubview(vachTrai)

        let cauHinhIcon = UIImage.SymbolConfiguration(pointSize: 16, weight: dangChon ? .bold : .semibold)
        let oIcon = UIImageView(image: UIImage(systemName: muc.bieuTuongSF, withConfiguration: cauHinhIcon))
        oIcon.tintColor = dangChon ? BangMauBCTD.xanhChuDaoDam : BangMauBCTD.chuPhu
        oIcon.contentMode = .scaleAspectFit
        oIcon.isUserInteractionEnabled = false
        oIcon.translatesAutoresizingMaskIntoConstraints = false
        nut.addSubview(oIcon)

        let nhanTieuDe = UILabel()
        nhanTieuDe.text = muc.tieuDe
        nhanTieuDe.font = .systemFont(ofSize: 15, weight: dangChon ? .bold : .semibold)
        nhanTieuDe.textColor = dangChon ? BangMauBCTD.xanhChuDaoDam : BangMauBCTD.chuChinh
        nhanTieuDe.numberOfLines = 0
        nhanTieuDe.lineBreakMode = .byWordWrapping
        nhanTieuDe.adjustsFontSizeToFitWidth = false
        nhanTieuDe.isUserInteractionEnabled = false
        nhanTieuDe.translatesAutoresizingMaskIntoConstraints = false
        nut.addSubview(nhanTieuDe)

        let nganPhai = UIStackView()
        nganPhai.axis = .horizontal
        nganPhai.spacing = 6
        nganPhai.alignment = .center
        nganPhai.isUserInteractionEnabled = false
        nganPhai.translatesAutoresizingMaskIntoConstraints = false
        nut.addSubview(nganPhai)

        if muc == .baoCao {
            let nhanAI = UILabel()
            nhanAI.text = "✨ AI"
            nhanAI.font = .systemFont(ofSize: 10.5, weight: .heavy)
            nhanAI.textColor = BangMauBCTD.chuChinh
            nhanAI.backgroundColor = BangMauBCTD.vangSang
            nhanAI.layer.cornerRadius = 5
            nhanAI.clipsToBounds = true
            nhanAI.numberOfLines = 0
            nhanAI.lineBreakMode = .byWordWrapping
            nhanAI.adjustsFontSizeToFitWidth = false
            nganPhai.addArrangedSubview(nhanAI)
        }

        if muc.coMenuCon {
            let tenMuiTen = dangMoMenuConDoSo ? "chevron.down" : "chevron.right"
            let cfgMuiTen = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
            let iconMuiTen = UIImageView(image: UIImage(systemName: tenMuiTen, withConfiguration: cfgMuiTen))
            iconMuiTen.tintColor = dangChon ? BangMauBCTD.xanhChuDaoDam : BangMauBCTD.chuPhu
            nganPhai.addArrangedSubview(iconMuiTen)
        }

        nganPhai.setContentHuggingPriority(.required, for: .horizontal)
        nganPhai.setContentCompressionResistancePriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            nut.heightAnchor.constraint(greaterThanOrEqualToConstant: 46),

            vachTrai.topAnchor.constraint(equalTo: nut.topAnchor),
            vachTrai.bottomAnchor.constraint(equalTo: nut.bottomAnchor),
            vachTrai.leadingAnchor.constraint(equalTo: nut.leadingAnchor),
            vachTrai.widthAnchor.constraint(equalToConstant: 4.5),

            oIcon.leadingAnchor.constraint(equalTo: nut.leadingAnchor, constant: 18),
            oIcon.centerYAnchor.constraint(equalTo: nut.centerYAnchor),
            oIcon.widthAnchor.constraint(equalToConstant: 22),
            oIcon.heightAnchor.constraint(equalToConstant: 22),

            nhanTieuDe.topAnchor.constraint(equalTo: nut.topAnchor, constant: 12),
            nhanTieuDe.bottomAnchor.constraint(equalTo: nut.bottomAnchor, constant: -12),
            nhanTieuDe.leadingAnchor.constraint(equalTo: oIcon.trailingAnchor, constant: 12),
            nhanTieuDe.trailingAnchor.constraint(lessThanOrEqualTo: nganPhai.leadingAnchor, constant: -8),

            nganPhai.trailingAnchor.constraint(equalTo: nut.trailingAnchor, constant: -14),
            nganPhai.centerYAnchor.constraint(equalTo: nut.centerYAnchor)
        ])

        return nut
    }

    private func taoDongMenuCon(mucCon: MucConDoSo, dangChon: Bool) -> UIView {
        let nut = UIControl()
        nut.tag = mucCon.rawValue
        nut.backgroundColor = dangChon ? BangMauBCTD.vangSang : BangMauBCTD.nenThe
        nut.layer.cornerRadius = 9
        nut.layer.borderWidth = 1
        nut.layer.borderColor = dangChon ? BangMauBCTD.vangChuDao.cgColor : BangMauBCTD.vienThe.cgColor
        nut.translatesAutoresizingMaskIntoConstraints = false
        nut.addTarget(self, action: #selector(bamMucCon(_:)), for: .touchUpInside)

        let cfgIcon = UIImage.SymbolConfiguration(pointSize: 13.5, weight: dangChon ? .bold : .semibold)
        let oIcon = UIImageView(image: UIImage(systemName: mucCon.bieuTuongSF, withConfiguration: cfgIcon))
        oIcon.tintColor = dangChon ? BangMauBCTD.chuChinh : BangMauBCTD.xanhChuDao
        oIcon.contentMode = .scaleAspectFit
        oIcon.isUserInteractionEnabled = false
        oIcon.translatesAutoresizingMaskIntoConstraints = false
        nut.addSubview(oIcon)

        let nhan = UILabel()
        nhan.text = mucCon.tieuDe
        nhan.font = .systemFont(ofSize: 14, weight: dangChon ? .bold : .semibold)
        nhan.textColor = BangMauBCTD.chuChinh
        nhan.numberOfLines = 0
        nhan.lineBreakMode = .byWordWrapping
        nhan.adjustsFontSizeToFitWidth = false
        nhan.isUserInteractionEnabled = false
        nhan.translatesAutoresizingMaskIntoConstraints = false
        nut.addSubview(nhan)

        NSLayoutConstraint.activate([
            nut.heightAnchor.constraint(greaterThanOrEqualToConstant: 38),

            oIcon.leadingAnchor.constraint(equalTo: nut.leadingAnchor, constant: 14),
            oIcon.centerYAnchor.constraint(equalTo: nut.centerYAnchor),
            oIcon.widthAnchor.constraint(equalToConstant: 18),
            oIcon.heightAnchor.constraint(equalToConstant: 18),

            nhan.topAnchor.constraint(equalTo: nut.topAnchor, constant: 9),
            nhan.bottomAnchor.constraint(equalTo: nut.bottomAnchor, constant: -9),
            nhan.leadingAnchor.constraint(equalTo: oIcon.trailingAnchor, constant: 10),
            nhan.trailingAnchor.constraint(equalTo: nut.trailingAnchor, constant: -10)
        ])

        return nut
    }

    @objc private func bamMucChinh(_ sender: UIControl) {
        guard let muc = MucMenuChinh(rawValue: sender.tag) else { return }
        if muc == .doSoXemSo {
            dangMoMenuConDoSo.toggle()
            dungLaiDanhSachMenu()
            return
        }
        mucChinhDangChon = muc
        dungLaiDanhSachMenu()
        khiChonMucChinh?(muc)
    }

    @objc private func bamMucCon(_ sender: UIControl) {
        guard let mucCon = MucConDoSo(rawValue: sender.tag) else { return }
        mucChinhDangChon = .doSoXemSo
        mucConDangChon = mucCon
        dungLaiDanhSachMenu()
        khiChonMucConDoSo?(mucCon)
    }
}

// MARK: - Màn Hình Chính Điều Phối Toàn Bộ Ứng Dụng

final class ManHinhChinh: UIViewController, PHPickerViewControllerDelegate, UITextViewDelegate {
    private enum CheDoQuetAnh {
        case doanhThu(LoaiCheDoDoanhThu)
        case thiDua(LoaiCheDoDoanhThu)
        case thiDuaNhanVien(LoaiCheDoDoanhThu)
        case doanhThuNhanVien(LoaiCheDoDoanhThu)
        case tatCaAnhTheoTab(LoaiCheDoDoanhThu)
    }

    private var ngayHienTai = TienIchNgay.lich.startOfDay(for: Date())
    private var mucMenuChinh: MucMenuChinh = .doSoXemSo
    private var mucConDoSo: MucConDoSo = .xemSo
    private var tabXemSo: TabXemSo = .luyKe
    private var cheDoDoanhThu: LoaiCheDoDoanhThu = .luyKe
    private var cheDoQuet: CheDoQuetAnh = .thiDua(.luyKe)
    private var thayTheBangThiDuaKhiQuet: Bool = false

    // Bộ nhớ đệm trạng thái bảng để bấm chuyển qua lại giữa các mục mượt tức thì
    private var dsThiDuaDaNapUI: [DongThiDua]?
    private var cheDoThiDuaDaNapUI: LoaiCheDoDoanhThu?
    private var kieuHienThiDaNapUI: KieuHienThiBaoCao?

    // Thanh điều hướng trên cùng
    private let nutMoMenu = UIButton(type: .system)
    private let nutNgay = UIButton(type: .system)
    private let nutNhapTatCa = UIButton(type: .system)
    private let nutXuatNav = UIButton(type: .system)
    private let nutCaiDatNav = UIButton(type: .system)

    // Khung nội dung phần "Đổ số - Xem số" (3 mục con: 1. Xem số | 2. Nhập số | 3. Xuất ảnh)
    private let khungDoSoXemSo = UIView()
    private let khungThanhMucConDoSo = UIView()
    private let nganNutMucConDoSo = UIStackView()
    private var cacNutMucConDoSo: [UIButton] = []

    // Mục con 1: XEM SỐ (Chứa 4 tab Lũy kế | Realtime | Biểu đồ | Nhân viên + 8 thẻ chỉ số + bảng/biểu đồ)
    private let khungXemSo = UIView()
    private let khungThanhTabXemSo = UIView()
    private let nganNutTabXemSo = UIStackView()
    private var cacNutTabXemSo: [UIButton] = []

    private let khungCumDoanhThu = UIView()
    private let thanhTieuDeDoanhThu = UIControl()
    private let nhanTieuDeCumDoanhThu = UILabel()
    private let nhanPhuCumDoanhThu = UILabel()
    private let vachNganHaiCum = UIView()
    private let khungCumDuoi = UIView()
    private var rangBuocTopKhungDuoiTheoVach: NSLayoutConstraint?
    private var rangBuocTopKhungDuoiTheoDinh: NSLayoutConstraint?
    private var rangBuocTopNutQuetTheoNV: NSLayoutConstraint?
    private var rangBuocTopNutQuetTheoDinh: NSLayoutConstraint?
    private var rangBuocTopBangThiDua: NSLayoutConstraint?
    private var rangBuocTopBangNhanVien: NSLayoutConstraint?
    private var rangBuocBangRongHaiNutNV: NSLayoutConstraint?

    // Mục con 2: NHẬP SỐ (Nhập tất cả Lũy kế & Nhập tất cả Realtime + Nhập từng phần)
    private let khungNhapSo = UIView()
    private let nhanTrangThaiNhapSo = UILabel()

    // Mục con 3: XUẤT ẢNH (Chọn loại ảnh -> Hiện ô Text báo cáo -> Nút Xuất ảnh thật & Copy gửi LINE + Xuất Excel/PPTX)
    private let khungXuatAnh = UIView()
    private var loaiXuatAnhDangChon: LoaiBaoCaoXuatAnh = .doanhThuThiDuaLuyKe
    private var giongXuatAnhDangChon: GiongVanBanTin = .binhThuong
    private var cacNutLoaiXuatAnh: [UIButton] = []
    private var cacNutGiongXuatAnh: [UIButton] = []
    private let oVanBanXuatAnh = UITextView()
    private let nhanTrangThaiXuatAnh = UILabel()
    private let nutAIGeminiXuatAnh = UIButton(type: .system)

    // 1. Cụm 8 thẻ Chỉ số chính
    private let cumChiSoChinh = CumChiSoChinhView(coLon: false, anHangNutCheDo: true)

    // 2. Thanh chọn nhanh chế độ Lũy kế / Realtime khi đang ở tab "Nhân viên" trong Xem số
    private let hangChonCheDoNV = UIStackView()
    private let nutNVLuyKe = UIButton(type: .custom)
    private let nutNVRealtime = UIButton(type: .custom)

    // 3. Cụm nút Quét / Thêm ảnh mới & Xoá
    private var hangNutQuet: UIStackView!
    private let nutThemAnhMoi = UIButton(type: .system)
    private let nutNhapDoanhThuNV = UIButton(type: .system)
    private let nutXoaQuetLai = UIButton(type: .system)
    private let nutThemThuCong = UIButton(type: .system)

    // 4. Các bảng dữ liệu trong phần "1. Xem số"
    private let bangThiDua = BangThiDuaView()
    private let bangNhanVien = BangNhanVienView()
    private let bangRealtimeThang = BangTongHopRealtimeThangView()

    // 5. Khung nội dung cho các mục khác trong Menu (Tổng quan, Báo cáo AI, Cài đặt, Quản trị, Mở rộng)
    private let khungTongQuan = UIView()
    private let nhanTomTatTongQuan = UILabel()
    private let khungBaoCao = UIView()
    private lazy var manHinhBanTinNhung = ManHinhBanTin(ngay: ngayHienTai) { [weak self] khung, soLieu in
        self?.taoAnhBangChoBanTin(khung: khung, soLieu: soLieu) ?? []
    }
    private let khungTaiKhoanHopThu = UIView()
    private lazy var manHinhCaiDatNhung = ManHinhCaiDat(ngay: ngayHienTai)
    private let khungQuanTri = UIView()
    private lazy var manHinhQuanTriNhung = ManHinhQuanLyTaiKhoan()
    private let khungMucMoRong = UIView()
    private let bieuTuongMucMoRong = UIImageView()
    private let nhanTieuDeMucMoRong = UILabel()
    private let nhanMoTaMucMoRong = UILabel()
    private let nganHanhDongMucMoRong = UIStackView()

    // 6. Menu trượt bên trái (Sidebar Drawer) & lớp nền mờ
    private let lopNenMoMenu = UIControl()
    private let menuBenTrai = MenuDieuHuongBenTraiView()
    private var rangBuocTraiMenu: NSLayoutConstraint?
    private let chieuRongMenu: CGFloat = 286
    private var dangMoMenu: Bool = false

    // Hộp thoại tiến trình quét
    private let lopPhuTai = UIView()
    private let nhanTienTrinh = UILabel()
    private let vongQuay = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BangMauBCTD.nenTrang
        cauHinhThanhDieuHuong()
        taoGiaoDien()
        napDuLieu()
        NotificationCenter.default.addObserver(self, selector: #selector(duLieuDaDongBo), name: .duLieuDMXDaDongBo, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(taiKhoanBiDangXuat), name: .taiKhoanDMXBiDangXuat, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ungDungTroLai), name: UIApplication.willEnterForegroundNotification, object: nil)
        DichVuDongBo.dungChung.taiDuLieu()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        napDuLieu()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func duLieuDaDongBo() {
        dsThiDuaDaNapUI = nil
        napDuLieu()
    }

    @objc private func taiKhoanBiDangXuat() {
        (UIApplication.shared.delegate as? UyQuyenUngDung)?.hienThiDangNhap()
    }

    @objc private func ungDungTroLai() { DichVuDongBo.dungChung.taiDuLieu() }

    // MARK: - Thanh điều hướng trên cùng (Nút mở Menu + Chọn ngày + Nhập số / Xuất ảnh / Cài đặt)

    private func cauHinhThanhDieuHuong() {
        let cfgMenu = UIImage.SymbolConfiguration(pointSize: 14.5, weight: .bold)
        nutMoMenu.setImage(UIImage(systemName: "line.3.horizontal", withConfiguration: cfgMenu), for: .normal)
        nutMoMenu.setTitle(" Menu", for: .normal)
        nutMoMenu.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        nutMoMenu.titleLabel?.numberOfLines = 0
        nutMoMenu.titleLabel?.lineBreakMode = .byWordWrapping
        nutMoMenu.titleLabel?.adjustsFontSizeToFitWidth = false
        nutMoMenu.tintColor = BangMauBCTD.vangSang
        nutMoMenu.setTitleColor(.white, for: .normal)
        nutMoMenu.backgroundColor = BangMauBCTD.xanhChuDao
        nutMoMenu.layer.cornerRadius = 9
        nutMoMenu.contentEdgeInsets = UIEdgeInsets(top: 6, left: 9, bottom: 6, right: 10)
        nutMoMenu.addTarget(self, action: #selector(bamNutMenu), for: .touchUpInside)

        nutNgay.titleLabel?.font = .systemFont(ofSize: 12.0, weight: .bold)
        nutNgay.titleLabel?.numberOfLines = 0
        nutNgay.titleLabel?.lineBreakMode = .byWordWrapping
        nutNgay.titleLabel?.adjustsFontSizeToFitWidth = false
        nutNgay.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
        nutNgay.backgroundColor = BangMauBCTD.nenThe
        nutNgay.layer.cornerRadius = 8
        nutNgay.layer.borderWidth = 1
        nutNgay.layer.borderColor = BangMauBCTD.vienDam.cgColor
        nutNgay.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        nutNgay.addTarget(self, action: #selector(moLichSuNgay), for: .touchUpInside)

        let cumTrai = UIStackView(arrangedSubviews: [nutMoMenu, nutNgay])
        cumTrai.axis = .horizontal
        cumTrai.spacing = 6
        cumTrai.alignment = .center
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cumTrai)

        let cfgPhoto = UIImage.SymbolConfiguration(pointSize: 12.0, weight: .bold)
        nutNhapTatCa.setImage(UIImage(systemName: "photo.stack.fill", withConfiguration: cfgPhoto), for: .normal)
        nutNhapTatCa.setTitle(" Nhập tất cả", for: .normal)
        nutNhapTatCa.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutNhapTatCa.titleLabel?.numberOfLines = 0
        nutNhapTatCa.titleLabel?.lineBreakMode = .byWordWrapping
        nutNhapTatCa.titleLabel?.textAlignment = .center
        nutNhapTatCa.titleLabel?.adjustsFontSizeToFitWidth = false
        nutNhapTatCa.backgroundColor = BangMauBCTD.xanhChuDao
        nutNhapTatCa.tintColor = .white
        nutNhapTatCa.setTitleColor(.white, for: .normal)
        nutNhapTatCa.layer.cornerRadius = 9
        nutNhapTatCa.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        nutNhapTatCa.setContentHuggingPriority(.required, for: .horizontal)
        nutNhapTatCa.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutNhapTatCa.addTarget(self, action: #selector(bamNhapTatCaAnh), for: .touchUpInside)

        let cauHinhIcon = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        nutXuatNav.setImage(UIImage(systemName: "square.and.arrow.up", withConfiguration: cauHinhIcon), for: .normal)
        nutXuatNav.tintColor = BangMauBCTD.chuChinh
        nutXuatNav.backgroundColor = BangMauBCTD.vangSang
        nutXuatNav.layer.cornerRadius = 8
        nutXuatNav.layer.borderWidth = 1
        nutXuatNav.layer.borderColor = BangMauBCTD.vangChuDao.cgColor
        nutXuatNav.translatesAutoresizingMaskIntoConstraints = false
        nutXuatNav.widthAnchor.constraint(equalToConstant: 32).isActive = true
        nutXuatNav.heightAnchor.constraint(equalToConstant: 31).isActive = true
        nutXuatNav.addTarget(self, action: #selector(moMenuXuatBaoCao), for: .touchUpInside)

        nutCaiDatNav.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: cauHinhIcon), for: .normal)
        nutCaiDatNav.tintColor = BangMauBCTD.xanhChuDaoDam
        nutCaiDatNav.backgroundColor = BangMauBCTD.nenHeaderPhu
        nutCaiDatNav.layer.cornerRadius = 8
        nutCaiDatNav.layer.borderWidth = 1
        nutCaiDatNav.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
        nutCaiDatNav.translatesAutoresizingMaskIntoConstraints = false
        nutCaiDatNav.widthAnchor.constraint(equalToConstant: 32).isActive = true
        nutCaiDatNav.heightAnchor.constraint(equalToConstant: 31).isActive = true
        nutCaiDatNav.addTarget(self, action: #selector(bamMoCaiDatNhanh), for: .touchUpInside)

        let cumPhai = UIStackView(arrangedSubviews: [nutNhapTatCa, nutXuatNav, nutCaiDatNav])
        cumPhai.axis = .horizontal
        cumPhai.spacing = 5
        cumPhai.alignment = .center
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cumPhai)
    }

    @objc private func bamMoCaiDatNhanh() {
        mucMenuChinh = .caiDat
        anMenu(animated: true)
        napDuLieu()
    }

    @objc private func bamNutMenu() {
        if dangMoMenu {
            anMenu(animated: true)
        } else {
            hienMenu(animated: true)
        }
    }

    private func hienMenu(animated: Bool) {
        dangMoMenu = true
        menuBenTrai.capNhatTrangThai(mucChinh: mucMenuChinh, mucCon: mucConDoSo)
        lopNenMoMenu.isHidden = false
        menuBenTrai.isHidden = false
        view.bringSubviewToFront(lopNenMoMenu)
        view.bringSubviewToFront(menuBenTrai)
        view.bringSubviewToFront(lopPhuTai)

        rangBuocTraiMenu?.constant = 0
        if animated {
            UIView.animate(withDuration: 0.24, delay: 0, options: [.curveEaseOut]) {
                self.lopNenMoMenu.alpha = 1
                self.view.layoutIfNeeded()
            }
        } else {
            lopNenMoMenu.alpha = 1
            view.layoutIfNeeded()
        }
    }

    @objc private func anMenu(animated: Bool = true) {
        guard dangMoMenu else { return }
        dangMoMenu = false
        view.endEditing(true)
        rangBuocTraiMenu?.constant = -chieuRongMenu
        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseIn]) {
                self.lopNenMoMenu.alpha = 0
                self.view.layoutIfNeeded()
            } completion: { _ in
                if !self.dangMoMenu {
                    self.lopNenMoMenu.isHidden = true
                    self.menuBenTrai.isHidden = true
                }
            }
        } else {
            lopNenMoMenu.alpha = 0
            lopNenMoMenu.isHidden = true
            menuBenTrai.isHidden = true
            view.layoutIfNeeded()
        }
    }

    private func chuyenSangTaiKhoanHopThu() {
        mucMenuChinh = .caiDat
        anMenu(animated: true)
        napDuLieu()
    }

    @objc private func bamNhapTatCaAnh() {
        moChonAnh(cheDo: .tatCaAnhTheoTab(cheDoDoanhThu), gioiHan: 0)
    }

    // MARK: - Dựng giao diện chính

    private func taoGiaoDien() {
        khungDoSoXemSo.backgroundColor = .clear
        khungDoSoXemSo.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(khungDoSoXemSo)

        // 0. Thanh chuyển nhanh 3 mục con của "Đổ số - Xem số": 1. Xem số | 2. Nhập số | 3. Xuất ảnh
        khungThanhMucConDoSo.backgroundColor = BangMauBCTD.nenThe
        khungThanhMucConDoSo.layer.cornerRadius = 11
        khungThanhMucConDoSo.layer.borderWidth = 1
        khungThanhMucConDoSo.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor

        nganNutMucConDoSo.axis = .horizontal
        nganNutMucConDoSo.spacing = 6
        nganNutMucConDoSo.distribution = .fillEqually
        nganNutMucConDoSo.translatesAutoresizingMaskIntoConstraints = false
        khungThanhMucConDoSo.addSubview(nganNutMucConDoSo)

        cacNutMucConDoSo.removeAll()
        for mucCon in MucConDoSo.allCases {
            let nut = UIButton(type: .custom)
            nut.tag = mucCon.rawValue
            let bieuTuong: String
            switch mucCon {
            case .xemSo: bieuTuong = "👁️ "
            case .nhapSo: bieuTuong = "📥 "
            case .xuatAnh: bieuTuong = "🖼️ "
            }
            nut.setTitle(bieuTuong + mucCon.tieuDe, for: .normal)
            nut.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
            nut.titleLabel?.numberOfLines = 0
            nut.titleLabel?.lineBreakMode = .byWordWrapping
            nut.titleLabel?.textAlignment = .center
            nut.titleLabel?.adjustsFontSizeToFitWidth = false
            nut.contentEdgeInsets = UIEdgeInsets(top: 7, left: 6, bottom: 7, right: 6)
            nut.layer.cornerRadius = 8
            nut.addTarget(self, action: #selector(bamChonMucConTrenThanh(_:)), for: .touchUpInside)
            cacNutMucConDoSo.append(nut)
            nganNutMucConDoSo.addArrangedSubview(nut)
        }

        // Khung Mục con 1: XEM SỐ (Chứa thanh 4 tab Lũy kế | Realtime | Biểu đồ | Nhân viên)
        khungXemSo.backgroundColor = .clear
        khungXemSo.translatesAutoresizingMaskIntoConstraints = false

        khungThanhTabXemSo.backgroundColor = BangMauBCTD.nenHeaderPhu
        khungThanhTabXemSo.layer.cornerRadius = 10
        khungThanhTabXemSo.layer.borderWidth = 1
        khungThanhTabXemSo.layer.borderColor = BangMauBCTD.vienThe.cgColor

        nganNutTabXemSo.axis = .horizontal
        nganNutTabXemSo.spacing = 4
        nganNutTabXemSo.distribution = .fillEqually
        nganNutTabXemSo.translatesAutoresizingMaskIntoConstraints = false
        khungThanhTabXemSo.addSubview(nganNutTabXemSo)

        cacNutTabXemSo.removeAll()
        for tab in TabXemSo.allCases {
            let nut = UIButton(type: .custom)
            nut.tag = tab.rawValue
            nut.setTitle("\(tab.bieuTuong) \(tab.tieuDe)", for: .normal)
            nut.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
            nut.titleLabel?.numberOfLines = 0
            nut.titleLabel?.lineBreakMode = .byWordWrapping
            nut.titleLabel?.textAlignment = .center
            nut.titleLabel?.adjustsFontSizeToFitWidth = false
            nut.contentEdgeInsets = UIEdgeInsets(top: 6, left: 4, bottom: 6, right: 4)
            nut.layer.cornerRadius = 7
            nut.addTarget(self, action: #selector(bamChonTabXemSo(_:)), for: .touchUpInside)
            cacNutTabXemSo.append(nut)
            nganNutTabXemSo.addArrangedSubview(nut)
        }

        // Khung cụm Doanh thu sáng sủa + thanh tiêu đề xanh tươi
        khungCumDoanhThu.backgroundColor = BangMauBCTD.nenThe
        khungCumDoanhThu.layer.cornerRadius = 12
        khungCumDoanhThu.layer.borderWidth = 1
        khungCumDoanhThu.layer.borderColor = BangMauBCTD.vienThe.cgColor
        khungCumDoanhThu.clipsToBounds = true

        thanhTieuDeDoanhThu.backgroundColor = BangMauBCTD.xanhChuDao
        thanhTieuDeDoanhThu.addTarget(self, action: #selector(bamTheDoanhThu), for: .touchUpInside)
        thanhTieuDeDoanhThu.translatesAutoresizingMaskIntoConstraints = false
        khungCumDoanhThu.addSubview(thanhTieuDeDoanhThu)

        let vachVangDauDT = UIView()
        vachVangDauDT.backgroundColor = BangMauBCTD.vangSang
        vachVangDauDT.isUserInteractionEnabled = false
        vachVangDauDT.translatesAutoresizingMaskIntoConstraints = false
        thanhTieuDeDoanhThu.addSubview(vachVangDauDT)

        nhanTieuDeCumDoanhThu.text = "CHỈ SỐ KINH DOANH · LŨY KẾ"
        nhanTieuDeCumDoanhThu.font = .systemFont(ofSize: 11.5, weight: .heavy)
        nhanTieuDeCumDoanhThu.textColor = BangMauBCTD.vangSang
        nhanTieuDeCumDoanhThu.numberOfLines = 0
        nhanTieuDeCumDoanhThu.lineBreakMode = .byWordWrapping
        nhanTieuDeCumDoanhThu.adjustsFontSizeToFitWidth = false
        nhanTieuDeCumDoanhThu.isUserInteractionEnabled = false
        nhanTieuDeCumDoanhThu.translatesAutoresizingMaskIntoConstraints = false
        thanhTieuDeDoanhThu.addSubview(nhanTieuDeCumDoanhThu)

        nhanPhuCumDoanhThu.text = "Chạm 8 thẻ để quét/sửa ▸"
        nhanPhuCumDoanhThu.font = .systemFont(ofSize: 10.5, weight: .semibold)
        nhanPhuCumDoanhThu.textColor = .white
        nhanPhuCumDoanhThu.textAlignment = .right
        nhanPhuCumDoanhThu.numberOfLines = 0
        nhanPhuCumDoanhThu.lineBreakMode = .byWordWrapping
        nhanPhuCumDoanhThu.adjustsFontSizeToFitWidth = false
        nhanPhuCumDoanhThu.isUserInteractionEnabled = false
        nhanPhuCumDoanhThu.setContentCompressionResistancePriority(.required, for: .horizontal)
        nhanPhuCumDoanhThu.translatesAutoresizingMaskIntoConstraints = false
        thanhTieuDeDoanhThu.addSubview(nhanPhuCumDoanhThu)

        vachNganHaiCum.backgroundColor = .clear
        vachNganHaiCum.isHidden = true

        khungCumDuoi.backgroundColor = BangMauBCTD.nenThe
        khungCumDuoi.layer.cornerRadius = 12
        khungCumDuoi.layer.borderWidth = 1
        khungCumDuoi.layer.borderColor = BangMauBCTD.vienThe.cgColor

        // 1. Cụm 8 thẻ Chỉ số chính
        cumChiSoChinh.addTarget(self, action: #selector(bamTheDoanhThu), for: .touchUpInside)
        cumChiSoChinh.khiBamVungThe = { [weak self] in
            self?.bamTheDoanhThu()
        }

        // 2. Thanh chọn nhanh chế độ dữ liệu Lũy kế / Realtime khi đang xem tab "Nhân viên"
        cauHinhNutCheDoNV(nutNVLuyKe, tieuDe: "📊 Nhân viên Lũy kế", tag: LoaiCheDoDoanhThu.luyKe.rawValue)
        cauHinhNutCheDoNV(nutNVRealtime, tieuDe: "⚡ Nhân viên Realtime", tag: LoaiCheDoDoanhThu.realtime.rawValue)
        hangChonCheDoNV.addArrangedSubview(nutNVLuyKe)
        hangChonCheDoNV.addArrangedSubview(nutNVRealtime)
        hangChonCheDoNV.axis = .horizontal
        hangChonCheDoNV.spacing = 6
        hangChonCheDoNV.distribution = .fillEqually

        // 3. Thanh nút Quét & Xoá
        nutThemAnhMoi.setImage(UIImage(systemName: "camera.viewfinder"), for: .normal)
        nutThemAnhMoi.setTitle(" Thêm ảnh", for: .normal)
        nutThemAnhMoi.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutThemAnhMoi.titleLabel?.numberOfLines = 0
        nutThemAnhMoi.titleLabel?.lineBreakMode = .byWordWrapping
        nutThemAnhMoi.titleLabel?.textAlignment = .center
        nutThemAnhMoi.titleLabel?.adjustsFontSizeToFitWidth = false
        nutThemAnhMoi.backgroundColor = BangMauBCTD.xanhChuDao
        nutThemAnhMoi.tintColor = .white
        nutThemAnhMoi.setTitleColor(.white, for: .normal)
        nutThemAnhMoi.layer.cornerRadius = 9
        nutThemAnhMoi.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        nutThemAnhMoi.addTarget(self, action: #selector(bamThemAnhMoi), for: .touchUpInside)

        nutNhapDoanhThuNV.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        nutNhapDoanhThuNV.setTitle(" Nhập ảnh Doanh thu", for: .normal)
        nutNhapDoanhThuNV.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutNhapDoanhThuNV.titleLabel?.numberOfLines = 0
        nutNhapDoanhThuNV.titleLabel?.lineBreakMode = .byWordWrapping
        nutNhapDoanhThuNV.titleLabel?.textAlignment = .center
        nutNhapDoanhThuNV.titleLabel?.adjustsFontSizeToFitWidth = false
        nutNhapDoanhThuNV.backgroundColor = BangMauBCTD.indigoNhatNen
        nutNhapDoanhThuNV.tintColor = BangMauBCTD.indigoDam
        nutNhapDoanhThuNV.setTitleColor(BangMauBCTD.indigoDam, for: .normal)
        nutNhapDoanhThuNV.layer.cornerRadius = 9
        nutNhapDoanhThuNV.layer.borderWidth = 1
        nutNhapDoanhThuNV.layer.borderColor = BangMauBCTD.indigoVien.cgColor
        nutNhapDoanhThuNV.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        nutNhapDoanhThuNV.addTarget(self, action: #selector(bamNhapAnhDoanhThuNV), for: .touchUpInside)

        nutXoaQuetLai.setTitle(" Xoá", for: .normal)
        nutXoaQuetLai.setImage(UIImage(systemName: "trash.fill"), for: .normal)
        nutXoaQuetLai.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutXoaQuetLai.titleLabel?.numberOfLines = 0
        nutXoaQuetLai.titleLabel?.lineBreakMode = .byWordWrapping
        nutXoaQuetLai.titleLabel?.textAlignment = .center
        nutXoaQuetLai.titleLabel?.adjustsFontSizeToFitWidth = false
        nutXoaQuetLai.backgroundColor = BangMauBCTD.doYeuPill
        nutXoaQuetLai.tintColor = BangMauBCTD.doYeuChu
        nutXoaQuetLai.setTitleColor(BangMauBCTD.doYeuChu, for: .normal)
        nutXoaQuetLai.layer.cornerRadius = 9
        nutXoaQuetLai.layer.borderWidth = 1
        nutXoaQuetLai.layer.borderColor = BangMauBCTD.doYeuVach.withAlphaComponent(0.3).cgColor
        nutXoaQuetLai.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        nutXoaQuetLai.addTarget(self, action: #selector(bamXoaQuetLai), for: .touchUpInside)

        nutThemThuCong.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        nutThemThuCong.setTitle(" Nhập/Mẫu", for: .normal)
        nutThemThuCong.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutThemThuCong.titleLabel?.numberOfLines = 0
        nutThemThuCong.titleLabel?.lineBreakMode = .byWordWrapping
        nutThemThuCong.titleLabel?.textAlignment = .center
        nutThemThuCong.titleLabel?.adjustsFontSizeToFitWidth = false
        nutThemThuCong.backgroundColor = BangMauBCTD.nenThePhu
        nutThemThuCong.tintColor = BangMauBCTD.chuChinh
        nutThemThuCong.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
        nutThemThuCong.layer.cornerRadius = 9
        nutThemThuCong.layer.borderWidth = 1
        nutThemThuCong.layer.borderColor = BangMauBCTD.vienDam.cgColor
        nutThemThuCong.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        nutThemThuCong.addTarget(self, action: #selector(bamThemDongThuCong), for: .touchUpInside)

        hangNutQuet = UIStackView(arrangedSubviews: [nutThemAnhMoi, nutNhapDoanhThuNV, nutXoaQuetLai, nutThemThuCong])
        hangNutQuet.axis = .horizontal
        hangNutQuet.spacing = 6
        nutThemAnhMoi.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nutThemAnhMoi.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nutNhapDoanhThuNV.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nutNhapDoanhThuNV.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nutXoaQuetLai.setContentHuggingPriority(.required, for: .horizontal)
        nutXoaQuetLai.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutThemThuCong.setContentHuggingPriority(.required, for: .horizontal)
        nutThemThuCong.setContentCompressionResistancePriority(.required, for: .horizontal)

        let rgBangRongNV = nutNhapDoanhThuNV.widthAnchor.constraint(equalTo: nutThemAnhMoi.widthAnchor)
        rgBangRongNV.priority = .defaultHigh
        rangBuocBangRongHaiNutNV = rgBangRongNV

        // 4. Sự kiện các bảng dữ liệu trong phần "1. Xem số"
        bangThiDua.khiBamQuetAnh = { [weak self] in
            self?.bamThemAnhMoi()
        }
        bangThiDua.khiDoiCheDoDuKien = { [weak self] _ in
            self?.napDuLieu()
        }
        bangThiDua.khiChonDong = { [weak self] dong in
            guard let self = self else { return }
            let vc = ManHinhChiTietNganhHang(dong: dong, ngay: self.ngayHienTai, cheDo: self.cheDoDoanhThu)
            vc.khiCapNhatDuLieu = { [weak self] in
                self?.dsThiDuaDaNapUI = nil
                self?.napDuLieu()
            }
            vc.khiYeuCauSuaDong = { [weak self] dongCanSua in
                self?.moHopThoaiSuaDong(dongCanSua)
            }
            self.navigationController?.pushViewController(vc, animated: true)
        }
        bangThiDua.khiSuaDong = { [weak self] dong in
            self?.moHopThoaiSuaDong(dong)
        }
        bangThiDua.khiXoaDong = { [weak self] id in
            guard let self = self else { return }
            var dl = KhoDuLieu.dungChung.duLieu(cho: self.ngayHienTai)
            var ds = dl.danhSachThiDua(theo: self.cheDoDoanhThu)
            ds.removeAll { $0.id == id }
            dl.ganDanhSachThiDua(ds, theo: self.cheDoDoanhThu)
            KhoDuLieu.dungChung.luu(dl)
            self.napDuLieu()
        }

        bangNhanVien.khiChonNhanVien = { [weak self] row in
            guard let self = self else { return }
            let vc = ManHinhChiTietNhanVien(row, ngay: self.ngayHienTai, cheDo: self.cheDoDoanhThu)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        bangNhanVien.khiBamQuetDoanhThuNV = { [weak self] in
            guard let self = self else { return }
            self.moChonAnh(cheDo: .doanhThuNhanVien(self.cheDoDoanhThu), gioiHan: 0)
        }
        bangNhanVien.khiBamMoCaiDatNV = { [weak self] in
            self?.chuyenSangTaiKhoanHopThu()
        }

        bangRealtimeThang.khiBamSuaDoanhThuLuyKe = { [weak self] in
            guard let self = self else { return }
            self.mucMenuChinh = .doSoXemSo
            self.mucConDoSo = .xemSo
            self.tabXemSo = .luyKe
            self.cheDoDoanhThu = .luyKe
            self.napDuLieu()
            self.bamTheDoanhThu()
        }
        bangRealtimeThang.khiChonNgayRealtime = { [weak self] item in
            self?.moMenuRealtimeChoNgay(item)
        }
        bangRealtimeThang.khiChonNhanVienSucKhoe = { [weak self] row, cheDo in
            guard let self = self else { return }
            let vc = ManHinhChiTietNhanVien(row, ngay: self.ngayHienTai, cheDo: cheDo)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        bangRealtimeThang.khiChiaSeAnhSucKhoe = { [weak self] anh in
            self?.chiaSe([anh])
        }

        cumChiSoChinh.translatesAutoresizingMaskIntoConstraints = false
        khungCumDoanhThu.addSubview(cumChiSoChinh)

        [hangChonCheDoNV, hangNutQuet, bangThiDua, bangNhanVien, bangRealtimeThang].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            khungCumDuoi.addSubview($0)
        }

        [khungThanhTabXemSo, khungCumDoanhThu, vachNganHaiCum, khungCumDuoi].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            khungXemSo.addSubview($0)
        }

        taoKhungNhapSo()
        taoKhungXuatAnh()

        [khungThanhMucConDoSo, khungXemSo, khungNhapSo, khungXuatAnh].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            khungDoSoXemSo.addSubview($0)
        }

        let rgTopDuoiTheoVach = khungCumDuoi.topAnchor.constraint(equalTo: khungCumDoanhThu.bottomAnchor, constant: 6)
        let rgTopDuoiTheoDinh = khungCumDuoi.topAnchor.constraint(equalTo: khungThanhTabXemSo.bottomAnchor, constant: 6)
        rangBuocTopKhungDuoiTheoVach = rgTopDuoiTheoVach
        rangBuocTopKhungDuoiTheoDinh = rgTopDuoiTheoDinh

        let rgTopNutQuetNV = hangNutQuet.topAnchor.constraint(equalTo: hangChonCheDoNV.bottomAnchor, constant: 6)
        let rgTopNutQuetDinh = hangNutQuet.topAnchor.constraint(equalTo: khungCumDuoi.topAnchor, constant: 8)
        rangBuocTopNutQuetTheoNV = rgTopNutQuetNV
        rangBuocTopNutQuetTheoDinh = rgTopNutQuetDinh

        let rgTopBangTD = bangThiDua.topAnchor.constraint(equalTo: hangNutQuet.bottomAnchor, constant: 8)
        let rgTopBangNV = bangNhanVien.topAnchor.constraint(equalTo: hangNutQuet.bottomAnchor, constant: 8)
        rangBuocTopBangThiDua = rgTopBangTD
        rangBuocTopBangNhanVien = rgTopBangNV

        NSLayoutConstraint.activate([
            khungDoSoXemSo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            khungDoSoXemSo.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            khungDoSoXemSo.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            khungDoSoXemSo.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            khungThanhMucConDoSo.topAnchor.constraint(equalTo: khungDoSoXemSo.topAnchor, constant: 4),
            khungThanhMucConDoSo.leadingAnchor.constraint(equalTo: khungDoSoXemSo.leadingAnchor, constant: 8),
            khungThanhMucConDoSo.trailingAnchor.constraint(equalTo: khungDoSoXemSo.trailingAnchor, constant: -8),
            khungThanhMucConDoSo.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),

            nganNutMucConDoSo.topAnchor.constraint(equalTo: khungThanhMucConDoSo.topAnchor, constant: 4),
            nganNutMucConDoSo.leadingAnchor.constraint(equalTo: khungThanhMucConDoSo.leadingAnchor, constant: 4),
            nganNutMucConDoSo.trailingAnchor.constraint(equalTo: khungThanhMucConDoSo.trailingAnchor, constant: -4),
            nganNutMucConDoSo.bottomAnchor.constraint(equalTo: khungThanhMucConDoSo.bottomAnchor, constant: -4),

            khungXemSo.topAnchor.constraint(equalTo: khungThanhMucConDoSo.bottomAnchor, constant: 4),
            khungXemSo.leadingAnchor.constraint(equalTo: khungDoSoXemSo.leadingAnchor),
            khungXemSo.trailingAnchor.constraint(equalTo: khungDoSoXemSo.trailingAnchor),
            khungXemSo.bottomAnchor.constraint(equalTo: khungDoSoXemSo.bottomAnchor),

            khungNhapSo.topAnchor.constraint(equalTo: khungThanhMucConDoSo.bottomAnchor, constant: 4),
            khungNhapSo.leadingAnchor.constraint(equalTo: khungDoSoXemSo.leadingAnchor),
            khungNhapSo.trailingAnchor.constraint(equalTo: khungDoSoXemSo.trailingAnchor),
            khungNhapSo.bottomAnchor.constraint(equalTo: khungDoSoXemSo.bottomAnchor),

            khungXuatAnh.topAnchor.constraint(equalTo: khungThanhMucConDoSo.bottomAnchor, constant: 4),
            khungXuatAnh.leadingAnchor.constraint(equalTo: khungDoSoXemSo.leadingAnchor),
            khungXuatAnh.trailingAnchor.constraint(equalTo: khungDoSoXemSo.trailingAnchor),
            khungXuatAnh.bottomAnchor.constraint(equalTo: khungDoSoXemSo.bottomAnchor),

            khungThanhTabXemSo.topAnchor.constraint(equalTo: khungXemSo.topAnchor, constant: 2),
            khungThanhTabXemSo.leadingAnchor.constraint(equalTo: khungXemSo.leadingAnchor, constant: 8),
            khungThanhTabXemSo.trailingAnchor.constraint(equalTo: khungXemSo.trailingAnchor, constant: -8),
            khungThanhTabXemSo.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),

            nganNutTabXemSo.topAnchor.constraint(equalTo: khungThanhTabXemSo.topAnchor, constant: 3),
            nganNutTabXemSo.leadingAnchor.constraint(equalTo: khungThanhTabXemSo.leadingAnchor, constant: 3),
            nganNutTabXemSo.trailingAnchor.constraint(equalTo: khungThanhTabXemSo.trailingAnchor, constant: -3),
            nganNutTabXemSo.bottomAnchor.constraint(equalTo: khungThanhTabXemSo.bottomAnchor, constant: -3),

            khungCumDoanhThu.topAnchor.constraint(equalTo: khungThanhTabXemSo.bottomAnchor, constant: 6),
            khungCumDoanhThu.leadingAnchor.constraint(equalTo: khungXemSo.leadingAnchor, constant: 8),
            khungCumDoanhThu.trailingAnchor.constraint(equalTo: khungXemSo.trailingAnchor, constant: -8),

            thanhTieuDeDoanhThu.topAnchor.constraint(equalTo: khungCumDoanhThu.topAnchor),
            thanhTieuDeDoanhThu.leadingAnchor.constraint(equalTo: khungCumDoanhThu.leadingAnchor),
            thanhTieuDeDoanhThu.trailingAnchor.constraint(equalTo: khungCumDoanhThu.trailingAnchor),
            thanhTieuDeDoanhThu.heightAnchor.constraint(greaterThanOrEqualToConstant: 29),

            vachVangDauDT.topAnchor.constraint(equalTo: thanhTieuDeDoanhThu.topAnchor),
            vachVangDauDT.bottomAnchor.constraint(equalTo: thanhTieuDeDoanhThu.bottomAnchor),
            vachVangDauDT.leadingAnchor.constraint(equalTo: thanhTieuDeDoanhThu.leadingAnchor),
            vachVangDauDT.widthAnchor.constraint(equalToConstant: 4),

            nhanTieuDeCumDoanhThu.topAnchor.constraint(equalTo: thanhTieuDeDoanhThu.topAnchor, constant: 5),
            nhanTieuDeCumDoanhThu.bottomAnchor.constraint(equalTo: thanhTieuDeDoanhThu.bottomAnchor, constant: -5),
            nhanTieuDeCumDoanhThu.leadingAnchor.constraint(equalTo: vachVangDauDT.trailingAnchor, constant: 8),
            nhanTieuDeCumDoanhThu.trailingAnchor.constraint(lessThanOrEqualTo: nhanPhuCumDoanhThu.leadingAnchor, constant: -6),

            nhanPhuCumDoanhThu.centerYAnchor.constraint(equalTo: thanhTieuDeDoanhThu.centerYAnchor),
            nhanPhuCumDoanhThu.trailingAnchor.constraint(equalTo: thanhTieuDeDoanhThu.trailingAnchor, constant: -10),

            cumChiSoChinh.topAnchor.constraint(equalTo: thanhTieuDeDoanhThu.bottomAnchor, constant: 7),
            cumChiSoChinh.leadingAnchor.constraint(equalTo: khungCumDoanhThu.leadingAnchor, constant: 7),
            cumChiSoChinh.trailingAnchor.constraint(equalTo: khungCumDoanhThu.trailingAnchor, constant: -7),
            cumChiSoChinh.bottomAnchor.constraint(equalTo: khungCumDoanhThu.bottomAnchor, constant: -7),
            cumChiSoChinh.heightAnchor.constraint(equalToConstant: 146),

            rgTopDuoiTheoVach,
            khungCumDuoi.leadingAnchor.constraint(equalTo: khungXemSo.leadingAnchor, constant: 8),
            khungCumDuoi.trailingAnchor.constraint(equalTo: khungXemSo.trailingAnchor, constant: -8),
            khungCumDuoi.bottomAnchor.constraint(equalTo: khungXemSo.bottomAnchor, constant: -4),

            hangChonCheDoNV.topAnchor.constraint(equalTo: khungCumDuoi.topAnchor, constant: 8),
            hangChonCheDoNV.leadingAnchor.constraint(equalTo: khungCumDuoi.leadingAnchor, constant: 8),
            hangChonCheDoNV.trailingAnchor.constraint(equalTo: khungCumDuoi.trailingAnchor, constant: -8),
            hangChonCheDoNV.heightAnchor.constraint(greaterThanOrEqualToConstant: 34),

            rgTopNutQuetDinh,
            hangNutQuet.leadingAnchor.constraint(equalTo: khungCumDuoi.leadingAnchor, constant: 8),
            hangNutQuet.trailingAnchor.constraint(equalTo: khungCumDuoi.trailingAnchor, constant: -8),
            hangNutQuet.heightAnchor.constraint(greaterThanOrEqualToConstant: 38),

            rgTopBangTD,
            bangThiDua.leadingAnchor.constraint(equalTo: khungCumDuoi.leadingAnchor, constant: 6),
            bangThiDua.trailingAnchor.constraint(equalTo: khungCumDuoi.trailingAnchor, constant: -6),
            bangThiDua.bottomAnchor.constraint(equalTo: khungCumDuoi.bottomAnchor, constant: -6),

            rgTopBangNV,
            bangNhanVien.leadingAnchor.constraint(equalTo: khungCumDuoi.leadingAnchor, constant: 2),
            bangNhanVien.trailingAnchor.constraint(equalTo: khungCumDuoi.trailingAnchor, constant: -2),
            bangNhanVien.bottomAnchor.constraint(equalTo: khungCumDuoi.bottomAnchor, constant: -6),

            bangRealtimeThang.topAnchor.constraint(equalTo: khungCumDuoi.topAnchor, constant: 8),
            bangRealtimeThang.leadingAnchor.constraint(equalTo: khungCumDuoi.leadingAnchor, constant: 6),
            bangRealtimeThang.trailingAnchor.constraint(equalTo: khungCumDuoi.trailingAnchor, constant: -6),
            bangRealtimeThang.bottomAnchor.constraint(equalTo: khungCumDuoi.bottomAnchor, constant: -6)
        ])

        taoKhungTongQuan()
        taoKhungBaoCao()
        taoKhungTaiKhoanHopThu()
        taoKhungQuanTri()
        taoKhungMucMoRong()
        taoMenuTruotBenTrai()
        taoLopPhuTienTrinh()
        capNhatTrangThaiMuc()
    }

    // MARK: - Mục con 2: Giao diện "2. Nhập số" (Nhập tất cả Lũy kế & Nhập tất cả Realtime + Nhập từng phần)

    private func taoKhungNhapSo() {
        khungNhapSo.backgroundColor = BangMauBCTD.nenTrang
        khungNhapSo.isHidden = true

        let cuon = UIScrollView()
        cuon.alwaysBounceVertical = true
        cuon.translatesAutoresizingMaskIntoConstraints = false
        khungNhapSo.addSubview(cuon)

        let ngan = UIStackView()
        ngan.axis = .vertical
        ngan.spacing = 12
        ngan.translatesAutoresizingMaskIntoConstraints = false
        cuon.addSubview(ngan)

        NSLayoutConstraint.activate([
            cuon.topAnchor.constraint(equalTo: khungNhapSo.topAnchor),
            cuon.leadingAnchor.constraint(equalTo: khungNhapSo.leadingAnchor),
            cuon.trailingAnchor.constraint(equalTo: khungNhapSo.trailingAnchor),
            cuon.bottomAnchor.constraint(equalTo: khungNhapSo.bottomAnchor),

            ngan.topAnchor.constraint(equalTo: cuon.contentLayoutGuide.topAnchor, constant: 8),
            ngan.leadingAnchor.constraint(equalTo: cuon.frameLayoutGuide.leadingAnchor, constant: 10),
            ngan.trailingAnchor.constraint(equalTo: cuon.frameLayoutGuide.trailingAnchor, constant: -10),
            ngan.bottomAnchor.constraint(equalTo: cuon.contentLayoutGuide.bottomAnchor, constant: -24)
        ])

        // Thẻ trạng thái dữ liệu đã nhập
        let theTrangThai = UIView()
        theTrangThai.backgroundColor = BangMauBCTD.nenThe
        theTrangThai.layer.cornerRadius = 12
        theTrangThai.layer.borderWidth = 1
        theTrangThai.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor

        nhanTrangThaiNhapSo.font = .systemFont(ofSize: 13.0, weight: .semibold)
        nhanTrangThaiNhapSo.textColor = BangMauBCTD.chuChinh
        nhanTrangThaiNhapSo.numberOfLines = 0
        nhanTrangThaiNhapSo.lineBreakMode = .byWordWrapping
        nhanTrangThaiNhapSo.adjustsFontSizeToFitWidth = false
        nhanTrangThaiNhapSo.translatesAutoresizingMaskIntoConstraints = false
        theTrangThai.addSubview(nhanTrangThaiNhapSo)

        NSLayoutConstraint.activate([
            nhanTrangThaiNhapSo.topAnchor.constraint(equalTo: theTrangThai.topAnchor, constant: 12),
            nhanTrangThaiNhapSo.leadingAnchor.constraint(equalTo: theTrangThai.leadingAnchor, constant: 12),
            nhanTrangThaiNhapSo.trailingAnchor.constraint(equalTo: theTrangThai.trailingAnchor, constant: -12),
            nhanTrangThaiNhapSo.bottomAnchor.constraint(equalTo: theTrangThai.bottomAnchor, constant: -12)
        ])
        ngan.addArrangedSubview(theTrangThai)

        // 2 Nút lớn: NHẬP TẤT CẢ LŨY KẾ & NHẬP TẤT CẢ REALTIME
        let nutNhapAllLK = taoNutLonNhapSo(
            tieuDe: "📥 NHẬP TẤT CẢ LŨY KẾ (Chọn nhiều ảnh 1 lần)",
            moTa: "Tự động đọc & phân loại: Doanh thu Lũy kế + Thi đua ngành hàng Lũy kế + Doanh thu NV & Thi đua NV Lũy kế",
            mauNen: BangMauBCTD.xanhChuDao,
            mauChu: .white,
            action: #selector(bamNhapTatCaLuyKe)
        )
        let nutNhapAllRT = taoNutLonNhapSo(
            tieuDe: "⚡ NHẬP TẤT CẢ REALTIME (Chọn nhiều ảnh 1 lần)",
            moTa: "Tự động đọc & phân loại: Doanh thu Realtime + Thi đua ngành hàng Realtime + Doanh thu NV & Thi đua NV Realtime",
            mauNen: BangMauBCTD.xanhDatVach,
            mauChu: .white,
            action: #selector(bamNhapTatCaRealtime)
        )
        ngan.addArrangedSubview(nutNhapAllLK)
        ngan.addArrangedSubview(nutNhapAllRT)

        // Khung nhập từng phần Lũy kế
        let theLK = taoKhungNhapTungPhan(
            tieuDe: "📊 NHẬP / SỬA TỪNG PHẦN — LŨY KẾ THÁNG",
            cacNut: [
                ("📷 Quét 2 ảnh Doanh thu Lũy kế (Thực + QĐ)", #selector(bamQuetDoanhThuLK)),
                ("✏️ Nhập / Sửa tay số liệu Doanh thu Lũy kế", #selector(bamSuaTayDoanhThuLK)),
                ("📋 Quét ảnh Bảng Thi đua Ngành hàng Lũy kế", #selector(bamQuetThiDuaLK)),
                ("👥 Quét ảnh Doanh thu Hợp nhất Nhân viên Lũy kế", #selector(bamQuetDoanhThuNVLK)),
                ("🏆 Quét ảnh Thực hiện Thi đua Nhân viên Lũy kế", #selector(bamQuetThiDuaNVLK))
            ]
        )
        ngan.addArrangedSubview(theLK)

        // Khung nhập từng phần Realtime
        let theRT = taoKhungNhapTungPhan(
            tieuDe: "⚡ NHẬP / SỬA TỪNG PHẦN — REALTIME HÔM NAY",
            cacNut: [
                ("📷 Quét 2 ảnh Doanh thu Realtime (Thực + QĐ)", #selector(bamQuetDoanhThuRT)),
                ("✏️ Nhập / Sửa tay số liệu Doanh thu Realtime", #selector(bamSuaTayDoanhThuRT)),
                ("📋 Quét ảnh Bảng Thi đua Ngành hàng Realtime", #selector(bamQuetThiDuaRT)),
                ("👥 Quét ảnh Doanh thu Hợp nhất Nhân viên Realtime", #selector(bamQuetDoanhThuNVRT)),
                ("🏆 Quét ảnh Thực hiện Thi đua Nhân viên Realtime", #selector(bamQuetThiDuaNVRT))
            ]
        )
        ngan.addArrangedSubview(theRT)
    }

    private func taoNutLonNhapSo(
        tieuDe: String,
        moTa: String,
        mauNen: UIColor,
        mauChu: UIColor,
        action: Selector
    ) -> UIControl {
        let the = UIControl()
        the.backgroundColor = mauNen
        the.layer.cornerRadius = 14
        the.addTarget(self, action: action, for: .touchUpInside)

        let lbTieuDe = UILabel()
        lbTieuDe.text = tieuDe
        lbTieuDe.font = .systemFont(ofSize: 15.5, weight: .heavy)
        lbTieuDe.textColor = mauChu
        lbTieuDe.numberOfLines = 0
        lbTieuDe.lineBreakMode = .byWordWrapping
        lbTieuDe.adjustsFontSizeToFitWidth = false
        lbTieuDe.isUserInteractionEnabled = false

        let lbMoTa = UILabel()
        lbMoTa.text = moTa
        lbMoTa.font = .systemFont(ofSize: 12.5, weight: .medium)
        lbMoTa.textColor = mauChu.withAlphaComponent(0.92)
        lbMoTa.numberOfLines = 0
        lbMoTa.lineBreakMode = .byWordWrapping
        lbMoTa.adjustsFontSizeToFitWidth = false
        lbMoTa.isUserInteractionEnabled = false

        let ngan = UIStackView(arrangedSubviews: [lbTieuDe, lbMoTa])
        ngan.axis = .vertical
        ngan.spacing = 4
        ngan.isUserInteractionEnabled = false
        ngan.translatesAutoresizingMaskIntoConstraints = false
        the.addSubview(ngan)

        NSLayoutConstraint.activate([
            ngan.topAnchor.constraint(equalTo: the.topAnchor, constant: 14),
            ngan.leadingAnchor.constraint(equalTo: the.leadingAnchor, constant: 14),
            ngan.trailingAnchor.constraint(equalTo: the.trailingAnchor, constant: -14),
            ngan.bottomAnchor.constraint(equalTo: the.bottomAnchor, constant: -14)
        ])
        return the
    }

    private func taoKhungNhapTungPhan(tieuDe: String, cacNut: [(String, Selector)]) -> UIView {
        let khung = UIView()
        khung.backgroundColor = BangMauBCTD.nenThe
        khung.layer.cornerRadius = 12
        khung.layer.borderWidth = 1
        khung.layer.borderColor = BangMauBCTD.vienThe.cgColor

        let lb = UILabel()
        lb.text = tieuDe
        lb.font = .systemFont(ofSize: 12.5, weight: .heavy)
        lb.textColor = BangMauBCTD.xanhChuDaoDam
        lb.numberOfLines = 0
        lb.lineBreakMode = .byWordWrapping
        lb.adjustsFontSizeToFitWidth = false

        let ngan = UIStackView(arrangedSubviews: [lb])
        ngan.axis = .vertical
        ngan.spacing = 8
        ngan.translatesAutoresizingMaskIntoConstraints = false
        khung.addSubview(ngan)

        for (ten, sel) in cacNut {
            let nut = UIButton(type: .system)
            nut.setTitle(ten + " ▸", for: .normal)
            nut.titleLabel?.font = .systemFont(ofSize: 13.5, weight: .bold)
            nut.titleLabel?.numberOfLines = 0
            nut.titleLabel?.lineBreakMode = .byWordWrapping
            nut.titleLabel?.textAlignment = .left
            nut.titleLabel?.adjustsFontSizeToFitWidth = false
            nut.contentHorizontalAlignment = .left
            nut.backgroundColor = BangMauBCTD.nenHeaderPhu
            nut.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
            nut.layer.cornerRadius = 9
            nut.layer.borderWidth = 1
            nut.layer.borderColor = BangMauBCTD.vienThe.cgColor
            nut.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
            nut.addTarget(self, action: sel, for: .touchUpInside)
            ngan.addArrangedSubview(nut)
        }

        NSLayoutConstraint.activate([
            ngan.topAnchor.constraint(equalTo: khung.topAnchor, constant: 12),
            ngan.leadingAnchor.constraint(equalTo: khung.leadingAnchor, constant: 12),
            ngan.trailingAnchor.constraint(equalTo: khung.trailingAnchor, constant: -12),
            ngan.bottomAnchor.constraint(equalTo: khung.bottomAnchor, constant: -12)
        ])
        return khung
    }

    @objc private func bamNhapTatCaLuyKe() {
        cheDoDoanhThu = .luyKe
        moChonAnh(cheDo: .tatCaAnhTheoTab(.luyKe), gioiHan: 0)
    }

    @objc private func bamNhapTatCaRealtime() {
        cheDoDoanhThu = .realtime
        moChonAnh(cheDo: .tatCaAnhTheoTab(.realtime), gioiHan: 0)
    }

    @objc private func bamQuetDoanhThuLK() {
        cheDoDoanhThu = .luyKe
        moChonAnh(cheDo: .doanhThu(.luyKe), gioiHan: 2)
    }

    @objc private func bamSuaTayDoanhThuLK() {
        cheDoDoanhThu = .luyKe
        moHopThoaiNhapDoanhThu()
    }

    @objc private func bamQuetThiDuaLK() {
        cheDoDoanhThu = .luyKe
        moHuongDanQuetAnhThiDua(cheDo: .luyKe)
    }

    @objc private func bamQuetDoanhThuNVLK() {
        cheDoDoanhThu = .luyKe
        moChonAnh(cheDo: .doanhThuNhanVien(.luyKe), gioiHan: 0)
    }

    @objc private func bamQuetThiDuaNVLK() {
        cheDoDoanhThu = .luyKe
        moChonAnh(cheDo: .thiDuaNhanVien(.luyKe), gioiHan: 0)
    }

    @objc private func bamQuetDoanhThuRT() {
        cheDoDoanhThu = .realtime
        moChonAnh(cheDo: .doanhThu(.realtime), gioiHan: 2)
    }

    @objc private func bamSuaTayDoanhThuRT() {
        cheDoDoanhThu = .realtime
        moHopThoaiNhapDoanhThu()
    }

    @objc private func bamQuetThiDuaRT() {
        cheDoDoanhThu = .realtime
        moHuongDanQuetAnhThiDua(cheDo: .realtime)
    }

    @objc private func bamQuetDoanhThuNVRT() {
        cheDoDoanhThu = .realtime
        moChonAnh(cheDo: .doanhThuNhanVien(.realtime), gioiHan: 0)
    }

    @objc private func bamQuetThiDuaNVRT() {
        cheDoDoanhThu = .realtime
        moChonAnh(cheDo: .thiDuaNhanVien(.realtime), gioiHan: 0)
    }

    // MARK: - Mục con 3: Giao diện "3. Xuất ảnh" (Chọn loại ảnh -> Ô Text báo cáo -> Nút Xuất ảnh thật & Copy gửi LINE + Excel/PowerPoint)

    private func taoKhungXuatAnh() {
        khungXuatAnh.backgroundColor = BangMauBCTD.nenTrang
        khungXuatAnh.isHidden = true

        let cuon = UIScrollView()
        cuon.alwaysBounceVertical = true
        cuon.keyboardDismissMode = .interactive
        cuon.translatesAutoresizingMaskIntoConstraints = false
        khungXuatAnh.addSubview(cuon)

        let ngan = UIStackView()
        ngan.axis = .vertical
        ngan.spacing = 12
        ngan.translatesAutoresizingMaskIntoConstraints = false
        cuon.addSubview(ngan)

        NSLayoutConstraint.activate([
            cuon.topAnchor.constraint(equalTo: khungXuatAnh.topAnchor),
            cuon.leadingAnchor.constraint(equalTo: khungXuatAnh.leadingAnchor),
            cuon.trailingAnchor.constraint(equalTo: khungXuatAnh.trailingAnchor),
            cuon.bottomAnchor.constraint(equalTo: khungXuatAnh.bottomAnchor),

            ngan.topAnchor.constraint(equalTo: cuon.contentLayoutGuide.topAnchor, constant: 8),
            ngan.leadingAnchor.constraint(equalTo: cuon.frameLayoutGuide.leadingAnchor, constant: 10),
            ngan.trailingAnchor.constraint(equalTo: cuon.frameLayoutGuide.trailingAnchor, constant: -10),
            ngan.bottomAnchor.constraint(equalTo: cuon.contentLayoutGuide.bottomAnchor, constant: -28)
        ])

        // BƯỚC 1: Chọn tùy chọn xuất ảnh gì
        let theChonLoai = UIView()
        theChonLoai.backgroundColor = BangMauBCTD.nenThe
        theChonLoai.layer.cornerRadius = 14
        theChonLoai.layer.borderWidth = 1
        theChonLoai.layer.borderColor = BangMauBCTD.vienThe.cgColor

        let lbBuoc1 = UILabel()
        lbBuoc1.text = "BƯỚC 1 · CHỌN LOẠI BÁO CÁO MUỐN XUẤT ẢNH (Ấn chọn để tạo nội dung chữ bên dưới)"
        lbBuoc1.font = .systemFont(ofSize: 12.5, weight: .heavy)
        lbBuoc1.textColor = BangMauBCTD.mauChuTieuDePhanTich
        lbBuoc1.numberOfLines = 0
        lbBuoc1.lineBreakMode = .byWordWrapping
        lbBuoc1.adjustsFontSizeToFitWidth = false

        let nganLuoiLoai = UIStackView(arrangedSubviews: [lbBuoc1])
        nganLuoiLoai.axis = .vertical
        nganLuoiLoai.spacing = 8
        nganLuoiLoai.translatesAutoresizingMaskIntoConstraints = false
        theChonLoai.addSubview(nganLuoiLoai)

        cacNutLoaiXuatAnh.removeAll()
        let tatCaLoai = LoaiBaoCaoXuatAnh.allCases
        var hangHienTai: UIStackView?
        for (i, loai) in tatCaLoai.enumerated() {
            if i % 2 == 0 {
                let h = UIStackView()
                h.axis = .horizontal
                h.spacing = 8
                h.distribution = .fillEqually
                nganLuoiLoai.addArrangedSubview(h)
                hangHienTai = h
            }
            let nut = UIButton(type: .custom)
            nut.tag = loai.rawValue
            nut.setTitle(loai.tieuDeNgan, for: .normal)
            nut.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
            nut.titleLabel?.numberOfLines = 0
            nut.titleLabel?.lineBreakMode = .byWordWrapping
            nut.titleLabel?.textAlignment = .center
            nut.titleLabel?.adjustsFontSizeToFitWidth = false
            nut.layer.cornerRadius = 10
            nut.layer.borderWidth = 1.2
            nut.contentEdgeInsets = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
            nut.addTarget(self, action: #selector(bamChonLoaiBaoCaoXuatAnh(_:)), for: .touchUpInside)
            cacNutLoaiXuatAnh.append(nut)
            hangHienTai?.addArrangedSubview(nut)
        }

        NSLayoutConstraint.activate([
            nganLuoiLoai.topAnchor.constraint(equalTo: theChonLoai.topAnchor, constant: 12),
            nganLuoiLoai.leadingAnchor.constraint(equalTo: theChonLoai.leadingAnchor, constant: 12),
            nganLuoiLoai.trailingAnchor.constraint(equalTo: theChonLoai.trailingAnchor, constant: -12),
            nganLuoiLoai.bottomAnchor.constraint(equalTo: theChonLoai.bottomAnchor, constant: -12)
        ])
        ngan.addArrangedSubview(theChonLoai)

        // BƯỚC 2: Ô Text chứa nội dung báo cáo về phần đó (sửa được + có AI Gemini)
        let theVanBan = UIView()
        theVanBan.backgroundColor = BangMauBCTD.nenThe
        theVanBan.layer.cornerRadius = 14
        theVanBan.layer.borderWidth = 1
        theVanBan.layer.borderColor = BangMauBCTD.vienThe.cgColor

        let lbBuoc2 = UILabel()
        lbBuoc2.text = "BƯỚC 2 · NỘI DUNG BÁO CÁO (Tự động Copy khi bấm Xuất ảnh thật)"
        lbBuoc2.font = .systemFont(ofSize: 12.5, weight: .heavy)
        lbBuoc2.textColor = BangMauBCTD.mauChuTieuDePhanTich
        lbBuoc2.numberOfLines = 0
        lbBuoc2.lineBreakMode = .byWordWrapping
        lbBuoc2.adjustsFontSizeToFitWidth = false

        nutAIGeminiXuatAnh.setTitle("✨ AI Gemini viết", for: .normal)
        nutAIGeminiXuatAnh.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        nutAIGeminiXuatAnh.titleLabel?.numberOfLines = 0
        nutAIGeminiXuatAnh.titleLabel?.lineBreakMode = .byWordWrapping
        nutAIGeminiXuatAnh.titleLabel?.adjustsFontSizeToFitWidth = false
        nutAIGeminiXuatAnh.backgroundColor = BangMauBCTD.nenHeaderBang
        nutAIGeminiXuatAnh.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
        nutAIGeminiXuatAnh.layer.cornerRadius = 8
        nutAIGeminiXuatAnh.layer.borderWidth = 1
        nutAIGeminiXuatAnh.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
        nutAIGeminiXuatAnh.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        nutAIGeminiXuatAnh.setContentHuggingPriority(.required, for: .horizontal)
        nutAIGeminiXuatAnh.addTarget(self, action: #selector(bamAIGeminiTrongXuatAnh), for: .touchUpInside)

        let nutTaoLaiMau = UIButton(type: .system)
        nutTaoLaiMau.setTitle("🔄 Tạo lại", for: .normal)
        nutTaoLaiMau.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .semibold)
        nutTaoLaiMau.titleLabel?.numberOfLines = 0
        nutTaoLaiMau.titleLabel?.lineBreakMode = .byWordWrapping
        nutTaoLaiMau.titleLabel?.adjustsFontSizeToFitWidth = false
        nutTaoLaiMau.backgroundColor = BangMauBCTD.nenThePhu
        nutTaoLaiMau.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
        nutTaoLaiMau.layer.cornerRadius = 8
        nutTaoLaiMau.layer.borderWidth = 1
        nutTaoLaiMau.layer.borderColor = BangMauBCTD.vienDam.cgColor
        nutTaoLaiMau.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        nutTaoLaiMau.setContentHuggingPriority(.required, for: .horizontal)
        nutTaoLaiMau.addTarget(self, action: #selector(bamTaoLaiMauXuatAnh), for: .touchUpInside)

        let hangTrenVB = UIStackView(arrangedSubviews: [lbBuoc2, nutAIGeminiXuatAnh, nutTaoLaiMau])
        hangTrenVB.axis = .horizontal
        hangTrenVB.spacing = 6
        hangTrenVB.alignment = .center

        // Hàng chọn giọng văn trong Xuất ảnh
        let hangGiongXA = UIStackView()
        hangGiongXA.axis = .horizontal
        hangGiongXA.spacing = 6
        hangGiongXA.distribution = .fillEqually
        cacNutGiongXuatAnh.removeAll()
        for giong in GiongVanBanTin.allCases {
            let nut = UIButton(type: .custom)
            nut.tag = giong.rawValue
            nut.setTitle("Giọng: \(giong.tieuDe)", for: .normal)
            nut.titleLabel?.font = .systemFont(ofSize: 12.0, weight: .bold)
            nut.titleLabel?.numberOfLines = 0
            nut.titleLabel?.lineBreakMode = .byWordWrapping
            nut.titleLabel?.textAlignment = .center
            nut.titleLabel?.adjustsFontSizeToFitWidth = false
            nut.layer.cornerRadius = 8
            nut.layer.borderWidth = 1
            nut.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
            nut.addTarget(self, action: #selector(bamDoiGiongTrongXuatAnh(_:)), for: .touchUpInside)
            cacNutGiongXuatAnh.append(nut)
            hangGiongXA.addArrangedSubview(nut)
        }

        oVanBanXuatAnh.font = .systemFont(ofSize: 14.5, weight: .regular)
        oVanBanXuatAnh.textColor = BangMauBCTD.chuChinh
        oVanBanXuatAnh.backgroundColor = BangMauBCTD.nenThePhu
        oVanBanXuatAnh.layer.cornerRadius = 10
        oVanBanXuatAnh.layer.borderWidth = 1
        oVanBanXuatAnh.layer.borderColor = BangMauBCTD.vienDam.cgColor
        oVanBanXuatAnh.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        oVanBanXuatAnh.isScrollEnabled = false
        oVanBanXuatAnh.delegate = self
        oVanBanXuatAnh.translatesAutoresizingMaskIntoConstraints = false
        oVanBanXuatAnh.heightAnchor.constraint(greaterThanOrEqualToConstant: 210).isActive = true

        nhanTrangThaiXuatAnh.text = "💡 Khi ấn nút "XUẤT ẢNH THẬT & COPY NỘI DUNG GỬI LINE" bên dưới, ứng dụng sẽ tự động Copy nội dung ô chữ này và mở hộp thoại chia sẻ ảnh qua LINE."
        nhanTrangThaiXuatAnh.font = .systemFont(ofSize: 12.5, weight: .medium)
        nhanTrangThaiXuatAnh.textColor = BangMauBCTD.chuPhu
        nhanTrangThaiXuatAnh.numberOfLines = 0
        nhanTrangThaiXuatAnh.lineBreakMode = .byWordWrapping
        nhanTrangThaiXuatAnh.adjustsFontSizeToFitWidth = false

        // BƯỚC 3: Nút Xuất ảnh thật + Copy gửi LINE & Nút xuất Excel (.xlsx) / PowerPoint (.pptx)
        let nutXuatAnhThat = UIButton(type: .system)
        nutXuatAnhThat.setTitle("📤 XUẤT ẢNH THẬT & COPY NỘI DUNG GỬI LINE", for: .normal)
        nutXuatAnhThat.titleLabel?.font = .systemFont(ofSize: 15.0, weight: .heavy)
        nutXuatAnhThat.titleLabel?.numberOfLines = 0
        nutXuatAnhThat.titleLabel?.lineBreakMode = .byWordWrapping
        nutXuatAnhThat.titleLabel?.textAlignment = .center
        nutXuatAnhThat.titleLabel?.adjustsFontSizeToFitWidth = false
        nutXuatAnhThat.backgroundColor = BangMauBCTD.xanhDatVach
        nutXuatAnhThat.setTitleColor(.white, for: .normal)
        nutXuatAnhThat.layer.cornerRadius = 12
        nutXuatAnhThat.contentEdgeInsets = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        nutXuatAnhThat.addTarget(self, action: #selector(bamXuatAnhThatVaCopyLine), for: .touchUpInside)

        let nutCopyRieng = UIButton(type: .system)
        nutCopyRieng.setTitle("📋 Chỉ Copy nội dung trong ô Text", for: .normal)
        nutCopyRieng.titleLabel?.font = .systemFont(ofSize: 13.5, weight: .bold)
        nutCopyRieng.titleLabel?.numberOfLines = 0
        nutCopyRieng.titleLabel?.lineBreakMode = .byWordWrapping
        nutCopyRieng.titleLabel?.textAlignment = .center
        nutCopyRieng.titleLabel?.adjustsFontSizeToFitWidth = false
        nutCopyRieng.backgroundColor = BangMauBCTD.nenHeaderPhu
        nutCopyRieng.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
        nutCopyRieng.layer.cornerRadius = 10
        nutCopyRieng.layer.borderWidth = 1
        nutCopyRieng.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
        nutCopyRieng.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        nutCopyRieng.addTarget(self, action: #selector(bamChiCopyNoiDungXuatAnh), for: .touchUpInside)

        let nutXuatExcel = UIButton(type: .system)
        nutXuatExcel.setTitle("📗 Xuất file Excel (.xlsx)", for: .normal)
        nutXuatExcel.titleLabel?.font = .systemFont(ofSize: 13.5, weight: .bold)
        nutXuatExcel.titleLabel?.numberOfLines = 0
        nutXuatExcel.titleLabel?.lineBreakMode = .byWordWrapping
        nutXuatExcel.titleLabel?.textAlignment = .center
        nutXuatExcel.titleLabel?.adjustsFontSizeToFitWidth = false
        nutXuatExcel.backgroundColor = BangMauBCTD.xanhChuDao
        nutXuatExcel.setTitleColor(.white, for: .normal)
        nutXuatExcel.layer.cornerRadius = 10
        nutXuatExcel.contentEdgeInsets = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        nutXuatExcel.addTarget(self, action: #selector(bamXuatExcelTuMucXuatAnh), for: .touchUpInside)

        let nutXuatPPTX = UIButton(type: .system)
        nutXuatPPTX.setTitle("📙 Xuất PowerPoint (.pptx)", for: .normal)
        nutXuatPPTX.titleLabel?.font = .systemFont(ofSize: 13.5, weight: .bold)
        nutXuatPPTX.titleLabel?.numberOfLines = 0
        nutXuatPPTX.titleLabel?.lineBreakMode = .byWordWrapping
        nutXuatPPTX.titleLabel?.textAlignment = .center
        nutXuatPPTX.titleLabel?.adjustsFontSizeToFitWidth = false
        nutXuatPPTX.backgroundColor = BangMauBCTD.vangKhaChu
        nutXuatPPTX.setTitleColor(.white, for: .normal)
        nutXuatPPTX.layer.cornerRadius = 10
        nutXuatPPTX.contentEdgeInsets = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        nutXuatPPTX.addTarget(self, action: #selector(bamXuatPowerPointTuMucXuatAnh), for: .touchUpInside)

        let hangOffice = UIStackView(arrangedSubviews: [nutXuatExcel, nutXuatPPTX])
        hangOffice.axis = .horizontal
        hangOffice.spacing = 8
        hangOffice.distribution = .fillEqually

        let nganVB = UIStackView(arrangedSubviews: [
            hangTrenVB,
            hangGiongXA,
            oVanBanXuatAnh,
            nhanTrangThaiXuatAnh,
            nutXuatAnhThat,
            hangOffice,
            nutCopyRieng
        ])
        nganVB.axis = .vertical
        nganVB.spacing = 10
        nganVB.translatesAutoresizingMaskIntoConstraints = false
        theVanBan.addSubview(nganVB)

        NSLayoutConstraint.activate([
            nganVB.topAnchor.constraint(equalTo: theVanBan.topAnchor, constant: 12),
            nganVB.leadingAnchor.constraint(equalTo: theVanBan.leadingAnchor, constant: 12),
            nganVB.trailingAnchor.constraint(equalTo: theVanBan.trailingAnchor, constant: -12),
            nganVB.bottomAnchor.constraint(equalTo: theVanBan.bottomAnchor, constant: -12)
        ])
        ngan.addArrangedSubview(theVanBan)
    }

    private func capNhatGiaoDienKhungXuatAnh(taoMoiVanBan: Bool) {
        for nut in cacNutLoaiXuatAnh {
            let dangChon = (nut.tag == loaiXuatAnhDangChon.rawValue)
            if dangChon {
                nut.backgroundColor = BangMauBCTD.vangSang
                nut.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
                nut.layer.borderColor = BangMauBCTD.vangChuDao.cgColor
            } else {
                nut.backgroundColor = BangMauBCTD.nenHeaderPhu
                nut.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
                nut.layer.borderColor = BangMauBCTD.vienThe.cgColor
            }
        }

        for nut in cacNutGiongXuatAnh {
            let dangChon = (nut.tag == giongXuatAnhDangChon.rawValue)
            if dangChon {
                nut.backgroundColor = BangMauBCTD.vangSang
                nut.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
                nut.layer.borderColor = BangMauBCTD.vangChuDao.cgColor
            } else {
                nut.backgroundColor = BangMauBCTD.nenThePhu
                nut.setTitleColor(BangMauBCTD.chuPhu, for: .normal)
                nut.layer.borderColor = BangMauBCTD.vienDam.cgColor
            }
        }

        if taoMoiVanBan || (oVanBanXuatAnh.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let noiDung = BoVietBanTin.taoNoiDungBaoCao(
                loai: loaiXuatAnhDangChon,
                ngay: ngayHienTai,
                giong: giongXuatAnhDangChon
            )
            oVanBanXuatAnh.attributedText = ManHinhBanTin.dinhDangVanBanCoInDam(noiDung)
            oVanBanXuatAnh.invalidateIntrinsicContentSize()
        }
    }

    @objc private func bamChonLoaiBaoCaoXuatAnh(_ sender: UIButton) {
        guard let loai = LoaiBaoCaoXuatAnh(rawValue: sender.tag) else { return }
        loaiXuatAnhDangChon = loai
        capNhatGiaoDienKhungXuatAnh(taoMoiVanBan: true)
        nhanTrangThaiXuatAnh.text = "✅ Đã nạp nội dung báo cáo cho phần "\(loai.tieuDeNgan)". Bạn có thể sửa chữ rồi bấm nút XUẤT ẢNH THẬT bên dưới."
        nhanTrangThaiXuatAnh.textColor = BangMauBCTD.xanhChuDaoDam
    }

    @objc private func bamDoiGiongTrongXuatAnh(_ sender: UIButton) {
        guard let giong = GiongVanBanTin(rawValue: sender.tag) else { return }
        giongXuatAnhDangChon = giong
        capNhatGiaoDienKhungXuatAnh(taoMoiVanBan: true)
    }

    @objc private func bamTaoLaiMauXuatAnh() {
        view.endEditing(true)
        capNhatGiaoDienKhungXuatAnh(taoMoiVanBan: true)
    }

    @objc private func bamAIGeminiTrongXuatAnh() {
        view.endEditing(true)
        let s = KhoDuLieu.dungChung.taoSoLieuBanTin(cho: ngayHienTai, khung: KhungBanTin.theoGio())
        nutAIGeminiXuatAnh.isEnabled = false
        nutAIGeminiXuatAnh.setTitle("⏳ Đang viết...", for: .normal)
        nhanTrangThaiXuatAnh.text = "🤖 Đang kết nối Google Gemini (\(DichVuGeminiAI.dungChung.modelHienTai)) để phân tích phần "\(loaiXuatAnhDangChon.tieuDeNgan)"..."
        nhanTrangThaiXuatAnh.textColor = BangMauBCTD.xanhChuDao

        DichVuGeminiAI.dungChung.phanTichBaoCao(
            soLieu: s,
            giong: giongXuatAnhDangChon,
            loaiBaoCao: loaiXuatAnhDangChon
        ) { [weak self] kq in
            guard let self = self else { return }
            self.nutAIGeminiXuatAnh.isEnabled = true
            self.nutAIGeminiXuatAnh.setTitle("✨ AI Gemini viết", for: .normal)
            switch kq {
            case .success(let baiAI):
                self.oVanBanXuatAnh.attributedText = ManHinhBanTin.dinhDangVanBanCoInDam(baiAI)
                self.oVanBanXuatAnh.invalidateIntrinsicContentSize()
                self.nhanTrangThaiXuatAnh.text = "✨ Đã tạo nội dung bằng Google Gemini AI (\(DichVuGeminiAI.dungChung.modelHienTai))! Ấn nút XUẤT ẢNH THẬT bên dưới để lưu/chia sẻ."
                self.nhanTrangThaiXuatAnh.textColor = BangMauBCTD.xanhLaDam
            case .failure(let loi):
                let mau = BoVietBanTin.taoNoiDungBaoCao(loai: self.loaiXuatAnhDangChon, ngay: self.ngayHienTai, giong: self.giongXuatAnhDangChon)
                self.oVanBanXuatAnh.attributedText = ManHinhBanTin.dinhDangVanBanCoInDam(mau)
                self.oVanBanXuatAnh.invalidateIntrinsicContentSize()
                self.nhanTrangThaiXuatAnh.text = "ℹ️ Đã tạo nội dung theo mẫu chuẩn (Gemini phản hồi: \(loi.localizedDescription))"
                self.nhanTrangThaiXuatAnh.textColor = BangMauBCTD.vangKhaChu
            }
        }
    }

    @objc private func bamChiCopyNoiDungXuatAnh() {
        view.endEditing(true)
        let text = oVanBanXuatAnh.text ?? ""
        UIPasteboard.general.string = text
        nhanTrangThaiXuatAnh.text = "✅ Đã sao chép nội dung trong ô văn bản vào bộ nhớ tạm!"
        nhanTrangThaiXuatAnh.textColor = BangMauBCTD.xanhLaDam
    }

    @objc private func bamXuatAnhThatVaCopyLine() {
        view.endEditing(true)
        let noiDungText = oVanBanXuatAnh.text ?? ""
        UIPasteboard.general.string = noiDungText

        guard let anh = taoAnhTheoLoaiBaoCao(loaiXuatAnhDangChon) else {
            nhanTrangThaiXuatAnh.text = "⚠️ Chưa có dữ liệu bảng của phần "\(loaiXuatAnhDangChon.tieuDeNgan)" để vẽ ảnh (Đã copy sẵn nội dung chữ)."
            nhanTrangThaiXuatAnh.textColor = BangMauBCTD.doYeuChu
            return
        }

        nhanTrangThaiXuatAnh.text = "✅ ĐÃ COPY NỘI DUNG Ô TEXT! Hãy chọn LINE (hoặc Lưu hình ảnh) trên hộp thoại rồi Dán (Paste) nội dung kèm ảnh."
        nhanTrangThaiXuatAnh.textColor = BangMauBCTD.xanhLaDam
        chiaSe([anh])
    }

    private func taoAnhTheoLoaiBaoCao(_ loai: LoaiBaoCaoXuatAnh) -> UIImage? {
        let dl = KhoDuLieu.dungChung.duLieu(cho: ngayHienTai)
        switch loai {
        case .doanhThuThiDuaLuyKe:
            return bangThiDua.taoAnhBaoCao(
                ngay: ngayHienTai,
                doanhThu: dl.doanhThu,
                danhSach: dl.danhSachThiDua,
                cheDoDoanhThu: .luyKe,
                xemDuKien: false,
                thongTinDonVi: dl.thongTinDonVi,
                capNhatLuc: dl.capNhatLuc
            )
        case .luyKeDuKien:
            return bangThiDua.taoAnhBaoCao(
                ngay: ngayHienTai,
                doanhThu: dl.doanhThu,
                danhSach: dl.danhSachThiDua,
                cheDoDoanhThu: .luyKe,
                xemDuKien: true,
                thongTinDonVi: dl.thongTinDonVi,
                capNhatLuc: dl.capNhatLuc
            )
        case .doanhThuThiDuaRealtime:
            return bangThiDua.taoAnhBaoCao(
                ngay: ngayHienTai,
                doanhThu: dl.doanhThuRealtime,
                danhSach: dl.danhSachThiDuaRealtime,
                cheDoDoanhThu: .realtime,
                xemDuKien: false,
                thongTinDonVi: dl.thongTinDonVi,
                capNhatLuc: dl.capNhatLuc
            )
        case .xepHangNVLuyKe:
            bangNhanVien.capNhat(cho: ngayHienTai, cheDo: .luyKe)
            return bangNhanVien.taoAnhBaoCaoNhanVien(
                ngay: ngayHienTai,
                cheDo: .luyKe,
                thongTinDonVi: dl.thongTinDonVi,
                capNhatLuc: dl.capNhatLuc
            )
        case .xepHangNVRealtime:
            bangNhanVien.capNhat(cho: ngayHienTai, cheDo: .realtime)
            return bangNhanVien.taoAnhBaoCaoNhanVien(
                ngay: ngayHienTai,
                cheDo: .realtime,
                thongTinDonVi: dl.thongTinDonVi,
                capNhatLuc: dl.capNhatLuc
            )
        case .bieuDoSucKhoeNV:
            return bangRealtimeThang.taoAnhBaoCaoSucKhoeNhanVien(
                ngay: ngayHienTai,
                thongTinDonVi: dl.thongTinDonVi,
                capNhatLuc: dl.capNhatLuc
            )
        case .bieuDoRealtimeThang:
            return bangRealtimeThang.taoAnhBaoCaoRealtimeThang(
                ngay: ngayHienTai,
                thongTinDonVi: dl.thongTinDonVi,
                capNhatLuc: dl.capNhatLuc
            )
        case .chiTiet16NV:
            return ManHinhChiTietNhanVien.taoAnhGopTatCaSucKhoe(cho: ngayHienTai, cheDo: .luyKe)
        }
    }

    @objc private func bamXuatExcelTuMucXuatAnh() {
        view.endEditing(true)
        let noiDung = oVanBanXuatAnh.text ?? ""
        UIPasteboard.general.string = noiDung
        guard let url = BoXuatOfficeDMX.xuatFileExcelXLSX(ngay: ngayHienTai, noiDungPhanTich: noiDung) else { return }
        nhanTrangThaiXuatAnh.text = "📗 Đã xuất file Excel (.xlsx) gồm 4 Sheet & copy sẵn nội dung báo cáo!"
        nhanTrangThaiXuatAnh.textColor = BangMauBCTD.xanhLaDam
        chiaSe([url])
    }

    @objc private func bamXuatPowerPointTuMucXuatAnh() {
        view.endEditing(true)
        let noiDung = oVanBanXuatAnh.text ?? ""
        UIPasteboard.general.string = noiDung
        guard let url = BoXuatOfficeDMX.xuatFilePowerPointPPTX(ngay: ngayHienTai, noiDungPhanTich: noiDung) else { return }
        nhanTrangThaiXuatAnh.text = "📙 Đã xuất file PowerPoint (.pptx) gồm 4 Slide & copy sẵn nội dung báo cáo!"
        nhanTrangThaiXuatAnh.textColor = BangMauBCTD.xanhLaDam
        chiaSe([url])
    }

    @objc private func bamChonMucConTrenThanh(_ sender: UIButton) {
        guard let mucCon = MucConDoSo(rawValue: sender.tag) else { return }
        mucMenuChinh = .doSoXemSo
        mucConDoSo = mucCon
        napDuLieu()
    }

    @objc private func bamChonTabXemSo(_ sender: UIButton) {
        guard let tab = TabXemSo(rawValue: sender.tag) else { return }
        mucMenuChinh = .doSoXemSo
        mucConDoSo = .xemSo
        tabXemSo = tab
        if tab == .luyKe {
            cheDoDoanhThu = .luyKe
        } else if tab == .realtime {
            cheDoDoanhThu = .realtime
        }
        napDuLieu()
    }

    private func cauHinhNutCheDoNV(_ nut: UIButton, tieuDe: String, tag: Int) {
        nut.tag = tag
        nut.setTitle(tieuDe, for: .normal)
        nut.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        nut.titleLabel?.numberOfLines = 0
        nut.titleLabel?.lineBreakMode = .byWordWrapping
        nut.titleLabel?.textAlignment = .center
        nut.titleLabel?.adjustsFontSizeToFitWidth = false
        nut.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        nut.layer.cornerRadius = 9
        nut.layer.borderWidth = 1
        nut.addTarget(self, action: #selector(bamChonCheDoNV(_:)), for: .touchUpInside)
    }

    @objc private func bamChonCheDoNV(_ sender: UIButton) {
        guard let moi = LoaiCheDoDoanhThu(rawValue: sender.tag), moi != cheDoDoanhThu else { return }
        cheDoDoanhThu = moi
        napDuLieu()
    }

    // MARK: - Khung nội dung Tổng quan, Báo cáo AI, Cài đặt, Quản trị và các mục mở rộng

    private func taoKhungTongQuan() {
        khungTongQuan.backgroundColor = BangMauBCTD.nenTrang
        khungTongQuan.isHidden = true
        khungTongQuan.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(khungTongQuan)

        let cuon = UIScrollView()
        cuon.alwaysBounceVertical = true
        cuon.translatesAutoresizingMaskIntoConstraints = false
        khungTongQuan.addSubview(cuon)

        let ngan = UIStackView()
        ngan.axis = .vertical
        ngan.spacing = 10
        ngan.translatesAutoresizingMaskIntoConstraints = false
        cuon.addSubview(ngan)

        let theChao = UIView()
        theChao.backgroundColor = BangMauBCTD.xanhChuDao
        theChao.layer.cornerRadius = 12
        theChao.clipsToBounds = true

        let vachVangChao = UIView()
        vachVangChao.backgroundColor = BangMauBCTD.vangSang
        vachVangChao.translatesAutoresizingMaskIntoConstraints = false
        theChao.addSubview(vachVangChao)

        let lbKickerChao = UILabel()
        lbKickerChao.text = "BÁO CÁO THI ĐUA · TỔNG QUAN SIÊU THỊ"
        lbKickerChao.font = .systemFont(ofSize: 11.5, weight: .heavy)
        lbKickerChao.textColor = BangMauBCTD.vangSang
        lbKickerChao.numberOfLines = 0
        lbKickerChao.lineBreakMode = .byWordWrapping
        lbKickerChao.adjustsFontSizeToFitWidth = false
        lbKickerChao.translatesAutoresizingMaskIntoConstraints = false
        theChao.addSubview(lbKickerChao)

        nhanTomTatTongQuan.font = .systemFont(ofSize: 13.5, weight: .semibold)
        nhanTomTatTongQuan.textColor = .white
        nhanTomTatTongQuan.numberOfLines = 0
        nhanTomTatTongQuan.lineBreakMode = .byWordWrapping
        nhanTomTatTongQuan.adjustsFontSizeToFitWidth = false
        nhanTomTatTongQuan.translatesAutoresizingMaskIntoConstraints = false
        theChao.addSubview(nhanTomTatTongQuan)

        let nhanHuongDan = UILabel()
        nhanHuongDan.text = "TRUY CẬP NHANH BÁO CÁO AI · XEM SỐ · NHẬP SỐ · XUẤT ẢNH & CÀI ĐẶT"
        nhanHuongDan.font = .systemFont(ofSize: 11.5, weight: .bold)
        nhanHuongDan.textColor = BangMauBCTD.chuPhu
        nhanHuongDan.numberOfLines = 0
        nhanHuongDan.lineBreakMode = .byWordWrapping
        nhanHuongDan.adjustsFontSizeToFitWidth = false

        let nutMoBaoCao = taoNutLoiTatTongQuan(
            tieuDe: "📰 Báo cáo & Phân tích AI Gemini (Gửi LINE)",
            moTa: "Tạo bản tin báo cáo 5 mục theo mẫu chuẩn bằng AI Gemini, chọn giọng văn & gửi LINE",
            mau: BangMauBCTD.vangChuDao,
            tag: 100
        )
        let nutMoXemSo = taoNutLoiTatTongQuan(
            tieuDe: "👁️ 1. Xem số (Lũy kế · Realtime · Biểu đồ · Nhân viên)",
            moTa: "Xem bảng thi đua Lũy kế, Realtime, Biểu đồ sức khỏe 16 NV & Bảng xếp hạng NV",
            mau: BangMauBCTD.xanhChuDao,
            tag: 101
        )
        let nutMoNhapSo = taoNutLoiTatTongQuan(
            tieuDe: "📥 2. Nhập số (Nhập tất cả Lũy kế & Nhập tất cả Realtime)",
            moTa: "Mở bảng nhập dữ liệu nhanh: quét tất cả ảnh Lũy kế, tất cả ảnh Realtime hoặc nhập tay",
            mau: BangMauBCTD.xanhDatVach,
            tag: 102
        )
        let nutMoXuatAnh = taoNutLoiTatTongQuan(
            tieuDe: "🖼️ 3. Xuất ảnh & Xuất file Excel / PowerPoint",
            moTa: "Chọn loại ảnh cần xuất, xem/sửa ô Text báo cáo, tự động Copy nội dung kèm ảnh gửi LINE",
            mau: BangMauBCTD.xanhBienChuDao,
            tag: 103
        )
        let nutMoCaiDat = taoNutLoiTatTongQuan(
            tieuDe: "⚙️ Cài đặt & Google Gemini API Key (Miễn phí)",
            moTa: "Nhập & kiểm tra Key Google Gemini miễn phí, Chia Target mặt hàng, Quản lý danh sách NV",
            mau: BangMauBCTD.indigoDam,
            tag: 105
        )

        [theChao, nhanHuongDan, nutMoBaoCao, nutMoXemSo, nutMoNhapSo, nutMoXuatAnh, nutMoCaiDat].forEach {
            ngan.addArrangedSubview($0)
        }

        NSLayoutConstraint.activate([
            khungTongQuan.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            khungTongQuan.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            khungTongQuan.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            khungTongQuan.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            cuon.topAnchor.constraint(equalTo: khungTongQuan.topAnchor),
            cuon.leadingAnchor.constraint(equalTo: khungTongQuan.leadingAnchor),
            cuon.trailingAnchor.constraint(equalTo: khungTongQuan.trailingAnchor),
            cuon.bottomAnchor.constraint(equalTo: khungTongQuan.bottomAnchor),

            ngan.topAnchor.constraint(equalTo: cuon.contentLayoutGuide.topAnchor, constant: 12),
            ngan.leadingAnchor.constraint(equalTo: cuon.contentLayoutGuide.leadingAnchor, constant: 12),
            ngan.trailingAnchor.constraint(equalTo: cuon.contentLayoutGuide.trailingAnchor, constant: -12),
            ngan.bottomAnchor.constraint(equalTo: cuon.contentLayoutGuide.bottomAnchor, constant: -16),
            ngan.widthAnchor.constraint(equalTo: cuon.frameLayoutGuide.widthAnchor, constant: -24),

            vachVangChao.topAnchor.constraint(equalTo: theChao.topAnchor),
            vachVangChao.bottomAnchor.constraint(equalTo: theChao.bottomAnchor),
            vachVangChao.leadingAnchor.constraint(equalTo: theChao.leadingAnchor),
            vachVangChao.widthAnchor.constraint(equalToConstant: 5),

            lbKickerChao.topAnchor.constraint(equalTo: theChao.topAnchor, constant: 12),
            lbKickerChao.leadingAnchor.constraint(equalTo: vachVangChao.trailingAnchor, constant: 12),
            lbKickerChao.trailingAnchor.constraint(equalTo: theChao.trailingAnchor, constant: -14),

            nhanTomTatTongQuan.topAnchor.constraint(equalTo: lbKickerChao.bottomAnchor, constant: 6),
            nhanTomTatTongQuan.leadingAnchor.constraint(equalTo: vachVangChao.trailingAnchor, constant: 12),
            nhanTomTatTongQuan.trailingAnchor.constraint(equalTo: theChao.trailingAnchor, constant: -14),
            nhanTomTatTongQuan.bottomAnchor.constraint(equalTo: theChao.bottomAnchor, constant: -14)
        ])
    }

    private func taoNutLoiTatTongQuan(tieuDe: String, moTa: String, mau: UIColor, tag: Int) -> UIControl {
        let the = UIControl()
        the.tag = tag
        the.backgroundColor = BangMauBCTD.nenThe
        the.layer.cornerRadius = 11
        the.layer.borderWidth = 1
        the.layer.borderColor = BangMauBCTD.vienThe.cgColor
        the.clipsToBounds = true
        the.addTarget(self, action: #selector(bamLoiTatTongQuan(_:)), for: .touchUpInside)

        let vachTrai = UIView()
        vachTrai.backgroundColor = mau
        vachTrai.isUserInteractionEnabled = false
        vachTrai.translatesAutoresizingMaskIntoConstraints = false
        the.addSubview(vachTrai)

        let lbChinh = UILabel()
        lbChinh.text = tieuDe
        lbChinh.font = .systemFont(ofSize: 14.5, weight: .bold)
        lbChinh.textColor = BangMauBCTD.chuChinh
        lbChinh.numberOfLines = 0
        lbChinh.lineBreakMode = .byWordWrapping
        lbChinh.adjustsFontSizeToFitWidth = false
        lbChinh.isUserInteractionEnabled = false
        lbChinh.translatesAutoresizingMaskIntoConstraints = false

        let lbPhu = UILabel()
        lbPhu.text = moTa
        lbPhu.font = .systemFont(ofSize: 12.5, weight: .medium)
        lbPhu.textColor = BangMauBCTD.chuMo
        lbPhu.numberOfLines = 0
        lbPhu.lineBreakMode = .byWordWrapping
        lbPhu.adjustsFontSizeToFitWidth = false
        lbPhu.isUserInteractionEnabled = false
        lbPhu.translatesAutoresizingMaskIntoConstraints = false

        the.addSubview(lbChinh)
        the.addSubview(lbPhu)

        NSLayoutConstraint.activate([
            vachTrai.topAnchor.constraint(equalTo: the.topAnchor),
            vachTrai.bottomAnchor.constraint(equalTo: the.bottomAnchor),
            vachTrai.leadingAnchor.constraint(equalTo: the.leadingAnchor),
            vachTrai.widthAnchor.constraint(equalToConstant: 4.5),

            lbChinh.topAnchor.constraint(equalTo: the.topAnchor, constant: 12),
            lbChinh.leadingAnchor.constraint(equalTo: vachTrai.trailingAnchor, constant: 12),
            lbChinh.trailingAnchor.constraint(equalTo: the.trailingAnchor, constant: -14),

            lbPhu.topAnchor.constraint(equalTo: lbChinh.bottomAnchor, constant: 4),
            lbPhu.leadingAnchor.constraint(equalTo: vachTrai.trailingAnchor, constant: 12),
            lbPhu.trailingAnchor.constraint(equalTo: the.trailingAnchor, constant: -14),
            lbPhu.bottomAnchor.constraint(equalTo: the.bottomAnchor, constant: -12)
        ])
        return the
    }

    @objc private func bamLoiTatTongQuan(_ sender: UIControl) {
        switch sender.tag {
        case 100:
            mucMenuChinh = .baoCao
        case 101:
            mucMenuChinh = .doSoXemSo
            mucConDoSo = .xemSo
        case 102:
            mucMenuChinh = .doSoXemSo
            mucConDoSo = .nhapSo
        case 103:
            mucMenuChinh = .doSoXemSo
            mucConDoSo = .xuatAnh
        case 105:
            mucMenuChinh = .caiDat
        default:
            break
        }
        napDuLieu()
    }

    private func taoKhungBaoCao() {
        khungBaoCao.backgroundColor = BangMauBCTD.nenTrang
        khungBaoCao.isHidden = true
        khungBaoCao.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(khungBaoCao)

        addChild(manHinhBanTinNhung)
        manHinhBanTinNhung.view.translatesAutoresizingMaskIntoConstraints = false
        khungBaoCao.addSubview(manHinhBanTinNhung.view)
        manHinhBanTinNhung.didMove(toParent: self)

        NSLayoutConstraint.activate([
            khungBaoCao.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            khungBaoCao.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            khungBaoCao.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            khungBaoCao.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            manHinhBanTinNhung.view.topAnchor.constraint(equalTo: khungBaoCao.topAnchor),
            manHinhBanTinNhung.view.leadingAnchor.constraint(equalTo: khungBaoCao.leadingAnchor),
            manHinhBanTinNhung.view.trailingAnchor.constraint(equalTo: khungBaoCao.trailingAnchor),
            manHinhBanTinNhung.view.bottomAnchor.constraint(equalTo: khungBaoCao.bottomAnchor)
        ])
    }

    private func taoKhungTaiKhoanHopThu() {
        khungTaiKhoanHopThu.backgroundColor = BangMauBCTD.nenTrang
        khungTaiKhoanHopThu.isHidden = true
        khungTaiKhoanHopThu.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(khungTaiKhoanHopThu)

        addChild(manHinhCaiDatNhung)
        manHinhCaiDatNhung.view.translatesAutoresizingMaskIntoConstraints = false
        khungTaiKhoanHopThu.addSubview(manHinhCaiDatNhung.view)
        manHinhCaiDatNhung.didMove(toParent: self)
        manHinhCaiDatNhung.khiThayDoiCaiDat = { [weak self] in
            self?.dsThiDuaDaNapUI = nil
            self?.napDuLieu()
        }

        NSLayoutConstraint.activate([
            khungTaiKhoanHopThu.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            khungTaiKhoanHopThu.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            khungTaiKhoanHopThu.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            khungTaiKhoanHopThu.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            manHinhCaiDatNhung.view.topAnchor.constraint(equalTo: khungTaiKhoanHopThu.topAnchor),
            manHinhCaiDatNhung.view.leadingAnchor.constraint(equalTo: khungTaiKhoanHopThu.leadingAnchor),
            manHinhCaiDatNhung.view.trailingAnchor.constraint(equalTo: khungTaiKhoanHopThu.trailingAnchor),
            manHinhCaiDatNhung.view.bottomAnchor.constraint(equalTo: khungTaiKhoanHopThu.bottomAnchor)
        ])
    }

    private func taoKhungQuanTri() {
        khungQuanTri.backgroundColor = BangMauBCTD.nenTrang
        khungQuanTri.isHidden = true
        khungQuanTri.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(khungQuanTri)

        addChild(manHinhQuanTriNhung)
        manHinhQuanTriNhung.view.translatesAutoresizingMaskIntoConstraints = false
        khungQuanTri.addSubview(manHinhQuanTriNhung.view)
        manHinhQuanTriNhung.didMove(toParent: self)

        NSLayoutConstraint.activate([
            khungQuanTri.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            khungQuanTri.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            khungQuanTri.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            khungQuanTri.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            manHinhQuanTriNhung.view.topAnchor.constraint(equalTo: khungQuanTri.topAnchor),
            manHinhQuanTriNhung.view.leadingAnchor.constraint(equalTo: khungQuanTri.leadingAnchor),
            manHinhQuanTriNhung.view.trailingAnchor.constraint(equalTo: khungQuanTri.trailingAnchor),
            manHinhQuanTriNhung.view.bottomAnchor.constraint(equalTo: khungQuanTri.bottomAnchor)
        ])
    }

    private func taoKhungMucMoRong() {
        khungMucMoRong.backgroundColor = BangMauBCTD.nenTrang
        khungMucMoRong.isHidden = true
        khungMucMoRong.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(khungMucMoRong)

        let the = UIView()
        the.backgroundColor = BangMauBCTD.nenThe
        the.layer.cornerRadius = 14
        the.layer.borderWidth = 1
        the.layer.borderColor = BangMauBCTD.vienThe.cgColor
        the.translatesAutoresizingMaskIntoConstraints = false
        khungMucMoRong.addSubview(the)

        bieuTuongMucMoRong.tintColor = BangMauBCTD.xanhChuDao
        bieuTuongMucMoRong.contentMode = .scaleAspectFit
        bieuTuongMucMoRong.translatesAutoresizingMaskIntoConstraints = false

        nhanTieuDeMucMoRong.font = .systemFont(ofSize: 18, weight: .heavy)
        nhanTieuDeMucMoRong.textColor = BangMauBCTD.chuChinh
        nhanTieuDeMucMoRong.textAlignment = .center
        nhanTieuDeMucMoRong.numberOfLines = 0
        nhanTieuDeMucMoRong.lineBreakMode = .byWordWrapping
        nhanTieuDeMucMoRong.adjustsFontSizeToFitWidth = false

        nhanMoTaMucMoRong.font = .systemFont(ofSize: 14, weight: .medium)
        nhanMoTaMucMoRong.textColor = BangMauBCTD.chuPhu
        nhanMoTaMucMoRong.textAlignment = .center
        nhanMoTaMucMoRong.numberOfLines = 0
        nhanMoTaMucMoRong.lineBreakMode = .byWordWrapping
        nhanMoTaMucMoRong.adjustsFontSizeToFitWidth = false

        nganHanhDongMucMoRong.axis = .vertical
        nganHanhDongMucMoRong.spacing = 10

        let ngan = UIStackView(arrangedSubviews: [bieuTuongMucMoRong, nhanTieuDeMucMoRong, nhanMoTaMucMoRong, nganHanhDongMucMoRong])
        ngan.axis = .vertical
        ngan.spacing = 12
        ngan.alignment = .fill
        ngan.translatesAutoresizingMaskIntoConstraints = false
        the.addSubview(ngan)

        NSLayoutConstraint.activate([
            khungMucMoRong.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            khungMucMoRong.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            khungMucMoRong.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            khungMucMoRong.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            the.topAnchor.constraint(equalTo: khungMucMoRong.topAnchor, constant: 16),
            the.leadingAnchor.constraint(equalTo: khungMucMoRong.leadingAnchor, constant: 14),
            the.trailingAnchor.constraint(equalTo: khungMucMoRong.trailingAnchor, constant: -14),

            bieuTuongMucMoRong.heightAnchor.constraint(equalToConstant: 44),

            ngan.topAnchor.constraint(equalTo: the.topAnchor, constant: 20),
            ngan.leadingAnchor.constraint(equalTo: the.leadingAnchor, constant: 16),
            ngan.trailingAnchor.constraint(equalTo: the.trailingAnchor, constant: -16),
            ngan.bottomAnchor.constraint(equalTo: the.bottomAnchor, constant: -20)
        ])
    }

    private func taoMenuTruotBenTrai() {
        lopNenMoMenu.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        lopNenMoMenu.alpha = 0
        lopNenMoMenu.isHidden = true
        lopNenMoMenu.translatesAutoresizingMaskIntoConstraints = false
        lopNenMoMenu.addTarget(self, action: #selector(anMenu), for: .touchUpInside)
        view.addSubview(lopNenMoMenu)

        menuBenTrai.isHidden = true
        menuBenTrai.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(menuBenTrai)

        let rgTrai = menuBenTrai.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -chieuRongMenu)
        rangBuocTraiMenu = rgTrai

        NSLayoutConstraint.activate([
            lopNenMoMenu.topAnchor.constraint(equalTo: view.topAnchor),
            lopNenMoMenu.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            lopNenMoMenu.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            lopNenMoMenu.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            menuBenTrai.topAnchor.constraint(equalTo: view.topAnchor),
            menuBenTrai.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            menuBenTrai.widthAnchor.constraint(equalToConstant: chieuRongMenu),
            rgTrai
        ])

        menuBenTrai.khiChonMucChinh = { [weak self] muc in
            guard let self = self else { return }
            self.mucMenuChinh = muc
            self.anMenu(animated: true)
            self.napDuLieu()
        }

        menuBenTrai.khiChonMucConDoSo = { [weak self] mucCon in
            guard let self = self else { return }
            self.mucMenuChinh = .doSoXemSo
            self.mucConDoSo = mucCon
            self.anMenu(animated: true)
            self.napDuLieu()
        }

        let vuotMoMenu = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(xuLyVuotMepTrai(_:)))
        vuotMoMenu.edges = .left
        view.addGestureRecognizer(vuotMoMenu)
    }

    @objc private func xuLyVuotMepTrai(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .began && !dangMoMenu {
            hienMenu(animated: true)
        }
    }

    private func taoLopPhuTienTrinh() {
        lopPhuTai.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        lopPhuTai.isHidden = true
        lopPhuTai.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lopPhuTai)

        let hop = UIView()
        hop.backgroundColor = .white
        hop.layer.cornerRadius = 16
        hop.translatesAutoresizingMaskIntoConstraints = false
        lopPhuTai.addSubview(hop)

        vongQuay.color = BangMauBCTD.xanhChuDao
        vongQuay.translatesAutoresizingMaskIntoConstraints = false

        nhanTienTrinh.font = .systemFont(ofSize: 14, weight: .semibold)
        nhanTienTrinh.textColor = BangMauBCTD.chuChinh
        nhanTienTrinh.textAlignment = .center
        nhanTienTrinh.numberOfLines = 0
        nhanTienTrinh.lineBreakMode = .byWordWrapping
        nhanTienTrinh.adjustsFontSizeToFitWidth = false
        nhanTienTrinh.translatesAutoresizingMaskIntoConstraints = false

        hop.addSubview(vongQuay)
        hop.addSubview(nhanTienTrinh)

        NSLayoutConstraint.activate([
            lopPhuTai.topAnchor.constraint(equalTo: view.topAnchor),
            lopPhuTai.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            lopPhuTai.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            lopPhuTai.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            hop.centerXAnchor.constraint(equalTo: lopPhuTai.centerXAnchor),
            hop.centerYAnchor.constraint(equalTo: lopPhuTai.centerYAnchor),
            hop.widthAnchor.constraint(equalToConstant: 250),

            vongQuay.topAnchor.constraint(equalTo: hop.topAnchor, constant: 18),
            vongQuay.centerXAnchor.constraint(equalTo: hop.centerXAnchor),

            nhanTienTrinh.topAnchor.constraint(equalTo: vongQuay.bottomAnchor, constant: 12),
            nhanTienTrinh.leadingAnchor.constraint(equalTo: hop.leadingAnchor, constant: 14),
            nhanTienTrinh.trailingAnchor.constraint(equalTo: hop.trailingAnchor, constant: -14),
            nhanTienTrinh.bottomAnchor.constraint(equalTo: hop.bottomAnchor, constant: -18)
        ])
    }

    // MARK: - Nạp dữ liệu & Chuyển đổi mượt mà giữa các mục trong Menu

    private func napDuLieu() {
        nutNgay.setTitle("📅 \(TienIchNgay.hienThiNgay.string(from: ngayHienTai)) ▾", for: .normal)
        nutNgay.sizeToFit()

        let dl = KhoDuLieu.dungChung.duLieu(cho: ngayHienTai)
        let dsThiDuaDangChon = dl.danhSachThiDua(theo: cheDoDoanhThu)
        let xemDK = (cheDoDoanhThu == .luyKe && bangThiDua.dangXemDuKien)
        let soDat = dsThiDuaDangChon.filter { xemDK ? $0.daHoanThanhDuBao : $0.daDat }.count
        let dtDangChon = (cheDoDoanhThu == .luyKe) ? dl.doanhThu : dl.doanhThuRealtime

        cumChiSoChinh.capNhat(
            doanhThu: dtDangChon,
            soNganhDat: soDat,
            tongSoNganh: dsThiDuaDangChon.count,
            ngay: ngayHienTai,
            cheDo: cheDoDoanhThu,
            dangXemBieuDo: (tabXemSo == .bieuDo)
        )

        capNhatTrangThaiMuc()
        capNhatNoiDungTheoMucDangChon(dl: dl, dsThiDuaDangChon: dsThiDuaDangChon)
    }

    private func capNhatNoiDungTheoMucDangChon(dl: DuLieuNgayDMX? = nil, dsThiDuaDangChon: [DongThiDua]? = nil) {
        let duLieu = dl ?? KhoDuLieu.dungChung.duLieu(cho: ngayHienTai)

        switch mucMenuChinh {
        case .tongQuan:
            let soDatLK = duLieu.danhSachThiDua.filter(\.daDat).count
            let tongLK = duLieu.danhSachThiDua.count
            let soDatRT = duLieu.danhSachThiDuaRealtime.filter(\.daDat).count
            let tongRT = duLieu.danhSachThiDuaRealtime.count
            let soNV = KhoDuLieu.dungChung.caiDat.danhSachNhanVien.count
            let ngayStr = TienIchNgay.hienThiNgay.string(from: ngayHienTai)
            nhanTomTatTongQuan.text = [
                "📅 Ngày báo cáo: \(ngayStr)",
                "• Doanh thu Lũy kế: Thực \(duLieu.doanhThu.doanhThuThuc.chuoiSoGonVN) | QĐ \(duLieu.doanhThu.doanhThuQuyDoi.chuoiSoGonVN) (\(duLieu.doanhThu.phanTramHTQDDuKienHienThi.chuoiPhanTram))",
                "• Doanh thu Realtime: Thực \(duLieu.doanhThuRealtime.doanhThuThuc.chuoiSoGonVN) | QĐ \(duLieu.doanhThuRealtime.doanhThuQuyDoi.chuoiSoGonVN)",
                "• Thi đua Lũy kế đạt: \(soDatLK)/\(tongLK) ngành hàng   •   Thi đua Realtime đạt: \(soDatRT)/\(tongRT) ngành hàng",
                "• Nhân sự đang quản lý: \(soNV) nhân viên"
            ].joined(separator: "\n")

        case .baoCao:
            manHinhBanTinNhung.capNhatNgay(ngayHienTai)

        case .doSoXemSo:
            switch mucConDoSo {
            case .xemSo:
                switch tabXemSo {
                case .luyKe, .realtime:
                    let ds = dsThiDuaDangChon ?? duLieu.danhSachThiDua(theo: cheDoDoanhThu)
                    let kieuHienTai = KhoDuLieu.dungChung.caiDat.kieuHienThi
                    if dsThiDuaDaNapUI != ds || cheDoThiDuaDaNapUI != cheDoDoanhThu || kieuHienThiDaNapUI != kieuHienTai {
                        dsThiDuaDaNapUI = ds
                        cheDoThiDuaDaNapUI = cheDoDoanhThu
                        kieuHienThiDaNapUI = kieuHienTai
                        bangThiDua.ganDanhSach(ds, cheDo: cheDoDoanhThu)
                    }
                case .nhanVien:
                    bangNhanVien.capNhat(cho: ngayHienTai, cheDo: cheDoDoanhThu)
                case .bieuDo:
                    bangRealtimeThang.capNhat(cho: ngayHienTai)
                }

            case .nhapSo:
                let ngayStr = TienIchNgay.hienThiNgay.string(from: ngayHienTai)
                let ttLK = duLieu.doanhThu.coDuLieu ? "Đã có (\(duLieu.doanhThu.doanhThuQuyDoi.chuoiSoGonVN) tr QĐ)" : "Chưa nhập"
                let ttRT = duLieu.doanhThuRealtime.coDuLieu ? "Đã có (\(duLieu.doanhThuRealtime.doanhThuQuyDoi.chuoiSoGonVN) tr QĐ)" : "Chưa nhập"
                nhanTrangThaiNhapSo.text = [
                    "📅 TRẠNG THÁI DỮ LIỆU NGÀY \(ngayStr):",
                    "• Lũy kế: Doanh thu [\(ttLK)] · Thi đua [\(duLieu.danhSachThiDua.count) ngành] · Doanh thu NV [\(duLieu.doanhThuNhanVienLuyKe.count) NV]",
                    "• Realtime: Doanh thu [\(ttRT)] · Thi đua [\(duLieu.danhSachThiDuaRealtime.count) ngành] · Doanh thu NV [\(duLieu.doanhThuNhanVienRealtime.count) NV]"
                ].joined(separator: "\n")

            case .xuatAnh:
                capNhatGiaoDienKhungXuatAnh(taoMoiVanBan: false)
            }

        case .caiDat, .taiKhoanHopThu:
            manHinhCaiDatNhung.capNhatNgay(ngayHienTai)

        case .quanTri:
            break

        default:
            capNhatNoiDungMucMoRong(mucMenuChinh)
        }
    }

    private func capNhatTrangThaiMuc() {
        menuBenTrai.capNhatTrangThai(mucChinh: mucMenuChinh, mucCon: mucConDoSo)

        let tieuDeNutMenu: String
        if mucMenuChinh == .doSoXemSo {
            tieuDeNutMenu = " \(mucConDoSo.tieuDeNgan)"
        } else {
            tieuDeNutMenu = " \(mucMenuChinh.tieuDe)"
        }
        nutMoMenu.setTitle(tieuDeNutMenu, for: .normal)

        let hienNutTrenNav = (mucMenuChinh == .doSoXemSo || mucMenuChinh == .tongQuan || mucMenuChinh == .baoCao || mucMenuChinh == .lichDoSo)
        nutNgay.isHidden = !hienNutTrenNav
        nutNhapTatCa.isHidden = (mucMenuChinh != .doSoXemSo)
        nutXuatNav.isHidden = (mucMenuChinh != .doSoXemSo && mucMenuChinh != .tongQuan && mucMenuChinh != .baoCao)

        let laCaiDat = (mucMenuChinh == .caiDat || mucMenuChinh == .taiKhoanHopThu)
        khungDoSoXemSo.isHidden = (mucMenuChinh != .doSoXemSo)
        khungTongQuan.isHidden = (mucMenuChinh != .tongQuan)
        khungBaoCao.isHidden = (mucMenuChinh != .baoCao)
        khungTaiKhoanHopThu.isHidden = !laCaiDat
        khungQuanTri.isHidden = (mucMenuChinh != .quanTri)
        khungMucMoRong.isHidden = (mucMenuChinh == .doSoXemSo || mucMenuChinh == .tongQuan || mucMenuChinh == .baoCao || laCaiDat || mucMenuChinh == .quanTri)

        guard mucMenuChinh == .doSoXemSo else { return }

        // Highlight 3 nút mục con: 1. Xem số | 2. Nhập số | 3. Xuất ảnh
        for nut in cacNutMucConDoSo {
            let dangChon = (nut.tag == mucConDoSo.rawValue)
            if dangChon {
                nut.backgroundColor = BangMauBCTD.vangSang
                nut.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
                nut.layer.borderWidth = 1.2
                nut.layer.borderColor = BangMauBCTD.vangChuDao.cgColor
            } else {
                nut.backgroundColor = .clear
                nut.setTitleColor(BangMauBCTD.chuPhu, for: .normal)
                nut.layer.borderWidth = 0
                nut.layer.borderColor = UIColor.clear.cgColor
            }
        }

        khungXemSo.isHidden = (mucConDoSo != .xemSo)
        khungNhapSo.isHidden = (mucConDoSo != .nhapSo)
        khungXuatAnh.isHidden = (mucConDoSo != .xuatAnh)

        guard mucConDoSo == .xemSo else { return }

        // Highlight 4 tab bên trong "1. Xem số": Lũy kế | Realtime | Biểu đồ | Nhân viên
        for nut in cacNutTabXemSo {
            let dangChon = (nut.tag == tabXemSo.rawValue)
            if dangChon {
                nut.backgroundColor = BangMauBCTD.xanhChuDao
                nut.setTitleColor(.white, for: .normal)
            } else {
                nut.backgroundColor = .clear
                nut.setTitleColor(BangMauBCTD.chuPhu, for: .normal)
            }
        }

        nhanTieuDeCumDoanhThu.text = (cheDoDoanhThu == .luyKe)
            ? "CHỈ SỐ KINH DOANH · LŨY KẾ THÁNG"
            : "CHỈ SỐ KINH DOANH · REALTIME HÔM NAY"

        let laThiDua = (tabXemSo == .luyKe || tabXemSo == .realtime)
        let laNhanVien = (tabXemSo == .nhanVien)
        let laBieuDo = (tabXemSo == .bieuDo)

        khungCumDoanhThu.isHidden = laBieuDo
        vachNganHaiCum.isHidden = true
        rangBuocTopKhungDuoiTheoVach?.isActive = !laBieuDo
        rangBuocTopKhungDuoiTheoDinh?.isActive = laBieuDo

        hangChonCheDoNV.isHidden = !laNhanVien
        hangNutQuet.isHidden = laBieuDo

        for (nut, loai) in [(nutNVLuyKe, LoaiCheDoDoanhThu.luyKe), (nutNVRealtime, LoaiCheDoDoanhThu.realtime)] {
            if cheDoDoanhThu == loai {
                nut.backgroundColor = BangMauBCTD.vangSang
                nut.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
                nut.layer.borderColor = BangMauBCTD.vangChuDao.cgColor
            } else {
                nut.backgroundColor = BangMauBCTD.nenThePhu
                nut.setTitleColor(BangMauBCTD.chuPhu, for: .normal)
                nut.layer.borderColor = BangMauBCTD.vienDam.cgColor
            }
        }

        if laNhanVien {
            rangBuocTopNutQuetTheoDinh?.isActive = false
            rangBuocTopNutQuetTheoNV?.isActive = true
        } else {
            rangBuocTopNutQuetTheoNV?.isActive = false
            rangBuocTopNutQuetTheoDinh?.isActive = true
        }

        let nhanCheDo = cheDoDoanhThu.tieuDe
        if laNhanVien {
            nutThemAnhMoi.setTitle(" Nhập ảnh Thi đua NV (\(nhanCheDo))", for: .normal)
            nutNhapDoanhThuNV.setTitle(" Nhập ảnh Doanh thu (\(nhanCheDo))", for: .normal)
            nutNhapDoanhThuNV.isHidden = false
            rangBuocBangRongHaiNutNV?.isActive = true
        } else {
            nutThemAnhMoi.setTitle(" Thêm ảnh Thi đua (\(nhanCheDo))", for: .normal)
            nutNhapDoanhThuNV.isHidden = true
            rangBuocBangRongHaiNutNV?.isActive = false
        }

        bangThiDua.isHidden = !laThiDua
        bangNhanVien.isHidden = !laNhanVien
        bangRealtimeThang.isHidden = !laBieuDo

        nutThemThuCong.isHidden = !laThiDua
        nutThemThuCong.setTitle(" Nhập/Mẫu", for: .normal)
    }

    private func capNhatNoiDungMucMoRong(_ muc: MucMenuChinh) {
        let cfg = UIImage.SymbolConfiguration(pointSize: 34, weight: .bold)
        bieuTuongMucMoRong.image = UIImage(systemName: muc.bieuTuongSF, withConfiguration: cfg)
        nhanTieuDeMucMoRong.text = muc.tieuDe.uppercased()

        nganHanhDongMucMoRong.arrangedSubviews.forEach {
            nganHanhDongMucMoRong.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        switch muc {
        case .lichDoSo:
            let ngayStr = TienIchNgay.hienThiNgay.string(from: ngayHienTai)
            nhanMoTaMucMoRong.text = "Quản lý lịch sử ngày đổ số và theo dõi tiến độ dữ liệu theo từng ngày trong tháng.\nNgày đang chọn: \(ngayStr)."
            nganHanhDongMucMoRong.addArrangedSubview(taoNutHanhDongMoRong("📅 Chọn ngày xem / đổ số báo cáo", action: #selector(moLichSuNgay)))
            nganHanhDongMucMoRong.addArrangedSubview(taoNutHanhDongMoRong("📈 Mở Biểu đồ & Tổng hợp Realtime tháng", action: #selector(moNhanhBieuDoTuMucMoRong)))

        case .congCu:
            nhanMoTaMucMoRong.text = "Bộ công cụ tiện ích hỗ trợ phân tích AI Gemini, chia Target ngành hàng, quản lý nhân viên và xuất báo cáo."
            nganHanhDongMucMoRong.addArrangedSubview(taoNutHanhDongMoRong("📰 Mở mục Báo cáo & Phân tích AI Gemini → Gửi LINE", action: #selector(moBanTin)))
            nganHanhDongMucMoRong.addArrangedSubview(taoNutHanhDongMoRong("🎯 Chia Target mặt hàng cho Nhân viên", action: #selector(moNhanhChiaTarget)))
            nganHanhDongMucMoRong.addArrangedSubview(taoNutHanhDongMoRong("👥 Quản lý danh sách Nhân viên", action: #selector(moNhanhQuanLyNV)))
            nganHanhDongMucMoRong.addArrangedSubview(taoNutHanhDongMoRong("🖼️ Mở mục 3. Xuất ảnh & Xuất Excel / PowerPoint", action: #selector(moMenuXuatBaoCao)))

        case .ketNoi:
            let tk = DichVuDongBo.dungChung.tenDangNhap.isEmpty ? "Chưa đăng nhập" : DichVuDongBo.dungChung.tenDangNhap
            nhanMoTaMucMoRong.text = "Trạng thái kết nối đồng bộ đám mây với máy chủ ĐMX (duongnt.io.vn/dmx).\nTài khoản hiện tại: \(tk)."
            nganHanhDongMucMoRong.addArrangedSubview(taoNutHanhDongMoRong("🔄 Đồng bộ dữ liệu đám mây ngay", action: #selector(dongBoDamMayTuMucMoRong)))

        default:
            nhanMoTaMucMoRong.text = "Mục \"\(muc.tieuDe)\" đã sẵn sàng phục vụ quản lý siêu thị."
            nganHanhDongMucMoRong.addArrangedSubview(taoNutHanhDongMoRong("📊 Quay lại Đổ số - Xem số", action: #selector(quayLaiDoSoXemSo)))
        }
    }

    private func taoNutHanhDongMoRong(_ tieuDe: String, action: Selector) -> UIButton {
        let nut = UIButton(type: .system)
        nut.setTitle(tieuDe, for: .normal)
        nut.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        nut.titleLabel?.numberOfLines = 0
        nut.titleLabel?.lineBreakMode = .byWordWrapping
        nut.titleLabel?.textAlignment = .center
        nut.titleLabel?.adjustsFontSizeToFitWidth = false
        nut.backgroundColor = BangMauBCTD.xanhChuDao
        nut.tintColor = .white
        nut.setTitleColor(.white, for: .normal)
        nut.layer.cornerRadius = 10
        nut.contentEdgeInsets = UIEdgeInsets(top: 11, left: 14, bottom: 11, right: 14)
        nut.addTarget(self, action: action, for: .touchUpInside)
        return nut
    }

    @objc private func moNhanhBieuDoTuMucMoRong() {
        mucMenuChinh = .doSoXemSo
        mucConDoSo = .xemSo
        tabXemSo = .bieuDo
        napDuLieu()
    }

    /// Mở mục Báo cáo & Phân tích AI Gemini
    @objc private func moBanTin() {
        mucMenuChinh = .baoCao
        napDuLieu()
    }

    private func taoAnhBangChoBanTin(khung: KhungBanTin, soLieu: SoLieuBanTin) -> [UIImage] {
        let anh: UIImage?
        switch khung {
        case .dauCa:
            guard soLieu.coSoLieuLuyKe else { return [] }
            anh = bangThiDua.taoAnhBaoCao(
                ngay: soLieu.ngay,
                doanhThu: soLieu.luyKe,
                danhSach: soLieu.dsLuyKe,
                cheDoDoanhThu: .luyKe,
                xemDuKien: true,
                thongTinDonVi: soLieu.tenDonVi,
                capNhatLuc: soLieu.capNhatLuc
            )
        case .hienTai, .ketCa:
            if soLieu.coSoLieuHomNay {
                anh = bangThiDua.taoAnhBaoCao(
                    ngay: soLieu.ngay,
                    doanhThu: soLieu.homNay,
                    danhSach: soLieu.dsHomNay,
                    cheDoDoanhThu: .realtime,
                    xemDuKien: false,
                    thongTinDonVi: soLieu.tenDonVi,
                    capNhatLuc: soLieu.capNhatLuc
                )
            } else if soLieu.coSoLieuLuyKe {
                anh = bangThiDua.taoAnhBaoCao(
                    ngay: soLieu.ngay,
                    doanhThu: soLieu.luyKe,
                    danhSach: soLieu.dsLuyKe,
                    cheDoDoanhThu: .luyKe,
                    xemDuKien: false,
                    thongTinDonVi: soLieu.tenDonVi,
                    capNhatLuc: soLieu.capNhatLuc
                )
            } else {
                anh = nil
            }
        }
        if let anh = anh { return [anh] }
        return []
    }

    @objc private func moNhanhChiaTarget() {
        navigationController?.pushViewController(ManHinhChiaTarget(ngay: ngayHienTai), animated: true)
    }

    @objc private func moNhanhQuanLyNV() {
        navigationController?.pushViewController(ManHinhQuanLyNhanVien(), animated: true)
    }

    @objc private func dongBoDamMayTuMucMoRong() {
        DichVuDongBo.dungChung.taiDuLieu()
    }

    @objc private func quayLaiDoSoXemSo() {
        mucMenuChinh = .doSoXemSo
        mucConDoSo = .xemSo
        napDuLieu()
    }

    // MARK: - Nút Nhập ảnh & Xoá

    @objc private func bamThemAnhMoi() {
        switch tabXemSo {
        case .luyKe, .realtime:
            moHuongDanQuetAnhThiDua()
        case .nhanVien:
            moChonAnh(cheDo: .thiDuaNhanVien(cheDoDoanhThu), gioiHan: 0)
        case .bieuDo:
            moChonAnh(cheDo: .doanhThu(.realtime), gioiHan: 2)
        }
    }

    @objc private func bamNhapAnhDoanhThuNV() {
        moChonAnh(cheDo: .doanhThuNhanVien(cheDoDoanhThu), gioiHan: 0)
    }

    private func moHuongDanQuetAnhThiDua(cheDo: LoaiCheDoDoanhThu? = nil) {
        let cheDoMucTieu = cheDo ?? cheDoDoanhThu
        if cheDoDoanhThu != cheDoMucTieu {
            cheDoDoanhThu = cheDoMucTieu
            napDuLieu()
        }
        let dl = KhoDuLieu.dungChung.duLieu(cho: ngayHienTai)
        let dsHienTai = dl.danhSachThiDua(theo: cheDoMucTieu)
        let tenCheDo = cheDoMucTieu.tieuDe
        let cheDoKhac: LoaiCheDoDoanhThu = (cheDoMucTieu == .luyKe) ? .realtime : .luyKe
        let bieuTuongKhac = (cheDoKhac == .luyKe) ? "📊" : "⚡"

        if dsHienTai.isEmpty {
            thayTheBangThiDuaKhiQuet = false
            moChonAnh(cheDo: .thiDua(cheDoMucTieu), gioiHan: 0)
            return
        }

        hienMenuChon(
            tieuDe: "Nhập ảnh Thi đua (\(tenCheDo))",
            cacMuc: [
                MucChonDMX(tieuDe: "➕ Quét thêm ảnh Thi đua \(tenCheDo) (Gộp nối tiếp)") { [weak self] in
                    self?.thayTheBangThiDuaKhiQuet = false
                    self?.moChonAnh(cheDo: .thiDua(cheDoMucTieu), gioiHan: 0)
                },
                MucChonDMX(tieuDe: "🔄 Quét mới Thi đua \(tenCheDo) (Thay thế bảng \(tenCheDo))", kieu: .nguyHiem) { [weak self] in
                    self?.thayTheBangThiDuaKhiQuet = true
                    self?.moChonAnh(cheDo: .thiDua(cheDoMucTieu), gioiHan: 0)
                },
                MucChonDMX(tieuDe: "\(bieuTuongKhac) Chuyển sang nhập Thi đua \(cheDoKhac.tieuDe)") { [weak self] in
                    self?.moHuongDanQuetAnhThiDua(cheDo: cheDoKhac)
                },
                MucChonDMX(tieuDe: "Huỷ", kieu: .huy)
            ]
        )
    }

    @objc private func bamXoaQuetLai() {
        let cheDoXoa = cheDoDoanhThu
        let tenCheDo = cheDoXoa.tieuDe

        if tabXemSo == .nhanVien {
            hienMenuChon(
                tieuDe: "Xoá dữ liệu Nhân viên (\(tenCheDo))?",
                thongDiep: "Chọn phần dữ liệu Nhân viên (\(tenCheDo)) muốn xoá:",
                cacMuc: [
                    MucChonDMX(tieuDe: "🗑️ Xoá bảng Doanh thu hợp nhất NV (\(tenCheDo))", kieu: .nguyHiem) { [weak self] in
                        guard let self = self else { return }
                        if cheDoXoa == .luyKe {
                            KhoDuLieu.dungChung.xoaDoanhThuNhanVienLuyKeThang(cho: self.ngayHienTai, xoaCaThiDuaNV: false)
                        } else {
                            var moi = KhoDuLieu.dungChung.duLieu(cho: self.ngayHienTai)
                            moi.ganDoanhThuNhanVien([], theo: cheDoXoa)
                            KhoDuLieu.dungChung.luu(moi)
                        }
                        self.napDuLieu()
                    },
                    MucChonDMX(tieuDe: "🗑️ Xoá cả Doanh thu NV & Thực hiện môn NV (\(tenCheDo))", kieu: .nguyHiem) { [weak self] in
                        guard let self = self else { return }
                        if cheDoXoa == .luyKe {
                            KhoDuLieu.dungChung.xoaDoanhThuNhanVienLuyKeThang(cho: self.ngayHienTai, xoaCaThiDuaNV: true)
                        } else {
                            var moi = KhoDuLieu.dungChung.duLieu(cho: self.ngayHienTai)
                            moi.ganDoanhThuNhanVien([], theo: cheDoXoa)
                            moi.ganThiDuaNhanVien([:], theo: cheDoXoa)
                            KhoDuLieu.dungChung.luu(moi)
                        }
                        self.napDuLieu()
                    },
                    MucChonDMX(tieuDe: "Huỷ", kieu: .huy)
                ]
            )
            return
        }

        guard tabXemSo == .luyKe || tabXemSo == .realtime else { return }
        let dl = KhoDuLieu.dungChung.duLieu(cho: ngayHienTai)
        let dsHienTai = dl.danhSachThiDua(theo: cheDoXoa)

        if dsHienTai.isEmpty {
            moHuongDanQuetAnhThiDua(cheDo: cheDoXoa)
            return
        }

        hienMenuChon(
            tieuDe: "Xoá bảng Thi đua \(tenCheDo)?",
            thongDiep: "Toàn bộ \(dsHienTai.count) ngành hàng trong bảng Thi đua \(tenCheDo) sẽ được xoá sạch.",
            cacMuc: [
                MucChonDMX(tieuDe: "🗑️ Xoá sạch Thi đua \(tenCheDo) & Quét lại ngay", kieu: .nguyHiem) { [weak self] in
                    guard let self = self else { return }
                    var moi = KhoDuLieu.dungChung.duLieu(cho: self.ngayHienTai)
                    moi.ganDanhSachThiDua([], theo: cheDoXoa)
                    KhoDuLieu.dungChung.luu(moi)
                    self.napDuLieu()
                    self.moChonAnh(cheDo: .thiDua(cheDoXoa), gioiHan: 0)
                },
                MucChonDMX(tieuDe: "Chỉ xoá sạch danh sách Thi đua \(tenCheDo)", kieu: .nguyHiem) { [weak self] in
                    guard let self = self else { return }
                    var moi = KhoDuLieu.dungChung.duLieu(cho: self.ngayHienTai)
                    moi.ganDanhSachThiDua([], theo: cheDoXoa)
                    KhoDuLieu.dungChung.luu(moi)
                    self.napDuLieu()
                },
                MucChonDMX(tieuDe: "Huỷ", kieu: .huy)
            ]
        )
    }

    // MARK: - Tương tác cụm Doanh thu

    @objc private func bamTheDoanhThu() {
        let tenCheDo = cheDoDoanhThu.tieuDe

        hienMenuChon(
            tieuDe: "Doanh thu (\(tenCheDo))",
            cacMuc: [
                MucChonDMX(tieuDe: "📷 Chọn 2 ảnh Doanh thu \(tenCheDo) (Thực + QĐ)") { [weak self] in
                    guard let self = self else { return }
                    self.moChonAnh(cheDo: .doanhThu(self.cheDoDoanhThu), gioiHan: 2)
                },
                MucChonDMX(tieuDe: "✏️ Nhập / Sửa tay Doanh thu \(tenCheDo) (& Lượt khách)") { [weak self] in
                    self?.moHopThoaiNhapDoanhThu()
                },
                MucChonDMX(tieuDe: "🗑️ Xoá số liệu Doanh thu \(tenCheDo)", kieu: .nguyHiem) { [weak self] in
                    guard let self = self else { return }
                    if self.cheDoDoanhThu == .luyKe {
                        KhoDuLieu.dungChung.xoaDoanhThuLuyKeThang(cho: self.ngayHienTai)
                    } else {
                        var dl = KhoDuLieu.dungChung.duLieu(cho: self.ngayHienTai)
                        dl.doanhThuRealtime = ThongTinDoanhThu()
                        KhoDuLieu.dungChung.luu(dl)
                    }
                    self.napDuLieu()
                },
                MucChonDMX(tieuDe: "Đóng", kieu: .huy)
            ]
        )
    }

    private func moHopThoaiNhapDoanhThu() {
        let dl = KhoDuLieu.dungChung.duLieu(cho: ngayHienTai)
        let dt = (cheDoDoanhThu == .luyKe) ? dl.doanhThu : dl.doanhThuRealtime
        let tenCheDo = cheDoDoanhThu.tieuDe

        let hop = UIAlertController(
            title: "Số liệu Doanh thu (\(tenCheDo))",
            message: "Nhập Doanh thu thực, Target thực, Doanh thu QĐ, Target QĐ và Lượt khách:",
            preferredStyle: .alert
        )
        hop.addTextField { tf in
            tf.placeholder = "Doanh thu thực (VD: 11143)"
            tf.keyboardType = .decimalPad
            if dt.doanhThuThuc > 0 { tf.text = String(dt.doanhThuThuc) }
        }
        hop.addTextField { tf in
            tf.placeholder = "Target thực (VD: 11128)"
            tf.keyboardType = .decimalPad
            if dt.targetThuc > 0 { tf.text = String(dt.targetThuc) }
        }
        hop.addTextField { tf in
            tf.placeholder = "Doanh thu quy đổi (VD: 15199)"
            tf.keyboardType = .decimalPad
            if dt.doanhThuQuyDoi > 0 { tf.text = String(dt.doanhThuQuyDoi) }
        }
        hop.addTextField { tf in
            tf.placeholder = "Target quy đổi (VD: 14957)"
            tf.keyboardType = .decimalPad
            if dt.targetQuyDoi > 0 { tf.text = String(dt.targetQuyDoi) }
        }
        hop.addTextField { tf in
            tf.placeholder = "Lượt khách (từ ô TLPVTC, VD: 19149)"
            tf.keyboardType = .numberPad
            if dt.luotKhach > 0 { tf.text = String(Int(dt.luotKhach)) }
        }

        hop.addAction(UIAlertAction(title: "Lưu", style: .default) { [weak self] _ in
            guard let self = self, let tfs = hop.textFields, tfs.count >= 5 else { return }
            var moi = KhoDuLieu.dungChung.duLieu(cho: self.ngayHienTai)
            let nhap = ThongTinDoanhThu(
                doanhThuThuc: self.docSoTuO(tfs[0].text),
                targetThuc: self.docSoTuO(tfs[1].text),
                doanhThuQuyDoi: self.docSoTuO(tfs[2].text),
                targetQuyDoi: self.docSoTuO(tfs[3].text),
                luotKhach: self.docSoTuO(tfs[4].text)
            )
            if self.cheDoDoanhThu == .luyKe {
                moi.doanhThu = moi.doanhThu.gop(voi: nhap, laRealtime: false)
            } else {
                moi.doanhThuRealtime = moi.doanhThuRealtime.gop(voi: nhap, laRealtime: true)
            }
            KhoDuLieu.dungChung.luu(moi)
            self.napDuLieu()
        })
        hop.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        present(hop, animated: true)
    }

    private func moMenuRealtimeChoNgay(_ item: DuLieuRealtimeNgayTrongThang) {
        let ngayStr = TienIchNgay.hienThiNgay.string(from: item.ngay)
        var cacMuc: [MucChonDMX] = [
            MucChonDMX(tieuDe: "📷 Chọn 2 ảnh Realtime ngày \(ngayStr)") { [weak self] in
                guard let self = self else { return }
                self.ngayHienTai = item.ngay
                self.napDuLieu()
                self.moChonAnh(cheDo: .doanhThu(.realtime), gioiHan: 2)
            },
            MucChonDMX(tieuDe: "✏️ Nhập / Sửa tay Realtime ngày \(ngayStr)") { [weak self] in
                guard let self = self else { return }
                self.ngayHienTai = item.ngay
                self.cheDoDoanhThu = .realtime
                self.napDuLieu()
                self.moHopThoaiNhapDoanhThu()
            }
        ]
        if item.coDuLieu {
            cacMuc.append(MucChonDMX(tieuDe: "🗑️ Xoá Realtime ngày \(ngayStr)", kieu: .nguyHiem) { [weak self] in
                guard let self = self else { return }
                var dl = KhoDuLieu.dungChung.duLieu(cho: item.ngay)
                dl.doanhThuRealtime = ThongTinDoanhThu()
                KhoDuLieu.dungChung.luu(dl)
                self.napDuLieu()
            })
        }
        cacMuc.append(MucChonDMX(tieuDe: "Đóng", kieu: .huy))

        hienMenuChon(
            tieuDe: ngayStr,
            thongDiep: item.coDuLieu
                ? "DT Thực: \(item.doanhThuThuc.chuoiSoVN)  •  DT Quy đổi: \(item.doanhThuQuyDoi.chuoiSoVN)"
                : nil,
            cacMuc: cacMuc
        )
    }

    private func docSoTuO(_ text: String?) -> Double {
        let s = (text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Double(s) ?? 0
    }

    // MARK: - Chọn ảnh & Quét Apple Vision

    private func moChonAnh(cheDo: CheDoQuetAnh, gioiHan: Int) {
        cheDoQuet = cheDo
        var cauHinh = PHPickerConfiguration()
        cauHinh.filter = .images
        cauHinh.selectionLimit = gioiHan
        if #available(iOS 15.0, *) {
            cauHinh.selection = .ordered
        }
        let picker = PHPickerViewController(configuration: cauHinh)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }

        let cheDo = cheDoQuet
        let nhom = DispatchGroup()
        let khoaAnh = NSLock()
        var danhSach = Array<UIImage?>(repeating: nil, count: results.count)

        for (i, r) in results.enumerated() {
            guard r.itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }
            nhom.enter()
            r.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                if let img = obj as? UIImage {
                    khoaAnh.lock()
                    danhSach[i] = img
                    khoaAnh.unlock()
                }
                nhom.leave()
            }
        }

        nhom.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            let cacAnh = danhSach.compactMap { $0 }
            guard !cacAnh.isEmpty else { return }

            switch cheDo {
            case .doanhThu(let loaiDT):
                self.xuLyQuetDoanhThu(cacAnh, loai: loaiDT)
            case .thiDua(let loaiTD):
                self.xuLyQuetThiDua(cacAnh, loai: loaiTD)
            case .thiDuaNhanVien(let loaiTDNV):
                self.xuLyQuetThiDuaNhanVien(cacAnh, loai: loaiTDNV)
            case .doanhThuNhanVien(let loaiNV):
                self.xuLyQuetDoanhThuNhanVien(cacAnh, loai: loaiNV)
            case .tatCaAnhTheoTab(let cheDoTab):
                self.xuLyQuetTatCaAnhTheoTab(cacAnh, cheDoTab: cheDoTab)
            }
        }
    }

    private func xuLyQuetTatCaAnhTheoTab(_ cacAnh: [UIImage], cheDoTab: LoaiCheDoDoanhThu) {
        let tenCheDo = cheDoTab.tieuDe
        let laRT = (cheDoTab == .realtime)
        hienTienTrinh("Đang đọc & lọc \(cacAnh.count) ảnh cho \(tenCheDo)...")
        DichVuDocAnh.dungChung.quetVaPhanLoaiTatCaAnh(
            danhSachAnh: cacAnh,
            ngay: ngayHienTai,
            cheDoDangChon: cheDoTab,
            tienTrinh: { [weak self] tt in
                self?.nhanTienTrinh.text = tt
            },
            hoanTat: { [weak self] kq in
                guard let self = self else { return }
                self.anTienTrinh()

                guard kq.coDuLieu else {
                    let tb = UIAlertController(
                        title: "Chưa nhận diện được dữ liệu",
                        message: "Không tìm thấy bảng Doanh thu, Thi đua hay Nhân viên hợp lệ trong các ảnh vừa chọn.",
                        preferredStyle: .alert
                    )
                    tb.addAction(UIAlertAction(title: "Đóng", style: .default))
                    self.present(tb, animated: true)
                    return
                }

                var dl = KhoDuLieu.dungChung.duLieu(cho: self.ngayHienTai)
                var cacMucDaDien: [String] = []

                if let dt = kq.doanhThu, dt.coDuLieu {
                    if laRT {
                        dl.doanhThuRealtime = dl.doanhThuRealtime.gop(voi: dt, laRealtime: true)
                        cacMucDaDien.append("• Doanh thu Realtime (\(kq.soAnhDoanhThu) ảnh): Thực \(dl.doanhThuRealtime.doanhThuThuc.chuoiSoGonVN) | QĐ \(dl.doanhThuRealtime.doanhThuQuyDoi.chuoiSoGonVN) | HT \(dl.doanhThuRealtime.phanTramHTQDDuKienHienThi.chuoiPhanTram)")
                    } else {
                        dl.doanhThu = dl.doanhThu.gop(voi: dt, laRealtime: false)
                        cacMucDaDien.append("• Doanh thu Lũy kế (\(kq.soAnhDoanhThu) ảnh): Thực \(dl.doanhThu.doanhThuThuc.chuoiSoGonVN) | QĐ \(dl.doanhThu.doanhThuQuyDoi.chuoiSoGonVN) | HT \(dl.doanhThu.phanTramHTQDDuKienHienThi.chuoiPhanTram)")
                    }
                }

                if !kq.danhSachThiDua.isEmpty {
                    let cu = dl.danhSachThiDua(theo: cheDoTab)
                    let gop = KhoDuLieu.gopDanhSachThiDua(cu: cu, moi: kq.danhSachThiDua)
                    dl.ganDanhSachThiDua(gop, theo: cheDoTab)
                    cacMucDaDien.append("• Thi đua \(tenCheDo) (\(kq.soAnhThiDua) ảnh): \(kq.danhSachThiDua.count) ngành hàng")
                }

                if !kq.doanhThuNhanVien.isEmpty {
                    let dsQuanLy = KhoDuLieu.dungChung.caiDat.danhSachNhanVien
                    var mapDTNV: [String: DoanhThuNhanVienItem] = [:]
                    if cheDoTab == .realtime {
                        for item in dl.doanhThuNhanVien(theo: cheDoTab) {
                            let ma = KhoDuLieu.chuanHoaMaNV(item.maNV)
                            if !ma.isEmpty { mapDTNV[ma] = item }
                        }
                    }
                    for item in kq.doanhThuNhanVien {
                        let nvKhop = KhoDuLieu.khopNhanVienQuetVoiQuanLy(maQuet: item.maNV, tenQuet: item.hoTen, dsQuanLy: dsQuanLy)
                        let ma = nvKhop?.maNV ?? KhoDuLieu.chuanHoaMaNV(item.maNV)
                        let ten = nvKhop?.hoTen ?? item.hoTen
                        guard !ma.isEmpty else { continue }
                        var capNhat = item
                        capNhat.maNV = ma
                        capNhat.hoTen = ten
                        mapDTNV[ma] = capNhat
                    }
                    dl.ganDoanhThuNhanVien(Array(mapDTNV.values), theo: cheDoTab)
                    cacMucDaDien.append("• Doanh thu Nhân viên \(tenCheDo) (\(kq.soAnhDoanhThuNV) ảnh): \(mapDTNV.count) NV (Đã thay thế dữ liệu cũ)")
                }

                if !kq.thiDuaNhanVien.isEmpty {
                    let bangNVMoi = KhoDuLieu.dungChung.gopKetQuaThiDuaNhanVien(
                        hienTai: dl.thiDuaNhanVien(theo: cheDoTab),
                        mangKhoiNV: kq.thiDuaNhanVien,
                        ngay: self.ngayHienTai,
                        cheDo: cheDoTab
                    )
                    dl.ganThiDuaNhanVien(bangNVMoi, theo: cheDoTab)
                    cacMucDaDien.append("• Thực hiện NV theo ngành \(tenCheDo) (\(kq.soAnhThiDuaNV) ảnh): \(kq.thiDuaNhanVien.count) nhóm ngành")
                }

                if !kq.capNhatLuc.isEmpty { dl.capNhatLuc = kq.capNhatLuc }
                if !kq.thongTinDonVi.isEmpty { dl.thongTinDonVi = kq.thongTinDonVi }

                KhoDuLieu.dungChung.luu(dl)
                self.napDuLieu()

                let tb = UIAlertController(
                    title: "✅ Đã nạp vào phần \(tenCheDo)",
                    message: cacMucDaDien.joined(separator: "\n"),
                    preferredStyle: .alert
                )
                tb.addAction(UIAlertAction(title: "Hoàn tất", style: .default))
                self.present(tb, animated: true)
            }
        )
    }

    private func xuLyQuetThiDua(_ cacAnh: [UIImage], loai: LoaiCheDoDoanhThu) {
        cheDoDoanhThu = loai
        let tenCheDo = loai.tieuDe
        let laRT = (loai == .realtime)
        let dlHienTai = KhoDuLieu.dungChung.duLieu(cho: ngayHienTai)
        let dsHienCo = thayTheBangThiDuaKhiQuet ? [] : dlHienTai.danhSachThiDua(theo: loai)
        hienTienTrinh("Đang đọc \(cacAnh.count) ảnh Thi đua (\(tenCheDo))...")
        DichVuDocAnh.dungChung.quetAnhThiDua(
            danhSachAnh: cacAnh,
            danhSachHienCo: dsHienCo,
            laRealtime: laRT,
            tienTrinh: { [weak self] tt in
                self?.nhanTienTrinh.text = tt
            },
            hoanTat: { [weak self] kq in
                guard let self = self else { return }
                self.anTienTrinh()
                var dl = KhoDuLieu.dungChung.duLieu(cho: self.ngayHienTai)
                if let dtMoi = kq.doanhThuQuetDuoc, dtMoi.coDuLieu {
                    if laRT {
                        dl.doanhThuRealtime = dl.doanhThuRealtime.gop(voi: dtMoi, laRealtime: true)
                    } else {
                        dl.doanhThu = dl.doanhThu.gop(voi: dtMoi, laRealtime: false)
                    }
                }
                if !kq.danhSach.isEmpty {
                    let cu = self.thayTheBangThiDuaKhiQuet ? [] : dl.danhSachThiDua(theo: loai)
                    let gop = KhoDuLieu.gopDanhSachThiDua(cu: cu, moi: kq.danhSach)
                    dl.ganDanhSachThiDua(gop, theo: loai)
                }
                self.thayTheBangThiDuaKhiQuet = false
                if !kq.thiDuaNhanVien.isEmpty {
                    let bangNVMoi = KhoDuLieu.dungChung.gopKetQuaThiDuaNhanVien(
                        hienTai: dl.thiDuaNhanVien(theo: loai),
                        mangKhoiNV: kq.thiDuaNhanVien,
                        ngay: self.ngayHienTai,
                        cheDo: loai
                    )
                    dl.ganThiDuaNhanVien(bangNVMoi, theo: loai)
                }
                dl.capNhatLuc = kq.capNhatLuc
                if !kq.thongTinDonVi.isEmpty { dl.thongTinDonVi = kq.thongTinDonVi }
                KhoDuLieu.dungChung.luu(dl)
                self.napDuLieu()
            }
        )
    }

    private func xuLyQuetThiDuaNhanVien(_ cacAnh: [UIImage], loai: LoaiCheDoDoanhThu) {
        let tenCheDo = loai.tieuDe
        hienTienTrinh("Đang đọc \(cacAnh.count) ảnh Thi đua Nhân viên (\(tenCheDo))...")
        DichVuDocAnh.dungChung.quetAnhThiDuaNhanVien(
            danhSachAnh: cacAnh,
            tenNganhGoiY: nil,
            tienTrinh: { [weak self] tt in
                self?.nhanTienTrinh.text = tt
            },
            hoanTat: { [weak self] cacKhoi in
                guard let self = self else { return }
                self.anTienTrinh()
                guard !cacKhoi.isEmpty else {
                    let tb = UIAlertController(
                        title: "Chưa đọc được dữ liệu Thi đua NV",
                        message: "Hãy chụp rõ bảng Thực hiện Thi đua Nhân viên theo ngành hàng rồi thử lại.",
                        preferredStyle: .alert
                    )
                    tb.addAction(UIAlertAction(title: "Đóng", style: .default))
                    self.present(tb, animated: true)
                    return
                }

                var dl = KhoDuLieu.dungChung.duLieu(cho: self.ngayHienTai)
                let bangNVMoi = KhoDuLieu.dungChung.gopKetQuaThiDuaNhanVien(
                    hienTai: dl.thiDuaNhanVien(theo: loai),
                    mangKhoiNV: cacKhoi,
                    ngay: self.ngayHienTai,
                    cheDo: loai
                )
                dl.ganThiDuaNhanVien(bangNVMoi, theo: loai)
                KhoDuLieu.dungChung.luu(dl)
                self.napDuLieu()
            }
        )
    }

    private func xuLyQuetDoanhThuNhanVien(_ cacAnh: [UIImage], loai: LoaiCheDoDoanhThu) {
        let tenCheDo = loai.tieuDe
        hienTienTrinh("Đang đọc \(cacAnh.count) ảnh Doanh thu Nhân viên (\(tenCheDo))...")
        DichVuDocAnh.dungChung.quetAnhDoanhThuNhanVien(
            danhSachAnh: cacAnh,
            tienTrinh: { [weak self] tt in
                self?.nhanTienTrinh.text = tt
            },
            hoanTat: { [weak self] dsQuet in
                guard let self = self else { return }
                self.anTienTrinh()
                guard !dsQuet.isEmpty else {
                    let tb = UIAlertController(
                        title: "Chưa đọc được dòng nhân viên",
                        message: "Hãy chụp rõ bảng Doanh thu hợp nhất theo Nhân viên rồi thử lại.",
                        preferredStyle: .alert
                    )
                    tb.addAction(UIAlertAction(title: "Đóng", style: .default))
                    self.present(tb, animated: true)
                    return
                }

                var dl = KhoDuLieu.dungChung.duLieu(cho: self.ngayHienTai)
                let dsQuanLy = KhoDuLieu.dungChung.caiDat.danhSachNhanVien
                var mapDTNV: [String: DoanhThuNhanVienItem] = [:]
                if loai == .realtime {
                    for item in dl.doanhThuNhanVien(theo: loai) {
                        let ma = KhoDuLieu.chuanHoaMaNV(item.maNV)
                        if !ma.isEmpty { mapDTNV[ma] = item }
                    }
                }
                for item in dsQuet {
                    let nvKhop = KhoDuLieu.khopNhanVienQuetVoiQuanLy(maQuet: item.maNV, tenQuet: item.hoTen, dsQuanLy: dsQuanLy)
                    let ma = nvKhop?.maNV ?? KhoDuLieu.chuanHoaMaNV(item.maNV)
                    let ten = nvKhop?.hoTen ?? item.hoTen
                    guard !ma.isEmpty else { continue }
                    var capNhat = item
                    capNhat.maNV = ma
                    capNhat.hoTen = ten
                    mapDTNV[ma] = capNhat
                }
                dl.ganDoanhThuNhanVien(Array(mapDTNV.values), theo: loai)
                KhoDuLieu.dungChung.luu(dl)
                self.napDuLieu()
            }
        )
    }

    private func xuLyQuetDoanhThu(_ cacAnh: [UIImage], loai: LoaiCheDoDoanhThu) {
        let tenCheDo = loai.tieuDe
        let laRT = (loai == .realtime)
        hienTienTrinh("Đang đọc \(cacAnh.count) ảnh Doanh thu (\(tenCheDo))...")
        DichVuDocAnh.dungChung.quetAnhDoanhThu(
            danhSachAnh: cacAnh,
            laRealtime: laRT,
            tienTrinh: { [weak self] tt in
                self?.nhanTienTrinh.text = tt
            },
            hoanTat: { [weak self] dtMoi in
                guard let self = self else { return }
                self.anTienTrinh()

                if dtMoi.doanhThuThuc <= 0 && dtMoi.doanhThuQuyDoi <= 0 {
                    let tb = UIAlertController(
                        title: "Chưa đọc được số liệu Doanh thu",
                        message: "Vui lòng chọn ảnh chụp màn hình Doanh thu thực và Doanh thu quy đổi của phần \(tenCheDo).",
                        preferredStyle: .alert
                    )
                    tb.addAction(UIAlertAction(title: "Chọn lại ảnh", style: .default) { [weak self] _ in
                        self?.moChonAnh(cheDo: .doanhThu(loai), gioiHan: 2)
                    })
                    tb.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
                    self.present(tb, animated: true)
                    return
                }

                var dl = KhoDuLieu.dungChung.duLieu(cho: self.ngayHienTai)
                if loai == .luyKe {
                    dl.doanhThu = dl.doanhThu.gop(voi: dtMoi, laRealtime: false)
                } else {
                    dl.doanhThuRealtime = dl.doanhThuRealtime.gop(voi: dtMoi, laRealtime: true)
                }
                KhoDuLieu.dungChung.luu(dl)
                self.napDuLieu()
            }
        )
    }

    private func hienTienTrinh(_ chu: String) {
        nhanTienTrinh.text = chu
        lopPhuTai.isHidden = false
        vongQuay.startAnimating()
    }

    private func anTienTrinh() {
        vongQuay.stopAnimating()
        lopPhuTai.isHidden = true
    }

    // MARK: - Sửa / Thêm / Xoá Ngành hàng Thi đua

    @objc private func bamThemDongThuCong() {
        let moi = DongThiDua(tenNganhHang: "T11 - ", loaiChiTieu: .doanhThu, thucHien: 0, target: 0)
        moHopThoaiSuaDong(moi, laThemMoi: true)
    }

    private func moHopThoaiSuaDong(_ dong: DongThiDua, laThemMoi: Bool = false) {
        let cheDoSua = cheDoDoanhThu
        let hop = UIAlertController(
            title: laThemMoi ? "Thêm ngành hàng (\(cheDoSua.tieuDe))" : "Sửa ngành hàng (\(cheDoSua.tieuDe))",
            message: nil,
            preferredStyle: .alert
        )
        hop.addTextField { tf in
            tf.placeholder = "Tên ngành hàng (VD: T11 - Cáp sạc)"
            tf.text = dong.tenNganhHang
        }
        hop.addTextField { tf in
            tf.placeholder = "ĐVT: DT hoặc SL"
            tf.text = dong.loaiChiTieu.maBang
            tf.autocapitalizationType = .allCharacters
        }
        hop.addTextField { tf in
            tf.placeholder = "Thực hiện (VD: 12.73)"
            tf.keyboardType = .decimalPad
            if !laThemMoi { tf.text = String(dong.thucHien) }
        }
        hop.addTextField { tf in
            tf.placeholder = "Target (VD: 127.66)"
            tf.keyboardType = .decimalPad
            if !laThemMoi { tf.text = String(dong.target) }
        }
        if cheDoSua == .luyKe {
            hop.addTextField { tf in
                tf.placeholder = "DT/SL Dự kiến cuối tháng (VD: 169.87)"
                tf.keyboardType = .decimalPad
                if !laThemMoi, let dk = dong.duKienGoc, dk > 0 {
                    tf.text = String(dk)
                }
            }
            hop.addTextField { tf in
                tf.placeholder = "% Dự kiến hoàn thành (VD: 133.1)"
                tf.keyboardType = .decimalPad
                if !laThemMoi, let ptDB = dong.phanTramDuBaoGoc, ptDB > 0 {
                    tf.text = String(ptDB)
                }
            }
        }

        hop.addAction(UIAlertAction(title: "Lưu", style: .default) { [weak self] _ in
            guard let self = self, let tfs = hop.textFields, tfs.count >= 4 else { return }
            let tenNhap = (tfs[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !tenNhap.isEmpty else { return }
            let dvt = (tfs[1].text ?? "DT").uppercased()
            let loai: LoaiChiTieuThiDua = dvt.contains("SL") ? .soLuong : .doanhThu
            let th = self.docSoTuO(tfs[2].text)
            let tg = self.docSoTuO(tfs[3].text)

            var dkMoi = dong.duKienGoc
            var ptDBMoi = dong.phanTramDuBaoGoc
            if cheDoSua == .luyKe && tfs.count >= 6 {
                let vDK = self.docSoTuO(tfs[4].text)
                let vPTDB = self.docSoTuO(tfs[5].text)
                dkMoi = vDK > 0 ? vDK : nil
                ptDBMoi = vPTDB > 0 ? vPTDB : nil
            }

            let capNhat = DongThiDua(
                id: dong.id,
                tenNganhHangGoc: tenNhap,
                tenNganhHang: tenNhap,
                loaiChiTieu: loai,
                thucHien: th,
                target: tg,
                phanTramHTGoc: dong.phanTramHTGoc,
                phanTramDuBaoGoc: ptDBMoi,
                duKienGoc: dkMoi
            )

            var dl = KhoDuLieu.dungChung.duLieu(cho: self.ngayHienTai)
            var ds = dl.danhSachThiDua(theo: cheDoSua)
            if laThemMoi {
                ds.append(capNhat)
            } else if let idx = ds.firstIndex(where: { $0.id == dong.id }) {
                ds[idx] = capNhat
            }
            dl.ganDanhSachThiDua(ds, theo: cheDoSua)
            KhoDuLieu.dungChung.luu(dl)
            self.napDuLieu()
        })

        if !laThemMoi {
            hop.addAction(UIAlertAction(title: "Xoá ngành hàng này", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                var dl = KhoDuLieu.dungChung.duLieu(cho: self.ngayHienTai)
                var ds = dl.danhSachThiDua(theo: cheDoSua)
                ds.removeAll { $0.id == dong.id }
                dl.ganDanhSachThiDua(ds, theo: cheDoSua)
                KhoDuLieu.dungChung.luu(dl)
                self.napDuLieu()
            })
        }

        hop.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        present(hop, animated: true)
    }

    // MARK: - Chọn ngày & Xuất báo cáo (Yêu cầu 2 & 4: các dòng text có cỡ chữ bằng nhau, dài tự xuống dòng, không có dấu "...")

    @objc private func moLichSuNgay() {
        let lich = TienIchNgay.lich
        let homNay = lich.startOfDay(for: Date())
        let khoaHienTai = TienIchNgay.khoa.string(from: ngayHienTai)

        var tapKhoaNgay = Set<String>()
        for i in 0..<15 {
            if let d = lich.date(byAdding: .day, value: -i, to: homNay) {
                tapKhoaNgay.insert(TienIchNgay.khoa.string(from: d))
            }
        }
        for khoa in KhoDuLieu.dungChung.cacNgay.keys {
            tapKhoaNgay.insert(khoa)
        }

        var cacMuc: [MucChonDMX] = []
        for khoa in tapKhoaNgay.sorted(by: >).prefix(20) {
            guard let d = TienIchNgay.khoa.date(from: khoa) else { continue }
            let tieuDeNgay = TienIchNgay.hienThiNgay.string(from: d)
            cacMuc.append(MucChonDMX(tieuDe: tieuDeNgay, dangChon: khoa == khoaHienTai) { [weak self] in
                self?.ngayHienTai = d
                self?.napDuLieu()
            })
        }
        cacMuc.append(MucChonDMX(tieuDe: "Đóng", kieu: .huy))

        hienMenuChon(tieuDe: "Chọn ngày xem báo cáo", cacMuc: cacMuc, canGiuaText: true)
    }

    @objc private func moMenuXuatBaoCao() {
        let dl = KhoDuLieu.dungChung.duLieu(cho: ngayHienTai)
        let kieu = KhoDuLieu.dungChung.caiDat.kieuHienThi
        let moTaKieu = (kieu == .bangChiTiet) ? "Bảng 8 cột" : "Thẻ \(KhoDuLieu.dungChung.caiDat.soCotXuatAnh) cột"
        let cheDoNV = cheDoDoanhThu
        let cheDoCSV = cheDoDoanhThu
        let dtDangChon = (cheDoCSV == .luyKe) ? dl.doanhThu : dl.doanhThuRealtime
        let dsDangChon = dl.danhSachThiDua(theo: cheDoCSV)

        let cacMuc: [MucChonDMX] = [
            MucChonDMX(tieuDe: "📰 Mở mục Báo cáo & Phân tích AI Gemini → Gửi LINE") { [weak self] in
                self?.mucMenuChinh = .baoCao
                self?.napDuLieu()
            },
            MucChonDMX(tieuDe: "🖼️ Mở mục 3. Xuất ảnh (Có ô Text báo cáo + Copy gửi LINE)") { [weak self] in
                self?.mucMenuChinh = .doSoXemSo
                self?.mucConDoSo = .xuatAnh
                self?.napDuLieu()
            },
            MucChonDMX(tieuDe: "📗 Xuất file Excel (.xlsx) (Đầy đủ 4 Sheet báo cáo)") { [weak self] in
                guard let self = self else { return }
                let s = KhoDuLieu.dungChung.taoSoLieuBanTin(cho: self.ngayHienTai, khung: KhungBanTin.theoGio())
                let text = BoVietBanTin(soLieu: s, giong: .binhThuong).vietTheoMauAnhChup()
                guard let url = BoXuatOfficeDMX.xuatFileExcelXLSX(ngay: self.ngayHienTai, noiDungPhanTich: text) else { return }
                self.chiaSe([url])
            },
            MucChonDMX(tieuDe: "📙 Xuất file PowerPoint (.pptx) (4 Slide báo cáo)") { [weak self] in
                guard let self = self else { return }
                let s = KhoDuLieu.dungChung.taoSoLieuBanTin(cho: self.ngayHienTai, khung: KhungBanTin.theoGio())
                let text = BoVietBanTin(soLieu: s, giong: .binhThuong).vietTheoMauAnhChup()
                guard let url = BoXuatOfficeDMX.xuatFilePowerPointPPTX(ngay: self.ngayHienTai, noiDungPhanTich: text) else { return }
                self.chiaSe([url])
            },
            MucChonDMX(tieuDe: "📊 Ảnh Thi đua Lũy kế — Thực hiện & Target (\(moTaKieu))") { [weak self] in
                guard let self = self,
                      let anh = self.bangThiDua.taoAnhBaoCao(
                          ngay: self.ngayHienTai,
                          doanhThu: dl.doanhThu,
                          danhSach: dl.danhSachThiDua,
                          cheDoDoanhThu: .luyKe,
                          xemDuKien: false,
                          thongTinDonVi: dl.thongTinDonVi,
                          capNhatLuc: dl.capNhatLuc
                      ) else { return }
                self.chiaSe([anh])
            },
            MucChonDMX(tieuDe: "📈 Ảnh Thi đua Lũy kế — % Dự kiến cuối tháng (\(moTaKieu))") { [weak self] in
                guard let self = self,
                      let anh = self.bangThiDua.taoAnhBaoCao(
                          ngay: self.ngayHienTai,
                          doanhThu: dl.doanhThu,
                          danhSach: dl.danhSachThiDua,
                          cheDoDoanhThu: .luyKe,
                          xemDuKien: true,
                          thongTinDonVi: dl.thongTinDonVi,
                          capNhatLuc: dl.capNhatLuc
                      ) else { return }
                self.chiaSe([anh])
            },
            MucChonDMX(tieuDe: "⚡ Ảnh Thi đua — Realtime (\(moTaKieu))") { [weak self] in
                guard let self = self,
                      let anh = self.bangThiDua.taoAnhBaoCao(
                          ngay: self.ngayHienTai,
                          doanhThu: dl.doanhThuRealtime,
                          danhSach: dl.danhSachThiDuaRealtime,
                          cheDoDoanhThu: .realtime,
                          xemDuKien: false,
                          thongTinDonVi: dl.thongTinDonVi,
                          capNhatLuc: dl.capNhatLuc
                      ) else { return }
                self.chiaSe([anh])
            },
            MucChonDMX(tieuDe: "👥 Ảnh Bảng Xếp Hạng Nhân Viên (\(cheDoNV.tieuDe))") { [weak self] in
                guard let self = self else { return }
                self.bangNhanVien.capNhat(cho: self.ngayHienTai, cheDo: cheDoNV)
                guard let anh = self.bangNhanVien.taoAnhBaoCaoNhanVien(
                    ngay: self.ngayHienTai,
                    cheDo: cheDoNV,
                    thongTinDonVi: dl.thongTinDonVi,
                    capNhatLuc: dl.capNhatLuc
                ) else { return }
                self.chiaSe([anh])
            },
            MucChonDMX(tieuDe: "❤️‍🩹 Ảnh Biểu Đồ Sức Khỏe 16 NV & Cảnh Báo Top 5 Yếu") { [weak self] in
                guard let self = self,
                      let anh = self.bangRealtimeThang.taoAnhBaoCaoSucKhoeNhanVien(
                          ngay: self.ngayHienTai,
                          thongTinDonVi: dl.thongTinDonVi,
                          capNhatLuc: dl.capNhatLuc
                      ) else { return }
                self.chiaSe([anh])
            },
            MucChonDMX(tieuDe: "👤 Ảnh Chi Tiết Từng Nhân Viên (\(cheDoNV.tieuDe))") { [weak self] in
                self?.moChonNhanVienChiaSeAnh(cheDo: cheDoNV)
            },
            MucChonDMX(tieuDe: "📈 Ảnh Biểu Đồ & Tổng Hợp Realtime Tháng (Toàn bộ bảng)") { [weak self] in
                guard let self = self,
                      let anh = self.bangRealtimeThang.taoAnhBaoCaoRealtimeThang(
                          ngay: self.ngayHienTai,
                          thongTinDonVi: dl.thongTinDonVi,
                          capNhatLuc: dl.capNhatLuc
                      ) else { return }
                self.chiaSe([anh])
            },
            MucChonDMX(tieuDe: "📑 Xuất file Biểu Đồ & Realtime Tháng (.csv)") { [weak self] in
                guard let self = self else { return }
                let csv = self.bangRealtimeThang.taoChuoiExcelCSVBieuDoThang(
                    ngay: self.ngayHienTai,
                    thongTinDonVi: dl.thongTinDonVi,
                    capNhatLuc: dl.capNhatLuc
                )
                let tenTep = "BieuDo-RealtimeThang-\(dl.khoaNgay.prefix(7)).csv"
                let duongDan = FileManager.default.temporaryDirectory.appendingPathComponent(tenTep)
                try? csv.write(to: duongDan, atomically: true, encoding: .utf8)
                self.chiaSe([duongDan])
            },
            MucChonDMX(tieuDe: "📄 Xuất file Excel (.csv) (\(cheDoCSV.tieuDe) + Biểu đồ)") { [weak self] in
                guard let self = self else { return }
                let csvThiDua = self.bangThiDua.taoChuoiExcelCSV(doanhThu: dtDangChon, danhSach: dsDangChon, cheDo: cheDoCSV, ngay: self.ngayHienTai)
                let csvBieuDo = self.bangRealtimeThang.taoChuoiExcelCSVBieuDoThang(
                    ngay: self.ngayHienTai,
                    thongTinDonVi: dl.thongTinDonVi,
                    capNhatLuc: dl.capNhatLuc
                ).replacingOccurrences(of: "\u{FEFF}", with: "")
                let csvGop = csvThiDua + "\n\n" + csvBieuDo
                let hauTo = (cheDoCSV == .luyKe) ? "LuyKe" : "Realtime"
                let tenTep = "TongHopDMX-\(dl.khoaNgay)-\(hauTo).csv"
                let duongDan = FileManager.default.temporaryDirectory.appendingPathComponent(tenTep)
                try? csvGop.write(to: duongDan, atomically: true, encoding: .utf8)
                self.chiaSe([duongDan])
            },
            MucChonDMX(tieuDe: "Đóng", kieu: .huy)
        ]

        hienMenuChon(
            tieuDe: "Chia sẻ ảnh & Xuất báo cáo",
            thongDiep: "Chọn loại ảnh hoặc file dữ liệu báo cáo bạn muốn chia sẻ hoặc lưu về máy:",
            cacMuc: cacMuc
        )
    }

    private func moChonNhanVienChiaSeAnh(cheDo: LoaiCheDoDoanhThu) {
        let dsNV = KhoDuLieu.dungChung.tongHopNhanVien(den: ngayHienTai, sapXep: .soMonHoanThanh, cheDo: cheDo)
        guard !dsNV.isEmpty else { return }

        var cacMuc: [MucChonDMX] = [
            MucChonDMX(tieuDe: "📚 Xuất TẤT CẢ \(dsNV.count) NV đang quản lý (Bộ \(dsNV.count) ảnh rời)") { [weak self] in
                guard let self = self else { return }
                let cacAnh = ManHinhChiTietNhanVien.taoTatCaAnhSucKhoe(cho: self.ngayHienTai, cheDo: cheDo)
                guard !cacAnh.isEmpty else { return }
                self.chiaSe(cacAnh)
            },
            MucChonDMX(tieuDe: "🖼️ Xuất TẤT CẢ \(dsNV.count) NV đang quản lý (Gộp 1 ảnh tổng hợp)") { [weak self] in
                guard let self = self,
                      let anhGop = ManHinhChiTietNhanVien.taoAnhGopTatCaSucKhoe(cho: self.ngayHienTai, cheDo: cheDo) else { return }
                self.chiaSe([anhGop])
            }
        ]

        for (i, item) in dsNV.enumerated() {
            let tieuDe = "👤 \(i + 1). \(item.nhanVien.hoTen) (\(item.soMonDat)/\(item.tongMonGiao) môn • \(String(format: "%.1f%%", item.phanTramHTTB)))"
            cacMuc.append(MucChonDMX(tieuDe: tieuDe) { [weak self] in
                guard let self = self,
                      let anh = ManHinhChiTietNhanVien.taoAnhSucKhoe(cho: item, ngay: self.ngayHienTai, cheDo: cheDo) else { return }
                self.chiaSe([anh])
            })
        }
        cacMuc.append(MucChonDMX(tieuDe: "Đóng", kieu: .huy))

        hienMenuChon(
            tieuDe: "Xuất ảnh Sức khoẻ Nhân viên (\(cheDo.tieuDe))",
            thongDiep: "Chọn xuất tất cả \(dsNV.count) nhân viên đang quản lý hoặc chọn 1 nhân viên cụ thể:",
            cacMuc: cacMuc
        )
    }

    private func chiaSe(_ muc: [Any]) {
        let vc = UIActivityViewController(activityItems: muc, applicationActivities: nil)
        if let pop = vc.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: 80, width: 1, height: 1)
        }
        present(vc, animated: true)
    }
}
