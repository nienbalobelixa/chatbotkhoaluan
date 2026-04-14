```mermaid
erDiagram
    USER ||--o{ CHAT_HISTORY : "tạo ra"
    USER {
        string user_id PK
        string email
        string password
        string department
    }
    CHAT_HISTORY {
        int chat_id PK
        string user_id FK
        string question
        string answer
        datetime created_at
    }
    DOCUMENT ||--o{ CHUNKS : "chia nhỏ thành"
    DOCUMENT {
        int doc_id PK
        string file_name
        datetime upload_date
    }