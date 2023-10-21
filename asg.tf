resource "aws_autoscaling_group" "express_app_ecs_asg" {
 vpc_zone_identifier = [aws_subnet.sn1, aws_subnet.sn2.id, aws_subnet.sn3,]
 desired_capacity    = 2
 max_size            = 3
 min_size            = 1

 launch_template {
   id      = aws_launch_template.ecs_lt.id
   version = "$Latest"
 }

 tag {
   key                 = "AmazonECSManaged"
   value               = true
   propagate_at_launch = true
 }
}