data "aws_organizations_organization" "current" {}

data "aws_partition" "current" {}

data "aws_organizations_organizational_units" "root" {
  parent_id = data.aws_organizations_organization.current.roots[0].id
}

data "aws_organizations_organizational_units" "depth_1" {
  for_each  = toset([for child in data.aws_organizations_organizational_units.root.children : child.id])
  parent_id = each.key
}

data "aws_organizations_organizational_units" "depth_2" {
  for_each = toset(flatten([
    for parent in data.aws_organizations_organizational_units.depth_1 : [
      for child in parent.children : child.id
    ]
  ]))
  parent_id = each.key
}

data "aws_organizations_organizational_units" "depth_3" {
  for_each = toset(flatten([
    for parent in data.aws_organizations_organizational_units.depth_2 : [
      for child in parent.children : child.id
    ]
  ]))
  parent_id = each.key
}

data "aws_organizations_organizational_units" "depth_4" {
  for_each = toset(flatten([
    for parent in data.aws_organizations_organizational_units.depth_3 : [
      for child in parent.children : child.id
    ]
  ]))
  parent_id = each.key
}

data "aws_organizations_organizational_units" "depth_5" {
  for_each = toset(flatten([
    for parent in data.aws_organizations_organizational_units.depth_4 : [
      for child in parent.children : child.id
    ]
  ]))
  parent_id = each.key
}

locals {
  normalized_controls = concat(
    [
      for group in var.controls : {
        control_names = [
          for control in group.control_names : { (control) = {} }
        ]
        organizational_unit_ids = group.organizational_unit_ids
      }
    ],
    var.controls_with_params
  )

  configured_controls = flatten([
    for group in local.normalized_controls : [
      for control in group.control_names : [
        for ou_id in group.organizational_unit_ids : {
          control_id = keys(control)[0]
          ou_id      = ou_id
          parameters = try(values(control)[0].parameters, null)
        }
      ]
    ]
  ])

  all_organizational_units = concat(
    data.aws_organizations_organizational_units.root.children,
    flatten([for units in data.aws_organizations_organizational_units.depth_1 : units.children]),
    flatten([for units in data.aws_organizations_organizational_units.depth_2 : units.children]),
    flatten([for units in data.aws_organizations_organizational_units.depth_3 : units.children]),
    flatten([for units in data.aws_organizations_organizational_units.depth_4 : units.children])
  )

  ou_id_to_arn = {
    for organizational_unit in local.all_organizational_units :
    organizational_unit.id => organizational_unit.arn
  }
}

resource "aws_controltower_control" "this" {
  for_each = {
    for item in local.configured_controls : "${item.control_id}:${item.ou_id}" => item
  }

  control_identifier = "arn:${data.aws_partition.current.partition}:controlcatalog:::control/${each.value.control_id}"
  target_identifier  = local.ou_id_to_arn[each.value.ou_id]

  dynamic "parameters" {
    for_each = each.value.parameters != null ? each.value.parameters : {}

    content {
      key   = parameters.key
      value = jsonencode(parameters.value)
    }
  }
}