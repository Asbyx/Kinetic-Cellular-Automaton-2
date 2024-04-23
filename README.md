# KCA2, Or Kinetic Cellular Automaton 2
Statut actuel: c'est une simulation de particule physique dans laquelle il existe de liens entre les particules. Ces liens définissent le neighborhood d'un cellular automaton qui tourne derrière, appelé le informational layer.  

# Particules
`class C`.  
Simples particules flottantes et soumises à un frottement cinétique. Chacune possède son propre informational layer.

# Liens
`class Link`
Liens qui lient les particules. Il agit comme un ressort tel que: 
- le coefficient est constant et le même pour toutes les particules
- la longueur au repos est la moyenne des 2 longueurs au repos donnés par les particules

# Informational layer
`class Information_layer`
L'idée est d'avoir un layer qui ne dépend pas à 100% de la simulation physique mais qui influe dessus.
Donc avoir de la transmission d'information non physique (i.e qui ne dépend pas de la simulation, qui se passe en arrière plan), mais qui influe quand même après sur la simulation.

Pour le moment cet impact est modélisé par le fait que la longueur au repos du lien entre 2 particules dépend de l'état informationel des particules.
Par exemple, si l'état de la particule est "rouge", elle va donner une longueur au repos de 4, alors que si l'état est "vert", elle donnera une longueur de 10.

Pour gérer les changements d'états, l'informational layer utilise un Process, décrit en dessous.

# Process
`abstract class Process`
Un process est la partie du traitement de l'information contenue dans l'informational layer. C'est la partie "cellular automaton".   
Un process définit l'état de la particule et lui permet d'agir sur la simulation.

On peut voir le process comme une boite noire qui prend en input le neighborhood de la cellule et, si on veut, qq données de la simulation physique, et va définir le prochain state de l'informational layer et agir sur la simulation.
C'est l'équivalent des règles d'un cellular automaton.

Par exemple, le NaiveVote_ClockMap_TLMap est un process qui prend en input les states des particules du neighborhood (i.e les particules connectées par des liens), l'état actuel de la particule et un clock, et va output un nouvel état pour la particule, ainsi qu'une longueur de repose pour les liens.  
Il le fait via un système de vote: chaque particule du neighborhood vote pour son état, la clock vote pour un état, puis l'état le plus représenté devient le nouvel état de la cellule. La longueur au repos des liens est défini par l'état actuel de la cellule.