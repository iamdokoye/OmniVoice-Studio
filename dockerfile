# syntax=docker/dockerfile:1
FROM oven/bun:1-alpine AS frontend-builder
WORKDIR /app
COPY package.json bun.lock ./
COPY frontend/package.json ./frontend/
RUN bun install --frozen-lockfile
COPY frontend/ ./frontend/
RUN bun run --cwd frontend build

FROM python:3.11-slim
WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_SYSTEM_PYTHON=1 \
    HF_HOME=/app/omnivoice_data/huggingface \
    PYTHONPATH=/app/backend \
    OMNIVOICE_SERVER_MODE=1 \
    OMNIVOICE_BIND_HOST=0.0.0.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg libsndfile1 curl build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir torch torchaudio \
    --index-url https://download.pytorch.org/whl/cpu

RUN pip install --no-cache-dir torchcodec

RUN pip install --no-cache-dir uv

COPY pyproject.toml uv.lock README.md patch_pyproject.py ./

RUN python3 patch_pyproject.py

RUN rm -f uv.lock && uv pip install --system --no-cache .

COPY backend/ ./backend/
RUN sed -i '/torchaudio\.set_audio_backend/d' /app/backend/main.py

COPY omnivoice/ ./omnivoice/
COPY --from=frontend-builder /app/frontend/dist ./frontend/dist

VOLUME ["/app/omnivoice_data"]
EXPOSE 3900
ENTRYPOINT ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "3900"]
