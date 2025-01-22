import React from 'react';
import '@testing-library/jest-dom';

import { mount, testComponentSnapshotsWithFixtures } from '@theforeman/test';
// Notice: (not) importing Modal affects the snapshot test since it fills
// the components data dynamically in snapshots as soon as it can find the component.
import { Modal } from '@patternfly/react-core';

import { withMockedProvider, withRedux } from '../../../test_helper';
import ResourceQuotaForm from '../../ResourceQuotaForm';
import ResourceQuotaEmptyState from '../index';

const TestComponent = withRedux(withMockedProvider(ResourceQuotaEmptyState));

describe('ResourceQuotaEmptyState', () => {
  testComponentSnapshotsWithFixtures(ResourceQuotaEmptyState, {
    'should render': {}, // component has no props
  });

  test('opens the modal on clicking "Create resource quota" button', () => {
    const wrapper = mount(<TestComponent />);

    expect(wrapper.find(Modal).prop('isOpen')).toBe(false); // check we provide the correct input to Modal
    expect(wrapper.find(ResourceQuotaForm).exists()).toBe(false);

    wrapper
      .find('button')
      .filterWhere(button => button.text() === 'Create resource quota')
      .simulate('click');
    wrapper.update();

    expect(wrapper.find(Modal).prop('isOpen')).toBe(true);
    expect(wrapper.find(ResourceQuotaForm).exists()).toBe(true);
  });
});
