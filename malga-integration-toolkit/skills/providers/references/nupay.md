# NuPay

Reference summary derived from `documentations/providers/nupay.mdx`. Official page: <https://docs.malga.io/documentations/providers/nupay>.

Legend: **✓** supported by Malga · **✗** not supported by the provider · **—** offered by the provider but not yet wired up in Malga's API (contact suporte@malga.io to request).

A NuPay é a plataforma de pagamento desenvolvida pelo Nubank, uma das maiores fintechs da América Latina. Ela foi criada para oferecer aos clientes uma maneira fácil e segura de realizar transações financeiras online. A NuPay integra-se diretamente com o aplicativo do Nubank, permitindo aos usuários fazer compras em lojas parceiras sem a necessidade de inserir dados de cartão de crédito, utilizando apenas a autenticação pelo app.
[Mais informações.](https://docs.nupaybusiness.com.br/checkout/docs/openapi/#tag/Pagamentos/operation/PaymentsPost)

## Funções por métodos de pagamento suportados

| Serviços                               |                   Crédito                    |                     Pix                      |                    Boleto                    |                   Voucher                    |               Apple Pay                |
| -------------------------------------- | :------------------------------------------: | :------------------------------------------: | :------------------------------------------: | :------------------------------------------: | :------------------------------------: |
| Cobrança                               |   ✓   |    ✗    |    ✗    |    ✗    | ✗ |
| Pré-autorização                        |    ✗    |    ✗    |    ✗    |    ✗    | ✗ |
| Captura parcial                        |    ✗    |    ✗    |    ✗    |    ✗    | ✗ |
| Estorno parcial                        |   ✓   | — |    ✗    |    ✗    | ✗ |
| Estorno total                          |   ✓   | — |    ✗    |    ✗    | ✗ |
| Split                                  |    ✗    | — | — |    ✗    | ✗ |
| Antifraude próprio                     |   ✓   |    ✗    |    ✗    |    ✗    | ✗ |
| 3DS                                    |    ✗    |    ✗    |    ✗    |    ✗    | ✗ |
| Token de Bandeira                      |    ✗    |    ✗    |    ✗    |    ✗    | ✗ |
| Validação de cartão (zero dollar auth) |    ✗    |    ✗    |    ✗    |    ✗    | ✗ |
| Flag de recorrência                    |    ✗    |    ✗    |    ✗    |    ✗    | ✗ |
| Notificação de abertura de disputa     |    ✗    |    ✗    |    ✗    |    ✗    | ✗ |
| Notificação de chargedback             |   ✓   |    ✗    |    ✗    |    ✗    | ✗ |
| Suporte a moedas internacionais        | — | — | — | — | ✗ |

 

Se você possui interesse em receber cotações e avaliar este provedor para o seu fluxo de pagamentos, entre em contato com o nosso time para avaliar;
