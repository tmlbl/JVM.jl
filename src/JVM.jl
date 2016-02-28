__precompile__()

module JVM

using JSON, Mustache

local_dir = ""
package_dir = "/tmp/.jdeps.pkg"
archive_name = "julia_pkgs.tar.gz"
JULIA_VERSION = ""
const DEFAULT_VERSION = v"0.4.3"
const CONFIG_FILE = ".jvm.json"

include("util.jl")
include("getbinary.jl")
include("Config.jl")
include("tasks.jl")
include("cli.jl")

# Localize the package directory
function localize()
  # Hack to fix the library load path.
  Base.LOAD_CACHE_PATH[1] =
    joinpath(local_dir, "lib/$JULIA_VERSION")
  if isfile(CONFIG_FILE)
    global config = getconfig()
    ENV["JULIA_PKGDIR"] = "$local_dir/$(config.julia)"
  else
    ENV["JULIA_PKGDIR"] = "$local_dir/$DEFAULT_VERSION"
  end
  run(`mkdir -p $(ENV["JULIA_PKGDIR"])`)
end

function __init__()
  global JULIA_PKGDIR_ORIG = Pkg.dir()
  global local_dir = joinpath(pwd(), ".jvm")
  global JULIA_VERSION = "v$(VERSION.major).$(VERSION.minor)"
end

end # module
