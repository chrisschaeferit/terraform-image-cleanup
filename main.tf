data "aws_caller_identity" "current" {}

data "archive_file" "lambda_zip" {
  type          = "zip"
  source_file   = "code/amicleanup.py"
  output_path   = "code/amicleanup.zip"
}

resource "aws_lambda_function" "ec2_amicleanup" {
  function_name = "${var.function_name}"
  role          = "${aws_iam_role.lambda_exec_role.arn}"
  handler       = "${var.handler}"
  runtime       = "${var.runtime}"
  timeout       = "${var.timeout}"
  memory_size   = "${var.memory_size}"
  filename      = "code/amicleanup.zip"
  source_code_hash = "${base64sha256(file("code/amicleanup.zip"))}"
  role = "${aws_iam_role.ec2_lambda_ami_cleanup_assumerole.arn}"

  environment {
  variables = {
   LOG_LEVEL = "INFO",
   FUNCTION_NAME = "${var.function_name}",
   APP_TIER = "dev",
   ACCOUNT_ID = "${data.aws_caller_identity.current.account_id}"
        }
  }   
}


