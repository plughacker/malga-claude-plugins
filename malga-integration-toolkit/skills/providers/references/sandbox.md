# Sandbox (Malga test provider)

Reference summary derived from `documentations/providers/sandbox.mdx`. Official page: <https://docs.malga.io/documentations/providers/sandbox>.

Legend: **✓** supported by Malga · **✗** not supported by the provider · **—** offered by the provider but not yet wired up in Malga's API (contact suporte@malga.io to request).

Provedor disponibilizado pela Malga para realização de testes de integração e validação dos fluxos de pagamento, disponível para todas as operações e métodos suportados pela Malga.
[Mais informações.](https://docs.malga.io/documentations/welcome/testing)

## Funções por métodos de pagamento suportados

| Serviços                               |                   Crédito                    |                     Pix                      |                    Boleto                    |                   Voucher                    |                  Apple Pay                   |
| -------------------------------------- | :------------------------------------------: | :------------------------------------------: | :------------------------------------------: | :------------------------------------------: | :------------------------------------------: |
| Cobrança                               |   ✓   |   ✓   |   ✓   |   ✓   | — |
| Pré-autorização                        |   ✓   |    ✗    |    ✗    |    ✗    | — |
| Captura parcial                        | — |    ✗    |    ✗    |    ✗    | — |
| Estorno parcial                        |   ✓   | — |    ✗    |    ✗    | — |
| Estorno total                          |   ✓   | — |    ✗    |    ✗    | — |
| Split                                  | — | — | — |    ✗    |    ✗    |
| Antifraude próprio                     |   ✓   |    ✗    |    ✗    |    ✗    |    ✗    |
| 3DS                                    |   ✓   |    ✗    |    ✗    |    ✗    |    ✗    |
| Token de Bandeira                      | — |    ✗    |    ✗    |    ✗    |    ✗    |
| Validação de cartão (zero dollar auth) |   ✓   |    ✗    |    ✗    |    ✗    |    ✗    |
| Flag de recorrência                    | — |    ✗    |    ✗    |    ✗    |    ✗    |
| Notificação de abertura de disputa     | — |    ✗    |    ✗    |    ✗    |    ✗    |
| Notificação de chargedback             | — |    ✗    |    ✗    |    ✗    |    ✗    |
| Suporte a moedas internacionais        | — | — | — | — |    ✗    |

 

Se você possui interesse em receber cotações e avaliar este provedor para o seu fluxo de pagamentos, entre em contato com o nosso time para avaliar;
