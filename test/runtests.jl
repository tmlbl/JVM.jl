using JDeps,
      Base.Test

@test !JDeps.isgit("Compat")
@test !JDeps.isgit("AppConf")
@test JDeps.isgit("git@github.com:tmlbl/AppConf.jl")
@test JDeps.isgit("https://github.com/tmlbl/AppConf.jl")

JDeps.init()

@test isdir(".jdeps")

JDeps.install()

@test Pkg.installed("AppConf") == v"0.0.3"

run(`rm -rf .jdeps`)
