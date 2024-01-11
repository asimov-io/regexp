# Description du Projet

Le projet est séparé en deux fichiers, regexp.sk et main.ml et s'articule autour de l'appartenance d'un mot au langage dénoté par une regexp. Le projet résout le problème de reconnaissance d’un mot par une expression rationnelle (telle que définie en théorie des langages) dans un premier temps puis s'étend à certaines features simples du standard POSIX comme le + et le ? mais également de façon plus ambitieuse aux captures et aux références (standardes, imbriquées et anticipées).

# Utilisation

`dune exec regexp` permet d’exécuter les tests dans main.ml.

## Créer un test

Il faut écrire une expression régulière à l’aide de la syntaxe ci-dessous, ainsi qu’un mot sous forme de `string`. Puis il faut appeler la fonction `test` sur ce couple.

### Syntaxe et Sémantique

- `Empty` : $\emptyset$

ne reconnaît rien;
- `Eps` : $\varepsilon$

reconnaît $\varepsilon$
- `Symb s` : $s$

reconnaît $s$
- `Or (e1, e2)` : $(e_1 \mid e_2)$

reconnaît les mots reconnus par $e_1$ et ceux reconnus par $e_2$
- `Dot (e1, e2)` : $(e_1 \cdot e_2)$ ou $e_1 e_2$

reconnaît les mots $w_1 w_2$ où $w_1$ est reconnu par $e_1$ et $w_2$ par $e_2$
- `Star e` : $e^*$

reconnaît les mots $w_1 \dots w_n$ avec $n\geq 0$ où $\forall i \in \llbracket1; n\rrbracket, w_i$ est reconnu par $e$
- `Plus e` : $e^+$

reconnaît les mots $w_1 \dots w_n$ avec $n> 0$ où $\forall i \in \llbracket1; n\rrbracket, w_i$ est reconnu par $e$
- `Exp (e, n)` : $e^n$

reconnaît les mots $w_1 \dots w_n$ où $\forall i \in \llbracket1; n\rrbracket, w_i$ est reconnu par $e$
- `Option e` : $e?$

reconnaît $\varepsilon$ et les mots reconnus par $e$
- `Group e` : $[e]$

reconnaît les mots reconnus par $e$, et le mot reconnu pour la première fois par `Group e` qui est le `r`-ième groupe *dynamiquement* rencontré est capturé en tant que `r`-ième capture
- `Ref r` : $\backslash r$

reconnaît la  (*référence standarde*). Si le $r$-ième groupe a été rencontré mais n’a pas encore reconnu de mot, `Ref r` ne peut rien reconnaître (*référence imbriquée*). Si le $r$-ième groupe n’a pas encore été rencontré, il n’a donc pas encore reconnu de mot et `Ref r` ne peut rien reconnaître (*référence anticipée* ou *référence illégale*).


### Exemples

```
let _ = test (Dot(Or(Group(Symb 'a'), Symb 'c'), Dot(Group(Symb 'b'), Option(Ref 1))), "aba")
```

teste si la regexp $([a] \mid c) [b] (\backslash 1)?$ reconnaît le mot $aba$ et produit le résultat suivant:

```
Reconnu de 1 façon(s):
(L(\1[a])⋅(\2[b]⋅\1"a"))
Groupe 1:
a

Groupe 2:
b
```


Comme les groupes sont rencontrés dynamiquement, un groupe non rencontré n’est pas déclaré et est ignoré par le compteur de groupes. C’est une différence avec la sémantique classique des numéros de capture qui sont normalement calculés statiquement (le `c`-ième groupe est celui dont la parenthèse ouvrante est la `c`-ième).

On avait imaginé deux façons d’avoir la sémantique classique:
- laisser l’utilisateur numéroter les groupes, mais c’est désagréable pour l’utilisateur.

- faire une passe de parsing avant évaluation qui annote les groupes. Une méthode pour faire cela serait d’avoir une fonction qui ne travaille que sur une expression et la parcourt en annotant les groupes. Cela ne nous semblait pas très élégant.


C’est pourquoi avec notre sémantique dynamique, la regexp $([a] \mid c) [b] (\backslash 1)?$ peut aussi reconnaître le mot $cbb$, alors qu’avec la sémantique classique elle ne reconnaît que $\{ab, cb, aba\}$:
```
let _ = test (Dot(Or(Group(Symb 'a'), Symb 'c'), Dot(Group(Symb 'b'), Option(Ref 1))), "cbb")
```
produit le résultat suivant:

```
Reconnu de 1 façon(s):
(R(c)⋅(\1[b]⋅\1"b"))
Groupe 1:
b
```




## Lire un résultat

1. Une ligne indiquant le nombre de façons que l’expression a pour reconnaître le mot. Pour éviter qu’il y ait une infinité de façons pour $(a \mid \varepsilon)^*$ de reconnaître $a$, on empêche la découpe d’un mot à reconnaître par une étoile de générer des $\varepsilon$ (cela enlève $\varepsilon a$, $a\varepsilon \varepsilon, \dots$). Vient ensuite une description de chacune de ces façons accompagnées des captures en résultant.
2. Une façon de reconnaître est décrite par la représentation infixe d’un arbre de découpage, avec les conventions suivantes:

- $\varepsilon$ est reconnu par `Eps`, `Star(_)` et `Option(_)` et produit `ε`

- $s$ est reconnu par `Symb(s)` et produit `s`
- $w$ est reconnu par `Or(e1, e2)` et produit `L(trace)` si $w$ est reconnu par `e1` en produisant `trace`
- $w$ est reconnu par `Or(e1, e2)` et produit `R(trace)` si $w$ est reconnu par `e2` en produisant `trace`
- $w_1 w_2$ est reconnu par `Dot(e1, e2)` et produit `(trace1⋅trace2)` si $w_1$ est reconnu par `e1` en produisant `trace1` et $w_2$ est reconnu par `e2` en produisant `trace2`
- $w_1\dots w_n$ est reconnu par `Star(e)` ou `Plus(e)` ou `Exp(e, n)` et produit `({trace1}␣...␣{tracen})` si $w_i$ est reconnu par `e` en produisant `tracei`
- $w$ est reconnu par `Group(e)` (qui est le `r`-ième groupe rencontré) et produit `\r[trace]` si $w$ est reconnu par `e` (pour la première fois) en produisant `trace`
- $w$ est reconnu par `Ref(r)` et produit `\r"w"` si $w$ est le mot reconnu par le `r`-ième groupe rencontré: *référence standarde*. Si le `r`-ième groupe a été rencontré mais n’a pas encore reconnu de mot, `Ref(r)` ne peut rien reconnaître: *référence imbriquée*. Si le `r`-ième groupe n’a pas encore été rencontré, il n’a donc pas encore reconnu de mot et `Ref(r)` ne peut rien reconnaître: *référence anticipée* ou *référence illégale*.

3. Les captures résultant d’une façon de reconnaître sont décrite par une liste d’associations numéro de groupe/mot capturé.

# Convention de nommage
- symbole (type `symb`): s
- expression (type `expr`): e
- lettre (type `lett`): l
- mot (type `word`): w
- élément de trace (type `tr_elt`): te
- trace (type `trace`): tr
- référence de capture (type `cref`): r
- mapping référence de capture → mot capturé (type `CMap.t`): cm
- prochaine référence de capture (type `cref`): nr
- tas (type `heap`): h
- ? optionnel (type `_ option`): ?o
- entier (type `nat`) : n
- valeur générique (type `a`): v
- valeur augmentée (type `m<?>`): x
- test (type `expr * string`): t

# Expressions rationnelles

## Définition formelle

Étant donné un alphabet fini $\Sigma$, on définit les expressions rationnelles sur cet alphabet ainsi :

$e ::= \emptyset$
    | $\varepsilon$
    | $a, \forall a \in \Sigma$
    | $(e_1 \mid e_2)$
    | $(e_1 \cdot e_2)$
    | $e^*$ 


Et le langage $L(e)$ dénoté par l'expression $e$ de facon inductive:

- $e = \emptyset : L(e) = \emptyset$
- $e = \varepsilon : L(e) = \{\varepsilon\}$
- $e = a : L(e) = \{a\}$
- $e = (e_1 \mid e_2) : L(e) = L(e_1) \cup L(e_2)$
- $e = (e_1 \cdot e_2) : \{w_1w_2 \mid w_1 \in L(e_1)$ et $w_2 \in L(e_2)\}$
- $e = e_0^* : \cup^\infty_{n=0} L(e)^n$


où  $L^0 = \{\varepsilon\}$ et pour $n \geq 1, L^n = L \cdot L^{(n-1)}$

Un mot est reconnu par une expression rationnelle s’il appartient dans le langage dénoté par cette expression.

Ici les symboles des expressions rationnelles et des mots sont les mêmes mais nous avons fait le choix de considérer que les données pouvaient être de types différents pour gagner en généricité. Voyons comment nous avons modélisé ceci.

## Données manipulées

### Côté Skel
- les symboles de l'alphabet de type `symb`

- les expressions régulières de type `expr`
- les lettres des mots de type `lett`
- les mots de type `word`
- la fonction `eval` de type `(expr, word) → result` qui permet de savoir si le mot est dans le langage de l'expression

### Côté OCaml
- les lettres et symboles de type `char`

- les mots de type `lett list`


Nous avons pris le parti d'avoir une fonction `eval` qui réussit son calcul seulement si le mot est dans le langage et échoue (`fail`) sinon.

Initialement la valeur pure du résultat de `eval` était donc de type `()` puisqu'elle ne comporte que l'information d'une réussite, nous avons dû l’étendre en une valeur pure de type `expr` pour gérer les captures comme nous le verrons plus tard.

    result = m<expr>

La monade était au départ la monade identité puis nous lui avons ajouté une trace et un tas pour les extensions.

    m<a> = heap → (a, trace, heap)

Nous justifierons les différentes modifications de valeurs pures et augmentations de monades en temps voulu, concentrons-nous dans un premier temps simplement sur la partie expression rationnelle.

## Fonctions manipulées en skel
Les fonctions manipulées peuvent échouer (`M.fail ()`), par exemple `head eps`.
Cela permet d’ailleurs de représenter un retour "booléen" par `()`: vrai si ça renvoie `()`, faux si ça échoue.

    equal : (symb, lett) → ()
teste l’égalité d’un symbole et d’une lettre

    eps : word
est la constante égale au mot vide

    isempty : word → ()
teste si un mot est vide

    head : word → lett
renvoie la première lettre d'un mot

    tail : word → word
renvoie un mot privé de sa première lettre

    cons : (lett, word) → word
ajoute une lettre en tête d'un mot et le renvoie

    wrdcmp : (word, word) → ()
teste l’égalité de deux mots

    cut_dot : word → (word, word)
coupe un mot en deux de facon non-déterministe

    cut_star : word → (word, word)
coupe un mot en deux de facon non-déterministe, en excluant le cas où la première partie est le mot vide.

## Utilisation

Pour `Or(e1, e2)` on a deux branches pour laisser `eval` choisir non-déterministiquement le côté qui va essayer de reconnaître récursivement le mot.

Pour `Dot(e1, e2)` on a `cut_dot` qui coupe non-déterministiquement le mot en deux et demande à ce que chaque morceau soit reconnu récursivement par `e1`, `e2`.

Pour `Star(e)` on a une branche récursive qui utilise `cut_star` (une variante de `cut_dot` où le premier morceau est non-vide). On demande à ce que le premier morceau soit reconnu récursivement par `e` et que le second (qui reste à découper) soit reconnu récursivement par `Star(e)`. On utilise `cut_star` plutôt que `cut_dot` pour éviter
une boucle infinie introduisant des $\varepsilon$ (`eval (Star(e), w)` appellerait `eval (Star(e), w)`).
En réalité le cas récursif de `Star(e)` appelle une variante de `Star` sur `e` (pour les traces qu’on verra plus tard).
On a aussi une branche cas de base qui ne reconnaît que le mot vide.


# Ajout des traces


## Données manipulées
### Côté Skel
- des éléments de trace de type `tr_elt`
- une trace de type `trace` (un arbre d’éléments de trace)
- la monade augmente une valeur pure avec une trace


### Côté OCaml
- On utilise une fonction `list_of_trace` qui aplatit l’arbre de trace de manière efficace (plutôt que des `@`).
- On utilise `Necromonad.List` pour lister toutes les façons de reconnaître le mot par la regexp. D’ailleurs, comme notre représentation de "non reconnu" est un `M.fail`, il est plus pratique de directement manipuler une liste pour simplement traiter le cas où le mot n’est pas reconnu en matchant `[]`.


## Fonctions manipulées en skel

    log : tr_elt → m<()>
enregistre un élément dans la trace.

## Utilisation

On utilise la fonction `log` dans les branches afin d’enregistrer les choix faits au cours de la reconnaissance.

Pour `Star(e)`, on s’attend à ce que la trace affiche des parenthèses autour d’une succession d’accolades pour distinguer les façons pour, par exemple, $a^* \cdot a^*$ de reconnaître $aaa$.

Il faut donc ajouter un constructeur d’expression qui n’apparaît pas dans la sémantique: `StarLight(e)`. Il a les mêmes deux branches que `Star(e)`, mais ne produit pas de parenthèses autour de ce qui est reconnu. On modifie donc la branche récursive de `Star` qui appelle en fait `StarLight` au lieu de `Star`.

# Ajout des captures

## Côté Skel

- des entiers de type `nat` (pour les itérées)
- des identifiants de capture de type `cref`
- un tas de type `heap` (qui associe un mot à chaque référence de capture)
- la monade augmente une valeur pure en une fonction prenant un tas en argument et renvoyant un tas (en plus de la valeur pure et de la trace): `m<a> = heap → (a, trace, heap)`
- les valeurs pures manipulées sont des `expr` (au lieu des `()` qui suffisaient pour une valeur booléenne jusqu’alors).

## Côté OCaml

Le tas est un objet `(cm, nr)` de type `(word option) CMap.t * cref`. L'idée est que l'on a toujours accès à la prochaine adresse libre `nc`, mise à jour à chaque fois qu'on la déclare dans le tas. Les éléments mappés sont des `word option` car on peut ne pas associer la capture d’un groupe à sa référence de capture juste après la déclaration de ce groupe, ce qui aura un intérêt dans le cas des références anticipées et imbriquées.

## Fonctions manipulées en skel

    empty_heap : heap

est la constante égale au tas vide

    alloc : heap → (cref, heap)

déclare un nouveau groupe

    set : (cref, word, heap) → heap

associe la capture d’un groupe (type `word`) à sa référence de capture (type `cref`)

    get : (cref, heap) → word

récupère le contenu d’une capture

    newref () → m<cref>

encapsule `alloc` et renvoie la capture nouvellement crée

    setref (cref, word) → m<()>

encapsule `set` et propage ses arguments

    getref (cref) → m<word>

encapsule `get` et renvoie la valeur récupérée.

## Utilisation

Une valeur augmentée prend et renvoie un tas car les captures sont globales au sein d’une expression.

Les valeurs contiennent une `expr` qui permet de consommer les constructeurs `Group`: une fois qu’un groupe a été rencontré, on lui alloue une référence qui se tient à disposition pour faire une capture, mais on ne veut pas réallouer une référence la prochaine fois qu’on le rencontrera.

Plus précisément, `Group e` jette `Group` et ne propage que `e`; les autres propagent. Il faut cependant que les `StarLight` redeviennent des `Star` à la fin (au cas de base) pour que quand on repasse dessus (dans le cas $(a^*)^*$ par exemple) ce soient toujours des `Star` et non des `StarLight` pour bien avoir les parenthèses.