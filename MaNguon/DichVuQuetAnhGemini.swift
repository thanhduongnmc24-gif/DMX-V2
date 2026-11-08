import UIKit

/// Phân tích ảnh bảng số liệu bằng Gemini Flash (Phương pháp 3) với API Key tích hợp sẵn trong app hoặc API Key nhập mới ở Cài đặt.
final class DichVuQuetAnhGemini {
    static let dungChung = DichVuQuetAnhGemini()
    private init() {}

    func quet(
        danhSachAnh: [UIImage],
        cheDo: LoaiCheDoDoanhThu,
        tienTrinh: @escaping (String) -> Void,
        hoanTat: @escaping (Result<KetQuaQuetTatCaAnh, Error>) -> Void
    ) {
        let cd = KhoDuLieu.dungChung.layCaiDatAnToan()
        let keyNguoiDung = cd.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let keyChinh = keyNguoiDung.isEmpty ? CaiDatDMX.geminiKeyMacDinh : keyNguoiDung

        var danhSachKey: [String] = [keyChinh]
        if keyChinh != CaiDatDMX.geminiKeyMacDinh && !CaiDatDMX.geminiKeyMacDinh.isEmpty {
            danhSachKey.append(CaiDatDMX.geminiKeyMacDinh)
        }
        guard let keyDau = danhSachKey.first, !keyDau.isEmpty else {
            hoanTat(.failure(NSError(domain: "GeminiVision", code: 400, userInfo: [NSLocalizedDescriptionKey: "Chưa có Gemini API Key."])))
            return
        }

        DispatchQueue.main.async {
            tienTrinh("Gemini Flash đang đọc \(danhSachAnh.count) ảnh (\(cheDo.tieuDe))...")
        }
        guard !danhSachAnh.isEmpty else {
            hoanTat(.failure(NSError(domain: "GeminiVision", code: 400, userInfo: [NSLocalizedDescriptionKey: "Chưa chọn ảnh để quét."])))
            return
        }

        var parts: [[String: Any]] = [["text": prompt(cheDo: cheDo)]]
        for anh in danhSachAnh {
            guard let data = duLieuAnhGon(anh) else { continue }
            parts.append(["inline_data": ["mime_type": "image/jpeg", "data": data.base64EncodedString()]])
        }
        guard parts.count > 1 else {
            hoanTat(.failure(NSError(domain: "GeminiVision", code: 400, userInfo: [NSLocalizedDescriptionKey: "Không thể đọc dữ liệu từ ảnh đã chọn."])))
            return
        }

        let body: [String: Any] = [
            "contents": [["parts": parts]],
            "generationConfig": [
                "temperature": 0.05,
                "maxOutputTokens": 8192,
                "responseMimeType": "application/json"
            ]
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            hoanTat(.failure(NSError(domain: "GeminiVision", code: 500, userInfo: [NSLocalizedDescriptionKey: "Không thể chuẩn bị dữ liệu ảnh gửi Gemini Flash."])))
            return
        }

        let modelLuu = cd.geminiModel.trimmingCharacters(in: .whitespacesAndNewlines)
        let modelUuTien = (modelLuu.hasPrefix("gemini-") && modelLuu.contains("flash")) ? modelLuu : "gemini-2.5-flash"
        var cacModel = [modelUuTien]
        for model in ["gemini-2.5-flash", "gemini-2.0-flash", "gemini-2.5-pro"] where !cacModel.contains(model) {
            cacModel.append(model)
        }

        var cacCapThu: [(key: String, model: String)] = []
        for k in danhSachKey {
            for m in cacModel {
                cacCapThu.append((key: k, model: m))
            }
        }

        goiGemini(cacCap: cacCapThu, chiSo: 0, cheDo: cheDo, bodyData: bodyData, tienTrinh: tienTrinh, hoanTat: hoanTat)
    }

    /// Giữ chữ đủ rõ cho bảng số liệu nhưng tránh vượt giới hạn kích thước request khi chọn nhiều ảnh.
    private func duLieuAnhGon(_ anh: UIImage) -> Data? {
        let gioiHan: CGFloat = 2048
        let canhLon = max(anh.size.width, anh.size.height)
        guard canhLon > gioiHan else { return anh.jpegData(compressionQuality: 0.80) }
        let tiLe = gioiHan / canhLon
        let kichThuoc = CGSize(width: anh.size.width * tiLe, height: anh.size.height * tiLe)
        let boVe = UIGraphicsImageRenderer(size: kichThuoc)
        let anhGon = boVe.image { _ in anh.draw(in: CGRect(origin: .zero, size: kichThuoc)) }
        return anhGon.jpegData(compressionQuality: 0.80)
    }

    private func goiGemini(
        cacCap: [(key: String, model: String)],
        chiSo: Int,
        cheDo: LoaiCheDoDoanhThu,
        bodyData: Data,
        tienTrinh: @escaping (String) -> Void,
        hoanTat: @escaping (Result<KetQuaQuetTatCaAnh, Error>) -> Void
    ) {
        guard chiSo < cacCap.count else {
            DispatchQueue.main.async {
                hoanTat(.failure(NSError(domain: "GeminiVision", code: 503, userInfo: [NSLocalizedDescriptionKey: "Không kết nối được Gemini Flash. Hãy kiểm tra mạng hoặc API Key trong Cài đặt."])))
            }
            return
        }
        let cap = cacCap[chiSo]
        guard var thanhPhan = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/\(cap.model):generateContent") else { return }
        thanhPhan.queryItems = [URLQueryItem(name: "key", value: cap.key)]
        guard let url = thanhPhan.url else { return }

        DispatchQueue.main.async {
            tienTrinh("Gemini Flash (\(cap.model)) đang phân tích bảng \(cheDo.tieuDe)...")
        }
        var req = URLRequest(url: url, timeoutInterval: 90)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = bodyData

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            guard let self else { return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if error != nil || [400, 403, 404, 429, 500, 503].contains(status) {
                if chiSo + 1 < cacCap.count {
                    self.goiGemini(cacCap: cacCap, chiSo: chiSo + 1, cheDo: cheDo, bodyData: bodyData, tienTrinh: tienTrinh, hoanTat: hoanTat)
                    return
                }
            }
            guard let data else {
                DispatchQueue.main.async {
                    hoanTat(.failure(error ?? NSError(domain: "GeminiVision", code: status, userInfo: [NSLocalizedDescriptionKey: "Gemini Flash không gửi dữ liệu phản hồi."])))
                }
                return
            }
            guard status == 200 else {
                let loi = self.thongDiepLoi(tu: data, status: status)
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError(domain: "GeminiVision", code: status, userInfo: [NSLocalizedDescriptionKey: loi])))
                }
                return
            }
            guard let json = self.layJSONKetQua(tu: data) else {
                if chiSo + 1 < cacCap.count {
                    self.goiGemini(cacCap: cacCap, chiSo: chiSo + 1, cheDo: cheDo, bodyData: bodyData, tienTrinh: tienTrinh, hoanTat: hoanTat)
                    return
                }
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError(domain: "GeminiVision", code: 422, userInfo: [NSLocalizedDescriptionKey: "Gemini Flash đã phản hồi nhưng nội dung không đúng định dạng JSON số liệu."])))
                }
                return
            }
            let ketQua = self.chuyen(json: json, cheDo: cheDo)
            guard ketQua.coDuLieu else {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError(domain: "GeminiVision", code: 422, userInfo: [NSLocalizedDescriptionKey: "Gemini Flash không tìm thấy bảng số liệu phù hợp trong ảnh."])))
                }
                return
            }
            DispatchQueue.main.async { hoanTat(.success(ketQua)) }
        }.resume()
    }

    private func layJSONKetQua(tu data: Data) -> [String: Any]? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = root["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else { return nil }
        var text = parts.compactMap { $0["text"] as? String }.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if let dau = text.firstIndex(of: "{"), let cuoi = text.lastIndex(of: "}") {
            text = String(text[dau...cuoi])
        }
        guard let jsonData = text.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
    }

    private func thongDiepLoi(tu data: Data, status: Int) -> String {
        if let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = root["error"] as? [String: Any], let message = error["message"] as? String {
            return message
        }
        return "Gemini Flash trả về lỗi HTTP \(status)."
    }

    private func prompt(cheDo: LoaiCheDoDoanhThu) -> String {
        """
        Bạn là hệ thống OCR chuyên dụng đọc bảng số liệu Điện Máy Xanh (ĐMX). Hãy đọc TẤT CẢ các ảnh được gửi, bỏ qua hoàn toàn chữ chìm watermark nghiêng (ví dụ: "54453", "Dũng Nguyễn Thanh"), giữ nguyên dấu âm, số thập phân và phần trăm. Chế độ hiện tại: \(cheDo.tieuDe).
        Trả về ĐÚNG MỘT đối tượng JSON theo cấu trúc sau, không giải thích thêm:
        {"capNhatLuc":"","thongTinDonVi":"","doanhThu":{"doanhThuThuc":0,"targetThuc":0,"duKienThuc":0,"phanTramHTThuc":0,"doanhThuQuyDoi":0,"targetQuyDoi":0,"duKienQuyDoi":0,"phanTramHTQuyDoi":0},"nganhHang":[{"ten":"","loai":"DT hoặc SL","thucHien":0,"target":0,"phanTramHT":0,"duKien":0,"phanTramDuKien":0}],"nhanVien":[{"maNV":"","hoTen":"","soLuong":0,"doanhThuQD":0,"dtKhoanVay":0,"phanTramTiTrong":0}],"thiDuaNhanVien":[{"tenNganhHang":"","danhSach":[{"maNV":"","hoTen":"","thucHien":0,"target":0}]}]}

        Quy tắc bắt buộc khi đọc Bảng Thi Đua (mảng "nganhHang"):
        1. Phân biệt rõ 2 loại bảng Thi Đua có dấu (+) ở đầu dòng:
           - BẢNG THI ĐUA THEO NGÀY / REALTIME (5 CỘT): Gồm 5 cột: [CHƯƠNG TRÌNH | THỰC HIỆN | TARGET NGÀY | % HT NGÀY | HẠNG VÙNG].
             + Cột 1 (CHƯƠNG TRÌNH): Tên môn thi đua kèm huy hiệu "DT" hoặc "SL" ở cuối (bỏ dấu "+" và ngôi sao vàng ⭐ ở đầu; tách "DT" hoặc "SL" vào trường "loai"; phần tên môn sạch đưa vào "ten").
             + Cột 2 (THỰC HIỆN): Đưa vào "thucHien".
             + Cột 3 (TARGET NGÀY): Đưa vào "target".
             + Cột 4 (% HT NGÀY): Đưa vào "phanTramHT". Vì bảng theo ngày chỉ có 5 cột (không có cột % HT Dự kiến), đặt "phanTramDuKien": 0 và "duKien": 0.
             + Cột 5 (HẠNG VÙNG): Bỏ qua.
           - BẢNG THI ĐUA LŨY KẾ (6 CỘT): Gồm 6 cột: [CHƯƠNG TRÌNH | THỰC HIỆN | TARGET | % HT | % HT DỰ KIẾN | HẠNG VÙNG].
             + Cột 1 (CHƯƠNG TRÌNH): Tách huy hiệu "DT"/"SL" vào "loai", tên môn sạch (bỏ dấu "+", ngôi sao ⭐) vào "ten".
             + Cột 2 (THỰC HIỆN): Đưa vào "thucHien".
             + Cột 3 (TARGET): Đưa vào "target" (lưu ý dấu phẩy hàng nghìn như 1,502.38 = 1502.38).
             + Cột 4 (% HT): Đưa vào "phanTramHT".
             + Cột 5 (% HT DỰ KIẾN): Đưa vào "phanTramDuKien".
             + Cột 6 (HẠNG VÙNG): Bỏ qua.
           - Ngoài ra nếu ảnh là Lưới thẻ thi đua 2 cột hoặc Bảng 4 cột có tiền tố T11: đọc đầy đủ tên môn, đơn vị DT/SL, Thực hiện, Target, % HT và % Dự kiến / DT Dự kiến.
        2. Đọc ĐẦY ĐỦ tất cả các dòng môn thi đua trong ảnh từ trên xuống dưới (kể cả dòng có Thực hiện = 0 hoặc 0.00). Không đưa nhãn DT, SL, CE, ICT, DV hay dấu + vào trong "ten".
        3. Với bảng doanh thu nhân viên (NHÂN VIÊN | SỐ LƯỢNG | DOANH THU QĐ | DT QĐ KHOẢN VAY | % TỈ TRỌNG), trích đúng "maNV" (bỏ tiền tố id:) và "hoTen".
        """
    }

    private func so(_ obj: [String: Any], _ key: String) -> Double {
        if let n = obj[key] as? NSNumber { return n.doubleValue }
        if let s = obj[key] as? String {
            var chuoi = s
                .replacingOccurrences(of: "%", with: "")
                .replacingOccurrences(of: " ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if chuoi.contains(",") && chuoi.contains(".") {
                if let viTriPhay = chuoi.lastIndex(of: ","), let viTriCham = chuoi.lastIndex(of: "."), viTriPhay > viTriCham {
                    chuoi = chuoi.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
                } else {
                    chuoi = chuoi.replacingOccurrences(of: ",", with: "")
                }
            } else if chuoi.contains(",") {
                chuoi = chuoi.replacingOccurrences(of: ",", with: ".")
            }
            return Double(chuoi) ?? 0
        }
        return 0
    }

    private func chuyen(json: [String: Any], cheDo: LoaiCheDoDoanhThu) -> KetQuaQuetTatCaAnh {
        var kq = KetQuaQuetTatCaAnh()
        kq.capNhatLuc = json["capNhatLuc"] as? String ?? ""
        kq.thongTinDonVi = json["thongTinDonVi"] as? String ?? ""
        if let d = json["doanhThu"] as? [String: Any], !d.isEmpty {
            let dt = ThongTinDoanhThu(
                doanhThuThuc: so(d, "doanhThuThuc"),
                targetThuc: so(d, "targetThuc"),
                duKienThuc: so(d, "duKienThuc"),
                phanTramHTThuc: so(d, "phanTramHTThuc"),
                doanhThuQuyDoi: so(d, "doanhThuQuyDoi"),
                targetQuyDoi: so(d, "targetQuyDoi"),
                duKienQuyDoi: so(d, "duKienQuyDoi"),
                phanTramHTQuyDoi: so(d, "phanTramHTQuyDoi")
            )
            if dt.coDuLieu { kq.doanhThu = dt; kq.soAnhDoanhThu = 1 }
        }
        if let arr = json["nganhHang"] as? [[String: Any]] {
            let dsQuet = arr.compactMap { item -> DongThiDua? in
                guard let tenTho = item["ten"] as? String else { return nil }
                let tenSach = KhoDuLieu.chuanHoaTenMonThiDuaChuan(tenTho)
                guard !tenSach.isEmpty else { return nil }
                let loaiStr = ((item["loai"] as? String) ?? "DT").uppercased()
                let loai: LoaiChiTieuThiDua = loaiStr.contains("SL") ? .soLuong : .doanhThu
                let th = so(item, "thucHien")
                let tg = so(item, "target")
                var ht = so(item, "phanTramHT")
                if ht <= 0 && tg > 0 && th > 0 {
                    ht = ((th / tg) * 1000.0).rounded() / 10.0
                }
                let db = so(item, "phanTramDuKien")
                var dk = so(item, "duKien")

                let phanTramDuBaoGoc: Double?
                let duKienGoc: Double?
                if cheDo == .realtime || db <= 0 {
                    phanTramDuBaoGoc = ht
                    duKienGoc = (dk > 0 && cheDo == .luyKe) ? dk : nil
                } else {
                    phanTramDuBaoGoc = db
                    if dk <= 0 && tg > 0 {
                        let uoc = tg * (db / 100.0)
                        dk = (loai == .soLuong) ? uoc.rounded() : ((uoc * 100).rounded() / 100)
                    }
                    duKienGoc = dk > 0 ? dk : nil
                }

                return DongThiDua(
                    tenNganhHangGoc: tenSach,
                    tenNganhHang: KhoDuLieu.apDungLocTuCaiDat(tenSach),
                    loaiChiTieu: loai,
                    thucHien: th,
                    target: tg,
                    phanTramHTGoc: ht,
                    phanTramDuBaoGoc: phanTramDuBaoGoc,
                    duKienGoc: duKienGoc
                )
            }
            kq.danhSachThiDua = KhoDuLieu.gopDanhSachThiDua(cu: [], moi: dsQuet)
            if !kq.danhSachThiDua.isEmpty { kq.soAnhThiDua = 1 }
        }
        if let arr = json["nhanVien"] as? [[String: Any]] {
            kq.doanhThuNhanVien = arr.compactMap { item in
                guard let ma = item["maNV"] as? String, !ma.isEmpty else { return nil }
                return DoanhThuNhanVienItem(
                    maNV: ma,
                    hoTen: item["hoTen"] as? String ?? "",
                    soLuong: so(item, "soLuong"),
                    doanhThuQD: so(item, "doanhThuQD"),
                    dtQDKhoanVay: so(item, "dtKhoanVay"),
                    phanTramQuyDoi: so(item, "phanTramTiTrong")
                )
            }
            if !kq.doanhThuNhanVien.isEmpty { kq.soAnhDoanhThuNV = 1 }
        }
        if let arrTDNV = json["thiDuaNhanVien"] as? [[String: Any]] {
            kq.thiDuaNhanVien = arrTDNV.compactMap { khoi -> KetQuaThiDuaNhanVienKhoi? in
                let tenNganh = (khoi["tenNganhHang"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard let dsRaw = khoi["danhSach"] as? [[String: Any]], !dsRaw.isEmpty else { return nil }
                let ds = dsRaw.compactMap { nv -> DongThiDuaNhanVienQuet? in
                    let ma = (nv["maNV"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    let ten = (nv["hoTen"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !ma.isEmpty || !ten.isEmpty else { return nil }
                    return DongThiDuaNhanVienQuet(
                        maNV: ma,
                        hoTen: ten,
                        thucHien: so(nv, "thucHien"),
                        target: so(nv, "target")
                    )
                }
                guard !ds.isEmpty else { return nil }
                return KetQuaThiDuaNhanVienKhoi(tenNganhHang: tenNganh, danhSach: ds)
            }
            if !kq.thiDuaNhanVien.isEmpty { kq.soAnhThiDuaNV = kq.thiDuaNhanVien.count }
        }
        return kq
    }
}
