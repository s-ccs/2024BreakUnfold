# Function to be used in simulations

function jitter_simulation(d::Dict)
    @unpack noiselevel shuffle offset width seed

    ## Components
    p1 = LinearModelComponent(;
        basis=p100(),
        formula=@formula(0 ~ 1),
        β=[5])

    n1 = LinearModelComponent(;
        basis=n170(),
        formula=@formula(0 ~ 1),
        β=[5],
    )

    p3 = LinearModelComponent(;
        basis=p300(),
        formula=@formula(0 ~ 1 + continuous + continuous^2),
        β=[5, 1, 0.2],
    )
    
    components = [p1, n1, p3]
    ## Design
    if shuffl
        design =
            SingleSubjectDesign(;
                conditions=Dict(
                    :condition => ["car", "face"],
                    :continuous => range(0, 5, length=10),
                ),
                event_order_function=x -> shuffle(MersenneTwister(seed), x),
            ) |> x -> RepeatDesign(x, 15)
    else
        design =
            SingleSubjectDesign(;
                conditions=Dict(
                    :condition => ["car", "face"],
                    :continuous => range(0, 5, length=10),
                ),
            ) |> x -> RepeatDesign(x, 15)
    end

    ## simulate

    data, evts = simulate(
        MersenneTwister(seed),
        design,
        components,
        UniformOnset(; width=width, offset=offset),
        PinkNoise(; noiselevel=noiselevel),
    )

    # Fit Unfold
    m = fit(
        UnfoldModel,
        [Any => (@formula(0 ~ 1 + condition + spl(continuous, 4)),
            firbasis(τ=[-0.1, 1], sfreq=100, name="basis"),
        )],
        evts,
        data,
    )
    return m # ground truth
end