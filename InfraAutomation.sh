#!/bin/bash

#AWS 가용리전 목록 불러오기
aws ec2 describe-regions --query "Regions[].{RegionName: RegionName}" --output text > regions.info

#루프문 시작
while :
do

#Provider 선택
echo "환경을 선택해주세요."
echo "1.AWS 2.NaverCloud"
read cloud
if [ $cloud == "1" ];then
	echo "=====가용리전목록====="
	cat -n "regions.info"
	echo "===================="
	read -p "번호를 입력해주세요: " region_choice
	region=$(sed -n "${region_choice}p" "regions.info")
	cat <<EOF > main.tf
# Terraform Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.39.1"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = "$region"
}
EOF
elif [ $cloud == "2" ];then
	echo "아직 지원되지 않는 Provider 입니다."
	break
fi

#가용영역 설정
aws ec2 describe-availability-zones --region $region --query "AvailabilityZones[].{ZoneName: ZoneName}" --output text  > azs.info
echo "=====가용영역목록====="
cat -n "azs.info"
echo "===================="
read -p "첫번째 가용영역 선택: " azs_choice1
read -p "두번째 가용영역 선택: " azs_choice2
azs1=$(sed -n "${azs_choice1}p" "azs.info")
sed -i "s/az-1 = \"[^\"]*\"/az-1 = \"$azs1\"/g" ./modules/vpc/main.tf
azs2=$(sed -n "${azs_choice2}p" "azs.info")
sed -i "s/az-2 = \"[^\"]*\"/az-2 = \"$azs2\"/g" ./modules/vpc/main.tf

#프로젝트명 입력
read -p "프로젝트명 입력: " prjt

#VPC 대역 설정
vpcCidr="10.0.0.0/16"
read -p "VPC IP 대역 설정[Default:10.0.0.0/16]: " vpcCidrInput
echo $vpcCidrInput
if [ -n "$vpcCidrInput" ];then
	vpcCidr="$vpcCidrInput"
fi

#서브넷 개수 설정
read -p "아키텍쳐 티어 설정[1/2/3]: " tier

cat <<EOF >> main.tf

# VPC Count
module "main-vpc" {
  source     = "./modules/vpc"
  naming     = "$prjt"
  cidr_block = "$vpcCidr"
  tier       = $tier
}
EOF

#BastionHost 보안그룹 설정
read -p "BastionHost SSH 보안그룹 IP 자동설정[y/n]: " sgAuto
if [ $sgAuto == "y" ];then
	curl ifconfig.me | grep -oE '[^%]*' > myIp.info
	myIp=$(cat myIp.info)
elif [ $sgAuto == "n" ];then
	echo "BastionHost SSH 보안그룹에 등록할 IP 입력"
	read -p "> " inputIp
	myIp=$inputIp
fi


#키페어 생성
echo "==========키페어 생성=========="
keyName="$prjt-ec2"
mkdir ./.ssh
ssh-keygen -t rsa -b 4096 -C "" -f "./.ssh/$keyName" -N ""

#인스턴스 관련
aws ec2 describe-instance-type-offerings --location-type "availability-zone" --region us-east-1 --query "InstanceTypeOfferings[?starts_with(InstanceType, 't3')].[InstanceType]" --output text | sort | uniq > instance.info
#유저이름 구분용 배열 선언
declare -a amiNumList
amiUserList=("ec2-user" "ubuntu" "ec2-user")

#BastionHost
echo "BastionHost AMI 선택"
echo "=============================="
echo "1.AMZN2 2.Ubuntu-20.04 3.RHEL9"
echo "=============================="
read -p "번호 입력: " amiNum
amiName=$(sed -n "${amiNum}p" "amiName.info")
aws ec2 describe-images \
--owners amazon \
--filters "Name=name,Values=$amiName" "Name=state,Values=available" \
--query "reverse(sort_by(Images, &Name))[:1].ImageId" \
--region "$region" \
--output text > ami.info

#Ansible-Server
echo "앤서블 서버 AMI 선택"
echo "=============================="
echo "1.AMZN2 2.Ubuntu-20.04 3.RHEL9"
echo "=============================="
read -p "번호 입력: " amiNum
((amiNum-=1))
amiNumList+=("$amiNum")
((amiNum+=1))
amiName=$(sed -n "${amiNum}p" "amiName.info")
aws ec2 describe-images \
--owners amazon \
--filters "Name=name,Values=$amiName" "Name=state,Values=available" \
--query "reverse(sort_by(Images, &Name))[:1].ImageId" \
--region "$region" \
--output text >> ami.info

echo "앤서블 서버 사양 선택"
echo "===================="
cat -n "instance.info"
echo "===================="
read -p "번호를 선택해주세요: " srvTypeSelect
srvType=$(sed -n "${srvTypeSelect}p" "instance.info")
read -p "앤서블 서버 볼륨 크기[최소:20,최대:30]: " srvVolume

#Ansible-Node
echo "앤서블 노드 AMI 선택"
echo "=============================="
echo "1.AMZN2 2.Ubuntu-20.04 3.RHEL9"
echo "=============================="
read -p "번호 입력: " amiNum
((amiNum-=1))
amiNumList+=("$amiNum")
((amiNum+=1))
amiName=$(sed -n "${amiNum}p" "amiName.info")
aws ec2 describe-images \
--owners amazon \
--filters "Name=name,Values=$amiName" "Name=state,Values=available" \
--query "reverse(sort_by(Images, &Name))[:1].ImageId" \
--region "$region" \
--output text >> ami.info

echo "앤서블 노드 사양 선택"
echo "===================="
cat -n "instance.info"
echo "===================="
read -p "번호를 선택해주세요: " nodTypeSelect
nodType=$(sed -n "${nodTypeSelect}p" "instance.info")
read -p "앤서블 노드 볼륨 크기[최소:10,최대:30]: " nodVolume
read -p "앤서블 노드 수량: " nodCount

# AMI 정보 저장
bAmi=$(sed -n "1p" "ami.info")
srvAmi=$(sed -n "2p" "ami.info")
nodAmi=$(sed -n "3p" "ami.info")

for var in "${amiNumList[@]}"
do
  echo "$var"
done

# OS User Name 저장
if [ ${amiNumList[0]} == ${amiNumList[1]} ];then
    echo "[all:vars]
ansible_user=${amiUserList[${amiNumList[0]}]}
ansible_ssh_private_key_file=/home/${amiUserList[${amiNumList[0]}]}/${prjt}-ec2

[${amiUserList[${amiNumList[0]}]}]
ansible-server" > user.info
else
    echo "[${amiUserList[${amiNumList[0]}]}:vars]
ansible_user=${amiUserList[${amiNumList[0]}]}
ansible_ssh_private_key_file=/home/${amiUserList[${amiNumList[0]}]}/${prjt}-ec2

[${amiUserList[${amiNumList[0]}]}]
ansible-server

[${amiUserList[${amiNumList[1]}]}:vars]
ansible_user=${amiUserList[${amiNumList[1]}]}
ansible_ssh_private_key_file=/home/${amiUserList[${amiNumList[1]}]}/${prjt}-ec2

[${amiUserList[${amiNumList[1]}]}]" > user.info
fi

cat <<EOF >> main.tf

# Instance
module "instance" {
  source     = "./modules/ec2"
  naming     = "$prjt"
  myIp       = "$myIp/32"
  defVpcId   = module.main-vpc.def-vpc-id
  pubSubIds   = module.main-vpc.public-sub-ids
  pvtSubIds  = module.main-vpc.private-sub-ids
  bastionAmi = "$bAmi"
  ansSrvAmi = "$srvAmi"
  ansSrvType = "$srvType"
  ansSrvVolume = $srvVolume
  ansNodAmi = "$nodAmi"
  ansNodType = "$nodType"
  ansNodVolume = $nodVolume
  ansNodCount = $nodCount
  keyName = "$keyName"
}

# Output
output "bastion-pub-ip" {
  value = module.instance.bastion-public-ip
}

output "ans-srv-pvt-ip" {
  value = module.instance.ans-srv-pvt-ip
}

output "ansible-nod-ips" {
  value = module.instance.ansible-nod-ips
}

EOF

#설정 파일 출력
echo "==========main.tf=========="
cat main.tf
echo "==========================="
echo "============ec2============"
cat ./modules/ec2/main.tf
echo "==========================="

#내용 확인 선택문
read -p "위 내용이 맞습니까?[y/n]: " check
if [ $check == "y" ];then
	echo "환경 설정이 완료되었습니다."
	break	#루프문 탈출
fi

#루프문 끝
done
