module BreakUnfold

using Reexport
using Unfold, UnfoldSim
using DrWatson
using Random, Statistics, StatsBase, LinearAlgebra
@reexport using DataFrames, DataFramesMeta, ProgressBars
# export all libraries

DrWatson._wsave(filename::AbstractString, df::DataFrame; kwargs...) = DrWatson.JLD2.@save(filename, df = df)
DrWatson.default_prefix(c::Dict) = string(split(string(c[:sim_fun]), "_")[1])


include("sim_types.jl")
include("sim_functions.jl")
include("helper_functions.jl")
include("plotting_functions.jl")

export jitter_simulation, FRP_sim, RT_sim, NAT_sim, set_up_parameters

end