# ═══════════════════════════════════════════════════════════════════
# CP2 — Dockerfile production-ready (Multi-stage build)
# ═══════════════════════════════════════════════════════════════════

# Stage 1: Builder
FROM python:3.11-slim AS builder

WORKDIR /app

# Copy requirements.txt và cài dependencies trước để tận dụng cache
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim AS runtime

WORKDIR /app

# Copy các package đã install từ builder sang
COPY --from=builder /install /usr/local

# Tạo non-root user và set permission
RUN useradd --create-home --uid 10001 appuser

# Copy toàn bộ source code
COPY . .
RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health').read()" || exit 1

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
