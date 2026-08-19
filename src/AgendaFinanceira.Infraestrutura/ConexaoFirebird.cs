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
