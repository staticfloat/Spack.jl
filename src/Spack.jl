module Spack

# Utilities for dealing with Pkg, Manifests, etc...
include("pkgutil.jl")

# Map JLL names to Spack names
include("mapping.jl")

# Become the puppet master
include("spackwrap.jl")

end # module
