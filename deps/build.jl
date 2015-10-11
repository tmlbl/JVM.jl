binpath = joinpath(Pkg.dir(), "JVM/bin/jvm")
linkpath = "/usr/local/bin/jvm"

@unix_only begin
  if !islink(linkpath)
    info("Creating a symlink at $linkpath")
    run(`sudo ln -s $binpath /usr/local/bin`)
  else
    targ = readlink(linkpath)
    if targ == binpath
      info("JVM is already linked.")
    else
      error("$linkpath leads to $targ, delete it and run Pkg.build(\"JVM\")")
    end
  end
end
