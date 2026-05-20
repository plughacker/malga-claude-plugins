# Getnet SEP

Reference summary derived from `documentations/providers/getnet-sep.mdx`. Official page: <https://docs.malga.io/documentations/providers/getnet-sep>.

Legend: **✓** supported by Malga · **✗** not supported by the provider · **—** offered by the provider but not yet wired up in Malga's API (contact suporte@malga.io to request).

Parte do grupo Santander e em operação desde 2003, a Getnet oferece diversos métodos de pagamento como crédito, PIX e boleto, para processamento de vendas online, com taxas atrativas para seus clientes e suportando altos volumes de venda através da sua solução.
[Mais informações.](https://devportalgetnet.sensedia-eng.com/pt/products/online-payments/regional-api)

## Funções por métodos de pagamento suportados

| Serviços                               |                   Crédito                    |                     Pix                      |                    Boleto                    |                   Voucher                    |               Apple Pay                |
| -------------------------------------- | :------------------------------------------: | :------------------------------------------: | :------------------------------------------: | :------------------------------------------: | :------------------------------------: |
| Cobrança                               |   ✓   |   ✓   |   ✓   |    ✗    | ✗ |
| Pré-autorização                        |   ✓   |    ✗    |    ✗    |    ✗    | ✗ |
| Captura parcial                        |    ✗    |    ✗    |    ✗    |    ✗    | ✗ |
| Estorno parcial                        |    ✗    | — |    ✗    |    ✗    | ✗ |
| Estorno total                          |   ✓   | — |    ✗    |    ✗    | ✗ |
| Split                                  | — | — | — |    ✗    | ✗ |
| Antifraude próprio                     |   ✓   |    ✗    |    ✗    |    ✗    | ✗ |
| 3DS                                    | — |    ✗    |    ✗    |    ✗    | ✗ |
| Token de Bandeira                      |   ✓   |    ✗    |    ✗    |    ✗    | ✗ |
| Validação de cartão (zero dollar auth) |   ✓   |    ✗    |    ✗    |    ✗    | ✗ |
| Flag de recorrência                    | — |    ✗    |    ✗    |    ✗    | ✗ |
| Notificação de abertura de disputa     | — |    ✗    |    ✗    |    ✗    | ✗ |
| Notificação de chargedback             | — |    ✗    |    ✗    |    ✗    | ✗ |
| Suporte a moedas internacionais        | — | — | — | — | ✗ |

 

Se você possui interesse em receber cotações e avaliar este provedor para o seu fluxo de pagamentos, entre em contato com o nosso time para avaliar;
