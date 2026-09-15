-- Current sql file was generated after introspecting the database
-- If you want to run this migration please uncomment this code before executing migrations
/*
CREATE TABLE `auditoria_log` (
	`id` bigint(20) AUTO_INCREMENT PRIMARY KEY,
	`tabela` varchar(50) NOT NULL,
	`operacao` varchar(10) NOT NULL,
	`usuario` varchar(100) NOT NULL,
	`valor_antigo` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
	`valor_novo` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
	`data_hora` timestamp NOT NULL DEFAULT current_timestamp(),
	CONSTRAINT `valor_antigo` CHECK(json_valid(`valor_antigo`)),
	CONSTRAINT `valor_novo` CHECK(json_valid(`valor_novo`))
);
--> statement-breakpoint
CREATE TABLE `episodios` (
	`id` bigint(20) AUTO_INCREMENT PRIMARY KEY,
	`serie_id` bigint(20) NOT NULL,
	`titulo` varchar(255) NOT NULL,
	`temporada` int(11) NOT NULL,
	`numero_episodio` int(11) NOT NULL,
	`duracao_minutos` int(11) NOT NULL,
	CONSTRAINT `uq_episodio_serie_temporada_numero` UNIQUE INDEX(`serie_id`,`temporada`,`numero_episodio`),
	CONSTRAINT `chk_episodios_temporada` CHECK(`temporada` > 0),
	CONSTRAINT `chk_episodios_numero` CHECK(`numero_episodio` > 0),
	CONSTRAINT `chk_episodios_duracao` CHECK(`duracao_minutos` > 0)
);
--> statement-breakpoint
CREATE TABLE `faturamento_produtoras` (
	`id` bigint(20) AUTO_INCREMENT PRIMARY KEY,
	`produtora_id` bigint(20) NOT NULL,
	`competencia` date NOT NULL,
	`minutos_consumidos` int(11) NOT NULL DEFAULT 0,
	`created_at` timestamp NOT NULL DEFAULT current_timestamp(),
	`data_ultima_alteracao` timestamp NOT NULL DEFAULT current_timestamp(),
	CONSTRAINT `uq_faturamento_produtora_competencia` UNIQUE INDEX(`produtora_id`,`competencia`),
	CONSTRAINT `chk_faturamento_minutos` CHECK(`minutos_consumidos` >= 0)
);
--> statement-breakpoint
CREATE TABLE `filmes` (
	`id` bigint(20) AUTO_INCREMENT PRIMARY KEY,
	`conteudo_id` bigint(20) NOT NULL,
	`duracao_minutos` int(11) NOT NULL,
	CONSTRAINT `conteudo_id` UNIQUE INDEX(`conteudo_id`),
	CONSTRAINT `chk_filmes_duracao` CHECK(`duracao_minutos` > 0)
);
--> statement-breakpoint
CREATE TABLE `perfis` (
	`id` bigint(20) AUTO_INCREMENT PRIMARY KEY,
	`assinante_id` bigint(20) NOT NULL,
	`nome_exibicao` varchar(100) NOT NULL,
	`created_at` timestamp NOT NULL DEFAULT current_timestamp()
);
--> statement-breakpoint
CREATE TABLE `preferencias_perfis` (
	`id` bigint(20) AUTO_INCREMENT PRIMARY KEY,
	`perfil_id` bigint(20) NOT NULL,
	`categoria_favorita` varchar(100) NOT NULL
);
--> statement-breakpoint
CREATE TABLE `produtoras` (
	`id` bigint(20) AUTO_INCREMENT PRIMARY KEY,
	`nome` varchar(200) NOT NULL,
	CONSTRAINT `nome` UNIQUE INDEX(`nome`)
);
--> statement-breakpoint
CREATE TABLE `series` (
	`id` bigint(20) AUTO_INCREMENT PRIMARY KEY,
	`conteudo_id` bigint(20) NOT NULL,
	CONSTRAINT `conteudo_id` UNIQUE INDEX(`conteudo_id`)
);
--> statement-breakpoint
CREATE TABLE `assinantes` (
	`id` bigint(20) AUTO_INCREMENT PRIMARY KEY,
	`nome` varchar(150) NOT NULL,
	`email` varchar(255) NOT NULL,
	`cpf` char(11) NOT NULL,
	`data_nascimento` date NOT NULL,
	`uf` char(2) NOT NULL,
	`saldo` decimal(12,2) NOT NULL DEFAULT 0.00,
	`created_at` timestamp NOT NULL DEFAULT current_timestamp(),
	`data_ultima_alteracao` timestamp NOT NULL DEFAULT current_timestamp(),
	CONSTRAINT `cpf` UNIQUE INDEX(`cpf`),
	CONSTRAINT `email` UNIQUE INDEX(`email`),
	CONSTRAINT `chk_saldo_positivo` CHECK(`saldo` >= 0)
);
--> statement-breakpoint
CREATE TABLE `conteudos` (
	`id` bigint(20) AUTO_INCREMENT PRIMARY KEY,
	`produtora_id` bigint(20) NOT NULL,
	`titulo` varchar(255) NOT NULL,
	`genero` varchar(100) DEFAULT 'NULL',
	`classificacao_indicativa` varchar(10) DEFAULT 'NULL',
	`tipo_conteudo` enum('FILME','SERIE') NOT NULL,
	`ativo` tinyint(1) NOT NULL DEFAULT true,
	`created_at` timestamp NOT NULL DEFAULT current_timestamp()
);
--> statement-breakpoint
CREATE TABLE `historicos_reproducao` (
	`id` bigint(20) AUTO_INCREMENT PRIMARY KEY,
	`perfil_id` bigint(20) NOT NULL,
	`tipo_midia` enum('FILME','EPISODIO') NOT NULL,
	`filme_id` bigint(20) DEFAULT NULL,
	`episodio_id` bigint(20) DEFAULT NULL,
	`tempo_visualizado_minutos` int(11) NOT NULL DEFAULT 0,
	`concluido` tinyint(1) NOT NULL DEFAULT false,
	`data_hora_atualizacao` timestamp NOT NULL DEFAULT current_timestamp(),
	CONSTRAINT `chk_historico_tempo` CHECK(`tempo_visualizado_minutos` >= 0),
	CONSTRAINT `chk_historico_tipo_midia` CHECK(`tipo_midia` = 'FILME' and `filme_id` is not null and `episodio_id` is null or `tipo_midia` = 'EPISODIO' and `episodio_id` is not null and `filme_id` is null)
);
--> statement-breakpoint
CREATE TABLE `logs_reproducao` (
	`id` bigint(20) AUTO_INCREMENT PRIMARY KEY,
	`perfil_id` bigint(20) NOT NULL,
	`tipo_midia` enum('FILME','EPISODIO') NOT NULL,
	`filme_id` bigint(20) DEFAULT NULL,
	`episodio_id` bigint(20) DEFAULT NULL,
	`ip_conexao` varchar(45) NOT NULL,
	`dispositivo` enum('SMARTTV','SMARTPHONE','WEB') NOT NULL,
	`data_hora_acesso` timestamp NOT NULL DEFAULT current_timestamp(),
	`tempo_assistido_minutos` int(11) NOT NULL DEFAULT 0,
	CONSTRAINT `chk_logs_tempo` CHECK(`tempo_assistido_minutos` >= 0),
	CONSTRAINT `chk_logs_tipo_midia` CHECK(`tipo_midia` = 'FILME' and `filme_id` is not null and `episodio_id` is null or `tipo_midia` = 'EPISODIO' and `episodio_id` is not null and `filme_id` is null)
);
--> statement-breakpoint
CREATE INDEX `idx_logs_dispositivo` ON `logs_reproducao` (`dispositivo`);--> statement-breakpoint
CREATE INDEX `idx_conteudos_produtora` ON `conteudos` (`produtora_id`);--> statement-breakpoint
CREATE INDEX `idx_logs_data_acesso` ON `logs_reproducao` (`data_hora_acesso`);--> statement-breakpoint
CREATE INDEX `idx_assinantes_uf` ON `assinantes` (`uf`);--> statement-breakpoint
CREATE INDEX `idx_logs_perfil` ON `logs_reproducao` (`perfil_id`);--> statement-breakpoint
CREATE INDEX `idx_historico_perfil_pendente` ON `historicos_reproducao` (`perfil_id`,`concluido`,`data_hora_atualizacao`);--> statement-breakpoint
ALTER TABLE `conteudos` ADD CONSTRAINT `fk_conteudos_produtoras` FOREIGN KEY (`produtora_id`) REFERENCES `produtoras`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;--> statement-breakpoint
ALTER TABLE `episodios` ADD CONSTRAINT `fk_episodios_series` FOREIGN KEY (`serie_id`) REFERENCES `series`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;--> statement-breakpoint
ALTER TABLE `faturamento_produtoras` ADD CONSTRAINT `fk_fat_produtoras` FOREIGN KEY (`produtora_id`) REFERENCES `produtoras`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;--> statement-breakpoint
ALTER TABLE `filmes` ADD CONSTRAINT `fk_filmes_conteudos` FOREIGN KEY (`conteudo_id`) REFERENCES `conteudos`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;--> statement-breakpoint
ALTER TABLE `historicos_reproducao` ADD CONSTRAINT `fk_hist_episodios` FOREIGN KEY (`episodio_id`) REFERENCES `episodios`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;--> statement-breakpoint
ALTER TABLE `historicos_reproducao` ADD CONSTRAINT `fk_hist_filmes` FOREIGN KEY (`filme_id`) REFERENCES `filmes`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;--> statement-breakpoint
ALTER TABLE `historicos_reproducao` ADD CONSTRAINT `fk_hist_perfis` FOREIGN KEY (`perfil_id`) REFERENCES `perfis`(`id`) ON DELETE CASCADE ON UPDATE RESTRICT;--> statement-breakpoint
ALTER TABLE `logs_reproducao` ADD CONSTRAINT `fk_logs_episodios` FOREIGN KEY (`episodio_id`) REFERENCES `episodios`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;--> statement-breakpoint
ALTER TABLE `logs_reproducao` ADD CONSTRAINT `fk_logs_filmes` FOREIGN KEY (`filme_id`) REFERENCES `filmes`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;--> statement-breakpoint
ALTER TABLE `logs_reproducao` ADD CONSTRAINT `fk_logs_perfis` FOREIGN KEY (`perfil_id`) REFERENCES `perfis`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;--> statement-breakpoint
ALTER TABLE `perfis` ADD CONSTRAINT `fk_perfis_assinantes` FOREIGN KEY (`assinante_id`) REFERENCES `assinantes`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;--> statement-breakpoint
ALTER TABLE `preferencias_perfis` ADD CONSTRAINT `fk_preferencias_perfis` FOREIGN KEY (`perfil_id`) REFERENCES `perfis`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;--> statement-breakpoint
ALTER TABLE `series` ADD CONSTRAINT `fk_series_conteudos` FOREIGN KEY (`conteudo_id`) REFERENCES `conteudos`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;--> statement-breakpoint
CREATE ALGORITHM = undefined SQL SECURITY definer VIEW `vw_analise_engajamento` AS (select `p`.`id` AS `perfil_id`,'CONFIDENCIAL' AS `nome`,concat(left(`a`.`email`,2),'***@',substring_index(`a`.`email`,'@',-1)) AS `email_mascarado`,'***.***.***-**' AS `cpf`,`calcular_idade`(`a`.`data_nascimento`) AS `idade`,`a`.`uf` AS `uf`,count(`l`.`id`) AS `total_reproducoes`,coalesce(sum(`l`.`tempo_assistido_minutos`),0) AS `minutos_consumidos` from ((`streamflow`.`assinantes` `a` join `streamflow`.`perfis` `p` on(`p`.`assinante_id` = `a`.`id`)) left join `streamflow`.`logs_reproducao` `l` on(`l`.`perfil_id` = `p`.`id`)) group by `p`.`id`,`a`.`data_nascimento`,`a`.`uf`,`a`.`email`);
*/