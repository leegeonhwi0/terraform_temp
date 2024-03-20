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
read -p "멀티 AZ 설정[y,n]: " multiAzs
echo "=====가용영역목록====="
cat -n "azs.info"
echo "===================="
if [ $multiAzs == "y" ];then
	read -p "첫번째 가용영역 선택: " azs_choice1
	azs1=$(sed -n "${azs_choice1}p" "azs.info")
	sed -i "s/az-1 = \"[^\"]*\"/az-1 = \"$azs1\"/g" ./modules/vpc/main.tf
	read -p "두번째 가용영역 선택: " azs_choice2	
	azs2=$(sed -n "${azs_choice2}p" "azs.info")
	sed -i "s/az-2 = \"[^\"]*\"/az-2 = \"$azs2\"/g" ./modules/vpc/main.tf
elif [ $mulbiAzs == "n" ];then
	read -p "가용영역 선택: " azs_choice
	azs=$(sed -n "${azs_choice}p" "azs.info")
	sed -i "s/az-1 = \"[^\"]*\"/az-1 = \"$azs\"/g" ./modules/vpc/locals.tf
fi

#프로젝트명 입력
read -p "프로젝트명 입력: " prjt

#VPC 대역 설정
vpcCidr="10.0.0.0/16"
read -p "VPC IP 대역 설정[Default:10.0.0.0/16]: " vpcCidrInput
echo $vpcCidrInput
if [ -n "$vpcCidrInput" ];then
	vpcCidr="$vpcCidrInput"
fi

cat <<EOF >> main.tf

# VPC Count
module "main-vpc" {
  source     = "./modules/vpc"
  naming     = "$prjt"
  cidr_block = "$vpcCidr"
}
EOF

#서브넷 개수 설정
echo "테스트 환경의 기본 서브넷"
echo "퍼블릭: 1"
echo "프라이빗: 2"

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

#인스턴스 생성
cat <<EOF >> main.tf

# Bastion Host
module "bastion-host" {
  source = "./modules/ec2"
  myIp   = "$myIp/32"
  defVpcId = module.main-vpc[0].def-vpc-id
}
EOF

aws ec2 describe-instance-type-offerings --location-type "availability-zone" --region us-east-1 --query "InstanceTypeOfferings[?starts_with(InstanceType, 't2')].[InstanceType]" --output text | sort | uniq > instance.type
echo "앤서블 서버 인스턴스 사양 선택"
echo "===================="
cat -n "instance.type"
echo "===================="
read -p "번호를 선택해주세요: " iType

#설정 파일 출력
echo "==========main.tf=========="
cat main.tf
echo "==========================="
echo "============ec2============"
cat ./moudles/ec2/main.tf
echo "==========================="

#내용 확인 선택문
read -p "위 내용이 맞습니까?[y/n]: " check
if [ $check == "y" ];then
	echo "환경 설정이 완료되었습니다."
	break	#루프문 탈출
fi

#루프문 끝
done
