
-- Create the login for database server
USE master
CREATE LOGIN [BankFlex] WITH PASSWORD=N'Cab@2021!@#$a', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF

-- Create/update user on specific database
USE BFARCHIVE
-- If the user isn't exist, run script above:
CREATE USER BankFlex FOR LOGIN [BankFlex]
ALTER ROLE db_owner ADD MEMBER BankFlex;
ALTER USER BankFlex WITH LOGIN = [BankFlex]

USE BFONLINE
-- If the user isn't exist, run script above:
CREATE USER BankFlex FOR LOGIN [BankFlex]
ALTER USER BankFlex WITH LOGIN = [BankFlex]
ALTER ROLE db_owner ADD MEMBER BankFlex;

USE [master]
GRANT ALTER TRACE TO [BankFlex];
GRANT VIEW SERVER STATE TO [BankFlex];
GRANT VIEW ANY DEFINITION TO [BankFlex];

GRANT CREATE ANY DATABASE TO [BankFlex] WITH GRANT OPTION;
GRANT VIEW ANY DATABASE TO [BankFlex] WITH GRANT OPTION;
ALTER SERVER ROLE processadmin ADD MEMBER BankFlex;
GRANT VIEW ANY DATABASE TO [BankFlex];
GRANT VIEW ANY definition to [BankFlex];
GRANT VIEW server state to [BankFlex];


-- Create/update user on specific database


USE [master]

GRANT VIEW SERVER STATE TO [BankFlex];
GRANT VIEW ANY DEFINITION TO [BankFlex];

GRANT CREATE ANY DATABASE TO [BankFlex] WITH GRANT OPTION;
GRANT VIEW ANY DATABASE TO [BankFlex] WITH GRANT OPTION;

ALTER SERVER ROLE processadmin ADD MEMBER BankFlex;
GRANT VIEW ANY DATABASE TO [BankFlex];
GRANT VIEW ANY definition to [BankFlex];
GRANT VIEW server state to [BankFlex];

