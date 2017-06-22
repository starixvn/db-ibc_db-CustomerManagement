/*
	SCRIPT FOR DEPLOYMENT SP - NON XML 
	Phase 1: Convert data in Jan 2009 ,Dec 2009 and Jan 2010 
	Phase 2: Feb 2010 and March 2010
	Phase 3: All data 

	Note: SP_1, _xtest , _xpre
*/

--1. Acc_CreditTermUpdCustomer  1749 [12-2009] 1415[01-2010]
declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CreditTermUpdCustomer',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.999'

WHILE (1=1)
BEGIN	
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET		TrackingValue = dbo.GenerateXML(SpName, dbo.f_EncodeXmlValue( dbo.RegExReplace
			(dbo.RegExReplace(doing, '(\d{1,3})(,)(\d{1,3})', '$1.$3'), '(\d{1,3})(,)(\d{1,3})', '$1.$3')))
			,ActionId = 1001
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END
--2. Acc_CustomerUpdClearCredit

declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdClearCredit',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.999'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName,Doing),
		ActionId = 1201
	WHERE	SPName = @SPName
			AND ActionID IS NULL
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END

--3. Acc_CustomerUpdClosed
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdClosed',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, Replace(Doing, 'Update customer status for ', '')),
		ActionId = 1105
	WHERE	SPName = @SPName
			AND ActionID IS NULL
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END

--4. Acc_CustomerUpdDangercust
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdDangercust',
		@fromdate = '2010-06-01',
		@todate = '2010-06-30 23:59:59.999'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, Replace(Doing, 'Update dangerous status for ', '')),
		ActionId = 1114
	WHERE	SPName = @SPName
			AND ActionID IS NULL
			AND logdate between @fromdate and @todate
			
    IF  @@ROWCOUNT < 1000
        BREAK
END

--5. Acc_CustomerUpdDisableFI
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdDisableFI',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, Replace(Doing, 'Update customer Disabled Financial Status for ', '')),
		ActionId = 1108
	WHERE	SPName = @SPName
			AND ActionID IS NULL
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END

--6. Acc_CustomerUpdImportant

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdImportant',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, Replace(Doing, 'Update customer Special status for ', '')),
		ActionId = 1106
	WHERE	SPName = @SPName
			AND ActionID IS NULL
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END

--7. Acc_CustomerUpdInternal

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdInternal',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, Replace(Doing, 'Update customer Internal/Betting status for custid:', 'custid')),
		ActionId = 1112
	WHERE	SPName = @SPName
			AND ActionID IS NULL
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END

--8. Acc_CustomerUpdMatchLimit

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdMatchLimit',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(Doing, 'Update creditpermatch ', ''),' by user ', ', UserId=' )),
		ActionId = 800
	WHERE	SPName = @SPName
			AND ActionID IS NULL
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END

--9. Acc_CustomerUpdMember_CommissionHR

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdMember_CommissionHR',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.ConvertToXML(@SPName, REPLACE(Doing, 'v151discount_41', 'v151discount_41=')),
	ActionID = 212
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END

--10. Acc_CustomerUpdMember_Master
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdMember_Master',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.ConvertToXML(@SPName, REPLACE(REPLACE(REPLACE(Doing, '', ','),' O',''), ',,',',')),
	ActionID = 407
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate	
	IF  @@ROWCOUNT < 1000
			BREAK
END

--10.1 Just in case for Dot 
--UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
--SET TrackingValue = dbo.ConvertToXML('Acc_CustomerUpdMember_Master', REPLACE(Doing, '', ','))	
--WHERE	SPName = 'Acc_CustomerUpdMember_Master'
--	and Logid = 8161120
--	and logdate = '2009-01-10 07:08:24.923'
--	and custid = 10138


--11. Acc_CustomerUpdMemberFI_MAg

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdMemberFI_MAg',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'


WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.ConvertToXML(@SPName, REPLACE(Doing, 'v201mpt_3', ', v201mpt_3')),
	ActionID = 408
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END

--12. Acc_CustomerUpdMemberHR_MAg

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdMemberHR_MAg',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'


WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.ConvertToXML(@SPName, REPLACE(Doing, 'v151mpt_32', ', v151mpt_32')),
	ActionID = 409
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END

--13. Acc_CustomerUpdMoveAgent

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdMoveAgent',
		@fromdate = '2009-01-16 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DOING, 'Move agent ', 'AgentName='),' from master id ', ',OldMasterId='),' to master ', ',NewMasterName='),' (id ', ',NewMasterId='),') ,', ',')),
	ActionID = 606
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END
 

--14. Acc_CustomerUpdMoveMaster

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdMoveMaster',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DOING, 'Move master ', 'MasterName='),' from super id ', ',OldSuperId='),' to super ', ',NewSuperName='),' (id ', ',NewSuperId='),') ,', ',')),
	ActionID = 607
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
			
	IF  @@ROWCOUNT < 1000
			BREAK
END

--15. Acc_CustomerUpdMoveMember

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdMoveMember',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DOING, 'Move member ', 'MemberName='),' from agent id ', ',OldAgentId='),' to agent ', ',NewAgentName='),' (id ', ',NewAgentId='),') ,', ',')),
	ActionID = 615
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate	
	IF  @@ROWCOUNT < 1000
			BREAK
END

--16. Acc_CustomerUpdMoveSite
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdMoveSite',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, Doing),
		ActionId = 614
	WHERE	SPName = @SPName
			AND ActionID IS NULL
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END
--17. 

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdMoveSite',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'
WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, Doing),
		ActionId = 614
	WHERE	SPName = @SPName
			AND ActionID IS NULL
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END

--18. Acc_CustomerUpdPwdReset

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdPwdReset',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'
WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(DOING, 'Reset password CustID:', 'CustID='),'IP:', ', IP=')),
	ActionID = 900
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END

--19. Acc_CustomerUpdResetMemberCredit

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdResetMemberCredit',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, Doing),
	ActionID = 1202
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END

--20. Acc_CustomerUpdSuspended
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdSuspended',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(DOING, 'Update customer Suspended for ', '')),
	ActionID = 1104
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END

--21. Acc_CustomerUpdTransferOption
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdTransferOption',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(DOING, 'Update Transfer Option for ', '')),
	ActionID = 700
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END

--22. Acc_CustomerUpdUserGroup
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdUserGroup',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(REPLACE(DOING, 'Update group of', 'CustName='),'from', ', From='),'to', ', To='),', Userid', '", Userid"')),
	ActionID = 608
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK

END

--23. Acc_CustomerUpdUserInfo
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdUserInfo',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(REPLACE(dbo.f_EncodeXMLValue(Doing), 'Update customer info for ', ''), ', ', 'xxxxx'),',', '.'),'xxxxx', ', ')),
	ActionID = 604
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK	   
END

--24. Acc_CustomerUpdUserName

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdUserName',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(Doing, 'Update username from ', 'FromName='),'Update usename of ','FromName='),'to ', ', ToName=')),
	ActionID = 605
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END

--25. Acc_CustomerUpdVirtualMultiplier
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdVirtualMultiplier',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(DOING, 'Update Virtual Rate for ', ''),'Acc_CustomerUpdVirtualMultiplier','')),
	ActionID = 801
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END

--26.Acc_CustOverrideUpd

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustOverrideUpd',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN	
	
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.TrimEnd(dbo.Trim(REPLACE(Doing, '',', ')), ',')
	WHERE	SPName = @SPName 	
			AND logdate between @fromdate and @todate
			AND TrackingValue IS NULL 
	
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE (REPLACE(REPLACE(TrackingValue, 'Acc_CustOverrideUpd',''),'<info>',''),'</info>','')),
		ActionId = 500
	WHERE	SPName = @SPName
			AND ActionID is null
			AND TrackingValue IS NOT NULL 
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END

--27. Acc_CustOverrideUpdFI

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustOverrideUpdFI',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(Doing, '<info>',''),'</info>','')),
		ActionId = 501
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK

END

--28. Acc_CustOverrideUpdHR
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustOverrideUpdHR',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(Doing, '<info>',''),'</info>','')),
		ActionId = 502
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END
--29. Acc_LoginAdmin

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_LoginAdmin',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE (REPLACE(Doing, 'The A/C is closed due to 5 wrong password attempts, ',''),'The A/C is closed due to 6 wrong password attempts','IP=')),
		ActionId = 905
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END

--30. Acc_VirtualRateMulUpd
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_VirtualRateMulUpd',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPname, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DOING, 'Updated new virtual rate:', 'Rate='),' for username:', ', UserName='),', IP:', ', IP='),', File Name:', ', FileName='),'(Size:', ', FileSize='),').', '')),
	ActionID = 802
	WHERE	SPName = @SPname
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END

--31.Acc_VirtualRateMulUpd_Sum
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_VirtualRateMulUpd_Sum',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DOING, 'Updated new virtual rate for', 'TotalUser='),'users', ''),', IP:', ', IP='),', File Name:', ', FileName='),'(Size:', ', FileSize='),').', '')),
	ActionID = 803
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate	
	IF  @@ROWCOUNT < 1000
			BREAK

END
--32.Age_CustomerPwdUpd2
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Age_CustomerPwdUpd2',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(DOING, 'reset password userID:', 'UserID='),'IP:', ', IP=')),
		ActionId = 902
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END
--33. Age_CustomerUpdPwd
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Age_CustomerUpdPwd',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DOING, 'SubAccount:', 'SubAccount='),' - ',''), 'reset password userID:',', UserID='),' IP ', ', IP='),' IP:',', IP=')),
		ActionId = 901
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate	
	IF  @@ROWCOUNT < 1000
			BREAK
END
--34.Age_CustomerUpdUserInfo
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Age_CustomerUpdUserInfo',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(REPLACE(dbo.f_EncodeXMLValue(Doing), 'Update customer info for ', ''), ', ', 'xxxxx'),',', '.'),'xxxxx', ', ')),
	ActionID = 609
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate	
	IF  @@ROWCOUNT < 1000
			BREAK
END

--35. Age_CustSubIns
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Age_CustSubIns',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, Doing),
	ActionID = 612
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END
--36. Age_CustSubPwdUpd
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Age_CustSubPwdUpd',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE (REPLACE(Doing, 'Reset password for sub-account:', 'SubAccount='),' IP:', ',IP='),' IP ', ',IP=')),
		ActionId = 903
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate	
	IF  @@ROWCOUNT < 1000
			BREAK
END

--37. Age_CustSubPwdUpd2
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Age_CustSubPwdUpd2',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE (REPLACE(Doing, 'SubAccountID:', 'SubAccountID='),'SubAccount:', 'SubAccount='),' - reset password successful. IP: ', ', IP='),' - reset password successful. IP:', ', IP=')),
		ActionId = 904
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate

	IF  @@ROWCOUNT < 1000
			BREAK
END
--38.Age_CustSubUpdPageAccess
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Age_CustSubUpdPageAccess',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'
WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, Doing),
		ActionId = 611
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate	
	IF  @@ROWCOUNT < 1000
			BREAK
END

--39. Age_LoginDownline

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Age_LoginDownline',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE (REPLACE(Doing, 'The A/C is closed due to 5 wrong password attempts, ',''),'The A/C is closed due to 6 wrong password attempts','IP='),'The A/C is closed due to 5 wrong password attempts','IP=')),
		ActionId = 906
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate	
	IF  @@ROWCOUNT < 1000
			BREAK
END

--40. Age_LoginDownline_Sub
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Age_LoginDownline_Sub',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE (REPLACE(Doing, 'The sub-account is closed due to 5 wrong password attempts, ',''),'The sub-account is closed due to 6 wrong password attempts','IP='),'The sub-account is closed due to 5 wrong password attempts','IP=')),
		ActionId = 907
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END
--41. Age_LoginVerifyDownline

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Age_LoginVerifyDownline',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(REPLACE (REPLACE(Doing, 'The A/C is closed due to 5 wrong password attempts, ',''),'The sub-account is closed due to 5 wrong password attempts, ',''),'The A/C is closed due to 6 wrong password attempts','IP='),'The sub-account is closed due to 6 wrong password attempts','IP='),'The A/C is closed due to 5 wrong password attempts','IP=')),
		ActionId = 908
	WHERE	SPName = @SPName
			AND ActionID is null

	IF  @@ROWCOUNT < 1000
			BREAK
END
--42. DBA_ArchiveAccount1_UpdateMove
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'DBA_ArchiveAccount1_UpdateMove',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML('DBA_ArchiveAccount1_UpdateMove', REPLACE(doing,'DBA_ArchiveAccount1_UpdateMove' ,'') ),
		ActionId = 1500
	WHERE	SPName=@SPName
			AND ActionID IS NULL
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END

--43. DBA_ArchiveAccount2_UpdateMove

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'DBA_ArchiveAccount2_UpdateMove',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML('DBA_ArchiveAccount2_UpdateMove', REPLACE(doing,'DBA_ArchiveAccount2_UpdateMove' ,'')),
		ActionId = 1501
	WHERE	SPName=@SPName
			AND ActionID IS NULL
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END

--44.DBA_ArchiveAccount1_Rollback
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'DBA_ArchiveAccount1_Rollback',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML('DBA_ArchiveAccount1_Rollback', doing),
		ActionId = 1503
	WHERE	SPName='DBA_ArchiveAccount1_Rollback'
			AND ActionID IS NULL
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END
--45.DBA_ArchiveAccount2_Rollback
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'DBA_ArchiveAccount2_Rollback',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML('DBA_ArchiveAccount2_Rollback', doing),
		ActionId = 1504
	WHERE	SPName='DBA_ArchiveAccount2_Rollback'
			AND ActionID IS NULL
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END
--46. DBA_ChangeCurrency

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'DBA_ChangeCurrency',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(Doing, 'Update currency for Super ','CustID=,CustName='),' from old currency: ',',Old='),' to new currency: ',',New=')),
	ActionID = 804
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END

--47. DBA_ChangeCurrencyAndMoveAgent
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'DBA_ChangeCurrencyAndMoveAgent',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(Doing, 'Update currency for Agent ','CustID=,CustName='),' from old currency: ',',Old='),' to new currency: ',',New=')),
	ActionID = 805
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END


--48. DBA_CustomerUpdMoveMaster
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'DBA_CustomerUpdMoveMaster',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DOING, 'Move master ', 'MasterName='),' from super id ', ',OldSuperId='),' to super ', ',NewSuperName='),' (id ', ',NewSuperId='),') ,', ',')),
	ActionID = 613
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END

--49. Dot_Dep_CustomerInsMember_Ag

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Dot_Dep_CustomerInsMember_Ag',
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(Doing,'Dot_Dep_CustomerInsMember_Ag','')),
	ActionID = 617
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
			and doing is not null
	IF  @@ROWCOUNT < 1000
		BREAK
END

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
	SET TrackingValue = null,
		ActionID = 617
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
			and doing is null	
	IF  @@ROWCOUNT < 1000
		BREAK
END

-- 50.Acc_CustomerUpdAutoSuspend
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdAutoSuspend',
		@fromdate = '2010-06-01',
		@todate = '2010-07-01'
		
DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE spname = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, Replace(Doing, 'update customer autosuspend for ', '')),
		ActionId = 1110
	WHERE	SPName=@SPName
			AND ActionID IS NULL
			AND userid IN (SELECT userid FROM @User)
			AND logdate >= @fromdate and logdate < @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END
	

--=== CONVERT TO XML ===

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime, @ActionID int
select @SPName = 'Acc_CustomerUpdSuper_Commission', 
		@fromdate = '2010-06-01 00:00:00.000',
		@todate = '2010-06-30 23:59:59.000'

select @ActionID = ActionID from LogAction with (nolock)
where SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.ConvertToXML(@SPName, Doing),
	ActionID = @ActionID
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END

--50. 

--51.

--52. 



--Credit
declare @fromdate smalldatetime, @todate smalldatetime
select @fromdate = '2009-06-01 00:00:00.000',
		@todate = '2010-07-30 23:59:59.000'

WHILE (1=1)
BEGIN
	update TOP (1000) l
	set l.actionid = a.actionid
	from dbo.UserLog_Credit l with(rowlock,updlock)
	inner join 
	(
	Select	1207	as ActionID,	'Acc_CustomerInsMember_Ag'	As SPName Union ALL
	Select	1208	as ActionID,	'Acc_CustomerInsMember_Com'	As SPName Union ALL
	Select	1209	as ActionID,	'Acc_CustomerInsMember_MAg'	As SPName Union ALL
	Select	1210	as ActionID,	'Acc_CustomerInsMember_SAg'	As SPName Union ALL
	Select	1201	as ActionID,	'Acc_CustomerUpdClearCredit'	As SPName Union ALL
	Select	1200	as ActionID,	'Acc_CustomerUpdCredit'	As SPName Union ALL
	Select	1202	as ActionID,	'Acc_CustomerUpdResetMemberCredit'	As SPName Union ALL
	Select	1211	as ActionID,	'Age_CustomerUpdClearCredit'	As SPName Union ALL
	Select	1203	as ActionID,	'Age_CustomerUpdCredit_Ag'	As SPName Union ALL
	Select	1204	as ActionID,	'Age_CustomerUpdCredit_MAg'	As SPName Union ALL
	Select	1205	as ActionID,	'Age_CustomerUpdCredit_SAg'	As SPName Union ALL
	Select	1206	as ActionID,	'Age_CustomerUpdMaxCredit'	As SPName
	)a on a.spname = l.spname 
	where l.actionid is null
		and l.logdate between @fromdate and @todate
	
    IF  @@ROWCOUNT < 1000
        BREAK
END