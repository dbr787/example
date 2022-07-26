#!/bin/bash

set -e

output_only=0
destroy=0
invocation="$0 $@"
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -o|--output-only) output_only=1 ;;
        -d|--destroy) destroy=1 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if (( output_only + destroy > 1 ))
then
    echo "only one flag is allowed" >&2
    exit 1
fi

# set colours for print output
bl=$(tput setaf 4)
gr=$(tput setaf 2)
re=$(tput setaf 1)
bo=$(tput bold)
no=$(tput sgr0)

printf "${bl}${bo}Executing script:${no}${bl} ${invocation}${no}\n"

start=$(date "+%F %T")
start_s=$(date +%s)

if (( $output_only == 0 )); then
    printf "${bl}${bo}Checking Authentication...${no}\n"
    
    if ! aws sts get-caller-identity
    then
        aws sso login
    else
        printf "${bl}${bo}Already Authenticated...${no}\n"
    fi

    start=$(date "+%F %T")
    start_s=$(date +%s)

    # format terraform code
    printf "${bl}${bo}Executing terraform fmt...${no}\n"
    terraform -chdir="./terraform" fmt -recursive

    if (( $destroy == 1 )); then
        # destroy terraform project
        printf "${bl}${bo}Executing terraform destroy...${no}\n"
        terraform -chdir="./terraform" destroy -auto-approve
    fi

    if (( $destroy == 0 )); then
        
        # init terraform project
        printf "${bl}${bo}Executing terraform init...${no}\n"
        terraform -chdir="./terraform" init

        # apply terraform project
        printf "${bl}${bo}Executing terraform apply...${no}\n"
        terraform -chdir="./terraform" apply -auto-approve

    fi

fi

# get terraform output and set vars
printf "${bl}${bo}Getting terraform output...${no}\n"
terraform_output_json=$(terraform -chdir="./terraform" output -json)
if [[ $terraform_output_json != "{}" ]]; then
    allowed_ip_cidrs=$(echo $terraform_output_json | jq -r '.allowed_ip_cidrs.value[]')
    user_ip_address=$(dig +short myip.opendns.com @resolver1.opendns.com)
    linux_nodes=$(echo $terraform_output_json | jq '.buildkite.value[] | select(.platform=="linux")')
fi

end=$(date "+%F %T")
end_s=$(date +%s)
duration_s=$((end_s-start_s))
duration_hms=$(echo $duration_s | awk '{printf "%d:%02d:%02d", $1/3600, ($1/60)%60, $1%60}')

# print final summary
printf "\n"
printf "${gr}${bo}Script completed successfully:${no}${gr} ${invocation}${no}\n"
printf "${gr}Start:               ${start}${no}\n"
printf "${gr}End:                 ${end}${no}\n"
printf "${gr}Duration:            ${duration_hms}${no}\n"

if [[ $terraform_output_json != "{}" ]]; then

    if [[ $allowed_ip_cidrs == *"${user_ip_address}"* ]]; then
        printf "${gr}Your IP is:          ${user_ip_address}/32${no}\n"
        printf "${gr}Allowed IPs include: ${allowed_ip_cidrs}${no}\n"
    else
        printf "${re}Your IP is:          ${user_ip_address}/32${no}\n"
        printf "${re}Allowed IPs include: ${allowed_ip_cidrs}${no}\n"
    fi

    printf "\n"
    printf "${gr}${bo}================================================================================================================================${no}\n"
    printf "\n"

    echo $linux_nodes | jq -c | while read i; do
        instance_id=$(echo $i | jq -r '.instance_id')
        instance_name=$(echo $i | jq -r '.instance_name')
        instance_state=$(echo $i | jq -r '.instance_state')
        public_ip=$(echo $i | jq -r '.public_ip')
        ssh_command=$(echo $i | jq -r '.ssh_command')
        ssh_command=${ssh_command/'./'/'./terraform/'}
        if [ "$instance_state" != "running" ] && [ -z "$public_ip"]; then
            printf ""$gr$bo"%-40s"$gr$bo"%s$no\n" "SSH to ${instance_name}: " "Instance is ${instance_state}. Run this command to start: ${no}${gr}aws ec2 start-instances --instance-ids ${instance_id}"
        else
            printf ""$gr$bo"%-40s"$no$gr"%s$no\n" "SSH to ${instance_name}: " "${ssh_command}"
        fi
    done

    printf "\n"
    printf "${gr}${bo}================================================================================================================================${no}\n"

fi

printf "\n"
