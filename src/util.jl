# Utils

isgit(str::AbstractString) = ismatch(r"^https|\@|^git", str)

namefromgit(url::AbstractString) = begin
  n = string(match(r"([^/]+$)", url).match)
  n = replace(n, ".jl", "")
  n = replace(n, ".git", "")
  n
end

gitcmd(pkg::AbstractString, cmd::AbstractString) =
    chomp(readall(`$(Pkg.Git.git(Pkg.dir(pkg))) $(split(cmd, ' '))`))

getsha(pkg::AbstractString) = gitcmd(pkg, "rev-parse HEAD")

checkout(pkg::AbstractString, sha::AbstractString) = gitcmd(pkg, "checkout $sha")

gitclean(pkg::AbstractString) = gitcmd(pkg, "clean -dfxq")

geturl(pkg::AbstractString) = gitcmd(pkg, "config --get remote.origin.url")

setorigin(url::AbstractString) = begin
  pkg = namefromgit(url)
  gitcmd(pkg, "remote rm origin")
  gitcmd(pkg, "remote add origin $url")
  gitcmd(pkg, "fetch --all")
end
