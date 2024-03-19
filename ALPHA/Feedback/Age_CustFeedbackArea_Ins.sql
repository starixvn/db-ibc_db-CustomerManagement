/*<info serverAlias="DBBOT-bodb_ChatBot" executers="bodbDownlineNet,wsv_alp"  viewers="" isFunction="0" isNested="1"></info>*/
 ALTER PROCEDURE [dbo].[Age_CustFeedbackArea_Ins]
	-- Add the parameters for the stored procedure here
	   @XMLfb	NVARCHAR(MAX) 
AS
/*
	Task : Alpha - Get user's feedback on specific function
	DB: DBBOT/bodb_ChatBot
	Original:
	
	Revisions:
		- 20230328@Tacy: Create SP [Redmine: #185515]

	Param's Explanation: 
		• @XMLfb =	<Root>
						<Feedback CustID="1" SubAccID="0" FuncID="1" AreaID="1" Rate="4"/>
						<Feedback CustID="1" SubAccID="0" FuncID="1" AreaID="2" Rate="3"/>
						<Feedback CustID="1" SubAccID="0" FuncID="1" AreaID="3" Rate="2"/>
						<Feedback CustID="1" SubAccID="0" FuncID="1" AreaID="4" Rate="0"/>
					</Root>
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @xml XML

	CREATE TABLE #Feedback (
		  CustID	INT
		, Subaccid	INT
		, FuncID	INT
		, AreaID	INT
		, Rate		TINYINT
	)

	--Parse XML data
	DECLARE @iDoc INT

	SET @xml = CONVERT(XML, @XMLfb)

	EXEC sp_xml_preparedocument @iDoc OUTPUT, @xml

	INSERT INTO #Feedback (CustID, Subaccid, FuncID, AreaID, Rate)
	SELECT CustID, Subaccid, FuncID, AreaID, Rate
	FROM OPENXML(@iDoc, '/Root/Feedback', 1) WITH (
			CustID	INT
		, SubAccID	INT
		, FuncID	INT
		, AreaID	INT
		, Rate		TINYINT
	)

	INSERT INTO CustFeedbackArea (CustID, Subaccid, FuncID, AreaID, Rate)
	SELECT CustID, Subaccid, FuncID, AreaID, Rate
	FROM #Feedback

	DROP TABLE #Feedback
END
GO
