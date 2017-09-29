/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0"></info>*/
USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[TASK_TOControl_GetTransition]
AS 
/*
Created: 20170324@Francis
Task : Get data to sync to DBCUST
DB: DBAGE.bodb02

Original:

Revisions:
	- 20170920@Helen: TO Control Phase 3 - [Redmine: 75557]
Param explanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @MaxID BIGINT = 0
	DECLARE @TmpTable AS TABLE (ID BIGINT, CustID INT, matchid INT, adjusted_TurnOver MONEY, adjusted_HouseTurnOver MONEY, IsGroupHeadline BIT)

	SELECT @MaxID = CONVERT(BIGINT, VValue)
	FROM dbo.TOConTrol_GlobalVariables WITH (ROWLOCK)
	WHERE VName = 'MaxID'

	INSERT INTO @TmpTable (ID, CustID, matchid, adjusted_TurnOver, adjusted_HouseTurnOver,IsGroupHeadline) --To avoid TABLOCK escalation
	SELECT TOP (4500) ID, CustID, matchid, adjusted_TurnOver, adjusted_HouseTurnOver,IsGroupHeadline
	FROM dbo.TOControl_Transition WITH (ROWLOCK)
	WHERE ID > @MaxID

	IF @@ROWCOUNT <> 0
	BEGIN
		SELECT @MaxID = MAX(ID)
			FROM @TmpTable

		UPDATE dbo.TOConTrol_GlobalVariables WITH (UPDLOCK, ROWLOCK)
		SET VValue = CONVERT(VARCHAR(200), @MaxID)
		WHERE VName = 'MaxID'
	END

	SELECT CustID, matchid, adjusted_TurnOver, adjusted_HouseTurnOver,IsGroupHeadline
	FROM @TmpTable
END
