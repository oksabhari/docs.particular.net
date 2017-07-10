﻿Set-StrictMode -Version 2.0

Add-Type -AssemblyName System.Data

Function Usage
{
# startcode create-queues-endpoint-usage-powershell
    # For NServiceBus 6 Enpoints
    CreateQueuesForEndpoint -endpointName "myendpoint" -connection "TheConnectionString"

# For NServiceBus 5 and below Endpoints
    CreateQueuesForEndpoint -endpointName "myendpoint" -connection "TheConnectionString" -IncludeRetries
# endcode

# startcode create-queues-shared-usage-powershell
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection("TheConnectionString")
    $sqlConnection.Open()

    try {
        CreateQueue -connection $connection -schema $schema -queuename "error"
    }
    finally {
        $sqlConnection.Close()
        $sqlConnection.Dispose()
    }

# endcode
}

# startcode create-queues-for-endpoint-powershell
Function CreateQueuesForEndpoint
{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $connection,

        [ValidateNotNullOrEmpty()]
        [string] $schema = "dbo",

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $endpointName,

        [Parameter(HelpMessage="Only required for NSB Versions 5 and below")]
        [Switch] $includeRetries
    )

    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection($connection)
    $sqlConnection.Open()

    try {
        # main queue
        CreateQueue -connection $sqlConnection -schema $schema -queuename $endpointName

        # timeout queue
        CreateQueue -connection $sqlConnection -schema $schema -queuename "$endpointName.timeouts"

        # timeout dispatcher queue
        CreateQueue -connection $sqlConnection -schema $schema -queuename "$endpointName.timeoutsdispatcher"

        # retries queue
        if ($includeRetries) {
            CreateQueue -connection $sqlConnection -schema $schema -queuename "$endpointName.Retries"
        }
    }
    finally {
        $sqlConnection.Close()
        $sqlConnection.Dispose()
    }
}
# endcode

# startcode create-queues-powershell
function CreateQueue {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [System.Data.SqlClient.SqlConnection] $connection,

        [ValidateNotNullOrEmpty()]
        [string] $schema = "dbo",

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $queueName
    )

    $sql = @"
    if not  exists (select * from sys.objects where object_id = object_id(N'[{0}].[{1}]') and type in (N'U'))
        begin
        create table [{0}].[{1}](
            [Id] [uniqueidentifier] not null,
            [CorrelationId] [varchar](255),
            [ReplyToAddress] [varchar](255),
            [Recoverable] [bit] not null,
            [Expires] [datetime],
            [Headers] [varchar](max) not null,
            [Body] [varbinary](max),
            [RowVersion] [bigint] identity(1,1) not null
        );
        create clustered index [Index_RowVersion] on [{0}].[{1}]
        (
            [RowVersion]
        )
        create nonclustered index [Index_Expires] on [{0}].[{1}]
        (
            [Expires]
        )
        include
        (
            [Id],
            [RowVersion]
        )
    end
"@ -f $schema, $queueName

    $command = New-Object System.Data.SqlClient.SqlCommand($sql, $connection)
    $command.ExecuteNonQuery()
    $command.Dispose()
}
# endcode
