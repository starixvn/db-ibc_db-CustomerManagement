/*<info serverAlias="DBCust-CustDB" selecters="bodbAdminNet,wsv_nap,bodbDownlineNet,wsv_alp,bodbExtAccNet,wsv_xnap,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="1"></info>*/
ALTER FUNCTION [dbo].[f_CustSetting_UM_GetProductBySportype](@Sporttype  SMALLINT)
RETURNS TABLE
AS
/*
Created: 20200720@Eden
Task :  get ProductID By Sportype use for block UM
DB: DBCUST.CustDB
Revisions:	
	- 20200720@Eden: Minimize UM Time - Lock Update Customer setting [Redmine: #136464]
Param's Explanation:
Examples : 
	SELECT ProductID FROM [dbo].[f_CustSetting_UM_GetProductBySportype](255)
*/

RETURN
	SELECT CASE WHEN @Sporttype IN (161, 164) THEN 3
				WHEN @Sporttype IN (208, 209, 210, 251) THEN 6
				WHEN @Sporttype = 202 THEN 8
				WHEN @Sporttype = 255 THEN 12
	END ProductID
GO