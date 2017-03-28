/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0"></info>*/
USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[TASK_TOControl_DeleteOldTransition]
AS 
/*
Created: 20170324@Francis
Task : Delete old data for TOControl_Transition
DB: DBAGE.bodb02

Original:

Revisions:

Param explanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @MaxID BIGINT = 0

	SELECT @MaxID = CONVERT(BIGINT, VValue)
	FROM dbo.TOConTrol_GlobalVariables WITH (ROWLOCK)
	WHERE VName = 'MaxID'

	IF @MaxID > 100000 --Keep 10000 very first rows in the table 
		WHILE EXISTS (SELECT 1 FROM dbo.TOControl_Transition WITH (NOLOCK) WHERE ID < @MaxID) --To avoid TABLOCK escalation
			DELETE TOP (4500)
			FROM dbo.TOControl_Transition WITH (UPDLOCK, ROWLOCK)
			WHERE ID < @MaxID
END