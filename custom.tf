variable "alarm_sns_topic_name" {
  type = string
  default = "chatops-info-alerts"
}

variable "create_msg_count_alarm" {
  type    = bool
  default = false
}

variable "oldest_msg_to_alarm" {
  type    = number
  default = 60  # 1 hr
  description = "The number of minutes to wait before triggering the alarm"
}

variable "max_count_msg_to_alarm" {
  type    = number
  default = 1000
  description = "The number of messages to wait before triggering the alarm"
}


locals {
  alarm_sns_topic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.alarm_sns_topic_name}"
}


resource "aws_cloudwatch_metric_alarm" "sqs_oldest_msg_alarm" {
  count = var.create ? 1 : 0
  alarm_name          = "${aws_sqs_queue.this.name}-sqs_oldest_msg_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "10"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Average"
  threshold           = tostring(var.oldest_msg_to_alarm * 60)
  alarm_description   = "will trigger if the queue has any msg older than threshold minutes"
  treat_missing_data  = "missing"

  alarm_actions = [local.alarm_sns_topic_arn]

  dimensions = {
    QueueName = aws_sqs_queue.this.name
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq_oldest_msg_alarm" {
  count = var.create && var.create_dlq && var.create_msg_count_alarm ? 1 : 0
  alarm_name          = "${aws_sqs_queue.dlq.name}-dlq-sqs_msg_count_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = tostring(var.oldest_msg_to_alarm * 60)
  alarm_description   = "will trigger if the queue has any msg older than threshold minutes"
  treat_missing_data  = "missing"

  alarm_actions = [local.alarm_sns_topic_arn]

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_count_msg_alarm" {
  count = var.create && var.create_msg_count_alarm ? 1 : 0
  alarm_name          = "${aws_sqs_queue.dlq.name}-dlq-sqs_msg_count_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = tostring(var.max_count_msg_to_alarm)
  alarm_description   = "will trigger if the queue has any msg older than threshold minutes"
  treat_missing_data  = "missing"

  alarm_actions = [local.alarm_sns_topic_arn]

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }
}


resource "aws_cloudwatch_metric_alarm" "dlq_count_msg_alarm" {
  count = var.create && var.create_dlq ? 1 : 0
  alarm_name          = "${aws_sqs_queue.dlq.name}-dlq-sqs_oldest_msg_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = tostring(var.max_count_msg_to_alarm)
  alarm_description   = "will trigger if the queue has any msg older than threshold minutes"
  treat_missing_data  = "missing"

  alarm_actions = [local.alarm_sns_topic_arn]

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }
}
