
CREATE PROCEDURE [dbo].[usp_add_job_to_log] ( @JobName VARCHAR(255) , 
@UserId                                                VARCHAR(25) , 
@ParameterListTable parameter_list_table_type readonly , 
@IsScheduled BIT = 0 ) 
AS 
  BEGIN 
    DECLARE @ProcessId INT , 
      @ErrorMessage    VARCHAR(500); 
    INSERT INTO dbo.process
                ( 
                            processname , 
                            processstarted , 
                            userid , 
                            scheduled 
                ) 
                VALUES 
                ( 
                            @JobName , 
                            Getdate() , 
                            @UserId , 
                            @IsScheduled 
                ); 
     
    SELECT @ProcessId = Scope_identity(); --check to see if   parameters were passed in, and if   so   add them to   the dbo.process_parameter table
    IF EXISTS 
    ( 
           SELECT 1 
           FROM   @ParameterListTable PLT ) 
    BEGIN 
      INSERT INTO dbo.process_parameter 
                  ( 
                              processid , 
                              parametername , 
                              parametervalue 
                  ) 
      SELECT @ProcessId , 
             PLT.parametername , 
             PLT.parametervalue 
      FROM   @ParameterListTable PLT; 
     
    END; 
  END;
