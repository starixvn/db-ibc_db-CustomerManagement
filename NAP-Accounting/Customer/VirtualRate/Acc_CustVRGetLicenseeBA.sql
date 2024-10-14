/*<info serverAlias="DBLIC-bodb_licensee" executers="wsv_nap" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_CustVRGetLicenseeBA]  
AS  
/*  
	Created:	20240701@Winfred
	Task:		Scale Out DBCUST - Apply In-house Replication for Virtual Rate Setting
	DB:			DBLIC/bodb_Licensee
	Original:  
  
	Revisions: 
		- 20240701@Winfred: Scale Out DBCUST - Apply In-house Replication for Virtual Rate Setting [redmine: #207029]

	Result Explanation:  
		- Output -> @JsonBACust : Json Type
		'[  { "CustID": "1111" }, { "CustID": "2222" }, { "CustID": "3333" }, { "CustID": "4444" },
			{ "CustID": "5555" }, { "CustID": "6666" }, { "CustID": "7777" }, { "CustID": "9999" }
		]'
*/  
BEGIN  
	SET NOCOUNT ON;  
	
	SELECT DISTINCT CustID
	FROM dbo.[LicenseeBAHistory] ba WITH (NOLOCK)
	WHERE ba.Status = 'Running'
	ORDER by CustID
	
END

GO