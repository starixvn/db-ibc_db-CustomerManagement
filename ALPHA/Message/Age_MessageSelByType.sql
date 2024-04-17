set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_MessageSelByType]
	@RoleID		tinyint,
	@Fdate		datetime,
	@Tdate		datetime,
	@Type		nvarchar(20) = null,
	@First      nvarchar(20) = '' OUTPUT
AS
    /*
    Created: 20090113@AnhPham
    Task: get the messages by type and time range
    DB: DB03.On_User
    Original:
    
    Revisions:
    
    Param's Explanation:
        .@RoleID: role of agent or master or super log in the system
        .@Fdate: start date
        .@Tdate: end date
        .@Type: type of message (NORMAL, SPECIAL, FIRST)
    
    */
    
	IF (@Type = 'SPECIAL')
	BEGIN
		SELECT TOP 25 mid, message_en, message_ch, postdate
		FROM message_new WITH (NOLOCK)
		WHERE	(
					CASE @RoleID
						WHEN 2 THEN agent
						WHEN 3 THEN ma
						WHEN 4 THEN sma		
					END = 1 OR member = 1
				) 
				AND IsSticky = 1
		ORDER BY mid DESC
	END
	
	IF (@Type = 'NORMAL')
	BEGIN
		SELECT TOP 25 mid, message_en, message_ch, postdate
		FROM message_new WITH (NOLOCK)
		WHERE	(
					CASE @RoleID
						WHEN 2 THEN agent
						WHEN 3 THEN ma
						WHEN 4 THEN sma		
					END = 1 OR member = 1
				)
				AND IsSticky = 0 
				AND convert(varchar(8), postdate, 112) BETWEEN convert(varchar(8), @Fdate, 112) AND convert(varchar(8), @Tdate, 112)
		ORDER BY mid DESC
	END
	
GO

GRANT EXECUTE ON [dbo].[Age_MessageSelByType] TO [wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Age_MessageSelByType] TO [wsv_alpv]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_MessageSelByType] TO [vnteam]
GO
