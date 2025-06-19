/*<info serverAlias="DBCUST-CUSTDB" executers="" isFunction="0"></info>*/
/*
	Created: 20250307@July
	Task:  Optimize SP [redmine: #226488]
	DB:DBCUST/CUSTDB
*/
USE CUSTDB
GO
IF EXISTS (
	SELECT * FROM sys.key_constraints 
	WHERE [name] = 'PK_WinLimit_CustWinlostGame'
)
BEGIN
	ALTER TABLE dbo.WinLimit_CustWinlostGame 
	DROP CONSTRAINT PK_WinLimit_CustWinlostGame;
END

--Change the column order in the index 
ALTER TABLE [dbo].[WinLimit_CustWinlostGame] ADD  CONSTRAINT [PK_WinLimit_CustWinlostGame] PRIMARY KEY CLUSTERED 
(
	[WinlostDate] ASC,
	[CustId] ASC,
	[BetType] ASC
	
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [WinlimitSetting_Tables]
GO
