```mermaid
sequenceDiagram
    participant U as Nhân viên
    participant F as Flutter App
    participant B as Backend (Python)
    participant VDB as Vector DB
    participant AI as OpenAI

    U->>F: Nhập câu hỏi (Ví dụ: Quy định nghỉ phép)
    F->>B: Gửi câu hỏi qua API
    B->>B: Biến câu hỏi thành Vector
    B->>VDB: Tìm kiếm các đoạn văn bản liên quan nhất
    VDB-->>B: Trả về 3-5 đoạn văn bản khớp nhất
    
    Note over B, AI: Prompt = "Dựa vào thông tin này: [Văn bản], trả lời: [Câu hỏi]"
    
    B->>AI: Gửi Prompt tối ưu
    AI-->>B: Trả về câu trả lời đã tổng hợp
    B-->>F: Trả về text + Nguồn (Tên file, trang)
    F-->>U: Hiển thị câu trả lời cho nhân viên