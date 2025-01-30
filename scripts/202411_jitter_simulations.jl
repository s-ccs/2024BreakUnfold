# Activate DrWatson
using DrWatson
@quickactivate :BreakUnfold

# Space for parameters
allparams = Dict(
    "noiselevel" => [7],#collect(3:6),
    "shuffle" => [false], # random order sequence?
    "offset" => [10], # Event onset offset -> influences overlap
    "width" => [5, 10, 15, 20, 30, 40, 50], # Width of distribution -> determines jitter; 0 = no jitter
    "seed" => collect(1:25),
    "sfreq" => 100,
    "τ" => (-0.1, 1)
)

dicts = dict_list(tosymboldict(allparams))

# Simulations
all_results_FRP = DataFrame()
all_results_RT = DataFrame()
pbar = ProgressBar(total=size(dicts, 1))

@time for d in dicts
    update(pbar)
    append!(all_results_FRP, jitter_simulation(d, FRP_sim))
    append!(all_results_RT, jitter_simulation(d, RT_sim))
end