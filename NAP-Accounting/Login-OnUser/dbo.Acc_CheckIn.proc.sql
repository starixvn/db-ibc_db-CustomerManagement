ALTER PROCEDURE [dbo].[Acc_CheckIn]  
 @CustID int,  
 @NetSessionID varchar(30),  
 @ServerID int,  
 @On_UserID int OUTPUT,  
 @IP nvarchar(15) = '',  
 @SubAccID int = 0  
AS  
  
/*  
 Task: CheckIN  
 DB: DB03.ON_USER  
 Original SP:LoginDownline_OnUser  
   
 Revisions:  
  - 20100812@Jamie:Grant permision for Thai site   
  - 20100912@Sophia: Change table On_User_Admin instead of On_user  
  - 20120816@Steven: additional @ServerId at where condition when update iskickout
   
 Param's Explanation:   
 @Thien: to allow internal admin login without interfere with real agent  
   -- pass @SubAccID = - CustID of Admin  
   
 Note : @SubSystem to indicate which of admin site connected from  
 1 : ASP admin  
 2 : VN.NET RBS  
 3 : VN.NET Account Site  
 4 : TW.NET Admin  
 5 : TW.NET Admin call to ASP Admin  
 6 : Affiliate Admin Site  
  
  
*/  
  
--Use kick-out method, so comment the below lines  
/*  
declare @ErrMsg varchar(100)  
if exists (select 1 from on_user with (nolock) where custid = @custid and subaccid=@subaccid and serverid<>0 group by custid having count(1)>=1 )  
BEGIN  
 Select @ErrMsg = 'Sorry, system does not allow multiple login.'  
 RaisError (@ErrMsg, 16, 1)  
 return  
END  
*/  
--EXEC dbo.On_UserIns @CustID = @CustID, @On_SessionID = @SessionID, @ServerID = @ServerID, @On_UserID = @On_UserID OUTPUT, @IP = @IP, @subaccid = @subaccid  



--if @@servername <> 'DB215'--Vinh: not kickout at local server for testing  
 update On_User_Admin with (ROWLOCK) set IsKickedout=1, ServerID=0 where CustID = @CustID and SubAccID = @SubAccID  AND ServerID = @ServerID
  
--if @SubAccID < 0 --One admin can just log in one Agent/master/Super only  
-- update on_user with (ROWLOCK) set IsKickedout=1, ServerID=0 where SubAccID = @SubAccID  
   
insert into On_User_Admin  
 (custid, NetSessionID, on_sessionid, ServerID, IsKickedout, IP, SubAccID)  
values  
 (@custid, @NetSessionid,0, @ServerID, 0, @IP, @SubAccID)  
  
Select @On_UserID = SCOPE_IDENTITY()  
  


GO
GRANT EXECUTE ON [dbo].[Acc_CheckIn] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CheckIn] TO [bodbExtAccNet]
GO