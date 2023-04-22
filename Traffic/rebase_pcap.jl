# Take pcap file, and the address range to rebase.
# Args:
#   1 - Pcap file : String
#   2 - Address range to rebase : String
#   3 - New address range : String
#   4 - Excluded addresses : String (csv)

# Example:
#  rebase_pcap.jl test.pcap 192.168.0.0 10.0.0.0 10.20.30.1,10.20.30.2

# !!! only does /24 ranges at the moment !!!

struct IpAddr
    octet1::UInt8
    octet2::UInt8
    octet3::UInt8
    octet4::UInt8
    IpAddr(s::String) = new(parse.(UInt8, split(s, "."))...)
end

addr(o::Vector{UInt8}) = join(string.(Int64.(o)), ".")

function pcap_addr_stats(pcapf::String, range::Vector{UInt8})::Vector{UInt8} # Vector of endpoints
    ref_dict = Dict{UInt8, Int64}()
    # Read pcap as bytes
    pcap = Vector{UInt8}()
    open(pcapf, "r") do f
        readbytes!(f, pcap, typemax(Int64))
    end
    println("Pcap length: $(length(pcap))")
    # search for range in Pcap
    for i in 1:length(pcap)-length(range)-1
        if pcap[i:i+length(range)-1] == range
            last_octet = pcap[i+length(range)]
            if haskey(ref_dict, last_octet)
                ref_dict[last_octet] += 1
            else
                ref_dict[last_octet] = 1
            end
        end
    end
    # Print stats
    for (oct, count) ∈ ref_dict
        println("Octet: $(addr(vcat(range, oct))), Count: $count")
    end
    return Vector{UInt8}([k for k ∈ keys(ref_dict)])
end

excluded_octects = parse.(UInt8, last.(split.(split(ARGS[4], ","), ".")))
println("Excluded octets: $excluded_octects")

pcapf = ARGS[1]
from = IpAddr(ARGS[2])
to = IpAddr(ARGS[3])
from_range = [from.octet1, from.octet2, from.octet3]
to_range = [to.octet1, to.octet2, to.octet3]

println("\n")

octs = pcap_addr_stats(pcapf, from_range)

remap = Dict{UInt8, UInt8}()

for o ∈ excluded_octects
    while true
        choice = rand(UInt8)
        if choice ∉ octs && choice ∉ values(remap) && choice ∉ excluded_octects
            remap[o] = choice
            break
        end
    end
end


println("\n")

function rebase(pcapf::String, fromrange::Vector{UInt8}, torange::Vector{UInt8}, remap::Dict{UInt8, UInt8})::NTuple{2, String}
    # Read pcap as bytes
    pcap = Vector{UInt8}()
    open(pcapf, "r") do f
        readbytes!(f, pcap, typemax(Int64))
    end
    range_length = length(fromrange)
    # search for range in Pcap
    for i in 1:length(pcap)-range_length-1
        if pcap[i:i+range_length-1] == fromrange
            last_octet = pcap[i+range_length]
            if last_octet ∈ excluded_octects
                pcap[i+range_length] = remap[last_octet]
            end
            pcap[i:i+range_length-1] = torange
        end
    end
    # Write new pcap
    name = join(vcat("rebased", split.(pcapf, ".")[2:end]), ".")
    rebased_name = "Dirty/" * name
    open(rebased_name, "w") do f
        write(f, pcap)
    end
    pcap_addr_stats(rebased_name, torange)
    return (rebased_name, "Rebased/"*name)
end

(broken_checksum, fixed) = rebase(pcapf, from_range, to_range, remap)

run(Cmd(["python3", "fix_checksum.py", broken_checksum, fixed]))