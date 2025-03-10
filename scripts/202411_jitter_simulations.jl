# Activate DrWatson
using DrWatson
@quickactivate :BreakUnfold


dicts = set_up_parameters([FRP_sim]; width=[5, 10, 15, 20, 30], seed=collect(1:10), sfreq=100)

# Simulations
all_results = DataFrame()
#all_results_RT = DataFrame()
pbar = ProgressBar(total=size(dicts, 1))

@time for d in dicts
    update(pbar)
    tmp_data, tmp_file = produce_or_load(jitter_simulation, d, datadir("jitter_simulations"); force=true, tag=false)
    append!(all_results, tmp_data)
end