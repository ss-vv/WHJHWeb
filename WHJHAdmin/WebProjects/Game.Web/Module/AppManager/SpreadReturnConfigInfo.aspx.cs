﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Game.Web.UI;
using Game.Utils;
using Game.Entity.Treasure;
using Game.Facade;
using System.Data;
using Game.Kernel;
using Game.Entity.Enum;

namespace Game.Web.Module.AppManager
{
    public partial class SpreadReturnConfigInfo : AdminPage
    {
        /// <summary>
        /// 页面加载
        /// </summary>
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                BindData();
            }
        }

        /// <summary>
        /// 数据保存
        /// </summary>
        protected void btnSave_Click(object sender, EventArgs e)
        {
            SpreadReturnConfig config = new SpreadReturnConfig();
            if (IntParam > 0)
            {
                AuthUserOperationPermission(Permission.Edit);
                config.ConfigID = IntParam;
            }
            else
            {
                AuthUserOperationPermission(Permission.Add);
            }

            config.SpreadLevel = CtrlHelper.GetInt(txtSpreadLevel, 0);
            if (config.SpreadLevel > 3)
            {
                ShowError("目前平台仅支持最多三级代理返利！");
                return;
            }
            config.PresentScale = Convert.ToDecimal(txtPresentScale.Text) / 1000;
            config.PresentType = Convert.ToByte(rblPresentType.SelectedValue);
            config.Nullity = Convert.ToBoolean(rblNullity.SelectedValue);
            config.UpdateTime = DateTime.Now;

            int result = FacadeManage.aideTreasureFacade.SaveSpreadReturnConfig(config);
            if (result > 0)
            {
                ShowInfo("操作成功", "SpreadReturnConfigList.aspx", 1200);
            }
            else
            {
                ShowError(config.ConfigID > 0 ? "操作失败" : "一个推广级别只能设置一个配置");
            }
        }

        /// <summary>
        /// 数据绑定
        /// </summary>
        private void BindData()
        {
            if (IntParam > 0)
            {
                SpreadReturnConfig config = FacadeManage.aideTreasureFacade.GetSpreadReturnConfig(IntParam);
                if (config != null)
                {
                    CtrlHelper.SetText(txtSpreadLevel, config.SpreadLevel.ToString());
                    CtrlHelper.SetText(txtPresentScale, (config.PresentScale * 1000).ToString("F0"));
                    rblPresentType.SelectedValue = config.PresentType.ToString();
                    rblNullity.SelectedValue = config.Nullity.ToString();
                }
            }
        }
    }
}