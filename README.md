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

Run `jvm` with no arguments to see help information.

TODO: Add a "package" command that will run `git clean -dfx` on all packages and
create a tarball that can be used to deploy the project.
