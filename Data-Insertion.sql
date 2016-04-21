
	INSERT INTO WellField
	(FName, FType, TextValue, DateValue, NumberValue, CurrencyValue, DisplayName, IsSystemGenerated, IsWell, IsQuestion, IsOverview, IsStandard, IsRequired, ColumnName, IsTag, IsRig, SubTableName, MaxLength, DecimalPoints, IsWPMCustomEntityField, IsWPMCustomSubjectField, IsBusinessEntityField, IsActive, IsDeleted, IsSystemDefined, BooleanValue, UseFormattedText, TextValueFormatted, IsPrimaryField, UseUniqueValue)
	SELECT 'Evidence Applicability', 'MSL', '', NULL, NULL, NULL, 'Evidence Applicability', 0, 0, 0, 0, 1, 0, NULL, 0, 0, NULL, 0, 0, 0, 0, 1, 1, 0, 1, NULL, 0, NULL, 0, 0
	SELECT @Doc_Evidence = SCOPE_IDENTITY()	

	----------------------------------------
	
	INSERT INTO WellFieldEntityTypeMapping
	(EntityTypeId, FID, DisplayName, TextValue, DateValue, NumberValue, CurrencyValue, IsQuestion, IsRequired, ColumnName, IsTag, MaxLength, DecimalPoints, IsVirtual, ParentEntityTypeId, SubTableName, IsDeleted, IsInherited, IsIntegrationEnabled, IsActive, BooleanValue, TextValueFormatted, CustomFieldDataColumn, CustomFieldDataTable, FreezeManageData, [Description] )
	VALUES
	(@BE_Document, @Doc_Evidence, 'Evidence Applicability', NULL, NULL, NULL, NULL, 0, 0, NULL, 0, 0, 0, 0, NULL, NULL, 0, 0, 1, 1, NULL, NULL,NULL,NULL,1, '')


	EXEC usp_AssignColumnMappingToCustomField @BE_Document, @Doc_Evidence

	
	DECLARE @CFDataColumn_MSL VARCHAR (50) = (SELECT CustomFieldDataColumn FROM WellFieldEntityTypeMapping WHERE FID = @Doc_Evidence)
	DECLARE @CFDataTable_MSL VARCHAR (50) = (SELECT CustomFieldDataTable FROM WellFieldEntityTypeMapping WHERE FID = @Doc_Evidence)

		------------------------------------------------
	--==Insertion of List Values for MSL==
	DECLARE @CFVID_RSAW INT
	DECLARE @CFVID_Audit INT


	INSERT INTO WellFieldListValuesData
	(ListText, Sequence, DefaultValue,  IsSystemGenerated, [Description])
	SELECT 'Use For Audit Package', 1, 0,  0, 'Use For Audit Package'
	SELECT @CFVID_Audit = SCOPE_IDENTITY()

	INSERT INTO WellFieldListValuesData
	(ListText, Sequence, DefaultValue, IsSystemGenerated, [Description])
	SELECT 'Use For RSAW', 2, 0, 0, 'Use For RSAW'
	SELECT @CFVID_RSAW = SCOPE_IDENTITY()
	
	INSERT INTO WellFieldListValuesMapping (CFVId, CFId)
	SELECT @CFVID_RSAW, @Doc_Evidence
	UNION
	SELECT @CFVID_Audit, @Doc_Evidence

	--------------------------------------------------

	INSERT INTO SystemDefinedFields (SystemFieldName,EntityTypeId,FieldId)
	SELECT 'Evidence Applicability', @BE_Document, @Doc_Evidence

	-- ENTRY IN ADD FORM--
	
	
	DECLARE @AddForm_TemplateGuid UNIQUEIDENTIFIER = (SELECT FormTemplateId FROM M_EntityFormTemplates WHERE EntityId = @BE_Document)
	DECLARE @DisplayOrder int = (SELECT MAX(DisplayOrder) from M_FormFieldsDisplay WHERE FormTemplateId = @AddForm_TemplateGuid) + 1
	
	DECLARE @FormFieldId UNIQUEIDENTIFIER = NEWID()

	INSERT INTO M_FormFields
	(FormFieldId,FieldId,FormTemplateId)
	SELECT @FormFieldId, @Doc_Evidence, @AddForm_TemplateGuid
	
	Insert into M_FormFieldsDisplay
	(FormFieldDisplayGuid,FieldId,FormFieldDisplayId,FormTemplateId,UseSeparatorAbove,DisplayOrder,IsReadOnly)
	SELECT NEWID(), @FormFieldId, null, @AddForm_TemplateGuid, 0 , @DisplayOrder  , 0
