using JDeps,
      Base.Test

JDeps.init()

@test isdir(".jdeps")

JDeps.install()

@test Pkg.installed("AppConf") == v"0.0.3"

run(`rm -rf .jdeps`)
