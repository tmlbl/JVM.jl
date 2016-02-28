JVM: The Julia Version Manager
==============================

A ridiculously simple dependency manager for Julia packages. JVM creates an
environment similar to python's `virtualenv` by locally reassigning the package
directory location. It also downloads and runs Julia, allowing you to
easily switch between versions of Julia.

## Installation

```julia
Pkg.clone("git@github.com:tmlbl/JVM.jl.git")
Pkg.build("JVM")
```

## Usage

JVM uses a `.jvm.json` config file. Run `jvm init` to create one. It is
structured like so:

```json
{
  "deps": [],
  "test": ["v0.3.8", "v0.3.11"],
  "julia": "v0.3.11"
}
```

This will run Julia `0.3.11`.
