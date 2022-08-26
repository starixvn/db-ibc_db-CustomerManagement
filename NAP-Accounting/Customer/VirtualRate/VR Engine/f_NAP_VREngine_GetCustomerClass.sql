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
		- 20220815@Eden: Virtual Rate - Initialize new CC IDs for all customers [Redmine:#175976]

	Parameter explanation:	

	Example: 
	SELECT * FROM dbo.f_NAP_VREngine_GetCustomerClass()

	*/
RETURN
	SELECT CustomerClass,CategoryName  AS Name
	FROM CategoryConfig WITH(NOLOCK)
	UNION ALL SELECT '200', 'New'
	UNION ALL SELECT '201', 'Good'
	UNION ALL SELECT '202', 'Normal'
	UNION ALL SELECT '203', 'Probation'
	UNION ALL SELECT '204', 'Smart'
	UNION ALL SELECT '205', 'Risky'
	UNION ALL SELECT '400', 'VIP (Problem Member)'
	UNION ALL SELECT '401', 'BA User'
	UNION ALL SELECT '901', 'Normal (inactive)'
	UNION ALL SELECT '902', 'Smart (inactive)'
	UNION ALL SELECT '999', 'VVIP'
	UNION ALL SELECT '2000', 'New linked Robot'
	UNION ALL SELECT '2001', 'Good linked Robot'
	UNION ALL SELECT '2002', 'Normal linked Robot'
	UNION ALL SELECT '2003', 'Prob linked Robot'
	UNION ALL SELECT '2004', 'Smart linked Robot'
	UNION ALL SELECT '2005', 'Risky linked Robot'
	UNION ALL SELECT '2100', 'New linked Group'
	UNION ALL SELECT '2101', 'Good linked Group'
	UNION ALL SELECT '2102', 'Normal linked Group'
	UNION ALL SELECT '2103', 'Prob linked Group'
	UNION ALL SELECT '2104', 'Smart linked Group'
	UNION ALL SELECT '2105', 'Risky linked Group'
	UNION ALL SELECT '2200', 'New linked PA'
	UNION ALL SELECT '2201', 'Good linked PA'
	UNION ALL SELECT '2202', 'Normal linked PA'
	UNION ALL SELECT '2203', 'Prob linked PA'
	UNION ALL SELECT '2204', 'Smart linked PA'
	UNION ALL SELECT '2205', 'Risky linked PA'
	UNION ALL SELECT '2303', 'Prob Group Betting'
	UNION ALL SELECT '2304', 'Smart Group Betting'
	UNION ALL SELECT '2305', 'Risky Group Betting'
	UNION ALL SELECT '2403', 'Prob High Rejected'
	UNION ALL SELECT '2404', 'Smart High Rejected'
	UNION ALL SELECT '2405', 'Risky High Rejected'
	UNION ALL SELECT '2500', 'New (Lic Sub)'
	UNION ALL SELECT '2503', 'Prob (Lic Sub)'
	UNION ALL SELECT '2504', 'Smart (Lic Sub)'
	UNION ALL SELECT '2505', 'Risky (Lic Sub)'
	UNION ALL SELECT '4000', 'VIP (Normal Member)'
GO