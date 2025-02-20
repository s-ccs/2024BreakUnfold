# Activate DrWatson
using DrWatson
@quickactivate :BreakUnfold

# DrWatson default change
DrWatson.default_prefix(c::Dict) = string(split(string(c[:sim_fun]), "_")[1])

# Make DataFrames usable for produce_or_load
#DrWatson._wsave(filename::AbstractString, df::DataFrame; kwargs...) = DrWatson.FileIO.save(filename, df=df; kwargs...)
DrWatson._wsave(filename::AbstractString, df::DataFrame; kwargs...) = DrWatson.JLD2.@save(filename, df=df)


# Space for parameters
allparams = Dict(
    "noiselevel" => [7],#collect(3:6),
    "shuffle" => [false], # random order sequence?
    "offset" => [10], # Event onset offset -> influences overlap
    "width" => [5, 10, 15], #[5, 10, 15, 20, 30, 40, 50], # Width of distribution -> determines jitter; 0 = no jitter
    "seed" => collect(1:2),
    "sfreq" => 100,
    "τ" => (-0.1, 1),
    "sim_fun" => [FRP_sim]#[FRP_sim, RT_sim]
)

dicts = dict_list(tosymboldict(allparams))

# Simulations
all_results_FRP = DataFrame()
all_results_RT = DataFrame()
pbar = ProgressBar(total=size(dicts, 1))

@time for d in dicts
    update(pbar)
    #append!(all_results_FRP, jitter_simulation(d, FRP_sim))
    #append!(all_results_RT, jitter_simulation(d, RT_sim))
    # TODO: figure out tagsave
   tmp_data, tmp_file = produce_or_load(jitter_simulation, d,  datadir("jitter_simulations"); tag =false)
    append!(all_results_RT, tmp_data)
end