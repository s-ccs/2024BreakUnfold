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
    @unpack noiselevel, shuffle, offset, width, seed, sfreq, τ, sim_fun = d

    design, # Simulation design
    data, # Simulated data
    evts, # Simulated events
    effects_dict, # Dictionary for conditions and such; needed for marg. eff and ground truth
    components, # components of ERP
    formula = # formula for fitting
        sim_fun(seed, sfreq, width, offset, τ; shuffle = shuffle, noiselevel=noiselevel, n_trials=90)

    # Simulate ground truth
    gt_effects = get_ground_truth(seed, design, effects_dict, components, τ, sfreq)
    @debug size(evts)
    
    # Fit Unfold
    m = fit(
        UnfoldModel,
        formula,
        evts,
        data,
        #  solver = (x,y)->Unfold.solver_predefined(x,y;solver=:cholesky)
    )

    # Calculate condition number
    X = modelmatrix(designmatrix(m))
    cond_number = cond(X'X, 1)

    ## Calculate marginalized effects
    result_effects = effects(effects_dict, m)

    # Calculate MSE
    MSE = calculate_mse(result_effects, gt_effects, effects_dict)

    # delete sim_fun from dict for saving
    delete!(d, :sim_fun)
    @show d
    return DataFrame(;
        sim_function = string(split(string(sim_fun), "_")[1]),
        results=result_effects,
        ground_truth=gt_effects,
        model=m,
        condition_number=cond_number,
        MSE=[MSE],
        d...
    )
end

# Function to zero-pad ground_truth and get into correct format
function format_gt(gt_data, τ, sfreq)
    sp = Int(abs(τ[1]) * sfreq) + Int(τ[2] * sfreq) # number of sample points
    padded_data = zeros(sp+1, size(gt_data, 2))

    for col in 1:size(gt_data, 2)
        tmp = pad_array(reshape(gt_data[:,col], size(gt_data[:,col], 1)), (Int(τ[1] * sfreq), Int(τ[2] * 100 - size(gt_data[:,col], 1) + 1)), 0) # pad ground truth to be same length as estimates
        padded_data[:, col] = tmp
    end
    padded_data = reshape(padded_data, 1, size(padded_data)...) # reshape to be channel x samplepoints x event
    
    return padded_data
end

# Changes effects design event DataFrame to be used with Unfold.result_to_table
df_to_vec(df) = [@rsubset(df, :event == e) for e in unique(df.event)] 

function reshape_eff_to_event_arrays(eff::Array{T, 3}, df::DataFrame) where T
    # Get events
    events = unique(df.event)

    # Get number of events
    num_unique_events = length(events)

    # Create an empty array to hold the result
    result = Vector{Array{T, 3}}(undef, num_unique_events)
    
    # For each event, we need to extract the corresponding indices from the DataFrame
    for (i, event) in enumerate(events)
        # Get the indices of the rows corresponding to the current event
        event_indices = findall(x -> x == event, df.event)
        
        # Extract the relevant slice of eff based on the current event
        # eff has shape (1, 110, 6), and we want to match it to the size of the event indices
        eff_slice = eff[:, :, event_indices]
        
        # Store the slice in the result array
        result[i] = eff_slice
    end
    
    return result
end