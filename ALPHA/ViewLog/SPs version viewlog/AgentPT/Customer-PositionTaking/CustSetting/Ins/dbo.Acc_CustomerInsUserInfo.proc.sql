ALTER PROCEDURE [dbo].[Acc_CustomerInsUserInfo]
	@custid int OUTPUT,
	@firstname nvarchar(50),
	@lastname nvarchar(50),
	@Gender bit = null,
	@creator int,
	@username varchar(30),
	@userpwd varchar(40),
	@pwdexpiry datetime,
	@currency int,
	@site nvarchar(50),
	@ugroup varchar(5) = NULL,

	@srecommend int,
	@mrecommend int,
	@recommend int,
	@roleid int,
	
	@phone nvarchar(50),
	@mobilephone nvarchar(50),
	@email nvarchar(50),
	@fax nvarchar(50),
	@address nvarchar(80),
	@city nvarchar(50),
	@state nvarchar(50),
	@country nvarchar(50),
	@postal nvarchar(50),
	@TransferOption varchar(8) = NULL, --pass value (not NULL) in case direct master add new agent
	@suspended bit = null,
	@closed bit = null,
	@DisableHorseRacing bit = 0,
	@DisableOutright bit = 0,
	@matchlimit smallmoney,
	@virtualmultiplier smallmoney,
	@DisableFinancial bit = 0,
	@DisableAutoMPT bit = 1,
	@IsInternal bit = 0,
	
	@MaxPerMatch money,
	@MaxPerMatchv2 money,
	@MaxPerMatchv3 money,
	@MaxPerMatchv5 money,
	@MaxPerMatchv8 money,
	@MaxPerMatchv10 money,
	@MaxPerMatchv11 money,
	--v201
	@MaxPerMatchv201 money = 0,
	--v151
	@MaxPerMatchv151 money = 0,
	@MaxPerMatchv99 money,
	@credit money,
	@maxcredit money = 0,
	
	@answer nvarchar(100)='',
	@IP varchar(15)='',
	@TransferOption_dec tinyint,

	@Language varchar(2)= 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS

/*
Created: 20090121@Phuc
Task :	Insert general customer's Informatioin.
		Table related: customer, custinfo
DB: DB02.bodb02
Original:

Revisions:
	- 20090521@PhuongDao: Not to insert maxcredit on custinfo table 
	- 20090703@Phuc: manual rollback
	- 20090901@Shifu: add IsInternal
	- 20091112@Jamie: Add the input param @DisableOutright 
	
Param's Explanation:
• @ErrCode:
    = 0: Insert successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

insert into customer   			
			(username, 
			firstname, 
			lastname, 
			Gender,
			phone, 
			mobilephone, 
			fax, 
			email,
			address, 
			city, 
			state, 
			country, 
			postal, 
			userpwd,
			roleid, 
			srecommend,
			mrecommend,
			recommend, 
			currency, 
			pwdexpiry, 
			creator, 
			site,
			creatdate,
			ugroup,
			answer,
			transferoption
			) 
 		 values (@username, 
			@firstname, 
			@lastname, 
			@Gender,
			@phone, 
			@mobilephone, 
			@fax, 
			@email,
			@address, 
			@city, 
			@state, 
			@country, 
			@postal, 
			@userpwd,
			@roleid, 
			@srecommend,
			@mrecommend,
			@recommend, 
			@currency, 
			@pwdexpiry, 
			@creator, 
			@site,
			getdate(),
			@ugroup,
			@answer,
			--dbo.F_Binary_Decimal(ISNULL(@TransferOption, 0))
			case when @TransferOption IS NULL then ISNULL(@TransferOption_dec, 0) else dbo.F_Binary_Decimal(ISNULL(@TransferOption, 0)) end
			)

SELECT @custid=@@IDENTITY

if @@error <> 0
BEGIN
	SELECT @ErrMsg = case @Language 
							when 'E' then 'Create customer failed. Please try again.'
							when 'CS' then N'新增会员不成功，请重新尝试.'
							when 'CT' then N'新增會員不成功,請重新再試.'
							when 'TH' then N'การเพิ่มจำนวนลูกค้าใหม่ ไม่สำเร็จ กรุณาทำรายการอีกครั้ง.'
							when 'J' then N'Create customer failed. Please try again.'
							when 'KO' then N'고객 생성에 실패했습니다. 다시 시도해 주시기 바랍니다.'
							else N'Create customer failed. Please try again.'
						end,
		@ErrCode = 111
		
	-- ROLLBACK MANUALLY
	Delete From customer With (ROWLOCK) Where CustID = @CustID
		
	return
END

if @roleid = 4
begin
	set @srecommend = @custid 
	Update Customer with (ROWLOCK, UPDLOCK) set srecommend = @custid where CustID = @CustID
	Insert into CustSuper(CustID, AutoIBCPositiontaking_Tote, AutoIBCPositiontaking_Fixed, IsInternal) Values(@CustID,0,0, @IsInternal)
end
else if @roleid = 3
begin
	set @mrecommend = @custid 
	Update Customer with (ROWLOCK, UPDLOCK) set mrecommend = @custid where CustID = @CustID
	Insert into CustMaster(CustID, DisableAutoMPT, IsInternal)Values(@CustID,@DisableAutoMPT, @IsInternal)
end
else if @roleid = 2
begin
	set @recommend = @custid
	Update Customer with (ROWLOCK, UPDLOCK) set recommend = @custid where CustID = @CustID
	Insert into CustAgent(CustID, MaxCredit, IsInternal)Values(@CustID, @MaxCredit, @IsInternal)
end
if @@error <> 0
BEGIN

	SELECT @ErrMsg = case @Language 
							when 'E' then 'Create customer failed. Please try again.'
							when 'CS' then N'新增会员不成功，请重新尝试.'
							when 'CT' then N'新增會員不成功,請重新再試.'
							when 'TH' then N'การเพิ่มจำนวนลูกค้าใหม่ ไม่สำเร็จ กรุณาทำรายการอีกครั้ง.'
							when 'J' then N'Create customer failed. Please try again.'
							when 'KO' then N'고객 생성에 실패했습니다. 다시 시도해 주시기 바랍니다.'
							else N'Create customer failed. Please try again.'
						end,
		@ErrCode = 112
		
	-- ROLLBACK MANUALLY
	IF @RoleID = 4
		DELETE FROM CustSuper With(ROWLOCK) WHERE CustID = @CustID
	ELSE IF @RoleID = 3
		DELETE FROM CustMaster With(ROWLOCK) WHERE CustID = @CustID
	ELSE IF @RoleID = 2
		DELETE FROM CustAgent With(ROWLOCK) WHERE CustID = @CustID
		
	DELETE FROM Customer With(ROWLOCK) WHERE CustID = @CustID
			
	return
END

INSERT INTO [dbo].[custinfo]([custid], [currency], [MaxPerMatch], [MaxPerMatch2], [MaxPerMatch3], [MaxPerMatch5], [MaxPerMatch8], [MaxPerMatch10], [MaxPerMatch11], [MaxPerMatch201],[MaxPerMatch151], [MaxPerMatch99], [roleid], srecommend, [mrecommend], [recommend], [dangercust], [autosuspend], [reject], [credit], [closed], [username], matchlimit, virtualmultiplier, DisableHorseRacing, DisableFinancial, DisableOutright)
VALUES(@custid, @currency, @MaxPerMatch, @MaxPerMatchv2, @MaxPerMatchv3, @MaxPerMatchv5, @MaxPerMatchv8, @MaxPerMatchv10, @MaxPerMatchv11, @MaxPerMatchv201,@MaxPerMatchv151, @MaxPerMatchv99, @roleid, @srecommend, @mrecommend, @recommend, 0, 0, isnull(@suspended,0), @credit, isnull(@closed,0), @username, @matchlimit, @virtualmultiplier, 
@DisableHorseRacing, @DisableFinancial,@DisableOutright)

if @@error <> 0
BEGIN
--	DELETE customer with (ROWLOCK) where custid =  @custid
	SELECT @ErrMsg = case @Language 
							when 'E' then 'Create customer failed. Please try again.'
							when 'CS' then N'新增会员不成功，请重新尝试.'
							when 'CT' then N'新增會員不成功,請重新再試.'
							when 'TH' then N'การเพิ่มจำนวนลูกค้าใหม่ ไม่สำเร็จ กรุณาทำรายการอีกครั้ง.'
							when 'J' then N'Create customer failed. Please try again.'
							when 'KO' then N'고객 생성에 실패했습니다. 다시 시도해 주시기 바랍니다.'
							else N'Create customer failed. Please try again.'
						end,
				@ErrCode = 113
				
	-- ROLLBACK MANUALLY
	IF @RoleID = 4
		DELETE FROM CustSuper With(ROWLOCK) WHERE CustID = @CustID
	ELSE IF @RoleID = 3
		DELETE FROM CustMaster With(ROWLOCK) WHERE CustID = @CustID
	ELSE IF @RoleID = 2
		DELETE FROM CustAgent With(ROWLOCK) WHERE CustID = @CustID
		
	DELETE FROM Customer With(ROWLOCK) WHERE CustID = @CustID

	return
END

GO
GRANT EXECUTE ON [Acc_CustomerInsUserInfo] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [Acc_CustomerInsUserInfo] TO [vnteam]

