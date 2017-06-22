ALTER PROC [dbo].[Acc_VirtualRateMulDelTmpExcel]	
	@UserID INT,	
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT	
AS
/*
	Created: Simon
	Task : Delete All Data of table Acc_CustVirtualRate belong @UserID
	DB: DBACC/BODB_ACC
	Original: 
	
	Revisions:	
		- 20090812@Simon: Delete All Data of table Acc_CustVirtualRate belong @UserID
		- 20090918@Jamie: Check whether the user is existing or not before deteted 
		- 20091116@Daniel: Change to check permission on dedicated function [UploadVR]
		- 20130224@Lukas: move table SP to new database bodb_ACC
						& change linked-server from db03 to DBPOLICY
		- 20150126@Johnson: Separate virtual rate setting into sport types and bet types [Redmine: #25840]						
						+ Change to use new structure : table Ac_VirtualRateList						 
*/
SET NOCOUNT ON
		
	--Check permission for account site
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[UploadVR]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	IF EXISTS (SELECT 1 FROM dbo.Acc_VirtualRateList WHERE UserID=@UserID)
	BEGIN
		DELETE FROM dbo.Acc_VirtualRateList WHERE UserID=@UserID
		IF @@ERROR <> 0
		BEGIN
			SELECT	@ErrMsg = 'Delete process is unsuccessful.',
					@ErrCode = 103
			RETURN			
		END
	END

GO


GRANT EXECUTE ON [dbo].[Acc_VirtualRateMulDelTmpExcel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_VirtualRateMulDelTmpExcel] TO [vnteam]