# Bolt

Reference summary derived from `documentations/providers/bolt.mdx`. Official page: <https://docs.malga.io/documentations/providers/bolt>.

Legend: **✓** supported by Malga · **✗** not supported by the provider · **—** offered by the provider but not yet wired up in Malga's API (contact suporte@malga.io to request).

Bolt é uma adquirente e operadora de cartões, que credencia estabelecimentos para aceitar transações com cartões de crédito e débito, comunicando-se com bandeiras e bancos para autorizar, capturar e liquidar pagamentos ao lojista. Além disso, oferece antecipação de recebíveis, de forma pontual ou automática, possibilitando maior flexibilidade e liquidez ao negócio.
[Mais informações.](https://bolt.github.io/bolt-docs-ms-ecommerce-checkout/docs/introduction)

## Funções por métodos de pagamento suportados

| Serviços                               |                   Crédito                    |                     Pix                      |                    Boleto                    |                Voucher                 |               Apple Pay                |
| -------------------------------------- | :------------------------------------------: | :------------------------------------------: | :------------------------------------------: | :------------------------------------: | :------------------------------------: |
| Cobrança                               |   ✓   |    ✗    |    ✗    | ✗ | ✗ |
| Pré-autorização                        |   ✓   |    ✗    |    ✗    | ✗ | ✗ |
| Captura parcial                        |   ✓   |    ✗    |    ✗    | ✗ | ✗ |
| Estorno parcial                        |   ✓   | — |    ✗    | ✗ | ✗ |
| Estorno total                          |   ✓   | — |    ✗    | ✗ | ✗ |
| Split                                  |    ✗    | — | — | ✗ | ✗ |
| Antifraude próprio                     |    ✗    |    ✗    |    ✗    | ✗ | ✗ |
| 3DS                                    | — |    ✗    |    ✗    | ✗ | ✗ |
| Token de Bandeira                      |    ✗    |    ✗    |    ✗    | ✗ | ✗ |
| Validação de cartão (zero dollar auth) |   ✓   |    ✗    |    ✗    | ✗ | ✗ |
| Flag de recorrência                    | — |    ✗    |    ✗    | ✗ | ✗ |
| Notificação de abertura de disputa     |    ✗    |    ✗    |    ✗    | ✗ | ✗ |
| Notificação de chargedback             |    ✗    |    ✗    |    ✗    | ✗ | ✗ |
| Suporte a moedas internacionais        |    ✗    |    ✗    |    ✗    | ✗ | ✗ |

 

Se você possui interesse em receber cotações e avaliar este provedor para o seu fluxo de pagamentos, entre em contato com o nosso time para avaliar;
