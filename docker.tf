provider "aws" {
  region = var.region
}

resource "aws_instance" "ucp-mgr" {
  count         = var.no_of_mgrs
  ami           = var.image_ami
  instance_type = "t2.xlarge"
  key_name      = var.key_name

  tags = {
    Name = "noop-mgr-${count.index+1}"
  }

  subnet_id              = "subnet-81348bcc"
  vpc_security_group_ids = ["sg-0081e442fa8766b23"]

  user_data = <<-EOF
        #!/bin/bash
        mkdir /etc/docker
        cat <<-EOT > /etc/docker/daemon.json
        {
        "log-driver": "json-file",
        "log-opts": {
            "max-size": "10m",
            "max-file": "3"
            }
        }
        EOT
        export DOCKER_EE_URL="https://storebits.docker.com/ee/ubuntu/sub-9368f4c1-b69e-4fff-af40-f8fdff1194ad"
        export DOCKER_EE_VERSION=19.03
        curl -fsSL "$DOCKER_EE_URL/ubuntu/gpg" | sudo apt-key add -
        apt-key fingerprint 6D085F96
        add-apt-repository \
           "deb [arch=$(dpkg --print-architecture)] $DOCKER_EE_URL/ubuntu \
           $(lsb_release -cs) \
           stable-$DOCKER_EE_VERSION"
        apt update
        apt install docker-ee docker-ee-cli containerd.io -y
        usermod -aG docker ubuntu
        systemctl enable docker
        EOF


  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> ssh-ucp.txt"
  }
}

resource "aws_instance" "dtr" {
  count         = var.no_of_dtrs
  ami           = var.image_ami
  instance_type = "t2.xlarge"
  key_name      = "noop"

  tags = {
    Name = "noop-dtr-${count.index+1}"
  }


  subnet_id              = "subnet-81348bcc"
  vpc_security_group_ids = ["sg-0081e442fa8766b23"]

  user_data = <<-EOF
        #!/bin/bash
        mkdir /etc/docker
        cat <<-EOT > /etc/docker/daemon.json
        {
        "log-driver": "json-file",
        "log-opts": {
            "max-size": "10m",
            "max-file": "3"
            }
        }
        EOT
        export DOCKER_EE_URL="https://storebits.docker.com/ee/ubuntu/sub-9368f4c1-b69e-4fff-af40-f8fdff1194ad"
        export DOCKER_EE_VERSION=19.03
        curl -fsSL "$DOCKER_EE_URL/ubuntu/gpg" | sudo apt-key add -
        apt-key fingerprint 6D085F96
        add-apt-repository \
           "deb [arch=$(dpkg --print-architecture)] $DOCKER_EE_URL/ubuntu \
           $(lsb_release -cs) \
           stable-$DOCKER_EE_VERSION"
        apt update
        apt install docker-ee docker-ee-cli containerd.io -y
        usermod -aG docker ubuntu
        systemctl enable docker
        EOF

# provisioner "local-exec" {
#   command = "echo ${self.public_ip} >> ssh-dtr.txt"
# }
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
