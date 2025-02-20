/*<info serverAlias="DBGLOB-GlobCustDB" executers="wsv_nap,wsv_xnap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE  [dbo].[Acc_SuperPrefixByGroupSel]
	@GroupName	VARCHAR(50) = NULL,
	@Prefix		VARCHAR(10)	= NULL,
	@AllowNewSuper BIT = NULL
AS

/*
	Created: 20200511@Johnson	
	Task: Select the list super/master of Acc_CustGroup
	DB: DBGLOB-GlobCustDB
	
	Revisions:
		- 20200511@Johnson: initial sp [redmine:#133846]
		- 20201008@Winfred : New Super - Prefix Warning [Redmine: #142239]
		- 20250226@Johnson: move sp to GlobCustDB [redmine: #216870]
*/
BEGIN
	SET NOCOUNT ON
	
	SELECT GroupName, Prefix, AllowNewSuper
	FROM Acc_SuperPrefix WITH(NOLOCK)
	WHERE GroupName = ISNULL(@GroupName,GroupName)
		AND Prefix = ISNULL(@Prefix,Prefix)
		AND AllowNewSuper = ISNULL(@AllowNewSuper,AllowNewSuper)
	ORDER BY GroupName, Prefix ASC
END	