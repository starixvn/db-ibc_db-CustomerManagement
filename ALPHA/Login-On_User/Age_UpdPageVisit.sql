
ALTER PROCEDURE [dbo].[Age_UpdPageVisit]
	@pageURL varchar(50),
	@role	tinyint
AS
-- =============================================
-- Author:		<Phuong Doan>
-- Create date: <2008 Jul 12>
-- Description:	Update agent page visit record
-- =============================================
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	if @role = 2
	begin
		update Age_PageVisit set AgVisits = AgVisits + 1
		where pageURL=@pageURL
	end
	else if @role=3
	begin
		update Age_PageVisit set MAgVisits = MAgVisits + 1
		where pageURL=@pageURL
	end	
	else if @role=4
	begin
		update Age_PageVisit set SAgVisits = SAgVisits + 1
		where pageURL=@pageURL
	end
	else
		return
	
	if not exists(select 1 from Age_PageVisit (nolock) where pageURL=@pageURL)
	BEGIN
		Insert into Age_PageVisit
		select @pageURL,
				case @role when 2 then 1 else 0 end,
				case @role when 3 then 1 else 0 end,
				case @role when 4 then 1 else 0 end
	END
END

GO
GRANT EXECUTE ON [dbo].[Age_UpdPageVisit] TO [wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Age_UpdPageVisit] TO [wsv_alpv]
GO