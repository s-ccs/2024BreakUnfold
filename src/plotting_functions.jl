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

function plot_sensitivity(res; param_names=nothing, size=(900, 600))
    # - param_names: optional Vector of names (Symbols or Strings) for parameters
    # If not provided, parameters will be named p1..pN

    n = length(res.S1)
    if param_names === nothing
        labels = ["p$(i)" for i in 1:n]
    else
        labels = String.(param_names)
    end

    fig = Figure(size=size)

    # Total order 
    ax1 = fig[1, 1] = Axis(fig, title = "Total order index", ylabel = "ST")
    barplot!(ax1, 1:n, vec(res.ST); color=:green)
    ax1.xticks = (1:n, labels)
    ax1.xticklabelrotation = 45

    # First order
    ax2 = fig[2, 1] = Axis(fig, title = "First order index", ylabel = "S1")
    barplot!(ax2, 1:n, vec(res.S1); color=:blue)
    ax2.xticks = (1:n, labels)
    ax2.xticklabelrotation = 45

    # Second order (S2) - plot as heatmap when matrix-like, otherwise fallback to barplot
    if hasproperty(res, :S2)
        S2 = res.S2
        if isa(S2, AbstractMatrix) && size(S2, 1) == n && size(S2, 2) == n
            ax3 = fig[1:2, 2] = Axis(fig, title = "Second order indices (S2)")
            hm = heatmap!(ax3, 1:n, 1:n, S2; colormap = :viridis)
            ax3.xticks = (1:n, labels)
            ax3.yticks = (1:n, labels)
            ax3.xticklabelrotation = 45
        else
            ax3 = fig[3, 1] = Axis(fig, title = "Second order index (flattened)", ylabel = "S2")
            barplot!(ax3, collect(1:length(vec(S2))), vec(S2); color=:orangered)
        end
    end

    fig
end


