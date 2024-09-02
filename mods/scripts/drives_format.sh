#!/bin/bash

# ANSI color codes for formatting
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
NC="\033[0m"  # No color

# Function to list drives and partitions
list_drives() {
    clear
    echo -e "${BLUE}========================="
    echo -e "   Top-Level Drives List   "
    echo -e "=========================${NC}"
    echo -e "${GREEN}Top-Level View of Drives, Partitions, Sizes, and Filesystems:${NC}"
    echo ""
    lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -E '^[a-z]'  # Show drives, sizes, and file system types
    echo ""
}

# Function to prompt for drive selection and format options
format_drive() {
    echo -e "${BLUE}Select a drive to format (e.g., sda, sdb):${NC}"
    read -p "> " drive

    if [ ! -b "/dev/$drive" ]; then
        echo -e "${RED}Invalid drive. Please ensure the drive exists.${NC}"
        exit 1
    fi

    echo -e "${BLUE}Select the filesystem format type:${NC}"
    echo "1) XFS"
    echo "2) ZFS"
    read -p "> " fs_choice

    if [[ "$fs_choice" == "1" ]]; then
        fs_type="xfs"
        fs_command="mkfs.xfs"
    elif [[ "$fs_choice" == "2" ]]; then
        fs_type="zfs"
        fs_command="mkfs.zfs"
    else
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
    fi

    # Prompt for mount point name
    echo -e "${BLUE}Enter a name for the mount point (e.g., cat):${NC}"
    read -p "> " mount_name
    mount_point="/mnt/pg_${mount_name}"

    # Unmount the drive if it's mounted
    umount "/dev/$drive"1 &>/dev/null

    echo -e "${YELLOW}Wiping existing filesystem signatures on /dev/$drive...${NC}"
    wipefs -a "/dev/$drive"

    echo -e "${YELLOW}Overwriting beginning of /dev/$drive with zeros...${NC}"
    dd if=/dev/zero of="/dev/$drive" bs=1M count=1000 status=progress

    echo -e "${YELLOW}Creating new partition table and partition on /dev/$drive...${NC}"
    (echo g; echo n; echo 1; echo ""; echo ""; echo w) | fdisk "/dev/$drive"

    echo -e "${YELLOW}Formatting the partition with $fs_type...${NC}"
    if [[ "$fs_type" == "xfs" ]]; then
        mkfs.xfs "/dev/${drive}1" -f
    elif [[ "$fs_type" == "zfs" ]]; then
        apt-get install -y zfsutils-linux  # Ensure ZFS tools are installed
        mkfs.zfs "/dev/${drive}1"
    fi

    # Create the mount point directory
    mkdir -p "$mount_point"

    # Mount the formatted partition
    echo -e "${YELLOW}Mounting the partition to $mount_point...${NC}"
    mount "/dev/${drive}1" "$mount_point"

    echo -e "${GREEN}Drive /dev/$drive formatted and mounted at $mount_point.${NC}"
}

# Main menu function
main_menu() {
    while true; do
        list_drives
        format_drive
        read -p "[Press ENTER to Exit]" exit_prompt
        exit 0
    done
}

# Start the script
main_menu