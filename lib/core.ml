type transaction_type = Expense | Payment

type transaction = {
  date : string;
  ttype : transaction_type;
  amount : float;
  person : string;
  description : string;
}

module StringMap = Map.Make(String)

let calculate_balances transactions attendees =
  let total_expenses =
    List.fold_left (fun acc t ->
      if t.ttype = Expense && List.mem t.person attendees then
        acc +. t.amount
      else
        acc
    ) 0.0 transactions
  in
  let num_attendees = List.length attendees in
  let cost_per_person = if num_attendees > 0 then total_expenses /. float_of_int num_attendees else 0.0 in
  let payments_map =
    List.fold_left (fun map t ->
      let current_paid = StringMap.find_opt t.person map |> Option.value ~default:0.0 in
      let new_paid = match t.ttype with
        | Payment -> current_paid +. t.amount
        (* If you fronted the money for an expense, it counts as you "paying" that amount *)
        | Expense -> if List.mem t.person attendees then current_paid +. t.amount else current_paid
      in
      StringMap.add t.person new_paid map
    ) StringMap.empty transactions
  in
  let balances =
    List.map (fun name ->
      let paid = StringMap.find_opt name payments_map |> Option.value ~default:0.0 in
      let balance = paid -. cost_per_person in
      (name, paid, balance)
    ) attendees
  in
  (total_expenses, cost_per_person, balances)
