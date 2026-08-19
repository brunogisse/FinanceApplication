using System.Data;
using System.Text;
using FirebirdSql.Data.FirebirdClient;

namespace AgendaFinanceira.Infraestrutura;

/// <summary>
/// Abre conexões com o banco legado.
///
/// O charset é ISO8859_1 e não WIN1252 porque o provider recusa WIN1252 em todas as variantes
/// do nome — verificado no spike. Os dois são idênticos onde vivem os acentos do português
/// (0xA0 a 0xFF) e divergem de 0x80 a 0x9F, onde ficam travessões e aspas tipográficas.
/// Por isso o texto livre é lido como bytes e decodificado com a página 1252.
/// Ver docs/decisoes/0009-acesso-a-dados-dapper-e-charset.md.
/// </summary>
public sealed class ConexaoFirebird
{
    private readonly string _cadeia;

    /// <summary>Página de código 1252, a interpretação correta dos bytes gravados pelo legado.</summary>
    public static readonly Encoding Win1252;

    static ConexaoFirebird()
    {
        Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
        Win1252 = Encoding.GetEncoding(1252);
    }

    public ConexaoFirebird(string caminhoBanco, string servidor = "localhost",
                           string usuario = "SYSDBA", string senha = "masterkey")
    {
        _cadeia = new FbConnectionStringBuilder
        {
            DataSource = servidor,
            Database = caminhoBanco,
            UserID = usuario,
            Password = senha,
            Charset = "ISO8859_1",
            Dialect = 3,
            ServerType = FbServerType.Default
        }.ToString();
    }

    public IDbConnection Abrir()
    {
        var con = new FbConnection(_cadeia);
        con.Open();
        return con;
    }

    /// <summary>
    /// Converte o que veio de uma coluna de texto lida como OCTETS. Se o provider já devolveu
    /// string (colunas curtas e controladas), passa direto.
    /// </summary>
    public static string? TextoDoLegado(object? valor) => valor switch
    {
        null or DBNull => null,
        byte[] bytes => Win1252.GetString(bytes).TrimEnd(),
        string texto => texto.TrimEnd(),
        _ => valor.ToString()?.TrimEnd()
    };

    /// <summary>
    /// Substitui pontuação tipográfica por equivalentes que cabem no banco, antes de gravar.
    ///
    /// A conexão usa ISO8859_1, onde travessões, aspas curvas e reticências não existem. Sem
    /// isso, a conversão aconteceria assim mesmo, mas de forma implícita e a mercê do
    /// provider — e o que é implícito não se pode garantir nem testar. Aqui é explícito.
    ///
    /// Word e Excel produzem esses caracteres sozinhos, e o fluxo de importação por planilha
    /// lê do Excel; é por ali que eles entram. Ver ADR 0009.
    /// </summary>
    public static string? NormalizarParaGravar(string? texto)
    {
        if (string.IsNullOrEmpty(texto)) return texto;

        var saida = new StringBuilder(texto.Length);
        foreach (var c in texto)
        {
            switch (c)
            {
                case '‐': case '‑': case '‒':
                case '–': case '—': case '―':
                    saida.Append('-'); break;              // hifens e travessões
                case '‘': case '’': case '‚': case '′':
                    saida.Append('\''); break;             // aspas simples curvas
                case '“': case '”': case '„': case '″':
                    saida.Append('"'); break;              // aspas duplas curvas
                case '…':
                    saida.Append("..."); break;            // reticências
                case '•': case '·':
                    saida.Append('*'); break;              // marcadores
                case ' ': case ' ': case ' ':
                    saida.Append(' '); break;              // espaços especiais
                case '™':
                    saida.Append("(TM)"); break;
                case '€':
                    saida.Append("EUR"); break;
                default:
                    saida.Append(c); break;
            }
        }
        return saida.ToString();
    }

    /// <summary>
    /// O legado grava 30/12/1899 — o zero do TDateTime do Delphi — quando a data fica vazia.
    /// São 11 registros. Aqui isso vira ausência de data, que é o que significa.
    /// </summary>
    public static readonly DateOnly ZeroDoDelphi = new(1899, 12, 30);

    public static DateOnly? DataDoLegado(object? valor)
    {
        if (valor is null or DBNull) return null;
        var data = DateOnly.FromDateTime(Convert.ToDateTime(valor));
        return data == ZeroDoDelphi ? null : data;
    }
}
