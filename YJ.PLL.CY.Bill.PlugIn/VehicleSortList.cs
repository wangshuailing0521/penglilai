using Kingdee.BOS;
using Kingdee.BOS.App.Data;
using Kingdee.BOS.Core;
using Kingdee.BOS.Core.Bill;
using Kingdee.BOS.Core.DynamicForm;
using Kingdee.BOS.Core.DynamicForm.PlugIn.Args;
using Kingdee.BOS.Core.List;
using Kingdee.BOS.Core.List.PlugIn;
using Kingdee.BOS.Core.List.PlugIn.Args;
using Kingdee.BOS.Orm.DataEntity;
using Kingdee.BOS.Util;

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Linq;
using System.Text;


namespace YJ.PLL.CY.Bill.PlugIn
{
    [Description("车辆分拣单-列表插件")]
    [HotUpdate]
    public class VehicleSortList : AbstractListPlugIn
    {
        public override void AfterBarItemClick(AfterBarItemClickEventArgs e)
        {
            base.AfterBarItemClick(e);

            if (e.BarItemKey == "AllCreate")
            {
                DynamicFormShowParameter para = new DynamicFormShowParameter();
                para.OpenStyle.ShowType = ShowType.Modal;
                para.PageId = Guid.NewGuid().ToString();
                para.FormId = "PZXD_AllCreate";
                para.CustomParams.Add("billType", "Vehicle");
                base.View.ShowForm(para);
            }
        }
    }
}
