/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE  [dbo].[Acc_CreditTermUpdCustAccount]
	@custid int,
	@creditgrade nvarchar(1) = '',
	@preagreeamount money,
	@installmentamount money,
	@installmentdate nvarchar(50),
	@accountremark nvarchar(200),
	@groupID int,
	@isgroupheadline bit,
	@checker int=null,
	@UserID int = null,
	@IP varchar(15) = ''
AS
/*	
	Created:  
	Date:  
	Task :  
	DB: DBCUST/CustDB
	Original:  
	Revisions:
		- 20160607@Elodie: Add headline type and their owner [Redmine:#51923]
		- 20160915@Elodie: SMA Mangement allows to input freetext for Owner info [Redmine:#63349]
		- 20240909@Tacy: NAP - White Label [Redmine:#209807]
		- 20250102@Hughie: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]
		- 20250317@July: Scale Out DBCUST - Change unique key table CustGroupHeadline [Redmine: #221252]
*/
BEGIN 
	DECLARE @NotificationInfo VARCHAR(MAX), @CreateDate DATETIME, @CustID_Headline INT
	SET @CreateDate = GETDATE()
	
	IF @isgroupheadline = 0
	BEGIN
		DELETE dbo.CustGroupHeadline WITH (ROWLOCK)
			OUTPUT DELETED.CustID, dbo.f_GetDateTime2(), DELETED.ID
			INTO CustGroupHeadline_Del_Inhouse (CustID, RepUpdateTime, ID)
		WHERE CustID = @custid
	END
	ELSE
	BEGIN
	
		UPDATE dbo.CustGroupHeadline WITH (ROWLOCK, UPDLOCK) 
		SET CustID = @CustID,
			OwnerName = '',
			RepUpdateTime = dbo.f_GetDateTime2()
		WHERE GroupID = @groupID

		IF @@ROWCOUNT = 0
			INSERT INTO CustGroupHeadline (CustID,GroupID, HeadlineType, OwnerName, RepUpdateTime)
			SELECT @custid, @groupID, 0, NULL, dbo.f_GetDateTime2()
	END

	UPDATE dbo.custAccount WITH (ROWLOCK, UPDLOCK) SET
		creditgrade = @creditgrade,
		preagreeamount = @preagreeamount,
		installmentamount = @installmentamount,
		installmentdate = @installmentdate,
		accountremarkdate = CASE WHEN accountremark = @accountremark THEN accountremarkdate ELSE CURRENT_TIMESTAMP END,
		accountremark = @accountremark,
		groupid = @groupid,
		isgroupheadline = @isgroupheadline,
		checker = isnull(@checker,0),
		RepUpdateTime = dbo.f_GetDateTime2()
	WHERE custid = @custid
	
	IF @@ROWCOUNT = 0
		INSERT INTO dbo.custAccount (custid, creditgrade, installmentdate, installmentamount, preagreeamount, accountremark, accountremarkdate,groupid,isgroupheadline,checker,RepUpdateTime)
		VALUES (@custid, @creditgrade, @installmentdate, @installmentamount, @preagreeamount, @accountremark, CURRENT_TIMESTAMP, @groupid,@isgroupheadline,isnull(@checker,0),dbo.f_GetDateTime2())

	--Update: GroupID for WhiteLabel
	BEGIN
		EXEC Acc_WhiteLabelSetting_UpdGroup	
			@CustIDList	= @CustID
			,@GroupID	= @groupID 
			,@UserID	= @UserID
			,@IP		= @IP
	END
END