-- [ARCHIVED] 已合入正式脚本(2026-06-08), 本文件仅供参考回溯
/*
 * 脚本名称: dws_ipd_ipm_zcmodel_detail_dd_jiguang_draft.sql
 * 功能描述: 在产型号数 - 激光产品线扩展（激光家用/激光商用）
 * 变更类型: CHG-02 产品线扩展
 * 创建时间: 2026-05-29
 * 参考对象: 正式脚本中视像科技段落（第197~258行）
 * MCP验证:
 *   - 目标表 dws_ipd_ipm_zcmodel_detail_dd 无 focallength 字段，需 ALTER TABLE
 *   - 目标表已有 plan_channel 字段 ✅
 * 依赖: 指标1（在销型号数-激光）必须先执行
 */

-- [需ALTER TABLE] 目标表新增焦距字段
-- ALTER TABLE dws.dws_ipd_ipm_zcmodel_detail_dd ADD COLUMN focallength VARCHAR(300) COMMENT '焦距';

------------------------------------在产型号-产品型号口径 激光-------------------------------

delete from dws.dws_ipd_ipm_zcmodel_detail_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '激光';

insert into dws.dws_ipd_ipm_zcmodel_detail_dd(
dt_month
,business_division
,company
,product_line
,in_out_sale
,model
,ir_act_time
,product_big
,product_mid
,product_sml
,platform
,productmodel
,chanpindingwei
,sale_country
,brand
,productmodel__life
,act_time_ss
,act_time_tszb
,act_time_tzxd
,act_time_tzsc
,shangshi_m
,tingchan_m
,is_project
,plan_channel
,focallength
,load_dt
)
select
dt_month
,business_division
,company
,product_line
,in_out_sale
,model
,ir_act_time
,product_big
,product_mid
,product_sml
,platform
,productmodel
,chanpindingwei
,sale_country
,brand
,productmodel__life
,act_time_ss
,act_time_tszb
,act_time_tzxd
,act_time_tzsc
,shangshi_m
,tingchan_m
,is_project
,plan_channel
,focallength
,now()
from dws.dws_ipd_ipm_sale_model_detail_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '激光'
and dt_type = '月'
and model_label_10 = '在产'
;
