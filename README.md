# altschool-december-nginx-challenge
A task to deploy a program that displays the hostname or ip of the server, using Nginx, on 2(+) private servers in the private subnet(s) of a Logical Network, behind a Load Balancer, attached to an Auto Scaling Group.
### deploy-node-app.sh
- Bash script to deploy my nodejs program
- Runs as User data, too
### package.json, server.js
- Deployed program
### eaaladejana.live
- Nginx configuration
### deploy-node-app-x.me.sh, eaaladejana.me
- Files for alternate domain "eaaladejana.me"
### AWS Infrastructure
- The infrastructure for this project was setup using the AWS console, Once familiar with Terraform or IaC(Infrastructure as Code) I'll update the repo with how to setup with that.
- **AWS Resources used:**
  - **VPC:** Your VPCs, Subnets, Internet gateways, Route tables, NAT Gateways
  - **EC2**: Instances, Load Balancers, Target Groups, AMIs, Launch Templates, Elastic IPs, Auto Scaling Groups, Security Groups
  - **Route 53**: Hosted Zones, AWS Certificate
  - **Certificate Manager**
### Procedures **(screenshots are below)**
- **Set up VPC Manually**
  - Create VPC
  - VPC only
  - IPv4 CIDR manual input
  - IPv4 CIDR - 10.0.0.0/16
  - Tenancy - default
- **Subnets**
  - Create Subnets
  - Associate VPC
  - Create both public and private subnets in different zones for more availability
- **Internet gateways**
  - Create Internet gateway
  - Name gateway and create
  - Attach gateway to VPC
- **Route tables**
  - Create two Route tables, one for public subnet one for private subnet
  - Edit the Route table for the public subnet to add new route attaching the internet gateway to allow from everywhere
  - Associate the public route table with the public subnets in VPC
- **NAT gateways**
  - Create NAT gateway
  - Select a public subnet in your VPC attached to the IGW
  - Allocate Elastic IP
  - Create NAT
- **Route tables - Again**
  - Select private route table
  - Confirm the subnet association
  - Go to Routes
  - Edit Routes
  - Attach NAT gateway, Destination -> 0.0.0.0/0 (the whole internet)
- **Instances**
  - Launch instances
  - Name instance
  - Select image (ubuntu 20.04 LTS, free tier)
  - Select instance type (t2.micro, free tier)
  - Select key pair
  - Select Private subnet of VPC and disable public ip
  - Select suitable security group (a section for this is provided below), for now allow -> HTTP, HTTPS, SSH
  - Create an instance in the public subnet of VPC as bastion host
- **Deploy Nodejs App**
  - **Option 1:** Copy and run deploy-node-app.sh as user data
  - **Option 2:** Connect to Bastion host, from there connect to private instance, copy, create and run the deploy-node-app.sh script with `./deploy-node-app.sh` 
  - **Option 3:** Option 2 but commands in "deploy-node-app" being run manually
- **Setup Load Balancer**
  - Create Application Load Balancer
  - Internet facing
  - Create Security Group for Load Balancer (LB)
  - Set inbound rules to allow HTTP and HTTPS (from anywhere)
  - Create HTTP:80 listener
  - Create Target Group
  - Register private instance in Target Group
  - Map Load Balancer with public subnet (Internet gateway attached) in VPC
- **Security Groups**
  - Set LB's Security Group to only accept HTTP and HTTPS, from anywhere
  - Set instance Security Group to allow SSH
  - Set instance Security Group to only accept HTTP and HTTPS traffic from LB's Security Group
- **AMI**
  - Create an AMI of your ready private instance and use to create a Launch Template for your Auto Scaling Group
  - Enter image name and description and create
- **Launch Templates**
  - Create Launch Template
  - For Application and OS images
  - Instance type t2.micro
  - Specify Subnets when creating the Auto Scaling Group
- **Auto Scaling Groups**
  - Create Auto Scaling Group
  - Select created Launch Template
  - Select VPC, select Subnets and Availability zones
  - Attach to Load Balancer
  - Select your Target Group
  - Set Minumun, Desired and Maximum Capacity
  - Set scaling policies (optional)
  - Create Auto Scaling Group
  - Attach already created private instance to Auto Scaling Group 
- **Route 53**
  - Create Hosted Zone with domain
  - Select the Hosted Zone
  - Create an Alias A record "A - Routes traffic to an IPV4 and some AWS resources"
  - Route traffic to "Alias to Network Load Balancer"
  - Choose region (the region that has your VPC and resources)
  - Simple routing
  - For root domain leave the subdomain blank
  - Add another record for the "www" subdomain
  - create records
- **Nameservers**
  - Add the links to AWS nameservers on your domain dashboard with your domain provider
- **Load Balancers - Again**
  - Select the Load Balancer
  - Add Listener
  - Listener details -> Protocol HTTPS
  - Action -> Forward
  - Forward to Target Group
  - Request new ACM Certificate (free)
  - Select the Certficate pending validation and create the record required for the validation
  - Wait for it to be delivered then select the Certificate
  - Add the Listener
  - Edit the HTTP:80 Listener
  - Delete Forward action and add a new Redirect action to -> port 443
  - Save changes
- **Check to see if the Domain works. Test Domain, and Load Balancer distribution(by reloading), The Load Balancer should switch between the different servers with their IPs indicating that** 
### Screenshots of the resources created
<pre>

</pre>
- **VPC**
![VPC](./images/VPC.png)
<pre>

</pre>
- **Subnets**
![subnets](./images/subnets.png)
<pre>

</pre>
- **Internet gateways**
![IGW](./images/IGW.png)
<pre>

</pre>
- **Route tables**
  - Route table for public subnet
![public Route table](./images/PubRT.png)
  - Route table for private subnet
![private Route table](./images/PrivRT.png)
<pre>

</pre>
- **Instances**
  - Private instance 1
![nginx-wbs-1](./images/nginx-wbs-1.png)
  - Private instance 2
![nginx-wbs-2](./images/nginx-wbs-2.png)
  - Private instance 3
![nginx-wbs-3](./images/nginx-wbs-3.png)
  - Bastion host
![Bastion host](./images/VPC.png)
<pre>

</pre>
- **Load Balancer**
![LB](./images/LB.png)
<pre>

</pre>
- **Security Groups**
  - Security group for private instances
![SG-instance](./images/SG-instance.png)
  - Security group for load balancer
![SG-LB](./images/SG-LB.png)
<pre>

</pre>
- **AMI**
![AMI](./images/AMI.png)
<pre>

</pre>
- **Launch Templates**
![LT](./images/LT.png)
<pre>

</pre>
- **Auto Scaling Groups**
![ASG](./images/ASG.png)
<pre>

</pre>
- **Route 53**
![Route 53](./images/Route-53.png)
### Demo
- **server 1**
![server-1](./images/demo_1.jpg)
- **server 2**
![server-2](./images/demo_2.jpg)
- **server 3**
![server-3](./images/demo_3.jpg)


