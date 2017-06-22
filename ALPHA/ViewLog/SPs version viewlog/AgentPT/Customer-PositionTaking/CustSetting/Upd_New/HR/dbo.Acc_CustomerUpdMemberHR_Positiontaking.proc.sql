ALTER PROCEDURE [dbo].[Acc_CustomerUpdMemberHR_PositionTaking]
	@custid INT,--memberid		
	@v151apositiontaking_31 SMALLMONEY,
	@v151apositiontaking_32 SMALLMONEY,
	@v151apositiontaking_41 SMALLMONEY,
	@v151apositiontaking_42 SMALLMONEY,
	
	@UserID INT,	
	@IP varchar(15)='',	
	@Language VARCHAR(2)= 'E',	
	@SubAccID INT = 0, --Sub-AccountID	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20090518@Phuc
Task : Update HR's Member Position Taking
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
	@v151mpositiontaking_31 SMALLMONEY,
	@v151mpositiontaking_32 SMALLMONEY,
	@v151mpositiontaking_41 SMALLMONEY,
	@v151mpositiontaking_42 SMALLMONEY,
	--m3
	@v151mapositiontaking_31_max SMALLMONEY,
	@v151mapositiontaking_32_max SMALLMONEY,
	@v151mapositiontaking_41_max SMALLMONEY,
	@v151mapositiontaking_42_max SMALLMONEY,
	--old_a1
	@old_v151apositiontaking_31 SMALLMONEY,
	@old_v151apositiontaking_32 SMALLMONEY,
	@old_v151apositiontaking_41 SMALLMONEY,
	@old_v151apositiontaking_42 SMALLMONEY,
	--s1
	@v151spositiontaking_31 SMALLMONEY,
	@v151spositiontaking_32 SMALLMONEY,
	@v151spositiontaking_41 SMALLMONEY,
	@v151spositiontaking_42 SMALLMONEY,
	--u3
	@auto_v151spositiontaking_31 SMALLMONEY,
	@auto_v151spositiontaking_32 SMALLMONEY,
	@auto_v151spositiontaking_41 SMALLMONEY,
	@auto_v151spositiontaking_42 SMALLMONEY,
	--s4
	@max_v151spositiontaking_31 SMALLMONEY,
	@max_v151spositiontaking_32 SMALLMONEY,
	@max_v151spositiontaking_41 SMALLMONEY,
	@max_v151spositiontaking_42 SMALLMONEY,
	--u1
	@auto_v151spositiontaking_mem_31 SMALLMONEY,
	@auto_v151spositiontaking_mem_32 SMALLMONEY,
	@auto_v151spositiontaking_mem_41 SMALLMONEY,
	@auto_v151spositiontaking_mem_42 SMALLMONEY,
	--i3
	@isauto_v151spositiontaking_31 BIT,
	@isauto_v151spositiontaking_32 BIT,
	@isauto_v151spositiontaking_41 BIT,
	@isauto_v151spositiontaking_42 BIT,
	--i1
	@isauto_v151spositiontaking_mem_31 BIT,
	@isauto_v151spositiontaking_mem_32 BIT,
	@isauto_v151spositiontaking_mem_41 BIT,
	@isauto_v151spositiontaking_mem_42 BIT,
	--um2
	@auto_v151mpositiontaking_31 SMALLMONEY,
	@auto_v151mpositiontaking_32 SMALLMONEY,
	@auto_v151mpositiontaking_41 SMALLMONEY,
	@auto_v151mpositiontaking_42 SMALLMONEY,
	--im2
	@isauto_v151mpositiontaking_31 BIT,
	@isauto_v151mpositiontaking_32 BIT,
	@isauto_v151mpositiontaking_41 BIT,
	@isauto_v151mpositiontaking_42 BIT,
	--um1
	@auto_v151mpositiontaking_mem_31 SMALLMONEY,
	@auto_v151mpositiontaking_mem_32 SMALLMONEY,
	@auto_v151mpositiontaking_mem_41 SMALLMONEY,
	@auto_v151mpositiontaking_mem_42 SMALLMONEY,
	--im1
	@isauto_v151mpositiontaking_mem_31 BIT,
	@isauto_v151mpositiontaking_mem_32 BIT,
	@isauto_v151mpositiontaking_mem_41 BIT,
	@isauto_v151mpositiontaking_mem_42 BIT
	


SELECT 	
	@Recommend = recommend,
	@MRecommend = mrecommend,
	@SRecommend = srecommend,	
	@UserName = username
FROM 
	custinfo WITH (NOLOCK)
WHERE CustID = @CustID

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
if @v151apositiontaking_31 < 0
	or @v151apositiontaking_31 > 0.5

	or	@v151apositiontaking_32 < 0
	or @v151apositiontaking_32 > 0.5
	 
	or	@v151apositiontaking_41 < 0
	or @v151apositiontaking_41 > 0.5
	
	or	@v151apositiontaking_42 < 0
	or @v151apositiontaking_42 > 0.5
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
select @ErrType = @ErrType + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10)) + '<br>'
from CustOverride3rd as co with (NOLOCK) inner join
	(
					select 31 as bettype, 151 as sporttype, @v151apositiontaking_31 as apositiontaking
		union all	select 32 as bettype, 151 as sporttype, @v151apositiontaking_32 as apositiontaking
		union all	select 41 as bettype, 151 as sporttype, @v151apositiontaking_41 as apositiontaking
		union all	select 42 as bettype, 151 as sporttype, @v151apositiontaking_42 as apositiontaking
	) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
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
select @ErrType = @ErrType + '-'+ typenamee + '-Max: '+ cast((scs.apositiontaking) as varchar(10)) + '<br>'
from custinfo as c with (NOLOCK) inner join CustSetting3rd as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
	(
				 	select 31 as bettype, 151 as sporttype, @v151apositiontaking_31 as apositiontaking
		union all 	select 32 as bettype, 151 as sporttype, @v151apositiontaking_32 as apositiontaking
		union all 	select 41 as bettype, 151 as sporttype, @v151apositiontaking_41 as apositiontaking
		union all 	select 42 as bettype, 151 as sporttype, @v151apositiontaking_42 as apositiontaking
	) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
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

--s1,u1,i1,m1,old_a1 
SELECT @v151spositiontaking_31 = spositiontaking, @v151mpositiontaking_31 = mpositiontaking, @auto_v151spositiontaking_mem_31 = autopositiontaking, @isauto_v151spositiontaking_mem_31 = isautopositiontaking, @old_v151apositiontaking_31 = apositiontaking, @auto_v151mpositiontaking_mem_31 = autompositiontaking, @isauto_v151mpositiontaking_mem_31 = isautompositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=31 AND sporttype=151 
SELECT @v151spositiontaking_32 = spositiontaking, @v151mpositiontaking_32 = mpositiontaking, @auto_v151spositiontaking_mem_32 = autopositiontaking, @isauto_v151spositiontaking_mem_32 = isautopositiontaking, @old_v151apositiontaking_32 = apositiontaking, @auto_v151mpositiontaking_mem_32 = autompositiontaking, @isauto_v151mpositiontaking_mem_32 = isautompositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=32 AND sporttype=151
SELECT @v151spositiontaking_41 = spositiontaking, @v151mpositiontaking_41 = mpositiontaking, @auto_v151spositiontaking_mem_41 = autopositiontaking, @isauto_v151spositiontaking_mem_41 = isautopositiontaking, @old_v151apositiontaking_41 = apositiontaking, @auto_v151mpositiontaking_mem_41 = autompositiontaking, @isauto_v151mpositiontaking_mem_41 = isautompositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=41 AND sporttype=151 
SELECT @v151spositiontaking_42 = spositiontaking, @v151mpositiontaking_42 = mpositiontaking, @auto_v151spositiontaking_mem_42 = autopositiontaking, @isauto_v151spositiontaking_mem_42 = isautopositiontaking, @old_v151apositiontaking_42 = apositiontaking, @auto_v151mpositiontaking_mem_42 = autompositiontaking, @isauto_v151mpositiontaking_mem_42 = isautompositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=42 AND sporttype=151


------------------------------------------------------------------------------------------------------------------------------
--Auto Master PT
------------------------------------------------------------------------------------------------------------------------------
--u2,i2
select @auto_v151mpositiontaking_31 = autompositiontaking, @isauto_v151mpositiontaking_31 = isautompositiontaking from CustSetting3rd with (NOLOCK) where custid = @recommend and bettype=31 and sporttype=151
select @auto_v151mpositiontaking_32 = autompositiontaking, @isauto_v151mpositiontaking_32 = isautompositiontaking from CustSetting3rd with (NOLOCK) where custid = @recommend and bettype=32 and sporttype=151
select @auto_v151mpositiontaking_41 = autompositiontaking, @isauto_v151mpositiontaking_41 = isautompositiontaking from CustSetting3rd with (NOLOCK) where custid = @recommend and bettype=41 and sporttype=151
select @auto_v151mpositiontaking_42 = autompositiontaking, @isauto_v151mpositiontaking_42 = isautompositiontaking from CustSetting3rd with (NOLOCK) where custid = @recommend and bettype=42 and sporttype=151
------------------------------------------------------------------------------------------------------------------------------

--m3,u3,i3
SELECT @v151mapositiontaking_31_max = mpositiontaking, @auto_v151spositiontaking_31 = autopositiontaking, @isauto_v151spositiontaking_31 = isautopositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype = 31 AND sporttype = 151
SELECT @v151mapositiontaking_32_max = mpositiontaking, @auto_v151spositiontaking_32 = autopositiontaking, @isauto_v151spositiontaking_32 = isautopositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype = 32 AND sporttype = 151
SELECT @v151mapositiontaking_41_max = mpositiontaking, @auto_v151spositiontaking_41 = autopositiontaking, @isauto_v151spositiontaking_41 = isautopositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype = 41 AND sporttype = 151
SELECT @v151mapositiontaking_42_max = mpositiontaking, @auto_v151spositiontaking_42 = autopositiontaking, @isauto_v151spositiontaking_42 = isautopositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype = 42 AND sporttype = 151

--s4
SELECT @max_v151spositiontaking_31 = spositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND bettype = 31 AND sporttype = 151
SELECT @max_v151spositiontaking_32 = spositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND bettype = 32 AND sporttype = 151
SELECT @max_v151spositiontaking_41 = spositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND bettype = 41 AND sporttype = 151
SELECT @max_v151spositiontaking_42 = spositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND bettype = 42 AND sporttype = 151

---------------------------------------------------------------------------------------------------------------------------------------------
--CHOOSE MEMBER AUTOPOSITIONTAKING IF MEMBER IS SET AUTO (regardless of the setting in master account)
SELECT 
	@auto_v151spositiontaking_31 = CASE WHEN @isauto_v151spositiontaking_mem_31 > 0 THEN @auto_v151spositiontaking_mem_31 ELSE @auto_v151spositiontaking_31 END,
	@auto_v151spositiontaking_32 = CASE WHEN @isauto_v151spositiontaking_mem_32 > 0 THEN @auto_v151spositiontaking_mem_32 ELSE @auto_v151spositiontaking_32 END,
	@auto_v151spositiontaking_41 = CASE WHEN @isauto_v151spositiontaking_mem_41 > 0 THEN @auto_v151spositiontaking_mem_41 ELSE @auto_v151spositiontaking_41 END,
	@auto_v151spositiontaking_42 = CASE WHEN @isauto_v151spositiontaking_mem_42 > 0 THEN @auto_v151spositiontaking_mem_42 ELSE @auto_v151spositiontaking_42 END,

	@isauto_v151spositiontaking_31 = CASE WHEN @isauto_v151spositiontaking_mem_31 > 0 THEN @isauto_v151spositiontaking_mem_31 ELSE @isauto_v151spositiontaking_31 END,
	@isauto_v151spositiontaking_32 = CASE WHEN @isauto_v151spositiontaking_mem_32 > 0 THEN @isauto_v151spositiontaking_mem_32 ELSE @isauto_v151spositiontaking_32 END,
	@isauto_v151spositiontaking_41 = CASE WHEN @isauto_v151spositiontaking_mem_41 > 0 THEN @isauto_v151spositiontaking_mem_41 ELSE @isauto_v151spositiontaking_41 END,
	@isauto_v151spositiontaking_42 = CASE WHEN @isauto_v151spositiontaking_mem_42 > 0 THEN @isauto_v151spositiontaking_mem_42 ELSE @isauto_v151spositiontaking_42 END
		
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--um=im1>0?um1:um2
SELECT 
	@auto_v151mpositiontaking_31 = CASE WHEN @isauto_v151mpositiontaking_mem_31>0 THEN @auto_v151mpositiontaking_mem_31 ELSE @auto_v151mpositiontaking_31 END,
	@auto_v151mpositiontaking_32 = CASE WHEN @isauto_v151mpositiontaking_mem_32>0 THEN @auto_v151mpositiontaking_mem_32 ELSE @auto_v151mpositiontaking_32 END,
	@auto_v151mpositiontaking_41 = CASE WHEN @isauto_v151mpositiontaking_mem_41>0 THEN @auto_v151mpositiontaking_mem_41 ELSE @auto_v151mpositiontaking_41 END,
	@auto_v151mpositiontaking_42 = CASE WHEN @isauto_v151mpositiontaking_mem_42>0 THEN @auto_v151mpositiontaking_mem_42 ELSE @auto_v151mpositiontaking_42 END,
--im=im1>0?im1:im2
	@isauto_v151mpositiontaking_31 = CASE WHEN @isauto_v151mpositiontaking_mem_31>0 THEN @isauto_v151mpositiontaking_mem_31 ELSE @isauto_v151mpositiontaking_31 END,
	@isauto_v151mpositiontaking_32 = CASE WHEN @isauto_v151mpositiontaking_mem_32>0 THEN @isauto_v151mpositiontaking_mem_32 ELSE @isauto_v151mpositiontaking_32 END,
	@isauto_v151mpositiontaking_41 = CASE WHEN @isauto_v151mpositiontaking_mem_41>0 THEN @isauto_v151mpositiontaking_mem_41 ELSE @isauto_v151mpositiontaking_41 END,
	@isauto_v151mpositiontaking_42 = CASE WHEN @isauto_v151mpositiontaking_mem_42>0 THEN @isauto_v151mpositiontaking_mem_42 ELSE @isauto_v151mpositiontaking_42 END


--a1=min(a1,m3)
SELECT 
	@v151apositiontaking_31 = CASE WHEN @v151apositiontaking_31 > @v151mapositiontaking_31_max THEN @v151mapositiontaking_31_max ELSE @v151apositiontaking_31 END,
	@v151apositiontaking_32 = CASE WHEN @v151apositiontaking_32 > @v151mapositiontaking_32_max THEN @v151mapositiontaking_32_max ELSE @v151apositiontaking_32 END,
	@v151apositiontaking_41 = CASE WHEN @v151apositiontaking_41 > @v151mapositiontaking_41_max THEN @v151mapositiontaking_41_max ELSE @v151apositiontaking_41 END,
	@v151apositiontaking_42 = CASE WHEN @v151apositiontaking_42 > @v151mapositiontaking_42_max THEN @v151mapositiontaking_42_max ELSE @v151apositiontaking_42 END


--a1=if(!im)if(m1+a1>m3,m3-m1)
SELECT 
	@v151apositiontaking_31 = CASE WHEN @isauto_v151mpositiontaking_31 > 0 THEN @v151apositiontaking_31 ELSE CASE WHEN @v151apositiontaking_31 + @v151mpositiontaking_31 > @v151mapositiontaking_31_max THEN @v151mapositiontaking_31_max - @v151mpositiontaking_31 ELSE @v151apositiontaking_31 END END,
	@v151apositiontaking_32 = CASE WHEN @isauto_v151mpositiontaking_32 > 0 THEN @v151apositiontaking_32 ELSE CASE WHEN @v151apositiontaking_32 + @v151mpositiontaking_32 > @v151mapositiontaking_32_max THEN @v151mapositiontaking_32_max - @v151mpositiontaking_32 ELSE @v151apositiontaking_32 END END,
	@v151apositiontaking_41 = CASE WHEN @isauto_v151mpositiontaking_41 > 0 THEN @v151apositiontaking_41 ELSE CASE WHEN @v151apositiontaking_41 + @v151mpositiontaking_41 > @v151mapositiontaking_41_max THEN @v151mapositiontaking_41_max - @v151mpositiontaking_41 ELSE @v151apositiontaking_41 END END,
	@v151apositiontaking_42 = CASE WHEN @isauto_v151mpositiontaking_42 > 0 THEN @v151apositiontaking_42 ELSE CASE WHEN @v151apositiontaking_42 + @v151mpositiontaking_42 > @v151mapositiontaking_42_max THEN @v151mapositiontaking_42_max - @v151mpositiontaking_42 ELSE @v151apositiontaking_42 END END


SELECT 
	@v151apositiontaking_31 = CASE WHEN @v151apositiontaking_31 < 0 THEN 0 ELSE @v151apositiontaking_31 END,
	@v151apositiontaking_32 = CASE WHEN @v151apositiontaking_32 < 0 THEN 0 ELSE @v151apositiontaking_32 END,
	@v151apositiontaking_41 = CASE WHEN @v151apositiontaking_41 < 0 THEN 0 ELSE @v151apositiontaking_41 END,
	@v151apositiontaking_42 = CASE WHEN @v151apositiontaking_42 < 0 THEN 0 ELSE @v151apositiontaking_42 END

---------------------------------------------------------------------------------------------------------------------------------------------
----------------***Use Master Auto Position Taking***----------------------------------
--use @auto_mpt at agent
--@max_mpt = @maxdownlinepos + mpt ; pt: positiontaking
--if um = 0 then m1 = m2
--else	if um < m3 - a1 then m1 = um
--		else m1 = m3 - a1

--m1=iif(im,min(m3-a1,um),m1)
select @v151mpositiontaking_31 = case when isnull(@isauto_v151mpositiontaking_31, 0)=0 then @v151mpositiontaking_31 else case when @auto_v151mpositiontaking_31 < @v151mapositiontaking_31_max - @v151apositiontaking_31 then @auto_v151mpositiontaking_31 else @v151mapositiontaking_31_max - @v151apositiontaking_31 end end
select @v151mpositiontaking_32 = case when isnull(@isauto_v151mpositiontaking_32, 0)=0 then @v151mpositiontaking_32 else case when @auto_v151mpositiontaking_32 < @v151mapositiontaking_32_max - @v151apositiontaking_32 then @auto_v151mpositiontaking_32 else @v151mapositiontaking_32_max - @v151apositiontaking_32 end end
select @v151mpositiontaking_41 = case when isnull(@isauto_v151mpositiontaking_41, 0)=0 then @v151mpositiontaking_41 else case when @auto_v151mpositiontaking_41 < @v151mapositiontaking_41_max - @v151apositiontaking_41 then @auto_v151mpositiontaking_41 else @v151mapositiontaking_41_max - @v151apositiontaking_41 end end
select @v151mpositiontaking_42 = case when isnull(@isauto_v151mpositiontaking_42, 0)=0 then @v151mpositiontaking_42 else case when @auto_v151mpositiontaking_42 < @v151mapositiontaking_42_max - @v151apositiontaking_42 then @auto_v151mpositiontaking_42 else @v151mapositiontaking_42_max - @v151apositiontaking_42 end end

--------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------------

----------------***Use Auto Position Taking***----------------------------------
--@max_spt = @maxdownlinepos + spt ; pt: positiontaking
--if @auto_spt = 0 then @spt = @spt  -- Auto pt is not used
--else	if @auto_spt < @max_spt - @mpt - @apt then @spt = @auto_spt
--		else @spt = @max_spt - @mpt - @apt
SELECT @v151spositiontaking_31 = CASE WHEN ISNULL(@isauto_v151spositiontaking_31, 0)<=0 THEN @v151spositiontaking_31 ELSE CASE WHEN @auto_v151spositiontaking_31 < @max_v151spositiontaking_31 - @v151mpositiontaking_31 - @v151apositiontaking_31 THEN @auto_v151spositiontaking_31 ELSE @max_v151spositiontaking_31 - @v151mpositiontaking_31 - @v151apositiontaking_31 END END
SELECT @v151spositiontaking_32 = CASE WHEN ISNULL(@isauto_v151spositiontaking_32, 0)<=0 THEN @v151spositiontaking_32 ELSE CASE WHEN @auto_v151spositiontaking_32 < @max_v151spositiontaking_32 - @v151mpositiontaking_32 - @v151apositiontaking_32 THEN @auto_v151spositiontaking_32 ELSE @max_v151spositiontaking_32 - @v151mpositiontaking_32 - @v151apositiontaking_32 END END
SELECT @v151spositiontaking_41 = CASE WHEN ISNULL(@isauto_v151spositiontaking_41, 0)<=0 THEN @v151spositiontaking_41 ELSE CASE WHEN @auto_v151spositiontaking_41 < @max_v151spositiontaking_41 - @v151mpositiontaking_41 - @v151apositiontaking_41 THEN @auto_v151spositiontaking_41 ELSE @max_v151spositiontaking_41 - @v151mpositiontaking_41 - @v151apositiontaking_41 END END
SELECT @v151spositiontaking_42 = CASE WHEN ISNULL(@isauto_v151spositiontaking_42, 0)<=0 THEN @v151spositiontaking_42 ELSE CASE WHEN @auto_v151spositiontaking_42 < @max_v151spositiontaking_42 - @v151mpositiontaking_42 - @v151apositiontaking_42 THEN @auto_v151spositiontaking_42 ELSE @max_v151spositiontaking_42 - @v151mpositiontaking_42 - @v151apositiontaking_42 END END
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--max_spositiontaking = if(i1||i3)s4:s4-m1-a1
SELECT @max_v151spositiontaking_31 = CASE WHEN ISNULL(@isauto_v151spositiontaking_31, 0)>0 THEN @max_v151spositiontaking_31 ELSE @max_v151spositiontaking_31 - @v151mpositiontaking_31 - @v151apositiontaking_31 END
SELECT @max_v151spositiontaking_32 = CASE WHEN ISNULL(@isauto_v151spositiontaking_32, 0)>0 THEN @max_v151spositiontaking_32 ELSE @max_v151spositiontaking_32 - @v151mpositiontaking_32 - @v151apositiontaking_32 END
SELECT @max_v151spositiontaking_41 = CASE WHEN ISNULL(@isauto_v151spositiontaking_41, 0)>0 THEN @max_v151spositiontaking_41 ELSE @max_v151spositiontaking_41 - @v151mpositiontaking_41 - @v151apositiontaking_41 END
SELECT @max_v151spositiontaking_42 = CASE WHEN ISNULL(@isauto_v151spositiontaking_42, 0)>0 THEN @max_v151spositiontaking_42 ELSE @max_v151spositiontaking_42 - @v151mpositiontaking_42 - @v151apositiontaking_42 END

--//REPLACING CHECK MAX SUPER PT ON MEMBER

--s1=min(s1,max_spositiontaking)
SELECT @v151spositiontaking_31 = CASE WHEN @v151spositiontaking_31 > @max_v151spositiontaking_31 THEN @max_v151spositiontaking_31 ELSE @v151spositiontaking_31 END
SELECT @v151spositiontaking_32 = CASE WHEN @v151spositiontaking_32 > @max_v151spositiontaking_32 THEN @max_v151spositiontaking_32 ELSE @v151spositiontaking_32 END
SELECT @v151spositiontaking_41 = CASE WHEN @v151spositiontaking_41 > @max_v151spositiontaking_41 THEN @max_v151spositiontaking_41 ELSE @v151spositiontaking_41 END
SELECT @v151spositiontaking_42 = CASE WHEN @v151spositiontaking_42 > @max_v151spositiontaking_42 THEN @max_v151spositiontaking_42 ELSE @v151spositiontaking_42 END


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------
BEGIN TRANSACTION
---------------------------------------

UPDATE CustSetting3rd WITH (ROWLOCK, UPDLOCK)
SET
	apositiontaking = CASE bettype WHEN 31 THEN @v151apositiontaking_31 WHEN 32 THEN @v151apositiontaking_32 WHEN 41 THEN @v151apositiontaking_41 WHEN 42 THEN @v151apositiontaking_42 ELSE apositiontaking END,	
	--Auto Master PT
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	mpositiontaking = CASE bettype WHEN 31 THEN @v151mpositiontaking_31 WHEN 32 THEN @v151mpositiontaking_32 WHEN 41 THEN @v151mpositiontaking_41 WHEN 42 THEN @v151mpositiontaking_42 ELSE mpositiontaking END,
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	spositiontaking = CASE bettype WHEN 31 THEN @v151spositiontaking_31 WHEN 32 THEN @v151spositiontaking_32 WHEN 41 THEN @v151spositiontaking_41 WHEN 42 THEN @v151spositiontaking_42 ELSE spositiontaking END
WHERE custid=@custid and sporttype = 151

EXEC dbo.Acc_CustomerUpdMemberHR_MinMaxPositiontaking @custid = @custid, @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend

COMMIT TRANSACTION

Declare @LogSPData varchar(5000)
	
Select @LogSPData = '<Acc_CustomerUpdMemberHR_PositionTaking><info custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(8000)),space(1)) + '" />' +

'<ag v151apt_31="'+ coalesce(cast(@v151apositiontaking_31 as varchar(50)),space(1)) + '" ' +
'v151apt_32="'+ coalesce(cast(@v151apositiontaking_32 as varchar(50)),space(1)) + '" ' +
'v151apt_41="'+ coalesce(cast(@v151apositiontaking_41 as varchar(50)),space(1)) + '" ' +
'v151apt_42="'+ coalesce(cast(@v151apositiontaking_42 as varchar(50)),space(1)) + '" /></Acc_CustomerUpdMemberHR_PositionTaking>'


EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 421,
	@TrackingValue = @LogSPData
	
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMemberHR_PositionTaking] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMemberHR_PositionTaking] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMemberHR_PositionTaking] TO vnteam
