--��Ӫ��������
--EXEC sp_YJ_BusinessReport  '001','2024-02-01','2024-02-29','','','','��'
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
		FRowType INT DEFAULT 0, --0:��ͨ���ݣ�1:�ϼ�����
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
		FStockUnitID INT, --������λ
		FBaseUnitID INT, --������λ
		FUnitName VARCHAR(255),
		FLotID INT, 
		FLotText VARCHAR(255), 
		FSUPPLYID INT DEFAULT 0,--��Ӧ��
		FCounterOrgID INT DEFAULT 0,--��Ӧ��֯
		FCurrentNoTaxPayAmount DECIMAL(28,10) DEFAULT 0, --δ˰�ɱ�
		FBaseQty DECIMAL(28,10) DEFAULT 0, --����-��
		FActQty DECIMAL(28,10) DEFAULT 0, --����-��
		FNoTaxRecAmount DECIMAL(28,10) DEFAULT 0, --δ˰����
		FNoTaxPayAmount DECIMAL(28,10) DEFAULT 0, --δ˰�ɱ�
		FProfit DECIMAL(28,10) DEFAULT 0, --ë����
		FProfitRate DECIMAL(28,2) DEFAULT 0, --ë����
		FProfitRateString VARCHAR(255) DEFAULT '', --ë����
		FNoTaxHandRecAmount DECIMAL(28,10) DEFAULT 0, --δ˰����-��������
		FQDProfitRate DECIMAL(28,2) DEFAULT 0, --����ë����
		FQDProfitRateString VARCHAR(255) DEFAULT '', --����ë����

		FCCF DECIMAL(28,10) DEFAULT 0, --�ִ���
		FWLF DECIMAL(28,10) DEFAULT 0, --������
		FYPF DECIMAL(28,10) DEFAULT 0, --��Ʒ��
		FBXF DECIMAL(28,10) DEFAULT 0, --������
		FJCF DECIMAL(28,10) DEFAULT 0, --����
		FBZF DECIMAL(28,10) DEFAULT 0, --��װ��
		FJGF DECIMAL(28,10) DEFAULT 0, --�ӹ���
		FSJF DECIMAL(28,10) DEFAULT 0, --��Ʒ�
		FKDF DECIMAL(28,10) DEFAULT 0, --��ݷ�
		FZXF DECIMAL(28,10) DEFAULT 0, --װж��
		FQGZF DECIMAL(28,10) DEFAULT 0, --����ӷ�
		FFLF DECIMAL(28,10) DEFAULT 0, --����
		FTGCX DECIMAL(28,10) DEFAULT 0, --�ƹ����
		FZK DECIMAL(28,10) DEFAULT 0, --�˿�
		FQTF DECIMAL(28,10) DEFAULT 0, --����
		FHTF DECIMAL(28,10) DEFAULT 0, --�������úϼ�

		FBusProfit DECIMAL(28,10) DEFAULT 0, --Ӫҵ�����
		FBusProfitRate DECIMAL(28,2) DEFAULT 0, --����Ӫҵ������
		FBusProfitRateString VARCHAR(255) DEFAULT '', --����Ӫҵ������
	)

	CREATE TABLE #AcctNo(
		FNumber VARCHAR(255))

	--��ȡ���۳�������
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

	--��ȡƾ֤����
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

	--���ݹ�Ӧ�̻�ȡ��Ӧ��֯
	UPDATE A SET FCounterOrgID = B.FCorrespondOrgId FROM #TEMP A INNER JOIN T_BD_SUPPLIER B ON A.FSUPPLYID = B.FSUPPLIERID
	UPDATE A SET FMaterialNo = B.FNUMBER FROM #TEMP A INNER JOIN T_BD_MATERIAL B ON A.FMaterialID = B.FMaterialID 
	--��Ӧ��Ϊ�ڲ���Ӧ��ʱ����ȡ�ڲ���Ӧ�̶�Ӧ��˾�����۳���ɱ�
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

	--����Ӧ��Ϊ�Ϻ�Ψ����ʵҵ���޹�˾���һ�ȡ�����ɱ�ʱ��ȡ�����ϵĲο��ɱ�
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

	--��ȡ�ͻ�,���ϣ���λ����
	UPDATE A SET FOrgName = B.FNAME FROM #TEMP A INNER JOIN T_ORG_ORGANIZATIONS_L B ON A.FOrgID = B.FOrgID AND B.FLOCALEID = 2052
	UPDATE A SET FCustName = B.FNAME FROM #TEMP A INNER JOIN T_BD_CUSTOMER_L B ON A.FCustID = B.FCUSTID AND B.FLOCALEID = 2052
	
	UPDATE A SET FMaterialName = B.FNAME FROM #TEMP A INNER JOIN T_BD_MATERIAL_L B ON A.FMaterialID = B.FMaterialID AND B.FLOCALEID = 2052
	UPDATE A SET FUnitName = B.FNAME FROM #TEMP A INNER JOIN T_BD_UNIT_L B ON A.FBaseUnitID = B.FUnitID AND B.FLOCALEID = 2052
	UPDATE A SET FDeptNo = B.FNUMBER FROM #TEMP A INNER JOIN T_BD_DEPARTMENT B ON A.FDeptID = B.FDEPTID 
	UPDATE A SET FDeptName = B.FNAME FROM #TEMP A INNER JOIN T_BD_DEPARTMENT_L B ON A.FDeptID = B.FDEPTID AND B.FLOCALEID = 2052
	

	---------------------------------------------------------------------------------------------------------------
	--����ͻ�С��
	---------------------------------------------------------------------------------------------------------------
	INSERT INTO #TEMP (FRowType,FOrgID,FOrgName, FDeptNo,FDeptName,FBaseQty,FNoTaxRecAmount,FNoTaxPayAmount,FNoTaxHandRecAmount)
	SELECT 1,FOrgID,FOrgName, FDeptNo,FDeptName + '�ϼ�',SUM(FBaseQty),SUM(FNoTaxRecAmount),SUM(FNoTaxPayAmount),SUM(FNoTaxHandRecAmount)
	  FROM #TEMP 
	 GROUP BY FDeptNo,FDeptName,FOrgID,FOrgName



	SELECT  FCURRENCYID,FNUMBER,FDeptNo,FFLEX6,FACCTORGID,FDeptID,SUM(FAmount)FDEBIT
	  INTO  #VoucherData
	  FROM  #VoucherDetail 
	 GROUP  BY FCURRENCYID,FNUMBER,FDeptNo,FFLEX6,FACCTORGID,FDeptID,FDeptNo

	--�ִ���
	UPDATE  A
	   SET  A.FCCF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER IN ('6601.07','6601.29') 
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--������
	UPDATE  A
	   SET  A.FWLF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER IN ('6601.06','6601.27') 
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--������
	UPDATE  A
	   SET  A.FWLF = ISNULL(A.FWLF,0) + B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT  FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM  #VoucherData A
					     WHERE  FNUMBER = '6601.19'
						   AND  A.FDeptID <> 100244 --���ţ�����
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--��Ʒ��
	UPDATE  A
	   SET  A.FYPF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER IN ('6401.03','6601.13') 
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--��������
	UPDATE  A
	   SET  A.FBXF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER IN ('6601.05','6602.08','6601.09','6602.09','6601.11','6601.25','6602.12') 
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--����
	UPDATE  A
	   SET  A.FJCF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER IN ('6601.14','6601.22') 
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--��װ��
	UPDATE  A
	   SET  A.FBZF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER = '6601.15'
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--�ӹ���
	UPDATE  A
	   SET  A.FJGF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER = '6601.20'
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--��Ʒ�
	UPDATE  A
	   SET  A.FSJF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER = '6601.16'
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--��ݷ�
	UPDATE  A
	   SET  A.FKDF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER = '6601.17'
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--װж��
	UPDATE  A
	   SET  A.FZXF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER = '6601.21'
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--����ӷ�
	UPDATE  A
	   SET  A.FQGZF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER = '6601.28'
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--����
	UPDATE  A
	   SET  A.FFLF = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER = '6601.24'
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--�ƹ����
	UPDATE  A
	   SET  A.FTGCX = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM #VoucherData 
					     WHERE FNUMBER = '6601.08'
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--�˿�
	UPDATE  A
	   SET  A.FZK = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT  FDeptNo,SUM(FDEBIT)FDEBIT ,FACCTORGID
						  FROM  #VoucherData A
					     WHERE  FNUMBER = '6601.19'
						   AND  A.FDeptID = 100244 --���ţ�����
						 GROUP BY FDeptNo,FACCTORGID) B
			ON A.FDeptNo = B.FDeptNo AND A.FOrgID = B.FACCTORGID
	 WHERE  A.FRowType = 1

	--����
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
	--�ܺϼ�
	---------------------------------------------------------------------------------------------------------------
	INSERT INTO #TEMP (
	 FRowType,FOrgID,FDeptNo,FDeptName,FBaseQty,FNoTaxRecAmount,FNoTaxPayAmount,FNoTaxHandRecAmount
	,FCCF,FWLF,FYPF,FBXF,FJCF,FBZF,FJGF,FSJF,FKDF,FZXF,FQGZF,FFLF,FTGCX,FZK,FQTF)
	SELECT 2,10000000,0,'�ܺϼ�',SUM(FBaseQty),SUM(FNoTaxRecAmount),SUM(FNoTaxPayAmount),SUM(FNoTaxHandRecAmount)
	,SUM(FCCF),SUM(FWLF),SUM(FYPF),SUM(FBXF),SUM(FJCF),SUM(FBZF),SUM(FJGF),SUM(FSJF),SUM(FKDF),SUM(FZXF),SUM(FQGZF),SUM(FFLF),SUM(FTGCX),SUM(FZK),SUM(FQTF)
	  FROM #TEMP 
	 WHERE FRowType = 1

	---------------------------------------------------------------------------------------------------------------
	--��������
	---------------------------------------------------------------------------------------------------------------
	--����ë����
	UPDATE #TEMP SET FProfit = FNoTaxRecAmount - FNoTaxPayAmount

	--����ë����
	UPDATE #TEMP SET FProfitRate = FProfit / FNoTaxRecAmount * 100 WHERE FNoTaxRecAmount <> 0
	--��������ë����
	UPDATE #TEMP SET FQDProfitRate = (FNoTaxRecAmount + FNoTaxHandRecAmount - FNoTaxPayAmount) / (FNoTaxRecAmount + FNoTaxHandRecAmount) * 100
	WHERE (FNoTaxRecAmount + FNoTaxHandRecAmount) <> 0

	--�������úϼ�
	UPDATE #TEMP SET FHTF = FCCF + FWLF + FYPF + FBXF + FJCF + FBZF + FJGF + FSJF + FKDF + FZXF + FQGZF + FFLF + FTGCX + FZK + FQTF
	--Ӫҵ�����
	UPDATE #TEMP SET FBusProfit = FProfit + FNoTaxHandRecAmount - FHTF
	--����Ӫҵ������
	UPDATE #TEMP SET FBusProfitRate = FBusProfit / (FNoTaxRecAmount + FNoTaxHandRecAmount) * 100
	WHERE (FNoTaxRecAmount + FNoTaxHandRecAmount) <> 0

	UPDATE #TEMP SET FProfitRateString = CONVERT(VARCHAR(255),FProfitRate) + '%' WHERE FProfitRate <> 0
	UPDATE #TEMP SET FQDProfitRateString = CONVERT(VARCHAR(255),FQDProfitRate) + '%' WHERE FQDProfitRate <> 0
	UPDATE #TEMP SET FBusProfitRateString = CONVERT(VARCHAR(255),FBusProfitRate) + '%' WHERE FBusProfitRate <> 0

	UPDATE #TEMP SET FCustName = FDeptName WHERE FCustName IS NULL

	IF(@Sum = '��')
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