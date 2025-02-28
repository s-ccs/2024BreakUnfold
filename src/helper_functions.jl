function calculate_mse(results::DataFrame, ground_truth::DataFrame, effects_dict::Dict)
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

    # Add event to dict to make dict_list
    full_factorial = UnfoldSim.factorproduct(((; k => v) for (k, v) in pairs(effects_dict))...) |> DataFrame

    # In singular events ground_truth doesn't have an event collumn
    if !("event" ∈ names(ground_truth))
        ground_truth[:, :event] .= Any
    end

    # Group DataFrames by event
    group_results = groupby(results, :event)
    group_ground_truth = groupby(ground_truth, :event)
    #@debug group_results
    #@debug full_factorial
    event_mse = []
    event_weights::AbstractVector{<:Real} = Float64[]
    for both_groups in zip(group_results, group_ground_truth)
        tmp_mse = []
        for row in eachrow(full_factorial)
            collums = Symbol.(names(row))
            tmp_value = values(row)

            # Filter both groups and calculate MSE on current factorial 
            d1 = subset(both_groups[1], collums => x -> x .== tmp_value) # I am not entirely sure why this works, but it does
            d2 = subset(both_groups[2], collums => x -> x .== tmp_value)
            push!(tmp_mse, mean(d1.yhat .- d2.yhat) .^ 2)
            @debug d1, d2

        end
        push!(event_weights, Float64(length(tmp_mse)))
        push!(event_mse, mean(tmp_mse))
    end

    @debug event_mse, event_weights
    # Calculate the mean of the MSE values
    return overall_mse = mean(event_mse, weights(event_weights))
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