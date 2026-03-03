FROM mongo:7.0

RUN apt-get update && apt-get install -y bash && rm -rf /var/lib/apt/lists/*

# Create non-root group and user (UID/GID 65522)
RUN groupadd -g 65522 buildpiper && \
    useradd -u 65522 -g 65522 -m -s /bin/bash buildpiper


RUN mkdir -p /opt/buildpiper/shell-functions


COPY BP-BASE-SHELL-STEPS /opt/buildpiper/shell-functions/


COPY build.sh /opt/buildpiper/build.sh


RUN chown -R buildpiper:buildpiper /opt/buildpiper && \
    chmod +x /opt/buildpiper/build.sh


USER buildpiper

WORKDIR /opt/buildpiper


ENTRYPOINT ["./build.sh"]
