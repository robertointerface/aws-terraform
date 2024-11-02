# aws-terraform

## Introduction
Terraform recipies for multiple AWS architectural patterns. Repository is intended for  learning purposes and not for 
commercialization.

## Requirements
If anyone would like to try to deploy these recipies on their AWS accounts from their local devices, these 2 requirements
must be met. <br>
1 - Terraform-cli installed locally, https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
2 - aws-cli installed with aws credentials that are allowed to deploy components defined on terraform code.

## Applications

### simple-app-fail-over
Simple application that has a fail-over strategy, application is deployed on 2 aws regions (London and Ireland), 
route 53 directs all traffic to the London region BUT when the London region fails, the traffic is automatically 
redirected to the Ireland Region, look at the diagram below. <br>

![simple-app-fail-over-diagram](aws-diagrams/simple-app-fail-over-diagram.png))

The web application is very simple, it runs on EC2s that are managed by an auto-scaling group with a maximum of 3 instances
and a minimum of 2, the application just prints the aws region where the EC2 is located. Traffic enters by an Application
Load Balancer. The primary region is the London region, The traffic is directed to the London region as long as the Load 
Balancer is returning 200 response. Route 53 redirects traffic to Ireland region when the Load balancer at the London
region returns non 2xx response.

#### How to test the fail-over.
After you have deployed the application to both regions, you can see that the response comes from EC2s on eu-west-2a/eu-west-2b 
which are London Availability Zones, you can create a failure by simply changing the security group on the London region
for the Load balancer to NOT allow any income traffic, that will create a fail-over and after 3 to 5 minutes you can 
see that web app response is now coming from EC2s located at eu-west-1a/eu-west-2b which are from Ireland.


### Rest-api fail over with DynamoDB (rest-api-mongodb-failover)
Simple rest api fail over with fail over to another region, including dynamoDB fail over.

The terraform code is under [rest-api-mongodb-failover](rest-api-mongodb-failover)

The diagram below shows the architecture diagram:

![rest-api-fail-over-with-dynamodb-diagram.png](aws-diagrams/rest-api-fail-over-with-dynamodb-diagram.png)
#### Pre-requisites
1 - The VPCs/subnets are not created in the terraform code, actually the vpc-ids and the subnets ids must be provided
as input variables, previous running terraform plan or apply the user must.

    a - Create a vpc in 2 different regions, one London region (eu-west-2) and one in Ireland (eu-west-1).
    b - On each region create 3 public subnets and 3 private subnets
    c - 2 route tables, one for public and one for private, note the public must direct public traffic to an Internet Gateway
    and the private table must direct public traffic to a NAT gateway.
    d - A global DynamoDB cluster where the "primary" cluster is on the London region and the "secondary" cluster in on 
    the Ireland region, Note that the clusters Host
    e - An owned domain and this one must be managed by AWS route 53.

#### Architecture Explanation
1 - there are 3 vpcs in 3 different regions:
- London region: Active region getting all the traffic from Route 53.
- Ireland region: Stand-by region, warm-stand by.
- US-east-1 (North-Virginia): Region for Route 53 health check, cloudwatch alarm and SNS topic that triggers the Lambda.

2- The rest api entry point is implemented using API-Getaway to take advantage of the features that API-Gateway gives you like 
authorization, monitoring or easy integration with other services such as Application Load Balancers. 

3- The rest-api itself is Deployed on a docker container and runs on Elastic Container Service (Fargate) where
an application load balancer distributes the incoming traffic, Note the Fargate cluster and Load balancer are
in private subnets. The rest-api is spread among 2 private subnets in different availability zones on each region.

4- The rest-api is also duplicated in the Ireland region but on stand by.

5- Dynamodb: there is global dynamoDB cluster, with the Primary Cluster on the London region (the primary region is the
region that accepts read & write traffic, the "secondary" regions only accept "Read" traffic). A secondary Cluster is on
the Ireland region, when the London region fails, the DynamoDB Secondary Cluster on the Ireland region gets promoted to 
"Primary" status and therefore can accept read & write traffic.

6- Monitoring regions status: We use health checks to monitor the London & Ireland region status, we monitor if the api 
Gateway is returning 200s response, Note that health checks are Controlled only from the US-East-1 region, this is important.

7- To promote the dynamoDB secondary cluster (On Ireland) to primary cluster we use a lambda located in The Ireland region,
if the Lambda is located on the London region and the London region goes down, then the Lambda could not be triggered.

This lambda is triggered by an SNS (System Notification Service) notification that comes when the health checks fail on 
US-east-1, Note that the SNS needs to be located on us-east-1. A message is put on the SNS when the health check fails, 
when the health check fails, that triggers a Cloudwatch alarm, the Cloudwatch alarm puts a message on the SNS. 

Cloudwatch alarm and sns topic need to be on US-east-1, this is all because Health Checks are only controlled from US-East-1.
The Cloudwatch alarm that is created by the Health checks needs to be on the same region as the health check and AWS does
not allow to put a message on an SNS topic from another region, for example if we have an SNS topic on eu-west-1 (Ireland),
we can NOT put a message on that topic from region ap-southeast-1 (Singapore), BUT SNS subscribers can be on different
regions, for example a Lambda on ap-southeast-1 (Singapore) can be triggered by a SNS topic located at eu-west-1 (Ireland).

8- Note that the code does not implement the DynamoDB databases, those need to be implemented separately, the primary
and secondary clusters.



