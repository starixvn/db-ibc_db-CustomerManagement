/*	
	Created: 20170407@Elodie
	Task: Initialize data for TO Control setting
	DB: DBAGE/bodb02
*/

USE bodb02
GO

WHILE EXISTS (SELECT TOP 1 1 FROM Queue_TOControl_DBAGE WITH (NOLOCK))
BEGIN
	EXEC TOControl_ProcessData
END

GO
DELETE FROM TOControl_Transition

GO
UPDATE TOConTrol_GlobalVariables
SET VValue = '0'
WHERE VName = 'MaxID'