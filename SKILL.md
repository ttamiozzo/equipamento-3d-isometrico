---
name: equipamento-3d-isometrico
description: Transforma qualquer equipamento de rede, telecom ou datacenter (por nome de modelo, foto ou descrição em texto) em um modelo padronizado em JSON e o mostra como desenho isométrico, 3D real (three.js) ou diagrama 2D editável do draw.io (.drawio), montando dashboards interativos com vários equipamentos em racks interligados por cabos, mostrando cada porta (PON, uplink, gerência, SFP, RJ45, SC/APC…), seu status, métricas e onde cada cabo está ligado. Use sempre que o usuário pedir desenho, diagrama, mapa, maquete, visualização 3D/isométrica ou dashboard de OLT, switch, roteador, DIO, patch panel, servidor, rack, POP, sala técnica ou datacenter; quando mandar foto de um equipamento querendo vê-lo no painel; quando quiser documentar cabeamento, mapa de portas ou "onde cada fibra está ligada"; ou quando quiser adicionar um equipamento novo a um dashboard iso3d existente, mesmo que não use a palavra "3D".
---

# Equipamento 3D isométrico

Esta skill tem duas peças que funcionam juntas.

1. **Modelos de equipamento** (JSON, um por tipo de equipamento). Descrevem em milímetros o chassi, as faces, as portas, os slots e as placas. São reutilizáveis: um modelo de "Huawei MA5600T" serve para todas as OLTs desse tipo.
2. **Dashboards** (JSON). Dizem onde cada equipamento está (rack e U), quais placas estão instaladas, quais cabos ligam quais portas e o estado e as métricas de cada porta.

O motor em `assets/template.html` lê esse JSON e desenha a cena 3D. O usuário pode girar, dar zoom, clicar em portas, placas e cabos, editar conexões, filtrar a tabela de portas e exportar o JSON. Como todos os modelos seguem o mesmo schema e a mesma escala, equipamentos de fabricantes diferentes se encaixam no mesmo painel. Também por isso um coletor de dados consegue alimentar qualquer painel usando só referências `equipamento:porta`.

Antes de criar ou editar JSON, leia `references/schema.md`, que tem o formato completo. Para criar um modelo novo, leia também `references/modelagem.md`, que explica como sair de foto, nome ou descrição para medidas e portas corretas.

## Fluxo de trabalho

### 1. Entenda o pedido

- **Equipamento novo:** gerar um modelo e, normalmente, mostrá-lo num dashboard.
- **Dashboard novo:** montar racks, equipamentos e cabos com modelos existentes ou novos.
- **Alteração:** adicionar equipamento ou cabos, trocar placas ou atualizar estado num dashboard existente.

Procure primeiro uma biblioteca do usuário (uma pasta `models/` no projeto) e a biblioteca da skill (`assets/models/`). Reaproveite modelos que já existem em vez de redesenhá-los, e estenda os que forem parecidos.

### 2. Crie o modelo (quando o equipamento ainda não existe)

Siga `references/modelagem.md`. Em resumo:

- **Nome de modelo:** pesquise o datasheet (dimensões, portas, disposição, numeração).
- **Foto:** escale pela largura de 19" ou pelo tamanho conhecido das portas, conte fileiras e grupos e identifique os tipos de conector.
- **Descrição em texto:** use a disposição mais comum da categoria e registre as suposições.

O que mais importa é quantidade de portas, tipos, ordem física e **ids iguais aos da CLI**. Os ids são a ponte entre o desenho e os dados reais; se eles não baterem, o painel não pode ser alimentado automaticamente. Use `source.confidence` e `source.notes` para dizer o que foi medido e o que foi estimado, porque o usuário precisa saber quanto confiar no desenho.

Salve como `models/<id>.json` na pasta de trabalho do usuário, para que o modelo entre na biblioteca dele.

#### Quando não houver certeza: pergunte ou peça fotos

Um modelo errado que parece certo é pior do que um modelo incompleto. O técnico confia no desenho para achar a porta no rack, e o coletor confia nos ids para alimentar o painel. Por isso, toda dúvida que afeta o resultado precisa chegar ao usuário. Não esconda a dúvida dentro de uma estimativa silenciosa.

**Pergunte ANTES de gerar** quando a dúvida muda o equipamento em si, porque um rascunho baseado num chute errado só gera retrabalho:

- O modelo não foi identificado com segurança: nome ambíguo, fabricante desconhecido ou mais de um produto com nome parecido. Exemplo: "TH3230S" era o A10 Thunder 3230S. Confirme antes de seguir.
- A configuração muda as portas e não foi dita: placas, subcartões ou módulos instalados num chassi modular; versão AC ou DC; variante com outra quantidade de portas.
- Não há nenhuma fonte, nem datasheet nem foto, sobre quantidade e tipo de portas.

Nesses casos, faça uma pergunta curta e objetiva, com as opções que você encontrou, e peça a informação que resolveria.

**Gere um rascunho e pergunte DEPOIS** quando a dúvida é de disposição ou de detalhe. Isso inclui posição das portas no painel, ordem da numeração, traseira, profundidade e cores. Um rascunho já dá ao usuário algo concreto para corrigir. Nesse caso:

1. Marque `source.confidence` como `"baixa"` ou `"média"` e liste cada item incerto em `source.questions` (veja `references/schema.md`). O painel mostra essa lista ao clicar no equipamento, então a dúvida fica junto do desenho.
2. Termine a resposta com um bloco curto **"Para deixar o modelo fiel"**, que diga:
   - **O que está estimado**, item por item, sem esconder nada.
   - **O que enviar**, pedido de forma específica:
     - foto da frente e foto da traseira, de frente e com o equipamento inteiro no quadro;
     - foto da etiqueta, quando o código do modelo for duvidoso;
     - a saída de `display interface brief`, `show interfaces` ou `/interface print` quando os ids da CLI forem incertos;
     - a lista das placas instaladas (`display board`, `show inventory`) em chassis modulares;
     - medidas com trena, quando só a profundidade faltar.
3. Quando a resposta chegar, atualize o modelo no mesmo arquivo e no mesmo `id`, suba a `confidence`, limpe os itens resolvidos de `source.questions` e diga o que mudou.

Não pergunte o que dá para descobrir sozinho, como datasheet, padrões da categoria ou convenções do fabricante. Não transforme dúvidas pequenas num interrogatório: agrupe tudo numa única mensagem.

### 3. Monte o dashboard

Escreva `<nome>.json` com `racks`, `devices`, `links` e o estado das portas (`devices[].ports`). Algumas regras:

- Use ids curtos e estáveis (`olt1`, `dio-a`, `rt1`), porque eles aparecem nas referências dos cabos. Para o `name`, use o hostname do usuário. Se ele não informou, use `<MODELO>-01` e diga isso na resposta.
- Antes de ligar um cabo num dashboard existente, procure a porta em `links[]` para ver se ela já está ocupada. Se estiver, pergunte ao usuário se o cabo antigo deve sair. A validação também acusa porta com dois cabos, mas é melhor não chegar lá.
- Antes de colocar um equipamento num rack, confira os U já ocupados. A validação acusa sobreposição.
- Não precisa copiar os modelos para dentro do dashboard: o build embute automaticamente os que estiverem nas pastas de modelos.
- Cabos ópticos monomodo usam `fiber-sm` (amarelo, como o cordão OS2 real), multimodo usa `fiber-mm` (aqua), cobre usa `cat6`, e assim por diante. A cor certa ajuda o técnico a reconhecer o cabo.
- Sem dados reais, use exemplos plausíveis e avise o usuário que são exemplos. Nunca apresente métricas inventadas como reais.

### 4. Gere o HTML

Escolha a primeira opção que funcionar no ambiente. Os dois scripts procuram modelos nas pastas de `--models`/`-ModelsDir`, em `<pasta do dashboard>/models` e em `assets/models` da skill. Se faltar algum modelo, eles param com erro e não gravam o HTML. Prefira caminhos absolutos.

```bash
python <skill>/scripts/build.py pop.json pop.html --models ./models
```
```powershell
powershell -ExecutionPolicy Bypass -File <skill>\scripts\build.ps1 -Dashboard pop.json -Out pop.html -ModelsDir .\models
```

Sem Python nem PowerShell, copie `assets/template.html`, troque a linha `__ISO3D_DATA__` pelo JSON completo (com os modelos embutidos em `models` e cada `</` escrito como `<\/`) e troque o `<title>`.

### 4b. Escolha a saída: desenho isométrico, 3D real ou draw.io

O mesmo HTML entrega as três visualizações a partir dos mesmos modelos. Escolha pelo que o usuário pediu:

| Pedido | Saída | Como |
|---|---|---|
| Painel, mapa, dashboard (padrão) | **Desenho isométrico** (SVG) | abre assim por padrão; leve, nítido, funciona em qualquer navegador |
| "3D de verdade", "three.js", ver profundidade, apresentar | **3D (three.js)** | botão **3D** na barra, `"mode": "3d"` no JSON do dashboard, ou `#3d` no fim do link do arquivo local |
| "draw.io", "diagrams.net", diagrama editável, documentação 2D | **Arquivo .drawio** | `IsoDash.exportDrawio()` ou o botão **Gerar draw.io / Baixar .drawio** no painel |

- **3D:** o three.js 0.128 é carregado do jsDelivr na hora em que o usuário abre o modo 3D, então é preciso internet. Funciona também em Artifact. Cada face é o mesmo desenho do modo isométrico, aplicado como textura, e cada cabo vira um tubo com o mesmo trajeto. O clique em porta, placa ou cabo abre o mesmo painel lateral.
- **draw.io:** gera um bloco por rack, com uma coluna de frente e outra de traseira. As faces entram como imagem vetorial, cada porta vira um ponto conectável com dica, e cada cabo vira uma ligação ortogonal com a cor do tipo de cabo, tracejada quando está fora. Abre em draw.io, diagrams.net e na extensão do VS Code.
- **Biblioteca do draw.io** (`drawio/iso3d-equipamentos.xml`): paleta com uma peça por face de cada modelo e uma por placa de chassi modular. As peças podem ser arrastadas para montar diagramas do zero, e as portas são pontos de conexão. **Sempre que criar ou alterar um modelo, regenere a biblioteca**, assim:
  1. `scripts/build-catalog.ps1 -Out catalogo.html -ModelsDir <pasta de modelos do usuário>` (ou `python scripts/build.py catalog catalogo.html --models <pasta>`). Isso gera um painel com todos os modelos.
  2. Abra o catálogo com `scripts/serve.ps1` e rode `await fetch('/save?name=iso3d-equipamentos.xml', { method: 'POST', body: await IsoDash.exportDrawioLibrary() })`.
  3. Copie o arquivo para `drawio/`.

  Sem navegador, entregue o `catalogo.html` e peça ao usuário para clicar em **Baixar biblioteca**. No draw.io, a biblioteca abre por *Arquivo › Abrir biblioteca*.
- **Para gravar o .drawio em disco** quando você só tem acesso a um navegador automatizado, suba `scripts/serve.ps1` na pasta do dashboard e rode na página:
  `await fetch('/save?name=<nome>.drawio', { method: 'POST', body: IsoDash.exportDrawio() })`
  O servidor só grava nomes simples terminados em `.drawio`, `.xml`, `.json` ou `.svg`. Sem navegador, entregue o HTML e diga ao usuário para clicar em **Baixar .drawio**. Isso funciona com o arquivo aberto localmente; dentro de um Artifact, o download é bloqueado e o usuário precisa usar **Gerar draw.io** e copiar.

### 5. Confira e entregue

- Abra o HTML se houver um navegador disponível. Para isso, `scripts/serve.ps1 -Root <pasta>` serve a pasta em `http://localhost:8765/`. Confira se não há erros no console e se o chip **"Problemas nos dados"** não aparece: ele lista portas fora da face, cabos para portas inexistentes, U sobreposto e outros problemas. `IsoDash.issues()` retorna a mesma lista.
- Rode `IsoDash.focus("<id do equipamento>")` no console ou por uma ferramenta de JavaScript para enquadrar o equipamento novo, e compare com a foto ou o datasheet: quantidade de portas, lado das portas e fileiras. Num navegador automatizado, a roda do mouse pode não funcionar; `focus` e os botões +/− funcionam.
- Entregue o HTML. Se a ferramenta Artifact estiver disponível, publique e passe o link. Entregue também os JSON, porque eles são a fonte de verdade que o usuário vai versionar e alimentar.
- Diga em uma ou duas linhas o que foi estimado (por exemplo: "profundidade estimada; disposição dos slots 19/20 estilizada").

## Alimentação com dados reais

Os dashboards são estáticos por padrão, com o estado salvo no JSON. Para dados ao vivo, a página expõe `IsoDash.update({ports, links, devices})`, descrito em `references/schema.md`, seção 7. Ao integrar com SNMP, Zabbix, NetBox, a API do NMS ou saídas de CLI, escreva um coletor que produza esse objeto usando os ids de porta da CLI e chame `update` periodicamente. Também é possível regenerar o JSON e rodar o build de novo. Uma página publicada como Artifact não acessa redes externas, então dados ao vivo exigem rodar o HTML localmente ou num servidor interno.

## Por que este formato

- **Milímetros reais** em vez de pixels: equipamentos de origens diferentes se encaixam no mesmo rack sem ajuste manual.
- **Modelo separado de instância:** o mesmo chassi aparece com placas diferentes em cada POP, e uma correção no modelo vale para todos os dashboards.
- **Ids iguais à CLI:** o mapa vira uma camada visual sobre o inventário e a monitoração que já existem, em vez de mais uma planilha para manter.
