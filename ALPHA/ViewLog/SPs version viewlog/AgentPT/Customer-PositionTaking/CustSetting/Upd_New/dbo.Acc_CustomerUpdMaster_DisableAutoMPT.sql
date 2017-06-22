ALTER PROCEDURE [dbo].Acc_CustomerUpdMaster_DisableAutoMPT
	@CustID int,-- MasterID
	@DisableAutoMPT bit = 0,
	@SubAccID int = 0, --Sub-AccountID
	@UserID int = 0,	
	@Language varchar(2) = 'E',
	@IP varchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20090701@Phuc
Task : Update Disable auto master PT
DB: DB02.bodb02

Revisions:
	- 20090723@Phuc: Write log subaccname instead of subaccid.
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20090917@Phuc: write log into DBLOG.
	- 20091203@Kiwi: Modify to retrieve data from CustSetting3rd.
	- 20100112@Kiwi: Amend to write log in xml format.

Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/
SET NOCOUNT ON
--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
--end
Declare @UplineClosed bit, @RoleID int, @srecommend int
 
Select @RoleID = roleid, @srecommend = srecommend From custinfo (nolock) Where custid = @CustID
if(@RoleID is null or @roleid <> 3) 
begin
	select @ErrCode = 101,
			@ErrMsg=
					CASE @Language 
						WHEN 'E' THEN 'Account does not exist or invalid customer account'
						WHEN 'CS' THEN N'此账号无效或不存在'
						WHEN 'CT' THEN N'此賬號無效或不存在'
						WHEN 'TH' THEN N'Account does not exist or invalid customer account'
						WHEN 'J' THEN N'Account does not exist or invalid customer account'
						WHEN 'KO' THEN N'Account does not exist or invalid customer account'
						ELSE N'Account does not exist or invalid customer account'
					END	
	return
end

Update CustMaster WITH(ROWLOCK,UPDLOCK) Set DisableAutoMPT = @DisableAutoMPT WHERE CustID = @CustID

IF @DisableAutoMPT = 1
BEGIN
	--Reset m2 of all agent under this master
	--m2=min(um2,m3-a2)
	UPDATE acs 
		SET mpositiontaking = case when acs.autompositiontaking > mcs.mpositiontaking - acs.apositiontaking then mcs.mpositiontaking - acs.apositiontaking else acs.autompositiontaking end  	
	FROM custsetting acs WITH(ROWLOCK,UPDLOCK) 
		INNER JOIN custinfo ci (nolock) on ci.custid = acs.custid
		INNER JOIN custsetting mcs (NOLOCK) on acs.sporttype = mcs.sporttype and acs.bettype = mcs.bettype and mcs.custid = @CustID
	WHERE ci.mrecommend = @CustID AND ci.roleid = 2 AND (acs.isautompositiontaking = 1)
	
	UPDATE acs 
		SET mpositiontaking = case when acs.autompositiontaking > mcs.mpositiontaking - acs.apositiontaking then mcs.mpositiontaking - acs.apositiontaking else acs.autompositiontaking end  	
	FROM CustSetting3rd acs WITH(ROWLOCK,UPDLOCK) 
		INNER JOIN custinfo ci (nolock) on ci.custid = acs.custid
		INNER JOIN CustSetting3rd mcs (NOLOCK) on acs.sporttype = mcs.sporttype and acs.bettype = mcs.bettype and mcs.custid = @CustID
	WHERE ci.mrecommend = @CustID AND ci.roleid = 2 AND (acs.isautompositiontaking = 1)

	UPDATE acs 
		SET mlivepositiontaking = case when acs.autolivempositiontaking > mcs.mlivepositiontaking - acs.alivepositiontaking then mcs.mlivepositiontaking - acs.alivepositiontaking else acs.autolivempositiontaking end  	
	FROM custsetting acs WITH(ROWLOCK,UPDLOCK) INNER JOIN custinfo ci (nolock) on ci.custid = acs.custid
		INNER JOIN custsetting mcs (NOLOCK) on acs.sporttype = mcs.sporttype and acs.bettype = mcs.bettype and mcs.custid = @CustID
	WHERE ci.mrecommend = @CustID AND ci.roleid = 2 AND (acs.isautolivempositiontaking = 1)

	--Reset auto master PT of all agent under this master 
	UPDATE cs
		SET isautompositiontaking = 0,
			autompositiontaking = 0
	FROM custsetting cs WITH(ROWLOCK,UPDLOCK) INNER JOIN custinfo ci (nolock) ON ci.custid = cs.custid 
	WHERE ci.mrecommend = @CustID AND ci.roleid in (1,2) AND (cs.isautompositiontaking = 1)
	
	UPDATE cs
		SET isautompositiontaking = 0,
			autompositiontaking = 0
	FROM CustSetting3rd cs WITH(ROWLOCK,UPDLOCK) INNER JOIN custinfo ci (nolock) ON ci.custid = cs.custid 
	WHERE ci.mrecommend = @CustID AND ci.roleid in (1,2) AND (cs.isautompositiontaking = 1)
	 
	 UPDATE cs
		SET isautolivempositiontaking = 0,
			autolivempositiontaking = 0
	FROM custsetting cs WITH(ROWLOCK,UPDLOCK) INNER JOIN custinfo ci (nolock) ON ci.custid = cs.custid 
	WHERE ci.mrecommend = @CustID AND ci.roleid in (1,2) AND (cs.isautolivempositiontaking = 1)
END

declare @LogSPData varchar(5000)

Select @LogSPData = '<Acc_CustomerUpdMaster_DisableAutoMPT CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '" ' +
'DisableaMPT="'+ coalesce(cast(@DisableAutoMPT as varchar(50)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(8000)),space(1)) + '" />'
 
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 1113,
	@TrackingValue = @LogSPData

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMaster_DisableAutoMPT] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMaster_DisableAutoMPT] TO [bodbDownlineNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMaster_DisableAutoMPT] TO [vnteam]

