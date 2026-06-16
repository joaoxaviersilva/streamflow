-- =====================================================
-- STREAMFLOW
-- PROJETO INTEGRADOR DE BANCO DE DADOS
-- MYSQL 8.0
-- =====================================================

DROP DATABASE IF EXISTS streamflow;
CREATE DATABASE streamflow;
USE streamflow;

-- =====================================================
-- TABELA ASSINANTES
-- =====================================================

CREATE TABLE assinantes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    nome VARCHAR(150) NOT NULL,

    email VARCHAR(255) NOT NULL UNIQUE,

    cpf CHAR(11) NOT NULL UNIQUE,

    data_nascimento DATE NOT NULL,

    uf CHAR(2) NOT NULL,

    saldo DECIMAL(12,2) NOT NULL DEFAULT 0.00,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_saldo_positivo
        CHECK (saldo >= 0)
);

-- =====================================================
-- TABELA PERFIS
-- =====================================================

CREATE TABLE perfis (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    assinante_id BIGINT NOT NULL,

    nome_exibicao VARCHAR(100) NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_perfis_assinantes
        FOREIGN KEY (assinante_id)
        REFERENCES assinantes(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- =====================================================
-- TABELA PREFERENCIAS PERFIS
-- =====================================================

CREATE TABLE preferencias_perfis (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    perfil_id BIGINT NOT NULL,

    categoria_favorita VARCHAR(100) NOT NULL,

    CONSTRAINT fk_preferencias_perfis
        FOREIGN KEY (perfil_id)
        REFERENCES perfis(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- =====================================================
-- PRODUTORAS
-- =====================================================

CREATE TABLE produtoras (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    nome VARCHAR(200) NOT NULL UNIQUE
);

-- =====================================================
-- CONTEUDOS
-- =====================================================

CREATE TABLE conteudos (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    produtora_id BIGINT NOT NULL,

    titulo VARCHAR(255) NOT NULL,

    genero VARCHAR(100),

    classificacao_indicativa VARCHAR(10),

    tipo_conteudo ENUM('FILME','SERIE') NOT NULL,

    ativo BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_conteudos_produtoras
        FOREIGN KEY (produtora_id)
        REFERENCES produtoras(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- =====================================================
-- FILMES
-- =====================================================

CREATE TABLE filmes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    conteudo_id BIGINT NOT NULL UNIQUE,

    duracao_minutos INT NOT NULL,

    CONSTRAINT fk_filmes_conteudos
        FOREIGN KEY (conteudo_id)
        REFERENCES conteudos(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- =====================================================
-- SERIES
-- =====================================================

CREATE TABLE series (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    conteudo_id BIGINT NOT NULL UNIQUE,

    CONSTRAINT fk_series_conteudos
        FOREIGN KEY (conteudo_id)
        REFERENCES conteudos(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- =====================================================
-- EPISODIOS
-- =====================================================

CREATE TABLE episodios (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    serie_id BIGINT NOT NULL,

    titulo VARCHAR(255) NOT NULL,

    temporada INT NOT NULL,

    numero_episodio INT NOT NULL,

    duracao_minutos INT NOT NULL,

    CONSTRAINT fk_episodios_series
        FOREIGN KEY (serie_id)
        REFERENCES series(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- =====================================================
-- HISTORICOS DE REPRODUCAO
-- =====================================================

CREATE TABLE historicos_reproducao (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    perfil_id BIGINT NOT NULL,

    tipo_midia ENUM('FILME','EPISODIO') NOT NULL,

    filme_id BIGINT NULL,

    episodio_id BIGINT NULL,

    tempo_visualizado_minutos INT NOT NULL DEFAULT 0,

    concluido BOOLEAN NOT NULL DEFAULT FALSE,

    data_hora_atualizacao TIMESTAMP
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_hist_perfis
        FOREIGN KEY (perfil_id)
        REFERENCES perfis(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_hist_filmes
        FOREIGN KEY (filme_id)
        REFERENCES filmes(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_hist_episodios
        FOREIGN KEY (episodio_id)
        REFERENCES episodios(id)
        ON DELETE RESTRICT
);

-- =====================================================
-- LOGS IMUTAVEIS
-- =====================================================

CREATE TABLE logs_reproducao (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    perfil_id BIGINT NOT NULL,

    tipo_midia ENUM('FILME','EPISODIO') NOT NULL,

    filme_id BIGINT NULL,

    episodio_id BIGINT NULL,

    ip_conexao VARCHAR(45) NOT NULL,

    dispositivo ENUM(
        'SMARTTV',
        'SMARTPHONE',
        'WEB'
    ) NOT NULL,

    data_hora_acesso TIMESTAMP
        DEFAULT CURRENT_TIMESTAMP,

    tempo_assistido_minutos INT NOT NULL DEFAULT 0,

    CONSTRAINT fk_logs_perfis
        FOREIGN KEY (perfil_id)
        REFERENCES perfis(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_logs_filmes
        FOREIGN KEY (filme_id)
        REFERENCES filmes(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_logs_episodios
        FOREIGN KEY (episodio_id)
        REFERENCES episodios(id)
        ON DELETE RESTRICT
);

-- =====================================================
-- TRIGGER: LIMITE DE 5 PERFIS POR ASSINANTE
-- =====================================================

DELIMITER $$

CREATE TRIGGER tg_limite_perfis
BEFORE INSERT ON perfis
FOR EACH ROW
BEGIN

    DECLARE qtd_perfis INT;

    SELECT COUNT(*)
    INTO qtd_perfis
    FROM perfis
    WHERE assinante_id = NEW.assinante_id;

    IF qtd_perfis >= 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Um assinante pode possuir no máximo 5 perfis.';
    END IF;

END$$

DELIMITER ;

-- =====================================================
-- FUNÇÃO DE PROTEÇÃO DOS LOGS
-- =====================================================

DELIMITER $$

CREATE TRIGGER tg_logs_bloqueia_update
BEFORE UPDATE ON logs_reproducao
FOR EACH ROW
BEGIN

    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT =
    'Logs são imutáveis. UPDATE proibido.';

END$$

DELIMITER ;

-- =====================================================
-- TRIGGER DE BLOQUEIO DE DELETE
-- =====================================================

DELIMITER $$

CREATE TRIGGER tg_logs_bloqueia_delete
BEFORE DELETE ON logs_reproducao
FOR EACH ROW
BEGIN

    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT =
    'Logs são imutáveis. DELETE proibido.';

END$$

DELIMITER ;

-- =====================================================
-- ÍNDICES DE PERFORMANCE
-- =====================================================

CREATE INDEX idx_historico_perfil_pendente
ON historicos_reproducao (
    perfil_id,
    concluido,
    data_hora_atualizacao
);

CREATE INDEX idx_logs_data_acesso
ON logs_reproducao (
    data_hora_acesso
);

CREATE INDEX idx_logs_dispositivo
ON logs_reproducao (
    dispositivo
);

CREATE INDEX idx_assinantes_uf
ON assinantes (
    uf
);

CREATE INDEX idx_conteudos_produtora
ON conteudos (
    produtora_id
);

CREATE INDEX idx_logs_perfil
ON logs_reproducao (
    perfil_id
);

-- =====================================================
-- VIEW LGPD
-- =====================================================

CREATE VIEW vw_analise_engajamento AS

SELECT

    p.id AS perfil_id,

    'CONFIDENCIAL' AS nome,

    CONCAT(
        LEFT(a.email,2),
        '***@',
        SUBSTRING_INDEX(a.email,'@',-1)
    ) AS email_mascarado,

    '***.***.***-**' AS cpf,

    TIMESTAMPDIFF(
        YEAR,
        a.data_nascimento,
        CURDATE()
    ) AS idade,

    a.uf,

    COUNT(l.id) AS total_reproducoes,

    SUM(l.tempo_assistido_minutos)
        AS minutos_consumidos

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
-- SEGURANÇA
-- =====================================================

CREATE USER IF NOT EXISTS
'application_user'@'%'
IDENTIFIED BY 'StreamFlow@2026';

CREATE USER IF NOT EXISTS
'auditoria_user'@'%'
IDENTIFIED BY 'Auditoria@2026';

-- =====================================================
-- PERMISSÕES APLICAÇÃO
-- =====================================================

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

-- =====================================================
-- PERMISSÕES AUDITORIA
-- =====================================================

GRANT SELECT
ON streamflow.logs_reproducao
TO 'auditoria_user'@'%';

GRANT SELECT
ON streamflow.vw_analise_engajamento
TO 'auditoria_user'@'%';

FLUSH PRIVILEGES;

-- =====================================================
-- DADOS DE TESTE
-- =====================================================

-- ==========================================
-- ASSINANTES
-- ==========================================

INSERT INTO assinantes
(nome,email,cpf,data_nascimento,uf,saldo)
VALUES
('Joao Xavier','joao@email.com','12345678901','2004-05-20','SP',100.00),
('Maria Silva','maria@email.com','12345678902','1990-08-15','RJ',150.00),
('Carlos Souza','carlos@email.com','12345678903','1985-11-30','MG',200.00);

-- ==========================================
-- PERFIS
-- ==========================================

INSERT INTO perfis
(assinante_id,nome_exibicao)
VALUES
(1,'Joao'),
(1,'Familia'),
(2,'Maria'),
(3,'Carlos');

-- ==========================================
-- PREFERENCIAS
-- ==========================================

INSERT INTO preferencias_perfis
(perfil_id,categoria_favorita)
VALUES
(1,'Acao'),
(2,'Comedia'),
(3,'Drama'),
(4,'Ficcao');

-- ==========================================
-- PRODUTORAS
-- ==========================================

INSERT INTO produtoras
(nome)
VALUES
('Netflix Studios'),
('Warner Bros'),
('Disney');

-- ==========================================
-- CONTEUDOS
-- ==========================================

INSERT INTO conteudos
(produtora_id,titulo,genero,classificacao_indicativa,tipo_conteudo)
VALUES
(1,'Dark','Ficcao','16','SERIE'),
(2,'Interestelar','Ficcao','12','FILME'),
(3,'Loki','Acao','14','SERIE');

-- ==========================================
-- SERIES
-- ==========================================

INSERT INTO series
(conteudo_id)
VALUES
(1),
(3);

-- ==========================================
-- FILMES
-- ==========================================

INSERT INTO filmes
(conteudo_id,duracao_minutos)
VALUES
(2,169);

-- ==========================================
-- EPISODIOS
-- ==========================================

INSERT INTO episodios
(serie_id,titulo,temporada,numero_episodio,duracao_minutos)
VALUES
(1,'Segredos',1,1,55),
(1,'Mentiras',1,2,58),
(2,'Glorioso Proposito',1,1,50);

-- ==========================================
-- HISTORICO
-- ==========================================

INSERT INTO historicos_reproducao
(
perfil_id,
tipo_midia,
episodio_id,
tempo_visualizado_minutos,
concluido
)
VALUES
(
1,
'EPISODIO',
1,
30,
FALSE
);

INSERT INTO historicos_reproducao
(
perfil_id,
tipo_midia,
filme_id,
tempo_visualizado_minutos,
concluido
)
VALUES
(
1,
'FILME',
1,
90,
FALSE
);

INSERT INTO historicos_reproducao
(
perfil_id,
tipo_midia,
episodio_id,
tempo_visualizado_minutos,
concluido
)
VALUES
(
3,
'EPISODIO',
2,
58,
TRUE
);

-- ==========================================
-- LOGS
-- ==========================================

INSERT INTO logs_reproducao
(
perfil_id,
tipo_midia,
episodio_id,
ip_conexao,
dispositivo,
tempo_assistido_minutos
)
VALUES
(
1,
'EPISODIO',
1,
'192.168.0.10',
'WEB',
55
);

INSERT INTO logs_reproducao
(
perfil_id,
tipo_midia,
filme_id,
ip_conexao,
dispositivo,
tempo_assistido_minutos
)
VALUES
(
1,
'FILME',
1,
'192.168.0.20',
'SMARTTV',
169
);

INSERT INTO logs_reproducao
(
perfil_id,
tipo_midia,
episodio_id,
ip_conexao,
dispositivo,
tempo_assistido_minutos
)
VALUES
(
3,
'EPISODIO',
2,
'192.168.0.30',
'SMARTPHONE',
58
);

INSERT INTO logs_reproducao
(
perfil_id,
tipo_midia,
episodio_id,
ip_conexao,
dispositivo,
tempo_assistido_minutos
)
VALUES
(
4,
'EPISODIO',
3,
'192.168.0.40',
'WEB',
50
);

-- =====================================================
-- CONSULTA 1
-- CONTINUAR ASSISTINDO
-- =====================================================

SELECT

    h.id,

    h.tipo_midia,

    h.tempo_visualizado_minutos,

    h.data_hora_atualizacao,

    CASE
        WHEN h.tipo_midia = 'FILME'
            THEN c.titulo
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

-- =====================================================
-- CONSULTA 2
-- FATURAMENTO PRODUTORAS
-- =====================================================

SELECT

    p.nome,

    SUM(
        l.tempo_assistido_minutos
    ) AS total_minutos,

    ROUND(
        SUM(l.tempo_assistido_minutos)/60,
        2
    ) AS total_horas

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

WHERE MONTH(l.data_hora_acesso) = 6
AND YEAR(l.data_hora_acesso) = 2026

GROUP BY p.id, p.nome

HAVING
SUM(l.tempo_assistido_minutos)
> 300000

ORDER BY total_horas DESC;

-- =====================================================
-- CONSULTA 3
-- AUDITORIA REGIONAL
-- =====================================================

SELECT

    a.uf,

    l.dispositivo,

    COUNT(*) AS total_acessos,

    SUM(
        l.tempo_assistido_minutos
    ) AS minutos_consumidos

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

-- =====================================================
-- CONSULTA 4
-- BI DE ENGAJAMENTO
-- =====================================================

SELECT

CASE

WHEN TIMESTAMPDIFF(
YEAR,
a.data_nascimento,
CURDATE()
) < 18

THEN 'MENOR DE 18'

WHEN TIMESTAMPDIFF(
YEAR,
a.data_nascimento,
CURDATE()
) BETWEEN 18 AND 29

THEN '18 A 29'

WHEN TIMESTAMPDIFF(
YEAR,
a.data_nascimento,
CURDATE()
) BETWEEN 30 AND 49

THEN '30 A 49'

ELSE '50+'

END AS faixa_etaria,

COUNT(DISTINCT p.id)
AS perfis_ativos,

AVG(
l.tempo_assistido_minutos
) AS media_consumo,

COUNT(l.id)
AS total_reproducoes

FROM assinantes a

INNER JOIN perfis p
ON p.assinante_id = a.id

INNER JOIN logs_reproducao l
ON l.perfil_id = p.id

GROUP BY faixa_etaria

ORDER BY total_reproducoes DESC;




