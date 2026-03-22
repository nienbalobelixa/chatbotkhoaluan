import os
import sqlite3
import requests
import shutil
import subprocess
from fastapi import FastAPI, UploadFile, File
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from passlib.context import CryptContext
from rag import search_docs 
import uvicorn

app = FastAPI()

# ==============================
# 🔥 CORS FIX
# ==============================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==============================
# CONFIG
# ==============================
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
LMSTUDIO_URL = "http://localhost:1234/v1/chat/completions"
DATA_FOLDER = "vector_db"

# ==============================
# INIT DB
# ==============================
def init_db():
    conn = sqlite3.connect('enterprise.db')
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS users 
                 (id INTEGER PRIMARY KEY AUTOINCREMENT, 
                  username TEXT UNIQUE, password TEXT)''')
    conn.commit()
    conn.close()

if not os.path.exists(DATA_FOLDER):
    os.makedirs(DATA_FOLDER)

init_db()

# ==============================
# MODELS
# ==============================
class User(BaseModel):
    username: str
    password: str

class Question(BaseModel):
    question: str


# ==============================
# AUTH
# ==============================
@app.post("/register")
async def register(user: User):
    hashed = pwd_context.hash(user.password)
    try:
        conn = sqlite3.connect('enterprise.db')
        c = conn.cursor()
        c.execute("INSERT INTO users (username, password) VALUES (?, ?)", (user.username, hashed))
        conn.commit()
        conn.close()
        return {"status": "success"}
    except:
        return {"status": "error", "message": "Username đã tồn tại"}

@app.post("/login")
async def login(user: User):
    conn = sqlite3.connect('enterprise.db')
    c = conn.cursor()
    c.execute("SELECT password FROM users WHERE username = ?", (user.username,))
    record = c.fetchone()
    conn.close()

    if record and pwd_context.verify(user.password, record[0]):
        return {"status": "success", "username": user.username}

    return {"status": "error", "message": "Sai tài khoản hoặc mật khẩu"}


# ==============================
# 🔥 CHAT RAG FIX FULL
# ==============================
@app.post("/ask")
def ask_ai(data: Question):
    try:
        print(f"📥 Question: {data.question}")

        # ✅ Lấy kết quả từ RAG (ĐÃ FIX FORMAT)
        rag_result = search_docs(data.question)

        context_text = rag_result.get("answer", "")
        sources = rag_result.get("sources", [])

        print("📄 Context:")
        print(context_text[:300])

        # ❌ Nếu không có context → trả luôn
        if not context_text.strip():
            return {
                "answer": "❌ Không tìm thấy thông tin trong tài liệu.",
                "sources": []
            }

        # ==============================
        # 🔥 CALL LM STUDIO
        # ==============================
        payload = {
            "model": "google/gemma-3-4b",
            "messages": [
                {
                    "role": "system",
                    "content": "Bạn là trợ lý HR chuyên nghiệp. Trả lời ngắn gọn, đúng trọng tâm, dựa trên tài liệu."
                },
                {
                    "role": "user",
                    "content": f"Ngữ cảnh:\n{context_text}\n\nCâu hỏi: {data.question}"
                }
            ],
            "temperature": 0.2
        }

        response = requests.post(LMSTUDIO_URL, json=payload, timeout=60)

        print("📡 LM STATUS:", response.status_code)

        if response.status_code != 200:
            print("❌ LM lỗi:", response.text)
            return {
                "answer": context_text,  # fallback luôn
                "sources": sources
            }

        result = response.json()

        answer = (
            result.get("choices", [{}])[0]
            .get("message", {})
            .get("content", "")
        )

        print("🤖 Answer:", answer[:200])

        # 🔥 Nếu LM không trả → fallback RAG
        if not answer.strip():
            answer = context_text

        return {
            "answer": answer,
            "sources": sources
        }

    except Exception as e:
        print(f"❌ Lỗi Ask AI: {e}")

        return {
            "answer": "❌ Backend lỗi, kiểm tra lại server hoặc LM Studio!",
            "sources": []
        }


# ==============================
# FILE MANAGEMENT
# ==============================
@app.get("/documents")
async def get_documents():
    files = []
    if os.path.exists(DATA_FOLDER):
        for f in os.listdir(DATA_FOLDER):
            if f.endswith(".pdf"):
                path = os.path.join(DATA_FOLDER, f)
                files.append({
                    "name": f,
                    "size": f"{os.path.getsize(path) // 1024} KB"
                })
    return files


@app.post("/upload")
async def upload_document(file: UploadFile = File(...)):
    try:
        file_path = os.path.join(DATA_FOLDER, file.filename)

        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        print("📥 Upload:", file.filename)

        subprocess.run("python ingest.py", shell=True)

        return {"status": "success"}

    except Exception as e:
        print(f"❌ Upload lỗi: {e}")
        return {"status": "error", "message": str(e)}


@app.delete("/documents/{filename}")
async def delete_document(filename: str):
    file_path = os.path.join(DATA_FOLDER, filename)

    try:
        if os.path.exists(file_path):
            os.remove(file_path)

            print("🗑 Deleted:", filename)

            subprocess.run("python ingest.py", shell=True)

            return {"status": "success"}

        return {"status": "error", "message": "File không tồn tại"}

    except Exception as e:
        return {"status": "error", "message": str(e)}


# ==============================
# RUN SERVER
# ==============================
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)