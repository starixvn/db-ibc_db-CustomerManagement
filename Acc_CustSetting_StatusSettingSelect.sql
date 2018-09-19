/*<info serverAlias="DBCUST-CUSTDB,DBAGE-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustSetting_StatusSettingSelect]   
   @CustID  INT  
 , @ProductID TINYINT = NULL  
 , @RoleID INT = NULL  
 , @SettingType TINYINT = NULL
AS  
/*  
 Created: 20151012@Helen  
 Task : setting values of a product  
 DB: DBCUST/CustDB, DBAGE/bodb02  
 Original:  
  
 Revisions:  
  - 20160114@Helen: Cricket - [Redmine: #50027]  
  - 20160330@Elodie: Get more IsSyncedUpline, IsSyncedDownline infomation [Redmine: #49606]  
  - 20160413@Billy: Remove Site Currency check - [Redmine: #54672]  
  - 20160429@Winnie: Return column IsHiddenUpline for AllBet, VoidBridge  
  - 20160801@Elodie: Get Game status (setting type = 11) - [Redmine: #60809]   
  - 20170307@Elodie: Get New product status (setting type = 13) - [Redmine: #70722]   
  - 20170421@Helen: Enable Downline FishingWorld checkbox is ticked & disabled control although Member is disabled [RedmineID: #74421]
  - 20170803@Winnie: Change Data Type of Sporttype [RedmineID: #73545]
  - 20170919@Johnson: fix the unsynchronized setting, remove IsDownlineSynced 
					and fix hasDownline status to show checkbox enable downline [Redmine: #72973]
						+hasDownline = 1: has at least one customer has sync status
									=0 : all downlines not sync	
 Param's Explanation:  
 - @CustID: 
 Example: EXEC Acc_CustSetting_StatusSettingSelect @CustID = 1176070, @ProductID = 24, @RoleID = 4, @SettingType = 13
   
 */  
BEGIN  
   
	DECLARE @IsDisabledDownline BIT, @downlines BIT  = 0   
	DECLARE @SuperID INT, @MasterID INT, @AgentID INT , @IsIMBC BIT = 0   
   
	SELECT @SuperID=ci.srecommend, @MasterID=ci.mrecommend , @AgentID = ci.recommend    
	FROM dbo.custInfo ci WITH(NOLOCK)    
	WHERE ci.custid=@CustID   
   
	IF EXISTS (SELECT 1 FROM Customer WITH (NOLOCK) WHERE custid = @SuperID AND [Site] = 'IMBC')  
		SET @IsIMBC = 1  
    
	CREATE TABLE #SportBettypeFilter (ProductID TINYINT, SportType SMALLINT,Bettype SMALLINT,IsLive BIT, SettingType TINYINT)

	INSERT INTO #SportBettypeFilter (ProductID,SportType,Bettype,IsLive, SettingType)
	SELECT ProductID,SportType,Bettype,IsLive, SettingType   
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@ProductID,4)
	WHERE @SettingType IS NULL OR @SettingType = 4

	INSERT INTO #SportBettypeFilter (ProductID,SportType,Bettype,IsLive, SettingType)
	SELECT ProductID,SportType,Bettype,IsLive, SettingType   
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@ProductID,11)
	WHERE @SettingType IS NULL OR @SettingType = 11

	INSERT INTO #SportBettypeFilter (ProductID,SportType,Bettype,IsLive, SettingType)
	SELECT ProductID,SportType,Bettype,IsLive, SettingType   
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@ProductID,13)
	WHERE @SettingType IS NULL OR @SettingType = 13	

	--DELETE sbf  
	--FROM  #SportBettypeFilter sbf  
	--INNER JOIN dbo.f_CustSetting_SportBetTypeHiddenBySiteCurrency(@CustID, @ProductID) AS sbhsc  
	--  ON sbhsc.ProductID = sbf.ProductID  
	--WHERE sbhsc.IsHidden = 1  
   
	IF @RoleID = 4  
	BEGIN  
		IF EXISTS (SELECT 1 FROM custinfo WITH (NOLOCK) WHERE srecommend = @CustID AND roleid = 3)  
			SET @downlines = 1     
     
		SELECT pdt.ProductID, pdt.SportType, pdt.BetType,  
			CASE WHEN stt.CustID IS NULL THEN 0 ELSE (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapHasSynced, PSP.bitmapOrder)) END as IsSync,
			CAST(CASE WHEN stt.CustID IS NULL  OR (@IsIMBC = 0 AND pdt.ProductID = 20) THEN 1 ELSE   
					(CASE WHEN (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsHidden, PSP.bitmapOrder)) = 0 THEN 0 ELSE 1 END) END AS BIT) AS isHidden,    
			1 AS isHiddenUpline,  
			CASE WHEN stt.CustID IS NULL THEN 1 ELSE (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsDisabled, PSP.bitmapOrder)) END as isDisabled, 
			CASE WHEN @downlines = 0 THEN (SELECT ISNULL(value,0) FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsDisabled, PSP.bitmapOrder))  
				ELSE ISNULL((	SELECT TOP 1 1  
								FROM dbo.custInfo ci WITH (NOLOCK)  
								INNER JOIN dbo.CustProductStatus cps_temp ON ci.custid = cps_temp.CustID  
								WHERE srecommend = @CustID 									
									AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps_temp.bitmapIsDisabled, PSP.bitmapOrder)) = 1  
									AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps_temp.bitmapHasSynced, PSP.bitmapOrder)) = 1  
								), 0) END AS IsDisabledDownline,
											 
			0 AS isDisabledUpline, 
			1 AS isSyncedUpline,
			CAST(CASE WHEN @downlines = 0 THEN 0
						ELSE ISNULL((	
								SELECT TOP 1 1  
								FROM dbo.custInfo ci WITH (NOLOCK)  
								INNER JOIN dbo.CustProductStatus cps_temp ON ci.custid = cps_temp.CustID  
								WHERE srecommend = @CustID  
									AND ci.custid <> @custid
									AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps_temp.bitmapHasSynced, PSP.bitmapOrder)) = 1
								), 0) END AS BIT)  HasDownline  
		FROM DBCUST.CUSTDB.dbo.ProductSettingDetail pdt WITH (NOLOCK)  
			INNER JOIN #SportBettypeFilter ft ON pdt.SportType = ft.sporttype AND pdt.BetType = ft.bettype AND pdt.IsLive = ft.islive AND pdt.SettingType = ft.SettingType
			INNER JOIN dbo.ProductStatusProfile psp WITH (NOLOCK) ON PSP.Bettype = pdt.BetType AND PSP.Sporttype = PDT.SportType                 
			LEFT JOIN dbo.CustProductStatus stt WITH (NOLOCK) ON stt.CustID = @CustID  
		WHERE pdt.SettingType IN (4,11,13) AND (@SettingType IS NULL OR ft.SettingType = @SettingType)
    
	END  
	ELSE IF @RoleID = 3  
	BEGIN  
		IF EXISTS (SELECT 1 FROM custinfo WITH (NOLOCK) WHERE mrecommend = @CustID AND roleid = 2)  
			SET @downlines = 1   
     
		SELECT pdt.ProductID, pdt.SportType, pdt.BetType,  
			CASE WHEN stt.CustID IS NULL THEN 0 ELSE (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapHasSynced, PSP.bitmapOrder)) END as IsSync,  
			CAST(CASE WHEN stt.CustID IS NULL OR (@IsIMBC = 0 AND pdt.ProductID = 20) THEN 1 
					ELSE (CASE WHEN (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsHidden, PSP.bitmapOrder)) = 0 THEN 0 ELSE 1 END) END AS BIT) AS isHidden,   
			CAST(CASE WHEN (SELECT ISNULL(value,1) FROM dbo.f_CustSetting_ProductStatusSel(stt_UPLINE.bitmapIsHidden, PSP.bitmapOrder))=0 THEN 0 ELSE 1 END AS BIT) AS isHiddenUpline, 
			CASE WHEN stt.CustID IS NULL THEN 1 ELSE (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsDisabled, PSP.bitmapOrder)) END as isDisabled,  
			CASE WHEN @downlines = 0 THEN (SELECT ISNULL(value,0) FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsDisabled, PSP.bitmapOrder))  
				ELSE ISNULL((	SELECT TOP 1 1  
								FROM dbo.custInfo ci WITH (NOLOCK)  
								INNER JOIN dbo.CustProductStatus cps_temp ON ci.custid = cps_temp.CustID  
								WHERE mrecommend = @CustID   
									AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps_temp.bitmapIsDisabled, PSP.bitmapOrder)) = 1  
									AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps_temp.bitmapHasSynced, PSP.bitmapOrder)) = 1  
								), 0) END AS IsDisabledDownline,  
			  
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt_UPLINE.bitmapIsDisabled, PSP.bitmapOrder)) as IsDisabledUpline,  
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt_UPLINE.bitmapHasSynced, PSP.bitmapOrder)) as IsSyncedUpline,  
			CAST(CASE WHEN @downlines = 0 THEN 0
						ELSE ISNULL((	
								SELECT TOP 1 1  
								FROM dbo.custInfo ci WITH (NOLOCK)  
								INNER JOIN dbo.CustProductStatus cps_temp ON ci.custid = cps_temp.CustID  
								WHERE mrecommend = @CustID  
									AND ci.custid <> @custid
									AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps_temp.bitmapHasSynced, PSP.bitmapOrder)) = 1
								), 0) END AS BIT)  HasDownline  
		FROM DBCUST.CUSTDB.dbo.ProductSettingDetail pdt WITH (NOLOCK)  
			INNER JOIN #SportBettypeFilter ft ON pdt.SportType = ft.sporttype AND pdt.BetType = ft.bettype AND pdt.IsLive = ft.islive AND pdt.SettingType = ft.SettingType
			INNER JOIN dbo.ProductStatusProfile psp WITH (NOLOCK) ON PSP.Bettype = pdt.BetType AND PSP.Sporttype = PDT.SportType                 
			LEFT JOIN dbo.CustProductStatus stt WITH (NOLOCK) ON stt.CustID = @CustID  
			LEFT JOIN  dbo.CustProductStatus stt_UPLINE WITH (NOLOCK) ON stt_UPLINE.CustID = @SuperID  
		WHERE pdt.SettingType IN (4,11,13) AND (@SettingType IS NULL OR ft.SettingType = @SettingType)
	END     
	ELSE IF @RoleID = 2  
	BEGIN  
		IF EXISTS ( SELECT 1 FROM custinfo WITH (NOLOCK) WHERE recommend = @CustID AND roleid = 1)  
			SET @downlines = 1   
     
		SELECT pdt.ProductID, pdt.SportType, pdt.BetType,  
			CASE WHEN stt.CustID IS NULL THEN 0 ELSE (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapHasSynced, PSP.bitmapOrder)) END as IsSync, 
			CAST(CASE WHEN stt.CustID IS NULL OR (@IsIMBC = 0 AND pdt.ProductID = 20) THEN 1 
						ELSE (CASE WHEN (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsHidden, PSP.bitmapOrder)) = 0 THEN 0 ELSE 1 END) END AS BIT) AS isHidden,    
			CAST(CASE WHEN (SELECT ISNULL(value,1) FROM dbo.f_CustSetting_ProductStatusSel(stt_UPLINE.bitmapIsHidden, PSP.bitmapOrder))=0 THEN 0 ELSE 1 END AS BIT) AS isHiddenUpline,  
			CASE WHEN stt.CustID IS NULL THEN 1 ELSE (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsDisabled, PSP.bitmapOrder)) END AS isDisabled, 
			CASE WHEN @downlines = 0 THEN (SELECT ISNULL(value,0) FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsDisabled, PSP.bitmapOrder))  
				ELSE ISNULL((	SELECT TOP 1 1  
								FROM dbo.custInfo ci WITH (NOLOCK)  
									INNER JOIN dbo.CustProductStatus cps_temp ON ci.custid = cps_temp.CustID  
								WHERE recommend = @CustID  
									AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps_temp.bitmapIsDisabled, PSP.bitmapOrder)) = 1  
									AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps_temp.bitmapHasSynced, PSP.bitmapOrder)) = 1  
								), 0) END AS IsDisabledDownline, 			
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt_UPLINE.bitmapIsDisabled, PSP.bitmapOrder)) AS IsDisabledUpline,  
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt_UPLINE.bitmapHasSynced, PSP.bitmapOrder)) AS IsSyncedUpline,  
			CAST(CASE WHEN @downlines = 0 THEN 0
						ELSE ISNULL((	
								SELECT TOP 1 1  
								FROM dbo.custInfo ci WITH (NOLOCK)  
								INNER JOIN dbo.CustProductStatus cps_temp ON ci.custid = cps_temp.CustID  
								WHERE recommend = @CustID  
									AND ci.custid <> @custid
									AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps_temp.bitmapHasSynced, PSP.bitmapOrder)) = 1
								), 0) END AS BIT)  HasDownline  
		FROM DBCUST.CUSTDB.dbo.ProductSettingDetail pdt WITH (NOLOCK)  
			INNER JOIN #SportBettypeFilter ft ON pdt.SportType = ft.sporttype AND pdt.BetType = ft.bettype AND pdt.IsLive = ft.islive AND pdt.SettingType = ft.SettingType
			INNER JOIN ProductStatusProfile psp WITH (NOLOCK) ON PSP.Bettype = pdt.BetType AND PSP.Sporttype = PDT.SportType                 
			LEFT JOIN dbo.CustProductStatus stt WITH (NOLOCK) ON stt.CustID = @CustID  
			LEFT JOIN  dbo.CustProductStatus stt_UPLINE WITH (NOLOCK) ON stt_UPLINE.CustID = @MasterID  
		WHERE pdt.SettingType IN (4,11,13) AND (@SettingType IS NULL OR ft.SettingType = @SettingType)
	END   
	ELSE IF @RoleID = 1  
	BEGIN  
		SELECT pdt.ProductID, pdt.SportType, pdt.BetType,  
			CASE WHEN stt.CustID IS NULL THEN 0 ELSE (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapHasSynced, PSP.bitmapOrder)) END as IsSync,  
			CAST(CASE WHEN stt.CustID IS NULL OR (@IsIMBC = 0 AND pdt.ProductID = 20) THEN 1 
					ELSE (CASE WHEN (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsHidden, PSP.bitmapOrder)) = 0 THEN 0 ELSE 1 END) END AS BIT) AS isHidden,    
			CAST(CASE WHEN (SELECT ISNULL(value,1) FROM dbo.f_CustSetting_ProductStatusSel(stt_UPLINE.bitmapIsHidden, PSP.bitmapOrder))=0 THEN 0 ELSE 1 END AS BIT) AS isHiddenUpline,   
			CASE WHEN stt.CustID IS NULL THEN 1 ELSE (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsDisabled, PSP.bitmapOrder)) END AS isDisabled,  
			0 AS IsDisabledDownline,			
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt_UPLINE.bitmapIsDisabled, PSP.bitmapOrder)) AS IsDisabledUpline,  
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt_UPLINE.bitmapHasSynced, PSP.bitmapOrder)) as IsSyncedUpline,  
			0 As HasDownline  
		FROM DBCUST.CUSTDB.dbo.ProductSettingDetail pdt WITH (NOLOCK)  
			INNER JOIN #SportBettypeFilter ft ON pdt.SportType = ft.sporttype AND pdt.BetType = ft.bettype AND pdt.IsLive = ft.islive AND pdt.SettingType = ft.SettingType
			INNER JOIN ProductStatusProfile psp WITH (NOLOCK) ON PSP.Bettype = pdt.BetType AND PSP.Sporttype = PDT.SportType                 
			LEFT JOIN dbo.CustProductStatus stt WITH (NOLOCK) ON stt.CustID = @CustID  
			LEFT JOIN  dbo.CustProductStatus stt_UPLINE WITH (NOLOCK) ON stt_UPLINE.CustID = @AgentID  
		WHERE pdt.SettingType IN (4,11,13) AND (@SettingType IS NULL OR ft.SettingType = @SettingType)
	END   
END

GO
