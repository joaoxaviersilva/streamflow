import { eq } from "drizzle-orm";
import type { RowDataPacket } from "mysql2";

import { db, pool } from "./db/index";
import {
    assinantes,
    logsReproducao,
    faturamentoProdutoras,
    produtoras,
} from "./db/schema";

// Functions

async function testarFuncoes() {
    const connection = await pool.promise().getConnection();

    try {
        const [idade] = await connection.query<RowDataPacket[]>(
            "SELECT calcular_idade(?) AS idade",
            ["2004-05-20"]
        );

        console.log("\nFUNCTION calcular_idade");
        console.table(idade);

        const [minutos] = await connection.query<RowDataPacket[]>(
            `
            SELECT minutos_assistidos_por_produtora(?, ?) AS minutos
            `,
            [1, "2026-07-01"]
        );

        console.log(
            "\nFUNCTION minutos_assistidos_por_produtora"
        );
        console.table(minutos);
    } finally {
        connection.release();
    }
}

// Procedure de cobranca

async function testarCobranca() {
    const connection = await pool.promise().getConnection();

    try {
        await connection.query(
            "SET @novo_saldo = NULL"
        );

        await connection.query(
            `
            CALL realizar_cobranca_mensal(
                ?,
                ?,
                @novo_saldo
            )
            `,
            [4, 5.00]
        );

        const [resultado] =
            await connection.query<RowDataPacket[]>(
                "SELECT @novo_saldo AS novo_saldo"
            );

        console.log(
            "\nPROCEDURE realizar_cobranca_mensal"
        );
        console.table(resultado);
    } finally {
        connection.release();
    }

    const assinante = await db
        .select({
            id: assinantes.id,
            nome: assinantes.nome,
            saldo: assinantes.saldo,
        })
        .from(assinantes)
        .where(eq(assinantes.id, 4));

    console.log("\nASSINANTE APOS A COBRANCA");
    console.table(assinante);
}

// Procedure de reproducao

async function testarReproducao() {
    const connection = await pool.promise().getConnection();

    let idReproducao = 0;

    try {
        await connection.query(
            "SET @id_reproducao = NULL"
        );

        await connection.query(
            `
            CALL registrar_reproducao(
                ?,
                ?,
                ?,
                ?,
                ?,
                @id_reproducao
            )
            `,
            [
                1,
                "FILME",
                1,
                "200.100.50.20",
                "WEB",
            ]
        );

        const [resultado] =
            await connection.query<RowDataPacket[]>(
                `
                SELECT
                    @id_reproducao AS id_reproducao
                `
            );

        idReproducao =
            Number(resultado[0].id_reproducao);

        console.log(
            "\nPROCEDURE registrar_reproducao"
        );
        console.table(resultado);
    } finally {
        connection.release();
    }

    const reproducao = await db
        .select({
            id: logsReproducao.id,
            perfilId: logsReproducao.perfilId,
            tipoMidia: logsReproducao.tipoMidia,
            filmeId: logsReproducao.filmeId,
            episodioId: logsReproducao.episodioId,
            ipConexao: logsReproducao.ipConexao,
            dispositivo: logsReproducao.dispositivo,
        })
        .from(logsReproducao)
        .where(eq(logsReproducao.id, idReproducao));

    console.log("\nREPRODUCAO CRIADA");
    console.table(reproducao);
}

// Procedure de faturamento

async function testarFaturamento() {
    const connection = await pool.promise().getConnection();

    try {
        await connection.query(
            "CALL gerar_faturamento_mensal(?)",
            ["2026-07-01"]
        );

        console.log(
            "\nPROCEDURE gerar_faturamento_mensal executada"
        );
    } finally {
        connection.release();
    }

    const faturamentos = await db
        .select({
            produtora: produtoras.nome,
            competencia:
                faturamentoProdutoras.competencia,
            minutos:
                faturamentoProdutoras.minutosConsumidos,
        })
        .from(faturamentoProdutoras)
        .innerJoin(
            produtoras,
            eq(
                faturamentoProdutoras.produtoraId,
                produtoras.id
            )
        );

    console.log("\nFATURAMENTO DAS PRODUTORAS");
    console.table(faturamentos);
}

async function main() {
    const comando = process.argv[2];

    switch (comando) {
        case "funcoes":
            await testarFuncoes();
            break;

        case "cobranca":
            await testarCobranca();
            break;

        case "reproducao":
            await testarReproducao();
            break;

        case "faturamento":
            await testarFaturamento();
            break;

        default:
            console.log(`
Comandos disponiveis:

npm run procedimentos -- funcoes
npm run procedimentos -- cobranca
npm run procedimentos -- reproducao
npm run procedimentos -- faturamento
            `);
    }
}

main()
    .catch((erro) => {
        console.error("\nErro:", erro);
        process.exitCode = 1;
    })
    .finally(async () => {
        await pool.promise().end();
    });