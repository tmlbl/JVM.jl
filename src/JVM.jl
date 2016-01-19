__precompile__()

module JVM

local_dir = ""
JULIA_VERSION = ""

# Localize the package directory
function __init__()
  global local_dir = joinpath(pwd(), ".jdeps")
  global JULIA_VERSION = "v$(VERSION.major).$(VERSION.minor)"
  info("Setting JULIA_PKGDIR to $local_dir")
  ENV["JULIA_PKGDIR"] = local_dir
  # Hack to fix the library load path.
  Base.LOAD_CACHE_PATH[1] =
    joinpath(local_dir, "lib/$JULIA_VERSION")
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
  deps = Array{Dep,1}()
  for ln in readlines(open("JDEPS"))
    if length(ln) > 1
      push!(deps, Dep(split(ln)...))
    end
  end
  deps
end

getdep(n::AbstractString) = find((d) -> d.name == n, getdeps())

function writedeps(deps::Array{Dep})
  mv("JDEPS", "/tmp/JDEPS.bak"; remove_destination=true)
  write(open("JDEPS", "w"), join(map((dep) -> "$(dep.name) $(dep.version)", sort(deps)), '\n'))
end

# Utils

isgit(str::AbstractString) = ismatch(r"^https|\@|^git", str)

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

function update(dep::Dep)
  if isgit(dep.name)
    pkg = namefromgit(dep.name)
    try
      gitcmd(pkg, "pull")
    catch
      warn("Error pulling $(dep.name)")
    end
    sha = getsha(pkg)
    if sha != dep.version
      info("Updating $pkg to SHA $sha")
      dep.version = sha
    end
  else
    nv = v"0.0.0"
    for v in Pkg.available(dep.name)
      if v > VersionNumber(dep.version)
        nv = v
      end
    end
    if nv > VersionNumber(dep.version)
      info("Updating $(dep.name) to $nv")
      dep.version = string(nv)
      Pkg.pin(dep.name, nv)
    end
  end
end

function update()
  gitcmd("METADATA", "pull origin metadata-v2")
  deps = getdeps()
  for dep in deps
    update(dep)
  end
  writedeps(deps)
end

function update(name::AbstractString)
  deps = getdeps()
  ix = find((d) -> d.name == name || namefromgit(d.name) == name, deps)
  if length(ix) == 0
    error("Package $name not found")
  end
  update(deps[ix[1]])
  writedeps(deps)
end

rmrequire() = begin
  reqpath = joinpath(Pkg.dir(), "REQUIRE")
  if isfile(reqpath)
    rm(reqpath)
  end
end

# Commands

function init()
  if !isdir(local_dir) mkdir(local_dir) end
  if !isfile("JDEPS") touch("JDEPS") end
  Pkg.init()
  rmrequire()
end

function freeze()
  cur_deps = getdeps()
  avail = Pkg.available()
  deps = Array{Dep,1}()
  for (p, v) in Pkg.installed()
    if length(find((d) -> isgit(d.name) && namefromgit(d.name) == p, cur_deps)) > 0
      push!(deps, Dep(geturl(p), getsha(p)))
    else
      if length(find((pkg) -> pkg == p, avail)) > 0
        push!(deps, Dep(p, string(v)))
      else
        push!(deps, Dep(geturl(p), getsha(p)))
      end
    end
  end
  writedeps(deps)
end

# Enforce the versions specified in JDEPS
function fix()
  for dep in getdeps()
    if isgit(dep.name)
      pkg = namefromgit(dep.name)
      gitcmd(pkg, "fetch --all")
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
  deps = getdeps()
  if isdir(Pkg.dir(namefromgit(pkg)))
    warn("Replacing existing installation of $(namefromgit(pkg))")
    rm(Pkg.dir(namefromgit(pkg)); recursive=true)
    ex = find((d) -> d.name == namefromgit(pkg), deps)
    if length(ex) > 0
      splice!(deps, ex[1])
    end
  end
  if isgit(pkg)
    Pkg.clone(pkg)
    if v != "" checkout(namefromgit(pkg), v) end
    push!(deps, Dep(pkg, getsha(namefromgit(pkg))))
    writedeps(deps)
  else
    if v != "" Pkg.add(pkg, VersionNumber(v)) else Pkg.add(pkg) end
    if v != "" Pkg.pin(pkg, VersionNumber(v)) else Pkg.pin(pkg) end
    freeze()
  end
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
end

function install()
  if !isfile("JDEPS")
    error("No JDEPS file in this directory!")
  end
  if !isdir(joinpath(Pkg.dir(), "METADATA"))
    init()
  else
    gitcmd("METADATA", "pull origin metadata-v2")
  end
  for dep in getdeps()
    if isgit(dep.name)
      install_unregistered(dep)
    else
      install_registered(dep)
    end
  end
  fix()
  Pkg.build()
end

function revert()
  mv("/tmp/JDEPS.bak", "JDEPS"; remove_destination=true)
  install()
end

function package()
  info("Copying files...")
  cp(".jdeps", "/tmp/.jdeps.pkg"; remove_destination=true)
  info("Removing cache...")
  run(`rm /tmp/.jdeps.pkg/$JULIA_VERSION/.cache`)
  run(`rm -rf /tmp/.jdeps.pkg/.cache/*`)
  ENV["JULIA_PKGDIR"] = "/tmp/.jdeps.pkg"
  info("Cleaning package sources...")
  for p in Pkg.installed()
    gitclean(p[1])
  end
  info("Creating tarball...")
  run(`tar -czf julia_pkgs.tar.gz -C /tmp .jdeps.pkg`)
  ENV["JULIA_PKGDIR"] = local_dir
end

end # module
