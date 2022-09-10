#function Get-IP-Info {

    Param(
    
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        <#
        [ValidatePattern] bracketed Regular expression tests for valid internet routable ipv4 address. 
        Tests for valid ipv4 address and filters out: 
        Local Identification Block 0.0.0.0/8
        Private Use Blocks 10.0.0.0/8, 192.168.0.0/16, 172.16.0.0/12
        Link Local Block 169.254.0.0/16
        Loopback Block 127.0.0.0/8
        Multicast Blocks 224.0.0.0/8 - 239.0.0.0/8
        Future Use Blocks 240.0.0.0/8-255.0.0.0/8
        And any address beggining or ending in 0 (i.e. 0.1.1.0, 0.1.1.1, 1.1.1.0)
        #>
        [ValidatePattern("^(?:2[0-2][0-3]|1[0-9][0-9]|[1-9][0-9]|[1-9])(?<!10|127)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(?<!192\.168)(?<!169\.254)(?<!172\.(1[6-9]|2\d|3[0-1]))\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(?<!0)$", ErrorMessage = 'You entered an invalid internet routable IPv4 address. Please try again with a different address.')]
        [string]$IP,
        
        [Parameter()]
        [switch]$j

       # [Parameter()]
       # [string]$Path
    )

    Begin {
       
        <#
        # Validate the $Path if set and $j is true. If not set, default $Path to User desktop if $j switch = true
        if ($j) {
            if ($Path) {
                $PathValidated = $false
                while (-not $PathValidated){
                    if (Test-Path $Path) {
                        if ((Get-Item $Path).PSisContainer) {
                            $PathValidated = $true
                        } else {
                            Write-Host 'You must provide a path to a folder. The path cannot be a file.'
                            $Path = Read-Host -Prompt 'Please input a valid path'
                        }
                        
                    } else {
                        Write-Host "Unable to locate: $Path"
                        $Path = Read-Host -Prompt 'Please input a valid path'
                    }
                } 
                
            }
        } else {
            $Path = [Environment]::GetFolderPath("Desktop")
        }
        #>

        # Base url api for WHOIS through arin.net api
        $arin_api_url = 'http://whois.arin.net/rest'

        # Header for Arin.net api
        $arin_header = @{"Accept"="application/xml"}

        # Base url for geolocation data through ip-api.com api
        $ip_api_url = 'http://ip-api.com/xml'

        # Base url for weather data through open-meteo.com api
        $open_meteo_api_url = "https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true&temperature_unit=fahrenheit&windspeed_unit=mph&precipitation_unit=inch&timezone=auto"
    }

    Process {
        
        # Get Whois Data
        $whois_url = "$arin_api_url/ip/$IP"
        $whois_inf = Invoke-Restmethod $whois_url -Headers $arin_header

        # For Testing... Remove in final#
        Write-Host ($whois_info.net | Out-String)
        # For Testing... Remove in final#

        #Get GeoLoc Data 
        $geo_loc_url = "$ip_api_url/$IP"
        $geo_loc_inf = Invoke-RestMethod $geo_loc_url 

        # For Testing... Remove in final#
        Write-Host ($geo_loc_inf.query | Out-String)
        # For Testing... Remove in final#

        # Read and set longitude and latitude
        $latitude = ($geo_loc_inf.query.lat)
        $longitude = ($geo_loc_inf.query.lon)

        # Get Weather data
        $weather_inf = Invoke-RestMethod $open_meteo_api_url

        # For Testing... Remove in final#
        Write-Host ($weather_inf.current_weather | Out-String)
        # For Testing... Remove in final#





    }
#}