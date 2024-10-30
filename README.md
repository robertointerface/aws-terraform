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

1 - there are 3 vpcs in 3 different regions:<br>
- London region: Active region getting all the traffic 
- Ireland region: Stand-by region
- US-east-1 (North-Virginia): Region for Route 53 health check, cloudwatch alarm and SNS topic.

2- The rest api entry point is implemented using API-Getaway to take advantage of the features that API-Gateway gives you like 
authorization or easy integration with other services.

3- The rest-api itself is Deployed on a docker container and runs on Elastic Container Service (Fargate) where
an application load balancer distributes the incoming traffic, Note the Fargate cluster and Load balancer are
in private subnets. The rest-api is spread among 2 private subnets in different availability zones.

4- The rest-api is also duplicated in the Ireland region but on stand by.

5- Dynamodb: there is global dynamoDB cluster, with the write instance on the London region and a read replica on
the Ireland region, when the London region fails, the DynamoDB read replica on the Ireland region gets promoted to 
write instance.

6- Monitoring London region status: We use health checks to monitor the London region status, Note that health checks are
only available on the US-East-1 region.

7- To promote the dynamoDB read replica to primary cluster we use a lambda located in The ireland region, this
lambda is triggered by an SNS notification that comes when the health checks fail on US-east-1, Note that the 
SNS needs to be located on us-east-1 as the cloudwatch alarms is on the US-east-1.

8- Note that the code does not implement the DynamoDB databases, those need to be implemented separately, the primary
and secondary clusters.

![rest-api-fail-over-with-dynamodb-diagram.png](aws-diagrams/rest-api-fail-over-with-dynamodb-diagram.png)

