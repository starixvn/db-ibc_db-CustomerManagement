ALTER PROCEDURE [dbo].[Age_MessageSelAll]
	@RoleID tinyint
AS

select top 25 mid, message_en, message_ch, postdate
from message_new with (nolock)
where (case @RoleID
		when 2 then agent
		when 3 then ma
		when 4 then sma		
		END = 1 OR member = 1) and IsSticky = 0
UNION ALL
select mid, message_en, message_ch, postdate
from message_new with (nolock)
where (case @RoleID
		when 2 then agent
		when 3 then ma
		when 4 then sma		
		END = 1 OR member = 1) and IsSticky = 1
order by mid desc
GO

GRANT EXECUTE ON [dbo].[Age_MessageSelAll] TO [bodbDownlineNet,wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Age_MessageSelAll] TO [bodbDownlineNetView,wsv_alpv]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_MessageSelAll] TO vnteam

