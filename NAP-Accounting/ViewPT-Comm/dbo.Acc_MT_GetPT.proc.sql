alter PROCEDURE [dbo].[Acc_MT_GetPT] 
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
	
Param's Explanation:
• @HasComm: view Comm or view PT
	+ 0: View PT (default)
	+ 1: View Commission
*/


SET NOCOUNT ON

----- 20150610@Kos -------------------
DECLARE @tmp_Sports TABLE (SportType TINYINT, SportName NVARCHAR(50))
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
	@v151_AutoIBC_pt_31 smallmoney,-- @ibc_pt_HR_31 -> @v151_AutoIBC_pt_31
	@v151_AutoIBC_pt_41 smallmoney,-- @ibc_pt_HR_41 -> @v151_AutoIBC_pt_41
	@v151_AutoIBC_pt_51 smallmoney,
	@v152_AutoIBC_pt_41 smallmoney,
	@v152_AutoIBC_pt_51 smallmoney,
	@v153_AutoIBC_pt_51 smallmoney,
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
	@v151_ibc_pt_31 smallmoney,	--@to1 -> @v151_ibc_pt_31  //IBC PT for Tote(member level)
	@v151_ibc_pt_41 smallmoney, -- @fo1 -> @v151_ibc_pt_41  //IBC PT for Fixed Odds(member level)
	@v151_ibc_pt_51 smallmoney,
	@v152_ibc_pt_41 smallmoney,
	@v152_ibc_pt_51 smallmoney,
	@v153_ibc_pt_51 smallmoney,
	@v151_ibc_pt_31_33 smallmoney, --@to_31_33 -> @v151_ibc_pt_31_33  //IBC PT for Tote(member level on eachway)
	@v151_ibc_pt_32_33 smallmoney, --@to_32_33 -> @v151_ibc_pt_32_33  //IBC PT for Tote(member level on eachway)
	@v151_ibc_pt_41_43 smallmoney, --@fo_41_43 -> @v151_ibc_pt_41_43  //IBC PT for Fixed Odds(member level on eachway)
	@v151_ibc_pt_42_43 smallmoney, --@fo_42_43 -> @v151_ibc_pt_42_43  //IBC PT for Fixed Odds(member level on eachway)
	@v151_ibc_pt_51_53 smallmoney,
	@v151_ibc_pt_52_53 smallmoney,
	@v152_ibc_pt_41_43 smallmoney,
	@v152_ibc_pt_42_43 smallmoney,
	@v152_ibc_pt_51_53 smallmoney,
	@v152_ibc_pt_52_53 smallmoney,
	@v153_ibc_pt_51_53 smallmoney,
	@v153_ibc_pt_52_53 smallmoney,

	@ga4 decimal(9,8) ,
	@gb4 decimal(9,8),
	@gc4 decimal(9,8) ,
	@gd4 decimal(9,8) ,
	@othercomm4 decimal(9,8),
	@comm_5_4 decimal(9,8),--1x2
	@HRFixedOddsComm_4 decimal(9,8),-- HR Fixed Odds
	@v161_comm_81_4 decimal(9,8), --number game
	@v201_comm_3_4 decimal(9,8),
	@v151_comm_31_4 decimal(9,8),
	@v151_comm_41_4 decimal(9,8),
	@v151_comm_51_4 decimal(9,8),
	@v152_comm_41_4 decimal(9,8),
	@v152_comm_51_4 decimal(9,8),
	@v153_comm_51_4 decimal(9,8),
	@v253_Comm_1_4 decimal(9,8),-- P2P
	@v253_Comm_2_4 decimal(9,8),

	@ga3 decimal(9,8) ,
	@gb3 decimal(9,8),
	@gc3 decimal(9,8) ,
	@gd3 decimal(9,8) ,
	@othercomm3 decimal(9,8),
	@comm_5_3 decimal(9,8),--1x2
	@HRFixedOddsComm_3 decimal(9,8), -- HR Fixed Odds
	@v161_comm_81_3 decimal(9,8), --number game
	@v201_comm_3_3 decimal(9,8),
	@v151_comm_31_3 decimal(9,8),
	@v151_comm_41_3 decimal(9,8),
	@v151_comm_51_3 decimal(9,8),
	@v152_comm_41_3 decimal(9,8),
	@v152_comm_51_3 decimal(9,8),
	@v153_comm_51_3 decimal(9,8),
	@v253_Comm_1_3 decimal(9,8),--P2P
	@v253_Comm_2_3 decimal(9,8),

	@ga2 decimal(9,8),
	@gb2 decimal(9,8),
	@gc2 decimal(9,8),
	@gd2 decimal(9,8) ,
	@othercomm2 decimal(9,8),
	@comm_5_2 decimal(9,8),--1x2
	@HRFixedOddsComm_2 decimal(9,8), -- HR Fixed Odds
	@v161_comm_81_2 decimal(9,8), --number game
	@v201_comm_3_2 decimal(9,8),
	@v151_comm_31_2 decimal(9,8),
	@v151_comm_41_2 decimal(9,8),
	@v151_comm_51_2 decimal(9,8),
	@v152_comm_41_2 decimal(9,8),
	@v152_comm_51_2 decimal(9,8),
	@v153_comm_51_2 decimal(9,8),
	@v253_Comm_1_2 decimal(9,8),--P2P
	@v253_Comm_2_2 decimal(9,8),

	@ugroup varchar(3) ,
	@comm decimal(9,8),
	@othercomm decimal(9,8),
	@comm_5 decimal(9,8),--1x2
	@HRFixedOddsComm decimal(9,8),
	@v161_comm_81 decimal(9,8), --number game
	@v201_comm_3 decimal(9,8),
	@v151_comm_31 decimal(9,8),
	@v151_comm_41 decimal(9,8),
	@v151_comm_51 decimal(9,8),
	@v152_comm_41 decimal(9,8),
	@v152_comm_51 decimal(9,8),
	@v153_comm_51 decimal(9,8),
	@v253_Comm_1 decimal(9,8), --P2P
	@v253_Comm_2 decimal(9,8),
	
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
	select @v151_AutoIBC_pt_31 = AutoIBCPositiontaking_Tote, @v151_AutoIBC_pt_41 = AutoIBCPositiontaking_Fixed,
	@v151_AutoIBC_pt_51 = AutoIBCPT151_AU, @v152_AutoIBC_pt_41 = AutoIBCPT152_UK, @v152_AutoIBC_pt_51 = AutoIBCPT152_AU,
	@v153_AutoIBC_pt_51 = AutoIBCPT153_AU
	from CustSuper (nolock) where custid = @SRecommend
	
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
	
	Declare @v151_OverallMaxPT_31 smallmoney, @v151_OverallMaxPT_41 smallmoney ,@v151_OverallMaxPT_51 smallmoney,--@OverallMaxPT_31 -> @v151_OverallMaxPT_31 ,@OverallMaxPT_41 -> @v151_OverallMaxPT_41
			@v152_OverallMaxPT_41 smallmoney, @v152_OverallMaxPT_51 smallmoney ,@v153_OverallMaxPT_51 smallmoney
	-- Max of (IBCPos + TPos)
	--Thien@20100521:	+ Phumelela: for (THB, $US, IRR, NTD, Yen, IN, IND, IDD, IDR) members, IBC MUST take 10% PT, MIN PT to Phumelela is 40%
	--					+ OpenTote: For members in ALL currencies, MIN PT to 3rd Party is ALWAYS 50%
	select	@v151_OverallMaxPT_31 = CASE
						WHEN @currency in (16, 17, 35, 40, 43, 15, 22, 33, 34, 47) then 0.6 --for (THB, $US, IRR, NTD, Yen, IN, IND, IDD, IDR) members, IBC MUST take 10% PT, MIN PT to Phumelela is 40%
						ELSE 0.5 --in first month, Phu will take at least 50%
					END, 
			@v151_OverallMaxPT_41 = 0.5, @v151_OverallMaxPT_51 = 0.5 , @v152_OverallMaxPT_41 = 0.5,
			@v152_OverallMaxPT_51 = 0.5, @v153_OverallMaxPT_51 = 0.5
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
		if @curSporttype in (151,152,153, 201, 161, 180, 181, 182, 183, 184, 185, 186) 
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
		
		if @curSporttype = 151
		begin
			if @curBettype  IN (31,32)
				Select @v151_ibc_pt_31 = (@v151_OverallMaxPT_31 - (@s1+@m1+@a1) + @v151_AutoIBC_pt_31 - ABS(@v151_OverallMaxPT_31 - (@s1+@m1+@a1) - @v151_AutoIBC_pt_31)) / 2
			else if @curBettype IN (41,42)
				Select	@v151_ibc_pt_41 = (@v151_OverallMaxPT_41 - (@s1+@m1+@a1) + @v151_AutoIBC_pt_41 - ABS(@v151_OverallMaxPT_41 - (@s1+@m1+@a1) - @v151_AutoIBC_pt_41)) / 2	
			else
				Select	@v151_ibc_pt_51 = (@v151_OverallMaxPT_51 - (@s1+@m1+@a1) + @v151_AutoIBC_pt_51 - ABS(@v151_OverallMaxPT_51 - (@s1+@m1+@a1) - @v151_AutoIBC_pt_51)) / 2	
		end
		else if @curSporttype = 152
		BEGIN
			if @curBettype IN (41,42)
				Select	@v152_ibc_pt_41 = (@v152_OverallMaxPT_41 - (@s1+@m1+@a1) + @v152_AutoIBC_pt_41 - ABS(@v152_OverallMaxPT_41 - (@s1+@m1+@a1) - @v152_AutoIBC_pt_41)) / 2	
			else
				Select	@v152_ibc_pt_51 = (@v152_OverallMaxPT_51 - (@s1+@m1+@a1) + @v152_AutoIBC_pt_51 - ABS(@v152_OverallMaxPT_51 - (@s1+@m1+@a1) - @v152_AutoIBC_pt_51)) / 2	
		END
		else if @curSporttype = 153
		BEGIN
			if @curBettype IN (51,52)
				Select	@v153_ibc_pt_51 = (@v153_OverallMaxPT_51 - (@s1+@m1+@a1) + @v153_AutoIBC_pt_51 - ABS(@v153_OverallMaxPT_51 - (@s1+@m1+@a1) - @v153_AutoIBC_pt_51)) / 2				
		END
		
		insert into #tmpresult(sporttype, bettype, sportname, typename,islive, s1,  s3,  s4,  m1,  m2,  m3, m4,  a1,  a2, a4,  u1, u3,  i1, i3, um1, um2, im1, im2, n2 ,  n3,  n4,  l2,  l3,  l4, ibc_pt_hr) 
		select @curSporttype sporttype, @curBettype bettype, @cursportname, @curtypename, 0 islive, @s1 s1, @s3 s3, @s4 s4, @m1 m1, @m2 m2, @m3 m3, @m4 m4, @a1 a1, @a2 a2, @a4 a4, @u1 u1, @u3 u3, @i1 i1, @i3 i3, @um1 um1, @um2 um2, @im1 im1, @im2 im2, @n2 n2, @n3 n3, @n4 n4, @l2 l2, @l3 l3, @l4 l4, 
			case when @cursporttype = 151 then case when @curbettype in (31,32) then @v151_ibc_pt_31 
													when @curbettype in (41,42) then @v151_ibc_pt_41 
													else @v151_ibc_pt_51 end 
				 when @cursporttype = 152 then case when @curbettype in (41,42) then @v152_ibc_pt_41
													else @v152_ibc_pt_51 end
				 when @cursporttype = 153 then @v153_ibc_pt_51 
			else 0 end as ibc_pt_hr	
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

	declare @v151_maxpos_31 smallmoney, @v151_maxpos_32 smallmoney, @v151_maxpos_41 smallmoney, @v151_maxpos_42 smallmoney, @v151_maxpos_51 smallmoney, @v151_maxpos_52 smallmoney,-- @maxpos_to -> @v151_maxpos_31 , @maxpos_fo -> @v151_maxpos_41
			@v152_maxpos_41 smallmoney, @v152_maxpos_42 smallmoney, @v152_maxpos_51 smallmoney, @v152_maxpos_52 smallmoney, @v153_maxpos_51 smallmoney, @v153_maxpos_52 smallmoney

	select @v151_maxpos_31 = max(case when sporttype = 151 and bettype = 31 then 
							(s1+m1+a1) + (@v151_OverallMaxPT_31 - (s1+m1+a1) + @v151_AutoIBC_pt_31 - abs(@v151_OverallMaxPT_31 - (s1+m1+a1) - @v151_AutoIBC_pt_31))/2
							else 0 end
						),
		   @v151_maxpos_32 = max(case when sporttype = 151 and bettype = 32 then 
							(s1+m1+a1) + (@v151_OverallMaxPT_31 - (s1+m1+a1) + @v151_AutoIBC_pt_31 - abs(@v151_OverallMaxPT_31 - (s1+m1+a1) - @v151_AutoIBC_pt_31))/2
							else 0 end
						),	
		   @v151_maxpos_41 = max(case when sporttype = 151 and bettype = 41 then 
								(s1+m1+a1) + (@v151_OverallMaxPT_41 - (s1+m1+a1) + @v151_AutoIBC_pt_41 - abs(@v151_OverallMaxPT_41 - (s1+m1+a1) - @v151_AutoIBC_pt_41))/2
							else 0 end 
						),
			@v151_maxpos_42 = max(case when sporttype = 151 and bettype = 42 then 
								(s1+m1+a1) + (@v151_OverallMaxPT_41 - (s1+m1+a1) + @v151_AutoIBC_pt_41 - abs(@v151_OverallMaxPT_41 - (s1+m1+a1) - @v151_AutoIBC_pt_41))/2
							else 0 end 
						),
		   @v151_maxpos_51 = max(case when sporttype = 151 and bettype = 51 then 
								(s1+m1+a1) + (@v151_OverallMaxPT_51 - (s1+m1+a1) + @v151_AutoIBC_pt_51 - abs(@v151_OverallMaxPT_51 - (s1+m1+a1) - @v151_AutoIBC_pt_51))/2
							else 0 end 
						),
			@v151_maxpos_52 = max(case when sporttype = 151 and bettype = 52 then 
								(s1+m1+a1) + (@v151_OverallMaxPT_51 - (s1+m1+a1) + @v151_AutoIBC_pt_51 - abs(@v151_OverallMaxPT_51 - (s1+m1+a1) - @v151_AutoIBC_pt_51))/2
							else 0 end 
						),
		   @v152_maxpos_41 = max(case when sporttype = 152 and bettype = 41 then 
								(s1+m1+a1) + (@v152_OverallMaxPT_41 - (s1+m1+a1) + @v152_AutoIBC_pt_41 - abs(@v152_OverallMaxPT_41 - (s1+m1+a1) - @v152_AutoIBC_pt_41))/2
							else 0 end 
						),
			@v152_maxpos_42 = max(case when sporttype = 152 and bettype = 42 then 
								(s1+m1+a1) + (@v152_OverallMaxPT_41 - (s1+m1+a1) + @v152_AutoIBC_pt_41 - abs(@v152_OverallMaxPT_41 - (s1+m1+a1) - @v152_AutoIBC_pt_41))/2
							else 0 end 
						),
		   @v152_maxpos_51 = max(case when sporttype = 152 and bettype = 51 then 
								(s1+m1+a1) + (@v152_OverallMaxPT_51 - (s1+m1+a1) + @v152_AutoIBC_pt_51 - abs(@v152_OverallMaxPT_51 - (s1+m1+a1) - @v152_AutoIBC_pt_51))/2
							else 0 end 
						),
			@v152_maxpos_52 = max(case when sporttype = 152 and bettype = 52 then 
								(s1+m1+a1) + (@v152_OverallMaxPT_51 - (s1+m1+a1) + @v152_AutoIBC_pt_51 - abs(@v152_OverallMaxPT_51 - (s1+m1+a1) - @v152_AutoIBC_pt_51))/2
							else 0 end 
						),
		   @v153_maxpos_51 = max(case when sporttype = 153 and bettype =51 then 
								(s1+m1+a1) + (@v153_OverallMaxPT_51 - (s1+m1+a1) + @v153_AutoIBC_pt_51 - abs(@v153_OverallMaxPT_51 - (s1+m1+a1) - @v153_AutoIBC_pt_51))/2
							else 0 end 
						),
			@v153_maxpos_52 = max(case when sporttype = 153 and bettype =52 then 
								(s1+m1+a1) + (@v153_OverallMaxPT_51 - (s1+m1+a1) + @v153_AutoIBC_pt_51 - abs(@v153_OverallMaxPT_51 - (s1+m1+a1) - @v153_AutoIBC_pt_51))/2
							else 0 end 
						)
	from #tmpresult t where sporttype between 151 and 153
	
	select @v151_ibc_pt_31_33 = max(case when bettype = 31 and sporttype = 151 then @v151_maxpos_31 - (s1+m1+a1) else 0 end),
			@v151_ibc_pt_32_33 = max(case when bettype = 32 and sporttype = 151 then @v151_maxpos_32 - (s1+m1+a1) else 0 end),
			@v151_ibc_pt_41_43 = max(case when bettype = 41 and sporttype = 151 then @v151_maxpos_41 - (s1+m1+a1) else 0 end),
			@v151_ibc_pt_42_43 = max(case when bettype = 42 and sporttype = 151 then @v151_maxpos_42 - (s1+m1+a1) else 0 end),
			@v151_ibc_pt_51_53 = max(case when bettype = 51 and sporttype = 151 then @v151_maxpos_51 - (s1+m1+a1) else 0 end),
			@v151_ibc_pt_52_53 = max(case when bettype = 52 and sporttype = 151 then @v151_maxpos_52 - (s1+m1+a1) else 0 end),
			@v152_ibc_pt_41_43 = max(case when bettype = 41 and sporttype = 152 then @v152_maxpos_41 - (s1+m1+a1) else 0 end),
			@v152_ibc_pt_42_43 = max(case when bettype = 42 and sporttype = 152 then @v152_maxpos_42 - (s1+m1+a1) else 0 end),
			@v152_ibc_pt_51_53 = max(case when bettype = 51 and sporttype = 152 then @v152_maxpos_51 - (s1+m1+a1) else 0 end),
			@v152_ibc_pt_52_53 = max(case when bettype = 52 and sporttype = 152 then @v152_maxpos_52 - (s1+m1+a1) else 0 end),
			@v153_ibc_pt_51_53 = max(case when bettype = 51 and sporttype = 153 then @v153_maxpos_51 - (s1+m1+a1) else 0 end),
			@v153_ibc_pt_52_53 = max(case when bettype = 52 and sporttype = 153 then @v153_maxpos_52 - (s1+m1+a1) else 0 end)
	from #tmpresult t where sporttype between 151 and 153
	
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
					@comm_5_4 = max(case when acs.bettype = 5 and acs.sporttype=1 then acs.sdiscount else 0 end), --1x2
					@HRFixedOddsComm_4 = max(case when acs.bettype = 20 and acs.sporttype = 154 then acs.sdiscount else 0 end)
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
						@comm_5_4 = MAX(CASE WHEN dcs.bettype = 5 AND dcs.sporttype = 1 THEN dcs.sdiscount ELSE 0 END) ,
						@HRFixedOddsComm_4 = max(case when dcs.bettype = 20 and dcs.sporttype = 154 then dcs.sdiscount else 0 end)
				FROM Dep_CustSetting dcs WITH (NOLOCK)
				WHERE dcs.custid = @SRecommend
				AND dcs.islive = 0
			END	

		--SELECT 3rd commission's setting from CustSetting3rd at Super level
		IF(@IsLicensee = 0)
			BEGIN
				SELECT	@v201_comm_3_4 = max(case when acs.bettype = 3 and acs.sporttype=201 then acs.sdiscount else 0 end),
					@v151_comm_31_4 = max(case when acs.bettype = 31 and acs.sporttype=151 then acs.sdiscount else 0 end),
					@v151_comm_41_4 = max(case when acs.bettype = 41 and acs.sporttype=151 then acs.sdiscount else 0 end),
					@v151_comm_51_4 = max(case when acs.bettype = 51 and acs.sporttype=151 then acs.sdiscount else 0 end),
					@v152_comm_41_4 = max(case when acs.bettype = 41 and acs.sporttype=152 then acs.sdiscount else 0 end),
					@v152_comm_51_4 = max(case when acs.bettype = 51 and acs.sporttype=152 then acs.sdiscount else 0 end),
					@v153_comm_51_4 = max(case when acs.bettype = 51 and acs.sporttype=153 then acs.sdiscount else 0 end),
					@v161_comm_81_4 = max(case when acs.bettype = 81 and acs.sporttype=161 then acs.sdiscount else 0 end)
				FROM CustSetting3rd as acs with (NOLOCK)
				WHERE acs.custid = @srecommend
			END
		ELSE
			BEGIN
				SELECT	@v201_comm_3_4 = max(case when dcs.bettype = 3 and dcs.sporttype=201 then dcs.sdiscount else 0 end),
					@v151_comm_31_4 = max(case when dcs.bettype = 31 and dcs.sporttype=151 then dcs.sdiscount else 0 end),
					@v151_comm_41_4 = max(case when dcs.bettype = 41 and dcs.sporttype=151 then dcs.sdiscount else 0 end),
					@v151_comm_51_4 = max(case when dcs.bettype = 51 and dcs.sporttype=151 then dcs.sdiscount else 0 end),
					@v152_comm_41_4 = max(case when dcs.bettype = 41 and dcs.sporttype=152 then dcs.sdiscount else 0 end),
					@v152_comm_51_4 = max(case when dcs.bettype = 51 and dcs.sporttype=152 then dcs.sdiscount else 0 end),
					@v153_comm_51_4 = max(case when dcs.bettype = 51 and dcs.sporttype=153 then dcs.sdiscount else 0 end),
					@v161_comm_81_4 = max(case when dcs.bettype = 81 and dcs.sporttype=161 then dcs.sdiscount else 0 end)
				FROM dep_CustSetting3rd as dcs with (NOLOCK)
				WHERE dcs.custid = @srecommend
				AND dcs.islive = 0
			END		
		--Select P2P commission at super level
		SELECT @v253_Comm_1_4 = MAX(CASE WHEN groupid = 1 THEN sdiscount ELSE 0 END),
			@v253_Comm_2_4 = MAX(CASE WHEN groupid = 2 THEN sdiscount ELSE 0 END)
		FROM P2PGroupComm WITH(NOLOCK)
		WHERE custid = @srecommend 
		-- 
		IF(@IsLicensee = 0)
			BEGIN
				SELECT	@ga3 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupa else 0 end),
					@gb3 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupb else 0 end),
					@gc3 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupc else 0 end),
					@gd3 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupd else 0 end),
					@othercomm3 = max(case when acs.bettype = 4 and acs.sporttype=1 then acs.adiscount else 0 end),
					@comm_5_3 = max(case when acs.bettype = 5 and acs.sporttype=1 then acs.adiscount else 0 end), --1x2
					@HRFixedOddsComm_3 = max(case when acs.bettype = 20 and acs.sporttype = 154 then acs.adiscount else 0 end)
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
					@comm_5_3 = max(case when dcs.bettype = 5 and dcs.sporttype=1 then dcs.adiscount else 0 end), --1x2
					@HRFixedOddsComm_3 = max(case when dcs.bettype = 20 and dcs.sporttype = 154 then dcs.adiscount else 0 end)
				FROM dep_custsetting as dcs with (NOLOCK)
				WHERE dcs.custid = @mrecommend
				AND dcs.islive = 0
			END

		--SELECT 3rd commission's setting from CustSetting3rd at Master Level
		IF(@IsLicensee = 0)
		BEGIN
			SELECT	@v201_comm_3_3 = max(case when acs.bettype = 3 and acs.sporttype=201 then acs.adiscount else 0 end),
				@v151_comm_31_3 = max(case when acs.bettype = 31 and acs.sporttype=151 then acs.adiscount else 0 end),
				@v151_comm_41_3 = max(case when acs.bettype = 41 and acs.sporttype=151 then acs.adiscount else 0 end),
				@v151_comm_51_3 = max(case when acs.bettype = 51 and acs.sporttype=151 then acs.adiscount else 0 end),
				@v152_comm_41_3 = max(case when acs.bettype = 41 and acs.sporttype=152 then acs.adiscount else 0 end),
				@v152_comm_51_3 = max(case when acs.bettype = 51 and acs.sporttype=152 then acs.adiscount else 0 end),
				@v153_comm_51_3 = max(case when acs.bettype = 51 and acs.sporttype=153 then acs.adiscount else 0 end),
				@v161_comm_81_3 = max(case when acs.bettype = 81 and acs.sporttype=161 then acs.adiscount else 0 end)
			FROM CustSetting3rd as acs with (NOLOCK)
			WHERE acs.custid = @mrecommend
		END
		ELSE
			BEGIN
				SELECT	@v201_comm_3_3 = max(case when dcs.bettype = 3 and dcs.sporttype=201 then dcs.adiscount else 0 end),
					@v151_comm_31_3 = max(case when dcs.bettype = 31 and dcs.sporttype=151 then dcs.adiscount else 0 end),
					@v151_comm_41_3 = max(case when dcs.bettype = 41 and dcs.sporttype=151 then dcs.adiscount else 0 end),
					@v151_comm_51_3 = max(case when dcs.bettype = 51 and dcs.sporttype=151 then dcs.adiscount else 0 end),
					@v152_comm_41_3 = max(case when dcs.bettype = 41 and dcs.sporttype=152 then dcs.adiscount else 0 end),
					@v152_comm_51_3 = max(case when dcs.bettype = 51 and dcs.sporttype=152 then dcs.adiscount else 0 end),
					@v153_comm_51_3 = max(case when dcs.bettype = 51 and dcs.sporttype=153 then dcs.adiscount else 0 end),
					@v161_comm_81_3 = max(case when dcs.bettype = 81 and dcs.sporttype=161 then dcs.adiscount else 0 end)
				FROM dep_CustSetting3rd as dcs with (NOLOCK)
				WHERE dcs.custid = @mrecommend
				AND dcs.islive = 0
			END
		
		--Select P2P commission at master level
		SELECT @v253_Comm_1_3 = MAX(CASE WHEN groupid = 1 THEN adiscount ELSE 0 END),
			@v253_Comm_2_3 = MAX(CASE WHEN groupid = 2 THEN adiscount ELSE 0 END)
		FROM P2PGroupComm WITH(NOLOCK)
		WHERE custid = @mrecommend 
		
		-- 
		IF(@IsLicensee = 0)
		BEGIN
			SELECT	@ga2 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupa else 0 end),
				@gb2 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupb else 0 end),
				@gc2 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupc else 0 end),
				@gd2 = max(case when acs.bettype = 1 and acs.sporttype=1 then acs.groupd else 0 end),
				@othercomm2 = max(case when acs.bettype = 4 and acs.sporttype=1 then acs.discount else 0 end),
				@comm_5_2 = max(case when acs.bettype = 5 and acs.sporttype=1 then acs.discount else 0 end),--1x2
				@HRFixedOddsComm_2 = max(case when acs.bettype = 20 and acs.sporttype = 154 then acs.discount else 0 end)
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
					@comm_5_2 = max(case when dcs.bettype = 5 and dcs.sporttype=1 then dcs.discount else 0 end),--1x2
					@HRFixedOddsComm_2 = max(case when dcs.bettype = 20 and dcs.sporttype = 154 then dcs.discount else 0 end)
				FROM dep_custsetting as dcs with (NOLOCK)
				WHERE dcs.custid = @recommend
				AND dcs.islive = 0
			END
		
		--SELECT 3rd commission's setting from CustSetting3rd at Agent Level
		IF(@IsLicensee = 0)
		BEGIN
			SELECT	@v201_comm_3_2 = max(case when acs.bettype = 3 and acs.sporttype=201 then acs.discount else 0 end),
				@v151_comm_31_2 = max(case when acs.bettype = 31 and acs.sporttype=151 then acs.discount else 0 end),
				@v151_comm_41_2 = max(case when acs.bettype = 41 and acs.sporttype=151 then acs.discount else 0 end),
				@v151_comm_51_2 = max(case when acs.bettype = 51 and acs.sporttype=151 then acs.discount else 0 end),
				@v152_comm_41_2 = max(case when acs.bettype = 41 and acs.sporttype=152 then acs.discount else 0 end),
				@v152_comm_51_2 = max(case when acs.bettype = 51 and acs.sporttype=152 then acs.discount else 0 end),
				@v153_comm_51_2 = max(case when acs.bettype = 51 and acs.sporttype=153 then acs.discount else 0 end),
				@v161_comm_81_2 = max(case when acs.bettype = 81 and acs.sporttype=161 then acs.discount else 0 end)
			FROM CustSetting3rd as acs with (NOLOCK)
			WHERE acs.custid = @recommend
		END
		ELSE
			BEGIN
				SELECT	@v201_comm_3_2 = max(case when dcs.bettype = 3 and dcs.sporttype=201 then dcs.discount else 0 end),
					@v151_comm_31_2 = max(case when dcs.bettype = 31 and dcs.sporttype=151 then dcs.discount else 0 end),
					@v151_comm_41_2 = max(case when dcs.bettype = 41 and dcs.sporttype=151 then dcs.discount else 0 end),
					@v151_comm_51_2 = max(case when dcs.bettype = 51 and dcs.sporttype=151 then dcs.discount else 0 end),
					@v152_comm_41_2 = max(case when dcs.bettype = 41 and dcs.sporttype=152 then dcs.discount else 0 end),
					@v152_comm_51_2 = max(case when dcs.bettype = 51 and dcs.sporttype=152 then dcs.discount else 0 end),
					@v153_comm_51_2 = max(case when dcs.bettype = 51 and dcs.sporttype=153 then dcs.discount else 0 end),
					@v161_comm_81_2 = max(case when dcs.bettype = 81 and dcs.sporttype=161 then dcs.discount else 0 end)
				FROM dep_CustSetting3rd as dcs with (NOLOCK)
				WHERE dcs.custid = @recommend
				AND dcs.islive = 0
			END
		--Select P2P commission at agent level
		SELECT @v253_Comm_1_2 = MAX(CASE WHEN groupid = 1 THEN discount ELSE 0 END),
			@v253_Comm_2_2 = MAX(CASE WHEN groupid = 2 THEN discount ELSE 0 END)
		FROM P2PGroupComm WITH(NOLOCK)
		WHERE custid = @recommend 
		 
		-- 
		IF(@IsLicensee = 0)
			BEGIN
				SELECT	@comm = isnull(max(case when acs.bettype = 1 and acs.sporttype=1 then acs.playerdiscount else 0 end), 0) ,
					@othercomm = isnull(max(case when acs.bettype = 4 and acs.sporttype=1 then acs.playerdiscount else 0 end), 0), 
					@comm_5 = isnull(max(case when acs.bettype = 5 and acs.sporttype=1 then acs.playerdiscount else 0 end), 0),--1x2 
					@HRFixedOddsComm = isnull(max(case when acs.bettype = 20 and acs.sporttype = 154 then acs.playerdiscount else 0 end), 0)
				FROM custsetting as acs with(nolock) 
				WHERE custid = @custid
			END	
		ELSE
			BEGIN
				SELECT	@comm = isnull(max(case when dcs.bettype = 1 and dcs.sporttype=1 then dcs.playerdiscount else 0 end), 0) ,
					@othercomm = isnull(max(case when dcs.bettype = 4 and dcs.sporttype=1 then dcs.playerdiscount else 0 end), 0), 
					@comm_5 = isnull(max(case when dcs.bettype = 5 and dcs.sporttype=1 then dcs.playerdiscount else 0 end), 0),--1x2
					@HRFixedOddsComm = isnull(max(case when dcs.bettype = 20 and dcs.sporttype = 154 then dcs.playerdiscount else 0 end), 0)
				FROM dep_custsetting as dcs with(nolock) 
				WHERE custid = @custid
				AND dcs.islive = 0
			END
			
		--SELECT 3rd commission's setting from CustSetting3rd at Member Level
		IF(@IsLicensee = 0)
			BEGIN
				SELECT	@v201_comm_3 = isnull(max(case when acs.bettype = 3 and acs.sporttype=201 then acs.playerdiscount else 0 end), 0),
					@v151_comm_31 = isnull(max(case when acs.bettype = 31 and acs.sporttype=151 then acs.playerdiscount else 0 end), 0), 
					@v151_comm_41 = isnull(max(case when acs.bettype = 41 and acs.sporttype=151 then acs.playerdiscount else 0 end), 0) ,
					@v151_comm_51 = isnull(max(case when acs.bettype = 51 and acs.sporttype=151 then acs.playerdiscount else 0 end), 0),
					@v152_comm_41 = isnull(max(case when acs.bettype = 41 and acs.sporttype=152 then acs.playerdiscount else 0 end), 0), 
					@v152_comm_51 = isnull(max(case when acs.bettype = 51 and acs.sporttype=152 then acs.playerdiscount else 0 end), 0),
					@v153_comm_51 = isnull(max(case when acs.bettype = 51 and acs.sporttype=153 then acs.playerdiscount else 0 end), 0),
					@v161_comm_81 = max(case when acs.bettype = 81 and acs.sporttype=161 then acs.playerdiscount else 0 end)
				FROM CustSetting3rd as acs with(nolock) 
				WHERE custid = @custid
			END		
		ELSE
			BEGIN
				SELECT	@v201_comm_3 = isnull(max(case when dcs.bettype = 3 and dcs.sporttype=201 then dcs.playerdiscount else 0 end), 0),
					@v151_comm_31 = isnull(max(case when dcs.bettype = 31 and dcs.sporttype=151 then dcs.playerdiscount else 0 end), 0), 
					@v151_comm_41 = isnull(max(case when dcs.bettype = 41 and dcs.sporttype=151 then dcs.playerdiscount else 0 end), 0) ,
					@v151_comm_51 = isnull(max(case when dcs.bettype = 51 and dcs.sporttype=151 then dcs.playerdiscount else 0 end), 0),
					@v152_comm_41 = isnull(max(case when dcs.bettype = 41 and dcs.sporttype=152 then dcs.playerdiscount else 0 end), 0), 
					@v152_comm_51 = isnull(max(case when dcs.bettype = 51 and dcs.sporttype=152 then dcs.playerdiscount else 0 end), 0),
					@v153_comm_51 = isnull(max(case when dcs.bettype = 51 and dcs.sporttype=153 then dcs.playerdiscount else 0 end), 0),
					@v161_comm_81 = max(case when dcs.bettype = 81 and dcs.sporttype=161 then dcs.playerdiscount else 0 end)
				FROM dep_CustSetting3rd as dcs with(nolock) 
				WHERE custid = @custid
				AND dcs.islive = 0
			END
		--Select P2P commission at member level
		SELECT @v253_Comm_1 = MAX(CASE WHEN groupid = 1 THEN playerdiscount ELSE 0 END),
			@v253_Comm_2 = MAX(CASE WHEN groupid = 2 THEN playerdiscount ELSE 0 END)
		FROM P2PGroupComm WITH(NOLOCK)
		WHERE custid = @custid 
		
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
				@HRFixedOddsComm_4 HRFixedOddsComm_4,
				@v201_comm_3_4 v201_comm_3_4, 
				@v151_comm_31_4 v151_comm_31_4, 
				@v151_comm_41_4 v151_comm_41_4, 
				@v151_comm_51_4 v151_comm_51_4, 
				@v152_comm_41_4 v152_comm_41_4,
				@v152_comm_51_4 v152_comm_51_4,
				@v153_comm_51_4 v153_comm_51_4, 
				@v161_comm_81_4 v161_comm_81_4, 
				@v253_comm_1_4  v253_comm_1_4,
				@v253_comm_2_4  v253_comm_2_4,				
				
				@ga3 ga3,
				@gb3 gb3,
				@gc3 gc3,
				@gd3 gd3,
				@othercomm3 othercomm3, 
				@comm_5_3 comm_5_3, 
				@HRFixedOddsComm_3 HRFixedOddsComm_3,
				@v201_comm_3_3 v201_comm_3_3, 
				@v151_comm_31_3 v151_comm_31_3,
				@v151_comm_41_3 v151_comm_41_3, 
				@v151_comm_51_3 v151_comm_51_3, 
				@v152_comm_41_3 v152_comm_41_3,
				@v152_comm_51_3 v152_comm_51_3,
				@v153_comm_51_3 v153_comm_51_3,
				@v161_comm_81_3 v161_comm_81_3, 
				@v253_comm_1_3 v253_comm_1_3,
				@v253_comm_2_3 v253_comm_2_3,
				
				@ga2 ga2,
				@gb2 gb2,
				@gc2 gc2,
				@gd2 gd2,
				@othercomm2 othercomm2, 
				@comm_5_2 comm_5_2,
				@HRFixedOddsComm_2 HRFixedOddsComm_2, 
				@v201_comm_3_2 v201_comm_3_2, 
				@v151_comm_31_2 v151_comm_31_2,
				@v151_comm_41_2 v151_comm_41_2, 
				@v151_comm_51_2 v151_comm_51_2, 
				@v152_comm_41_2 v152_comm_41_2,
				@v152_comm_51_2 v152_comm_51_2,
				@v153_comm_51_2 v153_comm_51_2, 
				@v161_comm_81_2 v161_comm_81_2,
				@v253_comm_1_2 v253_comm_1_2,
				@v253_comm_2_2 v253_comm_2_2,
				
				@comm comm,
				@othercomm othercomm, 
				@comm_5 comm_5, 
				@HRFixedOddsComm HRFixedOddsComm,
				@v201_comm_3 v201_comm_3, 
				@v151_comm_31 v151_comm_31,
				@v151_comm_41 v151_comm_41, 
				@v151_comm_51 v151_comm_51, 
				@v152_comm_41 v152_comm_41,
				@v152_comm_51 v152_comm_51,
				@v153_comm_51 v153_comm_51, 
				@v161_comm_81 v161_comm_81  , 
				@v253_comm_1  v253_comm_1,
				@v253_comm_2  v253_comm_2,  
				@ugroup ugroup,
				ISNULL(@IsMyanmarOdds,0) AS IsMyanmarOdds,
				ISNULL(@MyanmarOddsComm_1,0) AS MyanmarOddsComm_1,
				ISNULL(@MyanmarOddsComm_2,0) AS MyanmarOddsComm_2,
				ISNULL(@MyanmarOddsComm_3,0) AS MyanmarOddsComm_3,
				ISNULL(@MyanmarOddsComm_4,0) AS MyanmarOddsComm_4
	end
	--IBC pt for HR
	select	@v151_AutoIBC_pt_31 as v151_AutoIBC_pt_31,
			@v151_AutoIBC_pt_41 as v151_AutoIBC_pt_41,
			@v151_AutoIBC_pt_51 as v151_AutoIBC_pt_51,
			@v152_AutoIBC_pt_41 as v152_AutoIBC_pt_41,
			@v152_AutoIBC_pt_51 as v152_AutoIBC_pt_51,
			@v153_AutoIBC_pt_51 as v153_AutoIBC_pt_51,
			
			@v151_ibc_pt_31_33 as v151_ibc_pt_31_33, 
			@v151_ibc_pt_32_33 as v151_ibc_pt_32_33, 
			@v151_ibc_pt_41_43 as v151_ibc_pt_41_43, 
			@v151_ibc_pt_42_43 as v151_ibc_pt_42_43, 
			@v151_ibc_pt_51_53 as v151_ibc_pt_51_53, 
			@v151_ibc_pt_52_53 as v151_ibc_pt_52_53,
			@v152_ibc_pt_41_43 as v152_ibc_pt_41_43, 
			@v152_ibc_pt_42_43 as v152_ibc_pt_42_43, 
			@v152_ibc_pt_51_53 as v152_ibc_pt_51_53, 
			@v152_ibc_pt_52_53 as v152_ibc_pt_52_53, 
			@v152_ibc_pt_51_53 as v152_ibc_pt_51_53, 
			@v153_ibc_pt_51_53 as v153_ibc_pt_51_53, 
			@v153_ibc_pt_52_53 as v153_ibc_pt_52_53
End




GO
GRANT EXECUTE ON [dbo].[Acc_MT_GetPT] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_MT_GetPT] TO [vnteam]