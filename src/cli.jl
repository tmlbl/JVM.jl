function colo(n::Integer)
  return "\033[$(n)m"
end

function banner(c::Config)
  println("""

  $(colo(1))$(colo(30))[ $(colo(34))$(["Julia Version Manager", "Julia Virtual Machine"][rand(Bool) ? 1 : 2])$(colo(30)) ]

  Julia Version $(colo(37))$(c.julia)
  $(colo(30))Package Directory $(colo(37))$(ENV["JULIA_PKGDIR"])$(colo(0))
  """)
end

function jcommand(c::Config)
  options = "-q --color=yes"
  if c.julia > v"0.4.0"
    options = "-q --color=yes"
  end
  "JULIA_PKGDIR=$(ENV["JULIA_PKGDIR"]) $(getbinary(c.julia)) $options"
end

function jevaluate(cfg::Config, cmd::AbstractString)
  bashevaluate(jcommand(cfg)*" -e '$cmd'")
end

function bashevaluate(str::AbstractString)
  run(Cmd(ByteString["bash", "-c", str]))
end

function installarg(cfg::Config, s::UTF8String)
  if !contains(s, "#")
    if isgit(s)
      jevaluate(cfg, "Pkg.clone(\"$s\")")
    else
      jevaluate(cfg, "Pkg.add(\"$s\")")
    end
  end
  freeze(cfg)
end

function commandline(args::Vector{UTF8String})
  # Empty args (load) and init are done without loading existing config
  if length(args) == 0 && !isfile(CONFIG_FILE)
    info("Using default version: $DEFAULT_VERSION")
    banner(Config())
    bashevaluate(jcommand(Config()))
    exit()
  elseif length(args) > 0 && args[1] == "init"
    if isfile(CONFIG_FILE)
      error("Won't overwrite existing $CONFIG_FILE")
    end
    cfg = initconfig()
    jevaluate(cfg, "Pkg.init()")
    exit()
  end

  # Fetch existing config
  config = JVM.getconfig()
  banner(config)

  if length(args) == 0
    bashevaluate(jcommand(config))
    exit()
  end

  if args[1] == "add"
    for a in ARGS[2:end]
      installarg(config, a)
    end
    exit()
  end

  if args[1] == "freeze"
    freeze(config)
  end

  if args[1] == "install"
    install(config)
  end
end
