using Kingdee.BOS.App.Data;
using Kingdee.BOS.Contracts.Report;
using Kingdee.BOS.Core.CommonFilter;
using Kingdee.BOS.Core.Metadata.FieldElement;
using Kingdee.BOS.Core.Report;
using Kingdee.BOS.Core.Report.PlugIn;
using Kingdee.BOS.Model.ReportFilter;
using Kingdee.BOS.Orm.DataEntity;
using Kingdee.BOS.ServiceHelper;
using Kingdee.BOS.Util;
using Kingdee.K3.FIN.HS.App.Report;
using Kingdee.K3.FIN.HS.Report.PlugIn;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;

namespace YJ.PLL.CY.Bill.PlugIn
{
    [Description("存货收发存汇总表 报表插件")]
    [HotUpdate]
    public class InOutStockSummaryReport : SysReportBaseService
        //SysReportBaseService
    {
        private string tempName;
        List<string> orgIdList = new List<string>();

        public override void Initialize()
        {
            base.Initialize();

            base.ReportProperty.DspInsteadColumnsInfo.DefaultDspInsteadColumns = new Dictionary<string, string>();
            base.ReportProperty.DspInsteadColumnsInfo.DefaultDspInsteadColumns.Add("FMATERIALBASEID", "FMATERIALID");
            base.ReportProperty.DspInsteadColumnsInfo.DefaultDspInsteadColumns.Add("FSTOCKID", "FSTOCKNAME");
        }
         

        public override void BuilderReportSqlAndTempTable(IRptParams filter, string tableName)
        {
            base.BuilderReportSqlAndTempTable(filter, tableName);

            tempName = tableName;
            DynamicObject customFilter = filter.FilterParameter.CustomFilter;

            //组织
            orgIdList = new List<string>();
            if (customFilter["FAcctgOrgIds"] != null)
            {
                DynamicObjectCollection orgList = customFilter["FAcctgOrgIds"] as DynamicObjectCollection;
                foreach (DynamicObject item in orgList)
                {
                    DynamicObject org = item["FAcctgOrgIds"] as DynamicObject;
                    orgIdList.Add(Convert.ToString(org["Id"]));
                }
            }

            if (orgIdList.Count <= 0)
            {
                DynamicObject org = customFilter["AcctgOrgId"] as DynamicObject;
                orgIdList.Add(Convert.ToString(org["Id"]));
            }

            int i = 0;
            string sql = "";
            string interfaceTableName = "YJ" + DateTime.Now.ToString("yyMMddHHmmss");
            foreach (var orgId in orgIdList)
            {
                i++;
                ReportData reportData = (ReportData)GetData(filter, orgId);
                if (i<=1)
                {
                     sql = string.Format(@"/*dialect*/ 
                        SELECT {2} AS FFilterOrgId,*
                        INTO {0} FROM {1}", interfaceTableName, reportData.DataSource.TableName, orgId);
                    DBUtils.Execute(this.Context, sql); 
                }
                if (i > 1)
                {
                     sql = string.Format(@"/*dialect*/ 
                        INSERT INTO {0} (
                               FFilterOrgId,FACCTGID,FMATERIALBASEID,FMATERIALID,FMATERIALNAME,FMATERIALGROUP,FMODEL,FLOTNO,FASSIPROPERTYID
                              ,FMATERPROPERTY,FMATERTYPE,FBOMNO,FPLANNO,FSEQUENCENO,FPROJECTNO,FOWNERID,FOWNERNAME,FSTOCKORGID
	                          ,FSTOCKORGNAME,FSTOCKID,FSTOCKNAME,FSTOCKPLACEID,FSTOCKPLACENAME,FACCTGRANGEID,FACCTGRANGENAME,FUNITNAME
	                          ,FUNITID,FINITQTY,FINITPRICE,FINITAMOUNT,FRECEIVEQTY,FRECEIVEPRICE,FRECEIVEAMOUNT,FSENDAMOUNT,FENDQTY,FENDPRICE
	                          ,FENDAMOUNT,FSTOCKSTATUSID,FSTOCKSTATUSNAME,FDIMID,FACCTGDIMID,FASSIPROPNAME,FDIGITS,FQTYDIGITS
	                          ,FPRICEDIGITS,FVALUATION,FISTOTAL,FGROUPBYFIELD,FDETAILREPORTFORMID,FIDENTITYID)
                        SELECT {2},FACCTGID,FMATERIALBASEID,FMATERIALID,FMATERIALNAME,FMATERIALGROUP,FMODEL,FLOTNO,FASSIPROPERTYID
                              ,FMATERPROPERTY,FMATERTYPE,FBOMNO,FPLANNO,FSEQUENCENO,FPROJECTNO,FOWNERID,FOWNERNAME,FSTOCKORGID
	                          ,FSTOCKORGNAME,FSTOCKID,FSTOCKNAME,FSTOCKPLACEID,FSTOCKPLACENAME,FACCTGRANGEID,FACCTGRANGENAME,FUNITNAME
	                          ,FUNITID,FINITQTY,FINITPRICE,FINITAMOUNT,FRECEIVEQTY,FRECEIVEPRICE,FRECEIVEAMOUNT,FSENDAMOUNT,FENDQTY,FENDPRICE
	                          ,FENDAMOUNT,FSTOCKSTATUSID,FSTOCKSTATUSNAME,FDIMID,FACCTGDIMID,FASSIPROPNAME,FDIGITS,FQTYDIGITS
	                          ,FPRICEDIGITS,FVALUATION,FISTOTAL,FGROUPBYFIELD,FDETAILREPORTFORMID,FIDENTITYID 
                          FROM {1}", interfaceTableName, reportData.DataSource.TableName,orgId);
                    DBUtils.Execute(this.Context, sql);
                }

                sql = string.Format(@"/*dialect*/ 
                        DROP TABLE {0}"
                    , reportData.DataSource.TableName);
                DBUtils.Execute(this.Context, sql);
            }

            sql = string.Format(@"/*dialect*/ 
                SELECT ROW_NUMBER() OVER(ORDER BY FFilterOrgId,FIDENTITYID ASC) FNEWSEQ,* INTO {0} FROM {1}
                UPDATE {0} SET FIDENTITYID = FNEWSEQ
                DROP TABLE {1}
                SELECT * INTO {1} FROM {0}
                DROP TABLE {0}
                ", interfaceTableName + "1", interfaceTableName);
            DBUtils.Execute(this.Context, sql);


            sql = string.Format(@"/*dialect*/ 
                SELECT * INTO {0} FROM {1}
                DROP TABLE {1}
                ", tableName, interfaceTableName);
            DBUtils.Execute(this.Context, sql); 
        }

        public override ReportTitles GetReportTitles(IRptParams filter)
        {
            //return base.GetReportTitles(filter);

            ReportTitles titles = new ReportTitles(); 
            DynamicObject dyFilter = filter.FilterParameter.CustomFilter;
            titles.AddTitle("FACCTGSYSTEMNAME", "");
            titles.AddTitle("FACCTGORGNAME", "");
            titles.AddTitle("FACCTPOLICYNAME", "");
            titles.AddTitle("FPERIOD", "");
            titles.AddTitle("FCURRENCYID", "");
            return titles; 
        }

        /// <summary>
        /// IMoveRepor
        /// </summary>
        IReportData GetData(IRptParams oldFilter,string orgId)
        {
            var filterMetadata = FormMetaDataCache.GetCachedFilterMetaData(this.Context);
            //加载存货收发存汇总表元数据
            var reportMetadata = FormMetaDataCache.GetCachedFormMetaData(this.Context, "HS_INOUTSTOCKSUMMARYRPT");
            //加载存货收发存汇总表过滤条件元数据。
            var reportFilterMetadata = FormMetaDataCache.GetCachedFormMetaData(this.Context, "HS_INOUTSTOCKSUMMARYFILTER");
            var reportFilterServiceProvider = reportFilterMetadata.BusinessInfo.GetForm().GetFormServiceProvider();

            var model = new SysReportFilterModel();
            model.SetContext(this.Context, reportFilterMetadata.BusinessInfo, reportFilterServiceProvider);
            model.FormId = reportFilterMetadata.BusinessInfo.GetForm().Id;
            model.FilterObject.FilterMetaData = filterMetadata;
            model.InitFieldList(reportMetadata, reportFilterMetadata);
            model.GetSchemeList();

            //过滤方案的主键值，可通过该SQL语句查询得到：SELECT * FROM T_BAS_FILTERSCHEME
            var entity = model.Load("e271bf0a7e474513a19f07cc863b211c");

            //FilterParameter filter = model.GetFilterParameter();
            //filter = oldFilter.FilterParameter;
            DynamicObject customFilter = oldFilter.FilterParameter.CustomFilter;
            DynamicObject ACCTGORGID = customFilter["ACCTGORGID"] as DynamicObject;
            DynamicObject[] results = BusinessDataServiceHelper.Load(
                this.Context, new[] { orgId }, ACCTGORGID.DynamicObjectType);
            customFilter["ACCTGORGID_Id"] = orgId;
            customFilter["ACCTGORGID"] = results[0];

            #region
            //newCustomFilter["ACCTGSYSTEMID_Id"] = customFilter["ACCTGSYSTEMID_Id"];
            //newCustomFilter["ACCTGSYSTEMID"] = customFilter["ACCTGSYSTEMID"];



            //newCustomFilter["ACCTPOLICYID_Id"] = customFilter["ACCTPOLICYID_Id"];
            //newCustomFilter["ACCTPOLICYID"] = customFilter["ACCTPOLICYID"];

            //newCustomFilter["Year"] = customFilter["Year"];
            //newCustomFilter["EndYear"] = customFilter["EndYear"];
            //newCustomFilter["Period"] = customFilter["Period"];
            //newCustomFilter["EndPeriod"] = customFilter["EndPeriod"];

            //newCustomFilter["MATERIALID_Id"] = customFilter["MATERIALID_Id"];
            //newCustomFilter["MATERIALID"] = customFilter["MATERIALID"];
            //newCustomFilter["ENDMATERIALID_Id"] = customFilter["ENDMATERIALID_Id"];
            //newCustomFilter["ENDMATERIALID"] = customFilter["ENDMATERIALID"];


            //newCustomFilter["COMBOTotalType"] = customFilter["COMBOTotalType"];//汇总依据
            //newCustomFilter["FDimType"] = customFilter["FDimType"];//显示维度
            //newCustomFilter["CHXEXPENSE"] = customFilter["CHXEXPENSE"];//显示费用项目明细
            //newCustomFilter["CHXTotal"] = customFilter["CHXTotal"];//只显示汇总行
            //newCustomFilter["CHXNOINOUT"] = customFilter["CHXNOINOUT"];//无收发不显示
            //newCustomFilter["CHXNOCOSTALLOT"] = customFilter["CHXNOCOSTALLOT"];//不统计核算组织内调拨单据
            //newCustomFilter["IsDisplayPeriod"] = customFilter["IsDisplayPeriod"];//显示各期间明细
            //newCustomFilter["CHXNOSTOCKADJ"] = customFilter["CHXNOSTOCKADJ"];//不统计库存调整单据
            #endregion

            //IRptParams rptParam = new RptParams();
            //rptParam.FormId = reportFilterMetadata.BusinessInfo.GetForm().Id;
            //rptParam.StartRow = 1;
            //rptParam.EndRow = int.MaxValue;//StartRow和EndRow是报表数据分页的起始行数和截至行数，一般取所有数据，所以EndRow取int最大值。
            //rptParam.FilterParameter = filter;
            //rptParam.FilterFieldInfo = oldFilter.FilterFieldInfo;

            //p.CustomParams.Add("OpenParameter", "");
            //rptParam.BaseDataTempTable.AddRange(
            //    permissionService.GetBaseDataTempTable(this.Context, reportMetadata.BusinessInfo.GetForm().Id));
            
            MoveReportServiceParameter param = new MoveReportServiceParameter(
                this.Context, reportMetadata.BusinessInfo, Guid.NewGuid().ToString(), oldFilter);
            return SysReportServiceHelper.GetReportData(param);

            //using (DataTable dt = sysReporSservice.GetData(this.Context, reportMetadata.BusinessInfo, rptParam))
            //{
                ////dt就是报表数据，接下来就是你发挥的时间。
            //}

            //ServiceFactory.CloseService(sysReporSservice);
            //ServiceFactory.CloseService(permissionService);
        
        }
    }
}
