@echo off
@call:ini sqlguard_ip gip
@echo Appliance address is: %gip%

mkdir diag
cd diag

echo ********************************TAP**************************************************
IF EXIST %windir%\syswow64\guard_tap.ini (type %windir%\syswow64\guard_tap.ini > stap.txt) ELSE type %windir%\system32\guard_tap.ini > stap.txt
echo >> stap.txt
echo **INSTALL LOG** >> stap.txt
echo *****************************SetupLog************************************************
type c:\guardiumStapLog.txt >> stap.txt
echo *******************************TaskList**********************************************
tasklist /svc > tasks.txt
echo *******************************DriverQuery*******************************************
driverquery >> tasks.txt
echo ******************************SystemInfo********************************************
systeminfo > system.txt
echo ******************************Ipconfig***********************************************
ipconfig /all >> system.txt
echo ******************************Netstat************************************************
netstat -nao >> system.txt
echo ******************************Ping-appliance************************************************
ping -n 10 %gip% >> system.txt
echo ******************************trace-appliance************************************************
tracert -w 2 -h 10 %gip% >> system.txt
echo ******************************guardiumStap-CPU************************************************
typeperf "\Process(guardium_stapr)\%% Processor Time" -sc 10 >> system.txt
echo ******************************guardiumStap-Handles************************************************
typeperf "\Process(guardium_stapr)\Handle Count" -sc 10 >> system.txt
echo ******************************guardiumStap-privateBytes************************************************
typeperf "\Process(guardium_stapr)\Private Bytes" -sc 10 >> system.txt
echo ******************************System-CPU************************************************
typeperf  "\processor(_total)\%% processor time" -sc 10 >> system.txt

if EXIST %systemroot%\system32\wevtutil.exe GOTO DO_EVT2008

echo ******************************EventLog***********************************************
cscript //h:cscript /s
Eventquery /v /l application  /fi "source eq Guardium_STAP" /fo csv > evtlog.txt 2>NULL
Eventquery /v /l system  /fi "source eq NtTdidr" /fo csv >> evtlog.txt 2>NULL
Eventquery /v /l system  /fi "source eq LhmonProxy" /fo csv >> evtlog.txt 2>NULL
Eventquery /v /l system  /fi "source eq Nptrc" /fo csv >> evtlog.txt 2>NULL
Eventquery /v /l system  /fi "source eq NpProxy" /fo csv >> evtlog.txt 2>NULL
Eventquery /v /l application  /fi "source eq DB2 Tap" /fo csv >> evtlog.txt 2>NULL
Eventquery /v /l application  /fi "source eq DB2TapProxy" /fo csv >> evtlog.txt 2>NULL
Eventquery /v /l application  /fi "source eq DB2TapPRoxySvc" /fo csv >> evtlog.txt 2>NULL
Eventquery /v /l application  /fi "source eq DB2TapSvc" /fo csv >> evtlog.txt 2>NULL
Eventquery /v /l application  /fi "source eq IIS Tap" /fo csv >> evtlog.txt 2>NULL
Eventquery /v /l application  /fi "source eq SP Tap" /fo csv >> evtlog.txt 2>NULL

echo *****************************EventLog - System Error****************************
Eventquery /v /l system  /fi "type eq error" /fo csv >> evtlog.txt 2>NULL
echo *****************************EventLog - System Warning******************************
Eventquery /v /l system  /fi "type eq warning" /fo csv >> evtlog.txt 2>NULL
GOTO :DO_REG


:DO_EVT2008

echo ******************************EventLog2008***********************************************

wevtutil qe Application "/q:*[System[Provider[@Name='Guardium_STAP']]]" /f:text /c:200 /rd:true > evtlog2008.txt
wevtutil qe Application "/q:*[System[Provider[@Name='NtTdidr']]]" /f:text /c:200 /rd:true >> evtlog2008.txt
wevtutil qe Application "/q:*[System[Provider[@Name='LhmonProxy']]]" /f:text /c:200 /rd:true >> evtlog2008.txt
wevtutil qe Application "/q:*[System[Provider[@Name='Nptrc']]]" /f:text /c:200 /rd:true >> evtlog2008.txt
wevtutil qe Application "/q:*[System[Provider[@Name='NpProxy']]]" /f:text /c:200 /rd:true >> evtlog2008.txt
wevtutil qe Application "/q:*[System[Provider[@Name='DB2 Tap']]]" /f:text /c:200 /rd:true >> evtlog2008.txt
wevtutil qe Application "/q:*[System[Provider[@Name='DB2TapProxy']]]" /f:text /c:200 /rd:true >> evtlog2008.txt
wevtutil qe Application "/q:*[System[Provider[@Name='DB2TapPRoxySvc']]]" /f:text /c:200 /rd:true >> evtlog2008.txt
wevtutil qe Application "/q:*[System[Provider[@Name='DB2TapSvc']]]" /f:text /c:200 /rd:true >> evtlog2008.txt
wevtutil qe Application "/q:*[System[Provider[@Name='IIS Tap']]]" /f:text /c:200 /rd:true >> evtlog2008.txt
wevtutil qe Application "/q:*[System[Provider[@Name='SP Tap']]]" /f:text /c:200 /rd:true >> evtlog2008.txt
wevtutil qe system "/q:*[System[(Level=1  or Level=2 or Level=3)]]" /f:text /c:200 /rd:true >> evtlog2008.txt

:DO_REG

echo *****************************Registry - Uninstall************************************
reg query  HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /s > reg.txt
echo *****************************Registry - services***********************************
reg query  HKLM\SYSTEM\CurrentControlSet\Services /s >> reg.txt
echo *****************************Registry - GroupOrderList*******************************
reg query  HKLM\SYSTEM\CurrentControlSet\Control\GroupOrderList /s >> reg.txt
reg query  HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSSQLServer /s >> reg.txt

exit

:ini    
IF EXIST %windir%\syswow64\guard_tap.ini (set tapini=%windir%\syswow64\guard_tap.ini > stap.txt) ELSE set tapini=%windir%\system32\guard_tap.ini
@for /f "tokens=2 delims==" %%a in ('find /I "%~1=" %tapini%') do @set %~2=%%a    
@goto:eof
