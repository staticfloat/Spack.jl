using TOML

# Strip JLL-specific oddities from version number
function strip_jll_version_weirdness(v::String)
    # Right now they're all valid VersionNumbers with weird build_number's.
    # Strip it out.
    vn = VersionNumber(v)
    return string(vn.major, ".", vn.minor, ".", vn.patch)
end

function get_pkg_version(manifest::Dict, pkg_name::String)
    if !haskey(manifest, pkg_name)
        return nothing
    end
    @assert length(manifest[pkg_name]) == 1
    pkg = first(manifest[pkg_name])
    if !haskey(pkg, "version")
        return nothing
    end
    return strip_jll_version_weirdness(pkg["version"])
end

function get_pkg_uuid(manifest::Dict, pkg_name::String)
    if !haskey(manifest, pkg_name)
        return nothing
    end
    @assert length(manifest[pkg_name]) == 1
    pkg = first(manifest[pkg_name])
    if !haskey(pkg, "uuid")
        return nothing
    end
    return pkg["uuid"]
end

function get_jlls(project_dir::String)
    project_path = joinpath(project_dir, "Project.toml")
    project = TOML.parsefile(project_path)
    jll_names = filter(k -> endswith(k, "_jll"), keys(get(project, "deps", Dict{String,Any}())))

    manifest_path = joinpath(project_dir, "Manifest.toml")
    manifest = TOML.parsefile(manifest_path)

    jll_infos = Dict{String,String}[]
    for jll_name in jll_names
        jll_info = Dict("name" => jll_name)

        # Add a version, if we know of one
        version = get_pkg_version(manifest, jll_name)
        if version !== nothing
            jll_info["version"] = version
        end

        uuid = get_pkg_uuid(manifest, jll_name)
        if uuid !== nothing
            jll_info["uuid"] = uuid
        end

        push!(jll_infos, jll_info)
    end
    return jll_infos
end
