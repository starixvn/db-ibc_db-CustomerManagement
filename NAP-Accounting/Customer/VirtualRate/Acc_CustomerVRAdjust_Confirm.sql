/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE  [dbo].[Acc_CustomerVRAdjust_Confirm] 
	@CustID int,
	@Message NVARCHAR(500) = '' OUTPUT
AS
/*
	Created: 20200826@Eden
	DB: DBCUST/CUSTDB
	Task: checking to show confirmation when update SMA VR1 (NAP)
		
	Revisions:
		- 20200826@Eden: Adjust VR setting for Soccer of Haifa, IBO [redmine: #140368]

	Parameter's Explanation:

	DECLARE @Message NVARCHAR(500)
	EXEC Acc_CustomerVRAdjust_Confirm 
		@CustID = 44757232
		, @Message = @Message OUTPUT
	SELECT @Message
*/	
BEGIN
	SELECT @Message = 'Are you sure that you want to update these virtual rate values for this account and all of its downlines'
	DECLARE @except NVARCHAR(200) = ''

	DECLARE @SportType SMALLINT, @Type TINYINT

	IF EXISTS ( SELECT 1 FROM  Custinfo c WITH(NOLOCK) WHERE CustID = @CustID AND roleID = 1)
	BEGIN
		SET @Message = 'Are you sure that you want to update this Virtual Exchange Rate value for this account?'
		RETURN
	END

	SELECT TOP 1 @SportType = ad.SportType
	FROM Custinfo c WITH(NOLOCK)
		INNER JOIN VRCustAutoAdjustment ad  WITH(NOLOCK)
			ON c.custid = ad.CustID
	WHERE @CustID IN (srecommend,mrecommend,recommend)
		AND ad.Status = 2

	SELECT TOP 1 @Type = ad.Type
	FROM Custinfo c WITH(NOLOCK)
		INNER JOIN VRAgentAutoAdjustment ad  WITH(NOLOCK)
			ON c.custid = ad.AgentID
	WHERE @CustID IN (srecommend,mrecommend)
		AND ad.Status = 2

	IF EXISTS(
		SELECT	1
		FROM	DBLOG.bodb_CustomerLog.dbo.UserLog_VirtualRateSettings ulvrs WITH (NOLOCK)
		WHERE @CustID IN (srecommend,mrecommend,recommend)
	)
		SET @except = ' except Auto Adjusted Members'

	IF @SportType = 99
		SET @except = @except + '? For the members who are waiting for the performance checking, only new virtual rate for soccer will be applied, the other sports will be kept unchanged.'
	ELSE IF @Type = 1
		SELECT @except = CASE WHEN @except <> '' THEN  @except + ' and Agents waiting for performance checking?'
								ELSE ' except Agents waiting for performance checking?'
							END
	ELSE 
		SELECT @except = @except + '?'

	SET @Message = @Message + @except
END
