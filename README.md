# Danh mục tin tức (Flutter)

Ứng dụng hiển thị tin tức theo danh mục từ `https://newsapi.org/` với 3 trạng thái UI bắt buộc:
- Loading: hiển thị `CircularProgressIndicator`.
- Success: hiển thị danh sách tin dạng `ListView` + `Card`.
- Error + Retry: hiển thị thông báo lỗi và nút `Thử lại` để gọi API lại.

## Cấu trúc mã nguồn
- `lib/models/news_article.dart`: model dữ liệu bài viết.
- `lib/services/news_api_service.dart`: gọi API bằng `try-catch`.
- `lib/screens/news_home_screen.dart`: giao diện và xử lý trạng thái.
- `lib/main.dart`: điểm vào ứng dụng.

## Cách chạy
1. API key đã được cấu hình trực tiếp trong service.
2. Chạy ứng dụng:

```bash
flutter run
```
