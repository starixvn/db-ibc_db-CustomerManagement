/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[NAP_TOControl_TurnoverNotificationUpdate]
(
	@matchids			VARCHAR(1000),
	@supers				VARCHAR(1000),
	@IsGroupHeadlines	VARCHAR(1000),
	@nlevel				VARCHAR(4000),
	@ErrorCode			INT = 0 OUTPUT,
	@ErrorMessage		NVARCHAR(200) = '' OUTPUT
)
AS
/*
	Created: Don
	Date: 2017-03-24
	Task: Update isNotified after sending mail successfully
	DB: DBCUST.CustDB

	Revisions:

	Parameter's explaination:
*/
BEGIN
	SET NOCOUNT ON 
	
	;WITH tmp AS
	(
		SELECT m.val AS matchid, c.val AS custid, l.val AS nlevel,h.val AS IsGroupHeadline
		FROM dbo.strSplit(@matchids,',') m
			INNER JOIN dbo.strSplit(@supers,',') c ON m.rank = c.rank
			INNER JOIN dbo.strSplit(@IsGroupHeadlines,',') h ON m.rank = h.rank
			INNER JOIN dbo.strSplit(@nlevel,',') l ON m.rank = l.rank
	)
	UPDATE t WITH(ROWLOCK,UPDLOCK)
	SET t.IsNotified = tmp.nlevel
	FROM dbo.TOControl_Setting t
		INNER JOIN tmp ON t.matchid = tmp.matchid AND t.custid = tmp.custid AND t.IsGroupHeadLine = tmp.IsGroupHeadline
	
	IF @@ERROR <> 0
	BEGIN
		SELECT	@ErrorCode = 101,
				@ErrorMessage  = 'Update does not successfully.'
	END
END
GO

GRANT EXECUTE ON [dbo].[NAP_TOControl_TurnoverNotificationUpdate] TO [bodbAdminNet]
GO