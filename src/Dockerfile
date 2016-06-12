FROM julia:{{julia}}

RUN apt-get update && apt-get install -y make build-essential cmake clang
COPY .jvm.tar.gz /opt/
WORKDIR /opt
RUN tar xf /opt/.jvm.tar.gz
RUN chmod -R 777 /opt/.jvm
ENV JULIA_PKGDIR /opt/.jvm
RUN julia -e 'Pkg.build()'
