import React from 'react';
import WelcomePage from './WelcomePage';

const routes = [
  {
    path: '/foreman_resource_quota/welcome',
    exact: true,
    render: (props) => <WelcomePage {...props} />,
  },
];

export default routes;
