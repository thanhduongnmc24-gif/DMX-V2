import UIKit
import PhotosUI

final class ManHinhChinh: UIViewController, PHPickerViewControllerDelegate {
    private enum CheDoQuetAnh {
        case doanhThu(LoaiCheDoDoanhThu)
        case thiDua(LoaiCheDoDoanhThu)
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

    // Khung viền ngăn cách rõ ràng giữa Cụm Doanh thu và Cụm Thi đua / Nhân viên / Dự phòng 3
    private let khungCumDoanhThu = UIView()
    private let vachNganHaiCum = UIView()
    private let khungCumDuoi = UIView()
    private var rangBuocCaoCumChiSo: NSLayoutConstraint?

    // 1. Cụm Tiến độ tháng & 8 thẻ Chỉ số chính (Doanh thu Lũy kế | Doanh thu Realtime | Biểu đồ)
    private let cumChiSoChinh = CumChiSoChinhView(coLon: false)

    // 2. Cụm 3 nút phía dưới cụm Doanh thu: Thi đua | Nhân viên | Dự phòng 3
    private var cacNutMuc: [UIButton] = []
    private var hangBaNut: UIStackView!
    private var hangNutQuet: UIStackView!

    // 3. Cụm nút Quét / Thêm ảnh mới & Xoá quét lại nằm ngay dưới cụm nút mục
    private let nutThemAnhMoi = UIButton(type: .system)
    private let nutXoaQuetLai = UIButton(type: .system)
    private let nutThemThuCong = UIButton(type: .system)

    // 4. Nội dung của từng mục
    private let bangThiDua = BangThiDuaView()
    private let bangNhanVien = BangNhanVienView()
    private let bangRealtimeThang = BangTongHopRealtimeThangView()
    private let khungDuPhong = UIView()
    private let nhanTieuDeDuPhong = UILabel()
    private let nhanMoTaDuPhong = UILabel()

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

    // MARK: - Thanh điều hướng trên cùng (Cố định kích thước để nút Chia sẻ & Cài đặt không bao giờ bị co nhỏ)

    private func cauHinhThanhDieuHuong() {
        nutNgay.titleLabel?.font = .systemFont(ofSize: 13.5, weight: .bold)
        nutNgay.addTarget(self, action: #selector(moLichSuNgay), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: nutNgay)

        // Nút Nhập tất cả cố định kích thước gọn đẹp
        nutNhapTatCa.setImage(UIImage(systemName: "photo.stack.fill"), for: .normal)
        nutNhapTatCa.setTitle(" Nhập tất cả", for: .normal)
        nutNhapTatCa.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        nutNhapTatCa.backgroundColor = .systemBlue
        nutNhapTatCa.tintColor = .white
        nutNhapTatCa.layer.cornerRadius = 15
        nutNhapTatCa.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        nutNhapTatCa.setContentHuggingPriority(.required, for: .horizontal)
        nutNhapTatCa.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutNhapTatCa.addTarget(self, action: #selector(bamNhapTatCaAnh), for: .touchUpInside)

        // Nút Chia sẻ ảnh và Cài đặt cố định khung 34x32 để không bao giờ bị thanh điều hướng bóp nhỏ
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

        // 1. Cụm Tiến độ tháng & 8 thẻ Chỉ số chính (Doanh thu Lũy kế | Doanh thu Realtime | Biểu đồ)
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

        // 2. Cụm 3 nút phía dưới cụm Doanh thu (Thi đua | Nhân viên | Dự phòng 3)
        cacNutMuc = LoaiTabMuc.cacTabCumDuoi.map { loai in
            let nut = UIButton(type: .custom)
            nut.tag = loai.rawValue
            nut.setTitle(loai.tieuDe, for: .normal)
            nut.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
            nut.titleLabel?.adjustsFontSizeToFitWidth = true
            nut.titleLabel?.minimumScaleFactor = 0.8
            nut.layer.cornerRadius = 10
            nut.layer.borderWidth = 1
            nut.addTarget(self, action: #selector(bamChonMuc(_:)), for: .touchUpInside)
            return nut
        }

        hangBaNut = UIStackView(arrangedSubviews: cacNutMuc)
        hangBaNut.axis = .horizontal
        hangBaNut.spacing = 6
        hangBaNut.distribution = .fillEqually

        // 3. Thanh nút Quét (Thêm ảnh lần lượt - Cách 1) & Xoá (Quét lại từ đầu) nằm dưới cụm nút mục
        nutThemAnhMoi.setImage(UIImage(systemName: "camera.viewfinder"), for: .normal)
        nutThemAnhMoi.setTitle(" Thêm ảnh", for: .normal)
        nutThemAnhMoi.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        nutThemAnhMoi.backgroundColor = .systemBlue
        nutThemAnhMoi.tintColor = .white
        nutThemAnhMoi.layer.cornerRadius = 10
        nutThemAnhMoi.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        nutThemAnhMoi.addTarget(self, action: #selector(bamThemAnhMoi), for: .touchUpInside)

        nutXoaQuetLai.setTitle(" Xoá", for: .normal)
        nutXoaQuetLai.setImage(UIImage(systemName: "trash.fill"), for: .normal)
        nutXoaQuetLai.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        nutXoaQuetLai.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
        nutXoaQuetLai.tintColor = .systemRed
        nutXoaQuetLai.layer.cornerRadius = 10
        nutXoaQuetLai.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        nutXoaQuetLai.addTarget(self, action: #selector(bamXoaQuetLai), for: .touchUpInside)

        nutThemThuCong.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        nutThemThuCong.setTitle(" Nhập/Mẫu", for: .normal)
        nutThemThuCong.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .semibold)
        nutThemThuCong.backgroundColor = .tertiarySystemGroupedBackground
        nutThemThuCong.tintColor = .label
        nutThemThuCong.layer.cornerRadius = 10
        nutThemThuCong.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        nutThemThuCong.addTarget(self, action: #selector(moMenuNhapThuCong), for: .touchUpInside)

        hangNutQuet = UIStackView(arrangedSubviews: [nutThemAnhMoi, nutXoaQuetLai, nutThemThuCong])
        hangNutQuet.axis = .horizontal
        hangNutQuet.spacing = 6
        nutThemAnhMoi.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nutThemAnhMoi.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nutXoaQuetLai.setContentHuggingPriority(.required, for: .horizontal)
        nutXoaQuetLai.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutThemThuCong.setContentHuggingPriority(.required, for: .horizontal)
        nutThemThuCong.setContentCompressionResistancePriority(.required, for: .horizontal)

        // 4. Nội dung mục Thi đua, Nhân viên, Biểu đồ & Dự phòng 3
        bangThiDua.khiBamQuetAnh = { [weak self] in
            self?.bamThemAnhMoi()
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
        bangRealtimeThang.khiBamNhapMucTieuQDThang = { [weak self] in
            self?.moHopThoaiNhapMucTieuQDThang()
        }
        bangRealtimeThang.khiChonNgayRealtime = { [weak self] item in
            self?.moMenuRealtimeChoNgay(item)
        }

        taoGiaoDienKhungDuPhong()

        cumChiSoChinh.translatesAutoresizingMaskIntoConstraints = false
        khungCumDoanhThu.addSubview(cumChiSoChinh)

        [hangBaNut, hangNutQuet, bangThiDua, bangNhanVien, bangRealtimeThang, khungDuPhong].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            khungCumDuoi.addSubview($0)
        }

        [khungCumDoanhThu, vachNganHaiCum, khungCumDuoi].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        let rgCaoCum = cumChiSoChinh.heightAnchor.constraint(equalToConstant: 154)
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
            hangBaNut.heightAnchor.constraint(equalToConstant: 36),

            hangNutQuet.topAnchor.constraint(equalTo: hangBaNut.bottomAnchor, constant: 6),
            hangNutQuet.leadingAnchor.constraint(equalTo: khungCumDuoi.leadingAnchor, constant: 8),
            hangNutQuet.trailingAnchor.constraint(equalTo: khungCumDuoi.trailingAnchor, constant: -8),
            hangNutQuet.heightAnchor.constraint(equalToConstant: 36),

            bangThiDua.topAnchor.constraint(equalTo: hangNutQuet.bottomAnchor, constant: 8),
            bangThiDua.leadingAnchor.constraint(equalTo: khungCumDuoi.leadingAnchor, constant: 6),
            bangThiDua.trailingAnchor.constraint(equalTo: khungCumDuoi.trailingAnchor, constant: -6),
            bangThiDua.bottomAnchor.constraint(equalTo: khungCumDuoi.bottomAnchor, constant: -6),

            bangNhanVien.topAnchor.constraint(equalTo: hangNutQuet.bottomAnchor, constant: 8),
            bangNhanVien.leadingAnchor.constraint(equalTo: khungCumDuoi.leadingAnchor, constant: 2),
            bangNhanVien.trailingAnchor.constraint(equalTo: khungCumDuoi.trailingAnchor, constant: -2),
            bangNhanVien.bottomAnchor.constraint(equalTo: khungCumDuoi.bottomAnchor, constant: -6),

            // Ở tab Biểu đồ: bỏ các nút Thi đua/Nhân viên/Dự phòng 3 và bỏ nút Quét/Xoá/Nhập đi, nên Biểu đồ neo thẳng lên đỉnh khung dưới
            bangRealtimeThang.topAnchor.constraint(equalTo: khungCumDuoi.topAnchor, constant: 8),
            bangRealtimeThang.leadingAnchor.constraint(equalTo: khungCumDuoi.leadingAnchor, constant: 6),
            bangRealtimeThang.trailingAnchor.constraint(equalTo: khungCumDuoi.trailingAnchor, constant: -6),
            bangRealtimeThang.bottomAnchor.constraint(equalTo: khungCumDuoi.bottomAnchor, constant: -6),

            khungDuPhong.topAnchor.constraint(equalTo: hangNutQuet.bottomAnchor, constant: 8),
            khungDuPhong.leadingAnchor.constraint(equalTo: khungCumDuoi.leadingAnchor, constant: 6),
            khungDuPhong.trailingAnchor.constraint(equalTo: khungCumDuoi.trailingAnchor, constant: -6),
            khungDuPhong.bottomAnchor.constraint(equalTo: khungCumDuoi.bottomAnchor, constant: -6)
        ])

        taoLopPhuTienTrinh()
        capNhatTrangThaiMuc()
    }

    private func taoGiaoDienKhungDuPhong() {
        khungDuPhong.backgroundColor = .tertiarySystemGroupedBackground
        khungDuPhong.layer.cornerRadius = 12

        let icon = UIImageView(image: UIImage(systemName: "hammer.fill"))
        icon.tintColor = .secondaryLabel
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 38, weight: .regular)

        nhanTieuDeDuPhong.font = .systemFont(ofSize: 16, weight: .bold)
        nhanTieuDeDuPhong.textAlignment = .center

        nhanMoTaDuPhong.text = "Mục dự phòng đang để trống cho các tính năng tiếp theo."
        nhanMoTaDuPhong.font = .systemFont(ofSize: 13)
        nhanMoTaDuPhong.textColor = .secondaryLabel
        nhanMoTaDuPhong.textAlignment = .center
        nhanMoTaDuPhong.numberOfLines = 0

        let ngan = UIStackView(arrangedSubviews: [icon, nhanTieuDeDuPhong, nhanMoTaDuPhong])
        ngan.axis = .vertical
        ngan.spacing = 8
        ngan.alignment = .center
        ngan.translatesAutoresizingMaskIntoConstraints = false
        khungDuPhong.addSubview(ngan)

        NSLayoutConstraint.activate([
            ngan.centerXAnchor.constraint(equalTo: khungDuPhong.centerXAnchor),
            ngan.centerYAnchor.constraint(equalTo: khungDuPhong.centerYAnchor),
            ngan.leadingAnchor.constraint(greaterThanOrEqualTo: khungDuPhong.leadingAnchor, constant: 24),
            ngan.trailingAnchor.constraint(lessThanOrEqualTo: khungDuPhong.trailingAnchor, constant: -24)
        ])
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
            hop.widthAnchor.constraint(equalToConstant: 240),

            vongQuay.topAnchor.constraint(equalTo: hop.topAnchor, constant: 18),
            vongQuay.centerXAnchor.constraint(equalTo: hop.centerXAnchor),

            nhanTienTrinh.topAnchor.constraint(equalTo: vongQuay.bottomAnchor, constant: 12),
            nhanTienTrinh.leadingAnchor.constraint(equalTo: hop.leadingAnchor, constant: 14),
            nhanTienTrinh.trailingAnchor.constraint(equalTo: hop.trailingAnchor, constant: -14),
            nhanTienTrinh.bottomAnchor.constraint(equalTo: hop.bottomAnchor, constant: -18)
        ])
    }

    // MARK: - Nạp dữ liệu & Chuyển đổi mượt mà giữa các mục (Chỉ nạp bảng đang hiển thị)

    private func napDuLieu() {
        nutNgay.setTitle("📅 \(TienIchNgay.hienThiNgay.string(from: ngayHienTai)) ▾", for: .normal)
        nutNgay.sizeToFit()

        let dl = KhoDuLieu.dungChung.duLieu(cho: ngayHienTai)
        let dsThiDuaDangChon = dl.danhSachThiDua(theo: cheDoDoanhThu)
        let soDat = dsThiDuaDangChon.filter { $0.daDat }.count
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

    /// Chỉ cập nhật bảng của đúng tab đang mở; nếu dữ liệu không đổi thì giữ nguyên bảng để chuyển tab mượt tức thì
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
        case .duPhong3:
            break
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

        // Khi ở tab Biểu đồ: ẩn cụm 8 thẻ chỉ số trên (chỉ giữ hàng 3 nút 34pt), ẩn hàng 3 nút Thi đua/Nhân viên/Dự phòng 3 và ẩn hàng nút Quét/Xoá/Nhập
        rangBuocCaoCumChiSo?.constant = laBieuDo ? 34 : 154
        hangBaNut.isHidden = laBieuDo
        hangNutQuet.isHidden = laBieuDo

        let nhanCheDo = cheDoDoanhThu.tieuDe
        if laNhanVien {
            nutThemAnhMoi.setTitle(" Thêm ảnh DT NV (\(nhanCheDo))", for: .normal)
        } else if laThiDua {
            nutThemAnhMoi.setTitle(" Thêm ảnh Thi đua (\(nhanCheDo))", for: .normal)
        } else {
            nutThemAnhMoi.setTitle(" Thêm ảnh", for: .normal)
        }

        bangThiDua.isHidden = !laThiDua
        bangNhanVien.isHidden = !laNhanVien
        bangRealtimeThang.isHidden = !laBieuDo
        khungDuPhong.isHidden = laThiDua || laNhanVien || laBieuDo
        nutThemThuCong.isHidden = !(laThiDua || laNhanVien)
        nutThemThuCong.setTitle(" Nhập/Mẫu", for: .normal)

        if !laThiDua && !laNhanVien && !laBieuDo {
            nhanTieuDeDuPhong.text = tabHienTai.tieuDe
        }
    }

    // MARK: - Nút Thêm ảnh mới (Cách 1: Nhập lần lượt) & Nút Xoá quét lại từ đầu

    @objc private func bamThemAnhMoi() {
        switch tabHienTai {
        case .thiDua:
            moHuongDanQuetAnhThiDua()
        case .nhanVien:
            moChonAnh(cheDo: .doanhThuNhanVien(cheDoDoanhThu), gioiHan: 0)
        case .duPhong2:
            moChonAnh(cheDo: .doanhThu(.realtime), gioiHan: 2)
        case .duPhong3:
            let tb = UIAlertController(
                title: tabHienTai.tieuDe,
                message: "Mục \(tabHienTai.tieuDe) hiện đang là nút dự phòng chưa gắn chức năng.",
                preferredStyle: .alert
            )
            tb.addAction(UIAlertAction(title: "Đã hiểu", style: .default))
            present(tb, animated: true)
        }
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

        let hd = UIAlertController(
            title: "Nhập ảnh Thi đua (\(tenCheDo))",
            message: nil,
            preferredStyle: .alert
        )
        hd.addAction(UIAlertAction(title: "➕ Quét thêm ảnh Thi đua \(tenCheDo) (Gộp nối tiếp)", style: .default) { [weak self] _ in
            self?.thayTheBangThiDuaKhiQuet = false
            self?.moChonAnh(cheDo: .thiDua(cheDoMucTieu), gioiHan: 0)
        })
        hd.addAction(UIAlertAction(title: "🔄 Quét mới Thi đua \(tenCheDo) (Thay thế bảng \(tenCheDo))", style: .destructive) { [weak self] _ in
            self?.thayTheBangThiDuaKhiQuet = true
            self?.moChonAnh(cheDo: .thiDua(cheDoMucTieu), gioiHan: 0)
        })
        hd.addAction(UIAlertAction(title: "\(bieuTuongKhac) Chuyển sang nhập Thi đua \(cheDoKhac.tieuDe)...", style: .default) { [weak self] _ in
            self?.moHuongDanQuetAnhThiDua(cheDo: cheDoKhac)
        })
        hd.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        present(hd, animated: true)
    }

    @objc private func bamXoaQuetLai() {
        let cheDoXoa = cheDoDoanhThu
        let tenCheDo = cheDoXoa.tieuDe

        if tabHienTai == .nhanVien {
            let hoiNV = UIAlertController(
                title: "Xoá dữ liệu Nhân viên (\(tenCheDo))?",
                message: "Chọn phần dữ liệu Nhân viên (\(tenCheDo)) muốn xoá:",
                preferredStyle: .actionSheet
            )
            hoiNV.addAction(UIAlertAction(title: "🗑️ Xoá bảng Doanh thu hợp nhất NV (\(tenCheDo))", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                if cheDoXoa == .luyKe {
                    KhoDuLieu.dungChung.xoaDoanhThuNhanVienLuyKeThang(cho: self.ngayHienTai, xoaCaThiDuaNV: false)
                } else {
                    var moi = KhoDuLieu.dungChung.duLieu(cho: self.ngayHienTai)
                    moi.ganDoanhThuNhanVien([], theo: cheDoXoa)
                    KhoDuLieu.dungChung.luu(moi)
                }
                self.napDuLieu()
            })
            hoiNV.addAction(UIAlertAction(title: "🗑️ Xoá cả Doanh thu NV & Thực hiện môn NV (\(tenCheDo))", style: .destructive) { [weak self] _ in
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
            })
            hoiNV.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
            if let pop = hoiNV.popoverPresentationController {
                pop.sourceView = nutXoaQuetLai
                pop.sourceRect = nutXoaQuetLai.bounds
            }
            present(hoiNV, animated: true)
            return
        }

        guard tabHienTai == .thiDua else { return }
        let dl = KhoDuLieu.dungChung.duLieu(cho: ngayHienTai)
        let dsHienTai = dl.danhSachThiDua(theo: cheDoXoa)

        if dsHienTai.isEmpty {
            moHuongDanQuetAnhThiDua(cheDo: cheDoXoa)
            return
        }

        let hoi = UIAlertController(
            title: "Xoá bảng Thi đua \(tenCheDo)?",
            message: "Toàn bộ \(dsHienTai.count) ngành hàng trong bảng Thi đua \(tenCheDo) sẽ được xoá sạch.",
            preferredStyle: .actionSheet
        )
        hoi.addAction(UIAlertAction(title: "🗑️ Xoá sạch Thi đua \(tenCheDo) & Quét lại ngay", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            var moi = KhoDuLieu.dungChung.duLieu(cho: self.ngayHienTai)
            moi.ganDanhSachThiDua([], theo: cheDoXoa)
            KhoDuLieu.dungChung.luu(moi)
            self.napDuLieu()
            self.moChonAnh(cheDo: .thiDua(cheDoXoa), gioiHan: 0)
        })
        hoi.addAction(UIAlertAction(title: "Chỉ xoá sạch danh sách Thi đua \(tenCheDo)", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            var moi = KhoDuLieu.dungChung.duLieu(cho: self.ngayHienTai)
            moi.ganDanhSachThiDua([], theo: cheDoXoa)
            KhoDuLieu.dungChung.luu(moi)
            self.napDuLieu()
        })
        hoi.addAction(UIAlertAction(title: "Huỷ", style: .cancel))

        if let pop = hoi.popoverPresentationController {
            pop.sourceView = nutXoaQuetLai
            pop.sourceRect = nutXoaQuetLai.bounds
        }
        present(hoi, animated: true)
    }

    @objc private func moMenuNhapThuCong() {
        let menu = UIAlertController(title: "Dữ liệu & Chia Target", message: nil, preferredStyle: .actionSheet)
        menu.addAction(UIAlertAction(title: "📷 Nhập tất cả ảnh cho tab \(cheDoDoanhThu.tieuDe)", style: .default) { [weak self] _ in
            self?.bamNhapTatCaAnh()
        })
        menu.addAction(UIAlertAction(title: "⚙️ Cài đặt Mục tiêu tháng & Nhân viên", style: .default) { [weak self] _ in
            self?.moCaiDat()
        })
        menu.addAction(UIAlertAction(title: "➕ Thêm 1 ngành hàng Thi đua (\(cheDoDoanhThu.tieuDe))", style: .default) { [weak self] _ in
            self?.bamThemDongThuCong()
        })
        menu.addAction(UIAlertAction(title: "✨ Nạp dữ liệu mẫu thử (Lũy kế + Realtime)", style: .default) { [weak self] _ in
            self?.napDuLieuMau()
        })
        menu.addAction(UIAlertAction(title: "Đóng", style: .cancel))
        if let pop = menu.popoverPresentationController {
            pop.sourceView = nutThemThuCong
            pop.sourceRect = nutThemThuCong.bounds
        }
        present(menu, animated: true)
    }

    // MARK: - Tương tác cụm Doanh thu (Mở thẳng bộ chọn ảnh, không hiện nhắc nhở lần 2)

    @objc private func bamTheDoanhThu() {
        let tenCheDo = cheDoDoanhThu.tieuDe
        let duBao = KhoDuLieu.dungChung.tinhDuBaoQuyDoiTuRealtime(cho: ngayHienTai, cheDoDangXem: cheDoDoanhThu)

        let menu = UIAlertController(
            title: "Doanh thu (\(tenCheDo))",
            message: nil,
            preferredStyle: .actionSheet
        )
        menu.addAction(UIAlertAction(title: "📷 Chọn 2 ảnh Doanh thu \(tenCheDo) (Thực + QĐ)", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.moChonAnh(cheDo: .doanhThu(self.cheDoDoanhThu), gioiHan: 2)
        })
        menu.addAction(UIAlertAction(title: "🎯 Đặt Mục tiêu Doanh thu QĐ Tháng (Chia \(duBao.soNgayTrongThang) ngày)", style: .default) { [weak self] _ in
            self?.moHopThoaiNhapMucTieuQDThang()
        })
        menu.addAction(UIAlertAction(title: "✏️ Nhập / Sửa tay Doanh thu \(tenCheDo) (& Lượt khách)", style: .default) { [weak self] _ in
            self?.moHopThoaiNhapDoanhThu()
        })
        menu.addAction(UIAlertAction(title: "🗑️ Xoá số liệu Doanh thu \(tenCheDo)", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            if self.cheDoDoanhThu == .luyKe {
                KhoDuLieu.dungChung.xoaDoanhThuLuyKeThang(cho: self.ngayHienTai)
            } else {
                var dl = KhoDuLieu.dungChung.duLieu(cho: self.ngayHienTai)
                dl.doanhThuRealtime = ThongTinDoanhThu()
                KhoDuLieu.dungChung.luu(dl)
            }
            self.napDuLieu()
        })
        menu.addAction(UIAlertAction(title: "Đóng", style: .cancel))

        if let pop = menu.popoverPresentationController {
            pop.sourceView = cumChiSoChinh
            pop.sourceRect = cumChiSoChinh.bounds
        }
        present(menu, animated: true)
    }

    private func moHopThoaiNhapMucTieuQDThang() {
        let soNgay = KhoDuLieu.dungChung.soNgayTrongThang(cho: ngayHienTai)
        let thang = TienIchNgay.lich.component(.month, from: ngayHienTai)
        let nam = TienIchNgay.lich.component(.year, from: ngayHienTai)
        let hienTai = KhoDuLieu.dungChung.mucTieuDoanhThuQDThang(cho: ngayHienTai)

        let hop = UIAlertController(
            title: "🎯 Mục tiêu DT Quy đổi Tháng \(String(format: "%02d/%04d", thang, nam))",
            message: "Tháng \(thang)/\(nam) có \(soNgay) ngày thực tế.\nHệ thống sẽ tự chia cho \(soNgay) ngày và tính % HT QĐ dự kiến cuối tháng ở tab Realtime:",
            preferredStyle: .alert
        )
        hop.addTextField { tf in
            tf.placeholder = "Nhập mục tiêu DT QĐ tháng (VD: 15000)"
            tf.keyboardType = .decimalPad
            if hienTai > 0 {
                tf.text = String(format: "%.2f", hienTai).replacingOccurrences(of: ".00", with: "")
            }
        }
        hop.addAction(UIAlertAction(title: "Lưu mục tiêu tháng", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let val = self.docSoTuO(hop.textFields?.first?.text)
            KhoDuLieu.dungChung.luuMucTieuDoanhThuQDThang(val, cho: self.ngayHienTai)
            self.napDuLieu()
        })
        if hienTai > 0 {
            hop.addAction(UIAlertAction(title: "Xoá mục tiêu tháng", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                KhoDuLieu.dungChung.luuMucTieuDoanhThuQDThang(0, cho: self.ngayHienTai)
                self.napDuLieu()
            })
        }
        hop.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        present(hop, animated: true)
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
        let menu = UIAlertController(
            title: ngayStr,
            message: item.coDuLieu
                ? "DT Thực: \(item.doanhThuThuc.chuoiSoVN)  •  DT Quy đổi: \(item.doanhThuQuyDoi.chuoiSoVN)"
                : nil,
            preferredStyle: .actionSheet
        )
        menu.addAction(UIAlertAction(title: "📷 Chọn 2 ảnh Realtime ngày \(ngayStr)", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.ngayHienTai = item.ngay
            self.napDuLieu()
            self.moChonAnh(cheDo: .doanhThu(.realtime), gioiHan: 2)
        })
        menu.addAction(UIAlertAction(title: "✏️ Nhập / Sửa tay Realtime ngày \(ngayStr)", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.ngayHienTai = item.ngay
            self.cheDoDoanhThu = .realtime
            self.napDuLieu()
            self.moHopThoaiNhapDoanhThu()
        })
        if item.coDuLieu {
            menu.addAction(UIAlertAction(title: "🗑️ Xoá Realtime ngày \(ngayStr)", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                var dl = KhoDuLieu.dungChung.duLieu(cho: item.ngay)
                dl.doanhThuRealtime = ThongTinDoanhThu()
                KhoDuLieu.dungChung.luu(dl)
                self.napDuLieu()
            })
        }
        menu.addAction(UIAlertAction(title: "Đóng", style: .cancel))
        if let pop = menu.popoverPresentationController {
            pop.sourceView = bangRealtimeThang
            pop.sourceRect = CGRect(x: bangRealtimeThang.bounds.midX, y: 120, width: 1, height: 1)
        }
        present(menu, animated: true)
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
        var danhSach = Array<UIImage?>(repeating: nil, count: results.count)

        for (i, r) in results.enumerated() {
            guard r.itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }
            nhom.enter()
            r.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                let img = obj as? UIImage
                DispatchQueue.main.async {
                    if let img { danhSach[i] = img }
                    nhom.leave()
                }
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
                        cacMucDaDien.append("• Doanh thu Realtime (\(kq.soAnhDoanhThu) ảnh): Thực \(dl.doanhThuRealtime.doanhThuThuc.chuoiSoGonVN) | QĐ \(dl.doanhThuRealtime.doanhThuQuyDoi.chuoiSoGonVN)")
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
                    // Với Doanh thu Lũy kế Nhân viên: khi nhập sẽ THAY THẾ hoàn toàn dữ liệu cũ (không gộp với dữ liệu cũ)
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
                // Khi nhập Doanh thu Lũy kế Nhân viên: thay thế hoàn toàn dữ liệu cũ (không lấy lại dữ liệu cũ)
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

    private func bamThemDongThuCong() {
        let moi = DongThiDua(tenNganhHang: "T10 - ", loaiChiTieu: .doanhThu, thucHien: 0, target: 0)
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
            tf.placeholder = "Tên ngành hàng (VD: T10 - AUDIO)"
            tf.text = dong.tenNganhHang
        }
        hop.addTextField { tf in
            tf.placeholder = "ĐVT: DT hoặc SL"
            tf.text = dong.loaiChiTieu.maBang
            tf.autocapitalizationType = .allCharacters
        }
        hop.addTextField { tf in
            tf.placeholder = "Thực hiện (VD: 52.00)"
            tf.keyboardType = .decimalPad
            if !laThemMoi { tf.text = String(dong.thucHien) }
        }
        hop.addTextField { tf in
            tf.placeholder = "Target (VD: 55.12)"
            tf.keyboardType = .decimalPad
            if !laThemMoi { tf.text = String(dong.target) }
        }

        hop.addAction(UIAlertAction(title: "Lưu", style: .default) { [weak self] _ in
            guard let self = self, let tfs = hop.textFields, tfs.count >= 4 else { return }
            let tenNhap = (tfs[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !tenNhap.isEmpty else { return }
            let dvt = (tfs[1].text ?? "DTLK").uppercased()
            let loai: LoaiChiTieuThiDua = dvt.contains("SL") ? .soLuong : .doanhThu
            let th = self.docSoTuO(tfs[2].text)
            let tg = self.docSoTuO(tfs[3].text)

            let capNhat = DongThiDua(
                id: dong.id,
                tenNganhHangGoc: tenNhap,
                tenNganhHang: tenNhap,
                loaiChiTieu: loai,
                thucHien: th,
                target: tg
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

    private func napDuLieuMau() {
        var dl = KhoDuLieu.dungChung.duLieu(cho: ngayHienTai)
        dl.doanhThuRealtime = ThongTinDoanhThu(
            doanhThuThuc: 337,
            targetThuc: 407,
            duKienThuc: 0,
            phanTramHTThuc: 82.9,
            doanhThuQuyDoi: 455,
            targetQuyDoi: 547,
            duKienQuyDoi: 0,
            phanTramHTQuyDoi: 0,
            phanTramTraGop: 46.6,
            doanhThuTraGop: 212,
            luotKhach: 1356,
            soBill: 183,
            phanTramPVTC: 13.5,
            tangGiamCungKy: -17.1,
            coTangGiam: true,
            tb3Thang: 549,
            soNgayDaQua: 30,
            tongSoNgay: 31,
            phanTramTienDoThang: 94.0
        )
        dl.doanhThu = ThongTinDoanhThu(
            doanhThuThuc: 11143,
            targetThuc: 11128,
            duKienThuc: 11566,
            phanTramHTThuc: 100.1,
            doanhThuQuyDoi: 15199,
            targetQuyDoi: 14957,
            duKienQuyDoi: 15780,
            phanTramHTQuyDoi: 101.6,
            phanTramTraGop: 43.3,
            doanhThuTraGop: 6580,
            luotKhach: 19149,
            soBill: 2586,
            phanTramPVTC: 13.5,
            tangGiamCungKy: -7.7,
            coTangGiam: true,
            tb3Thang: 16469,
            soNgayDaQua: 30,
            tongSoNgay: 31,
            phanTramTienDoThang: 97.0
        )
        let mau: [DongThiDua] = [
            DongThiDua(tenNganhHang: "T09 - T10 IPHONE 18 series, iPhone Duo", loaiChiTieu: .doanhThu, thucHien: 4476.28, target: 3493.60),
            DongThiDua(tenNganhHang: "T10 - NẠP - RÚT TIỀN TÀI KHOẢN NGÂN HÀNG", loaiChiTieu: .soLuong, thucHien: 407, target: 363),
            DongThiDua(tenNganhHang: "T10 - SIM TỔNG", loaiChiTieu: .soLuong, thucHien: 52.00, target: 55.12),
            DongThiDua(tenNganhHang: "T10 - Bảo Hiểm Tổng", loaiChiTieu: .doanhThu, thucHien: 306.69, target: 283.58),
            DongThiDua(tenNganhHang: "T10 - BẢO HIỂM THỢ ĐMX_CE", loaiChiTieu: .doanhThu, thucHien: 551.87, target: 745.76),
            DongThiDua(tenNganhHang: "T10 - BẢO HIỂM THỢ ĐMX_ICT", loaiChiTieu: .doanhThu, thucHien: 103.82, target: 73.99),
            DongThiDua(tenNganhHang: "T10 - GIA DỤNG SUNHOUSE", loaiChiTieu: .doanhThu, thucHien: 647.39, target: 703.00),
            DongThiDua(tenNganhHang: "T10 - ĐIỆN TỬ TCL", loaiChiTieu: .doanhThu, thucHien: 205.22, target: 240.37),
            DongThiDua(tenNganhHang: "T10 - PANASONIC", loaiChiTieu: .doanhThu, thucHien: 599.03, target: 614.15),
            DongThiDua(tenNganhHang: "T10 - TIVI", loaiChiTieu: .doanhThu, thucHien: 800.25, target: 1079.00),
            DongThiDua(tenNganhHang: "T10 - HÚT BỤI", loaiChiTieu: .doanhThu, thucHien: 158.97, target: 288.00),
            DongThiDua(tenNganhHang: "T10 - AUDIO", loaiChiTieu: .doanhThu, thucHien: 19.00, target: 63.00),
            DongThiDua(tenNganhHang: "T10 - Máy Lạnh", loaiChiTieu: .soLuong, thucHien: 39.00, target: 147.00)
        ]
        dl.danhSachThiDua = KhoDuLieu.gopDanhSachThiDua(cu: dl.danhSachThiDua, moi: mau)
        let mauRealtime: [DongThiDua] = [
            DongThiDua(tenNganhHang: "T09 - T10 IPHONE 18 series, iPhone Duo", loaiChiTieu: .doanhThu, thucHien: 148.50, target: 112.70),
            DongThiDua(tenNganhHang: "T10 - NẠP - RÚT TIỀN TÀI KHOẢN NGÂN HÀNG", loaiChiTieu: .soLuong, thucHien: 16, target: 12),
            DongThiDua(tenNganhHang: "T10 - SIM TỔNG", loaiChiTieu: .soLuong, thucHien: 2.00, target: 2.00),
            DongThiDua(tenNganhHang: "T10 - Bảo Hiểm Tổng", loaiChiTieu: .doanhThu, thucHien: 11.20, target: 9.15),
            DongThiDua(tenNganhHang: "T10 - BẢO HIỂM THỢ ĐMX_CE", loaiChiTieu: .doanhThu, thucHien: 18.40, target: 24.06),
            DongThiDua(tenNganhHang: "T10 - BẢO HIỂM THỢ ĐMX_ICT", loaiChiTieu: .doanhThu, thucHien: 3.60, target: 2.39),
            DongThiDua(tenNganhHang: "T10 - GIA DỤNG SUNHOUSE", loaiChiTieu: .doanhThu, thucHien: 21.80, target: 22.68),
            DongThiDua(tenNganhHang: "T10 - ĐIỆN TỬ TCL", loaiChiTieu: .doanhThu, thucHien: 7.90, target: 7.75),
            DongThiDua(tenNganhHang: "T10 - PANASONIC", loaiChiTieu: .doanhThu, thucHien: 19.50, target: 19.81),
            DongThiDua(tenNganhHang: "T10 - TIVI", loaiChiTieu: .doanhThu, thucHien: 28.40, target: 34.81),
            DongThiDua(tenNganhHang: "T10 - HÚT BỤI", loaiChiTieu: .doanhThu, thucHien: 6.20, target: 9.29),
            DongThiDua(tenNganhHang: "T10 - AUDIO", loaiChiTieu: .doanhThu, thucHien: 1.50, target: 2.03),
            DongThiDua(tenNganhHang: "T10 - Máy Lạnh", loaiChiTieu: .soLuong, thucHien: 2.00, target: 5.00)
        ]
        dl.danhSachThiDuaRealtime = KhoDuLieu.gopDanhSachThiDua(cu: dl.danhSachThiDuaRealtime, moi: mauRealtime)
        dl.doanhThuNhanVien = [
            DoanhThuNhanVienItem(maNV: "24939", hoTen: "Phan Hoàng Sơn", soLuong: 220, doanhThuThuc: 717, doanhThuQD: 1412, target: 1361.09, dtQDKhoanVay: 0, dtTraThangQD: 924, dtTraGop: 296, phanTramHT: 70.75, phanTramQuyDoi: 34.31, phanTramTraGop: 41.28, gioCong: 170, soNgayNghi: 1, nangSuat: 4.22),
            DoanhThuNhanVienItem(maNV: "65255", hoTen: "Nguyễn Thị Thu Thảo", soLuong: 229, doanhThuThuc: 632, doanhThuQD: 1278, target: 1361.09, dtQDKhoanVay: 0, dtTraThangQD: 847, dtTraGop: 213, phanTramHT: 60.17, phanTramQuyDoi: 29.59, phanTramTraGop: 33.7, gioCong: 168, soNgayNghi: 1, nangSuat: 3.74),
            DoanhThuNhanVienItem(maNV: "261423", hoTen: "Trần Nam Tùng", soLuong: 162, doanhThuThuc: 689, doanhThuQD: 1206, target: 1361.09, dtQDKhoanVay: 0, dtTraThangQD: 716, dtTraGop: 217, phanTramHT: 64.14, phanTramQuyDoi: 26.71, phanTramTraGop: 31.49, gioCong: 188, soNgayNghi: 0, nangSuat: 3.65),
            DoanhThuNhanVienItem(maNV: "201962", hoTen: "Nguyễn Thị Kim Loan", soLuong: 169, doanhThuThuc: 722, doanhThuQD: 1190, target: 1166.65, dtQDKhoanVay: 0, dtTraThangQD: 493, dtTraGop: 470, phanTramHT: 81.94, phanTramQuyDoi: 32.41, phanTramTraGop: 65.1, gioCong: 188, soNgayNghi: 0, nangSuat: 3.83),
            DoanhThuNhanVienItem(maNV: "116719", hoTen: "Đinh Thị Quỳnh Nga", soLuong: 209, doanhThuThuc: 573, doanhThuQD: 1171, target: 1361.09, dtQDKhoanVay: 2, dtTraThangQD: 716, dtTraGop: 205, phanTramHT: 55.25, phanTramQuyDoi: 31.24, phanTramTraGop: 35.78, gioCong: 184, soNgayNghi: 1, nangSuat: 3.11),
            DoanhThuNhanVienItem(maNV: "23986", hoTen: "Nguyễn Ngọc Đẩu", soLuong: 203, doanhThuThuc: 650, doanhThuQD: 1164, target: 1361.09, dtQDKhoanVay: 2, dtTraThangQD: 761, dtTraGop: 259, phanTramHT: 63.99, phanTramQuyDoi: 34.0, phanTramTraGop: 39.85, gioCong: 170, soNgayNghi: 2, nangSuat: 3.82)
        ]
        dl.doanhThuNhanVienRealtime = [
            DoanhThuNhanVienItem(maNV: "24939", hoTen: "Phan Hoàng Sơn", soLuong: 12, doanhThuThuc: 38, doanhThuQD: 64, target: 45.3, dtQDKhoanVay: 0, dtTraThangQD: 42, dtTraGop: 15, phanTramHT: 141.2, phanTramQuyDoi: 68.4, phanTramTraGop: 39.5, gioCong: 8, soNgayNghi: 0, nangSuat: 4.75),
            DoanhThuNhanVienItem(maNV: "65255", hoTen: "Nguyễn Thị Thu Thảo", soLuong: 9, doanhThuThuc: 31, doanhThuQD: 52, target: 45.3, dtQDKhoanVay: 0, dtTraThangQD: 34, dtTraGop: 11, phanTramHT: 114.8, phanTramQuyDoi: 67.7, phanTramTraGop: 35.5, gioCong: 8, soNgayNghi: 0, nangSuat: 3.88),
            DoanhThuNhanVienItem(maNV: "261423", hoTen: "Trần Nam Tùng", soLuong: 8, doanhThuThuc: 29, doanhThuQD: 48, target: 45.3, dtQDKhoanVay: 0, dtTraThangQD: 30, dtTraGop: 10, phanTramHT: 105.9, phanTramQuyDoi: 65.5, phanTramTraGop: 34.5, gioCong: 8, soNgayNghi: 0, nangSuat: 3.62),
            DoanhThuNhanVienItem(maNV: "201962", hoTen: "Nguyễn Thị Kim Loan", soLuong: 7, doanhThuThuc: 25, doanhThuQD: 41, target: 38.8, dtQDKhoanVay: 0, dtTraThangQD: 24, dtTraGop: 12, phanTramHT: 105.7, phanTramQuyDoi: 64.0, phanTramTraGop: 48.0, gioCong: 8, soNgayNghi: 0, nangSuat: 3.12)
        ]
        dl.capNhatLuc = "21:05:01"
        dl.thongTinDonVi = "ĐML_QNG_QNG - 275 Quang Trung"
        KhoDuLieu.dungChung.luu(dl)
        napDuLieu()
    }

    // MARK: - Chọn ngày (Chỉ hiển thị danh sách ngày định dạng dd/MM/yyyy, không ghi thêm chữ phụ) & Xuất báo cáo

    @objc private func moLichSuNgay() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let lich = TienIchNgay.lich
        let homNay = lich.startOfDay(for: Date())

        var tapKhoaNgay = Set<String>()
        for i in 0..<15 {
            if let d = lich.date(byAdding: .day, value: -i, to: homNay) {
                tapKhoaNgay.insert(TienIchNgay.khoa.string(from: d))
            }
        }
        for khoa in KhoDuLieu.dungChung.cacNgay.keys {
            tapKhoaNgay.insert(khoa)
        }

        for khoa in tapKhoaNgay.sorted(by: >).prefix(20) {
            guard let d = TienIchNgay.khoa.date(from: khoa) else { continue }
            let tieuDeNgay = TienIchNgay.hienThiNgay.string(from: d)
            sheet.addAction(UIAlertAction(title: tieuDeNgay, style: .default) { [weak self] _ in
                self?.ngayHienTai = d
                self?.napDuLieu()
            })
        }

        sheet.addAction(UIAlertAction(title: "Đóng", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = nutNgay
            pop.sourceRect = nutNgay.bounds
        }
        present(sheet, animated: true)
    }

    @objc private func moMenuXuatBaoCao() {
        let dl = KhoDuLieu.dungChung.duLieu(cho: ngayHienTai)
        let kieu = KhoDuLieu.dungChung.caiDat.kieuHienThi
        let moTaKieu = (kieu == .bangChiTiet) ? "Bảng 8 cột" : "Thẻ \(KhoDuLieu.dungChung.caiDat.soCotXuatAnh) cột"
        let cheDoNV = cheDoDoanhThu

        let menu = UIAlertController(
            title: "Chia sẻ ảnh & Xuất báo cáo",
            message: "Chọn loại ảnh hoặc file dữ liệu báo cáo bạn muốn chia sẻ hoặc lưu về máy:",
            preferredStyle: .actionSheet
        )

        menu.addAction(UIAlertAction(title: "📊 Ảnh Thi đua — Doanh thu Lũy kế (\(moTaKieu))", style: .default) { [weak self] _ in
            guard let self = self,
                  let anh = self.bangThiDua.taoAnhBaoCao(
                      ngay: self.ngayHienTai,
                      doanhThu: dl.doanhThu,
                      danhSach: dl.danhSachThiDua,
                      cheDoDoanhThu: .luyKe,
                      thongTinDonVi: dl.thongTinDonVi,
                      capNhatLuc: dl.capNhatLuc
                  ) else { return }
            self.chiaSe([anh])
        })

        menu.addAction(UIAlertAction(title: "⚡ Ảnh Thi đua — Doanh thu Realtime (\(moTaKieu))", style: .default) { [weak self] _ in
            guard let self = self,
                  let anh = self.bangThiDua.taoAnhBaoCao(
                      ngay: self.ngayHienTai,
                      doanhThu: dl.doanhThuRealtime,
                      danhSach: dl.danhSachThiDuaRealtime,
                      cheDoDoanhThu: .realtime,
                      thongTinDonVi: dl.thongTinDonVi,
                      capNhatLuc: dl.capNhatLuc
                  ) else { return }
            self.chiaSe([anh])
        })

        menu.addAction(UIAlertAction(title: "👥 Ảnh Bảng Xếp Hạng Nhân Viên (\(cheDoNV.tieuDe))", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.bangNhanVien.capNhat(cho: self.ngayHienTai, cheDo: cheDoNV)
            guard let anh = self.bangNhanVien.taoAnhBaoCaoNhanVien(
                ngay: self.ngayHienTai,
                cheDo: cheDoNV,
                thongTinDonVi: dl.thongTinDonVi,
                capNhatLuc: dl.capNhatLuc
            ) else { return }
            self.chiaSe([anh])
        })

        menu.addAction(UIAlertAction(title: "👤 Ảnh Sức Khoẻ Nhân Viên (\(cheDoNV.tieuDe))...", style: .default) { [weak self] _ in
            self?.moChonNhanVienChiaSeAnh(cheDo: cheDoNV)
        })

        menu.addAction(UIAlertAction(title: "📈 Ảnh Biểu Đồ & Tổng Hợp Realtime Tháng (Toàn bộ bảng)", style: .default) { [weak self] _ in
            guard let self = self,
                  let anh = self.bangRealtimeThang.taoAnhBaoCaoRealtimeThang(
                      ngay: self.ngayHienTai,
                      thongTinDonVi: dl.thongTinDonVi,
                      capNhatLuc: dl.capNhatLuc
                  ) else { return }
            self.chiaSe([anh])
        })

        menu.addAction(UIAlertAction(title: "📑 Xuất file Biểu Đồ & Realtime Tháng (.csv)", style: .default) { [weak self] _ in
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
        })

        let cheDoCSV = cheDoDoanhThu
        let dtDangChon = (cheDoCSV == .luyKe) ? dl.doanhThu : dl.doanhThuRealtime
        let dsDangChon = dl.danhSachThiDua(theo: cheDoCSV)
        menu.addAction(UIAlertAction(title: "📄 Xuất file Excel (.csv) (\(cheDoCSV.tieuDe) + Biểu đồ)", style: .default) { [weak self] _ in
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
        })

        menu.addAction(UIAlertAction(title: "Đóng", style: .cancel))
        if let pop = menu.popoverPresentationController {
            pop.sourceView = nutXuatNav
            pop.sourceRect = nutXuatNav.bounds
        }
        present(menu, animated: true)
    }

    private func moChonNhanVienChiaSeAnh(cheDo: LoaiCheDoDoanhThu) {
        let dsNV = KhoDuLieu.dungChung.tongHopNhanVien(den: ngayHienTai, sapXep: .soMonHoanThanh, cheDo: cheDo)
        guard !dsNV.isEmpty else { return }
        let chon = UIAlertController(
            title: "Xuất ảnh Sức khoẻ Nhân viên (\(cheDo.tieuDe))",
            message: "Chọn xuất tất cả \(dsNV.count) nhân viên đang quản lý hoặc chọn 1 nhân viên cụ thể:",
            preferredStyle: .actionSheet
        )

        chon.addAction(UIAlertAction(title: "📚 Xuất TẤT CẢ \(dsNV.count) NV đang quản lý (Bộ \(dsNV.count) ảnh rời)", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let cacAnh = ManHinhChiTietNhanVien.taoTatCaAnhSucKhoe(cho: self.ngayHienTai, cheDo: cheDo)
            guard !cacAnh.isEmpty else { return }
            self.chiaSe(cacAnh)
        })

        chon.addAction(UIAlertAction(title: "🖼️ Xuất TẤT CẢ \(dsNV.count) NV đang quản lý (Gộp 1 ảnh tổng hợp)", style: .default) { [weak self] _ in
            guard let self = self,
                  let anhGop = ManHinhChiTietNhanVien.taoAnhGopTatCaSucKhoe(cho: self.ngayHienTai, cheDo: cheDo) else { return }
            self.chiaSe([anhGop])
        })

        for (i, item) in dsNV.enumerated() {
            let tieuDe = "👤 \(i + 1). \(item.nhanVien.hoTen) (\(item.soMonDat)/\(item.tongMonGiao) môn • \(String(format: "%.1f%%", item.phanTramHTTB)))"
            chon.addAction(UIAlertAction(title: tieuDe, style: .default) { [weak self] _ in
                guard let self = self,
                      let anh = ManHinhChiTietNhanVien.taoAnhSucKhoe(cho: item, ngay: self.ngayHienTai, cheDo: cheDo) else { return }
                self.chiaSe([anh])
            })
        }
        chon.addAction(UIAlertAction(title: "Đóng", style: .cancel))
        if let pop = chon.popoverPresentationController {
            pop.sourceView = nutXuatNav
            pop.sourceRect = nutXuatNav.bounds
        }
        present(chon, animated: true)
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
