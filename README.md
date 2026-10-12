# equipamento-3d-isometrico

Skill para Claude que transforma equipamentos de rede, telecom e datacenter em modelos padronizados. O equipamento pode ser informado pelo **nome do modelo**, por uma **foto** ou por uma **descrição**. Com esses modelos, a skill monta dashboards de racks e cabos com três saídas:

- **Desenho isométrico** (SVG): painel interativo com rotação, zoom, clique em portas, placas e cabos, edição de conexões e tabela de portas.
- **3D real** (three.js): caixas com as faces desenhadas, cabos em tubo, câmera orbital e o mesmo painel lateral.
- **draw.io** (`.drawio`): diagrama 2D editável com frente e traseira de cada rack, portas conectáveis e cabos coloridos pelo tipo.

Os modelos usam medidas reais em milímetros e ids de porta iguais aos da CLI do fabricante (`0/1/3`, `xe-0/0/0`, `Port1`…). Por isso equipamentos de fabricantes diferentes se encaixam no mesmo rack, e o painel pode ser alimentado com dados reais (SNMP, Zabbix, NMS) por `IsoDash.update(...)`.

## Biblioteca para o draw.io

O arquivo [`drawio/iso3d-equipamentos.xml`](drawio/iso3d-equipamentos.xml) é uma biblioteca de formas do draw.io com todos os modelos de `assets/models/`:

- **frente e traseira** de cada equipamento, como imagem vetorial em escala real (1 px = 1 mm);
- **placas** dos chassis modulares (MA5600T, NE8000 M4) como peças separadas, que se encaixam nos slots;
- **portas** como pontos de conexão (atributos `porta`, `tipo`, `modelo`), para ligar cabos diretamente nelas.

Para usar no draw.io (app.diagrams.net, desktop ou extensão do VS Code), baixe o arquivo e abra em **Arquivo › Abrir biblioteca › Dispositivo**. A paleta aparece na lateral esquerda. Como o repositório é privado, o link do GitHub não abre direto no draw.io: use o arquivo baixado.

Para regenerar depois de criar ou alterar modelos:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build-catalog.ps1 -Out catalogo.html
# abra catalogo.html, painel lateral › Importar / exportar dados › Baixar biblioteca
```

## Estrutura

```
SKILL.md                 instruções da skill (fluxo, quando perguntar, saídas)
references/schema.md     formato dos modelos e dashboards (iso3d v1) e API IsoDash
references/modelagem.md  como sair de nome, foto ou descrição para um modelo fiel
assets/template.html     motor (SVG + three.js + exportação draw.io), num único HTML
assets/models/           biblioteca de modelos
assets/exemplo-pop.json  dashboard de exemplo (2 racks, OLT, DIOs, borda, switch, servidor)
scripts/build.ps1        monta o HTML a partir de um dashboard (Windows / PowerShell)
scripts/build.py         o mesmo em Python
scripts/build-catalog.ps1 catálogo com todos os modelos (base para a biblioteca do draw.io)
scripts/serve.ps1        servidor local para pré-visualizar e salvar exportações
drawio/iso3d-equipamentos.xml  biblioteca de formas do draw.io gerada a partir dos modelos
```

## Uso rápido

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build.ps1 -Dashboard assets\exemplo-pop.json -Out exemplo.html
```

```bash
python scripts/build.py assets/exemplo-pop.json exemplo.html
```

Abra o `exemplo.html` no navegador. O botão **3D** abre a visualização em three.js, que precisa de internet para carregar a biblioteca. Para o draw.io, vá ao painel lateral, abra **Importar / exportar dados** e use **Baixar .drawio**.

## Biblioteca de modelos

| Modelo | Confiança |
|---|---|
| Huawei SmartAX MA5600T (OLT, chassi com placas GPFD/GPBD/SCUN/X2CS/PRTE) | média |
| Huawei NetEngine 8000 M4 (DC) | baixa |
| MikroTik CSS326-24G-2S+RM | alta |
| MikroTik CCR2004-1G-12S+2XS | média |
| A10 Networks Thunder 3230S | média |
| Dell PowerEdge R610 + Intel X710-DA4 | baixa |
| FAG Patch Panel Gigabit PoE 12 portas | média |
| DIO 1U 48 SC/APC, roteador 1U, switch 1U 24p, servidor 2U (genéricos) | média/baixa |

Cada modelo registra em `source` o que foi medido e o que foi estimado. As dúvidas em aberto ficam em `source.questions`, e o painel as mostra ao clicar no equipamento.

## Instalação no Claude

Compacte esta pasta como `.skill` (zip com a pasta `equipamento-3d-isometrico/` na raiz) e instale pelo Claude. Outra opção é copiar a pasta para `~/.claude/skills/` (Claude Code).
