import UIKit

/// Màn hình Bản tin & Phân tích: 3 khung (Đầu ca / Hiện tại / Kết ca) + 3 giọng văn.
/// Không tự gửi: người dùng bấm "Gửi LINE" → LINE mở ra, tự chọn nhóm / người nhận.
final class ManHinhBanTin: UIViewController, UITextViewDelegate {

    private let ngay: Date
    private let taoAnhBang: (KhungBanTin, SoLieuBanTin) -> [UIImage]

    private var khungDangChon: KhungBanTin = KhungBanTin.theoGio()
    private var giongDangChon: GiongVanBanTin = .binhThuong
    private var soLieu: SoLieuBanTin?
    private var bienThe = 0

    private let cuon = UIScrollView()
    private let ngan = UIStackView()
    private let chonKhung = UISegmentedControl(items: KhungBanTin.allCases.map { $0.tieuDe })
    private let chonGiong = UISegmentedControl(items: GiongVanBanTin.allCases.map { $0.tieuDe })
    private let nhanTrangThai = UILabel()
    private let oVanBan = UITextView()

    init(ngay: Date, taoAnhBang: @escaping (KhungBanTin, SoLieuBanTin) -> [UIImage]) {
        self.ngay = ngay
        self.taoAnhBang = taoAnhBang
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) chưa được hỗ trợ")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bản tin & Phân tích"
        view.backgroundColor = BangMauBCTD.nenTrang
        dungGiaoDien()
        napBanTin(taoMoi: false)
    }

    // MARK: Giao diện

    private func dungGiaoDien() {
        cuon.translatesAutoresizingMaskIntoConstraints = false
        cuon.keyboardDismissMode = .interactive
        cuon.alwaysBounceVertical = true
        view.addSubview(cuon)

        ngan.axis = .vertical
        ngan.spacing = 10
        ngan.translatesAutoresizingMaskIntoConstraints = false
        cuon.addSubview(ngan)

        NSLayoutConstraint.activate([
            cuon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cuon.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cuon.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cuon.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ngan.topAnchor.constraint(equalTo: cuon.contentLayoutGuide.topAnchor, constant: 10),
            ngan.leadingAnchor.constraint(equalTo: cuon.frameLayoutGuide.leadingAnchor, constant: 12),
            ngan.trailingAnchor.constraint(equalTo: cuon.frameLayoutGuide.trailingAnchor, constant: -12),
            ngan.bottomAnchor.constraint(equalTo: cuon.contentLayoutGuide.bottomAnchor, constant: -24)
        ])

        let theDau = UIView()
        theDau.backgroundColor = BangMauBCTD.nenMenuToi
        theDau.layer.cornerRadius = 12
        theDau.layer.borderWidth = 1
        theDau.layer.borderColor = BangMauBCTD.vangChuDao.withAlphaComponent(0.38).cgColor

        let lbKicker = UILabel()
        lbKicker.text = "CHỌN KHUNG BẢN TIN & GIỌNG VĂN PHÂN TÍCH"
        lbKicker.font = .systemFont(ofSize: 11.5, weight: .heavy)
        lbKicker.textColor = BangMauBCTD.vangChuDao
        lbKicker.numberOfLines = 0
        lbKicker.lineBreakMode = .byWordWrapping
        lbKicker.adjustsFontSizeToFitWidth = false

        [chonKhung, chonGiong].forEach { seg in
            seg.backgroundColor = BangMauBCTD.nenMenuCon
            seg.selectedSegmentTintColor = BangMauBCTD.nenDongChonMenu
            seg.setTitleTextAttributes([
                .font: UIFont.systemFont(ofSize: 12.0, weight: .semibold),
                .foregroundColor: BangMauBCTD.chuTrenNenToi
            ], for: .normal)
            seg.setTitleTextAttributes([
                .font: UIFont.systemFont(ofSize: 12.0, weight: .bold),
                .foregroundColor: BangMauBCTD.vangChuDao
            ], for: .selected)
            seg.damBaoHienThiDayDuText()
        }

        chonKhung.selectedSegmentIndex = khungDangChon.rawValue
        chonKhung.addTarget(self, action: #selector(doiKhung), for: .valueChanged)

        let nhanGiong = UILabel()
        nhanGiong.text = "Giọng văn bài phân tích:"
        nhanGiong.font = .systemFont(ofSize: 12.0, weight: .semibold)
        nhanGiong.textColor = BangMauBCTD.chuTrenNenToi
        nhanGiong.numberOfLines = 0
        nhanGiong.lineBreakMode = .byWordWrapping
        nhanGiong.adjustsFontSizeToFitWidth = false

        chonGiong.selectedSegmentIndex = giongDangChon.rawValue
        chonGiong.addTarget(self, action: #selector(doiGiong), for: .valueChanged)

        nhanTrangThai.numberOfLines = 0
        nhanTrangThai.lineBreakMode = .byWordWrapping
        nhanTrangThai.adjustsFontSizeToFitWidth = false
        nhanTrangThai.font = .systemFont(ofSize: 12.5, weight: .semibold)

        let nganDau = UIStackView(arrangedSubviews: [lbKicker, chonKhung, nhanGiong, chonGiong, nhanTrangThai])
        nganDau.axis = .vertical
        nganDau.spacing = 8
        nganDau.translatesAutoresizingMaskIntoConstraints = false
        theDau.addSubview(nganDau)

        NSLayoutConstraint.activate([
            nganDau.topAnchor.constraint(equalTo: theDau.topAnchor, constant: 12),
            nganDau.leadingAnchor.constraint(equalTo: theDau.leadingAnchor, constant: 12),
            nganDau.trailingAnchor.constraint(equalTo: theDau.trailingAnchor, constant: -12),
            nganDau.bottomAnchor.constraint(equalTo: theDau.bottomAnchor, constant: -12)
        ])
        ngan.addArrangedSubview(theDau)

        oVanBan.font = .systemFont(ofSize: 15)
        oVanBan.textColor = BangMauBCTD.chuChinh
        oVanBan.backgroundColor = BangMauBCTD.nenThe
        oVanBan.layer.cornerRadius = 12
        oVanBan.layer.borderWidth = 1
        oVanBan.layer.borderColor = BangMauBCTD.vienDam.cgColor
        oVanBan.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        oVanBan.isScrollEnabled = false
        oVanBan.delegate = self
        oVanBan.translatesAutoresizingMaskIntoConstraints = false
        oVanBan.heightAnchor.constraint(greaterThanOrEqualToConstant: 360).isActive = true
        ngan.addArrangedSubview(oVanBan)

        ngan.addArrangedSubview(taoNut("💬 Gửi vào LINE (chọn nhóm)", mau: BangMauBCTD.xanhDatVach, action: #selector(bamGuiLine)))
        ngan.addArrangedSubview(taoNut("🖼 Chia sẻ ảnh bảng số của khung này", mau: BangMauBCTD.nenMenuToi, action: #selector(bamChiaSeAnhBang)))
        ngan.addArrangedSubview(taoNut("📝 Chia sẻ ảnh bản tin (chữ phân tích)", mau: BangMauBCTD.indigoChuDao, action: #selector(bamChiaSeAnhChu)))
        ngan.addArrangedSubview(taoNut("🔄 Phân tích lại (viết bài mới)", mau: BangMauBCTD.vangKhaVach, action: #selector(bamPhanTichLai)))
        ngan.addArrangedSubview(taoNut("📋 Sao chép nội dung", mau: BangMauBCTD.chuPhu, action: #selector(bamSaoChep)))
    }

    private func taoNut(_ tieuDe: String, mau: UIColor, action: Selector) -> UIButton {
        let nut = UIButton(type: .system)
        nut.setTitle(tieuDe, for: .normal)
        nut.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        nut.titleLabel?.numberOfLines = 0
        nut.titleLabel?.lineBreakMode = .byWordWrapping
        nut.titleLabel?.textAlignment = .center
        nut.titleLabel?.adjustsFontSizeToFitWidth = false
        nut.backgroundColor = mau
        nut.tintColor = .white
        nut.setTitleColor(.white, for: .normal)
        nut.layer.cornerRadius = 12
        nut.contentEdgeInsets = UIEdgeInsets(top: 13, left: 14, bottom: 13, right: 14)
        nut.addTarget(self, action: action, for: .touchUpInside)
        return nut
    }

    // MARK: Nạp & lưu bài

    private func khoaLuu() -> String {
        "bantin.\(TienIchNgay.khoa.string(from: ngay)).\(khungDangChon.rawValue).\(giongDangChon.rawValue)"
    }

    /// taoMoi = true: bỏ bài đã lưu / đã sửa, viết bài mới
    private func napBanTin(taoMoi: Bool) {
        let s = KhoDuLieu.dungChung.taoSoLieuBanTin(cho: ngay, khung: khungDangChon)
        soLieu = s

        var thongBao: [String] = []
        if s.tamTinh {
            thongBao.append("⏳ Đầu ca TẠM TÍNH: lũy kế hôm qua + kết ca tối qua. Nhập ảnh Đầu ca hôm nay để có số thật.")
        }
        switch khungDangChon {
        case .dauCa:
            if !s.coSoLieuLuyKe { thongBao.append("⚠ Chưa có số Lũy kế.") }
        case .hienTai, .ketCa:
            if !s.coSoLieuHomNay { thongBao.append("⚠ Chưa có số Realtime hôm nay.") }
        }
        if s.nhanVien.isEmpty {
            thongBao.append("ℹ️ Chưa có danh sách nhân viên (Công cụ → Quản lý nhân viên) nên chưa có phần nhắc nhở / tập trung.")
        }
        nhanTrangThai.text = thongBao.isEmpty ? "✅ Đủ số liệu cho khung \(khungDangChon.tenNgan)." : thongBao.joined(separator: "\n")
        nhanTrangThai.textColor = thongBao.contains(where: { $0.hasPrefix("⚠") }) ? BangMauBCTD.vangChuDao : BangMauBCTD.chuTrenNenToi

        if !taoMoi, let daLuu = UserDefaults.standard.string(forKey: khoaLuu()), !daLuu.isEmpty {
            oVanBan.text = daLuu
        } else {
            UserDefaults.standard.removeObject(forKey: khoaLuu())
            oVanBan.text = BoVietBanTin(soLieu: s, giong: giongDangChon, bienThe: bienThe).viet()
        }
        oVanBan.invalidateIntrinsicContentSize()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        UserDefaults.standard.set(textView.text ?? "", forKey: khoaLuu())
    }

    // MARK: Hành động

    @objc private func doiKhung() {
        khungDangChon = KhungBanTin(rawValue: chonKhung.selectedSegmentIndex) ?? .dauCa
        bienThe = 0
        napBanTin(taoMoi: false)
    }

    @objc private func doiGiong() {
        giongDangChon = GiongVanBanTin(rawValue: chonGiong.selectedSegmentIndex) ?? .binhThuong
        bienThe = 0
        napBanTin(taoMoi: false)
    }

    @objc private func bamPhanTichLai() {
        view.endEditing(true)
        bienThe += 1
        napBanTin(taoMoi: true)
    }

    @objc private func bamSaoChep() {
        view.endEditing(true)
        UIPasteboard.general.string = oVanBan.text
        nhanTrangThai.text = "📋 Đã sao chép nội dung."
        nhanTrangThai.textColor = .systemGreen
    }

    /// Mở LINE với nội dung đã soạn → LINE tự hiện màn chọn nhóm / bạn bè. Không có LINE hoặc nội dung quá dài → mở menu chia sẻ.
    @objc private func bamGuiLine() {
        view.endEditing(true)
        let noiDung = oVanBan.text ?? ""
        UserDefaults.standard.set(noiDung, forKey: khoaLuu())
        guard let ma = noiDung.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
              noiDung.count <= 1800,
              let url = URL(string: "line://msg/text/" + ma) else {
            chiaSe([noiDung])
            return
        }
        UIApplication.shared.open(url, options: [:]) { [weak self] thanhCong in
            if !thanhCong {
                self?.chiaSe([noiDung])
            }
        }
    }

    @objc private func bamChiaSeAnhBang() {
        view.endEditing(true)
        guard let s = soLieu else { return }
        let cacAnh = taoAnhBang(khungDangChon, s)
        if cacAnh.isEmpty {
            nhanTrangThai.text = "⚠ Chưa có bảng số cho khung này để tạo ảnh."
            nhanTrangThai.textColor = .systemRed
            return
        }
        chiaSe(cacAnh)
    }

    @objc private func bamChiaSeAnhChu() {
        view.endEditing(true)
        let tieuDe = "BẢN TIN \(khungDangChon.tenNgan) · \(TienIchNgay.hienThiNgay.string(from: ngay))"
        let anh = ManHinhBanTin.veAnhVanBan(oVanBan.text ?? "", tieuDe: tieuDe)
        chiaSe([anh])
    }

    private func chiaSe(_ muc: [Any]) {
        let vc = UIActivityViewController(activityItems: muc, applicationActivities: nil)
        if let pop = vc.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(vc, animated: true)
    }

    // MARK: Vẽ ảnh bản tin từ chữ (tự xuống dòng, không cắt chữ)

    static func veAnhVanBan(_ chu: String, tieuDe: String) -> UIImage {
        let rong: CGFloat = 900
        let le: CGFloat = 36
        let rongChu = rong - le * 2
        let kieuChu = NSMutableParagraphStyle()
        kieuChu.lineBreakMode = .byWordWrapping
        kieuChu.lineSpacing = 5
        let thuocTinhThan: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 26, weight: .regular),
            .foregroundColor: UIColor(white: 0.1, alpha: 1),
            .paragraphStyle: kieuChu
        ]
        let thuocTinhTieuDe: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .heavy),
            .foregroundColor: UIColor.white,
            .paragraphStyle: kieuChu
        ]
        let than = NSAttributedString(string: chu, attributes: thuocTinhThan)
        let td = NSAttributedString(string: tieuDe, attributes: thuocTinhTieuDe)
        let khungToiDa = CGSize(width: rongChu, height: CGFloat.greatestFiniteMagnitude)
        let caoThan = ceil(than.boundingRect(with: khungToiDa, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height)
        let caoTieuDe = ceil(td.boundingRect(with: khungToiDa, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height)
        let caoBang = caoTieuDe + 40
        let tong = caoBang + caoThan + le * 2

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: rong, height: tong))
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: rong, height: tong))
            BangMauBCTD.nenHeaderBang.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: rong, height: caoBang))
            BangMauBCTD.vangChuDao.setFill()
            ctx.fill(CGRect(x: 0, y: caoBang - 6, width: rong, height: 6))
            td.draw(with: CGRect(x: le, y: 18, width: rongChu, height: caoTieuDe), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            than.draw(with: CGRect(x: le, y: caoBang + le, width: rongChu, height: caoThan), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        }
    }
}
