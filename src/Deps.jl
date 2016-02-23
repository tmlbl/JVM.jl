# The "Dep" type
# name: (registered) Name of package or (unregistered) git or https url
# version: (registered) Version tag or (unregistered) branch, sha, version tag
using JSON

typealias SHA ASCIIString

typealias DepVersion Union{SHA,VersionNumber}

type Dep
  name::AbstractString
  version::DepVersion
end

type JDEPS
  julia::VersionNumber
  deps::Vector{Dep}
end

JDEPS() = JDEPS(VERSION, Dep[])

Base.isless(d1::Dep, d2::Dep) = isless(d1.name, d2.name)

# Functions for reading and writing to deps file

# Verify or install Julia version, and get the path to the binary
function getbinary(v::VersionNumber)
  HOME = ENV["HOME"]
  run(`mkdir -p $HOME/.jvm/julia`)
  archive_path = "$HOME/.jvm/julia/$v"
  @osx_only begin
    dmg_path = "/tmp/$v.dmg"
    vol_path = "/Volumes/Julia/Julia-$v.app"
    bin_path = "$archive_path/Contents/Resources/julia/bin/julia"

    if isfile(bin_path) return bin_path end
    info("Installing Julia $v...")

    run(`wget -O $dmg_path https://s3.amazonaws.com/julialang/bin/osx/x64/0.$(v.minor)/julia-$v-osx10.7+.dmg`)
    run(`hdiutil attach $dmg_path`)
    run(`cp -r $vol_path $archive_path`)
    run(`hdiutil detach /Volumes/Julia`)
    run(`rm $dmg_path`)
    if !isfile(bin_path)
      error("Couldn't find the Julia $v executable at $bin_path")
    end
    bin_path
  end
  @linux_only begin
    bin_path = "$archive_path/bin/julia"
    tar_path = "/tmp/julia-$v.tar.gz"

    if isfile(bin_path) return bin_path end

    run(`wget -O $tar_path https://julialang.s3.amazonaws.com/bin/linux/x64/0.$(v.minor)/julia-$v-linux-x86_64.tar.gz`)
    run(`mkdir -p $archive_path`)
    run(`tar xf $tar_path -C $archive_path --strip-components=1`)
    bin_path
  end
end

function getconfig()
  js = JSON.parse(readall(open("JDEPS")))
  version = VersionNumber(js["julia"])
  deps = Array{Dep,1}()
  for (n, v) in js["deps"]
    push!(deps, Dep(n, ascii(v)))
  end
  JDEPS(version, deps)
end

function writeconfig(jdeps::JDEPS)
  v = jdeps.julia
  d = Dict()
  d["julia"] = "v$(v.major).$(v.minor).$(v.patch)"
  if !haskey(d, "deps")
    d["deps"] = Dep[]
  end
  js = json(d, 2)
  write(open("JDEPS", "w"), js)
end

function initconfig()
  writeconfig(JDEPS())
end

# function getdeps()
#   deps = Array{Dep,1}()
#   for ln in readlines(open("JDEPS"))
#     if length(ln) > 1
#       push!(deps, Dep(split(ln)...))
#     end
#   end
#   deps
# end
#
# getdep(n::AbstractString) = find((d) -> d.name == n, getdeps())
#
# function writedeps(deps::Array{Dep})
#   mv("JDEPS", "/tmp/JDEPS.bak"; remove_destination=true)
#   write(open("JDEPS", "w"), join(map((dep) -> "$(dep.name) $(dep.version)", sort(deps)), '\n'))
# end
