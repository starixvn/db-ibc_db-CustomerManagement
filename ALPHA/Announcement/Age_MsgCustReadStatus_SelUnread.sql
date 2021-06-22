/*<info serverAlias="DBMSG-bodb_Message" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_Message]
GO

ALTER PROCEDURE [dbo].[Age_MsgCustReadStatus_SelUnread]
	@CustId INT
	,@SubAccId INT = 0
	,@IsTest BIT = 0
	,@targetid2 VARCHAR(100) = '0'
AS
/*
	Created: 20180621@Razor
	Task : Announcement Renovation
	DB: DBMSG/bodb_Message
	
	Revisions:
		- 20180621@Razor: Renovation Announcement [Redmind: #94705]
		- 20180817@Viet: revise SP
		- 20210309@Max: [Alpha] Duplicated message shown in Personal message [Redmine: #149622]
		- 20210622@Joe: Revise SP
	Param's Explanation: 
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @lastSeenNormalMsg DATETIME, @lastSeenSpecialMsg DATETIME, @lastSeenPersonalMsg DATETIME
	DECLARE  @Saved_lastSeenNormalMsg DATETIME, @Saved_lastSeenSpecialMsg DATETIME, @Saved_lastSeenPersonalMsg DATETIME
	DECLARE @Saved_cntNormal INT, @Saved_cntSpecial INT, @Saved_cntPersonal INT
	DECLARE @ProcessMode TINYINT, @LastCutOffTime DATETIME
	
	-- read current LastSeen to determine MIN(LastSeen)
	-- read saved value calculate base on LastSeen -vs- LastCutOff
	SELECT @lastSeenNormalMsg   = LastSeenNormalMsg,
		@lastSeenSpecialMsg  = LastSeenSpecialMsg,
		@lastSeenPersonalMsg = LastSeenPersonalMsg,
		@LastCutOffTime = LastCutOff,
		@Saved_lastSeenNormalMsg   = Saved_LastSeenNormalMsg,
		@Saved_lastSeenSpecialMsg  = Saved_LastSeenSpecialMsg,
		@Saved_lastSeenPersonalMsg = Saved_LastSeenPersonalMsg,
		@Saved_cntNormal   = Saved_cntNormal,
		@Saved_cntSpecial  = Saved_cntSpecial,
		@Saved_cntPersonal = Saved_cntPersonal
	FROM MsgCustReadStatus WITH(NOLOCK)
	WHERE CustId = @CustId AND SubAccID = @SubAccId

	DECLARE @minLastSeen DATETIME
	SET @minLastSeen = @lastSeenNormalMsg
	IF @minLastSeen > @LastSeenSpecialMsg SET @minLastSeen = @LastSeenSpecialMsg
	IF @minLastSeen > @lastSeenPersonalMsg SET @minLastSeen = @lastSeenPersonalMsg

	-- determine which action need to perform
	IF (@Saved_lastSeenNormalMsg   <> @lastSeenNormalMsg -- lastSeenNormalMsg was change  
		OR	@Saved_lastSeenSpecialMsg  <> @lastSeenSpecialMsg -- lastSeenSpecialMsg was change 
		OR	@Saved_lastSeenPersonalMsg <> @lastSeenPersonalMsg -- lastSeenPersonalMsg was change
		OR	DATEDIFF(day, @LastCutOffTime, CURRENT_TIMESTAMP) >= 2 -- LastCutOff is too old
		OR	@LastCutOffTime IS NULL -- no cut off value yet, get whole data, so keep MinLastSeen untouch
			)
			--we will get whole data again (using MinLastSeen), and update new CutOff
			SELECT @ProcessMode = 1
		ELSE
			-- Last Seen still the same, just get data using LastCutOff
			SELECT @ProcessMode = 2, @minLastSeen = @LastCutOffTime

	-- actual data pulling
	DECLARE @mInfo as TABLE (MsgType tinyint, targetID int)	

	IF @targetid2 <> '0'
	BEGIN
		INSERT INTO @mInfo (MsgType, targetID)
		SELECT 3, val
		FROM dbo.strSplit(@targetid2, ',')

		INSERT INTO @mInfo (MsgType, targetID)
		SELECT MsgType, CONVERT(INT, LEFT(RTRIM(targetID),2)+'00'+RIGHT(RTRIM(targetID),2)+'0')
		FROM @mInfo
		WHERE targetID BETWEEN 1000 AND 9999 --len(targetID) = 4
	END

	INSERT INTO @mInfo (MsgType, targetID) VALUES (1, @CustId)

	DECLARE @new_cntNormal INT, @new_cntSpecial INT, @new_cntPersonal INT
	;WITH cteMsg
	AS(
	SELECT DISTINCT m.MessageId, m.MsgType, m.PostTime, m.IsSticky, s.targetID
	FROM dbo.Msg m WITH (NOLOCK, INDEX=IX_PostTime)
		INNER JOIN @mInfo s ON s.MsgType = m.MsgType
		INNER JOIN dbo.MsgTarget mt WITH (NOLOCK) ON mt.MessageId =  m.MessageId AND mt.TargetId = s.targetID AND mt.isDeleted = 0
	WHERE  m.PostTime > @minLastSeen
		AND m.isDeleted = 0 
		AND  m.IsTest = @IsTest
	)
	SELECT
		@new_cntNormal   = SUM(CASE WHEN m.MsgType = 3 AND m.IsSticky = 0 AND m.PostTime > @lastSeenNormalMsg THEN 1 ELSE 0 END),
		@new_cntSpecial  = SUM(CASE WHEN m.IsSticky = 1 AND m.PostTime > @lastSeenSpecialMsg THEN 1 ELSE 0 END),
		@new_cntPersonal = SUM(CASE WHEN m.MsgType = 1 AND m.PostTime > @lastSeenPersonalMsg THEN 1 ELSE 0 END)
	FROM cteMsg m

	-- perform action base on @ProcessMode
	IF @ProcessMode = 1 -- "LastSeen" got changed, and we re-count, update all figure
	BEGIN
		UPDATE dbo.MsgCustReadStatus
		SET LastCutOff = CURRENT_TIMESTAMP,
			Saved_LastSeenNormalMsg   = @lastSeenNormalMsg,
			Saved_LastSeenSpecialMsg  = @lastSeenSpecialMsg,
			Saved_LastSeenPersonalMsg = @lastSeenPersonalMsg,
			Saved_cntNormal   = @new_cntNormal,
			Saved_cntSpecial  = @new_cntSpecial,
			Saved_cntPersonal = @new_cntPersonal
		WHERE
			CustID = @CustId AND subAccID = @SubAccId

		SELECT @new_cntNormal AS Normal, @new_cntSpecial AS Special, @new_cntPersonal AS Personal
	END
	ELSE --IF @ProcessMode = 2 -- using LastCutOff value, Nothing to change, just return combined value of (Saved Count + New Count)
	BEGIN
		-- got new message? but reach here mean customer not see old message yet.
		-- we saved the value + update new CutOff
		-- so next round, we don't have to read that again.
		IF (ISNULL(@new_cntNormal  ,0) + ISNULL(@new_cntSpecial ,0) + ISNULL(@new_cntPersonal,0)) > 0
			UPDATE dbo.MsgCustReadStatus
			SET LastCutOff = CURRENT_TIMESTAMP,
				Saved_cntNormal   = @Saved_cntNormal   + ISNULL(@new_cntNormal  ,0),
				Saved_cntSpecial  = @Saved_cntSpecial  + ISNULL(@new_cntSpecial ,0),
				Saved_cntPersonal = @Saved_cntPersonal + ISNULL(@new_cntPersonal,0)
			WHERE
				CustID = @CustId AND subAccID = @SubAccId

		SELECT
			ISNULL(@new_cntNormal  ,0) + @Saved_cntNormal   AS Normal,
			ISNULL(@new_cntSpecial ,0) + @Saved_cntSpecial  AS Special,
			ISNULL(@new_cntPersonal,0) + @Saved_cntPersonal AS Personal
	END
END

