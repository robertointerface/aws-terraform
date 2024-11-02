import boto3


class DocumentDBFailOverException(Exception):
    pass


def lambda_handler(event, context):
    """
    Get the DocumentDB list of secondary Clusters, promote one of the secondary clusters to Primary cluster so it
    can accept write & read traffic
    """
    eu_west_2_boto_client = boto3.client('rds', region_name='eu-west-2')
    global_cluster_identifier = "ecommerce-ireland-cluster"
    try:
        documentdb_global_cluster = eu_west_2_boto_client.describe_global_clusters(
            GlobalClusterIdentifier="ecommerce-ireland-cluster")
        global_cluster_member = documentdb_global_cluster['GlobalClusters'][0]["GlobalClusterMembers"]
        document_db_secondary_clusters = [
            cluster_member for cluster_member in global_cluster_member if not cluster_member["IsWriter"]]
        secondary_clusters_have_been_found = len(document_db_secondary_clusters) > 0
        if not secondary_clusters_have_been_found:
            raise DocumentDBFailOverException("No readers found")
        new_primary_cluster_arn = document_db_secondary_clusters[0]["DBClusterArn"]
        _ = eu_west_2_boto_client.failover_global_cluster(
            GlobalClusterIdentifier="ecommerce-ireland-cluster",
            TargetDbClusterIdentifier=new_primary_cluster_arn,
            AllowDataLoss=True)
    except (eu_west_2_boto_client.exceptions.GlobalClusterNotFoundFault,
            eu_west_2_boto_client.exceptions.InvalidGlobalClusterStateFault,
            eu_west_2_boto_client.exceptions.InvalidDBClusterStateFault,
            eu_west_2_boto_client.exceptions.DBClusterNotFoundFault) as e:
        msg = (f"Could not perform fail-over on global cluster {global_cluster_identifier} to make the primary cluster "
               f" {new_primary_cluster_arn}")
        raise DocumentDBFailOverException(msg) from e
