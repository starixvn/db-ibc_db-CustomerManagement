/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelDangerCust]
	@username VARCHAR(30),
	@CheckCustId TINYINT = 0,
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
          , @uplineid INT		  
          , @roleid TINYINT

	--Get CustID FROM DB06, WHERE got index on Username AND Username2 or CustID
    EXEC @custid = DBACC.bodb02.dbo.f_GetCustIDFromUsernameOrCustId @username, @CheckCustId

	SELECT @ErrCode = 0, @ErrMsg = ''
	
	IF @custid is NULL
    BEGIN
		SELECT @ErrMsg = 'This Username does not exist.'
		SELECT @ErrCode = 1

		RETURN
	END

	SELECT CI.danger, CI.danger2, CI.danger3, CI.dangercust, CI.DangerLevel
	FROM CUSTINFO CI WITH (NOLOCK)
	WHERE CI.custid = @custid
END