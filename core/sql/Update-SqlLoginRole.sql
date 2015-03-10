IF (IS_SRVROLEMEMBER('$(Role)', '$(Username)') = 0)
BEGIN
    PRINT 'Adding user $(Username) to server role $(Role).'
    ALTER SERVER ROLE [$(Role)] ADD MEMBER [$(Username)]
END
ELSE
BEGIN
    PRINT 'User $(Username) already has server role $(Role).'
END