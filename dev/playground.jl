# Script to try out some stuff
using UnfoldSim
using Random
using Parameters
using StatsBase

sfreq = 100

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

components = [p1, n1, p3]

cond_dict = Dict(
    :condition => ["face", "bike"],
    :sac_amplitude => range(0, 5, length = 10),
    :evidence => range(1, 5, length = 8),
    :duration => range(2, 8, length = 12)
    )

design = SingleSubjectDesign(conditions=cond_dict)


@with_kw struct RandomEventsDesign{T} <: UnfoldSim.AbstractDesign
    seed::Int = 1
    nEvents::Int = 100
    design::T
end;

# size function for new design
Base.size(design::RandomEventsDesign) = (design.nEvents,);

function UnfoldSim.generate_events(design::RandomEventsDesign)
    # generate all events of single subject design
    full_events = UnfoldSim.generate_events(design.design)

    # Pull random events (without replacement) from events 
    @assert size(full_events, 1) >= design.nEvents
    idx = sample(MersenneTwister(design.seed), 1:size(full_events, 1), design.nEvents, replace = false)
    evts = full_events[idx, :]
    return evts
end;

# For NAT simulation
conditions = [
    :condition => (x -> x .== "face"),
    :sac_amplitude => (x -> x .== 0.0),
    :evidence => (x -> x .== 1.),
    :duration => (x -> x .== 2.)
]

# For FRP
conditions = [
    :condition => (x -> x .== "face")
]


plot_estimation_vs_gt(@rsubset(all_results, :sim_function == "NAT", :seed == 5, :width == 10), conditions; title = "NAT simulation, seed 8, width 10")
current_figure()
#save("./plots/2050909-estimation-vs-gt.pdf", current_figure())

function rainclouds(f = Figure())  
    raincloud_results(@rsubset(all_results, :shuffle == false), :width)
    f
end

function rainclouds_s(f = Figure())  
    raincloud_results(@rsubset(all_results, :shuffle == true), :width)
    f
end

fig = Figure(; size = (800, 600))
rainclouds(fig[1, 1])
rainclouds_s(fig[1, 2])
fig

raincloud_all_designs(all_results, :width;
                    size = (2835,983),
                    plot_boxplots = true, 
                    cloud_width=1.5, 
                    gap = 0.2, 
                    markersize = 10, 
                    boxplot_width=0.2
                    )

f = current_figure()
#save("./plots/2050909-rainclouds-all-jitter.pdf", f)

### 
rename = ["RT" => "Reaction Time", "FRP" => "Fixation-Related Potential", "NAT" => "Naturalistic"]
p1 = data(all_results) * mapping(:ntrials => nonnumeric,
                                 :MSE,
                                 col = :width => nonnumeric, 
                                 color = :sim_function => renamer(rename), 
                                 dodge = :sim_function => renamer(rename)) * visual(BoxPlot)

gdf = groupby(all_results, [:ntrials, :sim_function])
means = combine(gdf, :MSE => mean)
p2 = data(means) * mapping(:width => nonnumeric, :MSE_mean, color = :sim_function => renamer(rename)) * visual(Lines) # + data(means) * mapping(collumn => nonnumeric, :MSE_mean) * visual(Scatter)

#tm = unique(df[!, collumn])
#Makie.Categorical(Makie.wong_colors()[1:7])
f = Figure(; size = (1436,1058))
limits = (nothing, (-1.5, 60))
labelsizes= 28;
ticksizes = 24;
gr = draw!(f, p1; 
                axis = (; #xlabel = "Jitter Distribution Width (samples)",
                          xlabel = "Number of Trials",
                          xticklabelsize = ticksizes,
                          xlabelsize = labelsizes, 
                          ylabel = String(:MSE), 
                          ylabelsize = labelsizes,
                          yticklabelsize = ticksizes,
                          limits = limits))

axi = gr[2].axis
spines = (:r,:t, :l)
hidespines!(axi, spines...)
hidedecorations!(axi, grid = true, ticks = false, ticklabels = false, label = false)
hideydecorations!(axi)
legend!(f[1, 1], grid; tellheight=false, tellwidth=false, halign=:right, valign=:top)
#draw!(f, p2)
f
#save("./plots/2050909-boxplot_ntrials.pdf", f)


