variable "TAG" {
default = "latest"
}

group "default" {
targets = ["webapp"]
}

target "webapp" {
tags = ["docker.io/username/webapp:${TAG}"]
}
