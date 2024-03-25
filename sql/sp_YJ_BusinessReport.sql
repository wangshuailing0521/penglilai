--经营分析报表
--EXEC sp_YJ_BusinessReport  '001','2024-02-01','2024-02-29','','','','否'
ALTER PROC sp_YJ_BusinessReport
	@OrgNos VARCHAR(255) = '',
	@BeginTime VARCHAR(255) = '',
	@EndTime VARCHAR(255) = '',
	@MaterialNos VARCHAR(255) = '',
	@CustNos VARCHAR(255) = '',
	@LotNos VARCHAR(255) = '',
	@Sum VARCHAR(255) = ''
AS
BEGIN

	IF(@EndTime <> '')
	BEGIN
		SET @EndTime = CONVERT(VARCHAR(10),DATEADD(DAY,1,@EndTime),120) 
	END

	CREATE TABLE #TEMP(
		FRowType INT DEFAULT 0, --0:普通数据，1:合计数据
		FOrgID INT,
		FOrgName VARCHAR(255),
		FDeptID INT,
		FDeptNo VARCHAR(255),
		FDeptName VARCHAR(255),
		FCustID INT,
		FCustNo VARCHAR(255),
		FCustName VARCHAR(255),
		FMaterialID INT,
		FMaterialNo VARCHAR(255),
		FMaterialName VARCHAR(255),
		FStockUnitID INT, --基本单位
		FBaseUnitID INT, --基本单位
		FUnitName VARCHAR(255),
		FLotID INT, 
		FLotText VARCHAR(255), 
		FSUPPLYID INT DEFAULT 0,--供应商
		FCounterOrgID INT DEFAULT 0,--对应组织
		FCurrentNoTaxPayAmount DECIMAL(28,10) DEFAULT 0, --未税成本
		FBaseQty DECIMAL(28,10) DEFAULT 0, --数量-盒
		FActQty DECIMAL(28,10) DEFAULT 0, --数量-盒
		FNoTaxRecAmount DECIMAL(28,10) DEFAULT 0, --未税收入
		FNoTaxPayAmount DECIMAL(28,10) DEFAULT 0, --未税成本
		FProfit DECIMAL(28,10) DEFAULT 0, --毛利额
		FProfitRate DECIMAL(28,2) DEFAULT 0, --毛利率
		FProfitRateString VARCHAR(255) DEFAULT '', --毛利率
		FNoTaxHandRecAmount DECIMAL(28,10) DEFAULT 0, --未税收入-促销补差
		FQDProfitRate DECIMAL(28,2) DEFAULT 0, --渠道毛利率
		FQDProfitRateString VARCHAR(255) DEFAULT '', --渠道毛利率

		FCCF DECIMAL(28,10) DEFAULT 0, --仓储费
		FWLF DECIMAL(28,10) DEFAULT 0, --物流费
		FYPF DECIMAL(28,10) DEFAULT 0, --样品费
		FBXF DECIMAL(28,10) DEFAULT 0, --报销费
		FJCF DECIMAL(28,10) DEFAULT 0, --检测费
		FBZF DECIMAL(28,10) DEFAULT 0, --包装费
		FJGF DECIMAL(28,10) DEFAULT 0, --加工费
		FSJF DECIMAL(28,10) DEFAULT 0, --设计费
		FKDF DECIMAL(28,10) DEFAULT 0, --快递费
		FZXF DECIMAL(28,10) DEFAULT 0, --装卸费
		FQGZF DECIMAL(28,10) DEFAULT 0, --清关杂费
		FFLF DECIMAL(28,10) DEFAULT 0, --返利
		FTGCX DECIMAL(28,10) DEFAULT 0, --推广促销
		FZK DECIMAL(28,10) DEFAULT 0, --账扣
		FQTF DECIMAL(28,10) DEFAULT 0, --其他
		FHTF DECIMAL(28,10) DEFAULT 0, --渠道费用合计

		FBusProfit DECIMAL(28,10) DEFAULT 0, --营业利润额
		FBusProfitRate DECIMAL(28,2) DEFAULT 0, --渠道营业利润率
		FBusProfitRateString VARCHAR(255) DEFAULT '', --渠道营业利润率
	)

	CREATE TABLE #AcctNo(
		FNumber VARCHAR(255))

	--获取销售出库数据
	INSERT INTO #TEMP (
		FOrgID,FCustID,FMaterialID,FStockUnitID,FBaseUnitID,FLotID,FLotText,FSUPPLYID
	   ,FBaseQty,FNoTaxRecAmount,FNoTaxPayAmount,FActQty,FCustNo,FDeptID,FDeptNo)
	SELECT  A.FSALEORGID,A.FCUSTOMERID,B.FMATERIALID,B.FUNITID,B.FBASEUNITID,B.FLOT,B.FLOT_TEXT,ISNULL(D.FSUPPLYID,0)
	       ,SUM(B.FBaseUnitQty),SUM(C.FAMOUNT),SUM(C.FCOSTAMOUNT),SUM(FREALQTY),CUST.FNUMBER,CUST.FSALDEPTID,E.FNUMBER 
	  FROM  T_SAL_OUTSTOCK A WITH(NOLOCK)
			INNER JOIN T_SAL_OUTSTOCKENTRY B WITH(NOLOCK)
			ON A.FID = B.FID
			INNER JOIN T_SAL_OUTSTOCKENTRY_F C WITH(NOLOCK)
			ON B.FENTRYID = C.FENTRYID
			INNER JOIN T_ORG_ORGANIZATIONS ORG WITH(NOLOCK)
			ON A.FSALEORGID = ORG.FORGID
			INNER JOIN T_BD_CUSTOMER CUST WITH(NOLOCK)
			ON A.FCUSTOMERID = CUST.FCUSTID
			INNER JOIN T_BD_MATERIAL MAT WITH(NOLOCK)
			ON B.FMATERIALID = MAT.FMATERIALID
			LEFT JOIN T_BD_LOTMASTER D WITH(NOLOCK)
			ON B.FLOT = D.FLOTID
			LEFT JOIN T_BD_DEPARTMENT E WITH(NOLOCK)
			ON CUST.FSALDEPTID = E.FDEPTID
	 WHERE  1=1
	   AND  ((A.FDATE >= @BeginTime AND @BeginTime <> '') OR @BeginTime = '')
	   AND  ((A.FDATE < @EndTime AND @EndTime <> '') OR @EndTime = '')
	   AND  ((@OrgNos <> '' AND (ORG.FNUMBER IN (SELECT value FROM sp_split(@OrgNos,','))) )OR @OrgNos = '')
	   AND  ((@CustNos <> '' AND (CUST.FNUMBER IN (SELECT value FROM sp_split(@CustNos,','))) )OR @CustNos = '')
	   AND  ((@MaterialNos <> '' AND (MAT.FNUMBER IN (SELECT value FROM sp_split(@MaterialNos,','))) )OR @MaterialNos = '')
	   AND  ((@LotNos <> '' AND (B.FLOT_TEXT IN (SELECT value FROM sp_split(@LotNos,','))) )OR @LotNos = '')
	   AND  CUST.FSALDEPTID <> 0
	 GROUP  BY A.FCUSTOMERID,B.FMATERIALID,B.FLOT,B.FLOT_TEXT,B.FBASEUNITID,D.FSUPPLYID,A.FSALEORGID,CUST.FNUMBER,B.FUNITID,CUST.FSALDEPTID,E.FNUMBER

	--获取凭证数据
	SELECT  B.FCURRENCYID
	       ,E.FNUMBER
		   ,D.FFLEX5 FDeptID
		   ,ISNULL(F.FCUSTID,0)FFLEX6
		   ,C.FACCOUNTORGID FACCTORGID
		   ,F.FNUMBER FCustNo
		   ,H.FNUMBER FDeptNo
		   ,CASE WHEN FDEBIT = 0 THEN 0 - FCREDIT ELSE FDEBIT END FAmount
		   ,A.FBILLNO
	  INTO  #VoucherDetail
	  FROM  T_GL_VOUCHER A WITH(NOLOCK)
			INNER JOIN T_GL_VOUCHERENTRY B WITH(NOLOCK)
			ON A.FVOUCHERID = B.FVOUCHERID
			INNER JOIN T_BD_ACCOUNTBOOK C WITH(NOLOCK)
			ON A.FACCOUNTBOOKID = C.FBOOKID
			INNER JOIN T_ORG_ORGANIZATIONS ORG WITH(NOLOCK)
			ON C.FACCOUNTORGID = ORG.FORGID
			INNER JOIN T_BD_FLEXITEMDETAILV D WITH(NOLOCK)
			ON B.FDETAILID = D.FID
			INNER JOIN T_BD_ACCOUNT E WITH(NOLOCK)
			ON B.FACCOUNTID = E.FACCTID
			INNER JOIN V_Gl_VoucherBizType G
			ON A.FSOURCEBILLKEY = G.FID
			LEFT JOIN T_BD_CUSTOMER F
			ON F.FSALDEPTID = D.FFLEX5 AND F.FUSEORGID = C.FACCOUNTORGID
			LEFT JOIN T_BD_DEPARTMENT H
			ON H.FDEPTID = D.FFLEX5 AND H.FUSEORGID = C.FACCOUNTORGID
	 WHERE  1=1
	   AND  (E.FNUMBER LIKE '6601.%' OR E.FNUMBER LIKE '6602.%' OR E.FNUMBER = '6603.04' OR E.FNUMBER = '6401.03')
	   AND  A.FDOCUMENTSTATUS = 'C'
	   AND  G.fnumber NOT IN ('GL_PLScheme','33742a8f-813c-4ca9-989c-650289fad2d1')
	   AND  ((A.FDATE >= @BeginTime AND @BeginTime <> '') OR @BeginTime = '')
	   AND  ((A.FDATE < @EndTime AND @EndTime <> '') OR @EndTime = '')
	   AND  ((@OrgNos <> '' AND (ORG.FNUMBER IN (SELECT value FROM sp_split(@OrgNos,','))) )OR @OrgNos = '')
	   AND  ((@CustNos <> '' AND (F.FNUMBER IN (SELECT value FROM sp_split(@CustNos,','))) )OR @CustNos = '')
	   AND  F.FSALDEPTID <> 0

	INSERT INTO #TEMP (FOrgID,FDeptNo)
	SELECT  DISTINCT A.FACCTORGID,A.FDeptNo
	  FROM  #VoucherDetail A
	 WHERE  FDeptNo NOT IN (SELECT FDeptNo FROM #TEMP)

	--IF(@LotNos <> '')
	--BEGIN
	--	DELETE FROM #TEMP WHERE ISNULL(FLotText,'') <>  @LotNos
	--END

	--根据供应商获取对应组织
	UPDATE A SET FCounterOrgID = B.FCorrespondOrgId FROM #TEMP A INNER JOIN T_BD_SUPPLIER B ON A.FSUPPLYID = B.FSUPPLIERID
	UPDATE A SET FMaterialNo = B.FNUMBER FROM #TEMP A INNER JOIN T_BD_MATERIAL B ON A.FMaterialID = B.FMaterialID 
	--供应商为内部供应商时，获取内部供应商对应公司的销售出库成本
	--UPDATE #TEMP SET FNoTaxPayAmount = 0 WHERE FCounterOrgID <> 0
	UPDATE  A
	   SET  FCurrentNoTaxPayAmount = B.FCostPrice * A.FBaseQty
	  FROM  #TEMP A
			INNER JOIN (SELECT A.FSALEORGID,B.FLOT_TEXT,F.FNUMBER FMaterialNo,MAX(C.FCOSTPRICE)FCostPrice
						  FROM  T_SAL_OUTSTOCK A WITH(NOLOCK)
								INNER JOIN T_SAL_OUTSTOCKENTRY B WITH(NOLOCK)
								ON A.FID = B.FID
								INNER JOIN T_SAL_OUTSTOCKENTRY_F C WITH(NOLOCK)
								ON B.FENTRYID = C.FENTRYID
								INNER JOIN T_BD_MATERIAL F
								ON B.FMATERIALID = F.FMATERIALID 
						 WHERE  A.FDOCUMENTSTATUS = 'C'
						 GROUP  BY A.FSALEORGID,B.FLOT_TEXT,F.FNUMBER)B
			ON  A.FCounterOrgID = B.FSALEORGID AND A.FLotText = B.FLOT_TEXT AND A.FMaterialNo = B.FMaterialNo
	 WHERE  FCounterOrgID <> 0

	--当供应商为上海唯佳利实业有限公司，且获取不到成本时，取物料上的参考成本
	UPDATE  A
	   SET  A.FCurrentNoTaxPayAmount = B.FREFCOST * A.FBaseQty
	  FROM  #TEMP A
			INNER JOIN T_BD_MATERIALSTOCK B
			ON A.FMaterialID = B.FMATERIALID
			INNER JOIN T_BD_SUPPLIER C
			ON A.FSUPPLYID = C.FSUPPLIERID
	 WHERE  C.FNUMBER = 'VEN00040'
	   AND  FCounterOrgID <> 0
	   AND  FCurrentNoTaxPayAmount = 0

	UPDATE #TEMP SET FNoTaxPayAmount = FCurrentNoTaxPayAmount WHERE FCurrentNoTaxPayAmount <> 0

	--获取客户,物料，单位名称
	UPDATE A SET FOrgName = B.FNAME FROM #TEMP A INNER JOIN T_ORG_ORGANIZATIONS_L B ON A.FOrgID = B.FOrgID AND B.FLOCALEID = 2052
	UPDATE A SET FCustName = B.FNAME FROM #TEMP A INNER JOIN T_BD_CUSTOMER_L B ON A.FCustID = B.FCUSTID AND B.FLOCALEID = 2052
	
	UPDATE A SET FMaterialName = B.FNAME FROM #TEMP A INNER JOIN T_BD_MATERIAL_L B ON A.FMaterialID = B.FMaterialID AND B.FLOCALEID = 2052
	UPDATE A SET FUnitName = B.FNAME FROM #TEMP A INNER JOIN T_BD_UNIT_L B ON A.FBaseUnitID = B.FUnitID AND B.FLOCALEID = 2052
	UPDATE A SET FDeptNo = B.FNUMBER FROM #TEMP A INNER JOIN T_BD_DEPARTMENT B ON A.FDeptID = B.FDEPTID 
	UPDATE A SET FDeptName = B.FNAME FROM #TEMP A INNER JOIN T_BD_DEPARTMENT_L B ON A.FDeptID = B.FDEPTID AND B.FLOCALEID = 2052
	

	---------------------------------------------------------------------------------------------------------------
	--计算客户小计
	---------------------------------------------------------------------------------------------------------------
	INSERT INTO #TEMP (FRowType,FOrgID,FOrgName, FDeptNo,FDeptName,FBaseQty,FNoTaxRecAmount,FNoTaxPayAmount,FNoTaxHandRecAmount)
	SELECT 1,FOrgID,FOrgName, FDeptNo,FDeptName + '合计',SUM(FBaseQty),SUM(FNoTaxRecAmount),SUM(FNoTaxPayAmount),SUM(FNoTaxHandRecAmount)
	  FROM #TEMP 
	 GROUP BY FDeptNo,FDeptName,FOrgID,FOrgName



	SELECT  FCURRENCYID,FNUMBER,FDeptNo,FFLEX6,FACCTORGID,FDeptID,SUM(FAmount)FDEBIT
	  INTO  #VoucherData
	  FROM  #VoucherDetail 
	 GROUP  BY FCURRENCYID,FNUMBER,FDeptNo,FFLEX6,FACCTORGID,FDeptID,FDeptNo

	--仓储费
	UPDATE  A
	   SET  A.FCCF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER IN ('6601.07','6601.29') 
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--物流费
	UPDATE  A
	   SET  A.FWLF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER IN ('6601.06','6601.27') 
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--物流费
	UPDATE  A
	   SET  A.FWLF = ISNULL(A.FWLF,0) + B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT  FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM  #VoucherData A
					     WHERE  FNUMBER = '6601.19'
						   AND  A.FDeptID <> 100244 --部门：美团
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--样品费
	UPDATE  A
	   SET  A.FYPF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER IN ('6401.03','6601.13') 
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--报销费用
	UPDATE  A
	   SET  A.FBXF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER IN ('6601.05','6602.08','6601.09','6602.09','6601.11','6601.25','6602.12') 
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--检测费
	UPDATE  A
	   SET  A.FJCF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER IN ('6601.14','6601.22') 
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--包装费
	UPDATE  A
	   SET  A.FBZF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER = '6601.15'
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--加工费
	UPDATE  A
	   SET  A.FJGF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER = '6601.20'
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--设计费
	UPDATE  A
	   SET  A.FSJF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER = '6601.16'
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--快递费
	UPDATE  A
	   SET  A.FKDF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER = '6601.17'
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--装卸费
	UPDATE  A
	   SET  A.FZXF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER = '6601.21'
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--清关杂费
	UPDATE  A
	   SET  A.FQGZF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER = '6601.28'
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--返利
	UPDATE  A
	   SET  A.FFLF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER = '6601.24'
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--推广促销
	UPDATE  A
	   SET  A.FTGCX = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER = '6601.08'
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--账扣
	UPDATE  A
	   SET  A.FZK = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT  FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM  #VoucherData A
					     WHERE  FNUMBER = '6601.19'
						   AND  A.FDeptID = 100244 --部门：美团
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--其他
	UPDATE  A
	   SET  A.FQTF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT,FACCTORGID 
						  FROM #VoucherData 
					     WHERE FNUMBER IN ('6601.12','6601.23','6603.04','6602.16') 
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	---------------------------------------------------------------------------------------------------------------
	--总合计
	---------------------------------------------------------------------------------------------------------------
	INSERT INTO #TEMP (
	 FRowType,FOrgID,FDeptNo,FDeptName,FBaseQty,FNoTaxRecAmount,FNoTaxPayAmount,FNoTaxHandRecAmount
	,FCCF,FWLF,FYPF,FBXF,FJCF,FBZF,FJGF,FSJF,FKDF,FZXF,FQGZF,FFLF,FTGCX,FZK,FQTF)
	SELECT 2,10000000,0,'总合计',SUM(FBaseQty),SUM(FNoTaxRecAmount),SUM(FNoTaxPayAmount),SUM(FNoTaxHandRecAmount)
	,SUM(FCCF),SUM(FWLF),SUM(FYPF),SUM(FBXF),SUM(FJCF),SUM(FBZF),SUM(FJGF),SUM(FSJF),SUM(FKDF),SUM(FZXF),SUM(FQGZF),SUM(FFLF),SUM(FTGCX),SUM(FZK),SUM(FQTF)
	  FROM #TEMP 
	 WHERE FRowType = 1

	---------------------------------------------------------------------------------------------------------------
	--计算利润
	---------------------------------------------------------------------------------------------------------------
	--计算毛利额
	UPDATE #TEMP SET FProfit = FNoTaxRecAmount - FNoTaxPayAmount

	--计算毛利率
	UPDATE #TEMP SET FProfitRate = FProfit / FNoTaxRecAmount * 100 WHERE FNoTaxRecAmount <> 0
	--计算渠道毛利率
	UPDATE #TEMP SET FQDProfitRate = (FNoTaxRecAmount + FNoTaxHandRecAmount - FNoTaxPayAmount) / (FNoTaxRecAmount + FNoTaxHandRecAmount) * 100
	WHERE (FNoTaxRecAmount + FNoTaxHandRecAmount) <> 0

	--渠道费用合计
	UPDATE #TEMP SET FHTF = FCCF + FWLF + FYPF + FBXF + FJCF + FBZF + FJGF + FSJF + FKDF + FZXF + FQGZF + FFLF + FTGCX + FZK + FQTF
	--营业利润额
	UPDATE #TEMP SET FBusProfit = FProfit + FNoTaxHandRecAmount - FHTF
	--渠道营业利润率
	UPDATE #TEMP SET FBusProfitRate = FBusProfit / (FNoTaxRecAmount + FNoTaxHandRecAmount) * 100
	WHERE (FNoTaxRecAmount + FNoTaxHandRecAmount) <> 0

	UPDATE #TEMP SET FProfitRateString = CONVERT(VARCHAR(255),FProfitRate) + '%' WHERE FProfitRate <> 0
	UPDATE #TEMP SET FQDProfitRateString = CONVERT(VARCHAR(255),FQDProfitRate) + '%' WHERE FQDProfitRate <> 0
	UPDATE #TEMP SET FBusProfitRateString = CONVERT(VARCHAR(255),FBusProfitRate) + '%' WHERE FBusProfitRate <> 0

	UPDATE #TEMP SET FCustName = FDeptName WHERE FCustName IS NULL

	IF(@Sum = '是')
	BEGIN

		UPDATE #TEMP SET FRowType = 3 WHERE FRowType = 1
		UPDATE #TEMP SET FRowType = 4 WHERE FRowType = 2

		SELECT * FROM #TEMP WHERE FRowType > 0 ORDER BY FOrgID ASC, FDeptNo DESC,FRowType ASC
	END
	ELSE
	BEGIN
		SELECT * FROM #TEMP ORDER BY FOrgID ASC,FDeptNo DESC,FRowType ASC,FCustID ASC
	END
	
END