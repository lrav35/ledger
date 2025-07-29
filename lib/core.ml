open Transaction

module StringMap = Map.Make(String)

let calculate_balances transactions attendees =

  let (expense_shares, initial_owes_map) =
    List.fold_left (fun (shares_map, owes_acc) t ->
      if t.ttype = Expense && List.mem t.person attendees then
        let participants = List.filter (fun p -> List.mem p attendees) t.participants in
        let num_participants = List.length participants in
        if num_participants > 0 then
          let cost_per_participant = t.amount /. float_of_int num_participants in
          let updated_shares = List.fold_left (fun acc_map participant ->
            let current_owed = StringMap.find_opt participant acc_map |> Option.value ~default:0.0 in
            StringMap.add participant (current_owed +. cost_per_participant) acc_map
          ) shares_map participants in
          let updated_owes = List.fold_left (fun owes_map participant ->
            if participant <> t.person then
              let participant_owes = StringMap.find_opt participant owes_map |> Option.value ~default:StringMap.empty in
              let current_owed_to_person = StringMap.find_opt t.person participant_owes |> Option.value ~default:0.0 in
              let updated_participant_owes = StringMap.add t.person (current_owed_to_person +. cost_per_participant) participant_owes in
              StringMap.add participant updated_participant_owes owes_map
            else
              owes_map
          ) owes_acc participants in
          (updated_shares, updated_owes)
        else
          (shares_map, owes_acc)
      else
        (shares_map, owes_acc)
    ) (StringMap.empty, StringMap.empty) transactions
  in

  let owes_map =
    List.fold_left (fun owes_acc t ->
      if t.ttype = Payment && List.mem t.person attendees then
        match t.participants with
        | [recipient] when List.mem recipient attendees ->
            let payer_owes = StringMap.find_opt t.person owes_acc |> Option.value ~default:StringMap.empty in
            let current_owed_to_recipient = StringMap.find_opt recipient payer_owes |> Option.value ~default:0.0 in
            let new_amount_owed = max 0.0 (current_owed_to_recipient -. t.amount) in
            let updated_payer_owes = 
              if new_amount_owed > 0.0 then
                StringMap.add recipient new_amount_owed payer_owes
              else
                StringMap.remove recipient payer_owes
            in
            StringMap.add t.person updated_payer_owes owes_acc
        | _ -> owes_acc
      else
        owes_acc
    ) initial_owes_map transactions
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

  (total_expenses, balances, owes_map)
