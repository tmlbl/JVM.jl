# JVM [![Build Status](https://travis-ci.org/tmlbl/JVM.jl.svg?branch=travis)](https://travis-ci.org/tmlbl/JVM.jl)

The JVM is a tool for creating and working with virtual environments in Julia.
It manages installation of Julia versions automagically on Linux and OS X.
JVM integrates with Docker to generate images for Julia applications, and provide
a consistent environment for internal CI and artifact generation.

## Requirements

* Julia and tools necessary for Julia package installation: C compilers and tools for building
software, like those covered by the build-essential Debian repository
* Docker, for building images and launching containers (optional)
* docker-squash, a pip package for removing unnecessary files from Docker images (optional)

## Creating a project

Run `jvm init` to create a project in the current directory. This creates a
JSON manifest file. You can then add dependencies like so:

```bash
$ jvm add StatsBase
$ jvm add HttpServer 0.1.4
```

When a project contains this manifest file, you can fetch the required packages
by running `jvm install`.

## Running commands and files

Running `jvm` alone will open a REPL. Here is where you should manage your
package versions. To save a state in the manifest, run `jvm freeze`.

Use `jvm run` to evaluate Julia files in the local context.

## Creating a Docker image

Create a Dockerfile in your project that uses `${your_project}-base` as the
base image. JVM builds packages and generates cache files in a separate step
to speed up build times. Running `jvm image` will kick off the build.

Additional lines can be added to the base image in the manifest file like so:

```json

"pre-build": [
  "RUN apt-get install libsnappy1"
],
"post_build": [
  "WORKDIR /opt"
]
```

## Running tests

Running `jvm test ${pkg_name}` will run `Pkg.test` on the default version of
Julia in a sandbox environment for the given package. Another Julia version can
be specified like so: `jvm test JVM 0.4.0`. This will probably change.
