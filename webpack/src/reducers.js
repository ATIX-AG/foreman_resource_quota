import { combineReducers } from 'redux';
import EmptyStateReducer from './Components/EmptyState/EmptyStateReducer';

const reducers = {
  foremanResourceQuota: combineReducers({
    emptyState: EmptyStateReducer,
  }),
};

export default reducers;
