resource "local_file" "spec_auto_profile_1" {
  content     = "this file is generated by terraform spec_auto_profile_1 resource !"
  filename = "${path.cwd}/spec-auto-profile-1.txt"
}