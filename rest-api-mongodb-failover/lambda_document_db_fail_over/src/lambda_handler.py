import boto3


class DocumentDBFailOverException(Exception):
    pass


def lambda_handler(event, context):
    eu_west_2_client = boto3.client('rds', region_name='eu-west-2')
    global_cluster_identifier = "ecommerce-ireland-cluster"
    try:
        global_cluster = eu_west_2_client.describe_global_clusters(
            GlobalClusterIdentifier="ecommerce-ireland-cluster")
        global_cluster_member = global_cluster['GlobalClusters'][0]["GlobalClusterMembers"]
        readers = [cluster_member for cluster_member in global_cluster_member if not cluster_member["IsWriter"]]
        if not readers:
            raise DocumentDBFailOverException("No readers found")
        target_db_cluster_arn = readers[0]["DBClusterArn"]
        response = eu_west_2_client.failover_global_cluster(
            GlobalClusterIdentifier="ecommerce-ireland-cluster",
            TargetDbClusterIdentifier=target_db_cluster_arn,
            AllowDataLoss=True)
    except (eu_west_2_client.exceptions.GlobalClusterNotFoundFault,
            eu_west_2_client.exceptions.InvalidGlobalClusterStateFault,
            eu_west_2_client.exceptions.InvalidDBClusterStateFault,
            eu_west_2_client.exceptions.DBClusterNotFoundFault) as e:
        msg = (f"Could not perform fail-over on global cluster {global_cluster_identifier} to make the primary cluster "
               f" {target_db_cluster_arn}")
        raise DocumentDBFailOverException(msg) from e


if __name__ == "__main__":
    lambda_handler({}, {})
