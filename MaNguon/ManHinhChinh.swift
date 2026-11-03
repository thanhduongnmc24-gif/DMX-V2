import UIKit
import PhotosUI

final class ManHinhChinh: UIViewController, PHPickerViewControllerDelegate {
    private enum CheDoQuetAnh {
        case doanhThu(LoaiCheDoDoanhThu)
        case thiDua(LoaiCheDoDoanhThu)
        case thiDuaNhanVien(LoaiCheDoDoanhThu)
        case doanhThuNhanVien(LoaiCheDoDoanhThu)
        case tatCaAnhTheoTab(LoaiCheDoDoanhThu)
    }

    private var ngayHienTai = TienIchNgay.lich.startOfDay(for: Date())
    private var tabHienTai: LoaiTabMuc = .thiDua
    private var tabCumDuoiGanNhat: LoaiTabMuc = .thiDua
    private var cheDoDoanhThu: LoaiCheDoDoanhThu = .luyKe
    private var cheDoQuet: CheDoQuetAnh = .thiDua(.luyKe)
    private var thayTheBangThiDuaKhiQuet: Bool = false

    // Bộ nhớ đệm trạng thái bảng để bấm chuyển qua lại giữa các tab mượt tức thì (0ms) không dựng lại cell thừa
    private var dsThiDuaDaNapUI: [DongThiDua]?
    private var cheDoThiDuaDaNapUI: LoaiCheDoDoanhThu?
    private var kieuHienThiDaNapUI: KieuHienThiBaoCao?

    private let nutNgay = UIButton(type: .system)
    private let nutNhapTatCa = UIButton(type: .system)
    private let nutXuatNav = UIButton(type: .system)
    private let nutCaiDatNav = UIButton(type: .system)

    // Khung viền ngăn cách rõ ràng giữa Cụm Doanh thu và Cụm Thi đua / Nhân viên
    private let khungCumDoanhThu = UIView()
    private let vachNganHaiCum = UIView()
    private let khungCumDuoi = UIView()
    private var rangBuocCaoCumChiSo: NSLayoutConstraint?
    private var rangBuocBangRongHaiNutNV: NSLayoutConstraint?

    // 1. Cụm Tiến độ tháng & 8 thẻ Chỉ số chính (Lũy kế | Realtime | Biểu đồ)
    private let cumChiSoChinh = CumChiSoChinhView(coLon: false)

    // 2. Cụm 2 nút phía dưới cụm Doanh thu: Thi đua | Nhân viên (đã xoá nút Dự phòng 3)
    private var cacNutMuc: [UIButton] = []
    private var hangBaNut: UIStackView!
    private var hangNutQuet: UIStackView!

    // 3. Cụm nút Quét / Thêm ảnh mới & Xoá nằm ngay dưới cụm nút mục
    private let nutThemAnhMoi = UIButton(type: .system)
    private let nutNhapDoanhThuNV = UIButton(type: .system)
    private let nutXoaQuetLai = UIButton(type: .system)
    private let nutThemThuCong = UIButton(type: .system)

    // 4. Nội dung của từng mục
    private let bangThiDua = BangThiDuaView()
    private let bangNhanVien = BangNhanVienView()
    private let bangRealtimeThang = BangTongHopRealtimeThangView()

    // Hộp thoại tiến trình quét
    private let lopPhuTai = UIView()
    private let nhanTienTrinh = UILabel()
    private let vongQuay = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
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

    // MARK: - Thanh điều hướng trên cùng

    private func cauHinhThanhDieuHuong() {
        nutNgay.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        nutNgay.titleLabel?.numberOfLines = 0
        nutNgay.titleLabel?.lineBreakMode = .byWordWrapping
        nutNgay.titleLabel?.adjustsFontSizeToFitWidth = false
        nutNgay.addTarget(self, action: #selector(moLichSuNgay), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: nutNgay)

        nutNhapTatCa.setImage(UIImage(systemName: "photo.stack.fill"), for: .normal)
        nutNhapTatCa.setTitle(" Nhập tất cả", for: .normal)
        nutNhapTatCa.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        nutNhapTatCa.titleLabel?.numberOfLines = 0
        nutNhapTatCa.titleLabel?.lineBreakMode = .byWordWrapping
        nutNhapTatCa.titleLabel?.textAlignment = .center
        nutNhapTatCa.titleLabel?.adjustsFontSizeToFitWidth = false
        nutNhapTatCa.backgroundColor = .systemBlue
        nutNhapTatCa.tintColor = .white
        nutNhapTatCa.layer.cornerRadius = 15
        nutNhapTatCa.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        nutNhapTatCa.setContentHuggingPriority(.required, for: .horizontal)
        nutNhapTatCa.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutNhapTatCa.addTarget(self, action: #selector(bamNhapTatCaAnh), for: .touchUpInside)

        let cauHinhIcon = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        nutXuatNav.setImage(UIImage(systemName: "square.and.arrow.up", withConfiguration: cauHinhIcon), for: .normal)
        nutXuatNav.tintColor = .systemBlue
        nutXuatNav.backgroundColor = .secondarySystemGroupedBackground
        nutXuatNav.layer.cornerRadius = 8
        nutXuatNav.translatesAutoresizingMaskIntoConstraints = false
        nutXuatNav.widthAnchor.constraint(equalToConstant: 34).isActive = true
        nutXuatNav.heightAnchor.constraint(equalToConstant: 32).isActive = true
        nutXuatNav.addTarget(self, action: #selector(moMenuXuatBaoCao), for: .touchUpInside)

        nutCaiDatNav.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: cauHinhIcon), for: .normal)
        nutCaiDatNav.tintColor = .systemBlue
        nutCaiDatNav.backgroundColor = .secondarySystemGroupedBackground
        nutCaiDatNav.layer.cornerRadius = 8
        nutCaiDatNav.translatesAutoresizingMaskIntoConstraints = false
        nutCaiDatNav.widthAnchor.constraint(equalToConstant: 34).isActive = true
        nutCaiDatNav.heightAnchor.constraint(equalToConstant: 32).isActive = true
        nutCaiDatNav.addTarget(self, action: #selector(moCaiDat), for: .touchUpInside)

        let cumPhai = UIStackView(arrangedSubviews: [nutNhapTatCa, nutXuatNav, nutCaiDatNav])
        cumPhai.axis = .horizontal
        cumPhai.spacing = 6
        cumPhai.alignment = .center
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cumPhai)
    }

    @objc private func moCaiDat() {
        navigationController?.pushViewController(ManHinhCaiDat(ngay: ngayHienTai), animated: true)
    }

    @objc private func bamNhapTatCaAnh() {
        moChonAnh(cheDo: .tatCaAnhTheoTab(cheDoDoanhThu), gioiHan: 0)
    }

    // MARK: - Dựng giao diện chính

    private func taoGiaoDien() {
        khungCumDoanhThu.backgroundColor = .secondarySystemGroupedBackground
        khungCumDoanhThu.layer.cornerRadius = 14
        khungCumDoanhThu.layer.borderWidth = 1.5
        khungCumDoanhThu.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.38).cgColor

        vachNganHaiCum.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.28)
        vachNganHaiCum.layer.cornerRadius = 1

        khungCumDuoi.backgroundColor = .secondarySystemGroupedBackground
        khungCumDuoi.layer.cornerRadius = 14
        khungCumDuoi.layer.borderWidth = 1.5
        khungCumDuoi.layer.borderColor = UIColor.separator.cgColor

        // 1. Cụm Tiến độ tháng & 8 thẻ Chỉ số chính (Lũy kế | Realtime | Biểu đồ)
        cumChiSoChinh.addTarget(self, action: #selector(bamTheDoanhThu), for: .touchUpInside)
        cumChiSoChinh.khiBamVungThe = { [weak self] in
            self?.bamTheDoanhThu()
        }
        cumChiSoChinh.khiDoiCheDoDoanhThu = { [weak self] cheDoMoi in
            guard let self = self else { return }
            self.cheDoDoanhThu = cheDoMoi
            if self.tabHienTai == .duPhong2 {
                self.tabHienTai = self.tabCumDuoiGanNhat
            }
            self.napDuLieu()
        }
        cumChiSoChinh.khiBamBieuDo = { [weak self] in
            guard let self = self else { return }
            guard self.tabHienTai != .duPhong2 else { return }
            self.tabHienTai = .duPhong2
            self.capNhatTrangThaiMuc()
            self.bangRealtimeThang.capNhat(cho: self.ngayHienTai)
        }

        // 2. Cụm 2 nút phía dưới cụm Doanh thu (Thi đua | Nhân viên) — đã xoá Dự phòng 3
        cacNutMuc = LoaiTabMuc.cacTabCumDuoi.map { loai in
            let nut = UIButton(type: .custom)
            nut.tag = loai.rawValue
            nut.setTitle(loai.tieuDe, for: .normal)
            nut.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
            nut.titleLabel?.numberOfLines = 0
            nut.titleLabel?.lineBreakMode = .byWordWrapping
            nut.titleLabel?.textAlignment = .center
            nut.titleLabel?.adjustsFontSizeToFitWidth = false
            nut.contentEdgeInsets = UIEdgeInsets(top: 5, left: 6, bottom: 5, right: 6)
            nut.layer.cornerRadius = 10
            nut.layer.borderWidth = 1
            nut.addTarget(self, action: #selector(bamChonMuc(_:)), for: .touchUpInside)
            return nut
        }

        hangBaNut = UIStackView(arrangedSubviews: cacNutMuc)
        hangBaNut.axis = .horizontal
        hangBaNut.spacing = 6
        hangBaNut.distribution = .fillEqually

        // 3. Thanh nút Quét & Xoá (Ở Nhân viên: 2 nút Nhập ảnh Thi đua NV và Nhập ảnh Doanh thu nằm cùng hàng với nhau; không có nút Nhập/Mẫu)
        nutThemAnhMoi.setImage(UIImage(systemName: "camera.viewfinder"), for: .normal)
        nutThemAnhMoi.setTitle(" Thêm ảnh", for: .normal)
        nutThemAnhMoi.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutThemAnhMoi.titleLabel?.numberOfLines = 0
        nutThemAnhMoi.titleLabel?.lineBreakMode = .byWordWrapping
        nutThemAnhMoi.titleLabel?.textAlignment = .center
        nutThemAnhMoi.titleLabel?.adjustsFontSizeToFitWidth = false
        nutThemAnhMoi.backgroundColor = .systemBlue
        nutThemAnhMoi.tintColor = .white
        nutThemAnhMoi.layer.cornerRadius = 10
        nutThemAnhMoi.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        nutThemAnhMoi.addTarget(self, action: #selector(bamThemAnhMoi), for: .touchUpInside)

        nutNhapDoanhThuNV.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        nutNhapDoanhThuNV.setTitle(" Nhập ảnh Doanh thu", for: .normal)
        nutNhapDoanhThuNV.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutNhapDoanhThuNV.titleLabel?.numberOfLines = 0
        nutNhapDoanhThuNV.titleLabel?.lineBreakMode = .byWordWrapping
        nutNhapDoanhThuNV.titleLabel?.textAlignment = .center
        nutNhapDoanhThuNV.titleLabel?.adjustsFontSizeToFitWidth = false
        nutNhapDoanhThuNV.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.14)
        nutNhapDoanhThuNV.tintColor = .systemBlue
        nutNhapDoanhThuNV.layer.cornerRadius = 10
        nutNhapDoanhThuNV.layer.borderWidth = 1
        nutNhapDoanhThuNV.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.35).cgColor
        nutNhapDoanhThuNV.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        nutNhapDoanhThuNV.addTarget(self, action: #selector(bamNhapAnhDoanhThuNV), for: .touchUpInside)

        nutXoaQuetLai.setTitle(" Xoá", for: .normal)
        nutXoaQuetLai.setImage(UIImage(systemName: "trash.fill"), for: .normal)
        nutXoaQuetLai.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutXoaQuetLai.titleLabel?.numberOfLines = 0
        nutXoaQuetLai.titleLabel?.lineBreakMode = .byWordWrapping
        nutXoaQuetLai.titleLabel?.textAlignment = .center
        nutXoaQuetLai.titleLabel?.adjustsFontSizeToFitWidth = false
        nutXoaQuetLai.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
        nutXoaQuetLai.tintColor = .systemRed
        nutXoaQuetLai.layer.cornerRadius = 10
        nutXoaQuetLai.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        nutXoaQuetLai.addTarget(self, action: #selector(bamXoaQuetLai), for: .touchUpInside)

        nutThemThuCong.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        nutThemThuCong.setTitle(" Nhập/Mẫu", for: .normal)
        nutThemThuCong.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutThemThuCong.titleLabel?.numberOfLines = 0
        nutThemThuCong.titleLabel?.lineBreakMode = .byWordWrapping
        nutThemThuCong.titleLabel?.textAlignment = .center
        nutThemThuCong.titleLabel?.adjustsFontSizeToFitWidth = false
        nutThemThuCong.backgroundColor = .tertiarySystemGroupedBackground
        nutThemThuCong.tintColor = .label
        nutThemThuCong.layer.cornerRadius = 10
        nutThemThuCong.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        // Yêu cầu 6: Khi ấn vào Nhập/Mẫu ở Thi đua thì mở thẳng bảng thêm ngành hàng thi đua, không hiện menu nhiều dòng
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

        // 4. Nội dung mục Thi đua, Nhân viên & Biểu đồ
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
            self?.moCaiDat()
        }

        bangRealtimeThang.khiBamSuaDoanhThuLuyKe = { [weak self] in
            guard let self = self else { return }
            self.cheDoDoanhThu = .luyKe
            self.napDuLieu()
            self.bamTheDoanhThu()
        }
        bangRealtimeThang.khiChonNgayRealtime = { [weak self] item in
            self?.moMenuRealtimeChoNgay(item)
        }

        cumChiSoChinh.translatesAutoresizingMaskIntoConstraints = false
        khungCumDoanhThu.addSubview(cumChiSoChinh)

        [hangBaNut, hangNutQuet, bangThiDua, bangNhanVien, bangRealtimeThang].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            khungCumDuoi.addSubview($0)
        }

        [khungCumDoanhThu, vachNganHaiCum, khungCumDuoi].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        let rgCaoCum = cumChiSoChinh.heightAnchor.constraint(equalToConstant: 184)
        rangBuocCaoCumChiSo = rgCaoCum

        NSLayoutConstraint.activate([
            khungCumDoanhThu.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            khungCumDoanhThu.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            khungCumDoanhThu.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),

            cumChiSoChinh.topAnchor.constraint(equalTo: khungCumDoanhThu.topAnchor, constant: 8),
            cumChiSoChinh.leadingAnchor.constraint(equalTo: khungCumDoanhThu.leadingAnchor, constant: 8),
            cumChiSoChinh.trailingAnchor.constraint(equalTo: khungCumDoanhThu.trailingAnchor, constant: -8),
            cumChiSoChinh.bottomAnchor.constraint(equalTo: khungCumDoanhThu.bottomAnchor, constant: -8),
            rgCaoCum,

            vachNganHaiCum.topAnchor.constraint(equalTo: khungCumDoanhThu.bottomAnchor, constant: 5),
            vachNganHaiCum.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            vachNganHaiCum.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            vachNganHaiCum.heightAnchor.constraint(equalToConstant: 2),

            khungCumDuoi.topAnchor.constraint(equalTo: vachNganHaiCum.bottomAnchor, constant: 5),
            khungCumDuoi.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            khungCumDuoi.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            khungCumDuoi.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4),

            hangBaNut.topAnchor.constraint(equalTo: khungCumDuoi.topAnchor, constant: 8),
            hangBaNut.leadingAnchor.constraint(equalTo: khungCumDuoi.leadingAnchor, constant: 8),
            hangBaNut.trailingAnchor.constraint(equalTo: khungCumDuoi.trailingAnchor, constant: -8),
            hangBaNut.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),

            hangNutQuet.topAnchor.constraint(equalTo: hangBaNut.bottomAnchor, constant: 6),
            hangNutQuet.leadingAnchor.constraint(equalTo: khungCumDuoi.leadingAnchor, constant: 8),
            hangNutQuet.trailingAnchor.constraint(equalTo: khungCumDuoi.trailingAnchor, constant: -8),
            hangNutQuet.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),

            bangThiDua.topAnchor.constraint(equalTo: hangNutQuet.bottomAnchor, constant: 8),
            bangThiDua.leadingAnchor.constraint(equalTo: khungCumDuoi.leadingAnchor, constant: 6),
            bangThiDua.trailingAnchor.constraint(equalTo: khungCumDuoi.trailingAnchor, constant: -6),
            bangThiDua.bottomAnchor.constraint(equalTo: khungCumDuoi.bottomAnchor, constant: -6),

            bangNhanVien.topAnchor.constraint(equalTo: hangNutQuet.bottomAnchor, constant: 8),
            bangNhanVien.leadingAnchor.constraint(equalTo: khungCumDuoi.leadingAnchor, constant: 2),
            bangNhanVien.trailingAnchor.constraint(equalTo: khungCumDuoi.trailingAnchor, constant: -2),
            bangNhanVien.bottomAnchor.constraint(equalTo: khungCumDuoi.bottomAnchor, constant: -6),

            bangRealtimeThang.topAnchor.constraint(equalTo: khungCumDuoi.topAnchor, constant: 8),
            bangRealtimeThang.leadingAnchor.constraint(equalTo: khungCumDuoi.leadingAnchor, constant: 6),
            bangRealtimeThang.trailingAnchor.constraint(equalTo: khungCumDuoi.trailingAnchor, constant: -6),
            bangRealtimeThang.bottomAnchor.constraint(equalTo: khungCumDuoi.bottomAnchor, constant: -6)
        ])

        taoLopPhuTienTrinh()
        capNhatTrangThaiMuc()
    }

    private func taoLopPhuTienTrinh() {
        lopPhuTai.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        lopPhuTai.isHidden = true
        lopPhuTai.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lopPhuTai)

        let hop = UIView()
        hop.backgroundColor = .systemBackground
        hop.layer.cornerRadius = 16
        hop.translatesAutoresizingMaskIntoConstraints = false
        lopPhuTai.addSubview(hop)

        vongQuay.color = .systemBlue
        vongQuay.translatesAutoresizingMaskIntoConstraints = false

        nhanTienTrinh.font = .systemFont(ofSize: 14, weight: .semibold)
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

    // MARK: - Nạp dữ liệu & Chuyển đổi mượt mà giữa các mục

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
            dangXemBieuDo: (tabHienTai == .duPhong2)
        )

        capNhatTrangThaiMuc()
        capNhatNoiDungTabDangChon(dl: dl, dsThiDuaDangChon: dsThiDuaDangChon)
    }

    private func capNhatNoiDungTabDangChon(dl: DuLieuNgayDMX? = nil, dsThiDuaDangChon: [DongThiDua]? = nil) {
        switch tabHienTai {
        case .thiDua:
            let duLieu = dl ?? KhoDuLieu.dungChung.duLieu(cho: ngayHienTai)
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
        case .duPhong2:
            bangRealtimeThang.capNhat(cho: ngayHienTai)
        }
    }

    @objc private func bamChonMuc(_ sender: UIButton) {
        guard let loai = LoaiTabMuc(rawValue: sender.tag), loai != tabHienTai else { return }
        tabHienTai = loai
        if loai != .duPhong2 {
            tabCumDuoiGanNhat = loai
        }
        capNhatTrangThaiMuc()
        capNhatNoiDungTabDangChon()
    }

    private func capNhatTrangThaiMuc() {
        for nut in cacNutMuc {
            let loai = LoaiTabMuc(rawValue: nut.tag) ?? .thiDua
            let dangChon = (loai == tabHienTai)
            if dangChon {
                nut.backgroundColor = .systemBlue
                nut.setTitleColor(.white, for: .normal)
                nut.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                nut.backgroundColor = .systemBackground
                nut.setTitleColor(.label, for: .normal)
                nut.layer.borderColor = UIColor.separator.cgColor
            }
        }

        let laThiDua = (tabHienTai == .thiDua)
        let laNhanVien = (tabHienTai == .nhanVien)
        let laBieuDo = (tabHienTai == .duPhong2)

        rangBuocCaoCumChiSo?.constant = laBieuDo ? 38 : 184
        hangBaNut.isHidden = laBieuDo
        hangNutQuet.isHidden = laBieuDo

        let nhanCheDo = cheDoDoanhThu.tieuDe
        if laNhanVien {
            // Yêu cầu 3: Ở chỗ nhân viên, cho 2 nút nhập ảnh thi đua nhân viên và nhập ảnh doanh thu ở cùng hàng với nhau
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

        // Yêu cầu 6: Ở Nhân viên không có nút Nhập/Mẫu; chỉ hiển thị ở Thi đua
        nutThemThuCong.isHidden = !laThiDua
        nutThemThuCong.setTitle(" Nhập/Mẫu", for: .normal)
    }

    // MARK: - Nút Nhập ảnh & Xoá

    @objc private func bamThemAnhMoi() {
        switch tabHienTai {
        case .thiDua:
            moHuongDanQuetAnhThiDua()
        case .nhanVien:
            moChonAnh(cheDo: .thiDuaNhanVien(cheDoDoanhThu), gioiHan: 0)
        case .duPhong2:
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

        if tabHienTai == .nhanVien {
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

        guard tabHienTai == .thiDua else { return }
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
            MucChonDMX(tieuDe: "👤 Ảnh Sức Khoẻ Nhân Viên (\(cheDoNV.tieuDe))") { [weak self] in
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
