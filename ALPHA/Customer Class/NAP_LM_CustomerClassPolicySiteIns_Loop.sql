/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassPolicySiteIns_Loop] 
	@PolicySites  NVARCHAR(MAX)
	, @IsTest		TINYINT
	, @IsOverwrite	BIT = 1
	, @UserID		INT
	, @IP			VARCHAR(50)		= ''
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
	Example: NAP_LM_CustomerClassPolicySiteIns_Loop @PolicySites ='<ROOT><r PolicyID=1 Site="6777777" Currency=20 Platform=1/> 
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
   
	 CREATE TABLE #CustomerClass( PolicyID INT, Site NVARCHAR(MAX), Currency VARCHAR(MAX), Platform VARCHAR(MAX), STT INT IDENTITY (1,1), isFinished BIT DEFAULT(0))  
	
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

	 SET @iCheck = 1

	 WHILE (1 = 1)
	 BEGIN
		UPDATE TOP (1) c
		SET c.isfinished = 1
		FROM #CustomerClass c 
		WHERE isfinished = 0 AND STT = @iCheck
		
		IF @@ROWCOUNT = 0 BREAK

		SET @xml = (
				SELECT	PolicyID	AS '@PolicyID',
						Site		AS '@Site',
						Currency 	AS '@Currency',
						Platform 	AS '@Platform'
				FROM #CustomerClass c 
				WHERE STT = @iCheck 
				FOR XML PATH('r'),ROOT ('ROOT'),
				TYPE )
		
		IF @xml IS NOT NULL 
		BEGIN
			SET @PolicySite = CONVERT(VARCHAR(MAX), @xml)
			EXEC NAP_LM_CustomerClassPolicySiteIns @IsOverwrite=@IsOverwrite,@UserID=@UserID,@PolicySites=@PolicySite,@IP=@IP,@IsTest=@IsTest, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
		END

		SET @iCheck = @iCheck + 1
		SET @xml = ''
	 END
	
	DROP TABLE #CustomerClass
END
GO
