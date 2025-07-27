type db_effect = 
  | InsertTransaction of Transaction.t
  | LoadTransactionsByEvent of string

type 'a with_effects = 'a * db_effect list

let pure x = (x, [])

let map f (value, effects) = (f value, effects)

let bind (value, effects1) f =
  let (new_value, effects2) = f value in
  (new_value, effects1 @ effects2)

let add_an_effect eff (value, effects) =
  (value, eff :: effects)
