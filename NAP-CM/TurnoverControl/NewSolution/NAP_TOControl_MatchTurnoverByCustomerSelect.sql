/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="1"></info>*/

ALTER PROCEDURE [dbo].[NAP_TOControl_MatchTurnoverByCustomerSelect]
	@CustID INT,
	@RoleID TINYINT
AS
/*
	Created: Don
	Date: 2017-03-28
	Task: ???
	DB: DBAGE.bodb02

	Revisions:

	Parameter's explaination: 
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @MatchList TABLE (matchid INT)
	
	INSERT INTO @MatchList(matchid)
		SELECT m.matchid
		FROM bodb02.dbo.match m WITH(NOLOCK)
		WHERE m.eventstatus <> 'completed'

	IF (@RoleID = 4)
	BEGIN
		SELECT 
			b.matchid, 
			SUM(b.stake) AS SumOfStake, 
			SUM((1-b.tpositiontaking)*b.stake) AS HouseTurnover
		FROM bodb02.dbo.bettrans b WITH(NOLOCK)
			INNER JOIN @MatchList m ON b.matchid = b.matchid
		WHERE b.srecommend = @CustID
			AND b.statusid NOT BETWEEN 101 AND 103
			AND b.ruben = 0
			AND ((bettype < 31 and bettype NOT IN (9,29,10)) OR bettype between 121 and 999 OR bettype BETWEEN 1301 and 1334)
		GROUP BY b.matchid

	END
	ELSE IF (@RoleID = 3)
	BEGIN
		SELECT 
			b.matchid, 
			SUM(b.stake) AS SumOfStake, 
			SUM((1-b.tpositiontaking)*b.stake) AS HouseTurnover
		FROM bodb02.dbo.bettrans b WITH(NOLOCK)
			INNER JOIN @MatchList m ON b.matchid = b.matchid
		WHERE b.mrecommend = @CustID
			AND b.statusid NOT BETWEEN 101 AND 103
			AND b.ruben = 0
			AND ((bettype < 31 and bettype NOT IN (9,29,10)) OR bettype between 121 and 999 OR bettype BETWEEN 1301 and 1334)
		GROUP BY b.matchid

	END
	ELSE IF (@RoleID = 2)
	BEGIN
		SELECT 
			b.matchid, 
			SUM(b.stake) AS SumOfStake,
			SUM((1-b.tpositiontaking)*b.stake) AS HouseTurnover
		FROM bodb02.dbo.bettrans b WITH(NOLOCK)
			INNER JOIN @MatchList m ON b.matchid = b.matchid
		WHERE b.recommend = @CustID
			AND b.statusid NOT BETWEEN 101 AND 103
			AND b.ruben = 0
			AND ((bettype < 31 and bettype NOT IN (9,29,10)) OR bettype between 121 and 999 OR bettype BETWEEN 1301 and 1334)
		GROUP BY b.matchid

	END

END
GO