/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet"  viewers="" isFunction="0" isNested="1"></info>*/


USE CustDB
GO
/****** Object:  StoredProcedure [dbo].[Age_DomainListUpd]    Script Date: 2/8/2023 1:03:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON 
GO
 
CREATE PROCEDURE [dbo].[Age_DomainListUpd] 
	-- Add the parameters for the stored procedure here
  @SiteLabel varchar(50)  ,
  @DomainOld varchar(100) ,
  @DomainNew varchar(100)
 
AS

/*
 Created: 20230222@Helios 
 Task : Update Domains 
 DB: DBCUST/CustDB  

 
 Revisions:  
   - 20230222@Helios: Update Domains [Redmine: #184101]  
*/

BEGIN
 
 UPDATE [dbo].[Age_DomainList]
 SET Domain = @DomainNew
 WHERE SiteLabel = @SiteLabel AND Domain = @DomainOld
 
END
