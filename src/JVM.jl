__precompile__()

module JVM

using ArgParse

local_dir = ""
package_dir = "/tmp/.jdeps.pkg"
archive_name = "julia_pkgs.tar.gz"
JULIA_VERSION = ""

include("util.jl")
include("Deps.jl")
include("tasks.jl")
include("cli.jl")

# Localize the package directory
function __init__()
  global local_dir = joinpath(pwd(), ".jdeps")
  global JULIA_VERSION = "v$(VERSION.major).$(VERSION.minor)"
  # info("Setting JULIA_PKGDIR to $local_dir")
  ENV["JULIA_PKGDIR"] = local_dir
  # Hack to fix the library load path.
  Base.LOAD_CACHE_PATH[1] =
    joinpath(local_dir, "lib/$JULIA_VERSION")
  if isfile("JDEPS")
    global config = getconfig()
  end

  # rcpath = "$(ENV["HOME"])/.juliarc.jl"
  # @show rcpath
  # if isfile(rcpath)
  #   run(`mv $rcpath $rcpath.bak`)
  #   atexit() do
  #     run(`mv $rcpath.bak $rcpath`)
  #   end
  # end
end

end # module
