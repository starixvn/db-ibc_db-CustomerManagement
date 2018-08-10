/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_Con_GroupPolicyUpd]  
 @OldGroupPolicys NVARCHAR (MAX) = '',  
 @GroupPolicys NVARCHAR (MAX) = '',  
 @GroupID INT,   
 @UserID INT,   
 @isABS BIT = 0,  
 @Language VARCHAR (2)='E',   
 @ErrCode INT=0 OUTPUT,   
 @ErrMsg NVARCHAR (200)='' OUTPUT,   
 @System VARCHAR (50)='ACCOUNTING'  
AS  
/*  
 Created by: []  
 Task: Update (multiple) Policy  for Group   
 DB: DBCUST/NAP_UserControl
  
 Revisions:  
  - 20110526@Tom: Remove condition @System and Write log into table DB03.bodb_CustomerLog.dbo.UserLog_UserControl  
  - 20110624@Tom: Change DB02 to DBTRANS (Splitting DB02 to DBPros and DBTRANS)  
  - 20111017@Johnson: Check permission for update ABS system  
  - 20120604@Sophia: . Edit @LogData  
					 . Add new parametter @OldGroupPolicys  
  - 20121110@Viet: get username from currrent server instead of DBTrans    
  - 20130118@Elodie: Get Username by GroupID from currrent server instead of DBTrans 
					 Write more log on UserLog table in case of DBLOG server failure
 - 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]					 
     
 Explain @Paramater  
  -- Format of @GroupPolicys: @FuncID,@Policy@FuncID,@Policy ...   
*/  
BEGIN
	SET NOCOUNT ON  
	DECLARE @LogData AS NVARCHAR(MAX), @permission VARCHAR(50),  
	@Begin AS DATETIME,   
	@End AS DATETIME,   
	@Duration AS INT  
	SET @Begin = GETDATE()  
	  
	IF @isABS = 1  
	 SELECT @permission = '[ABSAdminUserControl]'  
	ELSE   
	 SELECT @permission = '[UserControl]'  
	  
	--Check permission for account site: @phuc20080213  
	EXEC DBPOL.NAP_UserControl.dbo.Acc_Con_CheckPermission @custid = @UserID, @funcname = @permission, @System = @System, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT  
	IF @ErrCode <> 0  
		RETURN  
	--end  
	DECLARE @UserName AS NVARCHAR (200),   
	@GroupName AS NVARCHAR (200)  
	  
	--EXEC @UserName = DBTRANS.BODB02.[dbo].[f_Get_CustNameByCustID] @UserID  
	  
	select @UserName = username
	from bodb02.dbo.custInfo with(nolock)  
	where custid = @UserID  
	  
	DECLARE @GroupPolicy AS NVARCHAR (500), @OldGroupPolicy AS NVARCHAR (500),   
	@FuncID AS INT,   
	@Policy AS INT  
	  
	-------------------Check format of Group Old Policys-------------------  
	  
	IF @OldGroupPolicys = ''   
	  Begin  
		SELECT @ErrMsg =  case @Language    
		   when 'E' then N'Check format of Group Old Policys.'    
		   when 'CS' then N'Check format of Group Old Policys.'    
		   when 'J' then N'Check format of Group Old Policys.'    
		   else N'Check format of Group Old Policys.'    
		   end,@ErrCode = 500    
		RETURN  
	  End  
	  
	DECLARE OldGroupPolicysCur CURSOR FOR  
	   SELECT Distinct val AS row_index  
	   FROM     dbo.strSplit (@OldGroupPolicys, ';')  
	  
	OPEN OldGroupPolicysCur  
	FETCH NEXT FROM OldGroupPolicysCur INTO @OldGroupPolicy  
	WHILE @@FETCH_STATUS = 0  
	Begin  
	  if @OldGroupPolicy+','<>dbo.Acc_SplitIndex(@OldGroupPolicy, ',', 3)   
	   Begin  
		SELECT @ErrMsg =  case @Language    
		   when 'E' then N'Check format of Group Old Policys.'    
		   when 'CS' then N'Check format of Group Old Policys.'    
		   when 'J' then N'Check format of Group Old Policys.'    
		   else N'Check format of Group Old Policys.'    
		   end,@ErrCode = 501    
		CLOSE OldGroupPolicysCur  
		DEALLOCATE OldGroupPolicysCur  
		RETURN  
	   End  
		FETCH NEXT FROM OldGroupPolicysCur INTO @OldGroupPolicy  
	 END  
	CLOSE OldGroupPolicysCur  
	DEALLOCATE OldGroupPolicysCur  
	  
	-------------------Check format of Group Policys-------------------  
	  
	IF @GroupPolicys = ''   
	  Begin  
		SELECT @ErrMsg =  case @Language    
		   when 'E' then N'Check format of Group Policys.'    
		   when 'CS' then N'Check format of Group Policys.'    
		   when 'J' then N'Check format of Group Policys.'    
		   else N'Check format of Group Policys.'    
		   end,@ErrCode = 502    
		RETURN  
	  End  
	     
	------    
	Create Table #Table_P(  
	  FuncID INT,  
	  Policy int  
	 )  
	       
	DECLARE GroupPolicysCur CURSOR  
	   FOR SELECT Distinct val AS row_index  
		   FROM     dbo.strSplit (@GroupPolicys, ';')  
	  
	OPEN GroupPolicysCur  
	FETCH NEXT FROM GroupPolicysCur INTO @GroupPolicy  
	WHILE @@FETCH_STATUS = 0  
	Begin  
	  if @GroupPolicy+','<>dbo.Acc_SplitIndex(@GroupPolicy, ',', 3)   
	   Begin  
		SELECT @ErrMsg =  case @Language    
		   when 'E' then N'Check format of Group Policys.'    
		   when 'CS' then N'Check format of Group Policys.'    
		   when 'J' then N'Check format of Group Policys.'    
		   else N'Check format of Group Policys.'    
		   end,@ErrCode = 503    
		CLOSE GroupPolicysCur  
		DEALLOCATE GroupPolicysCur  
		DROP TABLE #Table_P  
		RETURN  
	   End  
	  ELSE   
		  SET @FuncID = dbo.Acc_SplitIndex(@GroupPolicy, ',', 1)  
		  SET @Policy = dbo.Acc_SplitIndex(@GroupPolicy, ',', 2)  
	  
	 INSERT INTO #Table_P (FuncID ,Policy )  
	 VALUES(@FuncID ,@Policy )  
	   
	 FETCH NEXT FROM GroupPolicysCur INTO @GroupPolicy  
	 END  
	CLOSE GroupPolicysCur  
	DEALLOCATE GroupPolicysCur  
	  
	-------------------------Update Policy--------------------  
	  
	DECLARE GroupPolicysCur CURSOR  
	   FOR SELECT Funcid, Policy  
		   FROM     #Table_P  
	  
	OPEN GroupPolicysCur  
	FETCH NEXT FROM GroupPolicysCur INTO @Funcid, @Policy  
	IF (@@FETCH_STATUS = 0)  
		BEGIN  
			SET @GroupName = [dbo].[f_Get_GroupNameByGroupID](@GroupID)  
		END  
	WHILE @@FETCH_STATUS = 0  
	   BEGIN  
			IF NOT EXISTS (SELECT 1  
						   FROM   Acc_GroupPolicy WITH (NOLOCK)  
						   WHERE  GroupID = @GroupID  
								  AND funcid = @FuncID)  
				BEGIN  
					INSERT  INTO Acc_GroupPolicy (GroupID, Funcid, Policy, Createdate, Modifydate, Creator)  
					VALUES                        (@GroupID, @Funcid, @Policy, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, @UserID)  
				END  
			ELSE  
				BEGIN  
					UPDATE  Acc_GroupPolicy  
						SET policy     = @Policy,  
							modifydate = CURRENT_TIMESTAMP  
					WHERE   GroupID = @GroupID  
							AND funcid = @FuncID  
				END  
		   FETCH NEXT FROM GroupPolicysCur INTO @Funcid, @Policy  
	   END  
	CLOSE GroupPolicysCur  
	DEALLOCATE GroupPolicysCur  
	DROP TABLE #Table_P   
	  
	  
	/**************Write to Log for Group ********************/  
	  
	--------Get Username from GroupID  
	DECLARE @Members NVARCHAR(MAX)  
	  
	SELECT @Members = COALESCE (@Members+';', '') + C.Username  
	FROM accCustomer A WITH (NOLOCK)    
	INNER JOIN Custinfo C WITH(NOLOCK)    
	 ON A.CustId = C.CustID  
	WHERE A.GroupID = @GroupID  
	ORDER BY  C.Username  
	  
	---Write log  
	 SELECT @LogData = '<Acc_Con_GroupPolicyUpd>'+  
		   '<GroupID>'+ ISNULL(CONVERT(VARCHAR(20),@GroupID),'') + '</GroupID>'+  
		   '<GroupName>'+ ISNULL([dbo].[f_EncodeXMLValue](@GroupName),'') + '</GroupName>'+  
		   '<Permission>' +   
			'<Old>' + ISNULL(@OldGroupPolicys,'') + '</Old>' +  
			'<New>' + ISNULL(@GroupPolicys,'') + '</New>' +  
		   '</Permission>'+   
		   '<Members>'+ ISNULL([dbo].[f_EncodeXMLValue](@Members),'') +'</Members>'+  
		  '</Acc_Con_GroupPolicyUpd>'  
	  
	 SET @End = GETDATE()  
	 SET @Duration = DATEDIFF(millisecond, @Begin, @End)  
	 BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl]   
			@custID = @GroupID,   
			@Doing = @LogData,   
			@userid = @UserID,   
			@TypeID = 0, -- For Group  
			@actionid = 1709,   
			@duration = @Duration  
	END TRY
	BEGIN CATCH
							  
	END CATCH	      
	/**************Write to Log for custid ********************/  
	DECLARE @Mem INT  
	DECLARE MemCur CURSOR FOR  
	  SELECT CustID  
	  FROM   accCustomer WITH (NOLOCK)    
	  WHERE  GroupID = @GroupID  
	OPEN MemCur  
	FETCH NEXT FROM MemCur INTO @Mem  
	WHILE @@FETCH_STATUS = 0  
	 BEGIN        
		   SELECT @LogData = '<Acc_Con_GroupPolicyUpd>'+  
			'<GroupID>'+ ISNULL(CONVERT(VARCHAR(20),@GroupID),'') + '</GroupID>'+  
			'<GroupName>'+ ISNULL([dbo].[f_EncodeXMLValue](@GroupName),'') + '</GroupName>'+  
			'<Permission>' +   
			 '<Old>' + ISNULL(@OldGroupPolicys,'') + '</Old>' +  
			 '<New>' + ISNULL(@GroupPolicys,'') + '</New>' +  
			'</Permission>'+   
		   '</Acc_Con_GroupPolicyUpd>'  
		SET @End = GETDATE()  
		SET @Duration = DATEDIFF(millisecond, @Begin, @End)  
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl]   
				@custID = @Mem,   
				@Doing =  @LogData,   
				@userid = @UserID,   
				@TypeID = 1, --- For admin  
				@actionid = 1709,   
				@duration = @Duration  
	   END TRY
	   BEGIN CATCH
						   
	   END CATCH
	 FETCH NEXT FROM MemCur INTO @Mem   
	 END  
	  
	CLOSE MemCur  
	DEALLOCATE MemCur  
END  
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_GroupPolicyUpd] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_Con_GroupPolicyUpd] TO [bodbAdminNet]
  