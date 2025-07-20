# AWS VPC + Network Firewall (Terraform)

 Overview
This Terraform configuration provisions a secure AWS environment spanning **3 Availability Zones** with the following architecture:

1. A **VPC** across 3 AZs
2. **3 public subnets** (one per AZ)
3. **3 private subnets** (one per AZ)
4. **Internet Gateway** for public subnet internet access
5. **NAT Gateway** to allow private subnets outbound internet access
6. **AWS Network Firewall** deployed in private subnet(s) with:
   - A **stateless rule** permitting HTTP/HTTPS egress
   - A **stateful rule** blocking egress to a specific IP (`198.51.100.1`)
7. All resources are **tagged** with `Name` and `Environment` for clarity.

The configuration is fully **parameterized** via Terraform variables. A single command (`terraform apply`) provisions everything.

---

##  Prerequisites

- Terraform **v1.4+**
- AWS credentials configured via:
  - `~/.aws/credentials`, **or**
  - environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)


---

## 🔧 Deployment Instructions

1. Clone the repo:
   ```bash
   git clone https://github.com/Juhika14/terraform_assignment.git
   cd terraform_assignment
Initialize Terraform:

terraform init

Review the execution plan:


terraform apply -auto-approve


🌐 Configurable Variables (variables.tf)

Variable	Description	Default Value
aws_region	AWS deployment region	us-east-2
azs	List of 3 Availability Zones	["us-east-2a","us-east-2b","us-east-2c"]
vpc_cidr	VPC IP CIDR block	10.0.0.0/16
public_cidrs	Public subnet CIDRs (1 per AZ)	["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
private_cidrs	Private subnet CIDRs (1 per AZ)	["10.0.11.0/24","10.0.12.0/24","10.0.13.0/24"]
blocked_ip	IP to block via stateful rule	198.51.100.1
environment	Tag value for intuitiveness	dev

These can be overridden with a terraform.tfvars file.

🔍 Testing the Setup
Launch an EC2 instance in a private subnet (no public IP). Connect via Session Manager (SSM) or a bastion host.

From the EC2 instance, run:

curl -I http://example.com     # ✅ should succeed (HTTP egress allowed)
curl -I http://198.51.100.1    # ❌ should timeout or fail (stateful firewall blocks)
(Optional) Enable Flow and Alert logs for Network Firewall in CloudWatch to monitor traffic and verify rule effectiveness.

💡 Design Decisions
Single NAT Gateway deployed in the first public subnet—cost-effective, but not highly available.

Firewall Ordering: Stateless rules allow HTTP/HTTPS before stateful rules block traffic to disallowed IP.

Tagging: All resources include Name and Environment tags for easier tracking and cost management.

Variable-driven configuration ensures flexibility and reusability (Spacelift best practices).

⚠️ Assumptions & Limitations
NAT Gateway isn’t deployed in every AZ—single-point failure is possible.

Logging for Network Firewall isn’t enabled by default (can be added later).

Terraform state is local; consider remote state backend (like S3 + DynamoDB) for production environments.

🛠️ Future Enhancements
Enable CloudWatch or Kinesis logging for the firewall

Deploy multiple NAT Gateways for HA

Switch to remote state with proper locking

Integrate CI/CD pipeline with static analysis tools (e.g., tflint, tfsec)

Extend firewall policy with domain filtering (HTTPS/SNI inspection)

