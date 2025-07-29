let format_summary total_expenses balances owes_map event transactions =
  let buffer = Buffer.create 256 in
  Printf.bprintf buffer "\n=== EXPENSE SUMMARY FOR %s ===\n" event;
  Printf.bprintf buffer "Total expenses: $%.2f\n" total_expenses;
  Printf.bprintf buffer "Number of attendees: %d\n\n" (List.length balances);
  Buffer.add_string buffer "Individual Balances:\n";
  Buffer.add_string buffer "Name\t\tPaid\t\tBalance\n";
  Buffer.add_string buffer "----\t\t----\t\t-------\n";
  List.iter (fun (name, paid, balance) ->
    let status = if balance > 0.0 then "owed" else if balance < 0.0 then "owes" else "even" in
    Printf.bprintf buffer "%-15s\t$%.2f\t\t$%.2f (%s)\n" name paid balance status;
    
    (* Show who this person owes money to *)
    (match Core.StringMap.find_opt name owes_map with
     | Some person_owes_map ->
         Core.StringMap.iter (fun creditor amount ->
           Printf.bprintf buffer "  -> owes $%.2f to %s\n" amount creditor
         ) person_owes_map
     | None -> ())
  ) balances;
  
  Buffer.add_string buffer "\nTransaction Details:\n";
  Buffer.add_string buffer "Date\t\tType\t\tAmount\t\tPerson\t\tDescription\t\tParticipants\n";
  Buffer.add_string buffer "----\t\t----\t\t------\t\t------\t\t-----------\t\t------------\n";
  List.iter (fun transaction ->
    let type_str = match transaction.Transaction.ttype with
      | Transaction.Expense -> "Expense"
      | Transaction.Payment -> "Payment" in
    let participants_str = String.concat ", " transaction.Transaction.participants in
    Printf.bprintf buffer "%s\t%s\t\t$%.2f\t\t%-10s\t%-15s\t%s\n"
      transaction.Transaction.date
      type_str
      transaction.Transaction.amount
      transaction.Transaction.person
      transaction.Transaction.description
      participants_str
  ) transactions;
  
  Buffer.contents buffer

let execute_action action =
  match action with
  | Action.AddExpense { amount; description; person; event; participants } ->
      let expense = Transaction.create_expense ~amount ~description ~person ~event ~participants in
      let msg = Printf.sprintf "Added expense: %s - $%.2f by %s for %s" description amount person event in
      (msg, [Effects.InsertTransaction expense])

  | Action.AddPayment { amount; description; person; event; participants } ->
      let payment = Transaction.create_payment ~amount ~description ~person ~event ~participants in
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
    let (total_expenses, balances, owes_map) =
      Core.calculate_balances transactions attendees in
    format_summary total_expenses balances owes_map event transactions

