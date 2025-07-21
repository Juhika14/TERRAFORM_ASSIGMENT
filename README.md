# AWS VPC + Network Firewall (Terraform)

## 🚀 Project Overview

This Terraform-based project provisions a secure AWS network with the following components:

1. **VPC** spanning 3 AZs  
2. **3 public subnets** (one per AZ)  
3. **3 private subnets** (one per AZ)  
4. **Internet Gateway** attached to the public subnets  
5. **NAT Gateway** in one public subnet for private subnet egress  
6. **AWS Network Firewall** deployed across private subnets, with:
   - **Stateless rule**: allows outbound HTTP (port 80) and HTTPS (port 443)
   - **Stateful rule**: blocks outbound traffic to `198.51.100.1`
7. **Consistent tagging** (`Name`, `Environment`) on all resources  

**Configuration**: Region, AZs, and CIDR ranges are fully parameterized via Terraform variables—no hardcoding.  
**Deployment**: Run `terraform apply` once to provision all resources.

---


## ⚙️ Prerequisites

- Terraform **v1.4+**
- AWS credentials set up via one of:
  - `~/.aws/credentials`
  - `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables

---

## 📦 Deployment Steps

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/terraform_assignment.git
   cd terraform_assignment

Initialize Terraform and install providers:

terraform init
(Optional) Validate your configuration:

terraform validate
terraform plan


Apply the configuration:

terraform apply -auto-approve  //This single command builds the complete setup:

Creates the VPC, subnets, IGW, NAT, firewall, and rule groups

Tags each resource accordingly

🧩 Configuration Variables
Defined in variables.tf. Here are the key ones:

Variable	Description	Default
aws_region	AWS Region for deployment	us-east-2
azs	List of 3 Availability Zones	["us-east-2a","us-east-2b","us-east-2c"]
vpc_cidr	VPC CIDR block	10.0.0.0/16
public_cidrs	Public subnet CIDRs	["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
private_cidrs	Private subnet CIDRs	["10.0.11.0/24","10.0.12.0/24","10.0.13.0/24"]
blocked_ip	IP blocked by firewall	198.51.100.1/32
environment	Tag value for environment	dev


** 
 Testing & Verification**
Launched an EC2 instance in a private subnet (no public IP) using:

Session Manager (SSM), or

A bastion host in a public subnet

Inside the instance, verified connectivity:

# Test case got succeed: HTTP/HTTPS allowed
curl -I http://example.com

# Test case got failed: blocked HTTP access
curl -I http://198.51.100.1
(Optional) Check Network Firewall logs in CloudWatch:

Flow logs confirm outbound traffic

Alert logs capture blocked traffic

This validates that your firewall rules and NAT routing are functioning correctly.

 
 **Design Decisions**
Single NAT Gateway: Chosen for simplicity and cost-efficiency. Offers egress but not high availability.

**Firewall Architecture:**

Stateless rules first allow only HTTP/HTTPS

Stateful rule blocks specific IP, ensuring no accidental access

Subnet structure ensures public resources can access the internet, while private resources are protected

Tagging strategy (Name, Environment) enhances resource discoverability and cost allocation

**Assumptions & Limitations**
> NAT Gateway is not deployed in every AZ—this is not HA.

> Firewall logging is disabled by default; can be enabled with minor config changes.

> Terraform state is stored locally; production environments should use remote state (S3 + DynamoDB).

****Future Enhancements
> We can enable CloudWatch/Kinesis logging for Network Firewall

>We can add multiple NAT Gateways (one per AZ) for high availability

>We can mplement remote state backend

>We can integrate CI/CD with linter and audit tools (e.g., pre-commit, tfsec, tflint)

>Expand firewall policy for domain-based filtering or stricter rules

