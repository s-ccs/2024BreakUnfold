# Types of simulations

# Design function TODO: make more general; maybe second function
function design_and_simulation(seed, cond_dict::Dict, components, width, offset; shuff=false, repeat=15, noiselevel=5)
    if shuff
        design =
            SingleSubjectDesign(;
                conditions=cond_dict,
                event_order_function=shuffle,
            ) |> x -> RepeatDesign(x, repeat)
    else
        design =
            SingleSubjectDesign(;
                conditions=cond_dict,
            ) |> x -> RepeatDesign(x, repeat)
    end

    @debug "Design:" design
    # Simulate data
    data, evts = simulate(
        MersenneTwister(seed),
        design,
        components,
        UniformOnset(; width=width, offset=offset),
        PinkNoise(; noiselevel=noiselevel),
    )

    @debug "Size evts:" size(evts)

    return design, data, evts
end


# FRP like simulation; one shape, not changing, one condition
function FRP_sim(seed, sfreq, width, offset, τ;shuff = false, noiselevel=5, n_trials=30) # TODO: change some stuff (e.g. shuff to kwarks)
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
    design, data, evts = design_and_simulation(seed, cond_dict, components, width, offset; shuff=shuff, repeat=n_trials/2, noiselevel=noiselevel) # n_trials dividied by 2 because two conditions

    # Make formula to be used during fitting
    formula = [Any => (@formula(0 ~ 1 + condition), #(@formula(0 ~ 1 + condition + spl(continuous, 4)),
        firbasis(τ=τ, sfreq=sfreq, name=""),
    )]

    return design, data, evts, cond_dict, components, formula
end

# ---
# Reaction time like simulation; stimulus + response, one condition or two?, sequence,  
function RT_sim(seed, sfreq, width, offset, τ; shuff = false, noiselevel=5, n_trials=15)
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
    #design = SingleSubjectDesign(conditions=cond_dict)
    if shuff
        design =
            SingleSubjectDesign(;
                conditions=cond_dict,
                event_order_function=shuffle,
            )
    else
        design =
            SingleSubjectDesign(;
                conditions=cond_dict,
            )
    end
    design = SequenceDesign(design, "SR_")
    design = RepeatDesign(design, n_trials/2) # number of trials will be n_trials * 2 * 2 because two conditions and two events per trial

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

# ---
# Naturalistic/ complex simulation; 
function NAT_sim(seed, sfreq, width, offset, τ; shuff = false, noiselevel=5, n_trials=200)

    # Create components (one component complex for S(timulus); one for R(esponse))    
        p1 = LinearModelComponent(;
        basis=p100(; sfreq=sfreq),
        formula=@formula(0 ~ 1),
        β=[5]
    )

    n1 = LinearModelComponent(;
        basis=n170(; sfreq=sfreq),
        formula=@formula(0 ~ 1 + sac_amplitude^2),
        β=[5, 0.4],
    )

    p3 = LinearModelComponent(;
        basis=p300(; sfreq=sfreq),
        formula=@formula(0 ~ 1 + condition + evidence^2 + duration),
        β=[7, 2, 0.3, 0.5],
    )

    #=
    resp = LinearModelComponent(;
        basis=UnfoldSim.hanning(Int(0.5 * sfreq)), # sfreq = 100 for the other bases
        formula=@formula(0 ~ 1),
        β=[6],
        offset=-10,
    )
    =#

    event = "Stim"
    #components = Dict("Stim" => [p1, n1, p3])
    components = [p1, n1, p3] #Dict(event => [p1, n1, p3])
    #components = Dict('S' => [p1, n1, p3], 'R' => [resp])

    # Design
    cond_dict = Dict(
        :condition => ["face", "bike"],
        :sac_amplitude => range(0, 5, length = 10),
        :evidence => range(1, 5, length = 8),
        :duration => range(2, 8, length = 12)
        )
    @debug "Condition dictionary for NAT simulation:" cond_dict

    design = SingleSubjectDesign(conditions=cond_dict)
    #design = SequenceDesign(design, "SR_")
    design = RandomEventsDesign(; seed=seed, nEvents = n_trials, design) # number of trials will be n_trials
    @debug "Design of NAT simulation:" design

    data, evts = simulate(
        MersenneTwister(seed),
        design,
        components,
        UniformOnset(offset=offset, width=width),
        PinkNoise(; noiselevel=noiselevel),
    )
    @debug "Events of NAT simulation:" evts

    # Make formula to be used during fitting
    formula = [Any => (@formula(0 ~ 1 + sac_amplitude + condition + evidence + duration), #(@formula(0 ~ 1 + condition + spl(continuous, 4)),
    firbasis(τ=τ, sfreq=sfreq, name=""),
    )]

    #=
    formula = ['S' => (@formula(0 ~ 1 + condition), #(@formula(0 ~ 1 + condition + spl(continuous, 4)),
        firbasis(τ=τ, sfreq=sfreq, name=""),
    ), 
    'R' => (@formula(0 ~ 1),
        firbasis(τ=τ, sfreq=sfreq, name=""),
    )]
    =#
    return design, data, evts, cond_dict, components, formula
end