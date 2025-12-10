variable "system_prefix" {
  description = "System prefix for resource naming"
  type        = string
}

variable "env_prefix" {
  description = "Environment prefix for resource naming"
  type        = string
}

variable "webhook_url" {
  description = "Notify Communication App Webhook URL"
  type        = string
  sensitive   = true
}

variable "mentioned_user_mail_address" {
  description = "Email address of the user to mention (e.g., xxx@example.com)"
  type        = string
}

variable "mentioned_user_name" {
  description = "Display name of the user to mention"
  type        = string
}

variable "securityhub_cspm_severity_labels" {
  description = "Severity label list to notify for Security Hub CSPM (CRITICAL/HIGH/MEDIUM/LOW/INFORMATIONAL). Empty list disables notifications."
  type        = list(string)
  default     = ["HIGH", "CRITICAL"]
}

variable "guardduty_severity_labels" {
  description = "Severity label list to notify for GuardDuty (CRITICAL/HIGH/MEDIUM/LOW/INFORMATIONAL). Empty list disables notifications."
  type        = list(string)
  default     = ["HIGH", "CRITICAL"]
}

variable "iam_access_analyzer_severity_labels" {
  description = "Severity label list to notify for IAM Access Analyzer (CRITICAL/HIGH/MEDIUM/LOW/INFORMATIONAL). Empty list disables notifications."
  type        = list(string)
  default     = ["HIGH", "CRITICAL"]
}
