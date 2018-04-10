provider "aws" {
  region = "${var.region}"
}

resource "aws_instance" "ucp-mgr" {
  count         = "${var.no_of_mgrs}"
  ami           = "ami-26ebbc5c"
  instance_type = "t2.micro"
  tags {
    Name = "noop-mgr-${count.index+1}"
  }
}

resource "aws_instance" "dtr" {
  count         = "${var.no_of_dtrs}"
  ami           = "ami-26ebbc5c"
  instance_type = "t2.micro"
  tags {
    Name = "noop-dtr-${count.index+1}"
  }
}

output "ucp_ip" {
  value = "${aws_instance.ucp-mgr.*.public_ip}"
}

output "dtr_ip" {
  value = "${aws_instance.dtr.*.public_ip}"
}
