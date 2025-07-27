let parse_transaction_json json_string =
  let open Yojson.Basic.Util in
  try
    let json = Yojson.Basic.from_string json_string in
    let amount = json |> member "amount" |> to_float in
    let person = json |> member "person" |> to_string in
    let description = json |> member "description" |> to_string in
    let event = json |> member "event" |> to_string in
    Ok (amount, person, description, event)
  with
  | _ -> Error "Invalid JSON format"

(* === HANDLERS === *)
let handle_add ttype amount description person event =
  if amount <= 0.0 then
    Error "Amount must be positive"
  else
    match ttype with
    | Transaction.Expense ->
      Ok (Action.AddExpense { amount; description; person; event })
    | Transaction.Payment ->
      Ok (Action.AddPayment { amount; description; person; event })

let handle_summarize event =
  Ok (Action.ShowSummary { event })

let handle_help () =
  Ok Action.ShowHelp


(* === INTERPRETER === *)
let interpret_effect db = function
  | Effects.InsertTransaction transaction ->
      Persistence.insert_transaction db transaction;
      []
  | Effects.LoadTransactionsByEvent event ->
      Persistence.load_db_by_event db event

let run_effects db effects =
  List.fold_left (fun acc eff ->
    let result = interpret_effect db eff in
    acc @ result
  ) [] effects

let execute_and_interpret db attendees action =
  let (msg, effects) = Execution.execute_action action in

  let data = run_effects db effects in

  match action with
  | Action.ShowSummary { event } ->
      let summary = Execution.process_summary attendees data event in
      Ok summary
  | _ ->
      Ok msg
