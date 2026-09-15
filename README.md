# STREAMFLOW — Projeto Integrador de Banco de Dados II

A **StreamFlow** é uma plataforma fictícia de streaming de vídeo sob demanda desenvolvida como projeto integrador de **Banco de Dados II**. O projeto evolui uma modelagem relacional já existente e acrescenta regras de negócio no banco, procedures, functions, triggers, tratamento de exceções, auditoria, segurança, LGPD, consultas analíticas e uma camada de acesso via **Drizzle ORM + TypeScript**.

> **Status:** projeto concluído e validado em banco e aplicação.

---

## 1. Objetivo

O objetivo do projeto é demonstrar uma solução de banco de dados capaz de sustentar operações transacionais e analíticas de uma plataforma de streaming, preservando integridade, rastreabilidade, segurança e encapsulamento das regras de negócio.

A versão atual contempla:

- modelagem relacional completa;
- 12 tabelas e 1 view analítica;
- regras de integridade com `CHECK`, chaves estrangeiras e índices;
- Stored Functions;
- Stored Procedures;
- transações com `COMMIT` e `ROLLBACK`;
- tratamento de exceções com `HANDLER`, `SIGNAL` e `RESIGNAL`;
- cursor para faturamento mensal;
- triggers `BEFORE` e `AFTER`;
- auditoria com `OLD` e `NEW`;
- controle de privilégios por usuários específicos;
- view com mascaramento de dados para LGPD;
- mapeamento ORM com Drizzle;
- consultas em TypeScript;
- chamadas de Procedures e Functions pela aplicação.

---

## 2. Tecnologias utilizadas

| Tecnologia | Uso no projeto |
| --- | --- |
| SQL | definição do banco, regras, consultas e objetos programáveis |
| MySQL 8.0 | SGBD-alvo declarado no script SQL |
| MariaDB | ambiente utilizado na execução e validação local |
| Node.js | execução da camada ORM |
| TypeScript | implementação da camada de acesso |
| Drizzle ORM | mapeamento e consultas ORM |
| Drizzle Kit | introspecção do banco existente |
| mysql2 | driver de conexão com MySQL/MariaDB |

> O script foi estruturado para a sintaxe MySQL 8.0. Durante os testes locais, o servidor disponível foi MariaDB, compatível com os recursos utilizados no projeto. Para as consultas ORM foi usado o Query Builder do Drizzle, evitando dependências da Relational Query API que gerava SQL com `LATERAL` incompatível com o ambiente MariaDB utilizado.

---

## 3. Estrutura do repositório

```text
streamflow/
├── streamflow.sql
├── README.md
├── docs/
│   └── doc_streamflow.pdf
└── orm/
    ├── drizzle/
    │   └── ...
    ├── src/
    │   ├── db/
    │   │   ├── index.ts
    │   │   ├── relations.ts
    │   │   └── schema.ts
    │   ├── consultas.ts
    │   └── procedimentos.ts
    ├── .env.example
    ├── .gitignore
    ├── drizzle.config.ts
    ├── package.json
    ├── package-lock.json
    └── tsconfig.json
```

### Arquivos principais

- `streamflow.sql`: criação completa do banco, objetos programáveis, segurança, dados de teste e consultas de validação.
- `orm/src/db/schema.ts`: schema gerado por introspecção do banco através do Drizzle Kit.
- `orm/src/db/relations.ts`: mapeamento das relações entre as entidades.
- `orm/src/db/index.ts`: conexão da aplicação com o banco.
- `orm/src/consultas.ts`: consultas utilizando Drizzle ORM.
- `orm/src/procedimentos.ts`: chamadas das Stored Procedures e Functions.
- `docs/doc_streamflow.pdf`: documentação técnica completa do projeto.

---

## 4. Regras de negócio principais

### RN01 — Saldo do assinante

O saldo de um assinante nunca pode ser negativo.

A regra é protegida em mais de uma camada:

```sql
CHECK (saldo >= 0)
```

Também existem triggers `BEFORE INSERT` e `BEFORE UPDATE` com erro personalizado para impedir valores negativos.

### RN02 — Tipo de mídia válido

Toda reprodução deve representar exatamente um filme ou um episódio.

```sql
ENUM('FILME', 'EPISODIO')
```

Além do `ENUM`, constraints garantem a coerência entre `tipo_midia`, `filme_id` e `episodio_id`.

### RN03 — Reprodução imutável

Logs de reprodução são considerados registros de auditoria e não podem ser alterados nem excluídos após sua criação.

A regra é aplicada por triggers de bloqueio de `UPDATE` e `DELETE`.

### RN04 — Limite de perfis

Cada assinante pode possuir no máximo **5 perfis**.

A regra é aplicada por trigger `BEFORE INSERT` na tabela `perfis`.

---

## 5. Modelo de dados

As principais entidades do projeto são:

| Entidade | Responsabilidade |
| --- | --- |
| `assinantes` | titular da assinatura e saldo |
| `perfis` | perfis vinculados a um assinante |
| `preferencias_perfis` | categorias favoritas dos perfis |
| `produtoras` | empresas responsáveis pelos conteúdos |
| `conteudos` | atributos comuns do catálogo |
| `filmes` | especialização de conteúdo do tipo filme |
| `series` | especialização de conteúdo do tipo série |
| `episodios` | episódios pertencentes às séries |
| `historicos_reproducao` | progresso utilizado pelo recurso “Continuar Assistindo” |
| `logs_reproducao` | eventos imutáveis de reprodução |
| `faturamento_produtoras` | consolidação mensal de minutos por produtora |
| `auditoria_log` | histórico de alterações auditadas |

### Relacionamentos principais

```text
Assinante
   1
   │
   N
Perfil
   │
   ├── Preferencias
   ├── Historicos de Reproducao
   └── Logs de Reproducao

Produtora
   1
   │
   N
Conteudo
   │
   ├── Filme
   └── Serie
        │
        N
     Episodio
```

A especialização de conteúdos utiliza a estratégia **Class Table Inheritance**: `conteudos` concentra os atributos comuns e `filmes`/`series` armazenam os dados específicos.

---

## 6. Stored Functions

### `calcular_idade`

Calcula a idade atual a partir da data de nascimento.

```sql
SELECT calcular_idade('2004-05-20') AS idade;
```

Resultado validado durante os testes:

```text
22
```

A Function é declarada como `NOT DETERMINISTIC`, pois utiliza `CURDATE()`.

### `minutos_assistidos_por_produtora`

Soma os minutos consumidos de filmes e episódios pertencentes a uma produtora dentro de uma competência mensal.

```sql
SELECT minutos_assistidos_por_produtora(
    1,
    '2026-07-01'
) AS minutos;
```

Resultado validado:

```text
113
```

A Function utiliza `READS SQL DATA`, pois consulta os logs de reprodução e o catálogo.

---

## 7. Stored Procedures

### `realizar_cobranca_mensal`

Responsável por debitar a mensalidade de um assinante.

Principais comportamentos:

- valida o valor da mensalidade;
- valida a existência do assinante;
- utiliza `SELECT ... FOR UPDATE` para bloquear o registro durante a cobrança;
- impede cobrança quando não há saldo suficiente;
- retorna o novo saldo por parâmetro `OUT`;
- executa `ROLLBACK` em caso de erro;
- executa `COMMIT` em caso de sucesso.

Teste realizado através da aplicação:

```text
Saldo anterior: 50.00
Valor cobrado:   5.00
Novo saldo:      45.00
```

### `registrar_reproducao`

Registra uma nova reprodução de filme ou episódio.

A Procedure valida:

- perfil;
- tipo de mídia;
- mídia informada;
- dispositivo;
- consistência do registro.

Ao final, retorna o identificador criado através de `LAST_INSERT_ID()`.

Teste via aplicação:

```text
Tipo: FILME
Perfil: 1
Filme: 1
Dispositivo: WEB
Status: registro criado com sucesso
```

### `gerar_faturamento_mensal`

Percorre todas as produtoras utilizando cursor e calcula o total de minutos consumidos em uma competência.

Recursos utilizados:

- `CURSOR`;
- `OPEN`;
- `FETCH`;
- `LOOP`;
- `CLOSE`;
- `CONTINUE HANDLER FOR NOT FOUND`;
- transação;
- reutilização da Function `minutos_assistidos_por_produtora`;
- `ON DUPLICATE KEY UPDATE`.

Resultado validado para julho de 2026:

| Produtora | Minutos |
| --- | ---: |
| Netflix Studios | 113 |
| Warner Bros | 169 |
| Disney | 50 |

---

## 8. Triggers

O banco utiliza triggers para garantir regras que não devem depender exclusivamente da aplicação.

| Trigger | Evento | Finalidade |
| --- | --- | --- |
| `tg_limite_perfis` | `BEFORE INSERT` | limita cada assinante a cinco perfis |
| `tg_assinantes_saldo_insert` | `BEFORE INSERT` | impede saldo negativo na inserção |
| `tg_assinantes_saldo_update` | `BEFORE UPDATE` | impede saldo negativo na alteração |
| `tg_assinantes_normaliza_nome` | `BEFORE INSERT` | aplica `UPPER(TRIM(nome))` |
| `tg_assinantes_timestamp_update` | `BEFORE UPDATE` | atualiza a data da última alteração |
| `tg_logs_bloqueia_update` | `BEFORE UPDATE` | impede alteração de reproduções |
| `tg_logs_bloqueia_delete` | `BEFORE DELETE` | impede exclusão de reproduções |
| `tg_perfis_auditoria_update` | `AFTER UPDATE` | registra valores `OLD` e `NEW` na auditoria |

### `BEFORE` x `AFTER`

Triggers `BEFORE` são utilizadas quando a operação precisa ser validada, transformada ou bloqueada antes de atingir a tabela.

A trigger de auditoria utiliza `AFTER UPDATE` para garantir que o registro de auditoria só seja criado depois que a alteração principal foi efetivamente executada.

---

## 9. Tratamento de exceções e transações

As Procedures utilizam tratamento explícito de erros:

```sql
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
    ROLLBACK;
    RESIGNAL;
END;
```

Regras de negócio também geram exceções próprias através de:

```sql
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Mensagem da regra de negocio';
```

Esse desenho garante que uma falha não deixe a operação parcialmente executada.

---

## 10. Trigger x CHECK Constraint

A RN01 foi protegida por `CHECK` e Trigger.

O `CHECK` é ideal para uma regra declarativa simples:

```sql
saldo >= 0
```

A Trigger complementa a constraint ao permitir uma mensagem de erro específica e lógica procedural.

Assim, o banco utiliza duas camadas de proteção para uma regra crítica.

---

## 11. Segurança e privilégios

O projeto não utiliza o usuário administrador na aplicação.

Foram criados dois usuários específicos:

### `application_user`

Possui somente os privilégios necessários para a operação da aplicação, incluindo:

- leitura das tabelas necessárias;
- inserção/alteração somente onde permitido;
- inserção de logs de reprodução;
- execução das Stored Procedures;
- execução das Stored Functions;
- leitura do faturamento para apresentação dos resultados.

Não recebe privilégios administrativos como `DROP` ou `ALTER`.

### `auditoria_user`

Possui acesso de leitura aos dados necessários para auditoria:

- `logs_reproducao`;
- `auditoria_log`;
- `vw_analise_engajamento`.

Essa estratégia segue o princípio do **menor privilégio**.

---

## 12. LGPD

A view `vw_analise_engajamento` permite consultas analíticas sem exposição direta dos principais dados pessoais.

Proteções aplicadas:

- nome substituído por `CONFIDENCIAL`;
- CPF mascarado;
- e-mail parcialmente mascarado;
- uso da idade calculada em vez da exposição da data de nascimento em relatórios.

Exemplo de saída:

```text
Nome:  CONFIDENCIAL
CPF:   ***.***.***-**
Email: jo***@email.com
```

---

## 13. Índices de performance

Foram criados índices para apoiar os principais acessos da aplicação e consultas analíticas.

Entre eles:

- histórico por perfil, conclusão e data;
- logs por data de acesso;
- logs por dispositivo;
- logs por perfil;
- assinantes por UF;
- conteúdos por produtora.

O índice utilizado pelo recurso “Continuar Assistindo” é:

```sql
CREATE INDEX idx_historico_perfil_pendente
ON historicos_reproducao (
    perfil_id,
    concluido,
    data_hora_atualizacao
);
```

---

## 14. ORM — Drizzle + TypeScript

O diferencial ORM foi implementado com **Drizzle ORM** e **TypeScript**.

A estratégia adotada foi **database-first**: o banco foi criado pelo script SQL e posteriormente introspectado pelo Drizzle.

Comando utilizado:

```bash
npx drizzle-kit pull
```

A introspecção identificou:

```text
12 tabelas
67 colunas
19 indices
13 foreign keys
12 check constraints
1 view
```

O processo gerou automaticamente o schema e as relações utilizadas pela aplicação.

### Por que o ORM não recria as regras de negócio?

As regras críticas continuam dentro do banco.

A aplicação utiliza Drizzle para leitura e mapeamento, enquanto Procedures e Functions são chamadas diretamente pela camada de dados.

```text
Aplicacao TypeScript
        │
        ▼
Drizzle ORM / mysql2
        │
        ▼
Procedures e Functions
        │
        ▼
Banco de Dados
```

Dessa forma, a aplicação não duplica regras como cobrança, registro de reprodução ou faturamento.

---

## 15. Consultas ORM implementadas

O arquivo `orm/src/consultas.ts` demonstra consultas reais utilizando Drizzle.

Foram validadas consultas para:

- assinantes e seus perfis;
- conteúdos, filmes e séries;
- séries e episódios;
- históricos de reprodução.

Exemplo conceitual:

```ts
const resultado = await db
    .select({
        assinanteId: assinantes.id,
        nome: assinantes.nome,
        perfilId: perfis.id,
        nomeExibicao: perfis.nomeExibicao,
    })
    .from(assinantes)
    .leftJoin(
        perfis,
        eq(assinantes.id, perfis.assinanteId)
    );
```

---

## 16. Procedures e Functions pela aplicação

O arquivo `orm/src/procedimentos.ts` demonstra que os objetos programáveis do banco podem ser consumidos pela camada de aplicação preservando o encapsulamento.

Comandos disponíveis:

```bash
npm run procedimentos -- funcoes
npm run procedimentos -- cobranca
npm run procedimentos -- reproducao
npm run procedimentos -- faturamento
```

Resultados validados:

```text
calcular_idade                       -> 22
minutos_assistidos_por_produtora    -> 113
realizar_cobranca_mensal            -> 50.00 para 45.00
registrar_reproducao                -> registro criado
faturamento Netflix Studios         -> 113
faturamento Warner Bros             -> 169
faturamento Disney                  -> 50
```

---

## 17. Como executar o projeto

### 17.1 Clonar o repositório

```bash
git clone https://github.com/joaoxaviersilva/streamflow.git
cd streamflow
```

### 17.2 Criar o banco

Execute o arquivo:

```text
streamflow.sql
```

em um servidor MySQL/MariaDB compatível.

> **Atenção:** o script começa com `DROP DATABASE IF EXISTS streamflow`, portanto recria o banco `streamflow` do zero.

### 17.3 Instalar a camada ORM

```bash
cd orm
npm install
```

### 17.4 Configurar variáveis de ambiente

Copie o arquivo de exemplo:

```text
.env.example
```

para:

```text
.env
```

Configure as URLs de conexão de acordo com o ambiente local.

Exemplo:

```env
DATABASE_URL="mysql://root:senha@localhost:3306/streamflow"
APP_DATABASE_URL="mysql://application_user:senha@localhost:3306/streamflow"
```

Nunca envie o arquivo `.env` real para o repositório.

### 17.5 Validar o TypeScript

```bash
npm run check
```

### 17.6 Executar as consultas ORM

```bash
npm run consultas
```

### 17.7 Testar Functions

```bash
npm run procedimentos -- funcoes
```

### 17.8 Testar cobrança

```bash
npm run procedimentos -- cobranca
```

> A cobrança altera realmente o saldo no banco. Evite executar o teste repetidamente sem recriar os dados.

### 17.9 Testar registro de reprodução

```bash
npm run procedimentos -- reproducao
```

### 17.10 Testar faturamento

```bash
npm run procedimentos -- faturamento
```

---

## 18. Consultas SQL desenvolvidas

O script também contém consultas analíticas executadas diretamente no banco.

### Continuar Assistindo

Recupera conteúdos iniciados e ainda não concluídos pelo perfil.

### Consumo por produtora

Consolida minutos e horas assistidas por produtora em determinado período.

### Tráfego por região

Agrupa acessos por UF e dispositivo.

### Engajamento por faixa etária

Utiliza a Function `calcular_idade` para segmentar consumo em faixas etárias.

---

## 19. Testes realizados

O projeto possui uma seção específica de testes manuais no `streamflow.sql`.

Foram validados, entre outros:

- cálculo de idade;
- cálculo de minutos por produtora;
- cobrança com saldo suficiente;
- cobrança sem saldo suficiente;
- rollback em erro;
- registro de reprodução;
- rejeição de perfil inexistente;
- geração de faturamento;
- bloqueio de saldo negativo em `INSERT`;
- bloqueio de saldo negativo em `UPDATE`;
- bloqueio de `UPDATE` em logs;
- bloqueio de `DELETE` em logs;
- gravação de auditoria com `OLD` e `NEW`;
- atualização automática de timestamp;
- normalização de nomes;
- limite de cinco perfis.

---

## 20. Documentação técnica

A documentação completa do projeto está disponível em:

```text
docs/doc_streamflow.pdf
```

O documento detalha arquitetura, regras de negócio, Procedures, Functions, Triggers, segurança, LGPD, testes e integração ORM.

---

## 21. Considerações finais

A versão atual do StreamFlow ultrapassa a modelagem relacional básica e centraliza regras críticas diretamente no banco de dados.

O projeto combina:

- integridade referencial;
- constraints;
- Procedures;
- Functions;
- Triggers;
- cursor;
- transações;
- tratamento de exceções;
- auditoria;
- controle de privilégios;
- LGPD;
- índices de performance;
- consultas analíticas;
- Drizzle ORM;
- TypeScript;
- integração aplicação ↔ banco.

A camada ORM funciona como consumidor do banco, enquanto as regras de negócio críticas permanecem encapsuladas no SGBD, reduzindo duplicação de lógica e aumentando consistência e rastreabilidade.
