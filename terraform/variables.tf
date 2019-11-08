variable "azure_region" {
  default = "eastus"
}

variable "azure_image_user" {
  default = "azureuser"
}

variable "azure_image_password" {
  default = "__TF_INSTANCE_PASSWORD__"
}

variable "azure_sub_id" {
  default = "__ARM_SUBSCRIPTION_ID__"
}

variable "azure_tenant_id" {
  default = "__ARM_TENANT_ID__"
}

variable "azure_client_id" {
  default = "__ARM_CLIENT_ID__"
}
 
variable "azure_client_secret" {
  default = "__ARM_CLIENT_SECRET__"
}
variable "tag_customer" {
  default = "effortless"
}

variable "tag_project" {
  default = "effortless"
}


variable "custom_win_image_name" {
  default = "jcowie-effortless-win2016"
}

variable "custom_rhel_image_name" {
  default = "jcowie-effortless-rhel-7"
}
variable "custom_image_resource_group_name" {
  default = "jcowie"
}
