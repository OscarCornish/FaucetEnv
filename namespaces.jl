
FAUCET_PREFIX = "FaucetNS"

cmdify(s::String) = Cmd(String.(split(s, " ")))

function run_str(s::String)::Nothing
    run(cmdify(s))
    return nothing
end

function get_namespaces()::Vector{String}
    return readlines(`ip netns ls`)
end

get_faucet_namespaces() = filter(x -> startswith(x, FAUCET_PREFIX), get_namespaces())

ns(name::String) = name == "" ? "" : "ip netns exec $FAUCET_PREFIX$name "

function create_namespace(name::String, netns::String="")::Nothing
    run_str("ip netns add $FAUCET_PREFIX$name")
end

function delete_namespace(name::String)::Nothing
    run_str("ip netns del $FAUCET_PREFIX$name")
end

function create_veth_pair(name1::String, name2::String, netns::String="")::Nothing
    run_str("$(ns(netns))ip link add $FAUCET_PREFIX$name1 type veth peer name $FAUCET_PREFIX$name2")
end
create_veth_pair(name::String, netns::String="") = create_veth_pair("$(name)a", "$(name)b", netns)

function move_dev(name::String, dest_ns::String, source_ns::String="")::Nothing
    run_str("$(ns(source_ns))ip link set $FAUCET_PREFIX$name netns $FAUCET_PREFIX$dest_ns")
end

function set_dev_address(dev::String, cidr::String, netns::String="")::Nothing
    run_str("$(ns(netns))ip a add $cidr dev $FAUCET_PREFIX$dev")
end

function set_dev_up(dev::String, netns::String="")::Nothing
    run_str("$(ns(netns))ip link set $FAUCET_PREFIX$dev up")
end

function create_bridge(name::String, netns::String="")::Nothing
    run_str("$(ns(netns))ip link add $FAUCET_PREFIX$name type bridge")
end

function add_bridge_device(name::String, bridge::String, netns::String="")::Nothing
    run_str("$(ns(netns))ip link set $FAUCET_PREFIX$name master $FAUCET_PREFIX$bridge")
end

get_devs(netns::String="")::String = read(cmdify("$(ns(netns))ip a"), String)


# +---------------------------+
# | ns: bridge                |
# |                           |
# |            br0            |
# |           /   \           |
# |     sendb      recvb      |
# |                           |
# +---------------------------+

# +---------------------------+
# | ns: sender                |
# |                           |
# |          senda            |
# |                           |
# +---------------------------+

# +---------------------------+
# | ns: receiver              |
# |                           |
# |          recva            |
# |                           |
# +---------------------------+

# All have FAUCET_PREFIX prepended to them



function create_Faucet_env()::Nothing
    namespaces = ["bridge", "sender", "receiver", "aux"]
    @info "Created namespaces." namespaces
    create_namespace.(namespaces)
    @info "Faucet namespaces" get_faucet_namespaces()

    # Create sender veth pairs
    create_veth_pair("senda", "sendb", "sender")
    # Move senderb to bridge namespace
    move_dev("sendb", "bridge", "sender")
    set_dev_address("senda", "10.20.30.3/24", "sender")

    # Create receiver veth pairs
    create_veth_pair("recva", "recvb", "receiver")
    # Move receiverb to bridge namespace
    move_dev("recvb", "bridge", "receiver")
    set_dev_address("recva", "10.20.30.2/24", "receiver")

    # Create veth pair for aux
    create_veth_pair("auxa", "auxb", "aux")
    # Move auxb to bridge namespace
    move_dev("auxb", "bridge", "aux")
    set_dev_address("auxa", "10.20.30.201/24", "aux")

    # Create bridge
    create_bridge("br0", "bridge")

    # Add senderb and receiverb to bridge
    add_bridge_device("sendb", "br0", "bridge")
    add_bridge_device("recvb", "br0", "bridge")
    add_bridge_device("auxb", "br0", "bridge")

    bridge_devs = get_devs("bridge")
    sender_devs = get_devs("sender")
    receiver_devs = get_devs("receiver")
    aux_devs = get_devs("aux")

    # Bring devices up
    set_dev_up("senda", "sender")
    set_dev_up("recva", "receiver")
    set_dev_up("auxa", "aux")
    set_dev_up("sendb", "bridge")
    set_dev_up("recvb", "bridge")
    set_dev_up("auxb", "bridge")
    set_dev_up("br0", "bridge")

    @debug "Devs created and setup" bridge_devs sender_devs receiver_devs aux_devs
    return nothing
end

function teardown()::Nothing
    namespaces = ["bridge", "sender", "receiver", "aux"]
    @info "Deleting namespaces." namespaces
    delete_namespace.(namespaces)
    @info "Faucet namespaces" get_faucet_namespaces()
end
