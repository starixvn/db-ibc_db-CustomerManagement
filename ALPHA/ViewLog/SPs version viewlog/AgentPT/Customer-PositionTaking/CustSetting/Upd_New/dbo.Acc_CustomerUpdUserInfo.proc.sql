ALTER PROCEDURE [dbo].[Acc_CustomerUpdUserInfo]
	@CustID int,	
	@firstname nvarchar(50) = NULL,
	@lastname nvarchar(50) = NULL,
	@address nvarchar(80) = NULL,
	@postal nvarchar(50) = NULL,
	@city nvarchar(50) = NULL,
	@state nvarchar(50) = NULL,
	@country nvarchar(50) = NULL,
	@phone nvarchar(50) = NULL,
	@mobilephone nvarchar(50) = NULL,
	@fax nvarchar(50) = NULL,
	@email nvarchar(50) = NULL,
	@birthday smalldatetime = NULL,
	@refcode1 nvarchar(50) = NULL,
	@refcode2 nvarchar(50) = NULL,
	@remark nvarchar(50) = NULL,
	@important bit = NULL,
	@gender bit = NULL,
	@disCasino bit = 0,	
	
	@SubAccID int = 0, --Sub-AccountID
	@UserID int,
	@Language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@IP varchar(15)=''

AS
/*
Created: 20090122@Phuc
Task : Update customer's info
DB: DB02.bodb02
Original:
Revisions:
	- 20090723@Phuc: Write log subaccname instead of subaccid.
	- 20090801@Shifu: check disabled user	
	- 20090917@Phuc: write log into DBLOG.
	- 20091008@Kiwi: Remove WriteLog_UserLog
	- 20091125@Terry: Add one more para @disCasino to check disabled Casino
	- 20100107@Lewin: change sp format, call new writelog sp 
	- 20100414@Kiwi: Remove to do not update gender field.
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/
SET NOCOUNT ON

--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @CustID, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <> 0 return
--end
IF exists(select 1 from custinfo with (nolock) where synccasino = 1 and custid = @CustID)
BEGIN
	IF @disCasino = 1
		BEGIN	
			Select @ErrMsg = case @Language 
								when 'E' then 'This USER INFO function is temporarily unavailable, please update later.'
								when 'CS' then N'This USER INFO function is temporarily unavailable, please update later.'
								when 'CT' then N'This USER INFO function is temporarily unavailable, please update later.'
								when 'TH' then N'This USER INFO function is temporarily unavailable, please update later.'
								when 'J' then N'This USER INFO function is temporarily unavailable, please update later.'
								when 'KO' then N'This USER INFO function is temporarily unavailable, please update later.'
								else N'This USER INFO function is temporarily unavailable, please update later.'
							end	,
				@ErrCode = 100
				return
		END
END		



Update customer with (ROWLOCK) set	
	firstname = case when @firstname is null then firstname else @firstname end,
	lastname = case when @lastname is null then lastname else @lastname end,
	address = case when @address is null then address else @address end,
	postal = case when @postal is null then postal else @postal end,
	city = case when @city is null then city else @city end,
	state = case when @state is null then state else @state end,
	country = case when @country is null then country else @country end,
	phone = case when @phone is null then phone else @phone end,
	mobilephone = case when @mobilephone is null then mobilephone else @mobilephone end,
	fax = case when @fax is null then fax else @fax end,
	email = case when @email is null then email else @email end,
	birthday = case when @birthday is null then birthday else @birthday end,
	refcode1 = case when @refcode1 is null then refcode1 else @refcode1 end,
	refcode2 = case when @refcode2 is null then refcode2 else @refcode2 end,
	remark = case when @remark is null then remark else @remark end,
	important = case when @important is null then important else @important end
where custID = @CustID

declare @LogSPData varchar(max)

Select @LogSPData = '<Acc_CustomerUpdUserInfo CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1))+ '" ' + 
					'fname="'+ dbo.f_EncodeXMLValue(coalesce(cast(@firstname as varchar(100)),space(1)))+ '" ' +
					'lname="'+ dbo.f_EncodeXMLValue(coalesce(cast(@lastname as varchar(100)),space(1)))+ '" ' +
					'address="'+ dbo.f_EncodeXMLValue(coalesce(cast(@address as varchar(160)),space(1)))+ '" ' +
					'postal="'+ dbo.f_EncodeXMLValue(coalesce(cast(@postal as varchar(100)),space(1)))+ '" ' +
					'city="'+ dbo.f_EncodeXMLValue(coalesce(cast(@city as varchar(100)),space(1)))+ '" ' +
					'state="'+ dbo.f_EncodeXMLValue(coalesce(cast(@state as varchar(100)),space(1)))+ '" ' +
					'country="'+ coalesce(cast(@country as varchar(100)),space(1))+ '" ' +
					'phone="'+ dbo.f_EncodeXMLValue(coalesce(cast(@phone as varchar(100)),space(1)))+ '" ' +
					'mphone="'+ dbo.f_EncodeXMLValue(coalesce(cast(@mobilephone as varchar(100)),space(1)))+ '" ' +
					'fax="'+ dbo.f_EncodeXMLValue(coalesce(cast(@fax as varchar(100)),space(1)))+ '" ' +
					'email="'+ dbo.f_EncodeXMLValue(coalesce(cast(@email as varchar(100)),space(1)))+ '" ' +
					'birthday="'+ coalesce(cast(@birthday as varchar(50)),space(1))+ '" ' +
					'refcode1="'+ dbo.f_EncodeXMLValue(coalesce(cast(@refcode1 as varchar(100)),space(1)))+ '" ' +
					'refcode2="'+ dbo.f_EncodeXMLValue(coalesce(cast(@refcode2 as varchar(100)),space(1)))+ '" ' +
					'remark="'+ dbo.f_EncodeXMLValue(coalesce(cast(@remark as varchar(100)),space(1)))+ '" ' +
					'important="'+ coalesce(cast(@important as varchar(50)),space(1))+ '" ' +
					'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1))+ '" ' +
					'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1))+ '" ' +
					'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+ '" ' +
					'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1))+ '" ' +
					'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+ '" ' +
					'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'

/*604 Acc_CustomerUpdUserInfo Update customer info */
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 604,
	@TrackingValue = @LogSPData
	
GO
GRANT  EXECUTE  ON [dbo].[Acc_CustomerUpdUserInfo]  TO [bodbAdminNet]
GO
GRANT  EXECUTE  ON [dbo].[Acc_CustomerUpdUserInfo]  TO [bodbDownlineNet]
GO
GRANT  EXECUTE  ON [dbo].[Acc_CustomerUpdUserInfo]  TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdUserInfo] TO [bodbExtAccNet]
GO

