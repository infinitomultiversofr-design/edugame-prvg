# 08 — Avatar Lab, 8 Famílias e Coleção de 200 Animais

## Princípio
Animal primeiro. Roupa adapta-se ao animal.

Não usar “corpo humano padrão + cabeça de animal” como solução universal.

## 8 famílias anatômicas

### F01 Ágil
Canídeos/felinos e corpos médios esguios.

### F02 Robusto
Capivara, anta, urso, queixada etc.

### F03 Compacto
Micos, saguis, pequenos mamíferos, tatu, coelho.

### F04 Longilíneo
Tamanduás, primatas longos, canguru etc.

### F05 Ungulado
Veados, cervos, cavalo, zebra, cabra.

### F06 Ave
Araras, tucanos, corujas, ema etc. Asas permanecem asas.

### F07 Réptil/Anfíbio
Jacaré, teiú, iguana, sapos, serpentes adaptadas.

### F08 Aquático
Botos, grandes aquáticos e formas hidrodinâmicas.

## Anatomia por espécie
Cada espécie tem:
- family_id;
- height_profile;
- torso_profile;
- head_profile;
- eye_anchor;
- ear anchors;
- muzzle/beak;
- neck;
- arm/wing profile;
- leg profile;
- foot type;
- tail type;
- horns;
- crest;
- special flags.

## Âncoras universais
- head_top
- forehead
- eyes
- ear_left
- ear_right
- neck
- chest
- back
- shoulder_left/right
- wrist_left/right
- hand_left/right
- waist
- hip
- foot_left/right
- tail_root
- wing_left/right
- companion_left/right

## Camadas visuais
1. fundo
2. aura traseira
3. cauda/asa traseira
4. corpo
5. parte inferior
6. roupa superior
7. calçado/adaptação de pé
8. cabeça
9. características naturais frontais
10. óculos/chapéu/brincos
11. item especial
12. Pet
13. efeitos frontais
14. HUD

## Estratégia de roupa universal
Um item é um único produto lógico.

Render:
1. procurar variante específica da família;
2. se não houver, usar variante universal com anchors/scale;
3. se anatomia exigir, usar adaptação equivalente;
4. marcar incompatível apenas em último caso.

Exemplo:
“ tênis neon ”:
- pata: proteção de pata;
- casco: proteção de casco;
- ave: proteção de garra;
- aquático: acessório equivalente compatível.

O estudante continua possuindo o mesmo item.

## Categorias
- animal;
- cor/padrão;
- roupa superior;
- parte inferior;
- calçado;
- cabeça;
- olhos;
- orelhas;
- pescoço;
- pulso;
- costas;
- item especial;
- fundo;
- aura/efeito;
- Pet.

## Acessórios especiais
Devem ser autorais.
Arquétipos permitidos:
- cajado estelar;
- tridente oceânico original;
- bastão lunar original;
- orbe astral;
- livro holográfico;
- drone;
- cubo de energia;
- pingente de terceiro olho;
- visor;
- asas tecnológicas.

Não usar nomes, formas ou símbolos que copiem franquias.

## Evolução visual
Presets, não novas espécies:
1. Natural
2. Estudante
3. Especialista
4. Tech
5. Etéreo

## Bestiário educativo
Cada espécie pode ter ficha:
- nome popular;
- bioma/origem;
- alimentação;
- papel ecológico;
- curiosidade;
- conservação quando apropriado.

A ficha é conteúdo educativo; não transforma espécie em “mais valiosa” por raridade.

## Raridade
Raridade pertence ao item/visual, não ao valor da espécie.

## Catálogo
Lista oficial em `data/animal_species_200.csv`.

## Implementação por ondas
8 animais (1/família) → 24 → 48 → 100 → 200.

Não produzir 200 antes de validar o motor em 8.
