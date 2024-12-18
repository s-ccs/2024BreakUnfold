using Test
using UnfoldSim
using Random

include("../src/sim_functions.jl")

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

compoents = [p1, n1, p3]

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
    MersenneTwister(seed),
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
    after = zeros(Int(abs(τ[2]) * sfreq - size(gt_data,1))+1)
    manual_g = vcat(before, gt_data, after)'
    @test g == manual_g
end

###---
@testset "MSE calculation" begin
    g = format_gt(gt_data, τ, sfreq) # zero-pad ground_truth and get into correct format
    times = range(τ[1], τ[2], size(g, 2)) # get correct times vector
    gt_effects = Unfold.result_to_table([g], [gt_events], [times], ["effects"])

    ### Test MSE calculation
    MSE = mean((g' - gt_effects.yhat) .^ 2)
    @test MSE == 0
end