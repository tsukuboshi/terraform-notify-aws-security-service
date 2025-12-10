# EventBridge API Destination
resource "aws_cloudwatch_event_api_destination" "teams" {
  name                             = "${var.system_prefix}-${var.env_prefix}-teams-api-dest"
  connection_arn                   = aws_cloudwatch_event_connection.teams.arn
  invocation_endpoint              = var.webhook_url
  http_method                      = "POST"
  invocation_rate_limit_per_second = 300
}

# EventBridge Connection
resource "aws_cloudwatch_event_connection" "teams" {
  name               = "${var.system_prefix}-${var.env_prefix}-teams-conn"
  authorization_type = "API_KEY"

  auth_parameters {
    api_key {
      key   = "Content-Type"
      value = "application/json"
    }
  }
}

# IAM Policy Document for EventBridge
data "aws_iam_policy_document" "eventbridge_invoke_api_destination" {
  statement {
    effect    = "Allow"
    actions   = ["events:InvokeApiDestination"]
    resources = [aws_cloudwatch_event_api_destination.teams.arn]
  }
}

# IAM Managed Policy
resource "aws_iam_policy" "eventbridge_invoke_api_destination" {
  name   = "EventBridgePolicyForSecurityHubNotifytoTeams"
  path   = "/service-role/"
  policy = data.aws_iam_policy_document.eventbridge_invoke_api_destination.json
}

# IAM Policy Document for Assume Role
data "aws_iam_policy_document" "eventbridge_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

# IAM Role
resource "aws_iam_role" "eventbridge_teams_api_dest" {
  name                 = "${var.system_prefix}-${var.env_prefix}-eventbridge-teams-api-dest-role"
  path                 = "/service-role/"
  max_session_duration = 3600
  assume_role_policy   = data.aws_iam_policy_document.eventbridge_assume_role.json
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "eventbridge_teams_api_dest" {
  role       = aws_iam_role.eventbridge_teams_api_dest.name
  policy_arn = aws_iam_policy.eventbridge_invoke_api_destination.arn
}

# EventBridge Rule - Security Hub CSPM
resource "aws_cloudwatch_event_rule" "securityhub_cspm_notify_teams" {
  count          = length(var.securityhub_cspm_severity_labels) > 0 ? 1 : 0
  name           = "${var.system_prefix}-${var.env_prefix}-securityhub-cspm-notify-teams"
  event_bus_name = "default"
  event_pattern = jsonencode({
    detail-type = ["Security Hub Findings - Imported"]
    source      = ["aws.securityhub"]
    detail = {
      findings = {
        Severity = {
          Label = var.securityhub_cspm_severity_labels
        }
        ProductName = ["Security Hub"]
      }
    }
  })
}

# EventBridge Target - Security Hub CSPM
resource "aws_cloudwatch_event_target" "securityhub_cspm_to_teams" {
  count          = length(var.securityhub_cspm_severity_labels) > 0 ? 1 : 0
  rule           = aws_cloudwatch_event_rule.securityhub_cspm_notify_teams[0].name
  target_id      = "SecurityHubCSPMTarget"
  arn            = aws_cloudwatch_event_api_destination.teams.arn
  role_arn       = aws_iam_role.eventbridge_teams_api_dest.arn
  event_bus_name = "default"

  http_target {
    header_parameters       = {}
    query_string_parameters = {}
  }

  input_transformer {
    input_paths = {
      AwsAccountId      = "$.detail.findings[0].AwsAccountId"
      FirstObservedAt   = "$.detail.findings[0].FirstObservedAt"
      LastObservedAt    = "$.detail.findings[0].LastObservedAt"
      RecommendationUrl = "$.detail.findings[0].ProductFields.RecommendationUrl"
      Region            = "$.detail.findings[0].Resources[0].Region"
      ResourceId        = "$.detail.findings[0].Resources[0].Id"
      ResourceType      = "$.detail.findings[0].Resources[0].Type"
      SeverityLabel     = "$.detail.findings[0].Severity.Label"
      Title             = "$.detail.findings[0].Title"
    }

    input_template = templatefile("${path.module}/template.json", {
      service_name                = "SecurityHub"
      mentioned_user_name         = var.mentioned_user_name
      mentioned_user_mail_address = var.mentioned_user_mail_address
    })
  }
}

# EventBridge Rule - GuardDuty
resource "aws_cloudwatch_event_rule" "guardduty_notify_teams" {
  count          = length(var.guardduty_severity_labels) > 0 ? 1 : 0
  name           = "${var.system_prefix}-${var.env_prefix}-guardduty-notify-teams"
  event_bus_name = "default"
  event_pattern = jsonencode({
    detail-type = ["Security Hub Findings - Imported"]
    source      = ["aws.securityhub"]
    detail = {
      findings = {
        Severity = {
          Label = var.guardduty_severity_labels
        }
        ProductName = ["GuardDuty"]
      }
    }
  })
}

# EventBridge Target - GuardDuty
resource "aws_cloudwatch_event_target" "guardduty_to_teams" {
  count          = length(var.guardduty_severity_labels) > 0 ? 1 : 0
  rule           = aws_cloudwatch_event_rule.guardduty_notify_teams[0].name
  target_id      = "GuardDutyTarget"
  arn            = aws_cloudwatch_event_api_destination.teams.arn
  role_arn       = aws_iam_role.eventbridge_teams_api_dest.arn
  event_bus_name = "default"

  http_target {
    header_parameters       = {}
    query_string_parameters = {}
  }

  input_transformer {
    input_paths = {
      AwsAccountId      = "$.detail.findings[0].AwsAccountId"
      FirstObservedAt   = "$.detail.findings[0].FirstObservedAt"
      LastObservedAt    = "$.detail.findings[0].LastObservedAt"
      RecommendationUrl = "$.detail.findings[0].ProductFields.RecommendationUrl"
      Region            = "$.detail.findings[0].Resources[0].Region"
      ResourceId        = "$.detail.findings[0].Resources[0].Id"
      ResourceType      = "$.detail.findings[0].Resources[0].Type"
      SeverityLabel     = "$.detail.findings[0].Severity.Label"
      Title             = "$.detail.findings[0].Title"
    }

    input_template = templatefile("${path.module}/template.json", {
      service_name                = "GuardDuty"
      mentioned_user_name         = var.mentioned_user_name
      mentioned_user_mail_address = var.mentioned_user_mail_address
    })
  }
}

# EventBridge Rule - IAM Access Analyzer
resource "aws_cloudwatch_event_rule" "iam_access_analyzer_notify_teams" {
  count          = length(var.iam_access_analyzer_severity_labels) > 0 ? 1 : 0
  name           = "${var.system_prefix}-${var.env_prefix}-iam-access-analyzer-notify-teams"
  event_bus_name = "default"
  event_pattern = jsonencode({
    detail-type = ["Security Hub Findings - Imported"]
    source      = ["aws.securityhub"]
    detail = {
      findings = {
        Severity = {
          Label = var.iam_access_analyzer_severity_labels
        }
        ProductName = ["IAM Access Analyzer"]
      }
    }
  })
}

# EventBridge Target - IAM Access Analyzer
resource "aws_cloudwatch_event_target" "iam_access_analyzer_to_teams" {
  count          = length(var.iam_access_analyzer_severity_labels) > 0 ? 1 : 0
  rule           = aws_cloudwatch_event_rule.iam_access_analyzer_notify_teams[0].name
  target_id      = "IAMAccessAnalyzerTarget"
  arn            = aws_cloudwatch_event_api_destination.teams.arn
  role_arn       = aws_iam_role.eventbridge_teams_api_dest.arn
  event_bus_name = "default"

  http_target {
    header_parameters       = {}
    query_string_parameters = {}
  }

  input_transformer {
    input_paths = {
      AwsAccountId      = "$.detail.findings[0].AwsAccountId"
      FirstObservedAt   = "$.detail.findings[0].FirstObservedAt"
      LastObservedAt    = "$.detail.findings[0].LastObservedAt"
      RecommendationUrl = "$.detail.findings[0].ProductFields.RecommendationUrl"
      Region            = "$.detail.findings[0].Resources[0].Region"
      ResourceId        = "$.detail.findings[0].Resources[0].Id"
      ResourceType      = "$.detail.findings[0].Resources[0].Type"
      SeverityLabel     = "$.detail.findings[0].Severity.Label"
      Title             = "$.detail.findings[0].Title"
    }

    input_template = templatefile("${path.module}/template.json", {
      service_name                = "IAM Access Analyzer"
      mentioned_user_name         = var.mentioned_user_name
      mentioned_user_mail_address = var.mentioned_user_mail_address
    })
  }
}
