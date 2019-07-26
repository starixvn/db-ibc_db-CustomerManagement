/*<info serverAlias="DBACC-BODB_ACC" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_VirtualRateMulInsTmpExcel]	
	@UserID INT,
	@virtualrate VARCHAR(MAX),	
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: 
	Task : Insert new multi virtual rates into Acc_CustVirtualRate
	DB: DBACC/BODB_ACC
	Original: 
	Revisions:	
		- 20090812@Simon: Insert new multi virtual rates into Acc_CustVirtualRate
		- 20090919@Jamie: Check data before inserting 
		- 20091116@Daniel: Change to check permission on dedicated function [UploadVR]
		- 20130224@Lukas: move SP to new database bodb_ACC
						& change linked-server from db03 to DBPOLICY
		- 20131203@Elodie: Expand size of string
		- 20150126@Johnson: Separate virtual rate setting into sport types and bet types [Redmine: #25840]						
						+ Change to use new structure : table Ac_VirtualRateList						 						
		- 20170328@Elodie: Expand the range of VR setting [RedmineID:#73808]
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20190725@Elodie: Extend range and interval steps [Redmine:#117609]

	Parameter's Explanation:
		- @virtualRate = '<ROOT>
							<customer username="test123">
								<rate sporttype="1" bettype="1" islive="0" rate="0.8" />
								<rate sporttype="1" bettype="1" islive="1" rate="0.6" />
								<rate sporttype="99" bettype="1" islive="0" rate="1.5" />
								<rate sporttype="99" bettype="1" islive="1" rate="1.2" />
							</customer>	
							<customer username="supertest12">
								<rate sporttype="1" bettype="1" islive="0" rate="0.5" />
								<rate sporttype="1" bettype="1" islive="1" rate="0.9" />
								<rate sporttype="99" bettype="1" islive="0" rate="1" />
								<rate sporttype="99" bettype="1" islive="1" rate="0.7" />
							</customer>
						</ROOT>'						
*/
BEGIN
SET NOCOUNT ON
			
	--Check permission for account site
	EXEC DBPOL.NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[UploadVR]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN

	DECLARE @tblCust TABLE (
		UserName	NVARCHAR(50),
		sporttype	INT,
		bettype		INT,
		isLive		BIT,
		VirtualRate	SMALLMONEY
	)

	DECLARE @tblFail TABLE (
		UserName	NVARCHAR(50),
		sporttype	INT,
		bettype		INT,
		isLive		BIT,
		VirtualRate	SMALLMONEY,
		Reason		NVARCHAR(100)
	)
	
	DECLARE @DocHandler INT		
	
	IF @virtualrate <> ''
	BEGIN
		-- For read xml					
		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @virtualrate

		INSERT INTO @tblCust(
					UserName,
					SportType,
					BetType,
					IsLive,
					Virtualrate
				)
		SELECT
			Data.username,
			Data.SportType,
			Data.BetType,
			Data.IsLive,
			Data.rate
		FROM OPENXML (@DocHandler, '/ROOT/customer/rate',2) 
		WITH (
			username	NVARCHAR(50) '../@username',
			SportType	SMALLINT '@sporttype',
			BetType		SMALLINT '@bettype',
			IsLive		BIT '@islive',
			rate		SMALLMONEY '@rate'	
		) AS Data

		EXEC sp_xml_removedocument @DocHandler
		-- end read xml	
	END		


	INSERT INTO @tblFail(username, sporttype, bettype, isLive, virtualrate, reason)
	SELECT	username, sporttype, bettype, isLive, virtualrate, 
			CASE WHEN virtualrate <0.05 OR virtualrate > 3 
						OR ((virtualrate*100)%5!=0 AND (VirtualRate BETWEEN 0.2 AND 1.05 OR VirtualRate BETWEEN 1.1 AND 1.6)) -- -5,-10,-15,-20,-25,-30,-35,-40,-45,-50,-55,-60,-65,-70,-75, -80, 60,55,50,45,40,35,30,25,20,15,10
						OR ((virtualrate*100)%1!=0 AND VirtualRate BETWEEN 0.05 AND 0.2) -- -80,-81,-82,-83,-84,-85,-86,-87,-88,-89,-90,-91,-92,-93,-94,-95
						OR (VirtualRate IN (1.06,1.07,1.08,1.09,2,2.5,3)) --6,7,8,9,100,150,200 
						THEN 'Invalid Virtual Rate.'
				 WHEN ISNULL(username,'') ='' THEN 'Username cannot be blanked.' ELSE '' END AS Reason 	
	FROM	@tblCust 
	WHERE	virtualrate <0.05 
			OR virtualrate > 3 
			OR ((virtualrate*100)%5!=0 AND (VirtualRate BETWEEN 0.2 AND 1.05 OR VirtualRate BETWEEN 1.1 AND 1.6)) -- -5,-10,-15,-20,-25,-30,-35,-40,-45,-50,-55,-60,-65,-70,-75, -80, 60,55,50,45,40,35,30,25,20,15,10
			OR ((virtualrate*100)%1!=0 AND VirtualRate BETWEEN 0.05 AND 0.2) -- -80,-81,-82,-83,-84,-85,-86,-87,-88,-89,-90,-91,-92,-93,-94,-95
			OR (VirtualRate IN (1.06,1.07,1.08,1.09,2,2.5,3)) --6,7,8,9,100,150,200
			OR ISNULL(username,'') ='' 
	
	INSERT INTO dbo.Acc_VirtualRateList(userid, username, sporttype, bettype, islive, virtualrate)
	SELECT	@UserID, 
			c.username,
			c.sporttype,
			c.bettype,
			c.isLive,
			c.virtualrate
	FROM	@tblCust c
		LEFT JOIN @tblFail t ON c.UserName = t.username
								AND c.sporttype = t.sporttype 
								AND c.bettype = t.bettype
								AND c.isLive = t.isLive
	WHERE	t.username IS NULL
	
	IF @@ERROR <> 0
	BEGIN
		SELECT	@ErrMsg = 'Insert process is unsuccessful.',
				@ErrCode = 103
		RETURN			
	END
	
	SELECT * FROM @tblFail 
END

GO
GRANT EXECUTE ON [dbo].[Acc_VirtualRateMulInsTmpExcel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_VirtualRateMulInsTmpExcel] TO [vnteam] AS [dbo]