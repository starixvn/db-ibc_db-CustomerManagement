/*<info serverAlias="DBCUST-CUSTDB" executers=""  viewers="" isFunction="0" isNested="0"></info>*/


USE CustDB
GO
/****** Object:  StoredProcedure [dbo].[Acc_DomainListIns]    Script Date: 2/8/2023 1:03:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON 
GO
 
CREATE PROCEDURE [dbo].[Acc_DomainListIns] 
	-- Add the parameters for the stored procedure here
  @SiteLabel VARCHAR(50)  ,
  @Domain VARCHAR(50),
  @Environment VARCHAR(3) ,
  @ErrCode INT    = 0   OUTPUT,  
  @ErrMsg  NVARCHAR(20) = ''  OUTPUT 
 
AS

/*
 Created: 20230222@Helios 
 Task : Insert Domains 
 DB: DBCUST/CustDB   

 
 Revisions:  
   - 20230222@Helios: Insert Domains [Redmine: #184101]  
*/

BEGIN

IF EXISTS (Select 1 From Age_DomainList (NOLOCK) Where SiteLabel = @SiteLabel AND Domain = @Domain AND Environment = @Environment)
BEGIN  
	 SELECT @ErrMsg = N'This domain existed',  
	        @ErrCode = 100  
	RETURN  
END 
 
ELSE
BEGIN
	INSERT INTO [dbo].[Age_DomainList]
			([SiteLabel] ,[Domain] , [Environment])
	SELECT @SiteLabel  ,  @Domain , @Environment
END
 

END




