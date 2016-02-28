# Run the tests on versions listed in config
function test()
  for p in config.test
    @show p
  end
end

function freeze(cfg::Config)
  deps = Array{Dep,1}()
  for (p, v) in Pkg.installed()
    if isgit(p)
      push!(deps, Dep(p, getsha(p)))
    else
      push!(deps, Dep(p, v))
    end
  end
  cfg.deps = deps
  writeconfig(cfg)
end

function install_registered(dep::Dep)
  if !isdir(Pkg.dir(dep.name))
    Pkg.add(dep.name, dep.version)
  end
  v = Pkg.installed(dep.name)
  if v != dep.version
    Pkg.pin(dep.name, dep.version)
  end
end

function install_unregistered(dep::Dep)
  name = namefromgit(dep.name)
  if !isdir(Pkg.dir(name))
    Pkg.clone(dep.name)
  end
end

function install(cfg::Config)
  meta = ENV["JULIA_PKGDIR"]*"/$JULIA_VERSION/METADATA"
  if !isdir(meta)
    jevaluate(cfg, "Pkg.init()")
  end
  for d in cfg.deps
    if isgit(d.name)
      install_unregistered(d)
    else
      install_registered(d)
    end
  end
end

# function update(dep::Dep)
#   if isgit(dep.name)
#     pkg = namefromgit(dep.name)
#     try
#       gitcmd(pkg, "pull")
#     catch
#       warn("Error pulling $(dep.name)")
#     end
#     sha = getsha(pkg)
#     if sha != dep.version
#       info("Updating $pkg to SHA $sha")
#       dep.version = sha
#     end
#   else
#     nv = v"0.0.0"
#     for v in Pkg.available(dep.name)
#       if v > VersionNumber(dep.version)
#         nv = v
#       end
#     end
#     if nv > VersionNumber(dep.version)
#       info("Updating $(dep.name) to $nv")
#       dep.version = string(nv)
#       Pkg.pin(dep.name, nv)
#     end
#   end
# end
#
# function update()
#   gitcmd("METADATA", "pull origin metadata-v2")
#   deps = getdeps()
#   for dep in deps
#     update(dep)
#   end
#   writedeps(deps)
# end
#
# function update(name::AbstractString)
#   deps = getdeps()
#   ix = find((d) -> d.name == name || namefromgit(d.name) == name, deps)
#   if length(ix) == 0
#     error("Package $name not found")
#   end
#   update(deps[ix[1]])
#   writedeps(deps)
# end
#
# rmrequire() = begin
#   reqpath = joinpath(Pkg.dir(), "REQUIRE")
#   if isfile(reqpath)
#     rm(reqpath)
#   end
# end
#
# # Commands
#
# function init()
#   if !isdir(local_dir) mkdir(local_dir) end
#   Pkg.init()
#   initconfig()
#   rmrequire()
# end
#
# function freeze()
#   cur_deps = getdeps()
#   avail = Pkg.available()
#   deps = Array{Dep,1}()
#   for (p, v) in Pkg.installed()
#     if length(find((d) -> isgit(d.name) && namefromgit(d.name) == p, cur_deps)) > 0
#       push!(deps, Dep(geturl(p), getsha(p)))
#     else
#       if length(find((pkg) -> pkg == p, avail)) > 0
#         push!(deps, Dep(p, string(v)))
#       else
#         push!(deps, Dep(geturl(p), getsha(p)))
#       end
#     end
#   end
#   writedeps(deps)
# end
#
# # Enforce the versions specified in JDEPS
# function fix()
#   for dep in getdeps()
#     if isgit(dep.name)
#       pkg = namefromgit(dep.name)
#       gitcmd(pkg, "fetch --all")
#       if geturl(pkg) != dep.name
#         setorigin(dep.name)
#       end
#       info("Pinning $pkg at $(dep.version)")
#       gitcmd(pkg, "reset --hard $(dep.version)")
#     else
#       Pkg.pin(dep.name, VersionNumber(dep.version))
#     end
#   end
# end
#
# function add(pkg::AbstractString, v::AbstractString)
#   deps = getdeps()
#   if isdir(Pkg.dir(namefromgit(pkg)))
#     warn("Replacing existing installation of $(namefromgit(pkg))")
#     rm(Pkg.dir(namefromgit(pkg)); recursive=true)
#     ex = find((d) -> d.name == namefromgit(pkg), deps)
#     if length(ex) > 0
#       splice!(deps, ex[1])
#     end
#   end
#   if isgit(pkg)
#     Pkg.clone(pkg)
#     if v != "" checkout(namefromgit(pkg), v) end
#     push!(deps, Dep(pkg, getsha(namefromgit(pkg))))
#     writedeps(deps)
#   else
#     if v != "" Pkg.add(pkg, VersionNumber(v)) else Pkg.add(pkg) end
#     if v != "" Pkg.pin(pkg, VersionNumber(v)) else Pkg.pin(pkg) end
#     freeze()
#   end
# end
#
# add(pkg::AbstractString) = add(pkg, "")
#
# function install_registered(dep::Dep)
#   if !isdir(Pkg.dir(dep.name))
#     Pkg.add(dep.name, VersionNumber(dep.version))
#   end
# end
#
# function install_unregistered(dep::Dep)
#   name = namefromgit(dep.name)
#   if !isdir(Pkg.dir(name))
#     Pkg.clone(dep.name)
#   end
# end
#
# function install()
#   if !isfile("JDEPS")
#     error("No JDEPS file in this directory!")
#   end
#   if !isdir(joinpath(Pkg.dir(), "METADATA"))
#     init()
#   else
#     gitcmd("METADATA", "pull origin metadata-v2")
#   end
#   for dep in getdeps()
#     if isgit(dep.name)
#       install_unregistered(dep)
#     else
#       install_registered(dep)
#     end
#   end
#   fix()
#   Pkg.build()
# end
#
# function revert()
#   mv("/tmp/JDEPS.bak", "JDEPS"; remove_destination=true)
#   install()
# end
#
# function package()
#   if isfile(archive_name)
#     rm(archive_name)
#   end
#   info("Copying files...")
#   if isdir(package_dir)
#     rm(package_dir; recursive=true)
#   end
#   cp(".jdeps", package_dir)
#
#   info("Cleaning package sources...")
#   run(`rm $package_dir/$JULIA_VERSION/.cache`)
#   run(`rm -rf $package_dir/.cache/*`)
#
#   ENV["JULIA_PKGDIR"] = package_dir
#   # Remove Homebrew, in case we are on a Mac
#   if isdir(Pkg.dir("Homebrew"))
#     rm(Pkg.dir("Homebrew"); recursive=true)
#   end
#   # Remove all submodules, they may contain incompatible artifacts
#   cur_dir = pwd()
#   for p in readdir(Pkg.dir())
#     path = joinpath(Pkg.dir(), p)
#     if isdir(path)
#       cd(path)
#       paths = map((ln) -> split(chomp(ln)), readlines(`git submodule`))
#       for sub in paths
#         rm(joinpath(Pkg.dir(p), sub[2]); recursive=true)
#       end
#     end
#   end
#
#   for p in Pkg.installed()
#     gitclean(p[1])
#   end
#
#   info("Creating tarball...")
#   cd(cur_dir)
#   run(`tar -czf julia_pkgs.tar.gz -C /tmp .jdeps.pkg`)
#   ENV["JULIA_PKGDIR"] = local_dir
# end
