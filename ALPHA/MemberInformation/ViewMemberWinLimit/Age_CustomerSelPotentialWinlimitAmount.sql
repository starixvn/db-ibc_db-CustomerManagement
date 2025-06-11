/*<info serverAlias="DBSIC-bodb02" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE	dbo.Age_CustomerSelPotentialWinlimitAmount					
				@custids			NVARCHAR(MAX)	= ''
AS
/*
	Create:	20250529@Razor
	Task:	Potential Member win limit
	DB:		DBSIC/bodb02

	Revisions:
		- 20250529@Razor:	Get Accum Amount of Member - [Redmine: #228570]
	
*/
BEGIN

	SET NOCOUNT ON
	DECLARE @tmpCustIds TABLE ( CustID INT )
	INSERT INTO @tmpCustIds ( CustID )
		SELECT CAST([value] AS INT) FROM STRING_SPLIT(@custids,',')

	SELECT c.CustId,
		AccumToWin,
		AccumWinLoss
	FROM CustWinLimitBet AS c WITH(NOLOCK)
	INNER JOIN @tmpCustIds AS t ON c.CustID = t.CustID
END
