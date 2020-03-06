/*<info serverAlias="DBCUST-CUSTDB" executers="" viewers="" isFunction="0" isNested="0" ></info>*/
ALTER PROCEDURE [dbo].[Task_VRSettingAutoUpdate_TransferData]
AS
/*   
	Create: 20200304@Eden
	Task : Transfer data from VR2Model_VirtualRate to VRSettingAutoUpdate 
	DB: DBCUST/CustDB
	Revisions:
		- 20200304@Eden: Initial version [Redmine:#129279]
		
	Param's Explanation:
	
*/
BEGIN
	TRUNCATE TABLE VRSettingAutoUpdate

	INSERT INTO VRSettingAutoUpdate(
		 CustId
		,IsLive
		,SportType
		,VRLeagueGroupId
		,VRBettypeGroupId
		,Bettype
		,VirtualMultiplier
		,CreatedDate
	)
	SELECT cv.CustId
		,IsLive
		,SportId
		,VRLeagueGroupId
		,VRBettypeGroupId
		,BettypeId
		,cv.VirtualMultiplier
		,CreatedDate
	FROM DBDW2.bodb_VR2Model.[dbo].[VR2Model_VirtualRate] cv WITH (NOLOCK)
		INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON ci.custid = cv.CustId
	UNION ALL
	SELECT cv.CustId
		,IsLive
		,SportId
		,VRLeagueGroupId
		,VRBettypeGroupId
		,BettypeId
		,cv.VirtualMultiplier
		,CreatedDate
	FROM DBDW2.bodb_VR2Model.[dbo].[VR2Model_VirtualRate] cv WITH (NOLOCK)
	WHERE cv.CustId = 0
	UNION ALL
	SELECT CustId
		,IsLive
		,SportId
		,VRLeagueGroupId = -1
		,VRBettypeGroupId
		,BettypeId
		,VirtualMultiplier
		,CreatedDate
	FROM DBDW2.bodb_VR2Model.[dbo].[VR2Model_VirtualRate] WITH (NOLOCK)
	WHERE VRLeagueGroupId = 11 AND VRBettypeGroupId = -1 AND BettypeId = -1 AND CustID = 0
END
GO
