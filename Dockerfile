FROM python:3.9-slim-buster as build

WORKDIR /opt/CTFd

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libffi-dev \
        libssl-dev \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && python -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

COPY . /opt/CTFd

RUN pip install --no-cache-dir -r requirements.txt \
    && for d in CTFd/plugins/*; do \
        if [ -f "$d/requirements.txt" ]; then \
            pip install --no-cache-dir -r "$d/requirements.txt";\
        fi; \
    done;


FROM python:3.9-slim-buster as release
WORKDIR /tmp/CTFd

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libffi6 \
        libssl1.1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --chown=1001:1001 . /tmp/CTFd

RUN useradd \
    --no-log-init \
    --shell /bin/bash \
    -u 1001 \
    ctfd \
    && mkdir -p /tmp/log/CTFd /tmp/uploads \
    && chown -R 1001:1001 /tmp/log/CTFd /tmp/uploads /tmp/CTFd \
    && chmod +x /tmp/CTFd/docker-entrypoint.sh

COPY --chown=1001:1001 --from=build /opt/venv /tmp/venv
ENV PATH="/tmp/venv/bin:$PATH"

USER 1001
EXPOSE 8000
ENTRYPOINT ["/tmp/CTFd/docker-entrypoint.sh"]
