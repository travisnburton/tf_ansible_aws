# Create hosts file for Ansible
resource "local_file" "ansible_inventory" {
  content = templatefile("./templates/hosts.tpl",
    {
      host = aws_eip.hello_aws.public_ip
    }
  )
  filename = "../app/inventory/hosts"
}

# Execute Ansible playbook to configure webserver
resource "null_resource" "ansible" {
  triggers = {
    eip = aws_eip.hello_aws.id
  }
  depends_on = [
    aws_volume_attachment.hello_aws
  ]
  provisioner "local-exec" {
      command = "ansible-playbook -i ../app/inventory/ ../app/hello-aws.yml"
    }
}
