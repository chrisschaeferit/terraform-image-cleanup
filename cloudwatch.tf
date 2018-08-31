resource "aws_cloudwatch_event_rule" "us-east-2_ec2_amicleanup" {
  name                = "${var.function_name}"
  description         = "trigger amicleanup every week monday"
  schedule_expression = "${var.cron_schedule}"
}

resource "aws_cloudwatch_event_target" "lambda_amicleanup" {
  rule      = "${aws_cloudwatch_event_rule.us-east-2_ec2_amicleanup.name}"
  target_id = "ec2_amicleanup"
  arn       = "${aws_lambda_function.ec2_amicleanup.arn}"
}
 

resource "aws_lambda_permission" "ec2_amicleanup_trigger" {
  statement_id  = "AllowCloudwatchTrigger"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.ec2_amicleanup.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.us-east-2_ec2_amicleanup.arn}"
}
