import UIKit

enum BoLocThiDua: Int {
    case tatCa = 0
    case daDat = 1
    case chuaDat = 2
}

enum KieuSapXepThiDua: Int, CaseIterable {
    case phanTramCaoThap = 0
    case phanTramThapCao = 1
    case tenAZ = 2
    case tenZA = 3
    case thuTuGoc = 4

    var nhan: String {
        switch self {
        case .phanTramCaoThap: return "% HT: Cao → Thấp"
        case .phanTramThapCao: return "% HT: Thấp → Cao"
        case .tenAZ: return "Ngành hàng: A → Z"
        case .tenZA: return "Ngành hàng: Z → A"
        case .thuTuGoc: return "Thứ tự quét gốc"
        }
    }

    var nhanNgan: String {
        switch self {
        case .phanTramCaoThap: return "HT Cao↓"
        case .phanTramThapCao: return "HT Thấp↑"
        case .tenAZ: return "Tên A-Z"
        case .tenZA: return "Tên Z-A"
        case .thuTuGoc: return "Mặc định"
        }
    }
}

extension UIView {
    func timViewControllerCha() -> UIViewController? {
        var phanHoi: UIResponder? = self
        while let tiep = phanHoi?.next {
            if let vc = tiep as? UIViewController {
                return vc
            }
            phanHoi = tiep
        }
        return nil
    }
}

// MARK: - Thẻ Chỉ Số Gradient & Cụm 8 Thẻ "Chỉ Số Chính" (Chữ đồng nhất kích cỡ, tự xuống dòng, không bao giờ "...")

final class TheDoanhThuView: UIControl {
    private let lopGradient = CAGradientLayer()
    private let nhanTieuDe = UILabel()
    private let nhanGiaTriChinh = UILabel()
    private let vachKe = UIView()
    private let nhanTarget = UILabel()
    private let chamTron = UIView()

    init(tieuDe: String, mauBatDau: UIColor, mauKetThuc: UIColor, hienChamTron: Bool = false) {
        super.init(frame: .zero)
        layer.cornerRadius = 11
        clipsToBounds = true

        lopGradient.colors = [mauBatDau.cgColor, mauKetThuc.cgColor]
        lopGradient.startPoint = CGPoint(x: 0, y: 0)
        lopGradient.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(lopGradient, at: 0)

        nhanTieuDe.text = tieuDe
        nhanTieuDe.font = .systemFont(ofSize: 8.5, weight: .bold)
        nhanTieuDe.textColor = UIColor.white.withAlphaComponent(0.95)
        nhanTieuDe.textAlignment = .center
        nhanTieuDe.numberOfLines = 0
        nhanTieuDe.lineBreakMode = .byWordWrapping
        nhanTieuDe.adjustsFontSizeToFitWidth = false
        nhanTieuDe.setContentCompressionResistancePriority(.required, for: .vertical)

        nhanGiaTriChinh.text = "0,00"
        nhanGiaTriChinh.font = .systemFont(ofSize: 13.0, weight: .heavy)
        nhanGiaTriChinh.textColor = .white
        nhanGiaTriChinh.textAlignment = .center
        nhanGiaTriChinh.numberOfLines = 0
        nhanGiaTriChinh.lineBreakMode = .byWordWrapping
        nhanGiaTriChinh.adjustsFontSizeToFitWidth = false
        nhanGiaTriChinh.setContentCompressionResistancePriority(.required, for: .vertical)

        vachKe.backgroundColor = UIColor.white.withAlphaComponent(0.26)

        nhanTarget.text = "TARGET: 0,00"
        nhanTarget.font = .systemFont(ofSize: 8.0, weight: .bold)
        nhanTarget.textColor = UIColor.white.withAlphaComponent(0.92)
        nhanTarget.textAlignment = .center
        nhanTarget.numberOfLines = 0
        nhanTarget.lineBreakMode = .byWordWrapping
        nhanTarget.adjustsFontSizeToFitWidth = false
        nhanTarget.setContentCompressionResistancePriority(.required, for: .vertical)

        chamTron.backgroundColor = .white
        chamTron.layer.cornerRadius = 3.0
        chamTron.isHidden = !hienChamTron

        [nhanTieuDe, nhanGiaTriChinh, vachKe, nhanTarget, chamTron].forEach {
            $0.isUserInteractionEnabled = false
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        let trailingTieuDe: CGFloat = hienChamTron ? -10 : -2
        NSLayoutConstraint.activate([
            nhanTieuDe.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            nhanTieuDe.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            nhanTieuDe.trailingAnchor.constraint(equalTo: trailingAnchor, constant: trailingTieuDe),

            chamTron.centerYAnchor.constraint(equalTo: nhanTieuDe.centerYAnchor),
            chamTron.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3),
            chamTron.widthAnchor.constraint(equalToConstant: 5),
            chamTron.heightAnchor.constraint(equalToConstant: 5),

            nhanGiaTriChinh.topAnchor.constraint(equalTo: nhanTieuDe.bottomAnchor, constant: 1.5),
            nhanGiaTriChinh.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            nhanGiaTriChinh.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),

            vachKe.topAnchor.constraint(equalTo: nhanGiaTriChinh.bottomAnchor, constant: 2),
            vachKe.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            vachKe.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            vachKe.heightAnchor.constraint(equalToConstant: 1),

            nhanTarget.topAnchor.constraint(equalTo: vachKe.bottomAnchor, constant: 1.5),
            nhanTarget.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            nhanTarget.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            nhanTarget.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -2.5)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("Khong ho tro coder")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        lopGradient.frame = bounds
    }

    func capNhatNoiDung(chinh: String, phu: String, coLon: Bool = false) {
        nhanGiaTriChinh.text = chinh
        nhanTarget.text = phu
        nhanTieuDe.font = .systemFont(ofSize: coLon ? 11.0 : 8.5, weight: .bold)
        nhanGiaTriChinh.font = .systemFont(ofSize: coLon ? 17.0 : 13.0, weight: .heavy)
        nhanTarget.font = .systemFont(ofSize: coLon ? 10.5 : 8.0, weight: .bold)
    }

    func capNhat(doanhThu: Double, target: Double) {
        if doanhThu == 0 && target == 0 {
            nhanGiaTriChinh.text = "Chạm nhập/quét"
            nhanTarget.text = "TARGET: --"
        } else {
            nhanGiaTriChinh.text = doanhThu.chuoiSoVN
            if target > 0 {
                let pt = (doanhThu / target) * 100.0
                nhanTarget.text = "TARGET: \(target.chuoiSoVN) (\(pt.chuoiPhanTramVN))"
            } else {
                nhanTarget.text = "TARGET: 0,00"
            }
        }
    }
}

final class CumChiSoChinhView: UIControl {
    var khiDoiCheDoDoanhThu: ((LoaiCheDoDoanhThu) -> Void)?
    var khiBamBieuDo: (() -> Void)?
    var khiBamVungThe: (() -> Void)?

    private var cheDoDoanhThu: LoaiCheDoDoanhThu = .luyKe
    private var dangXemBieuDo: Bool = false
    private let nutLuyKe = UIButton(type: .custom)
    private let nutRealtime = UIButton(type: .custom)
    private let nutBieuDo = UIButton(type: .custom)
    private var luoiThe: UIStackView!

    private let theDTThuc = TheDoanhThuView(
        tieuDe: "💵 DOANH THU THỰC",
        mauBatDau: UIColor(red: 0.14, green: 0.39, blue: 0.92, alpha: 1),
        mauKetThuc: UIColor(red: 0.23, green: 0.25, blue: 0.89, alpha: 1)
    )
    private let theDTQD = TheDoanhThuView(
        tieuDe: "🎯 DOANH THU QĐ",
        mauBatDau: UIColor(red: 0.09, green: 0.61, blue: 0.27, alpha: 1),
        mauKetThuc: UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1),
        hienChamTron: true
    )
    private let theTraGop = TheDoanhThuView(
        tieuDe: "💳 % TRẢ GÓP",
        mauBatDau: UIColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1),
        mauKetThuc: UIColor(red: 0.85, green: 0.47, blue: 0.02, alpha: 1)
    )
    private let theLuotKhach = TheDoanhThuView(
        tieuDe: "👥 LƯỢT KHÁCH",
        mauBatDau: UIColor(red: 0.01, green: 0.52, blue: 0.78, alpha: 1),
        mauKetThuc: UIColor(red: 0.15, green: 0.39, blue: 0.92, alpha: 1)
    )
    private let theHTQDDuKien = TheDoanhThuView(
        tieuDe: "📈 % HT QĐ DỰ KIẾN",
        mauBatDau: UIColor(red: 0.39, green: 0.40, blue: 0.95, alpha: 1),
        mauKetThuc: UIColor(red: 0.49, green: 0.23, blue: 0.93, alpha: 1)
    )
    private let thePhanTramQD = TheDoanhThuView(
        tieuDe: "🔄 % QUY ĐỔI",
        mauBatDau: UIColor(red: 0.94, green: 0.27, blue: 0.27, alpha: 1),
        mauKetThuc: UIColor(red: 0.86, green: 0.15, blue: 0.15, alpha: 1),
        hienChamTron: true
    )
    private let theThiDuaHT = TheDoanhThuView(
        tieuDe: "🏆 THI ĐUA HOÀN THÀNH",
        mauBatDau: UIColor(red: 0.55, green: 0.36, blue: 0.96, alpha: 1),
        mauKetThuc: UIColor(red: 0.66, green: 0.33, blue: 0.97, alpha: 1)
    )
    private let theTangGiam = TheDoanhThuView(
        tieuDe: "📈 TĂNG/GIẢM CÙNG KỲ",
        mauBatDau: UIColor(red: 0.98, green: 0.45, blue: 0.09, alpha: 1),
        mauKetThuc: UIColor(red: 0.92, green: 0.35, blue: 0.05, alpha: 1)
    )

    private let coLon: Bool

    init(coLon: Bool = false) {
        self.coLon = coLon
        super.init(frame: .zero)
        taoGiaoDien()
    }

    required init?(coder: NSCoder) {
        fatalError("Khong ho tro coder")
    }

    private func cauHinhNutCheDo(_ nut: UIButton, tieuDe: String) {
        nut.setTitle(tieuDe, for: .normal)
        nut.titleLabel?.font = .systemFont(ofSize: coLon ? 13.5 : 12.0, weight: .bold)
        nut.titleLabel?.numberOfLines = 0
        nut.titleLabel?.lineBreakMode = .byWordWrapping
        nut.titleLabel?.textAlignment = .center
        nut.titleLabel?.adjustsFontSizeToFitWidth = false
        nut.contentEdgeInsets = UIEdgeInsets(top: 5, left: 6, bottom: 5, right: 6)
        nut.layer.cornerRadius = 10
        nut.layer.borderWidth = 1
    }

    private func taoGiaoDien() {
        // Yêu cầu 1: Bỏ chữ "Doanh thu" ra khỏi 2 nút trên đầu, chỉ còn "Lũy kế" và "Realtime"
        nutLuyKe.tag = LoaiCheDoDoanhThu.luyKe.rawValue
        cauHinhNutCheDo(nutLuyKe, tieuDe: "📊 Lũy kế")
        nutLuyKe.addTarget(self, action: #selector(bamChonCheDo(_:)), for: .touchUpInside)

        nutRealtime.tag = LoaiCheDoDoanhThu.realtime.rawValue
        cauHinhNutCheDo(nutRealtime, tieuDe: "⚡ Realtime")
        nutRealtime.addTarget(self, action: #selector(bamChonCheDo(_:)), for: .touchUpInside)

        cauHinhNutCheDo(nutBieuDo, tieuDe: "📈 Biểu đồ")
        nutBieuDo.isHidden = coLon
        nutBieuDo.addTarget(self, action: #selector(bamNutBieuDo), for: .touchUpInside)

        let cacNutTren: [UIView] = coLon ? [nutLuyKe, nutRealtime] : [nutLuyKe, nutRealtime, nutBieuDo]
        let hangBaNut = UIStackView(arrangedSubviews: cacNutTren)
        hangBaNut.axis = .horizontal
        hangBaNut.spacing = 6
        hangBaNut.distribution = .fillEqually

        let tatCaThe = [theDTThuc, theDTQD, theTraGop, theLuotKhach, theHTQDDuKien, thePhanTramQD, theThiDuaHT, theTangGiam]
        tatCaThe.forEach { $0.isUserInteractionEnabled = false }

        let khoangCach: CGFloat = coLon ? 10 : 5
        let hang1 = UIStackView(arrangedSubviews: [theDTThuc, theDTQD, theTraGop, theLuotKhach])
        hang1.axis = .horizontal
        hang1.spacing = khoangCach
        hang1.distribution = .fillEqually
        hang1.isUserInteractionEnabled = false

        let hang2 = UIStackView(arrangedSubviews: [theHTQDDuKien, thePhanTramQD, theThiDuaHT, theTangGiam])
        hang2.axis = .horizontal
        hang2.spacing = khoangCach
        hang2.distribution = .fillEqually
        hang2.isUserInteractionEnabled = false

        luoiThe = UIStackView(arrangedSubviews: [hang1, hang2])
        luoiThe.axis = .vertical
        luoiThe.spacing = khoangCach
        luoiThe.distribution = .fillEqually
        luoiThe.isUserInteractionEnabled = true

        let tapLuoiThe = UITapGestureRecognizer(target: self, action: #selector(bamVaoLuoiThe))
        luoiThe.addGestureRecognizer(tapLuoiThe)

        let nganChinh = UIStackView(arrangedSubviews: [hangBaNut, luoiThe])
        nganChinh.axis = .vertical
        nganChinh.spacing = coLon ? 8 : 6
        nganChinh.isUserInteractionEnabled = true
        nganChinh.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nganChinh)

        NSLayoutConstraint.activate([
            hangBaNut.heightAnchor.constraint(greaterThanOrEqualToConstant: coLon ? 38 : 34),
            nganChinh.topAnchor.constraint(equalTo: topAnchor),
            nganChinh.leadingAnchor.constraint(equalTo: leadingAnchor),
            nganChinh.trailingAnchor.constraint(equalTo: trailingAnchor),
            nganChinh.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        capNhatMauNutCheDo()
    }

    @objc private func bamChonCheDo(_ sender: UIButton) {
        guard let moi = LoaiCheDoDoanhThu(rawValue: sender.tag) else { return }
        if moi == cheDoDoanhThu && !dangXemBieuDo { return }
        cheDoDoanhThu = moi
        dangXemBieuDo = false
        capNhatMauNutCheDo()
        khiDoiCheDoDoanhThu?(moi)
    }

    @objc private func bamNutBieuDo() {
        dangXemBieuDo = true
        capNhatMauNutCheDo()
        khiBamBieuDo?()
    }

    @objc private func bamVaoLuoiThe() {
        if let khiBamVungThe {
            khiBamVungThe()
        } else {
            sendActions(for: .touchUpInside)
        }
    }

    private func capNhatMauNutCheDo() {
        for (nut, loai) in [(nutLuyKe, LoaiCheDoDoanhThu.luyKe), (nutRealtime, LoaiCheDoDoanhThu.realtime)] {
            if !dangXemBieuDo && cheDoDoanhThu == loai {
                nut.backgroundColor = .systemBlue
                nut.setTitleColor(.white, for: .normal)
                nut.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                nut.backgroundColor = .systemBackground
                nut.setTitleColor(.label, for: .normal)
                nut.layer.borderColor = UIColor.separator.cgColor
            }
        }
        if dangXemBieuDo {
            nutBieuDo.backgroundColor = .systemBlue
            nutBieuDo.setTitleColor(.white, for: .normal)
            nutBieuDo.layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            nutBieuDo.backgroundColor = .systemBackground
            nutBieuDo.setTitleColor(.label, for: .normal)
            nutBieuDo.layer.borderColor = UIColor.separator.cgColor
        }
        luoiThe?.isHidden = dangXemBieuDo
    }

    func capNhat(
        doanhThu dt: ThongTinDoanhThu,
        soNganhDat: Int,
        tongSoNganh: Int,
        ngay: Date = Date(),
        cheDo: LoaiCheDoDoanhThu = .luyKe,
        dangXemBieuDo: Bool = false
    ) {
        self.cheDoDoanhThu = cheDo
        self.dangXemBieuDo = dangXemBieuDo
        capNhatMauNutCheDo()

        if !dt.coDuLieu {
            theDTThuc.capNhatNoiDung(chinh: coLon ? "0,00" : "Chạm quét", phu: "TARGET: --", coLon: coLon)
            theDTQD.capNhatNoiDung(chinh: coLon ? "0,00" : "Chạm quét", phu: "TARGET: --", coLon: coLon)
        } else {
            let phuThuc: String
            if dt.phanTramHTThuc > 0 && dt.targetThuc > 0 {
                phuThuc = "TARGET: \(dt.targetThuc.chuoiSoGonVN) (\(dt.phanTramHTThuc.chuoiPhanTram))"
            } else {
                phuThuc = "TARGET: \(dt.targetThuc.chuoiSoGonVN)"
            }
            theDTThuc.capNhatNoiDung(
                chinh: dt.doanhThuThuc.chuoiSoGonVN,
                phu: phuThuc,
                coLon: coLon
            )

            let phuQD: String
            if dt.phanTramHTQuyDoi > 0 && dt.targetQuyDoi > 0 {
                phuQD = "TARGET: \(dt.targetQuyDoi.chuoiSoGonVN) (\(dt.phanTramHTQuyDoi.chuoiPhanTram))"
            } else {
                phuQD = "TARGET: \(dt.targetQuyDoi.chuoiSoGonVN)"
            }
            theDTQD.capNhatNoiDung(
                chinh: dt.doanhThuQuyDoi.chuoiSoGonVN,
                phu: phuQD,
                coLon: coLon
            )
        }

        theTraGop.capNhatNoiDung(
            chinh: dt.phanTramTraGop.chuoiPhanTram,
            phu: "DT: \(dt.doanhThuTraGop.chuoiSoGonVN)",
            coLon: coLon
        )

        theLuotKhach.capNhatNoiDung(
            chinh: dt.luotKhach.chuoiSoNguyenVN,
            phu: "BILL: \(dt.soBill.chuoiSoNguyenVN) | PVTC: \(dt.phanTramPVTC.chuoiPhanTram)",
            coLon: coLon
        )

        let ptGoc = dt.phanTramHTQDDuKienHienThi
        let dkGoc = dt.duKienQuyDoi > 0 ? dt.duKienQuyDoi : dt.duKienThuc
        theHTQDDuKien.capNhatNoiDung(
            chinh: ptGoc.chuoiPhanTram,
            phu: "DTQĐ DK: \(dkGoc.chuoiSoGonVN)",
            coLon: coLon
        )

        thePhanTramQD.capNhatNoiDung(
            chinh: dt.phanTramQuyDoi.chuoiPhanTramVN,
            phu: "MỤC TIÊU: 50%",
            coLon: coLon
        )

        let tyLeTD = tongSoNganh > 0 ? Int(round(Double(soNganhDat) / Double(tongSoNganh) * 100.0)) : 0
        theThiDuaHT.capNhatNoiDung(
            chinh: "\(soNganhDat)/\(tongSoNganh)",
            phu: "TỶ LỆ: \(tyLeTD)%",
            coLon: coLon
        )

        let dauTG = dt.tangGiamCungKy > 0 ? "+" : ""
        let phuTG = dt.tb3Thang > 0 ? "TB3T: \(dt.tb3Thang.chuoiSoGonVN)" : "TB3T: 0"
        theTangGiam.capNhatNoiDung(
            chinh: "\(dauTG)\(dt.tangGiamCungKy.chuoiPhanTram)",
            phu: phuTG,
            coLon: coLon
        )

        setNeedsLayout()
        layoutIfNeeded()
    }
}

// MARK: - Ô Thẻ Tiến Độ Gọn (Mẫu hiển thị 2 — toàn bộ các dòng text có cùng cỡ chữ 12.5pt, tự xuống dòng, không bao giờ "...")

final class OTheThiDuaCell: UICollectionViewCell {
    static let ma = "OTheThiDuaCell"
    static let coChuDongNhat: CGFloat = 12.5

    private let khungThe = UIView()
    private let nhanTen = UILabel()
    private let nhanPhanTram = UILabel()
    private let nhanThucHienTarget = UILabel()
    private let nhanConThieu = UILabel()
    private let thanhNenTienDo = UIView()
    private let thanhMauTienDo = UIView()
    private var rangBuocRongTienDo: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        taoGiaoDien()
    }

    required init?(coder: NSCoder) {
        fatalError("Khong ho tro coder")
    }

    private func taoGiaoDien() {
        let fontDam = UIFont.systemFont(ofSize: Self.coChuDongNhat, weight: .bold)
        let fontVua = UIFont.systemFont(ofSize: Self.coChuDongNhat, weight: .semibold)

        khungThe.backgroundColor = .systemBackground
        khungThe.layer.cornerRadius = 12
        khungThe.layer.borderWidth = 1
        khungThe.layer.borderColor = UIColor.systemGray5.cgColor
        khungThe.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(khungThe)

        nhanTen.font = fontDam
        nhanTen.textColor = .label
        nhanTen.numberOfLines = 0
        nhanTen.lineBreakMode = .byWordWrapping
        nhanTen.adjustsFontSizeToFitWidth = false
        nhanTen.setContentCompressionResistancePriority(.required, for: .vertical)

        nhanPhanTram.font = fontDam
        nhanPhanTram.textAlignment = .center
        nhanPhanTram.numberOfLines = 0
        nhanPhanTram.lineBreakMode = .byWordWrapping
        nhanPhanTram.layer.cornerRadius = 11
        nhanPhanTram.clipsToBounds = true
        nhanPhanTram.adjustsFontSizeToFitWidth = false
        nhanPhanTram.setContentHuggingPriority(.required, for: .horizontal)
        nhanPhanTram.setContentCompressionResistancePriority(.required, for: .horizontal)

        nhanThucHienTarget.font = fontDam
        nhanThucHienTarget.textColor = .label
        nhanThucHienTarget.numberOfLines = 0
        nhanThucHienTarget.lineBreakMode = .byWordWrapping
        nhanThucHienTarget.adjustsFontSizeToFitWidth = false
        nhanThucHienTarget.setContentCompressionResistancePriority(.required, for: .vertical)

        nhanConThieu.font = fontVua
        nhanConThieu.textColor = .secondaryLabel
        nhanConThieu.textAlignment = .right
        nhanConThieu.numberOfLines = 0
        nhanConThieu.lineBreakMode = .byWordWrapping
        nhanConThieu.adjustsFontSizeToFitWidth = false
        nhanConThieu.setContentHuggingPriority(.required, for: .horizontal)
        nhanConThieu.setContentCompressionResistancePriority(.required, for: .horizontal)
        nhanConThieu.setContentCompressionResistancePriority(.required, for: .vertical)

        thanhNenTienDo.backgroundColor = UIColor.systemGray5
        thanhNenTienDo.layer.cornerRadius = 2.5
        thanhNenTienDo.clipsToBounds = true

        thanhMauTienDo.layer.cornerRadius = 2.5
        thanhMauTienDo.translatesAutoresizingMaskIntoConstraints = false
        thanhNenTienDo.addSubview(thanhMauTienDo)

        [nhanTen, nhanPhanTram, nhanThucHienTarget, nhanConThieu, thanhNenTienDo].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            khungThe.addSubview($0)
        }

        let rgRong = thanhMauTienDo.widthAnchor.constraint(equalToConstant: 0)
        rangBuocRongTienDo = rgRong

        NSLayoutConstraint.activate([
            khungThe.topAnchor.constraint(equalTo: contentView.topAnchor),
            khungThe.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            khungThe.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            khungThe.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            nhanTen.topAnchor.constraint(equalTo: khungThe.topAnchor, constant: 10),
            nhanTen.leadingAnchor.constraint(equalTo: khungThe.leadingAnchor, constant: 10),
            nhanTen.trailingAnchor.constraint(lessThanOrEqualTo: nhanPhanTram.leadingAnchor, constant: -6),

            nhanPhanTram.topAnchor.constraint(equalTo: khungThe.topAnchor, constant: 8),
            nhanPhanTram.trailingAnchor.constraint(equalTo: khungThe.trailingAnchor, constant: -10),
            nhanPhanTram.widthAnchor.constraint(greaterThanOrEqualToConstant: 68),
            nhanPhanTram.heightAnchor.constraint(greaterThanOrEqualToConstant: 22),

            thanhNenTienDo.leadingAnchor.constraint(equalTo: khungThe.leadingAnchor, constant: 10),
            thanhNenTienDo.trailingAnchor.constraint(equalTo: khungThe.trailingAnchor, constant: -10),
            thanhNenTienDo.bottomAnchor.constraint(equalTo: khungThe.bottomAnchor, constant: -9),
            thanhNenTienDo.heightAnchor.constraint(equalToConstant: 5),

            thanhMauTienDo.leadingAnchor.constraint(equalTo: thanhNenTienDo.leadingAnchor),
            thanhMauTienDo.topAnchor.constraint(equalTo: thanhNenTienDo.topAnchor),
            thanhMauTienDo.bottomAnchor.constraint(equalTo: thanhNenTienDo.bottomAnchor),
            rgRong,

            nhanThucHienTarget.topAnchor.constraint(greaterThanOrEqualTo: nhanTen.bottomAnchor, constant: 6),
            nhanThucHienTarget.bottomAnchor.constraint(equalTo: thanhNenTienDo.topAnchor, constant: -6),
            nhanThucHienTarget.leadingAnchor.constraint(equalTo: khungThe.leadingAnchor, constant: 10),
            nhanThucHienTarget.trailingAnchor.constraint(lessThanOrEqualTo: nhanConThieu.leadingAnchor, constant: -6),

            nhanConThieu.centerYAnchor.constraint(equalTo: nhanThucHienTarget.centerYAnchor),
            nhanConThieu.trailingAnchor.constraint(equalTo: khungThe.trailingAnchor, constant: -10)
        ])
    }

    private var tyLeTienDoHienTai: CGFloat = 0

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
        contentView.layoutIfNeeded()
        let rongToiDa = thanhNenTienDo.bounds.width
        rangBuocRongTienDo?.constant = rongToiDa * min(1.0, max(0.0, tyLeTienDoHienTai))
    }

    static func tinhChieuCaoThe(cho dong: DongThiDua, rongThe: CGFloat, xemDuKien: Bool) -> CGFloat {
        let font = UIFont.systemFont(ofSize: Self.coChuDongNhat, weight: .bold)
        let pt = xemDuKien ? dong.phanTramDuBao : dong.phanTramHT
        let chuoiPT = "  \(pt.chuoiPhanTramVN)  "
        let rongPT = max(68, ceil((chuoiPT as NSString).size(withAttributes: [.font: font]).width) + 6)

        let rongTen = max(60, rongThe - 20 - rongPT - 8)
        let rectTen = (dong.tenNganhHang as NSString).boundingRect(
            with: CGSize(width: rongTen, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        let caoTen = max(20, ceil(rectTen.height))

        let chuoiTrai = xemDuKien
            ? "DK: \(dong.duKien.chuoiSoVN) / \(dong.target.chuoiSoVN) \(dong.loaiChiTieu.maThe)"
            : "\(dong.thucHien.chuoiSoVN) / \(dong.target.chuoiSoVN) \(dong.loaiChiTieu.maThe)"
        let chuoiPhai = xemDuKien
            ? (dong.conThieuDuKien > 0.005 ? "Còn DK: \(dong.conThieuDuKien.chuoiSoVN)" : "Vượt DK: \(dong.vuotMucDuKien.chuoiSoVN)")
            : (dong.conThieu > 0.005 ? "Còn: \(dong.conThieu.chuoiSoVN)" : "Vượt: \(dong.vuotMuc.chuoiSoVN)")

        let rongPhai = ceil((chuoiPhai as NSString).size(withAttributes: [.font: font]).width) + 6
        let rongTrai = max(60, rongThe - 20 - rongPhai - 8)
        let rectTrai = (chuoiTrai as NSString).boundingRect(
            with: CGSize(width: rongTrai, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        let caoSo = max(20, ceil(rectTrai.height))
        return max(88, 10 + caoTen + 8 + caoSo + 8 + 5 + 12)
    }

    func gan(_ dong: DongThiDua, xemDuKien: Bool = false) {
        nhanTen.text = dong.tenNganhHang
        let pt = xemDuKien ? dong.phanTramDuBao : dong.phanTramHT
        nhanPhanTram.text = "  \(pt.chuoiPhanTramVN)  "

        if pt >= 99.995 {
            nhanPhanTram.backgroundColor = UIColor(red: 0.86, green: 0.99, blue: 0.90, alpha: 1)
            nhanPhanTram.textColor = UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1)
            thanhMauTienDo.backgroundColor = UIColor(red: 0.09, green: 0.64, blue: 0.29, alpha: 1)
        } else if pt >= 80.0 {
            nhanPhanTram.backgroundColor = UIColor(red: 0.99, green: 0.95, blue: 0.78, alpha: 1)
            nhanPhanTram.textColor = UIColor(red: 0.71, green: 0.33, blue: 0.04, alpha: 1)
            thanhMauTienDo.backgroundColor = UIColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1)
        } else {
            nhanPhanTram.backgroundColor = UIColor(red: 0.99, green: 0.89, blue: 0.89, alpha: 1)
            nhanPhanTram.textColor = UIColor(red: 0.73, green: 0.11, blue: 0.11, alpha: 1)
            thanhMauTienDo.backgroundColor = (pt >= 70.0)
                ? UIColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1)
                : UIColor(red: 0.86, green: 0.15, blue: 0.15, alpha: 1)
        }

        let chuoiDam = xemDuKien ? "DK: \(dong.duKien.chuoiSoVN)" : dong.thucHien.chuoiSoVN
        let chuoiMo = " / \(dong.target.chuoiSoVN) \(dong.loaiChiTieu.maThe)"
        let attr = NSMutableAttributedString(
            string: chuoiDam,
            attributes: [
                .font: UIFont.systemFont(ofSize: Self.coChuDongNhat, weight: .bold),
                .foregroundColor: UIColor.label
            ]
        )
        attr.append(NSAttributedString(
            string: chuoiMo,
            attributes: [
                .font: UIFont.systemFont(ofSize: Self.coChuDongNhat, weight: .semibold),
                .foregroundColor: UIColor.secondaryLabel
            ]
        ))
        nhanThucHienTarget.attributedText = attr

        if xemDuKien {
            if dong.conThieuDuKien > 0.005 {
                nhanConThieu.text = "Còn DK: \(dong.conThieuDuKien.chuoiSoVN)"
                nhanConThieu.textColor = .secondaryLabel
            } else {
                nhanConThieu.text = "Vượt DK: \(dong.vuotMucDuKien.chuoiSoVN)"
                nhanConThieu.textColor = UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1)
            }
        } else {
            if dong.conThieu > 0.005 {
                nhanConThieu.text = "Còn: \(dong.conThieu.chuoiSoVN)"
                nhanConThieu.textColor = .secondaryLabel
            } else {
                nhanConThieu.text = "Vượt: \(dong.vuotMuc.chuoiSoVN)"
                nhanConThieu.textColor = UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1)
            }
        }

        tyLeTienDoHienTai = CGFloat(min(1.0, max(0.03, pt / 100.0)))
        setNeedsLayout()
    }
}

// MARK: - BangThiDuaView (Hỗ trợ cả 2 mẫu: Bảng 8 cột & Thẻ tiến độ gọn + Nút "% dự kiến" riêng ở Tab Lũy kế)

final class BangThiDuaView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate {
    var khiChonDong: ((DongThiDua) -> Void)?
    var khiSuaDong: ((DongThiDua) -> Void)?
    var khiXoaDong: ((UUID) -> Void)?
    var khiBamQuetAnh: (() -> Void)?
    var khiDoiCheDoDuKien: ((Bool) -> Void)?

    private var danhSachGoc: [DongThiDua] = []
    private var danhSachHienThi: [DongThiDua] = []
    private(set) var cheDoDoanhThu: LoaiCheDoDoanhThu = .luyKe
    private(set) var dangXemDuKien: Bool = false
    var hieuLucXemDuKien: Bool {
        cheDoDoanhThu == .luyKe && dangXemDuKien
    }

    private var boLoc: BoLocThiDua = .tatCa
    private var kieuSapXep: KieuSapXepThiDua = .phanTramCaoThap
    private var soCotTrenDienThoai: Int = 1
    private let tieuDeTrong = UILabel()
    private let phuDeTrong = UILabel()

    private let chieuRongCot: [CGFloat] = [42, 224, 52, 92, 92, 96, 88, 88]
    private var tongChieuRongBang: CGFloat { chieuRongCot.reduce(0, +) }

    private let chonBoLoc = UISegmentedControl(items: ["Tất cả", "Đạt", "Chưa đạt"])
    private let nutPhanTramDuKien = UIButton(type: .system)
    private let nutSapXep = UIButton(type: .system)
    private let nutSoCot = UIButton(type: .system)

    private let cuonNgang = UIScrollView()
    private let bang8Cot = UITableView(frame: .zero, style: .plain)

    private lazy var luoi: UICollectionView = {
        let boCuc = UICollectionViewFlowLayout()
        boCuc.minimumLineSpacing = 8
        boCuc.minimumInteritemSpacing = 8
        let cv = UICollectionView(frame: .zero, collectionViewLayout: boCuc)
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.alwaysBounceVertical = true
        cv.register(OTheThiDuaCell.self, forCellWithReuseIdentifier: OTheThiDuaCell.ma)
        return cv
    }()

    private let khungTrong = UIControl()

    override init(frame: CGRect) {
        super.init(frame: frame)
        taoGiaoDien()
    }

    required init?(coder: NSCoder) {
        fatalError("Khong ho tro coder")
    }

    private func cauHinhNutDieuKhien(_ nut: UIButton) {
        nut.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nut.titleLabel?.numberOfLines = 0
        nut.titleLabel?.lineBreakMode = .byWordWrapping
        nut.titleLabel?.textAlignment = .center
        nut.titleLabel?.adjustsFontSizeToFitWidth = false
        nut.layer.cornerRadius = 8
        nut.layer.borderWidth = 1
        nut.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
    }

    private func taoGiaoDien() {
        backgroundColor = .clear

        chonBoLoc.selectedSegmentIndex = 0
        chonBoLoc.apportionsSegmentWidthsByContent = false
        chonBoLoc.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 11.5, weight: .semibold)], for: .normal)
        chonBoLoc.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 11.5, weight: .bold)], for: .selected)
        chonBoLoc.addTarget(self, action: #selector(doiBoLoc), for: .valueChanged)

        nutPhanTramDuKien.setTitle("% dự kiến", for: .normal)
        cauHinhNutDieuKhien(nutPhanTramDuKien)
        nutPhanTramDuKien.addTarget(self, action: #selector(doiCheDoXemDuKien), for: .touchUpInside)
        capNhatGiaoDienNutDuKien()

        nutSapXep.setTitle("⇅ \(kieuSapXep.nhanNgan)", for: .normal)
        cauHinhNutDieuKhien(nutSapXep)
        nutSapXep.backgroundColor = .secondarySystemGroupedBackground
        nutSapXep.tintColor = .systemBlue
        nutSapXep.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.25).cgColor
        nutSapXep.addTarget(self, action: #selector(bamMoMenuSapXep), for: .touchUpInside)

        nutSoCot.setTitle(" 1 cột", for: .normal)
        nutSoCot.setImage(UIImage(systemName: "rectangle.grid.1x2"), for: .normal)
        cauHinhNutDieuKhien(nutSoCot)
        nutSoCot.backgroundColor = .secondarySystemGroupedBackground
        nutSoCot.tintColor = .systemBlue
        nutSoCot.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.25).cgColor
        nutSoCot.addTarget(self, action: #selector(doiSoCot), for: .touchUpInside)

        let hangNutPhu = UIStackView(arrangedSubviews: [nutPhanTramDuKien, nutSapXep, nutSoCot])
        hangNutPhu.axis = .horizontal
        hangNutPhu.spacing = 6
        hangNutPhu.distribution = .fillEqually

        let thanhDieuKhien = UIStackView(arrangedSubviews: [chonBoLoc, hangNutPhu])
        thanhDieuKhien.axis = .vertical
        thanhDieuKhien.spacing = 6

        cuonNgang.showsHorizontalScrollIndicator = true
        cuonNgang.showsVerticalScrollIndicator = false
        cuonNgang.bounces = false
        cuonNgang.layer.cornerRadius = 12
        cuonNgang.clipsToBounds = true
        cuonNgang.backgroundColor = .systemBackground

        bang8Cot.dataSource = self
        bang8Cot.delegate = self
        bang8Cot.rowHeight = 56
        bang8Cot.sectionHeaderHeight = 42
        bang8Cot.separatorStyle = .singleLine
        bang8Cot.separatorInset = .zero
        bang8Cot.backgroundColor = .systemBackground
        if #available(iOS 15.0, *) {
            bang8Cot.sectionHeaderTopPadding = 0
        }
        bang8Cot.translatesAutoresizingMaskIntoConstraints = false
        cuonNgang.addSubview(bang8Cot)

        khungTrong.backgroundColor = .secondarySystemGroupedBackground
        khungTrong.layer.cornerRadius = 14
        khungTrong.addTarget(self, action: #selector(bamQuet), for: .touchUpInside)

        let iconTrong = UIImageView(image: UIImage(systemName: "camera.viewfinder"))
        iconTrong.tintColor = .systemBlue
        iconTrong.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 42, weight: .regular)

        tieuDeTrong.text = "Chạm để chọn ảnh Thi đua (Lũy kế)"
        tieuDeTrong.font = .systemFont(ofSize: 15, weight: .bold)
        tieuDeTrong.textAlignment = .center
        tieuDeTrong.numberOfLines = 0
        tieuDeTrong.lineBreakMode = .byWordWrapping

        phuDeTrong.text = "Bảng Thi đua Lũy kế và Thi đua Realtime được lưu riêng biệt.\nChạm vào đây hoặc nút Thêm ảnh để tải ảnh Thi đua."
        phuDeTrong.font = .systemFont(ofSize: 12.5, weight: .regular)
        phuDeTrong.textColor = .secondaryLabel
        phuDeTrong.textAlignment = .center
        phuDeTrong.numberOfLines = 0
        phuDeTrong.lineBreakMode = .byWordWrapping

        let nganTrong = UIStackView(arrangedSubviews: [iconTrong, tieuDeTrong, phuDeTrong])
        nganTrong.axis = .vertical
        nganTrong.spacing = 8
        nganTrong.alignment = .center
        nganTrong.isUserInteractionEnabled = false
        nganTrong.translatesAutoresizingMaskIntoConstraints = false
        khungTrong.addSubview(nganTrong)

        [thanhDieuKhien, cuonNgang, luoi, khungTrong].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            chonBoLoc.heightAnchor.constraint(equalToConstant: 30),
            hangNutPhu.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),

            thanhDieuKhien.topAnchor.constraint(equalTo: topAnchor),
            thanhDieuKhien.leadingAnchor.constraint(equalTo: leadingAnchor),
            thanhDieuKhien.trailingAnchor.constraint(equalTo: trailingAnchor),

            cuonNgang.topAnchor.constraint(equalTo: thanhDieuKhien.bottomAnchor, constant: 6),
            cuonNgang.leadingAnchor.constraint(equalTo: leadingAnchor),
            cuonNgang.trailingAnchor.constraint(equalTo: trailingAnchor),
            cuonNgang.bottomAnchor.constraint(equalTo: bottomAnchor),

            bang8Cot.topAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.topAnchor),
            bang8Cot.bottomAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.bottomAnchor),
            bang8Cot.leadingAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.leadingAnchor),
            bang8Cot.trailingAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.trailingAnchor),
            bang8Cot.heightAnchor.constraint(equalTo: cuonNgang.frameLayoutGuide.heightAnchor),
            bang8Cot.widthAnchor.constraint(equalToConstant: tongChieuRongBang),

            luoi.topAnchor.constraint(equalTo: thanhDieuKhien.bottomAnchor, constant: 6),
            luoi.leadingAnchor.constraint(equalTo: leadingAnchor),
            luoi.trailingAnchor.constraint(equalTo: trailingAnchor),
            luoi.bottomAnchor.constraint(equalTo: bottomAnchor),

            khungTrong.topAnchor.constraint(equalTo: thanhDieuKhien.bottomAnchor, constant: 6),
            khungTrong.leadingAnchor.constraint(equalTo: leadingAnchor),
            khungTrong.trailingAnchor.constraint(equalTo: trailingAnchor),
            khungTrong.bottomAnchor.constraint(equalTo: bottomAnchor),

            nganTrong.centerXAnchor.constraint(equalTo: khungTrong.centerXAnchor),
            nganTrong.centerYAnchor.constraint(equalTo: khungTrong.centerYAnchor),
            nganTrong.leadingAnchor.constraint(greaterThanOrEqualTo: khungTrong.leadingAnchor, constant: 20),
            nganTrong.trailingAnchor.constraint(lessThanOrEqualTo: khungTrong.trailingAnchor, constant: -20)
        ])

        capNhatDanhSach()
    }

    private func capNhatGiaoDienNutDuKien() {
        nutPhanTramDuKien.isHidden = (cheDoDoanhThu != .luyKe)
        if hieuLucXemDuKien {
            let mauXanh = UIColor(red: 0.08, green: 0.56, blue: 0.26, alpha: 1)
            nutPhanTramDuKien.backgroundColor = mauXanh
            nutPhanTramDuKien.tintColor = .white
            nutPhanTramDuKien.layer.borderColor = mauXanh.cgColor
        } else {
            nutPhanTramDuKien.backgroundColor = .secondarySystemGroupedBackground
            nutPhanTramDuKien.tintColor = .systemBlue
            nutPhanTramDuKien.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        }
    }

    @objc private func doiCheDoXemDuKien() {
        guard cheDoDoanhThu == .luyKe else { return }
        dangXemDuKien.toggle()
        capNhatGiaoDienNutDuKien()
        capNhatDanhSach()
        khiDoiCheDoDuKien?(hieuLucXemDuKien)
    }

    @objc private func bamMoMenuSapXep() {
        guard let vc = timViewControllerCha() else { return }
        var cacMuc: [MucChonDMX] = KieuSapXepThiDua.allCases.map { kieu in
            MucChonDMX(tieuDe: kieu.nhan, dangChon: kieu == kieuSapXep) { [weak self] in
                guard let self else { return }
                self.kieuSapXep = kieu
                self.nutSapXep.setTitle("⇅ \(kieu.nhanNgan)", for: .normal)
                self.capNhatDanhSach()
            }
        }
        cacMuc.append(MucChonDMX(tieuDe: "Đóng", kieu: .huy))
        vc.hienMenuChon(tieuDe: "Sắp xếp ngành hàng", cacMuc: cacMuc)
    }

    func ganDanhSach(_ ds: [DongThiDua], cheDo: LoaiCheDoDoanhThu = .luyKe) {
        cheDoDoanhThu = cheDo
        danhSachGoc = ds
        capNhatGiaoDienNutDuKien()
        capNhatDanhSach()
    }

    private func locVaSapXep(_ dsGoc: [DongThiDua], xemDuKien: Bool? = nil) -> [DongThiDua] {
        let xemDK = xemDuKien ?? hieuLucXemDuKien
        var tam = dsGoc
        switch boLoc {
        case .tatCa: break
        case .daDat: tam = tam.filter { xemDK ? $0.daHoanThanhDuBao : $0.daDat }
        case .chuaDat: tam = tam.filter { xemDK ? !$0.daHoanThanhDuBao : !$0.daDat }
        }

        switch kieuSapXep {
        case .phanTramCaoThap:
            tam.sort { (xemDK ? $0.phanTramDuBao : $0.phanTramHT) > (xemDK ? $1.phanTramDuBao : $1.phanTramHT) }
        case .phanTramThapCao:
            tam.sort { (xemDK ? $0.phanTramDuBao : $0.phanTramHT) < (xemDK ? $1.phanTramDuBao : $1.phanTramHT) }
        case .tenAZ:
            tam.sort { tenDeSapXep($0.tenNganhHang).localizedCaseInsensitiveCompare(tenDeSapXep($1.tenNganhHang)) == .orderedAscending }
        case .tenZA:
            tam.sort { tenDeSapXep($0.tenNganhHang).localizedCaseInsensitiveCompare(tenDeSapXep($1.tenNganhHang)) == .orderedDescending }
        case .thuTuGoc:
            break
        }
        return tam
    }

    private func capNhatDanhSach() {
        capNhatGiaoDienNutDuKien()
        let xemDK = hieuLucXemDuKien
        let tong = danhSachGoc.count
        let soDat = danhSachGoc.filter { xemDK ? $0.daHoanThanhDuBao : $0.daDat }.count
        let soChuaDat = tong - soDat

        chonBoLoc.setTitle("Tất cả (\(tong))", forSegmentAt: 0)
        chonBoLoc.setTitle("Đạt (\(soDat))", forSegmentAt: 1)
        chonBoLoc.setTitle("Chưa đạt (\(soChuaDat))", forSegmentAt: 2)
        chonBoLoc.damBaoHienThiDayDuText()

        let nhanCheDo = (cheDoDoanhThu == .luyKe) ? "Lũy kế" : "Realtime"
        tieuDeTrong.text = "Chạm để chọn ảnh Thi đua (\(nhanCheDo))"
        phuDeTrong.text = "Bảng Thi đua Lũy kế và Thi đua Realtime được lưu riêng biệt.\nChạm vào đây hoặc nút Thêm ảnh để tải ảnh Thi đua \(nhanCheDo)."

        danhSachHienThi = locVaSapXep(danhSachGoc, xemDuKien: xemDK)
        let kieu = KhoDuLieu.dungChung.caiDat.kieuHienThi
        let trong = danhSachGoc.isEmpty

        khungTrong.isHidden = !trong
        cuonNgang.isHidden = trong || (kieu != .bangChiTiet)
        luoi.isHidden = trong || (kieu != .theGon)
        nutSoCot.isHidden = (kieu != .theGon)

        bang8Cot.reloadData()
        luoi.collectionViewLayout.invalidateLayout()
        luoi.reloadData()
    }

    private func tenDeSapXep(_ ten: String) -> String {
        ten.replacingOccurrences(of: "^T\\d{1,2}\\s*[-–]\\s*", with: "", options: .regularExpression)
    }

    @objc private func doiBoLoc() {
        boLoc = BoLocThiDua(rawValue: chonBoLoc.selectedSegmentIndex) ?? .tatCa
        capNhatDanhSach()
    }

    @objc private func doiSoCot() {
        soCotTrenDienThoai = (soCotTrenDienThoai == 1) ? 2 : 1
        let icon = (soCotTrenDienThoai == 1) ? "rectangle.grid.1x2" : "square.grid.2x2"
        nutSoCot.setTitle(" \(soCotTrenDienThoai) cột", for: .normal)
        nutSoCot.setImage(UIImage(systemName: icon), for: .normal)
        luoi.collectionViewLayout.invalidateLayout()
        luoi.reloadData()
    }

    @objc private func bamQuet() {
        khiBamQuetAnh?()
    }

    // MARK: - Mẫu 2: UICollectionView (Thẻ tiến độ)

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        danhSachHienThi.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OTheThiDuaCell.ma, for: indexPath) as! OTheThiDuaCell
        cell.gan(danhSachHienThi[indexPath.item], xemDuKien: hieuLucXemDuKien)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        khiChonDong?(danhSachHienThi[indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let rong = collectionView.bounds.width
        let dong = danhSachHienThi[indexPath.item]
        let xemDK = hieuLucXemDuKien
        if soCotTrenDienThoai == 2 {
            let rongCot = floor((rong - 8) / 2.0)
            let caoCot = OTheThiDuaCell.tinhChieuCaoThe(cho: dong, rongThe: rongCot, xemDuKien: xemDK)
            return CGSize(width: rongCot, height: caoCot)
        }
        let cao = OTheThiDuaCell.tinhChieuCaoThe(cho: dong, rongThe: rong, xemDuKien: xemDK)
        return CGSize(width: rong, height: cao)
    }

    // MARK: - Mẫu 1: UITableView (Bảng 8 cột chi tiết — tự mở rộng chiều cao dòng khi chữ nhiều, cỡ chữ đồng nhất, không bao giờ "...")

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        danhSachHienThi.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        taoDongTieuDeCot(cheDo: cheDoDoanhThu, xemDuKien: hieuLucXemDuKien)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let dong = danhSachHienThi[indexPath.row]
        return tinhChieuCaoDong8Cot(dong: dong, hienNhanNV: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ma = "DongBang8CotCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: ma) ?? UITableViewCell(style: .default, reuseIdentifier: ma)
        cell.selectionStyle = .default
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let dong = danhSachHienThi[indexPath.row]
        let caoDong = tinhChieuCaoDong8Cot(dong: dong, hienNhanNV: true)
        let viewDong = taoViewDongDuLieu8Cot(
            stt: indexPath.row + 1,
            dong: dong,
            chieuCao: caoDong,
            hienNhanNV: true,
            xemDuKien: hieuLucXemDuKien
        )
        viewDong.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(viewDong)

        NSLayoutConstraint.activate([
            viewDong.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            viewDong.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            viewDong.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            viewDong.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
        ])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        khiChonDong?(danhSachHienThi[indexPath.row])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let dong = danhSachHienThi[indexPath.row]
        let xoa = UIContextualAction(style: .destructive, title: "Xoá") { [weak self] _, _, hoanTat in
            self?.khiXoaDong?(dong.id)
            hoanTat(true)
        }
        let sua = UIContextualAction(style: .normal, title: "Sửa") { [weak self] _, _, hoanTat in
            self?.khiSuaDong?(dong)
            hoanTat(true)
        }
        sua.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [xoa, sua])
    }

    private func tinhChieuCaoDong8Cot(dong: DongThiDua, hienNhanNV: Bool) -> CGFloat {
        let rongTen = chieuRongCot[1] - 12
        let fontTen = UIFont.systemFont(ofSize: 12.5, weight: .bold)
        let rectTen = (dong.tenNganhHang as NSString).boundingRect(
            with: CGSize(width: rongTen, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontTen],
            context: nil
        )
        let caoTen = ceil(rectTen.height)
        if hienNhanNV {
            let soNVGiao = KhoDuLieu.dungChung.danhSachMaNVChiaTarget(cho: dong).count
            let moiNV = soNVGiao > 0 ? (dong.target / Double(soNVGiao)) : 0
            let chuoiNV = "👥 \(soNVGiao) NV (\(String(format: "%.1f", moiNV))/NV)"
            let rectNV = (chuoiNV as NSString).boundingRect(
                with: CGSize(width: rongTen, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: fontTen],
                context: nil
            )
            let caoNV = max(18, ceil(rectNV.height))
            return max(58, caoTen + caoNV + 16)
        } else {
            return max(52, caoTen + 18)
        }
    }

    private func taoDongTieuDeCot(cheDo: LoaiCheDoDoanhThu? = nil, xemDuKien: Bool = false) -> UIView {
        let khung = UIView(frame: CGRect(x: 0, y: 0, width: tongChieuRongBang, height: 42))
        khung.backgroundColor = UIColor.systemGray5

        let cheDoHienThi = cheDo ?? cheDoDoanhThu
        let tieuDe: [String]
        if cheDoHienThi == .luyKe && xemDuKien {
            tieuDe = ["STT", "NGÀNH HÀNG (BẤM XEM NV)", "ĐVT", "DT/SL DỰ KIẾN", "TARGET", "THIẾU/VƯỢT DK", "% DỰ KIẾN", "% HT THÁNG"]
        } else {
            let cotHT = (cheDoHienThi == .luyKe) ? "% HT THÁNG" : "% HT NGÀY"
            tieuDe = ["STT", "NGÀNH HÀNG (BẤM XEM NV)", "ĐVT", "THỰC HIỆN", "TARGET", "THIẾU/VƯỢT", cotHT, "% DỰ KIẾN"]
        }
        var xHienTai: CGFloat = 0

        for (i, chu) in tieuDe.enumerated() {
            let rong = chieuRongCot[i]
            let nhan = UILabel(frame: CGRect(x: xHienTai + 4, y: 2, width: rong - 8, height: 38))
            nhan.text = chu
            nhan.font = .systemFont(ofSize: 11, weight: .bold)
            nhan.textColor = .label
            nhan.numberOfLines = 0
            nhan.lineBreakMode = .byWordWrapping
            nhan.adjustsFontSizeToFitWidth = false
            nhan.textAlignment = (i == 1) ? .left : .center
            khung.addSubview(nhan)

            xHienTai += rong
            if i < tieuDe.count - 1 {
                let vach = UIView(frame: CGRect(x: xHienTai, y: 0, width: 0.5, height: 42))
                vach.backgroundColor = .separator
                khung.addSubview(vach)
            }
        }

        let vachDuoi = UIView(frame: CGRect(x: 0, y: 41.5, width: tongChieuRongBang, height: 0.5))
        vachDuoi.backgroundColor = .separator
        khung.addSubview(vachDuoi)
        return khung
    }

    private func taoViewDongDuLieu8Cot(
        stt: Int,
        dong: DongThiDua,
        chieuCao: CGFloat = 52,
        hienNhanNV: Bool = false,
        xemDuKien: Bool = false
    ) -> UIView {
        let khung = UIView(frame: CGRect(x: 0, y: 0, width: tongChieuRongBang, height: chieuCao))
        let dat = xemDuKien ? dong.daHoanThanhDuBao : dong.daDat
        khung.backgroundColor = dat
            ? UIColor.systemGreen.withAlphaComponent(0.05)
            : UIColor.systemRed.withAlphaComponent(0.04)

        let mauChuChinh: UIColor = .label
        let htDat = dong.daDat
        let mauChuHT: UIColor = htDat ? UIColor(red: 0.06, green: 0.52, blue: 0.24, alpha: 1) : UIColor(red: 0.80, green: 0.14, blue: 0.14, alpha: 1)
        let mauNenHT: UIColor = htDat ? UIColor.systemGreen.withAlphaComponent(0.18) : UIColor.systemRed.withAlphaComponent(0.16)

        let duBaoDat = dong.daHoanThanhDuBao
        let mauChuDuBao: UIColor = duBaoDat ? UIColor(red: 0.06, green: 0.52, blue: 0.24, alpha: 1) : UIColor(red: 0.80, green: 0.14, blue: 0.14, alpha: 1)
        let mauNenDuBao: UIColor = duBaoDat ? UIColor.systemGreen.withAlphaComponent(0.18) : UIColor.systemRed.withAlphaComponent(0.16)

        let giaTriCot: [String]
        if xemDuKien {
            giaTriCot = [
                "\(stt)",
                dong.tenNganhHang,
                dong.loaiChiTieu.maBang,
                dong.duKien.chuoiSoLieu,
                dong.target.chuoiSoLieu,
                dong.chenhLechDuKien.chuoiChenhLech,
                dong.phanTramDuBao.chuoiPhanTram,
                dong.phanTramHT.chuoiPhanTram
            ]
        } else {
            giaTriCot = [
                "\(stt)",
                dong.tenNganhHang,
                dong.loaiChiTieu.maBang,
                dong.thucHien.chuoiSoLieu,
                dong.target.chuoiSoLieu,
                dong.chenhLech.chuoiChenhLech,
                dong.phanTramHT.chuoiPhanTram,
                dong.phanTramDuBao.chuoiPhanTram
            ]
        }

        let soNVGiao = KhoDuLieu.dungChung.danhSachMaNVChiaTarget(cho: dong).count
        let moiNV = soNVGiao > 0 ? (dong.target / Double(soNVGiao)) : 0

        // Tất cả các cột dùng đúng cùng một cỡ chữ 12.5pt đồng nhất, tự xuống dòng, không bao giờ "..."
        let fontDongNhat = UIFont.monospacedDigitSystemFont(ofSize: 12.5, weight: .bold)
        let fontChuDongNhat = UIFont.systemFont(ofSize: 12.5, weight: .bold)

        var xHienTai: CGFloat = 0
        for i in 0..<giaTriCot.count {
            let rong = chieuRongCot[i]
            let khungO = CGRect(x: xHienTai, y: 0, width: rong, height: chieuCao)

            if i == 6 || i == 7 {
                let badge = UILabel(frame: khungO.insetBy(dx: 5, dy: max(4, (chieuCao - 32) / 2)))
                badge.text = giaTriCot[i]
                badge.font = fontDongNhat
                badge.textAlignment = .center
                badge.numberOfLines = 0
                badge.lineBreakMode = .byWordWrapping
                badge.adjustsFontSizeToFitWidth = false
                if xemDuKien {
                    badge.textColor = (i == 6) ? mauChuDuBao : mauChuHT
                    badge.backgroundColor = (i == 6) ? mauNenDuBao : mauNenHT
                } else {
                    badge.textColor = (i == 6) ? mauChuHT : mauChuDuBao
                    badge.backgroundColor = (i == 6) ? mauNenHT : mauNenDuBao
                }
                badge.layer.cornerRadius = 8
                badge.clipsToBounds = true
                khung.addSubview(badge)
            } else if i == 1 && hienNhanNV {
                let chuoiNV = "👥 \(soNVGiao) NV (\(String(format: "%.1f", moiNV))/NV)"
                let rectNV = (chuoiNV as NSString).boundingRect(
                    with: CGSize(width: rong - 12, height: CGFloat.greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: fontChuDongNhat],
                    context: nil
                )
                let caoNV = max(18, ceil(rectNV.height))
                let caoTen = max(20, chieuCao - caoNV - 10)

                let lbTen = UILabel(frame: CGRect(x: xHienTai + 6, y: 4, width: rong - 12, height: caoTen))
                lbTen.text = dong.tenNganhHang
                lbTen.font = fontChuDongNhat
                lbTen.textColor = mauChuChinh
                lbTen.numberOfLines = 0
                lbTen.lineBreakMode = .byWordWrapping
                lbTen.adjustsFontSizeToFitWidth = false

                let lbNV = UILabel(frame: CGRect(x: xHienTai + 6, y: chieuCao - caoNV - 4, width: rong - 12, height: caoNV))
                lbNV.text = chuoiNV
                lbNV.font = fontChuDongNhat
                lbNV.textColor = .systemBlue
                lbNV.numberOfLines = 0
                lbNV.lineBreakMode = .byWordWrapping
                lbNV.adjustsFontSizeToFitWidth = false

                khung.addSubview(lbTen)
                khung.addSubview(lbNV)
            } else {
                let nhan = UILabel(frame: khungO.insetBy(dx: 6, dy: 4))
                nhan.text = giaTriCot[i]
                nhan.numberOfLines = 0
                nhan.lineBreakMode = .byWordWrapping
                nhan.adjustsFontSizeToFitWidth = false
                if i == 1 {
                    nhan.font = fontChuDongNhat
                    nhan.textAlignment = .left
                    nhan.textColor = mauChuChinh
                } else if i == 0 || i == 2 {
                    nhan.font = fontDongNhat
                    nhan.textAlignment = .center
                    nhan.textColor = .secondaryLabel
                } else if i == 5 {
                    nhan.font = fontDongNhat
                    nhan.textAlignment = .right
                    nhan.textColor = xemDuKien ? mauChuDuBao : mauChuHT
                } else {
                    nhan.font = fontDongNhat
                    nhan.textAlignment = .right
                    nhan.textColor = mauChuChinh
                }
                khung.addSubview(nhan)
            }

            xHienTai += rong
            if i < giaTriCot.count - 1 {
                let vach = UIView(frame: CGRect(x: xHienTai, y: 0, width: 0.5, height: chieuCao))
                vach.backgroundColor = .separator
                khung.addSubview(vach)
            }
        }
        return khung
    }

    // MARK: - Xuất Ảnh Báo Cáo Thi Đua (Các dòng text có cùng cỡ chữ, tự xuống dòng đầy đủ, không có dấu "...")

    func taoAnhBaoCao(
        ngay: Date,
        doanhThu: ThongTinDoanhThu,
        danhSach: [DongThiDua]? = nil,
        cheDoDoanhThu: LoaiCheDoDoanhThu = .luyKe,
        xemDuKien: Bool? = nil,
        thongTinDonVi: String,
        capNhatLuc: String
    ) -> UIImage? {
        let xemDK = (cheDoDoanhThu == .luyKe) ? (xemDuKien ?? dangXemDuKien) : false
        let dsXuat = danhSach.map { locVaSapXep($0, xemDuKien: xemDK) } ?? locVaSapXep(danhSachGoc, xemDuKien: xemDK)
        switch KhoDuLieu.dungChung.caiDat.kieuHienThi {
        case .bangChiTiet:
            return taoAnhMauBang8Cot(
                ngay: ngay,
                doanhThu: doanhThu,
                danhSach: dsXuat,
                cheDoDoanhThu: cheDoDoanhThu,
                xemDuKien: xemDK,
                thongTinDonVi: thongTinDonVi,
                capNhatLuc: capNhatLuc
            )
        case .theGon:
            return taoAnhMauTheGon(
                ngay: ngay,
                doanhThu: doanhThu,
                danhSach: dsXuat,
                cheDoDoanhThu: cheDoDoanhThu,
                xemDuKien: xemDK,
                thongTinDonVi: thongTinDonVi,
                capNhatLuc: capNhatLuc
            )
        }
    }

    private func taoAnhMauBang8Cot(
        ngay: Date,
        doanhThu: ThongTinDoanhThu,
        danhSach: [DongThiDua],
        cheDoDoanhThu: LoaiCheDoDoanhThu,
        xemDuKien: Bool = false,
        thongTinDonVi: String,
        capNhatLuc: String
    ) -> UIImage? {
        let ds = danhSach
        let soDat = ds.filter { xemDuKien ? $0.daHoanThanhDuBao : $0.daDat }.count
        let soKhongDat = ds.count - soDat

        let donVi = thongTinDonVi.isEmpty ? "ĐIỆN MÁY XANH" : thongTinDonVi
        let ngayStr = TienIchNgay.hienThiNgay.string(from: ngay)
        let nhanCheDo = (cheDoDoanhThu == .luyKe)
            ? (xemDuKien ? "LŨY KẾ (% DỰ KIẾN CUỐI THÁNG)" : "LŨY KẾ (THỰC HIỆN & TARGET)")
            : "REALTIME"

        let le: CGFloat = 16
        let chieuRongAnh = tongChieuRongBang + le * 2
        let rongNoiDung = chieuRongAnh - le * 2
        let chieuCaoHeaderCot: CGFloat = 42
        let cacChieuCaoDong: [CGFloat] = ds.isEmpty
            ? [52]
            : ds.map { tinhChieuCaoDong8Cot(dong: $0, hienNhanNV: false) }
        let tongCaoCacDong = cacChieuCaoDong.reduce(0, +)

        let chuPhu = "\(donVi)  •  Ngày \(ngayStr)\(capNhatLuc.isEmpty ? "" : "  •  Cập nhật: \(capNhatLuc)")"
        let fontPhu = UIFont.systemFont(ofSize: 12.5, weight: .bold)
        let caoPhu = max(20, ceil((chuPhu as NSString).boundingRect(
            with: CGSize(width: rongNoiDung, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontPhu],
            context: nil
        ).height))

        let chuTieuDe = "BẢNG TỔNG HỢP THI ĐUA — \(nhanCheDo)"
        let fontTieuDe = UIFont.systemFont(ofSize: 18.0, weight: .heavy)
        let caoTieuDeChinh = max(26, ceil((chuTieuDe as NSString).boundingRect(
            with: CGSize(width: rongNoiDung, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontTieuDe],
            context: nil
        ).height))

        let nhanDat = xemDuKien ? "Đạt dự kiến" : "Đạt"
        let nhanChuaDat = xemDuKien ? "Chưa đạt dự kiến" : "Không đạt"
        let chuThongKe = "Tổng: \(ds.count) ngành hàng   •   \(nhanDat): \(soDat)   •   \(nhanChuaDat): \(soKhongDat)"
        let fontThongKe = UIFont.systemFont(ofSize: 12.5, weight: .semibold)
        let caoThongKe = max(22, ceil((chuThongKe as NSString).boundingRect(
            with: CGSize(width: rongNoiDung, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontThongKe],
            context: nil
        ).height))

        let chieuCaoTieuDe = caoPhu + 4 + caoTieuDeChinh + 8
        let chieuCaoDoanhThu: CGFloat = 272
        let chieuCaoDongThongKe = caoThongKe + 8
        let chieuCaoAnh = chieuCaoTieuDe + chieuCaoDoanhThu + chieuCaoDongThongKe + chieuCaoHeaderCot + tongCaoCacDong + le * 2

        let khungBaoCao = UIView(frame: CGRect(x: 0, y: 0, width: chieuRongAnh, height: chieuCaoAnh))
        khungBaoCao.backgroundColor = .white
        khungBaoCao.overrideUserInterfaceStyle = .light

        let lbPhu = UILabel(frame: CGRect(x: le, y: le, width: rongNoiDung, height: caoPhu))
        lbPhu.text = chuPhu
        lbPhu.font = fontPhu
        lbPhu.textColor = .darkGray
        lbPhu.numberOfLines = 0
        lbPhu.lineBreakMode = .byWordWrapping
        lbPhu.adjustsFontSizeToFitWidth = false
        khungBaoCao.addSubview(lbPhu)

        let tieuDe = UILabel(frame: CGRect(x: le, y: le + caoPhu + 4, width: rongNoiDung, height: caoTieuDeChinh))
        tieuDe.text = chuTieuDe
        tieuDe.font = fontTieuDe
        tieuDe.textColor = .black
        tieuDe.numberOfLines = 0
        tieuDe.lineBreakMode = .byWordWrapping
        tieuDe.adjustsFontSizeToFitWidth = false
        khungBaoCao.addSubview(tieuDe)

        var yHienTai = le + chieuCaoTieuDe

        let cumChiSo = CumChiSoChinhView(coLon: true)
        cumChiSo.overrideUserInterfaceStyle = .light
        cumChiSo.frame = CGRect(x: le, y: yHienTai, width: rongNoiDung, height: 260)
        cumChiSo.capNhat(doanhThu: doanhThu, soNganhDat: soDat, tongSoNganh: ds.count, ngay: ngay, cheDo: cheDoDoanhThu)
        cumChiSo.layoutIfNeeded()
        khungBaoCao.addSubview(cumChiSo)
        yHienTai += chieuCaoDoanhThu

        let dongThongKe = UILabel(frame: CGRect(x: le, y: yHienTai, width: rongNoiDung, height: caoThongKe))
        dongThongKe.text = chuThongKe
        dongThongKe.font = fontThongKe
        dongThongKe.textColor = .darkGray
        dongThongKe.numberOfLines = 0
        dongThongKe.lineBreakMode = .byWordWrapping
        dongThongKe.adjustsFontSizeToFitWidth = false
        khungBaoCao.addSubview(dongThongKe)

        yHienTai += chieuCaoDongThongKe

        let khungBang = UIView(frame: CGRect(
            x: le,
            y: yHienTai,
            width: tongChieuRongBang,
            height: chieuCaoHeaderCot + tongCaoCacDong
        ))
        khungBang.layer.borderWidth = 1
        khungBang.layer.borderColor = UIColor.systemGray4.cgColor
        khungBang.layer.cornerRadius = 8
        khungBang.clipsToBounds = true
        khungBaoCao.addSubview(khungBang)

        let header = taoDongTieuDeCot(cheDo: cheDoDoanhThu, xemDuKien: xemDuKien)
        header.frame = CGRect(x: 0, y: 0, width: tongChieuRongBang, height: chieuCaoHeaderCot)
        khungBang.addSubview(header)

        if ds.isEmpty {
            let lbTrong = UILabel(frame: CGRect(x: 0, y: chieuCaoHeaderCot, width: tongChieuRongBang, height: 52))
            lbTrong.text = "Chưa có ngành hàng thi đua nào trong danh sách."
            lbTrong.font = .systemFont(ofSize: 12.5, weight: .medium)
            lbTrong.textColor = .gray
            lbTrong.textAlignment = .center
            lbTrong.numberOfLines = 0
            lbTrong.lineBreakMode = .byWordWrapping
            khungBang.addSubview(lbTrong)
        } else {
            var yDong = chieuCaoHeaderCot
            for (i, dong) in ds.enumerated() {
                let caoDong = cacChieuCaoDong[i]
                let vDong = taoViewDongDuLieu8Cot(stt: i + 1, dong: dong, chieuCao: caoDong, hienNhanNV: false, xemDuKien: xemDuKien)
                vDong.frame = CGRect(x: 0, y: yDong, width: tongChieuRongBang, height: caoDong)
                let vach = UIView(frame: CGRect(x: 0, y: caoDong - 0.5, width: tongChieuRongBang, height: 0.5))
                vach.backgroundColor = .systemGray4
                vDong.addSubview(vach)
                khungBang.addSubview(vDong)
                yDong += caoDong
            }
        }

        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2.0
        return UIGraphicsImageRenderer(size: khungBaoCao.bounds.size, format: fmt).image { ctx in
            khungBaoCao.layer.render(in: ctx.cgContext)
        }
    }

    private func taoAnhMauTheGon(
        ngay: Date,
        doanhThu: ThongTinDoanhThu,
        danhSach: [DongThiDua],
        cheDoDoanhThu: LoaiCheDoDoanhThu,
        xemDuKien: Bool = false,
        thongTinDonVi: String,
        capNhatLuc: String
    ) -> UIImage? {
        let ds = danhSach
        let soDat = ds.filter { xemDuKien ? $0.daHoanThanhDuBao : $0.daDat }.count
        let soKhongDat = ds.count - soDat

        let donVi = thongTinDonVi.isEmpty ? "ĐIỆN MÁY XANH" : thongTinDonVi
        let ngayStr = TienIchNgay.hienThiNgay.string(from: ngay)
        let nhanCheDo = (cheDoDoanhThu == .luyKe)
            ? (xemDuKien ? "LŨY KẾ (% DỰ KIẾN CUỐI THÁNG)" : "LŨY KẾ (THỰC HIỆN & TARGET)")
            : "REALTIME"

        let soCot = max(1, min(4, KhoDuLieu.dungChung.caiDat.soCotXuatAnh))
        let le: CGFloat = 16
        let khoangCachO: CGFloat = 12
        let rongO: CGFloat = 330
        let rongAnh = max(780, le * 2 + CGFloat(soCot) * rongO + CGFloat(soCot - 1) * khoangCachO)
        let rongNoiDung = rongAnh - le * 2

        let soHang = Int(ceil(Double(ds.count) / Double(soCot)))
        var chieuCaoTungHang: [CGFloat] = []
        for h in 0..<soHang {
            var maxH: CGFloat = 88
            for c in 0..<soCot {
                let idx = h * soCot + c
                if idx < ds.count {
                    let hThe = OTheThiDuaCell.tinhChieuCaoThe(cho: ds[idx], rongThe: rongO, xemDuKien: xemDuKien)
                    maxH = max(maxH, hThe)
                }
            }
            chieuCaoTungHang.append(maxH)
        }

        let chuPhu = "\(donVi)  •  Ngày \(ngayStr)\(capNhatLuc.isEmpty ? "" : "  •  Cập nhật: \(capNhatLuc)")"
        let fontPhu = UIFont.systemFont(ofSize: 12.5, weight: .bold)
        let caoPhu = max(20, ceil((chuPhu as NSString).boundingRect(
            with: CGSize(width: rongNoiDung, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontPhu],
            context: nil
        ).height))

        let chuDau = "BẢNG TỔNG HỢP THI ĐUA — \(nhanCheDo)"
        let fontDau = UIFont.systemFont(ofSize: 18.0, weight: .heavy)
        let caoDau = max(26, ceil((chuDau as NSString).boundingRect(
            with: CGSize(width: rongNoiDung, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontDau],
            context: nil
        ).height))

        let nhanDat = xemDuKien ? "Đạt dự kiến" : "Đạt"
        let nhanChuaDat = xemDuKien ? "Chưa đạt dự kiến" : "Không đạt"
        let chuThongKe = "Tổng: \(ds.count) ngành hàng   •   \(nhanDat): \(soDat)   •   \(nhanChuaDat): \(soKhongDat)"
        let fontThongKe = UIFont.systemFont(ofSize: 12.5, weight: .semibold)
        let caoThongKe = max(22, ceil((chuThongKe as NSString).boundingRect(
            with: CGSize(width: rongNoiDung, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontThongKe],
            context: nil
        ).height))

        let caoTieuDe = caoPhu + 4 + caoDau + 8
        let caoPhanDoanhThu: CGFloat = 272
        let caoDongThongKe = caoThongKe + 8
        let caoLuoi = soHang > 0
            ? (chieuCaoTungHang.reduce(0, +) + CGFloat(max(0, soHang - 1)) * khoangCachO)
            : 48
        let caoAnh = le * 2 + caoTieuDe + caoPhanDoanhThu + caoDongThongKe + caoLuoi

        let khung = UIView(frame: CGRect(x: 0, y: 0, width: rongAnh, height: caoAnh))
        khung.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1)
        khung.overrideUserInterfaceStyle = .light

        let lbPhu = UILabel(frame: CGRect(x: le, y: le, width: rongNoiDung, height: caoPhu))
        lbPhu.text = chuPhu
        lbPhu.font = fontPhu
        lbPhu.textColor = .darkGray
        lbPhu.numberOfLines = 0
        lbPhu.lineBreakMode = .byWordWrapping
        lbPhu.adjustsFontSizeToFitWidth = false
        khung.addSubview(lbPhu)

        let nhanDau = UILabel(frame: CGRect(x: le, y: le + caoPhu + 4, width: rongNoiDung, height: caoDau))
        nhanDau.text = chuDau
        nhanDau.font = fontDau
        nhanDau.textColor = .black
        nhanDau.numberOfLines = 0
        nhanDau.lineBreakMode = .byWordWrapping
        nhanDau.adjustsFontSizeToFitWidth = false
        khung.addSubview(nhanDau)

        var yHienTai: CGFloat = le + caoTieuDe

        let cumChiSo = CumChiSoChinhView(coLon: true)
        cumChiSo.overrideUserInterfaceStyle = .light
        cumChiSo.frame = CGRect(x: le, y: yHienTai, width: rongNoiDung, height: 260)
        cumChiSo.capNhat(doanhThu: doanhThu, soNganhDat: soDat, tongSoNganh: ds.count, ngay: ngay, cheDo: cheDoDoanhThu)
        cumChiSo.layoutIfNeeded()
        khung.addSubview(cumChiSo)
        yHienTai += caoPhanDoanhThu

        let dongThongKe = UILabel(frame: CGRect(x: le, y: yHienTai, width: rongNoiDung, height: caoThongKe))
        dongThongKe.text = chuThongKe
        dongThongKe.font = fontThongKe
        dongThongKe.textColor = .darkGray
        dongThongKe.numberOfLines = 0
        dongThongKe.lineBreakMode = .byWordWrapping
        dongThongKe.adjustsFontSizeToFitWidth = false
        khung.addSubview(dongThongKe)

        yHienTai += caoDongThongKe

        var yHang = yHienTai
        for h in 0..<soHang {
            let caoO = chieuCaoTungHang[h]
            for c in 0..<soCot {
                let idx = h * soCot + c
                guard idx < ds.count else { break }
                let x = le + CGFloat(c) * (rongO + khoangCachO)
                let oThe = OTheThiDuaCell(frame: CGRect(x: x, y: yHang, width: rongO, height: caoO))
                oThe.overrideUserInterfaceStyle = .light
                oThe.gan(ds[idx], xemDuKien: xemDuKien)
                oThe.layoutIfNeeded()
                khung.addSubview(oThe)
            }
            yHang += caoO + khoangCachO
        }

        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2.0
        return UIGraphicsImageRenderer(size: khung.bounds.size, format: fmt).image { ctx in
            khung.layer.render(in: ctx.cgContext)
        }
    }

    // MARK: - Xuất File Excel (.csv chuẩn UTF-8 BOM)

    func taoChuoiExcelCSV(doanhThu: ThongTinDoanhThu, danhSach: [DongThiDua]? = nil, cheDo: LoaiCheDoDoanhThu? = nil, ngay: Date = Date()) -> String {
        var cacDong: [String] = []
        let cheDoCSV = cheDo ?? cheDoDoanhThu
        let xemDK = (cheDoCSV == .luyKe && dangXemDuKien)
        let ds = danhSach.map { locVaSapXep($0, xemDuKien: xemDK) } ?? danhSachHienThi
        let soDat = ds.filter { xemDK ? $0.daHoanThanhDuBao : $0.daDat }.count

        if doanhThu.coDuLieu {
            cacDong.append("CHỈ SỐ CHÍNH,GIÁ TRỊ CHÍNH,CHI TIẾT / MỤC TIÊU")
            cacDong.append("Doanh thu thực,\(doanhThu.doanhThuThuc),Target: \(doanhThu.targetThuc)")
            cacDong.append("Doanh thu quy đổi,\(doanhThu.doanhThuQuyDoi),Target: \(doanhThu.targetQuyDoi)")
            cacDong.append("% Trả góp,\(String(format: "%.2f%%", doanhThu.phanTramTraGop)),DT trả góp: \(doanhThu.doanhThuTraGop)")
            cacDong.append("Lượt khách,\(Int(doanhThu.luotKhach)),Bill: \(Int(doanhThu.soBill)) | PVTC: \(String(format: "%.1f%%", doanhThu.phanTramPVTC))")
            let dk = doanhThu.duKienQuyDoi > 0 ? doanhThu.duKienQuyDoi : doanhThu.duKienThuc
            let kqDK = doanhThu.phanTramHTQDDuKienHienThi >= 99.995 ? "ĐẠT MỤC TIÊU" : "CHƯA ĐẠT"
            cacDong.append("\"% HT QĐ dự kiến\",\(String(format: "%.2f%%", doanhThu.phanTramHTQDDuKienHienThi)),\"DTQĐ DK: \(dk) (\(kqDK))\"")
            cacDong.append("% Quy đổi,\(String(format: "%.2f%%", doanhThu.phanTramQuyDoi)),Mục tiêu: 50%")
            cacDong.append("Thi đua hoàn thành,\(soDat)/\(ds.count),Tỷ lệ: \(ds.count > 0 ? Int(round(Double(soDat) / Double(ds.count) * 100)) : 0)%")
            cacDong.append("Tăng/giảm cùng kỳ,\(String(format: "%.1f%%", doanhThu.tangGiamCungKy)),TB3T: \(doanhThu.tb3Thang)")
            cacDong.append("")
        }

        if cheDoCSV == .luyKe {
            cacDong.append("STT,Ngành hàng (Chương trình),ĐVT,Thực hiện,Target,Thiếu / Vượt,% HT Tháng,DT/SL Dự kiến,Thiếu / Vượt DK,% Dự kiến,Trạng thái Thực hiện,Trạng thái Dự kiến")
            for (i, d) in ds.enumerated() {
                let tenSach = "\"\(d.tenNganhHang.replacingOccurrences(of: "\"", with: "\"\""))\""
                let ttTH = d.daDat ? "Đạt" : "Chưa đạt"
                let ttDK = d.daHoanThanhDuBao ? "Đạt DK" : "Chưa đạt DK"
                let dong = "\(i + 1),\(tenSach),\(d.loaiChiTieu.maBang),\(d.thucHien),\(d.target),\(d.chenhLech),\(String(format: "%.2f", d.phanTramHT))%,\(d.duKien),\(d.chenhLechDuKien),\(String(format: "%.2f", d.phanTramDuBao))%,\(ttTH),\(ttDK)"
                cacDong.append(dong)
            }
        } else {
            cacDong.append("STT,Ngành hàng (Chương trình),ĐVT,Thực hiện,Target,Thiếu / Vượt,% HT Ngày,% Dự kiến,Trạng thái")
            for (i, d) in ds.enumerated() {
                let tenSach = "\"\(d.tenNganhHang.replacingOccurrences(of: "\"", with: "\"\""))\""
                let trangThai = d.daDat ? "Đạt" : "Chưa đạt"
                let dong = "\(i + 1),\(tenSach),\(d.loaiChiTieu.maBang),\(d.thucHien),\(d.target),\(d.chenhLech),\(String(format: "%.2f", d.phanTramHT))%,\(String(format: "%.2f", d.phanTramDuBao))%,\(trangThai)"
                cacDong.append(dong)
            }
        }
        return "\u{FEFF}" + cacDong.joined(separator: "\n")
    }
}

// MARK: - 4. Màn hình / Khung Tổng Hợp Biểu Đồ Realtime Theo Tháng (Nút Biểu đồ)

private final class VeBieuDoCotRealtimeView: UIView {
    var danhSachNgay: [DuLieuRealtimeNgayTrongThang] = [] {
        didSet { setNeedsDisplay() }
    }
    var ngayDangChon: Int = 1 {
        didSet { setNeedsDisplay() }
    }
    var khiChonNgay: ((DuLieuRealtimeNgayTrongThang) -> Void)?

    private let leTrai: CGFloat = 46
    private let lePhai: CGFloat = 14
    private let leTren: CGFloat = 26
    private let leDuoi: CGFloat = 34
    let chieuRongMoiNgay: CGFloat = 58

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(xuLyCham(_:)))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("Khong ho tro coder")
    }

    @objc private func xuLyCham(_ g: UITapGestureRecognizer) {
        guard !danhSachNgay.isEmpty else { return }
        let diem = g.location(in: self)
        guard diem.x >= leTrai else { return }
        let idx = Int((diem.x - leTrai) / chieuRongMoiNgay)
        if idx >= 0 && idx < danhSachNgay.count {
            khiChonNgay?(danhSachNgay[idx])
        }
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let caoVe = max(40, rect.height - leTren - leDuoi)
        let rongVe = max(60, rect.width - leTrai - lePhai)

        let maxValRaw = danhSachNgay.reduce(0.0) { acc, item in
            max(acc, max(item.doanhThuThuc, item.doanhThuQuyDoi))
        }
        let maxVal = maxValRaw > 0 ? maxValRaw * 1.15 : 100.0

        let fontTruc = UIFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .semibold)
        let mauChuPhu = UIColor.secondaryLabel
        let mauLuoi = UIColor.separator.withAlphaComponent(0.45)

        let soMucLuoi = 4
        for i in 0...soMucLuoi {
            let tyLe = CGFloat(i) / CGFloat(soMucLuoi)
            let y = leTren + caoVe * (1.0 - tyLe)
            let giaTri = maxVal * Double(tyLe)

            ctx.setStrokeColor(mauLuoi.cgColor)
            ctx.setLineWidth(i == 0 ? 1.0 : 0.6)
            if i > 0 {
                ctx.setLineDash(phase: 0, lengths: [3, 3])
            } else {
                ctx.setLineDash(phase: 0, lengths: [])
            }
            ctx.move(to: CGPoint(x: leTrai, y: y))
            ctx.addLine(to: CGPoint(x: leTrai + rongVe, y: y))
            ctx.strokePath()

            let chuY = giaTri >= 1000 ? String(format: "%.0f", giaTri) : giaTri.chuoiSoGonVN
            let attrY: [NSAttributedString.Key: Any] = [
                .font: fontTruc,
                .foregroundColor: mauChuPhu
            ]
            let sizeY = (chuY as NSString).size(withAttributes: attrY)
            (chuY as NSString).draw(
                at: CGPoint(x: max(2, leTrai - sizeY.width - 5), y: y - sizeY.height / 2),
                withAttributes: attrY
            )
        }
        ctx.setLineDash(phase: 0, lengths: [])

        guard !danhSachNgay.isEmpty else {
            let pCenter = NSMutableParagraphStyle()
            pCenter.alignment = .center
            pCenter.lineBreakMode = .byWordWrapping
            let thongBao = "Chưa có dữ liệu Realtime ngày nào trong tháng — chạm vào ngày bên dưới để thêm."
            let attr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: mauChuPhu,
                .paragraphStyle: pCenter
            ]
            (thongBao as NSString).draw(
                in: CGRect(x: leTrai + 8, y: leTren + caoVe / 2 - 20, width: max(100, rongVe - 16), height: 44),
                withAttributes: attr
            )
            return
        }

        let mauThuc = UIColor(red: 0.15, green: 0.39, blue: 0.92, alpha: 1.0)
        let mauQuyDoi = UIColor(red: 0.08, green: 0.60, blue: 0.28, alpha: 1.0)
        let fontSo = UIFont.monospacedDigitSystemFont(ofSize: 8.5, weight: .bold)
        let fontNgay = UIFont.systemFont(ofSize: 10, weight: .bold)

        let rongCot: CGFloat = 18
        let khoangCach2Cot: CGFloat = 3

        for (i, item) in danhSachNgay.enumerated() {
            let xTam = leTrai + CGFloat(i) * chieuRongMoiNgay + chieuRongMoiNgay / 2
            let yDay = leTren + caoVe

            if item.ngayTrongThang == ngayDangChon {
                let khungChon = CGRect(
                    x: xTam - chieuRongMoiNgay / 2 + 2,
                    y: leTren - 4,
                    width: chieuRongMoiNgay - 4,
                    height: caoVe + leDuoi
                )
                let pathNen = UIBezierPath(roundedRect: khungChon, cornerRadius: 8)
                UIColor.systemBlue.withAlphaComponent(0.08).setFill()
                pathNen.fill()
            }

            let caoThuc = item.doanhThuThuc > 0 ? max(4, CGFloat(item.doanhThuThuc / maxVal) * caoVe) : 0
            let xThuc = xTam - khoangCach2Cot / 2 - rongCot
            if caoThuc > 0 {
                let rectThuc = CGRect(x: xThuc, y: yDay - caoThuc, width: rongCot, height: caoThuc)
                let pathThuc = UIBezierPath(
                    roundedRect: rectThuc,
                    byRoundingCorners: [.topLeft, .topRight],
                    cornerRadii: CGSize(width: 4, height: 4)
                )
                mauThuc.setFill()
                pathThuc.fill()

                let chuSo = item.doanhThuThuc.chuoiSoGonVN
                let attrSo: [NSAttributedString.Key: Any] = [.font: fontSo, .foregroundColor: mauThuc]
                let szSo = (chuSo as NSString).size(withAttributes: attrSo)
                (chuSo as NSString).draw(
                    at: CGPoint(x: xThuc + (rongCot - szSo.width) / 2, y: max(2, yDay - caoThuc - szSo.height - 2)),
                    withAttributes: attrSo
                )
            }

            let caoQD = item.doanhThuQuyDoi > 0 ? max(4, CGFloat(item.doanhThuQuyDoi / maxVal) * caoVe) : 0
            let xQD = xTam + khoangCach2Cot / 2
            if caoQD > 0 {
                let rectQD = CGRect(x: xQD, y: yDay - caoQD, width: rongCot, height: caoQD)
                let pathQD = UIBezierPath(
                    roundedRect: rectQD,
                    byRoundingCorners: [.topLeft, .topRight],
                    cornerRadii: CGSize(width: 4, height: 4)
                )
                mauQuyDoi.setFill()
                pathQD.fill()

                let chuQD = item.doanhThuQuyDoi.chuoiSoGonVN
                let attrQD: [NSAttributedString.Key: Any] = [.font: fontSo, .foregroundColor: mauQuyDoi]
                let szQD = (chuQD as NSString).size(withAttributes: attrQD)
                let yNhanQD = max(2, yDay - caoQD - szQD.height - (abs(caoQD - caoThuc) < 10 && caoThuc > 0 ? 11 : 2))
                (chuQD as NSString).draw(
                    at: CGPoint(x: xQD + (rongCot - szQD.width) / 2, y: yNhanQD),
                    withAttributes: attrQD
                )
            }

            let chuNgay = String(format: "%02d/%02d", item.ngayTrongThang, TienIchNgay.lich.component(.month, from: item.ngay))
            let laChon = (item.ngayTrongThang == ngayDangChon)
            let attrNgay: [NSAttributedString.Key: Any] = [
                .font: fontNgay,
                .foregroundColor: laChon ? UIColor.systemBlue : UIColor.label
            ]
            let szNgay = (chuNgay as NSString).size(withAttributes: attrNgay)
            (chuNgay as NSString).draw(
                at: CGPoint(x: xTam - szNgay.width / 2, y: yDay + 8),
                withAttributes: attrNgay
            )
        }
    }
}

final class BangTongHopRealtimeThangView: UIView, UITableViewDataSource, UITableViewDelegate {
    var khiBamSuaDoanhThuLuyKe: (() -> Void)?
    var khiChonNgayRealtime: ((DuLieuRealtimeNgayTrongThang) -> Void)?

    private var ngayHienTai: Date = Date()
    private var doanhThuLuyKe = ThongTinDoanhThu()
    private var tatCaNgayTrongThang: [DuLieuRealtimeNgayTrongThang] = []
    private var danhSachBieuDo: [DuLieuRealtimeNgayTrongThang] = []
    private var chiHienNgayCoSo: Bool = false

    private let cuonDoc = UIScrollView()
    private let nganNoiDung = UIStackView()

    private let nhanTieuDeLuyKe = UILabel()
    private let theLuyKeThuc = TheDoanhThuView(
        tieuDe: "💵 DT LŨY KẾ THỰC (THÁNG)",
        mauBatDau: UIColor(red: 0.14, green: 0.39, blue: 0.92, alpha: 1),
        mauKetThuc: UIColor(red: 0.23, green: 0.25, blue: 0.89, alpha: 1)
    )
    private let theLuyKeQD = TheDoanhThuView(
        tieuDe: "🎯 DT LŨY KẾ QUY ĐỔI (THÁNG)",
        mauBatDau: UIColor(red: 0.09, green: 0.61, blue: 0.27, alpha: 1),
        mauKetThuc: UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1),
        hienChamTron: true
    )

    private let chonCheDoNgay = UISegmentedControl(items: ["Cả tháng", "Ngày có số"])
    private let nhanTomTatRT = UILabel()
    private let cuonBieuDo = UIScrollView()
    private let veBieuDo = VeBieuDoCotRealtimeView()
    private var rangBuocRongBieuDo: NSLayoutConstraint?

    private let bangNgay = UITableView(frame: .zero, style: .plain)
    private var rangBuocCaoBang: NSLayoutConstraint?

    private let soDongTongKetCuoiBang: Int = 3
    private let chieuCaoMoiDongBang: CGFloat = 52

    override init(frame: CGRect) {
        super.init(frame: frame)
        taoGiaoDien()
    }

    required init?(coder: NSCoder) {
        fatalError("Khong ho tro coder")
    }

    private func taoGiaoDien() {
        backgroundColor = .clear

        cuonDoc.showsVerticalScrollIndicator = true
        cuonDoc.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cuonDoc)

        nganNoiDung.axis = .vertical
        nganNoiDung.spacing = 10
        nganNoiDung.translatesAutoresizingMaskIntoConstraints = false
        cuonDoc.addSubview(nganNoiDung)

        let khungLuyKe = UIView()
        khungLuyKe.backgroundColor = .secondarySystemGroupedBackground
        khungLuyKe.layer.cornerRadius = 12

        nhanTieuDeLuyKe.text = "📌 DOANH THU LŨY KẾ THÁNG (CỐ ĐỊNH — MỖI NGÀY NHẬP THAY THẾ NGÀY TRƯỚC)"
        nhanTieuDeLuyKe.font = .systemFont(ofSize: 11, weight: .bold)
        nhanTieuDeLuyKe.textColor = .secondaryLabel
        nhanTieuDeLuyKe.numberOfLines = 0
        nhanTieuDeLuyKe.lineBreakMode = .byWordWrapping
        nhanTieuDeLuyKe.adjustsFontSizeToFitWidth = false

        let nutSuaLK = UIButton(type: .system)
        nutSuaLK.setTitle("✏️ Lũy kế", for: .normal)
        nutSuaLK.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutSuaLK.titleLabel?.numberOfLines = 0
        nutSuaLK.titleLabel?.lineBreakMode = .byWordWrapping
        nutSuaLK.titleLabel?.textAlignment = .center
        nutSuaLK.titleLabel?.adjustsFontSizeToFitWidth = false
        nutSuaLK.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        nutSuaLK.tintColor = .systemBlue
        nutSuaLK.layer.cornerRadius = 7
        nutSuaLK.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        nutSuaLK.addTarget(self, action: #selector(bamSuaLuyKe), for: .touchUpInside)
        nutSuaLK.setContentHuggingPriority(.required, for: .horizontal)

        let hangDauLK = UIStackView(arrangedSubviews: [nhanTieuDeLuyKe, nutSuaLK])
        hangDauLK.axis = .horizontal
        hangDauLK.spacing = 6
        hangDauLK.alignment = .center

        let hangTheLK = UIStackView(arrangedSubviews: [theLuyKeThuc, theLuyKeQD])
        hangTheLK.axis = .horizontal
        hangTheLK.spacing = 8
        hangTheLK.distribution = .fillEqually
        hangTheLK.heightAnchor.constraint(greaterThanOrEqualToConstant: 76).isActive = true

        let tapLK = UITapGestureRecognizer(target: self, action: #selector(bamSuaLuyKe))
        hangTheLK.addGestureRecognizer(tapLK)

        let nganLK = UIStackView(arrangedSubviews: [hangDauLK, hangTheLK])
        nganLK.axis = .vertical
        nganLK.spacing = 8
        nganLK.translatesAutoresizingMaskIntoConstraints = false
        khungLuyKe.addSubview(nganLK)

        NSLayoutConstraint.activate([
            nganLK.topAnchor.constraint(equalTo: khungLuyKe.topAnchor, constant: 10),
            nganLK.leadingAnchor.constraint(equalTo: khungLuyKe.leadingAnchor, constant: 10),
            nganLK.trailingAnchor.constraint(equalTo: khungLuyKe.trailingAnchor, constant: -10),
            nganLK.bottomAnchor.constraint(equalTo: khungLuyKe.bottomAnchor, constant: -10)
        ])

        let khungBieuDo = UIView()
        khungBieuDo.backgroundColor = .secondarySystemGroupedBackground
        khungBieuDo.layer.cornerRadius = 12

        let lbTieuDeBD = UILabel()
        lbTieuDeBD.text = "📊 BIỂU ĐỒ DOANH THU THỰC & QUY ĐỔI THEO NGÀY"
        lbTieuDeBD.font = .systemFont(ofSize: 12, weight: .bold)
        lbTieuDeBD.textColor = .label
        lbTieuDeBD.numberOfLines = 0
        lbTieuDeBD.lineBreakMode = .byWordWrapping
        lbTieuDeBD.adjustsFontSizeToFitWidth = false

        chonCheDoNgay.selectedSegmentIndex = 0
        chonCheDoNgay.addTarget(self, action: #selector(doiCheDoLocNgay), for: .valueChanged)
        chonCheDoNgay.setContentHuggingPriority(.required, for: .horizontal)

        let hangTieuDeBD = UIStackView(arrangedSubviews: [lbTieuDeBD, chonCheDoNgay])
        hangTieuDeBD.axis = .horizontal
        hangTieuDeBD.spacing = 8
        hangTieuDeBD.alignment = .center

        nhanTomTatRT.font = .systemFont(ofSize: 11.5, weight: .semibold)
        nhanTomTatRT.textColor = .secondaryLabel
        nhanTomTatRT.numberOfLines = 0
        nhanTomTatRT.lineBreakMode = .byWordWrapping
        nhanTomTatRT.adjustsFontSizeToFitWidth = false

        cuonBieuDo.showsHorizontalScrollIndicator = true
        cuonBieuDo.bounces = true
        cuonBieuDo.heightAnchor.constraint(equalToConstant: 210).isActive = true

        veBieuDo.translatesAutoresizingMaskIntoConstraints = false
        veBieuDo.khiChonNgay = { [weak self] item in
            self?.khiChonNgayRealtime?(item)
        }
        cuonBieuDo.addSubview(veBieuDo)

        let rBieuDo = veBieuDo.widthAnchor.constraint(equalToConstant: 800)
        rBieuDo.isActive = true
        rangBuocRongBieuDo = rBieuDo

        NSLayoutConstraint.activate([
            veBieuDo.topAnchor.constraint(equalTo: cuonBieuDo.contentLayoutGuide.topAnchor),
            veBieuDo.leadingAnchor.constraint(equalTo: cuonBieuDo.contentLayoutGuide.leadingAnchor),
            veBieuDo.trailingAnchor.constraint(equalTo: cuonBieuDo.contentLayoutGuide.trailingAnchor),
            veBieuDo.bottomAnchor.constraint(equalTo: cuonBieuDo.contentLayoutGuide.bottomAnchor),
            veBieuDo.heightAnchor.constraint(equalTo: cuonBieuDo.frameLayoutGuide.heightAnchor)
        ])

        let nganBD = UIStackView(arrangedSubviews: [hangTieuDeBD, nhanTomTatRT, cuonBieuDo])
        nganBD.axis = .vertical
        nganBD.spacing = 6
        nganBD.translatesAutoresizingMaskIntoConstraints = false
        khungBieuDo.addSubview(nganBD)

        NSLayoutConstraint.activate([
            nganBD.topAnchor.constraint(equalTo: khungBieuDo.topAnchor, constant: 10),
            nganBD.leadingAnchor.constraint(equalTo: khungBieuDo.leadingAnchor, constant: 10),
            nganBD.trailingAnchor.constraint(equalTo: khungBieuDo.trailingAnchor, constant: -10),
            nganBD.bottomAnchor.constraint(equalTo: khungBieuDo.bottomAnchor, constant: -10)
        ])

        let khungBang = UIView()
        khungBang.backgroundColor = .secondarySystemGroupedBackground
        khungBang.layer.cornerRadius = 12
        khungBang.clipsToBounds = true

        let lbTieuDeBang = UILabel()
        lbTieuDeBang.text = "📋 BẢNG CHI TIẾT REALTIME THEO NGÀY (CHẠM VÀO NGÀY ĐỂ SỬA / QUÉT ẢNH)"
        lbTieuDeBang.font = .systemFont(ofSize: 11.5, weight: .bold)
        lbTieuDeBang.textColor = .secondaryLabel
        lbTieuDeBang.numberOfLines = 0
        lbTieuDeBang.lineBreakMode = .byWordWrapping
        lbTieuDeBang.adjustsFontSizeToFitWidth = false
        lbTieuDeBang.translatesAutoresizingMaskIntoConstraints = false
        khungBang.addSubview(lbTieuDeBang)

        bangNgay.dataSource = self
        bangNgay.delegate = self
        bangNgay.isScrollEnabled = false
        bangNgay.rowHeight = chieuCaoMoiDongBang
        bangNgay.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        if #available(iOS 15.0, *) {
            bangNgay.sectionHeaderTopPadding = 0
        }
        bangNgay.translatesAutoresizingMaskIntoConstraints = false
        khungBang.addSubview(bangNgay)

        let cBang = bangNgay.heightAnchor.constraint(equalToConstant: 360)
        cBang.isActive = true
        rangBuocCaoBang = cBang

        NSLayoutConstraint.activate([
            lbTieuDeBang.topAnchor.constraint(equalTo: khungBang.topAnchor, constant: 10),
            lbTieuDeBang.leadingAnchor.constraint(equalTo: khungBang.leadingAnchor, constant: 12),
            lbTieuDeBang.trailingAnchor.constraint(equalTo: khungBang.trailingAnchor, constant: -12),

            bangNgay.topAnchor.constraint(equalTo: lbTieuDeBang.bottomAnchor, constant: 6),
            bangNgay.leadingAnchor.constraint(equalTo: khungBang.leadingAnchor),
            bangNgay.trailingAnchor.constraint(equalTo: khungBang.trailingAnchor),
            bangNgay.bottomAnchor.constraint(equalTo: khungBang.bottomAnchor)
        ])

        [khungLuyKe, khungBieuDo, khungBang].forEach {
            nganNoiDung.addArrangedSubview($0)
        }

        NSLayoutConstraint.activate([
            cuonDoc.topAnchor.constraint(equalTo: topAnchor),
            cuonDoc.leadingAnchor.constraint(equalTo: leadingAnchor),
            cuonDoc.trailingAnchor.constraint(equalTo: trailingAnchor),
            cuonDoc.bottomAnchor.constraint(equalTo: bottomAnchor),

            nganNoiDung.topAnchor.constraint(equalTo: cuonDoc.contentLayoutGuide.topAnchor),
            nganNoiDung.leadingAnchor.constraint(equalTo: cuonDoc.contentLayoutGuide.leadingAnchor),
            nganNoiDung.trailingAnchor.constraint(equalTo: cuonDoc.contentLayoutGuide.trailingAnchor),
            nganNoiDung.bottomAnchor.constraint(equalTo: cuonDoc.contentLayoutGuide.bottomAnchor, constant: -12),
            nganNoiDung.widthAnchor.constraint(equalTo: cuonDoc.frameLayoutGuide.widthAnchor)
        ])
    }

    @objc private func bamSuaLuyKe() {
        khiBamSuaDoanhThuLuyKe?()
    }

    @objc private func doiCheDoLocNgay() {
        chiHienNgayCoSo = (chonCheDoNgay.selectedSegmentIndex == 1)
        capNhatDuLieuHienThi()
    }

    func capNhat(cho ngay: Date) {
        self.ngayHienTai = ngay
        self.doanhThuLuyKe = KhoDuLieu.dungChung.doanhThuLuyKeThang(cho: ngay)
        self.tatCaNgayTrongThang = KhoDuLieu.dungChung.danhSachRealtimeTheoNgayTrongThang(cho: ngay)
        capNhatDuLieuHienThi()
    }

    private func taoNoiDungTomTatThang(
        dsCoSo: [DuLieuRealtimeNgayTrongThang],
        duBao: DuBaoQuyDoiThang
    ) -> (dong1: String, dong2: String, trangThaiDK: String) {
        let tongRTThuc = dsCoSo.reduce(0.0) { $0 + $1.doanhThuThuc }
        let tongRTQD = dsCoSo.reduce(0.0) { $0 + $1.doanhThuQuyDoi }
        let d1 = "🟦 DT Thực (\(dsCoSo.count) ngày): \(tongRTThuc.chuoiSoVN) (TB: \(duBao.trungBinhThucMoiNgay.chuoiSoVN)/ngày)  •  🟩 DT QĐ: \(tongRTQD.chuoiSoVN) (TB: \(duBao.trungBinhQDMoiNgay.chuoiSoVN)/ngày)"

        if duBao.phanTramHTQDDuKien > 0 || duBao.mucTieuThang > 0 {
            let kq = duBao.daHoanThanhDuKien ? "✅ ĐẠT MỤC TIÊU" : "⚠️ CHƯA ĐẠT"
            if duBao.mucTieuThang > 0 {
                let chenh = duBao.chenhLechDuKienCuoiThang
                let chuoiChenh = chenh >= 0 ? "Vượt +\(chenh.chuoiSoVN)" : "Thiếu \(abs(chenh).chuoiSoVN)"
                let d2 = "🎯 Target QĐ tháng: \(duBao.mucTieuThang.chuoiSoVN)  •  DK cuối tháng: \(duBao.duKienQDCuoiThang.chuoiSoVN) (\(duBao.phanTramHTQDDuKien.chuoiPhanTramVN) - \(kq) • \(chuoiChenh))"
                return (d1, d2, kq)
            } else {
                let d2 = "📈 DK cuối tháng: DT Thực DK: \(duBao.duKienThucCuoiThang.chuoiSoVN)  •  DT QĐ DK: \(duBao.duKienQDCuoiThang.chuoiSoVN) (\(duBao.phanTramHTQDDuKien.chuoiPhanTramVN) - \(kq))"
                return (d1, d2, kq)
            }
        } else {
            let d2 = "📈 DK cuối tháng (\(duBao.soNgayTrongThang) ngày): DT Thực DK: \(duBao.duKienThucCuoiThang.chuoiSoVN)  •  DT QĐ DK: \(duBao.duKienQDCuoiThang.chuoiSoVN)"
            return (d1, d2, "CHƯA CÓ TARGET")
        }
    }

    private func capNhatDuLieuHienThi() {
        let thang = TienIchNgay.lich.component(.month, from: ngayHienTai)
        let nam = TienIchNgay.lich.component(.year, from: ngayHienTai)
        let ngayChon = TienIchNgay.lich.component(.day, from: ngayHienTai)
        nhanTieuDeLuyKe.text = "📌 DOANH THU LŨY KẾ THÁNG \(String(format: "%02d/%04d", thang, nam)) (CỐ ĐỊNH — NHẬP MỚI THAY THẾ NGÀY TRƯỚC)"

        if doanhThuLuyKe.coDuLieu {
            theLuyKeThuc.capNhatNoiDung(
                chinh: doanhThuLuyKe.doanhThuThuc.chuoiSoGonVN,
                phu: "TARGET: \(doanhThuLuyKe.targetThuc.chuoiSoGonVN) | HT: \(doanhThuLuyKe.phanTramHTThucHienThi.chuoiPhanTram)"
            )
            theLuyKeQD.capNhatNoiDung(
                chinh: doanhThuLuyKe.doanhThuQuyDoi.chuoiSoGonVN,
                phu: "TARGET: \(doanhThuLuyKe.targetQuyDoi.chuoiSoGonVN) | HT: \(doanhThuLuyKe.phanTramHTQDDuKienHienThi.chuoiPhanTram)"
            )
        } else {
            theLuyKeThuc.capNhatNoiDung(chinh: "Chạm nhập", phu: "TARGET: --")
            theLuyKeQD.capNhatNoiDung(chinh: "Chạm nhập", phu: "TARGET: --")
        }

        let dsCoSo = tatCaNgayTrongThang.filter { $0.coDuLieu }
        if chiHienNgayCoSo && !dsCoSo.isEmpty {
            danhSachBieuDo = dsCoSo
        } else {
            danhSachBieuDo = tatCaNgayTrongThang
        }

        let duBao = KhoDuLieu.dungChung.tinhDuBaoQuyDoiTuRealtime(cho: ngayHienTai, cheDoDangXem: .realtime)
        let tomTat = taoNoiDungTomTatThang(dsCoSo: dsCoSo, duBao: duBao)
        nhanTomTatRT.numberOfLines = 0
        nhanTomTatRT.text = "\(tomTat.dong1)\n\(tomTat.dong2)"

        veBieuDo.ngayDangChon = ngayChon
        veBieuDo.danhSachNgay = danhSachBieuDo
        let rongCan = max(bounds.width - 20, 62 + CGFloat(max(1, danhSachBieuDo.count)) * veBieuDo.chieuRongMoiNgay)
        rangBuocRongBieuDo?.constant = rongCan

        let soDong = danhSachBieuDo.count + soDongTongKetCuoiBang
        rangBuocCaoBang?.constant = 42 + CGFloat(soDong) * chieuCaoMoiDongBang
        bangNgay.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        danhSachBieuDo.count + soDongTongKetCuoiBang
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 42))
        header.backgroundColor = .systemGray5
        let tieuDe = ["NGÀY / MỤC", "DT THỰC (RT)", "DT QUY ĐỔI (RT)", "% QUY ĐỔI", "KHÁCH / BILL", "DK / ĐÁNH GIÁ"]
        let tyLe: [CGFloat] = [0.16, 0.17, 0.18, 0.13, 0.16, 0.20]
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: header.topAnchor),
            stack.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: header.bottomAnchor)
        ])
        for (i, chu) in tieuDe.enumerated() {
            let lb = UILabel()
            lb.text = chu
            lb.font = .systemFont(ofSize: 10.5, weight: .bold)
            lb.textColor = .label
            lb.numberOfLines = 0
            lb.lineBreakMode = .byWordWrapping
            lb.adjustsFontSizeToFitWidth = false
            lb.textAlignment = (i == 0) ? .left : .right
            stack.addArrangedSubview(lb)
            lb.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: tyLe[i]).isActive = true
        }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        42
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ma = "DongRTThangCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: ma) ?? UITableViewCell(style: .default, reuseIdentifier: ma)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let tyLe: [CGFloat] = [0.16, 0.17, 0.18, 0.13, 0.16, 0.20]
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
        ])

        let duBao = KhoDuLieu.dungChung.tinhDuBaoQuyDoiTuRealtime(cho: ngayHienTai, cheDoDangXem: .realtime)
        let dsCoSo = tatCaNgayTrongThang.filter { $0.coDuLieu }
        let fontDongNhat = UIFont.monospacedDigitSystemFont(ofSize: 11.5, weight: .bold)

        if indexPath.row >= danhSachBieuDo.count {
            cell.selectionStyle = .none
            let loaiTongKet = indexPath.row - danhSachBieuDo.count
            let tongRTThuc = dsCoSo.reduce(0.0) { $0 + $1.doanhThuThuc }
            let tongRTQD = dsCoSo.reduce(0.0) { $0 + $1.doanhThuQuyDoi }
            let tongKhach = dsCoSo.reduce(0.0) { $0 + $1.luotKhach }
            let tongBill = dsCoSo.reduce(0.0) { $0 + $1.soBill }
            let ptQDTong = tongRTThuc > 0 ? ((tongRTQD - tongRTThuc) / tongRTThuc * 100.0) : 0

            let giaTri: [String]
            let mauChuCuoi: UIColor
            if loaiTongKet == 0 {
                cell.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
                let mtDenNay = duBao.mucTieuMoiNgay * Double(max(1, dsCoSo.count))
                let ptDenNay = mtDenNay > 0 ? (tongRTQD / mtDenNay * 100.0) : 0
                let danhGia = mtDenNay > 0
                    ? (ptDenNay >= 99.995 ? "✅ Đạt (\(ptDenNay.chuoiPhanTram))" : "⚠️ \(ptDenNay.chuoiPhanTram)")
                    : "\(dsCoSo.count) ngày RT"
                mauChuCuoi = (mtDenNay > 0 && ptDenNay >= 99.995) ? UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1) : .label
                giaTri = [
                    "TỔNG (\(dsCoSo.count)N)",
                    tongRTThuc.chuoiSoVN,
                    tongRTQD.chuoiSoVN,
                    ptQDTong.chuoiPhanTram,
                    "\(tongKhach.chuoiSoNguyenVN)/\(tongBill.chuoiSoNguyenVN)",
                    danhGia
                ]
            } else if loaiTongKet == 1 {
                cell.backgroundColor = UIColor.systemGray6
                let soN = Double(max(1, dsCoSo.count))
                let tbKhach = dsCoSo.isEmpty ? 0 : (tongKhach / soN)
                let tbBill = dsCoSo.isEmpty ? 0 : (tongBill / soN)
                let chuoiMTNgay = duBao.mucTieuMoiNgay > 0 ? "Target: \(duBao.mucTieuMoiNgay.chuoiSoGonVN)/ngày" : "TB \(dsCoSo.count) ngày"
                mauChuCuoi = .secondaryLabel
                giaTri = [
                    "TB / NGÀY",
                    duBao.trungBinhThucMoiNgay.chuoiSoVN,
                    duBao.trungBinhQDMoiNgay.chuoiSoVN,
                    ptQDTong.chuoiPhanTram,
                    "\(tbKhach.chuoiSoNguyenVN)/\(tbBill.chuoiSoNguyenVN)",
                    chuoiMTNgay
                ]
            } else {
                let dat = duBao.daHoanThanhDuKien
                let coPT = duBao.phanTramHTQDDuKien > 0 || duBao.mucTieuThang > 0
                cell.backgroundColor = coPT
                    ? (dat ? UIColor.systemGreen.withAlphaComponent(0.14) : UIColor.systemOrange.withAlphaComponent(0.15))
                    : UIColor.systemPurple.withAlphaComponent(0.08)
                let soN = Double(max(1, dsCoSo.count))
                let dkKhach = dsCoSo.isEmpty ? 0 : (tongKhach / soN * Double(duBao.soNgayTrongThang))
                let dkBill = dsCoSo.isEmpty ? 0 : (tongBill / soN * Double(duBao.soNgayTrongThang))
                let chuoiTrangThaiDK: String
                if coPT {
                    let kq = dat ? "✅ ĐẠT" : "⚠️ CHƯA ĐẠT"
                    chuoiTrangThaiDK = "\(kq) (\(duBao.phanTramHTQDDuKien.chuoiPhanTram))"
                } else {
                    chuoiTrangThaiDK = "--"
                }
                mauChuCuoi = coPT
                    ? (dat ? UIColor(red: 0.06, green: 0.52, blue: 0.24, alpha: 1) : UIColor(red: 0.80, green: 0.14, blue: 0.14, alpha: 1))
                    : .secondaryLabel
                giaTri = [
                    "DK CUỐI THÁNG",
                    duBao.duKienThucCuoiThang.chuoiSoVN,
                    duBao.duKienQDCuoiThang.chuoiSoVN,
                    duBao.phanTramQuyDoiDuKien.chuoiPhanTram,
                    "\(dkKhach.chuoiSoNguyenVN)/\(dkBill.chuoiSoNguyenVN)",
                    chuoiTrangThaiDK
                ]
            }

            for (i, chu) in giaTri.enumerated() {
                let lb = UILabel()
                lb.text = chu
                lb.textAlignment = (i == 0) ? .left : .right
                lb.numberOfLines = 0
                lb.lineBreakMode = .byWordWrapping
                lb.adjustsFontSizeToFitWidth = false
                lb.font = fontDongNhat
                if i == 0 {
                    lb.textColor = .label
                } else if i == 1 {
                    lb.textColor = UIColor(red: 0.15, green: 0.39, blue: 0.92, alpha: 1)
                } else if i == 2 {
                    lb.textColor = UIColor(red: 0.08, green: 0.60, blue: 0.28, alpha: 1)
                } else if i == 5 {
                    lb.textColor = mauChuCuoi
                } else {
                    lb.textColor = .label
                }
                stack.addArrangedSubview(lb)
                lb.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: tyLe[i]).isActive = true
            }
            return cell
        }

        cell.selectionStyle = .default
        let item = danhSachBieuDo[indexPath.row]
        let ngayChon = TienIchNgay.lich.component(.day, from: ngayHienTai)
        let laChon = (item.ngayTrongThang == ngayChon)
        cell.backgroundColor = laChon
            ? UIColor.systemBlue.withAlphaComponent(0.08)
            : (item.coDuLieu ? .systemBackground : UIColor.secondarySystemGroupedBackground.withAlphaComponent(0.5))

        let thang = TienIchNgay.lich.component(.month, from: item.ngay)
        let mtNgay = item.targetQuyDoi > 0 ? item.targetQuyDoi : duBao.mucTieuMoiNgay
        let ptHTNgay: Double
        if item.doanhThu.phanTramHTQuyDoi > 0 {
            ptHTNgay = item.doanhThu.phanTramHTQuyDoi
        } else if mtNgay > 0 && item.doanhThuQuyDoi > 0 {
            ptHTNgay = (item.doanhThuQuyDoi / mtNgay) * 100.0
        } else {
            ptHTNgay = 0
        }
        let datNgay = ptHTNgay >= 99.995
        let chuoiDanhGiaNgay: String
        if !item.coDuLieu {
            chuoiDanhGiaNgay = "--"
        } else if ptHTNgay > 0 {
            chuoiDanhGiaNgay = datNgay ? "✅ Đạt (\(ptHTNgay.chuoiPhanTram))" : "⚠️ Chưa (\(ptHTNgay.chuoiPhanTram))"
        } else {
            chuoiDanhGiaNgay = "Đã nhập"
        }

        let giaTri: [String] = [
            String(format: "%02d/%02d", item.ngayTrongThang, thang),
            item.coDuLieu ? item.doanhThuThuc.chuoiSoVN : "--",
            item.coDuLieu ? item.doanhThuQuyDoi.chuoiSoVN : "--",
            item.coDuLieu ? item.phanTramQuyDoi.chuoiPhanTram : "--",
            item.luotKhach > 0 || item.soBill > 0 ? "\(item.luotKhach.chuoiSoNguyenVN)/\(item.soBill.chuoiSoNguyenVN)" : "--",
            chuoiDanhGiaNgay
        ]

        for (i, chu) in giaTri.enumerated() {
            let lb = UILabel()
            lb.text = chu
            lb.textAlignment = (i == 0) ? .left : .right
            lb.numberOfLines = 0
            lb.lineBreakMode = .byWordWrapping
            lb.adjustsFontSizeToFitWidth = false
            lb.font = fontDongNhat
            if i == 0 {
                lb.textColor = laChon ? .systemBlue : .label
            } else if i == 1 {
                lb.textColor = item.coDuLieu ? UIColor(red: 0.15, green: 0.39, blue: 0.92, alpha: 1) : .secondaryLabel
            } else if i == 2 {
                lb.textColor = item.coDuLieu ? UIColor(red: 0.08, green: 0.60, blue: 0.28, alpha: 1) : .secondaryLabel
            } else if i == 5 {
                if !item.coDuLieu || ptHTNgay <= 0 {
                    lb.textColor = .secondaryLabel
                } else {
                    lb.textColor = datNgay
                        ? UIColor(red: 0.06, green: 0.52, blue: 0.24, alpha: 1)
                        : UIColor(red: 0.80, green: 0.14, blue: 0.14, alpha: 1)
                }
            } else {
                lb.textColor = .secondaryLabel
            }
            stack.addArrangedSubview(lb)
            lb.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: tyLe[i]).isActive = true
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < danhSachBieuDo.count else { return }
        khiChonNgayRealtime?(danhSachBieuDo[indexPath.row])
    }

    // MARK: - Xuất Ảnh Bảng Tổng Hợp & Đồ Thị Cột Realtime Tháng

    func taoAnhBaoCaoRealtimeThang(ngay: Date, thongTinDonVi: String = "", capNhatLuc: String = "") -> UIImage? {
        capNhat(cho: ngay)
        let dl = KhoDuLieu.dungChung.duLieu(cho: ngay)
        let donVi = !thongTinDonVi.isEmpty ? thongTinDonVi : (dl.thongTinDonVi.isEmpty ? "ĐIỆN MÁY XANH" : dl.thongTinDonVi)
        let thang = TienIchNgay.lich.component(.month, from: ngay)
        let nam = TienIchNgay.lich.component(.year, from: ngay)
        let dsCoSo = tatCaNgayTrongThang.filter { $0.coDuLieu }
        let dsVe = tatCaNgayTrongThang
        let duBao = KhoDuLieu.dungChung.tinhDuBaoQuyDoiTuRealtime(cho: ngay, cheDoDangXem: .realtime)
        let tomTat = taoNoiDungTomTatThang(dsCoSo: dsCoSo, duBao: duBao)

        let le: CGFloat = 18
        let rongBieuDo = max(860, 62 + CGFloat(dsVe.count) * 58)
        let rongAnh = rongBieuDo + le * 2

        let fontTomTat1 = UIFont.systemFont(ofSize: 12.5, weight: .bold)
        let fontTomTat2 = UIFont.systemFont(ofSize: 12.5, weight: .heavy)
        let caoD1 = max(20, ceil((tomTat.dong1 as NSString).boundingRect(
            with: CGSize(width: rongBieuDo - 24, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontTomTat1],
            context: nil
        ).height))
        let caoD2 = max(20, ceil((tomTat.dong2 as NSString).boundingRect(
            with: CGSize(width: rongBieuDo - 24, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontTomTat2],
            context: nil
        ).height))

        let caoHeader: CGFloat = 56
        let caoTieuDeLuyKe: CGFloat = 24
        let caoLuyKe: CGFloat = 88
        let caoHopTomTat: CGFloat = 16 + caoD1 + 6 + caoD2
        let caoBieuDo: CGFloat = 236
        let caoTieuDeBang: CGFloat = 24
        let caoHeaderBang: CGFloat = 42
        let caoDong: CGFloat = 48
        let tongSoDongBang = dsVe.count + soDongTongKetCuoiBang
        let caoBang = caoHeaderBang + CGFloat(max(1, tongSoDongBang)) * caoDong
        let caoAnh = le * 2 + caoHeader + 10 + caoTieuDeLuyKe + 6 + caoLuyKe + 12 + caoHopTomTat + 10 + caoBieuDo + 12 + caoTieuDeBang + 6 + caoBang

        let khung = UIView(frame: CGRect(x: 0, y: 0, width: rongAnh, height: caoAnh))
        khung.backgroundColor = .white
        khung.overrideUserInterfaceStyle = .light

        let lbPhu = UILabel(frame: CGRect(x: le, y: le, width: rongBieuDo, height: 20))
        lbPhu.text = "\(donVi)  •  Tháng \(String(format: "%02d/%04d", thang, nam))\(capNhatLuc.isEmpty ? "" : "  •  Cập nhật: \(capNhatLuc)")"
        lbPhu.font = .systemFont(ofSize: 12.5, weight: .bold)
        lbPhu.textColor = .darkGray
        lbPhu.numberOfLines = 0
        lbPhu.lineBreakMode = .byWordWrapping
        lbPhu.adjustsFontSizeToFitWidth = false
        khung.addSubview(lbPhu)

        let lbChinh = UILabel(frame: CGRect(x: le, y: le + 22, width: rongBieuDo, height: 30))
        lbChinh.text = "📊 BIỂU ĐỒ & TỔNG HỢP REALTIME THÁNG \(String(format: "%02d/%04d", thang, nam))"
        lbChinh.font = .systemFont(ofSize: 19, weight: .heavy)
        lbChinh.textColor = .black
        lbChinh.numberOfLines = 0
        lbChinh.lineBreakMode = .byWordWrapping
        lbChinh.adjustsFontSizeToFitWidth = false
        khung.addSubview(lbChinh)

        var y = le + caoHeader + 10

        let lbTieuDeLK = UILabel(frame: CGRect(x: le, y: y, width: rongBieuDo, height: caoTieuDeLuyKe))
        lbTieuDeLK.text = "📌 DOANH THU LŨY KẾ THÁNG \(String(format: "%02d/%04d", thang, nam)) (CỐ ĐỊNH — NHẬP MỚI THAY THẾ NGÀY TRƯỚC)"
        lbTieuDeLK.font = .systemFont(ofSize: 12.5, weight: .bold)
        lbTieuDeLK.textColor = .darkGray
        lbTieuDeLK.numberOfLines = 0
        lbTieuDeLK.lineBreakMode = .byWordWrapping
        lbTieuDeLK.adjustsFontSizeToFitWidth = false
        khung.addSubview(lbTieuDeLK)

        y += caoTieuDeLuyKe + 6

        let the1 = TheDoanhThuView(
            tieuDe: "💵 DOANH THU LŨY KẾ THỰC (THÁNG)",
            mauBatDau: UIColor(red: 0.14, green: 0.39, blue: 0.92, alpha: 1),
            mauKetThuc: UIColor(red: 0.23, green: 0.25, blue: 0.89, alpha: 1)
        )
        let kqLKThuc = doanhThuLuyKe.phanTramHTThucHienThi >= 99.995 ? "ĐẠT" : "CHƯA ĐẠT"
        the1.capNhatNoiDung(
            chinh: doanhThuLuyKe.doanhThuThuc.chuoiSoGonVN,
            phu: "TARGET: \(doanhThuLuyKe.targetThuc.chuoiSoGonVN) | HT: \(doanhThuLuyKe.phanTramHTThucHienThi.chuoiPhanTram) (\(kqLKThuc))",
            coLon: true
        )
        the1.frame = CGRect(x: le, y: y, width: (rongBieuDo - 12) / 2, height: caoLuyKe)
        the1.layoutIfNeeded()
        khung.addSubview(the1)

        let the2 = TheDoanhThuView(
            tieuDe: "🎯 DOANH THU LŨY KẾ QUY ĐỔI (THÁNG)",
            mauBatDau: UIColor(red: 0.09, green: 0.61, blue: 0.27, alpha: 1),
            mauKetThuc: UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1),
            hienChamTron: true
        )
        let dkLK = doanhThuLuyKe.duKienQuyDoi > 0 ? doanhThuLuyKe.duKienQuyDoi : doanhThuLuyKe.duKienThuc
        let kqLKQD = doanhThuLuyKe.phanTramHTQDDuKienHienThi >= 99.995 ? "ĐẠT" : "CHƯA ĐẠT"
        the2.capNhatNoiDung(
            chinh: doanhThuLuyKe.doanhThuQuyDoi.chuoiSoGonVN,
            phu: "TARGET: \(doanhThuLuyKe.targetQuyDoi.chuoiSoGonVN) | HT: \(doanhThuLuyKe.phanTramHTQDDuKienHienThi.chuoiPhanTram) (DK: \(dkLK.chuoiSoGonVN) - \(kqLKQD))",
            coLon: true
        )
        the2.frame = CGRect(x: le + (rongBieuDo - 12) / 2 + 12, y: y, width: (rongBieuDo - 12) / 2, height: caoLuyKe)
        the2.layoutIfNeeded()
        khung.addSubview(the2)

        y += caoLuyKe + 12

        let coPT = duBao.phanTramHTQDDuKien > 0 || duBao.mucTieuThang > 0
        let hopTomTat = UIView(frame: CGRect(x: le, y: y, width: rongBieuDo, height: caoHopTomTat))
        hopTomTat.backgroundColor = coPT
            ? (duBao.daHoanThanhDuKien ? UIColor(red: 0.92, green: 0.98, blue: 0.94, alpha: 1) : UIColor(red: 1.0, green: 0.96, blue: 0.90, alpha: 1))
            : UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1)
        hopTomTat.layer.cornerRadius = 10
        hopTomTat.layer.borderWidth = 1
        hopTomTat.layer.borderColor = (coPT
            ? (duBao.daHoanThanhDuKien ? UIColor.systemGreen : UIColor.systemOrange)
            : UIColor.systemBlue).withAlphaComponent(0.4).cgColor

        let lbDong1 = UILabel(frame: CGRect(x: 12, y: 8, width: rongBieuDo - 24, height: caoD1))
        lbDong1.text = tomTat.dong1
        lbDong1.font = fontTomTat1
        lbDong1.textColor = .black
        lbDong1.numberOfLines = 0
        lbDong1.lineBreakMode = .byWordWrapping
        lbDong1.adjustsFontSizeToFitWidth = false
        hopTomTat.addSubview(lbDong1)

        let lbDong2 = UILabel(frame: CGRect(x: 12, y: 8 + caoD1 + 6, width: rongBieuDo - 24, height: caoD2))
        lbDong2.text = tomTat.dong2
        lbDong2.font = fontTomTat2
        lbDong2.numberOfLines = 0
        lbDong2.lineBreakMode = .byWordWrapping
        lbDong2.adjustsFontSizeToFitWidth = false
        lbDong2.textColor = coPT
            ? (duBao.daHoanThanhDuKien ? UIColor(red: 0.06, green: 0.50, blue: 0.22, alpha: 1) : UIColor(red: 0.78, green: 0.18, blue: 0.08, alpha: 1))
            : UIColor(red: 0.14, green: 0.39, blue: 0.92, alpha: 1)
        hopTomTat.addSubview(lbDong2)
        khung.addSubview(hopTomTat)

        y += caoHopTomTat + 10

        let hopBD = UIView(frame: CGRect(x: le, y: y, width: rongBieuDo, height: caoBieuDo))
        hopBD.backgroundColor = UIColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 1)
        hopBD.layer.cornerRadius = 10
        hopBD.layer.borderWidth = 1
        hopBD.layer.borderColor = UIColor.systemGray4.cgColor

        let lbLegend = UILabel(frame: CGRect(x: 12, y: 8, width: rongBieuDo - 24, height: 18))
        lbLegend.text = "BIỂU ĐỒ CỘT REALTIME THEO NGÀY (\(dsCoSo.count)/\(dsVe.count) NGÀY CÓ SỐ):   🟦 Doanh thu Thực     🟩 Doanh thu Quy đổi"
        lbLegend.font = .systemFont(ofSize: 12, weight: .bold)
        lbLegend.textColor = .black
        lbLegend.numberOfLines = 0
        lbLegend.lineBreakMode = .byWordWrapping
        lbLegend.adjustsFontSizeToFitWidth = false
        hopBD.addSubview(lbLegend)

        let chart = VeBieuDoCotRealtimeView(frame: CGRect(x: 4, y: 28, width: rongBieuDo - 8, height: caoBieuDo - 32))
        chart.overrideUserInterfaceStyle = .light
        chart.ngayDangChon = TienIchNgay.lich.component(.day, from: ngay)
        chart.danhSachNgay = dsVe
        hopBD.addSubview(chart)
        khung.addSubview(hopBD)

        y += caoBieuDo + 12

        let lbTieuDeBangXuat = UILabel(frame: CGRect(x: le, y: y, width: rongBieuDo, height: caoTieuDeBang))
        lbTieuDeBangXuat.text = "📋 BẢNG CHI TIẾT REALTIME THEO NGÀY & ĐÁNH GIÁ DỰ KIẾN CUỐI THÁNG"
        lbTieuDeBangXuat.font = .systemFont(ofSize: 13, weight: .heavy)
        lbTieuDeBangXuat.textColor = .black
        lbTieuDeBangXuat.numberOfLines = 0
        lbTieuDeBangXuat.lineBreakMode = .byWordWrapping
        lbTieuDeBangXuat.adjustsFontSizeToFitWidth = false
        khung.addSubview(lbTieuDeBangXuat)

        y += caoTieuDeBang + 6

        let khungBang = UIView(frame: CGRect(x: le, y: y, width: rongBieuDo, height: caoBang))
        khungBang.layer.borderWidth = 1
        khungBang.layer.borderColor = UIColor.systemGray4.cgColor
        khungBang.layer.cornerRadius = 8
        khungBang.clipsToBounds = true
        khung.addSubview(khungBang)

        let cu = self.danhSachBieuDo
        self.danhSachBieuDo = dsVe
        if let hView = self.tableView(bangNgay, viewForHeaderInSection: 0) {
            hView.frame = CGRect(x: 0, y: 0, width: rongBieuDo, height: caoHeaderBang)
            hView.layoutIfNeeded()
            khungBang.addSubview(hView)
        }
        for i in 0..<tongSoDongBang {
            let cell = self.tableView(bangNgay, cellForRowAt: IndexPath(row: i, section: 0))
            let vDong = cell.contentView
            vDong.frame = CGRect(x: 0, y: caoHeaderBang + CGFloat(i) * caoDong, width: rongBieuDo, height: caoDong)
            vDong.backgroundColor = cell.backgroundColor
            vDong.layoutIfNeeded()
            let vach = UIView(frame: CGRect(x: 0, y: caoDong - 0.5, width: rongBieuDo, height: 0.5))
            vach.backgroundColor = .systemGray4
            vDong.addSubview(vach)
            khungBang.addSubview(vDong)
        }
        self.danhSachBieuDo = cu

        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2.0
        let anh = UIGraphicsImageRenderer(size: khung.bounds.size, format: fmt).image { ctx in
            khung.layer.render(in: ctx.cgContext)
        }
        bangNgay.reloadData()
        return anh
    }

    // MARK: - Xuất File Excel (.csv) cho Bảng Biểu Đồ & Tổng Hợp Realtime Tháng

    func taoChuoiExcelCSVBieuDoThang(ngay: Date, thongTinDonVi: String = "", capNhatLuc: String = "") -> String {
        capNhat(cho: ngay)
        let dl = KhoDuLieu.dungChung.duLieu(cho: ngay)
        let donVi = !thongTinDonVi.isEmpty ? thongTinDonVi : (dl.thongTinDonVi.isEmpty ? "ĐIỆN MÁY XANH" : dl.thongTinDonVi)
        let thang = TienIchNgay.lich.component(.month, from: ngay)
        let nam = TienIchNgay.lich.component(.year, from: ngay)
        let dsCoSo = tatCaNgayTrongThang.filter { $0.coDuLieu }
        let duBao = KhoDuLieu.dungChung.tinhDuBaoQuyDoiTuRealtime(cho: ngay, cheDoDangXem: .realtime)
        let tomTat = taoNoiDungTomTatThang(dsCoSo: dsCoSo, duBao: duBao)

        var cacDong: [String] = []
        cacDong.append("\"BIỂU ĐỒ & TỔNG HỢP REALTIME THÁNG \(String(format: "%02d/%04d", thang, nam))\",\"\(donVi)\",\"Cập nhật: \(capNhatLuc)\"")
        cacDong.append("")
        cacDong.append("PHẦN 1: DOANH THU LŨY KẾ THÁNG,GIÁ TRỊ,TARGET,TỶ LỆ HT,ĐÁNH GIÁ")
        let kqLKThuc = doanhThuLuyKe.phanTramHTThucHienThi >= 99.995 ? "ĐẠT" : "CHƯA ĐẠT"
        let kqLKQD = doanhThuLuyKe.phanTramHTQDDuKienHienThi >= 99.995 ? "ĐẠT" : "CHƯA ĐẠT"
        cacDong.append("\"DT Lũy kế Thực (Tháng)\",\(doanhThuLuyKe.doanhThuThuc),\(doanhThuLuyKe.targetThuc),\(String(format: "%.2f%%", doanhThuLuyKe.phanTramHTThucHienThi)),\"\(kqLKThuc)\"")
        cacDong.append("\"DT Lũy kế Quy đổi (Tháng)\",\(doanhThuLuyKe.doanhThuQuyDoi),\(doanhThuLuyKe.targetQuyDoi),\(String(format: "%.2f%%", doanhThuLuyKe.phanTramHTQDDuKienHienThi)),\"\(kqLKQD)\"")
        cacDong.append("")
        cacDong.append("PHẦN 2: TÓM TẮT & DỰ BÁO CUỐI THÁNG TỪ REALTIME")
        cacDong.append("\"\(tomTat.dong1.replacingOccurrences(of: "\"", with: "\"\""))\"")
        cacDong.append("\"\(tomTat.dong2.replacingOccurrences(of: "\"", with: "\"\""))\"")
        cacDong.append("\"Trạng thái DK cuối tháng\",\"\(tomTat.trangThaiDK)\",\"DK QĐ cuối tháng: \(duBao.duKienQDCuoiThang.chuoiSoVN)\",\"Target QĐ tháng: \(duBao.mucTieuThang.chuoiSoVN)\",\"% HT QĐ DK: \(duBao.phanTramHTQDDuKien.chuoiPhanTramVN)\"")
        cacDong.append("")
        cacDong.append("PHẦN 3: BẢNG CHI TIẾT REALTIME THEO NGÀY")
        cacDong.append("Ngày,DT Thực (RT),DT Quy đổi (RT),Target Ngày QĐ,% HT Ngày,% Quy đổi,Lượt khách,Số Bill,Đánh giá ngày")

        for item in tatCaNgayTrongThang {
            let ngayStr = String(format: "%02d/%02d/%04d", item.ngayTrongThang, thang, nam)
            let mtNgay = item.targetQuyDoi > 0 ? item.targetQuyDoi : duBao.mucTieuMoiNgay
            let ptHTNgay: Double
            if item.doanhThu.phanTramHTQuyDoi > 0 {
                ptHTNgay = item.doanhThu.phanTramHTQuyDoi
            } else if mtNgay > 0 && item.doanhThuQuyDoi > 0 {
                ptHTNgay = (item.doanhThuQuyDoi / mtNgay) * 100.0
            } else {
                ptHTNgay = 0
            }
            let danhGia: String
            if !item.coDuLieu {
                danhGia = "Chưa nhập"
            } else if ptHTNgay > 0 {
                danhGia = ptHTNgay >= 99.995 ? "ĐẠT (\(String(format: "%.1f%%", ptHTNgay)))" : "CHƯA ĐẠT (\(String(format: "%.1f%%", ptHTNgay)))"
            } else {
                danhGia = "Đã nhập"
            }
            cacDong.append("\(ngayStr),\(item.doanhThuThuc),\(item.doanhThuQuyDoi),\(String(format: "%.2f", mtNgay)),\(String(format: "%.2f%%", ptHTNgay)),\(String(format: "%.2f%%", item.phanTramQuyDoi)),\(Int(item.luotKhach)),\(Int(item.soBill)),\"\(danhGia)\"")
        }

        let tongRTThuc = dsCoSo.reduce(0.0) { $0 + $1.doanhThuThuc }
        let tongRTQD = dsCoSo.reduce(0.0) { $0 + $1.doanhThuQuyDoi }
        let tongKhach = dsCoSo.reduce(0.0) { $0 + $1.luotKhach }
        let tongBill = dsCoSo.reduce(0.0) { $0 + $1.soBill }
        let ptQDTong = tongRTThuc > 0 ? ((tongRTQD - tongRTThuc) / tongRTThuc * 100.0) : 0
        let mtDenNay = duBao.mucTieuMoiNgay * Double(max(1, dsCoSo.count))
        let ptDenNay = mtDenNay > 0 ? (tongRTQD / mtDenNay * 100.0) : 0
        let danhGiaTong = mtDenNay > 0 ? (ptDenNay >= 99.995 ? "ĐẠT TIẾN ĐỘ" : "CHƯA ĐẠT TIẾN ĐỘ") : "\(dsCoSo.count) ngày"
        let soN = Double(max(1, dsCoSo.count))

        cacDong.append("\"TỔNG CỘNG (\(dsCoSo.count) ngày)\",\(String(format: "%.2f", tongRTThuc)),\(String(format: "%.2f", tongRTQD)),\(String(format: "%.2f", mtDenNay)),\(String(format: "%.2f%%", ptDenNay)),\(String(format: "%.2f%%", ptQDTong)),\(Int(tongKhach)),\(Int(tongBill)),\"\(danhGiaTong)\"")
        cacDong.append("\"TRUNG BÌNH / NGÀY\",\(String(format: "%.2f", duBao.trungBinhThucMoiNgay)),\(String(format: "%.2f", duBao.trungBinhQDMoiNgay)),\(String(format: "%.2f", duBao.mucTieuMoiNgay)),\(String(format: "%.2f%%", ptDenNay)),\(String(format: "%.2f%%", ptQDTong)),\(Int(round(tongKhach / soN))),\(Int(round(tongBill / soN))),\"TB \(dsCoSo.count) ngày\"")
        let coPT = duBao.phanTramHTQDDuKien > 0 || duBao.mucTieuThang > 0
        let kqCuoiThang = coPT ? (duBao.daHoanThanhDuKien ? "ĐẠT MỤC TIÊU (\(duBao.phanTramHTQDDuKien.chuoiPhanTramVN))" : "CHƯA ĐẠT (\(duBao.phanTramHTQDDuKien.chuoiPhanTramVN))") : "--"
        cacDong.append("\"DK CUỐI THÁNG (\(duBao.soNgayTrongThang) ngày)\",\(String(format: "%.2f", duBao.duKienThucCuoiThang)),\(String(format: "%.2f", duBao.duKienQDCuoiThang)),\(String(format: "%.2f", duBao.mucTieuThang)),\(String(format: "%.2f%%", duBao.phanTramHTQDDuKien)),\(String(format: "%.2f%%", duBao.phanTramQuyDoiDuKien)),\(Int(round(tongKhach / soN * Double(duBao.soNgayTrongThang)))),\(Int(round(tongBill / soN * Double(duBao.soNgayTrongThang)))),\"\(kqCuoiThang)\"")

        return "\u{FEFF}" + cacDong.joined(separator: "\n")
    }
}
