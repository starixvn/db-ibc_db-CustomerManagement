
/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/

CREATE PROCEDURE	[dbo].[Acc_VirtualMultiplierList_Sel]
AS
/*    
	Created: 20190626@Dominic    
	Task :  Query a list of supported VR values  [Redmind: #114830]
	DB: DBCUST/CustDB    
	    
	Revisions:    
		- 20190626@Dominic : First commit
		- 20191016@Louis : #121875 - Minor Changes
  
*/ 
BEGIN
	SELECT ValueID, CASE WHEN ValueID = 0 THEN NULL 
								ELSE Value
							END Value
				, CASE WHEN ValueID = 0 THEN NULL 
					ELSE (Value - 1.0) * 100
				END DisplayValue
	FROM [dbo].[VRValueMapping] (NOLOCK)
	ORDER BY CASE 
		WHEN ValueID = 0 THEN -100001 
		WHEN Value = 1 THEN -100000 
		ELSE Value END ASC
END