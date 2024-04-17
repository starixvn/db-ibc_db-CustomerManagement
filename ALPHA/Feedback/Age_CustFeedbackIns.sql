/*<info serverAlias="DBBOT-bodb_ChatBot" executers="wsv_alp"  viewers="" isFunction="0" isNested="0"></info>*/

USE [bodb_ChatBot]
GO
/****** Object:  StoredProcedure [dbo].[Age_CustFeedbackIns]    Script Date: 2/8/2023 1:03:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON 
GO
 
CREATE PROCEDURE [dbo].[Age_CustFeedbackIns] 
	-- Add the parameters for the stored procedure here
	  @custID	INT
	, @Subaccid	INT
	, @comment	NVARCHAR(4000)
	, @Rate		TINYINT 
	, @FuncID	INT=NULL
	, @XMLfb	NVARCHAR(MAX)=NULL
AS
/*
	Created: 20230210@Helios 
	Task : Insert Feedback by SMA in AlphaSite   
	DB: DBBOT.bodb_ChatBot   
 
	Revisions:  
	- 20230210@Helios: Insert Feedback by SMA in AlphaSite [Redmine: #183412] 
	- 20230328@Tacy: Alpha - Get user's feedback on specific function

	Parameter's Explanation:
		• @FuncId :	 = NULL ~ current feedback [#183412]
					<> NULL ~ feedback by control 1|2

		• @XMLfb : = NULL ~ current feedback [#183412] & feedback by control 2
				  <> NULL ~ feedback by control 1

	Example:
		EXEC Age_CustFeedbackIns 340942 , 123 , N'Hoa hồng luôn có mặt trong các ngày lễ hội, liên hoan, sinh nhật, đám cưới. Ngoài ra, tinh dầu hoa hồng còn dùng để làm dầu thơm rất được ưa chuộng. Riêng đối với em, hoa hồng đã tô điểm cho vườn kiểng nhà em thêm xinh tươi. Em rất quý hoa vì những bông hoa có được là do ba em trồng..' , '5'
*/
BEGIN
	SET NOCOUNT ON;

	INSERT INTO  [dbo].[CustFeedback] ([CustID],[Subaccid],[Comment],[Rate],[FuncID],[CreatedDate])
	SELECT    @custID, @Subaccid, ISNULL(@comment , ''), ISNULL (@Rate , 0), @FuncID, Getdate()

	IF @XMLfb IS NOT NULL
	BEGIN
		EXEC [Age_CustFeedbackArea_Ins] @XMLfb=@XMLfb
	END
END