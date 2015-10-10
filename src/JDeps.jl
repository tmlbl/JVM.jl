__precompile__()

module JDeps

local_dir = ""

# Localize the package directory
function __init__()
  global local_dir = joinpath(pwd(), ".jdeps")
  info("Setting JULIA_PKGDIR to $local_dir")
  ENV["JULIA_PKGDIR"] = local_dir
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
  chomp(readall(`$(Pkg.Git.git(Pkg.dir(pkg))) git checkout $sha`))

geturl(pkg::AbstractString) =
  chomp(readall(`$(Pkg.Git.git(Pkg.dir(pkg))) config --get remote.origin.url`))

getinstalled() =
  map((p) -> if p[2] == v"0.0.0-" Dep(p[1], getsha(p[1])) else Dep(p[1], string(p[2])) end,
  Pkg.installed())

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

Base.isless(d1::JDeps.Dep, d2::JDeps.Dep) = isless(d1.name, d2.name)

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

function resolve()
  deps = getdeps()
  pkgs = getinstalled()

end

function freeze()
  deps = Array{Dep,1}()
  for (pkg, version) in Pkg.installed()
    if VersionNumber(version) == v"0.0.0-"
      sha = getsha(pkg)
      info("Freezing $pkg at $sha")
      push!(deps, Dep(geturl(pkg), sha))
    else
      Pkg.pin(pkg, version)
      push!(deps, Dep(pkg, string(version)))
    end
  end
  written = writedeps(deps)
  rmrequire()
end

function add(pkg::AbstractString, v::AbstractString)
  if isgit(pkg)
    Pkg.clone(pkg)
    if v != "" checkout(v) end
  else
    if v != "" Pkg.add(pkg, VersionNumber(v)) else Pkg.add(pkg) end
    if v != "" Pkg.pin(pkg, VersionNumber(v)) else Pkg.pin(pkg) end
  end
  freeze()
end

add(pkg::AbstractString) = add(pkg, "")

function install_registered(dep::Dep)
  version = v"0.0.0-"
  if isdir(Pkg.dir(dep.name))
    version = Pkg.installed(dep.name)
  else
    Pkg.add(dep.name, VersionNumber(dep.version))
  end
  if version != VersionNumber(dep.version) && version != v"0.0.0-"
    println("pinning $(dep.name) at $(dep.version)")
    Pkg.pin(dep.name, VersionNumber(dep.version))
  end
end

function install_unregistered(dep::Dep)
  name = namefromgit(dep.name)
  if isdir(Pkg.dir(name))
    checkout(dep.version)
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
  metapath = joinpath(Pkg.dir(), "METADATA")
  run(`git -C $metapath pull origin metadata-v2`)
  rmrequire()
  install()
end

function package()

end

end # module
