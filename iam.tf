data "aws_iam_policy_document" "ec2_lambda_ami_cleanup" {
  statement {
    effect = "Allow"
    actions = [ 
    "sns:Publish",
    "ec2:DescribeImages",
    "ec2:DeregisterImage",
    "ec2:DescribeInstances",
    "ec2:CreateTags",
    "autoscaling:DescribeAutoScalingGroups",
    "autoscaling:DescribeLaunchConfigurations",
    "ec2:DescribeSnapshots",
    "logs:CreateLogStream",
    "logs:CreateLogGroup",
    "logs:PutLogEvents"
    ],
    resources = ["*"]

    }
}

data "aws_iam_policy_document" "ec2_lambda_ami_cleanup_assumerole" {
  statement {
  actions = ["sts:AssumeRole"]
  principals {
    type = "Service"
    identifiers = ["lambda.amazonaws.com"]
  }
  effect = "Allow"
  }
}

resource "aws_iam_role" "ec2_lambda_ami_cleanup_assumerole" {
  name       = "${var.function_name}"
  assume_role_policy = "${data.aws_iam_policy_document.ec2_lambda_ami_cleanup_assumerole.json}"
}

resource "aws_iam_policy" "ec2_lambda_ami_cleanup" {
  name       = "${var.function_name}"
  policy     = "${data.aws_iam_policy_document.ec2_lambda_ami_cleanup.json}"
}

resource "aws_iam_policy_attachment" "ec2_lambda_ami_cleanup" {
  name       = "${var.function_name}"
  roles      = ["${aws_iam_role.ec2_lambda_ami_cleanup_assumerole.name}"]
  policy_arn = "${aws_iam_policy.ec2_lambda_ami_cleanup.arn}"
}
