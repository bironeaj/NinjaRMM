#Requires -Version 7
function Get-NinjaRMMJobs {
    <#
        .SYNOPSIS
            Gets jobs from the NinjaRMM API.
        .DESCRIPTION
            Retrieves jobs from the NinjaRMM v2 API.
        .OUTPUTS
            A powershell object containing the response.
    #>
    [CmdletBinding()]
    [OutputType([Object])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Uses dynamic parameter parsing.')]
    Param(
        # Filter by job type.
        [String]$jobType,
        # Filter by device triggering the alert.
        [Alias('df')]
        [String]$deviceFilter,
        # Filter by language tag.
        [Alias('lang')]
        [String]$languageTag,
        # Filter by timezone.
        [Alias('ts')]
        [String]$timeZone,
        # Filter by device ID.
        [Int]$deviceID
    )
    $CommandName = $MyInvocation.InvocationName
    $Parameters = (Get-Command -Name $CommandName).Parameters
    # Workaround to prevent the query string processor from adding an 'deviceid=' parameter by removing it from the set parameters.
    if ($deviceID) {
        $Parameters.Remove('deviceID') | Out-Null
    }
    try {
        $QSCollection = New-NinjaRMMQuery -CommandName $CommandName -Parameters $Parameters
        if ($deviceID) {
            Write-Verbose 'Getting device from NinjaRMM API.'
            $Device = Get-NinjaRMMDevices -deviceID $deviceID -ErrorAction SilentlyContinue
            if ($Device) {
                Write-Verbose "Retrieving jobs for $($Device.SystemName)."
                $Resource = "v2/device/$($deviceID)/jobs"
            } else {
                $DeviceNotFoundError = [ErrorRecord]::New(
                    [ItemNotFoundException]::new("Device with ID $($deviceID) was not found in NinjaRMM."),
                    'NinjaDeviceNotFound',
                    'ObjectNotFound',
                    $deviceID
                )
                $PSCmdlet.ThrowTerminatingError($DeviceNotFoundError)
            }
        } else {
            Write-Verbose 'Retrieving all jobs.'
            $Resource = 'v2/jobs'
        }
        $RequestParams = @{
            Method = 'GET'
            Resource = $Resource
            QSCollection = $QSCollection
        }
        $JobResults = New-NinjaRMMGETRequest @RequestParams
        Return $JobResults
    } catch {
        $CommandFailedError = [ErrorRecord]::New(
            [System.Exception]::New(
                'Failed to get jobs from NinjaRMM. You can use "Get-Error" for detailed error information.',
                $_.Exception
            ),
            'NinjaCommandFailed',
            'ReadError',
            $TargetObject
        )
        $PSCmdlet.ThrowTerminatingError($CommandFailedError)
    }
}