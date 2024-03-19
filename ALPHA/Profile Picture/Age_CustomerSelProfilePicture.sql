/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/

CREATE PROCEDURE [dbo].[Age_CustomerSelProfilePicture]
	@CustId INT
AS
/*

	Created by: Kathy
	Date: 20131114
	Task: Customer profile picture [Redmine:#7547]
	DB: DBAGE/bodb02

	Revisions:
		- 20181123@Helen: DB053.bodb_AGE/BODB02 & DB052.bodb_Summary Migration [Redmine: 104770]
		- 20191003@Elodie: Force user to use profile picture [Redmine: #120726]
		- 20230523@Helios: Migrate SP FROM bodb_Age TO bodb02 [Redmine: #186502] 
	Parameter's Explanation:


*/
BEGIN
	SET NOCOUNT ON

	SELECT p.image, cp.ImageId, cp.modified
	FROM CustProfilePicture cp WITH(NOLOCK)
		INNER JOIN dbo.ProfilePicture p WITH(NOLOCK) ON p.ImageId = cp.ImageId
	WHERE custid = @CustId
		AND cp.IsDeleted = 0
	AND p.IsDeleted = 0
END
GO


