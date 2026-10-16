# preload_img_vid

Ứng dụng Flutter demo các kỹ thuật **preload ảnh, GIF và video** để cuộn/vuốt mượt, hiển thị gần như tức thì — lấy cảm hứng từ cách Facebook Stories preload nội dung.

Dữ liệu lấy từ file mock JSON (`assets/mock/home_recommends.json`), không cần backend.

## Tính năng

Ứng dụng có 3 tab (bottom navigation, giữ state bằng `IndexedStack`):

| Tab   | Nội dung | Kỹ thuật chính |
|-------|----------|----------------|
| Image | Danh sách category, mỗi category là một list ngang các template card | `CachedNetworkImage` + `memCacheWidth` để giảm RAM, skeleton/shimmer khi loading, pull-to-refresh |
| Gif   | Grid các template có `previewGifUrl` (loại trùng theo `id`) | Precache 8 cover đầu tiên trước khi người dùng cuộn tới |
| Video | Grid cover video; chạm vào một item để mở viewer toàn màn hình | Precache cover + `VideoPreloader` cho viewer vuốt dọc |

### Video viewer (preload kiểu Facebook Stories)

Mở từ tab Video, vuốt dọc để chuyển video. [video_preloader.dart](lib/features/video/presentation/controllers/video_preloader.dart) quản lý một cửa sổ nhỏ các `VideoPlayerController`:

- **Cửa sổ tối đa 3 controller**: `current → next → prev`, không preload xa hơn.
- **Init tuần tự** theo thứ tự ưu tiên để các video không tranh băng thông.
- **Hủy khi vuốt nhanh**: init hoàn tất sau khi đã vuốt qua (không còn trong cửa sổ) sẽ bị bỏ và dispose ngay (cơ chế `_generation`).
- **Network-aware** (`connectivity_plus`): Wi-Fi/Ethernet preload cả `next` và `prev`; mobile data chỉ init video hiện tại.
- **Cover có sẵn từ grid** nên hiện ngay, không có khung đen trong lúc video khởi tạo.
- Dispose toàn bộ controller khi rời viewer; lỗi có thể retry.

Thiết kế chi tiết: [plan/phase2_video_viewer.md](plan/phase2_video_viewer.md).

## Yêu cầu

- Flutter **3.44.4** (ghim qua [FVM](https://fvm.app) trong `.fvmrc`)
- Dart SDK `^3.12.2`
- Android Studio/Xcode hoặc thiết bị/emulator tương ứng

## Chạy project

```bash
# Dùng FVM (khuyến nghị)
fvm install
fvm flutter pub get
fvm flutter run

# Hoặc dùng Flutter đã cài sẵn (đúng phiên bản)
flutter pub get
flutter run
```

Kiểm tra code:

```bash
fvm flutter analyze
fvm flutter test
```

> Video và ảnh được tải từ mạng, cần kết nối Internet khi chạy.

## Cấu trúc thư mục

Clean architecture theo feature, dùng `ChangeNotifier` cho state và composition root thủ công.

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── di/injector.dart        # composition root (tạo repository, usecase, controller)
│   ├── error/failure.dart
│   ├── theme/app_theme.dart
│   ├── usecase/                # UseCase, Result (Success / Error)
│   └── widgets/shimmer.dart
└── features/
    ├── main/                   # BottomNavigation 3 tab
    ├── home/                   # tab Image: data (datasource, model, repo) / domain / presentation
    ├── explore/                # tab Gif
    ├── video/                  # tab Video: grid, viewer, VideoPreloader
    └── profile/
assets/mock/home_recommends.json  # dữ liệu mock
plan/                             # tài liệu thiết kế
```

## Dependencies chính

- [`cached_network_image`](https://pub.dev/packages/cached_network_image) — cache ảnh trên đĩa và RAM
- [`video_player`](https://pub.dev/packages/video_player) — phát video
- [`connectivity_plus`](https://pub.dev/packages/connectivity_plus) — nhận biết loại mạng để quyết định preload

## Ngoài phạm vi / hướng phát triển

- Cache file video lâu dài trên đĩa (cache proxy / `flutter_cache_manager`).
- Prefetch video ngay từ grid khi người dùng dừng trên item.
- Pool tái sử dụng controller (hiện `video_player` không hỗ trợ đổi nguồn nên mỗi item một controller).
