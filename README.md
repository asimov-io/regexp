

# Description du Projet
Le projet est séparé en deux fichiers, regexp.sk et main.ml et s'articule autour de l'appartenance d'un mot au langage denoté par une expressionn rationnelle. Le projet montre la sémantique du matching à une expression régulière simple (telle que définie en théorie des langages) dans un premier temps puis s'étend à certaines features simples du standard POSIX comme le + et le ? mais également des extensions plus ambitieuses comme les itérées (^n) et les captures.

# Expressions rationnelles

## Premier modèle

Étant donné un alphabet fini $\Sigma$, on définit les expressions rationnelles sur cet alphabet ainsi :

e ::= $\emptyset$
    | $\epsilon$
    | $a, \forall a \in \Sigma$
    | $(e1 \mid e2)$
    | $(e1 \cdot e2)$
    | $e^*$ 


Et le langage L(e) dénoté par l'expression e de facon inductive :

- e = \emptyset : L(e) = \emptyset
- e = ε : L(e) = {""}
- e = a : L(e) = {"a"}
- e = (e1 | e2) : L(e) = L(e1) U L(e2)
- e = e1 • e2 : {w1w2 | w1 ∈ L(e1) et w2 ∈ L(e2)}
- e = e0* : U L(e)^n


où  $L^0 = \{""\}$ et pour $n >= 1, L^n = L • L^{(n-1)}$

Ici les symboles des expressions rationnelles et des mots sont les mêmes mais nous avons fait le choix de considérer que les données pouvaient être de type différent pour gagner en généricité. Montrons comment nous avons modéliser ceci :

## Données manipulées et principe

    - les expressions régulières : expr
    - définies à partir des symboles d'un alphabet : symb

    - les mots : word
    - définis à partir de lettres : lett

    - la fonction eval de type (expr, word) → result qui permet de savoir si le mot est dans le langage de l'expression

Le parti pris que nous avons choisi est d'avoir une fonction eval qui réussit son calcul seulement si le mot est dans la langage et échoue (fail) sinon. Initialement la valeur pure du résultat de eval était donc de type unit puisqu'elle ne comporte que l'information d'une réussite, nous avons dû la modifier plus tard en une valeur pûre de type (expr, word) pour gérer les captures comme nous le verrons plus tard.

    - result = m<(expr, word)>

La monade était au départ la monade identité puis nous lui avons ajouté une trace et un tas pour les extensions.

    - m<a> = heap → (a, trace, heap)

Nous justifierons les différentes modifications de valeurs pûres et augmentations de monades en temps voulu, concentrons dans un premier temps simplement sur la partie expression rationnelle.

## Fonctions manipulées en skel

## Utils

    - lett_of_symb : symb → lett     renvoie la lettre correspondant à un symbole
    - equal : (symb, lett) → ()      réussit si symb et lettre sont égales, échoue sinon

    - eps : word                     est la constante égale au mot vide
    - isempty : word → ()            réussit si le mot est vide, échoue sinon
    - head : word → lett             renvoie la première lettre d'un mot
    - tail : word → word             renvoie le mot privé de sa première lettre
    - cons : (lett, word) → word     ajoute une lettre en tête d'un mot et le renvoie 
    - wrdcmp : (word, word) → ()     réussit si les deux mots sont les mêmes, échoue sinon

    - cut_dot : word → (word, word)  coupe un mot en deux de facon non-déterministe
    - cut_star : word → (word, word) coupe un mot en deux de facon non-déterministe, le cas où la première partie est le mot vide est exclu, cela permet de ne pas boucler indéfiniment lorsqu'on essaye de matcher une étoile

# Ajout des traces

## Côté Skel

    - la trace du matching : trace
    - définie à partir d'unités atomiques : tr_elt

## Utils

# Ajout des captures et autres extensions du standard POSIX

## Côté Skel

    - des entiers : nat (pour les itérées)

    - des identifiants de capture : cap
    - un tas : heap (qui associe un mot à chaque identifiant de capture)

## Côté OCaml

    Le tas est un objet (h, nc) de type (word option) IMap.t * cap. L'idée est que l'on a toujours a toujours accès à la prochaine adresse libre nc, mise à jour à chaque fois qu'on la déclare dans le tas. Les éléments mappés sont des word option car on peut déclarer une capture sans l'initialiser, cela aura un intérêt dans le cas des références anticipées et imbriquées.

## Utils

    - empty_heap : heap
    - alloc : heap → (cap, heap)
    - set : (cap, word, heap) → heap
    - get : (cap, heap) → word

    - newcap () → m<cap>
    - setcap (cap, expr, word) → result
    - getcap (cap, expr) → result

# Convention de nommage
- lettre (type lett): l
- symbole (type symb): s
- expression (type expr): e
- trace element (type tr_elt): te
- traces (type trace): tr
- capture (type cap): c
- capture map (type CMap.t): cm
- next capture (type cap): nc
- tas (type heap): h
- option (type a option): ?o
- valeur générique (type a): v
- valeur spécifique (type word): w
- valeur augmentée: x
- test (type expr * string): t
- nat : n