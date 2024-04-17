ALTER PROCEDURE [dbo].[Age_MessageSelOne]
	@RoleID tinyint
AS

select top 1 mid, message_en, message_ch, IsSticky
from message_new with(nolock)
where (case @RoleID
		when 2 then agent
		when 3 then ma
		when 4 then sma		
		END = 1 OR member = 1)
order by mid desc

GO

GRANT EXECUTE ON [dbo].[Age_MessageSelOne] TO [wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Age_MessageSelOne] TO [bodbDownlineNetView,wsv_alpv]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_MessageSelOne] TO vnteam
