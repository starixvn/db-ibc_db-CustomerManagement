/*<info serverAlias="DBACC-bodb02" executers="wsv_nap,wsv_alp,wsv_xnap,wsv_lap" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_CustAbnormalLogin_PrepareIns]
	@OrgBatch	VARCHAR(MAX)	= ''
	, @NewBatch	VARCHAR(MAX)	= ''	OUTPUT
	, @ErrCode	INT				= 0		OUTPUT
	, @ErrMsg	NVARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: Dave
	Date: 20250612
	Task : Performance: Modify Acc_CustAbnormalLoginIns to use appropriate indexes
	DB: DBACC/bodb02
	Original:

	Revisions:
		- 20250612@Dave: Performance: Modify Acc_CustAbnormalLoginIns to use appropriate indexes [RedmineID: #230302] 

	Param's Explanation:

	Example: Acc_CustAbnormalLogin_PrepareIns 

		@OrgBatch= '<ROOT>
			<r TransID="1074519501" TransTime="2022-01-12 01:54:13.417" LoginName="NSUPER001" UserAgent="AgentHK0101" IP="10.0.0.116" Browser="Chrome Mobile" Device="Apple" OS="iPhone"/>
			<r TransID="1074519502" TransTime="2022-01-12 01:54:13.419" LoginName="NSUPER001" UserAgent="AgenttHK0101" IP="10.0.0.116" Browser="Safari Mobile" Device="Apple" OS="iPhone"/>
			<r TransID="1074519503" TransTime="2022-01-12 01:54:13.421" LoginName="NSUPER001" UserAgent="AgentHK0101" IP="10.0.0.116" Browser="Chrome Mobile" Device="Xiaomi" OS="Android 9" />
			<r TransID="1074519504" TransTime="2022-01-12 01:54:13.423" LoginName="NSUPER001" UserAgent="AgentHK0101" IP="10.0.0.116" Browser="Brave Mobile" Device="Xiaomi" OS="Android 9" />
			<r TransID="1074519505" TransTime="2022-01-12 01:54:13.425" LoginName="NSUPER001" UserAgent="AgentHK0101" IP="10.0.0.116" Browser="Chrome Mobile" Device="Xiaomi" OS="Android 12" />
			<r TransID="1074519506" TransTime="2022-01-12 01:54:13.427" LoginName="NSUPER001" UserAgent="AgentHK0101" IP="10.0.0.116" Browser="Brave Mobile" Device="Xiaomi" OS="Android 12" />
			<r TransID="1074519507" TransTime="2022-01-12 01:54:13.429" LoginName="NSUPER001" UserAgent="AgentHK0101" IP="10.0.0.116" Browser="Chrome Mobile" Device="Xiaomi" OS="Android 12" />
			<r TransID="1074519508" TransTime="2022-01-12 01:54:13.431" LoginName="NSUPER001" UserAgent="AgentHK0101" IP="10.0.0.116" Browser="Brave Mobile" Device="Xiaomi" OS="Android 12" />
			<r TransID="1074519509" TransTime="2022-01-12 01:54:13.433" LoginName="NSUPER001" UserAgent="AgentHK0101" IP="10.0.0.116" Browser="Chrome Mobile" Device="Xiaomi" OS="Android 12" />
			<r TransID="1074519510" TransTime="2022-01-12 01:54:13.435" LoginName="NSUPER001" UserAgent="AgentHK0101" IP="10.0.0.116" Browser="Brave Mobile" Device="Xiaomi" OS="Android 12" />
			<r TransID="1074519511" TransTime="2022-01-12 01:54:13.437" LoginName="NSUPER001" UserAgent="AgentHK0101" IP="10.0.0.116" Browser="Chrome Mobile" Device="Apple" OS="iPhone" />
			<r TransID="1074519512" TransTime="2022-01-12 01:54:13.439" LoginName="NSUPER001" UserAgent="AgentHK0101" IP="10.0.0.116" Browser="Safari Mobile" Device="Apple" OS="iPhone" />
			<r TransID="1074519513" TransTime="2022-01-12 01:54:13.441" LoginName="NSUPER001" UserAgent="AgentHK0101" IP="10.0.0.116" Browser="Chrome Mobile" Device="Apple" OS="iPhone" />
			<r TransID="1074519514" TransTime="2022-01-12 01:54:13.443" LoginName="NSUPER001" UserAgent="AgentHK0101" IP="10.0.0.116" Browser="Safari Mobile" Device="Apple" OS="iPhone" />
			<r TransID="1074519515" TransTime="2022-01-12 01:54:13.445" LoginName="NSUPER001" UserAgent="AgentHK0101" IP="10.0.0.116" Browser="Chrome Mobile" Device="Xiaomi" OS="Android 12" />
			<r TransID="1074519516" TransTime="2022-01-12 01:54:13.447" LoginName="NSUPER001" UserAgent="AgentHK0101" IP="10.0.0.116" Browser="Brave Mobile" Device="Xiaomi" OS="Android 12" />
			<r TransID="1074519517" TransTime="2022-01-12 01:54:13.449" LoginName="NSUPER001" UserAgent="AgentHK0101" IP="10.0.0.116" Browser="Chrome Mobile" Device="Xiaomi" OS="Android 12" />
			<r TransID="1074519518" TransTime="2022-01-12 01:54:13.451" LoginName="NSUPER001" UserAgent="AgentHK0101" IP="10.0.0.116" Browser="Brave Mobile" Device="Xiaomi" OS="Android 12" />
			<r TransID="1074519519" TransTime="2022-01-12 01:54:13.453" LoginName="NSUPER001" UserAgent="AgentHK0101" IP="10.0.0.116" Browser="Chrome Mobile" Device="Xiaomi" OS="Android 12" />
		</ROOT>'

		@NewBatch = '<ROOT>
            <r TransID="1074519501" TransTime="2022-01-12 01:54:13.417" LoginName="test_206_102" UserAgent="AgentHK0101" CustID="8" SubAccountID="0" IP="10.0.0.116" Browser="Chrome Mobile" Device="Apple" OS="iPhone"/>
            <r TransID="1074519502" TransTime="2022-01-12 01:54:13.419" LoginName="testsub07" UserAgent="AgentHK0101" CustID="1176070" SubAccountID="291431" IP="10.0.0.116" Browser="Safari Mobile" Device="Apple" OS="iPhone"/>
        </ROOT>'

*/ 
BEGIN

	SET NOCOUNT ON; 

	DECLARE	@iDoc INT;
	CREATE TABLE #tmpOutData(
		TransID			VARCHAR(20)
		,TransTime		VARCHAR(30)
		,LoginName 		VARCHAR(50)
		,UserAgent		VARCHAR(1000)
		,CustID			INT	DEFAULT 0
		,SubAccountID	INT	DEFAULT 0
		,IP				VARCHAR(15)
		,Browser		VARCHAR(40)
		,Device			VARCHAR(40)
		,OS				VARCHAR(40)	
	);

	BEGIN TRY
		IF @OrgBatch IS NOT NULL AND @OrgBatch <> ''
		BEGIN
			--Parse XML
			EXECUTE	sp_xml_preparedocument @iDoc OUTPUT, @OrgBatch;

			SELECT @iDoc, @OrgBatch;

			INSERT INTO #tmpOutData (TransID, TransTime, LoginName, UserAgent, IP, OS, Browser, Device )
			SELECT	
				ox.TransID,
				ox.TransTime, 
				ox.LoginName,
				ox.UserAgent,
				ox.IP,		
				ox.OS,		
				ox.Browser,
				ox.Device	
			FROM OPENXML (@iDoc, '/ROOT/r', 1) 
			WITH (
				TransID		VARCHAR(20)
				,TransTime	VARCHAR(30)
				,LoginName 	VARCHAR(50)	
				,UserAgent	VARCHAR(1000)	
				,IP			VARCHAR(15)	
				,Browser	VARCHAR(40)	
				,Device		VARCHAR(40)	
				,OS			VARCHAR(40)	
			) AS ox;

			EXECUTE sp_xml_removedocument @iDoc;
		END
	END TRY
	BEGIN CATCH
		SET @ErrCode = 100;
		SET @ErrMsg = N'Unable to process Notify abnormal login via Telegram chatbot to invalid parameters, please try again.';
		RETURN;
	END CATCH;

	UPDATE tmp
	SET tmp.CustID = cus.custid
	FROM #tmpOutData AS tmp
		INNER JOIN dbo.Customer AS cus WITH (NOLOCK)
			ON tmp.LoginName = cus.username2;

	UPDATE tmp
	SET	tmp.CustID = cus.custid,
		tmp.SubAccountID = cus.subaccid
	FROM #tmpOutData AS tmp
		INNER JOIN dbo.custSub AS cus WITH (NOLOCK)
			ON tmp.LoginName = cus.username2;
			
	DELETE #tmpOutData WHERE CustID = 0;
	
	SELECT @NewBatch = CAST((
		SELECT 
			TransID, TransTime, LoginName, UserAgent, CustID, SubAccountID, IP, Browser, Device, OS
		FROM #tmpOutData AS r
		FOR XML AUTO, ROOT('ROOT')
	) AS NVARCHAR(MAX));
    

	DROP TABLE #tmpOutData;

END;