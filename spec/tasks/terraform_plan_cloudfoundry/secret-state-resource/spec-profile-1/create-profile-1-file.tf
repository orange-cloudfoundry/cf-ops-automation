resource "local_file" "spec_profile_1" {
  content     = "this file is generated by terraform spec_profile_1 resource !"
  filename = "${path.cwd}/spec-profile-1.txt"
}
