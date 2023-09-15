start -Wait iisreset -ArgumentList '/STOP'
#Stop-WebAppPool DefaultAppPool
#Stop-WebAppPool 'Classic .NET AppPool'

taskkill /IM AwesomeSystemV0.exe >$null /F
taskkill /IM AwesomeSystemV0.exe >$null /F
taskkill /IM AwesomeSystemV0LS.exe >$null /F

Stop-Service -Force AwesomeSystemV0lsservice

Function DownloadArtifact
{    
    Param ($url, $output)    
	Write-Host 'Download ' $url
    $start_time = Get-Date

    $webClient = new-object System.Net.WebClient 
    $credentialAsBytes = [System.Text.Encoding]::ASCII.GetBytes("Jenkins" + ":" + "5q5q5q5q5q~5q_replaced")
    $credentialAsBase64String = [System.Convert]::ToBase64String($credentialAsBytes);
    $webClient.Headers[[System.Net.HttpRequestHeader]::Authorization] = "Basic " + $credentialAsBase64String;

    $webClient.DownloadFile($url, $output)
	Write-Host 'Time taken:' $((Get-Date).Subtract($start_time).Seconds)
}

$jenkinsBuildProject = "view/Branch%20TEST/job/Full_Build_ASV0_Test"
if($args[0])
{
	$jenkinsBuildProject = $args[0]
}

Write-Host ("Deploy from project " + $jenkinsBuildProject)

$result="Success"
Try
{    
    cd C:\DeployScripts\

    del C:\DeployScripts\*.zip

    $result="ERROR: Can not dowload AwesomeSystemV0"
    $url = "http://jenkins.area1.local:8080/" + $jenkinsBuildProject + "/lastSuccessfulBuild/artifact/AwesomeSystemV0/AwesomeSystemV0.Setup/Release/AwesomeSystemV0..Patch.zip"
    $output = "$PSScriptRoot\AwesomeSystemV0..Patch.zip"
    DownloadArtifact -Url $url -Output $output
	
    $result="ERROR: Can not dowload Migration"
    $url = "http://jenkins.area1.local:8080/" + $jenkinsBuildProject + "/lastSuccessfulBuild/artifact/AwesomeSystemV0.MigrationManager/bin/Release/Migration.zip"
    $output = "$PSScriptRoot\Migration.zip"
    DownloadArtifact -Url $url -Output $output

    $result="ERROR: Can not dowload WinUI"
    $url = "http://jenkins.area1.local:8080/" + $jenkinsBuildProject + "/lastSuccessfulBuild/artifact/AwesomeSystemV0.WinUI..Patch.en-us.zip"
    $output = "$PSScriptRoot\AwesomeSystemV0.WinUI..Setup.en-us.zip"
    DownloadArtifact -Url $url -Output $output
	
	$result="ERROR: Can not dowload Sign Service"
    $url = "http://jenkins.area1.local:8080/" + $jenkinsBuildProject + "/lastSuccessfulBuild/artifact/AwesomeSystemV0.Sign/AwesomeSystemV0.Web.Sign/bin/Release/Publish/SignService.zip"
    $output = "$PSScriptRoot\SignService.zip"
    DownloadArtifact -Url $url -Output $output

    $result="ERROR: Can not unzip AwesomeSystemV0"
    &"C:\Program Files\7-Zip\7z.exe" x -y  C:\DeployScripts\AwesomeSystemV0..Patch.zip -oC:\inetpub\wwwroot\AwesomeSystemV0

    $result="ERROR: Can not unzip Migration"
    & "C:\Program Files\7-Zip\7z.exe" x -y  C:\DeployScripts\Migration.zip -oC:\DeployScripts\Migration
	
    $result="ERROR: Can not unzip WinUI"
    & "C:\Program Files\7-Zip\7z.exe" x -y  C:\DeployScripts\AwesomeSystemV0.WinUI..Setup.fa-IR.zip -o"C:\Program Files (x86)\AwesomeSystem\AwesomeSystemV0. AwesomeSystemV0"
	
	$result="ERROR: Can not unzip Sign Service"
    & "C:\Program Files\7-Zip\7z.exe" x -y  C:\DeployScripts\SignService.zip -oC:\inetpub\wwwroot\Sign
  
	#If $connectionStr is not null and not empty - update Migration connectio string
	if ( $args[1] )
    {
		$pattern = '<add key="library.storageConnectionString".*'
		$connectionStr = $args[1]
		$configFile = 'C:\DeployScripts\Migration\AwesomeSystemV0.MigrationManager.exe.config'
		(Get-Content $configFile) -replace $pattern, $connectionStr | Set-Content $configFile
	}
	
	#If $connectionSignStr is not null and not empty - update Migration connectio string
	if ( $args[2] )
    {
		$pattern = '<add key="library.storageConnectionString.Sign".*' 
		$connectionSignStr = $args[2]
		$configFile = 'C:\DeployScripts\Migration\AwesomeSystemV0.MigrationManager.exe.config'
		(Get-Content $configFile) -replace $pattern, $connectionSignStr | Set-Content $configFile
	}

	$result="ERROR: Can not update database"
	
    cd .\Migration
	$result += .\AwesomeSystemV0.MigrationManager.exe --migrate All
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
    Start-Service AwesomeSystemV0lsservice
    #Start-WebAppPool DefaultAppPool    
	#Start-WebAppPool 'Classic .NET AppPool'
    start -Wait iisreset -ArgumentList '/START'
}

$result="Success"

return $result
