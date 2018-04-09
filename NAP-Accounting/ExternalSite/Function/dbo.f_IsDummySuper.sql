ALTER FUNCTION [dbo].[f_IsDummySuper]
(
	@CustID int
)
RETURNS BIT
/*  Created:20100521@Henry
    Task: Check whether custid is dummy super
    DB: DB05/DB06.BODB02

*/
AS
BEGIN
	DECLARE @ReturnVal as BIT
	
	IF EXISTS 
		(SELECT 1 FROM
			(	SELECT custid
				FROM custinfo WITH(NOLOCK)
				WHERE 
					(
					username LIKE '3rdSuper%'  
					OR username LIKE '12ACCSuper%'
					OR username LIKE 'MS88ACCSuper%'
					OR username LIKE 'AB88ACCSuper%'
					OR username LIKE 'ALogACCSuper%'
					OR username LIKE 'STEST%' 
					)
					AND roleid = 4
			) A
			WHERE A.custid = @CustID
		)
	BEGIN
		SET @ReturnVal = 1
	END
	ELSE
		SET @ReturnVal = 0
	
	RETURN @ReturnVal
END
GO
GRANT EXECUTE ON [dbo].[f_IsDummySuper] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[f_IsDummySuper] TO [vnteam]