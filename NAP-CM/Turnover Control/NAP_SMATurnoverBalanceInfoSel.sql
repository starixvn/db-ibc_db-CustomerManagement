/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE NAP_SMATurnoverBalanceInfoSel
	@CustID INT,
	@matchid INT
AS

/*
	Created: Elodie
	Date: 20130515
	Task : Update max turnover for SMA
	DB: DBAGE/bodb02

	Revisions:
		- 20140630@Lukas: add 1 more specific level for notification - 95% [Redmine:#18384]

	Parameter's explaination: 
	
*/
SET NOCOUNT ON
BEGIN
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
	--print '';
END

/*
select matchid,recommend,count(transid) from bettrans14(nolock) where bettype in(1,3,5,7,8,15) and matchid not in( 0,9) AND statusid NOT IN (101,102,103)  
group by matchid,recommend order by count(transid) desc

select matchid,recommend,count(transid) from bettrans(nolock) where bettype NOT in(1,3,5,7,8,15) AND matchid not in( 0,9) AND ((bettype < 31 and bettype <> 10) OR bettype between 121 and 999 OR bettype BETWEEN 1301 and 1334) 
group by matchid,recommend
order by count(transid) desc
GO
Acc_SMATurnoverBalanceInfoSel 10724295, 10277575

*/

