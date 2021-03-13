# Firewalld Country Blocker

Bash script to automate the dpwnload foc ountry IP ranges from https://www.ipdeny.com and load them into the DROP zone in firewalld.

Use it at your own risk, it works for me on my environment, test it before using it.
Reloading the firewalld might cause statfull connections to be drop, so be aware.

Needs to run as root, in order to be able to create IP Sets and add them to the DROP zone.

Script acts as a Blacklist, meaning that will block the countries you configure in the "Countries" variable. all other countries will still be allowed.

The script relies on IPDeny country IP ranges. If a malicious useris using a VPN from a country not blocked by the firewall he will still have access to your server.
