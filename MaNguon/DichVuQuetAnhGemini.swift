import UIKit

/// Phân tích ảnh bảng số liệu bằng Gemini Flash (Phương pháp 3) với API Key tích hợp sẵn trong app hoặc API Key nhập mới ở Cài đặt.
final class DichVuQuetAnhGemini {
    static let dungChung = DichVuQuetAnhGemini()
    private init() {}

    private struct CauHinhThuGemini {
        let key: String
        let model: String
        let tatThinking: Bool
    }

    func quet(
        danhSachAnh: [UIImage],
        cheDo: LoaiCheDoDoanhThu,
        tienTrinh: @escaping (String) -> Void,
        hoanTat: @escaping (Result<KetQuaQuetTatCaAnh, Error>) -> Void
    ) {
        let cd = KhoDuLieu.dungChung.layCaiDatAnToan()
        let keyUD = (UserDefaults.standard.string(forKey: "dmx.caiDat.geminiApiKey") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let keyCD = cd.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        let keyNguoiDung: String
        if !keyUD.isEmpty && keyUD != CaiDatDMX.geminiKeyMacDinh {
            keyNguoiDung = keyUD
        } else if !keyCD.isEmpty && keyCD != CaiDatDMX.geminiKeyMacDinh {
            keyNguoiDung = keyCD
        } else {
            keyNguoiDung = ""
        }

        let keyChinh = keyNguoiDung.isEmpty ? CaiDatDMX.geminiKeyMacDinh : keyNguoiDung

        var danhSachKey: [String] = []
        if !keyChinh.isEmpty {
            danhSachKey.append(keyChinh)
        }
        if !CaiDatDMX.geminiKeyMacDinh.isEmpty && !danhSachKey.contains(CaiDatDMX.geminiKeyMacDinh) {
            danhSachKey.append(CaiDatDMX.geminiKeyMacDinh)
        }

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

        let modelLuu = cd.geminiModel.trimmingCharacters(in: .whitespacesAndNewlines)
        let modelUuTien = (modelLuu.hasPrefix("gemini-") && modelLuu.contains("flash")) ? modelLuu : "gemini-2.5-flash"

        var cacModel: [(model: String, tatThinking: Bool)] = [
            (modelUuTien, modelUuTien.hasPrefix("gemini-2.5-flash")),
            ("gemini-2.5-flash", true),
            ("gemini-2.5-flash-lite", true),
            ("gemini-2.0-flash", false)
        ]
        var daCoModel = Set<String>()
        cacModel = cacModel.filter { item in
            let k = "\(item.model)|\(item.tatThinking)"
            if daCoModel.contains(k) { return false }
            daCoModel.insert(k)
            return true
        }

        var cacCapThu: [CauHinhThuGemini] = []
        for k in danhSachKey {
            for m in cacModel {
                cacCapThu.append(CauHinhThuGemini(key: k, model: m.model, tatThinking: m.tatThinking))
            }
        }

        // Quét từng ảnh độc lập (tối đa 2 ảnh song song) để tốc độ phản hồi chỉ 2-4 giây/ảnh và không bao giờ bị tràn maxOutputTokens
        let tongAnh = cacDuLieuAnh.count
        DispatchQueue.main.async {
            tienTrinh("Gemini Flash đang đọc \(tongAnh) ảnh (\(cheDo.tieuDe))...")
        }

        let khoaKetQua = NSLock()
        var ketQuaTungAnh = Array<KetQuaQuetTatCaAnh?>(repeating: nil, count: tongAnh)
        var loiCuoiCung: Error?
        var soAnhDaXong = 0

        let nhom = DispatchGroup()
        let semaphore = DispatchSemaphore(value: 2)

        DispatchQueue.global(qos: .userInitiated).async {
            for (idx, imgData) in cacDuLieuAnh.enumerated() {
                semaphore.wait()
                nhom.enter()
                DispatchQueue.main.async {
                    tienTrinh("Gemini Flash đang phân tích ảnh \(idx + 1)/\(tongAnh) (\(cheDo.tieuDe))...")
                }
                self.goiGeminiChoMotAnh(
                    cacCap: cacCapThu,
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
                    kqTong.thiDuaNhanVien.append(contentsOf: kq.thiDuaNhanVien)
                    kqTong.soAnhThiDuaNV += max(1, kq.soAnhThiDuaNV)
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

    /// Nén ảnh vừa đủ sắc nét (cạnh dài tối đa 1360px, JPEG 0.76) để tải lên Gemini Flash chỉ mất ~0.3s và phản hồi trong 2-4s.
    private func duLieuAnhGon(_ anh: UIImage) -> Data? {
        let gioiHan: CGFloat = 1360
        let canhLon = max(anh.size.width, anh.size.height)
        guard canhLon > gioiHan else { return anh.jpegData(compressionQuality: 0.76) }
        let tiLe = gioiHan / canhLon
        let kichThuoc = CGSize(width: (anh.size.width * tiLe).rounded(), height: (anh.size.height * tiLe).rounded())
        let dinhDang = UIGraphicsImageRendererFormat.default()
        dinhDang.scale = 1.0
        dinhDang.opaque = true
        let boVe = UIGraphicsImageRenderer(size: kichThuoc, format: dinhDang)
        let anhGon = boVe.image { _ in
            anh.draw(in: CGRect(origin: .zero, size: kichThuoc))
        }
        return anhGon.jpegData(compressionQuality: 0.76)
    }

    private func taoBodyData(imageData: Data, cheDo: LoaiCheDoDoanhThu, tatThinking: Bool) -> Data? {
        let parts: [[String: Any]] = [
            ["text": prompt(cheDo: cheDo)],
            ["inline_data": ["mime_type": "image/jpeg", "data": imageData.base64EncodedString()]]
        ]
        var genConfig: [String: Any] = [
            "temperature": 0.0,
            "maxOutputTokens": 4096,
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
            goiGeminiChoMotAnh(cacCap: cacCap, chiSo: chiSo + 1, cheDo: cheDo, imageData: imageData, hoanTat: hoanTat)
            return
        }
        thanhPhan.queryItems = [URLQueryItem(name: "key", value: cap.key)]
        guard let url = thanhPhan.url,
              let bodyData = taoBodyData(imageData: imageData, cheDo: cheDo, tatThinking: cap.tatThinking) else {
            goiGeminiChoMotAnh(cacCap: cacCap, chiSo: chiSo + 1, cheDo: cheDo, imageData: imageData, hoanTat: hoanTat)
            return
        }

        var req = URLRequest(url: url, timeoutInterval: 25)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = bodyData

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            guard let self else { return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if error != nil || status != 200 {
                if chiSo + 1 < cacCap.count {
                    self.goiGeminiChoMotAnh(cacCap: cacCap, chiSo: chiSo + 1, cheDo: cheDo, imageData: imageData, hoanTat: hoanTat)
                    return
                }
                let loi = data.map { self.thongDiepLoi(tu: $0, status: status) } ?? (error?.localizedDescription ?? "Gemini Flash không phản hồi.")
                hoanTat(.failure(NSError(domain: "GeminiVision", code: status, userInfo: [NSLocalizedDescriptionKey: loi])))
                return
            }

            guard let data, let json = self.layJSONKetQua(tu: data) else {
                if chiSo + 1 < cacCap.count {
                    self.goiGeminiChoMotAnh(cacCap: cacCap, chiSo: chiSo + 1, cheDo: cheDo, imageData: imageData, hoanTat: hoanTat)
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
                    self.goiGeminiChoMotAnh(cacCap: cacCap, chiSo: chiSo + 1, cheDo: cheDo, imageData: imageData, hoanTat: hoanTat)
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
        1. Phân biệt rõ 2 loại bảng Thi Đua có dấu (+) ở đầu dòng:
           - BẢNG THI ĐUA THEO NGÀY / REALTIME (5 CỘT): Gồm 5 cột: [CHƯƠNG TRÌNH | THỰC HIỆN | TARGET NGÀY | % HT NGÀY | HẠNG VÙNG].
             + Cột 1 (CHƯƠNG TRÌNH): Tên môn thi đua kèm huy hiệu "DT" hoặc "SL" ở cuối (bỏ dấu "+" và ngôi sao vàng ⭐ ở đầu; tách "DT" hoặc "SL" vào trường "loai"; phần tên môn sạch đưa vào "ten").
             + Cột 2 (THỰC HIỆN): Đưa vào "thucHien".
             + Cột 3 (TARGET NGÀY): Đưa vào "target".
             + Cột 4 (% HT NGÀY): Đưa vào "phanTramHT". Đặt "phanTramDuKien": 0 và "duKien": 0.
             + Cột 5 (HẠNG VÙNG): Bỏ qua.
           - BẢNG THI ĐUA LŨY KẾ (6 CỘT): Gồm 6 cột: [CHƯƠNG TRÌNH | THỰC HIỆN | TARGET | % HT | % HT DỰ KIẾN | HẠNG VÙNG].
             + Cột 1 (CHƯƠNG TRÌNH): Tách huy hiệu "DT"/"SL" vào "loai", tên môn sạch (bỏ dấu "+", ngôi sao ⭐) vào "ten".
             + Cột 2 (THỰC HIỆN): Đưa vào "thucHien".
             + Cột 3 (TARGET): Đưa vào "target" (lưu ý dấu phẩy hàng nghìn như 1,502.38 = 1502.38).
             + Cột 4 (% HT): Đưa vào "phanTramHT".
             + Cột 5 (% HT DỰ KIẾN): Đưa vào "phanTramDuKien".
             + Cột 6 (HẠNG VÙNG): Bỏ qua.
           - Ngoài ra nếu ảnh là Lưới thẻ thi đua 2 cột hoặc Bảng 4 cột có tiền tố T11: đọc đầy đủ tên môn, đơn vị DT/SL, Thực hiện, Target, % HT và % Dự kiến / DT Dự kiến.
        2. Đọc ĐẦY ĐỦ TẤT CẢ các dòng môn thi đua từ trên xuống dưới, kể cả các dòng tên dài xuống 2-3 hàng chữ như "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBAK EVO" (loai: "SL") hoặc "Trả chậm FECREDIT, SAMSUNG F+, SHINHAN, MCREDIT" và kể cả dòng có Thực hiện = 0, Target = 0. Không đưa nhãn DT, SL, CE, ICT, DV hay dấu + vào trong "ten".
        3. Với bảng doanh thu nhân viên 5 cột (NHÂN VIÊN / NGÀNH HÀNG BI | SỐ LƯỢNG | DOANH THU QĐ | DT QĐ KHOẢN VAY | % TỈ TRỌNG), trích đúng "maNV" (bỏ tiền tố id:) và "hoTen" vào mảng "nhanVien".
        4. Với bảng chi tiết môn thi đua của nhân viên (bảng mở rộng 1 môn thi đua có các dòng nhân viên kèm "id: <mã NV>" ở cột 1 và cột 2 hiển thị % đóng góp của nhân viên như 24%, 14%, 8%...): chỉ trích các hàng có cả tên nhân viên và id vào mảng "thiDuaNhanVien" (bỏ qua dòng tên chương trình và dòng tên siêu thị ĐML_...), đặt "laPhanTram": true, "thucHien" là con số phần trăm (ví dụ 24% -> 24), đặt "thucHienNganhGoiY" là số THỰC HIỆN của môn đó ở dòng đầu bảng, và đặt "targetNganhGoiY" là số TARGET của môn đó ở dòng đầu bảng.
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
                let laTheTinDung = (tenSach == "MỞ THẺ TÍN DỤNG VPBANK MWG VÀ TPBAK EVO")
                let loai: LoaiChiTieuThiDua = (loaiStr.contains("SL") || laTheTinDung) ? .soLuong : .doanhThu
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
                let ma = KhoDuLieu.chuanHoaMaNV((item["maNV"] as? String) ?? "")
                let ten = ((item["hoTen"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !ma.isEmpty || !ten.isEmpty else { return nil }
                return DoanhThuNhanVienItem(
                    maNV: ma,
                    hoTen: ten,
                    soLuong: so(item, "soLuong"),
                    doanhThuThuc: 0,
                    doanhThuQD: so(item, "doanhThuQD"),
                    dtQDKhoanVay: so(item, "dtKhoanVay"),
                    dtTraThangQD: so(item, "phanTramTiTrong"),
                    phanTramQuyDoi: so(item, "phanTramTiTrong")
                )
            }
            if !kq.doanhThuNhanVien.isEmpty { kq.soAnhDoanhThuNV = 1 }
        }
        if let arr = json["thiDuaNhanVien"] as? [[String: Any]] {
            kq.thiDuaNhanVien = arr.compactMap { khoi in
                let nganh = KhoDuLieu.chuanHoaTenMonThiDuaChuan((khoi["tenNganhHang"] as? String) ?? "")
                let thucHienGoiY = so(khoi, "thucHienNganhGoiY")
                let targetGoiY = so(khoi, "targetNganhGoiY")
                let ds = (khoi["danhSach"] as? [[String: Any]] ?? []).compactMap { nv -> DongThiDuaNhanVienQuet? in
                    let ma = KhoDuLieu.chuanHoaMaNV((nv["maNV"] as? String) ?? "")
                    let ten = ((nv["hoTen"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !ma.isEmpty, !ten.isEmpty else { return nil }
                    let laPT = (nv["laPhanTram"] as? Bool) ?? ((nv["thucHien"] as? String)?.contains("%") ?? false)
                    return DongThiDuaNhanVienQuet(
                        maNV: ma,
                        hoTen: ten,
                        thucHien: so(nv, "thucHien"),
                        target: so(nv, "target"),
                        laPhanTram: laPT
                    )
                }
                return ds.isEmpty ? nil : KetQuaThiDuaNhanVienKhoi(tenNganhHang: nganh, danhSach: ds, thucHienNganhGoiY: thucHienGoiY, targetNganhGoiY: targetGoiY)
            }
            kq.soAnhThiDuaNV = kq.thiDuaNhanVien.count
        }
        return kq
    }
}
