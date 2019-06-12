/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet,bodbExtAccNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROC [Acc_SiteSel_Credit]
AS

/*
Created by: Scott
Date: 2012-11-20
Task : GET active CREDIT sites
DB: DB053.BODB02
Original SP: [Acc_SiteSel] 
Revisions:
	 - 20190528@Winnie: NAP - Support CN88 Headline RedmineID: #112999
*/

SET NOCOUNT ON  

select [siteid], [site] 
from [site]  with(nolock)
where islicensee = 0  AND isactive=1
AND [siteid]<>329
GO


GRANT EXECUTE ON [dbo].[Acc_SiteSel_Credit] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_SiteSel_Credit] TO [bodbExtAccNet]


