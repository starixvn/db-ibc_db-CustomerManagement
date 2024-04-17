/*<info serverAlias="DBMSG-bodb_Message" executers="wsv_alp,wsv_alpv" viewers="vnteam" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Age_Msg_HasPriMessage24]
	@UserID int,
	@IsTest bit = 0
AS
/*
	Created: 20221121@Tacy
    Task: Alpha - Seperate SP get annoucement & void log spam
    DB: DBMSG-bodb_Message
    Original: Dot_Msg_HasPriMessage24

    Revisions:
			- 20221121@Tacy: Create SP

    Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON;
   
	declare @MessageID int
	declare @PostTime datetime
	--if exists
		SELECT top 1 @MessageID=m.MessageID,@PostTime=m.PostTime 
		FROM dbo.Msg m with (nolock , index = [PK_Msg])
		INNER JOIN dbo.MsgTarget mt with (nolock) ON m.MessageId = mt.MessageId and mt.TargetId=@UserID
		WHERE m.MsgType=1  
		AND m.isDeleted=0 AND mt.isDeleted=0
		--AND m.MessageId > 50000
		AND m.IsSticky = 0
		AND case @IsTest when 1 then 1
			when m.IsTest then 1
			end = 1
		--and m.posttime > dateadd(d,-1,getdate()) 
		ORDER BY m.PostTime DESC
		--set @MessageID = MessageID
	--else
	--	set @MessageID = 0

	if @@rowcount>0
		select @MessageID as MessageID, @PostTime as Posttime
	else
		select 0 as MessageID, null as PostTime
END
GO