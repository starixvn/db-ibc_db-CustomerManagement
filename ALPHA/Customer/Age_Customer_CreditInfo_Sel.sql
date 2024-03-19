/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,wsv_nap, bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE Age_Customer_CreditInfo_Sel
	@CustID INT
AS
/*
	Created: 20191008@Johnson
	DB: DBCUST/CustDB
	Task: Left menu - Search customer - Credit Info

	Revisions:
		- 20191008@Johnson: Initial sp[Redmine: #58776]

	Paramter's explanation:
*/

BEGIN
    SET NOCOUNT ON
	
	DECLARE @roleid INT,
			@srecommend INT, 
			@mrecommend INT, 
			@recommend INT,
			@credit MONEY,
			@UsedCredit MONEY
		
	SELECT @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend
		,@roleid = roleid,@credit = credit
	FROM custinfo WITH(NOLOCK)
	WHERE custid = @custid
	
	IF @roleid = 1
	BEGIN
		DECLARE @Credit_Mem_Max MONEY, 
			@Credit_AllOtherMember MONEY, 
			@Credit_Ag MONEY, 
			@MaxCredit_Mem MONEY, 
			@Credit_Ag_Bal MONEY
			
		--Upline
		SELECT	@Credit_Ag = ISNULL(credit, 0)
		FROM custinfo WITH(NOLOCK)
		WHERE custID = @recommend	

		--Member itself
		SELECT @Credit_AllOtherMember = ISNULL(SUM(credit), 0) 
		FROM dbo.custinfo AS ci WITH (NOLOCK) 
		WHERE recommend = @recommend 
			AND RoleID = 1 
			AND CustID <> @CustID
			
		SELECT @MaxCredit_Mem = ISNULL(maxcredit,0) 
		FROM dbo.CustAgent WITH(NOLOCK) WHERE CustID = @recommend
			
		SELECT @Credit_Ag_Bal = ISNULL(@Credit_Ag,0) - ISNULL(@Credit_AllOtherMember,0)
			
		SELECT @Credit_Mem_Max = CASE WHEN @MaxCredit_Mem =0 THEN @Credit_Ag_Bal
										WHEN @MaxCredit_Mem > @Credit_Ag_Bal THEN @Credit_Ag_Bal 
										ELSE @MaxCredit_Mem 
									END
									
		SELECT @Credit AS Credit,
			@Credit_Mem_Max AS MemMaxCredit_Max
	END
	ELSE IF @roleid = 2
	BEGIN
		DECLARE  @Mem_MaxCredit MONEY,
				@Credit_Ag_Min MONEY, 
				@Credit_Ag_Max MONEY, 
				@Credit_Mem_Min MONEY,
				@Credit_AllOtherAgent MONEY, 
				@Credit_MAg MONEY
				
		--Upline
		SELECT	@Credit_MAg = ISNULL(credit, 0)
		FROM custinfo WITH(NOLOCK)
		WHERE custID = @mrecommend	

		--Agent Itself		
		SELECT @Credit_AllOtherAgent = ISNULL(SUM(credit), 0) 
		FROM dbo.custinfo AS ci WITH(NOLOCK) 
		WHERE mrecommend = @mrecommend 
			AND RoleID = 2 
			AND Custid <> @custID
			
		SELECT @Credit_Ag_Max = ISNULL(@Credit_MAg,0) - ISNULL(@Credit_AllOtherAgent,0)	
		
		SELECT @Credit_Ag_Min = ISNULL(SUM(credit),0),
				@Credit_Mem_Min = ISNULL(MAX(credit),0),
				@UsedCredit = SUM(ISNULL(Credit, 0))	
		FROM custinfo (NOLOCK) 
		WHERE recommend = @custID AND RoleID=1
				
		SELECT @Mem_MaxCredit = ISNULL(maxcredit,0)
		FROM dbo.CustAgent WITH (NOLOCK) 
		WHERE custid = @CustID 
		
		SELECT
			@Credit AS Credit,
			@Credit_Ag_Min AS AgentCredit_Min,
			@Credit_Ag_Max AS AgentCredit_Max,
			@Credit_Mem_Min AS MemMaxCredit_Min,
			@UsedCredit	AS agentUsedCredit,
			@Mem_MaxCredit AS memberMaxCredit
	END
	ELSE IF @roleid = 3
	BEGIN
		DECLARE @Credit_MAg_Min MONEY, 
			@Credit_MAg_Max MONEY,
			@Credit_AllOtherMaster MONEY, 
			@Credit_SAg MONEY
		
		--Upline
		SELECT	@Credit_SAg = ISNULL(credit, 0)
		FROM custinfo WITH(NOLOCK)
		WHERE custID = @srecommend	

		--Master Itself
		SELECT @Credit_AllOtherMaster = ISNULL(SUM(credit), 0) 
		FROM dbo.custinfo AS ci (NOLOCK) 
		WHERE srecommend = @Srecommend 
			AND RoleID = 3 
			AND custid <> @CustId
		
		SELECT @Credit_MAg_Max = ISNULL(@Credit_SAg,0) - ISNULL(@Credit_AllOtherMaster,0)	
			
		SELECT @Credit_MAg_Min = ISNULL(SUM(CASE WHEN RoleID=2 THEN credit ELSE 0 END),0)
		FROM custinfo (NOLOCK) 
		WHERE mrecommend = @custID	
			
		SELECT @UsedCredit = SUM(ISNULL(Credit, 0))
		FROM dbo.custinfo WITH (NOLOCK) 
		WHERE roleid = 2 AND mrecommend = @custid	
		
		SELECT
			@Credit AS Credit,
			@Credit_MAg_Min AS MasterCredit_Min,
			@Credit_MAg_Max AS MasterCredit_Max,
			@UsedCredit	AS masterUsedCredit
	END
	
END	
GO