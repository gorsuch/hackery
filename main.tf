provider "aws" {
  region = "${var.region}"
}

resource "aws_vpc" "hackery" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
}

resource "aws_route_table" "external" {
    vpc_id = "${aws_vpc.hackery.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.hackery.id}"
    }
}

resource "aws_route_table_association" "external-hackery" {
    subnet_id = "${aws_subnet.hackery.id}"
    route_table_id = "${aws_route_table.external.id}"
}

# TODO: figure out how to support creating multiple subnets, one for each
# availability zone.
resource "aws_subnet" "hackery" {
    vpc_id = "${aws_vpc.hackery.id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "${var.availability_zone}"
}

resource "aws_internet_gateway" "hackery" {
    vpc_id = "${aws_vpc.hackery.id}"
}

# TODO: this seems overly permissive
resource "aws_security_group" "load_balancers" {
    name = "load_balancers"
    description = "Allows all traffic"
    vpc_id = "${aws_vpc.hackery.id}"

    # TODO: do we need to allow ingress besides TCP 80 and 443?
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # TODO: this probably only needs egress to the ECS security group.
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "ecs" {
    name = "ecs"
    description = "Allows all traffic"
    vpc_id = "${aws_vpc.hackery.id}"

    # TODO: remove this and replace with a bastion host for SSHing into
    # individual machines.
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        security_groups = ["${aws_security_group.load_balancers.id}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_ecs_cluster" "hackery" {
    name = "${var.ecs_cluster_name}"
}

resource "aws_autoscaling_group" "ecs-cluster" {
    availability_zones = ["${var.availability_zone}"]
    name = "ECS ${var.ecs_cluster_name}"
    min_size = "${var.autoscale_min}"
    max_size = "${var.autoscale_max}"
    desired_capacity = "${var.autoscale_desired}"
    health_check_type = "EC2"
    launch_configuration = "${aws_launch_configuration.ecs.name}"
    vpc_zone_identifier = ["${aws_subnet.hackery.id}"]
}

resource "aws_launch_configuration" "ecs" {
    name = "ECS ${var.ecs_cluster_name}"
    image_id = "${lookup(var.amis, var.region)}"
    instance_type = "${var.instance_type}"
    security_groups = ["${aws_security_group.ecs.id}"]
    iam_instance_profile = "${aws_iam_instance_profile.ecs.name}"
    # TODO: is there a good way to make the key configurable sanely?
    #key_name = "${aws_key_pair.alex.key_name}"
    associate_public_ip_address = true
    user_data = "#!/bin/bash\necho ECS_CLUSTER='${var.ecs_cluster_name}' > /etc/ecs/ecs.config"
}

resource "aws_iam_instance_profile" "ecs" {
    name = "ecs-instance-profile"
    path = "/"
    role = "${aws_iam_role.ecs_host_role.name}"
}
