### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# ╔═╡ 0e571d6f-5057-43ae-a088-fd331c56c34d
using Statistics, DataFrames, Query, VegaDatasets, VegaLite

# ╔═╡ 36466299-8faa-4d17-b2e4-ea9674f5cfce
using Dates

# ╔═╡ 1c405ed8-30ba-11ee-34e3-8d9c2987354e
md"""
# Lab 3. Aggregation
"""

# ╔═╡ f9fd43f6-ba16-4b6f-bf03-a8133b977d74
md"""
Let's try our hand on "disasters", a dataframe from the VegaDatasets
collection.
"""

# ╔═╡ fd9a575f-4763-45c5-ae6d-3306f7b54672
dissd = dataset("disasters") |>
  DataFrame

# ╔═╡ 3ad26b5f-ac12-4269-830d-12d1b901b13e
md"""
Let's have an overall quick look at the dataframe:
"""

# ╔═╡ 48301d24-3dc0-40e5-87d5-45db6da94a53
dissd |> describe

# ╔═╡ 16835fab-46b2-438c-b7ed-9fd272ba8b72
md"""
"All natural disasters" seems to be a _summary_ of the other entities.
Let's filter out the rows with `Entity == "All natural disasters"`:
"""

# ╔═╡ b8776f55-ae25-4247-828d-7ee50d35fe5f
dissd_noall = dissd |>
  @filter(_.Entity .!= "All natural disasters") |>
  DataFrame

# ╔═╡ c0af5362-14a1-4a8d-bc05-15898b8e3582
dissd_noall |> describe

# ╔═╡ 51fb2488-3ff0-43b8-b6eb-bcfa5632940b
md"""
We want to obtain the median number of deaths for each entity.
"""

# ╔═╡ 051b6c55-ac4a-430c-b849-7eae2f99091f
combine(groupby(dissd_noall, :Entity), :Deaths => median)

# ╔═╡ 44e1acb7-928c-4d5b-bec3-068d0e9f7a44
md"""
Similarly, we can compute the total sum over the entities for each year:
"""

# ╔═╡ 877ea758-20e0-44be-98ff-4f0e74613aa2
combine(groupby(dissd_noall, :Year), :Deaths => sum)

# ╔═╡ b0b08b2a-3f93-42bf-99cf-87438f31a61b
md"""
The other approach is by using `aggregate` which will apply one (or more)
functions to **all** of the columns of the dataframe.
"""

# ╔═╡ 19d48171-8839-423d-a0bf-52c5408c337f
combine(groupby(dissd_noall, :Entity), [:Deaths,:Year] .=> [median])

# ╔═╡ 25a71267-a676-4089-b8cc-991e45f1c78a
combine(
	groupby(dissd_noall, :Entity),
	[:Deaths] .=> [median, mean, sum],
	[:Year] .=> [median, mean, sum]
)

# ╔═╡ 3f257a65-6869-4e1f-83e3-be788dc2b9e1
md"""
As the function is applied over all the columns, some non meaningful `Year_`
columns are created.
We need to select them out. We can use `@map` to do that.
Notice that in this use of `@map` we are not applying any function, but only
selecting certain columns an dropping other
(_well, actually,_ we are applying the _indicator function_, look it up if
you want the maths of it).
"""

# ╔═╡ feeea522-1b3e-476d-9300-c828fb96af2a
combine(
	groupby(dissd_noall, :Entity),
	[:Deaths] .=> [median, mean, sum],
	[:Year] .=> [median, mean, sum]
) |> @map({_.Entity, _.Deaths_median, _.Deaths_mean, _.Deaths_sum})

# ╔═╡ 1dc15739-cb93-4397-9939-7f7f7765c552
md"""
However, `aggregate()` is often too rigid (even if quite performing) because he
will apply the function over all the columns, and sometimes that's just not
possible:
"""

# ╔═╡ 0dc370a2-0548-41e8-aa4a-c0fce35596dd
# **! expect Error !**
# aggregate(dissd_noall, :Year, sum)

# ╔═╡ 6c5d7b93-8ba9-434f-84a1-47048aefc4f2
md"""
Here we are trying to sum over strings (the `:Entity` column) and that's a
mistake.
The library "query" offers us another way of doing this, `@group_by` and
`@map`.
This approach is similar to what can be done with `by` and `do` but works on a
wide variety of data types.
"""

# ╔═╡ 96995e39-f7d3-40e6-8092-3481c584275a
dissd_noall |>
  @groupby(_.Year)

# ╔═╡ a8145680-381a-47d3-8704-0519dc52bde9
md"""
What happend is that now instead of 1 dataframe where everything is on the same
"level" we have a dataframe where one column is the "key" of the group
(in this case "Year")
and in the other columns each rows contains a dataframe
(where Year is equal to the key).
Let's see this.

First, the key:
"""

# ╔═╡ beda8e9c-6c0d-484e-b6e4-9bc3bba78c2a
dissd_noall |>
  @groupby(_.Year) |>
  @map({YearKey = key(_)}) |>
  DataFrame

# ╔═╡ 1005ff2c-8439-4ce8-a0d2-e69dbe43095f
md"""
And now the rest as well. Notice that although we use the same dot notation, we
are actually digging one level deeper
(the information is within the dataframe in the row).
"""

# ╔═╡ 58a0712a-0355-4c2a-9195-8224ef0088cc
dissd_noall |>
  @groupby(_.Year) |>
  @map({YearKey = key(_), MedianDeaths = median(_.Deaths)}) |>
  DataFrame

# ╔═╡ 084deb30-b8d2-4a5a-9bfe-0f79ad77a495
md"""
The key is just one number, but the other two columns contain an array in each
row.
Now that we know where the information is, we can operate on it.
"""

# ╔═╡ ce42c0c7-21a3-4ad6-8f19-5525c7c1ed81
dissd_noall |>
  @groupby(_.Year) |>
  @map({YearKey = key(_), MedianDeaths = median(_.Deaths)}) |>
  DataFrame

# ╔═╡ 3af19234-2e52-4c33-b82e-19795ff65bae
md"""
## Exercises

modify the following code compute the overal total deaths sum over the Years
for each Entity.
"""

# ╔═╡ 24bf9ea7-5f7d-43e6-98bc-cdd21fc43a05
dissd_noall |>
  @groupby([_.Year, _.Entity]) |>
  @map({YearKey = key(_), SumDeaths = sum(_.Deaths)}) |>
  DataFrame

# ╔═╡ 9f5a8260-4eae-4967-9ce2-a1be41b53159
md"""
## Reshaping

The two verbs that allow to go from long to wide dataframes and back are
`stack()` and `unstack()`.
"""

# ╔═╡ 23cac9f5-3190-4213-b7d2-995ec404649b
wide_dissd = unstack(dissd, # the first argument is the dataframe
    :Entity, # we specify wich column to use as row id
    :Year, # we specify which column to widen
    :Deaths # and from which column to take the values
)

# ╔═╡ a82ee3e5-0801-4225-bc8f-7b72b7115361
md"""
And, for sure, we can make it long again.

But first we need to find all the names for the "year" variables we just
created:
`names()` will give us the variable names, and then we say that we do not want
the first one (as it is the Entity variable).
"""

# ╔═╡ 7b9f52bb-c43a-46ae-99f3-1493e33187a0
year_variables = names(wide_dissd)[2: end]

# ╔═╡ e86d2501-e332-48a4-8b17-98ad05a83092
long_dissd = stack(wide_dissd, # on which data to work
    year_variables,
    :Entity, # what information NOT to stack
)

# ╔═╡ 97c0db87-edd4-40b2-81cb-273902c1a895
long_dissd |> describe

# ╔═╡ 0999849a-3a17-418e-89bd-6f2f81799872
md"""
The elements of `Year` are of type `Symbol`.
"""

# ╔═╡ e1afbe0d-7d5f-471f-ac87-889429035531
long_dissd[!,:variable] |> typeof

# ╔═╡ 14c392fc-3262-4414-84d3-7ee91765fa5f
md"""
We need to do the conversion.
It's a two step thing: first, we convert the Symbol in a string:
"""

# ╔═╡ bfe39ed5-2b46-4841-9c22-a17c9fae8631
long_dissd[42, :variable] |> string

# ╔═╡ 200c5947-a602-4975-8c96-3457ff3e898c
md"""
Then, we use `Date()` from the packages Dates to convert the string into a
proper date.
"""

# ╔═╡ 92165aa1-2f3c-4d6f-a6fb-0eeffa6b1bee
long_dissd[42,:variable] |> string |> Date

# ╔═╡ efc04a5c-b8f6-4de5-ab80-9525abf83d0f
md"""
**Wait**, there is yeat another problem: the functions `string()` and `Date()`
work on simple values: one Symbol at a time, or one string at a time.
They are not built for arrays of values.

No problem: in Julia there's something call **broadcasting**.
To convert a function that works on single elements to a function that works on
arrays of elements we just need to put a dot (.) after it.
Let's see that in action with `string()`.
"""

# ╔═╡ bfb1a1fc-180d-4f92-9f39-f89211edea62
string.(long_dissd[!,:variable])

# ╔═╡ 2335b5de-a78e-49e7-afd8-40cf9fe97b68
md"""
## Exercises

When we first initialized long_dissd_dates we used the function `copy()`.
What is that?
What happened to the original long_dissd we copied?
Is it still the same?
"""

# ╔═╡ a0492706-0592-4771-819d-347f9129c0c2
long_dissd[1, :variable] |> typeof

# ╔═╡ 655605ed-00d3-4a55-8fb8-5ca7ddc4a09c
md"""
Uh, yes, all fine here: we worked on the copy, not the original, so it is as we
expected.
Now, let's try again by doing something different
(that is assigning with `=` without using `copy()`):
"""

# ╔═╡ 2a9691e1-0112-476e-8d6a-4dd8adbdbf4f
md"""
Let's do something to long_dissd_dates. What happens?
"""

# ╔═╡ 8e75da68-61b4-4ebb-9fb6-1e14beecd07e
long_dissd_dates[!,:variable] = Date.(string.(long_dissd_dates[!,:variable]))

# ╔═╡ a81bfabc-d968-49a0-9f90-00649a37811f
md"""
## Join

The joining in Julia is standard (ie not at all dissimilar from the joining on
R).

We will use an example offered in this
[tutorial](https://juliabox.com/notebook/notebooks/tutorials/intro-to-julia-DataFrames/08_joins.ipynb)
(you will need to register and login to access it, but it is surely worth it!).
"""

# ╔═╡ 02dad2a0-5288-4c7b-b012-986eb619e571
x = DataFrame(
	id=[1,2,3,4,missing],
	name = ["Alice", "Bob", "Conor", "Dave","Zed"])

# ╔═╡ 4c616092-c411-46a3-98e6-854d226bd04f
y = DataFrame(id=[1,2,5,6,missing], age = [21,22,23,24,99])

# ╔═╡ 6a90e9d5-c63d-4d44-a323-26c862610391
md"""
We want to know the age of those people. By default, it will be an
"""

# ╔═╡ 18f6eb53-0a4b-462e-9ca9-d9b1d7492b40
innerjoin(x, y, on=:id, matchmissing=:equal)

# ╔═╡ a70800f0-c102-490f-82c7-3d926aa723ec
# ╠═╡ disabled = true
#=╠═╡
begin
	long_dissd_dates = copy(long_dissd) # we make a copy of long_dissd to work on
	long_dissd_dates[!,:variable] = Date.(string.(long_dissd_dates[!,:variable])) ;
	long_dissd_dates |> describe
end
  ╠═╡ =#

# ╔═╡ 98cacff5-678a-4721-bcf6-4002358d97a2
long_dissd_dates = long_dissd # we assign directly long_dissd to long_dissd_dates

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
Query = "1a8c2f83-1ff3-5112-b086-8aa67b057ba1"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
VegaDatasets = "0ae4a718-28b7-58ec-9efb-cded64d6d5b4"
VegaLite = "112f6efa-9a02-5b7d-90c0-432ed331239a"

[compat]
DataFrames = "~1.6.1"
Query = "~1.0.0"
VegaDatasets = "~2.1.1"
VegaLite = "~3.2.3"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.2"
manifest_format = "2.0"
project_hash = "ba295d5b5b022a9e07f4a87100b2574e4581809c"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BufferedStreams]]
git-tree-sha1 = "5bcb75a2979e40b29eb250cb26daab67aa8f97f5"
uuid = "e1450e63-4bb3-523b-b2a4-4ffa8c0fd77d"
version = "1.2.0"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "02aa26a4cf76381be7f66e020a3eddeb27b0a092"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.2"

[[deps.Compat]]
deps = ["UUIDs"]
git-tree-sha1 = "5ce999a19f4ca23ea484e92a1774a61b8ca4cf8e"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.8.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.5+0"

[[deps.ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "fe2838a593b5f776e1597e086dcd47560d94e816"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.5.3"

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseStaticArraysExt = "StaticArrays"

    [deps.ConstructionBase.weakdeps]
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "8da84edb865b0b5b0100c0666a9bc9a0b71c553c"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.15.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "DataStructures", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrecompileTools", "PrettyTables", "Printf", "REPL", "Random", "Reexport", "SentinelArrays", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "04c738083f29f86e62c8afc341f0967d8717bdb8"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.6.1"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "cf25ccb972fec4e4817764d01c82386ae94f77b4"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.14"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.DataValues]]
deps = ["DataValueInterfaces", "Dates"]
git-tree-sha1 = "d88a19299eba280a6d062e135a43f00323ae70bf"
uuid = "e7dc6d0d-1eca-5fa6-8ad6-5aecde8b7ea5"
version = "0.4.13"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.DoubleFloats]]
deps = ["GenericLinearAlgebra", "LinearAlgebra", "Polynomials", "Printf", "Quadmath", "Random", "Requires", "SpecialFunctions"]
git-tree-sha1 = "ff64f5601c231a7bc730e1e4eba2c39035d6cc60"
uuid = "497a8b3b-efae-58df-a0af-a86822472b78"
version = "1.2.4"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "299dc33549f68299137e51e6d49a13b5b1da9673"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.16.1"

[[deps.FilePaths]]
deps = ["FilePathsBase", "MacroTools", "Reexport", "Requires"]
git-tree-sha1 = "919d9412dbf53a2e6fe74af62a73ceed0bce0629"
uuid = "8fc22ac5-c921-52a6-82fd-178b2807b824"
version = "0.8.3"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "e27c4ebe80e8699540f2d6c805cc12203b614f12"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.20"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GenericLinearAlgebra]]
deps = ["LinearAlgebra", "Printf", "Random", "libblastrampoline_jll"]
git-tree-sha1 = "02be7066f936af6b04669f7c370a31af9036c440"
uuid = "14197337-ba66-59df-a3e3-ca00e7dcff7a"
version = "0.3.11"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "9cc2baf75c6d09f9da536ddf58eb2f29dedaf461"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InvertedIndices]]
git-tree-sha1 = "0dc7b50b8d436461be01300fd8cd45aa0274b038"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.IterableTables]]
deps = ["DataValues", "IteratorInterfaceExtensions", "Requires", "TableTraits", "TableTraitsUtils"]
git-tree-sha1 = "70300b876b2cebde43ebc0df42bc8c94a144e1b4"
uuid = "1c8ee90f-4401-5389-894e-7a04a3dc0f4d"
version = "1.0.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JSONSchema]]
deps = ["Downloads", "JSON", "URIs"]
git-tree-sha1 = "9b922425fbb02fa7698cd950420aba6058cb79f1"
uuid = "7d188eb4-7ad8-530c-ae41-71a32a6d4692"
version = "1.2.0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "c3ce8e7420b3a6e071e0fe4745f5d4300e37b13f"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.24"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "42324d08725e200c23d4dfb549e0d5d89dede2d2"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.10"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.10.11"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.NodeJS]]
deps = ["Pkg"]
git-tree-sha1 = "bf1f49fd62754064bc42490a8ddc2aa3694a8e7a"
uuid = "2bd173c7-0d6d-553b-b6af-13a54713934c"
version = "2.0.0"

[[deps.Nullables]]
git-tree-sha1 = "8f87854cc8f3685a60689d8edecaa29d2251979b"
uuid = "4d1e1d77-625e-5b40-9113-a560ec7a8ecd"
version = "1.0.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.21+4"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "2e73fe17cac3c62ad1aebe70d44c963c3cfdc3e3"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.2"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "716e24b21538abc91f6205fd1d8363f39b442851"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.7.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.9.2"

[[deps.Polynomials]]
deps = ["LinearAlgebra", "RecipesBase"]
git-tree-sha1 = "3aa2bb4982e575acd7583f01531f241af077b163"
uuid = "f27b6e38-b328-58d1-80ce-0feddd5e7a45"
version = "3.2.13"

    [deps.Polynomials.extensions]
    PolynomialsChainRulesCoreExt = "ChainRulesCore"
    PolynomialsMakieCoreExt = "MakieCore"
    PolynomialsMutableArithmeticsExt = "MutableArithmetics"

    [deps.Polynomials.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    MakieCore = "20f20a25-4f0e-4fdf-b5d1-57303727442b"
    MutableArithmetics = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "9673d39decc5feece56ef3940e5dafba15ba0f81"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.1.2"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "7eb1686b4f04b82f96ed7a4ea5890a4f0c7a09f1"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.0"

[[deps.PrettyTables]]
deps = ["Crayons", "LaTeXStrings", "Markdown", "Printf", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "ee094908d720185ddbdc58dbe0c1cbe35453ec7a"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.2.7"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Quadmath]]
deps = ["Compat", "Printf", "Random", "Requires"]
git-tree-sha1 = "15c8465e3cb37b6bf3abcc0a4c9440799f2ba3fb"
uuid = "be4d8f0f-7fa4-5f49-b795-2f01399ab2dd"
version = "0.5.9"

[[deps.Query]]
deps = ["DataValues", "IterableTables", "MacroTools", "QueryOperators", "Statistics"]
git-tree-sha1 = "a66aa7ca6f5c29f0e303ccef5c8bd55067df9bbe"
uuid = "1a8c2f83-1ff3-5112-b086-8aa67b057ba1"
version = "1.0.0"

[[deps.QueryOperators]]
deps = ["DataStructures", "DataValues", "IteratorInterfaceExtensions", "TableShowUtils"]
git-tree-sha1 = "911c64c204e7ecabfd1872eb93c49b4e7c701f02"
uuid = "2aef5ad7-51ca-5a8f-8e88-e75cf067b44b"
version = "0.9.3"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "5c3d09cc4f31f5fc6af001c250bf1278733100ff"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.4"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "04bdff0b09c65ff3e06a05e3eb7b120223da3d39"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "e2cc6d8c88613c05e1defb55170bf5ff211fbeac"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.1"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "c60ec5c62180f27efea3ba2908480f8055e17cee"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.1.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "7beb031cf8145577fbccacd94b8a8f4ce78428d3"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.3.0"

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

    [deps.SpecialFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"

[[deps.StaticArraysCore]]
git-tree-sha1 = "36b3d696ce6366023a0ea192b4cd442268995a0d"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.2"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.9.0"

[[deps.StringManipulation]]
git-tree-sha1 = "46da2434b41f41ac3594ee9816ce5541c6096123"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.3.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "5.10.1+6"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableShowUtils]]
deps = ["DataValues", "Dates", "JSON", "Markdown", "Unicode"]
git-tree-sha1 = "2a41a3dedda21ed1184a47caab56ed9304e9a038"
uuid = "5e66a065-1f0a-5976-b372-e0b8c017ca10"
version = "0.2.6"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.TableTraitsUtils]]
deps = ["DataValues", "IteratorInterfaceExtensions", "Missings", "TableTraits"]
git-tree-sha1 = "78fecfe140d7abb480b53a44f3f85b6aa373c293"
uuid = "382cd787-c1b6-5bf2-a167-d5b971a19bda"
version = "1.0.2"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "1544b926975372da01227b382066ab70e574a3ec"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.10.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TextParse]]
deps = ["CodecZlib", "DataStructures", "Dates", "DoubleFloats", "Mmap", "Nullables", "WeakRefStrings"]
git-tree-sha1 = "eb1f4fb185c8644faa2d18d14c72f2c24412415f"
uuid = "e0df1984-e451-5cb5-8b61-797a481e67e3"
version = "1.0.2"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "9a6ae7ed916312b41236fcef7e0af564ef934769"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.13"

[[deps.URIParser]]
deps = ["Unicode"]
git-tree-sha1 = "53a9f49546b8d2dd2e688d216421d050c9a31d0d"
uuid = "30578b45-9adc-5946-b283-645ec420af67"
version = "0.4.1"

[[deps.URIs]]
git-tree-sha1 = "074f993b0ca030848b897beff716d93aca60f06a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.2"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Vega]]
deps = ["BufferedStreams", "DataStructures", "DataValues", "Dates", "FileIO", "FilePaths", "IteratorInterfaceExtensions", "JSON", "JSONSchema", "MacroTools", "NodeJS", "Pkg", "REPL", "Random", "Setfield", "TableTraits", "TableTraitsUtils", "URIParser"]
git-tree-sha1 = "9d5c73642d291cb5aa34eb47b9d71428c4132398"
uuid = "239c3e63-733f-47ad-beb7-a12fde22c578"
version = "2.6.2"

[[deps.VegaDatasets]]
deps = ["DataStructures", "DataValues", "FilePaths", "IterableTables", "IteratorInterfaceExtensions", "JSON", "TableShowUtils", "TableTraits", "TableTraitsUtils", "TextParse"]
git-tree-sha1 = "c997c7217f37205c5795de8c797f8f8531890f1d"
uuid = "0ae4a718-28b7-58ec-9efb-cded64d6d5b4"
version = "2.1.1"

[[deps.VegaLite]]
deps = ["Base64", "BufferedStreams", "DataStructures", "DataValues", "Dates", "FileIO", "FilePaths", "IteratorInterfaceExtensions", "JSON", "MacroTools", "NodeJS", "Pkg", "REPL", "Random", "TableTraits", "TableTraitsUtils", "URIParser", "Vega"]
git-tree-sha1 = "4ac2ad3d9d389ddccc862514160140768bbb5f56"
uuid = "112f6efa-9a02-5b7d-90c0-432ed331239a"
version = "3.2.3"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
"""

# ╔═╡ Cell order:
# ╟─1c405ed8-30ba-11ee-34e3-8d9c2987354e
# ╠═0e571d6f-5057-43ae-a088-fd331c56c34d
# ╟─f9fd43f6-ba16-4b6f-bf03-a8133b977d74
# ╠═fd9a575f-4763-45c5-ae6d-3306f7b54672
# ╟─3ad26b5f-ac12-4269-830d-12d1b901b13e
# ╠═48301d24-3dc0-40e5-87d5-45db6da94a53
# ╟─16835fab-46b2-438c-b7ed-9fd272ba8b72
# ╠═b8776f55-ae25-4247-828d-7ee50d35fe5f
# ╠═c0af5362-14a1-4a8d-bc05-15898b8e3582
# ╟─51fb2488-3ff0-43b8-b6eb-bcfa5632940b
# ╠═051b6c55-ac4a-430c-b849-7eae2f99091f
# ╟─44e1acb7-928c-4d5b-bec3-068d0e9f7a44
# ╠═877ea758-20e0-44be-98ff-4f0e74613aa2
# ╟─b0b08b2a-3f93-42bf-99cf-87438f31a61b
# ╠═19d48171-8839-423d-a0bf-52c5408c337f
# ╠═25a71267-a676-4089-b8cc-991e45f1c78a
# ╟─3f257a65-6869-4e1f-83e3-be788dc2b9e1
# ╠═feeea522-1b3e-476d-9300-c828fb96af2a
# ╟─1dc15739-cb93-4397-9939-7f7f7765c552
# ╠═0dc370a2-0548-41e8-aa4a-c0fce35596dd
# ╟─6c5d7b93-8ba9-434f-84a1-47048aefc4f2
# ╠═96995e39-f7d3-40e6-8092-3481c584275a
# ╟─a8145680-381a-47d3-8704-0519dc52bde9
# ╠═beda8e9c-6c0d-484e-b6e4-9bc3bba78c2a
# ╟─1005ff2c-8439-4ce8-a0d2-e69dbe43095f
# ╠═58a0712a-0355-4c2a-9195-8224ef0088cc
# ╟─084deb30-b8d2-4a5a-9bfe-0f79ad77a495
# ╠═ce42c0c7-21a3-4ad6-8f19-5525c7c1ed81
# ╟─3af19234-2e52-4c33-b82e-19795ff65bae
# ╠═24bf9ea7-5f7d-43e6-98bc-cdd21fc43a05
# ╟─9f5a8260-4eae-4967-9ce2-a1be41b53159
# ╠═23cac9f5-3190-4213-b7d2-995ec404649b
# ╟─a82ee3e5-0801-4225-bc8f-7b72b7115361
# ╠═7b9f52bb-c43a-46ae-99f3-1493e33187a0
# ╠═e86d2501-e332-48a4-8b17-98ad05a83092
# ╠═97c0db87-edd4-40b2-81cb-273902c1a895
# ╟─0999849a-3a17-418e-89bd-6f2f81799872
# ╠═e1afbe0d-7d5f-471f-ac87-889429035531
# ╟─14c392fc-3262-4414-84d3-7ee91765fa5f
# ╠═bfe39ed5-2b46-4841-9c22-a17c9fae8631
# ╟─200c5947-a602-4975-8c96-3457ff3e898c
# ╠═36466299-8faa-4d17-b2e4-ea9674f5cfce
# ╠═92165aa1-2f3c-4d6f-a6fb-0eeffa6b1bee
# ╟─efc04a5c-b8f6-4de5-ab80-9525abf83d0f
# ╠═bfb1a1fc-180d-4f92-9f39-f89211edea62
# ╠═a70800f0-c102-490f-82c7-3d926aa723ec
# ╟─2335b5de-a78e-49e7-afd8-40cf9fe97b68
# ╠═a0492706-0592-4771-819d-347f9129c0c2
# ╟─655605ed-00d3-4a55-8fb8-5ca7ddc4a09c
# ╠═98cacff5-678a-4721-bcf6-4002358d97a2
# ╟─2a9691e1-0112-476e-8d6a-4dd8adbdbf4f
# ╠═8e75da68-61b4-4ebb-9fb6-1e14beecd07e
# ╟─a81bfabc-d968-49a0-9f90-00649a37811f
# ╠═02dad2a0-5288-4c7b-b012-986eb619e571
# ╠═4c616092-c411-46a3-98e6-854d226bd04f
# ╟─6a90e9d5-c63d-4d44-a323-26c862610391
# ╠═18f6eb53-0a4b-462e-9ca9-d9b1d7492b40
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
