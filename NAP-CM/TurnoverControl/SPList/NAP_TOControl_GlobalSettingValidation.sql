/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_TOControl_GlobalSettingValidation]
	 @GlobalSetting VARCHAR(MAX) = ''
	 , @SportType SMALLINT = 1
AS
/*
	Created: Helen
	Date: 2017-09-18
	Task: global settings validation, import from excel file
	DB: DBCUST.CustDB

	Revisions:

	Parameter's explaination:
	Sample data for @GlobalSetting: 
		'<ROOT>
			<GlobalSetting Username="super01" Headline="0" MaxTurnover="100" SportType = "1" />
			<GlobalSetting Username="super02" Headline="1" MaxTurnover="1" SportType = "1"/>
		</ROOT>'
*/
BEGIN
	
	CREATE TABLE #GlobalSettingTbl (ID INT IDENTITY(1,1) PRIMARY KEY, Username NVARCHAR(50), IsGroupHeadline VARCHAR(50), MaxTurnover VARCHAR(50), SportType SMALLINT)
	
	CREATE TABLE #GlobalSettingTblError (ID INT, Username NVARCHAR(50), IsGroupHeadline VARCHAR(50), MaxTurnover VARCHAR(50), SportType SMALLINT, ErrorID TINYINT)		
	
	CREATE TABLE #ErrorList (ErrorID TINYINT, Reason VARCHAR(200))
	INSERT INTO #ErrorList (ErrorID,Reason)
	VALUES	(1, 'Invalid Username')
			, (2, 'The account is not a Headline')
			, (3, 'Invalid Headline value')
			, (4, 'Invalid Max Turnover')
		
	--Parse XML	
	DECLARE @iDoc INT

	EXEC sp_xml_preparedocument @iDoc OUTPUT, @GlobalSetting

	INSERT #GlobalSettingTbl (Username,IsGroupHeadline,MaxTurnover,SportType)
	SELECT Username,ISNULL(IsGroupHeadline,'') AS IsGroupHeadline,MaxTurnover,SportType
	FROM OPENXML(@iDoc, '/ROOT/GlobalSetting', 1) WITH (Username NVARCHAR(50), IsGroupHeadline	VARCHAR(50), MaxTurnover VARCHAR(50), SportType SMALLINT)

	EXEC sp_xml_removedocument @iDoc		
		
	INSERT INTO #GlobalSettingTblError (ID,Username,IsGroupHeadline,MaxTurnover,SportType, ErrorID)
	SELECT GS.ID, GS.Username,GS.IsGroupHeadline,GS.MaxTurnover,GS.SportType, 1
	FROM #GlobalSettingTbl GS WITH (NOLOCK)
		LEFT JOIN dbo.custInfo ci WITH (NOLOCK) ON gs.username = ci.username
	WHERE ci.custid IS NULL
	
	UNION ALL		
	
	SELECT GS.ID, GS.Username,GS.IsGroupHeadline,GS.MaxTurnover,GS.SportType, 2
	FROM #GlobalSettingTbl GS WITH (NOLOCK)
		INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON gs.username = ci.username
		LEFT JOIN dbo.custAccount CA WITH (NOLOCK) ON CA.custid = ci.custid
	WHERE GS.IsGroupHeadline IN ('x','X') AND (CA.custid IS NULL OR CA.IsGroupHeadLine = 0)
	
	UNION ALL
	
	SELECT GS.ID, GS.Username,GS.IsGroupHeadline,GS.MaxTurnover,GS.SportType, 3
	FROM #GlobalSettingTbl GS WITH (NOLOCK)
	WHERE GS.IsGroupHeadline NOT IN ('x','X') AND GS.IsGroupHeadline <> ''
	
	UNION ALL
	
	SELECT GS.ID, GS.Username,GS.IsGroupHeadline,GS.MaxTurnover,GS.SportType, 4
	FROM #GlobalSettingTbl GS WITH (NOLOCK)
	WHERE (ISNUMERIC (GS.MaxTurnover) = 1 AND CONVERT(MONEY,GS.MaxTurnover) <= 0)
		 OR ISNUMERIC (GS.MaxTurnover) = 0
		
	-- VALID DATASET
	SELECT GS.Username
			, CASE 
					WHEN CA.custid IS NOT NULL THEN 'Headline'
					WHEN GS.IsGroupHeadline = '' AND CI.roleid = 4 THEN 'Super' 
					WHEN GS.IsGroupHeadline = '' AND CI.roleid = 3 THEN 'Master' 
					WHEN GS.IsGroupHeadline = '' AND CI.roleid = 2 THEN 'Agent' 
					
					ELSE ''
				END AS Level
			 , e.currency AS Currency
			 , CONVERT(MONEY,GS.MaxTurnover) AS MaxTurnover
	FROM #GlobalSettingTbl GS WITH (NOLOCK)
		INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON gs.username = ci.username
		INNER JOIN dbo.exchange e WITH (NOLOCK) ON e.exchangeid = ci.currency
		LEFT JOIN dbo.custAccount CA WITH (NOLOCK) ON CA.custid = ci.custid AND GS.IsGroupHeadline in ('x','X')
	WHERE NOT EXISTS (SELECT 1 FROM #GlobalSettingTblError GSE WITH (NOLOCK) WHERE GSE.ID = GS.ID)
	
	-- ERROR DATASET
	
	SELECT GS.Username, GS.IsGroupHeadline,GS.MaxTurnover, STUFF (GlobalSetting.Reason, 1,1, '') AS Reason
	FROM #GlobalSettingTbl GS WITH (NOLOCK)
		CROSS APPLY (SELECT ',' + ErrorRef.Reason
					 FROM #GlobalSettingTblError GS_error WITH (NOLOCK)
						INNER JOIN #ErrorList ErrorRef WITH (NOLOCK) ON GS_error.ErrorID = ErrorRef.ErrorID
					 WHERE GS_error.ID = GS.ID
					 FOR XML PATH ('')
					 )AS GlobalSetting(Reason)
	
	WHERE GS.ID IN (SELECT ID FROM #GlobalSettingTblError WITH (NOLOCK))
	
	DROP TABLE #ErrorList
	DROP TABLE #GlobalSettingTbl
	DROP TABLE #GlobalSettingTblError
		
END
GO

GO
GRANT EXECUTE ON [dbo].[NAP_TOControl_GlobalSettingValidation] TO [bodbAdminNet]
GO

