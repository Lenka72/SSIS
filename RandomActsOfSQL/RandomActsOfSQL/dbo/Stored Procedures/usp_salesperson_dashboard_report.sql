


-- ================================================
-- Author:		Elaena Bakman		 
-- Create date: 05/27/2018
-- Description:	This is  the stored procedure for
-- the SSIS Demo Report.
-- Update:		
-- ================================================

CREATE PROCEDURE [dbo].[usp_salesperson_dashboard_report] (
        @Type INT = 0
       ,@SalesPersonName NVARCHAR(50) = NULL
       ,@UserId dtUserId)
AS
BEGIN
        SET NOCOUNT ON;

        DECLARE @ErrorMessage VARCHAR(500)
                -- the following set of variables support the job processing
               ,@JobListTable dbo.job_list_table_type
               ,@ParameterListTable dbo.parameter_list_table_type
               ,@JobName VARCHAR(255);

        IF @Type = 1
        BEGIN
                IF @SalesPersonName IS NULL
                BEGIN
                        SET @ErrorMessage = 'The Sales Person name cannot be left blank.  Please use the interface to run the process for a specific Sales Person.';

                        RAISERROR(@ErrorMessage, 16, 1);

                        RETURN;
                END;

                SET @JobName = 'SSISDB Demo - Export Sales By Sales Person';

                INSERT INTO @JobListTable (JobName)
                VALUES
                ('SSISDB Demo - Export Sales By Sales Person');

                INSERT INTO @ParameterListTable
                (ParameterName
                ,ParameterValue)
                VALUES
                ('Sales Person Name', @SalesPersonName);

                EXEC dbo.usp_run_job @JobListTable = @JobListTable
                                    ,@JobName = @JobName
                                    ,@ParameterListTable = @ParameterListTable
                                    ,@UserId = @UserId
                                    ,@StartJobAtStep = NULL;
        END;

        SELECT          P.FullName
                       ,P.PhoneNumber
                       ,P.FaxNumber
                       ,P.EmailAddress
                       ,SO.OrderCount
        FROM            WideWorldImporters.Application.People P
        OUTER   APPLY   (SELECT     COUNT(  1) AS OrderCount
                         FROM       WideWorldImporters.Sales.Orders O
                         WHERE      O.SalespersonPersonID = P.PersonID) SO
        WHERE           IsSalesperson = 1
        ORDER BY        P.FullName;
END;
