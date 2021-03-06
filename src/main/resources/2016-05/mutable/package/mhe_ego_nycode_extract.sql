--liquibase formatted sql
--liquibase formatted sql

--changeset sourav_mukherjee:1 runAlways:true splitStatements:false
/*********************************************************************************************************************
/*             Name: MHEEGO_NYCDOE_EXTRACT_PKG.pkg
/*      Object Type: Package Specification Script File
/*      Description: This is the package specification for NYCDOE Extract
/* Execution Schema: APPS
/*
/* Change History:
/* Date      Name                IR  Modification
/* --------  -----------------   --- ------------
/* 12/24/13  TCS                 1.0 Created              
/*********************************************************************************************************************/
CREATE or REPLACE package mhe_ego_nycdoe_extract_pkg is

   PROCEDURE mhe_ego_nycdoe_pr(retcode OUT VARCHAR2
                               ,errbuf OUT VARCHAR2
                               ,p_bid_search_name IN VARCHAR2
                               ,p_freight_percentage IN NUMBER);

END mhe_ego_nycdoe_extract_pkg;


--changeset sourav_mukherjee:2 runAlways:true splitStatements:false
/*********************************************************************************************************************
/*             Name: MHEEGO_NYCDOE_EXTRACT_PKG.pkb
/*      Object Type: Package Body Script File
/*      Description: This is the package body for NYCDOE Extract in PDH
/* Execution Schema: APPS
/*
/* Change History:
/* Date      Name                IR  Modification
/* --------  -----------------   --- ------------
/* 12/24/13  TCS                 1.0 Created
/* 03/17/14  TCS                 1.1 Changes for defect 1147
/* 04/01/14  TCS                 1.2 Corrected version number in change control
/* 08/07/14  TCS                 1.3 Change as per defect 1646
 * 05/02/16  TCS                 1.4 Change for PDH-28
 */
/*********************************************************************************************************************/
CREATE OR REPLACE PACKAGE BODY mhe_ego_nycdoe_extract_pkg IS
   /********************************************************************************
   *  Name          : mhe_ego_nycdoe_extract_pkg.mhe_ego_nycdoe_pr
   *  Object Type   : Procedure
   *  Description   : This Procedure is for NYCDOE Extract
   *  Calls         : None
   *  Source        : PIM Application Concurrent Requests
   *  Change History:
   *  Date            Name           IR     Comments
   *  -----------     ------------   ----   --------------------------
   *  12/24/2013      TCS            1.0    Initial Revision
   *  03/17/2014      TCS            1.1    Changes for defect 1147
   *  08/07/2014      TCS            1.2    Change as per defect 1646
   /********************************************************************************/
   PROCEDURE mhe_ego_nycdoe_pr(retcode              OUT VARCHAR2
                              ,errbuf               OUT VARCHAR2
                              ,p_bid_search_name    IN VARCHAR2
                              ,p_freight_percentage IN NUMBER) IS

      l_application_code      VARCHAR2(2) := '01';
      l_item_number           NUMBER(8) := NULL;
      l_check_digit           VARCHAR2(1) := NULL;
      l_maintenance_code      VARCHAR2(1) := NULL;
      l_delivery_charge       NUMBER(15) := 0;
      l_expiration_date       DATE := NULL;
      l_class                 NUMBER(2) := NULL;
      l_group                 NUMBER(2) := NULL;
      l_electrical_indicator  NUMBER(2) := NULL;
      l_unit_of_measure       VARCHAR2(12) := 'EA';
      l_parent_publisher_name VARCHAR2(50) := 'McGraw-Hill School Education LLC';
      l_vendor_catalog        VARCHAR2(20) := NULL;
      l_item_type             VARCHAR2(10) := NULL;
      l_elementary            VARCHAR2(10) := NULL;
      l_intermediate          VARCHAR2(10) := NULL;
      l_secondary             VARCHAR2(10) := NULL;
      l_nystl_indicator       VARCHAR2(10) := NULL;
      l_initiation_date       DATE := NULL;
      l_delivery_code         VARCHAR2(10) := NULL;
      l_tracking              VARCHAR2(10) := NULL;
      l_url_link_item_image   VARCHAR2(150) := NULL;
      l_url_link_ext_vend_des VARCHAR2(150) := NULL;
      l_url_link_msds         VARCHAR2(150) := NULL;
      l_edition_number        NUMBER(4) := NULL;
      l_reading_level         VARCHAR2(2) := NULL;
      l_large_print           VARCHAR2(10) := NULL;
      l_inv_id                NUMBER;
      l_program_name          VARCHAR2(50);
      l_isbn                  VARCHAR2(10);
      l_isbn13                VARCHAR2(13);
      l_imprint               VARCHAR2(50);
      --l_cyear                 NUMBER(2);  --changed for defect 1147
      l_cyear                 VARCHAR2(2);
      l_pdate                 VARCHAR2(4);
      l_grade                 VARCHAR2(11);
      l_contract_name         VARCHAR2(7);
      l_vendor_code           VARCHAR2(9);
      l_rebid                 NUMBER(5,2);
      l_net_price             NUMBER(5,2);
      l_price                 NUMBER(15,2);
      l_author                VARCHAR2(30);
      l_subject_area          VARCHAR2(5);
      l_language              VARCHAR2(15);
      l_marketing_title       VARCHAR2(100);
      l_subtitle              VARCHAR2(100);
      l_ebs_full_title        VARCHAR2(100);
      l_book_title            VARCHAR2(300);
      l_item_form             VARCHAR2(5);
      l_o_division            VARCHAR2(30);
      l_d_medium              VARCHAR2(30);
      l_d_format              VARCHAR2(30);
      l_usage_c               VARCHAR2(30);
      l_prd_usage             VARCHAR2(30);
      l_famis_item            VARCHAR2(5);
      l_error_point           VARCHAR2(100);
      --start of changes for defect 1147
      l_def_nyc_language      VARCHAR2(10);
      l_def_nyc_subject       VARCHAR2(2);
      --end of changes for defect 1147

      -- cursor to fetch bid search name

      CURSOR c_get_inv_item_id(p_bid_search_name VARCHAR2) IS
         SELECT msi.inventory_item_id inv_id
               ,msi.c_ext_attr1       bid_search_name
               ,msi.c_ext_attr2       contract_number
               ,msi.c_ext_attr3       vendor_code
               ,msi.n_ext_attr1       re_bid_price
         FROM   ego_mtl_sy_items_ext_b msi
               ,ego_attr_groups_v      mri
         WHERE  msi.attr_group_id = mri.attr_group_id
         AND    mri.attr_group_name = 'MHE_AG_NYC_EDU_BIDS'
         AND    mri.attr_group_type = 'EGO_ITEMMGMT_GROUP'
         AND    msi.organization_id = (SELECT organization_id
                                       FROM   inv_organization_name_v
                                       WHERE  organization_name = 'US_FULFILL_ORG')
         AND    msi.c_ext_attr1 = p_bid_search_name;
      r_get_inv_item_id c_get_inv_item_id%ROWTYPE;

      -- cursor to fetch program name

      CURSOR c_get_program_name(p_inv_id mtl_system_items_b.inventory_item_id%TYPE) IS
         SELECT mps.product_series_description program_name
                ,mps.nyc_subject_area
                ,mps.nyc_language
         FROM   ego_mtl_sy_items_ext_b   msi
               ,ego_attr_groups_v        mri
               ,mhe_ego_product_series_v mps
         WHERE  msi.attr_group_id = mri.attr_group_id
         AND    msi.c_ext_attr1 = mps.product_series_code
         AND    msi.organization_id = (SELECT organization_id
                                       FROM   inv_organization_name_v
                                       WHERE  organization_name = 'MHE_ITEM_MASTER')
         AND    mri.attr_group_name = 'MHE_AG_PROGRAM_CHAR'
         AND    mri.attr_group_type = 'EGO_ITEMMGMT_GROUP'
         AND    msi.inventory_item_id = p_inv_id;
      r_get_program_name c_get_program_name%ROWTYPE;

      -- cursor to get ISBN Number

      CURSOR c_get_isbn(p_inv_id mtl_system_items_b.inventory_item_id%TYPE) IS
         SELECT segment1 isbn
         FROM   mtl_system_items_b mtl
               ,ego_attr_groups_v  mri
         WHERE  mtl.inventory_item_id = p_inv_id
         AND    mtl.organization_id = (SELECT organization_id
                                       FROM   inv_organization_name_v
                                       WHERE  organization_name = 'MHE_ITEM_MASTER');
      r_get_isbn c_get_isbn%ROWTYPE;

      -- cursor to get ISBN13

      CURSOR c_get_isbn13(p_inv_id mtl_system_items_b.inventory_item_id%TYPE) IS
         SELECT msi.c_ext_attr3 isbn13
         FROM   ego_mtl_sy_items_ext_b msi
               ,ego_attr_groups_v      mri
         WHERE  msi.attr_group_id = mri.attr_group_id
         AND    msi.organization_id = (SELECT organization_id
                                       FROM   inv_organization_name_v
                                       WHERE  organization_name = 'MHE_ITEM_MASTER')
         AND    mri. attr_group_name = 'MHE_AG_PROD_IDENTIFIER'
         AND    mri.attr_group_type = 'EGO_ITEMMGMT_GROUP'
         AND    msi.inventory_item_id = p_inv_id;
      r_get_isbn13 c_get_isbn13%ROWTYPE;

      -- cursor to get imprint

      CURSOR c_get_imprint(p_inv_id mtl_system_items_b.inventory_item_id%TYPE) IS
         SELECT substr(flv.description,1,50) imprint
         FROM   ego_mtl_sy_items_ext_b msi
               ,ego_attr_groups_v      mri
               ,fnd_flex_value_sets    fls
               ,fnd_flex_values_vl     flv
         WHERE  fls.flex_value_set_name = 'MHE_ONIX_IMPRINTS_VS' --change as per defect #1646
         AND    fls.flex_value_set_id = flv.flex_value_set_id
         AND    flv.flex_value = msi.c_ext_attr3
         AND    msi.organization_id = (SELECT organization_id
                                       FROM   inv_organization_name_v
                                       WHERE  organization_name = 'MHE_ITEM_MASTER')
         AND    mri.attr_group_name = 'MHE_AG_PUBLISHER_DETAILS'
         AND    mri.attr_group_type = 'EGO_ITEMMGMT_GROUP'
         AND    mri.attr_group_id = msi.attr_group_id
         AND    msi.inventory_item_id = p_inv_id;
      r_get_imprint c_get_imprint%ROWTYPE;

      -- cursor to get copyright year

      CURSOR c_get_cyear(p_inv_id mtl_system_items_b.inventory_item_id%TYPE) IS
         SELECT substr(to_char(n_ext_attr1),
                       -2) copyright_year
         FROM   ego_mtl_sy_items_ext_b msi
               ,ego_attr_groups_v      mri
         WHERE  msi.attr_group_id = mri.attr_group_id
         AND    msi.organization_id = (SELECT organization_id
                                       FROM   inv_organization_name_v
                                       WHERE  organization_name = 'MHE_ITEM_MASTER')
         AND    mri.attr_group_name = 'MHE_AG_PROD_EDITION_DETAILS'
         AND    mri.attr_group_type = 'EGO_ITEMMGMT_GROUP'
         AND    msi.inventory_item_id = p_inv_id;
      r_get_cyear c_get_cyear%ROWTYPE;

      -- cursor to publication date

      CURSOR c_get_pdate(p_inv_id mtl_system_items_b.inventory_item_id%TYPE) IS
         SELECT (to_char(d_ext_attr1,'YYYY')) publication_date
         FROM   ego_mtl_sy_items_ext_b msi
               ,ego_attr_groups_v      mri
         WHERE  msi.attr_group_id = mri.attr_group_id
         AND    msi.organization_id = (SELECT organization_id
                                       FROM   inv_organization_name_v
                                       WHERE  organization_name = 'MHE_ITEM_MASTER')
         AND    mri.attr_group_name = 'MHE_AG_PROCESSING_CAPABILITY'
         AND    mri.attr_group_type = 'EGO_ITEMMGMT_GROUP'
         AND    msi.inventory_item_id = p_inv_id;
      r_get_pdate c_get_pdate%ROWTYPE;

      -- cursor to get grade

      CURSOR c_get_grade(p_inv_id mtl_system_items_b.inventory_item_id%TYPE) IS
         SELECT (c_ext_attr2 || ' - ' || c_ext_attr3) grade
         FROM   ego_mtl_sy_items_ext_b msi
               ,ego_attr_groups_v      mri
         WHERE  msi.attr_group_id = mri.attr_group_id
         AND    msi.organization_id = (SELECT organization_id
                                       FROM   inv_organization_name_v
                                       WHERE  organization_name = 'MHE_ITEM_MASTER')
         AND    mri.attr_group_name = 'MHE_AG_PROD_AUDIENCE_CHAR'
         AND    mri.attr_group_type = 'EGO_ITEMMGMT_GROUP'
         AND    msi.inventory_item_id = p_inv_id
         --start of changes for defect 1147
         AND    (msi.c_ext_attr2 IS NOT NULL OR msi.c_ext_attr3 IS NOT NULL);
         --end of changes for defect 1147
      r_get_grade c_get_grade%ROWTYPE;

      -- cursor to get price
      -- cursor to get from pricing info AG

      CURSOR c_get_pinfo_price(p_inv_id mtl_system_items_b.inventory_item_id%TYPE) IS
         SELECT n_ext_attr2 net_price
         FROM   ego_mtl_sy_items_ext_b msi
         WHERE  msi.attr_group_id = (SELECT attr_group_id
                                     FROM   ego_attr_groups_v
                                     WHERE  attr_group_name = 'MHE_AG_PRICING_INFO'
                                     AND    attr_group_type = 'EGO_ITEMMGMT_GROUP')
         AND    msi.inventory_item_id = p_inv_id
         AND    msi.organization_id = (SELECT organization_id
                                       FROM   inv_organization_name_v
                                       WHERE  organization_name = 'US_FULFILL_ORG')
         AND    msi.d_ext_attr1 = (SELECT MAX(msi1.d_ext_attr1)
                                   FROM   ego_mtl_sy_items_ext_b msi1
                                   WHERE  msi1.inventory_item_id = msi.inventory_item_id
                                   AND    msi1.organization_id = msi.organization_id
                                   AND    msi1.attr_group_id = msi.attr_group_id);
      r_get_pinfo_price c_get_pinfo_price%ROWTYPE;

      -- cursor to get author
      CURSOR c_get_author(p_inv_id mtl_system_items_b.inventory_item_id%TYPE) IS
         SELECT (msi.c_ext_attr1 || ' ' || msi.c_ext_attr3) author
         FROM   ego_mtl_sy_items_ext_b msi
               ,ego_attr_groups_v      mri
         WHERE  msi.attr_group_id = mri.attr_group_id
         AND    msi.organization_id = (SELECT organization_id
                                       FROM   inv_organization_name_v
                                       WHERE  organization_name = 'MHE_ITEM_MASTER')
         AND    mri.attr_group_name = 'MHE_AG_CONTRIBUTOR_GEN_INFO'
         AND    mri.attr_group_type = 'EGO_ITEMMGMT_GROUP'
         AND    msi.inventory_item_id = (SELECT mdn.c_ext_attr1
                                         FROM   ego_mtl_sy_items_ext_b mdn
                                         WHERE  mdn.organization_id = msi.organization_id
                                         AND    mdn.attr_group_id = (SELECT attr_group_id
                                                                     FROM   ego_attr_groups_v
                                                                     WHERE  attr_group_name = 'MHE_AG_CONTRIBUTORS'
                                                                     AND    attr_group_type = 'EGO_ITEMMGMT_GROUP')
                                         AND    mdn.n_ext_attr1 = 1
                                         AND    inventory_item_id = p_inv_id);
      r_get_author c_get_author%ROWTYPE;

      -- cursor to get author from product details AG
      CURSOR c_get_author_ped(p_inv_id mtl_system_items_b.inventory_item_id%TYPE) IS
         SELECT c_ext_attr1 lead_contributor
         FROM   ego_mtl_sy_items_ext_b msi
               ,ego_attr_groups_v      mri
         WHERE  msi.attr_group_id = mri.attr_group_id
         AND    msi.organization_id = (SELECT organization_id
                                       FROM   inv_organization_name_v
                                       WHERE  organization_name = 'MHE_ITEM_MASTER')
         AND    mri.attr_group_name = 'MHE_AG_PROD_EDITION_DETAILS'
         AND    mri.attr_group_type = 'EGO_ITEMMGMT_GROUP'
         AND    msi.inventory_item_id = p_inv_id;
      r_get_author_ped c_get_author_ped%ROWTYPE;

      -- cursor to get subject area
      CURSOR c_get_subject_area(p_inv_id mtl_system_items_b.inventory_item_id%TYPE) IS
         SELECT nyc_subject_area subject_area
         FROM   mhe_ego_product_series_v
         WHERE  product_series_code = (SELECT c_ext_attr1
                                       FROM   ego_mtl_sy_items_ext_b msi
                                             ,ego_attr_groups_v      mri
                                       WHERE  msi.attr_group_id = mri.attr_group_id
                                       AND    msi.organization_id = (SELECT organization_id
                                                                     FROM   inv_organization_name_v
                                                                     WHERE  organization_name = 'MHE_ITEM_MASTER')
                                       AND    mri.attr_group_name = 'MHE_AG_PROGRAM_CHAR'
                                       AND    mri.attr_group_type = 'EGO_ITEMMGMT_GROUP'
                                       AND    msi.inventory_item_id = p_inv_id);
      r_get_subject_area c_get_subject_area%ROWTYPE;

      -- cursor to get language
      CURSOR c_get_language(p_inv_id mtl_system_items_b.inventory_item_id%TYPE) IS
         SELECT c_ext_attr5 language_code
         FROM   ego_mtl_sy_items_ext_b msi
               ,ego_attr_groups_v      mri
         WHERE  msi.attr_group_id = mri.attr_group_id
         AND    msi.organization_id = (SELECT organization_id
                                       FROM   inv_organization_name_v
                                       WHERE  organization_name = 'MHE_ITEM_MASTER')
         AND    mri.attr_group_name = 'MHE_AG_PROD_AUDIENCE_CHAR'
         AND    mri.attr_group_type = 'EGO_ITEMMGMT_GROUP'
         AND    msi.inventory_item_id = p_inv_id;
      r_get_language c_get_language%ROWTYPE;

      -- cursor to get book title
      CURSOR c_get_book_title(p_inv_id mtl_system_items_b.inventory_item_id%TYPE) IS
         SELECT msi.tl_ext_attr4 marketing_title
               ,msi.tl_ext_attr5 subtitle
         FROM   ego_mtl_sy_items_ext_tl msi
               ,ego_attr_groups_v       mri
         WHERE  msi.attr_group_id = mri.attr_group_id
         AND    msi.organization_id = (SELECT organization_id
                                       FROM   inv_organization_name_v
                                       WHERE  organization_name = 'MHE_ITEM_MASTER')
         AND    mri.attr_group_name = 'MHE_AG_MARKETING_TITLE_INFO'
         AND    mri.attr_group_type = 'EGO_ITEMMGMT_GROUP'
         AND    msi.inventory_item_id = p_inv_id
         AND    msi.LANGUAGE = 'US';
      r_get_book_title c_get_book_title%ROWTYPE;

      -- cursor to get book title from product title AG
      CURSOR c_get_book_title_product(p_inv_id mtl_system_items_b.inventory_item_id%TYPE) IS
         SELECT c_ext_attr1 ebs_full_title
         FROM   ego_mtl_sy_items_ext_b msi
               ,ego_attr_groups_v      mri
         WHERE  msi.attr_group_id = mri.attr_group_id
         AND    msi.organization_id = (SELECT organization_id
                                       FROM   inv_organization_name_v
                                       WHERE  organization_name = 'MHE_ITEM_MASTER')
         AND    mri.attr_group_name = 'MHE_AG_PROD_TITLE_INFO'
         AND    mri.attr_group_type = 'EGO_ITEMMGMT_GROUP'
         AND    msi.inventory_item_id = p_inv_id;
      r_get_book_title_product c_get_book_title_product%ROWTYPE;

      -- cursor to get item form
      CURSOR c_get_item_form(p_inv_id mtl_system_items_b.inventory_item_id%TYPE) IS
         SELECT flv.attribute1 product_form
         FROM   ego_mtl_sy_items_ext_b msi
               ,ego_attr_groups_v      mri
               ,fnd_flex_value_sets    fls
               ,fnd_flex_values_vl     flv
         WHERE  fls.flex_value_set_name = 'MHE_ONIX_PRDCT_FRM_VS'
         AND    fls.flex_value_set_id = flv.flex_value_set_id
         AND    flv.flex_value = msi.c_ext_attr1
         AND    flv.value_category = 'MHE_ONIX_PRDCT_FRM_VS'
         AND    msi.organization_id = (SELECT organization_id
                                       FROM   inv_organization_name_v
                                       WHERE  organization_name = 'MHE_ITEM_MASTER')
         AND    mri.attr_group_name = 'MHE_AG_ONIX_PRODUCT_FORM'
         AND    mri.attr_group_type = 'EGO_ITEMMGMT_GROUP'
         AND    mri.attr_group_id = msi.attr_group_id
         AND    msi.inventory_item_id = p_inv_id;
      r_get_item_form c_get_item_form%ROWTYPE;

      -- cursor to get item type
      -- cursor to get owning division
      CURSOR c_get_owning_division(p_inv_id mtl_system_items_b.inventory_item_id%TYPE) IS
         SELECT c_ext_attr3 owning_division
         FROM   ego_mtl_sy_items_ext_b msi
               ,ego_attr_groups_v      mri
         WHERE  msi.attr_group_id = mri.attr_group_id
         AND    msi.organization_id = (SELECT organization_id
                                       FROM   inv_organization_name_v
                                       WHERE  organization_name = 'MHE_ITEM_MASTER')
         AND    mri.attr_group_name = 'MHE_AG_PROD_OWNING_CHAR'
         AND    mri.attr_group_type = 'EGO_ITEMMGMT_GROUP'
         AND    msi.inventory_item_id = p_inv_id;
      r_get_owning_division c_get_owning_division%ROWTYPE;

      -- cursor to get from PRod usage AG
      CURSOR c_get_prod_usage(p_inv_id mtl_system_items_b.inventory_item_id%TYPE) IS
         SELECT c_ext_attr1 delivery_medium
               ,c_ext_attr2 delivery_format
               ,c_ext_attr3 usage_classification
               ,c_ext_attr4 product_usage
         FROM   ego_mtl_sy_items_ext_b msi
               ,ego_attr_groups_v      mri
         WHERE  msi.attr_group_id = mri.attr_group_id
         AND    msi.organization_id = (SELECT organization_id
                                       FROM   inv_organization_name_v
                                       WHERE  organization_name = 'MHE_ITEM_MASTER')
         AND    mri.attr_group_name = 'MHE_AG_PROD_USAGE'
         AND    mri.attr_group_type = 'EGO_ITEMMGMT_GROUP'
         AND    msi.inventory_item_id = p_inv_id;
      r_get_prod_usage c_get_prod_usage%ROWTYPE;

      -- cursor to get famis_item
      CURSOR c_get_famis_item(p_l_o_division r_get_owning_division.owning_division%TYPE
                             , p_l_d_medium r_get_prod_usage.delivery_medium%TYPE
                             , p_l_d_format r_get_prod_usage.delivery_format%TYPE
                             , p_l_usage_c r_get_prod_usage.usage_classification%TYPE
                             , p_l_prd_usage r_get_prod_usage.product_usage%TYPE) IS
         SELECT famis_item_type famis_item
                --start of changes for defect 1147
                ,(SELECT flv.attribute1
                  FROM fnd_flex_value_sets    fls
                       ,fnd_flex_values_vl     flv
                  WHERE  fls.flex_value_set_name = 'MHE_ONIX_PRDCT_FRM_VS'
                  AND    fls.flex_value_set_id = flv.flex_value_set_id
                  AND    flv.flex_value =onix_product_form) famis_item_form
                --end of changes for defect 1147
         FROM   mhe_ego_prdusg_grid_v
         WHERE  delivery_medium = p_l_d_medium
         AND    delivery_format = p_l_d_format
         AND    usage_classification = p_l_usage_c
         AND    product_usage = p_l_prd_usage
         AND    owning_division = p_l_o_division
         AND    s_delivery_medium IS NULL
         AND    s_prodmedia_type IS NULL;
      r_get_famis_item c_get_famis_item%ROWTYPE;

   BEGIN
      retcode := '0';
      errbuf  := NULL;
      fnd_file.put_line(fnd_file.output,
                        'Application code' || ',' ||
                        'Item number' || ',' ||
                        'Check digit' || ',' ||
                        'Maintenance Code' || ',' ||
                        'Price' || ',' ||
                        'Delivery charge' || ',' ||
                        'Expiration Date' || ',' ||
                        'Contract number' || ',' ||
                        'Vendor Code' || ',' ||
                        'Class' || ',' ||
                        'Group' || ',' ||
                        'Electrical Indicator' || ',' ||
                        'Unit of measure' || ',' ||
                        'Book title and Main Description' || ',' ||
                        'Imprint/Brand Name' || ',' ||
                        'Parent Publisher Name' || ',' ||
                        'Program name' || ',' ||
                        'Vendor Catalog Name' || ',' ||
                        'ISBN Number (10 digit)' || ',' ||
                        'ISBN Number (13 digit)' || ',' ||
                        'Item Type' || ',' ||
                        'Elementary' || ',' ||
                        'Intermediate' || ',' ||
                        'Secondary' || ',' ||
                        'Copyright year' || ',' ||
                        'NYSTL indicator' || ',' ||
                        'Initiation Date' || ',' ||
                        'Delivery Code' || ',' ||
                        'Tracking' || ',' ||
                        'URL Link for Item Image' || ',' ||
                        'URL Link for Extended Vendor Description' || ',' ||
                        'URL Link for MSDS Sheet' || ',' ||
                        'Author' || ',' ||
                        'Subject Area' || ',' ||
                        'Language/Licensing' || ',' ||
                        'Edition Number/Media Type' || ',' ||
                        'Reading Level/Platform' || ',' ||
                        'Grade' || ',' ||
                        'Item Form' || ',' ||
                        'Publication Date' || ',' ||
                        'Item Type' || ',' ||
                        'Large Print or Braille');

      -- for c_get_inv_item_id cursor

      FOR r_get_inv_item_id IN c_get_inv_item_id(p_bid_search_name) LOOP
         l_error_point   := 'Cursor c_get_inv_item_id for inv_item_id ' ||
                            l_inv_id;
         l_inv_id        := r_get_inv_item_id.inv_id;
         l_contract_name := (substr(r_get_inv_item_id.contract_number,1,7));
         l_vendor_code   := (substr(r_get_inv_item_id.vendor_code,1,9));
         l_rebid         := r_get_inv_item_id.re_bid_price;

         -- for c_get_program_name

         l_error_point := 'Cursor c_get_program_name for inv_item_id ' ||
                          l_inv_id;
         OPEN c_get_program_name(l_inv_id);
         FETCH c_get_program_name
            INTO r_get_program_name;
         IF (c_get_program_name%FOUND) THEN
            --start of changes for defect 1147
            l_program_name := (REPLACE(REPLACE(REPLACE(regexp_replace(r_get_program_name.program_name,'<[^>]*>'),
                                                          chr(13),''),
                                                  chr(10),''),
                                          ',',''));
            l_def_nyc_language := r_get_program_name.nyc_language;
            l_def_nyc_subject  := r_get_program_name.nyc_subject_area;
            --end of changes for defect 1147
         ELSE
            l_program_name := NULL;
         END IF;
         CLOSE c_get_program_name;

         -- for c_get_isbn
         l_error_point := 'Cursor c_get_isbn for inv_item_id ' || l_inv_id;
         OPEN c_get_isbn(l_inv_id);
         FETCH c_get_isbn
            INTO r_get_isbn;
         IF (c_get_isbn%FOUND) THEN
            l_isbn := r_get_isbn.isbn;
         ELSE
            l_isbn := NULL;
         END IF;
         CLOSE c_get_isbn;

         -- for c_get_isbn13
         l_error_point := 'Cursor c_get_isbn13 for inv_item_id ' ||
                          l_inv_id;
         OPEN c_get_isbn13(l_inv_id);
         FETCH c_get_isbn13
            INTO r_get_isbn13;
         IF (c_get_isbn13%FOUND) THEN
            l_isbn13 := r_get_isbn13.isbn13;
         ELSE
            l_isbn13 := NULL;
         END IF;
         CLOSE c_get_isbn13;

         -- for c_get_imprint
         l_error_point := 'Cursor c_get_imprint for inv_item_id ' ||
                          l_inv_id;
         OPEN c_get_imprint(l_inv_id);
         FETCH c_get_imprint
            INTO r_get_imprint;
         IF (c_get_imprint%FOUND) THEN
            l_imprint := r_get_imprint.imprint;
         ELSE
            l_imprint := NULL;
         END IF;
         CLOSE c_get_imprint;

         -- for c_get_cyear
         l_error_point := 'Cursor c_get_cyear for inv_item_id ' || l_inv_id;
         OPEN c_get_cyear(l_inv_id);
         FETCH c_get_cyear
            INTO r_get_cyear;
         IF (c_get_cyear%FOUND) THEN
            l_cyear := r_get_cyear.copyright_year;
         ELSE
            l_cyear := NULL;
         END IF;
         CLOSE c_get_cyear;

         -- for c_get_pdate
         l_error_point := 'Cursor c_get_pdate for inv_item_id ' || l_inv_id;
         OPEN c_get_pdate(l_inv_id);
         FETCH c_get_pdate
            INTO r_get_pdate;
         IF (c_get_pdate%FOUND) THEN
            l_pdate := r_get_pdate.publication_date;
         ELSE
            l_pdate := NULL;
         END IF;
         CLOSE c_get_pdate;

         -- for c_get_grade
         l_error_point := 'Cursor c_get_grade for inv_item_id ' || l_inv_id;
         OPEN c_get_grade(l_inv_id);
         FETCH c_get_grade
            INTO r_get_grade;
         IF (c_get_grade%FOUND) THEN
            l_grade := (substr(r_get_grade.grade,1,11));
         ELSE
            l_grade := NULL;
         END IF;
         CLOSE c_get_grade;

         -- for price
         IF (l_rebid IS NULL) THEN
            l_error_point := 'Cursor c_get_pinfo_price for inv_item_id ' ||
                             l_inv_id;
            OPEN c_get_pinfo_price(l_inv_id);
            FETCH c_get_pinfo_price
               INTO r_get_pinfo_price;
            IF (c_get_pinfo_price%FOUND) THEN
               l_net_price := r_get_pinfo_price.net_price;
               --start of changes for defect 1147
               l_price     := l_net_price + (l_net_price * nvl(p_freight_percentage,1));  --changed for defect 1147
               --end of changes for defect 1147
            ELSE
               l_price := NULL;
            END IF;
            CLOSE c_get_pinfo_price;
         ELSE
            l_price := l_rebid;
         END IF;

         -- for author
         l_error_point := 'Cursor c_get_author for inv_item_id ' ||
                          l_inv_id;
         OPEN c_get_author(l_inv_id);
         FETCH c_get_author
            INTO r_get_author;
         IF (c_get_author%FOUND) THEN
            l_author := (substr(r_get_author.author,1,30));
         ELSE
            l_error_point := 'Cursor c_get_author_ped for inv_item_id ' ||
                             l_inv_id;
            OPEN c_get_author_ped(l_inv_id);
            FETCH c_get_author_ped
               INTO r_get_author_ped;
            l_author := (substr(r_get_author_ped.lead_contributor,1,30));
            CLOSE c_get_author_ped; --added for defect 1147
         END IF;
         l_author := REPLACE(l_author,',','');
         CLOSE c_get_author;

         --start of changes for defect 1147
         IF l_def_nyc_subject IS NULL THEN
            -- for subject area
            l_error_point := 'Cursor c_get_subject_area for inv_item_id ' ||
                             l_inv_id;
            OPEN c_get_subject_area(l_inv_id);
            FETCH c_get_subject_area
               INTO r_get_subject_area;
            IF (c_get_subject_area%FOUND) THEN
               l_subject_area := (substr(r_get_subject_area.subject_area,1,2));
            ELSE
               l_subject_area := NULL;
            END IF;
            CLOSE c_get_subject_area;
         ELSE
            l_subject_area :=l_def_nyc_subject;
         END IF;
         --end of changes for defect 1147

         --start of changes for defect 1147
         IF l_def_nyc_language IS NULL THEN
            -- for language
            l_error_point := 'Cursor c_get_language for inv_item_id ' ||
                             l_inv_id;
            OPEN c_get_language(l_inv_id);
            FETCH c_get_language
               INTO r_get_language;
            IF (c_get_language%FOUND) THEN
               /*IF (r_get_language.language_code NOT IN ('eng', 'Eng') AND
                  l_subject_area = 'FL') THEN
                  l_language := (substr(r_get_language.language_code,1,10));
               ELSE
                  l_language := NULL;
               END IF;*/
               l_language := r_get_language.language_code;
            END IF;
            CLOSE c_get_language;
         ELSE
            l_language := l_def_nyc_language;
         END IF;
         IF (l_language NOT IN ('eng','Eng') AND l_subject_area = 'FL') THEN
            l_language := (substr(l_language,1,10));
         ELSE
            l_language := NULL;
         END IF;
         --end of changes for defect 1147

         -- for book title
         l_error_point := 'Cursor c_get_book_title for inv_item_id ' ||
                          l_inv_id;
         OPEN c_get_book_title(l_inv_id);
         FETCH c_get_book_title
            INTO r_get_book_title;
         IF (c_get_book_title%FOUND) THEN
            l_marketing_title := (REPLACE(REPLACE(REPLACE(regexp_replace(r_get_book_title.marketing_title,'<[^>]*>'),
                                                          chr(13),''),
                                                  chr(10),''),
                                          ',',''));
            l_subtitle        := (REPLACE(REPLACE(REPLACE(regexp_replace(r_get_book_title.subtitle,'<[^>]*>'),
                                                          chr(13),''),
                                                  chr(10),''),
                                          ',',''));
         END IF;
         CLOSE c_get_book_title;
         IF (l_marketing_title IS NULL) THEN
            l_error_point := 'Cursor c_get_book_title_product for inv_item_id ' ||
                             l_inv_id;
            OPEN c_get_book_title_product(l_inv_id);
            FETCH c_get_book_title_product
               INTO r_get_book_title_product;
            IF (c_get_book_title_product%FOUND) THEN
               --start of changes for defect 1147
               l_ebs_full_title := (REPLACE(REPLACE(REPLACE(regexp_replace(r_get_book_title_product.ebs_full_title,'<[^>]*>'),
                                                          chr(13),''),
                                                  chr(10),''),
                                          ',',''));
               --end of changes for defect 1147
               IF ( l_subtitle IS NULL ) THEN
                  l_book_title := l_ebs_full_title;
               ELSE
               l_book_title     := (substr(l_ebs_full_title || ':' ||l_subtitle,1,250));
               END IF;
            ELSE
               l_book_title := NULL;
            END IF;
            CLOSE c_get_book_title_product;
         ELSE
            IF ( l_subtitle IS NULL ) THEN
               l_book_title := l_marketing_title;
            ELSE
            l_book_title := (substr(l_marketing_title || ':' || l_subtitle,1,250));
            END IF;
         END IF;

         -- for item form
         l_error_point := 'Cursor c_get_item_form for inv_item_id ' ||
                          l_inv_id;
         OPEN c_get_item_form(l_inv_id);
         FETCH c_get_item_form
            INTO r_get_item_form;
         IF (c_get_item_form%FOUND) THEN
            l_item_form := (substr(r_get_item_form.product_form,1,2));
         ELSE
            l_item_form := NULL;
         END IF;
         CLOSE c_get_item_form;

         -- for item type
         l_error_point := 'Cursor c_get_owning_division for inv_item_id ' ||
                          l_inv_id;
         OPEN c_get_owning_division(l_inv_id);
         FETCH c_get_owning_division
            INTO r_get_owning_division;
         IF (c_get_owning_division%FOUND) THEN
            l_o_division := r_get_owning_division.owning_division;
         ELSE
            l_o_division := NULL;
         END IF;
         CLOSE c_get_owning_division;
         l_error_point := 'Cursor c_get_prod_usage for inv_item_id ' ||
                          l_inv_id;
         OPEN c_get_prod_usage(l_inv_id);
         FETCH c_get_prod_usage
            INTO r_get_prod_usage;
         IF (c_get_prod_usage%FOUND) THEN
            l_d_medium  := r_get_prod_usage.delivery_medium;
            l_d_format  := r_get_prod_usage.delivery_format;
            l_usage_c   := r_get_prod_usage.usage_classification;
            l_prd_usage := r_get_prod_usage.product_usage;
         END IF;
         CLOSE c_get_prod_usage;
         l_error_point := 'Cursor c_get_famis_itemod_usage for inv_item_id ' ||
                          l_inv_id;
         OPEN c_get_famis_item(l_o_division,
                               l_d_medium,
                               l_d_format,
                               l_usage_c,
                               l_prd_usage);
         FETCH c_get_famis_item
            INTO r_get_famis_item;
         IF (c_get_famis_item%FOUND) THEN
            l_famis_item := (substr(r_get_famis_item.famis_item,1,2));
            --start of changes for defect 1147
            --if item form on product is NULL then pick product form from product usage grid
            IF l_item_form IS NULL THEN
               l_item_form := r_get_famis_item.famis_item_form;
            END IF;
            --end of changes for defect 1147
         ELSE
            l_famis_item := NULL;
         END IF;
         CLOSE c_get_famis_item;

         fnd_file.put_line(fnd_file.output,
                            l_application_code || ','
                          ||l_item_number || ','
                          ||l_check_digit || ','
                          ||l_maintenance_code || ','
                          ||l_price ||','
                          ||l_delivery_charge || ','
                          ||l_expiration_date || ','
                          ||l_contract_name   || ','
                          ||l_vendor_code || ','
                          ||l_class || ','
                          ||l_group || ','
                          ||l_electrical_indicator || ','
                          ||l_unit_of_measure || ','
                          ||l_book_title || ','
                          ||l_imprint ||','
                          ||l_parent_publisher_name || ','
                          ||l_program_name || ','
                          ||l_vendor_catalog || ','
                          ||l_isbn ||','
                          ||l_isbn13 || ','
                          ||l_item_type || ','
                          ||l_elementary || ','
                          ||l_intermediate || ','
                          ||l_secondary || ','
                          ||l_cyear ||','
                          ||l_nystl_indicator || ','
                          ||l_initiation_date || ','
                          ||l_delivery_code || ','
                          ||l_tracking || ','
                          ||l_url_link_item_image || ','
                          ||l_url_link_ext_vend_des || ','
                          ||l_url_link_msds || ','
                          ||l_author || ','
                          ||l_subject_area ||','
                          ||l_language || ','
                          ||l_edition_number ||','
                          ||l_reading_level || ','
                          ||l_grade || ','
                          ||l_item_form || ','
                          ||l_pdate || ','
                          ||l_famis_item || ','
                          ||l_large_print);

         l_inv_id          := NULL;
         l_program_name    := NULL;
         l_isbn            := NULL;
         l_isbn13          := NULL;
         l_imprint         := NULL;
         l_cyear           := NULL;
         l_pdate           := NULL;
         l_grade           := NULL;
         l_contract_name   := NULL;
         l_vendor_code     := NULL;
         l_rebid           := NULL;
         l_net_price       := NULL;
         l_price           := NULL;
         l_author          := NULL;
         l_subject_area    := NULL;
         l_language        := NULL;
         l_marketing_title := NULL;
         l_subtitle        := NULL;
         l_ebs_full_title  := NULL;
         l_book_title      := NULL;
         l_item_form       := NULL;
         l_o_division      := NULL;
         l_d_medium        := NULL;
         l_d_format        := NULL;
         l_usage_c         := NULL;
         l_prd_usage       := NULL;
         l_famis_item      := NULL;

      END LOOP;

   EXCEPTION
      WHEN OTHERS THEN
         retcode := 2;
         errbuf  := SQLERRM || ' after ' || l_error_point;
         fnd_file.put_line(fnd_file.log,
                           errbuf);

   END mhe_ego_nycdoe_pr;

END mhe_ego_nycdoe_extract_pkg;




