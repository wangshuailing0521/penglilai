ALTER PROC sp_YJ_ProductReport
	@OrgNos VARCHAR(255) = '',
	@BeginTime VARCHAR(255) = '',
	@EndTime VARCHAR(255) = '',
	@MaterialNos VARCHAR(255) = '',
	@CustNos VARCHAR(255) = '',
	@LotNos VARCHAR(255) = ''
AS
BEGIN

	IF(@EndTime <> '')
	BEGIN
		SET @EndTime = CONVERT(VARCHAR(10),DATEADD(DAY,1,@EndTime),120) 
	END

	CREATE TABLE #TEMP(
		FRowType INT DEFAULT 0, --0:��ͨ���ݣ�1:�ϼ�����,2:�ܺϼ�
		FOrgID INT,
		FOrgName VARCHAR(255),
		FCustID INT,
		FCustName VARCHAR(255),
		FMaterialID INT,
		FMaterialNo VARCHAR(255),
		FMaterialName VARCHAR(255),
		FLotID INT, 
		FLotText VARCHAR(255), 
		FSUPPLYID INT DEFAULT 0,--��Ӧ��
		FCounterOrgID INT DEFAULT 0,--��Ӧ��֯

		FOutStockAmount DECIMAL(28,10) DEFAULT 0, --δ˰�����
		FOutStockRate DECIMAL(28,2) DEFAULT 0, --ռ�ܳ�����
		FOutStockRateString VARCHAR(255) DEFAULT '', --����ë����
		FPayAmount DECIMAL(28,10) DEFAULT 0, --δ˰�ɱ�
		FProfit DECIMAL(28,10) DEFAULT 0, --ë����
		FProfitRate DECIMAL(28,2) DEFAULT 0, --ռ��ë�����
		FProfitRateString VARCHAR(255) DEFAULT '', --����ë����

		FOldYearOutStockAmount DECIMAL(28,10) DEFAULT 0, --����ͬ�ڳ����
		FOldOutStockRate DECIMAL(28,2) DEFAULT 0, --δ˰�����ͬ��
		FOldOutStockRateString VARCHAR(255) DEFAULT '', --����ë����
		FOldMonthStockAmount DECIMAL(28,10) DEFAULT 0, --���³����
		FOldMonthOutStockRate DECIMAL(28,2) DEFAULT 0, --δ˰������
		FOldMonthOutStockRateString VARCHAR(255) DEFAULT '', --����ë����
		FOldYearPayAmount DECIMAL(28,10) DEFAULT 0, --����ͬ�ڳ���ɱ�
		FOldMonthPayAmount DECIMAL(28,10) DEFAULT 0, --����ͬ�ڳ���ɱ�

		FOldYearProfit DECIMAL(28,10) DEFAULT 0, --ë����
		FOldYearProfitRate DECIMAL(28,2) DEFAULT 0, --ë����ͬ��
		FOldYearProfitRateString VARCHAR(255) DEFAULT '', --����ë����
		FOldMonthProfit DECIMAL(28,10) DEFAULT 0, --����ë����
		FOldMonthProfitRate DECIMAL(28,2) DEFAULT 0, --ë�����
		FOldMonthProfitRateString VARCHAR(255) DEFAULT '', --����ë����

		FHandAmount DECIMAL(28,10) DEFAULT 0, --��������
		FJProfit DECIMAL(28,10) DEFAULT 0, --��ë����
	)

	-----------------------------------------------------------------------------------------------------------------
	--��ȡ��������
	-----------------------------------------------------------------------------------------------------------------
	SELECT  A.FSALEORGID,A.FCUSTOMERID,B.FMATERIALID,B.FLOT,B.FLOT_TEXT,ISNULL(D.FSUPPLYID,0)FSUPPLYID,0 FCounterOrgID
		    ,SUM(C.FAMOUNT)FAMOUNT,SUM(C.FCOSTAMOUNT)FCOSTAMOUNT,SUM(FREALQTY)FREALQTY,CUST.FNUMBER FCustNo,MAT.FNUMBER FMaterialNo,SUM(FBASEUNITQTY)FQTY,CONVERT(DECIMAL(28,10),0)FCurrentNoTaxPayAmount
	  INTO  #OutStock
	  FROM  T_SAL_OUTSTOCK A WITH(NOLOCK)
			INNER JOIN T_SAL_OUTSTOCKENTRY B WITH(NOLOCK)
			ON A.FID = B.FID
			INNER JOIN T_ORG_ORGANIZATIONS ORG WITH(NOLOCK)
			ON A.FSALEORGID = ORG.FORGID
			INNER JOIN T_SAL_OUTSTOCKENTRY_F C WITH(NOLOCK)
			ON B.FENTRYID = C.FENTRYID
			INNER JOIN T_BD_CUSTOMER CUST WITH(NOLOCK)
			ON A.FCUSTOMERID = CUST.FCUSTID
			INNER JOIN T_BD_MATERIAL MAT WITH(NOLOCK)
			ON B.FMATERIALID = MAT.FMATERIALID
			LEFT JOIN T_BD_LOTMASTER D WITH(NOLOCK)
			ON B.FLOT = D.FLOTID
	 WHERE  1=1
	   AND  ((A.FDATE >= @BeginTime AND @BeginTime <> '') OR @BeginTime = '')
	   AND  ((A.FDATE < @EndTime AND @EndTime <> '') OR @EndTime = '')
	   AND  ((@OrgNos <> '' AND (ORG.FNUMBER IN (SELECT value FROM sp_split(@OrgNos,','))) )OR @OrgNos = '')
	   AND  ((@CustNos <> '' AND (CUST.FNUMBER IN (SELECT value FROM sp_split(@CustNos,','))) )OR @CustNos = '')
	   AND  ((@MaterialNos <> '' AND (MAT.FNUMBER IN (SELECT value FROM sp_split(@MaterialNos,','))) )OR @MaterialNos = '')
	   AND  ((@LotNos <> '' AND (B.FLOT_TEXT IN (SELECT value FROM sp_split(@LotNos,','))) )OR @LotNos = '')
	 GROUP  BY A.FCUSTOMERID,B.FMATERIALID,B.FLOT,B.FLOT_TEXT,D.FSUPPLYID,A.FSALEORGID,CUST.FNUMBER,MAT.FNUMBER

	--IF(@LotNo <> '')
	--BEGIN
	--	DELETE FROM #OutStock WHERE ISNULL(FLOT_TEXT,'') <>  @LotNo
	--END

	--���ݹ�Ӧ�̻�ȡ��Ӧ��֯
	UPDATE A SET FCounterOrgID = B.FCorrespondOrgId FROM #OutStock A INNER JOIN T_BD_SUPPLIER B ON A.FSUPPLYID = B.FSUPPLIERID
	UPDATE A SET FMaterialNo = B.FNUMBER FROM #TEMP A INNER JOIN T_BD_MATERIAL B ON A.FMaterialID = B.FMaterialID 
	--��Ӧ��Ϊ�ڲ���Ӧ��ʱ����ȡ�ڲ���Ӧ�̶�Ӧ��˾�����۳���ɱ�
	--UPDATE #OutStock SET FCOSTAMOUNT = 0 WHERE FCounterOrgID <> 0
	UPDATE  A
	   SET  FCurrentNoTaxPayAmount = B.FCOSTPRICE * FQTY
	  FROM  #OutStock A
			INNER JOIN (SELECT A.FSALEORGID,F.FNUMBER FMaterialNo,B.FLOT_TEXT,MAX(C.FCOSTPRICE)FCOSTPRICE
						  FROM  T_SAL_OUTSTOCK A 
								INNER JOIN T_SAL_OUTSTOCKENTRY B
								ON A.FID = B.FID
								INNER JOIN T_SAL_OUTSTOCKENTRY_F C
								ON B.FENTRYID = C.FENTRYID
								INNER JOIN T_BD_MATERIAL F
								ON B.FMATERIALID = F.FMATERIALID 
						 GROUP  BY A.FSALEORGID,F.FNUMBER,B.FLOT_TEXT,B.FMATERIALID)B
			ON A.FCounterOrgID = B.FSALEORGID AND A.FLOT_TEXT = B.FLOT_TEXT AND A.FMaterialNo = B.FMaterialNo

	--����Ӧ��Ϊ�Ϻ�Ψ����ʵҵ���޹�˾���һ�ȡ�����ɱ�ʱ��ȡ�����ϵĲο��ɱ�
	UPDATE  A
	   SET  A.FCurrentNoTaxPayAmount = B.FREFCOST * A.FQTY
	  FROM  #OutStock A
			INNER JOIN T_BD_MATERIALSTOCK B
			ON A.FMaterialID = B.FMATERIALID
			INNER JOIN T_BD_SUPPLIER C
			ON A.FSUPPLYID = C.FSUPPLIERID
	 WHERE  C.FNUMBER = 'VEN00040'
	   AND  FCounterOrgID <> 0
	   AND  FCurrentNoTaxPayAmount = 0

	UPDATE #OutStock SET FCOSTAMOUNT = FCurrentNoTaxPayAmount WHERE FCurrentNoTaxPayAmount <> 0

	INSERT INTO #TEMP (FOrgID,FCustID,FMaterialID,FOutStockAmount,FPayAmount)
	SELECT FSALEORGID,FCUSTOMERID,FMATERIALID,SUM(FAMOUNT),SUM(FCOSTAMOUNT) 
	  FROM #OutStock 
	 GROUP BY FCUSTOMERID,FMATERIALID,FSALEORGID

	--����ë����
	UPDATE #TEMP SET FProfit = FOutStockAmount - FPayAmount

	-----------------------------------------------------------------------------------------------------------------
	--��ȡ����ͬ������
	-----------------------------------------------------------------------------------------------------------------
	DECLARE @OldYearBeginTime VARCHAR(255)
	DECLARE @OldYearEndTime VARCHAR(255)
	SET @OldYearBeginTime = CONVERT(VARCHAR(10),DATEADD(YEAR,-1,@BeginTime),120)
	SET @OldYearEndTime = CONVERT(VARCHAR(10),DATEADD(YEAR,-1,@EndTime),120)

	SELECT  A.FCUSTOMERID,B.FMATERIALID,B.FLOT,B.FLOT_TEXT,ISNULL(D.FSUPPLYID,0)FSUPPLYID,0 FCounterOrgID
		    ,SUM(C.FAMOUNT)FAMOUNT,SUM(C.FCOSTAMOUNT)FCOSTAMOUNT,SUM(FREALQTY)FREALQTY,CUST.FNUMBER FCustNo
	  INTO  #OldYearOutStock
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
	 WHERE  1=1
	   AND  ((A.FDATE >= @OldYearBeginTime AND @OldYearBeginTime <> '') OR @OldYearBeginTime = '')
	   AND  ((A.FDATE < @OldYearEndTime AND @OldYearEndTime <> '') OR @OldYearEndTime = '')
	   AND  ((@OrgNos <> '' AND (ORG.FNUMBER IN (SELECT value FROM sp_split(@OrgNos,','))) )OR @OrgNos = '')
	   AND  ((@CustNos <> '' AND (CUST.FNUMBER IN (SELECT value FROM sp_split(@CustNos,','))) )OR @CustNos = '')
	   AND  ((@MaterialNos <> '' AND (MAT.FNUMBER IN (SELECT value FROM sp_split(@MaterialNos,','))) )OR @MaterialNos = '')
	   AND  ((@LotNos <> '' AND (B.FLOT_TEXT IN (SELECT value FROM sp_split(@LotNos,','))) )OR @LotNos = '')
	 GROUP  BY A.FCUSTOMERID,B.FMATERIALID,B.FLOT,B.FLOT_TEXT,D.FSUPPLYID,CUST.FNUMBER

	--IF(@LotNo <> '')
	--BEGIN
	--	DELETE FROM #OldYearOutStock WHERE ISNULL(FLOT_TEXT,'') <>  @LotNo
	--END

	--���ݹ�Ӧ�̻�ȡ��Ӧ��֯
	UPDATE A SET FCounterOrgID = B.FCorrespondOrgId FROM #OldYearOutStock A INNER JOIN T_BD_SUPPLIER B ON A.FSUPPLYID = B.FSUPPLIERID
	--��Ӧ��Ϊ�ڲ���Ӧ��ʱ����ȡ�ڲ���Ӧ�̶�Ӧ��˾�����۳���ɱ�
	--UPDATE #OldYearOutStock SET FCOSTAMOUNT = 0 WHERE FCounterOrgID <> 0
	UPDATE  A
	   SET  FCOSTAMOUNT = B.FCOSTPRICE * FREALQTY
	  FROM  #OldYearOutStock A
			INNER JOIN (SELECT A.FSALEORGID,E.FNUMBER FCustNo,B.FLOT,B.FMATERIALID,MAX(C.FCOSTPRICE)FCOSTPRICE
						  FROM  T_SAL_OUTSTOCK A
								INNER JOIN T_SAL_OUTSTOCKENTRY B
								ON A.FID = B.FID
								INNER JOIN T_SAL_OUTSTOCKENTRY_F C
								ON B.FENTRYID = C.FENTRYID
								INNER JOIN T_BD_CUSTOMER E
								ON A.FCUSTOMERID = E.FCUSTID
						 GROUP  BY A.FSALEORGID,E.FNUMBER,B.FLOT,B.FMATERIALID)B
			ON A.FCounterOrgID = B.FSALEORGID AND A.FCustNo = B.FCustNo AND A.FLOT = B.FLOT AND A.FMaterialID = B.FMATERIALID

	UPDATE  A
	   SET  FOldYearOutStockAmount = B.FAMOUNT
	       ,FOldYearPayAmount = B.FCOSTAMOUNT
	  FROM  #TEMP A
			INNER JOIN (SELECT  FCUSTOMERID,FMATERIALID,SUM(FAMOUNT)FAMOUNT,SUM(FCOSTAMOUNT)FCOSTAMOUNT
						  FROM  #OldYearOutStock A WITH(NOLOCK)
						 GROUP  BY FCUSTOMERID,FMATERIALID
				)B
			ON A.FCustID = B.FCUSTOMERID AND A.FMaterialID = B.FMATERIALID

	UPDATE #TEMP SET FOldOutStockRate = FOutStockAmount / FOldYearOutStockAmount * 100 WHERE FOldYearOutStockAmount <> 0

	-----------------------------------------------------------------------------------------------------------------
	--��ȡ��������
	-----------------------------------------------------------------------------------------------------------------
	DECLARE @OldMonthBeginTime VARCHAR(255)
	DECLARE @OldMonthEndTime VARCHAR(255)
	SET @OldMonthBeginTime = CONVERT(VARCHAR(10),DATEADD(Month,-1,@BeginTime),120)
	SET @OldMonthEndTime = CONVERT(VARCHAR(10),DATEADD(Month,-1,@EndTime),120)

	SELECT  A.FCUSTOMERID,B.FMATERIALID,B.FLOT,B.FLOT_TEXT,ISNULL(D.FSUPPLYID,0)FSUPPLYID,0 FCounterOrgID
		    ,SUM(C.FAMOUNT)FAMOUNT,SUM(C.FCOSTAMOUNT)FCOSTAMOUNT,SUM(FREALQTY)FREALQTY,CUST.FNUMBER FCustNo
	  INTO  #OldMonthOutStock
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
	 WHERE  1=1
	   AND  ((A.FDATE >= @OldMonthBeginTime AND @OldMonthBeginTime <> '') OR @OldMonthBeginTime = '')
	   AND  ((A.FDATE < @OldMonthEndTime AND @OldMonthEndTime <> '') OR @OldMonthEndTime = '')
	   AND  ((@OrgNos <> '' AND (ORG.FNUMBER IN (SELECT value FROM sp_split(@OrgNos,','))) )OR @OrgNos = '')
	   AND  ((@CustNos <> '' AND (CUST.FNUMBER IN (SELECT value FROM sp_split(@CustNos,','))) )OR @CustNos = '')
	   AND  ((@MaterialNos <> '' AND (MAT.FNUMBER IN (SELECT value FROM sp_split(@MaterialNos,','))) )OR @MaterialNos = '')
	   AND  ((@LotNos <> '' AND (B.FLOT_TEXT IN (SELECT value FROM sp_split(@LotNos,','))) )OR @LotNos = '')
	 GROUP  BY A.FCUSTOMERID,B.FMATERIALID,B.FLOT,B.FLOT_TEXT,D.FSUPPLYID,CUST.FNUMBER

	--IF(@LotNo <> '')
	--BEGIN
	--	DELETE FROM #OldMonthOutStock WHERE ISNULL(FLOT_TEXT,'') <>  @LotNo
	--END

	--���ݹ�Ӧ�̻�ȡ��Ӧ��֯
	UPDATE A SET FCounterOrgID = B.FCorrespondOrgId FROM #OldMonthOutStock A INNER JOIN T_BD_SUPPLIER B ON A.FSUPPLYID = B.FSUPPLIERID
	--��Ӧ��Ϊ�ڲ���Ӧ��ʱ����ȡ�ڲ���Ӧ�̶�Ӧ��˾�����۳���ɱ�
	--UPDATE #OldMonthOutStock SET FCOSTAMOUNT = 0 WHERE FCounterOrgID <> 0
	UPDATE  A
	   SET  FCOSTAMOUNT = B.FCOSTPRICE * FREALQTY
	  FROM  #OldMonthOutStock A
			INNER JOIN (SELECT A.FSALEORGID,E.FNUMBER FCustNo,B.FLOT,B.FMATERIALID,MAX(C.FCOSTPRICE)FCOSTPRICE
						  FROM  T_SAL_OUTSTOCK A
								INNER JOIN T_SAL_OUTSTOCKENTRY B
								ON A.FID = B.FID
								INNER JOIN T_SAL_OUTSTOCKENTRY_F C
								ON B.FENTRYID = C.FENTRYID
								INNER JOIN T_BD_CUSTOMER E
								ON A.FCUSTOMERID = E.FCUSTID
						 WHERE  A.FDOCUMENTSTATUS = 'C'
						   AND  ((A.FDATE >= @BeginTime AND @BeginTime <> '') OR @BeginTime = '')
						   AND  ((A.FDATE < @EndTime AND @EndTime <> '') OR @EndTime = '')
						 GROUP  BY A.FSALEORGID,E.FNUMBER,B.FLOT,B.FMATERIALID)B
			ON A.FCounterOrgID = B.FSALEORGID AND A.FCustNo = B.FCustNo AND A.FLOT = B.FLOT AND A.FMaterialID = B.FMATERIALID

	UPDATE  A
	   SET  FOldMonthStockAmount = B.FAMOUNT
	       ,FOldMonthPayAmount = B.FCOSTAMOUNT
	  FROM  #TEMP A
			INNER JOIN (SELECT  FCUSTOMERID,FMATERIALID,SUM(FAMOUNT)FAMOUNT,SUM(FCOSTAMOUNT)FCOSTAMOUNT
						  FROM  #OldMonthOutStock A WITH(NOLOCK)
						 GROUP  BY FCUSTOMERID,FMATERIALID
				)B
			ON A.FCustID = B.FCUSTOMERID AND A.FMaterialID = B.FMATERIALID

	UPDATE #TEMP SET FOldMonthOutStockRate = FOutStockAmount / FOldMonthStockAmount * 100 WHERE FOldMonthStockAmount <> 0 
	
	--��ȡ�ͻ�,���ϣ���λ����
	UPDATE A SET FOrgName = B.FNAME FROM #TEMP A INNER JOIN T_ORG_ORGANIZATIONS_L B ON A.FOrgID = B.FOrgID AND B.FLOCALEID = 2052
	UPDATE A SET FCustName = B.FNAME FROM #TEMP A INNER JOIN T_BD_CUSTOMER_L B ON A.FCustID = B.FCUSTID AND B.FLOCALEID = 2052
	UPDATE A SET FMaterialNo = B.FNUMBER FROM #TEMP A INNER JOIN T_BD_MATERIAL B ON A.FMaterialID = B.FMaterialID 
	UPDATE A SET FMaterialName = B.FNAME FROM #TEMP A INNER JOIN T_BD_MATERIAL_L B ON A.FMaterialID = B.FMaterialID AND B.FLOCALEID = 2052

	INSERT INTO #TEMP(
		FRowType,FCustID,FCustName,FOutStockAmount,FPayAmount,FProfit
	   ,FOldYearOutStockAmount,FOldMonthStockAmount,FOldYearPayAmount,FOldMonthPayAmount
	   ,FOldYearProfit,FOldMonthProfit)
	SELECT  1,FCustID,FCustName + '�ϼ�', SUM(FOutStockAmount),SUM(FPayAmount),SUM(FProfit)
	       ,SUM(FOldYearOutStockAmount),SUM(FOldMonthStockAmount),SUM(FOldYearPayAmount),SUM(FOldMonthPayAmount)
		   ,SUM(FOldYearProfit),SUM(FOldMonthProfit)
	  FROM  #TEMP 
	 WHERE  FRowType = 0
	 GROUP  BY FCustID,FCustName

	INSERT INTO #TEMP(
		FRowType,FCustID,FCustName,FOutStockAmount,FPayAmount,FProfit
	   ,FOldYearOutStockAmount,FOldMonthStockAmount,FOldYearPayAmount,FOldMonthPayAmount
	   ,FOldYearProfit,FOldMonthProfit)
	SELECT  2,999999999,'�ܺϼ�',SUM(FOutStockAmount),SUM(FPayAmount),SUM(FProfit)
	       ,SUM(FOldYearOutStockAmount),SUM(FOldMonthStockAmount),SUM(FOldYearPayAmount),SUM(FOldMonthPayAmount)
		   ,SUM(FOldYearProfit),SUM(FOldMonthProfit)
	  FROM  #TEMP 
	WHERE  FRowType = 0

	UPDATE #TEMP SET FOutStockRate = FOutStockAmount / (SELECT FOutStockAmount FROM #TEMP WHERE FRowType = 2) * 100
	UPDATE #TEMP SET FProfitRate = FProfit / (SELECT FProfit FROM #TEMP WHERE FRowType = 2) * 100
	UPDATE #TEMP SET FOldOutStockRate = FOutStockAmount / FOldYearOutStockAmount * 100
	 WHERE FOldYearOutStockAmount <> 0
	UPDATE #TEMP SET FOldMonthOutStockRate = FOutStockAmount / FOldMonthStockAmount * 100
	 WHERE FOldMonthStockAmount <> 0
	UPDATE #TEMP SET FOldYearProfitRate = FProfit / FOldYearProfit * 100
	 WHERE FOldYearProfit <> 0
	UPDATE #TEMP SET FOldMonthProfitRate = FProfit / FOldMonthProfit * 100
	 WHERE FOldMonthProfit <> 0
	UPDATE #TEMP SET FJProfit = FProfit - FHandAmount

	UPDATE #TEMP SET FOutStockRateString = CONVERT(VARCHAR(255),FOutStockRate) + '%' WHERE FOutStockRate <> 0
	UPDATE #TEMP SET FProfitRateString = CONVERT(VARCHAR(255),FProfitRate) + '%' WHERE FProfitRate <> 0
	UPDATE #TEMP SET FOldOutStockRateString = CONVERT(VARCHAR(255),FOldOutStockRate) + '%' WHERE FOldOutStockRate <> 0
	UPDATE #TEMP SET FOldMonthOutStockRateString = CONVERT(VARCHAR(255),FOldMonthOutStockRate) + '%' WHERE FOldMonthOutStockRate <> 0
	UPDATE #TEMP SET FOldYearProfitRateString = CONVERT(VARCHAR(255),FOldYearProfitRate) + '%' WHERE FOldYearProfitRate <> 0
	UPDATE #TEMP SET FOldMonthProfitRateString = CONVERT(VARCHAR(255),FOldMonthProfitRate) + '%' WHERE FOldMonthProfitRate <> 0
	

	SELECT * FROM #TEMP ORDER BY FCustID ASC,FRowType ASC
END
