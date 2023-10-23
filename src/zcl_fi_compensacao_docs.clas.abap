CLASS zcl_fi_compensacao_docs DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

    PUBLIC SECTION.

        CONSTANTS:
            c_stype_header TYPE ftpost-stype VALUE 'K',
            c_stype_item TYPE ftpost-stype VALUE 'P',

            C_AUGLV_OUTGOING_PAYMENT TYPE AUGLV VALUE 'AUSGZAHL',
            C_AUGLV_INCOMING_PAYMENT TYPE AUGLV VALUE 'EINGZAHL',
            C_AUGLV_CREDIT_MEMO TYPE AUGLV VALUE 'GUTSCHRI',
            C_AUGLV_TRANSFER_POST_CLEARING TYPE AUGLV VALUE 'UMBUCHNG'.

        TYPES:
            ty_t_blntab TYPE STANDARD TABLE OF blntab.

        METHODS:

            constructor
                IMPORTING
                    IV_BLDAT TYPE BKPF-BLDAT DEFAULT SY-DATUM
                    IV_BLART TYPE BKPF-BLART
                    IV_BUKRS TYPE BKPF-BUKRS
                    IV_BUDAT TYPE BKPF-BUDAT DEFAULT SY-DATUM
                    IV_MONAT TYPE BKPF-MONAT DEFAULT SY-DATUM+4(2)
                    IV_WAERS TYPE BKPF-WAERS,

            ADD_DOCUMENT
                IMPORTING
                    IV_AGKOA TYPE FTCLEAR-AGKOA
                    IV_XNOPS TYPE FTCLEAR-XNOPS DEFAULT 'X'
                    IV_agbuk TYPE FTCLEAR-agbuk OPTIONAL
                    IV_AGKON TYPE FTCLEAR-AGKON
                    iv_belnr TYPE belnr_d,

            compensar
                IMPORTING
                    IV_AUGLV TYPE AUGLV DEFAULT C_AUGLV_TRANSFER_POST_CLEARING
                EXPORTING
                    et_blntab TYPE ty_t_blntab
                RAISING
                    zcx_fi_compensacao_docs.

    PROTECTED SECTION.

        DATA:
            LV_BUKRS TYPE BUKRS,

            lt_ftpost TYPE STANDARD TABLE OF ftpost,
            LT_FTCLEAR TYPE STANDARD TABLE OF FTCLEAR.

        METHODS:

            ADD_FIELD_TO_HEADER
                IMPORTING
                    IV_FIELD TYPE CSEQUENCE
                    IV_VALUE TYPE ANY.

    PRIVATE SECTION.

ENDCLASS.



CLASS zcl_fi_compensacao_docs IMPLEMENTATION.

    METHOD ADD_FIELD_TO_HEADER.

        CHECK IV_VALUE IS NOT INITIAL.

        APPEND INITIAL LINE TO lt_ftpost ASSIGNING FIELD-SYMBOL(<ls_ftpost>).
        <ls_ftpost>-stype = c_stype_header.
        <ls_ftpost>-count = '001'.
        <ls_ftpost>-fnam  = iv_field.
        WRITE iv_value TO <ls_ftpost>-fval.

    ENDMETHOD.

    METHOD ADD_DOCUMENT.

        APPEND INITIAL LINE TO LT_FTCLEAR ASSIGNING FIELD-SYMBOL(<LS_FTCLEAR>).
        <LS_FTCLEAR>-agkoa = IV_AGKOA.
        <LS_FTCLEAR>-XNOPS = iv_xnops.
        <LS_FTCLEAR>-agbuk = COND #( WHEN IV_agbuk IS INITIAL THEN LV_BUKRS ELSE IV_agbuk ).
        <LS_FTCLEAR>-AGKON = IV_AGKON.
        <LS_FTCLEAR>-SELFD = 'BELNR'.
        <LS_FTCLEAR>-SELVON = iv_belnr.


    ENDMETHOD.

    METHOD constructor.

        ME->add_field_to_header(
            iv_field = 'BKPF-BLDAT'
            iv_value = IV_BLDAT
        ).

        ME->add_field_to_header(
            iv_field = 'BKPF-BLART'
            iv_value = IV_BLART
        ).

        ME->add_field_to_header(
            iv_field = 'BKPF-BUKRS'
            iv_value = IV_BUKRS
        ).
        LV_BUKRS = IV_BUKRS.

        ME->add_field_to_header(
            iv_field = 'BKPF-BUDAT'
            iv_value = IV_BUDAT
        ).

        ME->add_field_to_header(
            iv_field = 'BKPF-MONAT'
            iv_value = IV_MONAT
        ).

        ME->add_field_to_header(
            iv_field = 'BKPF-WAERS'
            iv_value = IV_WAERS
        ).

    ENDMETHOD.

    METHOD compensar.

        clear et_blntab.

        call FUNCTION 'POSTING_INTERFACE_START'
          EXPORTING
*            i_client           = SY-MANDT
            i_function         = 'C'
*            i_group            = space
*            i_holddate         = space
*            i_keep             = space
*            i_mode             = 'N'
*            i_update           = 'S'
*            i_user             = space
*            i_xbdcc            = space
*            i_bdc_app_area     = space
          EXCEPTIONS
            client_incorrect   = 1
            function_invalid   = 2
            group_name_missing = 3
            mode_invalid       = 4
            update_invalid     = 5
            user_invalid       = 6
            others             = 7
          .

        IF SY-SUBRC <> 0.

            MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4
            INTO DATA(lv_tmp_message).

            RAISE EXCEPTION TYPE zcx_fi_compensacao_docs.

        ENDIF.


        DATA:
            lv_msgid type sy-msgid,
            lv_msgno type sy-msgno,
            lv_msgty type sy-msgty,
            lv_msgv1 type sy-msgv1,
            lv_msgv2 type sy-msgv2,
            lv_msgv3 type sy-msgv3,
            lv_msgv4 type sy-msgv4,
            lv_subrc type sy-subrc.

        data:
            lt_fttax TYPE STANDARD TABLE OF fttax.

        CALL FUNCTION 'POSTING_INTERFACE_CLEARING'
          EXPORTING
            i_auglv                    = iv_auglv
            i_tcode                    = 'FB05'
*            i_sgfunct                  = space
*            i_no_auth                  = space
*            i_xsimu                    = space
          IMPORTING
            e_msgid                    = lv_msgid
            e_msgno                    = lv_msgno
            e_msgty                    = lv_msgty
            e_msgv1                    = lv_msgv1
            e_msgv2                    = lv_msgv2
            e_msgv3                    = lv_msgv3
            e_msgv4                    = lv_msgv4
            e_subrc                    = lv_subrc
          TABLES
            t_blntab                   = et_blntab
            t_ftclear                  = lt_ftclear
            t_ftpost                   = lt_ftpost
            t_fttax                    = lt_fttax
          EXCEPTIONS
            clearing_procedure_invalid = 1
            clearing_procedure_missing = 2
            table_t041a_empty          = 3
            transaction_code_invalid   = 4
            amount_format_error        = 5
            too_many_line_items        = 6
            company_code_invalid       = 7
            screen_not_found           = 8
            no_authorization           = 9
            others                     = 10
          .
        IF SY-SUBRC <> 0.

            MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4
            INTO lv_tmp_message.

            RAISE EXCEPTION TYPE zcx_fi_compensacao_docs.

        ENDIF.


        CALL FUNCTION 'POSTING_INTERFACE_END'
          EXPORTING
            i_bdcimmed              = space
*            i_bdcstrtdt             = NO_DATE
*            i_bdcstrttm             = NO_TIME
          EXCEPTIONS
            session_not_processable = 1
            others                  = 2
          .

        IF SY-SUBRC <> 0.

            MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4
            INTO lv_tmp_message.

            RAISE EXCEPTION TYPE zcx_fi_compensacao_docs.

        ENDIF.

    ENDMETHOD.

ENDCLASS.
