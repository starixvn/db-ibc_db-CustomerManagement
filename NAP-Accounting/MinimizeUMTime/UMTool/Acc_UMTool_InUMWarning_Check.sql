/*<info serverAlias="DBGLOB-GlobCustDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_UMTool_InUMWarning_Check]
	 @ConfigID		INT
	,@IsInUM		INT = 0 OUTPUT
AS
BEGIN
/*
	Created: 20201002@Eden
	Task :  Check UM Time of the config when before submit delete
	DB: DBGLOB/GlobCustDB
	Revisions:	
		- 20201002@Eden: Minimize UM Time - Backend UM tool [Redmine: #142142]
		- 20250225@Johnson: move sp to GlobCustDB [redmine: #216870]
	Param's Explanation:   
		@IsInUM : 
			= 0 : Current time is greater than End Time 
			= 1 : Current time is less or equal to End Time (In UM)
		
	Examples :
		DECLARE @IsInUM INT = 0 
		EXEC [Acc_UMTool_InUMWarning_Check] 
			@ConfigID = 11,
			@IsInUM = @IsInUM OUT
		SELECT @IsInUM
		
*/
SET NOCOUNT ON	
	SELECT @IsInUM = CASE WHEN CONVERT(SMALLDATETIME,GETDATE()) BETWEEN BeginTime AND EndTime THEN 1 ELSE 0 END
	FROM UMConfig c WITH(NOLOCK) 
	WHERE c.ConfigID = @ConfigID
END
GO