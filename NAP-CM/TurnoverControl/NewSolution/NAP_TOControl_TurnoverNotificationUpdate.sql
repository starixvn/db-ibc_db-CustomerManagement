/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[NAP_TOControl_TurnoverNotificationUpdate]
(
	@matchids			VARCHAR(1000),
	@supers				VARCHAR(1000),
	@nlevel				TINYINT = 80,
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
		SELECT m.val AS matchid, c.val AS custid
		FROM dbo.strSplit(@matchids,',') m
			INNER JOIN dbo.strSplit(@supers,',') c ON m.rank = c.rank
	)
	UPDATE t WITH(ROWLOCK, UPDLOCK)
	SET t.IsNotified = @nlevel
	FROM dbo.TOControl_Setting t
		INNER JOIN tmp ON t.matchid = tmp.matchid AND t.custid = tmp.custid
	
	IF @@ERROR <> 0
	BEGIN
		SELECT	@ErrorCode = 101,
				@ErrorMessage  = 'Update does not successfully.'
	END
END
GO