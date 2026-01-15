Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Applications

try {
    Connect-MgGraph -Identity -NoWelcome -ErrorAction Stop

    $apps = Get-MgApplication -ErrorAction Stop

    $threshold = (Get-Date).AddDays(7)

    $SecretsToAlert = foreach ($app in $apps) {
        foreach ($secret in $app.PasswordCredentials) {
            if ($secret.EndDateTime -le $threshold) {
                [PSCustomObject]@{
                    AppDisplayName = $app.DisplayName
                    SecretKeyId    = $secret.KeyId
                    EndDate        = $secret.EndDateTime.ToString("dd-MM-yyyy")
                    DaysRemaining  = ($secret.EndDateTime - (Get-Date)).Days
                    Status         = if ($secret.EndDateTime -lt (Get-Date)) {
                        "Expired"
                    } else {
                        "ExpiringSoon"
                    }
                }
            }
        }
    }

    $AlertObjects = $SecretsToAlert |
        Where-Object AppDisplayName -Like "*test*" |
        Select-Object AppDisplayName, SecretKeyId, EndDate, DaysRemaining, Status

    $result = @{
        status = "Success"
        data   = @($AlertObjects)  # guarantees array
    }

    $result | ConvertTo-Json -Depth 4 | Write-Output
}
catch {
    $errorResult = @{
        status       = "Error"
        errorMessage = $_.Exception.Message
        errorType    = $_.Exception.GetType().FullName
    }

    $errorResult | ConvertTo-Json -Depth 3 | Write-Output
}