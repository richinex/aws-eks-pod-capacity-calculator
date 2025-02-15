#!/bin/bash
# interactive_calc_max_pods_with_profile_colored.sh
#
# This script:
# 1. Prompts you for an AWS CLI profile (from your ~/.aws/credentials).
# 2. Prompts for an instance type filter (e.g., m5.*, c5.*, t3.*).
# 3. Fetches matching instance types using the AWS CLI with the given profile.
# 4. Displays a numbered, colorized menu in columns for selection.
# 5. Retrieves the maximum number of ENIs and IPv4 addresses per ENI.
# 6. Calculates and displays the maximum pods using:
#
#      Maximum Pods = (Max ENIs * (IPv4 Addresses per ENI - 1)) + 2
#
# Ensure AWS CLI is installed and you have the required permissions.
# -----------------------------------------------------------------------------

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'    # No Color
BOLD='\033[1m'

# Function to check if AWS CLI is installed.
function check_aws_cli() {
    echo -e "${CYAN}Checking AWS CLI installation...${NC}"
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}Error:${NC} AWS CLI is not installed. Please install it and configure your profiles."
        exit 1
    fi
    echo -e "${GREEN}✓ AWS CLI is installed${NC}\n"
}

# Display fancy header
function display_header() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}          ${BOLD}Interactive AWS EKS Pod Calculator${NC}              ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Display formula explanation
function display_formula() {
    echo -e "${CYAN}Pod Calculation Formula:${NC}"
    echo -e "${YELLOW}  Maximum Pods = (Max ENIs * (IPv4 Addresses per ENI - 1)) + 2${NC}"
    echo
    echo -e "${CYAN}Where:${NC}"
    echo -e "  • ${YELLOW}Max ENIs${NC}: Maximum number of network interfaces"
    echo -e "  • ${YELLOW}IPv4 Addresses per ENI${NC}: Maximum private IPv4 addresses per interface"
    echo -e "  • ${YELLOW}- 1${NC}: Reserved for the primary IP on each ENI"
    echo -e "  • ${YELLOW}+ 2${NC}: Additional system overhead allocation"
    echo
}

# Main Program Start
display_header
check_aws_cli
display_formula

# Prompt for AWS CLI profile name.
echo -en "${YELLOW}Enter your AWS CLI profile name (e.g., default, myprofile): ${NC}"
read -r AWS_PROFILE
if [ -z "$AWS_PROFILE" ]; then
    echo -e "${RED}No profile specified. Exiting.${NC}"
    exit 1
fi
echo -e "${GREEN}Using AWS profile: ${AWS_PROFILE}${NC}"
echo -e "${BLUE}-----------------------------------------------${NC}\n"

# Prompt for an instance type filter.
echo -en "${YELLOW}Enter an instance type filter (e.g., m5.*, c5.*, t3.*) or press ENTER to list all: ${NC}"
read -r FILTER_INPUT
if [ -z "$FILTER_INPUT" ]; then
    FILTER_INPUT="*"
fi
echo -e "\n${GREEN}Fetching instance types matching filter: ${FILTER_INPUT} ...${NC}"

# Fetch instance types using AWS CLI with the specified profile.
INSTANCE_TYPES=$(aws ec2 describe-instance-types \
    --profile "$AWS_PROFILE" \
    --filters "Name=instance-type,Values=${FILTER_INPUT}" \
    --query "InstanceTypes[].InstanceType" \
    --output text)

# Check if any instance types were returned.
if [ -z "$INSTANCE_TYPES" ]; then
    echo -e "${RED}No instance types found with filter '${FILTER_INPUT}'.${NC}"
    exit 1
fi

# Convert the space-delimited list into an array.
read -r -a INSTANCE_ARRAY <<< "$INSTANCE_TYPES"

# Display a numbered menu (printed only once) in columns.
echo -e "\n${CYAN}Available Instance Types:${NC}"
echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"

# Configure columns
COLUMNS=3
COLUMN_WIDTH=25
TOTAL_ITEMS=${#INSTANCE_ARRAY[@]}
ROWS=$(( (TOTAL_ITEMS + COLUMNS - 1) / COLUMNS ))

for ((i = 0; i < ROWS; i++)); do
    for ((j = 0; j < COLUMNS; j++)); do
        INDEX=$(( j * ROWS + i ))
        if [ $INDEX -lt $TOTAL_ITEMS ]; then
            # Print each item with its number
            printf "${GREEN}%3d)${NC} %-${COLUMN_WIDTH}s" "$((INDEX + 1))" "${INSTANCE_ARRAY[$INDEX]}"
        fi
    done
    echo  # New line after each row
done

echo  # Extra spacing

# Prompt the user to select an instance type by number.
echo -ne "${YELLOW}Select an instance type by number (1-${TOTAL_ITEMS}): ${NC}"
read -r SELECTION

# Validate selection: must be a positive number within range.
if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt "$TOTAL_ITEMS" ]; then
    echo -e "${RED}Invalid selection. Please run the script again and choose a valid number.${NC}"
    exit 1
fi

SELECTED_INSTANCE=${INSTANCE_ARRAY[$((SELECTION - 1))]}
echo -e "\n${GREEN}Selected Instance Type: ${BOLD}$SELECTED_INSTANCE${NC}"
echo -e "${BLUE}-----------------------------------------------${NC}"

# Retrieve the network specifications for the chosen instance type.
echo -e "${CYAN}Retrieving network specifications for instance type: ${SELECTED_INSTANCE} ...${NC}"
SPEC_OUTPUT=$(aws ec2 describe-instance-types \
    --profile "$AWS_PROFILE" \
    --instance-types "$SELECTED_INSTANCE" \
    --query "InstanceTypes[].{MaxENI: NetworkInfo.MaximumNetworkInterfaces, IPv4addr: NetworkInfo.Ipv4AddressesPerInterface}" \
    --output text)

if [ -z "$SPEC_OUTPUT" ]; then
    echo -e "${RED}Error: Could not retrieve data for instance type '${SELECTED_INSTANCE}'.${NC}"
    exit 1
fi

# Parse the returned values into variables.
read -r MAX_ENI IPV4_PER_ENI <<< "$SPEC_OUTPUT"

echo -e "${GREEN}Instance Type: ${SELECTED_INSTANCE}${NC}"
echo -e "${GREEN}Maximum ENIs: ${MAX_ENI}${NC}"
echo -e "${GREEN}IPv4 Addresses per ENI: ${IPV4_PER_ENI}${NC}"

# Calculate maximum pods using the formula:
#   Maximum Pods = (Max ENIs * (IPv4 Addresses per ENI - 1)) + 2
MAX_PODS=$(( MAX_ENI * (IPV4_PER_ENI - 1) + 2 ))

echo -e "${BLUE}-----------------------------------------------${NC}"
echo -e "${CYAN}Calculated Maximum Pods for ${SELECTED_INSTANCE}:${NC}"
echo -e "${YELLOW}${MAX_PODS}${NC}"
echo -e "${CYAN}===============================================${NC}\n"

# Display calculation details
echo -e "${PURPLE}Calculation Details:${NC}"
echo -e "• Step 1: ${GREEN}Max ENIs × (IPv4 Addresses per ENI - 1) = $MAX_ENI × ($IPV4_PER_ENI - 1)${NC}"
echo -e "• Step 2: ${GREEN}Add 2 for system overhead${NC}"
echo -e "• Final Calculation: ${GREEN}$MAX_ENI × ($IPV4_PER_ENI - 1) + 2 = $MAX_PODS${NC}"
echo -e "\n${YELLOW}Important Note:${NC}"
echo -e "The actual available pod capacity may be lower due to system-reserved pods (e.g., kube-system, AWS CNI, kube-proxy, CoreDNS).\n"
