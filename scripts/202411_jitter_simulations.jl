# Activate DrWatson
using DrWatson
@quickactivate :BreakUnfold

# FRP, RT, NAT simulations
force_simulation = false
dicts = set_up_parameters([RT_sim, FRP_sim, NAT_sim]; shuffle=[true, false], offset=[15], width=[1, 5, 10, 20, 30, 50, 100], seed=collect(1:50), sfreq=100, ntrials=[200]) 

# Simulations
all_results = DataFrame()
#all_results_RT = DataFrame()
pbar = ProgressBar(total=size(dicts, 1))
@time for d in dicts
    update(pbar)
    tmp_data, tmp_file = produce_or_load(jitter_simulation, d, datadir("jitter_simulations"); force=force_simulation, tag=false)
    
    if typeof(tmp_data) == Dict{String, Any}
        append!(all_results, tmp_data["df"])
    else
        append!(all_results, tmp_data)
    end 
end