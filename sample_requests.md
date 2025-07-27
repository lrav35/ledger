# Add expense
curl -X POST http://localhost:8080/expenses \
  -H "Content-Type: application/json" \
  -d '{"amount": 25.50, "person": "Alice", "description": "Lunch", "event": "team_outing"}'

# Add payment
curl -X POST http://localhost:8080/payments \
  -H "Content-Type: application/json" \
  -d '{"amount": 100.00, "person": "Bob", "description": "Payment", "event": "team_outing"}'

# Get summary
curl http://localhost:8080/summary/team_outing

# Health check
curl http://localhost:8080/health
