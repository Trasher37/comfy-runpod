# ==============================================================================
# IMAGE DE BASE : Optimisée pour RTX 5090 (CUDA 12.8) - Version 5.5.1
# ==============================================================================
FROM runpod/worker-comfyui:5.5.1-base-cuda12.8.1

# ==============================================================================
# 1. PRÉ-REQUIS SYSTÈME (VITAL)
# ==============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libsndfile1 \
    ffmpeg \
    git \
    cmake \
    build-essential \
    python3-dev \
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
# 4. INSTALLATION DES NODES DU REGISTRE (CNR) - AUTOMATIQUE
# ==============================================================================
RUN comfy node install \
    comfyui-manager \
    comfyui-kjnodes \
    comfyui-easy-use \
    comfyui_controlnet_aux \
    comfyui-videohelpersuite \
    comfyui-impact-pack \
    comfyui-impact-subpack \
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
    comfyui-reactor-node \
    cg-use-everywhere \
    comfyui-comfyroll

# ==============================================================================
# 5. INSTALLATION MANUELLE (NODES SPÉCIFIQUES)
# ==============================================================================
WORKDIR /comfyui/custom_nodes

# SÉCURITÉ : Mise à jour de pip
RUN pip install --upgrade pip setuptools wheel

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

# --- 3. RES4LYF ---
RUN git clone https://github.com/ClownsharkBatwing/RES4LYF.git && \
    cd RES4LYF && \
    git checkout 46de917234f9fef3f2ab411c41e07aa3c633f4f7 && \
    if [ -f requirements.txt ]; then \
        sed -i 's/[<>=]=.*//' requirements.txt && \
        sed -i '/torch/d' requirements.txt && \
        pip install -r requirements.txt; \
    fi && cd ..

# --- 4. DyPE ---
RUN git clone https://github.com/wildminder/ComfyUI-DyPE.git && \
    cd ComfyUI-DyPE && \
    if [ -f requirements.txt ]; then \
        sed -i 's/[<>=]=.*//' requirements.txt && \
        sed -i '/torch/d' requirements.txt && \
        pip install -r requirements.txt; \
    fi && cd ..

# --- 5. SeedVR2 ---
RUN git clone https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler.git && \
    cd ComfyUI-SeedVR2_VideoUpscaler && \
    if [ -f requirements.txt ]; then \
        sed -i 's/[<>=]=.*//' requirements.txt && \
        sed -i '/torch/d' requirements.txt && \
        pip install -r requirements.txt; \
    fi && cd ..

# ==============================================================================
# 6. DÉPENDANCES PYTHON FINALES
# ==============================================================================
WORKDIR /comfyui

# InsightFace lib
RUN pip install insightface onnxruntime-gpu --no-deps

# ==============================================================================
# 7. FIN
# ==============================================================================
WORKDIR /comfyui