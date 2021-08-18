FUNCTION Z_FBC_SEND_MAIL_WITH_BCS.
*"----------------------------------------------------------------------
*"*"Interface local:
*"  IMPORTING
*"     REFERENCE(SAPUSER_SENDER) TYPE  SY-UNAME OPTIONAL
*"     REFERENCE(MAIL_SENDER) TYPE  AD_SMTPADR OPTIONAL
*"     REFERENCE(REPLY_TO) TYPE  AD_SMTPADR OPTIONAL
*"     REFERENCE(REQUESTED_STATUS) TYPE  BCS_RQST DEFAULT 'E'
*"     REFERENCE(DOCUMENTS) TYPE  ZCTBC_BDC_EMAIL_DOCUMENTS_ROW
*"     REFERENCE(RECIPIENTS) TYPE  ZCTBC_BDC_EMAIL_RECIPIENTS_ROW
*"     REFERENCE(DO_COMMIT_WORK) TYPE  FLAG DEFAULT 'X'
*"  EXPORTING
*"     REFERENCE(ERRO_ENVIO)
*"----------------------------------------------------------------------

*----------------------------------------------------------------------*
* CLASS-DEFINITIONS                                                    *
*----------------------------------------------------------------------*
  DATA: send_request       TYPE REF TO cl_bcs.
  DATA: document           TYPE REF TO cl_document_bcs.
  DATA: sender             TYPE REF TO cl_sapuser_bcs.
  DATA: replyer_to         type REF TO cl_cam_address_bcs.
  DATA: sender_int_addr    type ref to cl_cam_address_bcs .
  DATA: recipient          TYPE REF TO if_recipient_bcs.
  DATA: exception_info     TYPE REF TO if_os_exception_info,
        bcs_exception      TYPE REF TO cx_bcs.

*----------------------------------------------------------------------*
* INTERNAL TABLES                                                      *
*----------------------------------------------------------------------*
  DATA: l_mailtext TYPE soli_tab.
  DATA: l_mailhex  TYPE solix_tab.
  DATA: iaddsmtp   TYPE bapiadsmtp OCCURS 0 WITH HEADER LINE.
  DATA: ireturn    TYPE bapiret2 OCCURS 0 WITH HEADER LINE.

*----------------------------------------------------------------------*
* VARIABLES                                                            *
*----------------------------------------------------------------------*
  DATA: mail_line  LIKE LINE OF l_mailtext.
  DATA: mailx_line LIKE LINE OF l_mailhex.
  DATA: bapiadsmtp         TYPE bapiadsmtp.
  DATA VL_COBR(1) TYPE C.
*----------------------------------------------------------------------*
* CONSTANTS                                                            *
*----------------------------------------------------------------------*


  CLASS cl_cam_address_bcs DEFINITION LOAD.
  CLASS cl_abap_char_utilities DEFINITION LOAD.

  TRY.
* Create persistent send request
      send_request = cl_bcs=>create_persistent( ).

      DATA: first(1) TYPE c.
      CLEAR first.
      DATA: documents_line LIKE LINE OF documents.

      LOOP AT documents INTO documents_line.
        IF first IS INITIAL.
          MOVE 'X' TO first.
* Build the Main Document
          IF documents_line-content_hex[] IS INITIAL.
            document = cl_document_bcs=>create_document(
                                i_type    = documents_line-type
                                i_text    = documents_line-content_text
                                i_subject = documents_line-subject ).
          ELSE.
            document = cl_document_bcs=>create_document(
                                i_type    = documents_line-type
                                i_hex     = documents_line-content_hex
                                i_subject = documents_line-subject ).
          ENDIF.
        ELSE.
          IF documents_line-content_hex[] IS INITIAL.
* Add Attachment
            CALL METHOD document->add_attachment
              EXPORTING
                i_attachment_type    = documents_line-type
                i_attachment_subject = documents_line-subject
                i_att_content_text   = documents_line-content_text.
          ELSE.
            CALL METHOD document->add_attachment
              EXPORTING
                i_attachment_type    = documents_line-type
                i_attachment_subject = documents_line-subject
                i_att_content_hex    = documents_line-content_hex.
          ENDIF.
        ENDIF.
      ENDLOOP.


* Add document to send request
      CALL METHOD send_request->set_document( document ).

 CLEAR VL_COBR.
      DATA: recipients_line LIKE LINE OF recipients.



** Get sender object

  if MAIL_SENDER is INITIAL.
     sender = cl_sapuser_bcs=>create( SAPUSER_SENDER ).

      CALL METHOD send_request->set_sender
        EXPORTING
          i_sender = sender.

  else.
     sender_int_addr = cl_cam_address_bcs=>create_internet_address( mail_sender ).

     CALL METHOD send_request->set_sender
        EXPORTING
          i_sender = sender_int_addr.
  endif.
* ENDIF. " 17.12.2009
* Add sender


   if not reply_to is INITIAL.
      replyer_to = cl_cam_address_bcs=>create_internet_address( reply_to ).
      CALL METHOD send_request->set_reply_to
        EXPORTING
          i_reply_to = replyer_to
          .
   endif.

      LOOP AT recipients INTO recipients_line.
        IF recipients_line-c_address IS INITIAL.
* Create recipient
          CLEAR iaddsmtp.
          REFRESH iaddsmtp.
          CLEAR bapiadsmtp.
          CLEAR recipient.
* Read the E-Mail address for the user
          CALL FUNCTION 'BAPI_USER_GET_DETAIL'
            EXPORTING
              username = recipients_line-uname
            TABLES
              return   = ireturn
              addsmtp  = iaddsmtp.
          LOOP AT iaddsmtp WHERE std_no = 'X'.
            CLEAR bapiadsmtp.
            MOVE iaddsmtp TO bapiadsmtp.
          ENDLOOP.
* If no E-mail address was found, create one.

            MOVE bapiadsmtp-e_mail TO recipients_line-c_address.

        ENDIF.

        recipient = cl_cam_address_bcs=>create_internet_address( recipients_line-c_address ).
* Add recipient with its respective attributes to send request
        CALL METHOD send_request->add_recipient
          EXPORTING
            i_recipient  = recipient
            i_express    = recipients_line-i_express
            i_copy       = recipients_line-i_copy
            i_blind_copy = recipients_line-i_blind_copy
            i_no_forward = recipients_line-i_no_foward.

      ENDLOOP.

* Set that you don't need a Return Status E-mail
      DATA: status_mail TYPE bcs_stml.
      status_mail = requested_status.
      CALL METHOD send_request->set_status_attributes
        EXPORTING
          i_requested_status = requested_status
          i_status_mail      = status_mail.

* set send immediately flag
*** Exclusão - Alexander - 12/08/2016
*      send_request->set_send_immediately( 'X' ).
*** Fim de Exclusão - Alexander - 12/08/2016

* Send document
      CALL METHOD send_request->send( ).

   IF DO_COMMIT_WORK = 'X'.
      COMMIT WORK.
   ENDIF.
    CATCH cx_bcs INTO bcs_exception.
*      RAISE EXCEPTION bcs_exception.

       ERRO_ENVIO = BCS_EXCEPTION->GET_LONGTEXT( ).

  ENDTRY.



ENDFUNCTION.
