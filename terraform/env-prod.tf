data "aws_iam_policy_document" "assume_role_prod" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "juice_shop_tr_prod_ebs_ec2_role" {
  name               = "juice-shop-tr-prod-ebs-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_prod.json
}

resource "aws_iam_role_policy_attachment" "juice_shop_tr_prod_ebs-1" {
  role       = aws_iam_role.juice_shop_tr_prod_ebs_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "juice_shop_tr_prod_ebs-2" {
  role       = aws_iam_role.juice_shop_tr_prod_ebs_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_role_policy_attachment" "juice_shop_tr_prod_ebs-3" {
  role       = aws_iam_role.juice_shop_tr_prod_ebs_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_instance_profile" "juice_shop_tr_prod_ebs_iam_instance_profile" {
  name = "juice_shop_tr_prod_ebs_iam_instance_profile"
  role = aws_iam_role.juice_shop_tr_prod_ebs_ec2_role.name
}

resource "aws_s3_bucket" "juice-shop-tr-s3-prod" {
  # checkov:skip=CKV_AWS_145:BAIXO RISCO
  bucket = "juice-shop-tr-s3-prod"
  acl    = "private"
}

resource "aws_s3_bucket_object" "juice-shop-tr-s3_prod_app_options" {
  bucket = aws_s3_bucket.juice-shop-tr-s3-prod.id
  key    = "ebs-app-options.json"
  source = "ebs-app-options.json"
}

resource "aws_elastic_beanstalk_application" "juice_shop_tr_prod_app" {
  name        = "juice-shop-tr-web-prod"
  description = "Juice Shop DevSecOps"
}

resource "aws_elastic_beanstalk_environment" "juice_shop_tr_prod_env" {
  name         = "juice-shop-tr-ebs-prod"
  application  = aws_elastic_beanstalk_application.juice_shop_tr_prod_app.name
  cname_prefix = aws_elastic_beanstalk_application.juice_shop_tr_prod_app.name

  solution_stack_name = "64bit Amazon Linux 2 v4.3.1 running Docker"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.juice_shop_tr_prod_ebs_iam_instance_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "True"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "1"
  }
}

resource "aws_elastic_beanstalk_application_version" "juice_shop_tr_prod_version" {
  name        = "juice-shop-tr-web-prod"
  application = aws_elastic_beanstalk_application.juice_shop_tr_prod_app.name
  description = "application version created by terraform"
  bucket      = aws_s3_bucket.juice-shop-tr-s3-prod.id
  key         = aws_s3_bucket_object.juice-shop-tr-s3_prod_app_options.id
}

