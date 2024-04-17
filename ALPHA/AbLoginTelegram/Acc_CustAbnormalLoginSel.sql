/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet,wsv_nap,bodbDownlineNet,wsv_alp,bodbExtAccNet,wsv_xnap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustAbnormalLoginSel]
	@OldMaxLogID BIGINT,
	@MaxLogID BIGINT OUTPUT
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

	Example: Acc_CustAbnormalLoginSel 
*/ 
BEGIN
	SET NOCOUNT ON; 
	DECLARE @FromDate SMALLDATETIME
	SELECT @FromDate = DATEADD(MINUTE, -10, GETDATE())

	-- Update status over ten minute ( for data CTS)
	UPDATE CustAbnormalLogin WITH(ROWLOCK) SET Status = 3 WHERE LoginTime < @FromDate AND LoginID < @OldMaxLogID AND Status = 0
		
	CREATE TABLE #CustAbnormalLogin( LoginID BIGINT, LoginTime	DATETIME, CustID INT, SubAccountID INT, username VARCHAR(30), TimeTemp SMALLDATETIME , STT INT)    
	CREATE CLUSTERED INDEX Ix_AbnormalLogin ON #CustAbnormalLogin (CustID, SubAccountID, TimeTemp, STT)  
	
	CREATE NONCLUSTERED INDEX px_AbnormalLogin_STT ON #CustAbnormalLogin (STT,LoginID)  INCLUDE (CustID,SubAccountID, TimeTemp)

	INSERT INTO #CustAbnormalLogin(LoginID, LoginTime, CustID,SubAccountID, TimeTemp, STT)
	SELECT LoginID, LoginTime, CustID,SubAccountID, CAST(CONVERT(varchar, LoginTime, 100) AS SMALLDATETIME) zTime, 
		 ROW_NUMBER() OVER ( PARTITION BY custid, SubAccountID, CAST(CONVERT(VARCHAR, LoginTime, 100) AS SMALLDATETIME) ORDER BY custid, SubAccountID, LoginTime )  AS STT 
	FROM CustAbnormalLogin WITH(NOLOCK)
	WHERE LoginTime > @FromDate AND LoginID >= @OldMaxLogID AND Status = 0
	ORDER BY CustID, zTime, STT
	
	-- Update status Do not Notify 
	UPDATE c
	SET c.Status = CASE WHEN clChild.STT = 1 THEN 2 ELSE 1 END , c.ChildLoginID = CASE WHEN clChild.STT > 1 THEN clMain.LoginID END
	FROM CustAbnormalLogin c WITH(ROWLOCK) 
		INNER JOIN #CustAbnormalLogin clChild  ON c.LoginID = clChild.LoginID 
		INNER JOIN #CustAbnormalLogin clMain ON clChild.CustID = clMain.CustID  AND clChild.SubAccountID = clMain.SubAccountID 
			AND clChild.TimeTemp = clMain.TimeTemp AND clMain.STT = 1
	
	UPDATE a
	SET a.username = cc.username
	FROM #CustAbnormalLogin a
		INNER JOIN bodb02.dbo.Customer cc WITH(NOLOCK) ON a.CustID = cc.CustID
	WHERE a.STT= 1 AND SubAccountID = 0

	UPDATE a
	SET a.username = cc.username
	FROM #CustAbnormalLogin a
		INNER JOIN bodb02.dbo.custsub cc WITH(NOLOCK) ON a.SubAccountID = cc.subaccid
	WHERE a.STT= 1 AND SubAccountID <> 0

	SELECT @MaxLogID = MAX(LoginID) FROM #CustAbnormalLogin 
	IF ISNULL(@MaxLogID,0) = 0 SET @MaxLogID = @OldMaxLogID

	SELECT c.LoginID, c.LoginTime, c.LoginName, c.CustID, c.SubAccountID, c.UserAgent, c.IP, c.OS, c.Browser, c.Device, c.Status, kq.CountLogin , cam.username
	FROM CustAbnormalLogin c WITH(NOLOCK)
		INNER JOIN #CustAbnormalLogin cam ON c.LoginID = cam.LoginID AND cam.STT = 1
		CROSS APPLY (SELECT COUNT(STT) AS CountLogin FROM  #CustAbnormalLogin WHERE CustID = cam.CustID AND SubAccountID = cam.SubAccountID AND TimeTemp = cam.TimeTemp ) kq
	WHERE c.status = 2
	ORDER BY c.CustID, c.SubAccountID , c.LoginTime

	DROP TABLE #CustAbnormalLogin
END
GO