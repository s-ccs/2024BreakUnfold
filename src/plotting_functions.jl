# Plotting functions to use on resulting DataFrames

using CairoMakie, SwarmMakie, AlgebraOfGraphics
using DataFrames, DataFramesMeta, Statistics

"""
function beeswarm_results(df::DataFrame, collumn::Symbol; metric = :MSE)

Plots a beeswarm plot of the results in `df` grouped by `collumn` and colored by `collumn`.
The metric to plot can be specified with the `metric` keyword argument, defaulting to `:MSE`.
The function also calculates the mean of the specified metric for each group and adds a line plot of these means.

"""
function beeswarm_results(df::DataFrame, collumn::Symbol; metric=:MSE)

    p1 = data(df) * mapping(collumn, metric, color=collumn) * visual(Beeswarm)
    gdf = groupby(df, collumn)
    means = combine(gdf, metric => mean)
    p2 = data(means) * mapping(collumn, :MSE_mean) * visual(Lines) + data(means) * mapping(collumn, :MSE_mean) * visual(Scatter)

    #tm = unique(df[!, collumn])
    #Makie.Categorical(Makie.wong_colors()[1:7])
    f = Figure()
    draw!(f, p1 + p2, scales(Color=(; colormap=Makie.wong_colors())); axis=(; xlabel=String(collumn), ylabel=String(metric)))
    # limits = (nothing, (-0.2, 60))
    #draw!(f, p2)
    f
    return f
end

"""
function raincloud_results(df::DataFrame, collumn::Symbol; metric = :MSE)

Plots a raincloud plot of the results in `df` grouped by `collumn` and colored by `collumn`.
The metric to plot can be specified with the `metric` keyword argument, defaulting to `:MSE`.
The function also calculates the mean of the specified metric for each group and adds a line plot of these means.

"""
function raincloud_results(df::DataFrame, collumn::Symbol, f=Figure(); metric=:MSE, kwargs...)

    p1 = data(df) * mapping(collumn => nonnumeric, metric, color=collumn) * visual(RainClouds; kwargs...)
    gdf = groupby(df, collumn)
    means = combine(gdf, metric => mean)
    p2 = data(means) * mapping(collumn, :MSE_mean) * visual(Lines) + data(means) * mapping(collumn => nonnumeric, :MSE_mean) * visual(Scatter)

    #tm = unique(df[!, collumn])
    #Makie.Categorical(Makie.wong_colors()[1:7])
    limits = (nothing, (-1.5, 60))
    draw!(f, p1, scales(Color=(; colormap=Makie.wong_colors())); axis=(; xlabel=String(collumn), ylabel=String(metric), limits=limits))
    #draw!(f, p2)
    f
    return f
end

function raincloud_all_designs(df::DataFrame, collumn::Symbol; size=(1200, 800), metric=:MSE, limits=(nothing, (-1.5, 60)), kwargs...)

    p1 = data(df) * mapping(collumn => nonnumeric, metric, color=collumn, col=:sim_function => sorter(["RT", "FRP", "NAT"])) * visual(RainClouds; kwargs...)
    gdf = groupby(df, collumn)
    means = combine(gdf, metric => mean)
    p2 = data(means) * mapping(collumn, :MSE_mean) * visual(Lines) + data(means) * mapping(collumn => nonnumeric, :MSE_mean) * visual(Scatter)

    #tm = unique(df[!, collumn])
    #Makie.Categorical(Makie.wong_colors()[1:7])
    f = Figure(; size=size)

    draw!(f, p1, scales(Color=(; colormap=Makie.wong_colors())); axis=(; xlabel=String(collumn), ylabel=String(metric), limits=limits))
    #draw!(f, p2)
    f
    return f
end

function plot_error_timecourse(df::DataFrame, layout::Symbol; only_means::Bool=true)
    # Create time vector based on sfreq and τ
    time = range(df[1, :τ][1], df[1, :τ][2], step=1 / df[1, :sfreq])

    @assert size(df[1, :tp_error], 2) <= 1 "Multi event MSE timecourse not implemented yet."

    # Group the DataFrame by the condition column
    grouped_df = groupby(df, layout)

    # Calculate pointwise mean per condition
    condition_means = Dict()
    for g in grouped_df
        condition = g[1, layout]  # Get the condition value
        pointwise_mean = mean(reduce(hcat, g.tp_error), dims=2)
        condition_means[condition] = pointwise_mean
    end

    @debug "Condition means calculated: " condition_means
    # Decide on plot
    if only_means
        # Plot the timecourse for each condition
        f = Figure()
        ax = Axis(f[1, 1], xlabel="Time (s)", ylabel="Average error (μV)")
        for (condition, mean_values) in condition_means
            lines!(ax, time, vec(mean_values), label=string(condition))
        end
        axislegend(ax)
        f
    else
        # Create a figure with subplots for each condition
        num_conditions = length(condition_means)
        f = Figure(resolution=(800, 200 * num_conditions))  # Adjust height based on the number of conditions

        # Plot each condition in a separate subplot
        row = 1
        for (condition, mean_values) in condition_means
            ax = Axis(f[row, 1], xlabel="Time (s)", ylabel="Mean MSE", title=string(condition))
            lines!(ax, time, vec(mean_values), label=string(condition))
            row += 1
        end

        f
    end
end

function plot_CN_MSE(df::DataFrame)
    # Plot condition number versus MSE

    # Extract variables
    CN = df[!, :condition_number]
    MSE = df[!, :MSE]

    scatter(CN, MSE)
end

# Function to filter DataFrame based on an unknown number of conditions
function filter_with_conditions(df::DataFrame, conditions)
    for (col, condition) in conditions
        df = subset(df, col => condition)
    end
    return df
end


function plot_estimation_vs_gt(df::DataFrame, conditions; title::String="Estimation vs Ground Truth")
    # Plot estimation versus ground truth
    # Filter the DataFrame based on the conditions
    results_df = filter_with_conditions(df[1, :results], conditions)
    gt_df = filter_with_conditions(df[1, :ground_truth], conditions)

    f = Figure()
    ax = Axis(f[1, 1], xlabel="Time (s)", ylabel="Amplitude (μV)", title=title)
    lines!(ax, results_df[!, :time], results_df[!, :yhat], label="Estimation")
    lines!(ax, gt_df[!, :time], gt_df[!, :yhat])

    f
    return mse = mean((gt_df[!, :yhat] .- results_df[!, :yhat]) .^ 2)
end

# -------------------------------------------------------------

function plot_sensitivity(res)
    fig = Figure(size=(600, 400))

    barplot(fig[2, 1],
        collect(1:length(res.S1)),
        vec(res.S1),
        color=:green,
        axis=(xticksvisible=true, xticklabelsvisible=true,
            title="First order index", ylabel="First order"))

    barplot(fig[1, 1], collect(1:length(res.ST)), vec(res.ST), color=:green,
        axis=(xticksvisible=false, xticklabelsvisible=false, title="Total order index", ylabel="Total order"))

    if hasproperty(res, :S2)
        barplot(fig[3, 1],
            collect(1:length(res.S2)),
            vec(res.S2),
            color=:green,
            axis=(xticksvisible=true, xticklabelsvisible=false,
                title="Second order index", ylabel="Second order"))
    end

    fig
end


