function calculate_mse(results::DataFrame, ground_truth::DataFrame, effects_dict::Dict)

    # Debug: Log the input DataFrames and effects_dict
    @debug "Debugging calculate_mse"
    @debug "Results DataFrame:" results
    @debug "Ground Truth DataFrame:" ground_truth
    @debug "Effects Dict:" effects_dict

    # Ensure the dataframes have effects_dict entries
    if typeof(first(keys(effects_dict))) != String
        tmp = tostringdict(effects_dict)
        @assert all(x -> x in names(results), collect(keys(tmp))) "Effects not found in results "
        @assert all(x -> x in names(ground_truth), collect(keys(tmp))) "Effects not found in ground_truth "
    else
        @assert all(x -> x in names(results), collect(keys(effects_dict))) "Effects not found in results "
        @assert all(x -> x in names(ground_truth), collect(keys(effects_dict))) "Effects not found in ground_truth "
    end

    # Add event collumn to make dfs consistent
    results.event = results.eventname
    @debug "Results DataFrame after adding event column:" results

    # Add event to dict to make dict_list
    full_factorial = UnfoldSim.factorproduct(((; k => v) for (k, v) in pairs(effects_dict))...) |> DataFrame
    @debug "Full Factorial DataFrame:" full_factorial

    # In singular events ground_truth doesn't have an event collumn
    if !("event" ∈ names(ground_truth))
        ground_truth[:, :event] .= Any
        @debug "Ground Truth DataFrame after adding event column:" ground_truth
    end

    # Group DataFrames by event
    group_results = groupby(results, :event)
    group_ground_truth = groupby(ground_truth, :event)
    @debug "Grouped Results:" group_results
    @debug "Grouped Ground Truth:" group_ground_truth
    @assert length(group_results) == length(group_ground_truth) "Number of events in results and ground truth do not match"

    event_mse = []
    event_weights::AbstractVector{<:Real} = Float64[]
    event_tp_error = Float64[] # timepoint error
    for both_groups in zip(group_results, group_ground_truth)
        tmp_mse = []
        for row in eachrow(full_factorial)
            collums = Symbol.(names(row))
            tmp_value = values(row)
            #=
            @debug "Current Factorial Row:" row
            @debug "Current Factorial Columns:" collums
            @debug "Current Factorial Values:" tmp_value
            =#

            #error("This is a debug message to check the current factorial row, columns, and values.")
            # Filter both groups and calculate MSE on current factorial 
            d1 = subset(both_groups[1], [col => x -> x .== val for (col, val) in zip(collums, tmp_value)])
            d2 = subset(both_groups[2], [col => x -> x .== val for (col, val) in zip(collums, tmp_value)])
            #=
            @debug "Filtered Results Group:" d1
            @debug "Filtered Ground Truth Group:" d2
            =#
            tp_error = d1.yhat .- d2.yhat
            push!(tmp_mse, mean(tp_error) .^ 2)


        end
        push!(event_weights, Float64(length(tmp_mse)))
        push!(event_mse, mean(tmp_mse))
        
        @debug "Size of tp_error:" size(tp_error)
        if size(tp_error, 2) > 1
            tp_error = mean(tp_error, dims,2)
        end

        @debug "Timepoint Error for current event:" tp_error'
        if isempty(event_tp_error)
            event_tp_error = tp_error
        else
            # If event_tp_error is not empty, we can append the new tp_error
            event_tp_error = vcat(event_tp_error, tp_error)
        end

    end

    @debug "Event MSE:" event_mse
    @debug "Event Weights:" event_weights
    # Ensure that event_mse and event_weights are not empty
    @assert !isempty(event_mse) "Event MSE is empty"
    @assert !isempty(event_weights) "Event Weights are empty"
    
    # Calculate the mean of the MSE values
    return overall_mse = mean(event_mse, weights(event_weights)), event_tp_error
end

"""
    set_up_parameters(sim_functions; kwargs)

Sets up parameters for simulations

## Input
sim_functions: which simulation functions to use; can be vector of functions

### Keywords
- noise = [7]
- shuffle = [false]
- offset=[10] 
- width=[15] 
- seed=[1] 
- sfreq=100 
- τ=(-0.1, 1)

"""
function set_up_parameters(sim_functions; noise=[7], shuffle=[false], offset=[10], width=[15], seed=[1], sfreq=100, τ=(-0.1, 1))

    # Space for parameters
    allparams = Dict(
        "noiselevel" => noise,#collect(3:6),
        "shuffle" => shuffle, # random order sequence?
        "offset" => offset, # Event onset offset -> influences overlap
        "width" => width, #[5, 10, 15, 20, 30, 40, 50], # Width of distribution -> determines jitter; 0 = no jitter
        "seed" => seed,
        "sfreq" => sfreq,
        "τ" => τ,
        "sim_fun" => sim_functions#[FRP_sim, RT_sim, NAT_sim]
    )

    return dicts = dict_list(tosymboldict(allparams))

end