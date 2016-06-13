JVM: Julia Version Manager
==========================

The JVM is a tool for creating virtual environments in Julia and publishing
Docker images based on them. To use it, you will want to have certain programs
already installed, including:

* A reasonably recent version of Julia
* Tools necessary for Julia package installation: C compilers and tools for building
software, like those covered by the build-essential Debian repository
* Docker, for building images and launching containers
* docker-squash, a pip package for removing unnecessary files from Docker images

## Configuring

A new project can be created in the current directory by running `jvm init`.
This creates a basic configuration file, with the following properties:

```javascript
{
  "deps": {
    "AppConf": "0.1.1", // Map of dependencies to versions
    // Can do unregistered packages as well
    "https://github.com/tmlbl/Oanda.jl.git": "d32e3d9ee2a867cb5f7093bf8d7d8eecf5160b0d"
  },
  // Version of Julia the project will use to run (installed automatically)
  "julia": "0.4.5",
  // Project name and name of resulting Docker image
  "name": "jvm",
  "scripts": {
    // This section can contain arbitrary keys with bash commands, run with jvm [cmd]
    "bootstrap": "jvm run scripts/bootstrap.jl",
    // If the value is the file, the file will be executed
    "test": "test/runtests.jl"
  },
  // This is the version of the project itself
  // Docker images will be tagged with this version number
  "version": "0.0.1",
  // Here arbitrary lines can be injected before and after the package build
  // step when the image is created.
  "pre-build": [
    "RUN apt-get install libsnappy1"
  ]
}
```
