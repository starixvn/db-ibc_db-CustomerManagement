/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE NAP_SMATurnoverGlobalSettingSel
	@UserName NVARCHAR(30)=''
AS
BEGIN
	SET NOCOUNT ON;
	SELECT ci.UserName,
		CASE ci.RoleID WHEN  4 THEN 'Super' WHEN 3 THEN 'Master' WHEN 2 THEN 'Agent' END [Level],
		ex.Currency,
		gst.MaxTurnover,
		gst.CustID
	FROM DownlineTurnOver_GlobalSetting gst WITH(NOLOCK) 
	INNER JOIN CustInfo ci WITH(NOLOCK) ON ci.CustID = gst.CustID
	INNER JOIN Exchange ex WITH(NOLOCK) ON ex.exchangeid = ci.currency
	WHERE (ISNULL(@UserName,'')='' OR ci.Username=@UserName)
END

