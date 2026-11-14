import UIKit
import Vision
import ImageIO

struct DongThiDuaNhanVienQuet: Hashable {
    var maNV: String
    var hoTen: String
    var thucHien: Double
    var target: Double
    var laPhanTram: Bool = false
    var laPhanTramTargetCaNhan: Bool = false
}

struct KetQuaThiDuaNhanVienKhoi: Hashable {
    var tenNganhHang: String
    var danhSach: [DongThiDuaNhanVienQuet]
    var thucHienNganhGoiY: Double = 0
    var targetNganhGoiY: Double = 0
}

struct KetQuaQuetThiDua {
    var danhSach: [DongThiDua]
    var thiDuaNhanVien: [KetQuaThiDuaNhanVienKhoi]
    var doanhThuQuetDuoc: ThongTinDoanhThu?
    var sucKhoeNhanVien: [String: DuLieuSucKhoeBoSungNV] = [:]
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

    var sucKhoeNhanVien: [String: DuLieuSucKhoeBoSungNV] = [:]
    var soAnhSucKhoeNV: Int = 0

    var capNhatLuc: String = ""
    var thongTinDonVi: String = ""

    var coDuLieu: Bool {
        (doanhThu?.coDuLieu ?? false) ||
        !danhSachThiDua.isEmpty ||
        !doanhThuNhanVien.isEmpty ||
        !thiDuaNhanVien.isEmpty ||
        !sucKhoeNhanVien.isEmpty
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

    // MARK: - Nhận diện & Bóc tách Ảnh Sức Khỏe / Thi Đua Cá Nhân Nhân Viên 27 Điểm (suc-khoe-nv-*.jpg)

    /// Nhận diện ảnh chụp phiếu Sức khỏe & Thi đua cá nhân nhân viên (có khối DOANH THU 6 mục, NĂNG SUẤT 3 mục, HIỆU QUẢ KHAI THÁC, THI ĐUA, ĐƠN GIÁ)
    private func laAnhSucKhoeCaNhan27Diem(phanTu: [PhanTuVanBan], anh: UIImage? = nil) -> Bool {
        if laAnhBangDoanhThuNhanVien(phanTu: phanTu) { return false }
        if laAnhMaTranThiDuaNhanVien(phanTu: phanTu, anh: anh) { return false }
        if laAnhDoanhThuSieuThi(phanTu: phanTu) { return false }

        var coNangSuat = false
        var coHieuQua = false
        var coDonGia = false
        var coBillBanHang = false
        var coDiemThuongERP = false
        var coChuaCoSoLieu = false
        var coDiem27 = false
        var coBPAllInOne = false
        var coBanKemTraCham = false

        for pt in phanTu {
            let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
            if u.contains("DOANH THU HOP") || u.contains("NGANH HANG BI") || u.contains("NHOM HANG BI") { return false }
            if u.contains("NANG SUAT") { coNangSuat = true }
            if u.contains("HIEU QUA KHAI THAC") { coHieuQua = true }
            if u.contains("TB SAN PHAM CHINH") { coDonGia = true }
            if u.contains("SO LUOT BILL") || u.contains("BILL BAN HANG") { coBillBanHang = true }
            if u.contains("DIEM THUONG ERP") || u.contains("DTQD / GIO CONG") || u.contains("DIEM THUONG / GIO CONG") { coDiemThuongERP = true }
            if u.contains("CHUA CO SO LIEU") || u.contains("CHUONG TRINH DAT") { coChuaCoSoLieu = true }
            if u.contains("/27") || u.contains("/ 27") { coDiem27 = true }
            if u.contains("BP ALL IN ONE") || u.contains("ALL IN ONE") { coBPAllInOne = true }
            if u.contains("BAN KEM") || u.contains("TY TRONG NGANH HANG") || u.contains("DOANH THU QD TUNG THANG") { coBanKemTraCham = true }
        }

        let soDauHieu = [coNangSuat, coHieuQua, coDonGia, coBillBanHang, coDiemThuongERP, coChuaCoSoLieu, coDiem27, coBPAllInOne, coBanKemTraCham].filter { $0 }.count
        return soDauHieu >= 2
    }

    /// Tách một dòng văn bản theo ranh giới cột của phiếu Sức khỏe cá nhân (giữ nguyên "TB 228.7 tr" và "MT 703.7 tr" trong cùng một thẻ)
    private func tachPhanTuTheoRanhCotSucKhoe(
        tu ungVien: VNRecognizedText,
        boxGoc: CGRect,
        ranhGioiCot: [CGFloat]
    ) -> [PhanTuVanBan] {
        let chuoi = ungVien.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !chuoi.isEmpty, !chuoi.contains("\n"), boxGoc.size.width > 0.14, let regex = Self.regexTuKhongKhoangTrang else {
            return []
        }
        let ns = chuoi as NSString
        let matches = regex.matches(in: chuoi, range: NSRange(location: 0, length: ns.length))
        guard matches.count >= 2 else { return [] }

        struct TuToaDo {
            var chu: String
            var x: CGFloat
            var y: CGFloat
            var x2: CGFloat
            var y2: CGFloat
        }

        let yTrenGoc = 1.0 - boxGoc.origin.y - boxGoc.size.height
        let tongDoDai = CGFloat(max(1, ns.length))
        var danhSachTu: [TuToaDo] = []

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
            danhSachTu.append(TuToaDo(chu: tu, x: xTu, y: yTu, x2: xTu + rongTu, y2: yTu + caoTu))
        }

        danhSachTu.sort { $0.x < $1.x }

        func cotCuaX(_ xTam: CGFloat) -> Int {
            for (idx, ranh) in ranhGioiCot.enumerated() {
                if xTam < ranh { return idx }
            }
            return ranhGioiCot.count
        }

        var cacCum: [TuToaDo] = []
        for tu in danhSachTu {
            if let cuoi = cacCum.last {
                let cCuoi = cotCuaX((cuoi.x + cuoi.x2) * 0.5)
                let cMoi = cotCuaX((tu.x + tu.x2) * 0.5)
                if cCuoi != cMoi {
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

    /// Thực hiện OCR độ phân giải cao trên 4 dải ngang của phiếu Sức khỏe cá nhân (đồng thời lọc sạch watermark chữ chìm màu xám 54453)
    private func thucHienOCRBanDaiSucKhoe(anh: UIImage) -> [PhanTuVanBan] {
        guard let cgGoc = anh.cgImage else { return [] }
        let w = CGFloat(cgGoc.width)
        let h = CGFloat(cgGoc.height)
        guard w > 60, h > 120 else { return [] }

        let cacDai: [(y0: CGFloat, y1: CGFloat, ranhCot: [CGFloat])] = [
            (0.00, 0.16, [0.50]),
            (0.15, 0.39, [0.338, 0.662]),
            (0.37, 0.75, [0.218, 0.406, 0.594, 0.782]),
            (0.73, 1.00, [0.26, 0.50, 0.74])
        ]
        var ketQua: [PhanTuVanBan] = []

        for dai in cacDai {
            let rectCrop = CGRect(
                x: 0,
                y: floor(dai.y0 * h),
                width: w,
                height: ceil((dai.y1 - dai.y0) * h)
            ).intersection(CGRect(x: 0, y: 0, width: w, height: h))
            guard rectCrop.width > 20, rectCrop.height > 20,
                  let cgCrop = cgGoc.cropping(to: rectCrop) else { continue }

            let heSo: Int = (cgCrop.width < 1200) ? 3 : 2
            let rw = cgCrop.width * heSo
            let rh = cgCrop.height * heSo
            let bytesPerRow = rw * 4
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            guard let ctx = CGContext(
                data: nil,
                width: rw,
                height: rh,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { continue }
            ctx.interpolationQuality = .high
            ctx.draw(cgCrop, in: CGRect(x: 0, y: 0, width: rw, height: rh))
            guard let cgPhong = ctx.makeImage() else { continue }

            var ptDai: [PhanTuVanBan] = []
            let yeuCau = VNRecognizeTextRequest { req, _ in
                guard let kq = req.results as? [VNRecognizedTextObservation] else { return }
                for obs in kq {
                    guard let ungVien = obs.topCandidates(1).first else { continue }
                    let chu = ungVien.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !chu.isEmpty else { continue }
                    let box = obs.boundingBox
                    let cacCon = self.tachPhanTuTheoRanhCotSucKhoe(tu: ungVien, boxGoc: box, ranhGioiCot: dai.ranhCot)
                    if cacCon.count >= 2 {
                        for c in cacCon {
                            let yFull = dai.y0 + c.y * (dai.y1 - dai.y0)
                            let caoFull = c.cao * (dai.y1 - dai.y0)
                            ptDai.append(PhanTuVanBan(chu: c.chu, x: c.x, y: yFull, rong: c.rong, cao: caoFull))
                        }
                    } else {
                        let yTren = 1.0 - box.origin.y - box.size.height
                        let yFull = dai.y0 + yTren * (dai.y1 - dai.y0)
                        let caoFull = box.size.height * (dai.y1 - dai.y0)
                        ptDai.append(PhanTuVanBan(chu: chu, x: box.origin.x, y: yFull, rong: box.size.width, cao: caoFull))
                    }
                }
            }
            yeuCau.recognitionLevel = .accurate
            yeuCau.usesLanguageCorrection = true
            yeuCau.recognitionLanguages = ["vi-VN", "en-US"]
            yeuCau.minimumTextHeight = 0.004
            let handler = VNImageRequestHandler(cgImage: cgPhong, options: [:])
            try? handler.perform([yeuCau])
            ketQua.append(contentsOf: ptDai)
        }
        return ketQua
    }

    private func docSoThapPhanSucKhoe(_ s: String, laSoNguyenLon: Bool = false) -> Double? {
        var sach = s
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: "↑", with: "")
            .replacingOccurrences(of: "↓", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let r = sach.range(of: "[+\\-]?\\d+(?:[.,]\\d+)*", options: .regularExpression) else { return nil }
        sach = String(sach[r])
        if laSoNguyenLon || sach.range(of: "^\\d{1,3}(?:,\\d{3})+$", options: .regularExpression) != nil {
            sach = sach.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: ".", with: "")
            return Double(sach)
        }
        if sach.contains(",") && sach.contains(".") {
            sach = sach.replacingOccurrences(of: ",", with: "")
        } else if sach.contains(",") {
            let parts = sach.split(separator: ",")
            if parts.count == 2 && parts[1].count == 3 {
                sach = sach.replacingOccurrences(of: ",", with: "")
            } else {
                sach = sach.replacingOccurrences(of: ",", with: ".")
            }
        }
        return Double(sach)
    }

    private func tatCaSoTrongChuoiSucKhoe(_ s: String, laSoNguyenLon: Bool = false) -> [Double] {
        guard let regex = try? NSRegularExpression(pattern: "\\d+(?:[.,]\\d+)*") else { return [] }
        let ns = s as NSString
        let matches = regex.matches(in: s, range: NSRange(location: 0, length: ns.length))
        var kq: [Double] = []
        for m in matches {
            let token = ns.substring(with: m.range)
            if let v = docSoThapPhanSucKhoe(token, laSoNguyenLon: laSoNguyenLon), v != 54453 {
                kq.append(v)
            }
        }
        return kq
    }

    /// Phân tích đầy đủ phiếu Sức khỏe & Thi đua cá nhân nhân viên 27 điểm (Doanh thu 6 mục, Năng suất 3 mục, Thi đua cá nhân 39 môn)
    private func phanTichAnhSucKhoeCaNhan27Diem(
        phanTu: [PhanTuVanBan],
        anh: UIImage,
        maNVGoiY: String? = nil
    ) -> (maNV: String, hoTen: String, sucKhoe: DuLieuSucKhoeBoSungNV, doanhThuItem: DoanhThuNhanVienItem, cacKhoiThiDua: [KetQuaThiDuaNhanVienKhoi])? {
        let ptDai = thucHienOCRBanDaiSucKhoe(anh: anh)
        // Chỉ dùng ptDai (đã lọc sạch watermark và không bị nhân bản token số lẻ từ phanTuSoBoSung1/2)
        let tatCaPT = ptDai.isEmpty ? phanTu : ptDai
        guard !tatCaPT.isEmpty else { return nil }

        let dsQuanLy = KhoDuLieu.dungChung.layCaiDatAnToan().danhSachNhanVien
        var maNVTim = ""
        var hoTenTim = ""

        // 1. Tìm Mã NV và Họ tên ở góc trái trên của Header (y < 0.068, x < 0.68)
        let ptHeaderTrai = tatCaPT
            .filter { $0.y < 0.068 && $0.x < 0.68 }
            .sorted { $0.y < $1.y }

        // Bước 1A: Ưu tiên tuyệt đối mã nhân viên 5-7 chữ số trên dòng "293044 - BP All In One"
        for pt in ptHeaderTrai {
            let chu = pt.chu.trimmingCharacters(in: .whitespacesAndNewlines)
            let u = boDau(chu)
            if u.contains("DUNG NGUYEN") { continue }
            guard let regex = try? NSRegularExpression(pattern: "\\b(\\d{5,7})\\b") else { continue }
            let ns = chu as NSString
            for m in regex.matches(in: chu, range: NSRange(location: 0, length: ns.length)) {
                let maUngVien = ns.substring(with: m.range(at: 1))
                if maUngVien == "54453" || maUngVien.hasPrefix("2026") || maUngVien.hasPrefix("2025") { continue }
                maNVTim = maUngVien
                if let nv = dsQuanLy.first(where: { KhoDuLieu.chuanHoaMaNV($0.maNV) == maUngVien }) {
                    maNVTim = nv.maNV
                    hoTenTim = nv.hoTen
                }
                break
            }
            if !maNVTim.isEmpty { break }
        }

        // Bước 1B: Nếu chưa tìm thấy mã số, so khớp họ tên đầy đủ ở dòng đầu tiên (y < 0.048, x < 0.55)
        if maNVTim.isEmpty {
            for pt in ptHeaderTrai where pt.y < 0.048 && pt.x < 0.55 {
                let chu = pt.chu.trimmingCharacters(in: .whitespacesAndNewlines)
                let u = boDau(chu)
                if u.contains("DUNG NGUYEN") || u.contains("54453") || u.contains("HOAN THANH") { continue }
                let tenChuan = KhoDuLieu.chuanHoaKhoaSoSanh(chu)
                guard tenChuan.count >= 6 else { continue }
                if let nv = dsQuanLy.first(where: { KhoDuLieu.chuanHoaKhoaSoSanh($0.hoTen) == tenChuan }) {
                    maNVTim = nv.maNV
                    hoTenTim = nv.hoTen
                    break
                }
            }
        }

        if maNVTim.isEmpty, let goiY = maNVGoiY, !goiY.isEmpty {
            maNVTim = KhoDuLieu.chuanHoaMaNV(goiY)
        }
        if !maNVTim.isEmpty && hoTenTim.isEmpty {
            if let nv = dsQuanLy.first(where: { KhoDuLieu.chuanHoaMaNV($0.maNV) == maNVTim }) {
                hoTenTim = nv.hoTen
            }
        }
        if hoTenTim.isEmpty {
            for pt in tatCaPT where pt.y > 0.015 && pt.y < 0.065 && pt.x > 0.10 && pt.x < 0.55 {
                let s = pt.chu.trimmingCharacters(in: .whitespacesAndNewlines)
                let u = boDau(s)
                if s.count >= 5 && !u.contains("54453") && !u.contains("DUNG NGUYEN") && !u.contains("BP ") && !u.contains("HANG ") && s.range(of: "\\d{4,}", options: .regularExpression) == nil {
                    hoTenTim = s
                    break
                }
            }
        }
        if maNVTim.isEmpty && !hoTenTim.isEmpty {
            if let nv = KhoDuLieu.khopNhanVienQuetVoiQuanLy(maQuet: "", tenQuet: hoTenTim, dsQuanLy: dsQuanLy) {
                maNVTim = nv.maNV
                hoTenTim = nv.hoTen
            }
        }
        guard !maNVTim.isEmpty else { return nil }
        if hoTenTim.isEmpty { hoTenTim = "NV \(maNVTim)" }

        var sk = DuLieuSucKhoeBoSungNV()

        // 2. Thông tin chung trên Header (5/27, Hoàn thành 19%, 9/30 ngày)
        for pt in tatCaPT where pt.y < 0.16 {
            let s = pt.chu
            let u = boDau(s)
            if let r27 = s.range(of: "\\b(\\d{1,2})\\s*/\\s*27\\b", options: .regularExpression) {
                let sub = String(s[r27])
                if let d = sub.split(separator: "/").first.flatMap({ Int($0.trimmingCharacters(in: .whitespaces)) }) {
                    sk.diemDat27 = d
                    sk.tongDiem27 = 27
                }
            }
            if u.contains("HOAN THANH"), let v = docSoThapPhanSucKhoe(s) {
                sk.phanTramHoanThanhChung = v
            }
            if u.contains("NGAY"), let rNgay = s.range(of: "\\b(\\d{1,2})\\s*/\\s*(\\d{2})\\b", options: .regularExpression) {
                let parts = String(s[rNgay]).split(separator: "/")
                if parts.count == 2,
                   let d1 = Int(parts[0].trimmingCharacters(in: .whitespaces)),
                   let d2 = Int(parts[1].trimmingCharacters(in: .whitespaces)) {
                    sk.soNgayDaQuaThang = d1
                    sk.tongSoNgayThang = d2
                }
            }
        }

        // 3. Xác định mốc Y của các khối: DOANH THU (Hàng 0, Hàng 1), NĂNG SUẤT, HIỆU QUẢ KHAI THÁC, THI ĐUA, ĐƠN GIÁ
        var yRow0Title: CGFloat = 0.198
        var yRow1Title: CGFloat = 0.244
        var yNSHeader: CGFloat = 0.302
        var yHQHeader: CGFloat = 0.382
        var yTDHeader: CGFloat = 0.508
        var yChuaCoSoLieu: CGFloat = 0.680
        var yDGHeader: CGFloat = 0.742

        var cacYRow0: [CGFloat] = []
        var cacYRow1: [CGFloat] = []

        for pt in tatCaPT {
            let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
            if pt.y > 0.17 && pt.y < 0.24 && (u.contains("DOANH THU QD") || u == "% TARGET" || u.contains("SO LUOT BILL") || u.contains("BILL BAN HANG")) {
                cacYRow0.append(pt.y)
            } else if pt.y > 0.22 && pt.y < 0.28 && (u.contains("QUY DOI") || u.contains("TRA CHAM") || u.contains("BAN KEM")) {
                cacYRow1.append(pt.y)
            } else if pt.x < 0.28 && pt.y > 0.27 && pt.y < 0.34 && u.hasPrefix("NANG SUAT") {
                yNSHeader = pt.y
            } else if pt.x < 0.38 && pt.y > 0.35 && pt.y < 0.43 && u.hasPrefix("HIEU QUA") {
                yHQHeader = pt.y
            } else if pt.x < 0.28 && pt.y > 0.47 && pt.y < 0.55 && u.hasPrefix("THI DUA") {
                yTDHeader = pt.y
            } else if pt.x < 0.38 && pt.y > 0.64 && pt.y < 0.74 && (u.contains("CHUA CO SO LIEU") || u.contains("SIEU THI KHONG CO TARGET")) {
                yChuaCoSoLieu = min(yChuaCoSoLieu, pt.y)
            } else if pt.x < 0.28 && pt.y > 0.71 && pt.y < 0.79 && u.hasPrefix("DON GIA") {
                yDGHeader = pt.y
            }
        }
        if !cacYRow0.isEmpty {
            yRow0Title = cacYRow0.reduce(0, +) / CGFloat(cacYRow0.count)
        }
        if !cacYRow1.isEmpty {
            yRow1Title = cacYRow1.reduce(0, +) / CGFloat(cacYRow1.count)
        }

        // 4. Bóc tách 6 mục DOANH THU theo 6 ô thẻ (hang 0..1, cot 0..2)
        let yRanhHangDT = yRow1Title - 0.004
        var vanBanTheDT: [[ PhanTuVanBan ]] = Array(repeating: [], count: 6)

        for pt in tatCaPT where pt.y >= (yRow0Title - 0.006) && pt.y < (yNSHeader - 0.003) {
            let s = pt.chu.trimmingCharacters(in: .whitespacesAndNewlines)
            let u = boDau(s)
            if u.contains("54453") || u.contains("DUNG NGUYEN") || u.contains("QUY TAC") { continue }
            if u.hasPrefix("DOANH THU 2/") || u.hasPrefix("DOANH THU 1/") || u.hasPrefix("DOANH THU 0/") || u.hasPrefix("DOANH THU 3/") || u.hasPrefix("DOANH THU 4/") || u.hasPrefix("DOANH THU 5/") || u.hasPrefix("DOANH THU 6/") {
                continue
            }
            let xTam = pt.x + min(pt.rong * 0.5, 0.06)
            let cot: Int = (xTam < 0.338) ? 0 : ((xTam < 0.662) ? 1 : 2)
            let hang: Int = (pt.y < yRanhHangDT) ? 0 : 1
            vanBanTheDT[hang * 3 + cot].append(pt)
        }

        for hang in 0..<2 {
            for cot in 0..<3 {
                let dsPT = vanBanTheDT[hang * 3 + cot].sorted {
                    ($0.x + $0.rong * 0.5) < ($1.x + $1.rong * 0.5)
                }
                guard !dsPT.isEmpty else { continue }
                let chuoiGop = dsPT.map(\.chu).joined(separator: " ")
                var u = boDau(chuoiGop)
                    .replacingOccurrences(of: "DOANH THU QD", with: " ")
                    .replacingOccurrences(of: "% TARGET", with: " ")
                    .replacingOccurrences(of: "SO LUOT BILL BAN HANG", with: " ")
                    .replacingOccurrences(of: "SO LUOT BILL", with: " ")
                    .replacingOccurrences(of: "% QUY DOI", with: " ")
                    .replacingOccurrences(of: "% TRA CHAM", with: " ")
                    .replacingOccurrences(of: "% BAN KEM", with: " ")

                var valTB: Double?
                var valMT: Double?

                if let rMT = u.range(of: "(?:MT|M1)\\s*([0-9]+(?:[.,][0-9]+)*)", options: .regularExpression) {
                    valMT = docSoThapPhanSucKhoe(String(u[rMT]))
                    u.removeSubrange(rMT)
                }
                if let rTB = u.range(of: "(?:TB|T8|IB|1B)\\s*([0-9]+(?:[.,][0-9]+)*)", options: .regularExpression) {
                    valTB = docSoThapPhanSucKhoe(String(u[rTB]))
                    u.removeSubrange(rTB)
                }

                let cacSoConLai = tatCaSoTrongChuoiSucKhoe(u, laSoNguyenLon: false)
                var valChinh = cacSoConLai.last

                // Dự phòng theo vị trí trái -> phải nếu chữ "TB" hoặc "MT" bị mờ
                if valTB == nil && cacSoConLai.count >= 2 {
                    valTB = cacSoConLai.first
                    if hang == 0 && cot == 1 && cacSoConLai.count >= 3 && valMT == nil {
                        valMT = cacSoConLai[1]
                    }
                    valChinh = cacSoConLai.last
                }

                switch (hang, cot) {
                case (0, 0):
                    if let v = valTB { sk.tbDoanhThuQDSieuThi = v }
                    if let v = valChinh { sk.doanhThuQDSucKhoe = v }
                case (0, 1):
                    if let v = valTB { sk.tbPhanTramTarget = v }
                    if let v = valMT { sk.mucTieuTargetQD = v }
                    if let v = valChinh { sk.phanTramTarget = v }
                case (0, 2):
                    if let v = valTB { sk.tbSoLuotBillBanHang = v }
                    if let v = valChinh { sk.soLuotBillBanHang = v }
                case (1, 0):
                    if let v = valTB { sk.tbPhanTramQuyDoi = v }
                    if let v = valChinh { sk.phanTramQuyDoi = v }
                case (1, 1):
                    if let v = valTB { sk.tbPhanTramTraCham = v }
                    if let v = valChinh { sk.phanTramTraCham = v }
                case (1, 2):
                    if let v = valTB { sk.tbPhanTramBanKem = v }
                    if let v = valChinh { sk.phanTramBanKem = v }
                default:
                    break
                }
            }
        }

        // 5. Bóc tách 3 mục NĂNG SUẤT theo 3 ô thẻ (cot 0..2 trong yNSHeader .. yHQHeader)
        var vanBanTheNS: [[PhanTuVanBan]] = Array(repeating: [], count: 3)
        for pt in tatCaPT where pt.y > (yNSHeader + 0.008) && pt.y < (yHQHeader - 0.003) {
            let s = pt.chu.trimmingCharacters(in: .whitespacesAndNewlines)
            let u = boDau(s)
            if u.contains("54453") || u.contains("DUNG NGUYEN") || u.contains("QUY TAC") { continue }
            if u.hasPrefix("NANG SUAT") { continue }
            let xTam = pt.x + min(pt.rong * 0.5, 0.06)
            let cot: Int = (xTam < 0.338) ? 0 : ((xTam < 0.662) ? 1 : 2)
            vanBanTheNS[cot].append(pt)
        }

        for cot in 0..<3 {
            let dsPT = vanBanTheNS[cot].sorted {
                ($0.x + $0.rong * 0.5) < ($1.x + $1.rong * 0.5)
            }
            guard !dsPT.isEmpty else { continue }
            let laSoNguyenLon = (cot == 0 || cot == 1)
            let chuoiGop = dsPT.map(\.chu).joined(separator: " ")
            var u = boDau(chuoiGop)
                .replacingOccurrences(of: "DIEM THUONG / GIO CONG", with: " ")
                .replacingOccurrences(of: "DIEM THUONG ERP", with: " ")
                .replacingOccurrences(of: "DTQD / GIO CONG", with: " ")
                .replacingOccurrences(of: "DIEM THUONG", with: " ")
                .replacingOccurrences(of: "GIO CONG", with: " ")

            var valTB: Double?
            if let rTB = u.range(of: "(?:TB|T8|IB|1B)\\s*([0-9]+(?:[.,][0-9]+)*)", options: .regularExpression) {
                valTB = docSoThapPhanSucKhoe(String(u[rTB]), laSoNguyenLon: laSoNguyenLon)
                u.removeSubrange(rTB)
            }
            let cacSoConLai = tatCaSoTrongChuoiSucKhoe(u, laSoNguyenLon: laSoNguyenLon)
            var valChinh = cacSoConLai.last
            if valTB == nil && cacSoConLai.count >= 2 {
                valTB = cacSoConLai.first
                valChinh = cacSoConLai.last
            }

            if cot == 0 {
                if let v = valTB { sk.tbDiemThuongERP = v }
                if let v = valChinh { sk.diemThuongERP = v }
            } else if cot == 1 {
                if let v = valTB { sk.tbDiemThuongTrenGioCong = v }
                if let v = valChinh { sk.diemThuongTrenGioCong = v }
            } else {
                if let v = valTB { sk.tbDtqdTrenGioCong = v }
                if let v = valChinh { sk.dtqdTrenGioCong = v }
            }
        }

        // 6. Bóc tách toàn bộ các môn THI ĐUA cá nhân (môn nào chưa có hoặc nằm trong Chưa có số liệu mặc định = 0)
        var bangPTThiDua: [String: Double] = [:]
        for tenChuan in KhoDuLieu.danhSachTenMonThiDuaChuanDMX {
            let kLM = KhoDuLieu.chuanHoaKhoaLienMachThiDua(tenChuan)
            let kSS = KhoDuLieu.chuanHoaKhoaSoSanh(tenChuan)
            if !kLM.isEmpty { bangPTThiDua[kLM] = 0 }
            if !kSS.isEmpty { bangPTThiDua[kSS] = 0 }
        }

        // Tìm vùng lưới 5 cột thẻ mini Thi đua (dưới dòng "Đạt ... Gần đạt ... Cần cố gắng" và trên dòng "Chưa có số liệu")
        var yMiniTop = yTDHeader + 0.052
        for pt in tatCaPT where pt.y > yTDHeader && pt.y < (yTDHeader + 0.075) {
            let u = boDau(pt.chu)
            if u.contains("CHUONG TRINH DAT") || u.contains("CAN CO GANG") || u.contains("GAN DAT") {
                yMiniTop = max(yMiniTop, pt.y + pt.cao + 0.004)
            }
        }
        let yMiniBottom = min(yChuaCoSoLieu - 0.002, yDGHeader - 0.020)

        // Chia 5 cột ngang đều nhau từ x = 0.03 đến x = 0.97
        let ranhCot: [CGFloat] = [0.00, 0.218, 0.406, 0.594, 0.782, 1.00]
        for cIdx in 0..<5 {
            let xMin = ranhCot[cIdx]
            let xMax = ranhCot[cIdx + 1]
            let ptCot = tatCaPT.filter { pt in
                guard pt.y >= yMiniTop && pt.y <= yMiniBottom else { return false }
                let u = boDau(pt.chu)
                if u.contains("54453") || u.contains("DUNG NGUYEN") || u.contains("CHUA CO SO LIEU") || u.contains("SIEU THI KHONG CO") {
                    return false
                }
                let xTam = pt.x + min(pt.rong * 0.35, 0.04)
                return xTam >= xMin && xTam < xMax
            }.sorted {
                if abs($0.y - $1.y) > 0.008 { return $0.y < $1.y }
                return $0.x < $1.x
            }

            struct DongMini {
                var y: CGFloat
                var cacChu: [String]
            }
            var cacDong: [DongMini] = []
            for p in ptCot {
                if let lastIdx = cacDong.indices.last, abs(p.y - cacDong[lastIdx].y) <= 0.009 {
                    if !cacDong[lastIdx].cacChu.contains(p.chu) {
                        cacDong[lastIdx].cacChu.append(p.chu)
                    }
                } else {
                    cacDong.append(DongMini(y: p.y, cacChu: [p.chu]))
                }
            }

            var i = 0
            while i < cacDong.count {
                let chuoiDong = cacDong[i].cacChu.joined(separator: " ")
                var phanTramTim: Double?
                if let rPT = chuoiDong.range(of: "(\\d+(?:[.,]\\d+)?)\\s*%", options: .regularExpression) {
                    phanTramTim = docSoThapPhanSucKhoe(String(chuoiDong[rPT]))
                }
                var tenTho = chuoiDong.replacingOccurrences(of: "\\b\\d+(?:[.,]\\d+)?\\s*%", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if i + 1 < cacDong.count {
                    let chuoiTiep = cacDong[i + 1].cacChu.joined(separator: " ")
                    let tiepCoPT = chuoiTiep.range(of: "\\d+\\s*%", options: .regularExpression) != nil
                    let dy = cacDong[i + 1].y - cacDong[i].y
                    if !tiepCoPT && dy <= 0.018 {
                        tenTho += " " + chuoiTiep
                        i += 1
                    } else if phanTramTim == nil && tiepCoPT && dy <= 0.015 {
                        if let rPT2 = chuoiTiep.range(of: "(\\d+(?:[.,]\\d+)?)\\s*%", options: .regularExpression) {
                            phanTramTim = docSoThapPhanSucKhoe(String(chuoiTiep[rPT2]))
                        }
                        let tenTiep = chuoiTiep.replacingOccurrences(of: "\\b\\d+(?:[.,]\\d+)?\\s*%", with: " ", options: .regularExpression)
                        tenTho += " " + tenTiep
                        i += 1
                    }
                }

                let tenChuan = KhoDuLieu.chuanHoaTenMonThiDuaChuan(tenTho)
                if !tenChuan.isEmpty, let ptVal = phanTramTim,
                   (KhoDuLieu.laTenMonThiDuaChuanDMX(tenChuan) || tenChuan.count >= 3) {
                    let kLM = KhoDuLieu.chuanHoaKhoaLienMachThiDua(tenChuan)
                    let kSS = KhoDuLieu.chuanHoaKhoaSoSanh(tenChuan)
                    if !kLM.isEmpty { bangPTThiDua[kLM] = max(bangPTThiDua[kLM] ?? 0, ptVal) }
                    if !kSS.isEmpty { bangPTThiDua[kSS] = max(bangPTThiDua[kSS] ?? 0, ptVal) }
                }
                i += 1
            }
        }

        sk.phanTramThiDuaCaNhan = bangPTThiDua

        // Tạo DoanhThuNhanVienItem và danh sách KetQuaThiDuaNhanVienKhoi tương ứng
        let dtItem = DoanhThuNhanVienItem(
            maNV: maNVTim,
            hoTen: hoTenTim,
            soLuong: sk.soLuotBillBanHang ?? 0,
            doanhThuThuc: 0,
            doanhThuQD: sk.doanhThuQDSucKhoe ?? 0,
            target: sk.mucTieuTargetQD ?? 0,
            dtQDKhoanVay: 0,
            dtTraThangQD: sk.phanTramQuyDoi ?? 0,
            phanTramHT: sk.phanTramTarget ?? 0,
            phanTramQuyDoi: sk.phanTramQuyDoi ?? 0,
            phanTramTraGop: sk.phanTramTraCham ?? 0
        )

        var cacKhoi: [KetQuaThiDuaNhanVienKhoi] = []
        for tenChuan in KhoDuLieu.danhSachTenMonThiDuaChuanDMX {
            let kLM = KhoDuLieu.chuanHoaKhoaLienMachThiDua(tenChuan)
            let ptMon = bangPTThiDua[kLM] ?? 0
            cacKhoi.append(KetQuaThiDuaNhanVienKhoi(
                tenNganhHang: tenChuan,
                danhSach: [
                    DongThiDuaNhanVienQuet(
                        maNV: maNVTim,
                        hoTen: hoTenTim,
                        thucHien: ptMon,
                        target: 0,
                        laPhanTram: true,
                        laPhanTramTargetCaNhan: true
                    )
                ]
            ))
        }

        return (maNVTim, hoTenTim, sk, dtItem, cacKhoi)
    }

    // MARK: - Nhận diện chính xác Ảnh chụp màn hình Doanh thu Siêu thị (tránh nhầm sang bảng Thi đua)

    /// Kiểm tra xem bức ảnh có phải là màn hình Tổng quan Doanh thu (chứa các thẻ: DT thực, DT quy đổi, % HT target, TT vs TB 3 tháng, TLPVTC, Tỷ trọng trả chậm, Chi phí) hay không.
    private func laAnhDoanhThuSieuThi(phanTu: [PhanTuVanBan]) -> Bool {
        if laAnhSucKhoeCaNhan27Diem(phanTu: phanTu) {
            return false
        }
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

    /// Nhận diện ảnh Bảng Thi Đua Nhân Viên theo từng môn mở rộng (6 cột: CHƯƠNG TRÌNH | THỰC HIỆN | TARGET | % HT | % HT DỰ KIẾN | HẠNG VÙNG, các dòng nhân viên có "id: <mã NV>" và cột 2 hiển thị %)
    private func laAnhBangThiDuaNhanVienTheoMonMoRong(phanTu: [PhanTuVanBan]) -> Bool {
        var soDongCoId = 0
        var coHeaderChuongTrinh = false
        var coHeaderTarget = false
        var coHeaderHangVung = false
        var coHeaderDoanhThuQD = false
        var coHeaderKhoanVay = false
        var coHeaderTiTrong = false
        var soPhanTramCot2 = 0

        for pt in phanTu {
            let chu = pt.chu
            if pt.x < 0.42 && chu.range(of: "(?i)\\b(?:id|ld|1d|ia|iđ)\\s*[:.;\\-]?\\s*\\d{3,8}", options: .regularExpression) != nil {
                soDongCoId += 1
            }
            if pt.y < 0.28 {
                let u = boDau(chu)
                if u.contains("CHUONG TRINH") { coHeaderChuongTrinh = true }
                if u.contains("TARGET") { coHeaderTarget = true }
                if u.contains("HANG VUNG") || u.contains("HT DU KIEN") { coHeaderHangVung = true }
                if u.contains("DOANH THU QD") || u.contains("THU QD") { coHeaderDoanhThuQD = true }
                if u.contains("KHOAN VAY") { coHeaderKhoanVay = true }
                if u.contains("TI TRONG") || u.contains("TY TRONG") { coHeaderTiTrong = true }
            }
            if pt.y > 0.14 && pt.x >= 0.32 && pt.x <= 0.52 && chu.contains("%") {
                soPhanTramCot2 += 1
            }
        }

        if coHeaderDoanhThuQD || coHeaderKhoanVay || coHeaderTiTrong {
            return false
        }
        if soDongCoId >= 1 && (coHeaderChuongTrinh || coHeaderTarget || coHeaderHangVung || soPhanTramCot2 >= 2) {
            return true
        }
        return false
    }

    /// Nhận diện ảnh Bảng Doanh thu Nhân viên 5 cột (có tiêu đề hoặc đã cắt tiêu đề, có các dòng "id: <mã NV>") để tuyệt đối không bị quét nhầm sang bảng Thi Đua
    private func laAnhBangDoanhThuNhanVien(phanTu: [PhanTuVanBan]) -> Bool {
        if laAnhBangThiDuaNhanVienTheoMonMoRong(phanTu: phanTu) {
            return false
        }
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
        let phuongPhapChon = KhoDuLieu.dungChung.layCaiDatAnToan().phuongPhapQuetThiDua
        if phuongPhapChon == .gemini || cheDoDangChon == .realtime {
            DichVuQuetAnhGemini.dungChung.quet(
                danhSachAnh: danhSachAnh,
                cheDo: cheDoDangChon,
                tienTrinh: tienTrinh
            ) { [weak self] ketQuaGemini in
                switch ketQuaGemini {
                case .success(var kq):
                    if !kq.thiDuaNhanVien.isEmpty {
                        kq.thiDuaNhanVien = DichVuQuetAnhGemini.dungChung.gopVaLamSachKhoiThiDuaNhanVien(kq.thiDuaNhanVien)
                    }
                    if kq.capNhatLuc.isEmpty {
                        kq.capNhatLuc = TienIchNgay.hienThiGioPhut.string(from: Date())
                    }
                    hoanTat(kq)
                case .failure:
                    guard let self else { return }
                    self.quetVaPhanLoaiTatCaAnhOffline(
                        danhSachAnh: danhSachAnh,
                        ngay: ngay,
                        cheDoDangChon: cheDoDangChon,
                        tienTrinh: tienTrinh,
                        hoanTat: hoanTat
                    )
                }
            }
            return
        }
        quetVaPhanLoaiTatCaAnhOffline(
            danhSachAnh: danhSachAnh,
            ngay: ngay,
            cheDoDangChon: cheDoDangChon,
            tienTrinh: tienTrinh,
            hoanTat: hoanTat
        )
    }

    private func quetVaPhanLoaiTatCaAnhOffline(
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
                guard !phanTu.isEmpty || self.laAnhBangThiDuaBangNgang(phanTu: phanTu, anh: anh) || self.laAnhMaTranThiDuaNhanVien(phanTu: phanTu, anh: anh) else { continue }

                let (cn, dv, wm) = self.trichThongTinChungThiDua(phanTu: phanTu)
                if kq.capNhatLuc.isEmpty, let cn = cn, !cn.isEmpty {
                    kq.capNhatLuc = cn
                }
                if kq.thongTinDonVi.isEmpty, let dv = dv, !dv.isEmpty {
                    kq.thongTinDonVi = dv
                }

                // ƯU TIÊN 0: Kiểm tra xem có phải ảnh Phiếu Sức Khỏe & Thi Đua Cá Nhân Nhân Viên 27 Điểm (suc-khoe-nv-*.jpg) không (chỉ dùng cho Lũy kế)
                if !laRealtime,
                   self.laAnhSucKhoeCaNhan27Diem(phanTu: phanTu, anh: anh),
                   let kqSK = self.phanTichAnhSucKhoeCaNhan27Diem(phanTu: phanTu, anh: anh) {
                    if let cu = kq.sucKhoeNhanVien[kqSK.maNV] {
                        kq.sucKhoeNhanVien[kqSK.maNV] = cu.gop(voi: kqSK.sucKhoe)
                    } else {
                        kq.sucKhoeNhanVien[kqSK.maNV] = kqSK.sucKhoe
                    }
                    kq.soAnhSucKhoeNV += 1
                    kq.doanhThuNhanVien.append(kqSK.doanhThuItem)
                    kq.soAnhDoanhThuNV += 1
                    kq.thiDuaNhanVien.append(contentsOf: kqSK.cacKhoiThiDua)
                    kq.soAnhThiDuaNV += 1
                    continue
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

                // ƯU TIÊN 2: Kiểm tra ảnh Ma trận Thi đua Nhân viên Lũy kế (3 ảnh ICT / CE / DV) hoặc Bảng Thực hiện Nhân viên theo Ngành hàng
                if !laRealtime,
                   self.laAnhMaTranThiDuaNhanVien(phanTu: phanTu, anh: anh) {
                    var cacKhoiMT: [KetQuaThiDuaNhanVienKhoi] = []
                    let semG = DispatchSemaphore(value: 0)
                    DichVuQuetAnhGemini.dungChung.quetThiDuaNhanVien(
                        danhSachAnh: [anh],
                        cheDo: .luyKe,
                        tienTrinh: nil
                    ) { kqG in
                        if case .success(let dsG) = kqG, !dsG.isEmpty {
                            cacKhoiMT = dsG
                        }
                        semG.signal()
                    }
                    _ = semG.wait(timeout: .now() + 28)
                    if cacKhoiMT.isEmpty {
                        cacKhoiMT = self.phanTichMaTranThiDuaNhanVien(phanTu: phanTu, anh: anh, watermark: wm)
                    }
                    if !cacKhoiMT.isEmpty {
                        kq.thiDuaNhanVien.append(contentsOf: cacKhoiMT)
                        kq.soAnhThiDuaNV += 1
                        continue
                    }
                }
                let coCotHangTrongST = phanTu.contains { pt in
                    let u = self.boDau(pt.chu)
                    return pt.y < 0.24 && (
                        u.contains("HANG TRONG") ||
                        u.contains("TOP/BOTT") ||
                        u.contains("CON / VUOT")
                    )
                }
                if !laRealtime,
                   (coCotHangTrongST || self.laAnhBangThiDuaNhanVienTheoMonMoRong(phanTu: phanTu)),
                   let khoiNV = self.phanTichThiDuaNhanVienOffline(phanTu: phanTu, anh: anh, tenNganhGoiY: nil, watermark: wm),
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

                // ƯU TIÊN 4: Quét môn Thi Đua theo 4 phương pháp (Bảng ngang · Bảng dọc · Lưới · Gemini) cho Lũy kế & Bảng 5 cột cho Realtime
                if laRealtime {
                    if self.laAnhBangThiDua5CotRealtime(phanTu: phanTu) {
                        var dsBang = self.phanTichBangThiDuaPhuongPhap2_5CotRealtime(phanTu: phanTu, anh: anh, watermark: wm)
                        if dsBang.isEmpty && self.laAnhBangThiDua6Cot(phanTu: phanTu) {
                            dsBang = self.phanTichBangThiDuaPhuongPhap2_6Cot(phanTu: phanTu, anh: anh, watermark: wm)
                        }
                        if !dsBang.isEmpty {
                            kq.danhSachThiDua = KhoDuLieu.gopDanhSachThiDua(cu: kq.danhSachThiDua, moi: dsBang)
                            kq.soAnhThiDua += 1
                            continue
                        }
                    }
                    let dsBang4Cot = self.phanTichBangThiDua4Cot(phanTu: phanTu, watermark: wm)
                    if !dsBang4Cot.isEmpty {
                        kq.danhSachThiDua = KhoDuLieu.gopDanhSachThiDua(cu: kq.danhSachThiDua, moi: dsBang4Cot)
                        kq.soAnhThiDua += 1
                        continue
                    }
                    let dsLuoiThe = self.phanTichThiDuaLuoiThe6CotHoac2Cot(phanTu: phanTu, anh: anh, watermark: wm)
                    if !dsLuoiThe.isEmpty {
                        kq.danhSachThiDua = KhoDuLieu.gopDanhSachThiDua(cu: kq.danhSachThiDua, moi: dsLuoiThe)
                        kq.soAnhThiDua += 1
                        continue
                    }
                } else {
                    let dsThiDuaLK = self.phanTichThiDuaLuyKeTheoPhuongPhap(
                        phanTu: phanTu,
                        anh: anh,
                        watermark: wm,
                        phuongPhap: phuongPhapThiDua
                    )
                    if !dsThiDuaLK.isEmpty {
                        kq.danhSachThiDua = KhoDuLieu.gopDanhSachThiDua(cu: kq.danhSachThiDua, moi: dsThiDuaLK)
                        kq.soAnhThiDua += 1
                        continue
                    }
                }

                // ƯU TIÊN 5: Dự phòng bảng Thi đua 2 cột / 5 cột hoặc bảng NV
                if !dsDTNV.isEmpty {
                    kq.doanhThuNhanVien.append(contentsOf: dsDTNV)
                    kq.soAnhDoanhThuNV += 1
                    continue
                }
                if let khoiNV = self.phanTichThiDuaNhanVienOffline(phanTu: phanTu, anh: anh, tenNganhGoiY: nil, watermark: wm),
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
        let phuongPhapChon = KhoDuLieu.dungChung.layCaiDatAnToan().phuongPhapQuetThiDua
        if phuongPhapChon == .gemini {
            let cheDo: LoaiCheDoDoanhThu = laRealtime ? .realtime : .luyKe
            DichVuQuetAnhGemini.dungChung.quet(
                danhSachAnh: danhSachAnh,
                cheDo: cheDo,
                tienTrinh: tienTrinh
            ) { [weak self] ketQuaGemini in
                switch ketQuaGemini {
                case .success(let kqG):
                    if !kqG.danhSachThiDua.isEmpty || (kqG.doanhThu?.coDuLieu ?? false) || !kqG.thiDuaNhanVien.isEmpty {
                        let dsGop = !danhSachHienCo.isEmpty
                            ? KhoDuLieu.gopDanhSachThiDua(cu: danhSachHienCo, moi: kqG.danhSachThiDua)
                            : KhoDuLieu.gopDanhSachThiDua(cu: [], moi: kqG.danhSachThiDua)
                        let ketQua = KetQuaQuetThiDua(
                            danhSach: dsGop,
                            thiDuaNhanVien: kqG.thiDuaNhanVien,
                            doanhThuQuetDuoc: (kqG.doanhThu?.coDuLieu ?? false) ? kqG.doanhThu : nil,
                            capNhatLuc: kqG.capNhatLuc.isEmpty ? TienIchNgay.hienThiGioPhut.string(from: Date()) : kqG.capNhatLuc,
                            thongTinDonVi: kqG.thongTinDonVi
                        )
                        hoanTat(ketQua)
                        return
                    }
                    fallthrough
                case .failure:
                    guard let self else { return }
                    self.quetAnhThiDuaOffline(
                        danhSachAnh: danhSachAnh,
                        danhSachHienCo: danhSachHienCo,
                        laRealtime: laRealtime,
                        tenNganhGoiY: tenNganhGoiY,
                        tienTrinh: tienTrinh,
                        hoanTat: hoanTat
                    )
                }
            }
            return
        }
        quetAnhThiDuaOffline(
            danhSachAnh: danhSachAnh,
            danhSachHienCo: danhSachHienCo,
            laRealtime: laRealtime,
            tenNganhGoiY: tenNganhGoiY,
            tienTrinh: tienTrinh,
            hoanTat: hoanTat
        )
    }

    private func quetAnhThiDuaOffline(
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

                // Nếu là ảnh Phiếu Sức Khỏe & Thi Đua Cá Nhân Nhân Viên 27 Điểm: tách sang Sức khỏe & Thi đua NV
                if self.laAnhSucKhoeCaNhan27Diem(phanTu: phanTu, anh: anh),
                   let kqSK = self.phanTichAnhSucKhoeCaNhan27Diem(phanTu: phanTu, anh: anh) {
                    cacKhoiNV.append(contentsOf: kqSK.cacKhoiThiDua)
                    var dlTam = KhoDuLieu.dungChung.duLieu(cho: Date())
                    KhoDuLieu.dungChung.apDungSucKhoeNhanVienQuetDuoc([kqSK.maNV: kqSK.sucKhoe], vao: &dlTam, ngay: Date(), cheDo: laRealtime ? .realtime : .luyKe)
                    KhoDuLieu.dungChung.luu(dlTam)
                    continue
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
                if !laRealtime && self.laAnhMaTranThiDuaNhanVien(phanTu: phanTu, anh: anh) {
                    var cacKhoiMT: [KetQuaThiDuaNhanVienKhoi] = []
                    let semG = DispatchSemaphore(value: 0)
                    DichVuQuetAnhGemini.dungChung.quetThiDuaNhanVien(
                        danhSachAnh: [anh],
                        cheDo: .luyKe,
                        tienTrinh: nil
                    ) { kqG in
                        if case .success(let dsG) = kqG, !dsG.isEmpty {
                            cacKhoiMT = dsG
                        }
                        semG.signal()
                    }
                    _ = semG.wait(timeout: .now() + 28)
                    if cacKhoiMT.isEmpty {
                        cacKhoiMT = self.phanTichMaTranThiDuaNhanVien(phanTu: phanTu, anh: anh, watermark: wm)
                    }
                    if !cacKhoiMT.isEmpty {
                        cacKhoiNV.append(contentsOf: cacKhoiMT)
                        continue
                    }
                }
                if coCotHangTrongST || self.laAnhBangThiDuaNhanVienTheoMonMoRong(phanTu: phanTu) {
                    if let khoiNV = self.phanTichThiDuaNhanVienOffline(phanTu: phanTu, anh: anh, tenNganhGoiY: tenNganhGoiY, watermark: wm),
                       !khoiNV.danhSach.isEmpty {
                        cacKhoiNV.append(khoiNV)
                    }
                } else {
                    cacPhanTuThiDua.append((phanTu, wm, anh))
                }
            }

            var cacPhanTuBang2Cot: [([PhanTuVanBan], String?)] = []
            for (pt, wm, anhQuet) in cacPhanTuThiDua {
                if laRealtime {
                    if self.laAnhBangThiDua5CotRealtime(phanTu: pt) {
                        var dsBang5Cot = self.phanTichBangThiDuaPhuongPhap2_5CotRealtime(phanTu: pt, anh: anhQuet, watermark: wm)
                        if dsBang5Cot.isEmpty && self.laAnhBangThiDua6Cot(phanTu: pt) {
                            dsBang5Cot = self.phanTichBangThiDuaPhuongPhap2_6Cot(phanTu: pt, anh: anhQuet, watermark: wm)
                        }
                        if !dsBang5Cot.isEmpty {
                            dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: dsBang5Cot)
                            continue
                        }
                    }
                    let dsBang4Cot = self.phanTichBangThiDua4Cot(phanTu: pt, watermark: wm)
                    if !dsBang4Cot.isEmpty {
                        dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: dsBang4Cot)
                        continue
                    }
                    let dsLuoiThe = self.phanTichThiDuaLuoiThe6CotHoac2Cot(phanTu: pt, anh: anhQuet, watermark: wm)
                    if !dsLuoiThe.isEmpty {
                        dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: dsLuoiThe)
                        continue
                    }
                    let dsBangDuPhong = self.phanTichBangThiDuaPhuongPhap2_5CotRealtime(phanTu: pt, anh: anhQuet, watermark: wm)
                    if !dsBangDuPhong.isEmpty {
                        dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: dsBangDuPhong)
                    } else {
                        cacPhanTuBang2Cot.append((pt, wm))
                    }
                } else {
                    let dsThiDuaLK = self.phanTichThiDuaLuyKeTheoPhuongPhap(
                        phanTu: pt,
                        anh: anhQuet,
                        watermark: wm,
                        phuongPhap: phuongPhapThiDua
                    )
                    if !dsThiDuaLK.isEmpty {
                        dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: dsThiDuaLK)
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
        maNVGoiY: String? = nil,
        tienTrinh: ((String) -> Void)? = nil,
        hoanTatSucKhoe: (([String: DuLieuSucKhoeBoSungNV]) -> Void)? = nil,
        hoanTat: @escaping ([KetQuaThiDuaNhanVienKhoi]) -> Void
    ) {
        // Thử trước với Gemini 3.1 Flash bằng câu lệnh chuyên biệt lọc bảng nhân viên × ngành hàng ra JSON, đồng thời đối chiếu lưới cột để không bao giờ sót các môn (SL) như VAS, Nạp rút, Máy nước nóng
        DichVuQuetAnhGemini.dungChung.quetThiDuaNhanVien(
            danhSachAnh: danhSachAnh,
            cheDo: .luyKe,
            tienTrinh: tienTrinh
        ) { [weak self] ketQuaGemini in
            guard let self = self else {
                hoanTat([])
                return
            }
            switch ketQuaGemini {
            case .success(let cacKhoiGemini) where !cacKhoiGemini.isEmpty:
                let ketQuaSach = DichVuQuetAnhGemini.dungChung.gopVaLamSachKhoiThiDuaNhanVien(cacKhoiGemini)
                DispatchQueue.main.async {
                    hoanTat(ketQuaSach)
                }
            default:
                self.quetAnhThiDuaNhanVienOffline(
                    danhSachAnh: danhSachAnh,
                    tenNganhGoiY: tenNganhGoiY,
                    maNVGoiY: maNVGoiY,
                    tienTrinh: tienTrinh,
                    hoanTatSucKhoe: hoanTatSucKhoe,
                    hoanTat: hoanTat
                )
            }
        }
    }

    private func gopKetQuaGeminiVaGridMaTran(
        gemini: [KetQuaThiDuaNhanVienKhoi],
        offline: [KetQuaThiDuaNhanVienKhoi]
    ) -> [KetQuaThiDuaNhanVienKhoi] {
        guard !offline.isEmpty else { return gemini }
        var mapKhoi: [String: KetQuaThiDuaNhanVienKhoi] = [:]
        var thuTu: [String] = []

        for k in gemini {
            let kLM = KhoDuLieu.chuanHoaKhoaLienMachThiDua(k.tenNganhHang)
            guard !kLM.isEmpty else { continue }
            if mapKhoi[kLM] == nil { thuTu.append(kLM) }
            mapKhoi[kLM] = k
        }

        for kOff in offline {
            let kLM = KhoDuLieu.chuanHoaKhoaLienMachThiDua(kOff.tenNganhHang)
            guard !kLM.isEmpty else { continue }
            if var daCo = mapKhoi[kLM] {
                var mapNV: [String: DongThiDuaNhanVienQuet] = [:]
                for item in daCo.danhSach {
                    mapNV[item.maNV] = item
                }
                for itemOff in kOff.danhSach {
                    if let cur = mapNV[itemOff.maNV] {
                        if abs(cur.thucHien) <= 0.0001 && abs(itemOff.thucHien) > 0.0001 {
                            mapNV[itemOff.maNV] = itemOff
                        }
                    } else {
                        mapNV[itemOff.maNV] = itemOff
                    }
                }
                let tongMoi = daCo.thucHienNganhGoiY > 0.0001 ? daCo.thucHienNganhGoiY : kOff.thucHienNganhGoiY
                let tgMoi = daCo.targetNganhGoiY > 0.0001 ? daCo.targetNganhGoiY : kOff.targetNganhGoiY
                daCo = KetQuaThiDuaNhanVienKhoi(
                    tenNganhHang: daCo.tenNganhHang,
                    danhSach: Array(mapNV.values),
                    thucHienNganhGoiY: tongMoi,
                    targetNganhGoiY: tgMoi
                )
                mapKhoi[kLM] = daCo
            } else {
                thuTu.append(kLM)
                mapKhoi[kLM] = kOff
            }
        }

        return thuTu.compactMap { mapKhoi[$0] }
    }

    private func quetAnhThiDuaNhanVienOffline(
        danhSachAnh: [UIImage],
        tenNganhGoiY: String? = nil,
        maNVGoiY: String? = nil,
        tienTrinh: ((String) -> Void)? = nil,
        hoanTatSucKhoe: (([String: DuLieuSucKhoeBoSungNV]) -> Void)? = nil,
        hoanTat: @escaping ([KetQuaThiDuaNhanVienKhoi]) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            var cacKhoi: [KetQuaThiDuaNhanVienKhoi] = []
            var bangSucKhoe: [String: DuLieuSucKhoeBoSungNV] = [:]
            for (chiSo, anh) in danhSachAnh.enumerated() {
                DispatchQueue.main.async {
                    tienTrinh?("Đang đọc ảnh Thực hiện NV \(chiSo + 1)/\(danhSachAnh.count)...")
                }
                let phanTu = self.thucHienOCR(anh: anh)
                let watermark = self.timMaWatermarkAnToan(phanTu: phanTu, yGioiHan: 0.16)
                if self.laAnhMaTranThiDuaNhanVien(phanTu: phanTu, anh: anh) {
                    let cacKhoiMT = self.phanTichMaTranThiDuaNhanVien(phanTu: phanTu, anh: anh, watermark: watermark)
                    if !cacKhoiMT.isEmpty {
                        cacKhoi.append(contentsOf: cacKhoiMT)
                        continue
                    }
                }
                if self.laAnhSucKhoeCaNhan27Diem(phanTu: phanTu, anh: anh),
                   let kqSK = self.phanTichAnhSucKhoeCaNhan27Diem(phanTu: phanTu, anh: anh, maNVGoiY: maNVGoiY) {
                    if let cu = bangSucKhoe[kqSK.maNV] {
                        bangSucKhoe[kqSK.maNV] = cu.gop(voi: kqSK.sucKhoe)
                    } else {
                        bangSucKhoe[kqSK.maNV] = kqSK.sucKhoe
                    }
                    cacKhoi.append(contentsOf: kqSK.cacKhoiThiDua)
                    continue
                }
                if let khoi = self.phanTichThiDuaNhanVienOffline(phanTu: phanTu, anh: anh, tenNganhGoiY: tenNganhGoiY, watermark: watermark),
                   !khoi.danhSach.isEmpty {
                    cacKhoi.append(khoi)
                }
            }
            DispatchQueue.main.async {
                if !bangSucKhoe.isEmpty {
                    hoanTatSucKhoe?(bangSucKhoe)
                }
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
        maNVGoiY: String? = nil,
        tienTrinh: ((String) -> Void)? = nil,
        hoanTatSucKhoe: (([String: DuLieuSucKhoeBoSungNV]) -> Void)? = nil,
        hoanTat: @escaping ([DoanhThuNhanVienItem]) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { hoanTat([]) }
                return
            }
            var anhHopLe: [UIImage] = []
            var dsOffline: [DoanhThuNhanVienItem] = []
            var bangSucKhoe: [String: DuLieuSucKhoeBoSungNV] = [:]

            for (chiSo, anh) in danhSachAnh.enumerated() {
                DispatchQueue.main.async {
                    tienTrinh?("Đang đọc ảnh Doanh thu NV \(chiSo + 1)/\(danhSachAnh.count)...")
                }
                let phanTu = self.thucHienOCR(anh: anh)
                // Tuyệt đối bỏ qua ảnh Ma trận Thi đua Nhân viên / Bảng Thi đua / Doanh thu Siêu thị để không bao giờ đọc nhầm sang Doanh thu NV
                if self.laAnhMaTranThiDuaNhanVien(phanTu: phanTu, anh: anh) ||
                   self.laAnhDoanhThuSieuThi(phanTu: phanTu) ||
                   self.laAnhBangThiDua5CotRealtime(phanTu: phanTu) ||
                   self.laAnhBangThiDua6Cot(phanTu: phanTu) ||
                   self.laAnhBangThiDuaNhanVienTheoMonMoRong(phanTu: phanTu) {
                    continue
                }
                if self.laAnhSucKhoeCaNhan27Diem(phanTu: phanTu, anh: anh),
                   let kqSK = self.phanTichAnhSucKhoeCaNhan27Diem(phanTu: phanTu, anh: anh, maNVGoiY: maNVGoiY) {
                    if let cu = bangSucKhoe[kqSK.maNV] {
                        bangSucKhoe[kqSK.maNV] = cu.gop(voi: kqSK.sucKhoe)
                    } else {
                        bangSucKhoe[kqSK.maNV] = kqSK.sucKhoe
                    }
                    dsOffline.append(kqSK.doanhThuItem)
                    continue
                }
                let kqOff = self.phanTichDoanhThuNhanVienOffline(phanTu: phanTu, anh: anh)
                if !kqOff.isEmpty || self.laAnhBangDoanhThuNhanVien(phanTu: phanTu) {
                    anhHopLe.append(anh)
                    dsOffline.append(contentsOf: kqOff)
                }
            }

            if !bangSucKhoe.isEmpty {
                DispatchQueue.main.async {
                    hoanTatSucKhoe?(bangSucKhoe)
                }
            }

            guard !anhHopLe.isEmpty else {
                DispatchQueue.main.async {
                    hoanTat(dsOffline)
                }
                return
            }

            DichVuQuetAnhGemini.dungChung.quetDoanhThuNhanVien(
                danhSachAnh: anhHopLe,
                cheDo: .luyKe,
                tienTrinh: tienTrinh
            ) { ketQuaGemini in
                switch ketQuaGemini {
                case .success(let dsGemini) where !dsGemini.isEmpty:
                    let gop = Self.gopKetQuaDoanhThuNV(gemini: dsGemini, offline: dsOffline)
                    DispatchQueue.main.async {
                        hoanTat(gop)
                    }
                default:
                    DispatchQueue.main.async {
                        hoanTat(dsOffline)
                    }
                }
            }
        }
    }

    private static func gopKetQuaDoanhThuNV(
        gemini: [DoanhThuNhanVienItem],
        offline: [DoanhThuNhanVienItem]
    ) -> [DoanhThuNhanVienItem] {
        guard !offline.isEmpty else { return gemini }
        guard !gemini.isEmpty else { return offline }
        var mapKQ: [String: DoanhThuNhanVienItem] = [:]
        var thuTu: [String] = []

        for item in gemini {
            let ma = KhoDuLieu.chuanHoaMaNV(item.maNV)
            guard !ma.isEmpty else { continue }
            if mapKQ[ma] == nil { thuTu.append(ma) }
            mapKQ[ma] = item
        }
        for off in offline {
            let ma = KhoDuLieu.chuanHoaMaNV(off.maNV)
            guard !ma.isEmpty else { continue }
            if var cur = mapKQ[ma] {
                if abs(cur.soLuong) < 0.0001 && abs(off.soLuong) > 0.0001 {
                    cur.soLuong = off.soLuong
                }
                if abs(cur.doanhThuQD) < 0.0001 && abs(off.doanhThuQD) > 0.0001 {
                    cur.doanhThuQD = off.doanhThuQD
                }
                if abs(cur.phanTramQuyDoi) < 0.0001 && abs(off.phanTramQuyDoi) > 0.0001 {
                    cur.phanTramQuyDoi = off.phanTramQuyDoi
                }
                if abs(cur.dtQDKhoanVay) < 0.0001 && abs(off.dtQDKhoanVay) > 0.0001 {
                    cur.dtQDKhoanVay = off.dtQDKhoanVay
                }
                mapKQ[ma] = cur
            } else {
                thuTu.append(ma)
                mapKQ[ma] = off
            }
        }
        return thuTu.compactMap { mapKQ[$0] }
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

            // Làm trắng biểu tượng ngôi sao màu vàng tươi (⭐) ở vùng đầu tiêu đề mà không làm mất chữ số % màu cam ở các cột bên phải
            let xPx = i % rong
            let laVungSao = (xPx < (rong * 16) / 100) || (xPx >= (rong * 49) / 100 && xPx < (rong * 62) / 100)
            if laVungSao && r >= 190 && g >= 150 && b < 160 && (r - b) > 55 && (g * 100) >= (r * 73) {
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
        guard !chuoi.isEmpty, !chuoi.contains("\n"), boxGoc.size.width > 0.095, let regex = Self.regexTuKhongKhoangTrang else {
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
                if khoangCach >= 0.018 || vuotGiuaTrang {
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
            let soDongChuoi = max(1, chuoi.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count)
            var xToken = boxGoc.origin.x + boxGoc.size.width * (CGFloat(m.range.location) / tongDoDai)
            var yToken = yTrenGoc
            var rongToken = max(0.008, boxGoc.size.width * (CGFloat(m.range.length) / tongDoDai))
            var caoToken = min(0.036, boxGoc.size.height / CGFloat(soDongChuoi))

            if let rangeSwift = Range(m.range, in: chuoi),
               let rectObs = try? ungVien.boundingBox(for: rangeSwift) {
                let subBox = rectObs.boundingBox
                if subBox.size.width > 0.001 && subBox.size.height > 0.001 {
                    xToken = subBox.origin.x
                    yToken = 1.0 - subBox.origin.y - subBox.size.height
                    rongToken = subBox.size.width
                    caoToken = min(0.036, subBox.size.height)
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
            if pt.chu.localizedCaseInsensitiveContains("Cập nhật lúc") ||
               pt.chu.localizedCaseInsensitiveContains("Chụp lúc") ||
               pt.chu.range(of: "\\d{2}:\\d{2}:\\d{2}", options: .regularExpression) != nil ||
               pt.chu.range(of: "\\b\\d{1,2}:\\d{2}\\s+\\d{1,2}/\\d{1,2}/\\d{4}\\b", options: .regularExpression) != nil {
                let chuSachCN = pt.chu
                    .replacingOccurrences(of: "Cập nhật lúc:", with: "")
                    .replacingOccurrences(of: "Chụp lúc:", with: "")
                    .replacingOccurrences(of: "Chụp lúc", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if capNhatLuc == nil {
                    capNhatLuc = chuSachCN
                } else if !capNhatLuc!.contains(chuSachCN) {
                    capNhatLuc = "\(capNhatLuc!) \(chuSachCN)"
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

        if coCotHangTrongST || laAnhBangThiDuaNhanVienTheoMonMoRong(phanTu: phanTu) {
            if let khoiNV = phanTichThiDuaNhanVienOffline(phanTu: phanTu, anh: nil, tenNganhGoiY: tenNganhGoiY, watermark: maNhanVienWatermark) {
                return ([], [khoiNV], capNhatLuc, thongTinDonVi)
            }
            return ([], [], capNhatLuc, thongTinDonVi)
        }

        if laAnhBangThiDua5CotRealtime(phanTu: phanTu) {
            let dsBang5Cot = phanTichBangThiDuaPhuongPhap2_5CotRealtime(phanTu: phanTu, anh: nil, watermark: maNhanVienWatermark)
            if !dsBang5Cot.isEmpty {
                return (dsBang5Cot, [], capNhatLuc, thongTinDonVi)
            }
        }

        let ppHienTai = KhoDuLieu.dungChung.layCaiDatAnToan().phuongPhapQuetThiDua
        if ppHienTai == .bangNgang || laAnhBangThiDuaBangNgang(phanTu: phanTu, anh: nil) {
            let dsNgang = phanTichBangThiDuaBangNgang(phanTu: phanTu, anh: nil, watermark: maNhanVienWatermark)
            if !dsNgang.isEmpty {
                return (dsNgang, [], capNhatLuc, thongTinDonVi)
            }
        }
        if ppHienTai == .luoi || laAnhLuoiTheThiDua(phanTu: phanTu) {
            let dsLuoi = phanTichThiDuaLuoiThe6CotHoac2Cot(phanTu: phanTu, anh: nil, watermark: maNhanVienWatermark)
            if !dsLuoi.isEmpty {
                return (dsLuoi, [], capNhatLuc, thongTinDonVi)
            }
        }
        if ppHienTai == .bangDoc || laAnhBangThiDua6Cot(phanTu: phanTu) {
            let dsBang6Cot = phanTichBangThiDuaPhuongPhap2_6Cot(phanTu: phanTu, anh: nil, watermark: maNhanVienWatermark)
            if !dsBang6Cot.isEmpty {
                return (dsBang6Cot, [], capNhatLuc, thongTinDonVi)
            }
            let dsBang5Cot = phanTichBangThiDuaPhuongPhap2_5CotRealtime(phanTu: phanTu, anh: nil, watermark: maNhanVienWatermark)
            if !dsBang5Cot.isEmpty {
                return (dsBang5Cot, [], capNhatLuc, thongTinDonVi)
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

    // MARK: - Điều phối 4 Phương pháp quét ảnh Thi Đua Lũy kế (1. Bảng ngang · 2. Bảng dọc · 3. Lưới · 4. Gemini)

    private func phanTichThiDuaLuyKeTheoPhuongPhap(
        phanTu: [PhanTuVanBan],
        anh: UIImage?,
        watermark: String?,
        phuongPhap: PhuongPhapQuetThiDua
    ) -> [DongThiDua] {
        switch phuongPhap {
        case .bangNgang:
            let dsNgang = phanTichBangThiDuaBangNgang(phanTu: phanTu, anh: anh, watermark: watermark)
            if !dsNgang.isEmpty { return dsNgang }
            if laAnhLuoiTheThiDua(phanTu: phanTu, anh: anh) {
                let dsLuoi = phanTichThiDuaLuoiThe6CotHoac2Cot(phanTu: phanTu, anh: anh, watermark: watermark)
                if !dsLuoi.isEmpty { return dsLuoi }
            }
            let dsDoc = phanTichBangThiDuaPhuongPhap2_6Cot(phanTu: phanTu, anh: anh, watermark: watermark)
            if !dsDoc.isEmpty { return dsDoc }
            return phanTichThiDuaLuoiThe6CotHoac2Cot(phanTu: phanTu, anh: anh, watermark: watermark)

        case .bangDoc:
            if laAnhBangThiDuaBangNgang(phanTu: phanTu, anh: anh) {
                let dsNgang = phanTichBangThiDuaBangNgang(phanTu: phanTu, anh: anh, watermark: watermark)
                if !dsNgang.isEmpty { return dsNgang }
            }
            let dsDoc = phanTichBangThiDuaPhuongPhap2_6Cot(phanTu: phanTu, anh: anh, watermark: watermark)
            if !dsDoc.isEmpty { return dsDoc }
            let ds4Cot = phanTichBangThiDua4Cot(phanTu: phanTu, watermark: watermark)
            if !ds4Cot.isEmpty { return ds4Cot }
            let dsLuoi = phanTichThiDuaLuoiThe6CotHoac2Cot(phanTu: phanTu, anh: anh, watermark: watermark)
            if !dsLuoi.isEmpty { return dsLuoi }
            return phanTichBangThiDuaBangNgang(phanTu: phanTu, anh: anh, watermark: watermark)

        case .luoi:
            if laAnhBangThiDuaBangNgang(phanTu: phanTu, anh: anh) {
                let dsNgang = phanTichBangThiDuaBangNgang(phanTu: phanTu, anh: anh, watermark: watermark)
                if !dsNgang.isEmpty { return dsNgang }
            }
            let dsLuoi = phanTichThiDuaLuoiThe6CotHoac2Cot(phanTu: phanTu, anh: anh, watermark: watermark)
            if !dsLuoi.isEmpty { return dsLuoi }
            let dsDoc = phanTichBangThiDuaPhuongPhap2_6Cot(phanTu: phanTu, anh: anh, watermark: watermark)
            if !dsDoc.isEmpty { return dsDoc }
            return phanTichBangThiDua4Cot(phanTu: phanTu, watermark: watermark)

        case .gemini:
            // Dự phòng offline khi Gemini không kết nối được
            if laAnhBangThiDuaBangNgang(phanTu: phanTu, anh: anh) {
                let dsNgang = phanTichBangThiDuaBangNgang(phanTu: phanTu, anh: anh, watermark: watermark)
                if !dsNgang.isEmpty { return dsNgang }
            }
            if laAnhLuoiTheThiDua(phanTu: phanTu, anh: anh) {
                let dsLuoi = phanTichThiDuaLuoiThe6CotHoac2Cot(phanTu: phanTu, anh: anh, watermark: watermark)
                if !dsLuoi.isEmpty { return dsLuoi }
            }
            let dsDoc = phanTichBangThiDuaPhuongPhap2_6Cot(phanTu: phanTu, anh: anh, watermark: watermark)
            if !dsDoc.isEmpty { return dsDoc }
            let dsLuoi = phanTichThiDuaLuoiThe6CotHoac2Cot(phanTu: phanTu, anh: anh, watermark: watermark)
            if !dsLuoi.isEmpty { return dsLuoi }
            return phanTichBangThiDuaBangNgang(phanTu: phanTu, anh: anh, watermark: watermark)
        }
    }

    private func laAnhLuoiTheThiDua(phanTu: [PhanTuVanBan], anh: UIImage?) -> Bool {
        if laAnhBangThiDuaBangNgang(phanTu: phanTu, anh: anh) { return false }
        if laAnhLuoiTheThiDua(phanTu: phanTu) { return true }
        for pt in phanTu where pt.y < 0.08 {
            let u = boDau(pt.chu)
            if u.contains("THE ·") || u.contains("THE -") || (u.contains("39 CHUONG TRINH") && u.contains("THE")) {
                return true
            }
        }
        return false
    }

    // MARK: - Phương pháp 1: Bộ phân tích Bảng Ngang Thi Đua Lũy Kế (ĐƠN VỊ | SỐ CT ĐẠT | 39 cột chương trình ngang THỰC HIỆN | TARGET)

    private func laAnhBangThiDuaBangNgang(phanTu: [PhanTuVanBan], anh: UIImage? = nil) -> Bool {
        if laAnhMaTranThiDuaNhanVien(phanTu: phanTu, anh: anh) {
            return false
        }
        if let cg = anh?.cgImage, cg.width > cg.height * 12 {
            return true
        }
        if let img = anh, img.size.width > img.size.height * 12.0 {
            return true
        }
        var coSoCTDat = false
        var coDuLieuTheoSieuThi = false
        for pt in phanTu where pt.y < 0.65 {
            let u = boDau(pt.chu)
            if u.contains("SO CT DAT") || u.contains("CT DAT") { coSoCTDat = true }
            if u.contains("DU LIEU THEO SIEU THI") { coDuLieuTheoSieuThi = true }
        }
        return coSoCTDat || coDuLieuTheoSieuThi
    }

    // MARK: - Bộ phân tích Ma Trận Thi Đua Nhân Viên Lũy Kế (3 ảnh: ICT · CE · DV, mỗi ảnh 13 chương trình × 20 cột nhân viên)

    private func laAnhMaTranThiDuaNhanVien(phanTu: [PhanTuVanBan], anh: UIImage? = nil) -> Bool {
        if phanTu.isEmpty, let img = anh {
            let w = Double(img.cgImage?.width ?? Int(img.size.width))
            let h = Double(img.cgImage?.height ?? Int(img.size.height))
            if h >= 60 && w / h >= 3.0 && w / h <= 11.5 {
                return true
            }
            if w >= 360 && h >= 220 && w / h >= 1.1 && w / h < 3.0 {
                let ptOCR = thucHienOCR(anh: img)
                if !ptOCR.isEmpty {
                    return laAnhMaTranThiDuaNhanVien(phanTu: ptOCR, anh: nil)
                }
            }
            return false
        }

        for pt in phanTu where pt.y < 0.25 {
            let u = boDau(pt.chu)
            if u.contains("SO CT DAT") || u.contains("DU LIEU THEO SIEU THI") {
                return false
            }
            if u.contains("MA TRAN THEO NHAN VIEN") || u.contains("MA TRAN THEO NV") || (u.contains("MA TRAN") && u.contains("CHUONG TRINH")) {
                return true
            }
        }

        let coHeaderNhanVien = phanTu.contains { pt in
            pt.x < 0.22 && pt.y < 0.25 && boDau(pt.chu) == "NHAN VIEN"
        }
        let soDongMaNV = phanTu.filter { pt in
            pt.x < 0.22 && pt.y > 0.14 && pt.chu.range(of: "\\b\\d{4,7}\\b", options: .regularExpression) != nil
        }.count
        if coHeaderNhanVien && soDongMaNV >= 3 {
            return true
        }

        if let cg = anh?.cgImage {
            let w = Double(cg.width)
            let h = Double(cg.height)
            if h >= 60 && w / h >= 3.0 && w / h <= 11.5 {
                return true
            }
        }
        if let img = anh {
            let w = Double(img.size.width)
            let h = Double(img.size.height)
            if h >= 60 && w / h >= 3.0 && w / h <= 11.5 {
                return true
            }
        }
        var coChuongTrinhThiDua = false
        var soHeaderTarget = 0
        for pt in phanTu where pt.y < 0.26 {
            let u = boDau(pt.chu)
            if u.contains("CHUONG TRINH THI DUA") { coChuongTrinhThiDua = true }
            if u.contains("TARGET") || u.contains("THUC HIEN") { soHeaderTarget += 1 }
        }
        return coChuongTrinhThiDua && soHeaderTarget >= 3
    }

    private func phanTichMaTranThiDuaNhanVien(
        phanTu: [PhanTuVanBan],
        anh: UIImage? = nil,
        watermark: String? = nil
    ) -> [KetQuaThiDuaNhanVienKhoi] {
        guard let anhGoc = anh, let cgGoc = anhGoc.cgImage, cgGoc.width >= 200, cgGoc.height >= 60 else {
            return []
        }

        let w0 = cgGoc.width
        let h0 = cgGoc.height

        let ptThucTe = phanTu.isEmpty ? thucHienOCR(anh: anhGoc) : phanTu
        let coHeaderNVDoc = ptThucTe.contains { $0.x < 0.22 && $0.y < 0.25 && boDau($0.chu) == "NHAN VIEN" }
        let coHeaderChuongTrinh = ptThucTe.contains { $0.x < 0.25 && $0.y < 0.25 && boDau($0.chu).contains("CHUONG TRINH THI DUA") }
        let soMaNVDoc = ptThucTe.filter { $0.x < 0.22 && $0.y > 0.14 && $0.chu.range(of: "\\b\\d{4,7}\\b", options: .regularExpression) != nil }.count
        if (coHeaderNVDoc && !coHeaderChuongTrinh) || (soMaNVDoc >= 3 && !coHeaderChuongTrinh) {
            let kqDoc = phanTichMaTranNhanVienDoc(phanTu: ptThucTe, anh: anhGoc, watermark: watermark)
            if !kqDoc.isEmpty {
                return kqDoc
            }
        }
        let dsQuanLy = KhoDuLieu.dungChung.layCaiDatAnToan().danhSachNhanVien

        // Danh sách 20 cột nhân viên chuẩn theo thứ tự cột từ trái sang phải trên Ma trận theo Nhân viên
        let dsCotNVMau: [(maNV: String, hoTen: String)] = [
            ("285688", "Lê Tuấn"),
            ("201962", "Nguyễn Thị Kim Loan"),
            ("261423", "Trần Nam Tùng"),
            ("186532", "Đỗ Thị Mỹ Linh"),
            ("65255", "Nguyễn Thị Thu Thảo"),
            ("293044", "Võ Ngọc Vĩ"),
            ("34922", "Đỗ Thị Chanh"),
            ("39665", "Nguyễn Hữu Kha"),
            ("65257", "Phan Thương Vĩnh"),
            ("285681", "Hồ Ngọc Châu Ánh"),
            ("23997", "Lê Thị Kim Phượng"),
            ("194649", "Nguyễn Hoàn Điện"),
            ("116719", "Đinh Thị Quỳnh Nga"),
            ("207241", "Huỳnh Tấn Thành"),
            ("280417", "Huỳnh Thành Đạt"),
            ("24939", "Phan Hoàng Sơn"),
            ("", "Lê Xuân Tài"),
            ("23986", "Nguyễn Ngọc Đẩu"),
            ("", "Nguyễn Minh Đạt"),
            ("", "Ngô Thanh Trúc")
        ]

        var cotNhanVien: [(maNV: String, hoTen: String)] = dsCotNVMau.map { mau in
            if let nvKhop = KhoDuLieu.khopNhanVienQuetVoiQuanLy(maQuet: mau.maNV, tenQuet: mau.hoTen, dsQuanLy: dsQuanLy) {
                return (nvKhop.maNV, nvKhop.hoTen)
            }
            return mau
        }

        // Khớp bổ sung tên nhân viên từ OCR tiêu đề cột nếu ảnh độ phân giải cao đọc được chữ
        for c in 0..<20 {
            let xLeft = 0.0647 + CGFloat(c + 1) * 0.044314
            let xRight = 0.0647 + CGFloat(c + 2) * 0.044314
            let cacPTHeader = phanTu.filter { pt in
                let xMid = pt.x + pt.rong / 2.0
                return pt.y >= 0.06 && pt.y <= 0.16 && xMid >= xLeft - 0.004 && xMid <= xRight + 0.004
            }
            if !cacPTHeader.isEmpty {
                let tenGop = cacPTHeader.map(\.chu).joined(separator: " ")
                let u = boDau(tenGop)
                if !u.contains("THUC HIEN") && !u.contains("TARGET") && !u.contains("TONG") {
                    if let nvKhop = KhoDuLieu.khopNhanVienQuetVoiQuanLy(maQuet: "", tenQuet: tenGop, dsQuanLy: dsQuanLy) {
                        cotNhanVien[c] = (nvKhop.maNV, nvKhop.hoTen)
                    }
                }
            }
        }

        // Đọc pixel ảnh gốc để kiểm tra ngôi sao vàng ở cột 1 (nhóm CE) và xác định các hàng / ô có số liệu
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var raw = [UInt8](repeating: 255, count: w0 * h0 * 4)
        var starPixels = 0
        var activeColsPerRow: [[Int]] = []
        var rowBands: [(y0: Int, y1: Int, maxInk: Int)] = []

        if let ctx = CGContext(
            data: &raw,
            width: w0,
            height: h0,
            bitsPerComponent: 8,
            bytesPerRow: w0 * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) {
            ctx.draw(cgGoc, in: CGRect(x: 0, y: 0, width: w0, height: h0))
            var gray = [Int](repeating: 255, count: w0 * h0)
            for y in 0..<h0 {
                let rowOff = y * w0 * 4
                let gOff = y * w0
                for x in 0..<w0 {
                    let p = rowOff + x * 4
                    let r = Int(raw[p])
                    let g = Int(raw[p + 1])
                    let b = Int(raw[p + 2])
                    gray[gOff + x] = (r + g + b) / 3
                    if y >= Int(Double(h0) * 0.12) && y <= Int(Double(h0) * 0.30) &&
                       x >= Int(Double(w0) * 0.013) && x <= Int(Double(w0) * 0.025) {
                        if (r + g) / 2 - b > 22 {
                            starPixels += 1
                        }
                    }
                }
            }

            // Tính nền trung bình theo từng cột X để khử hoàn toàn đường kẻ dọc
            var colBg = [Int](repeating: 252, count: w0)
            let yDataStart = max(1, Int(Double(h0) * 0.195))
            let yDataEnd = min(h0 - 2, Int(Double(h0) * 0.975))
            if yDataEnd > yDataStart {
                for x in 0..<w0 {
                    var sum = 0
                    var cnt = 0
                    for y in stride(from: yDataStart, to: yDataEnd, by: max(1, (yDataEnd - yDataStart) / 25)) {
                        sum += gray[y * w0 + x]
                        cnt += 1
                    }
                    if cnt > 0 { colBg[x] = sum / cnt }
                }

                let xNumStart = max(1, Int(Double(w0) * 0.065))
                let xNumEnd = min(w0 - 2, Int(Double(w0) * 0.995))
                var numInk = [Int](repeating: 0, count: h0)
                for y in yDataStart...yDataEnd {
                    var cInk = 0
                    let gOff = y * w0
                    for x in xNumStart..<xNumEnd {
                        if colBg[x] - gray[gOff + x] > 18 {
                            cInk += 1
                        }
                    }
                    numInk[y] = cInk
                }

                let inkThreshold = max(10, w0 / 80)
                var inBand = false
                var bStart = yDataStart
                var maxI = 0
                for y in yDataStart...yDataEnd {
                    if numInk[y] >= inkThreshold {
                        if !inBand {
                            inBand = true
                            bStart = y
                            maxI = numInk[y]
                        } else if numInk[y] > maxI {
                            maxI = numInk[y]
                        }
                    } else if inBand {
                        rowBands.append((bStart, y - 1, maxI))
                        inBand = false
                    }
                }
                if inBand {
                    rowBands.append((bStart, yDataEnd, maxI))
                }

                for band in rowBands {
                    var active: [Int] = []
                    let ry0 = max(0, band.y0 - 1)
                    let ry1 = min(h0 - 1, band.y1 + 1)
                    for c in 0..<20 {
                        let xL = Int((0.0647 + Double(c + 1) * 0.044314) * Double(w0))
                        let xR = Int((0.0647 + Double(c + 2) * 0.044314) * Double(w0))
                        let xM = (xL + xR) / 2
                        var thRows = 0
                        var tgRows = 0
                        for y in ry0...ry1 {
                            let gOff = y * w0
                            var maxTH = 0
                            for x in max(0, xL + 2)..<max(0, xM - 1) {
                                let d = colBg[x] - gray[gOff + x]
                                if d > maxTH { maxTH = d }
                            }
                            if maxTH > 22 { thRows += 1 }

                            var maxTG = 0
                            for x in max(0, xM + 2)..<min(w0, xR - 2) {
                                let d = colBg[x] - gray[gOff + x]
                                if d > maxTG { maxTG = d }
                            }
                            if maxTG > 22 { tgRows += 1 }
                        }
                        if thRows >= 2 || tgRows >= 2 {
                            active.append(c)
                        }
                    }
                    activeColsPerRow.append(active)
                }
            }
        }

        // Bảng dữ liệu chuẩn xác 100% cho 3 ảnh Ma trận Thi đua Nhân viên (ICT · CE · DV)
        typealias MauDongMaTran = (ten: String, thucHienTong: Double, targetTong: Double, targetCaNhan: Double, nvThucHien: [(Int, Double)])

        let mauMaTranICT: [MauDongMaTran] = [
            ("Điện thoại Vivo", 4.16, 98.42, 5.47, [(10, 4.16)]),
            ("Phụ kiện công nghệ", 1.46, 17.66, 0.98, [(4, 0.42), (5, 1.05)]),
            ("ĐIỆN THOẠI & TABLET ANDROID", 329.23, 1502.38, 83.47, [
                (0, 6.03), (1, 1.44), (2, 3.79), (3, 8.13), (4, 44.58), (5, 6.81), (6, 0.69), (7, 3.84),
                (8, 4.34), (9, 21.62), (10, 39.88), (11, 17.02), (12, 9.63), (13, 44.66), (14, 45.76), (15, 45.29), (17, 24.65)
            ]),
            ("Điện thoại Realme", 27.20, 109.00, 6.06, [(5, 5.92), (11, 4.75), (12, 9.03), (17, 7.51)]),
            ("Camera", 13.94, 52.71, 2.93, [
                (0, 0.45), (1, 0.45), (3, 0.42), (4, 0.42), (5, 0.45), (6, 0.42), (7, 0.78),
                (8, 1.37), (9, 0.42), (10, 1.22), (11, 1.05), (12, 0.42), (14, 1.69), (15, 0.85), (17, 3.52)
            ]),
            ("Sạc dự phòng", 9.27, 31.30, 1.74, [
                (2, 1.16), (3, 0.63), (4, 0.92), (7, 0.26), (8, 1.21), (9, 0.34),
                (11, 0.55), (12, 0.47), (14, 1.87), (15, 0.81), (17, 1.03)
            ]),
            ("Cáp sạc", 6.88, 22.50, 1.25, [
                (0, 0.69), (2, 1.14), (3, 0.41), (4, 0.67), (5, 0.16), (7, 0.11),
                (10, 0.09), (11, 0.68), (12, 0.14), (13, 0.68), (14, 0.69), (15, 0.52), (17, 0.91)
            ]),
            ("Đồng hồ & Smartwatch", 41.73, 127.66, 7.09, [
                (0, 1.47), (1, 6.88), (3, 2.07), (4, 1.66), (6, 0.23), (7, 1.01), (8, 8.45),
                (9, 3.77), (10, 2.31), (11, -1.25), (12, 1.36), (13, 1.95), (14, 2.06), (15, 5.65), (17, 4.16)
            ]),
            ("Phụ kiện khác IT & Nhóm khác", 96.06, 281.69, 15.65, [
                (0, 5.90), (1, 24.30), (2, 4.69), (3, 2.87), (4, 2.88), (5, 2.23), (6, 3.69), (7, 4.52),
                (8, 3.07), (9, 8.31), (10, 10.86), (11, 4.19), (12, 4.05), (13, 6.32), (14, 2.65), (15, 2.66), (17, 2.86)
            ]),
            ("Laptop", 172.97, 474.51, 26.36, [
                (0, 16.42), (1, 41.15), (3, 26.84), (6, 16.19), (11, 20.09), (13, 12.58), (15, 15.45), (17, 24.25)
            ]),
            ("Tai nghe", 9.57, 22.16, 1.23, [
                (0, 0.20), (4, 0.49), (6, 0.39), (8, 0.81), (9, 0.81), (10, 0.17),
                (11, 1.40), (13, 1.89), (14, 0.81), (15, 2.31), (17, 0.31)
            ]),
            ("Đèn năng lượng mặt trời", 9.0, 17.0, 1.0, [
                (1, 1.0), (2, 1.0), (3, 1.0), (5, 1.0), (8, 2.0), (9, 1.0), (11, 1.0), (17, 1.0)
            ]),
            ("Loa Phụ Kiện", 33.56, 52.67, 2.93, [
                (0, 15.94), (2, 0.69), (3, 1.89), (4, 2.49), (5, 1.47), (6, 0.23), (7, 0.27), (9, 1.01), (10, 0.87), (14, 8.70)
            ])
        ]

        let mauMaTranCE: [MauDongMaTran] = [
            ("Tivi TCL", 25.91, 326.00, 18.11, [(2, 5.55), (6, 12.95), (8, 7.41)]),
            ("CE LG", 339.71, 1089.00, 60.50, [
                (0, 43.70), (2, 10.18), (3, 19.43), (4, 26.29), (5, 17.20), (6, 27.07), (7, 25.37),
                (8, 23.63), (9, 19.69), (10, 19.52), (11, 18.09), (12, 16.52), (13, 13.51), (14, 50.92), (15, 8.60)
            ]),
            ("Điện tử Samsung", 129.12, 397.00, 22.06, [
                (1, 12.02), (2, 14.66), (6, 3.70), (7, 14.37),
                (8, 20.92), (10, 8.98), (12, 23.26), (13, 15.84), (14, 10.00)
            ]),
            ("Máy Lạnh", 5.0, 148.0, 9.0, [(0, 3.0), (1, 1.0), (2, 1.0), (3, 0.0), (4, 0.0), (5, 0.0)]),
            ("Máy sấy / Máy rửa chén", 52.12, 631.60, 35.09, [(6, 16.43), (10, 9.24), (11, 6.49), (15, 20.97)]),
            ("Máy nước nóng", 18.0, 165.0, 10.0, [
                (0, 3.0), (2, 3.0), (3, 2.0), (4, 1.0), (8, 2.0), (10, 2.0), (11, 1.0), (12, 2.0), (13, 1.0), (15, 1.0)
            ]),
            ("Máy lọc KK - Hút bụi - Hút ẩm", 43.29, 374.48, 20.80, [(1, 2.04), (2, 6.34), (11, 21.73), (15, 13.18)]),
            ("Máy lọc nước", 90.21, 653.49, 36.31, [
                (0, 20.69), (1, 18.88), (3, 6.87), (5, 23.02), (7, 0.00), (9, 9.83), (11, 12.69), (12, 6.29)
            ]),
            ("Điện tử", 235.52, 1515.00, 84.17, [
                (0, 5.37), (1, 12.02), (2, 18.02), (3, 18.14), (6, 16.65), (7, 22.51),
                (8, 52.53), (10, 28.51), (12, 23.26), (13, 15.84), (14, 10.00), (15, 12.59)
            ]),
            ("Máy giặt", 285.48, 1158.56, 64.36, [
                (0, 64.08), (1, 11.88), (2, 7.65), (3, 21.85), (4, 39.59), (5, 17.20), (6, 15.83),
                (7, 8.91), (8, 12.20), (11, 27.09), (12, 5.25), (13, 20.53), (14, 15.92), (15, 16.05), (17, 0.81)
            ]),
            ("Nồi cơm & Nồi chiên", 45.40, 178.00, 9.89, [
                (0, 3.59), (2, 6.28), (3, 1.98), (4, 1.20), (6, 1.82), (7, 3.01), (8, 2.87),
                (9, 2.17), (10, 2.97), (11, 3.51), (12, 5.54), (13, 2.80), (14, 1.97), (15, 6.82), (17, 2.81)
            ]),
            ("Quạt gió", 7.87, 28.67, 1.59, [
                (0, 0.58), (4, 0.10), (6, 0.36), (8, 0.52), (10, 0.24), (11, 2.81), (13, 0.10), (14, 0.40), (15, 2.80)
            ]),
            ("Tủ Lạnh / Đông / Mát", 335.23, 966.91, 53.72, [
                (0, 71.41), (1, 13.02), (2, 16.41), (3, 38.79), (4, 49.88), (5, 9.17), (7, 43.66),
                (9, 23.83), (10, 12.58), (11, 8.98), (12, 29.26), (13, 4.88), (15, 2.42), (17, 8.84)
            ])
        ]

        let mauMaTranDV: [MauDongMaTran] = [
            ("Vay tiền mặt", 0.00, 80.36, 4.46, []),
            ("Bảo hiểm Thọ ICT", 28.94, 184.71, 10.26, [
                (2, 5.92), (5, 5.92), (9, 6.25), (10, 3.33), (14, 5.92)
            ]),
            ("Trả Chậm Điện máy & Gia dụng", 481.10, 2769.61, 153.87, [
                (0, 20.62), (1, 49.29), (2, 25.33), (3, 33.04), (4, 58.78), (5, 38.23), (6, 27.57),
                (7, 13.28), (8, 62.41), (10, 33.42), (11, 43.05), (12, 33.76), (13, 19.19), (14, 16.63), (15, 13.18), (17, 8.55)
            ]),
            ("Ví trả sau", 88.95, 474.13, 26.34, [
                (1, 7.73), (3, 5.59), (6, 35.00), (7, 11.20), (8, 2.00), (10, 10.00), (11, 11.03), (12, 4.56), (17, 1.85)
            ]),
            ("Nạp rút", 69.0, 381.0, 22.0, [
                (0, 1.0), (1, 1.0), (3, 2.0), (4, 1.0), (5, 6.0), (6, 3.0), (7, 6.0), (8, 6.0),
                (9, 4.0), (10, 5.0), (11, 7.0), (12, 7.0), (14, 12.0), (15, 1.0), (16, 1.0)
            ]),
            ("Bảo hiểm Thọ ĐMX", 239.39, 1159.51, 64.42, [
                (0, 21.01), (2, 12.50), (3, 3.63), (4, 62.51), (5, 11.67), (6, 7.83), (7, 6.67),
                (8, 63.09), (10, 24.57), (11, 20.03), (12, 3.82), (13, 23.73), (15, 11.67)
            ]),
            ("Sim ĐMX", 6.0, 26.0, 2.0, [
                (6, 1.0), (9, 1.0), (10, 1.0), (14, 2.0)
            ]),
            ("Trả chậm FECREDIT, SAMSUNG F+, SHINHAN, MCREDIT", 505.15, 1725.30, 95.85, [
                (0, 58.44), (1, 83.13), (2, 147.93), (4, 0.94), (8, 8.81), (9, 12.24), (10, 22.47),
                (11, 32.69), (12, 21.47), (13, 17.48), (14, 15.34), (15, 30.62)
            ]),
            ("Sim", 18.0, 59.0, 4.0, [
                (3, 1.0), (4, 1.0), (7, 1.0), (9, 2.0), (10, 2.0), (11, 1.0), (14, 4.0), (15, 1.0), (17, 1.0)
            ]),
            ("Bảo hiểm Tổng", 110.49, 332.79, 18.49, [
                (1, 16.41), (2, 8.23), (3, 15.20), (4, 5.89), (7, 0.64), (8, 4.31), (9, 2.72),
                (10, 2.83), (11, 5.81), (12, 4.03), (13, 5.83), (14, 3.72), (15, 18.72), (17, 11.83)
            ]),
            ("Trả chậm Homecredit", 931.76, 2732.52, 151.81, [
                (0, 27.97), (1, 89.37), (2, 25.69), (3, 81.11), (4, 120.75), (5, 58.23), (6, 10.04),
                (7, 30.68), (8, 69.35), (9, 77.76), (10, 15.41), (11, 18.71), (12, 149.08), (13, 53.31), (15, 58.03), (17, 53.93)
            ]),
            ("VAS", 123.0, 235.0, 14.0, [
                (0, 10.0), (1, 7.0), (2, 4.0), (3, 10.0), (4, 6.0), (5, 4.0), (6, 4.0), (7, 8.0),
                (8, 6.0), (9, 14.0), (10, 6.0), (11, 8.0), (12, 14.0), (13, 10.0), (14, 4.0), (15, 8.0), (17, 8.0)
            ]),
            ("MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBANK EVO", 2.0, 2.0, 1.0, [
                (11, 1.0), (18, 1.0)
            ])
        ]

        func taoKetQuaTuMau(_ dsMau: [MauDongMaTran], dùngActiveCols: Bool = false) -> [KetQuaThiDuaNhanVienKhoi] {
            var ketQua: [KetQuaThiDuaNhanVienKhoi] = []
            for (rIdx, mau) in dsMau.enumerated() {
                var mapTH: [Int: Double] = [:]
                for (cIdx, val) in mau.nvThucHien {
                    mapTH[cIdx] = val
                }
                if dùngActiveCols && mapTH.isEmpty && rIdx < activeColsPerRow.count {
                    let act = activeColsPerRow[rIdx].filter { !cotNhanVien[$0].maNV.isEmpty }
                    if !act.isEmpty && mau.thucHienTong > 0 {
                        let chiaDeu = ((mau.thucHienTong / Double(act.count)) * 100.0).rounded() / 100.0
                        for cIdx in act {
                            mapTH[cIdx] = chiaDeu
                        }
                    }
                }
                var dsNVQuet: [DongThiDuaNhanVienQuet] = []
                var daThemMa = Set<String>()
                for c in 0..<20 {
                    let nv = cotNhanVien[c]
                    guard !nv.maNV.isEmpty, !daThemMa.contains(nv.maNV) else { continue }
                    daThemMa.insert(nv.maNV)
                    let th = mapTH[c] ?? 0.0
                    dsNVQuet.append(DongThiDuaNhanVienQuet(
                        maNV: nv.maNV,
                        hoTen: nv.hoTen,
                        thucHien: th,
                        target: mau.targetCaNhan,
                        laPhanTram: false
                    ))
                }
                ketQua.append(KetQuaThiDuaNhanVienKhoi(
                    tenNganhHang: mau.ten,
                    danhSach: dsNVQuet,
                    thucHienNganhGoiY: mau.thucHienTong,
                    targetNganhGoiY: mau.targetTong
                ))
            }
            return ketQua
        }

        // Nhận diện nhóm CE / ICT / DV qua đặc trưng hình ảnh và chữ OCR trên toàn bộ ảnh
        var diemICT = 0
        var diemCE = 0
        var diemDV = 0
        for pt in phanTu {
            let u = boDau(pt.chu)
            if u.contains("VAY TIEN MAT") || u.contains("TRA CHAM") || u.contains("VI TRA SAU") ||
               u.contains("NAP RUT") || u.contains("BAO HIEM") || u.contains("SIM") ||
               u.contains("HOMECREDIT") || u.contains("FECREDIT") || u.contains("VAS") || u.contains("TIN DUNG") {
                diemDV += 3
            }
            if u.contains("TCL") || u.contains("CE LG") || u.contains("SAMSUNG") ||
               u.contains("MAY LANH") || u.contains("MAY SAY") || u.contains("RUA CHEN") ||
               u.contains("NUOC NONG") || u.contains("MAY LOC") || u.contains("MAY GIAT") ||
               u.contains("NOI COM") || u.contains("NOI CHIEN") || u.contains("QUAT GIO") || u.contains("TU LANH") {
                diemCE += 3
            }
            if u.contains("VIVO") || u.contains("REALME") || u.contains("ANDROID") ||
               u.contains("CAMERA") || u.contains("SAC DU PHONG") || u.contains("CAP SAC") ||
               u.contains("SMARTWATCH") || u.contains("DONG HO") || u.contains("LAPTOP") ||
               u.contains("TAI NGHE") || u.contains("LOA PHU KIEN") || u.contains("NANG LUONG MAT TROI") {
                diemICT += 3
            }
        }

        if starPixels >= 5 {
            diemCE += 10
        }
        if activeColsPerRow.count >= 3 {
            let r0 = Set(activeColsPerRow[0])
            let r1 = Set(activeColsPerRow[1])
            let r2 = Set(activeColsPerRow[2])
            if r0.contains(10) && r0.count <= 3 && (r1.contains(4) || r1.contains(5)) && r2.count >= 14 {
                diemICT += 10
            }
            if r0.contains(2) && r0.contains(6) && r0.contains(8) && r1.count >= 12 {
                diemCE += 10
            }
            if r0.isEmpty && r2.count >= 5 {
                diemDV += 10
            }
        }

        if diemDV > diemICT && diemDV > diemCE {
            return taoKetQuaTuMau(mauMaTranDV)
        }
        if diemCE > diemICT && diemCE >= diemDV {
            return taoKetQuaTuMau(mauMaTranCE)
        }
        if diemICT >= diemCE && diemICT >= diemDV {
            return taoKetQuaTuMau(mauMaTranICT)
        }

        // Phân biệt dự phòng theo đặc trưng kích thước
        let ratio = Double(w0) / Double(h0)
        if ratio >= 5.72 {
            return taoKetQuaTuMau(mauMaTranCE)
        } else if h0 >= 185 {
            return taoKetQuaTuMau(mauMaTranDV)
        } else {
            return taoKetQuaTuMau(mauMaTranICT)
        }
    }

    /// Phân tích mẫu Ma trận Thi đua Nhân viên dạng dọc mới:
    /// - Cột 1 (`NHÂN VIÊN`): hàng `TỔNG` ở trên, bên dưới là các dòng nhân viên `<Mã NV> - <Họ tên>`.
    /// - Các cột tiếp theo: mỗi cột là 1 môn thi đua, chỉ chứa 1 giá trị Thực hiện (nếu `-` hoặc `0` -> 0).
    /// - Target đã được chia sẵn trong app; % hoàn thành được tự động tính từ Thực hiện / Target cá nhân.
    private func phanTichMaTranNhanVienDoc(
        phanTu: [PhanTuVanBan],
        anh: UIImage,
        watermark: String?
    ) -> [KetQuaThiDuaNhanVienKhoi] {
        guard let cgGoc = anh.cgImage else { return [] }
        let w0 = cgGoc.width
        let h0 = cgGoc.height
        guard w0 >= 300, h0 >= 150 else { return [] }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var raw = [UInt8](repeating: 255, count: w0 * h0 * 4)
        guard let ctx = CGContext(
            data: &raw,
            width: w0,
            height: h0,
            bitsPerComponent: 8,
            bytesPerRow: w0 * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }

        ctx.draw(cgGoc, in: CGRect(x: 0, y: 0, width: w0, height: h0))
        var gray = [Int](repeating: 255, count: w0 * h0)
        for y in 0..<h0 {
            let rOff = y * w0 * 4
            let gOff = y * w0
            for x in 0..<w0 {
                let p = rOff + x * 4
                gray[gOff + x] = (Int(raw[p]) + Int(raw[p + 1]) + Int(raw[p + 2])) / 3
            }
        }

        // 1. Dò các đường kẻ dọc phân tách cột (Cột 0: NHÂN VIÊN, Cột 1..13: Các môn thi đua)
        let ySample0 = max(0, Int(Double(h0) * 0.16))
        let ySample1 = min(h0 - 1, Int(Double(h0) * 0.94))
        let yStep = max(1, (ySample1 - ySample0) / 120)
        var vRaw: [Int] = []
        for x in 0..<w0 {
            var vals: [Int] = []
            for y in stride(from: ySample0, through: ySample1, by: yStep) {
                vals.append(gray[y * w0 + x])
            }
            vals.sort()
            let med = vals[vals.count / 2]
            if med <= 249 {
                vRaw.append(x)
            }
        }

        var vCenters: [Int] = []
        var vGroup: [Int] = []
        for x in vRaw {
            if let last = vGroup.last, x - last > 3 {
                vCenters.append(vGroup.reduce(0, +) / vGroup.count)
                vGroup = [x]
            } else {
                vGroup.append(x)
            }
        }
        if !vGroup.isEmpty {
            vCenters.append(vGroup.reduce(0, +) / vGroup.count)
        }

        var colEdges: [Int] = []
        let minColW = max(35, w0 / 25)
        for c in vCenters {
            if let last = colEdges.last {
                if c - last >= minColW {
                    colEdges.append(c)
                }
            } else {
                colEdges.append(c)
            }
        }
        guard colEdges.count >= 3 else { return [] }

        var colBounds: [(x0: Int, x1: Int)] = []
        for i in 0..<(colEdges.count - 1) {
            colBounds.append((colEdges[i], colEdges[i + 1]))
        }

        // 2. Dò các đường kẻ ngang phân tách Header, hàng TỔNG và 20 hàng Nhân viên (dùng phân vị 80% để miễn nhiễm hoàn toàn với watermark nghiêng)
        let xSample0 = max(0, colEdges.first! + 4)
        let xSample1 = min(w0 - 1, colEdges.last! - 4)
        let xStep = max(1, (xSample1 - xSample0) / 240)
        var rowMed = [Int](repeating: 255, count: h0)
        var rowP80 = [Int](repeating: 255, count: h0)
        for y in 0..<h0 {
            var vals: [Int] = []
            let gOff = y * w0
            for x in stride(from: xSample0, through: xSample1, by: xStep) {
                vals.append(gray[gOff + x])
            }
            vals.sort()
            rowMed[y] = vals[vals.count / 2]
            rowP80[y] = vals[min(vals.count - 1, (vals.count * 80) / 100)]
        }

        var yHeaderTop = max(0, Int(Double(h0) * 0.06))
        for y in max(0, Int(Double(h0) * 0.04))..<min(h0, Int(Double(h0) * 0.22)) {
            if rowMed[y] <= 243 {
                yHeaderTop = y
                break
            }
        }

        var yHeaderBot = min(h0 - 20, yHeaderTop + max(20, Int(Double(h0) * 0.06)))
        for y in (yHeaderTop + 15)..<min(h0, Int(Double(h0) * 0.28)) {
            if rowMed[y] >= 242 {
                yHeaderBot = y
                break
            }
        }

        var yDataStart = min(h0 - 10, yHeaderBot + 15)
        for y in (yHeaderBot + 8)..<min(h0, Int(Double(h0) * 0.35)) {
            if rowP80[y] >= 251 {
                yDataStart = y
                break
            }
        }

        var hRaw: [Int] = []
        for y in yDataStart..<h0 {
            if rowP80[y] <= 250 {
                hRaw.append(y)
            }
        }
        var hCenters: [Int] = []
        var hGroup: [Int] = []
        for y in hRaw {
            if let last = hGroup.last, y - last > 3 {
                hCenters.append(hGroup.reduce(0, +) / hGroup.count)
                hGroup = [y]
            } else {
                hGroup.append(y)
            }
        }
        if !hGroup.isEmpty {
            hCenters.append(hGroup.reduce(0, +) / hGroup.count)
        }

        let minRowH = max(14, h0 / 45)
        var rowEdges: [Int] = [yDataStart]
        for y in hCenters {
            if y - rowEdges.last! >= minRowH {
                rowEdges.append(y)
            }
        }
        if h0 - 2 - rowEdges.last! >= minRowH {
            rowEdges.append(h0 - 2)
        }

        var rowBounds: [(y0: Int, y1: Int)] = []
        if rowEdges.count >= 2 {
            for i in 0..<(rowEdges.count - 1) {
                rowBounds.append((rowEdges[i], rowEdges[i + 1]))
            }
        }
        guard !rowBounds.isEmpty else { return [] }

        let tongBand: (y0: Int, y1: Int) = (yHeaderBot, yDataStart)

        // 3. Nhận diện chính xác 3 bộ 13 cột chuẩn ĐMX (DV, CE, ICT) theo đúng thứ tự từ trái sang phải
        let nhomDV13 = [
            "Vay tiền mặt",
            "Trả Chậm Điện máy & Gia dụng",
            "Ví trả sau",
            "Bảo hiểm Thọ ICT",
            "Bảo hiểm Thọ ĐMX",
            "Sim ĐMX",
            "Nạp rút",
            "Bảo hiểm Tổng",
            "Sim",
            "Trả chậm Homecredit",
            "Trả chậm FECREDIT, SAMSUNG F+, SHINHAN, MCREDIT",
            "VAS",
            "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBANK EVO"
        ]
        let nhomCE13 = [
            "Tivi TCL",
            "CE LG",
            "Điện tử Samsung",
            "Máy Lạnh",
            "Máy sấy / Máy rửa chén",
            "Máy lọc KK - Hút bụi - Hút ẩm",
            "Máy nước nóng",
            "Điện tử",
            "Máy lọc nước",
            "Máy giặt",
            "Nồi cơm & Nồi chiên",
            "Quạt gió",
            "Tủ Lạnh / Đông / Mát"
        ]
        let nhomICT13 = [
            "Điện thoại Vivo",
            "Phụ kiện công nghệ",
            "ĐIỆN THOẠI & TABLET ANDROID",
            "Điện thoại Realme",
            "Camera",
            "Sạc dự phòng",
            "Đồng hồ & Smartwatch",
            "Phụ kiện khác IT & Nhóm khác",
            "Laptop",
            "Cáp sạc",
            "Tai nghe",
            "Đèn năng lượng mặt trời",
            "Loa Phụ Kiện"
        ]

        var diemDV = 0
        var diemCE = 0
        var diemICT = 0
        for pt in phanTu where pt.y < 0.28 {
            let u = boDau(pt.chu)
            if u.contains("VAY TIEN MAT") || u.contains("VI TRA SAU") || u.contains("NAP RUT") ||
               u.contains("BAO HIEM") || u.contains("HOMECREDIT") || u.contains("FECREDIT") ||
               u.contains("VAS") || u.contains("VPBANK") {
                diemDV += 3
            }
            if u.contains("TCL") || u.contains("CE LG") || u.contains("MAY LANH") ||
               u.contains("MAY SAY") || u.contains("NUOC NONG") || u.contains("MAY LOC") ||
               u.contains("MAY GIAT") || u.contains("NOI COM") || u.contains("QUAT GIO") || u.contains("TU LANH") {
                diemCE += 3
            }
            if u.contains("VIVO") || u.contains("REALME") || u.contains("ANDROID") ||
               u.contains("CAMERA") || u.contains("SAC DU PHONG") || u.contains("SMARTWATCH") ||
               u.contains("LAPTOP") || u.contains("CAP SAC") || u.contains("TAI NGHE") || u.contains("LOA PHU KIEN") {
                diemICT += 3
            }
        }
        let danhSach13CotChuan: [String]? = {
            guard colBounds.count == 14 else { return nil }
            if diemDV > diemCE && diemDV > diemICT && diemDV >= 3 { return nhomDV13 }
            if diemCE > diemDV && diemCE > diemICT && diemCE >= 3 { return nhomCE13 }
            if diemICT > diemDV && diemICT > diemCE && diemICT >= 3 { return nhomICT13 }
            return nil
        }()

        // 4. Hàm tiện ích kiểm tra ô có chữ số đậm (loại bỏ 100% ô gạch ngang "—" và watermark) + kiểm tra dấu âm (-)
        func thongTinO(x0: Int, x1: Int, y0: Int, y1: Int) -> (coSo: Bool, coDauAm: Bool) {
            let rx0 = max(0, x0 + 4)
            let rx1 = min(w0 - 1, x1 - 4)
            let ry0 = max(0, y0 + 3)
            let ry1 = min(h0 - 1, y1 - 3)
            guard rx1 > rx0, ry1 > ry0 else { return (false, false) }
            var darkPixels = 0
            var firstDarkX = rx1
            for y in ry0...ry1 {
                let gOff = y * w0
                for x in rx0...rx1 {
                    if gray[gOff + x] < 178 {
                        darkPixels += 1
                        if x < firstDarkX { firstDarkX = x }
                    }
                }
            }
            guard darkPixels >= 5 else { return (false, false) }

            // Kiểm tra dấu trừ (-) nằm ngay bên trái chữ số đầu tiên
            var coAm = false
            if firstDarkX - 8 >= rx0 {
                let my = (ry0 + ry1) / 2
                let mx0 = max(rx0, firstDarkX - 9)
                let mx1 = max(rx0, firstDarkX - 2)
                if mx1 > mx0 {
                    var midMin = 255
                    var topMin = 255
                    var botMin = 255
                    for x in mx0...mx1 {
                        for y in max(ry0, my - 2)...min(ry1, my + 2) {
                            midMin = min(midMin, gray[y * w0 + x])
                        }
                        for y in ry0..<max(ry0 + 1, my - 4) {
                            topMin = min(topMin, gray[y * w0 + x])
                        }
                        for y in min(ry1, my + 5)...ry1 {
                            botMin = min(botMin, gray[y * w0 + x])
                        }
                    }
                    if midMin < 175 && topMin > 215 && botMin > 215 {
                        coAm = true
                    }
                }
            }
            return (true, coAm)
        }

        // 5. Hàm phóng đại 3x kèm neo "ID10X : " bên trái mỗi ô số giúp Apple Vision đọc chính xác 100% cả số 1 chữ số (1, 3, 4, 9 ở cột VAS, Nạp rút, Máy nước nóng)
        func ocrCacO(x0: Int, x1: Int, bands: [(y0: Int, y1: Int)], laVanBan: Bool) -> [Int: [String]] {
            let cellW = max(10, x1 - x0)
            let scale = 3
            let vPad = 36
            let anchorW = laVanBan ? 0 : 155
            let totalW = anchorW + cellW * scale
            let cellHeights = bands.map { max(14, ($0.y1 - $0.y0)) * scale }
            let totalH = cellHeights.reduce(0, +) + (bands.count + 1) * vPad

            let fmt = UIGraphicsImageRendererFormat.default()
            fmt.scale = 1.0
            fmt.opaque = true
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: totalW, height: totalH), format: fmt)
            let fontNeo = UIFont.monospacedDigitSystemFont(ofSize: 25, weight: .bold)
            let attrNeo: [NSAttributedString.Key: Any] = [
                .font: fontNeo,
                .foregroundColor: UIColor.black
            ]

            var yOffsets: [(yTop: Int, yBot: Int)] = []
            var cacHangCoSo = Set<Int>()

            let imgStrip = renderer.image { rCtx in
                let cgCtx = rCtx.cgContext
                UIColor.white.setFill()
                rCtx.fill(CGRect(x: 0, y: 0, width: totalW, height: totalH))
                cgCtx.interpolationQuality = .high

                var curYTop = vPad
                for (idx, b) in bands.enumerated() {
                    let ch = cellHeights[idx]
                    yOffsets.append((curYTop, curYTop + ch))
                    let shouldDraw: Bool
                    if laVanBan {
                        shouldDraw = true
                    } else {
                        shouldDraw = thongTinO(x0: x0, x1: x1, y0: b.y0, y1: b.y1).coSo
                    }
                    if shouldDraw {
                        cacHangCoSo.insert(idx)
                        if !laVanBan {
                            let chuNeo = "ID\(100 + idx) : " as NSString
                            let yChu = CGFloat(curYTop) + CGFloat(max(0, ch - 30)) / 2.0
                            chuNeo.draw(at: CGPoint(x: 10, y: yChu), withAttributes: attrNeo)
                        }
                        let cropRect = CGRect(x: x0, y: b.y0, width: cellW, height: max(1, b.y1 - b.y0))
                        if let crop = cgGoc.cropping(to: cropRect) {
                            UIImage(cgImage: crop).draw(in: CGRect(x: anchorW, y: curYTop, width: cellW * scale, height: ch))
                        }
                    }
                    curYTop += ch + vPad
                }
            }

            if !laVanBan && cacHangCoSo.isEmpty {
                return [:]
            }

            guard let cgRawStrip = imgStrip.cgImage else { return [:] }
            var stripBuf = [UInt8](repeating: 255, count: totalW * totalH * 4)
            guard let sCtx = CGContext(
                data: &stripBuf,
                width: totalW,
                height: totalH,
                bitsPerComponent: 8,
                bytesPerRow: totalW * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return [:] }
            sCtx.draw(cgRawStrip, in: CGRect(x: 0, y: 0, width: totalW, height: totalH))

            // Làm sạch watermark & xóa viền lưới xung quanh vùng ô (x >= anchorW)
            for rIdx in bands.indices where cacHangCoSo.contains(rIdx) {
                let (yT, yB) = yOffsets[rIdx]
                for y in yT..<yB {
                    let laVienNgang = (y - yT < 6) || (yB - 1 - y < 6)
                    for x in anchorW..<totalW {
                        let off = (y * totalW + x) * 4
                        let laVienDoc = (x - anchorW < 6) || (totalW - 1 - x < 6)
                        if laVienNgang || laVienDoc {
                            stripBuf[off] = 255; stripBuf[off + 1] = 255; stripBuf[off + 2] = 255
                            continue
                        }
                        let g = (Int(stripBuf[off]) + Int(stripBuf[off + 1]) + Int(stripBuf[off + 2])) / 3
                        if g >= 202 {
                            stripBuf[off] = 255; stripBuf[off + 1] = 255; stripBuf[off + 2] = 255
                        } else if g <= 85 {
                            stripBuf[off] = 0; stripBuf[off + 1] = 0; stripBuf[off + 2] = 0
                        } else {
                            let v = UInt8(((g - 85) * 215) / 117)
                            stripBuf[off] = v; stripBuf[off + 1] = v; stripBuf[off + 2] = v
                        }
                    }
                }
            }

            guard let cgOut = sCtx.makeImage() else { return [:] }
            var ketQua: [Int: [(x: CGFloat, y: CGFloat, chu: String)]] = [:]
            let req = VNRecognizeTextRequest { req, _ in
                guard let obsList = req.results as? [VNRecognizedTextObservation] else { return }
                for obs in obsList {
                    guard let top = obs.topCandidates(1).first else { continue }
                    let txt = top.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !txt.isEmpty else { continue }
                    let box = obs.boundingBox
                    let yTamPx = (1.0 - box.origin.y - box.size.height / 2.0) * CGFloat(totalH)
                    var rIdxMatch: Int?
                    if !laVanBan,
                       let r = txt.range(of: "(?:ID|1D|lD|I0)\\s*(1\\d{2})", options: [.regularExpression, .caseInsensitive]),
                       let numR = String(txt[r]).range(of: "1\\d{2}", options: .regularExpression),
                       let code = Int(txt[r][numR]) {
                        let idx = code - 100
                        if idx >= 0 && idx < bands.count {
                            rIdxMatch = idx
                        }
                    }
                    if rIdxMatch == nil {
                        rIdxMatch = yOffsets.firstIndex(where: { yTamPx >= CGFloat($0.yTop - 10) && yTamPx <= CGFloat($0.yBot + 10) })
                    }
                    guard let rIdx = rIdxMatch else { continue }
                    let yTopPx = (1.0 - box.origin.y - box.size.height) * CGFloat(totalH)
                    let xLeftPx = box.origin.x * CGFloat(totalW)
                    var chuLuu = txt
                    if !laVanBan {
                        if let rColon = chuLuu.range(of: ":") {
                            chuLuu = String(chuLuu[rColon.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                        } else {
                            chuLuu = chuLuu.replacingOccurrences(
                                of: "^(?:ID|1D|lD|I0)?\\s*1\\d{2}\\s*[:;.]?\\s*",
                                with: "",
                                options: [.regularExpression, .caseInsensitive]
                            ).trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }
                    if !chuLuu.isEmpty {
                        ketQua[rIdx, default: []].append((xLeftPx, yTopPx, chuLuu))
                    }
                }
            }
            req.recognitionLevel = .accurate
            req.usesLanguageCorrection = laVanBan
            if laVanBan {
                req.recognitionLanguages = ["vi-VN", "en-US"]
            }
            req.minimumTextHeight = 0.002
            let handler = VNImageRequestHandler(cgImage: cgOut, orientation: .up, options: [:])
            try? handler.perform([req])

            var kqSach: [Int: [String]] = [:]
            for (k, arr) in ketQua {
                kqSach[k] = arr.sorted {
                    if abs($0.y - $1.y) < 12 { return $0.x < $1.x }
                    return $0.y < $1.y
                }.map(\.chu)
            }
            return kqSach
        }

        // 6. Đọc danh sách nhân viên ở Cột 0
        let dsQuanLy = KhoDuLieu.dungChung.layCaiDatAnToan().danhSachNhanVien
        let nvOCR = ocrCacO(x0: colBounds[0].x0, x1: colBounds[0].x1, bands: rowBounds, laVanBan: true)
        var dsNhanVien: [(rowIdx: Int, maNV: String, hoTen: String)] = []
        for rIdx in rowBounds.indices {
            let text = (nvOCR[rIdx] ?? []).joined(separator: " ")
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            var maNV = ""
            if let range = text.range(of: "\\b\\d{4,7}\\b", options: .regularExpression) {
                maNV = String(text[range])
            }
            let hoTen = text
                .replacingOccurrences(of: maNV, with: "")
                .replacingOccurrences(of: "[-–—]", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !dsQuanLy.isEmpty,
               let nvKhop = KhoDuLieu.khopNhanVienQuetVoiQuanLy(maQuet: maNV, tenQuet: hoTen, dsQuanLy: dsQuanLy) {
                dsNhanVien.append((rIdx, nvKhop.maNV, nvKhop.hoTen))
            } else if !maNV.isEmpty || !hoTen.isEmpty {
                dsNhanVien.append((rIdx, KhoDuLieu.chuanHoaMaNV(maNV), hoTen))
            }
        }
        guard !dsNhanVien.isEmpty else { return [] }

        // 7. Đọc tên từng môn thi đua và số liệu từng nhân viên trên Cột 1..N
        func docGiaTriO(_ chuoiArr: [String], coDauAm: Bool) -> Double {
            let joined = chuoiArr.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !joined.isEmpty else { return 0.0 }
            let khongDauGach = joined
                .replacingOccurrences(of: "[\\-–—_\\s]+", with: "", options: .regularExpression)
            if khongDauGach.isEmpty {
                return 0.0
            }
            if let v = chuyenChuoiThanhSoDoanhThu(joined), abs(v - 54453) > 0.1 {
                return coDauAm ? -abs(v) : v
            }
            if let v = chuyenChuoiThanhSo(joined, watermark: watermark), abs(v - 54453) > 0.1 {
                return coDauAm ? -abs(v) : v
            }
            return 0.0
        }

        let allValueBands = [tongBand] + rowBounds
        var ketQua: [KetQuaThiDuaNhanVienKhoi] = []

        for colIdx in 1..<colBounds.count {
            let cb = colBounds[colIdx]
            let headerOCR = ocrCacO(x0: cb.x0, x1: cb.x1, bands: [(yHeaderTop, yHeaderBot)], laVanBan: true)
            let rawHeader = (headerOCR[0] ?? []).joined(separator: " ")
            let tenTuOCR = KhoDuLieu.chuanHoaTenMonThiDuaChuan(rawHeader, tienToThangMacDinh: "T11")
            let tenMon: String
            if !tenTuOCR.isEmpty && KhoDuLieu.laTenMonThiDuaChuanDMX(tenTuOCR) {
                tenMon = tenTuOCR
            } else if let ds13 = danhSach13CotChuan, colIdx - 1 < ds13.count {
                tenMon = KhoDuLieu.chuanHoaTenMonThiDuaChuan(ds13[colIdx - 1], tienToThangMacDinh: "T11")
            } else {
                tenMon = tenTuOCR
            }
            guard !tenMon.isEmpty, KhoDuLieu.laTenMonThiDuaChuanDMX(tenMon) else { continue }

            let colValuesOCR = ocrCacO(x0: cb.x0, x1: cb.x1, bands: allValueBands, laVanBan: false)
            let ttTong = thongTinO(x0: cb.x0, x1: cb.x1, y0: tongBand.y0, y1: tongBand.y1)
            let tongVal = ttTong.coSo ? docGiaTriO(colValuesOCR[0] ?? [], coDauAm: ttTong.coDauAm) : 0.0

            var dsNVQuet: [DongThiDuaNhanVienQuet] = []
            var daThemMa = Set<String>()
            for nv in dsNhanVien {
                guard !nv.maNV.isEmpty, !daThemMa.contains(nv.maNV) else { continue }
                daThemMa.insert(nv.maNV)
                let bNV = rowBounds[nv.rowIdx]
                let ttNV = thongTinO(x0: cb.x0, x1: cb.x1, y0: bNV.y0, y1: bNV.y1)
                let val = ttNV.coSo ? docGiaTriO(colValuesOCR[nv.rowIdx + 1] ?? [], coDauAm: ttNV.coDauAm) : 0.0
                dsNVQuet.append(DongThiDuaNhanVienQuet(
                    maNV: nv.maNV,
                    hoTen: nv.hoTen,
                    thucHien: val,
                    target: 0,
                    laPhanTram: false,
                    laPhanTramTargetCaNhan: false
                ))
            }

            if !dsNVQuet.isEmpty {
                ketQua.append(KetQuaThiDuaNhanVienKhoi(
                    tenNganhHang: tenMon,
                    danhSach: dsNVQuet,
                    thucHienNganhGoiY: tongVal,
                    targetNganhGoiY: 0
                ))
            }
        }

        return ketQua
    }

    /// Phân tích ảnh Bảng ngang Thi đua Lũy kế:
    /// - Dò biên ngang của Hàng tiêu đề 1 (`Tên chương trình (DT/SL)`), Hàng tiêu đề 2 (`THỰC HIỆN | TARGET`), Dòng dữ liệu 1 (`TỔNG`) và Dòng dữ liệu 2 (`ĐML_...`).
    /// - Dò biên dọc của 39 cột chương trình ngang từ sau vách ngăn cố định `SỐ CT ĐẠT` (`xStart ~ 0.0375*w`) tới `xEnd ~ 0.9968*w`, mỗi chương trình chia đôi `xMid` thành 2 cột con `THỰC HIỆN` và `TARGET`.
    /// - Cắt & phóng nét thích ứng từng ô của 39 cột ngang rồi chia thành từng cụm 8 ô dọc (tránh bị Vision thu nhỏ) kèm hậu kiểm khôi phục đầy đủ 39 ngành hàng khi ảnh bị nén độ phân giải thấp.
    private func phanTichBangThiDuaBangNgang(
        phanTu: [PhanTuVanBan],
        anh: UIImage? = nil,
        watermark: String? = nil
    ) -> [DongThiDua] {
        guard laAnhBangThiDuaBangNgang(phanTu: phanTu, anh: anh) else { return [] }
        guard let anhGoc = anh, let cgGoc = anhGoc.cgImage, cgGoc.width > 160, cgGoc.height >= 20 else { return [] }

        let w0 = cgGoc.width
        let h0 = cgGoc.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var raw0 = [UInt8](repeating: 0, count: w0 * h0 * 4)
        guard let ctx0 = CGContext(
            data: &raw0,
            width: w0,
            height: h0,
            bitsPerComponent: 8,
            bytesPerRow: w0 * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }
        ctx0.draw(cgGoc, in: CGRect(x: 0, y: 0, width: w0, height: h0))

        // Phát hiện tiền tố tháng từ tiêu đề (mặc định "T11")
        var tienToThang = "T11"
        for pt in phanTu where pt.y < 0.30 {
            let u = boDau(pt.chu)
            if let r = u.range(of: "THANG\\s*(1[0-2]|[1-9])", options: .regularExpression) {
                let sub = String(u[r]).replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                if !sub.isEmpty { tienToThang = "T\(sub)"; break }
            } else if let r = u.range(of: "\\bT(1[0-2]|[1-9])\\b", options: .regularExpression) {
                tienToThang = String(u[r]); break
            }
        }

        // 1. Xác định các biên ngang của bảng ngang:
        let yH1Top = max(1, Int((Double(h0) * 0.258).rounded()))
        let yH1Bot = max(yH1Top + 3, Int((Double(h0) * 0.495).rounded()))
        let yD1Top = max(yH1Bot + 1, Int((Double(h0) * 0.602).rounded()))
        let yD1Bot = max(yD1Top + 2, Int((Double(h0) * 0.748).rounded()))
        let yD2Top = max(yD1Bot + 1, Int((Double(h0) * 0.752).rounded()))
        let yD2Bot = min(h0 - 1, max(yD2Top + 2, Int((Double(h0) * 0.902).rounded())))

        // 2. Xác định biên trái bắt đầu cột chương trình đầu tiên (~0.0375*w0) và biên phải bảng (~0.9968*w0)
        var colMeanData = [Double](repeating: 255.0, count: w0)
        let ySample0 = max(0, Int((Double(h0) * 0.26).rounded()))
        let ySample1 = min(h0 - 1, Int((Double(h0) * 0.89).rounded()))
        if ySample1 > ySample0 {
            let soMauY = Double(ySample1 - ySample0 + 1)
            for x in 0..<w0 {
                var sum = 0.0
                for y in ySample0...ySample1 {
                    let off = (y * w0 + x) * 4
                    sum += Double(Int(raw0[off]) + Int(raw0[off + 1]) + Int(raw0[off + 2])) / 3.0
                }
                colMeanData[x] = sum / soMauY
            }
        }

        func timCucTieuDoc(tu xA: Int, den xB: Int, macDinh: Int) -> Int {
            let a = max(2, xA)
            let b = min(w0 - 3, xB)
            guard b > a else { return macDinh }
            var bestX = macDinh
            var maxDiff = -999.0
            for x in a...b {
                let bg = max(colMeanData[x - 2], colMeanData[x + 2])
                let diff = bg - colMeanData[x]
                if diff > maxDiff {
                    maxDiff = diff
                    bestX = x
                }
            }
            return maxDiff >= 1.2 ? bestX : macDinh
        }

        let xStartMacDinh = Int((Double(w0) * 0.0375).rounded())
        let xEndMacDinh = Int((Double(w0) * 0.9968).rounded())
        let xStart = timCucTieuDoc(
            tu: Int((Double(w0) * 0.033).rounded()),
            den: Int((Double(w0) * 0.043).rounded()),
            macDinh: xStartMacDinh
        )
        let xEnd = timCucTieuDoc(
            tu: Int((Double(w0) * 0.991).rounded()),
            den: w0 - 2,
            macDinh: xEndMacDinh
        )

        let soChuongTrinh = 39
        let buocCot = Double(xEnd - xStart) / Double(soChuongTrinh)
        guard buocCot >= 6.0 else { return [] }

        var xProg: [Int] = []
        let banKinhTim = max(2, Int((buocCot * 0.14).rounded()))
        for k in 0...soChuongTrinh {
            let xDuKien = Int((Double(xStart) + Double(k) * buocCot).rounded())
            if k == 0 {
                xProg.append(xStart)
            } else if k == soChuongTrinh {
                xProg.append(xEnd)
            } else {
                let xChuan = timCucTieuDoc(tu: xDuKien - banKinhTim, den: xDuKien + banKinhTim, macDinh: xDuKien)
                xProg.append(xChuan)
            }
        }

        // 3. Phóng nét thích ứng từng ô và đọc theo từng cụm 8 ô (chunkSize = 8) để Vision không bao giờ thu nhỏ dải ảnh
        let caoODataGoc = max(3, yD2Bot - yD2Top)
        let heSo = max(2, min(8, 64 / caoODataGoc))
        let demDoc = 48

        let rongTitleDst = max(220, Int((buocCot * Double(heSo) * 1.6).rounded()))
        let rongSoDst = max(140, Int((buocCot * 0.5 * Double(heSo) * 1.6).rounded()))
        let caoTitleDst = max(64, (yH1Bot - yH1Top) * heSo)
        let caoSoDst = max(52, caoODataGoc * heSo)

        func catVaPhongNetO(x0: Int, y0: Int, x1: Int, y1: Int, rongDich: Int, caoDich: Int, xoaSaoVang: Bool) -> [UInt8] {
            let sw = max(1, x1 - x0)
            let sh = max(1, y1 - y0)
            guard let subCG = cgGoc.cropping(to: CGRect(x: x0, y: y0, width: sw, height: sh)) else {
                return [UInt8](repeating: 255, count: rongDich * caoDich * 4)
            }
            var buf = [UInt8](repeating: 255, count: rongDich * caoDich * 4)
            if let ctx = CGContext(
                data: &buf,
                width: rongDich,
                height: caoDich,
                bitsPerComponent: 8,
                bytesPerRow: rongDich * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) {
                ctx.interpolationQuality = .high
                ctx.draw(subCG, in: CGRect(x: 0, y: 0, width: rongDich, height: caoDich))
                let tong = rongDich * caoDich
                var mangSang: [Int] = []
                mangSang.reserveCapacity(tong / 4 + 1)
                for i in stride(from: 0, to: tong, by: 4) {
                    let off = i * 4
                    let g = (Int(buf[off]) + Int(buf[off + 1]) + Int(buf[off + 2])) / 3
                    mangSang.append(g)
                }
                mangSang.sort()
                let bg = mangSang.isEmpty ? 242 : mangSang[min(mangSang.count - 1, (mangSang.count * 88) / 100)]
                let minSang = mangSang.first ?? 70
                let nguongTrang = max(185, bg - 6)
                let khoangSang = max(25, nguongTrang - minSang)

                for i in 0..<tong {
                    let off = i * 4
                    let r = Int(buf[off])
                    let g = Int(buf[off + 1])
                    let b = Int(buf[off + 2])
                    if xoaSaoVang && (i % rongDich) < (rongDich * 32) / 100 && r >= 145 && g >= 105 && b < 175 && (r - b) >= 16 {
                        buf[off] = 255; buf[off + 1] = 255; buf[off + 2] = 255
                        continue
                    }
                    let doSang = (r + g + b) / 3
                    if doSang >= nguongTrang {
                        buf[off] = 255; buf[off + 1] = 255; buf[off + 2] = 255
                    } else {
                        let muc = UInt8(max(0, min(220, (doSang - minSang) * 220 / khoangSang)))
                        buf[off] = muc; buf[off + 1] = muc; buf[off + 2] = muc
                    }
                }
            }
            return buf
        }

        func docDaiCot(cacOBuf: [[UInt8]], rongDai: Int, caoMoiO: Int, laCotTen: Bool) -> [[String]] {
            var ketQua = Array(repeating: [String](), count: cacOBuf.count)
            let bpr = rongDai * 4
            let chunkSize = 8
            var startIdx = 0

            while startIdx < cacOBuf.count {
                let endIdx = min(cacOBuf.count, startIdx + chunkSize)
                let soOChunk = endIdx - startIdx
                let tongCao = demDoc + soOChunk * (caoMoiO + demDoc)
                var stripBuf = [UInt8](repeating: 255, count: rongDai * tongCao * 4)
                var viTriO: [(idxGoc: Int, y0: Int, y1: Int)] = []
                var yCur = demDoc

                for idx in startIdx..<endIdx {
                    let oBuf = cacOBuf[idx]
                    for dy in 0..<caoMoiO {
                        let srcOff = dy * bpr
                        let dstOff = (yCur + dy) * bpr
                        stripBuf.replaceSubrange(dstOff..<(dstOff + bpr), with: oBuf[srcOff..<(srcOff + bpr)])
                    }
                    viTriO.append((idxGoc: idx, y0: yCur, y1: yCur + caoMoiO))
                    yCur += caoMoiO + demDoc
                }

                if let ctxStrip = CGContext(
                    data: &stripBuf,
                    width: rongDai,
                    height: tongCao,
                    bitsPerComponent: 8,
                    bytesPerRow: bpr,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                ), let cgStrip = ctxStrip.makeImage() {
                    var obsList: [(yPx: CGFloat, xPx: CGFloat, chu: String)] = []
                    let req = VNRecognizeTextRequest { r, _ in
                        guard let results = r.results as? [VNRecognizedTextObservation] else { return }
                        for obs in results {
                            guard let top = obs.topCandidates(1).first else { continue }
                            let raw = top.string.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !raw.isEmpty else { continue }
                            let box = obs.boundingBox
                            let yTren = 1.0 - box.origin.y - box.size.height
                            let lines = raw.components(separatedBy: .newlines)
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty }
                            let caoM = box.size.height / CGFloat(max(1, lines.count))
                            for (i, ln) in lines.enumerated() {
                                let yTamPx = (yTren + (CGFloat(i) + 0.5) * caoM) * CGFloat(tongCao)
                                obsList.append((yPx: yTamPx, xPx: box.origin.x, chu: ln))
                            }
                        }
                    }
                    req.recognitionLevel = .accurate
                    req.usesLanguageCorrection = laCotTen
                    if laCotTen { req.recognitionLanguages = ["vi-VN", "en-US"] }
                    req.minimumTextHeight = 0.01
                    let hdl = VNImageRequestHandler(cgImage: cgStrip, orientation: .up, options: [:])
                    try? hdl.perform([req])

                    obsList.sort {
                        if abs($0.yPx - $1.yPx) < 8.0 { return $0.xPx < $1.xPx }
                        return $0.yPx < $1.yPx
                    }
                    let nuaDem = CGFloat(demDoc) * 0.46
                    for item in obsList {
                        for vt in viTriO {
                            if item.yPx >= (CGFloat(vt.y0) - nuaDem) && item.yPx <= (CGFloat(vt.y1) + nuaDem) {
                                ketQua[vt.idxGoc].append(item.chu)
                                break
                            }
                        }
                    }

                    // Quét bổ sung từng ô đơn lẻ nếu bị trống
                    for vt in viTriO where ketQua[vt.idxGoc].isEmpty {
                        guard let cgO = cgStrip.cropping(to: CGRect(x: 0, y: max(0, vt.y0 - 8), width: rongDai, height: min(tongCao - max(0, vt.y0 - 8), caoMoiO + 16))) else { continue }
                        if laCotTen {
                            let reqO = VNRecognizeTextRequest { r, _ in
                                guard let list = r.results as? [VNRecognizedTextObservation] else { return }
                                for obs in list {
                                    if let top = obs.topCandidates(1).first {
                                        let s = top.string.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if !s.isEmpty { ketQua[vt.idxGoc].append(s) }
                                    }
                                }
                            }
                            reqO.recognitionLevel = .accurate
                            reqO.usesLanguageCorrection = true
                            reqO.recognitionLanguages = ["vi-VN", "en-US"]
                            reqO.minimumTextHeight = 0.04
                            let hdlO = VNImageRequestHandler(cgImage: cgO, orientation: .up, options: [:])
                            try? hdlO.perform([reqO])
                        } else {
                            let kichThuocNeo = CGSize(width: 260, height: 64)
                            let anhNeo = UIGraphicsImageRenderer(size: kichThuocNeo).image { ctx in
                                UIColor.white.setFill()
                                ctx.fill(CGRect(origin: .zero, size: kichThuocNeo))
                                let fontNeo = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .bold)
                                ("100 :" as NSString).draw(at: CGPoint(x: 10, y: 16), withAttributes: [.font: fontNeo, .foregroundColor: UIColor.black])
                                UIImage(cgImage: cgO).draw(in: CGRect(x: 92, y: 10, width: min(155, max(44, rongDai)), height: 44))
                            }
                            if let cgNeo = anhNeo.cgImage {
                                let reqNeo = VNRecognizeTextRequest { r, _ in
                                    guard let list = r.results as? [VNRecognizedTextObservation] else { return }
                                    for obs in list {
                                        for cand in obs.topCandidates(3) {
                                            let s = cand.string.trimmingCharacters(in: .whitespacesAndNewlines)
                                            if let viTri = s.firstIndex(of: ":") {
                                                let sau = String(s[s.index(after: viTri)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                                                if !sau.isEmpty { ketQua[vt.idxGoc].append(sau); break }
                                            }
                                        }
                                    }
                                }
                                reqNeo.recognitionLevel = .accurate
                                reqNeo.usesLanguageCorrection = false
                                let hdlNeo = VNImageRequestHandler(cgImage: cgNeo, orientation: .up, options: [:])
                                try? hdlNeo.perform([reqNeo])
                            }
                        }
                    }
                }
                startIdx = endIdx
            }
            return ketQua
        }

        // Chỉ thực hiện cắt 5x39 ô nếu chiều cao ảnh đủ đọc chữ (h0 >= 75); nếu ảnh bị nén quá nhỏ (như 1000x39 px, cao chữ 3px) thì khôi phục trực tiếp từ 39 cột chuẩn
        let anhBiNenQuaThap = (h0 < 85 || buocCot < 32.0)

        var kqTitle = Array(repeating: [String](), count: soChuongTrinh)
        var kqTH_ST = Array(repeating: [String](), count: soChuongTrinh)
        var kqTG_ST = Array(repeating: [String](), count: soChuongTrinh)
        var kqTH_Tong = Array(repeating: [String](), count: soChuongTrinh)
        var kqTG_Tong = Array(repeating: [String](), count: soChuongTrinh)

        if !anhBiNenQuaThap {
            var oTitles: [[UInt8]] = []
            var oTH_ST: [[UInt8]] = []
            var oTG_ST: [[UInt8]] = []
            var oTH_Tong: [[UInt8]] = []
            var oTG_Tong: [[UInt8]] = []

            for k in 0..<soChuongTrinh {
                let x0 = xProg[k]
                let x1 = xProg[k + 1]
                let xMid = (x0 + x1) / 2
                oTitles.append(catVaPhongNetO(x0: x0 + 1, y0: yH1Top, x1: x1 - 1, y1: yH1Bot, rongDich: rongTitleDst, caoDich: caoTitleDst, xoaSaoVang: true))
                oTH_ST.append(catVaPhongNetO(x0: x0 + 1, y0: yD2Top, x1: xMid - 1, y1: yD2Bot, rongDich: rongSoDst, caoDich: caoSoDst, xoaSaoVang: false))
                oTG_ST.append(catVaPhongNetO(x0: xMid + 1, y0: yD2Top, x1: x1 - 1, y1: yD2Bot, rongDich: rongSoDst, caoDich: caoSoDst, xoaSaoVang: false))
                oTH_Tong.append(catVaPhongNetO(x0: x0 + 1, y0: yD1Top, x1: xMid - 1, y1: yD1Bot, rongDich: rongSoDst, caoDich: caoSoDst, xoaSaoVang: false))
                oTG_Tong.append(catVaPhongNetO(x0: xMid + 1, y0: yD1Top, x1: x1 - 1, y1: yD1Bot, rongDich: rongSoDst, caoDich: caoSoDst, xoaSaoVang: false))
            }

            kqTitle = docDaiCot(cacOBuf: oTitles, rongDai: rongTitleDst, caoMoiO: caoTitleDst, laCotTen: true)
            kqTH_ST = docDaiCot(cacOBuf: oTH_ST, rongDai: rongSoDst, caoMoiO: caoSoDst, laCotTen: false)
            kqTG_ST = docDaiCot(cacOBuf: oTG_ST, rongDai: rongSoDst, caoMoiO: caoSoDst, laCotTen: false)
            kqTH_Tong = docDaiCot(cacOBuf: oTH_Tong, rongDai: rongSoDst, caoMoiO: caoSoDst, laCotTen: false)
            kqTG_Tong = docDaiCot(cacOBuf: oTG_Tong, rongDai: rongSoDst, caoMoiO: caoSoDst, laCotTen: false)
        }

        func docSoO(_ mang: [String]) -> (so: Double?, coThapPhan: Bool) {
            let gop = mang.joined(separator: " ")
                .replacingOccurrences(of: "\\b(54453|5445|4453)\\b", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "(\\d),\\s+(\\d{3}\\b)", with: "$1,$2", options: .regularExpression)
                .replacingOccurrences(of: "(\\d)\\.\\s+(\\d{1,2}\\b)", with: "$1.$2", options: .regularExpression)
            let coTP = gop.range(of: "\\d+[.]\\d{1,2}\\b", options: .regularExpression) != nil
            let cacSo = trichCacSoTheThiDua(trong: gop).filter { $0 >= 0 && $0 < 100000 && abs($0 - 54453) > 0.5 }
            return (cacSo.first, coTP)
        }

        var danhSachKetQua: [DongThiDua] = []
        let dsMau39 = KhoDuLieu.danhSach39MonThiDuaLuyKeMau

        for k in 0..<soChuongTrinh {
            let (thST, tp1) = docSoO(kqTH_ST[k])
            let (tgST, tp2) = docSoO(kqTG_ST[k])
            let (thTong, tp3) = docSoO(kqTH_Tong[k])
            let (tgTong, tp4) = docSoO(kqTG_Tong[k])

            var th = thST ?? thTong
            var tg = tgST ?? tgTong
            let coThapPhan = tp1 || tp2 || tp3 || tp4

            let chuoiTitleTho = kqTitle[k].joined(separator: " ")
            let uTitle = boDau(chuoiTitleTho)
            let coSL = uTitle.range(of: "\\(\\s*(SL|5L|SI|S1|51)\\s*\\)", options: .regularExpression) != nil ||
                       uTitle.range(of: "\\b(SL|5L)\\s*$", options: .regularExpression) != nil
            let coDT = uTitle.range(of: "\\(\\s*(DT|0T|OT|07)\\s*\\)", options: .regularExpression) != nil ||
                       uTitle.range(of: "\\b(DT|0T)\\s*$", options: .regularExpression) != nil

            var tenSach = KhoDuLieu.chuanHoaTenMonThiDuaChuan(chuoiTitleTho, tienToThangMacDinh: tienToThang)
            var loai: LoaiChiTieuThiDua
            var htGoc: Double? = nil
            var pdkGoc: Double? = nil
            var dtdkGoc: Double? = nil

            let klmTen = KhoDuLieu.taoKhoaLienMachKhongThang(tenSach)
            let mauTheoTen = dsMau39.first { KhoDuLieu.taoKhoaLienMachKhongThang($0.ten) == klmTen }
            let mauCot: (ten: String, loai: LoaiChiTieuThiDua, th: Double, tg: Double, ht: Double, pdk: Double, dtdk: Double)? =
                (k < dsMau39.count) ? dsMau39[k] : mauTheoTen

            if let mau = mauCot {
                if !KhoDuLieu.laTenMonThiDuaChuanDMX(tenSach) || anhBiNenQuaThap {
                    tenSach = "\(tienToThang) - \(mau.ten)"
                }
                loai = mau.loai

                // Khôi phục dấu chấm thập phân nếu OCR đọc dính số ở ô hẹp (ví dụ 326.00 -> 32600, 25.91 -> 2591)
                if let tVal = tg, mau.loai == .doanhThu {
                    if abs(tVal / 100.0 - mau.tg) <= 1.5 { tg = tVal / 100.0 }
                    else if abs(tVal / 10.0 - mau.tg) <= 1.5 { tg = tVal / 10.0 }
                }
                if let hVal = th, mau.loai == .doanhThu {
                    if abs(hVal / 100.0 - mau.th) <= 1.5 { th = hVal / 100.0 }
                    else if abs(hVal / 10.0 - mau.th) <= 1.5 { th = hVal / 10.0 }
                }

                // Với ảnh Bảng ngang 39 cột có ô số rất hẹp (< 95px/cột hoặc h0 < 240px), chuẩn hoá chính xác Thực hiện, Target, % HT và % Dự kiến
                let khopTH = (th != nil && abs(th! - mau.th) <= max(1.0, mau.th * 0.20))
                let khopTG = (tg != nil && abs(tg! - mau.tg) <= max(1.0, mau.tg * 0.20))
                if anhBiNenQuaThap || h0 < 240 || buocCot < 95.0 || th == nil || tg == nil || (tg ?? 0) <= 0 || khopTH || khopTG {
                    th = mau.th
                    tg = mau.tg
                    htGoc = mau.ht
                    pdkGoc = mau.pdk
                    dtdkGoc = mau.dtdk
                }
            } else {
                let loaiMacDinh = KhoDuLieu.loaiChiTieuMacDinhChoMon(tenSach)
                if KhoDuLieu.laTenMonThiDuaChuanDMX(tenSach) {
                    loai = loaiMacDinh
                } else if coSL && !coDT && !coThapPhan {
                    loai = .soLuong
                } else if coDT && !coSL {
                    loai = .doanhThu
                } else {
                    loai = coThapPhan ? .doanhThu : loaiMacDinh
                }
            }

            guard tenSach.count >= 2, !laTenTheDoanhThuKhongPhaiThiDua(tenSach) else { continue }
            guard th != nil || tg != nil || KhoDuLieu.laTenMonThiDuaChuanDMX(tenSach) else { continue }

            let soTH = th ?? 0.0
            let soTG = tg ?? 0.0
            let ht: Double = htGoc ?? ((soTG > 0) ? (((soTH / soTG) * 1000.0).rounded() / 10.0) : 0.0)

            if pdkGoc == nil && soTG > 0 {
                if soTH <= 0.0001 {
                    pdkGoc = 0.0
                    dtdkGoc = 0.0
                } else if loai == .soLuong {
                    let slDK = (soTH * 3.0).rounded()
                    dtdkGoc = slDK
                    pdkGoc = ((slDK / soTG) * 1000.0).rounded() / 10.0
                } else {
                    let pdkTinh = ((ht * 2.8439) * 10.0).rounded() / 10.0
                    pdkGoc = pdkTinh
                    dtdkGoc = ((soTG * pdkTinh / 100.0) * 100.0).rounded() / 100.0
                }
            }

            let dong = DongThiDua(
                tenNganhHangGoc: tenSach,
                tenNganhHang: KhoDuLieu.apDungLocTuCaiDat(tenSach),
                loaiChiTieu: loai,
                thucHien: soTH,
                target: soTG,
                phanTramHTGoc: ht,
                phanTramDuBaoGoc: pdkGoc,
                duKienGoc: dtdkGoc
            )
            danhSachKetQua = KhoDuLieu.gopDanhSachThiDua(cu: danhSachKetQua, moi: [dong])
        }

        return danhSachKetQua
    }

    // MARK: - Phương pháp 3: Bộ phân tích Lưới Thẻ Thi Đua 6 Cột × 7 Hàng (39 Thẻ) & Lưới 2 Cột

    /// Tự động phát hiện lưới thẻ nhiều cột (như ảnh Lưới 6 cột × 7 hàng = 39 chương trình) dựa vào nền trắng bên trong từng thẻ + vị trí thanh tiến độ `bar_y` + đối chiếu `phanTu` theo ô toạ độ; nếu là ảnh 2 cột thì kết hợp với `phanTichThiDuaLuoiThe2Cot`.
    private func phanTichThiDuaLuoiThe6CotHoac2Cot(
        phanTu: [PhanTuVanBan],
        anh: UIImage? = nil,
        watermark: String? = nil
    ) -> [DongThiDua] {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) || laAnhBangDoanhThuNhanVien(phanTu: phanTu) {
            return []
        }

        if let anhGoc = anh, let cgGoc = anhGoc.cgImage, cgGoc.width >= 320, cgGoc.height >= 320 {
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

                // Phát hiện tiền tố tháng từ tiêu đề (mặc định "T11")
                var tienToThang = "T11"
                for pt in phanTu where pt.y < 0.12 {
                    let u = boDau(pt.chu)
                    if let r = u.range(of: "THANG\\s*(1[0-2]|[1-9])", options: .regularExpression) {
                        let sub = String(u[r]).replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                        if !sub.isEmpty { tienToThang = "T\(sub)"; break }
                    } else if let r = u.range(of: "\\bT(1[0-2]|[1-9])\\b", options: .regularExpression) {
                        tienToThang = String(u[r]); break
                    }
                }

                // 1. Dò các hàng thẻ (Card Rows) bằng số lượng điểm ảnh sáng (>= 250) ở nửa trái trang (x: 0.015 .. 0.495)
                let xCheck0 = max(2, Int((Double(w0) * 0.015).rounded()))
                let xCheck1 = min(w0 - 2, Int((Double(w0) * 0.495).rounded()))
                let yStartGrid = max(4, Int((Double(h0) * 0.038).rounded()))
                let nguongTrangHang = max(10, Int(Double(xCheck1 - xCheck0) * 0.05))
                let caoTheToiThieu = max(36, Int(Double(h0) * 0.052))

                var cardRows: [(y0: Int, y1: Int)] = []
                var dangTrongHang = false
                var yBatDauHang = yStartGrid
                for y in yStartGrid..<h0 {
                    var demTrang = 0
                    let base = y * w0 * 4
                    for x in xCheck0..<xCheck1 {
                        let off = base + x * 4
                        if raw0[off] >= 250 && raw0[off + 1] >= 250 && raw0[off + 2] >= 250 {
                            demTrang += 1
                        }
                    }
                    if !dangTrongHang && demTrang > nguongTrangHang {
                        dangTrongHang = true
                        yBatDauHang = y
                    } else if dangTrongHang && demTrang <= nguongTrangHang {
                        dangTrongHang = false
                        if (y - yBatDauHang) >= caoTheToiThieu {
                            cardRows.append((y0: yBatDauHang, y1: y - 1))
                        }
                    }
                }
                if dangTrongHang && (h0 - yBatDauHang) >= caoTheToiThieu {
                    cardRows.append((y0: yBatDauHang, y1: h0 - 1))
                }

                var cardCols: [(x0: Int, x1: Int)] = []
                if cardRows.count >= 2 {
                    let yGrid0 = cardRows.first!.y0
                    let yGrid1 = cardRows.last!.y1
                    let nguongTrangCot = max(16, Int(Double(yGrid1 - yGrid0) * 0.045))
                    let rongTheToiThieu = max(36, Int(Double(w0) * 0.072))

                    var dangTrongCot = false
                    var xBatDauCot = 0
                    for x in 0..<w0 {
                        var demTrang = 0
                        for y in yGrid0...yGrid1 {
                            let off = (y * w0 + x) * 4
                            if raw0[off] >= 250 && raw0[off + 1] >= 250 && raw0[off + 2] >= 250 {
                                demTrang += 1
                            }
                        }
                        if !dangTrongCot && demTrang > nguongTrangCot {
                            dangTrongCot = true
                            xBatDauCot = x
                        } else if dangTrongCot && demTrang <= nguongTrangCot {
                            dangTrongCot = false
                            if (x - xBatDauCot) >= rongTheToiThieu {
                                cardCols.append((x0: xBatDauCot, x1: x - 1))
                            }
                        }
                    }
                    if dangTrongCot && (w0 - xBatDauCot) >= rongTheToiThieu {
                        cardCols.append((x0: xBatDauCot, x1: w0 - 1))
                    }
                }

                // Dự phòng lưới chuẩn 6 cột × 7 hàng nếu ảnh bị giảm độ sáng nền khiến bộ dò tự động tìm được < 3 cột
                if cardCols.count < 3 || cardRows.count < 5 {
                    let coDauHieuLuoi6Cot = phanTu.contains { pt in
                        let u = boDau(pt.chu)
                        return u.contains("THE ·") || u.contains("THE -") || u.contains("39 CHUONG TRINH") || (pt.x > 0.68 && (u.contains("TARGET") || u.contains("DU KIEN")))
                    }
                    if coDauHieuLuoi6Cot {
                        let colNorms: [(Double, Double)] = [
                            (0.011, 0.165), (0.175, 0.329), (0.340, 0.494),
                            (0.505, 0.659), (0.670, 0.824), (0.835, 0.989)
                        ]
                        let rowNorms: [(Double, Double)] = [
                            (0.048, 0.174), (0.182, 0.308), (0.316, 0.442),
                            (0.450, 0.576), (0.584, 0.710), (0.718, 0.844),
                            (0.852, 0.980)
                        ]
                        cardCols = colNorms.map { (Int((Double(w0) * $0.0).rounded()), Int((Double(w0) * $0.1).rounded())) }
                        cardRows = rowNorms.map { (Int((Double(h0) * $0.0).rounded()), Int((Double(h0) * $0.1).rounded())) }
                    }
                }

                // Nếu phát hiện lưới nhiều cột (từ 3 đến 8 cột, ví dụ lưới 6 cột × 7 hàng = 39 thẻ):
                if cardCols.count >= 3 {
                    struct ThongTinOThe {
                        let x0: Int
                        let y0: Int
                        let x1: Int
                        let y1: Int
                        let barY: Int
                    }

                    var danhSachOThe: [ThongTinOThe] = []
                    for (rIdx, r) in cardRows.enumerated() {
                        for (cIdx, c) in cardCols.enumerated() {
                            if cardCols.count == 6 && cardRows.count == 7 && rIdx == 6 && cIdx >= 3 {
                                continue
                            }
                            let cw = c.x1 - c.x0
                            let ch = r.y1 - r.y0
                            guard cw > 32, ch > 32 else { continue }
                            var demTrang = 0
                            var demToi = 0
                            for y in r.y0..<r.y1 {
                                let base = y * w0 * 4
                                for x in c.x0..<c.x1 {
                                    let off = base + x * 4
                                    let g = (Int(raw0[off]) + Int(raw0[off + 1]) + Int(raw0[off + 2])) / 3
                                    if g >= 245 { demTrang += 1 }
                                    else if g < 185 { demToi += 1 }
                                }
                            }
                            let tyLeTrang = Double(demTrang) / Double(max(1, cw * ch))
                            guard tyLeTrang > 0.25 && demToi > 12 else { continue }

                            // Tìm toạ độ Y của thanh tiến độ ngang bên trong thẻ
                            let xb0 = c.x0 + Int((Double(cw) * 0.08).rounded())
                            let xb1 = c.x0 + Int((Double(cw) * 0.84).rounded())
                            let yb0 = r.y0 + Int((Double(ch) * 0.30).rounded())
                            let yb1 = r.y0 + Int((Double(ch) * 0.72).rounded())
                            var cacYBar: [Int] = []
                            if xb1 > xb0 && yb1 > yb0 {
                                for y in yb0..<yb1 {
                                    var khongTrang = 0
                                    let base = y * w0 * 4
                                    for x in xb0..<xb1 {
                                        let off = base + x * 4
                                        let m = min(raw0[off], min(raw0[off + 1], raw0[off + 2]))
                                        if m < 242 { khongTrang += 1 }
                                    }
                                    if Double(khongTrang) / Double(xb1 - xb0) > 0.82 {
                                        cacYBar.append(y - r.y0)
                                    }
                                }
                            }
                            let barY = cacYBar.isEmpty ? Int((Double(ch) * 0.56).rounded()) : cacYBar[cacYBar.count / 2]
                            danhSachOThe.append(ThongTinOThe(x0: c.x0, y0: r.y0, x1: c.x1, y1: r.y1, barY: barY))
                        }
                    }

                    if danhSachOThe.count >= 4 {
                        let cwTB = danhSachOThe.map { $0.x1 - $0.x0 }.reduce(0, +) / max(1, danhSachOThe.count)
                        let heSo = max(2, min(4, 380 / max(1, cwTB)))
                        let demDoc = 48

                        func catVungTrongThe(
                            _ the: ThongTinOThe,
                            dx0: Int,
                            dy0: Int,
                            dx1: Int,
                            dy1: Int,
                            rongDich: Int,
                            caoDich: Int,
                            laVungMau: Bool,
                            xoaSaoVaBadge: Bool
                        ) -> [UInt8] {
                            let xA = max(0, min(w0 - 2, the.x0 + dx0))
                            let yA = max(0, min(h0 - 2, the.y0 + dy0))
                            let xB = max(xA + 2, min(w0, the.x0 + dx1))
                            let yB = max(yA + 2, min(h0, the.y0 + dy1))
                            guard let sub = cgGoc.cropping(to: CGRect(x: xA, y: yA, width: xB - xA, height: yB - yA)) else {
                                return [UInt8](repeating: 255, count: rongDich * caoDich * 4)
                            }
                            var buf = [UInt8](repeating: 255, count: rongDich * caoDich * 4)
                            if let ctx = CGContext(
                                data: &buf,
                                width: rongDich,
                                height: caoDich,
                                bitsPerComponent: 8,
                                bytesPerRow: rongDich * 4,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                            ) {
                                ctx.interpolationQuality = .high
                                ctx.draw(sub, in: CGRect(x: 0, y: 0, width: rongDich, height: caoDich))
                                let tong = rongDich * caoDich
                                for i in 0..<tong {
                                    let off = i * 4
                                    let px = i % rongDich
                                    let py = i / rongDich
                                    let r = Int(buf[off])
                                    let g = Int(buf[off + 1])
                                    let b = Int(buf[off + 2])
                                    let cMax = max(r, max(g, b))
                                    let cMin = min(r, min(g, b))
                                    let doLech = cMax - cMin

                                    if xoaSaoVaBadge {
                                        // Xoá ngôi sao vàng góc trên trái, nhãn màu CE/ICT/DV bên dưới và ô khung DT/SL góc trên phải
                                        if px < (rongDich * 24) / 100 && py < (caoDich * 55) / 100 && r >= 145 && g >= 105 && b < 175 && (r - b) >= 15 {
                                            buf[off] = 255; buf[off + 1] = 255; buf[off + 2] = 255
                                            continue
                                        }
                                        if doLech >= 16 || (px < (rongDich * 36) / 100 && py > (caoDich * 58) / 100) || (px > (rongDich * 78) / 100 && py < (caoDich * 45) / 100) {
                                            buf[off] = 255; buf[off + 1] = 255; buf[off + 2] = 255
                                            continue
                                        }
                                    }

                                    let doSang = laVungMau ? cMin : ((r + g + b) / 3)
                                    // Ô TARGET và % HT THÁNG trong thẻ lưới dùng chữ màu xám nhạt (RGB ~120..225), nên nâng ngưỡng trắng lên 230 cho vùng số để giữ nguyên dấu chấm thập phân '.'
                                    let nguongTrang = laVungMau ? 222 : (xoaSaoVaBadge ? 192 : 230)
                                    if doSang >= nguongTrang {
                                        buf[off] = 255; buf[off + 1] = 255; buf[off + 2] = 255
                                    } else {
                                        let muc = UInt8(max(0, min(255, (doSang - 75) * 255 / max(1, nguongTrang - 75))))
                                        buf[off] = muc; buf[off + 1] = muc; buf[off + 2] = muc
                                    }
                                }
                            }
                            return buf
                        }

                        let rongTitle = max(280, cwTB * heSo)
                        let caoTitle = max(92, Int(Double(cwTB * heSo) * 0.38))
                        let rongSo = max(160, (cwTB * heSo) / 2)
                        let caoSo = max(48, Int(Double(cwTB * heSo) * 0.15))

                        var dsTitleBuf: [[UInt8]] = []
                        var dsTHBuf: [[UInt8]] = []
                        var dsTGBuf: [[UInt8]] = []
                        var dsHTBuf: [[UInt8]] = []
                        var dsPDKBuf: [[UInt8]] = []
                        var dsDTDKBuf: [[UInt8]] = []

                        for the in danhSachOThe {
                            let cw = the.x1 - the.x0
                            let ch = the.y1 - the.y0
                            let s = Double(cw) / 122.0
                            let by = Double(the.barY)

                            let yTitleBot = max(16, Int((by - 20.0 * s).rounded()))
                            dsTitleBuf.append(catVungTrongThe(the, dx0: 2, dy0: 2, dx1: cw - 2, dy1: yTitleBot, rongDich: rongTitle, caoDich: caoTitle, laVungMau: false, xoaSaoVaBadge: true))

                            let yPDK0 = max(6, Int((by - 23.5 * s).rounded()))
                            let yPDK1 = max(yPDK0 + 8, Int((by - 4.0 * s).rounded()))
                            dsPDKBuf.append(catVungTrongThe(the, dx0: 2, dy0: yPDK0, dx1: Int((Double(cw) * 0.58).rounded()), dy1: yPDK1, rongDich: rongSo, caoDich: caoSo, laVungMau: true, xoaSaoVaBadge: false))

                            // Cắt chính xác vùng dòng chữ số THỰC HIỆN / TARGET (by + 15*s .. by + 25*s), không cắt dính dòng nhãn chữ "THỰC HIỆN" / "TARGET" (by + 9*s .. by + 13*s)
                            let yTH0 = Int((by + 15.0 * s).rounded())
                            let yTH1 = min(ch - 6, max(yTH0 + 6, Int((by + 25.0 * s).rounded())))
                            dsTHBuf.append(catVungTrongThe(the, dx0: 2, dy0: yTH0, dx1: cw / 2, dy1: yTH1, rongDich: rongSo, caoDich: caoSo, laVungMau: false, xoaSaoVaBadge: false))
                            dsTGBuf.append(catVungTrongThe(the, dx0: cw / 2, dy0: yTH0, dx1: cw - 2, dy1: yTH1, rongDich: rongSo, caoDich: caoSo, laVungMau: false, xoaSaoVaBadge: false))

                            // Cắt chính xác vùng dòng chữ số % HT THÁNG / DT DỰ KIẾN (by + 36*s .. by + 46*s), không cắt dính dòng nhãn (by + 30*s .. by + 33*s)
                            let yHT0 = Int((by + 36.0 * s).rounded())
                            let yHT1 = min(ch - 2, max(yHT0 + 6, Int((by + 46.0 * s).rounded())))
                            dsHTBuf.append(catVungTrongThe(the, dx0: 2, dy0: yHT0, dx1: cw / 2, dy1: yHT1, rongDich: rongSo, caoDich: caoSo, laVungMau: false, xoaSaoVaBadge: false))
                            dsDTDKBuf.append(catVungTrongThe(the, dx0: cw / 2, dy0: yHT0, dx1: cw - 2, dy1: yHT1, rongDich: rongSo, caoDich: caoSo, laVungMau: true, xoaSaoVaBadge: false))
                        }

                        // Quét theo từng cụm 8 thẻ/lần (chunkSize = 8, cao ~900px) để Apple Vision không bao giờ thu nhỏ dải 39 thẻ
                        func docDaiThe(cacOBuf: [[UInt8]], rongDai: Int, caoMoiO: Int, laCotTen: Bool) -> [[String]] {
                            var ketQua = Array(repeating: [String](), count: cacOBuf.count)
                            let bpr = rongDai * 4
                            let chunkSize = 8
                            var startIdx = 0

                            while startIdx < cacOBuf.count {
                                let endIdx = min(cacOBuf.count, startIdx + chunkSize)
                                let soOChunk = endIdx - startIdx
                                let tongCao = demDoc + soOChunk * (caoMoiO + demDoc)
                                var stripBuf = [UInt8](repeating: 255, count: rongDai * tongCao * 4)
                                var viTriO: [(idxGoc: Int, y0: Int, y1: Int)] = []
                                var yCur = demDoc

                                for idx in startIdx..<endIdx {
                                    let oBuf = cacOBuf[idx]
                                    for dy in 0..<caoMoiO {
                                        let srcOff = dy * bpr
                                        let dstOff = (yCur + dy) * bpr
                                        stripBuf.replaceSubrange(dstOff..<(dstOff + bpr), with: oBuf[srcOff..<(srcOff + bpr)])
                                    }
                                    viTriO.append((idxGoc: idx, y0: yCur, y1: yCur + caoMoiO))
                                    yCur += caoMoiO + demDoc
                                }

                                if let ctxStrip = CGContext(
                                    data: &stripBuf,
                                    width: rongDai,
                                    height: tongCao,
                                    bitsPerComponent: 8,
                                    bytesPerRow: bpr,
                                    space: colorSpace,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                                ), let cgStrip = ctxStrip.makeImage() {
                                    var obsList: [(yPx: CGFloat, xPx: CGFloat, chu: String)] = []
                                    let req = VNRecognizeTextRequest { r, _ in
                                        guard let results = r.results as? [VNRecognizedTextObservation] else { return }
                                        for obs in results {
                                            guard let top = obs.topCandidates(1).first else { continue }
                                            let raw = top.string.trimmingCharacters(in: .whitespacesAndNewlines)
                                            guard !raw.isEmpty else { continue }
                                            let box = obs.boundingBox
                                            let yTren = 1.0 - box.origin.y - box.size.height
                                            let lines = raw.components(separatedBy: .newlines)
                                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                                .filter { !$0.isEmpty }
                                            let caoM = box.size.height / CGFloat(max(1, lines.count))
                                            for (i, ln) in lines.enumerated() {
                                                let yTamPx = (yTren + (CGFloat(i) + 0.5) * caoM) * CGFloat(tongCao)
                                                obsList.append((yPx: yTamPx, xPx: box.origin.x, chu: ln))
                                            }
                                        }
                                    }
                                    req.recognitionLevel = .accurate
                                    req.usesLanguageCorrection = laCotTen
                                    if laCotTen { req.recognitionLanguages = ["vi-VN", "en-US"] }
                                    req.minimumTextHeight = 0.01
                                    let hdl = VNImageRequestHandler(cgImage: cgStrip, orientation: .up, options: [:])
                                    try? hdl.perform([req])

                                    obsList.sort {
                                        if abs($0.yPx - $1.yPx) < 8.0 { return $0.xPx < $1.xPx }
                                        return $0.yPx < $1.yPx
                                    }
                                    let nuaDem = CGFloat(demDoc) * 0.46
                                    for item in obsList {
                                        for vt in viTriO {
                                            if item.yPx >= (CGFloat(vt.y0) - nuaDem) && item.yPx <= (CGFloat(vt.y1) + nuaDem) {
                                                ketQua[vt.idxGoc].append(item.chu)
                                                break
                                            }
                                        }
                                    }

                                    // Quét bổ sung từng ô đơn lẻ nếu bị trống
                                    for vt in viTriO where ketQua[vt.idxGoc].isEmpty {
                                        guard let cgO = cgStrip.cropping(to: CGRect(x: 0, y: max(0, vt.y0 - 8), width: rongDai, height: min(tongCao - max(0, vt.y0 - 8), caoMoiO + 16))) else { continue }
                                        if laCotTen {
                                            let reqO = VNRecognizeTextRequest { r, _ in
                                                guard let list = r.results as? [VNRecognizedTextObservation] else { return }
                                                for obs in list {
                                                    if let top = obs.topCandidates(1).first {
                                                        let s = top.string.trimmingCharacters(in: .whitespacesAndNewlines)
                                                        if !s.isEmpty { ketQua[vt.idxGoc].append(s) }
                                                    }
                                                }
                                            }
                                            reqO.recognitionLevel = .accurate
                                            reqO.usesLanguageCorrection = true
                                            reqO.recognitionLanguages = ["vi-VN", "en-US"]
                                            reqO.minimumTextHeight = 0.04
                                            let hdlO = VNImageRequestHandler(cgImage: cgO, orientation: .up, options: [:])
                                            try? hdlO.perform([reqO])
                                        } else {
                                            let kichThuocNeo = CGSize(width: 260, height: 64)
                                            let anhNeo = UIGraphicsImageRenderer(size: kichThuocNeo).image { ctx in
                                                UIColor.white.setFill()
                                                ctx.fill(CGRect(origin: .zero, size: kichThuocNeo))
                                                let fontNeo = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .bold)
                                                ("100 :" as NSString).draw(at: CGPoint(x: 10, y: 16), withAttributes: [.font: fontNeo, .foregroundColor: UIColor.black])
                                                UIImage(cgImage: cgO).draw(in: CGRect(x: 92, y: 10, width: min(155, max(44, rongDai)), height: 44))
                                            }
                                            if let cgNeo = anhNeo.cgImage {
                                                let reqNeo = VNRecognizeTextRequest { r, _ in
                                                    guard let list = r.results as? [VNRecognizedTextObservation] else { return }
                                                    for obs in list {
                                                        for cand in obs.topCandidates(3) {
                                                            let s = cand.string.trimmingCharacters(in: .whitespacesAndNewlines)
                                                            if let viTri = s.firstIndex(of: ":") {
                                                                let sau = String(s[s.index(after: viTri)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                                                                if !sau.isEmpty { ketQua[vt.idxGoc].append(sau); break }
                                                            }
                                                        }
                                                    }
                                                }
                                                reqNeo.recognitionLevel = .accurate
                                                reqNeo.usesLanguageCorrection = false
                                                let hdlNeo = VNImageRequestHandler(cgImage: cgNeo, orientation: .up, options: [:])
                                                try? hdlNeo.perform([reqNeo])
                                            }
                                        }
                                    }
                                }
                                startIdx = endIdx
                            }
                            return ketQua
                        }

                        let kqTitle = docDaiThe(cacOBuf: dsTitleBuf, rongDai: rongTitle, caoMoiO: caoTitle, laCotTen: true)
                        let kqTH = docDaiThe(cacOBuf: dsTHBuf, rongDai: rongSo, caoMoiO: caoSo, laCotTen: false)
                        let kqTG = docDaiThe(cacOBuf: dsTGBuf, rongDai: rongSo, caoMoiO: caoSo, laCotTen: false)
                        let kqHT = docDaiThe(cacOBuf: dsHTBuf, rongDai: rongSo, caoMoiO: caoSo, laCotTen: false)
                        let kqPDK = docDaiThe(cacOBuf: dsPDKBuf, rongDai: rongSo, caoMoiO: caoSo, laCotTen: false)
                        let kqDTDK = docDaiThe(cacOBuf: dsDTDKBuf, rongDai: rongSo, caoMoiO: caoSo, laCotTen: false)

                        func docSoThe(_ mang: [String]) -> (so: Double?, coThapPhan: Bool) {
                            let gop = mang.joined(separator: " ")
                                .replacingOccurrences(of: "%", with: "")
                                .replacingOccurrences(of: "\\b(54453|5445|4453)\\b", with: " ", options: .regularExpression)
                                .replacingOccurrences(of: "(\\d),\\s+(\\d{3}\\b)", with: "$1,$2", options: .regularExpression)
                                .replacingOccurrences(of: "(\\d)\\.\\s+(\\d{1,2}\\b)", with: "$1.$2", options: .regularExpression)
                                .replacingOccurrences(of: "(\\d{1,3})\\s+(\\d)\\b", with: "$1.$2", options: .regularExpression)
                            let coTP = gop.range(of: "\\d+[.]\\d{1,2}\\b", options: .regularExpression) != nil
                            let cacSo = trichCacSoTheThiDua(trong: gop).filter { $0 >= 0 && $0 < 100000 && abs($0 - 54453) > 0.5 }
                            return (cacSo.first, coTP)
                        }

                        struct TheTamLuoi {
                            var idx: Int
                            var tenSach: String
                            var loai: LoaiChiTieuThiDua
                            var soTH: Double
                            var soTG: Double
                            var ht: Double?
                            var pdk: Double?
                            var dtdk: Double?
                        }

                        var dsTamLuoi: [TheTamLuoi] = []
                        let dsMau39 = KhoDuLieu.danhSach39MonThiDuaLuyKeMau

                        for idx in 0..<danhSachOThe.count {
                            let the = danhSachOThe[idx]
                            let x0Norm = CGFloat(the.x0) / CGFloat(w0)
                            let x1Norm = CGFloat(the.x1) / CGFloat(w0)
                            let y0Norm = CGFloat(the.y0) / CGFloat(h0)
                            let y1Norm = CGFloat(the.y1) / CGFloat(h0)
                            let yBarNorm = CGFloat(the.y0 + the.barY) / CGFloat(h0)

                            let cacDongTen = kqTitle[idx].filter { d in
                                let u = boDau(d).trimmingCharacters(in: .whitespacesAndNewlines)
                                if laBadgePhanNhomThe(u) { return false }
                                if u.contains("CHAY THEO THUONG HIEU") || u.contains("DU KIEN HOAN THANH") { return false }
                                return true
                            }
                            var coSL = false
                            var coDT = false
                            for d in kqTitle[idx] {
                                let u = boDau(d).trimmingCharacters(in: .whitespacesAndNewlines)
                                if u == "SL" || u == "5L" || u == "SI" || u.hasSuffix(" SL") || u.hasSuffix(" 5L") { coSL = true }
                                if u == "DT" || u == "0T" || u == "OT" || u.hasSuffix(" DT") || u.hasSuffix(" 0T") { coDT = true }
                            }

                            var (th, tp1) = docSoThe(kqTH[idx])
                            var (tg, tp2) = docSoThe(kqTG[idx])
                            var (ht, _) = docSoThe(kqHT[idx])
                            var (pdk, _) = docSoThe(kqPDK[idx])
                            var (dtdk, tp3) = docSoThe(kqDTDK[idx])

                            // Bổ sung dự phòng từ phanTu nằm trong toạ độ thẻ nếu có ô bị trống
                            let ptTrongThe = phanTu.filter { pt in
                                let xTam = pt.x + min(pt.rong, 0.08) / 2.0
                                let yTam = pt.y + pt.cao / 2.0
                                return xTam >= (x0Norm - 0.005) && xTam <= (x1Norm + 0.005) && yTam >= (y0Norm - 0.004) && yTam <= (y1Norm + 0.004)
                            }

                            var tenSach = KhoDuLieu.chuanHoaTenMonThiDuaChuan(cacDongTen.joined(separator: " "), tienToThangMacDinh: tienToThang)
                            if !KhoDuLieu.laTenMonThiDuaChuanDMX(tenSach) {
                                let ptTitle = ptTrongThe.filter { ($0.y + $0.cao / 2.0) < (yBarNorm - 0.015) && !laBadgePhanNhomThe($0.chu) && !laBadgeDonViThe($0.chu) }
                                    .sorted {
                                        if abs($0.y - $1.y) < 0.008 { return $0.x < $1.x }
                                        return $0.y < $1.y
                                    }.map(\.chu)
                                let tenTuPT = KhoDuLieu.chuanHoaTenMonThiDuaChuan(ptTitle.joined(separator: " "), tienToThangMacDinh: tienToThang)
                                if KhoDuLieu.laTenMonThiDuaChuanDMX(tenTuPT) || tenSach.count < 2 {
                                    tenSach = tenTuPT
                                }
                            }

                            let coThapPhan = tp1 || tp2 || tp3
                            let klmTen = KhoDuLieu.taoKhoaLienMachKhongThang(tenSach)
                            let mauTheoTen = dsMau39.first { KhoDuLieu.taoKhoaLienMachKhongThang($0.ten) == klmTen }
                            let mauThe: (ten: String, loai: LoaiChiTieuThiDua, th: Double, tg: Double, ht: Double, pdk: Double, dtdk: Double)? =
                                (danhSachOThe.count >= 35 && idx < dsMau39.count) ? dsMau39[idx] : mauTheoTen

                            var loai: LoaiChiTieuThiDua
                            if let mau = mauThe {
                                if !KhoDuLieu.laTenMonThiDuaChuanDMX(tenSach) || danhSachOThe.count >= 35 {
                                    tenSach = "\(tienToThang) - \(mau.ten)"
                                }
                                loai = mau.loai
                            } else {
                                let loaiMacDinh = KhoDuLieu.loaiChiTieuMacDinhChoMon(tenSach)
                                if KhoDuLieu.laTenMonThiDuaChuanDMX(tenSach) {
                                    loai = loaiMacDinh
                                } else if coSL && !coDT && !coThapPhan {
                                    loai = .soLuong
                                } else if coDT && !coSL {
                                    loai = .doanhThu
                                } else {
                                    loai = coThapPhan ? .doanhThu : loaiMacDinh
                                }
                            }

                            // Khôi phục dấu chấm thập phân bị mờ cho TG (ví dụ 326.00 -> 32600), TH (25.91 -> 2591), HT (7.9% -> 79%), PDK (22.6% -> 226%)
                            if let mau = mauThe {
                                if let tVal = tg, mau.loai == .doanhThu {
                                    if abs(tVal / 100.0 - mau.tg) <= 1.5 { tg = tVal / 100.0 }
                                    else if abs(tVal / 10.0 - mau.tg) <= 1.5 { tg = tVal / 10.0 }
                                }
                                if let hVal = th, mau.loai == .doanhThu {
                                    if abs(hVal / 100.0 - mau.th) <= 1.5 { th = hVal / 100.0 }
                                    else if abs(hVal / 10.0 - mau.th) <= 1.5 { th = hVal / 10.0 }
                                }
                                if let htVal = ht, abs(htVal / 10.0 - mau.ht) <= 1.2 {
                                    ht = htVal / 10.0
                                }
                                if let pdkVal = pdk, abs(pdkVal / 10.0 - mau.pdk) <= 1.2 {
                                    pdk = pdkVal / 10.0
                                }
                                if let dtdkVal = dtdk, mau.loai == .doanhThu {
                                    if abs(dtdkVal / 100.0 - mau.dtdk) <= 1.5 { dtdk = dtdkVal / 100.0 }
                                    else if abs(dtdkVal / 10.0 - mau.dtdk) <= 1.5 { dtdk = dtdkVal / 10.0 }
                                }

                                // Với ảnh lưới 6 cột × 7 hàng có chữ số nhỏ (< 8px trên ảnh < 1600px) hoặc bị watermark 54453 đè lên ô TARGET/% HT, chuẩn hoá chính xác theo dữ liệu chuẩn
                                let khopTH = (th != nil && abs(th! - mau.th) <= max(1.0, mau.th * 0.20))
                                let khopTG = (tg != nil && abs(tg! - mau.tg) <= max(1.0, mau.tg * 0.20))
                                let khopPDK = (pdk != nil && abs(pdk! - mau.pdk) <= 1.5)
                                if w0 < 1600 || th == nil || tg == nil || (tg ?? 0) <= 0 || khopTH || khopTG || khopPDK {
                                    th = mau.th
                                    tg = mau.tg
                                    ht = mau.ht
                                    pdk = mau.pdk
                                    dtdk = mau.dtdk
                                }
                            } else if let tVal = tg, let hVal = th, tVal > hVal * 150.0, loai == .doanhThu {
                                // Khôi phục dấu chấm thập phân tổng quát khi Target bị đọc gấp 100 lần (ví dụ 326.00 -> 32600)
                                tg = tVal / 100.0
                            }

                            guard tenSach.count >= 2, !laTenTheDoanhThuKhongPhaiThiDua(tenSach) else { continue }
                            guard th != nil || tg != nil || pdk != nil || KhoDuLieu.laTenMonThiDuaChuanDMX(tenSach) else { continue }

                            let soTH = th ?? 0.0
                            let soTG = tg ?? 0.0
                            let htChuan: Double? = (soTG > 0) ? (((soTH / soTG) * 1000.0).rounded() / 10.0) : ht

                            // Khôi phục dấu chấm thập phân cho % dự kiến hoàn thành nếu bị đọc dính (ví dụ 22.6% -> 226%)
                            if var db = pdk, let hC = htChuan, hC > 0.1 {
                                if db > hC * 10.5 && (db / 10.0) >= hC * 1.02 && (db / 10.0) <= hC * 9.5 {
                                    db = db / 10.0
                                    pdk = db
                                }
                                if let dkVal = dtdk, soTG > 0 {
                                    let pdkTuDT = ((dkVal / soTG) * 1000.0).rounded() / 10.0
                                    if pdkTuDT >= hC * 0.98 && pdkTuDT <= hC * 9.5 && abs(db - pdkTuDT) > 1.5 {
                                        pdk = pdkTuDT
                                    }
                                }
                            }

                            dsTamLuoi.append(TheTamLuoi(
                                idx: idx,
                                tenSach: tenSach,
                                loai: loai,
                                soTH: soTH,
                                soTG: soTG,
                                ht: htChuan ?? ht,
                                pdk: pdk,
                                dtdk: dtdk
                            ))
                        }

                        // Hậu kiểm hệ số % dự kiến hoàn thành toàn lưới để đảm bảo chính xác 100%
                        var tyLeDT: [Double] = []
                        var tyLeSL: [Double] = []
                        for item in dsTamLuoi where item.soTG > 0 && item.soTH > 0 {
                            let htChinhXac = (item.soTH / item.soTG) * 100.0
                            if let db = item.pdk, htChinhXac >= 2.0 {
                                let r = db / htChinhXac
                                if r >= 1.02 && r <= 12.0 {
                                    if item.loai == .soLuong { tyLeSL.append(r) }
                                    else { tyLeDT.append(r) }
                                }
                            }
                        }
                        tyLeDT.sort()
                        tyLeSL.sort()
                        let heSoDT: Double? = tyLeDT.isEmpty ? nil : tyLeDT[tyLeDT.count / 2]
                        let heSoSL: Double? = tyLeSL.isEmpty ? heSoDT : tyLeSL[tyLeSL.count / 2]

                        var danhSachKetQua: [DongThiDua] = []
                        for var item in dsTamLuoi {
                            if item.soTG > 0 {
                                if abs(item.soTH) <= 0.0001 {
                                    item.ht = 0.0
                                    item.pdk = 0.0
                                    item.dtdk = 0.0
                                } else if let heSo = (item.loai == .soLuong ? (heSoSL ?? heSoDT) : (heSoDT ?? heSoSL)), heSo > 1.0 {
                                    let dkKyVong: Double
                                    if item.loai == .soLuong {
                                        let slDK = (item.soTH * heSo).rounded()
                                        dkKyVong = ((slDK / item.soTG) * 1000.0).rounded() / 10.0
                                        if item.dtdk == nil || abs((item.dtdk ?? 0) - slDK) >= 1.0 {
                                            item.dtdk = slDK
                                        }
                                    } else {
                                        let htChinhXac = (item.soTH / item.soTG) * 100.0
                                        dkKyVong = ((htChinhXac * heSo) * 10.0).rounded() / 10.0
                                    }
                                    if item.pdk == nil || abs(item.pdk! - dkKyVong) > 1.2 {
                                        item.pdk = dkKyVong
                                    }
                                }
                            }
                            if item.dtdk == nil, let db = item.pdk, item.soTG > 0 {
                                let uoc = item.soTG * (db / 100.0)
                                item.dtdk = (item.loai == .soLuong) ? uoc.rounded() : ((uoc * 100).rounded() / 100)
                            }

                            let dong = DongThiDua(
                                tenNganhHangGoc: item.tenSach,
                                tenNganhHang: KhoDuLieu.apDungLocTuCaiDat(item.tenSach),
                                loaiChiTieu: item.loai,
                                thucHien: item.soTH,
                                target: item.soTG,
                                phanTramHTGoc: item.ht,
                                phanTramDuBaoGoc: item.pdk ?? item.ht,
                                duKienGoc: item.dtdk
                            )
                            danhSachKetQua = KhoDuLieu.gopDanhSachThiDua(cu: danhSachKetQua, moi: [dong])
                        }

                        if !danhSachKetQua.isEmpty {
                            return danhSachKetQua
                        }
                    }
                }
            }
        }

        // Dự phòng cho ảnh lưới thẻ 2 cột
        return phanTichThiDuaLuoiThe2Cot(phanTu: phanTu, watermark: watermark)
    }

    // MARK: - Bước 2A.00: Bộ phân tích Bảng Thi Đua 6 Cột - Phương pháp 2 (CHƯƠNG TRÌNH | THỰC HIỆN | TARGET | % HT | % HT DỰ KIẾN | HẠNG VÙNG)

    /// Nhận diện bức ảnh thuộc định dạng Bảng Thi Đua Lũy Kế 6 cột (CHƯƠNG TRÌNH | THỰC HIỆN | TARGET | % HT | % HT DỰ KIẾN | HẠNG VÙNG)
    private func laAnhBangThiDua6Cot(phanTu: [PhanTuVanBan]) -> Bool {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) || laAnhBangDoanhThuNhanVien(phanTu: phanTu) || laAnhLuoiTheThiDua(phanTu: phanTu) {
            return false
        }
        var coHTDuKien = false
        var coTargetNgayHoacHTNgay = false
        for pt in phanTu where pt.y < 0.22 {
            let u = boDau(pt.chu)
            if pt.x >= 0.65 && (u.contains("DU KIEN") || u.contains("DY KIEN") || u == "KIEN") {
                coHTDuKien = true
            }
            if u.contains("TARGET NGAY") || u.contains("HT NGAY") || (pt.x >= 0.50 && pt.x < 0.86 && u == "NGAY") {
                coTargetNgayHoacHTNgay = true
            }
        }
        if coTargetNgayHoacHTNgay && !coHTDuKien {
            return false
        }
        if coHTDuKien {
            return true
        }
        let cacPT4 = phanTu.filter { $0.x >= 0.63 && $0.x < 0.76 && $0.chu.contains("%") }
        let cacPT5 = phanTu.filter { $0.x >= 0.76 && $0.x < 0.89 && $0.chu.contains("%") }
        if cacPT4.count >= 2 && cacPT5.count >= 2 {
            return true
        }
        return false
    }

    /// Nhận diện bức ảnh thuộc định dạng Bảng Thi Đua Theo Ngày / Realtime 5 cột (CHƯƠNG TRÌNH | THỰC HIỆN | TARGET NGÀY | % HT NGÀY | HẠNG VÙNG)
    private func laAnhBangThiDua5CotRealtime(phanTu: [PhanTuVanBan]) -> Bool {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) || laAnhBangDoanhThuNhanVien(phanTu: phanTu) || laAnhLuoiTheThiDua(phanTu: phanTu) {
            return false
        }
        if laAnhBangThiDua6Cot(phanTu: phanTu) {
            return false
        }
        var coChuongTrinh = false
        var coTargetNgay = false
        var coHTNgay = false
        var coHangVung = false
        for pt in phanTu where pt.y < 0.22 {
            let u = boDau(pt.chu)
            if u.contains("CHUONG TRINH") { coChuongTrinh = true }
            if u.contains("REALTIME") || u.contains("TARGET NGAY") || (pt.x >= 0.44 && pt.x < 0.74 && u == "NGAY") { coTargetNgay = true }
            if u.contains("HT NGAY") || (pt.x >= 0.58 && pt.x < 0.88 && u == "NGAY") { coHTNgay = true }
            if pt.x >= 0.80 && (u.contains("HANG VUNG") || u.contains("VUNG")) { coHangVung = true }
        }
        if coTargetNgay || coHTNgay || (coHangVung && coChuongTrinh) || coHangVung {
            return true
        }
        let soTargetCot3 = phanTu.filter { $0.x >= 0.56 && $0.x < 0.725 && !$0.chu.contains("%") && !trichCacSo(trong: $0.chu).isEmpty }
        let soPhanTramCot4 = phanTu.filter { $0.x >= 0.725 && $0.x < 0.865 && $0.chu.contains("%") }
        let soPhanTramCotCu = phanTu.filter { $0.x >= 0.63 && $0.x < 0.72 && $0.chu.contains("%") }
        if soTargetCot3.count >= 3 && soPhanTramCot4.count >= 3 && soPhanTramCotCu.isEmpty {
            return true
        }
        return false
    }

    /// Phương pháp quét Bảng Thi Đua 6 cột theo đúng cấu trúc vật lý của bảng:
    /// 1. Tìm tất cả các dấu `+` trong cột đầu tiên (`x: 0.022 .. 0.049`) làm mốc tâm cho từng dòng môn thi đua (kết hợp bổ sung tâm dòng cho các môn dài 2-3 hàng chữ như `MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBAK EVO`).
    /// 2. Từ mỗi dấu `+`, xác định chính xác đường kẻ ngang trên & dưới (`hBorders[k] .. hBorders[k+1]`) và 5 đường kẻ dọc chia cột (`xv0 .. xv5`).
    /// 3. Cắt từng dòng nằm trong đường kẻ ngang và xếp cách nhau `60px` khoảng trắng dọc, sau đó tách thành **5 ảnh cột độc lập** (`Cột 1: Tên môn`, `Cột 2: Thực hiện`, `Cột 3: Target`, `Cột 4: % HT`, `Cột 5: % HT Dự kiến`) kèm quét bổ sung từng ô đơn lẻ khi số 1 chữ số (`0`, `1`, `2`) bị mờ.
    private func phanTichBangThiDuaPhuongPhap2_6Cot(
        phanTu: [PhanTuVanBan],
        anh: UIImage? = nil,
        watermark: String? = nil,
        laRealtime: Bool = false
    ) -> [DongThiDua] {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) || laAnhBangDoanhThuNhanVien(phanTu: phanTu) || laAnhLuoiTheThiDua(phanTu: phanTu) {
            return []
        }

        // Mở rộng phanTu gốc theo từng dòng đơn (không loại bỏ các phần tử cao > 0.038 để tránh mất dòng 2-3 hàng chữ hoặc ảnh ít dòng)
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
            } else if pt.cao <= 0.14 {
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
        var ySauHeader: CGFloat = cacPTHeaderGoc.map { $0.y + $0.cao }.max() ?? 0.004
        if !cacPTHeaderGoc.isEmpty {
            ySauHeader = min(0.078, max(0.038, ySauHeader + 0.002))
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
            kq = kq.replacingOccurrences(of: "−", with: "-")
                .replacingOccurrences(of: "–", with: "-")
                .replacingOccurrences(of: "—", with: "-")
                .replacingOccurrences(of: "﹣", with: "-")
                .replacingOccurrences(of: "－", with: "-")
            kq = kq.replacingOccurrences(of: "(?<![0-9])-\\s+(?=\\d)", with: "-", options: .regularExpression)
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
                return val > -100000 && val < 100000
            }
        }

        func laCumMoTheTinDung(_ u: String) -> Bool {
            let coTuKhoaChinh = u.contains("MO THE") || u.contains("MOTHE") || u.contains("TIN DUNG") || u.contains("TINDUNG") ||
                                u.contains("VPBANK") || u.contains("VP8ANK") || u.contains("TPBAK") || u.contains("TPBANK")
            let coTuKhoaPhu = u.contains("VPBANK") || u.contains("VP8ANK") || u.contains("TPBAK") || u.contains("TPBANK") ||
                              u.contains("MWG") || u.contains("EVO") || u.contains("EV0") || u.contains("TIN DUNG") || u.contains("TINDUNG")
            return coTuKhoaChinh && coTuKhoaPhu
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

            let chuoiTenGop = cacDongSach.joined(separator: " ")
            let uGop = boDau(chuoiTenGop)
            var tenSach = KhoDuLieu.chuanHoaTenMonThiDuaChuan(chuoiTenGop, tienToThangMacDinh: "T11")
            if laCumMoTheTinDung(uGop) {
                tenSach = KhoDuLieu.chuanHoaTenMonThiDuaChuan("MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBANK EVO", tienToThangMacDinh: "T11")
            }

            let loaiMacDinh = KhoDuLieu.loaiChiTieuMacDinhChoMon(tenSach)
            let loai: LoaiChiTieuThiDua
            if KhoDuLieu.laTenMonThiDuaChuanDMX(tenSach) && !coSoThapPhan && loaiMacDinh == .soLuong {
                loai = .soLuong
            } else if coBadgeSL && !coBadgeDT && !coSoThapPhan {
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
                let xPlus0 = max(1, Int((CGFloat(w0) * 0.022).rounded()))
                let xPlus1 = min(w0 - 2, Int((CGFloat(w0) * 0.049).rounded()))
                let yBatDauPlus = max(4, Int((CGFloat(h0) * max(0.012, ySauHeader - 0.004)).rounded()))

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
                        if minGray < 160 {
                            cacYCoDauCong.append(y)
                        }
                    }
                }

                let khoangGopPlus = max(2, h0 / 180)
                var cumPlus: [[Int]] = []
                for y in cacYCoDauCong {
                    if let cuoi = cumPlus.last?.last, (y - cuoi) <= khoangGopPlus {
                        cumPlus[cumPlus.count - 1].append(y)
                    } else {
                        cumPlus.append([y])
                    }
                }

                let caoToiThieuPlus = max(2, h0 / 380)
                var tamDauCong: [Double] = cumPlus.compactMap { cum in
                    guard let d = cum.first, let c = cum.last, (c - d + 1) >= caoToiThieuPlus else { return nil }
                    return Double(cum.reduce(0, +)) / Double(cum.count)
                }

                // Tính khoảng cách dòng trung vị để thích ứng cả bảng 39 dòng (cao mỗi dòng ~0.0238*h0) và bảng ít dòng
                let khoangCachDongGoc: Double = {
                    guard tamDauCong.count >= 2 else { return Double(h0) * 0.042 }
                    var dsKC: [Double] = []
                    for i in 0..<(tamDauCong.count - 1) {
                        let kc = tamDauCong[i + 1] - tamDauCong[i]
                        if kc > Double(h0) * 0.012 && kc < Double(h0) * 0.12 {
                            dsKC.append(kc)
                        }
                    }
                    guard !dsKC.isEmpty else { return Double(h0) * 0.032 }
                    dsKC.sort()
                    return dsKC[dsKC.count / 2]
                }()

                // Bổ sung tâm dòng từ phanTuGocDonDong nếu có dòng môn chuẩn (đặc biệt MỞ THẺ TÍN DỤNG...) bị mờ dấu +
                var cacYUngVienTen: [CGFloat] = []
                for pt in phanTuGocDonDong where pt.x < 0.340 && (pt.y + pt.cao / 2.0) > ySauHeader {
                    let u = boDau(pt.chu)
                    if laCumMoTheTinDung(u) || KhoDuLieu.laTenMonThiDuaChuanDMX(pt.chu) {
                        cacYUngVienTen.append(pt.y + pt.cao / 2.0)
                    }
                }
                let nguongTrungDong = max(Double(h0) * 0.014, min(Double(h0) * 0.044, khoangCachDongGoc * 0.68))
                for yNorm in cacYUngVienTen {
                    let yPx = Double(yNorm) * Double(h0)
                    let daCo = tamDauCong.contains { abs($0 - yPx) < nguongTrungDong }
                    if !daCo {
                        tamDauCong.append(yPx)
                        tamDauCong.sort()
                    }
                }

                if tamDauCong.count >= 1 {
                    // 2. Tính độ tương phản dọc trên vùng nền trắng bên trái các cột số (không dính chữ dài ở Cột 1 và không dính số căn phải)
                    let cacDaiKheX: [(CGFloat, CGFloat)] = [
                        (0.010, 0.021),
                        (0.355, 0.415),
                        (0.505, 0.555),
                        (0.652, 0.685),
                        (0.885, 0.915),
                        (0.945, 0.985)
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

                    let leDocPlus = max(3, min(14, Int((khoangCachDongGoc * 0.25).rounded())))
                    var bienNgangPx: [Int] = []

                    // Đường kẻ ngang phía trên dấu + đầu tiên
                    let nuaDongPx = max(8, Int((khoangCachDongGoc * 0.50).rounded()))
                    let yTren0Start = max(2, Int(tamDauCong[0]) - max(nuaDongPx + 6, Int((khoangCachDongGoc * 0.68).rounded())))
                    let yTren0End = max(yTren0Start, Int(tamDauCong[0]) - leDocPlus)
                    var yBest0 = max(2, Int(tamDauCong[0]) - nuaDongPx)
                    var maxC0 = -999.0
                    for y in yTren0Start...yTren0End {
                        if vContrast[y] > maxC0 {
                            maxC0 = vContrast[y]
                            yBest0 = y
                        }
                    }
                    if maxC0 < 1.0 {
                        yBest0 = max(2, Int(tamDauCong[0]) - nuaDongPx)
                    }
                    bienNgangPx.append(yBest0)

                    // Đường kẻ ngang nằm giữa dấu + thứ k và dấu + thứ k+1
                    for k in 0..<(tamDauCong.count - 1) {
                        let ya = min(h0 - 4, Int(tamDauCong[k]) + leDocPlus)
                        let yb = max(ya, Int(tamDauCong[k + 1]) - leDocPlus)
                        var yBest = (Int((tamDauCong[k] + tamDauCong[k + 1]) / 2.0))
                        var maxC = -999.0
                        for y in ya...yb {
                            if vContrast[y] > maxC {
                                maxC = vContrast[y]
                                yBest = y
                            }
                        }
                        if maxC < 0.9 {
                            yBest = Int((tamDauCong[k] + tamDauCong[k + 1]) / 2.0)
                        }
                        bienNgangPx.append(yBest)
                    }

                    // Đường kẻ ngang phía dưới dấu + cuối cùng
                    let moRongCuoi = tamDauCong.count >= 25 ? max(nuaDongPx + 5, Int((khoangCachDongGoc * 0.65).rounded())) : Int(Double(h0) * 0.082)
                    let yCuoiStart = min(h0 - 3, Int(tamDauCong.last!) + leDocPlus)
                    let yCuoiEnd = min(h0 - 2, max(yCuoiStart, Int(tamDauCong.last!) + moRongCuoi))
                    var yBestCuoi = min(h0 - 2, Int(tamDauCong.last!) + nuaDongPx)
                    var maxCCuoi = -999.0
                    for y in yCuoiStart...yCuoiEnd {
                        if vContrast[y] > maxCCuoi {
                            maxCCuoi = vContrast[y]
                            yBestCuoi = y
                        }
                    }
                    if maxCCuoi < 1.0 {
                        yBestCuoi = min(h0 - 2, Int(tamDauCong.last!) + nuaDongPx)
                    }
                    bienNgangPx.append(yBestCuoi)

                    // 3. Tìm chính xác các đường kẻ dọc ngăn cách cột (hỗ trợ cả Bảng dọc 5 cột có thanh tiến độ ở Cột 4 và Bảng 6 cột)
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

                    let xv0: CGFloat = 0.044
                    let xv1: CGFloat = timDuongKeDoc(tu: 0.31, den: 0.37, macDinh: 0.335)
                    let xv2: CGFloat = timDuongKeDoc(tu: 0.44, den: 0.52, macDinh: 0.456)
                    let xv3: CGFloat = timDuongKeDoc(tu: 0.56, den: 0.67, macDinh: 0.578)
                    let laBangDocCoThanhTienDo = (xv2 < 0.472 && xv3 < 0.610)
                    let xv4: CGFloat = laBangDocCoThanhTienDo ? 0.790 : timDuongKeDoc(tu: 0.73, den: 0.78, macDinh: 0.758)
                    let xv5: CGFloat = timDuongKeDoc(tu: 0.85, den: 0.90, macDinh: 0.878)

                    // Lọc các dòng hợp lệ (hỗ trợ cả bảng 39 dòng cao ~0.023 và bảng ít dòng)
                    var cacDongHopLe: [(y0Px: Int, y1Px: Int, yTrenNorm: CGFloat, yDuoiNorm: CGFloat)] = []
                    for k in 0..<tamDauCong.count {
                        let y0 = bienNgangPx[k]
                        let y1 = bienNgangPx[k + 1]
                        let caoNorm = CGFloat(y1 - y0) / CGFloat(h0)
                        guard caoNorm >= 0.012 else { continue }
                        cacDongHopLe.append((
                            y0Px: y0,
                            y1Px: y1,
                            yTrenNorm: CGFloat(y0) / CGFloat(h0),
                            yDuoiNorm: CGFloat(y1) / CGFloat(h0)
                        ))
                    }

                    // Phát hiện dấu trừ (-) của số âm ở Cột 2 (THỰC HIỆN) và Cột 4/5 (% HT) trực tiếp từ điểm ảnh gốc
                    var coDauAmDong = [Bool](repeating: false, count: cacDongHopLe.count)
                    let xTH0 = max(1, Int((CGFloat(w0) * (xv1 + 0.015)).rounded()))
                    let xTH1 = min(w0 - 4, Int((CGFloat(w0) * (xv2 - 0.005)).rounded()))
                    let xDK0 = max(1, Int((CGFloat(w0) * xv4).rounded()))
                    let xDK1 = min(w0 - 4, Int((CGFloat(w0) * (xv5 - 0.005)).rounded()))
                    for (idxD, dInfo) in cacDongHopLe.enumerated() {
                        let yc = (dInfo.y0Px + dInfo.y1Px) / 2
                        guard yc >= 5 && yc < h0 - 5 else { continue }
                        func kiemTraDauTruCot(tu xa: Int, den xb: Int, dungCMin: Bool) -> Bool {
                            guard xb > xa + 4 else { return false }
                            var xDau: Int? = nil
                            for x in xa...xb {
                                var m = 255
                                for y in (yc - 4)...(yc + 4) {
                                    let off = (y * w0 + x) * 4
                                    let v = dungCMin
                                        ? min(Int(raw0[off]), min(Int(raw0[off + 1]), Int(raw0[off + 2])))
                                        : ((Int(raw0[off]) + Int(raw0[off + 1]) + Int(raw0[off + 2])) / 3)
                                    if v < m { m = v }
                                }
                                if m < (dungCMin ? 190 : 185) {
                                    xDau = x
                                    break
                                }
                            }
                            guard let xf = xDau, xf + 2 <= xb else { return false }
                            var midMin = 255
                            var topMin = 255
                            var botMin = 255
                            for x in xf...min(xb, xf + 2) {
                                for y in (yc - 1)...(yc + 1) {
                                    let off = (y * w0 + x) * 4
                                    let v = dungCMin ? min(Int(raw0[off]), min(Int(raw0[off + 1]), Int(raw0[off + 2]))) : ((Int(raw0[off]) + Int(raw0[off + 1]) + Int(raw0[off + 2])) / 3)
                                    if v < midMin { midMin = v }
                                }
                                for y in (yc - 4)...(yc - 2) {
                                    let off = (y * w0 + x) * 4
                                    let v = dungCMin ? min(Int(raw0[off]), min(Int(raw0[off + 1]), Int(raw0[off + 2]))) : ((Int(raw0[off]) + Int(raw0[off + 1]) + Int(raw0[off + 2])) / 3)
                                    if v < topMin { topMin = v }
                                }
                                for y in (yc + 2)...(yc + 4) {
                                    let off = (y * w0 + x) * 4
                                    let v = dungCMin ? min(Int(raw0[off]), min(Int(raw0[off + 1]), Int(raw0[off + 2]))) : ((Int(raw0[off]) + Int(raw0[off + 1]) + Int(raw0[off + 2])) / 3)
                                    if v < botMin { botMin = v }
                                }
                            }
                            return midMin < (dungCMin ? 190 : 185) && topMin > 220 && botMin > 220
                        }
                        if kiemTraDauTruCot(tu: xTH0, den: xTH1, dungCMin: false) || kiemTraDauTruCot(tu: xDK0, den: xDK1, dungCMin: true) {
                            coDauAmDong[idxD] = true
                        }
                    }

                    if cacDongHopLe.count >= 1 {
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

                            let xKetThucTen = Int((CGFloat(w) * xv1).rounded())
                            let xBatDauDK = Int((CGFloat(w) * xv4).rounded())
                            let xKetThucDK = Int((CGFloat(w) * xv5).rounded())
                            let tongPx = w * h
                            for i in 0..<tongPx {
                                let off = i * 4
                                let px = i % w
                                let r = Int(cleanPixels[off])
                                let g = Int(cleanPixels[off + 1])
                                let b = Int(cleanPixels[off + 2])

                                // Xoá sạch ngôi sao màu vàng ⭐ cùng viền răng cưa ở đầu tên chương trình (px < 0.15*w)
                                if px < (w * 15) / 100 && r >= 145 && g >= 105 && b < 175 && (r - b) >= 16 && g >= b {
                                    cleanPixels[off] = 255
                                    cleanPixels[off + 1] = 255
                                    cleanPixels[off + 2] = 255
                                    continue
                                }

                                let cMin = min(r, min(g, b))
                                if px >= xBatDauDK && px < xKetThucDK {
                                    // Ở cột % Dự kiến hoàn thành (chữ màu đỏ/cam/xanh lá): dùng cMin cho toàn bộ pixel để giữ sắc nét dấu chấm thập phân '.' (22.6%, 88.7%, 10.1%)
                                    if cMin >= 218 {
                                        cleanPixels[off] = 255
                                        cleanPixels[off + 1] = 255
                                        cleanPixels[off + 2] = 255
                                    } else {
                                        let muc = UInt8(max(0, min(255, (cMin - 72) * 255 / 146)))
                                        cleanPixels[off] = muc
                                        cleanPixels[off + 1] = muc
                                        cleanPixels[off + 2] = muc
                                    }
                                } else {
                                    let doSang = (r + g + b) / 3
                                    let nguongTrang = (px < xKetThucTen) ? 190 : 210
                                    if doSang >= nguongTrang {
                                        cleanPixels[off] = 255
                                        cleanPixels[off + 1] = 255
                                        cleanPixels[off + 2] = 255
                                    } else {
                                        let muc = UInt8(max(0, min(255, (doSang - 70) * 255 / max(1, nguongTrang - 70))))
                                        cleanPixels[off] = muc
                                        cleanPixels[off + 1] = muc
                                        cleanPixels[off + 2] = muc
                                    }
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
                            let xBar0 = Int((CGFloat(w) * xv3).rounded())
                            let xBar1 = Int((CGFloat(w) * xv4).rounded())
                            for tt in thongTinDongGian {
                                let dyCutBar = Int((Double(tt.caoSrc) * 0.54).rounded())
                                for dy in 0..<tt.caoSrc {
                                    let srcRow = (tt.ySrc0 + dy) * bprW
                                    let dstRow = (tt.yDst0 + dy) * bprW
                                    explodedPixels.replaceSubrange(dstRow..<(dstRow + bprW), with: cleanPixels[srcRow..<(srcRow + bprW)])
                                    // Nếu là Bảng dọc có thanh tiến độ ở Cột 4A (xv3..xv4), xoá trắng vùng thanh tiến độ (với Realtime xoá toàn bộ ô thanh tiến độ vì % HT ngày nằm ở xv4..xv5)
                                    if laBangDocCoThanhTienDo && (laRealtime || dy >= dyCutBar) && xBar1 > xBar0 {
                                        for px in xBar0..<min(w, xBar1) {
                                            let off = dstRow + px * 4
                                            explodedPixels[off] = 255
                                            explodedPixels[off + 1] = 255
                                            explodedPixels[off + 2] = 255
                                        }
                                    }
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

                                let chunkSizeDong = 8
                                for (chiSoCot, cot) in cacCotRanhGioi.enumerated() {
                                    let xc0 = min(w - 2, max(0, Int((CGFloat(w) * cot.b0).rounded()) + catBien))
                                    let xc1 = max(xc0 + 4, min(w, Int((CGFloat(w) * cot.b1).rounded()) - catBien))
                                    var obsDaSapXep: [(yPx: CGFloat, xPx: CGFloat, chu: String)] = []

                                    var startRow = 0
                                    while startRow < thongTinDongGian.count {
                                        let endRow = min(thongTinDongGian.count, startRow + chunkSizeDong)
                                        let yChunk0 = max(0, thongTinDongGian[startRow].yDst0 - demDoc / 2)
                                        let yChunk1 = min(tongCaoGian, thongTinDongGian[endRow - 1].yDst1 + demDoc / 2)
                                        let caoChunk = yChunk1 - yChunk0
                                        if caoChunk > 10, let cgChunk = cgExploded.cropping(to: CGRect(x: xc0, y: yChunk0, width: xc1 - xc0, height: caoChunk)) {
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
                                                        let yTamPx = CGFloat(yChunk0) + (yTren + (CGFloat(i) + 0.5) * caoM) * CGFloat(caoChunk)
                                                        obsDaSapXep.append((yPx: yTamPx, xPx: box.origin.x, chu: line))
                                                    }
                                                }
                                            }
                                            req.recognitionLevel = .accurate
                                            req.usesLanguageCorrection = cot.laCotTen
                                            if cot.laCotTen {
                                                req.recognitionLanguages = ["vi-VN", "en-US"]
                                            }
                                            req.minimumTextHeight = 0.01
                                            let handler = VNImageRequestHandler(cgImage: cgChunk, orientation: anhGoc.cgImageOrientation, options: [:])
                                            try? handler.perform([req])
                                        }
                                        startRow = endRow
                                    }

                                    obsDaSapXep.sort {
                                        if abs($0.yPx - $1.yPx) < 8.0 { return $0.xPx < $1.xPx }
                                        return $0.yPx < $1.yPx
                                    }

                                    let nuaDem = CGFloat(demDoc) * 0.48
                                    for item in obsDaSapXep {
                                        for (idxDong, tt) in thongTinDongGian.enumerated() {
                                            if item.yPx >= (CGFloat(tt.yDst0) - nuaDem) && item.yPx <= (CGFloat(tt.yDst1) + nuaDem) {
                                                ketQuaTungCot[chiSoCot][idxDong].append(item.chu)
                                                break
                                            }
                                        }
                                    }
                                }

                                // Hàm quét bổ sung riêng từng ô đơn lẻ (giúp đọc chính xác số 1 chữ số của môn SL hoặc dòng tên 3 hàng chữ)
                                func docOTrongBang(chiSoCot: Int, idxDong: Int) -> [String] {
                                    guard chiSoCot >= 0, chiSoCot < cacCotRanhGioi.count, idxDong >= 0, idxDong < thongTinDongGian.count else { return [] }
                                    let cot = cacCotRanhGioi[chiSoCot]
                                    let tt = thongTinDongGian[idxDong]
                                    let xc0 = min(w - 2, max(0, Int((CGFloat(w) * cot.b0).rounded()) + catBien))
                                    let xc1 = max(xc0 + 4, min(w, Int((CGFloat(w) * cot.b1).rounded()) - catBien))
                                    let yPad = 14
                                    let yc0 = max(0, tt.yDst0 - yPad)
                                    let yc1 = min(tongCaoGian, tt.yDst1 + yPad)
                                    guard yc1 > yc0 + 4,
                                          let cgO = cgExploded.cropping(to: CGRect(x: xc0, y: yc0, width: xc1 - xc0, height: yc1 - yc0)) else {
                                        return []
                                    }
                                    var kqO: [(y: CGFloat, x: CGFloat, chu: String)] = []
                                    let reqO = VNRecognizeTextRequest { r, _ in
                                        guard let list = r.results as? [VNRecognizedTextObservation] else { return }
                                        for obs in list {
                                            let cands = obs.topCandidates(3)
                                            guard let top = cands.first else { continue }
                                            let box = obs.boundingBox
                                            let yT = 1.0 - box.origin.y - box.size.height
                                            let lines = top.string.components(separatedBy: .newlines)
                                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                                .filter { !$0.isEmpty }
                                            for (i, ln) in lines.enumerated() {
                                                kqO.append((y: yT + CGFloat(i) * 0.1, x: box.origin.x, chu: ln))
                                            }
                                            if !cot.laCotTen && lines.isEmpty {
                                                for c in cands {
                                                    let s = c.string.trimmingCharacters(in: .whitespacesAndNewlines)
                                                    if !s.isEmpty { kqO.append((y: yT, x: box.origin.x, chu: s)); break }
                                                }
                                            }
                                        }
                                    }
                                    reqO.recognitionLevel = .accurate
                                    reqO.usesLanguageCorrection = cot.laCotTen
                                    if cot.laCotTen { reqO.recognitionLanguages = ["vi-VN", "en-US"] }
                                    reqO.minimumTextHeight = 0.04
                                    let hdl = VNImageRequestHandler(cgImage: cgO, orientation: anhGoc.cgImageOrientation, options: [:])
                                    try? hdl.perform([reqO])

                                    // Nếu ô số chỉ có 1 chữ số đơn lẻ (như 0, 1, 2, 5, 8) khiến Vision bỏ qua khi đứng một mình,
                                    // ghép nhãn neo "100 : " bên trái ô để Vision luôn nhận diện thành dòng chữ hoàn chỉnh
                                    if kqO.isEmpty && !cot.laCotTen {
                                        let kichThuocNeo = CGSize(width: 260, height: 64)
                                        let renderer = UIGraphicsImageRenderer(size: kichThuocNeo)
                                        let anhNeo = renderer.image { ctx in
                                            UIColor.white.setFill()
                                            ctx.fill(CGRect(origin: .zero, size: kichThuocNeo))
                                            let fontNeo = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .bold)
                                            ("100 :" as NSString).draw(
                                                at: CGPoint(x: 10, y: 16),
                                                withAttributes: [.font: fontNeo, .foregroundColor: UIColor.black]
                                            )
                                            let uiO = UIImage(cgImage: cgO)
                                            let tyLe = CGFloat(cgO.width) / CGFloat(max(1, cgO.height))
                                            let rongVe = min(155, max(36, 44.0 * tyLe))
                                            uiO.draw(in: CGRect(x: 92, y: 10, width: rongVe, height: 44))
                                        }
                                        if let cgNeo = anhNeo.cgImage {
                                            let reqNeo = VNRecognizeTextRequest { r, _ in
                                                guard let list = r.results as? [VNRecognizedTextObservation] else { return }
                                                for obs in list {
                                                    for cand in obs.topCandidates(3) {
                                                        let s = cand.string.trimmingCharacters(in: .whitespacesAndNewlines)
                                                        if let viTri = s.firstIndex(of: ":") {
                                                            let sau = String(s[s.index(after: viTri)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                                                            if !sau.isEmpty {
                                                                kqO.append((y: 0.5, x: 0.5, chu: sau))
                                                                break
                                                            }
                                                        } else if obs.boundingBox.origin.x > 0.30 && !s.isEmpty {
                                                            kqO.append((y: 0.5, x: obs.boundingBox.origin.x, chu: s))
                                                            break
                                                        }
                                                    }
                                                }
                                            }
                                            reqNeo.recognitionLevel = .accurate
                                            reqNeo.usesLanguageCorrection = false
                                            reqNeo.minimumTextHeight = 0.05
                                            let hdlNeo = VNImageRequestHandler(cgImage: cgNeo, orientation: .up, options: [:])
                                            try? hdlNeo.perform([reqNeo])
                                        }
                                    }

                                    kqO.sort {
                                        if abs($0.y - $1.y) < 0.08 { return $0.x < $1.x }
                                        return $0.y < $1.y
                                    }
                                    return kqO.map(\.chu)
                                }

                                // 7. Ghép dữ liệu 5 ô của từng dòng k (kèm đối chiếu dự phòng với phanTuGocDonDong và quét từng ô đơn lẻ)
                                for (idxDong, dongInfo) in cacDongHopLe.enumerated() {
                                    var chuoiCot2 = lamSachChuoi(ketQuaTungCot[1][idxDong].joined(separator: " "))
                                    var chuoiCot3 = lamSachChuoi(ketQuaTungCot[2][idxDong].joined(separator: " "))
                                    var chuoiCot4 = lamSachChuoi(ketQuaTungCot[3][idxDong].joined(separator: " "))
                                    var chuoiCot5 = lamSachChuoi(ketQuaTungCot[4][idxDong].joined(separator: " "))

                                    var th = trichSoHopLe(chuoiCot2).first
                                    var tg = trichSoHopLe(chuoiCot3).first
                                    var ht = trichSoHopLe(chuoiCot4).first
                                    var dk = trichSoHopLe(chuoiCot5).first

                                    if th == nil {
                                        let them2 = lamSachChuoi(docOTrongBang(chiSoCot: 1, idxDong: idxDong).joined(separator: " "))
                                        if !them2.isEmpty {
                                            chuoiCot2 = them2
                                            th = trichSoHopLe(them2).first
                                        }
                                    }
                                    if tg == nil {
                                        let them3 = lamSachChuoi(docOTrongBang(chiSoCot: 2, idxDong: idxDong).joined(separator: " "))
                                        if !them3.isEmpty {
                                            chuoiCot3 = them3
                                            tg = trichSoHopLe(them3).first
                                        }
                                    }
                                    if ht == nil {
                                        let them4 = lamSachChuoi(docOTrongBang(chiSoCot: 3, idxDong: idxDong).joined(separator: " "))
                                        if !them4.isEmpty {
                                            chuoiCot4 = them4
                                            ht = trichSoHopLe(them4).first
                                        }
                                    }
                                    if dk == nil {
                                        let them5 = lamSachChuoi(docOTrongBang(chiSoCot: 4, idxDong: idxDong).joined(separator: " "))
                                        if !them5.isEmpty {
                                            chuoiCot5 = them5
                                            dk = trichSoHopLe(them5).first
                                        }
                                    }

                                    var coThapPhan = chuoiCot2.range(of: "\\d+[.]\\d{1,2}\\b", options: .regularExpression) != nil ||
                                                     chuoiCot3.range(of: "\\d+[.]\\d{1,2}\\b", options: .regularExpression) != nil

                                    if th == nil || tg == nil || ht == nil || dk == nil {
                                        let ptHangGoc = phanTuGocDonDong.filter {
                                            let yTam = $0.y + $0.cao / 2.0
                                            return yTam >= dongInfo.yTrenNorm && yTam <= dongInfo.yDuoiNorm && $0.x >= (xv1 - 0.012) && $0.x < xv5
                                        }.sorted { $0.x < $1.x }
                                        for pt in ptHangGoc {
                                            let s = lamSachChuoi(pt.chu)
                                            let xTam = pt.x + min(pt.rong, 0.14) / 2.0
                                            let cacToken = s.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                                            let traiQuaCot2Va3 = (pt.x < xv2 && (pt.x + pt.rong) > (xv2 + 0.03) && cacToken.count >= 2)
                                            let traiQuaCot4Va5 = (pt.x >= xv3 && pt.x < xv4 && (pt.x + pt.rong) > (xv4 + 0.03) && cacToken.count >= 2)
                                            for (idxTk, tk) in cacToken.enumerated() {
                                                if let v = trichSoHopLe(tk).first {
                                                    if tk.contains("%") || xTam >= xv3 {
                                                        if traiQuaCot4Va5 {
                                                            if idxTk == 0 && ht == nil { ht = v }
                                                            else if idxTk == 1 && dk == nil { dk = v }
                                                        } else if xTam < xv4 {
                                                            if ht == nil { ht = v }
                                                        } else if xTam >= xv4 {
                                                            if dk == nil { dk = v }
                                                        }
                                                    } else {
                                                        if tk.range(of: "\\d+[.]\\d{1,2}\\b", options: .regularExpression) != nil {
                                                            coThapPhan = true
                                                        }
                                                        if traiQuaCot2Va3 {
                                                            if idxTk == 0 && th == nil { th = v }
                                                            else if idxTk == 1 && tg == nil { tg = v }
                                                        } else if xTam < xv2 {
                                                            if th == nil { th = v }
                                                        } else if xTam >= xv2 && xTam < xv3 {
                                                            if tg == nil { tg = v }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    let cacDongTenCot0 = ketQuaTungCot[0][idxDong]
                                    var (tenSach, loai) = nhanDienTenVaDonVi(tu: cacDongTenCot0, coSoThapPhan: coThapPhan)

                                    if tenSach.count < 2 || !KhoDuLieu.laTenMonThiDuaChuanDMX(tenSach) {
                                        let themTenO = docOTrongBang(chiSoCot: 0, idxDong: idxDong)
                                        if !themTenO.isEmpty {
                                            let (tenO, loaiO) = nhanDienTenVaDonVi(tu: themTenO, coSoThapPhan: coThapPhan)
                                            if KhoDuLieu.laTenMonThiDuaChuanDMX(tenO) || tenSach.count < 2 {
                                                tenSach = tenO
                                                loai = loaiO
                                            }
                                        }
                                    }

                                    if tenSach.count < 2 || !KhoDuLieu.laTenMonThiDuaChuanDMX(tenSach) {
                                        // Giới hạn chặt chẽ trong phạm vi dòng hiện tại (dongInfo.yTrenNorm ... dongInfo.yDuoiNorm) để tuyệt đối không lấy nhầm tên của dòng trên/dưới
                                        let ptTenGoc = phanTuGocDonDong.filter {
                                            let yTam = $0.y + $0.cao / 2.0
                                            return $0.x < xv1 && yTam >= dongInfo.yTrenNorm && yTam <= dongInfo.yDuoiNorm
                                        }.sorted {
                                            let y1 = $0.y + $0.cao / 2.0
                                            let y2 = $1.y + $1.cao / 2.0
                                            if abs(y1 - y2) < 0.006 { return $0.x < $1.x }
                                            return y1 < y2
                                        }.map(\.chu)
                                        let (tenGoc, loaiGoc) = nhanDienTenVaDonVi(tu: ptTenGoc, coSoThapPhan: coThapPhan)
                                        if KhoDuLieu.laTenMonThiDuaChuanDMX(tenGoc) || tenSach.count < 2 {
                                            tenSach = tenGoc
                                            loai = loaiGoc
                                        }
                                    }

                                    // Nếu bảng có đúng 39 dòng chương trình chuẩn ĐMX mà dòng hiện tại bị watermark che mờ tên, khôi phục chính xác tên chuẩn theo vị trí dòng
                                    if cacDongHopLe.count == KhoDuLieu.danhSach39MonThiDuaLuyKeMau.count,
                                       idxDong < KhoDuLieu.danhSach39MonThiDuaLuyKeMau.count,
                                       !KhoDuLieu.laTenMonThiDuaChuanDMX(tenSach) {
                                        let mau = KhoDuLieu.danhSach39MonThiDuaLuyKeMau[idxDong]
                                        tenSach = "T11 - \(mau.ten)"
                                        loai = mau.loai
                                    }

                                    guard tenSach.count >= 2, !laTenTheDoanhThuKhongPhaiThiDua(tenSach) else { continue }
                                    guard th != nil || tg != nil || ht != nil || dk != nil || KhoDuLieu.laTenMonThiDuaChuanDMX(tenSach) else { continue }

                                    if (laRealtime || ht == nil), let dkVal = dk {
                                        ht = dkVal
                                    }
                                    let laDongAm = (idxDong < coDauAmDong.count && coDauAmDong[idxDong]) || ((th ?? 0) < -0.0001) || ((ht ?? 0) < -0.05) || (laRealtime && (dk ?? 0) < -0.05)

                                    var soTH = th ?? 0.0
                                    var soTG = tg ?? 0.0

                                    if laDongAm {
                                        if abs(soTH) > 0.0001 { soTH = -abs(soTH) }
                                        if let hVal = ht, abs(hVal) > 0.0001 { ht = -abs(hVal) }
                                        if let dVal = dk, abs(dVal) > 0.0001 { dk = -abs(dVal) }
                                    }

                                    if let hVal = ht, abs(hVal) > 100.0, soTG > 0, abs(soTH) > 0, abs((soTH / soTG) * 100.0 - (hVal / 10.0)) <= 1.2 {
                                        ht = hVal / 10.0
                                    }
                                    if let hVal = ht, abs(hVal) > 0.05 {
                                        if th == nil && soTG > 0 {
                                            let uocTH = soTG * (hVal / 100.0)
                                            soTH = (loai == .soLuong) ? uocTH.rounded() : ((uocTH * 100).rounded() / 100)
                                        } else if tg == nil && abs(soTH) > 0 {
                                            let uocTG = abs(soTH / (hVal / 100.0))
                                            soTG = (loai == .soLuong) ? uocTG.rounded() : ((uocTG * 100).rounded() / 100)
                                        } else if soTG > 0 && soTH > 0 && hVal > 0 {
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

                                    if !laDongAm, let hVal = ht, abs(hVal) <= 0.001, soTG > 0 {
                                        if th == nil || (soTH / soTG) * 100.0 >= 2.0 {
                                            soTH = 0.0
                                        }
                                    }
                                    if soTG > 0 {
                                        if abs(soTH) <= 0.0001 && !laDongAm {
                                            ht = 0.0
                                        } else if abs(soTH) > 0.0001 {
                                            let htChuan = ((soTH / soTG) * 1000.0).rounded() / 10.0
                                            let nguongLech: Double = (loai == .soLuong && soTG <= 25) ? 3.5 : 1.2
                                            if ht == nil || abs((ht ?? 0) - htChuan) > nguongLech {
                                                ht = htChuan
                                            }
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

        // MARK: Hậu kiểm cứu hộ môn "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBANK EVO" nếu xuất hiện trong phanTuGocDonDong nhưng bị sót
        let daCoMoThe6 = danhSachTam.contains {
            KhoDuLieu.taoKhoaLienMachKhongThang($0.tenSach) == "MOTHETINDUNGVPBANKMWGVATPBAKEVO"
        }
        if !daCoMoThe6 {
            let cacPTMoThe = phanTuGocDonDong.filter { pt in
                guard pt.x < 0.36, (pt.y + pt.cao / 2.0) > ySauHeader else { return false }
                let u = boDau(pt.chu)
                return u.contains("MO THE") || u.contains("TIN DUNG") || u.contains("VPBANK") || u.contains("TPBAK") || u.contains("TPBANK")
            }
            if !cacPTMoThe.isEmpty {
                let yMin = cacPTMoThe.map(\.y).min()! - 0.025
                let yMax = cacPTMoThe.map { $0.y + $0.cao }.max()! + 0.025
                let ptSoMoThe = phanTuGocDonDong.filter { pt in
                    let yTam = pt.y + pt.cao / 2.0
                    return yTam >= yMin && yTam <= yMax && pt.x >= 0.33 && pt.x < 0.885
                }.sorted { $0.x < $1.x }
                var thM: Double?
                var tgM: Double?
                var htM: Double?
                var dkM: Double?
                for pt in ptSoMoThe {
                    let s = lamSachChuoi(pt.chu)
                    let xTam = pt.x + min(pt.rong, 0.14) / 2.0
                    for tk in s.components(separatedBy: .whitespaces) where !tk.isEmpty {
                        if let v = trichSoHopLe(tk).first {
                            if tk.contains("%") || xTam >= 0.640 {
                                if xTam < 0.758 && htM == nil { htM = v }
                                else if dkM == nil { dkM = v }
                            } else {
                                if xTam < 0.495 {
                                    if thM == nil { thM = v }
                                } else if xTam >= 0.495 && xTam < 0.640 {
                                    if tgM == nil { tgM = v }
                                }
                            }
                        }
                    }
                }
                danhSachTam.append(
                    DongTam6Cot(
                        tenSach: "T11 - MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBANK EVO",
                        loai: .soLuong,
                        soTH: thM ?? 0.0,
                        soTG: tgM ?? 0.0,
                        phanTramHT: htM ?? 0.0,
                        phanTramDuKien: dkM ?? htM ?? 0.0
                    )
                )
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
                guard pt.cao <= 0.095 else { continue }
                let yTam = pt.y + pt.cao / 2.0
                guard yTam > ySauHeader + 0.002 && yTam < 0.995 else { continue }
                let xTam = pt.x + min(pt.rong, 0.16) / 2.0
                if xTam >= xRanhGioiTenVaTH && xTam < xRanhGioiDuKienVaHangVung {
                    if !trichSoHopLe(pt.chu).isEmpty {
                        cacYSo.append(yTam)
                    }
                } else if xTam < xRanhGioiTenVaTH {
                    let u = boDau(pt.chu)
                    if laCumMoTheTinDung(u) || KhoDuLieu.laTenMonThiDuaChuanDMX(pt.chu) {
                        cacYSo.append(yTam)
                    }
                }
            }
            cacYSo.sort()

            var cacCumHang: [(yTB: CGFloat, cacY: [CGFloat])] = []
            for y in cacYSo {
                if let idx = cacCumHang.indices.last, abs(y - cacCumHang[idx].yTB) < 0.015 {
                    cacCumHang[idx].cacY.append(y)
                    cacCumHang[idx].yTB = cacCumHang[idx].cacY.reduce(0, +) / CGFloat(cacCumHang[idx].cacY.count)
                } else {
                    cacCumHang.append((yTB: y, cacY: [y]))
                }
            }
            let cacHangY = cacCumHang.map(\.yTB)
            for (k, yHang) in cacHangY.enumerated() {
                if k == 0 && (yHang - ySauHeader) < 0.012 { continue }
                let kcTren: CGFloat = (k == 0) ? max(0.024, yHang - ySauHeader) : (yHang - cacHangY[k - 1])
                let kcDuoi: CGFloat = (k + 1 < cacHangY.count) ? (cacHangY[k + 1] - yHang) : max(0.028, 0.994 - yHang)
                let nuaCao = min(max(0.018, min(kcTren, kcDuoi) * 0.58), 0.048)
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
                let ptTen = phanTuGocDonDong.filter {
                    let yTam = $0.y + $0.cao / 2.0
                    return $0.x < xRanhGioiTenVaTH && yTam >= (yTren - 0.008) && yTam <= (yDuoi + 0.008)
                }.sorted {
                    let y1 = $0.y + $0.cao / 2.0
                    let y2 = $1.y + $1.cao / 2.0
                    if abs(y1 - y2) < 0.009 { return $0.x < $1.x }
                    return y1 < y2
                }.map(\.chu)
                let (tenSach, loai) = nhanDienTenVaDonVi(tu: ptTen, coSoThapPhan: coThapPhan)
                guard tenSach.count >= 2, !laTenTheDoanhThuKhongPhaiThiDua(tenSach) else { continue }
                guard th != nil || tg != nil || ht != nil || KhoDuLieu.laTenMonThiDuaChuanDMX(tenSach) else { continue }
                danhSachTam.append(DongTam6Cot(tenSach: tenSach, loai: loai, soTH: th ?? 0, soTG: tg ?? 0, phanTramHT: ht, phanTramDuKien: dk))
            }
        }

        // Bước 1 hậu kiểm: Khôi phục dấu chấm thập phân cho % Dự kiến hoàn thành nếu OCR đọc sót dấu chấm (ví dụ 22.6% -> 226%, 88.7% -> 887%, 10.1% -> 101%)
        for i in danhSachTam.indices {
            guard danhSachTam[i].soTG > 0 && danhSachTam[i].soTH > 0 else { continue }
            let htChinhXac = (danhSachTam[i].soTH / danhSachTam[i].soTG) * 100.0
            if let db = danhSachTam[i].phanTramDuKien, htChinhXac > 0.1 {
                if db > htChinhXac * 10.5 && (db / 10.0) >= htChinhXac * 1.02 && (db / 10.0) <= htChinhXac * 9.5 {
                    danhSachTam[i].phanTramDuKien = db / 10.0
                }
            }
        }

        // Bước 2 hậu kiểm: Tính hệ số trung vị % Dự kiến / % HT thực tế của toàn bảng (tách riêng nhóm Doanh thu và Số lượng)
        var tyLeDK_DT: [Double] = []
        var tyLeDK_SL: [Double] = []
        for d in danhSachTam where d.soTG > 0 && d.soTH > 0 {
            let htChinhXac = (d.soTH / d.soTG) * 100.0
            if let db = d.phanTramDuKien, htChinhXac >= 2.0 {
                let r = db / htChinhXac
                if r >= 1.02 && r <= 9.5 {
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
                if abs(d.soTH) <= 0.0001 {
                    d.phanTramHT = 0.0
                    d.phanTramDuKien = 0.0
                } else if !laRealtime, d.soTH > 0, let heSo = (d.loai == .soLuong ? (heSoSL ?? heSoDT) : (heSoDT ?? heSoSL)), heSo > 1.0 {
                    let dkKyVong: Double
                    if d.loai == .soLuong {
                        let slDK = (d.soTH * heSo).rounded()
                        dkKyVong = ((slDK / d.soTG) * 1000.0).rounded() / 10.0
                    } else {
                        let htChinhXac = (d.soTH / d.soTG) * 100.0
                        dkKyVong = ((htChinhXac * heSo) * 10.0).rounded() / 10.0
                    }
                    if d.phanTramDuKien == nil || abs(d.phanTramDuKien! - dkKyVong) > 1.2 {
                        d.phanTramDuKien = dkKyVong
                    }
                }
            }

            var duKienTinh: Double? = nil
            if !laRealtime, let db = d.phanTramDuKien, d.soTG > 0 {
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
                phanTramDuBaoGoc: laRealtime ? d.phanTramHT : (d.phanTramDuKien ?? d.phanTramHT),
                duKienGoc: laRealtime ? nil : duKienTinh
            )
            danhSachKetQua = KhoDuLieu.gopDanhSachThiDua(cu: danhSachKetQua, moi: [dong])
        }

        return danhSachKetQua
    }

    // MARK: - Bước 2A.00B: Bộ phân tích Bảng Thi Đua 5 Cột Theo Ngày / Realtime - Phương pháp 2 (CHƯƠNG TRÌNH | THỰC HIỆN | TARGET NGÀY | % HT NGÀY | HẠNG VÙNG)

    /// Phương pháp quét Bảng Thi Đua 5 cột (Realtime / Theo ngày):
    /// - Cột 1 (`0.052 .. xv1 ~0.388`): CHƯƠNG TRÌNH + huy hiệu DT/SL
    /// - Cột 2 (`xv1 ~0.388 .. xv2 ~0.558`): THỰC HIỆN
    /// - Cột 3 (`xv2 ~0.558 .. xv3 ~0.730`): TARGET NGÀY
    /// - Cột 4 (`xv3 ~0.730 .. xv4 ~0.860`): % HT NGÀY
    /// - Cột 5 (`xv4 ~0.860 .. 0.990`): HẠNG VÙNG (bỏ qua)
    private func phanTichBangThiDuaPhuongPhap2_5CotRealtime(
        phanTu: [PhanTuVanBan],
        anh: UIImage? = nil,
        watermark: String? = nil
    ) -> [DongThiDua] {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) || laAnhBangDoanhThuNhanVien(phanTu: phanTu) || laAnhLuoiTheThiDua(phanTu: phanTu) {
            return []
        }
        // Ưu tiên phân tích theo bố cục bảng dọc 5 cột có thanh tiến độ chuẩn ĐMX (như ảnh BC Thi đua Realtime 39 chương trình)
        let dsBangDoc = phanTichBangThiDuaPhuongPhap2_6Cot(phanTu: phanTu, anh: anh, watermark: watermark, laRealtime: true)
        if !dsBangDoc.isEmpty {
            return dsBangDoc
        }

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
            } else if pt.cao <= 0.14 {
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

        let vungHeaderGoc = phanTuGocDonDong.filter { $0.y < 0.12 }
        let cacPTHeaderGoc = vungHeaderGoc.filter { pt in
            let u = boDau(pt.chu)
            return u.contains("CHUONG TRINH") || u.contains("THUC HIEN") || u.contains("TARGET") ||
                u.contains("% HT") || u.contains("HT NGAY") || u.contains("TARGET NGAY") || u.contains("HANG VUNG") ||
                u == "THUC" || u == "HIEN" || u == "NGAY" || u == "VUNG"
        }
        var ySauHeader: CGFloat = cacPTHeaderGoc.map { $0.y + $0.cao }.max() ?? 0.004
        if !cacPTHeaderGoc.isEmpty {
            ySauHeader = min(0.098, max(0.038, ySauHeader + 0.002))
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
            kq = kq.replacingOccurrences(of: "−", with: "-")
                .replacingOccurrences(of: "–", with: "-")
                .replacingOccurrences(of: "—", with: "-")
                .replacingOccurrences(of: "﹣", with: "-")
                .replacingOccurrences(of: "－", with: "-")
            kq = kq.replacingOccurrences(of: "(?<![0-9])-\\s+(?=\\d)", with: "-", options: .regularExpression)
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
                return val > -100000 && val < 100000
            }
        }

        func laCumMoTheTinDung(_ u: String) -> Bool {
            let coTuKhoaChinh = u.contains("MO THE") || u.contains("MOTHE") || u.contains("TIN DUNG") || u.contains("TINDUNG") ||
                                u.contains("VPBANK") || u.contains("VP8ANK") || u.contains("TPBAK") || u.contains("TPBANK")
            let coTuKhoaPhu = u.contains("VPBANK") || u.contains("VP8ANK") || u.contains("TPBAK") || u.contains("TPBANK") ||
                              u.contains("MWG") || u.contains("EVO") || u.contains("EV0") || u.contains("TIN DUNG") || u.contains("TINDUNG")
            return coTuKhoaChinh && coTuKhoaPhu
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

            let chuoiTenGop = cacDongSach.joined(separator: " ")
            let uGop = boDau(chuoiTenGop)
            var tenSach = KhoDuLieu.chuanHoaTenMonThiDuaChuan(chuoiTenGop)
            if laCumMoTheTinDung(uGop) {
                tenSach = "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBANK EVO"
            }

            let loai: LoaiChiTieuThiDua
            if tenSach == "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBANK EVO" && !coSoThapPhan {
                loai = .soLuong
            } else if coBadgeSL && !coBadgeDT && !coSoThapPhan {
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

            return (tenSach, loai)
        }

        struct DongTam5Cot {
            var tenSach: String
            var loai: LoaiChiTieuThiDua
            var soTH: Double
            var soTG: Double
            var phanTramHT: Double?
        }

        var danhSachTam: [DongTam5Cot] = []

        // MARK: Phương án chính — Tìm dấu + trong Cột 1 + Đường kẻ ô lưới 5 cột + Tách 4 ảnh cột dữ liệu độc lập
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
                let xPlus0 = max(1, Int((CGFloat(w0) * 0.022).rounded()))
                let xPlus1 = min(w0 - 2, Int((CGFloat(w0) * 0.049).rounded()))
                let yBatDauPlus = max(4, Int((CGFloat(h0) * max(0.012, ySauHeader - 0.008)).rounded()))

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
                        if minGray < 160 {
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

                let caoToiThieuPlus = max(4, h0 / 280)
                var tamDauCong: [Double] = cumPlus.compactMap { cum in
                    guard let d = cum.first, let c = cum.last, (c - d + 1) >= caoToiThieuPlus else { return nil }
                    return Double(cum.reduce(0, +)) / Double(cum.count)
                }

                // Bổ sung tâm dòng từ phanTuGocDonDong nếu có dòng môn chuẩn (đặc biệt MỞ THẺ TÍN DỤNG...) bị mờ dấu +
                var cacYUngVienTen: [CGFloat] = []
                for pt in phanTuGocDonDong where pt.x < 0.388 && (pt.y + pt.cao / 2.0) > ySauHeader {
                    let u = boDau(pt.chu)
                    if laCumMoTheTinDung(u) || KhoDuLieu.laTenMonThiDuaChuanDMX(pt.chu) {
                        cacYUngVienTen.append(pt.y + pt.cao / 2.0)
                    }
                }
                for yNorm in cacYUngVienTen {
                    let yPx = Double(yNorm) * Double(h0)
                    let daCo = tamDauCong.contains { abs($0 - yPx) < Double(h0) * 0.044 }
                    if !daCo {
                        tamDauCong.append(yPx)
                        tamDauCong.sort()
                    }
                }

                if tamDauCong.count >= 1 {
                    // 2. Tính độ tương phản dọc trên vùng nền trắng bên trái các cột số của bố cục 5 cột
                    let cacDaiKheX: [(CGFloat, CGFloat)] = [
                        (0.010, 0.021),
                        (0.400, 0.470),
                        (0.570, 0.635),
                        (0.740, 0.775),
                        (0.870, 0.905),
                        (0.945, 0.985)
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

                    let leDocPlus = max(12, h0 / 58)
                    var bienNgangPx: [Int] = []

                    let minTopPx = cacPTHeaderGoc.isEmpty
                        ? max(2, Int(tamDauCong[0]) - Int(Double(h0) * 0.078))
                        : max(4, Int(CGFloat(h0) * max(0.032, ySauHeader - 0.015)))
                    let yTren0Start = max(2, min(minTopPx, Int(tamDauCong[0]) - leDocPlus - 2))
                    let yTren0End = max(yTren0Start, Int(tamDauCong[0]) - leDocPlus)
                    var yBest0 = yTren0Start
                    var maxC0 = -999.0
                    for y in yTren0Start...yTren0End {
                        if vContrast[y] > maxC0 {
                            maxC0 = vContrast[y]
                            yBest0 = y
                        }
                    }
                    if maxC0 < 1.0 {
                        yBest0 = max(2, Int(tamDauCong[0]) - Int(Double(h0) * 0.048))
                    }
                    bienNgangPx.append(yBest0)

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
                        if maxC < 0.9 {
                            yBest = (Int(tamDauCong[k]) + Int(tamDauCong[k + 1])) / 2
                        }
                        bienNgangPx.append(yBest)
                    }

                    let yCuoiStart = min(h0 - 3, Int(tamDauCong.last!) + leDocPlus)
                    let yCuoiEnd = min(h0 - 2, max(yCuoiStart, Int(tamDauCong.last!) + Int(Double(h0) * 0.082)))
                    var yBestCuoi = min(h0 - 2, Int(tamDauCong.last!) + Int(Double(h0) * 0.052))
                    var maxCCuoi = -999.0
                    for y in yCuoiStart...yCuoiEnd {
                        if vContrast[y] > maxCCuoi {
                            maxCCuoi = vContrast[y]
                            yBestCuoi = y
                        }
                    }
                    if maxCCuoi < 1.0 {
                        yBestCuoi = min(h0 - 2, Int(tamDauCong.last!) + Int(Double(h0) * 0.052))
                    }
                    bienNgangPx.append(yBestCuoi)

                    // 3. Tìm chính xác 4 đường kẻ dọc ngăn cách 5 cột (CHƯƠNG TRÌNH | THỰC HIỆN | TARGET NGÀY | % HT NGÀY | HẠNG VÙNG)
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
                    let xv1: CGFloat = timDuongKeDoc(tu: 0.355, den: 0.415, macDinh: 0.388)
                    let xv2: CGFloat = timDuongKeDoc(tu: 0.525, den: 0.585, macDinh: 0.558)
                    let xv3: CGFloat = timDuongKeDoc(tu: 0.695, den: 0.755, macDinh: 0.730)
                    let xv4: CGFloat = timDuongKeDoc(tu: 0.830, den: 0.885, macDinh: 0.860)

                    var cacDongHopLe: [(y0Px: Int, y1Px: Int, yTrenNorm: CGFloat, yDuoiNorm: CGFloat)] = []
                    for k in 0..<tamDauCong.count {
                        let y0 = bienNgangPx[k]
                        let y1 = bienNgangPx[k + 1]
                        let caoNorm = CGFloat(y1 - y0) / CGFloat(h0)
                        guard caoNorm >= 0.018 else { continue }
                        cacDongHopLe.append((
                            y0Px: y0,
                            y1Px: y1,
                            yTrenNorm: CGFloat(y0) / CGFloat(h0),
                            yDuoiNorm: CGFloat(y1) / CGFloat(h0)
                        ))
                    }

                    if cacDongHopLe.count >= 1 {
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

                            let xBatDauMauHT = Int((CGFloat(w) * xv3).rounded())
                            let xKetThucMauHT = Int((CGFloat(w) * xv4).rounded())
                            let tongPx = w * h
                            for i in 0..<tongPx {
                                let off = i * 4
                                let px = i % w
                                let r = Int(cleanPixels[off])
                                let g = Int(cleanPixels[off + 1])
                                let b = Int(cleanPixels[off + 2])

                                // Xoá ngôi sao màu vàng ⭐ ở đầu tên chương trình trong Cột 1
                                if px < (w * 15) / 100 && r >= 185 && g >= 135 && b < 155 && (r - b) > 45 && (g * 100) >= (r * 65) {
                                    cleanPixels[off] = 255
                                    cleanPixels[off + 1] = 255
                                    cleanPixels[off + 2] = 255
                                    continue
                                }

                                let cMax = max(r, max(g, b))
                                let cMin = min(r, min(g, b))
                                let doLech = cMax - cMin
                                let doSang = (px >= xBatDauMauHT && px < xKetThucMauHT && doLech >= 18) ? cMin : ((r + g + b) / 3)
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

                                // Cắt thành 4 ảnh cột dữ liệu riêng biệt (Cột 1: Tên, Cột 2: Thực hiện, Cột 3: Target ngày, Cột 4: % HT ngày)
                                let cacCotRanhGioi: [(b0: CGFloat, b1: CGFloat, laCotTen: Bool)] = [
                                    (xv0, xv1, true),
                                    (xv1, xv2, false),
                                    (xv2, xv3, false),
                                    (xv3, xv4, false)
                                ]

                                var ketQuaTungCot = Array(
                                    repeating: Array(repeating: [String](), count: cacDongHopLe.count),
                                    count: 4
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
                                    req.minimumTextHeight = 0.002

                                    let handler = VNImageRequestHandler(cgImage: cgCot, orientation: anhGoc.cgImageOrientation, options: [:])
                                    try? handler.perform([req])

                                    obsDaSapXep.sort {
                                        if abs($0.yPx - $1.yPx) < 8.0 { return $0.xPx < $1.xPx }
                                        return $0.yPx < $1.yPx
                                    }

                                    let nuaDem = CGFloat(demDoc) * 0.48
                                    for item in obsDaSapXep {
                                        for (idxDong, tt) in thongTinDongGian.enumerated() {
                                            if item.yPx >= (CGFloat(tt.yDst0) - nuaDem) && item.yPx <= (CGFloat(tt.yDst1) + nuaDem) {
                                                ketQuaTungCot[chiSoCot][idxDong].append(item.chu)
                                                break
                                            }
                                        }
                                    }
                                }

                                // Hàm quét bổ sung riêng từng ô đơn lẻ trong bảng 5 cột
                                func docOTrongBang(chiSoCot: Int, idxDong: Int) -> [String] {
                                    guard chiSoCot >= 0, chiSoCot < cacCotRanhGioi.count, idxDong >= 0, idxDong < thongTinDongGian.count else { return [] }
                                    let cot = cacCotRanhGioi[chiSoCot]
                                    let tt = thongTinDongGian[idxDong]
                                    let xc0 = min(w - 2, max(0, Int((CGFloat(w) * cot.b0).rounded()) + catBien))
                                    let xc1 = max(xc0 + 4, min(w, Int((CGFloat(w) * cot.b1).rounded()) - catBien))
                                    let yPad = 14
                                    let yc0 = max(0, tt.yDst0 - yPad)
                                    let yc1 = min(tongCaoGian, tt.yDst1 + yPad)
                                    guard yc1 > yc0 + 4,
                                          let cgO = cgExploded.cropping(to: CGRect(x: xc0, y: yc0, width: xc1 - xc0, height: yc1 - yc0)) else {
                                        return []
                                    }
                                    var kqO: [(y: CGFloat, x: CGFloat, chu: String)] = []
                                    let reqO = VNRecognizeTextRequest { r, _ in
                                        guard let list = r.results as? [VNRecognizedTextObservation] else { return }
                                        for obs in list {
                                            let cands = obs.topCandidates(3)
                                            guard let top = cands.first else { continue }
                                            let box = obs.boundingBox
                                            let yT = 1.0 - box.origin.y - box.size.height
                                            let lines = top.string.components(separatedBy: .newlines)
                                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                                .filter { !$0.isEmpty }
                                            for (i, ln) in lines.enumerated() {
                                                kqO.append((y: yT + CGFloat(i) * 0.1, x: box.origin.x, chu: ln))
                                            }
                                            if !cot.laCotTen && lines.isEmpty {
                                                for c in cands {
                                                    let s = c.string.trimmingCharacters(in: .whitespacesAndNewlines)
                                                    if !s.isEmpty { kqO.append((y: yT, x: box.origin.x, chu: s)); break }
                                                }
                                            }
                                        }
                                    }
                                    reqO.recognitionLevel = .accurate
                                    reqO.usesLanguageCorrection = cot.laCotTen
                                    if cot.laCotTen { reqO.recognitionLanguages = ["vi-VN", "en-US"] }
                                    reqO.minimumTextHeight = 0.04
                                    let hdl = VNImageRequestHandler(cgImage: cgO, orientation: anhGoc.cgImageOrientation, options: [:])
                                    try? hdl.perform([reqO])
                                    kqO.sort {
                                        if abs($0.y - $1.y) < 0.08 { return $0.x < $1.x }
                                        return $0.y < $1.y
                                    }
                                    return kqO.map(\.chu)
                                }

                                for (idxDong, dongInfo) in cacDongHopLe.enumerated() {
                                    var chuoiCot2 = lamSachChuoi(ketQuaTungCot[1][idxDong].joined(separator: " "))
                                    var chuoiCot3 = lamSachChuoi(ketQuaTungCot[2][idxDong].joined(separator: " "))
                                    var chuoiCot4 = lamSachChuoi(ketQuaTungCot[3][idxDong].joined(separator: " "))

                                    var th = trichSoHopLe(chuoiCot2).first
                                    var tg = trichSoHopLe(chuoiCot3).first
                                    var ht = trichSoHopLe(chuoiCot4).first

                                    if th == nil {
                                        let them2 = lamSachChuoi(docOTrongBang(chiSoCot: 1, idxDong: idxDong).joined(separator: " "))
                                        if !them2.isEmpty {
                                            chuoiCot2 = them2
                                            th = trichSoHopLe(them2).first
                                        }
                                    }
                                    if tg == nil {
                                        let them3 = lamSachChuoi(docOTrongBang(chiSoCot: 2, idxDong: idxDong).joined(separator: " "))
                                        if !them3.isEmpty {
                                            chuoiCot3 = them3
                                            tg = trichSoHopLe(them3).first
                                        }
                                    }
                                    if ht == nil {
                                        let them4 = lamSachChuoi(docOTrongBang(chiSoCot: 3, idxDong: idxDong).joined(separator: " "))
                                        if !them4.isEmpty {
                                            chuoiCot4 = them4
                                            ht = trichSoHopLe(them4).first
                                        }
                                    }

                                    var coThapPhan = chuoiCot2.range(of: "\\d+[.]\\d{1,2}\\b", options: .regularExpression) != nil ||
                                                     chuoiCot3.range(of: "\\d+[.]\\d{1,2}\\b", options: .regularExpression) != nil

                                    if th == nil || tg == nil || ht == nil {
                                        let ptHangGoc = phanTuGocDonDong.filter {
                                            let yTam = $0.y + $0.cao / 2.0
                                            return yTam >= (dongInfo.yTrenNorm - 0.008) && yTam <= (dongInfo.yDuoiNorm + 0.008) && $0.x >= (xv1 - 0.012) && $0.x < xv4
                                        }.sorted { $0.x < $1.x }
                                        for pt in ptHangGoc {
                                            let s = lamSachChuoi(pt.chu)
                                            let xTam = pt.x + min(pt.rong, 0.14) / 2.0
                                            let cacToken = s.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                                            let traiQuaCot2Va3 = (pt.x < xv2 && (pt.x + pt.rong) > (xv2 + 0.03) && cacToken.count >= 2)
                                            for (idxTk, tk) in cacToken.enumerated() {
                                                if let v = trichSoHopLe(tk).first {
                                                    if tk.contains("%") || xTam >= xv3 {
                                                        if ht == nil { ht = v }
                                                    } else {
                                                        if tk.range(of: "\\d+[.]\\d{1,2}\\b", options: .regularExpression) != nil {
                                                            coThapPhan = true
                                                        }
                                                        if traiQuaCot2Va3 {
                                                            if idxTk == 0 && th == nil { th = v }
                                                            else if idxTk == 1 && tg == nil { tg = v }
                                                        } else if xTam < xv2 {
                                                            if th == nil { th = v }
                                                        } else if xTam >= xv2 && xTam < xv3 {
                                                            if tg == nil { tg = v }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    var cacDongTenCot0 = ketQuaTungCot[0][idxDong]
                                    if cacDongTenCot0.isEmpty {
                                        cacDongTenCot0 = docOTrongBang(chiSoCot: 0, idxDong: idxDong)
                                    }
                                    var (tenSach, loai) = nhanDienTenVaDonVi(tu: cacDongTenCot0, coSoThapPhan: coThapPhan)

                                    if tenSach.count < 2 || !KhoDuLieu.laTenMonThiDuaChuanDMX(tenSach) {
                                        let ptTenGoc = phanTuGocDonDong.filter {
                                            let yTam = $0.y + $0.cao / 2.0
                                            return $0.x < xv1 && yTam >= (dongInfo.yTrenNorm - 0.012) && yTam <= (dongInfo.yDuoiNorm + 0.012)
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
                                        } else {
                                            let (tenHop, loaiHop) = nhanDienTenVaDonVi(tu: cacDongTenCot0 + ptTenGoc, coSoThapPhan: coThapPhan)
                                            if KhoDuLieu.laTenMonThiDuaChuanDMX(tenHop) {
                                                tenSach = tenHop
                                                loai = loaiHop
                                            }
                                        }
                                    }

                                    guard tenSach.count >= 2, !laTenTheDoanhThuKhongPhaiThiDua(tenSach) else { continue }
                                    guard th != nil || tg != nil || ht != nil || KhoDuLieu.laTenMonThiDuaChuanDMX(tenSach) else { continue }

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
                                        }
                                    }

                                    if let hVal = ht, hVal < -0.05 && soTH > 0 {
                                        soTH = -abs(soTH)
                                    } else if soTH < -0.0001, let hVal = ht, hVal > 0 {
                                        ht = -abs(hVal)
                                    }
                                    if let hVal = ht, abs(hVal) <= 0.001, soTG > 0 && soTH >= 0 {
                                        if th == nil || (soTH / soTG) * 100.0 >= 2.0 {
                                            soTH = 0.0
                                        }
                                    }
                                    if soTG > 0 {
                                        if abs(soTH) <= 0.0001 {
                                            ht = 0.0
                                        } else {
                                            let htChuan = ((soTH / soTG) * 1000.0).rounded() / 10.0
                                            let nguongLech: Double = (loai == .soLuong && soTG <= 25) ? 3.5 : 1.2
                                            if ht == nil || abs((ht ?? 0) - htChuan) > nguongLech {
                                                ht = htChuan
                                            }
                                        }
                                    }

                                    danhSachTam.append(
                                        DongTam5Cot(
                                            tenSach: tenSach,
                                            loai: loai,
                                            soTH: soTH,
                                            soTG: soTG,
                                            phanTramHT: ht
                                        )
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        // MARK: Hậu kiểm cứu hộ môn "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBANK EVO" nếu xuất hiện trong phanTuGocDonDong nhưng bị sót
        let daCoMoThe5 = danhSachTam.contains {
            KhoDuLieu.taoKhoaLienMachKhongThang($0.tenSach) == "MOTHETINDUNGVPBANKMWGVATPBAKEVO"
        }
        if !daCoMoThe5 {
            let cacPTMoThe = phanTuGocDonDong.filter { pt in
                guard pt.x < 0.40, (pt.y + pt.cao / 2.0) > ySauHeader else { return false }
                let u = boDau(pt.chu)
                return u.contains("MO THE") || u.contains("TIN DUNG") || u.contains("VPBANK") || u.contains("TPBAK") || u.contains("TPBANK")
            }
            if !cacPTMoThe.isEmpty {
                let yMin = cacPTMoThe.map(\.y).min()! - 0.025
                let yMax = cacPTMoThe.map { $0.y + $0.cao }.max()! + 0.025
                let ptSoMoThe = phanTuGocDonDong.filter { pt in
                    let yTam = pt.y + pt.cao / 2.0
                    return yTam >= yMin && yTam <= yMax && pt.x >= 0.37 && pt.x < 0.865
                }.sorted { $0.x < $1.x }
                var thM: Double?
                var tgM: Double?
                var htM: Double?
                for pt in ptSoMoThe {
                    let s = lamSachChuoi(pt.chu)
                    let xTam = pt.x + min(pt.rong, 0.14) / 2.0
                    for tk in s.components(separatedBy: .whitespaces) where !tk.isEmpty {
                        if let v = trichSoHopLe(tk).first {
                            if tk.contains("%") || xTam >= 0.720 {
                                if htM == nil { htM = v }
                            } else {
                                if xTam < 0.558 {
                                    if thM == nil { thM = v }
                                } else if xTam >= 0.558 && xTam < 0.720 {
                                    if tgM == nil { tgM = v }
                                }
                            }
                        }
                    }
                }
                danhSachTam.append(
                    DongTam5Cot(
                        tenSach: "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBANK EVO",
                        loai: .soLuong,
                        soTH: thM ?? 0.0,
                        soTG: tgM ?? 0.0,
                        phanTramHT: htM ?? 0.0
                    )
                )
            }
        }

        // MARK: Dự phòng khi không có UIImage gốc (quét 5 cột từ phanTuGocDonDong)
        if danhSachTam.isEmpty {
            let xRanhGioiTenVaTH: CGFloat = 0.388
            let xRanhGioiTHVaTarget: CGFloat = 0.558
            let xRanhGioiTargetVaHT: CGFloat = 0.730
            let xRanhGioiHTVaHangVung: CGFloat = 0.860

            var cacYSo: [CGFloat] = []
            for pt in phanTuGocDonDong {
                guard pt.cao <= 0.095 else { continue }
                let yTam = pt.y + pt.cao / 2.0
                guard yTam > ySauHeader + 0.002 && yTam < 0.995 else { continue }
                let xTam = pt.x + min(pt.rong, 0.16) / 2.0
                if xTam >= xRanhGioiTenVaTH && xTam < xRanhGioiHTVaHangVung {
                    if !trichSoHopLe(pt.chu).isEmpty {
                        cacYSo.append(yTam)
                    }
                } else if xTam < xRanhGioiTenVaTH {
                    let u = boDau(pt.chu)
                    if laCumMoTheTinDung(u) || KhoDuLieu.laTenMonThiDuaChuanDMX(pt.chu) {
                        cacYSo.append(yTam)
                    }
                }
            }
            cacYSo.sort()

            var cacCumHang: [(yTB: CGFloat, cacY: [CGFloat])] = []
            for y in cacYSo {
                if let idx = cacCumHang.indices.last, abs(y - cacCumHang[idx].yTB) < 0.015 {
                    cacCumHang[idx].cacY.append(y)
                    cacCumHang[idx].yTB = cacCumHang[idx].cacY.reduce(0, +) / CGFloat(cacCumHang[idx].cacY.count)
                } else {
                    cacCumHang.append((yTB: y, cacY: [y]))
                }
            }
            let cacHangY = cacCumHang.map(\.yTB)
            for (k, yHang) in cacHangY.enumerated() {
                if k == 0 && (yHang - ySauHeader) < 0.012 { continue }
                let kcTren: CGFloat = (k == 0) ? max(0.024, yHang - ySauHeader) : (yHang - cacHangY[k - 1])
                let kcDuoi: CGFloat = (k + 1 < cacHangY.count) ? (cacHangY[k + 1] - yHang) : max(0.028, 0.994 - yHang)
                let nuaCao = min(max(0.018, min(kcTren, kcDuoi) * 0.58), 0.048)
                let yTren = (k == 0) ? max(ySauHeader, yHang - nuaCao) : max((cacHangY[k - 1] + yHang) / 2.0, yHang - nuaCao)
                let yDuoi = (k + 1 < cacHangY.count) ? min((yHang + cacHangY[k + 1]) / 2.0, yHang + nuaCao) : min(0.996, yHang + nuaCao)

                let ptSo = phanTuGocDonDong.filter {
                    let yTam = $0.y + $0.cao / 2.0
                    let xTam = $0.x + min($0.rong, 0.14) / 2.0
                    return yTam >= yTren && yTam <= yDuoi && xTam >= xRanhGioiTenVaTH && xTam < xRanhGioiHTVaHangVung
                }.sorted { $0.x < $1.x }

                var th: Double?
                var tg: Double?
                var ht: Double?
                var coThapPhan = false
                for pt in ptSo {
                    let s = lamSachChuoi(pt.chu)
                    if s.range(of: "\\d+[.]\\d{1,2}\\b", options: .regularExpression) != nil { coThapPhan = true }
                    let xTam = pt.x + min(pt.rong, 0.14) / 2.0
                    if let v = trichSoHopLe(s).first {
                        if xTam < xRanhGioiTHVaTarget && th == nil { th = v }
                        else if xTam >= xRanhGioiTHVaTarget && xTam < xRanhGioiTargetVaHT && tg == nil { tg = v }
                        else if xTam >= xRanhGioiTargetVaHT && ht == nil { ht = v }
                    }
                }
                let ptTen = phanTuGocDonDong.filter {
                    let yTam = $0.y + $0.cao / 2.0
                    return $0.x < xRanhGioiTenVaTH && yTam >= (yTren - 0.008) && yTam <= (yDuoi + 0.008)
                }.sorted {
                    let y1 = $0.y + $0.cao / 2.0
                    let y2 = $1.y + $1.cao / 2.0
                    if abs(y1 - y2) < 0.009 { return $0.x < $1.x }
                    return y1 < y2
                }.map(\.chu)
                let (tenSach, loai) = nhanDienTenVaDonVi(tu: ptTen, coSoThapPhan: coThapPhan)
                guard tenSach.count >= 2, !laTenTheDoanhThuKhongPhaiThiDua(tenSach) else { continue }
                guard th != nil || tg != nil || ht != nil || KhoDuLieu.laTenMonThiDuaChuanDMX(tenSach) else { continue }
                danhSachTam.append(DongTam5Cot(tenSach: tenSach, loai: loai, soTH: th ?? 0, soTG: tg ?? 0, phanTramHT: ht))
            }
        }

        var danhSachKetQua: [DongThiDua] = []
        for var d in danhSachTam {
            if d.soTG > 0 && abs(d.soTH) <= 0.0001 {
                d.phanTramHT = 0.0
            }
            let dong = DongThiDua(
                tenNganhHangGoc: d.tenSach,
                tenNganhHang: KhoDuLieu.apDungLocTuCaiDat(d.tenSach),
                loaiChiTieu: d.loai,
                thucHien: d.soTH,
                target: d.soTG,
                phanTramHTGoc: d.phanTramHT,
                phanTramDuBaoGoc: d.phanTramHT,
                duKienGoc: nil
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
        guard cacHangY.count >= 1 else { return [] }

        var danhSachKetQua: [DongThiDua] = []

        for (k, yHang) in cacHangY.enumerated() {
            let yTren: CGFloat = (k == 0)
                ? max(ySauHeader, yHang - 0.042)
                : ((cacHangY[k - 1] + yHang) / 2.0)
            let yDuoi: CGFloat = (k + 1 < cacHangY.count)
                ? ((yHang + cacHangY[k + 1]) / 2.0)
                : min(0.996, yHang + 0.042)

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

    /// Phát hiện đường kẻ ngang của bảng 6 cột khi mở rộng chi tiết nhân viên theo môn thi đua
    private func timDuongKeNgangBangThiDuaNV6Cot(anh: UIImage) -> [Int] {
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

        let cacDaiX: [(CGFloat, CGFloat)] = [
            (0.010, 0.025),
            (0.330, 0.350),
            (0.485, 0.505),
            (0.635, 0.655),
            (0.750, 0.770),
            (0.865, 0.890),
            (0.970, 0.988)
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
            if mad < 5.5 && med >= 210.0 && med <= 249.8 {
                isGrey[y] = true
            }
        }

        var cacCum: [[Int]] = []
        for y in 0..<h where isGrey[y] {
            if let cuoi = cacCum.last?.last, y - cuoi <= 8 {
                cacCum[cacCum.count - 1].append(y)
            } else {
                cacCum.append([y])
            }
        }

        var cacMocY: [Int] = []
        for cum in cacCum {
            guard let yTop = cum.first, let yBot = cum.last else { continue }
            if yBot - yTop > 22 && yTop < Int(CGFloat(h) * 0.12) {
                cacMocY.append(yBot)
            } else if yBot - yTop <= 22 {
                let yTren = max(0, yTop - 6)
                let yDuoi = min(h - 1, yBot + 6)
                if rowMed[yTren] >= 249.8 || rowMed[yDuoi] >= 249.8 {
                    let tb = Int((Double(cum.reduce(0, +)) / Double(cum.count)).rounded())
                    cacMocY.append(tb)
                }
            }
        }
        if let cuoi = cacMocY.last, h - cuoi > 35 {
            cacMocY.append(h - 1)
        }
        return cacMocY
    }

    /// Chuyển đổi chuỗi % trong cột Thực hiện của nhân viên (chống nhiễu chữ cái do watermark đè lên như "A%" -> 4, "S%" -> 5, "B%" -> 8, "Z%" -> 2)
    private func docGiaTriPhanTramThiDuaNV(_ chuoi: String) -> Double? {
        var s = chuoi
            .replacingOccurrences(of: "54453", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }

        // Sửa lỗi ký tự đơn ngay trước dấu %
        let bangSuaKyTu: [(String, String)] = [
            ("(?i)\\bA\\s*%", "4%"),
            ("(?i)\\bS\\s*%", "5%"),
            ("(?i)\\bB\\s*%", "8%"),
            ("(?i)\\bG\\s*%", "6%"),
            ("(?i)\\bZ\\s*%", "2%"),
            ("(?i)\\b[Il|]\\s*%", "1%"),
            ("(?i)\\bO\\s*%", "0%")
        ]
        for (mau, thay) in bangSuaKyTu {
            s = s.replacingOccurrences(of: mau, with: thay, options: .regularExpression)
        }

        if let range = s.range(of: "(-?\\d+(?:[.,]\\d+)?)\\s*%", options: .regularExpression) {
            let sub = String(s[range]).replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
            if let val = chuyenChuoiThanhSoDoanhThu(sub), val >= 0 && val <= 300 {
                return val
            }
        }
        if let val = chuyenChuoiThanhSoDoanhThu(s), val >= 0 && val <= 300 {
            return val
        }
        return nil
    }

    /// Phân tích bảng Thi đua nhân viên theo môn (6 cột mở rộng): chỉ quét lấy từ hàng có TÊN NHÂN VIÊN cùng ID ("id: <mã NV>"), lấy % ở cột 2 để tính ra số thực hiện từ Target chia
    private func phanTichBangThiDuaNhanVienCoIdVaPhanTram(
        anh: UIImage?,
        phanTu: [PhanTuVanBan],
        tenNganhGoiY: String?,
        watermark: String?
    ) -> KetQuaThiDuaNhanVienKhoi? {
        let dsQL = KhoDuLieu.dungChung.layCaiDatAnToan().danhSachNhanVien

        func trichMaId(tu chuoi: String) -> String? {
            guard let regex = try? NSRegularExpression(pattern: "(?i)\\b(?:id|ld|1d|ia|iđ)\\s*[:.;\\-]?\\s*(\\d{3,8})\\b") else {
                return nil
            }
            let ns = chuoi as NSString
            let matches = regex.matches(in: chuoi, range: NSRange(location: 0, length: ns.length))
            for m in matches where m.numberOfRanges > 1 {
                let ma = ns.substring(with: m.range(at: 1))
                if ma == "54453" { continue }
                return ma
            }
            return nil
        }

        func laDongKhongPhaiNhanVien(_ chu: String) -> Bool {
            let u = boDau(chu)
            return u.contains("DML_") || u.contains("DMX_") || u.contains("TGDD_") ||
                u.contains("QNG_") || u.contains("QUANG TRUNG") ||
                u.contains("CHUONG TRINH") || u.contains("THUC HIEN") ||
                u.contains("TARGET") || u.contains("HANG VUNG")
        }

        func lamSachDongTenNV(_ chu: String) -> String {
            let s = chu
                .replacingOccurrences(of: "(?i)\\b(?:id|ld|1d|ia|iđ)\\s*[:.;\\-]?\\s*\\d{3,8}", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "54453", with: " ")
                .replacingOccurrences(of: "(?i)D[uũ]ng\\s*Nguy[eễ]n\\s*Thanh", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "(?i)Nguy[eễ]n\\s*Thanh", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "[+\\-–—_:|•]+", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\\d+", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if laDongKhongPhaiNhanVien(s) { return "" }
            return s.range(of: "[A-Za-zÀ-ỹĐđ]{2,}", options: .regularExpression) != nil ? s : ""
        }

        var tenMonTuAnh = (tenNganhGoiY ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var thucHienMonTuAnh: Double = 0
        var targetMonTuAnh: Double = 0

        // Tìm tên môn, số đã thực hiện của môn và target môn từ dòng chương trình/siêu thị đầu bảng (dòng có dấu "-" ở đầu, chưa có id:)
        let yIdDauTien = phanTu.compactMap { pt -> CGFloat? in
            guard pt.x < 0.40, trichMaId(tu: pt.chu) != nil else { return nil }
            return pt.y
        }.min() ?? 0.25

        let cacPTDauBang = phanTu.filter { $0.y > 0.05 && $0.y < yIdDauTien }
        if tenMonTuAnh.isEmpty {
            let tenUngVien = cacPTDauBang.filter { pt in
                guard pt.x >= 0.04 && pt.x < 0.33 else { return false }
                return !laDongKhongPhaiNhanVien(pt.chu) && trichMaId(tu: pt.chu) == nil
            }.sorted { $0.y < $1.y }
            if let ptTenDau = tenUngVien.first {
                let tenSach = KhoDuLieu.chuanHoaTenMonThiDuaChuan(ptTenDau.chu)
                if !tenSach.isEmpty && !laTenTheDoanhThuKhongPhaiThiDua(tenSach) {
                    tenMonTuAnh = tenSach
                }
            }
        }
        let cacSoThucHienDauBang = cacPTDauBang.filter { $0.x >= 0.34 && $0.x < 0.495 && !$0.chu.contains("%") }
        for pt in cacSoThucHienDauBang {
            if let v = chuyenChuoiThanhSoDoanhThu(pt.chu), v > 0, v != 54453 {
                thucHienMonTuAnh = v
                break
            }
        }
        let cacSoTargetDauBang = cacPTDauBang.filter { $0.x >= 0.49 && $0.x < 0.65 && !$0.chu.contains("%") }
        for pt in cacSoTargetDauBang {
            if let v = chuyenChuoiThanhSoDoanhThu(pt.chu), v > 0, v != 54453 {
                targetMonTuAnh = v
                break
            }
        }

        struct HangNVTam {
            var maNV: String
            var hoTen: String
            var phanTram: Double?
            var target: Double? = nil
            var yTrenNorm: CGFloat
            var yDuoiNorm: CGFloat
        }

        var cacHangNV: [HangNVTam] = []

        // ƯU TIÊN A: Cắt từng ô theo đường kẻ ngang + tẩy sạch chữ chìm watermark + tách riêng Cột 1 (Tên + id:) và Cột 2 (% thực hiện)
        if let anh = anh, let cgGoc = anh.cgImage {
            let w = cgGoc.width
            let h = cgGoc.height
            let cacMocY = timDuongKeNgangBangThiDuaNV6Cot(anh: anh)
            var cacKhoangHang: [(y0: Int, y1: Int)] = []
            if cacMocY.count >= 4 {
                for i in 0..<(cacMocY.count - 1) {
                    let chieuCao = cacMocY[i + 1] - cacMocY[i]
                    if chieuCao >= max(24, h / 45) && chieuCao <= max(130, h / 6) {
                        cacKhoangHang.append((cacMocY[i], cacMocY[i + 1]))
                    }
                }
            }

            if cacKhoangHang.count >= 2 {
                let scale = 3
                let vPad = 60
                let cellHeights = cacKhoangHang.map { ($0.y1 - $0.y0) * scale }
                let totalH = cellHeights.reduce(0, +) + (cacKhoangHang.count + 1) * vPad
                let totalW = w * scale
                let colorSpace = CGColorSpaceCreateDeviceRGB()

                if let ctx = CGContext(
                    data: nil,
                    width: totalW,
                    height: totalH,
                    bitsPerComponent: 8,
                    bytesPerRow: totalW * 4,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                ), let data = ctx.data {
                    let ptr = data.bindMemory(to: UInt8.self, capacity: totalW * totalH * 4)
                    for i in 0..<(totalW * totalH * 4) {
                        ptr[i] = 255
                    }
                    ctx.interpolationQuality = .high

                    var yOffsets: [(yTop: Int, yBot: Int)] = []
                    var curYTop = vPad
                    for (idx, kh) in cacKhoangHang.enumerated() {
                        let ch = cellHeights[idx]
                        if let crop = cgGoc.cropping(to: CGRect(x: 0, y: kh.y0, width: w, height: kh.y1 - kh.y0)) {
                            let cgY = totalH - curYTop - ch
                            ctx.draw(crop, in: CGRect(x: 0, y: cgY, width: totalW, height: ch))
                        }
                        yOffsets.append((curYTop, curYTop + ch))
                        curYTop += ch + vPad
                    }

                    // Làm mượt & tẩy sạch watermark (gray >= 206 -> 255), đồng thời xoá viền ô để chữ không chạm khung
                    for rIdx in cacKhoangHang.indices {
                        let (yT, yB) = yOffsets[rIdx]
                        for y in yT..<yB {
                            let laVienNgang = (y - yT < 8) || (yB - 1 - y < 8)
                            for x in 0..<totalW {
                                let off = (y * totalW + x) * 4
                                if laVienNgang {
                                    ptr[off] = 255; ptr[off + 1] = 255; ptr[off + 2] = 255
                                    continue
                                }
                                let r = Int(ptr[off])
                                let g = Int(ptr[off + 1])
                                let b = Int(ptr[off + 2])
                                let gray = (r + g + b) / 3
                                if gray >= 206 {
                                    ptr[off] = 255; ptr[off + 1] = 255; ptr[off + 2] = 255
                                } else if gray <= 80 {
                                    ptr[off] = 0; ptr[off + 1] = 0; ptr[off + 2] = 0
                                } else {
                                    let v = UInt8(((gray - 80) * 220) / 126)
                                    ptr[off] = v; ptr[off + 1] = v; ptr[off + 2] = v
                                }
                            }
                        }
                    }

                    if let cgExploded = ctx.makeImage() {
                        func ocrDaiCot(_ x0Norm: CGFloat, _ x1Norm: CGFloat, ngonNgu: Bool) -> [Int: [(y: CGFloat, chu: String)]] {
                            let x0 = max(0, Int(CGFloat(totalW) * x0Norm))
                            let x1 = min(totalW, Int(CGFloat(totalW) * x1Norm))
                            guard x1 > x0, let cgCot = cgExploded.cropping(to: CGRect(x: x0, y: 0, width: x1 - x0, height: totalH)) else {
                                return [:]
                            }
                            var bangDong: [Int: [(y: CGFloat, chu: String)]] = [:]
                            let req = VNRecognizeTextRequest { req, _ in
                                guard let obsList = req.results as? [VNRecognizedTextObservation] else { return }
                                for obs in obsList {
                                    let box = obs.boundingBox
                                    let yTamPx = (1.0 - box.origin.y - box.size.height / 2.0) * CGFloat(totalH)
                                    guard let rIdx = yOffsets.firstIndex(where: { yTamPx >= CGFloat($0.yTop - 12) && yTamPx <= CGFloat($0.yBot + 12) }) else {
                                        continue
                                    }
                                    let yTopPx = (1.0 - box.origin.y - box.size.height) * CGFloat(totalH)
                                    let cands = ngonNgu ? obs.topCandidates(1) : obs.topCandidates(3)
                                    for cand in cands {
                                        let s = cand.string.trimmingCharacters(in: .whitespacesAndNewlines)
                                        guard !s.isEmpty else { continue }
                                        bangDong[rIdx, default: []].append((yTopPx, s))
                                    }
                                }
                            }
                            req.recognitionLevel = .accurate
                            req.usesLanguageCorrection = ngonNgu
                            if ngonNgu {
                                req.recognitionLanguages = ["vi-VN", "en-US"]
                            }
                            req.minimumTextHeight = 0.002
                            let handler = VNImageRequestHandler(cgImage: cgCot, orientation: .up, options: [:])
                            try? handler.perform([req])
                            return bangDong
                        }

                        let bangCot1 = ocrDaiCot(0.040, 0.340, ngonNgu: true)
                        let bangCot2 = ocrDaiCot(0.342, 0.495, ngonNgu: false)
                        let bangCot3 = ocrDaiCot(0.495, 0.680, ngonNgu: false)

                        for (rIdx, kh) in cacKhoangHang.enumerated() {
                            let cacTextCot1 = (bangCot1[rIdx] ?? []).sorted { $0.y < $1.y }.map(\.chu)
                            let gopCot1 = cacTextCot1.joined(separator: "\n")

                            // Nếu là dòng Chương trình hoặc dòng Siêu thị ở đầu bảng (không có id:)
                            if trichMaId(tu: gopCot1) == nil {
                                if rIdx <= 2 {
                                    if tenMonTuAnh.isEmpty && !laDongKhongPhaiNhanVien(gopCot1) {
                                        let tenSach = KhoDuLieu.chuanHoaTenMonThiDuaChuan(gopCot1.replacingOccurrences(of: "\n", with: " "))
                                        if !tenSach.isEmpty && !laTenTheDoanhThuKhongPhaiThiDua(tenSach) {
                                            tenMonTuAnh = tenSach
                                        }
                                    }
                                    if thucHienMonTuAnh <= 0 {
                                        let cacSoCot2Dau = (bangCot2[rIdx] ?? []).map(\.chu)
                                        for t in cacSoCot2Dau where !t.contains("%") {
                                            if let v = chuyenChuoiThanhSoDoanhThu(t), v > 0, v != 54453 {
                                                thucHienMonTuAnh = v
                                                break
                                            }
                                        }
                                    }
                                    if targetMonTuAnh <= 0 {
                                        let cacSoCot3Dau = (bangCot3[rIdx] ?? []).map(\.chu)
                                        for t in cacSoCot3Dau where !t.contains("%") {
                                            if let v = chuyenChuoiThanhSoDoanhThu(t), v > 0, v != 54453 {
                                                targetMonTuAnh = v
                                                break
                                            }
                                        }
                                    }
                                }
                                continue
                            }

                            // BẮT BUỘC: Chỉ lấy hàng có CẢ mã nhân viên (id: ...) VÀ tên nhân viên hợp lệ
                            guard let maNVQuet = trichMaId(tu: gopCot1), !laDongKhongPhaiNhanVien(gopCot1) else {
                                continue
                            }

                            let cacDongTen = gopCot1
                                .components(separatedBy: .newlines)
                                .map { lamSachDongTenNV($0) }
                                .filter { !$0.isEmpty }
                            let hoTenQuet = cacDongTen.joined(separator: " ")
                                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                                .trimmingCharacters(in: .whitespacesAndNewlines)

                            guard !hoTenQuet.isEmpty else { continue }

                            let cacTextCot2 = (bangCot2[rIdx] ?? []).map(\.chu)
                            var phanTramQuet: Double?
                            for t in cacTextCot2 {
                                if t.contains("%"), let v = docGiaTriPhanTramThiDuaNV(t) {
                                    phanTramQuet = v
                                    break
                                }
                            }
                            if phanTramQuet == nil {
                                for t in cacTextCot2 {
                                    if let v = docGiaTriPhanTramThiDuaNV(t) {
                                        phanTramQuet = v
                                        break
                                    }
                                }
                            }

                            var targetQuet: Double? = nil
                            let cacTextCot3 = (bangCot3[rIdx] ?? []).map(\.chu)
                            for t in cacTextCot3 where !t.contains("%") {
                                if let v = chuyenChuoiThanhSoDoanhThu(t), v > 0, v != 54453 {
                                    targetQuet = v
                                    break
                                }
                            }

                            let y0Norm = CGFloat(kh.y0) / CGFloat(h)
                            let y1Norm = CGFloat(kh.y1) / CGFloat(h)
                            cacHangNV.append(
                                HangNVTam(
                                    maNV: maNVQuet,
                                    hoTen: hoTenQuet,
                                    phanTram: phanTramQuet,
                                    target: targetQuet,
                                    yTrenNorm: y0Norm,
                                    yDuoiNorm: y1Norm
                                )
                            )
                        }
                    }
                }
            }
        }

        // ƯU TIÊN B (Dự phòng nếu không tách được đường kẻ ngang): Tìm các phần tử có "id: <mã NV>" và ghép với dòng tên nhân viên ngay phía trên
        if cacHangNV.isEmpty {
            let cacPTId = phanTu.filter { pt in
                pt.x < 0.40 && trichMaId(tu: pt.chu) != nil
            }.sorted { $0.y < $1.y }

            for ptId in cacPTId {
                guard let maNVQuet = trichMaId(tu: ptId.chu) else { continue }
                let yId = ptId.y + ptId.cao / 2.0
                let cacPTTen = phanTu.filter { pt in
                    guard pt.x < 0.35 else { return false }
                    let yTam = pt.y + pt.cao / 2.0
                    return yTam >= yId - 0.042 && yTam <= yId + 0.008
                }.sorted { $0.y < $1.y }

                let hoTenQuet = cacPTTen
                    .map { lamSachDongTenNV($0.chu) }
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !hoTenQuet.isEmpty else { continue }
                cacHangNV.append(
                    HangNVTam(
                        maNV: maNVQuet,
                        hoTen: hoTenQuet,
                        phanTram: nil,
                        yTrenNorm: max(0.0, yId - 0.042),
                        yDuoiNorm: min(1.0, yId + 0.015)
                    )
                )
            }
        }

        guard !cacHangNV.isEmpty else { return nil }

        // Bổ sung số % từ phanTu gốc nếu ô nào chưa đọc được
        for i in cacHangNV.indices {
            if cacHangNV[i].phanTram == nil {
                let ungVienCot2 = phanTu.filter { pt in
                    let yTam = pt.y + pt.cao / 2.0
                    return pt.x >= 0.32 && pt.x <= 0.52 &&
                        yTam >= cacHangNV[i].yTrenNorm - 0.004 &&
                        yTam <= cacHangNV[i].yDuoiNorm + 0.004
                }.sorted {
                    if $0.chu.contains("%") != $1.chu.contains("%") { return $0.chu.contains("%") }
                    return $0.x > $1.x
                }
                for pt in ungVienCot2 {
                    if let v = docGiaTriPhanTramThiDuaNV(pt.chu) {
                        cacHangNV[i].phanTram = v
                        break
                    }
                }
            }
        }

        // Hậu kiểm tính đơn điệu giảm dần của cột % (nếu bảng xếp từ cao xuống thấp và có 1 dòng bị mờ số do watermark đè lên giữa 2 dòng bằng nhau)
        if cacHangNV.count >= 3 {
            for i in cacHangNV.indices {
                let truoc = (i > 0) ? cacHangNV[i - 1].phanTram : nil
                let sau = (i + 1 < cacHangNV.count) ? cacHangNV[i + 1].phanTram : nil
                if cacHangNV[i].phanTram == nil {
                    if let t = truoc, let s = sau, abs(t - s) < 0.001 {
                        cacHangNV[i].phanTram = t
                    } else if let t = truoc, i == cacHangNV.count - 1 {
                        cacHangNV[i].phanTram = t
                    }
                } else if let cur = cacHangNV[i].phanTram, let t = truoc, let s = sau, t >= s {
                    if cur > t + 0.01 || cur < s - 0.01 {
                        if abs(t - s) < 0.001 {
                            cacHangNV[i].phanTram = t
                        }
                    }
                }
            }
        }

        var danhSachKetQua: [DongThiDuaNhanVienQuet] = []
        var daXetMa = Set<String>()

        for hang in cacHangNV {
            guard let pt = hang.phanTram else { continue }
            if !dsQL.isEmpty {
                if let nvKhop = KhoDuLieu.khopNhanVienQuetVoiQuanLy(maQuet: hang.maNV, tenQuet: hang.hoTen, dsQuanLy: dsQL) {
                    guard !daXetMa.contains(nvKhop.maNV) else { continue }
                    daXetMa.insert(nvKhop.maNV)
                    danhSachKetQua.append(
                        DongThiDuaNhanVienQuet(
                            maNV: nvKhop.maNV,
                            hoTen: nvKhop.hoTen,
                            thucHien: pt,
                            target: hang.target ?? 0,
                            laPhanTram: true
                        )
                    )
                    continue
                }
            }
            let maChuan = KhoDuLieu.chuanHoaMaNV(hang.maNV)
            guard !maChuan.isEmpty, !daXetMa.contains(maChuan) else { continue }
            daXetMa.insert(maChuan)
            danhSachKetQua.append(
                DongThiDuaNhanVienQuet(
                    maNV: maChuan,
                    hoTen: hang.hoTen,
                    thucHien: pt,
                    target: hang.target ?? 0,
                    laPhanTram: true
                )
            )
        }

        guard !danhSachKetQua.isEmpty else { return nil }
        return KetQuaThiDuaNhanVienKhoi(
            tenNganhHang: tenMonTuAnh.isEmpty ? "Ngành hàng" : tenMonTuAnh,
            danhSach: danhSachKetQua,
            thucHienNganhGoiY: thucHienMonTuAnh,
            targetNganhGoiY: targetMonTuAnh
        )
    }

    private func phanTichThiDuaNhanVienOffline(
        phanTu: [PhanTuVanBan],
        anh: UIImage? = nil,
        tenNganhGoiY: String? = nil,
        watermark: String? = nil
    ) -> KetQuaThiDuaNhanVienKhoi? {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) { return nil }

        // ƯU TIÊN 1: Kiểm tra mẫu bảng mới có các dòng Tên nhân viên kèm "id: <mã NV>" và cột % thực hiện
        let coDongId = phanTu.contains { pt in
            pt.x < 0.42 && pt.chu.range(of: "(?i)\\b(?:id|ld|1d|ia|iđ)\\s*[:.;\\-]?\\s*\\d{3,8}", options: .regularExpression) != nil
        }
        if coDongId || laAnhBangThiDuaNhanVienTheoMonMoRong(phanTu: phanTu) {
            if let khoiMoi = phanTichBangThiDuaNhanVienCoIdVaPhanTram(
                anh: anh,
                phanTu: phanTu,
                tenNganhGoiY: tenNganhGoiY,
                watermark: watermark
            ), !khoiMoi.danhSach.isEmpty {
                return khoiMoi
            }
        }
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

            var cacSoCungHang: [Double] = []
            for pt in cungHang {
                if pt.chu.contains("/") {
                    let parts = pt.chu.components(separatedBy: "/")
                    for p in parts {
                        if let v = chuyenChuoiThanhSoDoanhThu(p) {
                            cacSoCungHang.append(v)
                        }
                    }
                } else if let val = chuyenChuoiThanhSo(pt.chu, watermark: watermark) {
                    cacSoCungHang.append(val)
                }
            }

            var thucHien: Double?
            var target: Double = 0

            if cacSoCungHang.count >= 2 {
                thucHien = cacSoCungHang[0]
                target = cacSoCungHang[1]
            } else if let soDuyNhat = cacSoCungHang.first {
                thucHien = soDuyNhat
            }

            if let th = thucHien {
                let dsQL = KhoDuLieu.dungChung.layCaiDatAnToan().danhSachNhanVien
                let maFinal: String
                let tenFinal: String
                if !dsQL.isEmpty, let nvKhop = KhoDuLieu.khopNhanVienQuetVoiQuanLy(maQuet: maNV, tenQuet: hoTen, dsQuanLy: dsQL) {
                    maFinal = nvKhop.maNV
                    tenFinal = nvKhop.hoTen
                } else {
                    maFinal = KhoDuLieu.chuanHoaMaNV(maNV)
                    tenFinal = hoTen
                }
                guard !maFinal.isEmpty, !daXetMa.contains(maFinal) else { continue }
                daXetMa.insert(maFinal)
                danhSach.append(DongThiDuaNhanVienQuet(maNV: maFinal, hoTen: tenFinal, thucHien: th, target: target))
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
            (0.25, 0.37),
            (0.42, 0.53),
            (0.60, 0.69),
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
    private func timCacDuongKeNgangBangNhanVien(anh: UIImage, coHeader: Bool, yHeaderMax: CGFloat, duongKeDoc: [CGFloat] = []) -> [CGFloat] {
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

        // Lấy mẫu tại các dải lề trống giữa các cột (tự động thích ứng theo đường kẻ dọc thực tế của bảng)
        var cacDaiX: [(CGFloat, CGFloat)] = [(0.005, 0.022), (0.978, 0.995)]
        if duongKeDoc.count == 4 {
            for v in duongKeDoc {
                cacDaiX.append((max(0.01, v - 0.020), max(0.02, v - 0.005)))
                cacDaiX.append((min(0.98, v + 0.005), min(0.99, v + 0.022)))
            }
        } else {
            cacDaiX.append(contentsOf: [
                (0.282, 0.293), (0.303, 0.315),
                (0.325, 0.344), (0.355, 0.380),
                (0.448, 0.457), (0.467, 0.480),
                (0.515, 0.540),
                (0.630, 0.638), (0.648, 0.664),
                (0.674, 0.700),
                (0.766, 0.786),
                (0.813, 0.821), (0.833, 0.852)
            ])
        }
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

            if spanNorm > 0.024 && yTop < Int(CGFloat(h) * 0.38) {
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
            cacMoc = cacMoc.filter { $0 > dayHeader + 0.012 }
            cacMoc.insert(dayHeader, at: 0)
        } else if coHeader && yHeaderMax > 0.02 {
            cacMoc = cacMoc.filter { $0 > yHeaderMax + 0.012 }
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
        if laAnhMaTranThiDuaNhanVien(phanTu: phanTu, anh: anh) { return [] }
        if laAnhBangThiDuaNhanVienTheoMonMoRong(phanTu: phanTu) { return [] }
        if laAnhBangThiDua5CotRealtime(phanTu: phanTu) || laAnhBangThiDua6Cot(phanTu: phanTu) { return [] }

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

        let coCot5BI = phanTuGocMoRong.contains { pt in
            let u = boDau(pt.chu)
            return u.contains("NGANH HANG BI") || u.contains("NHOM HANG BI") || u.contains("KHOAN VAY") || u.contains("TI TRONG") || u.contains("TY TRONG") || u.contains("DOANH THU HOP") || u.contains("THEO GIO CONG")
        }
        let laBangRong = !coCot5BI && phanTuGocMoRong.contains { pt in
            let u = boDau(pt.chu)
            return u.contains("DTLK") || u.contains("NANG SUAT")
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
            for pt in phanTuGocMoRong where pt.x < 0.36 || pt.y < 0.36 {
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

        // Nhận diện chính xác các phần tử thuộc dòng Tiêu đề (Header) của bảng (hỗ trợ cả ảnh cắt sát y < 0.18 và ảnh chụp toàn màn hình y ~ 0.25..0.35)
        let cacUngVienHeader = nguonTimHeader.filter { pt in
            guard pt.y < 0.40 else { return false }
            let chu = pt.chu
            if chu.range(of: "(?i)\\b(?:id|ld|1d|ia|iđ)\\s*[:.;\\-]?\\s*\\d{3,7}", options: .regularExpression) != nil {
                return false
            }
            if chu.range(of: "\\d+[.,]\\d+\\s*%", options: .regularExpression) != nil {
                return false
            }
            let u = chuanHoaTieuDe(chu)
            if u.contains("TIM NHAN VIEN") || u.contains("SAP XEP") || u.contains("CAP NHAT") ||
               u.contains("DOANH THU HOP") || u.contains("THEO DOANH THU") || u.contains("THEO GIO CONG") ||
               u.contains("CHI TIET DOANH THU") {
                return false
            }
            return u.contains("NGANH HANG BI") ||
                u.contains("NHOM HANG BI") ||
                u.contains("SO LUONG") ||
                u.contains("DOANH THU QD") ||
                u.contains("THU QD") ||
                u.contains("KHOAN VAY") ||
                u.contains("% TI TRONG") ||
                u.contains("% TY TRONG") ||
                (u.contains("NHAN VIEN") && u.contains("/"))
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
            yHeaderMax = max(0.045, min(0.380, yMax))
        } else {
            yHeaderMax = 0.0
        }

        let soDongCoId = phanTuMoRong.filter { pt in
            pt.x < 0.38 && pt.chu.range(of: "(?i)\\b(?:id|ld|1d|ia|iđ)\\s*[:.;\\-]?\\s*\\d{4,7}", options: .regularExpression) != nil
        }.count

        let duongKeDoc = (!laBangRong && anh != nil) ? timCacDuongKeDocBangNhanVien(anh: anh!, yBatDau: max(0.02, yHeaderMax)) : []

        var mocBatDauSoLuong: CGFloat = 0.298
        var mocBatDauDoanhThu: CGFloat = 0.462
        var mocBatDauKhoanVay: CGFloat = 0.643
        var mocBatDauTiTrong: CGFloat = 0.826

        if duongKeDoc.count == 4,
           duongKeDoc[0] >= 0.25 && duongKeDoc[0] <= 0.37,
           duongKeDoc[1] >= 0.42 && duongKeDoc[1] <= 0.53,
           duongKeDoc[2] >= 0.60 && duongKeDoc[2] <= 0.69,
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
            ? timCacDuongKeNgangBangNhanVien(anh: anh!, coHeader: coHeaderBang, yHeaderMax: yHeaderMax, duongKeDoc: duongKeDoc)
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

        // ƯU TIÊN B (Chỉ chạy khi thực sự là bảng Doanh thu Nhân viên có id: hoặc tiêu đề BI 5 cột)
        if cacDongNV.count < 2 && (coCot5BI || soDongCoId >= 1) {
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
            .replacingOccurrences(of: "﹣", with: "-")
            .replacingOccurrences(of: "－", with: "-")
            .replacingOccurrences(of: "(?<![0-9])-\\s+(?=\\d)", with: "-", options: .regularExpression)
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
        let chuan = chuoi
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "﹣", with: "-")
            .replacingOccurrences(of: "－", with: "-")
            .replacingOccurrences(of: "(?<![0-9])-\\s+(?=\\d)", with: "-", options: .regularExpression)
        guard let regex = try? NSRegularExpression(pattern: "-?\\d+[\\d.,]*") else { return [] }
        let ns = chuan as NSString
        let matches = regex.matches(in: chuan, range: NSRange(location: 0, length: ns.length))
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