/*<info serverAlias="DBMSG-bodb_Message" executers="bodbDownlineNet,bodbDownlineNetView,bodbAdminNet,bodbExtAccNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_MsgCustReadStatus_Ins] @CustId INT
	,@SubAccId INT = 0
	,@RoleId INT = NULL
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: 20180621@Razor
	Task : Announcement Renovation
	DB: DBMSG.bodb_Message
	
	Revisions:
		- 20180621@Razor: Renovation Announcement [Redmind: #94705]
		- 20190904@Johnson: add headline roleid = 0 [redmine:#119153]
		- 20210618@Eden: Database - Migrate bodb_message to new server [#157216]
	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON
	
	IF(@RoleId IS NULL)
	BEGIN
		SELECT @RoleId = RoleId
		FROM DBACC.bodb02.dbo.custInfo WITH(NOLOCK)
		WHERE CustId = @CustId
		
		IF @@rowcount = 0 
		BEGIN
			SELECT @ErrMsg = 'Invalid customer.'
				,@ErrCode = 100
			RETURN;
		END
	END	
	
	IF(@RoleId IN (0,2,3,4))
	BEGIN
		BEGIN TRY
			INSERT INTO dbo.MsgCustReadStatus (
				CustId
				,SubAccId
				,LastSeenNormalMsg
				,LastSeenPersonalMsg
				,LastSeenSpecialMsg
				,LastSeenSystemUpdMsg
				)
			VALUES (
				@CustId
				,@SubAccId
				,GETDATE()
				,GETDATE()
				,GETDATE()
				,GETDATE()
				)
		END TRY

		BEGIN CATCH
			SELECT @ErrMsg = 'Error! Error when adding Message Customer Read Status.'
				,@ErrCode = 101
		END CATCH
	END	
END
GO


