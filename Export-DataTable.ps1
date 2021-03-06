function Export-DataTable
{
    <#
    .Synopsis
        Exports objects to a datatable on disk
    .Description
        Exports objects to a datatable.  Objects in the datatable must be serialiazble in order to be stored.
    .Link
        Import-DataTable
    .Link
        ConvertTo-DataTable
    .Notes
        A datatable will not be able to be exported if it contains live objects that do not implement ISerializable.
    .Example
        dir | 
            select Name, LastWriteTime, CreationTime | 
            Export-DataTable -OutputPath .\Files.bin

        Import-DataTable .\Files.bin
    #>
    [CmdletBinding(DefaultParameterSetName='InputObject')]
    [OutputType([Nullable])]
    param(
    # The input object
    [Parameter(Mandatory=$true,ParameterSetName='InputObject', ValueFromPipeline=$true)]
    [PSObject[]]
    $InputObject,

    # An existing data table.  Use this parameter to store data tables created with New-DataTable
    [Parameter(Mandatory=$true,ParameterSetName='ExistingDataTable')]
    [Data.Datatable]
    $DataTable,

    # The output path
    [Parameter(Mandatory=$true,Position=0)]
    [string]
    $OutputPath
    )

    begin {
        # Create a collection to hold all objects
        $allObjects = New-Object Collections.ArrayList
        
    }

    process {
        #region Accumulate Input
        if ($PSCmdlet.ParameterSetName -eq 'InputObject') {
            $null = $allObjects.AddRange($InputObject)
        }
        #endregion Accumulate Input
    }

    end {
        # If input was supplied by the pipeline, convert it to a data table
        if ($allObjects.Count) {
            $DataTable = ConvertTo-DataTable -InputObject $allObjects
        }

        
        # Determine the absolute path of the output file
        $outFile = "$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath))"
        
        # Open the file stream
        $fileStream = New-Object IO.FileStream $outFile, "OpenOrCreate"                
        # Open a GZip stream on the file stream
        $cs = New-Object System.IO.Compression.GZipStream ($fileStream, [Io.Compression.CompressionMode]"Compress")
        
        # Serialize and save the data 
        (New-Object System.Runtime.Serialization.Formatters.Binary.BinaryFormatter).Serialize($cs, $DataTable) 
        
        # Close the compressed stream
        $cs.Close()
        # close the file stream
        $fileStream.Close()
    }
} 
