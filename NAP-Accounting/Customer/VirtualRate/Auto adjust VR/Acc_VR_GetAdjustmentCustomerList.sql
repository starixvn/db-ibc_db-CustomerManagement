/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE	dbo.Acc_VR_GetAdjustmentCustomerList   
	@Sporttype INT = 2
AS  
/*  
	Created:	
	Task:		Get Adjustment Customer List for DW check performance
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20200805@Eden: First commit [#138168]

	Param's Explanation:  
	Examples:
		EXEC Acc_VR_GetAdjustmentCustomerList
*/  
BEGIN  
	SET NOCOUNT ON  
	--> get customer list whose invidual VR setting = 0
	DECLARE @LevelID INT
	DECLARE @ValueID_0 INT
	DECLARE @CurrentDTS DATE = GETDATE()

	SELECT @LevelID = levelID
	FROM VRSettingHierarchy  WITH(NOLOCK)
	WHERE SportType = @Sporttype
		AND VRLeagueGroupID = -1
		AND BetType = -1

	SELECT @ValueID_0 = ValueID
	FROM VRValueMapping WITH(NOLOCK)
	WHERE Value = 1.00

	SELECT v.custid
	FROM VRCustAutoAdjustment v WITH(NOLOCK)
		 INNER JOIN VRCustSetting vr WITH(NOLOCK)
		   ON v.custid = vr.CustID
			  AND vr.LevelID = @LevelID
			  AND vr.ValueIDLIVE = @ValueID_0
			  AND vr.ValueIDNonLIVE = @ValueID_0
	WHERE v.SportType = @Sporttype
		AND (v.FirstBetDate = DATEADD( dd,-8,@CurrentDTS) OR v.FirstBetDate IS NULL)
		AND v.[Status] = 2
		AND NOT EXISTS
						(
							SELECT TOP 1 1
							FROM VRCustSetting vr1 WITH(NOLOCK)
							WHERE vr1.CustID = v.custid
									AND vr1.LevelID > @LevelID
									AND (vr1.ValueIDLIVE <> @ValueID_0
										OR vr1.ValueIDNonLIVE <> @ValueID_0)
						)
		AND NOT EXISTS( SELECT TOP 1 1 FROM VRSettingManualUpdAcc m WITH(NOLOCK) WHERE SportType = @Sporttype AND m.CustID = v.custid)

END
GO
