import os
from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings

# ==============================
# 1. CONFIG EMBEDDING MODEL
# ==============================
model_name = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"

model_kwargs = {
    "device": "cpu"  # đảm bảo chạy mọi máy
}

encode_kwargs = {
    "normalize_embeddings": False
}

embeddings = HuggingFaceEmbeddings(
    model_name=model_name,
    model_kwargs=model_kwargs,
    encode_kwargs=encode_kwargs
)

# ==============================
# 2. DB PATH
# ==============================
CHROMA_PATH = "vector_db"


# ==============================
# 3. SEARCH FUNCTION (FIX FULL)
# ==============================
def search_docs(query):
    """
    Tìm kiếm tài liệu liên quan và TRẢ TEXT + SOURCE rõ ràng cho frontend
    """
    try:
        # ❌ Nếu chưa có DB
        if not os.path.exists(CHROMA_PATH) or not os.listdir(CHROMA_PATH):
            print(f"❌ Chưa có dữ liệu trong {CHROMA_PATH}")
            return {
                "answer": "⚠️ Chưa có dữ liệu tài liệu. Vui lòng upload PDF trước.",
                "sources": []
            }

        # ✅ Load DB
        db = Chroma(
            persist_directory=CHROMA_PATH,
            embedding_function=embeddings
        )

        # ✅ Search
        docs = db.similarity_search(query, k=3)

        print(f"🔍 Query: {query}")
        print(f"📄 Tìm thấy {len(docs)} đoạn")

        # ❌ Không có kết quả
        if not docs:
            return {
                "answer": "❌ Không tìm thấy thông tin liên quan.",
                "sources": []
            }

        # ==============================
        # 🔥 GHÉP NỘI DUNG TRẢ VỀ
        # ==============================
        contents = []
        sources = []

        for doc in docs:
            content = doc.page_content.strip()

            raw_source = doc.metadata.get("source", "Tài liệu nội bộ")
            source_name = os.path.basename(raw_source)

            page = doc.metadata.get("page", 0) + 1

            contents.append(content)
            sources.append(f"{source_name} (trang {page})")

        # 🔥 Ghép thành 1 đoạn trả về cho Flutter
        final_answer = "\n\n---\n\n".join(contents)

        print("✅ Nội dung trả về:")
        print(final_answer[:300])  # preview

        return {
            "answer": final_answer,
            "sources": list(set(sources))  # remove trùng
        }

    except Exception as e:
        print(f"❌ Lỗi search_docs: {e}")

        return {
            "answer": "❌ Lỗi khi truy vấn dữ liệu.",
            "sources": []
        }