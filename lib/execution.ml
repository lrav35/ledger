let format_summary total_expenses balances owes_map event transactions =
  let individual_balances = List.map (fun (name, paid, balance) ->
    let status = if balance > 0.0 then "owed" else if balance < 0.0 then "owes" else "even" in
    let owes_to = match Core.StringMap.find_opt name owes_map with
      | Some person_owes_map ->
          Core.StringMap.fold (fun creditor amount acc ->
            `Assoc [("creditor", `String creditor); ("amount", `Float amount)] :: acc
          ) person_owes_map []
      | None -> []
    in
    `Assoc [
      ("name", `String name);
      ("paid", `Float paid);
      ("balance", `Float balance);
      ("status", `String status);
      ("owes_to", `List owes_to)
    ]
  ) balances in
  
  let transaction_details = List.map (fun transaction ->
    let type_str = match transaction.Transaction.ttype with
      | Transaction.Expense -> "expense"
      | Transaction.Payment -> "payment" in
    `Assoc [
      ("date", `String transaction.Transaction.date);
      ("type", `String type_str);
      ("amount", `Float transaction.Transaction.amount);
      ("person", `String transaction.Transaction.person);
      ("description", `String transaction.Transaction.description);
      ("participants", `List (List.map (fun p -> `String p) transaction.Transaction.participants))
    ]
  ) transactions in
  
  `Assoc [
    ("event", `String event);
    ("total_expenses", `Float total_expenses);
    ("attendee_count", `Int (List.length balances));
    ("individual_balances", `List individual_balances);
    ("transactions", `List transaction_details)
  ]

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
    `Assoc [("message", `String "No transactions found.")]
  else
    let (total_expenses, balances, owes_map) =
      Core.calculate_balances transactions attendees in
    format_summary total_expenses balances owes_map event transactions

