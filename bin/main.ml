open Ledger_tool_lib
open Cmdliner

let read_list_from_file filename =
  In_channel.with_open_text filename (fun ic ->
    In_channel.input_lines ic
    |> List.concat_map (fun line ->
         String.split_on_char ',' line
         |> List.map String.trim))


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

(* === USER INTERACTION === *)
let execute_and_print db action =
  let attendees = read_list_from_file "attendees.txt" in
  match execute_and_interpret db attendees action with
  | Ok msg -> print_endline msg
  | Error msg -> print_endline ("Error: " ^ msg)

let add_expense_cmd =
  let amount = Arg.(required & pos 0 (some float) None & info [] ~docv:"AMOUNT") in
  let person = Arg.(required & pos 1 (some string) None & info [] ~docv:"PERSON") in
  let description = Arg.(required & pos 2 (some string) None & info [] ~docv:"DESCRIPTION") in
  let event = Arg.(required & pos 3 (some string) None & info [] ~docv:"EVENT") in
  let doc = "Add an expense transaction - cost associated with and will be split across entire group" in
  let term = Term.(const (fun amt desc per evt ->
    let db = Persistence.init_db () in
    match handle_add Transaction.Expense amt desc per evt  with
    | Ok action -> execute_and_print db action
    | Error msg -> print_endline ("Error: " ^ msg);
  ) $ amount $ description $ person $ event) in
  let info = Cmd.info "expense" ~doc in
  Cmd.v info term

let add_payment_cmd =
  let amount = Arg.(required & pos 0 (some float) None & info [] ~docv:"AMOUNT") in
  let person = Arg.(required & pos 1 (some string) None & info [] ~docv:"PERSON") in
  let description = Arg.(required & pos 2 (some string) None & info [] ~docv:"DESCRIPTION") in
  let event = Arg.(required & pos 3 (some string) None & info [] ~docv:"EVENT") in
  let doc = "Add a payment transaction - money contributed by an individual to cover the expenses" in
  let term = Term.(const (fun amt desc per evt->
    let db = Persistence.init_db () in
    match handle_add Transaction.Payment amt desc per evt with
    | Ok action -> execute_and_print db action
    | Error msg -> print_endline ("Error: " ^ msg);
  ) $ amount $ description $ person $ event) in
  let info = Cmd.info "payment" ~doc in
  Cmd.v info term

let summary_cmd =
  let event = Arg.(required & pos 0 (some string) None & info [] ~docv:"EVENT") in
  let doc = "Calculate totals and generate a summary for the specified event" in
  let term = Term.(const (fun evt ->
    let db = Persistence.init_db () in
    match handle_summarize evt with
    | Ok action -> execute_and_print db action
    | Error msg -> print_endline ("Error: " ^ msg);
  ) $ event ) in
  let info = Cmd.info "summary" ~doc in
  Cmd.v info term

let help_cmd =
  let doc = "Get help with available commands" in
  let term = Term.(const (fun () ->
    let db = Persistence.init_db () in
    match handle_help () with
    | Ok action -> execute_and_print db action
    | Error msg -> print_endline ("Error: " ^ msg);
  ) $ const ()) in
  let info = Cmd.info "help" ~doc in
  Cmd.v info term

let main_cmd =
  let doc = "A tool to manage bachelor party expenses" in
  let info = Cmd.info "bachelor-party" ~version:"1.0" ~doc in
  Cmd.group info [add_expense_cmd; add_payment_cmd; summary_cmd; help_cmd]

(* Run the command line application *)
let () = exit (Cmd.eval main_cmd)
