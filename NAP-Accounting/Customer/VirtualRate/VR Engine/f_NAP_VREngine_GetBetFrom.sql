/*<info serverAlias="DBCust-CustDB,DBACC-bodb02" selecters="" viewers="" isFunction="1"></info>*/
ALTER FUNCTION [dbo].[f_NAP_VREngine_GetBetFrom] (	
)	       
RETURNS TABLE
/*
	Created: 20210428@Eden
	Task : VR Engine - GET Customer Class
	DB: DBCUST-CUSTDB,DBACC-bodb02
	Original:

	Revisions:  
	- 20210428@Eden: First commit [Redmine:#136423]

	Parameter explanation:	

	Example: 
	SELECT * FROM dbo.f_NAP_VREngine_GetBetFrom()

	*/
RETURN
	SELECT 'p' BetFrom, 'Phone Betting' AS Name
	UNION ALL SELECT 'z', 'Desktop/China View' 
GO