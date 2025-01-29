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
    @debug full_factorial

    # Group DataFrames by event
    group_results = groupby(results, :event)
    group_ground_truth = groupby(ground_truth, :event)

    group_mse = []
    for both_groups in zip(group_results, group_ground_truth)
        tmp_mse = []
        for row in eachrow(full_factorial)
            collums = Symbol.(names(row))
            tmp_value = values(row)

            # Filter both groups and calculate MSE on current factorial 
            d1 = subset(both_groups[1], collums => x -> x .== tmp_value) # I am not entirely sure why this works, but it does
            d2 = subset(both_groups[2], collums => x -> x .== tmp_value)
            push!(tmp_mse, mean(d1.yhat .- d2.yhat) .^ 2)
        end
        push!(group_mse, mean(tmp_mse))
    end

    # Calculate the mean of the MSE values
    return overall_mse = mean(group_mse)
end