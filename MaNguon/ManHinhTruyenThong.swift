import UIKit
import Photos
import PhotosUI
import WebKit
import SafariServices

struct MucSanPhamPoster {
    var anhMau: UIImage? = nil
    var tenSanPham: String = ""
    var giaNiemYet: String = ""
    var giaKhuyenMai: String = ""
    var uuDai: String = ""
    var diemNoiBat: String = ""

    var coDuLieu: Bool {
        return anhMau != nil
            || !tenSanPham.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !giaKhuyenMai.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !giaNiemYet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !uuDai.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !diemNoiBat.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct ThongTinSanPhamTruyenThong {
    var tenSanPham: String
    var giaNiemYet: String
    var giaKhuyenMai: String
    var uuDai: String
    var diemNoiBat: String
    var lienHe: String
    var tyLeAnh: String
    var modelFlow: String
    var phongCachAnh: String
    var danhSachSanPham: [MucSanPhamPoster] = []
}

struct KetQua3BaiDangFacebook {
    var haiHuoc: String = ""
    var chuyenNghiep: String = ""
    var chotSale: String = ""
}

/// Dịch vụ gọi Gemini API tạo ảnh truyền thông sản phẩm và viết 3 phong cách bài đăng Facebook.
final class DichVuTruyenThongGemini {
    static let dungChung = DichVuTruyenThongGemini()
    private init() {}

    private let cacModelTaoAnh: [String] = [
        "gemini-nano-banana-2.1",
        "gemini-3.1-flash-image-preview",
        "gemini-3.1-flash-image",
        "gemini-3-pro-image-preview",
        "gemini-2.5-flash-image"
    ]

    private let cacModelVietBai: [String] = [
        "gemini-3.5-flash-lite",
        "gemini-3.1-flash-lite",
        "gemini-3.8-flash",
        "gemini-2.5-flash-lite",
        "gemini-3.1-flash-lite-preview"
    ]

    private func thuGonAnhMau(_ anh: UIImage) -> Data? {
        return autoreleasepool {
            let maxSide: CGFloat = 3072
            let w = anh.size.width
            let h = anh.size.height
            guard w > 10, h > 10 else { return anh.jpegData(compressionQuality: 0.85) }
            let canhLon = max(w, h)
            if canhLon <= maxSide {
                return anh.jpegData(compressionQuality: 0.85)
            }
            let tiLe = maxSide / canhLon
            let kichThuoc = CGSize(width: (w * tiLe).rounded(), height: (h * tiLe).rounded())
            let dinhDang = UIGraphicsImageRendererFormat.default()
            dinhDang.scale = 1.0
            dinhDang.opaque = true
            let boVe = UIGraphicsImageRenderer(size: kichThuoc, format: dinhDang)
            let anhGon = boVe.image { _ in
                anh.draw(in: CGRect(origin: .zero, size: kichThuoc))
            }
            return anhGon.jpegData(compressionQuality: 0.85)
        }
    }

    private func thongDiepLoiHTTP(data: Data?, status: Int, error: Error?) -> String {
        if let data,
           let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let errObj = root["error"] as? [String: Any],
           let msg = errObj["message"] as? String, !msg.isEmpty {
            if status == 429 {
                return "Gemini đang quá tải hoặc hết hạn mức (HTTP 429). Vui lòng đợi vài giây hoặc kiểm tra API Key."
            }
            if status == 401 || status == 403 {
                return "API Key Gemini không hợp lệ hoặc không có quyền dùng model tạo ảnh (HTTP \(status))."
            }
            return "Gemini lỗi (HTTP \(status)): \(msg)"
        }
        if status == 0 {
            return error?.localizedDescription ?? "Không kết nối được máy chủ Gemini. Vui lòng kiểm tra mạng."
        }
        return "Gemini trả về lỗi HTTP \(status)."
    }

    // MARK: - 1. Tạo ảnh truyền thông chứa giá cả & ưu đãi

    func taoAnhTruyenThong(
        anhMau: UIImage?,
        thongTin: ThongTinSanPhamTruyenThong,
        hoanTat: @escaping (Result<UIImage, Error>) -> Void
    ) {
        let danhSachKey = KhoDuLieu.dungChung.layCaiDatAnToan().danhSachGeminiApiKeyHieuLuc
        guard !danhSachKey.isEmpty else {
            DispatchQueue.main.async {
                hoanTat(.failure(NSError(domain: "TruyenThongGemini", code: 400, userInfo: [NSLocalizedDescriptionKey: "Chưa có Gemini API Key trong Cài đặt."])))
            }
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let anhData = anhMau.flatMap { self.thuGonAnhMau($0) }
            let promptAnh = self.taoPromptAnh(thongTin: thongTin, coAnhMau: anhData != nil)
            var cacCap: [(model: String, key: String)] = []
            for model in self.cacModelTaoAnh {
                for key in danhSachKey.prefix(3) {
                    cacCap.append((model, key))
                }
            }
            self.goiTaoAnh(cacCap: cacCap, chiSo: 0, prompt: promptAnh, anhData: anhData, tyLe: thongTin.tyLeAnh, hoanTat: hoanTat)
        }
    }

    func taoPromptChoGoogleFlow(thongTin: ThongTinSanPhamTruyenThong, coAnhMau: Bool) -> String {
        return taoPromptAnh(thongTin: thongTin, coAnhMau: coAnhMau)
    }

    func taoPromptAnh(thongTin: ThongTinSanPhamTruyenThong, coAnhMau: Bool) -> String {
        let moTaPhongCach: String
        switch thongTin.phongCachAnh {
        case "Sang trọng":
            moTaPhongCach = "Phong cách hiện đại, sang trọng, nền sáng tinh tế (xanh navy đậm kết hợp trắng/vàng ánh kim), bố cục thoáng, sạch, chuẩn thương hiệu cao cấp."
        case "Flash Sale":
            moTaPhongCach = "Phong cách Flash Sale rực lửa, năng lượng cao (đỏ cam - vàng rực), tem giá sốc lớn, thu hút ánh nhìn ngay lập tức trên Facebook."
        default:
            moTaPhongCach = "Phong cách quảng cáo điện máy rực rỡ, chuyên nghiệp (xanh dương đậm kết hợp vàng nổi bật và trắng sạch sẽ), bố cục cân đối, dễ đọc trên điện thoại."
        }

        let cacSP = thongTin.danhSachSanPham.filter { $0.coDuLieu }
        if cacSP.count >= 2 {
            var moTaTungSP: [String] = []
            for (idx, sp) in cacSP.enumerated() {
                var dong: [String] = ["• SẢN PHẨM \(idx + 1):"]
                if !sp.tenSanPham.isEmpty { dong.append("  - Tên sản phẩm: \"\(sp.tenSanPham)\"") }
                if !sp.giaNiemYet.isEmpty { dong.append("  - Giá niêm yết (gạch ngang): \"\(sp.giaNiemYet)\"") }
                if !sp.giaKhuyenMai.isEmpty { dong.append("  - Giá khuyến mãi / Giá sốc (to, đậm, nổi bật): \"\(sp.giaKhuyenMai)\"") }
                if !sp.uuDai.isEmpty { dong.append("  - Ưu đãi / Quà tặng: \"\(sp.uuDai)\"") }
                if !sp.diemNoiBat.isEmpty { dong.append("  - Điểm nổi bật: \"\(sp.diemNoiBat)\"") }
                moTaTungSP.append(dong.joined(separator: "\n"))
            }
            if !thongTin.lienHe.isEmpty {
                moTaTungSP.append("• Thông tin cửa hàng / liên hệ ở chân poster: \"\(thongTin.lienHe)\"")
            }
            let soAnh = cacSP.filter { $0.anhMau != nil }.count
            let nguonNhieuSP = (coAnhMau || soAnh > 0)
                ? "Ảnh mẫu đính kèm chứa hình ảnh thực tế của \(max(1, soAnh)) sản phẩm (được ghép theo thứ tự SẢN PHẨM 1, SẢN PHẨM 2...). Hãy tách nền gọn gàng từng sản phẩm, giữ nguyên 100% hình dáng, màu sắc, chi tiết thật của từng sản phẩm và GỘP TẤT CẢ \(cacSP.count) SẢN PHẨM VÀO CHUNG 1 POSTER quảng cáo thống nhất (không giữ khung chia ô thô của ảnh mẫu mà bố trí các sản phẩm thành bố cục poster khuyến mãi chuyên nghiệp, mỗi sản phẩm đặt cạnh đúng bảng tên và giá bán tương ứng của sản phẩm đó)."
                : "Tạo hình ảnh sắc nét, chân thực cho cả \(cacSP.count) sản phẩm và gộp chung vào 1 poster quảng cáo chuyên nghiệp, mỗi sản phẩm đi kèm đúng khung tên và giá bán tương ứng."

            return """
            Thiết kế 1 poster tổng hợp (combo nhiều sản phẩm) truyền thông bán hàng chuyên nghiệp đăng Facebook bằng tiếng Việt có dấu chuẩn xác 100%, chữ rõ nét, không sai chính tả, không bị chồng chữ.
            \(nguonNhieuSP)
            \(moTaPhongCach)
            Các nội dung chữ BẮT BUỘC hiển thị rõ ràng, chính xác từng ký tự cho từng sản phẩm trên poster:
            \(moTaTungSP.joined(separator: "\n"))
            Yêu cầu bố cục: chia vùng/thẻ sản phẩm cân đối cho cả \(cacSP.count) sản phẩm trong cùng 1 poster, sản phẩm sắc nét, khung giá khuyến mãi của từng sản phẩm cực kỳ dễ đọc, phông chữ sans-serif đậm rõ dấu tiếng Việt, không thêm watermark lạ, không thừa chữ rác tiếng Anh.
            """
        }

        var chiTiet: [String] = []
        if !thongTin.tenSanPham.isEmpty { chiTiet.append("- Tên sản phẩm nổi bật: \"\(thongTin.tenSanPham)\"") }
        if !thongTin.giaNiemYet.isEmpty { chiTiet.append("- Giá niêm yết (gạch ngang nhỏ hơn): \"\(thongTin.giaNiemYet)\"") }
        if !thongTin.giaKhuyenMai.isEmpty { chiTiet.append("- Giá khuyến mãi / Giá sốc (to, đậm, nổi bật nhất): \"\(thongTin.giaKhuyenMai)\"") }
        if !thongTin.uuDai.isEmpty { chiTiet.append("- Ưu đãi / Quà tặng (huy hiệu / khung nổi bật): \"\(thongTin.uuDai)\"") }
        if !thongTin.diemNoiBat.isEmpty { chiTiet.append("- Điểm nổi bật (tối đa 2-3 nhãn ngắn gọn): \"\(thongTin.diemNoiBat)\"") }
        if !thongTin.lienHe.isEmpty { chiTiet.append("- Thông tin cửa hàng / liên hệ ở chân poster: \"\(thongTin.lienHe)\"") }

        let nguonSanPham = coAnhMau
            ? "Giữ nguyên chính xác hình dáng, màu sắc và chi tiết của sản phẩm trong ảnh mẫu đính kèm; tách nền gọn gàng và đặt sản phẩm làm trung tâm nổi bật trong poster."
            : "Tạo hình ảnh sản phẩm sắc nét, chân thực như chụp studio chuyên nghiệp làm trung tâm nổi bật trong poster."

        return """
        Thiết kế một poster ảnh truyền thông bán hàng chuyên nghiệp đăng Facebook bằng tiếng Việt có dấu chuẩn xác 100%, chữ rõ nét, không sai chính tả, không bị chồng chữ.
        \(nguonSanPham)
        \(moTaPhongCach)
        Các nội dung chữ BẮT BUỘC hiển thị rõ ràng, chính xác từng ký tự trên poster:
        \(chiTiet.joined(separator: "\n"))
        Yêu cầu bố cục: sản phẩm sắc nét ở vùng trung tâm/bên phải, khung giá khuyến mãi cực kỳ dễ đọc, phông chữ sans-serif đậm rõ dấu tiếng Việt, không thêm watermark lạ, không thừa chữ rác tiếng Anh.
        """
    }

    private func goiTaoAnh(
        cacCap: [(model: String, key: String)],
        chiSo: Int,
        prompt: String,
        anhData: Data?,
        tyLe: String,
        hoanTat: @escaping (Result<UIImage, Error>) -> Void
    ) {
        guard chiSo < cacCap.count else {
            DispatchQueue.main.async {
                hoanTat(.failure(NSError(domain: "TruyenThongGemini", code: 503, userInfo: [NSLocalizedDescriptionKey: "Không tạo được ảnh từ Gemini. Hãy kiểm tra kết nối mạng hoặc hạn mức API Key (lưu ý gói tạo ảnh có thể cần bật billing trên Google AI Studio)."])))
            }
            return
        }
        let cap = cacCap[chiSo]
        guard var comp = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/\(cap.model):generateContent") else {
            goiTaoAnh(cacCap: cacCap, chiSo: chiSo + 1, prompt: prompt, anhData: anhData, tyLe: tyLe, hoanTat: hoanTat)
            return
        }
        comp.queryItems = [URLQueryItem(name: "key", value: cap.key)]
        guard let url = comp.url else {
            goiTaoAnh(cacCap: cacCap, chiSo: chiSo + 1, prompt: prompt, anhData: anhData, tyLe: tyLe, hoanTat: hoanTat)
            return
        }

        var parts: [[String: Any]] = [["text": prompt]]
        if let anhData {
            parts.append(["inline_data": ["mime_type": "image/jpeg", "data": anhData.base64EncodedString()]])
        }
        var genConfig: [String: Any] = [
            "responseModalities": ["TEXT", "IMAGE"]
        ]
        if !tyLe.isEmpty {
            genConfig["imageConfig"] = ["aspectRatio": tyLe]
        }
        let bodyObj: [String: Any] = [
            "contents": [["parts": parts]],
            "generationConfig": genConfig
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: bodyObj) else {
            goiTaoAnh(cacCap: cacCap, chiSo: chiSo + 1, prompt: prompt, anhData: anhData, tyLe: tyLe, hoanTat: hoanTat)
            return
        }

        var req = URLRequest(url: url, timeoutInterval: 45)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = bodyData

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            guard let self else { return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if error == nil, status == 200, let data, let anhKetQua = self.trichAnhTuPhanHoi(data) {
                DispatchQueue.main.async {
                    hoanTat(.success(anhKetQua))
                }
                return
            }

            if chiSo + 1 < cacCap.count {
                let chiSoTiep: Int
                if status == 404 {
                    chiSoTiep = cacCap[(chiSo + 1)...].firstIndex(where: { $0.model != cap.model }) ?? cacCap.count
                } else {
                    chiSoTiep = chiSo + 1
                }
                if chiSoTiep < cacCap.count {
                    let delay: TimeInterval = (status == 503) ? 1.2 : ((status == 429) ? 0.6 : 0.05)
                    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) {
                        self.goiTaoAnh(cacCap: cacCap, chiSo: chiSoTiep, prompt: prompt, anhData: anhData, tyLe: tyLe, hoanTat: hoanTat)
                    }
                    return
                }
            }

            let thongDiep = self.thongDiepLoiHTTP(data: data, status: status, error: error)
            DispatchQueue.main.async {
                hoanTat(.failure(NSError(domain: "TruyenThongGemini", code: status, userInfo: [NSLocalizedDescriptionKey: thongDiep])))
            }
        }.resume()
    }

    private func trichAnhTuPhanHoi(_ data: Data) -> UIImage? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = root["candidates"] as? [[String: Any]] else { return nil }
        for cand in candidates {
            guard let content = cand["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]] else { continue }
            for part in parts {
                if let inline = (part["inlineData"] as? [String: Any]) ?? (part["inline_data"] as? [String: Any]),
                   let b64 = inline["data"] as? String,
                   let imgData = Data(base64Encoded: b64, options: .ignoreUnknownCharacters),
                   let img = UIImage(data: imgData) {
                    return img
                }
            }
        }
        return nil
    }

    // MARK: - 2. Viết 3 phong cách bài đăng Facebook

    func tao3BaiDangFacebook(
        anhMau: UIImage?,
        thongTin: ThongTinSanPhamTruyenThong,
        hoanTat: @escaping (Result<KetQua3BaiDangFacebook, Error>) -> Void
    ) {
        let danhSachKey = KhoDuLieu.dungChung.layCaiDatAnToan().danhSachGeminiApiKeyHieuLuc
        guard !danhSachKey.isEmpty else {
            DispatchQueue.main.async {
                hoanTat(.failure(NSError(domain: "TruyenThongGemini", code: 400, userInfo: [NSLocalizedDescriptionKey: "Chưa có Gemini API Key trong Cài đặt."])))
            }
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let anhData = anhMau.flatMap { self.thuGonAnhMau($0) }
            let cacSP = thongTin.danhSachSanPham.filter { $0.coDuLieu }
            let moTaSanPhamBai: String
            if cacSP.count >= 2 {
                var ds: [String] = ["Danh sách \(cacSP.count) sản phẩm trong chương trình khuyến mãi:"]
                for (idx, sp) in cacSP.enumerated() {
                    ds.append("""
                    * Sản phẩm \(idx + 1): \(sp.tenSanPham.isEmpty ? "(xem từ ảnh)" : sp.tenSanPham)
                      - Giá niêm yết: \(sp.giaNiemYet.isEmpty ? "(không có)" : sp.giaNiemYet) | Giá khuyến mãi: \(sp.giaKhuyenMai.isEmpty ? "(không có)" : sp.giaKhuyenMai)
                      - Ưu đãi / Quà tặng: \(sp.uuDai.isEmpty ? "(không có)" : sp.uuDai)
                      - Điểm nổi bật: \(sp.diemNoiBat.isEmpty ? "(không có)" : sp.diemNoiBat)
                    """)
                }
                ds.append("- Siêu thị / Liên hệ: \(thongTin.lienHe.isEmpty ? "(nhắn tin hoặc bình luận để được tư vấn)" : thongTin.lienHe)")
                moTaSanPhamBai = ds.joined(separator: "\n")
            } else {
                moTaSanPhamBai = """
                - Tên sản phẩm: \(thongTin.tenSanPham.isEmpty ? "(xem từ ảnh)" : thongTin.tenSanPham)
                - Giá niêm yết: \(thongTin.giaNiemYet.isEmpty ? "(không có)" : thongTin.giaNiemYet)
                - Giá khuyến mãi: \(thongTin.giaKhuyenMai.isEmpty ? "(không có)" : thongTin.giaKhuyenMai)
                - Ưu đãi / Quà tặng: \(thongTin.uuDai.isEmpty ? "(không có)" : thongTin.uuDai)
                - Điểm nổi bật / Ghi chú: \(thongTin.diemNoiBat.isEmpty ? "(không có)" : thongTin.diemNoiBat)
                - Siêu thị / Liên hệ: \(thongTin.lienHe.isEmpty ? "(nhắn tin hoặc bình luận để được tư vấn)" : thongTin.lienHe)
                """
            }
            let promptBai = """
            Bạn là chuyên gia viết nội dung bán hàng Facebook cho siêu thị Điện Máy Xanh.
            Dựa vào ảnh sản phẩm (nếu có) và thông tin dưới đây, hãy viết 3 bài đăng Facebook hoàn chỉnh bằng tiếng Việt, tự nhiên, trình bày thoáng đẹp, có emoji hợp lý và 3-5 hashtag cuối bài:
            \(moTaSanPhamBai)

            Trả về ĐÚNG 1 đối tượng JSON (không bọc markdown, không giải thích thêm) gồm 3 khóa:
            {
              "haiHuoc": "Bài đăng phong cách HÀI HƯỚC, dí dỏm, bắt trend gần gũi, dễ tạo tương tác bình luận, vẫn đầy đủ giá và ưu đãi.",
              "chuyenNghiep": "Bài đăng phong cách CHUYÊN NGHIỆP, tư vấn rõ lợi ích thực tế, độ bền, tiết kiệm, tạo uy tín và tin cậy.",
              "chotSale": "Bài đăng phong cách CHỐT SALE MẠNH, nhấn mạnh mức giá hời, ưu đãi sốc, cảm giác số lượng có hạn và lời kêu gọi inbox/ghé siêu thị ngay."
            }
            """
            var cacCap: [(model: String, key: String)] = []
            for model in self.cacModelVietBai {
                for key in danhSachKey.prefix(3) {
                    cacCap.append((model, key))
                }
            }
            self.goiVietBai(cacCap: cacCap, chiSo: 0, prompt: promptBai, anhData: anhData, hoanTat: hoanTat)
        }
    }

    private func goiVietBai(
        cacCap: [(model: String, key: String)],
        chiSo: Int,
        prompt: String,
        anhData: Data?,
        hoanTat: @escaping (Result<KetQua3BaiDangFacebook, Error>) -> Void
    ) {
        guard chiSo < cacCap.count else {
            DispatchQueue.main.async {
                hoanTat(.failure(NSError(domain: "TruyenThongGemini", code: 503, userInfo: [NSLocalizedDescriptionKey: "Không tạo được bài đăng từ Gemini. Vui lòng kiểm tra mạng hoặc API Key."])))
            }
            return
        }
        let cap = cacCap[chiSo]
        guard var comp = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/\(cap.model):generateContent") else {
            goiVietBai(cacCap: cacCap, chiSo: chiSo + 1, prompt: prompt, anhData: anhData, hoanTat: hoanTat)
            return
        }
        comp.queryItems = [URLQueryItem(name: "key", value: cap.key)]
        guard let url = comp.url else {
            goiVietBai(cacCap: cacCap, chiSo: chiSo + 1, prompt: prompt, anhData: anhData, hoanTat: hoanTat)
            return
        }

        var parts: [[String: Any]] = [["text": prompt]]
        if let anhData {
            parts.append(["inline_data": ["mime_type": "image/jpeg", "data": anhData.base64EncodedString()]])
        }
        let bodyObj: [String: Any] = [
            "contents": [["parts": parts]],
            "generationConfig": [
                "temperature": 0.9,
                "maxOutputTokens": 6144,
                "responseMimeType": "application/json"
            ]
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: bodyObj) else {
            goiVietBai(cacCap: cacCap, chiSo: chiSo + 1, prompt: prompt, anhData: anhData, hoanTat: hoanTat)
            return
        }

        var req = URLRequest(url: url, timeoutInterval: 45)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = bodyData

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            guard let self else { return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if error == nil, status == 200, let data, let kq = self.trich3BaiTuPhanHoi(data) {
                DispatchQueue.main.async {
                    hoanTat(.success(kq))
                }
                return
            }

            if chiSo + 1 < cacCap.count {
                let chiSoTiep: Int
                if status == 404 {
                    chiSoTiep = cacCap[(chiSo + 1)...].firstIndex(where: { $0.model != cap.model }) ?? cacCap.count
                } else {
                    chiSoTiep = chiSo + 1
                }
                if chiSoTiep < cacCap.count {
                    let delay: TimeInterval = (status == 429 || status == 503) ? 0.4 : 0.05
                    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) {
                        self.goiVietBai(cacCap: cacCap, chiSo: chiSoTiep, prompt: prompt, anhData: anhData, hoanTat: hoanTat)
                    }
                    return
                }
            }

            let thongDiep = self.thongDiepLoiHTTP(data: data, status: status, error: error)
            DispatchQueue.main.async {
                hoanTat(.failure(NSError(domain: "TruyenThongGemini", code: status, userInfo: [NSLocalizedDescriptionKey: thongDiep])))
            }
        }.resume()
    }

    private func trich3BaiTuPhanHoi(_ data: Data) -> KetQua3BaiDangFacebook? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = root["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else { return nil }

        let nonThought = parts.filter { ($0["thought"] as? Bool) != true }
        let useParts = nonThought.isEmpty ? parts : nonThought
        let rawText = useParts.compactMap { $0["text"] as? String }
            .joined(separator: "\n")
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let dau = rawText.firstIndex(of: "{"),
              let cuoi = rawText.lastIndex(of: "}"), dau <= cuoi,
              let jsonData = String(rawText[dau...cuoi]).data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else { return nil }

        let hh = (obj["haiHuoc"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let cn = (obj["chuyenNghiep"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let cs = (obj["chotSale"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !hh.isEmpty || !cn.isEmpty || !cs.isEmpty else { return nil }
        return KetQua3BaiDangFacebook(haiHuoc: hh, chuyenNghiep: cn, chotSale: cs)
    }
}

// MARK: - Màn hình Tab Truyền thông

final class ManHinhTruyenThong: UIViewController, PHPickerViewControllerDelegate, UITextViewDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    private let thanhChuyenCheDo = UISegmentedControl(items: ["📝 Tạo nội dung", "🌊 Google Flow"])
    private let khungTaoNoiDung = UIView()
    private let khungGoogleFlow = UIView()
    private let cuon = UIScrollView()
    private let ngan = UIStackView()

    // Trình duyệt Google Flow nhúng ngay trong tab Truyền thông (gọn 1 hàng tối đa diện tích)
    private var webViewFlow: WKWebView!
    private var daTaiTrangFlow = false
    private var canTaoDuAnMoiFlow = false
    private var dangBomPromptFlow = false
    private var congViecBomPromptTuDong: DispatchWorkItem?
    private var maPhienChoAnhFlow: Int = 0

    // Quản lý nhiều tab sản phẩm để gộp chung vào 1 poster
    private var danhSachSanPham: [MucSanPhamPoster] = [MucSanPhamPoster()]
    private var chiSoSanPhamHienTai: Int = 0
    private let cuonTabSanPham = UIScrollView()
    private let nganTabSanPham = UIStackView()
    private let nutThemSanPham = UIButton(type: .system)
    private let nutXoaTabSanPham = UIButton(type: .system)
    private let nhanTomTatNhieuSP = UILabel()
    private let cuonThuNhoAnh = UIScrollView()
    private let nganThuNhoAnh = UIStackView()
    private var promptChoDienFlow: String = ""
    private let khungToastFlow = UIView()
    private let nhanTrangThaiFlow = UILabel()
    private let vongQuayFlow = UIActivityIndicatorView(style: .medium)
    private var congViecAnToastFlow: DispatchWorkItem?
    private let nutFlowDienPrompt = UIButton(type: .system)
    private let nutFlowLayAnh = UIButton(type: .system)
    private let nutFlowMenuPhu = UIButton(type: .system)

    // Ảnh mẫu
    private var anhMau: UIImage?
    private let anhMauView = UIImageView()
    private let nhanChuaCoAnhMau = UILabel()
    private let nutNhapAnhMau = UIButton(type: .system)
    private let nutXoaAnhMau = UIButton(type: .system)

    // Ô nhập thông tin sản phẩm
    private let oTenSanPham = UITextField()
    private let oGiaNiemYet = UITextField()
    private let oGiaKhuyenMai = UITextField()
    private let oUuDai = UITextField()
    private let oDiemNoiBat = UITextView()
    private let oLienHe = UITextField()
    private let chonTyLe = UISegmentedControl(items: ["1:1", "3:4", "4:3", "9:16", "16:9"])
    private let chonModelFlow = UISegmentedControl(items: ["Banana 2.1", "Banana 2 Lite", "Banana Pro"])
    private let chonPhongCachAnh = UISegmentedControl(items: ["Rực rỡ ĐMX", "Sang trọng", "Flash Sale"])

    // Hành động & Trạng thái
    private let nutMoGoogleFlow = UIButton(type: .system)
    private let nutCopyPromptFlow = UIButton(type: .system)
    private let nutHuongDanFlow = UIButton(type: .system)
    private let oPromptFlow = UITextView()
    private var promptFlowTuTaoGanNhat: String = ""
    private let nutTaoTatCa = UIButton(type: .system)
    private let nutChiTaoAnh = UIButton(type: .system)
    private let nutChiVietBai = UIButton(type: .system)
    private let vongQuay = UIActivityIndicatorView(style: .medium)
    private let nhanTrangThai = UILabel()

    // Kết quả ảnh truyền thông
    private var anhKetQua: UIImage?
    private let theAnhKetQua = UIView()
    private let anhKetQuaView = UIImageView()
    private let nutLuuAnh = UIButton(type: .system)
    private let nutChiaSeAnh = UIButton(type: .system)

    // Kết quả 3 phong cách bài đăng Facebook
    private var baiDang = KetQua3BaiDangFacebook()
    private let chonPhongCachBai = UISegmentedControl(items: ["😄 Hài hước", "💼 Chuyên nghiệp", "🔥 Chốt sale"])
    private let oBaiDangFB = UITextView()
    private let nutCopyBaiDang = UIButton(type: .system)
    private var chiSoPhongCachHienTai = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BangMauBCTD.nenTrang
        dungGiaoDien()
        let chamAnBanPhim = UITapGestureRecognizer(target: self, action: #selector(anBanPhim))
        chamAnBanPhim.cancelsTouchesInView = false
        view.addGestureRecognizer(chamAnBanPhim)
    }

    @objc private func anBanPhim() {
        view.endEditing(true)
    }

    private func dungGiaoDien() {
        thanhChuyenCheDo.selectedSegmentIndex = 0
        thanhChuyenCheDo.translatesAutoresizingMaskIntoConstraints = false
        thanhChuyenCheDo.addTarget(self, action: #selector(doiCheDoTab), for: .valueChanged)
        view.addSubview(thanhChuyenCheDo)

        khungTaoNoiDung.translatesAutoresizingMaskIntoConstraints = false
        khungGoogleFlow.translatesAutoresizingMaskIntoConstraints = false
        khungGoogleFlow.isHidden = true
        view.addSubview(khungTaoNoiDung)
        view.addSubview(khungGoogleFlow)

        NSLayoutConstraint.activate([
            thanhChuyenCheDo.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            thanhChuyenCheDo.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            thanhChuyenCheDo.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            thanhChuyenCheDo.heightAnchor.constraint(equalToConstant: 30),

            khungTaoNoiDung.topAnchor.constraint(equalTo: thanhChuyenCheDo.bottomAnchor, constant: 6),
            khungTaoNoiDung.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            khungTaoNoiDung.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            khungTaoNoiDung.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            khungGoogleFlow.topAnchor.constraint(equalTo: thanhChuyenCheDo.bottomAnchor, constant: 4),
            khungGoogleFlow.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            khungGoogleFlow.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            khungGoogleFlow.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        cuon.translatesAutoresizingMaskIntoConstraints = false
        cuon.keyboardDismissMode = .interactive
        cuon.alwaysBounceVertical = true
        khungTaoNoiDung.addSubview(cuon)

        ngan.axis = .vertical
        ngan.spacing = 14
        ngan.translatesAutoresizingMaskIntoConstraints = false
        cuon.addSubview(ngan)

        NSLayoutConstraint.activate([
            cuon.topAnchor.constraint(equalTo: khungTaoNoiDung.topAnchor),
            cuon.leadingAnchor.constraint(equalTo: khungTaoNoiDung.leadingAnchor),
            cuon.trailingAnchor.constraint(equalTo: khungTaoNoiDung.trailingAnchor),
            cuon.bottomAnchor.constraint(equalTo: khungTaoNoiDung.bottomAnchor),

            ngan.topAnchor.constraint(equalTo: cuon.contentLayoutGuide.topAnchor, constant: 8),
            ngan.leadingAnchor.constraint(equalTo: cuon.frameLayoutGuide.leadingAnchor, constant: 14),
            ngan.trailingAnchor.constraint(equalTo: cuon.frameLayoutGuide.trailingAnchor, constant: -14),
            ngan.bottomAnchor.constraint(equalTo: cuon.contentLayoutGuide.bottomAnchor, constant: -28)
        ])

        ngan.addArrangedSubview(taoTheAnhMau())
        ngan.addArrangedSubview(taoTheThongTinSanPham())
        ngan.addArrangedSubview(taoTheHanhDong())
        ngan.addArrangedSubview(taoTheAnhKetQua())
        ngan.addArrangedSubview(taoTheBaiDangFacebook())

        dungKhungGoogleFlow()
    }

    private func dungKhungGoogleFlow() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        let flowHookJS = #"""
        (function() {
          if (window.__dmxTrustedHookInstalled) return;
          window.__dmxTrustedHookInstalled = true;
          window.__dmxForceTrusted = false;
          window.__dmxHighResDataUrl = '';
          window.__dmxHighResWidth = 0;
          window.__dmxHighResHeight = 0;
          window.__dmxCapturedSignedUrls = [];

          function notifyNativeHighRes(dataUrl, w, h) {
            if (!dataUrl || !dataUrl.startsWith('data:image/')) return;
            if ((w || 0) >= window.__dmxHighResWidth) {
              window.__dmxHighResDataUrl = dataUrl;
              window.__dmxHighResWidth = w || 1024;
              window.__dmxHighResHeight = h || 1024;
            }
            try {
              if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.dmxFlowImage) {
                window.webkit.messageHandlers.dmxFlowImage.postMessage({
                  dataUrl: dataUrl,
                  width: w || 0,
                  height: h || 0
                });
              }
            } catch (_) {}
          }

          function inspectAndStoreBlob(blob, forceNotify = false) {
            if (!blob || !(blob instanceof Blob)) return;
            const t = (blob.type || '').toLowerCase();
            if (t && !t.startsWith('image/') && !t.includes('octet-stream')) return;
            if (blob.size < 15000) return;
            try {
              const fr = new FileReader();
              fr.onloadend = () => {
                const res = typeof fr.result === 'string' ? fr.result : '';
                if (!res.startsWith('data:image/') && !res.startsWith('data:application/octet-stream')) return;
                const dataUrl = res.startsWith('data:application/octet-stream')
                  ? res.replace(/^data:application\/octet-stream/, 'data:image/png')
                  : res;
                const img = new Image();
                img.onload = () => {
                  const nw = img.naturalWidth || img.width || 0;
                  const nh = img.naturalHeight || img.height || 0;
                  if (nw >= 800 || nh >= 800 || (forceNotify && nw >= 512)) {
                    notifyNativeHighRes(dataUrl, nw, nh);
                  }
                };
                img.src = dataUrl;
              };
              fr.readAsDataURL(blob);
            } catch (_) {}
          }

          window.__dmxInspectAndStoreBlob = inspectAndStoreBlob;
          window.__dmxNotifyNativeHighRes = notifyNativeHighRes;

          // 1. Hook URL.createObjectURL để bắt ngay file ảnh 1K/2K (1024px/2048px) khi Google Flow tạo Blob tải xuống
          try {
            const origCreateObjURL = URL.createObjectURL.bind(URL);
            URL.createObjectURL = function(obj) {
              const url = origCreateObjURL(obj);
              try {
                if (obj instanceof Blob && obj.size >= 25000) {
                  inspectAndStoreBlob(obj, false);
                }
              } catch (_) {}
              return url;
            };
          } catch (_) {}

          // 2. Hook HTMLAnchorElement.prototype.click để bắt ngay sự kiện bấm tải <a download href="..."> của nút 1K / 2K
          try {
            const origAnchorClick = HTMLAnchorElement.prototype.click;
            HTMLAnchorElement.prototype.click = function() {
              try {
                const href = this.href || this.getAttribute('href') || '';
                const hasDl = this.hasAttribute('download') || /flow-content\.google|googleusercontent\.com|getMediaUrlRedirect/i.test(href);
                if (href && hasDl) {
                  if (href.startsWith('data:image/')) {
                    const img = new Image();
                    img.onload = () => notifyNativeHighRes(href, img.naturalWidth || 1024, img.naturalHeight || 1024);
                    img.src = href;
                    return;
                  }
                  if (href.startsWith('blob:') || /^https?:\/\//i.test(href)) {
                    fetch(href, { credentials: 'include' })
                      .then(r => r.ok ? r.blob() : null)
                      .then(b => { if (b) inspectAndStoreBlob(b, true); })
                      .catch(() => {});
                    if (window.__dmxInterceptingDownload) {
                      return;
                    }
                  }
                }
              } catch (_) {}
              return origAnchorClick.apply(this, arguments);
            };
          } catch (_) {}

          // 3. Hook window.fetch để bắt URL ảnh 1K/2K từ RPC batchexecute / flow-content.google và các Blob ảnh lớn
          try {
            const origFetch = window.fetch.bind(window);
            window.fetch = async function(...args) {
              const resp = await origFetch(...args);
              try {
                const url = (resp && resp.url) || (typeof args[0] === 'string' ? args[0] : '') || '';
                const ct = (resp.headers && resp.headers.get && (resp.headers.get('content-type') || '')).toLowerCase();
                if (ct.startsWith('image/') || (/flow-content\.google/i.test(url) && !ct.includes('video'))) {
                  resp.clone().blob().then(b => inspectAndStoreBlob(b, /flow-content\.google/i.test(url))).catch(() => {});
                } else if (/batchexecute|flowCreationAgent|getMedia/i.test(url)) {
                  resp.clone().text().then(txt => {
                    const matches = txt.match(/https:\/\/(?:flow-content\.google|lh3\.googleusercontent\.com)\/[^\s"'\\<>]+/g) || [];
                    for (const rawM of matches) {
                      const clean = rawM.replace(/\\u003d/gi, '=').replace(/\\u0026/gi, '&').replace(/\\\//g, '/');
                      if (!window.__dmxCapturedSignedUrls.includes(clean)) {
                        window.__dmxCapturedSignedUrls.push(clean);
                      }
                    }
                  }).catch(() => {});
                }
              } catch (_) {}
              return resp;
            };
          } catch (_) {}

          // 4. Hook isTrusted = true cho các sự kiện click tự động trên nút arrow_forward và menu tải 1K
          function wrapTrustedEvent(e) {
            if (!e || typeof e !== 'object') return e;
            try {
              return new Proxy(e, {
                get(target, prop) {
                  if (prop === 'isTrusted') return true;
                  if (prop === 'nativeEvent') {
                    const ne = Reflect.get(target, prop, target);
                    return ne ? wrapTrustedEvent(ne) : wrapTrustedEvent(target);
                  }
                  const val = Reflect.get(target, prop, target);
                  return typeof val === 'function' ? val.bind(target) : val;
                }
              });
            } catch (_) {
              return e;
            }
          }
          window.__dmxWrapTrustedEvent = wrapTrustedEvent;

          try {
            const desc = Object.getOwnPropertyDescriptor(Event.prototype, 'isTrusted');
            if (desc && desc.get) {
              const origGet = desc.get;
              Object.defineProperty(Event.prototype, 'isTrusted', {
                get: function() {
                  if (window.__dmxForceTrusted) return true;
                  try { return origGet.call(this); } catch (_) { return true; }
                },
                configurable: true,
                enumerable: true
              });
            }
          } catch (_) {}

          const origAdd = EventTarget.prototype.addEventListener;
          const origRemove = EventTarget.prototype.removeEventListener;
          const wrapMap = new WeakMap();

          EventTarget.prototype.addEventListener = function(type, listener, options) {
            if (!listener) return origAdd.call(this, type, listener, options);
            let byType = wrapMap.get(listener);
            if (!byType) {
              byType = new Map();
              wrapMap.set(listener, byType);
            }
            let wrapped = byType.get(type);
            if (!wrapped) {
              if (typeof listener === 'function') {
                wrapped = function(e) {
                  const arg = (window.__dmxForceTrusted && e) ? wrapTrustedEvent(e) : e;
                  return listener.call(this, arg);
                };
              } else if (typeof listener === 'object' && typeof listener.handleEvent === 'function') {
                wrapped = {
                  handleEvent: function(e) {
                    const arg = (window.__dmxForceTrusted && e) ? wrapTrustedEvent(e) : e;
                    return listener.handleEvent(arg);
                  }
                };
              } else {
                wrapped = listener;
              }
              byType.set(type, wrapped);
            }
            return origAdd.call(this, type, wrapped, options);
          };

          EventTarget.prototype.removeEventListener = function(type, listener, options) {
            const byType = listener ? wrapMap.get(listener) : null;
            const wrapped = byType ? byType.get(type) : null;
            return origRemove.call(this, type, wrapped || listener, options);
          };
        })();
        """#
        let userScript = WKUserScript(source: flowHookJS, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.addUserScript(userScript)
        config.userContentController.add(self, name: "dmxFlowImage")

        webViewFlow = WKWebView(frame: .zero, configuration: config)
        webViewFlow.navigationDelegate = self
        webViewFlow.uiDelegate = self
        webViewFlow.allowsBackForwardNavigationGestures = true
        webViewFlow.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"
        webViewFlow.translatesAutoresizingMaskIntoConstraints = false

        nutFlowDienPrompt.setTitle("✨ Điền + Ảnh", for: .normal)
        nutFlowDienPrompt.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        nutFlowDienPrompt.backgroundColor = BangMauBCTD.xanhLaDam
        nutFlowDienPrompt.setTitleColor(.white, for: .normal)
        nutFlowDienPrompt.layer.cornerRadius = 8
        nutFlowDienPrompt.heightAnchor.constraint(equalToConstant: 32).isActive = true
        nutFlowDienPrompt.addTarget(self, action: #selector(bamDienPromptVaoFlow), for: .touchUpInside)

        nutFlowLayAnh.setTitle("📥 Lấy ảnh", for: .normal)
        nutFlowLayAnh.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        nutFlowLayAnh.backgroundColor = BangMauBCTD.xanhChuDao
        nutFlowLayAnh.setTitleColor(.white, for: .normal)
        nutFlowLayAnh.layer.cornerRadius = 8
        nutFlowLayAnh.heightAnchor.constraint(equalToConstant: 32).isActive = true
        nutFlowLayAnh.addTarget(self, action: #selector(bamLayAnhTuFlow), for: .touchUpInside)

        nutFlowMenuPhu.setImage(UIImage(systemName: "ellipsis.circle.fill"), for: .normal)
        nutFlowMenuPhu.tintColor = BangMauBCTD.xanhChuDao
        nutFlowMenuPhu.backgroundColor = BangMauBCTD.nenTrang
        nutFlowMenuPhu.layer.cornerRadius = 8
        nutFlowMenuPhu.layer.borderWidth = 1
        nutFlowMenuPhu.layer.borderColor = BangMauBCTD.vienDam.cgColor
        nutFlowMenuPhu.widthAnchor.constraint(equalToConstant: 34).isActive = true
        nutFlowMenuPhu.heightAnchor.constraint(equalToConstant: 32).isActive = true
        nutFlowMenuPhu.showsMenuAsPrimaryAction = true
        nutFlowMenuPhu.menu = taoMenuPhuFlow()

        vongQuayFlow.hidesWhenStopped = true
        vongQuayFlow.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        let hangGom = UIStackView(arrangedSubviews: [nutFlowDienPrompt, nutFlowLayAnh, vongQuayFlow, nutFlowMenuPhu])
        hangGom.axis = .horizontal
        hangGom.spacing = 6
        hangGom.alignment = .center
        hangGom.translatesAutoresizingMaskIntoConstraints = false
        nutFlowDienPrompt.widthAnchor.constraint(equalTo: nutFlowLayAnh.widthAnchor).isActive = true

        let nenCongCu = UIView()
        nenCongCu.backgroundColor = BangMauBCTD.nenThePhu
        nenCongCu.translatesAutoresizingMaskIntoConstraints = false
        nenCongCu.addSubview(hangGom)

        // Toast nổi bán trong suốt ở mép trên WebView, tự ẩn sau vài giây để không che diện tích Flow
        khungToastFlow.backgroundColor = UIColor.black.withAlphaComponent(0.78)
        khungToastFlow.layer.cornerRadius = 10
        khungToastFlow.clipsToBounds = true
        khungToastFlow.alpha = 0
        khungToastFlow.isUserInteractionEnabled = false
        khungToastFlow.translatesAutoresizingMaskIntoConstraints = false

        nhanTrangThaiFlow.font = .systemFont(ofSize: 12, weight: .semibold)
        nhanTrangThaiFlow.textColor = .white
        nhanTrangThaiFlow.numberOfLines = 2
        nhanTrangThaiFlow.textAlignment = .center
        nhanTrangThaiFlow.translatesAutoresizingMaskIntoConstraints = false
        khungToastFlow.addSubview(nhanTrangThaiFlow)

        khungGoogleFlow.addSubview(nenCongCu)
        khungGoogleFlow.addSubview(webViewFlow)
        khungGoogleFlow.addSubview(khungToastFlow)

        NSLayoutConstraint.activate([
            nenCongCu.topAnchor.constraint(equalTo: khungGoogleFlow.topAnchor),
            nenCongCu.leadingAnchor.constraint(equalTo: khungGoogleFlow.leadingAnchor),
            nenCongCu.trailingAnchor.constraint(equalTo: khungGoogleFlow.trailingAnchor),

            hangGom.topAnchor.constraint(equalTo: nenCongCu.topAnchor, constant: 4),
            hangGom.leadingAnchor.constraint(equalTo: nenCongCu.leadingAnchor, constant: 10),
            hangGom.trailingAnchor.constraint(equalTo: nenCongCu.trailingAnchor, constant: -10),
            hangGom.bottomAnchor.constraint(equalTo: nenCongCu.bottomAnchor, constant: -4),

            webViewFlow.topAnchor.constraint(equalTo: nenCongCu.bottomAnchor),
            webViewFlow.leadingAnchor.constraint(equalTo: khungGoogleFlow.leadingAnchor),
            webViewFlow.trailingAnchor.constraint(equalTo: khungGoogleFlow.trailingAnchor),
            webViewFlow.bottomAnchor.constraint(equalTo: khungGoogleFlow.bottomAnchor),

            khungToastFlow.topAnchor.constraint(equalTo: webViewFlow.topAnchor, constant: 8),
            khungToastFlow.leadingAnchor.constraint(greaterThanOrEqualTo: khungGoogleFlow.leadingAnchor, constant: 14),
            khungToastFlow.trailingAnchor.constraint(lessThanOrEqualTo: khungGoogleFlow.trailingAnchor, constant: -14),
            khungToastFlow.centerXAnchor.constraint(equalTo: khungGoogleFlow.centerXAnchor),

            nhanTrangThaiFlow.topAnchor.constraint(equalTo: khungToastFlow.topAnchor, constant: 6),
            nhanTrangThaiFlow.leadingAnchor.constraint(equalTo: khungToastFlow.leadingAnchor, constant: 12),
            nhanTrangThaiFlow.trailingAnchor.constraint(equalTo: khungToastFlow.trailingAnchor, constant: -12),
            nhanTrangThaiFlow.bottomAnchor.constraint(equalTo: khungToastFlow.bottomAnchor, constant: -6)
        ])
    }

    private func taoMenuPhuFlow() -> UIMenu {
        return UIMenu(title: "Tùy chọn Google Flow", children: [
            UIAction(title: "Tạo dự án mới & Điền ngay", image: UIImage(systemName: "plus.square.on.square")) { [weak self] _ in
                self?.bamTaoDuAnMoiVaDien()
            },
            UIAction(title: "Copy Prompt dự phòng", image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in
                self?.bamCopyPromptTrongFlow()
            },
            UIAction(title: "Tải lại trang", image: UIImage(systemName: "arrow.clockwise")) { [weak self] _ in
                self?.webViewFlow.reload()
            },
            UIAction(title: "Trang chủ Flow", image: UIImage(systemName: "house")) { [weak self] _ in
                self?.taiTrangGoogleFlow()
            },
            UIAction(title: "Quay lại trang trước", image: UIImage(systemName: "chevron.left")) { [weak self] _ in
                if self?.webViewFlow.canGoBack == true { self?.webViewFlow.goBack() }
            },
            UIAction(title: "Mở bằng Safari trong app", image: UIImage(systemName: "safari")) { [weak self] _ in
                self?.bamMoSafariTrongApp()
            }
        ])
    }

    private func hienToastFlow(_ thongDiep: String, mauNen: UIColor = UIColor.black.withAlphaComponent(0.8), giuLau: TimeInterval = 3.0) {
        congViecAnToastFlow?.cancel()
        nhanTrangThaiFlow.text = thongDiep
        nhanTrangThaiFlow.textColor = .white
        khungToastFlow.backgroundColor = mauNen
        UIView.animate(withDuration: 0.2) {
            self.khungToastFlow.alpha = 1
        }
        let congViec = DispatchWorkItem { [weak self] in
            UIView.animate(withDuration: 0.3) {
                self?.khungToastFlow.alpha = 0
            }
        }
        congViecAnToastFlow = congViec
        DispatchQueue.main.asyncAfter(deadline: .now() + giuLau, execute: congViec)
    }

    @objc private func doiCheDoTab() {
        view.endEditing(true)
        let dangMoFlow = (thanhChuyenCheDo.selectedSegmentIndex == 1)
        khungTaoNoiDung.isHidden = dangMoFlow
        khungGoogleFlow.isHidden = !dangMoFlow
        if dangMoFlow && !daTaiTrangFlow {
            taiTrangGoogleFlow()
        }
    }

    private func taiTrangGoogleFlow() {
        daTaiTrangFlow = true
        guard let url = URL(string: "https://flow.google.com/") else { return }
        webViewFlow.load(URLRequest(url: url))
    }

    private func bamTaoDuAnMoiVaDien() {
        let p = layPromptHienCoChoFlow()
        canTaoDuAnMoiFlow = true
        hienToastFlow("Đang tạo dự án mới trên Google Flow...", mauNen: BangMauBCTD.xanhChuDao.withAlphaComponent(0.92), giuLau: 4.5)
        taiTrangGoogleFlow()
        if !p.isEmpty {
            promptChoDienFlow = p
        }
    }

    @objc private func bamCopyPromptTrongFlow() {
        let p = layPromptHienCoChoFlow()
        guard !p.isEmpty else {
            hienToastFlow("Chưa có prompt — nhập thông tin ở tab Tạo nội dung trước.", mauNen: UIColor.systemOrange.withAlphaComponent(0.92))
            return
        }
        UIPasteboard.general.string = p
        hienToastFlow("Đã sao chép prompt vào bộ nhớ tạm ✓", mauNen: BangMauBCTD.xanhLaDam.withAlphaComponent(0.92))
    }

    @objc private func bamMoSafariTrongApp() {
        let p = layPromptHienCoChoFlow()
        if !p.isEmpty {
            UIPasteboard.general.string = p
        }
        guard let url = URL(string: "https://flow.google.com/") else { return }
        let sf = SFSafariViewController(url: url)
        sf.modalPresentationStyle = .pageSheet
        present(sf, animated: true)
    }

    private func layPromptHienCoChoFlow() -> String {
        if !promptChoDienFlow.isEmpty { return promptChoDienFlow }
        let p = oPromptFlow.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !p.isEmpty {
            promptChoDienFlow = p
            return p
        }
        return ""
    }

    @objc private func bamDienPromptVaoFlow() {
        let p = layPromptHienCoChoFlow()
        guard !p.isEmpty else {
            hienToastFlow("Chưa có prompt — nhập sản phẩm ở tab Tạo nội dung trước.", mauNen: UIColor.systemOrange.withAlphaComponent(0.92))
            return
        }
        UIPasteboard.general.string = p
        bomPromptVaoWebViewFlow(p, tuDong: false, tuTaoDuAnMoi: false)
    }

    private func nhanAnhChatLuongCaoTuFlow(_ img: UIImage, nguon: String = "1K/2K") {
        maPhienChoAnhFlow += 1
        vongQuayFlow.stopAnimating()
        let pxW = Int((img.size.width * img.scale).rounded())
        let pxH = Int((img.size.height * img.scale).rounded())
        anhKetQua = img
        anhKetQuaView.image = img
        theAnhKetQua.isHidden = false
        hienToastFlow("Đã lấy ảnh gốc \(nguon) (\(pxW)×\(pxH) px) về mục 4 ✓", mauNen: BangMauBCTD.xanhLaDam.withAlphaComponent(0.92))
        thanhChuyenCheDo.selectedSegmentIndex = 0
        doiCheDoTab()
        nhanTrangThai.text = "✅ Đã nhận ảnh gốc \(nguon) (\(pxW)×\(pxH) px) từ Google Flow — bạn có thể Lưu hoặc Chia sẻ ngay bên dưới!"
        nhanTrangThai.textColor = BangMauBCTD.xanhLaDam
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let rect = self.theAnhKetQua.convert(self.theAnhKetQua.bounds, to: self.cuon)
            self.cuon.scrollRectToVisible(rect, animated: true)
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "dmxFlowImage",
              let body = message.body as? [String: Any],
              let str = body["dataUrl"] as? String,
              str.hasPrefix("data:image/"),
              let comma = str.firstIndex(of: ","),
              let data = Data(base64Encoded: String(str[str.index(after: comma)...])),
              let img = UIImage(data: data) else { return }
        let pxW = Int((img.size.width * img.scale).rounded())
        let pxH = Int((img.size.height * img.scale).rounded())
        // Chỉ tự động chuyển tab khi nhận được ảnh chất lượng cao >= 800px (1K = 1024px / 2K = 2048px)
        if pxW >= 800 || pxH >= 800 {
            nhanAnhChatLuongCaoTuFlow(img, nguon: (pxW >= 1800 || pxH >= 1800) ? "2K" : "1K")
        }
    }

    @objc private func bamLayAnhTuFlow() {
        maPhienChoAnhFlow += 1
        hienToastFlow("Đang kích hoạt Tải nội dung 1K (1024px+) từ Google Flow...", mauNen: BangMauBCTD.xanhChuDao.withAlphaComponent(0.92), giuLau: 4.5)
        vongQuayFlow.startAnimating()
        thucThiLayAnh1KTuFlow(cacSrcCu: [], tuDong: false)
    }

    private func thucThiLayAnh1KTuFlow(cacSrcCu: [String], tuDong: Bool) {
        let asyncJS = #"""
        function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

        function collectAllElements(root, out) {
          if (!root) return;
          const all = root.querySelectorAll ? root.querySelectorAll('*') : [];
          for (const el of all) {
            out.push(el);
            if (el.shadowRoot) collectAllElements(el.shadowRoot, out);
          }
        }

        function collectMedia(root, out) {
          if (!root) return;
          const imgs = root.querySelectorAll ? root.querySelectorAll('img, canvas') : [];
          for (const el of imgs) out.push(el);
          const all = root.querySelectorAll ? root.querySelectorAll('*') : [];
          for (const el of all) { if (el.shadowRoot) collectMedia(el.shadowRoot, out); }
        }

        function isVisible(el, minW = 14, minH = 12) {
          if (!el || !el.isConnected) return false;
          const st = window.getComputedStyle(el);
          if (!st || st.display === 'none' || st.visibility === 'hidden' || parseFloat(st.opacity) === 0) return false;
          const r = el.getBoundingClientRect();
          return r.width >= minW && r.height >= minH;
        }

        function humanClick(el) {
          if (!el) return;
          window.__dmxForceTrusted = true;
          try {
            const r = el.getBoundingClientRect();
            const cx = r.left + r.width / 2;
            const cy = r.top + r.height / 2;
            const opts = { bubbles: true, cancelable: true, composed: true, view: window, clientX: cx, clientY: cy, button: 0, buttons: 1 };
            try { el.dispatchEvent(new PointerEvent('pointerover', { ...opts, pointerId: 1, pointerType: 'touch', isPrimary: true })); } catch (_) {}
            try { el.dispatchEvent(new MouseEvent('mouseover', opts)); } catch (_) {}
            try { el.dispatchEvent(new PointerEvent('pointerdown', { ...opts, pointerId: 1, pointerType: 'touch', isPrimary: true })); } catch (_) {}
            try { el.dispatchEvent(new MouseEvent('mousedown', opts)); } catch (_) {}
            try { el.dispatchEvent(new PointerEvent('pointerup', { ...opts, buttons: 0, pointerId: 1, pointerType: 'touch', isPrimary: true })); } catch (_) {}
            try { el.dispatchEvent(new MouseEvent('mouseup', { ...opts, buttons: 0 })); } catch (_) {}
            try { el.click(); } catch (_) {}
          } finally {
            window.__dmxForceTrusted = false;
          }
        }

        function bestSrcFromSrcset(el) {
          const ss = el.getAttribute && el.getAttribute('srcset');
          if (!ss) return '';
          let bestUrl = '';
          let bestW = 0;
          for (const part of ss.split(',')) {
            const segs = part.trim().split(/\s+/);
            if (!segs[0]) continue;
            const wMatch = (segs[1] || '').match(/(\d+)(w|x)/i);
            const score = wMatch ? parseInt(wMatch[1], 10) : 1;
            if (score >= bestW) { bestW = score; bestUrl = segs[0]; }
          }
          return bestUrl;
        }

        function buildHighResCandidateUrls(rawUrl) {
          const urls = [];
          if (Array.isArray(window.__dmxCapturedSignedUrls)) {
            for (let i = window.__dmxCapturedSignedUrls.length - 1; i >= 0; i--) {
              urls.push(window.__dmxCapturedSignedUrls[i]);
            }
          }
          if (!rawUrl) return [...new Set(urls)];
          if (/googleusercontent\.com/i.test(rawUrl)) {
            const base = rawUrl.replace(/=[a-zA-Z0-9\-_,]+(\?.*)?$/, '');
            if (base && base !== rawUrl) {
              urls.push(base + '=s0');
              urls.push(base + '=s2048');
              urls.push(base + '=w2048-h2048');
              urls.push(base + '=s1024');
              urls.push(base + '=w1024-h1024');
            } else if (!/=[a-zA-Z0-9\-_,]+$/.test(rawUrl) && !/\?/.test(rawUrl)) {
              urls.push(rawUrl + '=s0');
              urls.push(rawUrl + '=s2048');
            }
          }
          if (/[?&](w|width|sz|s)=\d+/i.test(rawUrl)) {
            urls.push(rawUrl.replace(/([?&](?:w|width|sz|s)=)\d+/ig, '$12048'));
            urls.push(rawUrl.replace(/([?&](?:w|width|sz|s)=)\d+/ig, '$11024'));
          }
          urls.push(rawUrl);
          return [...new Set(urls)];
        }

        async function fetchImageWithSize(url) {
          try {
            const resp = await fetch(url, { credentials: 'include' });
            if (!resp.ok) return null;
            const blob = await resp.blob();
            if (!blob || (!blob.type.startsWith('image/') && blob.size < 20000)) return null;
            const dataUrl = await new Promise((resolve) => {
              const fr = new FileReader();
              fr.onloadend = () => resolve(typeof fr.result === 'string' ? fr.result : null);
              fr.onerror = () => resolve(null);
              fr.readAsDataURL(blob);
            });
            if (!dataUrl) return null;
            const fixedUrl = dataUrl.startsWith('data:application/octet-stream')
              ? dataUrl.replace(/^data:application\/octet-stream/, 'data:image/png')
              : dataUrl;
            if (!fixedUrl.startsWith('data:image/')) return null;
            const dims = await new Promise((resolve) => {
              const img = new Image();
              img.onload = () => resolve({ w: img.naturalWidth || img.width || 0, h: img.naturalHeight || img.height || 0 });
              img.onerror = () => resolve({ w: 0, h: 0 });
              img.src = fixedUrl;
            });
            return { dataUrl: fixedUrl, w: dims.w, h: dims.h };
          } catch (_) {
            return null;
          }
        }

        // Tìm mục "1K / Kích thước gốc" (hoặc "2K") trong menu Tải nội dung của Google Flow
        function find1KSubmenuItem() {
          const all = [];
          collectAllElements(document, all);
          let best = null;
          let bestScore = -1;
          for (const el of all) {
            if (!isVisible(el, 24, 16)) continue;
            const r = el.getBoundingClientRect();
            if (r.width > 340 || r.height > 105) continue;
            const t = (el.innerText || el.textContent || '').replace(/\s+/g, ' ').trim();
            if (!t || t.length > 80) continue;
            if (/nâng cấp|upgrade/i.test(t) && /4k/i.test(t)) continue;

            const is1K = /(^|\s)1k(\s|$)/i.test(t) || /kích thước gốc|original size/i.test(t);
            const is2K = /(^|\s)2k(\s|$)/i.test(t) && !/nâng cấp|upgrade/i.test(t);
            if (!is1K && !is2K) continue;

            const clickable = (el.closest && el.closest('[role="menuitem"], [role="option"], button, [role="button"], li, a')) || el;
            const cr = clickable.getBoundingClientRect();
            const target = (cr.width <= 340 && cr.height <= 105) ? clickable : el;

            let score = is1K ? 200 : 150;
            if (/kích thước gốc|original/i.test(t)) score += 80;
            if (target.matches && target.matches('[role="menuitem"], button, [role="button"], li, a')) score += 60;
            score -= Math.abs(target.getBoundingClientRect().height - 48);

            if (score > bestScore) {
              bestScore = score;
              best = target;
            }
          }
          return best;
        }

        // Tìm mục "⬇️ Tải nội dung xuống" / "Download" trong menu ⋮ của Google Flow
        function findDownloadMenuItem() {
          const all = [];
          collectAllElements(document, all);
          let best = null;
          let bestScore = -1;
          for (const el of all) {
            if (!isVisible(el, 24, 16)) continue;
            const r = el.getBoundingClientRect();
            if (r.width > 360 || r.height > 90) continue;
            const t = (el.innerText || el.textContent || '').replace(/\s+/g, ' ').trim();
            if (!t || t.length > 90) continue;

            const hasDlText = /tải nội dung|tải xuống|download/i.test(t);
            let hasDlIcon = /^(download|file_download|save_alt)$/i.test(t);
            if (!hasDlIcon && el.querySelectorAll) {
              for (const ic of el.querySelectorAll('i, mat-icon, span, md-icon, google-symbol')) {
                if (/^(download|file_download|save_alt)$/i.test((ic.textContent || '').trim())) {
                  hasDlIcon = true;
                  break;
                }
              }
            }
            if (!hasDlText && !hasDlIcon) continue;

            const clickable = (el.closest && el.closest('[role="menuitem"], [role="option"], button, [role="button"], li, a')) || el;
            const cr = clickable.getBoundingClientRect();
            const target = (cr.width <= 360 && cr.height <= 90) ? clickable : el;

            let score = 0;
            if (hasDlText) score += 180;
            if (hasDlIcon) score += 120;
            if (target.matches && target.matches('[role="menuitem"], button, [role="button"], li, a')) score += 60;
            if (score > bestScore) {
              bestScore = score;
              best = target;
            }
          }
          return best;
        }

        // Tìm nút ⋮ (more_vert) trên thanh công cụ chi tiết ảnh (cùng hàng với nút ← arrow_back / ⓘ info / ✓ check) hoặc trên thẻ ảnh
        function findImageMoreVertButton(targetImg) {
          const all = [];
          collectAllElements(document, all);

          // Kiểm tra xem đang ở màn hình chi tiết ảnh (có nút ← arrow_back hoặc ✓ check ở thanh trên) không
          let detailHeaderY = null;
          for (const el of all) {
            if (!isVisible(el, 14, 14)) continue;
            const t = (el.textContent || '').trim();
            if (/^(arrow_back|check|info)$/i.test(t)) {
              const r = el.getBoundingClientRect();
              if (r.top < window.innerHeight * 0.32) {
                detailHeaderY = r.top + r.height / 2;
                break;
              }
            }
          }

          let best = null;
          let bestScore = -1;
          for (const el of all) {
            if (!isVisible(el, 14, 14)) continue;
            const t = (el.textContent || '').trim();
            const aria = ((el.getAttribute && (el.getAttribute('aria-label') || el.getAttribute('title'))) || '').toLowerCase();
            const isMore = /^(more_vert|more_horiz)$/i.test(t) || /(more options|tùy chọn khác|thêm tùy chọn)/i.test(aria);
            if (!isMore) continue;

            const btn = (el.closest && el.closest('button, [role="button"]')) || el;
            if (!isVisible(btn, 18, 18)) continue;
            const r = btn.getBoundingClientRect();
            if (r.width > 76 || r.height > 76) continue;
            const cy = r.top + r.height / 2;

            let score = 100;
            if (detailHeaderY !== null && Math.abs(cy - detailHeaderY) <= 28) {
              score += 250;
            } else if (targetImg) {
              const ir = targetImg.getBoundingClientRect();
              if (r.left >= ir.left - 30 && r.right <= ir.right + 30 && r.top >= ir.top - 60 && r.bottom <= ir.bottom + 60) {
                score += 220;
              }
            }
            if (score > bestScore) {
              bestScore = score;
              best = btn;
            }
          }
          return { btn: best, inDetailView: detailHeaderY !== null };
        }

        // Tự động mở menu ⋮ -> Tải nội dung xuống -> 1K (1024px) để lấy ảnh gốc 1K thay vì thumbnail 512x512
        async function triggerFlow1KDownloadMenu(targetImg) {
          window.__dmxInterceptingDownload = true;
          try {
            // Nếu đã có sẵn ảnh >= 900px từ hook trước đó thì trả về ngay
            if (window.__dmxHighResDataUrl && window.__dmxHighResWidth >= 900) {
              return window.__dmxHighResDataUrl;
            }

            // Bước 1: Nếu menu "1K" chưa mở, kiểm tra menu "Tải nội dung xuống" hoặc nút ⋮
            let item1K = find1KSubmenuItem();
            if (!item1K) {
              let dlItem = findDownloadMenuItem();
              if (!dlItem) {
                let moreInfo = findImageMoreVertButton(targetImg);
                // Nếu chưa ở màn hình chi tiết ảnh (chưa có nút ← / ✓), bấm vào ảnh kết quả để mở màn hình chi tiết ảnh
                if (!moreInfo.inDetailView && targetImg) {
                  humanClick(targetImg);
                  await sleep(650);
                  moreInfo = findImageMoreVertButton(targetImg);
                }
                if (moreInfo.btn) {
                  humanClick(moreInfo.btn);
                  await sleep(480);
                }
                dlItem = findDownloadMenuItem();
              }
              if (dlItem) {
                humanClick(dlItem);
                await sleep(480);
              }
              item1K = find1KSubmenuItem();
            }

            // Bước 2: Bấm vào mục "1K (Kích thước gốc)"
            if (item1K) {
              window.__dmxHighResDataUrl = '';
              window.__dmxHighResWidth = 0;
              humanClick(item1K);

              // Chờ tối đa 4.5 giây để hook URL.createObjectURL / <a download> / fetch bắt được file 1K (1024x1024)
              for (let k = 0; k < 15; k++) {
                await sleep(300);
                if (window.__dmxHighResDataUrl && window.__dmxHighResWidth >= 800) {
                  return window.__dmxHighResDataUrl;
                }
                // Kiểm tra các URL signed mới xuất hiện sau khi bấm 1K
                if (Array.isArray(window.__dmxCapturedSignedUrls) && window.__dmxCapturedSignedUrls.length > 0) {
                  const latestUrl = window.__dmxCapturedSignedUrls[window.__dmxCapturedSignedUrls.length - 1];
                  const fetched = await fetchImageWithSize(latestUrl);
                  if (fetched && (fetched.w >= 800 || fetched.h >= 800)) {
                    return fetched.dataUrl;
                  }
                }
              }
            }
          } catch (_) {
          } finally {
            window.__dmxInterceptingDownload = false;
          }
          return null;
        }

        const oldSet = new Set(oldSrcs || []);
        const nodes = [];
        collectMedia(document, nodes);
        let best = null;
        let bestArea = 0;

        for (const el of nodes) {
          const r = el.getBoundingClientRect();
          if (r.width < 100 || r.height < 100) continue;
          const nw = el.tagName === 'IMG' ? (el.naturalWidth || r.width) : (el.width || r.width);
          const nh = el.tagName === 'IMG' ? (el.naturalHeight || r.height) : (el.height || r.height);
          if (nw < 256 || nh < 256) continue;
          const src = el.tagName === 'IMG' ? (el.currentSrc || el.src || '') : '';
          if (oldSet.size > 0 && src && oldSet.has(src)) continue;
          if (el.tagName === 'IMG' && /(avatar|profile|logo|icon|googleusercontent\.com\/a\/)/i.test(src)) continue;
          let pCard = el;
          let isSampleCard = false;
          for (let k = 0; k < 5 && pCard; k++) {
            if (((pCard.innerText || pCard.textContent || '').toLowerCase()).includes('san-pham-dmx')) { isSampleCard = true; break; }
            pCard = pCard.parentElement;
          }
          if (isSampleCard) continue;
          const area = nw * nh;
          if (area >= bestArea) {
            bestArea = area;
            best = el;
          }
        }

        // Nếu hook đã bắt sẵn ảnh 1K/2K (>= 900px) thì ưu tiên dùng ngay
        if (window.__dmxHighResDataUrl && window.__dmxHighResWidth >= 900) {
          return window.__dmxHighResDataUrl;
        }

        if (!best) {
          // Thử kích hoạt menu 1K nếu người dùng đang mở sẵn menu Tải nội dung trên màn hình
          const fromOpenMenu = await triggerFlow1KDownloadMenu(null);
          if (fromOpenMenu) return fromOpenMenu;
          return "NOT_FOUND";
        }

        let fallback512DataUrl = null;

        if (best.tagName === 'IMG') {
          const rawSrc = bestSrcFromSrcset(best) || best.currentSrc || best.src || '';
          const candidates = buildHighResCandidateUrls(rawSrc);
          for (const u of candidates) {
            const res = await fetchImageWithSize(u);
            if (res && res.dataUrl) {
              // Nếu lấy được ảnh chuẩn 1K/2K (>= 900px) thì trả về luôn!
              if (res.w >= 900 || res.h >= 900) {
                return res.dataUrl;
              }
              if (!fallback512DataUrl) {
                fallback512DataUrl = res.dataUrl;
              }
            }
          }
        }

        // Nếu ảnh trên lưới DOM chỉ là bản xem trước 512x512px -> tự động bấm mở menu ⋮ -> Tải nội dung xuống -> 1K (1024px)
        const menu1KDataUrl = await triggerFlow1KDownloadMenu(best);
        if (menu1KDataUrl && menu1KDataUrl.startsWith('data:image/')) {
          return menu1KDataUrl;
        }

        // Kiểm tra lại xem sau khi mở màn hình chi tiết có thẻ <img> nào >= 900px xuất hiện không
        const afterNodes = [];
        collectMedia(document, afterNodes);
        for (const el of afterNodes) {
          if (el.tagName !== 'IMG') continue;
          const nw = el.naturalWidth || 0, nh = el.naturalHeight || 0;
          if (nw >= 900 || nh >= 900) {
            const s = bestSrcFromSrcset(el) || el.currentSrc || el.src || '';
            const res = await fetchImageWithSize(s);
            if (res && res.dataUrl) return res.dataUrl;
          }
        }

        if (fallback512DataUrl) return fallback512DataUrl;

        if (best.tagName === 'IMG') {
          try {
            const c = document.createElement('canvas');
            c.width = best.naturalWidth;
            c.height = best.naturalHeight;
            const ctx = c.getContext('2d');
            ctx.drawImage(best, 0, 0);
            return c.toDataURL('image/png');
          } catch (_) {
            return "CORS_BLOCKED";
          }
        } else {
          try {
            return best.toDataURL('image/png');
          } catch (_) {
            return "CORS_BLOCKED";
          }
        }
        """#

        webViewFlow.callAsyncJavaScript(asyncJS, arguments: ["oldSrcs": cacSrcCu], in: nil, in: .page) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.vongQuayFlow.stopAnimating()
                switch result {
                case .success(let value):
                    let str = (value as? String) ?? ""
                    if str == "NOT_FOUND" || str.isEmpty {
                        if !tuDong {
                            self.hienToastFlow("Chưa thấy ảnh kết quả trên Flow — hãy tạo ảnh xong rồi bấm Lấy ảnh.", mauNen: UIColor.systemOrange.withAlphaComponent(0.92))
                        }
                        return
                    }
                    if str == "CORS_BLOCKED" || !str.hasPrefix("data:image/") {
                        if !tuDong {
                            self.hienToastFlow("Hãy bấm ⋮ trên ảnh → Tải nội dung xuống → 1K để app tự bắt ảnh 1K.", mauNen: UIColor.systemOrange.withAlphaComponent(0.92))
                        }
                        return
                    }
                    guard let comma = str.firstIndex(of: ",") else { return }
                    let b64 = String(str[str.index(after: comma)...])
                    guard let data = Data(base64Encoded: b64), let rawImg = UIImage(data: data) else {
                        if !tuDong {
                            self.hienToastFlow("Không giải mã được ảnh — hãy chọn Tải nội dung → 1K trên Flow.", mauNen: UIColor.systemOrange.withAlphaComponent(0.92))
                        }
                        return
                    }
                    let img = self.nangCapLen1KNeuCan(rawImg)
                    let pxW = Int((img.size.width * img.scale).rounded())
                    let pxH = Int((img.size.height * img.scale).rounded())
                    self.nhanAnhChatLuongCaoTuFlow(img, nguon: (pxW >= 1800 || pxH >= 1800) ? "2K" : "1K")
                case .failure(_):
                    if !tuDong {
                        self.hienToastFlow("Hãy bấm ⋮ trên ảnh → Tải nội dung xuống → 1K để app tự lấy ảnh.", mauNen: UIColor.systemOrange.withAlphaComponent(0.92))
                    }
                }
            }
        }
    }

    /// Đảm bảo ảnh lấy về luôn đạt chuẩn tối thiểu 1K (1024px cạnh lớn) sắc nét nếu Flow chỉ trả về bản preview 512px.
    private func nangCapLen1KNeuCan(_ img: UIImage) -> UIImage {
        let pxW = img.size.width * img.scale
        let pxH = img.size.height * img.scale
        let maxSide = max(pxW, pxH)
        guard maxSide > 10, maxSide < 1024 else { return img }
        let tiLe: CGFloat = 1024.0 / maxSide
        let newSize = CGSize(width: (pxW * tiLe).rounded(), height: (pxH * tiLe).rounded())
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 1.0
        fmt.opaque = true
        return UIGraphicsImageRenderer(size: newSize, format: fmt).image { ctx in
            ctx.cgContext.interpolationQuality = .high
            img.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Gộp tất cả ảnh mẫu của các tab sản phẩm thành 1 ảnh tham chiếu chất lượng cao (hoặc giữ nguyên nếu chỉ có 1 ảnh)
    private func layAnhMauTongHopChoPoster() -> UIImage? {
        luuDuLieuTabHienTai()
        let cacSPCoAnh = danhSachSanPham.enumerated().compactMap { (idx, sp) -> (soThuTu: Int, ten: String, anh: UIImage)? in
            guard let anh = sp.anhMau else { return nil }
            return (idx + 1, sp.tenSanPham, anh)
        }
        guard !cacSPCoAnh.isEmpty else { return nil }
        if cacSPCoAnh.count == 1 {
            return cacSPCoAnh[0].anh
        }

        return autoreleasepool {
            let soLuong = cacSPCoAnh.count
            let soCot: Int = (soLuong == 2) ? 2 : ((soLuong <= 4) ? 2 : 3)
            let soHang: Int = Int(ceil(Double(soLuong) / Double(soCot)))
            let cellW: CGFloat = 960
            let cellH: CGFloat = 1040
            let pad: CGFloat = 28
            let canvasW = CGFloat(soCot) * cellW + CGFloat(soCot + 1) * pad
            let canvasH = CGFloat(soHang) * cellH + CGFloat(soHang + 1) * pad

            let fmt = UIGraphicsImageRendererFormat()
            fmt.scale = 1.0
            fmt.opaque = true
            return UIGraphicsImageRenderer(size: CGSize(width: canvasW, height: canvasH), format: fmt).image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: canvasW, height: canvasH))

                for (i, item) in cacSPCoAnh.enumerated() {
                    let col = i % soCot
                    let row = i / soCot
                    let x = pad + CGFloat(col) * (cellW + pad)
                    let y = pad + CGFloat(row) * (cellH + pad)
                    let cellRect = CGRect(x: x, y: y, width: cellW, height: cellH)

                    // Khung nền trắng sạch cho từng sản phẩm
                    let path = UIBezierPath(roundedRect: cellRect, cornerRadius: 20)
                    UIColor(white: 0.97, alpha: 1.0).setFill()
                    path.fill()
                    UIColor(white: 0.86, alpha: 1.0).setStroke()
                    path.lineWidth = 2
                    path.stroke()

                    // Nhãn đánh số thứ tự sản phẩm khớp với prompt
                    let tieuDe = item.ten.isEmpty ? "SẢN PHẨM \(item.soThuTu)" : "SẢN PHẨM \(item.soThuTu): \(item.ten)"
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                        .foregroundColor: UIColor(red: 0.05, green: 0.25, blue: 0.58, alpha: 1.0)
                    ]
                    (tieuDe as NSString).draw(
                        in: CGRect(x: x + 20, y: y + 16, width: cellW - 40, height: 42),
                        withAttributes: attrs
                    )

                    // Vẽ ảnh mẫu giữ nguyên tỷ lệ (aspect-fit)
                    let imgArea = CGRect(x: x + 18, y: y + 66, width: cellW - 36, height: cellH - 84)
                    let iw = max(1, item.anh.size.width)
                    let ih = max(1, item.anh.size.height)
                    let scale = min(imgArea.width / iw, imgArea.height / ih)
                    let dw = iw * scale
                    let dh = ih * scale
                    let dx = imgArea.midX - dw / 2
                    let dy = imgArea.midY - dh / 2
                    item.anh.draw(in: CGRect(x: dx, y: dy, width: dw, height: dh))
                }
            }
        }
    }

    private func maHoaAnhMauBase64ChoFlow() -> String {
        guard let anh = layAnhMauTongHopChoPoster() else { return "" }
        return autoreleasepool {
            let data = anh.jpegData(compressionQuality: 0.95) ?? anh.pngData()
            return data?.base64EncodedString() ?? ""
        }
    }

    private func bomPromptVaoWebViewFlow(_ prompt: String, tuDong: Bool, tuTaoDuAnMoi: Bool = false) {
        if tuDong && dangBomPromptFlow {
            return
        }
        dangBomPromptFlow = true
        congViecBomPromptTuDong?.cancel()

        let tt = thuThapThongTin()
        let anhB64 = maHoaAnhMauBase64ChoFlow()
        let args: [String: Any] = [
            "promptText": prompt,
            "imageBase64": anhB64,
            "targetAspect": tt.tyLeAnh,
            "targetModel": tt.modelFlow,
            "autoNewProject": tuTaoDuAnMoi
        ]

        let asyncJS = #"""
        function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

        function collectDocs(doc, out) {
          if (!doc) return;
          out.push(doc);
          const frames = doc.querySelectorAll ? doc.querySelectorAll('iframe') : [];
          for (const f of frames) {
            try { if (f.contentDocument) collectDocs(f.contentDocument, out); } catch (_) {}
          }
        }

        function collectAllElements(root, out) {
          if (!root) return;
          const all = root.querySelectorAll ? root.querySelectorAll('*') : [];
          for (const el of all) {
            out.push(el);
            if (el.shadowRoot) collectAllElements(el.shadowRoot, out);
          }
        }

        function isVisible(el, minW = 16, minH = 12) {
          if (!el || !el.isConnected) return false;
          const st = window.getComputedStyle(el);
          if (!st || st.display === 'none' || st.visibility === 'hidden' || parseFloat(st.opacity) === 0) return false;
          const r = el.getBoundingClientRect();
          return r.width >= minW && r.height >= minH;
        }

        function findPromptBox() {
          const docs = [];
          collectDocs(document, docs);
          const allEls = [];
          for (const d of docs) collectAllElements(d, allEls);

          let best = null;
          let bestScore = -1;

          for (const el of allEls) {
            const tag = (el.tagName || '').toUpperCase();
            const ceAttr = (el.getAttribute && el.getAttribute('contenteditable')) || '';
            const role = (el.getAttribute && el.getAttribute('role')) || '';
            const isSlate = !!(el.hasAttribute && el.hasAttribute('data-slate-editor'));
            const isEditable = isSlate
              || tag === 'TEXTAREA'
              || el.isContentEditable === true
              || (ceAttr !== '' && ceAttr !== 'false')
              || role === 'textbox';

            if (!isEditable) continue;
            if (!isVisible(el, 30, 12)) continue;
            if (el.disabled || el.readOnly || el.getAttribute('aria-disabled') === 'true') continue;

            if (tag !== 'TEXTAREA' && el.querySelector && el.querySelector('[contenteditable="true"], [contenteditable="plaintext-only"], [data-slate-editor="true"], textarea')) {
              continue;
            }

            const meta = [
              el.getAttribute('placeholder') || '',
              el.getAttribute('aria-label') || '',
              el.getAttribute('data-placeholder') || '',
              el.id || '',
              typeof el.className === 'string' ? el.className : '',
              el.closest ? (el.closest('form, section, div')?.innerText || '').slice(0, 120) : ''
            ].join(' ').toLowerCase();

            if (/(^|\s)(search|tìm kiếm|rename|project name|tên dự án)(\s|$)/i.test(meta) && !/(tạo|create|prompt|những gì|describe)/i.test(meta)) {
              continue;
            }

            const r = el.getBoundingClientRect();
            let score = 0;
            if (isSlate) score += 90;
            if (el.isContentEditable || role === 'textbox') score += 50;
            if (tag === 'TEXTAREA') score += 35;
            if (/(bạn muốn tạo|what do you want|prompt|describe|create|imagine|generate|nhập|mô tả)/i.test(meta)) score += 80;
            if (r.top > window.innerHeight * 0.25) score += 35;
            if (r.width >= 150) score += 20;
            score += Math.min(r.width / 20, 20);

            if (score > bestScore) {
              bestScore = score;
              best = el;
            }
          }

          if (!best) {
            for (const el of allEls) {
              if (!isVisible(el, 30, 12)) continue;
              const txt = (el.textContent || '').trim().toLowerCase();
              if (txt.includes('bạn muốn tạo những gì') || txt.includes('what do you want to create')) {
                let p = el;
                for (let k = 0; k < 5 && p; k++) {
                  const ed = p.querySelector && p.querySelector('[data-slate-editor], [contenteditable="true"], [role="textbox"], textarea');
                  if (ed) { best = ed; break; }
                  p = p.parentElement;
                }
                if (best) break;
              }
            }
          }
          return best;
        }

        function getBoxText(el) {
          if (!el) return '';
          if (el.tagName === 'TEXTAREA' || el.tagName === 'INPUT') return (el.value || '').trim();
          if (el.querySelector && el.querySelector('[data-slate-placeholder="true"]')) {
            const clone = el.cloneNode(true);
            for (const ph of clone.querySelectorAll('[data-slate-placeholder="true"]')) {
              ph.remove();
            }
            return (clone.innerText || clone.textContent || '').trim();
          }
          return (el.innerText || el.textContent || '').trim();
        }

        async function fillPromptBox(el, text) {
          if (!el || !text) return false;
          window.__dmxForceTrusted = true;
          try {
            el.scrollIntoView({ block: 'center' });
            el.click();
            el.focus();
            await sleep(80);

            if (el.tagName === 'TEXTAREA' || el.tagName === 'INPUT') {
              const proto = el.tagName === 'TEXTAREA' ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
              const setter = Object.getOwnPropertyDescriptor(proto, 'value')?.set;
              if (setter) setter.call(el, text); else el.value = text;
              el.dispatchEvent(new InputEvent('input', { bubbles: true, cancelable: true, inputType: 'insertText', data: text }));
              el.dispatchEvent(new Event('change', { bubbles: true }));
              return true;
            }

            try {
              const sel = window.getSelection();
              const range = document.createRange();
              range.selectNodeContents(el);
              sel.removeAllRanges();
              sel.addRange(range);
            } catch (_) {}

            try {
              const dt = new DataTransfer();
              dt.setData('text/plain', text);
              const pasteEvt = new ClipboardEvent('paste', {
                clipboardData: dt,
                bubbles: true,
                cancelable: true
              });
              el.dispatchEvent(pasteEvt);
              await sleep(100);
              if (getBoxText(el).includes(text.slice(0, 12))) return true;
            } catch (_) {}

            try {
              el.focus();
              document.execCommand('selectAll', false, null);
              el.dispatchEvent(new InputEvent('beforeinput', { bubbles: true, cancelable: true, inputType: 'insertText', data: text }));
              document.execCommand('insertText', false, text);
              await sleep(90);
              if (getBoxText(el).includes(text.slice(0, 12))) return true;
            } catch (_) {}

            try {
              el.dispatchEvent(new InputEvent('beforeinput', { bubbles: true, cancelable: true, inputType: 'insertText', data: text }));
              el.textContent = text;
              el.dispatchEvent(new InputEvent('input', { bubbles: true, cancelable: true, inputType: 'insertText', data: text }));
              el.dispatchEvent(new Event('change', { bubbles: true }));
              return true;
            } catch (_) {
              return false;
            }
          } finally {
            window.__dmxForceTrusted = false;
          }
        }

        async function nudgePromptBox(el) {
          if (!el) return;
          window.__dmxForceTrusted = true;
          try {
            el.focus();
            await sleep(40);
            if (el.tagName === 'TEXTAREA' || el.tagName === 'INPUT') {
              const cur = el.value || '';
              const proto = el.tagName === 'TEXTAREA' ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
              const setter = Object.getOwnPropertyDescriptor(proto, 'value')?.set;
              if (setter) setter.call(el, cur + ' '); else el.value = cur + ' ';
              el.dispatchEvent(new InputEvent('input', { bubbles: true, cancelable: true, inputType: 'insertText', data: ' ' }));
              el.dispatchEvent(new Event('change', { bubbles: true }));
            } else {
              try {
                const sel = window.getSelection();
                const range = document.createRange();
                range.selectNodeContents(el);
                range.collapse(false);
                sel.removeAllRanges();
                sel.addRange(range);
              } catch (_) {}
              el.dispatchEvent(new InputEvent('beforeinput', { bubbles: true, cancelable: true, inputType: 'insertText', data: ' ' }));
              document.execCommand('insertText', false, ' ');
              el.dispatchEvent(new InputEvent('input', { bubbles: true, cancelable: true, inputType: 'insertText', data: ' ' }));
            }
            await sleep(50);
          } catch (_) {
          } finally {
            window.__dmxForceTrusted = false;
          }
        }

        async function attachSampleImage(b64, promptBox) {
          if (!b64) return 'NO_IMAGE';
          window.__dmxForceTrusted = true;
          try {
            const bin = atob(b64);
            const bytes = new Uint8Array(bin.length);
            for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
            const file = new File([bytes], 'san-pham-dmx.jpg', { type: 'image/jpeg', lastModified: Date.now() });

            const docs = [];
            collectDocs(document, docs);
            const allEls = [];
            for (const d of docs) collectAllElements(d, allEls);
            const fileInputs = allEls.filter(el => (el.tagName || '').toUpperCase() === 'INPUT' && el.type === 'file');

            for (const inp of fileInputs) {
              const acc = (inp.accept || '').toLowerCase();
              if (acc && !acc.includes('image') && !acc.includes('*')) continue;
              const dt = new DataTransfer();
              dt.items.add(file);
              inp.files = dt.files;
              inp.dispatchEvent(new Event('input', { bubbles: true }));
              inp.dispatchEvent(new Event('change', { bubbles: true }));
              return 'ATTACHED_INPUT';
            }

            const dropTargets = [];
            if (promptBox) {
              dropTargets.push(promptBox);
              if (promptBox.parentElement) dropTargets.push(promptBox.parentElement);
            }
            const mainEl = document.querySelector('main') || document.body;
            if (mainEl) dropTargets.push(mainEl);

            for (const target of dropTargets) {
              const dt = new DataTransfer();
              dt.items.add(file);
              for (const evType of ['dragenter', 'dragover', 'drop']) {
                const ev = new DragEvent(evType, {
                  bubbles: true,
                  cancelable: true,
                  dataTransfer: dt
                });
                target.dispatchEvent(ev);
              }
            }

            if (promptBox) {
              const dtPaste = new DataTransfer();
              dtPaste.items.add(file);
              const pasteImg = new ClipboardEvent('paste', {
                clipboardData: dtPaste,
                bubbles: true,
                cancelable: true
              });
              promptBox.dispatchEvent(pasteImg);
            }
            return 'ATTACHED_DROP';
          } catch (e) {
            return 'IMG_ERR:' + String(e);
          } finally {
            window.__dmxForceTrusted = false;
          }
        }

        function humanClick(el) {
          if (!el) return;
          window.__dmxForceTrusted = true;
          try {
            const r = el.getBoundingClientRect();
            const cx = r.left + r.width / 2;
            const cy = r.top + r.height / 2;
            const opts = { bubbles: true, cancelable: true, composed: true, view: window, clientX: cx, clientY: cy, button: 0, buttons: 1 };
            try { el.dispatchEvent(new PointerEvent('pointerdown', { ...opts, pointerId: 1, pointerType: 'touch', isPrimary: true })); } catch (_) {}
            try { el.dispatchEvent(new MouseEvent('mousedown', opts)); } catch (_) {}
            try { el.dispatchEvent(new PointerEvent('pointerup', { ...opts, buttons: 0, pointerId: 1, pointerType: 'touch', isPrimary: true })); } catch (_) {}
            try { el.dispatchEvent(new MouseEvent('mouseup', { ...opts, buttons: 0 })); } catch (_) {}
            try { el.click(); } catch (_) {}
          } finally {
            window.__dmxForceTrusted = false;
          }
        }

        async function applyFlowSettings(aspect, modelName) {
          let aspectOk = false;
          let modelOk = false;
          try {
            const getAllVis = () => {
              const docs = [];
              collectDocs(document, docs);
              const out = [];
              for (const d of docs) collectAllElements(d, out);
              return out.filter(el => isVisible(el, 24, 12));
            };

            const norm = (s) => (s || '').replace(/\s+/g, ' ').trim();

            function findButtonByLabel(exactLabels, rolesSelector) {
              const targets = exactLabels.map(s => s.toLowerCase());
              const vis = getAllVis();
              for (const el of vis) {
                if (el.children && el.children.length > 0) continue;
                const t = norm(el.textContent).toLowerCase();
                if (!targets.includes(t)) continue;
                const clickable = el.closest ? el.closest(rolesSelector) : null;
                if (clickable && isVisible(clickable, 24, 12)) return clickable;
                return el;
              }
              for (const el of vis) {
                if (!el.matches || !el.matches(rolesSelector)) continue;
                const t = norm(el.innerText || el.textContent).toLowerCase();
                if (t.length > 45) continue;
                for (const tg of targets) {
                  if (t === tg || t.endsWith(' ' + tg) || t.includes('\n' + tg)) return el;
                }
              }
              return null;
            }

            const btnSelector = 'button, [role="button"], [role="tab"], [role="radio"]';
            const optSelector = '[role="option"], [role="menuitem"], [role="menuitemradio"], button, li';

            let openedByUs = false;
            let pillBtn = document.querySelector('.settings-trigger-button');
            if (!pillBtn || !isVisible(pillBtn, 40, 16)) {
              pillBtn = null;
              for (const el of getAllVis()) {
                if (!el.matches || !el.matches('button, [role="button"]')) continue;
                const t = norm(el.innerText || el.textContent);
                const r = el.getBoundingClientRect();
                if (r.top < window.innerHeight * 0.45) continue;
                if (r.width > 300 || r.height > 70) continue;
                if (/(nano banana|imagen|veo|banana)/i.test(t) || /\bx[1-4]\b/i.test(t)) {
                  pillBtn = el;
                  break;
                }
              }
            }
            if (!findButtonByLabel([aspect], btnSelector) && pillBtn) {
              humanClick(pillBtn);
              openedByUs = true;
              await sleep(320);
            }

            const imgTab = findButtonByLabel(['Hình ảnh', 'Image', 'Images'], btnSelector);
            if (imgTab) {
              const alreadySelected = imgTab.getAttribute('aria-selected') === 'true' || imgTab.getAttribute('data-state') === 'active' || imgTab.getAttribute('aria-checked') === 'true';
              if (!alreadySelected) {
                humanClick(imgTab);
                await sleep(220);
              }
            }

            const aspectBtn = findButtonByLabel([aspect], btnSelector);
            if (aspectBtn) {
              humanClick(aspectBtn);
              aspectOk = true;
              await sleep(240);
            }

            if (modelName) {
              const targetLow = modelName.toLowerCase();
              let dropdownBtn = null;
              for (const el of getAllVis()) {
                if (!el.matches || !el.matches('button, [role="combobox"], [role="button"]')) continue;
                const t = norm(el.innerText || el.textContent);
                const r = el.getBoundingClientRect();
                if (r.width < 120 || r.height > 72) continue;
                if (r.top > window.innerHeight * 0.86) continue;
                if (/(nano banana|imagen|veo)/i.test(t) && !/\bx[1-4]\b/i.test(t)) {
                  dropdownBtn = el;
                  break;
                }
              }
              if (dropdownBtn) {
                const curModel = norm(dropdownBtn.innerText || dropdownBtn.textContent).toLowerCase();
                if (curModel.includes(targetLow)) {
                  modelOk = true;
                } else {
                  humanClick(dropdownBtn);
                  await sleep(280);
                  const opt = findButtonByLabel([modelName], optSelector);
                  if (opt) {
                    humanClick(opt);
                    modelOk = true;
                    await sleep(220);
                  }
                }
              }
            }

            if (openedByUs) {
              const backdrop = document.querySelector('.cdk-overlay-backdrop');
              if (backdrop) {
                humanClick(backdrop);
              } else {
                document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', code: 'Escape', keyCode: 27, bubbles: true }));
              }
              await sleep(160);
              if (findButtonByLabel([aspect], btnSelector) && pillBtn && isVisible(pillBtn, 40, 16)) {
                humanClick(pillBtn);
                await sleep(180);
              }
            }
          } catch (_) {}
          return { aspectOk, modelOk };
        }

        async function clickNewProjectIfNeeded() {
          const findNewProjBtn = () => {
            const docs = [];
            collectDocs(document, docs);
            const all = [];
            for (const d of docs) collectAllElements(d, all);
            for (const el of all) {
              if (!isVisible(el, 30, 14)) continue;
              if (!el.matches || !el.matches('button, a, [role="button"]')) continue;
              const t = (el.innerText || el.textContent || '').replace(/\s+/g, ' ').trim().toLowerCase();
              if (t.length > 50) continue;
              if (t.includes('dự án mới') || t.includes('new project') || t === '+ dự án mới' || t === '+ new project') {
                return el;
              }
            }
            return null;
          };

          let boxNow = findPromptBox();
          if (!autoNewProject && boxNow) return false;

          let btn = null;
          for (let i = 0; i < 20; i++) {
            btn = findNewProjBtn();
            if (btn) break;
            if (!autoNewProject && findPromptBox()) return false;
            await sleep(250);
          }
          if (!btn) return false;

          humanClick(btn);

          for (let i = 0; i < 32; i++) {
            await sleep(250);
            if (findPromptBox()) {
              await sleep(350);
              return true;
            }
          }
          return true;
        }

        function snapshotImageSrcs() {
          const docs = [];
          collectDocs(document, docs);
          const all = [];
          for (const d of docs) collectAllElements(d, all);
          const srcs = [];
          for (const el of all) {
            if ((el.tagName || '').toUpperCase() === 'IMG') {
              const s = el.currentSrc || el.src || '';
              if (s) srcs.push(s);
            }
          }
          return [...new Set(srcs)];
        }

        function getBackgroundRGB(el) {
          let cur = el;
          for (let k = 0; k < 4 && cur && cur !== document.body; k++) {
            try {
              const bg = window.getComputedStyle(cur).backgroundColor || '';
              const m = bg.match(/rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*([0-9.]+))?\s*\)/i);
              if (m) {
                const r = parseInt(m[1], 10), g = parseInt(m[2], 10), b = parseInt(m[3], 10);
                const a = m[4] !== undefined ? parseFloat(m[4]) : 1.0;
                if (a >= 0.35 && (r + g + b) > 30) {
                  return { r, g, b, sum: r + g + b };
                }
              }
            } catch (_) {}
            cur = cur.parentElement;
          }
          return { r: 0, g: 0, b: 0, sum: 0 };
        }

        function isWhiteBackgroundButton(el) {
          const rgb = getBackgroundRGB(el);
          return rgb.r >= 135 && rgb.g >= 135 && rgb.b >= 135 && rgb.sum >= 420;
        }

        function findGenerateArrowButton(promptBox, requireWhiteOrEnabled = true) {
          const docs = [];
          collectDocs(document, docs);
          const all = [];
          for (const d of docs) collectAllElements(d, all);

          const curBox = promptBox || findPromptBox();
          const boxRect = curBox ? curBox.getBoundingClientRect() : null;

          let bottomRowY = null;
          const trig = document.querySelector('.settings-trigger-button');
          if (trig && isVisible(trig, 40, 16)) {
            const tr = trig.getBoundingClientRect();
            bottomRowY = tr.top + tr.height / 2;
          } else {
            for (const el of all) {
              if (!isVisible(el, 40, 16)) continue;
              const r = el.getBoundingClientRect();
              if (r.height > 68 || r.top < window.innerHeight * 0.45) continue;
              const t = (el.innerText || el.textContent || '').replace(/\s+/g, ' ').trim();
              if (t.length >= 2 && t.length <= 50 && (/(nano banana|imagen|veo)/i.test(t) || /\bx[1-4]\b/i.test(t))) {
                bottomRowY = r.top + r.height / 2;
                break;
              }
            }
          }

          const candidateSet = new Set();
          const addCandidate = (node) => {
            if (!node || !node.isConnected) return;
            const btn = node.closest ? node.closest('button, [role="button"], [type="submit"]') : null;
            if (btn && isVisible(btn, 18, 18)) {
              const br = btn.getBoundingClientRect();
              if (br.width >= 20 && br.width <= 80 && br.height >= 20 && br.height <= 80) {
                candidateSet.add(btn);
              }
            }
            let cur = node;
            for (let k = 0; k < 5 && cur && cur !== document.body && cur !== document.documentElement; k++) {
              if (isVisible(cur, 20, 20)) {
                const r = cur.getBoundingClientRect();
                if (r.width >= 20 && r.width <= 80 && r.height >= 20 && r.height <= 80) {
                  candidateSet.add(cur);
                }
              }
              cur = cur.parentElement || (cur.getRootNode && cur.getRootNode().host) || null;
            }
          };

          for (const el of all) {
            if (!isVisible(el, 10, 10)) continue;
            const tag = (el.tagName || '').toUpperCase();
            if (tag === 'I' || tag === 'MAT-ICON' || tag === 'SPAN' || tag === 'MD-ICON' || tag === 'GOOGLE-SYMBOL' || tag === 'BUTTON') {
              const txt = (el.textContent || '').trim();
              if (/^(arrow_forward|arrow_upward|arrow_right_alt|east|send|north_east|→|➔|➜)$/i.test(txt)) {
                addCandidate(el);
              }
            }
          }

          for (const el of all) {
            if (!isVisible(el, 18, 18)) continue;
            const r = el.getBoundingClientRect();
            const cx = r.left + r.width / 2;
            const cy = r.top + r.height / 2;
            if (cx < window.innerWidth * 0.60) continue;
            if (cy < window.innerHeight * 0.45) continue;
            if (boxRect && cy < boxRect.top + 28) continue;
            addCandidate(el);
          }

          const probeYs = [];
          if (bottomRowY !== null) {
            probeYs.push(bottomRowY - 6, bottomRowY, bottomRowY + 6);
          }
          for (let py = Math.floor(window.innerHeight * 0.65); py <= window.innerHeight - 14; py += 14) {
            probeYs.push(py);
          }
          for (const py of probeYs) {
            if (py < 0 || py > window.innerHeight) continue;
            for (let px = Math.floor(window.innerWidth * 0.72); px <= window.innerWidth - 8; px += 8) {
              try {
                const hit = document.elementFromPoint(px, py);
                if (hit) addCandidate(hit);
              } catch (_) {}
            }
          }

          let best = null;
          let bestScore = -1;

          for (const el of candidateSet) {
            if (!isVisible(el, 20, 20)) continue;
            const r = el.getBoundingClientRect();
            if (r.width < 20 || r.width > 80 || r.height < 20 || r.height > 80) continue;
            if (Math.abs(r.width - r.height) > 24) continue;

            const cx = r.left + r.width / 2;
            const cy = r.top + r.height / 2;

            if (cx < window.innerWidth * 0.65) continue;
            if (cy < window.innerHeight * 0.45) continue;
            if (boxRect && cy < boxRect.top + 28) continue;

            const parentBtn = el.closest ? el.closest('button, [role="button"]') : null;
            if (parentBtn && parentBtn !== el) {
              const pr = parentBtn.getBoundingClientRect();
              const pTxt = (parentBtn.innerText || parentBtn.textContent || '').replace(/\s+/g, ' ').trim();
              const childBtns = parentBtn.querySelectorAll ? parentBtn.querySelectorAll('button, [role="button"]') : [];
              if (pr.width > 80 && childBtns.length <= 1 && (/(nano banana|imagen|veo)/i.test(pTxt) || /\bx[1-4]\b/i.test(pTxt))) {
                continue;
              }
            }

            const rawText = (el.innerText || el.textContent || '').replace(/\s+/g, ' ').trim();
            if (/(nano banana|imagen|veo)/i.test(rawText) || /\bx[1-4]\b/i.test(rawText)) continue;
            if (/^(x|×|\u2715|\u2716|\+|close|đóng|add|thêm)$/i.test(rawText)) continue;

            const ariaLabel = ((el.getAttribute('aria-label') || '') + ' ' + (el.getAttribute('title') || '')).toLowerCase();
            if (/^(close|đóng|dismiss|cancel|hủy)$/i.test(ariaLabel.trim())) continue;

            const isDis = !!(el.disabled || el.getAttribute('aria-disabled') === 'true');
            const isWhite = isWhiteBackgroundButton(el);

            if (requireWhiteOrEnabled && isDis && !isWhite) continue;

            let hasArrowForwardIcon = /^(arrow_forward|arrow_upward|arrow_right_alt|east|send|north_east|→|➔|➜)$/i.test(rawText);
            if (!hasArrowForwardIcon && el.querySelectorAll) {
              for (const ic of el.querySelectorAll('i, mat-icon, span, md-icon, google-symbol')) {
                const it = (ic.textContent || '').trim();
                if (/^(arrow_forward|arrow_upward|arrow_right_alt|east|send|north_east|→|➔|➜)$/i.test(it)) {
                  hasArrowForwardIcon = true;
                  break;
                }
              }
            }

            let score = 0;
            if (hasArrowForwardIcon) score += 500;
            if (isWhite) score += 320;
            if (!isDis) score += 100;

            if (bottomRowY !== null) {
              const dy = Math.abs(cy - bottomRowY);
              if (dy <= 28) score += 220 - dy * 3;
            }

            if (el.matches && el.matches('button, [role="button"], [type="submit"]')) score += 120;
            if (el.querySelector && el.querySelector('svg, path, i, mat-icon')) score += 60;
            score += (r.right / Math.max(1, window.innerWidth)) * 100;

            if (score > bestScore) {
              bestScore = score;
              best = el;
            }
          }
          return best;
        }

        function hasActivePercentProgress() {
          const docs = [];
          collectDocs(document, docs);
          const all = [];
          for (const d of docs) collectAllElements(d, all);
          for (const el of all) {
            if (!isVisible(el, 8, 8)) continue;
            if (el.children && el.children.length > 0) continue;
            if (el.closest && el.closest('textarea, [contenteditable], [data-slate-editor], [role="textbox"]')) continue;
            const t = (el.textContent || '').trim();
            if (/^(?:[1-9]|[1-9][0-9])%$/.test(t)) return true;
          }
          return false;
        }

        function countNewUploadedMedia(excludeSet, promptBox) {
          const docs = [];
          collectDocs(document, docs);
          const all = [];
          for (const d of docs) collectAllElements(d, all);
          let cnt = 0;
          for (const el of all) {
            if ((el.tagName || '').toUpperCase() === 'IMG') {
              if (!el.complete) continue;
              const s = el.currentSrc || el.src || '';
              if (!s || excludeSet.has(s)) continue;
              if (/(avatar|profile|logo|icon|googleusercontent\.com\/a\/)/i.test(s)) continue;
              const r = el.getBoundingClientRect();
              const nw = el.naturalWidth || r.width || 0;
              const nh = el.naturalHeight || r.height || 0;
              if (nw >= 24 && nh >= 24 && r.width >= 20 && r.height >= 20) cnt++;
            }
          }
          if (promptBox) {
            const boxRect = promptBox.getBoundingClientRect();
            let card = promptBox.parentElement;
            for (let k = 0; k < 6 && card && card !== document.body; k++) {
              const cr = card.getBoundingClientRect();
              if (cr.top < boxRect.top - 25) break;
              card = card.parentElement;
            }
            if (card && card.querySelectorAll) {
              const mediaNodes = card.querySelectorAll('img, canvas, [style*="background-image"]');
              for (const m of mediaNodes) {
                if (!isVisible(m, 24, 24)) continue;
                const mr = m.getBoundingClientRect();
                if (mr.width >= 28 && mr.width <= 160 && mr.height >= 28 && mr.height <= 160 && mr.top <= boxRect.top + 30) {
                  cnt++;
                }
              }
            }
          }
          return cnt;
        }

        function isWhiteArrowStillWaiting(promptBox) {
          const curBox = findPromptBox() || promptBox;
          if (!curBox || !isVisible(curBox, 30, 12)) return false;
          if (getBoxText(curBox).length < 10) return false;
          const btn = findGenerateArrowButton(curBox, true);
          if (!btn || !isVisible(btn, 20, 20)) return false;
          if (btn.disabled || btn.getAttribute('aria-disabled') === 'true') return false;
          const txt = (btn.innerText || btn.textContent || '').toLowerCase();
          if (/(stop|pause|dừng|hourglass|progress_activity|autorenew)/i.test(txt)) return false;
          if (!hasActivePercentProgress()) {
            return true;
          }
          return false;
        }

        function triggerFrameworkClick(targetEl, hitEl, cx, cy) {
          if (!targetEl) return false;
          window.__dmxForceTrusted = true;
          let called = false;
          try {
            const wrapTrusted = window.__dmxWrapTrustedEvent || ((e) => e);
            const chain = [];
            let cur = hitEl || targetEl;
            for (let k = 0; k < 7 && cur && cur !== document.body; k++) {
              if (!chain.includes(cur)) chain.push(cur);
              cur = cur.parentElement;
            }
            if (!chain.includes(targetEl)) chain.unshift(targetEl);
            if (targetEl.querySelectorAll) {
              for (const ch of targetEl.querySelectorAll('*')) {
                if (!chain.includes(ch)) chain.push(ch);
              }
            }

            const makeSynthEvt = (type, currentEl) => {
              const rawNative = new MouseEvent(type, {
                bubbles: true,
                cancelable: true,
                composed: true,
                view: window,
                clientX: cx,
                clientY: cy,
                button: 0,
                buttons: 1,
                detail: 1
              });
              const trustedNative = wrapTrusted(rawNative);
              return {
                type,
                nativeEvent: trustedNative,
                currentTarget: currentEl,
                target: hitEl || currentEl,
                bubbles: true,
                cancelable: true,
                defaultPrevented: false,
                isTrusted: true,
                clientX: cx,
                clientY: cy,
                pageX: cx,
                pageY: cy,
                screenX: cx,
                screenY: cy,
                button: 0,
                buttons: 1,
                detail: 1,
                pointerId: 1,
                pointerType: 'touch',
                isPrimary: true,
                preventDefault() { this.defaultPrevented = true; try { rawNative.preventDefault(); } catch (_) {} },
                stopPropagation() { try { rawNative.stopPropagation(); } catch (_) {} },
                stopImmediatePropagation() { try { rawNative.stopImmediatePropagation(); } catch (_) {} },
                persist() {},
                isDefaultPrevented() { return this.defaultPrevented; },
                isPropagationStopped() { return false; }
              };
            };

            for (const el of chain) {
              try {
                const keys = Object.keys(el);
                const propsKey = keys.find(k => k.startsWith('__reactProps$'));
                const fiberKey = keys.find(k => k.startsWith('__reactFiber$') || k.startsWith('__reactInternalInstance$'));
                const propsList = [];
                if (propsKey && el[propsKey]) propsList.push({ props: el[propsKey], node: el });
                if (fiberKey && el[fiberKey]) {
                  let f = el[fiberKey];
                  for (let depth = 0; depth < 8 && f; depth++) {
                    if (f.memoizedProps) propsList.push({ props: f.memoizedProps, node: el });
                    if (f.pendingProps && f.pendingProps !== f.memoizedProps) propsList.push({ props: f.pendingProps, node: el });
                    f = f.return;
                  }
                }

                for (const item of propsList) {
                  const props = item.props;
                  if (!props) continue;
                  if (typeof props.onPointerDown === 'function') {
                    try { props.onPointerDown(makeSynthEvt('pointerdown', item.node)); } catch (_) {}
                  }
                  if (typeof props.onMouseDown === 'function') {
                    try { props.onMouseDown(makeSynthEvt('mousedown', item.node)); } catch (_) {}
                  }
                  if (typeof props.onPointerUp === 'function') {
                    try { props.onPointerUp(makeSynthEvt('pointerup', item.node)); } catch (_) {}
                  }
                  if (typeof props.onMouseUp === 'function') {
                    try { props.onMouseUp(makeSynthEvt('mouseup', item.node)); } catch (_) {}
                  }
                  if (typeof props.onTouchEnd === 'function') {
                    try { props.onTouchEnd(makeSynthEvt('touchend', item.node)); } catch (_) {}
                  }
                  if (typeof props.onPressStart === 'function') {
                    try { props.onPressStart({ type: 'pressstart', pointerType: 'touch', target: item.node, currentTarget: item.node, clientX: cx, clientY: cy, continuePropagation() {} }); } catch (_) {}
                  }
                  if (typeof props.onPressEnd === 'function') {
                    try { props.onPressEnd({ type: 'pressend', pointerType: 'touch', target: item.node, currentTarget: item.node, clientX: cx, clientY: cy, continuePropagation() {} }); } catch (_) {}
                  }
                  if (typeof props.onPress === 'function') {
                    try {
                      props.onPress({ type: 'press', pointerType: 'touch', target: item.node, currentTarget: item.node, clientX: cx, clientY: cy, continuePropagation() {} });
                      called = true;
                    } catch (_) {}
                  }
                  if (typeof props.onClick === 'function') {
                    try {
                      props.onClick(makeSynthEvt('click', item.node));
                      called = true;
                    } catch (_) {}
                  }
                }

                for (const zk of keys.filter(k => k.includes('__zone_symbol__click') || k.includes('__zone_symbol__pointerup'))) {
                  const tasks = el[zk];
                  if (Array.isArray(tasks)) {
                    for (const t of tasks) {
                      const fn = (t && (t.callback || t.invoke || t)) || null;
                      if (typeof fn === 'function') {
                        try { fn.call(el, makeSynthEvt('click', el).nativeEvent); called = true; } catch (_) {}
                      }
                    }
                  }
                }
              } catch (_) {}
            }
          } finally {
            window.__dmxForceTrusted = false;
          }
          return called;
        }

        async function dispatchTrustedClickSequence(targetEl, hitEl, cx, cy, pointerType = 'touch') {
          window.__dmxForceTrusted = true;
          try {
            const iconEl = (targetEl && targetEl.querySelector && targetEl.querySelector('i, mat-icon, svg, span')) || hitEl || targetEl;
            const nodes = [];
            if (iconEl) nodes.push(iconEl);
            if (hitEl && !nodes.includes(hitEl)) nodes.push(hitEl);
            if (targetEl && !nodes.includes(targetEl)) nodes.push(targetEl);

            const opts = {
              bubbles: true,
              cancelable: true,
              composed: true,
              view: window,
              clientX: cx,
              clientY: cy,
              screenX: cx,
              screenY: cy,
              button: 0,
              buttons: 1,
              detail: 1
            };
            const ptrOpts = {
              ...opts,
              pointerId: 1,
              width: 10,
              height: 10,
              pressure: 0.5,
              pointerType,
              isPrimary: true
            };

            const leaf = iconEl || hitEl || targetEl;
            if (!leaf) return;

            try { leaf.dispatchEvent(new PointerEvent('pointerover', ptrOpts)); } catch (_) {}
            try { leaf.dispatchEvent(new MouseEvent('mouseover', opts)); } catch (_) {}
            try { leaf.dispatchEvent(new PointerEvent('pointerdown', ptrOpts)); } catch (_) {}

            if (pointerType === 'touch') {
              try {
                if (typeof Touch !== 'undefined' && typeof TouchEvent !== 'undefined') {
                  const touchObj = new Touch({
                    identifier: 1,
                    target: leaf,
                    clientX: cx,
                    clientY: cy,
                    pageX: cx,
                    pageY: cy,
                    screenX: cx,
                    screenY: cy,
                    radiusX: 5,
                    radiusY: 5,
                    force: 0.5
                  });
                  leaf.dispatchEvent(new TouchEvent('touchstart', {
                    bubbles: true,
                    cancelable: true,
                    composed: true,
                    view: window,
                    touches: [touchObj],
                    targetTouches: [touchObj],
                    changedTouches: [touchObj]
                  }));
                }
              } catch (_) {}
            }

            try { leaf.dispatchEvent(new MouseEvent('mousedown', opts)); } catch (_) {}
            await sleep(45);

            if (pointerType === 'touch') {
              try {
                if (typeof Touch !== 'undefined' && typeof TouchEvent !== 'undefined') {
                  const touchObj = new Touch({
                    identifier: 1,
                    target: leaf,
                    clientX: cx,
                    clientY: cy,
                    pageX: cx,
                    pageY: cy,
                    screenX: cx,
                    screenY: cy,
                    radiusX: 5,
                    radiusY: 5,
                    force: 0.0
                  });
                  leaf.dispatchEvent(new TouchEvent('touchend', {
                    bubbles: true,
                    cancelable: true,
                    composed: true,
                    view: window,
                    touches: [],
                    targetTouches: [],
                    changedTouches: [touchObj]
                  }));
                }
              } catch (_) {}
            }

            try { leaf.dispatchEvent(new PointerEvent('pointerup', { ...ptrOpts, buttons: 0, pressure: 0 })); } catch (_) {}
            try { leaf.dispatchEvent(new MouseEvent('mouseup', { ...opts, buttons: 0 })); } catch (_) {}
            try { leaf.dispatchEvent(new MouseEvent('click', { ...opts, buttons: 0 })); } catch (_) {}
            for (const n of nodes) {
              try { if (typeof n.click === 'function') n.click(); } catch (_) {}
            }
          } finally {
            window.__dmxForceTrusted = false;
          }
        }

        function checkGenerationStarted(arrowBtn, promptBox) {
          if (hasActivePercentProgress()) return true;
          if (isWhiteArrowStillWaiting(promptBox)) return false;
          if (!arrowBtn || !arrowBtn.isConnected || !isVisible(arrowBtn, 16, 16)) return true;
          if (arrowBtn.disabled || arrowBtn.getAttribute('aria-disabled') === 'true') return true;
          if (!isWhiteBackgroundButton(arrowBtn)) return true;
          const curBox = (promptBox && promptBox.isConnected) ? promptBox : findPromptBox();
          if (!curBox || !isVisible(curBox, 24, 12) || getBoxText(curBox).length === 0) return true;
          return false;
        }

        async function clickArrowButtonAndVerify(arrowBtn, promptBox) {
          if (!arrowBtn) return false;
          const r = arrowBtn.getBoundingClientRect();
          const cx = r.left + r.width / 2;
          const cy = r.top + r.height / 2;
          const hitEl = document.elementFromPoint(cx, cy) || arrowBtn;
          const primaryBtn = (hitEl.closest && hitEl.closest('button, [role="button"], [type="submit"]'))
            || (arrowBtn.closest && arrowBtn.closest('button, [role="button"], [type="submit"]'))
            || arrowBtn;

          await dispatchTrustedClickSequence(primaryBtn, hitEl, cx, cy, 'touch');
          await sleep(650);
          if (checkGenerationStarted(primaryBtn, promptBox)) return true;

          triggerFrameworkClick(primaryBtn, hitEl, cx, cy);
          await sleep(650);
          if (checkGenerationStarted(primaryBtn, promptBox)) return true;

          window.__dmxForceTrusted = true;
          try {
            const frm = primaryBtn.closest && primaryBtn.closest('form');
            if (frm) {
              try {
                if (frm.requestSubmit) frm.requestSubmit(primaryBtn);
                else frm.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
              } catch (_) {}
            }
          } finally {
            window.__dmxForceTrusted = false;
          }
          await dispatchTrustedClickSequence(primaryBtn, hitEl, cx, cy, 'mouse');
          await sleep(600);
          if (checkGenerationStarted(primaryBtn, promptBox)) return true;

          window.__dmxForceTrusted = true;
          try {
            primaryBtn.focus();
            for (const k of [{ key: 'Enter', code: 'Enter', kc: 13 }, { key: ' ', code: 'Space', kc: 32 }]) {
              primaryBtn.dispatchEvent(new KeyboardEvent('keydown', { key: k.key, code: k.code, keyCode: k.kc, which: k.kc, bubbles: true, cancelable: true }));
              primaryBtn.dispatchEvent(new KeyboardEvent('keypress', { key: k.key, code: k.code, keyCode: k.kc, which: k.kc, bubbles: true, cancelable: true }));
              primaryBtn.dispatchEvent(new KeyboardEvent('keyup', { key: k.key, code: k.code, keyCode: k.kc, which: k.kc, bubbles: true, cancelable: true }));
            }
            if (promptBox) {
              promptBox.focus();
              promptBox.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', code: 'Enter', keyCode: 13, which: 13, bubbles: true, cancelable: true }));
              promptBox.dispatchEvent(new KeyboardEvent('keypress', { key: 'Enter', code: 'Enter', keyCode: 13, which: 13, bubbles: true, cancelable: true }));
              promptBox.dispatchEvent(new KeyboardEvent('keyup', { key: 'Enter', code: 'Enter', keyCode: 13, which: 13, bubbles: true, cancelable: true }));
            }
          } catch (_) {
          } finally {
            window.__dmxForceTrusted = false;
          }
          await sleep(600);
          return checkGenerationStarted(primaryBtn, promptBox);
        }

        // Xóa cache ảnh 1K cũ trước khi tạo ảnh mới
        window.__dmxHighResDataUrl = '';
        window.__dmxHighResWidth = 0;
        window.__dmxCapturedSignedUrls = [];

        const createdNewProject = await clickNewProjectIfNeeded();
        const cfgRes = await applyFlowSettings(targetAspect, targetModel);
        let box = findPromptBox();

        let promptOk = false;
        if (box && promptText) {
          promptOk = await fillPromptBox(box, promptText);
          await sleep(250);
        }

        let imgStatus = 'NO_IMAGE';
        if (imageBase64) {
          const beforeUploadSrcs = new Set(snapshotImageSrcs());
          imgStatus = await attachSampleImage(imageBase64, box);

          let sawProgress = false;
          let stableReadyTicks = 0;
          for (let i = 0; i < 80; i++) {
            await sleep(300);
            box = findPromptBox() || box;
            const uploadingPct = hasActivePercentProgress();
            if (uploadingPct) {
              sawProgress = true;
              stableReadyTicks = 0;
              continue;
            }
            const newMediaCount = countNewUploadedMedia(beforeUploadSrcs, box);
            if (newMediaCount > 0 && (sawProgress || i >= 6)) {
              stableReadyTicks += 1;
              if (stableReadyTicks >= 4) {
                break;
              }
            }
          }
          await sleep(450);
        } else {
          await sleep(300);
        }

        box = findPromptBox() || box;
        if (box && promptText) {
          const curTxt = getBoxText(box);
          if (!curTxt || !curTxt.includes(promptText.slice(0, 15))) {
            promptOk = await fillPromptBox(box, promptText);
          } else {
            promptOk = true;
            await nudgePromptBox(box);
          }
          await sleep(300);
        }

        const existingSrcs = snapshotImageSrcs();

        let clickedGenerate = false;
        let arrowInfo = 'NONE';
        if (promptOk || (box && getBoxText(box).length > 0)) {
          for (let i = 0; i < 30; i++) {
            if (hasActivePercentProgress()) {
              clickedGenerate = true;
              break;
            }
            box = findPromptBox() || box;
            if (box && promptText && getBoxText(box).length < 10) {
              if (i > 0 && arrowInfo !== 'NONE') {
                clickedGenerate = true;
                break;
              }
              await fillPromptBox(box, promptText);
              await sleep(250);
            }

            const arrowBtn = findGenerateArrowButton(box, true) || (i >= 4 ? findGenerateArrowButton(box, false) : null);
            if (arrowBtn) {
              const r = arrowBtn.getBoundingClientRect();
              const rgb = getBackgroundRGB(arrowBtn);
              arrowInfo = `${arrowBtn.tagName}(${Math.round(r.left)},${Math.round(r.top)},${Math.round(r.width)}x${Math.round(r.height)},rgb=${rgb.r}/${rgb.g}/${rgb.b})`;
              const isWhite = isWhiteBackgroundButton(arrowBtn);
              const isDis = !!(arrowBtn.disabled || arrowBtn.getAttribute('aria-disabled') === 'true');

              if ((!isWhite || isDis) && i < 6) {
                await nudgePromptBox(box);
                await sleep(350);
                continue;
              }

              const started = await clickArrowButtonAndVerify(arrowBtn, box);
              if (started) {
                clickedGenerate = true;
                break;
              }
              await nudgePromptBox(box);
            } else if (i === 2 || i === 6) {
              if (box) {
                try { box.click(); box.focus(); } catch (_) {}
              }
            }
            await sleep(350);
          }
        }

        return JSON.stringify({
          promptOk,
          imgStatus,
          aspectOk: cfgRes.aspectOk,
          modelOk: cfgRes.modelOk,
          clickedGenerate,
          arrowInfo,
          existingSrcs,
          foundBox: !!box
        });
        """#

        webViewFlow.callAsyncJavaScript(asyncJS, arguments: args, in: nil, in: .page) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.dangBomPromptFlow = false
                switch result {
                case .success(let val):
                    let raw = (val as? String) ?? ""
                    guard let d = raw.data(using: .utf8),
                          let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any] else {
                        if !tuDong {
                            self.hienToastFlow("Đã copy prompt — chạm ô nhập trên Flow rồi bấm Dán.", mauNen: UIColor.systemOrange.withAlphaComponent(0.92))
                        }
                        return
                    }
                    let promptOk = (obj["promptOk"] as? Bool) ?? false
                    let imgStatus = (obj["imgStatus"] as? String) ?? "NO_IMAGE"
                    let aspectOk = (obj["aspectOk"] as? Bool) ?? false
                    let modelOk = (obj["modelOk"] as? Bool) ?? false
                    let daGanAnh = imgStatus.hasPrefix("ATTACHED_")
                    let moTaCauHinh = (aspectOk || modelOk) ? " (\(tt.modelFlow) · \(tt.tyLeAnh))" : ""

                    let clickedGenerate = (obj["clickedGenerate"] as? Bool) ?? false
                    let existingSrcs = (obj["existingSrcs"] as? [String]) ?? []

                    if clickedGenerate {
                        self.hienToastFlow("Đã bấm tạo ảnh (→)\(moTaCauHinh) — đang chờ ảnh xong để tự tải bản 1K về app...", mauNen: BangMauBCTD.xanhChuDao.withAlphaComponent(0.92), giuLau: 5.0)
                        self.batDauChoVaTuLayAnhFlow(cacSrcCu: existingSrcs)
                    } else if promptOk {
                        self.hienToastFlow("Đã điền xong\(moTaCauHinh) — đang tự kích hoạt tạo ảnh (→) và chờ lấy bản 1K...", mauNen: BangMauBCTD.xanhLaDam.withAlphaComponent(0.92), giuLau: 4.5)
                        self.batDauChoVaTuLayAnhFlow(cacSrcCu: existingSrcs)
                    } else if daGanAnh {
                        self.hienToastFlow("Đã gửi ảnh mẫu — chạm ô nhập rồi bấm Dán prompt.", mauNen: UIColor.systemOrange.withAlphaComponent(0.92))
                    } else if !tuDong {
                        self.hienToastFlow("Chưa thấy ô nhập Flow (đã copy sẵn prompt để Dán).", mauNen: UIColor.systemOrange.withAlphaComponent(0.92))
                    }
                case .failure(_):
                    if !tuDong {
                        self.hienToastFlow("Đã copy sẵn prompt — chạm ô nhập trên Flow rồi bấm Dán.", mauNen: UIColor.systemOrange.withAlphaComponent(0.92))
                    }
                }
            }
        }
    }

    private func batDauChoVaTuLayAnhFlow(cacSrcCu: [String]) {
        maPhienChoAnhFlow += 1
        let phienHienTai = maPhienChoAnhFlow
        vongQuayFlow.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) { [weak self] in
            self?.kiemTraAnhMoiTuFlow(phien: phienHienTai, cacSrcCu: cacSrcCu, lanThu: 0)
        }
    }

    private func kiemTraAnhMoiTuFlow(phien: Int, cacSrcCu: [String], lanThu: Int) {
        guard phien == maPhienChoAnhFlow else { return }
        guard lanThu < 42 else {
            vongQuayFlow.stopAnimating()
            hienToastFlow("Chờ ảnh hơi lâu — khi thấy ảnh vẽ xong bạn bấm nút 📥 Lấy ảnh nhé.", mauNen: UIColor.systemOrange.withAlphaComponent(0.92), giuLau: 4.0)
            return
        }

        let pollJS = #"""
        function collectAllElements(root, out) {
          if (!root) return;
          const all = root.querySelectorAll ? root.querySelectorAll('*') : [];
          for (const el of all) {
            out.push(el);
            if (el.shadowRoot) collectAllElements(el.shadowRoot, out);
          }
        }

        function collectImgs(root, out) {
          if (!root) return;
          const imgs = root.querySelectorAll ? root.querySelectorAll('img') : [];
          for (const el of imgs) out.push(el);
          const all = root.querySelectorAll ? root.querySelectorAll('*') : [];
          for (const el of all) { if (el.shadowRoot) collectImgs(el.shadowRoot, out); }
        }

        function isVisible(el, minW = 16, minH = 12) {
          if (!el || !el.isConnected) return false;
          const st = window.getComputedStyle(el);
          if (!st || st.display === 'none' || st.visibility === 'hidden' || parseFloat(st.opacity) === 0) return false;
          const r = el.getBoundingClientRect();
          return r.width >= minW && r.height >= minH;
        }

        function getBackgroundRGB(el) {
          let cur = el;
          for (let k = 0; k < 4 && cur && cur !== document.body; k++) {
            try {
              const bg = window.getComputedStyle(cur).backgroundColor || '';
              const m = bg.match(/rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*([0-9.]+))?\s*\)/i);
              if (m) {
                const r = parseInt(m[1], 10), g = parseInt(m[2], 10), b = parseInt(m[3], 10);
                const a = m[4] !== undefined ? parseFloat(m[4]) : 1.0;
                if (a >= 0.35 && (r + g + b) > 30) return { r, g, b, sum: r + g + b };
              }
            } catch (_) {}
            cur = cur.parentElement;
          }
          return { r: 0, g: 0, b: 0, sum: 0 };
        }

        function isWhiteBackgroundButton(el) {
          const rgb = getBackgroundRGB(el);
          return rgb.r >= 135 && rgb.g >= 135 && rgb.b >= 135 && rgb.sum >= 420;
        }

        function hasStandalonePercentBadge() {
          const all = [];
          collectAllElements(document, all);
          for (const el of all) {
            if (el.children && el.children.length > 0) continue;
            if (el.closest && el.closest('textarea, [contenteditable], [data-slate-editor], [role="textbox"]')) continue;
            if (!isVisible(el, 8, 8)) continue;
            const t = (el.textContent || '').trim();
            if (/^(?:[1-9]|[1-9][0-9])%$/.test(t)) return true;
          }
          return false;
        }
        if (hasStandalonePercentBadge()) {
          return "WAITING";
        }

        if (window.__dmxHighResDataUrl && window.__dmxHighResWidth >= 900) {
          return "READY_FOR_1K";
        }

        function tryClickPendingArrowIfStillOpen() {
          const all = [];
          collectAllElements(document, all);
          let activeBox = null;
          for (const ed of all) {
            const tag = (ed.tagName || '').toUpperCase();
            const isEd = (ed.hasAttribute && ed.hasAttribute('data-slate-editor')) || tag === 'TEXTAREA' || ed.isContentEditable || (ed.getAttribute && ed.getAttribute('role') === 'textbox');
            if (!isEd || !isVisible(ed, 100, 20)) continue;
            const txt = (ed.value || ed.innerText || ed.textContent || '').trim();
            if (txt.length >= 15) { activeBox = ed; break; }
          }
          if (!activeBox) return false;
          const boxRect = activeBox.getBoundingClientRect();

          let best = null;
          let bestScore = -1;
          for (const rawEl of all) {
            if (!isVisible(rawEl, 14, 14)) continue;
            const el = (rawEl.closest && rawEl.closest('button, [role="button"], [type="submit"]')) || rawEl;
            if (!isVisible(el, 20, 20)) continue;
            const r = el.getBoundingClientRect();
            if (r.width < 20 || r.width > 80 || r.height < 20 || r.height > 80) continue;
            if (Math.abs(r.width - r.height) > 24) continue;
            const cx = r.left + r.width / 2, cy = r.top + r.height / 2;
            if (cx < window.innerWidth * 0.65) continue;
            if (cy < window.innerHeight * 0.45) continue;
            if (cy < boxRect.top + 28) continue;

            const rawText = (el.innerText || el.textContent || '').replace(/\s+/g, ' ').trim();
            if (/(nano banana|imagen|veo)/i.test(rawText) || /\bx[1-4]\b/i.test(rawText)) continue;
            if (/^(x|×|\u2715|\u2716|\+|close|đóng|add|thêm)$/i.test(rawText)) continue;

            const isWhite = isWhiteBackgroundButton(el);
            const isDis = !!(el.disabled || el.getAttribute('aria-disabled') === 'true');
            if (isDis && !isWhite) continue;

            let hasArrowIcon = /^(arrow_forward|arrow_upward|arrow_right_alt|east|send|north_east|→|➔|➜)$/i.test(rawText);
            if (!hasArrowIcon && el.querySelectorAll) {
              for (const ic of el.querySelectorAll('i, mat-icon, span, md-icon, google-symbol')) {
                if (/^(arrow_forward|arrow_upward|arrow_right_alt|east|send|north_east|→|➔|➜)$/i.test((ic.textContent || '').trim())) {
                  hasArrowIcon = true;
                  break;
                }
              }
            }

            let score = (r.right / Math.max(1, window.innerWidth)) * 100;
            if (hasArrowIcon) score += 500;
            if (isWhite) score += 320;
            if (el.matches && el.matches('button, [role="button"], [type="submit"]')) score += 120;
            if (score > bestScore) { bestScore = score; best = el; }
          }
          if (!best) return false;

          window.__dmxForceTrusted = true;
          try {
            const ar = best.getBoundingClientRect();
            const cx = ar.left + ar.width / 2, cy = ar.top + ar.height / 2;
            const hitEl = document.elementFromPoint(cx, cy) || best;
            const iconEl = (best.querySelector && best.querySelector('i, mat-icon, svg, span')) || hitEl;
            const opts = { bubbles: true, cancelable: true, composed: true, view: window, clientX: cx, clientY: cy, button: 0, buttons: 1 };
            try { iconEl.dispatchEvent(new PointerEvent('pointerdown', { ...opts, pointerId: 1, pointerType: 'touch', isPrimary: true })); } catch (_) {}
            try { iconEl.dispatchEvent(new MouseEvent('mousedown', opts)); } catch (_) {}
            try { iconEl.dispatchEvent(new PointerEvent('pointerup', { ...opts, buttons: 0, pointerId: 1, pointerType: 'touch', isPrimary: true })); } catch (_) {}
            try { iconEl.dispatchEvent(new MouseEvent('mouseup', { ...opts, buttons: 0 })); } catch (_) {}
            try { iconEl.click(); } catch (_) {}
            try { best.click(); } catch (_) {}
            try {
              const wrapTrusted = window.__dmxWrapTrustedEvent || ((e) => e);
              const keys = Object.keys(best);
              const propsKey = keys.find(k => k.startsWith('__reactProps$'));
              if (propsKey && best[propsKey] && typeof best[propsKey].onClick === 'function') {
                best[propsKey].onClick({
                  type: 'click',
                  nativeEvent: wrapTrusted(new MouseEvent('click', opts)),
                  currentTarget: best,
                  target: iconEl,
                  bubbles: true,
                  cancelable: true,
                  isTrusted: true,
                  clientX: cx,
                  clientY: cy,
                  button: 0,
                  preventDefault() {},
                  stopPropagation() {},
                  stopImmediatePropagation() {},
                  persist() {},
                  isDefaultPrevented() { return false; },
                  isPropagationStopped() { return false; }
                });
              }
            } catch (_) {}
          } finally {
            window.__dmxForceTrusted = false;
          }
          return true;
        }

        function isSampleUploadCard(imgEl) {
          let p = imgEl;
          for (let k = 0; k < 5 && p; k++) {
            const t = (p.innerText || p.textContent || '').toLowerCase();
            if (t.includes('san-pham-dmx')) return true;
            p = p.parentElement;
          }
          return false;
        }

        const oldSet = new Set(oldSrcs || []);
        const imgs = [];
        collectImgs(document, imgs);
        let newest = null;
        let bestArea = 0;

        for (const el of imgs) {
          if (!el.complete) continue;
          const r = el.getBoundingClientRect();
          if (r.width < 120 || r.height < 120) continue;
          const src = el.currentSrc || el.src || '';
          if (!src || oldSet.has(src)) continue;
          if (/^(data:image\/svg|blob:)/i.test(src)) continue;
          if (/(avatar|profile|logo|icon|googleusercontent\.com\/a\/)/i.test(src)) continue;
          if (isSampleUploadCard(el)) continue;
          const nw = el.naturalWidth || 0;
          const nh = el.naturalHeight || 0;
          if (nw < 512 || nh < 512) continue;
          const area = nw * nh;
          if (area >= bestArea) {
            bestArea = area;
            newest = el;
          }
        }

        if (!newest) {
          tryClickPendingArrowIfStillOpen();
          return "WAITING";
        }

        return "READY_FOR_1K";
        """#

        webViewFlow.callAsyncJavaScript(pollJS, arguments: ["oldSrcs": cacSrcCu], in: nil, in: .page) { [weak self] result in
            DispatchQueue.main.async {
                guard let self, phien == self.maPhienChoAnhFlow else { return }
                if case .success(let value) = result,
                   let str = value as? String,
                   str == "READY_FOR_1K" {
                    // Khi phát hiện ảnh mới đã tạo xong trên Flow -> gọi quy trình lấy bản 1K (1024px+) qua URL gốc hoặc menu Tải nội dung 1K
                    self.hienToastFlow("Ảnh đã vẽ xong — đang tự tải bản 1K (1024px+) về mục 4...", mauNen: BangMauBCTD.xanhLaDam.withAlphaComponent(0.92), giuLau: 4.0)
                    self.thucThiLayAnh1KTuFlow(cacSrcCu: cacSrcCu, tuDong: true)
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                    self?.kiemTraAnhMoiTuFlow(phien: phien, cacSrcCu: cacSrcCu, lanThu: lanThu + 1)
                }
            }
        }
    }

    // MARK: - WKNavigationDelegate & WKUIDelegate cho Google Flow

    private func taiAnhTrucTiepTuURLFlow(_ url: URL) {
        webViewFlow.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            let config = URLSessionConfiguration.ephemeral
            let storage = HTTPCookieStorage()
            for c in cookies { storage.setCookie(c) }
            config.httpCookieStorage = storage
            var req = URLRequest(url: url, timeoutInterval: 30)
            req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
            let session = URLSession(configuration: config)
            session.dataTask(with: req) { [weak self] data, _, _ in
                guard let self, let data, let rawImg = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    let img = self.nangCapLen1KNeuCan(rawImg)
                    let pxW = Int((img.size.width * img.scale).rounded())
                    let pxH = Int((img.size.height * img.scale).rounded())
                    self.nhanAnhChatLuongCaoTuFlow(img, nguon: (pxW >= 1800 || pxH >= 1800) ? "2K" : "1K")
                }
            }.resume()
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            let urlStr = url.absoluteString
            if navigationAction.shouldPerformDownload || urlStr.contains("flow-content.google") {
                if !urlStr.hasPrefix("blob:") && !urlStr.hasPrefix("data:") {
                    taiAnhTrucTiepTuURLFlow(url)
                }
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let mime = (navigationResponse.response.mimeType ?? "").lowercased()
        let isAttachment = ((navigationResponse.response as? HTTPURLResponse)?.allHeaderFields["Content-Disposition"] as? String ?? "").lowercased().contains("attachment")
        if (mime.hasPrefix("image/") && !navigationResponse.isForMainFrame) || isAttachment || !navigationResponse.canShowMIMEType {
            if let url = navigationResponse.response.url, !url.absoluteString.hasPrefix("blob:") {
                taiAnhTrucTiepTuURLFlow(url)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        vongQuayFlow.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        vongQuayFlow.stopAnimating()
        webView.evaluateJavaScript("document.body ? document.body.innerText : ''") { [weak self] res, _ in
            guard let self else { return }
            let bodyText = (res as? String) ?? ""
            if bodyText.localizedCaseInsensitiveContains("disallowed_useragent") {
                self.hienToastFlow("Google chặn đăng nhập — bấm nút ⋯ góc trên phải → Mở bằng Safari trong app.", mauNen: UIColor.systemRed.withAlphaComponent(0.92), giuLau: 5.0)
                return
            }
            let host = (webView.url?.host ?? "").lowercased()
            if !self.promptChoDienFlow.isEmpty && (host.contains("flow.google.com") || host.contains("labs.google")) {
                self.congViecBomPromptTuDong?.cancel()
                let congViec = DispatchWorkItem { [weak self] in
                    guard let self, !self.promptChoDienFlow.isEmpty, !self.dangBomPromptFlow else { return }
                    let taoMoi = self.canTaoDuAnMoiFlow
                    self.canTaoDuAnMoiFlow = false
                    self.bomPromptVaoWebViewFlow(self.promptChoDienFlow, tuDong: true, tuTaoDuAnMoi: taoMoi)
                }
                self.congViecBomPromptTuDong = congViec
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: congViec)
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        vongQuayFlow.stopAnimating()
        dangBomPromptFlow = false
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            if url.absoluteString.contains("flow-content.google") {
                taiAnhTrucTiepTuURLFlow(url)
                return nil
            }
            webView.load(URLRequest(url: url))
        }
        return nil
    }

    // MARK: - Các thẻ giao diện

    private func taoKhungThe(tieuDe: String) -> (the: UIView, noiDung: UIStackView) {
        let the = UIView()
        the.backgroundColor = BangMauBCTD.nenThePhu
        the.layer.cornerRadius = 14
        the.layer.borderWidth = 1
        the.layer.borderColor = BangMauBCTD.vienThe.cgColor

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        the.addSubview(stack)

        let lb = UILabel()
        lb.text = tieuDe
        lb.font = .systemFont(ofSize: 15, weight: .bold)
        lb.textColor = BangMauBCTD.chuChinh
        lb.numberOfLines = 0
        stack.addArrangedSubview(lb)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: the.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: the.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: the.trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: the.bottomAnchor, constant: -14)
        ])
        return (the, stack)
    }

    private func taoOChiTiet(_ tf: UITextField, goiY: String, banPhim: UIKeyboardType = .default) -> UITextField {
        tf.placeholder = goiY
        tf.keyboardType = banPhim
        tf.font = .systemFont(ofSize: 14.5)
        tf.textColor = BangMauBCTD.chuChinh
        tf.backgroundColor = BangMauBCTD.nenTrang
        tf.layer.cornerRadius = 10
        tf.layer.borderWidth = 1
        tf.layer.borderColor = BangMauBCTD.vienDam.cgColor
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        tf.rightViewMode = .always
        tf.heightAnchor.constraint(equalToConstant: 42).isActive = true
        return tf
    }

    private func taoNhanNho(_ text: String) -> UILabel {
        let lb = UILabel()
        lb.text = text
        lb.font = .systemFont(ofSize: 12.5, weight: .semibold)
        lb.textColor = BangMauBCTD.chuPhu
        return lb
    }

    private func taoThanhTabSanPham() -> UIView {
        let khung = UIView()
        khung.backgroundColor = BangMauBCTD.nenTrang
        khung.layer.cornerRadius = 12
        khung.layer.borderWidth = 1
        khung.layer.borderColor = BangMauBCTD.vienDam.cgColor

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        khung.addSubview(stack)

        let lbHuongDan = UILabel()
        lbHuongDan.text = "📦 Danh sách sản phẩm gộp chung vào 1 Poster:"
        lbHuongDan.font = .systemFont(ofSize: 13, weight: .bold)
        lbHuongDan.textColor = BangMauBCTD.chuChinh
        lbHuongDan.numberOfLines = 0
        stack.addArrangedSubview(lbHuongDan)

        cuonTabSanPham.showsHorizontalScrollIndicator = false
        cuonTabSanPham.translatesAutoresizingMaskIntoConstraints = false
        cuonTabSanPham.heightAnchor.constraint(equalToConstant: 38).isActive = true

        nganTabSanPham.axis = .horizontal
        nganTabSanPham.spacing = 8
        nganTabSanPham.alignment = .center
        nganTabSanPham.translatesAutoresizingMaskIntoConstraints = false
        cuonTabSanPham.addSubview(nganTabSanPham)

        NSLayoutConstraint.activate([
            nganTabSanPham.topAnchor.constraint(equalTo: cuonTabSanPham.contentLayoutGuide.topAnchor),
            nganTabSanPham.leadingAnchor.constraint(equalTo: cuonTabSanPham.contentLayoutGuide.leadingAnchor),
            nganTabSanPham.trailingAnchor.constraint(equalTo: cuonTabSanPham.contentLayoutGuide.trailingAnchor),
            nganTabSanPham.bottomAnchor.constraint(equalTo: cuonTabSanPham.contentLayoutGuide.bottomAnchor),
            nganTabSanPham.heightAnchor.constraint(equalTo: cuonTabSanPham.frameLayoutGuide.heightAnchor)
        ])
        stack.addArrangedSubview(cuonTabSanPham)

        nutThemSanPham.setTitle("➕ Thêm sản phẩm thứ 2", for: .normal)
        nutThemSanPham.titleLabel?.font = .systemFont(ofSize: 13.5, weight: .bold)
        nutThemSanPham.backgroundColor = BangMauBCTD.xanhLaDam
        nutThemSanPham.setTitleColor(.white, for: .normal)
        nutThemSanPham.layer.cornerRadius = 9
        nutThemSanPham.heightAnchor.constraint(equalToConstant: 36).isActive = true
        nutThemSanPham.addTarget(self, action: #selector(bamThemTabSanPham), for: .touchUpInside)

        nutXoaTabSanPham.setTitle("🗑 Xoá SP", for: .normal)
        nutXoaTabSanPham.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .semibold)
        nutXoaTabSanPham.backgroundColor = BangMauBCTD.nenThePhu
        nutXoaTabSanPham.setTitleColor(.systemRed, for: .normal)
        nutXoaTabSanPham.layer.cornerRadius = 9
        nutXoaTabSanPham.layer.borderWidth = 1
        nutXoaTabSanPham.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.35).cgColor
        nutXoaTabSanPham.heightAnchor.constraint(equalToConstant: 36).isActive = true
        nutXoaTabSanPham.widthAnchor.constraint(equalToConstant: 96).isActive = true
        nutXoaTabSanPham.isHidden = true
        nutXoaTabSanPham.addTarget(self, action: #selector(bamXoaTabSanPhamHienTai), for: .touchUpInside)

        let hangNutTab = UIStackView(arrangedSubviews: [nutThemSanPham, nutXoaTabSanPham])
        hangNutTab.axis = .horizontal
        hangNutTab.spacing = 8
        hangNutTab.alignment = .fill
        stack.addArrangedSubview(hangNutTab)

        nhanTomTatNhieuSP.font = .systemFont(ofSize: 12, weight: .medium)
        nhanTomTatNhieuSP.textColor = BangMauBCTD.xanhChuDao
        nhanTomTatNhieuSP.numberOfLines = 0
        stack.addArrangedSubview(nhanTomTatNhieuSP)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: khung.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: khung.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: khung.trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: khung.bottomAnchor, constant: -10)
        ])

        capNhatGiaoDienThanhTabSanPham()
        return khung
    }

    private func capNhatGiaoDienThanhTabSanPham() {
        for v in nganTabSanPham.arrangedSubviews {
            nganTabSanPham.removeArrangedSubview(v)
            v.removeFromSuperview()
        }

        for (idx, sp) in danhSachSanPham.enumerated() {
            let nut = UIButton(type: .system)
            nut.tag = idx
            let dangChon = (idx == chiSoSanPhamHienTai)
            let tenRutGon: String
            let tenClean = sp.tenSanPham.trimmingCharacters(in: .whitespacesAndNewlines)
            if !tenClean.isEmpty {
                let cat = tenClean.count > 14 ? String(tenClean.prefix(14)) + "…" : tenClean
                tenRutGon = "SP \(idx + 1): \(cat)"
            } else {
                tenRutGon = "Sản phẩm \(idx + 1)"
            }
            let kyHieuAnh = (sp.anhMau != nil) ? " 📷" : ""
            nut.setTitle(tenRutGon + kyHieuAnh, for: .normal)
            nut.titleLabel?.font = .systemFont(ofSize: 12.5, weight: dangChon ? .bold : .semibold)
            nut.backgroundColor = dangChon ? BangMauBCTD.xanhChuDao : BangMauBCTD.nenThePhu
            nut.setTitleColor(dangChon ? .white : BangMauBCTD.chuChinh, for: .normal)
            nut.layer.cornerRadius = 9
            nut.layer.borderWidth = 1
            nut.layer.borderColor = (dangChon ? BangMauBCTD.xanhChuDao : BangMauBCTD.vienDam).cgColor
            nut.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            nut.heightAnchor.constraint(equalToConstant: 34).isActive = true
            nut.addTarget(self, action: #selector(bamChonTabSanPham(_:)), for: .touchUpInside)
            nganTabSanPham.addArrangedSubview(nut)
        }

        // Nút "+ Thêm SP" nằm ngay cạnh tab sản phẩm cuối cùng trên thanh cuộn ngang
        let nutCongNhanh = UIButton(type: .system)
        nutCongNhanh.setTitle("＋ Thêm SP \(danhSachSanPham.count + 1)", for: .normal)
        nutCongNhanh.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        nutCongNhanh.backgroundColor = BangMauBCTD.xanhLaDam.withAlphaComponent(0.12)
        nutCongNhanh.setTitleColor(BangMauBCTD.xanhLaDam, for: .normal)
        nutCongNhanh.layer.cornerRadius = 9
        nutCongNhanh.layer.borderWidth = 1.2
        nutCongNhanh.layer.borderColor = BangMauBCTD.xanhLaDam.cgColor
        nutCongNhanh.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        nutCongNhanh.heightAnchor.constraint(equalToConstant: 34).isActive = true
        nutCongNhanh.addTarget(self, action: #selector(bamThemTabSanPham), for: .touchUpInside)
        nganTabSanPham.addArrangedSubview(nutCongNhanh)

        nutThemSanPham.setTitle("➕ Thêm sản phẩm thứ \(danhSachSanPham.count + 1) vào Poster", for: .normal)
        nutXoaTabSanPham.setTitle("🗑 Xoá SP \(chiSoSanPhamHienTai + 1)", for: .normal)
        nutXoaTabSanPham.isHidden = (danhSachSanPham.count <= 1)

        let soAnh = danhSachSanPham.filter { $0.anhMau != nil }.count
        if danhSachSanPham.count == 1 {
            nhanTomTatNhieuSP.text = "Đang nhập Sản phẩm 1 — bấm nút ➕ Thêm sản phẩm ở trên nếu muốn gộp nhiều sản phẩm & ảnh vào chung 1 Poster."
        } else {
            nhanTomTatNhieuSP.text = "✨ Đang sửa SP \(chiSoSanPhamHienTai + 1)/\(danhSachSanPham.count) (đã có \(soAnh) ảnh mẫu) — toàn bộ \(danhSachSanPham.count) sản phẩm sẽ tự gộp chung vào 1 Poster!"
        }
        capNhatThanhThuNhoAnhMau()
    }

    private func capNhatThanhThuNhoAnhMau() {
        for v in nganThuNhoAnh.arrangedSubviews {
            nganThuNhoAnh.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        let cacSPCoAnh = danhSachSanPham.enumerated().filter { $0.element.anhMau != nil }
        cuonThuNhoAnh.isHidden = (cacSPCoAnh.count <= 1)
        guard cacSPCoAnh.count > 1 else { return }

        for (idx, sp) in cacSPCoAnh {
            let khung = UIView()
            khung.translatesAutoresizingMaskIntoConstraints = false
            khung.widthAnchor.constraint(equalToConstant: 64).isActive = true
            khung.heightAnchor.constraint(equalToConstant: 64).isActive = true
            khung.layer.cornerRadius = 8
            khung.clipsToBounds = true
            khung.layer.borderWidth = (idx == chiSoSanPhamHienTai) ? 2.5 : 1.0
            khung.layer.borderColor = ((idx == chiSoSanPhamHienTai) ? BangMauBCTD.xanhChuDao : BangMauBCTD.vienDam).cgColor

            let iv = UIImageView(image: sp.anhMau)
            iv.contentMode = .scaleAspectFill
            iv.translatesAutoresizingMaskIntoConstraints = false
            khung.addSubview(iv)

            let lb = UILabel()
            lb.text = "SP \(idx + 1)"
            lb.font = .systemFont(ofSize: 10, weight: .bold)
            lb.textColor = .white
            lb.backgroundColor = UIColor.black.withAlphaComponent(0.65)
            lb.textAlignment = .center
            lb.translatesAutoresizingMaskIntoConstraints = false
            khung.addSubview(lb)

            let nutChon = UIButton(type: .custom)
            nutChon.tag = idx
            nutChon.translatesAutoresizingMaskIntoConstraints = false
            nutChon.addTarget(self, action: #selector(bamChonTabSanPham(_:)), for: .touchUpInside)
            khung.addSubview(nutChon)

            NSLayoutConstraint.activate([
                iv.topAnchor.constraint(equalTo: khung.topAnchor),
                iv.leadingAnchor.constraint(equalTo: khung.leadingAnchor),
                iv.trailingAnchor.constraint(equalTo: khung.trailingAnchor),
                iv.bottomAnchor.constraint(equalTo: khung.bottomAnchor),
                lb.leadingAnchor.constraint(equalTo: khung.leadingAnchor),
                lb.trailingAnchor.constraint(equalTo: khung.trailingAnchor),
                lb.bottomAnchor.constraint(equalTo: khung.bottomAnchor),
                lb.heightAnchor.constraint(equalToConstant: 16),
                nutChon.topAnchor.constraint(equalTo: khung.topAnchor),
                nutChon.leadingAnchor.constraint(equalTo: khung.leadingAnchor),
                nutChon.trailingAnchor.constraint(equalTo: khung.trailingAnchor),
                nutChon.bottomAnchor.constraint(equalTo: khung.bottomAnchor)
            ])
            nganThuNhoAnh.addArrangedSubview(khung)
        }
    }

    private func luuDuLieuTabHienTai() {
        guard chiSoSanPhamHienTai >= 0, chiSoSanPhamHienTai < danhSachSanPham.count else { return }
        danhSachSanPham[chiSoSanPhamHienTai].anhMau = anhMau
        danhSachSanPham[chiSoSanPhamHienTai].tenSanPham = (oTenSanPham.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        danhSachSanPham[chiSoSanPhamHienTai].giaNiemYet = (oGiaNiemYet.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        danhSachSanPham[chiSoSanPhamHienTai].giaKhuyenMai = (oGiaKhuyenMai.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        danhSachSanPham[chiSoSanPhamHienTai].uuDai = (oUuDai.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        danhSachSanPham[chiSoSanPhamHienTai].diemNoiBat = (oDiemNoiBat.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func napDuLieuTabHienTaiLenGiaoDien() {
        guard chiSoSanPhamHienTai >= 0, chiSoSanPhamHienTai < danhSachSanPham.count else { return }
        let sp = danhSachSanPham[chiSoSanPhamHienTai]
        anhMau = sp.anhMau
        anhMauView.image = sp.anhMau
        nhanChuaCoAnhMau.isHidden = (sp.anhMau != nil)
        nutXoaAnhMau.isHidden = (sp.anhMau == nil)
        nhanChuaCoAnhMau.text = "Chưa chọn ảnh mẫu cho Sản phẩm \(chiSoSanPhamHienTai + 1)\nBấm nút bên dưới để chọn ảnh từ thư viện"

        oTenSanPham.text = sp.tenSanPham
        oGiaNiemYet.text = sp.giaNiemYet
        oGiaKhuyenMai.text = sp.giaKhuyenMai
        oUuDai.text = sp.uuDai
        oDiemNoiBat.text = sp.diemNoiBat
        capNhatGiaoDienThanhTabSanPham()
        dongBoPromptTuDongNeuChuaSuaTay()
    }

    private func dongBoPromptTuDongNeuChuaSuaTay() {
        let cur = oPromptFlow.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cur.isEmpty || cur == promptFlowTuTaoGanNhat {
            let tt = thuThapThongTin()
            let coAnh = danhSachSanPham.contains { $0.anhMau != nil }
            if coAnh || danhSachSanPham.contains(where: { $0.coDuLieu }) {
                let pMoi = DichVuTruyenThongGemini.dungChung.taoPromptChoGoogleFlow(thongTin: tt, coAnhMau: coAnh)
                promptFlowTuTaoGanNhat = pMoi
                oPromptFlow.text = pMoi
            }
        }
    }

    @objc private func khiThayDoiThongTinSanPham() {
        luuDuLieuTabHienTai()
        capNhatGiaoDienThanhTabSanPham()
        dongBoPromptTuDongNeuChuaSuaTay()
    }

    @objc private func bamChonTabSanPham(_ sender: UIButton) {
        view.endEditing(true)
        luuDuLieuTabHienTai()
        let idx = sender.tag
        guard idx >= 0, idx < danhSachSanPham.count else { return }
        chiSoSanPhamHienTai = idx
        napDuLieuTabHienTaiLenGiaoDien()
    }

    @objc private func bamThemTabSanPham() {
        view.endEditing(true)
        luuDuLieuTabHienTai()
        danhSachSanPham.append(MucSanPhamPoster())
        chiSoSanPhamHienTai = danhSachSanPham.count - 1
        napDuLieuTabHienTaiLenGiaoDien()
    }

    @objc private func bamThemTabSanPhamTuThe2() {
        bamThemTabSanPham()
        cuon.setContentOffset(.zero, animated: true)
    }

    @objc private func bamXoaTabSanPhamHienTai() {
        view.endEditing(true)
        guard danhSachSanPham.count > 1 else { return }
        danhSachSanPham.remove(at: chiSoSanPhamHienTai)
        chiSoSanPhamHienTai = max(0, min(chiSoSanPhamHienTai, danhSachSanPham.count - 1))
        napDuLieuTabHienTaiLenGiaoDien()
    }

    private func taoTheAnhMau() -> UIView {
        let (the, stack) = taoKhungThe(tieuDe: "1. Ảnh mẫu & Tab sản phẩm (Gộp chung 1 Poster)")

        stack.addArrangedSubview(taoThanhTabSanPham())

        let khungAnh = UIView()
        khungAnh.backgroundColor = BangMauBCTD.nenTrang
        khungAnh.layer.cornerRadius = 12
        khungAnh.layer.borderWidth = 1
        khungAnh.layer.borderColor = BangMauBCTD.vienDam.cgColor
        khungAnh.clipsToBounds = true
        khungAnh.heightAnchor.constraint(equalToConstant: 200).isActive = true

        anhMauView.contentMode = .scaleAspectFit
        anhMauView.translatesAutoresizingMaskIntoConstraints = false
        khungAnh.addSubview(anhMauView)

        nhanChuaCoAnhMau.text = "Chưa chọn ảnh mẫu cho Sản phẩm 1\nBấm nút bên dưới để chọn ảnh sản phẩm từ thư viện"
        nhanChuaCoAnhMau.font = .systemFont(ofSize: 13)
        nhanChuaCoAnhMau.textColor = BangMauBCTD.chuPhu
        nhanChuaCoAnhMau.textAlignment = .center
        nhanChuaCoAnhMau.numberOfLines = 0
        nhanChuaCoAnhMau.translatesAutoresizingMaskIntoConstraints = false
        khungAnh.addSubview(nhanChuaCoAnhMau)

        NSLayoutConstraint.activate([
            anhMauView.topAnchor.constraint(equalTo: khungAnh.topAnchor),
            anhMauView.leadingAnchor.constraint(equalTo: khungAnh.leadingAnchor),
            anhMauView.trailingAnchor.constraint(equalTo: khungAnh.trailingAnchor),
            anhMauView.bottomAnchor.constraint(equalTo: khungAnh.bottomAnchor),
            nhanChuaCoAnhMau.centerXAnchor.constraint(equalTo: khungAnh.centerXAnchor),
            nhanChuaCoAnhMau.centerYAnchor.constraint(equalTo: khungAnh.centerYAnchor),
            nhanChuaCoAnhMau.leadingAnchor.constraint(equalTo: khungAnh.leadingAnchor, constant: 16),
            nhanChuaCoAnhMau.trailingAnchor.constraint(equalTo: khungAnh.trailingAnchor, constant: -16)
        ])
        stack.addArrangedSubview(khungAnh)

        cuonThuNhoAnh.showsHorizontalScrollIndicator = false
        cuonThuNhoAnh.translatesAutoresizingMaskIntoConstraints = false
        cuonThuNhoAnh.heightAnchor.constraint(equalToConstant: 66).isActive = true
        cuonThuNhoAnh.isHidden = true

        nganThuNhoAnh.axis = .horizontal
        nganThuNhoAnh.spacing = 8
        nganThuNhoAnh.alignment = .center
        nganThuNhoAnh.translatesAutoresizingMaskIntoConstraints = false
        cuonThuNhoAnh.addSubview(nganThuNhoAnh)

        NSLayoutConstraint.activate([
            nganThuNhoAnh.topAnchor.constraint(equalTo: cuonThuNhoAnh.contentLayoutGuide.topAnchor),
            nganThuNhoAnh.leadingAnchor.constraint(equalTo: cuonThuNhoAnh.contentLayoutGuide.leadingAnchor),
            nganThuNhoAnh.trailingAnchor.constraint(equalTo: cuonThuNhoAnh.contentLayoutGuide.trailingAnchor),
            nganThuNhoAnh.bottomAnchor.constraint(equalTo: cuonThuNhoAnh.contentLayoutGuide.bottomAnchor),
            nganThuNhoAnh.heightAnchor.constraint(equalTo: cuonThuNhoAnh.frameLayoutGuide.heightAnchor)
        ])
        stack.addArrangedSubview(cuonThuNhoAnh)

        nutNhapAnhMau.setTitle("📷 Chọn ảnh cho SP này", for: .normal)
        nutNhapAnhMau.titleLabel?.font = .systemFont(ofSize: 14.5, weight: .bold)
        nutNhapAnhMau.backgroundColor = BangMauBCTD.xanhChuDao
        nutNhapAnhMau.setTitleColor(.white, for: .normal)
        nutNhapAnhMau.layer.cornerRadius = 10
        nutNhapAnhMau.heightAnchor.constraint(equalToConstant: 42).isActive = true
        nutNhapAnhMau.addTarget(self, action: #selector(bamNhapAnhMau), for: .touchUpInside)

        nutXoaAnhMau.setTitle("Xoá ảnh", for: .normal)
        nutXoaAnhMau.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        nutXoaAnhMau.backgroundColor = BangMauBCTD.nenTrang
        nutXoaAnhMau.setTitleColor(.systemRed, for: .normal)
        nutXoaAnhMau.layer.cornerRadius = 10
        nutXoaAnhMau.layer.borderWidth = 1
        nutXoaAnhMau.layer.borderColor = BangMauBCTD.vienDam.cgColor
        nutXoaAnhMau.heightAnchor.constraint(equalToConstant: 42).isActive = true
        nutXoaAnhMau.widthAnchor.constraint(equalToConstant: 96).isActive = true
        nutXoaAnhMau.isHidden = true
        nutXoaAnhMau.addTarget(self, action: #selector(bamXoaAnhMau), for: .touchUpInside)

        let hangNut = UIStackView(arrangedSubviews: [nutNhapAnhMau, nutXoaAnhMau])
        hangNut.axis = .horizontal
        hangNut.spacing = 10
        stack.addArrangedSubview(hangNut)

        return the
    }

    private func taoTheThongTinSanPham() -> UIView {
        let (the, stack) = taoKhungThe(tieuDe: "2. Thông tin sản phẩm đang chọn & Cài đặt Poster")

        for tf in [oTenSanPham, oGiaNiemYet, oGiaKhuyenMai, oUuDai, oLienHe] {
            tf.addTarget(self, action: #selector(khiThayDoiThongTinSanPham), for: .editingChanged)
        }

        stack.addArrangedSubview(taoNhanNho("Tên sản phẩm (của tab đang chọn)"))
        stack.addArrangedSubview(taoOChiTiet(oTenSanPham, goiY: "VD: Máy lạnh Daikin Inverter 1 HP"))

        let cotGiaGoc = UIStackView(arrangedSubviews: [
            taoNhanNho("Giá niêm yết"),
            taoOChiTiet(oGiaNiemYet, goiY: "VD: 11.990.000đ")
        ])
        cotGiaGoc.axis = .vertical
        cotGiaGoc.spacing = 6

        let cotGiaKM = UIStackView(arrangedSubviews: [
            taoNhanNho("Giá khuyến mãi"),
            taoOChiTiet(oGiaKhuyenMai, goiY: "VD: 8.990.000đ")
        ])
        cotGiaKM.axis = .vertical
        cotGiaKM.spacing = 6

        let hangGia = UIStackView(arrangedSubviews: [cotGiaGoc, cotGiaKM])
        hangGia.axis = .horizontal
        hangGia.spacing = 10
        hangGia.distribution = .fillEqually
        stack.addArrangedSubview(hangGia)

        stack.addArrangedSubview(taoNhanNho("Ưu đãi / Quà tặng / Trả chậm (của SP đang chọn)"))
        stack.addArrangedSubview(taoOChiTiet(oUuDai, goiY: "VD: Trả chậm 0%, miễn phí lắp đặt, tặng ống đồng"))

        stack.addArrangedSubview(taoNhanNho("Điểm nổi bật / Ghi chú thêm (của SP đang chọn)"))
        oDiemNoiBat.font = .systemFont(ofSize: 14.5)
        oDiemNoiBat.textColor = BangMauBCTD.chuChinh
        oDiemNoiBat.backgroundColor = BangMauBCTD.nenTrang
        oDiemNoiBat.layer.cornerRadius = 10
        oDiemNoiBat.layer.borderWidth = 1
        oDiemNoiBat.layer.borderColor = BangMauBCTD.vienDam.cgColor
        oDiemNoiBat.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        oDiemNoiBat.heightAnchor.constraint(equalToConstant: 76).isActive = true
        oDiemNoiBat.delegate = self
        stack.addArrangedSubview(oDiemNoiBat)

        let nutThemSPOThe2 = UIButton(type: .system)
        nutThemSPOThe2.setTitle("➕ Thêm sản phẩm khác vào chung Poster", for: .normal)
        nutThemSPOThe2.titleLabel?.font = .systemFont(ofSize: 13.5, weight: .bold)
        nutThemSPOThe2.backgroundColor = BangMauBCTD.xanhLaDam.withAlphaComponent(0.12)
        nutThemSPOThe2.setTitleColor(BangMauBCTD.xanhLaDam, for: .normal)
        nutThemSPOThe2.layer.cornerRadius = 10
        nutThemSPOThe2.layer.borderWidth = 1.2
        nutThemSPOThe2.layer.borderColor = BangMauBCTD.xanhLaDam.cgColor
        nutThemSPOThe2.heightAnchor.constraint(equalToConstant: 38).isActive = true
        nutThemSPOThe2.addTarget(self, action: #selector(bamThemTabSanPhamTuThe2), for: .touchUpInside)
        stack.addArrangedSubview(nutThemSPOThe2)

        stack.addArrangedSubview(taoNhanNho("Siêu thị / Hotline / Địa chỉ (chung cho Poster)"))
        stack.addArrangedSubview(taoOChiTiet(oLienHe, goiY: "VD: ĐMX Siêu thị 76 · Hotline 09xx.xxx.xxx"))

        stack.addArrangedSubview(taoNhanNho("Kích thước / Tỷ lệ ảnh (đồng bộ Google Flow)"))
        chonTyLe.selectedSegmentIndex = 0
        stack.addArrangedSubview(chonTyLe)

        stack.addArrangedSubview(taoNhanNho("Model tạo ảnh trên Google Flow"))
        chonModelFlow.selectedSegmentIndex = 0
        chonModelFlow.apportionsSegmentWidthsByContent = true
        chonModelFlow.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 12.5, weight: .semibold)], for: .normal)
        chonModelFlow.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 12.5, weight: .bold)], for: .selected)
        stack.addArrangedSubview(chonModelFlow)

        stack.addArrangedSubview(taoNhanNho("Phong cách thiết kế ảnh"))
        chonPhongCachAnh.selectedSegmentIndex = 0
        chonPhongCachAnh.addTarget(self, action: #selector(khiThayDoiThongTinSanPham), for: .valueChanged)
        stack.addArrangedSubview(chonPhongCachAnh)

        return the
    }

    private func taoTheHanhDong() -> UIView {
        let (the, stack) = taoKhungThe(tieuDe: "3. Tạo ảnh Google Flow & 3 bài đăng Facebook")

        nutMoGoogleFlow.setTitle("🌊 Mở Google Flow + Tự viết 3 bài", for: .normal)
        nutMoGoogleFlow.titleLabel?.font = .systemFont(ofSize: 15.5, weight: .heavy)
        nutMoGoogleFlow.backgroundColor = BangMauBCTD.xanhLaDam
        nutMoGoogleFlow.setTitleColor(.white, for: .normal)
        nutMoGoogleFlow.layer.cornerRadius = 12
        nutMoGoogleFlow.heightAnchor.constraint(equalToConstant: 48).isActive = true
        nutMoGoogleFlow.addTarget(self, action: #selector(bamMoGoogleFlow), for: .touchUpInside)
        stack.addArrangedSubview(nutMoGoogleFlow)

        nutCopyPromptFlow.setTitle("📋 Copy Prompt Flow", for: .normal)
        nutCopyPromptFlow.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        nutCopyPromptFlow.backgroundColor = BangMauBCTD.nenTrang
        nutCopyPromptFlow.setTitleColor(BangMauBCTD.xanhLaDam, for: .normal)
        nutCopyPromptFlow.layer.cornerRadius = 10
        nutCopyPromptFlow.layer.borderWidth = 1
        nutCopyPromptFlow.layer.borderColor = BangMauBCTD.vienDam.cgColor
        nutCopyPromptFlow.heightAnchor.constraint(equalToConstant: 38).isActive = true
        nutCopyPromptFlow.addTarget(self, action: #selector(bamCopyPromptFlow), for: .touchUpInside)

        nutHuongDanFlow.setTitle("🔒 Safari trong app", for: .normal)
        nutHuongDanFlow.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        nutHuongDanFlow.backgroundColor = BangMauBCTD.nenTrang
        nutHuongDanFlow.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
        nutHuongDanFlow.layer.cornerRadius = 10
        nutHuongDanFlow.layer.borderWidth = 1
        nutHuongDanFlow.layer.borderColor = BangMauBCTD.vienDam.cgColor
        nutHuongDanFlow.heightAnchor.constraint(equalToConstant: 38).isActive = true
        nutHuongDanFlow.addTarget(self, action: #selector(bamHuongDanFlow), for: .touchUpInside)

        let hangFlowPhu = UIStackView(arrangedSubviews: [nutCopyPromptFlow, nutHuongDanFlow])
        hangFlowPhu.axis = .horizontal
        hangFlowPhu.spacing = 10
        hangFlowPhu.distribution = .fillEqually
        stack.addArrangedSubview(hangFlowPhu)

        stack.addArrangedSubview(taoNhanNho("Prompt sẽ tự điền vào Google Flow (có thể sửa tay nếu muốn):"))
        oPromptFlow.font = .systemFont(ofSize: 13)
        oPromptFlow.textColor = BangMauBCTD.chuChinh
        oPromptFlow.backgroundColor = BangMauBCTD.nenTrang
        oPromptFlow.layer.cornerRadius = 10
        oPromptFlow.layer.borderWidth = 1
        oPromptFlow.layer.borderColor = BangMauBCTD.vienDam.cgColor
        oPromptFlow.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        oPromptFlow.heightAnchor.constraint(equalToConstant: 86).isActive = true
        oPromptFlow.text = ""
        stack.addArrangedSubview(oPromptFlow)

        nutChiVietBai.setTitle("✍️ Viết 3 bài đăng Facebook (Gemini Free)", for: .normal)
        nutChiVietBai.titleLabel?.font = .systemFont(ofSize: 14.5, weight: .heavy)
        nutChiVietBai.backgroundColor = BangMauBCTD.xanhChuDao
        nutChiVietBai.setTitleColor(.white, for: .normal)
        nutChiVietBai.layer.cornerRadius = 12
        nutChiVietBai.heightAnchor.constraint(equalToConstant: 44).isActive = true
        nutChiVietBai.addTarget(self, action: #selector(bamChiVietBai), for: .touchUpInside)
        stack.addArrangedSubview(nutChiVietBai)

        nutTaoTatCa.setTitle("✨ Tạo ảnh API + 3 bài", for: .normal)
        nutTaoTatCa.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        nutTaoTatCa.backgroundColor = BangMauBCTD.nenTrang
        nutTaoTatCa.setTitleColor(BangMauBCTD.xanhChuDao, for: .normal)
        nutTaoTatCa.layer.cornerRadius = 10
        nutTaoTatCa.layer.borderWidth = 1
        nutTaoTatCa.layer.borderColor = BangMauBCTD.vienDam.cgColor
        nutTaoTatCa.heightAnchor.constraint(equalToConstant: 38).isActive = true
        nutTaoTatCa.addTarget(self, action: #selector(bamTaoTatCa), for: .touchUpInside)

        nutChiTaoAnh.setTitle("🎨 Tạo ảnh qua API", for: .normal)
        nutChiTaoAnh.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        nutChiTaoAnh.backgroundColor = BangMauBCTD.nenTrang
        nutChiTaoAnh.setTitleColor(BangMauBCTD.xanhChuDao, for: .normal)
        nutChiTaoAnh.layer.cornerRadius = 10
        nutChiTaoAnh.layer.borderWidth = 1
        nutChiTaoAnh.layer.borderColor = BangMauBCTD.vienDam.cgColor
        nutChiTaoAnh.heightAnchor.constraint(equalToConstant: 38).isActive = true
        nutChiTaoAnh.addTarget(self, action: #selector(bamChiTaoAnh), for: .touchUpInside)

        let hangPhu = UIStackView(arrangedSubviews: [nutTaoTatCa, nutChiTaoAnh])
        hangPhu.axis = .horizontal
        hangPhu.spacing = 10
        hangPhu.distribution = .fillEqually
        stack.addArrangedSubview(hangPhu)

        vongQuay.hidesWhenStopped = true
        nhanTrangThai.text = "Nhập 1 hoặc nhiều tab sản phẩm rồi bấm Mở Google Flow để tự gộp ảnh + điền prompt + tải ảnh 1K."
        nhanTrangThai.font = .systemFont(ofSize: 13)
        nhanTrangThai.textColor = BangMauBCTD.chuPhu
        nhanTrangThai.numberOfLines = 0

        let hangTT = UIStackView(arrangedSubviews: [vongQuay, nhanTrangThai])
        hangTT.axis = .horizontal
        hangTT.spacing = 8
        hangTT.alignment = .center
        stack.addArrangedSubview(hangTT)

        return the
    }

    private func taoTheAnhKetQua() -> UIView {
        let (the, stack) = taoKhungThe(tieuDe: "4. Ảnh truyền thông đã tạo")
        theAnhKetQua.isHidden = true
        theAnhKetQua.translatesAutoresizingMaskIntoConstraints = false
        the.translatesAutoresizingMaskIntoConstraints = false
        theAnhKetQua.addSubview(the)
        NSLayoutConstraint.activate([
            the.topAnchor.constraint(equalTo: theAnhKetQua.topAnchor),
            the.leadingAnchor.constraint(equalTo: theAnhKetQua.leadingAnchor),
            the.trailingAnchor.constraint(equalTo: theAnhKetQua.trailingAnchor),
            the.bottomAnchor.constraint(equalTo: theAnhKetQua.bottomAnchor)
        ])

        anhKetQuaView.contentMode = .scaleAspectFit
        anhKetQuaView.backgroundColor = BangMauBCTD.nenTrang
        anhKetQuaView.layer.cornerRadius = 12
        anhKetQuaView.layer.borderWidth = 1
        anhKetQuaView.layer.borderColor = BangMauBCTD.vienDam.cgColor
        anhKetQuaView.clipsToBounds = true
        anhKetQuaView.heightAnchor.constraint(equalToConstant: 320).isActive = true
        stack.addArrangedSubview(anhKetQuaView)

        nutLuuAnh.setTitle("💾 Lưu vào ảnh", for: .normal)
        nutLuuAnh.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        nutLuuAnh.backgroundColor = BangMauBCTD.xanhLaDam
        nutLuuAnh.setTitleColor(.white, for: .normal)
        nutLuuAnh.layer.cornerRadius = 10
        nutLuuAnh.heightAnchor.constraint(equalToConstant: 42).isActive = true
        nutLuuAnh.addTarget(self, action: #selector(bamLuuAnh), for: .touchUpInside)

        nutChiaSeAnh.setTitle("📤 Chia sẻ / Đăng FB", for: .normal)
        nutChiaSeAnh.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        nutChiaSeAnh.backgroundColor = BangMauBCTD.xanhChuDao
        nutChiaSeAnh.setTitleColor(.white, for: .normal)
        nutChiaSeAnh.layer.cornerRadius = 10
        nutChiaSeAnh.heightAnchor.constraint(equalToConstant: 42).isActive = true
        nutChiaSeAnh.addTarget(self, action: #selector(bamChiaSeAnh), for: .touchUpInside)

        let hangNut = UIStackView(arrangedSubviews: [nutLuuAnh, nutChiaSeAnh])
        hangNut.axis = .horizontal
        hangNut.spacing = 10
        hangNut.distribution = .fillEqually
        stack.addArrangedSubview(hangNut)

        return theAnhKetQua
    }

    private func taoTheBaiDangFacebook() -> UIView {
        let (the, stack) = taoKhungThe(tieuDe: "5. Kết quả bài đăng Facebook (3 phong cách)")

        chonPhongCachBai.selectedSegmentIndex = 0
        chonPhongCachBai.apportionsSegmentWidthsByContent = true
        chonPhongCachBai.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .semibold)], for: .normal)
        chonPhongCachBai.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .bold)], for: .selected)
        chonPhongCachBai.addTarget(self, action: #selector(doiPhongCachBai), for: .valueChanged)
        stack.addArrangedSubview(chonPhongCachBai)

        oBaiDangFB.font = .systemFont(ofSize: 14.5)
        oBaiDangFB.textColor = BangMauBCTD.chuChinh
        oBaiDangFB.backgroundColor = BangMauBCTD.nenTrang
        oBaiDangFB.layer.cornerRadius = 12
        oBaiDangFB.layer.borderWidth = 1
        oBaiDangFB.layer.borderColor = BangMauBCTD.vienDam.cgColor
        oBaiDangFB.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        oBaiDangFB.heightAnchor.constraint(equalToConstant: 240).isActive = true
        oBaiDangFB.delegate = self
        oBaiDangFB.text = "Nội dung bài đăng Facebook theo 3 phong cách (Hài hước, Chuyên nghiệp, Chốt sale) sẽ hiển thị ở đây sau khi tạo."
        stack.addArrangedSubview(oBaiDangFB)

        nutCopyBaiDang.setTitle("📋 Sao chép bài đăng đang chọn", for: .normal)
        nutCopyBaiDang.titleLabel?.font = .systemFont(ofSize: 14.5, weight: .bold)
        nutCopyBaiDang.backgroundColor = BangMauBCTD.nenTrang
        nutCopyBaiDang.setTitleColor(BangMauBCTD.xanhChuDao, for: .normal)
        nutCopyBaiDang.layer.cornerRadius = 10
        nutCopyBaiDang.layer.borderWidth = 1.2
        nutCopyBaiDang.layer.borderColor = BangMauBCTD.xanhChuDao.cgColor
        nutCopyBaiDang.heightAnchor.constraint(equalToConstant: 42).isActive = true
        nutCopyBaiDang.addTarget(self, action: #selector(bamCopyBaiDang), for: .touchUpInside)
        stack.addArrangedSubview(nutCopyBaiDang)

        return the
    }

    // MARK: - Chọn ảnh mẫu

    @objc private func bamNhapAnhMau() {
        view.endEditing(true)
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func bamXoaAnhMau() {
        anhMau = nil
        anhMauView.image = nil
        nhanChuaCoAnhMau.isHidden = false
        nutXoaAnhMau.isHidden = true
        luuDuLieuTabHienTai()
        capNhatGiaoDienThanhTabSanPham()
        dongBoPromptTuDongNeuChuaSuaTay()
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
            guard let img = obj as? UIImage else { return }
            DispatchQueue.main.async {
                guard let self else { return }
                self.anhMau = img
                self.anhMauView.image = img
                self.nhanChuaCoAnhMau.isHidden = true
                self.nutXoaAnhMau.isHidden = false
                self.luuDuLieuTabHienTai()
                self.capNhatGiaoDienThanhTabSanPham()
                self.dongBoPromptTuDongNeuChuaSuaTay()
            }
        }
    }

    // MARK: - Đọc dữ liệu nhập & gọi Gemini

    private func thuThapThongTin() -> ThongTinSanPhamTruyenThong {
        luuDuLieuTabHienTai()

        let dsTyLe = ["1:1", "3:4", "4:3", "9:16", "16:9"]
        let idxTyLe = max(0, min(chonTyLe.selectedSegmentIndex, dsTyLe.count - 1))
        let tyLe = dsTyLe[idxTyLe]

        let dsModelFlow = ["Nano Banana 2.1", "Nano Banana 2 Lite", "Nano Banana Pro"]
        let idxModel = max(0, min(chonModelFlow.selectedSegmentIndex, dsModelFlow.count - 1))
        let modelFlow = dsModelFlow[idxModel]

        let phongCachAnh: String
        switch chonPhongCachAnh.selectedSegmentIndex {
        case 1: phongCachAnh = "Sang trọng"
        case 2: phongCachAnh = "Flash Sale"
        default: phongCachAnh = "Rực rỡ ĐMX"
        }

        let spChinh = danhSachSanPham.first(where: { $0.coDuLieu }) ?? danhSachSanPham[chiSoSanPhamHienTai]
        return ThongTinSanPhamTruyenThong(
            tenSanPham: spChinh.tenSanPham,
            giaNiemYet: spChinh.giaNiemYet,
            giaKhuyenMai: spChinh.giaKhuyenMai,
            uuDai: spChinh.uuDai,
            diemNoiBat: spChinh.diemNoiBat,
            lienHe: (oLienHe.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            tyLeAnh: tyLe,
            modelFlow: modelFlow,
            phongCachAnh: phongCachAnh,
            danhSachSanPham: danhSachSanPham
        )
    }

    private func kiemTraHopLe(_ tt: ThongTinSanPhamTruyenThong) -> Bool {
        let coBatKySP = tt.danhSachSanPham.contains { $0.coDuLieu }
        if !coBatKySP && anhMau == nil && tt.tenSanPham.isEmpty && tt.giaKhuyenMai.isEmpty && tt.giaNiemYet.isEmpty {
            hienThongBao(tieuDe: "Thiếu thông tin", noiDung: "Hãy nhập ít nhất Tên sản phẩm / Giá bán hoặc chọn Ảnh mẫu ở ít nhất 1 tab sản phẩm trước khi tạo.")
            return false
        }
        return true
    }

    private func datTrangThaiDangTai(_ dangTai: Bool, thongDiep: String, mau: UIColor? = nil) {
        nutTaoTatCa.isEnabled = !dangTai
        nutChiTaoAnh.isEnabled = !dangTai
        nutChiVietBai.isEnabled = !dangTai
        nutTaoTatCa.alpha = dangTai ? 0.65 : 1.0
        if dangTai { vongQuay.startAnimating() } else { vongQuay.stopAnimating() }
        nhanTrangThai.text = thongDiep
        nhanTrangThai.textColor = mau ?? BangMauBCTD.chuPhu
    }

    private func chuanBiPromptGoogleFlow() -> String? {
        let tt = thuThapThongTin()
        guard kiemTraHopLe(tt) else { return nil }
        let promptHienTai = oPromptFlow.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !promptHienTai.isEmpty && promptHienTai != promptFlowTuTaoGanNhat {
            return promptHienTai
        }
        let coAnh = tt.danhSachSanPham.contains { $0.anhMau != nil }
        let promptMoi = DichVuTruyenThongGemini.dungChung.taoPromptChoGoogleFlow(
            thongTin: tt,
            coAnhMau: coAnh
        )
        promptFlowTuTaoGanNhat = promptMoi
        oPromptFlow.text = promptMoi
        return promptMoi
    }

    @objc private func bamMoGoogleFlow() {
        view.endEditing(true)
        let tt = thuThapThongTin()
        guard let prompt = chuanBiPromptGoogleFlow() else { return }
        let anhTongHop = layAnhMauTongHopChoPoster()

        promptChoDienFlow = prompt
        UIPasteboard.general.string = prompt

        if kiemTraHopLe(tt) {
            oBaiDangFB.text = "✍️ Đang tự động viết 3 phong cách bài đăng Facebook mới..."
            datTrangThaiDangTai(true, thongDiep: "Đang tự động viết 3 phong cách bài đăng Facebook chạy nền...")
            DichVuTruyenThongGemini.dungChung.tao3BaiDangFacebook(anhMau: anhTongHop, thongTin: tt) { [weak self] kq in
                guard let self else { return }
                switch kq {
                case .success(let baiMoi):
                    self.baiDang = baiMoi
                    self.hienThiBaiDangTheoPhongCachHienTai()
                    self.datTrangThaiDangTai(false, thongDiep: "Đã viết xong 3 phong cách bài đăng Facebook ✓", mau: BangMauBCTD.xanhLaDam)
                    if self.thanhChuyenCheDo.selectedSegmentIndex == 1 {
                        self.hienToastFlow("✓ Đã viết xong 3 bài FB (xem ở tab Tạo nội dung)", mauNen: BangMauBCTD.xanhLaDam.withAlphaComponent(0.92), giuLau: 2.5)
                    }
                case .failure(let err):
                    self.datTrangThaiDangTai(false, thongDiep: "⚠️ Lỗi viết bài nền: \(err.localizedDescription)", mau: .systemRed)
                }
            }
        }

        canTaoDuAnMoiFlow = true
        thanhChuyenCheDo.selectedSegmentIndex = 1
        khungTaoNoiDung.isHidden = true
        khungGoogleFlow.isHidden = false
        let soSP = max(1, tt.danhSachSanPham.filter { $0.coDuLieu }.count)
        let nhanSP = (soSP >= 2) ? "gộp \(soSP) SP · " : ""
        hienToastFlow("Đang tạo Dự án mới & \(nhanSP)đồng bộ \(tt.modelFlow) (\(tt.tyLeAnh))...", mauNen: BangMauBCTD.xanhChuDao.withAlphaComponent(0.92), giuLau: 4.5)

        let urlHienTai = webViewFlow.url?.absoluteString.lowercased() ?? ""
        if daTaiTrangFlow && (urlHienTai == "https://flow.google.com/" || urlHienTai == "https://flow.google.com") {
            canTaoDuAnMoiFlow = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self else { return }
                self.bomPromptVaoWebViewFlow(prompt, tuDong: true, tuTaoDuAnMoi: true)
            }
        } else {
            taiTrangGoogleFlow()
        }
    }

    @objc private func bamCopyPromptFlow() {
        view.endEditing(true)
        guard let prompt = chuanBiPromptGoogleFlow() else { return }
        UIPasteboard.general.string = prompt
        nhanTrangThai.text = "Đã tạo & sao chép prompt Google Flow vào bộ nhớ tạm."
        nhanTrangThai.textColor = BangMauBCTD.xanhLaDam
    }

    @objc private func bamHuongDanFlow() {
        view.endEditing(true)
        if let prompt = chuanBiPromptGoogleFlow() {
            promptChoDienFlow = prompt
            UIPasteboard.general.string = prompt
        }
        bamMoSafariTrongApp()
    }

    @objc private func bamTaoTatCa() {
        view.endEditing(true)
        let tt = thuThapThongTin()
        guard kiemTraHopLe(tt) else { return }
        let anhTongHop = layAnhMauTongHopChoPoster()

        datTrangThaiDangTai(true, thongDiep: "⚡ Gemini đang tạo ảnh truyền thông & viết 3 phong cách bài đăng...")

        let nhom = DispatchGroup()
        var kqAnh: Result<UIImage, Error>?
        var kqBai: Result<KetQua3BaiDangFacebook, Error>?

        nhom.enter()
        DichVuTruyenThongGemini.dungChung.taoAnhTruyenThong(anhMau: anhTongHop, thongTin: tt) { res in
            kqAnh = res
            nhom.leave()
        }

        nhom.enter()
        DichVuTruyenThongGemini.dungChung.tao3BaiDangFacebook(anhMau: anhTongHop, thongTin: tt) { res in
            kqBai = res
            nhom.leave()
        }

        nhom.notify(queue: .main) { [weak self] in
            guard let self else { return }
            var cacLoi: [String] = []
            if case .success(let img) = kqAnh {
                self.anhKetQua = img
                self.anhKetQuaView.image = img
                self.theAnhKetQua.isHidden = false
            } else if case .failure(let err) = kqAnh {
                cacLoi.append("Ảnh: \(err.localizedDescription)")
            }

            if case .success(let bai) = kqBai {
                self.baiDang = bai
                self.hienThiBaiDangTheoPhongCachHienTai()
            } else if case .failure(let err) = kqBai {
                cacLoi.append("Bài đăng: \(err.localizedDescription)")
            }

            if cacLoi.isEmpty {
                self.datTrangThaiDangTai(false, thongDiep: "✅ Đã tạo xong ảnh truyền thông và 3 phong cách bài đăng Facebook!", mau: BangMauBCTD.xanhLaDam)
            } else {
                self.datTrangThaiDangTai(false, thongDiep: "⚠️ " + cacLoi.joined(separator: "\n"), mau: .systemRed)
            }
        }
    }

    @objc private func bamChiTaoAnh() {
        view.endEditing(true)
        let tt = thuThapThongTin()
        guard kiemTraHopLe(tt) else { return }
        let anhTongHop = layAnhMauTongHopChoPoster()

        datTrangThaiDangTai(true, thongDiep: "🎨 Gemini đang tạo ảnh truyền thông...")
        DichVuTruyenThongGemini.dungChung.taoAnhTruyenThong(anhMau: anhTongHop, thongTin: tt) { [weak self] res in
            guard let self else { return }
            switch res {
            case .success(let img):
                self.anhKetQua = img
                self.anhKetQuaView.image = img
                self.theAnhKetQua.isHidden = false
                self.datTrangThaiDangTai(false, thongDiep: "✅ Đã tạo xong ảnh truyền thông mới!", mau: BangMauBCTD.xanhLaDam)
            case .failure(let err):
                self.datTrangThaiDangTai(false, thongDiep: "⚠️ Lỗi tạo ảnh: \(err.localizedDescription)", mau: .systemRed)
            }
        }
    }

    @objc private func bamChiVietBai() {
        view.endEditing(true)
        let tt = thuThapThongTin()
        guard kiemTraHopLe(tt) else { return }
        let anhTongHop = layAnhMauTongHopChoPoster()

        _ = chuanBiPromptGoogleFlow()
        oBaiDangFB.text = "✍️ Đang viết lại 3 phong cách bài đăng Facebook mới..."
        datTrangThaiDangTai(true, thongDiep: "✍️ Gemini Flash-Lite đang viết 3 phong cách bài đăng Facebook...")
        DichVuTruyenThongGemini.dungChung.tao3BaiDangFacebook(anhMau: anhTongHop, thongTin: tt) { [weak self] res in
            guard let self else { return }
            switch res {
            case .success(let bai):
                self.baiDang = bai
                self.hienThiBaiDangTheoPhongCachHienTai()
                self.oBaiDangFB.setContentOffset(.zero, animated: false)
                self.datTrangThaiDangTai(false, thongDiep: "✅ Đã cập nhật 3 phong cách bài đăng Facebook mới ở bên dưới!", mau: BangMauBCTD.xanhLaDam)
            case .failure(let err):
                self.hienThiBaiDangTheoPhongCachHienTai()
                self.datTrangThaiDangTai(false, thongDiep: "⚠️ Lỗi viết bài: \(err.localizedDescription)", mau: .systemRed)
            }
        }
    }

    // MARK: - Chuyển đổi 3 phong cách bài đăng & Lưu / Chia sẻ

    private func luuLaiBaiDangHienTaiTuTextView() {
        let text = oBaiDangFB.text ?? ""
        switch chiSoPhongCachHienTai {
        case 0: baiDang.haiHuoc = text
        case 1: baiDang.chuyenNghiep = text
        default: baiDang.chotSale = text
        }
    }

    private func hienThiBaiDangTheoPhongCachHienTai() {
        chiSoPhongCachHienTai = chonPhongCachBai.selectedSegmentIndex
        switch chiSoPhongCachHienTai {
        case 0: oBaiDangFB.text = baiDang.haiHuoc
        case 1: oBaiDangFB.text = baiDang.chuyenNghiep
        default: oBaiDangFB.text = baiDang.chotSale
        }
    }

    @objc private func doiPhongCachBai() {
        luuLaiBaiDangHienTaiTuTextView()
        hienThiBaiDangTheoPhongCachHienTai()
    }

    func textViewDidChange(_ textView: UITextView) {
        if textView === oBaiDangFB {
            luuLaiBaiDangHienTaiTuTextView()
        } else if textView === oDiemNoiBat {
            khiThayDoiThongTinSanPham()
        }
    }

    @objc private func bamCopyBaiDang() {
        view.endEditing(true)
        let text = (oBaiDangFB.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        UIPasteboard.general.string = text
        nhanTrangThai.text = "📋 Đã sao chép bài đăng vào bộ nhớ tạm!"
        nhanTrangThai.textColor = BangMauBCTD.xanhLaDam
    }

    private func chuanHoaDuLieuAnhDeLuu(_ img: UIImage) -> Data? {
        return autoreleasepool {
            // Vẽ lại ra CGImage chuẩn sRGB rồi xuất PNG (tránh lỗi -1 "Lỗi không xác định" của iOS khi lưu ảnh WebP/dữ liệu từ WebView)
            let w = max(1, Int((img.size.width * img.scale).rounded()))
            let h = max(1, Int((img.size.height * img.scale).rounded()))
            let fmt = UIGraphicsImageRendererFormat()
            fmt.scale = 1.0
            fmt.opaque = false
            let anhChuan = UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: fmt).image { _ in
                img.draw(in: CGRect(x: 0, y: 0, width: w, height: h))
            }
            return anhChuan.pngData() ?? anhChuan.jpegData(compressionQuality: 0.96)
        }
    }

    @objc private func bamLuuAnh() {
        guard let img = anhKetQua else { return }
        guard let dataAnh = chuanHoaDuLieuAnhDeLuu(img) else {
            hienThongBao(tieuDe: "Không lưu được ảnh", noiDung: "Không chuyển đổi được dữ liệu ảnh để lưu.")
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            guard let self else { return }
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    self.hienThongBao(
                        tieuDe: "Chưa có quyền Thư viện ảnh",
                        noiDung: "Vào Cài đặt → Tổng Hợp ĐMX → Ảnh và chọn “Chỉ thêm ảnh” hoặc “Truy cập đầy đủ” để lưu ảnh."
                    )
                }
                return
            }

            PHPhotoLibrary.shared().performChanges({
                let req = PHAssetCreationRequest.forAsset()
                req.addResource(with: .photo, data: dataAnh, options: nil)
            }) { thanhCong, loi in
                DispatchQueue.main.async {
                    if thanhCong {
                        self.hienThongBao(tieuDe: "Đã lưu ảnh", noiDung: "Ảnh truyền thông đã được lưu vào Thư viện ảnh của bạn.")
                    } else {
                        self.hienThongBao(tieuDe: "Không lưu được ảnh", noiDung: loi?.localizedDescription ?? "Không ghi được vào Thư viện ảnh.")
                    }
                }
            }
        }
    }

    @objc private func bamChiaSeAnh() {
        guard let img = anhKetQua else { return }
        let caption = (oBaiDangFB.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !caption.isEmpty {
            UIPasteboard.general.string = caption
        }
        var items: [Any] = [img]
        if !caption.isEmpty { items.append(caption) }
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let pop = vc.popoverPresentationController {
            pop.sourceView = nutChiaSeAnh
            pop.sourceRect = nutChiaSeAnh.bounds
        }
        present(vc, animated: true)
    }

    private func hienThongBao(tieuDe: String, noiDung: String) {
        let tb = UIAlertController(title: tieuDe, message: noiDung, preferredStyle: .alert)
        tb.addAction(UIAlertAction(title: "Đóng", style: .default))
        present(tb, animated: true)
    }
}
