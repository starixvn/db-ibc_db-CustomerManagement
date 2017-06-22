ALTER PROCEDURE [dbo].[Age_CustSubPageAccessSel]
	@SubAccID int,
	@PageAccess varchar(50) = '' OUTPUT
AS
	/*
		Created: Kiwi
		Date: 2015-02-28
		Task: Get Sub Acc Page Access
		DB: DBAGE/BODB02
		
		Revisions:
		
		Parameter's Explanation:
	*/
BEGIN
	SET NOCOUNT ON
	SELECT @PageAccess = PageAccess
	FROM CustSub WITH(NOLOCK)
	WHERE subAccID = @SubAccID
	
	SELECT @PageAccess = ISNULL(@PageAccess,0) 
	
END	

GO
GRANT EXECUTE ON [dbo].[Age_CustSubPageAccessSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustSubPageAccessSel] TO [vnteam] AS [dbo]