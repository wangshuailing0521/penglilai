﻿using Kingdee.BOS;
using Kingdee.BOS.App.Data;
using Kingdee.BOS.Core;
using Kingdee.BOS.Core.DynamicForm;
using Kingdee.BOS.Core.DynamicForm.PlugIn;
using Kingdee.BOS.Core.DynamicForm.PlugIn.Args;
using Kingdee.BOS.Core.Report;
using Kingdee.BOS.Core.Report.PlugIn;
using Kingdee.BOS.KDThread;
using Kingdee.BOS.Orm.DataEntity;
using Kingdee.BOS.Util;
using OfficeOpenXml;
using OfficeOpenXml.Style;
using Spire.Xls;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.Threading;

namespace YJ.PLL.CY.Bill.PlugIn
{
    [Description("生成车辆配送详单-维护插件")]
    [HotUpdate]
    public class VehicleSendDetailDynamic : AbstractDynamicFormPlugIn
    {
        private List<string> sheetNameList = new List<string>();
        private List<ColumnInfo> columnInfoList = new List<ColumnInfo>();
        private int nums = 0;
        private string vehicleNo = "";
        private string date = DateTime.Now.ToString("yyyy-MM-dd");

        public override void OnInitialize(InitializeEventArgs e)
        {
            base.OnInitialize(e);

            ExcelPackage.LicenseContext = OfficeOpenXml.LicenseContext.NonCommercial;
        }

        public override void AfterButtonClick(AfterButtonClickEventArgs e)
        {
            base.AfterButtonClick(e);

            if (e.Key.EqualsIgnoreCase("FBegin"))
            {
                date = Convert.ToDateTime(View.Model.GetValue("FDate")).ToString("yyyy-MM-dd");

                sheetNameList.Clear();
                nums = 0;
                ExitProcess();
            }
        }

        /// <summary>
        /// 主要用于显示进度滚动界面，并调用引入实际处理子函数
        /// </summary>
        /// <param name="type"></param>
        private void ExitProcess()
        {
            string error = "";
            string fileName = "";
            // 显示一个进度显示界面：显示一个不停滚动的模拟进度

            // bUseTruePro参数：是否显示真实的进度。
            // bUseTruePro = false ：
            // 显示一个不停滚动的模拟进度，与实际处理进度没有关联。
            // 此方案优点：实际处理代码无需计算进度
            // 此方案缺点：进度不准确，且进度页面不会自动关闭。
            // bUseTruePro = true: 进度界面显示真实进度
            // 此方案优点：进度真实
            // 此方案缺点：需要在处理代码中，不断的更新真实进度，更新语句
            // this.View.Session["ProcessRateValue"] = 100;
            // 特别说明，当进度更新到100时，进度界面会自动关闭
            // 本案例选用此方案
            var processForm = this.View.ShowProcessForm(
                new Action<FormResult>(t => { }),
                true,
                "正在导出数据");

            MainWorker.QuequeTask(() =>
            {
                try
                {
                    fileName = this.Exit();
                }
                catch (Exception ex)
                {
                    error = ex.Message + ex.StackTrace;
                    throw new Exception(ex.Message + ex.StackTrace);
                }
                finally
                {
                    // 确保标记进度已经到达100%
                    this.View.Session["ProcessRateValue"] = 100;

                    // 引入完毕，关闭进度显示页面
                    var processView = this.View.GetView(processForm.PageId);
                    if (processView != null)
                    {
                        processView.Close();
                        this.View.SendDynamicFormAction(processView);
                        if (string.IsNullOrWhiteSpace(error))
                        {
                            DownLoad(fileName);
                        }
                        else
                        {
                            this.View.ShowErrMessage(error);
                        }

                    }
                }
            },
            (t) => { });
        }

        private string Exit()
        {
            string execlName = string.Format(@"车辆配送详单-{0}.xlsx", DateTime.Now.ToString("yyMMddHHmmss"));
            // 在临时文件目录，生成一个完整的文件名: C:\Program Files\Kingdee\K3Cloud\WebSite\...\JD.xls
            string fileName = PathUtils.GetPhysicalPath(KeyConst.TEMPFILEPATH, execlName);
            //string fileName = string.Format("C:\\execl\\内部管理报表{0}.xlsx", DateTime.Now.ToString("yyyyMMddHHmmss"));
            FileInfo fileInfo = new FileInfo(fileName);
            if (fileInfo.Exists)
            {
                fileInfo.Delete();
                fileInfo = new FileInfo(fileName);
            }
            ExcelPackage execlPackage = new ExcelPackage(fileInfo);
            try
            {
                long orgId = this.Context.CurrentOrganizationInfo.ID;
                ExcelWorkbook workbook = execlPackage.Workbook;
                //CreateCataLog(workbook, fileName, execlPackage);

                DynamicObjectCollection vehicleList = GetVehicle();
                foreach (var vehicle in vehicleList)
                {
                    vehicleNo = vehicle["FLineNo"].ToString();
                    string sql = string.Format("EXEC sp_YJ_VehicleSendDetail '',{0},'{1}','{2}'", vehicleNo, date, orgId);
                    DataSet dataSet = DBUtils.ExecuteDataSet(this.Context, sql);
                    DataTable data = dataSet.Tables[0];
                    if (data.Rows.Count > 0)
                    {
                        DataTableToExcel(data, string.Format("车辆号【{0}】", vehicleNo), true, fileName, workbook, execlPackage);
                    }
                    
                    this.View.Session["ProcessRateValue"] = Convert.ToInt32(1 / vehicleList.Count);
                }
                //UpdateCataLog(fileName, execlPackage);
                //AddReturn(fileName, execlPackage, nums);
            }
            finally
            {
                ((IDisposable)execlPackage).Dispose();
            }

            return execlName;
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

        private void DownLoad(string fileName)
        {
            // 生成一个供用户下载文件的url地址: http:\\localhost\K3Cloud\...\JD.xls
            string fileUrl
                = PathUtils.GetServerPath(KeyConst.TEMPFILEPATH, fileName);

            // 打开文件下载界面
            DynamicFormShowParameter showParameter = new DynamicFormShowParameter();
            showParameter.FormId = "BOS_FileDownload";
            showParameter.OpenStyle.ShowType = ShowType.Modal;
            showParameter.CustomParams.Add("url", fileUrl);

            this.View.ShowForm(showParameter);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="data">数据</param>
        /// <param name="sheetName">execl中sheet名称</param>
        /// <param name="isColumnWritten">列名是否生成</param>
        /// <param name="fileName">文件名</param>
        /// <param name="workbook"></param>
        /// <param name="package"></param>
        public void DataTableToExcel(
            DataTable data,
            string sheetName,
            bool isColumnWritten,
            string fileName,
            ExcelWorkbook workbook,
            ExcelPackage package)
        {
            if (data == null)
            {
                throw new ArgumentNullException("data");
            }
            if (string.IsNullOrEmpty(sheetName))
            {
                throw new ArgumentNullException(sheetName);
            }
            if (string.IsNullOrEmpty(fileName))
            {
                throw new ArgumentNullException(fileName);
            }
            try
            {
                if ((object)workbook != null)
                {
                    int rowIndex = 0;
                    int columnIndex = 0;

     
                    ExcelWorksheet workSheet = workbook.Worksheets.Add(sheetName);
                    workSheet.View.ShowGridLines = false;

                    #region 设置表头数据
                    workSheet.Cells[1, 1].Value = string.Format("车辆线路号:  {0}", vehicleNo);
                    workSheet.Cells[2, 1].Value = string.Format("送货日期:  {0}", date); 
                    
                    workSheet.Cells[1, 3].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                    workSheet.Cells[1, 3].Style.VerticalAlignment = ExcelVerticalAlignment.Center;
                    workSheet.Cells[2, 3].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                    workSheet.Cells[2, 3].Style.VerticalAlignment = ExcelVerticalAlignment.Center;

                    workSheet.Cells[1, 1].Style.Border.Top.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[1, 1].Style.Border.Bottom.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[1, 1].Style.Border.Left.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[1, 1].Style.Border.Right.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[1, 2].Style.Border.Top.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[1, 2].Style.Border.Bottom.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[1, 2].Style.Border.Left.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[1, 2].Style.Border.Right.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[1, 3].Style.Border.Top.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[1, 3].Style.Border.Bottom.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[1, 3].Style.Border.Left.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[1, 3].Style.Border.Right.Style = ExcelBorderStyle.Thin;

                    workSheet.Cells[2, 1].Style.Border.Top.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[2, 1].Style.Border.Bottom.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[2, 1].Style.Border.Left.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[2, 1].Style.Border.Right.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[2, 2].Style.Border.Top.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[2, 2].Style.Border.Bottom.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[2, 2].Style.Border.Left.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[2, 2].Style.Border.Right.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[2, 3].Style.Border.Top.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[2, 3].Style.Border.Bottom.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[2, 3].Style.Border.Left.Style = ExcelBorderStyle.Thin;
                    workSheet.Cells[2, 3].Style.Border.Right.Style = ExcelBorderStyle.Thin;
                    #endregion

                    #region 生成列名
                    columnInfoList = new List<ColumnInfo>();
                    if (isColumnWritten)
                    {
                        columnIndex = 0;

                        foreach (DataColumn column in data.Columns)
                        {
                            string columnName = column.ColumnName;

                            string columnText = columnName;

                            if (columnName.Equals("FIDENTITYID"))
                            {
                                continue;
                            }

                            if (columnName.Equals("FMaterialNo"))
                            {
                                continue;
                            }

                            if (columnName.Equals("FUnitNo"))
                            {
                                continue;
                            }

                            if (columnName.Equals("FMaterialSeq"))
                            {
                                columnText = "序号";
                            }

                            if (columnName.Equals("FMaterialName"))
                            {
                                columnText = "品名";
                            }

                            if (columnName.Equals("FUnitName"))
                            {
                                columnText = "单位";
                            }


                            columnIndex++;

                            string[] cloumnTexts = columnText.Split('-');
                            if (cloumnTexts.Length > 1)
                            {
                                workSheet.Cells[2, columnIndex].Value = cloumnTexts[1];
                                workSheet.Cells[2, columnIndex].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                                workSheet.Cells[2, columnIndex].Style.VerticalAlignment = ExcelVerticalAlignment.Center;
                                workSheet.Cells[2, columnIndex].Style.Border.Top.Style = ExcelBorderStyle.Thin;
                                workSheet.Cells[2, columnIndex].Style.Border.Bottom.Style = ExcelBorderStyle.Thin;
                                workSheet.Cells[2, columnIndex].Style.Border.Left.Style = ExcelBorderStyle.Thin;
                                workSheet.Cells[2, columnIndex].Style.Border.Right.Style = ExcelBorderStyle.Thin;
                            }

                            if (columnName == "合计")
                            {
                                workSheet.Cells[2, columnIndex].Style.Border.Top.Style = ExcelBorderStyle.Thin;
                                workSheet.Cells[2, columnIndex].Style.Border.Bottom.Style = ExcelBorderStyle.Thin;
                                workSheet.Cells[2, columnIndex].Style.Border.Left.Style = ExcelBorderStyle.Thin;
                                workSheet.Cells[2, columnIndex].Style.Border.Right.Style = ExcelBorderStyle.Thin;
                            }

                            workSheet.Cells[3, columnIndex].Value = cloumnTexts[0];
                            workSheet.Cells[3, columnIndex].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                            workSheet.Cells[3, columnIndex].Style.VerticalAlignment = ExcelVerticalAlignment.Center;
                            workSheet.Cells[3, columnIndex].Style.Font.Bold = true;
                            workSheet.Cells[3, columnIndex].Style.Border.Top.Style = ExcelBorderStyle.Thin;
                            workSheet.Cells[3, columnIndex].Style.Border.Bottom.Style = ExcelBorderStyle.Thin;
                            workSheet.Cells[3, columnIndex].Style.Border.Left.Style = ExcelBorderStyle.Thin;
                            workSheet.Cells[3, columnIndex].Style.Border.Right.Style = ExcelBorderStyle.Thin;

                            workSheet.Cells[3, columnIndex].Style.SetTextVertical(); //文字竖排
                            workSheet.Row(3).Height = 120;//行高
                            workSheet.Column(columnIndex).Width = 5;

                            ColumnInfo columnInfo = new ColumnInfo();
                            columnInfo.ColumnName = columnName;
                            columnInfo.ColumnIndex = columnIndex;
                            columnInfoList.Add(columnInfo);
                        }
                    }
                    #endregion

                    #region 生成数据
                    rowIndex = 4;

                    foreach (DataRow row in data.Rows)
                    {
                        int dataColumnIndex = -1;

                        foreach (DataColumn column in data.Columns)
                        {
                            string columnName = column.ColumnName;
                            dataColumnIndex = dataColumnIndex + 1;

                            if (columnName.Equals("FIDENTITYID"))
                            {
                                continue;
                            }

                            if (columnName.Equals("FMaterialNo"))
                            {
                                continue;
                            }

                            if (columnName.Equals("FUnitNo"))
                            {
                                continue;
                            }

                            columnIndex = 0;
                            foreach (var columnInfo in columnInfoList)
                            {
                                if (columnInfo.ColumnName == columnName)
                                {
                                    columnIndex = columnInfo.ColumnIndex;
                                }
                            }

                            if (columnIndex != 0)
                            {
                                workSheet.Cells[rowIndex, columnIndex].Value = row[dataColumnIndex];
                                workSheet.Cells[rowIndex, columnIndex].Style.Border.Top.Style = ExcelBorderStyle.Thin;
                                workSheet.Cells[rowIndex, columnIndex].Style.Border.Bottom.Style = ExcelBorderStyle.Thin;
                                workSheet.Cells[rowIndex, columnIndex].Style.Border.Left.Style = ExcelBorderStyle.Thin;
                                workSheet.Cells[rowIndex, columnIndex].Style.Border.Right.Style = ExcelBorderStyle.Thin;
                            }
                        }

                        workSheet.Row(rowIndex).Height = 20;

                        rowIndex++;
                    }

                    #endregion

                    #region 设置显示规格
                    workSheet.Cells[1, 1, 1, 2].Merge = true;
                    //workSheet.Cells[1, 3, 1, 5].Merge = true;

                    workSheet.Cells[2, 1, 2, 2].Merge = true;
                    //workSheet.Cells[2, 3, 2, 5].Merge = true;

                    //workSheet.Cells[1, 1].Style.Font.Color.SetColor(Color.Red);
                    // 单元格背景色的设置
                    workSheet.Cells[1, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
                    workSheet.Cells[1, 1].Style.Fill.BackgroundColor.SetColor(Color.LightBlue);

                    workSheet.Cells[2, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
                    workSheet.Cells[2, 1].Style.Fill.BackgroundColor.SetColor(Color.LightBlue);

                    workSheet.Column(2).Width = 25;

                    workSheet.Cells.Style.Font.Size = 12;
                    #endregion

                    using (Stream stream = new FileStream(fileName, FileMode.Create))
                    {
                        package.SaveAs(stream);
                    }

                    nums++;
                    sheetNameList.Add(sheetName);
                }
            }
            catch (IOException ex3)
            {
                throw new IOException(ex3.Message);
            }
            catch (Exception ex4)
            {
                throw new Exception(ex4.Message);
            }
        }

        private void CreateCataLog(ExcelWorkbook workbook, string fileName, ExcelPackage package)
        {
            try
            {
                if ((object)workbook != null)
                {
                    ExcelWorksheet val = workbook.Worksheets.Add("目录");
                    val.View.ShowGridLines = (false);
                    using (Stream stream = new FileStream(fileName, FileMode.Create))
                    {
                        package.SaveAs(stream);
                    }
                }
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        private void UpdateCataLog(string fileName, ExcelPackage package)
        {
            Workbook val = new Workbook();
            val.LoadFromFile(fileName);
            Worksheet val2 = val.Worksheets[0];
            int num = 1;
            foreach (string sheetName in sheetNameList)
            {
                CellRange val3 = val2.Range[string.Format("A{0}", num)];
                val3.Style.Font.Size = (13.0);
                val2.SetRowHeight(num, 25.0);
                val2.TabColor = (Color.DarkGreen);
                HyperLink val4 = val2.HyperLinks.Add(val3);
                val4.Type = HyperLinkType.Workbook;
                val4.TextToDisplay = (string.Format("{0}.", num) + sheetName);
                val4.Address = (sheetName + "!A1");
                if (sheetName.Contains("-"))
                {
                    val4.Address = ("'" + sheetName + "'!A1");
                }
                num++;
            }
            val2.AllocatedRange.AutoFitColumns();
            val.SaveToFile(fileName);
        }

        private void AddReturn(string fileName, ExcelPackage package, int num)
        {
            Workbook val = new Workbook();
            val.LoadFromFile(fileName);
            for (int i = 1; i <= nums; i++)
            {
                Worksheet val2 = val.Worksheets[i];
                val2.TabColor = (Color.DarkGreen);
                CellRange val3 = val2.Range["B1"];
                HyperLink val4 = val2.HyperLinks.Add(val3);
                val4.Type = HyperLinkType.Workbook;
                val4.TextToDisplay = ("返回");
                val4.Address = ("目录!A1");
            }
            val.SaveToFile(fileName);
        }

        public bool IsNumberic(string str)
        {
            double num = default(double);
            return double.TryParse(str, NumberStyles.Float, (IFormatProvider)NumberFormatInfo.InvariantInfo, out num);
        }

        public string StartSubString(string str, int startIdx, string endStr, bool isContains = false, bool isIgnoreCase = true)
        {
            if (string.IsNullOrEmpty(str) || startIdx > str.Length - 1 || startIdx < 0)
            {
                return string.Empty;
            }
            int num = str.IndexOf(endStr, startIdx, (StringComparison)(isIgnoreCase ? 5 : 4));
            if (num < 0)
            {
                return string.Empty;
            }
            return str.Substring(0, isContains ? (num + endStr.Length) : num);
        }
    }
}
