import Foundation
import Security

struct PhienDangNhapDMX: Codable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Int
    var userId: String?
    var tenDangNhap: String
    var laAdmin: Bool?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case userId = "user_id"
        case tenDangNhap = "ten_dang_nhap"
        case laAdmin = "la_admin"
    }
}

struct ThongTinTaiKhoanDMX: Codable, Hashable, Identifiable {
    var id: String
    var tenDangNhap: String
    var email: String
    var laAdmin: Bool
    var ngayTao: String
    var dangNhapCuoi: String

    var laAdminGoc: Bool {
        tenDangNhap.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == DichVuDongBo.taiKhoanAdminGoc
    }
}

private struct LoiMayChu: Codable { var loi: String? }
private struct DangKyThanhCong: Codable { var thanh_cong: Bool? }
private struct DuLieuDamMay: Codable {
    var caiDat: CaiDatDMX?
    var cacNgay: [String: DuLieuNgayDMX]?
}
private struct GoiDongBo: Codable {
    var caiDat: CaiDatDMX?
    var ngay: String?
    var duLieuNgay: DuLieuNgayDMX?
}

// MARK: - Phản hồi từ Supabase Auth & Admin REST API trực tiếp

private struct SupabaseAuthUser: Codable {
    var id: String
    var email: String?
    var userMetadata: [String: String]?
    var createdAt: String?
    var lastSignInAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case userMetadata = "user_metadata"
        case createdAt = "created_at"
        case lastSignInAt = "last_sign_in_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? ""
        email = try? c.decode(String.self, forKey: .email)
        createdAt = try? c.decode(String.self, forKey: .createdAt)
        lastSignInAt = try? c.decode(String.self, forKey: .lastSignInAt)

        if let dictStr = try? c.decode([String: String].self, forKey: .userMetadata) {
            userMetadata = dictStr
        } else if let rawAny = try? c.decode([String: AnyCodableValue].self, forKey: .userMetadata) {
            var map: [String: String] = [:]
            for (k, v) in rawAny {
                map[k] = v.stringValue
            }
            userMetadata = map
        } else {
            userMetadata = nil
        }
    }
}

private struct AnyCodableValue: Codable {
    let stringValue: String

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) {
            stringValue = s
        } else if let b = try? c.decode(Bool.self) {
            stringValue = b ? "true" : "false"
        } else if let i = try? c.decode(Int.self) {
            stringValue = String(i)
        } else if let d = try? c.decode(Double.self) {
            stringValue = String(d)
        } else {
            stringValue = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(stringValue)
    }
}

private struct DanhSachAdminUsersResponse: Codable {
    var users: [SupabaseAuthUser]?
}

private struct SupabaseAuthResponse: Codable {
    var accessToken: String?
    var refreshToken: String?
    var expiresAt: Int?
    var expiresIn: Int?
    var user: SupabaseAuthUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case expiresIn = "expires_in"
        case user
    }
}

private struct SupabaseAuthError: Codable {
    var msg: String?
    var message: String?
    var errorDescription: String?
    var code: String?

    enum CodingKeys: String, CodingKey {
        case msg
        case message
        case errorDescription = "error_description"
        case code
    }
}

private struct DongHoSoSupabase: Codable {
    var nguoi_dung_id: String?
    var ten_dang_nhap: String?
    var cai_dat: CaiDatDMX?
    var ngay_cap_nhat: String?
}

private struct DongDuLieuNgaySupabase: Codable {
    var nguoi_dung_id: String?
    var ngay: String
    var du_lieu: DuLieuNgayDMX
    var ngay_cap_nhat: String?
}

final class DichVuDongBo {
    static let dungChung = DichVuDongBo()
    static let taiKhoanAdminGoc = "duongnt"

    private let diaChiWeb = URL(string: "https://www.duongnt.io.vn")!
    private let diaChiSupabase = URL(string: "https://isxrxeaxytyiydxiwvuc.supabase.co")!
    private let khoaCongKhaiSupabase = "sb_publishable_mafynf1XYupP9W_WeLYSRg_M7cjJXPS"
    private let khoaBiMatSupabase = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlzeHJ4ZWF4eXR5aXlkeGl3dnVjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NDQ1OTY1OCwiZXhwIjoyMTAwMDM1NjU4fQ.V7zW8iMiwuKCHGY-1tG1ociK-aeUXwX0BnhqDf1rTo4"
    private let tenBucket = "dmx-du-lieu"
    private let hauToEmailDmx = "@dmx.internal.duongnt.io.vn"

    private let khoaKeychain = "com.thanhduong.tonghopdmx.phien-dang-nhap"
    private let khoaDaDonDepLocal = "com.thanhduong.tonghopdmx.da-don-dep-tai-khoan-cu-v1"
    private let hangDoi = DispatchQueue(label: "com.thanhduong.tonghopdmx.dongbo")
    private(set) var phien: PhienDangNhapDMX?

    var daDangNhap: Bool { phien != nil }
    var tenDangNhap: String { phien?.tenDangNhap ?? "" }
    var laAdmin: Bool {
        let ten = tenDangNhap.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if ten == Self.taiKhoanAdminGoc { return true }
        return phien?.laAdmin == true
    }

    private init() {
        phien = docKeychain()
        if var p = phien, p.tenDangNhap.lowercased() == Self.taiKhoanAdminGoc, p.laAdmin != true {
            p.laAdmin = true
            phien = p
            luuKeychain(p)
        }
    }

    func taoEmailDmx(_ tenDangNhap: String) -> String {
        let sach = chuanHoaTenDangNhap(tenDangNhap)
        return "\(sach)\(hauToEmailDmx)"
    }

    func chuanHoaTenDangNhap(_ tenDangNhap: String) -> String {
        tenDangNhap
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "D")
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "[^a-z0-9._-]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private func trichTenDangNhap(tu user: SupabaseAuthUser) -> String {
        if let tenMeta = user.userMetadata?["ten_dang_nhap"]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
           !tenMeta.isEmpty {
            return tenMeta
        }
        if let email = user.email?.lowercased(), email.hasSuffix(hauToEmailDmx) {
            return String(email.dropLast(hauToEmailDmx.count))
        }
        return user.email ?? ""
    }

    private func laUserThuocDMX(_ user: SupabaseAuthUser) -> Bool {
        if user.userMetadata?["ung_dung"] == "dmx" { return true }
        if let email = user.email?.lowercased(), email.hasSuffix(hauToEmailDmx) { return true }
        return false
    }

    private func xacDinhLaAdmin(user: SupabaseAuthUser, tenDangNhap: String) -> Bool {
        if tenDangNhap.lowercased() == Self.taiKhoanAdminGoc { return true }
        let raw = (user.userMetadata?["la_admin"] ?? user.userMetadata?["vai_tro"] ?? "").lowercased()
        return raw == "true" || raw == "1" || raw == "admin"
    }

    // MARK: - 1. Đăng nhập (Tự động set quyền Admin cho duongnt & kiểm tra tài khoản hợp lệ)

    func dangNhap(tenDangNhap: String, matKhau: String, hoanTat: @escaping (Result<Void, Error>) -> Void) {
        let tenChuan = chuanHoaTenDangNhap(tenDangNhap)
        let email = taoEmailDmx(tenChuan)
        let body: [String: String] = ["email": email, "password": matKhau]

        guiSupabaseAuth(query: "grant_type=password", body: body) { [weak self] kq in
            guard let self else { return }
            switch kq {
            case .success(let authRes):
                guard let token = authRes.accessToken,
                      let refresh = authRes.refreshToken else {
                    hoanTat(.failure(NSError.dmx("Tên đăng nhập hoặc mật khẩu chưa đúng.")))
                    return
                }
                let ungDung = authRes.user?.userMetadata?["ung_dung"] ?? "dmx"
                guard ungDung == "dmx" else {
                    hoanTat(.failure(NSError.dmx("Tài khoản này không thuộc ứng dụng ĐMX.")))
                    return
                }
                let exp = authRes.expiresAt ?? (Int(Date().timeIntervalSince1970) + (authRes.expiresIn ?? 3600))
                let tenHienThi = (authRes.user?.userMetadata?["ten_dang_nhap"] ?? tenChuan).lowercased()
                let quyenAdmin = (tenHienThi == Self.taiKhoanAdminGoc) ||
                    (authRes.user.map { self.xacDinhLaAdmin(user: $0, tenDangNhap: tenHienThi) } ?? false)

                let phienMoi = PhienDangNhapDMX(
                    accessToken: token,
                    refreshToken: refresh,
                    expiresAt: exp,
                    userId: authRes.user?.id,
                    tenDangNhap: tenHienThi,
                    laAdmin: quyenAdmin
                )
                self.phien = phienMoi
                self.luuKeychain(phienMoi)

                if tenHienThi == Self.taiKhoanAdminGoc, let uid = authRes.user?.id, !uid.isEmpty {
                    self.damBaoMetadataAdminChoDuongnt(userId: uid, metadataHienTai: authRes.user?.userMetadata)
                }
                self.thucHienKhoiTaoAdminVaXoaTaiKhoanCuNeuCan()
                hoanTat(.success(()))

            case .failure(let loi):
                // Nếu tài khoản đăng nhập là duongnt và chưa từng được tạo trên Supabase Auth thì tự khởi tạo tài khoản Admin gốc duongnt
                if tenChuan == Self.taiKhoanAdminGoc {
                    self.kiemTraVaKhoiTaoDuongntNeuChuaCo(matKhau: matKhau, loiGoc: loi, hoanTat: hoanTat)
                    return
                }
                hoanTat(.failure(loi))
            }
        }
    }

    private func kiemTraVaKhoiTaoDuongntNeuChuaCo(
        matKhau: String,
        loiGoc: Error,
        hoanTat: @escaping (Result<Void, Error>) -> Void
    ) {
        layDanhSachUsersSupabaseAdmin { [weak self] kq in
            guard let self else { return }
            switch kq {
            case .success(let users):
                let daCoDuongnt = users.contains {
                    self.trichTenDangNhap(tu: $0).lowercased() == Self.taiKhoanAdminGoc
                }
                if daCoDuongnt {
                    // Tài khoản duongnt đã có trên hệ thống -> mật khẩu nhập chưa đúng
                    DispatchQueue.main.async { hoanTat(.failure(loiGoc)) }
                } else {
                    // Chưa có tài khoản duongnt -> tạo mới làm Admin gốc rồi đăng nhập
                    self.adminTaoTaiKhoanMoi(tenDangNhap: Self.taiKhoanAdminGoc, matKhau: matKhau, laAdmin: true) { kqTao in
                        switch kqTao {
                        case .success:
                            self.dangNhap(tenDangNhap: Self.taiKhoanAdminGoc, matKhau: matKhau, hoanTat: hoanTat)
                        case .failure:
                            DispatchQueue.main.async { hoanTat(.failure(loiGoc)) }
                        }
                    }
                }
            case .failure:
                DispatchQueue.main.async { hoanTat(.failure(loiGoc)) }
            }
        }
    }

    // MARK: - 2. Đăng ký tài khoản mới

    func dangKy(tenDangNhap: String, matKhau: String, hoanTat: @escaping (Result<Void, Error>) -> Void) {
        let tenChuan = chuanHoaTenDangNhap(tenDangNhap)
        let laAdminGoc = (tenChuan == Self.taiKhoanAdminGoc)
        adminTaoTaiKhoanMoi(tenDangNhap: tenChuan, matKhau: matKhau, laAdmin: laAdminGoc) { [weak self] kq in
            switch kq {
            case .success:
                self?.dangNhap(tenDangNhap: tenChuan, matKhau: matKhau, hoanTat: hoanTat)
            case .failure(let loi):
                hoanTat(.failure(loi))
            }
        }
    }

    func dangXuat() {
        phien = nil
        xoaKeychain()
        KhoDuLieu.dungChung.datLaiSauDangXuat()
    }

    // MARK: - 3. Quản lý Tài khoản & Phân quyền Admin (Thêm mới, Đổi mật khẩu, Set quyền Admin, Xoá toàn bộ tài khoản khác trừ duongnt)

    /// Tự động chạy 1 lần duy nhất để set `duongnt` làm Admin gốc và xoá toàn bộ các tài khoản cũ đã đăng nhập vào dự án (giữ nguyên `duongnt`).
    /// Đồng thời kiểm tra nếu thiết bị hiện tại đang đăng nhập vào tài khoản đã bị xoá thì tự động đăng xuất ngay.
    func thucHienKhoiTaoAdminVaXoaTaiKhoanCuNeuCan(hoanTat: (() -> Void)? = nil) {
        layDanhSachUsersSupabaseAdmin { [weak self] kq in
            guard let self else { hoanTat?(); return }
            guard case .success(let tatCaUsers) = kq else {
                hoanTat?()
                return
            }

            let dmxUsers = tatCaUsers.filter { self.laUserThuocDMX($0) }
            let userDuongnt = dmxUsers.first {
                self.trichTenDangNhap(tu: $0).lowercased() == Self.taiKhoanAdminGoc
            }

            // Đảm bảo duongnt luôn có quyền Admin trên Supabase
            if let duongnt = userDuongnt {
                let daLaAdmin = self.xacDinhLaAdmin(user: duongnt, tenDangNhap: Self.taiKhoanAdminGoc)
                if !daLaAdmin || duongnt.userMetadata?["la_admin"] != "true" {
                    self.damBaoMetadataAdminChoDuongnt(userId: duongnt.id, metadataHienTai: duongnt.userMetadata)
                }
            }

            let daDonDepTrenCloud = (userDuongnt?.userMetadata?["da_don_dep_tai_khoan_v1"] == "true")
            let daDonDepLocal = UserDefaults.standard.bool(forKey: self.khoaDaDonDepLocal)

            if !daDonDepTrenCloud && !daDonDepLocal {
                UserDefaults.standard.set(true, forKey: self.khoaDaDonDepLocal)
                self.adminXoaTatCaTaiKhoanKhacGiuDuongnt { [weak self] _ in
                    guard let self else { hoanTat?(); return }
                    if self.daDangNhap && self.tenDangNhap.lowercased() != Self.taiKhoanAdminGoc {
                        DispatchQueue.main.async {
                            self.dangXuat()
                            NotificationCenter.default.post(name: .taiKhoanDMXBiDangXuat, object: nil)
                        }
                    }
                    hoanTat?()
                }
                return
            }

            // Kiểm tra tài khoản đang đăng nhập trên máy còn tồn tại trên hệ thống không
            if self.daDangNhap {
                let tenHienTai = self.tenDangNhap.lowercased()
                let conTonTai = dmxUsers.contains {
                    self.trichTenDangNhap(tu: $0).lowercased() == tenHienTai
                }
                if !conTonTai && tenHienTai != Self.taiKhoanAdminGoc {
                    DispatchQueue.main.async {
                        self.dangXuat()
                        NotificationCenter.default.post(name: .taiKhoanDMXBiDangXuat, object: nil)
                        hoanTat?()
                    }
                    return
                }
                // Cập nhật lại cờ laAdmin mới nhất từ server cho phiên hiện tại
                if let uHienTai = dmxUsers.first(where: { self.trichTenDangNhap(tu: $0).lowercased() == tenHienTai }),
                   var p = self.phien {
                    let quyenMoi = self.xacDinhLaAdmin(user: uHienTai, tenDangNhap: tenHienTai)
                    if p.laAdmin != quyenMoi || p.userId != uHienTai.id {
                        p.laAdmin = quyenMoi
                        p.userId = uHienTai.id
                        self.phien = p
                        self.luuKeychain(p)
                    }
                }
            }
            hoanTat?()
        }
    }

    private func damBaoMetadataAdminChoDuongnt(userId: String, metadataHienTai: [String: String]?) {
        var meta = metadataHienTai ?? [:]
        meta["ung_dung"] = "dmx"
        meta["ten_dang_nhap"] = Self.taiKhoanAdminGoc
        meta["la_admin"] = "true"
        meta["vai_tro"] = "admin"
        meta["da_don_dep_tai_khoan_v1"] = "true"
        capNhatUserSupabaseAdmin(userId: userId, matKhauMoi: nil, userMetadata: meta) { _ in }
    }

    /// Lấy danh sách toàn bộ các tài khoản ĐMX trong dự án
    func layDanhSachTaiKhoan(hoanTat: @escaping (Result<[ThongTinTaiKhoanDMX], Error>) -> Void) {
        layDanhSachUsersSupabaseAdmin { [weak self] kq in
            guard let self else { return }
            switch kq {
            case .success(let users):
                var ds: [ThongTinTaiKhoanDMX] = []
                for u in users where self.laUserThuocDMX(u) {
                    let ten = self.trichTenDangNhap(tu: u)
                    guard !ten.isEmpty else { continue }
                    let isAdm = self.xacDinhLaAdmin(user: u, tenDangNhap: ten)
                    if ten.lowercased() == Self.taiKhoanAdminGoc && u.userMetadata?["la_admin"] != "true" {
                        self.damBaoMetadataAdminChoDuongnt(userId: u.id, metadataHienTai: u.userMetadata)
                    }
                    ds.append(ThongTinTaiKhoanDMX(
                        id: u.id,
                        tenDangNhap: ten,
                        email: u.email ?? self.taoEmailDmx(ten),
                        laAdmin: isAdm,
                        ngayTao: self.dinhDangNgayISO(u.createdAt),
                        dangNhapCuoi: self.dinhDangNgayISO(u.lastSignInAt)
                    ))
                }
                ds.sort { a, b in
                    if a.laAdminGoc != b.laAdminGoc { return a.laAdminGoc }
                    if a.laAdmin != b.laAdmin { return a.laAdmin }
                    return a.tenDangNhap.localizedCaseInsensitiveCompare(b.tenDangNhap) == .orderedAscending
                }
                DispatchQueue.main.async { hoanTat(.success(ds)) }
            case .failure(let loi):
                DispatchQueue.main.async { hoanTat(.failure(loi)) }
            }
        }
    }

    /// Admin thêm tài khoản mới (có thể chọn làm tài khoản thường hoặc cấp quyền Admin) mà không làm đăng xuất phiên Admin hiện tại
    func adminTaoTaiKhoanMoi(
        tenDangNhap: String,
        matKhau: String,
        laAdmin: Bool,
        hoanTat: @escaping (Result<ThongTinTaiKhoanDMX, Error>) -> Void
    ) {
        let tenChuan = chuanHoaTenDangNhap(tenDangNhap)
        guard tenChuan.range(of: "^[a-z0-9][a-z0-9._-]{2,39}$", options: .regularExpression) != nil else {
            hoanTat(.failure(NSError.dmx("Tên đăng nhập gồm 3–40 ký tự: chữ thường, số, dấu chấm, gạch ngang hoặc gạch dưới.")))
            return
        }
        guard matKhau.count >= 6 else {
            hoanTat(.failure(NSError.dmx("Mật khẩu cần có ít nhất 6 ký tự.")))
            return
        }

        let email = taoEmailDmx(tenChuan)
        let quyenAdmin = (tenChuan == Self.taiKhoanAdminGoc) ? true : laAdmin

        struct GoiAdminTaoUser: Encodable {
            let email: String
            let password: String
            let email_confirm: Bool
            let user_metadata: [String: String]
        }

        var meta: [String: String] = [
            "ung_dung": "dmx",
            "ten_dang_nhap": tenChuan,
            "la_admin": quyenAdmin ? "true" : "false",
            "vai_tro": quyenAdmin ? "admin" : "user"
        ]
        if tenChuan == Self.taiKhoanAdminGoc {
            meta["da_don_dep_tai_khoan_v1"] = "true"
        }

        let payload = GoiAdminTaoUser(
            email: email,
            password: matKhau,
            email_confirm: true,
            user_metadata: meta
        )

        var req = URLRequest(url: diaChiSupabase.appendingPathComponent("/auth/v1/admin/users"))
        req.httpMethod = "POST"
        req.timeoutInterval = 25
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(khoaBiMatSupabase, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(khoaBiMatSupabase)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONEncoder().encode(payload)

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            guard let self else { return }
            if let error {
                DispatchQueue.main.async { hoanTat(.failure(error)) }
                return
            }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let duLieu = data ?? Data()
            guard (200..<300).contains(status) else {
                let errObj = try? JSONDecoder().decode(SupabaseAuthError.self, from: duLieu)
                let msg = errObj?.msg ?? errObj?.message ?? errObj?.errorDescription ?? ""
                let laTrung = status == 422 || status == 409 || msg.localizedCaseInsensitiveContains("already") || msg.localizedCaseInsensitiveContains("registered")
                let thongBao = laTrung ? "Tên đăng nhập \"\(tenChuan)\" đã tồn tại." : (msg.isEmpty ? "Chưa tạo được tài khoản mới." : msg)
                DispatchQueue.main.async { hoanTat(.failure(NSError.dmx(thongBao))) }
                return
            }

            let u = try? JSONDecoder().decode(SupabaseAuthUser.self, from: duLieu)
            let tk = ThongTinTaiKhoanDMX(
                id: u?.id ?? UUID().uuidString.lowercased(),
                tenDangNhap: tenChuan,
                email: email,
                laAdmin: quyenAdmin,
                ngayTao: self.dinhDangNgayISO(u?.createdAt),
                dangNhapCuoi: "--"
            )
            DispatchQueue.main.async { hoanTat(.success(tk)) }
        }.resume()
    }

    /// Admin đổi mật khẩu cho bất kỳ tài khoản nào trong hệ thống
    func adminDoiMatKhau(
        userId: String,
        tenDangNhap: String,
        matKhauMoi: String,
        hoanTat: @escaping (Result<Void, Error>) -> Void
    ) {
        guard matKhauMoi.count >= 6 else {
            hoanTat(.failure(NSError.dmx("Mật khẩu mới cần có ít nhất 6 ký tự.")))
            return
        }
        capNhatUserSupabaseAdmin(userId: userId, matKhauMoi: matKhauMoi, userMetadata: nil, hoanTat: hoanTat)
    }

    /// Đổi mật khẩu cho chính tài khoản đang đăng nhập
    func doiMatKhauCaNhan(matKhauMoi: String, hoanTat: @escaping (Result<Void, Error>) -> Void) {
        guard matKhauMoi.count >= 6 else {
            hoanTat(.failure(NSError.dmx("Mật khẩu mới cần có ít nhất 6 ký tự.")))
            return
        }
        damBaoUserId { [weak self] uid in
            guard let self, let uid, !uid.isEmpty else {
                DispatchQueue.main.async {
                    hoanTat(.failure(NSError.dmx("Không xác định được phiên tài khoản hiện tại.")))
                }
                return
            }
            self.capNhatUserSupabaseAdmin(userId: uid, matKhauMoi: matKhauMoi, userMetadata: nil, hoanTat: hoanTat)
        }
    }

    /// Admin cấp hoặc gỡ quyền Admin cho tài khoản thường (Riêng tài khoản `duongnt` luôn giữ quyền Admin gốc)
    func adminDatQuyenAdmin(
        taiKhoan: ThongTinTaiKhoanDMX,
        laAdmin: Bool,
        hoanTat: @escaping (Result<Void, Error>) -> Void
    ) {
        if taiKhoan.laAdminGoc && !laAdmin {
            hoanTat(.failure(NSError.dmx("Tài khoản \"\(Self.taiKhoanAdminGoc)\" là Admin gốc của dự án, không thể gỡ quyền Admin.")))
            return
        }
        let quyenMoi = taiKhoan.laAdminGoc ? true : laAdmin
        var meta: [String: String] = [
            "ung_dung": "dmx",
            "ten_dang_nhap": taiKhoan.tenDangNhap.lowercased(),
            "la_admin": quyenMoi ? "true" : "false",
            "vai_tro": quyenMoi ? "admin" : "user"
        ]
        if taiKhoan.laAdminGoc {
            meta["da_don_dep_tai_khoan_v1"] = "true"
        }
        capNhatUserSupabaseAdmin(userId: taiKhoan.id, matKhauMoi: nil, userMetadata: meta) { [weak self] kq in
            guard let self else { return }
            if case .success = kq,
               var p = self.phien,
               p.tenDangNhap.lowercased() == taiKhoan.tenDangNhap.lowercased() {
                p.laAdmin = quyenMoi
                self.phien = p
                self.luuKeychain(p)
            }
            hoanTat(kq)
        }
    }

    /// Admin xoá 1 tài khoản cụ thể (Bảo vệ tuyệt đối tài khoản `duongnt`)
    func adminXoaTaiKhoan(
        taiKhoan: ThongTinTaiKhoanDMX,
        hoanTat: @escaping (Result<Void, Error>) -> Void
    ) {
        if taiKhoan.laAdminGoc {
            hoanTat(.failure(NSError.dmx("Không thể xoá tài khoản Admin gốc \"\(Self.taiKhoanAdminGoc)\".")))
            return
        }
        xoaUserVaDuLieuTrenSupabase(userId: taiKhoan.id) { kq in
            DispatchQueue.main.async { hoanTat(kq) }
        }
    }

    /// Xoá TẤT CẢ các tài khoản hiện tại trong dự án, chỉ giữ lại duy nhất tài khoản Admin gốc `duongnt`
    func adminXoaTatCaTaiKhoanKhacGiuDuongnt(hoanTat: @escaping (Result<Int, Error>) -> Void) {
        layDanhSachUsersSupabaseAdmin { [weak self] kq in
            guard let self else { return }
            switch kq {
            case .success(let tatCaUsers):
                let dmxUsers = tatCaUsers.filter { self.laUserThuocDMX($0) }
                if let duongnt = dmxUsers.first(where: { self.trichTenDangNhap(tu: $0).lowercased() == Self.taiKhoanAdminGoc }) {
                    self.damBaoMetadataAdminChoDuongnt(userId: duongnt.id, metadataHienTai: duongnt.userMetadata)
                }

                let cacUserCanXoa = dmxUsers.filter {
                    self.trichTenDangNhap(tu: $0).lowercased() != Self.taiKhoanAdminGoc
                }

                // Xoá thêm các dòng hồ sơ mồ côi trong bảng dmx_ho_so khác duongnt
                self.xoaHoSoSQLKhacDuongnt()

                guard !cacUserCanXoa.isEmpty else {
                    DispatchQueue.main.async { hoanTat(.success(0)) }
                    return
                }

                let nhom = DispatchGroup()
                let khoaDem = NSLock()
                var soDaXoa = 0

                for u in cacUserCanXoa {
                    nhom.enter()
                    self.xoaUserVaDuLieuTrenSupabase(userId: u.id) { kqXoa in
                        if case .success = kqXoa {
                            khoaDem.lock()
                            soDaXoa += 1
                            khoaDem.unlock()
                        }
                        nhom.leave()
                    }
                }

                nhom.notify(queue: .main) {
                    if self.daDangNhap && self.tenDangNhap.lowercased() != Self.taiKhoanAdminGoc {
                        self.dangXuat()
                        NotificationCenter.default.post(name: .taiKhoanDMXBiDangXuat, object: nil)
                    }
                    hoanTat(.success(soDaXoa))
                }

            case .failure(let loi):
                DispatchQueue.main.async { hoanTat(.failure(loi)) }
            }
        }
    }

    private func layDanhSachUsersSupabaseAdmin(hoanTat: @escaping (Result<[SupabaseAuthUser], Error>) -> Void) {
        var comps = URLComponents(url: diaChiSupabase.appendingPathComponent("/auth/v1/admin/users"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "per_page", value: "1000")
        ]
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "GET"
        req.timeoutInterval = 25
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.setValue(khoaBiMatSupabase, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(khoaBiMatSupabase)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error {
                hoanTat(.failure(error))
                return
            }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(status), let data else {
                hoanTat(.failure(NSError.dmx("Không tải được danh sách tài khoản từ máy chủ.")))
                return
            }
            if let wrapped = try? JSONDecoder().decode(DanhSachAdminUsersResponse.self, from: data),
               let users = wrapped.users {
                hoanTat(.success(users))
            } else if let arr = try? JSONDecoder().decode([SupabaseAuthUser].self, from: data) {
                hoanTat(.success(arr))
            } else {
                hoanTat(.success([]))
            }
        }.resume()
    }

    private func capNhatUserSupabaseAdmin(
        userId: String,
        matKhauMoi: String?,
        userMetadata: [String: String]?,
        hoanTat: @escaping (Result<Void, Error>) -> Void
    ) {
        var bodyDict: [String: Any] = ["email_confirm": true]
        if let mk = matKhauMoi, !mk.isEmpty {
            bodyDict["password"] = mk
        }
        if let meta = userMetadata {
            bodyDict["user_metadata"] = meta
        }

        let url = diaChiSupabase.appendingPathComponent("/auth/v1/admin/users/\(userId)")
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.timeoutInterval = 25
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(khoaBiMatSupabase, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(khoaBiMatSupabase)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: bodyDict)

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error {
                DispatchQueue.main.async { hoanTat(.failure(error)) }
                return
            }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(status) else {
                let duLieu = data ?? Data()
                let errObj = try? JSONDecoder().decode(SupabaseAuthError.self, from: duLieu)
                let msg = errObj?.msg ?? errObj?.message ?? errObj?.errorDescription ?? "Không cập nhật được tài khoản."
                DispatchQueue.main.async { hoanTat(.failure(NSError.dmx(msg))) }
                return
            }
            DispatchQueue.main.async { hoanTat(.success(())) }
        }.resume()
    }

    private func xoaUserVaDuLieuTrenSupabase(userId: String, hoanTat: @escaping (Result<Void, Error>) -> Void) {
        let nhom = DispatchGroup()

        // 1. Xoá dữ liệu bảng dmx_du_lieu_ngay của user
        nhom.enter()
        var compNgay = URLComponents(url: diaChiSupabase.appendingPathComponent("/rest/v1/dmx_du_lieu_ngay"), resolvingAgainstBaseURL: false)!
        compNgay.queryItems = [URLQueryItem(name: "nguoi_dung_id", value: "eq.\(userId)")]
        var reqNgay = URLRequest(url: compNgay.url!)
        reqNgay.httpMethod = "DELETE"
        reqNgay.setValue(khoaBiMatSupabase, forHTTPHeaderField: "apikey")
        reqNgay.setValue("Bearer \(khoaBiMatSupabase)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: reqNgay) { _, _, _ in nhom.leave() }.resume()

        // 2. Xoá hồ sơ bảng dmx_ho_so của user
        nhom.enter()
        var compHoSo = URLComponents(url: diaChiSupabase.appendingPathComponent("/rest/v1/dmx_ho_so"), resolvingAgainstBaseURL: false)!
        compHoSo.queryItems = [URLQueryItem(name: "nguoi_dung_id", value: "eq.\(userId)")]
        var reqHoSo = URLRequest(url: compHoSo.url!)
        reqHoSo.httpMethod = "DELETE"
        reqHoSo.setValue(khoaBiMatSupabase, forHTTPHeaderField: "apikey")
        reqHoSo.setValue("Bearer \(khoaBiMatSupabase)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: reqHoSo) { _, _, _ in nhom.leave() }.resume()

        // 3. Xoá file JSON trong Supabase Storage dmx-du-lieu/{userId}.json
        nhom.enter()
        let urlStorage = diaChiSupabase.appendingPathComponent("/storage/v1/object/\(tenBucket)/\(userId).json")
        var reqStorage = URLRequest(url: urlStorage)
        reqStorage.httpMethod = "DELETE"
        reqStorage.setValue(khoaBiMatSupabase, forHTTPHeaderField: "apikey")
        reqStorage.setValue("Bearer \(khoaBiMatSupabase)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: reqStorage) { _, _, _ in nhom.leave() }.resume()

        // 4. Xoá tài khoản khỏi Supabase Auth (vô hiệu hoá ngay lập tức mọi phiên đăng nhập của tài khoản này)
        var xoaAuthThanhCong = false
        nhom.enter()
        let urlAuth = diaChiSupabase.appendingPathComponent("/auth/v1/admin/users/\(userId)")
        var reqAuth = URLRequest(url: urlAuth)
        reqAuth.httpMethod = "DELETE"
        reqAuth.timeoutInterval = 25
        reqAuth.setValue(khoaBiMatSupabase, forHTTPHeaderField: "apikey")
        reqAuth.setValue("Bearer \(khoaBiMatSupabase)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: reqAuth) { _, response, _ in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            xoaAuthThanhCong = (200..<300).contains(status) || status == 404
            nhom.leave()
        }.resume()

        nhom.notify(queue: .global()) {
            if xoaAuthThanhCong {
                hoanTat(.success(()))
            } else {
                hoanTat(.failure(NSError.dmx("Chưa xoá được tài khoản trên máy chủ.")))
            }
        }
    }

    private func xoaHoSoSQLKhacDuongnt() {
        var comp = URLComponents(url: diaChiSupabase.appendingPathComponent("/rest/v1/dmx_ho_so"), resolvingAgainstBaseURL: false)!
        comp.queryItems = [URLQueryItem(name: "ten_dang_nhap", value: "neq.\(Self.taiKhoanAdminGoc)")]
        var req = URLRequest(url: comp.url!)
        req.httpMethod = "DELETE"
        req.setValue(khoaBiMatSupabase, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(khoaBiMatSupabase)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: req) { _, _, _ in }.resume()
    }

    private func dinhDangNgayISO(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "--" }
        let prefix = String(raw.prefix(10))
        let parts = prefix.split(separator: "-")
        if parts.count == 3 {
            return "\(parts[2])/\(parts[1])/\(parts[0])"
        }
        return prefix
    }

    // MARK: - 4. Tải dữ liệu đồng bộ (Kết hợp kiểm tra tài khoản hợp lệ + Supabase Storage + Bảng SQL + Web API)

    func taiDuLieu(hoanTat: ((Result<Void, Error>) -> Void)? = nil) {
        thucHienKhoiTaoAdminVaXoaTaiKhoanCuNeuCan { [weak self] in
            guard let self else { return }
            guard self.daDangNhap else { hoanTat?(.success(())); return }

            self.damBaoUserId { [weak self] userId in
                guard let self else { return }
                guard self.daDangNhap else { hoanTat?(.success(())); return }

                let nhom = DispatchGroup()
                let khoaGop = NSLock()
                var caiDatGop: CaiDatDMX?
                var cacNgayGop: [String: DuLieuNgayDMX] = [:]

                func gopAnToan(caiDat: CaiDatDMX?, cacNgay: [String: DuLieuNgayDMX]?) {
                    khoaGop.lock()
                    defer { khoaGop.unlock() }
                    if let cd = caiDat { caiDatGop = cd }
                    if let ngay = cacNgay {
                        for (k, v) in ngay {
                            if var cu = cacNgayGop[k] {
                                if cu.danhSachThiDua.isEmpty && !v.danhSachThiDua.isEmpty {
                                    cu.danhSachThiDua = v.danhSachThiDua
                                }
                                if cu.danhSachThiDuaRealtime.isEmpty && !v.danhSachThiDuaRealtime.isEmpty {
                                    cu.danhSachThiDuaRealtime = v.danhSachThiDuaRealtime
                                }
                                if !v.danhSachThiDua.isEmpty && !v.danhSachThiDuaRealtime.isEmpty {
                                    cu = v
                                } else {
                                    var moi = v
                                    if moi.danhSachThiDua.isEmpty { moi.danhSachThiDua = cu.danhSachThiDua }
                                    if moi.danhSachThiDuaRealtime.isEmpty { moi.danhSachThiDuaRealtime = cu.danhSachThiDuaRealtime }
                                    cu = moi
                                }
                                cacNgayGop[k] = cu
                            } else {
                                cacNgayGop[k] = v
                            }
                        }
                    }
                }

                if let uid = userId, !uid.isEmpty {
                    nhom.enter()
                    self.docFileStorageSupabase(userId: uid) { cloud in
                        gopAnToan(caiDat: cloud?.caiDat, cacNgay: cloud?.cacNgay)
                        nhom.leave()
                    }

                    nhom.enter()
                    self.docBangSQLSupabase(userId: uid) { cdSQL, ngaySQL in
                        gopAnToan(caiDat: cdSQL, cacNgay: ngaySQL)
                        nhom.leave()
                    }
                }

                nhom.enter()
                self.guiWeb(path: "/api/dmx/dong-bo", method: "GET", bodyData: nil, canDangNhap: true) { (kq: Result<DuLieuDamMay, Error>) in
                    if case .success(let cloud) = kq {
                        gopAnToan(caiDat: cloud.caiDat, cacNgay: cloud.cacNgay)
                    }
                    nhom.leave()
                }

                nhom.notify(queue: .main) {
                    khoaGop.lock()
                    let cdCuoi = caiDatGop
                    let ngayCuoi = cacNgayGop
                    khoaGop.unlock()
                    if cdCuoi != nil || !ngayCuoi.isEmpty {
                        KhoDuLieu.dungChung.nhapDuLieuDamMay(caiDat: cdCuoi, cacNgay: ngayCuoi)
                        NotificationCenter.default.post(name: .duLieuDMXDaDongBo, object: nil)
                    }
                    hoanTat?(.success(()))
                }
            }
        }
    }

    // MARK: - 5. Đẩy dữ liệu ngày & cài đặt lên đám mây

    func dayDuLieuNgay(_ duLieu: DuLieuNgayDMX) {
        day(GoiDongBo(caiDat: nil, ngay: duLieu.khoaNgay, duLieuNgay: duLieu))
    }

    func dayCaiDat(_ caiDat: CaiDatDMX) {
        day(GoiDongBo(caiDat: caiDat, ngay: nil, duLieuNgay: nil))
    }

    private func day(_ goi: GoiDongBo) {
        guard daDangNhap else { return }
        hangDoi.async { [weak self] in
            guard let self else { return }
            self.guiWeb(path: "/api/dmx/dong-bo", method: "POST", body: goi, canDangNhap: true) { (_: Result<LoiMayChu, Error>) in }

            self.damBaoUserId { [weak self] userId in
                guard let self, let uid = userId, !uid.isEmpty else { return }
                self.ghiStorageSupabase(userId: uid, goi: goi)
                self.ghiBangSQLSupabase(userId: uid, goi: goi)
            }
        }
    }

    // MARK: - Các hàm làm việc trực tiếp với Supabase Auth, Storage & PostgREST

    private func guiSupabaseAuth(
        query: String,
        body: [String: String],
        hoanTat: @escaping (Result<SupabaseAuthResponse, Error>) -> Void
    ) {
        var comps = URLComponents(url: diaChiSupabase.appendingPathComponent("/auth/v1/token"), resolvingAgainstBaseURL: false)!
        comps.query = query
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "POST"
        req.timeoutInterval = 25
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(khoaCongKhaiSupabase, forHTTPHeaderField: "apikey")
        req.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error {
                DispatchQueue.main.async { hoanTat(.failure(error)) }
                return
            }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let duLieu = data ?? Data()
            guard (200..<300).contains(status) else {
                let errObj = try? JSONDecoder().decode(SupabaseAuthError.self, from: duLieu)
                let rawMsg = errObj?.msg ?? errObj?.message ?? errObj?.errorDescription ?? ""
                let thongBao: String
                if rawMsg.localizedCaseInsensitiveContains("invalid login credentials") || status == 400 {
                    thongBao = "Tên đăng nhập hoặc mật khẩu chưa đúng."
                } else {
                    thongBao = rawMsg.isEmpty ? "Không thể xác thực tài khoản." : rawMsg
                }
                DispatchQueue.main.async { hoanTat(.failure(NSError.dmx(thongBao))) }
                return
            }
            do {
                let decoded = try JSONDecoder().decode(SupabaseAuthResponse.self, from: duLieu)
                DispatchQueue.main.async { hoanTat(.success(decoded)) }
            } catch {
                DispatchQueue.main.async { hoanTat(.failure(error)) }
            }
        }.resume()
    }

    private func damBaoUserId(hoanTat: @escaping (String?) -> Void) {
        let bayGio = Int(Date().timeIntervalSince1970)
        if let exp = phien?.expiresAt, exp > 0, exp <= bayGio + 60 {
            lamMoiPhien { [weak self] _ in
                guard let self else { hoanTat(nil); return }
                if let uid = self.phien?.userId, !uid.isEmpty {
                    hoanTat(uid)
                } else {
                    self.truyVanUserIdTuSupabase(hoanTat: hoanTat)
                }
            }
            return
        }
        if let uid = phien?.userId, !uid.isEmpty {
            hoanTat(uid)
            return
        }
        truyVanUserIdTuSupabase(hoanTat: hoanTat)
    }

    private func truyVanUserIdTuSupabase(hoanTat: @escaping (String?) -> Void) {
        guard let token = phien?.accessToken else {
            hoanTat(nil)
            return
        }
        var req = URLRequest(url: diaChiSupabase.appendingPathComponent("/auth/v1/user"))
        req.httpMethod = "GET"
        req.timeoutInterval = 15
        req.setValue(khoaCongKhaiSupabase, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: req) { [weak self] data, response, _ in
            guard let self else { hoanTat(nil); return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if status == 401 || status == 403 || status == 404 {
                self.lamMoiPhien { ok in
                    if !ok {
                        DispatchQueue.main.async {
                            self.dangXuat()
                            NotificationCenter.default.post(name: .taiKhoanDMXBiDangXuat, object: nil)
                        }
                    }
                    hoanTat(ok ? self.phien?.userId : nil)
                }
                return
            }
            if let data, let u = try? JSONDecoder().decode(SupabaseAuthUser.self, from: data), !u.id.isEmpty {
                if var p = self.phien {
                    p.userId = u.id
                    p.laAdmin = self.xacDinhLaAdmin(user: u, tenDangNhap: p.tenDangNhap)
                    self.phien = p
                    self.luuKeychain(p)
                }
                hoanTat(u.id)
            } else {
                hoanTat(nil)
            }
        }.resume()
    }

    private func docFileStorageSupabase(userId: String, hoanTat: @escaping (DuLieuDamMay?) -> Void) {
        let url = diaChiSupabase.appendingPathComponent("/storage/v1/object/\(tenBucket)/\(userId).json")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 20
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.setValue(khoaBiMatSupabase, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(khoaBiMatSupabase)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: req) { data, response, _ in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(status), let data else {
                hoanTat(nil)
                return
            }
            let cloud = try? JSONDecoder().decode(DuLieuDamMay.self, from: data)
            hoanTat(cloud)
        }.resume()
    }

    private func ghiStorageSupabase(userId: String, goi: GoiDongBo) {
        let payload = DuLieuDamMay(
            caiDat: goi.caiDat ?? KhoDuLieu.dungChung.caiDat,
            cacNgay: KhoDuLieu.dungChung.cacNgay
        )
        guard let body = try? JSONEncoder().encode(payload) else { return }

        var reqBucket = URLRequest(url: diaChiSupabase.appendingPathComponent("/storage/v1/bucket"))
        reqBucket.httpMethod = "POST"
        reqBucket.setValue("application/json", forHTTPHeaderField: "Content-Type")
        reqBucket.setValue(khoaBiMatSupabase, forHTTPHeaderField: "apikey")
        reqBucket.setValue("Bearer \(khoaBiMatSupabase)", forHTTPHeaderField: "Authorization")
        reqBucket.httpBody = try? JSONSerialization.data(withJSONObject: ["id": tenBucket, "name": tenBucket, "public": false])
        URLSession.shared.dataTask(with: reqBucket) { _, _, _ in
            let url = self.diaChiSupabase.appendingPathComponent("/storage/v1/object/\(self.tenBucket)/\(userId).json")
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.timeoutInterval = 25
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("true", forHTTPHeaderField: "x-upsert")
            req.setValue(self.khoaBiMatSupabase, forHTTPHeaderField: "apikey")
            req.setValue("Bearer \(self.khoaBiMatSupabase)", forHTTPHeaderField: "Authorization")
            req.httpBody = body
            URLSession.shared.dataTask(with: req) { _, _, _ in }.resume()
        }.resume()
    }

    private func docBangSQLSupabase(
        userId: String,
        hoanTat: @escaping (CaiDatDMX?, [String: DuLieuNgayDMX]) -> Void
    ) {
        guard let token = phien?.accessToken else {
            hoanTat(nil, [:])
            return
        }
        let nhom = DispatchGroup()
        var cdKetQua: CaiDatDMX?
        var ngayKetQua: [String: DuLieuNgayDMX] = [:]

        nhom.enter()
        var compHoSo = URLComponents(url: diaChiSupabase.appendingPathComponent("/rest/v1/dmx_ho_so"), resolvingAgainstBaseURL: false)!
        compHoSo.queryItems = [
            URLQueryItem(name: "select", value: "cai_dat"),
            URLQueryItem(name: "nguoi_dung_id", value: "eq.\(userId)"),
            URLQueryItem(name: "limit", value: "1")
        ]
        var reqHoSo = URLRequest(url: compHoSo.url!)
        reqHoSo.setValue(khoaCongKhaiSupabase, forHTTPHeaderField: "apikey")
        reqHoSo.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: reqHoSo) { data, response, _ in
            if let status = (response as? HTTPURLResponse)?.statusCode, (200..<300).contains(status),
               let data, let rows = try? JSONDecoder().decode([DongHoSoSupabase].self, from: data),
               let cd = rows.first?.cai_dat {
                cdKetQua = cd
            }
            nhom.leave()
        }.resume()

        nhom.enter()
        var compNgay = URLComponents(url: diaChiSupabase.appendingPathComponent("/rest/v1/dmx_du_lieu_ngay"), resolvingAgainstBaseURL: false)!
        compNgay.queryItems = [
            URLQueryItem(name: "select", value: "ngay,du_lieu"),
            URLQueryItem(name: "nguoi_dung_id", value: "eq.\(userId)"),
            URLQueryItem(name: "order", value: "ngay.desc"),
            URLQueryItem(name: "limit", value: "62")
        ]
        var reqNgay = URLRequest(url: compNgay.url!)
        reqNgay.setValue(khoaCongKhaiSupabase, forHTTPHeaderField: "apikey")
        reqNgay.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: reqNgay) { data, response, _ in
            if let status = (response as? HTTPURLResponse)?.statusCode, (200..<300).contains(status),
               let data, let rows = try? JSONDecoder().decode([DongDuLieuNgaySupabase].self, from: data) {
                for r in rows {
                    ngayKetQua[r.ngay] = r.du_lieu
                }
            }
            nhom.leave()
        }.resume()

        nhom.notify(queue: .global()) {
            hoanTat(cdKetQua, ngayKetQua)
        }
    }

    private func ghiBangSQLSupabase(userId: String, goi: GoiDongBo) {
        guard let token = phien?.accessToken else { return }
        let isoNow = ISO8601DateFormatter().string(from: Date())

        if let cd = goi.caiDat {
            var comp = URLComponents(url: diaChiSupabase.appendingPathComponent("/rest/v1/dmx_ho_so"), resolvingAgainstBaseURL: false)!
            comp.queryItems = [URLQueryItem(name: "on_conflict", value: "nguoi_dung_id")]
            var req = URLRequest(url: comp.url!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
            req.setValue(khoaCongKhaiSupabase, forHTTPHeaderField: "apikey")
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let body = DongHoSoSupabase(
                nguoi_dung_id: userId,
                ten_dang_nhap: tenDangNhap.isEmpty ? "user" : tenDangNhap,
                cai_dat: cd,
                ngay_cap_nhat: isoNow
            )
            req.httpBody = try? JSONEncoder().encode(body)
            URLSession.shared.dataTask(with: req) { _, _, _ in }.resume()
        }

        if let ngay = goi.ngay, let dl = goi.duLieuNgay {
            var comp = URLComponents(url: diaChiSupabase.appendingPathComponent("/rest/v1/dmx_du_lieu_ngay"), resolvingAgainstBaseURL: false)!
            comp.queryItems = [URLQueryItem(name: "on_conflict", value: "nguoi_dung_id,ngay")]
            var req = URLRequest(url: comp.url!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
            req.setValue(khoaCongKhaiSupabase, forHTTPHeaderField: "apikey")
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let body = DongDuLieuNgaySupabase(
                nguoi_dung_id: userId,
                ngay: ngay,
                du_lieu: dl,
                ngay_cap_nhat: isoNow
            )
            req.httpBody = try? JSONEncoder().encode(body)
            URLSession.shared.dataTask(with: req) { _, _, _ in }.resume()
        }
    }

    private func lamMoiPhien(hoanTat: @escaping (Bool) -> Void) {
        guard let refresh = phien?.refreshToken else { hoanTat(false); return }
        guiSupabaseAuth(query: "grant_type=refresh_token", body: ["refresh_token": refresh]) { [weak self] kq in
            guard let self else { hoanTat(false); return }
            if case .success(let authRes) = kq,
               let token = authRes.accessToken,
               let refreshMoi = authRes.refreshToken {
                let exp = authRes.expiresAt ?? (Int(Date().timeIntervalSince1970) + (authRes.expiresIn ?? 3600))
                let ten = authRes.user?.userMetadata?["ten_dang_nhap"] ?? self.tenDangNhap
                let quyen = authRes.user.map { self.xacDinhLaAdmin(user: $0, tenDangNhap: ten) } ?? self.laAdmin
                let moi = PhienDangNhapDMX(
                    accessToken: token,
                    refreshToken: refreshMoi,
                    expiresAt: exp,
                    userId: authRes.user?.id ?? self.phien?.userId,
                    tenDangNhap: ten,
                    laAdmin: quyen
                )
                self.phien = moi
                self.luuKeychain(moi)
                hoanTat(true)
            } else {
                hoanTat(false)
            }
        }
    }

    private func guiWeb<T: Decodable, B: Encodable>(path: String, method: String, body: B, canDangNhap: Bool, hoanTat: @escaping (Result<T, Error>) -> Void) {
        let data = try? JSONEncoder().encode(body)
        guiWeb(path: path, method: method, bodyData: data, canDangNhap: canDangNhap, hoanTat: hoanTat)
    }

    private func guiWeb<T: Decodable>(path: String, method: String, bodyData: Data?, canDangNhap: Bool, thuLai: Bool = true, hoanTat: @escaping (Result<T, Error>) -> Void) {
        var request = URLRequest(url: diaChiWeb.appendingPathComponent(path))
        request.httpMethod = method
        request.httpBody = bodyData
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if canDangNhap, let token = phien?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error { DispatchQueue.main.async { hoanTat(.failure(error)) }; return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if status == 401, canDangNhap, thuLai {
                self?.lamMoiPhien { thanhCong in
                    guard thanhCong else {
                        DispatchQueue.main.async { hoanTat(.failure(NSError.dmx("Phiên đăng nhập đã hết hạn."))) }
                        return
                    }
                    self?.guiWeb(path: path, method: method, bodyData: bodyData, canDangNhap: true, thuLai: false, hoanTat: hoanTat)
                }
                return
            }
            let duLieu = data ?? Data()
            guard (200..<300).contains(status) else {
                let loi = (try? JSONDecoder().decode(LoiMayChu.self, from: duLieu).loi) ?? "Máy chủ chưa phản hồi."
                DispatchQueue.main.async { hoanTat(.failure(NSError.dmx(loi))) }
                return
            }
            do {
                let decoded = try JSONDecoder().decode(T.self, from: duLieu)
                DispatchQueue.main.async { hoanTat(.success(decoded)) }
            } catch {
                DispatchQueue.main.async { hoanTat(.failure(error)) }
            }
        }.resume()
    }

    private func docKeychain() -> PhienDangNhapDMX? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: khoaKeychain,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(PhienDangNhapDMX.self, from: data)
    }

    private func luuKeychain(_ phien: PhienDangNhapDMX) {
        guard let data = try? JSONEncoder().encode(phien) else { return }
        xoaKeychain()
        SecItemAdd([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: khoaKeychain,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ] as CFDictionary, nil)
    }

    private func xoaKeychain() {
        SecItemDelete([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: khoaKeychain
        ] as CFDictionary)
    }
}

extension Notification.Name {
    static let duLieuDMXDaDongBo = Notification.Name("duLieuDMXDaDongBo")
    static let taiKhoanDMXBiDangXuat = Notification.Name("taiKhoanDMXBiDangXuat")
}

private extension NSError {
    static func dmx(_ message: String) -> NSError {
        NSError(domain: "TongHopDMX", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
