# Tài Liệu Kiến Trúc & Chỉ Dẫn Nhanh Cho AI — Dự Án `TongHopDMX` (iOS)

> **MỤC ĐÍCH DÀNH CHO AI TRONG CUỘC TRÒ CHUYỆN MỚI:**
> Tài liệu này cung cấp bản đồ chi tiết toàn bộ mã nguồn, luồng dữ liệu, quy tắc giao diện và vị trí từng thành phần của dự án **Tổng Hợp Số Liệu ĐMX (`TongHopDMX`)**.
> Khi nhận yêu cầu từ người dùng, **hãy đọc file `README.md` này trước tiên** để xác định chính xác file `.swift` và hàm cần chỉnh sửa mà **không cần đọc mò lại toàn bộ dự án từ đầu**.

---

## 1. Quy Tắc Bắt Buộc Khi Sửa Code & Trả Kết Quả Cho Người Dùng

1. **Chỉ trả về các file đã sửa trong file `.zip`**:
   - Sau khi hoàn thành chỉnh sửa, **chỉ đóng gói những file đã sửa** (giữ nguyên cấu trúc thư mục `MaNguon/<TenFile>.swift`) vào một file `.zip` và gửi lại cho người dùng. **Không đóng gói toàn bộ dự án.**
2. **Hiển thị đầy đủ 100% văn bản, tuyệt đối không có dấu `...`**:
   - Mọi `UILabel`, `UIButton`, `UISegmentedControl`, `UITableViewCell`, `UICollectionViewCell` trên màn hình và trong các hàm xuất ảnh báo cáo đều phải đặt:
     - `numberOfLines = 0`
     - `lineBreakMode = .byWordWrapping`
     - `adjustsFontSizeToFitWidth = false`
   - Ở các menu chọn hành động / xuất ảnh, không dùng `UIAlertController(preferredStyle: .actionSheet)` mặc định của iOS (vì iOS tự thu nhỏ cỡ chữ không đều và cắt chữ bằng `...`). Luôn sử dụng `hienMenuChon(...)` (`HopChonDMXController` trong `MoHinh.swift`) để tất cả các dòng có **cùng cỡ chữ (`15pt semibold`)** và tự xuống dòng khi dài.
   - Ở các hàm vẽ/xuất ảnh (`taoAnh...`) và bảng dữ liệu, phải tính chiều cao dòng/thẻ/tiêu đề động theo `boundingRect` để khung chứa luôn đủ cao cho văn bản nhiều dòng.
3. **Không làm đơ máy người dùng (Non-blocking Main Thread)**:
   - Không ghi file JSON lớn hoặc mã hóa `.prettyPrinted` trên luồng chính (Main Thread); luôn dùng `ThuMucDuLieu.dungChung.ghiNgayBatDongBo(...)` và `ghiCaiDatBatDongBo(...)`.
   - Đồng bộ Supabase phải đi qua cơ chế gom nhóm & chống dội (`debounce 1.0s`) trên luồng nền `qos: .utility` trong `DichVuDongBo.swift`.
4. **Quy tắc an toàn biên dịch Xcode 16+ / Swift 5 (iOS 16.0+)**:
   - Khi dùng `boundingRect` với `CGSize`, luôn viết tường minh `CGFloat.greatestFiniteMagnitude` và ép kiểu `CGFloat` cho chiều rộng nếu là số nguyên, ví dụ:
     `CGSize(width: CGFloat(340), height: CGFloat.greatestFiniteMagnitude)` (tránh lỗi `ambiguous use of 'greatestFiniteMagnitude'`).
   - Với `OperationQueue`, thuộc tính tên là `opQueue.name` (chữ `n` viết thường).

---

## 2. Cấu Trúc Thư Mục & Thông Tin Build

- **Nền tảng**: iOS `16.0+`, Swift `5.0`, UIKit thuần (100% code tay bằng Auto Layout & Frame, không dùng Storyboard/SwiftUI).
- **Công cụ tạo project**: `project.yml` (XcodeGen) -> tạo `TongHopDMX.xcodeproj` -> biên dịch ra `TongHopDMX-unsigned.ipa` trên GitHub Actions.
- **Cấu trúc tệp**:
  - `project.yml`: Cấu hình target `TongHopDMX`, bundle ID `com.thanhduong.tonghopdmx`.
  - `TaiNguyen/ThongTin.plist`: `Info.plist` của ứng dụng.
  - `TaiNguyen/Assets.xcassets`: Icon ứng dụng (`AppIcon.appiconset`).
  - `MaNguon/`: Chứa toàn bộ 10 file mã nguồn Swift của ứng dụng.

---

## 3. Bản Đồ Chi Tiết 10 File Trong `MaNguon/` (Để AI Tra Cứu Tức Thì)

| File | Vai trò chính | Các Class / Struct / Hàm quan trọng bên trong |
| :--- | :--- | :--- |
| **`UyQuyenUngDung.swift`** | Điểm khởi chạy ứng dụng (`@main`) | - `UyQuyenUngDung`: Kiểm tra `DichVuDongBo.dungChung.daDangNhap` để mở `ManHinhChinh` hoặc `ManHinhDangNhap`.<br>- `hienThiManHinhChinh()`, `hienThiDangNhap()`. |
| **`MoHinh.swift`** | Model dữ liệu, Lưu trữ cục bộ (`KhoDuLieu`), Hộp chọn đa dòng (`HopChonDMXController`), Tiện ích định dạng | - **Enums**: `LoaiCheDoDoanhThu` (`.luyKe`, `.realtime`), `LoaiTabMuc` (`.thiDua`, `.nhanVien`, `.duPhong2` là Biểu đồ; `cacTabCumDuoi = [.thiDua, .nhanVien]`), `KieuSapXepNhanVien`, `KieuHienThiBaoCao` (`.bangChiTiet`, `.theGon`), `LoaiChiTieuThiDua` (`.soLuong`, `.doanhThu`).<br>- **Models**: `NhanVienQuanLy`, `DoanhThuNhanVienItem`, `DongXepHangNhanVienNganh`, `MonThiDuaNhanVien`, `TongHopNhanVien`, `ThongTinDoanhThu`, `DongThiDua`, `CaiDatDMX`, `DuBaoQuyDoiThang`, `DuLieuRealtimeNgayTrongThang`, `DuLieuNgayDMX`.<br>- **`ThuMucDuLieu`**: Đọc/ghi file JSON tại `Documents/DuLieuDMX/` (`du-lieu-dmx-v3.json`, `cai-dat-dmx-v3.json`), hỗ trợ ghi bất đồng bộ chống dội `ghiNgayBatDongBo` & `ghiCaiDatBatDongBo`.<br>- **`KhoDuLieu`**: Quản lý toàn bộ dữ liệu RAM + cache (`boNhoDemDuLieuNgay`), đồng bộ Doanh thu Lũy kế cố định theo tháng (`doanhThuLuyKeThang`, `doanhThuNhanVienLuyKeThang`), tính dự báo tháng (`tinhDuBaoQuyDoiTuRealtime`), xếp hạng nhân viên (`tongHopNhanVien`, `danhSachXepHangNhanVien`), lọc cụm từ cài đặt (`apDungLocTuCaiDat`, `gopDanhSachThiDua`).<br>- **`HopChonDMXController` & `MucChonDMX`**: Action Sheet tùy chỉnh hiển thị các lựa chọn cùng cỡ chữ `15pt`, tự xuống dòng không có dấu `...`, gọi qua `vc.hienMenuChon(...)`. |
| **`ManHinhChinh.swift`** | Màn hình chính điều phối toàn bộ thao tác của người dùng | - **Thanh điều hướng (`cauHinhThanhDieuHuong`)**: Nút chọn ngày (`nutNgay`), nút `Nhập tất cả` (`nutNhapTatCa`), nút Chia sẻ/Xuất báo cáo (`nutXuatNav`), nút Cài đặt (`nutCaiDatNav`).<br>- **Khung trên (`khungCumDoanhThu`)**: Chứa `CumChiSoChinhView` (3 nút chế độ trên đầu + 8 thẻ chỉ số chính).<br>- **Khung dưới (`khungCumDuoi`)**:<br>  + Hàng 2 nút tab (`hangBaNut`): `Thi đua` và `Nhân viên`.<br>  + Hàng nút công cụ (`hangNutQuet`):<br>    • Ở tab **Thi đua**: `[Thêm ảnh Thi đua]` (`nutThemAnhMoi`), `[Xoá]` (`nutXoaQuetLai`), `[Nhập/Mẫu]` (`nutThemThuCong` -> bấm vào gọi thẳng `bamThemDongThuCong()`).<br>    • Ở tab **Nhân viên**: `[Nhập ảnh Thi đua NV]` (`nutThemAnhMoi`) và `[Nhập ảnh Doanh thu]` (`nutNhapDoanhThuNV`) nằm **cùng hàng** với `[Xoá]` (`nutXoaQuetLai`); ẩn `nutThemThuCong`.<br>- **Xử lý quét ảnh**: `xuLyQuetTatCaAnhTheoTab`, `xuLyQuetThiDua`, `xuLyQuetThiDuaNhanVien`, `xuLyQuetDoanhThuNhanVien`, `xuLyQuetDoanhThu`.<br>- **Xuất báo cáo (`moMenuXuatBaoCao`, `moChonNhanVienChiaSeAnh`)**: Xuất ảnh Thi đua Lũy kế (Thực hiện & Target / % Dự kiến cuối tháng), ảnh Thi đua Realtime, ảnh Bảng xếp hạng NV, ảnh Sức khỏe NV (1 NV / bộ ảnh rời / 1 ảnh gộp), ảnh Biểu đồ & Realtime tháng, xuất file `.csv`. |
| **`BangThiDuaView.swift`** | Cụm 8 thẻ chỉ số, Bảng/Thẻ Thi đua, Biểu đồ Realtime tháng & Xuất ảnh/CSV | - **`TheDoanhThuView`**: Thẻ KPI nền gradient.<br>- **`CumChiSoChinhView`**: 3 nút trên đầu (`📊 Lũy kế`, `⚡ Realtime`, `📈 Biểu đồ`) + lưới 8 thẻ KPI (`DOANH THU THỰC`, `DOANH THU QĐ`, `% TRẢ GÓP`, `LƯỢT KHÁCH`, `% HT QĐ DỰ KIẾN`, `% QUY ĐỔI`, `THI ĐUA HOÀN THÀNH`, `TĂNG/GIẢM CÙNG KỲ`).<br>- **`OTheThiDuaCell`**: Ô thẻ tiến độ gọn (cỡ chữ đồng nhất `12.5pt`, tự tính chiều cao qua `tinhChieuCaoThe`).<br>- **`BangThiDuaView`**: Hiển thị bảng 8 cột (`bang8Cot`) hoặc lưới thẻ gọn (`luoi`), nút `% dự kiến` (chỉ hiện ở Lũy kế), lọc `Tất cả / Đạt / Chưa đạt`, sắp xếp, xuất ảnh (`taoAnhBaoCao`, `taoAnhMauBang8Cot`, `taoAnhMauTheGon`) và xuất CSV (`taoChuoiExcelCSV`).<br>- **`VeBieuDoCotRealtimeView` & `BangTongHopRealtimeThangView`**: Vẽ đồ thị cột Doanh thu Thực & Quy đổi theo ngày, bảng chi tiết các ngày + 3 dòng tổng kết cuối bảng (`TỔNG`, `TB / NGÀY`, `DK CUỐI THÁNG`), xuất ảnh (`taoAnhBaoCaoRealtimeThang`) và xuất CSV (`taoChuoiExcelCSVBieuDoThang`). |
| **`ManHinhNhanVien.swift`** | Bảng xếp hạng nhân viên, Chi tiết ngành hàng theo NV & Sức khỏe cá nhân NV | - **`ManHinhChiTietNganhHang`**: Mở khi chạm vào 1 ngành hàng trong bảng Thi đua. Cho phép quét ảnh thực hiện NV của ngành đó, sửa tay số thực hiện từng NV, mở màn hình Chia Target và xuất ảnh (`taoAnhBangNganhHang`).<br>- **`BangNhanVienView`**: Hiển thị ở tab **Nhân viên** ngoài màn hình chính. Gồm tiêu đề + nút sắp xếp (`Số môn HT`, `DT QĐ`, `% HT TB`), bảng 8 cột xếp hạng tổng hợp nhân viên và hàm xuất ảnh (`taoAnhBaoCaoNhanVien`).<br>- **`ManHinhChiTietNhanVien`**: Mở khi chạm vào 1 nhân viên trong `BangNhanVienView`. Hiển thị tiến độ tháng, 4 thẻ KPI cá nhân, bảng 8 cột các môn thi đua của nhân viên và hàm xuất ảnh sức khỏe (`taoAnhSucKhoeNhanVien`, `taoTatCaAnhSucKhoe`, `taoAnhGopTatCaSucKhoe`). |
| **`DichVuDocAnh.swift`** | Nhận diện chữ OCR bằng Apple Vision (Offline 100%) | - `DichVuDocAnh`: Dùng `VNRecognizeTextRequest` đọc văn bản tiếng Việt từ ảnh chụp màn hình báo cáo.<br>- Tự động phân loại và bóc tách 5 dạng ảnh trong `quetVaPhanLoaiTatCaAnh`:<br>  1. Ảnh Doanh thu siêu thị (`laAnhDoanhThuSieuThi`, `phanTichDoanhThu`)<br>  2. Ảnh Thực hiện Nhân viên theo Ngành hàng (`phanTichThiDuaNhanVienOffline`)<br>  3. Ảnh Doanh thu hợp nhất theo Nhân viên (`phanTichDoanhThuNhanVienOffline`)<br>  4. Ảnh Lưới thẻ thi đua 2 cột (`phanTichThiDuaLuoiThe2Cot`)<br>  5. Ảnh Bảng thi đua ghép cặp/đơn (`ghepCapAnhThiDua`, `phanTichThiDuaOffline`). |
| **`DichVuDongBo.swift`** | Xác thực, Phân quyền Admin & Đồng bộ đám mây Supabase | - Kết nối Supabase (`https://isxrxeaxytyiydxiwvuc.supabase.co`) và Web API (`https://www.duongnt.io.vn/api/dmx/dong-bo`).<br>- Tài khoản Admin gốc: `duongnt` (`DichVuDongBo.taiKhoanAdminGoc`).<br>- Lưu trữ đám mây: Bảng SQL `dmx_ho_so` (cài đặt), bảng SQL `dmx_du_lieu_ngay` (dữ liệu từng ngày) và Supabase Storage bucket `dmx-du-lieu/{userId}.json`.<br>- Tối ưu hiệu năng: Dùng `phienMang` (`URLSession` với `qos: .utility`), gom nhóm thay đổi (`cacNgayChoDay`, `caiDatChoDay`) và chống dội `1.0s` (`lenLichDayDuLieuNen` -> `thucThiDayDuLieuGomNhom`), tự động đẩy nốt khi ứng dụng xuống nền (`willResignActiveNotification`). |
| **`ManHinhCaiDat.swift`** | Cài đặt hiển thị, Lọc cụm từ & Quản trị tài khoản Admin | - **`ManHinhCaiDat`**: Chọn mẫu hiển thị (`Bảng 8 cột` / `Thẻ tiến độ`), chọn số cột xuất ảnh (`1–4 cột`), thêm/xóa cụm từ lọc bỏ khỏi tên ngành hàng, mở Chia Target / Quản lý NV, đổi mật khẩu, đăng xuất.<br>- **`ManHinhQuanLyTaiKhoan`**: Dành riêng cho Admin để xem danh sách tài khoản, tạo tài khoản mới (thường hoặc Admin), đổi mật khẩu, cấp/gỡ quyền Admin, xóa tài khoản. |
| **`ManHinhQuanLyNhanVien.swift`** | Quản lý danh sách nhân viên & Chia Target mặt hàng | - **`ManHinhQuanLyNhanVien`**: Thêm, sửa, xóa nhân viên, dán nhanh danh sách nhiều nhân viên từ bộ nhớ tạm (`Mã NV - Họ tên`), nạp 16 nhân viên mẫu.<br>- **`ManHinhChiaTarget`**: Chọn mặt hàng từ bảng Thi đua, tích chọn nhân viên nhận Target (chia đều tự động), sửa nhanh Target & ĐVT (`DT`/`SL`) đồng bộ 2 chiều với bảng Thi đua. |
| **`ManHinhDangNhap.swift`** | Màn hình đăng nhập | - `ManHinhDangNhap`: Đăng nhập bằng tên đăng nhập (tự ghép hậu tố `@dmx.internal.duongnt.io.vn`) và mật khẩu. |

---

## 4. Quy Trình Đề Xuất Cho AI Khi Nhận Yêu Cầu Mới

1. **Bước 1 — Định vị file cần sửa từ Bản đồ Mục 3**:
   - Sửa giao diện nút chế độ, 8 thẻ KPI, bảng/thẻ Thi đua, biểu đồ tháng hoặc ảnh xuất Thi đua/Biểu đồ -> mở `MaNguon/BangThiDuaView.swift`.
   - Sửa bố cục màn hình chính, thanh điều hướng, các nút dưới tab, luồng chọn ảnh hoặc menu xuất báo cáo -> mở `MaNguon/ManHinhChinh.swift`.
   - Sửa bảng xếp hạng nhân viên, chi tiết ngành hàng nhân viên, sức khỏe nhân viên hoặc ảnh xuất nhân viên -> mở `MaNguon/ManHinhNhanVien.swift`.
   - Sửa logic tính toán, lưu trữ, bộ lọc tên ngành hàng hoặc hộp chọn đa dòng `HopChonDMXController` -> mở `MaNguon/MoHinh.swift`.
   - Sửa thuật toán đọc ảnh OCR -> mở `MaNguon/DichVuDocAnh.swift`.
   - Sửa đồng bộ Supabase / phân quyền tài khoản -> mở `MaNguon/DichVuDongBo.swift`.
   - Sửa màn hình Cài đặt / Quản lý nhân viên / Chia Target -> mở `MaNguon/ManHinhCaiDat.swift` hoặc `MaNguon/ManHinhQuanLyNhanVien.swift`.
2. **Bước 2 — Thực hiện chỉnh sửa & Kiểm tra cú pháp**:
   - Đọc đúng đoạn code liên quan trong file cần sửa, áp dụng thay đổi và kiểm tra kỹ cân bằng dấu ngoặc `{}`, `()`, `[]` cùng kiểu dữ liệu `CGFloat` tường minh.
3. **Bước 3 — Đóng gói kết quả**:
   - Nén **chỉ những file đã sửa** (theo đường dẫn `MaNguon/<TenFile>.swift`) vào một file `.zip` và gửi lại cho người dùng.


## Cập nhật mới nhất: Biểu đồ Sức khỏe Nhân viên & Cảnh báo 5 NV yếu liên tục
- Trong mục **Biểu đồ** (`BangTongHopRealtimeThangView` tại `MaNguon/BangThiDuaView.swift`), trên đầu có **2 nút chuyển đổi trực tiếp**: `📊 Biểu đồ Realtime` và `❤️‍🩹 Biểu đồ sức khỏe NV`.
- **Biểu đồ sức khỏe NV (`VeBieuDoSucKhoeNhanVienView`)**: Hiển thị trực quan toàn bộ ~16 nhân viên bằng biểu đồ thanh ngang phân tầng màu (`🟢 Khỏe >=75%`, `🟡 Trung bình 55-74%`, `🔴 Yếu <55%`), kèm chuỗi chấm lịch sử các ngày gần nhất và bảng ma trận nhiệt theo ngày.
- **Cảnh báo 5 nhân viên yếu nhiều ngày liên tục (`KhoDuLieu.tinhBaoCaoSucKhoeNhanVien` tại `MaNguon/MoHinh.swift`)**: Tự động thống kê chuỗi ngày yếu liên tiếp (`soNgayYeuLienTuc`), tổng số ngày yếu và các ngành hàng yếu nhất cần kèm cặp của Top 5 nhân viên yếu nhất.
