/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_MT_GetPT] 
	@UserName varchar(30),
	@Sporttype smallint = 1,
	@Bettype smallint = 1,
	@IsLive bit = 0, 
	@HasComm bit = 1,
	@ErrCode int = 0 Output,
	@ErrMsg varchar(100) ='' Output
AS
/*
Created: Phuc
Date: 
Task : View PT, commission in a visualable way
DB: DBCUST.CustDB
Original: DBA_GetPT

Revisions:
	- 20090709@Daniel: Fix bug view LIVE PT
	- 20090715@Simon: Get Auto Master PT
	- 20090715@Jamie: Get DisableAutoMPT 
	- 20091203@Kiwi: Modify to retrieve data from CustSetting3rd.
	- 20100611@Phuc: check max IBC PT(50%) for HR.
	- 20100908@Henry: Add Number Game Sporttype
	- 20110105@Lukas: Re-arrange bettype
	- 20110309@Johnson: Add Horse Racing AU, GreyHound, Harness sporttype
	- 20110801@Johnson: - remove bettype dead ball over/under of number game
						- add more bettype for nubmer game Warrior,  Next combo and Number Group
	- 20120202@Johnson: Add P2P game
	- 20120820@Dan: Add Virtual soccer
	- 20121204@Tom: Add Virtual tennis
	- 20130222@Johnson: add virtual horse racing (sporttype: 181)
	- 20130702@Kathy: Fix bug view PT, Comm for licensee
	- 20131021@Kathy: Add HR Fixed Odds (154) [Redmine:#6505]
	- 20131121@Elodie: Add Virtual greyhounds(182), Virtual Motor Racing(184) [Redmine:#7234]
	- 20140402@Kathy: Add Virtual Speedway (183), Virtual Virtual Cycling (185)	[Redmine:#14142]
	- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB, use temp table for sports, bettype)
	- 20150904@Helen: commission setting for MO [Redmine #41470]
	- 20170808@Winnie: Change Data Type of Sporttype [RedmineID: #73545]
	- 20180125@Winnie: Hide inactive products [RedmineID: #86086]  
Param's Explanation:
• @HasComm: view Comm or view PT
	+ 0: View PT (default)
	+ 1: View Commission
*/


SET NOCOUNT ON

----- 20150610@Kos -------------------
DECLARE @tmp_Sports TABLE (SportType SMALLINT, SportName NVARCHAR(50))
DECLARE @tmp_Bettype TABLE (TypeID INT, TypeNamee NVARCHAR(50))
	
BEGIN TRY
	INSERT INTO @tmp_Sports (SportType, SportName)
	SELECT SportType, SportName FROM DBAGE.bodb02.dbo.Sports WITH (NOLOCK)
END TRY
BEGIN CATCH
	INSERT INTO @tmp_Sports (SportType, SportName)
	SELECT SportType, SportName FROM DBTXN.bodb02.dbo.Sports WITH (NOLOCK)
END CATCH

BEGIN TRY
	INSERT INTO @tmp_Bettype (TypeID, TypeNamee)
	SELECT TypeID, TypeNamee FROM DBAGE.bodb02.dbo.Bettype WITH (NOLOCK)
END TRY
BEGIN CATCH
	INSERT INTO @tmp_Bettype (TypeID, TypeNamee)
	SELECT TypeID, TypeNamee FROM DBTXN.bodb02.dbo.Bettype WITH (NOLOCK)
END CATCH
----- 20150610@Kos -------------------

Begin
	Declare
	@CustID int,
	@RoleID int,
	@SAg varchar(20),
	@MAg varchar(20),
	@Ag varchar(20),
	@s4 smallmoney,  
	@m4 smallmoney,  
	@a4 smallmoney,  
	@n4 smallmoney,   
	@l4 smallmoney,   
	@s3 smallmoney,  
	@m3 smallmoney,  
	@u3 smallmoney,  
	@i3 bit,  
	@n3 smallmoney,  
	@l3 smallmoney,  
	@m2 smallmoney,  
	@a2 smallmoney, 
	@um2 smallmoney, --Auto Master
	@im2 bit,		 --Auto Master
	@n2 smallmoney,
	@l2 smallmoney,  
	@s1 smallmoney,  
	@m1 smallmoney,  
	@a1 smallmoney,  
	@u1 smallmoney,  
	@i1 bit,	
	@um1 smallmoney, --Auto Master
	@im1 bit,		 --Auto Master
	@DisableAutoMPT bit, 
	@ga4 decimal(9,8) ,
	@gb4 decimal(9,8),
	@gc4 decimal(9,8) ,
	@gd4 decimal(9,8) ,
	@othercomm4 decimal(9,8),
	@comm_5_4 decimal(9,8),--1x2
	
	@v161_comm_81_4 decimal(9,8), --number game
	@v201_comm_3_4 decimal(9,8),


	@ga3 decimal(9,8) ,
	@gb3 decimal(9,8),
	@gc3 decimal(9,8) ,
	@gd3 decimal(9,8) ,
	@othercomm3 decimal(9,8),
	@comm_5_3 decimal(9,8),--1x2
	
	@v161_comm_81_3 decimal(9,8), --number game
	@v201_comm_3_3 decimal(9,8),


	@ga2 decimal(9,8),
	@gb2 decimal(9,8),
	@gc2 decimal(9,8),
	@gd2 decimal(9,8) ,
	@othercomm2 decimal(9,8),
	@comm_5_2 decimal(9,8),--1x2
	
	@v161_comm_81_2 decimal(9,8), --number game
	@v201_comm_3_2 decimal(9,8),
	


	@ugroup varchar(3) ,
	@comm decimal(9,8),
	@othercomm decimal(9,8),
	@comm_5 decimal(9,8),--1x2
	
	@v161_comm_81 decimal(9,8), --number game
	@v201_comm_3 decimal(9,8),

	
	@SRecommend int,  
	@MRecommend int,  
	@Recommend int,
	@curBettype smallint,  
	@curSporttype smallint,  
	@curtypename varchar(20),  
	@curSportname varchar(50),
	@currency tinyint   


	Create table #tmpresult
	(
		sporttype int,bettype int, sportname varchar(50),typename varchar(20), islive bit,s4 smallmoney, m4 smallmoney,a4 smallmoney,
		n4 smallmoney,l4 smallmoney,s3 smallmoney,m3 smallmoney,u3 smallmoney,i3 bit,n3 smallmoney,l3 smallmoney,
		m2 smallmoney,a2 smallmoney,n2 smallmoney,l2 smallmoney,s1 smallmoney,m1 smallmoney,a1 smallmoney,u1 smallmoney,i1 bit,
		um2 smallmoney,im2 bit, um1 smallmoney,im1 bit, -- Auto Master
		ibc_pt_hr smallmoney
	)

	select @CustID=CustID, @currency = currency from Custinfo with (nolock) where UserName=@UserName
	select @UserName=UserName, @RoleID=RoleID, @SRecommend = SRecommend, @MRecommend = MRecommend, @Recommend = Recommend from Custinfo with(nolock) where CustID = @CustID 
	select @SAg = UserName from Custinfo with(nolock) where CustID = @SRecommend
	select @MAg = UserName from Custinfo with(nolock) where CustID = @MRecommend
	select @Ag = UserName from Custinfo with(nolock) where CustID = @Recommend
	select @DisableAutoMPT = DisableAutoMPT from CustMaster with (nolock) where custid = @MRecommend
	select @CustID CustID, @UserName UserName, @RoleID RoleID, @currency currency, @SRecommend SAgID, @MRecommend MAgID, @Recommend AgID, @SAg SAg, @MAg MAg, @Ag Ag, @DisableAutoMPT DisableAutoMPT

	If @@rowcount = 0  
	BEGIN  
		select @ErrCode = 101, @ErrMsg ='Invalid UserName!'
		return  
	END  
	DECLARE @IsLicensee INT SET @IsLicensee = 0 
	IF(EXISTS(SELECT ci.custid FROM custInfo ci with(NOLOCK) WHERE ci.srecommend IN (SELECT * FROM dbo.f_DepSuper_1('ALL') fds) AND ci.custid = @CustID))
		SET @IsLicensee  = 1
	IF(@IsLicensee = 0)
		BEGIN
			Declare Type_Cursor CURSOR FOR	 
			SELECT t.Sporttype, Bettype, Sportname, typenamee
			FROM (	SELECT cs.custid, cs.bettype, cs.sporttype FROM CustSetting cs WITH (NOLOCK)
					UNION
					SELECT cs3rd.custid, cs3rd.bettype, cs3rd.sporttype FROM CustSetting3rd cs3rd WITH (NOLOCK)
				 ) t
			inner join @tmp_Sports sports on t.sporttype = sports.sporttype
			inner join @tmp_Bettype bettype on t.bettype = bettype.typeid
			WHERE CustID = @CustID and Bettype = case @Bettype when 0 then Bettype else @Bettype end  
				and t.Sporttype = case @Sporttype when 0 then t.Sporttype else @Sporttype end  
			ORDER BY t.Sporttype, t.Bettype		
		END
	ELSE
		BEGIN
			Declare Type_Cursor CURSOR FOR	 
			SELECT t.Sporttype, Bettype, Sportname, typenamee
			FROM (	SELECT cs.custid, cs.bettype, cs.sporttype FROM dep_CustSetting cs WITH (NOLOCK)
					UNION
					SELECT cs3rd.custid, cs3rd.bettype, cs3rd.sporttype FROM dep_CustSetting3rd cs3rd WITH (NOLOCK)
				 ) t
			inner join @tmp_Sports sports on t.sporttype = sports.sporttype
			inner join @tmp_Bettype bettype on t.bettype = bettype.typeid
			WHERE CustID = @CustID and Bettype = case @Bettype when 0 then Bettype else @Bettype end  
				and t.Sporttype = case @Sporttype when 0 then t.Sporttype else @Sporttype end  
			ORDER BY t.Sporttype, t.Bettype	
		END	
	
	
	OPEN Type_Cursor   
	FETCH NEXT FROM Type_Cursor  
	INTO @curSporttype, @curBettype, @curSportname, @curtypename 
	IF(@@FETCH_STATUS = -1)
		BEGIN  
			CLOSE Type_Cursor
			DEALLOCATE Type_Cursor
			select @ErrCode = 101, @ErrMsg ='Invalid Data!'
			return  
		END  
	WHILE @@FETCH_STATUS = 0  
	BEGIN 
		if @curSporttype in (201, 161, 180, 181, 182, 183, 184, 185, 186) 
			BEGIN
					select @l4 = MaxPositionTaking, @n4 = MinPositionTaking from CustOverride3rd with (NOLOCK) where CustID = @SRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
					select @l3 = MaxPositionTaking, @n3 = MinPositionTaking from CustOverride3rd with (NOLOCK) where CustID = @MRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
					select @l2 = MaxPositionTaking, @n2 = MinPositionTaking from CustOverride3rd with (NOLOCK) where CustID = @Recommend and Bettype=@curBettype and Sporttype=@curSporttype  
					IF(@IsLicensee =0)
						BEGIN
							select @s4 = SPositionTaking, @m4 = MPositionTaking, @a4 = APositionTaking from CustSetting3rd with (NOLOCK) where CustID = @SRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
							select @s3 = SPositionTaking, @m3 = MPositionTaking, @u3 = AutoPositionTaking, @i3 = IsAutoPositionTaking from CustSetting3rd with (NOLOCK)  where CustID = @MRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
							select @m2 = MPositionTaking, @a2 = APositionTaking, @um2 = autompositiontaking, @im2 = isautompositiontaking from CustSetting3rd with (NOLOCK)  where CustID = @Recommend and Bettype=@curBettype and Sporttype=@curSporttype  
							select @s1 = SPositionTaking, @m1 = MPositionTaking, @a1 = APositionTaking, @u1 = AutoPositionTaking, @i1 = IsAutoPositionTaking, @um1 = AutomPositionTaking, @im1 = IsAutomPositionTaking from CustSetting3rd with (NOLOCK)  where CustID = @CustID and Bettype=@curBettype and Sporttype=@curSporttype  
						END
					ELSE
						BEGIN
							select @s4 = SPositionTaking, @m4 = MPositionTaking, @a4 = APositionTaking from dep_CustSetting3rd with (NOLOCK) where CustID = @SRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
							select @s3 = SPositionTaking, @m3 = MPositionTaking, @u3 = 0, @i3 = 0 from dep_CustSetting3rd with (NOLOCK)  where CustID = @MRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
							select @m2 = MPositionTaking, @a2 = APositionTaking, @um2 = 0, @im2 = 0 from dep_CustSetting3rd with (NOLOCK)  where CustID = @Recommend and Bettype=@curBettype and Sporttype=@curSporttype  
							select @s1 = SPositionTaking, @m1 = MPositionTaking, @a1 = APositionTaking, @u1 = 0, @i1 = 0, @um1 = 0, @im1 = 0 from dep_CustSetting3rd with (NOLOCK)  where CustID = @CustID and Bettype=@curBettype and Sporttype=@curSporttype  
						END
					
			END
		ELSE
		BEGIN
				select @l4 = MaxPositionTaking, @n4 = MinPositionTaking from CustOverride with (NOLOCK) where CustID = @SRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
				select @l3 = MaxPositionTaking, @n3 = MinPositionTaking from CustOverride with (NOLOCK) where CustID = @MRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
				select @l2 = MaxPositionTaking, @n2 = MinPositionTaking from CustOverride with (NOLOCK) where CustID = @Recommend and Bettype=@curBettype and Sporttype=@curSporttype  
				IF(@IsLicensee =0)
					BEGIN					
						select @s4 = SPositionTaking, @m4 = MPositionTaking, @a4 = APositionTaking from CustSetting with (NOLOCK) where CustID = @SRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
						select @s3 = SPositionTaking, @m3 = MPositionTaking, @u3 = AutoPositionTaking, @i3 = IsAutoPositionTaking from CustSetting with (NOLOCK)  where CustID = @MRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
						select @m2 = MPositionTaking, @a2 = APositionTaking, @um2 = autompositiontaking, @im2 = isautompositiontaking from CustSetting with (NOLOCK)  where CustID = @Recommend and Bettype=@curBettype and Sporttype=@curSporttype  
						select @s1 = SPositionTaking, @m1 = MPositionTaking, @a1 = APositionTaking, @u1 = AutoPositionTaking, @i1 = IsAutoPositionTaking, @um1 = AutomPositionTaking, @im1 = IsAutomPositionTaking from CustSetting with (NOLOCK)  where CustID = @CustID and Bettype=@curBettype and Sporttype=@curSporttype
					END
				ELSE
				BEGIN
					select @s4 = SPositionTaking, @m4 = MPositionTaking, @a4 = APositionTaking from dep_CustSetting with (NOLOCK) where CustID = @SRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
					select @s3 = SPositionTaking, @m3 = MPositionTaking, @u3 = 0, @i3 = 0 from dep_CustSetting with (NOLOCK)  where CustID = @MRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
					select @m2 = MPositionTaking, @a2 = APositionTaking, @um2 = 0, @im2 = 0 from dep_CustSetting with (NOLOCK)  where CustID = @Recommend and Bettype=@curBettype and Sporttype=@curSporttype  
					select @s1 = SPositionTaking, @m1 = MPositionTaking, @a1 = APositionTaking, @u1 = 0, @i1 = 0, @um1 = 0, @im1 = 0 from dep_CustSetting with (NOLOCK)  where CustID = @CustID and Bettype=@curBettype and Sporttype=@curSporttype
				END				
		END

		
		insert into #tmpresult(sporttype, bettype, sportname, typename,islive, s1,  s3,  s4,  m1,  m2,  m3, m4,  a1,  a2, a4,  u1, u3,  i1, i3, um1, um2, im1, im2, n2 ,  n3,  n4,  l2,  l3,  l4, ibc_pt_hr) 
		select @curSporttype sporttype, @curBettype bettype, @cursportname, @curtypename, 0 islive, @s1 s1, @s3 s3, @s4 s4, @m1 m1, @m2 m2, @m3 m3, @m4 m4, @a1 a1, @a2 a2, @a4 a4, @u1 u1, @u3 u3, @i1 i1, @i3 i3, @um1 um1, @um2 um2, @im1 im1, @im2 im2, @n2 n2, @n3 n3, @n4 n4, @l2 l2, @l3 l3, @l4 l4, 
			 0 as ibc_pt_hr	
		where @curBettype not in (85,87,89,90) -- exclude number game bettype dead ball 
				
		IF (@IsLive = 1 and @curSporttype = 1 and @curBettype in (1,3,7,8))
		BEGIN
			select @l4 = MaxLivePositionTaking, @n4 = MinLivePositionTaking from CustOverride with (NOLOCK) where CustID = @SRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
			select @l3 = MaxLivePositionTaking, @n3 = MinLivePositionTaking from CustOverride with (NOLOCK) where CustID = @MRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
			select @l2 = MaxLivePositionTaking, @n2 = MinLivePositionTaking from CustOverride with (NOLOCK) where CustID = @Recommend and Bettype=@curBettype and Sporttype=@curSporttype  	  
			IF (@IsLicensee =0)
				BEGIN
					select @s4 = SLivePositionTaking, @m4 = MLivePositionTaking, @a4 = ALivePositionTaking from CustSetting with (NOLOCK) where CustID = @SRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
					select @s3 = SLivePositionTaking, @m3 = MLivePositionTaking, @u3 = AutolivePositionTaking, @i3 = IsAutolivePositionTaking from CustSetting with (NOLOCK)  where CustID = @MRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
					select @m2 = MLivePositionTaking, @a2 = ALivePositionTaking, @um2 = autolivempositiontaking, @im2 = IsAutolivemPositionTaking from CustSetting with (NOLOCK)  where CustID = @Recommend and Bettype=@curBettype and Sporttype=@curSporttype  
					select @s1 = SLivePositionTaking, @m1 = MLivePositionTaking, @a1 = ALivePositionTaking, @u1 = AutoLivePositionTaking, @i1 = IsAutoLivePositionTaking, @um1 = AutoLivemPositionTaking, @im1 = IsAutoLivemPositionTaking from CustSetting with (NOLOCK)  where CustID = @CustID and Bettype=@curBettype and Sporttype=@curSporttype   			  
				END
			ELSE
				BEGIN
					select @s4 = SPositionTaking, @m4 = MPositionTaking, @a4 = APositionTaking from dep_CustSetting with (NOLOCK) where CustID = @SRecommend and Bettype=@curBettype and Sporttype=@curSporttype AND islive = @IsLive
					 select @s3 = SPositionTaking, @m3 = MPositionTaking, @u3 = 0, @i3 = 0 from dep_CustSetting with (NOLOCK)  where CustID = @MRecommend and Bettype=@curBettype and Sporttype=@curSporttype  AND islive = @IsLive
					
					select @m2 = MPositionTaking, @a2 = APositionTaking, @um2 = 0, @im2 = 0 from dep_CustSetting with (NOLOCK)  where CustID = @Recommend and Bettype=@curBettype and Sporttype=@curSporttype  AND islive = @IsLive
					select @s1 = SPositionTaking, @m1 = MPositionTaking, @a1 = APositionTaking, @u1 = 0, @i1 = 0, @um1 = 0, @im1 = 0 from dep_CustSetting with (NOLOCK)  where CustID = @CustID and Bettype=@curBettype and Sporttype=@curSporttype  AND islive = @IsLive	 		  
				END
			insert into #tmpresult(sporttype, bettype, sportname, typename, islive, s1,  s3,  s4,  m1,  m2,  m3, m4,  a1,  a2,  a4,  u1, u3,  i1, i3, um1, um2, im1, im2, n2 ,  n3,  n4,  l2,  l3,  l4, ibc_pt_hr) 
			select @curSporttype sporttype,@curBettype bettype, @cursportname, @curtypename,1 islive, @s1 s1, @s3 s3, @s4 s4, @m1 m1, @m2 m2, @m3 m3, @m4 m4, @a1 a1, @a2 a2, @a4 a4, @u1 u1, @u3 u3, @i1 i1, @i3 i3, @um1 um1, @um2 um2, @im1 im1, @im2 im2, @n2 n2, @n3 n3, @n4 n4, @l2 l2, @l3 l3, @l4 l4, 0 as ibc_hr_pt
		END  	 
		ELSE IF (@IsLive = 1 and @curSporttype = 161 and @curBettype in (85,86,87,89,90))
		BEGIN
			select @l4 = MaxLivePositionTaking, @n4 = MinLivePositionTaking from CustOverride3rd with (NOLOCK) where CustID = @SRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
			select @l3 = MaxLivePositionTaking, @n3 = MinLivePositionTaking from CustOverride3rd with (NOLOCK) where CustID = @MRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
			select @l2 = MaxLivePositionTaking, @n2 = MinLivePositionTaking from CustOverride3rd with (NOLOCK) where CustID = @Recommend and Bettype=@curBettype and Sporttype=@curSporttype  	  
			IF(@IsLicensee = 0)
				BEGIN
					select @s4 = SLivePositionTaking, @m4 = MLivePositionTaking, @a4 = ALivePositionTaking from CustSetting3rd with (NOLOCK) where CustID = @SRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
					select @s3 = SLivePositionTaking, @m3 = MLivePositionTaking, @u3 = AutolivePositionTaking, @i3 = IsAutolivePositionTaking from CustSetting3rd with (NOLOCK)  where CustID = @MRecommend and Bettype=@curBettype and Sporttype=@curSporttype  
					select @m2 = MLivePositionTaking, @a2 = ALivePositionTaking, @um2 = autolivempositiontaking, @im2 = IsAutolivemPositionTaking from CustSetting3rd with (NOLOCK)  where CustID = @Recommend and Bettype=@curBettype and Sporttype=@curSporttype  
					select @s1 = SLivePositionTaking, @m1 = MLivePositionTaking, @a1 = ALivePositionTaking, @u1 = AutoLivePositionTaking, @i1 = IsAutoLivePositionTaking, @um1 = AutoLivemPositionTaking, @im1 = IsAutoLivemPositionTaking from CustSetting3rd with (NOLOCK)  where CustID = @CustID and Bettype=@curBettype and Sporttype=@curSporttype   			  
				END
			ELSE
				BEGIN
					select @s4 = SPositionTaking, @m4 = MPositionTaking, @a4 = APositionTaking from dep_CustSetting3rd with (NOLOCK) where CustID = @SRecommend and Bettype=@curBettype and Sporttype=@curSporttype AND islive = @IsLive 
					select @s3 = SPositionTaking, @m3 = MPositionTaking, @u3 = 0, @i3 = 0 from dep_CustSetting3rd with (NOLOCK)  where CustID = @MRecommend and Bettype=@curBettype and Sporttype=@curSporttype   AND islive = @IsLive
					select @m2 = MPositionTaking, @a2 = APositionTaking, @um2 = 0, @im2 = 0 from dep_CustSetting3rd with (NOLOCK)  where CustID = @Recommend and Bettype=@curBettype and Sporttype=@curSporttype   AND islive = @IsLive
					select @s1 = SPositionTaking, @m1 = MPositionTaking, @a1 = APositionTaking, @u1 = 0, @i1 = 0, @um1 = 0, @im1 = 0 from dep_CustSetting3rd with (NOLOCK)  where CustID = @CustID and Bettype=@curBettype and Sporttype=@curSporttype  AND islive = @IsLive  			  
				END
			insert into #tmpresult(sporttype, bettype, sportname, typename, islive, s1,  s3,  s4,  m1,  m2,  m3, m4,  a1,  a2,  a4,  u1, u3,  i1, i3, um1, um2, im1, im2, n2 ,  n3,  n4,  l2,  l3,  l4, ibc_pt_hr) 
			select @curSporttype sporttype,@curBettype bettype, @cursportname, @curtypename,1 islive, @s1 s1, @s3 s3, @s4 s4, @m1 m1, @m2 m2, @m3 m3, @m4 m4, @a1 a1, @a2 a2, @a4 a4, @u1 u1, @u3 u3, @i1 i1, @i3 i3, @um1 um1, @um2 um2, @im1 im1, @im2 im2, @n2 n2, @n3 n3, @n4 n4, @l2 l2, @l3 l3, @l4 l4, 0 as ibc_hr_pt
		END
		
		
		FETCH NEXT FROM Type_Cursor  
		INTO @curSporttype, @curBettype, @curSportname, @curtypename  
	END  
	CLOSE Type_Cursor  
	  
	DEALLOCATE Type_Cursor 

	select * from #tmpresult
	
	
	drop table #tmpresult

	-- Get comm
	IF @hascomm = 1
	BEGIN
		IF(@IsLicensee = 0)
			BEGIN
				SELECT	@ga4 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupa else 0 end),
					@gb4 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupb else 0 end),
					@gc4 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupc else 0 end),
					@gd4 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupd else 0 end),
					@othercomm4 = max(case when acs.bettype = 4 and acs.sporttype=1 then acs.sdiscount else 0 end),
					@comm_5_4 = max(case when acs.bettype = 5 and acs.sporttype=1 then acs.sdiscount else 0 end) --1x2
					
				FROM custsetting as acs with (NOLOCK)
				WHERE acs.custid = @srecommend
			END
		ELSE
			BEGIN
				SELECT @ga4 = MAX(CASE WHEN dcs.bettype = 1 AND dcs.sporttype = 1 THEN dcs.sdiscount ELSE 0 END ),
						@gb4 = MAX(CASE WHEN dcs.bettype = 1 AND dcs.sporttype = 1 THEN dcs.sdiscount ELSE 0 END ),
						@gc4 = MAX(CASE WHEN dcs.bettype = 1 AND dcs.sporttype = 1 THEN dcs.sdiscount ELSE 0 END ),
						@gd4 = MAX(CASE WHEN dcs.bettype = 1 AND dcs.sporttype = 1 THEN dcs.sdiscount ELSE 0 END ),
						@othercomm4 = MAX(CASE WHEN dcs.bettype = 4 AND dcs.sporttype = 1 THEN dcs.sdiscount ELSE 0 END),
						@comm_5_4 = MAX(CASE WHEN dcs.bettype = 5 AND dcs.sporttype = 1 THEN dcs.sdiscount ELSE 0 END) 
			
				FROM Dep_CustSetting dcs WITH (NOLOCK)
				WHERE dcs.custid = @SRecommend
				AND dcs.islive = 0
			END	

		--SELECT 3rd commission's setting from CustSetting3rd at Super level
		IF(@IsLicensee = 0)
			BEGIN
				SELECT	@v201_comm_3_4 = max(case when acs.bettype = 3 and acs.sporttype=201 then acs.sdiscount else 0 end),					
					@v161_comm_81_4 = max(case when acs.bettype = 81 and acs.sporttype=161 then acs.sdiscount else 0 end)
				FROM CustSetting3rd as acs with (NOLOCK)
				WHERE acs.custid = @srecommend
			END
		ELSE
			BEGIN
				SELECT	@v201_comm_3_4 = max(case when dcs.bettype = 3 and dcs.sporttype=201 then dcs.sdiscount else 0 end),
				
					@v161_comm_81_4 = max(case when dcs.bettype = 81 and dcs.sporttype=161 then dcs.sdiscount else 0 end)
				FROM dep_CustSetting3rd as dcs with (NOLOCK)
				WHERE dcs.custid = @srecommend
				AND dcs.islive = 0
			END		

		-- 
		IF(@IsLicensee = 0)
			BEGIN
				SELECT	@ga3 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupa else 0 end),
					@gb3 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupb else 0 end),
					@gc3 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupc else 0 end),
					@gd3 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupd else 0 end),
					@othercomm3 = max(case when acs.bettype = 4 and acs.sporttype=1 then acs.adiscount else 0 end),
					@comm_5_3 = max(case when acs.bettype = 5 and acs.sporttype=1 then acs.adiscount else 0 end) --1x2
					
				FROM custsetting as acs with (NOLOCK)
				WHERE acs.custid = @mrecommend
			END
		ELSE
			BEGIN
				SELECT	@ga3 = max(case when dcs.bettype = 1 and dcs.sporttype=1 then dcs.adiscount else 0 end),
					@gb3 = max(case when dcs.bettype = 1 and dcs.sporttype=1 then dcs.adiscount else 0 end),
					@gc3 = max(case when dcs.bettype = 1 and dcs.sporttype=1 then dcs.adiscount else 0 end),
					@gd3 = max(case when dcs.bettype = 1 and dcs.sporttype=1 then dcs.adiscount else 0 end),
					@othercomm3 = max(case when dcs.bettype = 4 and dcs.sporttype=1 then dcs.adiscount else 0 end),
					@comm_5_3 = max(case when dcs.bettype = 5 and dcs.sporttype=1 then dcs.adiscount else 0 end) --1x2					
				FROM dep_custsetting as dcs with (NOLOCK)
				WHERE dcs.custid = @mrecommend
				AND dcs.islive = 0
			END

		--SELECT 3rd commission's setting from CustSetting3rd at Master Level
		IF(@IsLicensee = 0)
		BEGIN
			SELECT	@v201_comm_3_3 = max(case when acs.bettype = 3 and acs.sporttype=201 then acs.adiscount else 0 end),			
				@v161_comm_81_3 = max(case when acs.bettype = 81 and acs.sporttype=161 then acs.adiscount else 0 end)
			FROM CustSetting3rd as acs with (NOLOCK)
			WHERE acs.custid = @mrecommend
		END
		ELSE
			BEGIN
				SELECT	@v201_comm_3_3 = max(case when dcs.bettype = 3 and dcs.sporttype=201 then dcs.adiscount else 0 end),				
					@v161_comm_81_3 = max(case when dcs.bettype = 81 and dcs.sporttype=161 then dcs.adiscount else 0 end)
				FROM dep_CustSetting3rd as dcs with (NOLOCK)
				WHERE dcs.custid = @mrecommend
				AND dcs.islive = 0
			END
		
	
		-- 
		IF(@IsLicensee = 0)
		BEGIN
			SELECT	@ga2 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupa else 0 end),
				@gb2 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupb else 0 end),
				@gc2 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupc else 0 end),
				@gd2 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupd else 0 end),
				@othercomm2 = max(case when acs.bettype = 4 and acs.sporttype=1 then acs.discount else 0 end),
				@comm_5_2 = max(case when acs.bettype = 5 and acs.sporttype=1 then acs.discount else 0 end)--1x2
				
			FROM custsetting as acs with (NOLOCK)
			WHERE acs.custid = @recommend
		END
		ELSE
			BEGIN
				SELECT	@ga2 = max(case when dcs.bettype = 1 and dcs.sporttype=1 then dcs.discount else 0 end),
					@gb2 = max(case when dcs.bettype = 1 and dcs.sporttype=1 then dcs.discount else 0 end),
					@gc2 = max(case when dcs.bettype = 1 and dcs.sporttype=1 then dcs.discount else 0 end),
					@gd2 = max(case when dcs.bettype = 1 and dcs.sporttype=1 then dcs.discount else 0 end),
					@othercomm2 = max(case when dcs.bettype = 4 and dcs.sporttype=1 then dcs.discount else 0 end),
					@comm_5_2 = max(case when dcs.bettype = 5 and dcs.sporttype=1 then dcs.discount else 0 end)--1x2
					
				FROM dep_custsetting as dcs with (NOLOCK)
				WHERE dcs.custid = @recommend
				AND dcs.islive = 0
			END
		
		--SELECT 3rd commission's setting from CustSetting3rd at Agent Level
		IF(@IsLicensee = 0)
		BEGIN
			SELECT	@v201_comm_3_2 = max(case when acs.bettype = 3 and acs.sporttype=201 then acs.discount else 0 end),				
				@v161_comm_81_2 = max(case when acs.bettype = 81 and acs.sporttype=161 then acs.discount else 0 end)
			FROM CustSetting3rd as acs with (NOLOCK)
			WHERE acs.custid = @recommend
		END
		ELSE
			BEGIN
				SELECT	@v201_comm_3_2 = max(case when dcs.bettype = 3 and dcs.sporttype=201 then dcs.discount else 0 end),				
					@v161_comm_81_2 = max(case when dcs.bettype = 81 and dcs.sporttype=161 then dcs.discount else 0 end)
				FROM dep_CustSetting3rd as dcs with (NOLOCK)
				WHERE dcs.custid = @recommend
				AND dcs.islive = 0
			END
	
		 
		-- 
		IF(@IsLicensee = 0)
			BEGIN
				SELECT	@comm = isnull(max(case when acs.bettype = 1 and acs.sporttype=1 then acs.playerdiscount else 0 end), 0) ,
					@othercomm = isnull(max(case when acs.bettype = 4 and acs.sporttype=1 then acs.playerdiscount else 0 end), 0), 
					@comm_5 = isnull(max(case when acs.bettype = 5 and acs.sporttype=1 then acs.playerdiscount else 0 end), 0)--1x2 
					
				FROM custsetting as acs with(nolock) 
				WHERE custid = @custid
			END	
		ELSE
			BEGIN
				SELECT	@comm = isnull(max(case when dcs.bettype = 1 and dcs.sporttype=1 then dcs.playerdiscount else 0 end), 0) ,
					@othercomm = isnull(max(case when dcs.bettype = 4 and dcs.sporttype=1 then dcs.playerdiscount else 0 end), 0), 
					@comm_5 = isnull(max(case when dcs.bettype = 5 and dcs.sporttype=1 then dcs.playerdiscount else 0 end), 0)--1x2

				FROM dep_custsetting as dcs with(nolock) 
				WHERE custid = @custid
				AND dcs.islive = 0
			END
			
		--SELECT 3rd commission's setting from CustSetting3rd at Member Level
		IF(@IsLicensee = 0)
			BEGIN
				SELECT	@v201_comm_3 = isnull(max(case when acs.bettype = 3 and acs.sporttype=201 then acs.playerdiscount else 0 end), 0),					
					@v161_comm_81 = max(case when acs.bettype = 81 and acs.sporttype=161 then acs.playerdiscount else 0 end)
				FROM CustSetting3rd as acs with(nolock) 
				WHERE custid = @custid
			END		
		ELSE
			BEGIN
				SELECT	@v201_comm_3 = isnull(max(case when dcs.bettype = 3 and dcs.sporttype=201 then dcs.playerdiscount else 0 end), 0),					
					@v161_comm_81 = max(case when dcs.bettype = 81 and dcs.sporttype=161 then dcs.playerdiscount else 0 end)
				FROM dep_CustSetting3rd as dcs with(nolock) 
				WHERE custid = @custid
				AND dcs.islive = 0
			END
	
		
		SELECT @ugroup = ugroup from customer with(nolock) where custid=@custid

		-- For Myanmar Odds
		DECLARE @MyanmarOddsComm_1 DECIMAL (9,8) = 0
				, @MyanmarOddsComm_2 DECIMAL (9,8) = 0
				, @MyanmarOddsComm_3 DECIMAL (9,8) = 0
				, @MyanmarOddsComm_4 DECIMAL (9,8) = 0
				, @IsMyanmarOdds BIT = 0
		
	
		IF @RoleID = 4
			SELECT @MyanmarOddsComm_4 = CommRate, @IsMyanmarOdds = 1 FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @SRecommend AND Sporttype = 1 AND Bettype = 301		
		IF @RoleID =3
		BEGIN
			SELECT @MyanmarOddsComm_3 = CommRate, @IsMyanmarOdds = 1 FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @MRecommend AND Sporttype = 1 AND Bettype = 301		
			SELECT @MyanmarOddsComm_4 = CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @SRecommend AND Sporttype = 1 AND Bettype = 301		
		END	
			
		IF @RoleID =2
		BEGIN
			SELECT @MyanmarOddsComm_2 = CommRate, @IsMyanmarOdds = 1 FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @Recommend AND Sporttype = 1 AND Bettype = 301
			SET @MyanmarOddsComm_3 = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @MRecommend AND Sporttype = 1 AND Bettype = 301)		
			SET @MyanmarOddsComm_4 = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @SRecommend AND Sporttype = 1 AND Bettype = 301)		
		END		
		
		IF @RoleID = 1
		BEGIN
			SELECT @IsMyanmarOdds = 1, @MyanmarOddsComm_1= playerdiscount, @MyanmarOddsComm_2 = discount,@MyanmarOddsComm_3= adiscount, @MyanmarOddsComm_4 = sdiscount
			FROM CustCommRate WITH (NOLOCK) WHERE CustId = @CustID AND Sporttype = 1 AND Bettype = 301		
			
		END
		
		SELECT	@ga4 ga4,
				@gb4 gb4,
				@gc4 gc4,
				@gd4 gd4,
				
				@othercomm4 othercomm4,
				@comm_5_4 comm_5_4, 			
				@v201_comm_3_4 v201_comm_3_4, 				
				@v161_comm_81_4 v161_comm_81_4, 
						
				
				@ga3 ga3,
				@gb3 gb3,
				@gc3 gc3,
				@gd3 gd3,
				@othercomm3 othercomm3, 
				@comm_5_3 comm_5_3, 
				
				@v201_comm_3_3 v201_comm_3_3, 
			
				@v161_comm_81_3 v161_comm_81_3, 
			
				
				@ga2 ga2,
				@gb2 gb2,
				@gc2 gc2,
				@gd2 gd2,
				@othercomm2 othercomm2, 
				@comm_5_2 comm_5_2,
				
				@v201_comm_3_2 v201_comm_3_2, 
				
				@v161_comm_81_2 v161_comm_81_2,
			
				
				@comm comm,
				@othercomm othercomm, 
				@comm_5 comm_5, 
				
				@v201_comm_3 v201_comm_3, 
			
				@v161_comm_81 v161_comm_81  , 
				
				@ugroup ugroup,
				ISNULL(@IsMyanmarOdds,0) AS IsMyanmarOdds,
				ISNULL(@MyanmarOddsComm_1,0) AS MyanmarOddsComm_1,
				ISNULL(@MyanmarOddsComm_2,0) AS MyanmarOddsComm_2,
				ISNULL(@MyanmarOddsComm_3,0) AS MyanmarOddsComm_3,
				ISNULL(@MyanmarOddsComm_4,0) AS MyanmarOddsComm_4
	end

End




GO
