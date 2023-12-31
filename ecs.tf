resource "aws_ecs_cluster" "express_app_cluster" {
  name = "express_app_cluster"
}

resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
 name = "test1"

 auto_scaling_group_provider {
   auto_scaling_group_arn = aws_autoscaling_group.express_app_ecs_asg.arn

   managed_scaling {
     maximum_scaling_step_size = 1000
     minimum_scaling_step_size = 1
     status                    = "ENABLED"
     target_capacity           = 3
   }
 }
}
resource "aws_ecs_cluster_capacity_providers" "example" {
 cluster_name = aws_ecs_cluster.express_app_cluster.name

 capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

 default_capacity_provider_strategy {
   base              = 1
   weight            = 100
   capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
 }
}

resource "aws_ecs_task_definition" "td" {
 family             = "express_app"
 network_mode       = "awsvpc"
 execution_role_arn = "arn:aws:iam::${var.account_id}:role/ecsTaskExecutionRole"
 task_role_arn      = "arn:aws:iam::${var.account_id}:role/ecsTaskExecutionRole"
 cpu                = 256
 runtime_platform {
   operating_system_family = "LINUX"
   cpu_architecture        = "X86_64"
 }

  container_definitions = jsonencode([
    {
      name         = "express_app"
      image        = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/express_app_repo"
      cpu          = 256
      memory       = 512
      essential    = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "ecs_service" {
 name            = "express_app_service"
 cluster         = aws_ecs_cluster.express_app_cluster.id
 task_definition = aws_ecs_task_definition.td.arn
 desired_count   = 2

 network_configuration {
   subnets         = [aws_subnet.sn1.id, aws_subnet.sn2.id, aws_subnet.sn3.id]
   security_groups = [aws_security_group.express_app_sg.id]
 }

 force_new_deployment = true
 placement_constraints {
   type = "distinctInstance"
 }

 triggers = {
   redeployment = timestamp()
 }

 capacity_provider_strategy {
   capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
   weight            = 100
 }

 load_balancer {
   target_group_arn = aws_lb_target_group.ecs_tg.arn
   container_name   = "express_app"
   container_port   = 80
 }

 depends_on = [aws_autoscaling_group.express_app_ecs_asg]
}