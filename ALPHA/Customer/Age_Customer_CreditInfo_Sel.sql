/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap,wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE Age_Customer_CreditInfo_Sel
	@CustID INT
AS
/*
	Created: 20191008@Johnson
	DB: DBCUST/CustDB
	Task: Left menu - Search customer - Credit Info

	Revisions:
		- 20191008@Johnson: Initial sp[Redmine: #58776]
		- 20241107@Helios: Offer Direct Member for Super/Master [redmine: #211969]   
	Paramter's explanation:
*/

BEGIN
    SET NOCOUNT ON
	
	DECLARE 
		@roleid INT,
		@srecommend INT, 
		@mrecommend INT, 
		@recommend INT,
		@credit MONEY,
		@UsedCredit MONEY,
		@Credit_AllSuperDirectMember MONEY,
		@Credit_AllMasterDirectMember MONEY,
		@Credit_AllOtherMember MONEY,
		@Credit_AllNormalMaster MONEY,
		@Credit_AllNormalAgent MONEY,
		@Credit_AllOtherMaster MONEY

	SELECT 
		@srecommend = srecommend
	,	@mrecommend = mrecommend
	,	@recommend = recommend
	,	@roleid = roleid
	,	@credit = credit
	FROM custinfo WITH(NOLOCK)
	WHERE custid = @custid
	
	IF @roleid = 1
	BEGIN
		DECLARE @Credit_Mem_Max MONEY, 
			
			@Credit_Upline MONEY, 
			@MaxCredit_Mem MONEY, 
			@Credit_Ag_Bal MONEY	
			
		
		--Member itself
		IF @recommend = -4	-- Super Direct Member
		BEGIN
			SELECT @MaxCredit_Mem = 0

			-- Max Given Credit
			SELECT @Credit_Upline = ISNULL(credit, 0)
			FROM custinfo WITH(NOLOCK)
			WHERE custID = @srecommend

			SELECT @Credit_AllOtherMember = ISNULL(SUM(credit), 0) 
			FROM dbo.custinfo AS ci WITH (NOLOCK) 
			WHERE ci.srecommend = @srecommend AND roleid = 1 AND CustID <> @CustId AND recommend = -4

			SELECT @Credit_AllNormalMaster = ISNULL(SUM(ISNULL(Credit, 0)), 0)
			FROM dbo.custInfo WITH (NOLOCK) 
			WHERE srecommend = @srecommend AND roleid = 3

			SELECT @Credit_Ag_Bal = ISNULL(@Credit_Upline,0) - ISNULL(@Credit_AllNormalMaster,0) - ISNULL(@Credit_AllOtherMember,0)	
		END
		ELSE IF @recommend = -3	-- Master Direct Member
		BEGIN
			SELECT @MaxCredit_Mem = 0
			

			-- Max Given Credit
			SELECT @Credit_Upline = ISNULL(credit, 0)
			FROM custinfo WITH(NOLOCK)
			WHERE custID = @mrecommend

			SELECT @Credit_AllOtherMember = ISNULL(SUM(credit), 0) 
			FROM dbo.custinfo AS ci WITH (NOLOCK) 
			WHERE mrecommend = @mrecommend AND roleid = 1 AND CustID <> @CustId AND recommend = -3

			SELECT @Credit_AllNormalAgent = ISNULL(SUM(ISNULL(Credit, 0)), 0)
			FROM dbo.custInfo WITH (NOLOCK) 
			WHERE mrecommend = @mrecommend AND roleid = 2

			SELECT @Credit_Ag_Bal = ISNULL(@Credit_Upline,0) - ISNULL(@Credit_AllNormalAgent,0) - ISNULL(@Credit_AllOtherMember,0)	
		END
		ELSE				-- Normal Member
		BEGIN
			SELECT @MaxCredit_Mem = ISNULL(maxcredit,0) FROM dbo.CustAgent WITH(NOLOCK) WHERE CustID = @recommend			


			-- Max Given Credit
			SELECT @Credit_Upline = ISNULL(credit, 0)
			FROM custinfo WITH(NOLOCK)
			WHERE custID = @recommend

			SELECT @Credit_AllOtherMember = ISNULL(SUM(credit), 0) 
			FROM dbo.custinfo AS ci WITH (NOLOCK) 
			WHERE CustID <> @CustID
			AND ci.roleid = 1 AND recommend = @recommend 			

			SELECT @Credit_Ag_Bal = ISNULL(@Credit_Upline,0) - ISNULL(@Credit_AllOtherMember,0)	
		END
					
			
									
		SELECT @Credit AS Credit,
			@MaxCredit_Mem AS MaxCredit_Mem,
			@Credit_Ag_Bal AS Credit_Ag_Bal
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
			
		SELECT @Credit_AllMasterDirectMember =  ISNULL(SUM(ISNULL(credit, 0)), 0)
		FROM dbo.custInfo WITH (NOLOCK)
		WHERE mrecommend = @mrecommend AND roleid = 1 AND recommend = -3

		SELECT @Credit_Ag_Max = ISNULL(@Credit_MAg,0) - ISNULL(@Credit_AllOtherAgent,0) - ISNULL(@Credit_AllMasterDirectMember,0)
		
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
			@Credit_SAg MONEY
		
		--Master Credit_Min
		SELECT @Credit_MAg_Min = ISNULL(SUM(CASE WHEN (RoleID=2) OR (RoleID=1 AND recommend = -3) THEN credit ELSE 0 END),0)
		FROM custinfo (NOLOCK) 
		WHERE mrecommend = @custID	

		--Master Credit_Max
		SELECT	@Credit_SAg = ISNULL(credit, 0)
		FROM custinfo WITH(NOLOCK)
		WHERE custID = @srecommend	

		SELECT @Credit_AllOtherMaster = ISNULL(SUM(credit), 0) 
		FROM dbo.custinfo AS ci (NOLOCK) 
		WHERE srecommend = @Srecommend 
			AND RoleID = 3 
			AND custid <> @CustID

		SELECT @Credit_AllSuperDirectMember = ISNULL(SUM(credit), 0) 
		FROM custinfo WITH(NOLOCK)
		WHERE srecommend = @srecommend AND roleid = 1 AND recommend = -4	
		
		SELECT @Credit_MAg_Max = ISNULL(@Credit_SAg,0) - ISNULL(@Credit_AllOtherMaster,0) - ISNULL(@Credit_AllSuperDirectMember,0) 
			
		SELECT @UsedCredit = SUM(ISNULL(Credit, 0))
		FROM dbo.custinfo WITH (NOLOCK) 
		WHERE ((RoleID=2) OR (RoleID=1 AND recommend = -3)) AND mrecommend = @custid	
		
		SELECT
			@Credit AS Credit,
			@Credit_MAg_Min AS MasterCredit_Min,
			@Credit_MAg_Max AS MasterCredit_Max,
			@UsedCredit	AS masterUsedCredit
	END
	
END	
GO