## part 1: create a Lambda function
In part 1 we're going to deploy a basic Lambda function via the AWS console and call it using the cli. We'll also learn where to find the execution logs and monitor performance.

### Create a function
* Log in to the AWS console and go to Lambda
* Click `Create function`, give it a unique name and select `Python 3.8` for the Runtime

After the function is created a sample function code is shown, this can be edited inline. Let's try and replace it with:
```python
import json

def handle(event: dict, context: dict) -> dict:

    print(f"Received event {json.dumps(event)}")

    return {
        "statusCode": 200,
        "body": json.dumps("Well done!")
    }
``` 

Now we have changed the function name i.e. the handler used when the function is invoked. Update the `Runtime settings` accordingly.

Last thing: under `Monitoring tools` activate AWS X-Ray.

### Invoke function
#### console
The easiest way to test invoking the function is using a test event in the console. 

At the top of the console:
* from the dropdown select `Configure test events`, leave the defaults and give it a name.
* hit `test` and confirm that the execution finished successfully

#### cli
Alternatively the function can be invoked from the cli:
* `aws lambda invoke --function-name <function-name> output.json` 
* check `output.json` for the expected result

If you receive an error `Function not found` check you have no env variable `AWS_DEFAULT_REGION` with a region other than the one your lambda resides in.

#### pro tip
When creating a test event, the list of templates is very useful when building a lambda which will be invoked by another AWS service. You'll get a template with the expected keys which helps when developing the Lambda.

### Check logs 
#### Cloudwatch
Cloudwatch is the AWS service which collects logs from other AWS services. Often you'll need to configure a service to log to Cloudwatch but with Lambda this is added by default. Logs will be collected in the `Log groups` under `/aws/lambda/<function-name>`.

Log statements can be added using the python [logging module](https://docs.python.org/3/howto/logging.html), but also stdout will be caught such as any `print` statement. Please visit Cloudwatch and verify that the event details from the print statement in our code are present in the logs.

#### X-Ray
[X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html) lets you monitor application performance and is very useful when debugging a service or when optimizing performance. X-Ray can trace application requests across multiple AWS services.

*Example X-Ray Trace map:*
![](https://docs.aws.amazon.com/xray/latest/devguide/images/scorekeep-servicemap.png)

Go to X-Ray and select Traces. You may need to adjust the timespan (top right) before any traces appear in the list. Select a trace and see if you understand what you're seeing.

At the bottom of the Traces page, the execution of the Lambda function is broken down in segments. With more complex functions, more segments can be added using the [X-Ray SDK](https://docs.aws.amazon.com/xray/latest/devguide/xray-sdk-python.html)
