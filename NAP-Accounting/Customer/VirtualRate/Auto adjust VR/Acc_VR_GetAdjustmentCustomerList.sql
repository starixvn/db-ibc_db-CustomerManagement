/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE	dbo.Acc_VR_GetAdjustmentCustomerList   
	@Sporttype INT = 99
AS  
/*  
	Created:	
	Task:		Get Adjustment Customer List for DW check performance
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20200805@Eden: First commit [#138168]
		- 20200811@Eden: Adjust VR setting for Other Sports of Haifa, IBO, Mansion88 & Happy8 [redmine: #139229]

	Param's Explanation:  
	Examples:
		EXEC Acc_VR_GetAdjustmentCustomerList
*/  
BEGIN  
	SET NOCOUNT ON  
	--> get customer list whose invidual VR setting = 0
	DECLARE @CurrentDTS DATE = GETDATE()

	--> Scan all members with Status = 2
	SELECT v.custid
	FROM VRCustAutoAdjustment v WITH(NOLOCK)
	WHERE v.SportType = @Sporttype
		AND (v.FirstBetDate = DATEADD( dd,-7,@CurrentDTS) OR v.FirstBetDate IS NULL)
		AND v.[Status] = 2

END
GO
