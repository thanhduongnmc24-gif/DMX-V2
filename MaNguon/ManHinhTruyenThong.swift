import UIKit
import PhotosUI
import WebKit
import SafariServices

struct ThongTinSanPhamTruyenThong {
    var tenSanPham: String
    var giaNiemYet: String
    var giaKhuyenMai: String
    var uuDai: String
    var diemNoiBat: String
    var lienHe: String
    var tyLeAnh: String
    var phongCachAnh: String
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
        "gemini-3.8-flash",
        "gemini-2.5-flash",
        "gemini-2.5-flash-lite",
        "gemini-3.1-flash-lite-preview",
        "gemini-3.5-flash-lite"
    ]

    private func thuGonAnhMau(_ anh: UIImage) -> Data? {
        return autoreleasepool {
            let maxSide: CGFloat = 1280
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
        var chiTiet: [String] = []
        if !thongTin.tenSanPham.isEmpty { chiTiet.append("- Tên sản phẩm nổi bật: \"\(thongTin.tenSanPham)\"") }
        if !thongTin.giaNiemYet.isEmpty { chiTiet.append("- Giá niêm yết (gạch ngang nhỏ hơn): \"\(thongTin.giaNiemYet)\"") }
        if !thongTin.giaKhuyenMai.isEmpty { chiTiet.append("- Giá khuyến mãi / Giá sốc (to, đậm, nổi bật nhất): \"\(thongTin.giaKhuyenMai)\"") }
        if !thongTin.uuDai.isEmpty { chiTiet.append("- Ưu đãi / Quà tặng (huy hiệu / khung nổi bật): \"\(thongTin.uuDai)\"") }
        if !thongTin.diemNoiBat.isEmpty { chiTiet.append("- Điểm nổi bật (tối đa 2-3 nhãn ngắn gọn): \"\(thongTin.diemNoiBat)\"") }
        if !thongTin.lienHe.isEmpty { chiTiet.append("- Thông tin cửa hàng / liên hệ ở chân poster: \"\(thongTin.lienHe)\"") }

        let moTaPhongCach: String
        switch thongTin.phongCachAnh {
        case "Sang trọng":
            moTaPhongCach = "Phong cách hiện đại, sang trọng, nền sáng tinh tế (xanh navy đậm kết hợp trắng/vàng ánh kim), bố cục thoáng, sạch, chuẩn thương hiệu cao cấp."
        case "Flash Sale":
            moTaPhongCach = "Phong cách Flash Sale rực lửa, năng lượng cao (đỏ cam - vàng rực), tem giá sốc lớn, thu hút ánh nhìn ngay lập tức trên Facebook."
        default:
            moTaPhongCach = "Phong cách quảng cáo điện máy rực rỡ, chuyên nghiệp (xanh dương đậm kết hợp vàng nổi bật và trắng sạch sẽ), bố cục cân đối, dễ đọc trên điện thoại."
        }

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
                    let delay: TimeInterval = (status == 429 || status == 503) ? 0.4 : 0.05
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
            let promptBai = """
            Bạn là chuyên gia viết nội dung bán hàng Facebook cho siêu thị Điện Máy Xanh.
            Dựa vào ảnh sản phẩm (nếu có) và thông tin dưới đây, hãy viết 3 bài đăng Facebook hoàn chỉnh bằng tiếng Việt, tự nhiên, trình bày thoáng đẹp, có emoji hợp lý và 3-5 hashtag cuối bài:
            - Tên sản phẩm: \(thongTin.tenSanPham.isEmpty ? "(xem từ ảnh)" : thongTin.tenSanPham)
            - Giá niêm yết: \(thongTin.giaNiemYet.isEmpty ? "(không có)" : thongTin.giaNiemYet)
            - Giá khuyến mãi: \(thongTin.giaKhuyenMai.isEmpty ? "(không có)" : thongTin.giaKhuyenMai)
            - Ưu đãi / Quà tặng: \(thongTin.uuDai.isEmpty ? "(không có)" : thongTin.uuDai)
            - Điểm nổi bật / Ghi chú: \(thongTin.diemNoiBat.isEmpty ? "(không có)" : thongTin.diemNoiBat)
            - Siêu thị / Liên hệ: \(thongTin.lienHe.isEmpty ? "(nhắn tin hoặc bình luận để được tư vấn)" : thongTin.lienHe)

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
                "temperature": 0.8,
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

final class ManHinhTruyenThong: UIViewController, PHPickerViewControllerDelegate, UITextViewDelegate, WKNavigationDelegate, WKUIDelegate {
    private let thanhChuyenCheDo = UISegmentedControl(items: ["📝 Tạo nội dung", "🌊 Google Flow"])
    private let khungTaoNoiDung = UIView()
    private let khungGoogleFlow = UIView()
    private let cuon = UIScrollView()
    private let ngan = UIStackView()

    // Trình duyệt Google Flow nhúng ngay trong tab Truyền thông
    private var webViewFlow: WKWebView!
    private var daTaiTrangFlow = false
    private var promptChoDienFlow: String = ""
    private let nhanTrangThaiFlow = UILabel()
    private let vongQuayFlow = UIActivityIndicatorView(style: .medium)
    private let nutFlowLui = UIButton(type: .system)
    private let nutFlowTien = UIButton(type: .system)
    private let nutFlowTaiLai = UIButton(type: .system)
    private let nutFlowTrangChu = UIButton(type: .system)
    private let nutFlowDienPrompt = UIButton(type: .system)
    private let nutFlowLayAnh = UIButton(type: .system)
    private let nutFlowCopyPrompt = UIButton(type: .system)
    private let nutFlowSafariTrongApp = UIButton(type: .system)

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
    private let chonTyLe = UISegmentedControl(items: ["1:1 Vuông", "4:5 Dọc FB", "9:16 Story"])
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
            thanhChuyenCheDo.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            thanhChuyenCheDo.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            thanhChuyenCheDo.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            thanhChuyenCheDo.heightAnchor.constraint(equalToConstant: 34),

            khungTaoNoiDung.topAnchor.constraint(equalTo: thanhChuyenCheDo.bottomAnchor, constant: 8),
            khungTaoNoiDung.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            khungTaoNoiDung.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            khungTaoNoiDung.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            khungGoogleFlow.topAnchor.constraint(equalTo: thanhChuyenCheDo.bottomAnchor, constant: 8),
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

        webViewFlow = WKWebView(frame: .zero, configuration: config)
        webViewFlow.navigationDelegate = self
        webViewFlow.uiDelegate = self
        webViewFlow.allowsBackForwardNavigationGestures = true
        webViewFlow.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"
        webViewFlow.translatesAutoresizingMaskIntoConstraints = false

        for (nut, icon, action) in [
            (nutFlowLui, "chevron.left", #selector(bamFlowLui)),
            (nutFlowTien, "chevron.right", #selector(bamFlowTien)),
            (nutFlowTaiLai, "arrow.clockwise", #selector(bamFlowTaiLai)),
            (nutFlowTrangChu, "house", #selector(bamFlowTrangChu))
        ] {
            nut.setImage(UIImage(systemName: icon), for: .normal)
            nut.tintColor = BangMauBCTD.xanhChuDao
            nut.widthAnchor.constraint(equalToConstant: 32).isActive = true
            nut.heightAnchor.constraint(equalToConstant: 32).isActive = true
            nut.addTarget(self, action: action, for: .touchUpInside)
        }

        nutFlowDienPrompt.setTitle("✨ Điền Prompt", for: .normal)
        nutFlowDienPrompt.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        nutFlowDienPrompt.backgroundColor = BangMauBCTD.xanhLaDam
        nutFlowDienPrompt.setTitleColor(.white, for: .normal)
        nutFlowDienPrompt.layer.cornerRadius = 8
        nutFlowDienPrompt.heightAnchor.constraint(equalToConstant: 34).isActive = true
        nutFlowDienPrompt.addTarget(self, action: #selector(bamDienPromptVaoFlow), for: .touchUpInside)

        nutFlowCopyPrompt.setTitle("📋 Copy", for: .normal)
        nutFlowCopyPrompt.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        nutFlowCopyPrompt.backgroundColor = BangMauBCTD.nenTrang
        nutFlowCopyPrompt.setTitleColor(BangMauBCTD.xanhChuDao, for: .normal)
        nutFlowCopyPrompt.layer.cornerRadius = 8
        nutFlowCopyPrompt.layer.borderWidth = 1
        nutFlowCopyPrompt.layer.borderColor = BangMauBCTD.vienDam.cgColor
        nutFlowCopyPrompt.heightAnchor.constraint(equalToConstant: 34).isActive = true
        nutFlowCopyPrompt.addTarget(self, action: #selector(bamCopyPromptTrongFlow), for: .touchUpInside)

        nutFlowSafariTrongApp.setTitle("🔒 Safari trong app", for: .normal)
        nutFlowSafariTrongApp.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        nutFlowSafariTrongApp.backgroundColor = BangMauBCTD.nenTrang
        nutFlowSafariTrongApp.setTitleColor(BangMauBCTD.chuChinh, for: .normal)
        nutFlowSafariTrongApp.layer.cornerRadius = 8
        nutFlowSafariTrongApp.layer.borderWidth = 1
        nutFlowSafariTrongApp.layer.borderColor = BangMauBCTD.vienDam.cgColor
        nutFlowSafariTrongApp.heightAnchor.constraint(equalToConstant: 34).isActive = true
        nutFlowSafariTrongApp.addTarget(self, action: #selector(bamMoSafariTrongApp), for: .touchUpInside)

        let hangDieuHuong = UIStackView(arrangedSubviews: [nutFlowLui, nutFlowTien, nutFlowTaiLai, nutFlowTrangChu, UIView(), nutFlowSafariTrongApp])
        hangDieuHuong.axis = .horizontal
        hangDieuHuong.spacing = 4
        hangDieuHuong.alignment = .center

        nutFlowLayAnh.setTitle("📥 Lấy ảnh về app", for: .normal)
        nutFlowLayAnh.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .bold)
        nutFlowLayAnh.backgroundColor = BangMauBCTD.xanhChuDao
        nutFlowLayAnh.setTitleColor(.white, for: .normal)
        nutFlowLayAnh.layer.cornerRadius = 8
        nutFlowLayAnh.heightAnchor.constraint(equalToConstant: 34).isActive = true
        nutFlowLayAnh.addTarget(self, action: #selector(bamLayAnhTuFlow), for: .touchUpInside)

        let hangPrompt = UIStackView(arrangedSubviews: [nutFlowDienPrompt, nutFlowLayAnh, nutFlowCopyPrompt])
        hangPrompt.axis = .horizontal
        hangPrompt.spacing = 6
        hangPrompt.distribution = .fill
        nutFlowDienPrompt.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nutFlowLayAnh.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nutFlowDienPrompt.widthAnchor.constraint(equalTo: nutFlowLayAnh.widthAnchor).isActive = true
        nutFlowCopyPrompt.widthAnchor.constraint(equalToConstant: 72).isActive = true

        vongQuayFlow.hidesWhenStopped = true
        nhanTrangThaiFlow.text = "Mở dự án trong Google Flow rồi bấm "Điền Prompt" nếu chưa tự điền."
        nhanTrangThaiFlow.font = .systemFont(ofSize: 12)
        nhanTrangThaiFlow.textColor = BangMauBCTD.chuPhu
        nhanTrangThaiFlow.numberOfLines = 2

        let hangTrangThai = UIStackView(arrangedSubviews: [vongQuayFlow, nhanTrangThaiFlow])
        hangTrangThai.axis = .horizontal
        hangTrangThai.spacing = 6
        hangTrangThai.alignment = .center

        let thanhCongCu = UIStackView(arrangedSubviews: [hangDieuHuong, hangPrompt, hangTrangThai])
        thanhCongCu.axis = .vertical
        thanhCongCu.spacing = 6
        thanhCongCu.translatesAutoresizingMaskIntoConstraints = false

        let nenCongCu = UIView()
        nenCongCu.backgroundColor = BangMauBCTD.nenThePhu
        nenCongCu.translatesAutoresizingMaskIntoConstraints = false
        nenCongCu.addSubview(thanhCongCu)

        khungGoogleFlow.addSubview(nenCongCu)
        khungGoogleFlow.addSubview(webViewFlow)

        NSLayoutConstraint.activate([
            nenCongCu.topAnchor.constraint(equalTo: khungGoogleFlow.topAnchor),
            nenCongCu.leadingAnchor.constraint(equalTo: khungGoogleFlow.leadingAnchor),
            nenCongCu.trailingAnchor.constraint(equalTo: khungGoogleFlow.trailingAnchor),

            thanhCongCu.topAnchor.constraint(equalTo: nenCongCu.topAnchor, constant: 6),
            thanhCongCu.leadingAnchor.constraint(equalTo: nenCongCu.leadingAnchor, constant: 10),
            thanhCongCu.trailingAnchor.constraint(equalTo: nenCongCu.trailingAnchor, constant: -10),
            thanhCongCu.bottomAnchor.constraint(equalTo: nenCongCu.bottomAnchor, constant: -6),

            webViewFlow.topAnchor.constraint(equalTo: nenCongCu.bottomAnchor),
            webViewFlow.leadingAnchor.constraint(equalTo: khungGoogleFlow.leadingAnchor),
            webViewFlow.trailingAnchor.constraint(equalTo: khungGoogleFlow.trailingAnchor),
            webViewFlow.bottomAnchor.constraint(equalTo: khungGoogleFlow.bottomAnchor)
        ])
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

    @objc private func bamFlowLui() {
        if webViewFlow.canGoBack { webViewFlow.goBack() }
    }

    @objc private func bamFlowTien() {
        if webViewFlow.canGoForward { webViewFlow.goForward() }
    }

    @objc private func bamFlowTaiLai() {
        webViewFlow.reload()
    }

    @objc private func bamFlowTrangChu() {
        taiTrangGoogleFlow()
    }

    @objc private func bamCopyPromptTrongFlow() {
        let p = layPromptHienCoChoFlow()
        guard !p.isEmpty else {
            nhanTrangThaiFlow.text = "Chưa có prompt. Chuyển sang tab Tạo nội dung để nhập sản phẩm."
            nhanTrangThaiFlow.textColor = .systemOrange
            return
        }
        UIPasteboard.general.string = p
        nhanTrangThaiFlow.text = "Đã sao chép prompt vào bộ nhớ tạm."
        nhanTrangThaiFlow.textColor = BangMauBCTD.xanhLaDam
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
            nhanTrangThaiFlow.text = "Chưa có prompt. Quay lại tab Tạo nội dung nhập thông tin trước nhé."
            nhanTrangThaiFlow.textColor = .systemOrange
            return
        }
        UIPasteboard.general.string = p
        bomPromptVaoWebViewFlow(p, tuDong: false)
    }

    @objc private func bamLayAnhTuFlow() {
        nhanTrangThaiFlow.text = "Đang tìm và lấy ảnh kết quả từ Google Flow..."
        nhanTrangThaiFlow.textColor = BangMauBCTD.xanhChuDao
        vongQuayFlow.startAnimating()

        let asyncJS = """
        function collectMedia(root, out) {
          if (!root) return;
          const imgs = root.querySelectorAll ? root.querySelectorAll('img, canvas') : [];
          for (const el of imgs) out.push(el);
          const all = root.querySelectorAll ? root.querySelectorAll('*') : [];
          for (const el of all) { if (el.shadowRoot) collectMedia(el.shadowRoot, out); }
        }
        const nodes = [];
        collectMedia(document, nodes);
        let best = null;
        let bestArea = 0;
        for (const el of nodes) {
          const r = el.getBoundingClientRect();
          if (r.width < 120 || r.height < 120) continue;
          const nw = el.tagName === 'IMG' ? (el.naturalWidth || r.width) : (el.width || r.width);
          const nh = el.tagName === 'IMG' ? (el.naturalHeight || r.height) : (el.height || r.height);
          if (nw < 256 || nh < 256) continue;
          const src = el.tagName === 'IMG' ? (el.currentSrc || el.src || '') : '';
          if (el.tagName === 'IMG' && /(avatar|profile|logo|icon|googleusercontent\.com\/a\/)/i.test(src)) continue;
          const area = nw * nh;
          if (area >= bestArea) {
            bestArea = area;
            best = el;
          }
        }
        if (!best) return "NOT_FOUND";
        try {
          if (best.tagName === 'CANVAS') {
            return best.toDataURL('image/png');
          }
          const c = document.createElement('canvas');
          c.width = best.naturalWidth;
          c.height = best.naturalHeight;
          const ctx = c.getContext('2d');
          ctx.drawImage(best, 0, 0);
          return c.toDataURL('image/png');
        } catch (_) {}
        try {
          const src = best.currentSrc || best.src;
          if (!src) return "CORS_BLOCKED";
          const resp = await fetch(src, { credentials: 'include' });
          const blob = await resp.blob();
          return await new Promise((resolve) => {
            const fr = new FileReader();
            fr.onloadend = () => resolve(typeof fr.result === 'string' ? fr.result : 'CORS_BLOCKED');
            fr.onerror = () => resolve('CORS_BLOCKED');
            fr.readAsDataURL(blob);
          });
        } catch (_) {
          return "CORS_BLOCKED";
        }
        """

        webViewFlow.callAsyncJavaScript(asyncJS, arguments: [:], in: nil, in: .page) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.vongQuayFlow.stopAnimating()
                switch result {
                case .success(let value):
                    let str = (value as? String) ?? ""
                    if str == "NOT_FOUND" || str.isEmpty {
                        self.nhanTrangThaiFlow.text = "Chưa thấy ảnh kết quả lớn trên Flow. Hãy bấm tạo ảnh xong rồi bấm Lấy ảnh về app."
                        self.nhanTrangThaiFlow.textColor = .systemOrange
                        return
                    }
                    if str == "CORS_BLOCKED" || !str.hasPrefix("data:image/") {
                        self.nhanTrangThaiFlow.text = "Flow chặn đọc ảnh trực tiếp — bạn hãy bấm nút Tải xuống ngay trên giao diện Flow nhé."
                        self.nhanTrangThaiFlow.textColor = .systemOrange
                        return
                    }
                    guard let comma = str.firstIndex(of: ",") else { return }
                    let b64 = String(str[str.index(after: comma)...])
                    guard let data = Data(base64Encoded: b64), let img = UIImage(data: data) else {
                        self.nhanTrangThaiFlow.text = "Không giải mã được ảnh từ Flow. Hãy tải trực tiếp trên Flow."
                        self.nhanTrangThaiFlow.textColor = .systemOrange
                        return
                    }
                    self.anhKetQua = img
                    self.anhKetQuaView.image = img
                    self.theAnhKetQua.isHidden = false
                    self.nhanTrangThaiFlow.text = "Đã lấy ảnh từ Google Flow về mục 4 ✓"
                    self.nhanTrangThaiFlow.textColor = BangMauBCTD.xanhLaDam
                    self.thanhChuyenCheDo.selectedSegmentIndex = 0
                    self.doiCheDoTab()
                    self.nhanTrangThai.text = "Đã nhận ảnh từ Google Flow — bạn có thể Lưu hoặc Chia sẻ ngay bên dưới."
                    self.nhanTrangThai.textColor = BangMauBCTD.xanhLaDam
                case .failure(let err):
                    self.nhanTrangThaiFlow.text = "Không lấy được ảnh tự động (\(err.localizedDescription)). Hãy bấm tải trực tiếp trên Flow."
                    self.nhanTrangThaiFlow.textColor = .systemOrange
                }
            }
        }
    }

    private func bomPromptVaoWebViewFlow(_ prompt: String, tuDong: Bool) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: [prompt], options: []),
              let jsonArr = String(data: jsonData, encoding: .utf8) else { return }

        let js = """
        (function() {
          const text = (\(jsonArr))[0];
          function collect(root, out) {
            if (!root) return;
            const list = root.querySelectorAll ? root.querySelectorAll('textarea, [contenteditable="true"], [contenteditable=""], [role="textbox"]') : [];
            for (const el of list) out.push(el);
            const all = root.querySelectorAll ? root.querySelectorAll('*') : [];
            for (const el of all) { if (el.shadowRoot) collect(el.shadowRoot, out); }
          }
          function visible(el) {
            if (!el || !el.isConnected) return false;
            const st = window.getComputedStyle(el);
            if (!st || st.display === 'none' || st.visibility === 'hidden' || parseFloat(st.opacity) === 0) return false;
            const r = el.getBoundingClientRect();
            return r.width >= 80 && r.height >= 24;
          }
          const cands = [];
          collect(document, cands);
          let best = null, bestScore = -1;
          for (const el of cands) {
            if (!visible(el) || el.disabled || el.readOnly || el.getAttribute('aria-disabled') === 'true') continue;
            const meta = ((el.getAttribute('placeholder')||'') + ' ' + (el.getAttribute('aria-label')||'') + ' ' + (el.getAttribute('data-placeholder')||'') + ' ' + (el.id||'')).toLowerCase();
            if (/(search|tìm kiếm|rename|project name|tên dự án|title)/i.test(meta)) continue;
            let score = 0;
            const r = el.getBoundingClientRect();
            if (el.tagName === 'TEXTAREA') score += 40;
            if (el.getAttribute('contenteditable') === 'true' || el.getAttribute('role') === 'textbox') score += 30;
            if (/(prompt|describe|create|imagine|generate|what|idea|scene|mô tả|nhập|tạo)/i.test(meta)) score += 60;
            if (r.width >= 180) score += 20;
            if (r.top > window.innerHeight * 0.3) score += 15;
            if (score > bestScore) { bestScore = score; best = el; }
          }
          if (!best) return "NOT_FOUND";
          best.focus();
          if (best.tagName === 'TEXTAREA' || best.tagName === 'INPUT') {
            const proto = best.tagName === 'TEXTAREA' ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
            const setter = Object.getOwnPropertyDescriptor(proto, 'value')?.set;
            if (setter) setter.call(best, text); else best.value = text;
            best.dispatchEvent(new InputEvent('input', { bubbles: true, cancelable: true, inputType: 'insertText', data: text }));
            best.dispatchEvent(new Event('change', { bubbles: true }));
            return "FILLED";
          }
          const sel = window.getSelection();
          const range = document.createRange();
          range.selectNodeContents(best);
          sel.removeAllRanges();
          sel.addRange(range);
          const ok = document.execCommand && document.execCommand('insertText', false, text);
          if (!ok || (best.innerText || best.textContent || '').trim().length < Math.min(10, text.length)) {
            best.textContent = text;
            best.dispatchEvent(new InputEvent('input', { bubbles: true, cancelable: true, inputType: 'insertText', data: text }));
            best.dispatchEvent(new Event('change', { bubbles: true }));
          }
          return "FILLED";
        })();
        """

        webViewFlow.evaluateJavaScript(js) { [weak self] ketQua, _ in
            guard let self else { return }
            let kq = (ketQua as? String) ?? ""
            if kq == "FILLED" {
                self.nhanTrangThaiFlow.text = "Đã tự điền prompt vào Google Flow ✓"
                self.nhanTrangThaiFlow.textColor = BangMauBCTD.xanhLaDam
            } else if !tuDong {
                self.nhanTrangThaiFlow.text = "Chưa thấy ô nhập prompt (hãy mở một dự án trong Flow rồi bấm Điền Prompt lại, hoặc bấm Dán)."
                self.nhanTrangThaiFlow.textColor = .systemOrange
            }
        }
    }

    // MARK: - WKNavigationDelegate & WKUIDelegate cho Google Flow

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        vongQuayFlow.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        vongQuayFlow.stopAnimating()
        webView.evaluateJavaScript("document.body ? document.body.innerText : ''") { [weak self] res, _ in
            guard let self else { return }
            let bodyText = (res as? String) ?? ""
            if bodyText.localizedCaseInsensitiveContains("disallowed_useragent") {
                self.nhanTrangThaiFlow.text = "Google chặn đăng nhập ở khung này — hãy bấm nút "🔒 Safari trong app" ở góc phải trên."
                self.nhanTrangThaiFlow.textColor = .systemRed
                return
            }
            if !self.promptChoDienFlow.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                    guard let self, !self.promptChoDienFlow.isEmpty else { return }
                    self.bomPromptVaoWebViewFlow(self.promptChoDienFlow, tuDong: true)
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        vongQuayFlow.stopAnimating()
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
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

    private func taoTheAnhMau() -> UIView {
        let (the, stack) = taoKhungThe(tieuDe: "1. Ảnh mẫu sản phẩm")

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

        nhanChuaCoAnhMau.text = "Chưa chọn ảnh mẫu\nBấm nút bên dưới để chọn ảnh sản phẩm từ thư viện"
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

        nutNhapAnhMau.setTitle("📷 Nhập ảnh mẫu", for: .normal)
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
        let (the, stack) = taoKhungThe(tieuDe: "2. Thông tin sản phẩm & giá bán")

        stack.addArrangedSubview(taoNhanNho("Tên sản phẩm"))
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

        stack.addArrangedSubview(taoNhanNho("Ưu đãi / Quà tặng / Trả chậm"))
        stack.addArrangedSubview(taoOChiTiet(oUuDai, goiY: "VD: Trả chậm 0%, miễn phí lắp đặt, tặng ống đồng"))

        stack.addArrangedSubview(taoNhanNho("Điểm nổi bật / Ghi chú thêm"))
        oDiemNoiBat.font = .systemFont(ofSize: 14.5)
        oDiemNoiBat.textColor = BangMauBCTD.chuChinh
        oDiemNoiBat.backgroundColor = BangMauBCTD.nenTrang
        oDiemNoiBat.layer.cornerRadius = 10
        oDiemNoiBat.layer.borderWidth = 1
        oDiemNoiBat.layer.borderColor = BangMauBCTD.vienDam.cgColor
        oDiemNoiBat.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        oDiemNoiBat.heightAnchor.constraint(equalToConstant: 76).isActive = true
        stack.addArrangedSubview(oDiemNoiBat)

        stack.addArrangedSubview(taoNhanNho("Siêu thị / Hotline / Địa chỉ"))
        stack.addArrangedSubview(taoOChiTiet(oLienHe, goiY: "VD: ĐMX Siêu thị 76 · Hotline 09xx.xxx.xxx"))

        stack.addArrangedSubview(taoNhanNho("Tỷ lệ ảnh truyền thông"))
        chonTyLe.selectedSegmentIndex = 0
        stack.addArrangedSubview(chonTyLe)

        stack.addArrangedSubview(taoNhanNho("Phong cách thiết kế ảnh"))
        chonPhongCachAnh.selectedSegmentIndex = 0
        stack.addArrangedSubview(chonPhongCachAnh)

        return the
    }

    private func taoTheHanhDong() -> UIView {
        let (the, stack) = taoKhungThe(tieuDe: "3. Tạo ảnh Google Flow & 3 bài đăng Facebook")

        nutMoGoogleFlow.setTitle("🌊 Mở Google Flow ngay trong app", for: .normal)
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
        nhanTrangThai.text = "Nhập thông tin sản phẩm rồi bấm Mở Google Flow để tự điền prompt, hoặc bấm Viết 3 bài Facebook."
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
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
            guard let img = obj as? UIImage else { return }
            DispatchQueue.main.async {
                self?.anhMau = img
                self?.anhMauView.image = img
                self?.nhanChuaCoAnhMau.isHidden = true
                self?.nutXoaAnhMau.isHidden = false
            }
        }
    }

    // MARK: - Đọc dữ liệu nhập & gọi Gemini

    private func thuThapThongTin() -> ThongTinSanPhamTruyenThong {
        let tyLe: String
        switch chonTyLe.selectedSegmentIndex {
        case 1: tyLe = "4:5"
        case 2: tyLe = "9:16"
        default: tyLe = "1:1"
        }
        let phongCachAnh: String
        switch chonPhongCachAnh.selectedSegmentIndex {
        case 1: phongCachAnh = "Sang trọng"
        case 2: phongCachAnh = "Flash Sale"
        default: phongCachAnh = "Rực rỡ ĐMX"
        }
        return ThongTinSanPhamTruyenThong(
            tenSanPham: (oTenSanPham.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            giaNiemYet: (oGiaNiemYet.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            giaKhuyenMai: (oGiaKhuyenMai.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            uuDai: (oUuDai.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            diemNoiBat: (oDiemNoiBat.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            lienHe: (oLienHe.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            tyLeAnh: tyLe,
            phongCachAnh: phongCachAnh
        )
    }

    private func kiemTraHopLe(_ tt: ThongTinSanPhamTruyenThong) -> Bool {
        if anhMau == nil && tt.tenSanPham.isEmpty && tt.giaKhuyenMai.isEmpty && tt.giaNiemYet.isEmpty {
            hienThongBao(tieuDe: "Thiếu thông tin", noiDung: "Hãy nhập ít nhất Tên sản phẩm / Giá bán hoặc chọn Ảnh mẫu trước khi tạo.")
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
        let promptHienTai = oPromptFlow.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !promptHienTai.isEmpty && promptHienTai != promptFlowTuTaoGanNhat {
            return promptHienTai
        }
        let tt = thuThapThongTin()
        guard kiemTraHopLe(tt) else { return nil }
        let promptMoi = DichVuTruyenThongGemini.dungChung.taoPromptChoGoogleFlow(
            thongTin: tt,
            coAnhMau: anhMau != nil
        )
        promptFlowTuTaoGanNhat = promptMoi
        oPromptFlow.text = promptMoi
        return promptMoi
    }


    @objc private func bamMoGoogleFlow() {
        view.endEditing(true)
        guard let prompt = chuanBiPromptGoogleFlow() else { return }

        promptChoDienFlow = prompt
        UIPasteboard.general.string = prompt

        // Chuyển ngay sang tab Google Flow tích hợp trong app DMX
        thanhChuyenCheDo.selectedSegmentIndex = 1
        doiCheDoTab()

        nhanTrangThaiFlow.text = "Đã chuẩn bị prompt — đang tự điền vào Google Flow..."
        nhanTrangThaiFlow.textColor = BangMauBCTD.xanhChuDao

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.bomPromptVaoWebViewFlow(prompt, tuDong: true)
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

        datTrangThaiDangTai(true, thongDiep: "⚡ Gemini đang tạo ảnh truyền thông & viết 3 phong cách bài đăng...")

        let nhom = DispatchGroup()
        var kqAnh: Result<UIImage, Error>?
        var kqBai: Result<KetQua3BaiDangFacebook, Error>?

        nhom.enter()
        DichVuTruyenThongGemini.dungChung.taoAnhTruyenThong(anhMau: anhMau, thongTin: tt) { res in
            kqAnh = res
            nhom.leave()
        }

        nhom.enter()
        DichVuTruyenThongGemini.dungChung.tao3BaiDangFacebook(anhMau: anhMau, thongTin: tt) { res in
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

        datTrangThaiDangTai(true, thongDiep: "🎨 Gemini đang tạo ảnh truyền thông...")
        DichVuTruyenThongGemini.dungChung.taoAnhTruyenThong(anhMau: anhMau, thongTin: tt) { [weak self] res in
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

        datTrangThaiDangTai(true, thongDiep: "✍️ Gemini đang viết 3 phong cách bài đăng Facebook...")
        DichVuTruyenThongGemini.dungChung.tao3BaiDangFacebook(anhMau: anhMau, thongTin: tt) { [weak self] res in
            guard let self else { return }
            switch res {
            case .success(let bai):
                self.baiDang = bai
                self.hienThiBaiDangTheoPhongCachHienTai()
                self.datTrangThaiDangTai(false, thongDiep: "✅ Đã viết xong 3 phong cách bài đăng Facebook!", mau: BangMauBCTD.xanhLaDam)
            case .failure(let err):
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

    @objc private func bamLuuAnh() {
        guard let img = anhKetQua else { return }
        UIImageWriteToSavedPhotosAlbum(img, self, #selector(ketQuaLuuAnh(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func ketQuaLuuAnh(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error {
            hienThongBao(tieuDe: "Không lưu được ảnh", noiDung: error.localizedDescription)
        } else {
            hienThongBao(tieuDe: "Đã lưu ảnh", noiDung: "Ảnh truyền thông đã được lưu vào Thư viện ảnh của bạn.")
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
