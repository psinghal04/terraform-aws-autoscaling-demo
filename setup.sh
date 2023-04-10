#!/bin/bash
yum update -y
yum install -y httpd
yum install -y wget
cd /var/www/html
echo -n "<html><body><h1>Hello World, I am server $(hostname -f) in the AWS auto-scaling demo.</h1></body></html>" > index.html
service httpd start