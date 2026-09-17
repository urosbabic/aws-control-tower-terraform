output "organizational_unit_id_to_arn" {
  description = "Map of discovered organizational unit IDs to ARNs."
  value       = local.ou_id_to_arn
}

output "enabled_controls" {
  description = "Control and OU pairs managed by this configuration."
  value = {
    for key, control in aws_controltower_control.this :
    key => control.target_identifier
  }
}