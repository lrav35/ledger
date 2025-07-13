type t = Transaction.t list

val load : unit -> t

val save : t -> unit
