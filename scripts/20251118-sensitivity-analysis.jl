# Activate DrWatson
using DrWatson
@quickactivate :BreakUnfold

using GlobalSensitivity

# FRP, RT, NAT simulations
force_simulation = false
dicts = set_up_parameters([RT_sim, FRP_sim, NAT_sim]; ntrials=[50, 100, 200, 300], offset=[15], width=[5, 45], seed=collect(1:50), sfreq=100)

function sensitivity_analysis(params)
    # Run the analysis stuff

    # assign parameters to variables
    d = set_up_parameters([RT_sim]; ntrials=[50, 100, 200, 300], offset=[15], width=[5, 45], seed=collect(1:50), sfreq=100)


    # Pluck variables into simulation function
    df = jitter_simulation(d)
    # use only MSE of output

    return df.MSE
end


params = [[1, 5], [1, 5], [1, 5], [1, 5]]

gsa(sensitivity_analysis, Sobol(), params, samples = 5)