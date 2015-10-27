JVM: The Julia Version Manager
==============================

A ridiculously simple dependency manager for Julia packages.

JVM is a command-line utility that uses `Base.Pkg` to create and manage a
localized package directory for managing explicit dependencies per-project.

Run `jvm init` in your project directory to create a `.jdeps` directory and a
`JDEPS` file. You can then add dependencies using `jvm add [pkg] [version]`.

```bash
~$ jvm add AppConf 0.0.3 # Add v0.0.3 of the AppConf package
~$ jvm add HttpCommon # Leave the version out to install the current version
~$ jvm add git@github.com:tmlbl/Oanda.jl.git # You can add unregistered packages as well
```

Registered packages will be tracked by their version numbers. Unregistered
packages will be tracked by SHA. Unlike REQUIRE, all dependencies will also be
recorded at their explicit versions in JDEPS. If are running a project that
includes a JDEPS file, you can fetch those dependencies by running `jvm install`.
Then, run the project by setting `JULIA_PKGDIR` to the created `.jdeps`
directory. Or, you can use the built-in shortcut to temporarily reassign
`JULIA_PKGDIR`:

```bash
~$ jvm run app.jl
```

Running `jvm package` will create a `julia_pkgs.tar.gz` of unbuilt packages that
can then be copied to and built on a target machine, or built inside a Docker
container to create a _Julia_Virtual_Machine_.

```bash
~$ jvm init
~$ jvm add LevelDB
~$ jvm package
```

Dockerfile:
```dockerfile
FROM julia:0.4.0

RUN apt-get update
RUN apt-get install -y wget build-essential libsnappy-dev

ADD . /opt/src
WORKDIR /opt/src
RUN tar xvf julia_pkgs.tar.gz
ENV JULIA_PKGDIR /opt/src/.jdeps.pkg
RUN julia -e "Pkg.build()"
ENTRYPOINT julia /opt/src/script.jl
```

Run `jvm` with no arguments to see help information.
