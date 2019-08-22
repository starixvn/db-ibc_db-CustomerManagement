/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet, bodbDownlineNet,bodbDownlineNetView" isFunction="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[Age_BalanceMemberSel]
	@CustID INT
AS
/*
	Created: 20180627@Elodie
	DB: DBAGE/bodb02
	Task: Left menu - Search customer - Balance Info

	Revisions:
		- 20180627@Elodie: Left menu - Search customer - Balance Info [Redmine: #58776]
		- 20190723@Percy: Member level - Don't calculate Cash & Outstanding amount [RedmineID: #117334]

	Example: EXEC Age_BalanceMemberSel @CustID=1382337
*/

BEGIN
    SET NOCOUNT ON

    DECLARE @roleid TINYINT, @srecommend INT, @mrecommend INT, @recommend INT, @Credit MONEY
    DECLARE @Credit_Mem_Max MONEY, @Credit_AllOtherMember MONEY, @Credit_Ag MONEY, @MaxCredit_Mem MONEY, @Credit_Ag_Bal MONEY

	SELECT @roleid = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend, @Credit = credit
	FROM custinfo WITH(NOLOCK)
    WHERE custid = @custid AND roleid = 1

	IF @roleid <> 1 RETURN
    		
	--Upline
	SELECT	@Credit_Ag = ISNULL(credit, 0)
	FROM custinfo WITH(NOLOCK)
	WHERE custID = @recommend	

	--Member itself
	SELECT @Credit_AllOtherMember = ISNULL(SUM(credit), 0) FROM DBCUST.CustDB.dbo.custinfo AS ci WITH (NOLOCK) WHERE recommend = @recommend AND RoleID = 1 AND CustID <> @CustID
    	
	SELECT @MaxCredit_Mem = ISNULL(maxcredit,0) FROM DBCUST.CustDB.dbo.CustAgent WITH(NOLOCK) WHERE CustID = @recommend
    	
	SELECT @Credit_Ag_Bal = ISNULL(@Credit_Ag,0) - ISNULL(@Credit_AllOtherMember,0)
	    
	SELECT @Credit_Mem_Max = CASE WHEN @MaxCredit_Mem =0 THEN @Credit_Ag_Bal
								    WHEN @MaxCredit_Mem > @Credit_Ag_Bal THEN @Credit_Ag_Bal 
								    ELSE @MaxCredit_Mem 
							    END 
	
	-- Net Balance: get data from other SP

    -------------------------------------------------------------------------
	-- Balance Info
	CREATE TABLE #BalanceInfo
	(
		superCash	MONEY DEFAULT ((0)), yesterdaySuperCash	 MONEY DEFAULT ((0)),
		masterCash	MONEY DEFAULT ((0)), yesterdayMasterCash MONEY DEFAULT ((0)),
		agentCash	MONEY DEFAULT ((0)), yesterdayAgentCash	 MONEY DEFAULT ((0)),
		memberCash	MONEY DEFAULT ((0)), yesterdayMemberCash MONEY DEFAULT ((0))
	)

	INSERT INTO #BalanceInfo
	(
		superCash,  yesterdaySuperCash,
		masterCash, yesterdayMasterCash,
		agentCash,  yesterdayAgentCash,
		memberCash, yesterdayMemberCash
	)
	EXEC dbo.Acc_CustomerSelCash @CustId = @CustId

	SELECT
		@custid AS CustID,
		@Credit AS Credit,
		@Credit_Mem_Max AS [MemMaxCredit_Max],
		SUM(yesterdayMemberCash) AS yesterday_Cash
		-- Cash & Outstanding: get from other SP
	FROM #BalanceInfo

	DROP TABLE #BalanceInfo
END
