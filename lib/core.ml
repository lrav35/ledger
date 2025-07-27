open Transaction

module StringMap = Map.Make(String)

let calculate_balances transactions attendees =

  let expense_shares =
    List.fold_left (fun map t ->
      if t.ttype = Expense && List.mem t.person attendees then
        let participants = List.filter (fun p -> List.mem p attendees) t.participants in
        let num_participants = List.length participants in
        if num_participants > 0 then
          let cost_per_participant = t.amount /. float_of_int num_participants in
          List.fold_left (fun acc_map participant ->
            let current_owed = StringMap.find_opt participant acc_map |> Option.value ~default:0.0 in
            StringMap.add participant (current_owed +. cost_per_participant) acc_map
          ) map participants
        else
          map
      else
        map
    ) StringMap.empty transactions
  in

  let total_expenses =
    List.fold_left (fun acc t ->
      if t.ttype = Expense && List.mem t.person attendees then
        acc +. t.amount
      else
        acc
    ) 0.0 transactions
  in

  let payments_map =
    List.fold_left (fun map t ->
      let current_paid = StringMap.find_opt t.person map |> Option.value ~default:0.0 in
      let new_paid = match t.ttype with
        | Payment -> current_paid +. t.amount
        | Expense -> if List.mem t.person attendees then current_paid +. t.amount else current_paid
      in
      StringMap.add t.person new_paid map
    ) StringMap.empty transactions
  in

  let balances =
    List.map (fun name ->
      let paid = StringMap.find_opt name payments_map |> Option.value ~default:0.0 in
      let owes = StringMap.find_opt name expense_shares |> Option.value ~default:0.0 in
      let balance = paid -. owes in
      (name, paid, balance)
    ) attendees
  in

  (total_expenses, balances)
