import UIKit

final class ManHinhCaiDat: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    private let ngay: Date
    private let oNhapMucTieuQDThang = UITextField()
    private let nhanChiTietMucTieuThang = UILabel()
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cài đặt & Nhân viên"
        view.backgroundColor = .systemGroupedBackground

        let nutLuu = UIBarButtonItem(
            title: "Lưu",
            style: .done,
            target: self,
            action: #selector(luuCaiDat)
        )
        let nutTaiKhoan = UIBarButtonItem(
            image: UIImage(systemName: "rectangle.portrait.and.arrow.right"),
            style: .plain,
            target: self,
            action: #selector(moQuanLyTaiKhoan)
        )
        nutTaiKhoan.tintColor = .systemRed
        navigationItem.rightBarButtonItems = [nutLuu, nutTaiKhoan]

        let cd = KhoDuLieu.dungChung.caiDat
        chonKieuHienThi.selectedSegmentIndex = cd.kieuHienThi.rawValue
        danhSachCumTu = cd.danhSachCumTuLocBo
        let chiSoCot = max(0, min(3, cd.soCotXuatAnh - 1))
        chonSoCotXuat.selectedSegmentIndex = chiSoCot

        let mtHienTai = KhoDuLieu.dungChung.mucTieuDoanhThuQDThang(cho: ngay)
        if mtHienTai > 0 {
            oNhapMucTieuQDThang.text = String(format: "%.2f", mtHienTai).replacingOccurrences(of: ".00", with: "")
        }

        taoGiaoDien()
        capNhatTieuDeNutNhanVien()
        capNhatThongTinChiaMucTieuThang()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        capNhatTieuDeNutNhanVien()
        capNhatThongTinChiaMucTieuThang()
    }

    private func capNhatTieuDeNutNhanVien() {
        let cd = KhoDuLieu.dungChung.caiDat
        let soMH = KhoDuLieu.dungChung.danhSachMatHangThang(den: ngay).count
        nutChiaTarget.setTitle("🎯 1. Chia Target mặt hàng (\(soMH) mặt hàng) ▸", for: .normal)
        nutQuanLyNV.setTitle("👥 2. Danh sách nhân viên quản lý (\(cd.danhSachNhanVien.count) NV) ▸", for: .normal)
    }

    private func docSoMucTieuTuO() -> Double {
        let raw = (oNhapMucTieuQDThang.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
        guard !raw.isEmpty else { return 0 }
        let chuan = raw.replacingOccurrences(of: ",", with: ".")
        return Double(chuan) ?? 0
    }

    @objc private func khiThayDoiMucTieuThang() {
        capNhatThongTinChiaMucTieuThang()
    }

    private func capNhatThongTinChiaMucTieuThang() {
        let soNgay = KhoDuLieu.dungChung.soNgayTrongThang(cho: ngay)
        let thang = TienIchNgay.lich.component(.month, from: ngay)
        let nam = TienIchNgay.lich.component(.year, from: ngay)
        let mucTieu = docSoMucTieuTuO()

        if mucTieu > 0 {
            let moiNgay = mucTieu / Double(max(1, soNgay))
            let duBao = KhoDuLieu.dungChung.tinhDuBaoQuyDoiTuRealtime(cho: ngay, cheDoDangXem: .realtime)
            var chuoi = "📅 Tháng \(String(format: "%02d/%04d", thang, nam)) có \(soNgay) ngày thực tế  →  Tự chia: \(moiNgay.chuoiSoVN) / ngày."
            if duBao.soNgayCoRealtime > 0 {
                let dkCuoiThang = duBao.trungBinhQDMoiNgay * Double(soNgay)
                let ptDK = (dkCuoiThang / mucTieu) * 100.0
                let kq = ptDK >= 99.995 ? "✅ ĐẠT MỤC TIÊU" : "⚠️ CHƯA ĐẠT"
                chuoi += "\n📊 Đã nhập \(duBao.soNgayCoRealtime) ngày RT (TB \(duBao.trungBinhQDMoiNgay.chuoiSoVN)/ngày) → Cuối tháng dự kiến: \(dkCuoiThang.chuoiSoVN) (\(ptDK.chuoiPhanTramVN) - \(kq))"
            } else {
                chuoi += "\n💡 Khi nhập 2 ảnh Realtime mỗi ngày, app sẽ tự lấy TB các ngày × \(soNgay) ngày để tính % HT QĐ dự kiến cuối tháng."
            }
            nhanChiTietMucTieuThang.text = chuoi
            nhanChiTietMucTieuThang.textColor = UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1)
        } else {
            nhanChiTietMucTieuThang.text = "📅 Tháng \(String(format: "%02d/%04d", thang, nam)) có \(soNgay) ngày thực tế.\nNhập mục tiêu DT quy đổi tháng để app tự chia cho \(soNgay) ngày và tự tính % HT QĐ dự kiến cuối tháng từ các ngày Realtime."
            nhanChiTietMucTieuThang.textColor = .secondaryLabel
        }
    }

    @objc private func bamApDungMucTieuThang() {
        oNhapMucTieuQDThang.resignFirstResponder()
        let mucTieu = docSoMucTieuTuO()
        KhoDuLieu.dungChung.luuMucTieuDoanhThuQDThang(mucTieu, cho: ngay)
        capNhatThongTinChiaMucTieuThang()
    }

    @objc private func moQuanLyTaiKhoan() {
        let tk = DichVuDongBo.dungChung.tenDangNhap.isEmpty ? "Tài khoản" : DichVuDongBo.dungChung.tenDangNhap
        let menu = UIAlertController(
            title: "Tài khoản ĐMX: \(tk)",
            message: "Dữ liệu được đồng bộ tự động với nhánh duongnt.io.vn/dmx.",
            preferredStyle: .actionSheet
        )
        menu.addAction(UIAlertAction(title: "🔄 Đồng bộ dữ liệu ngay", style: .default) { _ in
            DichVuDongBo.dungChung.taiDuLieu()
        })
        menu.addAction(UIAlertAction(title: "Đăng xuất tài khoản", style: .destructive) { _ in
            DichVuDongBo.dungChung.dangXuat()
            (UIApplication.shared.delegate as? UyQuyenUngDung)?.hienThiDangNhap()
        })
        menu.addAction(UIAlertAction(title: "Đóng", style: .cancel))
        if let pop = menu.popoverPresentationController {
            pop.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        present(menu, animated: true)
    }

    private func dongBoTamCaiDat() {
        if let dangGo = oNhapCumTu.text?.trimmingCharacters(in: .whitespacesAndNewlines), !dangGo.isEmpty {
            if !danhSachCumTu.contains(where: { $0.caseInsensitiveCompare(dangGo) == .orderedSame }) {
                danhSachCumTu.insert(dangGo, at: 0)
            }
            oNhapCumTu.text = ""
        }
        let mucTieuThang = docSoMucTieuTuO()
        KhoDuLieu.dungChung.luuMucTieuDoanhThuQDThang(mucTieuThang, cho: ngay)

        let kieu = KieuHienThiBaoCao(rawValue: chonKieuHienThi.selectedSegmentIndex) ?? .bangChiTiet
        let soCot = chonSoCotXuat.selectedSegmentIndex + 1
        var moi = KhoDuLieu.dungChung.caiDat
        moi.kieuHienThi = kieu
        moi.danhSachCumTuLocBo = danhSachCumTu
        moi.soCotXuatAnh = soCot
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

        // Khối 0: Mục tiêu Doanh thu Quy đổi Tháng (Tự chia theo số ngày thực tế của tháng hiện tại)
        let thang = TienIchNgay.lich.component(.month, from: ngay)
        let nam = TienIchNgay.lich.component(.year, from: ngay)
        let soNgayThang = KhoDuLieu.dungChung.soNgayTrongThang(cho: ngay)
        let tieuDeMucTieu = taoTieuDeNhom("🎯 DOANH THU QUY ĐỔI MỤC TIÊU THÁNG \(String(format: "%02d/%04d", thang, nam)) (\(soNgayThang) NGÀY)")
        let khungMucTieu = UIView()
        khungMucTieu.backgroundColor = .secondarySystemGroupedBackground
        khungMucTieu.layer.cornerRadius = 12
        khungMucTieu.layer.borderWidth = 1
        khungMucTieu.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.35).cgColor

        oNhapMucTieuQDThang.placeholder = "Nhập mục tiêu DT quy đổi tháng (VD: 15000)..."
        oNhapMucTieuQDThang.borderStyle = .roundedRect
        oNhapMucTieuQDThang.font = .systemFont(ofSize: 15, weight: .bold)
        oNhapMucTieuQDThang.keyboardType = .decimalPad
        oNhapMucTieuQDThang.clearButtonMode = .whileEditing
        oNhapMucTieuQDThang.addTarget(self, action: #selector(khiThayDoiMucTieuThang), for: .editingChanged)

        let nutLuuMT = UIButton(type: .system)
        nutLuuMT.setTitle(" Áp dụng ", for: .normal)
        nutLuuMT.titleLabel?.font = .systemFont(ofSize: 13.5, weight: .bold)
        nutLuuMT.backgroundColor = UIColor(red: 0.09, green: 0.61, blue: 0.27, alpha: 1)
        nutLuuMT.tintColor = .white
        nutLuuMT.layer.cornerRadius = 8
        nutLuuMT.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        nutLuuMT.setContentHuggingPriority(.required, for: .horizontal)
        nutLuuMT.addTarget(self, action: #selector(bamApDungMucTieuThang), for: .touchUpInside)

        let hangNhapMT = UIStackView(arrangedSubviews: [oNhapMucTieuQDThang, nutLuuMT])
        hangNhapMT.axis = .horizontal
        hangNhapMT.spacing = 8

        nhanChiTietMucTieuThang.font = .systemFont(ofSize: 12.5, weight: .semibold)
        nhanChiTietMucTieuThang.numberOfLines = 0

        let nganMT = UIStackView(arrangedSubviews: [hangNhapMT, nhanChiTietMucTieuThang])
        nganMT.axis = .vertical
        nganMT.spacing = 6
        nganMT.translatesAutoresizingMaskIntoConstraints = false
        khungMucTieu.addSubview(nganMT)

        // Khối 1 & 2: Chia Target mặt hàng & Quản lý danh sách nhân viên
        let tieuDeNV = taoTieuDeNhom("1 & 2. CHIA TARGET MẶT HÀNG & QUẢN LÝ NHÂN VIÊN")
        let khungNV = UIView()
        khungNV.backgroundColor = .secondarySystemGroupedBackground
        khungNV.layer.cornerRadius = 12

        [nutChiaTarget, nutQuanLyNV].forEach { nut in
            nut.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
            nut.contentHorizontalAlignment = .left
            nut.backgroundColor = .systemBackground
            nut.tintColor = .systemBlue
            nut.layer.cornerRadius = 10
            nut.layer.borderWidth = 1
            nut.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.22).cgColor
            nut.contentEdgeInsets = UIEdgeInsets(top: 11, left: 12, bottom: 11, right: 12)
        }
        nutChiaTarget.addTarget(self, action: #selector(moChiaTarget), for: .touchUpInside)
        nutQuanLyNV.addTarget(self, action: #selector(moQuanLyNhanVien), for: .touchUpInside)

        let nganNV = UIStackView(arrangedSubviews: [nutChiaTarget, nutQuanLyNV])
        nganNV.axis = .vertical
        nganNV.spacing = 8
        nganNV.translatesAutoresizingMaskIntoConstraints = false
        khungNV.addSubview(nganNV)

        // Khối 3: Chọn kiểu hiển thị & xuất báo cáo
        let tieuDeKieu = taoTieuDeNhom("3. KIỂU HIỂN THỊ & XUẤT BÁO CÁO")
        let khungKieu = UIView()
        khungKieu.backgroundColor = .secondarySystemGroupedBackground
        khungKieu.layer.cornerRadius = 12

        let nhanMoTaKieu = UILabel()
        nhanMoTaKieu.text = "Chọn 1 trong 2 mẫu hiển thị trên màn hình và khi xuất ảnh:"
        nhanMoTaKieu.font = .systemFont(ofSize: 13)
        nhanMoTaKieu.textColor = .secondaryLabel
        nhanMoTaKieu.numberOfLines = 0

        let nhanMoTaCot = UILabel()
        nhanMoTaCot.text = "Số cột khi xuất ảnh (áp dụng cho mẫu Thẻ tiến độ):"
        nhanMoTaCot.font = .systemFont(ofSize: 13)
        nhanMoTaCot.textColor = .secondaryLabel
        nhanMoTaCot.numberOfLines = 0

        let nganKieu = UIStackView(arrangedSubviews: [nhanMoTaKieu, chonKieuHienThi, nhanMoTaCot, chonSoCotXuat])
        nganKieu.axis = .vertical
        nganKieu.spacing = 8
        nganKieu.translatesAutoresizingMaskIntoConstraints = false
        khungKieu.addSubview(nganKieu)

        // Khối 4: Cụm từ lọc bỏ trong tất cả ngành hàng
        let tieuDeLoc = taoTieuDeNhom("4. CỤM TỪ LỌC BỎ TRONG TẤT CẢ NGÀNH HÀNG")
        let khungLoc = UIView()
        khungLoc.backgroundColor = .secondarySystemGroupedBackground
        khungLoc.layer.cornerRadius = 12
        khungLoc.clipsToBounds = true

        oNhapCumTu.placeholder = "Nhập cụm từ muốn lọc bỏ (VD: 275 Quang Trung)..."
        oNhapCumTu.borderStyle = .roundedRect
        oNhapCumTu.font = .systemFont(ofSize: 14)
        oNhapCumTu.clearButtonMode = .whileEditing
        oNhapCumTu.returnKeyType = .done
        oNhapCumTu.delegate = self

        let nutThem = UIButton(type: .system)
        nutThem.setTitle(" + Thêm ", for: .normal)
        nutThem.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        nutThem.backgroundColor = .systemBlue
        nutThem.tintColor = .white
        nutThem.layer.cornerRadius = 8
        nutThem.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        nutThem.addTarget(self, action: #selector(bamThemCumTu), for: .touchUpInside)
        nutThem.setContentHuggingPriority(.required, for: .horizontal)

        let hangNhap = UIStackView(arrangedSubviews: [oNhapCumTu, nutThem])
        hangNhap.axis = .horizontal
        hangNhap.spacing = 8

        let vachNgan = UIView()
        vachNgan.backgroundColor = .separator

        bangCumTu.dataSource = self
        bangCumTu.delegate = self
        bangCumTu.rowHeight = 42
        bangCumTu.backgroundColor = .clear
        bangCumTu.separatorInset = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)

        [hangNhap, vachNgan, bangCumTu].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            khungLoc.addSubview($0)
        }

        [tieuDeMucTieu, khungMucTieu, tieuDeNV, khungNV, tieuDeKieu, khungKieu, tieuDeLoc, khungLoc].forEach {
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

            nganMT.topAnchor.constraint(equalTo: khungMucTieu.topAnchor, constant: 10),
            nganMT.leadingAnchor.constraint(equalTo: khungMucTieu.leadingAnchor, constant: 12),
            nganMT.trailingAnchor.constraint(equalTo: khungMucTieu.trailingAnchor, constant: -12),
            nganMT.bottomAnchor.constraint(equalTo: khungMucTieu.bottomAnchor, constant: -10),

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
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == oNhapMucTieuQDThang {
            bamApDungMucTieuThang()
            return true
        }
        bamThemCumTu()
        textField.resignFirstResponder()
        return true
    }

    @objc private func luuCaiDat() {
        dongBoTamCaiDat()
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

        if danhSachCumTu.isEmpty {
            cell.textLabel?.text = "Chưa có cụm từ lọc bỏ nào"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.font = .systemFont(ofSize: 13)
            cell.detailTextLabel?.text = nil
            cell.accessoryView = nil
        } else {
            let cumTu = danhSachCumTu[indexPath.row]
            cell.textLabel?.text = "\"\(cumTu)\""
            cell.textLabel?.textColor = .label
            cell.textLabel?.font = .systemFont(ofSize: 14, weight: .semibold)

            let nutXoa = UIButton(type: .system)
            nutXoa.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            nutXoa.tintColor = .systemRed
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
    }

    private func taoTieuDeNhom(_ chu: String) -> UILabel {
        let nhan = UILabel()
        nhan.text = chu
        nhan.font = .systemFont(ofSize: 11.5, weight: .bold)
        nhan.textColor = .secondaryLabel
        return nhan
    }
}
