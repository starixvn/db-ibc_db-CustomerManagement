ALTER PROCEDURE [dbo].[Acc_VirtualRateMulSelCheck]	
	@UserID INT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: 
	Task : Check data on Acc_CustVirtualRate
	DB: DBACC/BODB_ACC
	Original: 
	Revisions:	
		- 20090812@Simon: Check data on Acc_CustVirtualRate
		- 20091116@Daniel: Change to check permission on dedicated function [UploadVR]
		- 20100112@Simon: improve performance by using @tmpExistUser table to check exist in the system.
		- 20130224@Lukas: move sp to new database bodb_ACC
						& change linked-server from db03 to DBPOLICY
		- 20131203@Elodie: Expand size of string	
		- 20150126@Johnson: Separate virtual rate setting into sport types and bet types [Redmine: #25840]						
						+ Change to use new structure : table Ac_VirtualRateList						 						
	
*/
BEGIN
SET NOCOUNT ON
		
	--Check permission for account site
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[UploadVR]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	
	DECLARE @tmpFail TABLE (
		UserName	NVARCHAR(50),
		Reason		NVARCHAR(80)
	)

	-- The table contents username exist in custinfo
	DECLARE @tmpExistUser TABLE (
		UserName	NVARCHAR(50) PRIMARY KEY
	)
	INSERT INTO @tmpExistUser
	SELECT 	v.UserName
	FROM	dbo.Acc_VirtualRateList v WITH (NOLOCK) 
			INNER JOIN bodb02.dbo.custinfo c WITH (NOLOCK) ON c.username=v.username
	WHERE	v.userID = @userID
	GROUP BY v.UserName


	INSERT INTO @tmpFail		
	SELECT	t.username,
			'This username does not exist in the system.' AS reason 
	FROM	
	(
			SELECT	username FROM dbo.Acc_VirtualRateList WITH (NOLOCK) WHERE	UserID=@UserID 
			EXCEPT (
				SELECT	UserName
				FROM	@tmpExistUser
			)
		) t
	
	DELETE FROM dbo.Acc_VirtualRateList WHERE userid = @userid AND username IN (SELECT username FROM @tmpFail)
	
	SELECT * FROM dbo.Acc_VirtualRateList WITH (NOLOCK) 
	WHERE	UserID=@UserID 
	ORDER BY username

	SELECT username, '-' AS virtualrate, reason FROM @tmpFail 

END

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_VirtualRateMulSelCheck] TO [vnteam] AS [dbo]