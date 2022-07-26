output "buildkite" {
  value = flatten([
    for mod in module.buildkite-agents : mod.buildkite-agents
  ])
  sensitive = true
}

output "allowed_ip_cidrs" {
  value = [for detail in var.allowed_ip_cidrs : detail]
}
