# Types of simulations

# Design function
function simulation_design(seed, cond_dict::Dict; shuffle=false, repeat=15)
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
    return design
end

# FRP like simulation; one shape, not changing, one condition
function FRP_sim(sfreq, shuffle, width, offset; noiselevel=5, n_trials=15)
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

    ## Design
    cond_dict = Dict(:condition => ["bike"])
    design = simulation_design(seed, cond_dict; shuffle=shuffle, repeat=n_trials)

    # Simulate data
    data, evts = simulate(
        MersenneTwister(seed),
        design,
        components,
        UniformOnset(; width=width, offset=offset),
        PinkNoise(; noiselevel=noiselevel),
    )
    return design, data, evts, cond_dict
end

# Reaction time like simulation; stimulus + response, one condition or two?, sequence,  
struct RT_sim

end

# Naturalistic/ complex simulation; 
struct NAT_sim

end