variable "module-param" {}

resource "local_file" "file-within-module" {
  content     = "this file is generated by terraform spec resource module! with input param : ${var.module-param}"
  filename = "${path.cwd}/module.txt"
}

