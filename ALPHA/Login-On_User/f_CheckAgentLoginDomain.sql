ALTER FUNCTION [dbo].[f_CheckAgentLoginDomain]
(
	@site varchar(10),
	@LoginDomain varchar(50) = ''
)

/*
Created by: [Lee@20100507]
Task: Check matching between @site and @LoginDomain
DB: DBTRANS.bodb02
	
Param's Explanation 
	+ @Site: alog, ispo...
	
Note: This function is used in:
	+ Agent site, login function

Revisions:
    + 20100824: revise the function to separate domains for all licensees.
	+ 20101027@Thien: add TLC site
	+ 20101105@Henry: add DELA and Spondemo site
	- 20110120@Johnson: Add Zzun88, Suncity, MayFair site
	- 20110224@Henry: Add Bezbet site
	- 20110801@Henry: Add Haifa site
*/
RETURNS bit
AS
BEGIN
declare @IsMatched bit

select  @IsMatched =
case
	--Thien@20100820: ALLOW ALL UNTIL 1ST SEP 2010
	--when @site in ('12Bet', 'asiabet88', 'mansion88', 'alog', 'ispo') then 1
	
	---------------------------------
	when @site in ('12Bet', 'asiabet88', 'mansion88', 'alog', 'TLC','DELA','Spondemo','Zzun88','SunCity','MayFair','Bezbet','Haifa')
		and @LoginDomain in ('www.006660.com', 'ag.006660.com', 'www.006660.net', 'ag.006660.net') then 1
		--and @LoginDomain in ('www.006660.com', 'ag.006660.com', 'www.006660.net', 'ag.006660.net', 'intagent.ibc88.com') then 1
	
	--ispo888
	when @site = 'ispo' and @LoginDomain in ('ag.ispo888.com', 'ag.ispo888.net') then 1
	
	--IBC's agents (other sites)
	when @site NOT in ('12Bet', 'asiabet88', 'mansion88', 'alog', 'ispo', 'TLC','DELA','Spondemo','Zzun88','SunCity','MayFair','Bezbet','Haifa')
	    AND @LoginDomain NOT IN ('www.006660.com', 'ag.006660.com', 'www.006660.net', 'ag.006660.net', 'ag.ispo888.com', 'ag.ispo888.net') then 1
	else 0

END

return @IsMatched

END


GO
GRANT EXECUTE ON [dbo].[f_CheckAgentLoginDomain] TO [bodbDownlineNet,wsv_alp]
GO
GRANT EXECUTE ON [dbo].[f_CheckAgentLoginDomain] TO [bodbDownlineNetView,wsv_alpv]
GO
GRANT VIEW DEFINITION ON [dbo].[f_CheckAgentLoginDomain] TO [vnteam]