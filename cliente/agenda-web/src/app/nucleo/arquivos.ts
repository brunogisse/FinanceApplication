/**
 * Entrega ao usuário um arquivo que veio da API.
 *
 * No Electron isto aciona a caixa de "Salvar como", tratada no processo principal
 * (`principal.js`, evento `will-download`). No navegador, o download normal.
 *
 * O endereço temporário é liberado logo em seguida: cada blob não liberado fica retido em
 * memória até a página ser recarregada, e quem exporta costuma exportar várias vezes.
 */
export function baixarArquivo(conteudo: Blob, nome: string): void {
  const endereco = URL.createObjectURL(conteudo);

  const ligacao = document.createElement('a');
  ligacao.href = endereco;
  ligacao.download = nome;
  document.body.appendChild(ligacao);
  ligacao.click();
  ligacao.remove();

  // Um instante depois: liberar no mesmo ciclo cancela o download que acabou de começar.
  setTimeout(() => URL.revokeObjectURL(endereco), 10_000);
}
