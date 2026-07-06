# Especificação: Conversor e Combinador de PDF (Flutter Desktop)

## 1. Visão Geral

Aplicativo desktop (Windows, macOS, Linux) construído em Flutter com duas funcionalidades
independentes:

1. Converter uma ou mais imagens (PNG, JPG, JPEG) em um arquivo PDF.
2. Unir dois ou mais arquivos PDF existentes em um único arquivo PDF.

Não há backend, conta de usuário, nuvem ou sincronização. Tudo roda localmente,
processando arquivos do sistema de arquivos do usuário.

## 2. Fora de Escopo (explicitamente)

Para manter o app enxuto, os itens abaixo **não** fazem parte do produto, mesmo que
pareçam "óbvios" de adicionar depois:

- OCR ou extração de texto de imagens/PDFs
- Edição de páginas de PDF (rotacionar, excluir, reordenar página a página)
- Compressão/otimização de PDF
- Assinatura digital ou proteção por senha
- Exportar para outros formatos além de PDF
- Suporte a mobile ou web
- Qualquer tipo de conta, login ou armazenamento em nuvem

## 3. Funcionalidade 1 — Imagens para PDF

### 3.1 História de usuário
Como usuário, quero selecionar uma ou mais imagens (PNG, JPG, JPEG) e gerar um único
arquivo PDF contendo essas imagens, uma por página, para poder compartilhar ou
arquivar fotos em formato PDF.

### 3.2 Comportamento esperado
- Usuário seleciona uma ou mais imagens via diálogo nativo de arquivos.
- Formatos aceitos: `.png`, `.jpg`, `.jpeg` (qualquer outro formato é rejeitado com
  mensagem clara).
- Usuário pode reordenar as imagens selecionadas antes de gerar o PDF (a ordem da
  lista define a ordem das páginas).
- Usuário pode remover uma imagem da lista antes de converter.
- Cada imagem vira uma página do PDF, mantendo a proporção original da imagem
  (sem distorcer), centralizada na página.
- Usuário escolhe o local e nome do arquivo PDF de saída via diálogo "Salvar como".
- Ao concluir, o app mostra confirmação de sucesso e, idealmente, opção de abrir a
  pasta de destino.

### 3.3 Casos de erro a tratar
- Nenhuma imagem selecionada → botão de converter fica desabilitado.
- Imagem corrompida ou ilegível → informar qual arquivo falhou, sem travar o app.
- Falha ao salvar (ex.: sem permissão de escrita) → mensagem de erro clara.

## 4. Funcionalidade 2 — Unir PDFs

### 4.1 História de usuário
Como usuário, quero selecionar dois ou mais arquivos PDF e uni-los em um único PDF,
na ordem que eu escolher, para consolidar documentos separados em um só arquivo.

### 4.2 Comportamento esperado
- Usuário seleciona dois ou mais arquivos `.pdf` via diálogo nativo de arquivos.
- Usuário pode reordenar a lista de PDFs antes de unir (ordem da lista = ordem no
  PDF final).
- Usuário pode remover um PDF da lista antes de unir.
- O PDF final contém todas as páginas de todos os PDFs selecionados, em sequência,
  respeitando a ordem definida pelo usuário.
- Usuário escolhe local e nome do arquivo de saída via diálogo "Salvar como".
- Confirmação de sucesso ao final.

### 4.3 Casos de erro a tratar
- Menos de 2 PDFs selecionados → botão de unir desabilitado.
- PDF corrompido, protegido por senha ou ilegível → informar qual arquivo falhou,
  sem travar o app, permitindo remover o arquivo problemático e tentar novamente.
- Falha ao salvar → mensagem de erro clara.

## 5. Requisitos Não-Funcionais

- **Plataformas**: Windows, macOS, Linux (build desktop nativo do Flutter).
- **Offline-first**: nenhuma funcionalidade depende de internet.
- **Performance**: conversão/união de até ~50 arquivos deve completar em segundos,
  não minutos, em hardware comum.
- **UI**: interface simples, duas telas ou abas (uma por funcionalidade), sem
  necessidade de onboarding ou tutorial.
- **Distribuição**: o app deve ser distribuído como executável/instalador nativo por
  plataforma (não apenas rodado via `flutter run`).
- **Qualidade/testes**: o projeto deve ter cobertura de testes automatizados —
  no mínimo 5 casos positivos e 5 casos negativos em testes unitários, e no mínimo
  5 casos positivos e 5 casos negativos em testes de integração.
- **DevOps**: o projeto deve ter um pipeline de CI/CD que rode os testes, gere o
  build/instalador, e envie o executável por e-mail (endereço vindo de variável de
  ambiente) quando tudo passar.

## 6. Perguntas em Aberto (para revisar antes do plano técnico)

- [ ] Existe preferência de nome/identidade visual do app?
- [ ] O PDF gerado a partir de imagens deve ter tamanho de página fixo (A4/Letter)
      ou ajustado ao tamanho de cada imagem?
