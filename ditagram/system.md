```mermaid
graph TB
    subgraph "Người dùng (Flutter)"
        A[Bắt đầu: Nhập yêu cầu/Gửi file] --> B[Gửi yêu cầu qua API]
    end

    subgraph "Ứng dụng di động"
        B --> C[Tiếp nhận & Kiểm tra định dạng]
        C --> D[Gửi yêu cầu đến Server]
    end

    subgraph "Backend Server (FastAPI)"
        D --> E[Xử lý yêu cầu từ App]
        E --> F{Kiểm tra quyền truy cập}
        F -- "Hợp lệ" --> G[Trích xuất Vector từ DB]
        F -- "Không hợp lệ" --> H[Báo lỗi quyền hạn]
        G --> I[Tạo Prompt Engineering]
        I --> J[Gọi OpenAI/Gemini API]
    end

    subgraph "Cơ sở dữ liệu / AI"
        J --> K[AI Xử lý & Phản hồi]
        K --> L[Trả kết quả JSON]
        L --> M[Lưu lịch sử vào enterprise.db]
    end

    M --> N[Nhận phản hồi & Hiển thị]
    N --> O((Kết thúc))

    %% Kết nối các làn
    H --> N