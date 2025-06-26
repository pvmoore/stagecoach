rem usage:
rem call getfilesize file.txt
rem then use %FileSize% in your batch file

set FileSize=%~z1
set /A FileSizeKB = %FileSize% / 1024
set /A FileSizeMB = %FileSize% / (1024*1024)