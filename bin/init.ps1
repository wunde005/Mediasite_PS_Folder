$APPROOT = $PSScriptRoot -replace 'bin',''
#$auth_file = ($PSScriptRoot -replace "(.*)\\.+\\?$",'$1') + "\config\auth.xml"
$auth_file = $APPROOT + "\config\auth.xml"

try {
  $auth = import-clixml ($auth_file)
}
catch [System.IO.FileNotFoundException] { #
  write-host "Authentication information not found."
  $auth = @{}
  $auth | add-member autoencrypt $true
}
$saveauth = $false
if([string]::IsNullOrEmpty($auth.uri)){
  write-host "uri is empty"
  $newuri = Read-Host 'What is your uri? should be http(s)://<servername>/Mediasite'
  $auth | add-member uri $newuri
  $saveauth = $true
}
if([string]::IsNullOrEmpty($auth.sfapikey)){
  write-host "api key missing"
  write-host "Information on the mediasite api can be found here: $newuri/api/v1/`$metadata"
  $newsfapikey = Read-Host 'What is your key?'
  $auth | add-member sfapikey $newsfapikey
  $saveauth = $true
}

if(($auth.authorization -eq $null) -and ($auth.secauthtext -eq $null)){
  $username = Read-Host 'What is your username?'
  $pass = Read-Host 'What is your password?' -AsSecureString
  $upass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))
  $authorization = "Basic $([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($username+ ':' + [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass)))))"
  Remove-Variable -name @("upass","pass")
}

if($auth.autoencrypt -and ($auth.secauthtext -eq $null)){
  write-host "saving auth"
  
  $secauth = (Convertto-SecureString "$authorization" -asPlainText -Force)
  $auth.PSObject.Properties.Remove("authorization")

  $auth | Add-Member secauthtext $(convertfrom-SecureString -SecureString $secauth)
  $auth | export-clixml ($APPROOT + "config\auth.xml")  
  
}

function rtnheader(){
  if($auth.secauthtext -ne $null){
    $authorization = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($(ConvertTo-SecureString $auth.secauthtext)))
  }
  else {
    $authorization = $auth.authorization  
  }
  return @{"Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8";"sfapikey"=$($auth.sfapikey);"Accept-Encoding"="gzip,deflate,sdch";"Accept-Language"="en-US,en;q=0.8";"Authorization"=$authorization}
}

function rtnuri(){
  return $full_uri
}

$full_uri = $auth.uri + "/api/v1/"

function mrestget($x){
  if(!$x){
    return;
    }
  elseif($x.contains("http")){
    $luricmd = $x
    }
  else{ 
    $luricmd = $full_uri + $x
    }
  if($debug){
    write-host $luricmd
    write-host $(rtnheader)
  }
  try{
    
    $lresult = Invoke-RestMethod -Headers $(rtnheader) -uri $luricmd
    return $lresult
  }
  catch{
    #Write-host $PSItem.ToString()
    throw $PSItem
  }
}

function mrestfolder($x){
  return mrestget("Folders('$x')")
}

function mrestfolderfolder($x){
  #"folderfolder: $x"
  return mrestgetall("Folders?`$filter=ParentFolderId+eq+'$x'")
}

function mrestfoldername($x){
  return mrestget("Folders?`$filter=Name+eq+'$x'")
}

function mrestfolderpresentations($x){
  $y = mrestfolder($x)
  return mrestgetall($y.'Presentations@odata.navigationLinkUrl')
}

function mrestgetall($x){
  $temp = @()
  if(!$x){
    #return if url is null
    return;
    }
  elseif($x.contains("http")){
    $luricmd = $x
    }
  else{ 
    $luricmd = $full_uri + $x
    }
  $response = Invoke-RestMethod -Headers $(rtnheader) -uri $luricmd
  $temp = $response.value
  $nextresponse = mrestgetall($response.'odata.nextLink')
  $temp += $nextresponse
  return $temp
}

function mrestheader{
  return $rtnheader
}

function mrestpost($x){
  if($postdata -ne $null){
    if($x.contains("http")){
      $luricmd = $x
    }
    else{
      $luricmd = $full_uri + $x
    }
    Invoke-RestMethod -Headers $(rtnheader) -uri $luricmd -method post -ContentType 'application/json' -Body (ConvertTo-Json $postdata)
  }
  else{
    write-host "`$postdata value is missing"
  }
}

function addfolder(){
$luricmd = $full_uri + "Folders"
Invoke-RestMethod -Headers $(rtnheader) -uri $luricmd -method post -Body (ConvertTo-Json $body) -ContentType 'application/json'
}

function addPresentations(){
$luricmd = $full_uri + "Presentations"
Invoke-RestMethod -Headers $(rtnheader) -uri $luricmd -method post -Body (ConvertTo-Json $presentation) -ContentType 'application/json'
}

function addpresenter(){
$luricmd = $full_uri + "Presenters"
Invoke-RestMethod -Headers $(rtnheader) -uri $luricmd -method post -Body (ConvertTo-Json $presenter) -ContentType 'application/json'
}

function getfolder(){
 $luricmd = $full_uri + "Folders('c1c06bbd41f044cbad2cec530123bf1a14')"
 Invoke-RestMethod -Headers $(rtnheader) -uri $luricmd -method get 
}
function putfolder(){
 $luricmd = $full_uri + "Folders('c1c06bbd41f044cbad2cec530123bf1a14')"
 Invoke-RestMethod -Headers $(rtnheader) -uri $luricmd -method put -Body (ConvertTo-Json $body) -ContentType 'application/json'
}


#Get all folders inside of a folder and return array of the folders and subfolders
#path is just for display purposes 
#quiet suppresses output
function gfolders{ 
  param([string]$parentid,[string]$parentname,[string]$path,[switch]$quiet)
  $local:folderarray = @{name=$parentname;id=$parentid;folders=@()}
  $local:folders = mrestfolderfolder($parentid)
  $local:fpath = $path
  #return if no subfolders are found
  if($local:folders.length -eq 0){
      return $local:folderarray 
  }
  #check for subfolders for each folder
  foreach($f in $local:folders){
    if(-NOT $quiet) {
        write-host "path: $($local:fpath)/$($f.name)"
    }
    $local:folderarray.folders += gfolders -parentid $f.id -parentname $f.name -path "$($fpath)/$($f.name)" -quiet:$quiet
  }
  return $local:folderarray
}

#save json of folder structure
#if file name is not specified it will return the json
#if rootfolderid is not specified it will start with the mediasite root folder 
#quiet suppresses folder output
function savefolders{
    param([string]$filename,[string]$rootfolderid,[switch]$quiet)
    $usingHome = $false
    #get mediasite root folder id 
    if([string]::IsNullOrEmpty($rootfolderid)){
        write-host "No root id specified. Using mediasite root folder"
        $usingHome = $true
        $rootfolder = mrestget("Home")
        $rootfolderid = $rootfolder.RootFolderId
        $rootfoldername = $rootfolder.SiteName
        $ParentFolderId = ""
    }
    #get info on specified folder id
    else{
        try{
            $rootfolder = mrestget("Folders('$($rootfolderid)')")
        }
        catch{
            if($psitem.ErrorDetails -match "The resource could not be found."){
                write-host "folder not found for id:$rootfolderid"
            }
            else{
                Write-host $PSItem.ToString()
            }
            return
        }
        $ParentFolderId = $rootfolder.ParentFolderId
        $rootfolderid = $rootfolder.Id
        $rootfoldername = $rootfolder.Name
    }
    if(-NOT $quiet){
        write-host "Root folder: $($rootfoldername) $($rootfolderid)"
    }
    $a = gfolders -parentid $rootfolderid -parentname $rootfoldername -path $rootfoldername -quiet:$quiet

    $depth = 100
    #$depth = 1
    #while ($a | convertto-json -depth $depth | select-string -pattern "System.Collections.Hashtable" -list) { $depth++ }
    $a.ParentFolderId = $ParentFolderId
    if([string]::IsNullOrEmpty($filename)){
        return $a
    }
    else{
        #return $a
        
         ($a | convertto-json -depth $depth) | out-file $filename
    
    }
}


function p2folders{ 
    param([Object[]]$folders,[string]$parentfolderid,[string]$path)
    
    foreach($f in $folders){
      if($f.name -ne $null){
          $res = cfolder -foldername $f.name -parentfolderid $parentfolderid -id $f.id
          write-host "$($path)\$($f.name)  "# -NoNewline
  
          if($res -ne $null){
              p2folders -folders $f.folders -parentfolderid $res.id -path $($path+"\"+$f.name)
          }     
      }
    }
}
#cfolder: creates folder in parentfolder
#folder id isn't required, but is used to check for folders existance in recycle bin
function cfolder{
    param([string]$foldername,  #name of new folder
          [string]$parentfolderid, #parent folder id
          [string]$id)  #not required, used to check for folders existance in recycle bin

    $local:postdata = '{"Name":"'+$foldername+'","ParentFolderId":"'+$parentfolderid+'"}'
    
    $fcmd = $(rtnuri)+"Folders"

    try {
        $r =  Invoke-RestMethod -Headers $(rtnheader) -uri $fcmd -method post -ContentType 'application/json' -Body $local:postdata
        
    } catch {
        if($_.Exception.Response.StatusCode.value__ -eq 500){
            write-host "found existing folder: " -NoNewline
            $r = mrestget("Folders?`$select=full&`$filter=(ParentFolderId+eq+'$($parentfolderid)')+and+(Name+eq+'$($foldername)')")
            #if folder is not returned check to see if it is in the recycle bin
            if($r.value.length -eq 0){
                $r = mrestget("Folders('$($id)')")
                if($r.recycled){
                    write-host "ERROR: Folder named $($foldername) with id $($id) is in recycle bin!: " -NoNewline
                    return
                }
                else{
                    write-host "ERROR: Unable to create Folder named $($foldername): " -NoNewline
                    return
                }
            }
            return $r.value
        }
    }
    write-host "Created folder       : " -NoNewline
    return $r
}

#load folder from file
function loadfoldersfromfile{
    param([parameter(Mandatory=$true)][string]$filename)
    $folderstructure = (Get-Content $filename | Out-String | ConvertFrom-Json)
    if($folderstructure.parentfolderid -ne ""){
        $res = cfolder -foldername $folderstructure.name -parentfolderid $folderstructure.parentfolderid -id $folderstructure.id
        write-host "$($folderstructure.name)  "
        p2folders -folders $folderstructure.folders -parentfolderid $res.id -path $folderstructure.name
    }
    else{
        p2folders -parentfolderid $folderstructure.id -folders $folderstructure.folders -path $folderstructure.name
    }
    
}