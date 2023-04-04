/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet,bodbExtAccNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROC [Acc_SiteSel_Credit]
	@Mode INT = 0
AS

/*
Created by: Scott
Date: 2012-11-20
Task : GET active CREDIT sites
DB: DB053.BODB02
Original SP: [Acc_SiteSel] 
Revisions:
	Parameter's explaination: @Mode  = 0: No sites CN88 and isActive = 1
									 = 1: All Site
	 - 20190528@Winnie: NAP - Support CN88 Headline RedmineID: #112999
	 - 20200629@Winfred: NAP - Get site by cansee RedmineID: #131241	 
	 - 20221808@Elodie: Get SiteDBGroupID [RedmineID: #158293]
	 - 20230110@Tacy: Alpha/NAP - Split 789y Site [RedmineID: #181596]
*/
BEGIN
	SET NOCOUNT ON  

	select SiteLabel, [siteid], [site] 
	from [site]  with(nolock)
	where islicensee = 0  AND (
	(@Mode = 1 AND isactive=1) OR (@Mode = 0 AND isactive=1 AND [siteid]<>329))
END
GO
