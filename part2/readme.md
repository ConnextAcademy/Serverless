## part 2: deploy Lambda function using Terraform
In part 2 we're going to create a Lambda function with dependencies locally and deploy it via S3.

For this part of the tutorial we'll assume all steps of the [prerequisites](../prerequisites.md) have been successfully carried out.
  
### Build resources
We'll build simple Lambda function, similar as in part 1, but with the addition of a dependency. The runtime environment in AWS Lambda comes with some batteries included but if you want to control your own dependencies or versions you'll have to package them with your Lambda code in a zip archive.

Start a python project inside this folder using the following command:
* `poetry init` -> initialise the project, answer the questions about dependencies with 'no'
* `poetry env use ~/.pyenv/versions/3.8.6/bin/python3.8` -> set the python version for your project
* `poetry add boto3` -> install the boto3 dependency (boto is the official AWS SDK for python) 

The example script [`handler.py`](./handler.py), together with a function from [`util.py`](./util.py) will check if a file exists in an AWS S3 bucket. Let's first create a bucket using the cli:

`aws s3 mb s3://<your-bucket-name>` -> this creates a bucket (mb=make bucket) in your default region. Remember that your bucket name must be globally unique.

Now go to the console > s3 to verify your bucket exists.

The dependencies need to be wrapped with your function code in a zip archive. Dependencies can be installed in a subdirectory called `python/`. Poetry can not do this (easily) but pip can:
* `poetry run pip freeze > requirements.txt`
* `poetry run pip install -r requirements.txt -t python`
* `zip -q lambda.zip -r .`

Now upload the zip file to your bucket using either
* the web console (navigate to your bucket and hit 'Upload')
* the cli on your machine (use this command: `aws s3 cp lambda.zip s3://<your-bucket-name>`)


### Deploy lambda
Go to the console > Lambda and to your previously build function. Under 'Function code' choose 'Actions > Upload a file form Amazon S3' and specify the path `s3://<your-bucket-name>/lambda.zip`.

Under 'Runtime settings' adjust the handler to `handler.handle` and in 'Environment variables' set `BUCKET = <your-bucket-name>`.

Now test your code, e.g. from the console with a test event like:
```json
{
  "body": "lambda.zip"
}
```

The code should execute but the result is not as expected: the file appears not to be found. Check the log details and verify this is caused by a 403 exception: your Lambda function is not allowed to access S3 yet.

These permissions are added by attaching an IAM policy to the IAM Role the Lambda uses to identify itself. In the Lambda function go to the 'Permissions' tab and click on the 'Execution role' name which should take you to AWS IAM. 

There you can attach an additional policy: look for the AWS managed policy `AmazonS3ReadOnlyAccess` and attach it to the role. Go back to Lambda and verify a successful execution with a test event.
