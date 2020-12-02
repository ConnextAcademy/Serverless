terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.8"
    }
  }
}

provider aws {
  region = var.region
}

/*
  Creating the IAM role for the Lambda function to assume
*/
data aws_iam_policy_document assume_role {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = toset(["lambda.amazonaws.com"])
    }
  }
}

resource aws_iam_role lambda {
  name               = "tutorial-lambda-role-${var.bucket}"  # must be unique within the account
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

/*
 Now attach the necessary policies to
   * allow logging to Cloudwatch
   * allow writing to X-ray
   * allow reading S3
*/
resource aws_iam_role_policy_attachment aws_lambda_cloudwatch {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource aws_iam_role_policy_attachment aws_xray_write_only_access {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource aws_iam_role_policy_attachment aws_s3_access {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

/*
 Use the Terraform module to create a Lambda function
*/
module lambda {
  source = "git::ssh://git@github.com/ConnectHolland/terraform-aws-lambda-function.git?ref=tags/0.2.1"

  filename         = var.lambda_file
  bucketname       = var.bucket
  source_code_hash = filebase64sha256("../part2/lambda.zip")

  description   = "Tutorial lambda"
  function_name = var.lambda_function_name
  handler       = "handler.handle"
  role_arn      = aws_iam_role.lambda.arn
  runtime       = "python3.8"
  enable_xray   = true

  lambda_env_vars = {
    BUCKET = var.bucket
  }

  role_numbers     = { LMB = 1, API = 1, LOG = 1}
  tagging_defaults = local.tagging_defaults
}

/*
 Here we'll create a second lambda which handles authorization
*/
module authorizer {
  source = "git::ssh://git@github.com/ConnectHolland/terraform-aws-lambda-function.git?ref=tags/0.2.1"

  filename         = var.lambda_file
  bucketname       = var.bucket
  source_code_hash = filebase64sha256("../part2/lambda.zip")

  description   = "Tutorial authorizer lambda"
  function_name = "${var.lambda_function_name}-authorizer"
  handler       = "authorizer.handle"
  role_arn      = aws_iam_role.lambda.arn
  runtime       = "python3.8"
  enable_xray   = true

  lambda_env_vars = {
    BUCKET = var.bucket
  }

  role_numbers     = module.lambda.role_numbers
  tagging_defaults = local.tagging_defaults
}

/*
 Use the Terraform module to create an API
*/
module api_gateway {
  source = "git::ssh://git@github.com/ConnectHolland/terraform-aws-api-gateway.git?ref=tags/0.2.1"

  description    = "Tutorial api"
  name           = "tutorial-api-${var.bucket}"
  endpoint_types = ["REGIONAL"]
  stage          = "dev"
  paths          = ["tutorial"]
  http_methods   = ["POST"]
  lambda_invoke_arn_list = [module.lambda.invoke_arn]

  CORS_allow_methods = "'OPTIONS,POST'"
  CORS_allow_origin  = "'*'"

  authorizer_type      = "REQUEST"
  authorizer_uri  = module.authorizer.invoke_arn
  enable_xray          = true

  role_numbers = module.authorizer.role_numbers
  tagging_defaults = local.tagging_defaults
}

/*
 Allow Api Gateway to trigger your Lambda
*/
resource aws_lambda_permission lambda {
  statement_id  = "AllowMyDemoAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${module.api_gateway.execution_arn}/*/*/*"
}

resource aws_lambda_permission authorizer {
  statement_id  = "AllowMyDemoAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.authorizer.name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${module.api_gateway.execution_arn}/*/*/*"
}
