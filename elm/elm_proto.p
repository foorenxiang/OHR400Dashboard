from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression

from elm import ELMClassifier
from random_hidden_layer import RBFRandomHiddenLayer
from random_hidden_layer import SimpleRandomHiddenLayer

# pre-process dataset
X, y = ds
X = StandardScaler().fit_transform(X)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=.4,
                                                    random_state=0)

x_min, x_max, y_min, y_max, xx, yy = get_data_bounds(X)




# iterate over classifiers
    for name, clf in zip(names, classifiers):
        # ax = pl.subplot(len(datasets), len(classifiers) + 1, i)
        clf.fit(X_train, y_train)
        score = clf.score(X_test, y_test)

        # Plot the decision boundary. For that, we will asign a color to each
        # point in the mesh [x_min, m_max]x[y_min, y_max].
        Z = clf.decision_function(np.c_[xx.ravel(), yy.ravel()])


#classifiers
def make_classifiers():

    names = ["ELM(10,tanh)", "ELM(10,tanh,LR)", "ELM(10,sinsq)",
             "ELM(10,tribas)", "ELM(hardlim)", "ELM(20,rbf(0.1))"]

    nh = 10

    # pass user defined transfer func
    sinsq = (lambda x: np.power(np.sin(x), 2.0))
    srhl_sinsq = SimpleRandomHiddenLayer(n_hidden=nh,
                                         activation_func=sinsq,
                                         random_state=0)

    # use internal transfer funcs
    srhl_tanh = SimpleRandomHiddenLayer(n_hidden=nh,
                                        activation_func='tanh',
                                        random_state=0)

    srhl_tribas = SimpleRandomHiddenLayer(n_hidden=nh,
                                          activation_func='tribas',
                                          random_state=0)

    srhl_hardlim = SimpleRandomHiddenLayer(n_hidden=nh,
                                           activation_func='hardlim',
                                           random_state=0)

    # use gaussian RBF
    srhl_rbf = RBFRandomHiddenLayer(n_hidden=nh*2, gamma=0.1, random_state=0)

    log_reg = LogisticRegression(solver='liblinear')

    classifiers = [ELMClassifier(srhl_tanh),
                   ELMClassifier(srhl_tanh, regressor=log_reg),
                   ELMClassifier(srhl_sinsq),
                   ELMClassifier(srhl_tribas),
                   ELMClassifier(srhl_hardlim),
                   ELMClassifier(srhl_rbf)]

    return names, classifiers