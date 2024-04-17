/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="wsv_nap,wsv_lap,wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustAbnormalLoginIns]
	@NewBatch			VARCHAR(MAX) = ''
	, @ExitsTransIDs	VARCHAR(MAX) = ''		OUTPUT
	, @ErrCode			INT				= 0		OUTPUT
	, @ErrMsg			NVARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: Winfred
	Date: 20230425
	Task : Alpha - Notify abnormal login via Telegram chatbot
	DB: DBLOG/bodb_CustomerLog
	Original:

	Revisions:
		- 20230425@Winfred: Alpha - Notify abnormal login via Telegram chatbot [RedmineID: #183746] 

	Param's Explanation:

	Example: Acc_CustAbnormalLoginIns 
	@NewBatch= '<ROOT>
		<r TransID="1074519501" TransTime="2022-01-12 01:54:13.417" LoginName="NSUPER001"  UserAgent="AgentHK0101"  IP="10.0.0.116"  Browser="Chrome Mobile"   Device="Apple"  OS="iPhone"/>
		<r TransID="1074519502" TransTime="2022-01-12 01:54:13.419" LoginName="NSUPER001" UserAgent="AgenttHK0101"  IP="10.0.0.116"  Browser="Safari Mobile"   Device="Apple"  OS="iPhone"/>
		<r TransID="1074519503" TransTime="2022-01-12 01:54:13.421" LoginName="NSUPER001"  UserAgent="AgentHK0101"  IP="10.0.0.116"  Browser="Chrome Mobile"   Device="Xiaomi"  OS="Android 9" />
		<r TransID="1074519504" TransTime="2022-01-12 01:54:13.423" LoginName="NSUPER001"  UserAgent="AgentHK0101"  IP="10.0.0.116"  Browser="Brave Mobile"   Device="Xiaomi"  OS="Android 9" />
		<r TransID="1074519505" TransTime="2022-01-12 01:54:13.425" LoginName="NSUPER001"  UserAgent="AgentHK0101"  IP="10.0.0.116"  Browser="Chrome Mobile"   Device="Xiaomi"  OS="Android 12" />
		<r TransID="1074519506" TransTime="2022-01-12 01:54:13.427" LoginName="NSUPER001"  UserAgent="AgentHK0101"  IP="10.0.0.116"  Browser="Brave Mobile"   Device="Xiaomi"  OS="Android 12" />
		<r TransID="1074519507" TransTime="2022-01-12 01:54:13.429" LoginName="NSUPER001"  UserAgent="AgentHK0101"  IP="10.0.0.116"  Browser="Chrome Mobile"   Device="Xiaomi"  OS="Android 12" />
		<r TransID="1074519508" TransTime="2022-01-12 01:54:13.431" LoginName="NSUPER001"  UserAgent="AgentHK0101"  IP="10.0.0.116"  Browser="Brave Mobile"   Device="Xiaomi"  OS="Android 12" />
		<r TransID="1074519509" TransTime="2022-01-12 01:54:13.433" LoginName="NSUPER001"  UserAgent="AgentHK0101"  IP="10.0.0.116"  Browser="Chrome Mobile"   Device="Xiaomi"  OS="Android 12" />
		<r TransID="1074519510" TransTime="2022-01-12 01:54:13.435" LoginName="NSUPER001"  UserAgent="AgentHK0101"  IP="10.0.0.116"  Browser="Brave Mobile"   Device="Xiaomi"  OS="Android 12" />
		<r TransID="1074519511" TransTime="2022-01-12 01:54:13.437" LoginName="NSUPER001" UserAgent="AgentHK0101"  IP="10.0.0.116"  Browser="Chrome Mobile"   Device="Apple"  OS="iPhone" />
		<r TransID="1074519512" TransTime="2022-01-12 01:54:13.439" LoginName="NSUPER001" UserAgent="AgentHK0101"  IP="10.0.0.116"  Browser="Safari Mobile"   Device="Apple"  OS="iPhone" />
		<r TransID="1074519513" TransTime="2022-01-12 01:54:13.441" LoginName="NSUPER001"  UserAgent="AgentHK0101"  IP="10.0.0.116"  Browser="Chrome Mobile"   Device="Apple"  OS="iPhone" />
		<r TransID="1074519514" TransTime="2022-01-12 01:54:13.443" LoginName="NSUPER001"  UserAgent="AgentHK0101"  IP="10.0.0.116"  Browser="Safari Mobile"   Device="Apple"  OS="iPhone" />
		<r TransID="1074519515" TransTime="2022-01-12 01:54:13.445" LoginName="NSUPER001"  UserAgent="AgentHK0101"  IP="10.0.0.116"  Browser="Chrome Mobile"   Device="Xiaomi"  OS="Android 12"  />
		<r TransID="1074519516" TransTime="2022-01-12 01:54:13.447" LoginName="NSUPER001"  UserAgent="AgentHK0101"  IP="10.0.0.116"  Browser="Brave Mobile"   Device="Xiaomi"  OS="Android 12"  />
		<r TransID="1074519517" TransTime="2022-01-12 01:54:13.449" LoginName="NSUPER001"  UserAgent="AgentHK0101"  IP="10.0.0.116"  Browser="Chrome Mobile"   Device="Xiaomi"  OS="Android 12"  />
		<r TransID="1074519518" TransTime="2022-01-12 01:54:13.451" LoginName="NSUPER001"  UserAgent="AgentHK0101"  IP="10.0.0.116"  Browser="Brave Mobile"   Device="Xiaomi"  OS="Android 12"  />
		<r TransID="1074519519" TransTime="2022-01-12 01:54:13.453" LoginName="NSUPER001" UserAgent="AgentHK0101"  IP="10.0.0.116"  Browser="Chrome Mobile"   Device="Xiaomi"  OS="Android 12"  />
		</ROOT>'
*/ 
BEGIN
	SET NOCOUNT ON; 
	
	DECLARE @xml XML, @iDoc INT, @CreatedDate SMALLDATETIME, @ArchiveDate DATETIME

	CREATE TABLE #CustAbnormalLogin( LoginID BIGINT, LoginTime DATETIME, LoginName VARCHAR(50), CustID INT, 
					SubAccountID INT, UserAgent VARCHAR(1000), IP VARCHAR(40), OS VARCHAR(40), Browser VARCHAR(40), Device VARCHAR(40), 
					ChildLoginID BIGINT, isfinished BIT DEFAULT 0)
	CREATE TABLE #temp( LoginID BIGINT)

	SELECT @CreatedDate = GETDATE() , @ArchiveDate = DATEADD(DAY,-90,GETDATE())

	BEGIN TRY
		IF @NewBatch IS NOT NULL AND @NewBatch <> ''
		BEGIN
			--Parse XML
			EXECUTE	sp_xml_preparedocument @iDoc OUTPUT, @NewBatch

			INSERT INTO #CustAbnormalLogin (LoginID, LoginTime, LoginName, UserAgent, IP, OS, Browser, Device )
			SELECT	
				CAST(ox.TransID AS BIGINT) AS LoginID,
				CAST(ox.TransTime AS DATETIME) AS LoginTime, 
				ox.LoginName,
				ox.UserAgent,
				ox.IP,		
				ox.OS,		
				ox.Browser,
				ox.Device	
			FROM OPENXML (@iDoc, '/ROOT/r', 1) 
			WITH (
				TransID		VARCHAR(20)
			,	TransTime	VARCHAR(30)
			,	LoginName 	VARCHAR(50)	
			,	UserAgent	VARCHAR(1000)	
			,	IP			VARCHAR(15)	
			,	Browser		VARCHAR(40)	
			,	Device		VARCHAR(40)	
			,	OS			VARCHAR(40)	
			) AS ox;

			EXECUTE sp_xml_removedocument @iDoc;
		END
	END TRY

	BEGIN CATCH
		SET @ErrCode = 100
		SET @ErrMsg = N'Unable to process Notify abnormal login via Telegram chatbot to invalid parameters, please try again.'
		RETURN
	END CATCH;
	
	DELETE a
	OUTPUT DELETED.LoginID INTO #temp(LoginID)
	FROM #CustAbnormalLogin a
		INNER JOIN CustAbnormalLogin b WITH(NOLOCK) ON a.LoginID = b.LoginID

	SELECT @ExitsTransIDs =  STUFF((SELECT DISTINCT ',' + cast(LoginID AS VARCHAR(10))
									FROM #temp
									FOR XML PATH('')), 1, 1, '')

	SELECT @ExitsTransIDs =  CASE WHEN ISNULL(@ExitsTransIDs,'') = '' THEN '' ELSE @ExitsTransIDs END + ISNULL(
									STUFF((SELECT DISTINCT ',' + cast(LoginID AS VARCHAR(10))
									FROM #CustAbnormalLogin a
									CROSS APPLY (SELECT COUNT(1) AS dem
												FROM #CustAbnormalLogin 
												WHERE LoginID = a.LoginID
												) t
									WHERE t.dem >  1
									FOR XML PATH('')), 1, 0, ''),'')

	INSERT INTO CustAbnormalLogin(LoginID, LoginTime, LoginName, CustID, SubAccountID, UserAgent, IP, OS, Browser, Device, ChildLoginID, Status, CreatedDate)
	SELECT LoginID, LoginTime, LoginName, cc.CustID, 0 AS SubAccountID, UserAgent, IP, OS, Browser, Device, 0 AS ChildLoginID, 0 AS Status, @CreatedDate AS CreatedDate
	FROM #CustAbnormalLogin c
		INNER JOIN bodb02.dbo.Customer cc WITH(NOLOCK) ON c.LoginName = cc.username2
	UNION 
	SELECT LoginID, LoginTime, LoginName, cc.CustID, cc.subaccid , UserAgent, IP, OS, Browser, Device, 0 AS ChildLoginID, 0 AS Status, @CreatedDate AS CreatedDate
	FROM #CustAbnormalLogin c
		INNER JOIN bodb02.dbo.custsub cc WITH(NOLOCK) ON c.LoginName = cc.username2

	IF  @@ERROR <> 0
	BEGIN
		DELETE c FROM dbo.CustAbnormalLogin c WITH(ROWLOCK)
				INNER JOIN #CustAbnormalLogin cl ON c.LoginID = cl.LoginID
		SELECT @ErrMsg = 'Insert failed. Please try again.',@ErrCode = @@ERROR
	END

	DELETE FROM CustAbnormalLogin WITH(ROWLOCK) WHERE LoginTime < @ArchiveDate
	DROP TABLE #CustAbnormalLogin
	DROP TABLE #temp
END
GO
