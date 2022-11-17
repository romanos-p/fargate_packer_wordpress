locals {
  timestamp = formatdate("YYYY-MM-DD-hhmmss", timestamp())
}

source "docker" "image-builder" {
  image  = "ubuntu:${var.ubuntu_version}"
  commit = true
  changes = [
    "USER root",
    "WORKDIR /var/www",
    "EXPOSE 80",
    "ENTRYPOINT /var/www/start.sh"
  ]
}

build {
  sources = ["source.docker.image-builder"]

  # install basic required utils
  provisioner "shell" {
    script = "./scripts/bootstrap.sh"
  }

  # install ansible for provisioning the image
  provisioner "shell" {
    script = "./scripts/install_ansible.sh"
  }

  # run ansible playbooks
  provisioner "ansible-local" {
    playbook_files          = ["../ansible/install_nginx.yml", "../ansible/install_php.yml", "../ansible/install_wordpress.yml"]
    playbook_dir            = "../ansible"
    clean_staging_directory = true
  }

  # uninstall ansible after provisioning is completed
  provisioner "shell" {
    script = "./scripts/remove_ansible.sh"
  }

  # tag anbd push the image to the repository
  post-processors {
    post-processor "docker-tag" {
      repository = "${var.docker_registry_host}/${var.docker_repository}/wp"
      tags       = ["${var.app_version}"]
    }
    post-processor "docker-push" {
      login          = true
      login_server   = "${var.docker_registry_host}"
      login_username = "${var.docker_registry_user}"
      login_password = "${var.docker_registry_pass}"
    }
  }
}