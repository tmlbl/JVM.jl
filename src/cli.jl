# JVM banner

function colo(n::Integer)
  return "\033[$(n)m"
end

bold = colo(1)
thin = colo(0)
gray = "\033[1;37m"
blue = colo(34)

jvmtitle() = "$bold$gray[ $blue$(["Julia Version Manager", "Julia Virtual Machine"][rand(Bool) ? 1 : 2])$gray ]"

function banner(c::Config)
  println("""

  $(jvmtitle())

  $(thin)Julia Version $bold$(c.julia)
  $(thin)Package Directory $bold$(ENV["JULIA_PKGDIR"])$(colo(0))
  """)
end

# CLI utils

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

jevalfile(c::Config, f::AbstractString) = jevaluate(c, "include(\"$(joinpath(pwd(), f))\")")
jevalfile(f::AbstractString) = jevalfile(config, f)

function bashevaluate(str::AbstractString)
  try
    run(Cmd(ByteString["bash", "-c", str]))
  catch err
    exit(1)
  end
end

# Minimal option parser to cut startup time because DocOpt is slow

const JVM_DOC = """

$(jvmtitle())

Usage: jvm [command] [options]

Commands:
    jvm              Start a REPL in the current environment
    jvm init         Create a new project in the current directory
    jvm install      Install dependencies for the current project
    jvm test <pkg>   Run tests for <pkg> in current environment
    jvm add <pkg>    Install a package or git repo and save it to jvm.json
    jvm freeze       Update jvm.json to match current state of project
    jvm package      Generate a tarball of assets ready for offsite installation
    jvm image        Build an updated Docker image for the project
    jvm update       Run Pkg.update() and freeze results
"""

function commandline(args::Vector{UTF8String})
  # Test can be run w/o localizing the package dir
  if length(args) > 0 && args[1] == "test"
    test(args[2:end])
    exit()
  end

  localize()
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
  config = getconfig()

  if length(args) == 0
    banner(config)
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
    exit()
  end

  if args[1] == "install"
    install(config)
    exit()
  end

  if args[1] == "image"
    image(config)
    exit()
  end

  if args[1] == "package"
    package(config)
    exit()
  end

  if args[1] == "update"
    update(config)
    freeze(config)
    exit()
  end

  if args[1] == "run" && length(args) > 1
    bashevaluate("$(jcommand(config)) $(join(args[2:end], ' '))")
    exit()
  end

  # Run scripts, if relevant
  if haskey(config.scripts, ascii(args[1]))
    content = config.scripts[args[1]]
    # If it's a Julia file, evaluate in JVM context
    if isfile(content)
      jevalfile(content)
    else
      # Execute bash commands
      bashevaluate(content)
    end
  else
    println(JVM_DOC)
  end
end
