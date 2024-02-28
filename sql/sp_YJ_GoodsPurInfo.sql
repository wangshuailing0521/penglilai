--货物跟踪订货表
--SELECT FSTOCKORGID,COUNT(1) FROM T_STK_INVENTORY GROUP BY FSTOCKORGID
--EXEC sp_YJ_GoodsPurInfo 101328,'2024-02-01'
ALTER PROC sp_YJ_GoodsPurInfo
	@OrgId INT = 0,
	@CurrentDay VARCHAR(10) = '',
	@MaterialNos VARCHAR(2000) = '',
	@MaterialGroups VARCHAR(2000) = '',
	@CategoryNos VARCHAR(2000) = '',
	@StockNos VARCHAR(2000) = '',
	@InStockNos VARCHAR(2000) = '',
	@NoGoodSpace INT = 15 --断货日期范围
AS
BEGIN
	DECLARE @SQL VARCHAR(4000)
	IF(@CurrentDay = '')
	BEGIN
		SET @CurrentDay = CONVERT(VARCHAR(10),GETDATE(),120)
	END

	CREATE TABLE #TEMP(
		FStockOrgId INT DEFAULT 0,
		FStockId INT DEFAULT 0,
		FStockNo VARCHAR(255) DEFAULT '', 
		FStockName VARCHAR(255) DEFAULT '', --仓库
		FMaterialId INT DEFAULT 0,
		FMaterialNo VARCHAR(255) DEFAULT '', --物料编码
		FMaterialName VARCHAR(255) DEFAULT '', --物料名称
		FSpecification VARCHAR(255) DEFAULT '', --规格型号
		FMaterialGroup VARCHAR(255) DEFAULT '', --物料分组
		FCategoryID VARCHAR(255) DEFAULT '', --存货类别
		FUnitName VARCHAR(255) DEFAULT '', --单位（库存单位）
		FOutStockDay1 DECIMAL(28,10) DEFAULT 0,
		FOutStockDay2 DECIMAL(28,10) DEFAULT 0,
		FOutStockDay3 DECIMAL(28,10) DEFAULT 0,
		FOutStockDay4 DECIMAL(28,10) DEFAULT 0,
		FOutStockDay5 DECIMAL(28,10) DEFAULT 0,
		FOutStockDay6 DECIMAL(28,10) DEFAULT 0,
		FOutStockDay7 DECIMAL(28,10) DEFAULT 0,
		FOutStockDay8 DECIMAL(28,10) DEFAULT 0,
		FOutStockDay9 DECIMAL(28,10) DEFAULT 0,
		FOutStockDay10 DECIMAL(28,10) DEFAULT 0, --当天
		FOutAvgBy10 DECIMAL(28,10) DEFAULT 0, --10日均发货数量
		FOutAvgBy5 DECIMAL(28,10) DEFAULT 0, --5日均发货数量
		FOutAvgByHand DECIMAL(28,10) DEFAULT 0, --大批量备货用日均增加值（手工数）
		FCurrentInventory DECIMAL(28,10) DEFAULT 0, --即时库存（库存单位）2023/10/10
		FPurQty1 DECIMAL(28,10) DEFAULT 0, --当天到货数量（隐藏）
		FPurQty2 DECIMAL(28,10) DEFAULT 0, --第2天到货数量（隐藏）
		FPurQty3 DECIMAL(28,10) DEFAULT 0, --第3天到货数量（隐藏）
		FPurQty4 DECIMAL(28,10) DEFAULT 0, --第2天到货数量（隐藏）
		FPurQty5 DECIMAL(28,10) DEFAULT 0, --第2天到货数量（隐藏）
		FPurQty6 DECIMAL(28,10) DEFAULT 0, --第2天到货数量（隐藏）
		FPurQty7 DECIMAL(28,10) DEFAULT 0, --第2天到货数量（隐藏）
		FPurQty8 DECIMAL(28,10) DEFAULT 0, --第2天到货数量（隐藏）
		FPurQty9 DECIMAL(28,10) DEFAULT 0, --第2天到货数量（隐藏）
		FPurQty10 DECIMAL(28,10) DEFAULT 0, --第2天到货数量（隐藏）
		FPurQty11 DECIMAL(28,10) DEFAULT 0, --第2天到货数量（隐藏）
		FPurQty12 DECIMAL(28,10) DEFAULT 0, --第2天到货数量（隐藏）
		FPurQty13 DECIMAL(28,10) DEFAULT 0, --第2天到货数量（隐藏）
		FPurQty14 DECIMAL(28,10) DEFAULT 0, --第2天到货数量（隐藏）
		FPurQty15 DECIMAL(28,10) DEFAULT 0, --第2天到货数量（隐藏）
		FPurQty16 DECIMAL(28,10) DEFAULT 0, --第2天到货数量（隐藏）
		FInventoryDay1 DECIMAL(28,10) DEFAULT 0, --当天预计库存
		FInventoryDay2 DECIMAL(28,10) DEFAULT 0, --第2天库存
		FInventoryDay3 DECIMAL(28,10) DEFAULT 0,
		FInventoryDay4 DECIMAL(28,10) DEFAULT 0,
		FInventoryDay5 DECIMAL(28,10) DEFAULT 0,
		FInventoryDay6 DECIMAL(28,10) DEFAULT 0,
		FInventoryDay7 DECIMAL(28,10) DEFAULT 0,
		FInventoryDay8 DECIMAL(28,10) DEFAULT 0,
		FInventoryDay9 DECIMAL(28,10) DEFAULT 0,
		FInventoryDay10 DECIMAL(28,10) DEFAULT 0,
		FInventoryDay11 DECIMAL(28,10) DEFAULT 0,
		FInventoryDay12 DECIMAL(28,10) DEFAULT 0,
		FInventoryDay13 DECIMAL(28,10) DEFAULT 0,
		FInventoryDay14 DECIMAL(28,10) DEFAULT 0,
		FInventoryDay15 DECIMAL(28,10) DEFAULT 0,
		FInventoryDay16 DECIMAL(28,10) DEFAULT 0,
		FMaxOutStockBy10 DECIMAL(28,10) DEFAULT 0, --10天内最大值(出库)
		FNoGoodsDay VARCHAR(255) DEFAULT '', --断货日期
		FSafeInventory DECIMAL(28,10) DEFAULT 0, --安全库存数量（库存单位）
		FMinPurQty DECIMAL(28,10) DEFAULT 0, --最低采购量（获取物料值）
		FDeliveryDay VARCHAR(255) DEFAULT '', --到货天数（获取物料值）
		FCanDeliveryDay DECIMAL(28,10) DEFAULT 0, --即时库存可发货天数
		FDeliveryDay1 VARCHAR(255) DEFAULT '', --已下采购订单到货日期
		FDeliveryDay1Qty DECIMAL(28,10) DEFAULT 0,--已下采购订单数量
		FDeliveryDay2 VARCHAR(255) DEFAULT '', 
		FDeliveryDay2Qty DECIMAL(28,10) DEFAULT 0,
		FDeliveryDay3 VARCHAR(255) DEFAULT '', 
		FDeliveryDay3Qty DECIMAL(28,10) DEFAULT 0,
		FReasonableDay VARCHAR(255) DEFAULT '',  --合理下单日期
		FHavePurOrder VARCHAR(255) DEFAULT '',  --断货日期前是否有采购订单
		FSuggestDay VARCHAR(255) DEFAULT '',  --建议下单日期
		FMaxGoodQty DECIMAL(28,10) DEFAULT 0, --最优进货数量
		FSuggestDeliveryDay VARCHAR(255) DEFAULT '',  --建议到货日期
	)

	CREATE TABLE #OUTSTOCKTEMP(
		FStockOrgId INT,
		FDATE DATETIME,
		FStockNo VARCHAR(255),
		FMaterialNo VARCHAR(255),
		FQty DECIMAL(28,10)
	)

	INSERT INTO #TEMP(
		FStockOrgId,FStockId,FStockNo,FStockName,FMaterialId,FMaterialNo,FMaterialName,FSpecification,FUnitName
	   ,FCurrentInventory,FMinPurQty,FDeliveryDay,FMaterialGroup,FCategoryID)
	SELECT  
		A.FStockOrgId,A.FSTOCKID,BS.FNUMBER,B.FNAME,A.FMATERIALID,C.FNUMBER,D.FNAME,D.FSPECIFICATION,E.FNAME
	   ,SUM(FBASEQTY/BMS.FSTOREURNUM*BMS.FSTOREURNOM),C.F_ora_XYSJ1,C.F_ora_XYSJ2,C.FMATERIALGROUP,BMB.FCategoryID
	  FROM  T_STK_INVENTORY A
			INNER JOIN T_BD_STOCK BS
			ON A.FSTOCKID = BS.FSTOCKID
			INNER JOIN T_BD_STOCK_L B
			ON A.FSTOCKID = B.FSTOCKID AND B.FLOCALEID = 2052
			INNER JOIN T_BD_MATERIAL C
			ON A.FMATERIALID = C.FMATERIALID
			INNER JOIN T_BD_MATERIALGROUP BMG
			ON C.FMATERIALGROUP = BMG.FID
			INNER JOIN T_BD_MATERIALBASE BMB
			ON A.FMATERIALID = BMB.FMATERIALID
			LEFT JOIN T_BD_MATERIALCATEGORY BMC
			ON BMB.FCATEGORYID = BMC.FCATEGORYID
			INNER JOIN T_BD_MATERIAL_L D
			ON A.FMATERIALID = D.FMATERIALID AND D.FLOCALEID = 2052
			INNER JOIN T_BD_UNIT_L E
			ON A.FSTOCKUNITID = E.FUNITID AND E.FLOCALEID = 2052
			LEFT JOIN T_BD_MATERIALSTOCK BMS
			ON A.FMATERIALID = BMS.FMATERIALID 
	 WHERE  A.FBASEQTY <> 0
	   AND  A.FSTOCKORGID = @OrgId
	   AND  ((@MaterialNos <> '' AND (C.FNUMBER IN (SELECT value FROM sp_split(@MaterialNos,','))) )OR @MaterialNos = '')
	   AND  ((@StockNos <> '' AND (BS.FNUMBER IN (SELECT value FROM sp_split(@StockNos,','))) )OR @StockNos = '')
	   AND  ((@CategoryNos <> '' AND (BMC.FNUMBER IN (SELECT value FROM sp_split(@CategoryNos,','))) )OR @CategoryNos = '')
	   AND  ((@MaterialGroups <> '' AND (BMG.FNUMBER IN (SELECT value FROM sp_split(@MaterialGroups,','))) )OR @MaterialGroups = '')
	 GROUP  BY A.FStockOrgId,A.FSTOCKID,BS.FNUMBER,B.FNAME,A.FMATERIALID,C.FNUMBER,D.FNAME,D.FSPECIFICATION
			  ,E.FNAME,C.F_ora_XYSJ1,C.F_ora_XYSJ2,C.FMATERIALGROUP,BMB.FCategoryID

	-------------------------------------------------------------------------------------------------------------------
	--获取当天之前，每天的出库数量
	-------------------------------------------------------------------------------------------------------------------
	DECLARE @OutDayInt INT
	DECLARE @OutBeginDateTime DATETIME
	DECLARE @OutEndDateTime DATETIME

	
	SET @OutBeginDateTime = DATEADD(DAY,-10,@CurrentDay)
	SET @OutEndDateTime = DATEADD(DAY,1,@CurrentDay)

	--获取销售出库数量
	SET @SQL = '
	INSERT INTO #OUTSTOCKTEMP
	SELECT  A.FStockOrgId,A.FDATE,D.FNumber FStockNo,C.FNUMBER FMaterialNo,SUM(B.FRealQty)FQty
	  FROM  T_SAL_OUTSTOCK A
			INNER JOIN T_SAL_OUTSTOCKENTRY B
			ON A.FID = B.FID
			INNER JOIN T_BD_MATERIAL C
			ON B.FMATERIALID = C.FMATERIALID
			INNER JOIN T_BD_STOCK D
			ON B.FStockId = D.FStockId
	 WHERE  1=1
	   AND  A.FDOCUMENTSTATUS = ''C''
	   AND  A.FCANCELSTATUS = ''A''
	   AND  A.FStockOrgId = '+CONVERT(VARCHAR(10),@OrgId)+'
	   AND  A.FDATE >= '''+CONVERT(VARCHAR(10),@OutBeginDateTime,120)+'''
	   AND  A.FDATE < '''+CONVERT(VARCHAR(10),@OutEndDateTime,120)+'''
	 GROUP  BY A.FStockOrgId,D.FNumber,C.FNUMBER,A.FDATE '
	EXECUTE (@SQL)
	--获取直接调拨数量
	SET @SQL = '
	INSERT INTO #OUTSTOCKTEMP
	SELECT  A.FStockOutOrgId FStockOrgId,A.FDATE,D.FNumber FStockNo,C.FNUMBER FMaterialNo,SUM(B.FQty)FQty
	  FROM  T_STK_STKTRANSFERIN A WITH(NOLOCK)
			INNER JOIN T_STK_STKTRANSFERINENTRY B WITH(NOLOCK)
			ON A.FID = B.FID
			INNER JOIN T_BD_MATERIAL C WITH(NOLOCK)
			ON B.FMATERIALID = C.FMATERIALID
			INNER JOIN T_BD_STOCK D WITH(NOLOCK)
			ON B.FSrcStockId = D.FStockId
			INNER JOIN T_BD_STOCK E WITH(NOLOCK)
			ON B.FDestStockId = E.FStockId
	 WHERE  1=1
	   AND  A.FDOCUMENTSTATUS = ''C''
	   AND  A.FCANCELSTATUS = ''A''
	   AND  A.FOBJECTTYPEID = ''STK_TransferDirect''
	   AND  A.FBILLTYPEID = ''ce8f49055c5c4782b65463a3f863bb4a''
	   AND  A.FDATE >= '''+CONVERT(VARCHAR(10),@OutBeginDateTime,120)+'''
	   AND  A.FDATE < '''+CONVERT(VARCHAR(10),@OutEndDateTime,120)+'''
	   '+@InStockNos+'
	 GROUP  BY A.FStockOutOrgId,D.FNumber,C.FNUMBER,A.FDATE '
	EXECUTE (@SQL)

	SET @OutDayInt = 1
	WHILE(@OutDayInt < 11)
	BEGIN
		SET @OutBeginDateTime = DATEADD(DAY,0 - (10 - @OutDayInt),@CurrentDay)
		SET @OutEndDateTime = DATEADD(DAY,1,@OutBeginDateTime)
		
		----获取销售出库数量
		--SET @SQL = '
		--UPDATE  A
		--   SET  A.FOutStockDay'+CONVERT(VARCHAR(10),@OutDayInt,120)+' = ISNULL(A.FOutStockDay'+CONVERT(VARCHAR(10),@OutDayInt,120)+',0) + ISNULL(B.FQty,0)
		--  FROM  #TEMP A
		--		INNER JOIN (SELECT  A.FStockOrgId,D.FNumber FStockNo,C.FNUMBER FMaterialNo,SUM(B.FRealQty)FQty
		--					  FROM  T_SAL_OUTSTOCK A
		--							INNER JOIN T_SAL_OUTSTOCKENTRY B
		--							ON A.FID = B.FID
		--							INNER JOIN T_BD_MATERIAL C
		--							ON B.FMATERIALID = C.FMATERIALID
		--							INNER JOIN T_BD_STOCK D
		--							ON B.FStockId = D.FStockId
		--					 WHERE  1=1
		--					   AND  A.FDOCUMENTSTATUS = ''C''
		--					   AND  A.FCANCELSTATUS = ''A''
		--					   AND  A.FStockOrgId = '+CONVERT(VARCHAR(10),@OrgId)+'
		--					   AND  A.FDATE >= '''+CONVERT(VARCHAR(10),@OutBeginDateTime,120)+'''
		--					   AND  A.FDATE < '''+CONVERT(VARCHAR(10),@OutEndDateTime,120)+'''
		--					 GROUP  BY A.FStockOrgId,D.FNumber,C.FNUMBER) B
		--		ON A.FStockOrgId = B.FStockOrgId AND A.FStockNo = B.FStockNo AND A.FMaterialNo = B.FMaterialNo '
		--EXECUTE (@SQL)

		--获取直接调拨数量
		SET @SQL = '
		UPDATE  A
		   SET  A.FOutStockDay'+CONVERT(VARCHAR(10),@OutDayInt,120)+' = ISNULL(A.FOutStockDay'+CONVERT(VARCHAR(10),@OutDayInt,120)+',0) + ISNULL(B.FQty,0)
		  FROM  #TEMP A
				INNER JOIN (SELECT  A.FStockOrgId,A.FStockNo,A.FMaterialNo,SUM(A.FQty)FQty
							  FROM  #OUTSTOCKTEMP A
							 WHERE  1=1
							   AND  A.FDATE >= '''+CONVERT(VARCHAR(10),@OutBeginDateTime,120)+'''
							   AND  A.FDATE < '''+CONVERT(VARCHAR(10),@OutEndDateTime,120)+'''
							 GROUP  BY A.FStockOrgId,A.FStockNo,A.FMaterialNo) B
				ON A.FStockOrgId = B.FStockOrgId AND A.FStockNo = B.FStockNo AND A.FMaterialNo = B.FMaterialNo '
		EXECUTE (@SQL)
		--SET @SQL = '
		--UPDATE  A
		--   SET  A.FOutStockDay'+CONVERT(VARCHAR(10),@OutDayInt,120)+' = ISNULL(A.FOutStockDay'+CONVERT(VARCHAR(10),@OutDayInt,120)+',0) + ISNULL(B.FQty,0)
		--  FROM  #TEMP A
		--		INNER JOIN (SELECT  A.FStockOutOrgId FStockOrgId,D.FNumber FStockNo,C.FNUMBER FMaterialNo,SUM(B.FQty)FQty
		--					  FROM  T_STK_STKTRANSFERIN A WITH(NOLOCK)
		--							INNER JOIN T_STK_STKTRANSFERINENTRY B WITH(NOLOCK)
		--							ON A.FID = B.FID
		--							INNER JOIN T_BD_MATERIAL C WITH(NOLOCK)
		--							ON B.FMATERIALID = C.FMATERIALID
		--							INNER JOIN T_BD_STOCK D WITH(NOLOCK)
		--							ON B.FSrcStockId = D.FStockId
		--							INNER JOIN T_BD_STOCK E WITH(NOLOCK)
		--							ON B.FDestStockId = E.FStockId
		--					 WHERE  1=1
		--					   AND  A.FDOCUMENTSTATUS = ''C''
		--					   AND  A.FCANCELSTATUS = ''A''
		--					   --AND  A.FOBJECTTYPEID = ''STK_TransferDirect''
		--					   AND  A.FBILLTYPEID = ''ce8f49055c5c4782b65463a3f863bb4a''
		--					   AND  A.FDATE >= '''+CONVERT(VARCHAR(10),@OutBeginDateTime,120)+'''
		--					   AND  A.FDATE < '''+CONVERT(VARCHAR(10),@OutEndDateTime,120)+'''
		--					   '+@InStockNos+'
		--					 GROUP  BY A.FStockOutOrgId,D.FNumber,C.FNUMBER) B
		--		ON A.FStockOrgId = B.FStockOrgId AND A.FStockNo = B.FStockNo AND A.FMaterialNo = B.FMaterialNo '
		--EXECUTE (@SQL)

		SET @OutDayInt = @OutDayInt + 1
	END

	UPDATE #TEMP SET FOutAvgBy10 = (
		FOutStockDay1 + FOutStockDay2 +FOutStockDay3 + FOutStockDay4 + FOutStockDay5  + FOutStockDay6
	  + FOutStockDay7 + FOutStockDay8 + FOutStockDay9 + FOutStockDay10) / 10
	UPDATE #TEMP SET FOutAvgBy5 = (
		FOutStockDay1 + FOutStockDay2 +FOutStockDay3 + FOutStockDay4 + FOutStockDay5) / 5

	DELETE FROM #TEMP WHERE FOutAvgBy10 = 0

	-------------------------------------------------------------------------------------------------------------------
	--获取10天内最大值(出库)
	-------------------------------------------------------------------------------------------------------------------
	SELECT FStockOrgId,FStockId,FMaterialId
		 ,(SELECT Max(FMaxOutStockDay) 
		     FROM (VALUES (FOutStockDay1),(FOutStockDay2),(FOutStockDay3)
			             ,(FOutStockDay4),(FOutStockDay5),(FOutStockDay6)
						 ,(FOutStockDay7),(FOutStockDay8),(FOutStockDay9),(FOutStockDay10)
				  )AS #MaxOutDayTemp(FMaxOutStockDay)) AS FMaxOutStockDay 
	  INTO #MaxOutStockDay
	  FROM #TEMP

	UPDATE  A
	   SET  A.FMaxOutStockBy10 = B.FMaxOutStockDay
	  FROM  #TEMP A
			INNER JOIN #MaxOutStockDay B
			ON A.FStockOrgId = B.FStockOrgId AND A.FStockId = B.FStockId AND A.FMaterialId = B.FMaterialId

	-------------------------------------------------------------------------------------------------------------------
	--获取当天之后15天内，每天的库存
	-------------------------------------------------------------------------------------------------------------------
	DECLARE @InDayInt INT
	DECLARE @PurBeginDateTime DATETIME
	DECLARE @PurEndDateTime DATETIME
	DECLARE @PurDayFileName VARCHAR(255)
	DECLARE @InDayFileName VARCHAR(255)
	
	SET @InDayInt = 0
	SET @PurBeginDateTime = DATEADD(DAY,@InDayInt,@CurrentDay)
	WHILE(@InDayInt < 16)
	BEGIN
		--第2天的库存量=即时库存-5日均量+当日采购订单数量（到货时间获取）（低于最小库存量则当天库存量显示红色即断货日期）；后续日期以此类推；                                         低于安全库存量的日期显示蓝色（合理下单日期）

		SET @PurEndDateTime = DATEADD(DAY,@InDayInt + 1,@CurrentDay)
		--获取当天采购到货数量
		SET @PurDayFileName = 'FPurQty'+CONVERT(VARCHAR(10),@InDayInt+1,120)
		SET @SQL ='
		UPDATE  A
		   SET  A.'+@PurDayFileName+' =  ISNULL(B.FQty,0)
		  FROM  #TEMP A
				LEFT JOIN (SELECT  A.FPurchaseOrgId FStockOrgId,D.FNumber FStockNo,C.FNUMBER FMaterialNo,SUM(BR.FRemainStockINQty)FQty
							  FROM  t_PUR_POOrder A
									INNER JOIN t_PUR_POOrderEntry B
									ON A.FID = B.FID
									INNER JOIN T_PUR_POORDERENTRY_R BR
									ON B.FENTRYID = BR.FENTRYID
									INNER JOIN t_PUR_POENTRYDELIPLAN BDP
									ON B.FENTRYID = BDP.FENTRYID
									INNER JOIN T_BD_MATERIAL C
									ON B.FMATERIALID = C.FMATERIALID
									INNER JOIN T_BD_MATERIALSTOCK BMS
									ON B.FMATERIALID = BMS.FMATERIALID
									INNER JOIN T_BD_STOCK D
									ON BMS.FStockId = D.FStockId
							 WHERE  1=1
							   AND  A.FDOCUMENTSTATUS = ''C''
							   AND  A.FCANCELSTATUS = ''A''
							   AND  B.FMRPCloseStatus = ''A''
							   AND  B.FMRPTerminateStatus = ''A''
							   AND  ISNULL(B.F_UNLF_LXBS,'''') <> ''2'' --非特采
							   AND  A.FPurchaseOrgId = '+CONVERT(VARCHAR(10),@OrgId)+'
							   AND  BDP.FDELIVERYDATE >= '''+CONVERT(VARCHAR(10),DATEADD(DAY,-1,@PurEndDateTime),120)+'''
							   AND  BDP.FDELIVERYDATE < '''+CONVERT(VARCHAR(10),@PurEndDateTime,120)+'''
							 GROUP  BY A.FPurchaseOrgId,D.FNumber,C.FNUMBER) B
				ON A.FStockOrgId = B.FStockOrgId AND A.FStockNo = B.FStockNo AND A.FMaterialNo = B.FMaterialNo '
		EXECUTE (@SQL)
		
		--获取当天库存 ： 即时库存-5日均量*天数+累计采购订单数量（到货时间获取）
		SET @InDayFileName = 'FInventoryDay'+CONVERT(VARCHAR(10),@InDayInt+1,120)
		SET @SQL ='
		UPDATE  A
		   SET  A.'+@InDayFileName+' = FCurrentInventory - FOutAvgBy5 * '+CONVERT(VARCHAR(10),@InDayInt)+' + ISNULL(B.FQty,0)
		  FROM  #TEMP A
				LEFT JOIN (SELECT  A.FPurchaseOrgId FStockOrgId,D.FNumber FStockNo,C.FNUMBER FMaterialNo,SUM(BR.FRemainStockINQty)FQty
							  FROM  t_PUR_POOrder A
									INNER JOIN t_PUR_POOrderEntry B
									ON A.FID = B.FID
									INNER JOIN T_PUR_POORDERENTRY_R BR
									ON B.FENTRYID = BR.FENTRYID
									INNER JOIN t_PUR_POENTRYDELIPLAN BDP
									ON B.FENTRYID = BDP.FENTRYID
									INNER JOIN T_BD_MATERIAL C
									ON B.FMATERIALID = C.FMATERIALID
									INNER JOIN T_BD_MATERIALSTOCK BMS
									ON B.FMATERIALID = BMS.FMATERIALID
									INNER JOIN T_BD_STOCK D
									ON BMS.FStockId = D.FStockId
							 WHERE  1=1
							   AND  A.FDOCUMENTSTATUS = ''C''
							   AND  A.FCANCELSTATUS = ''A''
							   AND  B.FMRPCloseStatus = ''A''
							   AND  B.FMRPTerminateStatus = ''A''
							   AND  ISNULL(B.F_UNLF_LXBS,'''') <> ''2'' --非特采
							   AND  A.FPurchaseOrgId = '+CONVERT(VARCHAR(10),@OrgId)+'
							   AND  BDP.FDELIVERYDATE >= '''+CONVERT(VARCHAR(10),@PurBeginDateTime,120)+'''
							   AND  BDP.FDELIVERYDATE < '''+CONVERT(VARCHAR(10),@PurEndDateTime,120)+'''
							 GROUP  BY A.FPurchaseOrgId,D.FNumber,C.FNUMBER) B
				ON A.FStockOrgId = B.FStockOrgId AND A.FStockNo = B.FStockNo AND A.FMaterialNo = B.FMaterialNo '
		EXECUTE (@SQL)

		--更新断货日期(库存量低于10天内最大发货量日期)
		SET @SQL = 'UPDATE #TEMP SET FNoGoodsDay = '''+CONVERT(VARCHAR(10),DATEADD(DAY,@InDayInt,@CurrentDay),120) +''' 
					WHERE '+@InDayFileName+' < FMaxOutStockBy10 AND FNoGoodsDay = '''''
		EXECUTE (@SQL)

		SET @InDayInt = @InDayInt + 1
	END

	--更新已下采购订单到货日期，已下采购订单数量
	SELECT  A.FPurchaseOrgId FStockOrgId,D.FNumber FStockNo,C.FNUMBER FMaterialNo,BDP.FDELIVERYDATE,SUM(BR.FRemainStockINQty)FQty
	  INTO  #Poorde
	  FROM  t_PUR_POOrder A
			INNER JOIN t_PUR_POOrderEntry B
			ON A.FID = B.FID
			INNER JOIN t_PUR_POOrderEntry_R BR
			ON B.FENTRYID = BR.FENTRYID
			INNER JOIN t_PUR_POENTRYDELIPLAN BDP
			ON B.FENTRYID = BDP.FENTRYID
			INNER JOIN T_BD_MATERIAL C
			ON B.FMATERIALID = C.FMATERIALID
			INNER JOIN T_BD_MATERIALSTOCK BMS
			ON B.FMATERIALID = BMS.FMATERIALID
			INNER JOIN T_BD_STOCK D
			ON BMS.FStockId = D.FStockId
	 WHERE  1=1
	   AND  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FCANCELSTATUS = 'A'
	   AND  B.FMRPCloseStatus = 'A'
	   AND  B.FMRPTerminateStatus = 'A'
	   AND  ISNULL(B.F_UNLF_LXBS,'') <> '2' --非特采
	   AND  A.FPurchaseOrgId = @OrgId	
	   AND  BR.FRemainStockINQty > 0
	 GROUP  BY A.FPurchaseOrgId,D.FNumber,C.FNUMBER,BDP.FDELIVERYDATE

	SELECT  ROW_NUMBER() OVER(PARTITION BY FStockOrgId,FStockNo,FMaterialNo ORDER BY FDELIVERYDATE ASC)FSeq,*
	  INTO  #PoorderSeq
	  FROM  #Poorde 

    DROP TABLE #Poorde
	
	UPDATE A
	   SET  A.FDeliveryDay1 = CONVERT(VARCHAR(10),B.FDELIVERYDATE,120)
	       ,A.FDeliveryDay1Qty = B.FQty
	  FROM  #TEMP A 
			INNER JOIN (SELECT * FROM #PoorderSeq WHERE FSeq = 1)B
			ON A.FStockOrgId = B.FStockOrgId AND A.FMaterialNo = B.FMaterialNo AND A.FStockNo = B.FStockNo

	UPDATE A
	   SET  A.FDeliveryDay2 = CONVERT(VARCHAR(10),B.FDELIVERYDATE,120)
	       ,A.FDeliveryDay2Qty = B.FQty
	  FROM  #TEMP A 
			INNER JOIN (SELECT * FROM #PoorderSeq WHERE FSeq = 2)B
			ON A.FStockOrgId = B.FStockOrgId AND A.FMaterialNo = B.FMaterialNo AND A.FStockNo = B.FStockNo

	UPDATE A
	   SET  A.FDeliveryDay3 = CONVERT(VARCHAR(10),B.FDELIVERYDATE,120)
	       ,A.FDeliveryDay3Qty = B.FQty
	  FROM  #TEMP A 
			INNER JOIN (SELECT * FROM #PoorderSeq WHERE FSeq = 3)B
			ON A.FStockOrgId = B.FStockOrgId AND A.FMaterialNo = B.FMaterialNo AND A.FStockNo = B.FStockNo

	--安全库存数量(5日均*到货天数)
	UPDATE #TEMP SET FDeliveryDay = 0 WHERE FDeliveryDay = ''
	UPDATE #TEMP SET FSafeInventory = FOutAvgBy5 * FDeliveryDay WHERE FDeliveryDay <> 0
	UPDATE #TEMP SET FSafeInventory = FOutAvgBy5  WHERE FDeliveryDay = 0
	--即时库存可发货天数(即时库存/5日均数（负数显示红色）)
	UPDATE #TEMP SET FCanDeliveryDay = FCurrentInventory / FOutAvgBy5 WHERE FOutAvgBy5 <> 0
	--合理下单日期(断货日期减到货天数)
	UPDATE #TEMP SET FReasonableDay = CONVERT(VARCHAR(10), DATEADD(DAY,0 - FDeliveryDay,FNoGoodsDay) ,120) WHERE FNoGoodsDay <> ''
	--断货日期前是否有采购订单(字段修改为采购建议)
	UPDATE #TEMP SET FHavePurOrder = '无'
	
	UPDATE #TEMP SET FHavePurOrder = '有' 
	WHERE FNoGoodsDay <> '' AND DATEDIFF(DAY,GETDATE(),CONVERT(VARCHAR(10),FNoGoodsDay,120)) <= @NoGoodSpace
	--UPDATE #TEMP SET FHavePurOrder = '否' WHERE FNoGoodsDay <> ''
	--UPDATE #TEMP SET FHavePurOrder = '是' WHERE FNoGoodsDay <> '' AND FDeliveryDay1 <> '' AND FDeliveryDay1 <= FNoGoodsDay
	--是否有采购订单为否时，进行下列操作
	--建议下单日期(建议下单日期=MAX(合理下单日期，当天))
	UPDATE #TEMP SET FSuggestDay = FReasonableDay WHERE FHavePurOrder = '有'
	UPDATE #TEMP SET FSuggestDay = CONVERT(VARCHAR(10),GETDATE(),120) 
	  WHERE FHavePurOrder = '有' 
	    AND FReasonableDay <> '' AND CONVERT(DATETIME,FReasonableDay) < CONVERT(DATETIME,CONVERT(VARCHAR(10),GETDATE(),120))
	--最优进货数量
	UPDATE #TEMP SET FMaxGoodQty = FSafeInventory WHERE FHavePurOrder = '有'
	UPDATE #TEMP SET FMaxGoodQty = FMinPurQty WHERE FSafeInventory < FMinPurQty AND FHavePurOrder = '有'
	--建议到货日期
	UPDATE #TEMP SET FSuggestDeliveryDay = CONVERT(VARCHAR(10),DATEADD(DAY,0 + FDeliveryDay,FSuggestDay),120)  WHERE FSuggestDay <> '' AND FHavePurOrder = '有'

	DELETE FROM #TEMP WHERE FOutAvgBy10 = 0

	SELECT * FROM #TEMP ORDER BY FStockId,FMaterialId
END
