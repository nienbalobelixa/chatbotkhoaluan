import os
import shutil
from langchain_community.document_loaders import PyPDFLoader, DirectoryLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma

# ==============================
# 📂 PATH CHUẨN
# ==============================
DATA_PATH = "documents"     # 👉 nơi chứa PDF
DB_DIR = "vector_db"        # 👉 nơi lưu vector

# ==============================
# 🧠 EMBEDDING (PHẢI GIỐNG RAG)
# ==============================
model_name = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"

embedding = HuggingFaceEmbeddings(
    model_name=model_name,
    model_kwargs={'device': 'cpu'}
)

# ==============================
# 🚀 INGEST FUNCTION
# ==============================
def create_db():
    # 🔍 Check thư mục documents
    if not os.path.exists(DATA_PATH):
        print(f"❌ Không tìm thấy thư mục {DATA_PATH}")
        return

    pdf_files = [f for f in os.listdir(DATA_PATH) if f.endswith('.pdf')]

    if not pdf_files:
        print(f"⚠️ Không có file PDF trong {DATA_PATH}")
        return

    print(f"📥 Đang nạp {len(pdf_files)} file PDF...")

    # ==============================
    # 📄 LOAD FILE
    # ==============================
    loader = DirectoryLoader(
        DATA_PATH,
        glob="**/*.pdf",   # 🔥 FIX: load tất cả file con
        loader_cls=PyPDFLoader
    )

    documents = loader.load()
    print(f"📄 Tổng số trang: {len(documents)}")

    # ==============================
    # ✂️ CHIA TEXT
    # ==============================
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=500,
        chunk_overlap=50
    )

    chunks = text_splitter.split_documents(documents)
    print(f"✂️ Tổng chunks: {len(chunks)}")

    # ==============================
    # 🧹 XOÁ DB CŨ (QUAN TRỌNG)
    # ==============================
    if os.path.exists(DB_DIR):
        print("🗑 Xoá vector DB cũ...")
        shutil.rmtree(DB_DIR)

    # ==============================
    # 💾 LƯU DB
    # ==============================
    db = Chroma.from_documents(
        documents=chunks,
        embedding=embedding,
        persist_directory=DB_DIR
    )

    print(f"✅ Đã tạo vector DB tại: {DB_DIR}")


# ==============================
# ▶️ RUN
# ==============================
if __name__ == "__main__":
    create_db()