import { mysqlTable, mysqlSchema, AnyMySqlColumn, bigint, varchar, char, date, decimal, timestamp, longtext, mysqlEnum, boolean, int, uniqueIndex, index, foreignKey, check, mysqlView } from "drizzle-orm/mysql-core"
import { sql } from "drizzle-orm"

export const auditoriaLog = mysqlTable("auditoria_log", {
	id: bigint({ mode: 'number' }).autoincrement().primaryKey(),
	tabela: varchar({ length: 50 }).notNull(),
	operacao: varchar({ length: 10 }).notNull(),
	usuario: varchar({ length: 100 }).notNull(),
	valorAntigo: longtext("valor_antigo").default(sql`NULL`).charSet("utf8mb4").collate("utf8mb4_bin"),
	valorNovo: longtext("valor_novo").default(sql`NULL`).charSet("utf8mb4").collate("utf8mb4_bin"),
	dataHora: timestamp("data_hora").default(new Date("current_timestamp()Z")).notNull(),
},
(table) => [
	check("valor_antigo", sql`json_valid(\`valor_antigo\`)`),
	check("valor_novo", sql`json_valid(\`valor_novo\`)`),
]);

export const episodios = mysqlTable("episodios", {
	id: bigint({ mode: 'number' }).autoincrement().primaryKey(),
	serieId: bigint("serie_id", { mode: 'number' }).notNull().references(() => series.id, { onDelete: "restrict", onUpdate: "cascade" } ),
	titulo: varchar({ length: 255 }).notNull(),
	temporada: int().notNull(),
	numeroEpisodio: int("numero_episodio").notNull(),
	duracaoMinutos: int("duracao_minutos").notNull(),
},
(table) => [
	uniqueIndex("uq_episodio_serie_temporada_numero").on(table.serieId, table.temporada, table.numeroEpisodio),
	check("chk_episodios_temporada", sql`\`temporada\` > 0`),
	check("chk_episodios_numero", sql`\`numero_episodio\` > 0`),
	check("chk_episodios_duracao", sql`\`duracao_minutos\` > 0`),
]);

export const faturamentoProdutoras = mysqlTable("faturamento_produtoras", {
	id: bigint({ mode: 'number' }).autoincrement().primaryKey(),
	produtoraId: bigint("produtora_id", { mode: 'number' }).notNull().references(() => produtoras.id, { onDelete: "restrict", onUpdate: "cascade" } ),
	competencia: date().notNull(),
	minutosConsumidos: int("minutos_consumidos").default(0).notNull(),
	createdAt: timestamp("created_at").default(new Date("current_timestamp()Z")).notNull(),
	dataUltimaAlteracao: timestamp("data_ultima_alteracao").default(new Date("current_timestamp()Z")).notNull(),
},
(table) => [
	uniqueIndex("uq_faturamento_produtora_competencia").on(table.produtoraId, table.competencia),
	check("chk_faturamento_minutos", sql`\`minutos_consumidos\` >= 0`),
]);

export const filmes = mysqlTable("filmes", {
	id: bigint({ mode: 'number' }).autoincrement().primaryKey(),
	conteudoId: bigint("conteudo_id", { mode: 'number' }).notNull().references(() => conteudos.id, { onDelete: "restrict", onUpdate: "cascade" } ),
	duracaoMinutos: int("duracao_minutos").notNull(),
},
(table) => [
	uniqueIndex("conteudo_id").on(table.conteudoId),
	check("chk_filmes_duracao", sql`\`duracao_minutos\` > 0`),
]);

export const perfis = mysqlTable("perfis", {
	id: bigint({ mode: 'number' }).autoincrement().primaryKey(),
	assinanteId: bigint("assinante_id", { mode: 'number' }).notNull().references(() => assinantes.id, { onDelete: "cascade", onUpdate: "cascade" } ),
	nomeExibicao: varchar("nome_exibicao", { length: 100 }).notNull(),
	createdAt: timestamp("created_at").default(new Date("current_timestamp()Z")).notNull(),
});

export const preferenciasPerfis = mysqlTable("preferencias_perfis", {
	id: bigint({ mode: 'number' }).autoincrement().primaryKey(),
	perfilId: bigint("perfil_id", { mode: 'number' }).notNull().references(() => perfis.id, { onDelete: "cascade", onUpdate: "cascade" } ),
	categoriaFavorita: varchar("categoria_favorita", { length: 100 }).notNull(),
});

export const produtoras = mysqlTable("produtoras", {
	id: bigint({ mode: 'number' }).autoincrement().primaryKey(),
	nome: varchar({ length: 200 }).notNull(),
},
(table) => [
	uniqueIndex("nome").on(table.nome),
]);

export const series = mysqlTable("series", {
	id: bigint({ mode: 'number' }).autoincrement().primaryKey(),
	conteudoId: bigint("conteudo_id", { mode: 'number' }).notNull().references(() => conteudos.id, { onDelete: "restrict", onUpdate: "cascade" } ),
},
(table) => [
	uniqueIndex("conteudo_id").on(table.conteudoId),
]);

export const assinantes = mysqlTable("assinantes", {
	id: bigint({ mode: 'number' }).autoincrement().primaryKey(),
	nome: varchar({ length: 150 }).notNull(),
	email: varchar({ length: 255 }).notNull(),
	cpf: char({ length: 11 }).notNull(),
	dataNascimento: date("data_nascimento").notNull(),
	uf: char({ length: 2 }).notNull(),
	saldo: decimal({ precision: 12, scale: 2, mode: 'number' }).default(0.00).notNull(),
	createdAt: timestamp("created_at").default(new Date("current_timestamp()Z")).notNull(),
	dataUltimaAlteracao: timestamp("data_ultima_alteracao").default(new Date("current_timestamp()Z")).notNull(),
},
(table) => [
	uniqueIndex("cpf").on(table.cpf),
	index("idx_assinantes_uf").on(table.uf),
	uniqueIndex("email").on(table.email),
	check("chk_saldo_positivo", sql`\`saldo\` >= 0`),
]);

export const conteudos = mysqlTable("conteudos", {
	id: bigint({ mode: 'number' }).autoincrement().primaryKey(),
	produtoraId: bigint("produtora_id", { mode: 'number' }).notNull().references(() => produtoras.id, { onDelete: "restrict", onUpdate: "cascade" } ),
	titulo: varchar({ length: 255 }).notNull(),
	genero: varchar({ length: 100 }).default("NULL"),
	classificacaoIndicativa: varchar("classificacao_indicativa", { length: 10 }).default("NULL"),
	tipoConteudo: mysqlEnum("tipo_conteudo", ["FILME","SERIE"]).notNull(),
	ativo: boolean().default(true).notNull(),
	createdAt: timestamp("created_at").default(new Date("current_timestamp()Z")).notNull(),
},
(table) => [
	index("idx_conteudos_produtora").on(table.produtoraId),
]);

export const historicosReproducao = mysqlTable("historicos_reproducao", {
	id: bigint({ mode: 'number' }).autoincrement().primaryKey(),
	perfilId: bigint("perfil_id", { mode: 'number' }).notNull().references(() => perfis.id, { onDelete: "cascade", onUpdate: "restrict" } ),
	tipoMidia: mysqlEnum("tipo_midia", ["FILME","EPISODIO"]).notNull(),
	filmeId: bigint("filme_id", { mode: 'number' }).default(sql`NULL`).references(() => filmes.id, { onDelete: "restrict", onUpdate: "restrict" } ),
	episodioId: bigint("episodio_id", { mode: 'number' }).default(sql`NULL`).references(() => episodios.id, { onDelete: "restrict", onUpdate: "restrict" } ),
	tempoVisualizadoMinutos: int("tempo_visualizado_minutos").default(0).notNull(),
	concluido: boolean().default(false).notNull(),
	dataHoraAtualizacao: timestamp("data_hora_atualizacao").default(new Date("current_timestamp()Z")).notNull(),
},
(table) => [
	index("idx_historico_perfil_pendente").on(table.perfilId, table.concluido, table.dataHoraAtualizacao),
	check("chk_historico_tempo", sql`\`tempo_visualizado_minutos\` >= 0`),
	check("chk_historico_tipo_midia", sql`\`tipo_midia\` = 'FILME' and \`filme_id\` is not null and \`episodio_id\` is null or \`tipo_midia\` = 'EPISODIO' and \`episodio_id\` is not null and \`filme_id\` is null`),
]);

export const logsReproducao = mysqlTable("logs_reproducao", {
	id: bigint({ mode: 'number' }).autoincrement().primaryKey(),
	perfilId: bigint("perfil_id", { mode: 'number' }).notNull().references(() => perfis.id, { onDelete: "restrict", onUpdate: "restrict" } ),
	tipoMidia: mysqlEnum("tipo_midia", ["FILME","EPISODIO"]).notNull(),
	filmeId: bigint("filme_id", { mode: 'number' }).default(sql`NULL`).references(() => filmes.id, { onDelete: "restrict", onUpdate: "restrict" } ),
	episodioId: bigint("episodio_id", { mode: 'number' }).default(sql`NULL`).references(() => episodios.id, { onDelete: "restrict", onUpdate: "restrict" } ),
	ipConexao: varchar("ip_conexao", { length: 45 }).notNull(),
	dispositivo: mysqlEnum(["SMARTTV","SMARTPHONE","WEB"]).notNull(),
	dataHoraAcesso: timestamp("data_hora_acesso").default(new Date("current_timestamp()Z")).notNull(),
	tempoAssistidoMinutos: int("tempo_assistido_minutos").default(0).notNull(),
},
(table) => [
	index("idx_logs_dispositivo").on(table.dispositivo),
	index("idx_logs_data_acesso").on(table.dataHoraAcesso),
	index("idx_logs_perfil").on(table.perfilId),
	check("chk_logs_tempo", sql`\`tempo_assistido_minutos\` >= 0`),
	check("chk_logs_tipo_midia", sql`\`tipo_midia\` = 'FILME' and \`filme_id\` is not null and \`episodio_id\` is null or \`tipo_midia\` = 'EPISODIO' and \`episodio_id\` is not null and \`filme_id\` is null`),
]);
export const vwAnaliseEngajamento = mysqlView("vw_analise_engajamento", {
}).algorithm("undefined").sqlSecurity("definer").as(sql`select \`p\`.\`id\` AS \`perfil_id\`,'CONFIDENCIAL' AS \`nome\`,concat(left(\`a\`.\`email\`,2),'***@',substring_index(\`a\`.\`email\`,'@',-1)) AS \`email_mascarado\`,'***.***.***-**' AS \`cpf\`,\`calcular_idade\`(\`a\`.\`data_nascimento\`) AS \`idade\`,\`a\`.\`uf\` AS \`uf\`,count(\`l\`.\`id\`) AS \`total_reproducoes\`,coalesce(sum(\`l\`.\`tempo_assistido_minutos\`),0) AS \`minutos_consumidos\` from ((\`streamflow\`.\`assinantes\` \`a\` join \`streamflow\`.\`perfis\` \`p\` on(\`p\`.\`assinante_id\` = \`a\`.\`id\`)) left join \`streamflow\`.\`logs_reproducao\` \`l\` on(\`l\`.\`perfil_id\` = \`p\`.\`id\`)) group by \`p\`.\`id\`,\`a\`.\`data_nascimento\`,\`a\`.\`uf\`,\`a\`.\`email\``);