
USE master
CREATE LOGIN [dbsa1] WITH PASSWORD=N'Cabdigital', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF

USE msdb

CREATE USER dbsa1 FOR LOGIN [dbsa1]

USE [master]

GRANT VIEW SERVER STATE TO [dbsa1];
GRANT VIEW ANY DEFINITION TO [dbsa1];

GRANT CREATE ANY DATABASE TO [dbsa1] WITH GRANT OPTION;
GRANT VIEW ANY DATABASE TO [dbsa1] WITH GRANT OPTION;

ALTER SERVER ROLE processadmin ADD MEMBER BankFlexUser;
GRANT VIEW ANY DATABASE TO [dbsa1];
GRANT VIEW ANY definition to [dbsa1];
GRANT VIEW server state to [dbsa1];

GRANT ALTER TRACE TO [dbsa1];



USE [BFARCHIVE]


GRANT EXECUTE ON msdb.dbo.rds_backup_database TO [BankFlexUser];
GRANT EXECUTE ON msdb.dbo.rds_restore_database TO [BankFlexUser];
GRANT EXECUTE ON msdb.dbo.rds_task_status TO [BankFlexUser];
GRANT EXECUTE ON msdb.dbo.rds_cancel_task TO [BankFlexUser];

GRANT SELECT ON dbo.sysjobs TO [BankFlexUser];
GRANT SELECT ON dbo.sysjobhistory TO [BankFlexUser];
GRANT SELECT ON msdb.dbo.sysjobactivity TO BankFlexUser;

EXECUTE	sp_addrolemember N'SQLAgentUserRole' , N'BankFlexUser';


USE [master]
ALTER SERVER ROLE [sysadmin] ADD MEMBER [BankFlexUser];

CREATE USER BankFlexUser FOR LOGIN BankFlexUser

GRANT ALTER ANY SCHEMA to BankFlexUser
GRANT EXECUTE to <non-admin user>
GRANT ALL to <non-admin user>
EXEC sp_addrolemember N'db_datareader', N'<non-admin user>'
EXEC sp_addrolemember N'db_datawriter', N'<non-admin user>'
EXEC sp_addrolemember N'db_ddladmin', N'<non-admin user>'


declare @dbnumber int;
declare @dbname sysname;
declare @use nvarchar(4000);
declare @Quest_dblist table (row int identity, name sysname);

insert into @Quest_dblist (name)
	select d.name
		from sys.databases d
		where	d.user_access = 0	and has_dbaccess(d.name) <> 0
		and		d.state = 0			and d.is_auto_close_on = 0
		and		d.is_read_only = 0	and	is_distributor = 0
		and		d.name not in ('master', 'model', 'msdb', 'tempdb', 'SSISDB', 'rdsadmin', 'jackie-ora-3');
set @dbnumber = @@rowcount;

while @dbnumber > 0
begin
	select @dbname =name from @Quest_dblist where row = @dbnumber

	set @use = N'USE ' + quotename(@dbname)
	+ N'CREATE USER [dbsa1] FOR LOGIN [dbsa1]';
	exec (@use);

	set @use = N'USE ' + quotename(@dbname)
	+ N'GRANT SHOWPLAN to dbsa1';
	exec (@use)

	set @dbnumber = @dbnumber - 1;
end


select name, state 
from sys.databases 
where state = 0  -- exclude offline databases
    and name <> db_name() -- exclude current dataase
