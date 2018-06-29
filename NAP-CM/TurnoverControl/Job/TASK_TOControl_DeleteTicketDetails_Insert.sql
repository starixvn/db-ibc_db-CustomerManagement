/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[TASK_TOControl_DeleteTicketDetails_Insert]
AS 
/*
	Created: 20180629@Helen
	Task : Delete old data for TOControl_TicketDetails_Insert
	DB: DBAGE.bodb02

	Original:

	Revisions:
		20180629@Helen: Delete old data for TOControl_TicketDetails_Insert - [Redmine:97442]
	Param explanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @MaxID BIGINT = 0

	SELECT @MaxID = sValue
	FROM dbo.TOControl_Tickets_Setting WITH (ROWLOCK)
	WHERE sKey = 'TOControl_Insert'

	--Keep 10000 very first rows in the table
	IF @MaxID - 10000 <= 0
		RETURN

	SET @MaxID = @MaxID - 10000

	WHILE EXISTS (SELECT 1 FROM dbo.TOControl_TicketDetails_Insert WITH (NOLOCK) WHERE rowid < @MaxID) --To avoid TABLOCK escalation
	BEGIN
		DELETE TOP (4500)
		FROM dbo.TOControl_TicketDetails_Insert WITH (UPDLOCK, ROWLOCK)
		WHERE rowid < @MaxID
	END		

END
GO