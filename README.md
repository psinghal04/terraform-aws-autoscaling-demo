# Autoscaling Demo on AWS

This repository contains a basic Terraform template to provision simple AWS infrastructure to test an AWS
Auto-Scaling Group (ASG) in action using a simple Target Tracking Scaling policy. The Terraform template will provision
the following resources:

* An Auto-Scaling Group (ASG) along with a launch template to spin up/spin down EC2 instances based on configured
  capacity and scaling requirements.
* An Application Load Balancer (ALB) to load balance incoming HTTP requests among the EC2 instances created by the
  autoscaling group.

Additionally, the Terraform template provisions the necessary security groups and supporting resources for the above.

## Pre-requisites

1. An AWS account. The AWS free tier is sufficient to run this demo.
2. A machine with the AWS CLI, Git and Terraform installed.

## Steps

1. Configure your AWS CLI. Execute the following command and follow the prompts.
   ```
   aws configure
   ```
2. Clone this repository locally.
3. Navigate to the root directory of the Terraform repo. Execute the following command
   ```
   terraform init
   ```
4. Dry run the Terraform template and review the generated plan. Verify it looks OK.
   ```
   terraform plan
   ```
5. Apply the Terraform template to create the AWS resources.
   ```
   terraform apply -auto-approve
   ```
6. Once the AWS resources are provisioned, log into the AWS console and verify that the Application Load Balancer (ALB)
   is created and available, and the minimum desired capacity of two EC2 instances are running and available. Enter the
   DNS name of the
   ALB in a browser and ensure you get a valid response back from the Web server from one of the EC2 instances.

7. Connect to one of the two EC2 instances using EC2 Instance Connect in the AWS Console.
8. Install and launch the stress tool on this EC2 instance
   ```
   sudo amazon-linux-extras install epel -y 
    
   sudo yum install -y stress

   stress --cpu 4 --timeout 300
   ```
9. In the AWS Console, Navigate to the Monitoring section of the EC2 instance where you initiated the stress test, and
   observe the CPU utilization. It should begin to go up.
10. In the AWS Console, navigate to the Auto-scaling Group that was created for the demo. Navigate to the Activity
    section, and observe the auto-scaling activity. It might take 5-10 minutes for the scaling operations to occur.
11. Once the Auto-scaling Group shows scaling activity, navigate to the EC2 instances section in the AWS console and
    confirm that one or more additional EC2 instances have been created and are running.
12. Once the stress test completes, the CPU utilization for the EC2 instance where the test was running will drop. This
    should trigger the Auto-scaling Group to spin down and remove the additional EC2 instance(s) created in response to
    the load. Observe the scale down activity in the Activity section of the Auto-scaling Group in the AWS Console.
    Verify that the number of EC2 instances comes back to the minimum capacity of 2 that was configured for the
    Auto-scaling group. The scale down activity might take an additional 5-10 minutes.
13. To clean up the demo and remove all AWS resources created for this demo, execute the following command from the root
    directory of the Terraform repo
    ```
    terraform destroy -auto-approve
    ```

