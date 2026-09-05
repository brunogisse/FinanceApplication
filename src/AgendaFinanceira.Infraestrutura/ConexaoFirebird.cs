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

    /// <summary>
    /// Abre conexões com o banco, local ou num servidor da rede.
    ///
    /// O <paramref name="caminhoBanco"/> aceita as duas formas do Firebird:
    ///
    ///   C:\bases\FINANCES.FDB              banco no disco desta máquina
    ///   192.168.1.20:C:\bases\FINANCES.FDB banco no servidor, no caminho DE LÁ
    ///
    /// Na segunda forma o servidor vem embutido no caminho e prevalece sobre
    /// <paramref name="servidor"/>: é assim que o Firebird sempre escreveu isso, e obrigar
    /// a separar em dois campos faria a mesma cadeia funcionar no isql e não aqui.
    ///
    /// **Caminho de compartilhamento (\\maquina\pasta\banco.FDB) não serve.** O Firebird
    /// recusa por padrão, e forçar corrompe o arquivo: o mecanismo de trava dele não
    /// atravessa rede, então dois processos escrevem por cima um do outro sem perceber.
    /// Banco em rede se alcança pelo SERVIDOR, nunca pelo sistema de arquivos.
    /// </summary>
    public ConexaoFirebird(string caminhoBanco, string servidor = "localhost",
                           string usuario = "SYSDBA", string senha = "masterkey",
                           int porta = 3050)
    {
        if (EhCaminhoDeRede(caminhoBanco))
            throw new ArgumentException(
                $"'{caminhoBanco}' é um caminho de compartilhamento de rede, e o Firebird não " +
                "abre banco assim — forçar corrompe o arquivo. Use servidor e caminho: " +
                @"'192.168.1.20:C:\bases\FINANCES.FDB', onde o caminho é o do disco DO SERVIDOR.",
                nameof(caminhoBanco));

        // "maquina:C:\caminho" traz o servidor embutido. Repetir o DataSource nesse caso faria
        // o provider montar "localhost" na frente de um endereço que já é completo.
        var (servidorEfetivo, caminhoEfetivo) = SepararServidor(caminhoBanco, servidor);

        _cadeia = new FbConnectionStringBuilder
        {
            DataSource = servidorEfetivo,
            Database = caminhoEfetivo,
            Port = porta,
            UserID = usuario,
            Password = senha,
            Charset = "ISO8859_1",
            Dialect = 3,
            ServerType = FbServerType.Default
        }.ToString();
    }

    /// <summary>UNC (\\maquina\pasta) ou caminho iniciado por duas barras.</summary>
    internal static bool EhCaminhoDeRede(string caminho) =>
        caminho.StartsWith(@"\\", StringComparison.Ordinal) ||
        caminho.StartsWith("//", StringComparison.Ordinal);

    /// <summary>
    /// Separa "servidor:caminho" quando o servidor vem embutido.
    ///
    /// A ambiguidade é com a letra do disco: <c>C:\bases\x.FDB</c> também tem dois-pontos.
    /// O que distingue é o tamanho do que vem antes — uma letra só é disco; mais que isso é
    /// nome de máquina ou IP.
    /// </summary>
    internal static (string Servidor, string Caminho) SepararServidor(string caminhoBanco, string padrao)
    {
        var corte = caminhoBanco.IndexOf(':');
        if (corte > 1)
        {
            var antes = caminhoBanco[..corte];
            var depois = caminhoBanco[(corte + 1)..];
            if (!string.IsNullOrWhiteSpace(antes) && !string.IsNullOrWhiteSpace(depois))
                return (antes, depois);
        }
        return (padrao, caminhoBanco);
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
