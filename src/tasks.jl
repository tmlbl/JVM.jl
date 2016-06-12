function test(args)
  test_dir = "/tmp/.jdeps.test"
  if length(args) < 1
    if isfile("test/runtests.jl")
      jevaluate(getconfig(), "include(\"test/runtests.jl\")")
      exit()
    else
      println(STDERR, "usage: \n\ttest <pkg> <?julia_version>")
      exit(1)
    end
  end
  test_pkg = Pkg.dir(args[1])
  if isdir(test_dir)
    bashevaluate("rm -rf $test_dir")
  end
  ENV["JULIA_PKGDIR"] = test_dir
  cfg = Config()
  if length(args) == 2
    cfg.julia = VersionNumber(args[2])
  end
  pkg_dir = "$(ENV["JULIA_PKGDIR"])/v$(cfg.julia.major).$(cfg.julia.minor)/$(args[1])"

  jevaluate(cfg, "Pkg.init()")

  # HACK - use clone to install dependencies, then copy the most recent code
  jevaluate(cfg, "Pkg.clone(\"$test_pkg\")")
  bashevaluate("rm -rf $pkg_dir; cp -r $test_pkg $pkg_dir")

  jevaluate(cfg, "Pkg.test(\"$(args[1])\")")
  info("Removing $(ENV["JULIA_PKGDIR"])")
  run(`rm -rf $(ENV["JULIA_PKGDIR"])`)
end

function freeze(cfg::Config)
  deps = Array{Dep,1}()
  for (p, v) in Pkg.installed()
    if isgit(p)
      push!(deps, Dep(p, getsha(p)))
    else
      push!(deps, Dep(p, v))
    end
  end
  cfg.deps = deps
  writeconfig(cfg)
end

function install_registered(dep::Dep)
  if !isdir(Pkg.dir(dep.name))
    Pkg.add(dep.name, dep.version)
  end
  v = Pkg.installed(dep.name)
  if v != dep.version
    Pkg.pin(dep.name, dep.version)
  end
end

function install_unregistered(dep::Dep)
  name = namefromgit(dep.name)
  if !isdir(Pkg.dir(name))
    Pkg.clone(dep.name)
  end
end

function install(cfg::Config)
  meta = ENV["JULIA_PKGDIR"]*"/$JULIA_VERSION/METADATA"
  if !isdir(meta)
    jevaluate(cfg, "Pkg.init()")
  end
  for d in cfg.deps
    if isgit(d.name)
      install_unregistered(d)
    else
      install_registered(d)
    end
  end
end

docker_template =
    Mustache.template_from_file(joinpath(Pkg.dir("JVM"), "src/Dockerfile"))

function image(cfg)
  install(cfg)
  package(cfg)
  Dockerfile = Mustache.render(docker_template, cfg)

  if isfile("$local_dir/Dockerfile")
    rm("$local_dir/Dockerfile")
  end
  f = open("$local_dir/Dockerfile", "w")
  write(f, Dockerfile)
  close(f)
  base_img_name = "$(cfg.name)-base:$(cfg.version)"
  bashevaluate("docker build -t $base_img_name -f $local_dir/Dockerfile .")
  info("Built image $base_img_name")
  f = open("$local_dir/$(base64encode(base_img_name))", "w")
  

  if isfile("Dockerfile")
    bashevaluate("docker build -t $(cfg.name):$(cfg.version) .")
    info("Built image $(cfg.name):$(cfg.version)")
  end
end

function package(cfg::Config)
  if isfile(archive_name)
    rm(archive_name)
  end
  info("Copying files...")
  if isdir(package_dir)
    rm(package_dir; recursive=true)
  end
  cp(local_dir, package_dir)

  info("Cleaning package sources...")
  run(`rm $package_dir/$JULIA_VERSION/.cache`)
  run(`rm -rf $package_dir/.cache/*`)

  ENV["JULIA_PKGDIR"] = package_dir
  # Remove Homebrew, in case we are on a Mac
  if isdir(Pkg.dir("Homebrew"))
    rm(Pkg.dir("Homebrew"); recursive=true)
  end
  # Remove all submodules, they may contain incompatible artifacts
  cur_dir = pwd()
  for p in readdir(Pkg.dir())
    path = joinpath(Pkg.dir(), p)
    if isdir(path)
      cd(path)
      paths = map((ln) -> split(chomp(ln)), readlines(`git submodule`))
      for sub in paths
        rm(joinpath(Pkg.dir(p), sub[2]); recursive=true)
      end
    end
  end

  for p in Pkg.installed()
    gitclean(p[1])
  end

  info("Creating tarball...")
  cd(cur_dir)
  run(`tar -czf $archive_name -C /tmp .jvm`)
end
