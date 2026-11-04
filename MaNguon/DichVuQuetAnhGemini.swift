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
        let model = cd.geminiModel.hasPrefix("gemini-2.5-") ? cd.geminiModel : "gemini-2.5-flash"
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(key)") else { return }

        tienTrinh("Gemini 2.5 đang đọc \(danhSachAnh.count) ảnh và đối chiếu số liệu...")
        var parts: [[String: Any]] = [["text": prompt(cheDo: cheDo)]]
        for anh in danhSachAnh {
            guard let data = anh.jpegData(compressionQuality: 0.82) else { continue }
            parts.append(["inline_data": ["mime_type": "image/jpeg", "data": data.base64EncodedString()]])
        }

        let body: [String: Any] = [
            "contents": [["parts": parts]],
            "generationConfig": ["temperature": 0.1, "maxOutputTokens": 8192, "responseMimeType": "application/json"]
        ]
        var req = URLRequest(url: url, timeoutInterval: 90)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error { DispatchQueue.main.async { hoanTat(.failure(error)) }; return }
            guard let data,
                  let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = root["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let responseParts = content["parts"] as? [[String: Any]],
                  let text = responseParts.compactMap({ $0["text"] as? String }).first,
                  let jsonData = text.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? [String: Any]
                let loi = (msg?["message"] as? String) ?? "Gemini không trả về dữ liệu bảng hợp lệ."
                DispatchQueue.main.async { hoanTat(.failure(NSError(domain: "GeminiVision", code: 500, userInfo: [NSLocalizedDescriptionKey: loi]))) }
                return
            }
            let ketQua = self.chuyen(json: json)
            DispatchQueue.main.async { hoanTat(.success(ketQua)) }
        }.resume()
    }

    private func prompt(cheDo: LoaiCheDoDoanhThu) -> String {
        """
        Bạn là hệ thống OCR bảng số liệu Điện Máy Xanh. Đọc TẤT CẢ ảnh, giữ nguyên số âm, dấu thập phân và phần trăm. Chế độ: \(cheDo.tieuDe).
        Trả đúng một JSON, không giải thích:
        {"capNhatLuc":"","thongTinDonVi":"","doanhThu":{"doanhThuThuc":0,"targetThuc":0,"duKienThuc":0,"phanTramHTThuc":0,"doanhThuQuyDoi":0,"targetQuyDoi":0,"duKienQuyDoi":0,"phanTramHTQuyDoi":0},"nganhHang":[{"ten":"","loai":"DT hoặc SL","thucHien":0,"target":0,"phanTramHT":0,"duKien":0,"phanTramDuKien":0}],"nhanVien":[{"maNV":"","hoTen":"","soLuong":0,"doanhThuQD":0,"dtKhoanVay":0,"phanTramTiTrong":0}]}
        Quy tắc: không bỏ dòng có số 0 hoặc số âm; % tỉ trọng phải giữ dấu âm; không suy diễn số không nhìn thấy; ảnh không có nhóm dữ liệu nào thì trả mảng rỗng/đối tượng rỗng tương ứng.
        """
    }

    private func so(_ obj: [String: Any], _ key: String) -> Double {
        if let n = obj[key] as? NSNumber { return n.doubleValue }
        if let s = obj[key] as? String {
            return Double(s.replacingOccurrences(of: "%", with: "").replacingOccurrences(of: ",", with: ".")) ?? 0
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
            kq.danhSachThiDua = arr.compactMap { item in
                guard let ten = item["ten"] as? String, !ten.isEmpty else { return nil }
                let loai: LoaiChiTieuThiDua = ((item["loai"] as? String) ?? "DT").uppercased().contains("SL") ? .soLuong : .doanhThu
                return DongThiDua(tenNganhHang: ten, loaiChiTieu: loai, thucHien: so(item, "thucHien"), target: so(item, "target"), phanTramHTGoc: so(item, "phanTramHT"), phanTramDuBaoGoc: so(item, "phanTramDuKien"), duKienGoc: so(item, "duKien"))
            }
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
