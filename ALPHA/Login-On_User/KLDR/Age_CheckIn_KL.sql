/*<info serverAlias="DBONUSER-ON_USER" executers="wsv_nap,wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
 ALTER PROCEDURE [dbo].[Age_CheckIn_KL]
	@CustID int,
	@NetSessionID varchar(30),
	@ServerID int,
	@On_UserID int OUTPUT,
	@IP nvarchar(15) = '',
	@SubAccID int = 0
AS

/*
	Created: 20110912@Sophia
	Task: Checkin at Agent site
	DB: DB03.ON_USER
	Original SP: Acc_CheckIn
	
	Revisions:	
		-2011107@Jamie: Add LoginTime 
		-20231218@Johnson: setup KL DR [redmine: #195700]
	Param's Explanation: 
	@Thien: to allow internal admin login without interfere with real agent
			--	pass @SubAccID = - CustID of Admin 
	
	Note : @SubSystem to indicate which of admin site connected from
	1 : ASP admin
	2 : VN.NET RBS
	3 : VN.NET Account Site
	4 : TW.NET Admin
	5 : TW.NET Admin call to ASP Admin
	6 : Affiliate Admin Site


*/
SET NOCOUNT ON

--if @@servername <> '5WRHH1S' 
--	update On_User_Agent with (ROWLOCK) set IsKickedout=1, ServerID=0 where CustID = @CustID and SubAccID = @SubAccID

 
	
--insert into On_User_Agent
--	(custid, NetSessionID, on_sessionid, ServerID, IsKickedout, IP, SubAccID,LoginTime)
--values
--	(@custid, @NetSessionid,0, @ServerID, 0, @IP, @SubAccID,GETDATE())

Select @On_UserID = 0;

GO