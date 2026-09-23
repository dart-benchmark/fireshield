FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    EASYOCR_MODEL_DIR=/app/.easyocr \
    PORT=8080

RUN apt-get update \
    && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 tesseract-ocr \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -u 1000 user

WORKDIR /app
COPY pyproject.toml README.md ./
COPY src ./src
# The [ocr] extra is pytesseract now — a thin wrapper around the apt package
# above, no model weights to pre-download and no PyTorch pulled in for it.
RUN pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu torch torchvision \
    && pip install --no-cache-dir ".[service,ocr]"
RUN chown -R user:user /app

USER user

EXPOSE 8080
CMD ["sh", "-c", "exec uvicorn floorplan2dxf.api:app --host 0.0.0.0 --port ${PORT:-8080} --workers 1"]
