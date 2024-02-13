# check all automatic services associated with PI are running
#
# loop through all the services that begin with "PI" and restart any that are set to
# automatic startup and are stopped, which exception of listed excluded services
#
# needs to be executed with elevation to be permitted to start services

Function ExcludeService
{
    param([string]$Name)

    # Include service names in array to exclude from restart
    # pishutev is the PI Shutdown Service, which is set to automatic but shouldn't be running constantly
    #
    # Return 1 if the service should be excluded, 0 if not

    # excluded service names
    $exclusions = @('pishutev','SQLAgent$SQLEXPRESS')

    # assume not excluded
    $check = 0

    ForEach ($exclude in $exclusions)
    {
        If ($exclude -eq $service.name)
        {
            $check = 1
        }
    }

    # return check code
    $check

}

# main

# loop through SQL and PI services
ForEach ($service in Get-Service | Where-Object {$_.DisplayName -like "SQL*" -Or $_.DisplayName -like "PI*"})
{

    [string]$checktime = Get-Date

    # check if service is stopped and set to automatic
    If ($service.status -eq 'Stopped' -and $service.StartType -like 'Automatic*')
    {
        $exclude = ExcludeService -Name $service.Name

        If ($exclude -eq 0)
        {
            Write-Output "$($service.name): $($service.status)"
            try {
                $errorflag = $false

                Write-Output "Starting $($service.name)"
                Start-Service -Name $service.servicename
            }
            catch {
                $errorflag = $true
                Write-Output "Unable to start $($service.name)"
            }
            finally {
                if ($errorflag -eq $false) {
                    Write-Output "Started $($service.name)"
                }
                else {
                    Write-Output "Failed $($service.name)"
                }
            }
            
        }
    }

}
