output "dashboard_name"  { value = aws_cloudwatch_dashboard.main.dashboard_name }
output "sns_topic_arn"   { value = aws_sns_topic.alarms.arn }
output "app_log_group"   { value = aws_cloudwatch_log_group.app.name }
output "web_log_group"   { value = aws_cloudwatch_log_group.web.name }
