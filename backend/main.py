from flask import Flask, request
from flask_cors import CORS

from logic import operations as o
import json
import os
import sys
# noinspection PyUnresolvedReferences
from werkzeug.utils import secure_filename


app = Flask('__name__')
CORS(app)

EMBEDDINGS_FOLDER = 'embeddings/'
UPLOAD_FOLDER = 'uploads/'

app.config['EMBEDDINGS_FOLDER'] = EMBEDDINGS_FOLDER
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER


ALLOWED_EXTENSIONS = set(['txt', 'matrix', 'vec'])
def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1] in ALLOWED_EXTENSIONS


def file_accessible(filepath, mode):
    '''
    Test if file exists.
    '''
    try:
        f = open(filepath, mode)
        f.close()
    except IOError as e:
        return False
    return True



@app.route('/upload', methods=['GET', 'POST'])
def upload_model():
    '''
    Upload own custom model.
    '''
    if request.method == 'POST':
        file = request.files['file']
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            present = file_accessible(UPLOAD_FOLDER + filename, 'r')
            if not present:
                file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
                o.load_embedding(UPLOAD_FOLDER + filename)
                o.create_index()
                print(filename + ' embedding loaded.', file=sys.stderr)
                os.remove(UPLOAD_FOLDER + filename)
                return 'Success'
            else:
                return 'file already present'
    return "Error"



@app.route('/model', methods=['POST'])
def get_model():
    '''
    Load one of default german or english word-model.
    '''
    lang = request.form['model']
    if lang == 'german':
        o.load_embedding(EMBEDDINGS_FOLDER+'english_12.txt')
        o.load_index(EMBEDDINGS_FOLDER+'indexenglish_12')
    else:
        o.load_embedding(EMBEDDINGS_FOLDER + 'english_12.txt')
        o.load_index(EMBEDDINGS_FOLDER + 'indexenglish_12')
    print(lang+' embedding loaded.', file=sys.stderr)
    return 'Success'



@app.route('/random', methods=['POST', 'GET'])
def get_random():
    '''
    Generate new random term.
    '''
    words = []
    j = json.loads(request.data)
    n=0
    for i in j:
        words.append(j.get(str(n)))
        n+=1
    response = o.get_random_term(words)
    return response



@app.route('/checkword', methods=['POST'])
def word_in_embedding():
    '''
    Check if word exists in embedding.
    '''
    term = str(request.form['term'])
    response = o.term_exists(term)
    return str(response)



@app.route('/projection', methods=['POST'])
def get_matrix_delta():
    '''
    Get deltas for a specific relation-type.
    '''
    relation = str(request.form['relation'])
    response = o.get_delta(relation).tolist()
    return json.dumps(response)



@app.route('/trainbatch', methods=['POST'])
def train_batch():
    '''
    Train data from temporary batch.
    '''
    # batch = request.get_json()
    data = request.get_json()
    batch = data['batch']
    alpha = float(data['alpha'])
    iterations = int(data['iterations'])
    o.add_training_data(batch)
    # o.add_history_data(batch)
    o.train(alpha, iterations)
    return 'Batch trained'



@app.route('/relationnode', methods=['POST'])
def get_related_terms():
    '''
    Predict terms for given word and relation-type.
    '''
    relation = str(request.form['relation'])
    term = str(request.form['term'])
    count = int(request.form['count'])
    if relation == "NN":
        result = o.nearest_neighbors(term, count)
    else:
        result = o.related_terms(term, relation, count)
    d = {}
    for i in range(len(result)):
        d[i] = {}
        d[i]['word'] = result[i][0]
        d[i]['value'] = round(result[i][1], 3)
    return json.dumps(d)



@app.route('/analogies', methods=['POST'])
def get_analogies():
    '''
    Calculate analogies.
    '''
    term1 = str(request.form['term1'])
    term2 = str(request.form['term2'])
    term3 = str(request.form['term3'])
    count = int(request.form['count'])
    result = o.analogies(term1, term2, term3, count)
    d = {}
    for i in range(len(result)):
        d[i] = {}
        d[i]['word'] = result[i][0]
        d[i]['value'] = round(result[i][1], 3)
    return json.dumps(d)



@app.route('/relationlink', methods=['POST'])
def get_related_links():
    '''
    Predict a relation-type for a word-pair.
    '''
    source = str(request.form['source'])
    target = str(request.form['target'])
    relation, mse = o.related_matrix(source, target)
    d = {}
    d[0] = {}
    d[0]['relation'] = relation
    d[0]['mse'] = round(mse, 3)
    return json.dumps(d)



@app.route('/addannon', methods=['POST'])
def add_annotation():
    '''
    Add annotation to history.
    '''
    annotation = request.get_json()
    o.add_history_data([annotation])
    return 'Annotation added'



@app.route('/resetmat', methods=['POST','GET'])
def reset_matrices():
    '''
    Re-initialize all projection-matrices.
    '''
    o.reset_matrices()
    print('Matrices reseted.', file=sys.stderr)
    return 'Success'



@app.route('/loadhistory', methods=['POST'])
def load_history():
    '''
    Load history from db.
    '''
    o.load_db_data()
    return 'Success'



@app.route('/history', methods=['POST','GET'])
def history():
    '''
    Get all history data.
    '''
    response = o.get_history()
    print('History send', file=sys.stderr)
    return json.dumps(response)



@app.route('/clearhistory', methods=['POST','GET'])
def clear_history():
    '''
    Clear all annotations in history.
    '''
    o.clear_history()
    print('History cleared.', file=sys.stderr)
    return 'Success'


@app.route('/uploadhistory', methods=['POST'])
def upload_history():
    '''
    Load history from db.
    '''
    o.upload_history_data()
    return 'Success'


@app.route('/learnhistory', methods=['POST'])
def train_history():
    '''
    Train on all history data.
    '''
    alpha = float(request.form['alpha'])
    iterations = int(request.form['iterations'])
    o.train_history(alpha, iterations)
    return 'Success'



@app.route('/savehistory', methods=['POST'])
def save_history():
    '''
    Save edited history.
    '''
    hist = request.get_json()
    o.save_history(hist)
    return 'Success'
    

if __name__ == "__main__":
    app.run(host="0.0.0.0",port=8080, debug=False, use_reloader=False)