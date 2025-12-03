## Architecture
This project deploys Airbyte on Amazon EKS in a secure, production-style network design. 
### VPC
- 3× **public subnets** and 3× **private subnets** across 3 AZs
- Public subnets host load balancers and bastion host
- Private subnets host EKS worker nodes and RDS instances

![01_architecture.png](images/01_architecture.png)
- Note: can also refer to my old exercise which explains the similar architecture set up.
  (https://github.com/chanchanngann/data-streaming-on-eks/blob/main/README.md)

---
### EKS Cluster
##### Control Plane
- Fully managed by AWS and reachable through a **public endpoint** for development convenience
- **Private endpoint** enabled so worker nodes communicate over internal VPC network
- In production, API access would typically be restricted to Bastion/VPN users

![controlplane](images/02_controlplane.png)
*diagram to visualise my understanding.*
##### Worker Nodes (AWS Managed Node Group)
- EC2 instances deployed in private subnets
- Outbound internet access via NAT Gateway
- No direct inbound exposure
##### Networking
- Nodes communicate with the control plane via private endpoint
- Applications exposed to the internet through ALB Ingress (for dev setup)
- Internal communication remains isolated inside private subnets
##### EKS Access Entries
- EKS access entries is used to grant users access to the Kubernetes API. The older way was using `aws-auth` ConfigMap which is now deprecated.
- You can use EKS Access Policies to define fine-grained cluster access - what actions the IAM principal (user/role) can take within the cluster. Access Policies is Kubernetes RBAC-like but managed through IAM. You assign access policies to the access entry, the access entry’s IAM principal can then perform the permitted actions within the cluster.
##### IAM Roles for Service Accounts (IRSA)
- We need to enable **IAM roles for service accounts (IRSA)** to link up service account in k8s with IAM role in AWS. Then by configuring the pods to use the service account, the pods act like the aws resources which could assume IAM role to perform actions in AWS.
- IRSA to be created: 
	- IRSA for EBS CSI Driver
	- IRSA for Load Balancer Controller
	- IRSA for Airbyte: Airbyte needs permissions to access S3, Glue
##### Security Groups
- **Cluster security group** - control traffic between nodes & control plane
- **Node security group** - control traffic between nodes & control plane, nodes & nodes, nodes & load balancers
- The Terraform EKS module automatically creates the SGs and applies default inbound/outbound rules. We can manually provide our own SGs but let's just stick to the existing setting first.
- RDS SG restricts DB access only to Bastion and EKS nodes
##### Ingress - AWS Load Balancer Controller
- The Load Balancer Controller (LBC) creates ALB (Application Load Balancer) when you create a k8s ingress object. 
- The ALB forwards traffic to pods through target groups.
- You can attach security group to ingress using annotations. 
- Airbyte UI exposed through HTTPS (using ACM certificate) via internet-facing ALB for development
- In production, ALB would typically be internal-only
##### Storage
- EBS CSI Driver is optional here because in this exercise Airbyte does not use Kubernetes PersistentVolumes.
- Instead, S3 is used both for Airbyte logs and for storing Iceberg tables produced by CDC syncs.
- External RDS Postgres as Airbyte Config DB: a persistent metadata store for connection settings, connector definitions, sync state, job history, etc. A dedicated **RDS Postgres** instance is used instead of a pod-level Postgres, improving durability and reliability.

---
### Airbyte on EKS

Key decisions:
##### Node selector
- Use nodeSelector to schedule Airbyte pods onto specific nodes.
- 2 node groups are created in EKS: with node labels "airbyte_node_type" = "core" and "airbyte_node_type" = "worker".
##### Pods allocation
- Worker pods: sync jobs which need more resources
- Core pods: services that run the platform (webapp, webserver, cron, temporal, ...etc.). These pods require lower resources to operate.
##### Accessing Airbyte
- For dev setup, I am going to deploy Airbyte on EKS with an internet-facing ALB in public subnets and HTTPS termination using ACM. Thus, Airbyte is accessible via HTTPS.
- In production, I would place ALB in private subnets and restrict access through VPN/PrivateLink.
##### IRSA for Airbyte pods
Airbyte service account bound to IAM role that allows:
- Airbyte pods to access S3 objects
- AWS Glue catalog operations
##### Deploy Airbyte via Helm Chart V2
- Airbyte has introduced Helm chart V2 which is an upgraded version. I will use V2 in this exercise.
  ref: https://docs.airbyte.com/platform/deploying-airbyte/chart-v2-community

---
### RDS (Postgres)

##### 2 RDS Postgres instances
- Creates
	- Airbyte internal metadata DB 
	- CDC source database for replication
- Both placed in private subnets.
##### Access patterns
- we need to set up Bastion host to query the DB.
- Can use SSH tunneling to access the DB via local DB client.
```ruby
Laptop laptop (DB client) → SSH (22) → Bastion → RDS Postgres (5432)
```
##### RDS Security Group
  - Allows inbound traffic only from Bastion host SG + EKS Node SG (Airbyte pods)
  - No direct access from local IP
```
- For RDS security group, do I need to allow ingress from my laptop?
From the RDS perspective, the traffic comes from the Bastion (not from local laptop directly). We don't need to allow ingress from the laptop.
```
##### Logical decoding enabled
- RDS parameters setting
```ruby
rds.logical_replication = 1
max_replication_slots = 5 (at least 1, default 5)
max_wal_senders = 1 (at least 1, default 1)
max_slot_wal_keep_size = 4096
```
- Publication created for CDC
- Airbyte creates its own replication slot

Note:
For the Temporal service, we need to configure the database to **not force SSL connections**. Otherwise, deployment fails at the creation of the Temporal DB.
ref https://medium.com/@kelvingakuo/self-hosting-airbyte-oss-on-aws-elastic-kubernetes-service-c74eb0bdb42d#4f21

---
### Bastion Host
We need bastion host to access the private RDSs.

- Deployed in public subnet 
- Allow ingress from local laptop IP at port 22 (SSH). You can check the local IP:
```ruby
curl https://checkip.amazonaws.com
```
- Used for Postgres administration, CDC configuration, and tunneling
- To access the Bastion host, we need to get its public IP from terraform output or via AWS console