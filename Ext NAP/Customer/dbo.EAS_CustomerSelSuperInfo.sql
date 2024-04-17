/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_xnap" viewers="vnteam" isFunction="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[EAS_CustomerSelSuperInfo] @CustId INT
AS  
/*  
Created by: 20180731@Razor
Task : Splitting Super Profile
DB: DBCUST/CustDB
Revisions:  
	- 20180731@Razor: Splitting Super Profile [#86934]
*/  
BEGIN    
    SET NOCOUNT ON  
	
	SELECT [custid]
      ,[firstname]
      ,[lastname]
      ,[phone]
      ,[mobilephone]
      ,[fax]
      ,[email]
      ,[remark]
  FROM [dbo].[CustSuperProfile] WITH(NOLOCK)
  WHERE custid = @CustId
  
END
GO