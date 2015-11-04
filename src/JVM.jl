__precompile__()

module JVM

local_dir = ""

# Localize the package directory
function __init__()
  global local_dir = joinpath(pwd(), ".jdeps")
  info("Setting JULIA_PKGDIR to $local_dir")
  ENV["JULIA_PKGDIR"] = local_dir
  # Hack to fix the library load path.
  Base.LOAD_CACHE_PATH[1] =
    joinpath(local_dir, "lib/v$(VERSION.major).$(VERSION.minor)")
end

# Utils

isgit(str::AbstractString) = ismatch(r"^https|\@", str)

namefromgit(url::AbstractString) = begin
  n = string(match(r"([^/]+$)", url).match)
  n = replace(n, ".jl", "")
  n = replace(n, ".git", "")
  n
end

gitcmd(pkg::AbstractString, cmd::AbstractString) =
    chomp(readall(`$(Pkg.Git.git(Pkg.dir(pkg))) $(split(cmd, ' '))`))

getsha(pkg::AbstractString) = gitcmd(pkg, "rev-parse HEAD")

checkout(pkg::AbstractString, sha::AbstractString) = gitcmd(pkg, "checkout $sha")

gitclean(pkg::AbstractString) = gitcmd(pkg, "clean -dfxq")

geturl(pkg::AbstractString) = gitcmd(pkg, "config --get remote.origin.url")

setorigin(url::AbstractString) = begin
  pkg = namefromgit(url)
  gitcmd(pkg, "remote rm origin")
  gitcmd(pkg, "remote add origin $url")
  gitcmd(pkg, "fetch --all")
end

# Get the current state
function update()
  # deps = Array{Dep,1}()
  # for p in Pkg.installed()
  #    push!(deps, if p[2] == v"0.0.0-"
  #      Dep(geturl(p[1]), getsha(p[1]))
  #    else
  #      Dep(p[1], string(p[2]))
  #    end)
  # end
  # deps
  gitcmd("METADATA", "pull origin metadata-v2")
  deps = getdeps()
  for dep in deps
    if isgit(dep.name)
      pkg = namefromgit(dep.name)
      gitcmd(pkg, "pull")
      dep.version = getsha(pkg)
    else
      nv = v"0.0.0"
      for v in Pkg.available(dep.name)
        if v > VersionNumber(dep.version)
          nv = v
        end
      end
      if nv > VersionNumber(dep.version)
        info("Updating $(dep.name) to $nv")
        dep.version = nv
      end
    end
  end
end

rmrequire() = begin
  reqpath = joinpath(Pkg.dir(), "REQUIRE")
  if isfile(reqpath)
    rm(reqpath)
  end
end

# The "Dep" type
# name: (registered) Name of package or (unregistered) git or https url
# version: (registered) Version tag or (unregistered) branch, sha, version tag
type Dep
  name::AbstractString
  version::AbstractString
end

Base.isless(d1::Dep, d2::Dep) = isless(d1.name, d2.name)

# Functions for reading and writing to deps file

function getdeps()
  map((line) -> Dep(split(line)...), readlines(open("JDEPS")))
end

getdep(n::AbstractString) = find((d) -> d.name == n, getdeps())

function writedeps(deps::Array{Dep})
  write(open("JDEPS", "w"), join(map((dep) -> "$(dep.name) $(dep.version)", sort(deps)), '\n'))
end

# Commands

function init()
  if !isdir(local_dir) mkdir(local_dir) end
  if !isfile("JDEPS") touch("JDEPS") end
  Pkg.init()
  rmrequire()
end

function freeze()
  # writedeps(installed())
  # rmrequire()
end

# Enforce the versions specified in JDEPS
function fix()
  for dep in getdeps()
    if isgit(dep.name)
      pkg = namefromgit(dep.name)
      if geturl(pkg) != dep.name
        setorigin(dep.name)
      end
      info("Pinning $pkg at $(dep.version)")
      gitcmd(pkg, "reset --hard $(dep.version)")
    else
      Pkg.pin(dep.name, VersionNumber(dep.version))
    end
  end
end

function add(pkg::AbstractString, v::AbstractString)
  if isgit(pkg)
    Pkg.clone(pkg)
    if v != "" checkout(namefromgit(pkg), v) end
  else
    if v != "" Pkg.add(pkg, VersionNumber(v)) else Pkg.add(pkg) end
    if v != "" Pkg.pin(pkg, VersionNumber(v)) else Pkg.pin(pkg) end
  end
  freeze()
end

add(pkg::AbstractString) = add(pkg, "")

function install_registered(dep::Dep)
  if !isdir(Pkg.dir(dep.name))
    Pkg.add(dep.name, VersionNumber(dep.version))
  end
end

function install_unregistered(dep::Dep)
  name = namefromgit(dep.name)
  if !isdir(Pkg.dir(name))
    Pkg.clone(dep.name)
  end
  Pkg.build(name)
end

function install()
  if !isfile("JDEPS")
    error("No JDEPS file in this directory!")
  end
  if !isdir(joinpath(Pkg.dir(), "METADATA"))
    init()
  end
  for dep in getdeps()
    if isgit(dep.name)
      install_unregistered(dep)
    else
      install_registered(dep)
    end
  end
  fix()
end

# function update()
#   mv("JDEPS", "/tmp/JDEPS.bak"; remove_destination=true)
#   Pkg.update()
#   freeze()
#   info("Local package directory updated. Run 'jvm revert' to restore the previous state")
# end

function revert()
  mv("/tmp/JDEPS.bak", "JDEPS"; remove_destination=true)
  install()
end

function package()
  cp(".jdeps", "/tmp/.jdeps.pkg"; remove_destination=true)
  ENV["JULIA_PKGDIR"] = "/tmp/.jdeps.pkg"
  for p in Pkg.installed()
    gitclean(p[1])
  end
  run(`tar -czf julia_pkgs.tar.gz -C /tmp .jdeps.pkg`)
  ENV["JULIA_PKGDIR"] = local_dir
end

end # module
