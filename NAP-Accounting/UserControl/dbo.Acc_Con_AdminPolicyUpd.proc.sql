ALTER PROCEDURE [dbo].[Acc_Con_AdminPolicyUpd]
	@OldMemPolicys NVARCHAR(MAX)= '', 
	@MemPolicys NVARCHAR(MAX)= '', 	
	@CustID INT,
	@UserID INT, 
	@isABS BIT = 0,
	@Language VARCHAR (2)='E', 
	@ErrCode INT=0 OUTPUT, 
	@ErrMsg NVARCHAR (200)='' OUTPUT, 
	@System VARCHAR (50)='ACCOUNTING'
AS
/*
Created: 
Task : UPDATE (multiple) Policy for account
DB: DBPOLICY/bodb02
Original:

Revisions:
	- 20110526@Tom: Remove condition @System and Write log into table DBLog.bodb_CustomerLog.dbo.UserLog_UserControl
	- 20110624@Tom: Change DB02 to DBTRANS (SplittingEXECUTE DB02 to DBPros and DBTRANS)
	- 20111017@Johnson: Check permission for update ABS system
	- 20120531@Sophia: Change the way to write log & add new parameter @OldMemPolicys
	- 20130118@Elodie: Get Username from currrent server instead of DBTrans 
					   Write more log on UserLog table in case of DBLOG server failure
	
Param's Explanation:
	Format of @MemPolicys @FuncID,@Policy@FuncID,@Policy ...
*/
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
EXEC dbo.Acc_Con_CheckPermission @custid = @UserID, @funcname = @permission, @System = @System, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
IF @ErrCode <> 0
   RETURN
--end

DECLARE @UserName AS NVARCHAR (200), @CustName AS NVARCHAR (200)
SELECT @UserName = UserName  
from bodb02.dbo.custInfo with(nolock)  
where custid = @UserID
--
SELECT @CustName = UserName  
from bodb02.dbo.custInfo with(nolock)  
where custid = @CustID

IF @CustName IS NULL
	BEGIN
		SELECT @ErrMsg =  case @Language  
			when 'E' then N'Account is not exist'  
			when 'CS' then N'Account is not exist'  
			when 'J' then N'Account is not exist'  
			else N'Account is not exist'  
			end,@ErrCode = 500  
		RETURN
	END

DECLARE @MemPolicy AS NVARCHAR (MAX), @OldMemPolicy AS NVARCHAR (MAX),
@FuncID AS INT, 
@Policy AS INT


----------Check format of Account Old Policies---------

IF @OldMemPolicys =''
BEGIN
	SELECT @ErrMsg =  case @Language  
					when 'E' then N'Check format of Account Old Policies.'  
					when 'CS' then N'Check format of Account Old Policies.'  
					when 'J' then N'Check format of Account Old Policies.'  
					else N'Check format of Account Old Policies.'  
					end,@ErrCode = 500  	 
	RETURN
END
		

DECLARE OldPolicysCur CURSOR
   FOR SELECT   DISTINCT val AS row_index
       FROM     dbo.strSplit (@OldMemPolicys, ';')

OPEN OldPolicysCur
FETCH NEXT FROM OldPolicysCur INTO @OldMemPolicy
WHILE (@@FETCH_STATUS = 0)
BEGIN 
	if @OldMemPolicy+','<>dbo.Acc_SplitIndex(@OldMemPolicy, ',', 3) 
		Begin
			SELECT @ErrMsg =  case @Language  
							when 'E' then N'Check format of Account Old Policies.'  
							when 'CS' then N'Check format of Account Old Policies.'  
							when 'J' then N'Check format of Account Old Policies.'  
							else N'Check format of Account Old Policies.'  
							end,@ErrCode = 501  	 

			CLOSE OldPolicysCur
			DEALLOCATE OldPolicysCur
			RETURN
		End
	FETCH NEXT FROM OldPolicysCur INTO @OldMemPolicy
END 
CLOSE OldPolicysCur
DEALLOCATE OldPolicysCur


---------Check format of Account Policies---------

IF @MemPolicys =''
BEGIN
	SELECT @ErrMsg =  case @Language  
					when 'E' then N'Check format of Account Policies.'  
					when 'CS' then N'Check format of Account Policies.'  
					when 'J' then N'Check format of Account Policies.'  
					else N'Check format of Account Policies.'  
					end,@ErrCode = 502  	 
	RETURN
END


Create Table #Table_P(
		FuncID INT,
		Policy int
	)

DECLARE PolicysCur CURSOR
   FOR SELECT   DISTINCT val AS row_index
       FROM     dbo.strSplit (@MemPolicys, ';')

OPEN PolicysCur
FETCH NEXT FROM PolicysCur INTO @MemPolicy
WHILE (@@FETCH_STATUS = 0)
BEGIN 
		if @MemPolicy+','<>dbo.Acc_SplitIndex(@MemPolicy, ',', 3) 
			Begin
				SELECT @ErrMsg =  case @Language  
							when 'E' then N'Check format of Account Policies.'  
							when 'CS' then N'Check format of Account Policies.'  
							when 'J' then N'Check format of Account Policies.'  
							else N'Check format of Account Policies.'  
							end,@ErrCode = 503  
				CLOSE PolicysCur
				DEALLOCATE PolicysCur
				DROP TABLE #Table_P
				RETURN
			End
		ELSE

	Begin
		SET @FuncID = dbo.Acc_SplitIndex(@MemPolicy, ',', 1)
		SET @Policy = dbo.Acc_SplitIndex(@MemPolicy, ',', 2)

		INSERT INTO #Table_P (FuncID ,Policy )
		VALUES (@FuncID ,@Policy )
	END
		FETCH NEXT FROM PolicysCur INTO @MemPolicy
	END
CLOSE PolicysCur
DEALLOCATE PolicysCur

------------------- Update Policy ------------------- 

DECLARE CustPolicysCur CURSOR
FOR SELECT Funcid, Policy
   FROM     #Table_P

OPEN CustPolicysCur
FETCH NEXT FROM CustPolicysCur INTO @Funcid, @Policy

WHILE @@FETCH_STATUS = 0
   BEGIN
      IF NOT EXISTS (SELECT 1
                     FROM   Acc_MemberPolicy_1 WITH (NOLOCK)
                     WHERE  CustID = @CustID
                            AND funcid = @FuncID)

         INSERT  INTO Acc_MemberPolicy_1 (CustID, Funcid, Policy, Createdate, Modifydate, Creator)
         VALUES                         (@CustID, @Funcid, @Policy, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, @UserID)
      ELSE
         UPDATE Acc_MemberPolicy_1
            SET policy     = @Policy,
                modifydate = CURRENT_TIMESTAMP
         WHERE  CustID = @CustID
                AND funcid = @FuncID

	 FETCH NEXT FROM CustPolicysCur INTO @Funcid, @Policy
   END
CLOSE CustPolicysCur
DEALLOCATE CustPolicysCur
DROP TABLE #Table_P

/**************Write to Log *******************/
SELECT @LogData = '<Acc_Con_AdminPolicyUpd>'+
					'<Permission>'+
						'<Old>'+ ISNULL(@OldMemPolicys,'') +'</Old>'+
						'<New>'+ ISNULL(@MemPolicys,'') +'</New>'+
					'</Permission>'+
				'</Acc_Con_AdminPolicyUpd>'      

SET @End = GETDATE()
SET @Duration = DATEDIFF(millisecond, @Begin, @End)

BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl] 
		@custID = @CustID, 
		@Doing = @LogData, 
		@userid = @UserID,
		@TypeID = 1, 
		@actionid = 1703, 
		@duration = @Duration
END TRY
BEGIN CATCH
	SELECT @LogData = '<Acc_Con_AdminPolicyUpd> ' +					
					'ErrMsg="' + COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" ' + 					
				'</Acc_Con_AdminPolicyUpd>'      
				
	EXEC WriteLog_UserLog @UserID = @UserID, 
						  @Doing = @LogData
END CATCH
      
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminPolicyUpd] TO [vnteam]

GO
GRANT EXECUTE ON [dbo].[Acc_Con_AdminPolicyUpd] TO [bodbAdminNet]

