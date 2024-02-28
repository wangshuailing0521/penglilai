--������ٶ�����
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
	@NoGoodSpace INT = 15 --�ϻ����ڷ�Χ
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
		FStockName VARCHAR(255) DEFAULT '', --�ֿ�
		FMaterialId INT DEFAULT 0,
		FMaterialNo VARCHAR(255) DEFAULT '', --���ϱ���
		FMaterialName VARCHAR(255) DEFAULT '', --��������
		FSpecification VARCHAR(255) DEFAULT '', --����ͺ�
		FMaterialGroup VARCHAR(255) DEFAULT '', --���Ϸ���
		FCategoryID VARCHAR(255) DEFAULT '', --������
		FUnitName VARCHAR(255) DEFAULT '', --��λ����浥λ��
		FOutStockDay1 DECIMAL(28,10) DEFAULT 0,
		FOutStockDay2 DECIMAL(28,10) DEFAULT 0,
		FOutStockDay3 DECIMAL(28,10) DEFAULT 0,
		FOutStockDay4 DECIMAL(28,10) DEFAULT 0,
		FOutStockDay5 DECIMAL(28,10) DEFAULT 0,
		FOutStockDay6 DECIMAL(28,10) DEFAULT 0,
		FOutStockDay7 DECIMAL(28,10) DEFAULT 0,
		FOutStockDay8 DECIMAL(28,10) DEFAULT 0,
		FOutStockDay9 DECIMAL(28,10) DEFAULT 0,
		FOutStockDay10 DECIMAL(28,10) DEFAULT 0, --����
		FOutAvgBy10 DECIMAL(28,10) DEFAULT 0, --10�վ���������
		FOutAvgBy5 DECIMAL(28,10) DEFAULT 0, --5�վ���������
		FOutAvgByHand DECIMAL(28,10) DEFAULT 0, --�������������վ�����ֵ���ֹ�����
		FCurrentInventory DECIMAL(28,10) DEFAULT 0, --��ʱ��棨��浥λ��2023/10/10
		FPurQty1 DECIMAL(28,10) DEFAULT 0, --���쵽�����������أ�
		FPurQty2 DECIMAL(28,10) DEFAULT 0, --��2�쵽�����������أ�
		FPurQty3 DECIMAL(28,10) DEFAULT 0, --��3�쵽�����������أ�
		FPurQty4 DECIMAL(28,10) DEFAULT 0, --��2�쵽�����������أ�
		FPurQty5 DECIMAL(28,10) DEFAULT 0, --��2�쵽�����������أ�
		FPurQty6 DECIMAL(28,10) DEFAULT 0, --��2�쵽�����������أ�
		FPurQty7 DECIMAL(28,10) DEFAULT 0, --��2�쵽�����������أ�
		FPurQty8 DECIMAL(28,10) DEFAULT 0, --��2�쵽�����������أ�
		FPurQty9 DECIMAL(28,10) DEFAULT 0, --��2�쵽�����������أ�
		FPurQty10 DECIMAL(28,10) DEFAULT 0, --��2�쵽�����������أ�
		FPurQty11 DECIMAL(28,10) DEFAULT 0, --��2�쵽�����������أ�
		FPurQty12 DECIMAL(28,10) DEFAULT 0, --��2�쵽�����������أ�
		FPurQty13 DECIMAL(28,10) DEFAULT 0, --��2�쵽�����������أ�
		FPurQty14 DECIMAL(28,10) DEFAULT 0, --��2�쵽�����������أ�
		FPurQty15 DECIMAL(28,10) DEFAULT 0, --��2�쵽�����������أ�
		FPurQty16 DECIMAL(28,10) DEFAULT 0, --��2�쵽�����������أ�
		FInventoryDay1 DECIMAL(28,10) DEFAULT 0, --����Ԥ�ƿ��
		FInventoryDay2 DECIMAL(28,10) DEFAULT 0, --��2����
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
		FMaxOutStockBy10 DECIMAL(28,10) DEFAULT 0, --10�������ֵ(����)
		FNoGoodsDay VARCHAR(255) DEFAULT '', --�ϻ�����
		FSafeInventory DECIMAL(28,10) DEFAULT 0, --��ȫ�����������浥λ��
		FMinPurQty DECIMAL(28,10) DEFAULT 0, --��Ͳɹ�������ȡ����ֵ��
		FDeliveryDay VARCHAR(255) DEFAULT '', --������������ȡ����ֵ��
		FCanDeliveryDay DECIMAL(28,10) DEFAULT 0, --��ʱ���ɷ�������
		FDeliveryDay1 VARCHAR(255) DEFAULT '', --���²ɹ�������������
		FDeliveryDay1Qty DECIMAL(28,10) DEFAULT 0,--���²ɹ���������
		FDeliveryDay2 VARCHAR(255) DEFAULT '', 
		FDeliveryDay2Qty DECIMAL(28,10) DEFAULT 0,
		FDeliveryDay3 VARCHAR(255) DEFAULT '', 
		FDeliveryDay3Qty DECIMAL(28,10) DEFAULT 0,
		FReasonableDay VARCHAR(255) DEFAULT '',  --�����µ�����
		FHavePurOrder VARCHAR(255) DEFAULT '',  --�ϻ�����ǰ�Ƿ��вɹ�����
		FSuggestDay VARCHAR(255) DEFAULT '',  --�����µ�����
		FMaxGoodQty DECIMAL(28,10) DEFAULT 0, --���Ž�������
		FSuggestDeliveryDay VARCHAR(255) DEFAULT '',  --���鵽������
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
	--��ȡ����֮ǰ��ÿ��ĳ�������
	-------------------------------------------------------------------------------------------------------------------
	DECLARE @OutDayInt INT
	DECLARE @OutBeginDateTime DATETIME
	DECLARE @OutEndDateTime DATETIME

	
	SET @OutBeginDateTime = DATEADD(DAY,-10,@CurrentDay)
	SET @OutEndDateTime = DATEADD(DAY,1,@CurrentDay)

	--��ȡ���۳�������
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
	--��ȡֱ�ӵ�������
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
		
		----��ȡ���۳�������
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

		--��ȡֱ�ӵ�������
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
	--��ȡ10�������ֵ(����)
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
	--��ȡ����֮��15���ڣ�ÿ��Ŀ��
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
		--��2��Ŀ����=��ʱ���-5�վ���+���ղɹ���������������ʱ���ȡ����������С���������������ʾ��ɫ���ϻ����ڣ������������Դ����ƣ�                                         ���ڰ�ȫ�������������ʾ��ɫ�������µ����ڣ�

		SET @PurEndDateTime = DATEADD(DAY,@InDayInt + 1,@CurrentDay)
		--��ȡ����ɹ���������
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
							   AND  ISNULL(B.F_UNLF_LXBS,'''') <> ''2'' --���ز�
							   AND  A.FPurchaseOrgId = '+CONVERT(VARCHAR(10),@OrgId)+'
							   AND  BDP.FDELIVERYDATE >= '''+CONVERT(VARCHAR(10),DATEADD(DAY,-1,@PurEndDateTime),120)+'''
							   AND  BDP.FDELIVERYDATE < '''+CONVERT(VARCHAR(10),@PurEndDateTime,120)+'''
							 GROUP  BY A.FPurchaseOrgId,D.FNumber,C.FNUMBER) B
				ON A.FStockOrgId = B.FStockOrgId AND A.FStockNo = B.FStockNo AND A.FMaterialNo = B.FMaterialNo '
		EXECUTE (@SQL)
		
		--��ȡ������ �� ��ʱ���-5�վ���*����+�ۼƲɹ���������������ʱ���ȡ��
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
							   AND  ISNULL(B.F_UNLF_LXBS,'''') <> ''2'' --���ز�
							   AND  A.FPurchaseOrgId = '+CONVERT(VARCHAR(10),@OrgId)+'
							   AND  BDP.FDELIVERYDATE >= '''+CONVERT(VARCHAR(10),@PurBeginDateTime,120)+'''
							   AND  BDP.FDELIVERYDATE < '''+CONVERT(VARCHAR(10),@PurEndDateTime,120)+'''
							 GROUP  BY A.FPurchaseOrgId,D.FNumber,C.FNUMBER) B
				ON A.FStockOrgId = B.FStockOrgId AND A.FStockNo = B.FStockNo AND A.FMaterialNo = B.FMaterialNo '
		EXECUTE (@SQL)

		--���¶ϻ�����(���������10������󷢻�������)
		SET @SQL = 'UPDATE #TEMP SET FNoGoodsDay = '''+CONVERT(VARCHAR(10),DATEADD(DAY,@InDayInt,@CurrentDay),120) +''' 
					WHERE '+@InDayFileName+' < FMaxOutStockBy10 AND FNoGoodsDay = '''''
		EXECUTE (@SQL)

		SET @InDayInt = @InDayInt + 1
	END

	--�������²ɹ������������ڣ����²ɹ���������
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
	   AND  ISNULL(B.F_UNLF_LXBS,'') <> '2' --���ز�
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

	--��ȫ�������(5�վ�*��������)
	UPDATE #TEMP SET FDeliveryDay = 0 WHERE FDeliveryDay = ''
	UPDATE #TEMP SET FSafeInventory = FOutAvgBy5 * FDeliveryDay WHERE FDeliveryDay <> 0
	UPDATE #TEMP SET FSafeInventory = FOutAvgBy5  WHERE FDeliveryDay = 0
	--��ʱ���ɷ�������(��ʱ���/5�վ�����������ʾ��ɫ��)
	UPDATE #TEMP SET FCanDeliveryDay = FCurrentInventory / FOutAvgBy5 WHERE FOutAvgBy5 <> 0
	--�����µ�����(�ϻ����ڼ���������)
	UPDATE #TEMP SET FReasonableDay = CONVERT(VARCHAR(10), DATEADD(DAY,0 - FDeliveryDay,FNoGoodsDay) ,120) WHERE FNoGoodsDay <> ''
	--�ϻ�����ǰ�Ƿ��вɹ�����(�ֶ��޸�Ϊ�ɹ�����)
	UPDATE #TEMP SET FHavePurOrder = '��'
	
	UPDATE #TEMP SET FHavePurOrder = '��' 
	WHERE FNoGoodsDay <> '' AND DATEDIFF(DAY,GETDATE(),CONVERT(VARCHAR(10),FNoGoodsDay,120)) <= @NoGoodSpace
	--UPDATE #TEMP SET FHavePurOrder = '��' WHERE FNoGoodsDay <> ''
	--UPDATE #TEMP SET FHavePurOrder = '��' WHERE FNoGoodsDay <> '' AND FDeliveryDay1 <> '' AND FDeliveryDay1 <= FNoGoodsDay
	--�Ƿ��вɹ�����Ϊ��ʱ���������в���
	--�����µ�����(�����µ�����=MAX(�����µ����ڣ�����))
	UPDATE #TEMP SET FSuggestDay = FReasonableDay WHERE FHavePurOrder = '��'
	UPDATE #TEMP SET FSuggestDay = CONVERT(VARCHAR(10),GETDATE(),120) 
	  WHERE FHavePurOrder = '��' 
	    AND FReasonableDay <> '' AND CONVERT(DATETIME,FReasonableDay) < CONVERT(DATETIME,CONVERT(VARCHAR(10),GETDATE(),120))
	--���Ž�������
	UPDATE #TEMP SET FMaxGoodQty = FSafeInventory WHERE FHavePurOrder = '��'
	UPDATE #TEMP SET FMaxGoodQty = FMinPurQty WHERE FSafeInventory < FMinPurQty AND FHavePurOrder = '��'
	--���鵽������
	UPDATE #TEMP SET FSuggestDeliveryDay = CONVERT(VARCHAR(10),DATEADD(DAY,0 + FDeliveryDay,FSuggestDay),120)  WHERE FSuggestDay <> '' AND FHavePurOrder = '��'

	DELETE FROM #TEMP WHERE FOutAvgBy10 = 0

	SELECT * FROM #TEMP ORDER BY FStockId,FMaterialId
END
