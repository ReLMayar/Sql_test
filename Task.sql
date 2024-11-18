CREATE SCHEMA tst;

--Creating tables
BEGIN
	CREATE TABLE tst.Statuses
	(
		id		BIGINT NOT NULL IDENTITY(1100000000001, 1) PRIMARY KEY,
		name	VARCHAR(100) NOT NULL
	)

	CREATE TABLE tst.Resolutions
	(
		id		BIGINT NOT NULL IDENTITY(1100000000001, 1) PRIMARY KEY,
		name	VARCHAR(100) NOT NULL
	)

	CREATE TABLE tst.ResolutionSolutions
	(
		id		BIGINT NOT NULL IDENTITY(1100000000001, 1) PRIMARY KEY,
		name	VARCHAR(100) NOT NULL
	)

	CREATE TABLE tst.Departments
	(
		id		BIGINT NOT NULL IDENTITY(1100000000001, 1) PRIMARY KEY,
		name	VARCHAR(100) NOT NULL
	)

	CREATE TABLE tst.Divisions
	(
		id		BIGINT NOT NULL IDENTITY(1100000000001, 1) PRIMARY KEY,
		name	VARCHAR(100) NOT NULL
	)

	CREATE TABLE tst.Positions
	(
		id		BIGINT NOT NULL IDENTITY(1100000000001, 1) PRIMARY KEY,
		name	VARCHAR(100) NOT NULL
	)

	CREATE TABLE tst.Employees
	(
		id				BIGINT NOT NULL IDENTITY(1100000000001, 1) PRIMARY KEY,
		firstName		VARCHAR(100) NOT NULL,
		lastName		VARCHAR(100) NOT NULL,
		middleName		VARCHAR(100) NOT NULL,
		departmentId	BIGINT,
		divisionsId		BIGINT,
		positionsId		BIGINT
	)
	ALTER TABLE tst.Employees ADD CONSTRAINT FK_EmployeeDepartment FOREIGN KEY (departmentId) REFERENCES tst.Departments(id)
	ALTER TABLE tst.Employees ADD CONSTRAINT FK_EmployeeDivision FOREIGN KEY (divisionsId) REFERENCES tst.Divisions(id)
	ALTER TABLE tst.Employees ADD CONSTRAINT FK_EmployeePosition FOREIGN KEY (positionsId) REFERENCES tst.Positions(id)


	CREATE TABLE tst.FurnitureOrders
	(
		id						BIGINT NOT NULL IDENTITY(1100000000001, 1) PRIMARY KEY,
		applicantId				BIGINT,
		applicationReason		VARCHAR(100),
		coordinatingManagerId	BIGINT,
		resolutionId			BIGINT,
		resolutionPeriod		INT,
		resolutionSolutionId	BIGINT,
		statusId				BIGINT
	)
	ALTER TABLE tst.FurnitureOrders ADD CONSTRAINT FK_FurnitureOrderApplicant			FOREIGN KEY (applicantId)			REFERENCES tst.Employees(id)
	ALTER TABLE tst.FurnitureOrders ADD CONSTRAINT FK_FurnitureOrderCoordinatingManager	FOREIGN KEY (coordinatingManagerId) REFERENCES tst.Employees(id)
	ALTER TABLE tst.FurnitureOrders ADD CONSTRAINT FK_FurnitureOrderResolution			FOREIGN KEY (resolutionId)			REFERENCES tst.Resolutions(id)
	ALTER TABLE tst.FurnitureOrders ADD CONSTRAINT FK_FurnitureOrderResolutionSolution	FOREIGN KEY (resolutionSolutionId)	REFERENCES tst.ResolutionSolutions(id)
	ALTER TABLE tst.FurnitureOrders ADD CONSTRAINT FK_FurnitureOrderStatus				FOREIGN KEY (statusId)				REFERENCES tst.Statuses(id)
END

--Check values
BEGIN
	--Check employee
	CREATE PROCEDURE tst.CheckEmployee
	AS
	BEGIN
		--Applicant
		BEGIN
			DECLARE @OutputApplicant TABLE (id BIGINT, firstName VARCHAR(100), lastName VARCHAR(100), middleName VARCHAR(100))

			INSERT INTO tst.Employees
			(
				firstName,
				lastName,
				middleName,
				departmentId,
				divisionsId,
				positionsId
			)
			OUTPUT Inserted.id, Inserted.firstName, Inserted.lastName, Inserted.middleName INTO @OutputApplicant
			SELECT	t.applicant_firstName,
					t.applicant_lastName,
					t.applicant_middleName,
					(SELECT id FROM tst.Departments WHERE name = t.applicant_department),
					(SELECT id FROM tst.Divisions WHERE name = t.applicant_division),
					(SELECT id FROM tst.Positions WHERE name = t.applicant_position)
			FROM #temp t
			WHERE NOT EXISTS(SELECT 1 FROM tst.Employees e WHERE e.id = t.applicant_id)

			UPDATE t SET t.applicant_id = o.id
			FROM @OutputApplicant o
				INNER JOIN #temp t	ON t.applicant_firstName = o.firstName
									AND t.applicant_lastName = o.lastName
									AND t.applicant_middleName = o.middleName
		END

		--Coordinating manager
		BEGIN
			DECLARE @OutputCm TABLE (id BIGINT, firstName VARCHAR(100), lastName VARCHAR(100), middleName VARCHAR(100))

			INSERT INTO tst.Employees
			(
				firstName,
				lastName,
				middleName,
				departmentId,
				divisionsId,
				positionsId
			)
			OUTPUT Inserted.id, Inserted.firstName, Inserted.lastName, Inserted.middleName INTO @OutputCm
			SELECT	t.coordinatingManager_firstName,
					t.coordinatingManager_lastName,
					t.coordinatingManager_middleName,
					(SELECT id FROM tst.Departments WHERE name = t.coordinatingManager_department),
					(SELECT id FROM tst.Divisions WHERE name = t.coordinatingManager_division),
					(SELECT id FROM tst.Positions WHERE name = t.coordinatingManager_position)
			FROM #temp t
			WHERE NOT EXISTS(SELECT 1 FROM tst.Employees e WHERE e.id = t.coordinatingManager_id)

			UPDATE t SET t.coordinatingManager_id = o.id
			FROM @OutputCm o
				INNER JOIN #temp t	ON t.coordinatingManager_firstName = o.firstName
									AND t.coordinatingManager_lastName = o.lastName
									AND t.coordinatingManager_middleName = o.middleName
		END
	END

	--CheckResolution
	CREATE PROCEDURE tst.CheckResolution
	AS
	BEGIN
		INSERT INTO tst.Resolutions(name)
		SELECT t.resolution
		FROM #temp t
		WHERE NOT EXISTS(SELECT 1 FROM tst.Resolutions r WHERE r.name = t.resolution)

		UPDATE t SET t.resolutionId = r.id
		FROM #temp t
			INNER JOIN tst.Resolutions r ON r.name = t.resolution
	END

	--CheckResolutionSolution
	CREATE PROCEDURE tst.CheckResolutionSolution
	AS
	BEGIN
		INSERT INTO tst.ResolutionSolutions(name)
		SELECT t.resolutionSolution
		FROM #temp t
		WHERE NOT EXISTS(SELECT 1 FROM tst.ResolutionSolutions rs WHERE rs.name = t.resolutionSolution)

		UPDATE t SET t.resolutionSolutionId = rs.id
		FROM #temp t
			INNER JOIN tst.ResolutionSolutions rs ON rs.name = t.resolutionSolution
	END

	--CheckStatus
	CREATE PROCEDURE tst.CheckStatus
	AS
	BEGIN
		INSERT INTO tst.Statuses(name)
		SELECT t.status
		FROM #temp t
		WHERE NOT EXISTS(SELECT 1 FROM tst.Statuses s WHERE s.name = t.status)

		UPDATE t SET t.statusId = s.id
		FROM #temp t
			INNER JOIN tst.Statuses s ON s.name = t.status
	END

	--CheckDepartment
	CREATE PROCEDURE tst.CheckDepartments
	AS
	BEGIN
		INSERT INTO tst.Departments(name)
		SELECT t.applicant_department
		FROM #temp t
		WHERE NOT EXISTS(SELECT 1 FROM tst.Departments d WHERE d.name = t.applicant_department)

		INSERT INTO tst.Departments(name)
		SELECT t.coordinatingManager_department
		FROM #temp t
		WHERE NOT EXISTS(SELECT 1 FROM tst.Departments d WHERE d.name = t.coordinatingManager_department)
	END

	--CheckDivision
	CREATE PROCEDURE tst.CheckDivisions
	AS
	BEGIN
		INSERT INTO tst.Divisions(name)
		SELECT t.applicant_division
		FROM #temp t
		WHERE NOT EXISTS(SELECT 1 FROM tst.Divisions d WHERE d.name = t.applicant_division)

		INSERT INTO tst.Divisions(name)
		SELECT t.coordinatingManager_division
		FROM #temp t
		WHERE NOT EXISTS(SELECT 1 FROM tst.Divisions d WHERE d.name = t.coordinatingManager_division)
	END

	--CheckPosition
	CREATE PROCEDURE tst.CheckPositions
	AS
	BEGIN
		INSERT INTO tst.Positions(name)
		SELECT t.applicant_position
		FROM #temp t
		WHERE NOT EXISTS(SELECT 1 FROM tst.Positions p WHERE p.name = t.applicant_position)

		INSERT INTO tst.Positions(name)
		SELECT t.coordinatingManager_position
		FROM #temp t
		WHERE NOT EXISTS(SELECT 1 FROM tst.Positions p WHERE p.name = t.coordinatingManager_position)
	END

	--CheckAll
	CREATE PROCEDURE tst.CheckAll
	AS
    BEGIN
		BEGIN TRANSACTION
			BEGIN TRY
				EXEC tst.CheckResolution;
				EXEC tst.CheckResolutionSolution;
				EXEC tst.CheckStatus;
				EXEC tst.CheckDepartments;
				EXEC tst.CheckDivisions;
				EXEC tst.CheckPositions;
				EXEC tst.CheckEmployee;
			END TRY
			BEGIN CATCH
				DECLARE @Message NVARCHAR(500) = 'Возникли ошибки при проверке данных: ' + ERROR_MESSAGE();
				RAISERROR(@Message, 18, 1);
				ROLLBACK TRANSACTION
				RETURN;
			END CATCH
		COMMIT TRANSACTION
	END
END

--Inserting from json
BEGIN
	DECLARE @json NVARCHAR(MAX);

	SELECT @json = BulkColumn
	FROM OPENROWSET(BULK 'E:\Test\test.json', SINGLE_CLOB) AS j;

	CREATE TABLE #temp
	(
		applicationReason				VARCHAR(100),
		resolutionId					BIGINT,
		resolution						VARCHAR(100),
		resolutionSolutionId			BIGINT,
		resolutionSolution				VARCHAR(100),
		resolutionPeriod				INT,
		statusId						BIGINT,
		status							VARCHAR(100),
		applicant_id					BIGINT,	
		applicant_firstName				VARCHAR(100),
		applicant_lastName				VARCHAR(100),
		applicant_middleName			VARCHAR(100),
		applicant_department			VARCHAR(100),
		applicant_division				VARCHAR(100),
		applicant_position				VARCHAR(100),
		coordinatingManager_id			BIGINT,		
		coordinatingManager_firstName	VARCHAR(100),
		coordinatingManager_lastName	VARCHAR(100),
		coordinatingManager_middleName	VARCHAR(100),
		coordinatingManager_department	VARCHAR(100),
		coordinatingManager_division	VARCHAR(100),
		coordinatingManager_position	VARCHAR(100),
	)

	INSERT INTO #temp
	(
	    applicationReason,
	    resolution,
	    resolutionSolution,
	    resolutionPeriod,
	    status,
	    applicant_id,
	    applicant_firstName,
	    applicant_lastName,
	    applicant_middleName,
	    applicant_department,
	    applicant_division,
	    applicant_position,
	    coordinatingManager_id,
	    coordinatingManager_firstName,
	    coordinatingManager_lastName,
	    coordinatingManager_middleName,
	    coordinatingManager_department,
	    coordinatingManager_division,
	    coordinatingManager_position
	)
	SELECT	fo.*,
			ap.*,
			cm.*
	FROM OPENJSON(@json) j

		CROSS APPLY OPENJSON(JSON_QUERY(j.value))
			WITH (
					applicationReason	VARCHAR(100)	'$.applicationReason',
					resolution			VARCHAR(100)	'$.resolution',
					resolutionSolution	VARCHAR(100)	'$.resolutionSolution',
					resolutionPeriod	INT				'$.resolutionPeriod',
					status				VARCHAR(100)	'$.status'
				)fo

		CROSS APPLY OPENJSON(JSON_QUERY(j.value, '$.applicant'))
			WITH (
					id			BIGINT			'$.id',
					firstName	VARCHAR(100)	'$.firstName',
					lastName	VARCHAR(100)	'$.lastName',
					middleName	VARCHAR(100)	'$.middleName',
					department	VARCHAR(100)	'$.department',
					division	VARCHAR(100)	'$.division',
					position	VARCHAR(100)	'$.position'
				 )ap

		CROSS APPLY OPENJSON(JSON_QUERY(j.value, '$.coordinatingManager'))
			WITH (
					id			BIGINT			'$.id',
					firstName	VARCHAR(100)	'$.firstName',
					lastName	VARCHAR(100)	'$.lastName',
					middleName	VARCHAR(100)	'$.middleName',
					department	VARCHAR(100)	'$.department',
					division	VARCHAR(100)	'$.division',
					position	VARCHAR(100)	'$.position'
				 )cm

	--Проверка всех входных значений, на наличие в БД, если отсутствуют, то добавляем в БД
	--По хорошему требует более детальной доработки, это скорее более урезанный вариант
	EXEC tst.CheckAll

	INSERT INTO tst.FurnitureOrders
	(
	    applicantId,
	    applicationReason,
	    coordinatingManagerId,
	    resolutionId,
	    resolutionPeriod,
	    resolutionSolutionId,
	    statusId
	)
	SELECT	t.applicant_id,
			t.applicationReason,
			t.coordinatingManager_id,
			t.resolutionId,
			t.resolutionPeriod,
			t.resolutionSolutionId,
			t.statusId
	FROM #temp t

	DROP TABLE #temp
END

--Procedures
BEGIN
	--Insert
	BEGIN
		--Вставка в таблицу FurnitureOrders
		CREATE PROCEDURE tst.InsertValueIntoFurnitureOrders @applicantId			BIGINT,
															@applicationReason		VARCHAR(100),
															@coordinatingManagerId	BIGINT,
															@resolution				VARCHAR(100),
															@resolutionPeriod		INT,
															@resolutionSolution		VARCHAR(100),
															@status					VARCHAR(100)
		AS
		BEGIN
			DECLARE @resolutionId			BIGINT = (SELECT TOP(1) id FROM tst.Resolutions WHERE name = @resolution)
			DECLARE @resolutionSolutionId	BIGINT = (SELECT TOP(1) id FROM tst.ResolutionSolutions WHERE name = @resolutionSolution)
			DECLARE @statusId				BIGINT = (SELECT TOP(1) id FROM tst.Statuses WHERE name = @status)

			BEGIN TRY
				INSERT INTO tst.FurnitureOrders
				(
					applicantId,
					applicationReason,
					coordinatingManagerId,
					resolutionId,
					resolutionPeriod,
					resolutionSolutionId,
					statusId
				)
				SELECT	@applicantId,
						@applicationReason,
						@coordinatingManagerId,
						@resolutionId,
						@resolutionPeriod,
						@resolutionSolutionId,
						@statusId
			END TRY
			BEGIN CATCH
				DECLARE @Message NVARCHAR(500) = 'Ошибка при добавлении данных: ' + ERROR_MESSAGE();
				RAISERROR(@Message, 18, 1);
				RETURN;
			END CATCH
		END

		--Test
		EXEC tst.InsertValueIntoFurnitureOrders @applicantId = 1100000000002,
												@applicationReason = 'Test',
												@coordinatingManagerId = 1100000000001,
												@resolution = 'Test',
												@resolutionPeriod = 2,
												@resolutionSolution = 'Test',
												@status = 'In test'
	END

	--Update
	BEGIN
		--Обновление данных в любой таблице по полю
		CREATE PROCEDURE tst.UpdateValueIntoTable @tableName VARCHAR(30), @fieldName VARCHAR(30), @oldValue VARCHAR(50), @newValue VARCHAR(50)
		AS
		BEGIN
			BEGIN TRY
				DECLARE @command NVARCHAR(MAX) = 'UPDATE ' + @tableName + ' SET ' + @fieldName + ' = ''' + @newValue + ''' WHERE ' + @fieldName + ' = ''' + @oldValue + ''';'
				EXEC(@command)
			END TRY
			BEGIN CATCH
				DECLARE @Message NVARCHAR(500) = 'Ошибка при обновлении данных: ' + ERROR_MESSAGE();
				RAISERROR(@Message, 18, 1);
				RETURN;
			END CATCH
		END

		--Test
		EXEC tst.UpdateValueIntoTable @tableName = 'tst.FurnitureOrders',
									  @fieldName = 'applicationReason',
									  @oldValue = 'Test',
									  @newValue = 'Test_1'
	END
	
	--Delete
	BEGIN
		--Поиск зависимостей
		CREATE PROCEDURE tst.GetReferences @tableName VARCHAR(30), @id VARCHAR(50)
		AS
		BEGIN
			CREATE TABLE #tempReferences
			(
				referencing_table_name	VARCHAR(100)	NULL,
				referencing_column_name VARCHAR(100)	NULL,
				id						BIGINT			NULL
			)

			DECLARE @referencing_table_name VARCHAR(100)
			DECLARE @referencing_column_name VARCHAR(100)

			DECLARE GetRefsCursor CURSOR FOR 
				SELECT	CONCAT(SCHEMA_NAME(f.schema_id), '.', OBJECT_NAME(f.parent_object_id)) referencing_table_name,
						COL_NAME(fc.parent_object_id, fc.parent_column_id) referencing_column_name
				FROM sys.foreign_keys AS f
					INNER JOIN sys.foreign_key_columns AS fc ON f.object_id = fc.constraint_object_id
				WHERE CONCAT(SCHEMA_NAME(f.schema_id), '.', OBJECT_NAME(f.referenced_object_id)) = @tableName
				ORDER BY referencing_table_name

			OPEN GetRefsCursor
			FETCH NEXT FROM GetRefsCursor INTO @referencing_table_name, @referencing_column_name

			WHILE @@FETCH_STATUS = 0
			BEGIN
				DECLARE @select NVARCHAR(MAX) = N'INSERT INTO #tempReferences(referencing_table_name, referencing_column_name, id)
													SELECT DISTINCT ''' + @referencing_table_name + ''', ''' + @referencing_column_name + ''', t.id
													FROM ' + @tableName + ' r
														INNER JOIN ' + @referencing_table_name + ' t ON t.[' + @referencing_column_name + '] = r.id
													WHERE r.id =  ' + CAST(@id AS NVARCHAR(14)) + ''
				EXEC (@select)
				FETCH NEXT FROM GetRefsCursor INTO @referencing_table_name, @referencing_column_name
			END
			CLOSE GetRefsCursor
			DEALLOCATE GetRefsCursor

			SELECT	referencing_table_name,
					referencing_column_name,
					id
			FROM #tempReferences
		END

		--Удаление значения из таблицы, с поиском всех зависимостей, которые относятся к конкретной записи
		CREATE PROCEDURE tst.DeleteValueFromTable @tableName VARCHAR(30), @id VARCHAR(50)
		AS
		BEGIN
			CREATE TABLE #tr
			(
				referencing_table_name	VARCHAR(100)	NULL,
				referencing_column_name VARCHAR(100)	NULL,
				id						BIGINT			NULL,
				orderNumber				INT				IDENTITY(1, 1) 
			)

			INSERT INTO #tr
			EXEC tst.GetReferences	@tableName = @tableName,
									@id = @id

			DECLARE @referencing_table_name_v VARCHAR(100)
			DECLARE @referencing_column_name_v VARCHAR(100)
			DECLARE @id_v BIGINT

			DECLARE SelectValuesCursor CURSOR FOR 
				SELECT	referencing_table_name,
						referencing_column_name,
						id
				FROM #tr

			OPEN SelectValuesCursor
			FETCH NEXT FROM SelectValuesCursor INTO @referencing_table_name_v, @referencing_column_name_v, @id_v
				WHILE @@FETCH_STATUS = 0
				BEGIN				
					INSERT INTO #tr
					EXEC tst.GetReferences	@tableName = @referencing_table_name_v,
											@id = @id_v

					FETCH NEXT FROM SelectValuesCursor INTO @referencing_table_name_v, @referencing_column_name_v, @id_v
				END
			CLOSE SelectValuesCursor
			DEALLOCATE SelectValuesCursor

			--Replacement
			BEGIN
				DECLARE @referencing_table_name_r VARCHAR(100)
				DECLARE @referencing_column_name_r VARCHAR(100)
				DECLARE @id_r BIGINT

				DECLARE DeleteCursor CURSOR FOR 
					SELECT	referencing_table_name,
							referencing_column_name,
							id
					FROM #tr
					ORDER BY orderNumber DESC

				OPEN DeleteCursor
				FETCH NEXT FROM DeleteCursor INTO @referencing_table_name_r, @referencing_column_name_r, @id_r

				WHILE @@FETCH_STATUS = 0
				BEGIN
					DECLARE @delete NVARCHAR(MAX) = N'DELETE FROM ' + @referencing_table_name_r + ' 
													  WHERE id = ' + CAST(@id_r AS NVARCHAR(14)) + ''
					BEGIN TRY
						EXEC (@delete)
					END TRY
					BEGIN CATCH					
						DECLARE @Message NVARCHAR(500) = 'Ошибка при удалении данных: ' + ERROR_MESSAGE();
						RAISERROR(@Message, 18, 1);
						RETURN;
					END CATCH
					FETCH NEXT FROM DeleteCursor INTO @referencing_table_name_r, @referencing_column_name_r, @id_r
				END
				CLOSE DeleteCursor
				DEALLOCATE DeleteCursor
			END

			DECLARE @command NVARCHAR(MAX) = 'DELETE t FROM ' + @tableName + ' t WHERE t.id = ' + CAST(@id AS NVARCHAR(14)) + ''
			EXEC (@command)

			DROP TABLE #tr
		END

		--Test
		EXEC tst.DeleteValueFromTable	@tableName = 'tst.Departments',
										@id = '1100000000001'

		SELECT *
		FROM tst.Departments
	END
END

--View
BEGIN
	CREATE VIEW tst.FurnitureOrdersView
	AS
		SELECT	CONCAT(ap.lastName, ' ', ap.firstName, ' ', ap.middleName)	applicant,
				fo.applicationReason										applicationReason,
				CONCAT(cm.lastName, ' ', cm.firstName, ' ', cm.middleName)	coordinatingManager,
				r.name														resolution,
				fo.resolutionPeriod											resolutionPeriod,
				rs.name														resolutionSolution,
				s.name														status
		FROM tst.FurnitureOrders fo
			INNER JOIN tst.Employees ap ON ap.id = fo.applicantId
			INNER JOIN tst.Employees cm ON cm.id = fo.coordinatingManagerId
			INNER JOIN tst.Resolutions r ON r.id = fo.resolutionId
			INNER JOIN tst.ResolutionSolutions rs ON rs.id = fo.resolutionSolutionId
			INNER JOIN tst.Statuses s ON s.id = fo.statusId

	SELECT *
	FROM tst.FurnitureOrdersView
	WHERE resolutionPeriod = 1
END

--Logs
BEGIN
	CREATE SCHEMA audit;

	CREATE TABLE audit.Tables
	(
		id INT NOT NULL IDENTITY(110000001, 1) PRIMARY KEY,
		schemaName varchar(200) NOT NULL,
		tableName varchar(200) NOT NULL,
		auditEnabled bit NOT NULL CONSTRAINT DF_audit_Tables_auditEnabled DEFAULT((0)),
		auditFor varchar (255) DEFAULT ('insert, update, delete'),
		tablePK varchar (1000),
		auditMaxRowsCount int NULL,
		countMonth int NULL,
		ignoreFields varchar(max)
	)

	CREATE TABLE audit.Logs
	(
		AuditID INT NOT NULL IDENTITY(110000001, 1) PRIMARY KEY,
		Type char(1) NULL,
		PrimaryKeyValue varchar (1000)  NULL,
		FieldName varchar (128) NULL,
		OldValue varchar (1000) NULL,
		NewValue varchar (1000) NULL,
		UpdateDate datetime NULL CONSTRAINT DF__Logs__UpdateDate DEFAULT (getdate()),
		HostName varchar (128) NULL CONSTRAINT DF__Logs__HostName DEFAULT (host_name()),
		UserName varchar (128) NULL,
		tableId INT NULL,
		actionid bigint NULL
	)
	ALTER TABLE audit.Logs ADD CONSTRAINT FK_LogsTable FOREIGN KEY (tableId) REFERENCES audit.Tables(id)

	--Trigger trEmployees_Audit
	BEGIN
		CREATE TRIGGER tst.trEmployees_Audit ON tst.Employees FOR INSERT, UPDATE, DELETE
		AS
			DECLARE @bit				INT,	
					@field				INT,
					@maxfield			INT,
					@char				INT,
					@fieldname			VARCHAR(128),
					@fieldCastName		VARCHAR(128),
					@fieldMaxLength		INT,
					@fieldDataType		VARCHAR(128),
					@TableName			VARCHAR(128),
					@PKCols				VARCHAR(1000),
					@sql				NVARCHAR(2000),
					@UpdateDate			VARCHAR(21),
					@UserName			VARCHAR(128),
					@Type				CHAR(1),
					@PKValueSelect		VARCHAR(1000),
					@TABLE_SCHEMA		VARCHAR(128),
					@auditEnabled		BIT,
					@auditTableId 		INT,
					@auditMaxRowsCount	INT,
					@actiONId			BIGINT,
					@groupActiONId		INT,
					@rowsInserted		BIGINT,
					@rowsDeleted		BIGINT,
					@parametrName		NVARCHAR(2000)
	
			SET NOCOUNT ON;
			SELECT @TableName = 'Employees'
			SELECT @TABLE_SCHEMA = 'tst'
	
			SELECT	@auditEnabled = auditEnabled,
					@auditTableId = id,
					@auditMaxRowsCount = auditMaxRowsCount 
			FROM	audit.Tables 
			WHERE	tableName = @TableName
			AND		schemaName = @TABLE_SCHEMA

			IF ISNULL(@auditEnabled,0) = 0
				RETURN;

			SELECT @rowsInserted = COUNT(1)
			FROM inserted

			SELECT @rowsDeleted = COUNT(1)
			FROM deleted
	
			IF (@rowsInserted > @auditMaxRowsCount)
				RETURN;
			IF (@rowsDeleted > @auditMaxRowsCount)
				RETURN;
			IF (@rowsInserted = 0 AND @rowsDeleted = 0)
				RETURN;

			--Date AND user
			SELECT  @UserName = SYSTEM_USER,
					@UpdateDate = CONVERT(VARCHAR(8), GETDATE(), 112) + ' ' + CONVERT(VARCHAR(12), GETDATE(), 114)

			--ActiON
			IF EXISTS (SELECT * FROM inserted)
			IF EXISTS (SELECT * FROM deleted)
				 SELECT @Type = 'U'
			ELSE
				 SELECT @Type = 'I'
			ELSE
				 SELECT @Type = 'D'

			--EXEC audit.GetContextInfo @groupActionId , @actionId OUT
			--Get list of columns
			SELECT * INTO #ins FROM inserted
			SELECT * INTO #del FROM deleted

			--Get primary key columns for full outer join
			SELECT	@PKCols = COALESCE(@PKCols + ' AND', ' ON') + ' i.[' + c.COLUMN_NAME + '] = d.[' + c.COLUMN_NAME + ']'
			FROM	INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk ,
					INFORMATION_SCHEMA.KEY_COLUMN_USAGE c
			WHERE	pk.TABLE_NAME = @TableName
			AND		pk.CONSTRAINT_SCHEMA=@TABLE_SCHEMA
			AND		CONSTRAINT_TYPE = 'PRIMARY KEY'
			AND		c.TABLE_NAME = pk.TABLE_NAME
			AND		c.CONSTRAINT_SCHEMA = pk.TABLE_SCHEMA
			AND		c.CONSTRAINT_NAME = pk.CONSTRAINT_NAME

			SELECT	@PKValueSelect = COALESCE(@PKValueSelect+'+','') + 'CONVERT(VARCHAR(100), COALESCE(i.[' + cc.COLUMN_NAME + '],d.[' + cc.COLUMN_NAME + '])' + (CASE WHEN cc.DATA_TYPE = 'datetime' THEN ',121' ELSE '' END) + ')' + '+'';'''
			FROM	INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk ,   
					INFORMATION_SCHEMA.KEY_COLUMN_USAGE c,
					INFORMATION_SCHEMA.COLUMNS cc  
			WHERE	pk.TABLE_NAME = @TableName  
			AND		pk.CONSTRAINT_SCHEMA=@TABLE_SCHEMA
			AND		CONSTRAINT_TYPE = 'PRIMARY KEY'  
			AND		c.TABLE_NAME = pk.TABLE_NAME  
			AND		c.CONSTRAINT_SCHEMA = pk.TABLE_SCHEMA
			AND		c.CONSTRAINT_NAME = pk.CONSTRAINT_NAME
			AND		cc.TABLE_CATALOG = c.TABLE_CATALOG
			AND		cc.TABLE_SCHEMA = c.TABLE_SCHEMA
			AND		cc.TABLE_NAME = c.TABLE_NAME
			AND		cc.COLUMN_NAME = c.COLUMN_NAME
			order by cc.COLUMN_NAME
	
			IF @PKValueSelect is not null
				SELECT @PKValueSelect = LEFT(@PKValueSelect, LEN(@PKValueSelect) - 4)

			--если в таблице присутствует поле id - берем его
			IF (EXISTS(
					SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS cc 
					WHERE cc.TABLE_SCHEMA = @TABLE_SCHEMA
						AND cc.TABLE_NAME = @TableName
						AND COLUMN_NAME = 'id'))
			BEGIN
				SELECT @PKValueSelect = 'CONVERT(VARCHAR(100), COALESCE(i.[id],d.[id]))'

				SELECT	@PKCols = COALESCE(@PKCols + ' AND', ' ON') + ' i.[id] = d.[id]'
			END

			IF @PKCols IS NULL
			BEGIN
				RETURN
			END

			SELECT	@field = 0,
					@maxfield = MAX(col.orPos) 
			FROM	INFORMATION_SCHEMA.COLUMNS 
					CROSS APPLY(SELECT columnproperty(OBJECT_ID('[' + TABLE_SCHEMA + '].[' + TABLE_NAME + ']'), COLUMN_NAME, 'ColumnID') orPos) col
			WHERE	TABLE_NAME = @TableName
				AND TABLE_SCHEMA=@TABLE_SCHEMA
				AND DATA_TYPE NOT IN('text', 'image', 'xml')
			WHILE @field < @maxfield
			BEGIN

				SELECT	@field = MIN(col.orPos) 
				FROM	INFORMATION_SCHEMA.COLUMNS 
					CROSS APPLY (SELECT columnproperty(OBJECT_ID('[' + TABLE_SCHEMA + '].[' + TABLE_NAME + ']'), COLUMN_NAME, 'ColumnID') orPos) col
				WHERE	TABLE_NAME = @TableName AND 
						TABLE_SCHEMA = @TABLE_SCHEMA AND
						col.orPos > @field AND
						DATA_TYPE NOT IN ('text', 'image', 'xml')
				SELECT	@bit = (@field - 1 )% 8 + 1
				SELECT	@bit = POWER(2,@bit - 1)
				SELECT	@char = ((@field - 1) / 8) + 1

				IF SUBSTRING(COLUMNS_UPDATED(),@char, 1) & @bit > 0 OR @Type IN('I','D')
				begin
					SELECT	@fieldname = COLUMN_NAME,
							@fieldCastName = '[' + COLUMN_NAME + ']' + (CASE WHEN DATA_TYPE = 'datetime' THEN ',121' ELSE '' END),
							@fieldMaxLength = CHARACTER_MAXIMUM_LENGTH,
							@fieldDataType = DATA_TYPE
					FROM	INFORMATION_SCHEMA.COLUMNS 
						CROSS APPLY(SELECT columnproperty(OBJECT_ID('[' + TABLE_SCHEMA + '].[' + TABLE_NAME + ']'), COLUMN_NAME, 'ColumnID') orPos) col
					WHERE	TABLE_NAME = @TableName
						AND TABLE_SCHEMA=@TABLE_SCHEMA
						AND col.orPos = @field
			
					SELECT @sql = ''
			
					IF (@fieldMaxLength >= 1000 or @fieldMaxLength < 0)
					begin
						SELECT @sql = '
							update #ins
							set [' + @fieldname + '] = CONVERT(' + @fieldDataType + '(max),
								right(CONVERT(VARCHAR(max),util.GetHash(CONVERT(varbinary(max), [' + @fieldname + ']), 0),1), 40) + '' ''
								+ right(CONVERT(VARCHAR(max),' + @fieldCastName + '),959))
							WHERE len(CONVERT(VARCHAR(max), [' + @fieldname + '])) >= 1000
					
							update #del
							set [' + @fieldname + '] = CONVERT(' + @fieldDataType + '(max),
								right(CONVERT(VARCHAR(max),util.GetHash(CONVERT(varbinary(max), [' + @fieldname + ']), 0),1), 40) + '' ''
								+ right(CONVERT(VARCHAR(max),' + @fieldCastName + '),959))
							WHERE len(CONVERT(VARCHAR(max), [' + @fieldname + '])) >= 1000
						'
					END
			
					SELECT @sql = @sql + 'insert audit.Logs(Type, tableId, PrimaryKeyValue, FieldName, OldValue, NewValue, UpdateDate, UserName, actiONId)'
					SELECT @sql = @sql + ' SELECT @Type,@auditTableId'
					SELECT @sql = @sql + ',' + @PKValueSelect
					SELECT @sql = @sql + ',@fieldname'
					SELECT @sql = @sql + ',CONVERT(VARCHAR(1000),d.' + @fieldCastName + ')'
					SELECT @sql = @sql + ',CONVERT(VARCHAR(1000),i.' + @fieldCastName + ')'
					SELECT @sql = @sql + ',@UpdateDate,@UserName,@actiONId'
					SELECT @sql = @sql + ' FROM #ins i full outer join #del d' 
					SELECT @sql = @sql + @PKCols
					SELECT @sql = @sql + ' WHERE (i.[' + @fieldname + '] <> d.[' + @fieldname + ']'
					SELECT @sql = @sql + ' or (i.[' + @fieldname + '] IS NULL AND  d.[' + @fieldname + '] is not null)'
					SELECT @sql = @sql + ' or (i.[' + @fieldname + '] is not null AND  d.[' + @fieldname + '] IS NULL))' 
			
					SET		@parametrName=' @Type char(1), @auditTableId int, @fieldname VARCHAR(128), @UpdateDate datetime, @UserName VARCHAR(128), @actiONId bigint'

					EXEC	sp_executesql	@sql,
											@parametrName,
											@Type = @Type,
											@auditTableId = @auditTableId,
											@fieldname = @fieldname,
											@UpdateDate = @UpdateDate,
											@UserName = @UserName,
											@actiONId = @actiONId
				END
		END	
    END

	--Trigger trFurnitureOrders_Audit
	BEGIN
		CREATE TRIGGER tst.trFurnitureOrders_Audit ON tst.FurnitureOrders FOR INSERT, UPDATE, DELETE
		AS
			DECLARE @bit				INT,	
					@field				INT,
					@maxfield			INT,
					@char				INT,
					@fieldname			VARCHAR(128),
					@fieldCastName		VARCHAR(128),
					@fieldMaxLength		INT,
					@fieldDataType		VARCHAR(128),
					@TableName			VARCHAR(128),
					@PKCols				VARCHAR(1000),
					@sql				NVARCHAR(2000),
					@UpdateDate			VARCHAR(21),
					@UserName			VARCHAR(128),
					@Type				CHAR(1),
					@PKValueSelect		VARCHAR(1000),
					@TABLE_SCHEMA		VARCHAR(128),
					@auditEnabled		BIT,
					@auditTableId 		INT,
					@auditMaxRowsCount	INT,
					@actiONId			BIGINT,
					@groupActiONId		INT,
					@rowsInserted		BIGINT,
					@rowsDeleted		BIGINT,
					@parametrName		NVARCHAR(2000)
	
			SET NOCOUNT ON;
			SELECT @TableName = 'FurnitureOrders'
			SELECT @TABLE_SCHEMA = 'tst'
	
			SELECT	@auditEnabled = auditEnabled,
					@auditTableId = id,
					@auditMaxRowsCount = auditMaxRowsCount 
			FROM	audit.Tables 
			WHERE	tableName = @TableName
			AND		schemaName = @TABLE_SCHEMA

			IF ISNULL(@auditEnabled,0) = 0
				RETURN;

			SELECT @rowsInserted = COUNT(1)
			FROM inserted

			SELECT @rowsDeleted = COUNT(1)
			FROM deleted
	
			IF (@rowsInserted > @auditMaxRowsCount)
				RETURN;
			IF (@rowsDeleted > @auditMaxRowsCount)
				RETURN;
			IF (@rowsInserted = 0 AND @rowsDeleted = 0)
				RETURN;

			--Date AND user
			SELECT  @UserName = SYSTEM_USER,
					@UpdateDate = CONVERT(VARCHAR(8), GETDATE(), 112) + ' ' + CONVERT(VARCHAR(12), GETDATE(), 114)

			--ActiON
			IF EXISTS (SELECT * FROM inserted)
			IF EXISTS (SELECT * FROM deleted)
				 SELECT @Type = 'U'
			ELSE
				 SELECT @Type = 'I'
			ELSE
				 SELECT @Type = 'D'

			--Get list of columns
			SELECT * INTO #ins FROM inserted
			SELECT * INTO #del FROM deleted

			--Get primary key columns for full outer join
			SELECT	@PKCols = COALESCE(@PKCols + ' AND', ' ON') + ' i.[' + c.COLUMN_NAME + '] = d.[' + c.COLUMN_NAME + ']'
			FROM	INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk ,
					INFORMATION_SCHEMA.KEY_COLUMN_USAGE c
			WHERE	pk.TABLE_NAME = @TableName
			AND		pk.CONSTRAINT_SCHEMA=@TABLE_SCHEMA
			AND		CONSTRAINT_TYPE = 'PRIMARY KEY'
			AND		c.TABLE_NAME = pk.TABLE_NAME
			AND		c.CONSTRAINT_SCHEMA = pk.TABLE_SCHEMA
			AND		c.CONSTRAINT_NAME = pk.CONSTRAINT_NAME

			SELECT	@PKValueSelect = COALESCE(@PKValueSelect+'+','') + 'CONVERT(VARCHAR(100), COALESCE(i.[' + cc.COLUMN_NAME + '],d.[' + cc.COLUMN_NAME + '])' + (CASE WHEN cc.DATA_TYPE = 'datetime' THEN ',121' ELSE '' END) + ')' + '+'';'''
			FROM	INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk ,   
					INFORMATION_SCHEMA.KEY_COLUMN_USAGE c,
					INFORMATION_SCHEMA.COLUMNS cc  
			WHERE	pk.TABLE_NAME = @TableName  
			AND		pk.CONSTRAINT_SCHEMA=@TABLE_SCHEMA
			AND		CONSTRAINT_TYPE = 'PRIMARY KEY'  
			AND		c.TABLE_NAME = pk.TABLE_NAME  
			AND		c.CONSTRAINT_SCHEMA = pk.TABLE_SCHEMA
			AND		c.CONSTRAINT_NAME = pk.CONSTRAINT_NAME
			AND		cc.TABLE_CATALOG = c.TABLE_CATALOG
			AND		cc.TABLE_SCHEMA = c.TABLE_SCHEMA
			AND		cc.TABLE_NAME = c.TABLE_NAME
			AND		cc.COLUMN_NAME = c.COLUMN_NAME
			order by cc.COLUMN_NAME
	
			IF @PKValueSelect is not null
				SELECT @PKValueSelect = LEFT(@PKValueSelect, LEN(@PKValueSelect) - 4)

			--если в таблице присутствует поле id - берем его
			IF (EXISTS(
					SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS cc 
					WHERE cc.TABLE_SCHEMA = @TABLE_SCHEMA
						AND cc.TABLE_NAME = @TableName
						AND COLUMN_NAME = 'id'))
			BEGIN
				SELECT @PKValueSelect = 'CONVERT(VARCHAR(100), COALESCE(i.[id],d.[id]))'

				SELECT	@PKCols = COALESCE(@PKCols + ' AND', ' ON') + ' i.[id] = d.[id]'
			END

			IF @PKCols IS NULL
			BEGIN
				RETURN
			END

			SELECT	@field = 0,
					@maxfield = MAX(col.orPos) 
			FROM	INFORMATION_SCHEMA.COLUMNS 
					CROSS APPLY(SELECT columnproperty(OBJECT_ID('[' + TABLE_SCHEMA + '].[' + TABLE_NAME + ']'), COLUMN_NAME, 'ColumnID') orPos) col
			WHERE	TABLE_NAME = @TableName
				AND TABLE_SCHEMA=@TABLE_SCHEMA
				AND DATA_TYPE NOT IN('text', 'image', 'xml')
			WHILE @field < @maxfield
			BEGIN

				SELECT	@field = MIN(col.orPos) 
				FROM	INFORMATION_SCHEMA.COLUMNS 
					CROSS APPLY (SELECT columnproperty(OBJECT_ID('[' + TABLE_SCHEMA + '].[' + TABLE_NAME + ']'), COLUMN_NAME, 'ColumnID') orPos) col
				WHERE	TABLE_NAME = @TableName AND 
						TABLE_SCHEMA = @TABLE_SCHEMA AND
						col.orPos > @field AND
						DATA_TYPE NOT IN ('text', 'image', 'xml')
				SELECT	@bit = (@field - 1 )% 8 + 1
				SELECT	@bit = POWER(2,@bit - 1)
				SELECT	@char = ((@field - 1) / 8) + 1

				IF SUBSTRING(COLUMNS_UPDATED(),@char, 1) & @bit > 0 OR @Type IN('I','D')
				begin
					SELECT	@fieldname = COLUMN_NAME,
							@fieldCastName = '[' + COLUMN_NAME + ']' + (CASE WHEN DATA_TYPE = 'datetime' THEN ',121' ELSE '' END),
							@fieldMaxLength = CHARACTER_MAXIMUM_LENGTH,
							@fieldDataType = DATA_TYPE
					FROM	INFORMATION_SCHEMA.COLUMNS 
						CROSS APPLY(SELECT columnproperty(OBJECT_ID('[' + TABLE_SCHEMA + '].[' + TABLE_NAME + ']'), COLUMN_NAME, 'ColumnID') orPos) col
					WHERE	TABLE_NAME = @TableName
						AND TABLE_SCHEMA=@TABLE_SCHEMA
						AND col.orPos = @field
			
					SELECT @sql = ''
			
					IF (@fieldMaxLength >= 1000 or @fieldMaxLength < 0)
					begin
						SELECT @sql = '
							update #ins
							set [' + @fieldname + '] = CONVERT(' + @fieldDataType + '(max),
								right(CONVERT(VARCHAR(max),util.GetHash(CONVERT(varbinary(max), [' + @fieldname + ']), 0),1), 40) + '' ''
								+ right(CONVERT(VARCHAR(max),' + @fieldCastName + '),959))
							WHERE len(CONVERT(VARCHAR(max), [' + @fieldname + '])) >= 1000
					
							update #del
							set [' + @fieldname + '] = CONVERT(' + @fieldDataType + '(max),
								right(CONVERT(VARCHAR(max),util.GetHash(CONVERT(varbinary(max), [' + @fieldname + ']), 0),1), 40) + '' ''
								+ right(CONVERT(VARCHAR(max),' + @fieldCastName + '),959))
							WHERE len(CONVERT(VARCHAR(max), [' + @fieldname + '])) >= 1000
						'
					END
			
					SELECT @sql = @sql + 'insert audit.Logs(Type, tableId, PrimaryKeyValue, FieldName, OldValue, NewValue, UpdateDate, UserName, actiONId)'
					SELECT @sql = @sql + ' SELECT @Type,@auditTableId'
					SELECT @sql = @sql + ',' + @PKValueSelect
					SELECT @sql = @sql + ',@fieldname'
					SELECT @sql = @sql + ',CONVERT(VARCHAR(1000),d.' + @fieldCastName + ')'
					SELECT @sql = @sql + ',CONVERT(VARCHAR(1000),i.' + @fieldCastName + ')'
					SELECT @sql = @sql + ',@UpdateDate,@UserName,@actiONId'
					SELECT @sql = @sql + ' FROM #ins i full outer join #del d' 
					SELECT @sql = @sql + @PKCols
					SELECT @sql = @sql + ' WHERE (i.[' + @fieldname + '] <> d.[' + @fieldname + ']'
					SELECT @sql = @sql + ' or (i.[' + @fieldname + '] IS NULL AND  d.[' + @fieldname + '] is not null)'
					SELECT @sql = @sql + ' or (i.[' + @fieldname + '] is not null AND  d.[' + @fieldname + '] IS NULL))' 
			
					SET		@parametrName=' @Type char(1), @auditTableId int, @fieldname VARCHAR(128), @UpdateDate datetime, @UserName VARCHAR(128), @actiONId bigint'

					exec	sp_executesql	@sql,
											@parametrName,
											@Type = @Type,
											@auditTableId = @auditTableId,
											@fieldname = @fieldname,
											@UpdateDate = @UpdateDate,
											@UserName = @UserName,
											@actiONId = @actiONId
				END
		END
	END

	--Добавление таблиц, по которым будет производится аудит
	INSERT INTO audit.Tables
	(
	    schemaName,
	    tableName,
	    auditEnabled,
	    auditFor,
	    tablePK,
	    auditMaxRowsCount,
	    countMonth,
	    ignoreFields
	)
	VALUES	('tst', 'Employees', 1, 'insert, update, delete', 'id', NULL, 12, NULL),
			('tst', 'FurnitureOrders', 1, 'insert, update, delete', 'id', NULL, 12, NULL)

	--Insert test
	BEGIN
		INSERT INTO tst.Employees
		(
			firstName,
			lastName,
			middleName,
			departmentId,
			divisionsId,
			positionsId
		)
		VALUES('1', '2', '3', 1100000000002, 1100000000001, 1100000000001)

		INSERT INTO tst.FurnitureOrders
		(
			applicantId,
			applicationReason,
			coordinatingManagerId,
			resolutionId,
			resolutionPeriod,
			resolutionSolutionId,
			statusId
		)
		VALUES(1100000000003, '1', 1100000000010, 1100000000002, 3, 1100000000001, 1100000000001)

		SELECT *
		FROM audit.Logs
		WHERE Type = 'I'
	END

	--Update test
	BEGIN
		UPDATE tst.Employees SET firstName = 'Test' WHERE id = 1100000000003
		UPDATE tst.FurnitureOrders SET resolutionPeriod = 5 WHERE resolutionPeriod = 3

		SELECT *
		FROM audit.Logs
		WHERE Type = 'U'
	END

	--Delete test
	BEGIN
		DELETE FROM tst.FurnitureOrders WHERE id = 1100000000003
		DELETE FROM tst.Employees WHERE id = 1100000000003
	
		SELECT *
		FROM audit.Logs
		WHERE Type = 'D'
    END
END