open Ledger_tool_lib.Transaction
open Ledger_tool_lib.Core

let epsilon = 0.0001

(* testable for balances list *)
let person_balance_testable =
  Alcotest.triple
    Alcotest.string          (* name *)
    (Alcotest.float epsilon) (* total paid *)
    (Alcotest.float epsilon) (* final balance *)

let sorted_balance_list_testable =
  Alcotest.testable
    (Fmt.Dump.list (Alcotest.pp person_balance_testable))
    (fun expected actual ->
      (* sort by name *)
      let sort_by_name = List.sort (fun (n1, _, _) (n2, _, _) -> String.compare n1 n2) in
      let sorted_expected = sort_by_name expected in
      let sorted_actual = sort_by_name actual in
      Alcotest.equal (Alcotest.list person_balance_testable) sorted_expected sorted_actual
    )

(* combine into testable value *)
let summary_testable =
  let epsilon = 0.0001 in
  Alcotest.triple
    (Alcotest.float epsilon) (* total expenses *)
    (Alcotest.float epsilon) (* per person cost *)
    sorted_balance_list_testable


let test_calculate_balances () =
    let attendees = ["Alice"; "Bob"; "Carol"] in
    let input_transactions = [
        { date = "2025-10-26";
          ttype = Payment;
          amount = 50.0;
          person = "Alice";
          description = "Funding Activities";
          event_name = "event"
        };
        { date = "2025-10-27";
          ttype = Expense;
          amount = 90.0;
          person = "Bob";
          description = "Group Dinner";
          event_name = "event"
        };
        { date = "2025-10-28";
          ttype = Expense;
          amount = 30.0;
          person = "Carol";
          description = "Movie Tickets";
          event_name = "event"
        };
        { date = "2025-10-28";
          ttype = Payment;
          amount = 40.0;
          person = "Carol";
          description = "Contrinbuting to Total";
          event_name = "event"
        };
        { date = "2025-10-29";
          ttype = Expense;
          amount = 15.0;
          person = "Dave";
          description = "Coffee";
          event_name = "event"
        }
    ] in

    let expected_total_expenses = 120.0 in
    let expected_cost_per_person = 40.0 in
    let expected_balances = [
        ("Alice", 50.0, -40.0 +. 50.0);
        ("Bob", 90.0, -40.0 +. 90.0);
        ("Carol", 70.0, -40.0 +. 30.0 +. 40.0);
    ] in 

    let expected = (expected_total_expenses, expected_cost_per_person, expected_balances) in
    let actual = calculate_balances input_transactions attendees in
    Alcotest.(check summary_testable) "should create a correct expense transaction" expected actual


let test_empty_list () =
  let expected = (0.0, 0.0, []) in
  let actual = calculate_balances [] [] in
  Alcotest.check summary_testable "Empty list should result in zeros and empty list" expected actual

let () =
  Alcotest.run "Ledger Tests" [
    ("Summary Calculations", [
      Alcotest.test_case "Empty List" `Quick test_empty_list;
      Alcotest.test_case "Basic Transactions" `Quick test_calculate_balances;
    ]);
  ]
