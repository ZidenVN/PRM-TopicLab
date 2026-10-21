# BÁO CÁO KỸ THUẬT & HƯỚNG DẪN THỰC THI: TOPIC 2 - BẢN ĐỒ & ĐỊNH VỊ GPS
> **Chủ đề (Topic 2):** Bản đồ số, Định vị GPS, Dẫn đường OSRM & Mô phỏng theo dõi thời gian thực (Flutter Map, OpenStreetMap & OSRM Engine)

---

## 1. TỔNG QUAN KIẾN TRÚC & NGUYÊN LÝ HOẠT ĐỘNG

Dự án được xây dựng theo mô hình kiến trúc phân tầng chuẩn (**Clean Service-Oriented Architecture**), phân tách độc lập giữa tầng giao diện (**UI Layer**), tầng quản lý trạng thái (**State/Controller**), tầng dịch vụ mạng (**Service Layer**) và tầng mô hình dữ liệu (**Domain/Model**).

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       GIAO DIỆN NGƯỜI DÙNG (UI LAYER)                       │
│  - Thanh tìm kiếm địa chỉ (Search Bar) & Bộ chọn Điểm đi / Điểm đến (A/B)   │
│  - Cụm phím điều khiển Zoom nổi (+, -, Fit Route, Về điểm xuất phát)        │
│  - Bảng thông số thời gian thực: Quãng đường (km), Thời gian (phút), ETA    │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    TẦNG ĐIỀU KHIỂN & HIỂN THỊ BẢN ĐỒ                        │
│  - MapController & FlutterMap (Camera, Bounds, Viewport, Gestures)          │
│  - TileLayer: Tải & Cache các mảnh ảnh bản đồ Slippy Map (z, x, y)          │
│  - PolylineLayer: Vẽ dải đường uốn lượn màu xanh theo các ngã rẽ giao thông │
│  - MarkerLayer: Ghim Marker xuất phát (A), Marker đích (B), Icon ô tô chạy  │
└───────────────────────┬───────────────────────────────┬─────────────────────┘
                        │                               │
                        ▼                               ▼
       ┌─────────────────────────────┐    ┌──────────────────────────────┐
       │   TÌM KIẾM ĐỊA CHỈ & TỌA ĐỘ │    │    TÍNH TUYẾN ĐƯỜNG & ETA    │
       │   - OSM Nominatim API       │    │    - OSRM Route Engine API   │
       │   - Bộ nhớ Offline Presets  │    │    - Thuật toán Fallback     │
       └─────────────────────────────┘    └──────────────────────────────┘
```

---

## 2. NGUYÊN LÝ LẤY BẢN ĐỒ, DỮ LIỆU & CƠ CHẾ LƯU TRỮ

### 2.1. Bản đồ số hoạt động như thế nào? (Tile-based Map System)
- Bản đồ trong ứng dụng không phải là một bức ảnh khổng lồ nguyên khối, mà được chia thành hàng triệu mảnh ảnh vuông nhỏ kích thước **256×256 pixels** gọi là **Map Tiles**.
- Mỗi mảnh ảnh được định vị theo hệ trục tọa độ Slippy Map: `(z, x, y)`:
  * `z (Zoom level)`: Mức độ phóng to (từ 3: toàn cầu đến 18: từng số nhà, ngõ ngách).
  * `x, y`: Tọa độ chỉ mục của mảnh ảnh trên quả địa cầu theo phép chiếu Mercator.
- **Nguồn máy chủ Tile:** Ứng dụng kết nối trực tiếp với cụm máy chủ OpenStreetMap Mirror tốc độ cao quốc tế:
  ```
  https://tile.openstreetmap.de/{z}/{x}/{y}.png
  ```
  Nguồn này hiển thị bản đồ tiếng Việt đầy đủ, cập nhật thời gian thực, không giới hạn lưu lượng, không yêu cầu API key và không có hình mờ (watermark).

### 2.2. Cơ chế lưu trữ đệm (Caching Mechanism)
- Khi một mảnh ảnh tile được tải về từ internet, hệ thống bộ nhớ đệm tự động (**Flutter ImageCache & NetworkImage Engine**) sẽ giữ lại hình ảnh trong bộ nhớ RAM của máy ảo/điện thoại.
- Khi người dùng lia camera (Pan) qua lại giữa các khu vực đã xem hoặc bấm Zoom, ứng dụng đọc ngay ảnh từ bộ nhớ đệm mà không cần gửi request lên máy chủ, giúp bản đồ hiển thị mượt mà 60 FPS và tiết kiệm băng thông mạng tối đa.

### 2.3. Cơ chế tìm kiếm tọa độ địa chỉ (Geocoding)
- Khi người dùng nhập tên địa điểm (ví dụ: *"Landmark 81"* hoặc *"Chợ Bến Thành"*):
  1. **Tầng 1 (Ưu tiên Offline):** Kiểm tra trong từ điển địa điểm nhanh có sẵn (`quickPlaces`). Nếu khớp từ khóa, trả về tọa độ `(Latitude, Longitude)` ngay tức thì (0ms trễ, hoạt động ngay cả khi ngắt kết nối mạng).
  2. **Tầng 2 (Online Geocoding):** Gửi request HTTP GET tới OpenStreetMap Nominatim API kèm proxy an toàn để phân tích chuỗi văn bản thành tọa độ địa lý chuẩn quốc tế WGS-84.

### 2.4. Cơ chế tính toán tuyến đường (OSRM Routing Engine)
- Gửi tọa độ Điểm đi (A) và Điểm đến (B) lên máy chủ OSRM (*Open Source Routing Machine*):
  ```
  https://router.project-osrm.org/route/v1/driving/{lon1},{lat1};{lon2},{lat2}?overview=full&geometries=geojson
  ```
- **Xử lý dữ liệu trả về:**
  * `distance`: Khoảng cách tính bằng mét ➔ Tự động quy đổi sang **km** (`${(distance / 1000).toStringAsFixed(1)} km`).
  * `duration`: Thời gian di chuyển tính bằng giây ➔ Tự động quy đổi sang **phút / giờ** (`$mins phút` hoặc `$hours giờ $mins phút`).
  * `geometry.coordinates`: Mảng danh sách hàng trăm cặp tọa độ `[longitude, latitude]` thể hiện từng khúc cua, ngã rẽ của con đường ➔ Chuyển đổi thành danh sách `List<LatLng>` để nạp vào `PolylineLayer` vẽ dải màu xanh nổi bật men theo các trục đường thực tế.
  * **ETA (Estimated Time of Arrival):** Lấy thời gian thực của đồng hồ hệ thống cộng với số giây di chuyển để hiển thị giờ đến chính xác (ví dụ: `10:45`).
- **Cơ chế Khả dụng cao (Fault-Tolerance Fallback):** Nếu mạng chập chờn hoặc máy chủ OSRM quá tải, thuật toán nội suy hình học Great-Circle sẽ tự động kích hoạt để tính khoảng cách toán học và sinh tuyến đường nối thông minh, đảm bảo app **không bao giờ bị crash**.

### 2.5. Cơ chế mô phỏng di chuyển thời gian thực (Real-time GPS Tracking Simulation)
- Để đáp ứng bài toán theo dõi xe công nghệ di chuyển (tương tự tài xế Grab đón khách):
  * Một bộ đếm nhịp bất đồng bộ `Timer.periodic(Duration(milliseconds: 600))` được khởi tạo.
  * Sau mỗi 600ms, vị trí xe ô tô `_movingPosition` tiến thêm một mắt xích tọa độ dọc theo đường vẽ Polyline.
  * Camera bản đồ tự động gọi `_mapController.move(pos, zoom)` để lia theo xe (Camera Auto-follow).
  * **Giải phóng bộ nhớ an toàn (Lifecycle & Anti-Memory Leak):** Khi xe đến đích, khi người dùng bấm nút **Dừng GPS**, hoặc khi màn hình bị đóng (`dispose`), Timer được tự động hủy (`cancel()`), giải phóng 100% tài nguyên CPU và RAM.

---

## 3. CẤU TRÚC THƯ MỤC DỰ ÁN

```
Map/
├── pubspec.yaml                          # Khai báo dependency (flutter_map, latlong2, http)
├── HUONG_DAN_CHAY.md                     # Tài liệu kỹ thuật chi tiết và kịch bản vận hành
├── README.md                             # Tổng quan giới thiệu và hướng dẫn chạy nhanh
├── android/
│   └── app/src/main/AndroidManifest.xml  # Cấu hình quyền INTERNET và GPS vị trí
├── lib/
│   ├── main.dart                         # Điểm khởi chạy ứng dụng (MyApp)
│   ├── models/
│   │   └── location_model.dart        # Model LocationModel và TripRoute (tính km, phút, ETA)
│   ├── services/
│   │   └── map_service.dart           # Service gọi Nominatim Geocoding & OSRM Routing Engine
│   └── screens/
│       └── map_screen.dart            # Màn hình bản đồ tương tác, phím Zoom, bộ chọn A/B, xe chạy
└── test/
    └── widget_test.dart                  # Bộ kiểm thử tự động toàn diện (5/5 unit tests passed)
```

---

## 4. CHI TIẾT CÁC TÍNH NĂNG ĐÃ TRIỂN KHAI THEO YÊU CẦU ĐỀ BÀI

### 4.1. Question 1: Bản đồ nền, Định vị & Cụm phím điều khiển Zoom
- Hiển thị bản đồ OpenStreetMap toàn diện với đầy đủ các địa danh, tên đường tiếng Việt tại TP.HCM và các tỉnh thành.
- **Tùy biến Điểm xuất phát (A) và Điểm đến (B) linh hoạt:**
  * Thanh chuyển đổi chế độ ở đầu màn hình: `[ 🔵 Điểm đi (A) ]` và `[ 🔴 Điểm đến (B) ]`.
  * Chạm ngón tay (hoặc click chuột) vào bất kỳ vị trí nào trên bản đồ để dời điểm đang chọn.
  * Nút đảo chiều `[ ⇅ ]`: Hoán đổi vị trí của Điểm đi và Điểm đến chỉ với 1 thao tác (A ⇄ B), tự động vẽ lại đường và tính lại thời gian.
- **Bộ phím điều khiển Zoom nổi chuyên dụng (Góc phải màn hình):**
  * Nút `[ + ]`: Phóng to bản đồ (Zoom In) từng nấc.
  * Nút `[ - ]`: Thu nhỏ bản đồ (Zoom Out) để nhìn bao quát.
  * Nút `[ ⛶ ] (Fit Route)`: Tự động tính toán khung bao tọa độ (`LatLngBounds`) và căn chỉnh camera để thấy trọn vẹn cả 2 điểm A, B cùng toàn bộ tuyến đường.
  * Nút `[ 🎯 ] (My Location)`: Bay nhanh góc nhìn về vị trí Điểm xuất phát (A).
  * Hỗ trợ đầy đủ thao tác cảm ứng tự nhiên: Chạm đúp (Double-Tap để phóng to), cuộn bánh xe chuột (Mouse Wheel) và kéo 2 ngón (Pinch-to-zoom).
- **Thanh tìm kiếm địa điểm thông minh:** Hỗ trợ tìm kiếm địa chỉ trực tuyến hoặc chọn nhanh danh mục địa danh mẫu (`landmark 81`, `khu cong nghe cao`, `ha noi`, `da nang`, `ho chi minh`).

### 4.2. Question 2: Tính tuyến đường ô tô, Khoảng cách (km), Thời gian (phút) & ETA
- Tự động gọi API OSRM kết nối giữa Điểm A (Marker tròn xanh) và Điểm B (Marker ghim đỏ).
- Dải màu tuyến đường Polyline màu xanh dương dày 5px uốn lượn sắc nét theo các tuyến phố giao thông.
- **Bảng thẻ thông số nổi phía dưới (Metric Dashboard):**
  * **Quãng đường:** Quy đổi chính xác từ mét sang **km** (ví dụ: `4.7 km`).
  * **Thời gian lái xe:** Quy đổi từ giây sang **phút / giờ** (ví dụ: `7 phút`).
  * **Giờ đến dự kiến (ETA):** Tự động tính toán theo thời gian thực (ví dụ: `10:45`).

### 4.3. Question 3: Theo dõi vị trí GPS thời gian thực (Real-time GPS Tracking)
- Nút bấm **"Mô phỏng xe chạy (Q3)"** trên thẻ thông tin hoặc icon điều hướng trên AppBar.
- Khi kích hoạt:
  * Icon ô tô màu xanh lam tự động lăn bánh theo đúng từng khúc cua của tuyến đường OSRM.
  * Camera tự động di chuyển theo xe (Auto-follow).
  * Thẻ trạng thái hiển thị huy hiệu `GPS Live` màu xanh lá cây gọn gàng, không bị lỗi tràn viền.
  * Nút bấm tự chuyển thành **"■ Dừng GPS"** để người dùng có thể can thiệp dừng bất cứ lúc nào.

---

## 5. HƯỚNG DẪN KHỞI CHẠY VÀ KỊCH BẢN KIỂM THỬ

### 5.1. Khởi chạy ứng dụng

#### Cách 1: Chạy bằng Android Studio (Khuyên dùng)
1. Mở **Android Studio** ➔ Chọn **Open** ➔ Trỏ đến thư mục: `Topic Lab/Map`.
2. Chờ Android Studio tải xong dependencies (`flutter pub get`).
3. Khởi động thiết bị giả lập Android (ví dụ: Pixel 8 API 34).
4. Nhấn nút **Run (Shift + F10)** hoặc bấm icon tam giác xanh ▶️.

#### Cách 2: Chạy qua giao diện dòng lệnh (CLI)
```bash
cd "Topic Lab/Map"
flutter pub get
flutter run
```
*(Nếu muốn chạy trên trình duyệt Web để kiểm thử nhanh: `flutter run -d chrome`)*

### 5.2. Chạy bộ kiểm thử tự động (Unit Test Suite)
```bash
flutter test
```
*Kết quả:* **5/5 tests PASSED (100%)**:
1. `LocationModel parses JSON and converts to LatLng correctly`: Kiểm thử chuyển đổi JSON sang tọa độ và đối tượng LatLng.
2. `TripRoute formats distance and duration correctly`: Kiểm thử quy đổi mét sang km và giây sang phút.
3. `TripRoute formats hours when duration exceeds 60 minutes`: Kiểm thử tự động format sang giờ và phút khi chuyến đi dài hơn 1 tiếng.
4. `MapService Offline Presets Tests`: Kiểm thử bộ từ điển địa danh offline không phụ thuộc internet.
5. `Map App smoke test - renders title and actions`: Kiểm thử render các thành phần giao diện, phím chức năng và bản đồ.

Kiểm tra phân tích mã nguồn linter:
```bash
flutter analyze
```
*Kết quả:* **No issues found! (0 lỗi, 0 cảnh báo).**

---

### 5.3. Kịch bản kiểm thử đề xuất dành cho Giảng viên

* **Kịch bản 1 — Kiểm thử Bản đồ nền & Tuyến đường mặc định (Question 1 & Question 2):**
  - Mở app: Bản đồ đường phố TP.HCM hiển thị sắc nét với sông Sài Gòn, các quận huyện, đường xá đầy đủ.
  - Tuyến đường màu xanh uốn lượn nối từ **Chợ Bến Thành** đến **Landmark 81**.
  - Bảng thông số hiển thị rõ: `4.7 km | 7 phút | Giờ đến (ETA)`.

* **Kịch bản 2 — Kiểm thử tính năng Phóng to, Thu nhỏ và Căn chỉnh (Zoom Controls):**
  - Bấm nút **`[ + ]`**: Bản đồ phóng to, thấy rõ các tuyến phố chi tiết (Lê Lợi, Pasteur, Nguyễn Huệ...).
  - Bấm nút **`[ - ]`**: Bản đồ thu nhỏ bao quát.
  - Bấm nút **`[ ⛶ ]`**: Camera tự động căn góc nhìn để trọn vẹn cả tuyến đường nằm gọn trong màn hình.
  - Bấm nút **`[ 🎯 ]`**: Camera tự động bay về điểm xuất phát (Chợ Bến Thành).

* **Kịch bản 3 — Kiểm thử Thay đổi Điểm đến hoặc Điểm đi (Interactive Pin Picking):**
  - Chạm vào một vị trí bất kỳ trên bản đồ: Tuyến đường màu xanh lập tức được vẽ lại theo tọa độ mới, số km và phút cập nhật ngay.
  - Bấm chọn tab `[ 🔵 Điểm đi (A) ]` ➔ Chạm vào vị trí khác: Điểm xuất phát được dời đi và lộ trình tự động tính toán lại.

* **Kịch bản 4 — Kiểm thử Hoán đổi 2 chiều (Swap Direction):**
  - Bấm nút icon đảo chiều **`[ ⇅ ]`** cạnh ô tìm kiếm:
  - Kết quả: Vị trí của Điểm đi và Điểm đến hoán đổi cho nhau tức thì, xe quay đầu và lộ trình được tính toán lại theo chiều ngược lại.

* **Kịch bản 5 — Kiểm thử Tìm kiếm địa điểm (Search Geocoding):**
  - Gõ vào ô tìm kiếm: `khu cong nghe cao` rồi bấm Enter (hoặc icon mũi tên).
  - Kết quả: Camera tự động di chuyển đến Khu Công Nghệ Cao TP.HCM (Quận 9) và lộ trình đường dài được cập nhật.

* **Kịch bản 6 — Kiểm thử Mô phỏng xe chạy thời gian thực (Question 3 - Real-time GPS):**
  - Bấm nút **"Mô phỏng xe chạy (Q3)"**.
  - Kết quả: Biểu tượng ô tô xanh di chuyển mượt mà bám sát từng khúc cua của con đường, camera tự động lia theo xe, nhãn `GPS Live` hiển thị nổi bật.
  - Khi xe đến đích (hoặc khi bấm **"Dừng GPS"**), ứng dụng hiển thị thông báo đã đến nơi và tự động ngắt timer an toàn.
