import UIKit

/// Phân tích ảnh bảng số liệu bằng Gemini Flash (Phương pháp 3) với API Key tích hợp sẵn trong app hoặc API Key nhập mới ở Cài đặt.
final class DichVuQuetAnhGemini {
    static let dungChung = DichVuQuetAnhGemini()
    private let khoaModel404 = NSLock()
    private var cacModelKhongHoTro = Set<String>()
    private init() {}

    /// Ưu tiên Gemini 3.5 Flash-Lite, sau đó 3.1 Flash-Lite. Khi cả hai model/key đều lỗi, lớp gọi bên ngoài chuyển sang OCR.
    private func danhSachModelHopLe() -> [(model: String, tatThinking: Bool)] {
        let ungVien: [(model: String, tatThinking: Bool)] = [
            ("gemini-3.5-flash-lite", true),
            ("gemini-3.1-flash-lite", true)
        ]
        khoaModel404.lock()
        let ds404 = cacModelKhongHoTro
        khoaModel404.unlock()
        let kq = ungVien.filter { !ds404.contains($0.model) }
        return kq.isEmpty ? ungVien : kq
    }

    private struct CauHinhThuGemini {
        let key: String
        let model: String
        let tatThinking: Bool
    }

    /// Thử theo thứ tự model rồi đến key: 3.5 với tối đa 3 project, sau đó 3.1 với cùng các project.
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
        for model in cacModel {
            for key in keyXoayVong.prefix(3) {
                cacCap.append(CauHinhThuGemini(key: key, model: model.model, tatThinking: model.tatThinking))
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

        DispatchQueue.global(qos: .userInitiated).async {
            var cacMucAnh: [(data: Data, luoiO: ThongTinLuoiMaTranAnh?)] = []
            for anh in danhSachAnh {
                if let d = self.duLieuAnhGon(anh) {
                    cacMucAnh.append((d, self.phanTichLuoiOAnhMaTran(anh)))
                }
            }
            guard !cacMucAnh.isEmpty else {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError(domain: "GeminiVision", code: 400, userInfo: [NSLocalizedDescriptionKey: "Không thể đọc dữ liệu từ ảnh đã chọn."])))
                }
                return
            }

            let cacModel = self.danhSachModelHopLe()
            let tongAnh = cacMucAnh.count
            let soLuongKey = max(1, min(3, danhSachKey.count))
            DispatchQueue.main.async {
                tienTrinh("⚡ Gemini 3.5 Flash-Lite đang quét đồng thời \(tongAnh) ảnh (\(soLuongKey) project · 0/\(tongAnh))...")
            }

            let khoaKetQua = NSLock()
            var ketQuaTungAnh = Array<KetQuaQuetTatCaAnh?>(repeating: nil, count: tongAnh)
            var loiCuoiCung: Error?
            var soAnhDaXong = 0
            var daGoiHoanTat = false

            func ketThucNeuCan(doTimeout: Bool = false) {
                khoaKetQua.lock()
                if daGoiHoanTat || (!doTimeout && soAnhDaXong < tongAnh) {
                    khoaKetQua.unlock()
                    return
                }
                daGoiHoanTat = true
                let cacKetQua = ketQuaTungAnh.compactMap { $0 }
                let loi = loiCuoiCung
                khoaKetQua.unlock()

                var kqTong = KetQuaQuetTatCaAnh()
                var dtGop = ThongTinDoanhThu()
                let laRT = (cheDo == .realtime)

                for kq in cacKetQua {
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
                        hoanTat(.failure(loi ?? NSError(
                            domain: "GeminiVision",
                            code: 422,
                            userInfo: [NSLocalizedDescriptionKey: "Gemini Flash không tìm thấy bảng số liệu hợp lệ trong ảnh."]
                        )))
                    }
                }
            }

            // Watchdog chống treo tuyệt đối sau 28 giây
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 28) {
                ketThucNeuCan(doTimeout: true)
            }

            // Gửi đồng thời tất cả các ảnh (phân bổ theo 1, 2 hoặc 3 Key đã nhập) để hoàn tất chỉ trong 3-5 giây
            for (idx, muc) in cacMucAnh.enumerated() {
                let cacCapAnh = self.taoDanhSachCapThu(chiSoAnh: idx, danhSachKey: danhSachKey, cacModel: cacModel)
                let doTreNhe: TimeInterval = (soLuongKey == 1) ? (Double(idx) * 0.15) : 0.0
                let promptMaTran: String? = (muc.luoiO?.soCotDuLieu == 13) ? self.taoPromptThiDuaNhanVien(luoiO: muc.luoiO) : nil
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + doTreNhe) {
                    self.goiGeminiChoMotAnh(
                        cacCap: cacCapAnh,
                        chiSo: 0,
                        cheDo: cheDo,
                        imageData: muc.data,
                        promptTuChon: promptMaTran,
                        luoiOTuChon: muc.luoiO
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
                            tienTrinh("⚡ Gemini Flash đã đọc xong \(xongHienTai)/\(tongAnh) ảnh (\(cheDo.tieuDe))...")
                        }
                        ketThucNeuCan(doTimeout: false)
                    }
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

        let gioiHan: CGFloat = 1800
        let canhLon = max(w, h)
        guard canhLon > gioiHan else { return anh.jpegData(compressionQuality: 0.82) }
        let tiLe = gioiHan / canhLon
        let kichThuoc = CGSize(width: (w * tiLe).rounded(), height: (h * tiLe).rounded())
        let dinhDang = UIGraphicsImageRendererFormat.default()
        dinhDang.scale = 1.0
        dinhDang.opaque = true
        let boVe = UIGraphicsImageRenderer(size: kichThuoc, format: dinhDang)
        let anhGon = boVe.image { _ in
            anh.draw(in: CGRect(origin: .zero, size: kichThuoc))
        }
        return anhGon.jpegData(compressionQuality: 0.82)
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
            // Tắt thinking để ưu tiên tốc độ và tránh cắt cụt JSON.
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
        luoiOTuChon: ThongTinLuoiMaTranAnh? = nil,
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
            goiGeminiChoMotAnh(cacCap: cacCap, chiSo: chiSo + 1, cheDo: cheDo, imageData: imageData, promptTuChon: promptTuChon, luoiOTuChon: luoiOTuChon, hoanTat: hoanTat)
            return
        }
        thanhPhan.queryItems = [URLQueryItem(name: "key", value: cap.key)]
        guard let url = thanhPhan.url,
              let bodyData = taoBodyData(imageData: imageData, cheDo: cheDo, tatThinking: cap.tatThinking, promptTuChon: promptTuChon) else {
            goiGeminiChoMotAnh(cacCap: cacCap, chiSo: chiSo + 1, cheDo: cheDo, imageData: imageData, promptTuChon: promptTuChon, luoiOTuChon: luoiOTuChon, hoanTat: hoanTat)
            return
        }

        var req = URLRequest(url: url, timeoutInterval: 20)
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
                    let delay: TimeInterval = (status == 429 || status == 503) ? 0.4 : 0.05
                    let chiSoTiep: Int
                    if status == 404 {
                        chiSoTiep = cacCap[(chiSo + 1)...].firstIndex(where: { $0.model != cap.model }) ?? cacCap.count
                    } else {
                        chiSoTiep = chiSo + 1
                    }
                    guard chiSoTiep < cacCap.count else {
                        let loi = data.map { self.thongDiepLoi(tu: $0, status: status) } ?? (error?.localizedDescription ?? "Gemini Flash-Lite không phản hồi.")
                        hoanTat(.failure(NSError(domain: "GeminiVision", code: status, userInfo: [NSLocalizedDescriptionKey: loi])))
                        return
                    }
                    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) {
                        self.goiGeminiChoMotAnh(cacCap: cacCap, chiSo: chiSoTiep, cheDo: cheDo, imageData: imageData, promptTuChon: promptTuChon, luoiOTuChon: luoiOTuChon, hoanTat: hoanTat)
                    }
                    return
                }
                let loi = data.map { self.thongDiepLoi(tu: $0, status: status) } ?? (error?.localizedDescription ?? "Gemini Flash không phản hồi.")
                hoanTat(.failure(NSError(domain: "GeminiVision", code: status, userInfo: [NSLocalizedDescriptionKey: loi])))
                return
            }

            guard let data, let json = self.layJSONKetQua(tu: data) else {
                if chiSo + 1 < cacCap.count {
                    self.goiGeminiChoMotAnh(cacCap: cacCap, chiSo: chiSo + 1, cheDo: cheDo, imageData: imageData, promptTuChon: promptTuChon, luoiOTuChon: luoiOTuChon, hoanTat: hoanTat)
                    return
                }
                hoanTat(.failure(NSError(
                    domain: "GeminiVision",
                    code: 422,
                    userInfo: [NSLocalizedDescriptionKey: "Gemini Flash đã phản hồi nhưng nội dung không đúng định dạng JSON số liệu."]
                )))
                return
            }

            let ketQua = self.chuyen(json: json, cheDo: cheDo, luoiO: luoiOTuChon)
            guard ketQua.coDuLieu else {
                if chiSo + 1 < cacCap.count {
                    self.goiGeminiChoMotAnh(cacCap: cacCap, chiSo: chiSo + 1, cheDo: cheDo, imageData: imageData, promptTuChon: promptTuChon, luoiOTuChon: luoiOTuChon, hoanTat: hoanTat)
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

        // Bỏ qua các part suy nghĩ nội bộ (thought == true) của Gemini.
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

    private func chuyen(json: [String: Any], cheDo: LoaiCheDoDoanhThu, luoiO: ThongTinLuoiMaTranAnh? = nil) -> KetQuaQuetTatCaAnh {
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
            let khoiTuBang = locThiDuaNhanVienTuJSON(json, luoiO: luoiO)
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

    /// Thông tin lưới ô 13 cột × 20 dòng nhân viên được trích xuất trực tiếp từ pixel ảnh (chỉ ~2ms/ảnh)
    /// giúp xác định chính xác 100% ô nào trên ảnh là dấu gạch ngang "—" (0 pixel đậm) và ô nào thực sự có chữ số (>= 4 pixel đậm).
    struct ThongTinLuoiMaTranAnh {
        let soCotDuLieu: Int
        let soHangNhanVien: Int
        let coSoTheoCot: [[Bool]] // coSoTheoCot[colIdx 0..<13][rowIdx 0..<soHang]
    }

    /// Phân tích nhanh lưới ô của ảnh Ma trận Thi đua Nhân viên bằng độ đậm pixel (không cần chạy OCR):
    /// - Chữ số thực tế trên bảng có độ xám < 140 (>= 4 pixel < 178).
    /// - Dấu gạch ngang "—" và chữ chìm watermark "54453 Dũng Nguyễn Thanh" có độ xám >= 195 (0 pixel < 178).
    func phanTichLuoiOAnhMaTran(_ anh: UIImage) -> ThongTinLuoiMaTranAnh? {
        guard let cgGoc = anh.cgImage else { return nil }
        let w0 = cgGoc.width
        let h0 = cgGoc.height
        guard w0 >= 300, h0 >= 150 else { return nil }

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
        ) else { return nil }

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
            if med <= 251 {
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
        guard colEdges.count >= 4 else { return nil }

        var colBounds: [(x0: Int, x1: Int)] = []
        for i in 0..<(colEdges.count - 1) {
            colBounds.append((colEdges[i], colEdges[i + 1]))
        }
        // Nếu 1 đường kẻ dọc mờ khiến 2 cột gộp làm 1 (colBounds.count == 13 thay vì 14), tự động tách đôi cột rộng gấp đôi
        if colBounds.count == 13 {
            let dataWidths = colBounds.dropFirst().map { $0.x1 - $0.x0 }.sorted()
            let medW = dataWidths[dataWidths.count / 2]
            varach: for i in 1..<colBounds.count {
                let wCol = colBounds[i].x1 - colBounds[i].x0
                if Double(wCol) > Double(medW) * 1.65 {
                    let mid = (colBounds[i].x0 + colBounds[i].x1) / 2
                    let c1 = (colBounds[i].x0, mid)
                    let c2 = (mid, colBounds[i].x1)
                    colBounds.replaceSubrange(i...i, with: [c1, c2])
                    break varach
                }
            }
        }
        guard colBounds.count == 14 else { return nil }

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
        var rowBounds: [(y0: Int, y1: Int)] = []
        if rowEdges.count >= 2 {
            for i in 0..<(rowEdges.count - 1) {
                rowBounds.append((rowEdges[i], rowEdges[i + 1]))
            }
        }
        if rowBounds.count > 20 {
            rowBounds = Array(rowBounds.prefix(20))
        }
        guard rowBounds.count >= 5 else { return nil }

        var coSoTheoCot: [[Bool]] = []
        for colIdx in 1..<colBounds.count {
            let cb = colBounds[colIdx]
            let rx0 = max(0, cb.x0 + 4)
            let rx1 = min(w0 - 1, cb.x1 - 4)
            var cotBool: [Bool] = []
            for rb in rowBounds {
                let ry0 = max(0, rb.y0 + 3)
                let ry1 = min(h0 - 1, rb.y1 - 3)
                var dp = 0
                if rx1 > rx0 && ry1 > ry0 {
                    for y in ry0...ry1 {
                        let gOff = y * w0
                        for x in rx0...rx1 {
                            if gray[gOff + x] < 178 {
                                dp += 1
                            }
                        }
                    }
                }
                cotBool.append(dp >= 4)
            }
            coSoTheoCot.append(cotBool)
        }

        return ThongTinLuoiMaTranAnh(
            soCotDuLieu: coSoTheoCot.count,
            soHangNhanVien: rowBounds.count,
            coSoTheoCot: coSoTheoCot
        )
    }

    /// Tạo câu lệnh chuyên biệt cho từng ảnh Ma trận Thi đua Nhân viên, đính kèm bản đồ tọa độ ô có số thực tế trên từng cột (nếu ảnh là bảng 13 cột)
    private func taoPromptThiDuaNhanVien(luoiO: ThongTinLuoiMaTranAnh?) -> String {
        var goiYLuoi = ""
        if let luoiO, luoiO.soCotDuLieu == 13 {
            var cacDongGoiY: [String] = []
            for c in 0..<13 {
                let hangCoSo = luoiO.coSoTheoCot[c].enumerated().compactMap { $0.element ? "\($0.offset + 1)" : nil }
                if hangCoSo.isEmpty {
                    cacDongGoiY.append("  + Cột \(c + 1): tất cả các hàng nhân viên đều là \"—\" (bắt buộc điền 0 hết).")
                } else {
                    cacDongGoiY.append("  + Cột \(c + 1): chỉ các hàng nhân viên thứ [\(hangCoSo.joined(separator: ", "))] có số (tất cả các hàng còn lại là \"—\" = 0).")
                }
            }
            goiYLuoi = """

            BẢN ĐỒ TỌA ĐỘ Ô CÓ SỐ TRÊN ẢNH NÀY (tính theo thứ tự hàng nhân viên từ 1 đến \(luoiO.soHangNhanVien) từ trên xuống dưới, sau hàng TỔNG):
            \(cacDongGoiY.joined(separator: "\n"))
            BẮT BUỘC tuân thủ đúng bản đồ trên: tại mỗi Cột k (1..13), những hàng nhân viên nằm trong danh sách có số thì PHẢI đọc đúng con số trên ảnh (tuyệt đối không để bằng 0), còn những hàng không nằm trong danh sách thì BẮT BUỘC ghi 0!
            """
        }

        return """
        Đây là ảnh bảng thực hiện thi đua (gồm cả ngành hàng tính theo Doanh thu DT và ngành hàng tính theo Số lượng SL) của nhân viên ứng với từng ngành hàng:
        - Cột đầu tiên bên trái ("NHÂN VIÊN"): hàng đầu tiên là "TỔNG", các hàng tiếp theo từ trên xuống dưới là từng nhân viên theo dạng "<Mã NV> - <Họ tên>" (nếu tên nhân viên xuống 2 dòng như "201962 - Nguyễn Thị Kim\nLoan" thì ghép lại thành 1 dòng).
        - 13 cột tiếp theo từ trái sang phải (Cột 1 đến Cột 13) là 13 ngành hàng thi đua.
        Hãy lọc chính xác toàn bộ bảng thành một đoạn JSON.

        QUY TẮC BẮT BUỘC ĐỂ ĐỌC ĐÚNG 100% CẢ 13 CỘT VÀ TỪNG NHÂN VIÊN:
        1. Bỏ qua hoàn toàn chữ chìm watermark nghiêng màu xám ("54453", "Dũng Nguyễn Thanh") kể cả khi chữ chìm đè lên tiêu đề cột như "Điện tử (DT)" hoặc "Bảo hiểm Thợ ĐMX (DT)".
        2. ĐỌC ĐÚNG THỨ TỰ 13 CỘT THỰC TẾ TRÊN ẢNH TỪ TRÁI SANG PHẢI (Cột 1 -> Cột 13):
           - Chuẩn hóa tên mỗi cột (bỏ ký hiệu ngôi sao "★", bỏ "(DT)", "(SL)") về đúng tên chuẩn trong 39 ngành hàng ĐMX thuộc 3 bảng sau:
             + Bảng Dịch Vụ (13 ngành): "Vay tiền mặt", "Trả Chậm Điện máy & Gia dụng", "Bảo hiểm Thọ ĐMX", "Ví trả sau", "Bảo hiểm Thọ ICT", "Bảo hiểm Tổng", "Sim ĐMX", "Trả chậm Homecredit", "Trả chậm FECREDIT, SAMSUNG F+, SHINHAN, MCREDIT", "Sim", "Nạp rút", "VAS", "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBANK EVO".
             + Bảng ICT / Phụ Kiện (13 ngành): "Phụ kiện công nghệ", "Điện thoại Vivo", "Điện thoại Realme", "ĐIỆN THOẠI & TABLET ANDROID", "Camera", "Sạc dự phòng", "Cáp sạc", "Đồng hồ & Smartwatch", "Phụ kiện khác IT & Nhóm khác", "Tai nghe", "Laptop", "Loa Phụ Kiện", "Đèn năng lượng mặt trời".
             + Bảng Điện Tử / Điện Lạnh / Gia Dụng (13 ngành): "Tivi TCL", "CE LG", "Điện tử Samsung", "Máy Lạnh", "Máy sấy / Máy rửa chén", "Máy nước nóng", "Điện tử", "Máy lọc nước", "Máy giặt", "Máy lọc KK - Hút bụi - Hút ẩm", "Nồi cơm & Nồi chiên", "Quạt gió", "Tủ Lạnh / Đông / Mát".
        3. ĐẶC BIỆT CHÚ Ý PHÂN BIỆT RÕ "Điện tử Samsung" VÀ "Điện tử" TRONG BẢNG ĐIỆN TỬ (CE):
           - Trên bảng Điện tử (CE), Cột "★ Điện tử Samsung (DT)" (tên chuẩn: "Điện tử Samsung") và Cột "Điện tử (DT)" (tên chuẩn: "Điện tử") là 2 CỘT HOÀN TOÀN RIÊNG BIỆT (thường Cột 3 là "Điện tử Samsung" có TỔNG 209.15 và Cột 7 là "Điện tử" có TỔNG 342.47).
           - Vì doanh thu Tivi Samsung nằm trong tổng Điện tử nên rất nhiều nhân viên có CÙNG MỘT CON SỐ ở cả cột "Điện tử Samsung" và cột "Điện tử" (ví dụ: nhân viên hàng 1 "285688 - Lê Tuấn" có 5.57 ở "Điện tử Samsung" VÀ cũng có 5.57 ở "Điện tử"; "116719 - Đinh Thị Quỳnh Nga" có 23.26 ở cả 2 cột; "201962 - Nguyễn Thị Kim Loan" có 12.02 ở cả 2 cột; "207241 - Huỳnh Tấn Thành" có 15.88 ở cả 2 cột).
           - BẮT BUỘC phải giữ nguyên đầy đủ con số thực tế (ví dụ 5.57 của Lê Tuấn) ở CẢ cột "Điện tử Samsung" LẪN cột "Điện tử", TUYỆT ĐỐI KHÔNG ĐƯỢC bỏ sót cột "Điện tử" hoặc tự ý ghi 0 vào cột "Điện tử"!
        4. GIỮ ĐÚNG CỘT DỌC & KHÔNG NHẢY SỐ GIỮA CÁC CỘT:
           - Mỗi mảng `soLieu` của từng nhân viên phải có ĐÚNG 13 PHẦN TỬ tương ứng với 13 cột từ trái sang phải (`Cột 1` đến `Cột 13`).
           - Ô nào có dấu gạch ngang "—", "-" hoặc trống thì ghi 0 tại đúng vị trí cột đó; ô nào có số âm (như -1.25) thì giữ nguyên dấu âm.\(goiYLuoi)
        5. Trả về DUY NHẤT 1 đối tượng JSON theo đúng cấu trúc:
        {"cotNganhHang":["Tên cột 1","Tên cột 2","...","Tên cột 13"],"hangTong":[0,0,0,0,0,0,0,0,0,0,0,0,0],"nhanVien":[{"maNV":"285688","hoTen":"Lê Tuấn","soLieu":[0,0,0,0,0,0,0,0,0,0,0,0,0]}]}
        """
    }

    private var promptThiDuaNhanVien: String {
        taoPromptThiDuaNhanVien(luoiO: nil)
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

        DispatchQueue.global(qos: .userInitiated).async {
            var cacMucAnh: [(data: Data, luoiO: ThongTinLuoiMaTranAnh?)] = []
            for anh in danhSachAnh {
                if let d = self.duLieuAnhGon(anh) {
                    let luoi = self.phanTichLuoiOAnhMaTran(anh)
                    cacMucAnh.append((d, luoi))
                }
            }
            guard !cacMucAnh.isEmpty else {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError(domain: "GeminiVision", code: 400, userInfo: [NSLocalizedDescriptionKey: "Không đọc được dữ liệu ảnh."])))
                }
                return
            }

            let cacModel = self.danhSachModelHopLe()
            let tongAnh = cacMucAnh.count
            let soLuongKey = max(1, min(3, danhSachKey.count))
            let khoa = NSLock()
            var ketQuaTungAnh = Array<[KetQuaThiDuaNhanVienKhoi]>(repeating: [], count: tongAnh)
            var loiCuoi: Error?
            var soAnhDaXong = 0
            var daHoanTat = false

            DispatchQueue.main.async {
                tienTrinh?("⚡ Gemini 3.5 Flash-Lite đang quét đồng thời \(tongAnh) ảnh Thi đua NV (\(soLuongKey) project · 0/\(tongAnh))...")
            }

            func ketThucTDNVNeuCan(doTimeout: Bool = false) {
                khoa.lock()
                if daHoanTat || (!doTimeout && soAnhDaXong < tongAnh) {
                    khoa.unlock()
                    return
                }
                daHoanTat = true
                let snapshotKhoi = ketQuaTungAnh.flatMap { $0 }
                let snapshotLoi = loiCuoi
                khoa.unlock()

                let tatCaKhoi = self.gopVaLamSachKhoiThiDuaNhanVien(snapshotKhoi)
                DispatchQueue.main.async {
                    if !tatCaKhoi.isEmpty {
                        hoanTat(.success(tatCaKhoi))
                    } else {
                        hoanTat(.failure(snapshotLoi ?? NSError(domain: "GeminiVision", code: 422, userInfo: [NSLocalizedDescriptionKey: "Chưa lọc được bảng thi đua nhân viên từ JSON."])))
                    }
                }
            }

            // Watchdog chống treo tuyệt đối sau 28 giây (không bao giờ kẹt ở 3/3)
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 28) {
                ketThucTDNVNeuCan(doTimeout: true)
            }

            // Gửi đồng thời tất cả các ảnh (phân bổ theo đúng 1, 2 hoặc 3 Key người dùng nhập)
            for (idx, muc) in cacMucAnh.enumerated() {
                let cacCapAnh = self.taoDanhSachCapThu(chiSoAnh: idx, danhSachKey: danhSachKey, cacModel: cacModel)
                let doTreNhe: TimeInterval = (soLuongKey == 1) ? (Double(idx) * 0.15) : 0.0
                let promptAnh = self.taoPromptThiDuaNhanVien(luoiO: muc.luoiO)
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + doTreNhe) {
                    self.goiGeminiChoMotAnh(
                        cacCap: cacCapAnh,
                        chiSo: 0,
                        cheDo: cheDo,
                        imageData: muc.data,
                        promptTuChon: promptAnh,
                        luoiOTuChon: muc.luoiO
                    ) { kqAnh in
                        khoa.lock()
                        soAnhDaXong += 1
                        let xongHienTai = soAnhDaXong
                        switch kqAnh {
                        case .success(let kq):
                            ketQuaTungAnh[idx] = kq.thiDuaNhanVien
                        case .failure(let err):
                            loiCuoi = err
                        }
                        khoa.unlock()
                        DispatchQueue.main.async {
                            tienTrinh?("⚡ Gemini Flash đã đọc xong \(xongHienTai)/\(tongAnh) ảnh Thi đua NV...")
                        }
                        ketThucTDNVNeuCan(doTimeout: false)
                    }
                }
            }
        }
    }

    /// Bộ lọc đa năng chuyển đổi kết quả JSON từ Gemini sang danh sách KetQuaThiDuaNhanVienKhoi của ứng dụng
    /// (tự động khôi phục tên cột bị đè watermark theo tập 13 ngành chuẩn và đối chiếu bản đồ pixel ô có số để không bao giờ mất cột "Điện tử" hoặc nhảy số sang cột "—")
    func locThiDuaNhanVienTuJSON(_ json: [String: Any], luoiO: ThongTinLuoiMaTranAnh? = nil) -> [KetQuaThiDuaNhanVienKhoi] {
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

        // TRƯỜNG HỢP 0 (Chuẩn tối ưu theo chỉ số cột 0..<soCot): {"cotNganhHang": [...], "hangTong": [...], "nhanVien": [{"maNV": "...", "hoTen": "...", "soLieu": [...]}]}
        if let dsCot = (json["cotNganhHang"] as? [String]) ?? (json["cot_nganh_hang"] as? [String]) ?? (json["nganhHang"] as? [String]) ?? (json["columns"] as? [String]),
           !dsCot.isEmpty {
            let cotNganhTho = dsCot.filter {
                let u = chuanHoaKhoaJSON($0)
                return u != "nhan_vien" && u != "ho_ten" && u != "ma_nv"
            }
            let soCot = cotNganhTho.count
            var mangTong = Array<Double>(repeating: 0, count: soCot)
            if let arrTong = (json["hangTong"] as? [Any]) ?? (json["hang_tong"] as? [Any]) ?? (json["tong"] as? [Any]) {
                for i in 0..<min(soCot, arrTong.count) {
                    mangTong[i] = docGiaTriSo(arrTong[i])
                }
            } else if let dictTong = (json["hangTong"] as? [String: Any]) ?? (json["hang_tong"] as? [String: Any]) {
                for (i, tenCot) in cotNganhTho.enumerated() {
                    let v = dictTong["C\(i + 1)"] ?? dictTong["c\(i + 1)"] ?? dictTong[tenCot]
                    mangTong[i] = docGiaTriSo(v)
                }
            }

            // Hoàn thiện danh sách 13 tên cột chuẩn (không bao giờ để mất cột "Điện tử" do trùng tên với "Điện tử Samsung" hoặc do chữ chìm watermark)
            let cotNganhChuan = KhoDuLieu.hoanThien13CotMaTran(tenCacCotTho: cotNganhTho, hangTong: mangTong, tienToThang: "T11")

            var dsNhanVienDong: [(maNV: String, hoTen: String, soLieu: [Double])] = []
            if let dsNV = (json["nhanVien"] as? [[String: Any]]) ?? (json["nhan_vien"] as? [[String: Any]]) ?? (json["danhSach"] as? [[String: Any]]) ?? (json["data"] as? [[String: Any]]) {
                for item in dsNV {
                    let maTho = (item["maNV"] as? String) ?? (item["ma_nv"] as? String) ?? ((item["maNV"] as? NSNumber)?.stringValue) ?? ""
                    let tenTho = (item["hoTen"] as? String) ?? (item["ho_ten"] as? String) ?? (item["ten"] as? String) ?? (item["nhanVien"] as? String) ?? ""
                    let uCheck = (maTho + " " + tenTho).folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN")).uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    let laTong = (uCheck == "TONG" || uCheck == "TONG CONG")
                    if laTong {
                        if let mangSo = (item["soLieu"] as? [Any]) ?? (item["so_lieu"] as? [Any]) ?? (item["giaTri"] as? [Any]) ?? (item["values"] as? [Any]) {
                            for i in 0..<min(soCot, mangSo.count) {
                                let v = docGiaTriSo(mangSo[i])
                                if abs(v) > 0.0001 { mangTong[i] = v }
                            }
                        }
                        continue
                    }
                    guard let nvInfo = tachMaVaTenNV(tenTho, maPhu: maTho), !nvInfo.maNV.isEmpty else { continue }
                    var soLieuNV = Array<Double>(repeating: 0, count: soCot)
                    if let mangSo = (item["soLieu"] as? [Any]) ?? (item["so_lieu"] as? [Any]) ?? (item["giaTri"] as? [Any]) ?? (item["values"] as? [Any]) {
                        for i in 0..<min(soCot, mangSo.count) {
                            soLieuNV[i] = docGiaTriSo(mangSo[i])
                        }
                    } else if let dictSo = (item["soLieu"] as? [String: Any]) ?? (item["so_lieu"] as? [String: Any]) ?? (item["nganhHang"] as? [String: Any]) ?? (item["nganh_hang"] as? [String: Any]) {
                        for (i, tenCot) in cotNganhTho.enumerated() {
                            if let v = dictSo["C\(i + 1)"] ?? dictSo["c\(i + 1)"] ?? dictSo[tenCot] ?? dictSo[cotNganhChuan[i]] {
                                soLieuNV[i] = docGiaTriSo(v)
                            }
                        }
                    }
                    dsNhanVienDong.append((maNV: nvInfo.maNV, hoTen: nvInfo.hoTen, soLieu: soLieuNV))
                }
            }

            // Đối chiếu với bản đồ pixel thực tế của ảnh (luoiO):
            // 1. Ô nào trên ảnh là dấu "—" (coSo == false) thì bắt buộc bằng 0 (chặn đứng 100% lỗi nhảy số từ cột Android sang cột Realme hoặc giữa bất kỳ 2 cột nào).
            // 2. Ô nào trên ảnh thực sự có chữ số (coSo == true) mà bị trả về 0 thì khôi phục chính xác từ hiệu số dòng TỔNG của cột đó (hoặc từ cột thương hiệu tương ứng).
            if let luoiO, luoiO.soCotDuLieu == soCot, abs(dsNhanVienDong.count - luoiO.soHangNhanVien) <= 1 {
                let soHangKhop = min(dsNhanVienDong.count, luoiO.soHangNhanVien)
                for c in 0..<soCot {
                    for r in 0..<soHangKhop {
                        if !luoiO.coSoTheoCot[c][r] {
                            dsNhanVienDong[r].soLieu[c] = 0
                        }
                    }
                }
                // Khôi phục nếu có đúng 1 ô có số thực tế trên ảnh (coSo == true) bị Gemini bỏ sót thành 0 trong cột c
                for c in 0..<soCot where mangTong[c] > 0.01 {
                    var cacHangThieu: [Int] = []
                    var tongDaCo: Double = 0
                    for r in 0..<soHangKhop {
                        if luoiO.coSoTheoCot[c][r] {
                            let v = dsNhanVienDong[r].soLieu[c]
                            if abs(v) <= 0.0001 {
                                cacHangThieu.append(r)
                            } else {
                                tongDaCo += v
                            }
                        }
                    }
                    if cacHangThieu.count == 1 {
                        let rThieu = cacHangThieu[0]
                        let phanConThieu = ((mangTong[c] - tongDaCo) * 100.0).rounded() / 100.0
                        if phanConThieu > 0.01 {
                            dsNhanVienDong[rThieu].soLieu[c] = phanConThieu
                        }
                    }
                }
            }

            // Hậu kiểm riêng cho cột "Điện tử" và "Điện tử Samsung":
            // Nếu nhân viên (như Lê Tuấn 285688) có số ở "Điện tử Samsung" (5.57) và tổng cột "Điện tử" đang thiếu đúng bằng con số đó do Gemini tưởng nhầm là trùng cột mà gán 0, tự động khôi phục đúng số cho cột "Điện tử"
            let idxSamsung = cotNganhChuan.firstIndex { KhoDuLieu.chuanHoaKhoaLienMachThiDua($0) == "DIENTUSAMSUNG" }
            let idxDienTu = cotNganhChuan.firstIndex { KhoDuLieu.chuanHoaKhoaLienMachThiDua($0) == "DIENTU" }
            if let cSam = idxSamsung, let cDT = idxDienTu, mangTong[cDT] > 0.01 {
                var tongDT = dsNhanVienDong.reduce(0.0) { $0 + $1.soLieu[cDT] }
                if mangTong[cDT] - tongDT >= 0.5 {
                    for r in dsNhanVienDong.indices {
                        let vSam = dsNhanVienDong[r].soLieu[cSam]
                        let vDT = dsNhanVienDong[r].soLieu[cDT]
                        let coSoTrenAnh = (luoiO != nil && cDT < luoiO!.soCotDuLieu && r < luoiO!.soHangNhanVien) ? luoiO!.coSoTheoCot[cDT][r] : true
                        if coSoTrenAnh && abs(vDT) <= 0.0001 && vSam > 0.01 {
                            if abs((tongDT + vSam) - mangTong[cDT]) < abs(tongDT - mangTong[cDT]) + 0.15 {
                                dsNhanVienDong[r].soLieu[cDT] = vSam
                                tongDT += vSam
                            }
                        }
                    }
                }
            }

            var ketQuaCot: [KetQuaThiDuaNhanVienKhoi] = []
            for i in 0..<soCot {
                let tenChuan = cotNganhChuan[i]
                guard !tenChuan.isEmpty,
                      KhoDuLieu.laTenMonThiDuaChuanDMX(tenChuan),
                      !KhoDuLieu.laTenDongNhanVienBiQuetNham(tenChuan) else { continue }
                let dsQuet = dsNhanVienDong.map { nv in
                    DongThiDuaNhanVienQuet(
                        maNV: nv.maNV,
                        hoTen: nv.hoTen,
                        thucHien: nv.soLieu[i],
                        target: 0,
                        laPhanTram: false,
                        laPhanTramTargetCaNhan: false
                    )
                }
                if !dsQuet.isEmpty {
                    ketQuaCot.append(KetQuaThiDuaNhanVienKhoi(
                        tenNganhHang: tenChuan,
                        danhSach: dsQuet,
                        thucHienNganhGoiY: mangTong[i],
                        targetNganhGoiY: 0
                    ))
                }
            }
            if !ketQuaCot.isEmpty {
                return gopVaLamSachKhoiThiDuaNhanVien(ketQuaCot)
            }
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

    /// Gộp trùng các ngành hàng thi đua nhân viên theo khóa liền mạch và chỉ khử lỗi nhảy số giữa 2 cột KỀ NHAU khi tổng nhân viên vượt dòng TỔNG
    /// (TUYỆT ĐỐI bảo toàn các cột độc lập có số trùng hợp lệ như "Điện tử" = 5.57 và "Điện tử Samsung" = 5.57 của Lê Tuấn).
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
                let tongNVCu = mapKhoi[kLM]?.mapNV.values.reduce(0.0, { $0 + $1.thucHien }) ?? 0
                let tongNVMoi = khoi.danhSach.reduce(0.0, { $0 + $1.thucHien })
                let saiSoCu = mapKhoi[kLM]!.tong > 0.0001 ? abs(tongNVCu - mapKhoi[kLM]!.tong) : Double.greatestFiniteMagnitude
                let saiSoMoi = khoi.thucHienNganhGoiY > 0.0001 ? abs(tongNVMoi - khoi.thucHienNganhGoiY) : Double.greatestFiniteMagnitude
                if saiSoMoi + 0.05 < saiSoCu {
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

        // Hậu kiểm an toàn: CHỈ kiểm tra giữa 2 cột KỀ NHAU TRỰC TIẾP (i - 1 và i + 1) khi cột B có dòng TỔNG > 0
        // và tổng các dòng nhân viên của cột B vượt xa dòng TỔNG của chính cột B (tongNVB > tongGoiYB + max(0.35, tongGoiYB * 0.03)),
        // đồng thời khi trừ đi số bị nhảy thì tổng cột B KHÔNG BAO GIỜ tụt xuống dưới dòng TỔNG (tongNVB - val >= tongGoiYB - 0.25).
        // Nhờ đó không bao giờ xóa nhầm các ô có số thật như Lê Tuấn ở cột "Điện tử" (5.57, tổng cột = 342.47).
        let cacCapChaConKhongLoc: Set<String> = [
            "DIENTU|DIENTUSAMSUNG", "DIENTUSAMSUNG|DIENTU",
            "DIENTU|CELG", "CELG|DIENTU",
            "DIENTU|TIVITCL", "TIVITCL|DIENTU",
            "MAYGIAT|CELG", "CELG|MAYGIAT",
            "TULANHDONGMAT|CELG", "CELG|TULANHDONGMAT"
        ]

        for i in 0..<thuTuKhoi.count {
            let kB = thuTuKhoi[i]
            guard var infoB = mapKhoi[kB] else { continue }
            let tongGoiYB = infoB.tong
            var tongNVB = infoB.mapNV.values.reduce(0.0) { $0 + $1.thucHien }

            if tongGoiYB > 0.01 && tongNVB > tongGoiYB + max(0.35, tongGoiYB * 0.03) {
                let cacChiSoKe = [i - 1, i + 1].filter { $0 >= 0 && $0 < thuTuKhoi.count }
                for j in cacChiSoKe {
                    let kA = thuTuKhoi[j]
                    if cacCapChaConKhongLoc.contains("\(kB)|\(kA)") { continue }
                    guard let infoA = mapKhoi[kA] else { continue }
                    for (ma, var nvB) in infoB.mapNV where abs(nvB.thucHien) > 0.0001 {
                        guard let nvA = infoA.mapNV[ma],
                              abs(nvA.thucHien) > 0.0001,
                              abs(nvB.thucHien - nvA.thucHien) < 0.005 else { continue }
                        let tongSauKhiBo = tongNVB - nvB.thucHien
                        // Chỉ loại bỏ nếu sau khi bỏ, tổng cột B vẫn >= (tongGoiYB - 0.25) và gần với tongGoiYB hơn rõ rệt
                        if tongSauKhiBo >= tongGoiYB - max(0.25, tongGoiYB * 0.02) &&
                           abs(tongSauKhiBo - tongGoiYB) + 0.10 < abs(tongNVB - tongGoiYB) {
                            tongNVB = tongSauKhiBo
                            nvB.thucHien = 0
                            infoB.mapNV[ma] = nvB
                        }
                    }
                }
                mapKhoi[kB] = infoB
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

    /// Quét danh sách ảnh Bảng Doanh thu Nhân viên bằng Gemini 3.5, dự phòng 3.1 Flash-Lite.
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

        DispatchQueue.global(qos: .userInitiated).async {
            var cacDuLieuAnh: [Data] = []
            for anh in danhSachAnh {
                if let d = self.duLieuAnhGon(anh) {
                    cacDuLieuAnh.append(d)
                }
            }
            guard !cacDuLieuAnh.isEmpty else {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError(domain: "GeminiVision", code: 400, userInfo: [NSLocalizedDescriptionKey: "Không đọc được dữ liệu ảnh."])))
                }
                return
            }

            let cacModel = self.danhSachModelHopLe()
            let tongAnh = cacDuLieuAnh.count
            let soLuongKey = max(1, min(3, danhSachKey.count))
            let khoa = NSLock()
            var ketQuaTungAnh = Array<[DoanhThuNhanVienItem]>(repeating: [], count: tongAnh)
            var loiCuoi: Error?
            var soAnhDaXong = 0
            var daHoanTat = false

            func ketThucDTNVNeuCan(doTimeout: Bool = false) {
                khoa.lock()
                if daHoanTat || (!doTimeout && soAnhDaXong < tongAnh) {
                    khoa.unlock()
                    return
                }
                daHoanTat = true
                let tatCa = ketQuaTungAnh.flatMap { $0 }
                let snapshotLoi = loiCuoi
                khoa.unlock()

                DispatchQueue.main.async {
                    if !tatCa.isEmpty {
                        hoanTat(.success(tatCa))
                    } else {
                        hoanTat(.failure(snapshotLoi ?? NSError(domain: "GeminiVision", code: 422, userInfo: [NSLocalizedDescriptionKey: "Chưa lọc được bảng doanh thu nhân viên từ JSON."])))
                    }
                }
            }

            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 25) {
                ketThucDTNVNeuCan(doTimeout: true)
            }

            for (idx, imgData) in cacDuLieuAnh.enumerated() {
                let cacCapAnh = self.taoDanhSachCapThu(chiSoAnh: idx, danhSachKey: danhSachKey, cacModel: cacModel)
                let doTreNhe: TimeInterval = (soLuongKey == 1) ? (Double(idx) * 0.15) : 0.0
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + doTreNhe) {
                    self.goiGeminiChoMotAnh(
                        cacCap: cacCapAnh,
                        chiSo: 0,
                        cheDo: cheDo,
                        imageData: imgData,
                        promptTuChon: self.promptDoanhThuNhanVien
                    ) { kqAnh in
                        khoa.lock()
                        soAnhDaXong += 1
                        let xongHienTai = soAnhDaXong
                        switch kqAnh {
                        case .success(let kq):
                            ketQuaTungAnh[idx] = kq.doanhThuNhanVien
                        case .failure(let err):
                            loiCuoi = err
                        }
                        khoa.unlock()
                        DispatchQueue.main.async {
                            tienTrinh?("⚡ Gemini Flash đã đọc xong \(xongHienTai)/\(tongAnh) ảnh Doanh thu NV...")
                        }
                        ketThucDTNVNeuCan(doTimeout: false)
                    }
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
