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
       participants TEXT,
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
     "SELECT id, date, transaction_type, amount, person, description, participants, event_name
      FROM transactions 
      WHERE event_name = ?" in
  let stmt = prepare db sql in
  let _ = bind stmt 1 (Data.TEXT event_name) in
  let rec collect_rows acc =
    match step stmt with
    | Rc.ROW ->
        let participants_json = column_text stmt 6 in
        let participants =
          try
            Yojson.Basic.from_string participants_json
            |> Yojson.Basic.Util.to_list
            |> List.map Yojson.Basic.Util.to_string
          with
          | _ -> []
        in
        let transaction = Transaction.{
          date = column_text stmt 1;
          ttype = transaction_type_of_string (column_text stmt 2);
          amount = column_double stmt 3;
          person = column_text stmt 4;
          description = column_text stmt 5;
          participants = participants;
          event = column_text stmt 7;
        } in
        collect_rows (transaction :: acc)
    | Rc.DONE -> List.rev acc
    | rc -> failwith ("Query failed: " ^ (Rc.to_string rc))
  in
  let result = collect_rows [] in
  let rc = finalize stmt in
  if rc <> Rc.OK then
    failwith ("Failed to finalize statement: " ^ (Rc.to_string rc));
  result

let insert_transaction db (transaction : Transaction.t) =
  let sql = "INSERT INTO transactions (date, transaction_type, amount, person, description, participants, event_name) VALUES (?, ?, ?, ?, ?, ?, ?)" in
  let stmt = prepare db sql in
  let check_bind_result rc =
    if rc <> Rc.OK then failwith ("Bind failed: " ^ (Rc.to_string rc)) in
  let participants_json = 
    `List (List.map (fun s -> `String s) transaction.participants)
    |> Yojson.Basic.to_string
  in
  check_bind_result (bind stmt 1 (Data.TEXT transaction.date));
  check_bind_result (bind stmt 2 (Data.TEXT (transaction_type_to_string transaction.ttype)));
  check_bind_result (bind stmt 3 (Data.FLOAT transaction.amount));
  check_bind_result (bind stmt 4 (Data.TEXT transaction.person));
  check_bind_result (bind stmt 5 (Data.TEXT transaction.description));
  check_bind_result (bind stmt 6 (Data.TEXT participants_json));
  check_bind_result (bind stmt 7 (Data.TEXT transaction.event));
  
  match step stmt with
  | Rc.DONE -> 
      let rc = finalize stmt in
      if rc <> Rc.OK then
        failwith ("Failed to finalize statement: " ^ (Rc.to_string rc))
  | _ -> 
      let rc = finalize stmt in
      let _ = if rc <> Rc.OK then
        failwith ("Failed to finalize statement: " ^ (Rc.to_string rc)) in
      failwith "Insert failed"
