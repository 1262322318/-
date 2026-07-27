# 015-rili-xpqd-migration 数据血缘

## 数据流转图

```
dim.dim_ipd_salemodel_dd（HDRP产品维度）
    │
    ├──→ dim.dim_ipd_ipm_rili_syb_xm_shangshitime_dd（事业部/项目上市时间维度）
    │         │
    │         ↓ CROSS JOIN（种子数据展开）
    │
    ├──→ dws.dws_ipd_ipm_rili_qdch_m_detail_dd（签单&出货月度明细）
    │         ↑                    ↑                    ↑
    │    dw.dim_product_base_info_dd   签单ODS表         出货ODS表
    │    （MDG桥接）              （内销+外销）       （内销+外销）
    │         │
    │         ↓ 被引用（data_type='型号口径-sap编码合计'）
    │
    └──→ dws.dws_ipd_ipm_rili_xpqd_detail_dd（新品签单汇总+完成率）
              ↑
         dwd.dwd_ipd_ipm_bp_lx_model_mid_dd（LX规划量）
```

## 表间依赖

| 目标表 | 依赖源表 | 关联方式 |
|--------|----------|----------|
| dim_syb_xm_shangshitime | dim_ipd_salemodel_dd | 直接读取，筛选新品范围 |
| dws_qdch_m_detail | dim_ipd_salemodel_dd | 新品范围 + MDG桥接 |
| dws_qdch_m_detail | dim_product_base_info_dd | sale_model_code → product_code |
| dws_qdch_m_detail | DWSD_RILISMS_TF_HAC_CONTRACT | PRODUCTID = product_code |
| dws_qdch_m_detail | odsemp_sms_hac_hh_gj_contract | PRODUCTID = product_code |
| dws_qdch_m_detail | DWSD_RILISMS_TF_HAC_SHIPMENT | MATERIAL_CODE = product_code |
| dws_qdch_m_detail | odsemp_sms_hac_hh_gj_tr_notice | PRODUCT_ID = product_code |
| dws_xpqd_detail | dws_qdch_m_detail | data_type='型号口径-sap编码合计', sap_number关联 |
| dws_xpqd_detail | dwd_ipd_ipm_bp_lx_model_mid_dd | salemodelcode = sap_number |

## 执行顺序约束

```
dim_ipd_ipm_rili_syb_xm_shangshitime_dd
    ↓（须先完成）
dws_ipd_ipm_rili_qdch_m_detail_dd
    ↓（须先完成，第3次INSERT引用自身产出）
dws_ipd_ipm_rili_xpqd_detail_dd
```
