ALTER PROCEDURE [dbo].[Acc_CustomerUpdDisableCasinoBonus]
	@CustID					INT,	
	@Disable				BIT,
	@DisableDownlines		BIT = true, --Disable all downline
	@SubAccID				INT = 0, --Sub-AccountID
	@UserID					INT,
	@Language				VARCHAR(2) = 'E',
	@ErrCode				INT = 0 OUTPUT,
	@ErrMsg					NVARCHAR(200) = '' OUTPUT,
	@IP						VARCHAR(15)=''
AS
/*
Created: 20130719@Elodie
Task : Update DisableCasinoBonus status for customer
DB: DBTXN/bodb02
Original: 
	
Revisions:
	- 20150606@Elodie: Separate CustDB to DBCUST server (Move Acc_CustomerSelCheckAllowedDownlines, Acc_CustomerSelCheckEnable to DBCUST.CustDB)
	   
Param's Explanation:
• @custid: customer id.   
• @Disable: status
*/
SET NOCOUNT ON

declare @startRun datetime
declare @endRun datetime
declare @duration int
set @startRun = getdate()

--Check disable user
EXEC Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
--end
Declare @RoleID tinyint , @UplineDisable bit, @Old_Disable bit

select	@RoleID = RoleID,
		@Old_Disable = isnull(DisableCasinoBonus, 0)
from Custinfo with (nolock)
where CustID = @CustID

if @RoleID not in (1,2,3,4)
BEGIN
	Select @ErrMsg = case @Language 
						when 'E' then 'Invalid user!'
						ELSE [dbo].[f_Get_MsgNamebyMsgID](40002,@Language)
					end, @ErrCode = 100	
	return
END

if @Old_Disable = @Disable 
	RETURN

if @Disable = 0 -- check status upline
begin			
	if @RoleID = 3
		SELECT @UplineDisable = isnull(DisableCasinoBonus,0) FROM CustInfo with (nolock)
		WHERE custid = (SELECT SRecommend FROM Custinfo with (nolock) WHERE custid = @CustID)
	if @RoleID = 2
		SELECT @UplineDisable = isnull(DisableCasinoBonus,0) FROM CustInfo with (nolock)
		WHERE custid = (SELECT MRecommend FROM Custinfo with (nolock) WHERE custid = @CustID)
	if @RoleID = 1
		SELECT @UplineDisable = isnull(DisableCasinoBonus,0) FROM CustInfo with (nolock)
		WHERE custid = (SELECT Recommend FROM Custinfo with (nolock) WHERE custid = @CustID)
	IF @RoleID = 4 SELECT @UplineDisable = 0   --not checking the upline when the customer is the super
		
	IF @UplineDisable = 1
	BEGIN
		SELECT @ErrMsg =  CASE @Language 
							WHEN 'E' THEN 'Account disabled for Casino Bonus. Unable to edit downlines.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](60015,@Language)
						END, @ErrCode = 105
		return
	END 
end

--Check Allowed downlines during peak hour at weekend
IF (@Disable = 1 or (@Disable = 0 and @DisableDownlines = 0))
BEGIN
	EXEC Acc_CustomerSelCheckAllowedDownlines	@custid=@custid,
											@roleid=@roleid,
											@isExecRep=0,
											@Language=@Language,
											@ErrMsg=@ErrMsg output,
											@ErrCode=@ErrCode output
		IF @ErrCode <>0 RETURN
		
END
---------------------

update CustInfo with (ROWLOCK, UPDLOCK) set DisableCasinoBonus = @Disable
where CustID = @CustID
if (@@error <> 0)
begin

	Select @ErrMsg =
					case @Language 
						when 'E' then 'Update process is unsuccessful.'
						ELSE [dbo].[f_Get_MsgNamebyMsgID](90001,@Language)
					end	, @ErrCode = 101
	return
end
--Check condition for update all downline
if (@Disable = 1 or (@Disable = 0 and @DisableDownlines = 0)) --Disable all downline or enable all downline
begin
	if @RoleID = 4 
	BEGIN
		update CustInfo with (ROWLOCK, UPDLOCK) 
		set DisableCasinoBonus = @Disable 
		where SRecommend = @CustID
		if (@@error <> 0)
		begin
			
			Select @ErrMsg = 
						case @Language 
							when 'E' then 'Update process is unsuccessful.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](90001,@Language)
						end	, @ErrCode = 102
		return
		end
	END

	if @RoleID = 3 
	BEGIN
		update CustInfo with (ROWLOCK, UPDLOCK) 
		set DisableCasinoBonus = @Disable 
		where MRecommend = @CustID
		if (@@error <> 0)
		begin
			
			Select @ErrMsg = 
						case @Language 
							when 'E' then 'Update process is unsuccessful.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](90001,@Language)
						end	, @ErrCode = 103
		return
		end
	END

	if @RoleID = 2 
	BEGIN
		update CustInfo with (ROWLOCK, UPDLOCK) 
		set DisableCasinoBonus = @Disable 
		where Recommend = @CustID
		if (@@error <> 0)
		begin
			
			Select @ErrMsg = 
						case @Language 
							when 'E' then 'Update process is unsuccessful.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](90001,@Language)
						end	, @ErrCode = 104
		return
		end
	END
End

declare @LogSPData varchar(2000)

Select @LogSPData = '<Acc_CustomerUpdDisableCasinoBonus CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '" '+
					'Disable="'+ coalesce(cast(@Disable as varchar(50)),space(1)) + '" '+
					'DisableDownlines="'+ coalesce(cast(@DisableDownlines as varchar(50)),space(1)) + '" '+
					'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" '+
					'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
					'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" '+
					'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
					'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" '+
					'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 1145,
		@TrackingValue = @LogSPData	 ,
		@duration = @duration
END TRY
BEGIN CATCH
	Select @LogSPData = '<Acc_CustomerUpdDisableCasinoBonus CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '" '+
					'Disable="'+ coalesce(cast(@Disable as varchar(50)),space(1)) + '" '+
					'DisableDownlines="'+ coalesce(cast(@DisableDownlines as varchar(50)),space(1)) + '" '+
					'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" '+
					'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
					'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" '+
					'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
					'ErrMsg="'+ ERROR_MESSAGE() + '" ' +
					'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
	
	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 1145,
		@TrackingValue = @LogSPData	 ,
		@duration = @duration
END CATCH


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdDisableCasinoBonus] TO [bodbAdminNet]
GO
GRANT  EXECUTE  ON [dbo].[Acc_CustomerUpdDisableCasinoBonus]  TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdDisableCasinoBonus] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdDisableCasinoBonus] TO [bodbExtAccNet] 