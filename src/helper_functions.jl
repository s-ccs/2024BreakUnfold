#function calculate_mse(df1::DataFrame, df2::DataFrame, effects_dict::Dict=Dict())
# Ensure the dataframes have effects_dict entries
if typeof(first(keys(effects_dict))) != String
    tmp = tostringdict(effects_dict)
    @assert all(x -> x in names(df1), collect(keys(tmp))) "Effects not found in df1 "
    @assert all(x -> x in names(df2), collect(keys(tmp))) "Effects not found in df2 "
else
    @assert all(x -> x in names(df1), collect(keys(effects_dict))) "Effects not found in df1 "
    @assert all(x -> x in names(df2), collect(keys(effects_dict))) "Effects not found in df2 "
end

# Add event collumn to make dfs consistent
df1.event = df1.eventname

# Add event to dict to make dict_list
full_factorial = BreakUnfold.UnfoldSim.factorproduct(((; k => v) for (k, v) in pairs(effects_dict))...) |> DataFrame


# Group DataFrames by event
group_df1 = groupby(df1, :event)
group_df2 = groupby(df2, :event)

group_mse = []
for both_groups in zip(group_df1, group_df2)
    tmp_mse = []
    for row in eachrow(full_factorial)
        collums = Symbol.(names(row))
        tmp_value = values(row)
        
        # Filter both groups and calculate MSE on current factorial
        d1 = subset(both_groups[1], collums => x -> x .== tmp_value)
        d2 = subset(both_groups[2], collums => x -> x .== tmp_value)
        push!(tmp_mse, mean(d1.yhat .- d2.yhat) .^ 2)
    end
    push!(group_mse, tmp_mse)
end
#=
# Group by the specified columns and calculate MSE for each group
mse_values = []
for group in groupby(df1, group_columns)
    group_key = group[1, group_columns]
    df1_group = filter(row -> all(row[group_columns] .== group_key), df1)
    df2_group = filter(row -> all(row[group_columns] .== group_key), df2)

    if nrow(df1_group) != nrow(df2_group)
        throw(ArgumentError("Mismatched number of rows in groups"))
    end

    mse = mean((df1_group.yhat .- df2_group.yhat) .^ 2)
    push!(mse_values, mse)
end
=#

# Calculate the mean of the MSE values
overall_mse = mean(mse_values)
return overall_mse
#end