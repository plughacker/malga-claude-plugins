# Braintree

Reference summary derived from `documentations/providers/braintree.mdx`. Official page: <https://docs.malga.io/documentations/providers/braintree>.

Legend: **✓** supported by Malga · **✗** not supported by the provider · **—** offered by the provider but not yet wired up in Malga's API (contact suporte@malga.io to request).

A Braintree é uma empresa do grupo PayPal, com operação desde 2014 no Brasil, e que atua globalmente oferecendo soluções para pagamento online com recursos avançados de prevenção à fraude, conhecida pela flexibilidade e robustez das suas operações.
[Mais informações.](https://developer.paypal.com/braintree/docs/start/overview)

## Funções por métodos de pagamento suportados

| Serviços                               |                   Crédito                    |                     Pix                      |                    Boleto                    |                 Voucher                  |                  Apple Pay                   |
| -------------------------------------- | :------------------------------------------: | :------------------------------------------: | :------------------------------------------: | :--------------------------------------: | :------------------------------------------: |
| Cobrança                               |   ✓   | — | — |  ✗  | — |
| Pré-autorização                        |   ✓   |    ✗    |    ✗    |  ✗  | — |
| Captura parcial                        |   ✓   |    ✗    |    ✗    |  ✗  | — |
| Estorno parcial                        |   ✓   | — |    ✗    |  ✗  | — |
| Estorno total                          |   ✓   | — |    ✗    |  ✗  | — |
| Split                                  | — | — | — |  ✗  |    ✗    |
| Antifraude próprio                     |   ✓   |    ✗    |    ✗    |  ✗  |    ✗    |
| 3DS                                    | — |    ✗    |    ✗    |  ✗  |    ✗    |
| Token de Bandeira                      |    ✗    |    ✗    |    ✗    |  ✗  |    ✗    |
| Validação de cartão (zero dollar auth) |    ✗    |    ✗    |    ✗    |  ✗  |    ✗    |
| Flag de recorrência                    | — |    ✗    |    ✗    |  ✗  |    ✗    |
| Notificação de abertura de disputa     | — |    ✗    |    ✗    |  ✗  |    ✗    |
| Notificação de chargedback             |   ✓   |    ✗    |    ✗    |  ✗  |    ✗    |
| Suporte a moedas internacionais        |   ✓   |   ✓   |   ✓   | ✓ |    ✗    |

 

Se você possui interesse em receber cotações e avaliar este provedor para o seu fluxo de pagamentos, entre em contato com o nosso time para avaliar;
