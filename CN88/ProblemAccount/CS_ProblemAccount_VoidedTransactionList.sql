/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[CS_ProblemAccount_VoidedTransactionList]
	@CustId		INT
	,@FromDate	DATETIME
	,@ToDate	DATETIME
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

	SELECT t.CreatedDate, t.TransId, r.ReasonEnglish
	FROM dbo.TicketVoiding_VoidedTransaction t WITH (NOLOCK)
		INNER JOIN dbo.TicketVoiding_Reason r WITH (NOLOCK) ON t.ReasonId = r.ReasonId
	WHERE t.CreatedDate BETWEEN @FromDate AND @ToDate
		AND t.CustID = @CustId
END
GO