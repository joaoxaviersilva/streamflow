import { defineRelations } from "drizzle-orm";

import * as schema from "./schema";

export const relations = defineRelations(schema, (r) => ({
    assinantes: {
        perfis: r.many.perfis(),
    },

    perfis: {
        assinante: r.one.assinantes({
            from: r.perfis.assinanteId,
            to: r.assinantes.id,
        }),

        preferencias: r.many.preferenciasPerfis(),

        historicos: r.many.historicosReproducao(),

        reproducoes: r.many.logsReproducao(),
    },

    preferenciasPerfis: {
        perfil: r.one.perfis({
            from: r.preferenciasPerfis.perfilId,
            to: r.perfis.id,
        }),
    },

    produtoras: {
        conteudos: r.many.conteudos(),

        faturamentos: r.many.faturamentoProdutoras(),
    },

    conteudos: {
        produtora: r.one.produtoras({
            from: r.conteudos.produtoraId,
            to: r.produtoras.id,
        }),

        filme: r.one.filmes({
            from: r.conteudos.id,
            to: r.filmes.conteudoId,
        }),

        serie: r.one.series({
            from: r.conteudos.id,
            to: r.series.conteudoId,
        }),
    },

    filmes: {
        conteudo: r.one.conteudos({
            from: r.filmes.conteudoId,
            to: r.conteudos.id,
        }),

        historicos: r.many.historicosReproducao(),

        reproducoes: r.many.logsReproducao(),
    },

    series: {
        conteudo: r.one.conteudos({
            from: r.series.conteudoId,
            to: r.conteudos.id,
        }),

        episodios: r.many.episodios(),
    },

    episodios: {
        serie: r.one.series({
            from: r.episodios.serieId,
            to: r.series.id,
        }),

        historicos: r.many.historicosReproducao(),

        reproducoes: r.many.logsReproducao(),
    },

    historicosReproducao: {
        perfil: r.one.perfis({
            from: r.historicosReproducao.perfilId,
            to: r.perfis.id,
        }),

        filme: r.one.filmes({
            from: r.historicosReproducao.filmeId,
            to: r.filmes.id,
        }),

        episodio: r.one.episodios({
            from: r.historicosReproducao.episodioId,
            to: r.episodios.id,
        }),
    },

    logsReproducao: {
        perfil: r.one.perfis({
            from: r.logsReproducao.perfilId,
            to: r.perfis.id,
        }),

        filme: r.one.filmes({
            from: r.logsReproducao.filmeId,
            to: r.filmes.id,
        }),

        episodio: r.one.episodios({
            from: r.logsReproducao.episodioId,
            to: r.episodios.id,
        }),
    },

    faturamentoProdutoras: {
        produtora: r.one.produtoras({
            from: r.faturamentoProdutoras.produtoraId,
            to: r.produtoras.id,
        }),
    },
}));