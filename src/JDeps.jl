module JDeps

# The alternative package dir
user_pkgdir = Pkg.dir()
local_dir = joinpath(pwd(), ".jdeps")
info("Setting JULIA_PKGDIR to $local_dir")
ENV["JULIA_PKGDIR"] = local_dir

function init()
  mkdir(local_dir)
  ENV["JULIA_PKGDIR"] = local_dir
  touch("JDEPS")
  Pkg.init()
end

type Dep
  name::ASCIIString
  version::ASCIIString
end

function getdeps()
  map((line) -> Dep(split(line)...), readlines(open("JDEPS")))
end

function writedeps(deps::Array{Dep})
  write(open("JDEPS", "w"), join(map((dep) -> "$(dep.name) $(dep.version)", deps), '\n'))
end

function add(pkg::ASCIIString)
  Pkg.add(pkg)
  deps = getdeps()
  if length(deps) == 0
    deps = Array{Dep,1}()
  end
  push!(deps, Dep(pkg, string(Pkg.installed(pkg))))
  Pkg.pin(pkg)
  writedeps(deps)
end

function install()
  if !isfile("JDEPS")
    error("No JDEPS file in this directory!")
  end
  if !isdir(local_dir)
    init()
  end
  for dep in getdeps()
    Pkg.add(dep.name, VersionNumber(dep.version))
    Pkg.pin(dep.name, VersionNumber(dep.version))
  end
end

function freeze()
  for pkg in readdir(Pkg.dir())
    println(pkg)
  end
end

end # module
