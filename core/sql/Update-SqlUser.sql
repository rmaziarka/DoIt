IF NOT EXISTS (SELECT name FROM master.sys.server_principals WHERE name = '$(Username)')
BEGIN
    RAISERROR ('Login name $(Username) does not exist', 11, 1);
    RETURN
END

USE [$(DatabaseName)]

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = '$(Username)')
BEGIN
    PRINT 'CREATING USER $(Username) FOR LOGIN $(Username)'
    CREATE USER [$(Username)] FOR LOGIN [$(Username)]
END
ELSE
BEGIN
    --Orphaned users
    --http://www.mssqltips.com/sqlservertip/1590/understanding-and-dealing-with-orphaned-users-in-a-sql-server-database/
    PRINT 'REMAPPING USER $(Username) TO LOGIN $(Username)'
    ALTER USER [$(Username)] WITH LOGIN = [$(Username)]
END


DECLARE @roles VARCHAR(200) = '$(Role)'
DECLARE @role VARCHAR(50) = null
WHILE LEN(@roles) > 0
BEGIN    
    IF PATINDEX('%|%', @roles) > 0
    BEGIN
        SET @role = SUBSTRING(@roles, 0, PATINDEX('%|%', @roles))
        PRINT 'ADDING' + @role + ' ROLE FOR $(Username)'
        EXEC sp_addrolemember @role, N'$(Username)'
        
        SET @roles = SUBSTRING(@roles, LEN(@role + '|') + 1,
                                                     LEN(@roles))
    END
    ELSE
    BEGIN
        SET @role = @roles
        SET @roles = NULL
        PRINT 'ADDING ROLE ' + @role + ' FOR $(Username)'
        EXEC sp_addrolemember @role, N'$(Username)'
        
    END
END


