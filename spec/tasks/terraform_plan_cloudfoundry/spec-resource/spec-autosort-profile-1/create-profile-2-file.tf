resource "local_file" "spec_auto_profile_2" {
  content     = "this file is generated by terraform spec_auto_profile_2 resource !"
  filename = "${path.cwd}/spec-auto-profile-2.txt"
}

# This file is overridden by the one in auto-profile-2, otherwise we get an error due to 'my_dummy_var' already define in another spec
variable "my_dummy_var" {
  type = "string"
}