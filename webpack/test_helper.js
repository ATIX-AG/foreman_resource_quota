/* Credits: https://github.com/theforeman/foreman_ansible/blob/master/webpack/testHelper.js */
import React, { useState } from 'react';
import { applyMiddleware, createStore, compose, combineReducers } from 'redux';
import { reducers as apiReducer, APIMiddleware } from 'foremanReact/redux/API';
import { Provider } from 'react-redux';
import { MockedProvider } from '@apollo/react-testing';
import thunk from 'redux-thunk';

import ConfirmModal, {
  reducers as confirmModalReducers,
} from 'foremanReact/components/ConfirmModal';
import { getForemanContext } from 'foremanReact/Root/Context/ForemanContext';

const reducers = combineReducers({ ...apiReducer, ...confirmModalReducers });
export const generateStore = () =>
  createStore(reducers, compose(applyMiddleware(thunk, APIMiddleware)));

// use to resolve async mock requests for apollo MockedProvider
export const tick = () => new Promise(resolve => setTimeout(resolve, 0));

export const withRedux = Component => props => (
  <Provider store={generateStore()}>
    <Component {...props} />
    <ConfirmModal />
  </Provider>
);

export const withMockedProvider = Component => props => {
  const [context, setContext] = useState({
    metadata: {
      UISettings: {
        perPage: 20,
      },
    },
  });
  const contextData = { context, setContext };
  const ForemanContext = getForemanContext(contextData);

  // eslint-disable-next-line react/prop-types
  const { mocks, ...rest } = props;

  return (
    <ForemanContext.Provider value={contextData}>
      <MockedProvider mocks={mocks}>
        <Component {...rest} />
      </MockedProvider>
    </ForemanContext.Provider>
  );
};
