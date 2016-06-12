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
  version::VersionNumber
  name::AbstractString
  deps::Vector{Dep}
  scripts::Dict{AbstractString,Any}
end

Config() = Config(DEFAULT_VERSION, v"0.0.1", lowercase(last(split(pwd(), '/'))),
    Dep[], Dict())

Base.isless(d1::Dep, d2::Dep) = isless(d1.name, d2.name)

# Functions for reading and writing to deps file

function getconfig(filepath::AbstractString)
  js = JSON.parse(readall(open(filepath)))
  julia_version = VersionNumber(js["julia"])
  version = VersionNumber(js["version"])

  deps = Array{Dep,1}()
  for (n, v) in js["deps"]
    if isgit(n)
      push!(deps, Dep(n, ascii(v)))
    else
      push!(deps, Dep(n, VersionNumber(v)))
    end
  end
  Config(julia_version, version, js["name"], deps, js["scripts"])
end

getconfig() = getconfig(CONFIG_FILE)

function writeconfig(filepath::AbstractString, jdeps::Config)
  d = Dict()
  d["julia"] = string(jdeps.julia)
  d["version"] = string(jdeps.version)
  d["name"] = jdeps.name
  d["scripts"] = jdeps.scripts
  d["deps"] = Dict()
  for dep in jdeps.deps
    d["deps"][dep.name] = string(dep.version)
  end
  js = json(d, 2)
  cfile = open(filepath, "w")
  write(cfile, js)
  close(cfile)
end

writeconfig(c::Config) = writeconfig(CONFIG_FILE, c)

function initconfig()
  c = Config()
  info("Creating default $CONFIG_FILE")
  writeconfig(c)
  c
end
