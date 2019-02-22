# Mediasite_PS_Tools

# Folder Tools:
Powershell script to save and load folders on a Mediasite server

To get started open a powershell and load the init script:
```powershell
> . <location>\Mediasite_PS_Folder\bin\init.ps1 
```

On the first run it will need the follow info:
+ Path to your server: ```http(s)://<servername>/Mediasite```
+ API Key:  This can be generated from a link at the API help page ```http(s)://<servername>/Mediasite/api/v1/$metadata```
+ Username and Password  

The two functions it loads are savefolders and loadfoldersfromfile

---

- NAME: **savefolders**
- SYNOPSIS: reads folder list from mediasite server and outputs it as an object or saves it to a file.
- SYNTAX: ```savefolders [[-filename] <String>] [[-rootfolderid] <String>] [-quiet] [-readmediasiteusers] [<CommonParameters>]```
- DESCRIPTION: 
    Reads folder list from mediasite server.
    If no rootfolderid is specified it will find the root of the server and start from there.
    If the "-filename" isn't specified it will output a object with folder name, it's id and all sub folders
    If a file is specifed it will save the folder structure to a json file
    quiet will supress output

---

- NAME: **loadfoldersfromfile**
- SYNOPSIS: Reads folder list from json file and recreates it on the mediasite server.
- SYNTAX: ```loadfoldersfromfile [-filename] <String> [<CommonParameters>]```
- DESCRIPTION:
    Reads folder list from a json file.
    Uses "ParentFolderId" from json file to specify starting folder on mediasite server.  Empty value means mediasite
    root folder.
    The "id" value for the folders in json file is only used if an error is thrown on creation to see if the folder is
    in the recycle bin.

---
# Example
![Example](/docs/images/folder_dump_example.JPG)



---
# Srt Caption Time Adjuster:

- NAME: **bin\srt-time-shift.ps1**
- SYNOPSIS: Reads SRT file and outputs new one with time shifted by cut time
- SYNTAX: ```bin\srt-time-shift.ps1 -file <String> -cuttime <string> -outfile <string> ```
- DESCRIPTION:
    Reads an SRT file and outputs a new SRT file with the time shifted by the cut time.
    The cut time can be found in the Mediasite web editor.  When you're editing the video put the time line marker to the new begining of the video.  In the time area on the right copy the time (highlighted yellow in the example) and use it as the "cuttime". 
    
---
# Example
![Example](/docs/images/srt_time_example.jpg)
