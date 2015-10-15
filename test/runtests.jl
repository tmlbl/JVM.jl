using JVM,
      Base.Test

@test !JVM.isgit("Compat")
@test !JVM.isgit("AppConf")
@test JVM.isgit("git@github.com:tmlbl/AppConf.jl")
@test JVM.isgit("https://github.com/tmlbl/AppConf.jl")
@test JVM.namefromgit("git@github.com:tmlbl/AppConf.jl.git") == "AppConf"
@test JVM.namefromgit("https://github.com/tmlbl/AppConf.jl") == "AppConf"

JVM.init()

@test isdir(".jdeps")
@test isfile("JDEPS")

JVM.add("AppConf", "0.0.3")

@test Pkg.installed("AppConf") == v"0.0.3"

run(`rm -rf .jdeps JDEPS`)
