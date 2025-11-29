# ==============================================================================
# IMAGE DE BASE : Optimisée pour RTX 5090 (CUDA 12.8)
# ==============================================================================
FROM runpod/worker-comfyui:5.5.1-base-cuda12.8.1

# ==============================================================================
# 1. PRÉ-REQUIS SYSTÈME (NETTOYAGE MAXIMAL)
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
    && apt-get clean && rm -rf /var/lib/apt/lists/*

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
# Le Manager gère les dépendances et bloque "torch" automatiquement.
# J'ai ajouté RES4LYF et SeedVR2 ici.
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
    comfyui-comfyroll \
    RES4LYF \
    seedvr2_videoupscaler \
    && rm -rf /root/.cache/pip

# ==============================================================================
# 5. INSTALLATION MANUELLE (LES DERNIERS SURVIVANTS)
# ==============================================================================
WORKDIR /comfyui/custom_nodes

# SÉCURITÉ : Mise à jour de pip sans cache
RUN pip install --upgrade pip setuptools wheel --no-cache-dir

# --- 1. Painter I2V ---
RUN git clone https://github.com/princepainter/ComfyUI-PainterI2V.git && \
    cd ComfyUI-PainterI2V && \
    git checkout 63f61e0b7729d91e12a518f8a33a329794e75890 && \
    rm -rf .git && \
    if [ -f requirements.txt ]; then \
        sed -i 's/[<>=]=.*//' requirements.txt && \
        sed -i '/torch/d' requirements.txt && \
        pip install -r requirements.txt --no-cache-dir; \
    fi && cd ..

# --- 2. Painter Sampler ---
RUN git clone https://github.com/princepainter/Comfyui-PainterSampler.git && \
    cd Comfyui-PainterSampler && \
    git checkout fc7cbf5b8cc9766edc7175c405625f15329ebb48 && \
    rm -rf .git && \
    if [ -f requirements.txt ]; then \
        sed -i 's/[<>=]=.*//' requirements.txt && \
        sed -i '/torch/d' requirements.txt && \
        pip install -r requirements.txt --no-cache-dir; \
    fi && cd ..

# --- 3. DyPE ---
RUN git clone https://github.com/wildminder/ComfyUI-DyPE.git && \
    cd ComfyUI-DyPE && \
    rm -rf .git && \
    if [ -f requirements.txt ]; then \
        sed -i 's/[<>=]=.*//' requirements.txt && \
        sed -i '/torch/d' requirements.txt && \
        pip install -r requirements.txt --no-cache-dir; \
    fi && cd ..

# ==============================================================================
# 6. DÉPENDANCES PYTHON FINALES (SANS CACHE)
# ==============================================================================
WORKDIR /comfyui

# InsightFace lib (Gardé car vital)
RUN pip install insightface onnxruntime-gpu --no-deps --no-cache-dir

# ==============================================================================
# 7. FIN & NETTOYAGE ULTIME
# ==============================================================================
RUN rm -rf /root/.cache/pip
WORKDIR /comfyui