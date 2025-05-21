class ZCL_ZOV_DPC_EXT definition
  public
  inheriting from ZCL_ZOV_DPC
  create public .

public section.
protected section.

  methods MENSAGEMSET_CREATE_ENTITY
    redefinition .
  methods MENSAGEMSET_DELETE_ENTITY
    redefinition .
  methods MENSAGEMSET_GET_ENTITY
    redefinition .
  methods MENSAGEMSET_GET_ENTITYSET
    redefinition .
  methods MENSAGEMSET_UPDATE_ENTITY
    redefinition .
  methods OVCABSET_CREATE_ENTITY
    redefinition .
  methods OVCABSET_DELETE_ENTITY
    redefinition .
  methods OVCABSET_GET_ENTITY
    redefinition .
  methods OVCABSET_GET_ENTITYSET
    redefinition .
  methods OVCABSET_UPDATE_ENTITY
    redefinition .
  methods OVITEMSET_CREATE_ENTITY
    redefinition .
  methods OVITEMSET_DELETE_ENTITY
    redefinition .
  methods OVITEMSET_GET_ENTITY
    redefinition .
  methods OVITEMSET_GET_ENTITYSET
    redefinition .
  methods OVITEMSET_UPDATE_ENTITY
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZOV_DPC_EXT IMPLEMENTATION.


  method MENSAGEMSET_CREATE_ENTITY.

  endmethod.


  method MENSAGEMSET_DELETE_ENTITY.

  endmethod.


  method MENSAGEMSET_GET_ENTITY.

  endmethod.


  method MENSAGEMSET_GET_ENTITYSET.

  endmethod.


  method MENSAGEMSET_UPDATE_ENTITY.

  endmethod.


  METHOD ovcabset_create_entity.

    DATA: ld_lastid TYPE int4, "Váriavel para controlar o incrementador do ID da Ordem"
          ls_cab    TYPE zovcab. "Estrutura do tipo da tabela ZOVCAB"

    "Objeto para emitir mensagens de erro para quem tiver consumindo o serviço"
    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

    "Pegando os dados da requisição e copiando pra estrutura er_entity"
    io_data_provider->read_entry_data(
      IMPORTING
        es_data = er_entity
    ).

    "Copiando os campos da Entidade para a estrutura ls_cab"
    MOVE-CORRESPONDING er_entity TO ls_cab.

    "Preenchendo manualmente os campos que faltam"
    ls_cab-criacao_data    = sy-datum.
    ls_cab-criacao_hora    = sy-uzeit.
    ls_cab-criacao_usuario = sy-uname.

    "Pegando o último ID da tabela"
    SELECT SINGLE MAX( ordemid )
      FROM zovcab
      INTO ld_lastid.

    "Incrementando o ID para por na Ordem"
    ls_cab-ordemid = ld_lastid + 1.

    "Inserindo no Banco de Dados"
    INSERT zovcab FROM ls_cab.

    IF sy-subrc <> 0.

      lo_msg->add_message_text_only(
        EXPORTING
          iv_msg_type = 'E'
          iv_msg_text = 'Erro ao inserir ordem na tabela ZOVCAB'
      ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.

    ENDIF.

    "Atualizando os dados para quem tiver chamando"
    MOVE-CORRESPONDING ls_cab TO er_entity.

    "Convertendo Data e Hora em um único campo"
    CONVERT
      DATE ls_cab-criacao_data
      TIME ls_cab-criacao_hora
      INTO TIME STAMP er_entity-datacriacao
      TIME ZONE sy-zonlo.

  ENDMETHOD.


  method OVCABSET_DELETE_ENTITY.

  endmethod.


  method OVCABSET_GET_ENTITY.

  endmethod.


  METHOD ovcabset_get_entityset.

    DATA: lt_cab       TYPE STANDARD TABLE OF zovcab,
          ls_cab       TYPE zovcab,
          ls_entityset LIKE LINE OF et_entityset. "Vamos copiar os dados que vem do BD pro formato da EntitySet"

    "Pegando todos os Cabeçalhos do Banco de Dados"
    SELECT *
      FROM zovcab
      INTO TABLE lt_cab.

    "Passando por todos os Cabeçalhos que vieram do BD, linha a linha"
    LOOP AT lt_cab INTO ls_cab.
      CLEAR ls_entityset.

      "Movendo os dados da estrutura da Tabela ZOVCAB para a estrutura da EntitySet"
      MOVE-CORRESPONDING ls_cab TO ls_entityset.

      "Movendo manualmente os campos que o MOVE não conseguiu copiar"
      ls_entityset-criadopor = ls_cab-criacao_usuario.

      "Pegando data e hora e colocando em um único campo na EntitySet"
      CONVERT DATE ls_cab-criacao_data
              TIME ls_cab-criacao_hora
         INTO TIME STAMP ls_entityset-datacriacao
         TIME ZONE sy-zonlo.

      "Passando os dados da estrutura da EntitySet para a própria EntitySet"
      APPEND ls_entityset TO et_entityset.
    ENDLOOP.
  ENDMETHOD.


  method OVCABSET_UPDATE_ENTITY.

  endmethod.


  METHOD ovitemset_create_entity.

    DATA: ls_item TYPE zovitem."Estrutura do tipo da tabela ZOVITEM"

    "Objeto para emitir mensagens de erro para quem tiver consumindo o serviço"
    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

    "Pegando os dados da requisição e copiando pra estrutura er_entity"
    io_data_provider->read_entry_data(
      IMPORTING
        es_data = er_entity
    ).

    "Copiando os campos da Entidade para a estrutura ls_item"
    MOVE-CORRESPONDING er_entity TO ls_item.

    "Passando manualmente os campos que o MOVE não preencheu na estrutura"
    ls_item-precouni = er_entity-precounitario.
    ls_item-precotot = er_entity-precototal.

    "Caso a pessoa não passe o ID do item dessa ORDEM"
    IF er_entity-itemid = 0.
      SELECT SINGLE MAX( itemid )
        FROM zovitem
        INTO er_entity-itemid
        WHERE ordemid = er_entity-ordemid.

      er_entity-itemid = er_entity-itemid + 1.
    ENDIF.

    INSERT zovitem FROM ls_item.

    IF sy-subrc <> 0.
      lo_msg->add_message_text_only(
        EXPORTING
          iv_msg_type = 'E'
          iv_msg_text = 'Erro ao inserir item'
      ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.
  ENDMETHOD.


  method OVITEMSET_DELETE_ENTITY.

  endmethod.


  method OVITEMSET_GET_ENTITY.

  endmethod.


  METHOD ovitemset_get_entityset.
    DATA: ld_ordemid       TYPE int4,
          lt_ordemid_range TYPE RANGE OF int4,
          ls_ordemid_range LIKE LINE OF lt_ordemid_range,
          ls_key_tab       LIKE LINE OF it_key_tab.

    "Pegando a chave com ID da Ordem"
    READ TABLE it_key_tab INTO ls_key_tab WITH KEY name = 'OrdemID'.

    "Se foi passado uma chave, prepara um range"
    IF sy-subrc IS INITIAL.
      ld_ordemid = ls_key_tab-value.

      CLEAR ls_ordemid_range.
      ls_ordemid_range-sign = 'I'.
      ls_ordemid_range-option = 'EQ'.
      ls_ordemid_range-low = ld_ordemid.
      APPEND ls_ordemid_range TO lt_ordemid_range.
    ENDIF.

    "Se tiver um range faz um select com ele, caso contrário, chama tudo da tabela"
    SELECT *
      FROM zovitem
      INTO CORRESPONDING FIELDS OF TABLE et_entityset
      WHERE ordemid IN lt_ordemid_range.
  ENDMETHOD.


  method OVITEMSET_UPDATE_ENTITY.

  endmethod.
ENDCLASS.
