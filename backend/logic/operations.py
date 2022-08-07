from logic import vectors as v, learning as lrn, load as l
import numpy as np
import time
import nmslib
import random
import json
import boto3



'''
This is the operational interface for all services provided by flask functions.
'''


'''Word-embedding, vocabulary, dimensions, index, training-data-container'''
words, voc, dims, index = None, None, None, None
trainData = {}

'''DynamoDB'''
annotations_table_name = "annotations"
dynamodb_resource = boto3.resource("dynamodb", region_name='eu-central-1')
annotations_table = dynamodb_resource.Table(annotations_table_name)



def load_embedding(dir):
    '''
    Loads embedding and initializes words with respective vectors,
    builds vocabulary of all words and chooses respective dimension.
    '''
    global words, voc, dims
    words, voc, dims = l.load_embedding(dir)
    lrn.reset_matrices(dims)



def load_index(dir):
    '''
    Loads existing index of default german, or english embedding.
    '''
    start = time.time()
    global index
    index = nmslib.init(method='hnsw', space='cosinesimil', data_type=nmslib.DataType.DENSE_VECTOR)
    index.loadIndex(dir)
    print(time.time() - start)



def create_index():
    '''
    Creates index for custom embedding with hnsw mode and cosine similarity.
    '''
    start = time.time()
    global index
    index = nmslib.init(method='hnsw', space='cosinesimil', data_type=nmslib.DataType.DENSE_VECTOR)
    i = 0
    for w in words:
        index.addDataPoint(i, w.vector)
        i += 1
    index.createIndex({}, print_progress=True)
    print(time.time() - start)



def save_idex(dir):
    '''
    Saves index of custom embedding.
    '''
    start = time.time()
    index.saveIndex(dir)
    print(time.time() - start)



def get_random_term(terms):
    '''
    A random word is chosen from vucabulary, as long it doesn't already exists in graph.
    '''
    while True:
        term = voc.get(random.randint(0,len(voc)-1))
        # if term[0].isupper() and term not in terms:
        # term = re.sub('[^A-Za-z0-9]+', '', term)
        if term not in terms:
            return term



def get_avg_term(terms):
    '''
    Based on existing terms in graph, an average is calculated and most similar words are returned.
    '''
    avg = np.zeros(dims)
    for t in terms:
        base_word = find_word(t)
        base_vector = base_word.vector
        avg += base_vector
    avg /= len(terms)
    result = most_similar(avg, 10)
    for k,v in result:
        if k[0].isupper() and k not in terms:
            return k
    return ''



def term_exists(term):
    '''
    Checks whether a word exists in vocabulary.
    '''
    return term in voc.values()



def find_word(text):
    '''
    Returns a term, if it exists in words.
    '''
    try:
        return next(w for w in words if text == w.text)
    except StopIteration:
        return None



def is_redundant(term1, term2):
    '''
    Checks whether two terms are equal regarding case sensitivity.
    '''
    return (term1.lower() in term2.lower() or
            term2.lower() in term1.lower())



def most_similar(base_vector, count):
    '''
    Basis-query with nmslib.
    Recieves vector of to-queried-word and looks
    for nearest terms based on cosine similarity.
    '''
    result = nmslib.knnQuery(index, count, base_vector.tolist())
    terms = [(words[idx].text, v.cosine_similarity_normalized(base_vector, words[idx].vector)) for idx in result]
    return terms



def nearest_neighbors(term, count):
    '''
    Returns nearest neighbors. First position in result is
    removed as it is the queried term with similarity 1.0.
    '''
    base_word = find_word(term)
    base_vector = base_word.vector
    result = most_similar(base_vector, count+1)
    if result[0][0] == term:
        result = result[1:]
    else:
        result = result[:-1]
    # for n in range(len(result) - 1, -1, -1):
    #     if is_redundant(term, result[n][0]):
    #         del result[n]
    return result



def analogies(left1, left2, right1, count):
    '''
    Performs vector calculation left2 - left1 + right1.
    For resulting vector is queried for closest terms.
    '''
    word_left1 = find_word(left1)
    word_left2 = find_word(left2)
    word_right1 = find_word(right1)
    if (not word_left1) or (not word_left2) or (not word_right1):
        return []
    vector = v.add(v.sub(word_left2.vector,word_left1.vector),word_right1.vector)
    closest = most_similar(vector, count)
    # closest_filtered = [(w, dist) for (w, dist) in closest if not
    #     is_redundant(w, left1) and not is_redundant(w, left2) and not is_redundant(w, right1)]
    return closest



def related_terms(term, relation, count):
    '''
    Performs a projection for given word.
    '''
    base_word = find_word(term)
    base_vector = base_word.vector
    proj = lrn.get_projection(base_vector, relation)
    print(proj.shape)
    result = most_similar(proj, count)
    # for n in range(len(result) - 1, -1, -1):
    #     if is_redundant(term, result[n][0]):
    #         del result[n]
    return result



def related_matrix(termX, termY):
    '''
    For inner product of two word-vectors the resulting matrix
    is compared with all relation matrices for similarity.
    '''
    base_wordX = find_word(termX)
    base_vectorX = base_wordX.vector
    base_wordY = find_word(termY)
    base_vectorY = base_wordY.vector
    return lrn.get_related_matrix(base_vectorX, base_vectorY)



def add_training_data(batch):
    '''
    Batch with new training data is added to trainData container. If
    an annotation from batch is already in trainData, it won't be added.
    Also not, if the annotation-relation is syno, anto, cohypo and the
    annotation is already in trainData with swapped x & y values.
    '''
    for i in range(len(batch)):
        x = batch[i]["x"]
        y = batch[i]["y"]
        rel = batch[i]["relation"]
        if rel in trainData:
            d = trainData[rel]
            if (x, y) not in d:
                if rel == 'syno' or rel == 'anto' or rel == 'cohypo':
                    if (y, x) not in d:
                        d.append((x, y))
                        trainData[rel] = d
                else:
                    d.append((x, y))
                    trainData[rel] = d
        else:
            trainData[rel] = [(x, y)]



def clear_training_data():
    '''
    Deletes all entries in trainData container.
    '''
    trainData.clear()



def train(alpha, numIterations):
    '''
    Performs linear regression with gradient descent optimization
    on all entries in the trainData container and removes all data
    afterwards.
    '''
    for rel,data in trainData.items():
        X, Y = build_wordpairs(rel, data, dims)
        lrn.gradient_descent(X, Y, rel, alpha, numIterations)
    clear_training_data()



def build_wordpairs(rel, trainData, dims):
    '''
    Searches for vectors of corresponding words in trainData and
    stacks them for later training.
    '''
    X, Y = [None] * dims, [None] * dims
    for x, y in trainData:
        base_word1 = find_word(x)
        base_word2 = find_word(y)
        X = np.vstack((X, base_word1.vector))
        Y = np.vstack((Y, base_word2.vector))
        # if rel == 'syno' or rel == 'anto' or rel == 'cohypo':
        #     X = np.vstack((X, base_word2.vector))
        #     Y = np.vstack((Y, base_word1.vector))
    return X[1:], Y[1:]



def get_delta(rel):
    '''
    Calculates the delta-values of a current rel matrix, and its initial values.
    '''
    return lrn.get_matrix_delta(rel)



def add_history_data(batch):
    '''
    Batch with new training data is added to history file. If
    an annotation from batch is already in history, it won't be added.
    Also not, if the annotation-relation is syno, anto, cohypo and the
    annotation is already in trainData with swapped x & y values.
    '''
    with open('history.txt', 'r') as json_file:
        history = json.load(json_file)
        for i in range(len(batch)):
            x = batch[i]["x"]
            y = batch[i]["y"]
            rel = batch[i]["relation"]
            d = {'x': x, 'y': y, 'relation': rel}
            if d not in history:
                if rel == 'syno' or rel == 'anto' or rel == 'cohypo':
                    if {'x': y, 'y': x, 'relation': rel} not in history:
                        history.append(d)
                else:
                    history.append(d)
    with open('history.txt', 'w') as outfile:
        json.dump(history, outfile)



def load_db_data():
    '''
    Loads annotations from db.
    '''
    response = annotations_table.scan()
    data = response['Items']
    while 'LastEvaluatedKey' in response:
        response = annotations_table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
        data.extend(response['Items'])
    add_history_data(data)



def upload_history_data():
    '''
    Uploads new annotations to dynamoDB.
    '''
    with open('history.txt', 'r') as json_file:
        history = json.load(json_file)
    for i in range(len(history)):
        x = history[i]["x"]
        y = history[i]["y"]
        rel = history[i]["relation"]
        anno = {'x': x, 'y': y, 'relation': rel}
        annotations_table.put_item(Item = anno)



def get_history():
    '''
    Returns history data.
    '''
    with open('history.txt', 'r') as json_file:
        history = json.load(json_file)
    return history



def save_history(hist):
    '''
    Overwrites current history file with new history data.
    '''
    with open('history.txt', 'w') as outfile:
        json.dump(hist, outfile)



def train_history(alpha, numIterations):
    '''
    Loads history file and performs linear regression with
    gradient descent on all entries.
    '''
    with open('history.txt', 'r') as json_file:
        history = json.load(json_file)
        add_training_data(history)
        train(alpha, numIterations)
    with open('history.txt', 'w') as outfile:
        json.dump(history, outfile)



def clear_history():
    '''
    Deletes all enties in history file.
    '''
    with open('history.txt') as json_file:
        history = []
    with open('history.txt', 'w') as outfile:
        json.dump(history, outfile)



def reset_matrices():
    '''
    Delete and re-initialize all relation-matrices.
    '''
    lrn.reset_matrices(dims)

