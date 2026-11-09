import UIKit
import PhotosUI

// MARK: - 1. Màn hình Chi tiết Ngành hàng -> Xếp hạng nhân viên, Nhập ảnh thực hiện NV, Chia Target & Xuất ảnh

final class ManHinhChiTietNganhHang: UIViewController, UITableViewDataSource, UITableViewDelegate, PHPickerViewControllerDelegate {
    private var dong: DongThiDua
    private let ngay: Date
    private let cheDo: LoaiCheDoDoanhThu
    private var danhSachXepHang: [DongXepHangNhanVienNganh] = []

    var khiCapNhatDuLieu: (() -> Void)?
    var khiYeuCauSuaDong: ((DongThiDua) -> Void)?

    private let nhanPhuDe = UILabel()
    private let nhanThongTinTarget = UILabel()
    private let bang = UITableView(frame: .zero, style: .plain)
    private let khungTongCong = UIView()
    private let nhanTongCongTrai = UILabel()
    private let nhanTongCongPhai = UILabel()
    private let khungTrong = UIView()
    private let lopPhuTai = UIView()
    private let nhanTienTrinh = UILabel()
    private let vongQuay = UIActivityIndicatorView(style: .large)

    init(dong: DongThiDua, ngay: Date, cheDo: LoaiCheDoDoanhThu = .luyKe) {
        self.dong = dong
        self.ngay = ngay
        self.cheDo = cheDo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func capNhatTieuDeThanhDieuHuong(_ chu: String) {
        title = chu
        let nhan = UILabel()
        nhan.text = chu
        nhan.font = .systemFont(ofSize: 13.5, weight: .bold)
        nhan.textColor = .label
        nhan.textAlignment = .center
        nhan.numberOfLines = 0
        nhan.lineBreakMode = .byWordWrapping
        nhan.adjustsFontSizeToFitWidth = false
        navigationItem.titleView = nhan
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        capNhatTieuDeThanhDieuHuong("\(dong.tenNganhHang) (\(cheDo.tieuDe))")
        view.backgroundColor = .systemGroupedBackground

        let nutSua = UIBarButtonItem(
            image: UIImage(systemName: "pencil.circle"),
            style: .plain,
            target: self,
            action: #selector(bamSuaNganhHang)
        )
        let nutXuatAnh = UIBarButtonItem(
            image: UIImage(systemName: "photo.on.rectangle.angled"),
            style: .plain,
            target: self,
            action: #selector(bamXuatAnhBangNganhHang)
        )
        navigationItem.rightBarButtonItems = [nutXuatAnh, nutSua]

        taoGiaoDien()
        napDuLieu()
        NotificationCenter.default.addObserver(self, selector: #selector(napDuLieu), name: .duLieuDMXDaDongBo, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        napDuLieu()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func taoGiaoDien() {
        view.backgroundColor = BangMauBCTD.nenTrang

        let khungDau = UIView()
        khungDau.backgroundColor = BangMauBCTD.nenMenuToi
        khungDau.layer.cornerRadius = 12
        khungDau.layer.borderWidth = 1
        khungDau.layer.borderColor = BangMauBCTD.vangChuDao.withAlphaComponent(0.35).cgColor

        nhanPhuDe.font = .systemFont(ofSize: 11.5, weight: .heavy)
        nhanPhuDe.textColor = BangMauBCTD.vangChuDao
        nhanPhuDe.numberOfLines = 0
        nhanPhuDe.lineBreakMode = .byWordWrapping
        nhanPhuDe.adjustsFontSizeToFitWidth = false

        nhanThongTinTarget.font = .systemFont(ofSize: 13.5, weight: .bold)
        nhanThongTinTarget.textColor = .white
        nhanThongTinTarget.numberOfLines = 0
        nhanThongTinTarget.lineBreakMode = .byWordWrapping
        nhanThongTinTarget.adjustsFontSizeToFitWidth = false

        let nutQuetAnhNV = UIButton(type: .system)
        nutQuetAnhNV.setImage(UIImage(systemName: "camera.viewfinder"), for: .normal)
        nutQuetAnhNV.setTitle(" Nhập ảnh thực hiện NV (\(cheDo.tieuDe))", for: .normal)
        nutQuetAnhNV.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        nutQuetAnhNV.titleLabel?.numberOfLines = 0
        nutQuetAnhNV.titleLabel?.lineBreakMode = .byWordWrapping
        nutQuetAnhNV.titleLabel?.textAlignment = .center
        nutQuetAnhNV.titleLabel?.adjustsFontSizeToFitWidth = false
        nutQuetAnhNV.backgroundColor = BangMauBCTD.indigoChuDao
        nutQuetAnhNV.tintColor = .white
        nutQuetAnhNV.setTitleColor(.white, for: .normal)
        nutQuetAnhNV.layer.cornerRadius = 9
        nutQuetAnhNV.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        nutQuetAnhNV.addTarget(self, action: #selector(bamQuetAnhNV), for: .touchUpInside)

        let nutChiaTarget = UIButton(type: .system)
        nutChiaTarget.setImage(UIImage(systemName: "person.2.badge.gearshape"), for: .normal)
        nutChiaTarget.setTitle(" Chia Target", for: .normal)
        nutChiaTarget.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        nutChiaTarget.titleLabel?.numberOfLines = 0
        nutChiaTarget.titleLabel?.lineBreakMode = .byWordWrapping
        nutChiaTarget.titleLabel?.textAlignment = .center
        nutChiaTarget.titleLabel?.adjustsFontSizeToFitWidth = false
        nutChiaTarget.backgroundColor = BangMauBCTD.nenDongChonMenu
        nutChiaTarget.tintColor = BangMauBCTD.vangChuDao
        nutChiaTarget.setTitleColor(BangMauBCTD.vangChuDao, for: .normal)
        nutChiaTarget.layer.cornerRadius = 9
        nutChiaTarget.layer.borderWidth = 1
        nutChiaTarget.layer.borderColor = BangMauBCTD.vangChuDao.withAlphaComponent(0.55).cgColor
        nutChiaTarget.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        nutChiaTarget.addTarget(self, action: #selector(bamMoChiaTarget), for: .touchUpInside)

        let nutXoaDuLieuMon = UIButton(type: .system)
        let cfgTrash = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        nutXoaDuLieuMon.setImage(UIImage(systemName: "trash.fill", withConfiguration: cfgTrash), for: .normal)
        nutXoaDuLieuMon.backgroundColor = BangMauBCTD.doYeuPill
        nutXoaDuLieuMon.tintColor = BangMauBCTD.doYeuChu
        nutXoaDuLieuMon.layer.cornerRadius = 9
        nutXoaDuLieuMon.layer.borderWidth = 1
        nutXoaDuLieuMon.layer.borderColor = BangMauBCTD.doYeuChu.withAlphaComponent(0.55).cgColor
        nutXoaDuLieuMon.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        nutXoaDuLieuMon.accessibilityLabel = "Xóa dữ liệu thi đua môn này"
        nutXoaDuLieuMon.translatesAutoresizingMaskIntoConstraints = false
        nutXoaDuLieuMon.widthAnchor.constraint(equalToConstant: 44).isActive = true
        nutXoaDuLieuMon.addTarget(self, action: #selector(bamXoaDuLieuThiDuaMon), for: .touchUpInside)

        let hangNutChinh = UIStackView(arrangedSubviews: [nutQuetAnhNV, nutChiaTarget])
        hangNutChinh.axis = .horizontal
        hangNutChinh.spacing = 8
        hangNutChinh.distribution = .fillEqually

        let hangNut = UIStackView(arrangedSubviews: [hangNutChinh, nutXoaDuLieuMon])
        hangNut.axis = .horizontal
        hangNut.spacing = 8
        hangNut.distribution = .fill

        let nganDau = UIStackView(arrangedSubviews: [nhanPhuDe, nhanThongTinTarget, hangNut])
        nganDau.axis = .vertical
        nganDau.spacing = 6
        nganDau.translatesAutoresizingMaskIntoConstraints = false
        khungDau.addSubview(nganDau)

        bang.dataSource = self
        bang.delegate = self
        bang.separatorStyle = .none
        bang.backgroundColor = .secondarySystemGroupedBackground
        bang.layer.cornerRadius = 12
        bang.clipsToBounds = true
        if #available(iOS 15.0, *) {
            bang.sectionHeaderTopPadding = 0
        }

        khungTongCong.backgroundColor = BangMauBCTD.nenMenuToi
        khungTongCong.layer.cornerRadius = 10
        khungTongCong.layer.borderWidth = 1
        khungTongCong.layer.borderColor = BangMauBCTD.vangChuDao.withAlphaComponent(0.4).cgColor
        nhanTongCongTrai.font = .systemFont(ofSize: 12.5, weight: .bold)
        nhanTongCongTrai.textColor = .white
        nhanTongCongTrai.numberOfLines = 0
        nhanTongCongTrai.lineBreakMode = .byWordWrapping
        nhanTongCongTrai.adjustsFontSizeToFitWidth = false

        nhanTongCongPhai.font = .systemFont(ofSize: 12.5, weight: .heavy)
        nhanTongCongPhai.textColor = BangMauBCTD.vangChuDao
        nhanTongCongPhai.textAlignment = .right
        nhanTongCongPhai.numberOfLines = 0
        nhanTongCongPhai.lineBreakMode = .byWordWrapping
        nhanTongCongPhai.adjustsFontSizeToFitWidth = false
        nhanTongCongPhai.setContentCompressionResistancePriority(.required, for: .horizontal)

        [nhanTongCongTrai, nhanTongCongPhai].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            khungTongCong.addSubview($0)
        }

        khungTrong.backgroundColor = .secondarySystemGroupedBackground
        khungTrong.layer.cornerRadius = 12
        let nhanTrong = UILabel()
        nhanTrong.text = "Chưa chọn nhân viên nhận Target cho mặt hàng này.\nHãy bấm \"Chia Target\" để tích chọn các nhân viên phụ trách hoặc \"Nhập ảnh thực hiện NV\"."
        nhanTrong.font = .systemFont(ofSize: 13.5)
        nhanTrong.textColor = .secondaryLabel
        nhanTrong.textAlignment = .center
        nhanTrong.numberOfLines = 0
        nhanTrong.lineBreakMode = .byWordWrapping
        nhanTrong.adjustsFontSizeToFitWidth = false
        nhanTrong.translatesAutoresizingMaskIntoConstraints = false
        khungTrong.addSubview(nhanTrong)

        [khungDau, bang, khungTrong, khungTongCong].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            khungDau.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            khungDau.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            khungDau.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            nganDau.topAnchor.constraint(equalTo: khungDau.topAnchor, constant: 10),
            nganDau.leadingAnchor.constraint(equalTo: khungDau.leadingAnchor, constant: 12),
            nganDau.trailingAnchor.constraint(equalTo: khungDau.trailingAnchor, constant: -12),
            nganDau.bottomAnchor.constraint(equalTo: khungDau.bottomAnchor, constant: -10),

            khungTongCong.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            khungTongCong.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            khungTongCong.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            khungTongCong.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            nhanTongCongTrai.leadingAnchor.constraint(equalTo: khungTongCong.leadingAnchor, constant: 12),
            nhanTongCongTrai.topAnchor.constraint(equalTo: khungTongCong.topAnchor, constant: 8),
            nhanTongCongTrai.bottomAnchor.constraint(equalTo: khungTongCong.bottomAnchor, constant: -8),
            nhanTongCongTrai.trailingAnchor.constraint(lessThanOrEqualTo: nhanTongCongPhai.leadingAnchor, constant: -8),

            nhanTongCongPhai.trailingAnchor.constraint(equalTo: khungTongCong.trailingAnchor, constant: -12),
            nhanTongCongPhai.centerYAnchor.constraint(equalTo: khungTongCong.centerYAnchor),

            bang.topAnchor.constraint(equalTo: khungDau.bottomAnchor, constant: 8),
            bang.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            bang.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            bang.bottomAnchor.constraint(equalTo: khungTongCong.topAnchor, constant: -8),

            khungTrong.topAnchor.constraint(equalTo: khungDau.bottomAnchor, constant: 8),
            khungTrong.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            khungTrong.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            khungTrong.bottomAnchor.constraint(equalTo: khungTongCong.topAnchor, constant: -8),

            nhanTrong.centerXAnchor.constraint(equalTo: khungTrong.centerXAnchor),
            nhanTrong.centerYAnchor.constraint(equalTo: khungTrong.centerYAnchor),
            nhanTrong.leadingAnchor.constraint(equalTo: khungTrong.leadingAnchor, constant: 20),
            nhanTrong.trailingAnchor.constraint(equalTo: khungTrong.trailingAnchor, constant: -20)
        ])

        taoLopPhuTienTrinh()
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

    @objc private func napDuLieu() {
        let dl = KhoDuLieu.dungChung.duLieu(cho: ngay)
        let dsTheoCheDo = dl.danhSachThiDua(theo: cheDo)
        if let capNhatDong = dsTheoCheDo.first(where: {
            $0.id == dong.id || KhoDuLieu.chuanHoaKhoaSoSanh($0.tenNganhHang) == KhoDuLieu.chuanHoaKhoaSoSanh(dong.tenNganhHang)
        }) ?? dl.danhSachThiDua.first(where: {
            $0.id == dong.id || KhoDuLieu.chuanHoaKhoaSoSanh($0.tenNganhHang) == KhoDuLieu.chuanHoaKhoaSoSanh(dong.tenNganhHang)
        }) {
            dong = capNhatDong
            capNhatTieuDeThanhDieuHuong("\(dong.tenNganhHang) (\(cheDo.tieuDe))")
        }

        danhSachXepHang = KhoDuLieu.dungChung.danhSachXepHangNhanVien(cho: dong, den: ngay, cheDo: cheDo)
        let soNV = danhSachXepHang.count
        let targetMoiNV = soNV > 0 ? dong.target / Double(soNV) : 0
        let donVi = dl.thongTinDonVi.isEmpty ? "ĐIỆN MÁY XANH" : dl.thongTinDonVi

        nhanPhuDe.text = "\(donVi) • \(cheDo.tieuDe) • Ngày \(TienIchNgay.hienThiNgay.string(from: ngay))"
        nhanThongTinTarget.text = "Target ST: \(dong.target.chuoiSoGonVN) (\(dong.loaiChiTieu.maBang))  •  Chia đều \(soNV) NV: \(soNV > 0 ? targetMoiNV.chuoiSoGonVN : "--")/NV"

        let tongTH = danhSachXepHang.reduce(0.0) { $0 + $1.thucHien }
        let tyLeChung = dong.target > 0 ? Int(round(tongTH / dong.target * 100.0)) : 0
        nhanTongCongTrai.text = "TỔNG (\(cheDo.tieuDe)): \(tongTH.chuoiSoGonVN) / \(dong.target.chuoiSoGonVN) • \(soNV) NV"
        nhanTongCongPhai.text = "Tỷ lệ HT: \(tyLeChung)%"

        khungTrong.isHidden = !danhSachXepHang.isEmpty
        bang.isHidden = danhSachXepHang.isEmpty
        bang.reloadData()
    }

    @objc private func bamQuetAnhNV() {
        var cauHinh = PHPickerConfiguration()
        cauHinh.filter = .images
        cauHinh.selectionLimit = 0
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

            self.nhanTienTrinh.text = "Đang đọc \(cacAnh.count) ảnh Thực hiện NV (\(self.cheDo.tieuDe))..."
            self.lopPhuTai.isHidden = false
            self.vongQuay.startAnimating()

            let khoaMacDinh = KhoDuLieu.chuanHoaKhoaSoSanh(self.dong.tenNganhHang)
            DichVuDocAnh.dungChung.quetAnhThiDuaNhanVien(
                danhSachAnh: cacAnh,
                tenNganhGoiY: self.dong.tenNganhHang,
                tienTrinh: { [weak self] tt in
                    self?.nhanTienTrinh.text = tt
                },
                hoanTat: { [weak self] cacKhoi in
                    guard let self = self else { return }
                    self.vongQuay.stopAnimating()
                    self.lopPhuTai.isHidden = true

                    if cacKhoi.isEmpty {
                        let tb = UIAlertController(
                            title: "Chưa đọc được dòng nhân viên",
                            message: "Hãy chụp rõ cột mã - tên nhân viên và cột số thực hiện rồi thử lại.",
                            preferredStyle: .alert
                        )
                        tb.addAction(UIAlertAction(title: "Đóng", style: .default))
                        self.present(tb, animated: true)
                        return
                    }

                    var cacKhoiCapNhat = cacKhoi
                    for i in cacKhoiCapNhat.indices {
                        if self.dong.thucHien > 0 && cacKhoiCapNhat[i].thucHienNganhGoiY <= 0 {
                            cacKhoiCapNhat[i].thucHienNganhGoiY = self.dong.thucHien
                        } else if self.dong.thucHien <= 0 && cacKhoiCapNhat[i].thucHienNganhGoiY > 0 {
                            self.dong.thucHien = cacKhoiCapNhat[i].thucHienNganhGoiY
                        }
                        if self.dong.target > 0 && cacKhoiCapNhat[i].targetNganhGoiY <= 0 {
                            cacKhoiCapNhat[i].targetNganhGoiY = self.dong.target
                        } else if self.dong.target <= 0 && cacKhoiCapNhat[i].targetNganhGoiY > 0 {
                            self.dong.target = cacKhoiCapNhat[i].targetNganhGoiY
                            KhoDuLieu.dungChung.capNhatTargetNganhHang(
                                dongGoc: self.dong,
                                targetMoi: cacKhoiCapNhat[i].targetNganhGoiY,
                                cho: self.ngay,
                                cheDo: self.cheDo
                            )
                        }
                    }

                    var dl = KhoDuLieu.dungChung.duLieu(cho: self.ngay)
                    let bangMoi = KhoDuLieu.dungChung.gopKetQuaThiDuaNhanVien(
                        hienTai: dl.thiDuaNhanVien(theo: self.cheDo),
                        mangKhoiNV: cacKhoiCapNhat,
                        ngay: self.ngay,
                        cheDo: self.cheDo,
                        khoaNganhMacDinh: khoaMacDinh
                    )
                    dl.ganThiDuaNhanVien(bangMoi, theo: self.cheDo)
                    KhoDuLieu.dungChung.luu(dl)
                    self.napDuLieu()
                    self.khiCapNhatDuLieu?()
                }
            )
        }
    }

    @objc private func bamXoaDuLieuThiDuaMon() {
        let hop = UIAlertController(
            title: "Xóa dữ liệu thi đua môn này?",
            message: "Bạn có chắc muốn xóa toàn bộ số liệu thi đua nhân viên của môn \"\(dong.tenNganhHang)\" (\(cheDo.tieuDe)) không?",
            preferredStyle: .alert
        )
        hop.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        hop.addAction(UIAlertAction(title: "Xóa dữ liệu", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            KhoDuLieu.dungChung.xoaThiDuaNhanVienTheoMon(
                dong: self.dong,
                ngay: self.ngay,
                cheDo: self.cheDo
            )
            self.napDuLieu()
            self.khiCapNhatDuLieu?()
        })
        present(hop, animated: true)
    }

    @objc private func bamMoChiaTarget() {
        let khoa = KhoDuLieu.chuanHoaKhoaSoSanh(dong.tenNganhHang)
        let vc = ManHinhChiaTarget(ngay: ngay, khoaNganhChonMacDinh: khoa)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func bamSuaNganhHang() {
        khiYeuCauSuaDong?(dong)
    }

    // MARK: - Bảng xếp hạng nhân viên của ngành hàng

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        danhSachXepHang.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = danhSachXepHang[indexPath.row]
        let chuoiTen = "\(item.hoTen) - \(item.maNV)"
        let rongTen = max(100, tableView.bounds.width - 230)
        let fontTen = UIFont.systemFont(ofSize: 12, weight: .bold)
        let rect = (chuoiTen as NSString).boundingRect(
            with: CGSize(width: rongTen, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontTen],
            context: nil
        )
        return max(54, ceil(rect.height) + 22)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44))
        header.backgroundColor = BangMauBCTD.nenHeaderBang

        let nhanTrai = UILabel()
        nhanTrai.text = "#  NHÂN VIÊN (Chạm sửa)"
        nhanTrai.font = .systemFont(ofSize: 11, weight: .bold)
        nhanTrai.textColor = BangMauBCTD.vangChuDao
        nhanTrai.numberOfLines = 0
        nhanTrai.lineBreakMode = .byWordWrapping
        nhanTrai.adjustsFontSizeToFitWidth = false

        let nhanPhai = UILabel()
        nhanPhai.text = "THỰC HIỆN • CÒN/VƯỢT • % HT"
        nhanPhai.font = .systemFont(ofSize: 11, weight: .bold)
        nhanPhai.textColor = .white
        nhanPhai.textAlignment = .right
        nhanPhai.numberOfLines = 0
        nhanPhai.lineBreakMode = .byWordWrapping
        nhanPhai.adjustsFontSizeToFitWidth = false

        [nhanTrai, nhanPhai].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            header.addSubview($0)
        }
        NSLayoutConstraint.activate([
            nhanTrai.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 10),
            nhanTrai.topAnchor.constraint(equalTo: header.topAnchor, constant: 4),
            nhanTrai.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -4),
            nhanPhai.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -10),
            nhanPhai.topAnchor.constraint(equalTo: header.topAnchor, constant: 4),
            nhanPhai.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -4),
            nhanTrai.trailingAnchor.constraint(lessThanOrEqualTo: nhanPhai.leadingAnchor, constant: -6)
        ])
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        44
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ma = "XepHangNVNganhCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: ma) ?? UITableViewCell(style: .default, reuseIdentifier: ma)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let item = danhSachXepHang[indexPath.row]
        let hang = indexPath.row + 1
        let dat = item.daDat
        let kha = item.phanTramHT >= 80.0

        let nenKhung = UIView()
        nenKhung.layer.cornerRadius = 8
        nenKhung.clipsToBounds = true
        nenKhung.backgroundColor = dat
            ? UIColor(red: 0.94, green: 0.99, blue: 0.96, alpha: 1)
            : (kha ? UIColor(red: 0.94, green: 0.96, blue: 1.0, alpha: 1) : UIColor(red: 1.0, green: 0.99, blue: 0.92, alpha: 1))
        nenKhung.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(nenKhung)

        let thanhTienDo = UIView()
        thanhTienDo.backgroundColor = dat
            ? UIColor(red: 0.86, green: 0.99, blue: 0.90, alpha: 1)
            : (kha ? UIColor(red: 0.86, green: 0.92, blue: 0.99, alpha: 1) : UIColor(red: 0.99, green: 0.94, blue: 0.54, alpha: 0.65))
        thanhTienDo.translatesAutoresizingMaskIntoConstraints = false
        nenKhung.addSubview(thanhTienDo)

        let fontDongNhat = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .bold)

        let nhanHang = UILabel()
        nhanHang.text = KhoDuLieu.huyChuongHang(hang)
        nhanHang.font = fontDongNhat
        nhanHang.textAlignment = .center
        nhanHang.numberOfLines = 0
        nhanHang.lineBreakMode = .byWordWrapping
        nhanHang.adjustsFontSizeToFitWidth = false

        let nhanTen = UILabel()
        nhanTen.text = "\(item.hoTen) - \(item.maNV)"
        nhanTen.font = .systemFont(ofSize: 12, weight: .bold)
        nhanTen.textColor = .label
        nhanTen.numberOfLines = 0
        nhanTen.lineBreakMode = .byWordWrapping
        nhanTen.adjustsFontSizeToFitWidth = false

        let nhanThucHien = UILabel()
        nhanThucHien.text = "\(item.thucHien.chuoiSoGonVN) / \(item.targetCaNhan.chuoiSoGonVN)"
        nhanThucHien.font = fontDongNhat
        nhanThucHien.textAlignment = .right
        nhanThucHien.numberOfLines = 0
        nhanThucHien.lineBreakMode = .byWordWrapping
        nhanThucHien.adjustsFontSizeToFitWidth = false

        let vuot = item.thucHien - item.targetCaNhan
        let nhanChenh = UILabel()
        nhanChenh.text = vuot >= -0.005 ? "+\(max(0, vuot).chuoiSoGonVN)" : "-\(abs(vuot).chuoiSoGonVN)"
        nhanChenh.font = fontDongNhat
        nhanChenh.textColor = vuot >= -0.005 ? UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1) : .secondaryLabel
        nhanChenh.textAlignment = .right
        nhanChenh.numberOfLines = 0
        nhanChenh.lineBreakMode = .byWordWrapping
        nhanChenh.adjustsFontSizeToFitWidth = false

        let nhanBadge = UILabel()
        nhanBadge.text = "\(Int(round(item.phanTramHT)))%"
        nhanBadge.font = fontDongNhat
        nhanBadge.textAlignment = .center
        nhanBadge.numberOfLines = 0
        nhanBadge.lineBreakMode = .byWordWrapping
        nhanBadge.adjustsFontSizeToFitWidth = false
        nhanBadge.layer.cornerRadius = 6
        nhanBadge.clipsToBounds = true
        nhanBadge.backgroundColor = dat
            ? UIColor(red: 0.80, green: 0.96, blue: 0.85, alpha: 1)
            : (kha ? UIColor(red: 0.82, green: 0.89, blue: 0.99, alpha: 1) : UIColor(red: 0.99, green: 0.92, blue: 0.75, alpha: 1))
        nhanBadge.textColor = dat
            ? UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1)
            : (kha ? UIColor(red: 0.11, green: 0.31, blue: 0.85, alpha: 1) : UIColor(red: 0.71, green: 0.33, blue: 0.04, alpha: 1))

        [nhanHang, nhanTen, nhanThucHien, nhanChenh, nhanBadge].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            nenKhung.addSubview($0)
        }

        let tyLe = CGFloat(min(1.0, max(0.03, item.phanTramHT / 100.0)))
        NSLayoutConstraint.activate([
            nenKhung.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 3),
            nenKhung.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -3),
            nenKhung.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 6),
            nenKhung.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -6),

            thanhTienDo.leadingAnchor.constraint(equalTo: nenKhung.leadingAnchor),
            thanhTienDo.topAnchor.constraint(equalTo: nenKhung.topAnchor),
            thanhTienDo.bottomAnchor.constraint(equalTo: nenKhung.bottomAnchor),
            thanhTienDo.widthAnchor.constraint(equalTo: nenKhung.widthAnchor, multiplier: tyLe),

            nhanHang.leadingAnchor.constraint(equalTo: nenKhung.leadingAnchor, constant: 6),
            nhanHang.centerYAnchor.constraint(equalTo: nenKhung.centerYAnchor),
            nhanHang.widthAnchor.constraint(equalToConstant: 26),

            nhanBadge.trailingAnchor.constraint(equalTo: nenKhung.trailingAnchor, constant: -6),
            nhanBadge.centerYAnchor.constraint(equalTo: nenKhung.centerYAnchor),
            nhanBadge.widthAnchor.constraint(equalToConstant: 48),
            nhanBadge.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),

            nhanChenh.trailingAnchor.constraint(equalTo: nhanBadge.leadingAnchor, constant: -6),
            nhanChenh.centerYAnchor.constraint(equalTo: nenKhung.centerYAnchor),
            nhanChenh.widthAnchor.constraint(equalToConstant: 56),

            nhanThucHien.trailingAnchor.constraint(equalTo: nhanChenh.leadingAnchor, constant: -6),
            nhanThucHien.centerYAnchor.constraint(equalTo: nenKhung.centerYAnchor),
            nhanThucHien.widthAnchor.constraint(greaterThanOrEqualToConstant: 68),

            nhanTen.leadingAnchor.constraint(equalTo: nhanHang.trailingAnchor, constant: 4),
            nhanTen.trailingAnchor.constraint(lessThanOrEqualTo: nhanThucHien.leadingAnchor, constant: -6),
            nhanTen.centerYAnchor.constraint(equalTo: nenKhung.centerYAnchor)
        ])

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < danhSachXepHang.count else { return }
        let item = danhSachXepHang[indexPath.row]
        let thucHienMon = dong.thucHien
        let hop = UIAlertController(
            title: "\(item.hoTen) (\(item.maNV))",
            message: "Môn \(dong.tenNganhHang) • Đã thực hiện: \(thucHienMon.chuoiSoGonVN) • Target chia: \(item.targetCaNhan.chuoiSoGonVN)\nNhập % đóng góp của nhân viên (tự tính = Đã thực hiện ÷ 100 × %) hoặc nhập trực tiếp số lượng:",
            preferredStyle: .alert
        )
        hop.addTextField { tf in
            tf.placeholder = "Nhập % (VD: 24) hoặc số thực hiện"
            tf.keyboardType = .decimalPad
            if item.thucHien > 0 {
                tf.text = item.thucHien.chuoiSoGonVN.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            }
        }
        hop.addAction(UIAlertAction(title: "Lưu theo % của môn (÷100 × %)", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let chu = (hop.textFields?.first?.text ?? "")
                .replacingOccurrences(of: "%", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: ".")
            let phanTram = Double(chu) ?? 0
            let giaTri = self.dong.thucHien > 0 ? (((self.dong.thucHien / 100.0) * phanTram * 10000.0).rounded() / 10000.0) : phanTram
            let khoa = KhoDuLieu.chuanHoaKhoaSoSanh(self.dong.tenNganhHang)
            var dl = KhoDuLieu.dungChung.duLieu(cho: self.ngay)
            var bangNV = dl.thiDuaNhanVien(theo: self.cheDo)
            bangNV[khoa, default: [:]][item.maNV] = giaTri
            dl.ganThiDuaNhanVien(bangNV, theo: self.cheDo)
            KhoDuLieu.dungChung.luu(dl)
            self.napDuLieu()
            self.khiCapNhatDuLieu?()
        })
        hop.addAction(UIAlertAction(title: "Lưu số lượng trực tiếp", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let chuGoc = (hop.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let coDauPhanTram = chuGoc.contains("%")
            let chu = chuGoc
                .replacingOccurrences(of: "%", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: ".")
            let soNhap = Double(chu) ?? 0
            let giaTri = (coDauPhanTram && self.dong.thucHien > 0)
                ? (((self.dong.thucHien / 100.0) * soNhap * 10000.0).rounded() / 10000.0)
                : soNhap
            let khoa = KhoDuLieu.chuanHoaKhoaSoSanh(self.dong.tenNganhHang)
            var dl = KhoDuLieu.dungChung.duLieu(cho: self.ngay)
            var bangNV = dl.thiDuaNhanVien(theo: self.cheDo)
            bangNV[khoa, default: [:]][item.maNV] = giaTri
            dl.ganThiDuaNhanVien(bangNV, theo: self.cheDo)
            KhoDuLieu.dungChung.luu(dl)
            self.napDuLieu()
            self.khiCapNhatDuLieu?()
        })
        hop.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        present(hop, animated: true)
    }

    // MARK: - Xuất ảnh Bảng xếp hạng nhân viên của ngành hàng

    @objc private func bamXuatAnhBangNganhHang() {
        guard !danhSachXepHang.isEmpty else { return }
        guard let anh = taoAnhBangNganhHang() else { return }
        let vc = UIActivityViewController(activityItems: [anh], applicationActivities: nil)
        if let pop = vc.popoverPresentationController {
            pop.barButtonItem = navigationItem.rightBarButtonItems?.first
        }
        present(vc, animated: true)
    }

    private func taoAnhBangNganhHang() -> UIImage? {
        let soNV = danhSachXepHang.count
        guard soNV > 0 else { return nil }
        let ngayStr = TienIchNgay.hienThiNgay.string(from: ngay)
        let targetMoiNV = dong.target / Double(soNV)
        let tongTH = danhSachXepHang.reduce(0.0) { $0 + $1.thucHien }
        let tyLeChung = dong.target > 0 ? Int(round(tongTH / dong.target * 100.0)) : 0

        let rong: CGFloat = 780
        let le: CGFloat = 22
        let fontTieuDe = UIFont.systemFont(ofSize: 18, weight: .heavy)
        let fontDong = UIFont.monospacedDigitSystemFont(ofSize: 12.5, weight: .bold)
        let fontTen = UIFont.systemFont(ofSize: 12.5, weight: .bold)

        let caoTenNganh = max(26, ceil((dong.tenNganhHang as NSString).boundingRect(
            with: CGSize(width: rong - le * 2 - 280, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontTieuDe],
            context: nil
        ).height))
        let caoHeader: CGFloat = 30 + caoTenNganh + 12
        let caoTieuDeCot: CGFloat = 34
        let cacCaoDong: [CGFloat] = danhSachXepHang.map { item in
            let chuoiTen = "\(item.hoTen) - \(item.maNV)"
            let rect = (chuoiTen as NSString).boundingRect(
                with: CGSize(width: CGFloat(340), height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: fontTen],
                context: nil
            )
            return max(44, ceil(rect.height) + 22)
        }
        let tongCaoDong = cacCaoDong.reduce(0, +)
        let caoChan: CGFloat = 52
        let cao = le * 2 + caoHeader + caoTieuDeCot + tongCaoDong + caoChan

        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2.0
        return UIGraphicsImageRenderer(size: CGSize(width: rong, height: cao), format: fmt).image { ctx in
            let cg = ctx.cgContext
            UIColor.white.setFill()
            cg.fill(CGRect(x: 0, y: 0, width: rong, height: cao))

            let pLeft = NSMutableParagraphStyle(); pLeft.alignment = .left; pLeft.lineBreakMode = .byWordWrapping
            let pRight = NSMutableParagraphStyle(); pRight.alignment = .right; pRight.lineBreakMode = .byWordWrapping
            let pCenter = NSMutableParagraphStyle(); pCenter.alignment = .center; pCenter.lineBreakMode = .byWordWrapping

            (cheDo.tieuDe.uppercased() as NSString).draw(at: CGPoint(x: le, y: le + 4), withAttributes: [
                .font: UIFont.systemFont(ofSize: 12.5, weight: .bold),
                .foregroundColor: UIColor.darkGray
            ])
            (dong.tenNganhHang as NSString).draw(in: CGRect(x: le, y: le + 24, width: rong - le * 2 - 280, height: caoTenNganh + 4), withAttributes: [
                .font: fontTieuDe,
                .foregroundColor: UIColor.black,
                .paragraphStyle: pLeft
            ])
            let subRight = "Ngày \(ngayStr) • Chia đều \(soNV) NV (\(targetMoiNV.chuoiSoGonVN)/NV)"
            (subRight as NSString).draw(in: CGRect(x: rong - le - 270, y: le + 18, width: 270, height: 42), withAttributes: [
                .font: UIFont.systemFont(ofSize: 12.5, weight: .semibold),
                .foregroundColor: UIColor.darkGray,
                .paragraphStyle: pRight
            ])

            var y = le + caoHeader
            let headerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11.5, weight: .bold),
                .foregroundColor: UIColor.gray
            ]
            ("#" as NSString).draw(at: CGPoint(x: le + 10, y: y + 8), withAttributes: headerAttr)
            ("NHÂN VIÊN" as NSString).draw(at: CGPoint(x: le + 46, y: y + 8), withAttributes: headerAttr)
            ("THỰC HIỆN" as NSString).draw(in: CGRect(x: rong - le - 300, y: y + 8, width: 110, height: 18), withAttributes: headerAttr.merging([.paragraphStyle: pRight]) { $1 })
            ("CÒN / VƯỢT" as NSString).draw(in: CGRect(x: rong - le - 180, y: y + 8, width: 96, height: 18), withAttributes: headerAttr.merging([.paragraphStyle: pRight]) { $1 })
            ("% HT" as NSString).draw(in: CGRect(x: rong - le - 68, y: y + 8, width: 62, height: 18), withAttributes: headerAttr.merging([.paragraphStyle: pCenter]) { $1 })

            y += caoTieuDeCot

            for (idx, item) in danhSachXepHang.enumerated() {
                let caoDong = cacCaoDong[idx]
                let hang = idx + 1
                let dat = item.daDat
                let kha = item.phanTramHT >= 80.0
                let bgTrack = dat ? UIColor(red: 0.94, green: 0.99, blue: 0.96, alpha: 1) : (kha ? UIColor(red: 0.94, green: 0.96, blue: 1.0, alpha: 1) : UIColor(red: 0.99, green: 0.99, blue: 0.91, alpha: 1))
                let bgFill = dat ? UIColor(red: 0.86, green: 0.99, blue: 0.90, alpha: 1) : (kha ? UIColor(red: 0.86, green: 0.92, blue: 0.99, alpha: 1) : UIColor(red: 0.99, green: 0.94, blue: 0.54, alpha: 1))

                let rectRow = CGRect(x: le, y: y + 3, width: rong - le * 2, height: caoDong - 6)
                bgTrack.setFill()
                UIBezierPath(roundedRect: rectRow, cornerRadius: 8).fill()

                let pctW = CGFloat(min(1.0, max(0.03, item.phanTramHT / 100.0))) * rectRow.width
                bgFill.setFill()
                UIBezierPath(roundedRect: CGRect(x: le, y: y + 3, width: pctW, height: caoDong - 6), cornerRadius: 8).fill()

                let yGiua = y + (caoDong - 20) / 2
                (KhoDuLieu.huyChuongHang(hang) as NSString).draw(in: CGRect(x: le + 6, y: yGiua, width: 28, height: 22), withAttributes: [
                    .font: fontDong,
                    .foregroundColor: UIColor.darkGray,
                    .paragraphStyle: pCenter
                ])
                ("\(item.hoTen) - \(item.maNV)" as NSString).draw(in: CGRect(x: le + 46, y: y + 10, width: 340, height: caoDong - 20), withAttributes: [
                    .font: fontTen,
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: pLeft
                ])
                ("\(item.thucHien.chuoiSoGonVN) / \(item.targetCaNhan.chuoiSoGonVN)" as NSString).draw(in: CGRect(x: rong - le - 315, y: yGiua, width: 125, height: 22), withAttributes: [
                    .font: fontDong,
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: pRight
                ])
                let vuot = item.thucHien - item.targetCaNhan
                let strDiff = vuot >= -0.005 ? "Vượt +\(max(0, vuot).chuoiSoGonVN)" : "Còn \(abs(vuot).chuoiSoGonVN)"
                (strDiff as NSString).draw(in: CGRect(x: rong - le - 184, y: yGiua, width: 100, height: 22), withAttributes: [
                    .font: fontDong,
                    .foregroundColor: vuot >= -0.005 ? UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1) : UIColor.darkGray,
                    .paragraphStyle: pRight
                ])

                let badgeRect = CGRect(x: rong - le - 68, y: y + (caoDong - 24) / 2, width: 62, height: 24)
                let badgeBg = dat ? UIColor(red: 0.86, green: 0.99, blue: 0.90, alpha: 1) : (kha ? UIColor(red: 0.86, green: 0.92, blue: 0.99, alpha: 1) : UIColor(red: 0.99, green: 0.95, blue: 0.78, alpha: 1))
                let badgeFg = dat ? UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1) : (kha ? UIColor(red: 0.11, green: 0.31, blue: 0.85, alpha: 1) : UIColor(red: 0.71, green: 0.33, blue: 0.04, alpha: 1))
                badgeBg.setFill()
                UIBezierPath(roundedRect: badgeRect, cornerRadius: 6).fill()
                ("\(Int(round(item.phanTramHT)))%" as NSString).draw(in: CGRect(x: badgeRect.minX, y: badgeRect.minY + 4, width: badgeRect.width, height: 18), withAttributes: [
                    .font: fontDong,
                    .foregroundColor: badgeFg,
                    .paragraphStyle: pCenter
                ])

                y += caoDong
            }

            UIColor.lightGray.setFill()
            cg.fill(CGRect(x: le, y: y + 8, width: rong - le * 2, height: 1))
            ("TỔNG CỘNG:  \(tongTH.chuoiSoGonVN) / \(dong.target.chuoiSoGonVN)   •   \(soNV) nhân viên" as NSString).draw(at: CGPoint(x: le, y: y + 20), withAttributes: [
                .font: UIFont.systemFont(ofSize: 13.5, weight: .heavy),
                .foregroundColor: UIColor.black
            ])
            ("Tỷ lệ HT: \(tyLeChung)%" as NSString).draw(in: CGRect(x: rong - le - 160, y: y + 20, width: 160, height: 22), withAttributes: [
                .font: UIFont.systemFont(ofSize: 13.5, weight: .heavy),
                .foregroundColor: UIColor(red: 0.11, green: 0.31, blue: 0.85, alpha: 1),
                .paragraphStyle: pRight
            ])
        }
    }
}

// MARK: - 2. BangNhanVienView (Tab Nhân viên trên màn hình chính: 2 nút nhập ảnh đã được gom lên cùng 1 hàng phía trên)

final class BangNhanVienView: UIView, UITableViewDataSource, UITableViewDelegate {
    var khiChonNhanVien: ((TongHopNhanVien) -> Void)?
    var khiBamQuetDoanhThuNV: (() -> Void)?
    var khiBamMoCaiDatNV: (() -> Void)?
    var khiBamChiaSeAnhNV: (() -> Void)?

    private static let khoaKieuSapXepNhanVien = "dmx.nhanVien.kieuSapXep"
    private var ngayHienTai = Date()
    private(set) var cheDoDoanhThu: LoaiCheDoDoanhThu = .luyKe
    private var kieuSapXep: KieuSapXepNhanVien = {
        if UserDefaults.standard.object(forKey: BangNhanVienView.khoaKieuSapXepNhanVien) != nil,
           let luu = KieuSapXepNhanVien(rawValue: UserDefaults.standard.integer(forKey: BangNhanVienView.khoaKieuSapXepNhanVien)) {
            return luu
        }
        return .doanhThuQD
    }()
    private var danhSach: [TongHopNhanVien] = []
    private var danhSachDaNapUI: [TongHopNhanVien]?
    private var cheDoDaNapUI: LoaiCheDoDoanhThu?
    private var khoaNgayDaNapUI: String = ""
    private var phienBanDaNapUI: Int = -1
    private var sapXepDaNapUI: KieuSapXepNhanVien?

    private let chieuRongCot: [CGFloat] = [44, 170, 78, 92, 84, 78, 96, 92]
    private var tongChieuRongBang: CGFloat { chieuRongCot.reduce(0, +) }

    private let nhanTieuDe = UILabel()
    private let nutChiaSeAnh = UIButton(type: .system)
    private let nutSapXep = UIButton(type: .system)
    private let cuonNgang = UIScrollView()
    private let bang = UITableView(frame: .zero, style: .plain)
    private let khungTrong = UIControl()

    override init(frame: CGRect) {
        super.init(frame: frame)
        taoGiaoDien()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func taoGiaoDien() {
        backgroundColor = .clear

        nhanTieuDe.font = .systemFont(ofSize: 12.5, weight: .bold)
        nhanTieuDe.textColor = BangMauBCTD.chuChinh
        nhanTieuDe.text = "🏆 Bảng Xếp Hạng Nhân Viên"
        nhanTieuDe.numberOfLines = 0
        nhanTieuDe.lineBreakMode = .byWordWrapping
        nhanTieuDe.adjustsFontSizeToFitWidth = false

        nutSapXep.setTitle(" ⇅ \(kieuSapXep.nhanNgan)", for: .normal)
        nutSapXep.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutSapXep.titleLabel?.numberOfLines = 0
        nutSapXep.titleLabel?.lineBreakMode = .byWordWrapping
        nutSapXep.titleLabel?.textAlignment = .center
        nutSapXep.titleLabel?.adjustsFontSizeToFitWidth = false
        nutSapXep.backgroundColor = BangMauBCTD.nenMenuToi
        nutSapXep.tintColor = BangMauBCTD.vangChuDao
        nutSapXep.setTitleColor(BangMauBCTD.vangChuDao, for: .normal)
        nutSapXep.layer.cornerRadius = 8
        nutSapXep.layer.borderWidth = 1
        nutSapXep.layer.borderColor = BangMauBCTD.vangChuDao.withAlphaComponent(0.5).cgColor
        nutSapXep.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        nutSapXep.setContentHuggingPriority(.required, for: .horizontal)
        nutSapXep.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutSapXep.addTarget(self, action: #selector(bamMoMenuSapXep), for: .touchUpInside)

        let cfgShare = UIImage.SymbolConfiguration(pointSize: 11.5, weight: .bold)
        nutChiaSeAnh.setImage(UIImage(systemName: "square.and.arrow.up", withConfiguration: cfgShare), for: .normal)
        nutChiaSeAnh.setTitle(" Chia sẻ ảnh", for: .normal)
        nutChiaSeAnh.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutChiaSeAnh.titleLabel?.numberOfLines = 0
        nutChiaSeAnh.titleLabel?.lineBreakMode = .byWordWrapping
        nutChiaSeAnh.titleLabel?.textAlignment = .center
        nutChiaSeAnh.titleLabel?.adjustsFontSizeToFitWidth = false
        nutChiaSeAnh.backgroundColor = BangMauBCTD.xanhDatVach
        nutChiaSeAnh.tintColor = .white
        nutChiaSeAnh.setTitleColor(.white, for: .normal)
        nutChiaSeAnh.layer.cornerRadius = 8
        nutChiaSeAnh.contentEdgeInsets = UIEdgeInsets(top: 6, left: 9, bottom: 6, right: 9)
        nutChiaSeAnh.setContentHuggingPriority(.required, for: .horizontal)
        nutChiaSeAnh.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutChiaSeAnh.addTarget(self, action: #selector(bamChiaSeAnh), for: .touchUpInside)

        let thanhDieuKhien = UIStackView(arrangedSubviews: [nhanTieuDe, nutChiaSeAnh, nutSapXep])
        thanhDieuKhien.axis = .horizontal
        thanhDieuKhien.spacing = 8
        thanhDieuKhien.alignment = .center

        cuonNgang.showsHorizontalScrollIndicator = true
        cuonNgang.showsVerticalScrollIndicator = false
        cuonNgang.bounces = false
        cuonNgang.layer.cornerRadius = 12
        cuonNgang.clipsToBounds = true
        cuonNgang.backgroundColor = .systemBackground

        bang.dataSource = self
        bang.delegate = self
        bang.rowHeight = 56
        bang.sectionHeaderHeight = 42
        bang.separatorStyle = .singleLine
        bang.separatorInset = .zero
        bang.backgroundColor = .systemBackground
        if #available(iOS 15.0, *) {
            bang.sectionHeaderTopPadding = 0
        }
        bang.translatesAutoresizingMaskIntoConstraints = false
        cuonNgang.addSubview(bang)

        khungTrong.backgroundColor = .secondarySystemGroupedBackground
        khungTrong.layer.cornerRadius = 14
        khungTrong.addTarget(self, action: #selector(bamMoCaiDat), for: .touchUpInside)

        let nhanTrong = UILabel()
        nhanTrong.text = "Chưa có nhân viên trong danh sách quản lý.\nChạm vào đây để thêm nhân viên."
        nhanTrong.font = .systemFont(ofSize: 13.5, weight: .semibold)
        nhanTrong.textColor = .secondaryLabel
        nhanTrong.textAlignment = .center
        nhanTrong.numberOfLines = 0
        nhanTrong.lineBreakMode = .byWordWrapping
        nhanTrong.adjustsFontSizeToFitWidth = false
        nhanTrong.isUserInteractionEnabled = false
        nhanTrong.translatesAutoresizingMaskIntoConstraints = false
        khungTrong.addSubview(nhanTrong)

        [thanhDieuKhien, cuonNgang, khungTrong].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            thanhDieuKhien.topAnchor.constraint(equalTo: topAnchor),
            thanhDieuKhien.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            thanhDieuKhien.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            thanhDieuKhien.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),

            cuonNgang.topAnchor.constraint(equalTo: thanhDieuKhien.bottomAnchor, constant: 6),
            cuonNgang.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            cuonNgang.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            cuonNgang.bottomAnchor.constraint(equalTo: bottomAnchor),

            bang.topAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.topAnchor),
            bang.bottomAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.bottomAnchor),
            bang.leadingAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.leadingAnchor),
            bang.trailingAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.trailingAnchor),
            bang.heightAnchor.constraint(equalTo: cuonNgang.frameLayoutGuide.heightAnchor),
            bang.widthAnchor.constraint(equalToConstant: tongChieuRongBang),

            khungTrong.topAnchor.constraint(equalTo: thanhDieuKhien.bottomAnchor, constant: 6),
            khungTrong.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            khungTrong.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            khungTrong.bottomAnchor.constraint(equalTo: bottomAnchor),

            nhanTrong.centerXAnchor.constraint(equalTo: khungTrong.centerXAnchor),
            nhanTrong.centerYAnchor.constraint(equalTo: khungTrong.centerYAnchor),
            nhanTrong.leadingAnchor.constraint(equalTo: khungTrong.leadingAnchor, constant: 20),
            nhanTrong.trailingAnchor.constraint(equalTo: khungTrong.trailingAnchor, constant: -20)
        ])
    }

    @objc private func bamMoMenuSapXep() {
        guard let vc = timViewControllerCha() else { return }
        var cacMuc: [MucChonDMX] = KieuSapXepNhanVien.allCases.map { kieu in
            MucChonDMX(tieuDe: kieu.nhan, dangChon: kieu == kieuSapXep) { [weak self] in
                guard let self = self else { return }
                self.kieuSapXep = kieu
                UserDefaults.standard.set(kieu.rawValue, forKey: Self.khoaKieuSapXepNhanVien)
                self.nutSapXep.setTitle(" ⇅ \(kieu.nhanNgan)", for: .normal)
                self.danhSachDaNapUI = nil
                self.capNhat(cho: self.ngayHienTai, cheDo: self.cheDoDoanhThu)
            }
        }
        cacMuc.append(MucChonDMX(tieuDe: "Đóng", kieu: .huy))
        vc.hienMenuChon(tieuDe: "Sắp xếp nhân viên", cacMuc: cacMuc)
    }

    @objc private func bamMoCaiDat() {
        khiBamMoCaiDatNV?()
    }

    @objc private func bamChiaSeAnh() {
        khiBamChiaSeAnhNV?()
    }

    func capNhat(cho ngay: Date, cheDo: LoaiCheDoDoanhThu = .luyKe) {
        ngayHienTai = ngay
        cheDoDoanhThu = cheDo
        let kho = KhoDuLieu.dungChung
        let khoaNgay = TienIchNgay.khoa.string(from: ngay)
        if phienBanDaNapUI == kho.phienBanDuLieu,
           khoaNgayDaNapUI == khoaNgay,
           cheDoDaNapUI == cheDo,
           sapXepDaNapUI == kieuSapXep,
           danhSachDaNapUI != nil {
            return
        }
        phienBanDaNapUI = kho.phienBanDuLieu
        khoaNgayDaNapUI = khoaNgay
        cheDoDaNapUI = cheDo
        sapXepDaNapUI = kieuSapXep

        let moi = kho.tongHopNhanVien(den: ngay, sapXep: kieuSapXep, cheDo: cheDo)
        let soMonThang = kho.danhSachMatHangThang(den: ngay, cheDo: cheDo).count
        nhanTieuDe.text = "🏆 Xếp Hạng \(cheDo.tieuDe) (\(moi.count) NV • \(soMonThang) môn)"

        let trong = moi.isEmpty
        khungTrong.isHidden = !trong
        cuonNgang.isHidden = trong

        danhSach = moi
        danhSachDaNapUI = moi
        bang.reloadData()
    }

    func gan(_ moi: [TongHopNhanVien]) {
        danhSach = moi
        danhSachDaNapUI = moi
        let trong = danhSach.isEmpty
        khungTrong.isHidden = !trong
        cuonNgang.isHidden = trong
        bang.reloadData()
    }

    private func tinhChieuCaoDongNV(_ row: TongHopNhanVien) -> CGFloat {
        let rongTen = chieuRongCot[1] - 16
        let fontTen = UIFont.systemFont(ofSize: 12.5, weight: .bold)
        let fontMa = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        let rectTen = (row.nhanVien.hoTen as NSString).boundingRect(
            with: CGSize(width: rongTen, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontTen],
            context: nil
        )
        let chuoiMa = "id: \(row.nhanVien.maNV)"
        let rectMa = (chuoiMa as NSString).boundingRect(
            with: CGSize(width: rongTen, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontMa],
            context: nil
        )
        return max(56, ceil(rectTen.height) + ceil(rectMa.height) + 16)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        danhSach.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        tinhChieuCaoDongNV(danhSach[indexPath.row])
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let khung = UIView(frame: CGRect(x: 0, y: 0, width: tongChieuRongBang, height: 42))
        khung.backgroundColor = BangMauBCTD.nenHeaderBang

        let tieuDe = ["HẠNG", "NHÂN VIÊN (CHẠM XEM SK)", "% TỈ TRỌNG", "DOANH THU QĐ", "% HT TB", "SỐ LƯỢNG", "SỐ MÔN ĐẠT", "DT KHOẢN VAY"]
        var xHienTai: CGFloat = 0
        for (i, chu) in tieuDe.enumerated() {
            let w = chieuRongCot[i]
            let nhan = UILabel(frame: CGRect(x: xHienTai + 4, y: 2, width: w - 8, height: 37))
            nhan.text = chu
            nhan.font = .systemFont(ofSize: 10.5, weight: .bold)
            nhan.textColor = (i == 3 || i == 6) ? BangMauBCTD.vangChuDao : .white
            nhan.numberOfLines = 0
            nhan.lineBreakMode = .byWordWrapping
            nhan.adjustsFontSizeToFitWidth = false
            nhan.textAlignment = (i == 1) ? .left : ((i == 0 || i == 4 || i == 6) ? .center : .right)
            khung.addSubview(nhan)

            xHienTai += w
            if i < tieuDe.count - 1 {
                let vach = UIView(frame: CGRect(x: xHienTai, y: 0, width: 0.5, height: 42))
                vach.backgroundColor = UIColor.white.withAlphaComponent(0.14)
                khung.addSubview(vach)
            }
        }
        let vachDuoi = UIView(frame: CGRect(x: 0, y: 39.5, width: tongChieuRongBang, height: 2.5))
        vachDuoi.backgroundColor = BangMauBCTD.vangChuDao
        khung.addSubview(vachDuoi)
        return khung
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ma = "DongTongHopNV8Cot"
        let cell = tableView.dequeueReusableCell(withIdentifier: ma) ?? UITableViewCell(style: .default, reuseIdentifier: ma)
        cell.selectionStyle = .default
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let row = danhSach[indexPath.row]
        let caoDong = tinhChieuCaoDongNV(row)
        let hang = indexPath.row + 1
        let laTop3 = hang <= 3

        let khung = UIView(frame: CGRect(x: 0, y: 0, width: tongChieuRongBang, height: caoDong))
        khung.backgroundColor = laTop3
            ? BangMauBCTD.xanhDatNenDong
            : ((indexPath.row % 2 == 1) ? BangMauBCTD.nenThePhu : BangMauBCTD.nenThe)
        let vachTrai = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: caoDong))
        vachTrai.backgroundColor = hang == 1
            ? BangMauBCTD.vangChuDao
            : (laTop3 ? BangMauBCTD.xanhDatVach : BangMauBCTD.indigoChuDao.withAlphaComponent(0.45))
        khung.addSubview(vachTrai)
        cell.contentView.addSubview(khung)

        let fontDongNhat = UIFont.monospacedDigitSystemFont(ofSize: 12.5, weight: .bold)
        let fontChuDongNhat = UIFont.systemFont(ofSize: 12.5, weight: .bold)

        var x: CGFloat = 0
        for i in 0..<chieuRongCot.count {
            let w = chieuRongCot[i]
            let rect = CGRect(x: x, y: 0, width: w, height: caoDong)

            switch i {
            case 0:
                let lb = UILabel(frame: rect)
                lb.text = KhoDuLieu.huyChuongHang(hang)
                lb.font = fontDongNhat
                lb.textAlignment = .center
                lb.numberOfLines = 0
                lb.lineBreakMode = .byWordWrapping
                lb.adjustsFontSizeToFitWidth = false
                khung.addSubview(lb)
            case 1:
                let rongTen = w - 16
                let rectTen = (row.nhanVien.hoTen as NSString).boundingRect(
                    with: CGSize(width: rongTen, height: CGFloat.greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: fontChuDongNhat],
                    context: nil
                )
                let caoTen = max(20, ceil(rectTen.height))
                let caoMa = max(18, caoDong - caoTen - 12)

                let lbTen = UILabel(frame: CGRect(x: x + 8, y: 5, width: rongTen, height: caoTen))
                lbTen.text = row.nhanVien.hoTen
                lbTen.font = fontChuDongNhat
                lbTen.numberOfLines = 0
                lbTen.lineBreakMode = .byWordWrapping
                lbTen.adjustsFontSizeToFitWidth = false

                let lbMa = UILabel(frame: CGRect(x: x + 8, y: 5 + caoTen + 2, width: rongTen, height: caoMa))
                lbMa.text = "id: \(row.nhanVien.maNV)"
                lbMa.font = .systemFont(ofSize: 12.0, weight: .medium)
                lbMa.textColor = .secondaryLabel
                lbMa.numberOfLines = 0
                lbMa.lineBreakMode = .byWordWrapping
                lbMa.adjustsFontSizeToFitWidth = false

                khung.addSubview(lbTen)
                khung.addSubview(lbMa)
            case 2:
                let lb = UILabel(frame: rect.insetBy(dx: 6, dy: 2))
                lb.text = String(format: "%.1f%%", row.phanTramTiTrong)
                lb.font = fontDongNhat
                lb.textColor = row.phanTramTiTrong < 0 ? .systemRed : BangMauBCTD.chuChinh
                lb.textAlignment = .right
                lb.numberOfLines = 0
                lb.lineBreakMode = .byWordWrapping
                lb.adjustsFontSizeToFitWidth = false
                khung.addSubview(lb)
            case 3:
                let lb = UILabel(frame: rect.insetBy(dx: 6, dy: 2))
                lb.text = row.doanhThuQD.chuoiSoLieu
                lb.font = fontDongNhat
                lb.textColor = row.doanhThuQD < 0 ? .systemRed : UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1)
                lb.textAlignment = .right
                lb.numberOfLines = 0
                lb.lineBreakMode = .byWordWrapping
                lb.adjustsFontSizeToFitWidth = false
                khung.addSubview(lb)
            case 4:
                let lb = UILabel(frame: rect.insetBy(dx: 4, dy: 2))
                lb.text = row.tongMonGiao > 0 ? String(format: "%.1f%%", row.phanTramHTTB) : "--"
                lb.font = fontDongNhat
                lb.textAlignment = .center
                lb.numberOfLines = 0
                lb.lineBreakMode = .byWordWrapping
                lb.adjustsFontSizeToFitWidth = false
                khung.addSubview(lb)
            case 5:
                let lb = UILabel(frame: rect.insetBy(dx: 6, dy: 2))
                lb.text = row.soLuongDon.chuoiSoNguyenVN
                lb.font = fontDongNhat
                lb.textColor = row.soLuongDon < 0 ? .systemRed : .secondaryLabel
                lb.textAlignment = .right
                lb.numberOfLines = 0
                lb.lineBreakMode = .byWordWrapping
                lb.adjustsFontSizeToFitWidth = false
                khung.addSubview(lb)
            case 6:
                let pill = UILabel(frame: rect.insetBy(dx: 5, dy: max(6, (caoDong - 34) / 2)))
                pill.text = "🏆 \(row.soMonDat)/\(row.tongMonGiao) môn"
                pill.font = fontChuDongNhat
                pill.textAlignment = .center
                pill.numberOfLines = 0
                pill.lineBreakMode = .byWordWrapping
                pill.adjustsFontSizeToFitWidth = false
                pill.layer.cornerRadius = 8
                pill.clipsToBounds = true
                pill.backgroundColor = row.soMonDat > 0 ? UIColor.systemGreen.withAlphaComponent(0.16) : UIColor.systemRed.withAlphaComponent(0.14)
                pill.textColor = row.soMonDat > 0 ? UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1) : UIColor(red: 0.78, green: 0.14, blue: 0.14, alpha: 1)
                khung.addSubview(pill)
            case 7:
                let lb = UILabel(frame: rect.insetBy(dx: 6, dy: 2))
                lb.text = row.dtQDKhoanVay > 0 ? row.dtQDKhoanVay.chuoiSoLieu : "0"
                lb.font = fontDongNhat
                lb.textColor = .secondaryLabel
                lb.textAlignment = .right
                lb.numberOfLines = 0
                lb.lineBreakMode = .byWordWrapping
                lb.adjustsFontSizeToFitWidth = false
                khung.addSubview(lb)
            default:
                break
            }

            x += w
            if i < chieuRongCot.count - 1 {
                let vach = UIView(frame: CGRect(x: x, y: 0, width: 0.5, height: caoDong))
                vach.backgroundColor = .separator
                khung.addSubview(vach)
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < danhSach.count else { return }
        khiChonNhanVien?(danhSach[indexPath.row])
    }

    // MARK: - Xuất Ảnh Bảng Xếp Hạng Tổng Hợp Nhân Viên

    func taoAnhBaoCaoNhanVien(
        ngay: Date,
        cheDo: LoaiCheDoDoanhThu? = nil,
        thongTinDonVi: String = "",
        capNhatLuc: String = ""
    ) -> UIImage? {
        let cheDoXuat = cheDo ?? cheDoDoanhThu
        let ds = KhoDuLieu.dungChung.tongHopNhanVien(den: ngay, sapXep: kieuSapXep, cheDo: cheDoXuat)
        let ngayStr = TienIchNgay.hienThiNgay.string(from: ngay)
        let soMonThang = KhoDuLieu.dungChung.danhSachMatHangThang(den: ngay, cheDo: cheDoXuat).count

        let tongDTQD = ds.reduce(0.0) { $0 + $1.doanhThuQD }
        let tongDon = ds.reduce(0.0) { $0 + $1.soLuongDon }
        let tongVay = ds.reduce(0.0) { $0 + $1.dtQDKhoanVay }
        let tbHT = ds.isEmpty ? 0.0 : (ds.reduce(0.0) { $0 + $1.phanTramHTTB } / Double(ds.count))

        let le: CGFloat = 18
        let rongBang = tongChieuRongBang
        let rongAnh = rongBang + le * 2

        let chuPhu = "\(cheDoXuat.tieuDe.uppercased())  •  Ngày \(ngayStr)\(capNhatLuc.isEmpty ? "" : "  •  Cập nhật: \(capNhatLuc)")"
        let fontPhu = UIFont.systemFont(ofSize: 12.5, weight: .bold)
        let caoPhu = max(20, ceil((chuPhu as NSString).boundingRect(
            with: CGSize(width: rongBang, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontPhu],
            context: nil
        ).height))

        let chuChinh = "🏆 BẢNG XẾP HẠNG NHÂN VIÊN - \(cheDoXuat.tieuDe.uppercased()) (\(ds.count) NV • \(soMonThang) MÔN)"
        let fontChinh = UIFont.systemFont(ofSize: 18.5, weight: .heavy)
        let caoChinh = max(28, ceil((chuChinh as NSString).boundingRect(
            with: CGSize(width: rongBang, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontChinh],
            context: nil
        ).height))

        let chuTomTat = "Tổng DT Quy đổi (\(cheDoXuat.tieuDe)): \(tongDTQD.chuoiSoGonVN)   •   Tổng đơn: \(tongDon.chuoiSoNguyenVN)   •   DT Khoản vay: \(tongVay.chuoiSoGonVN)   •   % HT TB: \(String(format: "%.1f%%", tbHT))"
        let fontTomTat = UIFont.systemFont(ofSize: 12.5, weight: .bold)
        let caoTextTomTat = max(24, ceil((chuTomTat as NSString).boundingRect(
            with: CGSize(width: rongBang - 24, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontTomTat],
            context: nil
        ).height))
        let caoTomTat = caoTextTomTat + 14

        let caoHeader = caoPhu + 4 + caoChinh
        let caoTieuDeCot: CGFloat = 42
        let cacCaoDong: [CGFloat] = ds.isEmpty ? [56] : ds.map { tinhChieuCaoDongNV($0) }
        let tongCaoDong = cacCaoDong.reduce(0, +)
        let caoBang = caoTieuDeCot + tongCaoDong
        let caoAnh = le * 2 + caoHeader + 8 + caoTomTat + 10 + caoBang

        let khungBaoCao = UIView(frame: CGRect(x: 0, y: 0, width: rongAnh, height: caoAnh))
        khungBaoCao.backgroundColor = .white
        khungBaoCao.overrideUserInterfaceStyle = .light

        let lbPhu = UILabel(frame: CGRect(x: le, y: le, width: rongBang, height: caoPhu))
        lbPhu.text = chuPhu
        lbPhu.font = fontPhu
        lbPhu.textColor = .darkGray
        lbPhu.numberOfLines = 0
        lbPhu.lineBreakMode = .byWordWrapping
        lbPhu.adjustsFontSizeToFitWidth = false
        khungBaoCao.addSubview(lbPhu)

        let lbChinh = UILabel(frame: CGRect(x: le, y: le + caoPhu + 4, width: rongBang, height: caoChinh))
        lbChinh.text = chuChinh
        lbChinh.font = fontChinh
        lbChinh.textColor = .black
        lbChinh.numberOfLines = 0
        lbChinh.lineBreakMode = .byWordWrapping
        lbChinh.adjustsFontSizeToFitWidth = false
        khungBaoCao.addSubview(lbChinh)

        var y = le + caoHeader + 8

        let hopTomTat = UIView(frame: CGRect(x: le, y: y, width: rongBang, height: caoTomTat))
        hopTomTat.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        hopTomTat.layer.cornerRadius = 8
        let lbTomTat = UILabel(frame: CGRect(x: 12, y: 7, width: rongBang - 24, height: caoTextTomTat))
        lbTomTat.text = chuTomTat
        lbTomTat.font = fontTomTat
        lbTomTat.textColor = .systemBlue
        lbTomTat.numberOfLines = 0
        lbTomTat.lineBreakMode = .byWordWrapping
        lbTomTat.adjustsFontSizeToFitWidth = false
        hopTomTat.addSubview(lbTomTat)
        khungBaoCao.addSubview(hopTomTat)

        y += caoTomTat + 10

        let khungBang = UIView(frame: CGRect(x: le, y: y, width: rongBang, height: caoBang))
        khungBang.layer.borderWidth = 1
        khungBang.layer.borderColor = UIColor.systemGray4.cgColor
        khungBang.layer.cornerRadius = 8
        khungBang.clipsToBounds = true
        khungBaoCao.addSubview(khungBang)

        if let header = self.tableView(bang, viewForHeaderInSection: 0) {
            header.frame = CGRect(x: 0, y: 0, width: rongBang, height: caoTieuDeCot)
            khungBang.addSubview(header)
        }

        if ds.isEmpty {
            let lbTrong = UILabel(frame: CGRect(x: 0, y: caoTieuDeCot, width: rongBang, height: 56))
            lbTrong.text = "Chưa có dữ liệu nhân viên."
            lbTrong.font = .systemFont(ofSize: 12.5, weight: .medium)
            lbTrong.textColor = .gray
            lbTrong.textAlignment = .center
            lbTrong.numberOfLines = 0
            lbTrong.lineBreakMode = .byWordWrapping
            khungBang.addSubview(lbTrong)
        } else {
            let cu = self.danhSach
            self.danhSach = ds
            var yDong = caoTieuDeCot
            for i in 0..<ds.count {
                let caoDong = cacCaoDong[i]
                let cell = self.tableView(bang, cellForRowAt: IndexPath(row: i, section: 0))
                let vDong = cell.contentView
                vDong.frame = CGRect(x: 0, y: yDong, width: rongBang, height: caoDong)
                let vach = UIView(frame: CGRect(x: 0, y: caoDong - 0.5, width: rongBang, height: 0.5))
                vach.backgroundColor = .systemGray4
                vDong.addSubview(vach)
                khungBang.addSubview(vDong)
                yDong += caoDong
            }
            self.danhSach = cu
        }

        let anh = khungBaoCao.ketXuatAnhChuanSang(scale: 3.0)
        bang.reloadData()
        return anh
    }
}

// MARK: - 3. Bảng Thông Số Sức Khoẻ Nhân Viên (Chuẩn mẫu 27 điểm: Doanh thu, Năng suất, Hiệu quả khai thác, Thi đua, Đơn giá, Tỷ trọng ngành hàng & Doanh thu QĐ từng tháng)

final class VongTronDiemSucKhoeView: UIView {
    var diemDat: Int = 0 { didSet { setNeedsDisplay() } }
    var tongDiem: Int = 27 { didSet { setNeedsDisplay() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let canh = min(rect.width, rect.height)
        let doDay: CGFloat = 6.0
        let banKinh = (canh - doDay * 2) / 2.0
        let tam = CGPoint(x: rect.midX, y: rect.midY)

        // Vòng nền xám nhạt
        ctx.setLineWidth(doDay)
        ctx.setStrokeColor(UIColor(red: 0.88, green: 0.91, blue: 0.95, alpha: 1).cgColor)
        ctx.addArc(center: tam, radius: banKinh, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.strokePath()

        // Cung tiến độ xanh dương
        let tyLe = CGFloat(min(1.0, max(0.0, Double(diemDat) / Double(max(1, tongDiem)))))
        if tyLe > 0.001 {
            let gocBatDau = -CGFloat.pi / 2.0
            let gocKetThuc = gocBatDau + tyLe * (.pi * 2.0)
            ctx.setLineWidth(doDay)
            ctx.setLineCap(.round)
            ctx.setStrokeColor(UIColor(red: 0.11, green: 0.36, blue: 0.91, alpha: 1).cgColor)
            ctx.addArc(center: tam, radius: banKinh, startAngle: gocBatDau, endAngle: gocKetThuc, clockwise: false)
            ctx.strokePath()
        }

        let pCenter = NSMutableParagraphStyle()
        pCenter.alignment = .center

        let chuDiem = "\(diemDat)" as NSString
        let fontDiem = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .heavy)
        let attrDiem: [NSAttributedString.Key: Any] = [
            .font: fontDiem,
            .foregroundColor: UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1),
            .paragraphStyle: pCenter
        ]
        let szDiem = chuDiem.size(withAttributes: attrDiem)

        let chuTong = "/\(tongDiem)" as NSString
        let fontTong = UIFont.monospacedDigitSystemFont(ofSize: 10.5, weight: .bold)
        let attrTong: [NSAttributedString.Key: Any] = [
            .font: fontTong,
            .foregroundColor: UIColor(red: 0.45, green: 0.51, blue: 0.60, alpha: 1),
            .paragraphStyle: pCenter
        ]
        let szTong = chuTong.size(withAttributes: attrTong)

        let tongCaoChu = szDiem.height + szTong.height - 2
        let yDau = tam.y - tongCaoChu / 2.0
        chuDiem.draw(in: CGRect(x: 0, y: yDau, width: rect.width, height: szDiem.height), withAttributes: attrDiem)
        chuTong.draw(in: CGRect(x: 0, y: yDau + szDiem.height - 2, width: rect.width, height: szTong.height), withAttributes: attrTong)
    }
}

final class TheChiSoSucKhoeView: UIControl {
    enum TrangThaiThe {
        case dat
        case chuaDat
        case chuaCoSo
    }

    private let vachTrai = UIView()
    private let nhanTieuDe = UILabel()
    private let nhanTB = UILabel()
    private let nhanPhu = UILabel()
    private let nhanGiaTri = UILabel()
    private var xuLyBam: (() -> Void)?

    init(
        tieuDe: String,
        giaTri: String,
        chuoiTB: String,
        chuoiPhu: String? = nil,
        trangThai: TrangThaiThe,
        khiBam: (() -> Void)? = nil
    ) {
        self.xuLyBam = khiBam
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.89, green: 0.92, blue: 0.96, alpha: 1).cgColor
        clipsToBounds = true

        switch trangThai {
        case .dat:
            vachTrai.backgroundColor = UIColor(red: 0.06, green: 0.65, blue: 0.38, alpha: 1) // #10A661
        case .chuaDat:
            vachTrai.backgroundColor = UIColor(red: 0.88, green: 0.18, blue: 0.18, alpha: 1) // #E02E2E
        case .chuaCoSo:
            vachTrai.backgroundColor = UIColor(red: 0.78, green: 0.82, blue: 0.88, alpha: 1) // #C7D1E0
        }
        vachTrai.isUserInteractionEnabled = false
        vachTrai.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vachTrai)

        nhanTieuDe.text = tieuDe.uppercased()
        nhanTieuDe.font = .systemFont(ofSize: 10.5, weight: .bold)
        nhanTieuDe.textColor = UIColor(red: 0.35, green: 0.42, blue: 0.52, alpha: 1)
        nhanTieuDe.numberOfLines = 2
        nhanTieuDe.lineBreakMode = .byWordWrapping
        nhanTieuDe.isUserInteractionEnabled = false

        nhanTB.font = .systemFont(ofSize: 10.0, weight: .bold)
        nhanTB.layer.cornerRadius = 5
        nhanTB.clipsToBounds = true
        nhanTB.textAlignment = .center
        nhanTB.numberOfLines = 1
        nhanTB.isUserInteractionEnabled = false
        switch trangThai {
        case .dat:
            nhanTB.text = " ↑ \(chuoiTB) "
            nhanTB.backgroundColor = UIColor(red: 0.84, green: 0.97, blue: 0.90, alpha: 1)
            nhanTB.textColor = UIColor(red: 0.05, green: 0.48, blue: 0.28, alpha: 1)
        case .chuaDat:
            nhanTB.text = " ↓ \(chuoiTB) "
            nhanTB.backgroundColor = UIColor(red: 0.99, green: 0.88, blue: 0.88, alpha: 1)
            nhanTB.textColor = UIColor(red: 0.74, green: 0.12, blue: 0.12, alpha: 1)
        case .chuaCoSo:
            nhanTB.text = " \(chuoiTB) "
            nhanTB.backgroundColor = UIColor(red: 0.94, green: 0.96, blue: 0.98, alpha: 1)
            nhanTB.textColor = UIColor(red: 0.42, green: 0.48, blue: 0.58, alpha: 1)
        }
        nhanTB.setContentHuggingPriority(.required, for: .horizontal)
        nhanTB.setContentCompressionResistancePriority(.required, for: .horizontal)

        nhanPhu.font = .systemFont(ofSize: 9.5, weight: .semibold)
        nhanPhu.backgroundColor = UIColor(red: 0.94, green: 0.96, blue: 0.98, alpha: 1)
        nhanPhu.textColor = UIColor(red: 0.38, green: 0.44, blue: 0.54, alpha: 1)
        nhanPhu.layer.cornerRadius = 5
        nhanPhu.clipsToBounds = true
        nhanPhu.textAlignment = .center
        nhanPhu.numberOfLines = 1
        nhanPhu.isUserInteractionEnabled = false
        if let phu = chuoiPhu, !phu.isEmpty {
            nhanPhu.text = " \(phu) "
            nhanPhu.isHidden = false
        } else {
            nhanPhu.isHidden = true
        }
        nhanPhu.setContentHuggingPriority(.required, for: .horizontal)

        nhanGiaTri.text = giaTri
        nhanGiaTri.font = .monospacedDigitSystemFont(ofSize: 17.5, weight: .heavy)
        nhanGiaTri.textColor = trangThai == .chuaCoSo
            ? UIColor(red: 0.45, green: 0.51, blue: 0.60, alpha: 1)
            : UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)
        nhanGiaTri.textAlignment = .right
        nhanGiaTri.numberOfLines = 1
        nhanGiaTri.adjustsFontSizeToFitWidth = true
        nhanGiaTri.minimumScaleFactor = 0.75
        nhanGiaTri.isUserInteractionEnabled = false
        nhanGiaTri.setContentCompressionResistancePriority(.required, for: .horizontal)

        let hangBadge = UIStackView(arrangedSubviews: [nhanTB, nhanPhu, UIView()])
        hangBadge.axis = .horizontal
        hangBadge.spacing = 4
        hangBadge.alignment = .center
        hangBadge.isUserInteractionEnabled = false

        let hangDuoi = UIStackView(arrangedSubviews: [hangBadge, nhanGiaTri])
        hangDuoi.axis = .horizontal
        hangDuoi.spacing = 6
        hangDuoi.alignment = .bottom
        hangDuoi.isUserInteractionEnabled = false

        let ngan = UIStackView(arrangedSubviews: [nhanTieuDe, hangDuoi])
        ngan.axis = .vertical
        ngan.spacing = 8
        ngan.distribution = .equalSpacing
        ngan.isUserInteractionEnabled = false
        ngan.translatesAutoresizingMaskIntoConstraints = false
        addSubview(ngan)

        NSLayoutConstraint.activate([
            vachTrai.leadingAnchor.constraint(equalTo: leadingAnchor),
            vachTrai.topAnchor.constraint(equalTo: topAnchor),
            vachTrai.bottomAnchor.constraint(equalTo: bottomAnchor),
            vachTrai.widthAnchor.constraint(equalToConstant: 4.0),

            nhanTB.heightAnchor.constraint(equalToConstant: 20),
            nhanPhu.heightAnchor.constraint(equalToConstant: 20),

            ngan.topAnchor.constraint(equalTo: topAnchor, constant: 9),
            ngan.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -9),
            ngan.leadingAnchor.constraint(equalTo: vachTrai.trailingAnchor, constant: 9),
            ngan.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 66)
        ])

        if khiBam != nil {
            addTarget(self, action: #selector(bamThe), for: .touchUpInside)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func bamThe() {
        xuLyBam?()
    }
}

final class ThanhHieuQuaKhaiThacView: UIControl {
    private var xuLyBam: (() -> Void)?

    init(tenMuc: String, giaTriPhanTram: Double?, mucTieuTB: Double = 50.0, khiBam: (() -> Void)? = nil) {
        self.xuLyBam = khiBam
        super.init(frame: .zero)
        backgroundColor = .clear

        let lbTen = UILabel()
        lbTen.text = tenMuc
        lbTen.font = .systemFont(ofSize: 11.5, weight: .semibold)
        lbTen.textColor = UIColor(red: 0.15, green: 0.20, blue: 0.28, alpha: 1)
        lbTen.isUserInteractionEnabled = false

        let lbGiaTri = UILabel()
        lbGiaTri.font = .monospacedDigitSystemFont(ofSize: 11.5, weight: .bold)
        lbGiaTri.textAlignment = .right
        lbGiaTri.isUserInteractionEnabled = false

        let khungThanh = UIView()
        khungThanh.isUserInteractionEnabled = false
        khungThanh.translatesAutoresizingMaskIntoConstraints = false

        let ranhNen = UIView()
        ranhNen.backgroundColor = UIColor(red: 0.86, green: 0.89, blue: 0.93, alpha: 1)
        ranhNen.layer.cornerRadius = 3
        ranhNen.clipsToBounds = true
        ranhNen.translatesAutoresizingMaskIntoConstraints = false
        khungThanh.addSubview(ranhNen)

        let thanhLap = UIView()
        thanhLap.layer.cornerRadius = 3
        thanhLap.translatesAutoresizingMaskIntoConstraints = false
        ranhNen.addSubview(thanhLap)

        // Vạch mốc giữa "| = 100% TB"
        let vachGiua = UIView()
        vachGiua.backgroundColor = UIColor(red: 0.25, green: 0.30, blue: 0.38, alpha: 1)
        vachGiua.layer.cornerRadius = 1
        vachGiua.translatesAutoresizingMaskIntoConstraints = false
        khungThanh.addSubview(vachGiua)

        let tyLeFill: CGFloat
        if let val = giaTriPhanTram {
            lbGiaTri.text = "\(Int(round(val)))%"
            let datTB = val >= mucTieuTB - 0.001
            lbGiaTri.textColor = datTB
                ? UIColor(red: 0.05, green: 0.48, blue: 0.28, alpha: 1)
                : UIColor(red: 0.76, green: 0.12, blue: 0.12, alpha: 1)
            thanhLap.backgroundColor = datTB
                ? UIColor(red: 0.06, green: 0.65, blue: 0.38, alpha: 1)
                : UIColor(red: 0.86, green: 0.16, blue: 0.16, alpha: 1)
            // Mốc giữa (0.5 chiều rộng thanh) tương ứng 100% TB
            let chuanTB = max(10.0, mucTieuTB)
            tyLeFill = CGFloat(min(1.0, max(0.0, (val / chuanTB) * 0.5)))
        } else {
            lbGiaTri.text = "--%"
            lbGiaTri.textColor = UIColor(red: 0.45, green: 0.51, blue: 0.60, alpha: 1)
            thanhLap.backgroundColor = .clear
            tyLeFill = 0
        }

        let hangChu = UIStackView(arrangedSubviews: [lbTen, lbGiaTri])
        hangChu.axis = .horizontal
        hangChu.distribution = .equalSpacing
        hangChu.isUserInteractionEnabled = false

        let ngan = UIStackView(arrangedSubviews: [hangChu, khungThanh])
        ngan.axis = .vertical
        ngan.spacing = 4
        ngan.isUserInteractionEnabled = false
        ngan.translatesAutoresizingMaskIntoConstraints = false
        addSubview(ngan)

        NSLayoutConstraint.activate([
            ngan.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            ngan.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            ngan.leadingAnchor.constraint(equalTo: leadingAnchor),
            ngan.trailingAnchor.constraint(equalTo: trailingAnchor),

            khungThanh.heightAnchor.constraint(equalToConstant: 12),
            ranhNen.leadingAnchor.constraint(equalTo: khungThanh.leadingAnchor),
            ranhNen.trailingAnchor.constraint(equalTo: khungThanh.trailingAnchor),
            ranhNen.centerYAnchor.constraint(equalTo: khungThanh.centerYAnchor),
            ranhNen.heightAnchor.constraint(equalToConstant: 6),

            thanhLap.leadingAnchor.constraint(equalTo: ranhNen.leadingAnchor),
            thanhLap.topAnchor.constraint(equalTo: ranhNen.topAnchor),
            thanhLap.bottomAnchor.constraint(equalTo: ranhNen.bottomAnchor),
            thanhLap.widthAnchor.constraint(equalTo: ranhNen.widthAnchor, multiplier: max(0.001, tyLeFill)),

            vachGiua.centerXAnchor.constraint(equalTo: khungThanh.centerXAnchor),
            vachGiua.centerYAnchor.constraint(equalTo: khungThanh.centerYAnchor),
            vachGiua.widthAnchor.constraint(equalToConstant: 2),
            vachGiua.heightAnchor.constraint(equalToConstant: 12)
        ])

        if khiBam != nil {
            addTarget(self, action: #selector(bamThanh), for: .touchUpInside)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func bamThanh() {
        xuLyBam?()
    }
}

final class TheMiniMonThiDuaSKView: UIControl {
    private var xuLyBam: (() -> Void)?

    init(mon: MonThiDuaNhanVien, khiBam: (() -> Void)? = nil) {
        self.xuLyBam = khiBam
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.92, green: 0.94, blue: 0.97, alpha: 1).cgColor

        let pt = Int(round(mon.phanTramHT))
        let mauThanh: UIColor
        let mauChu: UIColor
        if mon.phanTramHT >= 99.995 {
            mauThanh = UIColor(red: 0.95, green: 0.65, blue: 0.05, alpha: 1) // Vàng cam / xanh đạt như ảnh mẫu
            mauChu = UIColor(red: 0.78, green: 0.48, blue: 0.03, alpha: 1)
        } else if mon.phanTramHT >= 80.0 {
            mauThanh = UIColor(red: 0.95, green: 0.65, blue: 0.05, alpha: 1)
            mauChu = UIColor(red: 0.78, green: 0.48, blue: 0.03, alpha: 1)
        } else {
            mauThanh = UIColor(red: 0.86, green: 0.16, blue: 0.16, alpha: 1)
            mauChu = UIColor(red: 0.76, green: 0.12, blue: 0.12, alpha: 1)
        }

        let lbTen = UILabel()
        lbTen.text = mon.tenNganhHang
        lbTen.font = .systemFont(ofSize: 10.5, weight: .bold)
        lbTen.textColor = UIColor(red: 0.12, green: 0.16, blue: 0.24, alpha: 1)
        lbTen.numberOfLines = 2
        lbTen.lineBreakMode = .byWordWrapping
        lbTen.isUserInteractionEnabled = false

        let lbPT = UILabel()
        lbPT.text = "\(pt)%"
        lbPT.font = .monospacedDigitSystemFont(ofSize: 10.5, weight: .heavy)
        lbPT.textColor = mauChu
        lbPT.textAlignment = .right
        lbPT.setContentHuggingPriority(.required, for: .horizontal)
        lbPT.setContentCompressionResistancePriority(.required, for: .horizontal)
        lbPT.isUserInteractionEnabled = false

        let hangTren = UIStackView(arrangedSubviews: [lbTen, lbPT])
        hangTren.axis = .horizontal
        hangTren.spacing = 4
        hangTren.alignment = .top
        hangTren.isUserInteractionEnabled = false

        let track = UIView()
        track.backgroundColor = UIColor(red: 0.88, green: 0.91, blue: 0.95, alpha: 1)
        track.layer.cornerRadius = 2.5
        track.clipsToBounds = true
        track.isUserInteractionEnabled = false
        track.translatesAutoresizingMaskIntoConstraints = false

        let fill = UIView()
        fill.backgroundColor = mauThanh
        fill.layer.cornerRadius = 2.5
        fill.translatesAutoresizingMaskIntoConstraints = false
        track.addSubview(fill)

        let tyLe = CGFloat(min(1.0, max(0.04, mon.phanTramHT / 100.0)))

        let ngan = UIStackView(arrangedSubviews: [hangTren, track])
        ngan.axis = .vertical
        ngan.spacing = 6
        ngan.distribution = .equalSpacing
        ngan.isUserInteractionEnabled = false
        ngan.translatesAutoresizingMaskIntoConstraints = false
        addSubview(ngan)

        NSLayoutConstraint.activate([
            ngan.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            ngan.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -7),
            ngan.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            ngan.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            track.heightAnchor.constraint(equalToConstant: 5),
            fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            fill.topAnchor.constraint(equalTo: track.topAnchor),
            fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            fill.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: tyLe),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 46)
        ])

        if khiBam != nil {
            addTarget(self, action: #selector(bamThe), for: .touchUpInside)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func bamThe() {
        xuLyBam?()
    }
}

final class BieuDoTronTyTrongNganhHangView: UIView {
    var cacPhan: [(mau: UIColor, tyLe: Double)] = [] {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let canh = min(rect.width, rect.height)
        let doDay: CGFloat = max(14, canh * 0.22)
        let banKinh = (canh - doDay - 4) / 2.0
        let tam = CGPoint(x: rect.midX, y: rect.midY)

        let tong = cacPhan.reduce(0.0) { $0 + max(0, $1.tyLe) }
        if tong <= 0.001 {
            // Khung chờ bổ sung dữ liệu: vẽ vòng tròn mẫu phân 8 cung nhẹ nhàng
            let mauMacDinh: [(UIColor, Double)] = [
                (UIColor(red: 0.21, green: 0.49, blue: 0.85, alpha: 0.85), 55),
                (UIColor(red: 0.53, green: 0.31, blue: 0.82, alpha: 0.85), 14),
                (UIColor(red: 0.14, green: 0.62, blue: 0.35, alpha: 0.85), 11),
                (UIColor(red: 0.89, green: 0.56, blue: 0.13, alpha: 0.85), 8),
                (UIColor(red: 0.84, green: 0.20, blue: 0.24, alpha: 0.85), 5),
                (UIColor(red: 0.12, green: 0.63, blue: 0.64, alpha: 0.85), 3),
                (UIColor(red: 0.33, green: 0.38, blue: 0.45, alpha: 0.85), 2),
                (UIColor(red: 0.65, green: 0.70, blue: 0.77, alpha: 0.85), 2)
            ]
            var goc = -CGFloat.pi / 2.0
            for (mau, pt) in mauMacDinh {
                let quet = CGFloat(pt / 100.0) * (.pi * 2.0)
                ctx.setLineWidth(doDay)
                ctx.setStrokeColor(mau.cgColor)
                ctx.addArc(center: tam, radius: banKinh, startAngle: goc, endAngle: goc + quet, clockwise: false)
                ctx.strokePath()
                goc += quet
            }
            return
        }

        var goc = -CGFloat.pi / 2.0
        for phan in cacPhan where phan.tyLe > 0 {
            let quet = CGFloat(phan.tyLe / tong) * (.pi * 2.0)
            ctx.setLineWidth(doDay)
            ctx.setStrokeColor(phan.mau.cgColor)
            ctx.addArc(center: tam, radius: banKinh, startAngle: goc, endAngle: goc + quet, clockwise: false)
            ctx.strokePath()
            goc += quet
        }
    }
}

final class BieuDoCotDoanhThuThangNVView: UIView {
    var duLieuThang: [(nhan: String, giaTri: Double?)] = [] {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), !duLieuThang.isEmpty else { return }
        let soCot = duLieuThang.count
        let leTraiPhai: CGFloat = 8
        let yDinhSo: CGFloat = 6
        let yChanCot: CGFloat = rect.height - 24
        let caoToiDaCot = max(30, yChanCot - yDinhSo - 20)

        let maxVal = max(100.0, duLieuThang.compactMap(\.giaTri).max() ?? 500.0)
        let buocX = (rect.width - leTraiPhai * 2) / CGFloat(max(1, soCot))
        let rongCot = min(38, buocX * 0.58)

        let pCenter = NSMutableParagraphStyle()
        pCenter.alignment = .center

        let fontSo = UIFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .bold)
        let fontThang = UIFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .medium)

        for (i, muc) in duLieuThang.enumerated() {
            let tamX = leTraiPhai + buocX * (CGFloat(i) + 0.5)
            let xCot = tamX - rongCot / 2.0

            if let val = muc.giaTri, val > 0 {
                let tyLe = CGFloat(min(1.0, max(0.08, val / maxVal)))
                let caoCot = caoToiDaCot * tyLe
                let yCot = yChanCot - caoCot
                let rectCot = CGRect(x: xCot, y: yCot, width: rongCot, height: caoCot)
                UIColor(red: 0.08, green: 0.37, blue: 0.94, alpha: 1).setFill()
                UIBezierPath(roundedRect: rectCot, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 5, height: 5)).fill()

                let chuSo = String(format: "%.1f", val) as NSString
                chuSo.draw(
                    in: CGRect(x: tamX - buocX / 2.0, y: yDinSo(yCot: yCot), width: buocX, height: 15),
                    withAttributes: [
                        .font: fontSo,
                        .foregroundColor: UIColor(red: 0.18, green: 0.24, blue: 0.34, alpha: 1),
                        .paragraphStyle: pCenter
                    ]
                )
            } else {
                // Khung cột chờ bổ sung dữ liệu cho các tháng trước
                let caoKhung: CGFloat = 18
                let rectKhung = CGRect(x: xCot, y: yChanCot - caoKhung, width: rongCot, height: caoKhung)
                UIColor(red: 0.85, green: 0.89, blue: 0.95, alpha: 1).setFill()
                UIBezierPath(roundedRect: rectKhung, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 4, height: 4)).fill()

                ("--" as NSString).draw(
                    in: CGRect(x: tamX - buocX / 2.0, y: yChanCot - caoKhung - 15, width: buocX, height: 14),
                    withAttributes: [
                        .font: fontSo,
                        .foregroundColor: UIColor(red: 0.52, green: 0.58, blue: 0.68, alpha: 1),
                        .paragraphStyle: pCenter
                    ]
                )
            }

            (muc.nhan as NSString).draw(
                in: CGRect(x: tamX - buocX / 2.0, y: yChanCot + 5, width: buocX, height: 16),
                withAttributes: [
                    .font: fontThang,
                    .foregroundColor: UIColor(red: 0.45, green: 0.51, blue: 0.60, alpha: 1),
                    .paragraphStyle: pCenter
                ]
            )
        }

        // Đường kẻ chân biểu đồ
        ctx.setStrokeColor(UIColor(red: 0.84, green: 0.88, blue: 0.94, alpha: 1).cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: leTraiPhai, y: yChanCot))
        ctx.addLine(to: CGPoint(x: rect.width - leTraiPhai, y: yChanCot))
        ctx.strokePath()
    }

    private func yDinSo(yCot: CGFloat) -> CGFloat {
        max(2, yCot - 16)
    }
}

/// Giao diện Bảng Thông Số Sức Khỏe Nhân Viên chuẩn thiết kế mới (Dùng chung cho cả màn hình chi tiết, tab Sức khỏe và Xuất ảnh báo cáo)
final class BangThongSoSucKhoeNhanVienView: UIView {
    var khiYeuCauCapNhat: (() -> Void)?

    private var tongHop: TongHopNhanVien
    private var ngay: Date
    private var cheDo: LoaiCheDoDoanhThu
    private let laCheDoXuatAnhRong: Bool
    private let nganChinh = UIStackView()

    init(
        tongHop: TongHopNhanVien,
        ngay: Date,
        cheDo: LoaiCheDoDoanhThu = .luyKe,
        laCheDoXuatAnhRong: Bool = false
    ) {
        self.tongHop = tongHop
        self.ngay = ngay
        self.cheDo = cheDo
        self.laCheDoXuatAnhRong = laCheDoXuatAnhRong
        super.init(frame: .zero)
        backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1)
        nganChinh.axis = .vertical
        nganChinh.spacing = 12
        nganChinh.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nganChinh)
        NSLayoutConstraint.activate([
            nganChinh.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            nganChinh.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            nganChinh.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            nganChinh.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
        dungGiaoDien()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func capNhat(tongHop: TongHopNhanVien, ngay: Date, cheDo: LoaiCheDoDoanhThu) {
        self.tongHop = tongHop
        self.ngay = ngay
        self.cheDo = cheDo
        dungGiaoDien()
    }

    private func dungGiaoDien() {
        nganChinh.arrangedSubviews.forEach {
            nganChinh.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let kho = KhoDuLieu.dungChung
        let dl = kho.duLieu(cho: ngay)
        let dtST = (cheDo == .luyKe) ? dl.doanhThu : dl.doanhThuRealtime
        let dsTatCaNV = kho.tongHopNhanVien(den: ngay, sapXep: .doanhThuQD, cheDo: cheDo)
        let bangBoSung = kho.sucKhoeBoSungNhanVienThang(cho: ngay)
        let boSung = bangBoSung[tongHop.nhanVien.maNV]

        // 1. Tính toán các chỉ số đã có số liệu thật từ App
        let soNVQuanLy = max(1, dsTatCaNV.count)
        let hangNV = (dsTatCaNV.firstIndex(where: { $0.nhanVien.maNV == tongHop.nhanVien.maNV }) ?? 0) + 1

        // TB Doanh thu QĐ & TB Số lượng bill trên toàn đội ngũ có dữ liệu
        let dsCoDT = dsTatCaNV.filter { $0.doanhThuQD > 0 }
        let tbDTQD: Double = !dsCoDT.isEmpty
            ? (dsCoDT.reduce(0.0) { $0 + $1.doanhThuQD } / Double(dsCoDT.count))
            : (dtST.doanhThuQuyDoi > 0 ? dtST.doanhThuQuyDoi / Double(soNVQuanLy) : 0)

        let dsCoBill = dsTatCaNV.filter { $0.soLuongDon > 0 }
        let tbSoBill: Double = !dsCoBill.isEmpty
            ? (dsCoBill.reduce(0.0) { $0 + $1.soLuongDon } / Double(dsCoBill.count))
            : 0

        let lich = TienIchNgay.lich
        let thang = lich.component(.month, from: ngay)
        let nam = lich.component(.year, from: ngay)
        let soNgayQua = dtST.soNgayDaQua > 0 ? dtST.soNgayDaQua : max(1, lich.component(.day, from: ngay))
        let tongNgayThang = dtST.tongSoNgay > 0 ? dtST.tongSoNgay : (lich.range(of: .day, in: .month, for: ngay)?.count ?? 30)

        // Target cá nhân & % Target (tính từ Target siêu thị chia đều nếu chưa nhập riêng)
        let mtCaNhan: Double? = {
            if let mt = boSung?.mucTieuTargetQD, mt > 0 { return mt }
            if let t = tongHop.doanhThuCaNhan?.target, t > 0 { return t }
            if dtST.targetQuyDoi > 0 { return dtST.targetQuyDoi / Double(soNVQuanLy) }
            return nil
        }()

        let ptTargetCaNhan: Double? = {
            if let pt = boSung?.phanTramTarget, pt > 0 { return pt }
            if let pt = tongHop.doanhThuCaNhan?.phanTramHT, pt > 0 { return pt }
            if let mt = mtCaNhan, mt > 0, tongHop.doanhThuQD > 0 {
                let tyLeNgay = (cheDo == .luyKe) ? (Double(soNgayQua) / Double(max(1, tongNgayThang))) : 1.0
                let mtDenNgay = max(0.1, mt * tyLeNgay)
                return (tongHop.doanhThuQD / mtDenNgay) * 100.0
            }
            return nil
        }()

        let tbPtTargetST: Double? = {
            if let tb = boSung?.tbPhanTramTarget, tb > 0 { return tb }
            let htST = dtST.phanTramHTQuyDoiHienThi(cheDo: cheDo)
            if htST > 0 { return htST }
            if let mt = mtCaNhan, mt > 0, tbDTQD > 0 {
                let tyLeNgay = (cheDo == .luyKe) ? (Double(soNgayQua) / Double(max(1, tongNgayThang))) : 1.0
                return (tbDTQD / max(0.1, mt * tyLeNgay)) * 100.0
            }
            return nil
        }()

        let ptQuyDoiCaNhan: Double? = {
            if let v = boSung?.phanTramQuyDoi { return v }
            if let cn = tongHop.doanhThuCaNhan, cn.doanhThuThuc > 0, cn.doanhThuQD > 0 {
                return ((cn.doanhThuQD - cn.doanhThuThuc) / cn.doanhThuThuc) * 100.0
            }
            return nil
        }()
        let tbPtQuyDoiST: Double? = boSung?.tbPhanTramQuyDoi ?? (dtST.phanTramQuyDoi > 0 ? dtST.phanTramQuyDoi : nil)

        let ptTraChamCaNhan: Double? = {
            if let v = boSung?.phanTramTraCham { return v }
            if let cn = tongHop.doanhThuCaNhan, cn.phanTramTraGop > 0 { return cn.phanTramTraGop }
            return nil
        }()
        let tbPtTraChamST: Double? = boSung?.tbPhanTramTraCham ?? (dtST.phanTramTraGop > 0 ? dtST.phanTramTraGop : nil)

        let ptBanKemCaNhan: Double? = boSung?.phanTramBanKem
        let tbPtBanKemST: Double? = boSung?.tbPhanTramBanKem

        // Tính điểm đạt của từng khối (Tổng 27 điểm: Doanh thu 6, Năng suất 3, Hiệu quả 9, Đơn giá 8, Thi đua 1)
        var diemDoanhThu = 0
        if tongHop.doanhThuQD > 0 && tongHop.doanhThuQD >= tbDTQD - 0.001 { diemDoanhThu += 1 }
        if let ptT = ptTargetCaNhan, ptT >= (tbPtTargetST ?? 100.0) - 0.001 { diemDoanhThu += 1 }
        if tongHop.soLuongDon > 0 && tongHop.soLuongDon >= tbSoBill - 0.001 { diemDoanhThu += 1 }
        if let qd = ptQuyDoiCaNhan, qd >= (tbPtQuyDoiST ?? 40.0) - 0.001 { diemDoanhThu += 1 }
        if let tc = ptTraChamCaNhan, tc >= (tbPtTraChamST ?? 45.0) - 0.001 { diemDoanhThu += 1 }
        if let bk = ptBanKemCaNhan, bk >= (tbPtBanKemST ?? 50.0) - 0.001 { diemDoanhThu += 1 }

        var diemNangSuat = 0
        if let erp = boSung?.diemThuongERP, erp >= (boSung?.tbDiemThuongERP ?? erp) { diemNangSuat += 1 }
        if let dtgc = boSung?.diemThuongTrenGioCong, dtgc >= (boSung?.tbDiemThuongTrenGioCong ?? dtgc) { diemNangSuat += 1 }
        let dtqdGC: Double? = boSung?.dtqdTrenGioCong ?? ((tongHop.doanhThuCaNhan?.gioCong ?? 0) > 0 ? (tongHop.doanhThuQD / tongHop.doanhThuCaNhan!.gioCong) : nil)
        if let v = dtqdGC, v >= (boSung?.tbDtqdTrenGioCong ?? v) { diemNangSuat += 1 }

        var diemHieuQua = 0
        for muc in DuLieuSucKhoeBoSungNV.tatCaMucHieuQua {
            if let v = boSung?.hieuQuaKhaiThac[muc.khoa], v >= 50.0 {
                diemHieuQua += 1
            }
        }

        var diemDonGia = 0
        for muc in DuLieuSucKhoeBoSungNV.danhSachMucDonGia {
            if let v = boSung?.donGiaCaNhan[muc.khoa], v > 0 {
                let tb = boSung?.donGiaTrungBinhST[muc.khoa] ?? v
                if v >= tb - 0.001 { diemDonGia += 1 }
            }
        }

        // Khối Thi đua (1 điểm nếu tỷ lệ chương trình đạt >= 50% hoặc >= TB siêu thị khi có môn đạt)
        let cacMonGiao = tongHop.cacMonGiao
        let soMonDat = cacMonGiao.filter(\.daDat).count
        let soMonGanDat = cacMonGiao.filter { !$0.daDat && $0.phanTramHT >= 80.0 }.count
        let soMonCanCoGang = cacMonGiao.filter { $0.thucHien > 0.0001 && $0.phanTramHT < 80.0 }.count
        let dsChuaCoSo: [String]
        let tongSoChuongTrinh: Int
        if !cacMonGiao.isEmpty {
            dsChuaCoSo = cacMonGiao.filter { $0.thucHien <= 0.0001 }.map(\.tenNganhHang)
            tongSoChuongTrinh = cacMonGiao.count
        } else {
            dsChuaCoSo = KhoDuLieu.danhSachTenMonThiDuaChuanDMX
            tongSoChuongTrinh = dsChuaCoSo.count
        }
        let soMonChuaCoSo = dsChuaCoSo.count
        let tyLeMonDat = tongSoChuongTrinh > 0 ? Int(round(Double(soMonDat) / Double(tongSoChuongTrinh) * 100.0)) : 0
        let tbTyLeMonDatST: Int = {
            guard !dsTatCaNV.isEmpty, tongSoChuongTrinh > 0 else { return 0 }
            let tb = dsTatCaNV.reduce(0.0) { $0 + (Double($1.soMonDat) / Double(max(1, $1.tongMonGiao)) * 100.0) } / Double(dsTatCaNV.count)
            return Int(round(tb))
        }()
        let diemThiDua = (soMonDat > 0 && tyLeMonDat >= max(50, tbTyLeMonDatST)) ? 1 : 0

        let tongDiemDat = diemDoanhThu + diemNangSuat + diemHieuQua + diemDonGia + diemThiDua
        let ptHoanThanhTong = Int(round(Double(tongDiemDat) / 27.0 * 100.0))

        // ==================== KHỐI 1: HEADER TỔNG QUAN (27 ĐIỂM) ====================
        let theHeader = taoKhungHeader(
            tongDiemDat: tongDiemDat,
            ptHoanThanh: ptHoanThanhTong,
            hang: hangNV,
            tongNV: soNVQuanLy,
            thang: thang,
            nam: nam,
            soNgayQua: soNgayQua,
            tongNgay: tongNgayThang,
            thongTinDonVi: dl.thongTinDonVi,
            diemDoanhThu: diemDoanhThu,
            diemNangSuat: diemNangSuat,
            diemHieuQua: diemHieuQua,
            diemDonGia: diemDonGia,
            diemThiDua: diemThiDua,
            tbDTQD: tbDTQD,
            tbSoBill: tbSoBill
        )
        nganChinh.addArrangedSubview(theHeader)

        let lbCapNhat = UILabel()
        let ngayBaoCaoStr = String(format: "%02d/%02d", soNgayQua, thang)
        lbCapNhat.text = "Số tới hết ngày \(ngayBaoCaoStr) - \(dl.capNhatLuc.isEmpty ? "cập nhật hằng đêm" : "cập nhật \(dl.capNhatLuc)")"
        lbCapNhat.font = .systemFont(ofSize: 11.0, weight: .medium)
        lbCapNhat.textColor = UIColor(red: 0.45, green: 0.51, blue: 0.60, alpha: 1)
        nganChinh.addArrangedSubview(lbCapNhat)

        // ==================== KHỐI 2: DOANH THU (X/6) ====================
        let khoiDoanhThu = taoKhoiDoanhThu(
            diemDat: diemDoanhThu,
            tbDTQD: tbDTQD,
            mtCaNhan: mtCaNhan,
            ptTargetCaNhan: ptTargetCaNhan,
            tbPtTargetST: tbPtTargetST,
            tbSoBill: tbSoBill,
            ptQuyDoi: ptQuyDoiCaNhan,
            tbQuyDoi: tbPtQuyDoiST,
            ptTraCham: ptTraChamCaNhan,
            tbTraCham: tbPtTraChamST,
            ptBanKem: ptBanKemCaNhan,
            tbBanKem: tbPtBanKemST
        )
        nganChinh.addArrangedSubview(khoiDoanhThu)

        // ==================== KHỐI 3: NĂNG SUẤT (X/3) ====================
        let khoiNangSuat = taoKhoiNangSuat(diemDat: diemNangSuat, boSung: boSung, dtqdGC: dtqdGC)
        nganChinh.addArrangedSubview(khoiNangSuat)

        // ==================== KHỐI 4: HIỆU QUẢ KHAI THÁC (X/9) ====================
        let khoiHieuQua = taoKhoiHieuQuaKhaiThac(diemDat: diemHieuQua, boSung: boSung)
        nganChinh.addArrangedSubview(khoiHieuQua)

        // ==================== KHỐI 5: THI ĐUA (X/1) ====================
        let khoiThiDua = taoKhoiThiDua(
            diemDat: diemThiDua,
            tyLeDat: tyLeMonDat,
            tbTyLeDatST: tbTyLeMonDatST,
            soMonDat: soMonDat,
            soMonGanDat: soMonGanDat,
            soMonCanCoGang: soMonCanCoGang,
            soMonChuaCoSo: soMonChuaCoSo,
            tongSoChuongTrinh: tongSoChuongTrinh,
            cacMonCoSo: cacMonGiao.filter { $0.thucHien > 0.0001 }.sorted { $0.phanTramHT > $1.phanTramHT },
            dsChuaCoSo: dsChuaCoSo,
            dsThiDuaST: dl.danhSachThiDua(theo: cheDo)
        )
        nganChinh.addArrangedSubview(khoiThiDua)

        // ==================== KHỐI 6: ĐƠN GIÁ (X/8) ====================
        let khoiDonGia = taoKhoiDonGia(diemDat: diemDonGia, boSung: boSung)
        nganChinh.addArrangedSubview(khoiDonGia)

        // ==================== KHỐI 7: TỶ TRỌNG NGÀNH HÀNG & DOANH THU QĐ TỪNG THÁNG ====================
        let ds6Thang = kho.layDoanhThuQDTheo6ThangGanNhat(
            maNV: tongHop.nhanVien.maNV,
            den: ngay,
            doanhThuThangHienTai: tongHop.doanhThuQD,
            boSung: boSung
        )
        let khoiBieuDoDuoi = taoKhoiHaiBieuDoDuoi(boSung: boSung, ds6Thang: ds6Thang)
        nganChinh.addArrangedSubview(khoiBieuDoDuoi)
    }

    // MARK: - Các hàm dựng từng khối giao diện chuẩn mẫu ảnh 2

    private func taoNutQuyTac(tieuDe: String, noiDung: String) -> UIButton {
        let nut = UIButton(type: .system)
        nut.setTitle(" ⓘ Quy tắc ", for: .normal)
        nut.titleLabel?.font = .systemFont(ofSize: 10.0, weight: .semibold)
        nut.setTitleColor(UIColor(red: 0.35, green: 0.42, blue: 0.52, alpha: 1), for: .normal)
        nut.backgroundColor = .white
        nut.layer.cornerRadius = 6
        nut.layer.borderWidth = 1
        nut.layer.borderColor = UIColor(red: 0.85, green: 0.89, blue: 0.94, alpha: 1).cgColor
        nut.contentEdgeInsets = UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6)
        nut.setContentHuggingPriority(.required, for: .horizontal)
        nut.addAction(UIAction { [weak self] _ in
            guard let vc = self?.timViewControllerCha() else { return }
            let hop = UIAlertController(title: tieuDe, message: noiDung, preferredStyle: .alert)
            hop.addAction(UIAlertAction(title: "Đã hiểu", style: .default))
            vc.present(hop, animated: true)
        }, for: .touchUpInside)
        return nut
    }

    private func taoKhungHeader(
        tongDiemDat: Int,
        ptHoanThanh: Int,
        hang: Int,
        tongNV: Int,
        thang: Int,
        nam: Int,
        soNgayQua: Int,
        tongNgay: Int,
        thongTinDonVi: String,
        diemDoanhThu: Int,
        diemNangSuat: Int,
        diemHieuQua: Int,
        diemDonGia: Int,
        diemThiDua: Int,
        tbDTQD: Double,
        tbSoBill: Double
    ) -> UIView {
        let the = UIView()
        the.backgroundColor = .white
        the.layer.cornerRadius = 14
        the.layer.borderWidth = 1
        the.layer.borderColor = UIColor(red: 0.88, green: 0.91, blue: 0.96, alpha: 1).cgColor

        let vongDiem = VongTronDiemSucKhoeView()
        vongDiem.diemDat = tongDiemDat
        vongDiem.tongDiem = 27
        vongDiem.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vongDiem.widthAnchor.constraint(equalToConstant: 64),
            vongDiem.heightAnchor.constraint(equalToConstant: 64)
        ])

        let lbTen = UILabel()
        lbTen.text = tongHop.nhanVien.hoTen
        lbTen.font = .systemFont(ofSize: 17.5, weight: .heavy)
        lbTen.textColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)
        lbTen.numberOfLines = 0

        let tenST = thongTinDonVi.isEmpty
            ? (DichVuDongBo.dungChung.sieuThiDangChon.map { "\($0.maSieuThi) - \($0.tenSieuThi)" } ?? "Điện Máy Xanh")
            : thongTinDonVi
        let lbPhu = UILabel()
        lbPhu.text = "\(tongHop.nhanVien.maNV) · BP All In One - ĐMX - \(tenST)"
        lbPhu.font = .systemFont(ofSize: 11.0, weight: .medium)
        lbPhu.textColor = UIColor(red: 0.42, green: 0.48, blue: 0.58, alpha: 1)
        lbPhu.numberOfLines = 2

        let lbHang = UILabel()
        lbHang.text = "  Hạng \(hang) / \(tongNV)  "
        lbHang.font = .systemFont(ofSize: 10.5, weight: .bold)
        lbHang.textColor = UIColor(red: 0.20, green: 0.26, blue: 0.36, alpha: 1)
        lbHang.backgroundColor = UIColor(red: 0.93, green: 0.95, blue: 0.98, alpha: 1)
        lbHang.layer.cornerRadius = 6
        lbHang.clipsToBounds = true
        lbHang.setContentHuggingPriority(.required, for: .horizontal)

        let hangHang = UIStackView(arrangedSubviews: [lbHang, UIView()])
        hangHang.axis = .horizontal

        let nganTen = UIStackView(arrangedSubviews: [lbTen, lbPhu, hangHang])
        nganTen.axis = .vertical
        nganTen.spacing = 3

        let lbHT = UILabel()
        lbHT.text = "Hoàn thành \(ptHoanThanh)%"
        lbHT.font = .systemFont(ofSize: 11.5, weight: .bold)
        lbHT.textColor = UIColor(red: 0.28, green: 0.35, blue: 0.45, alpha: 1)
        lbHT.textAlignment = .right

        let lbThang = UILabel()
        lbThang.text = String(format: "Tháng %02d/%04d · %d/%d ngày", thang, nam, soNgayQua, tongNgay)
        lbThang.font = .systemFont(ofSize: 10.5, weight: .medium)
        lbThang.textColor = UIColor(red: 0.45, green: 0.51, blue: 0.60, alpha: 1)
        lbThang.textAlignment = .right
        lbThang.numberOfLines = 2

        let nganPhai = UIStackView(arrangedSubviews: [lbHT, lbThang])
        nganPhai.axis = .vertical
        nganPhai.spacing = 2
        nganPhai.alignment = .trailing
        nganPhai.setContentCompressionResistancePriority(.required, for: .horizontal)

        let hangTren = UIStackView(arrangedSubviews: [vongDiem, nganTen, nganPhai])
        hangTren.axis = .horizontal
        hangTren.spacing = 10
        hangTren.alignment = .center

        // 5 thẻ điểm thành phần: DOANH THU 4/6 | NĂNG SUẤT 3/3 | HIỆU QUẢ 0/9 | ĐƠN GIÁ 4/8 | THI ĐUA 0/1
        func taoPillNhom(_ ten: String, diem: String, nen: UIColor, chu: UIColor) -> UIView {
            let v = UIView()
            v.backgroundColor = nen
            v.layer.cornerRadius = 8
            let l1 = UILabel()
            l1.text = ten
            l1.font = .systemFont(ofSize: 9.5, weight: .heavy)
            l1.textColor = chu
            let l2 = UILabel()
            l2.text = diem
            l2.font = .monospacedDigitSystemFont(ofSize: 10.5, weight: .heavy)
            l2.textColor = chu
            l2.textAlignment = .right
            let st = UIStackView(arrangedSubviews: [l1, l2])
            st.axis = .horizontal
            st.spacing = 4
            st.distribution = .equalSpacing
            st.translatesAutoresizingMaskIntoConstraints = false
            v.addSubview(st)
            NSLayoutConstraint.activate([
                st.topAnchor.constraint(equalTo: v.topAnchor, constant: 6),
                st.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -6),
                st.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 8),
                st.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -8)
            ])
            return v
        }

        let p1 = taoPillNhom("DOANH THU", diem: "\(diemDoanhThu)/6", nen: UIColor(red: 0.92, green: 0.95, blue: 1.0, alpha: 1), chu: UIColor(red: 0.11, green: 0.35, blue: 0.85, alpha: 1))
        let p2 = taoPillNhom("NĂNG SUẤT", diem: "\(diemNangSuat)/3", nen: UIColor(red: 0.90, green: 0.98, blue: 0.94, alpha: 1), chu: UIColor(red: 0.05, green: 0.48, blue: 0.28, alpha: 1))
        let p3 = taoPillNhom("HIỆU QUẢ", diem: "\(diemHieuQua)/9", nen: UIColor(red: 1.0, green: 0.96, blue: 0.90, alpha: 1), chu: UIColor(red: 0.72, green: 0.32, blue: 0.05, alpha: 1))
        let p4 = taoPillNhom("ĐƠN GIÁ", diem: "\(diemDonGia)/8", nen: UIColor(red: 0.95, green: 0.93, blue: 1.0, alpha: 1), chu: UIColor(red: 0.42, green: 0.18, blue: 0.82, alpha: 1))
        let p5 = taoPillNhom("THI ĐUA", diem: "\(diemThiDua)/1", nen: UIColor(red: 1.0, green: 0.93, blue: 0.95, alpha: 1), chu: UIColor(red: 0.75, green: 0.10, blue: 0.25, alpha: 1))

        let hangPillNhom: UIView
        if laCheDoXuatAnhRong {
            let st = UIStackView(arrangedSubviews: [p1, p2, p3, p4, p5])
            st.axis = .horizontal
            st.spacing = 6
            st.distribution = .fillEqually
            hangPillNhom = st
        } else {
            let h1 = UIStackView(arrangedSubviews: [p1, p2, p3])
            h1.axis = .horizontal; h1.spacing = 6; h1.distribution = .fillEqually
            let h2 = UIStackView(arrangedSubviews: [p4, p5])
            h2.axis = .horizontal; h2.spacing = 6; h2.distribution = .fillEqually
            let gop = UIStackView(arrangedSubviews: [h1, h2])
            gop.axis = .vertical; gop.spacing = 6
            hangPillNhom = gop
        }

        // 2 hộp nhận xét Điểm mạnh & Cần tập trung
        let chuDiemManh: String
        if tongHop.doanhThuQD > 0 && tongHop.doanhThuQD >= tbDTQD {
            chuDiemManh = "★ Doanh thu QĐ đạt \(tongHop.doanhThuQD.chuoiSoGonVN) tr (Hạng \(hang)/\(tongNV), vượt TB \(tbDTQD.chuoiSoGonVN) tr)."
        } else if tongHop.soMonDat > 0 {
            chuDiemManh = "★ Thi đua đạt \(tongHop.soMonDat)/\(tongHop.tongMonGiao) chương trình (HT TB \(tongHop.phanTramHTTB.chuoiPhanTram))."
        } else if tongHop.soLuongDon > 0 && tongHop.soLuongDon >= tbSoBill {
            chuDiemManh = "★ Số lượt bill bán hàng đạt \(tongHop.soLuongDon.chuoiSoNguyenVN) đơn (vượt TB \(Int(round(tbSoBill))) đơn)."
        } else {
            chuDiemManh = "★ Đang cập nhật dữ liệu Doanh thu (\(diemDoanhThu)/6) & Năng suất (\(diemNangSuat)/3)."
        }

        let chuCanTapTrung: String
        if tongHop.doanhThuQD > 0 && tongHop.doanhThuQD < tbDTQD {
            chuCanTapTrung = "● Cần tập trung đẩy Doanh thu QĐ (đang \(tongHop.doanhThuQD.chuoiSoGonVN) tr, dưới TB \(tbDTQD.chuoiSoGonVN) tr)."
        } else if tongHop.tongMonGiao > 0 && tongHop.soMonDat < tongHop.tongMonGiao {
            chuCanTapTrung = "● Cần tập trung Thi đua: \(tongHop.tongMonGiao - tongHop.soMonDat)/\(tongHop.tongMonGiao) ngành hàng chưa đạt target."
        } else {
            chuCanTapTrung = "● Khung Năng suất, Hiệu quả khai thác & Đơn giá đã sẵn sàng chờ bổ sung số liệu."
        }

        func taoHopNhanXet(_ chu: String, nen: UIColor, mauChu: UIColor) -> UIView {
            let v = UIView()
            v.backgroundColor = nen
            v.layer.cornerRadius = 8
            let lb = UILabel()
            lb.text = chu
            lb.font = .systemFont(ofSize: 11.0, weight: .semibold)
            lb.textColor = mauChu
            lb.numberOfLines = 0
            lb.translatesAutoresizingMaskIntoConstraints = false
            v.addSubview(lb)
            NSLayoutConstraint.activate([
                lb.topAnchor.constraint(equalTo: v.topAnchor, constant: 7),
                lb.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -7),
                lb.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 10),
                lb.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -10)
            ])
            return v
        }

        let hopManh = taoHopNhanXet(chuDiemManh, nen: UIColor(red: 0.91, green: 0.98, blue: 0.94, alpha: 1), mauChu: UIColor(red: 0.06, green: 0.38, blue: 0.22, alpha: 1))
        let hopTapTrung = taoHopNhanXet(chuCanTapTrung, nen: UIColor(red: 1.0, green: 0.94, blue: 0.95, alpha: 1), mauChu: UIColor(red: 0.65, green: 0.12, blue: 0.20, alpha: 1))

        let hangNhanXet = UIStackView(arrangedSubviews: [hopManh, hopTapTrung])
        hangNhanXet.axis = laCheDoXuatAnhRong ? .horizontal : .vertical
        hangNhanXet.spacing = 6
        hangNhanXet.distribution = laCheDoXuatAnhRong ? .fillEqually : .fill

        let nutQT = taoNutQuyTac(
            tieuDe: "Quy tắc tính Điểm Sức Khỏe (27 điểm)",
            noiDung: "• Doanh thu (6 điểm): Doanh thu QĐ, % Target, Số lượt bill, % Quy đổi, % Trả chậm, % Bán kèm.\n• Năng suất (3 điểm): Điểm thưởng ERP, Điểm thưởng/Giờ công, DTQĐ/Giờ công.\n• Hiệu quả khai thác (9 điểm): 9 nhóm ngành hàng đạt >= 100% TB.\n• Đơn giá (8 điểm): 8 nhóm sản phẩm chính đạt >= TB siêu thị.\n• Thi đua (1 điểm): Hoàn thành mục tiêu chương trình thi đua."
        )

        let nutBoSung = UIButton(type: .system)
        nutBoSung.setTitle(" ✏️ Bổ sung thông số ", for: .normal)
        nutBoSung.titleLabel?.font = .systemFont(ofSize: 10.5, weight: .bold)
        nutBoSung.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
        nutBoSung.backgroundColor = BangMauBCTD.nenHeaderPhu
        nutBoSung.layer.cornerRadius = 6
        nutBoSung.layer.borderWidth = 1
        nutBoSung.layer.borderColor = BangMauBCTD.xanhChuDao.withAlphaComponent(0.35).cgColor
        nutBoSung.contentEdgeInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
        nutBoSung.addTarget(self, action: #selector(moMenuBoSungThongSo), for: .touchUpInside)

        let hangChanHeader = UIStackView(arrangedSubviews: [nutQT, UIView(), nutBoSung])
        hangChanHeader.axis = .horizontal
        hangChanHeader.alignment = .center

        let ngan = UIStackView(arrangedSubviews: [hangTren, hangPillNhom, hangNhanXet, hangChanHeader])
        ngan.axis = .vertical
        ngan.spacing = 10
        ngan.translatesAutoresizingMaskIntoConstraints = false
        the.addSubview(ngan)

        NSLayoutConstraint.activate([
            ngan.topAnchor.constraint(equalTo: the.topAnchor, constant: 12),
            ngan.bottomAnchor.constraint(equalTo: the.bottomAnchor, constant: -12),
            ngan.leadingAnchor.constraint(equalTo: the.leadingAnchor, constant: 12),
            ngan.trailingAnchor.constraint(equalTo: the.trailingAnchor, constant: -12)
        ])
        return the
    }

    private func taoTieuDeKhoi(
        ten: String,
        mauTen: UIColor,
        badge: String,
        nenBadge: UIColor,
        mauBadge: UIColor,
        quyTac: String,
        chuPhai: String? = nil
    ) -> UIView {
        let lbTen = UILabel()
        lbTen.text = ten
        lbTen.font = .systemFont(ofSize: 12.5, weight: .heavy)
        lbTen.textColor = mauTen

        let lbBadge = UILabel()
        lbBadge.text = " \(badge) "
        lbBadge.font = .monospacedDigitSystemFont(ofSize: 11.0, weight: .heavy)
        lbBadge.textColor = mauBadge
        lbBadge.backgroundColor = nenBadge
        lbBadge.layer.cornerRadius = 6
        lbBadge.clipsToBounds = true

        let nutQT = taoNutQuyTac(tieuDe: "Quy tắc \(ten)", noiDung: quyTac)

        var views: [UIView] = [lbTen, lbBadge, nutQT, UIView()]
        if let phai = chuPhai, !phai.isEmpty {
            let lbPhai = UILabel()
            lbPhai.text = phai
            lbPhai.font = .systemFont(ofSize: 10.5, weight: .semibold)
            lbPhai.textColor = UIColor(red: 0.40, green: 0.46, blue: 0.56, alpha: 1)
            lbPhai.textAlignment = .right
            views.append(lbPhai)
        }

        let hang = UIStackView(arrangedSubviews: views)
        hang.axis = .horizontal
        hang.spacing = 6
        hang.alignment = .center
        return hang
    }

    private func xepLuoiThe(_ cacThe: [UIView], soCot: Int) -> UIStackView {
        let nganDoc = UIStackView()
        nganDoc.axis = .vertical
        nganDoc.spacing = 8
        var idx = 0
        while idx < cacThe.count {
            let hang = UIStackView()
            hang.axis = .horizontal
            hang.spacing = 8
            hang.distribution = .fillEqually
            for c in 0..<soCot {
                if idx + c < cacThe.count {
                    hang.addArrangedSubview(cacThe[idx + c])
                } else {
                    hang.addArrangedSubview(UIView())
                }
            }
            nganDoc.addArrangedSubview(hang)
            idx += soCot
        }
        return nganDoc
    }

    private func taoKhoiDoanhThu(
        diemDat: Int,
        tbDTQD: Double,
        mtCaNhan: Double?,
        ptTargetCaNhan: Double?,
        tbPtTargetST: Double?,
        tbSoBill: Double,
        ptQuyDoi: Double?,
        tbQuyDoi: Double?,
        ptTraCham: Double?,
        tbTraCham: Double?,
        ptBanKem: Double?,
        tbBanKem: Double?
    ) -> UIView {
        let khung = UIView()
        khung.backgroundColor = UIColor(red: 0.93, green: 0.96, blue: 1.0, alpha: 1) // #EEF6FF
        khung.layer.cornerRadius = 14

        let dau = taoTieuDeKhoi(
            ten: "DOANH THU",
            mauTen: UIColor(red: 0.10, green: 0.32, blue: 0.78, alpha: 1),
            badge: "\(diemDat)/6",
            nenBadge: .white,
            mauBadge: UIColor(red: 0.10, green: 0.32, blue: 0.78, alpha: 1),
            quyTac: "Mỗi chỉ số trong 6 chỉ số Doanh thu (Doanh thu QĐ, % Target, Số lượt bill bán hàng, % Quy đổi, % Trả chậm, % Bán kèm) đạt từ mức Trung bình (TB) siêu thị trở lên được tính 1 điểm."
        )

        // 1. DOANH THU QĐ
        let dtQD = tongHop.doanhThuQD
        let tt1: TheChiSoSucKhoeView.TrangThaiThe = dtQD > 0 ? (dtQD >= tbDTQD - 0.001 ? .dat : .chuaDat) : .chuaCoSo
        let the1 = TheChiSoSucKhoeView(
            tieuDe: "DOANH THU QĐ",
            giaTri: dtQD > 0 ? "\(dtQD.chuoiSoGonVN) tr" : "—",
            chuoiTB: tbDTQD > 0 ? "TB \(String(format: "%.1f", tbDTQD)) tr" : "TB -- tr",
            chuoiPhu: tongHop.phanTramTiTrong > 0 ? String(format: "Tỉ trọng %.1f%%", tongHop.phanTramTiTrong) : nil,
            trangThai: tt1
        ) { [weak self] in self?.moNhapNhanhDoanhThu() }

        // 2. % TARGET
        let tt2: TheChiSoSucKhoeView.TrangThaiThe
        if let pt = ptTargetCaNhan {
            tt2 = pt >= (tbPtTargetST ?? 100.0) - 0.001 ? .dat : .chuaDat
        } else {
            tt2 = .chuaCoSo
        }
        let the2 = TheChiSoSucKhoeView(
            tieuDe: "% TARGET",
            giaTri: ptTargetCaNhan != nil ? "\(Int(round(ptTargetCaNhan!)))%" : "—",
            chuoiTB: tbPtTargetST != nil ? "TB \(Int(round(tbPtTargetST!)))%" : "TB --%",
            chuoiPhu: mtCaNhan != nil ? String(format: "MT %.1f tr", mtCaNhan!) : "MT -- tr",
            trangThai: tt2
        ) { [weak self] in self?.moNhapNhanhDoanhThu() }

        // 3. SỐ LƯỢT BILL BÁN HÀNG
        let bill = tongHop.soLuongDon
        let tt3: TheChiSoSucKhoeView.TrangThaiThe = bill > 0 ? (bill >= tbSoBill - 0.001 ? .dat : .chuaDat) : .chuaCoSo
        let the3 = TheChiSoSucKhoeView(
            tieuDe: "SỐ LƯỢT BILL BÁN HÀNG",
            giaTri: bill > 0 ? bill.chuoiSoNguyenVN : "—",
            chuoiTB: tbSoBill > 0 ? "TB \(Int(round(tbSoBill)))" : "TB --",
            trangThai: tt3
        ) { [weak self] in self?.moNhapNhanhDoanhThu() }

        // 4. % QUY ĐỔI
        let tt4: TheChiSoSucKhoeView.TrangThaiThe
        if let qd = ptQuyDoi {
            tt4 = qd >= (tbQuyDoi ?? 40.0) - 0.001 ? .dat : .chuaDat
        } else {
            tt4 = .chuaCoSo
        }
        let the4 = TheChiSoSucKhoeView(
            tieuDe: "% QUY ĐỔI",
            giaTri: ptQuyDoi != nil ? "\(Int(round(ptQuyDoi!)))%" : "—",
            chuoiTB: tbQuyDoi != nil ? "TB \(Int(round(tbQuyDoi!)))%" : "TB --%",
            trangThai: tt4
        ) { [weak self] in self?.moNhapNhanhDoanhThu() }

        // 5. % TRẢ CHẬM
        let tt5: TheChiSoSucKhoeView.TrangThaiThe
        if let tc = ptTraCham {
            tt5 = tc >= (tbTraCham ?? 45.0) - 0.001 ? .dat : .chuaDat
        } else {
            tt5 = .chuaCoSo
        }
        let the5 = TheChiSoSucKhoeView(
            tieuDe: "% TRẢ CHẬM",
            giaTri: ptTraCham != nil ? "\(Int(round(ptTraCham!)))%" : "—",
            chuoiTB: tbTraCham != nil ? "TB \(Int(round(tbTraCham!)))%" : "TB --%",
            chuoiPhu: tongHop.dtQDKhoanVay > 0 ? "Vay \(tongHop.dtQDKhoanVay.chuoiSoGonVN)" : nil,
            trangThai: tt5
        ) { [weak self] in self?.moNhapNhanhDoanhThu() }

        // 6. % BÁN KÈM
        let tt6: TheChiSoSucKhoeView.TrangThaiThe
        if let bk = ptBanKem {
            tt6 = bk >= (tbBanKem ?? 50.0) - 0.001 ? .dat : .chuaDat
        } else {
            tt6 = .chuaCoSo
        }
        let the6 = TheChiSoSucKhoeView(
            tieuDe: "% BÁN KÈM",
            giaTri: ptBanKem != nil ? "\(Int(round(ptBanKem!)))%" : "—",
            chuoiTB: tbBanKem != nil ? "TB \(Int(round(tbBanKem!)))%" : "TB --%",
            trangThai: tt6
        ) { [weak self] in self?.moNhapNhanhDoanhThu() }

        let luoi = xepLuoiThe([the1, the2, the3, the4, the5, the6], soCot: laCheDoXuatAnhRong ? 3 : 2)
        let ngan = UIStackView(arrangedSubviews: [dau, luoi])
        ngan.axis = .vertical
        ngan.spacing = 10
        ngan.translatesAutoresizingMaskIntoConstraints = false
        khung.addSubview(ngan)

        NSLayoutConstraint.activate([
            ngan.topAnchor.constraint(equalTo: khung.topAnchor, constant: 12),
            ngan.bottomAnchor.constraint(equalTo: khung.bottomAnchor, constant: -12),
            ngan.leadingAnchor.constraint(equalTo: khung.leadingAnchor, constant: 12),
            ngan.trailingAnchor.constraint(equalTo: khung.trailingAnchor, constant: -12)
        ])
        return khung
    }

    private func taoKhoiNangSuat(diemDat: Int, boSung: DuLieuSucKhoeBoSungNV?, dtqdGC: Double?) -> UIView {
        let khung = UIView()
        khung.backgroundColor = UIColor(red: 0.91, green: 0.98, blue: 0.94, alpha: 1) // #E8FAF0
        khung.layer.cornerRadius = 14

        let dau = taoTieuDeKhoi(
            ten: "NĂNG SUẤT",
            mauTen: UIColor(red: 0.04, green: 0.47, blue: 0.27, alpha: 1),
            badge: "\(diemDat)/3",
            nenBadge: .white,
            mauBadge: UIColor(red: 0.04, green: 0.47, blue: 0.27, alpha: 1),
            quyTac: "Đánh giá 3 chỉ số Năng suất cá nhân so với TB siêu thị: Điểm thưởng ERP, Điểm thưởng / Giờ công và Doanh thu QĐ / Giờ công."
        )

        let erp = boSung?.diemThuongERP
        let tbErp = boSung?.tbDiemThuongERP
        let tt1: TheChiSoSucKhoeView.TrangThaiThe = erp != nil ? (erp! >= (tbErp ?? erp!) ? .dat : .chuaDat) : .chuaCoSo
        let the1 = TheChiSoSucKhoeView(
            tieuDe: "ĐIỂM THƯỞNG ERP",
            giaTri: erp != nil ? erp!.chuoiSoNguyenVN : "—",
            chuoiTB: tbErp != nil ? "TB \(tbErp!.chuoiSoNguyenVN)" : "TB --",
            trangThai: tt1
        ) { [weak self] in self?.moNhapNhanhNangSuat() }

        let dtGC = boSung?.diemThuongTrenGioCong
        let tbDtGC = boSung?.tbDiemThuongTrenGioCong
        let tt2: TheChiSoSucKhoeView.TrangThaiThe = dtGC != nil ? (dtGC! >= (tbDtGC ?? dtGC!) ? .dat : .chuaDat) : .chuaCoSo
        let the2 = TheChiSoSucKhoeView(
            tieuDe: "ĐIỂM THƯỞNG / GIỜ CÔNG",
            giaTri: dtGC != nil ? dtGC!.chuoiSoNguyenVN : "—",
            chuoiTB: tbDtGC != nil ? "TB \(tbDtGC!.chuoiSoNguyenVN)" : "TB --",
            trangThai: tt2
        ) { [weak self] in self?.moNhapNhanhNangSuat() }

        let tbQdGC = boSung?.tbDtqdTrenGioCong
        let tt3: TheChiSoSucKhoeView.TrangThaiThe = dtqdGC != nil ? (dtqdGC! >= (tbQdGC ?? dtqdGC!) ? .dat : .chuaDat) : .chuaCoSo
        let the3 = TheChiSoSucKhoeView(
            tieuDe: "DTQĐ / GIỜ CÔNG",
            giaTri: dtqdGC != nil ? String(format: "%.2f", dtqdGC!) : "—",
            chuoiTB: tbQdGC != nil ? String(format: "TB %.2f", tbQdGC!) : "TB --",
            trangThai: tt3
        ) { [weak self] in self?.moNhapNhanhNangSuat() }

        let luoi = xepLuoiThe([the1, the2, the3], soCot: laCheDoXuatAnhRong ? 3 : 3)
        let ngan = UIStackView(arrangedSubviews: [dau, luoi])
        ngan.axis = .vertical
        ngan.spacing = 10
        ngan.translatesAutoresizingMaskIntoConstraints = false
        khung.addSubview(ngan)

        NSLayoutConstraint.activate([
            ngan.topAnchor.constraint(equalTo: khung.topAnchor, constant: 12),
            ngan.bottomAnchor.constraint(equalTo: khung.bottomAnchor, constant: -12),
            ngan.leadingAnchor.constraint(equalTo: khung.leadingAnchor, constant: 12),
            ngan.trailingAnchor.constraint(equalTo: khung.trailingAnchor, constant: -12)
        ])
        return khung
    }

    private func taoKhoiHieuQuaKhaiThac(diemDat: Int, boSung: DuLieuSucKhoeBoSungNV?) -> UIView {
        let khung = UIView()
        khung.backgroundColor = UIColor(red: 1.0, green: 0.96, blue: 0.91, alpha: 1) // #FFF5E8
        khung.layer.cornerRadius = 14

        let dau = taoTieuDeKhoi(
            ten: "HIỆU QUẢ KHAI THÁC",
            mauTen: UIColor(red: 0.68, green: 0.30, blue: 0.05, alpha: 1),
            badge: "\(diemDat)/9",
            nenBadge: .white,
            mauBadge: UIColor(red: 0.68, green: 0.30, blue: 0.05, alpha: 1),
            quyTac: "Theo dõi tỷ lệ khai thác bán kèm 9 nhóm ngành hàng trọng tâm. Vạch đứng ở giữa thanh biểu thị mốc 100% TB siêu thị.",
            chuPhai: "| = 100% TB"
        )

        let nganTrai = UIStackView()
        nganTrai.axis = .vertical
        nganTrai.spacing = 10
        for muc in DuLieuSucKhoeBoSungNV.danhSachMucHieuQuaTrai {
            let v = boSung?.hieuQuaKhaiThac[muc.khoa]
            let thanh = ThanhHieuQuaKhaiThacView(tenMuc: muc.nhan, giaTriPhanTram: v) { [weak self] in
                self?.moNhapNhanhHieuQua()
            }
            nganTrai.addArrangedSubview(thanh)
        }

        let nganPhai = UIStackView()
        nganPhai.axis = .vertical
        nganPhai.spacing = 10
        for muc in DuLieuSucKhoeBoSungNV.danhSachMucHieuQuaPhai {
            let v = boSung?.hieuQuaKhaiThac[muc.khoa]
            let thanh = ThanhHieuQuaKhaiThacView(tenMuc: muc.nhan, giaTriPhanTram: v) { [weak self] in
                self?.moNhapNhanhHieuQua()
            }
            nganPhai.addArrangedSubview(thanh)
        }
        nganPhai.addArrangedSubview(UIView())

        let hangHaiCot = UIStackView(arrangedSubviews: [nganTrai, nganPhai])
        hangHaiCot.axis = .horizontal
        hangHaiCot.spacing = 16
        hangHaiCot.distribution = .fillEqually
        hangHaiCot.alignment = .top

        let ngan = UIStackView(arrangedSubviews: [dau, hangHaiCot])
        ngan.axis = .vertical
        ngan.spacing = 10
        ngan.translatesAutoresizingMaskIntoConstraints = false
        khung.addSubview(ngan)

        NSLayoutConstraint.activate([
            ngan.topAnchor.constraint(equalTo: khung.topAnchor, constant: 12),
            ngan.bottomAnchor.constraint(equalTo: khung.bottomAnchor, constant: -12),
            ngan.leadingAnchor.constraint(equalTo: khung.leadingAnchor, constant: 12),
            ngan.trailingAnchor.constraint(equalTo: khung.trailingAnchor, constant: -12)
        ])
        return khung
    }

    private func taoKhoiThiDua(
        diemDat: Int,
        tyLeDat: Int,
        tbTyLeDatST: Int,
        soMonDat: Int,
        soMonGanDat: Int,
        soMonCanCoGang: Int,
        soMonChuaCoSo: Int,
        tongSoChuongTrinh: Int,
        cacMonCoSo: [MonThiDuaNhanVien],
        dsChuaCoSo: [String],
        dsThiDuaST: [DongThiDua]
    ) -> UIView {
        let khung = UIView()
        khung.backgroundColor = UIColor(red: 1.0, green: 0.94, blue: 0.96, alpha: 1) // #FFF0F5
        khung.layer.cornerRadius = 14

        let daDatThiDua = diemDat > 0
        let dau = taoTieuDeKhoi(
            ten: "THI ĐUA",
            mauTen: UIColor(red: 0.72, green: 0.08, blue: 0.24, alpha: 1),
            badge: daDatThiDua ? "✓ Đạt" : "✕ Chưa đạt",
            nenBadge: .white,
            mauBadge: daDatThiDua ? UIColor(red: 0.05, green: 0.48, blue: 0.28, alpha: 1) : UIColor(red: 0.76, green: 0.12, blue: 0.12, alpha: 1),
            quyTac: "Tổng hợp tiến độ hoàn thành các chương trình thi đua ngành hàng được giao cho nhân viên trong tháng.",
            chuPhai: "so với TB siêu thị \(tbTyLeDatST)%"
        )

        // Hộp trắng tóm tắt % chương trình đạt + thanh stacked bar 4 màu
        let hopTomTat = UIView()
        hopTomTat.backgroundColor = .white
        hopTomTat.layer.cornerRadius = 10
        hopTomTat.layer.borderWidth = 1
        hopTomTat.layer.borderColor = UIColor(red: 0.94, green: 0.88, blue: 0.90, alpha: 1).cgColor

        let lbPhanTramLon = UILabel()
        lbPhanTramLon.text = "\(tyLeDat)%"
        lbPhanTramLon.font = .monospacedDigitSystemFont(ofSize: 24, weight: .heavy)
        lbPhanTramLon.textColor = daDatThiDua
            ? UIColor(red: 0.05, green: 0.48, blue: 0.28, alpha: 1)
            : UIColor(red: 0.72, green: 0.08, blue: 0.24, alpha: 1)

        let lbSoMon = UILabel()
        lbSoMon.text = "\(soMonDat)/\(tongSoChuongTrinh) chương trình đạt"
        lbSoMon.font = .systemFont(ofSize: 10.5, weight: .medium)
        lbSoMon.textColor = UIColor(red: 0.45, green: 0.51, blue: 0.60, alpha: 1)

        let nganTraiTT = UIStackView(arrangedSubviews: [lbPhanTramLon, lbSoMon])
        nganTraiTT.axis = .vertical
        nganTraiTT.spacing = 2
        nganTraiTT.setContentHuggingPriority(.required, for: .horizontal)
        nganTraiTT.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Thanh tiến độ 4 phân đoạn
        let thanh4Mau = UIStackView()
        thanh4Mau.axis = .horizontal
        thanh4Mau.spacing = 0
        thanh4Mau.layer.cornerRadius = 6
        thanh4Mau.clipsToBounds = true
        thanh4Mau.translatesAutoresizingMaskIntoConstraints = false
        thanh4Mau.heightAnchor.constraint(equalToConstant: 12).isActive = true

        let tongM = CGFloat(max(1, tongSoChuongTrinh))
        let cacDoan: [(Int, UIColor)] = [
            (soMonDat, UIColor(red: 0.06, green: 0.65, blue: 0.38, alpha: 1)),
            (soMonGanDat, UIColor(red: 0.95, green: 0.65, blue: 0.05, alpha: 1)),
            (soMonCanCoGang, UIColor(red: 0.86, green: 0.16, blue: 0.16, alpha: 1)),
            (max(0, tongSoChuongTrinh - soMonDat - soMonGanDat - soMonCanCoGang), UIColor(red: 0.82, green: 0.85, blue: 0.90, alpha: 1))
        ]
        var doanTruoc: (view: UIView, soLuong: Int)?
        for (sl, mau) in cacDoan where sl > 0 {
            let v = UIView()
            v.backgroundColor = mau
            v.translatesAutoresizingMaskIntoConstraints = false
            thanh4Mau.addArrangedSubview(v)
            if let dt = doanTruoc {
                v.widthAnchor.constraint(equalTo: dt.view.widthAnchor, multiplier: CGFloat(sl) / CGFloat(dt.soLuong)).isActive = true
            }
            doanTruoc = (v, sl)
        }
        if thanh4Mau.arrangedSubviews.isEmpty {
            let v = UIView()
            v.backgroundColor = UIColor(red: 0.82, green: 0.85, blue: 0.90, alpha: 1)
            thanh4Mau.addArrangedSubview(v)
        }
        _ = tongM

        let lbChuThich = UILabel()
        let strChuThich = NSMutableAttributedString()
        func themCham(_ mau: UIColor, _ chu: String) {
            let dot = NSAttributedString(string: "● ", attributes: [.foregroundColor: mau, .font: UIFont.systemFont(ofSize: 10.5, weight: .bold)])
            let txt = NSAttributedString(string: "\(chu)   ", attributes: [.foregroundColor: UIColor(red: 0.25, green: 0.30, blue: 0.38, alpha: 1), .font: UIFont.systemFont(ofSize: 10.5, weight: .semibold)])
            strChuThich.append(dot)
            strChuThich.append(txt)
        }
        themCham(UIColor(red: 0.06, green: 0.65, blue: 0.38, alpha: 1), "Đạt \(soMonDat)")
        themCham(UIColor(red: 0.95, green: 0.65, blue: 0.05, alpha: 1), "Gần đạt \(soMonGanDat)")
        themCham(UIColor(red: 0.86, green: 0.16, blue: 0.16, alpha: 1), "Cần cố gắng \(soMonCanCoGang)")
        themCham(UIColor(red: 0.68, green: 0.73, blue: 0.80, alpha: 1), "Chưa có số \(soMonChuaCoSo)")
        lbChuThich.attributedText = strChuThich
        lbChuThich.numberOfLines = 0

        let nganPhaiTT = UIStackView(arrangedSubviews: [thanh4Mau, lbChuThich])
        nganPhaiTT.axis = .vertical
        nganPhaiTT.spacing = 6

        let hangTomTat = UIStackView(arrangedSubviews: [nganTraiTT, nganPhaiTT])
        hangTomTat.axis = .horizontal
        hangTomTat.spacing = 14
        hangTomTat.alignment = .center
        hangTomTat.translatesAutoresizingMaskIntoConstraints = false
        hopTomTat.addSubview(hangTomTat)
        NSLayoutConstraint.activate([
            hangTomTat.topAnchor.constraint(equalTo: hopTomTat.topAnchor, constant: 10),
            hangTomTat.bottomAnchor.constraint(equalTo: hopTomTat.bottomAnchor, constant: -10),
            hangTomTat.leadingAnchor.constraint(equalTo: hopTomTat.leadingAnchor, constant: 12),
            hangTomTat.trailingAnchor.constraint(equalTo: hopTomTat.trailingAnchor, constant: -12)
        ])

        var cacThanhPhan: [UIView] = [dau, hopTomTat]

        // Lưới các thẻ mini chương trình thi đua đã có số liệu
        if !cacMonCoSo.isEmpty {
            let cacTheMini = cacMonCoSo.map { mon in
                TheMiniMonThiDuaSKView(mon: mon) { [weak self] in
                    self?.moSuaMonThiDuaCaNhan(mon)
                }
            }
            let soCotMini = laCheDoXuatAnhRong ? 5 : 2
            cacThanhPhan.append(xepLuoiThe(cacTheMini, soCot: soCotMini))
        }

        // Dòng chữ liệt kê các chương trình chưa có số liệu ở chân khối Thi đua
        if !dsChuaCoSo.isEmpty {
            let lbChuaCo = UILabel()
            let attr = NSMutableAttributedString(
                string: "Chưa có số liệu (\(dsChuaCoSo.count)): ",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 10.5, weight: .bold),
                    .foregroundColor: UIColor(red: 0.25, green: 0.30, blue: 0.38, alpha: 1)
                ]
            )
            attr.append(NSAttributedString(
                string: dsChuaCoSo.joined(separator: " · "),
                attributes: [
                    .font: UIFont.systemFont(ofSize: 10.5, weight: .regular),
                    .foregroundColor: UIColor(red: 0.42, green: 0.48, blue: 0.58, alpha: 1)
                ]
            ))
            lbChuaCo.attributedText = attr
            lbChuaCo.numberOfLines = 0
            cacThanhPhan.append(lbChuaCo)
        }

        let dsKhongTarget = dsThiDuaST.filter { $0.target <= 0.0001 }.map(\.tenNganhHang)
        if !dsKhongTarget.isEmpty {
            let lbKT = UILabel()
            let attr = NSMutableAttributedString(
                string: "Siêu thị không có target – không tính tỷ lệ đạt (\(dsKhongTarget.count)): ",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 10.5, weight: .bold),
                    .foregroundColor: UIColor(red: 0.25, green: 0.30, blue: 0.38, alpha: 1)
                ]
            )
            attr.append(NSAttributedString(
                string: dsKhongTarget.joined(separator: " · "),
                attributes: [
                    .font: UIFont.systemFont(ofSize: 10.5, weight: .regular),
                    .foregroundColor: UIColor(red: 0.42, green: 0.48, blue: 0.58, alpha: 1)
                ]
            ))
            lbKT.attributedText = attr
            lbKT.numberOfLines = 0
            cacThanhPhan.append(lbKT)
        }

        let ngan = UIStackView(arrangedSubviews: cacThanhPhan)
        ngan.axis = .vertical
        ngan.spacing = 10
        ngan.translatesAutoresizingMaskIntoConstraints = false
        khung.addSubview(ngan)

        NSLayoutConstraint.activate([
            ngan.topAnchor.constraint(equalTo: khung.topAnchor, constant: 12),
            ngan.bottomAnchor.constraint(equalTo: khung.bottomAnchor, constant: -12),
            ngan.leadingAnchor.constraint(equalTo: khung.leadingAnchor, constant: 12),
            ngan.trailingAnchor.constraint(equalTo: khung.trailingAnchor, constant: -12)
        ])
        return khung
    }

    private func taoKhoiDonGia(diemDat: Int, boSung: DuLieuSucKhoeBoSungNV?) -> UIView {
        let khung = UIView()
        khung.backgroundColor = UIColor(red: 0.95, green: 0.94, blue: 1.0, alpha: 1) // #F3F0FF
        khung.layer.cornerRadius = 14

        let dau = taoTieuDeKhoi(
            ten: "ĐƠN GIÁ",
            mauTen: UIColor(red: 0.38, green: 0.16, blue: 0.78, alpha: 1),
            badge: "\(diemDat)/8",
            nenBadge: .white,
            mauBadge: UIColor(red: 0.38, green: 0.16, blue: 0.78, alpha: 1),
            quyTac: "Đơn giá trung bình sản phẩm chính và 7 ngành hàng chủ lực (Tivi, Tủ lạnh, Máy giặt, Máy lạnh, Máy lọc nước, Điện thoại, Laptop) so với TB siêu thị."
        )

        let cacThe: [UIView] = DuLieuSucKhoeBoSungNV.danhSachMucDonGia.map { muc in
            let val = boSung?.donGiaCaNhan[muc.khoa]
            let tb = boSung?.donGiaTrungBinhST[muc.khoa]
            let tt: TheChiSoSucKhoeView.TrangThaiThe
            if let v = val, v > 0 {
                tt = v >= (tb ?? v) - 0.001 ? .dat : .chuaDat
            } else {
                tt = .chuaCoSo
            }
            return TheChiSoSucKhoeView(
                tieuDe: muc.nhan,
                giaTri: (val != nil && val! > 0) ? String(format: "%.1f tr", val!) : "—",
                chuoiTB: (tb != nil && tb! > 0) ? String(format: "TB %.1f tr", tb!) : "TB -- tr",
                trangThai: tt
            ) { [weak self] in self?.moNhapNhanhDonGia(khoa: muc.khoa, nhan: muc.nhan) }
        }

        let luoi = xepLuoiThe(cacThe, soCot: laCheDoXuatAnhRong ? 4 : 2)
        let ngan = UIStackView(arrangedSubviews: [dau, luoi])
        ngan.axis = .vertical
        ngan.spacing = 10
        ngan.translatesAutoresizingMaskIntoConstraints = false
        khung.addSubview(ngan)

        NSLayoutConstraint.activate([
            ngan.topAnchor.constraint(equalTo: khung.topAnchor, constant: 12),
            ngan.bottomAnchor.constraint(equalTo: khung.bottomAnchor, constant: -12),
            ngan.leadingAnchor.constraint(equalTo: khung.leadingAnchor, constant: 12),
            ngan.trailingAnchor.constraint(equalTo: khung.trailingAnchor, constant: -12)
        ])
        return khung
    }

    private func taoKhoiHaiBieuDoDuoi(
        boSung: DuLieuSucKhoeBoSungNV?,
        ds6Thang: [(nhanThang: String, giaTri: Double?)]
    ) -> UIView {
        // 1. Khối Tỷ trọng ngành hàng (Biểu đồ tròn + Chú giải 8 nhóm)
        let theTyTrong = UIView()
        theTyTrong.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.99, alpha: 1)
        theTyTrong.layer.cornerRadius = 14

        let dauTT = taoTieuDeKhoi(
            ten: "TỶ TRỌNG NGÀNH HÀNG",
            mauTen: UIColor(red: 0.35, green: 0.18, blue: 0.72, alpha: 1),
            badge: "8 nhóm",
            nenBadge: .white,
            mauBadge: UIColor(red: 0.35, green: 0.18, blue: 0.72, alpha: 1),
            quyTac: "Cơ cấu tỷ trọng doanh thu theo 8 nhóm ngành hàng chính của nhân viên."
        )

        let bangMauNganh: [UIColor] = [
            UIColor(red: 0.21, green: 0.49, blue: 0.85, alpha: 1), // Apple
            UIColor(red: 0.53, green: 0.31, blue: 0.82, alpha: 1), // Tủ lạnh, đông, mát
            UIColor(red: 0.14, green: 0.62, blue: 0.35, alpha: 1), // Điện tử
            UIColor(red: 0.89, green: 0.56, blue: 0.13, alpha: 1), // Gia dụng
            UIColor(red: 0.84, green: 0.20, blue: 0.24, alpha: 1), // Viễn thông di động
            UIColor(red: 0.12, green: 0.63, blue: 0.64, alpha: 1), // Laptop
            UIColor(red: 0.33, green: 0.38, blue: 0.45, alpha: 1), // Máy lạnh & Máy nước nóng
            UIColor(red: 0.65, green: 0.70, blue: 0.77, alpha: 1)  // Khác
        ]

        let vongTron = BieuDoTronTyTrongNganhHangView()
        vongTron.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vongTron.widthAnchor.constraint(equalToConstant: 112),
            vongTron.heightAnchor.constraint(equalToConstant: 112)
        ])

        var cacPhanTron: [(mau: UIColor, tyLe: Double)] = []
        let nganChuGiai = UIStackView()
        nganChuGiai.axis = .vertical
        nganChuGiai.spacing = 4

        for (i, nhom) in DuLieuSucKhoeBoSungNV.danhSachNhomTyTrongNganhHang.enumerated() {
            let mau = bangMauNganh[i % bangMauNganh.count]
            let val = boSung?.tyTrongNganhHang[nhom.khoa]
            cacPhanTron.append((mau: mau, tyLe: val ?? 0))

            let cham = UILabel()
            cham.text = "●"
            cham.font = .systemFont(ofSize: 10.5, weight: .bold)
            cham.textColor = mau
            cham.setContentHuggingPriority(.required, for: .horizontal)

            let lbTen = UILabel()
            lbTen.text = nhom.nhan
            lbTen.font = .systemFont(ofSize: 11.0, weight: .medium)
            lbTen.textColor = UIColor(red: 0.18, green: 0.24, blue: 0.34, alpha: 1)

            let lbPT = UILabel()
            lbPT.text = val != nil ? "\(Int(round(val!)))%" : "--%"
            lbPT.font = .monospacedDigitSystemFont(ofSize: 11.0, weight: .bold)
            lbPT.textColor = val != nil
                ? UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 1)
                : UIColor(red: 0.50, green: 0.56, blue: 0.65, alpha: 1)
            lbPT.textAlignment = .right
            lbPT.setContentHuggingPriority(.required, for: .horizontal)

            let dong = UIStackView(arrangedSubviews: [cham, lbTen, lbPT])
            dong.axis = .horizontal
            dong.spacing = 6
            nganChuGiai.addArrangedSubview(dong)
        }
        vongTron.cacPhan = cacPhanTron

        let hangNoiDungTT = UIStackView(arrangedSubviews: [vongTron, nganChuGiai])
        hangNoiDungTT.axis = .horizontal
        hangNoiDungTT.spacing = 14
        hangNoiDungTT.alignment = .center

        let nganTT = UIStackView(arrangedSubviews: [dauTT, hangNoiDungTT])
        nganTT.axis = .vertical
        nganTT.spacing = 10
        nganTT.translatesAutoresizingMaskIntoConstraints = false
        theTyTrong.addSubview(nganTT)
        NSLayoutConstraint.activate([
            nganTT.topAnchor.constraint(equalTo: theTyTrong.topAnchor, constant: 12),
            nganTT.bottomAnchor.constraint(equalTo: theTyTrong.bottomAnchor, constant: -12),
            nganTT.leadingAnchor.constraint(equalTo: theTyTrong.leadingAnchor, constant: 12),
            nganTT.trailingAnchor.constraint(equalTo: theTyTrong.trailingAnchor, constant: -12)
        ])

        // 2. Khối Doanh thu QĐ từng tháng (Biểu đồ cột 6 tháng)
        let theDTThang = UIView()
        theDTThang.backgroundColor = UIColor(red: 0.93, green: 0.96, blue: 1.0, alpha: 1)
        theDTThang.layer.cornerRadius = 14

        let dauDT = taoTieuDeKhoi(
            ten: "DOANH THU QĐ TỪNG THÁNG",
            mauTen: UIColor(red: 0.10, green: 0.32, blue: 0.78, alpha: 1),
            badge: "6 tháng",
            nenBadge: .white,
            mauBadge: UIColor(red: 0.10, green: 0.32, blue: 0.78, alpha: 1),
            quyTac: "Biểu đồ Doanh thu quy đổi cá nhân qua 6 tháng gần nhất (tự động lấy số liệu tháng hiện tại và các tháng đã lưu trong hệ thống).",
            chuPhai: "Đơn vị: triệu đồng"
        )

        let bieuDoCot = BieuDoCotDoanhThuThangNVView()
        bieuDoCot.duLieuThang = ds6Thang.map { (nhan: $0.nhanThang, giaTri: $0.giaTri) }
        bieuDoCot.translatesAutoresizingMaskIntoConstraints = false
        bieuDoCot.heightAnchor.constraint(equalToConstant: 148).isActive = true

        let nganDT = UIStackView(arrangedSubviews: [dauDT, bieuDoCot])
        nganDT.axis = .vertical
        nganDT.spacing = 10
        nganDT.translatesAutoresizingMaskIntoConstraints = false
        theDTThang.addSubview(nganDT)
        NSLayoutConstraint.activate([
            nganDT.topAnchor.constraint(equalTo: theDTThang.topAnchor, constant: 12),
            nganDT.bottomAnchor.constraint(equalTo: theDTThang.bottomAnchor, constant: -12),
            nganDT.leadingAnchor.constraint(equalTo: theDTThang.leadingAnchor, constant: 12),
            nganDT.trailingAnchor.constraint(equalTo: theDTThang.trailingAnchor, constant: -12)
        ])

        let gop = UIStackView(arrangedSubviews: [theTyTrong, theDTThang])
        gop.axis = laCheDoXuatAnhRong ? .horizontal : .vertical
        gop.spacing = 12
        gop.distribution = laCheDoXuatAnhRong ? .fillEqually : .fill
        return gop
    }

    // MARK: - Hộp thoại bổ sung / chỉnh sửa thông số Sức khoẻ nhân viên

    @objc private func moMenuBoSungThongSo() {
        guard let vc = timViewControllerCha() else { return }
        vc.hienMenuChon(
            tieuDe: "Bổ sung thông số: \(tongHop.nhanVien.hoTen)",
            thongDiep: "Chọn nhóm thông số bạn muốn nhập hoặc bổ sung cho nhân viên này:",
            cacMuc: [
                MucChonDMX(tieuDe: "💵 1. Bổ sung chỉ số Doanh thu (% Target, % Quy đổi, % Trả chậm, % Bán kèm)") { [weak self] in
                    self?.moNhapNhanhDoanhThu()
                },
                MucChonDMX(tieuDe: "⚡ 2. Bổ sung chỉ số Năng suất (Điểm ERP, Điểm/Giờ công, DTQĐ/Giờ công)") { [weak self] in
                    self?.moNhapNhanhNangSuat()
                },
                MucChonDMX(tieuDe: "📊 3. Bổ sung Hiệu quả khai thác (9 nhóm ngành hàng)") { [weak self] in
                    self?.moNhapNhanhHieuQua()
                },
                MucChonDMX(tieuDe: "🏷️ 4. Bổ sung Đơn giá sản phẩm (8 nhóm sản phẩm)") { [weak self] in
                    self?.moChonMucDonGiaDeNhap()
                },
                MucChonDMX(tieuDe: "Đóng", kieu: .huy)
            ]
        )
    }

    private func luuCapNhatBoSung(_ capNhat: (inout DuLieuSucKhoeBoSungNV) -> Void) {
        let ma = tongHop.nhanVien.maNV
        var dl = KhoDuLieu.dungChung.duLieu(cho: ngay)
        var hienTai = KhoDuLieu.dungChung.sucKhoeBoSungNhanVienThang(cho: ngay)[ma] ?? DuLieuSucKhoeBoSungNV()
        capNhat(&hienTai)
        dl.sucKhoeBoSungNhanVien[ma] = hienTai
        KhoDuLieu.dungChung.luu(dl)
        dungGiaoDien()
        khiYeuCauCapNhat?()
    }

    private func docSo(_ text: String?) -> Double? {
        let s = (text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: ",", with: ".")
        guard !s.isEmpty else { return nil }
        return Double(s)
    }

    private func moNhapNhanhDoanhThu() {
        guard let vc = timViewControllerCha() else { return }
        let hienTai = KhoDuLieu.dungChung.sucKhoeBoSungNhanVienThang(cho: ngay)[tongHop.nhanVien.maNV] ?? DuLieuSucKhoeBoSungNV()
        let hop = UIAlertController(
            title: "Chỉ số Doanh thu — \(tongHop.nhanVien.hoTen)",
            message: "Nhập các chỉ số bổ sung (để trống nếu chưa có):",
            preferredStyle: .alert
        )
        hop.addTextField { tf in
            tf.placeholder = "Mục tiêu Target QĐ cá nhân (tr, VD: 745.1)"
            tf.keyboardType = .decimalPad
            if let v = hienTai.mucTieuTargetQD { tf.text = String(v) }
        }
        hop.addTextField { tf in
            tf.placeholder = "% Target đạt được (VD: 181)"
            tf.keyboardType = .decimalPad
            if let v = hienTai.phanTramTarget { tf.text = String(v) }
        }
        hop.addTextField { tf in
            tf.placeholder = "% Quy đổi cá nhân (VD: 34)"
            tf.keyboardType = .decimalPad
            if let v = hienTai.phanTramQuyDoi { tf.text = String(v) }
        }
        hop.addTextField { tf in
            tf.placeholder = "% Trả chậm cá nhân (VD: 73)"
            tf.keyboardType = .decimalPad
            if let v = hienTai.phanTramTraCham { tf.text = String(v) }
        }
        hop.addTextField { tf in
            tf.placeholder = "% Bán kèm cá nhân (VD: 20)"
            tf.keyboardType = .decimalPad
            if let v = hienTai.phanTramBanKem { tf.text = String(v) }
        }
        hop.addAction(UIAlertAction(title: "Lưu", style: .default) { [weak self] _ in
            guard let self, let tfs = hop.textFields, tfs.count >= 5 else { return }
            self.luuCapNhatBoSung { bs in
                if let v = self.docSo(tfs[0].text) { bs.mucTieuTargetQD = v }
                if let v = self.docSo(tfs[1].text) { bs.phanTramTarget = v }
                if let v = self.docSo(tfs[2].text) { bs.phanTramQuyDoi = v }
                if let v = self.docSo(tfs[3].text) { bs.phanTramTraCham = v }
                if let v = self.docSo(tfs[4].text) { bs.phanTramBanKem = v }
            }
        })
        hop.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        vc.present(hop, animated: true)
    }

    private func moNhapNhanhNangSuat() {
        guard let vc = timViewControllerCha() else { return }
        let hienTai = KhoDuLieu.dungChung.sucKhoeBoSungNhanVienThang(cho: ngay)[tongHop.nhanVien.maNV] ?? DuLieuSucKhoeBoSungNV()
        let hop = UIAlertController(
            title: "Chỉ số Năng suất — \(tongHop.nhanVien.hoTen)",
            message: "Nhập Điểm thưởng ERP, Điểm thưởng/Giờ công và DTQĐ/Giờ công:",
            preferredStyle: .alert
        )
        hop.addTextField { tf in
            tf.placeholder = "Điểm thưởng ERP (VD: 793585)"
            tf.keyboardType = .decimalPad
            if let v = hienTai.diemThuongERP { tf.text = String(Int(v)) }
        }
        hop.addTextField { tf in
            tf.placeholder = "Điểm thưởng / Giờ công (VD: 12458)"
            tf.keyboardType = .decimalPad
            if let v = hienTai.diemThuongTrenGioCong { tf.text = String(Int(v)) }
        }
        hop.addTextField { tf in
            tf.placeholder = "DTQĐ / Giờ công (VD: 4.94)"
            tf.keyboardType = .decimalPad
            if let v = hienTai.dtqdTrenGioCong { tf.text = String(v) }
        }
        hop.addAction(UIAlertAction(title: "Lưu", style: .default) { [weak self] _ in
            guard let self, let tfs = hop.textFields, tfs.count >= 3 else { return }
            self.luuCapNhatBoSung { bs in
                if let v = self.docSo(tfs[0].text) { bs.diemThuongERP = v }
                if let v = self.docSo(tfs[1].text) { bs.diemThuongTrenGioCong = v }
                if let v = self.docSo(tfs[2].text) { bs.dtqdTrenGioCong = v }
            }
        })
        hop.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        vc.present(hop, animated: true)
    }

    private func moNhapNhanhHieuQua() {
        guard let vc = timViewControllerCha() else { return }
        let hienTai = KhoDuLieu.dungChung.sucKhoeBoSungNhanVienThang(cho: ngay)[tongHop.nhanVien.maNV] ?? DuLieuSucKhoeBoSungNV()
        var cacMuc: [MucChonDMX] = DuLieuSucKhoeBoSungNV.tatCaMucHieuQua.map { muc in
            let vStr = hienTai.hieuQuaKhaiThac[muc.khoa].map { "\(Int(round($0)))%" } ?? "Chưa có"
            return MucChonDMX(tieuDe: "\(muc.nhan): \(vStr)") { [weak self] in
                self?.moHopNhapMotChiSoHieuQua(khoa: muc.khoa, nhan: muc.nhan)
            }
        }
        cacMuc.append(MucChonDMX(tieuDe: "Đóng", kieu: .huy))
        vc.hienMenuChon(tieuDe: "Hiệu quả khai thác (9 nhóm)", cacMuc: cacMuc)
    }

    private func moHopNhapMotChiSoHieuQua(khoa: String, nhan: String) {
        guard let vc = timViewControllerCha() else { return }
        let hienTai = KhoDuLieu.dungChung.sucKhoeBoSungNhanVienThang(cho: ngay)[tongHop.nhanVien.maNV] ?? DuLieuSucKhoeBoSungNV()
        let hop = UIAlertController(title: nhan, message: "Nhập tỷ lệ % khai thác của \(tongHop.nhanVien.hoTen):", preferredStyle: .alert)
        hop.addTextField { tf in
            tf.placeholder = "% đạt được (VD: 27)"
            tf.keyboardType = .decimalPad
            if let v = hienTai.hieuQuaKhaiThac[khoa] { tf.text = String(v) }
        }
        hop.addAction(UIAlertAction(title: "Lưu", style: .default) { [weak self] _ in
            guard let self, let v = self.docSo(hop.textFields?.first?.text) else { return }
            self.luuCapNhatBoSung { bs in bs.hieuQuaKhaiThac[khoa] = v }
        })
        hop.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        vc.present(hop, animated: true)
    }

    private func moChonMucDonGiaDeNhap() {
        guard let vc = timViewControllerCha() else { return }
        let hienTai = KhoDuLieu.dungChung.sucKhoeBoSungNhanVienThang(cho: ngay)[tongHop.nhanVien.maNV] ?? DuLieuSucKhoeBoSungNV()
        var cacMuc: [MucChonDMX] = DuLieuSucKhoeBoSungNV.danhSachMucDonGia.map { muc in
            let vStr = hienTai.donGiaCaNhan[muc.khoa].map { String(format: "%.1f tr", $0) } ?? "—"
            return MucChonDMX(tieuDe: "\(muc.nhan): \(vStr)") { [weak self] in
                self?.moNhapNhanhDonGia(khoa: muc.khoa, nhan: muc.nhan)
            }
        }
        cacMuc.append(MucChonDMX(tieuDe: "Đóng", kieu: .huy))
        vc.hienMenuChon(tieuDe: "Đơn giá sản phẩm (8 nhóm)", cacMuc: cacMuc)
    }

    private func moNhapNhanhDonGia(khoa: String, nhan: String) {
        guard let vc = timViewControllerCha() else { return }
        let hienTai = KhoDuLieu.dungChung.sucKhoeBoSungNhanVienThang(cho: ngay)[tongHop.nhanVien.maNV] ?? DuLieuSucKhoeBoSungNV()
        let hop = UIAlertController(title: "Đơn giá: \(nhan)", message: "Nhập đơn giá cá nhân và TB siêu thị (đơn vị: triệu đồng):", preferredStyle: .alert)
        hop.addTextField { tf in
            tf.placeholder = "Đơn giá cá nhân (VD: 20.9)"
            tf.keyboardType = .decimalPad
            if let v = hienTai.donGiaCaNhan[khoa] { tf.text = String(v) }
        }
        hop.addTextField { tf in
            tf.placeholder = "Đơn giá TB siêu thị (VD: 13.2)"
            tf.keyboardType = .decimalPad
            if let v = hienTai.donGiaTrungBinhST[khoa] { tf.text = String(v) }
        }
        hop.addAction(UIAlertAction(title: "Lưu", style: .default) { [weak self] _ in
            guard let self, let tfs = hop.textFields, tfs.count >= 2 else { return }
            self.luuCapNhatBoSung { bs in
                if let v1 = self.docSo(tfs[0].text) { bs.donGiaCaNhan[khoa] = v1 }
                if let v2 = self.docSo(tfs[1].text) { bs.donGiaTrungBinhST[khoa] = v2 }
            }
        })
        hop.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        vc.present(hop, animated: true)
    }

    private func moSuaMonThiDuaCaNhan(_ mon: MonThiDuaNhanVien) {
        guard let vc = timViewControllerCha() else { return }
        let hop = UIAlertController(
            title: "\(mon.tenNganhHang)",
            message: "Target cá nhân: \(mon.targetCaNhan.chuoiSoVN) (\(mon.loaiChiTieu.maBang)). Nhập số Thực hiện mới cho \(tongHop.nhanVien.hoTen):",
            preferredStyle: .alert
        )
        hop.addTextField { tf in
            tf.placeholder = "Thực hiện"
            tf.keyboardType = .decimalPad
            if mon.thucHien > 0 { tf.text = String(mon.thucHien) }
        }
        hop.addAction(UIAlertAction(title: "Lưu", style: .default) { [weak self] _ in
            guard let self, let val = self.docSo(hop.textFields?.first?.text) else { return }
            var dl = KhoDuLieu.dungChung.duLieu(cho: self.ngay)
            var bangNV = dl.thiDuaNhanVien(theo: self.cheDo)
            bangNV[mon.khoaNganh, default: [:]][self.tongHop.nhanVien.maNV] = val
            dl.ganThiDuaNhanVien(bangNV, theo: self.cheDo)
            KhoDuLieu.dungChung.luu(dl)
            if let capNhatTH = KhoDuLieu.dungChung.tongHopNhanVien(den: self.ngay, sapXep: .tenAZ, cheDo: self.cheDo)
                .first(where: { $0.nhanVien.maNV == self.tongHop.nhanVien.maNV }) {
                self.tongHop = capNhatTH
            }
            self.dungGiaoDien()
            self.khiYeuCauCapNhat?()
        })
        hop.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        vc.present(hop, animated: true)
    }

    static func taoAnhBaoCao(cho tongHop: TongHopNhanVien, ngay: Date, cheDo: LoaiCheDoDoanhThu) -> UIImage? {
        let rongAnh: CGFloat = 820
        let bangView = BangThongSoSucKhoeNhanVienView(
            tongHop: tongHop,
            ngay: ngay,
            cheDo: cheDo,
            laCheDoXuatAnhRong: true
        )
        bangView.overrideUserInterfaceStyle = .light
        bangView.translatesAutoresizingMaskIntoConstraints = false

        let khung = UIView(frame: CGRect(x: 0, y: 0, width: rongAnh, height: 2000))
        khung.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1)
        khung.overrideUserInterfaceStyle = .light
        khung.addSubview(bangView)

        NSLayoutConstraint.activate([
            bangView.topAnchor.constraint(equalTo: khung.topAnchor),
            bangView.leadingAnchor.constraint(equalTo: khung.leadingAnchor),
            bangView.trailingAnchor.constraint(equalTo: khung.trailingAnchor),
            bangView.widthAnchor.constraint(equalToConstant: rongAnh)
        ])

        khung.setNeedsLayout()
        khung.layoutIfNeeded()
        let kichThuoc = bangView.systemLayoutSizeFitting(
            CGSize(width: rongAnh, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        let caoAnh = max(600, ceil(kichThuoc.height))
        khung.frame = CGRect(x: 0, y: 0, width: rongAnh, height: caoAnh)
        bangView.frame = khung.bounds
        khung.setNeedsLayout()
        khung.layoutIfNeeded()

        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2.0
        return UIGraphicsImageRenderer(size: CGSize(width: rongAnh, height: caoAnh), format: fmt).image { ctx in
            khung.layer.render(in: ctx.cgContext)
        }
    }
}

// MARK: - 4. Màn hình Chi tiết Sức khoẻ Cá nhân Nhân viên (Tích hợp Bảng Thông Số Sức Khỏe 27 điểm + Chuyển nhanh NV)

final class ManHinhChiTietNhanVien: UIViewController {
    private var tongHop: TongHopNhanVien
    private let ngay: Date
    private var cheDo: LoaiCheDoDoanhThu

    private let nutChonNV = UIButton(type: .system)
    private let nutNVTruoc = UIButton(type: .system)
    private let nutNVSau = UIButton(type: .system)
    private let chonCheDo = UISegmentedControl(items: ["Lũy kế", "Realtime"])
    private let cuonDoc = UIScrollView()
    private var bangThongSoView: BangThongSoSucKhoeNhanVienView!

    init(_ tongHop: TongHopNhanVien, ngay: Date = Date(), cheDo: LoaiCheDoDoanhThu = .luyKe) {
        self.tongHop = tongHop
        self.ngay = ngay
        self.cheDo = cheDo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        capNhatTieuDe()
        view.backgroundColor = BangMauBCTD.nenTrang
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(bamChiaSeAnhSucKhoe)
        )
        taoGiaoDien()
    }

    private func capNhatTieuDe() {
        title = "Sức khỏe: \(tongHop.nhanVien.hoTen)"
    }

    private func taoGiaoDien() {
        let thanhDieuKhien = UIView()
        thanhDieuKhien.backgroundColor = .white
        thanhDieuKhien.layer.cornerRadius = 12
        thanhDieuKhien.layer.borderWidth = 1
        thanhDieuKhien.layer.borderColor = BangMauBCTD.vienThe.cgColor

        for (nut, icon, action) in [
            (nutNVTruoc, "chevron.left", #selector(bamNVTruoc)),
            (nutNVSau, "chevron.right", #selector(bamNVSau))
        ] {
            nut.setImage(UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)), for: .normal)
            nut.tintColor = BangMauBCTD.xanhChuDaoDam
            nut.backgroundColor = BangMauBCTD.nenThePhu
            nut.layer.cornerRadius = 8
            nut.layer.borderWidth = 1
            nut.layer.borderColor = BangMauBCTD.vienDam.cgColor
            nut.widthAnchor.constraint(equalToConstant: 34).isActive = true
            nut.heightAnchor.constraint(equalToConstant: 34).isActive = true
            nut.addTarget(self, action: action, for: .touchUpInside)
        }

        nutChonNV.titleLabel?.font = .systemFont(ofSize: 13.0, weight: .bold)
        nutChonNV.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
        nutChonNV.backgroundColor = BangMauBCTD.nenThePhu
        nutChonNV.layer.cornerRadius = 8
        nutChonNV.layer.borderWidth = 1
        nutChonNV.layer.borderColor = BangMauBCTD.vienDam.cgColor
        nutChonNV.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        nutChonNV.addTarget(self, action: #selector(bamMoDanhSachChonNV), for: .touchUpInside)

        chonCheDo.selectedSegmentIndex = (cheDo == .realtime) ? 1 : 0
        chonCheDo.selectedSegmentTintColor = BangMauBCTD.xanhChuDao
        chonCheDo.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 11.5, weight: .bold)], for: .selected)
        chonCheDo.setTitleTextAttributes([.foregroundColor: BangMauBCTD.chuPhu, .font: UIFont.systemFont(ofSize: 11.5, weight: .semibold)], for: .normal)
        chonCheDo.addTarget(self, action: #selector(doiCheDo), for: .valueChanged)
        chonCheDo.widthAnchor.constraint(equalToConstant: 132).isActive = true

        let hangTren = UIStackView(arrangedSubviews: [nutNVTruoc, nutChonNV, nutNVSau, chonCheDo])
        hangTren.axis = .horizontal
        hangTren.spacing = 6
        hangTren.alignment = .center
        hangTren.translatesAutoresizingMaskIntoConstraints = false
        thanhDieuKhien.addSubview(hangTren)

        cuonDoc.alwaysBounceVertical = true
        cuonDoc.showsVerticalScrollIndicator = true
        cuonDoc.translatesAutoresizingMaskIntoConstraints = false

        bangThongSoView = BangThongSoSucKhoeNhanVienView(tongHop: tongHop, ngay: ngay, cheDo: cheDo)
        bangThongSoView.translatesAutoresizingMaskIntoConstraints = false
        bangThongSoView.khiYeuCauCapNhat = { [weak self] in
            self?.napLaiDuLieuHienTai()
        }
        cuonDoc.addSubview(bangThongSoView)

        thanhDieuKhien.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(thanhDieuKhien)
        view.addSubview(cuonDoc)

        NSLayoutConstraint.activate([
            thanhDieuKhien.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            thanhDieuKhien.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            thanhDieuKhien.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),

            hangTren.topAnchor.constraint(equalTo: thanhDieuKhien.topAnchor, constant: 6),
            hangTren.bottomAnchor.constraint(equalTo: thanhDieuKhien.bottomAnchor, constant: -6),
            hangTren.leadingAnchor.constraint(equalTo: thanhDieuKhien.leadingAnchor, constant: 8),
            hangTren.trailingAnchor.constraint(equalTo: thanhDieuKhien.trailingAnchor, constant: -8),

            cuonDoc.topAnchor.constraint(equalTo: thanhDieuKhien.bottomAnchor, constant: 4),
            cuonDoc.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cuonDoc.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cuonDoc.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            bangThongSoView.topAnchor.constraint(equalTo: cuonDoc.contentLayoutGuide.topAnchor),
            bangThongSoView.leadingAnchor.constraint(equalTo: cuonDoc.contentLayoutGuide.leadingAnchor),
            bangThongSoView.trailingAnchor.constraint(equalTo: cuonDoc.contentLayoutGuide.trailingAnchor),
            bangThongSoView.bottomAnchor.constraint(equalTo: cuonDoc.contentLayoutGuide.bottomAnchor),
            bangThongSoView.widthAnchor.constraint(equalTo: cuonDoc.frameLayoutGuide.widthAnchor)
        ])

        capNhatNutChonNV()
    }

    private func danhSachNVHienTai() -> [TongHopNhanVien] {
        KhoDuLieu.dungChung.tongHopNhanVien(den: ngay, sapXep: .doanhThuQD, cheDo: cheDo)
    }

    private func capNhatNutChonNV() {
        let ds = danhSachNVHienTai()
        let idx = ds.firstIndex(where: { $0.nhanVien.maNV == tongHop.nhanVien.maNV }) ?? 0
        nutChonNV.setTitle("👤 \(idx + 1)/\(max(1, ds.count)). \(tongHop.nhanVien.hoTen) ▾", for: .normal)
        capNhatTieuDe()
    }

    private func napLaiDuLieuHienTai() {
        let ds = danhSachNVHienTai()
        if let moi = ds.first(where: { $0.nhanVien.maNV == tongHop.nhanVien.maNV }) ?? ds.first {
            tongHop = moi
        }
        capNhatNutChonNV()
        bangThongSoView.capNhat(tongHop: tongHop, ngay: ngay, cheDo: cheDo)
    }

    @objc private func doiCheDo() {
        cheDo = (chonCheDo.selectedSegmentIndex == 1) ? .realtime : .luyKe
        napLaiDuLieuHienTai()
    }

    @objc private func bamNVTruoc() {
        let ds = danhSachNVHienTai()
        guard !ds.isEmpty else { return }
        let idx = ds.firstIndex(where: { $0.nhanVien.maNV == tongHop.nhanVien.maNV }) ?? 0
        let moiIdx = (idx - 1 + ds.count) % ds.count
        tongHop = ds[moiIdx]
        capNhatNutChonNV()
        bangThongSoView.capNhat(tongHop: tongHop, ngay: ngay, cheDo: cheDo)
    }

    @objc private func bamNVSau() {
        let ds = danhSachNVHienTai()
        guard !ds.isEmpty else { return }
        let idx = ds.firstIndex(where: { $0.nhanVien.maNV == tongHop.nhanVien.maNV }) ?? 0
        let moiIdx = (idx + 1) % ds.count
        tongHop = ds[moiIdx]
        capNhatNutChonNV()
        bangThongSoView.capNhat(tongHop: tongHop, ngay: ngay, cheDo: cheDo)
    }

    @objc private func bamMoDanhSachChonNV() {
        let ds = danhSachNVHienTai()
        guard !ds.isEmpty else { return }
        var cacMuc: [MucChonDMX] = ds.enumerated().map { i, item in
            let dtStr = item.doanhThuQD > 0 ? "\(item.doanhThuQD.chuoiSoGonVN) tr" : "--"
            return MucChonDMX(
                tieuDe: "\(i + 1). \(item.nhanVien.hoTen) (id: \(item.nhanVien.maNV)) • DT QĐ: \(dtStr)",
                dangChon: item.nhanVien.maNV == tongHop.nhanVien.maNV
            ) { [weak self] in
                guard let self else { return }
                self.tongHop = item
                self.capNhatNutChonNV()
                self.bangThongSoView.capNhat(tongHop: item, ngay: self.ngay, cheDo: self.cheDo)
            }
        }
        cacMuc.append(MucChonDMX(tieuDe: "Đóng", kieu: .huy))
        hienMenuChon(tieuDe: "Chọn nhân viên xem Sức khỏe", cacMuc: cacMuc)
    }

    // MARK: - Xuất / Chia sẻ ảnh Sức khoẻ chi tiết

    @objc private func bamChiaSeAnhSucKhoe() {
        let dsNV = KhoDuLieu.dungChung.tongHopNhanVien(den: ngay, sapXep: .tenAZ, cheDo: cheDo)

        var cacMuc: [MucChonDMX] = [
            MucChonDMX(tieuDe: "👤 Xuất 1 nhân viên này (\(tongHop.nhanVien.hoTen))") { [weak self] in
                guard let self = self, let anh = self.taoAnhSucKhoeNhanVien() else { return }
                self.hienChiaSe([anh])
            }
        ]

        if !dsNV.isEmpty {
            cacMuc.append(MucChonDMX(tieuDe: "📚 Xuất TẤT CẢ \(dsNV.count) NV đang quản lý (Bộ \(dsNV.count) ảnh rời)") { [weak self] in
                guard let self = self else { return }
                let cacAnh = Self.taoTatCaAnhSucKhoe(cho: self.ngay, cheDo: self.cheDo)
                guard !cacAnh.isEmpty else { return }
                self.hienChiaSe(cacAnh)
            })
            cacMuc.append(MucChonDMX(tieuDe: "🖼️ Xuất TẤT CẢ \(dsNV.count) NV đang quản lý (Gộp 1 ảnh tổng hợp)") { [weak self] in
                guard let self = self, let anhGop = Self.taoAnhGopTatCaSucKhoe(cho: self.ngay, cheDo: self.cheDo) else { return }
                self.hienChiaSe([anhGop])
            })
        }
        cacMuc.append(MucChonDMX(tieuDe: "Đóng", kieu: .huy))

        hienMenuChon(
            tieuDe: "Xuất ảnh Sức khoẻ Nhân viên (\(cheDo.tieuDe))",
            thongDiep: "Chọn xuất riêng nhân viên đang xem hoặc xuất tất cả \(dsNV.count) nhân viên đang quản lý:",
            cacMuc: cacMuc
        )
    }

    private func hienChiaSe(_ muc: [Any]) {
        let vc = UIActivityViewController(activityItems: muc, applicationActivities: nil)
        if let pop = vc.popoverPresentationController {
            pop.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(vc, animated: true)
    }

    static func taoAnhSucKhoe(cho tongHop: TongHopNhanVien, ngay: Date, cheDo: LoaiCheDoDoanhThu = .luyKe) -> UIImage? {
        BangThongSoSucKhoeNhanVienView.taoAnhBaoCao(cho: tongHop, ngay: ngay, cheDo: cheDo)
    }

    static func taoTatCaAnhSucKhoe(cho ngay: Date, cheDo: LoaiCheDoDoanhThu = .luyKe) -> [UIImage] {
        let dsNV = KhoDuLieu.dungChung.tongHopNhanVien(den: ngay, sapXep: .tenAZ, cheDo: cheDo)
        return dsNV.compactMap { taoAnhSucKhoe(cho: $0, ngay: ngay, cheDo: cheDo) }
    }

    static func taoAnhGopTatCaSucKhoe(cho ngay: Date, cheDo: LoaiCheDoDoanhThu = .luyKe) -> UIImage? {
        let cacAnh = taoTatCaAnhSucKhoe(cho: ngay, cheDo: cheDo)
        guard !cacAnh.isEmpty else { return nil }
        if cacAnh.count == 1 { return cacAnh[0] }

        let khoangCach: CGFloat = 18
        let rong = cacAnh.map { $0.size.width }.max() ?? 820
        let tongCao = cacAnh.reduce(CGFloat(0)) { $0 + $1.size.height } + CGFloat(cacAnh.count - 1) * khoangCach

        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2.0
        return UIGraphicsImageRenderer(size: CGSize(width: rong, height: tongCao), format: fmt).image { ctx in
            UIColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: rong, height: tongCao))
            var y: CGFloat = 0
            for anh in cacAnh {
                anh.draw(in: CGRect(x: (rong - anh.size.width) / 2, y: y, width: anh.size.width, height: anh.size.height))
                y += anh.size.height + khoangCach
            }
        }
    }

    func taoAnhSucKhoeNhanVien() -> UIImage? {
        BangThongSoSucKhoeNhanVienView.taoAnhBaoCao(cho: tongHop, ngay: ngay, cheDo: cheDo)
    }
}
