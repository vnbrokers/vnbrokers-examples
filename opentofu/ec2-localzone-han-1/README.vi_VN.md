# EC2 Local Zone Hà Nội (ap-southeast-1-han-1a)

Triển khai EC2 instance trên AWS Local Zone tại Hà Nội (`ap-southeast-1-han-1a`), chỉ truy cập được qua **AWS Systems Manager Session Manager**, có lịch bật/tắt tự động (Thứ 2–Thứ 6, 8:00–16:00 giờ Hà Nội).

## Kiến trúc

```
AWS Region ap-southeast-1
└── VPC (10.0.0.0/16)
    ├── Internet Gateway
    ├── Route Table (0.0.0.0/0 → IGW)
    └── Public Subnet (10.0.1.0/24) @ ap-southeast-1-han-1a
        └── EC2 c7i.large (Amazon Linux 2023)
            └── Security Group (zero inbound, all outbound)
                └── IAM Role → AmazonSSMManagedInstanceCore
```

### Scheduling

```
CloudWatch Events (cron)
  ├── 0 1 ? * MON-FRI * → Lambda (action=start) → EC2 StartInstances
  └── 0 9 ? * MON-FRI * → Lambda (action=stop)  → EC2 StopInstances
```

Lambda kiểm tra tag `Schedule=mon-fri_8-16` để biết instance nào cần quản lý.

## Yêu cầu

- [OpenTofu](https://opentofu.org/) ≥ 1.6 hoặc Terraform ≥ 1.6
- Tài khoản AWS (có quyền admin hoặc root)
- Local Zone `ap-southeast-1-han-1a` đã được opt-in

## Chuẩn bị: tạo IAM User qua AWS Console

### Bước 1: Tạo IAM user

1. Đăng nhập [AWS Console](https://console.aws.amazon.com)
2. Vào **IAM** > **Users** > **Create user**
3. Nhập **User name**: `vnborkers`
4. Tick **Provide user access to the AWS Management Console** — _bỏ chọn_ (không cần console access, chỉ cần access key cho CLI)
5. Nhấn **Next**

### Bước 2: Gán policy cho user

1. Chọn tab **Attach policies directly**
2. Nhấn **Create policy** (ở phía trên, sẽ mở tab mới)
3. Ở tab mới:
   - Chọn tab **JSON**
   - Copy toàn bộ nội dung file `vnbrokers-policies.json` vào ô JSON editor
   - Nhấn **Next**
   - **Policy name**: `vnbrokers-policies`
   - **Description**: `Policy for deploying vnbrokers EC2 Local Zone infrastructure`
   - Nhấn **Create policy**
4. Quay lại tab tạo user, nhấn nút **Refresh** (cạnh ô search)
5. Search **`vnbrokers-policies`**, tick chọn policy đó
6. Nhấn **Next** > **Create user**

### Bước 3: Tạo Access Key

1. Sau khi tạo user thành công, nhấn **View user**
2. Vào tab **Security credentials**
3. Kéo xuống **Access keys** > nhấn **Create access key**
4. Chọn **Command Line Interface (CLI)**
5. Tick **I understand the above recommendation and want to proceed to create an access key**
6. Nhấn **Next**
7. Nhấn **Create access key**
8. **Lưu lại Access Key ID và Secret Access Key** (dùng nút **Download .csv file** hoặc copy ra chỗ an toàn)

### Bước 4: Cấu hình AWS CLI

```bash
aws configure
```

Nhập các thông tin:

```
AWS Access Key ID [None]: <Access Key ID vừa tạo>
AWS Secret Access Key [None]: <Secret Access Key vừa tạo>
Default region name [None]: ap-southeast-1
Default output format [None]: json
```

Kiểm tra kết nối:

```bash
aws sts get-caller-identity
```

Kết quả trả về dạng:

```json
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/vnborkers"
}
```

### Bước 5: Opt-in Local Zone Hà Nội

Local Zone mặc định ở trạng thái **not-opted-in**, cần opt-in thủ công:

```bash
aws ec2 modify-availability-zone-group \
  --group-name ap-southeast-1-han-1 \
  --opt-in-status opted-in
```

Kiểm tra trạng thái:

```bash
aws ec2 describe-availability-zones \
  --region ap-southeast-1 \
  --all-availability-zones \
  --query "AvailabilityZones[?ZoneName=='ap-southeast-1-han-1a']"
```

Kết quả mong đợi — `OptInStatus` là `opted-in`:

```json
[
    {
        "ZoneName": "ap-southeast-1-han-1a",
        "ZoneId": "apse1-han-1a",
        "RegionName": "ap-southeast-1",
        "State": "available",
        "OptInStatus": "opted-in",
        "Messages": []
    }
]
```

### IAM Permissions — file vnbrokers-policies.json

Policy `vnbrokers-policies` (đã tạo ở Bước 2) bao gồm các quyền sau:

| Scope | Actions |
|-------|---------|
| VPC/Network (ap-southeast-1) | `ec2:CreateVpc`, `ec2:CreateSubnet`, `ec2:CreateInternetGateway`, `ec2:CreateRouteTable`, `ec2:CreateRoute`, `ec2:AssociateRouteTable` |
| EC2 in HAN Local Zone | `ec2:RunInstances`, `ec2:CreateVolume` trong `ap-southeast-1-han-1a` |
| EC2 Management (ap-southeast-1) | `Describe*`, `StartInstances`, `StopInstances`, `TerminateInstances`, `CreateSecurityGroup`, ... |
| IAM | `iam:CreateRole`, `iam:CreateInstanceProfile`, `iam:PassRole`, ... (resource: `vnbrokers-*`) |
| Lambda | `lambda:CreateFunction`, `lambda:AddPermission`, ... (function: `vnbrokers-*`) |
| EventBridge | `events:PutRule`, `events:PutTargets`, ... (rule: `vnbrokers-*`) |
| CloudWatch Logs | `logs:CreateLogGroup`, ... (log group: `/aws/lambda/vnbrokers-*`) |
| SSM | `ssm:StartSession`, `ssm:SendCommand`, ... |
| Local Zone Opt-in (global) | `ec2:ModifyAvailabilityZoneGroup`, `ec2:DescribeAvailabilityZones` |

## Sử dụng

```bash
# Khởi tạo
tofu init

# Xem kế hoạch triển khai
tofu plan

# Áp dụng
tofu apply

# Huỷ bỏ (xoá tất các các phụ thuộc)
tofu destroy
```

> ⚠️ **CẢNH BÁO: State file chứa thông tin nhạy cảm**
>
> File `terraform.tfstate` chứa toàn bộ thông tin tài nguyên đã tạo, bao gồm cả **dữ liệu nhạy cảm** (IP, ID, trạng thái tài nguyên,...). **Không commit file này lên Git public.** Nếu mất state, bạn không thể `tofu destroy` — phải xoá thủ công từng resource qua AWS Console.
>
> - **Luôn giữ bí mật** — không đưa `*.tfstate` lên Git public
> - **Sao lưu** ra nơi an toàn (S3 bucket có versioning, Git private repo, hoặc copy ra máy khác)
> - Khuyến nghị: cấu hình [S3 backend](https://opentofu.org/docs/language/settings/backends/s3/) để lưu state từ xa có mã hoá khi triển khai thật

### Truy cập EC2

Instance không có SSH (security group zero inbound). Chỉ truy cập được qua SSM:

```bash
aws ssm start-session --target $(tofu output -raw instance_id)
```

Hoặc dùng lệnh output sẵn:

```bash
tofu output ssm_command
```

## Biến (Variables)

| Biến | Mặc định | Mô tả |
|------|----------|-------|
| `region` | `ap-southeast-1` | AWS region |
| `environment` | `prod` | Môi trường |
| `project_name` | `vnbrokers` | Prefix đặt tên resource |
| `han_zone` | `ap-southeast-1-han-1a` | Tên Local Zone |
| `instance_type` | `c7i.large` | Loại instance (C7i, M7i, R7i khả dụng trong HAN zone) |
| `schedule_start_hour` | `1` | Giờ bật UTC (1 = 8AM Hà Nội) |
| `schedule_stop_hour` | `9` | Giờ tắt UTC (9 = 4PM Hà Nội) |
| `schedule_days` | `MON-FRI` | Ngày chạy schedule |
| `ami_name_pattern` | `al2023-ami-\*-kernel-6.1-x86_64` | Pattern tìm AMI |
| `vpc_cidr` | `10.0.0.0/16` | CIDR VPC |
| `subnet_cidr` | `10.0.1.0/24` | CIDR subnet |
| `ebs_volume_size` | `30` | Dung lượng ổ gốc (GB) |
| `ebs_volume_type` | `gp3` | Loại EBS volume |

## Outputs

| Output | Mô tả |
|--------|-------|
| `instance_id` | ID EC2 instance |
| `instance_type` | Loại instance |
| `instance_state` | Trạng thái |
| `private_ip` | IP nội bộ |
| `public_ip` | IP công cộng |
| `availability_zone` | Availability Zone |
| `vpc_id` | VPC ID |
| `subnet_id` | Subnet ID |
| `security_group_id` | Security Group ID |
| `ami_used` | AMI ID |
| `schedule_description` | `"Mon-Fri 8:00-16:00 Hanoi (UTC+7)"` |
| `ssm_command` | Câu lệnh SSM để kết nối |

## Cấu trúc thư mục

```
.
├── main.tf                    # VPC, subnet, IGW, route table
├── ec2.tf                     # Security group, EC2 instance, AMI data
├── iam.tf                     # IAM roles, policies, instance profile
├── scheduler.tf               # Lambda + CloudWatch Events rules
├── variables.tf               # Biến đầu vào
├── outputs.tf                 # Giá trị đầu ra
├── versions.tf                # Version constraints
├── vnbrokers-policies.json    # IAM policy mẫu cho deployment
├── lambda/
│   └── instance_scheduler.py  # Python Lambda scheduler
└── .gitignore
```

## Lưu ý

- EBS volume được mã hóa (`encrypted = true`)
- Monitoring tắt (`monitoring = false`) để tiết kiệm chi phí
- Instance tự động tắt ngoài giờ hành chính và cuối tuần
- Security Group **không có** inbound rule nào — chỉ SSM
- Local Zone thuộc region `ap-southeast-1` nhưng có latency thấp hơn cho người dùng tại Hà Nội, Việt Nam
