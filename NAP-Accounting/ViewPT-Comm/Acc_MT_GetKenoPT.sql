CREATE PROCEDURE [dbo].[Acc_MT_GetKenoPT_xtest]
	@username	varchar(50),  
	@Sporttype	int = 202,
	@Bettype	int,
	@ErrCode	int = 0 output,  
	@ErrMsg		varchar(100) = '' output
AS
 /*
	Created: Logan
	Date: 20140604
	Task: View PT setting of customer - Keno
	DB: DBCUST/CustDB

	Revisions:
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB, use temp table for sports, bettype)
		- 20150807@Elodie: Correct show PT for deposit customer [Redmine:#36137]

	Parameters Explanation:
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

declare @roleid int,
        @custid int,
        @srecommend int,
        @mrecommend int,
        @recommend int,
        @SAg varchar(50),
        @MAg varchar(50),
        @Ag varchar(50),
        @DisableAutoMPT bit,
        @currency tinyint,
        @s4 smallmoney, @m4 smallmoney, @a4 smallmoney,                                                     @n4 smallmoney, @l4 smallmoney,
        @s3 smallmoney, @m3 smallmoney,                 @u3 smallmoney, @i3 bit,                            @n3 smallmoney, @l3 smallmoney,
                        @m2 smallmoney, @a2 smallmoney,                          @um2 smallmoney, @im2 bit, @n2 smallmoney, @l2 smallmoney,
        @s1 smallmoney, @m1 smallmoney, @a1 smallmoney, @u1 smallmoney, @i1 bit, @um1 smallmoney, @im1 bit, @n1 smallmoney, @l1 smallmoney


declare @tmpSportBetType table
(   
    sporttype int,
    sportname nvarchar(50),
    bettype   int,
    typename  varchar(20),
    gmaxpt    smallmoney,
    seq       smallint
)

declare @bettype2 varchar(4)
select @bettype2 = case @Bettype
                     when 0 then '%'
                     else cast(@Bettype as varchar(4))
                   end

insert into @tmpSportBetType(sporttype, sportname, bettype, typename, gmaxpt, seq)
     select @Sporttype,
            b.SportName,
            a.typeid,
            a.typenamee,
            pg.MaxPositiontaking,
            ROW_NUMBER() over(order by a.typeid)
       from @tmp_Bettype a 
 inner join @tmp_Sports b on b.SportType = 202
 inner join ProductGlobalSetting pg with(nolock) on a.typeid = pg.Bettype and b.SportType = pg.Sporttype
      where 1 = 1
        and (b.SportType = 202 and a.typeid between 1501 and 1599)
        and a.typeid like @bettype2

declare @tmpresult table
(
    sporttype int, bettype int, sportname varchar(50), typename varchar(20),
    s4 smallmoney, m4 smallmoney, a4 smallmoney,                                                 n4 smallmoney, l4 smallmoney,
    s3 smallmoney, m3 smallmoney,                u3 smallmoney, i3 bit,                          n3 smallmoney, l3 smallmoney,
                   m2 smallmoney, a2 smallmoney,                        um2 smallmoney, im2 bit, n2 smallmoney, l2 smallmoney,
    s1 smallmoney, m1 smallmoney, a1 smallmoney, u1 smallmoney, i1 bit, um1 smallmoney, im1 bit, n1 smallmoney, l1 smallmoney
)

select @custid = p.custid,
       @currency = p.currency,
       @roleid = p.roleid,
       @srecommend = p.srecommend,
       @mrecommend = p.mrecommend,
       @recommend = p.recommend,
       @SAg = s.username,
       @MAg = m.username,
       @Ag = a.username,
       @DisableAutoMPT = cm.DisableAutoMPT
  from CustInfo p WITH(NOLOCK)
  left join CustInfo a with(nolock) on p.recommend = a.custid
  left join CustInfo m with(nolock) on p.mrecommend = m.custid
  left join CustInfo s with(nolock) on p.srecommend = s.custid
  left join CustMaster cm with(nolock) on m.custid = cm.custid
 where p.username = @username

if @@rowcount = 0
begin
    select @ErrCode = 101, @ErrMsg ='Invalid UserName!'
    return
end

select @custid CustID,
       @username UserName,
       @roleid RoleID,
       @currency currency,
       @srecommend SAgID,
       @mrecommend MAgID,
       @recommend AgID,
       @SAg SAg,
       @MAg MAg,
       @Ag Ag,
       @DisableAutoMPT DisableAutoMPT

declare @betCount smallint,
        @seq smallint = 1

select @betCount = MAX(seq)
  from @tmpSportBetType

DECLARE @IsLicensee INT 
SET @IsLicensee = 0 
IF(EXISTS(SELECT ci.custid FROM custInfo ci with(NOLOCK) WHERE ci.srecommend IN (SELECT * FROM dbo.f_DepSuper_1('ALL') fds) AND ci.custid = @CustID))
	SET @IsLicensee  = 1

while @seq <= @betCount
begin
    select @s4 = scs.spositiontaking,
           @m4 = scs.mpositiontaking,
           @a4 = scs.apositiontaking,
           @n4 = sco.minpositiontaking,
           @l4 = CASE WHEN @IsLicensee = 1 THEN 0 ELSE scs.spositiontaking END
      from CustSettingGame scs with(nolock)
LEFT join CustOverrideGame sco with(nolock) on scs.sporttype = sco.Sporttype and scs.bettype = sco.Bettype and sco.CustID = scs.CustID
inner join @tmpSportBetType sb on sb.bettype = scs.bettype and sb.sporttype = scs.sporttype
     where 1 = 1
       and scs.CustID = @srecommend
       and sb.seq = @seq

    select @s3 = mcs.spositiontaking,
           @m3 = mcs.mpositiontaking,
           @u3 = mcs.autopositiontaking,
           @i3 = mcs.isautopositiontaking,
           @n3 = mco.minpositiontaking,
           @l3 = CASE WHEN @IsLicensee = 1 THEN 0 ELSE sb.gmaxpt END
      from CustSettingGame mcs with(nolock)
LEFT join CustOverrideGame mco with(nolock) on mcs.sporttype = mco.Sporttype and mcs.bettype = mco.Bettype and mco.CustID = mcs.CustID
inner join @tmpSportBetType sb on sb.bettype = mcs.bettype and sb.sporttype = mcs.sporttype
--inner join ProductGlobalSetting pg with(nolock) on sb.sporttype = pg.Sporttype and sb.bettype = pg.Bettype
     where 1 = 1
       and mcs.CustID = @mrecommend
       and sb.seq = @seq
       
    select @m2 = acs.mpositiontaking,
           @a2 = acs.apositiontaking,
           @um2 = acs.autompositiontaking,
           @im2 = acs.isautompositiontaking,
           @n2 = aco.minpositiontaking,
           @l2 = CASE WHEN @IsLicensee = 1 THEN 0 ELSE sb.gmaxpt END
      from CustSettingGame acs with(nolock)
LEFT join CustOverrideGame aco with(nolock) on acs.sporttype = aco.Sporttype and acs.bettype = aco.Bettype and aco.CustID = acs.CustID
inner join @tmpSportBetType sb on sb.bettype = acs.bettype and sb.sporttype = acs.sporttype
     where 1 = 1
       and acs.CustID = @recommend
       and sb.seq = @seq
       
    select @s1 = pcs.spositiontaking,
           @m1 = pcs.mpositiontaking,
           @a1 = pcs.apositiontaking,
           @u1 = pcs.autopositiontaking,
           @i1 = pcs.isautopositiontaking,
           @um1 = pcs.autompositiontaking,
           @im1 = pcs.isautompositiontaking,
           @n1 = 0,
           @l1 = 0
      from CustSettingGame pcs with(nolock)
inner join @tmpSportBetType sb on sb.bettype = pcs.bettype and sb.sporttype = pcs.sporttype
     where 1 = 1
       and pcs.CustID = @custid
       and @roleid = 1
       and sb.seq = @seq

    insert into @tmpresult
         select 202, sb.bettype, sb.sportname, sb.typename,
                @s4, @m4, @a4,                       @n4, @l4,
                @s3, @m3,      @u3, @i3,             @n3, @l3,
                     @m2, @a2,           @um2, @im2, @n2, @l2,
                @s1, @m1, @a1, @u1, @i1, @um1, @im1, @n1, @l1
           from @tmpSportBetType sb
          where 1 = 1
            and sb.seq = @seq

    set @seq = @seq + 1
end

select * from @tmpresult order by bettype

if @@rowcount = 0
begin    
    select @ErrCode = 101,
           @ErrMsg ='Invalid Data!'  
    return    
end


GO
GRANT EXECUTE ON [dbo].[Acc_MT_GetKenoPT] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_MT_GetKenoPT] TO [vnteam]
 
 