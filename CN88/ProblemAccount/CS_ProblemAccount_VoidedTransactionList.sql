/*<info serverAlias="DBACC-bodb02" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[CS_ProblemAccount_VoidedTransactionList]
	@CustId		INT
	,@FromDate	DATETIME
	,@ToDate	DATETIME
	,@PageIndex	INT = 1
	,@PageSize	INT = 50
	,@TotalRows	INT = 0 OUTPUT
AS

/*
	Created: 20190822@Percy
	DB: DBAGE.bodb02
	Task: Customer Management - CN88 - Problem Account - Voided Transaction List

	Revisions:
		- 20190822@Percy: Initialize SP [RedmineID: #116814]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @RowStart INT, @RowEnd INT

	SELECT  @RowStart	= @PageSize * (@PageIndex - 1) + 1
			,@RowEnd	= @RowStart + @PageSize - 1

	SELECT @TotalRows = COUNT(1)
	FROM dbo.TicketVoiding_VoidedTransaction t WITH (NOLOCK)
		INNER JOIN dbo.TicketVoiding_SubIssueType s WITH (NOLOCK) ON t.SubIssueTypeID = s.SubIssueTypeID
	WHERE t.CreatedDate BETWEEN @FromDate AND @ToDate
		AND t.CustID = @CustId
		AND t.IssueTypeId = 11 -- Abnormal Bets

	SELECT CreatedDate, TransId, AbnormalReason
	FROM (
		SELECT t.CreatedDate, t.TransId, s.SubIssueTypeName AS AbnormalReason, ROW_NUMBER() OVER(ORDER BY t.CreatedDate DESC) AS RowNum
		FROM dbo.TicketVoiding_VoidedTransaction t WITH (NOLOCK)
			INNER JOIN dbo.TicketVoiding_SubIssueType s WITH (NOLOCK) ON t.SubIssueTypeID = s.SubIssueTypeID
		WHERE t.CreatedDate BETWEEN @FromDate AND @ToDate
			AND t.CustID = @CustId
			AND t.IssueTypeId = 11 -- Abnormal Bets
	) AS A
	WHERE A.RowNum BETWEEN @RowStart AND @RowEnd
	ORDER BY A.RowNum
END
GO