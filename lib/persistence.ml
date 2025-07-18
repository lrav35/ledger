open Sqlite3

let get_db_path () =
  match Sys.getenv_opt "DB_PATH" with
  | Some path -> path
  | None -> "test.db"

let init_db () =
  let db_path = get_db_path () in
  let db = db_open db_path in
  
  let transactions_sql = 
    "CREATE TABLE IF NOT EXISTS transactions (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       date TEXT NOT NULL,
       transaction_type TEXT NOT NULL CHECK(transaction_type IN ('Expense', 'Payment')),
       amount REAL NOT NULL,
       person TEXT NOT NULL,
       description TEXT,
       event_name TEXT NOT NULL
     )" in

  match exec db transactions_sql with
  | Rc.OK -> db
  | _ -> failwith "Failed to create transactions table"


let transaction_type_to_string = function
  | Transaction.Expense -> "Expense"
  | Transaction.Payment -> "Payment"

let transaction_type_of_string = function
  | "Expense" -> Transaction.Expense
  | "Payment" -> Transaction.Payment
  | s -> failwith ("Invalid transaction type: " ^ s)

let load_db_by_event db event_name =
  let sql =
     "SELECT id, date, transaction_type, amount, person, description, event_name 
      FROM transactions 
      WHERE event_name = ?" in
  let stmt = prepare db sql in
  let _ = bind stmt 1 (Data.TEXT event_name) in
  let transactions = ref [] in
  let rec collect_rows acc =
    match step stmt with
    | Rc.ROW ->
        let transaction = {
          date = column_text stmt 1;
          ttype = transaction_type_of_string (column_text stmt 2);
          amount = column_double stmt 3;
          person = column_text stmt 4;
          description = column_text stmt 5;
          event_name;
        } in
        collect_rows (transaction :: acc)
    | Rc.DONE -> List.rev acc
    | rc -> failwith ("Query failed: " ^ (Rc.to_string rc))
  in
  let result = collect_rows [] in
  let () = finalize stmt in
  result

let insert_transaction db transaction =
  let sql = "INSERT INTO transactions (date, transaction_type, amount, person, description, event_name) VALUES (?, ?, ?, ?, ?, ?)" in
  let stmt = prepare db sql in
  let () = bind stmt 1 (Data.TEXT transaction.date) in
  let () = bind stmt 2 (Data.TEXT (transaction_type_to_string transaction.ttype)) in
  let () = bind stmt 3 (Data.FLOAT transaction.amount) in
  let () = bind stmt 4 (Data.TEXT transaction.person) in
  let () = bind stmt 5 (Data.TEXT transaction.description) in
  let () = bind stmt 6 (Data.TEXT transaction.event_name) in
  
  match step stmt with
  | Rc.DONE -> 
      let () = finalize stmt in
      ()
  | _ -> 
      let () = finalize stmt in
      failwith "Insert failed"


type t = Transaction.t list
let transactions_file = "transactions.json"

let load () : Transaction.t list = 
  if Sys.file_exists transactions_file then
    try
      let json = Yojson.Safe.from_file transactions_file in
      match Yojson.Safe.Util.to_list json with
      | json_list ->
        List.fold_left (fun acc json_item ->
          match Transaction.of_yojson json_item with
          | Ok transaction -> transaction :: acc
          | Error _ -> acc
        ) [] json_list
        |> List.rev
      | exception _ -> []
    with _ -> []
  else
    []

let save (transactions : t list) =
  let json_list = List.map Transaction.to_yojson transactions in
  let json = `List json_list in
  Yojson.Safe.to_file transactions_file json
