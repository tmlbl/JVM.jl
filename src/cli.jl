function banner(jdeps::JDEPS)
  println("""

  [ $(["Julia Version Manager", "Julia Virtual Machine"][rand(Bool) ? 1 : 2]) ]

  Julia Version: $(jdeps.julia)
  Package Directory: $(ENV["JULIA_PKGDIR"])
  """)
end

function jcommand()
  options = "-q --color=yes"
  if config.julia > v"0.4.0"
    options = "-q --color=yes"
  end
  `$(getbinary(config.julia)) $(split(options, ' '))`
end

function jevaluate(cmd::AbstractString)
  run(`$(jcommand()) -e \"$(split(cmd, ' '))\"`)
end

function installarg(s::UTF8String)
  if !contains(s, "#")
    if isgit(s)
      return install_unregistered(Dep(s, v"0.0.0"))
    else
      return install_registered(Dep(s, v"0.0.0"))
    end
  end
end

function commandline(args::Vector{UTF8String})
  @show args
  if args[1] == "init"
    warn("initting bitvh")
    initconfig()
    jevaluate("Pkg.init()")
    exit()
  end
  config = JVM.getconfig()
  banner(config)

  if length(args) == 0
    run(jcommand())
    exit()
  end

  if ARGS[1] == "add"
    for a in ARGS[2:end]
      installarg(a)
    end
    exit()
  end

  if ARGS[1] == "test"
    test()
  end
end
