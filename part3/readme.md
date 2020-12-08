## part 3: deploy Lambda function using Terraform
In part 3 we're going to deploy the Lambda function created in part 2 using Terraform, our IAC provider of choice. We'll also add an Api Gateway resource and create an endpoint which will reach the Lambda.
 
For this tutorial we will use an example script in this folder which makes use of our own Terraform modules.

### Terraform
A detailed explanation of how Terraform works is out of scope for this tutorial but we'll run through the basic steps to finish deploying all resources.

With Terraform every folder is treated as a (sub)module and typically has 3 files:
* `variables.tf` -> input variables of this (sub)module
* `main.tf` -> using the input variables to build resources
* `output.tf` -> output variables from the resources

We will ignore the other file (`locals.tf`) for now. 

Please open [the main config file](./main.tf) and try to understand what resources are going to be created:
* The IAM role which the lambda function(s) will assume + required policies
* A lambda similar to the one from part 2
* Another lambda which we'll use as authorizer for the API calls. Our API module requires an authorizer to be used, here we'll use a very simple lambda which accept all calls.
* An API with 1 path (/tutorial) and 1 method (POST) 

### Build resources
#### initialise
From within this folder call `terraform init` to initialise the Terraform modules required.

#### plan
When running a plan, Terraform will show you which resources it plans to create/update/destroy. This is very useful to test the integrity of your configuration code and see if your plan meets your intentions.

Run `terraform plan` to carry out a plan. Terraform will ask you for input for some of the [variables](./variables.tf) which have no default. 

To fix these variables for the next run, create a file here `fixtures.tfvars` with:
```hcl-terraform
bucket = "<your-bucket-name>"  # created in part 2
lambda_file = "lambda.zip"
lambda_function_name = "<lambda-function-name>"  # must be unique in the account+region
```

Run plan again with `terraform plan -var-file fixtures.tfvars`

#### apply
If you're confortable with the plan you can run `terraform apply` to create the resources in AWS. If successful the run will output the endpoint of your API.

### Call API
Now we can call the API endpoint which terraform showed upon finishing the plan:
`curl <endpoint> -d "lambda.zip"`

Now go to Cloudwatch and check in the Lambda log what the event received from Api Gateway looks like.

Now go to X-Ray and see how the trace has monitored the execution across the services.

### Finish & destroy
This is the end of the tutorial. When finished don't forget to destroy the resources using `terraform destroy`.
