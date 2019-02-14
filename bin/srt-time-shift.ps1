param([string]$file,
      [string]$cuttime,
      [string]$outfile)

$lines = Get-Content $file
$cutspan = [timespan]$cuttime
if([string]::IsNullOrEmpty($outfile)){
    $nooutfile = $true
}
else{
    $nooutfile = $false
}
$writelinecount = 0


function writeline($x){
    
    #write-host "$nooutfile"
    if($nooutfile){
        write-host $x
    }
    else{
        #write-host "$script:writelinecount $x"
        if($script:writelinecount -eq 0){
            $x | Out-File -filepath $outfile 
        }
        else{
            $x | Out-File -filepath $outfile -Append
        }
    }
    
    $script:writelinecount++

    
}
$caption_count = 0
$linecount = 0
#$outputtxt
$caption = ""
$negtime = $false


foreach ($line in $lines){
    $linecount++
    
    if([string]::IsNullOrEmpty($line)){
        #write-host "new group 2"
        $linecount = 0
    }
    elseif($linecount -eq 1){
        if(!$negtime){
            writeline($caption)
            #write-host "$caption"
            $caption_count++
        }
        else{
            #write-host "$caption"
        }
        $caption = "$caption_count`n"
        #write-host "caption_count:$($caption_count)"
        <#if($caption_count -gt 10){
            return
        }#>
    }
    else{
    $split = [regex]::split($line,' --> ')
    #$line.split(' --> ')
    if($split.count -gt 1){
        $timein = [timespan]($split[0].replace(',','.'))
        $timeout = [timespan]($split[1].replace(',','.'))
        #return $timein
        $a = $timein - $cutspan
        $b = $timeout - $cutspan
        if($a.ticks -lt 0){
            $negtime = $true
        }
        else{
            $negtime = $false
        }
        #return $a
        $timein_string = "$($a.hours.tostring('00')):$($a.minutes.tostring('00')):$($a.seconds.tostring('00')),$($a.Milliseconds.tostring('000'))"
        $timeout_string = "$($b.hours.tostring('00')):$($b.minutes.tostring('00')):$($b.seconds.tostring('00')),$($b.Milliseconds.tostring('000'))"
        #write-host "$($split[0]): 
        #writeline("$($timein_string) --> $($timeout_string)")
        $caption += "$($timein_string) --> $($timeout_string)`n"
    
        #write-host "$($split[0]): $timein $($split[1]): $timeout"
    }
    else{
        $caption += "$line`n"
    #        writeline($line)
    }
    }   
    #$previousline = $line
}