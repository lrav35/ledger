val init_db : unit -> Sqlite3.db

val load_db_by_event : Sqlite3.db -> string -> Transaction.t list

val insert_transaction : Sqlite3.db -> Transaction.t -> unit
