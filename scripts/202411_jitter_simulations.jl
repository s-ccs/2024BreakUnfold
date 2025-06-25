# Activate DrWatson
using DrWatson
@quickactivate :BreakUnfold

# FRP, RT, NAT simulations
dicts = set_up_parameters([FRP_sim, NAT_sim]; offset=[15], width=[5, 10, 20, 30, 50, 100], seed=collect(1:10), sfreq=100)

# Simulations
all_results = DataFrame()
#all_results_RT = DataFrame()
pbar = ProgressBar(total=size(dicts, 1))
@time for d in dicts
    update(pbar)
    tmp_data, tmp_file = produce_or_load(jitter_simulation, d, datadir("jitter_simulations"); force=true, tag=false)
    
    if typeof(tmp_data) == Dict{String, Any}
        append!(all_results, tmp_data["df"])
    else
        append!(all_results, tmp_data)
    end 
end