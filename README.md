# gmsh.jl (Julia package)

This repository is intended to provide **simpler and smoother setup** of gmsh
for julia.  If you are new to gmsh, please check out [here](http://gmsh.info/). 

 To install the package, use the following

## Installation

```julia
]add https://github.com/338rajesh/gmsh.jl
```

## Setup
After installation, one can proceed to setup the gmsh to the version of interest.

For example, to setup 4.9.4 version
```julia
using gmsh
gmsh.setup.run(;req_version="4.9.4")  # replace 4.9.4 with version of interest
```

**Note**: At the end of installation, restart the REPL session to see the effect
of new version of gmsh.

## What this package does?
It pulls the binaries of respective gmsh version, suitable for your operating
system, from the official source and places them in the directory of gmsh
package in julia depot.
