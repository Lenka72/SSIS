

-- ================================================
-- Author:		Elaena Bakman		 
-- Create date: 04/20/2017
-- Description:	This will pull the database access roles for audit.
-- ================================================

CREATE PROCEDURE [dbo].[usp_database_access_get_recent]
AS
BEGIN
        SET NOCOUNT ON;

        DECLARE @Version BIGINT;

        SET @Version = CONVERT(BIGINT, REPLACE(REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GETDATE(), 121), ':', ''), '-', ''), ' ', ''), '.', ''));

        INSERT INTO dbo.database_access_audit
        (Version
        ,LoginId
        ,DatabaseLoginName
        ,DatabaseLoginTypeDescription
        ,DatabaseLoginAuthenticationTypeDescription
        ,DatabaseLoginDefaultSchemaName
        ,ServerLoginName
        ,ServerLoginTypeDescription
        ,ServerLoginCreateDate
        ,ServerLoginModifyDate
        ,ServerLoginDefaultDatabaseName
        ,DatabaseRoleId
        ,DatabaseRoleName
        ,DatabaseRoleCreateDate
        ,DatabaseRoleModifyDate
        ,BuiltinDatabaseRole
        ,DatabasePermissionName
        ,DatabasePermission
        ,SchemaName
        ,SchemaPermissionName
        ,SchemaPermission
        ,DatabasePermissionCount)
        SELECT  @Version AS Version
               ,CONVERT(VARCHAR(100), DP1.sid, 1) AS LoginId
               ,DP1.name AS DatabaseLoginName
               ,DP1.type_desc AS DatabaseLoginTypeDescription
               ,DP1.authentication_type_desc AS DatabaseLoginAuthenticationTypeDescription
               ,DP1.default_schema_name AS DatabaseLoginDefaultSchemaName
               ,ISNULL(SVRP.name, 'N/A (Principal Exists on DB Only)') AS ServerLoginName
               ,ISNULL(SVRP.type_desc, 'Database Principal Only (Does not exists as a server Login)') AS ServerLoginTypeDescription
               ,SVRP.create_date AS ServerLoginCreateDate
               ,SVRP.modify_date AS ServerLoginModifyDate
               ,SVRP.default_database_name AS ServerLoginDefaultDatabaseName
               ,ISNULL(DP2.principal_id, -2) AS DatabaseRoleId
               ,ISNULL(DP2.name, 'Database Role - Not Assigned') AS DatabaseRoleName
               ,DP2.create_date AS DatabaseRoleCreateDate
               ,DP2.modify_date AS DatabaseRoleModifyDate
               ,DP2.is_fixed_role AS BuiltinDatabaseRole
               ,DPRM.DatabasePermissionName
               ,DPRM.DatabasePermission
               ,SP.SchemaName
               ,SP.SchemaPermissionName
               ,SP.SchemaPermission
               ,ISNULL(DPRM.DatabasePermissionCount, 0) AS DatabasePermissionCount
        FROM    sys.database_principals DP1
        LEFT    OUTER JOIN sys.database_role_members DRM
        ON DRM.member_principal_id = DP1.principal_id
        LEFT    OUTER JOIN sys.database_principals DP2
        ON DP2.principal_id = DRM.role_principal_id
        LEFT    OUTER JOIN sys.server_principals SVRP
        ON SVRP.sid = DP1.sid
        OUTER   APPLY
                (SELECT     S.name AS SchemaName
                           ,DP.permission_name AS SchemaPermissionName
                           ,DP.state_desc AS SchemaPermission
                 FROM       sys.schemas AS S
                 INNER   JOIN sys.database_permissions AS DP
                 ON DP.major_id = S.schema_id
                    AND   DP.minor_id = 0
                    AND   DP.class = 3
                 WHERE      DP.grantee_principal_id = DRM.role_principal_id) SP
        OUTER   APPLY
                (SELECT     DPI.permission_name AS DatabasePermissionName
                           ,DPI.state_desc AS DatabasePermission
                           ,COUNT(  *) OVER (PARTITION BY DPI.grantee_principal_id) AS DatabasePermissionCount
                 FROM       sys.database_permissions DPI WITH (NOLOCK)
                 WHERE      DPI.grantee_principal_id = DRM.role_principal_id
                            AND DPI.class = 0) DPRM
        WHERE   DP1.type != 'R'
                AND DP1.authentication_type != 0
        UNION
        SELECT  DISTINCT @Version AS Version
               ,CONVERT(VARCHAR(100), S.sid, 1) AS LoginId
               ,S.name AS DatabaseLoginName
               ,CASE
                        WHEN S.isntname = 1 THEN 'WINDOWS_USER'
                        WHEN S.isntname = 0 THEN 'SQL_USER'
                        WHEN S.isntgroup = 1 THEN 'WINDOWS_GROUP'
                        ELSE    'UNKNOWN'
                END AS DatabaseLoginTypeDescription
               ,CASE
                        WHEN S.isntuser = 1 THEN 'WINDOWS'
                        ELSE    'INSTANCE'
                END AS DatabaseLoginAuthenticationTypeDescription
               ,NULL AS DatabaseLoginDefaultSchemaName
               ,S.name AS ServerLoginName
               ,CASE
                        WHEN S.isntname = 1 THEN 'WINDOWS_USER'
                        WHEN S.isntname = 0 THEN 'SQL_USER'
                        WHEN S.isntgroup = 1 THEN 'WINDOWS_GROUP'
                        ELSE    'UNKNOWN'
                END AS ServerLoginTypeDescription
               ,S.createdate AS ServerLoginCreateDate
               ,S.updatedate AS ServerLoginModifyDate
               ,S.dbname AS ServerLoginDefaultDatabaseName
               ,-1 AS DatabaseRoleId
               ,CONCAT( 'Server Role - ', CASE
                                                  WHEN S.sysadmin = 1 THEN 'SYSADMIN'
                                                  WHEN S.serveradmin = 1 THEN 'SERVERADMIN'
                                                  WHEN S.securityadmin = 1 THEN 'SECURITYADMIN'
                                                  WHEN S.bulkadmin = 1 THEN 'BULKADMIN'
                                                  ELSE    'OTHER'
                                          END) AS DatabaseRoleName
               ,S.createdate AS DatabaseRoleCreateDate
               ,S.updatedate AS DatabaseRoleModifyDate
               ,CASE
                        WHEN S.name = 'sa' THEN 1
                        ELSE    0
                END AS BuiltinDatabaseRole
               ,CASE
                        WHEN S.sysadmin = 1 THEN 'SYSADMIN'
                        WHEN S.serveradmin = 1 THEN 'SERVERADMIN'
                        WHEN S.securityadmin = 1 THEN 'SECURITYADMIN'
                        WHEN S.bulkadmin = 1 THEN 'BULKADMIN'
                        ELSE    'OTHER'
                END DatabasePermissionName
               ,CASE
                        WHEN 1 IN (S.sysadmin, S.securityadmin, S.serveradmin, S.setupadmin, S.processadmin, S.diskadmin, S.dbcreator, S.bulkadmin) THEN 'GRANT'
                        ELSE    NULL
                END AS DatabasePermission
               ,NULL AS SchemaName
               ,NULL AS SchemaPermissionName
               ,NULL AS SchemaPermission
               ,1 AS DatabasePermissionCount
        FROM    sys.syslogins S
        INNER   JOIN sys.server_principals SP1
        ON SP1.sid = S.sid
        LEFT    OUTER JOIN sys.server_permissions AS SP2
        ON SP2.grantee_principal_id = SP1.principal_id
        WHERE   S.sysadmin = 1
                AND S.hasaccess = 1
        ORDER BY    DatabaseLoginName
                   ,DatabaseRoleName
                   ,SP.SchemaName;
END;
