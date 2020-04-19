
-- =============================================
-- Author:		E. Bakman
-- Create date: 07/20/2017
-- Description:	This function would return the 
-- value of a parameter from SSISDB based on the
-- Folder and Value name.  It is not intended for
-- use within a query and should only be used in
-- a SET statement.
-- =============================================

CREATE FUNCTION dbo.fn_get_environment_variable_value (
        -- Add the parameters for the function here
        @FolderName NVARCHAR(128)
       ,@EnvironmentName NVARCHAR(128)
       ,@EnvironmentVariableName NVARCHAR(128))
RETURNS SQL_VARIANT
AS
BEGIN
        -- Declare the return variable here
        DECLARE @ParameterValue SQL_VARIANT;

        -- Add the T-SQL statements to compute the return value here
        SELECT  @ParameterValue =
        (SELECT         EV.value AS VariableValue
         FROM           SSISDB.catalog.folders F
         INNER   JOIN   SSISDB.catalog.environments E
         ON F.folder_id = E.folder_id
         INNER   JOIN   SSISDB.internal.environment_variables EV
         ON E.environment_id = EV.environment_id
         WHERE          (F.name = @FolderName)
                        AND (E.name = @EnvironmentName)
                        AND EV.name = @EnvironmentVariableName);

        -- Return the result of the function
        RETURN @ParameterValue;
END;
