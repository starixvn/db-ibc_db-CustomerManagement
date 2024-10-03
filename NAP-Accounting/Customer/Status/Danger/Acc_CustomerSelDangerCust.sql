/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelDangerCust]
	@username VARCHAR(30),
	@UserId INT = 0,
	@AdName	VARCHAR(30), -- UserID's username
	@Permission	VARCHAR(20) = '1,2,3',
	@DeniedList	NVARCHAR(MAX)=NULL,
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
	- 20210819@Johnson: Add 2 new Dangerous types for Basketball & Esports [redmine:#159551]
	- 20220926@Tacy: Remove isBA column [RedmineID: #176518]
	- 20240816@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]

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
	@AdName = @AdName,
	@Permission	= @Permission,
	@DeniedList	= @DeniedList,
	@ErrCode = @ErrCode	OUTPUT,
	@ErrMsg = @ErrMsg	OUTPUT	

	IF @ErrCode <> 0
		RETURN;
	
	--General info
	SELECT ci.roleid, CI.danger, CI.danger2, CI.danger3,
	ISNULL(ci.danger4,0) as danger4,
	ISNULL(ci.danger5,0) as danger5,
	CI.dangercust, CI.DangerLevel
	FROM CUSTINFO CI WITH (NOLOCK)
	WHERE CI.custid = @custid
END