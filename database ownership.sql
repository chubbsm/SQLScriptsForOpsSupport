select 'alter authorization on database::' + d.name + ' to sa' from sys.databases  d
inner join sys.server_principals sp
on d.owner_sid = sp.sid
where sp.name <> 'sa'

