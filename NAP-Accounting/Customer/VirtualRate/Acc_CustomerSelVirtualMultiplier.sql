/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,wsv_nap,bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE  [dbo].[Acc_CustomerSelVirtualMultiplier] 
	@CustID int,
	@IsTest BIT=0
AS
	/*
		Created: 
		Date: 
		DB: DBACC/bodb02
		Task: Get virtual rate settings of customers
		
		Revisions:
			- 20141226@Johnson: Separate virtual rate by sporttype, bettype [Redmine: #25840]	
			- 20151029@Billy: Using new Virtual Rate structure [Redmine: #46541]
			- 20160128@Billy: Update Virtual Rate's range from [-0.8, 1.6] to [-0.9, 1.6] - [Redmine: #51611]
			- 20160816@Winnie: Change sp for UAT purpose [Redmine: #61713]			
			- 20170328@Elodie: Expand the range of VR setting [RedmineID:#73808]
			- 20190725@Elodie: Extend range and interval steps [Redmine:#117609]
			- 20190702@Dominic: Not show E-Sports [RedmineID:#114830]
			- 20200608@Cherry: Not show Basketball (#134978)
			- 20210223@Eden: Implement Lock for VR update [Redmine:#149370]
			- 20230302@Johnson: Return Basketball VR to its original state [redmine:#184339]
			- 20230427@Luke: Separate lock function for Basketball [Redmine: #185991]
			- 20230711@Helios: VR Accumulate Balance [Redmine: #189649] 
			- 20231205@Luke: NAP - Virtual rate - Enhance VR [Redmine: #194939]
		Parameter's Explanation:

	*/
BEGIN
	SET NOCOUNT ON

    DECLARE @ActualRate FLOAT
    DECLARE @CustVirtualRate TABLE (
                custid INT,
                sporttype SMALLINT,
                bettype SMALLINT,
                islive BIT,
                virtualMultiplier SMALLMONEY)

    SELECT      @ActualRate = actualrate
    FROM        exchange AS e WITH(NOLOCK)
    INNER JOIN  Customer AS c
            ON  e.exchangeid = c.currency
    WHERE       c.custid = @CustID

    SELECT  @ActualRate         AS ActualRate,
            ci.VirtualMultiplier   AS EnableVirtualRate,
            -0.95               AS Min_VirtualMultiplier,
            2.0                 AS Max_VirtualMultiplier,
			CASE WHEN sc.CustID IS NOT NULL THEN 1 ELSE 0 END AS VRLockedStatus_Soccer,
			CASE WHEN os.CustID IS NOT NULL THEN 1 ELSE 0 END AS VRLockedStatus_OS,
			CASE WHEN bb.CustID IS NOT NULL THEN 1 ELSE 0 END AS VRLockedStatus_Basketball,
			CASE WHEN ab.CustID IS NOT NULL THEN 1 ELSE 0 END AS VRAccumulated_Balance
    FROM    custInfo ci WITH(NOLOCK)
			LEFT JOIN VRCustLockStatus sc WITH(NOLOCK) ON ci.custid = sc.CustID AND sc.Type = 1 --soccer 
			LEFT JOIN VRCustLockStatus os WITH(NOLOCK) ON ci.custid = os.CustID AND os.Type = 2 --soccer 
			LEFT JOIN VRCustLockStatus bb WITH(NOLOCK) ON ci.custid = bb.CustID AND bb.Type = 3 --basketball
			LEFT JOIN VRCustLockStatus ab WITH(NOLOCK) ON ci.custid = ab.CustID AND ab.Type = 4 --VRAccumulatedBalance
    WHERE   ci.custid = @CustID

    INSERT INTO @CustVirtualRate
    SELECT      cvs.custid,
                pvs.sporttype,
                pvs.bettype,
                pvs.islive,
                dbo.f_GetVirtualSetting(cvs.bitmapVirtual, pvs.profileID) AS virtualMultiplier
    FROM        CustVirtualSetting    AS cvs WITH(NOLOCK)
    INNER JOIN  ProfileVirtualSetting       AS pvs WITH(NOLOCK)
            ON  cvs.seqNo = pvs.seqNo
    WHERE       cvs.custid = @CustID
			AND ((@IsTest=0 AND pvs.isActive = 1) OR (@IsTest=1))
			AND pvs.sporttype NOT IN (43)
	ORDER BY sporttype, isLive DESC, bettype

    SELECT custid, sporttype, bettype, islive, virtualMultiplier
    FROM @CustVirtualRate
	ORDER BY sporttype, bettype, islive

	DECLARE @roleid TINYINT
	SELECT @roleid = roleid 
	FROM custinfo WITH (NOLOCK)
	WHERE custid = @CustID

	DECLARE @downlines TABLE (custid INT, roleid TINYINT)
	IF @roleid = 4
		INSERT INTO @downlines(custid, roleid)
		SELECT custid, roleid
		FROM custinfo with (NOLOCK)
		WHERE srecommend = @custid
			AND custid <> @custid
	ELSE IF @roleid = 3
		INSERT INTO @downlines(custid, roleid)
		SELECT custid, roleid 
		FROM custinfo with (NOLOCK)
		WHERE mrecommend = @custid
			AND custid <> @custid
	ELSE IF @roleid = 2
		INSERT INTO @downlines(custid, roleid)
		SELECT custid, roleid 
		FROM custinfo with (NOLOCK)
		WHERE recommend = @custid
			AND custid <> @custid

	DECLARE @statusCnt TABLE (roleid TINYINT, lockSC INT, lockOS INT, lockBB INT, enableAB INT)
	DECLARE @custCnt TABLE (roleid TINYINT, cnt INT)

	INSERT INTO @statusCnt(roleid, lockSC, lockOS, lockBB, enableAB)
	SELECT roleid, 
		SUM(IIF(type = 1,1,0)) lockSC,
		SUM(IIF(type = 2,1,0)) lockOS,
		SUM(IIF(type = 3,1,0)) lockBB,
		SUM(IIF(type = 4,1,0)) enableAB

	FROM VRCustLockStatus vr WITH (NOLOCK)
		INNER JOIN @downlines c ON vr.CustID = c.custid
	GROUP BY roleid

	INSERT INTO @custCnt(roleid, cnt)
	SELECT roleid,
		COUNT(1) as cnt
	FROM @downlines
	GROUP BY roleid

	SELECT c.roleid, cnt, 
			ISNULL(lockSC,0) AS lockSC, 
			ISNULL(lockOS,0) AS lockOS, 
			ISNULL(lockBB,0) AS lockBB, 
			ISNULL(enableAB,0) AS enableAB
	FROM @custCnt c 
		LEFT JOIN @statusCnt s ON c.roleid = s.roleid
	ORDER BY c.roleid DESC
END