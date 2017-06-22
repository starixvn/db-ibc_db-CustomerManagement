ALTER PROCEDURE [dbo].[Acc_Con_AdminInsFromExisted]
	@username VARCHAR (30), 
	@GroupId INT, 
	@creator INT, 
	@ErrCode INT=0 OUTPUT, 
	@ErrMsg NVARCHAR (200)='' OUTPUT, 
	@Language VARCHAR (2)='E', 
	@System VARCHAR (50)='ACCOUNTING'
AS
/*
Created: 
Task : create AccAdmin from existed Admin
DB: DBPOLICY/BODB02
Original:

Revisions:
    - 20080213@Phuc: Check permission for account site
	- 20110526@Tom: Remove condition @System and Write log into table DBlog.bodb_CustomerLog.dbo.UserLog_UserControl"
	- 20120601@Sophia: Modify @LogData
	- 20130125@Elodie: Write more log on UserLog table in case of DBLOG server failure

*/
SET NOCOUNT ON;
DECLARE @Begin AS DATETIME;
SET @Begin = GETDATE();
--Check permission for account site: @phuc20080213
EXEC dbo.Acc_Con_CheckPermission @custid = @creator, @funcname = '[UserControl]', @System = @System, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT;
IF @ErrCode <> 0
   RETURN;
--end
DECLARE @custid AS INT, 
@roleid AS INT;
SELECT @custid = custid,
       @roleid = roleid
FROM   customer AS c WITH (NOLOCK)
WHERE  username = @username
       AND roleid BETWEEN 5 AND 10;
SELECT @custid = isnull(@custid, 0);
IF @custid = 0
   BEGIN
      SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Invalid username.' WHEN 'CS' THEN N'Invalid username.' WHEN 'J' THEN N'Invalid username.' ELSE N'Invalid username.' END,
             @ErrCode = 101;
      RETURN;
   END
ELSE
   BEGIN
      IF EXISTS (SELECT 1
                 FROM   accCustomer_1 WITH (NOLOCK)
                 WHERE  custid = @custid)
         BEGIN
            SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'This user has been existed as an accounting admin before.' WHEN 'CS' THEN N'This user has been existed as an accounting admin before.' WHEN 'J' THEN N'This user has been existed as an accounting admin before.' ELSE N'This user has been existed as an accounting admin before.' END,
                   @ErrCode = 102;
            RETURN;
         END
      ELSE
         BEGIN
            -- add existed admin
            BEGIN TRANSACTION;
            INSERT  INTO accCustomer_1 (CustID, createdate, creator, groupid)
            VALUES                    (@custid, getdate(), @creator, @groupid);
            INSERT INTO Acc_MemberPolicy_1 (CustID, FuncID, Policy, CreateDate, ModifyDate, Creator)
            -- 0 is default value of the member policy  when create new admin 
            SELECT @Custid AS custid,
                   FuncID,
                   0 AS Policy,
                   getdate() AS Createdate,
                   getdate() AS ModifyDate,
                   @creator AS Creator
            FROM   Acc_GroupPolicy_1 WITH (NOLOCK)
            WHERE  GroupId = @GroupID;
            IF @@ERROR <> 0
               BEGIN
                  ROLLBACK;
                  SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Add customer failed.' WHEN 'CS' THEN N'Add customer failed.' WHEN 'J' THEN N'Add customer failed.' ELSE N'Add customer failed.' END,
                         @ErrCode = 103;
                  RETURN;
               END
            COMMIT TRANSACTION;
         END
   END
/**************Write to Log table ********************/
DECLARE @LogData AS NVARCHAR (500), 
@End AS DATETIME, 
@Duration AS INT;
SELECT @LogData = '<Acc_Con_AdminInsFromExisted>'+
						'<ToGroup>' + ISNULL([dbo].[f_Get_GroupNameByGroupID](@GroupID),'') + '</ToGroup>'+
				  '</Acc_Con_AdminInsFromExisted>'

SET @End = GETDATE()
SET @Duration = DATEDIFF(millisecond, @Begin, @End)

BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl] @custID = @custid, @Doing = @LogData, @userid = @creator, @TypeID = 1, @actionid = 1702, @duration = @Duration;
END TRY
BEGIN CATCH
	SELECT @LogData = '<Acc_Con_AdminInsFromExisted> ' +						
						'ErrMsg="' + COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" ' + 
				  '</Acc_Con_AdminInsFromExisted>'
				  
	EXEC WriteLog_UserLog @UserID = @creator, 
						  @Doing = @LogData				  
END CATCH	

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminInsFromExisted] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_Con_AdminInsFromExisted] TO [bodbAdminNet]

