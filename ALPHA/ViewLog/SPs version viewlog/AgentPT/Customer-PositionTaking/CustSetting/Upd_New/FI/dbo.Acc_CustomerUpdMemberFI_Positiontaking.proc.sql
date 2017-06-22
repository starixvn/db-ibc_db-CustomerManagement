ALTER PROCEDURE [dbo].[Acc_CustomerUpdMemberFI_PositionTaking]
	@custid INT,--memberid		
	--v201
	@v201apositiontaking_2 SMALLMONEY,
	@v201apositiontaking_3 SMALLMONEY,
	
	@UpdateMultiple BIT = 0,
	--v201
	@UpdatePositiontakingv201 BIT = 1,
	@UserID INT,	
	@IP varchar(15)='',	
	@Language VARCHAR(2)= 'E',	
	@SubAccID INT = 0, --Sub-AccountID	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20090415@Phuc
Task : Update FI's Member Position Taking
DB: DB02.bodb02
Original:

Revisions:
	- 20090630@Phuc: auto master PT on member level.
					Write log subaccname instead of subaccid.
	- 20090917@Phuc: write log into DBLOG.
	- 20091201@Kiwi: Move custsetting & custoverride to the separated tables (CustSetting3rd & CustOverride3rd).
	- 20100112@Kiwi: Amend to write log in xml format.
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON


DECLARE 	
	@Recommend INT,	
	@MRecommend INT,
	@SRecommend INT,
	@UserName nvarchar(20),
	@ErrAcc varchar(4000), @ErrType varchar(4000),
	
	--m1
	@v201mpositiontaking_2 SMALLMONEY,
	@v201mpositiontaking_3 SMALLMONEY,

	--m3
	@v201mapositiontaking_2_max SMALLMONEY,
	@v201mapositiontaking_3_max SMALLMONEY,

	--old_a1
	@old_v201apositiontaking_2 SMALLMONEY,
	@old_v201apositiontaking_3 SMALLMONEY,

	--s1
	@v201spositiontaking_2 SMALLMONEY,
	@v201spositiontaking_3 SMALLMONEY,

	--u3
	@auto_v201spositiontaking_2 SMALLMONEY,
	@auto_v201spositiontaking_3 SMALLMONEY,

	--s4
	@max_v201spositiontaking_2 SMALLMONEY,
	@max_v201spositiontaking_3 SMALLMONEY,

	--u1
	@auto_v201spositiontaking_mem_2 SMALLMONEY,
	@auto_v201spositiontaking_mem_3 SMALLMONEY,

	--i3
	@isauto_v201spositiontaking_2 BIT,
	@isauto_v201spositiontaking_3 BIT,
	--i1
	@isauto_v201spositiontaking_mem_2 BIT,
	@isauto_v201spositiontaking_mem_3 BIT,

	--um2
	@auto_v201mpositiontaking_2 SMALLMONEY,
	@auto_v201mpositiontaking_3 SMALLMONEY,

	--im2
	@isauto_v201mpositiontaking_2 BIT,
	@isauto_v201mpositiontaking_3 BIT,
	--um1
	@auto_v201mpositiontaking_mem_2 SMALLMONEY,
	@auto_v201mpositiontaking_mem_3 SMALLMONEY,

	--im1
	@isauto_v201mpositiontaking_mem_2 BIT,
	@isauto_v201mpositiontaking_mem_3 BIT

SELECT 	
	@Recommend = recommend,
	@MRecommend = mrecommend,
	@SRecommend = srecommend,	
	@UserName = username
FROM 
	custinfo WITH (NOLOCK)
WHERE CustID = @CustID

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--v201
if @v201apositiontaking_2  <0
	or @v201apositiontaking_2  >0.9
	or	@v201apositiontaking_3  <0
	or @v201apositiontaking_3  >0.9
BEGIN
	select @ErrCode = 8
	Select @ErrMsg = 	@UserName + ': '+
		case @Language 
						when 'E' then 'Wrong position taking.'
						when 'CS' then N'占成数不正确.'
						when 'CT' then N'佔成數不正確.'
						when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง.'
						when 'J' then N'Wrong position taking.'
						when 'KO' then N'거래 조건이 잘못 되었습니다.'
						else N'Wrong position taking.'
				end
	return
END

--check n2<=a1<=l2 - Vinh
select @ErrType = ''
select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10)) + '<br>'
from CustOverride3rd as co with (NOLOCK) inner join
	(
					select 2 as bettype, 201 as sporttype, @v201apositiontaking_2 as apositiontaking
		union all	select 3 as bettype, 201 as sporttype, @v201apositiontaking_3 as apositiontaking
	) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
	inner join sports with (nolock) on b.sporttype = sports.sporttype
	inner join bettype with (nolock) on b.bettype = bettype.typeid
where co.custid = @recommend and (( (b.apositiontaking>co.maxpositiontaking or b.apositiontaking<co.minpositiontaking))
)
if @ErrType <>''
BEGIN
	select @ErrCode = 9
	Select @ErrMsg = 	@UserName + ': '+
		case @Language 
						when 'E' then 'Wrong position taking (min/max set by company).<br>'+@ErrType
						when 'CS' then N'占成数不正确(公司设给最低/高占成).<br>'+@ErrType
						when 'CT' then N'佔成數不正確(公司設給最低/高佔成).<br>'+@ErrType
						when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด หรือ ต่ำสุด อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
						when 'J' then N'Wrong position taking (min/max set by company).<br>'+@ErrType
						when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값).<br>'+@ErrType
						else N'Wrong position taking (min/max set by company).<br>'+@ErrType
				end
	return
END

--check a1<=a4 - Vinh
select @ErrType = ''
select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.apositiontaking) as varchar(10))+ '<br>'
from custinfo as c with (NOLOCK) inner join CustSetting3rd as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
	(
				 	select 2 as bettype, 201 as sporttype, @v201apositiontaking_2 as apositiontaking
		union all 	select 3 as bettype, 201 as sporttype, @v201apositiontaking_3 as apositiontaking
	) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
	inner join sports with (nolock) on b.sporttype = sports.sporttype
	inner join bettype with (nolock) on b.bettype = bettype.typeid
where c.custid = @recommend and (b.apositiontaking>scs.apositiontaking )
if @ErrType <>''
BEGIN
	select @ErrCode = 10
	Select @ErrMsg = 	@UserName + ': '+
		case @Language 
						when 'E' then 'Wrong position taking (max set by company).<br>'+@ErrType
						when 'CS' then N'占成数不正确(公司设给最高占成).<br>'+@ErrType
						when 'CT' then N'佔成數不正確(公司設給最高佔成).<br>'+@ErrType
						when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด  อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
						when 'J' then N'Wrong position taking (max set by company).<br>'+@ErrType
						when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최대 값).<br>'+@ErrType
						else N'Wrong position taking (max set by company).<br>'+@ErrType
				end
	return
END


--------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--s1,u1,i1,im1,um1 
--v201
SELECT @v201spositiontaking_2 = spositiontaking, @v201mpositiontaking_2 = mpositiontaking, @auto_v201spositiontaking_mem_2 = autopositiontaking, @isauto_v201spositiontaking_mem_2 = isautopositiontaking, @old_v201apositiontaking_2 = apositiontaking, @auto_v201mpositiontaking_mem_2 = autompositiontaking, @isauto_v201mpositiontaking_mem_2 = isautompositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=201 
SELECT @v201spositiontaking_3 = spositiontaking, @v201mpositiontaking_3 = mpositiontaking, @auto_v201spositiontaking_mem_3 = autopositiontaking, @isauto_v201spositiontaking_mem_3 = isautopositiontaking, @old_v201apositiontaking_3 = apositiontaking, @auto_v201mpositiontaking_mem_3 = autompositiontaking, @isauto_v201mpositiontaking_mem_3 = isautompositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=201

------------------------------------------------------------------------------------------------------------------------------
--Auto Master PT
------------------------------------------------------------------------------------------------------------------------------
--um2,im2
--v201
select @auto_v201mpositiontaking_2 = autompositiontaking, @isauto_v201mpositiontaking_2 = isautompositiontaking from CustSetting3rd with (NOLOCK) where custid = @recommend and bettype=2 and sporttype=201
select @auto_v201mpositiontaking_3 = autompositiontaking, @isauto_v201mpositiontaking_3 = isautompositiontaking from CustSetting3rd with (NOLOCK) where custid = @recommend and bettype=3 and sporttype=201
------------------------------------------------------------------------------------------------------------------------------

--s3,m3,u3,i3
--v201
SELECT @v201mapositiontaking_2_max = mpositiontaking, @auto_v201spositiontaking_2 = autopositiontaking, @isauto_v201spositiontaking_2 = isautopositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=201
SELECT @v201mapositiontaking_3_max = mpositiontaking, @auto_v201spositiontaking_3 = autopositiontaking, @isauto_v201spositiontaking_3 = isautopositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=201

--s4
--v201
SELECT @max_v201spositiontaking_2 = spositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND bettype=2 AND sporttype=201
SELECT @max_v201spositiontaking_3 = spositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND bettype=3 AND sporttype=201

---------------------------------------------------------------------------------------------------------------------------------------------
--CHOOSE MEMBER AUTOPOSITIONTAKING IF MEMBER IS SET AUTO (regardless of the setting in master account)
SELECT 
	--v201
	@auto_v201spositiontaking_2 = CASE WHEN @isauto_v201spositiontaking_mem_2>0 THEN @auto_v201spositiontaking_mem_2 ELSE @auto_v201spositiontaking_2 END,
	@auto_v201spositiontaking_3 = CASE WHEN @isauto_v201spositiontaking_mem_3>0 THEN @auto_v201spositiontaking_mem_3 ELSE @auto_v201spositiontaking_3 END,
	--v201
	@isauto_v201spositiontaking_2 = CASE WHEN @isauto_v201spositiontaking_mem_2>0 THEN @isauto_v201spositiontaking_mem_2 ELSE @isauto_v201spositiontaking_2 END,
	@isauto_v201spositiontaking_3 = CASE WHEN @isauto_v201spositiontaking_mem_3>0 THEN @isauto_v201spositiontaking_mem_3 ELSE @isauto_v201spositiontaking_3 END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--um=im1>0?um1:um2
SELECT 
	@auto_v201mpositiontaking_2 = CASE WHEN @isauto_v201mpositiontaking_mem_2>0 THEN @auto_v201mpositiontaking_mem_2 ELSE @auto_v201mpositiontaking_2 END,
	@auto_v201mpositiontaking_3 = CASE WHEN @isauto_v201mpositiontaking_mem_3>0 THEN @auto_v201mpositiontaking_mem_3 ELSE @auto_v201mpositiontaking_3 END,
--im=im1>0?im1:im2
	@isauto_v201mpositiontaking_2 = CASE WHEN @isauto_v201mpositiontaking_mem_2>0 THEN @isauto_v201mpositiontaking_mem_2 ELSE @isauto_v201mpositiontaking_2 END,
	@isauto_v201mpositiontaking_3 = CASE WHEN @isauto_v201mpositiontaking_mem_3>0 THEN @isauto_v201mpositiontaking_mem_3 ELSE @isauto_v201mpositiontaking_3 END


--a1=min(a1,m3)
SELECT 
	--v201
	@v201apositiontaking_2 = CASE WHEN @v201apositiontaking_2>@v201mapositiontaking_2_max THEN @v201mapositiontaking_2_max ELSE @v201apositiontaking_2 END,
	@v201apositiontaking_3 = CASE WHEN @v201apositiontaking_3>@v201mapositiontaking_3_max THEN @v201mapositiontaking_3_max ELSE @v201apositiontaking_3 END


--a1=if(!im)if(m1+a1>m3,m3-m1)
SELECT 
	--v201
	@v201apositiontaking_2 = CASE WHEN @isauto_v201mpositiontaking_2 > 0 THEN @v201apositiontaking_2 ELSE CASE WHEN @v201apositiontaking_2+@v201mpositiontaking_2>@v201mapositiontaking_2_max THEN @v201mapositiontaking_2_max-@v201mpositiontaking_2 ELSE @v201apositiontaking_2 END END,
	@v201apositiontaking_3 = CASE WHEN @isauto_v201mpositiontaking_3 > 0 THEN @v201apositiontaking_3 ELSE CASE WHEN @v201apositiontaking_3+@v201mpositiontaking_3>@v201mapositiontaking_3_max THEN @v201mapositiontaking_3_max-@v201mpositiontaking_3 ELSE @v201apositiontaking_3 END END


SELECT 
	--v201
	@v201apositiontaking_2 = CASE WHEN @v201apositiontaking_2<0 THEN 0 ELSE @v201apositiontaking_2 END,
	@v201apositiontaking_3 = CASE WHEN @v201apositiontaking_3<0 THEN 0 ELSE @v201apositiontaking_3 END
	

---------------------------------------------------------------------------------------------------------------------------------------------
----------------***Use Master Auto Position Taking***----------------------------------
--use @auto_mpt at agent
--@max_mpt = @maxdownlinepos + mpt ; pt: positiontaking
--if um = 0 then m1 = m2
--else	if um < m3 - a1 then m1 = um
--		else m1 = m3 - a1

--m1=iif(im,min(m3-a1,um),m1)
select @v201mpositiontaking_2 = case when isnull(@isauto_v201mpositiontaking_2, 0)=0 then @v201mpositiontaking_2 else case when @auto_v201mpositiontaking_2 < @v201mapositiontaking_2_max - @v201apositiontaking_2 then @auto_v201mpositiontaking_2 else @v201mapositiontaking_2_max - @v201apositiontaking_2 end end
select @v201mpositiontaking_3 = case when isnull(@isauto_v201mpositiontaking_3, 0)=0 then @v201mpositiontaking_3 else case when @auto_v201mpositiontaking_3 < @v201mapositiontaking_3_max - @v201apositiontaking_3 then @auto_v201mpositiontaking_3 else @v201mapositiontaking_3_max - @v201apositiontaking_3 end end

--------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------------

----------------***Use Auto Position Taking***----------------------------------
--@max_spt = @maxdownlinepos + spt ; pt: positiontaking
--if @auto_spt = 0 then @spt = @spt  -- Auto pt is not used
--else	if @auto_spt < @max_spt - @mpt - @apt then @spt = @auto_spt
--		else @spt = @max_spt - @mpt - @apt
--v201
SELECT @v201spositiontaking_2 = CASE WHEN ISNULL(@isauto_v201spositiontaking_2, 0)<=0 THEN @v201spositiontaking_2 ELSE CASE WHEN @auto_v201spositiontaking_2 < @max_v201spositiontaking_2 - @v201mpositiontaking_2 - @v201apositiontaking_2 THEN @auto_v201spositiontaking_2 ELSE @max_v201spositiontaking_2 - @v201mpositiontaking_2 - @v201apositiontaking_2 END END
SELECT @v201spositiontaking_3 = CASE WHEN ISNULL(@isauto_v201spositiontaking_3, 0)<=0 THEN @v201spositiontaking_3 ELSE CASE WHEN @auto_v201spositiontaking_3 < @max_v201spositiontaking_3 - @v201mpositiontaking_3 - @v201apositiontaking_3 THEN @auto_v201spositiontaking_3 ELSE @max_v201spositiontaking_3 - @v201mpositiontaking_3 - @v201apositiontaking_3 END END
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--max_spositiontaking = if(i1||i3)s4:s4-m1-a1
--v201
SELECT @max_v201spositiontaking_2 = CASE WHEN ISNULL(@isauto_v201spositiontaking_2, 0)>0 THEN @max_v201spositiontaking_2 ELSE @max_v201spositiontaking_2 - @v201mpositiontaking_2 - @v201apositiontaking_2 END
SELECT @max_v201spositiontaking_3 = CASE WHEN ISNULL(@isauto_v201spositiontaking_3, 0)>0 THEN @max_v201spositiontaking_3 ELSE @max_v201spositiontaking_3 - @v201mpositiontaking_3 - @v201apositiontaking_3 END

--//REPLACING CHECK MAX SUPER PT ON MEMBER

--s1=min(s1,max_spositiontaking)
--v201
SELECT @v201spositiontaking_2 = CASE WHEN @v201spositiontaking_2 > @max_v201spositiontaking_2 THEN @max_v201spositiontaking_2 ELSE @v201spositiontaking_2 END
SELECT @v201spositiontaking_3 = CASE WHEN @v201spositiontaking_3 > @max_v201spositiontaking_3 THEN @max_v201spositiontaking_3 ELSE @v201spositiontaking_3 END


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------
BEGIN TRANSACTION
---------------------------------------

UPDATE CustSetting3rd WITH (ROWLOCK, UPDLOCK)
SET
	apositiontaking = CASE bettype WHEN 3 THEN @v201apositiontaking_3 WHEN 2 THEN @v201apositiontaking_2 ELSE apositiontaking END,	
	--Auto Master PT
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	mpositiontaking = CASE bettype WHEN 3 THEN @v201mpositiontaking_3 WHEN 2 THEN @v201mpositiontaking_2 ELSE mpositiontaking END,
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	spositiontaking = CASE bettype WHEN 3 THEN @v201spositiontaking_3 WHEN 2 THEN @v201spositiontaking_2 ELSE spositiontaking END
WHERE custid=@custid and sporttype = 201

EXEC dbo.Acc_CustomerUpdMemberFI_MinMaxPositiontaking @custid = @custid, @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend

COMMIT TRANSACTION

Declare @LogSPData varchar(5000)
	
Select @LogSPData = '<Acc_CustomerUpdMemberFI_PositionTaking><info UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(8000)),space(1)) + '" />' +
'<ag v201apt_2="'+ coalesce(cast(@v201apositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v201apt_3="'+ coalesce(cast(@v201apositiontaking_3 as varchar(50)),space(1)) + '" /></Acc_CustomerUpdMemberFI_PositionTaking>'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 417,
	@TrackingValue = @LogSPData
	
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMemberFI_PositionTaking] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMemberFI_PositionTaking] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMemberFI_PositionTaking] TO [vnteam]
