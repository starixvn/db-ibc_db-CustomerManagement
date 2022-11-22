/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_Con_AdminGroupUpd]
	@CustID INT, 
	@UserID INT, 
	@GroupID INT, 
	@ExpiredDate DATETIME = NULL,
	@Language VARCHAR (2)='E', 
	@ErrCode INT=0 OUTPUT, 
	@ErrMsg NVARCHAR (200)='' OUTPUT, 
	@System VARCHAR (50)='ACCOUNTING'
AS
/*
	Created by: []
	Task: Update Group Name of account in User Control 
	DB: DBCUST/NAP_UserControl
 
	Revisions:
		- 20110526@Tom: Remove condition @System and Write log into table DBLog.bodb_CustomerLog.dbo.UserLog_UserControl
		- 20120604@Sophia: Edit @LogData. Get group permission old and new 
		- 20130125@Elodie: Write more log on UserLog table in case of DBLOG server failure
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20221104@Tacy: NAP - Set Expired Time For Permission + add param @ExpiredDate [RedmineID: #179323]
		
*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @LogData AS NVARCHAR (MAX), 
	@Begin AS DATETIME, 
	@End AS DATETIME, 
	@Duration AS INT, 
	@Groupid_Old AS INT,
	@ExpiredDate_Old AS DATETIME,
	@Permission_Old AS VARCHAR(MAX),
	@Permission_New AS VARCHAR(MAX)
	SET @Begin = GETDATE()

	IF EXISTS (SELECT 1
			   FROM   Acc_groupinfo WITH (NOLOCK)
			   WHERE  groupid = @groupid)
	BEGIN
			--IF EXISTS(SELECT 1 FROM AccCustomer_1 ac with(nolock) WHERE custid=@custid and groupid <> @groupID)   
			SELECT	@Groupid_Old = GroupID,
					@ExpiredDate_Old = ExpiredDate
			FROM   AccCustomer AS ac WITH (NOLOCK)
			WHERE  custid = @custid
				   AND (groupid <> @groupID
					OR ExpiredDate <> @ExpiredDate)

			IF (@groupid_old IS NOT NULL)
			BEGIN
				IF @GroupID <> @Groupid_Old
				BEGIN
					BEGIN TRANSACTION
					UPDATE  accCustomer WITH (ROWLOCK, UPDLOCK)
						SET groupid = @groupid
					WHERE   custid = @custid
					COMMIT TRANSACTION
	                			                
				----Get Policy of Old group 	
					SELECT		@Permission_Old = COALESCE(@Permission_Old + ';', '') +  CAST(O.FuncID AS VARCHAR(20))+','+ CAST(O.Policy AS VARCHAR(20)),
								@Permission_New = COALESCE(@Permission_New + ';', '') +  CAST(N.FuncID AS VARCHAR(20))+','+ CAST(N.Policy AS VARCHAR(20))
					FROM		Acc_GroupPolicy O WITH (NOLOCK)
					INNER JOIN	Acc_GroupPolicy N WITH (NOLOCK)
							ON	O.FuncID = N.FuncID
					WHERE	O.GroupID= @Groupid_Old 
							AND N.GroupID= @groupid
							AND O.Policy <> N.Policy	
				END	
				
				IF @ExpiredDate <> @ExpiredDate_Old
				BEGIN
					BEGIN TRANSACTION
					UPDATE  accCustomer WITH (ROWLOCK, UPDLOCK)
						SET ExpiredDate = @ExpiredDate
					WHERE   custid = @custid
					COMMIT TRANSACTION
	            END
			END
		END
	ELSE
		BEGIN
			SELECT @ErrMsg = CASE @Language WHEN 'E'	THEN N'This groupid ' + CONVERT (VARCHAR (20), @groupid) + ' is invalid.' 
											WHEN 'CS'	THEN N'This groupid ' + CONVERT (VARCHAR (20), @groupid) + ' is invalid.' 
											WHEN 'J'	THEN N'This groupid ' + CONVERT (VARCHAR (20), @groupid) + ' is invalid.' 
														ELSE N'This groupid ' + CONVERT (VARCHAR (20), @groupid) + ' is invalid.' END,
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
									'<ExpiredDate>'+
										'<Old>' + ISNULL(@ExpiredDate_Old,'') + '</Old>'+
										'<New>'+ ISNULL(@ExpiredDate,'') + '</New>'+
									'</ExpiredDate>'+
							  '</Acc_Con_AdminGroupUpd>'    					
							
			SET @End = GETDATE()
			SET @Duration = DATEDIFF(millisecond, @Begin, @End)
	        
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl] @custID = @custID, @Doing = @LogData, @userid = @UserID, @TypeID = 1, @actionid = 1700, @duration = @Duration
			END TRY
			BEGIN CATCH
				EXEC bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl] @custID = @custID, @Doing = @LogData, @userid = @UserID, @TypeID = 1, @actionid = 1700, @duration = @Duration
			END CATCH
		END
END
GO