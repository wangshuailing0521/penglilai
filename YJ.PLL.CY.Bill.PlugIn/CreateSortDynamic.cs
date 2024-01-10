using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Linq;
using Kingdee.BOS;
using Kingdee.BOS.App.Data;
using Kingdee.BOS.Contracts;
using Kingdee.BOS.Core;
using Kingdee.BOS.Core.Bill;
using Kingdee.BOS.Core.Bill.PlugIn;
using Kingdee.BOS.Core.DynamicForm;
using Kingdee.BOS.Core.DynamicForm.PlugIn;
using Kingdee.BOS.Core.DynamicForm.PlugIn.Args;
using Kingdee.BOS.Core.DynamicForm.PlugIn.ControlModel;
using Kingdee.BOS.Core.Interaction;
using Kingdee.BOS.Core.List.PlugIn;
using Kingdee.BOS.Core.Metadata;
using Kingdee.BOS.Core.Metadata.FormElement;
using Kingdee.BOS.Orm;
using Kingdee.BOS.Orm.DataEntity;
using Kingdee.BOS.ServiceHelper;
using Kingdee.BOS.Util;


namespace YJ.PLL.CY.Bill.PlugIn
{
    [Description("一键生成当日数据 维护插件")]
    [HotUpdate]
    public class CreateSortDynamic : AbstractDynamicFormPlugIn
    {
        /// <summary>
        /// 进度条
        /// </summary>
        private ProgressBar _progressBar = null;
        /// <summary>
        /// 当前进度
        /// </summary>
        private int _progressValue = 0;

        private string _progressCaption = "";

        private string date = DateTime.Now.ToString("yyyy-MM-dd");

        public override void OnInitialize(InitializeEventArgs e)
        {
            this._progressBar = this.View.GetControl<ProgressBar>("FProgressBar");
        }

        public override void AfterButtonClick(AfterButtonClickEventArgs e)
        {
            base.AfterButtonClick(e);

            if (e.Key.EqualsIgnoreCase("FBegin"))
            {
                string billType = this.View.OpenParameter.GetCustomParameter("billType").ToString();

                if (View.Model.GetValue("FDate") == null)
                {
                    throw new KDException("错误", "日期不能为空");
                }

                date = Convert.ToDateTime( View.Model.GetValue("FDate")).ToString("yyyy-MM-dd");


                if (this._progressBar != null)
                {
                    // 初始化当前进度：
                    this._progressBar.Visible = true;
                    this._progressValue = 0;
                    // 启动进度条，每个2s，到服务器获取一次进度。
                    // 如果进度达到了100，则自动停止
                    this._progressBar.Start(2);
                    // 开启一个新线程，处理需要长时间进行的业务
                    Kingdee.BOS.KDThread.MainWorker.QuequeTask(
                        () =>
                        {
                            // TODO: 异步处理
                            if (billType.Equals("Vehicle"))
                            {
                                CreateVehicle();
                            }
                            if (billType.Equals("Stock"))
                            {
                                CreateStock();
                            }
                        },
                        (asynResult) =>
                        {
                            if (asynResult != null && asynResult.Exception != null)
                            {
                                this.View.ShowMessage(asynResult.Exception.Message);
                            }
                            //TODO : 异步处理完毕，进行收尾
                        });
                }
            }

            if (e.Key.EqualsIgnoreCase("FStop"))
            {
                // 通过设置当前进度为100，通知进度条，任务已经完成
                this._progressValue = 100;
            } 
        }

        /// <summary>
        /// 进度条方法  定时获取进度显示至前台进度条
        /// </summary>
        /// <param name="e"></param>
        public override void OnQueryProgressValue(QueryProgressValueEventArgs e)
        {
            if (this._progressValue == 100)
            {
                // 进度到了100，提升成功
                _progressBar.Visible = false;
            }
            // 返回进度给前端
            e.Value = this._progressValue;
            e.Caption = _progressCaption;
        }

        #region 创建车辆分拣单
        void CreateVehicle()
        {
            try
            {
                DynamicObjectCollection data = GetVehicle();

                bool isAllSus = true;

                // 计算页数
                var pageCount = data.Count();
                // 当前页数
                int page = 0;

                foreach (var item in data)
                {
                    page++;

                    _progressValue = Convert.ToInt32(page / pageCount * 100);
                    _progressCaption = string.Format("已完成：{0}/{1}", page, pageCount);

                    string vehicleNo = item["FLineNo"].ToString();

                    if (!isAllSus)
                    {
                        continue;
                    }

                    if (!CreateAndSaveVehicle(vehicleNo))
                    {
                        _progressValue = 100;
                        isAllSus = false;
                        _progressCaption = "";
                    }
                }

                if (isAllSus)
                {
                    this.View.ShowMessage("一键生成数据完毕！");
                }

            }
            catch (Exception ex)
            {
                _progressValue = 100;
                _progressCaption = "";
                this.View.ShowErrMessage(ex.Message);
            }
        }

        /// <summary>
        /// 获取所有车辆号
        /// </summary>
        /// <returns></returns>
        private DynamicObjectCollection GetVehicle()
        {
            string sql = string.Format(
                @"/*dialect*/
                SELECT  FLineNo
                  FROM  T_YJ_ShopNo A
                        INNER JOIN T_YJ_ShopNoEntry B
                        ON A.FID = B.FID
                 WHERE  A.FDocumentStatus = 'C'
                 GROUP  BY B.FLineNo");
            return DBUtils.ExecuteDynamicObject(this.Context, sql);
        }

        private bool CreateAndSaveVehicle(string vehicleNo)
        {
            // 构建一个IBillView实例，通过此实例，可以方便的填写物料各属性
            IBillView billView = this.CreateBillView("PZXD_NewVehicleSort");
            // 新建一个空白单据
            ((IBillViewService)billView).LoadData();

            // 触发插件的OnLoad事件：
            // 组织控制基类插件，在OnLoad事件中，对主业务组织改变是否提示选项进行初始化。
            // 如果不触发OnLoad事件，会导致主业务组织赋值不成功
            DynamicFormViewPlugInProxy eventProxy = billView.GetService<DynamicFormViewPlugInProxy>();
            eventProxy.FireOnLoad();

            if (this.FillBillPropertysVehicle(billView, vehicleNo))
            {
                OperateOption saveOption = OperateOption.Create();
                IOperationResult saveResult = this.SaveBill(billView, saveOption);

                if (!saveResult.IsSuccess)
                {
                    saveResult.MergeValidateErrors();
                    this.View.ShowOperateResult(saveResult.OperateResult);

                    return false;
                }
            }

            return true;
        }

        private bool FillBillPropertysVehicle(IBillView billView, string vehicleNo)
        {
            // 把billView转换为IDynamicFormViewService接口：
            // 调用IDynamicFormViewService.UpdateValue: 会执行字段的值更新事件
            // 调用 dynamicFormView.SetItemValueByNumber ：不会执行值更新事件，需要继续调用：
            // ((IDynamicFormView)dynamicFormView).InvokeFieldUpdateService(key, rowIndex);
            IDynamicFormViewService dynamicFormView = billView as IDynamicFormViewService;

            string sql = string.Format("EXEC sp_YJ_VehicleSort {0},'{1}'", vehicleNo, date);
            DynamicObjectCollection data = DBUtils.ExecuteDynamicObject(this.Context, sql);

            if (data.Count <= 0)
            {
                return false;
            }

            dynamicFormView.UpdateValue("FDate", 0, date);
            dynamicFormView.UpdateValue("FVersion", 0, "V1.0");
            dynamicFormView.UpdateValue("FVehicleSeq", 0, vehicleNo);

            int rowIndex = 0;
            billView.Model.BatchCreateNewEntryRow("FEntity", data.Count - 1);
            foreach (var dataItem in data)
            {
                dynamicFormView.UpdateValue("FSeq1", rowIndex, dataItem["FSeq1"]);
                dynamicFormView.SetItemValueByID("FMaterialId1", dataItem["FMaterialID1"], rowIndex);
                dynamicFormView.SetItemValueByID("FUnitID1", dataItem["FUNITID1"], rowIndex);
                dynamicFormView.UpdateValue("FQty1", rowIndex, dataItem["FQTY1"]);
                dynamicFormView.UpdateValue("FNote1", rowIndex, "");

                dynamicFormView.UpdateValue("FSeq2", rowIndex, dataItem["FSeq2"]);
                dynamicFormView.SetItemValueByID("FMaterialId2", dataItem["FMaterialID2"], rowIndex);
                dynamicFormView.SetItemValueByID("FUnitID2", dataItem["FUNITID2"], rowIndex);
                dynamicFormView.UpdateValue("FQty2", rowIndex, dataItem["FQTY2"]);
                dynamicFormView.UpdateValue("FNote2", rowIndex, "");

                rowIndex++;
            }

            return true;
        }
        #endregion

        #region 创建仓库总拣单
        void CreateStock()
        {
            try
            {
                DynamicObjectCollection data = GetBatchNo();

                bool isAllSus = true;

                // 计算页数
                var pageCount = data.Count();
                // 当前页数
                int page = 0;

                foreach (var item in data)
                {
                    page++;

                    _progressValue = Convert.ToInt32(page / pageCount * 100);
                    _progressCaption = string.Format("已完成：{0}/{1}", page, pageCount);

                    string batchNo = item["FBatchSeq"].ToString();

                    if (!isAllSus)
                    {
                        continue;
                    }

                    if (!CreateAndSaveStock(batchNo))
                    {
                        _progressValue = 100;
                        isAllSus = false;
                        _progressCaption = "";
                    }
                }

                if (isAllSus)
                {
                    this.View.ShowMessage("一键生成数据完毕！");
                }

            }
            catch (Exception ex)
            {
                _progressValue = 100;
                _progressCaption = "";
                this.View.ShowErrMessage(ex.Message);
            }
        }

        /// <summary>
        /// 获取所有车辆号
        /// </summary>
        /// <returns></returns>
        private DynamicObjectCollection GetBatchNo()
        {
            string sql = string.Format(
                @"/*dialect*/
                SELECT '' AS FBatchSeq 
                UNION ALL
                SELECT  CONVERT(VARCHAR(10),FBatchSeq) 
                  FROM  T_YJ_ShopNo A
                        INNER JOIN T_YJ_ShopNoEntry B
                        ON A.FID = B.FID
                 WHERE  A.FDocumentStatus = 'C'
                 GROUP  BY B.FBatchSeq");
            return DBUtils.ExecuteDynamicObject(this.Context, sql);
        }

        private bool CreateAndSaveStock(string batchNo)
        {
            // 构建一个IBillView实例，通过此实例，可以方便的填写物料各属性
            IBillView billView = this.CreateBillView("PZXD_StockSort");
            // 新建一个空白单据
            ((IBillViewService)billView).LoadData();

            // 触发插件的OnLoad事件：
            // 组织控制基类插件，在OnLoad事件中，对主业务组织改变是否提示选项进行初始化。
            // 如果不触发OnLoad事件，会导致主业务组织赋值不成功
            DynamicFormViewPlugInProxy eventProxy = billView.GetService<DynamicFormViewPlugInProxy>();
            eventProxy.FireOnLoad();

            if (this.FillBillPropertysStock(billView, batchNo))
            {
                OperateOption saveOption = OperateOption.Create();
                IOperationResult saveResult = this.SaveBill(billView, saveOption);

                if (!saveResult.IsSuccess)
                {
                    saveResult.MergeValidateErrors();
                    this.View.ShowOperateResult(saveResult.OperateResult);

                    return false;
                }
            }

            return true;
        }

        private bool FillBillPropertysStock(IBillView billView, string stockNo)
        {
            // 把billView转换为IDynamicFormViewService接口：
            // 调用IDynamicFormViewService.UpdateValue: 会执行字段的值更新事件
            // 调用 dynamicFormView.SetItemValueByNumber ：不会执行值更新事件，需要继续调用：
            // ((IDynamicFormView)dynamicFormView).InvokeFieldUpdateService(key, rowIndex);
            IDynamicFormViewService dynamicFormView = billView as IDynamicFormViewService;

            string sql = string.Format("EXEC sp_YJ_StockSort '{0}','{1}'", stockNo, date);
            DynamicObjectCollection data = DBUtils.ExecuteDynamicObject(this.Context, sql);

            if (data.Count <= 0)
            {
                return false;
            }

            if (string.IsNullOrWhiteSpace(stockNo))
            {
                stockNo = "总计";
            }    

            dynamicFormView.UpdateValue("FDate", 0, date);
            dynamicFormView.UpdateValue("FVersion", 0, "V1.0");
            dynamicFormView.UpdateValue("FBatchSeqText", 0, stockNo);

            int rowIndex = 0;
            billView.Model.BatchCreateNewEntryRow("FEntity", data.Count - 1);
            foreach (var dataItem in data)
            {
                dynamicFormView.UpdateValue("FSeq1", rowIndex, dataItem["FSeq1"]);
                dynamicFormView.SetItemValueByID("FMaterialId1", dataItem["FMaterialID1"], rowIndex);
                dynamicFormView.SetItemValueByID("FUnitID1", dataItem["FUNITID1"], rowIndex);
                dynamicFormView.UpdateValue("FQty1", rowIndex, dataItem["FQTY1"]);
                dynamicFormView.UpdateValue("FNote1", rowIndex, "");

                dynamicFormView.UpdateValue("FSeq2", rowIndex, dataItem["FSeq2"]);
                dynamicFormView.SetItemValueByID("FMaterialId2", dataItem["FMaterialID2"], rowIndex);
                dynamicFormView.SetItemValueByID("FUnitID2", dataItem["FUNITID2"], rowIndex);
                dynamicFormView.UpdateValue("FQty2", rowIndex, dataItem["FQTY2"]);
                dynamicFormView.UpdateValue("FNote2", rowIndex, "");

                rowIndex++;
            }

            return true;
        }
        #endregion

        

        private IOperationResult SaveBill(IBillView billView, OperateOption saveOption)
        {
            // 设置FormId
            Form form = billView.BillBusinessInfo.GetForm();
            if (form.FormIdDynamicProperty != null)
            {
                form.FormIdDynamicProperty.SetValue(billView.Model.DataObject, form.Id);
            }

            // 调用保存操作
            IOperationResult saveResult = BusinessDataServiceHelper.Save(
            this.Context,
            billView.BillBusinessInfo,
            billView.Model.DataObject,
            saveOption,
            "Save");

            if (saveResult.IsSuccess == true)
            {
                saveResult = BusinessDataServiceHelper.Submit(this.Context
                    , billView.BillBusinessInfo, new object[] { billView.Model.DataObject["Id"] }, "Submit");

                if (saveResult.IsSuccess == true)
                {
                    saveResult = BusinessDataServiceHelper.Audit(this.Context
                        , billView.BillBusinessInfo, new object[] { billView.Model.DataObject["Id"] }, OperateOption.Create());

                    return saveResult;

                }
                else
                {
                    return saveResult;
                }
            }
            else
            {
                return saveResult;
            }
        }

        private IBillView CreateBillView(string formId)
        {
            // 读取物料的元数据
            FormMetadata meta = MetaDataServiceHelper.Load(this.Context, formId) as FormMetadata;
            Form form = meta.BusinessInfo.GetForm();
            // 创建用于引入数据的单据view
            Type type = Type.GetType("Kingdee.BOS.Web.Import.ImportBillView,Kingdee.BOS.Web");
            var billView = (IDynamicFormViewService)Activator.CreateInstance(type);
            // 开始初始化billView：
            // 创建视图加载参数对象，指定各种参数，如FormId, 视图(LayoutId)等
            BillOpenParameter openParam = CreateOpenParameter(meta);
            // 动态领域模型服务提供类，通过此类，构建MVC实例
            var provider = form.GetFormServiceProvider();
            billView.Initialize(openParam, provider);
            return billView as IBillView;
        }

        private BillOpenParameter CreateOpenParameter(FormMetadata meta)
        {
            Form form = meta.BusinessInfo.GetForm();
            // 指定FormId, LayoutId
            BillOpenParameter openParam = new BillOpenParameter(form.Id, meta.GetLayoutInfo().Id);
            // 数据库上下文
            openParam.Context = this.Context;
            // 本单据模型使用的MVC框架
            openParam.ServiceName = form.FormServiceName;
            // 随机产生一个不重复的PageId，作为视图的标识
            openParam.PageId = Guid.NewGuid().ToString();
            // 元数据
            openParam.FormMetaData = meta;
            // 界面状态：新增 (修改、查看)
            openParam.Status = OperationStatus.ADDNEW;
            // 单据主键：本案例演示新建物料，不需要设置主键
            openParam.PkValue = null;
            // 界面创建目的：普通无特殊目的 （为工作流、为下推、为复制等）
            openParam.CreateFrom = CreateFrom.Default;
            // 基础资料分组维度：基础资料允许添加多个分组字段，每个分组字段会有一个分组维度
            // 具体分组维度Id，请参阅 form.FormGroups 属性
            openParam.GroupId = "";
            // 基础资料分组：如果需要为新建的基础资料指定所在分组，请设置此属性
            openParam.ParentId = 0;
            // 单据类型
            openParam.DefaultBillTypeId = "";
            // 业务流程
            openParam.DefaultBusinessFlowId = "";
            // 主业务组织改变时，不用弹出提示界面
            openParam.SetCustomParameter("ShowConfirmDialogWhenChangeOrg", false);
            // 插件
            List<AbstractDynamicFormPlugIn> plugs = form.CreateFormPlugIns();
            openParam.SetCustomParameter(FormConst.PlugIns, plugs);
            PreOpenFormEventArgs args = new PreOpenFormEventArgs(this.Context, openParam);
            foreach (var plug in plugs)
            {// 触发插件PreOpenForm事件，供插件确认是否允许打开界面
                plug.PreOpenForm(args);
            }
            if (args.Cancel == true)
            {// 插件不允许打开界面
             // 本案例不理会插件的诉求，继续....
            }
            // 返回
            return openParam;
        }

       
    }
}
