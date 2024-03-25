/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,wsv_alp" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerUpdCredit_MAg]
	@UserID			INT,
	@CustID			INT, -- agentID
	@SubAccID		INT				= 0, -- Sub-AccountID
	@CreditAmt		MONEY,
	@IP				VARCHAR(15)		= '',
	@Language		VARCHAR(2)		= 'E',
	@CreditProblem	BIT				= 0 OUTPUT,
	@ErrMsg			NVARCHAR(500)	= '' OUTPUT
AS

/*
	Created: 20090211@xxx
	Task: Used to edit Agent Credit
	DB: DBCUST.CustDB

	Revisions:    
		- 20090318@Hanh: add Korean language
		- 20090729@Phuc: Write log subaccname instead of subaccid.
		- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
		- 20090903@Simon: Write Credit Log into Userlog_Credit table.
		- 20090917@Phuc: write log into DBLOG.
		- 20090929@Jamie: Check the old credit and the new credit before updating 
		- 20100101@Kiwi: Modify Log.
		- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
		- 20130218@Dan: Write more log on DBTXN server in case of DBLOG server failure
		- 20140423@Elodie: Implement SMA Turnover [Redmine:#14426]
		- 20150228@Kiwi: Fix for Member's given credit is greater than that of upline [Redmine:31476]
		- 20171107@Percy: Prevent user from decreasing given credit due to data processing [RedmineID: #82834]
		- 20181101@Johnson: Apply service broker for logging [Redmine: #103547]
		- 20200504@Johnson: allow negative given credit for some supers [redmine:#132994]
		- 20200623@Johnson: revert to not allow negative given credit [redmine:#132994]
		- 20230227@Evan: Balance-Up support transfer 247 [Redmine: #173554]
		- 20231019@Helios: Customer Setting - Migrate Sportsbook to DCS [RedmineID: #193083]
	Param's Explanation:
		• @custid: custid that need to be updated 
		• @CreditAmt: new credit 
*/

BEGIN
	SET NOCOUNT ON

	DECLARE
		@Credit_AllMember MONEY, 
		@Credit_AllOtherAgent MONEY, 
		@Credit_MAg MONEY
	
	DECLARE @ErrCode INT = 0
	
	DECLARE @SAgID INT, @MAgID INT, @username VARCHAR(50), @OldCredit MONEY, @RoleID TINYINT
	
	SELECT @SAgID = srecommend, @MAgID = mrecommend, @username = username, @OldCredit = Credit, @RoleID = roleid
	FROM dbo.custInfo WITH (NOLOCK)
	WHERE custid = @CustID

	IF (ISNULL(@RoleID, 0) <> 2)
	BEGIN
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Invalid user!!' ELSE [dbo].[f_Get_MsgNamebyMsgID](40002, @Language) END
		RETURN
	END

	IF ISNULL(@OldCredit, 0) = ISNULL(@CreditAmt, 0)
		RETURN
		
	IF @CreditAmt < 0
	BEGIN
		SELECT	@CreditProblem = 1,
				@ErrMsg = CASE @Language WHEN 'E' THEN 'Credit must be positive.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](70025, @Language) END
		RETURN	
	END
	

	SELECT @Credit_AllOtherAgent = ISNULL(SUM(ISNULL(credit, 0)), 0)
	FROM dbo.custInfo WITH (NOLOCK)
	WHERE mrecommend = @MAgID AND roleid = 2 AND CustID <> @CustID

	Select @Credit_AllMember = ISNULL(SUM(ISNULL(credit, 0)), 0)
	FROM dbo.custInfo WITH (NOLOCK)
	WHERE recommend = @CustID AND roleid = 1

	Select @Credit_MAg = ISNULL(credit, 0)
	FROM dbo.custInfo WITH (NOLOCK)
	WHERE custid = @MAgID

	IF @Credit_AllOtherAgent + @CreditAmt > @Credit_MAg
	BEGIN
		SELECT	@CreditProblem = 1,
				@ErrMsg = REPLACE(CASE @Language WHEN 'E' THEN 'The new credit has exceeded the available given credit ({number}).'
												ELSE [dbo].[f_Get_MsgNamebyMsgID](70030,@Language) 
											END  
											, '{number}', FORMAT(@Credit_MAg - @Credit_AllOtherAgent, '#,#0.####'))
		RETURN
	END
	
	IF @Credit_AllMember > @CreditAmt
	BEGIN
		SELECT	@CreditProblem = 1,
				@ErrMsg = REPLACE(CASE @Language WHEN 'E' THEN 'The new credit is insufficient for all current Members ({number}).'
												ELSE [dbo].[f_Get_MsgNamebyMsgID](70033,@Language) 
											END  
											, '{number}', FORMAT(@Credit_AllMember, '#,#0.####'))
		RETURN
	END

	UPDATE dbo.custInfo WITH (ROWLOCK)
	SET credit = @CreditAmt
	WHERE CustID = @CustID
	
	-- Write Log
	DECLARE @LogData VARCHAR(500)
	SELECT  @LogData = 'Update credit for agent account ' + COALESCE(@username, SPACE(1))

	IF @SubAccID > 0
	BEGIN
		SELECT @LogData = @LogData + ' by Sub-Account ' + COALESCE(dbo.f_GetSubUsername(@SubAccID), SPACE(1))
	END
	
	
	DECLARE @log xml, @SB_Error BIT = 0
 
	SELECT @log = (SELECT @UserID as '@UserID',
						@custid as '@CustID',
						@LogData as '@Doing',
						@OldCredit as '@OldValue',
						@CreditAmt as '@NewValue',
						@IP as '@IP',
						1204 as '@ActionID',
						getdate() as '@LogDate'
					FOR XML PATH('Row')	
				)

	EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @log, 
													@MessageType='MessageType_CustomerLog_UserLog_Credit', 
													@functionName = 'UserLog_Others',
													@SB_Error = @SB_Error out

	--if ssb error
	IF @SB_Error = 1
	BEGIN		
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Credit
				@UserID = @UserID,
				@CustID = @CustID,
				@Doing = @LogData,
				@OldValue = @OldCredit,
				@NewValue = @CreditAmt,
				@IP = @IP,
				@ActionID = 1204
		END TRY
		BEGIN CATCH		
			SELECT @LogData = @LogData + ' ErrMsg=' + ERROR_MESSAGE()
		
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Credit
				@UserID = @UserID,
				@CustID = @CustID,
				@Doing = @LogData,
				@OldValue = @OldCredit,
				@NewValue = @CreditAmt,
				@IP = @IP,
				@ActionID = 1204	
		END CATCH
	END	
END
GO
