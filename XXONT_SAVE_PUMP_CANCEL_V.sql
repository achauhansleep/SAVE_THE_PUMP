CREATE VIEW [DEV_SCBSG].[XXONT_SAVE_PUMP_CANCEL_V] AS
WITH MAT AS
 (SELECT OOLA1.HEADER_ID,
         OOLA1.LINE_ID,
         OOLA1.TOP_MODEL_LINE_ID,
         MSI1.SEGMENT1,
         MSI1.DESCRIPTION,
         (CASE
           WHEN OOLA1.CANCELLED_FLAG = 'Y' THEN
            OOLA1.LAST_UPDATE_DATE
           ELSE
            NULL
         END) CANCELLATION_DATE,
         OOLA1.FLOW_STATUS_CODE LINE_STATUS,
         OOLA1.SCHEDULE_SHIP_DATE,
         OOLA1.CANCELLED_FLAG CANCEL_FLAG
    FROM EBS.OE_ORDER_LINES_ALL OOLA1
    JOIN EBS.MTL_SYSTEM_ITEMS_B MSI1
      ON MSI1.INVENTORY_ITEM_ID = OOLA1.INVENTORY_ITEM_ID
     AND MSI1.ORGANIZATION_ID = OOLA1.SHIP_FROM_ORG_ID
     AND MSI1.DESCRIPTION LIKE '%MATTRESS%'
   WHERE EXISTS (SELECT 1
            FROM EBS.OE_REASONS OER1
           WHERE OER1.HEADER_ID = OOLA1.HEADER_ID
             AND OER1.REASON_CODE = 'SAVE_PUMP'
             AND OER1.ENTITY_CODE = 'LINE'))
SELECT OER.REASON_ID,
       OER.HEADER_ID SO_HEADER_ID,
       OER.ENTITY_ID SO_LINE_ID,
       MP.ORGANIZATION_CODE SHIP_FROM,
       OOHA.ORDER_NUMBER,
       OOHA.FLOW_STATUS_CODE ORDER_STATUS,
       OOLA.LINE_NUMBER,
       MSI.SEGMENT1 ITEM_NUMBER,
       MSI.DESCRIPTION ITEM_DESCRIPTION,
       OOLA.ATTRIBUTE4 MARKET,
       OOLA.CANCELLED_QUANTITY,
       OOLA.SHIP_FROM_ORG_ID,
       OOLA.INVENTORY_ITEM_ID,
       OOLA.FLOW_STATUS_CODE LINE_STATUS,
       --CO.ITEM_COST,
       (CASE WHEN CAST (OOLA.LAST_UPDATE_DATE AS DATE) BETWEEN '01-Dec-2022' AND '31-Dec-2022'
       THEN
       74.63
       ELSE
       CO.ITEM_COST
       END) ITEM_COST,
       --(OOLA.CANCELLED_QUANTITY * CO.ITEM_COST) TOTAL_COST,
       (OOLA.CANCELLED_QUANTITY * (CASE WHEN OOLA.LAST_UPDATE_DATE BETWEEN '01-Dec-2022' AND '31-Dec-2022'
       THEN
       74.63
       ELSE
       CO.ITEM_COST
       END)) TOTAL_COST,
       MICV_OM.SEGMENT2 OM_CATEGORY,
       MICV_INV.SEGMENT2 INVENTORY_CATEGORY,
       OOLA.LINE_TYPE_ID,
       (CASE
         WHEN OTT.NAME = 'SC EXCHANGE SALE LINE' THEN
          'Exchange Sale'
         WHEN OTT.NAME = 'SC EXCHANGE RETURN LINE' THEN
          'Exchange Return'
         ELSE
          OTT.NAME
       END) LINE_TYPE,
       'Y' KDNS_CANCELLATION,
       OER.REASON_CODE,
       OOLA.LAST_UPDATE_DATE CANCELLATION_DATE,
       DDD.FSCL_YEAR_YYYY CANCELLATION_FISCAL_YEAR,
       DDD.FSCL_MONTH_NUM CANCELLATION_FISCAL_MONTH,
       CONCAT('Wk ', RIGHT('0' + CAST(DDD.WEEK_NUM AS VARCHAR), 2)) CANCELLATION_FISCAL_WEEK,
       (CASE
         WHEN MAT.LINE_STATUS IN ('AWAITING_FULFILLMENT', 'CLOSED') THEN
          'Y'
         ELSE
          'N'
       END) ORDER_DELIVERED,
       (CASE
         WHEN SUBSTRING(MSI.SEGMENT1, 1, 1) = '9' THEN
          'Yes'
         ELSE
          'No'
       END) REFURBED_PUMP,
       '' SR_NUM,--SIEBEL.SR_NUM,
       '' SR_STATUS,--SIEBEL.SR_STATUS,
       '' DELIVERY_DATE,--SIEBEL.DELIVERY_DATE,
       MAT.SEGMENT1 MATTRESS,
       MAT.DESCRIPTION MATTRESS_DESCRIPTION,
       MAT.CANCELLATION_DATE MATTRESS_CANCELLATION_DATE,
       MAT.SCHEDULE_SHIP_DATE,
       ISNULL(MAT.CANCEL_FLAG, 'N') MATTRESS_CANCELLED,
       OOLA.TOP_MODEL_LINE_ID,
       MSI1.INVENTORY_ITEM_ID TOP_MODEL_ID,
       MSI1.SEGMENT1 TOP_MODEL,
       MSI1.DESCRIPTION TOP_MODEL_DESCRIPTION
  FROM EBS.OE_REASONS OER
  JOIN EBS.OE_ORDER_LINES_ALL OOLA
    ON OER.ENTITY_ID = OOLA.LINE_ID
   AND OER.HEADER_ID = OOLA.HEADER_ID
  JOIN EBS.OE_ORDER_HEADERS_ALL OOHA
    ON OOLA.HEADER_ID = OOHA.HEADER_ID
  JOIN EBS.OE_TRANSACTION_TYPES_TL OTT
    ON OOLA.LINE_TYPE_ID = OTT.TRANSACTION_TYPE_ID
  JOIN EBS.MTL_PARAMETERS MP
    ON OOLA.SHIP_FROM_ORG_ID = MP.ORGANIZATION_ID
  JOIN EBS.MTL_SYSTEM_ITEMS_B MSI
    ON OOLA.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
   AND OOLA.SHIP_FROM_ORG_ID = MSI.ORGANIZATION_ID
  LEFT JOIN DW.DWH_DAY_D DDD
    ON CAST(OOLA.LAST_UPDATE_DATE AS DATE) = CAST(DDD.DAY_DT AS DATE)
  JOIN PROD_SCBSG.MTL_ITEM_CATEGORIES_V MICV_INV
    ON MICV_INV.CATEGORY_SET_NAME = 'SC Inventory Category'
   AND MICV_INV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
   AND MICV_INV.ORGANIZATION_ID = MSI.ORGANIZATION_ID
  LEFT JOIN PROD_SCBSG.MTL_ITEM_CATEGORIES_V MICV_OM
    ON MICV_OM.CATEGORY_SET_NAME = 'SC OM Category'
   AND MICV_OM.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
   AND MICV_OM.ORGANIZATION_ID = MSI.ORGANIZATION_ID
  JOIN EBS.CST_ITEM_COSTS CO
    ON MSI.INVENTORY_ITEM_ID = CO.INVENTORY_ITEM_ID
   AND MSI.ORGANIZATION_ID = CO.ORGANIZATION_ID
   AND CO.COST_TYPE_ID = 1
  LEFT JOIN MAT
    ON MAT.HEADER_ID = OOHA.HEADER_ID
   AND MAT.TOP_MODEL_LINE_ID = OOLA.TOP_MODEL_LINE_ID
  LEFT JOIN EBS.OE_ORDER_LINES_ALL OOLA1
    ON OOLA1.LINE_ID = OOLA.TOP_MODEL_LINE_ID
  LEFT JOIN EBS.MTL_SYSTEM_ITEMS_B MSI1
    ON OOLA1.INVENTORY_ITEM_ID = MSI1.INVENTORY_ITEM_ID
   AND OOLA1.SHIP_FROM_ORG_ID = MSI1.ORGANIZATION_ID
 WHERE OER.REASON_CODE = 'SAVE_PUMP'
   AND OER.ENTITY_CODE = 'LINE'
      --AND OTT.NAME IN ('SC EXCHANGE RETURN LINE', 'SC EXCHANGE SALE LINE')
   AND OOHA.ORDER_TYPE_ID = 1011;