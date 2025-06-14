# Project 7: JSON Payload to AWS SNS Formatter

This Python script processes incoming JSON payloads from different markets and converts them into a standard AWS SNS message format.

### Workflow:
- Detects the **entity type** from the input.
- Routes to a **custom transformation function** depending on the entity.
- Outputs a **structured SNS-compliant JSON** ready for publishing or integration.

Useful for maintaining consistency in message formats across distributed systems.

