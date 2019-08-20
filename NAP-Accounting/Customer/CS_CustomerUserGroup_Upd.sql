/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[CS_CustomerUserGroup_Upd]
	@username varchar(50), 
	@ugroup varchar(3),
	@userid int,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: 20190814@Johnson
	Task : Update User group for cn88
	DB: DBCUST/CUSTDB
	Original:

	Revisions:  
		- 20190814@Johnson: initial sp [redmine: #116691]
	
	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun DATETIME
	DECLARE @endRun DATETIME
	DECLARE @duration INT
	SET @startRun = GETDATE()

	EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	If @ErrCode <> 0
		RETURN
	--end
	
	DECLARE @custid INT, 
			@currency INT, 
			@old_ugroup VARCHAR(3), 
			@srecommend INT, 
			@mrecommend INT, 
			@recommend INT,
			@IsGroupComm BIT,
			@MemCommGroup INT,
			@MemCommGroup_Old INT,
			@PlayerDiscount_XML XML
	
	SELECT
		@custid = custid,
		@currency = currency,
		@old_ugroup = ugroup,
		@recommend = recommend, 
		@mrecommend = mrecommend, 
		@srecommend = srecommend
	FROM customer with(nolock)
	WHERE
		username = @username
		AND roleid = 1
	
	IF @ugroup NOT IN ('a', 'b', 'c', 'd')
	BEGIN
		SELECT @ErrMsg = 'Unable to assign this group to the customer.',
			@ErrCode = 101					 	
		RETURN	
	END
	
	IF ISNULL(@custid, 0) = 0
	BEGIN
		SELECT @ErrMsg = 'Invalid user. Member '+@username+' is not found.',
			@ErrCode = 102					 	
		RETURN	
	END

	--Check disable user
	EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	if @ErrCode <>0 return
	--end

	IF @ugroup = @old_ugroup
	BEGIN
		SELECT @ErrMsg = 'The user group of '+ @username + ' is already "' + @ugroup + '".',
			@ErrCode = 103					 	
		RETURN	
	END
	
	SELECT @IsGroupComm = IsGroupComm FROM dbo.CS_CustSettingMode WITH (NOLOCK) WHERE CustId = @CustID
	
	IF @IsGroupComm = 1
	BEGIN
		SELECT cs.sporttype, cs.bettype, cs.isLive, acs.ValueID
		INTO #CommGroupMem_tmp
		FROM dbo.f_CS_GetGroupDiscount_Member(@recommend) cs--comm for member
			INNER JOIN dbo.f_CS_GetDiscount_Agent(@recommend) acs ON cs.SportType = acs.SportType AND cs.BetType = acs.BetType AND cs.IsLive = acs.IsLive	
			LEFT JOIN dbo.CS_GroupConfig gc WITH (NOLOCK) ON gc.SportType = acs.SportType AND gc.BetType = acs.BetType AND gc.IsLive = acs.IsLive AND gc.GroupId = acs.GroupId
		WHERE (gc.GroupName = @uGroup OR gc.GroupID is NULL)
			AND cs.uGroup = @old_ugroup	
			AND cs.PlayerDiscount > acs.Discount
		
		IF @@ROWCOUNT = 0
			GOTO Update_uGroup
			
		SET @PlayerDiscount_XML =(
										SELECT (
												SELECT	bs.ByteOrder	AS '@pos',
														comm.ValueId	AS '@val'
												FROM #CommGroupMem_tmp comm
													INNER JOIN dbo.CS_ByteSeq bs WITH (NOLOCK) ON bs.SportType = comm.SportType AND bs.BetType = comm.BetType AND bs.IsLive = comm.IsLive
												WHERE bs.Type = 'DiscountMember'
												FOR XML PATH('r')
													, TYPE
												)
										FOR XML PATH('root')
											, TYPE
										)
		
		SELECT @MemCommGroup = COUNT(1) 
		FROM CS_CustSettingMode sm WITH (NOLOCK) 
			INNER JOIN customer c WITH (NOLOCK) ON c.custid = sm.CustID 
		WHERE c.recommend = @recommend AND c.roleid = 1 AND sm.IsGroupComm = 1 AND c.ugroup = @uGroup 
		
		SELECT @MemCommGroup_Old = COUNT(1) 
		FROM CS_CustSettingMode sm WITH (NOLOCK) 
			INNER JOIN customer c WITH (NOLOCK) ON c.custid = sm.CustID 
		WHERE c.recommend = @recommend AND c.roleid = 1 AND sm.IsGroupComm = 1 AND c.ugroup = @Old_uGroup
		
		IF @MemCommGroup = 0 -- first member of new group
		BEGIN
			IF @MemCommGroup_Old = 1
			BEGIN
				UPDATE cm
				SET cm.PlayerDiscount = playercomm.binaryStr_new,
					uGroup = @uGroup
				FROM dbo.CS_CustGroupDiscount_Member cm WITH (ROWLOCK)
					CROSS APPLY dbo.f_SetBinaryValues(cm.PlayerDiscount, @PlayerDiscount_XML) playercomm	
				WHERE cm.AgentId = @recommend AND cm.uGroup = @uGroup
			END	
			ELSE 
			BEGIN
				INSERT INTO dbo.CS_CustGroupDiscount_Member([AgentId],[uGroup],[PlayerDiscount],[AgentDiscount],[MasterDiscount],[SuperDiscount])
				SELECT AgentID, @uGroup, playercomm.binaryStr_new, AgentDiscount, MasterDiscount, SuperDiscount
				FROM dbo.CS_CustGroupDiscount_Member cm WITH(NOLOCK)
					CROSS APPLY dbo.f_SetBinaryValues(cm.PlayerDiscount, @PlayerDiscount_XML) playercomm	
				WHERE AgentID = @recommend
					AND uGroup = @old_ugroup
			END
		END
		ELSE
		BEGIN
			IF EXISTS (SELECT 1 FROM CS_CustGroupDiscount_Member WITH (NOLOCK) WHERE AgentId = @recommend AND uGroup = @uGroup)
			BEGIN
				IF NOT EXISTS (	SELECT 1
							FROM CS_CustGroupDiscount_Member cs1 WITH(NOLOCK)
								INNER JOIN CS_CustGroupDiscount_Member cs2 WITH(NOLOCK) ON cs1.AgentID = cs2.AgentID
																						AND cs1.uGroup = @old_ugroup
																						AND cs2.uGroup = @uGroup
								CROSS APPLY dbo.f_SetBinaryValues(cs1.PlayerDiscount, @PlayerDiscount_XML) playercomm																			
							WHERE playercomm.binaryStr_new = cs2.PlayerDiscount
								AND cs1.AgentDiscount = cs2.AgentDiscount
								AND cs1.MasterDiscount = cs2.MasterDiscount
								AND cs1.SuperDiscount = cs2.SuperDiscount
						)
				BEGIN
					IF EXISTS (SELECT 1 FROM dbo.CS_CustDiscount_Member WITH (NOLOCK) WHERE CustId = @CustID)
					BEGIN
						UPDATE cm
						SET cm.PlayerDiscount = playercomm.binaryStr_new,
							cm.AgentDiscount = gm.AgentDiscount,
							cm.MasterDiscount = gm.MasterDiscount,
							cm.SuperDiscount = gm.SuperDiscount
						FROM dbo.CS_CustDiscount_Member cm WITH (ROWLOCK)
							CROSS JOIN dbo.CS_CustGroupDiscount_Member gm WITH (NOLOCK) 
							CROSS APPLY dbo.f_SetBinaryValues(gm.PlayerDiscount, @PlayerDiscount_XML) playercomm	
						WHERE cm.CustId = @CustID AND gm.AgentId = @recommend AND gm.uGroup = @uGroup			
					END
					ELSE
					BEGIN
						INSERT INTO CS_CustDiscount_Member (CustId, PlayerDiscount, AgentDiscount, MasterDiscount, SuperDiscount)
						SELECT @CustID, playercomm.binaryStr_new, gm.AgentDiscount, gm.MasterDiscount, gm.SuperDiscount
						FROM dbo.CS_CustGroupDiscount_Member gm WITH (NOLOCK) 
							CROSS APPLY dbo.f_SetBinaryValues(gm.PlayerDiscount, @PlayerDiscount_XML) playercomm	
						WHERE gm.AgentId = @recommend AND gm.uGroup = @uGroup
					END	
					
					UPDATE cm
					SET cm.IsGroupComm = 0
					FROM dbo.CS_CustSettingMode cm WITH (ROWLOCK)
					WHERE cm.CustId = @CustID		
				END				
			END					
		END
	END
	ELSE
	BEGIN
		SELECT cs.sporttype, cs.bettype, cs.isLive, acs.ValueID
		INTO #CommMem_tmp
		FROM dbo.f_CS_GetDiscount_Member(@custid) cs--comm for member
			INNER JOIN dbo.f_CS_GetDiscount_Agent(@recommend) acs ON cs.SportType = acs.SportType AND cs.BetType = acs.BetType AND cs.IsLive = acs.IsLive	
			LEFT JOIN dbo.CS_GroupConfig gc WITH (NOLOCK) ON gc.SportType = acs.SportType AND gc.BetType = acs.BetType AND gc.IsLive = acs.IsLive AND gc.GroupId = acs.GroupId
		WHERE (gc.GroupName = @uGroup OR gc.GroupID is NULL)				
			AND cs.PlayerDiscount > acs.Discount
		
		IF @@ROWCOUNT = 0
			GOTO Update_uGroup
			
		SET @PlayerDiscount_XML =(
										SELECT (
												SELECT	bs.ByteOrder	AS '@pos',
														comm.ValueId	AS '@val'
												FROM #CommMem_tmp comm
													INNER JOIN dbo.CS_ByteSeq bs WITH (NOLOCK) ON bs.SportType = comm.SportType AND bs.BetType = comm.BetType AND bs.IsLive = comm.IsLive
												WHERE bs.Type = 'DiscountMember'
												FOR XML PATH('r')
													, TYPE
												)
										FOR XML PATH('root')
											, TYPE
										)
		
		UPDATE cm
		SET cm.PlayerDiscount = playercomm.binaryStr_new
		FROM dbo.CS_CustDiscount_Member cm WITH (ROWLOCK)
			CROSS APPLY dbo.f_SetBinaryValues(cm.PlayerDiscount, @PlayerDiscount_XML) playercomm	
		WHERE cm.CustId = @CustID
	END
	
Update_uGroup:
	UPDATE customer WITH(UPDLOCK,ROWLOCK)
	SET uGroup = @uGroup	
	WHERE custid = @custid
	
	declare @LogSPData varchar(5000)

	Select @LogSPData = '<CS_CustomerUserGroup_Upd UserName="'+ @username + '" From="' + @old_ugroup 
						+ '" To="' + @ugroup +'" '+
						'Userid="'+ coalesce(cast(@userid as varchar(50)),space(1)) + '" '+
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" '+
						'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
						'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" />'

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)
	
	EXEC dbo.CS_WriteLog_UserLog_RunSP_Wrapper
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 160013,
		@TrackingValue = @LogSPData,		
		@duration = @duration
END	
GO


