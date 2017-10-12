----------------------------------------------------------------------
-- 版权：2017
-- 时间：2017-06-8
-- 用途：在线充值
----------------------------------------------------------------------

USE [WHJHTreasureDB]
GO

-- 在线充值
IF EXISTS (SELECT * FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[dbo].NET_PW_FinishOnLineOrder') and OBJECTPROPERTY(ID, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].NET_PW_FinishOnLineOrder
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

---------------------------------------------------------------------------------------
-- 在线充值
CREATE PROCEDURE NET_PW_FinishOnLineOrder
	@strOrdersID		NVARCHAR(50),			--	订单编号
	@PayAmount			DECIMAL(18,2),			--  支付金额
	@strIPAddress		NVARCHAR(31),			--	用户帐号	
	@strErrorDescribe	NVARCHAR(127) OUTPUT	--	输出信息
WITH ENCRYPTION AS

-- 属性设置
SET NOCOUNT ON

-- 订单信息
DECLARE @UserID INT
DECLARE @Amount DECIMAL(18,2)
DECLARE @Diamond INT
DECLARE @PresentDiamond INT
DECLARE @OtherPresent INT
DECLARE @BeforeDiamond BIGINT
DECLARE @OrderStatus TINYINT
DECLARE @DateTime DATETIME

-- 执行逻辑
BEGIN
	SET @DateTime = GETDATE()
	-- 订单查询
	SELECT @UserID=UserID,@Amount=Amount,@Diamond=Diamond,@OtherPresent=OtherPresent,@OrderStatus=OrderStatus FROM OnLinePayOrder WITH(NOLOCK) WHERE OrderID = @strOrdersID
	IF @UserID IS NULL
	BEGIN
		SET @strErrorDescribe=N'抱歉！充值订单不存在!'
		RETURN 1001
	END
	IF @OrderStatus=1
	BEGIN
		SET @strErrorDescribe=N'抱歉！充值订单已完成!'
		RETURN 1002
	END
	IF @Amount != @PayAmount
	BEGIN
		SET @strErrorDescribe=N'抱歉！支付金额错误!'
		RETURN 1003
	END
	SET @PresentDiamond = @Diamond + @OtherPresent

	-- 事务处理
	BEGIN TRAN

	SELECT @BeforeDiamond=Diamond FROM UserCurrency WITH(ROWLOCK) WHERE UserID=@UserID
	IF @BeforeDiamond IS NULL
	BEGIN
		SET @BeforeDiamond=0
		INSERT INTO UserCurrency VALUES(@UserID,@PresentDiamond)
	END
	ELSE
	BEGIN
		UPDATE UserCurrency SET Diamond = Diamond + @PresentDiamond WHERE UserID=@UserID
	END
	IF @@ROWCOUNT <=0
	BEGIN
		ROLLBACK TRAN
		SET @strErrorDescribe=N'抱歉！操作异常，请稍后重试!'
		RETURN 2001
	END
	UPDATE OnLinePayOrder SET OrderStatus=1,BeforeDiamond=@BeforeDiamond,PayDate=@DateTime,PayAddress=@strIPAddress WHERE OrderID = @strOrdersID
	IF @@ROWCOUNT <=0
	BEGIN
		ROLLBACK TRAN
		SET @strErrorDescribe=N'抱歉！操作异常，请稍后重试!'
		RETURN 2001
	END

	COMMIT TRAN

	-- 写入钻石流水记录
	INSERT INTO WHJHRecordDB.dbo.RecordDiamondSerial(SerialNumber,MasterID,UserID,TypeID,CurDiamond,ChangeDiamond,ClientIP,CollectDate) 
	VALUES(dbo.WF_GetSerialNumber(),0,@UserID,3,@BeforeDiamond,@PresentDiamond,@strIPAddress,@DateTime)
	
END 
RETURN 0
GO



