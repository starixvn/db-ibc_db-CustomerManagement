/*<info serverAlias="DBCust-CustDB,DBACC-bodb02" selecters="" viewers="" isFunction="1"></info>*/
ALTER FUNCTION [dbo].[f_NAP_VREngine_GetCustomerClass] (	
)	       
RETURNS TABLE
/*
	Created: 20210428@Eden
	Task : VR Engine - GET Customer Class
	DB: DBCUST-CUSTDB,DBACC-bodb02
	Original:

	Revisions:  
		- 20210428@Eden: First commit [Redmine:#136423]
		- 20220228@Elodie: Add new class 131,132 [Redmine:#169232]
		- 20220228@Eden: All sites - Integrate new Customer Class for PA Probation [Redmine:#170666]

	Parameter explanation:	

	Example: 
	SELECT * FROM dbo.f_NAP_VREngine_GetCustomerClass()

	*/
RETURN
	SELECT 1 AS CustomerClass , 'VIP' AS Name UNION ALL
	SELECT 111, 'VIP (111)' UNION ALL
	SELECT 112, 'VIP (112)' UNION ALL
	SELECT 113, 'VIP (113)' UNION ALL
	SELECT 2, 'Normal Member' UNION ALL
	SELECT 121, 'Normal Member (121)' UNION ALL
	SELECT 122, 'Normal Member (122)' UNION ALL
	SELECT 123, 'Normal Member (123)' UNION ALL
	SELECT 3, 'New Member' UNION ALL
	SELECT 31, 'New Member (31)' UNION ALL
	SELECT 32, 'New Member (32)' UNION ALL
	SELECT 33, 'New Member (33)' UNION ALL
	SELECT 5, 'Probation' UNION ALL
	SELECT 51, 'Probation (51)' UNION ALL
	SELECT 52, 'Probation (52)' UNION ALL
	SELECT 53, 'Probation (53)' UNION ALL
	SELECT 6, 'Smart Punter' UNION ALL
	SELECT 61, 'Smart Punter (61)' UNION ALL
	SELECT 62, 'Smart Punter (62)' UNION ALL
	SELECT 63, 'Smart Punter (63)' UNION ALL
	SELECT 7, 'High Risk Punter' UNION ALL
	SELECT 71, 'High Risk Punter (71)' UNION ALL
	SELECT 72, 'High Risk Punter (72)' UNION ALL
	SELECT 73, 'High Risk Punter (73)' UNION ALL
	--SELECT 8, 'Group Betting' UNION ALL
	--SELECT 9, 'Arbitrage' UNION ALL
	--SELECT 9, 'Irrigation Bet' UNION ALL
	--SELECT 10, 'Fixed' UNION ALL
	--SELECT 10, 'Robot Formula Bet' UNION ALL
	--SELECT 10, 'Hedging' UNION ALL
	--SELECT 11, 'AB Bet' UNION ALL
	--SELECT 11, 'Bonus Hunter' UNION ALL
	--SELECT 12, 'Info Bet' UNION ALL
	--SELECT 13, 'Robot User' UNION ALL
	--SELECT 131, 'Bad Robot' UNION ALL
	--SELECT 132, 'Good Robot' UNION ALL
	SELECT 100, 'VVIP internal' 	
	UNION ALL 
	SELECT CustomerClass,CategoryName 
	FROM CategoryConfig WITH(NOLOCK)
GO