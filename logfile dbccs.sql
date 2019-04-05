use [Sparkhound_Powertrak]
go
--displays each transaction log size and space used. 
Dbcc sqlperf (logspace) 

--Shows transactions in the log
Dbcc log ([Sparkhound_Powertrak], 0) 

--shows the number of VLF's. CreateLSN = 0 for the original created files.
--filesize /1024, *8 to get MB 
dbcc loginfo ([Sparkhound_Powertrak])

