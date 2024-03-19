 ALTER PROCEDURE [dbo].[Age_AnnouncementSelShowDate_Sub]
	@subAccID	INT,
	@custid		INT,
	@aID		INT,
	@showDate DATETIME = NULL OUTPUT,
	@viewcount INT = 0 OUTPUT
AS
	/*
		Created: Johnson
		Date: 2013-04-18
		Task: Get show date of announcement for sub-account
		DB: DBAGE/bodb_AGE
		
		Revisions:
		
		Parameter's Explanation:
			- @aID: ID of announcement 
			- @showDate: the date which announcement will show			
	*/ 
SET NOCOUNT ON
	SELECT @showDate = showDate, @viewcount = ISNULL(viewcount,0)
	FROM Age_AnnouncementSub WITH(NOLOCK)
	WHERE subAccID = @subAccID and custid = @custid AND aID = @aID
	
	

GO
GRANT EXECUTE ON [dbo].[Age_AnnouncementSelShowDate] TO [bodbDownlineNet,wsv_alp]