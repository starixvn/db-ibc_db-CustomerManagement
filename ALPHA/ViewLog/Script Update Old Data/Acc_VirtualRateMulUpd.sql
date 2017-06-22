/*
	DOING VALUE: Updated new virtual rate:1.00 for username:TESTCS01A5000, IP:202.78.228.8, File Name:sample_testLIVE.xls(Size:323290).  
	
	ACTION: 802 Acc_VirtualRateMulUpd Update new multi virtual rates 
	
	XML FORMAT: <Acc_VirtualRateMulUpd Rate="1.00"  UserName="TESTCS01A5000" IP="202.78.228.8"  FileName="sample_testLIVE.xls" FileSize="323290" />

*/

/*
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue =  REPLACE(DOING, 'Updated new virtual rate:', 'Rate=')
, dbo.UserLog_RunSP.ActionID = 801
WHERE dbo.UserLog_RunSP.SPName = 'Acc_VirtualRateMulUpd'

GO

UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue =  REPLACE(TrackingValue, ' for username:', 'UserName=')
WHERE  dbo.UserLog_RunSP.ActionID = 801

GO
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue =  REPLACE(TrackingValue, ', IP:', ', IP=')
WHERE  dbo.UserLog_RunSP.ActionID = 801

GO
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue =  REPLACE(TrackingValue, ', File Name:', ', FileName=')
WHERE  dbo.UserLog_RunSP.ActionID = 801
GO
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue =  REPLACE(TrackingValue, '(Size:', ', FileSize=')
WHERE  dbo.UserLog_RunSP.ActionID = 801
GO
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue =  REPLACE(TrackingValue, ').', '')
WHERE  dbo.UserLog_RunSP.ActionID = 801

UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue =  dbo.GenerateXML('Acc_VirtualRateMulUpd', TrackingValue)
WHERE  dbo.UserLog_RunSP.ActionID = 801
*/
--20100109@Kiwi
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_VirtualRateMulUpd',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'
		
DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPname

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPname, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DOING, 'Updated new virtual rate:', 'Rate='),' for username:', ', UserName='),', IP:', ', IP='),', File Name:', ', FileName='),'(Size:', ', FileSize='),').', '')),
	ActionID = 802
	WHERE	SPName = @SPname
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END