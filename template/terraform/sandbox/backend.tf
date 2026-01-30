terraform {
  required_version = ">= 1.4"
  backend "s3" {
    region         = "{{ copier__aws_region }}"
    bucket         = "{{ copier__terraform_state_name }}"
    key            = "{{ copier__project_slug }}.sandbox.json"
    encrypt        = true
    dynamodb_table = "{{ copier__terraform_state_name }}"
  }
}

module "global_variables" {
  source = "../modules/global_variables"
}
