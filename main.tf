provider "aws" {
  region = "us-west-2"
}
provider "vault" {

address = "http://127.0.0.1:8200"
skip_tls_verify = true
token = "hvs.0JBq0C2tUQ1Bg6d4HYJesOLY" # Can be set via variable to secure
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "tf-example"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "tf-example"
  }
}

resource "aws_network_interface" "foo" {
  subnet_id   = aws_subnet.my_subnet.id
  private_ips = ["172.16.10.100"]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "foo" {
  ami           = "ami-005e54dee72cc1d00" # us-west-2
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.foo.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
  user_data = <<EOF
  #cloud-config
    cloud_final_modules:
    - [users-groups,always]
    users:
    - name: ${data.consul_keys.user_name.var.user_name}
        groups: [ wheel ]
        sudo:     
        - "ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart httpd"
        - "ALL=(ALL) NOPASSWD: /usr/bin/cp /home/${data.consul_keys.user_name.var.user_name}/webserver_configuration.conf /etc/httpd/conf.d/"
        shell: /bin/bash
        ssh-authorized-keys: 
    - ${data.vault_generic_secret.srekv1.data["rsa"]}
  EOF
}

