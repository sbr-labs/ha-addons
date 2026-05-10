ARG BUILD_FROM=python:3.12-slim
FROM ${BUILD_FROM}

# Build deps for pyremoteplay's C extensions on archs without prebuilt
# wheels (notably armv7l on Pi 3 / Pi 4 32-bit). On amd64/arm64 the wheels
# exist and the compile step is a no-op — apt install is wasted ~30s but
# harmless.
RUN apt-get update && apt-get install -y --no-install-recommends \
      gcc libc6-dev libffi-dev libssl-dev curl jq \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY daemon.py psn_presence.py pair.py oauth_helper.py run.sh default-home-image.png ./
RUN chmod +x run.sh

ENV PYTHONUNBUFFERED=1
CMD [ "/app/run.sh" ]
