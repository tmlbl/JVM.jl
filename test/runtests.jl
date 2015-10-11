using JDeps,
      Base.Test

@test !JDeps.isgit("Compat")
@test !JDeps.isgit("AppConf")
@test JDeps.isgit("git@github.com:tmlbl/AppConf.jl")
@test JDeps.isgit("https://github.com/tmlbl/AppConf.jl")
@test JDeps.namefromgit("git@github.com:tmlbl/AppConf.jl.git") == "AppConf"
@test JDeps.namefromgit("https://github.com/tmlbl/AppConf.jl") == "AppConf"

JDeps.init()

@test isdir(".jdeps")
@test isfile("JDEPS")

JDeps.add("AppConf", "0.0.3")

@test Pkg.installed("AppConf") == v"0.0.3"

run(`rm -rf .jdeps JDEPS`)
