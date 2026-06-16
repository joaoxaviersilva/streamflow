# PROJETO INTEGRADOR DE BANCO DE DADOS – STREAMFLOW

## 1. Introdução

A StreamFlow é uma plataforma de streaming de vídeo sob demanda que necessita de uma infraestrutura de banco de dados relacional capaz de suportar múltiplos perfis por assinante, armazenamento seguro de históricos de reprodução, auditoria de acessos, relatórios analíticos e conformidade com a Lei Geral de Proteção de Dados (LGPD).

O objetivo deste projeto é desenvolver uma solução completa de banco de dados utilizando MySQL 8.0, contemplando modelagem conceitual, lógica e física, mecanismos de segurança, otimização de desempenho e consultas analíticas para suporte à tomada de decisão da diretoria.

---

# 2. Levantamento dos Requisitos

## 2.1 Regras de Negócio

### RN01 – Controle Preventivo de Endividamento

O saldo do assinante não pode assumir valores negativos.

**Solução aplicada:**

```sql
CHECK (saldo >= 0)
```

---

### RN02 – Classificação Rígida de Fluxo

Toda reprodução deve estar associada a um tipo de mídia válido.

**Solução aplicada:**

```sql
ENUM('FILME','EPISODIO')
```

---

### RN03 – Histórico Inalterável

Nenhum log de reprodução pode ser alterado ou removido.

**Solução aplicada:**

* Triggers de bloqueio de UPDATE
* Triggers de bloqueio de DELETE
* Permissões restritas via RBAC

---

## 2.2 Requisitos Funcionais

### RF01 – Gestão Multiperfil

Cada assinante pode possuir até cinco perfis.

### RF02 – Registro de Logs

O sistema deve registrar:

* IP de acesso
* Tipo de dispositivo
* Data e hora do acesso

### RF03 – Continuar Assistindo

Recuperar conteúdos iniciados e não concluídos.

### RF04 – Relatório de Produtoras

Consolidar tempo assistido por produtora.

### RF05 – Auditoria Regional

Consolidar acessos por UF e dispositivo.

---

## 2.3 Requisitos Não Funcionais

### RNF01 – Padronização

* Tabelas no plural
* Chave primária denominada "id"

### RNF02 – Precisão Numérica

Valores monetários armazenados com:

```sql
DECIMAL(12,2)
```

### RNF03 – Segurança

Implementação de RBAC utilizando:

```sql
CREATE USER
GRANT
REVOKE
```

### RNF04 – LGPD

Proteção de CPF, nome e e-mail.

### RNF05 – Performance

Uso de índices para evitar Full Table Scan.

---

# 3. Modelagem Conceitual

O sistema foi estruturado a partir das seguintes entidades:

## Assinantes

Representa o cliente principal responsável pela assinatura.

Atributos:

* id
* nome
* email
* cpf
* data_nascimento
* uf
* saldo

---

## Perfis

Representa os usuários individuais vinculados ao assinante.

Atributos:

* id
* assinante_id
* nome_exibicao

---

## Preferências dos Perfis

Armazena gostos e categorias favoritas.

Atributos:

* id
* perfil_id
* categoria_favorita

---

## Produtoras

Empresas responsáveis pelos conteúdos.

Atributos:

* id
* nome

---

## Conteúdos

Tabela base do catálogo.

Atributos:

* id
* produtora_id
* titulo
* genero
* classificacao_indicativa
* tipo_conteudo
* ativo

---

## Filmes

Especialização da entidade Conteúdos.

Atributos:

* id
* conteudo_id
* duracao_minutos

---

## Séries

Especialização da entidade Conteúdos.

Atributos:

* id
* conteudo_id

---

## Episódios

Representam os episódios pertencentes a uma série.

Atributos:

* id
* serie_id
* titulo
* temporada
* numero_episodio
* duracao_minutos

---

## Históricos de Reprodução

Controla o progresso do usuário.

Atributos:

* id
* perfil_id
* tipo_midia
* filme_id
* episodio_id
* tempo_visualizado_minutos
* concluido
* data_hora_atualizacao

---

## Logs de Reprodução

Registra eventos de auditoria.

Atributos:

* id
* perfil_id
* tipo_midia
* filme_id
* episodio_id
* ip_conexao
* dispositivo
* data_hora_acesso
* tempo_assistido_minutos

---

# 4. Modelagem Lógica

## Relacionamentos

### Assinantes → Perfis

Relacionamento:

```text
1:N
```

Um assinante pode possuir até cinco perfis.

---

### Perfis → Preferências

Relacionamento:

```text
1:N
```

---

### Produtoras → Conteúdos

Relacionamento:

```text
1:N
```

---

### Conteúdos → Filmes

Relacionamento:

```text
1:1
```

---

### Conteúdos → Séries

Relacionamento:

```text
1:1
```

---

### Séries → Episódios

Relacionamento:

```text
1:N
```

---

### Perfis → Históricos

Relacionamento:

```text
1:N
```

---

### Perfis → Logs

Relacionamento:

```text
1:N
```

---

# 5. Estratégia de Herança

Para resolver a especialização de conteúdos foi utilizada a técnica conhecida como:

## Class Table Inheritance

A tabela:

```text
conteudos
```

armazena os atributos comuns.

As tabelas:

```text
filmes
series
```

armazenam atributos específicos.

Benefícios:

* Eliminação de redundância
* Normalização
* Melhor manutenção
* Maior integridade dos dados

---

# 6. Integridade Referencial

Foi adotado:

```sql
ON DELETE RESTRICT
```

nas tabelas críticas.

Objetivo:

Impedir que a exclusão de um conteúdo destrua:

* históricos
* logs
* auditorias
* relatórios financeiros

Assim, caso um conteúdo possua reproduções registradas, sua remoção física é bloqueada pelo banco de dados.

---

# 7. Implementação da Regra dos 5 Perfis

Foi criada a trigger:

```sql
tg_limite_perfis
```

Responsável por:

1. Contar perfis existentes.
2. Verificar o assinante.
3. Bloquear inserções acima de cinco perfis.

Benefícios:

* Garantia da regra de negócio diretamente no banco.
* Independência da aplicação.

---

# 8. Implementação dos Logs Imutáveis

Foram criadas as triggers:

```sql
tg_logs_bloqueia_update
```

e

```sql
tg_logs_bloqueia_delete
```

Objetivo:

Impedir qualquer alteração posterior nos registros.

Benefícios:

* Auditoria confiável
* Conformidade legal
* Prevenção contra fraudes

---

# 9. Controle de Acesso (RBAC)

## Usuário da Aplicação

```text
application_user
```

Permissões:

* SELECT
* INSERT
* UPDATE

Sem permissão para:

* DELETE
* DROP
* ALTER

---

## Usuário de Auditoria

```text
auditoria_user
```

Permissões:

* SELECT nos logs
* SELECT na View LGPD

Sem acesso aos dados pessoais dos assinantes.

---

# 10. Conformidade com a LGPD

Foi criada a View:

```sql
vw_analise_engajamento
```

Dados protegidos:

* Nome
* CPF
* E-mail

Dados disponibilizados:

* Idade
* UF
* Total de reproduções
* Minutos consumidos

Exemplo:

```text
Nome: CONFIDENCIAL
CPF: ***.***.***-**
Email: jo***@email.com
```

---

# 11. Estratégia de Performance

O principal gargalo identificado foi a consulta:

```text
Continuar Assistindo
```

Sem índice:

```text
Full Table Scan
```

Com índice:

```sql
CREATE INDEX idx_historico_perfil_pendente
ON historicos_reproducao (
perfil_id,
concluido,
data_hora_atualizacao
);
```

Benefícios:

* Menor uso de CPU
* Menor uso de disco
* Resposta em milissegundos

---

# 12. Consultas Desenvolvidas

## Consulta 1 – Continuar Assistindo

Objetivo:

Listar conteúdos iniciados e não concluídos.

Características:

* Filtragem por perfil
* Ordenação por data
* Recuperação do progresso

---

## Consulta 2 – Relatório de Produtoras

Objetivo:

Somar minutos assistidos por produtora.

Recursos utilizados:

* JOIN
* SUM
* GROUP BY
* HAVING

---

## Consulta 3 – Auditoria Regional

Objetivo:

Mapear acessos por:

* Estado
* Dispositivo

Permite planejamento de infraestrutura.

---

## Consulta 4 – BI de Engajamento

Objetivo:

Analisar comportamento por faixa etária.

Faixas:

* Menor de 18
* 18 a 29
* 30 a 49
* 50+

Indicadores:

* Perfis ativos
* Média de consumo
* Total de reproduções

---

# 13. Conclusão

O projeto StreamFlow foi desenvolvido seguindo princípios modernos de Engenharia de Dados, Modelagem Relacional e Governança de Informação.

A solução atende integralmente aos requisitos propostos pelo desafio, oferecendo:

* Integridade referencial;
* Controle de acesso baseado em papéis;
* Histórico imutável;
* Conformidade com a LGPD;
* Estrutura preparada para auditoria;
* Consultas analíticas para Business Intelligence;
* Estratégias de otimização para bases massivas.

O banco de dados resultante é capaz de suportar operações transacionais e analíticas simultaneamente, garantindo confiabilidade, segurança, rastreabilidade e escalabilidade para o crescimento futuro da plataforma StreamFlow.
