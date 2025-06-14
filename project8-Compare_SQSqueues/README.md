# Project 8: Compare AWS SQS Queue Configurations

This script uses the AWS SDK (`boto3`) to compare configuration details between pairs of Amazon SQS queues — typically a normal queue and a resend version.

### Functionality:
- Fetches and filters queue **attributes**, **tags**, and key **settings** like encryption, visibility timeout, and queue type.
- Compares settings between queue pairs.
- Generates **Markdown reports** to visualize differences.
- Aids in **audit**, **documentation**, and **troubleshooting**.

Ideal for cloud engineers working with messaging systems and infrastructure consistency.

