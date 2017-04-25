/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[NAP_TOControl_BalanceInfoSelect]
	@CustID INT,
	@matchid INT
AS

/*
	Created: Don
	Date: 2017-03-27
	Task: Retrieve balance information
	DB: DBAGE.bodb02
	Original: DBAGE.bodb02.NAP_SMATurnoverBalanceInfoSel

	Revisions:

	Parameter's explaination: 
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @RoleID INT
	SELECT @RoleID = RoleID FROM CustInfo WITH(NOLOCK) WHERE CustID = @CustID

	IF EXISTS (SELECT matchid FROM match WITH (NOLOCK) WHERE matchid = @matchid)
	BEGIN
		IF(@RoleID=4)
		BEGIN
			SELECT b.bettype,
				CASE WHEN b.bettype IN(1,3,7,8) THEN 
					CAST(SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS VARCHAR(30)) + ' - ' +
					CAST(SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS VARCHAR(30))
				ELSE 
					CAST(SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS VARCHAR(30)) + ' - ' +
					CAST(SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS VARCHAR(30)) + ' - ' +
					CAST(SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS VARCHAR(30))
				END BalanceInfo
			FROM bettrans b WITH(NOLOCK) 
			WHERE b.matchid = @matchid
			AND b.srecommend = @custid
			AND b.statusid NOT IN (101,102,103)
			AND b.bettype IN(1,3,5,7,8,15)
			GROUP BY b.bettype
			UNION ALL
			SELECT -1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans b WITH(NOLOCK) 
			WHERE b.matchid = @matchid
			AND b.srecommend = @custid
			AND b.statusid NOT IN (101,102,103)
			AND b.bettype NOT IN(SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
			AND b.bettype NOT IN(1,3,5,7,8,15)
			AND ((bettype < 31 and bettype NOT IN (9,29,10)) OR bettype between 121 and 999 OR bettype BETWEEN 1301 and 1334)
		END
		ELSE IF (@RoleID=3)
		BEGIN
			SELECT b.bettype,
				CASE WHEN b.bettype IN(1,3,7,8) THEN 
					CAST(SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30)) + ' - ' +
					CAST(SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30))
				ELSE 
					CAST(SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30)) + ' - ' +
					CAST(SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30)) + ' - ' +
					CAST(SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30))
				END BalanceInfo
			FROM bettrans b WITH(NOLOCK) 
			WHERE b.matchid = @matchid
			AND b.mrecommend = @custid
			AND b.statusid NOT IN (101,102,103)
			AND b.bettype IN(1,3,5,7,8,15)
			GROUP BY b.bettype
			UNION ALL
			SELECT -1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans b WITH(NOLOCK) 
			WHERE b.matchid = @matchid
			AND b.mrecommend = @custid
			AND b.statusid NOT IN (101,102,103)
			AND b.bettype NOT IN(SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
			AND b.bettype NOT IN(1,3,5,7,8,15)
			AND ((bettype < 31 and bettype NOT IN (9,29,10)) OR bettype between 121 and 999 OR bettype BETWEEN 1301 and 1334)
		END
		ELSE IF (@RoleID=2)
		BEGIN
			SELECT b.bettype,
				CASE WHEN b.bettype IN(1,3,7,8) THEN 
					CAST(SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30)) + ' - ' +
					CAST(SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30))
				ELSE 
					CAST(SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30)) + ' - ' +
					CAST(SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30)) + ' - ' +
					CAST(SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30))
				END BalanceInfo
			FROM bettrans b WITH(NOLOCK) 
			WHERE b.matchid = @matchid
			AND b.recommend = @custid
			AND b.statusid NOT IN (101,102,103)
			AND b.bettype IN(1,3,5,7,8,15)
			GROUP BY b.bettype
			UNION ALL
			SELECT -1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans b WITH(NOLOCK) 
			WHERE b.matchid = @matchid
			AND b.recommend = @custid
			AND b.statusid NOT IN (101,102,103)
			AND b.bettype NOT IN(SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
			AND b.bettype NOT IN(1,3,5,7,8,15)
			AND ((bettype < 31 and bettype NOT IN (9,29,10)) OR bettype between 121 and 999 OR bettype BETWEEN 1301 and 1334)
		END
	END
	ELSE --------------Get from bettrans14-------------
	BEGIN
		IF(@RoleID=4)
		BEGIN
			SELECT b.bettype,
				CASE WHEN b.bettype IN(1,3,7,8) THEN 
					CAST(SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30)) + ' - ' +
					CAST(SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30))
				ELSE 
					CAST(SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30)) + ' - ' +
					CAST(SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30)) + ' - ' +
					CAST(SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30))
				END BalanceInfo
			FROM bettrans14 b WITH(NOLOCK) 
			WHERE b.matchid = @matchid
			AND b.srecommend = @custid
			AND b.statusid NOT IN (101,102,103)
			AND b.bettype IN(1,3,5,7,8,15)
			GROUP BY b.bettype
			UNION ALL
			SELECT -1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans14 b WITH(NOLOCK) 
			WHERE b.matchid = @matchid
			AND b.srecommend = @custid
			AND b.statusid NOT IN (101,102,103)
			AND b.bettype NOT IN(SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
			AND b.bettype NOT IN(1,3,5,7,8,15)
			AND ((bettype < 31 and bettype NOT IN (9,29,10)) OR bettype between 121 and 999 OR bettype BETWEEN 1301 and 1334)
		END
		ELSE IF (@RoleID=3)
		BEGIN
			SELECT b.bettype,
				CASE WHEN b.bettype IN(1,3,7,8) THEN 
					CAST(SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30)) + ' - ' +
					CAST(SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30))
				ELSE 
					CAST(SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30)) + ' - ' +
					CAST(SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30)) + ' - ' +
					CAST(SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30))
				END BalanceInfo
			FROM bettrans14 b WITH(NOLOCK) 
			WHERE b.matchid = @matchid
			AND b.mrecommend = @custid
			AND b.statusid NOT IN (101,102,103)
			AND b.bettype IN(1,3,5,7,8,15)
			GROUP BY b.bettype
			UNION ALL
			SELECT -1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans14 b WITH(NOLOCK) 
			WHERE b.matchid = @matchid
			AND b.mrecommend = @custid
			AND b.statusid NOT IN (101,102,103)
			AND b.bettype NOT IN(SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
			AND b.bettype NOT IN(1,3,5,7,8,15)
			AND ((bettype < 31 and bettype NOT IN (9,29,10)) OR bettype between 121 and 999 OR bettype BETWEEN 1301 and 1334)
		END
		ELSE IF (@RoleID=2)
		BEGIN
			SELECT b.bettype,
				CASE WHEN b.bettype IN(1,3,7,8) THEN 
					CAST(SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30)) + ' - ' +
					CAST(SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30))
				ELSE 
					CAST(SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30)) + ' - ' +
					CAST(SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30)) + ' - ' +
					CAST(SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking)*abs(stake) ELSE 0 END,0)) AS NVARCHAR(30))
				END BalanceInfo
			FROM bettrans14 b WITH(NOLOCK) 
			WHERE b.matchid = @matchid
			AND b.recommend = @custid
			AND b.statusid NOT IN (101,102,103)
			AND b.bettype IN(1,3,5,7,8,15)
			GROUP BY b.bettype
			UNION ALL
			SELECT -1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans14 b WITH(NOLOCK) 
			WHERE b.matchid = @matchid
			AND b.recommend = @custid
			AND b.statusid NOT IN (101,102,103)
			AND b.bettype NOT IN(SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
			AND b.bettype NOT IN(1,3,5,7,8,15)
			AND ((bettype < 31 and bettype NOT IN (9,29,10)) OR bettype between 121 and 999 OR bettype BETWEEN 1301 and 1334)
		END
	END

END
GO