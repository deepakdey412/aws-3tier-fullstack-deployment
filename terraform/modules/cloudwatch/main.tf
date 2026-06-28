########################################
# SNS Topic for alarms
########################################
resource "aws_sns_topic" "alarms" {
  name = "${var.project_name}-${var.environment}-alarms"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

########################################
# CloudWatch Dashboard
########################################
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title   = "Web ASG CPU"
          region  = var.aws_region
          period  = 300
          stat    = "Average"
          metrics = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.web_asg_name]]
        }
      },
      {
        type = "metric"
        properties = {
          title   = "App ASG CPU"
          region  = var.aws_region
          period  = 300
          stat    = "Average"
          metrics = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.app_asg_name]]
        }
      },
      {
        type = "metric"
        properties = {
          title   = "RDS CPU"
          region  = var.aws_region
          period  = 300
          stat    = "Average"
          metrics = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_identifier]]
        }
      },
      {
        type = "metric"
        properties = {
          title   = "RDS Free Storage"
          region  = var.aws_region
          period  = 300
          stat    = "Average"
          metrics = [["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.rds_identifier]]
        }
      }
    ]
  })
}

########################################
# Alarms
########################################
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU > 80%"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = { DBInstanceIdentifier = var.rds_identifier }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2000000000  # 2 GB
  alarm_description   = "RDS free storage < 2 GB"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = { DBInstanceIdentifier = var.rds_identifier }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/app/${var.project_name}-${var.environment}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "web" {
  name              = "/web/${var.project_name}-${var.environment}"
  retention_in_days = 14
}
