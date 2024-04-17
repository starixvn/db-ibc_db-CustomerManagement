/*<info serverAlias="DBBOT-bodb_ChatBot" executers="wsv_alp,wsv_alpv"  viewers="" isFunction="0" isNested="0"></info>*/

USE [bodb_ChatBot]
GO
/****** Object:  StoredProcedure [dbo].[Age_CustFeedbackCheckExists]    Script Date: 2/8/2023 1:03:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON 
GO
 
CREATE PROCEDURE [dbo].[Age_CustFeedbackCheckExists] 
-- Add the parameters for the stored procedure here
	  @custID	INT 
	, @SubAccId INT = 0
	, @FuncId	INT = NULL
	, @IsExists BIT = 0 OUTPUT 
-- ReleaseNote: Next Step Enhance ADD Index CustID ,Subaccid in table and Remove Check IF EXISTS(SELECT 1 FROM CustFeedback WITH(NOLOCK) WHERE SubAccId = @SubAccId)
 
AS  
/*    
	Created: 20230210@Helios
	Task : Check existing feedback or not  
	DB: DBBOT.bodb_ChatBot   
   
 
	Revisions:   
		- 20230210@Helios: Check existing feedback or not [Redmine: #183412]  
		- 20230328@Tacy: Alpha - Get user's feedback on specific function [RedmineID: #185515]

	Parameter's Explanation:
		• @FuncId :	 = NULL ~ current feedback [#183412]
					<> NULL ~ feedback by control 1|2
*/ 
BEGIN  
	SET NOCOUNT ON  

	IF EXISTS(SELECT 1 FROM CustFeedback WITH(NOLOCK) WHERE CustID = @custID and Subaccid = @SubAccId and @FuncId=FuncID)
		SELECT @IsExists = 1  
	ELSE   
		SELECT @IsExists = 0
END  
