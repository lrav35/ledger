type action =
  | AddExpense of { amount: float; description: string; person: string }
  | AddPayment of { amount: float; description: string; person: string }
  | ShowSummary
  | ShowHelp
