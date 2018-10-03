/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet" viewers="vnteam" isFunction="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Agw_CustomerSelInfo]
	@CustID int

AS
/*
	Created: 20080909@QuiNV
	Task: Get basic information of a customer (belonging have been checked on web already)
	DB: DBCUST/CustDB
	Original:


	Revisions:
		- 20090417@[Lee]: [Add 2 return values for Casino] 
		- 20090710@Phuc: unhide IP for TB currency.
		- 20100413@Kiwi: Get transferoption from CustSuper/CustMaster/CustAgent
		- 20100513@Terry: Get Disable Open Tote Status
		- 20100928@Johnson: get DisableNumber, DisableBingo and SyncBingo column
		- 20110303@Simon: get Disable151_51, Disable152_41, Disable152_51 and Disable153_51 column
		- 20110307@Lukas: get DisableAutoMPT
		- 20120817@Sophia: get DisableVirtualSports, HideVirtualSports
		- 20120926@Sophia: Get DoubleCommLosing
		- 20140303@Kathy: Get HideKeno [Redmine:#12691]
		- 20140822@Logan: Get Esports status [Redmine: #21007]
		- 20150422@Elodie: Add Gold Deluxe product [Redmine:#34486]
		- 20150612@Kathy: Move sp from DBAGE.bodb02 to DBCUST.CustDB [Redmine:#36216]
		- 20150825@Helen: Colossus Bet - [Redmine: #41264]
		- 20151028@Helen: Member Information to support Muay Thai  [Redmine: #45496]
		- 20170601@Elodie: Migrate Inspired VS to DCS structure, add BetRadar VS product [Redmine: #77274]
		- 20180125@Winnie: Hide inactive products [RedmineID: #86086]
		- 20180918@Winnie: Esports Product - [Redmine: #101526]	
*/
BEGIN
    SET NOCOUNT ON

    DECLARE @RoleID TINYINT
          , @TransferOption VARCHAR(8)
          , @DisableAutoMPT BIT
          , @HasDownline BIT = 0
          , @uplineDisableColossusBet	BIT
		  , @recommend INT 
		  , @mrecommend INT
		  , @srecommend INT

    SELECT @RoleID = RoleID, @srecommend = @srecommend, @mrecommend = mrecommend, @recommend = recommend
    FROM custinfo WITH(NOLOCK)
    WHERE custid = @CustId

    IF (@RoleID = 4)
    BEGIN 
	    SELECT @TransferOption = dbo.F_Decimal_Binary(ISNULL(TransferOption, 0))
	      FROM CustSuper WITH(NOLOCK) 
	     WHERE custid = @CustId
	    
	    SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE srecommend = @custid AND roleid = 3 
	    
    END
    ELSE IF (@RoleID = 3)
    BEGIN 
	    SELECT @TransferOption = dbo.F_Decimal_Binary(ISNULL(TransferOption, 0)),
		       @DisableAutoMPT = DisableAutoMPT
	      FROM CustMaster WITH(NOLOCK) 
	     WHERE custid = @CustId
	     
	     SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2
	     
	    SELECT @uplineDisableColossusBet = ISNULL(DisableColossusBet, 0)
		FROM custinfo WITH(NOLOCK)
	    WHERE custID = @srecommend	
	     
	     
    END
    ELSE IF (@RoleID = 2)
    BEGIN 
	    SELECT @TransferOption = dbo.F_Decimal_Binary(ISNULL(TransferOption, 0))
	      FROM CustAgent WITH(NOLOCK) 
	     WHERE custid = @CustId
	     
	     SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE recommend = @custid AND roleid = 1
	     
	    SELECT @uplineDisableColossusBet = ISNULL(DisableColossusBet, 0)
		FROM custinfo WITH(NOLOCK)
	    WHERE custID = @mrecommend	
	    
    END
    ELSE IF (@RoleID = 1 )
    BEGIN
		
		SELECT @uplineDisableColossusBet = ISNULL(DisableColossusBet, 0)
		FROM custinfo WITH(NOLOCK)
	    WHERE custID = @recommend	
	     
    END
    
    SELECT c.username
         , firstname
         , lastname
         , iplogin
         , closed
         , reject suspended
         , c.roleid roleid
         , ISNULL(@TransferOption, 0) transferoption
         , ISNULL(@DisableAutoMPT, 0) DisableAutoMPT
        
      
         , ci.DisableOutright
         , ci.disablecasino
   
         , ci.DisableNumber
         --, ci.DisableVirtualSports
         , ci.synccasino
        
         --, ci.HideVirtualSports
         , ci.currency
         , ci.credit
         , ci.DoubleCommLosing
         , ci.HideKeno
         --, ci.DisableEsports
		 , ISNULL(ci.DisableGoldDeluxe,1) AS DisableGoldDeluxe
		 , ISNULL(ci.HideGoldDeluxe,1) AS HideGoldDeluxe
		 
		 , ISNULL(ci.DisableColossusBet,1) AS DisableColossusBet
		 , ISNULL(ci.HideColossusBet,1) AS HideColossusBet
		 , ISNULL(@uplineDisableColossusBet, 0) AS uplineDisableColossusBet
    	 , ISNULL(@HasDownline,0) AS HasDownline
    	
      FROM Customer c WITH(NOLOCK)
		INNER JOIN Custinfo ci WITH(NOLOCK) ON c.CustID = ci.CustID
     WHERE c.CustID = @CustID
     
    -- For Sportbook2
	EXEC Acc_CustSetting_StatusSettingSelect @CustID = @custid,@roleid = @roleid		    
	
END
GO
