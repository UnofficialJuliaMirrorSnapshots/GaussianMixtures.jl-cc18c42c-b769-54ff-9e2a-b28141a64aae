## data.jl Test some functionality of the Data type
## (c) 2015 David A. van Leeuwen
using Logging
using Distributed

@info("Testing Data")

using JLD
for i = 1:10
    save("$i.jld", "data", randn(10000,3))
end
x = Matrix{Float64}[load("$i.jld", "data") for i=1:10]

using GaussianMixtures

g = rand(GMM, 2, 3)
d = Data(x)
dd = Data(["$i.jld" for i=1:10], Float64)

f1(gmm, data) = GaussianMixtures.dmapreduce(x->stats(gmm, x), +, data)
f2(gmm, data) = reduce(+, map(x->stats(gmm, x), data))

sleep(1)
println(f2(g,dd))

import Base.isapprox
isapprox(a::Array, b::Array) = size(a)==size(b) && all(i->isapprox(a[i], b[i]), 1:length(a))
isapprox(a::Tuple, b::Tuple) = all(Bool[isapprox(x,y) for (x,y) in zip(a,b)])

s = stats(g, collect(d))

@assert isapprox(s, f1(g,d))
@assert isapprox(s, f1(g,dd))
@assert isapprox(s, f2(g,d))
@assert isapprox(s, f2(g,dd))

@assert isapprox(s, stats(g,d))
@assert isapprox(s, stats(g,dd))
@assert isapprox(s, stats(g,d, parallel=true))
@assert isapprox(s, stats(g,dd, parallel=true))

rmprocs(workers())
