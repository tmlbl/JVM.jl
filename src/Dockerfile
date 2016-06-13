FROM {{{baseImg}}}

# Add build tools
RUN apt-get update && apt-get install -y build-essential cmake clang

{{{preBuild}}}

# Add and unpack sources archive
COPY .jvm.tar.gz /opt/
WORKDIR /opt
ENV JULIA_PKGDIR /opt/.jvm
RUN tar xf /opt/.jvm.tar.gz && rm /opt/.jvm.tar.gz && chmod -R 777 /opt/.jvm && julia -e 'Pkg.build()';

{{{postBuild}}}

# Remove build tools
RUN apt-get remove -y build-essential cmake clang && apt-get autoremove -y
