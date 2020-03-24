import featuretools as ft
import pandas as pd

# Create Entity
turnover_df = pd.read_csv('/Users/foorx/droneDataset/train_020319_LOG00049_56_58_59.csv')
es = ft.EntitySet(id = 'Turnover')
es.entity_from_dataframe(entity_id = 'hr', dataframe = turnover_df, index = 'index')

# Run deep feature synthesis with transformation primitives
feature_matrix, feature_defs = ft.dfs(entityset = es, target_entity = 'hr',
                                      trans_primitives = ['add_numeric', 'multiply_numeric'], 
                                      verbose=True)

feature_matrix.to_csv("feature_matrix.csv")