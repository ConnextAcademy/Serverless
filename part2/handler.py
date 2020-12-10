import json
from os import getenv
from util import file_exists


def handle(event: dict, context: dict) -> dict:
    print(f"Received event: {json.dumps(event)}")

    bucket_name = getenv("BUCKET")
    file_name = event["body"] if "body" in event else "-missing-"

    found = "" if file_exists(bucket_name, file_name) else "NOT "

    return {
        "statusCode": 200,
        "body": json.dumps(f"File {file_name} has {found}been found in {bucket_name}!")
    }
