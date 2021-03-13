# Firewalld Country Blocker

Bash script to automate the download of country IP ranges from https://www.ipdeny.com and load them into the DROP zone in firewalld. Works with IPv4 and IPv6

**Use it at your own risk, it works for me on my environment, highly recommended to test it before using it in production.
Reloading the firewalld might cause statefull connections to be drop, so be aware.**

Needs to run as root, in order to be able to create IPSets and add them to the DROP zone.

Script acts as a Blacklist, meaning that will block the countries you configure in the "Countries" variable. all other countries will still be allowed.

The script relies on IPDeny country IP ranges. If a malicious useris using a VPN from a country not blocked by the firewall he will still have access to your server.


Usage: fcb.sh ACTION TYPE
Actions:
        create - Create IPSet
        delete - Delete existing IPSet
Types:
        ipv4 - Create or delete an IPv4 IPSet
        ipv6 - Create or delete an IPv6 IPSet
        ipv46 - Create or delete IPv4 and IPv6 IPSets

Example: sudo ./fcb.sh create ipv4
Will download the IP ranges from the countries defined in the variable "Countries", create a firewalld IPSet and add t to the Drop zone.

To remove the IPSet, just do: sudo ./fcb.sh delete ipv4

The default size for IP CIDRs is 100000, this can be changed in the script.

And finally, I'm not a developer or bash scripter, so I believe that the script can be improved and made more efficient.
I use it for myself, just sharing because I couldn't find many options to do this.

Enjoy...
