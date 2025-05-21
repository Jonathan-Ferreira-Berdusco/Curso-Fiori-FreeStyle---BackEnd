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


  method OVCABSET_GET_ENTITYSET.

  endmethod.


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


  method OVITEMSET_GET_ENTITYSET.

  endmethod.


  method OVITEMSET_UPDATE_ENTITY.

  endmethod.
ENDCLASS.
