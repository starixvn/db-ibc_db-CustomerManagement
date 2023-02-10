/*<info serverAlias="DBBOT-bodb_ChatBot" executers="bodbDownlineNet"  viewers="" isFunction="0" isNested="1"></info>*/

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
, @IsExists BIT = 0
AS  
/*  
 Created: Helios  
 Date: 2023-02-12  
 Task: Check existing feedback or not in Day 
--	DB DEV  : DBBOT/DB-61\DevDB053
--	DB LOCAL: DBBOT/TESTDB053
--	DB SIT  : DBBOT/SITDB052
--	DB LOCAL: DBBOT/DB052
--  Database: bodb_Chatbot
   
 Revisions:  
  - 20230210@Helios: Check existing feedback or not in Day
 Parameter's Explanation:
 
*/ 
BEGIN  
 SET NOCOUNT ON  
 
 DECLARE @CurrentDay date = CAST(GETDATE() As date)
 
 IF EXISTS(SELECT 1 FROM CustFeedback WITH(NOLOCK) WHERE CustID = @custID AND CAST(CreatedDate AS date) = @CurrentDay )  
   SELECT @IsExists = 1  
 ELSE   
   SELECT @IsExists = 0  
END  

 SELECT @IsExists
