variable "ubuntu_version" {
  description = "The password for the anible vault."
  type        = string
  default     = "22.04"
}

variable "docker_repository" {
  description = "The repository to push the image to."
  type        = string
  default     = "romanos"
}

variable "app_version" {
  description = "The version to tag the image with."
  type        = string
  default     = "1.1"
}

variable "docker_registry_host" {
  description = "The registry to push the image to."
  type        = string
  default     = env("DOCKER_REGISTRY_HOST")
}

variable "docker_registry_user" {
  description = "The username for the registry."
  type        = string
  default     = env("DOCKER_REGISTRY_USER")
}

variable "docker_registry_pass" {
  description = "The password for the registry."
  type        = string
  default     = env("DOCKER_REGISTRY_PASS")
}