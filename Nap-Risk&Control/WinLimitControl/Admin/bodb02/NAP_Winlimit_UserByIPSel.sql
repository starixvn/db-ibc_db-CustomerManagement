/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_Winlimit_UserByIPSel] @IP VARCHAR(50) = ''
AS

/*
	Created: Franklin	
	Date: 2016-06-22
	Task: #57722 - Implement Game Win Limit Control phase2
	DB: DBACC/bodb02
	Revisions:
		- 20160923@Jacob: Risk & Control - Phase 3 [#61220].
		- 20210311@Winfred: add default value for @IP [#151512].
	Parameters Explanation:
	Eample:
	EXEC [NAP_Winlimit_UserByIPSel] @IP = '127.0.0.1'
*/

     SET NOCOUNT ON;
     DECLARE @Today SMALLDATETIME;
     SELECT @Today = CONVERT( DATE, GETDATE());
     SELECT DISTINCT
            CustId,
            winlostdate LastAccessedDate,
            @IP AS IP
     FROM dbo.bettrans AS b WITH (NOLOCK)
     WHERE winlostdate = @Today
           AND ip = @IP
           AND bettype <= 19000;
GO