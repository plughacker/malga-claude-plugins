# Mercado Pago

Reference summary derived from `documentations/providers/mercado-pago.mdx`. Official page: <https://docs.malga.io/documentations/providers/mercado-pago>.

Legend: **✓** supported by Malga · **✗** not supported by the provider · **—** offered by the provider but not yet wired up in Malga's API (contact suporte@malga.io to request).

Parte do grupo Mercado Livre e em operação desde 2004, a Mercado Pago atua como adquirente e plataforma de pagamentos para múltiplos métodos e moedas em transações online e offline, possuindo ampla participação de mercado no Brasil e América Latina. Oferece taxas atrativas e condições facilitadas para as lojas.
[Mais informações.](https://www.mercadopago.com.br/developers/pt)

## Funções por métodos de pagamento suportados

| Serviços                               |                   Crédito                    |                     Pix                      |                    Boleto                    |                 Voucher                  |               Apple Pay                |
| -------------------------------------- | :------------------------------------------: | :------------------------------------------: | :------------------------------------------: | :--------------------------------------: | :------------------------------------: |
| Cobrança                               |   ✓   |   ✓   |   ✓   |  ✗  | ✗ |
| Pré-autorização                        |   ✓   |    ✗    |    ✗    |  ✗  | ✗ |
| Captura parcial                        |   ✓   |    ✗    |    ✗    |  ✗  | ✗ |
| Estorno parcial                        |   ✓   |   ✓   |    ✗    |  ✗  | ✗ |
| Estorno total                          |   ✓   |   ✓   |    ✗    |  ✗  | ✗ |
| Split                                  | — | — | — |  ✗  | ✗ |
| Antifraude próprio                     |   ✓   |    ✗    |    ✗    |  ✗  | ✗ |
| 3DS                                    | — |    ✗    |    ✗    |  ✗  | ✗ |
| Token de Bandeira                      |   ✓   |    ✗    |    ✗    |  ✗  | ✗ |
| Validação de cartão (zero dollar auth) |    ✗    |    ✗    |    ✗    |  ✗  | ✗ |
| Flag de recorrência                    | — |    ✗    |    ✗    |  ✗  | ✗ |
| Notificação de abertura de disputa     | — |    ✗    |    ✗    |  ✗  | ✗ |
| Notificação de chargedback             |   ✓   |    ✗    |    ✗    |  ✗  | ✗ |
| Suporte a moedas internacionais        |   ✓   |   ✓   |   ✓   | ✓ | ✗ |

 

Se você possui interesse em receber cotações e avaliar este provedor para o seu fluxo de pagamentos, entre em contato com o nosso time para avaliar;
