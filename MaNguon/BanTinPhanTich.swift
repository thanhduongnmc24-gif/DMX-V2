import UIKit

// MARK: - Khung bản tin & giọng văn

/// 3 khung bản tin trong ngày: Đầu ca (tới 9h) · Hiện tại (9h–19h) · Kết ca (sau 19h)
enum KhungBanTin: Int, CaseIterable {
    case dauCa = 0
    case hienTai = 1
    case ketCa = 2

    var tieuDe: String {
        switch self {
        case .dauCa: return "☀️ Đầu ca"
        case .hienTai: return "⏱ Hiện tại"
        case .ketCa: return "🌙 Kết ca"
        }
    }

    var tenNgan: String {
        switch self {
        case .dauCa: return "ĐẦU CA"
        case .hienTai: return "HIỆN TẠI"
        case .ketCa: return "KẾT CA"
        }
    }

    /// Tự chọn khung theo giờ hiện tại: tới 9h = Đầu ca, 9h–19h = Hiện tại, sau 19h = Kết ca
    static func theoGio(_ luc: Date = Date()) -> KhungBanTin {
        let gio = TienIchNgay.lich.component(.hour, from: luc)
        if gio < 9 { return .dauCa }
        if gio < 19 { return .hienTai }
        return .ketCa
    }
}

enum GiongVanBanTin: Int, CaseIterable {
    case binhThuong = 0
    case cangThang = 1
    case thaoMai = 2

    var tieuDe: String {
        switch self {
        case .binhThuong: return "Bình thường"
        case .cangThang: return "Căng thẳng"
        case .thaoMai: return "Thảo mai"
        }
    }
}

// MARK: - Loại báo cáo trong mục "3. Xuất ảnh"

enum LoaiBaoCaoXuatAnh: Int, CaseIterable {
    case doanhThuThiDuaLuyKe = 0
    case luyKeDuKien = 1
    case doanhThuThiDuaRealtime = 2
    case xepHangNVLuyKe = 3
    case xepHangNVRealtime = 4
    case bieuDoSucKhoeNV = 5
    case bieuDoRealtimeThang = 6
    case chiTiet16NV = 7

    var tieuDeNgan: String {
        switch self {
        case .doanhThuThiDuaLuyKe: return "📊 Doanh thu & Thi đua Lũy kế"
        case .luyKeDuKien: return "📈 Lũy kế — % Dự kiến cuối tháng"
        case .doanhThuThiDuaRealtime: return "⚡ Doanh thu & Thi đua Realtime"
        case .xepHangNVLuyKe: return "👥 Bảng Xếp Hạng NV (Lũy kế)"
        case .xepHangNVRealtime: return "🔥 Bảng Xếp Hạng NV (Realtime)"
        case .bieuDoSucKhoeNV: return "❤️‍🩹 Biểu Đồ Sức Khỏe 16 NV"
        case .bieuDoRealtimeThang: return "📆 Biểu Đồ Realtime Tháng"
        case .chiTiet16NV: return "👤 Gộp Chi Tiết Tất Cả NV"
        }
    }

    var moTaPhu: String {
        switch self {
        case .doanhThuThiDuaLuyKe: return "8 thẻ Doanh thu Lũy kế + Bảng ngành hàng Thực hiện & Target"
        case .luyKeDuKien: return "8 thẻ Doanh thu Lũy kế + Bảng % Dự kiến hoàn thành cuối tháng"
        case .doanhThuThiDuaRealtime: return "8 thẻ Doanh thu Realtime + Bảng ngành hàng trong ngày"
        case .xepHangNVLuyKe: return "Xếp hạng Doanh thu QĐ & số môn hoàn thành Lũy kế của NV"
        case .xepHangNVRealtime: return "Xếp hạng Doanh thu QĐ & số môn Realtime trong ngày của NV"
        case .bieuDoSucKhoeNV: return "Biểu đồ sức khỏe 16 NV & Cảnh báo Top 5 NV cần hỗ trợ"
        case .bieuDoRealtimeThang: return "Biểu đồ cột Doanh thu Realtime các ngày trong tháng"
        case .chiTiet16NV: return "Ảnh tổng hợp chi tiết các môn thi đua của toàn bộ nhân viên"
        }
    }
}

// MARK: - Bộ số liệu dùng để viết bản tin

struct SoLieuBanTin {
    var ngay: Date
    var khung: KhungBanTin
    var tenDonVi: String
    var capNhatLuc: String
    var luyKe: ThongTinDoanhThu
    var dsLuyKe: [DongThiDua]
    var homNay: ThongTinDoanhThu
    var dsHomNay: [DongThiDua]
    var nhanVien: [TongHopNhanVien]
    var homNayNV: [DoanhThuNhanVienItem]
    /// true = số Lũy kế đầu ca hôm nay chưa có, đang tính tạm từ (Lũy kế hôm qua + Realtime kết ca hôm qua)
    var tamTinh: Bool
    var soNgayTrongThang: Int
    var ngayTrongThang: Int

    /// Số ngày còn lại để chạy tới cuối tháng (đầu ca / hiện tại: tính cả hôm nay; kết ca: không tính hôm nay)
    var soNgayConLai: Int {
        let con = (khung == .ketCa) ? (soNgayTrongThang - ngayTrongThang) : (soNgayTrongThang - ngayTrongThang + 1)
        return max(1, con)
    }

    var coSoLieuLuyKe: Bool {
        luyKe.coDuLieu || !dsLuyKe.isEmpty
    }

    var coSoLieuHomNay: Bool {
        homNay.coDuLieu || !dsHomNay.isEmpty
    }
}

extension KhoDuLieu {
    /// Gom số liệu cho bản tin. Đầu ca chưa có số hôm nay → tự dựng "Đầu ca tạm tính".
    func taoSoLieuBanTin(cho ngay: Date, khung: KhungBanTin) -> SoLieuBanTin {
        let lich = TienIchNgay.lich
        let dl = duLieu(cho: ngay)
        let soNgay = soNgayTrongThang(cho: ngay)
        let ngayTrongThang = lich.component(.day, from: ngay)

        var luyKe = dl.doanhThu
        var dsLuyKe = danhSachMatHangThang(den: ngay, cheDo: .luyKe)
        var tamTinh = false

        if khung == .dauCa, ngayTrongThang > 1, lich.isDateInToday(ngay) {
            let khoaHomNay = TienIchNgay.khoa.string(from: ngay)
            let homNay = cacNgay[khoaHomNay]
            let homNayDaCo = (homNay?.doanhThu.coDuLieu ?? false) || !(homNay?.danhSachThiDua.isEmpty ?? true)
            if !homNayDaCo, let homQua = lich.date(byAdding: .day, value: -1, to: ngay) {
                let khoaQua = TienIchNgay.khoa.string(from: homQua)
                if let q = cacNgay[khoaQua], q.doanhThu.coDuLieu, q.doanhThuRealtime.coDuLieu {
                    let daQua = Double(max(1, ngayTrongThang - 1))
                    let tong = Double(soNgay)

                    var lk = q.doanhThu
                    lk.doanhThuThuc += q.doanhThuRealtime.doanhThuThuc
                    lk.doanhThuQuyDoi += q.doanhThuRealtime.doanhThuQuyDoi
                    if lk.phanTramHTThuc > 0, lk.targetThuc > 0 {
                        lk.phanTramHTThuc = lk.doanhThuThuc / lk.targetThuc * 100.0
                    }
                    lk.duKienThuc = lk.doanhThuThuc / daQua * tong
                    lk.duKienQuyDoi = lk.doanhThuQuyDoi / daQua * tong
                    if lk.targetQuyDoi > 0 {
                        lk.phanTramHTQuyDoi = lk.duKienQuyDoi / lk.targetQuyDoi * 100.0
                    }
                    lk.soNgayDaQua = Int(daQua)
                    lk.tongSoNgay = soNgay
                    lk.phanTramTienDoThang = daQua / tong * 100.0

                    var dsTam: [DongThiDua] = []
                    for d in q.danhSachThiDua {
                        let khoa = KhoDuLieu.chuanHoaKhoaSoSanh(d.tenNganhHang)
                        var them: Double = 0
                        for r in q.danhSachThiDuaRealtime where KhoDuLieu.chuanHoaKhoaSoSanh(r.tenNganhHang) == khoa {
                            them = r.thucHien
                            break
                        }
                        let thucHien = d.thucHien + them
                        let duKien = thucHien / daQua * tong
                        let phanTramHT: Double? = d.target > 0 ? (thucHien / d.target * 100.0) : nil
                        let phanTramDuBao: Double? = d.target > 0 ? (duKien / d.target * 100.0) : nil
                        let dong = DongThiDua(
                            tenNganhHangGoc: d.tenNganhHangGoc,
                            tenNganhHang: d.tenNganhHang,
                            loaiChiTieu: d.loaiChiTieu,
                            thucHien: thucHien,
                            target: d.target,
                            phanTramHTGoc: phanTramHT,
                            phanTramDuBaoGoc: phanTramDuBao,
                            duKienGoc: duKien
                        )
                        dsTam.append(dong)
                    }
                    luyKe = lk
                    dsLuyKe = dsTam
                    tamTinh = true
                }
            }
        }

        return SoLieuBanTin(
            ngay: ngay,
            khung: khung,
            tenDonVi: dl.thongTinDonVi,
            capNhatLuc: dl.capNhatLuc,
            luyKe: luyKe,
            dsLuyKe: dsLuyKe,
            homNay: dl.doanhThuRealtime,
            dsHomNay: dl.danhSachThiDuaRealtime,
            nhanVien: tongHopNhanVien(den: ngay, sapXep: .soMonHoanThanh, cheDo: .luyKe),
            homNayNV: dl.doanhThuNhanVienRealtime,
            tamTinh: tamTinh,
            soNgayTrongThang: soNgay,
            ngayTrongThang: ngayTrongThang
        )
    }
}

// MARK: - Bộ sinh số ngẫu nhiên theo hạt giống

struct BoSinhNgauNhien: RandomNumberGenerator {
    private var trangThai: UInt64

    init(hatGiong: String) {
        var h: UInt64 = 1469598103934665603
        for byte in hatGiong.utf8 {
            h ^= UInt64(byte)
            h = h &* 1099511628211
        }
        trangThai = h
    }

    mutating func next() -> UInt64 {
        trangThai = trangThai &+ 0x9E3779B97F4A7C15
        var z = trangThai
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

// MARK: - Bộ viết bài Phân tích (theo đúng mẫu đính kèm & cho từng loại ảnh xuất)

final class BoVietBanTin {
    private var rng: BoSinhNgauNhien
    private let s: SoLieuBanTin
    private let giong: GiongVanBanTin

    private struct LoiDan {
        var mo: String
        var viec: String
        var duoiTapTrung: String
        var ket: String
    }

    /// Việc cụ thể theo nhóm hàng: (từ khóa, việc làm)
    private static let bangViec: [([String], String)] = [
        (["sim"], "mời 100% khách mua máy lấy sim, để sẵn bộ sim + bảng giá gói cước ngay quầy thu ngân"),
        (["bao hiem"], "chào bảo hiểm cho mọi đơn máy từ 3 triệu, nói rõ quyền lợi rơi vỡ – vào nước trong 1 câu"),
        (["phu kien", "cap", "sac", "tai nghe", "op", "dan"], "giao máy là đưa combo phụ kiện ra bàn: ốp + dán + sạc, báo giá combo thay vì từng món"),
        (["tra cham", "tra gop", "vay", "the tin dung", "vi tra sau", "homecredit", "fecredit"], "khách chê giá hoặc phân vân thì mời ngay trả chậm 0%, tính sẵn số tiền mỗi tháng để khách dễ gật"),
        (["laptop", "tablet", "dong ho", "camera", "may doc sach"], "mời khách trải nghiệm máy trưng bày, demo tính năng chính trong 2 phút"),
        (["iphone"], "chủ động gợi ý đổi máy cũ lên iPhone, báo giá thu cũ ngay tại quầy"),
        (["vas", "nap", "rut", "tai khoan"], "mời khách nạp/rút tiền, mở tài khoản ngay lúc chờ thanh toán"),
        (["dien thoai"], "đón khách ở khu điện thoại, so sánh 2 mẫu cùng tầm giá để khách chốt nhanh"),
        (["tivi", "tu lanh", "may giat", "may lanh", "gia dung", "loc nuoc"], "tư vấn gói trả chậm 0% + ưu đãi lắp đặt miễn phí trong ngày để chốt đơn nhanh")
    ]

    init(soLieu: SoLieuBanTin, giong: GiongVanBanTin, bienThe: Int = 0) {
        self.s = soLieu
        self.giong = giong
        let khoa = TienIchNgay.khoa.string(from: soLieu.ngay)
        self.rng = BoSinhNgauNhien(hatGiong: "\(khoa)|\(soLieu.khung.rawValue)|\(giong.rawValue)|\(soLieu.tenDonVi)|\(bienThe)")
    }

    func viet() -> String {
        return vietTheoMauAnhChup(nhomTapTrung: [], nvTapTrung: [])
    }

    /// Viết bản tin đúng chuẩn mẫu ảnh chụp đính kèm (1..5 có đánh số, in đậm đầu mục, lọc theo chip Nhóm hàng & Nhân viên tập trung)
    func vietTheoMauAnhChup(nhomTapTrung: Set<String> = [], nvTapTrung: Set<String> = []) -> String {
        let dfNgay = DateFormatter()
        dfNgay.dateFormat = "dd/MM/yyyy"
        let ngayStr = dfNgay.string(from: s.ngay)

        let dfGio = DateFormatter()
        dfGio.dateFormat = "HH:mm"
        let gioStr = s.capNhatLuc.isEmpty ? dfGio.string(from: Date()) : s.capNhatLuc
        let donViStr = s.tenDonVi.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "ĐMX"
            : s.tenDonVi.trimmingCharacters(in: .whitespacesAndNewlines)

        let lk = s.luyKe
        let rt = s.homNay
        let dungQD = lk.targetQuyDoi > 0 || lk.doanhThuQuyDoi > 0
        let dtLK = dungQD ? lk.doanhThuQuyDoi : lk.doanhThuThuc
        let tgLK = dungQD ? lk.targetQuyDoi : lk.targetThuc
        let ptHTLK: Double = {
            if tgLK > 0 { return dtLK / tgLK * 100.0 }
            return lk.phanTramHTQDDuKienHienThi
        }()
        let dtRT = (rt.doanhThuQuyDoi > 0) ? rt.doanhThuQuyDoi : rt.doanhThuThuc

        let dsLK = dongCoTarget(s.dsLuyKe)
        let dsRT = dongCoTarget(s.dsHomNay)
        let nguonNganh = !dsLK.isEmpty ? dsLK : dsRT

        // 2) Nhóm hàng bán tốt (đạt >= 100% dự kiến hoặc có % hoàn thành cao nhất)
        let nhomTot = nguonNganh
            .sorted { $0.phanTramDuBao > $1.phanTramDuBao }
            .filter { $0.phanTramDuBao >= 95.0 || $0.phanTramHT >= 85.0 }
            .prefix(6)

        // 3) Nhóm hàng tập trung — gần đạt target (còn thiếu ít) hoặc do người dùng chọn chip
        let nhomGanDat: [DongThiDua] = {
            if !nhomTapTrung.isEmpty {
                let daChon = nguonNganh.filter { nhomTapTrung.contains($0.tenNganhHang) }
                if !daChon.isEmpty { return Array(daChon.prefix(6)) }
            }
            let gan = nguonNganh
                .filter { $0.phanTramHT < 100.0 && $0.target > $0.thucHien }
                .sorted { $0.phanTramHT > $1.phanTramHT }
            return Array(gan.prefix(5))
        }()

        // 4) Ghi nhận nhân viên bán tốt
        let dsNVLuyKe = KhoDuLieu.dungChung.duLieu(cho: s.ngay).doanhThuNhanVienLuyKe
        let dsNVRealtime = s.homNayNV
        var dongNVTot: [String] = []

        let topNVLK = dsNVLuyKe.filter { $0.doanhThuQD > 0 }.sorted { $0.doanhThuQD > $1.doanhThuQD }.prefix(4)
        for nv in topNVLK {
            let tenRutGon = rutGonHoTenNV(nv.hoTen, maNV: nv.maNV)
            let dtThuc = nv.doanhThuThuc > 0 ? " (DT thực \(Int(nv.doanhThuThuc.rounded())) tr)" : ""
            dongNVTot.append("- **\(tenRutGon)**: Doanh thu QĐ lũy kế **\(Int(nv.doanhThuQD.rounded())) triệu**\(dtThuc).")
        }

        if dongNVTot.isEmpty {
            let topNVThiDua = s.nhanVien
                .filter { $0.tongMonGiao > 0 }
                .sorted { ($0.soMonDat, $0.phanTramHTTB) > ($1.soMonDat, $1.phanTramHTTB) }
                .prefix(4)
            for nv in topNVThiDua {
                let tenRutGon = rutGonHoTenNV(nv.nhanVien.hoTen, maNV: nv.nhanVien.maNV)
                dongNVTot.append("- **\(tenRutGon)**: Hoàn thành **\(nv.soMonDat)/\(nv.tongMonGiao) môn** thi đua (TB **\(nv.phanTramHTTB.chuoiPhanTram)**).")
            }
        }

        let topNVRT = dsNVRealtime.filter { $0.doanhThuQD > 0 }.sorted { $0.doanhThuQD > $1.doanhThuQD }.prefix(2)
        for nv in topNVRT {
            let tenRutGon = rutGonHoTenNV(nv.hoTen, maNV: nv.maNV)
            dongNVTot.append("- **\(tenRutGon)** (Realtime hôm nay): **\(nv.doanhThuQD.chuoiSoGonVN) triệu** QĐ.")
        }

        var L: [String] = []
        L.append("THÔNG BÁO TÌNH HÌNH KINH DOANH ĐẾN NGÀY \(ngayStr) — \(donViStr) lúc \(gioStr)")
        L.append("")

        if giong == .cangThang {
            L.append("⚠️ Anh chị em chú ý đọc kỹ số liệu và tập trung đẩy số ngay trong ca:")
            L.append("")
        } else if giong == .thaoMai {
            L.append("🌸 Cả nhà iu ơi, mình cùng điểm qua tình hình kinh doanh của siêu thị để cùng về đích thật rực rỡ nha ♥")
            L.append("")
        }

        // Mục 1
        L.append("1) **Doanh thu hiện tại so với lũy kế / target**:")
        if s.coSoLieuLuyKe {
            L.append("- Doanh thu lũy kế: **\(Int(dtLK.rounded()).dinhDangSoVN) triệu**")
            L.append("- Target: **\(Int(tgLK.rounded()).dinhDangSoVN) triệu**")
            L.append("- % hoàn thành: **\(String(format: "%.0f%%", ptHTLK))** (Dự kiến cuối tháng: **\(lk.phanTramHTQDDuKienHienThi.chuoiPhanTram)**)")
        } else {
            L.append("- Doanh thu lũy kế: Chưa nhập ảnh Doanh thu lũy kế hôm nay")
        }
        if dtRT > 0 {
            let tgNgay = rt.targetQuyDoi > 0 ? " / target ngày **\(rt.targetQuyDoi.chuoiSoGonVN) triệu** (**\(rt.phanTramHTQDDuKienHienThi.chuoiPhanTram)**)" : ""
            L.append("- Doanh thu Realtime: **\(dtRT.chuoiSoGonVN) triệu**\(tgNgay)")
        } else {
            L.append("- Doanh thu Realtime: **0 triệu** (cần cập nhật đơn phát sinh trong ca)")
        }
        L.append("")

        // Mục 2
        L.append("2) **Nhóm hàng bán tốt** (lũy kế đến hôm qua):")
        if !nhomTot.isEmpty {
            for d in nhomTot {
                let dvt = d.loaiChiTieu == .soLuong ? "cái" : "triệu"
                L.append("- **\(d.tenNganhHang)**: lũy kế **\(d.thucHien.chuoiSoGonVN)** / target **\(d.target.chuoiSoGonVN) \(dvt)** — đạt **\(String(format: "%.0f%%", d.phanTramHT))** (dự kiến **\(String(format: "%.0f%%", d.phanTramDuBao))**)")
            }
        } else if !nguonNganh.isEmpty {
            for d in nguonNganh.sorted(by: { $0.phanTramHT > $1.phanTramHT }).prefix(4) {
                L.append("- **\(d.tenNganhHang)**: thực hiện **\(d.thucHien.chuoiSoGonVN)** / target **\(d.target.chuoiSoGonVN)** (**\(String(format: "%.0f%%", d.phanTramHT))**)")
            }
        } else {
            L.append("- Chưa có dữ liệu bảng ngành hàng thi đua. Vui lòng vào mục **Nhập số** để quét ảnh.")
        }
        L.append("")

        // Mục 3
        L.append("3) **Nhóm hàng tập trung — gần đạt target** (còn thiếu ít):")
        if !nhomGanDat.isEmpty {
            for d in nhomGanDat {
                let thieu = max(0, d.target - d.thucHien)
                L.append("- **\(d.tenNganhHang)**: đạt **\(String(format: "%.0f%%", d.phanTramHT))** (\(d.thucHien.chuoiSoGonVN)/\(d.target.chuoiSoGonVN)), chỉ còn thiếu **\(thieu.chuoiSoGonVN)** để cán mốc 100%")
            }
        } else {
            L.append("- Các nhóm ngành trọng tâm đang bám sát tiến độ, tiếp tục duy trì tư vấn combo phụ kiện, trả chậm và bảo hiểm.")
        }
        L.append("")

        // Mục 4
        L.append("4) **Ghi nhận nhân viên bán tốt**:")
        if !dongNVTot.isEmpty {
            L.append(contentsOf: dongNVTot)
        } else {
            L.append("- Ghi nhận tinh thần chủ động đón khách và tư vấn nhiệt tình của tập thể nhân viên trong ca.")
        }
        L.append("")

        // Mục 5
        L.append("5) **Trọng tâm tập trung trong ca**:")
        if !nhomTapTrung.isEmpty {
            for tenNhom in nhomTapTrung.sorted() {
                let goiY = vietHoaDau(hanhDong(cho: tenNhom))
                L.append("- Tập trung đẩy **\(tenNhom)**: \(goiY).")
            }
        } else if let dau = nhomGanDat.first {
            L.append("- Ưu tiên chốt dứt điểm các nhóm sát đích (**\(dau.tenNganhHang)**): \(hanhDong(cho: dau.tenNganhHang)).")
        }

        if !nvTapTrung.isEmpty {
            let dsTen = nvTapTrung.sorted().joined(separator: ", ")
            L.append("- Nhân sự trọng tâm cần bứt tốc trong ca: **\(dsTen)** — chủ động bám sát mục tiêu cá nhân và báo đơn ngay khi phát sinh.")
        } else {
            let nvCanHoTro = s.nhanVien
                .filter { $0.tongMonGiao > 0 && $0.phanTramHTTB < 90 }
                .sorted { $0.phanTramHTTB < $1.phanTramHTTB }
                .prefix(3)
            if !nvCanHoTro.isEmpty {
                let dsTen = nvCanHoTro.map { ten($0.nhanVien.hoTen) }.joined(separator: ", ")
                L.append("- Nhắc nhở các bạn **\(dsTen)** tập trung khai thác các môn còn 0 và tận dụng tối đa lượt khách vào quầy.")
            }
        }

        switch giong {
        case .cangThang:
            L.append("- Yêu cầu 100% nhân sự bám sát chỉ tiêu, không để môn thi đua bằng 0, cuối ca Quản lý rà soát trực tiếp từng bạn!")
        case .thaoMai:
            L.append("- Cả nhà mình cùng cố gắng thêm một chút nữa để chiều tối nay bảng số xanh mướt hết nha, yêu cả nhà nhiều ♥")
        case .binhThuong:
            L.append("- Toàn siêu thị chủ động đón khách trong 5 giây, tư vấn kèm Phụ kiện + Sim + Bảo hiểm để hoàn thành vượt mức Target hôm nay!")
        }

        return L.joined(separator: "\n")
    }

    private func rutGonHoTenNV(_ hoTen: String, maNV: String) -> String {
        let sach = hoTen.trimmingCharacters(in: .whitespacesAndNewlines)
        if maNV.isEmpty || sach.contains(maNV) {
            return sach
        }
        return "\(maNV) - \(sach)"
    }

    /// Tạo nội dung phân tích tương ứng cho từng nút trong mục "3. Xuất ảnh"
    static func taoNoiDungBaoCao(loai: LoaiBaoCaoXuatAnh, ngay: Date, giong: GiongVanBanTin = .binhThuong) -> String {
        let dl = KhoDuLieu.dungChung.duLieu(cho: ngay)
        let s = KhoDuLieu.dungChung.taoSoLieuBanTin(cho: ngay, khung: KhungBanTin.theoGio())
        let ngayStr = TienIchNgay.hienThiNgay.string(from: ngay)
        let donVi = dl.thongTinDonVi.isEmpty ? "Siêu thị ĐMX" : dl.thongTinDonVi

        switch loai {
        case .doanhThuThiDuaLuyKe:
            return BoVietBanTin(soLieu: s, giong: giong).vietTheoMauAnhChup()

        case .luyKeDuKien:
            let dt = dl.doanhThu
            let ds = dl.danhSachThiDua.filter { $0.target > 0 }
            let dat = ds.filter { $0.phanTramDuBao >= 100 }.sorted { $0.phanTramDuBao > $1.phanTramDuBao }
            let gan = ds.filter { $0.phanTramDuBao >= 85 && $0.phanTramDuBao < 100 }.sorted { $0.phanTramDuBao > $1.phanTramDuBao }
            let yeu = ds.filter { $0.phanTramDuBao < 85 }.sorted { $0.phanTramDuBao < $1.phanTramDuBao }

            var L: [String] = [
                "📈 BÁO CÁO LŨY KẾ & % DỰ KIẾN CUỐI THÁNG — \(donVi) (\(ngayStr))",
                "",
                "1) Tổng quan Doanh thu Lũy kế:",
                "• Doanh thu Thực: \(dt.doanhThuThuc.chuoiSoGonVN) / Target \(dt.targetThuc.chuoiSoGonVN) triệu",
                "• Doanh thu Quy đổi: \(dt.doanhThuQuyDoi.chuoiSoGonVN) / Target \(dt.targetQuyDoi.chuoiSoGonVN) triệu",
                "• Dự kiến hoàn thành cuối tháng: \(dt.phanTramHTQDDuKienHienThi.chuoiPhanTram) (Số ngành đạt dự kiến: \(dat.count)/\(ds.count) ngành)",
                ""
            ]
            if !dat.isEmpty {
                L.append("2) Nhóm ngành vượt / đạt dự kiến tốt (>= 100%):")
                for d in dat.prefix(5) {
                    L.append("- \(d.tenNganhHang): TH \(d.thucHien.chuoiSoGonVN)/\(d.target.chuoiSoGonVN) → Dự kiến \(d.phanTramDuBao.chuoiPhanTram)")
                }
                L.append("")
            }
            if !gan.isEmpty {
                L.append("3) Nhóm ngành sát đích (85% – 99%):")
                for d in gan.prefix(5) {
                    L.append("- \(d.tenNganhHang): Dự kiến \(d.phanTramDuBao.chuoiPhanTram) (cần đẩy nhẹ mỗi ngày)")
                }
                L.append("")
            }
            if !yeu.isEmpty {
                L.append("4) Nhóm ngành cần tập trung bứt tốc (< 85%):")
                for d in yeu.prefix(5) {
                    L.append("- \(d.tenNganhHang): Dự kiến \(d.phanTramDuBao.chuoiPhanTram) (TH \(d.thucHien.chuoiSoGonVN)/\(d.target.chuoiSoGonVN))")
                }
            }
            return L.joined(separator: "\n")

        case .doanhThuThiDuaRealtime:
            let rt = dl.doanhThuRealtime
            let ds = dl.danhSachThiDuaRealtime.filter { $0.target > 0 }
            let dat = ds.filter { $0.phanTramHT >= 100 }
            let coSo = ds.filter { $0.thucHien > 0 && $0.phanTramHT < 100 }.sorted { $0.phanTramHT > $1.phanTramHT }
            let bangKhong = ds.filter { $0.thucHien <= 0 }

            var L: [String] = [
                "⚡ BÁO CÁO NHANH REALTIME TRONG NGÀY — \(donVi) (\(ngayStr) \(dl.capNhatLuc))",
                "",
                "1) Doanh thu Realtime trong ngày:",
                "• Doanh thu Thực: \(rt.doanhThuThuc.chuoiSoGonVN) triệu",
                "• Doanh thu Quy đổi: \(rt.doanhThuQuyDoi.chuoiSoGonVN) / Target ngày \(rt.targetQuyDoi.chuoiSoGonVN) triệu (\(rt.phanTramHTQDDuKienHienThi.chuoiPhanTram))",
                "• Số ngành đạt target ngày: \(dat.count)/\(ds.count) ngành",
                ""
            ]
            if !dat.isEmpty {
                L.append("2) Ngành hàng đã hoàn thành target ngày:")
                for d in dat.prefix(5) {
                    L.append("- \(d.tenNganhHang): \(d.thucHien.chuoiSoGonVN)/\(d.target.chuoiSoGonVN) (\(d.phanTramHT.chuoiPhanTram))")
                }
                L.append("")
            }
            if !coSo.isEmpty {
                L.append("3) Ngành hàng đang chạy số — cần chốt thêm:")
                for d in coSo.prefix(5) {
                    let thieu = max(0, d.target - d.thucHien)
                    L.append("- \(d.tenNganhHang): \(d.thucHien.chuoiSoGonVN)/\(d.target.chuoiSoGonVN) (\(d.phanTramHT.chuoiPhanTram)) — còn thiếu \(thieu.chuoiSoGonVN)")
                }
                L.append("")
            }
            if !bangKhong.isEmpty {
                L.append("4) Ngành hàng đang bằng 0 (ưu tiên mở điểm ngay trong ca):")
                L.append("- " + bangKhong.prefix(8).map(\.tenNganhHang).joined(separator: ", "))
            }
            return L.joined(separator: "\n")

        case .xepHangNVLuyKe, .xepHangNVRealtime:
            let cheDo: LoaiCheDoDoanhThu = (loai == .xepHangNVLuyKe) ? .luyKe : .realtime
            let dsNV = KhoDuLieu.dungChung.tongHopNhanVien(den: ngay, sapXep: .soMonHoanThanh, cheDo: cheDo)
            let dsDT = dl.doanhThuNhanVien(theo: cheDo).sorted { $0.doanhThuQD > $1.doanhThuQD }

            var L: [String] = [
                "👥 BẢNG XẾP HẠNG NHÂN VIÊN (\(cheDo.tieuDe.uppercased())) — \(donVi) (\(ngayStr))",
                ""
            ]
            if !dsDT.isEmpty {
                L.append("1) Top Doanh thu Quy đổi (\(cheDo.tieuDe)):")
                for (i, nv) in dsDT.prefix(6).enumerated() {
                    L.append("  \(i + 1). \(nv.hoTen): \(nv.doanhThuQD.chuoiSoGonVN) triệu QĐ (Thực: \(nv.doanhThuThuc.chuoiSoGonVN) tr • QĐ: \(nv.hieuQuaQD.chuoiPhanTram))")
                }
                L.append("")
            }
            if !dsNV.isEmpty {
                L.append("2) Xếp hạng hoàn thành môn Thi đua (\(cheDo.tieuDe)):")
                for (i, nv) in dsNV.prefix(6).enumerated() {
                    L.append("  \(i + 1). \(nv.nhanVien.hoTen): \(nv.soMonDat)/\(nv.tongMonGiao) môn đạt • TB \(nv.phanTramHTTB.chuoiPhanTram)")
                }
                let yeu = dsNV.suffix(3)
                if !yeu.isEmpty {
                    L.append("")
                    L.append("3) Nhân sự cần tập trung đẩy thêm các môn còn thiếu:")
                    for nv in yeu {
                        L.append("- \(nv.nhanVien.hoTen): đạt \(nv.soMonDat)/\(nv.tongMonGiao) môn (TB \(nv.phanTramHTTB.chuoiPhanTram))")
                    }
                }
            }
            return L.joined(separator: "\n")

        case .bieuDoSucKhoeNV:
            let dsNV = KhoDuLieu.dungChung.tongHopNhanVien(den: ngay, sapXep: .soMonHoanThanh, cheDo: .luyKe)
            let topManh = dsNV.prefix(3)
            let topYeu = dsNV.sorted { $0.phanTramHTTB < $1.phanTramHTTB }.prefix(5)

            var L: [String] = [
                "❤️‍🩹 BÁO CÁO BIỂU ĐỒ SỨC KHỎE NHÂN VIÊN — \(donVi) (\(ngayStr))",
                "",
                "1) Nhân sự dẫn đầu phong trào thi đua:"
            ]
            for nv in topManh {
                L.append("- \(nv.nhanVien.hoTen): \(nv.soMonDat)/\(nv.tongMonGiao) môn đạt • TB \(nv.phanTramHTTB.chuoiPhanTram)")
            }
            L.append("")
            L.append("2) Top 5 nhân sự cần kèm cặp & hỗ trợ đẩy số ngay trong ca:")
            for nv in topYeu {
                let monKhong = nv.cacMonGiao.filter { $0.thucHien <= 0 }.count
                L.append("- \(nv.nhanVien.hoTen): TB \(nv.phanTramHTTB.chuoiPhanTram) (\(nv.soMonDat)/\(nv.tongMonGiao) môn đạt, còn \(monKhong) môn = 0)")
            }
            L.append("")
            L.append("3) Trọng tâm hành động: Quản lý ca phân công kèm cặp trực tiếp các môn = 0 trong hôm nay.")
            return L.joined(separator: "\n")

        case .bieuDoRealtimeThang:
            let dsNgay = KhoDuLieu.dungChung.danhSachRealtimeTrongThang(cho: ngay).filter(\.coDuLieu)
            let tongQD = dsNgay.map(\.doanhThuQuyDoi).reduce(0, +)
            let tongThuc = dsNgay.map(\.doanhThuThuc).reduce(0, +)
            let tbQD = dsNgay.isEmpty ? 0 : tongQD / Double(dsNgay.count)
            let caoNhat = dsNgay.max(by: { $0.doanhThuQuyDoi < $1.doanhThuQuyDoi })

            var L: [String] = [
                "📆 TỔNG HỢP BIỂU ĐỒ DOANH THU REALTIME THÁNG — \(donVi) (đến \(ngayStr))",
                "",
                "• Số ngày đã cập nhật Realtime: \(dsNgay.count) ngày",
                "• Tổng Doanh thu Thực các ngày: \(tongThuc.chuoiSoGonVN) triệu",
                "• Tổng Doanh thu Quy đổi các ngày: \(tongQD.chuoiSoGonVN) triệu (Trung bình: \(tbQD.chuoiSoGonVN) triệu/ngày)"
            ]
            if let maxD = caoNhat {
                L.append("• Ngày cao điểm nhất: Ngày \(maxD.ngayTrongThang) đạt \(maxD.doanhThuQuyDoi.chuoiSoGonVN) triệu QĐ (\(maxD.phanTramHTQuyDoi.chuoiPhanTram))")
            }
            L.append("• Cả siêu thị tiếp tục duy trì nhịp độ chốt đơn đều đặn ở tất cả các khung giờ!")
            return L.joined(separator: "\n")

        case .chiTiet16NV:
            let dsNV = KhoDuLieu.dungChung.tongHopNhanVien(den: ngay, sapXep: .soMonHoanThanh, cheDo: .luyKe)
            var L: [String] = [
                "👤 TỔNG HỢP CHI TIẾT THI ĐUA CÁ NHÂN (\(dsNV.count) NHÂN VIÊN) — \(ngayStr)",
                ""
            ]
            for (i, nv) in dsNV.enumerated() {
                let monYeu = nv.cacMonGiao.filter { $0.phanTramHT < 80 }.prefix(2).map(\.tenNganhHang).joined(separator: ", ")
                let ghiChuYeu = monYeu.isEmpty ? "Đều các môn" : "Cần đẩy: \(monYeu)"
                L.append("\(i + 1). \(nv.nhanVien.hoTen): \(nv.soMonDat)/\(nv.tongMonGiao) môn đạt (TB \(nv.phanTramHTTB.chuoiPhanTram)) — \(ghiChuYeu)")
            }
            return L.joined(separator: "\n")
        }
    }

    // MARK: Tiện ích

    private func chon(_ cacMau: [String]) -> String {
        cacMau.randomElement(using: &rng) ?? ""
    }

    private func ten(_ hoTen: String) -> String {
        hoTen.split(separator: " ").last.map { String($0) } ?? hoTen
    }

    private func vietHoaDau(_ chu: String) -> String {
        guard let dau = chu.first else { return chu }
        return String(dau).uppercased() + chu.dropFirst()
    }

    private func khongDau(_ chu: String) -> String {
        KhoDuLieu.chuanHoaKhoaSoSanh(chu).lowercased()
    }

    private func hanhDong(cho nhom: String) -> String {
        let g = " " + khongDau(nhom) + " "
        for (cacKhoa, viec) in Self.bangViec {
            for khoa in cacKhoa {
                let trung = khoa.count <= 3 ? g.contains(" " + khoa + " ") : g.contains(khoa)
                if trung { return viec }
            }
        }
        return "đưa \(nhom) vào lời chào đầu tiên với mỗi khách, mục tiêu ít nhất 1 đơn trong ca"
    }

    private func dongCoTarget(_ ds: [DongThiDua]) -> [DongThiDua] {
        ds.filter { $0.target > 0.0001 }
    }
}

// MARK: - Dịch vụ Google Gemini AI (Free-tier Flash model, tích hợp sẵn key mặc định)

final class DichVuGeminiAI {
    static let dungChung = DichVuGeminiAI()

    /// Key mặc định do người dùng cung cấp để kiểm tra và dùng thử ngay
    static let khoaMacDinh = "AIzaSyBLV7N_qUxSuiJ3B3FETmj2Ta67CKeVKWo"

    /// Danh sách các model Google Gemini miễn phí (Free-tier trong Google AI Studio)
    static let cacModelMienPhi: [(ma: String, ten: String)] = [
        ("gemini-2.5-flash", "Gemini 2.5 Flash (Miễn phí · Nhanh & Thông minh nhất)"),
        ("gemini-2.0-flash", "Gemini 2.0 Flash (Miễn phí · Ổn định, Tốc độ cao)"),
        ("gemini-2.0-flash-lite", "Gemini 2.0 Flash-Lite (Miễn phí · Siêu nhẹ, Hạn mức cao)"),
        ("gemini-1.5-flash", "Gemini 1.5 Flash (Miễn phí · Tương thích rộng)")
    ]

    private init() {}

    var apiKeyHienTai: String {
        let luu = KhoDuLieu.dungChung.caiDat.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return luu.isEmpty ? Self.khoaMacDinh : luu
    }

    var modelHienTai: String {
        let luu = KhoDuLieu.dungChung.caiDat.geminiModel.trimmingCharacters(in: .whitespacesAndNewlines)
        return luu.isEmpty ? "gemini-2.5-flash" : luu
    }

    /// Kiểm tra API Key trực tiếp với máy chủ Google Gemini (tự động thử model dự phòng miễn phí nếu model đầu bận)
    func kiemTraVaDungThuKey(
        apiKey: String? = nil,
        model: String? = nil,
        hoanTat: @escaping (Result<(modelThanhCong: String, phanHoiMau: String), Error>) -> Void
    ) {
        let key = (apiKey ?? apiKeyHienTai).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            let err = NSError(domain: "GeminiAI", code: 400, userInfo: [NSLocalizedDescriptionKey: "Vui lòng nhập Google Gemini API Key."])
            DispatchQueue.main.async { hoanTat(.failure(err)) }
            return
        }

        let modelUuTien = (model ?? modelHienTai).trimmingCharacters(in: .whitespacesAndNewlines)
        var danhSachThu: [String] = [modelUuTien]
        for m in Self.cacModelMienPhi.map(\.ma) where !danhSachThu.contains(m) {
            danhSachThu.append(m)
        }

        let cauLenhThu = "Bạn là trợ lý phân tích kinh doanh Điện Máy Xanh. Hãy trả lời ngắn gọn 1 câu tiếng Việt xác nhận kết nối API Gemini thành công và sẵn sàng tạo báo cáo."
        goiTiepModel(danhSachModel: danhSachThu, chiSo: 0, apiKey: key, prompt: cauLenhThu) { kq in
            DispatchQueue.main.async {
                switch kq {
                case .success(let (modelOK, text)):
                    hoanTat(.success((modelOK, text)))
                case .failure(let loi):
                    hoanTat(.failure(loi))
                }
            }
        }
    }

    /// Gọi Google Gemini AI để phân tích dữ liệu thật của siêu thị và sinh báo cáo theo đúng mẫu ảnh chụp
    func phanTichBaoCao(
        soLieu: SoLieuBanTin,
        giong: GiongVanBanTin,
        nhomTapTrung: Set<String> = [],
        nvTapTrung: Set<String> = [],
        loaiBaoCao: LoaiBaoCaoXuatAnh? = nil,
        hoanTat: @escaping (Result<String, Error>) -> Void
    ) {
        let key = apiKeyHienTai
        let modelUuTien = modelHienTai
        var danhSachThu: [String] = [modelUuTien]
        for m in Self.cacModelMienPhi.map(\.ma) where !danhSachThu.contains(m) {
            danhSachThu.append(m)
        }

        let prompt = taoPromptPhanTich(
            soLieu: soLieu,
            giong: giong,
            nhomTapTrung: nhomTapTrung,
            nvTapTrung: nvTapTrung,
            loaiBaoCao: loaiBaoCao
        )

        goiTiepModel(danhSachModel: danhSachThu, chiSo: 0, apiKey: key, prompt: prompt) { kq in
            DispatchQueue.main.async {
                switch kq {
                case .success(let (_, vanBan)):
                    hoanTat(.success(vanBan))
                case .failure(let loi):
                    hoanTat(.failure(loi))
                }
            }
        }
    }

    private func taoPromptPhanTich(
        soLieu: SoLieuBanTin,
        giong: GiongVanBanTin,
        nhomTapTrung: Set<String>,
        nvTapTrung: Set<String>,
        loaiBaoCao: LoaiBaoCaoXuatAnh?
    ) -> String {
        let banMau = BoVietBanTin(soLieu: soLieu, giong: giong).vietTheoMauAnhChup(
            nhomTapTrung: nhomTapTrung,
            nvTapTrung: nvTapTrung
        )
        let moTaGiong: String
        switch giong {
        case .binhThuong:
            moTaGiong = "Chuyên nghiệp, rõ ràng, khích lệ tinh thần đội ngũ siêu thị."
        case .cangThang:
            moTaGiong = "Quyết liệt, thẳng thắn, tập trung đốc thúc tiến độ và yêu cầu cam kết hành động."
        case .thaoMai:
            moTaGiong = "Thân thiện, ngọt ngào, truyền cảm hứng tích cực nhưng vẫn bám sát con số mục tiêu."
        }

        let yeuCauRieng: String
        if let loai = loaiBaoCao {
            let tomTatRieng = BoVietBanTin.taoNoiDungBaoCao(loai: loai, ngay: soLieu.ngay, giong: giong)
            yeuCauRieng = "\nBỐI CẢNH XUẤT ẢNH: Người dùng đang chọn xuất ảnh \"\(loai.tieuDeNgan)\".\nDữ liệu chi tiết của phần này:\n\(tomTatRieng)\n"
        } else {
            yeuCauRieng = ""
        }

        return [
            "Bạn là Quản lý Siêu thị Điện Máy Xanh chuyên phân tích số liệu thi đua kinh doanh để gửi lên nhóm LINE.",
            "Hãy dựa trên số liệu thực tế dưới đây để viết một bản thông báo tình hình kinh doanh súc tích, chính xác tuyệt đối về con số, có đánh số 1) 2) 3) 4) 5) và giữ định dạng **in đậm** cho các chỉ số quan trọng giống hệt cấu trúc mẫu.",
            "Giọng văn yêu cầu: \(moTaGiong)",
            yeuCauRieng,
            "DỮ LIỆU & BẢN MẪU CHUẨN CỦA SIÊU THỊ:",
            banMau,
            "",
            "Chỉ trả về nội dung bài báo cáo hoàn chỉnh để copy gửi LINE (không thêm lời giải thích mở đầu hay kết thúc ngoài bản tin)."
        ].joined(separator: "\n")
    }

    private func goiTiepModel(
        danhSachModel: [String],
        chiSo: Int,
        apiKey: String,
        prompt: String,
        hoanTat: @escaping (Result<(String, String), Error>) -> Void
    ) {
        guard chiSo < danhSachModel.count else {
            let err = NSError(
                domain: "GeminiAI",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Không thể kết nối tới các model Gemini miễn phí. Vui lòng kiểm tra lại kết nối mạng hoặc API Key."]
            )
            hoanTat(.failure(err))
            return
        }

        let model = danhSachModel[chiSo]
        let urlStr = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlStr) else {
            goiTiepModel(danhSachModel: danhSachModel, chiSo: chiSo + 1, apiKey: apiKey, prompt: prompt, hoanTat: hoanTat)
            return
        }

        var req = URLRequest(url: url, timeoutInterval: 28)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.45,
                "maxOutputTokens": 2048
            ]
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            guard let self = self else { return }
            if let error = error {
                if chiSo + 1 < danhSachModel.count {
                    self.goiTiepModel(danhSachModel: danhSachModel, chiSo: chiSo + 1, apiKey: apiKey, prompt: prompt, hoanTat: hoanTat)
                } else {
                    hoanTat(.failure(error))
                }
                return
            }

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard let data = data else {
                self.goiTiepModel(danhSachModel: danhSachModel, chiSo: chiSo + 1, apiKey: apiKey, prompt: prompt, hoanTat: hoanTat)
                return
            }

            if statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let first = candidates.first,
               let content = first["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]] {
                let gopText = parts.compactMap { $0["text"] as? String }.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                if !gopText.isEmpty {
                    hoanTat(.success((model, gopText)))
                    return
                }
            }

            // Nếu lỗi 404 / 429 / 503 trên model hiện tại, thử sang model miễn phí kế tiếp
            if (statusCode == 404 || statusCode == 429 || statusCode == 503) && (chiSo + 1 < danhSachModel.count) {
                self.goiTiepModel(danhSachModel: danhSachModel, chiSo: chiSo + 1, apiKey: apiKey, prompt: prompt, hoanTat: hoanTat)
                return
            }

            var thongDiepLoi = "Mã phản hồi HTTP \(statusCode)"
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errObj = json["error"] as? [String: Any],
               let msg = errObj["message"] as? String {
                thongDiepLoi = msg
            }
            let err = NSError(domain: "GeminiAI", code: statusCode, userInfo: [NSLocalizedDescriptionKey: thongDiepLoi])
            hoanTat(.failure(err))
        }.resume()
    }
}

// MARK: - Bộ tạo gói ZIP (Store mode + CRC32 chuẩn) & Xuất file Excel (.xlsx) / PowerPoint (.pptx) thật

enum BoXuatOfficeDMX {

    /// Tạo file Excel (.xlsx) chuẩn OpenXML gồm 4 Sheet: Tổng quan & Phân tích, Thi đua Lũy kế, Thi đua Realtime, Nhân viên
    static func xuatFileExcelXLSX(ngay: Date, noiDungPhanTich: String) -> URL? {
        let dl = KhoDuLieu.dungChung.duLieu(cho: ngay)
        let ngayStr = TienIchNgay.hienThiNgay.string(from: ngay)
        let donVi = dl.thongTinDonVi.isEmpty ? "Siêu thị ĐMX" : dl.thongTinDonVi

        // Sheet 1: Tổng quan & Phân tích AI
        var dongSheet1: [[String]] = [
            ["BÁO CÁO TỔNG HỢP KINH DOANH & THI ĐUA — \(donVi)"],
            ["Ngày báo cáo", ngayStr, "Cập nhật lúc", dl.capNhatLuc],
            [],
            ["CHỈ SỐ DOANH THU", "DOANH THU THỰC", "TARGET THỰC", "DOANH THU QUY ĐỔI", "TARGET QUY ĐỔI", "% HT DỰ KIẾN", "LƯỢT KHÁCH"],
            [
                "Lũy kế tháng",
                dl.doanhThu.doanhThuThuc.chuoiSoGonVN,
                dl.doanhThu.targetThuc.chuoiSoGonVN,
                dl.doanhThu.doanhThuQuyDoi.chuoiSoGonVN,
                dl.doanhThu.targetQuyDoi.chuoiSoGonVN,
                dl.doanhThu.phanTramHTQDDuKienHienThi.chuoiPhanTram,
                String(Int(dl.doanhThu.luotKhach))
            ],
            [
                "Realtime hôm nay",
                dl.doanhThuRealtime.doanhThuThuc.chuoiSoGonVN,
                dl.doanhThuRealtime.targetThuc.chuoiSoGonVN,
                dl.doanhThuRealtime.doanhThuQuyDoi.chuoiSoGonVN,
                dl.doanhThuRealtime.targetQuyDoi.chuoiSoGonVN,
                dl.doanhThuRealtime.phanTramHTQDDuKienHienThi.chuoiPhanTram,
                String(Int(dl.doanhThuRealtime.luotKhach))
            ],
            [],
            ["NỘI DUNG BẢN TIN PHÂN TÍCH (AI GEMINI / MẪU BÁO CÁO):"]
        ]
        for dong in noiDungPhanTich.components(separatedBy: .newlines) {
            dongSheet1.append([dong])
        }

        // Sheet 2: Thi đua Lũy kế
        var dongSheet2: [[String]] = [
            ["BẢNG THI ĐUA NGÀNH HÀNG — LŨY KẾ (\(ngayStr))"],
            ["STT", "Ngành hàng", "ĐVT", "Thực hiện", "Target", "Còn thiếu", "% Hoàn thành", "Dự kiến cuối tháng", "% Dự kiến"]
        ]
        for (i, d) in dl.danhSachThiDua.enumerated() {
            let thieu = max(0, d.target - d.thucHien)
            dongSheet2.append([
                String(i + 1),
                d.tenNganhHang,
                d.loaiChiTieu.maBang,
                d.thucHien.chuoiSoGonVN,
                d.target.chuoiSoGonVN,
                thieu.chuoiSoGonVN,
                d.phanTramHT.chuoiPhanTram,
                d.duKienCuoiThang.chuoiSoGonVN,
                d.phanTramDuBao.chuoiPhanTram
            ])
        }

        // Sheet 3: Thi đua Realtime
        var dongSheet3: [[String]] = [
            ["BẢNG THI ĐUA NGÀNH HÀNG — REALTIME (\(ngayStr))"],
            ["STT", "Ngành hàng", "ĐVT", "Thực hiện hôm nay", "Target ngày", "Còn thiếu", "% Hoàn thành"]
        ]
        for (i, d) in dl.danhSachThiDuaRealtime.enumerated() {
            let thieu = max(0, d.target - d.thucHien)
            dongSheet3.append([
                String(i + 1),
                d.tenNganhHang,
                d.loaiChiTieu.maBang,
                d.thucHien.chuoiSoGonVN,
                d.target.chuoiSoGonVN,
                thieu.chuoiSoGonVN,
                d.phanTramHT.chuoiPhanTram
            ])
        }

        // Sheet 4: Xếp hạng Nhân viên
        let dsNV = KhoDuLieu.dungChung.tongHopNhanVien(den: ngay, sapXep: .soMonHoanThanh, cheDo: .luyKe)
        let mapDTLK = Dictionary(uniqueKeysWithValues: dl.doanhThuNhanVienLuyKe.map { (KhoDuLieu.chuanHoaMaNV($0.maNV), $0) })
        let mapDTRT = Dictionary(uniqueKeysWithValues: dl.doanhThuNhanVienRealtime.map { (KhoDuLieu.chuanHoaMaNV($0.maNV), $0) })
        var dongSheet4: [[String]] = [
            ["BẢNG XẾP HẠNG NHÂN VIÊN (\(ngayStr))"],
            ["Hạng", "Mã NV", "Họ tên Nhân viên", "Số môn Đạt", "Tổng môn Giao", "% HT Trung bình", "DT Thực Lũy kế", "DT QĐ Lũy kế", "DT QĐ Realtime"]
        ]
        for (i, nv) in dsNV.enumerated() {
            let ma = KhoDuLieu.chuanHoaMaNV(nv.nhanVien.maNV)
            let dtLK = mapDTLK[ma]
            let dtRT = mapDTRT[ma]
            dongSheet4.append([
                String(i + 1),
                nv.nhanVien.maNV,
                nv.nhanVien.hoTen,
                String(nv.soMonDat),
                String(nv.tongMonGiao),
                nv.phanTramHTTB.chuoiPhanTram,
                dtLK.map { $0.doanhThuThuc.chuoiSoGonVN } ?? "0",
                dtLK.map { $0.doanhThuQD.chuoiSoGonVN } ?? "0",
                dtRT.map { $0.doanhThuQD.chuoiSoGonVN } ?? "0"
            ])
        }

        let contentTypes = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
            "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">",
            "<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>",
            "<Default Extension=\"xml\" ContentType=\"application/xml\"/>",
            "<Override PartName=\"/xl/workbook.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/>",
            "<Override PartName=\"/xl/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml\"/>",
            "<Override PartName=\"/xl/worksheets/sheet1.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>",
            "<Override PartName=\"/xl/worksheets/sheet2.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>",
            "<Override PartName=\"/xl/worksheets/sheet3.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>",
            "<Override PartName=\"/xl/worksheets/sheet4.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>",
            "</Types>"
        ].joined(separator: "\n")

        let relsRoot = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
            "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">",
            "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"xl/workbook.xml\"/>",
            "</Relationships>"
        ].joined(separator: "\n")

        let workbookXML = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
            "<workbook xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\">",
            "<sheets>",
            "<sheet name=\"1_TongQuan_PhanTich\" sheetId=\"1\" r:id=\"rId1\"/>",
            "<sheet name=\"2_ThiDua_LuyKe\" sheetId=\"2\" r:id=\"rId2\"/>",
            "<sheet name=\"3_ThiDua_Realtime\" sheetId=\"3\" r:id=\"rId3\"/>",
            "<sheet name=\"4_XepHang_NhanVien\" sheetId=\"4\" r:id=\"rId4\"/>",
            "</sheets>",
            "</workbook>"
        ].joined(separator: "\n")

        let workbookRels = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
            "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">",
            "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet1.xml\"/>",
            "<Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet2.xml\"/>",
            "<Relationship Id=\"rId3\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet3.xml\"/>",
            "<Relationship Id=\"rId4\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet4.xml\"/>",
            "<Relationship Id=\"rId5\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\" Target=\"styles.xml\"/>",
            "</Relationships>"
        ].joined(separator: "\n")

        let stylesXML = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
            "<styleSheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">",
            "<fonts count=\"2\">",
            "<font><sz val=\"11\"/><name val=\"Arial\"/></font>",
            "<font><b/><sz val=\"11\"/><name val=\"Arial\"/></font>",
            "</fonts>",
            "<fills count=\"2\"><fill><patternFill patternType=\"none\"/></fill><fill><patternFill patternType=\"gray125\"/></fill></fills>",
            "<borders count=\"1\"><border><left/><right/><top/><bottom/><diagonal/></border></borders>",
            "<cellStyleXfs count=\"1\"><xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\"/></cellStyleXfs>",
            "<cellXfs count=\"2\">",
            "<xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\" xfId=\"0\"/>",
            "<xf numFmtId=\"0\" fontId=\"1\" fillId=\"0\" borderId=\"0\" xfId=\"0\" applyFont=\"1\"/>",
            "</cellXfs>",
            "</styleSheet>"
        ].joined(separator: "\n")

        let cacTep: [(String, Data)] = [
            ("[Content_Types].xml", Data(contentTypes.utf8)),
            ("_rels/.rels", Data(relsRoot.utf8)),
            ("xl/workbook.xml", Data(workbookXML.utf8)),
            ("xl/_rels/workbook.xml.rels", Data(workbookRels.utf8)),
            ("xl/styles.xml", Data(stylesXML.utf8)),
            ("xl/worksheets/sheet1.xml", Data(taoSheetXML(dongSheet1).utf8)),
            ("xl/worksheets/sheet2.xml", Data(taoSheetXML(dongSheet2).utf8)),
            ("xl/worksheets/sheet3.xml", Data(taoSheetXML(dongSheet3).utf8)),
            ("xl/worksheets/sheet4.xml", Data(taoSheetXML(dongSheet4).utf8))
        ]

        let duLieuZip = dongGoiZipStore(cacTep: cacTep)
        let tenTep = "BaoCao-DMX-\(dl.khoaNgay).xlsx"
        let duongDan = FileManager.default.temporaryDirectory.appendingPathComponent(tenTep)
        do {
            try duLieuZip.write(to: duongDan, options: .atomic)
            return duongDan
        } catch {
            return nil
        }
    }

    /// Tạo file PowerPoint (.pptx) chuẩn OpenXML gồm 4 Slide báo cáo tổng hợp
    static func xuatFilePowerPointPPTX(ngay: Date, noiDungPhanTich: String) -> URL? {
        let dl = KhoDuLieu.dungChung.duLieu(cho: ngay)
        let ngayStr = TienIchNgay.hienThiNgay.string(from: ngay)
        let donVi = dl.thongTinDonVi.isEmpty ? "Siêu thị ĐMX" : dl.thongTinDonVi

        // Slide 1: Tóm tắt & Bản tin phân tích
        let cacDongPhanTich = noiDungPhanTich
            .replacingOccurrences(of: "**", with: "")
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .prefix(16)
        let slide1Lines = ["BÁO CÁO KINH DOANH — \(donVi) (\(ngayStr))"] + Array(cacDongPhanTich)

        // Slide 2: Thi đua Lũy kế
        var slide2Lines: [String] = [
            "THI ĐUA NGÀNH HÀNG — LŨY KẾ (\(ngayStr))",
            "Doanh thu Thực: \(dl.doanhThu.doanhThuThuc.chuoiSoGonVN) tr | Doanh thu QĐ: \(dl.doanhThu.doanhThuQuyDoi.chuoiSoGonVN) tr | Dự kiến: \(dl.doanhThu.phanTramHTQDDuKienHienThi.chuoiPhanTram)"
        ]
        for (i, d) in dl.danhSachThiDua.prefix(14).enumerated() {
            slide2Lines.append("\(i + 1). \(d.tenNganhHang): TH \(d.thucHien.chuoiSoGonVN) / Target \(d.target.chuoiSoGonVN) — HT \(d.phanTramHT.chuoiPhanTram) (Dự kiến \(d.phanTramDuBao.chuoiPhanTram))")
        }

        // Slide 3: Thi đua Realtime
        var slide3Lines: [String] = [
            "THI ĐUA NGÀNH HÀNG — REALTIME TRONG NGÀY (\(ngayStr))",
            "Doanh thu Thực: \(dl.doanhThuRealtime.doanhThuThuc.chuoiSoGonVN) tr | Doanh thu QĐ: \(dl.doanhThuRealtime.doanhThuQuyDoi.chuoiSoGonVN) tr (\(dl.doanhThuRealtime.phanTramHTQDDuKienHienThi.chuoiPhanTram))"
        ]
        for (i, d) in dl.danhSachThiDuaRealtime.prefix(14).enumerated() {
            slide3Lines.append("\(i + 1). \(d.tenNganhHang): TH \(d.thucHien.chuoiSoGonVN) / Target \(d.target.chuoiSoGonVN) — HT \(d.phanTramHT.chuoiPhanTram)")
        }

        // Slide 4: Xếp hạng Nhân viên
        let dsNV = KhoDuLieu.dungChung.tongHopNhanVien(den: ngay, sapXep: .soMonHoanThanh, cheDo: .luyKe)
        var slide4Lines: [String] = [
            "BẢNG XẾP HẠNG NHÂN VIÊN — LŨY KẾ (\(ngayStr))"
        ]
        for (i, nv) in dsNV.prefix(15).enumerated() {
            slide4Lines.append("Hạng \(i + 1). \(nv.nhanVien.hoTen) (\(nv.nhanVien.maNV)): Đạt \(nv.soMonDat)/\(nv.tongMonGiao) môn • Hoàn thành TB \(nv.phanTramHTTB.chuoiPhanTram)")
        }

        let contentTypes = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
            "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">",
            "<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>",
            "<Default Extension=\"xml\" ContentType=\"application/xml\"/>",
            "<Override PartName=\"/ppt/presentation.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml\"/>",
            "<Override PartName=\"/ppt/slideMasters/slideMaster1.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml\"/>",
            "<Override PartName=\"/ppt/slideLayouts/slideLayout1.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml\"/>",
            "<Override PartName=\"/ppt/slides/slide1.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.presentationml.slide+xml\"/>",
            "<Override PartName=\"/ppt/slides/slide2.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.presentationml.slide+xml\"/>",
            "<Override PartName=\"/ppt/slides/slide3.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.presentationml.slide+xml\"/>",
            "<Override PartName=\"/ppt/slides/slide4.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.presentationml.slide+xml\"/>",
            "</Types>"
        ].joined(separator: "\n")

        let relsRoot = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
            "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">",
            "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"ppt/presentation.xml\"/>",
            "</Relationships>"
        ].joined(separator: "\n")

        let presentationXML = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
            "<p:presentation xmlns:a=\"http://schemas.openxmlformats.org/drawingml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\" xmlns:p=\"http://schemas.openxmlformats.org/presentationml/2006/main\">",
            "<p:sldMasterIdLst><p:sldMasterId id=\"2147483648\" r:id=\"rId1\"/></p:sldMasterIdLst>",
            "<p:sldIdLst>",
            "<p:sldId id=\"256\" r:id=\"rId2\"/>",
            "<p:sldId id=\"257\" r:id=\"rId3\"/>",
            "<p:sldId id=\"258\" r:id=\"rId4\"/>",
            "<p:sldId id=\"259\" r:id=\"rId5\"/>",
            "</p:sldIdLst>",
            "<p:sldSz cx=\"12192000\" cy=\"6858000\"/>",
            "<p:notesSz cx=\"6858000\" cy=\"9144000\"/>",
            "</p:presentation>"
        ].joined(separator: "\n")

        let presentationRels = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
            "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">",
            "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster\" Target=\"slideMasters/slideMaster1.xml\"/>",
            "<Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide\" Target=\"slides/slide1.xml\"/>",
            "<Relationship Id=\"rId3\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide\" Target=\"slides/slide2.xml\"/>",
            "<Relationship Id=\"rId4\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide\" Target=\"slides/slide3.xml\"/>",
            "<Relationship Id=\"rId5\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide\" Target=\"slides/slide4.xml\"/>",
            "</Relationships>"
        ].joined(separator: "\n")

        let slideMasterXML = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
            "<p:sldMaster xmlns:a=\"http://schemas.openxmlformats.org/drawingml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\" xmlns:p=\"http://schemas.openxmlformats.org/presentationml/2006/main\">",
            "<p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id=\"1\" name=\"\"/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld>",
            "<p:clrMap bg1=\"lt1\" tx1=\"dk1\" bg2=\"lt2\" tx2=\"dk2\" accent1=\"accent1\" accent2=\"accent2\" accent3=\"accent3\" accent4=\"accent4\" accent5=\"accent5\" accent6=\"accent6\" hlink=\"hlink\" folHlink=\"folHlink\"/>",
            "<p:sldLayoutIdLst><p:sldLayoutId id=\"2147483649\" r:id=\"rId1\"/></p:sldLayoutIdLst>",
            "</p:sldMaster>"
        ].joined(separator: "\n")

        let slideMasterRels = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
            "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">",
            "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout\" Target=\"../slideLayouts/slideLayout1.xml\"/>",
            "</Relationships>"
        ].joined(separator: "\n")

        let slideLayoutXML = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
            "<p:sldLayout xmlns:a=\"http://schemas.openxmlformats.org/drawingml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\" xmlns:p=\"http://schemas.openxmlformats.org/presentationml/2006/main\" type=\"blank\">",
            "<p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id=\"1\" name=\"\"/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld>",
            "</p:sldLayout>"
        ].joined(separator: "\n")

        let slideLayoutRels = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
            "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">",
            "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster\" Target=\"../slideMasters/slideMaster1.xml\"/>",
            "</Relationships>"
        ].joined(separator: "\n")

        let slideRels = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
            "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">",
            "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout\" Target=\"../slideLayouts/slideLayout1.xml\"/>",
            "</Relationships>"
        ].joined(separator: "\n")

        let cacTep: [(String, Data)] = [
            ("[Content_Types].xml", Data(contentTypes.utf8)),
            ("_rels/.rels", Data(relsRoot.utf8)),
            ("ppt/presentation.xml", Data(presentationXML.utf8)),
            ("ppt/_rels/presentation.xml.rels", Data(presentationRels.utf8)),
            ("ppt/slideMasters/slideMaster1.xml", Data(slideMasterXML.utf8)),
            ("ppt/slideMasters/_rels/slideMaster1.xml.rels", Data(slideMasterRels.utf8)),
            ("ppt/slideLayouts/slideLayout1.xml", Data(slideLayoutXML.utf8)),
            ("ppt/slideLayouts/_rels/slideLayout1.xml.rels", Data(slideLayoutRels.utf8)),
            ("ppt/slides/slide1.xml", Data(taoSlideXML(cacDong: slide1Lines).utf8)),
            ("ppt/slides/_rels/slide1.xml.rels", Data(slideRels.utf8)),
            ("ppt/slides/slide2.xml", Data(taoSlideXML(cacDong: slide2Lines).utf8)),
            ("ppt/slides/_rels/slide2.xml.rels", Data(slideRels.utf8)),
            ("ppt/slides/slide3.xml", Data(taoSlideXML(cacDong: slide3Lines).utf8)),
            ("ppt/slides/_rels/slide3.xml.rels", Data(slideRels.utf8)),
            ("ppt/slides/slide4.xml", Data(taoSlideXML(cacDong: slide4Lines).utf8)),
            ("ppt/slides/_rels/slide4.xml.rels", Data(slideRels.utf8))
        ]

        let duLieuZip = dongGoiZipStore(cacTep: cacTep)
        let tenTep = "BaoCao-Slide-DMX-\(dl.khoaNgay).pptx"
        let duongDan = FileManager.default.temporaryDirectory.appendingPathComponent(tenTep)
        do {
            try duLieuZip.write(to: duongDan, options: .atomic)
            return duongDan
        } catch {
            return nil
        }
    }

    // MARK: - Helpers sinh XML cho Excel & PowerPoint

    private static func thoatXML(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private static func tenCotExcel(_ chiSo: Int) -> String {
        var n = chiSo + 1
        var ketQua = ""
        while n > 0 {
            let du = (n - 1) % 26
            ketQua = String(UnicodeScalar(65 + du)!) + ketQua
            n = (n - 1) / 26
        }
        return ketQua
    }

    private static func taoSheetXML(_ cacDong: [[String]]) -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n"
        xml += "<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\"><sheetData>"
        for (rIdx, dong) in cacDong.enumerated() {
            let soDong = rIdx + 1
            xml += "<row r=\"\(soDong)\">"
            for (cIdx, o) in dong.enumerated() {
                let ref = "\(tenCotExcel(cIdx))\(soDong)"
                let kieuInDam = (rIdx <= 1) ? " s=\"1\"" : ""
                xml += "<c r=\"\(ref)\" t=\"inlineStr\"\(kieuInDam)><is><t>\(thoatXML(o))</t></is></c>"
            }
            xml += "</row>"
        }
        xml += "</sheetData></worksheet>"
        return xml
    }

    private static func taoSlideXML(cacDong: [String]) -> String {
        var doanVan = ""
        for (idx, dong) in cacDong.enumerated() {
            let coChu = (idx == 0) ? 2400 : 1550
            let inDam = (idx == 0) ? " b=\"1\"" : ""
            let mauChu = (idx == 0) ? "1D4ED8" : "0F172A"
            doanVan += "<a:p><a:r><a:rPr lang=\"vi-VN\" sz=\"\(coChu)\"\(inDam)><a:solidFill><a:srgbClr val=\"\(mauChu)\"/></a:solidFill></a:rPr><a:t>\(thoatXML(dong))</a:t></a:r></a:p>"
        }
        return [
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
            "<p:sld xmlns:a=\"http://schemas.openxmlformats.org/drawingml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\" xmlns:p=\"http://schemas.openxmlformats.org/presentationml/2006/main\">",
            "<p:cSld><p:spTree>",
            "<p:nvGrpSpPr><p:cNvPr id=\"1\" name=\"\"/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>",
            "<p:grpSpPr><a:xfrm><a:off x=\"0\" y=\"0\"/><a:ext cx=\"0\" cy=\"0\"/><a:chOff x=\"0\" y=\"0\"/><a:chExt cx=\"0\" cy=\"0\"/></a:xfrm></p:grpSpPr>",
            "<p:sp>",
            "<p:nvSpPr><p:cNvPr id=\"2\" name=\"TextBox 1\"/><p:cNvSpPr txBox=\"1\"/><p:nvPr/></p:nvSpPr>",
            "<p:spPr><a:xfrm><a:off x=\"457200\" y=\"360000\"/><a:ext cx=\"11277600\" cy=\"6100000\"/></a:xfrm><a:prstGeom prst=\"rect\"><a:avLst/></a:prstGeom></p:spPr>",
            "<p:txBody><a:bodyPr wrap=\"square\"/><a:lstStyle/>\(doanVan)</p:txBody>",
            "</p:sp>",
            "</p:spTree></p:cSld>",
            "</p:sld>"
        ].joined(separator: "\n")
    }

    // MARK: - Bộ đóng gói ZIP (Store mode + CRC32 IEEE 802.3)

    private static let bangCRC32: [UInt32] = {
        (0..<256).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 {
                c = (c & 1 != 0) ? (0xEDB88320 ^ (c >> 1)) : (c >> 1)
            }
            return c
        }
    }()

    private static func tinhCRC32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            let idx = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = (crc >> 8) ^ bangCRC32[idx]
        }
        return crc ^ 0xFFFFFFFF
    }

    private static func ghiUInt16LE(_ v: UInt16, vao data: inout Data) {
        var le = v.littleEndian
        withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
    }

    private static func ghiUInt32LE(_ v: UInt32, vao data: inout Data) {
        var le = v.littleEndian
        withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
    }

    private static func dongGoiZipStore(cacTep: [(String, Data)]) -> Data {
        var zipData = Data()
        var centralDir = Data()

        for (ten, noiDung) in cacTep {
            let tenBytes = Data(ten.utf8)
            let crc = tinhCRC32(noiDung)
            let kichThuoc = UInt32(noiDung.count)
            let viTriOffset = UInt32(zipData.count)

            // Local file header
            ghiUInt32LE(0x04034B50, vao: &zipData)
            ghiUInt16LE(20, vao: &zipData)
            ghiUInt16LE(0, vao: &zipData)
            ghiUInt16LE(0, vao: &zipData) // 0 = Store
            ghiUInt16LE(0, vao: &zipData)
            ghiUInt16LE(0x5421, vao: &zipData)
            ghiUInt32LE(crc, vao: &zipData)
            ghiUInt32LE(kichThuoc, vao: &zipData)
            ghiUInt32LE(kichThuoc, vao: &zipData)
            ghiUInt16LE(UInt16(tenBytes.count), vao: &zipData)
            ghiUInt16LE(0, vao: &zipData)
            zipData.append(tenBytes)
            zipData.append(noiDung)

            // Central directory header
            ghiUInt32LE(0x02014B50, vao: &centralDir)
            ghiUInt16LE(20, vao: &centralDir)
            ghiUInt16LE(20, vao: &centralDir)
            ghiUInt16LE(0, vao: &centralDir)
            ghiUInt16LE(0, vao: &centralDir)
            ghiUInt16LE(0, vao: &centralDir)
            ghiUInt16LE(0x5421, vao: &centralDir)
            ghiUInt32LE(crc, vao: &centralDir)
            ghiUInt32LE(kichThuoc, vao: &centralDir)
            ghiUInt32LE(kichThuoc, vao: &centralDir)
            ghiUInt16LE(UInt16(tenBytes.count), vao: &centralDir)
            ghiUInt16LE(0, vao: &centralDir)
            ghiUInt16LE(0, vao: &centralDir)
            ghiUInt16LE(0, vao: &centralDir)
            ghiUInt16LE(0, vao: &centralDir)
            ghiUInt32LE(0, vao: &centralDir)
            ghiUInt32LE(viTriOffset, vao: &centralDir)
            centralDir.append(tenBytes)
        }

        let cdOffset = UInt32(zipData.count)
        let cdSize = UInt32(centralDir.count)
        zipData.append(centralDir)

        // End of central directory record
        ghiUInt32LE(0x06054B50, vao: &zipData)
        ghiUInt16LE(0, vao: &zipData)
        ghiUInt16LE(0, vao: &zipData)
        ghiUInt16LE(UInt16(cacTep.count), vao: &zipData)
        ghiUInt16LE(UInt16(cacTep.count), vao: &zipData)
        ghiUInt32LE(cdSize, vao: &zipData)
        ghiUInt32LE(cdOffset, vao: &zipData)
        ghiUInt16LE(0, vao: &zipData)

        return zipData
    }
}
