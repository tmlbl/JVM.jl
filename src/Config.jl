# The "Dep" type
# name: (registered) Name of package or (unregistered) git or https url
# version: (registered) Version tag or (unregistered) branch, sha, version tag
# using JSON

typealias SHA ASCIIString

typealias DepVersion Union{SHA,VersionNumber}

type Dep
  name::AbstractString
  version::DepVersion
end

type Config
  julia::VersionNumber
  deps::Vector{Dep}
  scripts::Dict{AbstractString,Any}
end

Config() = Config(DEFAULT_VERSION, Dep[], Dict())

Base.isless(d1::Dep, d2::Dep) = isless(d1.name, d2.name)

# Functions for reading and writing to deps file

function getconfig()
  js = JSON.parse(readall(open(CONFIG_FILE)))
  version = VersionNumber(js["julia"])
  deps = Array{Dep,1}()
  for (n, v) in js["deps"]
    if isgit(n)
      push!(deps, Dep(n, ascii(v)))
    else
      push!(deps, Dep(n, VersionNumber(v)))
    end
  end
  Config(version, deps, js["scripts"])
end

function writeconfig(jdeps::Config)
  d = Dict()
  d["julia"] = string(jdeps.julia)
  d["scripts"] = jdeps.scripts
  d["deps"] = Dict()
  for dep in jdeps.deps
    d["deps"][dep.name] = string(dep.version)
  end
  js = json(d, 2)
  cfile = open(CONFIG_FILE, "w")
  write(cfile, js)
  close(cfile)
end

function initconfig()
  c = Config()
  info("Creating default $CONFIG_FILE")
  writeconfig(c)
  c
end
