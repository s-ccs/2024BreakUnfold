# Types of simulations

# Design function TODO: make more general; maybe second function
function design_and_simulation(seed, cond_dict::Dict, components, width, offset; shuffle=false, repeat=15, noiselevel=5)
    if shuffle
        design =
            SingleSubjectDesign(;
                conditions=cond_dict,
                event_order_function=x -> shuffle(MersenneTwister(seed), x),
            ) |> x -> RepeatDesign(x, repeat)
    else
        design =
            SingleSubjectDesign(;
                conditions=cond_dict,
            ) |> x -> RepeatDesign(x, repeat)
    end

    # Simulate data
    data, evts = simulate(
        MersenneTwister(seed),
        design,
        components,
        UniformOnset(; width=width, offset=offset),
        PinkNoise(; noiselevel=noiselevel),
    )

    return design, data, evts
end


# FRP like simulation; one shape, not changing, one condition
function FRP_sim(seed, sfreq, width, offset, τ;shuffle = false, noiselevel=5, n_trials=30) # TODO: change some stuff (e.g. shuffle to kwarks)
    ## Components
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
        formula=@formula(0 ~ 1 + condition),
        β=[7, 2],
    )

    components = [p1, n1, p3]

    ## Design and simulate data
    cond_dict = Dict(:condition => ["bike", "face"])
    design, data, evts = design_and_simulation(seed, cond_dict, components, width, offset; shuffle=shuffle, repeat=n_trials, noiselevel=noiselevel)

    # Make formula to be used during fitting
    formula = [Any => (@formula(0 ~ 1 + condition), #(@formula(0 ~ 1 + condition + spl(continuous, 4)),
        firbasis(τ=τ, sfreq=sfreq, name=""),
    )]

    return design, data, evts, cond_dict, components, formula
end

# Reaction time like simulation; stimulus + response, one condition or two?, sequence,  
function RT_sim(seed, sfreq, width, offset, τ; shuffle = false, noiselevel=5, n_trials=15)
    # Create components (one component complex for S(timulus); one for R(esponse))
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
        formula=@formula(0 ~ 1 + condition),
        β=[7, 2],
    )

    resp = LinearModelComponent(;
        basis=UnfoldSim.hanning(Int(0.5 * sfreq)), # sfreq = 100 for the other bases
        formula=@formula(0 ~ 1),
        β=[6],
        offset=-10,
    )

    components = Dict('S' => [p1, n1, p3], 'R' => [resp])

    # Design
    cond_dict = Dict(:condition => ["one", "two"])
    design = SingleSubjectDesign(conditions=cond_dict)
    design = SequenceDesign(design, "SR_")
    design = RepeatDesign(design, n_trials) # number of trials will be n_trials * 2

    # Simulate
    data, evts = simulate(
        MersenneTwister(seed),
        design,
        components,
        UniformOnset(offset=offset, width=width),
        PinkNoise(; noiselevel=noiselevel),
    )

    # Make formula to be used during fitting
    formula = ['S' => (@formula(0 ~ 1 + condition), #(@formula(0 ~ 1 + condition + spl(continuous, 4)),
        firbasis(τ=τ, sfreq=sfreq, name=""),
    ), 
    'R' => (@formula(0 ~ 1),
        firbasis(τ=τ, sfreq=sfreq, name=""),
    )]
    return design, data, evts, cond_dict, components, formula
end

# Naturalistic/ complex simulation; 
function NAT_sim(sfreq, width, offset; noiselevel=5, n_trials=15, shuffle=true)

    return design, data, evts, cond_dict
end