open Printf
open OpenFlow0x01.Types
open Packet
open Syntax.External
open Word
open Misc

module Learning = struct
    
  (** The objective is to learn the port on which a host is connected on all
      switches. Word48.t is the type of MAC-addresses. This hashtable stores
      switch * host * port tuples. The reason it is keyed-by (switch * host)
      is to acount for host-mobility. When a host moves to a different port 
      on a switch, updating its entry removes the old entry too. *)
  let learned_hosts : (switchId * Word48.t, portId) Hashtbl.t = 
    Hashtbl.create 100

  (** Create a predicate that matches all unknown 
      switch * port * host * port tuples. *)
  let make_unknown_predicate () = 
    Not
      (Hashtbl.fold 
        (fun (sw,eth) pt pol -> 
          Or (And (And (Switch sw, InPort pt), DlSrc eth), pol))
        learned_hosts
        NoPackets)

  (** We're using the Lwt library to create streams. Policy is a stream
      we can read. The push function sends a value into the policy 
      stream. *)
  let (policy, push) = Lwt_stream.create ()

  (** Create a policy that directs all unknown packets to the controller. These
      packets are sent to the [learn_host] function below. *)
  let rec make_learning_policy () = 
    Seq (Filter (make_unknown_predicate ()),
         Act (GetPacket learn_host))

  (** Stores a new switch * host * port tuple in the table, creates a
      new learning policy, and pushes that policy to the stream. *)
  and learn_host sw pt pk : unit =
    begin
      printf "[MacLearning] at switch %Ld host %s at port %d\n%!"
	    sw (string_of_mac pk.pktDlSrc) pt;
      if Hashtbl.mem learned_hosts (sw, pk.pktDlSrc) then
        printf "[MacLearning.ml] at switch %Ld, host %s at port %d (moved)\n%!"
          sw (string_of_mac pk.pktDlSrc) pt
      else
        printf "[MacLearning.ml] at switch %Ld, host %s at port %d\n%!"
          sw (string_of_mac pk.pktDlSrc) pt
    end;
    Hashtbl.replace learned_hosts (sw, pk.pktDlSrc) pt;
    push (Some (make_learning_policy ()))
  
  (** The initial value of the policy is to receives packets from all hosts. *)

  let init = 
    Seq (Filter All, Act (GetPacket learn_host))

  let _ = push (Some init)

end 

module Routing = struct

  let known_hosts () = 
    Hashtbl.fold 
      (fun (sw,dst) _ hosts -> Or (And (Switch sw, DlDst dst), hosts))
      Learning.learned_hosts
      NoPackets

  (** Maps over all tuples, (sw, pt, mac) in [learned_hosts], and
      writes the rule:
      
      Switch = sw && DstMac = mac ==> To pt
      
      Sends traffic for unknown destinations to ToAll ports. *)
  let make_routing_policy () = 
    Hashtbl.fold
      (fun (sw, dst) pt pol ->
        Par (Seq (Filter (And (Switch sw, DlDst dst)), Act (To pt)),  pol))
      Learning.learned_hosts
      (Seq (Filter (Not (known_hosts ())), Act ToAll))

  (** Composes learning and routing policies, which together form
      mac-learning. *)      
  let policy = Lwt_stream.map (fun learning_pol ->
    Par (learning_pol, make_routing_policy ()))
    Learning.policy
end


