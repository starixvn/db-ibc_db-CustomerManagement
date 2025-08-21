/*<info serverAlias="DBBOT-bodb_ChatBot" executers="wsv_alp"  viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Age_CustFeedbackIns] 
	-- Add the parameters for the stored procedure here
	  @custID		INT
	, @Subaccid		INT
	, @comment		NVARCHAR(4000)
	, @Rate			TINYINT 
	, @FuncID		INT				= NULL
	, @XMLfb		NVARCHAR(MAX)	= NULL
	, @StatusID 	INT				= NULL
	, @ExtraInfo	NVARCHAR(MAX)	= NULL
AS
/*
	Created: 20230210@Helios 
	Task : Insert Feedback by SMA in AlphaSite   
	DB: DBBOT.bodb_ChatBot   
 
	Revisions:  
	- 20230210@Helios: Insert Feedback by SMA in AlphaSite [Redmine: #183412] 
	- 20230328@Tacy: Alpha - Get user's feedback on specific function
	- 20250313@Virgil: CRM - Manage SMA Feedback in effective way [Redmine #196012]
	- 20250813@Dave: Alpha - Implement compact feedback [RedmineID: #234817]

	Parameter's Explanation:
		• @FuncId :	 = NULL ~ current feedback [#183412]
					<> NULL ~ feedback by control 1|2

		• @XMLfb : = NULL ~ current feedback [#183412] & feedback by control 2
				  <> NULL ~ feedback by control 1

	Example:
		EXEC Age_CustFeedbackIns 340942 , 1234 , N'Hoa hồng luôn có mặt trong các ngày lễ hội, liên hoan, sinh nhật, đám cưới...' , 5
*/
BEGIN
	SET NOCOUNT ON;

	INSERT INTO [dbo].[CustFeedback] ([CustID],[Subaccid],[Comment],[Rate],[FuncID],[CreatedDate], [ReviewStatusID], [ExtraInfo])
	SELECT    @custID, @Subaccid, ISNULL(@comment , ''), ISNULL (@Rate , 0), @FuncID, Getdate(), @StatusID, ISNULL(@ExtraInfo, '');

	IF @XMLfb IS NOT NULL
	BEGIN
		EXEC [Age_CustFeedbackArea_Ins] @XMLfb=@XMLfb
	END

END