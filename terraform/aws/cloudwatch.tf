
// Create CloudWatch log group for EKS cluster
resource "aws_cloudwatch_log_group" "eks_cluster_logs" {
  name              = "/eks/${var.cluster_name}/cluster"
  retention_in_days = var.log_retention_days
}

// Create CloudWatch log group for application logs
resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "/eks/${var.cluster_name}/application"
  retention_in_days = var.log_retention_days
}

// Enable CloudWatch Container Insights for the EKS cluster
resource "aws_eks_cluster" "cluster" {
  name = var.cluster_name
  tags = {
    Name = var.cluster_name
  }

  lifecycle {
    ignore_changes = [
      vpc_config
    ]
  }
  
  // Enable CloudWatch Container Insights
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

// Create CloudWatch metric alarms for EKS cluster
resource "aws_cloudwatch_metric_alarm" "eks_cpu_utilization" {
  alarm_name          = "eks_cpu_utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "cpu_utilization"
  namespace           = "ContainerInsights"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors the CPU utilization of the EKS cluster nodes."
  alarm_actions       = [var.sns_topic_arn]
  dimensions {
    ClusterName = aws_eks_cluster.cluster.name
  }
}

resource "aws_cloudwatch_metric_alarm" "eks_memory_utilization" {
  alarm_name          = "eks_memory_utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "memory_utilization"
  namespace           = "ContainerInsights"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors the memory utilization of the EKS cluster nodes."
  alarm_actions       = [var.sns_topic_arn]
  dimensions {
    ClusterName = aws_eks_cluster.cluster.name
  }
}
