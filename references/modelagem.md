# Como modelar um equipamento a partir da entrada

O objetivo é um modelo que **qualquer técnico reconheça olhando para o painel**. Isso exige proporções e quantidade de portas corretas, numeração idêntica à da CLI e a mesma disposição física (portas à esquerda ou à direita, em 1 ou 2 fileiras, frente ou traseira). Detalhes estéticos, como o formato exato de um logo, importam pouco.

## Sumário
1. Entrada: nome de modelo
2. Entrada: foto
3. Entrada: descrição em texto
4. Medidas de referência
5. Convenções de nomes de porta por fabricante
6. Chassis modulares
7. Checklist antes de entregar

---

## 1. Entrada: nome de modelo ("Huawei MA5800-X7", "MikroTik CCR2004-1G-12S+2XS")

1. **Pesquise o datasheet ou o manual de hardware** com WebSearch/WebFetch, quando disponíveis. Procure:
   - dimensões L × A × P em mm, sem as orelhas de rack;
   - altura em U;
   - lista de portas da frente e da traseira, com tipo, quantidade e velocidade;
   - foto ou desenho frontal, para ver a ordem das portas, as fileiras e a posição de console e LEDs;
   - para chassis: número de slots, numeração, orientação das placas (vertical ou horizontal) e placas comuns com suas portas.
2. Se não der para pesquisar, use o que você sabe e marque `source.confidence` como `"média"` ou `"baixa"`, dizendo nas `notes` o que foi estimado.
3. Use o `id` em kebab-case com fabricante e modelo, como `mikrotik-ccr2004-1g-12s-2xs`. Salve como `models/<id>.json`.

## 2. Entrada: foto

1. **Escale pela largura.** A frente de um equipamento 19" sem orelhas tem cerca de 440 mm (com orelhas, 482,6 mm). Meça a largura em pixels e calcule mm por pixel. Se não houver equipamento 19" na foto, escale por uma porta conhecida: um RJ45 tem cerca de 11,7 mm e um SFP cerca de 13,7 mm de largura.
2. **Conte as portas fileira por fileira.** Anote grupos (blocos de 4, 6, 8 ou 12), espaços entre grupos e a numeração serigrafada, se estiver legível.
3. **Identifique os tipos pelo formato:**
   - RJ45: abertura retangular com a trava embaixo;
   - SFP/SFP+: gaiola metálica estreita;
   - QSFP: gaiola mais larga;
   - SC: quadrado, azul (UPC) ou verde (APC);
   - LC: pequeno, geralmente em pares.
4. **Corrija a perspectiva.** Uma foto em ângulo encurta a dimensão que está inclinada. Use as portas, que têm tamanho conhecido, para reconstruir a escala de cada eixo.
5. A profundidade não aparece numa foto frontal. Use a profundidade típica da categoria (seção 4) ou o datasheet.
6. Em `source.basis`, inclua `"photo"` e descreva nas `notes` o que ficou ilegível.

## 3. Entrada: descrição em texto ("switch 1U com 48 portas gigabit e 4 SFP+ à direita")

Monte a disposição mais comum da categoria:

- **Switches de acesso:** RJ45 em 2 fileiras (ímpar em cima), blocos de 12, SFP à direita, console à direita ou na traseira.
- **Roteadores 1U:** portas ópticas no centro ou à direita, gerência e console à esquerda ou à direita.
- **Patch panels e DIOs:** 24 ou 48 posições em 1 ou 2 fileiras, numeradas da esquerda para a direita e de cima para baixo.

Pergunte ao usuário antes de gerar o que muda o equipamento e não dá para inferir, como a quantidade de portas quando ela não foi dita. Para o resto, assuma o padrão de mercado, registre em `source.questions` e peça confirmação ao final, como explica o SKILL.md na seção "Quando não houver certeza".

## 4. Medidas de referência

- 1U = 44,45 mm. Larguras do corpo: 19" ≈ 440 mm, 23" ≈ 540 mm (padrão ETSI ≈ 500 a 535 mm).
- Profundidades típicas:

  | Equipamento | Profundidade |
  |---|---|
  | DIO / patch panel | 100 a 250 mm |
  | Switch de acesso | 220 a 300 mm |
  | Roteador 1U | 250 a 450 mm |
  | OLT chassi | 240 a 300 mm |
  | Servidor | 600 a 780 mm |
  | Nobreak de rack | 450 a 650 mm |
  | ONU/CPE de mesa | 100 a 180 mm, com 150 a 220 mm de largura e 25 a 40 mm de altura |

- Rack: 600 mm de largura × 800 a 1200 mm de profundidade. Use `width: 600, depth: 1000` quando não souber.
- Margens: deixe de 6 a 10 mm entre a borda da face e a primeira porta, e pelo menos 2 mm entre portas.

## 5. Convenções de nomes de porta (o `id` deve bater com a CLI)

| Fabricante / linha | Exemplo de `id` |
|---|---|
| Huawei OLT (MA56xx/MA58xx) | placa: `{slot}/{porta}` com `portLabel: "0/{slot}/{port}"` (frame/slot/porta) |
| Huawei VRP (switch/roteador) | `GE0/0/1`, `XGE0/0/1`, `100GE0/0/1` |
| ZTE OLT (C300/C600) | `gpon-olt_1/{slot}/{porta}` via `portLabel: "gpon-olt_1/{slot}/{port}"` |
| Nokia ISAM/Lightspan | `1/1/{slot}/{porta}` |
| Fiberhome AN5516 | `{slot}/{porta}` |
| Cisco IOS/IOS-XE | `Gi1/0/1`, `Te1/1/1` |
| Cisco IOS-XR / Juniper | `Hu0/0/0/0` / `xe-0/0/0`, `ge-0/0/0`, `et-0/0/0` |
| MikroTik | `ether1`, `sfp-sfpplus1`, `sfp28-1`, `qsfpplus1-1`. Gaiolas empilhadas em 1U (CCR, CRS): ímpar em cima e par embaixo, em blocos separados por um espaço; as portas de maior velocidade ficam à direita |
| Datacom DmOS | `gigabit-ethernet-1/1/1`, `ten-gigabit-ethernet-1/1/1` |
| Linux / servidor | `eno1`, `ens1f0`, `bmc` |
| DIO / patch panel | `1` … `48` (ou `A1` … `B24`, se o painel for assim) |

Na dúvida, use o nome que aparece em `show interfaces` ou `display interface brief`, porque é ele que o coletor de dados vai usar. Quando a serigrafia da porta for diferente do id da CLI, ponha a serigrafia em `short` (veja schema.md, seção 4).

## 6. Chassis modulares (OLT, roteadores de chassi, DWDM)

- Modele **slots** com a geometria física real (largura, altura, orientação), usando a numeração do fabricante.
- Modele em `cards` as placas mais comuns daquele chassi, com portas relativas ao slot. As placas instaladas ficam em `devices[].cards` no dashboard.
- Placas de controle, fonte e ventilação também entram, para que o desenho fique fiel, mesmo sem portas de dados.
- Se a disposição física exata for incerta, como slots meia-altura empilhados, prefira uma disposição plausível e documentada nas `notes` a inventar detalhes.

## 7. Checklist antes de entregar

- [ ] `size` em mm, coerente com a altura em U (h ≈ U × 44,45).
- [ ] Toda porta cabe na face: x + w ≤ largura da face e y + h ≤ altura da face.
- [ ] Nenhuma porta se sobrepõe a outra (confira o passo e as fileiras).
- [ ] `id` das portas único no modelo (ou na placa) e igual ao nome da CLI.
- [ ] Portas da traseira com `"face": "rear"`, como fontes, gerência de servidores e portas traseiras de switches.
- [ ] `source` preenchido com o que foi medido e o que foi estimado.
- [ ] Cada item estimado que o usuário pode confirmar está em `source.questions`, e a resposta termina pedindo as fotos ou informações que resolvem esses itens.
- [ ] Depois do build, o painel não mostra o chip "Problemas nos dados", ou os avisos restantes são intencionais.
