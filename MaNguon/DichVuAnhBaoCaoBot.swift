import UIKit
import Security

enum KhoAnhBaoCaoBot: String, Codable, CaseIterable {
    case supabase
    case googleDrive

    var tieuDe: String {
        switch self {
        case .supabase: return "Supabase"
        case .googleDrive: return "Google Drive"
        }
    }
}

struct CauHinhKhoAnhBaoCaoBot: Codable, Equatable {
    var kho: KhoAnhBaoCaoBot = .supabase
    var urlAppsScript: String = ""
    var khoaBiMat: String = ""
    var folderId: String = ""

    var driveDaSanSang: Bool {
        kho == .googleDrive &&
        urlAppsScript.lowercased().hasPrefix("https://script.google.com/") &&
        !khoaBiMat.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !folderId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct PhanHoiGoogleDrive: Decodable {
    var ok: Bool?
    var url: String?
    var fileId: String?
    var error: String?
}

final class DichVuAnhBaoCaoBot {
    static let dungChung = DichVuAnhBaoCaoBot()
    private let khoaKeychain = "com.thanhduong.tonghopdmx.kho-anh-bao-cao-bot-v1"
    private let hangDoi = DispatchQueue(label: "com.thanhduong.tonghopdmx.anh-bot", qos: .utility)
    private let phienMang: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 45
        cfg.timeoutIntervalForResource = 60
        return URLSession(configuration: cfg)
    }()

    private init() {}

    var cauHinh: CauHinhKhoAnhBaoCaoBot {
        get { docCauHinh() ?? CauHinhKhoAnhBaoCaoBot() }
        set { luuCauHinh(newValue) }
    }

    func taiAnh(
        _ anh: UIImage,
        loai: String,
        ngay: String,
        buocDungSupabase: Bool = false,
        hoanTat: ((Result<String, Error>) -> Void)? = nil
    ) {
        let cauHinh = self.cauHinh
        hangDoi.async { [weak self] in
            guard let self,
                  let jpeg = self.duLieuJPEGToiUu(anh) else {
                DispatchQueue.main.async { hoanTat?(.failure(NSError.dmx("Không nén được ảnh báo cáo."))) }
                return
            }
            if !buocDungSupabase && cauHinh.driveDaSanSang {
                self.taiLenDrive(jpeg, loai: loai, ngay: ngay, cauHinh: cauHinh) { ketQua in
                    switch ketQua {
                    case .success(let url):
                        DichVuDongBo.dungChung.luuAnhBaoCaoBot(loai: loai, ngay: ngay, urlDrive: url) { kq in
                            hoanTat?(kq.map { "Google Drive" })
                        }
                    case .failure:
                        // Drive lỗi không làm mất lịch gửi: tự lưu bản mới nhất sang Supabase.
                        self.taiLenSupabase(jpeg, loai: loai, ngay: ngay, hoanTat: hoanTat)
                    }
                }
            } else {
                self.taiLenSupabase(jpeg, loai: loai, ngay: ngay, hoanTat: hoanTat)
            }
        }
    }

    private func taiLenSupabase(
        _ jpeg: Data,
        loai: String,
        ngay: String,
        hoanTat: ((Result<String, Error>) -> Void)?
    ) {
        DichVuDongBo.dungChung.taoPhienTaiAnhBaoCaoTrucTiep(loai: loai, ngay: ngay) { [weak self] ketQua in
            guard let self else { return }
            switch ketQua {
            case .failure(let loi):
                hoanTat?(.failure(loi))
            case .success(let phienTai):
                var request = URLRequest(url: phienTai.signedURL)
                request.httpMethod = "PUT"
                request.httpBody = jpeg
                request.timeoutInterval = 60
                request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
                request.setValue("max-age=31536000", forHTTPHeaderField: "Cache-Control")
                request.setValue("false", forHTTPHeaderField: "x-upsert")
                request.setValue(String(jpeg.count), forHTTPHeaderField: "Content-Length")
                self.phienMang.dataTask(with: request) { _, response, error in
                    if let error {
                        DispatchQueue.main.async { hoanTat?(.failure(error)) }
                        return
                    }
                    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                    guard (200..<300).contains(status) else {
                        DispatchQueue.main.async {
                            hoanTat?(.failure(NSError.dmx("Supabase từ chối tải ảnh trực tiếp (HTTP \(status)).")))
                        }
                        return
                    }
                    DichVuDongBo.dungChung.xacNhanTaiAnhBaoCaoTrucTiep(
                        loai: loai,
                        ngay: ngay,
                        duongDanLuuTru: phienTai.duongDanLuuTru
                    ) { kq in
                        hoanTat?(kq.map { "Supabase" })
                    }
                }.resume()
            }
        }
    }

    private func taiLenDrive(
        _ jpeg: Data,
        loai: String,
        ngay: String,
        cauHinh: CauHinhKhoAnhBaoCaoBot,
        hoanTat: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: cauHinh.urlAppsScript) else {
            hoanTat(.failure(NSError.dmx("URL Apps Script không hợp lệ.")))
            return
        }
        let payload: [String: Any] = [
            "key": cauHinh.khoaBiMat,
            "folderId": cauHinh.folderId,
            "fileName": "dmx-\(loai)-\(ngay).jpg",
            "mimeType": "image/jpeg",
            "base64": jpeg.base64EncodedString()
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            hoanTat(.failure(NSError.dmx("Không đóng gói được ảnh Drive.")))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        phienMang.dataTask(with: request) { data, response, error in
            if let error { hoanTat(.failure(error)); return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(status), let data,
                  let kq = try? JSONDecoder().decode(PhanHoiGoogleDrive.self, from: data),
                  kq.ok == true, let urlAnh = kq.url,
                  URL(string: urlAnh)?.scheme == "https" else {
                hoanTat(.failure(NSError.dmx("Google Drive từ chối ảnh hoặc chưa chia sẻ ảnh công khai.")))
                return
            }
            hoanTat(.success(urlAnh))
        }.resume()
    }

    private func duLieuJPEGToiUu(_ anh: UIImage) -> Data? {
        let gioiHan = 2_900_000
        let rong = max(1, anh.size.width)
        let cao = max(1, anh.size.height)
        let gioiHanDiemAnh: CGFloat = 6_000_000
        let tiLeTheoRong = min(1, 1_400 / rong)
        let tiLeTheoDiemAnh = min(1, sqrt(gioiHanDiemAnh / (rong * cao)))
        var anhDangNen = thuNho(anh, tiLe: min(tiLeTheoRong, tiLeTheoDiemAnh))

        // Chỉ mã hóa vài lần có tính toán. Cách cũ có thể mã hóa hơn 100 lần
        // đối với ảnh thứ 8 rất dài, khiến người dùng tưởng mạng tải chậm.
        let cacChatLuong: [CGFloat] = [0.82, 0.66, 0.50, 0.36]
        var nhoNhat: Data?
        for _ in 0..<4 {
            for chatLuong in cacChatLuong {
                guard let data = anhDangNen.jpegData(compressionQuality: chatLuong) else { continue }
                if nhoNhat == nil || data.count < nhoNhat!.count { nhoNhat = data }
                if data.count <= gioiHan { return data }
            }

            guard let nhoNhat else { return nil }
            let tiLeDuKien = sqrt(CGFloat(gioiHan) / CGFloat(max(1, nhoNhat.count))) * 0.90
            let tiLeThuNho = min(0.82, max(0.45, tiLeDuKien))
            anhDangNen = thuNho(anhDangNen, tiLe: tiLeThuNho)
        }

        return nhoNhat.flatMap { $0.count <= gioiHan ? $0 : nil }
    }

    private func thuNho(_ anh: UIImage, rongToiDa: CGFloat) -> UIImage {
        guard anh.size.width > rongToiDa else { return anh }
        return thuNho(anh, tiLe: rongToiDa / anh.size.width)
    }

    private func thuNho(_ anh: UIImage, tiLe: CGFloat) -> UIImage {
        guard tiLe < 0.999 else { return anh }
        let kichThuoc = CGSize(
            width: max(1, anh.size.width * tiLe),
            height: max(1, anh.size.height * tiLe)
        )
        return UIGraphicsImageRenderer(size: kichThuoc).image { _ in
            anh.draw(in: CGRect(origin: .zero, size: kichThuoc))
        }
    }

    private func luuCauHinh(_ value: CauHinhKhoAnhBaoCaoBot) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrAccount as String: khoaKeychain]
        SecItemDelete(query as CFDictionary)
        var them = query
        them[kSecValueData as String] = data
        SecItemAdd(them as CFDictionary, nil)
    }

    private func docCauHinh() -> CauHinhKhoAnhBaoCaoBot? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: khoaKeychain,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(CauHinhKhoAnhBaoCaoBot.self, from: data)
    }
}
