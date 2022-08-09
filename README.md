# Taxonomy Annotator

The "Taxonomy Annotator" is a crowd based human-in-the-loop application for producing training data. The user annotates word-pairs with their potential relation type like "synonym", "antonym", "hypernym", and the annotations are written into a central database. Afterwards a machine learning model can be trained for predicting relations by itself.\
\
Try it out! https://www.annotator-capstone.ml

\
In the UI start with loading a word-embedding - then the current annotations-history under *Annotations* - and generate its graph in the same dropdown-menu.
\
Afterwards you can continue to produce your own annotations by writing new terms and link them by holding left-click and draging a line. To annotate the relation type, just right-click the now created edge, or press one of the fields at the bottom-bar.

A more detailed explanation of the application, you can find below in the manual.

</br>

## AWS - Architecture
This web application is hosted in the AWS Cloud. Here you can see the setup of the corresponding cloud-services:

![Overview](img/3d-nogrid.png)

</br>

## Manual

### 1. Load word-embeddings
First choose a word embedding (currently only an english embedding is installed by default, so either selection will trigger loading an english embedding). Afterwards hit the *Load* button and the respective 
embedding will be loaded into the application. While loading, all vectors are normalized to **L2 norm**.
If you load your own model, it will be indexed  by the nmslib module automatically.

### 2. Add new words
With a word-embedding initialized, you can start to build a graph. Provide new terms with the 
text input field. The app will accept only words that are contained in the loaded embedding. 
Alternatively, you can generate some random terms by double-clicking anywhere on 
the canvas. A selected word can be removed from the graph anytime by hitting remove/delete, or with 
the context-menu on right-clicking the word. Note that you can re-position all nodes & links in the
graph by dragging them while holding ctrl.

### 3. Annotating word-pairs
For the later-on learning process, relation types have to be annotated between two words first. Therefore,
drag an enge between two words. A dashed grey edge is indicating no relation yet. For annotating the link, 
open the context-menu by right-clicking the link and chose the respective relation-type in *Annotate*.
An alternative, and probably the smoother option, is just pressing one of the respective relation fields
at the bottom-bar.\
Currently, the app supports the distinction of eight different relation types:

| Type          | Semantic             | Example             |
|---------------|----------------------|---------------------|
| Synonym       | same                 | sick - ill          |
| Antonym       | different            | good - bad          |
| Hypernym      | superordinate        | tulip - flower      |
| Hyponym       | subordinate          | plant - flower      |
| Cohyponym     | shared hypernym      | man - woman (human) |
| Meronym       | part of              | tree - bark         |
| Holonym       | entire               | tree - forest       |
| Troponym      | generalization       | spin - move         |

Relations can be further categorized in **directed** and **undirected** relations, indicated by an arrowed or 
non-arrowed edge in the graph. Whereas Synonyms, Antonyms and Cohyponyms have no direction, the other relation types represent some semantic ordering.

Because there is no definition of a relation in the appliation before the learning process, you can 
in fact introduce an own relation type and treat it as one of the above relations. Just make sure to
be consistent when annotating over the whole process.

### 4. Annotation History
Whenever word-pairs are annotated these information is written into the termorary history file, which you can find under *Anotations* - *Show History*. Here you can also edit the currently made annotations. With *Load History* you can obtain all annotations produced by all users so far from the central repository. Don't hasitate to use *Save New Relations*. Regardless of the shown state of the temporary
history-file, you can't delete annotations from the central repository accidentally. Only so far not recorded annotations can be added there.\
Further, in the process of recording annotations, the app prevents duplicate annotations and x - y annotations of undirected relations, if an y - x annotation is already present.

### 5. Basic operations
Generate the **Nearest Neighbors** of a word by right-clicking a word and selecting the respective 
option. The **query-result window** will pop up, showing the respective terms ordered by their cosine-
similarities. With selecting a word from the result, it will be integrated into the graph. The 
**query-result size** can be changed from 1 - 20 anytime at the top bar.\
\
The other basic operation are **Analogies**. Here you just have to select three different words 
successively in a semantic order and choose the analogy operation from the context-menu. E.g. selecting 
the words Germany - Berlin - China after another, should ideally generate some chinese cities, in best 
case Peking since it's the capital like Berlin. The mathematical vector operation done here is
```console
word_2 - word_1 + word_3
```
For the resulting vector, the app then shows the nearest neighbors in the vector space.

### 6. Learning & Predicting
Whith annotating word-pairs, training data is created in form of json
```console
{"x":"word_1","y":"word_2","relation":"relation-type"}
```
and is collected in a temporary batch. With opening the *Learing* panel you can see how many annotations have been collected so far for every relation type. Based on their count you can adjust the **learning-rate** and the number of **iterations** and train the respective relation by selecting it.\
Note that there can be several annotations for a word-pair. For example, some might annotate cat - dog 
as an Antonym and then annotate it as a Cohyponym (sharing Hypernym 'mammal'). Both would make sense
and so both annotations are integrated into the training-batch, while showing only the last annotation
in the graph.\
However, the system detects if a word-pair was already annotated with the same relation in the past 
and won't add it to the training data. Also, for non-directed relations the annotation word_1 - word_2
won't be considered for training, if the annotation word_2 - word_1 is already present for this relation.

When learning the annotations for a specific relation type, or the whole batch at once, the respective data
is cleared from the batch afterwards, allowing to add any kind of annotations again. You can also clear the 
batch manually in the *Learning* panel anytime.

The learning process used here is based on 
[Learning Semantic Hierarchies via Word Embeddings](https://www.researchgate.net/publication/270877882_Learning_Semantic_Hierarchies_via_Word_Embeddings).
For every relation-type a **Projection Matrix Φ** is initialized with normal distribution of zero and std 0.1.
With the provided training-data, the mean square error of
```console
x Φ - y
```
is minimized, making it a linear regression problem. Here x and y are the word-vectors of the terms in 
the annotation, and Φ the respective projection matrix to be trained. For optimization a SGD algorithm for 
matrices is being used.

To predict related terms for a word, choose *Find Related Term* from the context-menu on a node. The 
dot-product of the given word and the projection matrix for the chosen relation is then being calculated. 
For the resulting vector the nearest neighbors are queried and presented.\
If there is a match in the result-set, select this word and it will be integrated into the graph with the 
corresponding relation. If there are no matching words, click so in the result-window. Either
way, the precision of predictions is maintained, based on your selection, in the relation fields at the 
bottom.

To predict a relation type given a word-pair, open the context-menu of the link between two words and 
select *Find Relation*. The dot-product of the two word-vectors is calculated and the resulting matrix is 
being matched with the existing projection matrices for overall error. The result is the best matching 
relation-type with the overall error. Selecting the relation from the result-window will colour the 
corresponding link, but have no effect on the precisions in the bottom fields.

All matrices can be reset anytime in the *Learning* panel, re-initializing them with a new normal distribution.
By doing so, the precisions of predictions so far, will be reset as well.


### 7. Projection deltas
The application can visualize the adaptation of a projection-matrix being made during training. Therefore the
deltas of a relation matrix are calculated with regard to it's initialized values. The outcome is a heatmap 
that can be seen under *Projections*.\
The hypothesis here is that a specific relation-matrix is getting specialized on some areas in the vector-space, 
indicating it by a shift of it's values during training. For this observation, however, there must be sufficient 
and appropriate training data available.



## Copyright
Copyright (c) 2022 Alexander Klassen.

