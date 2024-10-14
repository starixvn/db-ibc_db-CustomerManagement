/*<info serverAlias="DBTXN-bodb02" executers="wsv_nap" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_CustomerVRGetSportBettype]  
AS  
/*  
	Created:	20240701@Winfred
	Task:		Scale Out DBCUST - Apply In-house Replication for Virtual Rate Setting
	DB:			DBTXN/bodb02
	Original:  
  
	Revisions: 
		- 20240701@Winfred: Scale Out DBCUST - Apply In-house Replication for Virtual Rate Setting [redmine: #207029]

	Result Explanation:  
		- Output -> @JsonSportList : Json Type
		'[  { "Sporttype": "1" }, { "Sporttype": "2" }, { "Sporttype": "43" }, { "Sporttype": "99" },
			{ "Sporttype": "5" }, { "Sporttype": "8" }, { "Sporttype": "9901" }, { "Sporttype": "9902" }
		]'
*/  
BEGIN  
	SET NOCOUNT ON;  
	
	SELECT DISTINCT r.Sporttype 
	FROM dbo.Sport_Bettype_Reference_VirtualRate r WITH(NOLOCK)
	
END

GO