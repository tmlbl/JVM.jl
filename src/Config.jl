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
end

Config() = Config(VERSION, Dep[])

Base.isless(d1::Dep, d2::Dep) = isless(d1.name, d2.name)

# Functions for reading and writing to deps file

function getconfig()
  js = JSON.parse(readall(open(CONFIG_FILE)))
  version = VersionNumber(js["julia"])
  deps = Array{Dep,1}()
  for (n, v) in js["deps"]
    push!(deps, Dep(n, ascii(v)))
  end
  Config(version, deps)
end

function writeconfig(jdeps::Config)
  v = jdeps.julia
  d = Dict()
  d["julia"] = "v$(v.major).$(v.minor).$(v.patch)"
  if !haskey(d, "deps")
    d["deps"] = Dep[]
  end
  js = json(d, 2)
  write(open(CONFIG_FILE, "w"), js)
end

function initconfig()
  c = Config()
  writeconfig(c)
  c
end
