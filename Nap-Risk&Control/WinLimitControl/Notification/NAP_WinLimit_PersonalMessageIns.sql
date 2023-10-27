/*<info serverAlias="DBCUST-CustDB" executers="" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[NAP_WinLimit_PersonalMessageIns]
	@Message	NVARCHAR(MAX)
AS
/*
	Created: 20230911@Tacy
    Task: CWL job - Sending Personal Message to Agent in Alpha site
    DB: DBCUST-CustDB

	Revisions:
		- 20230911@Tacy: Create SP [RedmineID: #184911]

	Param's Explanation:
		- @MsgContentsType: to identify normal message or changed settings message
				= 0 ~ Normal Data
				= 100 ~ msg from CRM site
				= 109 ~ msg from CWL
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE	  @StartRun		DATETIME
			, @EndRun		DATETIME
			, @Duration		INT
			, @logSpData	NVARCHAR(MAX)
			, @MessageId	INT
			, @recommend	INT
			, @rUsername	VARCHAR(30)
			, @Content_en	NVARCHAR(4000)
			, @Content_cs	NVARCHAR(4000)
			, @Content_ch	NVARCHAR(4000)
			, @Content_th	NVARCHAR(4000)
			, @Content_vn	NVARCHAR(4000)
			
	DECLARE @tbCustinfo TABLE (
			  Username		VARCHAR(30)
			, recommend		INT
			, rUsername		VARCHAR(30)
			, TotalWinAmt	MONEY
			, ProductID		TINYINT
		)

	DECLARE @xml XML = NULL

	SET @StartRun=GETDATE()

	SELECT @xml = CAST(@Message AS xml)

	--Parse XML	
	DECLARE @iDoc INT

	EXEC sp_xml_preparedocument @iDoc OUTPUT
		, @xml

	INSERT INTO @tbCustinfo (Username, recommend, rUsername, TotalWinAmt, ProductID)
	SELECT Username, recommend, rUsername, TotalWinAmt, ProductID
	FROM OPENXML(@iDoc, '/Root/Msg', 1) WITH (
			  Username		VARCHAR(30)
			, TotalWinAmt	MONEY
			, ProductID		TINYINT
			, recommend		INT
			, rUsername		VARCHAR(30)
		)
	
	EXEC sp_xml_removedocument @iDoc

	--set msg content
	SELECT @Content_en = N'Dear valued customer, please be informed that the Member '''
					+ ci.Username + N''' under your line had won ' + REPLACE(CONVERT(VARCHAR, CAST(ci.TotalWinAmt AS money), 1),'.00','') + N' on the '
					+ p.ProductName 
					+ N' product. This member''s account has been suspended. Kindly check and take timely action accordingly. Thank you!'
	
	  , @Content_cs = N'尊敬的代理们，请注意，在您底下的会员''' + ci.Username 
					+ N'''已经在' + ISNULL(p.ProductNameCs, p.ProductName)
					+ N'产品赢得金额' + REPLACE(CONVERT(VARCHAR, CAST(ci.TotalWinAmt AS money), 1),'.00','') 
					+ N'。该会员账号已被设为暂停使用。请确认并及时采取对应措施，谢谢！'

	  , @Content_ch = N'尊敬的代理們，請注意，在您底下的會員''' + ci.Username 
					+ N'''已經在' + ISNULL(p.ProductNameCs, p.ProductName)
					+ N'產品贏得金額' + REPLACE(CONVERT(VARCHAR, CAST(ci.TotalWinAmt AS money), 1),'.00','') 
					+ N'。該會員帳號已被設為暫停使用。請確認並及時採取對應措施，謝謝！'
		
	  , @Content_th = N'เรียน เอเย่นต์ ขอแจ้งให้ทราบว่า '
					+ ci.Username + N' ซึ่งเป็นสมาชิกของคุณ มียอดชนะเดิมพัน ' + REPLACE(CONVERT(VARCHAR, CAST(ci.TotalWinAmt AS money), 1),'.00','') + N' จากผลิตภัณฑ์ '
					+ ISNULL(p.ProductNameTh, p.ProductName)
					+ N' ขณะนี้บัญชีของสมาชิกรายนี้ได้ถูกระงับไว้ กรุณาตรวจสอบและดำเนินการตามที่ท่านเห็นสมควร ขอขอบคุณ'
		
	  , @Content_vn = N'Kính gửi Quý khách hàng, chúng tôi xin thông báo rằng Member '''
					+ ci.Username + N''' thuộc cấp dưới của bạn đã thắng ' + REPLACE(CONVERT(VARCHAR, CAST(ci.TotalWinAmt AS money), 1),'.00','') + N' cho sản phẩm '
					+ ISNULL(p.ProductNameVN, p.ProductName)
					+ N'. Tài khoản Member này đã bị tạm đình chỉ. Vui lòng kiểm tra và thực hiện hành động tương ứng kịp thời. Trân trọng!'
		
		, @recommend=recommend
		, @rUsername=rUsername
	FROM @tbCustinfo ci 
	INNER JOIN DBACC.bodb02.dbo.Products p WITH (NOLOCK) ON p.ProductID=ci.ProductID
	
	--Insert Msg
	EXEC DBMSG.bodb_Message.dbo.Age_Msg_SetMessage 
		@Content_en=@Content_en,
		@Content_ch=@Content_ch,
		@Content_cs=@Content_cs,
		@Content_jp=@Content_en,
		@Content_it=N'',
		@Content_th=@Content_th,
		@Content_ko=@Content_en,
		@Content_es=N'',
		@Content_vn=@Content_vn,
		@CreatorName='starixIT',
		@MsgType=1,
		@IsBatch=0,
		@MsgContentsType=109,
		@MessageIDOutput=@MessageId OUTPUT

	--Insert MsgTarget
	exec DBMSG.bodb_Message.dbo.Age_Msg_SetUsrMessage @MessageId=@MessageId,@TargetId=@recommend,@TargetName=@rUsername

END
GO
