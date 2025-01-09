# Activate DrWatson
using DrWatson
@quickactivate :BreakUnfold

# Space for parameters
allparams = Dict(
    "noiselevel" => [7],#collect(3:6),
    "shuffle" => [false], # random order sequence?
    "offset" => [5], # Event onset offset -> influences overlap
    "width" => [5, 10, 15, 20, 30, 40, 50], # Width of distribution -> determines jitter; 0 = no jitter
    "seed" => collect(1:50),
    "sfreq" => 100,
    "τ" => (-0.1, 1)
)

dicts = dict_list(tosymboldict(allparams))

# Simulations
all_results = DataFrame()
@time for d in dicts
    append!(all_results, jitter_simulation(d))
end