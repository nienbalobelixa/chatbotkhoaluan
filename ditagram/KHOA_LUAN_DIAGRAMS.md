# Sơ đồ Khóa luận Chatbot Nội bộ

## 1. Sơ đồ Hoạt động (Activity Diagram) - Luồng xử lý file PDF
Sơ đồ này mô tả cách hệ thống tiếp nhận và "học" một file tài liệu mới.

```mermaid
stateDiagram-v2
    [*] --> Upload_PDF: User tải file lên
    Upload_PDF --> Check_Type: Kiểm tra định dạng
    
    state Check_Type {
        [*] --> Extract_Text: Trích xuất văn bản (PyMuPDF)
        Extract_Text --> OCR_Needed: Kiểm tra nội dung
        OCR_Needed --> OCR_Process: Nếu là ảnh (Sử dụng PaddleOCR)
        OCR_Process --> Combine
        OCR_Needed --> Combine: Nếu là văn bản chuẩn
    }

    Combine --> Chunking: Chia nhỏ văn bản (RecursiveCharacterTextSplitter)
    Chunking --> Embedding: Chuyển thành Vector (OpenAI Ada-002)
    Embedding --> VectorDB: Lưu vào ChromaDB / Pinecone
    VectorDB --> [*]: Thông báo thành công

    