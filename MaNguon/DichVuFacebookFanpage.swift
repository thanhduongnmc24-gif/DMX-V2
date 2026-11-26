import UIKit
import Security
import LocalAuthentication

// MARK: - Mô hình thông tin Fanpage Facebook (chỉ lưu metadata không nhạy cảm, tách biệt từng tài khoản)

struct ThongTinFanpageFacebook: Codable, Equatable, Identifiable {
    var id: String { pageId }
    var pageId: String
    var tenFanpage: String
    var bonKyTuCuoiToken: String
    var ngayCapNhat: String

    var moTaTokenAn: String {
        let cuoi = bonKyTuCuoiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        return cuoi.isEmpty ? "••••" : "••••\(cuoi)"
    }
}

struct KetQuaDangBaiFacebook {
    var postId: String
    var duongDanBai: URL?
    var laHenGio: Bool
    var thoiGianHenGio: Date?
}

// MARK: - Kho Keychain cục bộ cho Fanpage Facebook (CHỈ lưu trên thiết bị này, tách riêng theo tài khoản DMX)

final class KhoKeychainFacebookFanpage {
    static let dungChung = KhoKeychainFacebookFanpage()
    private init() {}

    private let dichVuKeychain = "com.thanhduong.v2dmx.facebook-fanpage-v1"
    private let khoaDongBo = NSLock()

    /// Khóa định danh riêng cho tài khoản DMX đang đăng nhập. Nếu chưa đăng nhập trả về nil.
    var khoaTaiKhoanHienTai: String? {
        if let uid = DichVuDongBo.dungChung.phien?.userId?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(), !uid.isEmpty {
            return uid
        }
        let ten = DichVuDongBo.dungChung.tenDangNhap
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return ten.isEmpty ? nil : "user_\(ten)"
    }

    var tenHienThiTaiKhoanHienTai: String {
        let ten = DichVuDongBo.dungChung.tenDangNhap.trimmingCharacters(in: .whitespacesAndNewlines)
        return ten.isEmpty ? "Chưa đăng nhập" : ten
    }

    private func khoaMeta(cho taiKhoan: String) -> String {
        return "meta_\(taiKhoan)"
    }

    private func khoaToken(cho taiKhoan: String, pageId: String) -> String {
        return "token_\(taiKhoan)_\(pageId)"
    }

    private func khoaPageChonGanNhat(cho taiKhoan: String) -> String {
        return "selected_\(taiKhoan)"
    }

    // MARK: - Thao tác Keychain nguyên thủy (chỉ trên máy này, chỉ giải mã khi mở khóa)

    private func ghiKeychain(account: String, data: Data) -> OSStatus {
        let xoaQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: dichVuKeychain,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(xoaQuery as CFDictionary)

        let themQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: dichVuKeychain,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        return SecItemAdd(themQuery as CFDictionary, nil)
    }

    private func docKeychain(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: dichVuKeychain,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var ref: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &ref)
        guard status == errSecSuccess, let data = ref as? Data else { return nil }
        return data
    }

    private func xoaKeychain(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: dichVuKeychain,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - API công khai theo từng tài khoản

    func layDanhSachFanpage() -> [ThongTinFanpageFacebook] {
        khoaDongBo.lock()
        defer { khoaDongBo.unlock() }
        guard let tk = khoaTaiKhoanHienTai,
              let data = docKeychain(account: khoaMeta(cho: tk)),
              let ds = try? JSONDecoder().decode([ThongTinFanpageFacebook].self, from: data) else {
            return []
        }
        return ds
    }

    func coKhoaDaLuuCuaTaiKhoanHienTai() -> Bool {
        return !layDanhSachFanpage().isEmpty
    }

    func layPageIdDangChon() -> String? {
        khoaDongBo.lock()
        defer { khoaDongBo.unlock() }
        guard let tk = khoaTaiKhoanHienTai,
              let data = docKeychain(account: khoaPageChonGanNhat(cho: tk)),
              let str = String(data: data, encoding: .utf8), !str.isEmpty else {
            return nil
        }
        return str
    }

    func luuPageIdDangChon(_ pageId: String) {
        khoaDongBo.lock()
        defer { khoaDongBo.unlock() }
        guard let tk = khoaTaiKhoanHienTai, let data = pageId.data(using: .utf8) else { return }
        _ = ghiKeychain(account: khoaPageChonGanNhat(cho: tk), data: data)
    }

    func layToken(choPageId pageId: String) -> String? {
        khoaDongBo.lock()
        defer { khoaDongBo.unlock() }
        guard let tk = khoaTaiKhoanHienTai else { return nil }
        let idSach = pageId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !idSach.isEmpty,
              let data = docKeychain(account: khoaToken(cho: tk, pageId: idSach)),
              let token = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !token.isEmpty else {
            return nil
        }
        return token
    }

    func luuFanpage(pageId: String, tenFanpage: String, token: String) -> Result<ThongTinFanpageFacebook, Error> {
        khoaDongBo.lock()
        defer { khoaDongBo.unlock() }

        guard let tk = khoaTaiKhoanHienTai else {
            return .failure(NSError.dmx("Hãy đăng nhập tài khoản DMX trước khi lưu khóa Fanpage."))
        }
        let idSach = pageId.trimmingCharacters(in: .whitespacesAndNewlines)
        let tenSach = tenFanpage.trimmingCharacters(in: .whitespacesAndNewlines)
        let tokenSach = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !idSach.isEmpty, !tokenSach.isEmpty else {
            return .failure(NSError.dmx("Thiếu Page ID hoặc Page Access Token."))
        }
        guard let tokenData = tokenSach.data(using: .utf8) else {
            return .failure(NSError.dmx("Không mã hóa được dữ liệu token."))
        }

        let trangThaiLuuToken = ghiKeychain(account: khoaToken(cho: tk, pageId: idSach), data: tokenData)
        guard trangThaiLuuToken == errSecSuccess else {
            return .failure(NSError.dmx("Không ghi được token vào iOS Keychain (mã lỗi \(trangThaiLuuToken))."))
        }

        let bonKyTuCuoi = String(tokenSach.suffix(4))
        let thongTinMoi = ThongTinFanpageFacebook(
            pageId: idSach,
            tenFanpage: tenSach.isEmpty ? "Fanpage \(idSach)" : tenSach,
            bonKyTuCuoiToken: bonKyTuCuoi,
            ngayCapNhat: ISO8601DateFormatter().string(from: Date())
        )

        var danhSach: [ThongTinFanpageFacebook] = []
        if let dataCu = docKeychain(account: khoaMeta(cho: tk)),
           let dsCu = try? JSONDecoder().decode([ThongTinFanpageFacebook].self, from: dataCu) {
            danhSach = dsCu
        }
        if let idx = danhSach.firstIndex(where: { $0.pageId == idSach }) {
            danhSach[idx] = thongTinMoi
        } else {
            danhSach.append(thongTinMoi)
        }

        guard let metaData = try? JSONEncoder().encode(danhSach) else {
            return .failure(NSError.dmx("Không lưu được danh sách Fanpage vào Keychain."))
        }
        let trangThaiLuuMeta = ghiKeychain(account: khoaMeta(cho: tk), data: metaData)
        guard trangThaiLuuMeta == errSecSuccess else {
            return .failure(NSError.dmx("Không cập nhật được danh sách Fanpage trong Keychain (mã lỗi \(trangThaiLuuMeta))."))
        }
        if let idData = idSach.data(using: .utf8) {
            _ = ghiKeychain(account: khoaPageChonGanNhat(cho: tk), data: idData)
        }
        return .success(thongTinMoi)
    }

    func capNhatTenFanpage(pageId: String, tenMoi: String) {
        khoaDongBo.lock()
        defer { khoaDongBo.unlock() }
        guard let tk = khoaTaiKhoanHienTai,
              let dataCu = docKeychain(account: khoaMeta(cho: tk)),
              var danhSach = try? JSONDecoder().decode([ThongTinFanpageFacebook].self, from: dataCu),
              let idx = danhSach.firstIndex(where: { $0.pageId == pageId }) else { return }
        let tenSach = tenMoi.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tenSach.isEmpty else { return }
        danhSach[idx].tenFanpage = tenSach
        danhSach[idx].ngayCapNhat = ISO8601DateFormatter().string(from: Date())
        if let dataMoi = try? JSONEncoder().encode(danhSach) {
            _ = ghiKeychain(account: khoaMeta(cho: tk), data: dataMoi)
        }
    }

    func xoaFanpage(pageId: String) {
        khoaDongBo.lock()
        defer { khoaDongBo.unlock() }
        guard let tk = khoaTaiKhoanHienTai else { return }
        xoaKeychain(account: khoaToken(cho: tk, pageId: pageId))

        if let dataCu = docKeychain(account: khoaMeta(cho: tk)),
           var danhSach = try? JSONDecoder().decode([ThongTinFanpageFacebook].self, from: dataCu) {
            danhSach.removeAll { $0.pageId == pageId }
            if danhSach.isEmpty {
                xoaKeychain(account: khoaMeta(cho: tk))
                xoaKeychain(account: khoaPageChonGanNhat(cho: tk))
            } else if let dataMoi = try? JSONEncoder().encode(danhSach) {
                _ = ghiKeychain(account: khoaMeta(cho: tk), data: dataMoi)
            }
        }
    }

    func xoaTatCaCuaTaiKhoanHienTai() {
        khoaDongBo.lock()
        defer { khoaDongBo.unlock() }
        guard let tk = khoaTaiKhoanHienTai else { return }
        if let dataCu = docKeychain(account: khoaMeta(cho: tk)),
           let danhSach = try? JSONDecoder().decode([ThongTinFanpageFacebook].self, from: dataCu) {
            for page in danhSach {
                xoaKeychain(account: khoaToken(cho: tk, pageId: page.pageId))
            }
        }
        xoaKeychain(account: khoaMeta(cho: tk))
        xoaKeychain(account: khoaPageChonGanNhat(cho: tk))
    }

    // MARK: - Xác thực Face ID / Touch ID / Mật mã thiết bị trước khi quản lý khóa

    func xacThucChuThietBi(
        lyDo: String = "Xác thực để quản lý khóa kết nối Fanpage Facebook trên thiết bị này.",
        hoanTat: @escaping (Result<Void, Error>) -> Void
    ) {
        let context = LAContext()
        context.localizedFallbackTitle = "Dùng mật mã iPhone"
        var loi: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &loi) else {
            let ma = loi?.code ?? 0
            if ma == LAError.Code.passcodeNotSet.rawValue
                || ma == LAError.Code.biometryNotAvailable.rawValue
                || ma == LAError.Code.biometryNotEnrolled.rawValue {
                DispatchQueue.main.async { hoanTat(.success(())) }
            } else {
                let msg = loi?.localizedDescription ?? "Không thể xác thực chủ thiết bị."
                DispatchQueue.main.async { hoanTat(.failure(NSError.dmx(msg))) }
            }
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: lyDo) { thanhCong, err in
            DispatchQueue.main.async {
                if thanhCong {
                    hoanTat(.success(()))
                } else {
                    let ma = (err as NSError?)?.code ?? 0
                    if ma == LAError.Code.userCancel.rawValue
                        || ma == LAError.Code.systemCancel.rawValue
                        || ma == LAError.Code.appCancel.rawValue {
                        hoanTat(.failure(NSError.dmx("Đã hủy xác thực.")))
                    } else {
                        hoanTat(.failure(NSError.dmx("Xác thực không thành công. Không thể mở kho khóa Facebook.")))
                    }
                }
            }
        }
    }
}

// MARK: - Dịch vụ gọi Meta Graph API trực tiếp (Ephemeral session, Bearer Header, không lưu cache)

final class DichVuFacebookFanpage {
    static let dungChung = DichVuFacebookFanpage()

    private let phienBanGraph = "v22.0"
    private let phienMang: URLSession

    private init() {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.urlCache = nil
        cfg.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        cfg.httpCookieStorage = nil
        cfg.httpShouldSetCookies = false
        cfg.timeoutIntervalForRequest = 60
        cfg.timeoutIntervalForResource = 240
        let hangDoi = OperationQueue()
        hangDoi.name = "com.thanhduong.v2dmx.facebook-graph"
        hangDoi.qualityOfService = .userInitiated
        hangDoi.maxConcurrentOperationCount = 2
        phienMang = URLSession(configuration: cfg, delegate: nil, delegateQueue: hangDoi)
    }

    // MARK: - 1. Xác minh Token & luôn thu hẹp về đúng Page Access Token của 1 Fanpage

    func xacMinhVaLayPageToken(
        pageIdNhap: String,
        tokenNhap: String,
        hoanTat: @escaping (Result<(pageId: String, tenFanpage: String, pageToken: String), Error>) -> Void
    ) {
        let pageIdSach = pageIdNhap.trimmingCharacters(in: .whitespacesAndNewlines)
        let tokenSach = tokenNhap.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tokenSach.isEmpty else {
            DispatchQueue.main.async {
                hoanTat(.failure(NSError.dmx("Hãy dán Page Access Token của Fanpage.")))
            }
            return
        }
        if !pageIdSach.isEmpty && pageIdSach.range(of: "^[0-9]{5,30}$", options: .regularExpression) == nil {
            DispatchQueue.main.async {
                hoanTat(.failure(NSError.dmx("Page ID không hợp lệ (chỉ gồm các chữ số).")))
            }
            return
        }

        // Bước 1: Gọi /me?fields=id,name,category bằng Bearer header để kiểm tra có phải Page Token không.
        guard let urlMe = URL(string: "https://graph.facebook.com/\(phienBanGraph)/me?fields=id,name,category") else {
            DispatchQueue.main.async { hoanTat(.failure(NSError.dmx("URL Graph API không hợp lệ."))) }
            return
        }
        var req = URLRequest(url: urlMe)
        req.httpMethod = "GET"
        req.setValue("Bearer \(tokenSach)", forHTTPHeaderField: "Authorization")

        phienMang.dataTask(with: req) { [weak self] data, response, error in
            guard let self else { return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if let error {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError.dmx("Không kết nối được Facebook: \(self.lamSachThongDiep(error.localizedDescription, anToken: tokenSach))")))
                }
                return
            }

            if status == 200,
               let data,
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let id = obj["id"] as? String, !id.isEmpty,
               let name = obj["name"] as? String, !name.isEmpty,
               let category = obj["category"] as? String, !category.isEmpty {
                // Đây là Page Access Token hợp lệ!
                if !pageIdSach.isEmpty && pageIdSach != id {
                    DispatchQueue.main.async {
                        hoanTat(.failure(NSError.dmx("Token này thuộc Fanpage \"\(name)\" (ID: \(id)), không khớp với Page ID bạn nhập (\(pageIdSach)). Hãy để trống ô Page ID hoặc nhập đúng \(id).")))
                    }
                    return
                }
                DispatchQueue.main.async {
                    hoanTat(.success((pageId: id, tenFanpage: name, pageToken: tokenSach)))
                }
                return
            }

            // Nếu token là System User Token / User Token và người dùng có nhập sẵn Page ID cụ thể,
            // tự động đổi sang Page Access Token giới hạn riêng cho đúng Fanpage đó rồi bỏ token gốc.
            if !pageIdSach.isEmpty {
                self.doiSangPageTokenRieng(pageId: pageIdSach, tokenNguon: tokenSach, hoanTat: hoanTat)
                return
            }

            let thongDiepLoi = self.giaiMaLoiFacebook(data: data, status: status, anToken: tokenSach)
            if status == 200 {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError.dmx("Token bạn vừa dán là User / System User Token, KHÔNG phải Page Access Token. Để bảo mật và giới hạn đúng 1 trang, hãy nhập thêm Page ID của Fanpage (app sẽ tự trích riêng Page Token và không lưu token gốc) hoặc dán trực tiếp Page Access Token.")))
                }
            } else {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError.dmx(thongDiepLoi)))
                }
            }
        }.resume()
    }

    private func doiSangPageTokenRieng(
        pageId: String,
        tokenNguon: String,
        hoanTat: @escaping (Result<(pageId: String, tenFanpage: String, pageToken: String), Error>) -> Void
    ) {
        guard let url = URL(string: "https://graph.facebook.com/\(phienBanGraph)/\(pageId)?fields=id,name,category,access_token") else {
            DispatchQueue.main.async { hoanTat(.failure(NSError.dmx("Page ID không hợp lệ."))) }
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(tokenNguon)", forHTTPHeaderField: "Authorization")

        phienMang.dataTask(with: req) { [weak self] data, response, error in
            guard let self else { return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if let error {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError.dmx("Không kết nối được Facebook: \(self.lamSachThongDiep(error.localizedDescription, anToken: tokenNguon))")))
                }
                return
            }
            if status == 200,
               let data,
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let id = obj["id"] as? String, !id.isEmpty,
               let name = obj["name"] as? String, !name.isEmpty,
               let pageToken = obj["access_token"] as? String, !pageToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                DispatchQueue.main.async {
                    hoanTat(.success((pageId: id, tenFanpage: name, pageToken: pageToken.trimmingCharacters(in: .whitespacesAndNewlines))))
                }
                return
            }
            let loiChiTiet = self.giaiMaLoiFacebook(data: data, status: status, anToken: tokenNguon)
            DispatchQueue.main.async {
                hoanTat(.failure(NSError.dmx("Không trích xuất được Page Access Token cho Page ID \(pageId). \(loiChiTiet)")))
            }
        }.resume()
    }

    // MARK: - 2. Kiểm tra kết nối token đã lưu trong Keychain

    func kiemTraKetNoi(
        pageId: String,
        hoanTat: @escaping (Result<String, Error>) -> Void
    ) {
        guard let token = KhoKeychainFacebookFanpage.dungChung.layToken(choPageId: pageId) else {
            DispatchQueue.main.async {
                hoanTat(.failure(NSError.dmx("Không tìm thấy khóa Facebook của Fanpage này trong Keychain tài khoản hiện tại.")))
            }
            return
        }
        guard let url = URL(string: "https://graph.facebook.com/\(phienBanGraph)/\(pageId)?fields=id,name,category") else {
            DispatchQueue.main.async { hoanTat(.failure(NSError.dmx("Page ID không hợp lệ."))) }
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        phienMang.dataTask(with: req) { [weak self] data, response, error in
            guard let self else { return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if let error {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError.dmx("Lỗi mạng khi kiểm tra kết nối: \(self.lamSachThongDiep(error.localizedDescription, anToken: token))")))
                }
                return
            }
            if status == 200,
               let data,
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let name = obj["name"] as? String, !name.isEmpty {
                KhoKeychainFacebookFanpage.dungChung.capNhatTenFanpage(pageId: pageId, tenMoi: name)
                DispatchQueue.main.async { hoanTat(.success(name)) }
                return
            }
            let loi = self.giaiMaLoiFacebook(data: data, status: status, anToken: token)
            DispatchQueue.main.async { hoanTat(.failure(NSError.dmx(loi))) }
        }.resume()
    }

    // MARK: - 3. Đăng bài (Ảnh + Bài / Video + Bài / Chỉ chữ) & Hẹn giờ đăng

    func dangBaiLenFanpage(
        pageId: String,
        noiDung: String,
        anh: UIImage?,
        videoURL: URL?,
        thoiGianHenGio: Date?,
        hoanTat: @escaping (Result<KetQuaDangBaiFacebook, Error>) -> Void
    ) {
        guard let token = KhoKeychainFacebookFanpage.dungChung.layToken(choPageId: pageId) else {
            DispatchQueue.main.async {
                hoanTat(.failure(NSError.dmx("Chưa có Page Access Token trong Keychain cho Fanpage này. Hãy mở Quản lý khóa FB để kết nối.")))
            }
            return
        }

        let noiDungSach = noiDung.trimmingCharacters(in: .whitespacesAndNewlines)
        if noiDungSach.isEmpty && anh == nil && videoURL == nil {
            DispatchQueue.main.async {
                hoanTat(.failure(NSError.dmx("Hãy có ít nhất nội dung bài viết, ảnh poster hoặc video để đăng.")))
            }
            return
        }

        var mocHenGioUnix: Int? = nil
        if let henGio = thoiGianHenGio {
            let khoangCach = henGio.timeIntervalSinceNow
            if khoangCach < 11 * 60 {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError.dmx("Thời gian hẹn giờ trên Facebook phải cách hiện tại ít nhất 11 phút.")))
                }
                return
            }
            if khoangCach > 29 * 24 * 3600 {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError.dmx("Facebook chỉ cho hẹn giờ tối đa trong vòng 29 ngày tới.")))
                }
                return
            }
            mocHenGioUnix = Int(henGio.timeIntervalSince1970)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            if let videoURL {
                self.dangVideoLenFanpage(
                    pageId: pageId,
                    token: token,
                    moTa: noiDungSach,
                    videoURL: videoURL,
                    mocHenGioUnix: mocHenGioUnix,
                    thoiGianHenGio: thoiGianHenGio,
                    hoanTat: hoanTat
                )
            } else if let anh {
                self.dangAnhLenFanpage(
                    pageId: pageId,
                    token: token,
                    chuThich: noiDungSach,
                    anh: anh,
                    mocHenGioUnix: mocHenGioUnix,
                    thoiGianHenGio: thoiGianHenGio,
                    hoanTat: hoanTat
                )
            } else {
                self.dangVanBanLenFanpage(
                    pageId: pageId,
                    token: token,
                    noiDung: noiDungSach,
                    mocHenGioUnix: mocHenGioUnix,
                    thoiGianHenGio: thoiGianHenGio,
                    hoanTat: hoanTat
                )
            }
        }
    }

    private func dangVanBanLenFanpage(
        pageId: String,
        token: String,
        noiDung: String,
        mocHenGioUnix: Int?,
        thoiGianHenGio: Date?,
        hoanTat: @escaping (Result<KetQuaDangBaiFacebook, Error>) -> Void
    ) {
        guard let url = URL(string: "https://graph.facebook.com/\(phienBanGraph)/\(pageId)/feed") else {
            DispatchQueue.main.async { hoanTat(.failure(NSError.dmx("Page ID không hợp lệ."))) }
            return
        }

        var thamSo: [(String, String)] = [("message", noiDung)]
        if let unix = mocHenGioUnix {
            thamSo.append(("published", "false"))
            thamSo.append(("scheduled_publish_time", String(unix)))
        }
        let bodyString = thamSo
            .map { "\(maHoaFormURL($0.0))=\(maHoaFormURL($0.1))" }
            .joined(separator: "&")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.httpBody = bodyString.data(using: .utf8)

        phienMang.dataTask(with: req) { [weak self] data, response, error in
            self?.xuLyPhanHoiDangBai(
                data: data,
                response: response,
                error: error,
                pageId: pageId,
                tokenAn: token,
                laHenGio: mocHenGioUnix != nil,
                thoiGianHenGio: thoiGianHenGio,
                hoanTat: hoanTat
            )
        }.resume()
    }

    private func dangAnhLenFanpage(
        pageId: String,
        token: String,
        chuThich: String,
        anh: UIImage,
        mocHenGioUnix: Int?,
        thoiGianHenGio: Date?,
        hoanTat: @escaping (Result<KetQuaDangBaiFacebook, Error>) -> Void
    ) {
        guard let duLieuAnh = chuanHoaAnhDangFB(anh) else {
            DispatchQueue.main.async { hoanTat(.failure(NSError.dmx("Không chuẩn hóa được dữ liệu ảnh để tải lên Facebook."))) }
            return
        }
        guard let url = URL(string: "https://graph.facebook.com/\(phienBanGraph)/\(pageId)/photos") else {
            DispatchQueue.main.async { hoanTat(.failure(NSError.dmx("Page ID không hợp lệ."))) }
            return
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        if !chuThich.isEmpty {
            themTruongForm(&body, boundary: boundary, ten: "caption", giaTri: chuThich)
        }
        if let unix = mocHenGioUnix {
            themTruongForm(&body, boundary: boundary, ten: "published", giaTri: "false")
            themTruongForm(&body, boundary: boundary, ten: "scheduled_publish_time", giaTri: String(unix))
        }
        themTepForm(&body, boundary: boundary, ten: "source", tenTep: "poster-dmx.jpg", mimeType: "image/jpeg", duLieu: duLieuAnh)
        if let end = "--\(boundary)--\r\n".data(using: .utf8) {
            body.append(end)
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        req.httpBody = body

        phienMang.dataTask(with: req) { [weak self] data, response, error in
            self?.xuLyPhanHoiDangBai(
                data: data,
                response: response,
                error: error,
                pageId: pageId,
                tokenAn: token,
                laHenGio: mocHenGioUnix != nil,
                thoiGianHenGio: thoiGianHenGio,
                hoanTat: hoanTat
            )
        }.resume()
    }

    private func dangVideoLenFanpage(
        pageId: String,
        token: String,
        moTa: String,
        videoURL: URL,
        mocHenGioUnix: Int?,
        thoiGianHenGio: Date?,
        hoanTat: @escaping (Result<KetQuaDangBaiFacebook, Error>) -> Void
    ) {
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            DispatchQueue.main.async { hoanTat(.failure(NSError.dmx("Không tìm thấy tệp video trên máy."))) }
            return
        }
        let kichThuoc = (try? FileManager.default.attributesOfItem(atPath: videoURL.path)[.size] as? NSNumber)?.int64Value ?? 0
        guard kichThuoc > 0 else {
            DispatchQueue.main.async { hoanTat(.failure(NSError.dmx("Tệp video rỗng hoặc bị lỗi."))) }
            return
        }
        if kichThuoc > 150 * 1024 * 1024 {
            DispatchQueue.main.async { hoanTat(.failure(NSError.dmx("Video vượt quá 150MB. Hãy rút gọn hoặc nén video trước khi đăng trực tiếp."))) }
            return
        }
        guard let url = URL(string: "https://graph-video.facebook.com/\(phienBanGraph)/\(pageId)/videos") else {
            DispatchQueue.main.async { hoanTat(.failure(NSError.dmx("Page ID không hợp lệ."))) }
            return
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        let tepTam = FileManager.default.temporaryDirectory
            .appendingPathComponent("fb-video-upload-\(UUID().uuidString).multipart")

        do {
            FileManager.default.createFile(atPath: tepTam.path, contents: nil, attributes: nil)
            let handle = try FileHandle(forWritingTo: tepTam)
            defer { try? handle.close() }

            var headerData = Data()
            if !moTa.isEmpty {
                themTruongForm(&headerData, boundary: boundary, ten: "description", giaTri: moTa)
            }
            if let unix = mocHenGioUnix {
                themTruongForm(&headerData, boundary: boundary, ten: "published", giaTri: "false")
                themTruongForm(&headerData, boundary: boundary, ten: "scheduled_publish_time", giaTri: String(unix))
            }
            if let partHead = "--\(boundary)\r\nContent-Disposition: form-data; name=\"source\"; filename=\"video-dmx.mp4\"\r\nContent-Type: video/mp4\r\n\r\n".data(using: .utf8) {
                headerData.append(partHead)
            }
            try handle.write(contentsOf: headerData)

            let readHandle = try FileHandle(forReadingFrom: videoURL)
            defer { try? readHandle.close() }
            while let chunk = try readHandle.read(upToCount: 1024 * 1024), !chunk.isEmpty {
                try handle.write(contentsOf: chunk)
            }

            if let tail = "\r\n--\(boundary)--\r\n".data(using: .utf8) {
                try handle.write(contentsOf: tail)
            }
        } catch {
            try? FileManager.default.removeItem(at: tepTam)
            DispatchQueue.main.async {
                hoanTat(.failure(NSError.dmx("Không chuẩn bị được tệp tải lên video: \(error.localizedDescription)")))
            }
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        phienMang.uploadTask(with: req, fromFile: tepTam) { [weak self] data, response, error in
            try? FileManager.default.removeItem(at: tepTam)
            self?.xuLyPhanHoiDangBai(
                data: data,
                response: response,
                error: error,
                pageId: pageId,
                tokenAn: token,
                laHenGio: mocHenGioUnix != nil,
                thoiGianHenGio: thoiGianHenGio,
                hoanTat: hoanTat
            )
        }.resume()
    }

    // MARK: - Tiện ích xử lý phản hồi & chuẩn hóa dữ liệu

    private func xuLyPhanHoiDangBai(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        pageId: String,
        tokenAn: String,
        laHenGio: Bool,
        thoiGianHenGio: Date?,
        hoanTat: @escaping (Result<KetQuaDangBaiFacebook, Error>) -> Void
    ) {
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if let error {
            DispatchQueue.main.async {
                hoanTat(.failure(NSError.dmx("Lỗi mạng khi đăng Facebook: \(self.lamSachThongDiep(error.localizedDescription, anToken: tokenAn))")))
            }
            return
        }
        guard status >= 200 && status < 300,
              let data,
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let loi = giaiMaLoiFacebook(data: data, status: status, anToken: tokenAn)
            DispatchQueue.main.async { hoanTat(.failure(NSError.dmx(loi))) }
            return
        }

        let postId = (obj["post_id"] as? String) ?? (obj["id"] as? String) ?? ""
        let urlBai: URL?
        if postId.contains("_") {
            urlBai = URL(string: "https://www.facebook.com/\(postId)")
        } else if !postId.isEmpty {
            urlBai = URL(string: "https://www.facebook.com/\(pageId)/posts/\(postId)")
        } else {
            urlBai = URL(string: "https://www.facebook.com/\(pageId)")
        }
        let kq = KetQuaDangBaiFacebook(
            postId: postId,
            duongDanBai: urlBai,
            laHenGio: laHenGio,
            thoiGianHenGio: thoiGianHenGio
        )
        DispatchQueue.main.async { hoanTat(.success(kq)) }
    }

    private func chuanHoaAnhDangFB(_ img: UIImage) -> Data? {
        return autoreleasepool {
            let maxSide: CGFloat = 2048
            let w = img.size.width * img.scale
            let h = img.size.height * img.scale
            guard w > 10, h > 10 else { return img.jpegData(compressionQuality: 0.92) }
            let canhLon = max(w, h)
            let tiLe = canhLon > maxSide ? (maxSide / canhLon) : CGFloat(1.0)
            let kichThuoc = CGSize(width: max(1, (w * tiLe).rounded()), height: max(1, (h * tiLe).rounded()))
            let fmt = UIGraphicsImageRendererFormat()
            fmt.scale = 1.0
            fmt.opaque = true
            let anhChuan = UIGraphicsImageRenderer(size: kichThuoc, format: fmt).image { _ in
                UIColor.white.setFill()
                UIRectFill(CGRect(origin: .zero, size: kichThuoc))
                img.draw(in: CGRect(origin: .zero, size: kichThuoc))
            }
            return anhChuan.jpegData(compressionQuality: 0.92)
        }
    }

    private func themTruongForm(_ data: inout Data, boundary: String, ten: String, giaTri: String) {
        if let d = "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(ten)\"\r\n\r\n\(giaTri)\r\n".data(using: .utf8) {
            data.append(d)
        }
    }

    private func themTepForm(_ data: inout Data, boundary: String, ten: String, tenTep: String, mimeType: String, duLieu: Data) {
        if let head = "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(ten)\"; filename=\"\(tenTep)\"\r\nContent-Type: \(mimeType)\r\n\r\n".data(using: .utf8) {
            data.append(head)
        }
        data.append(duLieu)
        if let nl = "\r\n".data(using: .utf8) {
            data.append(nl)
        }
    }

    private func maHoaFormURL(_ str: String) -> String {
        let choPhep = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        return str.addingPercentEncoding(withAllowedCharacters: choPhep) ?? str
    }

    private func lamSachThongDiep(_ raw: String, anToken: String) -> String {
        guard !anToken.isEmpty else { return raw }
        return raw.replacingOccurrences(of: anToken, with: "[ĐÃ_ẨN]")
    }

    private func giaiMaLoiFacebook(data: Data?, status: Int, anToken: String) -> String {
        if let data,
           let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let err = root["error"] as? [String: Any] {
            let code = err["code"] as? Int ?? 0
            let msgGoc = lamSachThongDiep(err["message"] as? String ?? "", anToken: anToken)
            if code == 190 {
                return "Token Fanpage đã hết hạn hoặc bị thu hồi (mã 190). Hãy vào Quản lý khóa FB để dán Page Access Token mới."
            }
            if code == 200 || code == 10 {
                return "Token thiếu quyền đăng bài (pages_manage_posts / pages_read_engagement / publish_video) hoặc không có quyền quản trị trên Fanpage này. Chi tiết: \(msgGoc)"
            }
            if code == 100 && msgGoc.lowercased().contains("scheduled_publish_time") {
                return "Thời gian hẹn giờ không hợp lệ theo quy định Facebook (phải cách hiện tại từ 10 phút đến 30 ngày)."
            }
            if !msgGoc.isEmpty {
                return "Facebook lỗi (\(code > 0 ? "mã \(code)" : "HTTP \(status)")): \(msgGoc)"
            }
        }
        return "Facebook trả về lỗi HTTP \(status). Hãy kiểm tra lại Page Access Token và chế độ Live của Meta App."
    }
}

// MARK: - Màn hình Quản lý Khóa Fanpage Facebook (Bảo vệ bằng Face ID / Mật mã, Write-only)

final class ManHinhQuanLyFacebookFanpage: UIViewController {
    var khiThayDoiDanhSach: (() -> Void)?

    private let cuon = UIScrollView()
    private let ngan = UIStackView()
    private let oPageId = UITextField()
    private let oToken = UITextField()
    private let nutDanToken = UIButton(type: .system)
    private let nutLuu = UIButton(type: .system)
    private let nutHuongDan = UIButton(type: .system)
    private let vongQuay = UIActivityIndicatorView(style: .medium)
    private let nhanTrangThai = UILabel()
    private let nganDanhSach = UIStackView()
    private let nutXoaTatCa = UIButton(type: .system)
    private var danhSach: [ThongTinFanpageFacebook] = []
    private var dangXuLy = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "🔐 Khóa Fanpage Facebook"
        view.backgroundColor = BangMauBCTD.nenTrang
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Đóng", style: .done, target: self, action: #selector(bamDong))

        let chamAnBanPhim = UITapGestureRecognizer(target: self, action: #selector(anBanPhim))
        chamAnBanPhim.cancelsTouchesInView = false
        view.addGestureRecognizer(chamAnBanPhim)

        dungGiaoDien()
        taiDanhSach()
    }

    @objc private func bamDong() {
        dismiss(animated: true)
    }

    @objc private func anBanPhim() {
        view.endEditing(true)
    }

    private func dungGiaoDien() {
        cuon.translatesAutoresizingMaskIntoConstraints = false
        cuon.keyboardDismissMode = .interactive
        cuon.alwaysBounceVertical = true
        view.addSubview(cuon)

        ngan.axis = .vertical
        ngan.spacing = 12
        ngan.translatesAutoresizingMaskIntoConstraints = false
        cuon.addSubview(ngan)

        NSLayoutConstraint.activate([
            cuon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cuon.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cuon.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cuon.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            ngan.topAnchor.constraint(equalTo: cuon.contentLayoutGuide.topAnchor, constant: 12),
            ngan.leadingAnchor.constraint(equalTo: cuon.frameLayoutGuide.leadingAnchor, constant: 14),
            ngan.trailingAnchor.constraint(equalTo: cuon.frameLayoutGuide.trailingAnchor, constant: -14),
            ngan.bottomAnchor.constraint(equalTo: cuon.contentLayoutGuide.bottomAnchor, constant: -24)
        ])

        // 1. Thẻ thông tin bảo mật & tách tài khoản
        let (theBaoMat, stackBaoMat) = taoThe(tieuDe: "🛡️ Bảo mật theo từng tài khoản")
        let tenTK = KhoKeychainFacebookFanpage.dungChung.tenHienThiTaiKhoanHienTai
        let nhanTK = taoNhan("Tài khoản DMX đang đăng nhập: \(tenTK)", dam: true)
        nhanTK.textColor = BangMauBCTD.xanhChuDaoDam
        stackBaoMat.addArrangedSubview(nhanTK)
        stackBaoMat.addArrangedSubview(taoNhan("• Khóa Facebook chỉ lưu trong iOS Keychain phần cứng của riêng máy này (WhenUnlockedThisDeviceOnly).\n• Tách biệt hoàn toàn theo từng tài khoản DMX — tài khoản khác đăng nhập sẽ không thấy khóa này.\n• Tuyệt đối KHÔNG lưu ra thư mục Tệp (Documents) và KHÔNG đẩy lên đám mây / Supabase.\n• Sau khi lưu, app không bao giờ hiển thị lại chuỗi token gốc."))
        ngan.addArrangedSubview(theBaoMat)

        // 2. Thẻ thêm / cập nhật Fanpage
        let (theThem, stackThem) = taoThe(tieuDe: "➕ Thêm hoặc cập nhật Fanpage")
        stackThem.addArrangedSubview(taoNhan("Page ID (để trống nếu dán trực tiếp Page Access Token; bắt buộc nhập nếu muốn app tự trích Page Token từ System User Token):"))
        cauHinhO(oPageId, goiY: "Ví dụ: 1353269864728879 (tùy chọn)", baoMat: false)
        oPageId.keyboardType = .numberPad
        stackThem.addArrangedSubview(oPageId)

        stackThem.addArrangedSubview(taoNhan("Page Access Token (ẩn ký tự, gửi qua Bearer Header):"))
        cauHinhO(oToken, goiY: "Dán Page Access Token tại đây…", baoMat: true)
        oToken.textContentType = .oneTimeCode
        stackThem.addArrangedSubview(oToken)

        nutDanToken.setTitle("📋 Dán Token từ bộ nhớ tạm", for: .normal)
        cauHinhNutPhu(nutDanToken)
        nutDanToken.addTarget(self, action: #selector(bamDanToken), for: .touchUpInside)
        stackThem.addArrangedSubview(nutDanToken)

        nutLuu.setTitle("🔒 Xác minh & Lưu vào Keychain", for: .normal)
        cauHinhNutChinh(nutLuu, mau: BangMauBCTD.xanhChuDao)
        nutLuu.addTarget(self, action: #selector(bamXacMinhVaLuu), for: .touchUpInside)
        stackThem.addArrangedSubview(nutLuu)

        nutHuongDan.setTitle("❓ Hướng dẫn lấy Page Token & bật Live Mode", for: .normal)
        cauHinhNutPhu(nutHuongDan)
        nutHuongDan.addTarget(self, action: #selector(bamHuongDan), for: .touchUpInside)
        stackThem.addArrangedSubview(nutHuongDan)

        vongQuay.hidesWhenStopped = true
        nhanTrangThai.font = .systemFont(ofSize: 12.5, weight: .semibold)
        nhanTrangThai.textColor = BangMauBCTD.chuPhu
        nhanTrangThai.numberOfLines = 0
        nhanTrangThai.lineBreakMode = .byWordWrapping
        nhanTrangThai.adjustsFontSizeToFitWidth = false
        let hangTrangThai = UIStackView(arrangedSubviews: [vongQuay, nhanTrangThai])
        hangTrangThai.axis = .horizontal
        hangTrangThai.spacing = 8
        hangTrangThai.alignment = .center
        stackThem.addArrangedSubview(hangTrangThai)
        ngan.addArrangedSubview(theThem)

        // 3. Thẻ danh sách Fanpage đã kết nối
        let (theDS, stackDS) = taoThe(tieuDe: "📘 Fanpage đã kết nối trên máy này")
        nganDanhSach.axis = .vertical
        nganDanhSach.spacing = 8
        stackDS.addArrangedSubview(nganDanhSach)

        nutXoaTatCa.setTitle("🗑 Xóa toàn bộ khóa Facebook của tài khoản này", for: .normal)
        cauHinhNutChinh(nutXoaTatCa, mau: .systemRed)
        nutXoaTatCa.addTarget(self, action: #selector(bamXoaTatCa), for: .touchUpInside)
        stackDS.addArrangedSubview(nutXoaTatCa)
        ngan.addArrangedSubview(theDS)
    }

    private func taiDanhSach() {
        danhSach = KhoKeychainFacebookFanpage.dungChung.layDanhSachFanpage()
        veDanhSach()
    }

    private func veDanhSach() {
        nganDanhSach.arrangedSubviews.forEach { nganDanhSach.removeArrangedSubview($0); $0.removeFromSuperview() }
        nutXoaTatCa.isHidden = danhSach.isEmpty
        if danhSach.isEmpty {
            nganDanhSach.addArrangedSubview(taoNhan("Tài khoản này chưa lưu khóa Fanpage nào trên máy."))
            return
        }

        for (idx, page) in danhSach.enumerated() {
            let khung = UIStackView()
            khung.axis = .vertical
            khung.spacing = 8
            khung.isLayoutMarginsRelativeArrangement = true
            khung.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            khung.backgroundColor = BangMauBCTD.nenThePhu
            khung.layer.cornerRadius = 10
            khung.layer.borderWidth = 1
            khung.layer.borderColor = BangMauBCTD.vienThe.cgColor

            let nhanTen = taoNhan("📘 \(page.tenFanpage)", dam: true)
            let nhanChiTiet = taoNhan("Page ID: \(page.pageId) • Token: \(page.moTaTokenAn)")
            nhanChiTiet.textColor = BangMauBCTD.chuPhu
            khung.addArrangedSubview(nhanTen)
            khung.addArrangedSubview(nhanChiTiet)

            let nutKiemTra = UIButton(type: .system)
            nutKiemTra.setTitle("✅ Kiểm tra kết nối", for: .normal)
            nutKiemTra.tag = idx
            cauHinhNutPhu(nutKiemTra)
            nutKiemTra.addTarget(self, action: #selector(bamKiemTraPage(_:)), for: .touchUpInside)

            let nutXoa = UIButton(type: .system)
            nutXoa.setTitle("🗑 Xóa khóa", for: .normal)
            nutXoa.tag = idx
            nutXoa.titleLabel?.font = .systemFont(ofSize: 13.5, weight: .bold)
            nutXoa.titleLabel?.numberOfLines = 0
            nutXoa.titleLabel?.lineBreakMode = .byWordWrapping
            nutXoa.titleLabel?.adjustsFontSizeToFitWidth = false
            nutXoa.setTitleColor(.systemRed, for: .normal)
            nutXoa.backgroundColor = UIColor.systemRed.withAlphaComponent(0.08)
            nutXoa.layer.cornerRadius = 9
            nutXoa.layer.borderWidth = 1
            nutXoa.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.35).cgColor
            nutXoa.contentEdgeInsets = UIEdgeInsets(top: 9, left: 10, bottom: 9, right: 10)
            nutXoa.addTarget(self, action: #selector(bamXoaPage(_:)), for: .touchUpInside)

            let hangNut = UIStackView(arrangedSubviews: [nutKiemTra, nutXoa])
            hangNut.axis = .horizontal
            hangNut.spacing = 8
            hangNut.distribution = .fillEqually
            khung.addArrangedSubview(hangNut)

            nganDanhSach.addArrangedSubview(khung)
        }
    }

    private func datTrangThai(_ dangChay: Bool, thongDiep: String, mau: UIColor = BangMauBCTD.chuPhu) {
        dangXuLy = dangChay
        nutLuu.isEnabled = !dangChay
        nutDanToken.isEnabled = !dangChay
        if dangChay { vongQuay.startAnimating() } else { vongQuay.stopAnimating() }
        nhanTrangThai.text = thongDiep
        nhanTrangThai.textColor = mau
    }

    @objc private func bamDanToken() {
        guard let str = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty else {
            datTrangThai(false, thongDiep: "⚠️ Bộ nhớ tạm hiện đang trống.", mau: .systemOrange)
            return
        }
        oToken.text = str
        datTrangThai(false, thongDiep: "Đã dán token (đã ẩn ký tự). Bấm “Xác minh & Lưu vào Keychain” để kiểm tra.", mau: BangMauBCTD.xanhChuDao)
    }

    @objc private func bamXacMinhVaLuu() {
        view.endEditing(true)
        guard !dangXuLy else { return }
        let pageIdNhap = (oPageId.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let tokenNhap = (oToken.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tokenNhap.isEmpty else {
            datTrangThai(false, thongDiep: "⚠️ Hãy dán Page Access Token trước khi lưu.", mau: .systemRed)
            return
        }

        datTrangThai(true, thongDiep: "Đang xác minh Page Token với Meta Graph API…", mau: BangMauBCTD.xanhChuDao)
        DichVuFacebookFanpage.dungChung.xacMinhVaLayPageToken(pageIdNhap: pageIdNhap, tokenNhap: tokenNhap) { [weak self] ketQua in
            guard let self else { return }
            switch ketQua {
            case .failure(let loi):
                self.datTrangThai(false, thongDiep: "⚠️ \(loi.localizedDescription)", mau: .systemRed)
            case .success(let kq):
                let kqLuu = KhoKeychainFacebookFanpage.dungChung.luuFanpage(
                    pageId: kq.pageId,
                    tenFanpage: kq.tenFanpage,
                    token: kq.pageToken
                )
                // Tự xóa clipboard nếu vẫn đang chứa token vừa dán để chống app khác đọc trộm
                if UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) == tokenNhap {
                    UIPasteboard.general.string = ""
                }
                self.oToken.text = ""
                self.oPageId.text = ""
                switch kqLuu {
                case .success(let daLuu):
                    self.taiDanhSach()
                    self.khiThayDoiDanhSach?()
                    self.datTrangThai(
                        false,
                        thongDiep: "✅ Đã lưu an toàn vào Keychain: \(daLuu.tenFanpage) (ID: \(daLuu.pageId), Token: \(daLuu.moTaTokenAn)). Bộ nhớ tạm đã được dọn sạch.",
                        mau: BangMauBCTD.xanhLaDam
                    )
                case .failure(let loi):
                    self.datTrangThai(false, thongDiep: "⚠️ \(loi.localizedDescription)", mau: .systemRed)
                }
            }
        }
    }

    @objc private func bamKiemTraPage(_ sender: UIButton) {
        guard !dangXuLy, danhSach.indices.contains(sender.tag) else { return }
        let page = danhSach[sender.tag]
        datTrangThai(true, thongDiep: "Đang kiểm tra kết nối tới \(page.tenFanpage)…", mau: BangMauBCTD.xanhChuDao)
        DichVuFacebookFanpage.dungChung.kiemTraKetNoi(pageId: page.pageId) { [weak self] kq in
            guard let self else { return }
            switch kq {
            case .success(let tenMoi):
                self.taiDanhSach()
                self.khiThayDoiDanhSach?()
                self.datTrangThai(false, thongDiep: "✅ Kết nối tốt! Fanpage hoạt động: \(tenMoi) (ID: \(page.pageId)).", mau: BangMauBCTD.xanhLaDam)
            case .failure(let loi):
                self.datTrangThai(false, thongDiep: "⚠️ \(loi.localizedDescription)", mau: .systemRed)
            }
        }
    }

    @objc private func bamXoaPage(_ sender: UIButton) {
        guard danhSach.indices.contains(sender.tag) else { return }
        let page = danhSach[sender.tag]
        let tb = UIAlertController(
            title: "Xóa khóa Fanpage?",
            message: "Token của \"\(page.tenFanpage)\" (ID: \(page.pageId)) sẽ bị xóa khỏi Keychain trên máy này.",
            preferredStyle: .alert
        )
        tb.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        tb.addAction(UIAlertAction(title: "Xóa khóa", style: .destructive) { [weak self] _ in
            guard let self else { return }
            KhoKeychainFacebookFanpage.dungChung.xoaFanpage(pageId: page.pageId)
            self.taiDanhSach()
            self.khiThayDoiDanhSach?()
            self.datTrangThai(false, thongDiep: "Đã xóa khóa Fanpage \"\(page.tenFanpage)\" khỏi Keychain.", mau: BangMauBCTD.xanhLaDam)
        })
        present(tb, animated: true)
    }

    @objc private func bamXoaTatCa() {
        let tb = UIAlertController(
            title: "Xóa toàn bộ khóa Facebook?",
            message: "Mọi Page Access Token của tài khoản \"\(KhoKeychainFacebookFanpage.dungChung.tenHienThiTaiKhoanHienTai)\" lưu trong Keychain máy này sẽ bị xóa sạch.",
            preferredStyle: .alert
        )
        tb.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        tb.addAction(UIAlertAction(title: "Xóa toàn bộ", style: .destructive) { [weak self] _ in
            guard let self else { return }
            KhoKeychainFacebookFanpage.dungChung.xoaTatCaCuaTaiKhoanHienTai()
            self.taiDanhSach()
            self.khiThayDoiDanhSach?()
            self.datTrangThai(false, thongDiep: "Đã xóa sạch toàn bộ khóa Facebook của tài khoản này trên máy.", mau: BangMauBCTD.xanhLaDam)
        })
        present(tb, animated: true)
    }

    @objc private func bamHuongDan() {
        let noiDung = """
        1. Tạo Meta App tại developers.facebook.com (loại Business) và chuyển App sang chế độ TRỰC TIẾP (Live Mode) để khách hàng thấy bài đăng.
        2. Cấp đúng các quyền tối thiểu: pages_show_list, pages_read_engagement, pages_manage_posts (thêm publish_video nếu đăng video).
        3. Khuyên dùng System User trong Meta Business Suite → gán đúng Fanpage cần đăng → tạo Token vĩnh viễn → nhập Page ID + dán Token vào đây (app sẽ tự trích riêng Page Access Token và KHÔNG lưu System User Token).
        4. Nếu mất máy hoặc đổi nhân sự, vào Meta Business Suite bấm Thu hồi (Revoke) token đó ngay lập tức.
        """
        let tb = UIAlertController(title: "Hướng dẫn lấy Page Token an toàn", message: noiDung, preferredStyle: .alert)
        tb.addAction(UIAlertAction(title: "Đã hiểu", style: .default))
        present(tb, animated: true)
    }

    // MARK: - Tiện ích tạo UI tuân thủ đầy đủ xuống dòng

    private func taoThe(tieuDe: String) -> (UIView, UIStackView) {
        let the = UIView()
        the.backgroundColor = BangMauBCTD.nenThe
        the.layer.cornerRadius = 14
        the.layer.borderWidth = 1
        the.layer.borderColor = BangMauBCTD.vienThe.cgColor

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 9
        stack.translatesAutoresizingMaskIntoConstraints = false
        the.addSubview(stack)

        let lbl = taoNhan(tieuDe, dam: true)
        lbl.font = .systemFont(ofSize: 15, weight: .bold)
        stack.addArrangedSubview(lbl)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: the.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: the.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: the.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: the.bottomAnchor, constant: -12)
        ])
        return (the, stack)
    }

    private func taoNhan(_ text: String, dam: Bool = false) -> UILabel {
        let l = UILabel()
        l.text = text
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.adjustsFontSizeToFitWidth = false
        l.textColor = BangMauBCTD.chuChinh
        l.font = .systemFont(ofSize: dam ? 13.5 : 12.5, weight: dam ? .bold : .regular)
        return l
    }

    private func cauHinhO(_ o: UITextField, goiY: String, baoMat: Bool) {
        o.placeholder = goiY
        o.font = .systemFont(ofSize: 13.5)
        o.textColor = BangMauBCTD.chuChinh
        o.backgroundColor = BangMauBCTD.nenThePhu
        o.layer.cornerRadius = 9
        o.layer.borderWidth = 1
        o.layer.borderColor = BangMauBCTD.vienDam.cgColor
        o.isSecureTextEntry = baoMat
        o.autocapitalizationType = .none
        o.autocorrectionType = .no
        o.spellCheckingType = .no
        o.smartQuotesType = .no
        o.smartDashesType = .no
        o.clearButtonMode = .whileEditing
        o.heightAnchor.constraint(equalToConstant: 42).isActive = true
        let dem = UIView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(10), height: CGFloat(1)))
        o.leftView = dem
        o.leftViewMode = .always
    }

    private func cauHinhNutChinh(_ b: UIButton, mau: UIColor) {
        b.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        b.titleLabel?.numberOfLines = 0
        b.titleLabel?.lineBreakMode = .byWordWrapping
        b.titleLabel?.adjustsFontSizeToFitWidth = false
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = mau
        b.layer.cornerRadius = 10
        b.contentEdgeInsets = UIEdgeInsets(top: 11, left: 10, bottom: 11, right: 10)
    }

    private func cauHinhNutPhu(_ b: UIButton) {
        b.titleLabel?.font = .systemFont(ofSize: 13.5, weight: .bold)
        b.titleLabel?.numberOfLines = 0
        b.titleLabel?.lineBreakMode = .byWordWrapping
        b.titleLabel?.adjustsFontSizeToFitWidth = false
        b.setTitleColor(BangMauBCTD.xanhChuDao, for: .normal)
        b.backgroundColor = BangMauBCTD.nenThePhu
        b.layer.cornerRadius = 9
        b.layer.borderWidth = 1
        b.layer.borderColor = BangMauBCTD.xanhChuDao.cgColor
        b.contentEdgeInsets = UIEdgeInsets(top: 9, left: 10, bottom: 9, right: 10)
    }
}
