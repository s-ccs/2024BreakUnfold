using DrWatson
@quickactivate :BreakUnfold

using GlobalSensitivity
using Random
using DataFrames
using Statistics
using QuasiMonteCarlo
#using ProgressMeter

# -----
# set jitter_simulation inputs
param_names = [:width, 
            :offset, 
            :ntrials, 
            :noiselevel, 
            #:sfreq
            ] 

# bounds as (min, max) for each parameter above
bounds = [(1, 50), 
        (5, 50), 
        (50, 400), 
        (1, 10), 
        #(50, 200)
        ]

# template dict with defaults for all jitter_simulation keys
template = set_up_parameters([FRP_sim])[1]

# convert some params to integer 
int_params = Set([:ntrials, :sfreq, :width, :offset, :noiselevel])

# wrapper accepted by GlobalSensitivity.gsa
function make_model_wrapper(fun, template::Dict, param_names::Vector{Symbol}, int_params::Set{Symbol})
    k = length(param_names)
    function model(x)
        d = deepcopy(template)
        for j in 1:k
            name = param_names[j]
            val = x[j]
            if name in int_params
                @debug "Assigning $name = $val"
                d[name] = Int(round(val))
            else
                @debug "Assigning $name = $val"
                d[name] = val
            end
        end
        @debug "Running simulation with parameters:"
        @debug d
        out = fun(d)
        return out.MSE
    end
    return model
end

# main entry for running Sobol analysis
function run_sobol(jitter_fun; param_names=param_names, bounds=bounds, template=template, int_params=int_params, samples=1024, rng=MersenneTwister(1))
    @assert length(param_names) == length(bounds) "param_names and bounds must match"
    model = make_model_wrapper(jitter_fun, template, param_names, int_params)

    # GlobalSensitivity expects bounds as Vector or DesignMatrices

    # build lower/upper bound vectors
    lb = [b[1] for b in bounds]
    ub = [b[2] for b in bounds]

    # create Sobol sampler and generate A, B design matrices
    sampler = SobolSample()
    A, B = QuasiMonteCarlo.generate_design_matrices(samples, lb, ub, sampler)

    # round columns corresponding to integer parameters to integer values
    #int_idx = findall(j -> param_names[j] in int_params, 1:length(param_names))
    #for j in int_idx
    A = Int.(round.(A))
    B = Int.(round.(B))
    @debug "First 5 rows of A after rounding to Int:"
    @debug first(A, 5)
    @debug "First 5 rows of B after rounding to Int:"
    @debug first(B, 5)

    # keep a bounds_vec for compatibility with GlobalSensitivity API
    # bounds_vec = [(lb[i], ub[i]) for i in 1:length(lb)]

    # run analysis (Sobol)
    println("Running Sobol GSA with $samples samples, this might take a while...")
    res = gsa(model, Sobol(;order = [0, 1, 2]), A, B; samples = samples, rng = rng)


    return res
end

# Test the sensitivity analysis
samples = 50000
println("Running quick sensitivity (samples=$samples)...")
res = run_sobol(jitter_simulation; samples=samples)

BreakUnfold.plot_sensitivity(res)