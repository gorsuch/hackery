variable "region" {
    description = "The AWS region to create resources in."
    default = "us-east-2"
}

# TODO: multiaz
variable "availability_zone" {
    description = "The AWS AZto create resources in."
    default = "us-east-2a"
}

variable "ecs_cluster_name" {
    description = "The name of the Amazon ECS cluster."
    default = "hackery"
}

variable "autoscale_min" {
    default = "1"
    description = "Minimum autoscale (number of EC2)"
}

variable "autoscale_max" {
    default = "10"
    description = "Maximum autoscale (number of EC2)"
}

variable "autoscale_desired" {
    default = "1"
    description = "Desired autoscale (number of EC2)"
}

variable "instance_type" {
    default = "t2.micro"
}

variable "amis" {
    description = "Which AMI to spawn. Defaults to the AWS ECS optimized images."
    default = {
        us-east-2 = "ami-1c002379"
    }
}

variable "ssh_pubkey_file" {
    description = "Path to an SSH public key"
    default = "~/.ssh/id_rsa.pub"
}
