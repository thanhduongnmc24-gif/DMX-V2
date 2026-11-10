import UIKit

// MARK: - Khung Lọc Dữ Liệu Tồn Kho Từ Google Sheet (19 Cột A -> S)

final class KhungLocTonKhoView: UIView, UITextFieldDelegate {
    static let linkSheetMacDinh = "https://docs.google.com/spreadsheets/d/1QiOlw6Rz_9uWrlqiD_VX5-beX_PBDjdo/edit?gid=1060398274#gid=1060398274"
    private static let khoaLuuLinkSheet = "dmx_ton_kho_google_sheet_url_v1"
    private static let khoaLuuMaSieuThi = "dmx_ton_kho_ma_sieu_thi_v1"

    /// 19 cột chuẩn theo thứ tự từ A đến S
    static let tenCacCotChuan: [String] = [
        "Tên siêu thị",                           // A (0)
        "Mã Model",                               // B (1)
        "Mã sản phẩm",                            // C (2)
        "Tên sản phẩm",                           // D (3)
        "Đơn vị",                                 // E (4)
        "Ngành hàng",                             // F (5)
        "Nhóm hàng",                              // G (6)
        "Trạng thái sản phẩm",                    // H (7)
        "Số lượng",                               // I (8)
        "Số lượng không bao gồm hàng đi đường",   // J (9)
        "Số lượng đặt",                           // K (10)
        "Số lượng được chia đến",                 // L (11)
        "Số lượng đang  đi đường",                // M (12)
        "Số lượng được chia đi",                  // N (13)
        "Số lượng đã đặt",                        // O (14)
        "Số lượng có thể bán",                    // P (15)
        "SL tồn kho tối thiểu",                   // Q (16)
        "Có in QR",                               // R (17)
        "Số lượng tồn lô"                         // S (18)
    ]

    static let doRongCacCot: [CGFloat] = [
        175, // A: Tên siêu thị
        115, // B: Mã Model
        120, // C: Mã sản phẩm
        230, // D: Tên sản phẩm
        68,  // E: Đơn vị
        130, // F: Ngành hàng
        145, // G: Nhóm hàng
        145, // H: Trạng thái sản phẩm
        82,  // I: Số lượng
        145, // J: Số lượng không bao gồm hàng đi đường
        92,  // K: Số lượng đặt
        120, // L: Số lượng được chia đến
        125, // M: Số lượng đang  đi đường
        120, // N: Số lượng được chia đi
        100, // O: Số lượng đã đặt
        115, // P: Số lượng có thể bán
        115, // Q: SL tồn kho tối thiểu
        78,  // R: Có in QR
        105  // S: Số lượng tồn lô
    ]

    var khiXuatAnh: ((UIImage) -> Void)?

    private let oLinkSheet = UITextField()
    private let nutTaiSheet = UIButton(type: .system)
    private let oMaSieuThi = UITextField()
    private let nutChonNhomHang = UIButton(type: .system)
    private let nutChonTrangThai = UIButton(type: .system)
    private let nutXuatAnh = UIButton(type: .system)
    private let nhanTrangThai = UILabel()
    private let vongQuay = UIActivityIndicatorView(style: .medium)

    private let cuonNgang = UIScrollView()
    private let cuonDoc = UIScrollView()
    private let nganBang = UIStackView()
    private let khungTrong = UIView()
    private let nhanTrong = UILabel()

    private var tatCaDong: [[String]] = []
    private var dsNhomHang: [String] = []
    private var dsTrangThai: [String] = []
    private var nhomHangDangChon: String? = nil   // nil = chưa chọn; "__ALL__" = tất cả
    private var trangThaiDangChon: String = "__ALL__"
    private var cacDongDaLoc: [[String]] = []
    private var dangTaiSheet = false
    private var daTuDongTaiLanDau = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        taoGiaoDien()
    }

    required init?(coder: NSCoder) {
        fatalError("Khong ho tro coder")
    }

    func kichHoatNeuCan() {
        if !daTuDongTaiLanDau && tatCaDong.isEmpty && !dangTaiSheet {
            daTuDongTaiLanDau = true
            bamTaiSheet()
        }
    }

    private func taoGiaoDien() {
        backgroundColor = BangMauBCTD.nenTrang

        let theBoLoc = UIView()
        theBoLoc.backgroundColor = BangMauBCTD.nenThe
        theBoLoc.layer.cornerRadius = 12
        theBoLoc.layer.borderWidth = 1
        theBoLoc.layer.borderColor = BangMauBCTD.vienThe.cgColor
        theBoLoc.translatesAutoresizingMaskIntoConstraints = false
        addSubview(theBoLoc)

        let lbLink = UILabel()
        lbLink.text = "🔗 LINK GOOGLE SHEET TỒN KHO:"
        lbLink.font = .systemFont(ofSize: 11.5, weight: .heavy)
        lbLink.textColor = BangMauBCTD.xanhChuDaoDam

        let linkLuu = UserDefaults.standard.string(forKey: Self.khoaLuuLinkSheet) ?? Self.linkSheetMacDinh
        oLinkSheet.text = linkLuu.isEmpty ? Self.linkSheetMacDinh : linkLuu
        oLinkSheet.placeholder = "Dán link Google Sheet tồn kho..."
        oLinkSheet.font = .systemFont(ofSize: 12.5, weight: .medium)
        oLinkSheet.textColor = BangMauBCTD.chuChinh
        oLinkSheet.backgroundColor = BangMauBCTD.nenThePhu
        oLinkSheet.layer.cornerRadius = 8
        oLinkSheet.layer.borderWidth = 1
        oLinkSheet.layer.borderColor = BangMauBCTD.vienDam.cgColor
        oLinkSheet.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 1))
        oLinkSheet.leftViewMode = .always
        oLinkSheet.clearButtonMode = .whileEditing
        oLinkSheet.keyboardType = .URL
        oLinkSheet.autocapitalizationType = .none
        oLinkSheet.autocorrectionType = .no
        oLinkSheet.returnKeyType = .go
        oLinkSheet.delegate = self
        oLinkSheet.heightAnchor.constraint(equalToConstant: 34).isActive = true

        nutTaiSheet.setTitle("🔄 Quét Sheet", for: .normal)
        nutTaiSheet.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .heavy)
        nutTaiSheet.backgroundColor = BangMauBCTD.xanhChuDao
        nutTaiSheet.setTitleColor(.white, for: .normal)
        nutTaiSheet.layer.cornerRadius = 8
        nutTaiSheet.contentEdgeInsets = UIEdgeInsets(top: 7, left: 10, bottom: 7, right: 10)
        nutTaiSheet.setContentHuggingPriority(.required, for: .horizontal)
        nutTaiSheet.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutTaiSheet.addTarget(self, action: #selector(bamTaiSheet), for: .touchUpInside)

        let hangLink = UIStackView(arrangedSubviews: [oLinkSheet, nutTaiSheet])
        hangLink.axis = .horizontal
        hangLink.spacing = 6
        hangLink.alignment = .fill

        // Hàng 2: Nhập mã siêu thị (Cột A) + Nút Xuất ảnh
        let lbSieuThi = UILabel()
        lbSieuThi.text = "🏪 Siêu thị (Cột A):"
        lbSieuThi.font = .systemFont(ofSize: 12.0, weight: .bold)
        lbSieuThi.textColor = BangMauBCTD.chuChinh
        lbSieuThi.setContentHuggingPriority(.required, for: .horizontal)

        let maLuu = UserDefaults.standard.string(forKey: Self.khoaLuuMaSieuThi) ?? "76"
        oMaSieuThi.text = maLuu
        oMaSieuThi.placeholder = "VD: 76"
        oMaSieuThi.font = .systemFont(ofSize: 13.5, weight: .bold)
        oMaSieuThi.textColor = BangMauBCTD.xanhChuDaoDam
        oMaSieuThi.backgroundColor = BangMauBCTD.vangNhatNen
        oMaSieuThi.layer.cornerRadius = 8
        oMaSieuThi.layer.borderWidth = 1.2
        oMaSieuThi.layer.borderColor = BangMauBCTD.vangChuDao.cgColor
        oMaSieuThi.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 1))
        oMaSieuThi.leftViewMode = .always
        oMaSieuThi.clearButtonMode = .whileEditing
        oMaSieuThi.returnKeyType = .done
        oMaSieuThi.delegate = self
        oMaSieuThi.addTarget(self, action: #selector(maSieuThiThayDoi), for: .editingChanged)
        oMaSieuThi.heightAnchor.constraint(equalToConstant: 34).isActive = true

        nutXuatAnh.setTitle("🖼️ Xuất ảnh", for: .normal)
        nutXuatAnh.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .heavy)
        nutXuatAnh.backgroundColor = BangMauBCTD.xanhDatVach
        nutXuatAnh.setTitleColor(.white, for: .normal)
        nutXuatAnh.layer.cornerRadius = 8
        nutXuatAnh.contentEdgeInsets = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12)
        nutXuatAnh.setContentHuggingPriority(.required, for: .horizontal)
        nutXuatAnh.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutXuatAnh.addTarget(self, action: #selector(bamXuatAnhBang), for: .touchUpInside)

        let hangSieuThi = UIStackView(arrangedSubviews: [lbSieuThi, oMaSieuThi, nutXuatAnh])
        hangSieuThi.axis = .horizontal
        hangSieuThi.spacing = 6
        hangSieuThi.alignment = .center

        // Hàng 3: Combobox Nhóm hàng (Cột G) & Trạng thái sản phẩm (Cột H)
        cauHinhNutCombobox(nutChonNhomHang, tieuDe: "📂 Nhóm hàng (Cột G): Chưa chọn ▾", laChinh: true)
        cauHinhNutCombobox(nutChonTrangThai, tieuDe: "🏷️ Trạng thái (Cột H): Tất cả ▾", laChinh: false)

        let hangCombo = UIStackView(arrangedSubviews: [nutChonNhomHang, nutChonTrangThai])
        hangCombo.axis = .horizontal
        hangCombo.spacing = 6
        hangCombo.distribution = .fillEqually

        vongQuay.hidesWhenStopped = true
        vongQuay.color = BangMauBCTD.xanhChuDao

        nhanTrangThai.text = "Nhập link Google Sheet, mã siêu thị (VD: 76) rồi chọn Nhóm hàng (Cột G) để hiển thị bảng tồn kho."
        nhanTrangThai.font = .systemFont(ofSize: 11.5, weight: .semibold)
        nhanTrangThai.textColor = BangMauBCTD.chuPhu
        nhanTrangThai.numberOfLines = 0

        let hangTrangThai = UIStackView(arrangedSubviews: [vongQuay, nhanTrangThai])
        hangTrangThai.axis = .horizontal
        hangTrangThai.spacing = 6
        hangTrangThai.alignment = .center

        let nganLoc = UIStackView(arrangedSubviews: [lbLink, hangLink, hangSieuThi, hangCombo, hangTrangThai])
        nganLoc.axis = .vertical
        nganLoc.spacing = 6
        nganLoc.translatesAutoresizingMaskIntoConstraints = false
        theBoLoc.addSubview(nganLoc)

        // Khung bảng 19 cột (A -> S) bên dưới
        let theBang = UIView()
        theBang.backgroundColor = BangMauBCTD.nenThe
        theBang.layer.cornerRadius = 12
        theBang.layer.borderWidth = 1
        theBang.layer.borderColor = BangMauBCTD.vienThe.cgColor
        theBang.clipsToBounds = true
        theBang.translatesAutoresizingMaskIntoConstraints = false
        addSubview(theBang)

        cuonNgang.showsHorizontalScrollIndicator = true
        cuonNgang.bounces = true
        cuonNgang.translatesAutoresizingMaskIntoConstraints = false
        theBang.addSubview(cuonNgang)

        cuonDoc.showsVerticalScrollIndicator = true
        cuonDoc.alwaysBounceVertical = true
        cuonDoc.translatesAutoresizingMaskIntoConstraints = false
        cuonNgang.addSubview(cuonDoc)

        nganBang.axis = .vertical
        nganBang.spacing = 0
        nganBang.alignment = .fill
        nganBang.translatesAutoresizingMaskIntoConstraints = false
        cuonDoc.addSubview(nganBang)

        khungTrong.backgroundColor = BangMauBCTD.nenThe
        khungTrong.translatesAutoresizingMaskIntoConstraints = false
        theBang.addSubview(khungTrong)

        nhanTrong.text = "📦 Hãy bấm “Quét Sheet” và chọn Nhóm hàng (Cột G) trên Combobox để hiển thị bảng dữ liệu tồn kho (19 cột từ A đến S)."
        nhanTrong.font = .systemFont(ofSize: 13.5, weight: .semibold)
        nhanTrong.textColor = BangMauBCTD.chuPhu
        nhanTrong.textAlignment = .center
        nhanTrong.numberOfLines = 0
        nhanTrong.translatesAutoresizingMaskIntoConstraints = false
        khungTrong.addSubview(nhanTrong)

        let tongRongBang = Self.doRongCacCot.reduce(0, +)

        NSLayoutConstraint.activate([
            theBoLoc.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            theBoLoc.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            theBoLoc.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),

            nganLoc.topAnchor.constraint(equalTo: theBoLoc.topAnchor, constant: 8),
            nganLoc.leadingAnchor.constraint(equalTo: theBoLoc.leadingAnchor, constant: 10),
            nganLoc.trailingAnchor.constraint(equalTo: theBoLoc.trailingAnchor, constant: -10),
            nganLoc.bottomAnchor.constraint(equalTo: theBoLoc.bottomAnchor, constant: -8),

            theBang.topAnchor.constraint(equalTo: theBoLoc.bottomAnchor, constant: 6),
            theBang.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            theBang.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            theBang.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),

            cuonNgang.topAnchor.constraint(equalTo: theBang.topAnchor),
            cuonNgang.leadingAnchor.constraint(equalTo: theBang.leadingAnchor),
            cuonNgang.trailingAnchor.constraint(equalTo: theBang.trailingAnchor),
            cuonNgang.bottomAnchor.constraint(equalTo: theBang.bottomAnchor),

            cuonDoc.topAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.topAnchor),
            cuonDoc.leadingAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.leadingAnchor),
            cuonDoc.trailingAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.trailingAnchor),
            cuonDoc.bottomAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.bottomAnchor),
            cuonDoc.heightAnchor.constraint(equalTo: cuonNgang.frameLayoutGuide.heightAnchor),
            cuonDoc.widthAnchor.constraint(equalToConstant: tongRongBang),

            nganBang.topAnchor.constraint(equalTo: cuonDoc.contentLayoutGuide.topAnchor),
            nganBang.leadingAnchor.constraint(equalTo: cuonDoc.contentLayoutGuide.leadingAnchor),
            nganBang.trailingAnchor.constraint(equalTo: cuonDoc.contentLayoutGuide.trailingAnchor),
            nganBang.bottomAnchor.constraint(equalTo: cuonDoc.contentLayoutGuide.bottomAnchor),
            nganBang.widthAnchor.constraint(equalToConstant: tongRongBang),

            khungTrong.topAnchor.constraint(equalTo: theBang.topAnchor),
            khungTrong.leadingAnchor.constraint(equalTo: theBang.leadingAnchor),
            khungTrong.trailingAnchor.constraint(equalTo: theBang.trailingAnchor),
            khungTrong.bottomAnchor.constraint(equalTo: theBang.bottomAnchor),

            nhanTrong.centerYAnchor.constraint(equalTo: khungTrong.centerYAnchor),
            nhanTrong.leadingAnchor.constraint(equalTo: khungTrong.leadingAnchor, constant: 24),
            nhanTrong.trailingAnchor.constraint(equalTo: khungTrong.trailingAnchor, constant: -24)
        ])

        capNhatMenuCombobox()
    }

    private func cauHinhNutCombobox(_ nut: UIButton, tieuDe: String, laChinh: Bool) {
        nut.setTitle(tieuDe, for: .normal)
        nut.titleLabel?.font = .systemFont(ofSize: 12.0, weight: .bold)
        nut.titleLabel?.numberOfLines = 2
        nut.titleLabel?.lineBreakMode = .byTruncatingTail
        nut.contentHorizontalAlignment = .left
        nut.backgroundColor = laChinh ? BangMauBCTD.nenHeaderPhu : BangMauBCTD.nenThePhu
        nut.setTitleColor(laChinh ? BangMauBCTD.xanhChuDaoDam : BangMauBCTD.chuChinh, for: .normal)
        nut.layer.cornerRadius = 8
        nut.layer.borderWidth = 1.1
        nut.layer.borderColor = (laChinh ? BangMauBCTD.xanhChuDao : BangMauBCTD.vienDam).cgColor
        nut.contentEdgeInsets = UIEdgeInsets(top: 7, left: 9, bottom: 7, right: 9)
        nut.showsMenuAsPrimaryAction = true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField === oLinkSheet {
            bamTaiSheet()
        } else if textField === oMaSieuThi {
            maSieuThiThayDoi()
        }
        return true
    }

    @objc private func maSieuThiThayDoi() {
        let ma = (oMaSieuThi.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(ma, forKey: Self.khoaLuuMaSieuThi)
        capNhatDanhSachComboboxTuDuLieu()
        apDungBoLocVaVeBang()
    }

    @objc private func bamTaiSheet() {
        endEditing(true)
        let rawLink = (oLinkSheet.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let link = rawLink.isEmpty ? Self.linkSheetMacDinh : rawLink
        oLinkSheet.text = link
        UserDefaults.standard.set(link, forKey: Self.khoaLuuLinkSheet)

        guard let (sheetId, gid) = Self.tachSheetIdVaGid(tu: link) else {
            nhanTrangThai.text = "⚠️ Link Google Sheet không hợp lệ. Hãy dán link dạng https://docs.google.com/spreadsheets/d/.../edit?gid=..."
            nhanTrangThai.textColor = BangMauBCTD.doYeuChu
            return
        }

        var cacURL: [URL] = []
        if let u1 = URL(string: "https://docs.google.com/spreadsheets/d/\(sheetId)/export?format=tsv&gid=\(gid)") {
            cacURL.append(u1)
        }
        if let u2 = URL(string: "https://docs.google.com/spreadsheets/d/\(sheetId)/export?format=csv&gid=\(gid)") {
            cacURL.append(u2)
        }
        if let u3 = URL(string: "https://docs.google.com/spreadsheets/d/\(sheetId)/gviz/tq?tqx=out:csv&gid=\(gid)") {
            cacURL.append(u3)
        }

        dangTaiSheet = true
        nutTaiSheet.isEnabled = false
        vongQuay.startAnimating()
        nhanTrangThai.text = "⏳ Đang quét dữ liệu & danh sách Nhóm hàng (Cột G), Trạng thái (Cột H) từ Google Sheet..."
        nhanTrangThai.textColor = BangMauBCTD.xanhChuDaoDam

        taiTuDanhSachURL(cacURL, chiSo: 0)
    }

    private func taiTuDanhSachURL(_ cacURL: [URL], chiSo: Int) {
        guard chiSo < cacURL.count else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.dangTaiSheet = false
                self.nutTaiSheet.isEnabled = true
                self.vongQuay.stopAnimating()
                self.nhanTrangThai.text = "⚠️ Không tải được Google Sheet. Hãy kiểm tra kết nối mạng hoặc quyền chia sẻ (Bất kỳ ai có liên kết đều xem được)."
                self.nhanTrangThai.textColor = BangMauBCTD.doYeuChu
            }
            return
        }

        let url = cacURL[chiSo]
        var req = URLRequest(url: url)
        req.timeoutInterval = 25
        req.cachePolicy = .reloadIgnoringLocalCacheData

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            guard let self = self else { return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard error == nil, status >= 200 && status < 300,
                  let data = data,
                  let text = String(data: data, encoding: .utf8),
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !text.lowercased().contains("<!doctype html") else {
                self.taiTuDanhSachURL(cacURL, chiSo: chiSo + 1)
                return
            }

            let laTSV = url.absoluteString.contains("format=tsv")
            let cacDong = Self.phanTichBangSheet(text, laTSV: laTSV)
            guard !cacDong.isEmpty else {
                self.taiTuDanhSachURL(cacURL, chiSo: chiSo + 1)
                return
            }

            DispatchQueue.main.async {
                self.dangTaiSheet = false
                self.nutTaiSheet.isEnabled = true
                self.vongQuay.stopAnimating()
                self.tatCaDong = cacDong
                self.capNhatDanhSachComboboxTuDuLieu()
                self.apDungBoLocVaVeBang()
            }
        }.resume()
    }

    private func capNhatDanhSachComboboxTuDuLieu() {
        let maST = (oMaSieuThi.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let dongTheoSieuThi: [[String]]
        if maST.isEmpty {
            dongTheoSieuThi = tatCaDong
        } else {
            let loc = tatCaDong.filter { dong in
                guard !dong.isEmpty else { return false }
                return dong[0].localizedCaseInsensitiveContains(maST)
            }
            dongTheoSieuThi = loc.isEmpty ? tatCaDong : loc
        }

        var tapNhom = Set<String>()
        var tapTrangThai = Set<String>()
        for dong in dongTheoSieuThi {
            if dong.count > 6 {
                let nhom = dong[6].trimmingCharacters(in: .whitespacesAndNewlines)
                if !nhom.isEmpty && nhom.lowercased() != "nhóm hàng" {
                    tapNhom.insert(nhom)
                }
            }
            if dong.count > 7 {
                let tt = dong[7].trimmingCharacters(in: .whitespacesAndNewlines)
                if !tt.isEmpty && tt.lowercased() != "trạng thái sản phẩm" {
                    tapTrangThai.insert(tt)
                }
            }
        }

        dsNhomHang = tapNhom.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        dsTrangThai = tapTrangThai.sorted { $0.localizedStandardCompare($1) == .orderedAscending }

        if let dangChon = nhomHangDangChon, dangChon != "__ALL__", !dsNhomHang.contains(dangChon) {
            nhomHangDangChon = nil
        }
        if trangThaiDangChon != "__ALL__", !dsTrangThai.contains(trangThaiDangChon) {
            trangThaiDangChon = "__ALL__"
        }

        capNhatMenuCombobox()
    }

    private func capNhatMenuCombobox() {
        // 1. Menu Nhóm hàng (Cột G)
        let nhanNhom: String
        if let chon = nhomHangDangChon {
            nhanNhom = (chon == "__ALL__") ? "Tất cả (\(dsNhomHang.count))" : chon
        } else {
            nhanNhom = dsNhomHang.isEmpty ? "Chưa quét" : "Chọn nhóm (\(dsNhomHang.count))"
        }
        nutChonNhomHang.setTitle("📂 Nhóm hàng (G): \(nhanNhom) ▾", for: .normal)

        var actionsNhom: [UIAction] = []
        actionsNhom.append(UIAction(
            title: "📋 Tất cả nhóm hàng (\(dsNhomHang.count) nhóm)",
            state: nhomHangDangChon == "__ALL__" ? .on : .off
        ) { [weak self] _ in
            guard let self = self else { return }
            self.nhomHangDangChon = "__ALL__"
            self.capNhatMenuCombobox()
            self.apDungBoLocVaVeBang()
        })
        for nhom in dsNhomHang {
            actionsNhom.append(UIAction(
                title: nhom,
                state: nhomHangDangChon == nhom ? .on : .off
            ) { [weak self] _ in
                guard let self = self else { return }
                self.nhomHangDangChon = nhom
                self.capNhatMenuCombobox()
                self.apDungBoLocVaVeBang()
            })
        }
        nutChonNhomHang.menu = UIMenu(title: "Chọn Nhóm hàng (Cột G)", children: actionsNhom)

        // 2. Menu Trạng thái sản phẩm (Cột H)
        let nhanTT = (trangThaiDangChon == "__ALL__") ? "Tất cả (\(dsTrangThai.count))" : trangThaiDangChon
        nutChonTrangThai.setTitle("🏷️ Trạng thái (H): \(nhanTT) ▾", for: .normal)

        var actionsTT: [UIAction] = []
        actionsTT.append(UIAction(
            title: "📋 Tất cả trạng thái (\(dsTrangThai.count))",
            state: trangThaiDangChon == "__ALL__" ? .on : .off
        ) { [weak self] _ in
            guard let self = self else { return }
            self.trangThaiDangChon = "__ALL__"
            self.capNhatMenuCombobox()
            self.apDungBoLocVaVeBang()
        })
        for tt in dsTrangThai {
            actionsTT.append(UIAction(
                title: tt,
                state: trangThaiDangChon == tt ? .on : .off
            ) { [weak self] _ in
                guard let self = self else { return }
                self.trangThaiDangChon = tt
                self.capNhatMenuCombobox()
                self.apDungBoLocVaVeBang()
            })
        }
        nutChonTrangThai.menu = UIMenu(title: "Chọn Trạng thái sản phẩm (Cột H)", children: actionsTT)
    }

    private func apDungBoLocVaVeBang() {
        guard !tatCaDong.isEmpty else {
            khungTrong.isHidden = false
            nhanTrong.text = "📦 Chưa có dữ liệu. Hãy bấm “Quét Sheet” để tải các nhóm hàng và dữ liệu tồn kho từ Google Sheet."
            return
        }

        let maST = (oMaSieuThi.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        // Chờ người dùng chọn xong Nhóm hàng trong Combobox mới hiển thị bảng bên dưới
        guard let nhomChon = nhomHangDangChon else {
            cacDongDaLoc = []
            khungTrong.isHidden = false
            nhanTrong.text = "✅ Đã quét xong \(tatCaDong.count) dòng (\(dsNhomHang.count) Nhóm hàng ở cột G, \(dsTrangThai.count) Trạng thái ở cột H).\n\n👉 Hãy bấm vào Combobox “Nhóm hàng (G)” phía trên để chọn nhóm hàng cần xem bảng tồn kho."
            nhanTrangThai.text = "Đã quét \(tatCaDong.count) dòng · \(dsNhomHang.count) Nhóm hàng (Cột G) · Hãy chọn Nhóm hàng trên Combobox"
            nhanTrangThai.textColor = BangMauBCTD.xanhChuDaoDam
            return
        }

        let ketQua = tatCaDong.filter { dong in
            let cotA = dong.count > 0 ? dong[0] : ""
            let cotG = dong.count > 6 ? dong[6].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            let cotH = dong.count > 7 ? dong[7].trimmingCharacters(in: .whitespacesAndNewlines) : ""

            if !maST.isEmpty && !cotA.localizedCaseInsensitiveContains(maST) {
                return false
            }
            if nhomChon != "__ALL__" && cotG.caseInsensitiveCompare(nhomChon) != .orderedSame {
                return false
            }
            if trangThaiDangChon != "__ALL__" && cotH.caseInsensitiveCompare(trangThaiDangChon) != .orderedSame {
                return false
            }
            return true
        }

        cacDongDaLoc = ketQua

        if ketQua.isEmpty {
            khungTrong.isHidden = false
            nhanTrong.text = "Không có sản phẩm nào khớp điều kiện:\n• Siêu thị (Cột A) chứa: \"\(maST.isEmpty ? "Tất cả" : maST)\"\n• Nhóm hàng (Cột G): \"\(nhomChon == "__ALL__" ? "Tất cả" : nhomChon)\"\n• Trạng thái (Cột H): \"\(trangThaiDangChon == "__ALL__" ? "Tất cả" : trangThaiDangChon)\""
            nhanTrangThai.text = "0 dòng khớp bộ lọc (Tổng Sheet: \(tatCaDong.count) dòng)"
            nhanTrangThai.textColor = BangMauBCTD.vangKhaChu
            return
        }

        khungTrong.isHidden = true
        let tenNhomHienThi = (nhomChon == "__ALL__") ? "Tất cả nhóm" : nhomChon
        let tenTTHienThi = (trangThaiDangChon == "__ALL__") ? "Tất cả TT" : trangThaiDangChon
        nhanTrangThai.text = "✅ Hiển thị \(ketQua.count) dòng (Siêu thị: \(maST.isEmpty ? "Tất cả" : maST) · Nhóm: \(tenNhomHienThi) · \(tenTTHienThi))"
        nhanTrangThai.textColor = BangMauBCTD.xanhLaDam

        dungBangHienThi(cacDong: ketQua)
    }

    private func dungBangHienThi(cacDong: [[String]]) {
        nganBang.arrangedSubviews.forEach {
            nganBang.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        // Hàng đầu tiên: tên của 19 cột theo thứ tự từ A -> S
        let hangTieuDe = Self.taoHangBang(cacGiaTri: Self.tenCacCotChuan, laHeader: true, chiSoDong: -1)
        nganBang.addArrangedSubview(hangTieuDe)

        let gioiHanHienThi = min(cacDong.count, 500)
        for i in 0..<gioiHanHienThi {
            let hang = Self.taoHangBang(cacGiaTri: cacDong[i], laHeader: false, chiSoDong: i)
            nganBang.addArrangedSubview(hang)
        }
    }

    private static func taoHangBang(cacGiaTri: [String], laHeader: Bool, chiSoDong: Int) -> UIView {
        let hang = UIStackView()
        hang.axis = .horizontal
        hang.spacing = 0
        hang.alignment = .fill
        hang.distribution = .fill

        let mauNen: UIColor
        if laHeader {
            mauNen = BangMauBCTD.xanhChuDao
        } else {
            mauNen = (chiSoDong % 2 == 0) ? .white : BangMauBCTD.nenHeaderPhu
        }
        hang.backgroundColor = mauNen

        for i in 0..<tenCacCotChuan.count {
            let giaTri = (i < cacGiaTri.count) ? cacGiaTri[i] : ""
            let rong = doRongCacCot[i]

            let o = UIView()
            o.backgroundColor = mauNen
            o.layer.borderWidth = 0.5
            o.layer.borderColor = (laHeader ? UIColor.white.withAlphaComponent(0.3) : BangMauBCTD.vienThe).cgColor
            o.translatesAutoresizingMaskIntoConstraints = false
            o.widthAnchor.constraint(equalToConstant: rong).isActive = true

            let lb = UILabel()
            lb.text = giaTri
            lb.font = laHeader
                ? .systemFont(ofSize: 11.5, weight: .heavy)
                : .systemFont(ofSize: 11.5, weight: (i == 0 || i == 3 || i == 8 || i == 15) ? .bold : .medium)
            lb.textColor = laHeader
                ? BangMauBCTD.vangSang
                : (i == 8 || i == 15 ? BangMauBCTD.xanhChuDaoDam : BangMauBCTD.chuChinh)
            lb.numberOfLines = laHeader ? 3 : 2
            lb.lineBreakMode = .byWordWrapping
            lb.textAlignment = (laHeader || i >= 8 || i == 4 || i == 17) ? .center : .left
            lb.translatesAutoresizingMaskIntoConstraints = false
            o.addSubview(lb)

            NSLayoutConstraint.activate([
                o.heightAnchor.constraint(greaterThanOrEqualToConstant: laHeader ? 42 : 34),
                lb.topAnchor.constraint(equalTo: o.topAnchor, constant: 5),
                lb.bottomAnchor.constraint(equalTo: o.bottomAnchor, constant: -5),
                lb.leadingAnchor.constraint(equalTo: o.leadingAnchor, constant: 6),
                lb.trailingAnchor.constraint(equalTo: o.trailingAnchor, constant: -6)
            ])

            hang.addArrangedSubview(o)
        }
        return hang
    }

    @objc private func bamXuatAnhBang() {
        guard !cacDongDaLoc.isEmpty else {
            nhanTrangThai.text = "⚠️ Chưa có dữ liệu bảng đang hiển thị để xuất ảnh. Hãy chọn Nhóm hàng (Cột G) trước!"
            nhanTrangThai.textColor = BangMauBCTD.doYeuChu
            return
        }
        guard let anh = taoAnhBangTonKho() else { return }
        khiXuatAnh?(anh)
    }

    func taoAnhBangTonKho() -> UIImage? {
        guard !cacDongDaLoc.isEmpty else { return nil }
        let dsXuat = Array(cacDongDaLoc.prefix(250))
        let tongRong = Self.doRongCacCot.reduce(0, +) + 24

        let khung = UIView()
        khung.backgroundColor = .white
        khung.translatesAutoresizingMaskIntoConstraints = false

        let nganChinh = UIStackView()
        nganChinh.axis = .vertical
        nganChinh.spacing = 0
        nganChinh.translatesAutoresizingMaskIntoConstraints = false
        khung.addSubview(nganChinh)

        // Thanh tiêu đề ảnh xuất
        let dau = UIView()
        dau.backgroundColor = BangMauBCTD.xanhChuDaoDam
        let lbDau = UILabel()
        let maST = (oMaSieuThi.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let tenNhom = (nhomHangDangChon == nil || nhomHangDangChon == "__ALL__") ? "Tất cả nhóm hàng" : (nhomHangDangChon ?? "")
        let tenTT = (trangThaiDangChon == "__ALL__") ? "Tất cả trạng thái" : trangThaiDangChon
        lbDau.text = "📦 BẢNG DỮ LIỆU TỒN KHO · SIÊU THỊ: \(maST.isEmpty ? "TẤT CẢ" : maST) · NHÓM HÀNG: \(tenNhom.uppercased()) · TRẠNG THÁI: \(tenTT.uppercased()) (\(dsXuat.count) SP)"
        lbDau.font = .systemFont(ofSize: 14, weight: .heavy)
        lbDau.textColor = BangMauBCTD.vangSang
        lbDau.numberOfLines = 0
        lbDau.translatesAutoresizingMaskIntoConstraints = false
        dau.addSubview(lbDau)
        NSLayoutConstraint.activate([
            lbDau.topAnchor.constraint(equalTo: dau.topAnchor, constant: 10),
            lbDau.bottomAnchor.constraint(equalTo: dau.bottomAnchor, constant: -10),
            lbDau.leadingAnchor.constraint(equalTo: dau.leadingAnchor, constant: 12),
            lbDau.trailingAnchor.constraint(equalTo: dau.trailingAnchor, constant: -12)
        ])
        nganChinh.addArrangedSubview(dau)

        // Hàng đầu tiên: đúng 19 cột từ A đến S
        let hangHeader = Self.taoHangBang(cacGiaTri: Self.tenCacCotChuan, laHeader: true, chiSoDong: -1)
        nganChinh.addArrangedSubview(hangHeader)

        for (i, dong) in dsXuat.enumerated() {
            let hang = Self.taoHangBang(cacGiaTri: dong, laHeader: false, chiSoDong: i)
            nganChinh.addArrangedSubview(hang)
        }

        NSLayoutConstraint.activate([
            khung.widthAnchor.constraint(equalToConstant: tongRong),
            nganChinh.topAnchor.constraint(equalTo: khung.topAnchor, constant: 12),
            nganChinh.bottomAnchor.constraint(equalTo: khung.bottomAnchor, constant: -12),
            nganChinh.leadingAnchor.constraint(equalTo: khung.leadingAnchor, constant: 12),
            nganChinh.trailingAnchor.constraint(equalTo: khung.trailingAnchor, constant: -12)
        ])

        khung.setNeedsLayout()
        khung.layoutIfNeeded()
        let kichThuoc = khung.systemLayoutSizeFitting(
            CGSize(width: tongRong, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        guard kichThuoc.width > 10 && kichThuoc.height > 10 else { return nil }
        khung.frame = CGRect(origin: .zero, size: kichThuoc)
        khung.layoutIfNeeded()

        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2.0
        fmt.opaque = true
        let renderer = UIGraphicsImageRenderer(size: kichThuoc, format: fmt)
        return renderer.image { ctx in
            khung.layer.render(in: ctx.cgContext)
        }
    }

    // MARK: - Tách ID Google Sheet & Phân tích TSV / CSV

    static func tachSheetIdVaGid(tu link: String) -> (sheetId: String, gid: String)? {
        let s = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let r1 = s.range(of: "/spreadsheets/d/") else { return nil }
        let sau = s[r1.upperBound...]
        let sheetId = String(sau.prefix { $0 != "/" && $0 != "?" && $0 != "#" && $0 != "&" })
        guard !sheetId.isEmpty else { return nil }

        var gid = "0"
        if let rgGid = s.range(of: "gid=") {
            let sauGid = s[rgGid.upperBound...]
            let chuoiSo = String(sauGid.prefix { $0.isNumber })
            if !chuoiSo.isEmpty { gid = chuoiSo }
        }
        return (sheetId, gid)
    }

    static func phanTichBangSheet(_ noiDung: String, laTSV: Bool) -> [[String]] {
        let bang = laTSV ? phanTichTSV(noiDung) : phanTichCSV(noiDung)
        var ketQua: [[String]] = []

        for (chiSo, dongGoc) in bang.enumerated() {
            var dong = dongGoc.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if dong.allSatisfy({ $0.isEmpty }) { continue }

            // Bỏ qua dòng tiêu đề gốc của Sheet nếu trùng với hàng tiêu đề A-S
            let cot0 = dong.first?.lowercased() ?? ""
            let cot1 = (dong.count > 1 ? dong[1] : "").lowercased()
            if chiSo == 0 && (cot0.contains("tên siêu thị") || cot0.contains("ten sieu thi") || cot1.contains("mã model") || cot1.contains("ma model")) {
                continue
            }
            while dong.count < tenCacCotChuan.count {
                dong.append("")
            }
            if dong.count > tenCacCotChuan.count {
                dong = Array(dong.prefix(tenCacCotChuan.count))
            }
            ketQua.append(dong)
        }
        return ketQua
    }

    private static func phanTichTSV(_ text: String) -> [[String]] {
        let chuan = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        return chuan.components(separatedBy: "\n").map { $0.components(separatedBy: "\t") }
    }

    private static func phanTichCSV(_ text: String) -> [[String]] {
        var ketQua: [[String]] = []
        var dongHienTai: [String] = []
        var oHienTai = ""
        var trongNhay = false
        let chars = Array(text)
        var i = 0

        while i < chars.count {
            let c = chars[i]
            if trongNhay {
                if c == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        oHienTai.append("\"")
                        i += 2
                        continue
                    } else {
                        trongNhay = false
                    }
                } else {
                    oHienTai.append(c)
                }
            } else {
                if c == "\"" {
                    trongNhay = true
                } else if c == "," {
                    dongHienTai.append(oHienTai)
                    oHienTai = ""
                } else if c == "\r" {
                    dongHienTai.append(oHienTai)
                    oHienTai = ""
                    ketQua.append(dongHienTai)
                    dongHienTai = []
                    if i + 1 < chars.count && chars[i + 1] == "\n" {
                        i += 1
                    }
                } else if c == "\n" {
                    dongHienTai.append(oHienTai)
                    oHienTai = ""
                    ketQua.append(dongHienTai)
                    dongHienTai = []
                } else {
                    oHienTai.append(c)
                }
            }
            i += 1
        }
        if !oHienTai.isEmpty || !dongHienTai.isEmpty {
            dongHienTai.append(oHienTai)
            ketQua.append(dongHienTai)
        }
        return ketQua
    }
}
