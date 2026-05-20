# Adyen

Reference summary derived from `documentations/providers/adyen.mdx`. Official page: <https://docs.malga.io/documentations/providers/adyen>.

Legend: **✓** supported by Malga · **✗** not supported by the provider · **—** offered by the provider but not yet wired up in Malga's API (contact suporte@malga.io to request).

Plataforma global de pagamentos operando no Brasil desde 2011 como provedor de pagamentos, permite que as empresas aceitem moedas internacionais e processem alto volume de vendas em qualquer parte do mundo, com uma solução integrada de 3DS e diversos métodos como Cartão de crédito, PIX e boleto.
[Mais informações.](https://docs.adyen.com/)

## Funções por métodos de pagamento suportados

| Serviços                               |                   Crédito                    |                     Pix                      |                    Boleto                    |                   Voucher                    |                  Apple Pay                   |
| -------------------------------------- | :------------------------------------------: | :------------------------------------------: | :------------------------------------------: | :------------------------------------------: | :------------------------------------------: |
| Cobrança                               |   ✓   |   ✓   |   ✓   | — | — |
| Pré-autorização                        |   ✓   |    ✗    |    ✗    |    ✗    | — |
| Captura parcial                        |   ✓   |    ✗    |    ✗    |    ✗    | — |
| Estorno parcial                        |   ✓   |   ✓   |    ✗    |    ✗    | — |
| Estorno total                          |   ✓   |   ✓   |    ✗    |    ✗    | — |
| Split                                  | — | — | — |    ✗    |    ✗    |
| Antifraude próprio                     |   ✓   |    ✗    |    ✗    |    ✗    |    ✗    |
| 3DS                                    |   ✓   |    ✗    |    ✗    |    ✗    |    ✗    |
| Token de Bandeira                      |   ✓   |    ✗    |    ✗    |    ✗    |    ✗    |
| Validação de cartão (zero dollar auth) | — |    ✗    |    ✗    |    ✗    |    ✗    |
| Flag de recorrência                    | — |    ✗    |    ✗    |    ✗    |    ✗    |
| Notificação de abertura de disputa     |   ✓   |    ✗    |    ✗    |    ✗    |    ✗    |
| Notificação de chargedback             |   ✓   |    ✗    |    ✗    |    ✗    |    ✗    |
| Suporte a moedas internacionais        |   ✓   |   ✓   |   ✓   |   ✓   |    ✗    |

 

Se você possui interesse em receber cotações e avaliar este provedor para o seu fluxo de pagamentos, entre em contato com o nosso time para avaliar;
