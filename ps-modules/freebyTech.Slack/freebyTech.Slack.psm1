#requires -Version 3

<# 
--------------------------------------------------------------------------------
    Contains functions used for slack communication by other scripts.
--------------------------------------------------------------------------------
#>

<#
    .SYNOPSIS
        Post an operational status or general message to a given slack channel.
    .DESCRIPTION
        Note: The environment variable SLACK_AUTH_TOKEN needs to exist and needs
        to be an authorization token defined for slack communication to use this 
        function.
    .LINK
        Validate or update your Slack tokens:
        https://api.slack.com/tokens
        Create a Slack token:
        https://api.slack.com/web
        More information on Bot Users:
        https://api.slack.com/bot-users
#>
function Post-OperationToSlack
{
    Param(
        # Slack channel to post to.
        [Parameter(Mandatory = $true,Position = 0)]
        [ValidateNotNullorEmpty()]
        [String]$Channel,

        # Name of the Bot posting the message.
        [Parameter(Mandatory = $true,Position = 1)]
        [ValidateNotNullorEmpty()]
        [String]$BotName,

        # The message to send.
        [Parameter(Mandatory = $true,Position = 2,HelpMessage = 'Message')]
        [ValidateNotNullorEmpty()]
        [String]$Message,

        # OperationType, valid values are: Started | Message | Important | CompleteSuccess | CompleteFailure.
        [Parameter(Mandatory = $true,Position = 3,HelpMessage = 'OperationType, valid values are: Started | Message | Important | CompleteSuccess | CompleteFailure')]
        [ValidateNotNullorEmpty()]
        [String]$OperationType,

        # If applicable, more information about the operation.
        [Parameter(Mandatory = $false,Position = 5,HelpMessage = 'More Information if Available')]
        [String] $MoreInformation = '',

        # A Relevant URL if Available.
        [Parameter(Mandatory = $false,Position = 6,HelpMessage = 'A Relevant URL if Available')]
        [String]$RelevantURL = '',

        # A Relevant URL Text Description if Available.
        [Parameter(Mandatory = $false,Position = 7,HelpMessage = 'A Relevant URL Text Description if Available')]
        [String]$RelevantURLDescription = ''        
    )

    Process {

        $MoreInformation = $MoreInformation.Replace("`"", "'")
        $Message = $Message.Replace("`"", "'")
        $RelevantURLDescription = $RelevantURLDescription.Replace("`"", "'")

        # Static parameters
        $token = (Get-ChildItem Env:SLACK_AUTH_TOKEN).Value
        $uri = 'https://slack.com/api/chat.postMessage'

        $iconEmoji = ':speech_balloon:'
        $attachmentColorStr = ''
        if($OperationType -eq "Started")
        {
            $iconEmoji = ":stopwatch:"
        }
        elseif($OperationType -eq "CompleteSuccess")
        {
            $iconEmoji = ":metal:"
            $attachmentColorStr = @"
                "color": "good",
"@
        }
        elseif($OperationType -eq "CompleteFailure")
        {
            $Message = "<!channel>, $Message"
            $iconEmoji = ":scream:"
            $attachmentColorStr = @"
                "color": "danger",
"@
        }
        elseif($OperationType -eq "Important")
        {
            $iconEmoji = ":information_source:"
        }

        #Write-Host "Posting message to $Channel..."

        $RelevantURLAttachment = ''
        $hasFields = $false

        if($RelevantURL -ne '')
        {
            $hasFields = $true
            $RelevantURLAttachment = @"
            {
                "short": true,
                "title": "URL",
                "value": "<$RelevantURL|$RelevantURLDescription>"
            }
"@
        }

        if($MoreInformation -ne '')
        {
            $MoreInformationAttachment = @"
            {
                "short": false,
                "title": "More Information",
                "value": "$MoreInformation"
            }
"@            
            if($hasFields -eq $true)
            {
                $MoreInformationAttachment = ",$MoreInformationAttachment"
            }
            $hasFields = $true
        }

        $fieldsStr = ''
        $additionalMarkdownIn = ''
        if($hasFields -eq $true)
        {
            $fieldsStr = @"
            "fields": [
                $RelevantURLAttachment$MoreInformationAttachment
            ],
"@
            $additionalMarkdownIn = ', "fields"'
        }

        $attachments = @"
        [
            {
            "pretext": "$Message",
            "fallback": "$Message",
            $attachmentColorStr$fieldsStr"mrkdwn_in": ["pretext"$additionalMarkdownIn]    
            }
        ]
"@
        #Write-Host $attachments

        # Build the body as per https://api.slack.com/methods/chat.postMessage
        $body = @{
            token    = $token
            channel  = $Channel
            as_user  = $false
            username = $BotName
            icon_emoji = $iconEmoji
            attachments = $attachments
        }

        # Call the API
        try 
        {
            Invoke-RestMethod -Uri $uri -Body $body
        }
        catch 
        {
            $ErrorMessage = $_.Exception.Message
            throw "Unable to call the API - $ErrorMessage"
        }

    }
}

function Post-ToSlack 
{
    <#  
            .SYNOPSIS
            Sends a chat message to a Slack organization
            .DESCRIPTION
            The Post-ToSlack cmdlet is used to send a chat message to a Slack channel, group, or person.
            Slack requires a token to authenticate to an org. Either place a file named token.txt in the same directory as this cmdlet,
            or provide the token using the -token parameter. For more details on Slack tokens, use Get-Help with the -Full arg.
            .NOTES
            Written by Chris Wahl for community usage
            Twitter: @ChrisWahl
            GitHub: chriswahl
            .EXAMPLE
            Post-ToSlack -channel '#general' -message 'Hello everyone!' -botname 'The Borg'
            This will send a message to the #General channel, and the bot's name will be The Borg.
            .EXAMPLE
            Post-ToSlack -channel '#general' -message 'Hello everyone!' -token '1234567890'
            This will send a message to the #General channel using a specific token 1234567890, and the bot's name will be default (PowerShell Bot).
            .LINK
            Validate or update your Slack tokens:
            https://api.slack.com/tokens
            Create a Slack token:
            https://api.slack.com/web
            More information on Bot Users:
            https://api.slack.com/bot-users
    #>

    Param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Slack channel')]
        [ValidateNotNullorEmpty()]
        [String]$Channel,
        [Parameter(Mandatory = $true,Position = 1,HelpMessage = 'Chat message')]
        [ValidateNotNullorEmpty()]
        [String]$Message,
        [Parameter(Mandatory = $false,Position = 2,HelpMessage = 'Slack API token')]
        [ValidateNotNullorEmpty()]
        [String]$token,
        [Parameter(Mandatory = $false,Position = 3,HelpMessage = 'Optional name for the bot')]
        [String]$BotName = 'PowerShell Bot'
    )

    Process {

        # Static parameters
        if (!$token) 
        {
            $token = Get-Content -Path "$PSScriptRoot\token.txt"
        }
        $uri = 'https://slack.com/api/chat.postMessage'

        # Build the body as per https://api.slack.com/methods/chat.postMessage
        $body = @{
            token    = $token
            channel  = $Channel
            text     = $Message
            username = $BotName
            parse    = 'full'
        }

        # Call the API
        try 
        {
            Invoke-RestMethod -Uri $uri -Body $body
        }
        catch 
        {
            throw 'Unable to call the API'
        }

    } # End of process
} # End of function