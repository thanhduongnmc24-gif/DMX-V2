import UIKit

final class ManHinhCaiDat: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    var khiThayDoiCaiDat: (() -> Void)?
    private var ngay: Date
    private let nhanThongTinTaiKhoan = UILabel()
    private let nhanHopThuThongBao = UILabel()
    private let nutDongBoNgay = UIButton(type: .system)
    private let nutMoAdminTaiKhoan = UIButton(type: .system)
    private let nutDoiMatKhauNhanh = UIButton(type: .system)
    private let nutDangXuatNhanh = UIButton(type: .system)

    // Cụm cài đặt Google Gemini AI (Miễn phí)
    private let oNhapGeminiKey = UITextField()
    private let nutChonModelGemini = UIButton(type: .system)
    private let nutKiemTraKeyGemini = UIButton(type: .system)
    private let nutKhoiPhucKeyMacDinh = UIButton(type: .system)
    private let nhanTrangThaiGemini = UILabel()
    private var modelGeminiDangChon: String = "gemini-2.5-flash"

    private let chonKieuHienThi = UISegmentedControl(items: ["Bảng 8 cột (Chi tiết)", "Thẻ tiến độ (Gọn)"])
    private let chonSoCotXuat = UISegmentedControl(items: ["1 cột", "2 cột", "3 cột", "4 cột"])
    private let nutChiaTarget = UIButton(type: .system)
    private let nutQuanLyNV = UIButton(type: .system)
    private let oNhapCumTu = UITextField()
    private let bangCumTu = UITableView(frame: .zero, style: .plain)
    private var danhSachCumTu: [String] = []

    init(ngay: Date = Date()) {
        self.ngay = ngay
        super.init(nibName: nil, bundle: nil)
    }

    func capNhatNgay(_ ngayMoi: Date) {
        self.ngay = ngayMoi
        guard isViewLoaded else { return }
        let cd = KhoDuLieu.dungChung.caiDat
        chonKieuHienThi.selectedSegmentIndex = cd.kieuHienThi.rawValue
        danhSachCumTu = cd.danhSachCumTuLocBo
        chonSoCotXuat.selectedSegmentIndex = max(0, min(3, cd.soCotXuatAnh - 1))
        oNhapGeminiKey.text = cd.geminiApiKey.isEmpty ? DichVuGeminiAI.khoaMacDinh : cd.geminiApiKey
        modelGeminiDangChon = cd.geminiModel.isEmpty ? "gemini-2.5-flash" : cd.geminiModel
        capNhatTieuDeNutModelGemini()
        bangCumTu.reloadData()
        capNhatThongTinTaiKhoanUI()
        capNhatTieuDeNutNhanVien()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cài đặt & Gemini AI"
        view.backgroundColor = BangMauBCTD.nenTrang
        chonKieuHienThi.addTarget(self, action: #selector(thayDoiTuyChonHienThi), for: .valueChanged)
        chonSoCotXuat.addTarget(self, action: #selector(thayDoiTuyChonHienThi), for: .valueChanged)

        let nutLuu = UIBarButtonItem(
            title: "Lưu",
            style: .done,
            target: self,
            action: #selector(luuCaiDat)
        )
        let nutTaiKhoan = UIBarButtonItem(
            image: UIImage(systemName: "person.crop.circle.badge.checkmark"),
            style: .plain,
            target: self,
            action: #selector(moQuanLyTaiKhoan)
        )
        nutTaiKhoan.tintColor = BangMauBCTD.xanhChuDao
        navigationItem.rightBarButtonItems = [nutLuu, nutTaiKhoan]

        let cd = KhoDuLieu.dungChung.caiDat
        chonKieuHienThi.selectedSegmentIndex = cd.kieuHienThi.rawValue
        danhSachCumTu = cd.danhSachCumTuLocBo
        let chiSoCot = max(0, min(3, cd.soCotXuatAnh - 1))
        chonSoCotXuat.selectedSegmentIndex = chiSoCot
        oNhapGeminiKey.text = cd.geminiApiKey.isEmpty ? DichVuGeminiAI.khoaMacDinh : cd.geminiApiKey
        modelGeminiDangChon = cd.geminiModel.isEmpty ? "gemini-2.5-flash" : cd.geminiModel

        taoGiaoDien()
        capNhatTieuDeNutModelGemini()
        capNhatThongTinTaiKhoanUI()
        capNhatTieuDeNutNhanVien()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        capNhatThongTinTaiKhoanUI()
        capNhatTieuDeNutNhanVien()
    }

    private func capNhatThongTinTaiKhoanUI() {
        let ten = DichVuDongBo.dungChung.tenDangNhap.isEmpty ? "Chưa đăng nhập" : DichVuDongBo.dungChung.tenDangNhap
        let laAdmin = DichVuDongBo.dungChung.laAdmin
        let vaiTro = laAdmin ? "🛡️ Quản trị viên (Admin)" : "👑 Thành viên Cao cấp"
        nhanThongTinTaiKhoan.text = "Tài khoản: \(ten)   •   \(vaiTro)"
        let ngayStr = TienIchNgay.hienThiNgay.string(from: ngay)
        nhanHopThuThongBao.text = "📩 Hệ thống ĐMX (\(ngayStr)): Dữ liệu và cài đặt của tài khoản \(ten) được đồng bộ đám mây tự động."
        nutMoAdminTaiKhoan.isHidden = !laAdmin
    }

    private func capNhatTieuDeNutModelGemini() {
        let moTa = DichVuGeminiAI.cacModelMienPhi.first(where: { $0.ma == modelGeminiDangChon })?.ten
            ?? "\(modelGeminiDangChon) (Miễn phí)"
        nutChonModelGemini.setTitle("⚡ Model miễn phí: \(moTa) ▾", for: .normal)
    }

    @objc private func bamChonModelGemini() {
        var cacMuc: [MucChonDMX] = []
        for item in DichVuGeminiAI.cacModelMienPhi {
            let dangChon = (item.ma == modelGeminiDangChon)
            cacMuc.append(MucChonDMX(tieuDe: item.ten, dangChon: dangChon) { [weak self] in
                guard let self = self else { return }
                self.modelGeminiDangChon = item.ma
                self.capNhatTieuDeNutModelGemini()
                self.dongBoTamCaiDat()
                self.khiThayDoiCaiDat?()
            })
        }
        cacMuc.append(MucChonDMX(tieuDe: "Đóng", kieu: .huy))
        hienMenuChon(
            tieuDe: "Chọn Model Google Gemini (Không tính phí)",
            thongDiep: "Tất cả các dòng Gemini Flash bên dưới đều thuộc gói miễn phí (Free Tier) của Google AI Studio:",
            cacMuc: cacMuc
        )
    }

    @objc private func bamKhoiPhucKeyMacDinh() {
        oNhapGeminiKey.text = DichVuGeminiAI.khoaMacDinh
        modelGeminiDangChon = "gemini-2.5-flash"
        capNhatTieuDeNutModelGemini()
        dongBoTamCaiDat()
        bamKiemTraKeyGemini()
    }

    @objc private func bamKiemTraKeyGemini() {
        view.endEditing(true)
        dongBoTamCaiDat()
        let key = (oNhapGeminiKey.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let keyDung = key.isEmpty ? DichVuGeminiAI.khoaMacDinh : key
        oNhapGeminiKey.text = keyDung

        nutKiemTraKeyGemini.isEnabled = false
        nutKiemTraKeyGemini.setTitle("⏳ Đang kiểm tra kết nối Gemini AI...", for: .normal)
        nhanTrangThaiGemini.text = "🔄 Đang gửi yêu cầu kiểm tra key tới máy chủ Google Gemini (\(modelGeminiDangChon))..."
        nhanTrangThaiGemini.textColor = BangMauBCTD.xanhChuDao

        DichVuGeminiAI.dungChung.kiemTraVaDungThuKey(apiKey: keyDung, model: modelGeminiDangChon) { [weak self] kq in
            guard let self = self else { return }
            self.nutKiemTraKeyGemini.isEnabled = true
            self.nutKiemTraKeyGemini.setTitle("🔍 Kiểm tra & Dùng thử Key Gemini ngay", for: .normal)

            switch kq {
            case .success(let (modelOK, phanHoi)):
                self.modelGeminiDangChon = modelOK
                self.capNhatTieuDeNutModelGemini()
                self.dongBoTamCaiDat()
                self.nhanTrangThaiGemini.text = "✅ Kết nối thành công với model miễn phí \"\(modelOK)\"!\n💬 Phản hồi thử: \(phanHoi)"
                self.nhanTrangThaiGemini.textColor = BangMauBCTD.xanhLaDam
                self.hienThongBao(
                    tieuDe: "✅ Key Gemini Hoạt Động Tốt",
                    noiDung: "Model sử dụng: \(modelOK) (Miễn phí)\n\nPhản hồi từ AI:\n\(phanHoi)"
                )
            case .failure(let loi):
                self.nhanTrangThaiGemini.text = "⚠️ Không thể xác thực trực tiếp lúc này: \(loi.localizedDescription). Đã lưu key để dùng cho mục Báo cáo & Xuất ảnh."
                self.nhanTrangThaiGemini.textColor = BangMauBCTD.doYeuChu
                self.hienThongBao(
                    tieuDe: "Thông báo kiểm tra Key Gemini",
                    noiDung: "Chi tiết phản hồi từ Google API:\n\(loi.localizedDescription)\n\n(Key đã được lưu sẵn. Khi không có mạng hoặc hết hạn mức, ứng dụng vẫn tự động tạo báo cáo chuẩn 5 mục ngay lập tức)."
                )
            }
        }
    }

    @objc private func thayDoiTuyChonHienThi() {
        dongBoTamCaiDat()
        khiThayDoiCaiDat?()
    }

    @objc private func bamDongBoDamMayNgay() {
        DichVuDongBo.dungChung.taiDuLieu()
        hienThongBao(tieuDe: "🔄 Đang đồng bộ", noiDung: "Đã gửi yêu cầu đồng bộ dữ liệu mới nhất từ đám mây.")
    }

    private func capNhatTieuDeNutNhanVien() {
        let cd = KhoDuLieu.dungChung.caiDat
        let soMH = KhoDuLieu.dungChung.danhSachMatHangThang(den: ngay).count
        nutChiaTarget.setTitle("🎯 1. Chia Target mặt hàng (\(soMH) mặt hàng) ▸", for: .normal)
        nutQuanLyNV.setTitle("👥 2. Danh sách nhân viên quản lý (\(cd.danhSachNhanVien.count) NV) ▸", for: .normal)
    }

    @objc private func bamMoManHinhAdminTaiKhoan() {
        dongBoTamCaiDat()
        navigationController?.pushViewController(ManHinhQuanLyTaiKhoan(), animated: true)
    }

    @objc private func bamDoiMatKhauCaNhan() {
        let tk = DichVuDongBo.dungChung.tenDangNhap
        let hop = UIAlertController(
            title: "🔑 Đổi mật khẩu (\(tk))",
            message: "Nhập mật khẩu mới (tối thiểu 6 ký tự):",
            preferredStyle: .alert
        )
        hop.addTextField { tf in
            tf.placeholder = "Mật khẩu mới"
            tf.isSecureTextEntry = true
        }
        hop.addTextField { tf in
            tf.placeholder = "Nhập lại mật khẩu mới"
            tf.isSecureTextEntry = true
        }
        hop.addAction(UIAlertAction(title: "Cập nhật mật khẩu", style: .default) { [weak self] _ in
            guard let self, let tfs = hop.textFields, tfs.count >= 2 else { return }
            let mk1 = tfs[0].text ?? ""
            let mk2 = tfs[1].text ?? ""
            guard mk1.count >= 6 else {
                self.hienThongBao(tieuDe: "Mật khẩu quá ngắn", noiDung: "Mật khẩu mới cần có ít nhất 6 ký tự.")
                return
            }
            guard mk1 == mk2 else {
                self.hienThongBao(tieuDe: "Chưa khớp", noiDung: "Mật khẩu nhập lại chưa khớp.")
                return
            }
            DichVuDongBo.dungChung.doiMatKhauCaNhan(matKhauMoi: mk1) { kq in
                switch kq {
                case .success:
                    self.hienThongBao(tieuDe: "✅ Thành công", noiDung: "Đã cập nhật mật khẩu cho tài khoản \(tk).")
                case .failure(let loi):
                    self.hienThongBao(tieuDe: "Lỗi", noiDung: loi.localizedDescription)
                }
            }
        })
        hop.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        present(hop, animated: true)
    }

    @objc private func bamDangXuatTaiKhoan() {
        let tk = DichVuDongBo.dungChung.tenDangNhap
        let hoi = UIAlertController(
            title: "Đăng xuất tài khoản \(tk)?",
            message: "Bạn có thể đăng nhập lại bất cứ lúc nào.",
            preferredStyle: .alert
        )
        hoi.addAction(UIAlertAction(title: "Đăng xuất", style: .destructive) { _ in
            DichVuDongBo.dungChung.dangXuat()
            (UIApplication.shared.delegate as? UyQuyenUngDung)?.hienThiDangNhap()
        })
        hoi.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        present(hoi, animated: true)
    }

    @objc private func moQuanLyTaiKhoan() {
        let tk = DichVuDongBo.dungChung.tenDangNhap.isEmpty ? "Tài khoản" : DichVuDongBo.dungChung.tenDangNhap
        let laAdmin = DichVuDongBo.dungChung.laAdmin
        var cacMuc: [MucChonDMX] = []
        if laAdmin {
            cacMuc.append(MucChonDMX(tieuDe: "🛡️ Quản lý tài khoản & Phân quyền Admin") { [weak self] in
                self?.bamMoManHinhAdminTaiKhoan()
            })
        }
        cacMuc.append(MucChonDMX(tieuDe: "🔑 Đổi mật khẩu tài khoản \(tk)") { [weak self] in
            self?.bamDoiMatKhauCaNhan()
        })
        cacMuc.append(MucChonDMX(tieuDe: "🔄 Đồng bộ dữ liệu ngay") {
            DichVuDongBo.dungChung.taiDuLieu()
        })
        cacMuc.append(MucChonDMX(tieuDe: "🚪 Đăng xuất tài khoản", kieu: .nguyHiem) {
            DichVuDongBo.dungChung.dangXuat()
            (UIApplication.shared.delegate as? UyQuyenUngDung)?.hienThiDangNhap()
        })
        cacMuc.append(MucChonDMX(tieuDe: "Đóng", kieu: .huy))

        hienMenuChon(
            tieuDe: "Tài khoản ĐMX: \(tk) \(laAdmin ? "(Admin)" : "")",
            thongDiep: "Dữ liệu được đồng bộ tự động với nhánh duongnt.io.vn/dmx.",
            cacMuc: cacMuc
        )
    }

    private func hienThongBao(tieuDe: String, noiDung: String) {
        let tb = UIAlertController(title: tieuDe, message: noiDung, preferredStyle: .alert)
        tb.addAction(UIAlertAction(title: "Đóng", style: .default))
        present(tb, animated: true)
    }

    private func dongBoTamCaiDat() {
        if let dangGo = oNhapCumTu.text?.trimmingCharacters(in: .whitespacesAndNewlines), !dangGo.isEmpty {
            if !danhSachCumTu.contains(where: { $0.caseInsensitiveCompare(dangGo) == .orderedSame }) {
                danhSachCumTu.insert(dangGo, at: 0)
            }
            oNhapCumTu.text = ""
        }

        let kieu = KieuHienThiBaoCao(rawValue: chonKieuHienThi.selectedSegmentIndex) ?? .bangChiTiet
        let soCot = chonSoCotXuat.selectedSegmentIndex + 1
        let keyGemini = (oNhapGeminiKey.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        var moi = KhoDuLieu.dungChung.caiDat
        moi.kieuHienThi = kieu
        moi.danhSachCumTuLocBo = danhSachCumTu
        moi.soCotXuatAnh = soCot
        moi.geminiApiKey = keyGemini.isEmpty ? DichVuGeminiAI.khoaMacDinh : keyGemini
        moi.geminiModel = modelGeminiDangChon
        KhoDuLieu.dungChung.luuCaiDat(moi)
    }

    @objc private func moChiaTarget() {
        dongBoTamCaiDat()
        navigationController?.pushViewController(ManHinhChiaTarget(ngay: ngay), animated: true)
    }

    @objc private func moQuanLyNhanVien() {
        dongBoTamCaiDat()
        navigationController?.pushViewController(ManHinhQuanLyNhanVien(), animated: true)
    }

    private func taoGiaoDien() {
        let cuon = UIScrollView()
        cuon.alwaysBounceVertical = true
        cuon.keyboardDismissMode = .interactive
        cuon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cuon)

        let nganTong = UIStackView()
        nganTong.axis = .vertical
        nganTong.spacing = 10
        nganTong.translatesAutoresizingMaskIntoConstraints = false
        cuon.addSubview(nganTong)

        // 0. KHUNG CÀI ĐẶT GOOGLE GEMINI AI (MIỄN PHÍ)
        let tieuDeGemini = taoTieuDeNhom("🤖 TRÍ TUỆ NHÂN TẠO GOOGLE GEMINI (MIỄN PHÍ — PHÂN TÍCH BÁO CÁO)")
        let khungGemini = UIView()
        khungGemini.backgroundColor = BangMauBCTD.nenThe
        khungGemini.layer.cornerRadius = 12
        khungGemini.layer.borderWidth = 1.2
        khungGemini.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor

        let nhanMoTaGemini = UILabel()
        nhanMoTaGemini.text = "Nhập Google Gemini API Key để phân tích số liệu và viết báo cáo tự động. Ứng dụng sử dụng dòng model Gemini Flash miễn phí (Free Tier) không bị tính phí, đã tích hợp sẵn Key mặc định bên dưới:"
        nhanMoTaGemini.font = .systemFont(ofSize: 13.0, weight: .medium)
        nhanMoTaGemini.textColor = BangMauBCTD.chuPhu
        nhanMoTaGemini.numberOfLines = 0
        nhanMoTaGemini.lineBreakMode = .byWordWrapping
        nhanMoTaGemini.adjustsFontSizeToFitWidth = false

        oNhapGeminiKey.placeholder = "Nhập Google Gemini API Key (AIzaSy...)"
        oNhapGeminiKey.borderStyle = .roundedRect
        oNhapGeminiKey.font = .monospacedSystemFont(ofSize: 13.0, weight: .semibold)
        oNhapGeminiKey.textColor = BangMauBCTD.chuChinh
        oNhapGeminiKey.backgroundColor = BangMauBCTD.nenThePhu
        oNhapGeminiKey.clearButtonMode = .whileEditing
        oNhapGeminiKey.autocapitalizationType = .none
        oNhapGeminiKey.autocorrectionType = .no
        oNhapGeminiKey.returnKeyType = .done
        oNhapGeminiKey.delegate = self

        nutChonModelGemini.titleLabel?.font = .systemFont(ofSize: 13.0, weight: .bold)
        nutChonModelGemini.titleLabel?.numberOfLines = 0
        nutChonModelGemini.titleLabel?.lineBreakMode = .byWordWrapping
        nutChonModelGemini.titleLabel?.adjustsFontSizeToFitWidth = false
        nutChonModelGemini.contentHorizontalAlignment = .left
        nutChonModelGemini.backgroundColor = BangMauBCTD.nenHeaderBang
        nutChonModelGemini.tintColor = BangMauBCTD.xanhChuDaoDam
        nutChonModelGemini.layer.cornerRadius = 9
        nutChonModelGemini.layer.borderWidth = 1
        nutChonModelGemini.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
        nutChonModelGemini.contentEdgeInsets = UIEdgeInsets(top: 9, left: 10, bottom: 9, right: 10)
        nutChonModelGemini.addTarget(self, action: #selector(bamChonModelGemini), for: .touchUpInside)

        nutKiemTraKeyGemini.setTitle("🔍 Kiểm tra & Dùng thử Key Gemini ngay", for: .normal)
        nutKiemTraKeyGemini.titleLabel?.font = .systemFont(ofSize: 13.5, weight: .bold)
        nutKiemTraKeyGemini.titleLabel?.numberOfLines = 0
        nutKiemTraKeyGemini.titleLabel?.lineBreakMode = .byWordWrapping
        nutKiemTraKeyGemini.titleLabel?.textAlignment = .center
        nutKiemTraKeyGemini.titleLabel?.adjustsFontSizeToFitWidth = false
        nutKiemTraKeyGemini.backgroundColor = BangMauBCTD.xanhChuDao
        nutKiemTraKeyGemini.tintColor = .white
        nutKiemTraKeyGemini.setTitleColor(.white, for: .normal)
        nutKiemTraKeyGemini.layer.cornerRadius = 10
        nutKiemTraKeyGemini.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        nutKiemTraKeyGemini.addTarget(self, action: #selector(bamKiemTraKeyGemini), for: .touchUpInside)

        nutKhoiPhucKeyMacDinh.setTitle("↺ Khôi phục & Dùng thử Key mặc định", for: .normal)
        nutKhoiPhucKeyMacDinh.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        nutKhoiPhucKeyMacDinh.titleLabel?.numberOfLines = 0
        nutKhoiPhucKeyMacDinh.titleLabel?.lineBreakMode = .byWordWrapping
        nutKhoiPhucKeyMacDinh.titleLabel?.textAlignment = .center
        nutKhoiPhucKeyMacDinh.titleLabel?.adjustsFontSizeToFitWidth = false
        nutKhoiPhucKeyMacDinh.backgroundColor = BangMauBCTD.vangSang
        nutKhoiPhucKeyMacDinh.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
        nutKhoiPhucKeyMacDinh.layer.cornerRadius = 9
        nutKhoiPhucKeyMacDinh.layer.borderWidth = 1
        nutKhoiPhucKeyMacDinh.layer.borderColor = BangMauBCTD.vangChuDao.cgColor
        nutKhoiPhucKeyMacDinh.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        nutKhoiPhucKeyMacDinh.addTarget(self, action: #selector(bamKhoiPhucKeyMacDinh), for: .touchUpInside)

        nhanTrangThaiGemini.text = "✅ Đã nạp sẵn Key mặc định (AIzaSyBLV7N_qUxSuiJ3B3FETmj2Ta67CKeVKWo). Bấm nút kiểm tra bên trên để test trực tiếp."
        nhanTrangThaiGemini.font = .systemFont(ofSize: 12.5, weight: .semibold)
        nhanTrangThaiGemini.textColor = BangMauBCTD.xanhLaDam
        nhanTrangThaiGemini.numberOfLines = 0
        nhanTrangThaiGemini.lineBreakMode = .byWordWrapping
        nhanTrangThaiGemini.adjustsFontSizeToFitWidth = false

        let nganGemini = UIStackView(arrangedSubviews: [
            nhanMoTaGemini,
            oNhapGeminiKey,
            nutChonModelGemini,
            nutKiemTraKeyGemini,
            nutKhoiPhucKeyMacDinh,
            nhanTrangThaiGemini
        ])
        nganGemini.axis = .vertical
        nganGemini.spacing = 8
        nganGemini.translatesAutoresizingMaskIntoConstraints = false
        khungGemini.addSubview(nganGemini)

        // 1. HỘP THƯ & ĐỒNG BỘ
        let tieuDeHopThu = taoTieuDeNhom("📬 HỘP THƯ & THÔNG BÁO HỆ THỐNG")
        let khungHopThu = UIView()
        khungHopThu.backgroundColor = BangMauBCTD.nenThe
        khungHopThu.layer.cornerRadius = 12
        khungHopThu.layer.borderWidth = 1
        khungHopThu.layer.borderColor = BangMauBCTD.vienThe.cgColor

        nhanHopThuThongBao.font = .systemFont(ofSize: 13, weight: .medium)
        nhanHopThuThongBao.textColor = BangMauBCTD.chuChinh
        nhanHopThuThongBao.numberOfLines = 0
        nhanHopThuThongBao.lineBreakMode = .byWordWrapping
        nhanHopThuThongBao.adjustsFontSizeToFitWidth = false

        nutDongBoNgay.setTitle("🔄 Đồng bộ dữ liệu đám mây ngay", for: .normal)
        nutDongBoNgay.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        nutDongBoNgay.titleLabel?.numberOfLines = 0
        nutDongBoNgay.titleLabel?.lineBreakMode = .byWordWrapping
        nutDongBoNgay.titleLabel?.adjustsFontSizeToFitWidth = false
        nutDongBoNgay.backgroundColor = BangMauBCTD.nenHeaderBang
        nutDongBoNgay.tintColor = BangMauBCTD.xanhChuDao
        nutDongBoNgay.layer.cornerRadius = 9
        nutDongBoNgay.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        nutDongBoNgay.addTarget(self, action: #selector(bamDongBoDamMayNgay), for: .touchUpInside)

        let nganHopThu = UIStackView(arrangedSubviews: [nhanHopThuThongBao, nutDongBoNgay])
        nganHopThu.axis = .vertical
        nganHopThu.spacing = 8
        nganHopThu.translatesAutoresizingMaskIntoConstraints = false
        khungHopThu.addSubview(nganHopThu)

        let tieuDeTK = taoTieuDeNhom("👤 TÀI KHOẢN & CÀI ĐẶT HỆ THỐNG")
        let khungTK = UIView()
        khungTK.backgroundColor = BangMauBCTD.nenThe
        khungTK.layer.cornerRadius = 12
        khungTK.layer.borderWidth = 1
        khungTK.layer.borderColor = BangMauBCTD.vienThe.cgColor

        nhanThongTinTaiKhoan.font = .systemFont(ofSize: 13.5, weight: .bold)
        nhanThongTinTaiKhoan.textColor = BangMauBCTD.chuChinh
        nhanThongTinTaiKhoan.numberOfLines = 0
        nhanThongTinTaiKhoan.lineBreakMode = .byWordWrapping
        nhanThongTinTaiKhoan.adjustsFontSizeToFitWidth = false

        nutMoAdminTaiKhoan.setTitle("🛡️ Quản lý Tài khoản (Thêm mới, Đổi mật khẩu, Set quyền Admin) ▸", for: .normal)
        nutMoAdminTaiKhoan.titleLabel?.font = .systemFont(ofSize: 13.5, weight: .bold)
        nutMoAdminTaiKhoan.titleLabel?.numberOfLines = 0
        nutMoAdminTaiKhoan.titleLabel?.lineBreakMode = .byWordWrapping
        nutMoAdminTaiKhoan.titleLabel?.adjustsFontSizeToFitWidth = false
        nutMoAdminTaiKhoan.contentHorizontalAlignment = .left
        nutMoAdminTaiKhoan.backgroundColor = BangMauBCTD.nenHeaderBang
        nutMoAdminTaiKhoan.tintColor = BangMauBCTD.xanhChuDao
        nutMoAdminTaiKhoan.layer.cornerRadius = 10
        nutMoAdminTaiKhoan.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        nutMoAdminTaiKhoan.addTarget(self, action: #selector(bamMoManHinhAdminTaiKhoan), for: .touchUpInside)

        nutDoiMatKhauNhanh.setTitle("🔑 Đổi mật khẩu", for: .normal)
        nutDoiMatKhauNhanh.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        nutDoiMatKhauNhanh.titleLabel?.numberOfLines = 0
        nutDoiMatKhauNhanh.titleLabel?.lineBreakMode = .byWordWrapping
        nutDoiMatKhauNhanh.titleLabel?.adjustsFontSizeToFitWidth = false
        nutDoiMatKhauNhanh.backgroundColor = BangMauBCTD.nenThePhu
        nutDoiMatKhauNhanh.tintColor = BangMauBCTD.chuChinh
        nutDoiMatKhauNhanh.layer.cornerRadius = 9
        nutDoiMatKhauNhanh.layer.borderWidth = 1
        nutDoiMatKhauNhanh.layer.borderColor = BangMauBCTD.vienDam.cgColor
        nutDoiMatKhauNhanh.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        nutDoiMatKhauNhanh.addTarget(self, action: #selector(bamDoiMatKhauCaNhan), for: .touchUpInside)

        nutDangXuatNhanh.setTitle("🚪 Đăng xuất", for: .normal)
        nutDangXuatNhanh.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        nutDangXuatNhanh.titleLabel?.numberOfLines = 0
        nutDangXuatNhanh.titleLabel?.lineBreakMode = .byWordWrapping
        nutDangXuatNhanh.titleLabel?.adjustsFontSizeToFitWidth = false
        nutDangXuatNhanh.backgroundColor = BangMauBCTD.doYeuPill
        nutDangXuatNhanh.tintColor = BangMauBCTD.doYeuChu
        nutDangXuatNhanh.layer.cornerRadius = 9
        nutDangXuatNhanh.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        nutDangXuatNhanh.addTarget(self, action: #selector(bamDangXuatTaiKhoan), for: .touchUpInside)

        let hangNutTK = UIStackView(arrangedSubviews: [nutDoiMatKhauNhanh, nutDangXuatNhanh])
        hangNutTK.axis = .horizontal
        hangNutTK.spacing = 8
        hangNutTK.distribution = .fillEqually

        let nganTK = UIStackView(arrangedSubviews: [nhanThongTinTaiKhoan, nutMoAdminTaiKhoan, hangNutTK])
        nganTK.axis = .vertical
        nganTK.spacing = 8
        nganTK.translatesAutoresizingMaskIntoConstraints = false
        khungTK.addSubview(nganTK)

        let tieuDeNV = taoTieuDeNhom("1 & 2. CHIA TARGET MẶT HÀNG & QUẢN LÝ NHÂN VIÊN")
        let khungNV = UIView()
        khungNV.backgroundColor = BangMauBCTD.nenThe
        khungNV.layer.cornerRadius = 12
        khungNV.layer.borderWidth = 1
        khungNV.layer.borderColor = BangMauBCTD.vienThe.cgColor

        [nutChiaTarget, nutQuanLyNV].forEach { nut in
            nut.titleLabel?.numberOfLines = 0
            nut.titleLabel?.lineBreakMode = .byWordWrapping
            nut.titleLabel?.adjustsFontSizeToFitWidth = false
            nut.titleLabel?.textAlignment = .left
            nut.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
            nut.contentHorizontalAlignment = .left
            nut.backgroundColor = BangMauBCTD.nenHeaderBang
            nut.tintColor = BangMauBCTD.xanhChuDaoDam
            nut.layer.cornerRadius = 10
            nut.layer.borderWidth = 1
            nut.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
            nut.contentEdgeInsets = UIEdgeInsets(top: 11, left: 12, bottom: 11, right: 12)
        }
        nutChiaTarget.addTarget(self, action: #selector(moChiaTarget), for: .touchUpInside)
        nutQuanLyNV.addTarget(self, action: #selector(moQuanLyNhanVien), for: .touchUpInside)

        let nganNV = UIStackView(arrangedSubviews: [nutChiaTarget, nutQuanLyNV])
        nganNV.axis = .vertical
        nganNV.spacing = 8
        nganNV.translatesAutoresizingMaskIntoConstraints = false
        khungNV.addSubview(nganNV)

        let tieuDeKieu = taoTieuDeNhom("3. KIỂU HIỂN THỊ & XUẤT BÁO CÁO")
        let khungKieu = UIView()
        khungKieu.backgroundColor = BangMauBCTD.nenThe
        khungKieu.layer.cornerRadius = 12
        khungKieu.layer.borderWidth = 1
        khungKieu.layer.borderColor = BangMauBCTD.vienThe.cgColor

        let nhanMoTaKieu = UILabel()
        nhanMoTaKieu.text = "Chọn 1 trong 2 mẫu hiển thị trên màn hình và khi xuất ảnh:"
        nhanMoTaKieu.font = .systemFont(ofSize: 13)
        nhanMoTaKieu.textColor = BangMauBCTD.chuPhu
        nhanMoTaKieu.numberOfLines = 0
        nhanMoTaKieu.lineBreakMode = .byWordWrapping
        nhanMoTaKieu.adjustsFontSizeToFitWidth = false

        let nhanMoTaCot = UILabel()
        nhanMoTaCot.text = "Số cột khi xuất ảnh (áp dụng cho mẫu Thẻ tiến độ):"
        nhanMoTaCot.font = .systemFont(ofSize: 13)
        nhanMoTaCot.textColor = BangMauBCTD.chuPhu
        nhanMoTaCot.numberOfLines = 0
        nhanMoTaCot.lineBreakMode = .byWordWrapping
        nhanMoTaCot.adjustsFontSizeToFitWidth = false

        [chonKieuHienThi, chonSoCotXuat].forEach { seg in
            seg.backgroundColor = BangMauBCTD.nenThePhu
            seg.selectedSegmentTintColor = BangMauBCTD.vangSang
            seg.setTitleTextAttributes([
                .font: UIFont.systemFont(ofSize: 12.0, weight: .semibold),
                .foregroundColor: BangMauBCTD.chuPhu
            ], for: .normal)
            seg.setTitleTextAttributes([
                .font: UIFont.systemFont(ofSize: 12.0, weight: .bold),
                .foregroundColor: BangMauBCTD.chuChinh
            ], for: .selected)
            seg.damBaoHienThiDayDuText()
        }

        let nganKieu = UIStackView(arrangedSubviews: [nhanMoTaKieu, chonKieuHienThi, nhanMoTaCot, chonSoCotXuat])
        nganKieu.axis = .vertical
        nganKieu.spacing = 8
        nganKieu.translatesAutoresizingMaskIntoConstraints = false
        khungKieu.addSubview(nganKieu)

        let tieuDeLoc = taoTieuDeNhom("4. CỤM TỪ LỌC BỎ TRONG TẤT CẢ NGÀNH HÀNG")
        let khungLoc = UIView()
        khungLoc.backgroundColor = BangMauBCTD.nenThe
        khungLoc.layer.cornerRadius = 12
        khungLoc.layer.borderWidth = 1
        khungLoc.layer.borderColor = BangMauBCTD.vienThe.cgColor
        khungLoc.clipsToBounds = true

        oNhapCumTu.placeholder = "Nhập cụm từ muốn lọc bỏ (VD: 275 Quang Trung)"
        oNhapCumTu.borderStyle = .roundedRect
        oNhapCumTu.font = .systemFont(ofSize: 14)
        oNhapCumTu.clearButtonMode = .whileEditing
        oNhapCumTu.returnKeyType = .done
        oNhapCumTu.delegate = self

        let nutThem = UIButton(type: .system)
        nutThem.setTitle(" + Thêm ", for: .normal)
        nutThem.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        nutThem.titleLabel?.numberOfLines = 0
        nutThem.titleLabel?.lineBreakMode = .byWordWrapping
        nutThem.titleLabel?.adjustsFontSizeToFitWidth = false
        nutThem.backgroundColor = BangMauBCTD.xanhChuDao
        nutThem.tintColor = .white
        nutThem.layer.cornerRadius = 8
        nutThem.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        nutThem.addTarget(self, action: #selector(bamThemCumTu), for: .touchUpInside)
        nutThem.setContentHuggingPriority(.required, for: .horizontal)

        let hangNhap = UIStackView(arrangedSubviews: [oNhapCumTu, nutThem])
        hangNhap.axis = .horizontal
        hangNhap.spacing = 8

        let vachNgan = UIView()
        vachNgan.backgroundColor = BangMauBCTD.vienThe

        bangCumTu.dataSource = self
        bangCumTu.delegate = self
        bangCumTu.rowHeight = UITableView.automaticDimension
        bangCumTu.estimatedRowHeight = 44
        bangCumTu.backgroundColor = .clear
        bangCumTu.separatorInset = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)

        [hangNhap, vachNgan, bangCumTu].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            khungLoc.addSubview($0)
        }

        [
            tieuDeGemini, khungGemini,
            tieuDeNV, khungNV,
            tieuDeKieu, khungKieu,
            tieuDeLoc, khungLoc,
            tieuDeHopThu, khungHopThu,
            tieuDeTK, khungTK
        ].forEach {
            nganTong.addArrangedSubview($0)
        }

        NSLayoutConstraint.activate([
            cuon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cuon.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cuon.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cuon.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            nganTong.topAnchor.constraint(equalTo: cuon.contentLayoutGuide.topAnchor, constant: 10),
            nganTong.leadingAnchor.constraint(equalTo: cuon.contentLayoutGuide.leadingAnchor, constant: 14),
            nganTong.trailingAnchor.constraint(equalTo: cuon.contentLayoutGuide.trailingAnchor, constant: -14),
            nganTong.bottomAnchor.constraint(equalTo: cuon.contentLayoutGuide.bottomAnchor, constant: -16),
            nganTong.widthAnchor.constraint(equalTo: cuon.frameLayoutGuide.widthAnchor, constant: -28),

            nganGemini.topAnchor.constraint(equalTo: khungGemini.topAnchor, constant: 12),
            nganGemini.leadingAnchor.constraint(equalTo: khungGemini.leadingAnchor, constant: 12),
            nganGemini.trailingAnchor.constraint(equalTo: khungGemini.trailingAnchor, constant: -12),
            nganGemini.bottomAnchor.constraint(equalTo: khungGemini.bottomAnchor, constant: -12),

            nganHopThu.topAnchor.constraint(equalTo: khungHopThu.topAnchor, constant: 10),
            nganHopThu.leadingAnchor.constraint(equalTo: khungHopThu.leadingAnchor, constant: 12),
            nganHopThu.trailingAnchor.constraint(equalTo: khungHopThu.trailingAnchor, constant: -12),
            nganHopThu.bottomAnchor.constraint(equalTo: khungHopThu.bottomAnchor, constant: -10),

            nganTK.topAnchor.constraint(equalTo: khungTK.topAnchor, constant: 10),
            nganTK.leadingAnchor.constraint(equalTo: khungTK.leadingAnchor, constant: 12),
            nganTK.trailingAnchor.constraint(equalTo: khungTK.trailingAnchor, constant: -12),
            nganTK.bottomAnchor.constraint(equalTo: khungTK.bottomAnchor, constant: -10),

            nganNV.topAnchor.constraint(equalTo: khungNV.topAnchor, constant: 10),
            nganNV.leadingAnchor.constraint(equalTo: khungNV.leadingAnchor, constant: 10),
            nganNV.trailingAnchor.constraint(equalTo: khungNV.trailingAnchor, constant: -10),
            nganNV.bottomAnchor.constraint(equalTo: khungNV.bottomAnchor, constant: -10),

            nganKieu.topAnchor.constraint(equalTo: khungKieu.topAnchor, constant: 10),
            nganKieu.leadingAnchor.constraint(equalTo: khungKieu.leadingAnchor, constant: 12),
            nganKieu.trailingAnchor.constraint(equalTo: khungKieu.trailingAnchor, constant: -12),
            nganKieu.bottomAnchor.constraint(equalTo: khungKieu.bottomAnchor, constant: -10),

            hangNhap.topAnchor.constraint(equalTo: khungLoc.topAnchor, constant: 10),
            hangNhap.leadingAnchor.constraint(equalTo: khungLoc.leadingAnchor, constant: 12),
            hangNhap.trailingAnchor.constraint(equalTo: khungLoc.trailingAnchor, constant: -12),

            vachNgan.topAnchor.constraint(equalTo: hangNhap.bottomAnchor, constant: 10),
            vachNgan.leadingAnchor.constraint(equalTo: khungLoc.leadingAnchor),
            vachNgan.trailingAnchor.constraint(equalTo: khungLoc.trailingAnchor),
            vachNgan.heightAnchor.constraint(equalToConstant: 0.5),

            bangCumTu.topAnchor.constraint(equalTo: vachNgan.bottomAnchor),
            bangCumTu.leadingAnchor.constraint(equalTo: khungLoc.leadingAnchor),
            bangCumTu.trailingAnchor.constraint(equalTo: khungLoc.trailingAnchor),
            bangCumTu.bottomAnchor.constraint(equalTo: khungLoc.bottomAnchor),
            bangCumTu.heightAnchor.constraint(equalToConstant: 210)
        ])
    }

    @objc private func bamThemCumTu() {
        let chu = oNhapCumTu.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !chu.isEmpty else { return }
        if !danhSachCumTu.contains(where: { $0.caseInsensitiveCompare(chu) == .orderedSame }) {
            danhSachCumTu.insert(chu, at: 0)
            bangCumTu.reloadData()
        }
        oNhapCumTu.text = ""
        dongBoTamCaiDat()
        khiThayDoiCaiDat?()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === oNhapGeminiKey {
            dongBoTamCaiDat()
            textField.resignFirstResponder()
            return true
        }
        bamThemCumTu()
        textField.resignFirstResponder()
        return true
    }

    @objc private func luuCaiDat() {
        dongBoTamCaiDat()
        khiThayDoiCaiDat?()
        navigationController?.popViewController(animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(1, danhSachCumTu.count)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ma = "CumTuLocCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: ma) ?? UITableViewCell(style: .value1, reuseIdentifier: ma)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.adjustsFontSizeToFitWidth = false

        if danhSachCumTu.isEmpty {
            cell.textLabel?.text = "Chưa có cụm từ lọc bỏ nào"
            cell.textLabel?.textColor = BangMauBCTD.chuMo
            cell.textLabel?.font = .systemFont(ofSize: 13)
            cell.detailTextLabel?.text = nil
            cell.accessoryView = nil
        } else {
            let cumTu = danhSachCumTu[indexPath.row]
            cell.textLabel?.text = "\"\(cumTu)\""
            cell.textLabel?.textColor = BangMauBCTD.chuChinh
            cell.textLabel?.font = .systemFont(ofSize: 14, weight: .semibold)

            let nutXoa = UIButton(type: .system)
            nutXoa.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            nutXoa.tintColor = BangMauBCTD.doYeuChu
            nutXoa.tag = indexPath.row
            nutXoa.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
            nutXoa.addTarget(self, action: #selector(xoaCumTuTai(_:)), for: .touchUpInside)
            cell.accessoryView = nutXoa
        }
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !danhSachCumTu.isEmpty else { return nil }
        let xoa = UIContextualAction(style: .destructive, title: "Xoá") { [weak self] _, _, hoanTat in
            self?.danhSachCumTu.remove(at: indexPath.row)
            self?.bangCumTu.reloadData()
            hoanTat(true)
        }
        return UISwipeActionsConfiguration(actions: [xoa])
    }

    @objc private func xoaCumTuTai(_ sender: UIButton) {
        let idx = sender.tag
        guard idx >= 0 && idx < danhSachCumTu.count else { return }
        danhSachCumTu.remove(at: idx)
        bangCumTu.reloadData()
        dongBoTamCaiDat()
        khiThayDoiCaiDat?()
    }

    private func taoTieuDeNhom(_ chu: String) -> UILabel {
        let nhan = UILabel()
        nhan.text = chu
        nhan.font = .systemFont(ofSize: 12.0, weight: .heavy)
        nhan.textColor = BangMauBCTD.xanhChuDaoDam
        nhan.numberOfLines = 0
        nhan.lineBreakMode = .byWordWrapping
        nhan.adjustsFontSizeToFitWidth = false
        return nhan
    }
}

// MARK: - Màn hình Quản trị Tài khoản (Dành cho Admin)

final class ManHinhQuanLyTaiKhoan: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private var danhSach: [ThongTinTaiKhoanDMX] = []
    private let nhanTomTat = UILabel()
    private let nutThemTaiKhoan = UIButton(type: .system)
    private let bang = UITableView(frame: .zero, style: .insetGrouped)
    private let vongQuay = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Quản lý Tài khoản"
        view.backgroundColor = BangMauBCTD.nenTrang

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(bamThemTaiKhoanMoi)),
            UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(taiDanhSach))
        ]

        taoGiaoDien()
        taiDanhSach()
    }

    private func taoGiaoDien() {
        let khungDau = UIView()
        khungDau.backgroundColor = BangMauBCTD.nenThe
        khungDau.layer.cornerRadius = 12
        khungDau.layer.borderWidth = 1
        khungDau.layer.borderColor = BangMauBCTD.vienThe.cgColor

        nhanTomTat.font = .systemFont(ofSize: 13, weight: .semibold)
        nhanTomTat.textColor = BangMauBCTD.chuChinh
        nhanTomTat.numberOfLines = 0
        nhanTomTat.lineBreakMode = .byWordWrapping
        nhanTomTat.adjustsFontSizeToFitWidth = false
        nhanTomTat.text = "Chạm vào từng tài khoản bên dưới để Đổi mật khẩu, Set/Gỡ quyền Admin hoặc Xoá."

        nutThemTaiKhoan.setImage(UIImage(systemName: "person.badge.plus"), for: .normal)
        nutThemTaiKhoan.setTitle(" Thêm tài khoản mới", for: .normal)
        nutThemTaiKhoan.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        nutThemTaiKhoan.titleLabel?.numberOfLines = 0
        nutThemTaiKhoan.titleLabel?.lineBreakMode = .byWordWrapping
        nutThemTaiKhoan.titleLabel?.adjustsFontSizeToFitWidth = false
        nutThemTaiKhoan.backgroundColor = BangMauBCTD.xanhChuDao
        nutThemTaiKhoan.tintColor = .white
        nutThemTaiKhoan.layer.cornerRadius = 9
        nutThemTaiKhoan.contentEdgeInsets = UIEdgeInsets(top: 9, left: 10, bottom: 9, right: 10)
        nutThemTaiKhoan.addTarget(self, action: #selector(bamThemTaiKhoanMoi), for: .touchUpInside)

        let nganDau = UIStackView(arrangedSubviews: [nhanTomTat, nutThemTaiKhoan, vongQuay])
        nganDau.axis = .vertical
        nganDau.spacing = 8
        nganDau.translatesAutoresizingMaskIntoConstraints = false
        khungDau.addSubview(nganDau)

        bang.dataSource = self
        bang.delegate = self
        bang.rowHeight = UITableView.automaticDimension
        bang.estimatedRowHeight = 64

        [khungDau, bang].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            khungDau.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            khungDau.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            khungDau.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),

            nganDau.topAnchor.constraint(equalTo: khungDau.topAnchor, constant: 12),
            nganDau.leadingAnchor.constraint(equalTo: khungDau.leadingAnchor, constant: 12),
            nganDau.trailingAnchor.constraint(equalTo: khungDau.trailingAnchor, constant: -12),
            nganDau.bottomAnchor.constraint(equalTo: khungDau.bottomAnchor, constant: -12),

            bang.topAnchor.constraint(equalTo: khungDau.bottomAnchor, constant: 6),
            bang.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bang.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bang.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func taiDanhSach() {
        vongQuay.startAnimating()
        DichVuDongBo.dungChung.layDanhSachTaiKhoan { [weak self] kq in
            guard let self else { return }
            self.vongQuay.stopAnimating()
            switch kq {
            case .success(let ds):
                self.danhSach = ds
                let soAdmin = ds.filter(\.laAdmin).count
                let soThuong = ds.count - soAdmin
                self.nhanTomTat.text = "Tổng: \(ds.count) tài khoản (\(soAdmin) Admin, \(soThuong) tài khoản thường).\nChạm vào tài khoản bên dưới để Đổi mật khẩu, Set quyền Admin hoặc Xoá."
                self.bang.reloadData()
            case .failure(let loi):
                self.hienThongBao(tieuDe: "Lỗi tải danh sách", noiDung: loi.localizedDescription)
            }
        }
    }

    @objc private func bamThemTaiKhoanMoi() {
        let hop = UIAlertController(
            title: "➕ Thêm tài khoản mới",
            message: "Nhập tên đăng nhập (3–40 ký tự) và mật khẩu (tối thiểu 6 ký tự):",
            preferredStyle: .alert
        )
        hop.addTextField { tf in
            tf.placeholder = "Tên đăng nhập"
            tf.autocapitalizationType = .none
            tf.autocorrectionType = .no
        }
        hop.addTextField { tf in
            tf.placeholder = "Mật khẩu (tối thiểu 6 ký tự)"
            tf.isSecureTextEntry = true
        }
        hop.addAction(UIAlertAction(title: "👤 Tạo Tài khoản thường", style: .default) { [weak self] _ in
            self?.thucHienTaoTaiKhoan(hop: hop, laAdmin: false)
        })
        hop.addAction(UIAlertAction(title: "🛡️ Tạo & Set quyền Admin", style: .default) { [weak self] _ in
            self?.thucHienTaoTaiKhoan(hop: hop, laAdmin: true)
        })
        hop.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        present(hop, animated: true)
    }

    private func thucHienTaoTaiKhoan(hop: UIAlertController, laAdmin: Bool) {
        guard let tfs = hop.textFields, tfs.count >= 2 else { return }
        let ten = (tfs[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let mk = tfs[1].text ?? ""
        vongQuay.startAnimating()
        DichVuDongBo.dungChung.adminTaoTaiKhoanMoi(tenDangNhap: ten, matKhau: mk, laAdmin: laAdmin) { [weak self] kq in
            guard let self else { return }
            self.vongQuay.stopAnimating()
            switch kq {
            case .success(let tkMoi):
                self.taiDanhSach()
                self.hienThongBao(
                    tieuDe: "✅ Đã tạo tài khoản",
                    noiDung: "Tài khoản \"\(tkMoi.tenDangNhap)\" (\(tkMoi.laAdmin ? "Admin" : "Tài khoản thường")) đã sẵn sàng đăng nhập."
                )
            case .failure(let loi):
                self.hienThongBao(tieuDe: "Chưa tạo được tài khoản", noiDung: loi.localizedDescription)
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(1, danhSach.count)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "DANH SÁCH TÀI KHOẢN (\(danhSach.count))"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ma = "TaiKhoanAdminCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: ma) ?? UITableViewCell(style: .subtitle, reuseIdentifier: ma)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.adjustsFontSizeToFitWidth = false
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.lineBreakMode = .byWordWrapping
        cell.detailTextLabel?.adjustsFontSizeToFitWidth = false

        guard !danhSach.isEmpty else {
            cell.textLabel?.text = "Đang tải danh sách tài khoản"
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .none
            return cell
        }

        let tk = danhSach[indexPath.row]
        let nhanVaiTro = tk.laAdmin ? "🛡️ ADMIN" : "👤 Tài khoản thường"

        cell.textLabel?.text = "\(tk.tenDangNhap)   •   \(nhanVaiTro)"
        cell.textLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        cell.textLabel?.textColor = tk.laAdmin ? BangMauBCTD.xanhChuDao : BangMauBCTD.chuChinh

        cell.detailTextLabel?.text = "Tạo: \(tk.ngayTao)   •   Đăng nhập cuối: \(tk.dangNhapCuoi)"
        cell.detailTextLabel?.font = .systemFont(ofSize: 12)
        cell.detailTextLabel?.textColor = BangMauBCTD.chuMo
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < danhSach.count else { return }
        let tk = danhSach[indexPath.row]
        moMenuTacVuChoTaiKhoan(tk)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < danhSach.count else { return nil }
        let tk = danhSach[indexPath.row]
        guard !tk.laAdminGoc else { return nil }

        let xoa = UIContextualAction(style: .destructive, title: "Xoá") { [weak self] _, _, hoanTat in
            self?.xacNhanXoaTaiKhoan(tk)
            hoanTat(true)
        }
        let doiMK = UIContextualAction(style: .normal, title: "Đổi MK") { [weak self] _, _, hoanTat in
            self?.moHopThoaiDoiMatKhau(cho: tk)
            hoanTat(true)
        }
        doiMK.backgroundColor = BangMauBCTD.xanhChuDao
        return UISwipeActionsConfiguration(actions: [xoa, doiMK])
    }

    private func moMenuTacVuChoTaiKhoan(_ tk: ThongTinTaiKhoanDMX) {
        let vaiTro = tk.laAdmin ? "Admin" : "Tài khoản thường"
        var cacMuc: [MucChonDMX] = [
            MucChonDMX(tieuDe: "🔑 Đổi mật khẩu cho \"\(tk.tenDangNhap)\"") { [weak self] in
                self?.moHopThoaiDoiMatKhau(cho: tk)
            }
        ]

        if !tk.laAdminGoc {
            if tk.laAdmin {
                cacMuc.append(MucChonDMX(tieuDe: "👤 Gỡ quyền Admin (Chuyển về Tài khoản thường)") { [weak self] in
                    self?.thucHienDoiQuyenAdmin(cho: tk, laAdmin: false)
                })
            } else {
                cacMuc.append(MucChonDMX(tieuDe: "🛡️ Set quyền Admin cho \"\(tk.tenDangNhap)\"") { [weak self] in
                    self?.thucHienDoiQuyenAdmin(cho: tk, laAdmin: true)
                })
            }

            cacMuc.append(MucChonDMX(tieuDe: "🗑️ Xoá tài khoản \"\(tk.tenDangNhap)\"", kieu: .nguyHiem) { [weak self] in
                self?.xacNhanXoaTaiKhoan(tk)
            })
        }
        cacMuc.append(MucChonDMX(tieuDe: "Đóng", kieu: .huy))

        hienMenuChon(
            tieuDe: "Tài khoản: \(tk.tenDangNhap)",
            thongDiep: "Quyền hiện tại: \(vaiTro)",
            cacMuc: cacMuc
        )
    }

    private func moHopThoaiDoiMatKhau(cho tk: ThongTinTaiKhoanDMX) {
        let hop = UIAlertController(
            title: "🔑 Đổi mật khẩu: \(tk.tenDangNhap)",
            message: "Nhập mật khẩu mới cho tài khoản \"\(tk.tenDangNhap)\" (tối thiểu 6 ký tự):",
            preferredStyle: .alert
        )
        hop.addTextField { tf in
            tf.placeholder = "Mật khẩu mới (tối thiểu 6 ký tự)"
            tf.isSecureTextEntry = true
        }
        hop.addAction(UIAlertAction(title: "Lưu mật khẩu mới", style: .default) { [weak self] _ in
            guard let self else { return }
            let mk = hop.textFields?.first?.text ?? ""
            self.vongQuay.startAnimating()
            DichVuDongBo.dungChung.adminDoiMatKhau(userId: tk.id, tenDangNhap: tk.tenDangNhap, matKhauMoi: mk) { [weak self] kq in
                guard let self else { return }
                self.vongQuay.stopAnimating()
                switch kq {
                case .success:
                    self.hienThongBao(tieuDe: "✅ Đã đổi mật khẩu", noiDung: "Đã cập nhật mật khẩu mới cho tài khoản \"\(tk.tenDangNhap)\".")
                case .failure(let loi):
                    self.hienThongBao(tieuDe: "Lỗi đổi mật khẩu", noiDung: loi.localizedDescription)
                }
            }
        })
        hop.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        present(hop, animated: true)
    }

    private func thucHienDoiQuyenAdmin(cho tk: ThongTinTaiKhoanDMX, laAdmin: Bool) {
        vongQuay.startAnimating()
        DichVuDongBo.dungChung.adminDatQuyenAdmin(taiKhoan: tk, laAdmin: laAdmin) { [weak self] kq in
            guard let self else { return }
            self.vongQuay.stopAnimating()
            switch kq {
            case .success:
                self.taiDanhSach()
                self.hienThongBao(
                    tieuDe: "✅ Đã cập nhật quyền",
                    noiDung: laAdmin
                        ? "Đã cấp quyền Admin cho tài khoản \"\(tk.tenDangNhap)\"."
                        : "Đã chuyển \"\(tk.tenDangNhap)\" về Tài khoản thường."
                )
            case .failure(let loi):
                self.hienThongBao(tieuDe: "Không thể đổi quyền", noiDung: loi.localizedDescription)
            }
        }
    }

    private func xacNhanXoaTaiKhoan(_ tk: ThongTinTaiKhoanDMX) {
        guard !tk.laAdminGoc else { return }
        let hoi = UIAlertController(
            title: "Xoá tài khoản \"\(tk.tenDangNhap)\"?",
            message: "Tài khoản này và phiên đăng nhập của nó sẽ bị xoá khỏi hệ thống.",
            preferredStyle: .alert
        )
        hoi.addAction(UIAlertAction(title: "Xoá tài khoản", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.vongQuay.startAnimating()
            DichVuDongBo.dungChung.adminXoaTaiKhoan(taiKhoan: tk) { [weak self] kq in
                guard let self else { return }
                self.vongQuay.stopAnimating()
                switch kq {
                case .success:
                    self.taiDanhSach()
                case .failure(let loi):
                    self.hienThongBao(tieuDe: "Lỗi xoá tài khoản", noiDung: loi.localizedDescription)
                }
            }
        })
        hoi.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        present(hoi, animated: true)
    }

    private func hienThongBao(tieuDe: String, noiDung: String) {
        let tb = UIAlertController(title: tieuDe, message: noiDung, preferredStyle: .alert)
        tb.addAction(UIAlertAction(title: "Đóng", style: .default))
        present(tb, animated: true)
    }
}
