# ABAP-ZSENDMAIL_WITH_BCS
Send Mail with BCS <br>
Função de envio de e-mail no SAP, mais fácil de usar <br>
Usar o ABAPGit (<a href="https://github.com/abapGit/abapGit">https://github.com/abapGit/abapGit</a>) para instalar esse pacote em seu sistema SAP

## Parâmetros de entrada

* `SAPUSER_SENDER (opcional)`: Nome do usuário SAP do remetente.
* `MAIL_SENDER (opcional)`: Endereço de e-mail do remetente.
* `REPLY_TO (opcional)`: Endereço de e-mail para resposta.
* `REQUESTED_STATUS (opcional)`: Define o status do e-mail solicitado (padrão: 'E').
* `DOCUMENTS`: Tabela interna contendo os dados dos documentos a serem anexados.
* `RECIPIENTS`: Tabela interna contendo os dados dos destinatários.
* `DO_COMMIT_WORK (opcional)`: Define se um COMMIT WORK deve ser executado após o envio do e-mail (padrão: 'X').

## Parâmetros de saída

* `ERRO_ENVIO`: Texto contendo o erro ocorrido durante o envio do e-mail (apenas preenchido em caso de erro).

