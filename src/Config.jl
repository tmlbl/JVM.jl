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
  test::Vector{VersionNumber}
end

Config() = Config(VERSION, Dep[], VersionNumber[VERSION])

Base.isless(d1::Dep, d2::Dep) = isless(d1.name, d2.name)

# Functions for reading and writing to deps file

function getconfig()
  js = JSON.parse(readall(open(CONFIG_FILE)))
  version = VersionNumber(js["julia"])
  deps = Array{Dep,1}()
  test = Array{VersionNumber,1}()
  for (d) in js["deps"]
    for (n, v) in d
      if isgit(n)
        push!(deps, Dep(n, ascii(v)))
      else
        push!(deps, Dep(n, VersionNumber(v)))
      end
    end
  end
  for v in js["test"]
    push!(test, VersionNumber(v))
  end
  Config(version, deps, test)
end

function writeconfig(jdeps::Config)
  d = Dict()
  d["julia"] = string(jdeps.julia)
  d["deps"] = map((dep) -> Dict(dep.name => string(dep.version)), jdeps.deps)
  d["test"] = map(string, jdeps.test)
  js = json(d, 2)
  write(open(CONFIG_FILE, "w"), js)
end

function initconfig()
  c = Config()
  writeconfig(c)
  c
end
