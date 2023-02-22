/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet"  viewers="" isFunction="0" isNested="1"></info>*/


USE CustDB
GO
/****** Object:  StoredProcedure [dbo].[Age_DomainListIns]    Script Date: 2/8/2023 1:03:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON 
GO
 
CREATE PROCEDURE [dbo].[Age_DomainListIns] 
	-- Add the parameters for the stored procedure here
  @SiteLabel varchar(50)  ,
  @Domain varchar(100)
 
AS

/*
 Created: 20230222@Helios 
 Task : Insert Domains 
 DB: DBCUST/CustDB   

 
 Revisions:  
   - 20230222@Helios: Insert Domains [Redmine: #184101]  
*/

BEGIN
 
 INSERT INTO [dbo].[Age_DomainList]
           ([SiteLabel] ,[Domain])
 SELECT @SiteLabel  ,  @Domain

END
