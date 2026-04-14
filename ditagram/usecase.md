```mermaid
flowchart TD
    Start([Bắt đầu]) --> Upload[Tải file PDF nội bộ lên]
    Upload --> Check{Loại file?}
    Check -- PDF Text --> Extract[Trích xuất bằng PyMuPDF]
    Check -- PDF Scan/Ảnh --> OCR[Xử lý bằng PaddleOCR]
    
    Extract --> Chunk[Cắt nhỏ văn bản - RecursiveChunking]
    OCR --> Chunk
    
    Chunk --> Embed[Chuyển thành Vector - OpenAI Embedding]
    Embed --> Save[(Lưu vào ChromaDB)]
    Save --> End([Hoàn thành nạp tri thức])