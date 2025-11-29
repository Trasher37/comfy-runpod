# ==============================================================================
# IMAGE DE BASE : Optimisée pour RTX 5090 (CUDA 12.8)
# ==============================================================================
FROM runpod/worker-comfyui:5.5.0-base-cuda12.8.1

# ==============================================================================
# 1. PRÉ-REQUIS SYSTÈME (AVEC OUTILS DE COMPILATION)
# ==============================================================================
# 'build-essential' et 'python3-dev' sont vitaux pour installer SAM2
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3-dev \
    libgl1 \
    libglib2.0-0 \
    libsndfile1 \
    ffmpeg \
    git \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# 2. MISE À JOUR DU CŒUR COMFYUI
# ==============================================================================
RUN /usr/bin/yes | comfy --workspace /comfyui update all

# ==============================================================================
# 3. CONFIGURATION RÉSEAU
# ==============================================================================
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml

# ==============================================================================
# 4. INSTALLATION DES NODES DU REGISTRE (CNR)
# ==============================================================================
RUN comfy node install \
    comfyui-manager \
    comfyui-kjnodes \
    comfyui-easy-use \
    comfyui_controlnet_aux \
    comfyui-videohelpersuite \
    comfyui-impact-pack \
    comfyui-inspire-pack \
    rgthree-comfy \
    comfyui-depthanythingv2 \
    comfyui-detail-daemon \
    comfyui-mixlab-nodes \
    comfyui_ultimatesdupscale \
    comfyui-automaticcfg \
    comfyui-custom-scripts \
    comfyui_ipadapter_plus \
    comfyui-animatediff-evolved \
    comfyui-reactor-node

# ==============================================================================
# 5. INSTALLATION MANUELLE STANDARDISÉE (NODES GIT)
# ==============================================================================
WORKDIR /comfyui/custom_nodes

# --- 1. Painter I2V ---
RUN git clone https://github.com/princepainter/ComfyUI-PainterI2V.git && \
    cd ComfyUI-PainterI2V && \
    git checkout 63f61e0b7729d91e12a518f8a33a329794e75890 && \
    if [ -f requirements.txt ]; then \
        sed -i 's/[<>=]=.*//' requirements.txt && \
        sed -i '/torch/d' requirements.txt && \
        pip install -r requirements.txt; \
    fi && cd ..

# --- 2. Painter Sampler ---
RUN git clone https://github.com/princepainter/Comfyui-PainterSampler.git && \
    cd Comfyui-PainterSampler && \
    git checkout fc7cbf5b8cc9766edc7175c405625f15329ebb48 && \
    if [ -f requirements.txt ]; then \
        sed -i 's/[<>=]=.*//' requirements.txt && \
        sed -i '/torch/d' requirements.txt && \
        pip install -r requirements.txt; \
    fi && cd ..

# --- 3. ComfyRoll ---
RUN git clone