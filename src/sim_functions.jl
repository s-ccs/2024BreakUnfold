# Function to be used in simulations

function jitter_simulation(d::Dict)
    @unpack noiselevel shuffle offset width seed sfreq τ

    ## Components
    p1 = LinearModelComponent(;
        basis=p100(;sfreq=sfreq),
        formula=@formula(0 ~ 1),
        β=[5]
        )

    n1 = LinearModelComponent(;
        basis=n170(;sfreq=sfreq),
        formula=@formula(0 ~ 1),
        β=[5],
    )

    p3 = LinearModelComponent(;
        basis=p300(;sfreq=sfreq),
        formula=@formula(0 ~ 1),
        β=[7],
    )

    components = [p1, n1, p3]
    ## Design
    if shuffle
        design =
            SingleSubjectDesign(;
                conditions=Dict(
                    :condition => ["bike"] #:condition => ["bike", "face"],
                    #:continuous => range(0, 5, length=10),
                ),
                event_order_function=x -> shuffle(MersenneTwister(seed), x),
            ) |> x -> RepeatDesign(x, 15)
    else
        design =
            SingleSubjectDesign(;
                conditions=Dict(
                    :condition => ["bike"] #:condition => ["bike", "face"],
                    #:continuous => range(0, 5, length=10),
                ),
            ) |> x -> RepeatDesign(x, 15)
    end


    ## Grund Truth design
    effects_dict = Dict(:condition => ["bike"]) #effects_dict = Dict(:condition => ["bike", "face"])

    effects_design = EffectsDesign(design, effects_dict)

    ## simulate

    data, evts = simulate(
        MersenneTwister(seed),
        design,
        components,
        UniformOnset(; width=width, offset=offset),
        PinkNoise(; noiselevel=noiselevel),
    )

    ## simulate ground truth

    gt_data, gt_events = simulate(
        MersenneTwister(seed),
        effects_design,
        components,
        UniformOnset(; width=0, offset=1000),
        NoNoise(),
        return_epoched=true,
    )


    ## change gt to effects style DataFrame
    g = format_gt(gt_data, τ, sfreq) # zero-pad ground_truth and get into correct format
    times = range(τ[1], τ[2], size(g,2)) # get correct times vector
    gt_effects = Unfold.result_to_table([g], [gt_events], [times], ["effects"])

    # Fit Unfold
    m = fit(
        UnfoldModel,
        [Any => (@formula(0 ~ 1), #(@formula(0 ~ 1 + condition + spl(continuous, 4)),
            firbasis(τ=τ, sfreq=sfreq, name="basis"),
        )],
        evts,
        data,
    )

    ## Calculate marginalized effects
    result_effects = effects(effects_dict, m); 

    # Calculate MSE
    MSE = mean((g - result_effects.yhat).^2)

    return DataFrame(;
        results = result_effects,
        ground_truth = gt_effects,
        model = m,
        MSE = MSE,
        d...
        ) # change to d...
end

# Function to zero-pad ground_truth and get into correct format
function format_gt(gt_data, τ, sfreq)
    gt_data = pad_array(reshape(gt_data, size(gt_data,1)), (Int(τ[1]*sfreq), Int(τ[2]*100-size(gt_data, 1)+1)), 0); # pad ground truth to be same length as estimates

    gt_data = reshape(gt_data, 1, size(gt_data)...) # reshape to be channel x samplepoints x event
    return gt_data
end