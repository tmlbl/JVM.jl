using JVM,
      Base.Test

@test !JVM.isgit("Compat")
@test !JVM.isgit("AppConf")
@test JVM.isgit("git@github.com:tmlbl/AppConf.jl")
@test JVM.isgit("https://github.com/tmlbl/AppConf.jl")
@test JVM.namefromgit("git@github.com:tmlbl/AppConf.jl.git") == "AppConf"
@test JVM.namefromgit("https://github.com/tmlbl/AppConf.jl") == "AppConf"
