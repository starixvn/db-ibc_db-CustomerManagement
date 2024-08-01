/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap, wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ExchangeSel]
	@UserID INT = NULL,
	@System varchar(50) = 'ACCOUNTING',
	@IsTest BIT = 0 ,
	@Mode	tinyint = 0,	 -- 0: All, 1 : Credit, 2 :Deposit
	@DeniedList NVARCHAR(MAX)=NULL
AS
/*
	DB: DBCUST/CUSTDB
	Original: member/addmaster.asp

	Revisions:
		- 20090526@Phuc: get allowed HR currency from f_GetHRAllowedCurr
		- 20100720@Shifu: get system name
		- 20111020@Johnson: remove currency C and H from result
		- 20160620@Elodie: Add parameter @IsTest for testing purpose
		- 20200826@Winfred: Hide Inactive , OfferSite Currency [Redmine: #140084]
		- 20240419@Tacy: NAP - Permission controls on real currency [redmineID: #202523]

*/
BEGIN
	SET NOCOUNT ON

	IF(@System = 'ACCOUNTING')
	BEGIN
		DECLARE @tmpExchange TABLE (exchangeID INT, Currency NVARCHAR(50), OfferSite TINYINT)

		--get deny currency
		IF ISNULL(@DeniedList,'')<>''
		BEGIN
			INSERT INTO  @tmpExchange (exchangeID, Currency, OfferSite)
			SELECT vl.[ID], vl.[Name], vl.[Opt]
			FROM OPENJSON(@DeniedList) 
					WITH (  [KeyName]	VARCHAR(30),
							[Value]	NVARCHAR(MAX) AS JSON
						) AS js
			CROSS APPLY OPENJSON (js.[value])
					WITH (  [ID]	INT,
							[Name]	NVARCHAR(30),
							[Opt]	TINYINT
						) AS vl
			WHERE js.[KeyName]='Exchange'
		END


		select 
			ExchangeID, Currency,
			case when currency IN(select currency from dbo.[f_GetHRAllowedCurr]()) then 1 else 0 end HRAllowed
		from 
			exchange with (NOLOCK)
		WHERE ((@IsTest = 0 AND exchangeID NOT IN (27,28)) OR @IsTest = 1)
			AND (@Mode = 0 OR (@Mode  = 1 AND OfferSite in (0,1)))
			AND IsActive = 1
			AND (@Userid IS NULL 
				OR (@Userid IS NOT NULL AND ExchangeId NOT IN (SELECT exchangeID FROM @tmpExchange)))
		ORDER BY 
			currency
	END
	ELSE
	BEGIN
		SELECT 
			ExchangeID, Currency,
			case when currency IN(select currency from dbo.[f_GetHRAllowedCurr]()) then 1 else 0 end HRAllowed
		FROM 
			exchange with (NOLOCK)
		WHERE ExchangeID IN (SELECT exchangeID 
							FROM dbo.f_CurrencyBySystem(@System)) 
				AND ExchangeID NOT IN (27,28)
				AND (@Mode = 0 OR (@Mode  = 1 AND  IsActive = 1 AND OfferSite in (0,1)) 	)
		ORDER BY 
			currency
	END
END
GO