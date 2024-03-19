/*<info serverAlias="DBMSG-bodb_Message" executers="bodbExtAccNet,wsv_xnap,bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv,bodbAdminNet,wsv_nap" viewers="vnteam" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Age_Msg_SetUsrMessage]
	@MessageId int,
	@TargetId int,
	@TargetName nvarchar(50) = '',
	@isRead bit = 0,
	@BetTransId varchar(max) = '',
	@PostTime DATETIME = NULL ,
	@Creator INT =0
AS
/*	
	Created: 20221121@Tacy
    Task: Alpha - Seperate SP get annoucement & void log spam
    DB: DBMSG-bodb_Message
    Original: Dot_Msg_SetUsrMessage

    Revisions:
			- 20221121@Tacy: Create SP
			- 20231101@Bobby: Enhance TransferOption config [RedmineID: #195135]
*/

BEGIN
	IF EXISTS (SELECT MessageId FROM dbo.Msg with (nolock) WHERE MessageId = @MessageId)
	BEGIN
		IF EXISTS (SELECT MessageId FROM dbo.MsgTarget with (nolock) WHERE MessageId = @MessageId AND TargetId = @TargetId)
			BEGIN
				-- update
				UPDATE dbo.MsgTarget WITH (rowlock,updlock)
				SET	TargetName = @TargetName, BetTransId = @BetTransId, isDeleted = 0
				WHERE MessageId = @MessageId 
					AND TargetId = @TargetId
			END
		ELSE
			BEGIN
				-- insert
				INSERT dbo.MsgTarget(MessageId, TargetId, TargetName, isRead, BetTransId ,PostTime) --messagetype: for old version
				VALUES (@MessageId, @TargetId, @TargetName, @isRead, @BetTransId ,@PostTime)
			END
	END
END
GO