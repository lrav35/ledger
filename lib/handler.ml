let parse_transaction_json json_string =

  let amount_field j = 
    match Yojson.Basic.Util.member "amount" j with
    | `Float f -> f
    | `Int i -> float_of_int i
    | `String s -> float_of_string s
    | _ -> failwith "amount: expected number or decimal string" in

  let open Yojson.Basic.Util in
  try
    let json = Yojson.Basic.from_string json_string in
    let amount = amount_field json in
    let person = json |> member "person" |> to_string in
    let description = json |> member "description" |> to_string in
    let event = json |> member "event" |> to_string in
    let participants = 
      json 
      |> member "participants" 
      |> to_list 
      |> List.map to_string
    in
    Ok (amount, person, description, event, participants)
  with
  | _ -> Error "Invalid JSON format"

(* === HANDLERS === *)
let handle_add ttype amount description person event participants =
  if amount <= 0.0 then
    Error "Amount must be positive"
  else
    match ttype with
    | Transaction.Expense ->
      Ok (Action.AddExpense { amount; description; person; event; participants })
    | Transaction.Payment ->
      Ok (Action.AddPayment { amount; description; person; event; participants })

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
      Ok (`Summary summary)
  | _ ->
      Ok (`Message msg)
