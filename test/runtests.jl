using Test
using UnfoldSim
using Random
using DataFrames
using BreakUnfold

#include("../src/sim_functions.jl")
#include("../src/helper_functions.jl")

#=
## Setup
sfreq = 100
τ = (-0.1, 1.0)

### Components
p1 = LinearModelComponent(;
    basis=p100(; sfreq=sfreq),
    formula=@formula(0 ~ 1),
    β=[5]
)

n1 = LinearModelComponent(;
    basis=n170(; sfreq=sfreq),
    formula=@formula(0 ~ 1),
    β=[5],
)

p3 = LinearModelComponent(;
    basis=p300(; sfreq=sfreq),
    formula=@formula(0 ~ 1),
    β=[7],
)

components = [p1, n1, p3]

### Subject design
design = SingleSubjectDesign(;
    conditions=Dict(
        :condition => ["bike"]
    ),
) |> x -> RepeatDesign(x, 15);

### Grund Truth design
effects_dict = Dict(:condition => ["bike"])

effects_design = EffectsDesign(design, effects_dict)

gt_data, gt_events = simulate(
    MersenneTwister(1),
    effects_design,
    components,
    UniformOnset(; width=0, offset=1000),
    NoNoise(),
    return_epoched=true,
)

###---
@testset "gt formatting" begin
    g = format_gt(gt_data, τ, sfreq)
    before = zeros(Int(abs(τ[1]) * sfreq))
    after = zeros(Int(abs(τ[2]) * sfreq - size(gt_data, 1)) + 1)
    manual_g = vcat(before, gt_data, after)'
    @test g == manual_g
end
=#
###---
@testset "MSE calculation" begin
    # Sample DataFrames
    results = DataFrame(eventname=["A", "A", "B", "B"], yhat=[1.0, 2.0, 3.0, 4.0], factor1=[1, 1, 2, 2], factor2=[1, 2, 1, 2])
    ground_truth = DataFrame(event=["A", "A", "B", "B"], yhat=[1.1, 1.9, 3.1, 3.9], factor1=[1, 1, 2, 2], factor2=[1, 2, 1, 2])
    effects_dict = Dict("factor1" => [1, 2], "factor2" => [1, 2])

    # Test with valid inputs
    @test BreakUnfold.calculate_mse(results, ground_truth, effects_dict) ≈ 0.01

    # Test with missing columns in results
    results_missing = DataFrame(eventname=["A", "A", "B", "B"], yhat=[1.0, 2.0, 3.0, 4.0], factor1=[1, 1, 2, 2])
    @test_throws AssertionError BreakUnfold.calculate_mse(results_missing, ground_truth, effects_dict)

    # Test with missing columns in ground_truth
    ground_truth_missing = DataFrame(event=["A", "A", "B", "B"], yhat=[1.1, 1.9, 3.1, 3.9], factor1=[1, 1, 2, 2])
    @test_throws AssertionError BreakUnfold.calculate_mse(results, ground_truth_missing, effects_dict)

    # Test with empty DataFrames
    empty_results = DataFrame()
    empty_ground_truth = DataFrame()
    @test_throws AssertionError BreakUnfold.calculate_mse(empty_results, empty_ground_truth, effects_dict)
end