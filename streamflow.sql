-- =====================================================
-- STREAMFLOW
-- PROJETO INTEGRADOR DE BANCO DE DADOS II
-- SGBD: MySQL 8.0
-- =====================================================

DROP DATABASE IF EXISTS streamflow;
CREATE DATABASE streamflow CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE streamflow;

-- =====================================================
-- 01 - TABELAS
-- =====================================================

-- Tabela de assinantes

CREATE TABLE assinantes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    cpf CHAR(11) NOT NULL UNIQUE,
    data_nascimento DATE NOT NULL,
    uf CHAR(2) NOT NULL,
    saldo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_ultima_alteracao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_saldo_positivo CHECK (saldo >= 0)
);

-- Tabela de perfis

CREATE TABLE perfis (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    assinante_id BIGINT NOT NULL,
    nome_exibicao VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_perfis_assinantes FOREIGN KEY (assinante_id)
        REFERENCES assinantes(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Tabela de preferencias dos perfis

CREATE TABLE preferencias_perfis (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    perfil_id BIGINT NOT NULL,
    categoria_favorita VARCHAR(100) NOT NULL,
    CONSTRAINT fk_preferencias_perfis FOREIGN KEY (perfil_id)
        REFERENCES perfis(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Tabela de produtoras

CREATE TABLE produtoras (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(200) NOT NULL UNIQUE
);

-- Tabela de conteudos

CREATE TABLE conteudos (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    produtora_id BIGINT NOT NULL,
    titulo VARCHAR(255) NOT NULL,
    genero VARCHAR(100),
    classificacao_indicativa VARCHAR(10),
    tipo_conteudo ENUM('FILME', 'SERIE') NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_conteudos_produtoras FOREIGN KEY (produtora_id)
        REFERENCES produtoras(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Tabela de filmes

CREATE TABLE filmes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    conteudo_id BIGINT NOT NULL UNIQUE,
    duracao_minutos INT NOT NULL,
    CONSTRAINT chk_filmes_duracao CHECK (duracao_minutos > 0),
    CONSTRAINT fk_filmes_conteudos FOREIGN KEY (conteudo_id)
        REFERENCES conteudos(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Tabela de series

CREATE TABLE series (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    conteudo_id BIGINT NOT NULL UNIQUE,
    CONSTRAINT fk_series_conteudos FOREIGN KEY (conteudo_id)
        REFERENCES conteudos(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Tabela de episodios

CREATE TABLE episodios (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    serie_id BIGINT NOT NULL,
    titulo VARCHAR(255) NOT NULL,
    temporada INT NOT NULL,
    numero_episodio INT NOT NULL,
    duracao_minutos INT NOT NULL,
    CONSTRAINT chk_episodios_temporada CHECK (temporada > 0),
    CONSTRAINT chk_episodios_numero CHECK (numero_episodio > 0),
    CONSTRAINT chk_episodios_duracao CHECK (duracao_minutos > 0),
    CONSTRAINT uq_episodio_serie_temporada_numero UNIQUE (serie_id, temporada, numero_episodio),
    CONSTRAINT fk_episodios_series FOREIGN KEY (serie_id)
        REFERENCES series(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Tabela de historico de reproducao

CREATE TABLE historicos_reproducao (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    perfil_id BIGINT NOT NULL,
    tipo_midia ENUM('FILME', 'EPISODIO') NOT NULL,
    filme_id BIGINT NULL,
    episodio_id BIGINT NULL,
    tempo_visualizado_minutos INT NOT NULL DEFAULT 0,
    concluido BOOLEAN NOT NULL DEFAULT FALSE,
    data_hora_atualizacao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT chk_historico_tempo CHECK (tempo_visualizado_minutos >= 0),

    CONSTRAINT chk_historico_tipo_midia CHECK (
        (tipo_midia = 'FILME' AND filme_id IS NOT NULL AND episodio_id IS NULL)
        OR
        (tipo_midia = 'EPISODIO' AND episodio_id IS NOT NULL AND filme_id IS NULL)
    ),

    CONSTRAINT fk_hist_perfis FOREIGN KEY (perfil_id)
        REFERENCES perfis(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_hist_filmes FOREIGN KEY (filme_id)
        REFERENCES filmes(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_hist_episodios FOREIGN KEY (episodio_id)
        REFERENCES episodios(id)
        ON DELETE RESTRICT
);

-- Tabela de logs de reproducao

CREATE TABLE logs_reproducao (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    perfil_id BIGINT NOT NULL,
    tipo_midia ENUM('FILME', 'EPISODIO') NOT NULL,
    filme_id BIGINT NULL,
    episodio_id BIGINT NULL,
    ip_conexao VARCHAR(45) NOT NULL,
    dispositivo ENUM('SMARTTV', 'SMARTPHONE', 'WEB') NOT NULL,
    data_hora_acesso TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tempo_assistido_minutos INT NOT NULL DEFAULT 0,

    CONSTRAINT chk_logs_tempo CHECK (tempo_assistido_minutos >= 0),

    CONSTRAINT chk_logs_tipo_midia CHECK (
        (tipo_midia = 'FILME' AND filme_id IS NOT NULL AND episodio_id IS NULL)
        OR
        (tipo_midia = 'EPISODIO' AND episodio_id IS NOT NULL AND filme_id IS NULL)
    ),

    CONSTRAINT fk_logs_perfis FOREIGN KEY (perfil_id)
        REFERENCES perfis(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_logs_filmes FOREIGN KEY (filme_id)
        REFERENCES filmes(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_logs_episodios FOREIGN KEY (episodio_id)
        REFERENCES episodios(id)
        ON DELETE RESTRICT
);

-- Tabela de faturamento das produtoras

CREATE TABLE faturamento_produtoras (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    produtora_id BIGINT NOT NULL,
    competencia DATE NOT NULL,
    minutos_consumidos INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_ultima_alteracao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT uq_faturamento_produtora_competencia
        UNIQUE (produtora_id, competencia),

    CONSTRAINT chk_faturamento_minutos
        CHECK (minutos_consumidos >= 0),

    CONSTRAINT fk_fat_produtoras FOREIGN KEY (produtora_id)
        REFERENCES produtoras(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Tabela de auditoria

CREATE TABLE auditoria_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tabela VARCHAR(50) NOT NULL,
    operacao VARCHAR(10) NOT NULL,
    usuario VARCHAR(100) NOT NULL,
    valor_antigo JSON,
    valor_novo JSON,
    data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 02 - STORED FUNCTIONS
-- =====================================================

DELIMITER $$

-- Function de calcular idade

CREATE FUNCTION calcular_idade(
    p_data_nascimento DATE
)
RETURNS INT
NOT DETERMINISTIC
NO SQL
BEGIN
    DECLARE v_idade INT;

    IF p_data_nascimento IS NULL THEN
        RETURN NULL;
    END IF;

    SET v_idade = TIMESTAMPDIFF(
        YEAR,
        p_data_nascimento,
        CURDATE()
    );

    RETURN v_idade;
END$$

-- Function de calcular minutos assistidos por produtora

CREATE FUNCTION minutos_assistidos_por_produtora(
    p_produtora_id BIGINT,
    p_competencia DATE
)
RETURNS BIGINT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_inicio DATE;
    DECLARE v_fim DATE;
    DECLARE v_minutos_filmes BIGINT DEFAULT 0;
    DECLARE v_minutos_episodios BIGINT DEFAULT 0;

    SET v_inicio = STR_TO_DATE(
        DATE_FORMAT(p_competencia, '%Y-%m-01'),
        '%Y-%m-%d'
    );

    SET v_fim = DATE_ADD(
        v_inicio,
        INTERVAL 1 MONTH
    );

    SELECT COALESCE(SUM(l.tempo_assistido_minutos), 0)
    INTO v_minutos_filmes
    FROM logs_reproducao l
    INNER JOIN filmes f
        ON f.id = l.filme_id
    INNER JOIN conteudos c
        ON c.id = f.conteudo_id
    WHERE c.produtora_id = p_produtora_id
      AND l.tipo_midia = 'FILME'
      AND l.data_hora_acesso >= v_inicio
      AND l.data_hora_acesso < v_fim;

    SELECT COALESCE(SUM(l.tempo_assistido_minutos), 0)
    INTO v_minutos_episodios
    FROM logs_reproducao l
    INNER JOIN episodios e
        ON e.id = l.episodio_id
    INNER JOIN series s
        ON s.id = e.serie_id
    INNER JOIN conteudos c
        ON c.id = s.conteudo_id
    WHERE c.produtora_id = p_produtora_id
      AND l.tipo_midia = 'EPISODIO'
      AND l.data_hora_acesso >= v_inicio
      AND l.data_hora_acesso < v_fim;

    RETURN v_minutos_filmes + v_minutos_episodios;
END$$

DELIMITER ;

-- =====================================================
-- 03 - STORED PROCEDURES
-- =====================================================

DELIMITER $$

-- Procedure de realizar cobranca mensal

CREATE PROCEDURE realizar_cobranca_mensal(
    IN p_id_assinante BIGINT,
    IN p_valor_mensalidade DECIMAL(12,2),
    OUT p_novo_saldo DECIMAL(12,2)
)
BEGIN
    DECLARE v_saldo_atual DECIMAL(12,2);
    DECLARE v_existe INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF p_valor_mensalidade IS NULL OR p_valor_mensalidade <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'O valor da mensalidade deve ser maior que zero.';
    END IF;

    SELECT COUNT(*)
    INTO v_existe
    FROM assinantes
    WHERE id = p_id_assinante;

    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Assinante nao encontrado.';
    END IF;

    SELECT saldo
    INTO v_saldo_atual
    FROM assinantes
    WHERE id = p_id_assinante
    FOR UPDATE;

    IF v_saldo_atual < p_valor_mensalidade THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Saldo insuficiente para realizar a cobranca.';
    END IF;

    UPDATE assinantes
    SET saldo = saldo - p_valor_mensalidade
    WHERE id = p_id_assinante;

    SELECT saldo
    INTO p_novo_saldo
    FROM assinantes
    WHERE id = p_id_assinante;

    COMMIT;
END$$

-- Procedure de registrar reproducao

CREATE PROCEDURE registrar_reproducao(
    IN p_perfil_id BIGINT,
    IN p_tipo_midia VARCHAR(10),
    IN p_midia_id BIGINT,
    IN p_ip_conexao VARCHAR(45),
    IN p_dispositivo VARCHAR(20),
    IN p_tempo_assistido_minutos INT,
    OUT p_reproducao_id BIGINT
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT COUNT(*)
    INTO v_existe
    FROM perfis
    WHERE id = p_perfil_id;

    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Perfil nao encontrado.';
    END IF;

    IF UPPER(p_tipo_midia) NOT IN ('FILME', 'EPISODIO') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tipo de midia invalido. Use FILME ou EPISODIO.';
    END IF;

    IF UPPER(p_dispositivo) NOT IN ('SMARTTV', 'SMARTPHONE', 'WEB') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Dispositivo invalido.';
    END IF;

    IF p_tempo_assistido_minutos IS NULL
       OR p_tempo_assistido_minutos < 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tempo assistido invalido.';
    END IF;

    IF UPPER(p_tipo_midia) = 'FILME' THEN

        SELECT COUNT(*)
        INTO v_existe
        FROM filmes
        WHERE id = p_midia_id;

        IF v_existe = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Filme nao encontrado.';
        END IF;

        INSERT INTO logs_reproducao (
            perfil_id,
            tipo_midia,
            filme_id,
            episodio_id,
            ip_conexao,
            dispositivo,
            tempo_assistido_minutos
        )
        VALUES (
            p_perfil_id,
            'FILME',
            p_midia_id,
            NULL,
            p_ip_conexao,
            UPPER(p_dispositivo),
            p_tempo_assistido_minutos
        );

    ELSE

        SELECT COUNT(*)
        INTO v_existe
        FROM episodios
        WHERE id = p_midia_id;

        IF v_existe = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Episodio nao encontrado.';
        END IF;

        INSERT INTO logs_reproducao (
            perfil_id,
            tipo_midia,
            filme_id,
            episodio_id,
            ip_conexao,
            dispositivo,
            tempo_assistido_minutos
        )
        VALUES (
            p_perfil_id,
            'EPISODIO',
            NULL,
            p_midia_id,
            p_ip_conexao,
            UPPER(p_dispositivo),
            p_tempo_assistido_minutos
        );
    END IF;

    SET p_reproducao_id = LAST_INSERT_ID();

    COMMIT;
END$$

-- Procedure de gerar faturamento mensal

CREATE PROCEDURE gerar_faturamento_mensal(
    IN p_competencia DATE
)
BEGIN
    DECLARE v_fim INT DEFAULT 0;
    DECLARE v_produtora_id BIGINT;
    DECLARE v_minutos BIGINT DEFAULT 0;
    DECLARE v_competencia_normalizada DATE;

    DECLARE cur_produtoras CURSOR FOR
        SELECT id
        FROM produtoras
        ORDER BY id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET v_fim = 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET v_competencia_normalizada =
        STR_TO_DATE(
            DATE_FORMAT(p_competencia, '%Y-%m-01'),
            '%Y-%m-%d'
        );

    START TRANSACTION;

    OPEN cur_produtoras;

    leitura_produtoras: LOOP

        FETCH cur_produtoras
        INTO v_produtora_id;

        IF v_fim = 1 THEN
            LEAVE leitura_produtoras;
        END IF;

        SET v_minutos =
            minutos_assistidos_por_produtora(
                v_produtora_id,
                v_competencia_normalizada
            );

        INSERT INTO faturamento_produtoras (
            produtora_id,
            competencia,
            minutos_consumidos
        )
        VALUES (
            v_produtora_id,
            v_competencia_normalizada,
            v_minutos
        )
        ON DUPLICATE KEY UPDATE
            minutos_consumidos = VALUES(minutos_consumidos),
            data_ultima_alteracao = CURRENT_TIMESTAMP;

    END LOOP;

    CLOSE cur_produtoras;

    COMMIT;
END$$

DELIMITER ;

-- =====================================================
-- 04 - TRIGGERS
-- =====================================================

DELIMITER $$

-- Trigger de limitar perfis

CREATE TRIGGER tg_limite_perfis
BEFORE INSERT ON perfis
FOR EACH ROW
BEGIN
    DECLARE v_quantidade INT;

    SELECT COUNT(*)
    INTO v_quantidade
    FROM perfis
    WHERE assinante_id = NEW.assinante_id;

    IF v_quantidade >= 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Um assinante pode possuir no maximo 5 perfis.';
    END IF;
END$$

-- Trigger de verificar saldo no INSERT

CREATE TRIGGER tg_assinantes_saldo_insert
BEFORE INSERT ON assinantes
FOR EACH ROW
BEGIN
    IF NEW.saldo < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN01 violada: o saldo do assinante nao pode ser negativo.';
    END IF;
END$$

-- Trigger de verificar saldo no UPDATE

CREATE TRIGGER tg_assinantes_saldo_update
BEFORE UPDATE ON assinantes
FOR EACH ROW
BEGIN
    IF NEW.saldo < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN01 violada: o saldo do assinante nao pode ser negativo.';
    END IF;
END$$

-- Trigger de normalizar nome

CREATE TRIGGER tg_assinantes_normaliza_nome
BEFORE INSERT ON assinantes
FOR EACH ROW
BEGIN
    SET NEW.nome = UPPER(TRIM(NEW.nome));
END$$

-- Trigger de atualizar data da ultima alteracao

CREATE TRIGGER tg_assinantes_timestamp_update
BEFORE UPDATE ON assinantes
FOR EACH ROW
BEGIN
    SET NEW.data_ultima_alteracao = CURRENT_TIMESTAMP;
END$$

-- Trigger de bloquear UPDATE nos logs

CREATE TRIGGER tg_logs_bloqueia_update
BEFORE UPDATE ON logs_reproducao
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'RN03: reproducoes sao imutaveis. UPDATE proibido.';
END$$

-- Trigger de bloquear DELETE nos logs

CREATE TRIGGER tg_logs_bloqueia_delete
BEFORE DELETE ON logs_reproducao
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'RN03: reproducoes sao imutaveis. DELETE proibido.';
END$$

-- Trigger de auditoria dos perfis

CREATE TRIGGER tg_perfis_auditoria_update
AFTER UPDATE ON perfis
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (
        tabela,
        operacao,
        usuario,
        valor_antigo,
        valor_novo
    )
    VALUES (
        'perfis',
        'UPDATE',
        CURRENT_USER(),

        JSON_OBJECT(
            'id', OLD.id,
            'assinante_id', OLD.assinante_id,
            'nome_exibicao', OLD.nome_exibicao
        ),

        JSON_OBJECT(
            'id', NEW.id,
            'assinante_id', NEW.assinante_id,
            'nome_exibicao', NEW.nome_exibicao
        )
    );
END$$

DELIMITER ;

-- =====================================================
-- 05 - INDICES DE PERFORMANCE
-- =====================================================

-- Indice de continuar assistindo

CREATE INDEX idx_historico_perfil_pendente
ON historicos_reproducao (
    perfil_id,
    concluido,
    data_hora_atualizacao
);

-- Indice pela data de acesso

CREATE INDEX idx_logs_data_acesso
ON logs_reproducao (
    data_hora_acesso
);

-- Indice por dispositivo

CREATE INDEX idx_logs_dispositivo
ON logs_reproducao (
    dispositivo
);

-- Indice por perfil

CREATE INDEX idx_logs_perfil
ON logs_reproducao (
    perfil_id
);

-- Indice por UF

CREATE INDEX idx_assinantes_uf
ON assinantes (
    uf
);

-- Indice por produtora

CREATE INDEX idx_conteudos_produtora
ON conteudos (
    produtora_id
);

-- =====================================================
-- 06 - VIEW LGPD
-- =====================================================

-- View de analise de engajamento

CREATE VIEW vw_analise_engajamento AS
SELECT
    p.id AS perfil_id,
    'CONFIDENCIAL' AS nome,

    CONCAT(
        LEFT(a.email, 2),
        '***@',
        SUBSTRING_INDEX(a.email, '@', -1)
    ) AS email_mascarado,

    '***.***.***-**' AS cpf,

    calcular_idade(a.data_nascimento) AS idade,

    a.uf,

    COUNT(l.id) AS total_reproducoes,

    COALESCE(
        SUM(l.tempo_assistido_minutos),
        0
    ) AS minutos_consumidos

FROM assinantes a

INNER JOIN perfis p
    ON p.assinante_id = a.id

LEFT JOIN logs_reproducao l
    ON l.perfil_id = p.id

GROUP BY
    p.id,
    a.data_nascimento,
    a.uf,
    a.email;

-- =====================================================
-- 07 - SEGURANCA E PRIVILEGIOS
-- =====================================================

-- Usuario da aplicacao

CREATE USER IF NOT EXISTS 'application_user'@'%'
IDENTIFIED BY 'StreamFlow@2026';

-- Usuario de auditoria

CREATE USER IF NOT EXISTS 'auditoria_user'@'%'
IDENTIFIED BY 'Auditoria@2026';

-- Permissoes da aplicacao

GRANT SELECT, INSERT, UPDATE
ON streamflow.assinantes
TO 'application_user'@'%';

GRANT SELECT, INSERT, UPDATE
ON streamflow.perfis
TO 'application_user'@'%';

GRANT SELECT, INSERT, UPDATE
ON streamflow.historicos_reproducao
TO 'application_user'@'%';

GRANT SELECT, INSERT
ON streamflow.logs_reproducao
TO 'application_user'@'%';

GRANT SELECT
ON streamflow.produtoras
TO 'application_user'@'%';

GRANT SELECT
ON streamflow.conteudos
TO 'application_user'@'%';

GRANT SELECT
ON streamflow.filmes
TO 'application_user'@'%';

GRANT SELECT
ON streamflow.series
TO 'application_user'@'%';

GRANT SELECT
ON streamflow.episodios
TO 'application_user'@'%';

GRANT SELECT
ON streamflow.faturamento_produtoras
TO 'application_user'@'%';

-- Permissoes das Procedures

GRANT EXECUTE
ON PROCEDURE streamflow.realizar_cobranca_mensal
TO 'application_user'@'%';

GRANT EXECUTE
ON PROCEDURE streamflow.registrar_reproducao
TO 'application_user'@'%';

GRANT EXECUTE
ON PROCEDURE streamflow.gerar_faturamento_mensal
TO 'application_user'@'%';

-- Permissoes das Functions

GRANT EXECUTE
ON FUNCTION streamflow.calcular_idade
TO 'application_user'@'%';

GRANT EXECUTE
ON FUNCTION streamflow.minutos_assistidos_por_produtora
TO 'application_user'@'%';

-- Permissoes da auditoria

GRANT SELECT
ON streamflow.logs_reproducao
TO 'auditoria_user'@'%';

GRANT SELECT
ON streamflow.auditoria_log
TO 'auditoria_user'@'%';

GRANT SELECT
ON streamflow.vw_analise_engajamento
TO 'auditoria_user'@'%';

FLUSH PRIVILEGES;

-- =====================================================
-- 08 - DADOS DE TESTE
-- =====================================================

-- Insercao dos assinantes

INSERT INTO assinantes
(nome, email, cpf, data_nascimento, uf, saldo)
VALUES
('Joao Xavier', 'joao@email.com', '12345678901', '2004-05-20', 'SP', 100.00),
('Maria Silva', 'maria@email.com', '12345678902', '1990-08-15', 'RJ', 150.00),
('Carlos Souza', 'carlos@email.com', '12345678903', '1985-11-30', 'MG', 200.00);

-- Insercao dos perfis

INSERT INTO perfis
(assinante_id, nome_exibicao)
VALUES
(1, 'Joao'),
(1, 'Familia'),
(2, 'Maria'),
(3, 'Carlos');

-- Insercao das preferencias

INSERT INTO preferencias_perfis
(perfil_id, categoria_favorita)
VALUES
(1, 'Acao'),
(2, 'Comedia'),
(3, 'Drama'),
(4, 'Ficcao');

-- Insercao das produtoras

INSERT INTO produtoras
(nome)
VALUES
('Netflix Studios'),
('Warner Bros'),
('Disney');

-- Insercao dos conteudos

INSERT INTO conteudos
(produtora_id, titulo, genero, classificacao_indicativa, tipo_conteudo)
VALUES
(1, 'Dark', 'Ficcao', '16', 'SERIE'),
(2, 'Interestelar', 'Ficcao', '12', 'FILME'),
(3, 'Loki', 'Acao', '14', 'SERIE');

-- Insercao das series

INSERT INTO series
(conteudo_id)
VALUES
(1),
(3);

-- Insercao dos filmes

INSERT INTO filmes
(conteudo_id, duracao_minutos)
VALUES
(2, 169);

-- Insercao dos episodios

INSERT INTO episodios
(serie_id, titulo, temporada, numero_episodio, duracao_minutos)
VALUES
(1, 'Segredos', 1, 1, 55),
(1, 'Mentiras', 1, 2, 58),
(2, 'Glorioso Proposito', 1, 1, 50);

-- Insercao dos historicos

INSERT INTO historicos_reproducao
(perfil_id, tipo_midia, episodio_id, tempo_visualizado_minutos, concluido)
VALUES
(1, 'EPISODIO', 1, 30, FALSE);

INSERT INTO historicos_reproducao
(perfil_id, tipo_midia, filme_id, tempo_visualizado_minutos, concluido)
VALUES
(1, 'FILME', 1, 90, FALSE);

INSERT INTO historicos_reproducao
(perfil_id, tipo_midia, episodio_id, tempo_visualizado_minutos, concluido)
VALUES
(3, 'EPISODIO', 2, 58, TRUE);

-- Insercao dos logs

INSERT INTO logs_reproducao
(
    perfil_id,
    tipo_midia,
    episodio_id,
    ip_conexao,
    dispositivo,
    data_hora_acesso,
    tempo_assistido_minutos
)
VALUES
(1, 'EPISODIO', 1, '192.168.0.10', 'WEB', '2026-07-05 20:00:00', 55);

INSERT INTO logs_reproducao
(
    perfil_id,
    tipo_midia,
    filme_id,
    ip_conexao,
    dispositivo,
    data_hora_acesso,
    tempo_assistido_minutos
)
VALUES
(1, 'FILME', 1, '192.168.0.20', 'SMARTTV', '2026-07-08 21:30:00', 169);

INSERT INTO logs_reproducao
(
    perfil_id,
    tipo_midia,
    episodio_id,
    ip_conexao,
    dispositivo,
    data_hora_acesso,
    tempo_assistido_minutos
)
VALUES
(3, 'EPISODIO', 2, '192.168.0.30', 'SMARTPHONE', '2026-07-12 19:15:00', 58);

INSERT INTO logs_reproducao
(
    perfil_id,
    tipo_midia,
    episodio_id,
    ip_conexao,
    dispositivo,
    data_hora_acesso,
    tempo_assistido_minutos
)
VALUES
(4, 'EPISODIO', 3, '192.168.0.40', 'WEB', '2026-07-20 22:10:00', 50);

-- =====================================================
-- 09 - CONSULTAS
-- =====================================================

-- Consulta continuar assistindo

SELECT
    h.id,
    h.tipo_midia,
    h.tempo_visualizado_minutos,
    h.data_hora_atualizacao,

    CASE
        WHEN h.tipo_midia = 'FILME' THEN c.titulo
        ELSE e.titulo
    END AS titulo

FROM historicos_reproducao h

LEFT JOIN filmes f
    ON h.filme_id = f.id

LEFT JOIN conteudos c
    ON f.conteudo_id = c.id

LEFT JOIN episodios e
    ON h.episodio_id = e.id

WHERE h.perfil_id = 1
  AND h.concluido = FALSE

ORDER BY h.data_hora_atualizacao DESC;

-- Consulta de consumo por produtora

SELECT
    p.nome,
    SUM(l.tempo_assistido_minutos) AS total_minutos,
    ROUND(SUM(l.tempo_assistido_minutos) / 60, 2) AS total_horas

FROM produtoras p

INNER JOIN conteudos c
    ON c.produtora_id = p.id

LEFT JOIN filmes f
    ON f.conteudo_id = c.id

LEFT JOIN series s
    ON s.conteudo_id = c.id

LEFT JOIN episodios e
    ON e.serie_id = s.id

INNER JOIN logs_reproducao l
    ON (
        l.filme_id = f.id
        OR
        l.episodio_id = e.id
    )

WHERE l.data_hora_acesso >= '2026-07-01'
  AND l.data_hora_acesso < '2026-08-01'

GROUP BY p.id, p.nome

ORDER BY total_horas DESC;

-- Consulta de trafego por regiao

SELECT
    a.uf,
    l.dispositivo,
    COUNT(*) AS total_acessos,
    SUM(l.tempo_assistido_minutos) AS minutos_consumidos

FROM logs_reproducao l

INNER JOIN perfis p
    ON p.id = l.perfil_id

INNER JOIN assinantes a
    ON a.id = p.assinante_id

GROUP BY
    a.uf,
    l.dispositivo

ORDER BY
    a.uf,
    total_acessos DESC;

-- Consulta de engajamento por idade

SELECT
    CASE
        WHEN calcular_idade(a.data_nascimento) < 18
            THEN 'MENOR DE 18'

        WHEN calcular_idade(a.data_nascimento) BETWEEN 18 AND 29
            THEN '18 A 29'

        WHEN calcular_idade(a.data_nascimento) BETWEEN 30 AND 49
            THEN '30 A 49'

        ELSE '50+'
    END AS faixa_etaria,

    COUNT(DISTINCT p.id) AS perfis_ativos,

    AVG(l.tempo_assistido_minutos) AS media_consumo,

    COUNT(l.id) AS total_reproducoes

FROM assinantes a

INNER JOIN perfis p
    ON p.assinante_id = a.id

INNER JOIN logs_reproducao l
    ON l.perfil_id = p.id

GROUP BY faixa_etaria

ORDER BY total_reproducoes DESC;

-- =====================================================
-- 10 - TESTES MANUAIS
-- =====================================================

-- Teste da Function calcular idade

 SELECT calcular_idade('2004-05-20') AS idade;

-- Teste da Function minutos por produtora

 SELECT minutos_assistidos_por_produtora(
     1,
     '2026-07-01'
 ) AS minutos_julho;

-- Teste da Procedure de cobranca com sucesso

 SET @novo_saldo = 0;

 CALL realizar_cobranca_mensal(
     1,
     30.00,
     @novo_saldo
 );

 SELECT @novo_saldo AS novo_saldo;

 SELECT id, nome, saldo
 FROM assinantes
 WHERE id = 1;

-- Teste da Procedure de cobranca sem saldo

 SET @novo_saldo = 0;

 CALL realizar_cobranca_mensal(
     1,
     9999.00,
     @novo_saldo
 );
 
 SELECT id, nome, saldo
 FROM assinantes
 WHERE id = 1;

-- Teste da Procedure registrar reproducao

 SET @id_reproducao = 0;

 CALL registrar_reproducao(
    1,
    'FILME',
    1,
    '200.100.50.10',
    'WEB',
    42,
    @id_reproducao
);

 SELECT @id_reproducao AS reproducao_criada;

 SELECT *
 FROM logs_reproducao
 WHERE id = @id_reproducao;

-- Teste da Procedure registrar reproducao com perfil inexistente

 SET @id_reproducao = 0;

 CALL registrar_reproducao(
    999,
    'FILME',
    1,
    '200.100.50.10',
    'WEB',
    42,
    @id_reproducao
);

-- Teste da Procedure de faturamento

 CALL gerar_faturamento_mensal(
     '2026-07-01'
 );

 SELECT
     fp.id,
     p.nome AS produtora,
     fp.competencia,
     fp.minutos_consumidos
 FROM faturamento_produtoras fp
 INNER JOIN produtoras p
     ON p.id = fp.produtora_id
 ORDER BY fp.produtora_id;

-- Teste do Trigger de saldo negativo no INSERT

 INSERT INTO assinantes
 (nome, email, cpf, data_nascimento, uf, saldo)
 VALUES (
     'Teste Negativo',
     'negativo@email.com',
     '99999999991',
     '2000-01-01',
     'SP',
     -10.00
 );

-- Teste do Trigger de saldo negativo no UPDATE

 UPDATE assinantes
 SET saldo = -1
 WHERE id = 1;

-- Teste do Trigger de bloquear UPDATE

 UPDATE logs_reproducao
 SET tempo_assistido_minutos = 999
 WHERE id = 1;

-- Teste do Trigger de bloquear DELETE

 DELETE FROM logs_reproducao
 WHERE id = 1;

-- Teste do Trigger de auditoria

 UPDATE perfis
 SET nome_exibicao = 'Joao Principal'
 WHERE id = 1;

 SELECT *
 FROM auditoria_log
 ORDER BY id DESC;

-- Teste do Trigger de timestamp

 SELECT
     id,
     nome,
     saldo,
     data_ultima_alteracao
 FROM assinantes
 WHERE id = 2;

 DO SLEEP(1);

 UPDATE assinantes
 SET saldo = saldo + 1
 WHERE id = 2;

 SELECT
     id,
     nome,
     saldo,
     data_ultima_alteracao
 FROM assinantes
 WHERE id = 2;

-- Teste do Trigger de normalizacao do nome

 INSERT INTO assinantes
 (nome, email, cpf, data_nascimento, uf, saldo)
 VALUES (
     '   teste da silva   ',
     'normalizacao@email.com',
     '99999999992',
     '2001-01-01',
     'SP',
     50
 );

 SELECT id, nome
 FROM assinantes
 WHERE email = 'normalizacao@email.com';

-- Teste do limite de 5 perfis

 INSERT INTO perfis
 (assinante_id, nome_exibicao)
 VALUES (1, 'Teste3');

 INSERT INTO perfis
 (assinante_id, nome_exibicao)
 VALUES (1, 'Teste4');

 INSERT INTO perfis
 (assinante_id, nome_exibicao)
 VALUES (1, 'Teste5');

 INSERT INTO perfis
 (assinante_id, nome_exibicao)
 VALUES (1, 'Perfil6');

-- =====================================================
-- 11 - CONSULTAS DE CONFERENCIA
-- =====================================================

-- Conferir assinantes

SELECT *
FROM assinantes;

-- Conferir perfis

SELECT *
FROM perfis;

-- Conferir logs

SELECT *
FROM logs_reproducao
ORDER BY id;

-- Conferir View LGPD

SELECT *
FROM vw_analise_engajamento;

-- Conferir usuarios

SELECT User, Host
FROM mysql.user
WHERE User IN (
    'application_user',
    'auditoria_user'
);

-- Conferir permissoes da aplicacao

SHOW GRANTS FOR 'application_user'@'%';

-- Conferir permissoes da auditoria

SHOW GRANTS FOR 'auditoria_user'@'%';
