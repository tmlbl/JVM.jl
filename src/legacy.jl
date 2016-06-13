function legacy_getdeps()
  deps = Array{Dep,1}()
  for ln in readlines(open("JDEPS"))
    if length(ln) > 1
      name = ascii(split(ln)[1])
      version = ascii(split(ln)[2])

      if isgit(name)
        push!(deps, Dep(name, version))
      else
        push!(deps, Dep(name, VersionNumber(version)))
      end
    end
  end
  deps
end

function update_env()
  if isfile("JDEPS") && !isfile(CONFIG_FILE)
    print_with_color(:yellow, "WARNING: v1 environment detected, update automatically [Y/n]? ")
    input = readline(STDIN)
    if ismatch(r"[yY]", input) || input == "\n"
      if !isfile(CONFIG_FILE)
        initconfig()
      end
      localize()
      ldeps = legacy_getdeps()
      config.deps = ldeps
      info("Writing $(length(ldeps)) deps to new config format...")
      writeconfig(config)
      install(config)
      info("You may now remove JDEPS and the .jdeps/ directory")
    else
      exit()
    end
  end
end
