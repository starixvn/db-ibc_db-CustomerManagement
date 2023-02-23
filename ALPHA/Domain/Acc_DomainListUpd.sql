/*<info serverAlias="DBCUST-CUSTDB" executers=""  viewers="" isFunction="0" isNested="0"></info>*/


USE CustDB
GO
/****** Object:  StoredProcedure [dbo].[Acc_DomainListUpd]    Script Date: 2/8/2023 1:03:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON 
GO
 
CREATE PROCEDURE [dbo].[Acc_DomainListUpd] 
	-- Add the parameters for the stored procedure here
  @SiteLabel varchar(50)  ,
  @DomainOld varchar(50) ,
  @DomainNew varchar(50) ,
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
 
 UPDATE [dbo].[Age_DomainList]
 SET Domain = @DomainNew
 WHERE SiteLabel = @SiteLabel AND Domain = @DomainOld;
 
IF @@ERROR <> 0  
   BEGIN  
    SELECT @ErrMsg = N'Update domain failed.', 
        @ErrCode = 101;  
    RETURN;  
   END  

END


