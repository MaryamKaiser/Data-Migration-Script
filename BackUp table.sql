	IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Backup_DocumentCHKMigration')
	  BEGIN

		CREATE TABLE Backup_DocumentCHKMigration(BusinessEntityGuid UNIQUEIDENTIFIER, UseForRSAW BIT, UseForAudit BIT)

	  END

	INSERT INTO Backup_DocumentCHKMigration(BusinessEntityGuid, UseForRSAW, UseForAudit)
	EXECUTE sp_executesql @Query 