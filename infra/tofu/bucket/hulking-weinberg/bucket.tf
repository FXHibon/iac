resource "ovh_cloud_project_user" "s3_user" {
  service_name = data.sops_file.secrets.data["ovh.cloud_project_id"]
  description  = "tofu"
  role_names = [
    "objectstore_operator"
  ]
}

resource "ovh_cloud_project_user_s3_credential" "s3_credentials" {
  service_name = ovh_cloud_project_user.s3_user.service_name
  user_id      = ovh_cloud_project_user.s3_user.id
}

resource "ovh_cloud_project_storage" "tofu_state_storage" {
  service_name = data.sops_file.secrets.data["ovh.cloud_project_id"]
  region_name  = "RBX"
  name         = "hulking-weinberg"
  versioning = {
    status = "enabled"
  }
}

resource "ovh_cloud_project_user_s3_policy" "s3_user_policy" {
  service_name = ovh_cloud_project_user.s3_user.service_name
  user_id      = ovh_cloud_project_user.s3_user.id
  policy = jsonencode({
    Statement = [
      {
        Sid    = "AllowAllS3Actions"
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          "arn:aws:s3:::hulking-weinberg",
          "arn:aws:s3:::hulking-weinberg/*",
          "arn:aws:s3:::backups-fxhibon",
          "arn:aws:s3:::backups-fxhibon/*"
        ]
      }
    ]
  })
}

