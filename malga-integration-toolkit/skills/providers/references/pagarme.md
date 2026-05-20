# Pagar.me (legacy)

Reference summary derived from `documentations/providers/pagarme.mdx`. Official page: <https://docs.malga.io/documentations/providers/pagarme>.

Legend: **✓** supported by Malga · **✗** not supported by the provider · **—** offered by the provider but not yet wired up in Malga's API (contact suporte@malga.io to request).

Parte do grupo StoneCo, o Pagar.me atua desde 2013, oferecendo soluções avançadas de pagamento por crédito, boleto, PIX, voucher, contando com Split e outros recursos para lojas online. Conhecida pela flexibilidade e pela gama de serviços, entrega uma experiência segura para o processamento de vendas e prevenção de fraudes.
[Mais informações.](https://docs.pagar.me/)

## Funções por métodos de pagamento suportados

| Serviços                               |                   Crédito                    |                     Pix                      |                    Boleto                    |                   Voucher                    |                Apple Pay                 |
| -------------------------------------- | :------------------------------------------: | :------------------------------------------: | :------------------------------------------: | :------------------------------------------: | :--------------------------------------: |
| Cobrança                               |   ✓   |   ✓   |   ✓   |   ✓   | ✓ |
| Pré-autorização                        |   ✓   |    ✗    |    ✗    |    ✗    | ✓ |
| Captura parcial                        |   ✓   |    ✗    |    ✗    |    ✗    | ✓ |
| Estorno parcial                        |   ✓   |   ✓   |    ✗    |    ✗    | ✓ |
| Estorno total                          |   ✓   |   ✓   |    ✗    |    ✗    | ✓ |
| Split                                  |   ✓   | — | — |    ✗    |  ✗  |
| Antifraude próprio                     |   ✓   |    ✗    |    ✗    |    ✗    |  ✗  |
| 3DS                                    | — |    ✗    |    ✗    |    ✗    |  ✗  |
| Token de Bandeira                      |    ✗    |    ✗    |    ✗    |    ✗    |  ✗  |
| Validação de cartão (zero dollar auth) |    ✗    |    ✗    |    ✗    |    ✗    |  ✗  |
| Flag de recorrência                    | — |    ✗    |    ✗    |    ✗    |  ✗  |
| Notificação de abertura de disputa     |   ✓   |    ✗    |    ✗    |    ✗    |  ✗  |
| Notificação de chargedback             |   ✓   |    ✗    |    ✗    |    ✗    |  ✗  |
| Suporte a moedas internacionais        | — | — | — | — |  ✗  |

 

Se você possui interesse em receber cotações e avaliar este provedor para o seu fluxo de pagamentos, entre em contato com o nosso time para avaliar;
