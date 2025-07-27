type t =
  | AddExpense of { amount: float; description: string; person: string; event: string }
  | AddPayment of { amount: float; description: string; person: string; event: string }
  | ShowSummary of { event: string }
  | ShowHelp
