# Activate DrWatson
using DrWatson
@quickactivate :BreakUnfold

# Space for parameters
allparams = Dict(
"noiselevel" => collect(0:0.5:3),
"shuffle" => [false, true], # random order sequence?
"offset" => [1, 2], # Event onset offset -> influences overlap
"width" => [20, 40], # Width of distribution -> determines jitter; 0 = no jitter
"seed" => collect(1:5)
)

dicts = dict_list(allparams)
# Simulations

