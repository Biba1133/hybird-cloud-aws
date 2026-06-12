provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://127.0.0.1:4566"
    s3 = "http://127.0.0.1:4566"
  }
}

# الجزء الثاني: بناء شبكة الشركة (VPC)
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "Nile-Company-VPC"
  }
}
# ==========================================
# الجزء الثالث: تقسيم الشبكة لغرف (Subnets)
# ==========================================

# 1. الغرفة العامة (Public Subnet) - للاستقبال والإنترنت
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Nile-Public-Subnet"
  }
}

# 2. الغرفة الخاصة (Private Subnet) - للخزنة وقاعدة البيانات
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Nile-Private-Subnet"
  }
}
# ==========================================
# الجزء الرابع: الباب الرئيسي (Internet Gateway) ولوحات الإرشاد
# ==========================================

# 1. تركيب الباب الرئيسي للشركة
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "Nile-IGW"
  }
}

# 2. لوحة الإرشاد (Route Table) اللي بتوجه الناس للباب
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # (0.0.0.0/0) معناها أي مكان في الإنترنت
    gateway_id = aws_internet_gateway.main_igw.id # يمر عبر الباب دا
  }

  tags = {
    Name = "Nile-Public-RouteTable"
  }
}

# 3. ربط لوحة الإرشاد بالغرفة العامة
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ==========================================
# الجزء الخامس: قاعدة البيانات (الخزنة السرية - RDS)
# ==========================================

# 1. الحارس الشخصي (Security Group) لقاعدة البيانات
resource "aws_security_group" "db_sg" {
  name        = "nile-db-sg"
  description = "Allow MySQL traffic only from inside the company"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name = "Nile-DB-SecurityGroup"
  }
}

# --- الكود أدناه مجمد (مؤقتاً) لأن النسخة المجانية من LocalStack لا تدعمه ---
# --- سيتم تفعيله يوم المناقشة على حساب AWS الحقيقي ---

# resource "aws_db_subnet_group" "db_subnet_group" {
#   name       = "nile-db-subnet-group"
#   subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.public_subnet.id] 
#   tags = {
#     Name = "Nile-DB-SubnetGroup"
#   }
# }

# resource "aws_db_instance" "main_db" {
#   allocated_storage      = 20
#   engine                 = "mysql"
#   engine_version         = "8.0"
#   instance_class         = "db.t3.micro"
#   db_name                = "nile_company_db"
#   username               = "admin"
#   password               = "NilePassword123"
#   db_subnet_group_name   = "nile-db-subnet-group"
#   vpc_security_group_ids = [aws_security_group.db_sg.id]
#   skip_final_snapshot    = true
#   tags = {
#     Name = "Nile-Database"
#   }
# }

# ==========================================
# الجزء السادس: مخزن الملفات (S3 Bucket)
# ==========================================

resource "aws_s3_bucket" "company_files" {
  # اسم المخزن لازم يكون فريد على مستوى العالم، عشان كدا ضفنا ليه أرقام
  bucket = "nile-company-files-bucket-2026" 
  
  tags = {
    Name        = "Nile-Company-Files"
    Environment = "Hybrid-Cloud-Project"
  }
}
