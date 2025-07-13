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
