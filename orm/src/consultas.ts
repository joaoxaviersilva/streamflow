import { eq } from "drizzle-orm";

import { db } from "./db/index";
import {
    assinantes,
    perfis,
    produtoras,
    conteudos,
    filmes,
    series,
    episodios,
    historicosReproducao,
} from "./db/schema";

async function main() {
    // Assinantes e perfis

    const assinantesPerfis = await db
        .select({
            assinanteId: assinantes.id,
            nome: assinantes.nome,
            email: assinantes.email,
            saldo: assinantes.saldo,
            perfilId: perfis.id,
            nomeExibicao: perfis.nomeExibicao,
        })
        .from(assinantes)
        .leftJoin(
            perfis,
            eq(assinantes.id, perfis.assinanteId)
        );

    console.log("\nASSINANTES E PERFIS");
    console.table(assinantesPerfis);

    // Conteudos, produtoras, filmes e series

    const conteudosMapeados = await db
        .select({
            conteudoId: conteudos.id,
            titulo: conteudos.titulo,
            tipoConteudo: conteudos.tipoConteudo,
            produtora: produtoras.nome,
            filmeId: filmes.id,
            duracaoFilme: filmes.duracaoMinutos,
            serieId: series.id,
        })
        .from(conteudos)
        .leftJoin(
            produtoras,
            eq(conteudos.produtoraId, produtoras.id)
        )
        .leftJoin(
            filmes,
            eq(conteudos.id, filmes.conteudoId)
        )
        .leftJoin(
            series,
            eq(conteudos.id, series.conteudoId)
        );

    console.log("\nCONTEUDOS, FILMES E SERIES");
    console.table(conteudosMapeados);

    // Series e episodios

    const seriesEpisodios = await db
        .select({
            serieId: series.id,
            conteudoId: series.conteudoId,
            episodioId: episodios.id,
            tituloEpisodio: episodios.titulo,
            temporada: episodios.temporada,
            numeroEpisodio: episodios.numeroEpisodio,
            duracaoMinutos: episodios.duracaoMinutos,
        })
        .from(series)
        .leftJoin(
            episodios,
            eq(series.id, episodios.serieId)
        );

    console.log("\nSERIES E EPISODIOS");
    console.table(seriesEpisodios);

    // Historico de reproducao

    const historicos = await db
        .select({
            historicoId: historicosReproducao.id,
            tipoMidia: historicosReproducao.tipoMidia,
            minutos:
                historicosReproducao.tempoVisualizadoMinutos,
            concluido: historicosReproducao.concluido,
            perfil: perfis.nomeExibicao,
            filmeId: historicosReproducao.filmeId,
            episodioId: historicosReproducao.episodioId,
        })
        .from(historicosReproducao)
        .innerJoin(
            perfis,
            eq(historicosReproducao.perfilId, perfis.id)
        );

    console.log("\nHISTORICO DE REPRODUCAO");
    console.table(historicos);
}

main()
    .catch((erro) => {
        console.error("Erro ao consultar o banco:", erro);
        process.exitCode = 1;
    })
    .finally(async () => {
        await db.$client.end();
    });