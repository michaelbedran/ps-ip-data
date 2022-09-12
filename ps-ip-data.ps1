<#
.SYNOPSIS
Retreives data pertaining to an internaet routable IPv4 address.
.DESCRIPTION
If an IP address does not match the schema for an internet routable address the script will throw an error informing the user. 
.PARAMETER IP
Mandatory perameter that can be supplied by commandline. Needs to be an internet routable IP address in order to pass validation.
Switch that when triggered by commandline will print data in the form of a JSON object, rather than friendly words.
.NOTES
Requires Powershell Core or Powershell 7 +
.EXAMPLE
Get-IP-Info 1.1.1.1
Get-IP-Info -IP 1.1.1.1
Get-IP-Info 1.1.1.1 -j
Get-IP-Info -j
#>

function Get-IP-Info {

    Param(
    
        [Parameter(Mandatory)]
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

    )

    Begin {

        Write-Host ''
        Write-Host ''
        Write-Host 'Script is now running..'
        Write-Host ''

        # Base url api for WHOIS through arin.net api
        $arin_api_url = 'http://whois.arin.net/rest'
        
        # Header for Arin.net api
        $arin_header = @{"Accept"="application/xml"}

        # Base url for geolocation data through ip-api.com api
        $ip_api_url = 'http://ip-api.com/xml'
        $ip_api_options = '?fields=status,message,country,countryCode,region,regionName,city,zip,lat,lon,timezone,offset,isp,org,as,asname,query'

        # Base url for weather data through open-meteo.com api 
        $open_meteo_api_url = 'https://api.open-meteo.com/v1/forecast?latitude='
        $open_meteo_api_url_2 = '&longitude='
        $open_meteo_api_url_3 = '&current_weather=true&temperature_unit=fahrenheit&windspeed_unit=mph&precipitation_unit=inch&timezone=auto'

        # Base api for WorldTimeAPI
        $world_time_api_url = 'http://worldtimeapi.org/api/timezone/'
    }

    Process {
        
        # Get Whois Data
        $whois_url = "$arin_api_url/ip/$IP"
        $whois_inf = Invoke-Restmethod $whois_url -Headers $arin_header     
        
        #Get GeoLoc Data 
        $geo_loc_url = "$ip_api_url/$IP$ip_api_options"
        $geo_loc_inf = Invoke-RestMethod $geo_loc_url 

        # Read and set longitude and latitude
        $lat = $geo_loc_inf.query.lat
        $lon = $geo_loc_inf.query.lon
        $latitude = [float]$lat
        $longitude = [float]$lon

        # Setting weather api to string due to error
        $open_meteo_api_url = $open_meteo_api_url+$latitude+$open_meteo_api_url_2+$longitude+$open_meteo_api_url_3
        
        # Get Weather data
        $weather_inf = Invoke-RestMethod $open_meteo_api_url
       
        # Set timezone
        $timezone = $geo_loc_inf.query.timezone
        
        # Get Ttime
        $time_inf = Invoke-RestMethod "$world_time_api_url/$timezone"

        # Store and calculate average latency of 10 pings to IP
        $ping = Test-Connection $IP -Count 10 -ea 0
        if ($ping) {
            $average_latency = ($ping | Measure-Object -Property Latency -Average).Average
        }
        else {
            $average_latency = "Ping to $IP failed" 
        }

        # Gathers and stores hop count
        $number_of_hops = ((Test-Connection -Traceroute $IP) | Measure-Object -Property Hop -Maximum).Maximum
        

        # Set Weather condition 
        switch ($weather_inf.current_weather.weathercode) {
            {0 -contains $_} { $weather = 'Clear Sky'}
            {1, 2, 3 -contains $_} { $weather = 'Mainly clear, partly cloudy, and overcast'}
            {45, 48 -contains $_} { $weather = 'Fog and depositing rime fog'}
            {51, 53, 55 -contains $_} { $weather = 'Drizzle: Light, moderate, and dense intensity'}
            {56, 57 -contains $_} { $weather = 'Freezing Drizzle: Light and dense intensity'}
            {61, 63, 65 -contains $_} { $weather = 'Rain: Slight, moderate and heavy intensity'}
            {66, 67 -contains $_} { $weather = 'Freezing Rain: Light and heavy intensity'}
            {71, 73, 75 -contains $_} { $weather = 'Snow fall: Slight, moderate, and heavy intensity'}
            {77 -contains $_} { $weather = 'Snow grains'}
            {80, 81, 82 -contains $_} { $weather = 'Rain showers: Slight, moderate, and violent'}
            {85, 86 -contains $_} { $weather = 'Snow showers slight and heavy'}
            {95 -contains $_} { $weather = 'Thunderstorm: Slight or moderate'}
            {96, 99 -contains $_} { $weather = 'Thunderstorm with slight and heavy hail'}    
            default {$weather = 'No Weather Data Available'}
        }
        
        # Set Wind Direction
        switch ($weather_inf.current_weather.winddirection) {
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
            { ($_ -ge 0 ) -and ( $_ -lt 11.25)}  {$local_wind_direction = 'North'}
            { ($_ -ge 11.25 ) -and ( $_ -lt 22.5)}  {$local_wind_direction = 'North by East'}
            { ($_ -ge 22.5 ) -and ( $_ -lt 33.75)}  {$local_wind_direction = 'North-Northeast'}
            { ($_ -ge 33.75 ) -and ( $_ -lt 45)}  {$local_wind_direction = 'Northeast by North'}
            { ($_ -ge 45 ) -and ( $_ -lt 56.25)}  {$local_wind_direction = 'Northeast'}
            { ($_ -ge 56.25 ) -and ( $_ -lt 67.5)}  {$local_wind_direction = 'Northeast by East'}
            { ($_ -ge 67.5 ) -and ( $_ -lt 78.75)}  {$local_wind_direction = 'East-Northeast'}
            { ($_ -ge 78.75 ) -and ( $_ -lt 90)}  {$local_wind_direction = 'East by North'}
            { ($_ -ge 90 ) -and ( $_ -lt 101.25)}  {$local_wind_direction = 'East'}
            { ($_ -ge 101.25 ) -and ( $_ -lt 112.5)}  {$local_wind_direction = 'East by South'}
            { ($_ -ge 112.5 ) -and ( $_ -lt 123.75)}  {$local_wind_direction = 'East-Southeast'}
            { ($_ -ge 123.75 ) -and ( $_ -lt 135)}  {$local_wind_direction = 'Southeast by East'}
            { ($_ -ge 135 ) -and ( $_ -lt 146.25)}  {$local_wind_direction = 'Southeast'}
            { ($_ -ge 146.25 ) -and ( $_ -lt 157.5)}  {$local_wind_direction = 'Southeast by South'}
            { ($_ -ge 157.5 ) -and ( $_ -lt 168.75)}  {$local_wind_direction = 'South-Southeast'}
            { ($_ -ge 168.75 ) -and ( $_ -lt 180)}  {$local_wind_direction = 'South by East'}
            { ($_ -ge 180 ) -and ( $_ -lt 191.25)}  {$local_wind_direction = 'South'}
            { ($_ -ge 191.25 ) -and ( $_ -lt 202.5)}  {$local_wind_direction = 'South by West'}
            { ($_ -ge 202.5 ) -and ( $_ -lt 213.75)}  {$local_wind_direction = 'South-Southwest'}
            { ($_ -ge 213.75 ) -and ( $_ -lt 225)}  {$local_wind_direction = 'Southwest by South'}
            { ($_ -ge 225 ) -and ( $_ -lt 236.25)}  {$local_wind_direction = 'Southwest'}
            { ($_ -ge 236.25 ) -and ( $_ -lt 247.5)}  {$local_wind_direction = 'Southwest by West'}
            { ($_ -ge 247.5 ) -and ( $_ -lt 258.75)}  {$local_wind_direction = 'West-Southwest'}
            { ($_ -ge 258.75 ) -and ( $_ -lt 270)}  {$local_wind_direction = 'West by South'}
            { ($_ -ge 270 ) -and ( $_ -lt 281.25)}  {$local_wind_direction = 'West'}
            { ($_ -ge 281.25 ) -and ( $_ -lt 292.5)}  {$local_wind_direction = 'West by North'}
            { ($_ -ge 292.5 ) -and ( $_ -lt 303.75)}  {$local_wind_direction = 'West-Northwest'}
            { ($_ -ge 303.75 ) -and ( $_ -lt 315)}  {$local_wind_direction = 'Northwest by West'}
            { ($_ -ge 315 ) -and ( $_ -lt 326.25)}  {$local_wind_direction = 'Northwest'}
            { ($_ -ge 326.25 ) -and ( $_ -lt 337.5)}  {$local_wind_direction = 'Northwest by North'}
            { ($_ -ge 337.5 ) -and ( $_ -lt 348.75)}  {$local_wind_direction = 'North-Northwest'}
            { ($_ -ge 348.75 ) -and ( $_ -le 360  )}  {$local_wind_direction = 'North by West'}            
            
            Default {'No Wind Data Available'}
        }
    }

    End {

        # Setting variables
        $owner_of_netblock = $whois_inf.net.orgRef.name
        $average_latency = "$average_latency ms"        
        $isp = $geo_loc_inf.query.isp
        $as_number_owner = $geo_loc_inf.query.asname
        $country = $geo_loc_inf.query.country
        $region_name = $geo_loc_inf.query.regionName
        $local_time = $time_inf.datetime
        $local_temp = $weather_inf.current_weather.temperature
        $local_windspeed = $weather_inf.current_weather.windspeed
        $local_windspeed = "$local_windspeed mph"

        # If it only takes one hop, hops in output is chnaged to hop. 
        $h = 'hops'
        if ($number_of_hops -eq 1)
        {
            $h='hop'
        }

        #output data as json object if flag marked, otherwise output in friendly manor. 
        if($j){
            $json_temp = @{
                'Ping Data' =@{
                    'Number of Hops'= $number_of_hops
                    'Average Ping Latency'= $average_latency
                    }
                
                'Network Data' =@{
                    'Netblock Owner'= $owner_of_netblock
                    'ISP'= $isp
                    'AS Number Owner'= $as_number_owner
                    }

                'Geo-Location Data' =@{
                    'Country'= $country
                    'Region'= $region_name
                    'Latitude'= $latitude
                    'Longitude'= $longitude
                    'Timezone'= $timezone
                    'Local Time'= $local_time
                    }

                'Weather Data' = @{
                    'Temp'= $local_temp
                    'Windspeed'= $local_windspeed
                    'Wind Direction'= $local_wind_direction
                    'Weather'= $weather
                    }
                }
            
                $json = $json_temp | ConvertTo-Json
                Write-Host ''
                Write-Host ''
                Write-Host $json 
                Write-Host ''
                Write-Host ''
        }
        else {
            Write-Host ''
            Write-Host ''
            Write-Host "It took $number_of_hops $h to get to this IP."
            Write-Host "The average latency of 10 pings to the IP was $average_latency."
            Write-Host "$owner_of_netblock owns the netblock."
            Write-Host "$as_number_owner is the owner associated to the AS Number."
            Write-Host "The ISP for this IP is $isp."
            Write-Host ''
            Write-Host "This IP is located in $country in the region of $region_name at the global coordinates of Latitude $latitude and Longitude $longitude."
            Write-Host ''

           if ($weather_inf){
            Write-Host "The local weather for $region_name is $weather. The current windspeed is $local_windspeed, with winds blowing due $local_wind_direction."
            } else {
            Write-Host 'We were unable to retrieve the weather data. Please try again later.'
           }
            Write-Host ''
            Write-Host "The local timezone for $region_name is $timezone."
            Write-Host "The current local date and time in $region_name is $local_time."
            Write-Host ''
            Write-Host ''
        }
    }
}




    
