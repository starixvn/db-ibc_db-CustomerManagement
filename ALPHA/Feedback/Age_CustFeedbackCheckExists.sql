/*<info serverAlias="DBBOT-bodb_ChatBot" executers="bodbDownlineNet,bodbDownlineNetView"  viewers="" isFunction="0" isNested="1"></info>*/

USE [bodb_ChatBot]
GO
/****** Object:  StoredProcedure [dbo].[Age_CustFeedbackCheckExists]    Script Date: 2/8/2023 1:03:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON 
GO
 
CREATE PROCEDURE [dbo].[Age_CustFeedbackCheckExists] 
	-- Add the parameters for the stored procedure here
  @custID int 
, @SubAccId int 
, @IsExists BIT = 0 OUTPUT 
 -- Input @custID to check exists
 -- EXEC Age_CustFeedbackCheckExists 123 
AS  
/*    
 Created: 20230210@Helios
 Task : Check existing feedback or not  
 DB: DBBOT.bodb_ChatBot   
   
 
 Revisions:   
  - 20230210@Helios: Check existing feedback or not [Redmine: #183412]  
 Parameter's Explanation:
 
*/ 
BEGIN  
 SET NOCOUNT ON  
 IF (@SubAccId  = 0)
 BEGIN 
	IF EXISTS(SELECT 1 FROM CustFeedback WITH(NOLOCK) WHERE CustID = @custID and Subaccid = @SubAccId)
	SELECT @IsExists = 1  
	ELSE   
	SELECT @IsExists = 0
 END
 ELSE
 IF EXISTS(SELECT 1 FROM CustFeedback WITH(NOLOCK) WHERE SubAccId = @SubAccId)  
   SELECT @IsExists = 1  
 ELSE   
   SELECT @IsExists = 0  
END  
