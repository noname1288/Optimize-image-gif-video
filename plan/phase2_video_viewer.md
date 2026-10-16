# Giai đoạn 2 — Video viewer với preload kiểu Facebook Stories

## Mục tiêu

Từ tab Video (tab 3), click 1 item → mở viewer full-screen, vuốt dọc để chuyển video
(như Stories). Video kế tiếp được preload để khi vuốt tới là phát gần như ngay.

## Kiến trúc

```
VideoPage (grid)
  └─ onTap(i) ──► VideoViewerPage(templates, startIndex)
                    ├─ PageView dọc (mỗi trang: cover → video khi sẵn sàng)
                    └─ VideoPreloader  (quản lý cửa sổ player + hàng đợi)
```

## Ánh xạ chiến lược Facebook Stories

| Chiến lược Facebook            | Áp dụng                                                                |
|--------------------------------|------------------------------------------------------------------------|
| Preload item kế tiếp           | Sau khi `current` ready → `initialize()` controller `next`              |
| Partial preload                | Player tự buffer vài giây đầu khi init (tương đương partial preload)   |
| Ưu tiên theo khoảng cách       | Hàng đợi init tuần tự `current → next → prev`, sắp lại mỗi lần vuốt    |
| Hủy khi vuốt nhanh             | Item đã vuốt qua mà chưa init xong → bỏ kết quả + dispose              |
| Giới hạn số lượng              | Cửa sổ tối đa 3 controller, không preload xa hơn                        |
| Network-aware                  | Mobile data: chỉ `current`. Wi-Fi/Ethernet: thêm `next`, `prev`         |
| Player warm sẵn                | Controller `next` đã init → vuốt tới là `play()` ngay                   |
| Cover luôn có sẵn              | Cover đã nằm trong cache từ grid → hiện tức thì, không khung đen        |

## Các bước

### Bước 1 — Dependency
- `fvm flutter pub add video_player connectivity_plus`
- iOS: kiểm tra URL video trong mock là HTTPS; nếu không, thêm `NSAppTransportSecurity`
  vào `ios/Runner/Info.plist`.
- Android: đảm bảo có `INTERNET` permission trong `AndroidManifest.xml` (main).

### Bước 2 — `VideoPreloader`
File: `lib/features/video/presentation/controllers/video_preloader.dart`

- Input: `List<TemplateEntity>`. State: `Map<int, VideoPlayerController>` (cửa sổ).
- `focus(int index)` — gọi mỗi khi trang đổi:
  1. Tính cửa sổ `{index, index+1, index-1}` (clamp theo độ dài list; nếu
     `allowPreload == false` thì chỉ `{index}`).
  2. Dispose controller ngoài cửa sổ.
  3. Init tuần tự theo thứ tự `current → next → prev` (item sau chỉ bắt đầu khi item
     trước xong) để không tranh băng thông.
  4. Token `_generation` tăng mỗi lần `focus`. Init xong mà generation đã cũ và index
     không còn trong cửa sổ → dispose ngay (hủy khi vuốt nhanh).
- `controllerOf(int index)` → controller nếu đã initialized, ngược lại `null`.
- `errorOf(int index)` / `retry(int index)` cho trang hiện tại.
- `ChangeNotifier`: notify khi một controller init xong hoặc lỗi.
- `dispose()`: dispose tất cả controller + hủy subscription connectivity.

### Bước 3 — `VideoViewerPage`
File: `lib/features/video/presentation/pages/video_viewer_page.dart`

- Params: `templates`, `initialIndex`.
- `PageView.builder` dọc, `PageController(initialPage: initialIndex)`.
- `onPageChanged(i)`: `preloader.focus(i)`, pause trang cũ, play trang mới.
- Mỗi trang là `Stack`:
  - Cover (`CachedNetworkImage`) — luôn ở dưới cùng.
  - `VideoPlayer` khi controller ready (fade-in, `AspectRatio` theo video).
  - Spinner nhỏ nếu là trang hiện tại và chưa ready.
  - Lỗi: icon + nút retry (chỉ trang hiện tại).
- Video `setLooping(true)`; tap để pause/play; nút back.
- Lifecycle: `WidgetsBindingObserver` → pause khi app background, resume khi quay lại.
  Dispose preloader khi rời trang.

### Bước 4 — Nối từ grid
- `video_page.dart`: truyền `onTap` cho `ExploreGridItem` →
  `Navigator.push(VideoViewerPage(templates: ..., initialIndex: i))`.

### Bước 5 — Network-aware
- Trong `VideoPreloader`: đọc `Connectivity().checkConnectivity()` lúc khởi tạo,
  lắng nghe `onConnectivityChanged` để cập nhật `allowPreload`.
- Khi chuyển từ mobile → Wi-Fi: gọi lại `focus(current)` để bổ sung preload.

### Bước 6 — Kiểm tra
- `fvm flutter analyze` sạch.
- Kiểm thử thủ công:
  1. Mở item, vuốt sang item kế → video phát gần như ngay.
  2. Vuốt nhanh qua 5–6 item → không leak controller (log dispose / DevTools memory).
  3. Thoát viewer → không còn âm thanh, mọi controller đã dispose.
  4. Tắt Wi-Fi (mobile data) → chỉ init `current`.
  5. App vào background → video pause.

## File thay đổi

| File                                                              | Loại            |
|-------------------------------------------------------------------|-----------------|
| `pubspec.yaml`                                                    | sửa             |
| `lib/features/video/presentation/controllers/video_preloader.dart`| mới             |
| `lib/features/video/presentation/pages/video_viewer_page.dart`    | mới             |
| `lib/features/video/presentation/pages/video_page.dart`           | sửa (`onTap`)   |
| `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml`| sửa nếu cần     |

## Ngoài phạm vi (giai đoạn sau)

- Cache file video lâu dài trên đĩa (cần cache proxy, vd `flutter_cache_manager` +
  local server / `video_player` với file đã tải đủ).
- Prefetch video ngay từ grid khi user dừng trên item (dwell > 300ms).
- Pool tái sử dụng controller — `video_player` không hỗ trợ đổi nguồn, nên mỗi item
  một controller.
