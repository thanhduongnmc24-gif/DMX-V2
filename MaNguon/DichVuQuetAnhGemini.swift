import UIKit

/// Phân tích ảnh bảng số liệu bằng Gemini 2.5 khi người dùng chọn trong Cài đặt.
final class DichVuQuetAnhGemini {
    static let dungChung = DichVuQuetAnhGemini()
    private init() {}

    func quet(
        danhSachAnh: [UIImage],
        cheDo: LoaiCheDoDoanhThu,
        tienTrinh: @escaping (String) -> Void,
        hoanTat: @escaping (Result<KetQuaQuetTatCaAnh, Error>) -> Void
    ) {
        let cd = KhoDuLieu.dungChung.caiDat
        let key = cd.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            hoanTat(.failure(NSError(domain: "GeminiVision", code: 400, userInfo: [NSLocalizedDescriptionKey: "Chưa có Gemini API Key."])))
            return
        }
        tienTrinh("Gemini 2.5 đang đọc \(danhSachAnh.count) ảnh và đối chiếu số liệu...")
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
            "generationConfig": ["temperature": 0.1, "maxOutputTokens": 8192, "responseMimeType": "application/json"]
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            hoanTat(.failure(NSError(domain: "GeminiVision", code: 500, userInfo: [NSLocalizedDescriptionKey: "Không thể chuẩn bị dữ liệu ảnh gửi Gemini."])))
            return
        }

        let modelUuTien = cd.geminiModel.hasPrefix("gemini-2.5-") ? cd.geminiModel : "gemini-2.5-flash"
        var cacModel = [modelUuTien]
        for model in ["gemini-2.5-flash", "gemini-2.5-pro"] where !cacModel.contains(model) {
            cacModel.append(model)
        }
        goiGemini(cacModel: cacModel, chiSo: 0, key: key, bodyData: bodyData, tienTrinh: tienTrinh, hoanTat: hoanTat)
    }

    /// Giữ chữ đủ rõ cho bảng số liệu nhưng tránh vượt giới hạn kích thước request khi chọn nhiều ảnh.
    private func duLieuAnhGon(_ anh: UIImage) -> Data? {
        let gioiHan: CGFloat = 2048
        let canhLon = max(anh.size.width, anh.size.height)
        guard canhLon > gioiHan else { return anh.jpegData(compressionQuality: 0.78) }
        let tiLe = gioiHan / canhLon
        let kichThuoc = CGSize(width: anh.size.width * tiLe, height: anh.size.height * tiLe)
        let boVe = UIGraphicsImageRenderer(size: kichThuoc)
        let anhGon = boVe.image { _ in anh.draw(in: CGRect(origin: .zero, size: kichThuoc)) }
        return anhGon.jpegData(compressionQuality: 0.78)
    }

    private func goiGemini(
        cacModel: [String], chiSo: Int, key: String, bodyData: Data,
        tienTrinh: @escaping (String) -> Void,
        hoanTat: @escaping (Result<KetQuaQuetTatCaAnh, Error>) -> Void
    ) {
        guard chiSo < cacModel.count else {
            DispatchQueue.main.async {
                hoanTat(.failure(NSError(domain: "GeminiVision", code: 503, userInfo: [NSLocalizedDescriptionKey: "Không model Gemini 2.5 nào phản hồi. Hãy kiểm tra API Key, quyền dùng model và hạn mức tài khoản."])))
            }
            return
        }
        let model = cacModel[chiSo]
        guard var thanhPhan = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent") else { return }
        thanhPhan.queryItems = [URLQueryItem(name: "key", value: key)]
        guard let url = thanhPhan.url else { return }

        DispatchQueue.main.async { tienTrinh("Gemini 2.5 đang phân tích ảnh bằng \(model)...") }
        var req = URLRequest(url: url, timeoutInterval: 120)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = bodyData

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            guard let self else { return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if error != nil || [400, 403, 404, 429, 503].contains(status) {
                if chiSo + 1 < cacModel.count {
                    self.goiGemini(cacModel: cacModel, chiSo: chiSo + 1, key: key, bodyData: bodyData, tienTrinh: tienTrinh, hoanTat: hoanTat)
                    return
                }
            }
            guard let data else {
                DispatchQueue.main.async { hoanTat(.failure(error ?? NSError(domain: "GeminiVision", code: status, userInfo: [NSLocalizedDescriptionKey: "Gemini không gửi dữ liệu phản hồi."]))) }
                return
            }
            guard status == 200 else {
                let loi = self.thongDiepLoi(tu: data, status: status)
                DispatchQueue.main.async { hoanTat(.failure(NSError(domain: "GeminiVision", code: status, userInfo: [NSLocalizedDescriptionKey: loi]))) }
                return
            }
            guard let json = self.layJSONKetQua(tu: data) else {
                DispatchQueue.main.async { hoanTat(.failure(NSError(domain: "GeminiVision", code: 422, userInfo: [NSLocalizedDescriptionKey: "Gemini đã phản hồi nhưng nội dung không đúng định dạng số liệu."]))) }
                return
            }
            let ketQua = self.chuyen(json: json)
            guard ketQua.coDuLieu else {
                DispatchQueue.main.async { hoanTat(.failure(NSError(domain: "GeminiVision", code: 422, userInfo: [NSLocalizedDescriptionKey: "Gemini không tìm thấy bảng số liệu phù hợp trong ảnh."]))) }
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
        return "Gemini trả về lỗi HTTP \(status)."
    }

    private func prompt(cheDo: LoaiCheDoDoanhThu) -> String {
        """
        Bạn là hệ thống OCR bảng số liệu Điện Máy Xanh. Đọc TẤT CẢ ảnh, giữ nguyên số âm, dấu thập phân và phần trăm. Chế độ: \(cheDo.tieuDe).
        Trả đúng một JSON, không giải thích:
        {"capNhatLuc":"","thongTinDonVi":"","doanhThu":{"doanhThuThuc":0,"targetThuc":0,"duKienThuc":0,"phanTramHTThuc":0,"doanhThuQuyDoi":0,"targetQuyDoi":0,"duKienQuyDoi":0,"phanTramHTQuyDoi":0},"nganhHang":[{"ten":"","loai":"DT hoặc SL","thucHien":0,"target":0,"phanTramHT":0,"duKien":0,"phanTramDuKien":0}],"nhanVien":[{"maNV":"","hoTen":"","soLuong":0,"doanhThuQD":0,"dtKhoanVay":0,"phanTramTiTrong":0}]}
        Quy tắc: đọc đầy đủ mọi môn thi đua trên ảnh (từ 1, 3 đến 8+ môn/ảnh); không đưa nhãn phân nhóm (CE, ICT, DV), đơn vị (DT, SL), ngôi sao hay dòng phụ (Chạy theo thương hiệu) vào tên môn; không bỏ dòng có số 0 hoặc số âm; % tỉ trọng và % HT phải giữ dấu âm; nếu các môn có tên giống nhau 100% thì chỉ giữ 1 môn duy nhất; không suy diễn số không nhìn thấy; ảnh không có nhóm dữ liệu nào thì trả mảng rỗng/đối tượng rỗng tương ứng.
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

    private func chuyen(json: [String: Any]) -> KetQuaQuetTatCaAnh {
        var kq = KetQuaQuetTatCaAnh()
        kq.capNhatLuc = json["capNhatLuc"] as? String ?? ""
        kq.thongTinDonVi = json["thongTinDonVi"] as? String ?? ""
        if let d = json["doanhThu"] as? [String: Any], !d.isEmpty {
            let dt = ThongTinDoanhThu(
                doanhThuThuc: so(d, "doanhThuThuc"), targetThuc: so(d, "targetThuc"), duKienThuc: so(d, "duKienThuc"), phanTramHTThuc: so(d, "phanTramHTThuc"),
                doanhThuQuyDoi: so(d, "doanhThuQuyDoi"), targetQuyDoi: so(d, "targetQuyDoi"), duKienQuyDoi: so(d, "duKienQuyDoi"), phanTramHTQuyDoi: so(d, "phanTramHTQuyDoi")
            )
            if dt.coDuLieu { kq.doanhThu = dt; kq.soAnhDoanhThu = 1 }
        }
        if let arr = json["nganhHang"] as? [[String: Any]] {
            let dsQuet = arr.compactMap { item -> DongThiDua? in
                guard let ten = item["ten"] as? String, !ten.isEmpty else { return nil }
                let loai: LoaiChiTieuThiDua = ((item["loai"] as? String) ?? "DT").uppercased().contains("SL") ? .soLuong : .doanhThu
                return DongThiDua(tenNganhHang: ten, loaiChiTieu: loai, thucHien: so(item, "thucHien"), target: so(item, "target"), phanTramHTGoc: so(item, "phanTramHT"), phanTramDuBaoGoc: so(item, "phanTramDuKien"), duKienGoc: so(item, "duKien"))
            }
            kq.danhSachThiDua = KhoDuLieu.gopDanhSachThiDua(cu: [], moi: dsQuet)
            if !kq.danhSachThiDua.isEmpty { kq.soAnhThiDua = 1 }
        }
        if let arr = json["nhanVien"] as? [[String: Any]] {
            kq.doanhThuNhanVien = arr.compactMap { item in
                guard let ma = item["maNV"] as? String, !ma.isEmpty else { return nil }
                return DoanhThuNhanVienItem(maNV: ma, hoTen: item["hoTen"] as? String ?? "", soLuong: so(item, "soLuong"), doanhThuQD: so(item, "doanhThuQD"), dtQDKhoanVay: so(item, "dtKhoanVay"), phanTramQuyDoi: so(item, "phanTramTiTrong"))
            }
            if !kq.doanhThuNhanVien.isEmpty { kq.soAnhDoanhThuNV = 1 }
        }
        return kq
    }
}
