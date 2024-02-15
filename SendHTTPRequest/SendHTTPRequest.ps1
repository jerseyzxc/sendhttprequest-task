Trace-VstsEnteringInvocation $MyInvocation

try {
    # Get user inputs
    $HttpMethod = (Get-VstsInput -Name httpMethod -Require).ToUpper() # Convert HttpMethod to uppercase

    $HttpUri = (Get-VstsInput -Name httpUri -Require).Trim()
    $HttpHeadersJson = (Get-VstsInput -Name httpHeaders -Require).Trim()
    $BodyPayload = (Get-VstsInput -Name bodyPayload).Trim()
    $UseProxy = Get-VstsInput -Name useProxy -Require
    $ProxyAddress = (Get-VstsInput -Name proxyAddress).Trim()
    $UseProxyCredentials = Get-VstsInput -Name useProxyCredentials
    $ProxyUsername = (Get-VstsInput -Name proxyUsername).Trim()
    $ProxyPassword = (Get-VstsInput -Name proxyPassword).Trim()

    # For compatibility with the legacy handler implementation, set the error action
    # preference to continue. An implication of changing the preference to Continue,
    # is that Invoke-VstsTaskScript will no longer handle setting the result to failed.
    $global:ErrorActionPreference = 'Continue'

    $HttpHeaders = @{}

    # Check if provided headers is a valid JSON object
    $IsHeadersValidJson = $false
    try {
        ConvertFrom-Json -InputObject $HttpHeadersJson -ErrorAction Stop
        $IsHeadersValidJson = $true
    } catch {
        $IsHeadersValidJson = $false
    }

    if ($IsHeadersValidJson -eq $true) {
        # Convert HttpHeaders from JSON string to a dictionary object compatible with IDictionary
        (ConvertFrom-Json $HttpHeadersJson).psobject.properties | ForEach-Object { $HttpHeaders[$_.Name] = $_.Value }
    }

    $Params = @{
        Uri = $HttpUri
        Headers = $HttpHeaders
        Method = $HttpMethod
    }

    # Check if the HTTP method is POST, PUT, or PATCH, and add Body Payload if not empty
    if (($HttpMethod -match 'POST|PUT|PATCH') -and (![string]::IsNullOrWhiteSpace($BodyPayload))) {
        
        # Check if provided payload is a valid JSON
        $IsPayloadValidJson = $false
        try {
            ConvertFrom-Json -InputObject $BodyPayload -ErrorAction Stop
            $IsPayloadValidJson = $true
        } catch {
            $IsPayloadValidJson = $false
        }

        if ($IsPayloadValidJson) {
            Write-Host "##[debug] '$($HttpMethod)' method was selected. Adding Body Payload to the request ..."
            $Params['Body'] = $BodyPayload
        } else {
            Write-Host "##[error] Provided Body Payload is not a valid JSON object."
            throw
        }    
    }

    # If Proxy usage is required, proceed with setting it up
    if ($UseProxy -eq "true" -and ![string]::IsNullOrWhiteSpace($ProxyAddress)) {
        Write-Host "##[debug] Proxy option was selected. Setting up proxy $($ProxyAddress) for the request ..."
        $Params['Proxy'] = $ProxyAddress
    }

    # If Proxy credentials were provided, then proceed with configuring them
    if ($UseProxy -eq "true" -and $UseProxyCredentials -eq "true" -and ![string]::IsNullOrWhiteSpace($ProxyUsername)) {
        $pass = ''

        if (![string]::IsNullOrWhiteSpace($ProxyPassword)) {
            $pass = ConvertTo-SecureString $ProxyPassword -AsPlainText -Force  
        }
        
        $cred = New-Object System.Management.Automation.PSCredential -ArgumentList $ProxyUsername, $pass

        Write-Host "##[debug] Proxy credentials have been provided. Configuring credentials: `nUsername: $($ProxyUsername) `nPassword: $($ProxyPassword)"
        $Params['ProxyCredential'] = $cred
    }

    # Try to Invoke a request and log
    try {
        Write-Host "##[debug] Trying to send a $($HttpMethod) request to $($HttpUri) ..."    
        $Response = Invoke-WebRequest @Params
        Write-Host "##[debug] Successfully executed the request with HTTP status code: $($Response.StatusCode)."
        Write-Host "##[section] Initializing 'responseBody' and 'statusCode' variables ..."
        Write-Host "##vso[task.setvariable variable=responseBody;]$($Response.Content)"
        Write-Host "##vso[task.setvariable variable=statusCode;]$($Response.StatusCode)"
        Write-Host "##[debug] Response Body: `n$($Response.Content)"
    } catch {
        $OutputCode = 0
        if ($_.Exception.Response.StatusCode.value__ -gt 0) {
            $OutputCode = $_.Exception.Response.StatusCode.value__
        }

        Write-Host "##[error] Status: '$($OutputCode)'."
        Write-Host "##[error] An error occurred while performing the request."
        Write-Host "##[error] $($_.Exception.Message)"

        "##vso[task.setvariable variable=statusCode;]$($OutputCode)"
    }


} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
