ALTER PROCEDURE [dbo].[Age_AnnouncementUpdViewcount_Sub]
	@custid INT,
	@aID	INT,
	@subaccID INT
AS
	/*
		Created: Johnson
		Date: 2013-05-17
		Task: update view count on an announcement for customer
		DB: DBAGE/bodb_AGE
		
		Revisions:
		
		Parameter's Explanation:
	*/ 
SET NOCOUNT ON 
	UPDATE Age_announcementSub WITH(UPDLOCK,ROWLOCK)
	SET viewcount = viewcount + 1
	WHERE custid = @custid AND subAccID = @subAccID AND aID = @aID


GO 
GRANT EXECUTE ON [dbo].[Age_AnnouncementUpdViewcount_Sub] TO [bodbDownlineNet] 