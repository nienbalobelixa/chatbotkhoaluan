import os
import shutil
from langchain_community.document_loaders import DirectoryLoader, PyPDFLoader
from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter

# ==============================
# 📂 CONFIG
# ==============================
DOCS_PATH = "documents"
DB_PATH = "vector_db"

# ==============================
# 🧠 EMBEDDING MODEL (ĐỒNG BỘ VỚI RAG)
# ==============================
embedding = HuggingFaceEmbeddings(
    model_name="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
    model_kwargs={"device": "cpu"}
)

# ==============================
# 🔥 LOAD FILE PDF
# ==============================
def load_documents():
    if not os.path.exists(DOCS_PATH):
        print(f"❌ Không tìm thấy thư mục {DOCS_PATH}")
        return []

    loader = DirectoryLoader(
        DOCS_PATH,
        glob="**/*.pdf",   # 🔥 FIX: load toàn bộ file con
        loader_cls=PyPDFLoader
    )

    documents = loader.load()
    print(f"📄 Đã load {len(documents)} trang từ PDF")
    return documents


# ==============================
# ✂️ CHIA NHỎ TEXT
# ==============================
def split_text(documents):
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=100
    )

    docs = text_splitter.split_documents(documents)
    print(f"✂️ Đã chia thành {len(docs)} chunks")
    return docs


# ==============================
# 🧹 XOÁ DB CŨ (TRÁNH LỖI CACHE)
# ==============================
def clear_db():
    if os.path.exists(DB_PATH):
        print("🗑 Đang xoá DB cũ...")
        shutil.rmtree(DB_PATH)


# ==============================
# 💾 LƯU VECTOR DB
# ==============================
def save_to_db(docs):
    db = Chroma.from_documents(
        documents=docs,
        embedding=embedding,
        persist_directory=DB_PATH
    )

    print("💾 Đã lưu vào vector_db")
    print(f"📊 Tổng chunks: {len(docs)}")


# ==============================
# 🚀 MAIN
# ==============================
def main():
    print("🚀 BẮT ĐẦU INGEST DATA...\n")

    documents = load_documents()

    if not documents:
        print("❌ Không có tài liệu để xử lý")
        return

    docs = split_text(documents)

    # 🔥 FIX QUAN TRỌNG: luôn clear DB để tránh lỗi dữ liệu cũ
    clear_db()

    save_to_db(docs)

    print("\n✅ INGEST HOÀN TẤT!")


if __name__ == "__main__":
    main()