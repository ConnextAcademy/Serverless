import boto3
from botocore.exceptions import ClientError

s3 = boto3.resource('s3')


def file_exists(bucket: str, file_name: str) -> bool:
    try:
        s3.Object(bucket, file_name).load()
        return True
    except ClientError as e:
        print(f"Received exception: {e}")
        return False
