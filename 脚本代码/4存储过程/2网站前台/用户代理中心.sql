----------------------------------------------------------------------------------------------------
-- 版权：2017
-- 时间：2017-11-16
-- 用途：用户代理中心数据
----------------------------------------------------------------------------------------------------

USE WHJHAccountsDB
GO

IF EXISTS (SELECT * FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[dbo].NET_PW_UserSpreadHome') and OBJECTPROPERTY(ID, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].NET_PW_UserSpreadHome
GO

SET QUOTED_IDENTIFIER ON 
GO

SET ANSI_NULLS ON 
GO

----------------------------------------------------------------------------------------------------

-- 帐号注册
CREATE PROCEDURE NET_PW_UserSpreadHome
	@dwUserID			INT,
	@dwType				TINYINT
-- 用户标识
WITH
	ENCRYPTION
AS

-- 属性设置
SET NOCOUNT ON

-- 基本信息
DECLARE @UserID INT
DECLARE @GameID INT

-- 扩展信息
DECLARE @Lv1Count INT
DECLARE @Lv2Count INT
DECLARE @Lv3Count INT
DECLARE @TotalReturn BIGINT
DECLARE @TotalReceive BIGINT

-- 执行逻辑
BEGIN
	SELECT @UserID=UserID, @GameID=GameID
	FROM WHJHAccountsDB.dbo.AccountsInfo
	WHERE UserID=@dwUserID

	SELECT @Lv1Count = COUNT(UserID)
	FROM [dbo].WF_GetAgentBelowAccounts (@dwUserID)
	WHERE LevelID = 2

	SELECT @Lv2Count = COUNT(UserID)
	FROM [dbo].WF_GetAgentBelowAccounts (@dwUserID)
	WHERE LevelID = 3

	SELECT @Lv3Count = COUNT(UserID)
	FROM [dbo].WF_GetAgentBelowAccounts (@dwUserID)
	WHERE LevelID = 4

	SELECT @TotalReturn = CAST(ISNULL(SUM(ReturnNum),0) AS BIGINT)
	FROM WHJHRecordDB.dbo.RecordSpreadReturn(NOLOCK)
	WHERE TargetUserID=@dwUserID AND ReturnType=@dwType

	SELECT @TotalReceive = CAST(ISNULL(SUM(ReceiveNum),0) AS BIGINT)
	FROM WHJHRecordDB.dbo.RecordSpreadReturnReceive(NOLOCK)
	WHERE UserID=@dwUserID AND ReceiveType=@dwType

	SELECT @UserID AS UserID, @GameID AS GameID, @Lv1Count AS Lv1Count, @Lv2Count AS Lv2Count,
		@Lv3Count AS Lv3Count, @TotalReturn AS TotalReturn, @TotalReceive AS TotalReceive

	SELECT TOP 100
		*
	FROM WHJHRecordDB.dbo.RecordSpreadReturn(NOLOCK)
	WHERE TargetUserID = @dwUserID AND ReturnType = @dwType
	ORDER BY CollectDate DESC

END

RETURN 0

GO