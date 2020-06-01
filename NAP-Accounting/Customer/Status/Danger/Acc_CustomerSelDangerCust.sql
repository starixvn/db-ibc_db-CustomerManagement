/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelDangerCust]
	@username VARCHAR(30),
	@UserId INT = 0,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(500) = '' OUTPUT
AS

/*
Created: 
Task : Show danger info of customer
DB: DBCUST/CUSTDB
Original:Accounting site

Revisions:
	- 20200508@Tiara: NAP Enhance Dangerous Grouping function [#Redmine: 129306]

Param's Explanation:
	@username: username to get danger info
*/	

BEGIN
    SET NOCOUNT ON
	DECLARE @custid INT

	--Get CustID FROM DB06, WHERE got index on Username AND Username2 
    EXEC @custid = DBACC.bodb02.dbo.f_GetCustIDFromUsername @username

	SELECT @ErrCode = 0, @ErrMsg = ''
	
	EXECUTE dbo.Acc_CustomerCheckDangerCustList
	@UsernameList= @Username ,		
	@UserID = @UserID	,		
	@DangerType	= 0	,	
	@DangerLevel =0	,
	@ErrCode = @ErrCode	OUTPUT,
	@ErrMsg = @ErrMsg	OUTPUT	

	IF @ErrCode <> 0
		RETURN;
	    --General info
    DECLARE @isBA BIT
    IF EXISTS (
			     SELECT 1 FROM bodb_Licensee.dbo.LicenseeBAHistory lb WITH(NOLOCK)
			     WHERE custid=@custid AND status='running'
			    )
	    SET @isBA=1
    ELSE
	    SET @isBA=0

	SELECT ci.roleid, CI.danger, CI.danger2, CI.danger3, CI.dangercust, CI.DangerLevel, @isBA AS IsBA
	FROM CUSTINFO CI WITH (NOLOCK)
	WHERE CI.custid = @custid
END