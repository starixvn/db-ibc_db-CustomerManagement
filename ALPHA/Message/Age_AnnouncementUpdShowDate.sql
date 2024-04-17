ALTER PROCEDURE [dbo].[Age_AnnouncementUpdShowDate] 
	@custid	INT,
	@aID	INT,
	@showDate DATETIME
AS
	/*
		Created: Johnson
		Date: 2013-04-18
		Task: Update/Insert announcement info for customer
		DB: DBAGE/bodb_AGE
		
		Revisions:
		
		Parameter's Explanation:
			- @aID: ID of announcement 
			- @showDate: the date which announcement will show		
	*/
SET NOCOUNT ON

	IF EXISTS (SELECT 1 FROM Age_Announcement WITH(NOLOCK) WHERE custid = @custid and aID = @aID)
	BEGIN
		UPDATE Age_Announcement WITH(UPDLOCK,ROWLOCK)
		SET showDate = @showDate, viewcount = 0
		WHERE custid = @custid AND aID = @aID
	END
	ELSE
	BEGIN
		INSERT INTO Age_Announcement(custid,aID,showDate,viewcount)
		VALUES(@custid,@aID,@showDate,0)
	END


GO
GRANT EXECUTE ON [dbo].[Age_AnnouncementUpdShowDate] TO [wsv_alp]