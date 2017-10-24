/*<info serverAlias="DBLIC-bodb_licensee" executers="bodbadminNet" viewers="vnteam" isFunction="0"></info>*/
USE bodb_licensee
GO
ALTER PROCEDURE	dbo.Acc_CustomerVirtualRateSelectBA
					@CustID		VARCHAR(MAX)	= ''				
AS  
/*  
	Created:	20171024@Winnie
	Task:		Get BA customers
	DB:			DBLIC/bodb_licensee
	Original:    
	Revisions: 	
	Param's Explanation:  
		- @SportType = 0 : All
					 = 1 : Soccer
					 = 2 : Other Sports
		- @VirtualMultiplier = '<ROOT>
									<Rate CustIds="1,2,3,4,5,6" VirtualMultiplier="0.7" />	
									<Rate CustIds="11,22,33,44,55,66" VirtualMultiplier="1.5" />
								</ROOT>'
*/  
BEGIN  
	SET NOCOUNT ON;  

	CREATE TABLE #CustList (CustID INT PRIMARY KEY)
	INSERT INTO #CustList(CustID)
	SELECT CONVERT(INT,ss.val)
	FROM dbo.strSplit(@CustID, ',') AS ss

	DELETE t
	FROM #CustList t
	INNER JOIN dbo.[LicenseeBAHistory] ba WITH (NOLOCK) ON t.CustID=BA.CustID
	WHERE ba.Status = 'Running'

	SELECT * FROM #CustList
	
END

GO
GRANT EXECUTE ON Acc_CustomerVirtualRateSelectBA TO bodbAdminNet 
