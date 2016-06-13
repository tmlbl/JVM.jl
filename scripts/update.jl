for p in Pkg.installed()
  try
    Pkg.free(p[1])
  catch err
    warn(err)
  end
end

Pkg.update()
