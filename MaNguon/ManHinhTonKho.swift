import UIKit
import QuartzCore

private struct DongTonKho: Hashable {
    var cot: [String]

    init(_ giaTri: [String]) {
        cot = Array(giaTri.prefix(19))
        if cot.count < 19 {
            cot.append(contentsOf: Array(repeating: "", count: 19 - cot.count))
        }
    }
}

private enum BangTonKho {
    static let tieuDeCot = [
        "Tên siêu thị", "Mã Model", "Mã sản phẩm", "Tên sản phẩm", "Đơn vị",
        "Ngành hàng", "Nhóm hàng", "Trạng thái sản phẩm", "Số lượng",
        "SL không gồm hàng đi đường", "Số lượng đặt", "SL được chia đến",
        "SL đang đi đường", "SL được chia đi", "Số lượng đã đặt",
        "Số lượng có thể bán", "SL tồn kho tối thiểu", "Có in QR", "Số lượng tồn lô"
    ]

    static let doRongCot: [CGFloat] = [
        135, 135, 145, 270, 90, 155, 180, 195, 105,
        190, 120, 145, 145, 145, 145, 160, 165, 105, 145
    ]
    static let caoHeader: CGFloat = 62
    static let caoDong: CGFloat = 48
    static var tongRong: CGFloat { doRongCot.reduce(0, +) }

    static func veBang(
        trong context: CGContext,
        rect: CGRect,
        cacDong: [DongTonKho],
        batDau: Int = 0,
        hienHeader: Bool = true
    ) {
        context.saveGState()
        context.clip(to: rect)
        UIColor.white.setFill()
        context.fill(rect)

        let mauHeader = UIColor(red: 0.10, green: 0.38, blue: 0.90, alpha: 1)
        let mauVien = UIColor(red: 0.82, green: 0.87, blue: 0.94, alpha: 1)
        let mauDongLe = UIColor(red: 0.95, green: 0.97, blue: 1.00, alpha: 1)
        let fontHeader = UIFont.systemFont(ofSize: 13, weight: .bold)
        let fontDong = UIFont.systemFont(ofSize: 13, weight: .medium)

        if hienHeader {
            mauHeader.setFill()
            context.fill(CGRect(x: 0, y: 0, width: tongRong, height: caoHeader))
            var x: CGFloat = 0
            for i in 0..<tieuDeCot.count {
                veChu(tieuDeCot[i], trong: CGRect(x: x + 7, y: 7, width: doRongCot[i] - 14, height: caoHeader - 14),
                      font: fontHeader, mau: .white, canGiua: i >= 8)
                x += doRongCot[i]
            }
        }

        let dongDau = max(0, Int(floor((rect.minY - caoHeader) / caoDong)))
        let dongCuoi = min(cacDong.count - 1, Int(ceil((rect.maxY - caoHeader) / caoDong)))
        if !cacDong.isEmpty, dongDau <= dongCuoi {
            for viTri in dongDau...dongCuoi {
                let y = caoHeader + CGFloat(viTri) * caoDong
                if (viTri + batDau) % 2 == 1 {
                    mauDongLe.setFill()
                    context.fill(CGRect(x: 0, y: y, width: tongRong, height: caoDong))
                }
                var x: CGFloat = 0
                for cot in 0..<tieuDeCot.count {
                    let noiDung = cot < cacDong[viTri].cot.count ? cacDong[viTri].cot[cot] : ""
                    veChu(noiDung, trong: CGRect(x: x + 7, y: y + 6, width: doRongCot[cot] - 14, height: caoDong - 12),
                          font: fontDong, mau: BangMauBCTD.chuChinh, canGiua: cot >= 8)
                    x += doRongCot[cot]
                }
            }
        }

        mauVien.setStroke()
        context.setLineWidth(1)
        var x: CGFloat = 0
        context.move(to: CGPoint(x: 0, y: 0))
        context.addLine(to: CGPoint(x: 0, y: caoHeader + CGFloat(cacDong.count) * caoDong))
        for w in doRongCot {
            x += w
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: caoHeader + CGFloat(cacDong.count) * caoDong))
        }
        context.move(to: CGPoint(x: 0, y: caoHeader))
        context.addLine(to: CGPoint(x: tongRong, y: caoHeader))
        for i in 0...cacDong.count {
            let y = caoHeader + CGFloat(i) * caoDong
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: tongRong, y: y))
        }
        context.strokePath()
        context.restoreGState()
    }

    private static func veChu(_ chu: String, trong rect: CGRect, font: UIFont, mau: UIColor, canGiua: Bool) {
        let p = NSMutableParagraphStyle()
        p.alignment = canGiua ? .center : .left
        p.lineBreakMode = .byTruncatingTail
        (chu as NSString).draw(
            with: rect,
            options: [.usesLineFragmentOrigin, .usesFontLeading, .truncatesLastVisibleLine],
            attributes: [.font: font, .foregroundColor: mau, .paragraphStyle: p],
            context: nil
        )
    }
}

private final class BangTonKhoCanvas: UIView {
    override class var layerClass: AnyClass { CATiledLayer.self }
    var cacDong: [DongTonKho] = [] {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = true
        backgroundColor = .white
        if let tiled = layer as? CATiledLayer {
            tiled.tileSize = CGSize(width: 1024, height: 1024)
            tiled.levelsOfDetail = 1
            tiled.levelsOfDetailBias = 0
        }
    }

    required init?(coder: NSCoder) { fatalError("Khong ho tro coder") }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        BangTonKho.veBang(trong: context, rect: rect, cacDong: cacDong)
    }
}

final class ManHinhTonKho: UIViewController, UITextFieldDelegate {
    private let oLink = UITextField()
    private let oSieuThi = UITextField()
    private let nutTai = UIButton(type: .system)
    private let nutNhomHang = UIButton(type: .system)
    private let nutTrangThai = UIButton(type: .system)
    private let nutXuatAnh = UIButton(type: .system)
    private let nhanTrangThai = UILabel()
    private let vongQuay = UIActivityIndicatorView(style: .medium)
    private let cuonBang = UIScrollView()
    private let canvas = BangTonKhoCanvas()

    private var tatCaDong: [DongTonKho] = []
    private var dongTheoSieuThi: [DongTonKho] = []
    private var dongDangHienThi: [DongTonKho] = []
    private var nhomHangDangChon: String?
    private var trangThaiDangChon: String?

    private let khoaLink = "dmx_ton_kho_link_google_sheet_v1"
    private let khoaSieuThi = "dmx_ton_kho_ma_sieu_thi_v1"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BangMauBCTD.nenTrang
        taoGiaoDien()
        oLink.text = UserDefaults.standard.string(forKey: khoaLink) ?? ""
        oSieuThi.text = UserDefaults.standard.string(forKey: khoaSieuThi) ?? ""
        capNhatMenuBoLoc(nhomHang: [], trangThai: [])
    }

    private func taoGiaoDien() {
        let theLoc = UIView()
        theLoc.backgroundColor = .white
        theLoc.layer.cornerRadius = 14
        theLoc.layer.borderWidth = 1
        theLoc.layer.borderColor = BangMauBCTD.vienThe.cgColor
        theLoc.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(theLoc)

        let nhanHuongDan = UILabel()
        nhanHuongDan.text = "Dán link Google Sheet công khai, nhập mã siêu thị rồi tải dữ liệu. App tự đọc Nhóm hàng (cột G) và Trạng thái (cột H)."
        nhanHuongDan.font = .systemFont(ofSize: 12.5, weight: .medium)
        nhanHuongDan.textColor = BangMauBCTD.chuPhu
        nhanHuongDan.numberOfLines = 0

        cauHinhO(oLink, goiY: "Link Google Sheet", kieu: .URL)
        oLink.autocapitalizationType = .none
        oLink.autocorrectionType = .no
        oLink.clearButtonMode = .whileEditing
        cauHinhO(oSieuThi, goiY: "Mã siêu thị, ví dụ: 76", kieu: .numberPad)

        nutTai.setTitle("Tải & lọc dữ liệu", for: .normal)
        nutTai.setImage(UIImage(systemName: "arrow.triangle.2.circlepath"), for: .normal)
        cauHinhNutChinh(nutTai, mau: BangMauBCTD.xanhChuDao)
        nutTai.addTarget(self, action: #selector(bamTaiDuLieu), for: .touchUpInside)

        cauHinhNutLoc(nutNhomHang, tieuDe: "Tất cả nhóm hàng")
        cauHinhNutLoc(nutTrangThai, tieuDe: "Tất cả trạng thái")

        nutXuatAnh.setTitle("Xuất ảnh", for: .normal)
        nutXuatAnh.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        cauHinhNutChinh(nutXuatAnh, mau: BangMauBCTD.xanhDatVach)
        nutXuatAnh.addTarget(self, action: #selector(bamXuatAnh), for: .touchUpInside)
        nutXuatAnh.isEnabled = false
        nutXuatAnh.alpha = 0.55

        nhanTrangThai.text = "Chưa tải dữ liệu tồn kho."
        nhanTrangThai.font = .systemFont(ofSize: 12.5, weight: .semibold)
        nhanTrangThai.textColor = BangMauBCTD.chuPhu
        nhanTrangThai.numberOfLines = 0

        vongQuay.hidesWhenStopped = true
        let hangTai = UIStackView(arrangedSubviews: [nutTai, vongQuay])
        hangTai.axis = .horizontal
        hangTai.spacing = 8
        hangTai.alignment = .center

        let hangLoc = UIStackView(arrangedSubviews: [nutNhomHang, nutTrangThai])
        hangLoc.axis = .horizontal
        hangLoc.spacing = 8
        hangLoc.distribution = .fillEqually

        let hangCuoi = UIStackView(arrangedSubviews: [nhanTrangThai, nutXuatAnh])
        hangCuoi.axis = .horizontal
        hangCuoi.spacing = 8
        hangCuoi.alignment = .center
        nhanTrangThai.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nutXuatAnh.setContentCompressionResistancePriority(.required, for: .horizontal)

        let ngan = UIStackView(arrangedSubviews: [nhanHuongDan, oLink, oSieuThi, hangTai, hangLoc, hangCuoi])
        ngan.axis = .vertical
        ngan.spacing = 8
        ngan.translatesAutoresizingMaskIntoConstraints = false
        theLoc.addSubview(ngan)

        cuonBang.backgroundColor = .white
        cuonBang.layer.cornerRadius = 12
        cuonBang.layer.borderWidth = 1
        cuonBang.layer.borderColor = BangMauBCTD.vienThe.cgColor
        cuonBang.alwaysBounceHorizontal = true
        cuonBang.alwaysBounceVertical = true
        cuonBang.directionalLockEnabled = true
        cuonBang.showsHorizontalScrollIndicator = true
        cuonBang.showsVerticalScrollIndicator = true
        cuonBang.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cuonBang)
        cuonBang.addSubview(canvas)

        let chamAnBanPhim = UITapGestureRecognizer(target: self, action: #selector(anBanPhim))
        chamAnBanPhim.cancelsTouchesInView = false
        view.addGestureRecognizer(chamAnBanPhim)

        NSLayoutConstraint.activate([
            theLoc.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            theLoc.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            theLoc.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),

            ngan.topAnchor.constraint(equalTo: theLoc.topAnchor, constant: 12),
            ngan.leadingAnchor.constraint(equalTo: theLoc.leadingAnchor, constant: 12),
            ngan.trailingAnchor.constraint(equalTo: theLoc.trailingAnchor, constant: -12),
            ngan.bottomAnchor.constraint(equalTo: theLoc.bottomAnchor, constant: -12),
            oLink.heightAnchor.constraint(equalToConstant: 40),
            oSieuThi.heightAnchor.constraint(equalToConstant: 40),
            nutTai.heightAnchor.constraint(equalToConstant: 40),
            nutNhomHang.heightAnchor.constraint(equalToConstant: 40),
            nutTrangThai.heightAnchor.constraint(equalToConstant: 40),
            nutXuatAnh.heightAnchor.constraint(equalToConstant: 38),
            nutXuatAnh.widthAnchor.constraint(greaterThanOrEqualToConstant: 108),

            cuonBang.topAnchor.constraint(equalTo: theLoc.bottomAnchor, constant: 8),
            cuonBang.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            cuonBang.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            cuonBang.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -6)
        ])
        capNhatCanvas()
    }

    private func cauHinhO(_ o: UITextField, goiY: String, kieu: UIKeyboardType) {
        o.placeholder = goiY
        o.keyboardType = kieu
        o.delegate = self
        o.font = .systemFont(ofSize: 13.5, weight: .medium)
        o.textColor = BangMauBCTD.chuChinh
        o.backgroundColor = BangMauBCTD.nenThePhu
        o.layer.cornerRadius = 9
        o.layer.borderWidth = 1
        o.layer.borderColor = BangMauBCTD.vienDam.cgColor
        o.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        o.leftViewMode = .always
        o.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 1))
        o.rightViewMode = .always
        o.returnKeyType = .done
    }

    private func cauHinhNutChinh(_ nut: UIButton, mau: UIColor) {
        nut.backgroundColor = mau
        nut.tintColor = .white
        nut.setTitleColor(.white, for: .normal)
        nut.titleLabel?.font = .systemFont(ofSize: 13.5, weight: .bold)
        nut.layer.cornerRadius = 9
        nut.configuration = {
            var c = UIButton.Configuration.plain()
            c.imagePadding = 6
            c.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
            return c
        }()
    }

    private func cauHinhNutLoc(_ nut: UIButton, tieuDe: String) {
        nut.setTitle(tieuDe, for: .normal)
        nut.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
        nut.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        nut.titleLabel?.lineBreakMode = .byTruncatingTail
        nut.contentHorizontalAlignment = .left
        nut.backgroundColor = BangMauBCTD.nenHeaderPhu
        nut.layer.cornerRadius = 9
        nut.layer.borderWidth = 1
        nut.layer.borderColor = BangMauBCTD.vienXanhNhat.cgColor
        nut.showsMenuAsPrimaryAction = true
    }

    @objc private func anBanPhim() { view.endEditing(true) }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc private func bamTaiDuLieu() {
        anBanPhim()
        let link = (oLink.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let maSieuThi = (oSieuThi.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !maSieuThi.isEmpty else {
            hienLoi("Hãy nhập mã siêu thị, ví dụ 76.")
            return
        }
        guard let url = taoURLCSV(tu: link) else {
            hienLoi("Link Google Sheet chưa đúng định dạng.")
            return
        }

        UserDefaults.standard.set(link, forKey: khoaLink)
        UserDefaults.standard.set(maSieuThi, forKey: khoaSieuThi)
        nutTai.isEnabled = false
        vongQuay.startAnimating()
        nhanTrangThai.text = "Đang tải và đọc dữ liệu Google Sheet..."

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 35
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            DispatchQueue.main.async {
                self.nutTai.isEnabled = true
                self.vongQuay.stopAnimating()
            }
            if let error {
                DispatchQueue.main.async { self.hienLoi("Không tải được Google Sheet: \(error.localizedDescription)") }
                return
            }
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let data, let chuoi = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    self.hienLoi("Không đọc được Sheet. Hãy bật chia sẻ: Bất kỳ ai có đường liên kết đều có thể xem.")
                }
                return
            }
            let ketQua = self.docCSV(chuoi)
            DispatchQueue.main.async { self.apDungDuLieuCSV(ketQua, maSieuThi: maSieuThi) }
        }.resume()
    }

    private func taoURLCSV(tu link: String) -> URL? {
        guard let url = URL(string: link),
              let viTriD = url.pathComponents.firstIndex(of: "d"),
              url.pathComponents.indices.contains(viTriD + 1) else { return nil }
        let id = url.pathComponents[viTriD + 1]
        guard !id.isEmpty else { return nil }
        let comp = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var gid = comp?.queryItems?.first(where: { $0.name == "gid" })?.value
        if gid == nil, let fragment = comp?.fragment {
            gid = URLComponents(string: "?\(fragment)")?.queryItems?.first(where: { $0.name == "gid" })?.value
        }
        var xuat = URLComponents(string: "https://docs.google.com/spreadsheets/d/\(id)/export")
        xuat?.queryItems = [
            URLQueryItem(name: "format", value: "csv"),
            URLQueryItem(name: "gid", value: gid ?? "0")
        ]
        return xuat?.url
    }

    private func docCSV(_ chuoi: String) -> [[String]] {
        var ketQua: [[String]] = []
        var dong: [String] = []
        var o = ""
        var trongNgoac = false
        var i = chuoi.startIndex
        while i < chuoi.endIndex {
            let kyTu = chuoi[i]
            if kyTu == "\"" {
                let tiep = chuoi.index(after: i)
                if trongNgoac, tiep < chuoi.endIndex, chuoi[tiep] == "\"" {
                    o.append("\"")
                    i = tiep
                } else {
                    trongNgoac.toggle()
                }
            } else if kyTu == ",", !trongNgoac {
                dong.append(o.trimmingCharacters(in: .whitespacesAndNewlines))
                o = ""
            } else if (kyTu == "\n" || kyTu == "\r"), !trongNgoac {
                if kyTu == "\r" {
                    let tiep = chuoi.index(after: i)
                    if tiep < chuoi.endIndex, chuoi[tiep] == "\n" { i = tiep }
                }
                dong.append(o.trimmingCharacters(in: .whitespacesAndNewlines))
                o = ""
                if dong.contains(where: { !$0.isEmpty }) { ketQua.append(dong) }
                dong = []
            } else {
                o.append(kyTu)
            }
            i = chuoi.index(after: i)
        }
        if !o.isEmpty || !dong.isEmpty {
            dong.append(o.trimmingCharacters(in: .whitespacesAndNewlines))
            if dong.contains(where: { !$0.isEmpty }) { ketQua.append(dong) }
        }
        return ketQua
    }

    private func apDungDuLieuCSV(_ mang: [[String]], maSieuThi: String) {
        guard !mang.isEmpty else {
            hienLoi("Google Sheet không có dữ liệu.")
            return
        }
        let viTriHeader = mang.prefix(30).firstIndex { dong in
            guard dong.count >= 2 else { return false }
            return chuanHoa(dong[0]).contains("ten sieu thi") && chuanHoa(dong[1]).contains("ma model")
        } ?? 0
        tatCaDong = mang.dropFirst(viTriHeader + 1).map(DongTonKho.init).filter { dong in
            dong.cot.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        }
        dongTheoSieuThi = tatCaDong.filter { $0.cot[0].range(of: maSieuThi, options: [.caseInsensitive, .diacriticInsensitive]) != nil }

        nhomHangDangChon = nil
        trangThaiDangChon = nil
        let nhom = Array(Set(dongTheoSieuThi.map { $0.cot[6] }.filter { !$0.isEmpty })).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        let trangThai = Array(Set(dongTheoSieuThi.map { $0.cot[7] }.filter { !$0.isEmpty })).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        capNhatMenuBoLoc(nhomHang: nhom, trangThai: trangThai)
        apDungBoLoc()
        if dongTheoSieuThi.isEmpty {
            hienLoi("Không tìm thấy dòng nào có mã siêu thị \(maSieuThi) trong cột A.")
        }
    }

    private func chuanHoa(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
            .lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func capNhatMenuBoLoc(nhomHang: [String], trangThai: [String]) {
        let tatCaNhom = UIAction(title: "Tất cả nhóm hàng", state: nhomHangDangChon == nil ? .on : .off) { [weak self] _ in
            self?.nhomHangDangChon = nil
            self?.capNhatMenuBoLoc(nhomHang: nhomHang, trangThai: trangThai)
            self?.apDungBoLoc()
        }
        let cacNhom = nhomHang.map { ten in
            UIAction(title: ten, state: nhomHangDangChon == ten ? .on : .off) { [weak self] _ in
                self?.nhomHangDangChon = ten
                self?.capNhatMenuBoLoc(nhomHang: nhomHang, trangThai: trangThai)
                self?.apDungBoLoc()
            }
        }
        nutNhomHang.menu = UIMenu(title: "Nhóm hàng (cột G)", options: .displayInline, children: [tatCaNhom] + cacNhom)
        nutNhomHang.setTitle(nhomHangDangChon ?? "Tất cả nhóm hàng", for: .normal)

        let tatCaTT = UIAction(title: "Tất cả trạng thái", state: trangThaiDangChon == nil ? .on : .off) { [weak self] _ in
            self?.trangThaiDangChon = nil
            self?.capNhatMenuBoLoc(nhomHang: nhomHang, trangThai: trangThai)
            self?.apDungBoLoc()
        }
        let cacTT = trangThai.map { ten in
            UIAction(title: ten, state: trangThaiDangChon == ten ? .on : .off) { [weak self] _ in
                self?.trangThaiDangChon = ten
                self?.capNhatMenuBoLoc(nhomHang: nhomHang, trangThai: trangThai)
                self?.apDungBoLoc()
            }
        }
        nutTrangThai.menu = UIMenu(title: "Trạng thái sản phẩm (cột H)", options: .displayInline, children: [tatCaTT] + cacTT)
        nutTrangThai.setTitle(trangThaiDangChon ?? "Tất cả trạng thái", for: .normal)
    }

    private func apDungBoLoc() {
        dongDangHienThi = dongTheoSieuThi.filter { dong in
            let dungNhom = nhomHangDangChon == nil || dong.cot[6] == nhomHangDangChon
            let dungTrangThai = trangThaiDangChon == nil || dong.cot[7] == trangThaiDangChon
            return dungNhom && dungTrangThai
        }
        let ma = (oSieuThi.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        nhanTrangThai.text = "Siêu thị \(ma): \(dongDangHienThi.count)/\(dongTheoSieuThi.count) dòng · \(Set(dongTheoSieuThi.map { $0.cot[6] }).count) nhóm hàng"
        nutXuatAnh.isEnabled = !dongDangHienThi.isEmpty
        nutXuatAnh.alpha = dongDangHienThi.isEmpty ? 0.55 : 1
        capNhatCanvas()
    }

    private func capNhatCanvas() {
        canvas.cacDong = dongDangHienThi
        let cao = BangTonKho.caoHeader + CGFloat(max(1, dongDangHienThi.count)) * BangTonKho.caoDong
        canvas.frame = CGRect(x: 0, y: 0, width: BangTonKho.tongRong, height: cao)
        cuonBang.contentSize = canvas.frame.size
        cuonBang.setContentOffset(.zero, animated: false)
    }

    @objc private func bamXuatAnh() {
        guard !dongDangHienThi.isEmpty else { return }
        let moiTrang = 28
        let soTrang = Int(ceil(Double(dongDangHienThi.count) / Double(moiTrang)))
        let ma = (oSieuThi.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let boLoc = "Nhóm hàng: \(nhomHangDangChon ?? "Tất cả") · Trạng thái: \(trangThaiDangChon ?? "Tất cả")"
        var anh: [UIImage] = []
        for trang in 0..<soTrang {
            let dau = trang * moiTrang
            let cuoi = min(dau + moiTrang, dongDangHienThi.count)
            let ds = Array(dongDangHienThi[dau..<cuoi])
            let caoTieuDe: CGFloat = 92
            let kichThuoc = CGSize(width: BangTonKho.tongRong, height: caoTieuDe + BangTonKho.caoHeader + CGFloat(ds.count) * BangTonKho.caoDong)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = true
            let image = UIGraphicsImageRenderer(size: kichThuoc, format: format).image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(origin: .zero, size: kichThuoc))
                BangMauBCTD.xanhChuDao.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: kichThuoc.width, height: caoTieuDe))
                let p = NSMutableParagraphStyle(); p.alignment = .left
                ("BẢNG TỒN KHO · SIÊU THỊ \(ma)" as NSString).draw(
                    in: CGRect(x: 24, y: 16, width: kichThuoc.width - 48, height: 30),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 24, weight: .heavy), .foregroundColor: UIColor.white, .paragraphStyle: p]
                )
                ("\(boLoc) · \(dongDangHienThi.count) dòng · Trang \(trang + 1)/\(soTrang)" as NSString).draw(
                    in: CGRect(x: 24, y: 52, width: kichThuoc.width - 48, height: 22),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 15, weight: .semibold), .foregroundColor: UIColor.white.withAlphaComponent(0.92), .paragraphStyle: p]
                )
                ctx.cgContext.saveGState()
                ctx.cgContext.translateBy(x: 0, y: caoTieuDe)
                BangTonKho.veBang(trong: ctx.cgContext,
                                  rect: CGRect(x: 0, y: 0, width: BangTonKho.tongRong, height: kichThuoc.height - caoTieuDe),
                                  cacDong: ds, batDau: dau)
                ctx.cgContext.restoreGState()
            }
            anh.append(image)
        }
        let chiaSe = UIActivityViewController(activityItems: anh, applicationActivities: nil)
        chiaSe.popoverPresentationController?.sourceView = nutXuatAnh
        chiaSe.popoverPresentationController?.sourceRect = nutXuatAnh.bounds
        present(chiaSe, animated: true)
    }

    private func hienLoi(_ noiDung: String) {
        let tb = UIAlertController(title: "Dữ liệu tồn kho", message: noiDung, preferredStyle: .alert)
        tb.addAction(UIAlertAction(title: "Đóng", style: .default))
        present(tb, animated: true)
        nhanTrangThai.text = noiDung
    }
}
