# Types of simulations

# Design function
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
function FRP_sim(seed, sfreq, shuffle, width, offset; noiselevel=5, n_trials=15)
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
        formula=@formula(0 ~ 1),
        β=[7],
    )

    components = [p1, n1, p3]

    ## Design and simulate data
    cond_dict = Dict(:condition => ["bike"])
    design, data, evts = design_and_simulation(seed, cond_dict, components, width, offset; shuffle=shuffle, repeat=n_trials)

    return design, data, evts, cond_dict, components
end

# Reaction time like simulation; stimulus + response, one condition or two?, sequence,  
function RT_sim(sfreq, shuffle, width, offset; noiselevel=5, n_trials=15)
    # Create components (one component complex for S(timulus); one for R(esponse))

end

# Naturalistic/ complex simulation; 
function NAT_sim(sfreq, width, offset; noiselevel=5, n_trials=15, shuffle=true)
    
    return design, data, evts, cond_dict
end