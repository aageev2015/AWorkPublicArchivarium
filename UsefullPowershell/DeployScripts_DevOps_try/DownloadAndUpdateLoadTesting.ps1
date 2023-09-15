start -Wait iisreset -ArgumentList '/STOP'
#Stop-WebAppPool DefaultAppPool
#Stop-WebAppPool 'Classic .NET AppPool'

$jenkinsBuildProject = "job/Build%20area1%20binaries%20(AwesomeSystemV0,%20SyncroService,%20WebService)"
if($args[0])
{
	$jenkinsBuildProject = $args[0]
}

Function DownloadArtifact
{    
    Param ($url, $output)    

    $start_time = Get-Date

    $webClient = new-object System.Net.WebClient 
    $credentialAsBytes = [System.Text.Encoding]::ASCII.GetBytes("Jenkins" + ":" + "5q5q5q5q5q~5q_replaced")
    $credentialAsBase64String = [System.Convert]::ToBase64String($credentialAsBytes);
    $webClient.Headers[[System.Net.HttpRequestHeader]::Authorization] = "Basic " + $credentialAsBase64String;

    $webClient.DownloadFile($url, $output)

    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
}

Write-Host ("Deploy from project " + $jenkinsBuildProject)

Try
{    
    cd C:\DeployScripts\

	if ([System.IO.File]::Exists("C:\DeployScripts\Patch.zip") )
	{
		Remove-Item -path ("C:\DeployScripts\Patch.zip") -Force
	}
	
    $result="ERROR: Can not dowload Patch"
    $url = "http://jenkins.area1.local:8080/" + $jenkinsBuildProject + "/lastSuccessfulBuild/artifact/LoadTesting/LoadTesting.Report/Patch.zip"
    $output = "$PSScriptRoot\Patch.zip"
    DownloadArtifact -Url $url -Output $output

    &"C:\Program Files\7-Zip\7z.exe" x -y  C:\DeployScripts\Patch.zip -oC:\inetpub\wwwroot\StressTestHistory    
}
Catch
{
    return $result
}
Finally
{
    #Start-WebAppPool DefaultAppPool    
	#Start-WebAppPool 'Classic .NET AppPool'
    start -Wait iisreset -ArgumentList '/START'
}

$result="Success"

return $result

