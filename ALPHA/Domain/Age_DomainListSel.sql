/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,bodbDownlineNetView"  viewers="" isFunction="0" isNested="1"></info>*/

USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_DomainListSel]    Script Date: 2/8/2023 1:03:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON 
GO
 
CREATE PROCEDURE [dbo].[Age_DomainListSel] 
	-- Add the parameters for the stored procedure here
  @SiteLabel varchar(50)  

AS

/*
 Created: 20230222@Helios 
 Task : Select DomainList Of SiteLabel 
 DB: DBCUST/CustDB

 
 Revisions:  
   - 20230222@Helios: Select DomainList Of SiteLabel [Redmine: #184101]  
*/

BEGIN
 
 SELECT SiteLabel , Domain FROM dbo.Age_DomainList WITH (NOLOCK)
 WHERE SiteLabel = @SiteLabel

END
