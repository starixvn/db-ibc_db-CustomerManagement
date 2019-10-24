/*<info serverAlias="DBAGE-BODB02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Age_CustomerProfilePictureSuggest]
	@CustId INT,
	@Mode TINYINT
AS
/*
	Created by: Elodie
	Date: 20191003
	Task: Suggest picture library [Redmine:#120726]
	DB: DBAGE/BODB02 	

	Revisions:
		- 20191003@Elodie: Initial SP
		
	Parameter's Explanation:

*/
BEGIN
	SET NOCOUNT ON

	SELECT p.ImageId, p.image
	FROM Age_CustProfilePicture cp WITH(NOLOCK)
		INNER JOIN Age_ProfilePicture p WITH (NOLOCK) ON cp.ImageId = p.ImageId
	WHERE custid = @CustId
	UNION ALL
	SELECT ImageId, Image
	FROM Age_ProfilePicture WITH(NOLOCK)
	WHERE ImageId IN (	SELECT CAST(RAND()*200+1 AS INT) + @Mode * 10000
						UNION ALL 				 
						SELECT CAST(RAND()*200+1 AS INT) + @Mode * 10000
						UNION ALL 		    	
						SELECT CAST(RAND()*200+1 AS INT) + @Mode * 10000
						UNION ALL 		    	 
						SELECT CAST(RAND()*200+1 AS INT) + @Mode * 10000
						)
END
GO


