# Add expense
curl -X POST http://localhost:8080/expenses \
  -H "Content-Type: application/json" \
-d '{"amount": 150.0, "person": "Alice", "description": "Lunch", "event": "team_outing", "participants": ["Alice", "Bob", "Francisco"]}'

curl -X POST http://localhost:8080/expenses \
  -H "Content-Type: application/json" \
-d '{"amount": 80.0, "person": "Francisco", "description": "More Lunch", "event": "team_outing", "participants": ["Alice", "Francisco"]}'

curl -X POST http://localhost:8080/expenses \
  -H "Content-Type: application/json" \
-d '{"amount": 30.0, "person": "Bob", "description": "Lunch", "event": "team_outing", "participants": ["Alice", "Bob", "Francisco"]}'

# Add payment
curl -X POST http://localhost:8080/payments \
  -H "Content-Type: application/json" \
-d '{"amount": 100.00, "person": "Bob", "description": "Payment", "event": "team_outing", "participants": []}'

# Get summary
curl http://localhost:8080/summary/team_outing

# Health check
curl http://localhost:8080/health
