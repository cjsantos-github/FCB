#!/bin/bash
#
# Firewalld Country Blocker
# Author: Carlos Santos
# Created: 13th May 2021
# Version: 1.0
#
# Description:
#
# Script to automate the download of country IP ranges from ipdeny.com
# and load those ranges into Firewalld DROP zone
#
# Works with IPv4 and IPv6
#
# Needs to run as a root
#
################

#
# Config
#
version="1.0"

# Colors
nocolor='\e[0m'
blue='\e[0;94m'
green='\e[0;92m'
red='\e[0;31m'
yellow='\e[1;33m'

# Banner
banner="\n${blue}Firewalld Country Blocker - FCB $version${nocolor}"

# List Name
ListName="CountryBlackList"

# Use aggreagted zones for better performance
IPDeny4="https://www.ipdeny.com/ipblocks/data/aggregated/"
IPDeny6="https://www.ipdeny.com/ipv6/ipaddresses/aggregated/"

# List size, will depend on how many IP ranges you want to load into firewalld zones
ListSize=100000

# Get Firewall-cmd location
firewallcmd=`which firewall-cmd`

# ISO codes of countries to block separated by espaces: ( aa bb cc dd )
# Works as a Blacklist, blocks countries listed below, allow all others
Countries=( cn ru )

### Config End

#
# Function: Create IP Set if it doesn't exist
#
Create_IPSet () {
    # Check what type of IP Set we're creating IPv4 or IPv6
    if [ $1 == "v4" ]
    then
        local inet="inet"
        local ipsettype="IPv4"
    else
        local inet="inet6"
        local ipsettype="IPv6"
    fi

    local FullListName="$ListName-$ipsettype"

    # Check if IP Set already exists
    if [[ -z `$firewallcmd --get-ipsets | grep $FullListName`  ]]
    then
        echo -e "Creating IP set named ${yellow}$FullListName${nocolor} for $ipsettype with $ListSize entries"
        $firewallcmd --permanent --new-ipset $FullListName --type hash:net --option family=$inet --option hashsize=4096 --option maxelem=$ListSize > /dev/null
    else
        echo -e "IP Set $FullListName already exists, skipping creation."
    fi
}

#
# Function:  Delete IP Set
#
Delete_IPSet () {
    # Check what type of IP Set we are creating
    if [ $1 == "v4" ]
    then
        local inet="inet"
        local ipsettype="IPv4"
    else
        local inet="inet6"
        local ipsettype="IPv6"
    fi

    local FullListName="$ListName-$ipsettype"

    # Check if the IPSet exists
    if [[ -z `$firewallcmd --get-ipsets | grep $FullListName` ]]
    then
        echo -e "${red}IPSet ${yellow}$FullListName${red} does not exist.${nocolor}"

        # Only set reload flag to no if there isn't a previous reload request
        if [ "$reloadfw" != "yes" ]; then reloadfw="no"; fi
    else
        echo -e "${red}Removing IPSet ${yellow}$FullListName${red} from drop Zone"
        $firewallcmd --permanent --zone drop --remove-source ipset:$FullListName > /dev/null
        echo -e "${red}Removing IPSet ${yellow}$FullListName${nocolor}"
        $firewallcmd --permanent --delete-ipset $FullListName > /dev/null

        # Set flag to reload firewall
        reloadfw="yes"
    fi

}

#
# Function:  Download zones files
#
DownloadZones () {
    # Check what zone type to download
    if [ $1 == "v4" ]
    then
        local url=$IPDeny4
        local zonetype="IPv4"
    else
        local url=$IPDeny6
        local zonetype="IPv6"
    fi

    local FullListName="$ListName-$zonetype"

    for i in "${Countries[@]}"
    do
        echo -e "${green}Downloading $zonetype zone for:${yellow}$i${nocolor}"
        curl -o "$i-$zonetype.zone" "$url$i-aggregated.zone"  > /dev/null 2> /dev/null
    done


    # Load Zones into Firewall
    for file in *$zonetype.zone
    do
        echo -e "${green}Adding $zonetype ranges from $file to IP set ${yellow}$FullListName${nocolor}"
        $firewallcmd --permanent --ipset $FullListName --add-entries-from-file $file > /dev/null
    done

    # Delete Zone files
    rm ./*.zone

    # Add IPset to drop Zone
    $firewallcmd --permanent --zone=drop --add-source ipset:$FullListName > /dev/null
}

#
# Execution starts here
#
echo -e "\n$banner"
# Show how to use the script
ShowUsage() {
    echo -e "Usage: fcb.sh ACTION TYPE"
    echo -e "${yellow}Actions:${nocolor}"
    echo -e "\tcreate - Create IPSet"
    echo -e "\tdelete - Delete existing IPSet"
    echo -e "${yellow}Types:${nocolor}"
    echo -e "\tipv4 - Create or delete an IPv4 IPSet"
    echo -e "\tipv6 - Create or delete an IPv6 IPSet"
    echo -e "\tipv46 - Create or delete IPv4 and IPv6 IPSets"
    echo ""
    exit
}

# Check command line options
if [ $# -lt 2 ]
then
    ShowUsage
fi

# Check first arguement
case $1 in
    delete)
        action="delete"
        ;;
    create)
        action="create"
        ;;
    *)
        ShowUsage
        ;;
esac

# Check second argument
case $2 in
    ipv4)
        ipv4="yes"
        ipv6=""
        ;;
    ipv6)
        ipv4=""
        ipv6="yes"
        ;;
    ipv46 | ipv64)
        ipv4="yes"
        ipv6="yes"
        ;;
    *)
        ShowUsage
        ;;
esac

if [ "$action" == "delete" ]
then
    if [ "$ipv4" == "yes" ]
    then
        Delete_IPSet v4
    fi
    if [ "$ipv6" == "yes" ]
    then
        Delete_IPSet v6
    fi

elif [ "$action" == "create" ]
    then
    if [ "$ipv4" == "yes" ]
    then
        Create_IPSet v4
        DownloadZones v4
    fi
    if [ "$ipv6" == "yes" ]
    then
        Create_IPSet v6
        DownloadZones v6
    fi
fi

# Delete action might not need a FW reload
# Create action always need to reload FW
if [ "$action" == "create" ] || [ "$reloadfw" == "yes" ]
then
    echo -e "${red}Reloading Firewall${nocolor}"
    $firewallcmd --reload > /dev/null
fi
