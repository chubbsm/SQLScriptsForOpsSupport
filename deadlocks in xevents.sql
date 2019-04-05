
declare @xml xml
select @xml = CAST(t.target_data as xml)
from sys.dm_xe_session_targets t
inner join sys.dm_xe_sessions s
	on s.address = t.event_session_address
	where s.name = 'system_health'
	and t.target_name = 'ring_buffer'
select @xml.query('/RingBufferTarget/event [@name="xml_deadlock_report"]')
FOR XML PATH ('XEvent')
