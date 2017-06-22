/*--Notice for sps below
Acc_CustomerInsMember_Com ==> ActionID = 600
Acc_CustomerInsMember_SAg ==> ActionID = 601
Acc_CustomerInsMember_MAg ==> ActionID = 602
Acc_CustomerInsMember_Ag ==> ActionID = 603
Dot_Dep_CustomerInsMember_Ag ==> ActionID = 617
Acc_CustomerUpdMember_Super ==> ActionID = 404
*/

declare @ActionID int, @SPName varchar (50), @fromdate smalldatetime, @todate smalldatetime

select @SPName = 'Acc_CustomerUpdSuper_Commission',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

select @ActionID = ActionID from LogAction (nolock)
where SPName = @SPName

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.ConvertToXML(@SPName, Doing),
	ActionID = @ActionID
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END