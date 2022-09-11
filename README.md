# ps-ip-data
 Powershell Script to pull data pertaining to a particular IP address

 To run, open a powershell prompt from the folder this script is located.

 In PowerShell use the "Get-IP-Info" function to run the script

 "Get-IP-Info" accepts the following commandline options:

 -IP
    The -IP tag does not need to be excplicitly stated. This will only allow a valid internet routable IP as an input. If no commandline option is given, the script will ask you for a valid IP.

    Example:   ~/ps-ip-data> Get-IP-Info 1.1.1.1
    Example 2: ~/ps-ip-data> Get-IP-Info -IP 1.1.1.1

-j

    The -j tag needs to be explicitly stated, but can be used without intially assigning a variable to -IP parameter. This tells the script to compile, and output the retreived data as a JSON object.

    Example:   ~/ps-ip-data> Get-IP-Info 1.1.1.1 -j
    Example 2: ~/ps-ip-data> Get-IP-Info -j