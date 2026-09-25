# The demo image: a dst release plus in-process embeddings, weights baked in.
#
# serve/dst.yaml declares `embed: {type: local}`. The stock image is weight-free, so
# certified matching would report unavailable. This layer adds the local-embed extra
# and downloads the model at build time: a cold start never fetches from Hugging Face.
#
#   docker build -f deploy/Dockerfile --build-arg BASE=<a dst image> -t dota-demo deploy
ARG BASE=ghcr.io/get-dst/dst:0.5.2
FROM ${BASE}
USER root
# No-op when the base was already built with UV_EXTRA=local-embed.
RUN uv sync --frozen --no-dev --extra local-embed
ENV FASTEMBED_CACHE_PATH=/opt/dst/fastembed
RUN mkdir -p "$FASTEMBED_CACHE_PATH" \
 && python -c "from services.context.local_embedder import LocalEmbedder; LocalEmbedder().embed(['warm'])" \
 && chmod -R a+rX /opt/dst
USER 10001
