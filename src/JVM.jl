__precompile__()

module JVM

local_dir = ""

# Localize the package directory
function __init__()
  global local_dir = joinpath(pwd(), ".jdeps")
  info("Setting JULIA_PKGDIR to $local_dir")
  ENV["JULIA_PKGDIR"] = local_dir
  # Hack to fix the library load path.
  # TODO: Seek alternative approaches -- depends on Julia internals for precompilation.
  VERSION >= v"0.4.0-" && (Base.LOAD_CACHE_PATH[1] = local_dir*"/lib/v0.4")
end

# Utils

isgit(str::AbstractString) = ismatch(r"^https|\@", str)

namefromgit(url::AbstractString) = begin
  n = string(match(r"([^/]+$)", url).match)
  n = replace(n, ".jl", "")
  n = replace(n, ".git", "")
  n
end

getsha(pkg::AbstractString) =
  chomp(readall(`$(Pkg.Git.git(Pkg.dir(pkg))) rev-parse HEAD`))

checkout(pkg::AbstractString, sha::AbstractString) =
  chomp(readall(`$(Pkg.Git.git(Pkg.dir(pkg))) checkout $sha`))

gitclean(pkg::AbstractString) =
  run(`$(Pkg.Git.git(Pkg.dir(pkg))) clean -dfxq`)

geturl(pkg::AbstractString) =
  chomp(readall(`$(Pkg.Git.git(Pkg.dir(pkg))) config --get remote.origin.url`))

# Get the current state
function installed()
  deps = Array{Dep,1}()
  for p in Pkg.installed()
     push!(deps, if p[2] == v"0.0.0-"
       Dep(geturl(p[1]), getsha(p[1]))
     else
       Dep(p[1], string(p[2]))
     end)
  end
  deps
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
  writedeps(installed())
  rmrequire()
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
  version = Pkg.installed(dep.name)
  if version != VersionNumber(dep.version) && version != v"0.0.0-"
    println("pinning $(dep.name) at $(dep.version)")
    Pkg.pin(dep.name, VersionNumber(dep.version))
  end
end

function install_unregistered(dep::Dep)
  name = namefromgit(dep.name)
  if isdir(Pkg.dir(name))
    checkout(namefromgit(dep.name), dep.version)
  else
    Pkg.clone(dep.name)
  end
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
end

function update()
  mv("JDEPS", "/tmp/JDEPS.bak"; remove_destination=true)
  Pkg.update()
  freeze()
  info("Local package directory updated. Run 'jvm revert' to restore the previous state")
end

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
