type t =
  | AddExpense of { amount: float; description: string; person: string; event: string; participants: string list }
  | AddPayment of { amount: float; description: string; person: string; event: string; participants: string list }
  | ShowSummary of { event: string }
  | ShowHelp
