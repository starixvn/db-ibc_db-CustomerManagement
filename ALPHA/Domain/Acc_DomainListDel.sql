/*<info serverAlias="DBCUST-CUSTDB" executers=""  viewers="" isFunction="0" isNested="0"></info>*/


USE CustDB
GO
/****** Object:  StoredProcedure [dbo].[Acc_DomainListDel]    Script Date: 2/8/2023 1:03:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON 
GO
 
CREATE PROCEDURE [dbo].[Acc_DomainListDel] 
	-- Add the parameters for the stored procedure here
  @SiteLabel VARCHAR(50)  ,
  @Domain VARCHAR(50) ,
  @ErrCode INT    = 0   OUTPUT,  
  @ErrMsg  NVARCHAR(21) = ''  OUTPUT 
 
AS

/*
 Created: 20230222@Helios 
 Task : Update Domains 
 DB: DBCUST/CustDB  

 
 Revisions:  
   - 20230222@Helios: Update Domains [Redmine: #184101]  
*/

BEGIN
 
 DELETE 
 FROM [dbo].[Age_DomainList] WITH (ROWLOCK , UPDLOCK)
 WHERE SiteLabel = @SiteLabel AND Domain = @Domain;
 
IF @@ERROR <> 0  
   BEGIN  
    SELECT @ErrMsg = N'Delete domain failed.', 
        @ErrCode = 102;  
    RETURN;  
   END  

END


