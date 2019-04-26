USE [bodb_Message]
GO

ALTER PROCEDURE [dbo].[Dot_Msg_SetMessage]
	@MessageId int = NULL,
	@Content_en	nvarchar(4000) = NULL,
	@Content_ch	nvarchar(4000) = NULL,
	@Content_cs	nvarchar(4000) = NULL,
	@Content_jp	nvarchar(4000) = NULL,
	@Content_it	nvarchar(4000) = NULL,
	@Content_th	nvarchar(4000) = NULL,
	@Content_ko nvarchar(4000) = NULL,
	@Content_es nvarchar(4000) = NULL,
	@Content_vn nvarchar(4000) = NULL,
	@Content_id nvarchar(4000) = NULL,
	@content_el nvarchar(4000) = NULL,
	@content_mx nvarchar(4000) = NULL,
	@Content_zhcn nvarchar(4000) = NULL,
	@MsgType int = 3,
	@IsSticky bit = 0,
	@Creator int = 0,
	@CreatorName nvarchar(50),
	@IsTest bit = 0,
	@MatchId int = 0,
	@IsBatch bit = 0,
	@MsgContentsType tinyint = 0,
	@BetTransId varchar(2000) = NULL, -- remove when admin lanuch batchmessage
	@MessageIDOutput INT = NULL OUTPUT
	/*	
	Created by: VinhTruong
	Task : insert/update special and normal message
	DB: DBMSG/bodb_Message
	Original: 20090910@KhoaTran: update sp follow new structure design

	Revisions:
		- 20110804@Jamie: Put @MsgContentsType to identify normal message or changed settings message
		- 20180914@Alan: Support New Chinese Simplified Language [101082]

	Param's Explanation:
		@MessageId: MessageId of a message
		@Content_en : English Message Content 
		@Content_ch : Tridional Chinese Message Content 
		@Content_cs : Simple Chinese Message Content 
		@Content_jp : Japanese Message Content 
		@Content_it : Italian Message Content 
		@Content_th : Thai Message Content 
		@Content_ko : Korean Message Content 
		@Content_es : Spanish Message Content 
		@Content_vn : Vinam Message Content 
		@Content_id : Indonisia Message Content 
		@Content_el : Greece Message Content 
		@Content_zhcn: New Chinese Simplified MessageContent
		@MsgType    : 
		= 1 : message to customer (personal)
		= 3 : message to indicate site (refer to table MsgSite and MsgTarget.targetid) 
		@IsSticky   : Is special Message or not 
		@Creator    : Creator ID 
		@CreatorName: Creator Name 
		@IsTest     : Is test or not 
		@MatchId    : matchid of a match
		@IsBatch    : 
		= 0 : normal message (no need to replace the symbol @@ by transid when display)
		= 1 : special message (need to replace the symbol @@ by transid when display)
	*/

AS
SET NOCOUNT ON
BEGIN
	IF EXISTS (SELECT MessageId FROM dbo.Msg with (nolock) WHERE MessageId = @MessageId)
	BEGIN
		-- update
		UPDATE dbo.Msg WITH (rowlock,updlock)
		SET
			Content_ch = @Content_ch,
			Content_cs = @Content_cs,
			Content_it = @Content_it,
			Content_jp = @Content_jp,
			Content_th = @Content_th,
			Content_en = @Content_en,
			Content_ko = @Content_ko,
			Content_es = @Content_es,
			Content_vn = @Content_vn,
			Content_id = @Content_id,
			Content_el = @Content_el,
			Content_mx = @Content_mx,
			Content_zhcn = @Content_zhcn,
			--PostTime = getdate(),
			LastUpdateTime = getdate(),
			MsgType = @MsgType,
			IsSticky = @IsSticky,
			LastUpdator = @Creator,
			LastUpdateName = @CreatorName,
			IsTest = @IsTest,
			MatchId = @MatchId,
			IsBatch = @IsBatch,
			MsgContentsType = @MsgContentsType --set default values Normal Data 
		WHERE MessageId = @MessageId;
		SELECT @MessageIDOutput = @MessageId
		SELECT @MessageID AS MessageId;
	END
	ELSE
	BEGIN
		-- insert
		INSERT dbo.Msg (Content_ch, Content_it, Content_cs, Content_jp, Content_th,
						Content_en, Content_ko, Content_es, Content_vn, Content_id,
						Content_el, Content_mx, Content_zhcn,
						MsgType, IsSticky, Creator, CreatorName, MatchId,
						LastUpdator, LastUpdateName, CreateTime, LastUpdateTime, PostTime, IsTest,
						IsBatch,
						MsgContentsType
						) 
		VALUES(@Content_ch, @Content_it, @Content_cs, @Content_jp, @Content_th, 
  			   @Content_en, @Content_ko, @Content_es, @Content_vn, @Content_id,
			   @Content_el, @Content_mx, @Content_zhcn,
			   @MsgType, @IsSticky, @Creator, @CreatorName, @MatchId,
			   @Creator, @CreatorName, getdate(), getdate(), getdate(), @IsTest,
			   @IsBatch,
			   @MsgContentsType
				);
		
		SELECT @MessageId = SCOPE_IDENTITY();

		SELECT @MessageIDOutput = @MessageId
		SELECT @MessageId AS MessageId;
	END
END

GO
GRANT EXECUTE ON [dbo].[Dot_Msg_SetMessage] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Dot_Msg_SetMessage] TO [Dot_Admin]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Msg_SetMessage] TO [vnteam]