# Activate DrWatson
using DrWatson
@quickactivate :BreakUnfold

# Space for parameters
allparams = Dict(
    "noiselevel" => collect(1:3),
    "shuffle" => [false], # random order sequence?
    "offset" => [2], # Event onset offset -> influences overlap
    "width" => [20], # Width of distribution -> determines jitter; 0 = no jitter
    "seed" => collect(1:5),
    "sfreq" => 100,
    "τ" => (-0.1, 1)
)

dicts = dict_list(tosymboldict(allparams))
# Simulations

all_results = DataFrame()
for d in dicts
    append!(all_results, jitter_simulation(d))
end