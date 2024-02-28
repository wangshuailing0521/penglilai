--车辆配送详单
--EXEC sp_YJ_VehicleSendDetail '',1,'2024-01-05'
ALTER PROC sp_YJ_VehicleSendDetail
	@TempTable VARCHAR(36),
	@VehicleNo INT = '',
	@Date VARCHAR(255) = '',
	@OrgId INT = 0,
	@IsReport INT = 0
AS
BEGIN
	CREATE TABLE #TEMP (
		FMaterialSeq INT,
		FMaterialNo VARCHAR(255),
		FMaterialName VARCHAR(255),
		FUnitNo VARCHAR(255),
		FUnitName VARCHAR(255)
	)

	--------------------------------------------------------------------------------------------------------
	--获取总数据
	--------------------------------------------------------------------------------------------------------
	SELECT  C.FNUMBER
	  INTO  #OrgNo
	  FROM  T_YJ_ShopNo A
			INNER JOIN T_YJ_ShopNoEntry B
			ON A.FID = B.FID
			INNER JOIN T_ORG_Organizations C
			ON B.FShopItem = C.FORGID
	 WHERE  1=1
	   AND  A.FDOCUMENTSTATUS = 'C'
	   AND  B.FShopItemType = 'ORG_Organizations'
	   AND  B.FLineNo = @VehicleNo
	   AND  B.FShopItem <> 0 
	 GROUP  BY C.FNUMBER

	SELECT  C.FNUMBER
	  INTO  #DeptNo
	  FROM  T_YJ_ShopNo A
			INNER JOIN T_YJ_ShopNoEntry B
			ON A.FID = B.FID
			INNER JOIN T_BD_DEPARTMENT C
			ON B.FShopItem = C.FDEPTID
	 WHERE  1=1
	   AND  A.FDOCUMENTSTATUS = 'C'
	   AND  B.FShopItemType = 'BD_Department'
	   AND  B.FLineNo = @VehicleNo
	   AND  B.FShopItem <> 0 
	 GROUP  BY C.FNUMBER

	SELECT  C.FNUMBER
	  INTO  #CustNo
	  FROM  T_YJ_ShopNo A
			INNER JOIN T_YJ_ShopNoEntry B
			ON A.FID = B.FID
			INNER JOIN T_BD_CUSTOMER C
			ON B.FShopItem = C.FCUSTID
	 WHERE  1=1
	   AND  A.FDOCUMENTSTATUS = 'C'
	   AND  B.FShopItemType = 'BD_Customer'
	   AND  B.FLineNo = @VehicleNo
	   AND  B.FShopItem <> 0 
	 GROUP  BY C.FNUMBER

	--获取销售出库数据
	SELECT  C.FNUMBER FMaterialNo
		   ,D.FNUMBER FUnitNo
		   ,ORG.FNUMBER FOrgNo
		   ,DEPT.FNUMBER FDeptNo
		   ,CUST.FNUMBER FCustNo
		   ,SUM(B.FREALQTY)FQty
	  INTO  #SaleTable
	  FROM  T_SAL_OUTSTOCK A WITH(NOLOCK)
			INNER JOIN T_SAL_OUTSTOCKENTRY B WITH(NOLOCK)
			ON A.FID = B.FID 
			INNER JOIN T_BD_MATERIAL C WITH(NOLOCK)
			ON B.FMATERIALID = C.FMATERIALID
			LEFT JOIN T_BD_UNIT D WITH(NOLOCK)
			ON B.FUNITID = D.FUNITID 
			LEFT JOIN T_ORG_ORGANIZATIONS ORG WITH(NOLOCK)
			ON A.FSALEORGID = ORG.FORGID
			LEFT JOIN T_BD_DEPARTMENT DEPT WITH(NOLOCK)
			ON A.FSALEDEPTID = DEPT.FDEPTID
			LEFT JOIN T_BD_CUSTOMER CUST WITH(NOLOCK)
			ON A.FCUSTOMERID = CUST.FCUSTID
	 WHERE  1=1
	   AND  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FCANCELSTATUS = 'A'
	   AND  A.FSALEORGID = @OrgId
	   AND  YEAR(A.FDATE) = YEAR(@Date)
	   AND  MONTH(A.FDATE) = MONTH(@Date)
	   AND  DAY(A.FDATE) = DAY(@Date)
	   AND  (    ORG.FNUMBER IN (SELECT FNUMBER FROM #OrgNo) 
	          OR DEPT.FNUMBER IN (SELECT FNUMBER FROM #DeptNo)
			  OR CUST.FNUMBER IN (SELECT FNUMBER FROM #CustNo)
			)
	 GROUP  BY C.FNUMBER,D.FNUMBER,ORG.FNUMBER,DEPT.FNUMBER,CUST.FNUMBER

	--获取直接调拨数据
	SELECT  C.FNUMBER FMaterialNo
		   ,D.FNUMBER FUnitNo
		   ,ORG.FNUMBER FOrgNo
		   ,DEPT.FNUMBER FDeptNo
		   ,CONVERT(VARCHAR(255),'') FCustNo
		   ,SUM(B.FQty)FQty
	  INTO  #StkTable
	  FROM  T_STK_STKTRANSFERIN A WITH(NOLOCK)
			INNER JOIN T_STK_STKTRANSFERINENTRY B WITH(NOLOCK)
			ON A.FID = B.FID 
			INNER JOIN T_BD_MATERIAL C WITH(NOLOCK)
			ON B.FMATERIALID = C.FMATERIALID
			LEFT JOIN T_BD_UNIT D WITH(NOLOCK)
			ON B.FUNITID = D.FUNITID 
			LEFT JOIN T_ORG_ORGANIZATIONS ORG WITH(NOLOCK)
			ON A.FStockOutOrgId = ORG.FORGID
			LEFT JOIN T_BD_STOCK BS
			ON B.FDESTSTOCKID = BS.FSTOCKID
			LEFT JOIN T_BD_DEPARTMENT DEPT WITH(NOLOCK)
			ON BS.F_ora_xy1 = DEPT.FDEPTID
			--LEFT JOIN T_BD_CUSTOMER CUST WITH(NOLOCK)
			--ON A.FCUSTOMERID = CUST.FCUSTID
	 WHERE  1=1
	   --AND  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FCANCELSTATUS = 'A'
	   AND  A.FOBJECTTYPEID = 'STK_TransferDirect'
	   AND  A.FStockOutOrgId = @OrgId
	   AND  YEAR(A.FDATE) = YEAR(@Date)
	   AND  MONTH(A.FDATE) = MONTH(@Date)
	   AND  DAY(A.FDATE) = DAY(@Date)
	   AND  (    ORG.FNUMBER IN (SELECT FNUMBER FROM #OrgNo) 
	          OR DEPT.FNUMBER IN (SELECT FNUMBER FROM #DeptNo)
			)
	 GROUP  BY C.FNUMBER,D.FNUMBER,ORG.FNUMBER,DEPT.FNUMBER

	--销售出库数据，直接调拨数据 合计到一起展示
	SELECT FMaterialNo,FUnitNo,FOrgNo,FDeptNo,FCustNo,SUM(FQty)FQty
	  INTO  #ALLMaterial
	  FROM (
		SELECT * FROM  #SaleTable
		UNION ALL
		SELECT * FROM  #StkTable)A
	 GROUP  BY FMaterialNo,FUnitNo,FOrgNo,FDeptNo,FCustNo

	--将数据整理到缓存表
	INSERT INTO #TEMP(FMaterialNo,FUnitNo,FMaterialSeq)
	SELECT  A.FMaterialNo,A.FUnitNo,B.FMATERIALSEQ
	  FROM  #ALLMaterial A
			INNER JOIN (SELECT C.FNUMBER,B.FMATERIALSEQ 
			              FROM T_YJ_MaterialInfo A 
							   INNER JOIN T_YJ_MaterialInfoEntry B 
						       ON A.FID = B.FID
							   INNER JOIN T_BD_MATERIAL C
							   ON B.FMATERIALID = C.FMATERIALID
						 WHERE A.FDOCUMENTSTATUS = 'C'
						 GROUP BY C.FNUMBER,B.FMATERIALSEQ)B
			ON A.FMaterialNo = B.FNUMBER
	 GROUP  BY A.FMaterialNo,A.FUnitNo,B.FMATERIALSEQ
	 ORDER  BY B.FMATERIALSEQ ASC

	SELECT  B.FShopItemType,B.FDeliverySeq
	       ,CASE WHEN B.FShopItemType = 'ORG_Organizations' THEN C.FNUMBER
				 WHEN B.FShopItemType = 'BD_Department' THEN E.FNUMBER
				 WHEN B.FShopItemType = 'BD_Customer' THEN G.FNUMBER
			END FNumber
		   ,CASE WHEN B.FShopItemType = 'ORG_Organizations' THEN D.FNAME
				 WHEN B.FShopItemType = 'BD_Department' THEN F.FNAME
				 WHEN B.FShopItemType = 'BD_Customer' THEN H.FNAME
			END FName
	  INTO  #AllShopInfo
	  FROM  T_YJ_ShopNo A WITH(NOLOCK)
			INNER JOIN T_YJ_ShopNoEntry B WITH(NOLOCK)
			ON A.FID = B.FID
			LEFT JOIN T_ORG_Organizations C WITH(NOLOCK)
			ON B.FShopItem = C.FORGID
			LEFT JOIN T_ORG_Organizations_L D WITH(NOLOCK)
			ON B.FShopItem = D.FORGID AND D.FLOCALEID = 2052
			LEFT JOIN T_BD_DEPARTMENT E WITH(NOLOCK)
			ON B.FShopItem = E.FDEPTID
			LEFT JOIN T_BD_DEPARTMENT_L F WITH(NOLOCK)
			ON B.FShopItem = F.FDEPTID AND F.FLOCALEID = 2052
			LEFT JOIN T_BD_CUSTOMER G WITH(NOLOCK)
			ON B.FShopItem = G.FCUSTID
			LEFT JOIN T_BD_CUSTOMER_L H WITH(NOLOCK)
			ON B.FShopItem = H.FCUSTID AND H.FLOCALEID = 2052
	 WHERE  1=1
	   AND  A.FDOCUMENTSTATUS = 'C'
	   AND  B.FLineNo = @VehicleNo
	   AND  B.FShopItem <> 0
	 GROUP  BY B.FShopItemType,B.FDeliverySeq,C.FNUMBER,D.FNAME,E.FNUMBER,F.FNAME,G.FNUMBER,H.FNAME

	DECLARE @SQL VARCHAR(2000)
	DECLARE @SUMSQL VARCHAR(4000)
	DECLARE @FilterColumn VARCHAR(20)
	DECLARE @ItemType VARCHAR(255)
	DECLARE @ItemNo VARCHAR(255)
	DECLARE @ItemName VARCHAR(255)
	DECLARE @ItemSeq VARCHAR(255)

	SET @SUMSQL = 'UPDATE #TEMP SET [合计] = 0 '

	DECLARE MyCursor CURSOR FOR
		SELECT FShopItemType,FNumber,FName,FDeliverySeq FROM #AllShopInfo ORDER BY FDeliverySeq ASC
	   OPEN MyCursor
	FETCH NEXT FROM MyCursor INTO @ItemType,@ItemNo,@ItemName,@ItemSeq
	WHILE(@@Fetch_Status = 0)
	BEGIN
		--动态创建列
		SET @ItemName = REPLACE(@ItemName,'(','')
		SET @ItemName = REPLACE(@ItemName,')','')
		SET @ItemName = REPLACE(@ItemName,'-','')
		
		IF(@IsReport = 0)
		BEGIN
			SET @ItemName = @ItemName + '-' + @ItemSeq
		END

		IF(@ItemType = 'ORG_Organizations')
		BEGIN
			SET @FilterColumn = 'FOrgNo'
			--SET @ItemName = 'Z' + @ItemName
		END

		IF(@ItemType = 'BD_Department')
		BEGIN
			SET @FilterColumn = 'FDeptNo'
			--SET @ItemName = 'B' + @ItemName
		END

		IF(@ItemType = 'BD_Customer')
		BEGIN
			SET @FilterColumn = 'FCustNo'
			--SET @ItemName = 'K' + @ItemName
		END

		SET @SQL = 'ALTER TABLE #TEMP ADD ['+ @ItemName + '] DECIMAL(28,2)'
		EXECUTE(@SQL)

		SET @SQL='
		UPDATE  A 
		   SET  A.['+@ItemName+'] = B.FQty
		  FROM  #TEMP A
				INNER JOIN (SELECT FMaterialNo,FUnitNo,SUM(FQty)FQty
							  FROM #ALLMaterial 
							 WHERE '+@FilterColumn+' = '''+@ItemNo+'''
							 GROUP BY FMaterialNo,FUnitNo)B
				ON A.FMaterialNo = B.FMaterialNo AND A.FUnitNo = B.FUnitNo'
		EXECUTE(@SQL)

		--将列名计入到合计列
		SET @SUMSQL = @SUMSQL + ' + ISNULL(['+@ItemName+'],0)'

		FETCH NEXT FROM MyCursor INTO @ItemType,@ItemNo,@ItemName,@ItemSeq
	END
	CLOSE MyCursor
	DEALLOCATE MyCursor


	--创建合计列
	SET @SQL = 'ALTER TABLE #TEMP ADD [合计] DECIMAL(28,2)'
	EXECUTE(@SQL)
	--计算合计列
	
	EXECUTE(@SUMSQL)

	--更新物料名称，单位名称
	UPDATE  A
	   SET  A.FMaterialName = D.FNAME
	  FROM  #TEMP A
			LEFT JOIN T_BD_MATERIAL C
			ON A.FMaterialNo = C.FNUMBER AND C.FCREATEORGID = C.FUSEORGID
			LEFT JOIN T_BD_MATERIAL_L D
			ON C.FMATERIALID = D.FMATERIALID AND D.FLOCALEID = 2052
	UPDATE  A
	   SET  A.FUnitName = D.FNAME
	  FROM  #TEMP A
			LEFT JOIN T_BD_UNIT C
			ON A.FUnitNo = C.FNUMBER AND C.FCREATEORGID = C.FUSEORGID
			LEFT JOIN T_BD_UNIT_L D
			ON C.FUNITID = D.FUNITID AND D.FLOCALEID = 2052

	
	SELECT ROW_NUMBER() OVER(ORDER BY FMaterialSeq ASC) AS FIDENTITYID,* FROM #TEMP
	
	IF(@TempTable <> '')
	BEGIN
		SET @SQL = 'SELECT ROW_NUMBER() OVER(ORDER BY FMaterialSeq ASC) AS FIDENTITYID,* INTO '+@TempTable+' FROM #TEMP'
		EXECUTE(@SQL)
	END
END

