--@DBPRO/DB02
USE bodb02
GO
ALTER TABLE dbo.Products
ADD ProductType TINYINT DEFAULT(0) --0: sportsbook, 1: Racing, 2: Gaming
go
 
--@DBPRO/DBTRANS
use bodb02
go
CREATE TABLE dbo.WinLimit_GlobalSetting
(
    ProductID       TINYINT NOT NULL
    ,ExchangeID     INT NOT NULL
    ,MaxWinLimit    MONEY NULL
) ON [DATA]
GO
 
--@DBTXN/DBCUST
USE CustDB
GO
CREATE TABLE dbo.WinLimit_CustSetting
(
    CustID          INT NOT NULL
    ,ProductID      TINYINT NOT NULL
    ,MaxWinLimit    MONEY NULL
) ON [DATA]
GO
 
--@DBTXN/DBTRANS
USE bodb02
GO
CREATE TABLE dbo.WinLimit_Game
(
    CustID          INT     NOT NULL
    ,ProductID      TINYINT NOT NULL
    ,MaxWinLimit    MONEY   NULL
    ,TotalWinAmt    MONEY   NULL
    ,IsBlocked      BIT     NULL
    ,CreateDate     DATETIME NULL DEFAULT(GETDATE())
    ,UnBlockDate    DATETIME NULL
    ,IsNotified     BIT NULL
     
) ON [DATA]
GO
 
--@DBTXN/DBCUST
USE CustDB
GO
CREATE TABLE dbo.WinLimit_UseDeviceId
(
    DeviceID        VARCHAR(50)     NOT NULL
    ,ProductID      TINYINT NOT NULL
    ,IsBlocked      BIT     NULL
    ,CreateDate     DATETIME NULL DEFAULT(GETDATE())
    ,UnBlockDate    DATETIME NULL
) ON [DATA]
GO