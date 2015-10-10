module JDeps

isgit(str::AbstractString) = ismatch(r"[\@|https]", str)

namefromgit(url::AbstractString) = begin
  pkg_name = string(match(r"([^/]+$)", url).match)
  pkg_name = replace(pkg_name, ".jl", "")
  pkg_name = replace(pkg_name, ".git", "")
  pkg_name
end

# The alternative package dir
user_pkgdir = Pkg.dir()
local_dir = joinpath(pwd(), ".jdeps")
info("Setting JULIA_PKGDIR to $local_dir")
ENV["JULIA_PKGDIR"] = local_dir

function init()
  if !isdir(local_dir)
    mkdir(local_dir)
  end
  ENV["JULIA_PKGDIR"] = local_dir
  touch("JDEPS")
  Pkg.init()
  rm(joinpath(Pkg.dir(), "REQUIRE"))
end

# (registered) Name of package or (unregistered) git or https url
type Dep
  name::AbstractString
  version::AbstractString
end

# Read the DEPS file
function getdeps()
  map((line) -> Dep(split(line)...), readlines(open("JDEPS")))
end

function writedeps(deps::Array{Dep})
  write(open("JDEPS", "w"), join(map((dep) -> "$(dep.name) $(dep.version)", deps), '\n'))
end

function add(pkg::AbstractString)
  if !isfile("JDEPS")
    touch("JDEPS")
  end
  deps = getdeps()
  if length(deps) == 0
    deps = Array{Dep,1}()
  end

  if isgit(pkg)
    # Going to guess this is a url
    Pkg.clone(pkg)
    pkg_name = namefromgit(pkg)
    git_cmd = Pkg.Git.git(Pkg.dir(pkg_name))
    sha = chomp(readall(`$git_cmd rev-parse HEAD`))
    push!(deps, Dep(pkg, sha))
  else
    Pkg.add(pkg)
    push!(deps, Dep(pkg, string(Pkg.installed(pkg))))
    Pkg.pin(pkg)
  end

  writedeps(deps)
end

function install_registered(dep::Dep)
  version = v"0.0.0-"
  if isdir(Pkg.dir(dep.name))
    version = Pkg.installed(dep.name)
  else
    Pkg.add(dep.name, VersionNumber(dep.version))
  end
  if version != VersionNumber(dep.version) && version != v"0.0.0-"
    Pkg.pin(dep.name, VersionNumber(dep.version))
  end
end

function install_unregistered(dep::Dep)
  name = namefromgit(dep.name)
  if isdir(Pkg.dir(name))
    git_cmd = Pkg.Git.git(Pkg.dir(name))
    run(`$git_cmd checkout $(dep.version)`)
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

function freeze()
  deps = Array{Dep,1}()
  for (pkg, version) in Pkg.installed()
    if VersionNumber(version) != v"0.0.0-"
      Pkg.pin(pkg, version)
    end
    push!(deps, Dep(pkg, string(version)))
  end
  written = writedeps(deps)
end

function update()
  metapath = joinpath(Pkg.dir(), "METADATA")
  run(`git -C $metapath pull origin metadata-v2`)
end

end # module
