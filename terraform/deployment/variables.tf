variable "aws_region" {
  type = string
  default = "eu-central-1"
}

variable "aws_access" {
    type = string
}
variable "aws_secret" {
    type = string
}

variable "stage_name" {
    type = string
}

variable "image_tag" {
    type = string
}