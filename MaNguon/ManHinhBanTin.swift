import UIKit

/// Màn hình Báo cáo & Phân tích AI (Nằm ngay dưới Tổng quan trong Menu và có thể mở độc lập).
/// Thiết kế khớp chuẩn ảnh mẫu đính kèm + Bổ sung ô nhập Yêu cầu riêng của người dùng khi viết báo cáo & xuất file Excel/PowerPoint:
/// - PHÂN TÍCH (viết sẵn — sửa được) + nút [✨ AI Gemini] + [Phân tích lại]
/// - Ô văn bản đánh số 1) 2) 3) 4) 5) có định dạng in đậm trực quan
/// - Khung 💬 YÊU CẦU RIÊNG CỦA NGƯỜI DÙNG (CHO AI GEMINI & XUẤT FILE EXCEL/PPTX) kèm các nút gợi ý nhanh
/// - Khung 📌 TẬP TRUNG BÀI VIẾT: ↺ Bỏ chọn hết, Giọng văn (Bình thường màu vàng sáng #FACC15 / Căng thẳng / Thảo mai),
///   chọn Nhóm hàng tập trung & Nhân viên tập trung
/// - Các nút Gửi LINE & Copy nội dung, Xuất ảnh báo cáo, Xuất Excel (.xlsx) 7 Sheet & PowerPoint (.pptx) 6 Slide bằng AI Gemini
final class ManHinhBanTin: UIViewController, UITextViewDelegate {

    private var ngay: Date
    private let taoAnhBang: (KhungBanTin, SoLieuBanTin) -> [UIImage]

    private var khungDangChon: KhungBanTin = KhungBanTin.theoGio()
    private var giongDangChon: GiongVanBanTin = .binhThuong
    private var soLieu: SoLieuBanTin?
    private var bienThe = 0

    private var nhomTapTrung: Set<String> = []
    private var nvTapTrung: Set<String> = []

    private let cuon = UIScrollView()
    private let ngan = UIStackView()

    // Dòng trạng thái trên cùng
    private let nhanTrangThaiTren = UILabel()

    // Khung thẻ PHÂN TÍCH chính
    private let thePhanTich = UIView()
    private let nhanTieuDePhanTich = UILabel()
    private let nutAIGemini = UIButton(type: .system)
    private let nutPhanTichLai = UIButton(type: .system)
    private let oVanBan = UITextView()

    // Ô nhập yêu cầu riêng của người dùng khi phân tích AI & xuất file Excel / PowerPoint
    private let oYeuCauRieng = UITextView()
    private let nhanGoiYYeuCau = UILabel()
    private var nutXuatExcelAI: UIButton!
    private var nutXuatPowerPointAI: UIButton!

    // Khung 📌 TẬP TRUNG BÀI VIẾT
    private let nhanTapTrung = UILabel()
    private let nutBoChonHet = UIButton(type: .system)
    private var cacNutGiongVan: [UIButton] = []
    private let nganChipNhomHang = UIStackView()
    private let nganChipNhanVien = UIStackView()

    init(ngay: Date, taoAnhBang: @escaping (KhungBanTin, SoLieuBanTin) -> [UIImage]) {
        self.ngay = ngay
        self.taoAnhBang = taoAnhBang
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) chưa được hỗ trợ")
    }

    func capNhatNgay(_ ngayMoi: Date) {
        self.ngay = ngayMoi
        guard isViewLoaded else { return }
        napBanTin(taoMoi: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Báo cáo & Phân tích AI"
        view.backgroundColor = BangMauBCTD.nenTrang
        dungGiaoDien()
        napBanTin(taoMoi: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let ycLuu = DichVuGeminiAI.dungChung.yeuCauTuyChinhHienTai
        if (oYeuCauRieng.text ?? "") != ycLuu {
            oYeuCauRieng.text = ycLuu
            capNhatTrangThaiPlaceholderYeuCau()
        }
    }

    // MARK: - Dựng giao diện chuẩn mẫu ảnh đính kèm + Ô nhập yêu cầu người dùng

    private func dungGiaoDien() {
        cuon.translatesAutoresizingMaskIntoConstraints = false
        cuon.keyboardDismissMode = .interactive
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

            ngan.topAnchor.constraint(equalTo: cuon.contentLayoutGuide.topAnchor, constant: 8),
            ngan.leadingAnchor.constraint(equalTo: cuon.frameLayoutGuide.leadingAnchor, constant: 12),
            ngan.trailingAnchor.constraint(equalTo: cuon.frameLayoutGuide.trailingAnchor, constant: -12),
            ngan.bottomAnchor.constraint(equalTo: cuon.contentLayoutGuide.bottomAnchor, constant: -28)
        ])

        // 1. Dòng trạng thái phía trên thẻ
        nhanTrangThaiTren.text = "Bản tin đã lưu trên máy · bấm Phân tích lại hoặc ✨ AI Gemini nếu vừa đổi số"
        nhanTrangThaiTren.font = .systemFont(ofSize: 13.5, weight: .medium)
        nhanTrangThaiTren.textColor = BangMauBCTD.chuPhu
        nhanTrangThaiTren.numberOfLines = 0
        nhanTrangThaiTren.lineBreakMode = .byWordWrapping
        nhanTrangThaiTren.adjustsFontSizeToFitWidth = false
        ngan.addArrangedSubview(nhanTrangThaiTren)

        // 2. Thẻ PHÂN TÍCH (viết sẵn — sửa được)
        thePhanTich.backgroundColor = BangMauBCTD.nenThe
        thePhanTich.layer.cornerRadius = 16
        thePhanTich.layer.borderWidth = 1
        thePhanTich.layer.borderColor = BangMauBCTD.vienThe.cgColor
        thePhanTich.translatesAutoresizingMaskIntoConstraints = false

        let nganTrongThe = UIStackView()
        nganTrongThe.axis = .vertical
        nganTrongThe.spacing = 10
        nganTrongThe.translatesAutoresizingMaskIntoConstraints = false
        thePhanTich.addSubview(nganTrongThe)

        NSLayoutConstraint.activate([
            nganTrongThe.topAnchor.constraint(equalTo: thePhanTich.topAnchor, constant: 14),
            nganTrongThe.leadingAnchor.constraint(equalTo: thePhanTich.leadingAnchor, constant: 14),
            nganTrongThe.trailingAnchor.constraint(equalTo: thePhanTich.trailingAnchor, constant: -14),
            nganTrongThe.bottomAnchor.constraint(equalTo: thePhanTich.bottomAnchor, constant: -14)
        ])

        // Hàng tiêu đề: PHÂN TÍCH (viết sẵn — sửa được) bên trái + [✨ AI Gemini] [Phân tích lại] bên phải
        nhanTieuDePhanTich.text = "PHÂN TÍCH (viết sẵn — sửa được)"
        nhanTieuDePhanTich.font = .systemFont(ofSize: 13.5, weight: .heavy)
        nhanTieuDePhanTich.textColor = BangMauBCTD.mauChuTieuDePhanTich
        nhanTieuDePhanTich.numberOfLines = 0
        nhanTieuDePhanTich.lineBreakMode = .byWordWrapping
        nhanTieuDePhanTich.adjustsFontSizeToFitWidth = false

        nutAIGemini.setTitle("✨ AI Gemini", for: .normal)
        nutAIGemini.titleLabel?.font = .systemFont(ofSize: 13.0, weight: .bold)
        nutAIGemini.titleLabel?.numberOfLines = 0
        nutAIGemini.titleLabel?.lineBreakMode = .byWordWrapping
        nutAIGemini.titleLabel?.adjustsFontSizeToFitWidth = false
        nutAIGemini.backgroundColor = BangMauBCTD.nenHeaderBang
        nutAIGemini.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
        nutAIGemini.layer.cornerRadius = 9
        nutAIGemini.layer.borderWidth = 1
        nutAIGemini.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
        nutAIGemini.contentEdgeInsets = UIEdgeInsets(top: 7, left: 10, bottom: 7, right: 10)
        nutAIGemini.setContentHuggingPriority(.required, for: .horizontal)
        nutAIGemini.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutAIGemini.addTarget(self, action: #selector(bamPhanTichAIGemini), for: .touchUpInside)

        nutPhanTichLai.setTitle("Phân tích lại", for: .normal)
        nutPhanTichLai.titleLabel?.font = .systemFont(ofSize: 13.5, weight: .semibold)
        nutPhanTichLai.titleLabel?.numberOfLines = 0
        nutPhanTichLai.titleLabel?.lineBreakMode = .byWordWrapping
        nutPhanTichLai.titleLabel?.adjustsFontSizeToFitWidth = false
        nutPhanTichLai.backgroundColor = BangMauBCTD.nenThePhu
        nutPhanTichLai.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
        nutPhanTichLai.layer.cornerRadius = 9
        nutPhanTichLai.layer.borderWidth = 1
        nutPhanTichLai.layer.borderColor = BangMauBCTD.vienDam.cgColor
        nutPhanTichLai.contentEdgeInsets = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12)
        nutPhanTichLai.setContentHuggingPriority(.required, for: .horizontal)
        nutPhanTichLai.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutPhanTichLai.addTarget(self, action: #selector(bamPhanTichLai), for: .touchUpInside)

        let hangNutTrenPhai = UIStackView(arrangedSubviews: [nutAIGemini, nutPhanTichLai])
        hangNutTrenPhai.axis = .horizontal
        hangNutTrenPhai.spacing = 6
        hangNutTrenPhai.alignment = .center

        let hangTieuDeThe = UIStackView(arrangedSubviews: [nhanTieuDePhanTich, hangNutTrenPhai])
        hangTieuDeThe.axis = .horizontal
        hangTieuDeThe.spacing = 8
        hangTieuDeThe.alignment = .center
        nganTrongThe.addArrangedSubview(hangTieuDeThe)

        // Ô soạn thảo văn bản báo cáo
        oVanBan.font = .systemFont(ofSize: 15.5, weight: .regular)
        oVanBan.textColor = BangMauBCTD.chuChinh
        oVanBan.backgroundColor = BangMauBCTD.nenThe
        oVanBan.layer.cornerRadius = 12
        oVanBan.layer.borderWidth = 1
        oVanBan.layer.borderColor = BangMauBCTD.vienDam.cgColor
        oVanBan.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        oVanBan.isScrollEnabled = false
        oVanBan.delegate = self
        oVanBan.translatesAutoresizingMaskIntoConstraints = false
        oVanBan.heightAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true
        nganTrongThe.addArrangedSubview(oVanBan)

        // KHUNG MỚI: 💬 YÊU CẦU RIÊNG CỦA NGƯỜI DÙNG (CHO AI GEMINI & XUẤT EXCEL / POWERPOINT)
        let khungYeuCau = taoKhungYeuCauNguoiDung()
        nganTrongThe.addArrangedSubview(khungYeuCau)

        // Khung 📌 TẬP TRUNG BÀI VIẾT
        let hangTieuDeTapTrung = UIStackView()
        hangTieuDeTapTrung.axis = .horizontal
        hangTieuDeTapTrung.alignment = .center
        hangTieuDeTapTrung.distribution = .equalSpacing

        nhanTapTrung.text = "📌 TẬP TRUNG BÀI VIẾT"
        nhanTapTrung.font = .systemFont(ofSize: 13.0, weight: .heavy)
        nhanTapTrung.textColor = BangMauBCTD.mauChuTieuDePhanTich
        nhanTapTrung.numberOfLines = 0
        nhanTapTrung.lineBreakMode = .byWordWrapping
        nhanTapTrung.adjustsFontSizeToFitWidth = false

        nutBoChonHet.setTitle("↺ Bỏ chọn hết", for: .normal)
        nutBoChonHet.titleLabel?.font = .systemFont(ofSize: 13.0, weight: .semibold)
        nutBoChonHet.titleLabel?.numberOfLines = 0
        nutBoChonHet.titleLabel?.lineBreakMode = .byWordWrapping
        nutBoChonHet.titleLabel?.adjustsFontSizeToFitWidth = false
        nutBoChonHet.setTitleColor(BangMauBCTD.chuPhu, for: .normal)
        nutBoChonHet.addTarget(self, action: #selector(bamBoChonHet), for: .touchUpInside)

        hangTieuDeTapTrung.addArrangedSubview(nhanTapTrung)
        hangTieuDeTapTrung.addArrangedSubview(nutBoChonHet)
        nganTrongThe.addArrangedSubview(hangTieuDeTapTrung)

        // Chọn Giọng văn
        let nhanGiong = taoNhanMucNho("Giọng văn")
        nganTrongThe.addArrangedSubview(nhanGiong)

        let hangGiong = UIStackView()
        hangGiong.axis = .horizontal
        hangGiong.spacing = 8
        hangGiong.distribution = .fillProportionally
        cacNutGiongVan.removeAll()
        for giong in GiongVanBanTin.allCases {
            let nut = UIButton(type: .custom)
            nut.tag = giong.rawValue
            nut.setTitle(giong.tieuDe, for: .normal)
            nut.titleLabel?.font = .systemFont(ofSize: 14.0, weight: .bold)
            nut.titleLabel?.numberOfLines = 0
            nut.titleLabel?.lineBreakMode = .byWordWrapping
            nut.titleLabel?.textAlignment = .center
            nut.titleLabel?.adjustsFontSizeToFitWidth = false
            nut.layer.cornerRadius = 10
            nut.layer.borderWidth = 1
            nut.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
            nut.addTarget(self, action: #selector(bamChonGiongVan(_:)), for: .touchUpInside)
            cacNutGiongVan.append(nut)
            hangGiong.addArrangedSubview(nut)
        }
        nganTrongThe.addArrangedSubview(hangGiong)

        // Chọn Nhóm hàng tập trung
        let nhanNhomHang = taoNhanMucNho("Nhóm hàng (bấm để chọn/bỏ nhóm cần nhắc trong bài)")
        nganTrongThe.addArrangedSubview(nhanNhomHang)

        nganChipNhomHang.axis = .vertical
        nganChipNhomHang.spacing = 6
        nganTrongThe.addArrangedSubview(nganChipNhomHang)

        // Chọn Nhân viên tập trung
        let nhanNV = taoNhanMucNho("Nhân viên (bấm để chọn/bỏ bạn cần nhắc trong bài)")
        nganTrongThe.addArrangedSubview(nhanNV)

        nganChipNhanVien.axis = .vertical
        nganChipNhanVien.spacing = 6
        nganTrongThe.addArrangedSubview(nganChipNhanVien)

        ngan.addArrangedSubview(thePhanTich)

        // 3. Cụm nút Gửi báo cáo LINE, Xuất ảnh, Xuất Excel (.xlsx) 7 Sheet & PowerPoint (.pptx) 6 Slide bằng AI Gemini
        ngan.addArrangedSubview(taoNutHanhDong(
            "💬 Gửi báo cáo vào LINE & Copy nội dung",
            mauNen: BangMauBCTD.xanhDatVach,
            mauChu: .white,
            action: #selector(bamGuiLine)
        ))
        ngan.addArrangedSubview(taoNutHanhDong(
            "🖼️ Xuất ảnh bảng số + Copy nội dung báo cáo gửi LINE",
            mauNen: BangMauBCTD.xanhChuDao,
            mauChu: .white,
            action: #selector(bamChiaSeAnhBang)
        ))
        ngan.addArrangedSubview(taoNutHanhDong(
            "📝 Xuất ảnh bản tin chữ phân tích + Copy nội dung",
            mauNen: BangMauBCTD.xanhBienChuDao,
            mauChu: .white,
            action: #selector(bamChiaSeAnhChu)
        ))

        nutXuatExcelAI = taoNutHanhDong(
            "📗 Xuất Excel (.xlsx) Chi Tiết (7 Sheet • AI Gemini)",
            mauNen: BangMauBCTD.xanhLaDam,
            mauChu: .white,
            action: #selector(bamXuatExcel)
        )
        nutXuatPowerPointAI = taoNutHanhDong(
            "📙 Xuất PowerPoint (.pptx) Chi Tiết (6 Slide • AI Gemini)",
            mauNen: BangMauBCTD.vangKhaChu,
            mauChu: .white,
            action: #selector(bamXuatPowerPoint)
        )

        let hangOffice = UIStackView(arrangedSubviews: [nutXuatExcelAI, nutXuatPowerPointAI])
        hangOffice.axis = .vertical
        hangOffice.spacing = 8
        hangOffice.distribution = .fill
        ngan.addArrangedSubview(hangOffice)

        ngan.addArrangedSubview(taoNutHanhDong(
            "📋 Chỉ sao chép nội dung văn bản",
            mauNen: BangMauBCTD.nenThePhu,
            mauChu: BangMauBCTD.chuChinh,
            coVien: true,
            action: #selector(bamSaoChep)
        ))

        ngan.addArrangedSubview(taoNutHanhDong(
            "📊 Chỉ lấy số liệu để dán vào Copilot 365",
            mauNen: BangMauBCTD.vangSang,
            mauChu: BangMauBCTD.chuChinh,
            coVien: true,
            action: #selector(bamSaoChepSoLieu)
        ))

        capNhatMauNutGiongVan()
    }

    private func taoKhungYeuCauNguoiDung() -> UIView {
        let hop = UIView()
        hop.backgroundColor = BangMauBCTD.nenHeaderBang
        hop.layer.cornerRadius = 12
        hop.layer.borderWidth = 1.2
        hop.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor

        let lbTieuDe = UILabel()
        lbTieuDe.text = "💬 YÊU CẦU RIÊNG CỦA BẠN (ÁP DỤNG CHO AI GEMINI & XUẤT FILE EXCEL / POWERPOINT)"
        lbTieuDe.font = .systemFont(ofSize: 12.5, weight: .heavy)
        lbTieuDe.textColor = BangMauBCTD.xanhChuDaoDam
        lbTieuDe.numberOfLines = 0
        lbTieuDe.lineBreakMode = .byWordWrapping
        lbTieuDe.adjustsFontSizeToFitWidth = false

        let nutXoaYC = UIButton(type: .system)
        nutXoaYC.setTitle("Xoá", for: .normal)
        nutXoaYC.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        nutXoaYC.titleLabel?.numberOfLines = 0
        nutXoaYC.titleLabel?.lineBreakMode = .byWordWrapping
        nutXoaYC.titleLabel?.adjustsFontSizeToFitWidth = false
        nutXoaYC.setTitleColor(BangMauBCTD.doYeuChu, for: .normal)
        nutXoaYC.setContentHuggingPriority(.required, for: .horizontal)
        nutXoaYC.addTarget(self, action: #selector(bamXoaYeuCauRieng), for: .touchUpInside)

        let hangTren = UIStackView(arrangedSubviews: [lbTieuDe, nutXoaYC])
        hangTren.axis = .horizontal
        hangTren.spacing = 8
        hangTren.alignment = .center

        let lbMoTa = UILabel()
        lbMoTa.text = "Nhập yêu cầu phân tích riêng hoặc bấm chọn nhanh gợi ý bên dưới. Khi bấm [✨ AI Gemini], [📗 Xuất Excel] hoặc [📙 Xuất PowerPoint], AI sẽ thiết kế bảng chuyên đề và nhận xét bám sát yêu cầu này:"
        lbMoTa.font = .systemFont(ofSize: 12.5, weight: .medium)
        lbMoTa.textColor = BangMauBCTD.chuPhu
        lbMoTa.numberOfLines = 0
        lbMoTa.lineBreakMode = .byWordWrapping
        lbMoTa.adjustsFontSizeToFitWidth = false

        oYeuCauRieng.font = .systemFont(ofSize: 14.0, weight: .medium)
        oYeuCauRieng.textColor = BangMauBCTD.chuChinh
        oYeuCauRieng.backgroundColor = BangMauBCTD.nenThe
        oYeuCauRieng.layer.cornerRadius = 10
        oYeuCauRieng.layer.borderWidth = 1
        oYeuCauRieng.layer.borderColor = BangMauBCTD.vienDam.cgColor
        oYeuCauRieng.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        oYeuCauRieng.isScrollEnabled = false
        oYeuCauRieng.delegate = self
        oYeuCauRieng.text = DichVuGeminiAI.dungChung.yeuCauTuyChinhHienTai
        oYeuCauRieng.translatesAutoresizingMaskIntoConstraints = false
        oYeuCauRieng.heightAnchor.constraint(greaterThanOrEqualToConstant: 68).isActive = true

        nhanGoiYYeuCau.text = "Ví dụ: \"Phân tích sâu các ngành dưới 80%, lập bảng chia chỉ tiêu ngày còn lại và giao từng nhân viên kèm cặp Top 5 yếu...\""
        nhanGoiYYeuCau.font = .italicSystemFont(ofSize: 13.0)
        nhanGoiYYeuCau.textColor = BangMauBCTD.chuPhu
        nhanGoiYYeuCau.numberOfLines = 0
        nhanGoiYYeuCau.lineBreakMode = .byWordWrapping
        nhanGoiYYeuCau.adjustsFontSizeToFitWidth = false
        nhanGoiYYeuCau.translatesAutoresizingMaskIntoConstraints = false
        oYeuCauRieng.addSubview(nhanGoiYYeuCau)

        NSLayoutConstraint.activate([
            nhanGoiYYeuCau.topAnchor.constraint(equalTo: oYeuCauRieng.topAnchor, constant: 10),
            nhanGoiYYeuCau.leadingAnchor.constraint(equalTo: oYeuCauRieng.leadingAnchor, constant: 12),
            nhanGoiYYeuCau.trailingAnchor.constraint(equalTo: oYeuCauRieng.frameLayoutGuide.trailingAnchor, constant: -12)
        ])
        capNhatTrangThaiPlaceholderYeuCau()

        // Lưới các nút gợi ý nhanh (2 cột)
        let nganGoiY = UIStackView()
        nganGoiY.axis = .vertical
        nganGoiY.spacing = 6
        let dsGoiY = DichVuGeminiAI.cacGoiYYeuCauNhanh
        var hangGY: UIStackView?
        for (idx, item) in dsGoiY.enumerated() {
            if idx % 2 == 0 {
                let h = UIStackView()
                h.axis = .horizontal
                h.spacing = 6
                h.distribution = .fillEqually
                nganGoiY.addArrangedSubview(h)
                hangGY = h
            }
            let nut = UIButton(type: .system)
            nut.tag = idx
            nut.setTitle(item.nhan, for: .normal)
            nut.titleLabel?.font = .systemFont(ofSize: 12.0, weight: .semibold)
            nut.titleLabel?.numberOfLines = 0
            nut.titleLabel?.lineBreakMode = .byWordWrapping
            nut.titleLabel?.textAlignment = .center
            nut.titleLabel?.adjustsFontSizeToFitWidth = false
            nut.backgroundColor = BangMauBCTD.nenThe
            nut.setTitleColor(BangMauBCTD.xanhChuDaoDam, for: .normal)
            nut.layer.cornerRadius = 8
            nut.layer.borderWidth = 1
            nut.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
            nut.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
            nut.addTarget(self, action: #selector(bamChonGoiYYeuCau(_:)), for: .touchUpInside)
            hangGY?.addArrangedSubview(nut)
        }

        let nganHop = UIStackView(arrangedSubviews: [hangTren, lbMoTa, oYeuCauRieng, nganGoiY])
        nganHop.axis = .vertical
        nganHop.spacing = 8
        nganHop.translatesAutoresizingMaskIntoConstraints = false
        hop.addSubview(nganHop)

        NSLayoutConstraint.activate([
            nganHop.topAnchor.constraint(equalTo: hop.topAnchor, constant: 10),
            nganHop.leadingAnchor.constraint(equalTo: hop.leadingAnchor, constant: 10),
            nganHop.trailingAnchor.constraint(equalTo: hop.trailingAnchor, constant: -10),
            nganHop.bottomAnchor.constraint(equalTo: hop.bottomAnchor, constant: -10)
        ])
        return hop
    }

    private func capNhatTrangThaiPlaceholderYeuCau() {
        let trong = (oYeuCauRieng.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        nhanGoiYYeuCau.isHidden = !trong
    }

    @objc private func bamXoaYeuCauRieng() {
        oYeuCauRieng.text = ""
        DichVuGeminiAI.dungChung.yeuCauTuyChinhHienTai = ""
        capNhatTrangThaiPlaceholderYeuCau()
        oYeuCauRieng.invalidateIntrinsicContentSize()
    }

    @objc private func bamChonGoiYYeuCau(_ sender: UIButton) {
        let ds = DichVuGeminiAI.cacGoiYYeuCauNhanh
        guard sender.tag >= 0 && sender.tag < ds.count else { return }
        let noiDungGoiY = ds[sender.tag].noiDung
        oYeuCauRieng.text = noiDungGoiY
        DichVuGeminiAI.dungChung.yeuCauTuyChinhHienTai = noiDungGoiY
        capNhatTrangThaiPlaceholderYeuCau()
        oYeuCauRieng.invalidateIntrinsicContentSize()
        nhanTrangThaiTren.text = "💬 Đã nạp yêu cầu: \"\(ds[sender.tag].nhan)\" · Bấm ✨ AI Gemini hoặc Xuất Excel / PowerPoint để tạo!"
        nhanTrangThaiTren.textColor = BangMauBCTD.xanhChuDaoDam
    }

    private func taoNhanMucNho(_ chu: String) -> UILabel {
        let lb = UILabel()
        lb.text = chu
        lb.font = .systemFont(ofSize: 13.0, weight: .medium)
        lb.textColor = BangMauBCTD.chuPhu
        lb.numberOfLines = 0
        lb.lineBreakMode = .byWordWrapping
        lb.adjustsFontSizeToFitWidth = false
        return lb
    }

    private func taoNutHanhDong(
        _ tieuDe: String,
        mauNen: UIColor,
        mauChu: UIColor,
        coVien: Bool = false,
        action: Selector
    ) -> UIButton {
        let nut = UIButton(type: .system)
        nut.setTitle(tieuDe, for: .normal)
        nut.titleLabel?.font = .systemFont(ofSize: 14.5, weight: .bold)
        nut.titleLabel?.numberOfLines = 0
        nut.titleLabel?.lineBreakMode = .byWordWrapping
        nut.titleLabel?.textAlignment = .center
        nut.titleLabel?.adjustsFontSizeToFitWidth = false
        nut.backgroundColor = mauNen
        nut.tintColor = mauChu
        nut.setTitleColor(mauChu, for: .normal)
        nut.layer.cornerRadius = 12
        if coVien {
            nut.layer.borderWidth = 1
            nut.layer.borderColor = BangMauBCTD.vienDam.cgColor
        }
        nut.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        nut.addTarget(self, action: action, for: .touchUpInside)
        return nut
    }

    private func capNhatMauNutGiongVan() {
        for nut in cacNutGiongVan {
            let dangChon = (nut.tag == giongDangChon.rawValue)
            if dangChon {
                nut.backgroundColor = BangMauBCTD.vangSang
                nut.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
                nut.layer.borderColor = BangMauBCTD.vangChuDao.cgColor
            } else {
                nut.backgroundColor = BangMauBCTD.nenThePhu
                nut.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
                nut.layer.borderColor = BangMauBCTD.vienDam.cgColor
            }
        }
    }

    private func dungLaiCacChipTapTrung(soLieu s: SoLieuBanTin) {
        nganChipNhomHang.arrangedSubviews.forEach {
            nganChipNhomHang.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        nganChipNhanVien.arrangedSubviews.forEach {
            nganChipNhanVien.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let dsNganh = (!s.dsLuyKe.isEmpty ? s.dsLuyKe : s.dsHomNay)
            .filter { $0.target > 0 }
            .prefix(12)
            .map(\.tenNganhHang)

        if dsNganh.isEmpty {
            let lb = taoNhanMucNho("Chưa có nhóm ngành hàng (nhập ảnh ở mục Nhập số để hiển thị)")
            nganChipNhomHang.addArrangedSubview(lb)
        } else {
            themCacChipVaoNgan(
                nganChipNhomHang,
                danhSach: Array(dsNganh),
                tapDangChon: nhomTapTrung,
                laNhomHang: true
            )
        }

        let dsTenNV = s.nhanVien.prefix(12).map { $0.nhanVien.hoTen }
        if dsTenNV.isEmpty {
            let lb = taoNhanMucNho("Chưa có danh sách nhân viên")
            nganChipNhanVien.addArrangedSubview(lb)
        } else {
            themCacChipVaoNgan(
                nganChipNhanVien,
                danhSach: Array(dsTenNV),
                tapDangChon: nvTapTrung,
                laNhomHang: false
            )
        }
    }

    private func themCacChipVaoNgan(
        _ ngan: UIStackView,
        danhSach: [String],
        tapDangChon: Set<String>,
        laNhomHang: Bool
    ) {
        // Hai cột đủ rộng để tên ngành/nhân viên không chồng chữ trên màn hình iPhone.
        let soCot = 2
        var hangHienTai: UIStackView?
        for (i, ten) in danhSach.enumerated() {
            if i % soCot == 0 {
                let h = UIStackView()
                h.axis = .horizontal
                h.spacing = 6
                h.distribution = .fillEqually
                ngan.addArrangedSubview(h)
                hangHienTai = h
            }
            let dangChon = tapDangChon.contains(ten)
            let nut = UIButton(type: .custom)
            nut.setTitle(ten, for: .normal)
            nut.accessibilityIdentifier = ten
            nut.tag = laNhomHang ? 1 : 2
            nut.titleLabel?.font = .systemFont(ofSize: 12.0, weight: dangChon ? .bold : .medium)
            nut.titleLabel?.numberOfLines = 0
            nut.titleLabel?.lineBreakMode = .byWordWrapping
            nut.titleLabel?.textAlignment = .center
            nut.titleLabel?.adjustsFontSizeToFitWidth = false
            nut.layer.cornerRadius = 8
            nut.layer.borderWidth = 1
            nut.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
            nut.heightAnchor.constraint(greaterThanOrEqualToConstant: laNhomHang ? 44 : 40).isActive = true
            if dangChon {
                nut.backgroundColor = BangMauBCTD.vangSang
                nut.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
                nut.layer.borderColor = BangMauBCTD.vangChuDao.cgColor
            } else {
                nut.backgroundColor = BangMauBCTD.nenThePhu
                nut.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
                nut.layer.borderColor = BangMauBCTD.vienDam.cgColor
            }
            nut.addTarget(self, action: #selector(bamChipTapTrung(_:)), for: .touchUpInside)
            hangHienTai?.addArrangedSubview(nut)
        }
    }

    // MARK: - Định dạng văn bản có **in đậm** trực quan như ảnh chụp

    static func dinhDangVanBanCoInDam(_ chuoi: String) -> NSAttributedString {
        let kieuDoan = NSMutableParagraphStyle()
        kieuDoan.lineSpacing = 4
        kieuDoan.lineBreakMode = .byWordWrapping

        let fontThuong = UIFont.systemFont(ofSize: 15.5, weight: .regular)
        let fontDam = UIFont.systemFont(ofSize: 15.5, weight: .bold)

        let ketQua = NSMutableAttributedString()
        let cacPhan = chuoi.components(separatedBy: "**")
        for (idx, phan) in cacPhan.enumerated() {
            guard !phan.isEmpty else { continue }
            let laInDam = (idx % 2 == 1)
            let attr: [NSAttributedString.Key: Any] = [
                .font: laInDam ? fontDam : fontThuong,
                .foregroundColor: BangMauBCTD.chuChinh,
                .backgroundColor: UIColor.clear,
                .paragraphStyle: kieuDoan
            ]
            ketQua.append(NSAttributedString(string: phan, attributes: attr))
        }
        return ketQua
    }

    private func ganVanBanHienThi(_ chuoi: String) {
        oVanBan.backgroundColor = BangMauBCTD.nenThe
        oVanBan.attributedText = Self.dinhDangVanBanCoInDam(chuoi)
        oVanBan.typingAttributes[.backgroundColor] = UIColor.clear
        oVanBan.invalidateIntrinsicContentSize()
    }

    // MARK: - Nạp & lưu bài

    private func khoaLuu() -> String {
        "bantin.v2.\(TienIchNgay.khoa.string(from: ngay)).\(giongDangChon.rawValue)"
    }

    private func napBanTin(taoMoi: Bool) {
        khungDangChon = KhungBanTin.theoGio()
        let s = KhoDuLieu.dungChung.taoSoLieuBanTin(cho: ngay, khung: khungDangChon)
        soLieu = s

        capNhatMauNutGiongVan()
        dungLaiCacChipTapTrung(soLieu: s)

        if !taoMoi,
           nhomTapTrung.isEmpty,
           nvTapTrung.isEmpty,
           let daLuu = UserDefaults.standard.string(forKey: khoaLuu()),
           !daLuu.isEmpty {
            ganVanBanHienThi(daLuu)
            nhanTrangThaiTren.text = "Bản tin đã lưu trên máy · bấm Phân tích lại nếu vừa đổi số"
            nhanTrangThaiTren.textColor = BangMauBCTD.chuPhu
        } else {
            let baiMoi = BoVietBanTin(soLieu: s, giong: giongDangChon, bienThe: bienThe)
                .vietTheoMauAnhChup(nhomTapTrung: nhomTapTrung, nvTapTrung: nvTapTrung)
            UserDefaults.standard.set(baiMoi, forKey: khoaLuu())
            ganVanBanHienThi(baiMoi)
            nhanTrangThaiTren.text = "Bản tin đã lưu trên máy · bấm Phân tích lại nếu vừa đổi số"
            nhanTrangThaiTren.textColor = BangMauBCTD.chuPhu
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        if textView === oYeuCauRieng {
            capNhatTrangThaiPlaceholderYeuCau()
            DichVuGeminiAI.dungChung.yeuCauTuyChinhHienTai = textView.text ?? ""
            oYeuCauRieng.invalidateIntrinsicContentSize()
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView === oYeuCauRieng {
            DichVuGeminiAI.dungChung.yeuCauTuyChinhHienTai = textView.text ?? ""
            capNhatTrangThaiPlaceholderYeuCau()
        } else {
            UserDefaults.standard.set(textView.text ?? "", forKey: khoaLuu())
        }
    }

    // MARK: - Sự kiện tương tác

    @objc private func bamChonGiongVan(_ sender: UIButton) {
        guard let giongMoi = GiongVanBanTin(rawValue: sender.tag) else { return }
        giongDangChon = giongMoi
        bienThe = 0
        napBanTin(taoMoi: true)
    }

    @objc private func bamBoChonHet() {
        nhomTapTrung.removeAll()
        nvTapTrung.removeAll()
        napBanTin(taoMoi: true)
    }

    @objc private func bamChipTapTrung(_ sender: UIButton) {
        guard let ten = sender.accessibilityIdentifier else { return }
        if sender.tag == 1 {
            if nhomTapTrung.contains(ten) {
                nhomTapTrung.remove(ten)
            } else {
                nhomTapTrung.insert(ten)
            }
        } else {
            if nvTapTrung.contains(ten) {
                nvTapTrung.remove(ten)
            } else {
                nvTapTrung.insert(ten)
            }
        }
        napBanTin(taoMoi: true)
    }

    @objc private func bamPhanTichLai() {
        view.endEditing(true)
        bienThe += 1
        napBanTin(taoMoi: true)
    }

    @objc private func bamPhanTichAIGemini() {
        view.endEditing(true)
        guard let s = soLieu else { return }
        let yc = (oYeuCauRieng.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        DichVuGeminiAI.dungChung.yeuCauTuyChinhHienTai = yc

        nutAIGemini.isEnabled = false
        nutAIGemini.setTitle("⏳ Đang phân tích...", for: .normal)
        nhanTrangThaiTren.text = "🤖 Đang kết nối Google Gemini (\(DichVuGeminiAI.dungChung.modelHienTai)) để phân tích số liệu\(yc.isEmpty ? "" : " theo yêu cầu riêng")..."
        nhanTrangThaiTren.textColor = BangMauBCTD.xanhChuDao

        DichVuGeminiAI.dungChung.phanTichBaoCao(
            soLieu: s,
            giong: giongDangChon,
            nhomTapTrung: nhomTapTrung,
            nvTapTrung: nvTapTrung,
            yeuCauRieng: yc
        ) { [weak self] kq in
            guard let self = self else { return }
            self.nutAIGemini.isEnabled = true
            self.nutAIGemini.setTitle("✨ AI Gemini", for: .normal)
            switch kq {
            case .success(let baiAI):
                UserDefaults.standard.set(baiAI, forKey: self.khoaLuu())
                self.ganVanBanHienThi(baiAI)
                self.nhanTrangThaiTren.text = "✨ Đã tạo báo cáo bằng Google Gemini AI (\(DichVuGeminiAI.dungChung.modelHienTai)) · có thể chỉnh sửa trực tiếp"
                self.nhanTrangThaiTren.textColor = BangMauBCTD.xanhLaDam
            case .failure(let loi):
                let baiOffline = BoVietBanTin(soLieu: s, giong: self.giongDangChon, bienThe: self.bienThe + 1)
                    .vietTheoMauAnhChup(nhomTapTrung: self.nhomTapTrung, nvTapTrung: self.nvTapTrung)
                self.ganVanBanHienThi(baiOffline)
                self.nhanTrangThaiTren.text = "ℹ️ Đã tạo bản phân tích theo mẫu chuẩn (Gemini phản hồi: \(loi.localizedDescription))"
                self.nhanTrangThaiTren.textColor = BangMauBCTD.vangKhaChu
            }
        }
    }

    @objc private func bamSaoChep() {
        view.endEditing(true)
        let noiDung = oVanBan.text ?? ""
        UIPasteboard.general.string = noiDung
        nhanTrangThaiTren.text = "✅ Đã sao chép nội dung báo cáo vào bộ nhớ tạm ( sẵn sàng dán vào LINE )."
        nhanTrangThaiTren.textColor = BangMauBCTD.xanhLaDam
    }

    @objc private func bamSaoChepSoLieu() {
        view.endEditing(true)
        let dl = KhoDuLieu.dungChung.duLieu(cho: ngay)
        var dong = [
            "DU LIEU BAO CAO DMX - \(TienIchNgay.hienThiNgay.string(from: ngay))",
            "Don vi\t\(dl.thongTinDonVi)",
            "Chi so\tThuc hien\tTarget\tTy le",
            "Doanh thu thuc\t\(dl.doanhThu.doanhThuThuc)\t\(dl.doanhThu.targetThuc)\t\(dl.doanhThu.phanTramHTThucHienThi)",
            "Doanh thu quy doi\t\(dl.doanhThu.doanhThuQuyDoi)\t\(dl.doanhThu.targetQuyDoi)\t\(dl.doanhThu.phanTramHTQuyDoi)",
            "",
            "NGANH HANG\tDON VI\tTHUC HIEN\tTARGET\tPHAN TRAM HT\tPHAN TRAM DU KIEN"
        ]
        dong.append(contentsOf: dl.danhSachThiDua.map {
            "\($0.tenNganhHang)\t\($0.loaiChiTieu.maBang)\t\($0.thucHien)\t\($0.target)\t\($0.phanTramHT)\t\($0.phanTramDuBao)"
        })
        UIPasteboard.general.string = dong.joined(separator: "\n")
        nhanTrangThaiTren.text = "✅ Đã copy riêng số liệu dạng bảng. Mở Trình duyệt Copilot, dán và yêu cầu tạo Excel/PowerPoint."
        nhanTrangThaiTren.textColor = BangMauBCTD.xanhLaDam
    }

    @objc private func bamGuiLine() {
        view.endEditing(true)
        let noiDung = oVanBan.text ?? ""
        UIPasteboard.general.string = noiDung
        UserDefaults.standard.set(noiDung, forKey: khoaLuu())
        nhanTrangThaiTren.text = "✅ Đã tự động copy nội dung báo cáo · đang mở LINE..."
        nhanTrangThaiTren.textColor = BangMauBCTD.xanhLaDam

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
        let noiDung = oVanBan.text ?? ""
        UIPasteboard.general.string = noiDung

        let cacAnh = taoAnhBang(khungDangChon, s)
        if cacAnh.isEmpty {
            nhanTrangThaiTren.text = "⚠ Chưa có bảng số cho khung này để tạo ảnh. Đã copy nội dung chữ."
            nhanTrangThaiTren.textColor = BangMauBCTD.doYeuChu
            return
        }
        nhanTrangThaiTren.text = "✅ Đã copy nội dung trong ô văn bản! Hãy chọn LINE để gửi ảnh rồi Dán (Paste) nội dung."
        nhanTrangThaiTren.textColor = BangMauBCTD.xanhLaDam
        chiaSe(cacAnh)
    }

    @objc private func bamChiaSeAnhChu() {
        view.endEditing(true)
        let noiDung = oVanBan.text ?? ""
        UIPasteboard.general.string = noiDung
        let tieuDe = "BÁO CÁO KINH DOANH · \(TienIchNgay.hienThiNgay.string(from: ngay))"
        let anh = ManHinhBanTin.veAnhVanBan(noiDung, tieuDe: tieuDe)
        nhanTrangThaiTren.text = "✅ Đã copy nội dung chữ & mở hộp thoại chia sẻ ảnh bản tin!"
        nhanTrangThaiTren.textColor = BangMauBCTD.xanhLaDam
        chiaSe([anh])
    }

    @objc private func bamXuatExcel() {
        view.endEditing(true)
        let noiDung = oVanBan.text ?? ""
        let yc = (oYeuCauRieng.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        DichVuGeminiAI.dungChung.yeuCauTuyChinhHienTai = yc
        UIPasteboard.general.string = noiDung

        nutXuatExcelAI.isEnabled = false
        nutXuatExcelAI.setTitle("⏳ AI Gemini đang thiết kế Excel 7 Sheet...", for: .normal)
        nhanTrangThaiTren.text = "🤖 Đang gọi Google Gemini AI phân tích chuyên sâu & thiết kế file Excel (.xlsx) 7 Sheet có công thức và màu sắc..."
        nhanTrangThaiTren.textColor = BangMauBCTD.xanhChuDao

        BoXuatOfficeDMX.taoFileExcelBangAIGemini(
            ngay: ngay,
            noiDungPhanTich: noiDung,
            yeuCauNguoiDung: yc
        ) { [weak self] url, dungAIThat, tenModel in
            guard let self = self else { return }
            self.nutXuatExcelAI.isEnabled = true
            self.nutXuatExcelAI.setTitle("📗 Xuất Excel (.xlsx) Chi Tiết (7 Sheet • AI Gemini)", for: .normal)
            guard let url else { return }
            let nguon = dungAIThat ? "Google Gemini (\(tenModel))" : "Bộ phân tích thông minh"
            self.nhanTrangThaiTren.text = "📗 Đã tạo file Excel (.xlsx) 7 Sheet chi tiết bằng \(nguon) & copy sẵn nội dung báo cáo!"
            self.nhanTrangThaiTren.textColor = BangMauBCTD.xanhLaDam
            self.chiaSe([url])
        }
    }

    @objc private func bamXuatPowerPoint() {
        view.endEditing(true)
        let noiDung = oVanBan.text ?? ""
        let yc = (oYeuCauRieng.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        DichVuGeminiAI.dungChung.yeuCauTuyChinhHienTai = yc
        UIPasteboard.general.string = noiDung

        nutXuatPowerPointAI.isEnabled = false
        nutXuatPowerPointAI.setTitle("⏳ AI Gemini đang thiết kế 6 Slide...", for: .normal)
        nhanTrangThaiTren.text = "🤖 Đang gọi Google Gemini AI thiết kế bộ 6 Slide PowerPoint (.pptx) trình chiếu điều hành..."
        nhanTrangThaiTren.textColor = BangMauBCTD.xanhChuDao

        BoXuatOfficeDMX.taoFilePowerPointBangAIGemini(
            ngay: ngay,
            noiDungPhanTich: noiDung,
            yeuCauNguoiDung: yc
        ) { [weak self] url, dungAIThat, tenModel in
            guard let self = self else { return }
            self.nutXuatPowerPointAI.isEnabled = true
            self.nutXuatPowerPointAI.setTitle("📙 Xuất PowerPoint (.pptx) Chi Tiết (6 Slide • AI Gemini)", for: .normal)
            guard let url else { return }
            let nguon = dungAIThat ? "Google Gemini (\(tenModel))" : "Bộ phân tích thông minh"
            self.nhanTrangThaiTren.text = "📙 Đã tạo file PowerPoint (.pptx) 6 Slide chuyên nghiệp bằng \(nguon) & copy sẵn nội dung báo cáo!"
            self.nhanTrangThaiTren.textColor = BangMauBCTD.xanhLaDam
            self.chiaSe([url])
        }
    }

    private func chiaSe(_ muc: [Any]) {
        let vc = UIActivityViewController(activityItems: muc, applicationActivities: nil)
        if let pop = vc.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(vc, animated: true)
    }

    // MARK: - Vẽ ảnh bản tin từ chữ (nền sáng, header xanh tươi sáng, không cắt chữ)

    static func veAnhVanBan(_ chu: String, tieuDe: String) -> UIImage {
        let rong: CGFloat = 920
        let le: CGFloat = 36
        let rongChu = rong - le * 2
        let kieuChu = NSMutableParagraphStyle()
        kieuChu.lineBreakMode = .byWordWrapping
        kieuChu.lineSpacing = 6
        let thuocTinhThan: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 25, weight: .regular),
            .foregroundColor: BangMauBCTD.chuChinh,
            .paragraphStyle: kieuChu
        ]
        let thuocTinhTieuDe: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .heavy),
            .foregroundColor: UIColor.white,
            .paragraphStyle: kieuChu
        ]
        let chuSach = chu.replacingOccurrences(of: "**", with: "")
        let than = NSAttributedString(string: chuSach, attributes: thuocTinhThan)
        let td = NSAttributedString(string: tieuDe, attributes: thuocTinhTieuDe)
        let khungToiDa = CGSize(width: rongChu, height: CGFloat.greatestFiniteMagnitude)
        let caoThan = ceil(than.boundingRect(with: khungToiDa, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height)
        let caoTieuDe = ceil(td.boundingRect(with: khungToiDa, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height)
        let caoBang = caoTieuDe + 42
        let tong = caoBang + caoThan + le * 2

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: rong, height: tong))
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: rong, height: tong))
            BangMauBCTD.xanhChuDao.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: rong, height: caoBang))
            BangMauBCTD.vangSang.setFill()
            ctx.fill(CGRect(x: 0, y: caoBang - 6, width: rong, height: 6))
            td.draw(with: CGRect(x: le, y: 18, width: rongChu, height: caoTieuDe), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            than.draw(with: CGRect(x: le, y: caoBang + le, width: rongChu, height: caoThan), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        }
    }
}
