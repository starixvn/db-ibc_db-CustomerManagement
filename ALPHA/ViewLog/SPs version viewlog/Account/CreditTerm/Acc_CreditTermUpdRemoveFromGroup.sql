/****** Object:  StoredProcedure [dbo].[Acc_CreditTermUpdRemoveFromGroup]    Script Date: 06/24/2008 19:07:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [dbo].[Acc_CreditTermUpdRemoveFromGroup]
	@CustIDList varchar(200),
	@groupID int,
	@UserID int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2)= 'E',
	@IP varchar(15) = ''
AS
--Original: ADMIN\account\creditterm_group_feed_add.asp
/*	Created by: [Creator]
	Revisions:
		- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]
		- 20090916@Shifu: Write log to DB06	
		- 20100112@Kiwi: amend to write log in xml format.			
*/
SET NOCOUNT ON

--Check permission for account site: @phuc20080213
EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

--Check an account disabled or not
declare @username nvarchar(100)
select top 1 @username = username  
from custinfo with (nolock)
where custID in (select val from dbo.strSplit(@CustIDList, ',')) and enabled = 0

if (@username is not null)
begin 
	set @ErrMsg = @username + ' is disabled'
	set @ErrCode=600
	Return
end
--end


update custAccount WITH (ROWLOCK, UPDLOCK) 
set groupid = 0 
where custid in (select val from dbo.strSplit(@CustIDList, ','))
	and isgroupheadline <> 1


declare @LogData nvarchar(1000)
Select @LogData = 'GroupID="' + convert(varchar(20), @groupID) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(10)),space(1)) + '" ' +
'ErrMsg="'+ @ErrMsg  + '" />'

--Write log

INSERT INTO DBLOG.bodb_CustomerLog.dbo.UserLog_RunSP (UserID, CustID, ActionID, TrackingValue)	
SELECT	@UserID, 
		CustID,
		1002,
		'<Acc_CreditTermUpdRemoveFromGroup CustID="'+ CustID + '" ' + @LogData
FROM (SELECT val CustID FROM dbo.strSplit(@CustIDList, ',')) tbCust

GO
GRANT EXECUTE ON [dbo].[Acc_CreditTermUpdRemoveFromGroup] TO [bodbAdminNet]	
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CreditTermUpdRemoveFromGroup] TO [vnteam]

