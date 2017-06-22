
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Acc_CustomerUpdMemberFI_MAg    Script Date: 8/6/2009 8:08:10 PM ******/
ALTER PROCEDURE [dbo].Acc_CustomerUpdMemberFI_MAg
	@CustID INT,--memberid
	--m1
	@v201mpositiontaking_2 SMALLMONEY OUTPUT,
	@v201mpositiontaking_3 SMALLMONEY OUTPUT,
	--im2
	@isauto_v201mpositiontaking_2 BIT = 0,
	@isauto_v201mpositiontaking_3 BIT = 0,	
	
	--im1
	@isauto_v201mpositiontaking_mem_2 BIT = 0,
	@isauto_v201mpositiontaking_mem_3 BIT = 0,	

	--um1
	@auto_v201mpositiontaking_mem_2 SMALLMONEY = 0,
	@auto_v201mpositiontaking_mem_3 SMALLMONEY = 0,	

	@UserID INT,--masterid	
	@Language VARCHAR(2) = 'E',
	@SubAccID INT = 0, --Sub-AccountID
	@IP VARCHAR(15)='',
	@Username varchar(30) = '' OUTPUT,
	@ErrCode varchar(300) = '' OUTPUT,
	@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20090415@Phuc
Task : Master edit member(FI)
DB: DB02.bodb02
Original: [Acc_CustomerUpdMaster_Member]

Revisions:
    - 20090616@Phuc: Auto master PT on member level.
					 Enrich error message.(-101: general info, -102: closed, -103: suspended, 
						-104: credit, -105: commission, -106: min/max bet, -107: positiontaking
						-108: disable FI, -109: disableHR)
	- 20090723@Phuc: Write log subaccname instead of subaccid.
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
/*
if not exists (select 1 from custinfo with (nolock) where custid = @custid and srecommend in (181940,197461))
BEGIN
	declare @ErrMsg varchar(200)
	Select @ErrMsg = 'Sorry, please try again later.'
	RaisError (@ErrMsg, 16, 1)
	return
END
*/
DECLARE @ErrType varchar(1000), @roleid tinyint, @ErrCode_cur int, @ErrMsg_cur NVARCHAR(4000)
SELECT @ErrCode_cur = 0, @ErrMsg_cur = '', @ErrCode = '', @ErrMsg = ''

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

 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Check parameter
IF @v201mpositiontaking_2 < 0
	OR @v201mpositiontaking_3 < 0
	OR @v201mpositiontaking_2 > 0.9
	OR @v201mpositiontaking_3 > 0.9
	
	OR @auto_v201mpositiontaking_mem_2 < 0
	OR @auto_v201mpositiontaking_mem_3 < 0
	OR @auto_v201mpositiontaking_mem_2 > 0.9
	OR @auto_v201mpositiontaking_mem_3 > 0.9
BEGIN
	SELECT @ErrCode_cur = 5
	SELECT @ErrMsg_cur = 	CASE @Language 
						WHEN 'E' THEN 'Wrong position taking.'
						WHEN 'CS' THEN N'占成数不正确.'
						WHEN 'CT' THEN N'佔成數不正確.'
						WHEN 'TH' THEN N'การกำหนดไม่ถูกต้อง.'
						WHEN 'J' THEN N'Wrong position taking.'
						WHEN 'KO' THEN N'거래 조건이 잘못 되었습니다.'
						ELSE N'Wrong position taking.'
				END
	SELECT @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
		@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
	RETURN
END


DECLARE 
	--a1
	@v201apositiontaking_2 SMALLMONEY,
	@v201apositiontaking_3 SMALLMONEY,
	
	--a2
	@max_v201apositiontaking_2 SMALLMONEY,
	@max_v201apositiontaking_3 SMALLMONEY,
	
	--old_m1	
	@old_v201mpositiontaking_2 SMALLMONEY,
	@old_v201mpositiontaking_3 SMALLMONEY,
	
	--old_um1
	@old_auto_v201mpositiontaking_mem_2 SMALLMONEY,
	@old_auto_v201mpositiontaking_mem_3 SMALLMONEY,
	
	--old_im1
	@old_isauto_v201mpositiontaking_mem_2 BIT,
	@old_isauto_v201mpositiontaking_mem_3 BIT,


	@maxpos smallmoney,
	--s4
	@max_v201spositiontaking_2 SMALLMONEY,
	@max_v201spositiontaking_3 SMALLMONEY,
	
	@v201spositiontaking_2 SMALLMONEY,
	@v201spositiontaking_3 SMALLMONEY,
	
	@recommend INT,
	@mrecommend INT,
	@srecommend INT,
	
	--u1
	@auto_v201spositiontaking_mem_2 SMALLMONEY,
	@auto_v201spositiontaking_mem_3 SMALLMONEY,
	--i1
	@isauto_v201spositiontaking_mem_2 BIT,
	@isauto_v201spositiontaking_mem_3 BIT,
	--u3
	@auto_v201spositiontaking_2 SMALLMONEY,
	@auto_v201spositiontaking_3 SMALLMONEY,
	
	--i3
	@isauto_v201spositiontaking_2 BIT,
	@isauto_v201spositiontaking_3 BIT,
	
	--um2
	@auto_v201mpositiontaking_2 SMALLMONEY ,
	@auto_v201mpositiontaking_3 SMALLMONEY

DECLARE
	@max_v201mapositiontaking_2 SMALLMONEY,
	@max_v201mapositiontaking_3 SMALLMONEY
	
DECLARE
	@min_v201mapositiontaking_2 SMALLMONEY,
	@min_v201mapositiontaking_3 SMALLMONEY

SELECT @recommend = recommend, @mrecommend = mrecommend, @srecommend = srecommend, @UserName = username
FROM custinfo WITH (NOLOCK) WHERE custid = @custid
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
SELECT	@v201spositiontaking_2	=	spositiontaking,	@v201apositiontaking_2	=	apositiontaking,	@auto_v201spositiontaking_mem_2	=	autopositiontaking,	@isauto_v201spositiontaking_mem_2	=	isautopositiontaking,	@old_v201mpositiontaking_2	=	mpositiontaking	,	@old_auto_v201mpositiontaking_mem_2	=	autompositiontaking	,	@old_isauto_v201mpositiontaking_mem_2	=	isautompositiontaking	FROM	CustSetting3rd	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=2	AND	sporttype=201																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v201spositiontaking_3	=	spositiontaking,	@v201apositiontaking_3	=	apositiontaking,	@auto_v201spositiontaking_mem_3	=	autopositiontaking,	@isauto_v201spositiontaking_mem_3	=	isautopositiontaking,	@old_v201mpositiontaking_3	=	mpositiontaking	,	@old_auto_v201mpositiontaking_mem_3	=	autompositiontaking	,	@old_isauto_v201mpositiontaking_mem_3	=	isautompositiontaking	FROM	CustSetting3rd	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=3	AND	sporttype=201																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												

--Check if old_PT = new_PT return
IF @v201mpositiontaking_2 = @old_v201mpositiontaking_2 AND
	@v201mpositiontaking_3 = @old_v201mpositiontaking_3 AND
	--um1
	@auto_v201mpositiontaking_mem_2 = @old_auto_v201mpositiontaking_mem_2 AND
	@auto_v201mpositiontaking_mem_3 = @old_auto_v201mpositiontaking_mem_3 AND
	--im1
	@isauto_v201mpositiontaking_mem_2 = @old_isauto_v201mpositiontaking_mem_2 AND
	@isauto_v201mpositiontaking_mem_3 = @old_isauto_v201mpositiontaking_mem_3 
BEGIN
	Select @ErrCode = @ErrCode + '-107'+char(7), @ErrMsg = @ErrMsg + char(7)
	RETURN 
END

--Check um1<=l3
	SELECT @ErrType = ''
	SELECT @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ CAST((co.maxpositiontaking) AS VARCHAR(10))
	FROM CustOverride3rd AS co WITH (NOLOCK) INNER JOIN
		(
							SELECT 201 AS sporttype, 2 AS bettype, @auto_v201mpositiontaking_mem_2 AS autopositiontaking, @isauto_v201mpositiontaking_mem_2 AS isautopositiontaking
			UNION ALL		SELECT 201 AS sporttype, 3 AS bettype, @auto_v201mpositiontaking_mem_3 AS autopositiontaking, @isauto_v201mpositiontaking_mem_3 AS isautopositiontaking
			
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
	SELECT @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
		   @ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
			
	RETURN
END

--Check um1<=m3
	SELECT @ErrType = ''
	SELECT @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ CAST((mcs.mpositiontaking) AS VARCHAR(10))
	FROM CustSetting3rd AS mcs WITH (NOLOCK) INNER JOIN
		(
							SELECT 201 AS sporttype, 2 AS bettype, @auto_v201mpositiontaking_mem_2 AS autopositiontaking, @isauto_v201mpositiontaking_mem_2 AS isautopositiontaking
			UNION ALL		SELECT 201 AS sporttype, 3 AS bettype, @auto_v201mpositiontaking_mem_3 AS autopositiontaking, @isauto_v201mpositiontaking_mem_3 AS isautopositiontaking
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
	SELECT @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
		@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
											
	RETURN
END

--m3,u3,i3
SELECT @max_v201mapositiontaking_2 =mpositiontaking, @auto_v201spositiontaking_2 = autopositiontaking, @isauto_v201spositiontaking_2 = isautopositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=201
SELECT @max_v201mapositiontaking_3 =mpositiontaking, @auto_v201spositiontaking_3 = autopositiontaking, @isauto_v201spositiontaking_3 = isautopositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=201
--n3
SELECT @min_v201mapositiontaking_2 = minpositiontaking FROM CustOverride3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=201
SELECT @min_v201mapositiontaking_3 = minpositiontaking FROM CustOverride3rd WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=201

--s4
SELECT @max_v201spositiontaking_2 = spositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND bettype=2 AND sporttype=201
SELECT @max_v201spositiontaking_3 = spositiontaking FROM CustSetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND bettype=3 AND sporttype=201

--um2
SELECT 
	@auto_v201mpositiontaking_2 = MAX(CASE WHEN acs.bettype = 2 AND acs.sporttype=201 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v201mpositiontaking_3 = MAX(CASE WHEN acs.bettype = 3 AND acs.sporttype=201 THEN acs.autompositiontaking ELSE 0 END),
	--a2	
	@max_v201apositiontaking_2 = MAX(CASE WHEN acs.bettype = 2 AND acs.sporttype=201 THEN acs.apositiontaking ELSE 0 END),
	@max_v201apositiontaking_3 = MAX(CASE WHEN acs.bettype = 3 AND acs.sporttype=201 THEN acs.apositiontaking ELSE 0 END)
FROM CustSetting3rd acs WITH(NOLOCK)
WHERE acs.custid = @recommend


--Check m1<=m3
SELECT @ErrType = ''
SELECT @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ CAST((b.maxmpositiontaking) AS VARCHAR(10))
FROM (
						SELECT 201 AS sporttype	,	 2 AS bettype	,	 @v201mpositiontaking_2 AS mpositiontaking	,	 @max_v201mapositiontaking_2 AS maxmpositiontaking
		UNION ALL		SELECT 201 AS sporttype	,	 3 AS bettype	,	 @v201mpositiontaking_3 AS mpositiontaking	,	 @max_v201mapositiontaking_3 AS maxmpositiontaking
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
	SELECT @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
		   @ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
											
	RETURN
END
--Check m1<=l3
SELECT @ErrType = ''
SELECT @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ CAST((co.maxpositiontaking) AS VARCHAR(10))
	FROM CustOverride3rd AS co WITH (NOLOCK) INNER JOIN
		(
							SELECT 201 AS sporttype	,	 2 AS bettype	,	 @v201mpositiontaking_2 AS mpositiontaking
			UNION ALL		SELECT 201 AS sporttype	,	 3 AS bettype	,	 @v201mpositiontaking_3 AS mpositiontaking
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
	SELECT @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
		@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
				
	RETURN
END

--m1=m1+a1>m3?m3-a1:m1
SELECT 
	@v201mpositiontaking_2 = CASE WHEN @v201apositiontaking_2+@v201mpositiontaking_2>@max_v201mapositiontaking_2 THEN @max_v201mapositiontaking_2-@v201apositiontaking_2 ELSE @v201mpositiontaking_2 END,
	@v201mpositiontaking_3 = CASE WHEN @v201apositiontaking_3+@v201mpositiontaking_3>@max_v201mapositiontaking_3 THEN @max_v201mapositiontaking_3-@v201apositiontaking_3 ELSE @v201mpositiontaking_3 END

--m1=m1+a1<n2?n2-a1:m1
SELECT 
	@v201mpositiontaking_2 = CASE WHEN @v201apositiontaking_2+@v201mpositiontaking_2<@min_v201mapositiontaking_2 THEN @min_v201mapositiontaking_2-@v201apositiontaking_2 ELSE @v201mpositiontaking_2 END,
	@v201mpositiontaking_3 = CASE WHEN @v201apositiontaking_3+@v201mpositiontaking_3<@min_v201mapositiontaking_3 THEN @min_v201mapositiontaking_3-@v201apositiontaking_3 ELSE @v201mpositiontaking_3 END

SELECT 
	@v201mpositiontaking_2 = CASE WHEN @v201mpositiontaking_2<0 THEN 0 ELSE @v201mpositiontaking_2 END,
	@v201mpositiontaking_3 = CASE WHEN @v201mpositiontaking_3<0 THEN 0 ELSE @v201mpositiontaking_3 END


--Must include code for auto master
--um=im1>0?um1:um2
--im=im1>0?im1:im2
--m1=im>0?min(um,m3-a1):m1
----------------------------------------------------------------------------------------------------------------------------
--auto master

--um=im1>0?um1:um2
SELECT 
	@auto_v201mpositiontaking_2 = CASE WHEN @isauto_v201mpositiontaking_mem_2>0 THEN @auto_v201mpositiontaking_mem_2 ELSE @auto_v201mpositiontaking_2 END,
	@auto_v201mpositiontaking_3 = CASE WHEN @isauto_v201mpositiontaking_mem_3>0 THEN @auto_v201mpositiontaking_mem_3 ELSE @auto_v201mpositiontaking_3 END,
	--im=im1>0?im1:im2
	@isauto_v201mpositiontaking_2 = CASE WHEN @isauto_v201mpositiontaking_mem_2>0 THEN @isauto_v201mpositiontaking_mem_2 ELSE @isauto_v201mpositiontaking_2 END,
	@isauto_v201mpositiontaking_3 = CASE WHEN @isauto_v201mpositiontaking_mem_3>0 THEN @isauto_v201mpositiontaking_mem_3 ELSE @isauto_v201mpositiontaking_3 END
---------------------------------------------------------------------------------------------------------------------------------------------

----------------***Use Auto Position Taking***----------------------------------
--m1=im>0?min(um,m3-a1):m1
SELECT @v201mpositiontaking_2 = CASE WHEN ISNULL(@isauto_v201mpositiontaking_2, 0)<=0 THEN @v201mpositiontaking_2 ELSE CASE WHEN @auto_v201mpositiontaking_2 < @max_v201mapositiontaking_2 - @v201apositiontaking_2 THEN @auto_v201mpositiontaking_2 ELSE @max_v201mapositiontaking_2 - @v201apositiontaking_2 END END
SELECT @v201mpositiontaking_3 = CASE WHEN ISNULL(@isauto_v201mpositiontaking_3, 0)<=0 THEN @v201mpositiontaking_3 ELSE CASE WHEN @auto_v201mpositiontaking_3 < @max_v201mapositiontaking_3 - @v201apositiontaking_3 THEN @auto_v201mpositiontaking_3 ELSE @max_v201mapositiontaking_3 - @v201apositiontaking_3 END END

/*
-------------------------------------------------------------------------------
--maxm1=isauto?m3:m2-a2
SELECT @max_v201mapositiontaking_2 = CASE WHEN ISNULL(@isauto_v201mpositiontaking_2, 0)>0 THEN @max_v201mapositiontaking_2 ELSE @max_v201mapositiontaking_2-@max_v201apositiontaking_2 END
SELECT @max_v201mapositiontaking_3 = CASE WHEN ISNULL(@isauto_v201mpositiontaking_3, 0)>0 THEN @max_v201mapositiontaking_3 ELSE @max_v201mapositiontaking_3-@max_v201apositiontaking_3 END
--m1=m1>maxm1?maxm1:m1
SELECT @v201mpositiontaking_2 = CASE WHEN @v201mpositiontaking_2 > @max_v201mapositiontaking_2 THEN @max_v201mapositiontaking_2 ELSE @v201mpositiontaking_2 END
SELECT @v201mpositiontaking_3 = CASE WHEN @v201mpositiontaking_3 > @max_v201mapositiontaking_3 THEN @max_v201mapositiontaking_3 ELSE @v201mpositiontaking_3 END
*/

----------------------------------------------------------------------------------------------------------------------------
-- end auto master



---------------------------------------------------------------------------------------------------------------------------------------------
--CHOOSE MEMBER AUTOPOSITIONTAKING IF MEMBER IS SET AUTO (regardless of the setting in master account)
SELECT 
	@auto_v201spositiontaking_2 = CASE WHEN @isauto_v201spositiontaking_mem_2>0 THEN @auto_v201spositiontaking_mem_2 ELSE @auto_v201spositiontaking_2 END,
	@auto_v201spositiontaking_3 = CASE WHEN @isauto_v201spositiontaking_mem_3>0 THEN @auto_v201spositiontaking_mem_3 ELSE @auto_v201spositiontaking_3 END,

	@isauto_v201spositiontaking_2 = CASE WHEN @isauto_v201spositiontaking_mem_2>0 THEN @isauto_v201spositiontaking_mem_2 ELSE @isauto_v201spositiontaking_2 END,
	@isauto_v201spositiontaking_3 = CASE WHEN @isauto_v201spositiontaking_mem_3>0 THEN @isauto_v201spositiontaking_mem_3 ELSE @isauto_v201spositiontaking_3 END
---------------------------------------------------------------------------------------------------------------------------------------------

----------------***Use Auto Position Taking***----------------------------------
SELECT @v201spositiontaking_2 = CASE WHEN ISNULL(@isauto_v201spositiontaking_2, 0)<=0 THEN @v201spositiontaking_2 ELSE CASE WHEN @auto_v201spositiontaking_2 < @max_v201spositiontaking_2 - @v201mpositiontaking_2 - @v201apositiontaking_2 THEN @auto_v201spositiontaking_2 ELSE @max_v201spositiontaking_2 - @v201mpositiontaking_2 - @v201apositiontaking_2 END END
SELECT @v201spositiontaking_3 = CASE WHEN ISNULL(@isauto_v201spositiontaking_3, 0)<=0 THEN @v201spositiontaking_3 ELSE CASE WHEN @auto_v201spositiontaking_3 < @max_v201spositiontaking_3 - @v201mpositiontaking_3 - @v201apositiontaking_3 THEN @auto_v201spositiontaking_3 ELSE @max_v201spositiontaking_3 - @v201mpositiontaking_3 - @v201apositiontaking_3 END END

-------------------------------------------------------------------------------
--maxs1=isauto?s4:s4-m2
SELECT @max_v201spositiontaking_2 = CASE WHEN ISNULL(@isauto_v201spositiontaking_2, 0)>0 THEN @max_v201spositiontaking_2 ELSE @max_v201spositiontaking_2-@max_v201mapositiontaking_2 END
SELECT @max_v201spositiontaking_3 = CASE WHEN ISNULL(@isauto_v201spositiontaking_3, 0)>0 THEN @max_v201spositiontaking_3 ELSE @max_v201spositiontaking_3-@max_v201mapositiontaking_3 END
--s1=s1>maxs1?maxs1:s1
SELECT @v201spositiontaking_2 = CASE WHEN @v201spositiontaking_2 > @max_v201spositiontaking_2 THEN @max_v201spositiontaking_2 ELSE @v201spositiontaking_2 END
SELECT @v201spositiontaking_3 = CASE WHEN @v201spositiontaking_3 > @max_v201spositiontaking_3 THEN @max_v201spositiontaking_3 ELSE @v201spositiontaking_3 END

--don't update m1,s1 for member under agent was set im2=1
UPDATE cs WITH (ROWLOCK, UPDLOCK)
SET
	mpositiontaking = CASE cs.bettype WHEN 2 THEN @v201mpositiontaking_2 WHEN 3 THEN @v201mpositiontaking_3 else cs.mpositiontaking END,
	spositiontaking =  CASE cs.bettype WHEN 2 THEN @v201spositiontaking_2 WHEN 3 THEN @v201spositiontaking_3 else cs.spositiontaking END
FROM CustSetting3rd cs INNER JOIN custinfo c WITH(NOLOCK) ON cs.custid = c.custid
	INNER JOIN CustSetting3rd acs WITH(NOLOCK) ON acs.custid = c.recommend AND cs.sporttype = acs.sporttype AND cs.bettype = acs.bettype 
WHERE c.custid=@custid AND c.roleid = 1 AND acs.isautompositiontaking = 0 AND cs.sporttype = 201 


--Update auto PT
--------------------------------------------------------
--Update Member account (autompositiontaking field)
update CustSetting3rd with (ROWLOCK, UPDLOCK) set autompositiontaking = b.autompositiontaking, isautompositiontaking = b.isautompositiontaking
from CustSetting3rd as cs inner join 
		(
						select 2 as bettype, 201 as sporttype, @auto_v201mpositiontaking_mem_2 as autompositiontaking, @isauto_v201mpositiontaking_mem_2 as isautompositiontaking
			union all 	select 3 as bettype, 201 as sporttype, @auto_v201mpositiontaking_mem_3 as autompositiontaking, @isauto_v201mpositiontaking_mem_3 as isautompositiontaking
		
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
	SELECT @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
		@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
					
	return
END
	
if @isauto_v201mpositiontaking_2 >0
BEGIN
	select @maxpos = mpositiontaking from CustSetting3rd with (NOLOCK) where custid = @mrecommend and sporttype=201 and bettype = 2
	update CustSetting3rd with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@auto_v201mpositiontaking_2 then @auto_v201mpositiontaking_2 else @maxpos - apositiontaking end
	from CustSetting3rd as cs
	where custid = @custid and cs.bettype = 2 and cs.sporttype = 201
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

if @isauto_v201mpositiontaking_3 >0
BEGIN
	select @maxpos = mpositiontaking from CustSetting3rd with (NOLOCK) where custid = @mrecommend and sporttype=201 and bettype = 3
	update CustSetting3rd with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@auto_v201mpositiontaking_3 then @auto_v201mpositiontaking_3 else @maxpos - apositiontaking end
	from CustSetting3rd as cs
	where custid = @custid and cs.bettype = 3 and cs.sporttype = 201
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


EXEC dbo.Acc_CustomerUpdMemberFI_MinMaxPositiontaking @custid = @custid, @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend

--Log customer info
DECLARE @LogSPData VARCHAR(5000)

Select @LogSPData = '<Acc_CustomerUpdMemberFI_MAg><info custid="'+ COALESCE(CAST(@CustID AS VARCHAR(50)),SPACE(1)) + '" ' +
'UserID="'+ COALESCE(CAST(@UserID AS VARCHAR(50)),SPACE(1)) + '" ' +
'Language="'+ COALESCE(CAST(@Language AS VARCHAR(2)),SPACE(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),SPACE(1)) + '" ' +
'IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1)) + '" ' +
'ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) + '" ' +
'ErrMsg="'+ COALESCE(CAST(@ErrMsg AS VARCHAR(5000)),SPACE(1)) + '" />' +

'<m v201mpt_2="'+ coalesce(cast(@v201mpositiontaking_2 as varchar(50)),SPACE(1)) + '" ' +
'v201mpt_3="'+ coalesce(cast(@v201mpositiontaking_3 as varchar(50)),space(1)) + '" />' +

'<iam isa_v201mpt_2="'+ coalesce(cast(@isauto_v201mpositiontaking_2 as varchar(50)),SPACE(1)) + '" ' +
'isa_v201mpt_3="'+ coalesce(cast(@isauto_v201mpositiontaking_3 as varchar(50)),space(1)) + '" />' +

'<iame isa_v201mpt_mem_2="'+ coalesce(cast(@isauto_v201mpositiontaking_mem_2 as varchar(50)),SPACE(1)) + '" ' +
'isa_v201mpt_mem_3="'+ coalesce(cast(@isauto_v201mpositiontaking_mem_3 as varchar(50)),space(1)) + '" />' +

'<aume a_v201mpt_mem_2="'+ coalesce(cast(@auto_v201mpositiontaking_mem_2 as varchar(50)),SPACE(1)) + '" ' +
'a_v201mpt_mem_3="'+ coalesce(cast(@auto_v201mpositiontaking_mem_3 as varchar(50)),space(1)) + '" /></Acc_CustomerUpdMemberFI_MAg>'

Select @ErrCode = @ErrCode + '-107'+char(7), @ErrMsg = @ErrMsg + char(7)

--Log positiontaking
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 408,
	@TrackingValue = @LogSPData

GO 
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMemberFI_MAg] TO [bodbAdminNet]
GO 
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMemberFI_MAg] TO [vnteam]
GO 
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMemberFI_MAg] TO [bodbDownlineNet]
