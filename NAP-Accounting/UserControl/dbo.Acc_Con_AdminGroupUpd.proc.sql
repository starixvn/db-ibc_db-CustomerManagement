ALTER PROCEDURE [dbo].[Acc_Con_AdminGroupUpd]
	@CustID INT, 
	@UserID INT, 
	@GroupID INT, 
	@Language VARCHAR (2)='E', 
	@ErrCode INT=0 OUTPUT, 
	@ErrMsg NVARCHAR (200)='' OUTPUT, 
	@System VARCHAR (50)='ACCOUNTING'
AS
/*
	Created by: []
	Task: Update Group Name of account in User Control 
	DB: DBPOLICY/BODB02
 
	Revisions:
		- 20110526@Tom: Remove condition @System and Write log into table DBLog.bodb_CustomerLog.dbo.UserLog_UserControl
		- 20120604@Sophia: Edit @LogData. Get group permission old and new 
		- 20130125@Elodie: Write more log on UserLog table in case of DBLOG server failure
		
*/
SET NOCOUNT ON;
DECLARE @LogData AS NVARCHAR (MAX), 
@Begin AS DATETIME, 
@End AS DATETIME, 
@Duration AS INT, 
@Groupid_Old AS INT,
@Permission_Old AS VARCHAR(MAX),
@Permission_New AS VARCHAR(MAX)
SET @Begin = GETDATE()

IF EXISTS (SELECT 1
           FROM   Acc_groupinfo_1 WITH (NOLOCK)
           WHERE  groupid = @groupid)
    BEGIN
        --IF EXISTS(SELECT 1 FROM AccCustomer_1 ac with(nolock) WHERE custid=@custid and groupid <> @groupID)   
        SELECT @Groupid_Old = GroupID
        FROM   AccCustomer_1 AS ac WITH (NOLOCK)
        WHERE  custid = @custid
               AND groupid <> @groupID
        IF (@groupid_old IS NOT NULL)
            BEGIN
                BEGIN TRANSACTION
                UPDATE  accCustomer_1 WITH (ROWLOCK, UPDLOCK)
                    SET groupid = @groupid
                WHERE   custid = @custid
                COMMIT TRANSACTION
                			                
			----Get Policy of Old group 	
				SELECT		@Permission_Old = COALESCE(@Permission_Old + ';', '') +  CAST(O.FuncID AS VARCHAR(20))+','+ CAST(O.Policy AS VARCHAR(20)),
							@Permission_New = COALESCE(@Permission_New + ';', '') +  CAST(N.FuncID AS VARCHAR(20))+','+ CAST(N.Policy AS VARCHAR(20))
				FROM		Acc_GroupPolicy_1 O WITH (NOLOCK)
				INNER JOIN	Acc_GroupPolicy_1 N WITH (NOLOCK)
						ON	O.FuncID = N.FuncID
				WHERE	O.GroupID= @Groupid_Old 
						AND N.GroupID= @groupid
						AND O.Policy <> N.Policy			
                
            END
    END
ELSE
    BEGIN
        SELECT @ErrMsg = CASE @Language WHEN 'E' THEN N'This groupid ' + CONVERT (VARCHAR (20), @groupid) + ' is invalid.' WHEN 'CS' THEN N'This groupid ' + CONVERT (VARCHAR (20), @groupid) + ' is invalid.' WHEN 'J' THEN N'This groupid ' + CONVERT (VARCHAR (20), @groupid) + ' is invalid.' ELSE N'This groupid ' + CONVERT (VARCHAR (20), @groupid) + ' is invalid.' END,
               @ErrCode = 103
        RETURN
    END
    
    
/**** Write to log table ***/
IF (@groupid_old IS NOT NULL)
    BEGIN
        SELECT @LogData = '<Acc_Con_AdminGroupUpd>' +
								'<GroupID>'+
									'<Old>'+ ISNULL(CONVERT(VARCHAR(20),@Groupid_Old),'')+'</Old>'+
									'<New>'+ ISNULL(CONVERT(VARCHAR(20),@Groupid),'')+'</New>'+
								'</GroupID>'+
								'<GroupName>'+
									'<Old>' + ISNULL([dbo].[f_EncodeXMLValue]([dbo].[f_Get_GroupNameByGroupID](@groupid_old)),'') + '</Old>'+
									'<New>' + ISNULL([dbo].[f_EncodeXMLValue]([dbo].[f_Get_GroupNameByGroupID](@groupid)),'') + '</New>'+
								'</GroupName>'+
								'<Permission>'+
									'<Old>' + ISNULL(@Permission_Old,'') + '</Old>'+
									'<New>'+ ISNULL(@Permission_New,'') + '</New>'+
								'</Permission>'+
						  '</Acc_Con_AdminGroupUpd>'    					
						
        SET @End = GETDATE()
        SET @Duration = DATEDIFF(millisecond, @Begin, @End)
        
        BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl] @custID = @custID, @Doing = @LogData, @userid = @UserID, @TypeID = 1, @actionid = 1700, @duration = @Duration
		END TRY
		BEGIN CATCH
			SELECT @LogData = '<Acc_Con_AdminGroupUpd> ' +								
								'ErrMsg="' + COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" ' + 								
						  '</Acc_Con_AdminGroupUpd>'   
						   
			EXEC WriteLog_UserLog @UserID = @UserID, 
								  @Doing = @LogData
		END CATCH
    END


GO 
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminGroupUpd] TO [vnteam]

GO
GRANT EXECUTE ON [dbo].Acc_Con_AdminGroupUpd TO [bodbAdminNet]


