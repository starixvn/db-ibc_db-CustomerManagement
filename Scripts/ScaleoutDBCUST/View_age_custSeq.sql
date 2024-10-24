/*<info serverAlias="DBGLOB-GLOBCUSTDB" executers="wsv_nap,wsv_alp,wsv_xnap,wsv_alpv" viewers="" isFunction="0"></info>*/
CREATE VIEW [dbo].[age_custSeq]
AS
/*
	Created: Helens
	Date: 2024-07-04
	Task: Scale out dbcust - error message
	DB: DBGLOB-GLOBCUSTDB
	
	Revisions:
		- 20240704@Helen:Scale out dbcust - error message - [Redmine:206823]
		
	Parameter's Explanation:
		
*/	
SELECT [SeqName], [Type]
FROM CUSTDB.dbo.age_custSeq
