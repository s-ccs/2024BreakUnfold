# Plotting functions to use on resulting DataFrames

using CairoMakie, SwarmMakie, AlgebraOfGraphics
using DataFrames, DataFramesMeta, Statistics

function beeswarm_results(df::DataFrame, collumn::Symbol; metric = :MSE)
    
    p1 = data(df) * mapping(collumn, metric, color = collumn) * visual(Beeswarm)    
    gdf = groupby(df, collumn)
    means = combine(gdf, metric => mean)
    p2 = data(means) * mapping(collumn, :MSE_mean) * visual(Lines) + data(means) * mapping(collumn, :MSE_mean) * visual(Scatter)

    #tm = unique(df[!, collumn])
    #Makie.Categorical(Makie.wong_colors()[1:7])
    f = Figure()
    draw!(f, p1 + p2, scales(Color = (;colormap = Makie.wong_colors())); axis = (;xlabel = String(collumn), ylabel = String(metric)))
    #draw!(f, p2)
    f
end