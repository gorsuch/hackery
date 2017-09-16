resource "aws_elb" "test-http" {
    name = "test-http-elb"
    security_groups = ["${aws_security_group.load_balancers.id}"]
    subnets = ["${aws_subnet.hackery.id}"]

    listener {
        lb_protocol = "http"
        lb_port = 80

        instance_protocol = "http"
        instance_port = 8080
    }

    health_check {
        healthy_threshold = 3
        unhealthy_threshold = 2
        timeout = 3
        target = "HTTP:8080/hello-world"
        interval = 5
    }

    cross_zone_load_balancing = true
}

resource "aws_ecs_task_definition" "test-http" {
    family = "test-http"
    container_definitions = <<EOF
[
    {
        "name": "test-http",
        "image": "317428627193.dkr.ecr.us-east-2.amazonaws.com/hello",
        "cpu": 10,
        "memory": 512,
        "links": [],
        "portMappings": [
            {
                "containerPort": 8080,
                "hostPort": 8080,
                "protocol": "tcp"
            }
        ],
        "essential": true,
        "entryPoint": [],
        "command": [],
        "environment": [],
        "mountPoints": [],
        "volumesFrom": []
    }
]
EOF
}

resource "aws_ecs_service" "test-http" {
    name = "test-http"
    cluster = "${aws_ecs_cluster.hackery.id}"
    task_definition = "${aws_ecs_task_definition.test-http.arn}"
    iam_role = "${aws_iam_role.ecs_service_role.arn}"
    desired_count = 1
    depends_on = ["aws_iam_role_policy.ecs_service_role_policy"]

    load_balancer {
        elb_name = "${aws_elb.test-http.id}"
        container_name = "test-http"
        container_port = 8080
    }
}
