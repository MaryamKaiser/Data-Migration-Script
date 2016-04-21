----- Data Migration--

	DECLARE @UseForAuditPackage varchar (50) = 'Use for Audit Package'
	DECLARE @UseForRSAW varchar (30) = 'Use for RSAW'

	DECLARE @TempTable TABLE (FName VARCHAR(50), CFDataColumn varchar(50), CFDataTable varchar(50),FID INT )

		INSERT INTO @TempTable
		SELECT 
			CASE
				WHEN wf.FName = 'Use for Audit' THEN @UseForRSAW
				ELSE wf.FName
			END , etm.CustomFieldDataColumn, etm.CustomFieldDataTable, etm.FId			
		FROM WellField wf
		INNER JOIN WellFieldEntityTypeMapping etm
		ON etm.FID = wf.FID

		WHERE etm.EntityTypeId = 9 
		AND  wf.FName IN ('Use for Audit','Use for Audit Package')	
	

	DECLARE @UseForRSAW_FId INT = (SELECT FID  FROM @TempTable  WHERE FName = @UseForRSAW )
	DECLARE @UseForAudit_FId INT = (SELECT FID FROM @TempTable  WHERE FName = @UseForAuditPackage )

	DECLARE @CFDataCol_1 VARCHAR(50) = (SELECT CFDataColumn FROM @TempTable  WHERE FID = @UseForRSAW_FId )
	DECLARE @CFDataTbl1 VARCHAR(50) = (SELECT CFDataTable FROM @TempTable  WHERE  FID = @UseForRSAW_FId )
	
	DECLARE @CFDataCol_2 VARCHAR(50) = (SELECT CFDataColumn FROM @TempTable  WHERE FID = @UseForAudit_FId)	
	DECLARE @CFDataTbl2 VARCHAR(50) = (SELECT CFDataTable FROM @TempTable  WHERE FID = @UseForAudit_FId)


	DECLARE @QUERY NVARCHAR(MAX)
	SET @Query = '
	SELECT DISTINCT BE.BusinessEntityGuid , CHK1.[' + @CFDataCol_1 + '], CHK2.[' + @CFDataCol_2 +'] 
	FROM BusinessEntity BE
	LEFT OUTER JOIN [' + @CFDataTbl1 +'] CHK1 
	ON BE.BusinessEntityGuid = CHK1.BusinessEntityGuid
	LEFT OUTER JOIN  [' + @CFDataTbl2 +'] CHK2
	ON BE.BusinessEntityGuid = CHK2.BusinessEntityGuid
	WHERE BE.EntityTypeID = 9 and (CHK1.[' + @CFDataCol_1 + '] = 1 OR CHK2.[' + @CFDataCol_2 + '] = 1) '
 
	IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Backup_DocumentCHKMigration')
	  BEGIN

		CREATE TABLE Backup_DocumentCHKMigration(BusinessEntityGuid UNIQUEIDENTIFIER, UseForRSAW BIT, UseForAudit BIT)

	  END

	INSERT INTO Backup_DocumentCHKMigration(BusinessEntityGuid, UseForRSAW, UseForAudit)
	EXECUTE sp_executesql @Query 

	-----------------------------------------------------------------------

	Declare @BusinessEntityGuid uniqueidentifier
	Declare @CHK_RSAW varchar(20)
	Declare @CHK_Audit varchar(20)

		Declare CursorforMSLField cursor forward_only
		for
			SELECT BusinessEntityGuid, UseForRSAW, UseForAudit
			FROM Backup_DocumentCHKMigration

		OPEN CursorForMSLField

		FETCH NEXT FROM CursorForMSLField
		INTO @BusinessEntityGuid , @CHK_RSAW , @CHK_Audit

		WHILE @@FETCH_STATUS = 0 
		BEGIN

		DECLARE @NewGuid uniqueidentifier = newid()

		DECLARE @CSV VARCHAR(50) = NULL, @CFVID VARCHAR(50) = NULL
		
		IF (@CHK_Audit = 1)
		  BEGIN
			SET @CSV= @UseForAuditPackage
			SET @CFVID = CAST(@CFVID_Audit as varchar(10))
		  END
		
		IF (@CHK_RSAW = 1)
		  BEGIN
			SELECT @CSV = COALESCE(@CSV + ', ','') + @UseForRSAW
			SELECT @CFVID = COALESCE(@CFVID + ',','') + CAST(@CFVID_RSAW as varchar(10))
		  END

		INSERT into CustomFieldDataListValuesCsv
		(CustomFieldListValueGuid, CustomFieldListValueCsv, CustomFieldListValueIdCsv) 
		values
		(@NewGuid, @CSV, @CFVID)

		INSERT INTO CustomFieldDataListValues
		(RowId, BusinessEntityGuid, FId, CustomFieldListValueGuid, CustomFieldListValueId, BusinessEntityValueGuid)
		SELECT NEWID(), @BusinessEntityGuid, @Doc_Evidence, @NewGuid, @CFVID_Audit, NULL
		WHERE @CHK_Audit = 1
		UNION
		SELECT NEWID(), @BusinessEntityGuid, @Doc_Evidence, @NewGuid, @CFVID_RSAW, NULL 
		WHERE @CHK_RSAW = 1

		DECLARE @Query_MSL nvarchar(max) = NULL
		SET @Query_MSL = 
		'IF EXISTS (SELECT 1  FROM  [' + @CFDataTable_MSL  +'] TBL WHERE TBL.BusinessEntityGuid = ''' + CAST( @BusinessEntityGuid AS varchar(36))+ ''' )
			BEGIN
				UPDATE [' + @CFDataTable_MSL + ']
				SET [' + @CFDataColumn_MSL + '] = ''' + CAST(@NewGuid AS varchar(36)) + '''
				WHERE BusinessEntityGuid = ''' + CAST( @BusinessEntityGuid AS varchar(36)) + '''
			END
		ELSE
			BEGIN
				INSERT INTO [' + @CFDataTable_MSL + ']
				(BusinessEntityGuid, ['+ @CFDataColumn_MSL +'])
				SELECT '''+ CAST(@BusinessEntityGuid AS varchar(36)) +''' , ''' + CAST(@NewGuid AS varchar(36)) + '''
			END'
		EXECUTE sp_executesql @Query_MSL
		
		FETCH NEXT FROM CursorforMSLField
		INTO @BusinessEntityGuid , @CHK_RSAW , @CHK_Audit
		END

		CLOSE  CursorforMSLField
		DEALLOCATE CursorforMSLField

	UPDATE WellField
	SET IsActive = 0 
	WHERE FID IN ( @UseForRSAW_FId, @UseForAudit_FId)


	DELETE FROM SystemSettings where name = 'EntitySchemaViewsCreated'
	END