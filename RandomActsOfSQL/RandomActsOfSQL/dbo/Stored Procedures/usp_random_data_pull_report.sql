

-- ================================================
-- Author:		Elaena Bakman		 
-- Create date: 02/09/2019
-- Description:	This is the stored procedure to
-- manage the report for the Rendom Data Pull 
-- Update:		
-- ================================================
--Type: 0 - Report Only
--		1 - Update Record
--		2 - Run Job
--		3 - Truncate Demo Tables
-- ================================================
CREATE PROCEDURE [dbo].[usp_random_data_pull_report]	(
 @Type INT = 0
,@RandomRowCount BIGINT = NULL
,@UserId dbo.dtUserId
,@LogonName NVARCHAR(50) = NULL
,@IsPermittedToLogon BIT = NULL
,@PreferredName NVARCHAR(50) = NULL
,@IsEmployee BIT = NULL
,@IsSalesperson BIT = NULL
,@PhoneNumber NVARCHAR(20) = NULL
)
AS
    BEGIN
        SET NOCOUNT ON;
        
		--delare local variables
		DECLARE @ErrorMessage VARCHAR(255)
				,@PersonId BIGINT
		-- the following set of variables support the job processing
			   ,@JobListTable dbo.job_list_table_type
			   ,@ParameterListTable dbo.parameter_list_table_type
			   ,@JobName VARCHAR(255);

			   IF @Type = 1 OR (@IsEmployee IS NOT NULL AND @LogonName IS NOT NULL) OR (@IsPermittedToLogon IS NOT NULL AND @LogonName IS NOT NULL)
			   	--get prson id based on the User Id provided
					SET @PersonId = (SELECT PersonId FROM WideWorldImporters.Application.People WHERE LogonName = ISNULL(@UserId, 'NO LOGON'));

				IF @Type = 1
				BEGIN

					IF @LogonName IS NULL
					BEGIN
						SET @ErrorMessage = CONCAT('No ID provided for the record to be mofied.', CHAR(10), CHAR(13), 'Please use the edit button in the report appropriate for the record you would like to modify and try again.');
						RAISERROR(@ErrorMessage, 16, 1);
						RETURN;
					END;
					--as we have an update here this is wher the update statement is going to go.
					UPDATE WideWorldImporters.Application.People
					SET IsPermittedToLogon = ISNULL(@IsPermittedToLogon, IsPermittedToLogon)
						,PreferredName 	   = ISNULL(@PreferredName 	   , PreferredName 	   )
						,IsEmployee 	   = ISNULL(@IsEmployee 	   , IsEmployee 	   )
						,PhoneNumber 	   = ISNULL(@PhoneNumber 	   , PhoneNumber 	   )
						,IsSalesperson	   = ISNULL(@IsSalesperson		,IsSalesPerson     )
						,LastEditedBy	   = @PersonId
					WHERE LogonName = @LogonName;			

				END;
				IF @Type = 2
				BEGIN 
					SET @JobName = 'SSISDB Demo - Random Data Pulls';

						INSERT INTO @JobListTable (JobName)
						VALUES
						('SSISDB Demo - Random Data Pulls');

						INSERT INTO @ParameterListTable
								(ParameterName
								,ParameterValue)
						VALUES ('Random Row Count'
								,@RandomRowCount);

						EXEC dbo.usp_run_job @JobListTable = @JobListTable
											,@JobName = @JobName
											,@ParameterListTable = @ParameterListTable
											,@UserId = @UserId;
				END
				IF @Type = 3
				BEGIN 
					TRUNCATE TABLE dbo.People_IsNotPermittedToLogon; 
					TRUNCATE TABLE dbo.People_IsPermittedToLogon;
				END
				IF @IsPermittedToLogon IS NOT NULL AND @LogonName IS NOT NULL
				BEGIN 
					UPDATE WideWorldImporters.Application.People
					SET IsPermittedToLogon = ISNULL(@IsPermittedToLogon, IsPermittedToLogon)
						,LastEditedBy	   = @PersonId
					WHERE LogonName = @LogonName;			
				END

				IF @IsEmployee IS NOT NULL AND @LogonName IS NOT NULL
				BEGIN 
					UPDATE WideWorldImporters.Application.People
					SET IsEmployee = ISNULL(@IsEmployee, IsEmployee)
						,LastEditedBy	   = @PersonId
					WHERE  LogonName = @LogonName;			
				END

		SELECT P.FullName 
		,P.PreferredName 
		,P.IsPermittedToLogon 
		,P.LogonName 
		,P.IsExternalLogonProvider 
		,P.HashedPassword 
		,P.IsSystemUser 
		,P.IsEmployee 
		,P.IsSalesperson 
		,P.UserPreferences 
		,P.PhoneNumber 
		,P.FaxNumber 
		,P.EmailAddress 
		,P.Photo 
		,P.CustomFields 
		,P.LastEditedBy 
		,PP.FullName AS LastEditedByName
		FROM WideWorldImporters.Application.People P
		INNER JOIN WideWorldImporters.Application.People PP
		ON PP.PersonID = P.LastEditedBy
		WHERE P.LogonName != N'NO LOGON'
			AND ((NOT(@IsPermittedToLogon IS NOT NULL 
			OR @IsEmployee IS NOT NULL)
			AND P.LogonName = ISNULL(@LogonName, P.LogonName))
			OR 1 = 1);
			;
    END;
