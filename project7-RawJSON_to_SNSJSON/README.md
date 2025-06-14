# Project 7: JSON Payload to AWS SNS Formatter

This Python script processes incoming JSON payloads from different markets and converts them into a standard AWS SNS message format. In this scenario each market uses a slightly different JSON structure, therefore I defined 4 different functions.

### Workflow:
- Detects the **entity type** from the input.
- Routes to a **custom transformation function** depending on the entity.
- Outputs a **structured SNS-compliant JSON** ready for publishing or integration.

Useful for maintaining consistency in message formats across distributed systems.

