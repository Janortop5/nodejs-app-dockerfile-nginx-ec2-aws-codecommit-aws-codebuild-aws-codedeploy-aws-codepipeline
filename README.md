# Step-by-Step Instructions
#### 1. Set up the AWS CodeCommit Repository
1. Create a Repository in AWS CodeCommit:<br>
○ Go to the AWS Management Console.<br>
○ Navigate to CodeCommit under Developer Tools.<br>
○ Click on Create Repository.<br>
○ Enter a repository name (e.g., my-nodejs-app).<br>
○ Click Create.


2. Clone the Repository Locally:

○ Clone the repository to your local machine.<br>
sh<br>
Copy code
```
git clone
https://git-codecommit.us-east-1.amazonaws.com/v1/repos/endowdAfricaCodeCommit
cd endowdAfricaCodeCommit
```


3. Push Your Node.js Application Code:

○ Add your Node.js application code to the repository.<br>
○ Commit and push the code to CodeCommit.<br>
sh<br>
Copy code
```
git add .
git commit -m "Initial commit"
git push origin master
```

#### 2. Set up AWS CodeBuild
1. Create a Build Project in AWS CodeBuild:<br>
○ Go to the AWS Management Console.<br>
○ Navigate to CodeBuild under Developer Tools.<br>
○ Click on Create build project.<br>
○ Enter a project name (e.g., my-nodejs-app-build).<br>
○ Under Source, choose AWS CodeCommit and select your repository.<br>
○ Under Environment, choose a Managed image and select Ubuntu and
Standard runtime.<br>
○ Choose Privileged to enable Docker support.<br>
○ Under Buildspec, choose Use a buildspec file and enter the location of your
buildspec.yml file (e.g., buildspec.yml).<br><br>
2. Create buildspec.yml File:

○ In your local repository, create a buildspec.yml file with the following content:
yaml
Copy code
```
version: 0.2

phases:
  pre_build:
    commands:
      - python secret_manager.py

  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...
      - docker build -t endowdafrica:latest .
      - docker tag endowdafrica:latest 767397895765.dkr.ecr.us-east-1.amazonaws.com/endowdafrica_05:latest

  post_build:
    commands:
      - echo Build completed on `date`
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 767397895765.dkr.ecr.us-east-1.amazonaws.com
      - echo Pushing the Docker image...
      - docker push 767397895765.dkr.ecr.us-east-1.amazonaws.com/endowdafrica_05:latest
      - echo Writing image definitions file...
      - printf '[{"name":"container-name","imageUri":"%s"}]' 767397895765.dkr.ecr.us-east-1.amazonaws.com/endowdafrica_05:latest > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
    - appspec.yml
    - deploy/install_dependencies.sh
    - deploy/start_application.sh
```
3. Login to Dockerhub with secret_manager.py (improve rate limiting):<br>
○  Store your docker_details secrets in AWS Secrets Manager<br>
○ Create an IAM role for CodePipeline.<br>
○ Update your CodePipeline to use the secret. <br>
○ Create secret_manager.py file. <br>

secret_manager.py<br>
Copy code
```
import boto3
from botocore.exceptions import ClientError
import json
import os
import subprocess

def get_secret():

    secret_name = "docker_details"
    region_name = "us-east-1"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        # For a list of exceptions thrown, see
        # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        raise e

    secret = get_secret_value_response['SecretString']

    return json.loads(secret)

    # Your code goes here.

def main():
    try:
        # Get the secret
        secret_dict = get_secret()

        # Export secrets as environment variables
        for key, value in secret_dict.items():
            os.environ[key] = value

        print("Secrets exported as environment variables")

        # Check if Docker credentials are available
        if 'docker_username' in secret_dict and 'docker_password' in secret_dict:
            print("Docker credentials found. Attempting to log in...")

            # Use subprocess to run the docker login command
            try:
                result = subprocess.run(
                    ["docker", "login",
                     "-u", secret_dict['docker_username'],
                     "-p", secret_dict['docker_password']],
                    check=True,
                    capture_output=True,
                    text=True
                )
                print("Docker login successful")
            except subprocess.CalledProcessError as e:
                print(f"Docker login failed: {e.stderr}")
                raise
        else:
            print("Docker credentials not found in the secret")

        # Add any additional steps that require Docker access here

    except Exception as e:
        print(f"An error occurred: {e}")
        raise e

if __name__ == "__main__":
    main()
```
#### 3. Set up AWS CodeDeploy
1. Create an Application in AWS CodeDeploy:<br>
○ Go to the AWS Management Console.<br>
○ Navigate to CodeDeploy under Developer Tools.<br>
○ Click on Create application.<br>
○ Enter an application name (e.g., my-nodejs-app-deploy).<br>
○ Select EC2/On-Premises as the compute platform.<br>

2. Create a Deployment Group:<br>
○ In the CodeDeploy application, click on Create Deployment Group.<br>
○ Enter a deployment group name (e.g., my-nodejs-app-deployment-group).<br>
○ Select the EC2 instances to which you want to deploy your application.<br>
○ Choose Amazon EC2 Auto Scaling groups or Amazon EC2 instances as per
    your setup.<br>
○ Set up the service role and deployment settings.<br>

3. Create appspec.yml File:
○ In your local repository, create an appspec.yml file with the following content:
yaml
Copy code
```
version: 0.0
os: linux
files:
  - source: /imagedefinitions.json
    destination: /opt/codedeploy-agent/deployment-root/
hooks:
  AfterInstall:
    - location: deploy/install_dependencies.sh
      timeout: 300
      runas: root
  ApplicationStart:
    - location: deploy/start_application.sh
      timeout: 300
      runas: root
```

4. Create Deployment Scripts:
○ In your local repository, create the following scripts:<br>
scripts/install_dependencies.sh:<br>
sh<br>
Copy code
```
#!/usr/bin/bash

ECR_URI=$(jq -r '.[0].imageUri' /opt/codedeploy-agent/deployment-root/imagedefinitions.json)

# Install Docker if not already installed
if ! [ -x "$(command -v docker)" ]; then
    echo 'Installing Docker...' >&2
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    # Create docker group if it doesn't exist
    if ! getent group docker > /dev/null; then
        sudo groupadd docker
    fi
    sudo usermod -aG docker $USER
    # Start and enable Docker service
    systemctl start docker
    systemctl enable docker
fi

sudo usermod -aG docker $USER

# Authenticate Docker with ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 767397895765.dkr.ecr.us-east-1.amazonaws.com

# Pull the latest image
# The ECR_URI environment variable should be set in the CodeDeploy deployment configuration
if [ -z "$ECR_URI" ]; then
    echo "Error: ECR_URI is not set. Cannot pull the image." >&2
    exit 1
fi

docker pull $ECR_URI
```
○ In your local repository, create the following scripts:
scripts/start_application.sh:<br>
sh<br>
Copy code<br>
```
#!/bin/bash

ECR_URI=$(jq -r '.[0].imageUri' /opt/codedeploy-agent/deployment-root/imagedefinitions.json)

# Stop any running containers
docker stop $(docker ps -a -q) || true
docker rm $(docker ps -a -q) || true

# Run the new container
# The ECR_URI environment variable should be set in the CodeDeploy deployment configuration
if [ -z "$ECR_URI" ]; then
    echo "Error: ECR_URI is not set. Cannot start the container." >&2
    exit 1
fi

docker run -d -p 3000:3000 $ECR_URI
```


#### 4. Set up AWS CodePipeline
1. Create a Pipeline in AWS CodePipeline:<br>
○ Go to the AWS Management Console.<br>
○ Navigate to CodePipeline under Developer Tools.<br>
○ Click on Create pipeline.<br>
○ Enter a pipeline name (e.g., endowdAfricaCodePipeline).<br>
○ Choose an existing service role or create a new one.<br>

2. Add Source Stage:<br>
○ In the Source stage, choose AWS CodeCommit as the source provider.<br>
○ Select your repository and branch (e.g., master).

3. Add Build Stage:<br>
○ In the Build stage, choose AWS CodeBuild as the build provider.<br>
○ Select the build project you created earlier.<br>

4. Add Deploy Stage:<br>
○ In the Deploy stage, choose AWS CodeDeploy as the deploy provider.<br>
○ Select the application and deployment group you created earlier.<br>

#### 5. Confugure EC2 Instance

1. Launch an EC2 Instance:<br>
○ Go to the AWS Management Console.<br>
○ Navigate to EC2 under Compute.<br>
○ Launch a new instance with an Ubuntu LTS<br>
○ Choose an instance type (e.g., t2.micro).<br>
○ Configure the instance with necessary security groups and key pairs.

2. Install Docker and nginx:<br>
○ SSH into your EC2 instance.<br>
Install Docker:<br>
sh<br>
Copy code
```
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo docker run hello-world
```
3. Install and setup Codedeploy-agent on ec2 instance with ansible:<br>
○ Ansible Role created:<br>
ansible/role/codedeploy_agent/tasks/main.yml<br>
yaml<br>
Copy code<br>
sh
```
---
- name: Install and Enable CodeDeploy Agent
  become: yes
  block:
    - name: Update apt cache
      apt:
        update_cache: yes

    - name: Install required packages
      apt:
        name:
          - ruby-full
          - wget
        state: present

    - name: Download CodeDeploy agent installation script
      get_url:
        url: https://aws-codedeploy-{{ aws_region }}.s3.amazonaws.com/latest/install
        dest: /tmp/codedeploy-install
        mode: '0755'

    - name: Install CodeDeploy agent
      command: /tmp/codedeploy-install auto
      args:
        creates: /opt/codedeploy-agent/bin/codedeploy-agent

    - name: Enable and start CodeDeploy agent
      systemd:
        name: codedeploy-agent
        state: started
        enabled: yes
        daemon_reload: yes

    - name: Clean up installation script
      file:
        path: /tmp/codedeploy-install
        state: absent

    - name: Verify CodeDeploy agent is running
      command: systemctl is-active codedeploy-agent
      register: codedeploy_status
      changed_when: false
      failed_when: codedeploy_status.rc != 0

    - name: Display CodeDeploy agent status
      debug:
        msg: "CodeDeploy agent is {{ codedeploy_status.stdout }}"
```
○ ansible/role/codedeploy_agent/vars/codedeploy.yml<br>
○ ansible-playbook
Copy code<br>
```
---
aws_region: "us-east-1"
```
○ ansible/setup_codedeploy_agent.yml
ansible-playbook
Copy code
```
---
- name: Setup code deploy agent on ubuntu
  hosts: web_servers
  remote_user: ubuntu
  become: yes
  vars_files:
  - vars/codedeploy.yml

  roles:
  - codedeploy_agent
```
○ ansible/hosts
Copy code
```
[web_servers]
3.84.223.10 ansible_user=ubuntu
```
○ Run Ansible playbook
ansible/setup_codedeploy_agent
ansible/yaml
Copy code
```
ansible-playbook -i hosts setup_codedeploy_agent
```
4. Configure Nginx as a Reverse Proxy:<br>
○ Install nginx:<br>
Sh<br>
Copy code
```
sudo apt install nginx
sudo service nginx start
```
○ Edit the nginx configuration file:
sh
Copy code
```
sudo vi /etc/nginx/sites-available/reverse_proxy.conf
```
○ Add the following server block:
Configuration
Copy code
```
server {
    listen 80;
    server_name node.eaaladejana.xyz; 

    location / {
        proxy_pass http://3.84.223.10:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```
○ Enable configuration:<br>
sh<br>
Copy code
```
sudo ln -s /etc/nginx/sites-available/reverse_proxy /etc/nginx/sites-enabled/
```
○ Test nginx configuration<br>
sh<br>
Copy code
```
sudo nginx -t
```
○ Restart nginx:<br>
sh<br>
Copy code
```
sudo service nginx restart
```

#### 6. Set up Domain and DNS
1. Register a Free Subdomain:<br>
○ Choose a domain provider (e.g., namedotcom)<br>
○ Register a free subdomain (e.g.,eaaladejana.xyz)<br>

2. Configure DNS Settings: <br>
○ Go to your route53 and create an hosted zone for ‘eaaladejana.xyz’ <br>
○ Create an A record pointing to the public IP address of your EC2 instance. <br>

○ Example DNS settings: <br>
vbnet <br>
Record Configuration:<br>
Host: node<br>
Type: A <br>
Value: <br>
TTL: 300
IP: 3.84.223.10

# Successful Pipeline
![pipeline successful](images/pipeline_successful_1)

![pipeline successful](images/pipeline_successful_2)



