** Assignment instructions as part of the AWS Cloud Technical Essentials course from Coursera

Design a three-tier architecture that follows AWS best practices by using services such as Amazon Virtual Private Cloud (Amazon VPC), Amazon Elastic Compute Cloud (Amazon EC2), Amazon Relational Database Service (Amazon RDS) with high availability, and Elastic Load Balancing (ELB). Create an architecture diagram that lays out your design, including the networking layer, compute layer, database layer, and anything else that’s needed to accurately depict the architecture. Write a few paragraphs that explain why you chose the AWS services that you used and how they would support the solution for the given scenario. Your explanation must describe how traffic flows through the different AWS components—from the client to the backend database, and back to the client.

** AWS Architecture Explanation

For this solution, I implemented a 3-tier architecture in AWS to align with the principles of high availability, fault tolerance, scalability, and security. This architecture separates concerns into the presentation layer, application layer, and database layer, which improves maintainability and security. It is deployed in a single AWS region (Europe) using two Availability Zones (AZs) to ensure redundancy and fault isolation, supporting the Reliability and High Availability principles of cloud architecture design.

At the foundation, I created a single Virtual Private Cloud (VPC) to logically isolate my network environment. Inside each AZ, I deployed one public subnet and one private subnet. The public subnets host EC2 instances (application and presentation layers), while the private subnets host MySQL databases (database layer). This subnet separation follows the Security and Network Segmentation best practices, allowing me to tightly control access to sensitive data.

To efficiently handle incoming web traffic, I used an Application Load Balancer (ALB). It receives HTTP requests from client browsers and routes them to EC2 instances in the public subnets. These instances are stateless, meaning they don’t store session data locally. This enables horizontal scaling through Auto Scaling Groups, which add or remove instances based on demand. This setup supports the principles of Performance Efficiency and Cost Optimization by dynamically adjusting resources to actual usage patterns.

For routing, I configured two route tables:

The main route table is associated with the public subnets and includes a route to an Internet Gateway (IGW), allowing EC2 instances to communicate with the internet.

A custom route table is associated with the private subnets and deliberately omits any route to the IGW. This ensures that databases remain inaccessible from the public internet, promoting Security and Data Protection.

To enhance infrastructure security, I implemented security groups (stateful virtual firewalls):

One security group for EC2 instances allows inbound traffic on specific ports (e.g., 80 for HTTP, 22 for SSH) from the internet.

Another security group for the MySQL database only allows inbound traffic on port 3306 from the EC2 security group. It denies all other access, including from the internet or unrelated resources.

This layered security model upholds the principle of least privilege, allowing only essential access between application and database tiers. The use of private subnets for databases ensures they are logically isolated, while public subnets for EC2 instances allow controlled access from users via the internet. These architectural decisions collectively support the AWS Well-Architected Framework, particularly the pillars of Security, Reliability, Performance Efficiency, and Operational Excellence.
