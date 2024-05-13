/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassPolicySiteIns_Loop] 
	@PolicySites  NVARCHAR(MAX)
	, @IsTest		TINYINT
	, @IsOverwrite	BIT = 1
	, @UserID		INT
	, @IP			VARCHAR(50)		= ''
	, @ActionID		BIT = 0
	, @ErrCode		INT				= 0		OUTPUT
	, @ErrMsg		NVARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: Winfred
	Date: 20240223
	Task : [NAP CM] Update SP to call loop for updating policies [#201256]
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20240223@Winfred: [NAP CM] - CCMgt - Update SP to call loop for updating policies [RedmineID: #201256] 
		- 20240315@Winfred: [NAP CM] - CCMgt - Enhance SP call loop for updating policies [RedmineID: #201256] 

	Param's Explanation:
	* @Policys:
		'<ROOT><r PolicyID = 1 Site = "6777777" Currency = "20,75" Platform = "1,2,3,6"/> 
			   <r PolicyID = 2 Site = "2222222" Currency = "4" Platform = "2,4"/>
		</ROOT>'
	* Site : "All : All
			  AllCredit : All site Credit 
			  AllDeposit : All site Deposit"
	* Currency : 0 : All
	* Platform : "0 : All
				  1 : Desktop
				  2 : Mobile
				  3 : APP
				  4 : Oddsfeed
				  5 : DirectAPI"
	* @IsOverwrite : 1. Overwrite, 0. Not Overwrite
	Example: NAP_LM_CustomerClassPolicySiteIns_Loop 
		@PolicySites ='<ROOT><r PolicyID=1 Site="6777777" Currency=20 Platform=1/> 
						<r PolicyID=2 PolicyTitle="2222222" Currency=4 Platform=2/> </ROOT>' ,@ErrCode =0, @ErrMsg = '',  @IP = '11.12.11.10', @UserID = 6
*/ 
BEGIN
	SET NOCOUNT ON;   
   
	 DECLARE @iDoc     INT  
	  , @xml     XML  
	  , @iCheck INT = 1
	  , @PolicySite NVARCHAR(MAX)
   
	 --Check if XML is null or empty  
	 IF @PolicySites IS NULL OR @PolicySites = ''  
	  RETURN  
   
	 CREATE TABLE #CustomerClass( PolicyID INT, Site NVARCHAR(MAX), Currency VARCHAR(MAX), Platform VARCHAR(MAX), STT INT IDENTITY (1,1))  
	 CREATE TABLE #CustomerClass_Group( PolicyID INT, Site NVARCHAR(50), Currency INT, Platform TINYINT, STT INT, BatchID TINYINT) 
	
	 BEGIN TRY  
	  EXECUTE sp_xml_preparedocument @iDoc OUTPUT, @PolicySites;  
  
	  INSERT INTO #CustomerClass (PolicyID , Site , Currency , Platform )  
	  SELECT CASE WHEN Data.PolicyID = '' THEN null ELse  CAST(Data.PolicyID AS INT) END AS PolicyID          
		, Data.Site            
		, Data.Currency              
		, Data.Platform  
	  FROM OPENXML (@iDoc, '/ROOT/r', 1)   
	  WITH (  
		PolicyID  VARCHAR(20),             
		Site     NVARCHAR(MAX),  
		Currency  VARCHAR(MAX),  
		Platform  VARCHAR(MAX)  
	  ) AS Data;  
  
	  EXECUTE sp_xml_removedocument @iDoc;  
	 END TRY  
	 BEGIN CATCH  
	  SELECT  @ErrMsg = N'Invalid XML format' , @ErrCode = 3 ;    
	  RETURN  
	 END CATCH  

	 INSERT INTO #CustomerClass_Group (PolicyID , Site , Currency , Platform , STT, BatchID)
	 SELECT a.PolicyID, b.Site, CAST(c.Currency AS TINYINT) AS Currency, CAST(d.Platform  AS TINYINT) AS Platform , STT
	   ,DENSE_RANK() OVER(PARTITION BY b.Site  ORDER BY  STT) AS BatchID
	 FROM #CustomerClass a  
	  CROSS APPLY ( SELECT VALUE AS site FROM STRING_SPLIT(a.Site,',') WHERE VALUE <> '' ) b  
	  CROSS APPLY ( SELECT VALUE AS Currency FROM STRING_SPLIT(a.Currency,',') WHERE VALUE <> '' ) c  
	  CROSS APPLY ( SELECT VALUE AS Platform FROM STRING_SPLIT(a.Platform,',') WHERE VALUE <> '' ) d  
	ORDER BY BatchID, STT, PolicyID, site, Currency, Platform

	;WITH Tmp AS (
	SELECT DISTINCT a.BatchID, a.PolicyID, a.STT, b.Sites, c.Currency, d.Platform ,
	DENSE_RANK() OVER(PARTITION BY a.BatchID ORDER BY a.BatchID,a.STT) AS RowBatch
	FROM #CustomerClass_Group a
		CROSS APPLY(
				SELECT STRING_AGG(CAST(Site AS VARCHAR(MAX)), ',')  AS Sites
				FROM (SELECT DISTINCT PolicyID , STT, Site
				FROM #CustomerClass_Group 
				WHERE BatchID = a.BatchID  AND PolicyID = a.PolicyID  AND STT = a.STT
				) mis
			) b
		CROSS APPLY(
				SELECT STRING_AGG(CAST(Currency AS VARCHAR(MAX)), ',')  AS Currency
				FROM (SELECT DISTINCT PolicyID , STT, Currency 
				FROM #CustomerClass_Group 
				WHERE BatchID = a.BatchID   AND PolicyID = a.PolicyID  AND STT = a.STT  
				) mis
			) c
		CROSS APPLY(
				SELECT STRING_AGG(CAST(Platform AS VARCHAR(MAX)), ',')  AS Platform
				FROM (SELECT DISTINCT PolicyID , STT, Platform 
				FROM #CustomerClass_Group
				WHERE BatchID = a.BatchID   AND PolicyID = a.PolicyID  AND STT = a.STT  
				) mis
			) d
	)
	
	INSERT INTO CustomerClassSMQueue (UserID, IsTest, IsOverwrite, ActionID, IP, LastModifiedTime, Status, ErrCode, BatchID, PolicySites)
	SELECT  @UserID AS UserID, @IsTest AS IsTest, @IsOverwrite AS IsOverwrite, @ActionID, 
			@IP AS IP, GETDATE() AS LastModifiedTime, 0 AS Status, 0 AS ErrCode, c.BatchID ,CAST((
				SELECT	PolicyID	AS '@PolicyID',
						Sites		AS '@Site',
						Currency 	AS '@Currency',
						Platform 	AS '@Platform'
				FROM Tmp
				WHERE BatchID = c.BatchID  
				ORDER BY STT
				FOR XML PATH('r'),ROOT ('ROOT'),
				TYPE ) AS NVARCHAR(MAX)) AS PolicySites
	from Tmp c
	WHERE RowBatch = 1

	DROP TABLE #CustomerClass
	DROP TABLE #CustomerClass_Group
END
