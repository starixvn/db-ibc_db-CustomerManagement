/* 
	DOING VALUE: Custid= 9636, GroupID=136, CreditGrade=A, PreAgreeAmount=500000.00, InstallmentAmount=0.00, InstallmentDate=1, AccountRemark=EURO -745,215.81, IsGroupHeadline=0, Checker=0, IP=115.135.34.105, ErrCode=0, ErrMsg=msg 7 : Done : Group changed 
	action id = 1001
*/
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CreditTermUpdCustomer',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

DECLARE @temp Table
	(
		LogId int,
		TrackingValue nvarchar(max)
	)

	INSERT @temp(logid, trackingvalue)
		SELECT logid, dbo.GenerateXML(SpName, dbo.EncodeXmlValue( dbo.RegExReplace
			(dbo.RegExReplace(doing, '(\d{1,3})(,)(\d{1,3})', '$1.$3'), '(\d{1,3})(,)(\d{1,3})', '$1.$3')))		
		FROM dbo.UserLog_RunSP with (nolock)
		WHERE actionid=1001 and doing is not null
		
select * from @temp
		
WHILE (1=1)
BEGIN	
	
	
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = (SELECT TOP 1 trackingvalue FROM @temp A WHERE A.logid = dbo.UserLog_RunSP.logid),
		ActionId = 1001
	WHERE	SPName = @SPName
			--AND ActionID is null
			--AND userid IN (SELECT userid FROM @User)	
			--AND logdate between @fromdate and @todate
			
	IF  @@ROWCOUNT < 1000
			BREAK
END