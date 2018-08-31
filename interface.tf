variable "function_name" {
  description = "lambda name"
  default     = "ec2-manager-ent-vpc-2-amicleanup"
}

variable "cron_schedule" {
  description = "schedule for cloudwatch event"
  default     = "cron(0 10 ? * WED *)"
}

variable "timeout" {
  description = "timeout"
  default     = "30"
}

variable "memory_size" {
  description = "memory size"
  default = "128"
}

variable "app_tier" {
  description = "app tier"
  default     = "dev"
}


variable "aws_region" {
  description = "aws region"
  default = "us-east-2"
}

variable "handler" {
  description = "handler definition"
  default = "amicleanup.handler"
}

variable "runtime" {
  description = "runtime"
  default = "python3.6"
}
