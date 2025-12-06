####################################
# ebs-csi
####################################

output "ebs-csi-iam-role-arn" {
  value = module.irsa-ebs-csi-controller.iam_role_arn
}

output "ebs-csi-iam-role-name" {
  value = module.irsa-ebs-csi-controller.iam_role_name
}


####################################
# lb-controller
####################################
output "lb-controller-iam-role-arn" {
  value = module.irsa-lb-controller.iam_role_arn
}

output "lb-controller-iam-role-name" {
  value = module.irsa-lb-controller.iam_role_name
}

