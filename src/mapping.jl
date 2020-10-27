# A special mapping from JLL name to Spack package name
jll_to_spack_mapping = Dict{String,String}(
)

function map_jll_name_to_spack(jll_name::String)
    return lowercase(get(jll_to_spack_mapping, jll_name, jll_name[1:end-4]))
end
