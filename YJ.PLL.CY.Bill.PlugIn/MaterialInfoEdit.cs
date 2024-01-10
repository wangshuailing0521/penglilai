using Kingdee.BOS.Core.Bill.PlugIn;
using Kingdee.BOS.Core.DynamicForm.PlugIn.ControlModel;
using Kingdee.BOS.Orm.DataEntity;
using Kingdee.BOS.Util;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace YJ.PLL.CY.Bill.PlugIn
{
    [Description("物料维护表-表单插件")]
    [HotUpdate]
    public class MaterialInfoEdit : AbstractBillPlugIn
    {
        public override void AfterBindData(EventArgs e)
        {
            base.AfterBindData(e);

            SetCellsColor();
        }

        /// <summary>
        /// 设置背景行颜色
        /// </summary>
        private void SetCellsColor()
        {
            DynamicObject billObj = this.Model.DataObject;
            DynamicObjectCollection entrys = billObj["FEntity"] as DynamicObjectCollection;
            List<string> saleBillNos = new List<string>();

            var lineNos = from entry in entrys group entry by entry["FLineNo"] into g select new { groupkey = g.Key, count = g.Count() };
            var stockSeqs = from entry in entrys group entry by entry["FStockSeq"] into g select new { groupkey = g.Key, count = g.Count() };
            var materialSeqs = from entry in entrys group entry by entry["FMaterialSeq"] into g select new { groupkey = g.Key, count = g.Count() };

            var entryGrid = this.View.GetControl<EntryGrid>("FEntity");
            for (var x = 0; x < entrys.Count; ++x)
            {
                DynamicObject entry = entrys[x];

                string lineNo = entry["FLineNo"].ToString();
                string stockSeq = entry["FStockSeq"].ToString();
                string materialSeq = entry["FMaterialSeq"].ToString();

                int lineNoCount = lineNos.Where(t => t.groupkey.ToString() == lineNo).Select(t => t.count).FirstOrDefault();
                int stockSeqCount = stockSeqs.Where(t => t.groupkey.ToString() == stockSeq).Select(t => t.count).FirstOrDefault();
                int materialSeqCount = materialSeqs.Where(t => t.groupkey.ToString() == materialSeq).Select(t => t.count).FirstOrDefault();

                if (lineNoCount == 2 || stockSeqCount == 2 || materialSeqCount == 2)
                {
                    var backColor = "#FFFF00";
                    entryGrid.SetRowBackcolor(backColor, x);
                }

                if (lineNoCount > 2 || stockSeqCount > 2 || materialSeqCount > 2)
                {
                    var backColor = "#FF0000";
                    entryGrid.SetRowBackcolor(backColor, x);
                }
            }

            
        }
    }
}
