 ALTER PROCEDURE [dbo].[Age_AnnouncementUpdShowDate_Sub] 
	@subAccID	INT,
	@custid		INT,	
	@aID		INT,
	@showDate	DATETIME
AS
	/*
		Created: Johnson
		Date: 2013-04-18
		Task: Update/Insert announcement info for sub-account
		DB: DBAGE/bodb_AGE
		
		Revisions:
		
		Parameter's Explanation:
			- @aID: ID of announcement 
			- @showDate: the date which announcement will show		
	*/
SET NOCOUNT ON

	IF EXISTS (SELECT 1 FROM Age_AnnouncementSub WITH(NOLOCK) WHERE subAccID = @subAccID and custid = @custid and aID = @aID)
	BEGIN
		UPDATE Age_AnnouncementSub WITH(UPDLOCK,ROWLOCK)
		SET showDate = @showDate, viewcount = 0
		WHERE subAccID = @subAccID AND custid = @custid AND aID = @aID
	END
	ELSE
	BEGIN
		INSERT INTO Age_AnnouncementSub(subAccID,custid,aID,showDate,viewcount)
		VALUES(@subAccID,@custid,@aID,@showDate,0)
	END


GO
GRANT EXECUTE ON [dbo].[Age_AnnouncementUpdShowDate_Sub] TO [bodbDownlineNet]