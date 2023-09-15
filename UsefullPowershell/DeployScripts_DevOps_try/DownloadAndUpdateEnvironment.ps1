start -Wait iisreset -ArgumentList '/STOP'
#Stop-WebAppPool DefaultAppPool
#Stop-WebAppPool 'Classic .NET AppPool'

taskkill /IM SyncroService.exe >$null /F

$jenkinsBuildProject = "job/Build%area1%20binaries%20(AwesomeSystemV0,%20SyncroService,%20WebService)"
if($args[0])
{
	$jenkinsBuildProject = $args[0]
}

$migrationConnectionString = '<add key="library.storageConnectionString" value="data source=node1.area1.local;initial catalog=AwesomeSystemV0;persist security info=True;user=sa;password=zhz_replaced;packet size=4096" />'
if($args[1])
{
	$migrationConnectionString = $args[1]
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

    del C:\DeployScripts\Patch.exe
    Remove-Item C:\DeployScripts\Patch\* -Force -Recurse

    $result="ERROR: Can not dowload AwesomeSystemV0"
    $url = "http://jenkins.area1.local:8080/" + $jenkinsBuildProject + "/lastSuccessfulBuild/artifact/BackgroundServices/Patch.exe"
    $output = "$PSScriptRoot\Patch.exe"
    DownloadArtifact -Url $url -Output $output

    start -Wait .\Patch.exe -ArgumentList '-o"C:\DeployScripts\Patch" -y'
    cd .\Patch
    start -Wait .\AwesomeSystemV0.Patch.exe -ArgumentList '-o"C:\inetpub\wwwroot\AwesomeSystemV0" -y'
    start -Wait .\SyncroService.Patch.exe -ArgumentList '-o"C:\Program Files (x86)\AwesomeSystem\AwesomeSystemV0. AwesomeSystemV0" -y'
    start -Wait .\Migration.exe -ArgumentList '-o"C:\DeployScripts\Patch\Migration" -y'
    cd .\Migration

	$pattern = '<add key="library.storageConnectionString".*'
	$configFile = '.\AwesomeSystemV0.MigrationManager.exe.config'
	(Get-Content $configFile) -replace $pattern, $migrationConnectionString | Set-Content $configFile	

    $result="ERROR: Can not update database"
    $result += .\AwesomeSystemV0.BaseLib.Migration.exe --migrate All
	if ($LASTEXITCODE -ne 0)
	{
		return $result
	}
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

