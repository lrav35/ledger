(* For dates, we'll use string "YYYY-MM-DD" for simplicity in CSV *)
(* module StringMap = Map.Make(String) *)
(**)
(* type expense = { *)
(*   date : string; *)
(*   item : string; *)
(*   amount : float; *)
(*   paid_by : string; *)
(*   shared_amongst : string list; *)
(* } *)
(**)
(* type payment = { *)
(*   date : string; *)
(*   from_person : string; *)
(*   amount : float; *)
(* } *)
(**)
(* let attendees_file = "attendees.txt" *)
(* let expenses_file = "expenses.csv" *)
(* let payments_file = "payments.csv" *)

let expenses_headers = ["Date"; "Item"; "Amount"; "PaidBy"; "SharedAmongst"]
let payments_headers = ["Date"; "FromPerson"; "Amount"]

let () =
  print_endline "printing expense headers:";
    List.iter (fun e -> Printf.printf "Item: %s\n" e) expenses_headers;

  print_endline "printing payment headers:";
    List.iter (fun p -> Printf.printf "Item: %s\n" p) payments_headers;
