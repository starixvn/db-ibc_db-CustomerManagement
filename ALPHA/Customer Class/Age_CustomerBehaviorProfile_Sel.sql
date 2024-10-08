/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CustomerBehaviorProfile_Sel
	  @CustID	INT
	, @Language	VARCHAR(2)='E'
	, @Errcode	INT=0	OUTPUT
	, @ErrMsg	NVARCHAR(MAX)='' OUTPUT
AS  
/*  
	Created:	20240424@Tacy
	Task:		Get customer profile
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20240424@Tacy: Alpha - Risk Management - Member Betting Behavior [Redmine:#204089]
	    - 20240816@Tacy: Return CustomerClass [Redmine:#209412]

	Param's Explanation:  	
		
	Example:
		
*/  
BEGIN 
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM Customer WITH (NOLOCK) WHERE custid=@CustID AND roleid=1)
	BEGIN
		SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Member username is invalid.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40067,@Language) END,
				@ErrCode = 100
		RETURN
	END

	SELECT ci.custid, ci.username
		, ci.CustomerClass
		, CASE WHEN wl.CustID IS NOT NULL THEN 1 ELSE 0 END AS IsMonitoredMember
		, CASE WHEN p.custid IS NOT NULL AND cc.CustomerClass IS NOT NULL THEN 1 ELSE 0 END AS IsProblemAccount
	FROM custInfo ci WITH (NOLOCK)
		LEFT JOIN ProblemAccountClassification p WITH(NOLOCK) ON ci.custid = p.custid
		OUTER APPLY (SELECT TOP 1 cc.CustomerClass FROM CategoryConfig cc WITH (NOLOCK) 
					 WHERE cc.CustomerClass=ci.CustomerClass
					 AND cc.HiddenSite NOT IN (1,3)) cc
		LEFT JOIN WLMonitored_Player wl WITH(NOLOCK) ON ci.CustID=wl.CustID
	WHERE ci.custid=@CustID
END
GO