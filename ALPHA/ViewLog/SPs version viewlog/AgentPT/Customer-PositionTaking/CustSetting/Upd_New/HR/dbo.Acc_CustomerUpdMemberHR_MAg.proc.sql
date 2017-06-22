
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Acc_CustomerUpdMemberHR_MAg    Script Date: 8/6/2009 8:08:10 PM ******/
ALTER PROCEDURE [dbo].[Acc_CustomerUpdMemberHR_MAg] 
	@CustID int,--memberid
	--m1
	@v151mpositiontaking_31 smallmoney OUTPUT,
	@v151mpositiontaking_32 smallmoney OUTPUT,
	@v151mpositiontaking_41 smallmoney OUTPUT,
	@v151mpositiontaking_42 smallmoney OUTPUT,
	--im2
	@isauto_v151mpositiontaking_31 bit = 0,
	@isauto_v151mpositiontaking_32 bit = 0,
	@isauto_v151mpositiontaking_41 bit = 0,
	@isauto_v151mpositiontaking_42 bit = 0,
	--im1
	@isauto_v151mpositiontaking_mem_31 bit = 0,
	@isauto_v151mpositiontaking_mem_32 bit = 0,
	@isauto_v151mpositiontaking_mem_41 bit = 0,
	@isauto_v151mpositiontaking_mem_42 bit = 0,
	--um1
	@auto_v151mpositiontaking_mem_31 SMALLMONEY = 0,
	@auto_v151mpositiontaking_mem_32 SMALLMONEY = 0,	
	@auto_v151mpositiontaking_mem_41 SMALLMONEY = 0,
	@auto_v151mpositiontaking_mem_42 SMALLMONEY = 0,	

	@UserID int,--masterid	
	@Language varchar(2) = 'E',
	@SubAccID int = 0, --Sub-AccountID
	@IP varchar(15)='',
	@Username varchar(30) = '' OUTPUT,
	@ErrCode varchar(300) = '' OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20090520@Phuc
Task : Master edit member(HR)
DB: DB02.bodb02
Original: [Acc_CustomerUpdMaster_Member]

Revisions:
	-20090626@Phuc: Auto master PT on member level
					Enrich error message.(-101: general info, -102: closed, -103: suspended, 
						-104: credit, -105: commission, -106: min/max bet, -107: positiontaking
						-108: disable FI, -109: disableHR)
	-20090723@Phuc: Write log subaccname instead of subaccid.
    - 20090801@Shifu: check disabled user
    - 20090806@Phuc: remove check m1=min(m3-a2,m1)
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20090917@Phuc: write log into DBLOG.
	- 20091201@Kiwi: Move custsetting & custoverride to the separated tables (CustSetting3rd & CustOverride3rd).
	- 20100112@Kiwi: amend to write log in xml format.
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON

Declare @ErrType varchar(1000), @roleid tinyint, @recommend INT,	@mrecommend INT, @srecommend INT,
	@ErrCode_cur int, @ErrMsg_cur nvarchar(4000)
Select @ErrCode_cur = 0, @ErrMsg_cur = '', @ErrCode = '', @ErrMsg = ''

EXEC DB052.bodb02.dbo.Age_CustomerSelCheckBelonging 
	@SessionCustID = @Userid, 
	@username = @username output,
	@Custid = @custid,
	@roleid = @roleid OUTPUT
	if (@roleid = 0) return

--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode_Cur output,@ErrMsg=@ErrMsg_Cur output
IF @ErrCode_Cur > 0
BEGIN
	select @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
			@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
	return
END
--end

select @UserName = username, @recommend = recommend, @mrecommend = mrecommend, @srecommend = srecommend 
from customer with (NOLOCK) where custid = @custid

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Check parameter

declare @maxpos smallmoney
set @maxpos = 0.5

if @v151mpositiontaking_31 <0
	or @v151mpositiontaking_32 <0
	or @v151mpositiontaking_41 <0
	or @v151mpositiontaking_42 <0
	or @v151mpositiontaking_31 > @maxpos
	or @v151mpositiontaking_32 > @maxpos
	or @v151mpositiontaking_41 > @maxpos
	or @v151mpositiontaking_42 > @maxpos
	
	or @auto_v151mpositiontaking_mem_31 <0
	or @auto_v151mpositiontaking_mem_32 <0
	or @auto_v151mpositiontaking_mem_41 <0
	or @auto_v151mpositiontaking_mem_42 <0
	or @auto_v151mpositiontaking_mem_31 > @maxpos
	or @auto_v151mpositiontaking_mem_32 > @maxpos
	or @auto_v151mpositiontaking_mem_41 > @maxpos
	or @auto_v151mpositiontaking_mem_42 > @maxpos

BEGIN
	select @ErrCode_cur = 5
	Select @ErrMsg_cur = 	@UserName + ': ' +
		case @Language 
						when 'E' then 'Wrong position taking.'
						when 'CS' then N'占成数不正确.'
						when 'CT' then N'佔成數不正確.'
						when 'TH' then N'การกำหนดไม่ถูกต้อง.'
						when 'J' then N'Wrong position taking.'
						when 'KO' then N'거래 조건이 잘못 되었습니다.'
						else N'Wrong position taking.'
				end
	Select  @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
			@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
	return
END
-- End check param
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


DECLARE 
	--a1
	@v151apositiontaking_31 SMALLMONEY,
	@v151apositiontaking_32 SMALLMONEY,
	@v151apositiontaking_41 SMALLMONEY,
	@v151apositiontaking_42 SMALLMONEY,
	
	--a2
	@max_v151apositiontaking_31 SMALLMONEY,
	@max_v151apositiontaking_32 SMALLMONEY,
	@max_v151apositiontaking_41 SMALLMONEY,
	@max_v151apositiontaking_42 SMALLMONEY,
	
	--old_m1	
	@old_v151mpositiontaking_31 SMALLMONEY,
	@old_v151mpositiontaking_32 SMALLMONEY,
	@old_v151mpositiontaking_41 SMALLMONEY,
	@old_v151mpositiontaking_42 SMALLMONEY,
	
	--old_um1
	@old_auto_v151mpositiontaking_mem_31 SMALLMONEY,
	@old_auto_v151mpositiontaking_mem_32 SMALLMONEY,
	@old_auto_v151mpositiontaking_mem_41 SMALLMONEY,
	@old_auto_v151mpositiontaking_mem_42 SMALLMONEY,
	
	--old_im1
	@old_isauto_v151mpositiontaking_mem_31 BIT,
	@old_isauto_v151mpositiontaking_mem_32 BIT,
	@old_isauto_v151mpositiontaking_mem_41 BIT,
	@old_isauto_v151mpositiontaking_mem_42 BIT,

	--s4
	@max_v151spositiontaking_31 SMALLMONEY,
	@max_v151spositiontaking_32 SMALLMONEY,
	@max_v151spositiontaking_41 SMALLMONEY,
	@max_v151spositiontaking_42 SMALLMONEY,
	
	@v151spositiontaking_31 SMALLMONEY,
	@v151spositiontaking_32 SMALLMONEY,
	@v151spositiontaking_41 SMALLMONEY,
	@v151spositiontaking_42 SMALLMONEY,
	
	--u1
	@auto_v151spositiontaking_mem_31 SMALLMONEY,
	@auto_v151spositiontaking_mem_32 SMALLMONEY,
	@auto_v151spositiontaking_mem_41 SMALLMONEY,
	@auto_v151spositiontaking_mem_42 SMALLMONEY,
	--i1
	@isauto_v151spositiontaking_mem_31 BIT,
	@isauto_v151spositiontaking_mem_32 BIT,
	@isauto_v151spositiontaking_mem_41 BIT,
	@isauto_v151spositiontaking_mem_42 BIT,
	--u3
	@auto_v151spositiontaking_31 SMALLMONEY,
	@auto_v151spositiontaking_32 SMALLMONEY,
	@auto_v151spositiontaking_41 SMALLMONEY,
	@auto_v151spositiontaking_42 SMALLMONEY,
	
	--i3
	@isauto_v151spositiontaking_31 BIT,
	@isauto_v151spositiontaking_32 BIT,
	@isauto_v151spositiontaking_41 BIT,
	@isauto_v151spositiontaking_42 BIT,
	
	--um2
	@auto_v151mpositiontaking_31 SMALLMONEY ,
	@auto_v151mpositiontaking_32 SMALLMONEY,
	@auto_v151mpositiontaking_41 SMALLMONEY ,
	@auto_v151mpositiontaking_42 SMALLMONEY

DECLARE
	@max_v151mapositiontaking_31 SMALLMONEY,
	@max_v151mapositiontaking_32 SMALLMONEY,
	@max_v151mapositiontaking_41 SMALLMONEY,
	@max_v151mapositiontaking_42 SMALLMONEY
	
DECLARE
	@min_v151mapositiontaking_31 SMALLMONEY,
	@min_v151mapositiontaking_32 SMALLMONEY,
	@min_v151mapositiontaking_41 SMALLMONEY,
	@min_v151mapositiontaking_42 SMALLMONEY



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
if @srecommend>100 and @custid<>79711
BEGIN
	declare @ErrMsg varchar(200)
	Select @ErrMsg = 'Sorry, please try again later.'
	RaisError (@ErrMsg, 16, 1)
	return
END
*/
--s1,a1,old_m1,u1,i1
SELECT	@v151spositiontaking_31	=	spositiontaking,	@v151apositiontaking_31	=	apositiontaking,	@auto_v151spositiontaking_mem_31	=	autopositiontaking,	@isauto_v151spositiontaking_mem_31	=	isautopositiontaking,	@old_v151mpositiontaking_31	=	mpositiontaking	,	@old_auto_v151mpositiontaking_mem_31	=	autompositiontaking	,	@old_isauto_v151mpositiontaking_mem_31	=	isautompositiontaking	FROM	CustSetting3rd	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=31	AND	sporttype=151																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v151spositiontaking_32	=	spositiontaking,	@v151apositiontaking_32	=	apositiontaking,	@auto_v151spositiontaking_mem_32	=	autopositiontaking,	@isauto_v151spositiontaking_mem_32	=	isautopositiontaking,	@old_v151mpositiontaking_32	=	mpositiontaking	,	@old_auto_v151mpositiontaking_mem_32	=	autompositiontaking	,	@old_isauto_v151mpositiontaking_mem_32	=	isautompositiontaking	FROM	CustSetting3rd	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=32	AND	sporttype=151																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v151spositiontaking_41	=	spositiontaking,	@v151apositiontaking_41	=	apositiontaking,	@auto_v151spositiontaking_mem_41	=	autopositiontaking,	@isauto_v151spositiontaking_mem_41	=	isautopositiontaking,	@old_v151mpositiontaking_41	=	mpositiontaking	,	@old_auto_v151mpositiontaking_mem_41	=	autompositiontaking	,	@old_isauto_v151mpositiontaking_mem_41	=	isautompositiontaking	FROM	CustSetting3rd	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=41	AND	sporttype=151																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v151spositiontaking_42	=	spositiontaking,	@v151apositiontaking_42	=	apositiontaking,	@auto_v151spositiontaking_mem_42	=	autopositiontaking,	@isauto_v151spositiontaking_mem_42	=	isautopositiontaking,	@old_v151mpositiontaking_42	=	mpositiontaking	,	@old_auto_v151mpositiontaking_mem_42	=	autompositiontaking	,	@old_isauto_v151mpositiontaking_mem_42	=	isautompositiontaking	FROM	CustSetting3rd	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=42	AND	sporttype=151																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												

--Check if old_PT = new_PT return
IF @v151mpositiontaking_31 = @old_v151mpositiontaking_31 AND
	@v151mpositiontaking_32 = @old_v151mpositiontaking_32 AND
	@v151mpositiontaking_41 = @old_v151mpositiontaking_41 AND
	@v151mpositiontaking_42 = @old_v151mpositiontaking_42 AND
	--um1
	@auto_v151mpositiontaking_mem_31 = @old_auto_v151mpositiontaking_mem_31 AND
	@auto_v151mpositiontaking_mem_32 = @old_auto_v151mpositiontaking_mem_32 AND
	@auto_v151mpositiontaking_mem_41 = @old_auto_v151mpositiontaking_mem_41 AND
	@auto_v151mpositiontaking_mem_42 = @old_auto_v151mpositiontaking_mem_42 AND
	--im1
	@isauto_v151mpositiontaking_mem_31 = @old_isauto_v151mpositiontaking_mem_31 AND
	@isauto_v151mpositiontaking_mem_32 = @old_isauto_v151mpositiontaking_mem_32 AND
	@isauto_v151mpositiontaking_mem_41 = @old_isauto_v151mpositiontaking_mem_41 AND
	@isauto_v151mpositiontaking_mem_42 = @old_isauto_v151mpositiontaking_mem_42 
BEGIN
	Select @ErrCode = @ErrCode + '-107'+char(7), @ErrMsg = @ErrMsg + char(7)
	RETURN 
END

--Check um1<=l3
	SELECT @ErrType = ''
	SELECT @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ CAST((co.maxpositiontaking) AS VARCHAR(10))
	FROM CustOverride3rd AS co WITH (NOLOCK) INNER JOIN
		(
							SELECT 151 AS sporttype, 31 AS bettype, @auto_v151mpositiontaking_mem_31 AS autopositiontaking, @isauto_v151mpositiontaking_mem_31 AS isautopositiontaking
			UNION ALL		SELECT 151 AS sporttype, 32 AS bettype, @auto_v151mpositiontaking_mem_32 AS autopositiontaking, @isauto_v151mpositiontaking_mem_32 AS isautopositiontaking
			UNION ALL		SELECT 151 AS sporttype, 41 AS bettype, @auto_v151mpositiontaking_mem_41 AS autopositiontaking, @isauto_v151mpositiontaking_mem_41 AS isautopositiontaking
			UNION ALL		SELECT 151 AS sporttype, 42 AS bettype, @auto_v151mpositiontaking_mem_42 AS autopositiontaking, @isauto_v151mpositiontaking_mem_42 AS isautopositiontaking
		) AS b ON co.sporttype=b.sporttype AND co.bettype=b.bettype
	INNER JOIN sports WITH (NOLOCK) ON b.sporttype = sports.sporttype
	INNER JOIN bettype WITH (NOLOCK) ON b.bettype = bettype.typeid

WHERE co.custid = @mrecommend AND (b.isautopositiontaking>0 AND b.autopositiontaking>co.maxpositiontaking)

IF @ErrType <>''
BEGIN
	SELECT @ErrCode_cur = 6,
		   @ErrMsg_cur = CASE @Language 
								WHEN 'E' THEN 'Wrong position taking (min/max set by company) ('+@ErrType+').'
								WHEN 'CS' THEN N'占成数不正确(公司设给最低/高占成) ('+@ErrType+').'
								WHEN 'CT' THEN N'佔成數不正確(公司設給最低/高佔成) ('+@ErrType+').'
								WHEN 'TH' THEN N'การกำหนดไม่ถูกต้อง (สูงสุด หรือ ต่ำสุด อ้างอิงจากข้อมูลบริษัท) ('+@ErrType+').'
								WHEN 'J' THEN N'Wrong position taking (min/max set by company) ('+@ErrType+').'
								WHEN 'KO' THEN N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값) ('+@ErrType+').'
								ELSE N'Wrong position taking (min/max set by company) ('+@ErrType+').'
						END
	SELECT  @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
			@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
						
	RETURN
END

--Check um1<=m3
	SELECT @ErrType = ''
	SELECT @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ CAST((mcs.mpositiontaking) AS VARCHAR(10))
	FROM CustSetting3rd AS mcs WITH (NOLOCK) INNER JOIN
		(
							SELECT 151 AS sporttype, 31 AS bettype, @auto_v151mpositiontaking_mem_31 AS autopositiontaking, @isauto_v151mpositiontaking_mem_31 AS isautopositiontaking
			UNION ALL		SELECT 151 AS sporttype, 32 AS bettype, @auto_v151mpositiontaking_mem_32 AS autopositiontaking, @isauto_v151mpositiontaking_mem_32 AS isautopositiontaking
			UNION ALL		SELECT 151 AS sporttype, 41 AS bettype, @auto_v151mpositiontaking_mem_41 AS autopositiontaking, @isauto_v151mpositiontaking_mem_41 AS isautopositiontaking
			UNION ALL		SELECT 151 AS sporttype, 42 AS bettype, @auto_v151mpositiontaking_mem_42 AS autopositiontaking, @isauto_v151mpositiontaking_mem_42 AS isautopositiontaking
		) AS b ON mcs.sporttype=b.sporttype AND mcs.bettype=b.bettype
	INNER JOIN sports WITH (NOLOCK) ON b.sporttype = sports.sporttype
	INNER JOIN bettype WITH (NOLOCK) ON b.bettype = bettype.typeid
WHERE mcs.custid = @mrecommend AND (b.isautopositiontaking>0 AND b.autopositiontaking>mcs.mpositiontaking) 

IF @ErrType <>''
BEGIN
	SELECT @ErrCode_cur = 7,
		   @ErrMsg_cur = @UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Wrong auto position taking.<br>'+@ErrType
							WHEN 'CS' THEN N'自动占成数不正确.<br>'+@ErrType
							WHEN 'CT' THEN N'自動佔成數不正確.<br>'+@ErrType
							WHEN 'TH' THEN N'การปรับยอดเงินที่ผิดพลาดอันเนื่องมาจากระบบ.<br>'+@ErrType
							WHEN 'J' THEN N'Wrong auto position taking.<br>'+@ErrType
							WHEN 'KO' THEN N'자동 거래조건이 잘못 되었습니다.<br>'+@ErrType
							ELSE N'Wrong auto position taking.<br>'+@ErrType
						END							
	SELECT  @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
			@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
	
	RETURN
END

--m3,u3,i3
SELECT @max_v151mapositiontaking_31 =mpositiontaking, @auto_v151spositiontaking_31 = autopositiontaking, @isauto_v151spositiontaking_31 = isautopositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=31 AND sporttype=151
SELECT @max_v151mapositiontaking_32 =mpositiontaking, @auto_v151spositiontaking_32 = autopositiontaking, @isauto_v151spositiontaking_32 = isautopositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=32 AND sporttype=151
SELECT @max_v151mapositiontaking_41 =mpositiontaking, @auto_v151spositiontaking_41 = autopositiontaking, @isauto_v151spositiontaking_41 = isautopositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=41 AND sporttype=151
SELECT @max_v151mapositiontaking_42 =mpositiontaking, @auto_v151spositiontaking_42 = autopositiontaking, @isauto_v151spositiontaking_42 = isautopositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=42 AND sporttype=151

--n3
SELECT @min_v151mapositiontaking_31 = minpositiontaking FROM CustOverride3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=31 AND sporttype=151
SELECT @min_v151mapositiontaking_32 = minpositiontaking FROM CustOverride3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=32 AND sporttype=151
SELECT @min_v151mapositiontaking_41 = minpositiontaking FROM CustOverride3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=41 AND sporttype=151
SELECT @min_v151mapositiontaking_42 = minpositiontaking FROM CustOverride3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=42 AND sporttype=151

--s4
SELECT @max_v151spositiontaking_31 = spositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND bettype=31 AND sporttype=151
SELECT @max_v151spositiontaking_32 = spositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND bettype=32 AND sporttype=151
SELECT @max_v151spositiontaking_41 = spositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND bettype=41 AND sporttype=151
SELECT @max_v151spositiontaking_42 = spositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND bettype=42 AND sporttype=151

--um2
SELECT 
	@auto_v151mpositiontaking_31 = MAX(CASE WHEN acs.bettype = 31 AND acs.sporttype=151 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v151mpositiontaking_32 = MAX(CASE WHEN acs.bettype = 32 AND acs.sporttype=151 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v151mpositiontaking_41 = MAX(CASE WHEN acs.bettype = 41 AND acs.sporttype=151 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v151mpositiontaking_42 = MAX(CASE WHEN acs.bettype = 42 AND acs.sporttype=151 THEN acs.autompositiontaking ELSE 0 END),
	--a2	
	@max_v151apositiontaking_31 = MAX(CASE WHEN acs.bettype = 31 AND acs.sporttype=151 THEN acs.apositiontaking ELSE 0 END),
	@max_v151apositiontaking_32 = MAX(CASE WHEN acs.bettype = 32 AND acs.sporttype=151 THEN acs.apositiontaking ELSE 0 END),
	@max_v151apositiontaking_41 = MAX(CASE WHEN acs.bettype = 41 AND acs.sporttype=151 THEN acs.apositiontaking ELSE 0 END),
	@max_v151apositiontaking_42 = MAX(CASE WHEN acs.bettype = 42 AND acs.sporttype=151 THEN acs.apositiontaking ELSE 0 END)
FROM CustSetting3rd acs WITH(NOLOCK)
WHERE acs.custid = @recommend


--Check m1<=m3
SELECT @ErrType = ''
SELECT @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ CAST((b.maxmpositiontaking) AS VARCHAR(10))
FROM (
						SELECT 151 AS sporttype	,	 31 AS bettype	,	 @v151mpositiontaking_31 AS mpositiontaking	,	 @max_v151mapositiontaking_31 AS maxmpositiontaking
		UNION ALL		SELECT 151 AS sporttype	,	 32 AS bettype	,	 @v151mpositiontaking_32 AS mpositiontaking	,	 @max_v151mapositiontaking_32 AS maxmpositiontaking
		UNION ALL		SELECT 151 AS sporttype	,	 41 AS bettype	,	 @v151mpositiontaking_41 AS mpositiontaking	,	 @max_v151mapositiontaking_41 AS maxmpositiontaking
		UNION ALL		SELECT 151 AS sporttype	,	 42 AS bettype	,	 @v151mpositiontaking_42 AS mpositiontaking	,	 @max_v151mapositiontaking_42 AS maxmpositiontaking
)b 	
	INNER JOIN sports WITH (NOLOCK) ON b.sporttype = sports.sporttype
	INNER JOIN bettype WITH (NOLOCK) ON b.bettype = bettype.typeid
WHERE (b.mpositiontaking>b.maxmpositiontaking) 

IF @ErrType <>''
BEGIN
	SELECT @ErrCode_cur = 8,
			@ErrMsg_cur = @UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Wrong  position taking.<br>'+@ErrType
							WHEN 'CS' THEN N'占成数不正确.<br>'+@ErrType
							WHEN 'CT' THEN N'佔成數不正確.<br>'+@ErrType
							WHEN 'TH' THEN N'การกำหนดไม่ถูกต้อง.<br>'+@ErrType
							WHEN 'J' THEN N'Wrong  position taking.<br>'+@ErrType
							WHEN 'KO' THEN N'거래 조건이 잘못 되었습니다.<br>'+@ErrType
							ELSE N'Wrong  position taking.<br>'+@ErrType
						END							
	SELECT  @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
			@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
	
	RETURN
END
--Check m1<=l3
SELECT @ErrType = ''
SELECT @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ CAST((co.maxpositiontaking) AS VARCHAR(10))
	FROM CustOverride3rd AS co WITH (NOLOCK) INNER JOIN
		(
							SELECT 151 AS sporttype	,	 31 AS bettype	,	 @v151mpositiontaking_31 AS mpositiontaking
			UNION ALL		SELECT 151 AS sporttype	,	 32 AS bettype	,	 @v151mpositiontaking_32 AS mpositiontaking
			UNION ALL		SELECT 151 AS sporttype	,	 41 AS bettype	,	 @v151mpositiontaking_41 AS mpositiontaking
			UNION ALL		SELECT 151 AS sporttype	,	 42 AS bettype	,	 @v151mpositiontaking_42 AS mpositiontaking
		) AS b ON co.sporttype=b.sporttype AND co.bettype=b.bettype
	INNER JOIN sports WITH (NOLOCK) ON b.sporttype = sports.sporttype
	INNER JOIN bettype WITH (NOLOCK) ON b.bettype = bettype.typeid
WHERE co.custid = @mrecommend AND (b.mpositiontaking>co.maxpositiontaking) 
IF @ErrType <>''
BEGIN
	SELECT @ErrCode_cur = 9,
  			@ErrMsg_cur = @UserName + ': '+
				 CASE @Language 
						WHEN 'E' THEN 'Wrong position taking (min/max set by company) ('+@ErrType+').'
						WHEN 'CS' THEN N'占成数不正确(公司设给最低/高占成) ('+@ErrType+').'
						WHEN 'CT' THEN N'佔成數不正確(公司設給最低/高佔成) ('+@ErrType+').'
						WHEN 'TH' THEN N'การกำหนดไม่ถูกต้อง (สูงสุด หรือ ต่ำสุด อ้างอิงจากข้อมูลบริษัท) ('+@ErrType+').'
						WHEN 'J' THEN N'Wrong position taking (min/max set by company) ('+@ErrType+').'
						WHEN 'KO' THEN N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값) ('+@ErrType+').'
						ELSE N'Wrong position taking (min/max set by company) ('+@ErrType+').'
				END
	SELECT  @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
			@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
	RETURN
END

--m1=m1+a1>m3?m3-a1:m1
SELECT 
	@v151mpositiontaking_31 = CASE WHEN @v151apositiontaking_31+@v151mpositiontaking_31>@max_v151mapositiontaking_31 THEN @max_v151mapositiontaking_31-@v151apositiontaking_31 ELSE @v151mpositiontaking_31 END,
	@v151mpositiontaking_32 = CASE WHEN @v151apositiontaking_32+@v151mpositiontaking_32>@max_v151mapositiontaking_32 THEN @max_v151mapositiontaking_32-@v151apositiontaking_32 ELSE @v151mpositiontaking_32 END,
	@v151mpositiontaking_41 = CASE WHEN @v151apositiontaking_41+@v151mpositiontaking_41>@max_v151mapositiontaking_41 THEN @max_v151mapositiontaking_41-@v151apositiontaking_41 ELSE @v151mpositiontaking_41 END,
	@v151mpositiontaking_42 = CASE WHEN @v151apositiontaking_42+@v151mpositiontaking_42>@max_v151mapositiontaking_42 THEN @max_v151mapositiontaking_42-@v151apositiontaking_42 ELSE @v151mpositiontaking_42 END

--m1=m1+a1<n3?n3-a1:m1
SELECT 
	@v151mpositiontaking_31 = CASE WHEN @v151apositiontaking_31+@v151mpositiontaking_31<@min_v151mapositiontaking_31 THEN @min_v151mapositiontaking_31-@v151apositiontaking_31 ELSE @v151mpositiontaking_31 END,
	@v151mpositiontaking_32 = CASE WHEN @v151apositiontaking_32+@v151mpositiontaking_32<@min_v151mapositiontaking_32 THEN @min_v151mapositiontaking_32-@v151apositiontaking_32 ELSE @v151mpositiontaking_32 END,
	@v151mpositiontaking_41 = CASE WHEN @v151apositiontaking_41+@v151mpositiontaking_41<@min_v151mapositiontaking_41 THEN @min_v151mapositiontaking_41-@v151apositiontaking_41 ELSE @v151mpositiontaking_41 END,
	@v151mpositiontaking_42 = CASE WHEN @v151apositiontaking_42+@v151mpositiontaking_42<@min_v151mapositiontaking_42 THEN @min_v151mapositiontaking_42-@v151apositiontaking_42 ELSE @v151mpositiontaking_42 END

SELECT 
	@v151mpositiontaking_31 = CASE WHEN @v151mpositiontaking_31<0 THEN 0 ELSE @v151mpositiontaking_31 END,
	@v151mpositiontaking_32 = CASE WHEN @v151mpositiontaking_32<0 THEN 0 ELSE @v151mpositiontaking_32 END,
	@v151mpositiontaking_41 = CASE WHEN @v151mpositiontaking_41<0 THEN 0 ELSE @v151mpositiontaking_41 END,
	@v151mpositiontaking_42 = CASE WHEN @v151mpositiontaking_42<0 THEN 0 ELSE @v151mpositiontaking_42 END


--Must include code for auto master
--um=im1>0?um1:um2
--im=im1>0?im1:im2
--m1=im>0?min(um,m3-a1):m1
----------------------------------------------------------------------------------------------------------------------------
--auto master

--um=im1>0?um1:um2
SELECT 
	@auto_v151mpositiontaking_31 = CASE WHEN @isauto_v151mpositiontaking_mem_31>0 THEN @auto_v151mpositiontaking_mem_31 ELSE @auto_v151mpositiontaking_31 END,
	@auto_v151mpositiontaking_32 = CASE WHEN @isauto_v151mpositiontaking_mem_32>0 THEN @auto_v151mpositiontaking_mem_32 ELSE @auto_v151mpositiontaking_32 END,
	@auto_v151mpositiontaking_41 = CASE WHEN @isauto_v151mpositiontaking_mem_41>0 THEN @auto_v151mpositiontaking_mem_41 ELSE @auto_v151mpositiontaking_41 END,
	@auto_v151mpositiontaking_42 = CASE WHEN @isauto_v151mpositiontaking_mem_42>0 THEN @auto_v151mpositiontaking_mem_42 ELSE @auto_v151mpositiontaking_42 END,
	--im=im1>0?im1:im31
	@isauto_v151mpositiontaking_31 = CASE WHEN @isauto_v151mpositiontaking_mem_31>0 THEN @isauto_v151mpositiontaking_mem_31 ELSE @isauto_v151mpositiontaking_31 END,
	@isauto_v151mpositiontaking_32 = CASE WHEN @isauto_v151mpositiontaking_mem_32>0 THEN @isauto_v151mpositiontaking_mem_32 ELSE @isauto_v151mpositiontaking_32 END,
	@isauto_v151mpositiontaking_41 = CASE WHEN @isauto_v151mpositiontaking_mem_41>0 THEN @isauto_v151mpositiontaking_mem_41 ELSE @isauto_v151mpositiontaking_41 END,
	@isauto_v151mpositiontaking_42 = CASE WHEN @isauto_v151mpositiontaking_mem_42>0 THEN @isauto_v151mpositiontaking_mem_42 ELSE @isauto_v151mpositiontaking_42 END
---------------------------------------------------------------------------------------------------------------------------------------------

----------------***Use Auto Position Taking***----------------------------------
--m1=im>0?min(um,m3-a1):m1
SELECT @v151mpositiontaking_31 = CASE WHEN ISNULL(@isauto_v151mpositiontaking_31, 0)<=0 THEN @v151mpositiontaking_31 ELSE CASE WHEN @auto_v151mpositiontaking_31 < @max_v151mapositiontaking_31 - @v151apositiontaking_31 THEN @auto_v151mpositiontaking_31 ELSE @max_v151mapositiontaking_31 - @v151apositiontaking_31 END END
SELECT @v151mpositiontaking_32 = CASE WHEN ISNULL(@isauto_v151mpositiontaking_32, 0)<=0 THEN @v151mpositiontaking_32 ELSE CASE WHEN @auto_v151mpositiontaking_32 < @max_v151mapositiontaking_32 - @v151apositiontaking_32 THEN @auto_v151mpositiontaking_32 ELSE @max_v151mapositiontaking_32 - @v151apositiontaking_32 END END
SELECT @v151mpositiontaking_41 = CASE WHEN ISNULL(@isauto_v151mpositiontaking_41, 0)<=0 THEN @v151mpositiontaking_41 ELSE CASE WHEN @auto_v151mpositiontaking_41 < @max_v151mapositiontaking_41 - @v151apositiontaking_41 THEN @auto_v151mpositiontaking_41 ELSE @max_v151mapositiontaking_41 - @v151apositiontaking_41 END END
SELECT @v151mpositiontaking_42 = CASE WHEN ISNULL(@isauto_v151mpositiontaking_42, 0)<=0 THEN @v151mpositiontaking_42 ELSE CASE WHEN @auto_v151mpositiontaking_42 < @max_v151mapositiontaking_42 - @v151apositiontaking_42 THEN @auto_v151mpositiontaking_42 ELSE @max_v151mapositiontaking_42 - @v151apositiontaking_42 END END

-------------------------------------------------------------------------------
/*
--maxm1=isauto?m3:m3-a2
SELECT @max_v151mapositiontaking_31 = CASE WHEN ISNULL(@isauto_v151mpositiontaking_31, 0)>0 THEN @max_v151mapositiontaking_31 ELSE @max_v151mapositiontaking_31-@max_v151apositiontaking_31 END
SELECT @max_v151mapositiontaking_32 = CASE WHEN ISNULL(@isauto_v151mpositiontaking_32, 0)>0 THEN @max_v151mapositiontaking_32 ELSE @max_v151mapositiontaking_32-@max_v151apositiontaking_32 END
SELECT @max_v151mapositiontaking_41 = CASE WHEN ISNULL(@isauto_v151mpositiontaking_41, 0)>0 THEN @max_v151mapositiontaking_41 ELSE @max_v151mapositiontaking_41-@max_v151apositiontaking_41 END
SELECT @max_v151mapositiontaking_42 = CASE WHEN ISNULL(@isauto_v151mpositiontaking_42, 0)>0 THEN @max_v151mapositiontaking_42 ELSE @max_v151mapositiontaking_42-@max_v151apositiontaking_42 END
--m1=m1>maxm1?maxm1:m1
SELECT @v151mpositiontaking_31 = CASE WHEN @v151mpositiontaking_31 > @max_v151mapositiontaking_31 THEN @max_v151mapositiontaking_31 ELSE @v151mpositiontaking_31 END
SELECT @v151mpositiontaking_32 = CASE WHEN @v151mpositiontaking_32 > @max_v151mapositiontaking_32 THEN @max_v151mapositiontaking_32 ELSE @v151mpositiontaking_32 END
SELECT @v151mpositiontaking_41 = CASE WHEN @v151mpositiontaking_41 > @max_v151mapositiontaking_41 THEN @max_v151mapositiontaking_41 ELSE @v151mpositiontaking_41 END
SELECT @v151mpositiontaking_42 = CASE WHEN @v151mpositiontaking_42 > @max_v151mapositiontaking_42 THEN @max_v151mapositiontaking_42 ELSE @v151mpositiontaking_42 END
*/
----------------------------------------------------------------------------------------------------------------------------
-- end auto master



---------------------------------------------------------------------------------------------------------------------------------------------
--CHOOSE MEMBER AUTOPOSITIONTAKING IF MEMBER IS SET AUTO (regardless of the setting in master account)
SELECT 
	@auto_v151spositiontaking_31 = CASE WHEN @isauto_v151spositiontaking_mem_31>0 THEN @auto_v151spositiontaking_mem_31 ELSE @auto_v151spositiontaking_31 END,
	@auto_v151spositiontaking_32 = CASE WHEN @isauto_v151spositiontaking_mem_32>0 THEN @auto_v151spositiontaking_mem_32 ELSE @auto_v151spositiontaking_32 END,
	@auto_v151spositiontaking_41 = CASE WHEN @isauto_v151spositiontaking_mem_41>0 THEN @auto_v151spositiontaking_mem_41 ELSE @auto_v151spositiontaking_41 END,
	@auto_v151spositiontaking_42 = CASE WHEN @isauto_v151spositiontaking_mem_42>0 THEN @auto_v151spositiontaking_mem_42 ELSE @auto_v151spositiontaking_42 END,

	@isauto_v151spositiontaking_31 = CASE WHEN @isauto_v151spositiontaking_mem_31>0 THEN @isauto_v151spositiontaking_mem_31 ELSE @isauto_v151spositiontaking_31 END,
	@isauto_v151spositiontaking_32 = CASE WHEN @isauto_v151spositiontaking_mem_32>0 THEN @isauto_v151spositiontaking_mem_32 ELSE @isauto_v151spositiontaking_32 END,
	@isauto_v151spositiontaking_41 = CASE WHEN @isauto_v151spositiontaking_mem_41>0 THEN @isauto_v151spositiontaking_mem_41 ELSE @isauto_v151spositiontaking_41 END,
	@isauto_v151spositiontaking_42 = CASE WHEN @isauto_v151spositiontaking_mem_42>0 THEN @isauto_v151spositiontaking_mem_42 ELSE @isauto_v151spositiontaking_42 END
---------------------------------------------------------------------------------------------------------------------------------------------

----------------***Use Auto Position Taking***----------------------------------
SELECT @v151spositiontaking_31 = CASE WHEN ISNULL(@isauto_v151spositiontaking_31, 0)<=0 THEN @v151spositiontaking_31 ELSE CASE WHEN @auto_v151spositiontaking_31 < @max_v151spositiontaking_31 - @v151mpositiontaking_31 - @v151apositiontaking_31 THEN @auto_v151spositiontaking_31 ELSE @max_v151spositiontaking_31 - @v151mpositiontaking_31 - @v151apositiontaking_31 END END
SELECT @v151spositiontaking_32 = CASE WHEN ISNULL(@isauto_v151spositiontaking_32, 0)<=0 THEN @v151spositiontaking_32 ELSE CASE WHEN @auto_v151spositiontaking_32 < @max_v151spositiontaking_32 - @v151mpositiontaking_32 - @v151apositiontaking_32 THEN @auto_v151spositiontaking_32 ELSE @max_v151spositiontaking_32 - @v151mpositiontaking_32 - @v151apositiontaking_32 END END
SELECT @v151spositiontaking_41 = CASE WHEN ISNULL(@isauto_v151spositiontaking_41, 0)<=0 THEN @v151spositiontaking_41 ELSE CASE WHEN @auto_v151spositiontaking_41 < @max_v151spositiontaking_41 - @v151mpositiontaking_41 - @v151apositiontaking_41 THEN @auto_v151spositiontaking_41 ELSE @max_v151spositiontaking_41 - @v151mpositiontaking_41 - @v151apositiontaking_41 END END
SELECT @v151spositiontaking_42 = CASE WHEN ISNULL(@isauto_v151spositiontaking_42, 0)<=0 THEN @v151spositiontaking_42 ELSE CASE WHEN @auto_v151spositiontaking_42 < @max_v151spositiontaking_42 - @v151mpositiontaking_42 - @v151apositiontaking_42 THEN @auto_v151spositiontaking_42 ELSE @max_v151spositiontaking_42 - @v151mpositiontaking_42 - @v151apositiontaking_42 END END

-------------------------------------------------------------------------------
--maxs1=isauto?s4:s4-m2
SELECT @max_v151spositiontaking_31 = CASE WHEN ISNULL(@isauto_v151spositiontaking_31, 0)>0 THEN @max_v151spositiontaking_31 ELSE @max_v151spositiontaking_31-@max_v151mapositiontaking_31 END
SELECT @max_v151spositiontaking_32 = CASE WHEN ISNULL(@isauto_v151spositiontaking_32, 0)>0 THEN @max_v151spositiontaking_32 ELSE @max_v151spositiontaking_32-@max_v151mapositiontaking_32 END
SELECT @max_v151spositiontaking_41 = CASE WHEN ISNULL(@isauto_v151spositiontaking_41, 0)>0 THEN @max_v151spositiontaking_41 ELSE @max_v151spositiontaking_41-@max_v151mapositiontaking_41 END
SELECT @max_v151spositiontaking_42 = CASE WHEN ISNULL(@isauto_v151spositiontaking_42, 0)>0 THEN @max_v151spositiontaking_42 ELSE @max_v151spositiontaking_42-@max_v151mapositiontaking_42 END
--s1=s1>maxs1?maxs1:s1
SELECT @v151spositiontaking_31 = CASE WHEN @v151spositiontaking_31 > @max_v151spositiontaking_31 THEN @max_v151spositiontaking_31 ELSE @v151spositiontaking_31 END
SELECT @v151spositiontaking_32 = CASE WHEN @v151spositiontaking_32 > @max_v151spositiontaking_32 THEN @max_v151spositiontaking_32 ELSE @v151spositiontaking_32 END
SELECT @v151spositiontaking_41 = CASE WHEN @v151spositiontaking_41 > @max_v151spositiontaking_41 THEN @max_v151spositiontaking_41 ELSE @v151spositiontaking_41 END
SELECT @v151spositiontaking_42 = CASE WHEN @v151spositiontaking_42 > @max_v151spositiontaking_42 THEN @max_v151spositiontaking_42 ELSE @v151spositiontaking_42 END

--don't update m1,s1 for member under agent was set im2=1
UPDATE cs WITH (ROWLOCK, UPDLOCK)
SET
	mpositiontaking = CASE cs.bettype WHEN 31 THEN @v151mpositiontaking_31 WHEN 32 THEN @v151mpositiontaking_32 WHEN 41 THEN @v151mpositiontaking_41 WHEN 42 THEN @v151mpositiontaking_42 ELSE cs.mpositiontaking END,
	spositiontaking =  CASE cs.bettype WHEN 31 THEN @v151spositiontaking_31 WHEN 32 THEN @v151spositiontaking_32 WHEN 41 THEN @v151spositiontaking_41 WHEN 42 THEN @v151spositiontaking_42 ELSE cs.spositiontaking END
FROM CustSetting3rd cs INNER JOIN custinfo c WITH(NOLOCK) ON cs.custid = c.custid
	INNER JOIN CustSetting3rd acs WITH(NOLOCK) ON acs.custid = c.recommend AND cs.sporttype = acs.sporttype AND cs.bettype = acs.bettype 
WHERE c.custid=@custid AND c.roleid = 1 AND acs.isautompositiontaking = 0 AND cs.sporttype = 151 


--Update auto PT
--------------------------------------------------------
--Update Member account (autompositiontaking field)
update CustSetting3rd with (ROWLOCK, UPDLOCK) set autompositiontaking = b.autompositiontaking, isautompositiontaking = b.isautompositiontaking
from CustSetting3rd as cs inner join 
		(
						select 31 as bettype, 151 as sporttype, @auto_v151mpositiontaking_mem_31 as autompositiontaking, @isauto_v151mpositiontaking_mem_31 as isautompositiontaking
			union all 	select 32 as bettype, 151 as sporttype, @auto_v151mpositiontaking_mem_32 as autompositiontaking, @isauto_v151mpositiontaking_mem_32 as isautompositiontaking
			union all 	select 41 as bettype, 151 as sporttype, @auto_v151mpositiontaking_mem_41 as autompositiontaking, @isauto_v151mpositiontaking_mem_41 as isautompositiontaking
			union all 	select 42 as bettype, 151 as sporttype, @auto_v151mpositiontaking_mem_42 as autompositiontaking, @isauto_v151mpositiontaking_mem_42 as isautompositiontaking
		
		) as b on b.bettype = cs.bettype and b.sporttype = cs.sporttype
where cs.custid = @custid
if @@Error <> 0
BEGIN
	
	SELECT @ErrCode_cur = 101,
			@ErrMsg_cur =  
					case @Language 
						when 'E' then 'Error updating auto positiontaking'
						when 'CS' then N'更新占成数不成功'
						when 'CT' then N'更新佔成數不成功'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์'
						when 'J' then N'Error updating auto positiontaking'
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다.'
						else N'Error updating auto positiontaking'
					end	
	SELECT  @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
			@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
	return
END
	
if @isauto_v151mpositiontaking_31 >0
BEGIN
	select @maxpos = mpositiontaking from CustSetting3rd with (NOLOCK) where custid = @mrecommend and sporttype=151 and bettype = 31
	update CustSetting3rd with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@auto_v151mpositiontaking_31 then @auto_v151mpositiontaking_31 else @maxpos - apositiontaking end
	from CustSetting3rd as cs
	where custid = @custid and cs.bettype = 31 and cs.sporttype = 151
	if @@Error <> 0
	BEGIN
		SELECT @ErrCode_cur = 110,
				@ErrMsg_cur =  
						case @Language 
							when 'E' then 'Error updating auto positiontaking (for Other sports)'
							when 'CS' then N'更新占成数不成功(于其他)'
							when 'CT' then N'更新佔成數不成功(於其他'
							when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาอื่นๆ)'
							when 'J' then N'Error updating auto positiontaking (for Other sports)'
							when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (기타 스포츠)'
							else N'Error updating auto positiontaking (for Other sports)'
						end	
		SELECT  @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
				@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
		return
	END
END

if @isauto_v151mpositiontaking_32 >0
BEGIN
	select @maxpos = mpositiontaking from CustSetting3rd with (NOLOCK) where custid = @mrecommend and sporttype=151 and bettype = 32
	update CustSetting3rd with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@auto_v151mpositiontaking_32 then @auto_v151mpositiontaking_32 else @maxpos - apositiontaking end
	from CustSetting3rd as cs
	where custid = @custid and cs.bettype = 32 and cs.sporttype = 151
	if @@Error <> 0
	BEGIN
		SELECT @ErrCode_cur = 110,
				@ErrMsg_cur =  
						case @Language 
							when 'E' then 'Error updating auto positiontaking (for Other sports)'
							when 'CS' then N'更新占成数不成功(于其他)'
							when 'CT' then N'更新佔成數不成功(於其他'
							when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาอื่นๆ)'
							when 'J' then N'Error updating auto positiontaking (for Other sports)'
							when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (기타 스포츠)'
							else N'Error updating auto positiontaking (for Other sports)'
						end	
		SELECT @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
				@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)			
		return
	END
END
if @isauto_v151mpositiontaking_41 >0
BEGIN
	select @maxpos = mpositiontaking from CustSetting3rd with (NOLOCK) where custid = @mrecommend and sporttype=151 and bettype = 41
	update CustSetting3rd with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@auto_v151mpositiontaking_41 then @auto_v151mpositiontaking_41 else @maxpos - apositiontaking end
	from CustSetting3rd as cs
	where custid = @custid and cs.bettype = 41 and cs.sporttype = 151
	if @@Error <> 0
	BEGIN
		SELECT @ErrCode_cur = 110,
				@ErrMsg_cur =  
						case @Language 
							when 'E' then 'Error updating auto positiontaking (for Other sports)'
							when 'CS' then N'更新占成数不成功(于其他)'
							when 'CT' then N'更新佔成數不成功(於其他'
							when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาอื่นๆ)'
							when 'J' then N'Error updating auto positiontaking (for Other sports)'
							when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (기타 스포츠)'
							else N'Error updating auto positiontaking (for Other sports)'
						end	
		SELECT  @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
				@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
		return
	END
END
if @isauto_v151mpositiontaking_42 >0
BEGIN
	select @maxpos = mpositiontaking from CustSetting3rd with (NOLOCK) where custid = @mrecommend and sporttype=151 and bettype = 42
	update CustSetting3rd with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@auto_v151mpositiontaking_42 then @auto_v151mpositiontaking_42 else @maxpos - apositiontaking end
	from CustSetting3rd as cs
	where custid = @custid and cs.bettype = 42 and cs.sporttype = 151
	if @@Error <> 0
	BEGIN
		SELECT @ErrCode_cur = 110,
				@ErrMsg_cur =  
						case @Language 
							when 'E' then 'Error updating auto positiontaking (for Other sports)'
							when 'CS' then N'更新占成数不成功(于其他)'
							when 'CT' then N'更新佔成數不成功(於其他'
							when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาอื่นๆ)'
							when 'J' then N'Error updating auto positiontaking (for Other sports)'
							when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (기타 스포츠)'
							else N'Error updating auto positiontaking (for Other sports)'
						end	
		SELECT  @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
				@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
		return
	END
END


EXEC dbo.Acc_CustomerUpdMemberHR_MinMaxPositiontaking @custid = @custid, @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @LogSPData VARCHAR(5000)

Select @LogSPData = '<Acc_CustomerUpdMemberHR_MAg><info custid="'+ COALESCE(CAST(@CustID AS VARCHAR(50)),SPACE(1)) + '" ' +
'UserID="'+ COALESCE(CAST(@UserID AS VARCHAR(50)),SPACE(1)) + '" ' +
'Language="'+ COALESCE(CAST(@Language AS VARCHAR(2)),SPACE(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),SPACE(1)) + '" ' +
'IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1)) + '" ' +
'ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) + '" ' +
'ErrMsg="'+ COALESCE(CAST(@ErrMsg AS VARCHAR(5000)),SPACE(1)) + '" />' +

'<m v151mpt_31="'+ coalesce(cast(@v151mpositiontaking_31 as varchar(50)),space(1)) + '" ' +
'v151mpt_32="'+ coalesce(cast(@v151mpositiontaking_32 as varchar(50)),SPACE(1)) + '" ' +
'v151mpt_41="'+ coalesce(cast(@v151mpositiontaking_41 as varchar(50)),SPACE(1)) + '" ' +
'v151mpt_42="'+ coalesce(cast(@v151mpositiontaking_42 as varchar(50)),space(1)) + '" />' +

'<iam isa_v151mpt_31="'+ coalesce(cast(@isauto_v151mpositiontaking_31 as varchar(50)),SPACE(1)) + '" ' +
'isa_v151mpt_32="'+ coalesce(cast(@isauto_v151mpositiontaking_32 as varchar(50)),SPACE(1)) + '" ' +
'isa_v151mpt_41="'+ coalesce(cast(@isauto_v151mpositiontaking_41 as varchar(50)),SPACE(1)) + '" ' +
'isa_v151mpt_42="'+ coalesce(cast(@isauto_v151mpositiontaking_42 as varchar(50)),space(1)) + '" />' +

'<iame isa_v151mpt_mem_31="'+ coalesce(cast(@isauto_v151mpositiontaking_mem_31 as varchar(50)),SPACE(1)) + '" ' +
'isa_v151mpt_mem_32="'+ coalesce(cast(@isauto_v151mpositiontaking_mem_32 as varchar(50)),SPACE(1)) + '" ' +
'isa_v151mpt_mem_41="'+ coalesce(cast(@isauto_v151mpositiontaking_mem_41 as varchar(50)),SPACE(1)) + '" ' +
'isa_v151mpt_mem_42="'+ coalesce(cast(@isauto_v151mpositiontaking_mem_42 as varchar(50)),space(1)) + '" />' +

'<aume a_v151mpt_mem_31="'+ coalesce(cast(@auto_v151mpositiontaking_mem_31 as varchar(50)),SPACE(1)) + '" ' +
'a_v151mpt_mem_32="'+ coalesce(cast(@auto_v151mpositiontaking_mem_32 as varchar(50)),space(1)) + '" ' +
'a_v151mpt_mem_41="'+ coalesce(cast(@auto_v151mpositiontaking_mem_41 as varchar(50)),SPACE(1)) + '" ' +
'a_v151mpt_mem_42="'+ coalesce(cast(@auto_v151mpositiontaking_mem_42 as varchar(50)),space(1)) + '" /></Acc_CustomerUpdMemberHR_MAg>'

Select @ErrCode = @ErrCode + '-107'+char(7), @ErrMsg = @ErrMsg + char(7)

--Log positiontaking
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 409,
	@TrackingValue = @LogSPData

GO 
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMemberHR_MAg] TO [bodbAdminNet]
GO 
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMemberHR_MAg] TO [bodbExtAccNet]
GO 
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMemberHR_MAg] TO [vnteam]
GO 
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMemberHR_MAg] TO [bodbDownlineNet]