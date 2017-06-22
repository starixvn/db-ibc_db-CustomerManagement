--409	Acc_CustomerUpdMemberHR_MAg	Update Master's Horse racing Position Taking at member

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdMemberHR_MAg'
		
DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.ConvertToXML(@SPName, Doing),
	ActionID = 409
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate <='2009-08-02'
	IF  @@ROWCOUNT < 1000
			BREAK
END

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.ConvertToXML(@SPName, REPLACE(Doing, 'v151mpt_32', ', v151mpt_32')),
	ActionID = 409
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate >= '2009-08-04'
	IF  @@ROWCOUNT < 1000
			BREAK
END
