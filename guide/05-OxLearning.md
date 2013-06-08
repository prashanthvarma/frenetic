Chapter 5: Learning Switch
==========================

In this chapter, you will build an Ethernet learning switch.

Thus far, you've provided connectivity by simply flooding every
packet. Early network devices (called 'hubs') behaved this way, but it
was quickly discovered that they don't scale as the network grows in
size. As an alternative, if we know the location of specific hosts, we
forward direct traffic directly towards them. We can learn the
locations of hosts by remembering where they are when they send
traffic, and flooding traffic for as-yet-unknown hosts. Such a device
is called a switch.

> Not entirely unlike the classic Monty Python sketch "How Not to be Seen"

> FILL

 A learning switch has two logically distinct components:

- The *learning module* builds a table that maps hosts (mac addresses)
  to the switch-port on which they are connected. The learning module
  builds this table by inspects the source ethernet address and inport
  of every packet at the switch.

- The *routing module* uses the table generated above to route traffic
  directly to its route. That is, if the switch receives a packet for
  destination _X_ and the table, mentioned above, has learned that _X_
  is accessible through port _N_, then the routing module forwards the
  packet directly out of port _N_. (If the table does not have an
  entry for _X_, it simply floods the packet.)

### The Learning Switch Function

Naturally, you'll begin by writing a `packet_in` function that learns host
locations. Use `Learning.ml` as a template, which has a hash-table for you
to use as a map from hosts to ports:

```ocaml
let known_hosts : (dlAddr, portId) = Hashtbl.create 50 (* initial capacity *)
```

Use `Hashtbl.add` to learn the location of each host in the
`learning_packet_in` function:

```ocaml
let learning_packet_in (sw : switchId) (xid : xid) (pktIn : packetIn) : unit =
  let pk = parse_payload pktIn.input_payload in
  Hashtbl.add known_hosts <pkt_src> <pkt_in_port>
```

You already know how to extract fields from the payload. The packet's
input port is a field of [pktIn]. Its type is [packetIn], which is
documented in the manual.

For the routing module, you have to fill in the `routing_packet_in`
function to lookup packets' destination in `known_hosts`:

```ocaml
let routing_packet_in (sw : switchId) (xid : xid) (pktIn : packetIn) : unit =
  let pk = parse_payload pktIn.input_payload in
  let pkt_dst = 0L (* [FILL] *) in
  try
    let out_port = Hashtbl.find known_hosts pkt_dst in
    Printf.printf "Sending via port %d to %Ld.\n" out_port pkt_dst;
    send_packet_out sw 0l {
      output_payload = pktIn.input_payload;
      port_id = None;
      apply_actios = [Output (PhysicalPort out_port)]
    }
  with Not_found ->
    (Printf.printf "Flooding to %Ld.\n" pkt_dst;
     send_packet_out sw 0l {
       output_payload = pktIn.input_payload;
       port_id = None;
       apply_actios = [Output AllPorts]
     })
```

Finally, in the `packet_in` handler, run both `learning_packet_in` and
`routing_packet_in`.

#### Compiling and Testing

> FILL (show mobility)

### An Efficient Learning Switch

- 

     
                            
  Hashtbl.add known_hosts <pkt_src> <pkt_in_port>






  

the
  port to which i

 traffic directly to its destinatio

inspects packets' source locations




[Action]: http://frenetic-lang.github.io/frenetic/docs/OpenFlow0x01.Action.html

[PacketIn]: http://frenetic-lang.github.io/frenetic/docs/OpenFlow0x01.PacketIn.html

[PacketOut]: http://frenetic-lang.github.io/frenetic/docs/OpenFlow0x01.PacketOut.html

[OxPlatform]: http://frenetic-lang.github.io/frenetic/docs/Ox_Controller.OxPlatform.html

[Match]: http://frenetic-lang.github.io/frenetic/docs/OpenFlow0x01.Match.html

[Packet]: http://frenetic-lang.github.io/frenetic/docs/Packet.html