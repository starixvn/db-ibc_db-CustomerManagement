/*
	Created: 20180626@Helen
	Task: Tunning trigger 
	DB: DB054/bodb02
*/
USE bodb02
GO
CREATE TABLE TOControl_Tickets 
(	rowid BIGINT IDENTITY (1,1) 
	, transid BIGINT
)
GO
CREATE CLUSTERED INDEX [CIX_TOControl_Tickets] ON [dbo].[TOControl_Tickets]
(
	[RowId] ASC
)
GO


CREATE TABLE TOControl_TicketDetails 
(	
	  rowid INT
	, transid BIGINT
	, statusID TINYINT
	, bettype SMALLINT
)
GO
CREATE CLUSTERED INDEX [CIX_TOControl_TicketDetails] ON [dbo].[TOControl_TicketDetails]
(
	[RowId], transid
)
GO
CREATE TABLE [dbo].[TOControl_Tickets_Setting](
	[sKey] [varchar](30) NOT NULL,
	[sValue] [bigint] NOT NULL
) ON [PRIMARY]

GO
CREATE UNIQUE CLUSTERED INDEX [CIX_TOControl_Tickets_setting] ON [dbo].[TOControl_Tickets_Setting]
(
	[sKey] ASC
)
GO
INSERT INTO TOControl_Tickets_Setting (sKey,sValue) VALUES ('TOControl_Insert',0)
GO
