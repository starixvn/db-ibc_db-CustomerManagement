--408	Acc_CustomerUpdMemberFI_MAg	Update Master's Finance Position Taking at member

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdMemberFI_MAg'
		
DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.ConvertToXML(@SPName, Doing),
	ActionID = 408
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate <='2009-08-06'
	IF  @@ROWCOUNT < 1000
			BREAK
END

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.ConvertToXML(@SPName, REPLACE(Doing, 'v201mpt_3', ', v201mpt_3')),
	ActionID = 408
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate >= '2009-08-06'
	IF  @@ROWCOUNT < 1000
			BREAK
END