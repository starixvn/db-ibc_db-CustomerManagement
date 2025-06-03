/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap,wsv_CashService" viewers="" isFunction="1"></info>*/
CREATE FUNCTION [dbo].[f_GetSubUsername](@SubAccID [int])
RETURNS [varchar](300) WITH EXECUTE AS CALLER
AS 
/*
	Created by: 
	Task: Get SubAccName
	DB: DBCust/CustDB
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]   
		
	Explanation's Param:
		
*/   
BEGIN
    Declare @SubAccName varchar(30)
    If @SubAccID > 0
        Select @SubAccName = username From dbo.custSub WITH(NOLOCK) where SubAccID = @SubAccID
    Else
        Set @SubAccName = ''
    Return isnull(@SubAccName,'')
END
GO


