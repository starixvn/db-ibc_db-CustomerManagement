USE [CustDB]
GO

/****** Object:  UserDefinedFunction [dbo].[f_GetFinanceUser]    Script Date: 2/10/2020 5:04:10 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[f_GetFinanceUser]()
RETURNS TABLE 
/*
    Created: 20200210@Tiara
    Task: Arrange detail permission for finance account
    DB: DBCUST/CustDB, DBONUSER/ON_USER, DBAGE/bodb02
    Original versions:                
    Revision:
		- 20200210@Tiara: Arrange detail permission for finance account [Redmine: #128128]

    Parameter's Explanation:

*/
RETURN
	SELECT CONVERT (INT,676156) AS CustID
	,CONVERT(VARCHAR(3), 'A') AS GroupName
	UNION ALL SELECT 675758, 'A'
	UNION ALL SELECT 676178, 'A'
	UNION ALL SELECT 676537, 'A'
	UNION ALL SELECT 676788, 'A'
	UNION ALL SELECT 676793, 'B'
	UNION ALL SELECT 676878, 'B'

GO


