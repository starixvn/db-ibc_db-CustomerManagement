USE [CustDB]
GO

/****** Object:  UserDefinedFunction [dbo].[f_CS_GetFinanceUser]    Script Date: 2/10/2020 5:04:10 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[f_CS_GetFIPermission]()
RETURNS TABLE 
/*
    Created: 20200211@Tiara
    Task: Arrange detail permission for finance account
    DB: DBCUST/CustDB, DBONUSER/ON_USER, DBAGE/bodb02
    Original versions:                
    Revision:
		- 20200211@Tiara: Arrange detail permission for finance account [Redmine: #128128]

    Parameter's Explanation:

*/
RETURN
	SELECT CONVERT(VARCHAR(3), 'A') AS GroupName
	, CONVERT (VARCHAR(5),'All') AS Permission
	UNION ALL SELECT 'B', 'B'

GO

