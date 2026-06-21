data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/instance_scheduler.py"
  output_path = "${path.module}/lambda/instance_scheduler.zip"
}

resource "aws_lambda_function" "scheduler" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-${var.environment}-instance-scheduler"
  role             = aws_iam_role.lambda_scheduler.arn
  handler          = "instance_scheduler.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TAG_KEY   = "Schedule"
      TAG_VALUE = "mon-fri_8-16"
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-instance-scheduler"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "opentofu"
  }
}

resource "aws_cloudwatch_event_rule" "start" {
  name                = "${var.project_name}-${var.environment}-start-rule"
  description         = "Start EC2 instances at 8AM Hanoi (1AM UTC) on weekdays"
  schedule_expression = "cron(0 1 ? * MON-FRI *)"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "opentofu"
  }
}

resource "aws_cloudwatch_event_rule" "stop" {
  name                = "${var.project_name}-${var.environment}-stop-rule"
  description         = "Stop EC2 instances at 4PM Hanoi (9AM UTC) on weekdays"
  schedule_expression = "cron(0 9 ? * MON-FRI *)"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "opentofu"
  }
}

resource "aws_cloudwatch_event_target" "start" {
  rule  = aws_cloudwatch_event_rule.start.name
  arn   = aws_lambda_function.scheduler.arn
  input = jsonencode({ action = "start" })
}

resource "aws_cloudwatch_event_target" "stop" {
  rule  = aws_cloudwatch_event_rule.stop.name
  arn   = aws_lambda_function.scheduler.arn
  input = jsonencode({ action = "stop" })
}

resource "aws_lambda_permission" "allow_eventbridge_start" {
  statement_id  = "AllowExecutionFromEventBridgeStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start.arn
}

resource "aws_lambda_permission" "allow_eventbridge_stop" {
  statement_id  = "AllowExecutionFromEventBridgeStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop.arn
}
