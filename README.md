# Data Wrangling

## Environment Setup

Activating environment:

```julia
using Pkg; Pkg.activate("DataWrangling.jl")
```

Notebook development:

```jl
using Pluto; Pluto.run()
```

Pluto as a web service:

```sh
julia --eval 'using Pluto; Pluto.run(require_secret_for_access=false, launch_browser=false)'
```
