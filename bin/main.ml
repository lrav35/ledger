open Ledger_tool_lib
open Cmdliner

let read_list_from_file filename =
  let ic = open_in filename in
  let rec read_lines acc =
    try
      let line = input_line ic in
      String.split_on_char ',' line
      |> List.map String.trim
      |> List.append acc
      |> read_lines
    with
    | End_of_file ->
        close_in ic;
        acc
  in
  read_lines []

let attendees = read_list_from_file "attendees.txt"

(* === HANDLERS === *)
let handle_add ttype amount description person =
  if amount <= 0.0 then
    Error "Amount must be positive"
  else
    match ttype with
    | Transaction.Expense ->
      Ok (Action.AddExpense { amount; description; person })
    | Transaction.Payment ->
      Ok (Action.AddPayment { amount; description; person })

let handle_summarize () =
  Ok Action.ShowSummary

let handle_help () =
  Ok Action.ShowHelp

(* === SUMMARY === *)

let format_summary total_expenses cost_per_person balances =
  let buffer = Buffer.create 256 in
  
  Buffer.add_string buffer "\n=== EXPENSE SUMMARY ===\n";
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

(* === INTERPRETER === *)

let execute_action action =
  match action with
  | Action.AddExpense { amount; description; person } ->
      let transactions = Persistence.load () in
      let expense = Transaction.create_expense ~amount ~description ~person in
      let updated = expense :: transactions in
      Persistence.save updated;
      Ok (Printf.sprintf "Added expense: %s - $%.2f by %s" description amount person)
  | Action.AddPayment { amount; description; person } ->
      let transactions = Persistence.load () in
      let payment = Transaction.create_payment ~amount ~description ~person in
      let updated = payment :: transactions in
      Persistence.save updated;
      Ok (Printf.sprintf "Added payment: %s - $%.2f by %s" description amount person)
  | Action.ShowSummary ->
      let transactions = Persistence.load () in
      if transactions = [] then
        Ok "No transactions found."
      else
        let (total_expenses, cost_per_person, balances) =
          Core.calculate_balances transactions attendees in
        Printf.printf "DEBUG: %.2f\n" total_expenses;
        Printf.printf "DEBUG: %.2f\n" cost_per_person;
        let summary = format_summary total_expenses cost_per_person balances in
        Ok summary
  | Action.ShowHelp ->
      Ok "Available commands: expense, payment, summary"

(* === USER INTERACTION === *)

let execute_and_print action =
  match execute_action action with
  | Ok msg -> print_endline msg
  | Error msg -> print_endline ("Error: " ^ msg)

let add_expense_cmd =
  let amount = Arg.(required & pos 0 (some float) None & info [] ~docv:"AMOUNT") in
  let person = Arg.(required & pos 1 (some string) None & info [] ~docv:"PERSON") in
  let description = Arg.(required & pos 2 (some string) None & info [] ~docv:"DESCRIPTION") in
  let doc = "Add an expense transaction - cost associated with and will be split across entire group" in
  let term = Term.(const (fun amt desc per ->
    match handle_add Transaction.Expense amt desc per  with
    | Ok action -> execute_and_print action
    | Error msg -> print_endline ("Error: " ^ msg);
  ) $ amount $ description $ person) in
  let info = Cmd.info "expense" ~doc in
  Cmd.v info term

let add_payment_cmd =
  let amount = Arg.(required & pos 0 (some float) None & info [] ~docv:"AMOUNT") in
  let person = Arg.(required & pos 1 (some string) None & info [] ~docv:"PERSON") in
  let description = Arg.(required & pos 2 (some string) None & info [] ~docv:"DESCRIPTION") in
  let doc = "Add a payment transaction - money contributed by an individual to cover the expenses" in
  let term = Term.(const (fun amt desc per ->
    match handle_add Transaction.Payment amt desc per  with
    | Ok action -> execute_and_print action
    | Error msg -> print_endline ("Error: " ^ msg);
  ) $ amount $ description $ person) in
  let info = Cmd.info "payment" ~doc in
  Cmd.v info term

let summary_cmd =
  let doc = "Calculate totals and generate a summary" in
  let term = Term.(const (fun () ->
    match handle_summarize () with
    | Ok action -> execute_and_print action
    | Error msg -> print_endline ("Error: " ^ msg);
  ) $ const ()) in
  let info = Cmd.info "summary" ~doc in
  Cmd.v info term

let help_cmd =
  let doc = "Get help with available commands" in
  let term = Term.(const (fun () ->
    match handle_help () with
    | Ok action -> execute_and_print action
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
