resource "aws_sns_topic" "user_updates" {
  name = "${var.aws_region}_ec2_amicleanup_notify"


  provisioner "local-exec" {
    command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint test@test.com"
  }
}
