/*<info serverAlias="DBBOT-SITDB052" executers="bodbExtAccNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/

USE [bodb_ChatBot]
GO
/****** Object:  StoredProcedure [dbo].[Age_CustFeedbackIns]    Script Date: 2/8/2023 1:03:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON 
GO

CREATE PROCEDURE [dbo].[Age_CustFeedbackIns] 
	-- Add the parameters for the stored procedure here
  @custID int
, @comment Nvarchar(4000)
, @Rate tinyint

AS
--- EXEC Age_CustFeedbackIns 340942 , N'Hoa hồng luôn có mặt trong các ngày lễ hội, liên hoan, sinh nhật, đám cưới. Ngoài ra, tinh dầu hoa hồng còn dùng để làm dầu thơm rất được ưa chuộng. Riêng đối với em, hoa hồng đã tô điểm cho vườn kiểng nhà em thêm xinh tươi. Em rất quý hoa vì những bông hoa có được là do ba em trồng..' , '5'

/*
Created : 2/8/2023 1:03:18 PM
--	DB DEV  : DBBOT/DB-61\DevDB053
--	DB LOCAL: DBBOT/TESTDB053
--	DB SIT  : DBBOT/SITDB052
--	DB LOCAL: DBBOT/DB052
--  Database: bodb_Chatbot
Task : Insert Feedback by SMA in AlphaSite
 Revisions:  
   - 20230208@Helios: Insert Feedback by SMA in AlphaSite  [Redmine: #183412]  
*/

BEGIN
 
 INSERT INTO  [dbo].[CustFeedback] ([CustID],[Comment],[Rate],[CreatedDate])
    select    @custID , ISNULL(@comment , '') , ISNULL (@Rate , 0) , Getdate()

END