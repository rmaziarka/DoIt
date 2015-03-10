USE [$(DatabaseName)]
IF (IS_ROLEMEMBER('$(Role)', '$(Username)') = 0)
BEGIN
    PRINT 'Adding user $(Username) to database role $(Role).'
    ALTER ROLE [$(Role)] ADD MEMBER [$(Username)]
END
ELSE
BEGIN
    PRINT 'User $(Username) already has database role $(Role).'
END