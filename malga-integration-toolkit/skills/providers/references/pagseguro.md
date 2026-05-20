# PagSeguro

Reference summary derived from `documentations/providers/pagseguro.mdx`. Official page: <https://docs.malga.io/documentations/providers/pagseguro>.

Legend: **✓** supported by Malga · **✗** not supported by the provider · **—** offered by the provider but not yet wired up in Malga's API (contact suporte@malga.io to request).

Parte do grupo UOL e em operação desde 2006, o PagSeguro oferece soluções completas de pagamento para transações online, através de métodos como cartão de crédito e PIX, contando com ampla participação no mercado brasileiro. Destaca-se pela flexibilidade das suas soluções que atendem a negócios em diferentes estágios e segmentos.
[Mais informações.](https://developer.pagbank.com.br/docs/o-pagbank)

## Funções por métodos de pagamento suportados

| Serviços                               |                   Crédito                    |                     Pix                      |                    Boleto                    |                   Voucher                    |                Apple Pay                 |
| -------------------------------------- | :------------------------------------------: | :------------------------------------------: | :------------------------------------------: | :------------------------------------------: | :--------------------------------------: |
| Cobrança                               |   ✓   |   ✓   | — |    ✗    | ✓ |
| Pré-autorização                        |   ✓   |    ✗    |    ✗    |    ✗    | ✓ |
| Captura parcial                        |   ✓   |    ✗    |    ✗    |    ✗    | ✓ |
| Estorno parcial                        |   ✓   |   ✓   |    ✗    |    ✗    | ✓ |
| Estorno total                          |   ✓   |   ✓   |    ✗    |    ✗    | ✓ |
| Split                                  | — | — | — |    ✗    |  ✗  |
| Antifraude próprio                     |   ✓   |    ✗    |    ✗    |    ✗    |  ✗  |
| 3DS                                    | — |    ✗    |    ✗    |    ✗    |  ✗  |
| Token de Bandeira                      |   ✓   |    ✗    |    ✗    |    ✗    |  ✗  |
| Validação de cartão (zero dollar auth) |   ✓   |    ✗    |    ✗    |    ✗    |  ✗  |
| Flag de recorrência                    |   ✓   |    ✗    |    ✗    |    ✗    |  ✗  |
| Notificação de abertura de disputa     |   ✓   |    ✗    |    ✗    |    ✗    |  ✗  |
| Notificação de chargedback             |   ✓   |    ✗    |    ✗    |    ✗    |  ✗  |
| Suporte a moedas internacionais        | — | — | — | — |  ✗  |

 

Se você possui interesse em receber cotações e avaliar este provedor para o seu fluxo de pagamentos, entre em contato com o nosso time para avaliar;
