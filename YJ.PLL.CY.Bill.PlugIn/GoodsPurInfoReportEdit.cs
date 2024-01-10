using Kingdee.BOS;
using Kingdee.BOS.App.Data;
using Kingdee.BOS.Core.Bill.PlugIn;
using Kingdee.BOS.Core.DynamicForm.PlugIn.Args;
using Kingdee.BOS.Core.DynamicForm.PlugIn.ControlModel;
using Kingdee.BOS.Core.Metadata.FieldElement;
using Kingdee.BOS.Core.Metadata.PreInsertData;
using Kingdee.BOS.Orm.DataEntity;
using Kingdee.BOS.ServiceHelper;
using Kingdee.BOS.Util;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


namespace YJ.PLL.CY.Bill.PlugIn
{
    [Description("货物跟踪订货表")]
    [HotUpdate]
    public class GoodsPurInfoReportEdit : AbstractBillPlugIn
    {
        public override void AfterBindData(EventArgs e)
        {
            base.AfterBindData(e);

            SetCellsColor();
        }

        public override void AfterButtonClick(AfterButtonClickEventArgs e)
        {
            base.AfterButtonClick(e);

            if (e.Key.EqualsIgnoreCase("FSearch"))
            {
                ClearThisBill();
                RefreshData();
                SetCellsColor();
                this.View.UpdateView();
            }

            if (e.Key.EqualsIgnoreCase("FJSData"))
            {
                JSData();
                SetCellsColor();
                this.View.UpdateView();
                View.ShowMessage("计算完毕");
            }
        }


        void RefreshData()
        {
            int orgId = 0;
            string materialNos = "";
            string materialGroupNos = "";
            string categoryNos = "";
            string stockNos = "";
            string inStockNos = "";

            DynamicObject billObj = this.Model.DataObject;

            string date = Convert.ToDateTime(billObj["FDate"]).ToString("yyyy-MM-dd");

            DynamicObject org = billObj["FOrgId"] as DynamicObject;
            if (org == null)
            {
                throw new Exception("组织不能为空");
            }
            orgId = Convert.ToInt32(org["Id"]);

            //物料
            List<string> materialNoList = new List<string>();
            if (billObj["FHeadMaterialIds"] != null)
            {
                DynamicObjectCollection materialList = billObj["FHeadMaterialIds"] as DynamicObjectCollection;
                foreach (DynamicObject item in materialList)
                {
                    DynamicObject material = item["FHeadMaterialIds"] as DynamicObject;
                    materialNoList.Add(Convert.ToString(material["Number"]));
                }
            }
            materialNos = string.Join(",", materialNoList);

            //仓库
            List<string> stockNoList = new List<string>();
            if (billObj["FHeadStockIds"] != null)
            {
                DynamicObjectCollection stockList = billObj["FHeadStockIds"] as DynamicObjectCollection;
                foreach (DynamicObject item in stockList)
                {
                    DynamicObject stock = item["FHeadStockIds"] as DynamicObject;
                    stockNoList.Add(Convert.ToString(stock["Number"]));
                }
            }
            stockNos = string.Join(",", stockNoList);

            //调入仓库
            List<string> inStockNoList = new List<string>();
            if (billObj["FHeadInStockIds"] != null)
            {
                DynamicObjectCollection inStockList = billObj["FHeadInStockIds"] as DynamicObjectCollection;
                foreach (DynamicObject item in inStockList)
                {
                    DynamicObject inStock = item["FHeadInStockIds"] as DynamicObject;
                    inStockNoList.Add("'"+Convert.ToString(inStock["Number"])+"'");
                }
            }

            if (inStockNoList.Count > 0)
            {
                inStockNos = string.Format(" AND D.FNUMBER IN ({0}) ", string.Join(",", inStockNoList));
                inStockNos = inStockNos.Replace("'", "''");
            } 

            //物料分组
            if (billObj["FMaterialGroup"] != null)
            {
                materialGroupNos = Convert.ToString(((DynamicObject)billObj["FMaterialGroup"])["Number"]);
            }

            //存货类别
            List<string> categoryNoList = new List<string>();
            if (billObj["FCategoryIDs"] != null)
            {
                DynamicObjectCollection categoryList = billObj["FCategoryIDs"] as DynamicObjectCollection;
                foreach (DynamicObject item in categoryList)
                {
                    DynamicObject category = item["FCategoryIDs"] as DynamicObject;
                    categoryNoList.Add(Convert.ToString(category["Number"]));
                }
            }
            categoryNos = string.Join(",", categoryNoList);

            string sql = string.Format(
                "EXEC sp_YJ_GoodsPurInfo {0},'{1}','{2}','{3}','{4}','{5}','{6}'", orgId, date, materialNos, materialGroupNos, categoryNos, stockNos, inStockNos);
            
            DataSet ds = DBUtils.ExecuteDataSet(
                this.Context, sql);

            SetEntity(billObj, ds.Tables[0]);
        }

        /// <summary>
        /// 滞期费/速遣费
        /// </summary>
        /// <param name="billObj"></param>
        /// <param name="dt"></param>
        void SetEntity(DynamicObject billObj, DataTable dt)
        {
            if (dt.Rows.Count <= 0)
            {
                return;
            }

            DynamicObjectCollection entity = billObj["FEntity"] as DynamicObjectCollection;

            int seq = 1;

            foreach (DataRow dtRow in dt.Rows)
            {
                DynamicObject newEntry = new DynamicObject(entity.DynamicCollectionItemPropertyType);

                BaseDataField fldStock = this.View.BillBusinessInfo.GetField("FStockId") as BaseDataField;
                DynamicObject stockObj = BusinessDataServiceHelper.LoadFromCache(
                    this.Context, new object[] { dtRow["FStockId"] }, fldStock.RefFormDynamicObjectType).FirstOrDefault();
                fldStock.RefIDDynamicProperty.SetValue(newEntry, dtRow["FStockId"]);
                fldStock.DynamicProperty.SetValue(newEntry, stockObj);

                BaseDataField fldMaterial = this.View.BillBusinessInfo.GetField("FMaterialId") as BaseDataField;
                DynamicObject materialObj = BusinessDataServiceHelper.LoadFromCache(
                    this.Context, new object[] { dtRow["FMaterialId"] }, fldMaterial.RefFormDynamicObjectType).FirstOrDefault();
                fldMaterial.RefIDDynamicProperty.SetValue(newEntry, dtRow["FMaterialId"]);
                fldMaterial.DynamicProperty.SetValue(newEntry, materialObj);

                newEntry["Seq"] = seq;
                newEntry["FOutStockDay1"] = dtRow["FOutStockDay1"];
                newEntry["FOutStockDay2"] = dtRow["FOutStockDay2"];
                newEntry["FOutStockDay3"] = dtRow["FOutStockDay3"];
                newEntry["FOutStockDay4"] = dtRow["FOutStockDay4"];
                newEntry["FOutStockDay5"] = dtRow["FOutStockDay5"];
                newEntry["FOutStockDay6"] = dtRow["FOutStockDay6"];
                newEntry["FOutStockDay7"] = dtRow["FOutStockDay7"];
                newEntry["FOutStockDay8"] = dtRow["FOutStockDay8"];
                newEntry["FOutStockDay9"] = dtRow["FOutStockDay9"];
                newEntry["FOutStockDay10"] = dtRow["FOutStockDay10"];
                newEntry["FOutAvgBy10"] = dtRow["FOutAvgBy10"];
                newEntry["FOutAvgBy5"] = dtRow["FOutAvgBy5"];
                newEntry["FOutAvgByHand"] = dtRow["FOutAvgByHand"];
                newEntry["FCurrentInventory"] = dtRow["FCurrentInventory"];

                newEntry["FPurQty2"] = dtRow["FPurQty2"];
                newEntry["FPurQty3"] = dtRow["FPurQty3"];
                newEntry["FPurQty4"] = dtRow["FPurQty4"];
                newEntry["FPurQty5"] = dtRow["FPurQty5"];
                newEntry["FPurQty6"] = dtRow["FPurQty6"];
                newEntry["FPurQty7"] = dtRow["FPurQty7"];
                newEntry["FPurQty8"] = dtRow["FPurQty8"];
                newEntry["FPurQty9"] = dtRow["FPurQty9"];
                newEntry["FPurQty10"] = dtRow["FPurQty10"];
                newEntry["FPurQty11"] = dtRow["FPurQty11"];
                newEntry["FPurQty12"] = dtRow["FPurQty12"];
                newEntry["FPurQty13"] = dtRow["FPurQty13"];
                newEntry["FPurQty14"] = dtRow["FPurQty14"];
                newEntry["FPurQty15"] = dtRow["FPurQty15"];
                newEntry["FPurQty16"] = dtRow["FPurQty16"];

                newEntry["FInventoryDay2"] = dtRow["FInventoryDay2"];
                newEntry["FInventoryDay3"] = dtRow["FInventoryDay3"];
                newEntry["FInventoryDay4"] = dtRow["FInventoryDay4"];
                newEntry["FInventoryDay5"] = dtRow["FInventoryDay5"];
                newEntry["FInventoryDay6"] = dtRow["FInventoryDay6"];
                newEntry["FInventoryDay7"] = dtRow["FInventoryDay7"];
                newEntry["FInventoryDay8"] = dtRow["FInventoryDay8"];
                newEntry["FInventoryDay9"] = dtRow["FInventoryDay9"];
                newEntry["FInventoryDay10"] = dtRow["FInventoryDay10"];
                newEntry["FInventoryDay11"] = dtRow["FInventoryDay11"];
                newEntry["FInventoryDay12"] = dtRow["FInventoryDay12"];
                newEntry["FInventoryDay13"] = dtRow["FInventoryDay13"];
                newEntry["FInventoryDay14"] = dtRow["FInventoryDay14"];
                newEntry["FInventoryDay15"] = dtRow["FInventoryDay15"];
                newEntry["FInventoryDay16"] = dtRow["FInventoryDay16"];
                newEntry["FMaxOutStockBy10"] = dtRow["FMaxOutStockBy10"];
                newEntry["FNoGoodsDay"] = dtRow["FNoGoodsDay"];
                newEntry["FSafeInventory"] = dtRow["FSafeInventory"];
                newEntry["FMinPurQty"] = dtRow["FMinPurQty"];
                newEntry["FDeliveryDay"] = dtRow["FDeliveryDay"];
                newEntry["FCanDeliveryDay"] = dtRow["FCanDeliveryDay"];
                newEntry["FDeliveryDay1"] = dtRow["FDeliveryDay1"];
                newEntry["FDeliveryDay1Qty"] = dtRow["FDeliveryDay1Qty"];
                newEntry["FDeliveryDay2"] = dtRow["FDeliveryDay2"];
                newEntry["FDeliveryDay2Qty"] = dtRow["FDeliveryDay2Qty"];
                newEntry["FDeliveryDay3"] = dtRow["FDeliveryDay3"];
                newEntry["FDeliveryDay3Qty"] = dtRow["FDeliveryDay3Qty"];
                newEntry["FReasonableDay"] = dtRow["FReasonableDay"];
                newEntry["FHavePurOrder"] = dtRow["FHavePurOrder"];
                newEntry["FSuggestDay"] = dtRow["FSuggestDay"];
                newEntry["FMaxGoodQty"] = dtRow["FMaxGoodQty"];
                newEntry["FSuggestDeliveryDay"] = dtRow["FSuggestDeliveryDay"];
                

                entity.Add(newEntry);

                seq++;
            }
        }

        void ClearThisBill()
        {
            DynamicObject billObj = this.Model.DataObject;

            DynamicObjectCollection FEntity = billObj["FEntity"] as DynamicObjectCollection;
            FEntity.Clear();

        }

        /// <summary>
        /// 计算数据
        /// </summary>
        void JSData()
        {
            DynamicObject billObj = this.Model.DataObject;
            DynamicObjectCollection entity = billObj["FEntity"] as DynamicObjectCollection;

            //获取查询日期
            DateTime searchDate = Convert.ToDateTime(billObj["FDate"]);

            foreach (DynamicObject entry in entity)
            {
                //大批量备货用日均增加值（手工数）
                decimal FOutAvgByHand = Convert.ToDecimal(entry["FOutAvgByHand"]);

                decimal FOutStockDay1 = Convert.ToDecimal(entry["FOutStockDay1"]);
                decimal FOutStockDay2 = Convert.ToDecimal(entry["FOutStockDay2"]);
                decimal FOutStockDay3 = Convert.ToDecimal(entry["FOutStockDay3"]);
                decimal FOutStockDay4 = Convert.ToDecimal(entry["FOutStockDay4"]);
                decimal FOutStockDay5 = Convert.ToDecimal(entry["FOutStockDay5"]);
                decimal FOutStockDay6 = Convert.ToDecimal(entry["FOutStockDay6"]);
                decimal FOutStockDay7 = Convert.ToDecimal(entry["FOutStockDay7"]);
                decimal FOutStockDay8 = Convert.ToDecimal(entry["FOutStockDay8"]);
                decimal FOutStockDay9 = Convert.ToDecimal(entry["FOutStockDay9"]);
                decimal FOutStockDay10 = Convert.ToDecimal(entry["FOutStockDay10"]);
                //5日均发货数量
                decimal FOutAvgBy5 = (FOutStockDay1 + FOutStockDay2 + FOutStockDay3 + FOutStockDay4 + FOutStockDay5)/5;
                decimal FOutAvgBy10 = (FOutStockDay1 + FOutStockDay2 + FOutStockDay3 + FOutStockDay4 + FOutStockDay5
                                     + FOutStockDay6 + FOutStockDay7 + FOutStockDay8 + FOutStockDay9 + FOutStockDay10) / 10;

                FOutAvgBy5 = FOutAvgBy5 * (1 + FOutAvgByHand / 100);
                FOutAvgBy10 = FOutAvgBy10 * (1 + FOutAvgByHand / 100);
                entry["FOutAvgBy5"] = FOutAvgBy5;
                entry["FOutAvgBy10"] = FOutAvgBy10;
                entry["FNoGoodsDay"] = "";//清空断货日期

                //更新当天之后每天的库存
                entry["FInventoryDay2"] = Convert.ToDecimal(entry["FCurrentInventory"]) - FOutAvgBy5 + Convert.ToDecimal(entry["FPurQty2"]);
                for (int i = 3; i <= 16; i++)
                {
                    entry["FInventoryDay"+ i.ToString()] = Convert.ToDecimal(entry["FInventoryDay" + (i-1).ToString()]) - FOutAvgBy5 + Convert.ToDecimal(entry["FPurQty" + i.ToString()]);

                    if (string.IsNullOrWhiteSpace(entry["FNoGoodsDay"].ToString()))
                    {
                        if (Convert.ToDecimal(entry["FInventoryDay"+ i.ToString()]) < Convert.ToDecimal(entry["FMaxOutStockBy10"]))
                        {
                            entry["FNoGoodsDay"] = searchDate.AddDays(i - 1).ToString("yyyy-MM-dd");
                        }
                    }
                }

                //安全库存数量(5日均*到货天数)
                entry["FSafeInventory"] = 0;
                if (Convert.ToDecimal(entry["FDeliveryDay"]) == 0)
                {
                    entry["FSafeInventory"] = FOutAvgBy5;
                }
                if (Convert.ToDecimal(entry["FDeliveryDay"]) != 0)
                {
                    entry["FSafeInventory"] = FOutAvgBy5 * Convert.ToDecimal(entry["FDeliveryDay"]);
                }

                //即时库存可发货天数(即时库存/5日均数（负数显示红色）)
                entry["FCanDeliveryDay"] = 0;
                if (FOutAvgBy5 != 0)
                {
                    entry["FCanDeliveryDay"] = Convert.ToDecimal(entry["FCurrentInventory"]) / FOutAvgBy5;
                }

                //合理下单日期(断货日期减到货天数)
                entry["FReasonableDay"] = "";
                if (!string.IsNullOrWhiteSpace(entry["FNoGoodsDay"].ToString()))
                {
                    entry["FReasonableDay"] = (Convert.ToDateTime(entry["FNoGoodsDay"]).AddDays(0 - Convert.ToInt32(entry["FDeliveryDay"]))).ToString("yyyy-MM-dd");
                }

                //断货日期前是否有采购订单
                entry["FHavePurOrder"] = "";
                if (string.IsNullOrWhiteSpace(entry["FNoGoodsDay"].ToString()))
                {
                    entry["FHavePurOrder"] = "滞销";
                }
                if (!string.IsNullOrWhiteSpace(entry["FNoGoodsDay"].ToString()))
                {
                    entry["FHavePurOrder"] = "否";

                    if (!string.IsNullOrWhiteSpace(entry["FDeliveryDay1"].ToString()) && Convert.ToDateTime(entry["FDeliveryDay1"]) <= Convert.ToDateTime(entry["FNoGoodsDay"]))
                    {
                        entry["FHavePurOrder"] = "是";
                    }
                }

                //是否有采购订单为否时，进行下列操作
                //建议下单日期，最优进货数量，建议到货日期
                entry["FSuggestDay"] = "";
                entry["FMaxGoodQty"] = 0;
                entry["FSuggestDeliveryDay"] = "";
                if (entry["FHavePurOrder"].ToString() == "否")
                {
                    entry["FSuggestDay"] = entry["FReasonableDay"];
                    //最优进货数量
                    entry["FMaxGoodQty"] = entry["FSafeInventory"];

                    if (Convert.ToDecimal(entry["FSafeInventory"]) < Convert.ToDecimal(entry["FMinPurQty"]))
                    {
                        entry["FMaxGoodQty"] = entry["FMinPurQty"];
                    }

                    if (!string.IsNullOrWhiteSpace(entry["FSuggestDay"].ToString()) && !string.IsNullOrWhiteSpace(entry["FDeliveryDay"].ToString()))
                    {
                        entry["FSuggestDeliveryDay"] = (Convert.ToDateTime(entry["FSuggestDay"]).AddDays(Convert.ToInt32(entry["FDeliveryDay"]))).ToString("yyyy-MM-dd");
                    }
                }
            }
        }

        /// <summary>
        /// 设置背景行颜色
        /// </summary>
        private void SetCellsColor()
        {
            DynamicObject billObj = this.Model.DataObject;
            DynamicObjectCollection entrys = billObj["FEntity"] as DynamicObjectCollection;

            //获取查询日期
            DateTime searchDate = Convert.ToDateTime(billObj["FDate"]);

            var entryGrid = this.View.GetControl<EntryGrid>("FEntity");

            //重置颜色
            for (var x = 0; x < entrys.Count; ++x)
            {
                var backColor = "#FFFFFF";
                entryGrid.SetRowBackcolor(backColor, x);
            }

            for (var x = 0; x < entrys.Count; ++x)
            {
                DynamicObject entry = entrys[x];

                //断货日期
                if (string.IsNullOrWhiteSpace(entry["FNoGoodsDay"].ToString()))
                {
                    continue;
                }

                DateTime FNoGoodsDay = Convert.ToDateTime(entry["FNoGoodsDay"]);
                TimeSpan interval = FNoGoodsDay.Subtract(searchDate); // 计算时间间隔
                //int days = interval.Days;// 提取天数部分

                var backColor = "#FF0000";
                for (int days = interval.Days; days <= 15; days++)
                {
                    entryGrid.SetBackcolor("FInventoryDay" + (days + 1).ToString(), backColor, x);
                }
                
            }
        }
    }
}
