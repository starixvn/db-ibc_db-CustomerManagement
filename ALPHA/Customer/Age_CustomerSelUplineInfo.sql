/*<info serverAlias="DBACC-bodb02" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelUplineInfo]  
	@CustID INT = NULL,
	@Username VARCHAR(30) = NULL
AS  
/*  
	Creator: 20241001@Tacy  
	Task : Get upline info.
	DB: DBACC/bodb02

	Revisions:  
		- 20241001@Tacy: Create SP [Redmine: #211405]
	
	Param's Explanation:
*/
BEGIN
    SET NOCOUNT ON;

	IF ISNULL(@CustID,0)=0 AND ISNULL(@Username,'')=''
		RETURN

	IF @Username<>''
		EXEC @custid = dbo.f_GetCustIDFromUsernameOrCustId @Username,0
	
	DECLARE @tmpHeadline TABLE (
		 CustID			INT
		,CustDirect		INT
		,HeadlineID		INT
		,HeadlineName	VARCHAR(30)
		,GroupID		SMALLINT
	)

	INSERT INTO @tmpHeadline (CustID, CustDirect, HeadlineID, HeadlineName, GroupID)
	EXEC Acc_GroupHeadlineSelectByCustID @CustID=@CustID

	SELECT ci.custid, ci.username, ci.roleid
	FROM Customer c with (nolock)		
	CROSS APPLY (SELECT ci.custid, ci.username, ci.roleid
				 FROM Customer ci WITH (NOLOCK)
				 WHERE ci.CustID in (c.mrecommend, c.srecommend, c.recommend, c.custid)
				) ci	
	WHERE c.custid = @CustID AND ci.roleid>c.roleid
	UNION ALL
	--Headline info
	SELECT HeadlineID, HeadlineName, 5 AS roleid
	FROM @tmpHeadline t
	WHERE t.GroupID<>0
	ORDER BY roleid DESC
END
GO