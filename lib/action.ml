type t = 
  | AddExpense of { amount: float; description: string; person: string }
  | AddPayment of { amount: float; description: string; person: string }
  | ShowSummary of { event: string }
  | ShowHelp
