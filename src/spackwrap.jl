using Scratch

export spack, spackify

function get_spack_exe()
    spack_dir = @get_scratch!("spack_install")
    exe_path = joinpath(spack_dir, "bin", "spack")
    if !isfile(exe_path)
        run(`git clone https://github.com/spack/spack.git $(spack_dir)`)
    end
    return exe_path
end

function spack(args...)
    spack_exe = get_spack_exe()
    run(`$(spack_exe) $(args)`)
end

function get_spack_env(name::String)
    env = @get_scratch!("spackenv-$(name)")
    if !isfile(joinpath(env, "spack.yaml"))
        spack("env", "create", "-d", env)
    end
    return env
end

function with_spack_env(f::Function, name::String)
    env = get_spack_env(name)
    return withenv("SPACK_ENV" => env) do
        return f(env)
    end
end

function spackify_jll(jll_info::Dict{String,String})
    ret = map_jll_name_to_spack(jll_info["name"])
    if haskey(jll_info, "version")
        ret = string(ret, "@", jll_info["version"])
    end
    return ret
end

function spackify(project::String; julia_version=VERSION)
    # Collect JLLs in the project
    jll_infos = get_jlls(project)

    # Create spack environment
    project_name = basename(dirname(project))

    # Activate the environment, install all of the packages
    with_spack_env(project_name) do env_dir
        spack("install", spackify_jll.(jll_infos)..., "julia@$(julia_version)")
    end

    # Get some useful paths
    env_path = get_spack_env(project_name)
    view_prefix = joinpath(env_path, ".spack-env", "view")
    julia_prefix = dirname(dirname(realpath(joinpath(view_prefix, "bin", "julia"))))

    # Next, generate overrides in that Julia's stdlib depot for each JLL here.
    stdlib_artifacts_dir = joinpath(julia_prefix, "share", "julia", "artifacts")
    mkpath(stdlib_artifacts_dir)
    open(joinpath(stdlib_artifacts_dir, "Overrides.toml"), "w") do io
        overrides = Dict(jll["uuid"] => Dict(jll["name"][1:end-4] => view_prefix) for jll in jll_infos)
        TOML.print(io, overrides)
    end
end
