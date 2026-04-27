FROM cr.ai.cloud.ru/aicloud-base-images/cuda12.3-torch2-py310:0.0.37

USER root

RUN apt-get update \
   && apt-get install -y --no-install-recommends \
      curl wget tar bzip2 xz-utils \
      libglu1-mesa libxi6 libxxf86vm1 libxrender1 \
   && rm -rf /var/lib/apt/lists/*

RUN cd /opt \
 && wget https://download.blender.org/release/Blender2.79/blender-2.79b-linux-glibc219-x86_64.tar.bz2 \
 && tar -xjf blender-2.79b-linux-glibc219-x86_64.tar.bz2 \
 && ln -s /opt/blender-2.79b-linux-glibc219-x86_64/blender /usr/local/bin/blender \
 && chown -R user:user /opt/blender-2.79b-linux-glibc219-x86_64 \
 && echo /opt/blender-2.79b-linux-glibc219-x86_64/2.79/python/lib/python3.5/site-packages \
    >> /opt/blender-2.79b-linux-glibc219-x86_64/2.79/python/lib/python3.5/site-packages/clevr.pth


# --- user ---
USER user

# --- default shell ---
CMD ["/bin/bash"]
