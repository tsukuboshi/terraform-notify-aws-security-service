output "events_api_destination_arn" {
  description = "The ARN of the EventBridge API Destination"
  value       = aws_cloudwatch_event_api_destination.teams.arn
}
