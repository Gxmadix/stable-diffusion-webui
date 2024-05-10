ARG PYTHON_VERSION=3.10

FROM python:${PYTHON_VERSION}

ARG RELEASE="install-script"
ARG BUILD_ARGS="--use-cpu all --precision full --no-half --skip-torch-cuda-test --xformers"
ARG RUN_ARGS="--use-cpu all --precision full --no-half --skip-torch-cuda-test --skip-version-check --allow-code --enable-insecure-extension-access --api --xformers --opt-channelslast"
ARG PY_TORCH_CMD="pip install torch==2.1.2 torchvision==0.16.2 --extra-index-url https://download.pytorch.org/whl/cu121"
ARG AUTH_USERS=root:password

ENV PYTHONUNBUFFERED="1"

# Install packages
RUN apt-get update && \
    apt-get install -y bc git libgl1 libglib2.0-0 && \
    apt-get install -y wget xdg-user-dirs google-perftools && \
    apt-get clean

# Set up a non-root user (recommended for security)
RUN useradd -ms /bin/bash webui

# clone a git repository into the container
# RUN git clone --depth 1 --branch $RELEASE https://github.com/AUTOMATIC1111/stable-diffusion-webui.git app
RUN git clone --depth 1 -b install-script https://github.com/Gxmadix/stable-diffusion-webui.git app

# Set working directory
WORKDIR /app

RUN pip install -r requirements_versions.txt
RUN bash -c "$PY_TORCH_CMD"

# Give full permissions on /app to the webui user
RUN mkdir /app/repositories
RUN mkdir /app/outputs
RUN chown -R webui:root /app

USER webui

RUN chmod +x webui.sh
RUN chmod +x install.sh
RUN COMMANDLINE_ARGS=$BUILD_ARGS bash ./install.sh

# Models
# ADD https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors models/Stable-diffusion/v1-5-pruned-emaonly.safetensors

# Extensions
RUN git clone --depth 1 https://github.com/Iyashinouta/sd-model-downloader.git sd-model-downloader

ENV PYTORCH_TRACING_MODE TORCHFX
ENV COMMANDLINE_ARGS="--listen --port 7860 --gradio-auth ${AUTH_USERS} ${RUN_ARGS}"

EXPOSE 7860

# Command to run when the container starts
CMD ["bash", "/app/webui.sh"]
