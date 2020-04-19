





-- =============================================
-- Author:		Elaena Bakman
-- Create date: 6/5/2013
-- Description: This fucntion splits a delimited string and returns a table. 
-- Example: 
-- DECLARE @InputString AS VARCHAR(MAX),
--		   @Delimiter AS VARCHAR(10)
-- SET @InputString = 'A, B, C, D, E, F, G'; 
-- SET @Delimiter = ',';

-- SELECT * FROM dbo.fn_split(@InputString, @Delimiter)
-- =============================================
CREATE FUNCTION [dbo].[fn_split] 
(
	@InputString AS VARCHAR(MAX),
	@Delimiter AS VARCHAR(10)
)
RETURNS @SplitData TABLE 
(
	Value VARCHAR(255)
)
AS
BEGIN
	
DECLARE @XML AS XML

SET @XML = CAST(('<X>' + REPLACE(@InputString, @Delimiter, '</X><X>') + '</X>') AS XML);
	
	INSERT INTO @SplitData 
	SELECT RTRIM(LTRIM(N.value('.', 'varchar(255)'))) AS Value 
	FROM @XML.nodes('X') AS T(N)
	
	RETURN 
END





