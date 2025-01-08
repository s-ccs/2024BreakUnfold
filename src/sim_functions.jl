# Function to be used in simulations

# Simulate a ground truth based on a given simulation design and components
function get_ground_truth(seed, design, effects_dict, components, τ, sfreq)
    effects_design = EffectsDesign(design, effects_dict)

    gt_data, gt_events = simulate(
        MersenneTwister(seed),
        effects_design,
        components,
        UniformOnset(; width=0, offset=1000),
        NoNoise(),
        return_epoched=true,
    )


    ## change gt to effects style DataFrame
    g = format_gt(gt_data, τ, sfreq) # zero-pad ground_truth and get into correct format
    times = range(τ[1], τ[2], size(g, 2)) # get correct times vector
    gt_effects = Unfold.result_to_table([g], [gt_events], [times], ["effects"])
    return gt_effects
end

# Main simulation function; to be used in Dr.Watson script
function jitter_simulation(d::Dict)
    @unpack noiselevel, shuffle, offset, width, seed, sfreq, τ = d

    design, # Simulation design
    data, # Simulated data
    evts, # Simulated events
    effects_dict, # Dictionary for conditions and such; needed for marg. eff and ground truth
    components = # components of ERP
        FRP_sim(seed, sfreq, shuffle, width, offset; noiselevel=noiselevel, n_trials=90)

    # Simulate ground truth
    gt_effects = get_ground_truth(seed, design, effects_dict, components, τ, sfreq)

    # Fit Unfold
    m = fit(
        UnfoldModel,
        [Any => (@formula(0 ~ 1), #(@formula(0 ~ 1 + condition + spl(continuous, 4)),
            firbasis(τ=τ, sfreq=sfreq, name="basis"),
        )],
        evts,
        data,
          #  solver = (x,y)->Unfold.solver_predefined(x,y;solver=:cholesky)
    )

    ## Calculate marginalized effects
    result_effects = effects(effects_dict, m)

    # Calculate MSE
    MSE = mean((@rsubset(gt_effects, :condition .== "bike").yhat -
                @rsubset(result_effects, :condition .== "bike").yhat) .^ 2)

    return DataFrame(;
        results=result_effects,
        ground_truth=gt_effects,
        model=m,
        MSE=MSE,
        d...
    ) # change to d...
end

# Function to zero-pad ground_truth and get into correct format
function format_gt(gt_data, τ, sfreq)
    gt_data = pad_array(reshape(gt_data, size(gt_data, 1)), (Int(τ[1] * sfreq), Int(τ[2] * 100 - size(gt_data, 1) + 1)), 0) # pad ground truth to be same length as estimates

    gt_data = reshape(gt_data, 1, size(gt_data)...) # reshape to be channel x samplepoints x event
    return gt_data
end