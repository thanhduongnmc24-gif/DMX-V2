import UIKit
import Vision
import ImageIO

struct DongThiDuaNhanVienQuet: Hashable {
    var maNV: String
    var hoTen: String
    var thucHien: Double
    var target: Double
}

struct KetQuaThiDuaNhanVienKhoi: Hashable {
    var tenNganhHang: String
    var danhSach: [DongThiDuaNhanVienQuet]
}

struct KetQuaQuetThiDua {
    var danhSach: [DongThiDua]
    var thiDuaNhanVien: [KetQuaThiDuaNhanVienKhoi]
    var doanhThuQuetDuoc: ThongTinDoanhThu?
    var capNhatLuc: String
    var thongTinDonVi: String
}

struct KetQuaQuetTatCaAnh {
    var doanhThu: ThongTinDoanhThu?
    var soAnhDoanhThu: Int = 0

    var danhSachThiDua: [DongThiDua] = []
    var soAnhThiDua: Int = 0

    var doanhThuNhanVien: [DoanhThuNhanVienItem] = []
    var soAnhDoanhThuNV: Int = 0

    var thiDuaNhanVien: [KetQuaThiDuaNhanVienKhoi] = []
    var soAnhThiDuaNV: Int = 0

    var capNhatLuc: String = ""
    var thongTinDonVi: String = ""

    var coDuLieu: Bool {
        (doanhThu?.coDuLieu ?? false) ||
        !danhSachThiDua.isEmpty ||
        !doanhThuNhanVien.isEmpty ||
        !thiDuaNhanVien.isEmpty
    }
}

final class DichVuDocAnh {
    static let dungChung = DichVuDocAnh()
    private init() {}

    private struct PhanTuVanBan {
        let chu: String
        let x: CGFloat      // 0 (trái) -> 1 (phải)
        let y: CGFloat      // 0 (đỉnh) -> 1 (đáy)
        let rong: CGFloat
        let cao: CGFloat
    }

    // MARK: - Nhận diện chính xác Ảnh chụp màn hình Doanh thu Siêu thị (tránh nhầm sang bảng Thi đua)

    /// Kiểm tra xem bức ảnh có phải là màn hình Tổng quan Doanh thu (chứa các thẻ: DT thực, DT quy đổi, % HT target, TT vs TB 3 tháng, TLPVTC, Tỷ trọng trả chậm, Chi phí) hay không.
    private func laAnhDoanhThuSieuThi(phanTu: [PhanTuVanBan]) -> Bool {
        var coDauHieuDoanhThu = 0
        for pt in phanTu where pt.y > 0.30 && pt.y < 0.96 {
            let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
            if u == "DT THUC" || u == "DT QUY DOI" || u.contains("DT QUY DOI KHOAN VAY") ||
               u.contains("TLPVTC") || u.contains("TY TRONG TRA CHAM") ||
               u.contains("TT VS TB 3 THANG") || u.contains("TB3T CUNG CUA SO") ||
               u == "CHI PHI" || u.contains("HT TARGET") ||
               u.contains("QUY THOI GIAN") || u.contains("THOI GIAN LAM VIEC") ||
               u.contains("TARGET TRON KY") || u.contains("DT TRA GOP") {
                coDauHieuDoanhThu += 1
            }
        }
        return coDauHieuDoanhThu >= 2
    }

    private func laTenTheDoanhThuKhongPhaiThiDua(_ ten: String) -> Bool {
        if KhoDuLieu.laTenDongNhanVienBiQuetNham(ten) {
            return true
        }
        let u = boDau(ten)
        let cacCumCam = [
            "DT THUC", "DT QUY DOI", "DT DU KIEN", "HT TARGET",
            "TT VS TB", "TB 3 THANG", "TLPVTC", "TY TRONG TRA CHAM",
            "CHI PHI", "QUY THOI GIAN", "THOI GIAN LAM VIEC",
            "TOAN CONG TY", "SIEU THI 76", "XUAT EXCEL", "XUAT THEO MAU",
            "NGANH HANG BI", "NHOM HANG BI", "KHOAN VAY"
        ]
        for cum in cacCumCam {
            if u.contains(cum) { return true }
        }
        return false
    }

    /// Nhận diện ảnh Bảng Doanh thu Nhân viên 5 cột (có tiêu đề hoặc đã cắt tiêu đề, có các dòng "id: <mã NV>") để tuyệt đối không bị quét nhầm sang bảng Thi Đua
    private func laAnhBangDoanhThuNhanVien(phanTu: [PhanTuVanBan]) -> Bool {
        var soDongCoId = 0
        var coHeaderNganhHangBI = false
        var coHeaderDoanhThuQD = false
        var coHeaderKhoanVay = false
        var coHeaderTiTrong = false

        for pt in phanTu {
            let chu = pt.chu
            if pt.x < 0.42 && chu.range(of: "(?i)\\b(?:id|ld|1d|ia|iđ)\\s*[:.;\\-]?\\s*\\d{3,7}", options: .regularExpression) != nil {
                soDongCoId += 1
            }
            if pt.y < 0.30 {
                let u = boDau(chu)
                if u.contains("NGANH HANG BI") || u.contains("NHOM HANG BI") {
                    coHeaderNganhHangBI = true
                }
                if u.contains("DOANH THU QD") || u.contains("THU QD") {
                    coHeaderDoanhThuQD = true
                }
                if u.contains("KHOAN VAY") {
                    coHeaderKhoanVay = true
                }
                if u.contains("TI TRONG") || u.contains("TY TRONG") {
                    coHeaderTiTrong = true
                }
            }
        }

        if soDongCoId >= 2 { return true }
        let soDauHieuHeader = [coHeaderNganhHangBI, coHeaderDoanhThuQD, coHeaderKhoanVay, coHeaderTiTrong].filter { $0 }.count
        if soDauHieuHeader >= 2 { return true }
        if soDongCoId >= 1 && soDauHieuHeader >= 1 { return true }
        return false
    }

    // MARK: - 0. Quét & Tự động phân loại TẤT CẢ các ảnh chọn cùng lúc theo Tab đang đứng (Lũy kế hoặc Realtime)

    func quetVaPhanLoaiTatCaAnh(
        danhSachAnh: [UIImage],
        ngay: Date,
        cheDoDangChon: LoaiCheDoDoanhThu,
        tienTrinh: @escaping (String) -> Void,
        hoanTat: @escaping (KetQuaQuetTatCaAnh) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            var kq = KetQuaQuetTatCaAnh()
            let laRealtime = (cheDoDangChon == .realtime)
            var dtGop = ThongTinDoanhThu()
            var cacPhanTuThiDuaDuPhong: [([PhanTuVanBan], String?)] = []

            for (chiSo, anh) in danhSachAnh.enumerated() {
                DispatchQueue.main.async {
                    tienTrinh("Đang đọc & phân loại ảnh \(chiSo + 1)/\(danhSachAnh.count)...")
                }
                let phanTu = self.thucHienOCR(anh: anh)
                guard !phanTu.isEmpty else { continue }

                let (cn, dv, wm) = self.trichThongTinChungThiDua(phanTu: phanTu)
                if kq.capNhatLuc.isEmpty, let cn = cn, !cn.isEmpty {
                    kq.capNhatLuc = cn
                }
                if kq.thongTinDonVi.isEmpty, let dv = dv, !dv.isEmpty {
                    kq.thongTinDonVi = dv
                }

                // ƯU TIÊN 1: Kiểm tra xem có phải ảnh Doanh thu Siêu thị (DT thực / DT quy đổi) không
                // Phải kiểm tra ĐẦU TIÊN để không bao giờ bị nhầm sang bảng Thi đua!
                if self.laAnhDoanhThuSieuThi(phanTu: phanTu) {
                    let dt = self.phanTichDoanhThu(phanTu: phanTu)
                    if dt.coDuLieu {
                        dtGop = dtGop.gop(voi: dt, laRealtime: laRealtime)
                        kq.soAnhDoanhThu += 1
                        continue
                    }
                }

                // ƯU TIÊN 2: Kiểm tra ảnh Bảng Thực hiện Nhân viên theo Ngành hàng
                let coCotHangTrongST = phanTu.contains { pt in
                    let u = self.boDau(pt.chu)
                    return pt.y < 0.24 && (
                        u.contains("HANG TRONG") ||
                        u.contains("TOP/BOTT") ||
                        u.contains("CON / VUOT")
                    )
                }
                if coCotHangTrongST,
                   let khoiNV = self.phanTichThiDuaNhanVienOffline(phanTu: phanTu, tenNganhGoiY: nil, watermark: wm),
                   !khoiNV.danhSach.isEmpty {
                    kq.thiDuaNhanVien.append(khoiNV)
                    kq.soAnhThiDuaNV += 1
                    continue
                }

                // ƯU TIÊN 3: Kiểm tra ảnh Bảng Doanh thu hợp nhất theo Nhân viên
                let laBangDTNV = self.laAnhBangDoanhThuNhanVien(phanTu: phanTu)
                let dsDTNV = self.phanTichDoanhThuNhanVienOffline(phanTu: phanTu, anh: anh)
                if dsDTNV.count >= 1 || laBangDTNV {
                    if !dsDTNV.isEmpty {
                        kq.doanhThuNhanVien.append(contentsOf: dsDTNV)
                        kq.soAnhDoanhThuNV += 1
                    }
                    continue
                }

                let phuongPhapThiDua = KhoDuLieu.dungChung.layCaiDatAnToan().phuongPhapQuetThiDua

                // ƯU TIÊN 4: Quét môn Thi Đua theo Phương pháp đã chọn trong Cài đặt (kèm tự động nhận diện bảng 6 cột mới)
                if phuongPhapThiDua == .phuongPhap2 || self.laAnhBangThiDua6Cot(phanTu: phanTu) {
                    let dsBang6Cot = self.phanTichBangThiDuaPhuongPhap2_6Cot(phanTu: phanTu, anh: anh, watermark: wm)
                    if !dsBang6Cot.isEmpty {
                        kq.danhSachThiDua = KhoDuLieu.gopDanhSachThiDua(cu: kq.danhSachThiDua, moi: dsBang6Cot)
                        kq.soAnhThiDua += 1
                        continue
                    }
                }

                // ƯU TIÊN 4A: Kiểm tra ảnh Bảng Thi Đua 4 Cột (CHƯƠNG TRÌNH | THỰC HIỆN | TARGET NGÀY/THÁNG | % HT)
                let dsBang4Cot = self.phanTichBangThiDua4Cot(phanTu: phanTu, watermark: wm)
                if !dsBang4Cot.isEmpty {
                    kq.danhSachThiDua = KhoDuLieu.gopDanhSachThiDua(cu: kq.danhSachThiDua, moi: dsBang4Cot)
                    kq.soAnhThiDua += 1
                    continue
                }

                // ƯU TIÊN 4B: Kiểm tra ảnh Lưới Thẻ Thi Đua 2 Cột
                let dsLuoiThe = self.phanTichThiDuaLuoiThe2Cot(phanTu: phanTu, watermark: wm)
                if !dsLuoiThe.isEmpty {
                    kq.danhSachThiDua = KhoDuLieu.gopDanhSachThiDua(cu: kq.danhSachThiDua, moi: dsLuoiThe)
                    kq.soAnhThiDua += 1
                    continue
                }

                // ƯU TIÊN 5: Dự phòng bảng Thi đua 2 cột / 5 cột hoặc bảng NV
                if !dsDTNV.isEmpty {
                    kq.doanhThuNhanVien.append(contentsOf: dsDTNV)
                    kq.soAnhDoanhThuNV += 1
                    continue
                }
                if let khoiNV = self.phanTichThiDuaNhanVienOffline(phanTu: phanTu, tenNganhGoiY: nil, watermark: wm),
                   khoiNV.danhSach.count >= 2 {
                    kq.thiDuaNhanVien.append(khoiNV)
                    kq.soAnhThiDuaNV += 1
                    continue
                }

                cacPhanTuThiDuaDuPhong.append((phanTu, wm))
                kq.soAnhThiDua += 1
            }

            if !cacPhanTuThiDuaDuPhong.isEmpty {
                let ds = self.xuLyNhomBangThiDuaDuPhong(cacPhanTuThiDuaDuPhong)
                kq.danhSachThiDua = KhoDuLieu.gopDanhSachThiDua(cu: kq.danhSachThiDua, moi: ds)
            }

            if dtGop.coDuLieu {
                kq.doanhThu = dtGop
            }

            if kq.capNhatLuc.isEmpty {
                kq.capNhatLuc = TienIchNgay.hienThiGioPhut.string(from: Date())
            }

            DispatchQueue.main.async {
                hoanTat(kq)
            }
        }
    }

    private func xuLyNhomBangThiDuaDuPhong(_ cacPhanTu: [([PhanTuVanBan], String?)]) -> [DongThiDua] {
        var dsTongHop: [DongThiDua] = []
        var idx = 0
        while idx < cacPhanTu.count {
            let (pt1, wm1) = cacPhanTu[idx]
            if idx + 1 < cacPhanTu.count {
                let (pt2, wm2) = cacPhanTu[idx + 1]
                let dsCap = ghepCapAnhThiDua(phanTu1: pt1, watermark1: wm1, phanTu2: pt2, watermark2: wm2)
                if !dsCap.isEmpty {
                    dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: dsCap)
                }
                idx += 2
            } else {
                let (ds1, _, _, _) = phanTichThiDuaOffline(phanTu: pt1, tenNganhGoiY: nil)
                if !ds1.isEmpty {
                    dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: ds1)
                }
                idx += 1
            }
        }
        return dsTongHop
    }

    // MARK: - 1. Quét danh sách ảnh chụp màn hình Thi Đua (nếu chọn nhầm ảnh Doanh thu vẫn tự tách sang Doanh thu, không đưa vào Thi đua)

    func quetAnhThiDua(
        danhSachAnh: [UIImage],
        danhSachHienCo: [DongThiDua] = [],
        laRealtime: Bool = false,
        tenNganhGoiY: String? = nil,
        tienTrinh: @escaping (String) -> Void,
        hoanTat: @escaping (KetQuaQuetThiDua) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            var dsTongHop: [DongThiDua] = []
            var cacKhoiNV: [KetQuaThiDuaNhanVienKhoi] = []
            var dtQuetDuoc = ThongTinDoanhThu()
            var capNhatOffline = ""
            var donViOffline = ""

            var cacPhanTuThiDua: [([PhanTuVanBan], String?, UIImage)] = []
            let phuongPhapThiDua = KhoDuLieu.dungChung.layCaiDatAnToan().phuongPhapQuetThiDua

            for (chiSo, anh) in danhSachAnh.enumerated() {
                DispatchQueue.main.async {
                    tienTrinh("Đang quét chữ (Apple Vision) ảnh \(chiSo + 1)/\(danhSachAnh.count)...")
                }
                let phanTu = self.thucHienOCR(anh: anh)
                let (cn, dv, wm) = self.trichThongTinChungThiDua(phanTu: phanTu)
                if capNhatOffline.isEmpty, let cn = cn, !cn.isEmpty {
                    capNhatOffline = cn
                }
                if donViOffline.isEmpty, let dv = dv, !dv.isEmpty {
                    donViOffline = dv
                }

                // Nếu là ảnh Doanh thu Siêu thị (DT thực / DT quy đổi): tách sang Doanh thu, tuyệt đối không đưa vào bảng Thi đua
                if self.laAnhDoanhThuSieuThi(phanTu: phanTu) {
                    let dt = self.phanTichDoanhThu(phanTu: phanTu)
                    if dt.coDuLieu {
                        dtQuetDuoc = dtQuetDuoc.gop(voi: dt, laRealtime: laRealtime)
                        continue
                    }
                }

                // Nếu là ảnh Bảng Doanh thu Nhân viên 5 cột (có "id: mã NV" hoặc "NGÀNH HÀNG BI / DOANH THU QĐ / DT QĐ KHOẢN VAY / % TỈ TRỌNG"): tuyệt đối không đưa vào Thi Đua
                if self.laAnhBangDoanhThuNhanVien(phanTu: phanTu) {
                    continue
                }

                // Kiểm tra xem có phải ảnh bảng Thực hiện nhân viên theo ngành hàng không
                let coCotHangTrongST = phanTu.contains { pt in
                    let u = self.boDau(pt.chu)
                    return pt.y < 0.22 && (
                        u.contains("HANG TRONG") ||
                        u.contains("TOP/BOTT") ||
                        u.contains("CON / VUOT")
                    )
                }
                if coCotHangTrongST {
                    if let khoiNV = self.phanTichThiDuaNhanVienOffline(phanTu: phanTu, tenNganhGoiY: tenNganhGoiY, watermark: wm),
                       !khoiNV.danhSach.isEmpty {
                        cacKhoiNV.append(khoiNV)
                    }
                } else {
                    cacPhanTuThiDua.append((phanTu, wm, anh))
                }
            }

            var cacPhanTuBang2Cot: [([PhanTuVanBan], String?)] = []
            for (pt, wm, anhQuet) in cacPhanTuThiDua {
                if phuongPhapThiDua == .phuongPhap2 || self.laAnhBangThiDua6Cot(phanTu: pt) {
                    let dsBang6Cot = self.phanTichBangThiDuaPhuongPhap2_6Cot(phanTu: pt, anh: anhQuet, watermark: wm)
                    if !dsBang6Cot.isEmpty {
                        dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: dsBang6Cot)
                        continue
                    }
                }
                let dsBang4Cot = self.phanTichBangThiDua4Cot(phanTu: pt, watermark: wm)
                if !dsBang4Cot.isEmpty {
                    dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: dsBang4Cot)
                    continue
                }
                let dsLuoiThe = self.phanTichThiDuaLuoiThe2Cot(phanTu: pt, watermark: wm)
                if !dsLuoiThe.isEmpty {
                    dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: dsLuoiThe)
                } else {
                    let dsBang6CotDuPhong = self.phanTichBangThiDuaPhuongPhap2_6Cot(phanTu: pt, anh: anhQuet, watermark: wm)
                    if !dsBang6CotDuPhong.isEmpty {
                        dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: dsBang6CotDuPhong)
                    } else {
                        cacPhanTuBang2Cot.append((pt, wm))
                    }
                }
            }

            if !cacPhanTuBang2Cot.isEmpty {
                if cacPhanTuBang2Cot.count == 1,
                   !danhSachHienCo.isEmpty,
                   (danhSachHienCo.allSatisfy({ $0.target <= 0 }) || danhSachHienCo.allSatisfy({ $0.thucHien <= 0 })) {
                    let (pt2, wm2) = cacPhanTuBang2Cot[0]
                    let (_, cacSo2) = self.trichXuatSoCotPhaiTuTrenXuong(phanTu: pt2, watermark: wm2)
                    let dangThieuTarget = danhSachHienCo.allSatisfy({ $0.target <= 0 })
                    var capNhat = danhSachHienCo
                    for i in 0..<min(capNhat.count, cacSo2.count) {
                        if dangThieuTarget {
                            capNhat[i].target = cacSo2[i].giaTri
                        } else {
                            capNhat[i].thucHien = cacSo2[i].giaTri
                        }
                    }
                    dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: capNhat)
                } else {
                    var idx = 0
                    while idx < cacPhanTuBang2Cot.count {
                        let (pt1, wm1) = cacPhanTuBang2Cot[idx]
                        if idx + 1 < cacPhanTuBang2Cot.count {
                            let (pt2, wm2) = cacPhanTuBang2Cot[idx + 1]
                            let dsCap = self.ghepCapAnhThiDua(phanTu1: pt1, watermark1: wm1, phanTu2: pt2, watermark2: wm2)
                            if !dsCap.isEmpty {
                                dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: dsCap)
                            }
                            idx += 2
                        } else {
                            let (ds1, _, _, _) = self.phanTichThiDuaOffline(phanTu: pt1, tenNganhGoiY: tenNganhGoiY)
                            if !ds1.isEmpty {
                                dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: ds1)
                            }
                            idx += 1
                        }
                    }
                }
            }

            if !danhSachHienCo.isEmpty && !dsTongHop.isEmpty {
                dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: danhSachHienCo, moi: dsTongHop)
            } else {
                dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: [], moi: dsTongHop)
            }

            let ketQua = KetQuaQuetThiDua(
                danhSach: dsTongHop,
                thiDuaNhanVien: cacKhoiNV,
                doanhThuQuetDuoc: dtQuetDuoc.coDuLieu ? dtQuetDuoc : nil,
                capNhatLuc: capNhatOffline.isEmpty ? TienIchNgay.hienThiGioPhut.string(from: Date()) : capNhatOffline,
                thongTinDonVi: donViOffline
            )
            DispatchQueue.main.async {
                hoanTat(ketQua)
            }
        }
    }

    /// Chỉ nhận diện mã watermark ở vùng đầu ảnh khi mã đó KHÔNG nằm trong danh sách nhân viên quản lý và không phải dòng nhân viên trong bảng (bắt đầu bằng dấu '+')
    private func timMaWatermarkAnToan(
        phanTu: [PhanTuVanBan],
        yGioiHan: CGFloat = 0.16,
        yTruocHeader: CGFloat? = nil
    ) -> String? {
        let tapMaQuanLy = Set(KhoDuLieu.dungChung.layCaiDatAnToan().danhSachNhanVien.map(\.maNV))
        for pt in phanTu where pt.y < yGioiHan {
            let chuTrim = pt.chu.trimmingCharacters(in: .whitespacesAndNewlines)
            if chuTrim.hasPrefix("+") { continue }
            if let yMax = yTruocHeader, (pt.y + pt.cao) >= yMax {
                let u = boDau(chuTrim)
                if !u.contains("DUNG NGUYEN") && !u.contains("NGUYEN THANH") {
                    continue
                }
            }
            if let range = chuTrim.range(of: "\\b\\d{4,7}(?=\\s*-)", options: .regularExpression) {
                let ma = String(chuTrim[range])
                if tapMaQuanLy.contains(ma) { continue }
                if ma.count >= 6 && tapMaQuanLy.contains(String(ma.dropFirst())) { continue }
                return ma
            }
        }
        return nil
    }

    // MARK: - 2. Quét danh sách ảnh chụp bảng Thực hiện Nhân viên theo Ngành hàng

    func quetAnhThiDuaNhanVien(
        danhSachAnh: [UIImage],
        tenNganhGoiY: String? = nil,
        tienTrinh: ((String) -> Void)? = nil,
        hoanTat: @escaping ([KetQuaThiDuaNhanVienKhoi]) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            var cacKhoi: [KetQuaThiDuaNhanVienKhoi] = []
            for (chiSo, anh) in danhSachAnh.enumerated() {
                DispatchQueue.main.async {
                    tienTrinh?("Đang đọc ảnh Thực hiện NV \(chiSo + 1)/\(danhSachAnh.count)...")
                }
                let phanTu = self.thucHienOCR(anh: anh)
                let watermark = self.timMaWatermarkAnToan(phanTu: phanTu, yGioiHan: 0.16)
                if let khoi = self.phanTichThiDuaNhanVienOffline(phanTu: phanTu, tenNganhGoiY: tenNganhGoiY, watermark: watermark),
                   !khoi.danhSach.isEmpty {
                    cacKhoi.append(khoi)
                }
            }
            DispatchQueue.main.async {
                hoanTat(cacKhoi)
            }
        }
    }

    // MARK: - 3. Quét danh sách ảnh chụp màn hình Doanh thu (Lũy kế hoặc Realtime: DT thực & DT quy đổi)

    func quetAnhDoanhThu(
        danhSachAnh: [UIImage],
        laRealtime: Bool = false,
        tienTrinh: ((String) -> Void)? = nil,
        hoanTat: @escaping (ThongTinDoanhThu) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            var ketQuaGop = ThongTinDoanhThu()
            for (chiSo, anh) in danhSachAnh.enumerated() {
                DispatchQueue.main.async {
                    tienTrinh?("Đang đọc ảnh Doanh thu \(chiSo + 1)/\(danhSachAnh.count)...")
                }
                let phanTu = self.thucHienOCR(anh: anh)
                let kqAnh = self.phanTichDoanhThu(phanTu: phanTu)
                ketQuaGop = ketQuaGop.gop(voi: kqAnh, laRealtime: laRealtime)
            }
            DispatchQueue.main.async {
                hoanTat(ketQuaGop)
            }
        }
    }

    // MARK: - 4. Quét danh sách ảnh chụp bảng Doanh thu hợp nhất theo Nhân viên

    func quetAnhDoanhThuNhanVien(
        danhSachAnh: [UIImage],
        tienTrinh: ((String) -> Void)? = nil,
        hoanTat: @escaping ([DoanhThuNhanVienItem]) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            var dsQuet: [DoanhThuNhanVienItem] = []
            for (chiSo, anh) in danhSachAnh.enumerated() {
                DispatchQueue.main.async {
                    tienTrinh?("Đang đọc ảnh Doanh thu NV \(chiSo + 1)/\(danhSachAnh.count)...")
                }
                let phanTu = self.thucHienOCR(anh: anh)
                dsQuet.append(contentsOf: self.phanTichDoanhThuNhanVienOffline(phanTu: phanTu, anh: anh))
            }
            DispatchQueue.main.async {
                hoanTat(dsQuet)
            }
        }
    }

    // MARK: - Bước 1: Apple Vision OCR trên iPhone

    /// Làm sạch watermark chữ chìm màu xám nhạt (ví dụ: 54453 / Dũng Nguyễn Thanh) và phóng nét ảnh nhỏ trước khi đưa vào Apple Vision OCR
    private func taoCGImageDaLocWatermarkVaTangNet(tu anh: UIImage) -> CGImage? {
        guard let cgGoc = anh.cgImage else { return nil }
        let rongGoc = cgGoc.width
        let caoGoc = cgGoc.height
        guard rongGoc > 20, caoGoc > 20 else { return cgGoc }

        let heSo: Int = (rongGoc < 1500) ? 2 : 1
        let rong = rongGoc * heSo
        let cao = caoGoc * heSo
        let bytesPerPixel = 4
        let bytesPerRow = rong * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let ctx = CGContext(
            data: nil,
            width: rong,
            height: cao,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return cgGoc
        }

        ctx.interpolationQuality = .high
        ctx.draw(cgGoc, in: CGRect(x: 0, y: 0, width: rong, height: cao))

        guard let data = ctx.data else { return ctx.makeImage() ?? cgGoc }
        let ptr = data.bindMemory(to: UInt8.self, capacity: rong * cao * bytesPerPixel)
        let tongPixel = rong * cao

        for i in 0..<tongPixel {
            let offset = i * 4
            let r = Int(ptr[offset])
            let g = Int(ptr[offset + 1])
            let b = Int(ptr[offset + 2])

            // Làm trắng biểu tượng ngôi sao màu vàng tươi (⭐) ở đầu tiêu đề thẻ để không bị đọc nhầm thành ký tự rác (& 1-, gy T1-)
            if r >= 190 && g >= 150 && b < 160 && (r - b) > 55 && (g * 100) >= (r * 73) {
                ptr[offset] = 255
                ptr[offset + 1] = 255
                ptr[offset + 2] = 255
            }
        }

        return ctx.makeImage() ?? cgGoc
    }

    private static let regexTokenSoOCR = try? NSRegularExpression(pattern: "[+\\-−–—]?\\d+([.,]\\d+)?%?")
    private static let regexTuKhongKhoangTrang = try? NSRegularExpression(pattern: "\\S+")

    /// Tách một dòng văn bản rộng (gộp nhiều cột trong thẻ hoặc gộp cả thẻ trái & thẻ phải) thành các phần tử độc lập khi có khoảng trống ngang >= 0.042 hoặc vượt qua trục giữa x = 0.495
    private func tachPhanTuTheoKhoangTrongNgang(tu ungVien: VNRecognizedText, boxGoc: CGRect) -> [PhanTuVanBan] {
        let chuoi = ungVien.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !chuoi.isEmpty, !chuoi.contains("\n"), boxGoc.size.width > 0.18, let regex = Self.regexTuKhongKhoangTrang else {
            return []
        }
        let ns = chuoi as NSString
        let matches = regex.matches(in: chuoi, range: NSRange(location: 0, length: ns.length))
        guard matches.count >= 2 else { return [] }

        struct TuCoToaDo {
            var chu: String
            var x: CGFloat
            var y: CGFloat
            var x2: CGFloat
            var y2: CGFloat
        }

        let yTrenGoc = 1.0 - boxGoc.origin.y - boxGoc.size.height
        let tongDoDai = CGFloat(max(1, ns.length))
        var danhSachTu: [TuCoToaDo] = []

        for m in matches {
            let tu = ns.substring(with: m.range)
            var xTu = boxGoc.origin.x + boxGoc.size.width * (CGFloat(m.range.location) / tongDoDai)
            var yTu = yTrenGoc
            var rongTu = max(0.006, boxGoc.size.width * (CGFloat(m.range.length) / tongDoDai))
            var caoTu = boxGoc.size.height

            if let rangeSwift = Range(m.range, in: chuoi),
               let rectObs = try? ungVien.boundingBox(for: rangeSwift) {
                let subBox = rectObs.boundingBox
                if subBox.size.width > 0.001 && subBox.size.height > 0.001 {
                    xTu = subBox.origin.x
                    yTu = 1.0 - subBox.origin.y - subBox.size.height
                    rongTu = subBox.size.width
                    caoTu = subBox.size.height
                }
            }
            danhSachTu.append(TuCoToaDo(chu: tu, x: xTu, y: yTu, x2: xTu + rongTu, y2: yTu + caoTu))
        }

        danhSachTu.sort { $0.x < $1.x }
        var cacCum: [TuCoToaDo] = []
        for tu in danhSachTu {
            if let cuoi = cacCum.last {
                let khoangCach = tu.x - cuoi.x2
                let vuotGiuaTrang = (cuoi.x2 < 0.498 && tu.x >= 0.490)
                if khoangCach >= 0.042 || vuotGiuaTrang {
                    cacCum.append(tu)
                } else {
                    var gop = cuoi
                    gop.chu += " " + tu.chu
                    gop.x2 = max(gop.x2, tu.x2)
                    gop.y = min(gop.y, tu.y)
                    gop.y2 = max(gop.y2, tu.y2)
                    cacCum[cacCum.count - 1] = gop
                }
            } else {
                cacCum.append(tu)
            }
        }

        guard cacCum.count >= 2 else { return [] }
        return cacCum.map {
            PhanTuVanBan(
                chu: $0.chu.trimmingCharacters(in: .whitespacesAndNewlines),
                x: $0.x,
                y: $0.y,
                rong: max(0.006, $0.x2 - $0.x),
                cao: max(0.006, $0.y2 - $0.y)
            )
        }
    }

    private func trichXuatCacPhanTuTokenSo(tu ungVien: VNRecognizedText, boxGoc: CGRect) -> [PhanTuVanBan] {
        let chuoi = ungVien.string
        guard !chuoi.isEmpty, let regex = Self.regexTokenSoOCR else { return [] }
        let ns = chuoi as NSString
        let matches = regex.matches(in: chuoi, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return [] }

        let yTrenGoc = 1.0 - boxGoc.origin.y - boxGoc.size.height
        let tongDoDai = CGFloat(max(1, ns.length))
        var ketQua: [PhanTuVanBan] = []

        for m in matches {
            // Không tách các con số nằm dính liền bên trong chữ (ví dụ số "11" trong "T11", "#2", "4G", "5G") để tránh tạo phần tử "11" giả ở đầu tiêu đề
            if m.range.location > 0 {
                let kyTuTruoc = ns.substring(with: NSRange(location: m.range.location - 1, length: 1))
                if kyTuTruoc.range(of: "[A-Za-zÀ-ỹĐđ#]", options: .regularExpression) != nil {
                    continue
                }
            }
            let viTriSau = m.range.location + m.range.length
            if viTriSau < ns.length {
                let kyTuSau = ns.substring(with: NSRange(location: viTriSau, length: 1))
                if kyTuSau.range(of: "[A-Za-zÀ-ỹĐđ]", options: .regularExpression) != nil {
                    continue
                }
            }
            let token = ns.substring(with: m.range).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !token.isEmpty else { continue }
            var xToken = boxGoc.origin.x + boxGoc.size.width * (CGFloat(m.range.location) / tongDoDai)
            var yToken = yTrenGoc
            var rongToken = max(0.008, boxGoc.size.width * (CGFloat(m.range.length) / tongDoDai))
            var caoToken = boxGoc.size.height

            if let rangeSwift = Range(m.range, in: chuoi),
               let rectObs = try? ungVien.boundingBox(for: rangeSwift) {
                let subBox = rectObs.boundingBox
                if subBox.size.width > 0.001 && subBox.size.height > 0.001 {
                    xToken = subBox.origin.x
                    yToken = 1.0 - subBox.origin.y - subBox.size.height
                    rongToken = subBox.size.width
                    caoToken = subBox.size.height
                }
            }
            ketQua.append(
                PhanTuVanBan(
                    chu: token,
                    x: xToken,
                    y: yToken,
                    rong: rongToken,
                    cao: caoToken
                )
            )
        }
        return ketQua
    }

    private func thucHienOCR(anh: UIImage) -> [PhanTuVanBan] {
        guard let cgImage = taoCGImageDaLocWatermarkVaTangNet(tu: anh) ?? anh.cgImage else { return [] }

        var phanTu: [PhanTuVanBan] = []
        var phanTuSoBoSung1: [PhanTuVanBan] = []
        var phanTuSoBoSung2: [PhanTuVanBan] = []

        let yeuCau = VNRecognizeTextRequest { [weak self] request, _ in
            guard let self = self, let ketQua = request.results as? [VNRecognizedTextObservation] else { return }
            for obs in ketQua {
                guard let ungVien = obs.topCandidates(1).first else { continue }
                let chuGoc = ungVien.string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !chuGoc.isEmpty else { continue }
                let box = obs.boundingBox
                let yTrenXuong = 1.0 - box.origin.y - box.size.height

                let cacDong = chuGoc.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }

                if cacDong.count > 1 {
                    let caoMoiDong = box.size.height / CGFloat(cacDong.count)
                    for (idx, dongChu) in cacDong.enumerated() {
                        let yDong = yTrenXuong + CGFloat(idx) * caoMoiDong
                        phanTu.append(
                            PhanTuVanBan(
                                chu: dongChu,
                                x: box.origin.x,
                                y: yDong,
                                rong: box.size.width,
                                cao: caoMoiDong
                            )
                        )
                    }
                } else {
                    let cacCumTach = self.tachPhanTuTheoKhoangTrongNgang(tu: ungVien, boxGoc: box)
                    if cacCumTach.count >= 2 {
                        phanTu.append(contentsOf: cacCumTach)
                    } else {
                        phanTu.append(
                            PhanTuVanBan(
                                chu: chuGoc,
                                x: box.origin.x,
                                y: yTrenXuong,
                                rong: box.size.width,
                                cao: box.size.height
                            )
                        )
                    }
                }

                // Tách riêng từng con số nếu một box gộp nhiều cột (hỗ trợ cả cột thẻ bên trái x >= 0.02 và cột bên phải)
                let cacTokenSo = self.trichXuatCacPhanTuTokenSo(tu: ungVien, boxGoc: box)
                if cacTokenSo.count >= 2 {
                    for tk in cacTokenSo where tk.x >= 0.02 {
                        phanTuSoBoSung1.append(tk)
                    }
                }
            }
        }

        yeuCau.recognitionLevel = .accurate
        yeuCau.usesLanguageCorrection = true
        yeuCau.recognitionLanguages = ["vi-VN", "en-US"]

        let yeuCauSo = VNRecognizeTextRequest { [weak self] request, _ in
            guard let self = self, let ketQua = request.results as? [VNRecognizedTextObservation] else { return }
            for obs in ketQua {
                let box = obs.boundingBox
                let yTrenXuong = 1.0 - box.origin.y - box.size.height
                let cacUngVien = obs.topCandidates(3)

                if let dauTien = cacUngVien.first {
                    let chuDau = dauTien.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    if self.laDauTieuDeMonThiDua(chuDau) ||
                       (chuDau.contains("-") && chuDau.range(of: "\\b\\d{4,7}\\b", options: .regularExpression) == nil && chuDau.range(of: "[A-Za-zÀ-ỹĐđ]{2,}", options: .regularExpression) != nil) {
                        continue
                    }
                }

                for ungVien in cacUngVien {
                    let chu = ungVien.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !chu.isEmpty else { continue }
                    if chu.range(of: "^[+\\-−–—]?[0-9]+([.,][0-9]+)?%?$", options: .regularExpression) != nil {
                        phanTuSoBoSung2.append(
                            PhanTuVanBan(
                                chu: chu,
                                x: box.origin.x,
                                y: yTrenXuong,
                                rong: box.size.width,
                                cao: box.size.height
                            )
                        )
                        break
                    } else {
                        let cacToken = self.trichXuatCacPhanTuTokenSo(tu: ungVien, boxGoc: box)
                        if !cacToken.isEmpty {
                            for tk in cacToken where tk.x >= 0.02 {
                                phanTuSoBoSung2.append(tk)
                            }
                            break
                        }
                    }
                }
            }
        }
        yeuCauSo.recognitionLevel = .accurate
        yeuCauSo.usesLanguageCorrection = false
        yeuCauSo.minimumTextHeight = 0.004

        let xuLy = VNImageRequestHandler(cgImage: cgImage, orientation: anh.cgImageOrientation, options: [:])
        try? xuLy.perform([yeuCau])
        try? xuLy.perform([yeuCauSo])

        let phanTuSoBoSung = phanTuSoBoSung1 + phanTuSoBoSung2
        for ptSo in phanTuSoBoSung {
            let daCo = phanTu.contains { pt in
                guard abs(pt.y - ptSo.y) < 0.013 && abs(pt.x - ptSo.x) < 0.032 else { return false }
                guard pt.rong < 0.16 && !pt.chu.contains("\n") else { return false }
                return self.trichCacSo(trong: pt.chu).count == 1
            }
            if !daCo {
                phanTu.append(ptSo)
            }
        }
        return phanTu
    }

    // MARK: - Bước 2A: Bộ phân tích bố cục Thi Đua ĐMX & Thực hiện NV

    private func phanTichThiDuaOffline(
        phanTu: [PhanTuVanBan],
        tenNganhGoiY: String? = nil
    ) -> ([DongThiDua], [KetQuaThiDuaNhanVienKhoi], String?, String?) {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) || laAnhBangDoanhThuNhanVien(phanTu: phanTu) {
            return ([], [], nil, nil)
        }

        var capNhatLuc: String?
        var thongTinDonVi: String?
        var maNhanVienWatermark: String?

        for pt in phanTu {
            if pt.chu.localizedCaseInsensitiveContains("Cập nhật lúc") || pt.chu.range(of: "\\d{2}:\\d{2}:\\d{2}", options: .regularExpression) != nil {
                if capNhatLuc == nil {
                    capNhatLuc = pt.chu.replacingOccurrences(of: "Cập nhật lúc:", with: "").trimmingCharacters(in: .whitespaces)
                } else if !capNhatLuc!.contains(pt.chu) {
                    capNhatLuc = "\(capNhatLuc!) \(pt.chu)"
                }
            }
            if maNhanVienWatermark == nil, pt.y < 0.16 {
                maNhanVienWatermark = timMaWatermarkAnToan(phanTu: [pt], yGioiHan: 0.16)
            }
            if pt.chu.hasPrefix("ĐML_") || pt.chu.hasPrefix("ĐMX_") || pt.chu.hasPrefix("TGDĐ_") {
                if thongTinDonVi == nil {
                    thongTinDonVi = pt.chu
                }
            }
        }

        let coCotHangTrongST = phanTu.contains { pt in
            let u = boDau(pt.chu)
            return pt.y < 0.22 && (
                u.contains("HANG TRONG") ||
                u.contains("TOP/BOTT") ||
                u.contains("CON / VUOT") ||
                u.contains("NHAN VIEN")
            )
        }

        if coCotHangTrongST {
            if let khoiNV = phanTichThiDuaNhanVienOffline(phanTu: phanTu, tenNganhGoiY: tenNganhGoiY, watermark: maNhanVienWatermark) {
                return ([], [khoiNV], capNhatLuc, thongTinDonVi)
            }
            return ([], [], capNhatLuc, thongTinDonVi)
        }

        if KhoDuLieu.dungChung.layCaiDatAnToan().phuongPhapQuetThiDua == .phuongPhap2 || laAnhBangThiDua6Cot(phanTu: phanTu) {
            let dsBang6Cot = phanTichBangThiDuaPhuongPhap2_6Cot(phanTu: phanTu, anh: nil, watermark: maNhanVienWatermark)
            if !dsBang6Cot.isEmpty {
                return (dsBang6Cot, [], capNhatLuc, thongTinDonVi)
            }
        }

        let dsBang4Cot = phanTichBangThiDua4Cot(phanTu: phanTu, watermark: maNhanVienWatermark)
        if !dsBang4Cot.isEmpty {
            return (dsBang4Cot, [], capNhatLuc, thongTinDonVi)
        }

        let dsLuoiThe = phanTichThiDuaLuoiThe2Cot(phanTu: phanTu, watermark: maNhanVienWatermark)
        if !dsLuoiThe.isEmpty {
            return (dsLuoiThe, [], capNhatLuc, thongTinDonVi)
        }

        let dsHaiCot = phanTichThiDuaHaiCot(phanTu: phanTu, watermark: maNhanVienWatermark)
        if !dsHaiCot.isEmpty {
            return (dsHaiCot, [], capNhatLuc, thongTinDonVi)
        }

        let mocChiTieu = phanTu.filter { pt in
            let khongDau = boDau(pt.chu)
            let laChiTieu = khongDau.contains("SO LUONG") || khongDau.contains("DOANH THU")
            return laChiTieu && pt.x >= 0.22 && pt.x <= 0.55 && pt.y > 0.12
        }.sorted { $0.y < $1.y }

        var ketQua: [DongThiDua] = []

        for (chiSo, moc) in mocChiTieu.enumerated() {
            let yTieuDe = moc.y
            let yGioiHanDuoi: CGFloat = (chiSo + 1 < mocChiTieu.count) ? mocChiTieu[chiSo + 1].y - 0.015 : 0.98

            let loai: LoaiChiTieuThiDua = boDau(moc.chu).contains("DOANH") ? .doanhThu : .soLuong

            let phanTuTen = phanTu.filter { pt in
                pt.x < 0.31 && abs(pt.y - yTieuDe) < 0.045 && !laChuoiRac(pt.chu, watermark: maNhanVienWatermark)
            }.sorted {
                if abs($0.y - $1.y) < 0.008 { return $0.x < $1.x }
                return $0.y < $1.y
            }

            let tenNganhHang = phanTuTen
                .map { $0.chu }
                .joined(separator: " ")
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !tenNganhHang.isEmpty, !laTenTheDoanhThuKhongPhaiThiDua(tenNganhHang) else { continue }

            let vungDuLieu = phanTu.filter { pt in
                pt.y > yTieuDe + 0.015 && pt.y < min(yGioiHanDuoi, yTieuDe + 0.14) && pt.x >= 0.28
            }

            let soThucHien = timGiaTriSo(trong: vungDuLieu.filter { $0.x >= 0.28 && $0.x < 0.50 }, watermark: maNhanVienWatermark)
            let soTarget = timGiaTriSo(trong: vungDuLieu.filter { $0.x >= 0.50 && $0.x < 0.69 }, watermark: maNhanVienWatermark)
            let soHT = timGiaTriSo(trong: vungDuLieu.filter { $0.x >= 0.69 && $0.x < 0.84 }, watermark: maNhanVienWatermark)
            let soDuBao = timGiaTriSo(trong: vungDuLieu.filter { $0.x >= 0.84 }, watermark: maNhanVienWatermark)

            guard let thucHien = soThucHien, let target = soTarget else { continue }

            let dong = DongThiDua(
                tenNganhHangGoc: tenNganhHang,
                tenNganhHang: tenNganhHang,
                loaiChiTieu: loai,
                thucHien: thucHien,
                target: target,
                phanTramHTGoc: soHT,
                phanTramDuBaoGoc: soDuBao
            )
            ketQua = KhoDuLieu.gopDanhSachThiDua(cu: ketQua, moi: [dong])
        }

        return (ketQua, [], capNhatLuc, thongTinDonVi)
    }

    // MARK: - Nhận diện Lưới Thẻ Thi Đua (hỗ trợ từ 1, 2, 3 môn đến 8+ môn trên 1 ảnh)

    private func laDauTieuDeMonThiDua(_ chu: String) -> Bool {
        let u = boDau(chu)
            .replacingOccurrences(of: "^[^A-Z0-9]+", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return u.range(of: "^(?:[A-Z]{1,3}\\s+)?(?:T|7|1|I|L)?\\d{1,2}\\s*[-–—]", options: .regularExpression) != nil
    }

    private func laBadgePhanNhomThe(_ chu: String) -> Bool {
        let uGon = boDau(chu).replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
        let tapBadge: Set<String> = ["CE", "ICT", "1CT", "LCT", "LER", "IC", "DV", "BV", "OV", "0V", "MDA", "SDA", "GD", "PK", "AV"]
        return tapBadge.contains(uGon)
    }

    private func laBadgeDonViThe(_ chu: String) -> Bool {
        let uGon = boDau(chu).replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
        let tapDonVi: Set<String> = ["DT", "SL", "0T", "OT", "5L", "SI", "ST", "PR", "PRT", "PT", "OR", "SE", "RI", "BT", "CY", "OO", "EE"]
        return tapDonVi.contains(uGon)
    }

    /// Kiểm tra xem bức ảnh có phải là giao diện Lưới Thẻ Thi Đua (dù ảnh có 8 môn, 6 môn, 5 môn, 4 môn hay chỉ 3 môn / 1-2 môn) hay không
    private func laAnhLuoiTheThiDua(phanTu: [PhanTuVanBan]) -> Bool {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) { return false }

        // Bảng 4 cột có chữ "CHƯƠNG TRÌNH" ở góc trên bên trái và KHÔNG bao giờ có tiêu đề T11 ở nửa phải hoặc nhãn THỰC HIỆN ở sát lề trái (x < 0.22)
        let coHeaderChuongTrinh = phanTu.contains { $0.y < 0.25 && $0.x < 0.35 && boDau($0.chu).contains("CHUONG TRINH") }
        let coTieuDeThePhai = phanTu.contains { $0.x >= 0.46 && laDauTieuDeMonThiDua($0.chu) }
        let coTieuDeTheTrai = phanTu.contains { $0.x < 0.45 && laDauTieuDeMonThiDua($0.chu) }
        let coThucHienSatTrai = phanTu.contains {
            $0.x < 0.22 && (boDau($0.chu).contains("THUC HIEN") || boDau($0.chu).contains("THYUC HIEN") || boDau($0.chu).contains("THC HIEN"))
        }
        let coDuKienTrongThe = phanTu.contains {
            let u = boDau($0.chu)
            return u.contains("DT DU") || u.contains("SL DU") || u.contains("DT DY") || u.contains("SL DY") || u.contains("OT DU")
        }
        let coTargetPhai = phanTu.contains { $0.x >= 0.46 && boDau($0.chu).contains("TARGET") }

        if coTieuDeThePhai && (coTieuDeTheTrai || coThucHienSatTrai || coTargetPhai || coDuKienTrongThe) {
            return true
        }
        if !coHeaderChuongTrinh && (coThucHienSatTrai || coDuKienTrongThe) && (coTieuDeTheTrai || coTargetPhai) {
            return true
        }
        return false
    }

    // MARK: - Bước 2A.00: Bộ phân tích Bảng Thi Đua 6 Cột - Phương pháp 2 (CHƯƠNG TRÌNH | THỰC HIỆN | TARGET | % HT | % HT DỰ KIẾN | HẠNG VÙNG)

    /// Nhận diện bức ảnh thuộc định dạng Bảng Thi Đua 6 cột mới (có cột "% HT DỰ KIẾN" / "HẠNG VÙNG" hoặc có 2 cột % ở x = 0.64..0.88)
    private func laAnhBangThiDua6Cot(phanTu: [PhanTuVanBan]) -> Bool {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) || laAnhBangDoanhThuNhanVien(phanTu: phanTu) || laAnhLuoiTheThiDua(phanTu: phanTu) {
            return false
        }
        var coChuongTrinh = false
        var coHTDuKien = false
        var coHangVung = false
        for pt in phanTu where pt.y < 0.22 {
            let u = boDau(pt.chu)
            if u.contains("CHUONG TRINH") { coChuongTrinh = true }
            if pt.x >= 0.68 && (u.contains("DU KIEN") || u.contains("DY KIEN")) { coHTDuKien = true }
            if pt.x >= 0.80 && (u.contains("HANG VUNG") || u.contains("VUNG")) { coHangVung = true }
        }
        if coHTDuKien || coHangVung || (coChuongTrinh && (coHTDuKien || coHangVung)) {
            return true
        }
        let cacPT4 = phanTu.filter { $0.x >= 0.63 && $0.x < 0.76 && $0.chu.contains("%") }
        let cacPT5 = phanTu.filter { $0.x >= 0.76 && $0.x < 0.89 && $0.chu.contains("%") }
        if cacPT4.count >= 3 && cacPT5.count >= 3 {
            return true
        }
        return false
    }

    /// Phương pháp quét Bảng Thi Đua 6 cột theo đúng cấu trúc vật lý của bảng:
    /// 1. Tìm tất cả các dấu `+` trong cột đầu tiên (`x: 0.022 .. 0.049`) làm mốc tâm cho từng dòng môn thi đua.
    /// 2. Từ mỗi dấu `+`, xác định chính xác đường kẻ ngang trên & dưới (`hBorders[k] .. hBorders[k+1]`) và 5 đường kẻ dọc chia cột (`xv0 .. xv5`).
    /// 3. Cắt từng dòng nằm trong đường kẻ ngang và xếp cách nhau `60px` khoảng trắng dọc, sau đó tách thành **5 ảnh cột độc lập** (`Cột 1: Tên môn`, `Cột 2: Thực hiện`, `Cột 3: Target`, `Cột 4: % HT`, `Cột 5: % HT Dự kiến`) để Apple Vision đọc riêng từng cột — tuyệt đối không bao giờ gộp dính 2 dòng hay gộp dính 2 cột cạnh nhau.
    private func phanTichBangThiDuaPhuongPhap2_6Cot(
        phanTu: [PhanTuVanBan],
        anh: UIImage? = nil,
        watermark: String? = nil
    ) -> [DongThiDua] {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) || laAnhBangDoanhThuNhanVien(phanTu: phanTu) || laAnhLuoiTheThiDua(phanTu: phanTu) {
            return []
        }

        // Mở rộng phanTu gốc theo từng dòng đơn
        var phanTuGocDonDong: [PhanTuVanBan] = []
        for pt in phanTu {
            let cacDong = pt.chu.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if cacDong.count > 1 {
                let caoM = pt.cao / CGFloat(cacDong.count)
                for (i, d) in cacDong.enumerated() {
                    phanTuGocDonDong.append(PhanTuVanBan(chu: d, x: pt.x, y: pt.y + CGFloat(i) * caoM, rong: pt.rong, cao: caoM))
                }
            } else if pt.cao <= 0.038 {
                phanTuGocDonDong.append(pt)
            }
        }

        var maWM = watermark
        if maWM == nil {
            var demMa5So: [String: Int] = [:]
            for pt in phanTu {
                let u = boDau(pt.chu)
                if let r = u.range(of: "\\b\\d{5}\\b", options: .regularExpression) {
                    let m = String(u[r])
                    demMa5So[m, default: 0] += (u.contains("NGUYEN") || u.contains("DUNG") || u.contains("THANH") ? 2 : 1)
                }
            }
            if let totNhat = demMa5So.max(by: { $0.value < $1.value }), totNhat.value >= 2 {
                maWM = totNhat.key
            }
        }

        // Tìm vị trí đáy thanh Header (CHƯƠNG TRÌNH | THỰC HIỆN | TARGET | % HT | % HT DỰ KIẾN | HẠNG VÙNG)
        let vungHeaderGoc = phanTuGocDonDong.filter { $0.y < 0.12 }
        let cacPTHeaderGoc = vungHeaderGoc.filter { pt in
            let u = boDau(pt.chu)
            return u.contains("CHUONG TRINH") || u.contains("THUC HIEN") || u.contains("TARGET") ||
                u.contains("% HT") || u.contains("DU KIEN") || u.contains("HANG VUNG") ||
                u == "THUC" || u == "HIEN" || u == "KIEN" || u == "VUNG"
        }
        var ySauHeader: CGFloat = cacPTHeaderGoc.map { $0.y + $0.cao }.max() ?? 0.008
        if !cacPTHeaderGoc.isEmpty {
            ySauHeader = min(0.072, max(0.042, ySauHeader + 0.002))
        }

        func lamSachChuoi(_ s: String) -> String {
            var kq = s
            if let wm = maWM, !wm.isEmpty {
                kq = kq.replacingOccurrences(of: wm, with: " ")
            }
            kq = kq.replacingOccurrences(of: "\\b(54453|5445|4453)\\b", with: " ", options: .regularExpression)
            kq = kq.replacingOccurrences(of: "(?i)dũng\\s*nguyễn(\\s*thanh)?", with: " ", options: .regularExpression)
            kq = kq.replacingOccurrences(of: "(?i)nguyễn\\s*thanh", with: " ", options: .regularExpression)
            kq = kq.replacingOccurrences(of: "(?i)dung\\s*nguyen(\\s*thanh)?", with: " ", options: .regularExpression)
            kq = kq.replacingOccurrences(of: "(?i)nguyen\\s*thanh", with: " ", options: .regularExpression)
            kq = kq.replacingOccurrences(of: "(\\d),\\s+(\\d{3}\\b)", with: "$1,$2", options: .regularExpression)
            kq = kq.replacingOccurrences(of: "(\\d)\\.\\s+(\\d{1,2}\\b)", with: "$1.$2", options: .regularExpression)
            kq = kq.replacingOccurrences(of: "(\\d{1,3})\\s+(\\d)\\s*%", with: "$1.$2%", options: .regularExpression)
            return kq.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        func trichSoHopLe(_ raw: String) -> [Double] {
            var sach = lamSachChuoi(raw)
                .replacingOccurrences(of: "%", with: "")
                .replacingOccurrences(of: "§", with: "5")
                .replacingOccurrences(of: "$", with: "5")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if sach.range(of: "^[Ss](\\d)", options: .regularExpression) != nil {
                sach = "5" + sach.dropFirst()
            }
            guard !sach.isEmpty else { return [] }
            let u = boDau(sach)
            if u.range(of: "[A-Z]{2,}", options: .regularExpression) != nil && u != "DT" && u != "SL" {
                return []
            }
            return trichCacSoTheThiDua(trong: sach).filter { val in
                if let wm = maWM, let wmVal = Double(wm), abs(val - wmVal) < 0.1 { return false }
                if abs(val - 54453) < 0.1 || abs(val - 5445) < 0.1 || abs(val - 4453) < 0.1 { return false }
                return val >= 0 && val < 100000
            }
        }

        func nhanDienTenVaDonVi(tu cacChuoiDong: [String], coSoThapPhan: Bool) -> (tenSach: String, loai: LoaiChiTieuThiDua) {
            var coBadgeSL = false
            var coBadgeDT = false
            var cacDongSach: [String] = []

            for d in cacChuoiDong {
                let chuSach = lamSachChuoi(d)
                guard !chuSach.isEmpty else { continue }
                let u = boDau(chuSach).trimmingCharacters(in: .whitespacesAndNewlines)
                let uGon = u.replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)

                if uGon == "SL" || uGon == "5L" || uGon == "SI" || uGon == "SV" || uGon == "ST" || uGon == "SE" || uGon == "S1" || uGon == "51" ||
                   u.range(of: "\\b(SL|5L|SI|SV|ST|SE|S1|51)\\b\\s*$", options: .regularExpression) != nil {
                    coBadgeSL = true
                } else if uGon == "DT" || uGon == "0T" || uGon == "OT" || uGon == "07" || uGon == "OX" || uGon == "OR" || uGon == "PR" || uGon == "PT" || uGon == "BT" || uGon == "OF" ||
                          u.range(of: "\\b(DT|0T|OT|07|OX|OR|PR|PT|BT|OF)\\b\\s*$", options: .regularExpression) != nil {
                    coBadgeDT = true
                }

                if uGon.isEmpty || ["DT", "SL", "5L", "0T", "OT", "SI", "SV", "ST", "SE", "07", "OX", "OR", "PR", "PT", "BT", "OF", "S1", "51"].contains(uGon) {
                    continue
                }
                if u.contains("CHUONG TRINH") || u.contains("THUC HIEN") || u.contains("TARGET") || u.contains("HANG VUNG") {
                    continue
                }
                if laChuoiRac(chuSach, watermark: maWM) {
                    continue
                }

                let sach = chuSach
                    .replacingOccurrences(of: "^[+⊕⊞★☆⭐4\\s]+(?=\\p{L})", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "^[+⊕⊞★☆⭐\\s]+", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "(?:\\s+|\\s*[\\|¦_]\\s*)\\b(DT|SL|5L|0T|OT|SI|SV|ST|SE|07|OX|OR|PR|PT|BT|OF|S1|51)\\b\\s*$", with: "", options: [.regularExpression, .caseInsensitive])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !sach.isEmpty {
                    cacDongSach.append(sach)
                }
            }

            let loai: LoaiChiTieuThiDua
            if coBadgeSL && !coBadgeDT && !coSoThapPhan {
                loai = .soLuong
            } else if coBadgeDT && !coBadgeSL {
                loai = .doanhThu
            } else if coSoThapPhan {
                loai = .doanhThu
            } else if coBadgeSL {
                loai = .soLuong
            } else {
                loai = .doanhThu
            }

            let chuoiTenGop = cacDongSach.joined(separator: " ")
            let tenSach = KhoDuLieu.chuanHoaTenMonThiDuaChuan(chuoiTenGop)
            return (tenSach, loai)
        }

        struct DongTam6Cot {
            var tenSach: String
            var loai: LoaiChiTieuThiDua
            var soTH: Double
            var soTG: Double
            var phanTramHT: Double?
            var phanTramDuKien: Double?
        }

        var danhSachTam: [DongTam6Cot] = []

        // MARK: Phương án chính — Tìm dấu + trong Cột 1 + Đường kẻ ô lưới + Tách 5 ảnh cột độc lập
        if let anhGoc = anh, let cgGoc = anhGoc.cgImage, cgGoc.width > 120, cgGoc.height > 120 {
            let w0 = cgGoc.width
            let h0 = cgGoc.height
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            var raw0 = [UInt8](repeating: 0, count: w0 * h0 * 4)
            if let ctx0 = CGContext(
                data: &raw0,
                width: w0,
                height: h0,
                bitsPerComponent: 8,
                bytesPerRow: w0 * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) {
                ctx0.draw(cgGoc, in: CGRect(x: 0, y: 0, width: w0, height: h0))

                // 1. Dò tất cả dấu + trong cột đầu tiên (x: 0.022 .. 0.049)
                // Bên trong dấu + có nét chữ thập màu đen/xám đậm (minGray <= 55..140), trong khi nền, vòng tròn và watermark đều >= 210
                let xPlus0 = max(1, Int((CGFloat(w0) * 0.022).rounded()))
                let xPlus1 = min(w0 - 2, Int((CGFloat(w0) * 0.049).rounded()))
                let yBatDauPlus = max(6, Int((CGFloat(h0) * max(0.018, ySauHeader - 0.004)).rounded()))

                var cacYCoDauCong: [Int] = []
                if xPlus1 > xPlus0 {
                    for y in yBatDauPlus..<(h0 - 3) {
                        var minGray = 255
                        let base = y * w0 * 4
                        for x in xPlus0...xPlus1 {
                            let off = base + x * 4
                            let g = (Int(raw0[off]) + Int(raw0[off + 1]) + Int(raw0[off + 2])) / 3
                            if g < minGray { minGray = g }
                        }
                        if minGray < 155 {
                            cacYCoDauCong.append(y)
                        }
                    }
                }

                let khoangGopPlus = max(4, h0 / 160)
                var cumPlus: [[Int]] = []
                for y in cacYCoDauCong {
                    if let cuoi = cumPlus.last?.last, (y - cuoi) <= khoangGopPlus {
                        cumPlus[cumPlus.count - 1].append(y)
                    } else {
                        cumPlus.append([y])
                    }
                }

                let caoToiThieuPlus = max(4, h0 / 260)
                let tamDauCong: [Double] = cumPlus.compactMap { cum in
                    guard let d = cum.first, let c = cum.last, (c - d + 1) >= caoToiThieuPlus else { return nil }
                    return Double(cum.reduce(0, +)) / Double(cum.count)
                }

                if tamDauCong.count >= 2 {
                    // 2. Tính độ tương phản dọc để tìm chính xác đường kẻ ngang trên và dưới của mỗi dấu +
                    let cacDaiKheX: [(CGFloat, CGFloat)] = [
                        (0.010, 0.023),
                        (0.330, 0.350),
                        (0.485, 0.505),
                        (0.635, 0.655),
                        (0.750, 0.770),
                        (0.865, 0.890),
                        (0.970, 0.988)
                    ]
                    var dsKheX: [Int] = []
                    for (b0, b1) in cacDaiKheX {
                        let xa = max(1, Int((CGFloat(w0) * b0).rounded()))
                        let xb = min(w0 - 2, Int((CGFloat(w0) * b1).rounded()))
                        if xb > xa {
                            for x in xa..<xb { dsKheX.append(x) }
                        }
                    }

                    var rowMed = [Double](repeating: 255.0, count: h0)
                    if !dsKheX.isEmpty {
                        var buf = [Double](repeating: 0.0, count: dsKheX.count)
                        for y in 0..<h0 {
                            let base = y * w0 * 4
                            for (idx, x) in dsKheX.enumerated() {
                                let off = base + x * 4
                                buf[idx] = Double(Int(raw0[off]) + Int(raw0[off + 1]) + Int(raw0[off + 2])) / 3.0
                            }
                            buf.sort()
                            rowMed[y] = buf[buf.count / 2]
                        }
                    }

                    func trungViSlice(_ s: ArraySlice<Double>) -> Double {
                        guard !s.isEmpty else { return 255.0 }
                        let a = s.sorted()
                        return a[a.count / 2]
                    }

                    var vContrast = [Double](repeating: 0.0, count: h0)
                    if h0 > 12 {
                        for y in 5..<(h0 - 5) {
                            let bgTren = trungViSlice(rowMed[(y - 5)...(y - 2)])
                            let bgDuoi = trungViSlice(rowMed[(y + 2)...(y + 5)])
                            vContrast[y] = max(bgTren, bgDuoi) - rowMed[y]
                        }
                    }

                    let leDocPlus = max(5, h0 / 180)
                    var bienNgangPx: [Int] = []

                    // Đường kẻ ngang phía trên dấu + đầu tiên
                    let yTren0Start = max(4, min(Int(CGFloat(h0) * max(0.035, ySauHeader - 0.012)), Int(tamDauCong[0]) - leDocPlus - 2))
                    let yTren0End = max(yTren0Start, Int(tamDauCong[0]) - leDocPlus)
                    var yBest0 = yTren0Start
                    var maxC0 = -999.0
                    for y in yTren0Start...yTren0End {
                        if vContrast[y] > maxC0 {
                            maxC0 = vContrast[y]
                            yBest0 = y
                        }
                    }
                    if maxC0 < 1.2 {
                        yBest0 = max(4, Int(tamDauCong[0]) - Int(Double(h0) * 0.019))
                    }
                    bienNgangPx.append(yBest0)

                    // Đường kẻ ngang nằm giữa dấu + thứ k và dấu + thứ k+1
                    for k in 0..<(tamDauCong.count - 1) {
                        let ya = min(h0 - 4, Int(tamDauCong[k]) + leDocPlus)
                        let yb = max(ya, Int(tamDauCong[k + 1]) - leDocPlus)
                        var yBest = (Int(tamDauCong[k]) + Int(tamDauCong[k + 1])) / 2
                        var maxC = -999.0
                        for y in ya...yb {
                            if vContrast[y] > maxC {
                                maxC = vContrast[y]
                                yBest = y
                            }
                        }
                        if maxC < 1.0 {
                            yBest = (Int(tamDauCong[k]) + Int(tamDauCong[k + 1])) / 2
                        }
                        bienNgangPx.append(yBest)
                    }

                    // Đường kẻ ngang phía dưới dấu + cuối cùng
                    let yCuoiStart = min(h0 - 3, Int(tamDauCong.last!) + leDocPlus)
                    let yCuoiEnd = min(h0 - 2, max(yCuoiStart, Int(tamDauCong.last!) + Int(Double(h0) * 0.055)))
                    var yBestCuoi = min(h0 - 2, Int(tamDauCong.last!) + Int(Double(h0) * 0.021))
                    var maxCCuoi = -999.0
                    for y in yCuoiStart...yCuoiEnd {
                        if vContrast[y] > maxCCuoi {
                            maxCCuoi = vContrast[y]
                            yBestCuoi = y
                        }
                    }
                    if maxCCuoi < 1.2 {
                        yBestCuoi = min(h0 - 2, Int(tamDauCong.last!) + Int(Double(h0) * 0.021))
                    }
                    bienNgangPx.append(yBestCuoi)

                    // 3. Tìm chính xác 5 đường kẻ dọc ngăn cách 6 cột
                    let yThap = max(0, bienNgangPx.first ?? 0)
                    let yCao = min(h0 - 1, bienNgangPx.last ?? (h0 - 1))
                    var colMed = [Double](repeating: 255.0, count: w0)
                    if yCao > yThap + 10 {
                        let buocY = max(1, (yCao - yThap) / 120)
                        var mauY: [Int] = []
                        var yCur = yThap
                        while yCur <= yCao {
                            mauY.append(yCur)
                            yCur += buocY
                        }
                        var bufC = [Double](repeating: 0.0, count: mauY.count)
                        for x in 0..<w0 {
                            for (idx, y) in mauY.enumerated() {
                                let off = (y * w0 + x) * 4
                                bufC[idx] = Double(Int(raw0[off]) + Int(raw0[off + 1]) + Int(raw0[off + 2])) / 3.0
                            }
                            bufC.sort()
                            colMed[x] = bufC[bufC.count / 2]
                        }
                    }

                    var hContrast = [Double](repeating: 0.0, count: w0)
                    if w0 > 12 {
                        for x in 5..<(w0 - 5) {
                            let bgTrai = trungViSlice(colMed[(x - 5)...(x - 2)])
                            let bgPhai = trungViSlice(colMed[(x + 2)...(x + 5)])
                            hContrast[x] = max(bgTrai, bgPhai) - colMed[x]
                        }
                    }

                    func timDuongKeDoc(tu b0: CGFloat, den b1: CGFloat, macDinh: CGFloat) -> CGFloat {
                        let xa = max(5, Int((CGFloat(w0) * b0).rounded()))
                        let xb = min(w0 - 6, Int((CGFloat(w0) * b1).rounded()))
                        guard xb > xa else { return macDinh }
                        var xBest = xa
                        var maxC = -999.0
                        for x in xa...xb {
                            if hContrast[x] > maxC {
                                maxC = hContrast[x]
                                xBest = x
                            }
                        }
                        return (maxC >= 1.5) ? (CGFloat(xBest) / CGFloat(w0)) : macDinh
                    }

                    let xv0: CGFloat = 0.052
                    let xv1: CGFloat = timDuongKeDoc(tu: 0.31, den: 0.37, macDinh: 0.340)
                    let xv2: CGFloat = timDuongKeDoc(tu: 0.47, den: 0.52, macDinh: 0.495)
                    let xv3: CGFloat = timDuongKeDoc(tu: 0.62, den: 0.67, macDinh: 0.645)
                    let xv4: CGFloat = timDuongKeDoc(tu: 0.73, den: 0.78, macDinh: 0.758)
                    let xv5: CGFloat = timDuongKeDoc(tu: 0.85, den: 0.90, macDinh: 0.875)

                    // Lọc các dòng hợp lệ (bỏ dòng đầu nếu bị thanh tiêu đề che khuất quá nửa < 0.021 chiều cao ảnh)
                    var cacDongHopLe: [(y0Px: Int, y1Px: Int, yTrenNorm: CGFloat, yDuoiNorm: CGFloat)] = []
                    for k in 0..<tamDauCong.count {
                        let y0 = bienNgangPx[k]
                        let y1 = bienNgangPx[k + 1]
                        let caoNorm = CGFloat(y1 - y0) / CGFloat(h0)
                        guard caoNorm >= 0.021 else { continue }
                        cacDongHopLe.append((
                            y0Px: y0,
                            y1Px: y1,
                            yTrenNorm: CGFloat(y0) / CGFloat(h0),
                            yDuoiNorm: CGFloat(y1) / CGFloat(h0)
                        ))
                    }

                    if cacDongHopLe.count >= 2 {
                        // 4. Phóng nét ảnh và kéo giãn tương phản mượt [70..210] -> [0..255] để tẩy sạch watermark mà giữ nguyên nét chữ
                        let heSo: Int = (w0 < 900) ? 3 : ((w0 < 1500) ? 2 : 1)
                        let w = w0 * heSo
                        let h = h0 * heSo
                        var cleanPixels = [UInt8](repeating: 255, count: w * h * 4)
                        if let ctxUp = CGContext(
                            data: &cleanPixels,
                            width: w,
                            height: h,
                            bitsPerComponent: 8,
                            bytesPerRow: w * 4,
                            space: colorSpace,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                        ) {
                            ctxUp.interpolationQuality = .high
                            ctxUp.draw(cgGoc, in: CGRect(x: 0, y: 0, width: w, height: h))

                            let xBatDauDK = Int((CGFloat(w) * xv4).rounded())
                            let xKetThucDK = Int((CGFloat(w) * xv5).rounded())
                            let tongPx = w * h
                            for i in 0..<tongPx {
                                let off = i * 4
                                let px = i % w
                                let r = Int(cleanPixels[off])
                                let g = Int(cleanPixels[off + 1])
                                let b = Int(cleanPixels[off + 2])

                                // Xoá ngôi sao màu vàng ⭐ ở đầu tên chương trình
                                if r >= 185 && g >= 135 && b < 155 && (r - b) > 45 && (g * 100) >= (r * 65) {
                                    cleanPixels[off] = 255
                                    cleanPixels[off + 1] = 255
                                    cleanPixels[off + 2] = 255
                                    continue
                                }

                                let cMax = max(r, max(g, b))
                                let cMin = min(r, min(g, b))
                                let doLech = cMax - cMin
                                let doSang = (px >= xBatDauDK && px < xKetThucDK && doLech >= 18) ? cMin : ((r + g + b) / 3)
                                if doSang >= 210 {
                                    cleanPixels[off] = 255
                                    cleanPixels[off + 1] = 255
                                    cleanPixels[off + 2] = 255
                                } else {
                                    let muc = UInt8(max(0, min(255, (doSang - 70) * 255 / 140)))
                                    cleanPixels[off] = muc
                                    cleanPixels[off + 1] = muc
                                    cleanPixels[off + 2] = muc
                                }
                            }

                            // 5. Tạo ảnh giãn dòng dọc (mỗi dòng k nằm trong đường kẻ ngang được cách nhau 60px trắng tinh)
                            let demDoc: Int = 60
                            var tongCaoGian: Int = demDoc
                            var thongTinDongGian: [(ySrc0: Int, caoSrc: Int, yDst0: Int, yDst1: Int)] = []
                            let catBien = max(2, heSo)
                            for d in cacDongHopLe {
                                let ys0 = min(h - 2, max(0, d.y0Px * heSo + catBien))
                                let ys1 = max(ys0 + 4, min(h, d.y1Px * heSo - catBien))
                                let cs = ys1 - ys0
                                thongTinDongGian.append((ySrc0: ys0, caoSrc: cs, yDst0: tongCaoGian, yDst1: tongCaoGian + cs))
                                tongCaoGian += cs + demDoc
                            }

                            var explodedPixels = [UInt8](repeating: 255, count: w * tongCaoGian * 4)
                            let bprW = w * 4
                            for tt in thongTinDongGian {
                                for dy in 0..<tt.caoSrc {
                                    let srcRow = (tt.ySrc0 + dy) * bprW
                                    let dstRow = (tt.yDst0 + dy) * bprW
                                    explodedPixels.replaceSubrange(dstRow..<(dstRow + bprW), with: cleanPixels[srcRow..<(srcRow + bprW)])
                                }
                            }

                            if let ctxExploded = CGContext(
                                data: &explodedPixels,
                                width: w,
                                height: tongCaoGian,
                                bitsPerComponent: 8,
                                bytesPerRow: bprW,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                            ), let cgExploded = ctxExploded.makeImage() {

                                // 6. Cắt thành 5 ảnh cột riêng biệt theo đúng đường kẻ dọc (xv0..xv5) và đọc OCR từng cột
                                let cacCotRanhGioi: [(b0: CGFloat, b1: CGFloat, laCotTen: Bool)] = [
                                    (xv0, xv1, true),
                                    (xv1, xv2, false),
                                    (xv2, xv3, false),
                                    (xv3, xv4, false),
                                    (xv4, xv5, false)
                                ]

                                var ketQuaTungCot = Array(
                                    repeating: Array(repeating: [String](), count: cacDongHopLe.count),
                                    count: 5
                                )

                                for (chiSoCot, cot) in cacCotRanhGioi.enumerated() {
                                    let xc0 = min(w - 2, max(0, Int((CGFloat(w) * cot.b0).rounded()) + catBien))
                                    let xc1 = max(xc0 + 4, min(w, Int((CGFloat(w) * cot.b1).rounded()) - catBien))
                                    guard let cgCot = cgExploded.cropping(to: CGRect(x: xc0, y: 0, width: xc1 - xc0, height: tongCaoGian)) else {
                                        continue
                                    }

                                    var obsDaSapXep: [(yPx: CGFloat, xPx: CGFloat, chu: String)] = []
                                    let req = VNRecognizeTextRequest { r, _ in
                                        guard let list = r.results as? [VNRecognizedTextObservation] else { return }
                                        for obs in list {
                                            guard let top = obs.topCandidates(1).first else { continue }
                                            let raw = top.string.trimmingCharacters(in: .whitespacesAndNewlines)
                                            guard !raw.isEmpty else { continue }
                                            let box = obs.boundingBox
                                            let yTren = 1.0 - box.origin.y - box.size.height
                                            let lines = raw.components(separatedBy: .newlines)
                                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                                .filter { !$0.isEmpty }
                                            let caoM = box.size.height / CGFloat(max(1, lines.count))
                                            for (i, line) in lines.enumerated() {
                                                let yTamPx = (yTren + (CGFloat(i) + 0.5) * caoM) * CGFloat(tongCaoGian)
                                                obsDaSapXep.append((yPx: yTamPx, xPx: box.origin.x, chu: line))
                                            }
                                        }
                                    }
                                    req.recognitionLevel = .accurate
                                    req.usesLanguageCorrection = cot.laCotTen
                                    if cot.laCotTen {
                                        req.recognitionLanguages = ["vi-VN", "en-US"]
                                    }
                                    req.minimumTextHeight = 0.003

                                    let handler = VNImageRequestHandler(cgImage: cgCot, orientation: anhGoc.cgImageOrientation, options: [:])
                                    try? handler.perform([req])

                                    obsDaSapXep.sort {
                                        if abs($0.yPx - $1.yPx) < 8.0 { return $0.xPx < $1.xPx }
                                        return $0.yPx < $1.yPx
                                    }

                                    let nuaDem = CGFloat(demDoc) * 0.46
                                    for item in obsDaSapXep {
                                        for (idxDong, tt) in thongTinDongGian.enumerated() {
                                            if item.yPx >= (CGFloat(tt.yDst0) - nuaDem) && item.yPx <= (CGFloat(tt.yDst1) + nuaDem) {
                                                ketQuaTungCot[chiSoCot][idxDong].append(item.chu)
                                                break
                                            }
                                        }
                                    }
                                }

                                // 7. Ghép dữ liệu 5 ô của từng dòng k (kèm đối chiếu dự phòng với phanTuGocDonDong nếu ô nào bị mờ)
                                for (idxDong, dongInfo) in cacDongHopLe.enumerated() {
                                    let chuoiCot2 = lamSachChuoi(ketQuaTungCot[1][idxDong].joined(separator: " "))
                                    let chuoiCot3 = lamSachChuoi(ketQuaTungCot[2][idxDong].joined(separator: " "))
                                    let chuoiCot4 = lamSachChuoi(ketQuaTungCot[3][idxDong].joined(separator: " "))
                                    let chuoiCot5 = lamSachChuoi(ketQuaTungCot[4][idxDong].joined(separator: " "))

                                    var th = trichSoHopLe(chuoiCot2).first
                                    var tg = trichSoHopLe(chuoiCot3).first
                                    var ht = trichSoHopLe(chuoiCot4).first
                                    var dk = trichSoHopLe(chuoiCot5).first
                                    var coThapPhan = chuoiCot2.range(of: "\\d+[.]\\d{1,2}\\b", options: .regularExpression) != nil ||
                                                     chuoiCot3.range(of: "\\d+[.]\\d{1,2}\\b", options: .regularExpression) != nil

                                    if th == nil || tg == nil {
                                        let ptHangGoc = phanTuGocDonDong.filter {
                                            let yTam = $0.y + $0.cao / 2.0
                                            return yTam >= (dongInfo.yTrenNorm - 0.002) && yTam <= (dongInfo.yDuoiNorm + 0.002) && $0.x >= (xv1 - 0.01)
                                        }.sorted { $0.x < $1.x }
                                        for pt in ptHangGoc {
                                            let s = lamSachChuoi(pt.chu)
                                            for tk in s.components(separatedBy: .whitespaces) where !tk.isEmpty {
                                                if let v = trichSoHopLe(tk).first {
                                                    if tk.contains("%") {
                                                        if ht == nil { ht = v }
                                                        else if dk == nil { dk = v }
                                                    } else {
                                                        if tk.range(of: "\\d+[.]\\d{1,2}\\b", options: .regularExpression) != nil {
                                                            coThapPhan = true
                                                        }
                                                        if th == nil { th = v }
                                                        else if tg == nil { tg = v }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    guard th != nil || tg != nil else { continue }

                                    var (tenSach, loai) = nhanDienTenVaDonVi(tu: ketQuaTungCot[0][idxDong], coSoThapPhan: coThapPhan)
                                    if tenSach.count < 2 || !KhoDuLieu.laTenMonThiDuaChuanDMX(tenSach) {
                                        let ptTenGoc = phanTuGocDonDong.filter {
                                            let yTam = $0.y + $0.cao / 2.0
                                            return $0.x < xv1 && yTam >= (dongInfo.yTrenNorm - 0.002) && yTam <= (dongInfo.yDuoiNorm + 0.002)
                                        }.sorted {
                                            let y1 = $0.y + $0.cao / 2.0
                                            let y2 = $1.y + $1.cao / 2.0
                                            if abs(y1 - y2) < 0.009 { return $0.x < $1.x }
                                            return y1 < y2
                                        }.map(\.chu)
                                        let (tenGoc, loaiGoc) = nhanDienTenVaDonVi(tu: ptTenGoc, coSoThapPhan: coThapPhan)
                                        if KhoDuLieu.laTenMonThiDuaChuanDMX(tenGoc) || tenSach.count < 2 {
                                            tenSach = tenGoc
                                            loai = loaiGoc
                                        }
                                    }

                                    guard tenSach.count >= 2, !laTenTheDoanhThuKhongPhaiThiDua(tenSach) else { continue }

                                    var soTH = th ?? 0.0
                                    var soTG = tg ?? 0.0

                                    if let hVal = ht, hVal > 100.0, soTG > 0, soTH > 0, abs((soTH / soTG) * 100.0 - (hVal / 10.0)) <= 1.2 {
                                        ht = hVal / 10.0
                                    }
                                    if let hVal = ht, hVal > 0.05 {
                                        if th == nil && soTG > 0 {
                                            let uocTH = soTG * (hVal / 100.0)
                                            soTH = (loai == .soLuong) ? uocTH.rounded() : ((uocTH * 100).rounded() / 100)
                                        } else if tg == nil && soTH > 0 {
                                            let uocTG = soTH / (hVal / 100.0)
                                            soTG = (loai == .soLuong) ? uocTG.rounded() : ((uocTG * 100).rounded() / 100)
                                        } else if soTG > 0 && soTH > 0 {
                                            let htTinh = (soTH / soTG) * 100.0
                                            if abs(htTinh - hVal) > max(1.8, hVal * 0.08) {
                                                var daSua = false
                                                for d in 1...9 {
                                                    for heSo in [100.0, 1000.0, 10.0] {
                                                        let tgThu = Double(d) * heSo + soTG
                                                        if abs((soTH / tgThu) * 100.0 - hVal) <= 0.75 {
                                                            soTG = ((tgThu * 100).rounded() / 100)
                                                            daSua = true
                                                            break
                                                        }
                                                    }
                                                    if daSua { break }
                                                }
                                            }
                                        }
                                    }

                                    if soTG > 0 && soTH >= 0 {
                                        let htChuan = ((soTH / soTG) * 1000.0).rounded() / 10.0
                                        if ht == nil || abs((ht ?? 0) - htChuan) > 1.2 {
                                            ht = htChuan
                                        }
                                    }

                                    danhSachTam.append(
                                        DongTam6Cot(
                                            tenSach: tenSach,
                                            loai: loai,
                                            soTH: soTH,
                                            soTG: soTG,
                                            phanTramHT: ht,
                                            phanTramDuKien: dk
                                        )
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        // MARK: Dự phòng khi không có UIImage gốc (quét từ phanTuGocDonDong)
        if danhSachTam.isEmpty {
            let xRanhGioiTenVaTH: CGFloat = 0.340
            let xRanhGioiTHVaTarget: CGFloat = 0.495
            let xRanhGioiTargetVaHT: CGFloat = 0.645
            let xRanhGioiHTVaDuKien: CGFloat = 0.762
            let xRanhGioiDuKienVaHangVung: CGFloat = 0.885

            var cacYSo: [CGFloat] = []
            for pt in phanTuGocDonDong {
                guard pt.cao <= 0.036 else { continue }
                let yTam = pt.y + pt.cao / 2.0
                guard yTam > ySauHeader + 0.002 && yTam < 0.995 else { continue }
                let xTam = pt.x + min(pt.rong, 0.16) / 2.0
                guard xTam >= xRanhGioiTenVaTH && xTam < xRanhGioiDuKienVaHangVung else { continue }
                if !trichSoHopLe(pt.chu).isEmpty {
                    cacYSo.append(yTam)
                }
            }
            cacYSo.sort()

            var cacCumHang: [(yTB: CGFloat, cacY: [CGFloat])] = []
            for y in cacYSo {
                if let idx = cacCumHang.indices.last, abs(y - cacCumHang[idx].yTB) < 0.011 {
                    cacCumHang[idx].cacY.append(y)
                    cacCumHang[idx].yTB = cacCumHang[idx].cacY.reduce(0, +) / CGFloat(cacCumHang[idx].cacY.count)
                } else {
                    cacCumHang.append((yTB: y, cacY: [y]))
                }
            }
            let cacHangY = cacCumHang.map(\.yTB)
            for (k, yHang) in cacHangY.enumerated() {
                if k == 0 && (yHang - ySauHeader) < 0.015 { continue }
                let kcTren: CGFloat = (k == 0) ? max(0.016, yHang - ySauHeader) : (yHang - cacHangY[k - 1])
                let kcDuoi: CGFloat = (k + 1 < cacHangY.count) ? (cacHangY[k + 1] - yHang) : max(0.020, 0.994 - yHang)
                let nuaCao = min(max(0.015, min(kcTren, kcDuoi) * 0.56), 0.042)
                let yTren = (k == 0) ? max(ySauHeader, yHang - nuaCao) : max((cacHangY[k - 1] + yHang) / 2.0, yHang - nuaCao)
                let yDuoi = (k + 1 < cacHangY.count) ? min((yHang + cacHangY[k + 1]) / 2.0, yHang + nuaCao) : min(0.996, yHang + nuaCao)

                let ptSo = phanTuGocDonDong.filter {
                    let yTam = $0.y + $0.cao / 2.0
                    return yTam >= yTren && yTam <= yDuoi && ($0.x + min($0.rong, 0.14) / 2.0) >= xRanhGioiTenVaTH
                }.sorted { $0.x < $1.x }

                var th: Double?
                var tg: Double?
                var ht: Double?
                var dk: Double?
                var coThapPhan = false
                for pt in ptSo {
                    let s = lamSachChuoi(pt.chu)
                    if s.range(of: "\\d+[.]\\d{1,2}\\b", options: .regularExpression) != nil { coThapPhan = true }
                    let xTam = pt.x + min(pt.rong, 0.14) / 2.0
                    if let v = trichSoHopLe(s).first {
                        if xTam < xRanhGioiTHVaTarget && th == nil { th = v }
                        else if xTam >= xRanhGioiTHVaTarget && xTam < xRanhGioiTargetVaHT && tg == nil { tg = v }
                        else if xTam >= xRanhGioiTargetVaHT && xTam < xRanhGioiHTVaDuKien && ht == nil { ht = v }
                        else if xTam >= xRanhGioiHTVaDuKien && dk == nil { dk = v }
                    }
                }
                guard th != nil || tg != nil else { continue }
                let ptTen = phanTuGocDonDong.filter {
                    let yTam = $0.y + $0.cao / 2.0
                    return $0.x < xRanhGioiTenVaTH && yTam >= yTren && yTam <= yDuoi
                }.sorted {
                    let y1 = $0.y + $0.cao / 2.0
                    let y2 = $1.y + $1.cao / 2.0
                    if abs(y1 - y2) < 0.009 { return $0.x < $1.x }
                    return y1 < y2
                }.map(\.chu)
                let (tenSach, loai) = nhanDienTenVaDonVi(tu: ptTen, coSoThapPhan: coThapPhan)
                guard tenSach.count >= 2, !laTenTheDoanhThuKhongPhaiThiDua(tenSach) else { continue }
                danhSachTam.append(DongTam6Cot(tenSach: tenSach, loai: loai, soTH: th ?? 0, soTG: tg ?? 0, phanTramHT: ht, phanTramDuKien: dk))
            }
        }

        // Hậu kiểm hệ số % HT Dự kiến toàn bảng để khôi phục chính xác các ô chữ màu bị mờ
        var tyLeDK_DT: [Double] = []
        var tyLeDK_SL: [Double] = []
        for d in danhSachTam where d.soTG > 0 && d.soTH > 0 {
            let htChinhXac = (d.soTH / d.soTG) * 100.0
            if let db = d.phanTramDuKien, htChinhXac >= 2.0 {
                let r = db / htChinhXac
                if r >= 1.02 && r <= 12.0 {
                    if d.loai == .soLuong {
                        tyLeDK_SL.append(r)
                    } else {
                        tyLeDK_DT.append(r)
                    }
                }
            }
        }
        tyLeDK_DT.sort()
        tyLeDK_SL.sort()
        let heSoDT: Double? = tyLeDK_DT.isEmpty ? nil : tyLeDK_DT[tyLeDK_DT.count / 2]
        let heSoSL: Double? = tyLeDK_SL.isEmpty ? heSoDT : tyLeDK_SL[tyLeDK_SL.count / 2]

        var danhSachKetQua: [DongThiDua] = []
        for var d in danhSachTam {
            if d.soTG > 0 {
                if d.soTH <= 0.0001 {
                    d.phanTramHT = 0.0
                    d.phanTramDuKien = 0.0
                } else if let heSo = (d.loai == .soLuong ? (heSoSL ?? heSoDT) : (heSoDT ?? heSoSL)), heSo > 1.0 {
                    let htChinhXac = (d.soTH / d.soTG) * 100.0
                    let dkKyVong = ((htChinhXac * heSo) * 10.0).rounded() / 10.0
                    if d.phanTramDuKien == nil || abs(d.phanTramDuKien! - dkKyVong) > 3.0 {
                        d.phanTramDuKien = dkKyVong
                    }
                }
            }

            var duKienTinh: Double? = nil
            if let db = d.phanTramDuKien, d.soTG > 0 {
                let uocDK = d.soTG * (db / 100.0)
                duKienTinh = (d.loai == .soLuong) ? uocDK.rounded() : ((uocDK * 100).rounded() / 100)
            }

            let dong = DongThiDua(
                tenNganhHangGoc: d.tenSach,
                tenNganhHang: KhoDuLieu.apDungLocTuCaiDat(d.tenSach),
                loaiChiTieu: d.loai,
                thucHien: d.soTH,
                target: d.soTG,
                phanTramHTGoc: d.phanTramHT,
                phanTramDuBaoGoc: d.phanTramDuKien ?? d.phanTramHT,
                duKienGoc: duKienTinh
            )
            danhSachKetQua = KhoDuLieu.gopDanhSachThiDua(cu: danhSachKetQua, moi: [dong])
        }

        return danhSachKetQua
    }

    // MARK: - Bước 2A.0: Bộ phân tích Bảng Thi Đua 4-5 Cột (CHƯƠNG TRÌNH | THỰC HIỆN | TARGET NGÀY/THÁNG | % HT NGÀY/THÁNG)

    private func phanTichBangThiDua4Cot(phanTu: [PhanTuVanBan], watermark: String?) -> [DongThiDua] {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) || laAnhBangDoanhThuNhanVien(phanTu: phanTu) || laAnhLuoiTheThiDua(phanTu: phanTu) {
            return []
        }

        // Tự động phát hiện mã watermark 5 chữ số (như 54453) nếu xuất hiện lặp lại hoặc đi kèm tên người dùng
        var maWM = watermark
        if maWM == nil {
            var demMa5So: [String: Int] = [:]
            for pt in phanTu {
                let u = boDau(pt.chu)
                if let r = u.range(of: "\\b\\d{5}\\b", options: .regularExpression) {
                    let m = String(u[r])
                    demMa5So[m, default: 0] += (u.contains("NGUYEN") || u.contains("DUNG") || u.contains("THANH") ? 2 : 1)
                }
            }
            if let totNhat = demMa5So.max(by: { $0.value < $1.value }), totNhat.value >= 2 {
                maWM = totNhat.key
            }
        }

        // 1. Tìm dòng Header của bảng (CHƯƠNG TRÌNH | THỰC HIỆN | TARGET NGÀY/THÁNG | % HT NGÀY/THÁNG)
        let vungHeader = phanTu.filter { $0.y < 0.25 }
        let mocChuongTrinh = vungHeader.first { boDau($0.chu).contains("CHUONG TRINH") }
        let mocThucHien = vungHeader.first { pt in
            let u = boDau(pt.chu)
            return pt.x >= 0.25 && pt.x <= 0.58 && u.contains("THUC HIEN")
        }
        let mocTarget = vungHeader.first { pt in
            let u = boDau(pt.chu)
            return pt.x >= 0.46 && pt.x <= 0.78 && (u.contains("TARGET") || u.contains("ARGET") || u.contains("MUC TIEU"))
        }
        let mocHT = vungHeader.first { pt in
            let u = boDau(pt.chu)
            return pt.x >= 0.66 && (u.contains("% HT") || u.contains("HT NGAY") || u.contains("HT THANG") || u == "HT")
        }

        let cacYHeader = [mocChuongTrinh, mocThucHien, mocTarget, mocHT].compactMap { pt -> CGFloat? in
            guard let pt else { return nil }
            return pt.y + pt.cao
        }
        let ySauHeader: CGFloat = cacYHeader.isEmpty ? 0.012 : (cacYHeader.max()! + 0.004)

        // Xác định toạ độ X phân tách các cột:
        // - Cột 1 (CHƯƠNG TRÌNH + nhãn DT/SL): x < xRanhGioiTenVaTH (~0.34)
        // - Cột 2 (THỰC HIỆN): xRanhGioiTenVaTH ..< xRanhGioiTHVaTarget (~0.34 ..< 0.53)
        // - Cột 3 (TARGET NGÀY / TARGET): xRanhGioiTHVaTarget ..< xRanhGioiTargetVaHT (~0.53 ..< 0.72)
        // - Cột 4 (% HT NGÀY / % HT): >= xRanhGioiTargetVaHT (~0.72 .. 0.99)
        let xRanhGioiTenVaTH: CGFloat = 0.34
        let xRanhGioiTHVaTarget: CGFloat
        if let mth = mocThucHien, let mtg = mocTarget, mtg.x > mth.x {
            xRanhGioiTHVaTarget = max(0.49, min(0.56, (mth.x + mth.rong + mtg.x) / 2.0))
        } else {
            xRanhGioiTHVaTarget = 0.528
        }
        let xRanhGioiTargetVaHT: CGFloat = 0.72

        func lamSachChuoiWatermark(_ s: String) -> String {
            var kq = s
            if let wm = maWM, !wm.isEmpty {
                kq = kq.replacingOccurrences(of: wm, with: " ")
            }
            // Loại bỏ mã watermark 54453 hoặc cụm tên watermark bị dính vào ô
            kq = kq.replacingOccurrences(of: "\\b54453\\b", with: " ", options: .regularExpression)
            kq = kq.replacingOccurrences(of: "(?i)dũng\\s*nguyễn(\\s*thanh)?", with: " ", options: .regularExpression)
            kq = kq.replacingOccurrences(of: "(?i)nguyễn\\s*thanh", with: " ", options: .regularExpression)
            kq = kq.replacingOccurrences(of: "(?i)dung\\s*nguyen(\\s*thanh)?", with: " ", options: .regularExpression)
            return kq.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        func trichSoHopLeCotBang(_ raw: String) -> [Double] {
            let sach = lamSachChuoiWatermark(raw)
                .replacingOccurrences(of: "%", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sach.isEmpty else { return [] }
            // Không lấy dòng nếu có chữ cái tiếng Việt của tên ngành hàng
            let u = boDau(sach)
            if u.range(of: "[A-Z]{2,}", options: .regularExpression) != nil && u != "DT" && u != "SL" {
                return []
            }
            return trichCacSoTheThiDua(trong: sach).filter { val in
                if let wm = maWM, let wmVal = Double(wm), abs(val - wmVal) < 0.1 { return false }
                if abs(val - 54453) < 0.1 || abs(val - 5445) < 0.1 || abs(val - 4453) < 0.1 { return false }
                return val >= 0 && val < 50000
            }
        }

        // 2. Gom cụm toạ độ Y tâm của từng dòng dựa trên các con số ở Cột 2 (THỰC HIỆN), Cột 3 (TARGET) và huy hiệu DT/SL
        struct DiemNeoHang {
            let yTam: CGFloat
            let laSoCot2Hoac3: Bool
        }

        var cacDiemNeo: [DiemNeoHang] = []
        for pt in phanTu {
            let yTam = pt.y + pt.cao / 2.0
            guard yTam > ySauHeader && yTam < 0.992 else { continue }
            let xTam = pt.x + min(pt.rong, 0.20) / 2.0
            let uGon = boDau(pt.chu).replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)

            if xTam >= xRanhGioiTenVaTH && xTam < xRanhGioiTargetVaHT && !pt.chu.contains("%") {
                let cacSo = trichSoHopLeCotBang(pt.chu)
                if !cacSo.isEmpty {
                    cacDiemNeo.append(DiemNeoHang(yTam: yTam, laSoCot2Hoac3: true))
                }
            } else if xTam >= 0.19 && xTam <= xRanhGioiTenVaTH + 0.02 {
                if uGon == "DT" || uGon == "SL" || uGon == "5L" || uGon == "0T" || uGon == "OT" || uGon == "SI" {
                    cacDiemNeo.append(DiemNeoHang(yTam: yTam, laSoCot2Hoac3: false))
                }
            }
        }

        cacDiemNeo.sort { $0.yTam < $1.yTam }

        var cacCumHang: [(yTrungBinh: CGFloat, cacY: [CGFloat], coSo: Bool)] = []
        for neo in cacDiemNeo {
            if let idx = cacCumHang.indices.last, abs(neo.yTam - cacCumHang[idx].yTrungBinh) < 0.024 {
                cacCumHang[idx].cacY.append(neo.yTam)
                let tong = cacCumHang[idx].cacY.reduce(0, +)
                cacCumHang[idx].yTrungBinh = tong / CGFloat(cacCumHang[idx].cacY.count)
                if neo.laSoCot2Hoac3 {
                    cacCumHang[idx].coSo = true
                }
            } else {
                cacCumHang.append((yTrungBinh: neo.yTam, cacY: [neo.yTam], coSo: neo.laSoCot2Hoac3))
            }
        }

        let cacHangY = cacCumHang.filter(\.coSo).map(\.yTrungBinh)
        guard cacHangY.count >= 2 else { return [] }

        var danhSachKetQua: [DongThiDua] = []

        for (k, yHang) in cacHangY.enumerated() {
            let yTren: CGFloat = (k == 0)
                ? max(ySauHeader, yHang - 0.027)
                : ((cacHangY[k - 1] + yHang) / 2.0)
            let yDuoi: CGFloat = (k + 1 < cacHangY.count)
                ? ((yHang + cacHangY[k + 1]) / 2.0)
                : min(0.996, yHang + 0.028)

            let trongHang = phanTu.filter { pt in
                let yTam = pt.y + pt.cao / 2.0
                return yTam >= yTren && yTam <= yDuoi
            }
            guard !trongHang.isEmpty else { continue }

            // A. Đọc số THỰC HIỆN (Cột 2), TARGET (Cột 3) và % HT (Cột 4)
            var thucHien: Double?
            var target: Double?
            var phanTramHT: Double?
            var coSoThapPhan = false

            let phanTuSoPhai = trongHang
                .filter { ($0.x + min($0.rong, 0.20) / 2.0) >= xRanhGioiTenVaTH }
                .sorted { $0.x < $1.x }

            for pt in phanTuSoPhai {
                let chuSach = lamSachChuoiWatermark(pt.chu)
                guard !chuSach.isEmpty else { continue }
                let xTam = pt.x + min(pt.rong, 0.20) / 2.0

                if xTam < xRanhGioiTargetVaHT && !chuSach.contains("%") {
                    if chuSach.range(of: "\\d+[.,]\\d+", options: .regularExpression) != nil {
                        coSoThapPhan = true
                    }
                }

                let cacSo = trichSoHopLeCotBang(chuSach)
                guard !cacSo.isEmpty else { continue }

                if pt.x < xRanhGioiTHVaTarget && (pt.x + pt.rong) > (xRanhGioiTHVaTarget + 0.04) && cacSo.count >= 2 && !chuSach.contains("%") {
                    if thucHien == nil { thucHien = cacSo[0] }
                    if target == nil { target = cacSo[1] }
                } else if xTam >= xRanhGioiTenVaTH && xTam < xRanhGioiTHVaTarget && !chuSach.contains("%") {
                    if thucHien == nil { thucHien = cacSo[0] }
                } else if xTam >= xRanhGioiTHVaTarget && xTam < xRanhGioiTargetVaHT && !chuSach.contains("%") {
                    if target == nil { target = cacSo[0] }
                } else if xTam >= xRanhGioiTargetVaHT || chuSach.contains("%") {
                    if phanTramHT == nil { phanTramHT = cacSo[0] }
                }
            }

            if thucHien == nil && target == nil {
                continue
            }

            // B. Xác định ĐVT (DT hay SL) từ huy hiệu DT/SL hoặc định dạng số thập phân (.00)
            var coBadgeSL = false
            var coBadgeDT = false
            for pt in trongHang where pt.x < xRanhGioiTenVaTH + 0.02 {
                let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
                let uGon = u.replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
                if uGon == "SL" || uGon == "5L" || uGon == "SI" || u.hasSuffix(" SL") || u.hasSuffix(" 5L") {
                    coBadgeSL = true
                } else if uGon == "DT" || uGon == "0T" || uGon == "OT" || u.hasSuffix(" DT") || u.hasSuffix(" 0T") {
                    coBadgeDT = true
                }
            }

            let loai: LoaiChiTieuThiDua
            if coBadgeSL && !coBadgeDT {
                loai = .soLuong
            } else if coBadgeDT && !coBadgeSL {
                loai = .doanhThu
            } else {
                loai = coSoThapPhan ? .doanhThu : .soLuong
            }

            // C. Ghép tên Chương trình thi đua ở Cột 1 (x < xRanhGioiTenVaTH)
            let phanTuTen = trongHang.filter { pt in
                guard pt.x < xRanhGioiTenVaTH else { return false }
                let chuSach = lamSachChuoiWatermark(pt.chu)
                guard !chuSach.isEmpty else { return false }
                let u = boDau(chuSach)
                let uGon = u.replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)

                // Bỏ dấu '+' ở đầu dòng và huy hiệu DT / SL rời
                if uGon.isEmpty || uGon == "DT" || uGon == "SL" || uGon == "5L" || uGon == "0T" || uGon == "OT" || uGon == "SI" {
                    return false
                }
                if pt.x >= 0.21 && uGon.count <= 2 && (uGon.hasPrefix("D") || uGon.hasPrefix("S") || uGon.hasPrefix("0") || uGon.hasPrefix("5")) {
                    return false
                }
                if u.contains("CHUONG TRINH") || u.contains("THUC HIEN") || u.contains("TARGET") {
                    return false
                }
                if laChuoiRac(chuSach, watermark: maWM) {
                    return false
                }
                return true
            }.sorted { $0.y < $1.y }

            var cacDongTen: [(y: CGFloat, tu: [PhanTuVanBan])] = []
            for pt in phanTuTen {
                if let idx = cacDongTen.indices.last, abs(pt.y - cacDongTen[idx].y) < 0.013 {
                    cacDongTen[idx].tu.append(pt)
                } else {
                    cacDongTen.append((y: pt.y, tu: [pt]))
                }
            }

            var cacChuoiDong: [String] = cacDongTen.map { dong in
                let gop = dong.tu.sorted { $0.x < $1.x }.map { lamSachChuoiWatermark($0.chu) }.joined(separator: " ")
                return gop
                    .replacingOccurrences(of: "^[+]\\s*", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "\\s+(DT|SL|5L|0T|OT)\\s*$", with: "", options: [.regularExpression, .caseInsensitive])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }.filter { !$0.isEmpty }

            // Nếu trong hàng có dòng bắt đầu bằng "T11 - ..." thì loại bỏ mọi mảnh chữ bị cắt từ hàng phía trên (như "... nước nóng")
            if let viTriBatDauT = cacChuoiDong.firstIndex(where: {
                boDau($0).range(of: "^T\\d{1,2}\\b", options: .regularExpression) != nil
            }) {
                cacChuoiDong = Array(cacChuoiDong.suffix(from: viTriBatDauT))
                if cacChuoiDong.count >= 2 {
                    for idxDong in 1..<cacChuoiDong.count {
                        if boDau(cacChuoiDong[idxDong]).range(of: "^T\\d{1,2}\\b", options: .regularExpression) != nil {
                            cacChuoiDong = Array(cacChuoiDong.prefix(idxDong))
                            break
                        }
                    }
                }
            }

            let tenSach = lamSachTenChuongTrinh(cacChuoiDong.joined(separator: " "))
            guard tenSach.count >= 2, !laTenTheDoanhThuKhongPhaiThiDua(tenSach) else { continue }

            let soTH = thucHien ?? 0.0
            let soTG = target ?? 0.0

            let dong = DongThiDua(
                tenNganhHangGoc: tenSach,
                tenNganhHang: KhoDuLieu.apDungLocTuCaiDat(tenSach),
                loaiChiTieu: loai,
                thucHien: soTH,
                target: soTG,
                phanTramHTGoc: phanTramHT
            )
            danhSachKetQua = KhoDuLieu.gopDanhSachThiDua(cu: danhSachKetQua, moi: [dong])
        }

        return danhSachKetQua
    }

    // MARK: - Bước 2A.1: Bộ phân tích Lưới Thẻ Thi Đua 2 Cột (Hỗ trợ 1–8+ môn/ảnh, lọc sạch CE/ICT/DV, đối chiếu toán học & lọc trùng 100%)

    private func phanTichThiDuaLuoiThe2Cot(phanTu: [PhanTuVanBan], watermark: String?) -> [DongThiDua] {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) || laAnhBangDoanhThuNhanVien(phanTu: phanTu) {
            return []
        }
        guard laAnhLuoiTheThiDua(phanTu: phanTu) else {
            return []
        }

        let cacYHeader = phanTu.compactMap { pt -> CGFloat? in
            guard pt.y < 0.15 else { return nil }
            let u = boDau(pt.chu)
            if u.contains("DOANH THU HOP") || u.contains("HOP NHAT") || u.contains("CAP NHAT") ||
               u.contains("DUNG NGUYEN") || (watermark != nil && u.contains(watermark!)) {
                return pt.y + pt.cao
            }
            return nil
        }
        let yBatDauTrang: CGFloat = (cacYHeader.max() ?? -0.01) + 0.008

        // Tìm ranh giới giữa cột thẻ Trái và cột thẻ Phải
        let cacXDauCotPhai = phanTu.compactMap { pt -> CGFloat? in
            guard pt.x >= 0.48 && pt.x <= 0.65 else { return nil }
            let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
            if laDauTieuDeMonThiDua(u) ||
               u.contains("THUC HIEN") || u.contains("HT THANG") || u.contains("HT NGAY") ||
               (pt.chu.contains("%") && chuyenChuoiThanhSoDoanhThu(pt.chu) != nil) {
                return pt.x
            }
            return nil
        }
        let xRanhGioiCot: CGFloat
        if let minXPhai = cacXDauCotPhai.min() {
            xRanhGioiCot = max(0.490, min(0.535, minXPhai - 0.025))
        } else {
            xRanhGioiCot = 0.50
        }

        let theCotTrai = phanTichCotTheThiDua(
            phanTu: phanTu,
            xMin: 0.0,
            xMax: xRanhGioiCot,
            yBatDauTrang: max(0.002, yBatDauTrang),
            watermark: watermark
        )
        let theCotPhai = phanTichCotTheThiDua(
            phanTu: phanTu,
            xMin: xRanhGioiCot,
            xMax: 1.0,
            yBatDauTrang: max(0.002, yBatDauTrang),
            watermark: watermark
        )

        var ketQua: [DongThiDua] = []
        let soHang = max(theCotTrai.count, theCotPhai.count)
        for i in 0..<soHang {
            if i < theCotTrai.count {
                ketQua = KhoDuLieu.gopDanhSachThiDua(cu: ketQua, moi: [theCotTrai[i]])
            }
            if i < theCotPhai.count {
                ketQua = KhoDuLieu.gopDanhSachThiDua(cu: ketQua, moi: [theCotPhai[i]])
            }
        }
        return ketQua
    }

    private func phanTichCotTheThiDua(
        phanTu: [PhanTuVanBan],
        xMin: CGFloat,
        xMax: CGFloat,
        yBatDauTrang: CGFloat,
        watermark: String?
    ) -> [DongThiDua] {
        let phanTuCot = phanTu.filter { pt in
            let xTam = pt.x + min(pt.rong, 0.15) / 2.0
            return xTam >= xMin && xTam < xMax && pt.y >= yBatDauTrang && pt.y < 0.996
        }
        guard !phanTuCot.isEmpty else { return [] }

        let xTraiThuc = phanTuCot.map(\.x).min() ?? xMin
        let xPhaiThuc = phanTuCot.map { $0.x + min($0.rong, 0.15) }.max() ?? xMax
        let xGiua = (xTraiThuc + xPhaiThuc) / 2.0 - 0.015

        // Phát hiện tiền tố tháng chủ đạo trên cột/ảnh (ví dụ "T11")
        var tienToThang = "T11"
        for pt in phanTu {
            let u = boDau(pt.chu)
            if let r = u.range(of: "\\bT(1[0-2]|[1-9])\\b", options: .regularExpression) {
                tienToThang = String(u[r])
                break
            }
        }

        // 1. Gom các ứng viên đầu thẻ từ tiêu đề môn ("T11 - ...") hoặc huy hiệu ĐVT (DT/SL) ở góc phải trên của thẻ
        var ungVienDauThe: [CGFloat] = []
        for pt in phanTuCot {
            let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
            if pt.x >= xPhaiThuc - 0.13 && laBadgeDonViThe(u) {
                ungVienDauThe.append(pt.y)
            } else if pt.x < xGiua && laDauTieuDeMonThiDua(u) {
                ungVienDauThe.append(pt.y)
            }
        }
        ungVienDauThe.sort()

        var cacDauThe: [CGFloat] = []
        for y in ungVienDauThe {
            if let cuoi = cacDauThe.last, y - cuoi < 0.09 {
                cacDauThe[cacDauThe.count - 1] = min(cuoi, y)
            } else {
                cacDauThe.append(y)
            }
        }

        // 2. Gom cụm mốc dòng nhãn "THỰC HIỆN" / "TARGET" (mỗi thẻ có đúng 1 dòng nhãn này, thích ứng mọi bố cục 3–8 môn/ảnh)
        let rawMocTHTG = phanTuCot.compactMap { pt -> CGFloat? in
            let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
            if u.contains("THUC HIEN") || u.contains("THYUC HIEN") || u.contains("THC HIEN") ||
               (u.hasPrefix("TARGET") && !u.contains("TARGET TRON KY")) {
                return pt.y
            }
            return nil
        }.sorted()

        var cacYMocTHTG: [CGFloat] = []
        for y in rawMocTHTG {
            if let cuoi = cacYMocTHTG.last, abs(y - cuoi) < 0.04 {
                cacYMocTHTG[cacYMocTHTG.count - 1] = min(cuoi, y)
            } else {
                cacYMocTHTG.append(y)
            }
        }

        // Đảm bảo mỗi mốc THỰC HIỆN / TARGET đều có đúng 1 mốc đầu thẻ nằm giữa đáy thẻ trước và mốc hiện tại
        // (Không dùng ngưỡng cố định 0.24 để ảnh 3 môn hoặc 4 môn có thẻ cao ~0.48 không bao giờ bị cắt đôi thẻ)
        for (idxMoc, yMoc) in cacYMocTHTG.enumerated() {
            let yMinHopLe: CGFloat = (idxMoc == 0) ? yBatDauTrang : (cacYMocTHTG[idxMoc - 1] + 0.055)
            let daCoDauThe = cacDauThe.contains { yDau in
                yDau >= yMinHopLe && yDau < yMoc
            }
            if !daCoDauThe {
                let ySauTheTruoc: CGFloat = (idxMoc == 0) ? yBatDauTrang : (cacYMocTHTG[idxMoc - 1] + 0.09)
                let cacYPhanTu = phanTuCot.compactMap { pt -> CGFloat? in
                    (pt.y > ySauTheTruoc && pt.y < yMoc - 0.03) ? pt.y : nil
                }
                let yUocLuong = cacYPhanTu.min() ?? max(yBatDauTrang, yMoc - 0.12)
                cacDauThe.append(yUocLuong)
                cacDauThe.sort()
            }
        }

        guard !cacDauThe.isEmpty else { return [] }

        var danhSachThe: [DongThiDua] = []

        for (k, yDau) in cacDauThe.enumerated() {
            let yTrenThe: CGFloat = max(yBatDauTrang, yDau - 0.015)
            let yDuoiThe: CGFloat = (k + 1 < cacDauThe.count)
                ? (cacDauThe[k + 1] - 0.014)
                : 0.996

            let trongThe = phanTuCot.filter { $0.y >= yTrenThe && $0.y <= yDuoiThe }
            guard !trongThe.isEmpty else { continue }

            // Ghép các mảnh số % nằm trên cùng một dòng ở nửa trái thẻ (phòng trường hợp "115.4%" bị tách thành "11" và "5.4%")
            let cacPhanTuPhanTramTrai = trongThe.filter { pt in
                pt.y >= yDau + 0.015 && pt.x < xGiua && pt.chu.contains("%") && chuyenChuoiThanhSoDoanhThu(pt.chu) != nil
            }.sorted { $0.y < $1.y }

            func docPhanTramDayDu(tai ptPct: PhanTuVanBan) -> Double? {
                let cungDong = trongThe.filter { p in
                    p.x < xGiua && abs(p.y - ptPct.y) < 0.014 &&
                    p.chu.range(of: "^[+\\-−–—0-9.,%\\s]+$", options: .regularExpression) != nil
                }.sorted { $0.x < $1.x }
                let chuoiGop = cungDong.map { $0.chu.replacingOccurrences(of: " ", with: "") }.joined()
                return chuyenChuoiThanhSoDoanhThu(chuoiGop) ?? chuyenChuoiThanhSoDoanhThu(ptPct.chu)
            }

            let yBigPct: CGFloat = cacPhanTuPhanTramTrai.first?.y ?? (yDau + 0.08)
            let yBotPct: CGFloat = (cacPhanTuPhanTramTrai.count >= 2)
                ? cacPhanTuPhanTramTrai.last!.y
                : (yDuoiThe - 0.012)

            var phanTramDuBao = cacPhanTuPhanTramTrai.first.flatMap { docPhanTramDayDu(tai: $0) }
            var phanTramHT: Double? = (cacPhanTuPhanTramTrai.count >= 2)
                ? cacPhanTuPhanTramTrai.last.flatMap { docPhanTramDayDu(tai: $0) }
                : nil

            // Xác định ĐVT (DT hay SL) theo 3 tín hiệu độc lập:
            // 1. Nhãn "SL DỰ KIẾN" vs "DT DỰ KIẾN" ở góc dưới phải
            // 2. Huy hiệu "SL" vs "DT" ở góc trên phải
            // 3. Định dạng số thập phân (.XX) của Thực hiện / Target
            var coSLDuKien = false
            var coDTDuKien = false
            var coBadgeSL = false
            var coBadgeDT = false

            for pt in trongThe {
                let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
                let uGon = u.replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
                if u.contains("SL DU") || u.contains("SL DY") || uGon.hasPrefix("SLDU") || uGon.hasPrefix("SLDY") {
                    coSLDuKien = true
                } else if u.contains("DT DU") || u.contains("DT DY") || u.contains("OT DU") || u.contains("OT OU") || u.contains("DOT DU") {
                    coDTDuKien = true
                }
                if pt.y < yBigPct {
                    if uGon == "SL" || uGon == "5L" || uGon == "SI" || uGon == "ST" || uGon == "SE" ||
                       u.range(of: "\\b(SL|5L|SI|ST|SE)$", options: .regularExpression) != nil {
                        coBadgeSL = true
                    } else if uGon == "DT" || uGon == "0T" || uGon == "OT" || uGon == "PR" || uGon == "PRT" || uGon == "PT" || uGon == "OR" || uGon == "BT" ||
                              u.range(of: "\\b(DT|0T|OT|PR|PRT|PT|OR|BT)$", options: .regularExpression) != nil {
                        coBadgeDT = true
                    }
                }
            }

            // Giới hạn vùng tiêu đề thẻ: dừng ngay trước huy hiệu phân nhóm (CE, ICT, DV), dòng ghi chú phụ ("Chạy theo thương hiệu") hoặc số % lớn
            var yGioiHanTieuDe = yBigPct - 0.004
            for pt in trongThe where pt.y < yBigPct + 0.025 {
                let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
                if (pt.chu.contains("%") && pt.y >= yDau + 0.015) ||
                   (pt.y >= yDau + 0.016 && laBadgePhanNhomThe(u)) ||
                   u.contains("DU KIEN") ||
                   u.contains("HOAN THANH") ||
                   u.contains("HT NGAY") ||
                   u.contains("HT THANG") ||
                   ((u == "HOAN" || u == "THANH" || u == "HT" || u == "NGAY") && pt.x > xGiua) ||
                   u.contains("KHONG TINH") ||
                   u.contains("TINH HANG") ||
                   u.contains("CHAY THEO") ||
                   u.contains("THUONG HIEU") {
                    yGioiHanTieuDe = min(yGioiHanTieuDe, pt.y - 0.004)
                }
            }

            let phanTuTen = trongThe.filter { pt in
                guard pt.y >= yDau - 0.012 && pt.y <= yGioiHanTieuDe else { return false }
                let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
                let uGon = u.replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
                if laBadgeDonViThe(u) || laBadgePhanNhomThe(u) {
                    return false
                }
                if pt.x >= xPhaiThuc - 0.125 && uGon.count <= 3 {
                    return false
                }
                // Tuyệt đối không lấy các phần tử chỉ chứa toàn chữ số (như "11" do bước quét số phụ tách ra) hoặc tiền tố "T11" ngắn bị trùng vào tiêu đề thẻ
                if uGon.range(of: "^[0-9]+$", options: .regularExpression) != nil {
                    return false
                }
                if uGon.range(of: "^[T71IL]\\d{1,2}$", options: .regularExpression) != nil {
                    let coTieuDeDaiTrongThe = trongThe.contains { khac in
                        khac.chu != pt.chu &&
                        khac.y >= yDau - 0.012 &&
                        khac.y <= yGioiHanTieuDe &&
                        khac.rong > pt.rong + 0.025
                    }
                    if coTieuDeDaiTrongThe {
                        return false
                    }
                }
                if u.contains("KHONG TINH") || u.contains("TINH HANG") || u.contains("CHAY THEO") || u.contains("THUONG HIEU") {
                    return false
                }
                if let wm = watermark, u.contains(wm) || u.contains("DUNG NGUYEN") {
                    return false
                }
                return true
            }

            let sapXepY = phanTuTen.sorted { $0.y < $1.y }
            var cacDongTen: [(y: CGFloat, tu: [PhanTuVanBan])] = []
            for pt in sapXepY {
                if let idx = cacDongTen.indices.last, abs(pt.y - cacDongTen[idx].y) < 0.018 {
                    cacDongTen[idx].tu.append(pt)
                } else {
                    cacDongTen.append((y: pt.y, tu: [pt]))
                }
            }

            // Loại bỏ huy hiệu ĐVT (DT/SL) bị dính ở cuối từng dòng trước khi nối các dòng tiêu đề nhiều dòng
            let cacChuoiDong = cacDongTen.compactMap { dong -> String? in
                let gop = dong.tu.sorted { $0.x < $1.x }.map(\.chu).joined(separator: " ")
                let sach = gop.replacingOccurrences(
                    of: "\\s+\\b(DT|SL|5L|0T|OT|SI|ST|PR|PRT|PT|OR|SE|RI|BT)\\b\\s*$",
                    with: "",
                    options: [.regularExpression, .caseInsensitive]
                ).trimmingCharacters(in: .whitespacesAndNewlines)
                return sach.isEmpty ? nil : sach
            }

            let tenSach = KhoDuLieu.chuanHoaTenMonThiDuaChuan(
                cacChuoiDong.joined(separator: " "),
                tienToThangMacDinh: tienToThang
            )
            guard tenSach.count >= 2, !laTenTheDoanhThuKhongPhaiThiDua(tenSach) else { continue }

            let yMocTHTGTrongThe = trongThe.compactMap { pt -> CGFloat? in
                guard pt.y > yBigPct else { return nil }
                let u = boDau(pt.chu)
                if u.contains("THUC") || u.contains("HIEN") || u.contains("TARGET") || u.contains("ARGE") {
                    return pt.y
                }
                return nil
            }.min() ?? (yBigPct + 0.025)

            var coSoThapPhan = false
            let vungSoDuoiThanh = trongThe.filter { pt in
                guard pt.y >= yMocTHTGTrongThe + 0.008 && pt.y <= yDuoiThe else { return false }
                let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
                if u.contains("THUC") || u.contains("HIEN") || u.contains("TARGET") || u.contains("ARGE") ||
                   u.contains("NGAY") || u.contains("THANG") || u.contains("DU KIEN") || u.contains("DY KIEN") ||
                   u.contains("OU KIEN") || u.contains("KIEN") || u.contains("HOAN") || u.contains("THANH") ||
                   u == "HT" || u == "% HT" || u == ">" {
                    return false
                }
                if !pt.chu.contains("%") && pt.chu.range(of: "\\d+[.,]\\d+", options: .regularExpression) != nil {
                    coSoThapPhan = true
                }
                return !trichCacSoTheThiDua(trong: pt.chu).isEmpty
            }.sorted {
                if abs($0.y - $1.y) < 0.018 { return $0.x < $1.x }
                return $0.y < $1.y
            }

            var cacHangSo: [(y: CGFloat, phanTu: [PhanTuVanBan])] = []
            for pt in vungSoDuoiThanh {
                if let idx = cacHangSo.indices.last, abs(pt.y - cacHangSo[idx].y) < 0.026 {
                    cacHangSo[idx].phanTu.append(pt)
                } else {
                    cacHangSo.append((y: pt.y, phanTu: [pt]))
                }
            }

            var thucHien: Double?
            var target: Double?
            var duKien: Double?

            let cacYMocHang2 = trongThe.compactMap { pt -> CGFloat? in
                guard pt.y > yBigPct + 0.03 else { return nil }
                let u = boDau(pt.chu)
                if u.contains("HT THANG") || u.contains("DT DU") || u.contains("SL DU") || u.contains("DT DY") || u.contains("SL DY") {
                    return pt.y
                }
                return nil
            }
            let yMocHang2 = cacYMocHang2.min()

            for (chiSoHang, hang) in cacHangSo.enumerated() {
                let laHangDuKien: Bool
                if cacHangSo.count >= 2 {
                    laHangDuKien = (chiSoHang >= 1)
                } else if let yMoc2 = yMocHang2, hang.y > yMoc2 {
                    laHangDuKien = true
                } else if cacPhanTuPhanTramTrai.count >= 2 && abs(hang.y - yBotPct) < 0.025 {
                    laHangDuKien = true
                } else {
                    laHangDuKien = false
                }

                for pt in hang.phanTu.sorted(by: { $0.x < $1.x }) {
                    let cacSo = trichCacSoTheThiDua(trong: pt.chu)
                    guard !cacSo.isEmpty else { continue }

                    if !laHangDuKien {
                        if cacSo.count >= 2 && pt.rong > 0.16 && !pt.chu.contains("%") {
                            if thucHien == nil { thucHien = cacSo[0] }
                            if target == nil { target = cacSo[1] }
                        } else if let so = cacSo.first {
                            if pt.x < xGiua {
                                if !pt.chu.contains("%") && thucHien == nil {
                                    thucHien = so
                                }
                            } else {
                                if !pt.chu.contains("%") && target == nil {
                                    target = so
                                }
                            }
                        }
                    } else {
                        if cacSo.count >= 2 && pt.rong > 0.16 {
                            if phanTramHT == nil { phanTramHT = cacSo[0] }
                            if duKien == nil { duKien = cacSo[1] }
                        } else if let so = cacSo.first {
                            if pt.x < xGiua {
                                if phanTramHT == nil { phanTramHT = so }
                            } else if !pt.chu.contains("%") {
                                if duKien == nil { duKien = so }
                            }
                        }
                    }
                }
            }

            if thucHien == nil && target == nil && phanTramDuBao == nil && phanTramHT == nil && duKien == nil {
                continue
            }

            if phanTramHT == nil && duKien == nil {
                phanTramHT = phanTramDuBao
            }

            let loai: LoaiChiTieuThiDua
            if coSLDuKien && !coDTDuKien {
                loai = .soLuong
            } else if coDTDuKien && !coSLDuKien {
                loai = .doanhThu
            } else if coBadgeSL && !coBadgeDT {
                loai = .soLuong
            } else if coBadgeDT && !coBadgeSL {
                loai = .doanhThu
            } else {
                loai = coSoThapPhan ? .doanhThu : .soLuong
            }

            var soTH = thucHien ?? 0.0
            var soTG = target ?? 0.0
            let ptKiemTra = phanTramHT ?? phanTramDuBao

            // Đối chiếu toán học giữa Thực hiện, Target và % Hoàn thành để tự động khôi phục dấu âm hoặc chữ số bị mờ
            if let pt = ptKiemTra, abs(pt) > 0.05 {
                if thucHien == nil && soTG > 0 {
                    let uocTH = soTG * (pt / 100.0)
                    soTH = (loai == .soLuong) ? uocTH.rounded() : ((uocTH * 100).rounded() / 100)
                } else if target == nil && abs(soTH) > 0.0001 {
                    let uocTG = soTH / (pt / 100.0)
                    soTG = (loai == .soLuong) ? uocTG.rounded() : ((uocTG * 100).rounded() / 100)
                } else if soTG > 0 {
                    let ptTinh = (soTH / soTG) * 100.0
                    if abs(ptTinh - pt) > max(3.5, abs(pt) * 0.12) {
                        if pt < 0 && soTH > 0 && abs((-soTH / soTG) * 100.0 - pt) <= 1.5 {
                            soTH = -soTH
                        } else {
                            var daSuaTG = false
                            for d in 1...9 {
                                for heSo in [10.0, 100.0] {
                                    let tgThu = Double(d) * heSo + soTG
                                    if abs((soTH / tgThu) * 100.0 - pt) <= 1.2 {
                                        soTG = ((tgThu * 100).rounded() / 100)
                                        daSuaTG = true
                                        break
                                    }
                                }
                                if daSuaTG { break }
                            }
                            if !daSuaTG {
                                let uocTH = soTG * (pt / 100.0)
                                soTH = (loai == .soLuong) ? uocTH.rounded() : ((uocTH * 100).rounded() / 100)
                            }
                        }
                    }
                }
            }

            if phanTramDuBao == nil, let dk = duKien, soTG > 0.0001 {
                phanTramDuBao = ((dk / soTG) * 1000).rounded() / 10
            }

            let dong = DongThiDua(
                tenNganhHangGoc: tenSach,
                tenNganhHang: KhoDuLieu.apDungLocTuCaiDat(tenSach),
                loaiChiTieu: loai,
                thucHien: soTH,
                target: soTG,
                phanTramHTGoc: phanTramHT,
                phanTramDuBaoGoc: phanTramDuBao ?? phanTramHT,
                duKienGoc: duKien
            )
            danhSachThe = KhoDuLieu.gopDanhSachThiDua(cu: danhSachThe, moi: [dong])
        }

        return danhSachThe
    }

    private func trichCacSoTheThiDua(trong chuoi: String) -> [Double] {
        let sach = chuoi.trimmingCharacters(in: .whitespacesAndNewlines)
        if sach.count == 1 {
            let mapKyTuDon: [String: Double] = [
                "O": 0, "o": 0, "Q": 0, "D": 0, "°": 0,
                "I": 1, "l": 1,
                "Z": 2, "S": 5, "B": 8
            ]
            if let v = mapKyTuDon[sach] {
                return [v]
            }
        }
        if sach.count == 2,
           let first = sach.first,
           let last = sach.last,
           ["a", "I", "l", "|"].contains(String(first)),
           last.isNumber,
           let v = Double("1" + String(last)) {
            return [v]
        }
        return trichCacSo(trong: sach)
    }

    // MARK: - Bước 2A.2: Bộ phân tích bố cục Thi Đua 2 cột

    private struct DongAnh1Tam {
        var ten: String
        var loai: LoaiChiTieuThiDua
        var giaTriCot1: Double
    }

    private func trichThongTinChungThiDua(phanTu: [PhanTuVanBan]) -> (capNhatLuc: String?, thongTinDonVi: String?, watermark: String?) {
        var capNhatLuc: String?
        var thongTinDonVi: String?
        var maNhanVienWatermark: String?

        for pt in phanTu {
            if pt.chu.localizedCaseInsensitiveContains("Cập nhật lúc") || pt.chu.range(of: "\\d{2}:\\d{2}:\\d{2}", options: .regularExpression) != nil {
                if capNhatLuc == nil {
                    capNhatLuc = pt.chu.replacingOccurrences(of: "Cập nhật lúc:", with: "").trimmingCharacters(in: .whitespaces)
                } else if !capNhatLuc!.contains(pt.chu) {
                    capNhatLuc = "\(capNhatLuc!) \(pt.chu)"
                }
            }
            if maNhanVienWatermark == nil, pt.y < 0.16 {
                maNhanVienWatermark = timMaWatermarkAnToan(phanTu: [pt], yGioiHan: 0.16)
            }
            if pt.chu.hasPrefix("ĐML_") || pt.chu.hasPrefix("ĐMX_") || pt.chu.hasPrefix("TGDĐ_") {
                if thongTinDonVi == nil {
                    thongTinDonVi = pt.chu
                }
            }
        }
        return (capNhatLuc, thongTinDonVi, maNhanVienWatermark)
    }

    private func ghepCapAnhThiDua(
        phanTu1: [PhanTuVanBan],
        watermark1: String?,
        phanTu2: [PhanTuVanBan],
        watermark2: String?
    ) -> [DongThiDua] {
        let (laTarget1, dsAnh1) = trichXuatDongTuAnh1(phanTu: phanTu1, watermark: watermark1)
        let (laTarget2, cacSoAnh2) = trichXuatSoCotPhaiTuTrenXuong(phanTu: phanTu2, watermark: watermark2)

        guard !dsAnh1.isEmpty else {
            let (dsCu1, _, _, _) = phanTichThiDuaOffline(phanTu: phanTu1, tenNganhGoiY: nil)
            let (dsCu2, _, _, _) = phanTichThiDuaOffline(phanTu: phanTu2, tenNganhGoiY: nil)
            return KhoDuLieu.gopDanhSachThiDua(cu: dsCu1, moi: dsCu2)
        }

        let anh1LaTarget: Bool
        if let t1 = laTarget1, let t2 = laTarget2, t1 != t2 {
            anh1LaTarget = t1
        } else if let t1 = laTarget1 {
            anh1LaTarget = t1
        } else if let t2 = laTarget2 {
            anh1LaTarget = !t2
        } else {
            anh1LaTarget = true
        }

        var ketQua: [DongThiDua] = []
        for (i, d1) in dsAnh1.enumerated() {
            let soAnh1 = d1.giaTriCot1
            let soAnh2: Double = (i < cacSoAnh2.count) ? cacSoAnh2[i].giaTri : 0
            let dong = DongThiDua(
                tenNganhHangGoc: d1.ten,
                tenNganhHang: d1.ten,
                loaiChiTieu: d1.loai,
                thucHien: anh1LaTarget ? soAnh2 : soAnh1,
                target: anh1LaTarget ? soAnh1 : soAnh2
            )
            ketQua.append(dong)
        }
        return ketQua
    }

    private func phanTichThiDuaHaiCot(phanTu: [PhanTuVanBan], watermark: String?) -> [DongThiDua] {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) || laAnhBangDoanhThuNhanVien(phanTu: phanTu) { return [] }
        let (laTarget, dsAnh1) = trichXuatDongTuAnh1(phanTu: phanTu, watermark: watermark)
        guard !dsAnh1.isEmpty else { return [] }
        let laCotTarget = laTarget ?? true
        return dsAnh1.map { d in
            DongThiDua(
                tenNganhHangGoc: d.ten,
                tenNganhHang: d.ten,
                loaiChiTieu: d.loai,
                thucHien: laCotTarget ? 0 : d.giaTriCot1,
                target: laCotTarget ? d.giaTriCot1 : 0
            )
        }
    }

    private func trichXuatSoCotPhaiTuTrenXuong(
        phanTu: [PhanTuVanBan],
        watermark: String?
    ) -> (laCotTarget: Bool?, cacSo: [(y: CGFloat, giaTri: Double)]) {
        let vungHeader = phanTu.filter { $0.y > 0.08 && $0.y < 0.33 }
        let mocChuongTrinh = vungHeader.first { boDau($0.chu).contains("CHUONG TRINH") }
        let mocTarget = vungHeader.first { pt in
            let u = boDau(pt.chu)
            return pt.x > 0.50 && (u.contains("TARGET") || u.contains("ARGET"))
        }
        let mocThucHien = vungHeader.first { pt in
            let u = boDau(pt.chu)
            return pt.x > 0.50 && u.contains("THUC HIEN")
        }

        var laCotTarget: Bool?
        if let mt = mocTarget, let mth = mocThucHien {
            laCotTarget = mt.x >= mth.x
        } else if mocTarget != nil {
            laCotTarget = true
        } else if mocThucHien != nil {
            laCotTarget = false
        } else if phanTu.contains(where: { $0.y < 0.32 && $0.x > 0.55 && boDau($0.chu).contains("ARGET") }) {
            laCotTarget = true
        } else if phanTu.contains(where: { $0.y < 0.32 && $0.x > 0.55 && boDau($0.chu).contains("THUC HIEN") }) {
            laCotTarget = false
        }

        let yHeader = max(
            mocChuongTrinh?.y ?? 0,
            max(mocTarget?.y ?? 0, mocThucHien?.y ?? 0)
        )
        let yBatDau: CGFloat = (yHeader > 0.08) ? (yHeader + 0.015) : 0.21

        let ungVien = phanTu.compactMap { pt -> (y: CGFloat, x: CGFloat, giaTri: Double)? in
            guard (pt.x >= 0.64 || (pt.x >= 0.58 && pt.x + pt.rong >= 0.78)),
                  pt.y > yBatDau,
                  pt.y < 0.98 else {
                return nil
            }
            if let wm = watermark, pt.chu.contains(wm) { return nil }
            guard let so = chuyenTokenSoCotPhai(pt.chu) else { return nil }
            return (y: pt.y, x: pt.x, giaTri: so)
        }.sorted {
            if abs($0.y - $1.y) < 0.014 { return $0.x > $1.x }
            return $0.y < $1.y
        }

        var cacSoTheoHang: [(y: CGFloat, giaTri: Double)] = []
        for item in ungVien {
            if let last = cacSoTheoHang.last, abs(item.y - last.y) < 0.018 {
                continue
            }
            cacSoTheoHang.append((y: item.y, giaTri: item.giaTri))
        }

        return (laCotTarget, cacSoTheoHang)
    }

    private func trichXuatDongTuAnh1(
        phanTu: [PhanTuVanBan],
        watermark: String?
    ) -> (laCotTarget: Bool?, danhSach: [DongAnh1Tam]) {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) { return (nil, []) }
        let (laCotTarget, cacSoPhai) = trichXuatSoCotPhaiTuTrenXuong(phanTu: phanTu, watermark: watermark)
        guard !cacSoPhai.isEmpty else { return (laCotTarget, []) }

        let vungHeader = phanTu.filter { $0.y > 0.08 && $0.y < 0.33 }
        let mocChuongTrinh = vungHeader.first { boDau($0.chu).contains("CHUONG TRINH") }
        let mocTarget = vungHeader.first { pt in
            let u = boDau(pt.chu)
            return pt.x > 0.50 && (u.contains("TARGET") || u.contains("ARGET"))
        }
        let mocThucHien = vungHeader.first { pt in
            let u = boDau(pt.chu)
            return pt.x > 0.50 && u.contains("THUC HIEN")
        }
        let yHeader = max(
            mocChuongTrinh?.y ?? 0,
            max(mocTarget?.y ?? 0, mocThucHien?.y ?? 0)
        )
        let yBatDau: CGFloat = (yHeader > 0.08) ? (yHeader + 0.015) : 0.21

        var ketQua: [DongAnh1Tam] = []
        for (k, soHang) in cacSoPhai.enumerated() {
            let yTren: CGFloat = (k == 0) ? yBatDau : (cacSoPhai[k - 1].y + 0.008)
            let yDuoi: CGFloat = soHang.y + 0.012

            let phanTuTrongHang = phanTu.filter { pt in
                guard pt.x < 0.68 && pt.y > yTren && pt.y <= yDuoi else { return false }
                let u = boDau(pt.chu)
                if u.contains("CHUONG TRINH") || u.contains("CAN DICH") || u.contains("CHUA DAT") ||
                   u.contains("NGANH HANG") || u.contains("NHOM HANG") || u.contains("TAT CA (") {
                    return false
                }
                if let wm = watermark, u.contains(wm) || u.contains("DUNG NGUYEN") {
                    return false
                }
                return true
            }

            var coBadgeSL = false
            var coBadgeDT = false
            for pt in phanTuTrongHang {
                let u = boDau(pt.chu).trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                if u == "SL" || u == "5L" {
                    coBadgeSL = true
                } else if u == "DT" || u == "0T" {
                    coBadgeDT = true
                }
            }

            let phanTuTen = phanTuTrongHang.filter { pt in
                let chuSach = pt.chu.trimmingCharacters(in: .whitespacesAndNewlines)
                let u = boDau(chuSach)
                let uGon = u.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

                if uGon == "DT" || uGon == "SL" || uGon == "5L" || uGon == "0T" {
                    return false
                }
                if chuSach.hasPrefix("ĐML_") || chuSach.hasPrefix("ĐMX_") || chuSach.hasPrefix("TGDĐ_") ||
                   u.hasPrefix("DML_") || u.hasPrefix("DMX_") || u.hasPrefix("TGDD_") ||
                   u.contains("QUANG TRUNG") ||
                   u.range(of: "^[A-Z0-9]{2,5}_[A-Z0-9]{2,5}", options: .regularExpression) != nil {
                    return false
                }
                if laChuoiRac(chuSach, watermark: watermark) {
                    return false
                }
                if pt.x >= 0.58 && chuyenTokenSoCotPhai(chuSach) != nil {
                    return false
                }
                return true
            }.sorted {
                if abs($0.y - $1.y) < 0.012 { return $0.x < $1.x }
                return $0.y < $1.y
            }

            let chuoiGop = phanTuTen.map(\.chu).joined(separator: " ")
            let uGop = boDau(chuoiGop)

            let loai: LoaiChiTieuThiDua
            if uGop.contains("SO LUONG") || uGop.range(of: "\\bSL\\s*$", options: .regularExpression) != nil {
                loai = .soLuong
            } else if uGop.contains("DOANH THU") || uGop.range(of: "\\bDT\\s*$", options: .regularExpression) != nil {
                loai = .doanhThu
            } else if coBadgeSL && !coBadgeDT {
                loai = .soLuong
            } else {
                loai = .doanhThu
            }

            let tenSach = lamSachTenChuongTrinh(chuoiGop)
            guard tenSach.count >= 2, !laTenTheDoanhThuKhongPhaiThiDua(tenSach) else { continue }

            ketQua.append(DongAnh1Tam(ten: tenSach, loai: loai, giaTriCot1: soHang.giaTri))
        }

        return (laCotTarget, ketQua)
    }

    private func chuyenTokenSoCotPhai(_ chuoi: String) -> Double? {
        let s = chuoi
            .replacingOccurrences(of: "…", with: "")
            .replacingOccurrences(of: "...", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        if s.range(of: "[A-Za-zÀ-ỹĐđ_]", options: .regularExpression) != nil {
            return nil
        }
        guard s.range(of: "^[+\\-]?\\d+([.,]\\d+)*$", options: .regularExpression) != nil else {
            return nil
        }
        return chuyenChuoiThanhSoDoanhThu(s)
    }

    private func lamSachTenChuongTrinh(_ chuoi: String) -> String {
        KhoDuLieu.chuanHoaTenMonThiDuaChuan(chuoi)
    }

    // MARK: - Bước 2B: Phân tích ảnh Thực hiện Nhân viên theo Ngành hàng

    private func phanTichThiDuaNhanVienOffline(
        phanTu: [PhanTuVanBan],
        tenNganhGoiY: String? = nil,
        watermark: String? = nil
    ) -> KetQuaThiDuaNhanVienKhoi? {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) { return nil }

        var tenNganhHang = tenNganhGoiY ?? ""
        if tenNganhHang.isEmpty {
            if let mocTieuDe = phanTu.first(where: { pt in
                let u = boDau(pt.chu)
                return pt.y > 0.05 && pt.y < 0.20 && (
                    u.contains("DOANH THU") || u.contains("SO LUONG") || u.contains("THUC HIEN")
                )
            }) {
                let phanTuTen = phanTu.filter { pt in
                    pt.x < 0.31 && abs(pt.y - mocTieuDe.y) < 0.05 && !laChuoiRac(pt.chu, watermark: watermark)
                }.sorted {
                    if abs($0.y - $1.y) < 0.008 { return $0.x < $1.x }
                    return $0.y < $1.y
                }
                tenNganhHang = phanTuTen
                    .map(\.chu)
                    .joined(separator: " ")
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        let cacDongNV = phanTu.filter { pt in
            guard pt.x < 0.45 && pt.y > 0.13 && pt.y < 0.96 else { return false }
            let u = boDau(pt.chu)
            if u.contains("ONLINE") || u.contains("TONG CONG") || u == "TONG" { return false }
            guard let range = pt.chu.range(of: "\\b\\d{4,7}\\b", options: .regularExpression) else { return false }
            let ma = String(pt.chu[range])
            if let wm = watermark, ma == wm, u.contains("DUNG NGUYEN") { return false }
            return true
        }.sorted { $0.y < $1.y }

        var danhSach: [DongThiDuaNhanVienQuet] = []
        var daXetMa = Set<String>()

        for dong in cacDongNV {
            guard let range = dong.chu.range(of: "\\b\\d{4,7}\\b", options: .regularExpression) else { continue }
            let maNV = String(dong.chu[range])
            if daXetMa.contains(maNV) { continue }

            let hoTen = dong.chu
                .replacingOccurrences(of: maNV, with: "")
                .replacingOccurrences(of: "[-–—]", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let cungHang = phanTu.filter { pt in
                pt.x >= 0.28 && pt.x < 0.72 && abs(pt.y - dong.y) < 0.03
            }.sorted { $0.x < $1.x }

            var thucHien: Double?
            var target: Double = 0

            for pt in cungHang {
                if pt.chu.contains("/") {
                    let parts = pt.chu.components(separatedBy: "/")
                    if let v1 = chuyenChuoiThanhSoDoanhThu(parts[0]) {
                        thucHien = v1
                        if parts.count > 1, let v2 = chuyenChuoiThanhSoDoanhThu(parts[1]) {
                            target = v2
                        }
                        break
                    }
                }
                if let val = chuyenChuoiThanhSo(pt.chu, watermark: watermark) {
                    thucHien = val
                    break
                }
            }

            if let th = thucHien {
                let dsQL = KhoDuLieu.dungChung.layCaiDatAnToan().danhSachNhanVien
                if !dsQL.isEmpty {
                    guard let nvKhop = KhoDuLieu.khopNhanVienQuetVoiQuanLy(maQuet: maNV, tenQuet: hoTen, dsQuanLy: dsQL) else { continue }
                    guard !daXetMa.contains(nvKhop.maNV) else { continue }
                    daXetMa.insert(nvKhop.maNV)
                    danhSach.append(DongThiDuaNhanVienQuet(maNV: nvKhop.maNV, hoTen: nvKhop.hoTen, thucHien: th, target: target))
                } else {
                    daXetMa.insert(maNV)
                    danhSach.append(DongThiDuaNhanVienQuet(maNV: maNV, hoTen: hoTen, thucHien: th, target: target))
                }
            }
        }

        return KetQuaThiDuaNhanVienKhoi(
            tenNganhHang: tenNganhHang.isEmpty ? "Ngành hàng" : tenNganhHang,
            danhSach: danhSach
        )
    }

    // MARK: - Bước 2C: Phân tích ảnh Doanh thu hợp nhất theo Nhân viên

    /// Quét bổ sung vùng bảng Nhân viên (phóng đại 3x, không tẩy nét mảnh) để đọc trọn vẹn các con số 1 chữ số trong ô tròn (như 4, 5, 6, 9) và dòng đầu bảng
    private func quetBoSungBangNhanVienTuAnhGoc(
        anh: UIImage,
        yMin: CGFloat,
        yMax: CGFloat
    ) -> [PhanTuVanBan] {
        guard let cgGoc = anh.cgImage else { return [] }
        let rongAnh = CGFloat(cgGoc.width)
        let caoAnh = CGFloat(cgGoc.height)
        guard rongAnh > 40, caoAnh > 40 else { return [] }

        let yTren = max(0.0, min(0.95, yMin))
        let yDuoi = max(yTren + 0.05, min(1.0, yMax))
        let rectCrop = CGRect(
            x: 0,
            y: Int(floor(yTren * caoAnh)),
            width: Int(rongAnh),
            height: max(20, Int(ceil((yDuoi - yTren) * caoAnh)))
        )
        guard let cgCrop = cgGoc.cropping(to: rectCrop) else { return [] }

        let heSo = 3
        let rong = cgCrop.width * heSo
        let cao = cgCrop.height * heSo
        let bytesPerPixel = 4
        let bytesPerRow = rong * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let ctx = CGContext(
            data: nil,
            width: rong,
            height: cao,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return []
        }

        ctx.interpolationQuality = .high
        ctx.draw(cgCrop, in: CGRect(x: 0, y: 0, width: rong, height: cao))

        if let data = ctx.data {
            let ptr = data.bindMemory(to: UInt8.self, capacity: rong * cao * bytesPerPixel)
            let tongPixel = rong * cao
            let xGioiHanCotTrai = Int(CGFloat(rong) * 0.38)
            for i in 0..<tongPixel {
                let offset = i * 4
                let px = i % rong
                let r = Int(ptr[offset])
                let g = Int(ptr[offset + 1])
                let b = Int(ptr[offset + 2])
                let cMax = max(r, max(g, b))
                let cMin = min(r, min(g, b))
                let doLech = cMax - cMin
                // Giữ lại chữ đen/xám đậm, chữ đỏ số âm và chữ màu xanh dương của mã - tên nhân viên ở cột 1;
                // xoá sạch chữ chìm watermark màu xám nhạt (54453 / Dũng Nguyễn Thanh) và thanh màu thành nền trắng tinh
                let laChuDenXam = (cMax < 194 && doLech <= 32)
                let laChuIdXamCotTrai = (px < xGioiHanCotTrai && cMax < 218 && doLech <= 26)
                let laChuDoAm = (r > 130 && g < 105 && b < 105 && (r - max(g, b)) > 35)
                let laChuXanhCotTrai = (px < xGioiHanCotTrai && b >= 110 && (b - r) >= 16 && (b - g) >= 4 && r < 200)
                if laChuDenXam || laChuIdXamCotTrai || laChuDoAm || laChuXanhCotTrai {
                    let mucDam = UInt8(max(0, (cMin * 2) / 10))
                    ptr[offset] = mucDam
                    ptr[offset + 1] = mucDam
                    ptr[offset + 2] = mucDam
                } else {
                    ptr[offset] = 255
                    ptr[offset + 1] = 255
                    ptr[offset + 2] = 255
                }
            }
        }

        guard let cgTangNet = ctx.makeImage() else { return [] }
        let chieuCaoNorm = yDuoi - yTren
        var ketQua: [PhanTuVanBan] = []

        let yeuCau = VNRecognizeTextRequest { [weak self] req, _ in
            guard let self = self, let obsList = req.results as? [VNRecognizedTextObservation] else { return }
            for obs in obsList {
                let box = obs.boundingBox
                let yCropTren = 1.0 - box.origin.y - box.size.height
                let yFull = yTren + yCropTren * chieuCaoNorm
                let caoFull = box.size.height * chieuCaoNorm

                for ungVien in obs.topCandidates(3) {
                    let chu = ungVien.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !chu.isEmpty else { continue }
                    ketQua.append(
                        PhanTuVanBan(
                            chu: chu,
                            x: box.origin.x,
                            y: yFull,
                            rong: box.size.width,
                            cao: caoFull
                        )
                    )
                    if box.size.width > 0.16 {
                        let tokens = self.trichXuatCacPhanTuTokenSo(tu: ungVien, boxGoc: box)
                        for tk in tokens {
                            ketQua.append(
                                PhanTuVanBan(
                                    chu: tk.chu,
                                    x: tk.x,
                                    y: yTren + tk.y * chieuCaoNorm,
                                    rong: tk.rong,
                                    cao: tk.cao * chieuCaoNorm
                                )
                            )
                        }
                    }
                    break
                }
            }
        }
        yeuCau.recognitionLevel = .accurate
        yeuCau.usesLanguageCorrection = false
        yeuCau.minimumTextHeight = 0.004

        let yeuCauChu = VNRecognizeTextRequest { [weak self] req, _ in
            guard let self = self, let obsList = req.results as? [VNRecognizedTextObservation] else { return }
            for obs in obsList {
                guard let ungVien = obs.topCandidates(1).first else { continue }
                let chu = ungVien.string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !chu.isEmpty else { continue }
                let box = obs.boundingBox
                let yCropTren = 1.0 - box.origin.y - box.size.height
                let yFull = yTren + yCropTren * chieuCaoNorm
                let caoFull = box.size.height * chieuCaoNorm
                let cacDong = chu.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if cacDong.count > 1 {
                    let caoM = caoFull / CGFloat(cacDong.count)
                    for (i, d) in cacDong.enumerated() {
                        ketQua.append(PhanTuVanBan(chu: d, x: box.origin.x, y: yFull + CGFloat(i) * caoM, rong: box.size.width, cao: caoM))
                    }
                } else {
                    let cacCumTach = self.tachPhanTuTheoKhoangTrongNgang(tu: ungVien, boxGoc: box)
                    if cacCumTach.count >= 2 {
                        for cum in cacCumTach {
                            ketQua.append(
                                PhanTuVanBan(
                                    chu: cum.chu,
                                    x: cum.x,
                                    y: yTren + cum.y * chieuCaoNorm,
                                    rong: cum.rong,
                                    cao: cum.cao * chieuCaoNorm
                                )
                            )
                        }
                    } else {
                        ketQua.append(PhanTuVanBan(chu: chu, x: box.origin.x, y: yFull, rong: box.size.width, cao: caoFull))
                    }
                }
                if box.size.width > 0.16 {
                    let tokens = self.trichXuatCacPhanTuTokenSo(tu: ungVien, boxGoc: box)
                    for tk in tokens where tk.x >= 0.02 {
                        ketQua.append(
                            PhanTuVanBan(
                                chu: tk.chu,
                                x: tk.x,
                                y: yTren + tk.y * chieuCaoNorm,
                                rong: tk.rong,
                                cao: tk.cao * chieuCaoNorm
                            )
                        )
                    }
                }
            }
        }
        yeuCauChu.recognitionLevel = .accurate
        yeuCauChu.usesLanguageCorrection = true
        yeuCauChu.recognitionLanguages = ["vi-VN", "en-US"]
        yeuCauChu.minimumTextHeight = 0.004

        let handler = VNImageRequestHandler(cgImage: cgTangNet, orientation: anh.cgImageOrientation, options: [:])
        try? handler.perform([yeuCau])
        try? handler.perform([yeuCauChu])
        return ketQua
    }

    /// Đọc chính xác các con số 1 chữ số nằm đơn lẻ trong ô (SỐ LƯỢNG / DOANH THU QĐ) bằng cách xoá thanh màu nền, cắt sát chữ số và ghép cạnh nhãn neo "10X :" trên cùng một dòng ngang
    private func quetCacOThieuSoBangNhanVien(
        anh: UIImage,
        cacO: [(idO: Int, xMin: CGFloat, xMax: CGFloat, yMin: CGFloat, yMax: CGFloat)]
    ) -> [Int: Double] {
        guard !cacO.isEmpty, let cgGoc = anh.cgImage else { return [:] }
        let rongAnh = CGFloat(cgGoc.width)
        let caoAnh = CGFloat(cgGoc.height)
        guard rongAnh > 40, caoAnh > 40 else { return [:] }

        struct AnhODaLoc {
            let idO: Int
            let cgImage: CGImage
            let rongHienThi: CGFloat
        }

        var danhSachO: [AnhODaLoc] = []
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        for o in cacO {
            let x0 = max(0, min(Int(rongAnh) - 4, Int(floor(o.xMin * rongAnh))))
            let x1 = max(x0 + 4, min(Int(rongAnh), Int(ceil(o.xMax * rongAnh))))
            let y0 = max(0, min(Int(caoAnh) - 4, Int(floor(o.yMin * caoAnh))))
            let y1 = max(y0 + 4, min(Int(caoAnh), Int(ceil(o.yMax * caoAnh))))
            guard let crop = cgGoc.cropping(to: CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)) else { continue }

            let heSo = 3
            let w = crop.width * heSo
            let h = crop.height * heSo
            let bpr = w * 4
            guard let ctx = CGContext(
                data: nil,
                width: w,
                height: h,
                bitsPerComponent: 8,
                bytesPerRow: bpr,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { continue }

            ctx.interpolationQuality = .high
            ctx.draw(crop, in: CGRect(x: 0, y: 0, width: w, height: h))
            guard let data = ctx.data else { continue }
            let ptr = data.bindMemory(to: UInt8.self, capacity: w * h * 4)

            var xDauChu = w
            let yGiuaMin = max(0, h / 6)
            let yGiuaMax = min(h, (h * 5) / 6)

            for py in 0..<h {
                for px in 0..<w {
                    let offset = (py * w + px) * 4
                    let r = Int(ptr[offset])
                    let g = Int(ptr[offset + 1])
                    let b = Int(ptr[offset + 2])
                    let cMax = max(r, max(g, b))
                    let cMin = min(r, min(g, b))
                    let doLech = cMax - cMin
                    let laChuDen = (cMax < 185 && doLech <= 32)
                    let laChuDo = (r > 130 && g < 105 && b < 105 && (r - max(g, b)) > 35)
                    if laChuDen || laChuDo {
                        let mucDam = UInt8(max(0, (cMin * 3) / 10))
                        ptr[offset] = mucDam
                        ptr[offset + 1] = mucDam
                        ptr[offset + 2] = mucDam
                        if py >= yGiuaMin && py < yGiuaMax && px < xDauChu {
                            xDauChu = px
                        }
                    } else {
                        ptr[offset] = 255
                        ptr[offset + 1] = 255
                        ptr[offset + 2] = 255
                    }
                }
            }

            guard let cgFull = ctx.makeImage(), xDauChu < w - 2 else { continue }
            let xCat = max(0, xDauChu - 6)
            let cgCat = cgFull.cropping(to: CGRect(x: xCat, y: 0, width: w - xCat, height: h)) ?? cgFull
            let tyLe = CGFloat(cgCat.width) / CGFloat(max(1, cgCat.height))
            danhSachO.append(AnhODaLoc(idO: o.idO, cgImage: cgCat, rongHienThi: min(160, max(28, 44.0 * tyLe))))
        }

        guard !danhSachO.isEmpty else { return [:] }

        let caoDong: CGFloat = 64
        let kichThuocGhep = CGSize(width: CGFloat(280), height: CGFloat(danhSachO.count) * caoDong)
        let renderer = UIGraphicsImageRenderer(size: kichThuocGhep)
        let anhGhep = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: kichThuocGhep))
            let fontNeo = UIFont.monospacedDigitSystemFont(ofSize: 25, weight: .bold)
            for (idx, item) in danhSachO.enumerated() {
                let yTop = CGFloat(idx) * caoDong
                let chuNeo = "\(100 + idx) :" as NSString
                chuNeo.draw(
                    at: CGPoint(x: 12, y: yTop + 16),
                    withAttributes: [.font: fontNeo, .foregroundColor: UIColor.black]
                )
                let uiO = UIImage(cgImage: item.cgImage)
                uiO.draw(in: CGRect(x: 98, y: yTop + 10, width: item.rongHienThi, height: 44))
            }
        }

        guard let cgGhep = anhGhep.cgImage else { return [:] }
        var ketQua: [Int: Double] = [:]

        let yeuCau = VNRecognizeTextRequest { [weak self] req, _ in
            guard let self = self, let obsList = req.results as? [VNRecognizedTextObservation] else { return }
            for obs in obsList {
                let box = obs.boundingBox
                let yTamNorm = 1.0 - (box.origin.y + box.size.height / 2.0)
                let idx = Int(floor(yTamNorm * CGFloat(danhSachO.count)))
                guard idx >= 0 && idx < danhSachO.count else { continue }
                let maNeo = "\(100 + idx)"

                for ungVien in obs.topCandidates(3) {
                    let s = ungVien.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    let phanSauDauHaiCham: String
                    if let viTri = s.firstIndex(of: ":") {
                        phanSauDauHaiCham = String(s[s.index(after: viTri)...])
                    } else if box.origin.x > 0.28 {
                        phanSauDauHaiCham = s
                    } else {
                        phanSauDauHaiCham = s.replacingOccurrences(of: maNeo, with: "")
                    }
                    let sach = phanSauDauHaiCham.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let val = self.chuyenChuoiThanhSoDoanhThu(sach) ?? self.trichCacSoTheThiDua(trong: sach).first {
                        ketQua[danhSachO[idx].idO] = val
                        break
                    }
                }
            }
        }
        yeuCau.recognitionLevel = .accurate
        yeuCau.usesLanguageCorrection = false
        yeuCau.minimumTextHeight = 0.01

        let handler = VNImageRequestHandler(cgImage: cgGhep, orientation: .up, options: [:])
        try? handler.perform([yeuCau])
        return ketQua
    }

    /// Phát hiện các đường kẻ dọc chia cột của bảng Doanh thu Nhân viên (x ≈ 0.299, 0.463, 0.644, 0.827)
    private func timCacDuongKeDocBangNhanVien(anh: UIImage, yBatDau: CGFloat) -> [CGFloat] {
        guard let cg = anh.cgImage else { return [] }
        let w = cg.width
        let h = cg.height
        guard w > 120, h > 120 else { return [] }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bpr = w * 4
        var raw = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(
            data: &raw,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: bpr,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        let y0 = max(6, min(h - 20, Int(CGFloat(h) * max(0.02, yBatDau))))
        let y1 = max(y0 + 20, min(h - 4, Int(CGFloat(h) * 0.96)))

        let cacDaiTimKiem: [(CGFloat, CGFloat)] = [
            (0.25, 0.34),
            (0.42, 0.51),
            (0.60, 0.68),
            (0.78, 0.87)
        ]

        var ketQua: [CGFloat] = []
        for (xMinNorm, xMaxNorm) in cacDaiTimKiem {
            let xMin = max(2, Int(CGFloat(w) * xMinNorm))
            let xMax = min(w - 3, Int(CGFloat(w) * xMaxNorm))
            guard xMax > xMin else { continue }
            var totNhat: (x: Int, mad: Double)?
            for x in xMin...xMax {
                var mau: [Double] = []
                mau.reserveCapacity((y1 - y0) / 2 + 1)
                for y in stride(from: y0, to: y1, by: 2) {
                    let off = (y * w + x) * 4
                    let g = Double(Int(raw[off]) + Int(raw[off + 1]) + Int(raw[off + 2])) / 3.0
                    mau.append(g)
                }
                guard !mau.isEmpty else { continue }
                mau.sort()
                let med = mau[mau.count / 2]
                guard med >= 220.0 && med <= 249.5 else { continue }
                var lech = mau.map { abs($0 - med) }
                lech.sort()
                let mad70 = lech[min(lech.count - 1, (lech.count * 70) / 100)]
                if mad70 < 5.2 {
                    if totNhat == nil || mad70 < totNhat!.mad {
                        totNhat = (x, mad70)
                    }
                }
            }
            if let totNhat {
                ketQua.append(CGFloat(totNhat.x) / CGFloat(w))
            }
        }
        return ketQua.count == 4 ? ketQua : []
    }

    /// Phát hiện các đường kẻ ngang chia dòng nhân viên trong bảng BI mới (hỗ trợ cả ảnh CÓ tiêu đề và ảnh KHÔNG tiêu đề, kháng nhiễu watermark chéo)
    private func timCacDuongKeNgangBangNhanVien(anh: UIImage, coHeader: Bool, yHeaderMax: CGFloat) -> [CGFloat] {
        guard let cg = anh.cgImage else { return [] }
        let w = cg.width
        let h = cg.height
        guard w > 120, h > 120 else { return [] }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bpr = w * 4
        var raw = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(
            data: &raw,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: bpr,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        // Lấy mẫu tại các dải lề trống giữa các cột (nơi KHÔNG có cả chữ tiêu đề Header lẫn chữ tên NV hay chữ số)
        // kết hợp trung vị (median) + độ lệch phân vị 70% để kháng hoàn toàn watermark chéo (54453 / Dũng Nguyễn Thanh)
        let cacDaiX: [(CGFloat, CGFloat)] = [
            (0.005, 0.024),
            (0.282, 0.293), (0.303, 0.315),
            (0.448, 0.457), (0.467, 0.480),
            (0.630, 0.638), (0.648, 0.666),
            (0.766, 0.786),
            (0.813, 0.821), (0.831, 0.842),
            (0.978, 0.995)
        ]
        var danhSachX: [Int] = []
        for (b0, b1) in cacDaiX {
            let x0 = max(1, Int(CGFloat(w) * b0))
            let x1 = min(w - 2, Int(CGFloat(w) * b1))
            if x1 > x0 {
                for x in x0..<x1 {
                    danhSachX.append(x)
                }
            }
        }
        guard danhSachX.count >= 8 else { return [] }

        var rowMed = [Double](repeating: 255.0, count: h)
        var rowMad = [Double](repeating: 0.0, count: h)
        var isGrey = [Bool](repeating: false, count: h)

        var buffer = [Double](repeating: 0.0, count: danhSachX.count)
        for y in 0..<h {
            for (idx, x) in danhSachX.enumerated() {
                let off = (y * w + x) * 4
                buffer[idx] = Double(Int(raw[off]) + Int(raw[off + 1]) + Int(raw[off + 2])) / 3.0
            }
            buffer.sort()
            let med = buffer[buffer.count / 2]
            rowMed[y] = med
            var lech = buffer.map { abs($0 - med) }
            lech.sort()
            let mad = lech[min(lech.count - 1, (lech.count * 70) / 100)]
            rowMad[y] = mad
            if mad < 5.2 && med >= 212.0 && med <= 249.7 {
                isGrey[y] = true
            }
        }

        var cacCum: [[Int]] = []
        let khoangGop = max(5, h / 140)
        for y in 0..<h where isGrey[y] {
            if let cuoi = cacCum.last?.last, y - cuoi <= khoangGop {
                cacCum[cacCum.count - 1].append(y)
            } else {
                cacCum.append([y])
            }
        }

        var cacMocHeader: [CGFloat] = []
        var cacMoc: [CGFloat] = []
        let buocKiemTraTrang = max(3, h / 180)
        let gioiHanHeaderY = coHeader ? max(0.078, yHeaderMax + 0.016) : 0.0

        for cum in cacCum {
            guard let yTop = cum.first, let yBot = cum.last else { continue }
            let yBotNorm = CGFloat(yBot) / CGFloat(h)
            let spanNorm = CGFloat(yBot - yTop + 1) / CGFloat(h)

            if coHeader && yBotNorm <= gioiHanHeaderY {
                // Mọi cụm xám nằm trong vùng Tiêu đề (Header) chỉ lấy cạnh đáy cuối cùng làm mốc bắt đầu Hàng 1
                cacMocHeader.append(yBotNorm)
                continue
            }

            if spanNorm > 0.024 && yTop < Int(CGFloat(h) * 0.14) {
                cacMocHeader.append(yBotNorm)
            } else if spanNorm <= 0.024 {
                let yTren = max(0, yTop - buocKiemTraTrang)
                let yDuoi = min(h - 1, yBot + buocKiemTraTrang)
                if rowMed[yTren] >= 249.8 || rowMed[yDuoi] >= 249.8 {
                    let tbY = Double(cum.reduce(0, +)) / Double(cum.count)
                    cacMoc.append(CGFloat(tbY) / CGFloat(h))
                }
            }
        }

        if let dayHeader = cacMocHeader.max() {
            cacMoc.insert(dayHeader, at: 0)
        } else if coHeader && yHeaderMax > 0.02 {
            cacMoc.insert(yHeaderMax, at: 0)
        }

        guard !cacMoc.isEmpty else { return [] }

        // Nếu ảnh KHÔNG có tiêu đề: đảm bảo luôn có mốc 0.0 ở đầu cho Hàng 1 (Đinh Thị Quỳnh Nga)
        if !coHeader && cacMoc[0] >= 0.022 {
            cacMoc.insert(0.0, at: 0)
        } else if cacMoc[0] >= 0.045 && !coHeader {
            cacMoc.insert(0.0, at: 0)
        }

        if let cuoi = cacMoc.last, cuoi < 0.972 {
            cacMoc.append(1.0)
        }

        guard cacMoc.count >= 4 else { return [] }
        var hopLe: [CGFloat] = [cacMoc[0]]
        for i in 1..<cacMoc.count {
            let kc = cacMoc[i] - hopLe.last!
            if kc >= 0.032 && kc <= 0.118 {
                hopLe.append(cacMoc[i])
            } else if kc > 0.118 {
                // Nếu có 1 hoặc nhiều đường kẻ ngang bị mờ, tự động chia đều khoảng cách để không bao giờ bị đứt chuỗi dòng
                let soBuoc = max(2, min(8, Int((kc / 0.058).rounded())))
                let buoc = kc / CGFloat(soBuoc)
                let mocTruoc = hopLe.last!
                for b in 1..<soBuoc {
                    hopLe.append(mocTruoc + CGFloat(b) * buoc)
                }
                hopLe.append(cacMoc[i])
            }
        }
        return hopLe.count >= 4 ? hopLe : []
    }

    private func phanTichDoanhThuNhanVienOffline(phanTu: [PhanTuVanBan], anh: UIImage? = nil) -> [DoanhThuNhanVienItem] {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) { return [] }

        let dsQuanLy = KhoDuLieu.dungChung.layCaiDatAnToan().danhSachNhanVien
        let tapMaQuanLy = Set(dsQuanLy.map(\.maNV))

        // Mở rộng các phần tử từ lượt OCR ban đầu
        var phanTuGocMoRong: [PhanTuVanBan] = []
        for pt in phanTu {
            let cacDong = pt.chu.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if cacDong.count > 1 {
                let caoDong = pt.cao / CGFloat(cacDong.count)
                for (i, d) in cacDong.enumerated() {
                    phanTuGocMoRong.append(PhanTuVanBan(chu: d, x: pt.x, y: pt.y + CGFloat(i) * caoDong, rong: pt.rong, cao: caoDong))
                }
            } else {
                phanTuGocMoRong.append(pt)
            }
        }

        let laBangRong = phanTuGocMoRong.contains { pt in
            let u = boDau(pt.chu)
            return u.contains("DTLK") || u.contains("GIO CONG") || u.contains("NANG SUAT")
        }

        // Quét bổ sung độ phân giải cao 3x ĐÃ TẨY SẠCH WATERMARK (54453 / Dũng Nguyễn Thanh) trên toàn bộ chiều cao ảnh (0.0 -> 1.0)
        var boSungToanAnh: [PhanTuVanBan] = []
        if !laBangRong, let anh = anh {
            boSungToanAnh = quetBoSungBangNhanVienTuAnhGoc(anh: anh, yMin: 0.0, yMax: 1.0)
        }

        // Sử dụng nguồn đã tẩy sạch watermark (boSungToanAnh) làm nguồn chính để đọc số liệu (tránh hoàn toàn số rác "94" do watermark đè lên "215"),
        // chỉ ghép thêm phần tử cột 1 từ phanTuGocMoRong để hỗ trợ nhận diện tên/tiêu đề
        var phanTuMoRong: [PhanTuVanBan] = []
        if boSungToanAnh.count >= 8 {
            phanTuMoRong.append(contentsOf: boSungToanAnh)
            for pt in phanTuGocMoRong where pt.x < 0.32 || pt.y < 0.12 {
                phanTuMoRong.append(pt)
            }
        } else {
            phanTuMoRong = phanTuGocMoRong + boSungToanAnh
        }

        let nguonPhanTuSoSach: [PhanTuVanBan] = (boSungToanAnh.count >= 8) ? boSungToanAnh : phanTuMoRong

        func chuanHoaTieuDe(_ chu: String) -> String {
            boDau(chu)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let nguonTimHeader = phanTuGocMoRong + boSungToanAnh

        // Nhận diện chính xác các phần tử thuộc dòng Tiêu đề (Header) ở vùng đầu bảng (y < 0.18)
        let cacUngVienHeader = nguonTimHeader.filter { pt in
            guard pt.y < 0.18 else { return false }
            let chu = pt.chu
            if chu.range(of: "(?i)\\b(?:id|ld|1d|ia|iđ)\\s*[:.;\\-]?\\s*\\d{3,7}", options: .regularExpression) != nil {
                return false
            }
            if chu.range(of: "\\d+[.,]\\d+\\s*%", options: .regularExpression) != nil {
                return false
            }
            let u = chuanHoaTieuDe(chu)
            return u.contains("NHAN VIEN") ||
                u.contains("NGANH HANG") ||
                u.contains("NHOM HANG") ||
                u.contains("SO LUONG") ||
                u.contains("DOANH THU") ||
                u.contains("THU QD") ||
                u.contains("KHOAN VAY") ||
                u.contains("TI TRONG") ||
                u.contains("TY TRONG") ||
                u == "LUONG" || u == "KHOAN" || u == "VAY" || u == "TRONG"
        }

        let coHeaderBang: Bool = !cacUngVienHeader.isEmpty
        let yTamHeaderGoiY: CGFloat
        if coHeaderBang {
            let cacY = cacUngVienHeader.map { $0.y + $0.cao / 2.0 }.sorted()
            yTamHeaderGoiY = cacY[cacY.count / 2]
        } else {
            yTamHeaderGoiY = 0.0
        }

        let cacHeader = cacUngVienHeader.filter { pt in
            let yTam = pt.y + pt.cao / 2.0
            return abs(yTam - yTamHeaderGoiY) <= 0.055
        }

        // Tìm dòng dữ liệu đầu tiên (dòng số thập phân xx.x% hoặc dòng id:) để giới hạn yHeaderMax không bao giờ lấn xuống Hàng 1
        let yIdDauTien = phanTuMoRong.compactMap { pt -> CGFloat? in
            guard pt.x < 0.36 else { return nil }
            if pt.chu.range(of: "(?i)\\b(?:id|ld|1d|ia|iđ)\\s*[:.;\\-]?\\s*\\d{4,7}", options: .regularExpression) != nil {
                return pt.y + pt.cao / 2.0
            }
            return nil
        }.min()

        let yPhanTramDauTien = nguonPhanTuSoSach.compactMap { pt -> CGFloat? in
            guard pt.x >= 0.75 && pt.y > 0.05 else { return nil }
            guard pt.chu.range(of: "\\d+[.,]\\d+\\s*%", options: .regularExpression) != nil else { return nil }
            return pt.y + pt.cao / 2.0
        }.min()

        let yHeaderMax: CGFloat
        if coHeaderBang {
            var yMax = cacHeader.map { $0.y + $0.cao }.max() ?? 0.060
            if let yPT1 = yPhanTramDauTien {
                yMax = min(yMax, max(0.045, yPT1 - 0.024))
            }
            if let yId1 = yIdDauTien {
                yMax = min(yMax, max(0.045, yId1 - 0.040))
            }
            yHeaderMax = max(0.045, min(0.085, yMax))
        } else {
            yHeaderMax = 0.0
        }

        let soDongCoId = phanTuMoRong.filter { pt in
            pt.x < 0.36 && pt.chu.range(of: "(?i)\\b(?:id|ld|1d|ia|iđ)\\s*[:.;\\-]?\\s*\\d{4,7}", options: .regularExpression) != nil
        }.count

        let duongKeDoc = (!laBangRong && anh != nil) ? timCacDuongKeDocBangNhanVien(anh: anh!, yBatDau: max(0.02, yHeaderMax)) : []

        var mocBatDauSoLuong: CGFloat = 0.298
        var mocBatDauDoanhThu: CGFloat = 0.462
        var mocBatDauKhoanVay: CGFloat = 0.643
        var mocBatDauTiTrong: CGFloat = 0.826

        if duongKeDoc.count == 4,
           duongKeDoc[0] >= 0.25 && duongKeDoc[0] <= 0.34,
           duongKeDoc[1] >= 0.42 && duongKeDoc[1] <= 0.51,
           duongKeDoc[2] >= 0.60 && duongKeDoc[2] <= 0.68,
           duongKeDoc[3] >= 0.78 && duongKeDoc[3] <= 0.87 {
            mocBatDauSoLuong = duongKeDoc[0]
            mocBatDauDoanhThu = duongKeDoc[1]
            mocBatDauKhoanVay = duongKeDoc[2]
            mocBatDauTiTrong = duongKeDoc[3]
        } else if !laBangRong && !coHeaderBang && soDongCoId < 1 && !laAnhBangDoanhThuNhanVien(phanTu: phanTuMoRong) {
            return []
        }

        // Tìm dòng TỔNG ngay dưới Header (chỉ tìm trong vùng sát dưới Header y < 0.16 để không bao giờ nhầm với tên NV như Trần Nam Tùng)
        let phanTuDongTong = phanTuMoRong.first { pt in
            guard pt.x < 0.25 && pt.y >= max(0.0, yHeaderMax - 0.01) && pt.y < 0.16 else { return false }
            let u = boDau(pt.chu).replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
            return u == "TONG" || u == "TONGCONG"
        }
        let yDongTong = phanTuDongTong.map { $0.y + $0.cao / 2.0 }
        let yBatDauNV: CGFloat
        if let ptTong = phanTuDongTong {
            yBatDauNV = ptTong.y + ptTong.cao * 0.55
        } else if coHeaderBang {
            yBatDauNV = yHeaderMax
        } else {
            yBatDauNV = 0.0
        }

        let watermark = timMaWatermarkAnToan(
            phanTu: phanTu,
            yGioiHan: 0.25,
            yTruocHeader: coHeaderBang ? max(0.01, yTamHeaderGoiY - 0.015) : nil
        )

        func lamSachWatermarkNV(_ s: String) -> String {
            var kq = s
            if let wm = watermark, !wm.isEmpty, !tapMaQuanLy.contains(wm) {
                kq = kq.replacingOccurrences(
                    of: "\\b\(NSRegularExpression.escapedPattern(for: wm))\\b",
                    with: " ",
                    options: .regularExpression
                )
            }
            kq = kq.replacingOccurrences(of: "\\b(54453|5445|4453)\\b", with: " ", options: .regularExpression)
            kq = kq.replacingOccurrences(of: "(?i)dũng\\s*nguyễn(\\s*thanh)?", with: " ", options: .regularExpression)
            kq = kq.replacingOccurrences(of: "(?i)nguyễn\\s*thanh", with: " ", options: .regularExpression)
            kq = kq.replacingOccurrences(of: "(?i)dung\\s*nguyen(\\s*thanh)?", with: " ", options: .regularExpression)
            kq = kq.replacingOccurrences(of: "(?i)nguyen\\s*thanh", with: " ", options: .regularExpression)
            return kq.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        func laSoWatermarkNV(_ val: Double, chu: String) -> Bool {
            if abs(val - 54453) < 0.1 || abs(val - 5445) < 0.1 || abs(val - 4453) < 0.1 { return true }
            if let wm = watermark, !tapMaQuanLy.contains(wm), let wmVal = Double(wm), abs(val - wmVal) < 0.1 { return true }
            let u = boDau(chu)
            if u.contains("DUNG NGUYEN") || u.contains("NGUYEN THANH") { return true }
            return false
        }

        func trichDanhSachUngVienMa(tu chuGoc: String) -> [String] {
            var s = lamSachWatermarkNV(chuGoc)
            if let rId = s.range(of: "(?i)\\b(?:id|ld|1d|ia|iđ)\\s*[:.;\\-]?", options: .regularExpression) {
                let truoc = String(s[..<rId.upperBound])
                let sau = String(s[rId.upperBound...])
                    .replacingOccurrences(of: "O", with: "0")
                    .replacingOccurrences(of: "o", with: "0")
                    .replacingOccurrences(of: "I", with: "1")
                    .replacingOccurrences(of: "l", with: "1")
                    .replacingOccurrences(of: "Z", with: "2")
                    .replacingOccurrences(of: "S", with: "5")
                    .replacingOccurrences(of: "G", with: "6")
                    .replacingOccurrences(of: "B", with: "8")
                s = truoc + " " + sau
            } else if let viTriGach = s.firstIndex(where: { $0 == "-" || $0 == "–" || $0 == "—" }) {
                let tienTo = String(s[..<viTriGach])
                    .replacingOccurrences(of: "O", with: "0")
                    .replacingOccurrences(of: "o", with: "0")
                    .replacingOccurrences(of: "I", with: "1")
                    .replacingOccurrences(of: "l", with: "1")
                    .replacingOccurrences(of: "Z", with: "2")
                    .replacingOccurrences(of: "S", with: "5")
                    .replacingOccurrences(of: "G", with: "6")
                    .replacingOccurrences(of: "B", with: "8")
                s = tienTo + String(s[viTriGach...])
            }

            guard let regexMa = try? NSRegularExpression(pattern: "(?<![0-9])\\d{4,7}(?![0-9])") else { return [] }
            let ns = s as NSString
            let matches = regexMa.matches(in: s, range: NSRange(location: 0, length: ns.length))
            var kq: [String] = []
            for m in matches {
                var ma = ns.substring(with: m.range)
                if ma == "54453" || ma == "5445" || ma == "4453" { continue }
                if let wm = watermark, !tapMaQuanLy.contains(wm), ma == wm { continue }
                if !tapMaQuanLy.contains(ma), ma.count >= 6 {
                    let boKyTuDau = String(ma.dropFirst())
                    if tapMaQuanLy.contains(boKyTuDau) {
                        ma = boKyTuDau
                    }
                }
                if !kq.contains(ma) {
                    kq.append(ma)
                }
            }
            return kq
        }

        func trichMaVaTenNhanVien(tu chuGoc: String) -> (maNV: String, hoTen: String)? {
            var s = lamSachWatermarkNV(chuGoc)
            s = s.replacingOccurrences(of: "(?i)^\\s*t[ổoồốởỡợ]ng(\\s+c[ộo]ng)?\\b[\\s+\\-–—]*", with: "", options: .regularExpression)
            s = s.replacingOccurrences(of: "(?i)nh[âa]n\\s*vi[êe]n(\\s*/\\s*ng[àa][^0-9+\\-]*)?", with: " ", options: .regularExpression)
            let uCheck = boDau(s)
            if uCheck == "TONG" || uCheck.contains("ONLINE") || uCheck.contains("KHU VUC") || uCheck.contains("QUANG NGAI") ||
               uCheck.contains("NGANH HANG BI") || uCheck.contains("NHOM HANG BI") {
                return nil
            }
            if (uCheck.contains("NHAN VIEN") || uCheck.contains("SO LUONG")) &&
               uCheck.range(of: "\\b\\d{4,7}\\b", options: .regularExpression) == nil {
                return nil
            }

            let cacUngVienMa = trichDanhSachUngVienMa(tu: s)
            let phanTenSach = s
                .replacingOccurrences(of: "(?i)\\b(?:id|ld|1d|ia|iđ)\\s*[:.;\\-]?\\s*\\d*", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\\d+", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "[+\\-–—:]+", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !dsQuanLy.isEmpty {
                for ma in cacUngVienMa {
                    if let nv = dsQuanLy.first(where: { $0.maNV == ma }) {
                        return (nv.maNV, nv.hoTen)
                    }
                }
                if !phanTenSach.isEmpty {
                    for ma in cacUngVienMa {
                        if let nv = KhoDuLieu.khopNhanVienQuetVoiQuanLy(maQuet: ma, tenQuet: phanTenSach, dsQuanLy: dsQuanLy) {
                            return (nv.maNV, nv.hoTen)
                        }
                    }
                    let tenChuan = KhoDuLieu.chuanHoaKhoaSoSanh(phanTenSach)
                    if cacUngVienMa.isEmpty, tenChuan.split(separator: " ").count >= 2,
                       let nv = dsQuanLy.first(where: { KhoDuLieu.chuanHoaKhoaSoSanh($0.hoTen) == tenChuan }) {
                        return (nv.maNV, nv.hoTen)
                    }
                }
                if let maDau = cacUngVienMa.first, !phanTenSach.isEmpty {
                    return (maDau, phanTenSach)
                }
                return nil
            }
            guard let maChon = cacUngVienMa.first else { return nil }
            return (maChon, phanTenSach.isEmpty ? maChon : phanTenSach)
        }

        // Chỉ lấy các token số thuần khiết (không lẫn chữ cái, không lấy từ cột 1 x < 0.28) từ nguồn đã tẩy sạch watermark
        func laTokenSoThuanKhiet(_ token: String) -> Bool {
            let s = token.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !s.isEmpty else { return false }
            if s.range(of: "[A-Za-zÀ-ỹĐđ:]", options: .regularExpression) != nil {
                return false
            }
            return s.range(of: "^[+\\-−–—]?\\d+([.,]\\d+)?%?$", options: .regularExpression) != nil
        }

        var tatCaPhanTuSo: [PhanTuVanBan] = []
        for pt in nguonPhanTuSoSach {
            guard pt.x >= 0.28 else { continue }
            if coHeaderBang && (pt.y + pt.cao / 2.0) < yBatDauNV { continue }
            let chuSach = lamSachWatermarkNV(pt.chu)
            guard !chuSach.isEmpty else { continue }
            let cacToken = chuSach.components(separatedBy: .whitespaces)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { laTokenSoThuanKhiet($0) && chuyenChuoiThanhSoDoanhThu($0) != nil }
            if cacToken.count >= 2 && pt.rong > 0.08 {
                let buocX = pt.rong / CGFloat(cacToken.count)
                for (idx, tk) in cacToken.enumerated() {
                    tatCaPhanTuSo.append(
                        PhanTuVanBan(
                            chu: tk,
                            x: pt.x + CGFloat(idx) * buocX,
                            y: pt.y,
                            rong: buocX,
                            cao: pt.cao
                        )
                    )
                }
            } else if laTokenSoThuanKhiet(chuSach), chuyenChuoiThanhSoDoanhThu(chuSach) != nil {
                tatCaPhanTuSo.append(PhanTuVanBan(chu: chuSach, x: pt.x, y: pt.y, rong: pt.rong, cao: pt.cao))
            }
        }

        struct DongUngVienNV {
            var maNV: String
            var hoTen: String
            var yTam: CGFloat
            var yTren: CGFloat? = nil
            var yDuoi: CGFloat? = nil
        }

        // Xây dựng danh sách khoảng hàng theo cả 2 phương pháp (Đường kẻ ngang & Hàng số + Đáy ID) rồi chọn phương pháp đọc được nhiều nhân viên nhất
        let cacMocNgang = (!laBangRong && anh != nil)
            ? timCacDuongKeNgangBangNhanVien(anh: anh!, coHeader: coHeaderBang, yHeaderMax: yHeaderMax)
            : []

        var khoangTuDuongKe: [(yTren: CGFloat, yDuoi: CGFloat)] = []
        if cacMocNgang.count >= 4 {
            for i in 0..<(cacMocNgang.count - 1) {
                let yt = max(yBatDauNV - 0.004, cacMocNgang[i])
                let yd = cacMocNgang[i + 1]
                if yd - yt >= 0.026 {
                    khoangTuDuongKe.append((yTren: yt, yDuoi: yd))
                }
            }
        }

        var khoangTuHangSoVaId: [(yTren: CGFloat, yDuoi: CGFloat)] = []
        if !laBangRong {
            let cacPTId = phanTuMoRong.filter { pt in
                let yTam = pt.y + pt.cao / 2.0
                guard pt.x < mocBatDauSoLuong && yTam >= max(0.0, yBatDauNV - 0.005) && yTam < 0.996 else { return false }
                let s = lamSachWatermarkNV(pt.chu)
                return s.range(of: "(?i)\\b(?:id|ld|1d|ia|iđ)\\s*[:.;\\-]?\\s*\\d{4,7}", options: .regularExpression) != nil
            }.sorted { ($0.y + $0.cao / 2.0) < ($1.y + $1.cao / 2.0) }

            var cacDayId: [CGFloat] = []
            for pt in cacPTId {
                let yDay = min(0.998, pt.y + pt.cao + 0.005)
                if let cuoi = cacDayId.last, abs(yDay - cuoi) < 0.024 {
                    cacDayId[cacDayId.count - 1] = max(cuoi, yDay)
                } else {
                    cacDayId.append(yDay)
                }
            }

            let cacSoHang = tatCaPhanTuSo.filter { pt in
                let yTam = pt.y + pt.cao / 2.0
                let xTam = pt.x + min(pt.rong, 0.12) / 2.0
                guard xTam >= mocBatDauSoLuong && yTam >= yBatDauNV + 0.005 && yTam < 0.995 else { return false }
                if let yTong = yDongTong, abs(yTam - yTong) < 0.015 { return false }
                guard let val = chuyenChuoiThanhSoDoanhThu(pt.chu) else { return false }
                return !laSoWatermarkNV(val, chu: pt.chu)
            }.sorted { ($0.y + $0.cao / 2.0) < ($1.y + $1.cao / 2.0) }

            var cumHangSo: [(yTB: CGFloat, cacY: [CGFloat], coPhanTram: Bool)] = []
            for pt in cacSoHang {
                let yTam = pt.y + pt.cao / 2.0
                if let idx = cumHangSo.indices.last, abs(yTam - cumHangSo[idx].yTB) < 0.022 {
                    cumHangSo[idx].cacY.append(yTam)
                    cumHangSo[idx].yTB = cumHangSo[idx].cacY.reduce(0, +) / CGFloat(cumHangSo[idx].cacY.count)
                    if pt.chu.contains("%") { cumHangSo[idx].coPhanTram = true }
                } else {
                    cumHangSo.append((yTB: yTam, cacY: [yTam], coPhanTram: pt.chu.contains("%")))
                }
            }
            let cacHangSoY = cumHangSo.filter { $0.cacY.count >= 2 || $0.coPhanTram }.map(\.yTB)

            if cacHangSoY.count >= 2 {
                var yTrenHienTai = yBatDauNV
                for k in 0..<cacHangSoY.count {
                    let ySo = cacHangSoY[k]
                    let yDuoiHang: CGFloat
                    if k + 1 < cacHangSoY.count {
                        let ySoKe = cacHangSoY[k + 1]
                        if let yIdGiua = cacDayId.first(where: { $0 > ySo && $0 < ySoKe - 0.006 }) {
                            yDuoiHang = yIdGiua
                        } else {
                            yDuoiHang = (ySo + ySoKe) / 2.0
                        }
                    } else {
                        let yIdCuoi = cacDayId.last(where: { $0 > ySo }) ?? (ySo + 0.032)
                        yDuoiHang = min(1.0, max(yIdCuoi, ySo + 0.028))
                    }
                    if yDuoiHang - yTrenHienTai >= 0.022 {
                        khoangTuHangSoVaId.append((yTren: yTrenHienTai, yDuoi: yDuoiHang))
                        yTrenHienTai = yDuoiHang
                    }
                }
            } else if cacDayId.count >= 2 {
                var yTrenHienTai = yBatDauNV
                for yDay in cacDayId {
                    if yDay - yTrenHienTai >= 0.022 {
                        khoangTuHangSoVaId.append((yTren: yTrenHienTai, yDuoi: yDay))
                        yTrenHienTai = yDay
                    }
                }
            }
        }

        func trichDongNVTuKhoang(_ cacKhoang: [(yTren: CGFloat, yDuoi: CGFloat)]) -> [DongUngVienNV] {
            var ds: [DongUngVienNV] = []
            var daCo = Set<String>()
            for khoang in cacKhoang {
                let ptTrongO = phanTuMoRong.filter { pt in
                    let yTam = pt.y + pt.cao / 2.0
                    return pt.x < (mocBatDauSoLuong - 0.008) && yTam >= (khoang.yTren - 0.004) && yTam <= (khoang.yDuoi + 0.004)
                }.sorted {
                    let y1 = $0.y + $0.cao / 2.0
                    let y2 = $1.y + $1.cao / 2.0
                    if abs(y1 - y2) < 0.009 { return $0.x < $1.x }
                    return y1 < y2
                }
                guard !ptTrongO.isEmpty else { continue }

                var cacDongChuTrongO: [(yTam: CGFloat, chu: String)] = []
                for pt in ptTrongO {
                    let s = lamSachWatermarkNV(pt.chu)
                        .replacingOccurrences(of: "^[+⊕⊞\\s]+$", with: "", options: .regularExpression)
                        .replacingOccurrences(of: "^[+⊕⊞]\\s+", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !s.isEmpty else { continue }
                    let uCheck = chuanHoaTieuDe(s)
                    if uCheck.contains("NHAN VIEN") || uCheck.contains("NGANH HANG") || uCheck.contains("NHOM HANG") ||
                       uCheck.contains("SO LUONG") || uCheck.contains("DOANH THU") || uCheck.contains("KHOAN VAY") ||
                       uCheck.contains("TI TRONG") || uCheck.contains("TY TRONG") {
                        continue
                    }
                    let yTam = pt.y + pt.cao / 2.0
                    if let idx = cacDongChuTrongO.indices.last, abs(yTam - cacDongChuTrongO[idx].yTam) < 0.011 {
                        let cu = cacDongChuTrongO[idx].chu
                        let cuChuan = KhoDuLieu.chuanHoaKhoaSoSanh(cu)
                        let moiChuan = KhoDuLieu.chuanHoaKhoaSoSanh(s)
                        if moiChuan.isEmpty { continue }
                        if cuChuan.contains(moiChuan) { continue }
                        if moiChuan.contains(cuChuan) {
                            cacDongChuTrongO[idx].chu = s
                        } else {
                            cacDongChuTrongO[idx].chu = cu + " " + s
                        }
                    } else {
                        cacDongChuTrongO.append((yTam: yTam, chu: s))
                    }
                }

                let chuCaO = cacDongChuTrongO.map(\.chu).joined(separator: " ")
                let cacMa = trichDanhSachUngVienMa(tu: chuCaO)
                let cacDongTen = cacDongChuTrongO.compactMap { dong -> String? in
                    let u = boDau(dong.chu)
                    if u.range(of: "^(?:ID|LD|1D|IA|MA)\\s*[:.;\\-]?\\s*\\d+$", options: .regularExpression) != nil {
                        return nil
                    }
                    let sach = dong.chu
                        .replacingOccurrences(of: "(?i)\\b(?:id|ld|1d|ia|iđ)\\s*[:.;\\-]?\\s*\\d*", with: " ", options: .regularExpression)
                        .replacingOccurrences(of: "\\d+", with: " ", options: .regularExpression)
                        .replacingOccurrences(of: "[+\\-–—:]+", with: " ", options: .regularExpression)
                        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    return sach.range(of: "[A-Za-zÀ-ỹĐđ]{2,}", options: .regularExpression) != nil ? sach : nil
                }
                let tenGhep = cacDongTen.joined(separator: " ")
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                var maChon = ""
                var tenChon = tenGhep

                if !dsQuanLy.isEmpty {
                    for ma in cacMa {
                        if let nv = dsQuanLy.first(where: { $0.maNV == ma }) {
                            maChon = nv.maNV
                            tenChon = nv.hoTen
                            break
                        }
                    }
                    if maChon.isEmpty, !tenGhep.isEmpty {
                        for ma in cacMa {
                            if let nv = KhoDuLieu.khopNhanVienQuetVoiQuanLy(maQuet: ma, tenQuet: tenGhep, dsQuanLy: dsQuanLy) {
                                maChon = nv.maNV
                                tenChon = nv.hoTen
                                break
                            }
                        }
                    }
                    if maChon.isEmpty, !tenGhep.isEmpty {
                        let tenChuan = KhoDuLieu.chuanHoaKhoaSoSanh(tenGhep)
                        if let nv = dsQuanLy.first(where: { KhoDuLieu.chuanHoaKhoaSoSanh($0.hoTen) == tenChuan }) {
                            maChon = nv.maNV
                            tenChon = nv.hoTen
                        } else if cacMa.isEmpty, let nv = KhoDuLieu.khopNhanVienQuetVoiQuanLy(maQuet: "", tenQuet: tenGhep, dsQuanLy: dsQuanLy) {
                            maChon = nv.maNV
                            tenChon = nv.hoTen
                        }
                    }
                    if maChon.isEmpty, let maDau = cacMa.first {
                        maChon = maDau
                        if tenChon.isEmpty { tenChon = "NV \(maDau)" }
                    }
                } else {
                    maChon = cacMa.first ?? ""
                    if tenChon.isEmpty { tenChon = maChon }
                }

                guard !maChon.isEmpty, !daCo.contains(maChon) else { continue }
                daCo.insert(maChon)
                ds.append(
                    DongUngVienNV(
                        maNV: maChon,
                        hoTen: tenChon,
                        yTam: (khoang.yTren + khoang.yDuoi) / 2.0,
                        yTren: khoang.yTren,
                        yDuoi: khoang.yDuoi
                    )
                )
            }
            return ds
        }

        let dsTuDuongKe = trichDongNVTuKhoang(khoangTuDuongKe)
        let dsTuHangSo = trichDongNVTuKhoang(khoangTuHangSoVaId)
        var cacDongNV: [DongUngVienNV] = (dsTuHangSo.count > dsTuDuongKe.count) ? dsTuHangSo : dsTuDuongKe
        var daXetMa = Set(cacDongNV.map(\.maNV))

        // ƯU TIÊN B (Dự phòng cho bảng kiểu cũ 1 dòng "+ 116719 - Đinh Thị Quỳnh Nga" nếu Ưu tiên A không tìm thấy >= 2 dòng)
        if cacDongNV.count < 2 {
            cacDongNV.removeAll()
            daXetMa.removeAll()

            let phanTuCotTrai = phanTuMoRong.filter { pt in
                let yTam = pt.y + pt.cao / 2.0
                return pt.x < 0.36 && yTam >= yBatDauNV && yTam < 0.985
            }.sorted {
                let y1 = $0.y + $0.cao / 2.0
                let y2 = $1.y + $1.cao / 2.0
                if abs(y1 - y2) < 0.011 { return $0.x < $1.x }
                return y1 < y2
            }

            var cacCumCotTrai: [(yTam: CGFloat, cacPT: [PhanTuVanBan])] = []
            for pt in phanTuCotTrai {
                let yTam = pt.y + pt.cao / 2.0
                if let idx = cacCumCotTrai.indices.last, abs(yTam - cacCumCotTrai[idx].yTam) < 0.013 {
                    cacCumCotTrai[idx].cacPT.append(pt)
                    let tongY = cacCumCotTrai[idx].cacPT.reduce(CGFloat(0)) { $0 + ($1.y + $1.cao / 2.0) }
                    cacCumCotTrai[idx].yTam = tongY / CGFloat(cacCumCotTrai[idx].cacPT.count)
                } else {
                    cacCumCotTrai.append((yTam: yTam, cacPT: [pt]))
                }
            }

            for cum in cacCumCotTrai {
                let chuGop = cum.cacPT.sorted { $0.x < $1.x }.map(\.chu).joined(separator: " ")
                if let (maNV, hoTen) = trichMaVaTenNhanVien(tu: chuGop), !daXetMa.contains(maNV) {
                    daXetMa.insert(maNV)
                    cacDongNV.append(DongUngVienNV(maNV: maNV, hoTen: hoTen, yTam: cum.yTam))
                } else {
                    for pt in cum.cacPT {
                        if let (maNV, hoTen) = trichMaVaTenNhanVien(tu: pt.chu), !daXetMa.contains(maNV) {
                            daXetMa.insert(maNV)
                            cacDongNV.append(DongUngVienNV(maNV: maNV, hoTen: hoTen, yTam: pt.y + pt.cao / 2.0))
                        }
                    }
                }
            }

            for pt in phanTuMoRong where pt.x < 0.40 {
                let chu = lamSachWatermarkNV(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
                guard chu.range(of: "^[+\\s]*\\d{4,7}\\s*$", options: .regularExpression) != nil,
                      let (maNV, hoTen) = trichMaVaTenNhanVien(tu: chu) else { continue }
                let yTam = pt.y + pt.cao / 2.0
                guard yTam > 0.01 && yTam < 0.99 else { continue }
                if let idx = cacDongNV.firstIndex(where: { $0.maNV == maNV }) {
                    cacDongNV[idx].yTam = yTam
                    cacDongNV[idx].hoTen = hoTen
                } else {
                    daXetMa.insert(maNV)
                    cacDongNV.append(DongUngVienNV(maNV: maNV, hoTen: hoTen, yTam: yTam))
                }
            }
            cacDongNV.sort { $0.yTam < $1.yTam }
        }

        guard !cacDongNV.isEmpty else { return [] }

        // Đọc tổng Số lượng và tổng Doanh thu QĐ từ dòng TỔNG (nếu có)
        var tongSoLuongBang: Double = 0
        var tongDTQDBangTuDongTong: Double = 0
        if let yTong = yDongTong {
            let soDongTong = tatCaPhanTuSo.filter { pt in
                let yTam = pt.y + pt.cao / 2.0
                return abs(yTam - yTong) < 0.015
            }
            for pt in soDongTong {
                let xTam = pt.x + min(pt.rong, 0.12) / 2.0
                guard let val = chuyenChuoiThanhSoDoanhThu(pt.chu), !laSoWatermarkNV(val, chu: pt.chu) else { continue }
                if xTam >= mocBatDauSoLuong && xTam < mocBatDauDoanhThu && !pt.chu.contains("%") && tongSoLuongBang == 0 {
                    tongSoLuongBang = val
                } else if xTam >= mocBatDauDoanhThu && xTam < mocBatDauKhoanVay && !pt.chu.contains("%") && tongDTQDBangTuDongTong == 0 {
                    tongDTQDBangTuDongTong = val
                }
            }
        }

        let khoangCachHangTB: CGFloat = (cacDongNV.count >= 2)
            ? max(0.018, min(0.075, (cacDongNV.last!.yTam - cacDongNV.first!.yTam) / CGFloat(cacDongNV.count - 1)))
            : 0.045

        var ketQua: [DoanhThuNhanVienItem] = []
        var ungVienDTQDMoiHang: [[Double]] = []
        var ungVienTiTrongMoiHang: [[Double]] = []

        for (k, dong) in cacDongNV.enumerated() {
            let yHang = dong.yTam
            let yTren: CGFloat
            let yDuoi: CGFloat
            if let yt = dong.yTren, let yd = dong.yDuoi {
                yTren = max(0.0, yt - 0.002)
                yDuoi = min(1.0, yd + 0.002)
            } else {
                if k == 0 {
                    if let yTong = yDongTong, yTong < yHang {
                        yTren = max(yHang - khoangCachHangTB * 0.65, (yTong + yHang) / 2.0)
                    } else {
                        yTren = max(0.0, yHang - khoangCachHangTB * 0.65)
                    }
                } else {
                    yTren = max(yHang - khoangCachHangTB * 0.62, (cacDongNV[k - 1].yTam + yHang) / 2.0)
                }
                yDuoi = (k + 1 < cacDongNV.count)
                    ? min(yHang + khoangCachHangTB * 0.62, (yHang + cacDongNV[k + 1].yTam) / 2.0)
                    : min(1.0, yHang + khoangCachHangTB * 0.65)
            }

            let cacPhanTuSoCungHang = tatCaPhanTuSo.filter { pt in
                let yTam = pt.y + pt.cao / 2.0
                guard yTam >= yTren && yTam <= yDuoi else { return false }
                guard let val = chuyenChuoiThanhSoDoanhThu(pt.chu) else { return false }
                return !laSoWatermarkNV(val, chu: pt.chu)
            }.sorted { $0.x < $1.x }

            func giaTriCoDau(_ pt: PhanTuVanBan) -> Double {
                let giaTri = chuyenChuoiThanhSoDoanhThu(pt.chu) ?? 0
                if giaTri < 0 { return giaTri }
                let yTamPT = pt.y + pt.cao / 2.0
                let coDauTruRoi = phanTuMoRong.contains { dau in
                    let token = dau.chu.trimmingCharacters(in: .whitespacesAndNewlines)
                    let laDauTru = token == "-" || token == "−" || token == "–" || token == "—"
                    let mepPhai = dau.x + dau.rong
                    let yTamDau = dau.y + dau.cao / 2.0
                    return laDauTru && abs(yTamDau - yTamPT) < 0.015 && mepPhai <= pt.x + 0.012 && pt.x - mepPhai < 0.035
                }
                return coDauTruRoi ? -abs(giaTri) : giaTri
            }

            if !laBangRong {
                // Trong bảng 5 cột BI, các con số đều căn phải sát lề phải của từng cột;
                // ưu tiên phần tử nằm sát lề phải của cột nhất để không bao giờ lấy nhầm mảnh số rác ở lề trái ô
                func layDanhSachSoTheoKhoangX(_ xMin: CGFloat, _ xMax: CGFloat, choPhepPhanTram: Bool = false) -> [Double] {
                    let ungVien = cacPhanTuSoCungHang.filter { pt in
                        let xTam = pt.x + min(pt.rong, 0.12) / 2.0
                        if !choPhepPhanTram && pt.chu.contains("%") { return false }
                        return xTam >= xMin && xTam < xMax
                    }.sorted {
                        let r0 = $0.x + min($0.rong, 0.12)
                        let r1 = $1.x + min($1.rong, 0.12)
                        if abs(r0 - r1) > 0.015 { return r0 > r1 }
                        return $0.chu.count > $1.chu.count
                    }
                    return ungVien.map { giaTriCoDau($0) }
                }

                func laySoTheoKhoangX(_ xMin: CGFloat, _ xMax: CGFloat, choPhepPhanTram: Bool = false) -> Double? {
                    let ds = layDanhSachSoTheoKhoangX(xMin, xMax, choPhepPhanTram: choPhepPhanTram)
                    guard !ds.isEmpty else { return nil }
                    if let khacKhong = ds.first(where: { abs($0) > 0.0001 }) {
                        return khacKhong
                    }
                    return ds[0]
                }

                let dsDTQDUngVien = layDanhSachSoTheoKhoangX(mocBatDauDoanhThu, mocBatDauKhoanVay)
                let soLuong = laySoTheoKhoangX(mocBatDauSoLuong, mocBatDauDoanhThu) ?? 0
                let doanhThuQD = dsDTQDUngVien.first(where: { abs($0) > 0.0001 }) ?? dsDTQDUngVien.first ?? 0
                let dtQDKhoanVay = laySoTheoKhoangX(mocBatDauKhoanVay, mocBatDauTiTrong) ?? 0

                // Ưu tiên số % có phần thập phân (như "4.1%", "10.7%") hơn mảnh bị đứt (như "1%")
                let cacPTPhanTram = cacPhanTuSoCungHang.filter {
                    ($0.x + min($0.rong, 0.12) / 2.0) >= max(0.75, mocBatDauTiTrong - 0.02) &&
                    ($0.chu.contains("%") || ($0.x + min($0.rong, 0.12) / 2.0) >= mocBatDauTiTrong)
                }.sorted { a, b in
                    let aCoThapPhan = a.chu.range(of: "\\d+[.,]\\d+", options: .regularExpression) != nil
                    let bCoThapPhan = b.chu.range(of: "\\d+[.,]\\d+", options: .regularExpression) != nil
                    if aCoThapPhan != bCoThapPhan { return aCoThapPhan }
                    if a.chu.contains("%") != b.chu.contains("%") { return a.chu.contains("%") }
                    return a.chu.count > b.chu.count
                }
                let dsTTUngVien = cacPTPhanTram.map { giaTriCoDau($0) }.filter { abs($0) <= 100.0 }
                let phanTramTiTrong = dsTTUngVien.first(where: { abs($0) > 0.0001 }) ?? dsTTUngVien.first ?? 0

                ungVienDTQDMoiHang.append(dsDTQDUngVien)
                ungVienTiTrongMoiHang.append(dsTTUngVien)

                ketQua.append(DoanhThuNhanVienItem(
                    maNV: dong.maNV,
                    hoTen: dong.hoTen,
                    soLuong: soLuong,
                    doanhThuThuc: 0,
                    doanhThuQD: doanhThuQD,
                    target: 0,
                    dtQDKhoanVay: dtQDKhoanVay,
                    phanTramQuyDoi: phanTramTiTrong
                ))
            } else {
                guard !cacPhanTuSoCungHang.isEmpty else { continue }
                let cacSo = cacPhanTuSoCungHang.map { giaTriCoDau($0) }
                func soTai(_ idx: Int) -> Double { idx < cacSo.count ? cacSo[idx] : 0 }

                ketQua.append(DoanhThuNhanVienItem(
                    maNV: dong.maNV,
                    hoTen: dong.hoTen,
                    soLuong: 0,
                    doanhThuThuc: soTai(0),
                    doanhThuQD: soTai(1),
                    target: soTai(2),
                    dtQDKhoanVay: 0,
                    dtTraThangQD: soTai(0),
                    dtTraGop: soTai(6),
                    phanTramHT: soTai(3),
                    phanTramQuyDoi: soTai(4),
                    phanTramTraGop: soTai(5),
                    gioCong: soTai(7),
                    soNgayNghi: soTai(8),
                    nangSuat: soTai(9)
                ))
            }
        }

        // Quét bổ sung những ô còn thiếu số
        if !laBangRong, let anh = anh, !ketQua.isEmpty {
            var cacOCanQuet: [(idO: Int, xMin: CGFloat, xMax: CGFloat, yMin: CGFloat, yMax: CGFloat)] = []
            for (i, item) in ketQua.enumerated() where i < cacDongNV.count {
                let dong = cacDongNV[i]
                let yMinO = dong.yTren.map { $0 + 0.004 } ?? max(0.0, dong.yTam - khoangCachHangTB * 0.48)
                let yMaxO = dong.yDuoi.map { $0 - 0.004 } ?? min(1.0, dong.yTam + khoangCachHangTB * 0.48)
                if abs(item.soLuong) < 0.0001 {
                    cacOCanQuet.append((idO: i * 10 + 1, xMin: mocBatDauSoLuong + 0.012, xMax: mocBatDauDoanhThu - 0.004, yMin: yMinO, yMax: yMaxO))
                }
                if abs(item.doanhThuQD) < 0.0001 {
                    cacOCanQuet.append((idO: i * 10 + 2, xMin: mocBatDauDoanhThu + 0.010, xMax: mocBatDauKhoanVay - 0.004, yMin: yMinO, yMax: yMaxO))
                }
            }
            if !cacOCanQuet.isEmpty {
                let soQuetDuoc = quetCacOThieuSoBangNhanVien(anh: anh, cacO: cacOCanQuet)
                for (idO, giaTri) in soQuetDuoc where abs(giaTri) < 10000 {
                    let rowIdx = idO / 10
                    let loaiCot = idO % 10
                    guard rowIdx >= 0 && rowIdx < ketQua.count else { continue }
                    if loaiCot == 1 && abs(ketQua[rowIdx].soLuong) < 0.0001 {
                        ketQua[rowIdx].soLuong = giaTri
                    } else if loaiCot == 2 && abs(ketQua[rowIdx].doanhThuQD) < 0.0001 {
                        ketQua[rowIdx].doanhThuQD = giaTri
                    }
                }
            }
        }

        // Hậu kiểm & Tự động hiệu chỉnh toán học giữa DOANH THU QĐ và % TỈ TRỌNG bằng trung vị tổng doanh thu siêu thị (T_med = DT_i / (P_i / 100))
        if !laBangRong && !ketQua.isEmpty {
            var cacTyLeTong: [Double] = []
            var tatCaDTQDLaSoNguyen = true

            for item in ketQua {
                if abs(item.doanhThuQD) > 0.001 {
                    if abs(item.doanhThuQD - item.doanhThuQD.rounded()) > 0.01 {
                        tatCaDTQDLaSoNguyen = false
                    }
                    if abs(item.phanTramQuyDoi) >= 0.2 {
                        let t = item.doanhThuQD / (item.phanTramQuyDoi / 100.0)
                        if t > 50.0 && t < 500000.0 {
                            cacTyLeTong.append(t)
                        }
                    }
                }
            }

            let tongDTQDUocLuong: Double
            if cacTyLeTong.count >= 3 {
                cacTyLeTong.sort()
                tongDTQDUocLuong = cacTyLeTong[cacTyLeTong.count / 2]
            } else if tongDTQDBangTuDongTong > 0 {
                tongDTQDUocLuong = tongDTQDBangTuDongTong
            } else {
                tongDTQDUocLuong = 0
            }

            if tongDTQDUocLuong > 0 {
                for i in ketQua.indices {
                    let dt = ketQua[i].doanhThuQD
                    let pt = ketQua[i].phanTramQuyDoi

                    if abs(dt) < 0.0001 && abs(pt) > 0.05 {
                        let dtKhoiPhuc = tongDTQDUocLuong * (pt / 100.0)
                        ketQua[i].doanhThuQD = tatCaDTQDLaSoNguyen ? dtKhoiPhuc.rounded() : ((dtKhoiPhuc * 100).rounded() / 100)
                    } else if abs(pt) < 0.0001 && abs(dt) > 0.001 {
                        ketQua[i].phanTramQuyDoi = ((dt / tongDTQDUocLuong) * 1000).rounded() / 10
                    } else if abs(dt) > 0.001 && abs(pt) > 0.05 {
                        let dtUocTuPT = tongDTQDUocLuong * (pt / 100.0)
                        let ptUocTuDT = (dt / tongDTQDUocLuong) * 100.0
                        let lechDT = abs(dt - dtUocTuPT)
                        let nguongDT = max(2.8, abs(dtUocTuPT) * 0.055)

                        if lechDT > nguongDT {
                            // 1. Kiểm tra xem trong ô có ứng viên số nào khớp với T_med không
                            var daSua = false
                            if i < ungVienDTQDMoiHang.count {
                                if let khopDT = ungVienDTQDMoiHang[i].first(where: { abs($0 - dtUocTuPT) <= nguongDT }) {
                                    ketQua[i].doanhThuQD = khopDT
                                    daSua = true
                                }
                            }
                            if !daSua && i < ungVienTiTrongMoiHang.count {
                                if let khopPT = ungVienTiTrongMoiHang[i].first(where: { abs($0 - ptUocTuDT) <= 0.35 }) {
                                    ketQua[i].phanTramQuyDoi = khopPT
                                    daSua = true
                                }
                            }

                            // 2. Nếu vẫn lệch (do watermark che mờ 1 trong 2 số), đối chiếu thứ tự giảm dần với dòng liền kề để biết số nào đúng
                            if !daSua {
                                let dtTruoc = (i > 0) ? ketQua[i - 1].doanhThuQD : Double.greatestFiniteMagnitude
                                let dtSau = (i + 1 < ketQua.count && ketQua[i + 1].doanhThuQD > 0) ? ketQua[i + 1].doanhThuQD : 0.0
                                let ptTruoc = (i > 0) ? ketQua[i - 1].phanTramQuyDoi : 100.0
                                let ptSau = (i + 1 < ketQua.count && ketQua[i + 1].phanTramQuyDoi > 0) ? ketQua[i + 1].phanTramQuyDoi : 0.0

                                let dtHopThuTu = (dt <= dtTruoc + 1.0 && dt >= dtSau - 1.0)
                                let ptHopThuTu = (pt <= ptTruoc + 0.15 && pt >= ptSau - 0.15)

                                if ptHopThuTu && !dtHopThuTu {
                                    ketQua[i].doanhThuQD = tatCaDTQDLaSoNguyen ? dtUocTuPT.rounded() : ((dtUocTuPT * 100).rounded() / 100)
                                } else if dtHopThuTu && !ptHopThuTu {
                                    ketQua[i].phanTramQuyDoi = (ptUocTuDT * 10).rounded() / 10
                                } else {
                                    ketQua[i].doanhThuQD = tatCaDTQDLaSoNguyen ? dtUocTuPT.rounded() : ((dtUocTuPT * 100).rounded() / 100)
                                }
                            }
                        }
                    }
                }
            }

            if tongSoLuongBang > 0 {
                let cacChiSoThieuSL = ketQua.indices.filter {
                    abs(ketQua[$0].soLuong) < 0.0001 && (abs(ketQua[$0].doanhThuQD) > 0.001 || abs(ketQua[$0].phanTramQuyDoi) > 0.05)
                }
                let tongSLDaBiet = ketQua.reduce(0.0) { $0 + $1.soLuong }
                if cacChiSoThieuSL.count == 1 && tongSoLuongBang > tongSLDaBiet {
                    ketQua[cacChiSoThieuSL[0]].soLuong = (tongSoLuongBang - tongSLDaBiet).rounded()
                }
            }
        }

        // Chỉ giữ lại và chuẩn hoá các nhân viên có trong danh sách quản lý
        if !dsQuanLy.isEmpty {
            var ketQuaDaLoc: [DoanhThuNhanVienItem] = []
            var daGiuMa = Set<String>()
            for item in ketQua {
                guard let nvKhop = KhoDuLieu.khopNhanVienQuetVoiQuanLy(
                    maQuet: item.maNV,
                    tenQuet: item.hoTen,
                    dsQuanLy: dsQuanLy
                ) else { continue }
                if daGiuMa.contains(nvKhop.maNV) { continue }
                daGiuMa.insert(nvKhop.maNV)
                var capNhat = item
                capNhat.maNV = nvKhop.maNV
                capNhat.hoTen = nvKhop.hoTen
                ketQuaDaLoc.append(capNhat)
            }
            return ketQuaDaLoc
        }

        return ketQua
    }

    private func laChuoiRac(_ chu: String, watermark: String?) -> Bool {
        let inHoa = boDau(chu).trimmingCharacters(in: .whitespacesAndNewlines)
        if inHoa == "TONG" || inHoa == "TARGET" || inHoa.contains("% HT") || inHoa.contains("DU BAO") || inHoa.contains("HANG TRONG") || inHoa.contains("BO PHAN") {
            return true
        }
        if let wm = watermark, inHoa.contains(wm) {
            return true
        }
        return false
    }

    private func timGiaTriSo(trong danhSach: [PhanTuVanBan], watermark: String?) -> Double? {
        let sapXep = danhSach.sorted { $0.y < $1.y }
        for pt in sapXep {
            let chu = pt.chu.trimmingCharacters(in: .whitespacesAndNewlines)
            if let wm = watermark, chu.contains(wm) { continue }
            if let so = chuyenChuoiThanhSo(chu, watermark: watermark) {
                return so
            }
        }
        return nil
    }

    private func chuyenChuoiThanhSo(_ chuoi: String, watermark: String? = nil) -> Double? {
        var sach = chuoi
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: "…", with: "")
            .replacingOccurrences(of: "...", with: "")
            .replacingOccurrences(of: "..", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        sach = sach.replacingOccurrences(of: ",", with: "")

        guard !sach.isEmpty else { return nil }
        if sach.range(of: "^-?\\d+(\\.\\d+)?$", options: .regularExpression) != nil {
            if let wm = watermark, sach == wm { return nil }
            return Double(sach)
        }
        if let range = sach.range(of: "-?\\d+(\\.\\d+)?$", options: .regularExpression) {
            let token = String(sach[range])
            if let wm = watermark, token == wm { return nil }
            return Double(token)
        }
        return nil
    }

    // MARK: - Phân tích ảnh chụp màn hình "Doanh thu hợp nhất" (Lũy kế & Realtime: DT thực & DT quy đổi)

    private func boDau(_ chuoi: String) -> String {
        chuoi
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "D")
            .uppercased()
    }

    private func chuyenChuoiThanhSoDoanhThu(_ chuoi: String) -> Double? {
        var s = chuoi
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: "…", with: "")
            .replacingOccurrences(of: "...", with: "")
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "^[^0-9\\-]+|[^0-9]+$", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !s.isEmpty else { return nil }

        if s.contains(",") && s.contains(".") {
            let viTriPhay = s.lastIndex(of: ",")!
            let viTriCham = s.lastIndex(of: ".")!
            if viTriPhay > viTriCham {
                s = s.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            } else {
                s = s.replacingOccurrences(of: ",", with: "")
            }
        } else if s.contains(",") {
            if s.range(of: "^-?\\d{1,3}(,\\d{3})+$", options: .regularExpression) != nil {
                s = s.replacingOccurrences(of: ",", with: "")
            } else {
                s = s.replacingOccurrences(of: ",", with: ".")
            }
        } else if s.contains(".") {
            if s.range(of: "^-?\\d{1,3}(\\.\\d{3})+$", options: .regularExpression) != nil {
                s = s.replacingOccurrences(of: ".", with: "")
            }
        }

        if let range = s.range(of: "-?\\d+(\\.\\d+)?", options: .regularExpression) {
            return Double(String(s[range]))
        }
        return nil
    }

    private func trichCacSo(trong chuoi: String) -> [Double] {
        guard let regex = try? NSRegularExpression(pattern: "-?\\d+[\\d.,]*") else { return [] }
        let ns = chuoi as NSString
        let matches = regex.matches(in: chuoi, range: NSRange(location: 0, length: ns.length))
        return matches.compactMap { m in
            let sub = ns.substring(with: m.range)
            return chuyenChuoiThanhSoDoanhThu(sub)
        }
    }

    private func phanTichDoanhThu(phanTu: [PhanTuVanBan]) -> ThongTinDoanhThu {
        var kq = ThongTinDoanhThu()

        // 1. Tìm thanh "Quỹ thời gian: 30/31 ngày" (Lũy kế) hoặc "THỜI GIAN LÀM VIỆC: 08:00 - 22:00" (Realtime)
        var yBatDauVungThe: CGFloat = 0.44
        if let mocQTG = phanTu.first(where: {
            let u = boDau($0.chu)
            return u.contains("QUY THOI GIAN") || u.contains("TIEN DO THANG") || u.contains("THOI GIAN LAM VIEC")
        }) {
            yBatDauVungThe = mocQTG.y + 0.02
            let cungHang = phanTu
                .filter { abs($0.y - mocQTG.y) < 0.035 }
                .sorted { $0.x < $1.x }
            let chuoiHang = cungHang.map { $0.chu }.joined(separator: " ")

            if !boDau(chuoiHang).contains("LAM VIEC"),
               let regex = try? NSRegularExpression(pattern: "(\\d{1,2})\\s*/\\s*(\\d{1,2})"),
               let m = regex.firstMatch(in: chuoiHang, range: NSRange(location: 0, length: (chuoiHang as NSString).length)) {
                let ns = chuoiHang as NSString
                let d1 = Int(ns.substring(with: m.range(at: 1))) ?? 0
                let d2 = Int(ns.substring(with: m.range(at: 2))) ?? 0
                if d1 > 0 && d2 > 0 {
                    kq.soNgayDaQua = d1
                    kq.tongSoNgay = d2
                }
            }
            if let ptPhanTram = cungHang.last(where: { $0.chu.contains("%") }),
               let val = chuyenChuoiThanhSoDoanhThu(ptPhanTram.chu) {
                kq.phanTramTienDoThang = val
            } else if kq.soNgayDaQua > 0 && kq.tongSoNgay > 0 {
                kq.phanTramTienDoThang = (Double(kq.soNgayDaQua) / Double(kq.tongSoNgay)) * 100.0
            }
        } else if let mocNut = phanTu.filter({
            let u = boDau($0.chu)
            return u.contains("XUAT EXCEL") || u.contains("XUAT THEO MAU") || u.contains("TOAN CONG TY")
        }).max(by: { $0.y < $1.y }) {
            yBatDauVungThe = mocNut.y + 0.03
        }

        // 2. Lọc vùng các thẻ chỉ số bên dưới thanh Quỹ thời gian / Thời gian làm việc (tới sát thanh tab đáy y < 0.965)
        let vungThe = phanTu.filter { pt in
            guard pt.y > yBatDauVungThe && pt.y < 0.965 else { return false }
            if pt.y > 0.935 {
                let u = boDau(pt.chu)
                if u == "DOANH THU" || u.contains("TONG HOP") || u.contains("NGANH HANG BI") {
                    return false
                }
            }
            return true
        }

        let laAnhQuyDoi = vungThe.contains { pt in
            let u = boDau(pt.chu)
            return u.contains("DT QUY DOI") || u.contains("KHOAN VAY") || u.contains("TRA GOP QD")
        }

        func layDuLieuThe(thoaMan: (String) -> Bool) -> (soChinh: Double?, vanBanPhu: String)? {
            guard let moc = vungThe.sorted(by: { $0.y < $1.y }).first(where: { thoaMan(boDau($0.chu)) }) else {
                return nil
            }
            let laCotTrai = moc.x < 0.47
            let trongThe = vungThe.filter { pt in
                let cungCot = laCotTrai ? (pt.x < 0.47) : (pt.x >= 0.47)
                return cungCot && pt.y > moc.y + 0.008 && pt.y < moc.y + 0.12
            }.sorted {
                if abs($0.y - $1.y) < 0.012 { return $0.x < $1.x }
                return $0.y < $1.y
            }

            var soChinh: Double?
            for pt in trongThe where pt.y < moc.y + 0.072 {
                let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
                if u == "?" || u.contains("TRIEU DONG") || u.contains("TARGET") || u.contains("BILL") || u.contains("TRA GOP") || u.contains("CHUA CO") {
                    continue
                }
                if let val = chuyenChuoiThanhSoDoanhThu(pt.chu) {
                    soChinh = val
                    break
                }
            }
            let vanBanPhu = trongThe.map { $0.chu }.joined(separator: " ")
            return (soChinh, vanBanPhu)
        }

        // 3A. Ô "DT thực"
        if !laAnhQuyDoi, let theDTThuc = layDuLieuThe(thoaMan: { $0 == "DT THUC" || ($0.contains("DT THUC") && !$0.contains("LUY KE")) }) {
            if let so = theDTThuc.soChinh { kq.doanhThuThuc = so }
        }

        // 3B. Ô "DT quy đổi"
        if laAnhQuyDoi, let theDTQD = layDuLieuThe(thoaMan: { $0 == "DT QUY DOI" || ($0.contains("DT QUY DOI") && !$0.contains("KHOAN VAY")) }) {
            if let so = theDTQD.soChinh { kq.doanhThuQuyDoi = so }
        }

        // 3C. Ô "DT dự kiến"
        if let theDuKien = layDuLieuThe(thoaMan: { $0.contains("DT DU KIEN") || $0 == "DU KIEN" }) {
            if let so = theDuKien.soChinh {
                if laAnhQuyDoi {
                    kq.duKienQuyDoi = so
                } else {
                    kq.duKienThuc = so
                }
            }
        }

        // 3D. Ô "% HT target" / "% HT dự kiến" / "% HT target ngày"
        if let theHT = layDuLieuThe(thoaMan: { $0.contains("HT TARGET") || $0.contains("HT DU KIEN") || $0.contains("DU KIEN HOAN") || ($0.contains("TARGET") && $0.contains("%")) }) {
            if let so = theHT.soChinh {
                if laAnhQuyDoi {
                    kq.phanTramHTQuyDoi = so
                } else {
                    kq.phanTramHTThuc = so
                }
            }
            let phuKhongDau = boDau(theHT.vanBanPhu)
            if let range = phuKhongDau.range(of: "KY\\s*([0-9][0-9.,]*)", options: .regularExpression) ??
                phuKhongDau.range(of: "TARGET[^0-9]*([0-9][0-9.,]*)", options: .regularExpression) {
                let chuoiCon = String(phuKhongDau[range])
                if let targetVal = trichCacSo(trong: chuoiCon).first, targetVal > 0 {
                    if laAnhQuyDoi {
                        kq.targetQuyDoi = targetVal
                    } else {
                        kq.targetThuc = targetVal
                    }
                }
            }
        }

        // 3E. Ô "TT vs TB 3 tháng"
        if let theTB3T = layDuLieuThe(thoaMan: { $0.contains("TB 3 THANG") || $0.contains("TT VS") }) {
            if let so = theTB3T.soChinh {
                kq.tangGiamCungKy = so
                kq.coTangGiam = true
            }
            let phuKhongDau = boDau(theTB3T.vanBanPhu)
            if let range = phuKhongDau.range(of: "SO:?\\s*([0-9][0-9.,]*)", options: .regularExpression) ??
                phuKhongDau.range(of: "CUA[^0-9]*([0-9][0-9.,]*)", options: .regularExpression) {
                let chuoiCon = String(phuKhongDau[range])
                if let tbVal = trichCacSo(trong: chuoiCon).last, tbVal > 0 {
                    kq.tb3Thang = tbVal
                }
            }
        }

        // 3F. Ô "TLPVTC lũy kế" / "TLPVTC hôm nay" -> Lấy % PVTC, Số Bill và Lượt Khách
        if let thePVTC = layDuLieuThe(thoaMan: { $0.contains("TLPVTC") || $0.contains("PVTC") }) {
            if let so = thePVTC.soChinh {
                kq.phanTramPVTC = so
            }
            let phuKhongDau = boDau(thePVTC.vanBanPhu)
            if let rBill = phuKhongDau.range(of: "([0-9][0-9.,]*)\\s*BILL", options: .regularExpression) {
                if let bVal = trichCacSo(trong: String(phuKhongDau[rBill])).first {
                    kq.soBill = bVal
                }
            }
            if let rKhach = phuKhongDau.range(of: "([0-9][0-9.,]*)\\s*KHACH", options: .regularExpression) {
                if let kVal = trichCacSo(trong: String(phuKhongDau[rKhach])).first {
                    kq.luotKhach = kVal
                }
            }
        }

        // 3G. Ô "Tỷ trọng trả chậm"
        if let theTraCham = layDuLieuThe(thoaMan: { $0.contains("TRA CHAM") || $0.contains("TY TRONG") }) {
            if let so = theTraCham.soChinh {
                kq.phanTramTraGop = so
            }
            let phuKhongDau = boDau(theTraCham.vanBanPhu)
            if let rTG = phuKhongDau.range(of: "TRA GOP(?:\\s*QD)?\\s*([0-9][0-9.,]*)", options: .regularExpression) {
                if let tgVal = trichCacSo(trong: String(phuKhongDau[rTG])).first {
                    kq.doanhThuTraGop = tgVal
                }
            }
        }

        // 4. Dự phòng nếu người dùng quét ảnh đã tổng hợp sẵn kiểu Ảnh 3
        if !kq.coDuLieu {
            if let mocThuc = phanTu.first(where: { boDau($0.chu).contains("DOANH THU THUC") }),
               let mocQD = phanTu.first(where: { boDau($0.chu).contains("DOANH THU QD") }) {
                let ranhX = (mocThuc.x + mocQD.x) / 2.0
                let vung = phanTu.filter { $0.y > min(mocThuc.y, mocQD.y) && $0.y < min(mocThuc.y, mocQD.y) + 0.18 }
                let trai = vung.filter { $0.x < ranhX }.sorted { $0.y < $1.y }
                let phai = vung.filter { $0.x >= ranhX }.sorted { $0.y < $1.y }
                for pt in trai {
                    if boDau(pt.chu).contains("TARGET"), let v = trichCacSo(trong: pt.chu).first { kq.targetThuc = v }
                    else if kq.doanhThuThuc == 0, let v = chuyenChuoiThanhSoDoanhThu(pt.chu), v > 0 { kq.doanhThuThuc = v }
                }
                for pt in phai {
                    if boDau(pt.chu).contains("TARGET"), let v = trichCacSo(trong: pt.chu).first { kq.targetQuyDoi = v }
                    else if kq.doanhThuQuyDoi == 0, let v = chuyenChuoiThanhSoDoanhThu(pt.chu), v > 0 { kq.doanhThuQuyDoi = v }
                }
            }
        }

        return kq
    }
}

private extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}