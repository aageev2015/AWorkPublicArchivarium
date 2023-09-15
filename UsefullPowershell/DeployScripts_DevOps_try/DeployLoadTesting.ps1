$deploy_on = $args[0]
$jenkinsBuildProject = $args[1]

#Download DownloadAndIntallAwesomeSystemV0 script on remote machine. If invoke command failed return 1 - Jenkins build Failed
If (-Not( Invoke-Command -Computername $deploy_on -ArgumentList $jenkinsBuildProject -ScriptBlock { 
	Remove-Item C:\DeployScripts\DownloadAndUpdateLoadTesting.ps1 -Force
	$url = ("http://jenkins.area1.local:8080/" + $args[0] + "/lastSuccessfulBuild/artifact/CI/DeployScripts/DownloadAndUpdateLoadTesting.ps1")
	$output = "C:\DeployScripts\DownloadAndUpdateLoadTesting.ps1"
	$start_time = Get-Date

	$webClient = new-object System.Net.WebClient 
    $credentialAsBytes = [System.Text.Encoding]::ASCII.GetBytes("Jenkins" + ":" + "5q5q5q5q5q~5q_replaced")
    $credentialAsBase64String = [System.Convert]::ToBase64String($credentialAsBytes);
    $webClient.Headers[[System.Net.HttpRequestHeader]::Authorization] = "Basic " + $credentialAsBase64String;

    $webClient.DownloadFile($url, $output)
	Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
}))
{
	return 1
}

#Run DownloadAndIntallAwesomeSystemV0 script on remote machine. If invoke command failed return 1 - Jenkins build Failed
$result = ''
If (-Not( $result = Invoke-Command -Computername $deploy_on -ArgumentList $jenkinsBuildProject -ScriptBlock { C:\DeployScripts\DownloadAndUpdateLoadTesting.ps1 $args[0]} ))
{
	return 1
}

Write-Host $result
if ($result -like '*Error*')
{  
  return 1
}
return 0