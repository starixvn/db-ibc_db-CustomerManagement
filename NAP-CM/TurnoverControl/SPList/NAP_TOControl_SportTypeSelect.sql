/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_TOControl_SportTypeSelect]
(
	@Mode TINYINT = 0
	, @SportType SMALLINT = 0
	
)	
AS
/*
	Created: Don
	Date: 2017-03-27
	Task: Retrieve list of sports
	DB: DBAGE.bodb02

	Revisions:
			- 20171212@Helen: Implement some change request from OPS Team - [Redmine: 85638]
	Parameter's explaination: 
		@Mode	= 0: Sport of sportbook
				= 1: All sports
*/
BEGIN
	SET NOCOUNT ON

	SELECT DISTINCT s.sporttype, s.sportname 
	FROM dbo.sports s WITH(NOLOCK) 
	WHERE	1 = CASE  
					WHEN @Mode = 0 AND @SportType = 1  AND s.SportType = 1 THEN 1
					WHEN @Mode = 0 AND @SportType = 99 AND s.sporttype > 1 AND s.sporttype <= 99 THEN 1
					WHEN @Mode = 0 AND @SportType = 0  AND s.sporttype <= 99 THEN 1
					WHEN @Mode = 1 THEN 1
					ELSE 0 END			
					
	ORDER BY s.sporttype

END
GO
GRANT EXECUTE ON [dbo].[NAP_TOControl_SportTypeSelect] TO [bodbAdminNet]
GO