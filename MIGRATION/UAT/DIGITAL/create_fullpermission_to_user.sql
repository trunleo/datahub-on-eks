
-- Create the login for database server
USE master
CREATE LOGIN [BankFlexUser1] WITH PASSWORD=N'CabDigital@123', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF

-- Create/update user on specific database
USE BFARCHIVE
-- If the user isn't exist, run script above:
-- CREATE USER BankFlexUser FOR LOGIN [BankFlexUser]

ALTER USER BankFlexUser WITH LOGIN = [BankFlexUser]

USE [master]

GRANT VIEW SERVER STATE TO [BankFlexUser];
GRANT VIEW ANY DEFINITION TO [BankFlexUser];

GRANT CREATE ANY DATABASE TO [BankFlexUser] WITH GRANT OPTION;
GRANT VIEW ANY DATABASE TO [BankFlexUser] WITH GRANT OPTION;

ALTER SERVER ROLE processadmin ADD MEMBER BankFlexUser;
GRANT VIEW ANY DATABASE TO [BankFlexUser];
GRANT VIEW ANY definition to [BankFlexUser];
GRANT VIEW server state to [BankFlexUser];

GRANT ALTER TRACE TO [BankFlexUser];
EXECUTE	sp_addrolemember N'db_owner' , N'BankFlexUser';