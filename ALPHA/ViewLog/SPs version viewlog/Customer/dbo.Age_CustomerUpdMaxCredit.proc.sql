/****** Object:  Stored Procedure dbo.Age_CustomerUpdMaxCredit    Script Date: 9/25/2009 10:14:53 PM ******/
ALTER PROCEDURE [dbo].[Age_CustomerUpdMaxCredit] 
	@CustID int,
	@MaxCredit money = null, 
	@UserID int,	
	@SubAccID int = 0, --Sub-AccountID
	@Language varchar(2) = 'E',
	@IP varchar(20)='',
	@ErrCode int = 0 output, --default no error
	@ErrMsg nvarchar(600) = '' output 
AS

/*
Created: minhnguyen
Task : Update Agent's MaxCredit
DB: DB02.bodb02
Original: Age_CustomerUpdMaxCredit

Revisions:
    - 20090311@MinhNguyen: 
	- 20090729@Phuc: Write log subaccname instead of subaccid.
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20090917@Phuc: write log into DBLOG.
	- 20100101@Kiwi: Modify Log.
Param's Explanation:
â€¢ @MaxCredit: max credit agent give member 	
â€¢ @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
  
â€¢ @ErrMsg: Error description.
*/

SET NOCOUNT ON

--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
--end


--Specify roleid
DECLARE @roleid TINYINT, @username VARCHAR(30)
DECLARE @oldmaxcredit MONEY

SELECT @roleid = roleid, @username = username
FROM custinfo WITH (nolock)
WHERE custid = @custid

SELECT @oldmaxcredit = maxcredit 
FROM CustAgent (nolock)
WHERE custid = @custid

IF @oldmaxcredit = @MaxCredit
	return
	
------------------------------------------------------
IF (@roleid=2)
BEGIN
	-- Check condition:
	--	1. New MaxCredit must be >= (Current Max (Credit of all Members))
	--	2. New MaxCredit must be <= AgentCredit
	DECLARE @AgentCredit money	
	
	SELECT @AgentCredit = Credit
	FROM CustInfo (nolock)
	WHERE custid = @CustID
	
	IF @MaxCredit IS NOT NULL
	BEGIN
		DECLARE @MaxCreditMem_Max MONEY

		SELECT @MaxCreditMem_Max = MAX(ISNULL(credit,0)) FROM custinfo (nolock)
		WHERE recommend = @CustId AND roleid =1 

		IF @MaxCredit < @MaxCreditMem_Max AND (ISNULL(@MaxCredit,0) > 0)
		BEGIN
			SELECT @ErrMsg = 
							CASE @Language 
								WHEN 'E' THEN 'Update max credit unsuccessfully. The new max credit must be greater than or equal to the total credit of current members.'
								WHEN 'CS' THEN N'更新最高信用不成功。新的最高信用必须大于或等于总现任会员的信用。'
								WHEN 'CT' THEN N'更新最高信用不成功。新的最高信用必须大于或等于总现任会员的信用。'
								WHEN 'TH' THEN N'การอัพเดทเครดิตสูงสุดไม่สำเร็จ. เครดิตสูงสุดต้องมากกว่าหรือเท่ากับเครดิตของสมาชิกทั้งหมด'
								WHEN 'J' THEN N'Update max credit unsuccessfully. The new max credit must be greater than or equal to the total credit of current members.'
								WHEN 'KO' THEN N'Update max credit unsuccessfully. The new max credit must be greater than or equal to the total credit of current members.'
								ELSE N'Update max credit unsuccessfully. The new max credit must be greater than or equal to the credit of total current members.'
							end
							+' (' + CONVERT(VARCHAR(100), @MaxCreditMem_Max) + ').', @ErrCode = 119					 
			RETURN
		END 

		IF @MaxCredit > @AgentCredit 
		BEGIN
			SELECT @ErrMsg = 
							case @Language 
								when 'E' then 'Update max credit unsuccessfully. The new max credit must be less than or equal to the credit of this agent.'
								when 'CS' then N'更新最高信用不成功。新的最高信用必须小于或等于总现任代理的信用。'
								when 'CT' then N'更新最高信用不成功。新的最高信用必須小於或等於總現任代理的信用。'
								when 'TH' then N'การอัพเดทเครดิตสูงสุดไม่สำเร็จ. เครดิตสูงสุดต้องน้อกว่าหรือเท่ากับเครดิตของเอเย่นทั้งหมด'
								when 'J' then N'Update max credit unsuccessfully. The new max credit must be less than or equal to the credit of this agent.'
								when 'KO' then N'Update max credit unsuccessfully. The new max credit must be less than or equal to the credit of this agent.'
								else N'Update max credit unsuccessfully. The new max credit must be less than or equal to the credit of this agent.'
							end
							+' (' + convert(varchar(100), @AgentCredit) + ').', @ErrCode = 120					 
			return
		END 	
	END
	
	-- Do update Agent MaxCredit
	UPDATE CustAgent WITH(ROWLOCK,UPDLOCK)
	SET maxcredit = ISNULL(@MaxCredit, maxcredit)
	WHERE custid = @custid 
	
END
--Write Log Credit
Declare @LogData varchar(200)
Select @LogData = 'Update Member Max credit for account ' + coalesce(cast(@username as varchar(30)),space(1))

-- ***Check Sub-Account***  
IF @SubAccID > 0 
BEGIN
	SET @LogData = @LogData + ' by Sub-Account ' +  COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)),SPACE(1))
END
---------------------------  

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Credit_New
	@UserID = @UserID,
	@CustID = @CustID,
	@Doing = @LogData,
	@OldValue = @oldmaxcredit,
	@NewValue = @maxcredit,
	@IP = @IP,
	@ActionID = 1206

GO 
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerUpdMaxCredit] TO [vnteam]
GO 
GRANT EXECUTE ON [dbo].[Age_CustomerUpdMaxCredit] TO [bodbDownlineNet]

