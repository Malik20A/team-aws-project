resource "aws_db_subnet_group" "default" {
  name       = "wordpress"
  subnet_ids = data.terraform_remote_state.remote.outputs.private_subnets
  tags = var.tags
}

resource "aws_security_group" "mysql" {
  name        = "mysql"
  description = "Allow mysql inbound traffic"
  vpc_id      = data.terraform_remote_state.remote.outputs.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.tags
}

resource "aws_security_group_rule" "mysql" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mysql.id
}



resource "aws_rds_cluster" "wordpress_db" {
  vpc_security_group_ids = [aws_security_group.mysql.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
  cluster_identifier      = "aurora-cluster"
  engine                  = "aurora"
  engine_version          = "5.6.10a"
  database_name           = "mydb"
  master_username         = "foo"
  master_password         = "12345678"
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot    = true
}

resource "aws_rds_cluster_instance" "wordpress_db" {
  cluster_identifier = aws_rds_cluster.wordpress_db.id
  instance_class     = "db.t2.small"
  engine             = aws_rds_cluster.wordpress_db.engine
  engine_version     = aws_rds_cluster.wordpress_db.engine_version
}



resource "aws_route53_record" "writer" {
  zone_id = var.zone_id
  name    = "writer.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_rds_cluster_instance.wordpress_db.endpoint]
}


resource "aws_route53_record" "reader1" {
  zone_id = var.zone_id
  name    = "reader1.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_rds_cluster_instance.wordpress_db.reader_endpoint]
}


resource "aws_route53_record" "reader2" {
  zone_id = var.zone_id
  name    = "reader2.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_rds_cluster_instance.wordpress_db.reader_endpoint]
}


resource "aws_route53_record" "reader3" {
  zone_id = var.zone_id
  name    = "reader3.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_rds_cluster_instance.wordpress_db.reader_endpoint]




# resource "aws_route53_record" "wordpressdb" {
#   zone_id = var.zone_id
#   name    = "wordpressdb.${var.domain_name}"
#   type    = "CNAME"
#   ttl     = 300
#   records = [aws_rds_cluster.wordpress_db.address]
# }