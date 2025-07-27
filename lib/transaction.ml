type transaction_type = Expense | Payment

type t = {
  date : string;
  ttype : transaction_type;
  amount : float;
  person : string;
  description : string;
  event: string;
  participants: string list
}

let get_date () =
  let tm = Unix.localtime (Unix.time ()) in
  Printf.sprintf "%d-%02d-%02d" (tm.tm_year + 1900) (tm.tm_mon + 1) tm.tm_mday

let create_expense ~amount ~person ~description ~event ~participants =
  let date = get_date () in
  { date; ttype = Expense; amount; person; description; event; participants}

let create_payment ~amount ~person ~description ~event ~participants=
  let date = get_date () in
  { date; ttype = Payment; amount; person; description; event; participants }
