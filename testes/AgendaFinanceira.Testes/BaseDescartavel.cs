using AgendaFinanceira.Infraestrutura;

namespace AgendaFinanceira.Testes;

/// <summary>
/// Cópia descartável do banco, para os testes que escrevem.
///
/// Cada classe de teste recebe o seu próprio arquivo, copiado de um molde e apagado ao final.
/// Assim um teste nunca enxerga o que outro gravou, e nem a base de paridade nem a produção
/// são tocadas em momento algum.
///
/// O molde é a base congelada com a coluna SENHA_HASH já aplicada — ver o ADR 0010.
/// </summary>
public sealed class BaseDescartavel : IDisposable
{
    private const string Molde = @"C:\PROGRAMAS\AgendaFinanceira-paridade\MOLDE_ESCRITA.FDB";

    public string Caminho { get; }
    public ConexaoFirebird Conexao { get; }

    public BaseDescartavel()
    {
        Assert.True(File.Exists(Molde),
            $"Molde de escrita não encontrado em {Molde}. " +
            "Recrie-o restaurando o backup de paridade e aplicando ALTER TABLE LOGIN ADD SENHA_HASH VARCHAR(200).");

        Caminho = Path.Combine(Path.GetTempPath(), $"agenda-teste-{Guid.NewGuid():N}.fdb");
        File.Copy(Molde, Caminho);
        Conexao = new ConexaoFirebird(Caminho);
    }

    public RepositorioCadastros Cadastros() => new(Conexao);
    public RepositorioUsuarios Usuarios() => new(Conexao, new ServicoSenhaBCrypt());
    public RepositorioLancamentos Lancamentos() => new(Conexao);

    public void Dispose()
    {
        // O servidor pode segurar o arquivo por um instante depois da última conexão.
        for (var tentativa = 0; tentativa < 10; tentativa++)
        {
            try
            {
                if (File.Exists(Caminho)) File.Delete(Caminho);
                return;
            }
            catch (IOException) { Thread.Sleep(200); }
            catch (UnauthorizedAccessException) { Thread.Sleep(200); }
        }
    }
}
