/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_SportTypeSel]
	@Mode TINYINT = 0
AS
/*
	Created: Elodie
	Date: 20130515
	Task : Retrieve Sport type
	DB: DBAGE/bodb02

	Revisions:

	Parameter's explaination: @Mode  = 0: Sport of sportbook
									 = 1: All sports
	Example: EXEC Acc_SportTypeSel @Mode = 1									 
	
*/
SET NOCOUNT ON
SELECT DISTINCT sporttype, sportname 
FROM sports s WITH(NOLOCK) 
WHERE 1 = CASE  WHEN @Mode = 0 AND SportType <= 99 THEN 1
				WHEN @Mode = 1 THEN 1
				ELSE 0 END			
ORDER BY sporttype


