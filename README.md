JVM: The Julia Version Manager
==============================

A ridiculously simple dependency manager for Julia packages. JVM creates an
environment similar to python's `virtualenv` by locally reassigning the package
directory location.

## Installation

```julia
Pkg.clone("git@github.com:tmlbl/JVM.jl.git")
Pkg.build("JVM")
```

## Usage

Run `jvm init` in your project directory to create a `.jdeps` directory and a
`JDEPS` file. You can then add dependencies using `jvm add [pkg] [version]`.

```bash
~$ jvm add AppConf 0.0.3 # Add v0.0.3 of the AppConf package
~$ jvm add HttpCommon # Leave the version out to install the latest version
# You can add unregistered packages as well
~$ jvm add git@github.com:tmlbl/Oanda.jl.git
```

Registered packages will be tracked by their version numbers. Unregistered
packages will be tracked by SHA. Unlike REQUIRE, all dependencies will also be
recorded at their explicit versions in JDEPS.

The `jvm install` command works like `Pkg.resolve()`, using the `JDEPS` file to
ensure that the correct packages and versions are installed. To run a script,
pass it to `jvm run` like so:

```bash
~$ jvm run app.jl
```

To open a REPL in the environment, you can run `jvm load`. Run `jvm` with no
arguments to see a list of commands.

## Packaging

Running `jvm package` will create a `julia_pkgs.tar.gz` of unbuilt packages that
can then be copied to and built on a target machine, or built inside a Docker
container to create a _Julia Virtual Machine_.

```bash
~$ jvm init
~$ jvm add LevelDB
~$ jvm package
```

Check out [keyval](https://github.com/tmlbl/keyval) for an example project using JVM 
to create a containerized build.
