# terraform-aws-autoscaling-demo

# Generating CPU stress on one of the EC2 instances
sudo amazon-linux-extras install epel -y  
sudo yum install -y stress

stress --cpu 4 --timeout 300