# Worldpay

Reference summary derived from `documentations/providers/worldpay.mdx`. Official page: <https://docs.malga.io/documentations/providers/worldpay>.

Legend: **✓** supported by Malga · **✗** not supported by the provider · **—** offered by the provider but not yet wired up in Malga's API (contact suporte@malga.io to request).

Parte do grupo FIS, a Worldpay oferece soluções de pagamento global, incluindo processamento de cartões, prevenção de fraudes e suporte a múltiplas moedas. Operando no Brasil desde 2015, destaca-se pela cobertura global e tecnologia avançada.
[Mais informações.](https://developer.worldpay.com/)

## Funções por métodos de pagamento suportados

| Serviços                               |                   Crédito                    |                     Pix                      |                    Boleto                    |                 Voucher                  |                  Apple Pay                   |
| -------------------------------------- | :------------------------------------------: | :------------------------------------------: | :------------------------------------------: | :--------------------------------------: | :------------------------------------------: |
| Cobrança                               |   ✓   | — | — |  ✗  | — |
| Pré-autorização                        |   ✓   |    ✗    |    ✗    |  ✗  | — |
| Captura parcial                        |   ✓   |    ✗    |    ✗    |  ✗  | — |
| Estorno parcial                        |   ✓   | — |    ✗    |  ✗  | — |
| Estorno total                          |   ✓   | — |    ✗    |  ✗  | — |
| Split                                  | — | — | — |  ✗  |    ✗    |
| Antifraude próprio                     | — |    ✗    |    ✗    |  ✗  |    ✗    |
| 3DS                                    | — |    ✗    |    ✗    |  ✗  |    ✗    |
| Token de Bandeira                      |   ✓   |    ✗    |    ✗    |  ✗  |    ✗    |
| Validação de cartão (zero dollar auth) |    ✗    |    ✗    |    ✗    |  ✗  |    ✗    |
| Flag de recorrência                    | — |    ✗    |    ✗    |  ✗  |    ✗    |
| Notificação de abertura de disputa     | — |    ✗    |    ✗    |  ✗  |    ✗    |
| Notificação de chargedback             | — |    ✗    |    ✗    |  ✗  |    ✗    |
| Suporte a moedas internacionais        |   ✓   |   ✓   |   ✓   | ✓ |    ✗    |

 

Se você possui interesse em receber cotações e avaliar este provedor para o seu fluxo de pagamentos, entre em contato com o nosso time para avaliar;
