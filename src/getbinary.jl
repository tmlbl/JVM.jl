# Verify or install Julia version, and get the path to the binary

function getbinary(v::VersionNumber)
  HOME = ENV["HOME"]
  run(`mkdir -p $HOME/.jvm/julia`)
  archive_path = "$HOME/.jvm/julia/$v"

  # Julia changed the OS-specific macros, so let's just sniff it ourselves
  uname = chomp(readstring(`uname`))

  # OS X
  if uname == "Darwin"
    # We download and mount the disk image, copy everything out, then delete it.
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
    return bin_path
  end

  # Linux
  if uname == "Linux"
    # Linux is the easiest, of course
    bin_path = "$archive_path/bin/julia"
    tar_path = "/tmp/julia-$v.tar.gz"

    if isfile(bin_path) return bin_path end

    run(`wget -O $tar_path https://julialang.s3.amazonaws.com/bin/linux/x64/0.$(v.minor)/julia-$v-linux-x86_64.tar.gz`)
    run(`mkdir -p $archive_path`)
    run(`tar xf $tar_path -C $archive_path --strip-components=1`)
    return bin_path
  end
end
