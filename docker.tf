provider "aws" {
  region = "${var.region}"
}

resource "aws_instance" "ucp-mgr" {
  count         = "${var.no_of_mgrs}"
  ami           = "ami-26ebbc5c"
  instance_type = "t2.micro"
  key_name      = "${var.key_name}"

  tags {
    Name = "noop-mgr-${count.index+1}"
  }

  subnet_id              = "subnet-71c4205b"
  vpc_security_group_ids = ["sg-bcb667f5"]

  user_data = <<-EOF
        #!/bin/bash
        sh -c 'echo "https://storebits.docker.com/ee/m/sub-0c8da95e-0837-42c0-a63f-6d57b5ee2f2a/rhel" > /etc/yum/vars/dockerurl'
        sh -c 'echo "7" > /etc/yum/vars/dockerosversion'
        yum install -y yum-utils device-mapper-persistent-data lvm2
        yum-config-manager --enable docker-ee-stable-17.06
        yum-config-manager --enable rhel-7-server-extras-rpms
        yum-config-manager --enable rhui-REGION-rhel-server-extras
        yum-config-manager --add-repo https://storebits.docker.com/ee/m/sub-0c8da95e-0837-42c0-a63f-6d57b5ee2f2a/rhel/docker-ee.repo
        yum makecache fast
        yum install --enablerepo=docker-ee-test-2.0 docker-ee -y
        systemctl start docker
        systemctl enable docker
        usermod -aG docker ec2-user
        EOF
}

resource "aws_instance" "dtr" {
  count         = "${var.no_of_dtrs}"
  ami           = "ami-26ebbc5c"
  instance_type = "t2.micro"
  key_name      = "noop-win"

  tags {
    Name = "noop-dtr-${count.index+1}"
  }

  subnet_id              = "subnet-71c4205b"
  vpc_security_group_ids = ["sg-bcb667f5"]

  user_data = <<-EOF
        #!/bin/bash
        sh -c 'echo "https://storebits.docker.com/ee/m/sub-0c8da95e-0837-42c0-a63f-6d57b5ee2f2a/rhel" > /etc/yum/vars/dockerurl'
        sh -c 'echo "7" > /etc/yum/vars/dockerosversion'
        yum install -y yum-utils device-mapper-persistent-data lvm2
        yum-config-manager --enable docker-ee-stable-17.06
        yum-config-manager --enable rhel-7-server-extras-rpms
        yum-config-manager --enable rhui-REGION-rhel-server-extras
        yum-config-manager --add-repo https://storebits.docker.com/ee/m/sub-0c8da95e-0837-42c0-a63f-6d57b5ee2f2a/rhel/docker-ee.repo
        yum makecache fast
        yum install --enablerepo=docker-ee-test-2.0 docker-ee -y
        systemctl start docker
        systemctl enable docker
        usermod -aG docker ec2-user
        EOF
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
