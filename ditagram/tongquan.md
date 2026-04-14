```mermaid
graph TB
    subgraph "Giao diện (Frontend)"
        User((Nhân viên)) <--> App[Flutter App]
    end

    subgraph "Máy chủ (Backend - Python/FastAPI)"
        App <--> API[API Endpoint]
        API <--> RAG[RAG Engine]
        RAG <--> OCR[OCR - Trích xuất PDF/Ảnh]
    end

    subgraph "Lưu trữ & AI"
        RAG <--> VDB[(Vector Database - ChromaDB)]
        RAG <--> LLM[OpenAI API / GPT-4]
        API <--> SQL[(PostgreSQL - Lưu User/Lịch sử)]
    end