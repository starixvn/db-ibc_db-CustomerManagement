ALTER PROCEDURE [dbo].[Dot_Dep_CustomerInsMember_Ag]	
	@FirstName nvarchar(50),
	@LastName nvarchar(50),
	@Email nvarchar(50),
	@DepositUserName varchar(50),
	@DepositUserID int,
	@Password varchar(40),
	@OddsType varchar(5),	
	
	@AgentID int,
	--12BETUS$01, 12BETEURO01 for normal sign up
	--12BETUS$02, 12BETEURO02 for sign up under affiliate. Need to input @AffiliateID as well
	@AffiliateID int = NULL,
	@BonusCode varchar(20) = NULL,
	
	@CustID int = 0 OUTPUT,
	@Username varchar(50) ='' OUTPUT,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(2000) = '' OUTPUT	
AS
/*
Created: 
Task : Create a 12 bet player account for this Affiliate on IBC system
DB: DB02.bodb02
Original:

Revisions:
	- 20090122@Dung: Add excute permission on bodbDownlineNet and view Definition on vnteam
	- 20090427@Phuc: hard code max pt for finance sporttype(a2+m2<=0.5, a1+m1<=0.5)
	- 20090427@Viet: temporary hard code pt=0 for finance
	- 20090507@Viet: HARD CODE MaxBet and MaxPermatch for new EURO member (Request By Charles@20090507)
	- 20090521@PhuongDao: Get maxcredit from CustAgent 
	- 20090528@Viet: HARD CODE MaxBet and MaxPermatch for new GBP, USD, AUD member (Request By Charles 2009-05-27)
	- 20090530@Phuc: PT for Tote and Fixed Odds(HR) and commission for 1x2 bettype.
	- 20090626@Viet: HARD CODE MaxBet and MaxPermatch for new RMB, RM, TB member (Request By Charles 2009-06-24, for 12bet's member only)
	- 20090917@Thien: Hard code Maxbet and MaxPerMatch for new SGD currency
    - 20091202@Peter : Write log for customer settings
    - 20091203@Peter : #353 IRP - DBA - Separate HorseRacing and Financial's setting from custsetting and custoverride
    - 20091205@Thien: Change default 12bet bet setting for IN currency to 5,000 max bet and 15,000 max per match
	
Param's Explanation:
• @CustID: return new 12bet Player Cust ID
• @Username: return new 12bet Player User name

• @ErrCode:
	= 0: Transaction recorded successfully.
	> 0: Specific Error.
	
• @ErrMsg: Error description.
*/
SET NOCOUNT ON

declare @currency int,
	@recommend int,
	@recommendForPT int,
	@mrecommend int,
	@srecommend int,	
	@agusername varchar(30),
	@site varchar(30),

	@pwdexpiry datetime,
	@ugroup varchar(5),
	@discount decimal(9,8),	
	@discountcs decimal(9,8),
	@discount1x2 decimal(9,8),--1x2 agent comm	
	@playerdiscount decimal(9,8),
	@playerdiscountcs decimal(9,8),
	@playerdiscount1x2 decimal(9,8),--1x2 comm	
	--v201
	@v201playerdiscount decimal(9,8),
	--v151
	@v151playerdiscount_31 decimal(9,8),--Tote comm
	@v151playerdiscount_41 decimal(9,8),--FO comm
	--v201
	@v201discount decimal(9,8),
	--v151
	@v151discount_31 decimal(9,8),
	@v151discount_41 decimal(9,8),

	@minbet money,	
	@maxbet money,	
	@maxpermatch money,	
	@minbetv2 money,	
	@maxbetv2 money,	
	@maxpermatchv2 money,

	@minbetv3 money,	
	@maxbetv3 money,	
	@maxpermatchv3 money,

	@minbetv5 money,	
	@maxbetv5 money,	
	@maxpermatchv5 money,

	@minbetv8 money,	
	@maxbetv8 money,	
	@maxpermatchv8 money,

	@minbetv10 money,	
	@maxbetv10 money,	
	@maxpermatchv10 money,

	@minbetv11 money,	
	@maxbetv11 money,	
	@maxpermatchv11 money,
	
	@minbetv201 money,	
	@maxbetv201 money,	
	@maxpermatchv201 money,
	
	@minbetv151 money,	
	@maxbetv151 money,	
	@maxpermatchv151 money,
	
	@minbetv99 money,	
	@maxbetv99 money,	
	@maxpermatchv99 money,
	
	@Success bit

Declare @apositiontaking_1 smallmoney,
	@apositiontaking_2 smallmoney,
	@apositiontaking_3 smallmoney,
	@apositiontaking_4 smallmoney,
	@apositiontaking_5 smallmoney,
	@apositiontaking_6 smallmoney,
	@apositiontaking_7 smallmoney,
	@apositiontaking_8 smallmoney,
	@apositiontaking_9 smallmoney,
	@apositiontaking_10 smallmoney,
	
	@alivepositiontaking_1 smallmoney,
	@alivepositiontaking_3 smallmoney,
	@alivepositiontaking_7 smallmoney,
	@alivepositiontaking_8 smallmoney,
	
	@v2apositiontaking_1 smallmoney,
	@v2apositiontaking_2 smallmoney,
	@v2apositiontaking_3 smallmoney,
	@v2apositiontaking_7 smallmoney,
	@v2apositiontaking_8 smallmoney,
	@v2apositiontaking_9 smallmoney,
	@v2apositiontaking_20 smallmoney,
	
	@v3apositiontaking_1 smallmoney,
	@v3apositiontaking_2 smallmoney,
	@v3apositiontaking_3 smallmoney,
	@v3apositiontaking_20 smallmoney,

	@v5apositiontaking_1 smallmoney,
	@v5apositiontaking_2 smallmoney,
	@v5apositiontaking_3 smallmoney,
	@v5apositiontaking_20 smallmoney,

	@v8apositiontaking_1 smallmoney,
	@v8apositiontaking_3 smallmoney,
	@v8apositiontaking_20 smallmoney,

	@v10apositiontaking_1 smallmoney,
	@v10apositiontaking_2 smallmoney,
	@v10apositiontaking_3 smallmoney,
	@v10apositiontaking_20 smallmoney,

	@v11apositiontaking_1 smallmoney,
	@v11apositiontaking_20 smallmoney,	
	
	@v201apositiontaking_2 smallmoney,
	@v201apositiontaking_3 smallmoney,
	
	@v151apositiontaking_31 smallmoney,
	@v151apositiontaking_32 smallmoney,
	@v151apositiontaking_41 smallmoney,
	@v151apositiontaking_42 smallmoney,

	@v99apositiontaking_1 smallmoney,
	@v99apositiontaking_2 smallmoney,
	@v99apositiontaking_3 smallmoney,
	@v99apositiontaking_20 smallmoney
	
declare @transcode bigint, 
	@MinMinBet money, @MaxMaxBet money, @MaxMaxPerMatch money,
	@MinMinBetv2 money, @MaxMaxBetv2 money, @MaxMaxPerMatchv2 money,
	@MinMinBetv3 money, @MaxMaxBetv3 money, @MaxMaxPerMatchv3 money,
	@MinMinBetv5 money, @MaxMaxBetv5 money, @MaxMaxPerMatchv5 money,
	@MinMinBetv8 money, @MaxMaxBetv8 money, @MaxMaxPerMatchv8 money,
	@MinMinBetv10 money, @MaxMaxBetv10 money, @MaxMaxPerMatchv10 money,
	@MinMinBetv11 money, @MaxMaxBetv11 money, @MaxMaxPerMatchv11 money,
	
	--v201
	@MinMinBetv201 money, @MaxMaxBetv201 money, @MaxMaxPerMatchv201 money,
	--v151
	@MinMinBetv151 money, @MaxMaxBetv151 money, @MaxMaxPerMatchv151 money,

	@MinMinBetv99 money, @MaxMaxBetv99 money, @MaxMaxPerMatchv99 money,	
	
	@AgentCredit money, @Credit_AllOtherMember money, @Aclosed bit,
	@MaxCredit_Mem money,
	@Asuspended bit,
--	@AgentMaxPerMatch money, @AgentMaxPerMatchb money,
--	@MaxPerMatch_AllOtherMember money, @MaxPerMatchv2_AllOtherMember money,

	--m2
	@mpositiontaking_1 smallmoney,
	@mpositiontaking_2 smallmoney,
	@mpositiontaking_3 smallmoney,
	@mpositiontaking_4 smallmoney,
	@mpositiontaking_5 smallmoney,
	@mpositiontaking_6 smallmoney,
	@mpositiontaking_7 smallmoney,
	@mpositiontaking_8 smallmoney,
	@mpositiontaking_9 smallmoney,
	@mpositiontaking_10 smallmoney,
	@mlivepositiontaking_1 smallmoney,
	@mlivepositiontaking_3 smallmoney,
	@mlivepositiontaking_7 smallmoney,
	@mlivepositiontaking_8 smallmoney,
	
	@v2mpositiontaking_1 smallmoney,
	@v2mpositiontaking_2 smallmoney,
	@v2mpositiontaking_3 smallmoney,
	@v2mpositiontaking_7 smallmoney,
	@v2mpositiontaking_8 smallmoney,
	@v2mpositiontaking_9 smallmoney,
	@v2mpositiontaking_20 smallmoney,

	@v3mpositiontaking_1 smallmoney,
	@v3mpositiontaking_2 smallmoney,
	@v3mpositiontaking_3 smallmoney,
	@v3mpositiontaking_20 smallmoney,

	@v5mpositiontaking_1 smallmoney,
	@v5mpositiontaking_2 smallmoney,
	@v5mpositiontaking_3 smallmoney,
	@v5mpositiontaking_20 smallmoney,

	@v8mpositiontaking_1 smallmoney,
	@v8mpositiontaking_3 smallmoney,
	@v8mpositiontaking_20 smallmoney,

	@v10mpositiontaking_1 smallmoney,
	@v10mpositiontaking_2 smallmoney,
	@v10mpositiontaking_3 smallmoney,
	@v10mpositiontaking_20 smallmoney,

	@v11mpositiontaking_1 smallmoney,
	@v11mpositiontaking_20 smallmoney,
	--v201
	@v201mpositiontaking_2 smallmoney,
	@v201mpositiontaking_3 smallmoney,
	--v151
	@v151mpositiontaking_31 smallmoney,
	@v151mpositiontaking_32 smallmoney,
	@v151mpositiontaking_41 smallmoney,
	@v151mpositiontaking_42 smallmoney,

	@v99mpositiontaking_1 smallmoney,
	@v99mpositiontaking_2 smallmoney,
	@v99mpositiontaking_3 smallmoney,
	@v99mpositiontaking_20 smallmoney,
	
	--s3
	@spositiontaking_1 smallmoney,
	@spositiontaking_2 smallmoney,
	@spositiontaking_3 smallmoney,
	@spositiontaking_4 smallmoney,
	@spositiontaking_5 smallmoney,
	@spositiontaking_6 smallmoney,
	@spositiontaking_7 smallmoney,
	@spositiontaking_8 smallmoney,
	@spositiontaking_9 smallmoney,
	@spositiontaking_10 smallmoney,
	
	@slivepositiontaking_1 smallmoney,
	@slivepositiontaking_3 smallmoney,
	@slivepositiontaking_7 smallmoney,
	@slivepositiontaking_8 smallmoney,
	
	@v2spositiontaking_1 smallmoney,
	@v2spositiontaking_2 smallmoney,
	@v2spositiontaking_3 smallmoney,
	@v2spositiontaking_7 smallmoney,
	@v2spositiontaking_8 smallmoney,
	@v2spositiontaking_9 smallmoney,
	@v2spositiontaking_20 smallmoney,
	
	@v3spositiontaking_1 smallmoney,
	@v3spositiontaking_2 smallmoney,
	@v3spositiontaking_3 smallmoney,
	@v3spositiontaking_20 smallmoney,

	@v5spositiontaking_1 smallmoney,
	@v5spositiontaking_2 smallmoney,
	@v5spositiontaking_3 smallmoney,
	@v5spositiontaking_20 smallmoney,

	@v8spositiontaking_1 smallmoney,
	@v8spositiontaking_3 smallmoney,
	@v8spositiontaking_20 smallmoney,

	@v10spositiontaking_1 smallmoney,
	@v10spositiontaking_2 smallmoney,
	@v10spositiontaking_3 smallmoney,
	@v10spositiontaking_20 smallmoney,

	@v11spositiontaking_1 smallmoney,
	@v11spositiontaking_20 smallmoney,
	--v201
	@v201spositiontaking_2 smallmoney,
	@v201spositiontaking_3 smallmoney,
	--v151
	@v151spositiontaking_31 smallmoney,
	@v151spositiontaking_32 smallmoney,
	@v151spositiontaking_41 smallmoney,
	@v151spositiontaking_42 smallmoney,

	@v99spositiontaking_1 smallmoney,
	@v99spositiontaking_2 smallmoney,
	@v99spositiontaking_3 smallmoney,
	@v99spositiontaking_20 smallmoney,
	
	@adiscount decimal(9,8),
	@adiscountcs decimal(9,8),
	@adiscount1x2 decimal(9,8),--1x2 master comm	
	@sdiscount decimal(9,8),
	@sdiscountcs decimal(9,8),
	@sdiscount1x2 decimal(9,8),--1x2 super comm
	@maxdiscount decimal(9,8),
	@maxdiscountcs decimal(9,8),
	
	--v201
	@v201adiscount decimal(9,8),
	@v201sdiscount decimal(9,8),
	--v151
	@v151adiscount_31 decimal(9,8),
	@v151sdiscount_31 decimal(9,8),
	
	@v151adiscount_41 decimal(9,8),
	@v151sdiscount_41 decimal(9,8),

	@DisableHorseRacing bit,
	@suspendedFlag varchar(6),
	@suspended bit,

	@matchlimit smallmoney,
	@virtualmultiplier smallmoney

--Init param
select @ErrCode = 0,
	@ErrMsg = '',
	@pwdexpiry = dateadd(dd, 30, getdate()),
	@ugroup = @OddsType
	
----------------Affiliate Bonus Code---------------------
IF (isnull(@AffiliateID, 0) = 0 AND @BonusCode is not null) 
BEGIN	
	select @AffiliateID = AffID from DB052.[Affiliate_12Bet].dbo.AffDetail with(nolock) where bonuscode = @BonusCode	
	if isnull(@AffiliateID,0) > 0 -- @bonuscode is valid, change currency agent from [..]01 --> [..]02
	BEGIN
		declare @_currAgentName varchar(20)
		select @_currAgentName =username from Custinfo with(nolock) where custid=@AgentID					
		select @AgentID = CustID from CustInfo with(nolock) where username = Replace(@_currAgentName, '01', '02')	
	END	
END
-------------------------------------------------------

select
	@recommend = ci.custID,
	@agusername = ci.username,
	@currency = ci.currency, 
	@maxpermatch = maxpermatch,
	@maxpermatchv2 = maxpermatch2,
	@maxpermatchv3 = maxpermatch3,
	@maxpermatchv5 = maxpermatch5,
	@maxpermatchv8 = maxpermatch8,
	@maxpermatchv10 = maxpermatch10,
	@maxpermatchv11 = maxpermatch11,
	@maxpermatchv201 = maxpermatch201,
	@maxpermatchv151 = maxpermatch151,
	@maxpermatchv99 = maxpermatch99,
	@mrecommend = ci.mrecommend, 
	@srecommend = ci.srecommend,
	@site = c.site
from custinfo ci with (NOLOCK) 
	inner join customer c with (nolock) on ci.custid = c.custid
where ci.CustID = @AgentID

--check valid agent here
if @recommend is null
BEGIN
	Select @ErrMsg = 'Invalid agent.', @ErrCode = 10
	return
END

--generate the username automatically

Select @username = isnull(max(cast(replace(username, @AgUsername, '') as int)),0)
from customer with (nolock)
where recommend = @recommend and roleid = 1
	and charindex(@AgUsername, username) = 1
/*
Select @username = isnull(right(max(username),3), '000')
from customer with (nolock)
where recommend = @recommend and roleid = 1
	and charindex(@AgUsername, username) = 1
	and len(username) = len(@AgUsername) + 3
*/
if isnumeric(@username) = 1
BEGIN
	select @username = convert(varchar(20), convert(int, @username) + 1)
	if len(@username)<3
	BEGIN
		select @Username = right('00' + @username, 3)
	END
END
else
BEGIN
	select @UserName = '001'
END
select @username = @agusername  + @username

--20080623: Add sitename prefix to the DepositUsername
select @DepositUserName = @site + '$' + @DepositUserName
 
--Check the unique username
if exists (select 1 from customer c with (NOLOCK)
				--inner join customer ag with(nolock) on c.recommend = ag.custid and c.roleid = 1
			where c.username2 = @DepositUserName
					--and ag.site= @site
				)
	or exists (select 1 from customer with(NOLOCK) where username = @UserName)
BEGIN
	Select @ErrMsg = 'The username is not available.', @ErrCode = 11
	return
END

--Will check the usergroup here
--MinBet, MaxBet, Commission get from CA Agent
select 	
	@minbet = minbet,
	@maxbet = maxbet
from custsetting with (NOLOCK) where custid = @recommend and bettype=1 and sporttype=1

select 	
	@minbetv2 = minbet,
	@maxbetv2 = maxbet
from custsetting with (NOLOCK) where custid = @recommend and bettype=1 and sporttype=2

select 	
	@minbetv3 = minbet,
	@maxbetv3 = maxbet
from custsetting with (NOLOCK) where custid = @recommend and bettype=1 and sporttype=3

select 	
	@minbetv5 = minbet,
	@maxbetv5 = maxbet
from custsetting with (NOLOCK) where custid = @recommend and bettype=1 and sporttype=5

select 	
	@minbetv8 = minbet,
	@maxbetv8 = maxbet
from custsetting with (NOLOCK) where custid = @recommend and bettype=1 and sporttype=8

select 	
	@minbetv10 = minbet,
	@maxbetv10 = maxbet
from custsetting with (NOLOCK) where custid = @recommend and bettype=1 and sporttype=10

select 	
	@minbetv11 = minbet,
	@maxbetv11 = maxbet
from custsetting with (NOLOCK) where custid = @recommend and bettype=1 and sporttype=11

select 	
	@minbetv201 = minbet,
	@maxbetv201 = maxbet
from custsetting3rd with (NOLOCK) where custid = @recommend and bettype=3 and sporttype=201
select 	
	@minbetv151 = minbet,
	@maxbetv151 = maxbet
from custsetting3rd with (NOLOCK) where custid = @recommend and bettype=31 and sporttype=151

select 	
	@minbetv99 = minbet,
	@maxbetv99 = maxbet
from custsetting with (NOLOCK) where custid = @recommend and bettype=1 and sporttype=99


select 	
	@discount = case when @ugroup in ('a','hka') then groupa when @ugroup in ('b','hkb') then groupb when @ugroup in ('c','hkc') then groupc when @ugroup in ('d','hkd') then groupd else groupa end		
from custsetting with (NOLOCK) where custid = @recommend and bettype=1 and sporttype=1

select 	
	@discountcs = discount		
from custsetting with (NOLOCK)
where custid = @recommend and bettype=4 and sporttype=1
--1x2
select 	
	@discount1x2 = discount		
from custsetting with (NOLOCK)
where custid = @recommend and bettype=5 and sporttype=1
--v201
select 	
	@v201discount = discount		
from custsetting3rd with (NOLOCK)
where custid = @recommend and bettype=3 and sporttype=201
--v151
select 	
	@v151discount_31 = discount		
from custsetting3rd with (NOLOCK)
where custid = @recommend and bettype=31 and sporttype=151
select 	
	@v151discount_41 = discount		
from custsetting3rd with (NOLOCK)
where custid = @recommend and bettype=41 and sporttype=151

DECLARE @vMaxbet money, @vMaxpermatch money
SELECT @vMaxbet = 0, @vMaxpermatch = 0 -- assign the default value

IF @site = '12Bet'
BEGIN
	IF @Currency = 6 SELECT @vMaxbet = 250, @vMaxpermatch = 750 -- EURO
	IF @Currency= 12 SELECT @vMaxbet = 250, @vMaxpermatch = 750 -- GBP
	IF @Currency = 3  SELECT @vMaxbet = 350, @vMaxpermatch = 1150 -- USD
	IF @Currency = 9 SELECT @vMaxbet = 500, @vMaxpermatch = 1500 -- AUD	
	IF @Currency = 13 SELECT @vMaxbet = 10000, @vMaxpermatch = 30000 -- RMB
	IF @Currency = 2 SELECT @vMaxbet = 1500, @vMaxpermatch = 3000 -- RM
	IF @Currency = 4 SELECT @vMaxbet = 15000, @vMaxpermatch = 30000 -- TB
	IF @Currency = 41 SELECT @vMaxbet = 500, @vMaxpermatch = 1500 -- CHF
	IF @Currency = 1 SELECT @vMaxbet = 1500, @vMaxpermatch = 4500 -- SD$
	IF @Currency = 15 SELECT @vMaxbet = 5000, @vMaxpermatch = 15000 -- IN (Indo rupiah)
END
/*Thien@2009117: comment out, to let MS88 handle by themselves.
IF @site = 'mansion88'
BEGIN
    IF @Currency = 6 SELECT @vMaxbet = 100, @vMaxpermatch = 100 -- EURO
	IF @Currency= 12 SELECT @vMaxbet = 100, @vMaxpermatch = 100 -- GBP
	IF @Currency = 2 SELECT @vMaxbet = 4000, @vMaxpermatch = 16000 -- RM
	IF @Currency = 4 SELECT @vMaxbet = 50000, @vMaxpermatch = 200000 -- TB
END
*/

if @vMaxbet > 0 and @vMaxpermatch > 0
BEGIN
    SELECT	@maxpermatch = @vMaxpermatch,
		@maxpermatchv2 = @vMaxpermatch,
		@maxpermatchv3 = @vMaxpermatch,
		@maxpermatchv5 = @vMaxpermatch,
		@maxpermatchv8 = @vMaxpermatch,
		@maxpermatchv10 = @vMaxpermatch,
		@maxpermatchv11 = @vMaxpermatch,
		@maxpermatchv201 = @vMaxpermatch,
		--@maxpermatchv151 = @vMaxpermatch
		@maxpermatchv99 = @vMaxpermatch,
		@maxbet = @vMaxbet,
		@maxbetv2 = @vMaxbet,
		@maxbetv3 = @vMaxbet,
		@maxbetv5 = @vMaxbet,
		@maxbetv8 = @vMaxbet,
		@maxbetv10 = @vMaxbet,
		@maxbetv11 = @vMaxbet,
		@maxbetv201 = @vMaxbet,
		--@maxbetv151 = @vMaxbet
		@maxbetv99 = @vMaxbet
END

select
	@playerdiscount = 0,
	@playerdiscountcs = 0,
	@playerdiscount1x2 = 0,
	--v201
	@v201playerdiscount = 0,

	--v151
	@v151playerdiscount_31 = 0,
	@v151playerdiscount_41 = 0 

--Position Taking get from Affilate Account
if isnull(@AffiliateID,0) > 0
BEGIN
	if NOT exists(select 1 from custinfo with (NOLOCK) 
				where CustID = @AffiliateID and roleID = 2)
	BEGIN
		Select @ErrMsg = 'Invalid Affiliate agent.', @ErrCode = 12
		return
	END	
				
	select @recommendForPT = @AffiliateID
	
	--hard code PT for Horse racing
	select @v151apositiontaking_31 = 0
    select @v151apositiontaking_32 = 0
    select @v151apositiontaking_41 = 0
    select @v151apositiontaking_42 = 0
    
    select @v151mpositiontaking_31 = 0.5
    select @v151mpositiontaking_32 = 0.5
    select @v151mpositiontaking_41 = 0.5
    select @v151mpositiontaking_42 = 0.5

END
ELSE
BEGIN
	select @recommendForPT = @recommend
	
	if @site = '12Bet'
	BEGIN
	    select @v151apositiontaking_31 = 0.5
        select @v151apositiontaking_32 = 0.5
        select @v151apositiontaking_41 = 0.5
        select @v151apositiontaking_42 = 0.5
    END
    ELSE --if @site in ('mansion88', 'asiabet88')
    BEGIN
        select @v151apositiontaking_31 = 0
        select @v151apositiontaking_32 = 0
        select @v151apositiontaking_41 = 0
        select @v151apositiontaking_42 = 0
    END
    
    select @v151mpositiontaking_31 = 0
    select @v151mpositiontaking_32 = 0
    select @v151mpositiontaking_41 = 0
    select @v151mpositiontaking_42 = 0
END

select @apositiontaking_1 = apositiontaking, @alivepositiontaking_1 = alivepositiontaking  from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=1 and sporttype=1
select @apositiontaking_3 = apositiontaking, @alivepositiontaking_3 = alivepositiontaking  from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=3 and sporttype=1
select @apositiontaking_7 = apositiontaking, @alivepositiontaking_7 = alivepositiontaking  from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=7 and sporttype=1
select @apositiontaking_8 = apositiontaking, @alivepositiontaking_8 = alivepositiontaking  from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=8 and sporttype=1
select @apositiontaking_2 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=2 and sporttype=1
select @apositiontaking_4 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=4 and sporttype=1

select @apositiontaking_5 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=5 and sporttype=1
select @apositiontaking_6 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=6 and sporttype=1
select @apositiontaking_9 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=9 and sporttype=1
select @apositiontaking_10 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=10 and sporttype=1

select @v2apositiontaking_1 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=1 and sporttype=2
select @v2apositiontaking_2 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=2 and sporttype=2
select @v2apositiontaking_3 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=3 and sporttype=2
select @v2apositiontaking_7 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=7 and sporttype=2
select @v2apositiontaking_8 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=8 and sporttype=2
select @v2apositiontaking_9 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=9 and sporttype=2
select @v2apositiontaking_20 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=20 and sporttype=2

select @v3apositiontaking_1 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=1 and sporttype=3
select @v3apositiontaking_2 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=2 and sporttype=3
select @v3apositiontaking_3 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=3 and sporttype=3
select @v3apositiontaking_20 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=20 and sporttype=3

select @v5apositiontaking_1 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=1 and sporttype=5
select @v5apositiontaking_2 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=2 and sporttype=5
select @v5apositiontaking_3 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=3 and sporttype=5
select @v5apositiontaking_20 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=20 and sporttype=5

select @v8apositiontaking_1 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=1 and sporttype=8
select @v8apositiontaking_3 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=3 and sporttype=8
select @v8apositiontaking_20 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=20 and sporttype=8

select @v10apositiontaking_1 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=1 and sporttype=10
select @v10apositiontaking_2 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=2 and sporttype=10
select @v10apositiontaking_3 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=3 and sporttype=10
select @v10apositiontaking_20 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=20 and sporttype=10

select @v11apositiontaking_1 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=1 and sporttype=11
select @v11apositiontaking_20 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=20 and sporttype=11

--select @v201apositiontaking_2 = apositiontaking from custsetting3rd with (NOLOCK) where custid = @recommendForPT and bettype=2 and sporttype=201
--select @v201apositiontaking_3 = apositiontaking from custsetting3rd with (NOLOCK) where custid = @recommendForPT and bettype=3 and sporttype=201

--select @v151apositiontaking_31 = apositiontaking from custsetting3rd with (NOLOCK) where custid = @recommendForPT and bettype=31 and sporttype=151
--select @v151apositiontaking_32 = apositiontaking from custsetting3rd with (NOLOCK) where custid = @recommendForPT and bettype=32 and sporttype=151
--select @v151apositiontaking_41 = apositiontaking from custsetting3rd with (NOLOCK) where custid = @recommendForPT and bettype=41 and sporttype=151
--select @v151apositiontaking_42 = apositiontaking from custsetting3rd with (NOLOCK) where custid = @recommendForPT and bettype=42 and sporttype=151

select @v99apositiontaking_1 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=1 and sporttype=99
select @v99apositiontaking_2 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=2 and sporttype=99
select @v99apositiontaking_3 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=3 and sporttype=99
select @v99apositiontaking_20 = apositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=20 and sporttype=99

	

----INSERT MEMBER ---------------------------------------------------------------


--Check an account disabled or not 
EXEC dbo.Acc_CustomerSelCheckEnable @custid = @recommend, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output 
if @ErrCode <>0	return 

	
declare @ErrType varchar(4000)	

Select @ErrCode = 0

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
select @username = replace(@username, ' ', '')
select @site=case when @ugroup like 'indo_' then 'INDO' else '' end, @ugroup = case when @ugroup like 'indo_' then right(@ugroup,1) else @ugroup end

if exists(select 1 from customer with (NOLOCK) where username= @username)
	or exists(select 1 from custsub with (NOLOCK) where username= @username) 
BEGIN
	Select @ErrMsg = 'This username is not available.', @ErrCode = 201
	return
END



declare @DisableFinancial bit
select 
	@currency = currency, 
	@mrecommend = mrecommend, 
	@srecommend = srecommend, 
	@AgentCredit = IsNull(Credit, 0),
--	@MaxCredit_Mem = isnull(maxcredit,0), 
--	@AgentMaxPerMatch = IsNull(MaxPerMatch, 0),
--	@AgentMaxPerMatchb = IsNull(MaxPerMatchb, 0),
	@Aclosed = closed,
	@Asuspended = reject,
	@matchlimit = matchlimit,
	@virtualmultiplier = virtualmultiplier,
	@DisableHorseRacing = case when DisableHorseRacing = 1 then 1 else @DisableHorseRacing end,
	@DisableFinancial = DisableFinancial
from custinfo with (NOLOCK) where CustID = @recommend

SELECT @MaxCredit_Mem = isnull(maxcredit,0) FROM CustAgent WITH (NOLOCK) 
WHERE CustID = @recommend


select @mpositiontaking_1 = mpositiontaking, @mlivepositiontaking_1 = mlivepositiontaking  from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=1 and sporttype=1
select @mpositiontaking_3 = mpositiontaking, @mlivepositiontaking_3 = mlivepositiontaking  from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=3 and sporttype=1
select @mpositiontaking_7 = mpositiontaking, @mlivepositiontaking_7 = mlivepositiontaking  from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=7 and sporttype=1
select @mpositiontaking_8 = mpositiontaking, @mlivepositiontaking_8 = mlivepositiontaking  from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=8 and sporttype=1
select @mpositiontaking_2 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=2 and sporttype=1
select @mpositiontaking_4 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=4 and sporttype=1

select @mpositiontaking_5 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=5 and sporttype=1
select @mpositiontaking_6 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=6 and sporttype=1
select @mpositiontaking_9 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=9 and sporttype=1
select @mpositiontaking_10 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=10 and sporttype=1

select @v2mpositiontaking_1 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=1 and sporttype=2
select @v2mpositiontaking_2 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=2 and sporttype=2
select @v2mpositiontaking_3 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=3 and sporttype=2
select @v2mpositiontaking_7 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=7 and sporttype=2
select @v2mpositiontaking_8 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=8 and sporttype=2
select @v2mpositiontaking_9 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=9 and sporttype=2
select @v2mpositiontaking_20 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=20 and sporttype=2

select @v3mpositiontaking_1 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=1 and sporttype=3
select @v3mpositiontaking_2 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=2 and sporttype=3
select @v3mpositiontaking_3 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=3 and sporttype=3
select @v3mpositiontaking_20 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=20 and sporttype=3

select @v5mpositiontaking_1 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=1 and sporttype=5
select @v5mpositiontaking_2 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=2 and sporttype=5
select @v5mpositiontaking_3 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=3 and sporttype=5
select @v5mpositiontaking_20 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=20 and sporttype=5

select @v8mpositiontaking_1 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=1 and sporttype=8
select @v8mpositiontaking_3 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=3 and sporttype=8
select @v8mpositiontaking_20 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=20 and sporttype=8

select @v10mpositiontaking_1 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=1 and sporttype=10
select @v10mpositiontaking_2 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=2 and sporttype=10
select @v10mpositiontaking_3 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=3 and sporttype=10
select @v10mpositiontaking_20 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=20 and sporttype=10

select @v11mpositiontaking_1 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=1 and sporttype=11
select @v11mpositiontaking_20 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=20 and sporttype=11

--select @v201mpositiontaking_2 = mpositiontaking from custsetting3rd with (NOLOCK) where custid = @recommendForPT and bettype=2 and sporttype=201
--select @v201mpositiontaking_3 = mpositiontaking from custsetting3rd with (NOLOCK) where custid = @recommendForPT and bettype=3 and sporttype=201

--select @v151mpositiontaking_31 = mpositiontaking from custsetting3rd with (NOLOCK) where custid = @recommendForPT and bettype=31 and sporttype=151
--select @v151mpositiontaking_32 = mpositiontaking from custsetting3rd with (NOLOCK) where custid = @recommendForPT and bettype=32 and sporttype=151
--select @v151mpositiontaking_41 = mpositiontaking from custsetting3rd with (NOLOCK) where custid = @recommendForPT and bettype=41 and sporttype=151
--select @v151mpositiontaking_42 = mpositiontaking from custsetting3rd with (NOLOCK) where custid = @recommendForPT and bettype=42 and sporttype=151

select @v99mpositiontaking_1 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=1 and sporttype=99
select @v99mpositiontaking_2 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=2 and sporttype=99
select @v99mpositiontaking_3 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=3 and sporttype=99
select @v99mpositiontaking_20 = mpositiontaking from custsetting with (NOLOCK) where custid = @recommendForPT and bettype=20 and sporttype=99


select @spositiontaking_1 = 0, @slivepositiontaking_1 = 0
select @spositiontaking_3 = 0, @slivepositiontaking_3 = 0  
select @spositiontaking_7 = 0, @slivepositiontaking_7 = 0  
select @spositiontaking_8 = 0, @slivepositiontaking_8 = 0 
select @spositiontaking_2 = 0 
select @spositiontaking_4 = 0 

select @spositiontaking_5 = 0 
select @spositiontaking_6 = 0 
select @spositiontaking_9 = 0 
select @spositiontaking_10 = 0

select @v2spositiontaking_1 = 0 
select @v2spositiontaking_2 = 0 
select @v2spositiontaking_3 = 0 
select @v2spositiontaking_7 = 0 
select @v2spositiontaking_8 = 0 
select @v2spositiontaking_9 = 0 
select @v2spositiontaking_20 = 0 

select @v3spositiontaking_1 = 0 
select @v3spositiontaking_2 = 0 
select @v3spositiontaking_3 = 0 
select @v3spositiontaking_20 = 0

select @v5spositiontaking_1 = 0
select @v5spositiontaking_2 = 0 
select @v5spositiontaking_3 = 0 
select @v5spositiontaking_20 = 0 

select @v8spositiontaking_1 = 0 
select @v8spositiontaking_3 = 0 
select @v8spositiontaking_20 = 0 

select @v10spositiontaking_1 = 0 
select @v10spositiontaking_2 = 0
select @v10spositiontaking_3 = 0 
select @v10spositiontaking_20 = 0

select @v11spositiontaking_1 = 0
select @v11spositiontaking_20 = 0

select @v201spositiontaking_2 = 0
select @v201spositiontaking_3 = 0

select @v151spositiontaking_31 = 0
select @v151spositiontaking_32 = 0
select @v151spositiontaking_41 = 0
select @v151spositiontaking_42 = 0

select @v99spositiontaking_1 = 0
select @v99spositiontaking_2 = 0
select @v99spositiontaking_3 = 0
select @v99spositiontaking_20 = 0


select @adiscount =  case when @ugroup in ('a','hka') then groupa when @ugroup in ('b','hkb') then groupb when @ugroup in ('c','hkc') then groupc else groupd end
from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=1
select @adiscountcs =  adiscount from custsetting with (NOLOCK) where custid = @mrecommend and bettype=4 and sporttype=1
--1x2 adiscount
select @adiscount1x2 = adiscount 
from custsetting with (NOLOCK) where custid = @mrecommend and bettype=5 and sporttype=1

--v201 adiscount
select @v201adiscount = adiscount 
from custsetting3rd with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=201

--v151 adiscount
select @v151adiscount_31 = adiscount 
from custsetting3rd with (NOLOCK) where custid = @mrecommend and bettype=31 and sporttype=151
select @v151adiscount_41 = adiscount 
from custsetting3rd with (NOLOCK) where custid = @mrecommend and bettype=41 and sporttype=151

select @sdiscount =  case when @ugroup in ('a','hka') then groupa when @ugroup in ('b','hkb') then groupb when @ugroup in ('c','hkc') then groupc else groupd end
from custsetting with (NOLOCK) where custid = @srecommend and bettype=1 and sporttype=1
select @sdiscountcs =  sdiscount from custsetting with (NOLOCK) where custid = @srecommend and bettype=4 and sporttype=1
--1x2
select @sdiscount1x2 =  sdiscount from custsetting with (NOLOCK) where custid = @srecommend and bettype=5 and sporttype=1

--v201 sdiscount
select @v201sdiscount = sdiscount 
from custsetting3rd with (NOLOCK) where custid = @srecommend and bettype=3 and sporttype=201

--v151 sdiscount
select @v151sdiscount_31 = sdiscount 
from custsetting3rd with (NOLOCK) where custid = @srecommend and bettype=31 and sporttype=151
select @v151sdiscount_41 = sdiscount 
from custsetting3rd with (NOLOCK) where custid = @srecommend and bettype=41 and sporttype=151

select
	@playerdiscount = case when @playerdiscount > @adiscount then @adiscount else @playerdiscount end,
	@playerdiscountcs = case when @playerdiscountcs > @adiscountcs then @adiscountcs else @playerdiscountcs end,
	--1x2
	@playerdiscount1x2 = case when @playerdiscount1x2 > @adiscount1x2 then @adiscount1x2 else @playerdiscount1x2 end,
	--v201
	@v201playerdiscount = case when @v201playerdiscount > @v201adiscount then @v201adiscount else @v201playerdiscount end,
	--v151
	@v151playerdiscount_31 = case when @v151playerdiscount_31 > @v151adiscount_31 then @v151adiscount_31 else @v151playerdiscount_31 end,
	@v151playerdiscount_41 = case when @v151playerdiscount_41 > @v151adiscount_41 then @v151adiscount_41 else @v151playerdiscount_41 end
	
-- NOTE : agent can set discount to member more than what he get.   but should not more than Master discount
--	which normally Master is get FULL discount from company  (Later might need to detect at SUPERAGENT level


SET ANSI_WARNINGS OFF
Select 
	@MinMinBet = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
	@MaxMaxBet = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.CustID or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) and cs.bettype = 1 and cs.sporttype=1
where ci.custid = @Recommend

Select 
	@MinMinBetv2 = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
	@MaxMaxBetv2 = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.CustID or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) and cs.bettype = 1 and cs.sporttype=2
where ci.custid = @Recommend

Select 
	@MinMinBetv3 = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
	@MaxMaxBetv3 = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.CustID or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) and cs.bettype = 1 and cs.sporttype=3
where ci.custid = @Recommend

Select 
	@MinMinBetv5 = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
	@MaxMaxBetv5 = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.CustID or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) and cs.bettype = 1 and cs.sporttype=5
where ci.custid = @Recommend

Select 
	@MinMinBetv8 = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
	@MaxMaxBetv8 = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.CustID or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) and cs.bettype = 1 and cs.sporttype=8
where ci.custid = @Recommend

Select 
	@MinMinBetv10 = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
	@MaxMaxBetv10 = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.CustID or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) and cs.bettype = 1 and cs.sporttype=10
where ci.custid = @Recommend

Select 
	@MinMinBetv11 = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
	@MaxMaxBetv11 = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.CustID or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) and cs.bettype = 1 and cs.sporttype=11
where ci.custid = @Recommend

--v201
Select 
	@MinMinBetv201 = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
	@MaxMaxBetv201 = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
from 
	custsetting3rd as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.CustID or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) and cs.bettype = 3 and cs.sporttype=201
where ci.custid = @Recommend
--v151
Select 
	@MinMinBetv151 = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
	@MaxMaxBetv151 = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
from 
	custsetting3rd as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.CustID or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) and cs.bettype = 31 and cs.sporttype=151
where ci.custid = @Recommend


Select 
	@MinMinBetv99 = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
	@MaxMaxBetv99 = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.CustID or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) and cs.bettype = 1 and cs.sporttype=99
where ci.custid = @Recommend

Select	
	@MaxMaxperMatch = IsNull(Min(case when cs.MaxPerMatch = 0 then NULL else cs.MaxPerMatch end),0), 
	@MaxMaxPerMatchv2 = IsNull(Min(case when cs.MaxPerMatch2 = 0 then NULL else cs.MaxPerMatch2 end),0),
	@MaxMaxPerMatchv3 = IsNull(Min(case when cs.MaxPerMatch3 = 0 then NULL else cs.MaxPerMatch3 end),0),
	@MaxMaxPerMatchv5 = IsNull(Min(case when cs.MaxPerMatch5 = 0 then NULL else cs.MaxPerMatch5 end),0),
	@MaxMaxPerMatchv8 = IsNull(Min(case when cs.MaxPerMatch8 = 0 then NULL else cs.MaxPerMatch8 end),0),
	@MaxMaxPerMatchv10 = IsNull(Min(case when cs.MaxPerMatch10 = 0 then NULL else cs.MaxPerMatch10 end),0),
	@MaxMaxPerMatchv11 = IsNull(Min(case when cs.MaxPerMatch11 = 0 then NULL else cs.MaxPerMatch11 end),0),
	--v201
	@MaxMaxPerMatchv201 = IsNull(Min(case when cs.MaxPerMatch201 = 0 then NULL else cs.MaxPerMatch201 end),0),
	--v151
	@MaxMaxPerMatchv151 = IsNull(Min(case when cs.MaxPerMatch151 = 0 then NULL else cs.MaxPerMatch151 end),0),

	@MaxMaxPerMatchv99 = IsNull(Min(case when cs.MaxPerMatch99 = 0 then NULL else cs.MaxPerMatch99 end),0)
from 
	custinfo as cs WITH (NOLOCK) 
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.CustID or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
where ci.custid = @Recommend
SET ANSI_WARNINGS ON

select @ErrType = ''
select @ErrType = @ErrType + sportname + ', '
from sports with (NOLOCK) inner join
(
				select 1 as sporttype, @MinBet as MinBet, @MinMinBet as MinMinBet
	union all	select 2 as sporttype, @MinBetv2 as MinBet, @MinMinBetv2 as MinMinBet
	union all	select 3 as sporttype, @MinBetv3 as MinBet, @MinMinBetv3 as MinMinBet
	union all	select 5 as sporttype, @MinBetv5 as MinBet, @MinMinBetv5 as MinMinBet
	union all	select 8 as sporttype, @MinBetv8 as MinBet, @MinMinBetv8 as MinMinBet
	union all	select 10 as sporttype, @MinBetv10 as MinBet, @MinMinBetv10 as MinMinBet
	union all	select 11 as sporttype, @MinBetv11 as MinBet, @MinMinBetv11 as MinMinBet	
	--v201
	union all	select 201 as sporttype, @MinBetv201 as MinBet, @MinMinBetv201 as MinMinBet
	union all	select 201 as sporttype, @MinBetv201 as MinBet, @MinMinBetv201 as MinMinBet
	--v151
	union all	select 151 as sporttype, @MinBetv151 as MinBet, @MinMinBetv151 as MinMinBet

	union all	select 99 as sporttype, @MinBetv99 as MinBet, @MinMinBetv99 as MinMinBet	 
) as b on sports.sporttype = b.sporttype
where MinMinBet>0 and MinBet>0 and MinBet<MinMinBet
if @ErrType <>''
BEGIN
	SELECT
		@ErrMsg =	'Sorry, min bet must be equal to or greater than Super/Master/Agent min bet ('+@ErrType+').',
		@ErrCode = 205
	return
END

select @ErrType = ''
select @ErrType = @ErrType + sportname + ', '
from sports with (NOLOCK) inner join
(
				select 1 as sporttype, @MaxBet as MaxBet, @MaxMaxBet as MaxMaxBet
	union all	select 2 as sporttype, @MaxBetv2 as MaxBet, @MaxMaxBetv2 as MaxMaxBet
	union all	select 3 as sporttype, @MaxBetv3 as MaxBet, @MaxMaxBetv3 as MaxMaxBet
	union all	select 5 as sporttype, @MaxBetv5 as MaxBet, @MaxMaxBetv5 as MaxMaxBet
	union all	select 8 as sporttype, @MaxBetv8 as MaxBet, @MaxMaxBetv8 as MaxMaxBet
	union all	select 10 as sporttype, @MaxBetv10 as MaxBet, @MaxMaxBetv10 as MaxMaxBet
	union all	select 11 as sporttype, @MaxBetv11 as MaxBet, @MaxMaxBetv11 as MaxMaxBet	
	--v201
	union all	select 201 as sporttype, @MaxBetv201 as MaxBet, @MaxMaxBetv201 as MaxMaxBet	
	--v151
	union all	select 151 as sporttype, @MaxBetv151 as MaxBet, @MaxMaxBetv151 as MaxMaxBet	

	union all	select 99 as sporttype, @MaxBetv99 as MaxBet, @MaxMaxBetv99 as MaxMaxBet	 
) as b on sports.sporttype = b.sporttype
where MaxMaxBet>0 and MaxBet>0 and MaxBet>MaxMaxBet
if @ErrType <>''
BEGIN
	SELECT
		@ErrMsg =	'Sorry, max bet must be equal to or less than Master/Agent max bet ('+@ErrType+').',
		@ErrCode = 107
	return
END

select @ErrType = ''
select @ErrType = @ErrType + sportname + ', '
from sports with (NOLOCK) inner join
(
				select 1 as sporttype, @MaxPerMatch as MaxPerMatch, @MaxMaxPerMatch as MaxMaxPerMatch
	union all	select 2 as sporttype, @MaxPerMatchv2 as MaxPerMatch, @MaxMaxPerMatchv2 as MaxMaxPerMatch
	union all	select 3 as sporttype, @MaxPerMatchv3 as MaxPerMatch, @MaxMaxPerMatchv3 as MaxMaxPerMatch
	union all	select 5 as sporttype, @MaxPerMatchv5 as MaxPerMatch, @MaxMaxPerMatchv5 as MaxMaxPerMatch
	union all	select 8 as sporttype, @MaxPerMatchv8 as MaxPerMatch, @MaxMaxPerMatchv8 as MaxMaxPerMatch
	union all	select 10 as sporttype, @MaxPerMatchv10 as MaxPerMatch, @MaxMaxPerMatchv10 as MaxMaxPerMatch
	union all	select 11 as sporttype, @MaxPerMatchv11 as MaxPerMatch, @MaxMaxPerMatchv11 as MaxMaxPerMatch
	--v201
	union all	select 201 as sporttype, @MaxPerMatchv201 as MaxPerMatch, @MaxMaxPerMatchv201 as MaxMaxPerMatch	
	--v151
	union all	select 151 as sporttype, @MaxPerMatchv151 as MaxPerMatch, @MaxMaxPerMatchv151 as MaxMaxPerMatch	

	union all	select 99 as sporttype, @MaxPerMatchv99 as MaxPerMatch, @MaxMaxPerMatchv99 as MaxMaxPerMatch	 
) as b on sports.sporttype = b.sporttype
where MaxMaxPerMatch>0 and MaxPerMatch>0 and MaxPerMatch>MaxMaxPerMatch
if @ErrType <>''
BEGIN
	SELECT
		@ErrMsg = 'Sorry, Max Per Match must be equal to or less than Master/Agent Max Per Match ('+@ErrType+').',
		@ErrCode = 107
	return
END

select @pwdexpiry = dateadd(dd, 30, getdate())

if @Aclosed = 1
BEGIN
	SELECT	
		@ErrMsg = 'Your account was closed. Cannot add member.', 
		@ErrCode=211
	return
END

--check suspended of Agent 
if @Asuspended =1 and @suspendedFlag is null
BEGIN
	set @suspended =1
END

--Insert general data 
EXEC dbo.Acc_CustomerInsUserInfo 
	@custid = @custid OUTPUT,
	@firstname = @firstname,
	@lastname = @lastname,
	@creator = @recommendForPT,
	@username = @username,
	@userpwd = @Password,
	@pwdexpiry = @pwdexpiry,
	@currency = @currency,
	@site = @site,
	@srecommend = @srecommend,
	@mrecommend = @mrecommend,
	@recommend = @recommend,
	@roleid = 1,
	@phone = '',
	@mobilephone = '',
	@email = '',
	@fax = '',
	@address = '',
	@city = '',
	@state = '',
	@country = '',
	@postal = '',
	@TransferOption = null,
	@suspended = @suspended,
	@DisableHorseRacing = 0,
	@matchlimit = @matchlimit,
	@virtualmultiplier = @virtualmultiplier,
	@DisableFinancial = 0,
	
	@MaxPerMatch = @MaxPerMatch,
	@MaxPerMatchv2 = @MaxPerMatchv2,
	@MaxPerMatchv3 = @MaxPerMatchv3,
	@MaxPerMatchv5 = @MaxPerMatchv5,
	@MaxPerMatchv8 = @MaxPerMatchv8,
	@MaxPerMatchv10 = @MaxPerMatchv10,
	@MaxPerMatchv11 = @MaxPerMatchv11,
	@MaxPerMatchv201 = @MaxPerMatchv201,
	@MaxPerMatchv151 = @MaxPerMatchv151,
	@MaxPerMatchv99 = @MaxPerMatchv99,
	
	@credit = 0,
	@answer = '',
	@IP = '',
	@TransferOption_dec = null,
	@Language = 'E',
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg = @ErrMsg OUTPUT
IF @ErrCode <> 0
	return

--Hardcode for FI
Select @v201apositiontaking_2 = 0,
	@v201mpositiontaking_2 = 0,
	@v201apositiontaking_3 = 0,
	@v201mpositiontaking_3 = 0
	
--print @v2mpositiontaking_20
INSERT INTO [dbo].[custsetting]([custid], [bettype], [sporttype], [apositiontaking], [mpositiontaking], [spositiontaking], [alivepositiontaking], [mlivepositiontaking], [slivepositiontaking], [playerdiscount], [discount], [adiscount], [sdiscount], [groupa], [groupb], [groupc], [groupd], [groupe], [groupf], MinBet, MaxBet, autopositiontaking, autolivepositiontaking, isautopositiontaking, isautolivepositiontaking)
select @custid, 1, 1, @apositiontaking_1, @mpositiontaking_1,@spositiontaking_1, @alivepositiontaking_1, @mlivepositiontaking_1, @slivepositiontaking_1, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0,@MinBet, @MaxBet, 0, 0, 0, 0
UNION ALL
select @custid, 3, 1, @apositiontaking_3, @mpositiontaking_3, @spositiontaking_3, @alivepositiontaking_3, @mlivepositiontaking_3, @slivepositiontaking_3, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0,@MinBet, @MaxBet, 0, 0, 0, 0
UNION ALL
select @custid, 7, 1, @apositiontaking_7, @mpositiontaking_7, @spositiontaking_7, @alivepositiontaking_7, @mlivepositiontaking_7, @slivepositiontaking_7, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0,@MinBet, @MaxBet, 0, 0, 0, 0
UNION ALL
select @custid, 8, 1, @apositiontaking_8, @mpositiontaking_8, @spositiontaking_8, @alivepositiontaking_8, @mlivepositiontaking_8, @slivepositiontaking_8, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0,@MinBet, @MaxBet, 0, 0, 0, 0
UNION ALL
select @custid, 2, 1, @apositiontaking_2, @mpositiontaking_2, @spositiontaking_2, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0,@MinBet, @MaxBet, 0, 0, 0, 0
UNION ALL
select @custid, 4, 1, @apositiontaking_4, @mpositiontaking_4, @spositiontaking_4, 0, 0, 0, @playerdiscountcs, @discountcs, @adiscountcs, @sdiscountcs, 0, 0, 0, 0, 0, 0,@MinBet, @MaxBet, 0, 0, 0, 0
UNION ALL
select @custid, 5, 1, @apositiontaking_5, @mpositiontaking_5, @spositiontaking_5, 0, 0, 0, @playerdiscount1x2, @discount1x2, @adiscount1x2, @sdiscount1x2, 0, 0, 0, 0, 0, 0,@MinBet, @MaxBet, 0, 0, 0, 0
UNION ALL
select @custid, 6, 1, @apositiontaking_6, @mpositiontaking_6, @spositiontaking_6, 0, 0, 0, @playerdiscountcs, @discountcs, @adiscountcs, @sdiscountcs, 0, 0, 0, 0, 0, 0,@MinBet, @MaxBet, 0, 0, 0, 0
UNION ALL
select @custid, 9, 1, @apositiontaking_9, @mpositiontaking_9, @spositiontaking_9, 0, 0, 0, @playerdiscountcs, @discountcs, @adiscountcs, @sdiscountcs, 0, 0, 0, 0, 0, 0,@MinBet, @MaxBet, 0, 0, 0, 0
UNION ALL
select @custid, 10, 1, @apositiontaking_10, @mpositiontaking_10, @spositiontaking_10, 0, 0, 0, @playerdiscountcs, @discountcs, @adiscountcs, @sdiscountcs, 0, 0, 0, 0, 0, 0,@MinBet, @MaxBet, 0, 0, 0, 0

UNION ALL
select @custid, 1, 2, @v2apositiontaking_1, @v2mpositiontaking_1, @v2spositiontaking_1, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv2, @MaxBetv2, 0, 0, 0, 0
UNION ALL
select @custid, 2, 2, @v2apositiontaking_2, @v2mpositiontaking_2, @v2spositiontaking_2, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv2, @MaxBetv2, 0, 0, 0, 0
UNION ALL
select @custid, 3, 2, @v2apositiontaking_3, @v2mpositiontaking_3, @v2spositiontaking_3, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv2, @MaxBetv2, 0, 0, 0, 0
UNION ALL
select @custid, 7, 2, @v2apositiontaking_7, @v2mpositiontaking_7, @v2spositiontaking_7, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv2, @MaxBetv2, 0, 0, 0, 0
UNION ALL
select @custid, 8, 2, @v2apositiontaking_8, @v2mpositiontaking_8, @v2spositiontaking_8, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv2, @MaxBetv2, 0, 0, 0, 0
UNION ALL
select @custid, 9, 2, @v2apositiontaking_9, @v2mpositiontaking_9, @v2spositiontaking_9, 0, 0, 0, @playerdiscountcs, @discountcs, @adiscountcs, @sdiscountcs, 0, 0, 0, 0, 0, 0, @MinBetv2, @MaxBetv2, 0, 0, 0, 0
UNION ALL
select @custid, 20, 2, @v2apositiontaking_20, @v2mpositiontaking_20, @v2spositiontaking_20, 0, 0, 0, @playerdiscountcs, @discountcs, @adiscountcs, @sdiscountcs, 0, 0, 0, 0, 0, 0, @MinBetv2, @MaxBetv2, 0, 0, 0, 0

UNION ALL
select @custid, 1, 3, @v3apositiontaking_1, @v3mpositiontaking_1, @v3spositiontaking_1, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv3, @MaxBetv3, 0, 0, 0, 0
UNION ALL
select @custid, 2, 3, @v3apositiontaking_2, @v3mpositiontaking_2, @v3spositiontaking_2, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv3, @MaxBetv3, 0, 0, 0, 0
UNION ALL
select @custid, 3, 3, @v3apositiontaking_3, @v3mpositiontaking_3, @v3spositiontaking_3, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv3, @MaxBetv3, 0, 0, 0, 0
UNION ALL
select @custid, 20, 3, @v3apositiontaking_20, @v3mpositiontaking_20, @v3spositiontaking_20, 0, 0, 0, @playerdiscountcs, @discountcs, @adiscountcs, @sdiscountcs, 0, 0, 0, 0, 0, 0, @MinBetv3, @MaxBetv3, 0, 0, 0, 0

UNION ALL
select @custid, 1, 5, @v5apositiontaking_1, @v5mpositiontaking_1, @v5spositiontaking_1, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv5, @MaxBetv5, 0, 0, 0, 0
UNION ALL
select @custid, 2, 5, @v5apositiontaking_2, @v5mpositiontaking_2, @v5spositiontaking_2, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv5, @MaxBetv5, 0, 0, 0, 0
UNION ALL
select @custid, 3, 5, @v5apositiontaking_3, @v5mpositiontaking_3, @v5spositiontaking_3, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv5, @MaxBetv5, 0, 0, 0, 0
UNION ALL
select @custid, 20, 5, @v5apositiontaking_20, @v5mpositiontaking_20, @v5spositiontaking_20, 0, 0, 0, @playerdiscountcs, @discountcs, @adiscountcs, @sdiscountcs, 0, 0, 0, 0, 0, 0, @MinBetv5, @MaxBetv5, 0, 0, 0, 0

UNION ALL
select @custid, 1, 8, @v8apositiontaking_1, @v8mpositiontaking_1, @v8spositiontaking_1, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv8, @MaxBetv8, 0, 0, 0, 0
UNION ALL
select @custid, 3, 8, @v8apositiontaking_3, @v8mpositiontaking_3, @v8spositiontaking_3, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv8, @MaxBetv8, 0, 0, 0, 0
UNION ALL
select @custid, 20, 8, @v8apositiontaking_20, @v8mpositiontaking_20, @v8spositiontaking_20, 0, 0, 0, @playerdiscountcs, @discountcs, @adiscountcs, @sdiscountcs, 0, 0, 0, 0, 0, 0, @MinBetv8, @MaxBetv8, 0, 0, 0, 0

UNION ALL
select @custid, 1, 10, @v10apositiontaking_1, @v10mpositiontaking_1, @v10spositiontaking_1, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv10, @MaxBetv10, 0, 0, 0, 0
UNION ALL
select @custid, 2, 10, @v10apositiontaking_2, @v10mpositiontaking_2, @v10spositiontaking_2, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv10, @MaxBetv10, 0, 0, 0, 0
UNION ALL
select @custid, 3, 10, @v10apositiontaking_3, @v10mpositiontaking_3, @v10spositiontaking_3, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv10, @MaxBetv10, 0, 0, 0, 0
UNION ALL
select @custid, 20, 10, @v10apositiontaking_20, @v10mpositiontaking_20, @v10spositiontaking_20, 0, 0, 0, @playerdiscountcs, @discountcs, @adiscountcs, @sdiscountcs, 0, 0, 0, 0, 0, 0, @MinBetv10, @MaxBetv10, 0, 0, 0, 0

UNION ALL
select @custid, 1, 11, @v11apositiontaking_1, @v11mpositiontaking_1, @v11spositiontaking_1, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv11, @MaxBetv11, 0, 0, 0, 0
UNION ALL
select @custid, 20, 11, @v11apositiontaking_20, @v11mpositiontaking_20, @v11spositiontaking_20, 0, 0, 0, @playerdiscountcs, @discountcs, @adiscountcs, @sdiscountcs, 0, 0, 0, 0, 0, 0, @MinBetv11, @MaxBetv11, 0, 0, 0, 0

UNION ALL
select @custid, 1, 99, @v99apositiontaking_1, @v99mpositiontaking_1, @v99spositiontaking_1, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv99, @MaxBetv99, 0, 0, 0, 0
UNION ALL
select @custid, 2, 99, @v99apositiontaking_2, @v99mpositiontaking_2, @v99spositiontaking_2, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv99, @MaxBetv99, 0, 0, 0, 0
UNION ALL
select @custid, 3, 99, @v99apositiontaking_3, @v99mpositiontaking_3, @v99spositiontaking_3, 0, 0, 0, @playerdiscount, @discount, @adiscount, @sdiscount, 0, 0, 0, 0, 0, 0, @MinBetv99, @MaxBetv99, 0, 0, 0, 0
UNION ALL
select @custid, 20, 99, @v99apositiontaking_20, @v99mpositiontaking_20, @v99spositiontaking_20, 0, 0, 0, @playerdiscountcs, @discountcs, @adiscountcs, @sdiscountcs, 0, 0, 0, 0, 0, 0, @MinBetv99, @MaxBetv99, 0, 0, 0, 0

--Insert into custsetting3rd

INSERT INTO [bodb02].[dbo].[CustSetting3rd]
           ([custid]
           ,[bettype]
           ,[sporttype]
           ,[apositiontaking]
           ,[mpositiontaking]
           ,[spositiontaking]
           ,[playerdiscount]
           ,[discount]
           ,[adiscount]
           ,[sdiscount]
           ,[minbet]
           ,[maxbet]
           ,[autopositiontaking]
           ,[isautopositiontaking]
           ,[autompositiontaking]
           ,[isautompositiontaking])
select @custid, 2, 201, @v201apositiontaking_2, @v201mpositiontaking_2, @v201spositiontaking_2, @v201playerdiscount, @v201discount, @v201adiscount, @v201sdiscount, @MinBetv201, @MaxBetv201, 0, 0, 0, 0
UNION ALL
select @custid, 3, 201, @v201apositiontaking_3, @v201mpositiontaking_3, @v201spositiontaking_3,  @v201playerdiscount, @v201discount, @v201adiscount, @v201sdiscount, @MinBetv201, @MaxBetv201, 0, 0, 0, 0

--v151
UNION ALL
select @custid, 31, 151, @v151apositiontaking_31, @v151mpositiontaking_31, @v151spositiontaking_31, @v151playerdiscount_31, @v151discount_31, @v151adiscount_31, @v151sdiscount_31, @MinBetv151, @MaxBetv151, 0, 0, 0, 0
UNION ALL
select @custid, 32, 151, @v151apositiontaking_32, @v151mpositiontaking_32, @v151spositiontaking_32, @v151playerdiscount_31, @v151discount_31, @v151adiscount_31, @v151sdiscount_31, @MinBetv151, @MaxBetv151, 0, 0, 0, 0
UNION ALL
select @custid, 41, 151, @v151apositiontaking_41, @v151mpositiontaking_41, @v151spositiontaking_41, @v151playerdiscount_41, @v151discount_41, @v151adiscount_41, @v151sdiscount_41, @MinBetv151, @MaxBetv151, 0, 0, 0, 0
UNION ALL
select @custid, 42, 151, @v151apositiontaking_42, @v151mpositiontaking_42, @v151spositiontaking_42, @v151playerdiscount_41, @v151discount_41, @v151adiscount_41, @v151sdiscount_41, @MinBetv151, @MaxBetv151, 0, 0, 0, 0

           

if (not exists (select 1 from custsetting with (NOLOCK) where custid = @custid) or not exists (select 1 from custsetting3rd with (NOLOCK) where custid = @custid)) or @@Error <> 0
BEGIN
	--Error occurs
	SELECT 
		@ErrMsg = 'Add member fail. Please try again',
		@ErrCode=215
	
	-- MANUALLY ROLLBACK
	DELETE CustSetting WHERE CustID = @CustID
	DELETE CustSetting3rd WHERE CustID = @CustID
	EXEC Acc_CustomerInsUserInfo_Rollback @CustID = @CustID
	return
END

	
---------------------------------------------------------------------------------
BEGIN
	Update customer with (ROWLOCK, UPDLOCK) set		
		username2 = @DepositUserName,
		refcode2 = @DepositUserID
	where custID = @custID
	
	if isnull(@AffiliateID,0) > 0
	BEGIN
		Update custinfo with (ROWLOCK, UPDLOCK) set		
			AffiliateID = @AffiliateID
		where custID = @custID
	END
END

IF @AffiliateID is not NULL
EXEC DB052.Affiliate_12BET.dbo.Aff_CustomerInsMember 
	@IbcCustID = @CustID,
	@AffID = @AffiliateID,
	@Username = @DepositUserName,
	@IBCUsername = @Username,	
	@DepositCustID = @DepositUserID,
	@FirstName = @FirstName,
	@LastName = @LastName,
	@Currency = @currency,
	@Recommend = @recommend,
	@Email = @Email


Declare @LogSPData varchar(4000)

Select @LogSPData = '<Dot_Dep_CustomerInsMember_Ag custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'fname="'+ coalesce(cast(@firstname as varchar(100)),space(1)) + '" ' +
'lname="'+ coalesce(cast(@lastname as varchar(100)),space(1)) + '" ' +
'creator="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '" ' +
'username="'+ coalesce(cast(@username as varchar(30)),space(1)) + '" ' +
'Email="'+ coalesce(cast(@Email as varchar(100)),space(1)) + '" ' +
'DepositUserName="'+ coalesce(cast(@DepositUserName as varchar(50)),space(1)) + '" ' +
'DepositUserID="'+ coalesce(cast(@DepositUserID as varchar(50)),space(1)) + '" ' +
'Password="'+ coalesce(cast(@Password as varchar(40)),space(1)) + '" ' +
'OddsType="'+ coalesce(cast(@OddsType as varchar(5)),space(1)) + '" ' +
'AgentID="'+ coalesce(cast(@AgentID as varchar(50)),space(1)) + '" ' +
'AffiliateID="'+ coalesce(cast(@AffiliateID as varchar(50)),space(1)) + '" ' +
'BonusCode="'+ coalesce(cast(@BonusCode as varchar(20)),space(1)) + '" ' +
'recommend="'+ coalesce(cast(@recommend as varchar(50)),space(1)) + '" ' +
'ugroup="'+ coalesce(cast(@ugroup as varchar(5)),space(1)) + '" ' +
'success="'+ coalesce(cast(@success as varchar(50)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(4000)),space(1)) + '" />'
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @CustID,
	@CustID = @CustID,
	@ActionID = 617,
	@TrackingValue = @LogSPData
	
--Write commission log
Select @LogSPData = '<Dot_Dep_CustomerInsMember_Ag custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'discount="'+ coalesce(cast(@discount as varchar(50)),space(1)) + '" />'
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @CustID,
	@CustID = @CustID,
	@ActionID = 216,
	@TrackingValue = @LogSPData
	
--Write betsetting log
Select @LogSPData = '<Dot_Dep_CustomerInsMember_Ag custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'MinBet="'+ coalesce(cast(@MinBet as varchar(50)),space(1)) + '" ' +
'MaxBet="'+ coalesce(cast(@MaxBet as varchar(50)),space(1)) + '" ' +
'MaxPerMatch="'+ coalesce(cast(@MaxPerMatch as varchar(50)),space(1)) + '" />'
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @CustID,
	@CustID = @CustID,
	@ActionID = 315,
	@TrackingValue = @LogSPData
	
--Write PT log
Select @LogSPData = '<Dot_Dep_CustomerInsMember_Ag custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'Agent PT="'+ coalesce(cast(@apositiontaking_1 as varchar(50)),space(1)) + '" />'
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @CustID,
	@CustID = @CustID,
	@ActionID = 422,
	@TrackingValue = @LogSPData

--Write Statuses log	
Select @LogSPData = '<Dot_Dep_CustomerInsMember_Ag custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'suspended="'+ coalesce(cast(@suspended as varchar(50)),space(1)) + '" ' +
'DisableHorseRacing="'+ coalesce(cast(@DisableHorseRacing as varchar(1)),space(1)) + '" ' +
'DisableFinancial="'+ coalesce(cast(@DisableFinancial as varchar(1)),space(1)) + '" />'
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @CustID,
	@CustID = @CustID,
	@ActionID = 1118,
	@TrackingValue = @LogSPData


GO
GRANT EXECUTE ON [dbo].[Dot_Dep_CustomerInsMember_Ag] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Dot_Dep_CustomerInsMember_Ag] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Dot_Dep_CustomerInsMember_Ag] TO [Dot_Member]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Dep_CustomerInsMember_Ag] TO [ITTim]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Dep_CustomerInsMember_Ag] TO [ITVivi]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Dep_CustomerInsMember_Ag] TO [vnteam]