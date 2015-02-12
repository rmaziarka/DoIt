PRINT 'Creating database $(DatabaseName)'
CREATE DATABASE [$(DatabaseName)]
GO

ALTER DATABASE [$(DatabaseName)] SET RECOVERY SIMPLE 
GO

ALTER DATABASE [$(DatabaseName)] SET MULTI_USER 
GO