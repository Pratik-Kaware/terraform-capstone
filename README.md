<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" class="logo" width="120"/>

## Professional README for: Complete Terraform AWS EC2 + RDS Setup for Beginners


---

# Complete Terraform AWS EC2 + RDS Setup for Beginners (100% Terraform)

A step-by-step, production-grade starter project to provision a secure, scalable AWS infrastructure using only Terraform. This template automates the creation of a VPC, public/private subnets, EC2 instance, and MySQL RDS database—ideal for learning, prototyping, or bootstrapping real-world cloud deployments.

---

## 🚀 Features

- **End-to-end AWS setup**: VPC, subnets, EC2, RDS (MySQL), security groups, and IAM roles
- **100% Infrastructure as Code**: No manual AWS console steps
- **Secure by default**: Random SSH keys and DB passwords, private subnets for RDS, secrets stored in AWS SSM
- **Free Tier eligible**: Uses t2.micro/db.t3.micro and 20GB storage
- **Reproducible and customizable**: All parameters and scripts easily adjustable

---

## 🛠️ Prerequisites

- **AWS Account** (free tier eligible)
- **AWS CLI** installed and configured
- **Terraform** installed (>= 1.0)

---

## 📁 Project Structure

```
terraform-aws-project/
├── main.tf              # Main infrastructure code
├── variables.tf         # Input variables
├── outputs.tf           # Key outputs after deployment
├── terraform.tfvars     # Your variable overrides
└── userdata.sh          # EC2 bootstrap script
```


---

## ⚡ Quick Start

1. **Clone the repo and enter the directory**

```bash
git clone <your-repo-url>
cd terraform-aws-project
```

2. **Configure AWS CLI**

```bash
aws configure
```

3. **Initialize and deploy**

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

4. **Confirm with `yes` when prompted**

---

## 🔑 What Gets Created

- **VPC** with public/private subnets (multi-AZ)
- **Internet Gateway** and route tables
- **EC2 Instance** (Amazon Linux 2, HTTP + SSH, auto-bootstrapped)
- **RDS MySQL Instance** (private subnets, secure password)
- **Security Groups** for EC2 and RDS
- **SSH Key Pair** (auto-generated, saved as `terraform-key.pem`)
- **Random DB password** (stored in AWS SSM Parameter Store)
- **Outputs**: EC2 public IP/DNS, RDS endpoint, SSH/database connection commands

---

## 🌐 Accessing Your Resources

- **Website:** Visit the `website_url` output in your browser.
- **SSH to EC2:**

```bash
ssh -i terraform-key.pem ec2-user@<EC2_PUBLIC_IP>
```

- **Get DB Password:**

```bash
aws ssm get-parameter --name "/my-terraform-project/database/password" --with-decryption --query Parameter.Value --output text
```

- **Connect to MySQL from EC2:**

```bash
mysql -h <RDS_ENDPOINT> -u admin -p
```


---

## 🧰 Customization

- Change `variables.tf` and `terraform.tfvars` to set your region, project name, and allowed SSH CIDRs.
- Modify `userdata.sh` to customize EC2 setup.

---

## 🛡️ Security \& Best Practices

- **No hardcoded secrets**: All credentials are generated and stored securely.
- **Private subnets for RDS**: Database is not publicly accessible.
- **SSH open by default**: Restrict with `allowed_cidr_blocks` for production.

---

## 🧹 Clean Up

To avoid AWS charges, destroy all resources when finished:

```bash
terraform destroy
```


---

## 📝 Troubleshooting

- **InvalidKeyPair.NotFound**: Handled automatically by Terraform.
- **UnauthorizedOperation**: Check your AWS credentials.
- **DBSubnetGroupDoesNotCoverEnoughAZs**: The template creates subnets in multiple AZs.

---

## 📊 Comparison: Manual vs. Terraform Approach

| Manual Setup | This Project (Terraform) |
| :-- | :-- |
| Manual key/password gen | ✅ Auto-generated \& secure |
| Manual AMI lookup | ✅ Always uses latest |
| Manual subnet config | ✅ Multi-AZ, best practices |
| Risk of missed steps | ✅ Fully reproducible |


---

## 📚 References

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Free Tier](https://aws.amazon.com/free/)

---

## 🙏 Credits

Inspired by best practices in cloud automation and open-source DevOps communities.

---

**Start deploying modern AWS infrastructure—securely, repeatably, and with zero manual steps!**
[See full code and instructions above for details.][^1]

<div style="text-align: center">⁂</div>

[^1]: paste.txt

