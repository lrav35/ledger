open Sqlite3

let get_db_path () =
  match Sys.getenv_opt "DB_PATH" with
  | Some path -> path
  | None -> "test.db"

let init_db () =
  let db_path = get_db_path () in
  let db = db_open db_path in
  let sql = "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT)" in
  match exec db sql with
  | Rc.OK -> db
  | _ -> failwith "Failed to initialize database"

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

let save (transactions : t) =
  let json_list = List.map Transaction.to_yojson transactions in
  let json = `List json_list in
  Yojson.Safe.to_file transactions_file json
