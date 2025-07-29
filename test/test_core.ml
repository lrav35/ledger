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
    sorted_balance_list_testable
    Alcotest.unit (* owes_map - we'll ignore for now *)


let test_calculate_balances () =
    let attendees = ["Alice"; "Bob"; "Carol"] in
    let input_transactions = [
        { date = "2025-10-26";
          ttype = Payment;
          amount = 50.0;
          person = "Alice";
          description = "Funding Activities";
          event = "event";
          participants = []
        };
        { date = "2025-10-27";
          ttype = Expense;
          amount = 90.0;
          person = "Bob";
          description = "Group Dinner";
          event = "event";
          participants = ["Alice"; "Bob"; "Carol"]
        };
        { date = "2025-10-28";
          ttype = Expense;
          amount = 30.0;
          person = "Carol";
          description = "Movie Tickets";
          event = "event";
          participants = ["Alice"; "Bob"; "Carol"]
        };
        { date = "2025-10-28";
          ttype = Payment;
          amount = 40.0;
          person = "Carol";
          description = "Contrinbuting to Total";
          event = "event";
          participants = []
        };
        { date = "2025-10-29";
          ttype = Expense;
          amount = 15.0;
          person = "Dave";
          description = "Coffee";
          event = "event";
          participants = ["Dave"; "Eve"]
        }
    ] in

    let expected_total_expenses = 120.0 in
    let expected_balances = [
        ("Alice", 50.0, 10.0);
        ("Bob", 90.0, 50.0);
        ("Carol", 70.0, 30.0);
    ] in 

    let expected = (expected_total_expenses, expected_balances, ()) in
    let (total, balances, _owes_map) = calculate_balances input_transactions attendees in
    let actual = (total, balances, ()) in
    Alcotest.(check summary_testable) "should create a correct expense transaction" expected actual


let test_empty_list () =
  let expected = (0.0, [], ()) in
  let (total, balances, _owes_map) = calculate_balances [] [] in
  let actual = (total, balances, ()) in
  Alcotest.check summary_testable "Empty list should result in zeros and empty list" expected actual

let test_payment_reduces_debt () =
  let attendees = ["Alice"; "Bob"] in
  let transactions = [
    (* Bob pays $60 for dinner shared between Alice and Bob *)
    { date = "2025-01-01"; ttype = Expense; amount = 60.0; person = "Bob"; 
      description = "Dinner"; event = "event"; participants = ["Alice"; "Bob"] };
    (* Alice pays Bob $20 *)
    { date = "2025-01-02"; ttype = Payment; amount = 20.0; person = "Alice"; 
      description = "Paying Bob"; event = "event"; participants = ["Bob"] };
  ] in
  
  let (_total_expenses, _balances, owes_map) = calculate_balances transactions attendees in
  
  (* Alice should owe Bob only $10 now (was $30, paid $20) *)
  let alice_owes = StringMap.find_opt "Alice" owes_map |> Option.value ~default:StringMap.empty in
  let alice_owes_bob = StringMap.find_opt "Bob" alice_owes |> Option.value ~default:0.0 in
  
  Alcotest.(check (float 0.001)) "Alice should owe Bob $10 after payment" 10.0 alice_owes_bob

let () =
  Alcotest.run "Ledger Tests" [
    ("Summary Calculations", [
      Alcotest.test_case "Empty List" `Quick test_empty_list;
      Alcotest.test_case "Basic Transactions" `Quick test_calculate_balances;
      Alcotest.test_case "Payment Reduces Debt" `Quick test_payment_reduces_debt;
    ]);
  ]
