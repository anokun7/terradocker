provider "aws" {
  region = "${var.region}"
}

resource "aws_instance" "ucp-mgr" {
  count         = "${var.no_of_mgrs}"
  ami           = "${var.image_ami}"
  instance_type = "t2.large"
  key_name      = "${var.key_name}"

  tags {
    Name = "noop-mgr-${count.index+1}"
  }

  subnet_id              = "subnet-71c4205b"
  vpc_security_group_ids = ["sg-bcb667f5"]

  user_data = <<-EOF
        #!/bin/bash
        apt update
        apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        apt-key fingerprint 0EBFCD88
        add-apt-repository  "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) Stable test"
        apt update
        apt-cache madison docker-ce
        apt-get install docker-ce -y
        systemctl enable docker
        usermod -aG docker ubuntu
        EOF


  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> ssh-ucp.txt"
  }
}

resource "aws_instance" "dtr" {
  count         = "${var.no_of_dtrs}"
  ami           = "${var.image_ami}"
  instance_type = "t2.large"
  key_name      = "noop-win"

  tags {
    Name = "noop-dtr-${count.index+1}"
  }

  subnet_id              = "subnet-71c4205b"
  vpc_security_group_ids = ["sg-bcb667f5"]

  user_data = <<-EOF
        #!/bin/bash
        apt update
        apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        apt-key fingerprint 0EBFCD88
        add-apt-repository  "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) Stable test"
        apt update
        apt-cache madison docker-ce docker-ce
        apt-get install docker-ce -y
        systemctl enable docker
        usermod -aG docker ubuntu
        EOF

  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> ssh-dtr.txt"
  }
}

resource "null_resource" "ssh-configs" {
  count = 3

  provisioner "local-exec" {
    command = "echo ${element(aws_instance.dtr.*.public_ip, count.index+1)} >> ssh.txt"
  }
}

output "ucp_ip" {
  value = "${aws_instance.ucp-mgr.*.public_ip}"
}

output "dtr_ip" {
  value = "${aws_instance.dtr.*.public_ip}"
}
