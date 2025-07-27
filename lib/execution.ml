let format_summary total_expenses cost_per_person balances event =
  let buffer = Buffer.create 256 in
  Printf.bprintf buffer "\n=== EXPENSE SUMMARY FOR %s ===\n" event;
  Printf.bprintf buffer "Total expenses: $%.2f\n" total_expenses;
  Printf.bprintf buffer "Cost per person: $%.2f\n" cost_per_person;
  Printf.bprintf buffer "Number of attendees: %d\n\n" (List.length balances);
  Buffer.add_string buffer "Individual Balances:\n";
  Buffer.add_string buffer "Name\t\tPaid\t\tBalance\n";
  Buffer.add_string buffer "----\t\t----\t\t-------\n";
  List.iter (fun (name, paid, balance) ->
    let status = if balance > 0.0 then "owed" else if balance < 0.0 then "owes" else "even" in
    Printf.bprintf buffer "%-15s\t$%.2f\t\t$%.2f (%s)\n" name paid balance status
  ) balances;
  Buffer.contents buffer

let execute_action action =
  match action with
  | Action.AddExpense { amount; description; person; event } ->
      let expense = Transaction.create_expense ~amount ~description ~person ~event in
      let msg = Printf.sprintf "Added expense: %s - $%.2f by %s for %s" description amount person event in
      (msg, [Effects.InsertTransaction expense])

  | Action.AddPayment { amount; description; person; event } ->
      let payment = Transaction.create_payment ~amount ~description ~person ~event in
      let msg = Printf.sprintf "Added payment: %s - $%.2f by %s for %s" description amount person event in
      (msg, [Effects.InsertTransaction payment])
  | Action.ShowSummary { event } ->
      let msg = "Summary requested" in
      (msg, [Effects.LoadTransactionsByEvent event])
  | Action.ShowHelp ->
      ("Available commands: expense, payment, summary", [])

let process_summary attendees transactions event =
  if transactions = [] then
    "No transactions found."
  else
    let (total_expenses, cost_per_person, balances) =
      Core.calculate_balances transactions attendees in
    format_summary total_expenses cost_per_person balances event

