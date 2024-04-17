USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_LoginCheckGrantAccess]    Script Date: 06/30/2015 16:04:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Age_LoginCheckGrantAccess    Script Date: 12/5/2013 4:35:19 PM ******/
ALTER PROCEDURE [dbo].[Age_LoginCheckGrantAccess]  
	@CustID int,
	@LoginIP varchar(15),
	@CurrencyID int,
	@IsAccess bit = 1 OUTPUT
AS
/*
Created: Elodie
Date: 20120308
Task : Check grant access to AgentSite from outside throught test accounts
DB: DBCUST/CustDB
Original:

Revisions:
	- 20120327@Elodie: all downlines are allowed to access if upline is allowed
	- 20130123@Elodie: Add link server to DBTXNIP	
	- 20130820@Elodie: Add more range IP 10.21.10.xxx for local environment
	- 20150630@Kathy: Remove linked server DBTXNIP
	- 20170905@Elodie: Add more range IP 10.36.36.xxx for local environment
Param's Explanation:
	
*/
BEGIN	
	SET NOCOUNT ON 
	
	IF @CustID IN (1374738,2085352)   --20120623@Jamie: Allow TESTCS0101 (Agent:1374738) and supertest6(Super:2085352) login from outside 
	BEGIN
		SET @IsAccess = 1
		RETURN
	END
		
	IF @CurrencyID = 20 -- account test
	BEGIN
		DECLARE @PrefixLoginIP NVARCHAR(11)					
		SELECT  @PrefixLoginIP = left(@LoginIP, (len(@LoginIP) - (charindex('.',reverse(@LoginIP)))+1))

		DECLARE @SuperCustID int,
				@MasterCustID int,
				@Role int
		SELECT @Role = roleid, @SuperCustID = srecommend, @MasterCustID = mrecommend FROM custInfo with (NOLOCK) where custid = @CustID 

		IF @LoginIP not in (select IP FROM IPDB.dbo.IPOffice WITH (NOLOCK)) AND @PrefixLoginIP <> '10.36.36.' AND @PrefixLoginIP <> '10.19.10.' and @PrefixLoginIP <> '10.21.10.' and @LoginIP <> '127.0.0.1' and @LoginIP <> '::1' -- not in IP's Office		
		BEGIN			
			IF @Role = 4 -- super				
				IF  not (exists(select 1 from Acc_CustAllowList WITH (NOLOCK) WHERE CustID = @CustID AND isAllowed = 1))
					Select @IsAccess = 0
			IF @Role = 3 -- master
				IF	not (exists (select 1 from Acc_CustAllowList WITH (NOLOCK) WHERE (CustID = @CustID OR CustID = @SuperCustID) AND isAllowed = 1))								
					Select @IsAccess = 0
			IF @Role = 2 -- agent
				IF	not (exists (select 1 from Acc_CustAllowList WITH (NOLOCK) WHERE (CustID = @CustID OR CustID = @MasterCustID OR CustID = @SuperCustID) AND isAllowed = 1))								
					Select @IsAccess = 0
		END	
	END
END

GO
GRANT EXECUTE ON [dbo].[Age_LoginCheckGrantAccess] TO [wsv_alp] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_LoginCheckGrantAccess] TO [wsv_alpv] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_LoginCheckGrantAccess] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_LoginCheckGrantAccess] TO [vnteam] AS [dbo]