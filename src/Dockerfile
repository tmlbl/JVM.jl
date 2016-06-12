FROM julia:{{julia}}

# Add build tools
RUN apt-get update && apt-get install -y make build-essential cmake clang

# Add and unpack sources archive
COPY .jvm.tar.gz /opt/
WORKDIR /opt
RUN tar xf /opt/.jvm.tar.gz
RUN chmod -R 777 /opt/.jvm
ENV JULIA_PKGDIR /opt/.jvm

# Build package sources
RUN julia -e 'Pkg.build()'

# Remove build tools
RUN apt-get remove -y make build-essential cmake clang && apt-get autoremove -y
