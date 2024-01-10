using Kingdee.BOS;
using Kingdee.BOS.App.Data;
using Kingdee.BOS.Contracts;
using Kingdee.BOS.Contracts.Report;
using Kingdee.BOS.Core.Report;
using Kingdee.BOS.Orm.DataEntity;
using Kingdee.BOS.Orm.Metadata.DataEntity;
using Kingdee.BOS.Util;

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;

namespace YJ.PLL.CY.Bill.PlugIn
{
    [Description("车辆配送详单 报表插件")]
    [HotUpdate]
    public class VehicleSendDetailReport : SysReportBaseService
    {
         private string tempName;

        private List<string> fileNameList = new List<string>();

        public override void Initialize()
        {
            //设置零时表主键
            base.Initialize();
            this.ReportProperty.IdentityFieldName = "FIDENTITYID";
        }

        public override void BuilderReportSqlAndTempTable(IRptParams filter, string tableName)
        {
            base.BuilderReportSqlAndTempTable(filter, tableName);

            tempName = tableName;

            string date = "";
            string vehicleNo = "";
            
            DynamicObject customFilter = filter.FilterParameter.CustomFilter;

            if (customFilter["FDate"] != null)
            {
                date = Convert.ToDateTime(customFilter["FDate"]).ToString("yyyy-MM-dd");
            }

            if (customFilter["FVehicleNo"] != null)
            {
                vehicleNo = customFilter["FVehicleNo"].ToString();
            }

            string sql = string.Format("EXEC sp_YJ_VehicleSendDetail '{0}',{1},'{2}'", tempName, vehicleNo, date);

            DynamicObjectCollection table 
                = DBUtils.ExecuteDynamicObject(this.Context, sql);


            DynamicPropertyCollection dynamicObjectTypeColl = table.DynamicCollectionItemPropertyType.Properties;

            foreach (var dynamicObjectType in dynamicObjectTypeColl)
            {
                fileNameList.Add(dynamicObjectType.Name);
            }
            
        }

        public override ReportHeader GetReportHeaders(IRptParams filter)
        {
            ReportHeader header = new ReportHeader();

            int i = 1;
            int oldi = i;
            foreach (var fileName in fileNameList)
            {
                oldi = i;

                string fileLocalName = fileName;

                if (fileName == "FIDENTITYID")
                {
                    continue;
                }

                if (fileName == "FMaterialSeq")
                {
                    continue;
                }

                if (fileName == "FMaterialNo")
                {
                    continue;
                }

                if (fileName == "FUnitNo")
                {
                    continue;
                }

                if (fileName == "FMaterialName")
                {
                    fileLocalName = "品名";
                }

                if (fileName == "FUnitName")
                {
                    fileLocalName = "单位";
                }

                if (fileName == "合计")
                {
                    i = 100;
                }

                header.AddChild(fileName, new LocaleValue(fileLocalName));
                header.AddChild(fileName, new LocaleValue(fileLocalName)).ColIndex = i;

                i = oldi;

                i++;
            }

            return header;
        }

        public override void CloseReport()
        {
            base.CloseReport();

            IDBService dbService = Kingdee.BOS.App.ServiceHelper.GetService<IDBService>();
            dbService.DeleteTemporaryTableName(Context, new string[] { tempName });
        }
    }
}
