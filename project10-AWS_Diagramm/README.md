** Assignment instructions

Design a three-tier architecture that follows AWS best practices by using services such as Amazon Virtual Private Cloud (Amazon VPC), Amazon Elastic Compute Cloud (Amazon EC2), Amazon Relational Database Service (Amazon RDS) with high availability, and Elastic Load Balancing (ELB). Create an architecture diagram that lays out your design, including the networking layer, compute layer, database layer, and anything else that’s needed to accurately depict the architecture. Write a few paragraphs that explain why you chose the AWS services that you used and how they would support the solution for the given scenario. Your explanation must describe how traffic flows through the different AWS components—from the client to the backend database, and back to the client.


** AWS Architecture Explanation

For this solution, I’ve implemented a 3-tier architecture in AWS to ensure high availability, fault tolerance, scalability, and security. The architecture consists of a presentation layer, an application layer, and a database layer. It’s built within a single AWS region (Europe), leveraging two Availability Zones (AZs) for redundancy and better fault isolation.

At the foundation, I created a single Virtual Private Cloud (VPC) to isolate my network environment. Within each Availability Zone, I deployed one public subnet and one private subnet. The public subnets host my EC2 instances (application + presentation layer), while the private subnets host MySQL databases (database layer). This separation allows me to tightly control access to sensitive data resources.

To serve incoming web traffic efficiently, I used an Application Load Balancer (ALB). The ALB receives requests from client browsers and distributes them across EC2 instances in the public subnets. These EC2 instances are stateless, so they do not store session data locally. This allows me to take advantage of horizontal scaling through Auto Scaling Groups, which automatically add or remove instances based on demand—optimizing cost while maintaining performance.

In terms of routing, I created two route tables. The main route table is associated with the public subnets and includes a route to an Internet Gateway (IGW), which allows the EC2 instances to send and receive traffic from the internet. For the private subnets, I created a custom route table that does not include a route to the IGW, isolating the database layer from public internet access and ensuring only internal resources (like EC2) can reach the database.

To protect my infrastructure, I used security groups, which act as virtual firewalls. I created:

A security group for the EC2 instances, which allows inbound traffic on specific ports (e.g., 80 for HTTP, 22 for SSH) from the internet.

A security group for the MySQL database, which only allows inbound traffic on port 3306 from the EC2 instances’ security group—not from the internet or other sources.

This layered security ensures that only authorized traffic can reach the database and that the application layer is appropriately exposed to the internet. The public subnet for EC2 instances is necessary to allow internet access, but security groups restrict access to only what’s needed. The private subnet for the database provides a second level of protection by keeping it completely unreachable from the outside world.
