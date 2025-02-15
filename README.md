# Interactive AWS EKS Pod Capacity Calculator

## Overview

This simple Bash script provides an interactive, colorized interface to calculate the maximum number of pods an AWS EC2 instance (used as an EKS node) can support.

The calculation is based on the AWS VPC CNI plugin formula:

```
Maximum Pods = (Max ENIs × (IPv4 Addresses per ENI - 1)) + 2
```

## Features

- **Interactive Prompts:** Step-by-step guidance for easy usage
- **Colorized Output:** A polished, visually appealing interface using ANSI colors
- **Dynamic Filtering:** Enter instance type filters to narrow down results
- **Detailed Calculation:** See the breakdown of the pod capacity formula
- **AWS CLI Integration:** Fetches real-time data from AWS using your configured CLI profiles

## Prerequisites

- **AWS CLI:** Must be installed and configured with your AWS credentials
  - [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- **Bash Shell:** The script is written in Bash (works on Linux, macOS, or Windows with WSL)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/richinex/aws-eks-pod-capacity-calculator.git
   ```

2. Navigate to the project directory:
   ```bash
   cd aws-eks-pod-capacity-calculator
   ```

3. Make the script executable:
   ```bash
   chmod +x eks_pod_calculator.sh
   ```

## Usage

Run the script by executing:
```bash
./eks_pod_calculator.sh
```

## How It Works

1. **AWS Profile Prompt:**
   - You'll be asked to enter your AWS CLI profile name (e.g., default, myprofile)

2. **Instance Filter Prompt:**
   - Enter an instance type filter (e.g., m5.*)
   - Press ENTER to list all instance types

3. **Instance Type Selection:**
   - The script fetches matching instance types and displays them in columns with numbers
   - Enter the number corresponding to your desired instance type

4. **Calculation:**
   - The script retrieves network specifications (Max ENIs and IPv4 addresses per ENI)
   - Calculates maximum pods using the formula above

5. **Output:**
   - Displays calculated maximum pods
   - Shows detailed calculation steps
   - Provides important notes about system reservations

## Example Output

```
╔════════════════════════════════════════════════════════════╗
║          Interactive AWS EKS Pod Calculator                 ║
╚════════════════════════════════════════════════════════════╝

Pod Calculation Formula:
  Maximum Pods = (Max ENIs × (IPv4 Addresses per ENI - 1)) + 2

Where:
  • Max ENIs: Maximum network interfaces
  • IPv4 Addresses per ENI: Maximum private IPv4 addresses per interface
  • -1: Reserved for the primary IP on each ENI
  • +2: Additional system overhead allocation

Enter an instance type filter (e.g., m5.*, c5.*, t3.*): m5.*

Available Instance Types:
────────────────────────────────────
  1) m5.large              4) m5.4xlarge            7) m5.16xlarge
  2) m5.xlarge             5) m5.8xlarge            8) m5.24xlarge
  3) m5.2xlarge            6) m5.12xlarge

Select an instance type (1-8): 1

Selected: m5.large

Instance Specifications
╔════════════════════════════════════════════════════════════╗
║ Instance Type:        m5.large                             ║
║ Maximum ENIs:         3                                    ║
║ IPv4 Addresses/ENI:   10                                   ║
╠════════════════════════════════════════════════════════════╣
║ Maximum Pods:         29                                   ║
╚════════════════════════════════════════════════════════════╝

Important Notes:
- The actual available pod capacity will be lower than 29
- System components reserve some pods:
  - kube-system pods
  - AWS CNI plugin
  - kube-proxy
  - CoreDNS

Calculation Details:
- Step 1: ENIs × (IPs per ENI - 1) = 3 × (10 - 1)
- Step 2: Add 2 for system overhead
- Final calculation: 3 × (10 - 1) + 2 = 29
```

Important Note:
The actual available pod capacity may be lower due to system-reserved pods.