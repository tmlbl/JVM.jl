# The "Dep" type
# name: (registered) Name of package or (unregistered) git or https url
# version: (registered) Version tag or (unregistered) branch, sha, version tag
# using JSON

typealias SHA ASCIIString

typealias DepVersion @compat Union{SHA,VersionNumber}

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
  baseImg::AbstractString
  preBuild::AbstractString
  postBuild::AbstractString
end

Config() = Config(DEFAULT_VERSION, v"0.0.1", lowercase(last(split(pwd(), '/'))),
    Dep[], Dict(), "", "", "")

Base.isless(d1::Dep, d2::Dep) = isless(d1.name, d2.name)

# Functions for reading and writing to deps file

function getconfig(filepath::AbstractString)
  js = JSON.parse(readstring(open(filepath)))
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

  baseImg = haskey(js, "base-image") ? js["base-image"] : ""
  preBuild = haskey(js, "pre-build") ? join(js["pre-build"], '\n') : ""
  postBuild = haskey(js, "post-build") ? join(js["post-build"], '\n') : ""

  Config(julia_version, version, js["name"], deps, js["scripts"],
      baseImg, preBuild, postBuild)
end

getconfig() = getconfig(CONFIG_FILE)

function writeconfig(filepath::AbstractString, c::Config)
  d = Dict()
  d["julia"] = string(c.julia)
  d["version"] = string(c.version)
  d["name"] = c.name
  d["scripts"] = c.scripts
  d["deps"] = Dict()
  if c.baseImg != ""
    d["base-image"] = c.baseImg
  end
  if c.preBuild != ""
    d["pre-build"] = split(c.preBuild, '\n')
  end
  if c.postBuild != ""
    d["post-build"] = split(c.postBuild, '\n')
  end
  for dep in c.deps
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
