import UIKit

/// Phân tích ảnh bảng số liệu bằng Gemini Flash (Phương pháp 3) với API Key tích hợp sẵn trong app hoặc API Key nhập mới ở Cài đặt.
final class DichVuQuetAnhGemini {
    static let dungChung = DichVuQuetAnhGemini()
    private let khoaModel404 = NSLock()
    private var cacModelKhongHoTro = Set<String>()
    private init() {}

    private func danhSachModelHopLe(modelUuTien: String) -> [(model: String, tatThinking: Bool)] {
        let ungVien: [(model: String, tatThinking: Bool)] = [
            ("gemini-3.1-flash", false),
            ("gemini-3-flash-preview", false),
            ("gemini-3.1-flash-lite-preview", false),
            (modelUuTien, modelUuTien.hasPrefix("gemini-2.5-flash")),
            ("gemini-2.5-flash", true),
            ("gemini-2.5-flash-lite", true),
            ("gemini-2.0-flash", false)
        ]
        khoaModel404.lock()
        let ds404 = cacModelKhongHoTro
        khoaModel404.unlock()
        var daCo = Set<String>()
        var kq: [(model: String, tatThinking: Bool)] = []
        for item in ungVien where !ds404.contains(item.model) {
            let k = "\(item.model)|\(item.tatThinking)"
            if !daCo.contains(k) {
                daCo.insert(k)
                kq.append(item)
            }
        }
        return kq.isEmpty ? [("gemini-2.5-flash", true), ("gemini-2.0-flash", false)] : kq
    }

    private struct CauHinhThuGemini {
        let key: String
        let model: String
        let tatThinking: Bool
    }

    /// Tạo danh sách cấu hình thử theo đúng số Key người dùng nhập:
    /// - Nhập 1 Key -> chỉ dùng đúng 1 Key đó
    /// - Nhập 2 Key -> phân bổ Ảnh 1 dùng Key 1, Ảnh 2 dùng Key 2 (xoay vòng dự phòng giữa 2 Key)
    /// - Nhập 3 Key -> phân bổ Ảnh 1 dùng Key 1, Ảnh 2 dùng Key 2, Ảnh 3 dùng Key 3 (xoay vòng dự phòng giữa 3 Key)
    private func taoDanhSachCapThu(chiSoAnh: Int, danhSachKey: [String], cacModel: [(model: String, tatThinking: Bool)]) -> [CauHinhThuGemini] {
        guard !danhSachKey.isEmpty else { return [] }
        var keyXoayVong: [String] = []
        for offset in 0..<danhSachKey.count {
            let k = danhSachKey[(chiSoAnh + offset) % danhSachKey.count]
            if !keyXoayVong.contains(k) {
                keyXoayVong.append(k)
            }
        }
        var cacCap: [CauHinhThuGemini] = []
        for m in cacModel {
            for k in keyXoayVong {
                cacCap.append(CauHinhThuGemini(key: k, model: m.model, tatThinking: m.tatThinking))
            }
        }
        return cacCap
    }

    func quet(
        danhSachAnh: [UIImage],
        cheDo: LoaiCheDoDoanhThu,
        tienTrinh: @escaping (String) -> Void,
        hoanTat: @escaping (Result<KetQuaQuetTatCaAnh, Error>) -> Void
    ) {
        let cd = KhoDuLieu.dungChung.layCaiDatAnToan()
        let danhSachKey = cd.danhSachGeminiApiKeyHieuLuc

        guard !danhSachKey.isEmpty else {
            hoanTat(.failure(NSError(domain: "GeminiVision", code: 400, userInfo: [NSLocalizedDescriptionKey: "Chưa có Gemini API Key."])))
            return
        }
        guard !danhSachAnh.isEmpty else {
            hoanTat(.failure(NSError(domain: "GeminiVision", code: 400, userInfo: [NSLocalizedDescriptionKey: "Chưa chọn ảnh để quét."])))
            return
        }

        var cacDuLieuAnh: [Data] = []
        for anh in danhSachAnh {
            if let d = duLieuAnhGon(anh) {
                cacDuLieuAnh.append(d)
            }
        }
        guard !cacDuLieuAnh.isEmpty else {
            hoanTat(.failure(NSError(domain: "GeminiVision", code: 400, userInfo: [NSLocalizedDescriptionKey: "Không thể đọc dữ liệu từ ảnh đã chọn."])))
            return
        }

        let cacModel = danhSachModelHopLe(modelUuTien: "gemini-3.1-flash")
        let tongAnh = cacDuLieuAnh.count
        let soLuongKey = max(1, min(3, danhSachKey.count))
        DispatchQueue.main.async {
            tienTrinh("Gemini Flash đang đọc \(tongAnh) ảnh bằng \(soLuongKey) Key (\(cheDo.tieuDe))...")
        }

        let khoaKetQua = NSLock()
        var ketQuaTungAnh = Array<KetQuaQuetTatCaAnh?>(repeating: nil, count: tongAnh)
        var loiCuoiCung: Error?
        var soAnhDaXong = 0

        let nhom = DispatchGroup()
        // Nhập 1 key chạy 1 luồng, 2 key chạy 2 luồng song song, 3 key chạy 3 luồng song song
        let semaphore = DispatchSemaphore(value: soLuongKey)

        DispatchQueue.global(qos: .userInitiated).async {
            for (idx, imgData) in cacDuLieuAnh.enumerated() {
                semaphore.wait()
                nhom.enter()
                let cacCapAnh = self.taoDanhSachCapThu(chiSoAnh: idx, danhSachKey: danhSachKey, cacModel: cacModel)
                let chiSoKeyHienThi = (idx % soLuongKey) + 1
                DispatchQueue.main.async {
                    tienTrinh("Gemini Flash (Key \(chiSoKeyHienThi)/\(soLuongKey)) đang phân tích ảnh \(idx + 1)/\(tongAnh)...")
                }
                self.goiGeminiChoMotAnh(
                    cacCap: cacCapAnh,
                    chiSo: 0,
                    cheDo: cheDo,
                    imageData: imgData
                ) { kqAnh in
                    khoaKetQua.lock()
                    soAnhDaXong += 1
                    let xongHienTai = soAnhDaXong
                    switch kqAnh {
                    case .success(let kq):
                        ketQuaTungAnh[idx] = kq
                    case .failure(let err):
                        loiCuoiCung = err
                    }
                    khoaKetQua.unlock()

                    DispatchQueue.main.async {
                        tienTrinh("Gemini Flash đã đọc \(xongHienTai)/\(tongAnh) ảnh (\(cheDo.tieuDe))...")
                    }
                    semaphore.signal()
                    nhom.leave()
                }
            }

            nhom.wait()

            var kqTong = KetQuaQuetTatCaAnh()
            var dtGop = ThongTinDoanhThu()
            let laRT = (cheDo == .realtime)

            for kq in ketQuaTungAnh.compactMap({ $0 }) {
                if kqTong.capNhatLuc.isEmpty && !kq.capNhatLuc.isEmpty {
                    kqTong.capNhatLuc = kq.capNhatLuc
                }
                if kqTong.thongTinDonVi.isEmpty && !kq.thongTinDonVi.isEmpty {
                    kqTong.thongTinDonVi = kq.thongTinDonVi
                }
                if let dt = kq.doanhThu, dt.coDuLieu {
                    dtGop = dtGop.gop(voi: dt, laRealtime: laRT)
                    kqTong.soAnhDoanhThu += max(1, kq.soAnhDoanhThu)
                }
                if !kq.danhSachThiDua.isEmpty {
                    kqTong.danhSachThiDua = KhoDuLieu.gopDanhSachThiDua(cu: kqTong.danhSachThiDua, moi: kq.danhSachThiDua)
                    kqTong.soAnhThiDua += max(1, kq.soAnhThiDua)
                }
                if !kq.doanhThuNhanVien.isEmpty {
                    kqTong.doanhThuNhanVien.append(contentsOf: kq.doanhThuNhanVien)
                    kqTong.soAnhDoanhThuNV += max(1, kq.soAnhDoanhThuNV)
                }
                if !kq.thiDuaNhanVien.isEmpty {
                    kqTong.thiDuaNhanVien = self.gopVaLamSachKhoiThiDuaNhanVien(kqTong.thiDuaNhanVien + kq.thiDuaNhanVien)
                    kqTong.soAnhThiDuaNV += max(1, kq.soAnhThiDuaNV)
                }
                if !kq.sucKhoeNhanVien.isEmpty {
                    for (ma, sk) in kq.sucKhoeNhanVien {
                        if let cu = kqTong.sucKhoeNhanVien[ma] {
                            kqTong.sucKhoeNhanVien[ma] = cu.gop(voi: sk)
                        } else {
                            kqTong.sucKhoeNhanVien[ma] = sk
                        }
                    }
                    kqTong.soAnhSucKhoeNV += max(1, kq.soAnhSucKhoeNV)
                }
            }

            if dtGop.coDuLieu {
                kqTong.doanhThu = dtGop
            }

            DispatchQueue.main.async {
                if kqTong.coDuLieu {
                    hoanTat(.success(kqTong))
                } else {
                    hoanTat(.failure(loiCuoiCung ?? NSError(
                        domain: "GeminiVision",
                        code: 422,
                        userInfo: [NSLocalizedDescriptionKey: "Gemini Flash không tìm thấy bảng số liệu hợp lệ trong ảnh."]
                    )))
                }
            }
        }
    }

    /// Nén ảnh sắc nét (hỗ trợ cắt xếp dọc cho ảnh Bảng ngang siêu rộng để không bị mờ chữ 39 cột, và giữ độ nét 2048px cho Bảng dọc / Lưới 6 cột).
    private func duLieuAnhGon(_ anh: UIImage) -> Data? {
        let w = anh.size.width
        let h = anh.size.height
        guard w > 10, h > 10 else { return anh.jpegData(compressionQuality: 0.84) }

        // Giữ nguyên toàn bộ khung ảnh bảng 13 cột (không cắt thành 4 dải dọc làm đứt đôi các cột ở vị trí nối)

        // Nếu là ảnh Bảng ngang siêu rộng của Siêu thị (width > height * 11.5): cắt thành 4 dải ngang có chồng lấp 3% và xếp dọc trên 1 khung ảnh rộng 2200px
        if w > h * 11.5, let cg = anh.cgImage {
            let cw = CGFloat(cg.width)
            let ch = CGFloat(cg.height)
            let cacDai: [(CGFloat, CGFloat)] = [
                (0.00, 0.27),
                (0.24, 0.52),
                (0.49, 0.77),
                (0.74, 1.00)
            ]
            let rongDich: CGFloat = min(2200, max(1600, cw * 0.28))
            let demDoc: CGFloat = 20
            var cacAnhDai: [(img: CGImage, caoVe: CGFloat)] = []
            for (x0, x1) in cacDai {
                let rect = CGRect(
                    x: (cw * x0).rounded(),
                    y: 0,
                    width: max(1, (cw * (x1 - x0)).rounded()),
                    height: ch
                )
                if let sub = cg.cropping(to: rect) {
                    let tyLe = rongDich / CGFloat(sub.width)
                    let caoVe = max(80, (CGFloat(sub.height) * tyLe).rounded())
                    cacAnhDai.append((sub, caoVe))
                }
            }
            if !cacAnhDai.isEmpty {
                let tongCao = cacAnhDai.reduce(CGFloat(0)) { $0 + $1.caoVe } + CGFloat(cacAnhDai.count + 1) * demDoc
                let dinhDang = UIGraphicsImageRendererFormat.default()
                dinhDang.scale = 1.0
                dinhDang.opaque = true
                let boVe = UIGraphicsImageRenderer(size: CGSize(width: rongDich, height: tongCao), format: dinhDang)
                let anhGhep = boVe.image { ctx in
                    UIColor.white.setFill()
                    ctx.fill(CGRect(x: 0, y: 0, width: rongDich, height: tongCao))
                    var yHienTai = demDoc
                    for item in cacAnhDai {
                        UIImage(cgImage: item.img, scale: 1.0, orientation: anh.imageOrientation)
                            .draw(in: CGRect(x: 0, y: yHienTai, width: rongDich, height: item.caoVe))
                        yHienTai += item.caoVe + demDoc
                    }
                }
                return anhGhep.jpegData(compressionQuality: 0.85)
            }
        }

        let gioiHan: CGFloat = 2560
        let canhLon = max(w, h)
        guard canhLon > gioiHan else { return anh.jpegData(compressionQuality: 0.88) }
        let tiLe = gioiHan / canhLon
        let kichThuoc = CGSize(width: (w * tiLe).rounded(), height: (h * tiLe).rounded())
        let dinhDang = UIGraphicsImageRendererFormat.default()
        dinhDang.scale = 1.0
        dinhDang.opaque = true
        let boVe = UIGraphicsImageRenderer(size: kichThuoc, format: dinhDang)
        let anhGon = boVe.image { _ in
            anh.draw(in: CGRect(origin: .zero, size: kichThuoc))
        }
        return anhGon.jpegData(compressionQuality: 0.88)
    }

    private func taoBodyData(imageData: Data, cheDo: LoaiCheDoDoanhThu, tatThinking: Bool, promptTuChon: String? = nil) -> Data? {
        let parts: [[String: Any]] = [
            ["text": promptTuChon ?? prompt(cheDo: cheDo)],
            ["inline_data": ["mime_type": "image/jpeg", "data": imageData.base64EncodedString()]]
        ]
        var genConfig: [String: Any] = [
            "temperature": 0.0,
            "maxOutputTokens": 8192,
            "responseMimeType": "application/json"
        ]
        if tatThinking {
            // Tắt hoàn toàn thinking trên gemini-2.5-flash để trả kết quả ngay lập tức (2-4s) và không bị cắt cụt JSON
            genConfig["thinkingConfig"] = ["thinkingBudget": 0]
        }
        let body: [String: Any] = [
            "contents": [["parts": parts]],
            "generationConfig": genConfig
        ]
        return try? JSONSerialization.data(withJSONObject: body)
    }

    private func goiGeminiChoMotAnh(
        cacCap: [CauHinhThuGemini],
        chiSo: Int,
        cheDo: LoaiCheDoDoanhThu,
        imageData: Data,
        promptTuChon: String? = nil,
        hoanTat: @escaping (Result<KetQuaQuetTatCaAnh, Error>) -> Void
    ) {
        guard chiSo < cacCap.count else {
            hoanTat(.failure(NSError(
                domain: "GeminiVision",
                code: 503,
                userInfo: [NSLocalizedDescriptionKey: "Không kết nối được Gemini Flash. Hãy kiểm tra mạng hoặc API Key trong Cài đặt."]
            )))
            return
        }
        let cap = cacCap[chiSo]
        guard var thanhPhan = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/\(cap.model):generateContent") else {
            goiGeminiChoMotAnh(cacCap: cacCap, chiSo: chiSo + 1, cheDo: cheDo, imageData: imageData, promptTuChon: promptTuChon, hoanTat: hoanTat)
            return
        }
        thanhPhan.queryItems = [URLQueryItem(name: "key", value: cap.key)]
        guard let url = thanhPhan.url,
              let bodyData = taoBodyData(imageData: imageData, cheDo: cheDo, tatThinking: cap.tatThinking, promptTuChon: promptTuChon) else {
            goiGeminiChoMotAnh(cacCap: cacCap, chiSo: chiSo + 1, cheDo: cheDo, imageData: imageData, promptTuChon: promptTuChon, hoanTat: hoanTat)
            return
        }

        var req = URLRequest(url: url, timeoutInterval: 25)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = bodyData

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            guard let self else { return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if status == 404 {
                self.khoaModel404.lock()
                self.cacModelKhongHoTro.insert(cap.model)
                self.khoaModel404.unlock()
            }
            if error != nil || status != 200 {
                if chiSo + 1 < cacCap.count {
                    self.goiGeminiChoMotAnh(cacCap: cacCap, chiSo: chiSo + 1, cheDo: cheDo, imageData: imageData, promptTuChon: promptTuChon, hoanTat: hoanTat)
                    return
                }
                let loi = data.map { self.thongDiepLoi(tu: $0, status: status) } ?? (error?.localizedDescription ?? "Gemini Flash không phản hồi.")
                hoanTat(.failure(NSError(domain: "GeminiVision", code: status, userInfo: [NSLocalizedDescriptionKey: loi])))
                return
            }

            guard let data, let json = self.layJSONKetQua(tu: data) else {
                if chiSo + 1 < cacCap.count {
                    self.goiGeminiChoMotAnh(cacCap: cacCap, chiSo: chiSo + 1, cheDo: cheDo, imageData: imageData, promptTuChon: promptTuChon, hoanTat: hoanTat)
                    return
                }
                hoanTat(.failure(NSError(
                    domain: "GeminiVision",
                    code: 422,
                    userInfo: [NSLocalizedDescriptionKey: "Gemini Flash đã phản hồi nhưng nội dung không đúng định dạng JSON số liệu."]
                )))
                return
            }

            let ketQua = self.chuyen(json: json, cheDo: cheDo)
            guard ketQua.coDuLieu else {
                if chiSo + 1 < cacCap.count {
                    self.goiGeminiChoMotAnh(cacCap: cacCap, chiSo: chiSo + 1, cheDo: cheDo, imageData: imageData, promptTuChon: promptTuChon, hoanTat: hoanTat)
                    return
                }
                hoanTat(.failure(NSError(
                    domain: "GeminiVision",
                    code: 422,
                    userInfo: [NSLocalizedDescriptionKey: "Gemini Flash không tìm thấy bảng số liệu phù hợp trong ảnh."]
                )))
                return
            }
            hoanTat(.success(ketQua))
        }.resume()
    }

    private func layJSONKetQua(tu data: Data) -> [String: Any]? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = root["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else { return nil }

        // Bỏ qua các part suy nghĩ nội bộ (thought == true) của dòng Gemini 2.5
        let nonThoughtParts = parts.filter { ($0["thought"] as? Bool) != true }
        let useParts = nonThoughtParts.isEmpty ? parts : nonThoughtParts

        let text = useParts.compactMap { $0["text"] as? String }
            .joined(separator: "\n")
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Nếu phản hồi là mảng JSON gốc [...] thì bọc vào ["danhSach": arr]
        if let dauVuong = text.firstIndex(of: "["),
           (text.firstIndex(of: "{") == nil || dauVuong < text.firstIndex(of: "{")!),
           let cuoiVuong = text.lastIndex(of: "]"), dauVuong <= cuoiVuong {
            let subArr = String(text[dauVuong...cuoiVuong])
            if let arrData = subArr.data(using: .utf8),
               let arrObj = try? JSONSerialization.jsonObject(with: arrData) as? [[String: Any]] {
                return ["danhSach": arrObj]
            }
        }

        if let dau = text.firstIndex(of: "{"), let cuoi = text.lastIndex(of: "}"), dau <= cuoi {
            let sub = String(text[dau...cuoi])
            if let subData = sub.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: subData) as? [String: Any] {
                return obj
            }
        }

        // Khôi phục JSON nếu chẳng may bị cắt ở cuối
        if let dau = text.firstIndex(of: "{") {
            let tuDau = String(text[dau...])
            if let daSua = suaJSONBiCat(tuDau),
               let suaData = daSua.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: suaData) as? [String: Any] {
                return obj
            }
        }
        return nil
    }

    private func suaJSONBiCat(_ raw: String) -> String? {
        guard let viTriCuoiHopLe = raw.range(of: "}", options: .backwards)?.upperBound else { return nil }
        var s = String(raw[..<viTriCuoiHopLe])
        var ngoacVuong = 0
        var ngoacNhon = 0
        var trongChuoi = false
        var escape = false
        for ch in s {
            if escape { escape = false; continue }
            if ch == "\\" { escape = true; continue }
            if ch == "\"" { trongChuoi.toggle(); continue }
            if !trongChuoi {
                if ch == "[" { ngoacVuong += 1 }
                else if ch == "]" { ngoacVuong = max(0, ngoacVuong - 1) }
                else if ch == "{" { ngoacNhon += 1 }
                else if ch == "}" { ngoacNhon = max(0, ngoacNhon - 1) }
            }
        }
        if ngoacVuong > 0 { s += String(repeating: "]", count: ngoacVuong) }
        if ngoacNhon > 0 { s += String(repeating: "}", count: ngoacNhon) }
        return s
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
        Bạn là hệ thống OCR chuyên dụng đọc bảng số liệu Điện Máy Xanh (ĐMX). Hãy đọc ảnh được gửi, bỏ qua hoàn toàn chữ chìm watermark nghiêng (ví dụ: "54453", "Dũng Nguyễn Thanh"), giữ nguyên dấu âm, số thập phân và phần trăm. Chế độ hiện tại: \(cheDo.tieuDe).
        Trả về ĐÚNG MỘT đối tượng JSON theo cấu trúc sau, không giải thích thêm:
        {"capNhatLuc":"","thongTinDonVi":"","doanhThu":{"doanhThuThuc":0,"targetThuc":0,"duKienThuc":0,"phanTramHTThuc":0,"doanhThuQuyDoi":0,"targetQuyDoi":0,"duKienQuyDoi":0,"phanTramHTQuyDoi":0},"nganhHang":[{"ten":"","loai":"DT hoặc SL","thucHien":0,"target":0,"phanTramHT":0,"duKien":0,"phanTramDuKien":0}],"nhanVien":[{"maNV":"","hoTen":"","soLuong":0,"doanhThuQD":0,"dtKhoanVay":0,"phanTramTiTrong":0}],"thiDuaNhanVien":[{"tenNganhHang":"","danhSach":[{"maNV":"","hoTen":"","thucHien":0,"target":0}]}]}

        Quy tắc bắt buộc khi đọc Bảng Thi Đua (mảng "nganhHang"):
        1. Hỗ trợ đầy đủ 3 định dạng ảnh Thi Đua Lũy kế (Bảng ngang, Bảng dọc, Lưới thẻ) và Bảng Realtime:
           - ĐỊNH DẠNG A — BẢNG NGANG LŨY KẾ (Dữ liệu theo Siêu thị · 39 chương trình xếp ngang):
             + Hai cột đầu bên trái là [ĐƠN VỊ | SỐ CT ĐẠT], tiếp theo là 39 cột chương trình ngang (nếu ảnh rộng được cắt thành 4 dải xếp dọc thì đọc lần lượt hết các cột từ dải trên xuống dải dưới, bỏ qua cột bị lặp ở mép nối).
             + Hàng tiêu đề trên của mỗi chương trình có dạng "<Tên môn> (DT)" hoặc "<Tên môn> (SL)" -> tách "DT"/"SL" vào "loai", tên môn vào "ten".
             + Hàng tiêu đề con bên dưới chia làm 2 cột: [THỰC HIỆN | TARGET]. Đọc con số ở dòng siêu thị (hoặc dòng TỔNG) đưa vào "thucHien" và "target", tính "phanTramHT" = (thucHien / target) * 100.
           - ĐỊNH DẠNG B — BẢNG DỌC LŨY KẾ (5 CỘT CÓ THANH TIẾN ĐỘ hoặc 6 CỘT):
             + Gồm [CHƯƠNG TRÌNH | THỰC HIỆN | TARGET | % DỰ KIẾN HOÀN THÀNH | HẠNG VÙNG].
             + Cột 1 (CHƯƠNG TRÌNH): Tách huy hiệu "DT"/"SL" vào "loai", tên môn sạch (bỏ dấu "+", ngôi sao ⭐) vào "ten".
             + Cột 2 (THỰC HIỆN): Đưa vào "thucHien".
             + Cột 3 (TARGET): Đưa vào "target" (lưu ý dấu phẩy hàng nghìn như 1,089.00 = 1089.00, 2,769.61 = 2769.61).
             + Cột 4 (% DỰ KIẾN HOÀN THÀNH): Con số % nhỏ nằm bên trái phía trên thanh tiến độ là "phanTramHT" (ví dụ 7.9%, 31.2%); con số % lớn in đậm màu đỏ/cam/xanh nằm bên phải thanh tiến độ là "phanTramDuKien" (ví dụ 22.6%, 88.7%, 300%).
             + Cột cuối (HẠNG VÙNG): Bỏ qua.
           - ĐỊNH DẠNG C — LƯỚI THẺ LŨY KẾ (Lưới 6 cột × 7 hàng = 39 thẻ hoặc Lưới 2 cột thẻ):
             + Đọc lần lượt tất cả 39 thẻ từ trái sang phải, từ trên xuống dưới.
             + Trong mỗi thẻ: góc trên trái là tên môn ("T11 - ..."), góc trên phải là huy hiệu "DT" hoặc "SL", con số % lớn ở giữa bên trái là "phanTramDuKien" (DỰ KIẾN HOÀN THÀNH), và 4 ô số ở nửa dưới thẻ gồm: "THỰC HIỆN" -> "thucHien", "TARGET" -> "target", "% HT THÁNG" -> "phanTramHT", "DT DỰ KIẾN" / "SL DỰ KIẾN" -> "duKien".
           - ĐỊNH DẠNG D — BẢNG THI ĐUA THEO NGÀY / REALTIME (5 CỘT): [CHƯƠNG TRÌNH | THỰC HIỆN | TARGET NGÀY | % HT NGÀY | HẠNG VÙNG] -> đọc chính xác cột THỰC HIỆN vào "thucHien", TARGET NGÀY vào "target", con số phần trăm bên phải thanh tiến độ ở cột % HT NGÀY vào "phanTramHT", đặt "phanTramDuKien": 0 và "duKien": 0. ĐẶC BIỆT CHÚ Ý GIỮ NGUYÊN DẤU ÂM (-) của các số âm ở cả cột THỰC HIỆN và % HT NGÀY (ví dụ: thucHien: -0.94, target: 5.93, phanTramHT: -15.8).
        2. Đọc ĐẦY ĐỦ TẤT CẢ các dòng môn thi đua từ trên xuống dưới, kể cả các dòng có số âm (như -0.94, -15.8%), các dòng tên dài xuống 2-3 hàng chữ như "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBANK EVO" (loai: "SL") hoặc "Trả chậm FECREDIT, SAMSUNG F+, SHINHAN, MCREDIT" và kể cả dòng có Thực hiện = 0, Target = 0. Không đưa nhãn DT, SL, CE, ICT, DV hay dấu + vào trong "ten".
        3. Với bảng doanh thu nhân viên 5 cột (NHÂN VIÊN / NGÀNH HÀNG BI | SỐ LƯỢNG | DOANH THU QĐ | DT QĐ KHOẢN VAY | % TỈ TRỌNG), trích đúng "maNV" (bỏ tiền tố id:) và "hoTen" vào mảng "nhanVien".
        4. Với bảng Thi đua Nhân viên (mảng "thiDuaNhanVien"), hỗ trợ cả 2 mẫu:
           - MẪU 1 — MA TRẬN THEO NHÂN VIÊN ("Ma trận theo Nhân viên · 13 chương trình"):
             + Hỗ trợ 2 kiểu bố cục ma trận:
               * KIỂU DỌC (mới): Cột đầu tiên là "NHÂN VIÊN" (dạng "<maNV> - <hoTen>"), hàng đầu tiên là "TỔNG", các cột tiếp theo là từng chương trình thi đua. Mỗi ô chỉ có 1 con số thực hiện (nếu là "—", "-", hoặc 0 thì đặt "thucHien": 0), không có cột target riêng (đặt "target": 0). Với mỗi cột chương trình, tạo 1 phần tử trong "thiDuaNhanVien" với "tenNganhHang", "thucHienNganhGoiY" (lấy từ hàng TỔNG), "targetNganhGoiY": 0, và "danhSach" gồm các nhân viên kèm "maNV", "hoTen", "thucHien", "target": 0, "laPhanTram": false.
               * KIỂU NGANG (cũ): Các hàng là danh sách chương trình thi đua, các cột là từng nhân viên với 2 cột con [THỰC HIỆN | TARGET].
           - MẪU 2 — BẢNG MỞ RỘNG 1 MÔN THI ĐUA (có các dòng nhân viên kèm "id: <mã NV>" ở cột 1 và cột 2 hiển thị % đóng góp): chỉ trích các hàng có cả tên nhân viên và id vào mảng "thiDuaNhanVien", đặt "laPhanTram": true, "thucHien" là con số phần trăm, kèm "thucHienNganhGoiY" và "targetNganhGoiY".
        5. Nếu ảnh là PHIẾU SỨC KHỎE & THI ĐUA CÁ NHÂN NHÂN VIÊN 27 ĐIỂM (có tên nhân viên, mã NV 6 số, khối DOANH THU 6 mục, khối NĂNG SUẤT 3 mục, khối THI ĐUA gồm lưới thẻ % các môn): hãy trả thêm trường "sucKhoeNhanVien": [{"maNV":"293044","hoTen":"Võ Ngọc Vĩ","doanhThuQD":97.1,"tbDoanhThuQD":228.7,"phanTramTarget":46,"tbPhanTramTarget":108,"mucTieuTargetQD":703.7,"soLuotBill":33,"tbSoLuotBill":35,"phanTramQuyDoi":64,"tbPhanTramQuyDoi":43,"phanTramTraCham":45,"tbPhanTramTraCham":53,"phanTramBanKem":100,"tbPhanTramBanKem":61,"diemThuongERP":1254937,"tbDiemThuongERP":1496937,"diemThuongGioCong":17317,"tbDiemThuongGioCong":20855,"dtqdGioCong":1.34,"tbDtqdGioCong":3.20,"thiDua":[{"ten":"Phụ kiện công nghệ","phanTram":107}]}] (các môn nằm ở phần "Chưa có số liệu" đặt phanTram: 0).
        """
    }

    private func chuyenChuoiThanhSo(_ s: String) -> Double? {
        var chuoi = s
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "﹣", with: "-")
            .replacingOccurrences(of: "－", with: "-")
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
        return Double(chuoi)
    }

    private func so(_ obj: [String: Any], _ key: String) -> Double {
        if let n = obj[key] as? NSNumber { return n.doubleValue }
        if let s = obj[key] as? String {
            return chuyenChuoiThanhSo(s) ?? 0
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
                let tenSach = KhoDuLieu.chuanHoaTenMonThiDuaChuan(tenTho, tienToThangMacDinh: "T11")
                guard !tenSach.isEmpty else { return nil }
                let loaiStr = ((item["loai"] as? String) ?? "DT").uppercased()
                let laTheTinDung = (tenSach == "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBANK EVO")
                let loai: LoaiChiTieuThiDua = (loaiStr.contains("SL") || laTheTinDung) ? .soLuong : .doanhThu
                var th = so(item, "thucHien")
                let tg = so(item, "target")
                var ht = so(item, "phanTramHT")
                if ht < -0.05 && th > 0 {
                    th = -abs(th)
                } else if th < -0.0001 && ht > 0 {
                    ht = -abs(ht)
                }
                if abs(ht) <= 0.0001 && tg > 0 && abs(th) > 0.0001 {
                    ht = ((th / tg) * 1000.0).rounded() / 10.0
                }
                let db = so(item, "phanTramDuKien")
                var dk = so(item, "duKien")

                let phanTramDuBaoGoc: Double?
                let duKienGoc: Double?
                if cheDo == .realtime || abs(db) <= 0.0001 {
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
        if json["nhanVien"] is [[String: Any]] {
            let dsDT = locDoanhThuNhanVienTuJSON(json)
            if !dsDT.isEmpty {
                kq.doanhThuNhanVien = dsDT
                kq.soAnhDoanhThuNV = 1
            }
        }
        if let arr = json["thiDuaNhanVien"] as? [[String: Any]] {
            kq.thiDuaNhanVien = arr.compactMap { khoi in
                let nganh = KhoDuLieu.chuanHoaTenMonThiDuaChuan((khoi["tenNganhHang"] as? String) ?? "", tienToThangMacDinh: "T11")
                let thucHienGoiY = so(khoi, "thucHienNganhGoiY")
                let targetGoiY = so(khoi, "targetNganhGoiY")
                let dsQuanLy = KhoDuLieu.dungChung.layCaiDatAnToan().danhSachNhanVien
                let ds = (khoi["danhSach"] as? [[String: Any]] ?? []).compactMap { nv -> DongThiDuaNhanVienQuet? in
                    let maTho = (nv["maNV"] as? String) ?? ""
                    let tenTho = ((nv["hoTen"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    let nvKhop = KhoDuLieu.khopNhanVienQuetVoiQuanLy(maQuet: maTho, tenQuet: tenTho, dsQuanLy: dsQuanLy)
                    let ma = nvKhop?.maNV ?? KhoDuLieu.chuanHoaMaNV(maTho)
                    let ten = nvKhop?.hoTen ?? tenTho
                    guard !ma.isEmpty || !ten.isEmpty else { return nil }
                    let laPT = (nv["laPhanTram"] as? Bool) ?? ((nv["thucHien"] as? String)?.contains("%") ?? false)
                    var thVal = so(nv, "thucHien")
                    var tgVal = so(nv, "target")
                    if let sTh = nv["thucHien"] as? String, sTh.contains("/") {
                        let parts = sTh.components(separatedBy: "/")
                        if let v1 = chuyenChuoiThanhSo(parts[0]) { thVal = v1 }
                        if tgVal <= 0, parts.count > 1, let v2 = chuyenChuoiThanhSo(parts[1]) { tgVal = v2 }
                    }
                    return DongThiDuaNhanVienQuet(
                        maNV: ma,
                        hoTen: ten,
                        thucHien: thVal,
                        target: tgVal,
                        laPhanTram: laPT
                    )
                }
                return ds.isEmpty ? nil : KetQuaThiDuaNhanVienKhoi(tenNganhHang: nganh, danhSach: ds, thucHienNganhGoiY: thucHienGoiY, targetNganhGoiY: targetGoiY)
            }
            kq.thiDuaNhanVien = gopVaLamSachKhoiThiDuaNhanVien(kq.thiDuaNhanVien)
            kq.soAnhThiDuaNV = kq.thiDuaNhanVien.count
        }
        if let arrSK = json["sucKhoeNhanVien"] as? [[String: Any]] {
            let dsQuanLy = KhoDuLieu.dungChung.layCaiDatAnToan().danhSachNhanVien
            for item in arrSK {
                let maTho = (item["maNV"] as? String) ?? ""
                let tenTho = (item["hoTen"] as? String) ?? ""
                let nvKhop = KhoDuLieu.khopNhanVienQuetVoiQuanLy(maQuet: maTho, tenQuet: tenTho, dsQuanLy: dsQuanLy)
                let ma = nvKhop?.maNV ?? KhoDuLieu.chuanHoaMaNV(maTho)
                let ten = nvKhop?.hoTen ?? (tenTho.isEmpty ? "NV \(ma)" : tenTho)
                guard !ma.isEmpty else { continue }

                var sk = DuLieuSucKhoeBoSungNV()
                let dtQD = so(item, "doanhThuQD")
                let tbDTQD = so(item, "tbDoanhThuQD")
                let ptTG = so(item, "phanTramTarget")
                let tbTG = so(item, "tbPhanTramTarget")
                let mtQD = so(item, "mucTieuTargetQD")
                let bill = so(item, "soLuotBill")
                let tbBill = so(item, "tbSoLuotBill")
                let ptQD = so(item, "phanTramQuyDoi")
                let tbQD = so(item, "tbPhanTramQuyDoi")
                let ptTC = so(item, "phanTramTraCham")
                let tbTC = so(item, "tbPhanTramTraCham")
                let ptBK = so(item, "phanTramBanKem")
                let tbBK = so(item, "tbPhanTramBanKem")
                let erp = so(item, "diemThuongERP")
                let tbErp = so(item, "tbDiemThuongERP")
                let erpGC = so(item, "diemThuongGioCong")
                let tbErpGC = so(item, "tbDiemThuongGioCong")
                let dtGC = so(item, "dtqdGioCong")
                let tbDtGC = so(item, "tbDtqdGioCong")

                if dtQD > 0 { sk.doanhThuQDSucKhoe = dtQD }
                if tbDTQD > 0 { sk.tbDoanhThuQDSieuThi = tbDTQD }
                if ptTG > 0 { sk.phanTramTarget = ptTG }
                if tbTG > 0 { sk.tbPhanTramTarget = tbTG }
                if mtQD > 0 { sk.mucTieuTargetQD = mtQD }
                if bill > 0 { sk.soLuotBillBanHang = bill }
                if tbBill > 0 { sk.tbSoLuotBillBanHang = tbBill }
                if ptQD > 0 { sk.phanTramQuyDoi = ptQD }
                if tbQD > 0 { sk.tbPhanTramQuyDoi = tbQD }
                if ptTC > 0 { sk.phanTramTraCham = ptTC }
                if tbTC > 0 { sk.tbPhanTramTraCham = tbTC }
                if ptBK > 0 { sk.phanTramBanKem = ptBK }
                if tbBK > 0 { sk.tbPhanTramBanKem = tbBK }
                if erp > 0 { sk.diemThuongERP = erp }
                if tbErp > 0 { sk.tbDiemThuongERP = tbErp }
                if erpGC > 0 { sk.diemThuongTrenGioCong = erpGC }
                if tbErpGC > 0 { sk.tbDiemThuongTrenGioCong = tbErpGC }
                if dtGC > 0 { sk.dtqdTrenGioCong = dtGC }
                if tbDtGC > 0 { sk.tbDtqdTrenGioCong = tbDtGC }

                var bangPT: [String: Double] = [:]
                for tenChuan in KhoDuLieu.danhSachTenMonThiDuaChuanDMX {
                    let kLM = KhoDuLieu.chuanHoaKhoaLienMachThiDua(tenChuan)
                    let kSS = KhoDuLieu.chuanHoaKhoaSoSanh(tenChuan)
                    if !kLM.isEmpty { bangPT[kLM] = 0 }
                    if !kSS.isEmpty { bangPT[kSS] = 0 }
                }
                if let dsTD = item["thiDua"] as? [[String: Any]] {
                    for td in dsTD {
                        let tenMon = KhoDuLieu.chuanHoaTenMonThiDuaChuan((td["ten"] as? String) ?? "")
                        guard !tenMon.isEmpty else { continue }
                        let ptVal = so(td, "phanTram")
                        let kLM = KhoDuLieu.chuanHoaKhoaLienMachThiDua(tenMon)
                        let kSS = KhoDuLieu.chuanHoaKhoaSoSanh(tenMon)
                        if !kLM.isEmpty { bangPT[kLM] = max(0, ptVal) }
                        if !kSS.isEmpty { bangPT[kSS] = max(0, ptVal) }
                    }
                }
                sk.phanTramThiDuaCaNhan = bangPT
                kq.sucKhoeNhanVien[ma] = sk
                kq.soAnhSucKhoeNV += 1

                kq.doanhThuNhanVien.append(DoanhThuNhanVienItem(
                    maNV: ma,
                    hoTen: ten,
                    soLuong: bill,
                    doanhThuThuc: 0,
                    doanhThuQD: dtQD,
                    target: mtQD,
                    dtQDKhoanVay: 0,
                    dtTraThangQD: ptQD,
                    phanTramHT: ptTG,
                    phanTramQuyDoi: ptQD,
                    phanTramTraGop: ptTC
                ))
                kq.soAnhDoanhThuNV += 1

                for tenChuan in KhoDuLieu.danhSachTenMonThiDuaChuanDMX {
                    let kLM = KhoDuLieu.chuanHoaKhoaLienMachThiDua(tenChuan)
                    let ptMon = bangPT[kLM] ?? 0
                    kq.thiDuaNhanVien.append(KetQuaThiDuaNhanVienKhoi(
                        tenNganhHang: tenChuan,
                        danhSach: [
                            DongThiDuaNhanVienQuet(
                                maNV: ma,
                                hoTen: ten,
                                thucHien: ptMon,
                                target: 0,
                                laPhanTram: true,
                                laPhanTramTargetCaNhan: true
                            )
                        ]
                    ))
                }
                kq.soAnhThiDuaNV += 1
            }
        }
        // Nếu JSON được tạo từ câu lệnh lọc bảng nhân viên × ngành hàng (chưa vào kq.thiDuaNhanVien)
        if kq.thiDuaNhanVien.isEmpty {
            let khoiTuBang = locThiDuaNhanVienTuJSON(json)
            if !khoiTuBang.isEmpty {
                kq.thiDuaNhanVien = khoiTuBang
                kq.soAnhThiDuaNV = khoiTuBang.count
            }
        }
        if kq.thiDuaNhanVien.isEmpty && kq.doanhThuNhanVien.isEmpty {
            let dsDTTuBang = locDoanhThuNhanVienTuJSON(json)
            if !dsDTTuBang.isEmpty {
                kq.doanhThuNhanVien = dsDTTuBang
                kq.soAnhDoanhThuNV = 1
            }
        }
        // Nếu là ảnh Ma trận Thi đua Nhân viên (không phải phiếu sức khỏe 27 điểm) thì tuyệt đối không sinh doanhThuNhanVien giả
        if !kq.thiDuaNhanVien.isEmpty && kq.sucKhoeNhanVien.isEmpty {
            kq.doanhThuNhanVien = []
            kq.soAnhDoanhThuNV = 0
        }
        return kq
    }

    /// Câu lệnh chuyên biệt đã tối ưu cho Gemini Flash để quét ảnh Ma trận Thi đua Nhân viên:
    /// Đọc theo đúng thứ tự cột thực tế trên ảnh (không ép cứng thứ tự cột), giữ đúng vị trí mọi ô "—" = 0 để không bao giờ nhảy số sang cột kế bên, và đối chiếu tổng từng cột với dòng "TỔNG".
    private var promptThiDuaNhanVien: String {
        """
        Đây là ảnh bảng thực hiện thi đua (gồm cả ngành hàng tính theo Doanh thu DT và ngành hàng tính theo Số lượng SL) của nhân viên ứng với từng ngành hàng:
        - Cột đầu tiên bên trái ("NHÂN VIÊN"): hàng đầu tiên là "TỔNG", các hàng tiếp theo là từng nhân viên theo dạng "<Mã NV> - <Họ tên>" (nếu tên nhân viên xuống 2 dòng như "201962 - Nguyễn Thị Kim\nLoan" thì ghép lại thành 1 dòng).
        - Các cột tiếp theo từ trái sang phải (thường là 13 cột: Cột 1 đến Cột 13) là các ngành hàng thi đua.
        Hãy lọc chính xác toàn bộ bảng thành một đoạn JSON.

        QUY TẮC BẮT BUỘC ĐỂ KHÔNG BỊ TRÙNG NGÀNH HÀNG VÀ KHÔNG BAO GIỜ NHẢY SỐ / LẤY NHẦM KẾT QUẢ GIỮA CÁC CỘT KẾ NHAU:
        1. Bỏ qua hoàn toàn chữ chìm watermark nghiêng màu xám ("54453", "Dũng Nguyễn Thanh").
        2. ĐỌC ĐÚNG THỨ TỰ CỘT THỰC TẾ TRÊN ẢNH TỪ TRÁI SANG PHẢI:
           - Thứ tự các cột trên ảnh thay đổi theo từng ngày/siêu thị, vì vậy PHẢI đọc tiêu đề của từng cột trực tiếp trên ảnh từ trái sang phải (Cột 1 -> Cột 13), tuyệt đối không tự ý đảo thứ tự cột.
           - Chuẩn hóa tên mỗi cột (bỏ tiền tố "T11 -", bỏ ký hiệu "(DT)", "(SL)") về đúng tên chuẩn trong 39 ngành hàng ĐMX thuộc 3 nhóm sau:
             + Nhóm Dịch Vụ (13 ngành): "Vay tiền mặt", "Trả Chậm Điện máy & Gia dụng", "Ví trả sau", "Bảo hiểm Thọ ICT", "Bảo hiểm Thọ ĐMX", "Sim ĐMX", "Nạp rút", "Bảo hiểm Tổng", "Sim", "Trả chậm Homecredit", "Trả chậm FECREDIT, SAMSUNG F+, SHINHAN, MCREDIT", "VAS", "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBANK EVO".
             + Nhóm Điện Tử / Điện Lạnh / Gia Dụng (13 ngành): "Tivi TCL", "CE LG", "Điện tử Samsung", "Máy Lạnh", "Máy sấy / Máy rửa chén", "Máy lọc KK - Hút bụi - Hút ẩm", "Máy nước nóng", "Điện tử", "Máy lọc nước", "Máy giặt", "Nồi cơm & Nồi chiên", "Quạt gió", "Tủ Lạnh / Đông / Mát".
             + Nhóm ICT / Phụ Kiện (13 ngành): "Điện thoại Vivo", "Phụ kiện công nghệ", "ĐIỆN THOẠI & TABLET ANDROID", "Điện thoại Realme", "Camera", "Sạc dự phòng", "Đồng hồ & Smartwatch", "Phụ kiện khác IT & Nhóm khác", "Laptop", "Cáp sạc", "Tai nghe", "Đèn năng lượng mặt trời", "Loa Phụ Kiện".
           - Mỗi cột trên ảnh là 1 ngành hàng riêng biệt, không được đặt trùng tên 2 cột giống nhau.
        3. GIỮ ĐÚNG CỘT DỌC & KHÔNG LẤY NHẦM SỐ CỦA CỘT BÊN CẠNH:
           - Bám sát đường kẻ dọc của từng cột từ trên xuống dưới.
           - Ô nào có dấu gạch ngang "—", "-" hoặc trống thì BẮT BUỘC ghi đúng số 0 tại vị trí cột đó.
           - TUYỆT ĐỐI KHÔNG lấy số của cột bên trái hoặc bên phải đắp vào ô có dấu "—" (ví dụ: không được lấy số của cột kế bên có nhiều số liệu chép sang cột ít số liệu nằm cạnh nó).
           - TUYỆT ĐỐI KHÔNG bỏ qua ô "—" làm dồn dịch vị trí các cột phía sau.
           - Phải đọc đầy đủ cả các cột đơn vị (DT) lẫn các cột đơn vị (SL) như: "Máy Lạnh", "Máy nước nóng", "Sim ĐMX", "Nạp rút", "Sim", "VAS", "Đèn năng lượng mặt trời", "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBANK EVO".
           - Ô nào có số âm (ví dụ -1.25) thì giữ nguyên dấu âm (-1.25).
        4. KIỂM TRA CHÉO VỚI HÀNG "TỔNG":
           - Tại mỗi cột thứ k (từ 1 đến 13), tổng các số của nhân viên trong cột k phải xấp xỉ bằng giá trị ở hàng "TỔNG" (`hangTong[k-1]`) của chính cột k đó. Nếu một cột có `hangTong` nhỏ (hoặc bằng 0) thì chỉ đúng những nhân viên thực sự có số trong cột đó mới khác 0.
        5. Trả về DUY NHẤT 1 đối tượng JSON theo đúng cấu trúc:
        {"cotNganhHang":["Tên cột 1","Tên cột 2","...","Tên cột 13"],"hangTong":[0,0,0,0,0,0,0,0,0,0,0,0,0],"nhanVien":[{"maNV":"285688","hoTen":"Lê Tuấn","soLieu":[0,0,0,0,0,0,0,0,0,0,0,0,0]}]}
        """
    }

    /// Quét danh sách ảnh Thi đua Nhân viên bằng Gemini Flash (1 key chạy 1 key, 2 key chạy 2 key, 3 key chạy 3 key song song)
    func quetThiDuaNhanVien(
        danhSachAnh: [UIImage],
        cheDo: LoaiCheDoDoanhThu = .luyKe,
        tienTrinh: ((String) -> Void)? = nil,
        hoanTat: @escaping (Result<[KetQuaThiDuaNhanVienKhoi], Error>) -> Void
    ) {
        let cd = KhoDuLieu.dungChung.layCaiDatAnToan()
        let danhSachKey = cd.danhSachGeminiApiKeyHieuLuc

        guard !danhSachKey.isEmpty, !danhSachAnh.isEmpty else {
            hoanTat(.failure(NSError(domain: "GeminiVision", code: 400, userInfo: [NSLocalizedDescriptionKey: "Chưa có ảnh hoặc API Key."])))
            return
        }

        var cacDuLieuAnh: [Data] = []
        for anh in danhSachAnh {
            if let d = duLieuAnhGon(anh) {
                cacDuLieuAnh.append(d)
            }
        }
        guard !cacDuLieuAnh.isEmpty else {
            hoanTat(.failure(NSError(domain: "GeminiVision", code: 400, userInfo: [NSLocalizedDescriptionKey: "Không đọc được dữ liệu ảnh."])))
            return
        }

        let cacModel = danhSachModelHopLe(modelUuTien: "gemini-3.1-flash")
        let tongAnh = cacDuLieuAnh.count
        let soLuongKey = max(1, min(3, danhSachKey.count))
        let khoa = NSLock()
        var ketQuaTungAnh = Array<[KetQuaThiDuaNhanVienKhoi]>(repeating: [], count: tongAnh)
        var loiCuoi: Error?
        let nhom = DispatchGroup()
        // Nhập 1 key dùng 1 luồng, 2 key dùng 2 luồng, 3 key dùng 3 luồng song song
        let semaphore = DispatchSemaphore(value: soLuongKey)

        DispatchQueue.global(qos: .userInitiated).async {
            for (idx, imgData) in cacDuLieuAnh.enumerated() {
                semaphore.wait()
                nhom.enter()
                let cacCapAnh = self.taoDanhSachCapThu(chiSoAnh: idx, danhSachKey: danhSachKey, cacModel: cacModel)
                let chiSoKeyHienThi = (idx % soLuongKey) + 1
                DispatchQueue.main.async {
                    tienTrinh?("Gemini Flash (Key \(chiSoKeyHienThi)/\(soLuongKey)) đang quét ảnh Thi đua NV \(idx + 1)/\(tongAnh)...")
                }
                self.goiGeminiChoMotAnh(
                    cacCap: cacCapAnh,
                    chiSo: 0,
                    cheDo: cheDo,
                    imageData: imgData,
                    promptTuChon: self.promptThiDuaNhanVien
                ) { kqAnh in
                    khoa.lock()
                    switch kqAnh {
                    case .success(let kq):
                        ketQuaTungAnh[idx] = kq.thiDuaNhanVien
                    case .failure(let err):
                        loiCuoi = err
                    }
                    khoa.unlock()
                    semaphore.signal()
                    nhom.leave()
                }
            }
            nhom.wait()

            let tatCaKhoi = self.gopVaLamSachKhoiThiDuaNhanVien(ketQuaTungAnh.flatMap { $0 })
            DispatchQueue.main.async {
                if !tatCaKhoi.isEmpty {
                    hoanTat(.success(tatCaKhoi))
                } else {
                    hoanTat(.failure(loiCuoi ?? NSError(domain: "GeminiVision", code: 422, userInfo: [NSLocalizedDescriptionKey: "Chưa lọc được bảng thi đua nhân viên từ JSON."])))
                }
            }
        }
    }

    /// Bộ lọc đa năng chuyển đổi kết quả JSON từ Gemini sang danh sách KetQuaThiDuaNhanVienKhoi của ứng dụng
    func locThiDuaNhanVienTuJSON(_ json: [String: Any]) -> [KetQuaThiDuaNhanVienKhoi] {
        let dsQuanLy = KhoDuLieu.dungChung.layCaiDatAnToan().danhSachNhanVien

        func docGiaTriSo(_ anyVal: Any?) -> Double {
            guard let anyVal else { return 0 }
            if let n = anyVal as? NSNumber { return n.doubleValue }
            if let s = anyVal as? String {
                let trim = s.trimmingCharacters(in: .whitespacesAndNewlines)
                let khongGach = trim.replacingOccurrences(of: "^[\\-–—_\\s]+$", with: "", options: .regularExpression)
                if khongGach.isEmpty { return 0 }
                return chuyenChuoiThanhSo(trim) ?? 0
            }
            if let dict = anyVal as? [String: Any] {
                for k in ["thucHien", "thuc_hien", "doanhThu", "doanh_thu", "soLuong", "so_luong", "giaTri", "gia_tri", "value", "so_lieu", "soLieu"] {
                    if let v = dict[k] {
                        return docGiaTriSo(v)
                    }
                }
            }
            return 0
        }

        func chuanHoaKhoaJSON(_ k: String) -> String {
            k.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
                .replacingOccurrences(of: "đ", with: "d")
                .lowercased()
                .replacingOccurrences(of: "[^a-z0-9]+", with: "_", options: .regularExpression)
                .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        }

        func tachMaVaTenNV(_ chuoi: String, maPhu: String = "") -> (maNV: String, hoTen: String)? {
            let clean = chuoi
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let u = clean.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN")).uppercased()
            if u == "TONG" || u == "TONG CONG" || u == "NHAN VIEN" || u == "TOTAL" {
                return nil
            }
            var ma = maPhu.trimmingCharacters(in: .whitespacesAndNewlines)
            if ma.isEmpty, let r = clean.range(of: "\\b\\d{4,7}\\b", options: .regularExpression) {
                ma = String(clean[r])
            }
            let ten = clean
                .replacingOccurrences(of: ma, with: "")
                .replacingOccurrences(of: "^[\\s\\-–—:|_]+|[\\s\\-–—:|_]+$", with: "", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !dsQuanLy.isEmpty,
               let nvKhop = KhoDuLieu.khopNhanVienQuetVoiQuanLy(maQuet: ma, tenQuet: ten.isEmpty ? clean : ten, dsQuanLy: dsQuanLy) {
                return (nvKhop.maNV, nvKhop.hoTen)
            }
            let maChuan = KhoDuLieu.chuanHoaMaNV(ma)
            guard !maChuan.isEmpty || !ten.isEmpty else { return nil }
            return (maChuan, ten.isEmpty ? clean : ten)
        }

        var bangMon: [String: (tenChuan: String, tong: Double, dsNV: [String: (hoTen: String, thucHien: Double)])] = [:]
        var thuTuMon: [String] = []

        func ghiNhanSoLieu(tenNganhTho: String, maNV: String, hoTen: String, giaTri: Double, laHangTong: Bool = false) {
            let tenSach = tenNganhTho.replacingOccurrences(of: "_", with: " ")
            let tenChuan = KhoDuLieu.chuanHoaTenMonThiDuaChuan(tenSach, tienToThangMacDinh: "T11")
            guard !tenChuan.isEmpty,
                  tenChuan != "Ngành hàng",
                  KhoDuLieu.laTenMonThiDuaChuanDMX(tenChuan),
                  !KhoDuLieu.laTenDongNhanVienBiQuetNham(tenChuan) else { return }
            let kLM = KhoDuLieu.chuanHoaKhoaLienMachThiDua(tenChuan)
            guard !kLM.isEmpty else { return }

            if bangMon[kLM] == nil {
                bangMon[kLM] = (tenChuan: tenChuan, tong: 0, dsNV: [:])
                thuTuMon.append(kLM)
            }
            if laHangTong {
                if abs(giaTri) > 0.0001 {
                    bangMon[kLM]?.tong = giaTri
                }
            } else if !maNV.isEmpty {
                bangMon[kLM]?.dsNV[maNV] = (hoTen: hoTen, thucHien: giaTri)
            }
        }

        // TRƯỜNG HỢP 0 (Chuẩn tối ưu): {"cotNganhHang": [...], "hangTong": [...], "nhanVien": [{"maNV": "...", "hoTen": "...", "soLieu": [...]}]}
        if let dsCot = (json["cotNganhHang"] as? [String]) ?? (json["cot_nganh_hang"] as? [String]) ?? (json["nganhHang"] as? [String]) ?? (json["columns"] as? [String]),
           !dsCot.isEmpty {
            let cotNganh = dsCot.filter {
                let u = chuanHoaKhoaJSON($0)
                return u != "nhan_vien" && u != "ho_ten" && u != "ma_nv"
            }
            if let arrTong = (json["hangTong"] as? [Any]) ?? (json["hang_tong"] as? [Any]) ?? (json["tong"] as? [Any]) {
                for (i, tenCot) in cotNganh.enumerated() where i < arrTong.count {
                    ghiNhanSoLieu(tenNganhTho: tenCot, maNV: "", hoTen: "", giaTri: docGiaTriSo(arrTong[i]), laHangTong: true)
                }
            } else if let dictTong = (json["hangTong"] as? [String: Any]) ?? (json["hang_tong"] as? [String: Any]) {
                for (i, tenCot) in cotNganh.enumerated() {
                    let v = dictTong["C\(i + 1)"] ?? dictTong["c\(i + 1)"] ?? dictTong[tenCot]
                    ghiNhanSoLieu(tenNganhTho: tenCot, maNV: "", hoTen: "", giaTri: docGiaTriSo(v), laHangTong: true)
                }
            }

            if let dsNV = (json["nhanVien"] as? [[String: Any]]) ?? (json["nhan_vien"] as? [[String: Any]]) ?? (json["danhSach"] as? [[String: Any]]) ?? (json["data"] as? [[String: Any]]) {
                for item in dsNV {
                    let maTho = (item["maNV"] as? String) ?? (item["ma_nv"] as? String) ?? ((item["maNV"] as? NSNumber)?.stringValue) ?? ""
                    let tenTho = (item["hoTen"] as? String) ?? (item["ho_ten"] as? String) ?? (item["ten"] as? String) ?? (item["nhanVien"] as? String) ?? ""
                    let uCheck = (maTho + " " + tenTho).folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN")).uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    let laTong = (uCheck == "TONG" || uCheck == "TONG CONG")
                    let nvInfo = laTong ? nil : tachMaVaTenNV(tenTho, maPhu: maTho)
                    if !laTong && nvInfo == nil { continue }

                    if let mangSo = (item["soLieu"] as? [Any]) ?? (item["so_lieu"] as? [Any]) ?? (item["giaTri"] as? [Any]) ?? (item["values"] as? [Any]) {
                        for (i, tenCot) in cotNganh.enumerated() where i < mangSo.count {
                            ghiNhanSoLieu(
                                tenNganhTho: tenCot,
                                maNV: nvInfo?.maNV ?? "",
                                hoTen: nvInfo?.hoTen ?? "",
                                giaTri: docGiaTriSo(mangSo[i]),
                                laHangTong: laTong
                            )
                        }
                    } else if let dictSo = (item["soLieu"] as? [String: Any]) ?? (item["so_lieu"] as? [String: Any]) ?? (item["nganhHang"] as? [String: Any]) ?? (item["nganh_hang"] as? [String: Any]) {
                        for (i, tenCot) in cotNganh.enumerated() {
                            if let v = dictSo["C\(i + 1)"] ?? dictSo["c\(i + 1)"] ?? dictSo[tenCot] {
                                ghiNhanSoLieu(
                                    tenNganhTho: tenCot,
                                    maNV: nvInfo?.maNV ?? "",
                                    hoTen: nvInfo?.hoTen ?? "",
                                    giaTri: docGiaTriSo(v),
                                    laHangTong: laTong
                                )
                            } else {
                                ghiNhanSoLieu(
                                    tenNganhTho: tenCot,
                                    maNV: nvInfo?.maNV ?? "",
                                    hoTen: nvInfo?.hoTen ?? "",
                                    giaTri: 0,
                                    laHangTong: laTong
                                )
                            }
                        }
                    }
                }
            }
        }

        let cacKhoaNhanVien: Set<String> = [
            "nhan_vien", "nhanvien", "ten_nhan_vien", "tennhanvien", "ho_ten", "hoten",
            "employee", "name", "ten", "ma_va_ten", "nhan_su", "staff", "ho_va_ten"
        ]
        let cacKhoaMaNV: Set<String> = [
            "ma_nv", "manv", "ma_nhan_vien", "manhanvien", "id", "ma", "employee_id"
        ]
        let cacKhoaNganhLong: Set<String> = [
            "nganh_hang", "nganhhang", "doanh_thu", "doanhthu", "du_lieu", "dulieu",
            "chi_tiet", "chitiet", "cac_nganh_hang", "categories", "data", "mon_thi_dua", "values", "scores", "so_lieu", "solieu"
        ]

        // TRƯỜNG HỢP 1: Mảng các dòng nhân viên (từ json["danhSach"], json["nhan_vien"], json["data"], json["rows"], ...)
        if bangMon.isEmpty {
            var mangDong: [[String: Any]] = []
            for (_, val) in json {
                if let arr = val as? [[String: Any]], !arr.isEmpty {
                    if arr.first?["danhSach"] != nil { continue }
                    mangDong = arr
                    break
                }
            }

            if !mangDong.isEmpty {
                for dong in mangDong {
                    var chuoiTenNV = ""
                    var chuoiMaNV = ""
                    for (k, v) in dong {
                        let kNorm = chuanHoaKhoaJSON(k)
                        if cacKhoaNhanVien.contains(kNorm) || kNorm.contains("nhan_vien") || kNorm.contains("nhanvien") {
                            if let s = v as? String { chuoiTenNV = s }
                        } else if cacKhoaMaNV.contains(kNorm) {
                            if let s = v as? String { chuoiMaNV = s }
                            else if let n = v as? NSNumber { chuoiMaNV = n.stringValue }
                        }
                    }

                    let uTen = chuoiTenNV.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN")).uppercased()
                    let laTong = (uTen == "TONG" || uTen == "TONG CONG" || uTen == "TOTAL")
                    let nvInfo = laTong ? nil : tachMaVaTenNV(chuoiTenNV, maPhu: chuoiMaNV)
                    if !laTong && nvInfo == nil { continue }

                    var daTimThayDictCon = false
                    for (k, v) in dong {
                        let kNorm = chuanHoaKhoaJSON(k)
                        if cacKhoaNganhLong.contains(kNorm), let subDict = v as? [String: Any] {
                            daTimThayDictCon = true
                            for (tenMonKey, valMon) in subDict {
                                let gt = docGiaTriSo(valMon)
                                ghiNhanSoLieu(
                                    tenNganhTho: tenMonKey,
                                    maNV: nvInfo?.maNV ?? "",
                                    hoTen: nvInfo?.hoTen ?? "",
                                    giaTri: gt,
                                    laHangTong: laTong
                                )
                            }
                        } else if cacKhoaNganhLong.contains(kNorm), let subArr = v as? [[String: Any]] {
                            daTimThayDictCon = true
                            for itemMon in subArr {
                                let tenMonKey = (itemMon["ten"] as? String)
                                    ?? (itemMon["nganh_hang"] as? String)
                                    ?? (itemMon["nganhHang"] as? String)
                                    ?? (itemMon["mon"] as? String)
                                    ?? ""
                                let gt = docGiaTriSo(itemMon)
                                ghiNhanSoLieu(
                                    tenNganhTho: tenMonKey,
                                    maNV: nvInfo?.maNV ?? "",
                                    hoTen: nvInfo?.hoTen ?? "",
                                    giaTri: gt,
                                    laHangTong: laTong
                                )
                            }
                        }
                    }

                    if !daTimThayDictCon {
                        for (k, v) in dong {
                            let kNorm = chuanHoaKhoaJSON(k)
                            if cacKhoaNhanVien.contains(kNorm) || cacKhoaMaNV.contains(kNorm) || kNorm.contains("nhan_vien") || kNorm.contains("nhanvien") {
                                continue
                            }
                            let gt = docGiaTriSo(v)
                            ghiNhanSoLieu(
                                tenNganhTho: k,
                                maNV: nvInfo?.maNV ?? "",
                                hoTen: nvInfo?.hoTen ?? "",
                                giaTri: gt,
                                laHangTong: laTong
                            )
                        }
                    }
                }
            }
        }

        // TRƯỜNG HỢP 2: JSON dạng Dictionary ánh xạ trực tiếp {"285688 - Lê Tuấn": {"Tivi TCL (DT)": 0, "CE LG (DT)": 83.70, ...}, "TỔNG": {...}}
        if bangMon.isEmpty {
            let dictNguon: [String: Any]
            if let sub = (json["du_lieu"] as? [String: Any]) ?? (json["data"] as? [String: Any]) ?? (json["nhan_vien"] as? [String: Any]) {
                dictNguon = sub
            } else {
                dictNguon = json
            }
            for (kOuter, vOuter) in dictNguon {
                guard let innerDict = vOuter as? [String: Any] else { continue }
                let uOuter = kOuter.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN")).uppercased()
                let laTong = (uOuter == "TONG" || uOuter == "TONG CONG" || uOuter == "TOTAL")
                if let nvInfo = laTong ? nil : tachMaVaTenNV(kOuter) {
                    for (tenMonKey, valMon) in innerDict {
                        let gt = docGiaTriSo(valMon)
                        ghiNhanSoLieu(
                            tenNganhTho: tenMonKey,
                            maNV: nvInfo.maNV,
                            hoTen: nvInfo.hoTen,
                            giaTri: gt,
                            laHangTong: false
                        )
                    }
                } else if laTong {
                    for (tenMonKey, valMon) in innerDict {
                        let gt = docGiaTriSo(valMon)
                        ghiNhanSoLieu(
                            tenNganhTho: tenMonKey,
                            maNV: "",
                            hoTen: "",
                            giaTri: gt,
                            laHangTong: true
                        )
                    }
                }
            }
        }

        var ketQua: [KetQuaThiDuaNhanVienKhoi] = []
        for kLM in thuTuMon {
            guard let info = bangMon[kLM], !info.dsNV.isEmpty else { continue }
            let dsQuet = info.dsNV.map { (ma, v) in
                DongThiDuaNhanVienQuet(
                    maNV: ma,
                    hoTen: v.hoTen,
                    thucHien: v.thucHien,
                    target: 0,
                    laPhanTram: false,
                    laPhanTramTargetCaNhan: false
                )
            }
            ketQua.append(KetQuaThiDuaNhanVienKhoi(
                tenNganhHang: info.tenChuan,
                danhSach: dsQuet,
                thucHienNganhGoiY: info.tong,
                targetNganhGoiY: 0
            ))
        }
        return gopVaLamSachKhoiThiDuaNhanVien(ketQua)
    }

    /// Gộp trùng các ngành hàng thi đua nhân viên theo khóa liền mạch và tự động khử lỗi nhảy số / sao chép nhầm giữa BẤT KỲ 2 cột nào bằng đối chiếu dòng TỔNG của từng cột
    func gopVaLamSachKhoiThiDuaNhanVien(_ danhSach: [KetQuaThiDuaNhanVienKhoi]) -> [KetQuaThiDuaNhanVienKhoi] {
        guard !danhSach.isEmpty else { return [] }
        var mapKhoi: [String: (tenChuan: String, tong: Double, target: Double, mapNV: [String: DongThiDuaNhanVienQuet], thuTuNV: [String])] = [:]
        var thuTuKhoi: [String] = []

        for khoi in danhSach {
            let tenChuan = KhoDuLieu.chuanHoaTenMonThiDuaChuan(khoi.tenNganhHang, tienToThangMacDinh: "T11")
            let kLM = KhoDuLieu.chuanHoaKhoaLienMachThiDua(tenChuan.isEmpty ? khoi.tenNganhHang : tenChuan)
            guard !kLM.isEmpty else { continue }

            if mapKhoi[kLM] == nil {
                mapKhoi[kLM] = (
                    tenChuan: tenChuan.isEmpty ? khoi.tenNganhHang : tenChuan,
                    tong: khoi.thucHienNganhGoiY,
                    target: khoi.targetNganhGoiY,
                    mapNV: [:],
                    thuTuNV: []
                )
                thuTuKhoi.append(kLM)
            } else {
                // Nếu 2 cột trong cùng lần quét bị gán trùng tên ngành hàng, giữ bản có tổng nhân viên khớp với dòng TỔNG hơn
                let tongNVCu = mapKhoi[kLM]?.mapNV.values.reduce(0.0, { $0 + $1.thucHien }) ?? 0
                let tongNVMoi = khoi.danhSach.reduce(0.0, { $0 + $1.thucHien })
                let saiSoCu = mapKhoi[kLM]!.tong > 0.0001 ? abs(tongNVCu - mapKhoi[kLM]!.tong) : Double.greatestFiniteMagnitude
                let saiSoMoi = khoi.thucHienNganhGoiY > 0.0001 ? abs(tongNVMoi - khoi.thucHienNganhGoiY) : Double.greatestFiniteMagnitude
                if saiSoMoi < saiSoCu {
                    mapKhoi[kLM]?.tong = khoi.thucHienNganhGoiY
                    if khoi.targetNganhGoiY > 0.0001 { mapKhoi[kLM]?.target = khoi.targetNganhGoiY }
                    mapKhoi[kLM]?.mapNV.removeAll()
                    mapKhoi[kLM]?.thuTuNV.removeAll()
                } else {
                    if mapKhoi[kLM]!.tong <= 0.0001 && khoi.thucHienNganhGoiY > 0.0001 {
                        mapKhoi[kLM]?.tong = khoi.thucHienNganhGoiY
                    }
                    if mapKhoi[kLM]!.target <= 0.0001 && khoi.targetNganhGoiY > 0.0001 {
                        mapKhoi[kLM]?.target = khoi.targetNganhGoiY
                    }
                }
            }

            for item in khoi.danhSach {
                let ma = KhoDuLieu.chuanHoaMaNV(item.maNV)
                let khoaNV = !ma.isEmpty ? ma : item.hoTen.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !khoaNV.isEmpty else { continue }
                if let daCo = mapKhoi[kLM]?.mapNV[khoaNV] {
                    if abs(item.thucHien) > 0.0001 && abs(daCo.thucHien) <= 0.0001 {
                        mapKhoi[kLM]?.mapNV[khoaNV] = item
                    }
                } else {
                    mapKhoi[kLM]?.thuTuNV.append(khoaNV)
                    mapKhoi[kLM]?.mapNV[khoaNV] = item
                }
            }
        }

        // Hậu kiểm tổng quát cho TẤT CẢ các cột:
        // Nếu bất kỳ cột B nào có tổng nhân viên vượt quá dòng TỔNG của chính cột B (do bị nhảy/lặp số từ cột A khác sang các ô "—" của cột B),
        // hoặc cột B sao chép nguyên mảng số lẻ của cột A, tự động loại bỏ các ô bị nhảy số để tổng nhân viên khớp chính xác với dòng TỔNG của cột B.
        for i in 0..<thuTuKhoi.count {
            let kB = thuTuKhoi[i]
            guard var infoB = mapKhoi[kB] else { continue }
            let tongGoiYB = infoB.tong
            var tongNVB = infoB.mapNV.values.reduce(0.0) { $0 + $1.thucHien }

            // Kiểm tra 1: Cột B có tổng nhân viên vượt dòng TỔNG (tongGoiYB) do nhảy số từ cột lân cận
            if tongGoiYB >= 0 && tongNVB > tongGoiYB + max(0.15, tongGoiYB * 0.06) {
                let cacKhoaKhac = thuTuKhoi.enumerated()
                    .filter { $0.offset != i }
                    .sorted { abs($0.offset - i) < abs($1.offset - i) }
                    .map(\.element)

                for kA in cacKhoaKhac {
                    guard let infoA = mapKhoi[kA] else { continue }
                    for (ma, var nvB) in infoB.mapNV where abs(nvB.thucHien) > 0.0001 {
                        guard let nvA = infoA.mapNV[ma],
                              abs(nvA.thucHien) > 0.0001,
                              abs(nvB.thucHien - nvA.thucHien) < 0.005 else { continue }
                        let saiSoHienTai = abs(tongNVB - tongGoiYB)
                        let saiSoNeuBo = abs((tongNVB - nvB.thucHien) - tongGoiYB)
                        if saiSoNeuBo + 0.01 < saiSoHienTai {
                            tongNVB -= nvB.thucHien
                            nvB.thucHien = 0
                            infoB.mapNV[ma] = nvB
                        }
                    }
                }
                mapKhoi[kB] = infoB
            }

            // Kiểm tra 2: Cả cột B (gồm cả dòng TỔNG) bị sao chép y hệt từ một cột A đứng trước
            let nvCoSoB = infoB.mapNV.filter { abs($0.value.thucHien) > 0.0001 }
            if nvCoSoB.count >= 3 && i > 0 {
                for j in 0..<i {
                    let kA = thuTuKhoi[j]
                    guard let infoA = mapKhoi[kA] else { continue }
                    var soTrungLe = 0
                    var tongTrung: Double = 0
                    for (ma, nvB) in nvCoSoB {
                        if let nvA = infoA.mapNV[ma],
                           abs(nvA.thucHien - nvB.thucHien) < 0.005,
                           (abs(nvB.thucHien - nvB.thucHien.rounded()) > 0.005 || nvB.thucHien >= 3.0) {
                            soTrungLe += 1
                            tongTrung += abs(nvB.thucHien)
                        }
                    }
                    if soTrungLe >= 3 && soTrungLe * 2 >= nvCoSoB.count && tongTrung >= 5.0 && abs(infoB.tong - infoA.tong) < 0.01 {
                        for (ma, var nvB) in infoB.mapNV {
                            if let nvA = infoA.mapNV[ma], abs(nvA.thucHien - nvB.thucHien) < 0.005 {
                                nvB.thucHien = 0
                                infoB.mapNV[ma] = nvB
                            }
                        }
                        infoB.tong = infoB.mapNV.values.reduce(0.0) { $0 + $1.thucHien }
                        mapKhoi[kB] = infoB
                        break
                    }
                }
            }
        }

        return thuTuKhoi.compactMap { kLM in
            guard let info = mapKhoi[kLM] else { return nil }
            let ds = info.thuTuNV.compactMap { info.mapNV[$0] }
            guard !ds.isEmpty else { return nil }
            return KetQuaThiDuaNhanVienKhoi(
                tenNganhHang: info.tenChuan,
                danhSach: ds,
                thucHienNganhGoiY: info.tong,
                targetNganhGoiY: info.target
            )
        }
    }

    /// Câu lệnh chuyên biệt đã tối ưu cho Gemini để quét bảng Doanh thu hợp nhất theo Nhân viên 5 cột
    private var promptDoanhThuNhanVien: String {
        """
        Đây là ảnh bảng "Doanh thu hợp nhất" theo Nhân viên gồm đúng 5 cột từ trái sang phải:
        - Cột 1 (NHÂN VIÊN / NGÀNH HÀNG BI / NHÓM HÀNG BI): Tên nhân viên ở dòng trên và mã nhân viên "id: <mã số>" ở dòng dưới (ví dụ: "Lê Tuấn", "id: 285688").
        - Cột 2 (SỐ LƯỢNG): Số lượng đơn / lượt bill bán hàng (số nguyên như 77, 64, 62, 85, 55, 43, 98, 73, 51, 75, 65, 84, 59, 85, 53, 52, 50, 2).
        - Cột 3 (DOANH THU QĐ): Doanh thu quy đổi (đơn vị triệu đồng, như 439, 433, 403, 381, 365, 339, 319, 314, 297, 264, 262, 258, 241, 204, 191, 171, 147, 0).
        - Cột 4 (DT QĐ KHOẢN VAY): Doanh thu quy đổi khoản vay (như 0).
        - Cột 5 (% TỈ TRỌNG): Phần trăm tỉ trọng đóng góp có dấu % ở cột ngoài cùng bên phải (như 8.7%, 8.6%, 8.0%, 7.6%, 7.3%, 6.8%, 6.4%, 6.2%, 5.9%, 5.3%, 5.2%, 5.1%, 4.8%, 4.1%, 3.8%, 3.4%, 2.9%, 0.0%).
        Bỏ qua hoàn toàn chữ chìm watermark nghiêng ("54453", "Dũng Nguyễn Thanh"). Tuyệt đối không gán cột SỐ LƯỢNG (cột 2) vào % TỈ TRỌNG (cột 5).
        Trả về DUY NHẤT 1 đối tượng JSON theo đúng cấu trúc:
        {"nhanVien":[{"maNV":"285688","hoTen":"Lê Tuấn","soLuong":77,"doanhThuQD":439,"dtKhoanVay":0,"phanTramTiTrong":8.7}]}
        """
    }

    /// Quét danh sách ảnh Bảng Doanh thu Nhân viên bằng Gemini 3.1 Flash
    func quetDoanhThuNhanVien(
        danhSachAnh: [UIImage],
        cheDo: LoaiCheDoDoanhThu = .luyKe,
        tienTrinh: ((String) -> Void)? = nil,
        hoanTat: @escaping (Result<[DoanhThuNhanVienItem], Error>) -> Void
    ) {
        let cd = KhoDuLieu.dungChung.layCaiDatAnToan()
        let danhSachKey = cd.danhSachGeminiApiKeyHieuLuc

        guard !danhSachKey.isEmpty, !danhSachAnh.isEmpty else {
            hoanTat(.failure(NSError(domain: "GeminiVision", code: 400, userInfo: [NSLocalizedDescriptionKey: "Chưa có ảnh hoặc API Key."])))
            return
        }

        var cacDuLieuAnh: [Data] = []
        for anh in danhSachAnh {
            if let d = duLieuAnhGon(anh) {
                cacDuLieuAnh.append(d)
            }
        }
        guard !cacDuLieuAnh.isEmpty else {
            hoanTat(.failure(NSError(domain: "GeminiVision", code: 400, userInfo: [NSLocalizedDescriptionKey: "Không đọc được dữ liệu ảnh."])))
            return
        }

        let cacModel = danhSachModelHopLe(modelUuTien: "gemini-3.1-flash")
        let tongAnh = cacDuLieuAnh.count
        let soLuongKey = max(1, min(3, danhSachKey.count))
        let khoa = NSLock()
        var ketQuaTungAnh = Array<[DoanhThuNhanVienItem]>(repeating: [], count: tongAnh)
        var loiCuoi: Error?
        let nhom = DispatchGroup()
        let semaphore = DispatchSemaphore(value: soLuongKey)

        DispatchQueue.global(qos: .userInitiated).async {
            for (idx, imgData) in cacDuLieuAnh.enumerated() {
                semaphore.wait()
                nhom.enter()
                let cacCapAnh = self.taoDanhSachCapThu(chiSoAnh: idx, danhSachKey: danhSachKey, cacModel: cacModel)
                let chiSoKeyHienThi = (idx % soLuongKey) + 1
                DispatchQueue.main.async {
                    tienTrinh?("Gemini Flash (Key \(chiSoKeyHienThi)/\(soLuongKey)) đang quét ảnh Doanh thu NV \(idx + 1)/\(tongAnh)...")
                }
                self.goiGeminiChoMotAnh(
                    cacCap: cacCapAnh,
                    chiSo: 0,
                    cheDo: cheDo,
                    imageData: imgData,
                    promptTuChon: self.promptDoanhThuNhanVien
                ) { kqAnh in
                    khoa.lock()
                    switch kqAnh {
                    case .success(let kq):
                        ketQuaTungAnh[idx] = kq.doanhThuNhanVien
                    case .failure(let err):
                        loiCuoi = err
                    }
                    khoa.unlock()
                    semaphore.signal()
                    nhom.leave()
                }
            }
            nhom.wait()

            let tatCa = ketQuaTungAnh.flatMap { $0 }
            DispatchQueue.main.async {
                if !tatCa.isEmpty {
                    hoanTat(.success(tatCa))
                } else {
                    hoanTat(.failure(loiCuoi ?? NSError(domain: "GeminiVision", code: 422, userInfo: [NSLocalizedDescriptionKey: "Chưa lọc được bảng doanh thu nhân viên từ JSON."])))
                }
            }
        }
    }

    func locDoanhThuNhanVienTuJSON(_ json: [String: Any]) -> [DoanhThuNhanVienItem] {
        let dsQuanLy = KhoDuLieu.dungChung.layCaiDatAnToan().danhSachNhanVien
        var mangDong: [[String: Any]] = []
        for (k, v) in json {
            if k == "thiDuaNhanVien" || k == "nganhHang" || k == "cotNganhHang" { continue }
            if let arr = v as? [[String: Any]], !arr.isEmpty {
                if arr.first?["soLieu"] != nil || arr.first?["so_lieu"] != nil { continue }
                mangDong = arr
                break
            }
        }
        guard !mangDong.isEmpty else { return [] }

        func chuanKhoa(_ k: String) -> String {
            k.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
                .replacingOccurrences(of: "đ", with: "d")
                .lowercased()
                .replacingOccurrences(of: "[^a-z0-9]+", with: "_", options: .regularExpression)
                .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        }

        var ketQua: [DoanhThuNhanVienItem] = []
        for item in mangDong {
            var maTho = ""
            var tenTho = ""
            var sl: Double = 0
            var dtQD: Double = 0
            var vay: Double = 0
            var tt: Double = 0

            for (k, v) in item {
                let kn = chuanKhoa(k)
                if kn == "manv" || kn == "ma_nv" || kn == "id" || kn == "ma_nhan_vien" {
                    if let s = v as? String { maTho = s }
                    else if let n = v as? NSNumber { maTho = n.stringValue }
                } else if kn == "hoten" || kn == "ho_ten" || kn == "ten" || kn.hasPrefix("nhan_vien") || kn == "nhanvien" {
                    if let s = v as? String { tenTho = s }
                } else if kn == "soluong" || kn == "so_luong" || kn == "so_luot_bill" || kn == "bill" {
                    sl = so(item, k)
                } else if kn == "doanhthuqd" || kn == "doanh_thu_qd" || kn == "doanhthu" || kn == "doanh_thu" {
                    dtQD = so(item, k)
                } else if kn.contains("khoan_vay") || kn.contains("khoanvay") || kn == "vay" {
                    vay = so(item, k)
                } else if kn.contains("ti_trong") || kn.contains("titrong") || kn.contains("ty_trong") || kn.contains("tytrong") || kn == "phan_tram" {
                    tt = so(item, k)
                }
            }

            var ma = KhoDuLieu.chuanHoaMaNV(maTho)
            var ten = tenTho
                .replacingOccurrences(of: "(?i)\\bid\\s*:\\s*\\d+", with: "", options: .regularExpression)
                .replacingOccurrences(of: "^[+\\-–—\\s]+", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if ma.isEmpty, let r = tenTho.range(of: "\\b\\d{4,7}\\b", options: .regularExpression) {
                ma = String(tenTho[r])
            }
            if !dsQuanLy.isEmpty, let khop = KhoDuLieu.khopNhanVienQuetVoiQuanLy(maQuet: ma, tenQuet: ten, dsQuanLy: dsQuanLy) {
                ma = khop.maNV
                ten = khop.hoTen
            }
            guard !ma.isEmpty || !ten.isEmpty else { continue }
            ketQua.append(DoanhThuNhanVienItem(
                maNV: ma,
                hoTen: ten,
                soLuong: sl,
                doanhThuThuc: 0,
                doanhThuQD: dtQD,
                target: 0,
                dtQDKhoanVay: vay,
                dtTraThangQD: 0,
                phanTramHT: 0,
                phanTramQuyDoi: tt
            ))
        }
        return ketQua
    }
}
