__precompile__()

module JVM

using JSON

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
function __init__()
  global local_dir = joinpath(pwd(), ".jvm")
  global JULIA_VERSION = "v$(VERSION.major).$(VERSION.minor)"
  # info("Setting JULIA_PKGDIR to $local_dir")
  ENV["JULIA_PKGDIR"] = local_dir
  # Hack to fix the library load path.
  Base.LOAD_CACHE_PATH[1] =
    joinpath(local_dir, "lib/$JULIA_VERSION")
  if isfile(CONFIG_FILE)
    global config = getconfig()
  end
end

end # module
