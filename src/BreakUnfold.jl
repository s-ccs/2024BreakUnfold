module BreakUnfold

using Unfold, UnfoldSim
using DrWatson
using Random, DataFrames, DataFramesMeta, Statistics

# export all libraries
export Unfold, UnfoldSim, Random, DataFrames, DataFramesMeta, Statistics

include("sim_types.jl")
include("sim_functions.jl")

export jitter_simulation

end