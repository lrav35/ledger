open Ledger_tool_lib

let read_list_from_file filename =
  In_channel.with_open_text filename (fun ic ->
    In_channel.input_lines ic
    |> List.concat_map (fun line ->
         String.split_on_char ',' line
         |> List.map String.trim))

let attendees = lazy (read_list_from_file "attendees.txt")

let db_field = Dream.new_field ()

let with_db handler request =
  let db = Persistence.init_db () in
  Dream.set_field request db_field db;
  handler request

let get_db request =
  match Dream.field request db_field with
  | None -> failwith "Database not initialized"
  | Some db -> db

(* JSON response helpers *)
let success_response message =
  `Assoc [("status", `String "success"); ("message", `String message)]
  |> Yojson.Basic.to_string
  |> Dream.json

let error_response message =
  `Assoc [("status", `String "error"); ("message", `String message)]
  |> Yojson.Basic.to_string
  |> Dream.json ~status:`Bad_Request

(* API Endpoints *)
let add_expense_handler request =
  let db = get_db request in
  let%lwt body = Dream.body request in
  match Handler.parse_transaction_json body with
  | Error msg -> (error_response msg)
  | Ok (amount, person, description, event, participants) ->
      match Handler.handle_add Transaction.Expense amount description person event participants with
      | Error msg -> (error_response msg)
      | Ok action ->
          (match Handler.execute_and_interpret db (Lazy.force attendees) action with
           | Ok (`Message msg) -> (success_response msg)
           | Ok (`Summary _) -> (error_response "Unexpected summary response")
           | Error msg -> (error_response msg))

let add_payment_handler request =
  let db = get_db request in
  let%lwt body = Dream.body request in
  match Handler.parse_transaction_json body with
  | Error msg ->  (error_response msg)
  | Ok (amount, person, description, event, participants) ->
      match Handler.handle_add Transaction.Payment amount description person event participants with
      | Error msg -> (error_response msg)
      | Ok action ->
          (match Handler.execute_and_interpret db (Lazy.force attendees) action with
           | Ok (`Message msg) -> (success_response msg)
           | Ok (`Summary _) -> (error_response "Unexpected summary response")
           | Error msg -> (error_response msg))

let get_summary_handler request =
  let db = get_db request in
  let event = Dream.param request "event" in
  match Handler.handle_summarize event with
  | Error msg ->  (error_response msg)
  | Ok action ->
      (match Handler.execute_and_interpret db (Lazy.force attendees) action with
       | Ok (`Summary summary) -> 
           `Assoc [("status", `String "success"); ("summary", summary)]
           |> Yojson.Basic.to_string
           |> Dream.json
       | Ok (`Message _) -> (error_response "Unexpected message response")
       | Error msg ->  (error_response msg))

(* Health check endpoint *)
let health_handler _request =
   (success_response "Server is running")

(* Main server setup *)
let () =
  Dream.run ~port:8080
  @@ Dream.logger
  @@ with_db
  @@ Dream.router [
    Dream.post "/expenses" add_expense_handler;
    Dream.post "/payments" add_payment_handler;
    Dream.get "/summary/:event" get_summary_handler;
    Dream.get "/health" health_handler;
  ]
