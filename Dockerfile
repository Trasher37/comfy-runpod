# ==============================================================================
# IMAGE DE BASE : Optimisée pour RTX 5090 (CUDA 12.8)
# ==============================================================================
FROM runpod/worker-comfyui:5.5.0-base-cuda12.8.1

# ==============================================================================
# 1. PRÉ-REQUIS SYSTÈME (Indispensables pour vos libs Python)
# ==============================================================================
# libgl1/glib2 -> Pour OpenCV (InsightFace, ReActor, Impact)
# libsndfile1 -> Pour Soundfile (SenseVoice)
# ffmpeg -> Pour VideoHelperSuite, Animatediff
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
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
# Liste complète sans Gemini
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
    comfyui-dype \
    comfyui-automaticcfg \
    comfyui-custom-scripts \
    comfyui_ipadapter_plus \
    comfyui-animatediff-evolved \
    comfyui-reactor-node \
    comfyui_insightface

# ==============================================================================
# 5. INSTALLATION MANUELLE VERROUILLÉE (GIT + HASH)
# ==============================================================================
WORKDIR /comfyui/custom_nodes

# --- 1. Painter I2V (Hash snapshot: 63f61e0b...) ---
RUN git clone https://github.com/princepainter/ComfyUI-PainterI2V.git && \
    cd ComfyUI-PainterI2V && \
    git checkout 63f61e0b7729d91e12a518f8a33a329794e75890 && \
    pip install -r requirements.txt && \
    cd ..

# --- 2. Painter Sampler (Hash snapshot: fc7cbf5b...) ---
RUN git clone https://github.com/princepainter/Comfyui-PainterSampler.git && \
    cd Comfyui-PainterSampler && \
    git checkout fc7cbf5b8cc9766edc7175c405625f15329ebb48 && \
    pip install -r requirements.txt && \
    cd ..

# --- 3. ComfyRoll (Hash snapshot: d78b780a...) ---
RUN git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git && \
    cd ComfyUI_Comfyroll_CustomNodes && \
    git checkout d78b780ae43fcf8c6b7c6505e6ffb4584281ceca && \
    cd ..

# --- 4. RES4LYF (Hash snapshot: 46de9172...) ---
RUN git clone https://github.com/ClownsharkBatwing/RES4LYF.git && \
    cd RES4LYF && \
    git checkout 46de917234f9fef3f2ab411c41e07aa3c633f4f7 && \
    cd ..

# --- 5. CG-Use-Everywhere (Version 7.5.1 via Tag) ---
RUN git clone https://github.com/chrisgoringe/cg-use-everywhere.git && \
    cd cg-use-everywhere && \
    git checkout 3f08687258941011538c232379361668e1462066 || echo "Hash introuvable, fallback sur latest" && \
    cd ..

# --- 6. SeedVR2 (Installation capricieuse) ---
RUN git clone https://github.com/StartHua/seedvr2_videoupscaler.git && \
    if [ -f seedvr2_videoupscaler/requirements.txt ]; then pip install -r seedvr2_videoupscaler/requirements.txt; fi

# ==============================================================================
# 6. DÉPENDANCES PYTHON COMPLEXES (SAM2 / SenseVoice)
# ==============================================================================
# Installation forcée sans casser l'environnement CUDA 12.8
RUN pip install "git+https://github.com/facebookresearch/sam2@2b90b9f5ceec907a1c18123530e92e794ad901a4" --no-deps
RUN pip install "git+https://github.com/shadowcz007/SenseVoice-python.git@43f6cf1531e7e4a7d7507d37fbc9b0fb169166ab" --no-deps

# ==============================================================================
# 7. FIN
# ==============================================================================
WORKDIR /comfyui