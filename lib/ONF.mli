(** Compiler for NetKAT *)


(* A set of maps from header names to header values *)
module HdrValSet : Set.S
  with type elt = NetKAT_Types.hdrValMap

(** Conjunction of tests, where each test tests a distinct field. *)
type pred = NetKAT_Types.hdrValMap

(** Set of updates, where each update affects a distinct field. Therefore, they
	  all commute with each other. *)
type seq = NetKAT_Types.hdrValMap

type sum = HdrValSet.t

type local =
  | Action of sum
  | ITE of pred * sum * local

val compile : NetKAT_Types.pol -> local

val to_netkat : local -> NetKAT_Types.pol